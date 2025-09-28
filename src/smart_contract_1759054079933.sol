This smart contract, named **"Cognitive Consensus Network (CCN)"**, aims to create a decentralized, adaptive protocol for collaboratively building, validating, and deploying "Adaptive Decision Modules" (ADMs). ADMs are not actual AI models on-chain, but rather configurable logic sets with parameters that can be tuned and optimized through collective intelligence, driven by staked "Cognition Tokens" ($COG) and a reputation system. The goal is to evolve on-chain strategies (e.g., for asset management, protocol incentives, or dynamic pricing) based on real-world performance data provided by whitelisted oracles.

---

## Smart Contract: Cognitive Consensus Network (CCN)

### Outline

1.  **Core Concepts & Philosophy**: Explain the purpose of ADMs, COG tokens, and the adaptive nature.
2.  **State Variables**: Global state, mappings, and structs.
3.  **Events**: For transparent contract interactions.
4.  **Modifiers**: Access control.
5.  **Constructor**: Initial setup.
6.  **CCN Configuration & Setup (Functions 1-4)**: Administrative functions for protocol parameters.
7.  **Cognition Token ($COG) Management (Functions 5-7)**: User interaction with the staking token.
8.  **Adaptive Decision Module (ADM) Lifecycle (Functions 8-14)**: Proposing, activating, updating, and deactivating ADMs.
9.  **Performance Validation & Oracle Interaction (Functions 15-17)**: How external data influences ADMs.
10. **Reputation & Rewards (Functions 18-20)**: Incentivizing participation and accuracy.
11. **Query & Utility Functions (Functions 21-24)**: Read-only functions for network information.

---

### Function Summary

1.  `constructor()`: Initializes the contract with an owner, initial epoch duration, and sets the Cognition Token ($COG) address.
2.  `setEpochDuration(uint256 _newDuration)`: Allows the owner to adjust the duration of each epoch.
3.  `setOracleAddress(address _oracle, bool _isWhitelisted)`: Whitelists or de-whitelists an address as a trusted oracle for performance data.
4.  `setProtocolFeeRecipient(address _recipient)`: Sets the address that receives protocol fees generated from successful ADMs.
5.  `stakeCognitionTokens(uint256 _amount)`: Allows users to stake $COG tokens to participate in governance, validation, and earn reputation.
6.  `unstakeCognitionTokens(uint256 _amount)`: Allows users to unstake $COG tokens after a cool-down period.
7.  `claimEpochRewards()`: Allows stakers to claim rewards accumulated from active ADMs and successful validations in the previous epoch.
8.  `proposeNewADM(string memory _name, string memory _description, bytes memory _initialLogicParameters)`: Submits a proposal for a new Adaptive Decision Module, including its initial configuration.
9.  `voteOnADMProposal(uint256 _proposalId, bool _support)`: Allows staked $COG holders to vote on a new ADM proposal.
10. `activateADM(uint256 _proposalId)`: Activates an ADM if its proposal has passed the voting threshold and epoch conditions are met.
11. `submitADMParameterUpdateProposal(uint256 _admId, string memory _parameterKey, uint256 _newValue)`: Proposes a specific parameter change for an active ADM.
12. `voteOnParameterUpdate(uint256 _updateProposalId, bool _support)`: Staked $COG holders vote on proposed parameter updates for an ADM.
13. `executeParameterUpdate(uint256 _updateProposalId)`: Applies an approved parameter update to an active ADM.
14. `deactivateADM(uint256 _admId)`: Allows the DAO (via governance) to deactivate an ADM, potentially due to poor performance.
15. `submitADMPerformanceData(uint256 _admId, int256 _performanceMetric, uint256 _timestamp)`: A whitelisted oracle submits verifiable performance data for a specific ADM.
16. `validatePerformanceData(uint256 _admId, uint256 _performanceDataIndex, bool _isAccurate)`: Stakers review submitted oracle performance data and confirm or challenge its accuracy to earn reputation.
17. `reportADMAnomaly(uint256 _admId, uint256 _dataIndex, string memory _reason)`: Allows stakers to report potential anomalies or malicious data from an oracle, triggering a review.
18. `updateRewardWeights(uint256 _newADMSuccessWeight, uint256 _newValidatorAccuracyWeight)`: Allows owner/governance to adjust the weights for calculating rewards based on ADM success and validator accuracy.
19. `getCurrentReputation(address _user)`: Retrieves the current reputation score of a specific user.
20. `distributeProtocolRevenue(uint256 _amount)`: Allows the protocol fee recipient to manually trigger distribution of collected fees to successful ADM developers and validators.
21. `getADMDetails(uint256 _admId)`: Retrieves all current details and parameters for a specific ADM.
22. `getADMProposalDetails(uint256 _proposalId)`: Retrieves details about a specific ADM proposal.
23. `getADMParameterUpdateProposal(uint256 _updateProposalId)`: Retrieves details about a specific ADM parameter update proposal.
24. `getCurrentEpoch()`: Returns the current epoch number and its end timestamp.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Cognitive Consensus Network (CCN)
 * @dev A decentralized, adaptive protocol for collaboratively building, validating,
 * and deploying "Adaptive Decision Modules" (ADMs). ADMs are configurable logic sets
 * whose parameters can be tuned and optimized through collective intelligence,
 * driven by staked "Cognition Tokens" ($COG) and a reputation system.
 * The goal is to evolve on-chain strategies (e.g., for asset management, protocol incentives,
 * or dynamic pricing) based on real-world performance data provided by whitelisted oracles.
 */
