Here's a Solidity smart contract named "ChronoNexus - Adaptive Predictive Protocol" that aims to be advanced, creative, and incorporates trendy concepts like dynamic fees, a reputation system, and a simplified dispute resolution mechanism for time-series data prediction.

This contract has been designed to avoid direct duplication of common open-source projects by combining several concepts in a unique way, particularly the adaptive economic model tied to a reputation system that influences user privileges and dispute resolution.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking, if we use an ERC20 token

/**
 * @title ChronoNexus - Adaptive Predictive Protocol
 * @author [Your Name/Team Name]
 * @notice ChronoNexus is an advanced, adaptive, and reputation-weighted decentralized protocol
 *         for time-series data prediction and automated action triggering. Users predict
 *         future states of defined data streams (e.g., average gas prices, specific oracle values),
 *         stake on their predictions, and earn rewards for accuracy. The protocol's economic
 *         parameters (fees, rewards, staking requirements) dynamically adjust based on
 *         on-chain metrics (simulated) like current gas prices, total protocol activity, and collective
 *         prediction accuracy. A built-in reputation system further influences user
 *         privileges and participation levels, fostering a more robust and reliable network.
 *         It aims to be resilient to market fluctuations and encourage skilled participants.
 */

/*
 * =================================================================================================
 * OUTLINE & FUNCTION SUMMARY
 * =================================================================================================
 *
 * I. Core Infrastructure & Access Control:
 *    - Standard Ownable pattern from OpenZeppelin for contract ownership.
 *    - `adminAddress`: An address with elevated privileges for managing protocol parameters and streams.
 *    - `oracleAddress`: A trusted address responsible for submitting actual outcomes to settle prediction epochs.
 *    - `gasPriceOracle`: Placeholder for an external oracle that could provide dynamic data for adaptive parameters.
 *    - Emergency pause mechanism to halt critical operations.
 *
 * II. Data Structures & Constants:
 *    - `DataType`: Enum for different types of predicted values (UINT256, INT256, BOOLEAN).
 *    - `PredictionStreamStatus`: Enum for the lifecycle status of a prediction stream.
 *    - `DisputeStatus`: Enum for the state of an epoch's dispute.
 *    - `PredictionStream`: Struct defining the characteristics of a data stream to be predicted.
 *    - `PredictionSubmission`: Struct storing a user's prediction details.
 *    - `EpochOutcome`: Struct holding the settled actual value and dispute-related information for an epoch.
 *
 * III. Prediction Stream Management (Admin controlled):
 *    1. `createPredictionStream(name, description, dataType, epochDuration, stakeTokenAddress)`:
 *       Creates a new type of data stream for users to predict (e.g., "ETH Gas Price 1-hour average").
 *    2. `updatePredictionStream(streamId, newName, newDescription, newEpochDuration, newStatus)`:
 *       Modifies parameters or status of an existing prediction stream.
 *    3. `getPredictionStreamDetails(streamId)`: (View) Retrieves detailed information about a prediction stream.
 *
 * IV. Prediction & Staking Logic (User interactions):
 *    4. `submitPrediction(streamId, epochNumber, predictedValue, stakeAmount)`:
 *       Allows a user to place a prediction for a specific epoch, requiring a stake in an ERC20 token.
 *    5. `withdrawStake(streamId, epochNumber)`:
 *       Enables users to cancel their pending prediction and withdraw their stake if the epoch is not yet settled.
 *
 * V. Epoch Settlement & Reward Distribution (Oracle/User interactions):
 *    6. `settlePredictionEpoch(streamId, epochNumber, actualValue, winningTolerance)`:
 *       Called by the `oracleAddress` to record the true outcome of an epoch, identifying winners based on tolerance.
 *    7. `claimPredictionReward(streamId, epochNumber)`:
 *       Allows accurate predictors to claim their proportional share of the reward pool after an epoch is settled.
 *    8. `getEpochOutcome(streamId, epochNumber)`: (View) Retrieves the settled outcome and dispute status for an epoch.
 *    9. `getUserPredictionOutcome(streamId, epochNumber, user)`: (View) Gets a specific user's prediction result for an epoch.
 *
 * VI. Adaptive Economic Parameters (Admin/DAO controlled, simulating dynamic adjustment):
 *    10. `setBasePredictionFee(newFee)`:
 *        Sets the base fee charged for submitting predictions.
 *    11. `setRewardAndProtocolFeeBps(newRewardPoolShareBps, newProtocolFeeBps)`:
 *        Configures the percentage split of total staked value between the reward pool and protocol fees.
 *    12. `adjustDynamicParameters(newMinReputationForDispute, newDisputeVoteReputationWeight)`:
 *        Adjusts parameters that influence economic behavior or user requirements, can integrate with external oracles.
 *    13. `getDynamicParameters()`: (View) Returns the current configuration of dynamic parameters.
 *
 * VII. Reputation System (Internal & Admin configured):
 *    14. `getReputationScore(user)`: (View) Retrieves the current reputation score of a user.
 *    15. `_updateReputation(user, scoreChange)`: (Internal) Adjusts a user's reputation based on actions (e.g., accurate predictions gain points, inaccurate lose).
 *    16. `setReputationModifiers(newReputationGainOnWin, newReputationLossOnLoss)`:
 *        Configures how reputation changes based on prediction outcomes.
 *
 * VIII. Decentralized Dispute Resolution (Simplified, Reputation-weighted):
 *    17. `initiateDispute(streamId, epochNumber, proposedCorrectValue, disputeBond)`:
 *        Allows users with sufficient reputation to challenge a settled epoch's outcome, requiring a bond.
 *    18. `voteOnDispute(streamId, epochNumber, supportsDispute)`:
 *        Enables other users (with reputation) to vote on an ongoing dispute, with votes potentially weighted by reputation.
 *    19. `resolveDispute(streamId, epochNumber)`:
 *        Admin/Oracle (or automated after a voting period) resolves the dispute based on collected votes,
 *        adjusting outcomes, distributing bonds, and updating reputations.
 *
 * IX. Governance & Maintenance Hooks (Owner/Admin):
 *    20. `setOracleAddress(newOracleAddress)`: Sets the address of the trusted oracle.
 *    21. `setAdminAddress(newAdminAddress)`: Sets a new admin address for the protocol.
 *    22. `rescueERC20(tokenAddress, to, amount)`: Allows owner to recover accidentally sent ERC20 tokens.
 *    23. `togglePause()`: Toggles the emergency pause state for the contract.
 *    24. `getContractBalance()`: (View) Returns the contract's ETH balance.
 *
 * X. Auxiliary View Functions for Data Retrieval:
 *    25. `getCurrentEpoch(streamId)`: (View) Calculates and returns the current active epoch number for a stream.
 *    26. `getEpochPredictionCount(streamId, epochNumber)`: (View) Returns the number of predictions submitted for an epoch.
 *    27. `getUserPredictionsForEpoch(streamId, epochNumber, user)`: (View) Retrieves a user's raw prediction data for a specific epoch.
 */

