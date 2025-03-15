```solidity
/**
 * @title Decentralized AI Prediction Marketplace with Data Contribution & Reputation
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized marketplace for AI predictions,
 * incorporating data contribution from users and a reputation system for predictors and data providers.
 * It allows users to create prediction markets, submit predictions based on available data,
 * contribute data to improve prediction accuracy, and earn rewards based on prediction outcomes
 * and data quality. The contract also features a reputation system to incentivize honest and
 * high-quality contributions.
 *
 * **Outline:**
 *
 * **1. State Variables:**
 *    - Contract Owner
 *    - Prediction Markets (mapping of market IDs to market details)
 *    - Predictions (mapping of prediction IDs to prediction details)
 *    - Data Sets (mapping of data set IDs to data set details)
 *    - Predictor Reputations (mapping of addresses to reputation scores)
 *    - Data Provider Reputations (mapping of addresses to reputation scores)
 *    - Fee for market creation
 *    - Fee for data access
 *    - Resolution Oracle Address
 *    - Contract Paused State
 *
 * **2. Events:**
 *    - MarketCreated
 *    - PredictionSubmitted
 *    - DataContributed
 *    - PredictionResolved
 *    - RewardsDistributed
 *    - ReputationUpdated
 *    - DataAccessPurchased
 *    - ContractPaused
 *    - ContractUnpaused
 *    - FeeUpdated
 *    - OracleUpdated
 *
 * **3. Modifiers:**
 *    - onlyOwner
 *    - whenNotPaused
 *    - whenPaused
 *    - marketExists
 *    - predictionExists
 *    - dataSetExists
 *    - onlyResolutionOracle
 *
 * **4. Functions:**
 *
 *    **Market Management:**
 *    - createPredictionMarket(string _marketTitle, string _marketDescription, uint256 _resolutionTimestamp, uint256 _dataAccessCost, uint256 _rewardPool)
 *    - cancelPredictionMarket(uint256 _marketId)
 *    - getMarketDetails(uint256 _marketId)
 *    - getActiveMarkets()
 *    - getPastMarkets()
 *
 *    **Prediction Submission:**
 *    - submitPrediction(uint256 _marketId, string _predictionData, uint256 _dataAccessId)
 *    - getPredictionDetails(uint256 _predictionId)
 *    - getUserPredictionsForMarket(uint256 _marketId, address _user)
 *
 *    **Data Contribution & Access:**
 *    - contributeData(uint256 _marketId, string _dataDescription, string _dataHash, uint256 _qualityScore)
 *    - getDataDetails(uint256 _dataSetId)
 *    - purchaseDataAccess(uint256 _dataSetId)
 *    - getDataSetsForMarket(uint256 _marketId)
 *
 *    **Resolution & Rewards:**
 *    - resolvePredictionMarket(uint256 _marketId, string _resolutionData) (Oracle Function)
 *    - distributeRewards(uint256 _marketId) (Internal Function called by resolvePredictionMarket)
 *    - withdrawRewards()
 *
 *    **Reputation Management:**
 *    - getPredictorReputation(address _predictor)
 *    - getDataProviderReputation(address _dataProvider)
 *    - reportInaccuratePrediction(uint256 _predictionId)
 *    - reportLowQualityData(uint256 _dataSetId)
 *    - updateReputationScore(address _user, int256 _scoreChange) (Internal Function)
 *
 *    **Admin & Utility:**
 *    - setMarketCreationFee(uint256 _newFee) (Owner Function)
 *    - setDataAccessFee(uint256 _newFee) (Owner Function)
 *    - setResolutionOracle(address _newOracle) (Owner Function)
 *    - pauseContract() (Owner Function)
 *    - unpauseContract() (Owner Function)
 *    - getContractBalance()
 *    - getPredictionCount()
 *    - getDataSetCount()
 */

pragma solidity ^0.8.0;

contract AIPredictionMarketplace {
    // State Variables
    address public owner;
    uint256 public marketCreationFee;
    uint256 public dataAccessFee;
    address public resolutionOracle;
    bool public paused;

    uint256 public nextMarketId;
    uint256 public nextPredictionId;
    uint256 public nextDataSetId;

    struct PredictionMarket {
        uint256 marketId;
        string marketTitle;
        string marketDescription;
        uint256 resolutionTimestamp;
        uint256 dataAccessCost;
        uint256 rewardPool;
        address creator;
        bool isActive;
        bool isResolved;
        string resolutionData;
        uint256 dataSetCount;
        uint256 predictionCount;
    }
    mapping(uint256 => PredictionMarket) public predictionMarkets;

    struct Prediction {
        uint256 predictionId;
        uint256 marketId;
        address predictor;
        string predictionData;
        uint256 dataSetId; // Data set used for prediction (optional)
        bool isCorrect;
        bool reportedInaccurate;
    }
    mapping(uint256 => Prediction) public predictions;

    struct DataSet {
        uint256 dataSetId;
        uint256 marketId;
        address dataProvider;
        string dataDescription;
        string dataHash; // IPFS hash or similar for data storage
        uint256 qualityScore;
        uint256 accessCost;
        uint256 purchaseCount;
        bool reportedLowQuality;
    }
    mapping(uint256 => DataSet) public dataSets;

    mapping(address => int256) public predictorReputations;
    mapping(address => int256) public dataProviderReputations;

    // Events
    event MarketCreated(uint256 marketId, string marketTitle, address creator);
    event PredictionSubmitted(uint256 predictionId, uint256 marketId, address predictor);
    event DataContributed(uint256 dataSetId, uint256 marketId, address dataProvider);
    event PredictionResolved(uint256 marketId, string resolutionData);
    event RewardsDistributed(uint256 marketId);
    event ReputationUpdated(address user, int256 newScore);
    event DataAccessPurchased(uint256 dataSetId, address purchaser);
    event ContractPaused();
    event ContractUnpaused();
    event FeeUpdated(string feeType, uint256 newFee);
    event OracleUpdated(address newOracle);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier marketExists(uint256 _marketId) {
        require(predictionMarkets[_marketId].marketId == _marketId, "Market does not exist.");
        _;
    }

    modifier predictionExists(uint256 _predictionId) {
        require(predictions[_predictionId].predictionId == _predictionId, "Prediction does not exist.");
        _;
    }

    modifier dataSetExists(uint256 _dataSetId) {
        require(dataSets[_dataSetId].dataSetId == _dataSetId, "Data set does not exist.");
        _;
    }

    modifier onlyResolutionOracle() {
        require(msg.sender == resolutionOracle, "Only resolution oracle can call this function.");
        _;
    }

    // Constructor
    constructor(uint256 _initialMarketCreationFee, uint256 _initialDataAccessFee, address _initialResolutionOracle) {
        owner = msg.sender;
        marketCreationFee = _initialMarketCreationFee;
        dataAccessFee = _initialDataAccessFee;
        resolutionOracle = _initialResolutionOracle;
        paused = false;
        nextMarketId = 1;
        nextPredictionId = 1;
        nextDataSetId = 1;
    }

    // -------- Market Management Functions --------

    /// @notice Creates a new prediction market.
    /// @param _marketTitle Title of the prediction market.
    /// @param _marketDescription Description of the prediction market.
    /// @param _resolutionTimestamp Timestamp at which the market will be resolved.
    /// @param _dataAccessCost Cost to access data sets associated with this market.
    /// @param _rewardPool Initial reward pool for the market.
    function createPredictionMarket(
        string memory _marketTitle,
        string memory _marketDescription,
        uint256 _resolutionTimestamp,
        uint256 _dataAccessCost,
        uint256 _rewardPool
    ) external payable whenNotPaused {
        require(msg.value >= marketCreationFee, "Insufficient market creation fee.");
        require(_resolutionTimestamp > block.timestamp, "Resolution timestamp must be in the future.");
        require(_rewardPool > 0, "Reward pool must be greater than zero.");

        predictionMarkets[nextMarketId] = PredictionMarket({
            marketId: nextMarketId,
            marketTitle: _marketTitle,
            marketDescription: _marketDescription,
            resolutionTimestamp: _resolutionTimestamp,
            dataAccessCost: _dataAccessCost,
            rewardPool: _rewardPool,
            creator: msg.sender,
            isActive: true,
            isResolved: false,
            resolutionData: "",
            dataSetCount: 0,
            predictionCount: 0
        });

        emit MarketCreated(nextMarketId, _marketTitle, msg.sender);
        nextMarketId++;

        // Refund extra fee if paid more than required
        if (msg.value > marketCreationFee) {
            payable(msg.sender).transfer(msg.value - marketCreationFee);
        }
    }

    /// @notice Cancels a prediction market before resolution. Only market creator can cancel. Funds are returned.
    /// @param _marketId ID of the market to cancel.
    function cancelPredictionMarket(uint256 _marketId) external marketExists(_marketId) whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.creator == msg.sender, "Only market creator can cancel.");
        require(market.isActive, "Market is not active.");
        require(!market.isResolved, "Market is already resolved.");

        market.isActive = false;

        // Return the reward pool and market creation fee to the creator
        payable(market.creator).transfer(market.rewardPool + marketCreationFee);
        market.rewardPool = 0; // Reset reward pool to avoid double payout

        // Consider refunding prediction fees if applicable (if implemented)

        // TODO: Handle refunds for data access purchases if needed.
    }

    /// @notice Retrieves details of a specific prediction market.
    /// @param _marketId ID of the market.
    /// @return Market details.
    function getMarketDetails(uint256 _marketId) external view marketExists(_marketId)
        returns (
            uint256 marketId,
            string memory marketTitle,
            string memory marketDescription,
            uint256 resolutionTimestamp,
            uint256 dataAccessCost,
            uint256 rewardPool,
            address creator,
            bool isActive,
            bool isResolved,
            string memory resolutionData,
            uint256 dataSetCount,
            uint256 predictionCount
        )
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        return (
            market.marketId,
            market.marketTitle,
            market.marketDescription,
            market.resolutionTimestamp,
            market.dataAccessCost,
            market.rewardPool,
            market.creator,
            market.isActive,
            market.isResolved,
            market.resolutionData,
            market.dataSetCount,
            market.predictionCount
        );
    }

    /// @notice Retrieves a list of active prediction market IDs.
    /// @return Array of active market IDs.
    function getActiveMarkets() external view returns (uint256[] memory) {
        uint256[] memory activeMarketIds = new uint256[](nextMarketId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextMarketId; i++) {
            if (predictionMarkets[i].isActive && !predictionMarkets[i].isResolved) {
                activeMarketIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active markets
        assembly { // Inline assembly for efficient array resizing
            mstore(activeMarketIds, count)
        }
        return activeMarketIds;
    }

    /// @notice Retrieves a list of past (resolved or cancelled) prediction market IDs.
    /// @return Array of past market IDs.
    function getPastMarkets() external view returns (uint256[] memory) {
        uint256[] memory pastMarketIds = new uint256[](nextMarketId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextMarketId; i++) {
            if (!predictionMarkets[i].isActive || predictionMarkets[i].isResolved) {
                pastMarketIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(activeMarketIds, count)
        }
        return pastMarketIds;
    }


    // -------- Prediction Submission Functions --------

    /// @notice Submits a prediction for a given market.
    /// @param _marketId ID of the market to predict on.
    /// @param _predictionData Data representing the prediction (e.g., JSON, string, etc.).
    /// @param _dataAccessId ID of the data set used for prediction (0 if no specific data set used).
    function submitPrediction(uint256 _marketId, string memory _predictionData, uint256 _dataAccessId) external whenNotPaused marketExists(_marketId) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.isActive, "Market is not active.");
        require(!market.isResolved, "Market is already resolved.");
        require(block.timestamp < market.resolutionTimestamp, "Prediction submission time expired.");

        // Optional: Check if data access is required and if user has purchased it.
        if (market.dataAccessCost > 0 && _dataAccessId > 0) {
            DataSet storage dataSet = dataSets[_dataAccessId];
            require(dataSet.marketId == _marketId, "Data set is not for this market.");
            // In a real implementation, you might track data access purchases and verify here.
            // For simplicity, we skip explicit purchase tracking in this example.
        }

        predictions[nextPredictionId] = Prediction({
            predictionId: nextPredictionId,
            marketId: _marketId,
            predictor: msg.sender,
            predictionData: _predictionData,
            dataSetId: _dataAccessId,
            isCorrect: false,
            reportedInaccurate: false
        });

        market.predictionCount++;
        emit PredictionSubmitted(nextPredictionId, _marketId, msg.sender);
        nextPredictionId++;
    }

    /// @notice Retrieves details of a specific prediction.
    /// @param _predictionId ID of the prediction.
    /// @return Prediction details.
    function getPredictionDetails(uint256 _predictionId) external view predictionExists(_predictionId)
        returns (
            uint256 predictionId,
            uint256 marketId,
            address predictor,
            string memory predictionData,
            uint256 dataSetId,
            bool isCorrect,
            bool reportedInaccurate
        )
    {
        Prediction storage prediction = predictions[_predictionId];
        return (
            prediction.predictionId,
            prediction.marketId,
            prediction.predictor,
            prediction.predictionData,
            prediction.dataSetId,
            prediction.isCorrect,
            prediction.reportedInaccurate
        );
    }

    /// @notice Retrieves a list of predictions made by a user for a specific market.
    /// @param _marketId ID of the market.
    /// @param _user Address of the user.
    /// @return Array of prediction IDs made by the user for the market.
    function getUserPredictionsForMarket(uint256 _marketId, address _user) external view marketExists(_marketId) returns (uint256[] memory) {
        uint256[] memory userPredictionIds = new uint256[](predictionMarkets[_marketId].predictionCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].marketId == _marketId && predictions[i].predictor == _user) {
                userPredictionIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(userPredictionIds, count)
        }
        return userPredictionIds;
    }


    // -------- Data Contribution & Access Functions --------

    /// @notice Allows users to contribute data to a prediction market.
    /// @param _marketId ID of the market for which data is contributed.
    /// @param _dataDescription Description of the data set.
    /// @param _dataHash Hash of the data set (e.g., IPFS CID).
    /// @param _qualityScore Score representing the quality of the data (e.g., 1-10).
    function contributeData(
        uint256 _marketId,
        string memory _dataDescription,
        string memory _dataHash,
        uint256 _qualityScore
    ) external whenNotPaused marketExists(_marketId) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.isActive, "Market is not active.");
        require(!market.isResolved, "Market is already resolved.");

        dataSets[nextDataSetId] = DataSet({
            dataSetId: nextDataSetId,
            marketId: _marketId,
            dataProvider: msg.sender,
            dataDescription: _dataDescription,
            dataHash: _dataHash,
            qualityScore: _qualityScore,
            accessCost: market.dataAccessCost, // Inherit market's data access cost
            purchaseCount: 0,
            reportedLowQuality: false
        });

        market.dataSetCount++;
        emit DataContributed(nextDataSetId, _marketId, msg.sender);
        nextDataSetId++;

        // Optionally reward data provider based on quality score and market parameters.
        // Example: updateReputationScore(msg.sender, int256(_qualityScore));
    }

    /// @notice Retrieves details of a specific data set.
    /// @param _dataSetId ID of the data set.
    /// @return Data set details.
    function getDataDetails(uint256 _dataSetId) external view dataSetExists(_dataSetId)
        returns (
            uint256 dataSetId,
            uint256 marketId,
            address dataProvider,
            string memory dataDescription,
            string memory dataHash,
            uint256 qualityScore,
            uint256 accessCost,
            uint256 purchaseCount,
            bool reportedLowQuality
        )
    {
        DataSet storage dataSet = dataSets[_dataSetId];
        return (
            dataSet.dataSetId,
            dataSet.marketId,
            dataSet.dataProvider,
            dataSet.dataDescription,
            dataSet.dataHash,
            dataSet.qualityScore,
            dataSet.accessCost,
            dataSet.purchaseCount,
            dataSet.reportedLowQuality
        );
    }

    /// @notice Allows a user to purchase access to a data set.
    /// @param _dataSetId ID of the data set to purchase access to.
    function purchaseDataAccess(uint256 _dataSetId) external payable whenNotPaused dataSetExists(_dataSetId) {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(msg.value >= dataSet.accessCost, "Insufficient data access fee.");

        dataSet.purchaseCount++;
        emit DataAccessPurchased(_dataSetId, msg.sender);

        // Transfer funds to the data provider (or market creator, depending on business logic)
        payable(dataSet.dataProvider).transfer(dataSet.accessCost);

        // Refund extra fee if paid more than required
        if (msg.value > dataSet.accessCost) {
            payable(msg.sender).transfer(msg.value - dataSet.accessCost);
        }
    }

    /// @notice Retrieves a list of data set IDs associated with a specific market.
    /// @param _marketId ID of the market.
    /// @return Array of data set IDs for the market.
    function getDataSetsForMarket(uint256 _marketId) external view marketExists(_marketId) returns (uint256[] memory) {
        uint256[] memory dataSetIds = new uint256[](predictionMarkets[_marketId].dataSetCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextDataSetId; i++) {
            if (dataSets[i].marketId == _marketId) {
                dataSetIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(dataSetIds, count)
        }
        return dataSetIds;
    }


    // -------- Resolution & Rewards Functions --------

    /// @notice Resolves a prediction market and sets the resolution data. Only callable by the resolution oracle.
    /// @param _marketId ID of the market to resolve.
    /// @param _resolutionData Data representing the market outcome (e.g., JSON, string, etc.).
    function resolvePredictionMarket(uint256 _marketId, string memory _resolutionData) external onlyResolutionOracle whenNotPaused marketExists(_marketId) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.isActive, "Market is not active.");
        require(!market.isResolved, "Market is already resolved.");
        require(block.timestamp >= market.resolutionTimestamp, "Resolution timestamp not reached yet.");

        market.isActive = false;
        market.isResolved = true;
        market.resolutionData = _resolutionData;

        emit PredictionResolved(_marketId, _resolutionData);

        distributeRewards(_marketId); // Distribute rewards to correct predictors
    }

    /// @notice Internal function to distribute rewards to correct predictors after market resolution.
    /// @param _marketId ID of the resolved market.
    function distributeRewards(uint256 _marketId) internal marketExists(_marketId) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.isResolved, "Market is not resolved yet.");
        require(market.rewardPool > 0, "Reward pool is empty.");

        uint256 correctPredictionCount = 0;
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].marketId == _marketId) {
                // In a real implementation, determine if prediction is correct based on _resolutionData
                // This is a simplified example, assuming all predictions are considered "correct" for reward distribution.
                // **Crucially, you need to implement logic to compare predictions against resolution data to determine correctness.**
                predictions[i].isCorrect = true; // Placeholder: Replace with actual correctness check
                if (predictions[i].isCorrect) {
                    correctPredictionCount++;
                }
            }
        }

        if (correctPredictionCount > 0) {
            uint256 rewardPerPredictor = market.rewardPool / correctPredictionCount;
            uint256 remainingReward = market.rewardPool % correctPredictionCount; // Handle remainder

            for (uint256 i = 1; i < nextPredictionId; i++) {
                if (predictions[i].marketId == _marketId && predictions[i].isCorrect) {
                    payable(predictions[i].predictor).transfer(rewardPerPredictor);
                    updateReputationScore(predictions[i].predictor, 5); // Example: Reward reputation for correct prediction
                }
            }
            // Optionally handle remainingReward (e.g., return to market creator, burn, etc.)
            if (remainingReward > 0) {
                payable(market.creator).transfer(remainingReward); // Example: Return remainder to market creator
            }
        }

        market.rewardPool = 0; // Reset reward pool after distribution
        emit RewardsDistributed(_marketId);
    }

    /// @notice Allows users to withdraw their earned rewards (currently implemented as immediate transfer in distributeRewards).
    /// In a more complex system, you might track individual user balances and allow separate withdrawals.
    function withdrawRewards() external payable {
        // In this simplified example, rewards are distributed directly in `distributeRewards`.
        // In a real-world scenario, you might have a separate function to track and withdraw balances.
        revert("Reward withdrawal is handled automatically upon market resolution in this example.");
    }


    // -------- Reputation Management Functions --------

    /// @notice Gets the reputation score of a predictor.
    /// @param _predictor Address of the predictor.
    /// @return Reputation score of the predictor.
    function getPredictorReputation(address _predictor) external view returns (int256) {
        return predictorReputations[_predictor];
    }

    /// @notice Gets the reputation score of a data provider.
    /// @param _dataProvider Address of the data provider.
    /// @return Reputation score of the data provider.
    function getDataProviderReputation(address _dataProvider) external view returns (int256) {
        return dataProviderReputations[_dataProvider];
    }

    /// @notice Allows users to report a prediction as inaccurate. May decrease predictor's reputation.
    /// @param _predictionId ID of the prediction to report.
    function reportInaccuratePrediction(uint256 _predictionId) external predictionExists(_predictionId) whenNotPaused {
        Prediction storage prediction = predictions[_predictionId];
        require(!prediction.reportedInaccurate, "Prediction already reported as inaccurate.");
        prediction.reportedInaccurate = true;

        // Implement logic to verify the report and potentially penalize the predictor's reputation.
        // This could involve voting, oracle verification, or admin review.
        // For simplicity, we directly decrease reputation in this example.
        updateReputationScore(prediction.predictor, -2); // Example: Decrease reputation by 2
    }

    /// @notice Allows users to report a data set as low quality. May decrease data provider's reputation.
    /// @param _dataSetId ID of the data set to report.
    function reportLowQualityData(uint256 _dataSetId) external dataSetExists(_dataSetId) whenNotPaused {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(!dataSet.reportedLowQuality, "Data set already reported as low quality.");
        dataSet.reportedLowQuality = true;

        // Implement logic to verify the report and potentially penalize the data provider's reputation.
        // Similar to inaccurate prediction reporting, this could involve voting, oracle verification, or admin review.
        // For simplicity, we directly decrease reputation in this example.
        updateReputationScore(dataSet.dataProvider, -3); // Example: Decrease reputation by 3
    }

    /// @notice Internal function to update a user's reputation score.
    /// @param _user Address of the user.
    /// @param _scoreChange Amount to change the reputation score by (positive or negative).
    function updateReputationScore(address _user, int256 _scoreChange) internal {
        if (msg.sender == this) { // Only allow reputation updates from within the contract
            if (isPredictor(_user)) {
                predictorReputations[_user] += _scoreChange;
            } else if (isDataProvider(_user)) {
                dataProviderReputations[_user] += _scoreChange;
            }
            emit ReputationUpdated(_user, predictorReputations[_user] + dataProviderReputations[_user]);
        }
    }

    // Helper functions to determine if an address is a predictor or data provider
    function isPredictor(address _user) internal view returns (bool) {
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (predictions[i].predictor == _user) {
                return true;
            }
        }
        return false;
    }

    function isDataProvider(address _user) internal view returns (bool) {
        for (uint256 i = 1; i < nextDataSetId; i++) {
            if (dataSets[i].dataProvider == _user) {
                return true;
            }
        }
        return false;
    }


    // -------- Admin & Utility Functions --------

    /// @notice Sets the fee required to create a prediction market. Only callable by the contract owner.
    /// @param _newFee New market creation fee.
    function setMarketCreationFee(uint256 _newFee) external onlyOwner {
        marketCreationFee = _newFee;
        emit FeeUpdated("Market Creation Fee", _newFee);
    }

    /// @notice Sets the fee required to access data sets. Only callable by the contract owner.
    /// @param _newFee New data access fee.
    function setDataAccessFee(uint256 _newFee) external onlyOwner {
        dataAccessFee = _newFee;
        emit FeeUpdated("Data Access Fee", _newFee);
    }

    /// @notice Sets the address of the resolution oracle. Only callable by the contract owner.
    /// @param _newOracle Address of the new resolution oracle.
    function setResolutionOracle(address _newOracle) external onlyOwner {
        resolutionOracle = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    /// @notice Pauses the contract, preventing most functions from being called. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Gets the contract's current balance.
    /// @return Contract balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the total number of predictions submitted to the contract.
    /// @return Total prediction count.
    function getPredictionCount() external view returns (uint256) {
        return nextPredictionId - 1;
    }

    /// @notice Gets the total number of data sets contributed to the contract.
    /// @return Total data set count.
    function getDataSetCount() external view returns (uint256) {
        return nextDataSetId - 1;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```