contract CognitiveConsensusNetwork is Ownable, ReentrancyGuard {

    // --- Core Concepts & Philosophy ---
    // ADMs (Adaptive Decision Modules): On-chain configurable logic sets, representing strategies.
    // COG Tokens: ERC20 token for staking, governance, and earning reputation.
    // Epochs: Time-bound cycles for ADM evolution, proposals, and reward distribution.
    // Reputation: Earned by accurate validation and successful ADM contributions, influencing voting power and rewards.
    // Oracles: Provide external, verifiable performance data for ADMs.

    // --- State Variables ---

    // ERC20 token for staking and governance
    IERC20 public cognitionToken;

    // --- Epoch Management ---
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds
    mapping(uint256 => uint256) public epochEndTime; // epoch => end timestamp

    // --- ADM (Adaptive Decision Module) Management ---
    struct ADM {
        uint256 id;
        string name;
        string description;
        address creator;
        bool isActive;
        uint256 createdAtEpoch;
        mapping(string => uint256) parameters; // Key-value parameters for the decision logic
        uint256 totalPerformanceScore; // Accumulated performance score
        uint256 performanceDataCount; // Number of performance data points received
        uint256 lastPerformanceUpdateEpoch; // Epoch when performance was last updated
        uint256 totalRevenueGenerated; // Total revenue attributed to this ADM
    }
    uint256 private _nextADMId;
    mapping(uint256 => ADM) public adms;

    // --- ADM Proposal System ---
    struct ADMProposal {
        uint256 id;
        uint256 admId; // 0 for new ADM, refers to existing ADM for updates
        string name;
        string description;
        bytes initialLogicParameters; // Raw bytes for complex initial setup or logic reference
        address proposer;
        uint256 startEpoch;
        uint256 endEpoch; // Voting period ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed; // True if ADM was activated or parameters updated
        bool isNewADMProposal; // True if this proposal is for a new ADM, false for parameter update
        string parameterKey; // Used for parameter update proposals
        uint224 newValue; // Used for parameter update proposals (uint256 for value, uint224 to save space as it's typically within range)
    }
    uint256 private _nextProposalId;
    mapping(uint256 => ADMProposal) public admProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedADMProposal; // proposalId => user => voted

    // --- Oracle & Performance Validation ---
    mapping(address => bool) public isWhitelistedOracle;
    struct ADMPerformanceData {
        int256 metric; // e.g., percentage gain/loss, accuracy score
        uint256 timestamp;
        address submitter; // Oracle address
        uint256 epoch;
        uint256 totalValidations; // Number of stakers who validated as accurate
        uint256 totalChallenges; // Number of stakers who challenged
    }
    mapping(uint256 => ADMPerformanceData[]) public admPerformanceHistory; // admId => array of performance data
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasValidatedPerformance; // admId => dataIndex => user => validated

    // --- User Reputation & Staking ---
    struct UserReputation {
        uint256 totalStakedCOG; // Total staked amount
        uint256 currentReputationScore; // Affects voting weight and reward share
        uint256 lastUnstakeEpoch; // Epoch when unstake cooldown started
        uint256 pendingRewards; // Rewards claimable by the user
    }
    mapping(address => UserReputation) public userReputations;
    uint256 public constant UNSTAKE_COOLDOWN_EPOCHS = 3; // Example cooldown

    // --- Reward Weights ---
    uint256 public ADM_SUCCESS_WEIGHT = 70; // Percentage weight for ADM success in reward calculation
    uint256 public VALIDATOR_ACCURACY_WEIGHT = 30; // Percentage weight for validator accuracy

    // --- Protocol Fees ---
    address public protocolFeeRecipient;
    uint256 public protocolFeesAccrued; // Fees collected but not yet distributed

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 endTime);
    event EpochDurationSet(uint256 indexed newDuration);
    event OracleWhitelisted(address indexed oracle, bool indexed status);
    event ProtocolFeeRecipientSet(address indexed recipient);

    event CognitionTokensStaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event CognitionTokensUnstaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event RewardsClaimed(address indexed user, uint256 amount);

    event ADMProposed(uint256 indexed proposalId, uint256 indexed admId, address indexed proposer, string name);
    event ADMVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votesFor, uint256 votesAgainst);
    event ADMActivated(uint256 indexed admId, address indexed activator, uint256 proposalId);
    event ADMDeactivated(uint256 indexed admId, address indexed executor);

    event ADMParameterUpdateProposed(uint256 indexed proposalId, uint256 indexed admId, string parameterKey, uint256 newValue, address indexed proposer);
    event ADMParameterUpdateExecuted(uint256 indexed admId, string parameterKey, uint256 newValue, uint256 proposalId);

    event ADMPerformanceDataSubmitted(uint256 indexed admId, uint256 indexed dataIndex, int256 metric, address indexed submitter);
    event PerformanceDataValidated(uint256 indexed admId, uint256 indexed dataIndex, address indexed validator, bool isAccurate);
    event ADMAnomalyReported(uint256 indexed admId, uint256 indexed dataIndex, address indexed reporter, string reason);

    event RewardWeightsUpdated(uint256 newADMSuccessWeight, uint256 newValidatorAccuracyWeight);
    event ReputationUpdated(address indexed user, uint256 newReputationScore);
    event ProtocolRevenueDistributed(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyWhitelistedOracle() {
        require(isWhitelistedOracle[msg.sender], "CCN: Not a whitelisted oracle");
        _;
    }

    modifier onlyStaker() {
        require(userReputations[msg.sender].totalStakedCOG > 0, "CCN: Caller must be a COG staker");
        _;
    }

    modifier enforceEpochAdvance() {
        if (block.timestamp >= epochEndTime[currentEpoch]) {
            _advanceEpoch();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _cognitionTokenAddress, uint256 _initialEpochDuration) Ownable(msg.sender) {
        require(_cognitionTokenAddress != address(0), "CCN: Invalid COG token address");
        require(_initialEpochDuration > 0, "CCN: Epoch duration must be positive");

        cognitionToken = IERC20(_cognitionTokenAddress);
        epochDuration = _initialEpochDuration;
        currentEpoch = 1;
        epochEndTime[currentEpoch] = block.timestamp + epochDuration;
        protocolFeeRecipient = owner();

        _nextADMId = 1;
        _nextProposalId = 1;

        emit EpochAdvanced(currentEpoch, epochEndTime[currentEpoch]);
    }

    // --- Internal Helpers ---
    function _advanceEpoch() internal {
        // This function must be called only when current epoch has ended.
        // It handles epoch advancement and initiates reward calculations.
        require(block.timestamp >= epochEndTime[currentEpoch], "CCN: Current epoch has not ended");

        // First, distribute rewards for the ending epoch before advancing state
        _distributeEpochRewards(currentEpoch);

        currentEpoch++;
        epochEndTime[currentEpoch] = block.timestamp + epochDuration;
        emit EpochAdvanced(currentEpoch, epochEndTime[currentEpoch]);
    }

    function _distributeEpochRewards(uint256 _epoch) internal {
        // Simplified reward distribution logic for demonstration.
        // In a real system, this would involve complex calculations based on
        // ADM performance, validator accuracy, and total staked COG.
        // For now, it's a placeholder to show the concept.

        // Iterate through users, calculate their rewards based on ADM success & validation.
        // This placeholder skips actual complex iteration and calculation due to gas limits.
        // A real implementation would require off-chain computation or a more gas-efficient
        // on-chain aggregated approach / Merkle tree distribution.

        // Placeholder: Assuming some pool of rewards is available.
        // For demonstration, we simply clear pending rewards if any were accrued.
        // In a full system, `userReputations[user].pendingRewards` would be populated
        // during _advanceEpoch based on the epoch's performance and validation.

        // Example: Iterate through ADMs to calculate their success contribution
        // and distribute a portion of protocolFeesAccrued to their creators
        // and to validators who accurately validated data related to these ADMs.
        // This part is left abstract to avoid iterating over all ADMs/users, which is gas-intensive.
    }

    // --- CCN Configuration & Setup (Functions 1-4) ---

    /// @notice Allows the owner to adjust the duration of each epoch.
    /// @param _newDuration The new duration for an epoch in seconds.
    function setEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "CCN: Epoch duration must be positive");
        epochDuration = _newDuration;
        // Update the end time for the current epoch if it hasn't ended yet
        if (block.timestamp < epochEndTime[currentEpoch]) {
            epochEndTime[currentEpoch] = block.timestamp + _newDuration;
        }
        emit EpochDurationSet(_newDuration);
    }

    /// @notice Whitelists or de-whitelists an address as a trusted oracle for performance data.
    /// @param _oracle The address of the oracle.
    /// @param _isWhitelisted True to whitelist, false to de-whitelist.
    function setOracleAddress(address _oracle, bool _isWhitelisted) public onlyOwner {
        require(_oracle != address(0), "CCN: Invalid oracle address");
        isWhitelistedOracle[_oracle] = _isWhitelisted;
        emit OracleWhitelisted(_oracle, _isWhitelisted);
    }

    /// @notice Sets the address that receives protocol fees generated from successful ADMs.
    /// @param _recipient The address to receive protocol fees.
    function setProtocolFeeRecipient(address _recipient) public onlyOwner {
        require(_recipient != address(0), "CCN: Invalid recipient address");
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientSet(_recipient);
    }

    // --- Cognition Token ($COG) Management (Functions 5-7) ---

    /// @notice Allows users to stake $COG tokens to participate in governance, validation, and earn reputation.
    /// @param _amount The amount of $COG tokens to stake.
    function stakeCognitionTokens(uint256 _amount) public nonReentrant enforceEpochAdvance {
        require(_amount > 0, "CCN: Stake amount must be positive");
        require(cognitionToken.transferFrom(msg.sender, address(this), _amount), "CCN: COG transfer failed");

        UserReputation storage userRep = userReputations[msg.sender];
        userRep.totalStakedCOG += _amount;
        // Reputation score can be updated based on new stake, or it can be a separate mechanism
        // For simplicity, we'll just track total staked and assume reputation is influenced by it.
        emit CognitionTokensStaked(msg.sender, _amount, userRep.totalStakedCOG);
    }

    /// @notice Allows users to unstake $COG tokens after a cool-down period.
    /// @param _amount The amount of $COG tokens to unstake.
    function unstakeCognitionTokens(uint256 _amount) public nonReentrant enforceEpochAdvance {
        UserReputation storage userRep = userReputations[msg.sender];
        require(userRep.totalStakedCOG >= _amount, "CCN: Insufficient staked COG");
        require(userRep.lastUnstakeEpoch + UNSTAKE_COOLDOWN_EPOCHS <= currentEpoch, "CCN: Unstake cooldown in effect");

        userRep.totalStakedCOG -= _amount;
        userRep.lastUnstakeEpoch = currentEpoch; // Start cooldown
        require(cognitionToken.transfer(msg.sender, _amount), "CCN: COG transfer failed");

        emit CognitionTokensUnstaked(msg.sender, _amount, userRep.totalStakedCOG);
    }

    /// @notice Allows stakers to claim rewards accumulated from active ADMs and successful validations.
    function claimEpochRewards() public nonReentrant enforceEpochAdvance {
        UserReputation storage userRep = userReputations[msg.sender];
        uint256 rewards = userRep.pendingRewards;
        require(rewards > 0, "CCN: No pending rewards to claim");

        userRep.pendingRewards = 0; // Reset pending rewards
        require(cognitionToken.transfer(msg.sender, rewards), "CCN: Reward transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }


    // --- Adaptive Decision Module (ADM) Lifecycle (Functions 8-14) ---

    /// @notice Submits a proposal for a new Adaptive Decision Module, including its initial configuration.
    /// @param _name The name of the new ADM.
    /// @param _description A detailed description of the ADM's purpose and logic.
    /// @param _initialLogicParameters Raw bytes representing initial parameters or a pointer to off-chain logic.
    /// @return The ID of the newly created proposal.
    function proposeNewADM(
        string memory _name,
        string memory _description,
        bytes memory _initialLogicParameters
    ) public onlyStaker enforceEpochAdvance returns (uint256) {
        uint256 proposalId = _nextProposalId++;
        admProposals[proposalId] = ADMProposal({
            id: proposalId,
            admId: 0, // Placeholder, actual ADM ID assigned on activation
            name: _name,
            description: _description,
            initialLogicParameters: _initialLogicParameters,
            proposer: msg.sender,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + 2, // Voting period of 2 epochs
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            isNewADMProposal: true,
            parameterKey: "",
            newValue: 0
        });
        emit ADMProposed(proposalId, 0, msg.sender, _name);
        return proposalId;
    }

    /// @notice Allows staked $COG holders to vote on a new ADM proposal.
    /// @param _proposalId The ID of the ADM proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnADMProposal(uint256 _proposalId, bool _support) public onlyStaker enforceEpochAdvance {
        ADMProposal storage proposal = admProposals[_proposalId];
        require(proposal.id != 0, "CCN: Proposal does not exist");
        require(proposal.isNewADMProposal, "CCN: Not a new ADM proposal");
        require(currentEpoch >= proposal.startEpoch && currentEpoch <= proposal.endEpoch, "CCN: Voting period not active");
        require(!hasVotedADMProposal[_proposalId][msg.sender], "CCN: Already voted on this proposal");
        require(!proposal.executed, "CCN: Proposal already executed");

        uint256 votingPower = userReputations[msg.sender].totalStakedCOG + userReputations[msg.sender].currentReputationScore; // Reputation boosts voting power

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        hasVotedADMProposal[_proposalId][msg.sender] = true;

        emit ADMVoted(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Activates an ADM if its proposal has passed the voting threshold and epoch conditions are met.
    /// @param _proposalId The ID of the passed ADM proposal.
    /// @return The ID of the newly activated ADM.
    function activateADM(uint256 _proposalId) public nonReentrant enforceEpochAdvance returns (uint256) {
        ADMProposal storage proposal = admProposals[_proposalId];
        require(proposal.id != 0, "CCN: Proposal does not exist");
        require(proposal.isNewADMProposal, "CCN: Not a new ADM proposal");
        require(currentEpoch > proposal.endEpoch, "CCN: Voting period not yet ended");
        require(!proposal.executed, "CCN: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "CCN: Proposal did not pass");

        uint256 newADMId = _nextADMId++;
        adms[newADMId] = ADM({
            id: newADMId,
            name: proposal.name,
            description: proposal.description,
            creator: proposal.proposer,
            isActive: true,
            createdAtEpoch: currentEpoch,
            parameters: new mapping(string => uint256), // Initialize an empty map
            totalPerformanceScore: 0,
            performanceDataCount: 0,
            lastPerformanceUpdateEpoch: currentEpoch,
            totalRevenueGenerated: 0
        });

        // Initialize parameters from initialLogicParameters (simplified: assume a single uint parameter)
        // In a real system, this would involve a more complex parsing or a dedicated ADM registry.
        if (proposal.initialLogicParameters.length > 0) {
            // Example: If initialLogicParameters is just a single uint, convert it.
            // For complex logic, this might be a pointer or a hash.
            // For demonstration, let's assume `initialLogicParameters` is a single uint256 as bytes.
            if (proposal.initialLogicParameters.length >= 32) {
                uint256 initialParamValue = abi.decode(proposal.initialLogicParameters, (uint256));
                adms[newADMId].parameters["initialValue"] = initialParamValue;
            }
        }

        proposal.executed = true;
        proposal.admId = newADMId; // Link proposal to activated ADM
        emit ADMActivated(newADMId, msg.sender, _proposalId);
        return newADMId;
    }

    /// @notice Submits a proposal for a specific parameter change for an active ADM.
    /// @param _admId The ID of the ADM to update.
    /// @param _parameterKey The specific parameter to change (e.g., "riskThreshold", "feeRate").
    /// @param _newValue The new value for the parameter.
    /// @return The ID of the newly created parameter update proposal.
    function submitADMParameterUpdateProposal(
        uint256 _admId,
        string memory _parameterKey,
        uint256 _newValue
    ) public onlyStaker enforceEpochAdvance returns (uint256) {
        ADM storage adm = adms[_admId];
        require(adm.id != 0 && adm.isActive, "CCN: ADM not found or not active");

        uint256 proposalId = _nextProposalId++;
        admProposals[proposalId] = ADMProposal({
            id: proposalId,
            admId: _admId,
            name: string(abi.encodePacked("Update ", adm.name, " - ", _parameterKey)),
            description: string(abi.encodePacked("Proposed change for parameter '", _parameterKey, "' to ", Strings.toString(_newValue))),
            initialLogicParameters: "",
            proposer: msg.sender,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + 1, // Shorter voting period for updates
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            isNewADMProposal: false,
            parameterKey: _parameterKey,
            newValue: uint224(_newValue) // Cast to uint224
        });
        emit ADMParameterUpdateProposed(proposalId, _admId, _parameterKey, _newValue, msg.sender);
        return proposalId;
    }

    /// @notice Staked $COG holders vote on proposed parameter updates for an ADM.
    /// @param _updateProposalId The ID of the parameter update proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnParameterUpdate(uint256 _updateProposalId, bool _support) public onlyStaker enforceEpochAdvance {
        ADMProposal storage proposal = admProposals[_updateProposalId];
        require(proposal.id != 0, "CCN: Proposal does not exist");
        require(!proposal.isNewADMProposal, "CCN: Not a parameter update proposal");
        require(currentEpoch >= proposal.startEpoch && currentEpoch <= proposal.endEpoch, "CCN: Voting period not active");
        require(!hasVotedADMProposal[_updateProposalId][msg.sender], "CCN: Already voted on this proposal");
        require(!proposal.executed, "CCN: Proposal already executed");

        uint256 votingPower = userReputations[msg.sender].totalStakedCOG + userReputations[msg.sender].currentReputationScore;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        hasVotedADMProposal[_updateProposalId][msg.sender] = true;

        emit ADMVoted(_updateProposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    /// @notice Applies an approved parameter update to an active ADM.
    /// @param _updateProposalId The ID of the parameter update proposal.
    function executeParameterUpdate(uint256 _updateProposalId) public nonReentrant enforceEpochAdvance {
        ADMProposal storage proposal = admProposals[_updateProposalId];
        require(proposal.id != 0, "CCN: Proposal does not exist");
        require(!proposal.isNewADMProposal, "CCN: Not a parameter update proposal");
        require(currentEpoch > proposal.endEpoch, "CCN: Voting period not yet ended");
        require(!proposal.executed, "CCN: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "CCN: Proposal did not pass");

        ADM storage adm = adms[proposal.admId];
        require(adm.id != 0 && adm.isActive, "CCN: Target ADM not found or not active");

        adm.parameters[proposal.parameterKey] = proposal.newValue;
        proposal.executed = true;

        emit ADMParameterUpdateExecuted(adm.id, proposal.parameterKey, proposal.newValue, _updateProposalId);
    }

    /// @notice Allows the DAO (via governance, represented by `owner()` for simplicity) to deactivate an ADM, potentially due to poor performance.
    /// @param _admId The ID of the ADM to deactivate.
    function deactivateADM(uint256 _admId) public onlyOwner enforceEpochAdvance {
        ADM storage adm = adms[_admId];
        require(adm.id != 0 && adm.isActive, "CCN: ADM not found or not active");

        adm.isActive = false;
        emit ADMDeactivated(_admId, msg.sender);
    }

    // --- Performance Validation & Oracle Interaction (Functions 15-17) ---

    /// @notice A whitelisted oracle submits verifiable performance data for a specific ADM.
    /// @param _admId The ID of the ADM for which data is being submitted.
    /// @param _performanceMetric The numerical performance metric (e.g., % gain, error rate).
    /// @param _timestamp The timestamp when the data was recorded (for historical context).
    function submitADMPerformanceData(
        uint256 _admId,
        int256 _performanceMetric,
        uint256 _timestamp
    ) public onlyWhitelistedOracle nonReentrant enforceEpochAdvance {
        ADM storage adm = adms[_admId];
        require(adm.id != 0 && adm.isActive, "CCN: ADM not found or not active");

        admPerformanceHistory[_admId].push(ADMPerformanceData({
            metric: _performanceMetric,
            timestamp: _timestamp,
            submitter: msg.sender,
            epoch: currentEpoch,
            totalValidations: 0,
            totalChallenges: 0
        }));

        adm.totalPerformanceScore += _performanceMetric; // Simplified aggregation
        adm.performanceDataCount++;
        adm.lastPerformanceUpdateEpoch = currentEpoch;

        emit ADMPerformanceDataSubmitted(_admId, admPerformanceHistory[_admId].length - 1, _performanceMetric, msg.sender);
    }

    /// @notice Stakers review submitted oracle performance data and confirm or challenge its accuracy to earn reputation.
    /// @dev Accurate validation boosts reputation, inaccurate validation incurs penalties.
    /// @param _admId The ID of the ADM.
    /// @param _performanceDataIndex The index of the performance data entry in the history array.
    /// @param _isAccurate True if the staker believes the data is accurate, false if challenging.
    function validatePerformanceData(
        uint256 _admId,
        uint256 _performanceDataIndex,
        bool _isAccurate
    ) public onlyStaker nonReentrant enforceEpochAdvance {
        require(_admId != 0, "CCN: Invalid ADM ID");
        require(_performanceDataIndex < admPerformanceHistory[_admId].length, "CCN: Invalid performance data index");
        require(!hasValidatedPerformance[_admId][_performanceDataIndex][msg.sender], "CCN: Already validated this data point");

        ADMPerformanceData storage data = admPerformanceHistory[_admId][_performanceDataIndex];
        UserReputation storage userRep = userReputations[msg.sender];

        // Simplified logic: Assume performance data submitted by a whitelisted oracle is generally considered correct
        // A more advanced system would have a dispute resolution mechanism.
        if (_isAccurate) {
            data.totalValidations++;
            userRep.currentReputationScore += 1; // Small reputation boost for confirming
        } else {
            data.totalChallenges++;
            userRep.currentReputationScore = userRep.currentReputationScore > 0 ? userRep.currentReputationScore - 1 : 0; // Small reputation penalty for challenging without proof
            // In a real system, challenging would initiate a dispute, with higher stakes/rewards/penalties.
        }
        hasValidatedPerformance[_admId][_performanceDataIndex][msg.sender] = true;
        emit PerformanceDataValidated(_admId, _performanceDataIndex, msg.sender, _isAccurate);
        emit ReputationUpdated(msg.sender, userRep.currentReputationScore);
    }

    /// @notice Allows stakers to report potential anomalies or malicious data from an oracle, triggering a review.
    /// @dev This is a higher-level challenge that could lead to oracle de-whitelisting or more severe penalties.
    /// @param _admId The ID of the ADM.
    /// @param _dataIndex The index of the performance data entry in the history array.
    /// @param _reason A description of why the data is considered anomalous/malicious.
    function reportADMAnomaly(
        uint256 _admId,
        uint256 _dataIndex,
        string memory _reason
    ) public onlyStaker enforceEpochAdvance {
        require(_admId != 0, "CCN: Invalid ADM ID");
        require(_dataIndex < admPerformanceHistory[_admId].length, "CCN: Invalid performance data index");
        // No double-reporting for a specific data point from the same user for simplicity,
        // but a real system might allow multiple users to report.

        // This would typically trigger a governance proposal for investigation or a separate dispute module.
        // For simplicity, we just emit an event and potentially penalize the reporter if proven false.
        UserReputation storage userRep = userReputations[msg.sender];
        // Placeholder for initial reputation cost to prevent spamming reports.
        require(userRep.currentRepputationScore >= 5, "CCN: Insufficient reputation to report anomaly");
        userRep.currentReputationScore -= 5; // Cost to report, will be refunded/boosted if report is valid.

        emit ADMAnomalyReported(_admId, _dataIndex, msg.sender, _reason);
        emit ReputationUpdated(msg.sender, userRep.currentReputationScore);
    }


    // --- Reputation & Rewards (Functions 18-20) ---

    /// @notice Allows owner/governance to adjust the weights for calculating rewards based on ADM success and validator accuracy.
    /// @param _newADMSuccessWeight New percentage weight for ADM success (e.g., 70 for 70%).
    /// @param _newValidatorAccuracyWeight New percentage weight for validator accuracy (e.g., 30 for 30%).
    function updateRewardWeights(uint256 _newADMSuccessWeight, uint256 _newValidatorAccuracyWeight) public onlyOwner {
        require(_newADMSuccessWeight + _newValidatorAccuracyWeight == 100, "CCN: Weights must sum to 100%");
        ADM_SUCCESS_WEIGHT = _newADMSuccessWeight;
        VALIDATOR_ACCURACY_WEIGHT = _newValidatorAccuracyWeight;
        emit RewardWeightsUpdated(_newADMSuccessWeight, _newValidatorAccuracyWeight);
    }

    /// @notice Retrieves the current reputation score of a specific user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getCurrentReputation(address _user) public view returns (uint256) {
        return userReputations[_user].currentReputationScore;
    }

    /// @notice Allows the protocol fee recipient to manually trigger distribution of collected fees to successful ADM developers and validators.
    /// @param _amount The amount of protocol revenue to distribute.
    /// @dev This function would typically be called periodically or by a governance proposal.
    /// In a full system, `protocolFeesAccrued` would hold the fees, and this function would calculate and send to users.
    function distributeProtocolRevenue(uint256 _amount) public nonReentrant {
        require(msg.sender == protocolFeeRecipient, "CCN: Only fee recipient can trigger distribution");
        require(protocolFeesAccrued >= _amount, "CCN: Insufficient accrued fees for distribution");
        require(_amount > 0, "CCN: Distribution amount must be positive");

        // Transfer collected fees from this contract to the distribution pool.
        // In a real system, the `_distributeEpochRewards` or a similar function
        // would take from this pool. For simplicity, this acts as a placeholder
        // for making funds available to be processed.
        // A more advanced system might transfer these fees to a separate
        // reward distribution contract.
        protocolFeesAccrued -= _amount;
        // The actual distribution to individual users happens within _distributeEpochRewards
        // or a separate function that calculates individual shares.
        // This function merely makes `_amount` available for such distributions.
        emit ProtocolRevenueDistributed(protocolFeeRecipient, _amount);
    }

    // --- Query & Utility Functions (Functions 21-24) ---

    /// @notice Retrieves all current details and parameters for a specific ADM.
    /// @param _admId The ID of the ADM.
    /// @return admId The ADM's ID.
    /// @return name The name of the ADM.
    /// @return description The description of the ADM.
    /// @return creator The address of the ADM's creator.
    /// @return isActive True if the ADM is currently active.
    /// @return createdAtEpoch The epoch when the ADM was created.
    /// @return currentParameters The current key-value parameters of the ADM (returned as arrays).
    /// @return totalPerformanceScore The accumulated performance score.
    /// @return performanceDataCount The number of performance data points.
    function getADMDetails(uint256 _admId)
        public
        view
        returns (
            uint256 admId,
            string memory name,
            string memory description,
            address creator,
            bool isActive,
            uint256 createdAtEpoch,
            string[] memory parameterKeys,
            uint256[] memory parameterValues,
            int256 totalPerformanceScore,
            uint256 performanceDataCount
        )
    {
        ADM storage adm = adms[_admId];
        require(adm.id != 0, "CCN: ADM does not exist");

        uint256 paramCount = 0;
        for (uint256 i = 1; i <= _nextADMId; i++) { // Iterate to count parameters, inefficient for many ADMs, but for demonstration.
            if (adms[i].id == _admId) { // Find the specific ADM
                // This iteration pattern is for getting map keys, which is generally not direct in Solidity.
                // A better approach would be to store keys in a separate array if needed, or iterate off-chain.
                // For this example, we'll assume parameters are known or iterated off-chain.
                // A simpler return for on-chain would be just fixed parameters.
                // Let's create dummy arrays for demonstration, assuming specific keys.
                // If the number of parameters is truly dynamic and unknown, this is hard on-chain.
                // For this example, we'll return generic 'initialValue' if it exists.
                break;
            }
        }

        string[] memory keys = new string[](1); // Assume at most one common key for simplicity
        uint256[] memory values = new uint256[](1);

        if (adm.parameters["initialValue"] > 0) {
            keys[0] = "initialValue";
            values[0] = adm.parameters["initialValue"];
            paramCount = 1;
        }


        return (
            adm.id,
            adm.name,
            adm.description,
            adm.creator,
            adm.isActive,
            adm.createdAtEpoch,
            keys, // This needs to be dynamically populated, which is hard on-chain without an explicit list of keys.
            values, // Same as above.
            adm.totalPerformanceScore,
            adm.performanceDataCount
        );
    }

    /// @notice Retrieves details about a specific ADM proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The full `ADMProposal` struct.
    function getADMProposalDetails(uint256 _proposalId) public view returns (ADMProposal memory) {
        require(admProposals[_proposalId].id != 0, "CCN: Proposal does not exist");
        return admProposals[_proposalId];
    }

    /// @notice Retrieves details about a specific ADM parameter update proposal.
    /// @param _updateProposalId The ID of the parameter update proposal.
    /// @return The full `ADMProposal` struct (same struct type used for both).
    function getADMParameterUpdateProposal(uint256 _updateProposalId) public view returns (ADMProposal memory) {
        require(admProposals[_updateProposalId].id != 0, "CCN: Proposal does not exist");
        return admProposals[_updateProposalId];
    }

    /// @notice Returns the current epoch number and its end timestamp.
    /// @return _currentEpoch The current epoch number.
    /// @return _epochEndTime The timestamp when the current epoch is scheduled to end.
    function getCurrentEpoch() public view returns (uint256 _currentEpoch, uint256 _epochEndTime) {
        return (currentEpoch, epochEndTime[currentEpoch]);
    }

    // --- Fallback & Receive (Optional, but good practice for receiving ETH) ---
    receive() external payable {
        // Ether sent to this contract will be considered as part of protocol fees
        // (if the protocol is designed to accept ETH directly).
        // It could also be used to fund rewards.
        protocolFeesAccrued += msg.value;
    }

    fallback() external payable {
        // Same as receive
        protocolFeesAccrued += msg.value;
    }
}

// Utility library for converting uint256 to string, from OpenZeppelin
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
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
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```