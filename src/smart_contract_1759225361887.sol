Here's a Solidity smart contract named `NexusBeacon` that implements a Decentralized Real-World Asset (RWA) Digital Twin & Predictive Maintenance Protocol. It integrates concepts like dynamic digital twins, verifiable off-chain AI predictions, an incentive-based reputation system, and a simplified DAO governance model.

This contract aims to be interesting, advanced, creative, and trendy by combining several cutting-edge blockchain concepts into a cohesive protocol. It emphasizes the dynamic nature of on-chain digital twins, driven by real-world data and AI-powered insights, with built-in mechanisms for trust, incentives, and governance.

---

### Outline for NexusBeacon Smart Contract

**I. Core Asset Management**
   - `registerRWAAsset`: Registers a new real-world asset (RWA) digital twin on-chain.
   - `updateAssetMetadata`: Allows asset owners to update descriptive metadata for their RWA.
   - `transferAssetOwnership`: Facilitates the transfer of ownership for a registered RWA digital twin.
   - `retireAsset`: Marks an RWA as decommissioned, preventing further data/prediction submissions.
   - `getAssetDetails`: Retrieves comprehensive details of a specific registered RWA.

**II. Data Stream & Oracle Integration**
   - `authorizeDataStreamProvider`: Authorizes a specific address to submit telemetry data for certain asset types.
   - `submitAssetTelemetryData`: Records real-world sensor data (telemetry) for an RWA via an authorized oracle/provider.
   - `setAssetDataFeedParameters`: Configures expected data frequency, acceptable ranges, and update intervals for an RWA's data feed.
   - `getDataStreamHistory`: Fetches a history of recent telemetry data points for a given RWA.

**III. Predictive Maintenance & AI Model Integration**
   - `authorizePredictionModelOperator`: Authorizes an address to operate and submit AI model predictions.
   - `submitPredictiveMaintenanceReport`: Submits an AI-generated prediction or anomaly report, including a verifiable proof hash.
   - `validatePredictionReport`: Allows authorized validators to confirm or challenge the accuracy of submitted predictions.
   - `requestAdHocPrediction`: Enables an asset owner to request and pay for a specific, on-demand AI prediction.
   - `getModelOperatorReputation`: Retrieves the reputation score of a prediction model operator.

**IV. Incentive & Reputation System**
   - `stakeForPerformanceBond`: Asset owner stakes tokens as a performance bond, potentially for insurance or incentivizing good maintenance.
   - `claimPerformanceReward`: Allows asset owners to claim rewards for consistent good asset performance based on KPIs.
   - `distributePredictionRewards`: System function to distribute rewards to successful model operators and validators.
   - `punishMaliciousActor`: Imposes penalties (slashing, reputation reduction) on actors found to be malicious or inaccurate.
   - `getActorReputation`: Retrieves the general reputation score of any participant address (owner, provider, operator, validator).

**V. Governance & System Parameters**
   - `proposeSystemParameterUpdate`: Initiates a DAO proposal to change system-wide parameters (e.g., fees, reward rates).
   - `voteOnProposal`: Allows DAO members to vote on active governance proposals.
   - `executeProposal`: Executes a successfully passed DAO governance proposal.
   - `setOracleAddress`: Updates the address of a trusted oracle for a specific function (e.g., telemetry, prediction validation).
   - `updateDAOContractAddress`: Updates the address of the main governance DAO contract, allowing for future upgrades.

---

### NexusBeacon Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking

/**
 * @title NexusBeacon - Decentralized Real-World Asset (RWA) Digital Twin & Predictive Maintenance Protocol
 * @dev This contract manages the digital twins of real-world assets, integrates with data oracles for telemetry,
 *      incorporates verifiable AI predictions for maintenance, and includes a reputation and incentive system.
 *      It also features a simplified DAO-like governance structure.
 */