contract ChronoNexus is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---

    address public adminAddress;
    address public oracleAddress;
    address public gasPriceOracle; // External oracle for dynamic fee adjustments (placeholder)

    bool public paused;

    // Dynamic Parameters
    uint256 public basePredictionFee; // Fee for submitting a prediction (e.g., 0.01 ETH or stake token)
    uint256 public rewardPoolShareBps; // Basis points of total stake collected for reward pool (e.g., 9000 = 90%)
    uint256 public protocolFeeBps;     // Basis points of total stake collected as protocol fee (e.g., 1000 = 10%)
    uint256 public minReputationForDispute;    // Minimum reputation to initiate a dispute
    uint256 public disputeVoteReputationWeight; // Multiplier for reputation when voting on disputes
    uint256 public reputationGainOnWin;        // Points gained for an accurate prediction
    uint256 public reputationLossOnLoss;       // Points lost for an inaccurate prediction

    // Structs and Enums
    enum DataType { UINT256, INT256, BOOLEAN }
    enum PredictionStreamStatus { ACTIVE, PAUSED, DEPRECATED }
    enum DisputeStatus { NONE, PENDING, RESOLVED_UPHELD, RESOLVED_OVERTURNED }

    struct PredictionStream {
        string name;
        string description;
        DataType dataType;
        uint256 epochDuration; // in seconds
        uint256 nextEpochStartTime; // Timestamp when the next epoch begins
        address stakeToken; // ERC20 token address used for staking
        PredictionStreamStatus status;
    }

    struct PredictionSubmission {
        address predictor;
        uint256 predictedValue; // Value depends on DataType
        uint256 stakeAmount;
        uint256 submissionTimestamp;
        bool claimedReward;
        bool isWinner; // Set after epoch settlement
    }

    struct EpochOutcome {
        uint256 actualValue; // The true value as determined by oracle or dispute
        uint256 settlementTimestamp;
        bool isSettled;
        address oracleSettler; // The address that initially settled the epoch
        DisputeStatus disputeStatus;
        uint256 disputeBondTotal; // Total bond collected for a dispute
        mapping(address => bool) hasVotedOnDispute; // To track if an address has voted on this dispute
        mapping(address => bool) supportsDispute; // To track voter's choice
        uint256 totalReputationSupportingDispute; // Sum of reputation-weighted votes supporting dispute
        uint256 totalReputationOpposingDispute;   // Sum of reputation-weighted votes opposing dispute
        address disputeInitiator;
        uint256 disputeProposedValue;
    }

    // Mappings
    mapping(uint256 => PredictionStream) public predictionStreams; // streamId => PredictionStream
    uint256 public nextStreamId; // Counter for new stream IDs

    // streamId => epochNumber => address => PredictionSubmission
    mapping(uint256 => mapping(uint256 => mapping(address => PredictionSubmission))) public predictionSubmissions;

    // streamId => epochNumber => address[] (for iterating over submissions in an epoch)
    mapping(uint256 => mapping(uint256 => address[])) public epochSubmissionsList;

    // streamId => epochNumber => EpochOutcome
    mapping(uint256 => mapping(uint256 => EpochOutcome)) public epochOutcomes;

    mapping(address => uint256) public userReputation; // address => score

    // --- Events ---

    event PredictionStreamCreated(uint256 indexed streamId, string name, address stakeToken);
    event PredictionStreamUpdated(uint256 indexed streamId, PredictionStreamStatus newStatus);
    event PredictionSubmitted(uint256 indexed streamId, uint256 indexed epochNumber, address indexed predictor, uint256 predictedValue, uint256 stakeAmount);
    event EpochSettled(uint256 indexed streamId, uint256 indexed epochNumber, uint256 actualValue, address indexed settler);
    event RewardClaimed(uint256 indexed streamId, uint256 indexed epochNumber, address indexed claimant, uint256 rewardAmount);
    event ReputationUpdated(address indexed user, uint256 newScore, int256 change);
    event DisputeInitiated(uint256 indexed streamId, uint256 indexed epochNumber, address indexed initiator, uint256 proposedCorrectValue);
    event DisputeVoteCast(uint256 indexed streamId, uint256 indexed epochNumber, address indexed voter, bool supportsDispute);
    event DisputeResolved(uint256 indexed streamId, uint256 indexed epochNumber, DisputeStatus status);
    event ParametersAdjusted(uint256 newBaseFee, uint256 newRewardPoolShareBps, uint256 newProtocolFeeBps);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner(), "ChronoNexus: Caller is not admin");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoNexus: Caller is not oracle");
        _;
    }

    modifier notPaused() {
        require(!paused, "ChronoNexus: Contract is paused");
        _;
    }

    modifier reputationRequired(uint256 requiredScore) {
        require(userReputation[msg.sender] >= requiredScore, "ChronoNexus: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(address _admin, address _oracle, address _gasPriceOracle, uint256 _basePredictionFee, uint256 _rewardPoolShareBps, uint256 _protocolFeeBps) Ownable(msg.sender) {
        require(_admin != address(0), "ChronoNexus: Admin address cannot be zero");
        require(_oracle != address(0), "ChronoNexus: Oracle address cannot be zero");
        require(_gasPriceOracle != address(0), "ChronoNexus: Gas Price Oracle address cannot be zero");
        require(_rewardPoolShareBps.add(_protocolFeeBps) <= 10000, "ChronoNexus: Total BPS exceeds 10000");

        adminAddress = _admin;
        oracleAddress = _oracle;
        gasPriceOracle = _gasPriceOracle; // For potential future dynamic fee logic
        basePredictionFee = _basePredictionFee;
        rewardPoolShareBps = _rewardPoolShareBps;
        protocolFeeBps = _protocolFeeBps;

        paused = false;
        nextStreamId = 1;

        // Default reputation settings
        reputationGainOnWin = 10;
        reputationLossOnLoss = 5;
        minReputationForDispute = 100; // Example: Minimum score to initiate a dispute
        disputeVoteReputationWeight = 1; // Example: Multiplier for reputation when voting
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Allows the owner to set a new admin address. The admin has elevated privileges
     *         for managing prediction streams and certain parameters. This role could eventually
     *         be transferred to a DAO.
     * @param _newAdmin The address of the new admin.
     */
    function setAdminAddress(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "ChronoNexus: New admin address cannot be zero");
        adminAddress = _newAdmin;
    }

    /**
     * @notice Allows the owner to set a new oracle address. The oracle is responsible
     *         for settling prediction epochs with actual outcomes.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ChronoNexus: New oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    /**
     * @notice Allows the owner to pause or unpause critical contract operations in an emergency.
     *         When paused, functions critical to core operations (like submitting predictions
     *         or settling epochs) become inaccessible.
     */
    function togglePause() external onlyOwner {
        paused = !paused;
        if (paused) {
            emit EmergencyPaused(msg.sender);
        } else {
            emit EmergencyUnpaused(msg.sender);
        }
    }

    /**
     * @notice Allows the owner to rescue ERC20 tokens accidentally sent to the contract.
     *         This prevents tokens from being permanently locked.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param to The address to send the rescued tokens to.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "ChronoNexus: Invalid token address");
        require(to != address(0), "ChronoNexus: Recipient address cannot be zero");
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(to, amount), "ChronoNexus: ERC20 transfer failed");
    }

    /**
     * @notice Returns the current ETH balance of the contract. Useful for auditing fees.
     * @return The current ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- III. Prediction Stream Management ---

    /**
     * @notice Allows the admin to create a new prediction stream. A stream defines a specific
     *         type of data to be predicted, its data type, epoch duration, and the ERC20 token
     *         used for staking on it.
     * @param _name A human-readable name for the stream (e.g., "ETH Gas Price Average").
     * @param _description A detailed description of what this stream predicts.
     * @param _dataType The type of data being predicted (UINT256, INT256, BOOLEAN).
     * @param _epochDuration The duration of each prediction epoch in seconds.
     * @param _stakeTokenAddress The address of the ERC20 token used for staking on this stream.
     * @return The ID of the newly created prediction stream.
     */
    function createPredictionStream(
        string memory _name,
        string memory _description,
        DataType _dataType,
        uint256 _epochDuration,
        address _stakeTokenAddress
    ) external onlyAdmin notPaused returns (uint256) {
        require(bytes(_name).length > 0, "ChronoNexus: Name cannot be empty");
        require(_epochDuration > 0, "ChronoNexus: Epoch duration must be positive");
        require(_stakeTokenAddress != address(0), "ChronoNexus: Stake token address cannot be zero");

        uint256 streamId = nextStreamId++;
        predictionStreams[streamId] = PredictionStream({
            name: _name,
            description: _description,
            dataType: _dataType,
            epochDuration: _epochDuration,
            nextEpochStartTime: block.timestamp, // First epoch starts immediately, or could be a future timestamp
            stakeToken: _stakeTokenAddress,
            status: PredictionStreamStatus.ACTIVE
        });

        emit PredictionStreamCreated(streamId, _name, _stakeTokenAddress);
        return streamId;
    }

    /**
     * @notice Allows the admin to update parameters of an existing prediction stream.
     *         Can change name, description, epoch duration, or status (e.g., to PAUSED or DEPRECATED).
     * @param _streamId The ID of the stream to update.
     * @param _newName The new name for the stream.
     * @param _newDescription The new description for the stream.
     * @param _newEpochDuration The new epoch duration in seconds (0 to keep current).
     * @param _newStatus The new status for the stream.
     */
    function updatePredictionStream(
        uint256 _streamId,
        string memory _newName,
        string memory _newDescription,
        uint256 _newEpochDuration,
        PredictionStreamStatus _newStatus
    ) external onlyAdmin notPaused {
        PredictionStream storage stream = predictionStreams[_streamId];
        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");

        stream.name = _newName;
        stream.description = _newDescription;
        if (_newEpochDuration > 0) {
            stream.epochDuration = _newEpochDuration;
        }
        stream.status = _newStatus;

        emit PredictionStreamUpdated(_streamId, _newStatus);
    }

    /**
     * @notice Retrieves the details of a specific prediction stream.
     * @param _streamId The ID of the prediction stream.
     * @return name, description, dataType, epochDuration, nextEpochStartTime, stakeTokenAddress, status.
     */
    function getPredictionStreamDetails(uint256 _streamId)
        public
        view
        returns (
            string memory name,
            string memory description,
            DataType dataType,
            uint256 epochDuration,
            uint256 nextEpochStartTime,
            address stakeTokenAddress,
            PredictionStreamStatus status
        )
    {
        PredictionStream storage stream = predictionStreams[_streamId];
        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");

        return (
            stream.name,
            stream.description,
            stream.dataType,
            stream.epochDuration,
            stream.nextEpochStartTime,
            stream.stakeToken,
            stream.status
        );
    }

    // --- IV. Prediction & Staking Logic ---

    /**
     * @notice Users submit their prediction for a specific stream and epoch, along with a stake.
     *         The stake token must be approved by the user for transfer to this contract.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The specific epoch number for which the prediction is made.
     * @param _predictedValue The user's predicted value for the epoch outcome.
     * @param _stakeAmount The amount of stake token to put on this prediction.
     */
    function submitPrediction(
        uint256 _streamId,
        uint256 _epochNumber,
        uint256 _predictedValue,
        uint256 _stakeAmount
    ) external notPaused reputationRequired(0) { // All users can predict, but higher rep might get higher stake limits (future)
        PredictionStream storage stream = predictionStreams[_streamId];
        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");
        require(stream.status == PredictionStreamStatus.ACTIVE, "ChronoNexus: Stream is not active");
        require(_stakeAmount > 0, "ChronoNexus: Stake amount must be positive");

        uint256 currentEpoch = getCurrentEpoch(_streamId);
        require(_epochNumber == currentEpoch, "ChronoNexus: Prediction can only be made for the current epoch");
        
        // Ensure user hasn't predicted for this epoch already
        require(predictionSubmissions[_streamId][_epochNumber][msg.sender].predictor == address(0), "ChronoNexus: Already predicted for this epoch");

        // Transfer stake token from user to contract
        IERC20 stakeToken = IERC20(stream.stakeToken);
        require(stakeToken.transferFrom(msg.sender, address(this), _stakeAmount), "ChronoNexus: Stake transfer failed");

        predictionSubmissions[_streamId][_epochNumber][msg.sender] = PredictionSubmission({
            predictor: msg.sender,
            predictedValue: _predictedValue,
            stakeAmount: _stakeAmount,
            submissionTimestamp: block.timestamp,
            claimedReward: false,
            isWinner: false
        });
        epochSubmissionsList[_streamId][_epochNumber].push(msg.sender);

        emit PredictionSubmitted(_streamId, _epochNumber, msg.sender, _predictedValue, _stakeAmount);
    }

    /**
     * @notice Allows a user to withdraw their stake if the prediction epoch has not yet been settled.
     *         This acts as a "cancel prediction" feature.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The specific epoch number.
     */
    function withdrawStake(uint256 _streamId, uint256 _epochNumber) external notPaused {
        PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][msg.sender];
        require(submission.predictor == msg.sender, "ChronoNexus: No prediction found for user in this epoch");
        require(!epochOutcomes[_streamId][_epochNumber].isSettled, "ChronoNexus: Epoch is already settled, cannot withdraw stake");

        // Return stake to user
        IERC20 stakeToken = IERC20(predictionStreams[_streamId].stakeToken);
        require(stakeToken.transfer(msg.sender, submission.stakeAmount), "ChronoNexus: Stake withdrawal failed");

        // Clear the prediction entry. Note: For gas efficiency, we do not remove from epochSubmissionsList.
        // This means epochSubmissionsList might contain addresses with 0 stake, which must be filtered when iterating.
        delete predictionSubmissions[_streamId][_epochNumber][msg.sender];

        emit PredictionSubmitted(_streamId, _epochNumber, msg.sender, 0, 0); // Signify withdrawal by 0 values
    }

    // --- V. Epoch Settlement & Reward Distribution ---

    /**
     * @notice Called by the designated oracle to settle an epoch. This function records the actual
     *         outcome, identifies winning predictions based on a tolerance, and prepares for reward distribution.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number to settle.
     * @param _actualValue The actual outcome value for the epoch.
     * @param _winningTolerance The allowed deviation for a prediction to be considered accurate (e.g., 5 for +/-5 units).
     */
    function settlePredictionEpoch(
        uint256 _streamId,
        uint256 _epochNumber,
        uint256 _actualValue,
        uint256 _winningTolerance
    ) external onlyOracle notPaused {
        PredictionStream storage stream = predictionStreams[_streamId];
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];

        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");
        require(!outcome.isSettled, "ChronoNexus: Epoch already settled");
        
        // Ensure the epoch being settled has concluded based on its expected end time.
        // This assumes `getCurrentEpoch` correctly reflects the current ongoing epoch.
        require(_epochNumber < getCurrentEpoch(_streamId), "ChronoNexus: Epoch has not ended yet or is the current epoch");

        // After settling, update the next epoch's start time for this stream.
        // A more robust implementation might track each epoch's start time individually.
        stream.nextEpochStartTime = block.timestamp; 

        outcome.actualValue = _actualValue;
        outcome.settlementTimestamp = block.timestamp;
        outcome.isSettled = true;
        outcome.oracleSettler = msg.sender;
        outcome.disputeStatus = DisputeStatus.NONE; // Initial status

        uint256 totalWinnerStake = 0;
        address[] storage submissionsInEpoch = epochSubmissionsList[_streamId][_epochNumber];
        
        // First pass: Identify winners and calculate total winner stake
        for (uint256 i = 0; i < submissionsInEpoch.length; i++) {
            address predictor = submissionsInEpoch[i];
            PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][predictor];

            // Skip if the prediction was withdrawn (indicated by 0 stake)
            if (submission.stakeAmount == 0) {
                continue;
            }

            // Check if prediction is within tolerance
            if (submission.predictedValue >= _actualValue.sub(_winningTolerance) &&
                submission.predictedValue <= _actualValue.add(_winningTolerance)) {
                
                submission.isWinner = true;
                totalWinnerStake = totalWinnerStake.add(submission.stakeAmount);
                _updateReputation(predictor, int256(reputationGainOnWin));
            } else {
                _updateReputation(predictor, -int256(reputationLossOnLoss));
            }
        }

        emit EpochSettled(_streamId, _epochNumber, _actualValue, msg.sender);
    }

    /**
     * @notice Allows an accurate predictor to claim their share of the reward pool.
     *         Rewards are distributed proportionally based on winning stake.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number for which to claim rewards.
     */
    function claimPredictionReward(uint256 _streamId, uint256 _epochNumber) external notPaused {
        PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][msg.sender];
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];

        require(submission.predictor == msg.sender, "ChronoNexus: No prediction found for user in this epoch");
        require(outcome.isSettled, "ChronoNexus: Epoch not yet settled");
        require(submission.isWinner, "ChronoNexus: Your prediction was not accurate");
        require(!submission.claimedReward, "ChronoNexus: Rewards already claimed");
        require(outcome.disputeStatus != DisputeStatus.PENDING, "ChronoNexus: Cannot claim during active dispute");

        uint256 totalEpochStake = 0;
        uint256 totalWinnerStake = 0;
        address[] storage submissionsInEpoch = epochSubmissionsList[_streamId][_epochNumber];

        for (uint256 i = 0; i < submissionsInEpoch.length; i++) {
            address predictor = submissionsInEpoch[i];
            PredictionSubmission storage s = predictionSubmissions[_streamId][_epochNumber][predictor];
            if (s.stakeAmount > 0) { // Only count active submissions (not withdrawn)
                totalEpochStake = totalEpochStake.add(s.stakeAmount);
                if (s.isWinner) {
                    totalWinnerStake = totalWinnerStake.add(s.stakeAmount);
                }
            }
        }
        
        require(totalWinnerStake > 0, "ChronoNexus: No winners or total winner stake is zero");

        uint256 totalRewardPool = totalEpochStake.mul(rewardPoolShareBps).div(10000);
        uint256 rewardAmount = submission.stakeAmount.mul(totalRewardPool).div(totalWinnerStake);

        submission.claimedReward = true;
        IERC20 stakeToken = IERC20(predictionStreams[_streamId].stakeToken);
        require(stakeToken.transfer(msg.sender, rewardAmount), "ChronoNexus: Reward transfer failed");

        emit RewardClaimed(_streamId, _epochNumber, msg.sender, rewardAmount);
    }

    /**
     * @notice Retrieves the settled outcome details for a specific epoch.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number.
     * @return actualValue, settlementTimestamp, isSettled, oracleSettler, disputeStatus.
     */
    function getEpochOutcome(uint256 _streamId, uint256 _epochNumber)
        public
        view
        returns (uint256 actualValue, uint256 settlementTimestamp, bool isSettled, address oracleSettler, DisputeStatus disputeStatus)
    {
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];
        return (outcome.actualValue, outcome.settlementTimestamp, outcome.isSettled, outcome.oracleSettler, outcome.disputeStatus);
    }

    /**
     * @notice Retrieves a specific user's prediction details and win status for an epoch.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number.
     * @param _user The address of the user.
     * @return predictedValue, stakeAmount, submissionTimestamp, claimedReward, isWinner.
     */
    function getUserPredictionOutcome(uint256 _streamId, uint256 _epochNumber, address _user)
        public
        view
        returns (uint256 predictedValue, uint256 stakeAmount, uint256 submissionTimestamp, bool claimedReward, bool isWinner)
    {
        PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][_user];
        require(submission.predictor == _user, "ChronoNexus: No prediction found for user");
        return (submission.predictedValue, submission.stakeAmount, submission.submissionTimestamp, submission.claimedReward, submission.isWinner);
    }

    // --- VI. Adaptive Economic Parameters ---

    /**
     * @notice Allows the admin to set the base fee for submitting predictions.
     *         This fee is charged in the stake token of the respective stream.
     * @param _newFee The new base prediction fee.
     */
    function setBasePredictionFee(uint256 _newFee) external onlyAdmin {
        basePredictionFee = _newFee;
        emit ParametersAdjusted(basePredictionFee, rewardPoolShareBps, protocolFeeBps);
    }

    /**
     * @notice Allows the admin to set the reward pool share and protocol fee as basis points.
     *         These define how collected stakes are divided between rewards for winners and protocol revenue.
     * @param _newRewardPoolShareBps New basis points for the reward pool (e.g., 9000 for 90%).
     * @param _newProtocolFeeBps New basis points for the protocol fee (e.g., 1000 for 10%).
     */
    function setRewardAndProtocolFeeBps(uint256 _newRewardPoolShareBps, uint256 _newProtocolFeeBps) external onlyAdmin {
        require(_newRewardPoolShareBps.add(_newProtocolFeeBps) <= 10000, "ChronoNexus: Total BPS exceeds 10000");
        rewardPoolShareBps = _newRewardPoolShareBps;
        protocolFeeBps = _newProtocolFeeBps;
        emit ParametersAdjusted(basePredictionFee, rewardPoolShareBps, protocolFeeBps);
    }

    /**
     * @notice Allows the admin to adjust various dynamic parameters. This function could be
     *         extended to integrate with external gas price oracles or other on-chain metrics
     *         to dynamically set fees, staking requirements, or reward multipliers.
     * @param _newMinReputationForDispute New minimum reputation required to initiate a dispute.
     * @param _newDisputeVoteReputationWeight New multiplier for reputation in dispute voting.
     */
    function adjustDynamicParameters(uint256 _newMinReputationForDispute, uint256 _newDisputeVoteReputationWeight) external onlyAdmin {
        // In a more advanced system, this function might read from a gas price oracle
        // and adjust 'basePredictionFee' or 'minReputationForPrediction' automatically.
        // For this example, we're just allowing admin to set some thresholds.
        minReputationForDispute = _newMinReputationForDispute;
        disputeVoteReputationWeight = _newDisputeVoteReputationWeight;
        
        // Example of internal adaptive logic based on some hypothetical scenario (requires gasPriceOracle to be functional):
        // uint256 currentGasPrice = IChainlinkAggregator(gasPriceOracle).latestAnswer(); // Hypothetical Chainlink integration
        // if (currentGasPrice > SOME_THRESHOLD_GAS) {
        //     basePredictionFee = basePredictionFee.mul(110).div(100); // increase by 10%
        // }
        
        emit ParametersAdjusted(basePredictionFee, rewardPoolShareBps, protocolFeeBps);
    }

    /**
     * @notice Retrieves the current dynamic parameters of the protocol.
     * @return _basePredictionFee, _rewardPoolShareBps, _protocolFeeBps, _minReputationForDispute, _disputeVoteReputationWeight.
     */
    function getDynamicParameters()
        public
        view
        returns (
            uint256 _basePredictionFee,
            uint256 _rewardPoolShareBps,
            uint256 _protocolFeeBps,
            uint256 _minReputationForDispute,
            uint256 _disputeVoteReputationWeight
        )
    {
        return (
            basePredictionFee,
            rewardPoolShareBps,
            protocolFeeBps,
            minReputationForDispute,
            disputeVoteReputationWeight
        );
    }

    // --- VII. Reputation System ---

    /**
     * @notice Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Internal function to update a user's reputation score.
     *         Called automatically upon accurate/inaccurate predictions, successful/failed disputes.
     * @param _user The address of the user whose reputation is to be updated.
     * @param _scoreChange The amount to change the reputation by (positive for gain, negative for loss).
     */
    function _updateReputation(address _user, int256 _scoreChange) internal {
        if (_scoreChange > 0) {
            userReputation[_user] = userReputation[_user].add(uint256(_scoreChange));
        } else if (_scoreChange < 0) {
            uint256 absChange = uint256(-_scoreChange);
            userReputation[_user] = userReputation[_user] > absChange ? userReputation[_user].sub(absChange) : 0;
        }
        emit ReputationUpdated(_user, userReputation[_user], _scoreChange);
    }

    /**
     * @notice Allows the admin to set the reputation thresholds required for different
     *         protocol interactions, such as initiating disputes or becoming a validator (future).
     * @param _newReputationGainOnWin Reputation points gained for a correct prediction.
     * @param _newReputationLossOnLoss Reputation points lost for an incorrect prediction.
     */
    function setReputationModifiers(uint256 _newReputationGainOnWin, uint256 _newReputationLossOnLoss) external onlyAdmin {
        reputationGainOnWin = _newReputationGainOnWin;
        reputationLossOnLoss = _newReputationLossOnLoss;
    }

    // --- VIII. Decentralized Dispute Resolution (Simplified) ---

    /**
     * @notice Allows a user with sufficient reputation to initiate a dispute for a settled epoch.
     *         Requires a dispute bond, which is locked during the dispute period.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number to dispute.
     * @param _proposedCorrectValue The value the initiator believes is the true outcome.
     * @param _disputeBond The amount of stake token to put up as a dispute bond.
     */
    function initiateDispute(
        uint256 _streamId,
        uint256 _epochNumber,
        uint256 _proposedCorrectValue,
        uint256 _disputeBond
    ) external notPaused reputationRequired(minReputationForDispute) {
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];
        PredictionStream storage stream = predictionStreams[_streamId];
        
        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");
        require(outcome.isSettled, "ChronoNexus: Epoch is not settled yet");
        require(outcome.disputeStatus == DisputeStatus.NONE, "ChronoNexus: Dispute already initiated for this epoch");
        require(_disputeBond > 0, "ChronoNexus: Dispute bond must be positive");

        // Transfer dispute bond from user to contract
        IERC20 stakeToken = IERC20(stream.stakeToken);
        require(stakeToken.transferFrom(msg.sender, address(this), _disputeBond), "ChronoNexus: Dispute bond transfer failed");

        outcome.disputeStatus = DisputeStatus.PENDING;
        outcome.disputeInitiator = msg.sender;
        outcome.disputeProposedValue = _proposedCorrectValue;
        outcome.disputeBondTotal = outcome.disputeBondTotal.add(_disputeBond);

        // Record the initiator's vote implicitly
        outcome.hasVotedOnDispute[msg.sender] = true;
        outcome.supportsDispute[msg.sender] = true;
        outcome.totalReputationSupportingDispute = outcome.totalReputationSupportingDispute.add(userReputation[msg.sender].mul(disputeVoteReputationWeight));

        emit DisputeInitiated(_streamId, _epochNumber, msg.sender, _proposedCorrectValue);
    }

    /**
     * @notice Allows users with sufficient reputation to vote on an ongoing dispute.
     *         Their vote weight is influenced by their reputation score.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number of the dispute.
     * @param _supportsDispute True if the voter supports overturning the original outcome, false otherwise.
     */
    function voteOnDispute(uint252 _streamId, uint252 _epochNumber, bool _supportsDispute)
        external
        notPaused
        reputationRequired(1) // Even low reputation users can vote, but weight is low
    {
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];
        require(outcome.disputeStatus == DisputeStatus.PENDING, "ChronoNexus: No active dispute for this epoch");
        require(!outcome.hasVotedOnDispute[msg.sender], "ChronoNexus: Already voted on this dispute");
        
        uint256 voterReputationWeight = userReputation[msg.sender].mul(disputeVoteReputationWeight);
        require(voterReputationWeight > 0, "ChronoNexus: Voter must have positive weighted reputation");

        outcome.hasVotedOnDispute[msg.sender] = true;
        outcome.supportsDispute[msg.sender] = _supportsDispute;

        if (_supportsDispute) {
            outcome.totalReputationSupportingDispute = outcome.totalReputationSupportingDispute.add(voterReputationWeight);
        } else {
            outcome.totalReputationOpposingDispute = outcome.totalReputationOpposingDispute.add(voterReputationWeight);
        }

        emit DisputeVoteCast(_streamId, _epochNumber, msg.sender, _supportsDispute);
    }

    /**
     * @notice Resolves an ongoing dispute. This can be called by admin or after a specific
     *         voting period (not implemented here, but implied). Based on reputation-weighted
     *         votes, the dispute is either upheld or overturned. Bonds are distributed accordingly,
     *         and reputation scores are adjusted.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number of the dispute.
     */
    function resolveDispute(uint256 _streamId, uint256 _epochNumber) external onlyAdmin notPaused { // Could be automated or DAO-gated
        EpochOutcome storage outcome = epochOutcomes[_streamId][_epochNumber];
        require(outcome.disputeStatus == DisputeStatus.PENDING, "ChronoNexus: No active dispute to resolve");
        
        DisputeStatus newStatus;
        address[] storage submissionsInEpoch = epochSubmissionsList[_streamId][_epochNumber];
        IERC20 stakeToken = IERC20(predictionStreams[_streamId].stakeToken);

        if (outcome.totalReputationSupportingDispute > outcome.totalReputationOpposingDispute) {
            // Dispute is upheld: original outcome is overturned, new value is proposed one.
            newStatus = DisputeStatus.RESOLVED_OVERTURNED;
            
            // Re-evaluate winners based on disputeProposedValue
            uint256 totalNewWinnerStake = 0;
            // A fixed tolerance or the original stream's tolerance could be used here.
            // For simplicity, re-using a placeholder tolerance.
            uint256 reEvaluationTolerance = 5; 

            for (uint256 i = 0; i < submissionsInEpoch.length; i++) {
                address predictor = submissionsInEpoch[i];
                PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][predictor];
                
                if (submission.stakeAmount == 0) continue; // Skip withdrawn predictions

                // Reset winner status and calculate new winners
                submission.isWinner = false; // Reset for re-evaluation
                
                if (submission.predictedValue >= outcome.disputeProposedValue.sub(reEvaluationTolerance) &&
                    submission.predictedValue <= outcome.disputeProposedValue.add(reEvaluationTolerance)) {
                    submission.isWinner = true;
                    totalNewWinnerStake = totalNewWinnerStake.add(submission.stakeAmount);
                }
            }

            // Refund dispute initiator's bond
            require(stakeToken.transfer(outcome.disputeInitiator, outcome.disputeBondTotal), "ChronoNexus: Dispute bond refund failed");
            _updateReputation(outcome.disputeInitiator, int256(reputationGainOnWin.mul(2))); // Double reward for successful dispute

            // Update epoch's actual value for future reward claims
            outcome.actualValue = outcome.disputeProposedValue;
            outcome.settlementTimestamp = block.timestamp; // Update settlement timestamp
            
        } else {
            // Dispute is not upheld: original outcome stands.
            newStatus = DisputeStatus.RESOLVED_UPHELD;

            // Punish dispute initiator by keeping bond (could be distributed to opposing voters or protocol fees)
            // For simplicity, bond is kept by contract (protocol fees).
            // No refund for dispute initiator.
            _updateReputation(outcome.disputeInitiator, -int256(reputationLossOnLoss.mul(2))); // Double penalty for failed dispute
        }

        outcome.disputeStatus = newStatus;
        emit DisputeResolved(_streamId, _epochNumber, newStatus);
    }

    // --- X. View Functions for Data Retrieval ---

    /**
     * @notice Gets the current active epoch number for a given prediction stream.
     *         Calculated based on stream's `nextEpochStartTime` and `epochDuration`.
     * @param _streamId The ID of the prediction stream.
     * @return The current epoch number.
     */
    function getCurrentEpoch(uint256 _streamId) public view returns (uint256) {
        PredictionStream storage stream = predictionStreams[_streamId];
        require(bytes(stream.name).length > 0, "ChronoNexus: Stream does not exist");
        if (stream.epochDuration == 0) return 0; // Prevent division by zero

        // Calculate current epoch based on time elapsed since nextEpochStartTime
        // This is a simplified model. A more robust system might track epoch starts
        // explicitly or have an external service update nextEpochStartTime.
        return (block.timestamp.sub(stream.nextEpochStartTime)).div(stream.epochDuration).add(1);
    }

    /**
     * @notice Gets the total number of predictions submitted for a specific epoch.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number.
     * @return The count of predictions for that epoch. Note: includes withdrawn predictions (stakeAmount=0).
     */
    function getEpochPredictionCount(uint256 _streamId, uint256 _epochNumber) public view returns (uint256) {
        return epochSubmissionsList[_streamId][_epochNumber].length;
    }

    /**
     * @notice Retrieves a specific user's raw prediction details for a given epoch.
     * @param _streamId The ID of the prediction stream.
     * @param _epochNumber The epoch number.
     * @param _user The address of the user.
     * @return predictedValue, stakeAmount, submissionTimestamp, claimedReward, isWinner.
     */
    function getUserPredictionsForEpoch(uint256 _streamId, uint256 _epochNumber, address _user)
        public
        view
        returns (uint256 predictedValue, uint256 stakeAmount, uint256 submissionTimestamp, bool claimedReward, bool isWinner)
    {
        PredictionSubmission storage submission = predictionSubmissions[_streamId][_epochNumber][_user];
        require(submission.predictor == _user, "ChronoNexus: User did not predict in this epoch");
        return (submission.predictedValue, submission.stakeAmount, submission.submissionTimestamp, submission.claimedReward, submission.isWinner);
    }
}
```