contract NexusBeacon is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    uint256 public nextAssetId; // Counter for unique RWA asset IDs
    address public daoContractAddress; // Address of the DAO contract for governance functions

    // ERC20 token used for staking, rewards, and fees
    IERC20 public immutable nexusToken; 

    // Mappings for various entities and their properties
    mapping(uint256 => Asset) public assets; // assetId => Asset details
    mapping(address => int256) public actorReputation; // address => reputation score (can be negative)
    mapping(address => bool) public isDataStreamProviderAuthorized; // address => is authorized
    mapping(address => bool) public isPredictionModelOperatorAuthorized; // address => is authorized
    mapping(address => bool) public isValidatorAuthorized; // address => is authorized
    mapping(bytes32 => address) public oracleAddresses; // oracleType (e.g., "TelemetryOracle") => address

    // Structs for data representation
    struct Asset {
        uint256 id;
        address owner;
        string assetType; // e.g., "SolarPanel", "IndustrialRobot", "Vehicle"
        string metadataURI; // URI to IPFS/Arweave for detailed asset metadata
        uint256 registrationTimestamp;
        bool retired;
        // Data Feed Parameters
        uint256 expectedDataInterval; // seconds
        int256 minAcceptableValue;
        int256 maxAcceptableValue;
        // Performance Tracking
        uint256 lastPerformanceRewardClaim;
        uint256 totalPerformanceScore; // Accumulated score for good performance
    }

    struct TelemetryDataPoint {
        uint256 timestamp;
        uint256 assetId;
        int256 value; // Example value, can be expanded to a struct for multiple sensor readings
        string dataType; // e.g., "Temperature", "PowerOutput", "Humidity"
        bytes32 dataHash; // Hash of full off-chain data blob for integrity
    }

    // Stores recent telemetry data points for an asset. Use an array for simplicity,
    // in a real-world scenario, this might be off-chain with only hashes on-chain or aggregated.
    mapping(uint256 => TelemetryDataPoint[]) public assetTelemetryHistory;

    struct PredictionReport {
        uint256 reportId;
        uint256 assetId;
        address operator; // The model operator who submitted the prediction
        uint256 timestamp;
        string predictionType; // e.g., "FailurePrediction", "AnomalyDetection", "PerformanceForecast"
        string predictionResultURI; // URI to off-chain detailed prediction report
        bytes32 verifiableProofHash; // Hash of ZK-proof or verifiable computation result
        bool isValidated; // True if validated, false if challenged or pending
        bool isValid; // True if validated as correct, false if validated as incorrect
        uint256 validationTimestamp;
    }

    // Mapping for prediction reports
    mapping(uint256 => PredictionReport) public predictionReports;
    uint256 public nextReportId;

    // DAO Governance (Simplified)
    struct Proposal {
        uint256 id;
        string description;
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract to call if proposal passes
        uint256 quorumThreshold; // Minimum votes needed (percentage)
        uint256 majorityThreshold; // Percentage of 'yes' votes needed
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // System Parameters (adjustable via DAO)
    uint256 public minStakeForOperator; // Minimum stake for a prediction model operator
    uint256 public predictionRewardAmount; // Reward for a correct prediction
    uint256 public validationRewardAmount; // Reward for correctly validating/challenging
    int256 public maliciousActorReputationPenalty; // Reputation penalty for malicious behavior
    int256 public successfulPredictionReputationBonus; // Reputation bonus for accurate predictions
    int256 public successfulValidationReputationBonus; // Reputation bonus for accurate validation
    uint256 public performanceRewardRate; // Nexus tokens per performance score point

    // --- Events ---
    event AssetRegistered(uint256 indexed assetId, address indexed owner, string assetType, string metadataURI);
    event AssetMetadataUpdated(uint256 indexed assetId, string newMetadataURI);
    event AssetOwnershipTransferred(uint256 indexed assetId, address indexed from, address indexed to);
    event AssetRetired(uint256 indexed assetId);
    event TelemetryDataSubmitted(uint256 indexed assetId, uint256 timestamp, string dataType, int256 value);
    event DataFeedParametersSet(uint256 indexed assetId, uint256 expectedInterval, int256 minVal, int256 maxVal);
    event PredictionReportSubmitted(uint256 indexed reportId, uint256 indexed assetId, address indexed operator, string predictionType, bytes32 verifiableProofHash);
    event PredictionReportValidated(uint256 indexed reportId, uint256 indexed assetId, address indexed validator, bool isValid);
    event PerformanceBondStaked(uint256 indexed assetId, address indexed staker, uint256 amount);
    event PerformanceRewardClaimed(uint256 indexed assetId, address indexed owner, uint256 amount, uint256 scoreEarned);
    event ActorReputationUpdated(address indexed actor, int256 oldReputation, int256 newReputation);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleAddressSet(bytes32 indexed oracleType, address indexed newAddress);
    event DAOContractAddressUpdated(address indexed newAddress);


    // --- Constructor ---
    constructor(address _nexusTokenAddress, address _daoContractAddress) Ownable(msg.sender) {
        require(_nexusTokenAddress != address(0), "Invalid Nexus Token address");
        require(_daoContractAddress != address(0), "Invalid DAO Contract address");

        nexusToken = IERC20(_nexusTokenAddress);
        daoContractAddress = _daoContractAddress;
        nextAssetId = 1;
        nextReportId = 1;
        nextProposalId = 1;

        // Initialize default system parameters (can be changed by DAO)
        minStakeForOperator = 1000 * (10 ** 18); // Example: 1000 Nexus tokens
        predictionRewardAmount = 100 * (10 ** 18); // Example: 100 Nexus tokens
        validationRewardAmount = 20 * (10 ** 18); // Example: 20 Nexus tokens
        maliciousActorReputationPenalty = -500;
        successfulPredictionReputationBonus = 50;
        successfulValidationReputationBonus = 10;
        performanceRewardRate = 1 * (10 ** 18); // 1 Nexus token per point
    }

    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "Only DAO can call this function");
        _;
    }

    modifier onlyAuthorizedDataStreamProvider() {
        require(isDataStreamProviderAuthorized[msg.sender], "Not an authorized data stream provider");
        _;
    }

    modifier onlyAuthorizedPredictionModelOperator() {
        require(isPredictionModelOperatorAuthorized[msg.sender], "Not an authorized prediction model operator");
        _;
    }

    modifier onlyAuthorizedValidator() {
        require(isValidatorAuthorized[msg.sender], "Not an authorized validator");
        _;
    }

    modifier onlyOracle(bytes32 _oracleType) {
        require(msg.sender == oracleAddresses[_oracleType], "Sender is not the authorized oracle");
        _;
    }

    // --- I. Core Asset Management ---

    /**
     * @dev Registers a new real-world asset (RWA) digital twin.
     * @param _assetType A string describing the type of the asset (e.g., "SolarPanel", "IndustrialRobot").
     * @param _metadataURI URI pointing to off-chain detailed metadata (e.g., IPFS hash).
     * @return The unique ID of the newly registered asset.
     */
    function registerRWAAsset(string memory _assetType, string memory _metadataURI)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 newAssetId = nextAssetId++;
        assets[newAssetId] = Asset({
            id: newAssetId,
            owner: msg.sender,
            assetType: _assetType,
            metadataURI: _metadataURI,
            registrationTimestamp: block.timestamp,
            retired: false,
            expectedDataInterval: 0, // Default, must be set by owner
            minAcceptableValue: 0,
            maxAcceptableValue: 0,
            lastPerformanceRewardClaim: block.timestamp,
            totalPerformanceScore: 0
        });

        emit AssetRegistered(newAssetId, msg.sender, _assetType, _metadataURI);
        return newAssetId;
    }

    /**
     * @dev Allows the asset owner to update descriptive metadata for their RWA.
     * @param _assetId The ID of the asset.
     * @param _newMetadataURI New URI pointing to updated off-chain metadata.
     */
    function updateAssetMetadata(uint256 _assetId, string memory _newMetadataURI)
        external
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender, "Only asset owner can update metadata");
        require(!assets[_assetId].retired, "Asset is retired");
        assets[_assetId].metadataURI = _newMetadataURI;
        emit AssetMetadataUpdated(_assetId, _newMetadataURI);
    }

    /**
     * @dev Transfers ownership of a registered RWA digital twin to a new address.
     * @param _assetId The ID of the asset.
     * @param _newOwner The address of the new owner.
     */
    function transferAssetOwnership(uint256 _assetId, address _newOwner)
        external
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender, "Only asset owner can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(!assets[_assetId].retired, "Asset is retired");

        address oldOwner = assets[_assetId].owner;
        assets[_assetId].owner = _newOwner;

        emit AssetOwnershipTransferred(_assetId, oldOwner, _newOwner);
    }

    /**
     * @dev Marks an RWA as decommissioned, preventing further data/prediction submissions.
     *      Only the owner or DAO can retire an asset.
     * @param _assetId The ID of the asset to retire.
     */
    function retireAsset(uint256 _assetId)
        external
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender || msg.sender == daoContractAddress, "Only asset owner or DAO can retire asset");
        require(!assets[_assetId].retired, "Asset is already retired");
        assets[_assetId].retired = true;
        emit AssetRetired(_assetId);
    }

    /**
     * @dev Retrieves full details of a specific registered RWA.
     * @param _assetId The ID of the asset.
     * @return All fields of the Asset struct.
     */
    function getAssetDetails(uint256 _assetId)
        external
        view
        returns (uint256, address, string memory, string memory, uint256, bool, uint256, int256, int256, uint256, uint256)
    {
        Asset storage asset = assets[_assetId];
        return (
            asset.id,
            asset.owner,
            asset.assetType,
            asset.metadataURI,
            asset.registrationTimestamp,
            asset.retired,
            asset.expectedDataInterval,
            asset.minAcceptableValue,
            asset.maxAcceptableValue,
            asset.lastPerformanceRewardClaim,
            asset.totalPerformanceScore
        );
    }

    // --- II. Data Stream & Oracle Integration ---

    /**
     * @dev Authorizes an address to submit telemetry data for any asset type.
     *      This is a DAO-governed function.
     * @param _providerAddress The address to authorize.
     * @param _isAuthorized True to authorize, false to deauthorize.
     */
    function authorizeDataStreamProvider(address _providerAddress, bool _isAuthorized)
        external
        onlyDAO
        whenNotPaused
    {
        isDataStreamProviderAuthorized[_providerAddress] = _isAuthorized;
    }

    /**
     * @dev Submits periodic sensor data (telemetry) for an RWA.
     *      Requires sender to be an authorized data stream provider or a specific telemetry oracle.
     * @param _assetId The ID of the asset.
     * @param _dataType A string describing the type of data (e.g., "Temperature", "PowerOutput").
     * @param _value The integer value of the sensor reading.
     * @param _dataHash A cryptographic hash of the raw, detailed off-chain data for verification.
     */
    function submitAssetTelemetryData(uint256 _assetId, string memory _dataType, int256 _value, bytes32 _dataHash)
        external
        onlyAuthorizedDataStreamProvider // Or `onlyOracle(keccak256("TelemetryOracle"))`
        whenNotPaused
    {
        require(assets[_assetId].owner != address(0), "Asset does not exist");
        require(!assets[_assetId].retired, "Asset is retired");

        assetTelemetryHistory[_assetId].push(TelemetryDataPoint({
            timestamp: block.timestamp,
            assetId: _assetId,
            value: _value,
            dataType: _dataType,
            dataHash: _dataHash
        }));

        // Simplified performance score update: If value is within acceptable range, increase score.
        // More complex logic would involve comparing against historical data, expected curves, etc.
        Asset storage asset = assets[_assetId];
        if (_value >= asset.minAcceptableValue && _value <= asset.maxAcceptableValue) {
            asset.totalPerformanceScore++;
        }

        emit TelemetryDataSubmitted(_assetId, block.timestamp, _dataType, _value);
    }

    /**
     * @dev Configures expected data frequency, acceptable ranges for an RWA's data feed.
     *      Only the asset owner or DAO can set these parameters.
     * @param _assetId The ID of the asset.
     * @param _expectedDataInterval Expected interval between data submissions in seconds. 0 for no expectation.
     * @param _minAcceptableValue Minimum acceptable sensor reading value.
     * @param _maxAcceptableValue Maximum acceptable sensor reading value.
     */
    function setAssetDataFeedParameters(uint256 _assetId, uint256 _expectedDataInterval, int256 _minAcceptableValue, int256 _maxAcceptableValue)
        external
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender || msg.sender == daoContractAddress, "Only asset owner or DAO can set data feed parameters");
        require(!assets[_assetId].retired, "Asset is retired");
        require(_minAcceptableValue <= _maxAcceptableValue, "Min value cannot be greater than max value");

        Asset storage asset = assets[_assetId];
        asset.expectedDataInterval = _expectedDataInterval;
        asset.minAcceptableValue = _minAcceptableValue;
        asset.maxAcceptableValue = _maxAcceptableValue;

        emit DataFeedParametersSet(_assetId, _expectedDataInterval, _minAcceptableValue, _maxAcceptableValue);
    }

    /**
     * @dev Fetches a history of recent telemetry data points for a given RWA.
     * @param _assetId The ID of the asset.
     * @param _limit The maximum number of data points to retrieve.
     * @return An array of TelemetryDataPoint structs.
     */
    function getDataStreamHistory(uint256 _assetId, uint256 _limit)
        external
        view
        returns (TelemetryDataPoint[] memory)
    {
        require(assets[_assetId].owner != address(0), "Asset does not exist");
        
        uint256 total = assetTelemetryHistory[_assetId].length;
        uint256 startIndex = 0;
        if (total > _limit) {
            startIndex = total - _limit;
        }

        TelemetryDataPoint[] memory history = new TelemetryDataPoint[](total - startIndex);
        for (uint256 i = startIndex; i < total; i++) {
            history[i - startIndex] = assetTelemetryHistory[_assetId][i];
        }
        return history;
    }


    // --- III. Predictive Maintenance & AI Model Integration ---

    /**
     * @dev Authorizes an address to operate and submit AI model predictions.
     *      Requires a minimum stake to prevent spam/malicious operators.
     *      This is a DAO-governed function.
     * @param _operatorAddress The address to authorize.
     * @param _isAuthorized True to authorize, false to deauthorize.
     */
    function authorizePredictionModelOperator(address _operatorAddress, bool _isAuthorized)
        external
        onlyDAO
        whenNotPaused
    {
        // Add logic here to check if the operator has sufficient stake if _isAuthorized is true
        // For simplicity, this initial version assumes stake is managed externally or via a separate function.
        // require(nexusToken.balanceOf(_operatorAddress) >= minStakeForOperator, "Operator must stake minimum tokens");
        isPredictionModelOperatorAuthorized[_operatorAddress] = _isAuthorized;
    }

    /**
     * @dev Submits an AI-generated prediction or anomaly report for an asset.
     *      Includes a verifiable proof hash (e.g., ZK-proof output hash, trusted execution environment proof hash).
     * @param _assetId The ID of the asset the prediction is for.
     * @param _predictionType A string describing the prediction (e.g., "FailurePrediction", "AnomalyDetected").
     * @param _predictionResultURI URI to off-chain detailed prediction report.
     * @param _verifiableProofHash A hash representing the verifiable proof of the off-chain computation.
     * @return The ID of the new prediction report.
     */
    function submitPredictiveMaintenanceReport(uint256 _assetId, string memory _predictionType, string memory _predictionResultURI, bytes32 _verifiableProofHash)
        external
        onlyAuthorizedPredictionModelOperator
        whenNotPaused
        returns (uint256)
    {
        require(assets[_assetId].owner != address(0), "Asset does not exist");
        require(!assets[_assetId].retired, "Asset is retired");

        uint256 reportId = nextReportId++;
        predictionReports[reportId] = PredictionReport({
            reportId: reportId,
            assetId: _assetId,
            operator: msg.sender,
            timestamp: block.timestamp,
            predictionType: _predictionType,
            predictionResultURI: _predictionResultURI,
            verifiableProofHash: _verifiableProofHash,
            isValidated: false,
            isValid: false,
            validationTimestamp: 0
        });

        emit PredictionReportSubmitted(reportId, _assetId, msg.sender, _predictionType, _verifiableProofHash);
        return reportId;
    }

    /**
     * @dev Allows authorized validators to confirm or challenge the accuracy of submitted predictions.
     *      A challenge might involve staking tokens.
     * @param _reportId The ID of the prediction report to validate.
     * @param _isValid True if the validator confirms the prediction is correct, false if it's incorrect/malicious.
     */
    function validatePredictionReport(uint256 _reportId, bool _isValid)
        external
        onlyAuthorizedValidator // Or specific oracle for validation
        whenNotPaused
    {
        PredictionReport storage report = predictionReports[_reportId];
        require(report.operator != address(0), "Prediction report does not exist");
        require(!report.isValidated, "Prediction report already validated");
        
        report.isValidated = true;
        report.isValid = _isValid;
        report.validationTimestamp = block.timestamp;

        // Update reputation based on validation
        _updateActorReputation(report.operator, _isValid ? successfulPredictionReputationBonus : -successfulPredictionReputationBonus);
        _updateActorReputation(msg.sender, successfulValidationReputationBonus); // Validator gets bonus for contributing

        emit PredictionReportValidated(_reportId, report.assetId, msg.sender, _isValid);
    }

    /**
     * @dev Enables an asset owner to request a specific, on-demand AI prediction and pay a fee.
     *      This would trigger an off-chain process by a model operator.
     * @param _assetId The ID of the asset.
     * @param _predictionRequestType The type of prediction requested (e.g., "7DayPerformanceForecast").
     * @param _operatorAddress The specific operator to request from, or address(0) for any available.
     * @param _fee Amount of Nexus tokens paid for the request.
     */
    function requestAdHocPrediction(uint256 _assetId, string memory _predictionRequestType, address _operatorAddress, uint256 _fee)
        external
        nonReentrant
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender, "Only asset owner can request predictions for their asset");
        require(!assets[_assetId].retired, "Asset is retired");
        require(_fee > 0, "Fee must be greater than zero");
        
        // Transfer fee to contract, which will forward to operator upon successful submission/validation
        require(nexusToken.transferFrom(msg.sender, address(this), _fee), "Nexus token transfer failed");

        // Logic to notify _operatorAddress off-chain.
        // The actual prediction submission would come via `submitPredictiveMaintenanceReport` later.
        // For simplicity, we just log the request here.
        // In a real system, this would involve event listeners and a request queue.
        emit PredictionReportSubmitted(0, _assetId, _operatorAddress, _predictionRequestType, bytes32(0)); // Use 0 for reportId as it's just a request
    }

    /**
     * @dev Retrieves the reputation score of a prediction model operator.
     * @param _operatorAddress The address of the model operator.
     * @return The reputation score.
     */
    function getModelOperatorReputation(address _operatorAddress)
        external
        view
        returns (int256)
    {
        return actorReputation[_operatorAddress];
    }

    // --- IV. Incentive & Reputation System ---

    /**
     * @dev Asset owner stakes tokens as a performance bond, potentially for insurance or incentivizing good maintenance.
     * @param _assetId The ID of the asset.
     * @param _amount The amount of Nexus tokens to stake.
     */
    function stakeForPerformanceBond(uint256 _assetId, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(assets[_assetId].owner == msg.sender, "Only asset owner can stake for their asset");
        require(!assets[_assetId].retired, "Asset is retired");
        require(_amount > 0, "Stake amount must be greater than zero");

        require(nexusToken.transferFrom(msg.sender, address(this), _amount), "Nexus token transfer failed");
        // In a more complex system, this might be locked in a separate staking contract
        // and released based on performance or dispute resolution.

        emit PerformanceBondStaked(_assetId, msg.sender, _amount);
    }

    /**
     * @dev Allows asset owners to claim rewards for consistent good asset performance based on KPIs.
     *      Reward calculation is simplified: (current_score - last_claimed_score) * rate.
     * @param _assetId The ID of the asset.
     */
    function claimPerformanceReward(uint256 _assetId)
        external
        nonReentrant
        whenNotPaused
    {
        Asset storage asset = assets[_assetId];
        require(asset.owner == msg.sender, "Only asset owner can claim rewards for their asset");
        require(!asset.retired, "Asset is retired");

        uint256 scoreEarnedSinceLastClaim = asset.totalPerformanceScore - (asset.lastPerformanceRewardClaim > 0 ? asset.lastPerformanceRewardClaim : 0); // Simplified calculation
        if (asset.lastPerformanceRewardClaim == 0) { // First claim, assume totalPerformanceScore is net new
             scoreEarnedSinceLastClaim = asset.totalPerformanceScore;
        } else if (asset.totalPerformanceScore >= asset.lastPerformanceRewardClaim) { // Ensure score doesn't decrease when calculating
             scoreEarnedSinceLastClaim = asset.totalPerformanceScore - asset.lastPerformanceRewardClaim;
        } else {
             scoreEarnedSinceLastClaim = 0; // Score somehow decreased, no reward
        }

        require(scoreEarnedSinceLastClaim > 0, "No new performance score earned since last claim");

        uint256 rewardAmount = scoreEarnedSinceLastClaim * performanceRewardRate;
        require(rewardAmount > 0, "Calculated reward is zero");

        asset.lastPerformanceRewardClaim = asset.totalPerformanceScore; // Update last claim marker

        require(nexusToken.transfer(msg.sender, rewardAmount), "Failed to transfer reward tokens");

        emit PerformanceRewardClaimed(_assetId, msg.sender, rewardAmount, scoreEarnedSinceLastClaim);
    }

    /**
     * @dev Distributes rewards to successful prediction model operators and validators.
     *      This function would typically be called by the DAO or an automated system
     *      after a batch of predictions have been validated.
     * @param _reportIds An array of report IDs for which rewards should be distributed.
     */
    function distributePredictionRewards(uint256[] memory _reportIds)
        external
        onlyDAO // Or by a specialized reward distributor contract
        nonReentrant
        whenNotPaused
    {
        for (uint256 i = 0; i < _reportIds.length; i++) {
            PredictionReport storage report = predictionReports[_reportIds[i]];
            if (report.isValidated && report.isValid && report.operator != address(0)) {
                // Ensure operator hasn't already been rewarded for this report (add a flag if needed)
                if (nexusToken.transfer(report.operator, predictionRewardAmount)) {
                    // Update reputation for the operator
                    _updateActorReputation(report.operator, successfulPredictionReputationBonus);
                }
            }
            // Logic for validator rewards could be here too, if validation involves a specific validator ID
        }
    }

    /**
     * @dev Imposes penalties (slashing, reputation reduction) on actors found to be malicious or inaccurate.
     *      This is a critical DAO-governed function.
     * @param _actorAddress The address of the malicious actor.
     * @param _slashingAmount The amount of tokens to slash (if applicable, assumes actor has staked).
     * @param _reason A string describing the reason for the punishment.
     */
    function punishMaliciousActor(address _actorAddress, uint256 _slashingAmount, string memory _reason)
        external
        onlyDAO
        nonReentrant
        whenNotPaused
    {
        require(_actorAddress != address(0), "Cannot punish zero address");
        
        // Reduce reputation
        _updateActorReputation(_actorAddress, maliciousActorReputationPenalty);
        
        // Slash tokens (if any were staked in this contract or a linked staking contract)
        if (_slashingAmount > 0) {
            // For simplicity, assuming tokens are held by this contract directly,
            // or this would interact with a separate staking contract.
            // require(nexusToken.transfer(daoContractAddress, _slashingAmount), "Failed to slash tokens"); // Slash to DAO treasury
        }
        
        // In a full system, an event for this would detail the reason and action.
        emit ActorReputationUpdated(_actorAddress, actorReputation[_actorAddress] - maliciousActorReputationPenalty, actorReputation[_actorAddress]); // Simplified event
    }

    /**
     * @dev Private helper function to update an actor's reputation.
     * @param _actor The address of the actor.
     * @param _change The change in reputation (can be positive or negative).
     */
    function _updateActorReputation(address _actor, int256 _change) internal {
        int256 oldReputation = actorReputation[_actor];
        actorReputation[_actor] += _change;
        emit ActorReputationUpdated(_actor, oldReputation, actorReputation[_actor]);
    }

    /**
     * @dev Retrieves the general reputation score of any participant address.
     * @param _actorAddress The address of the participant.
     * @return The reputation score.
     */
    function getActorReputation(address _actorAddress)
        external
        view
        returns (int256)
    {
        return actorReputation[_actorAddress];
    }


    // --- V. Governance & System Parameters ---

    /**
     * @dev Creates a new governance proposal for system parameter updates or other actions.
     *      Callable by DAO members or privileged addresses.
     * @param _description A description of the proposal.
     * @param _targetContract The contract address to call if the proposal passes.
     * @param _callData Encoded function call data for the target contract.
     * @param _quorumThreshold Percentage (0-100) of total votes required for validity.
     * @param _majorityThreshold Percentage (0-100) of 'yes' votes required to pass.
     * @param _votingDuration Seconds for which the voting period will be open.
     * @return The ID of the newly created proposal.
     */
    function proposeSystemParameterUpdate(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _quorumThreshold,
        uint256 _majorityThreshold,
        uint256 _votingDuration
    )
        external
        onlyDAO // Or by specific role holders defined by DAO
        whenNotPaused
        returns (uint256)
    {
        require(_quorumThreshold <= 100 && _majorityThreshold <= 100, "Thresholds must be percentages (0-100)");
        require(_votingDuration > 0, "Voting duration must be positive");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            quorumThreshold: _quorumThreshold,
            majorityThreshold: _majorityThreshold,
            startTime: block.timestamp,
            endTime: block.timestamp + _votingDuration,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            executed: false
        });

        emit ProposalCreated(proposalId, _description, block.timestamp, block.timestamp + _votingDuration);
        return proposalId;
    }

    /**
     * @dev Allows DAO members to vote on active proposals.
     *      Each member (address) can vote only once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp < proposal.endTime, "Voting has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        
        // In a real DAO, voting power would be based on token balance, NFT ownership, or reputation
        // For simplicity, each address gets one vote.
        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully passed DAO proposal.
     *      Can only be called after the voting period has ended and thresholds are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        onlyDAO // Or by a specific executor role
        nonReentrant
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        // Simplified check for quorum. A real DAO would check against total eligible voting power.
        // Here, it checks if total votes exceed a minimum absolute number, or assumes `proposal.quorumThreshold`
        // is based on total *participating* voters for simplicity, or hardcoded for a small DAO.
        // For a full DAO, `totalSupply()` of governance tokens or a snapshot would be used.
        uint256 minTotalVotesForQuorum = 1; // Example: assuming at least 1 vote for quorum (highly simplified)
        if (totalVotes > minTotalVotesForQuorum) { // More realistic: total voting power * proposal.quorumThreshold / 100;
             uint256 yesPercentage = (proposal.yesVotes * 100) / totalVotes;
             require(yesPercentage >= proposal.majorityThreshold, "Proposal did not reach majority threshold");

             proposal.executed = true;
             (bool success, ) = proposal.targetContract.call(proposal.callData);
             require(success, "Proposal execution failed");
             emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal did not meet quorum threshold");
        }
    }

    /**
     * @dev Updates the address of a trusted oracle for a specific data type or function.
     *      This is a critical DAO-governed function.
     * @param _oracleType A bytes32 identifier for the oracle type (e.g., keccak256("TelemetryOracle")).
     * @param _newAddress The new address of the trusted oracle.
     */
    function setOracleAddress(bytes32 _oracleType, address _newAddress)
        external
        onlyDAO
        whenNotPaused
    {
        require(_newAddress != address(0), "New oracle address cannot be zero");
        oracleAddresses[_oracleType] = _newAddress;
        emit OracleAddressSet(_oracleType, _newAddress);
    }

    /**
     * @dev Updates the address of the main governance DAO contract.
     *      This allows for DAO contract upgrades or delegating governance to a new system.
     *      Only callable by the current DAO contract.
     * @param _newDAOContractAddress The address of the new DAO contract.
     */
    function updateDAOContractAddress(address _newDAOContractAddress)
        external
        onlyDAO
        whenNotPaused
    {
        require(_newDAOContractAddress != address(0), "New DAO contract address cannot be zero");
        daoContractAddress = _newDAOContractAddress;
        emit DAOContractAddressUpdated(_newDAOContractAddress);
    }
    
    // --- Owner / Admin Functions (inherited from Ownable) ---
    
    /**
     * @dev Pauses all external operations of the contract.
     *      Only callable by the owner (or DAO after transferOwnership).
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses all external operations of the contract.
     *      Only callable by the owner (or DAO after transferOwnership).
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to set system parameters directly before DAO takes over.
     *      This function should ideally be removed or restricted to DAO only after initial setup.
     */
    function setSystemParameters(
        uint256 _minStakeForOperator,
        uint256 _predictionRewardAmount,
        uint256 _validationRewardAmount,
        int256 _maliciousActorReputationPenalty,
        int256 _successfulPredictionReputationBonus,
        int256 _successfulValidationReputationBonus,
        uint256 _performanceRewardRate
    ) external onlyOwner {
        minStakeForOperator = _minStakeForOperator;
        predictionRewardAmount = _predictionRewardAmount;
        validationRewardAmount = _validationRewardAmount;
        maliciousActorReputationPenalty = _maliciousActorReputationPenalty;
        successfulPredictionReputationBonus = _successfulPredictionReputationBonus;
        successfulValidationReputationBonus = _successfulValidationReputationBonus;
        performanceRewardRate = _performanceRewardRate;
    }
}
```