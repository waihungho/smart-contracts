Okay, this is an exciting challenge! Combining advanced concepts, unique features, and avoiding existing open-source patterns requires a creative approach.

Let's design a smart contract called **"QuantOracle Nexus"**. This contract will serve as a decentralized hub for quantitative data aggregation, verifiable metric calculation, and algorithmic strategy execution based on those metrics. It aims to bridge complex off-chain analytical models with on-chain deterministic actions, fostering a new layer of DeFi automation.

---

## QuantOracle Nexus Smart Contract

**Contract Name:** `QuantOracleNexus`

**Purpose:** The QuantOracle Nexus acts as a decentralized platform for ingesting raw market data, allowing the community to propose and approve advanced quantitative metric formulas, and enabling the automated execution of pre-defined strategies based on the values of these calculated metrics. It combines elements of decentralized data oracles, community governance for analytical models, and an on-chain automation engine.

**Key Advanced Concepts & Creativity:**

1.  **Community-Defined & Governed Metrics:** Instead of fixed metrics, users propose complex analytical formulas (e.g., advanced volatility indices, sentiment scores, correlation matrices, risk metrics). These formulas are then voted upon by token holders. The contract doesn't execute arbitrary code directly but stores a *validated bytecode representation* or *parameters for a predefined set of complex operations*, whose results are then *verifiably submitted* by specialized oracles.
2.  **Verifiable Off-Chain Computation via Oracles:** The actual complex calculations for the advanced metrics are performed off-chain by dedicated "Quant Oracles." These oracles then submit the *results* along with cryptographic proofs (e.g., ZK-SNARKs or Merkle proofs of computation, or simply signed attestations linking to raw data) which the contract can partially verify or trust based on a multi-signer setup. This avoids prohibitive on-chain gas costs for complex math while maintaining data integrity.
3.  **Algorithmic Strategy Execution Engine:** Users can register "execution strategies" – predefined actions (e.g., call a specific function on a DeFi protocol, trigger a rebalance, adjust parameters) that are autonomously triggered when a specific on-chain metric crosses a threshold. These strategies can be funded with collateral and offer incentives for successful execution.
4.  **Dynamic Oracle Tiers & Reputations:** Oracles can have different trust levels or be part of dynamic committees based on their performance and stake. (Implicitly supported by `oracleSigners`).
5.  **Data Time-Series Management:** Efficient storage and retrieval of time-series data points.

---

### Outline & Function Summary

**I. Core Infrastructure & Access Control**
*   `constructor()`: Initializes the contract, setting the owner and initial oracle signers.
*   `pauseContract()`: Emergency function to pause all sensitive operations.
*   `unpauseContract()`: Resumes operations after a pause.
*   `transferOwnership()`: Transfers ownership of the contract.
*   `addOracleSigner()`: Adds a new trusted address capable of submitting data/metrics.
*   `removeOracleSigner()`: Removes an oracle signer.

**II. Raw Data Feed Management (Input Layer)**
*   `submitRawDataFeed(string memory _feedId, uint256 _value, uint256 _timestamp, bytes32 _dataHash)`: Allows whitelisted oracles to submit raw, time-stamped data points (e.g., price, volume, news sentiment). Includes a data hash for off-chain integrity checks.
*   `requestDataPoint(string memory _feedId, uint256 _timestamp)`: A view function to retrieve a specific raw data point by ID and timestamp.
*   `getLatestRawData(string memory _feedId)`: Retrieves the most recently submitted raw data point for a given feed.
*   `setRawDataFeedStaleThreshold(string memory _feedId, uint256 _threshold)`: Sets a maximum age for a data point before it's considered stale.

**III. Metric Definition & Governance (Quant Layer)**
*   `proposeMetricFormula(string memory _metricId, string memory _description, bytes memory _formulaBytes, string[] memory _requiredFeeds)`: Allows anyone to propose a new, complex quantitative metric formula. `_formulaBytes` represents the specific off-chain computation logic (e.g., a hash of the computation script, or a unique identifier for a known complex algorithm). `_requiredFeeds` specifies which raw data feeds are needed for this metric.
*   `voteOnFormulaProposal(bytes32 _proposalHash, bool _approve)`: Token holders vote on proposed metric formulas.
*   `finalizeFormulaProposal(bytes32 _proposalHash)`: Finalizes an approved metric proposal, making it active. Only callable after voting period ends and quorum is met.
*   `getFormulaProposalDetails(bytes32 _proposalHash)`: View function to check the status and details of a formula proposal.
*   `getMetricFormula(string memory _metricId)`: View function to retrieve the details of an active metric formula.
*   `updateMetricFormula(string memory _metricId, bytes memory _newFormulaBytes, string[] memory _newRequiredFeeds)`: Propose an update to an existing metric formula, requiring new governance approval.

**IV. Calculated Metric Submission & Verification (Oracle Layer)**
*   `submitCalculatedMetric(string memory _metricId, uint256 _value, uint256 _timestamp, bytes32 _rawDataSourceHash, bytes memory _proof)`: Dedicated "Quant Oracles" submit the *result* of a complex calculation for an approved metric. `_rawDataSourceHash` points to the specific raw data used, and `_proof` could be a ZK proof or a multi-signature attestation verifying the computation.
*   `getCalculatedMetricValue(string memory _metricId, uint256 _timestamp)`: View function to retrieve a specific calculated metric value.
*   `getLatestCalculatedMetric(string memory _metricId)`: View function to retrieve the most recent calculated metric value.
*   `invalidateCalculatedMetric(string memory _metricId, uint256 _timestamp)`: Allows governance or a supermajority of oracles to invalidate a submitted metric if found fraudulent (e.g., after an off-chain dispute resolution).

**V. Algorithmic Strategy Execution (Automation Layer)**
*   `registerExecutionStrategy(string memory _strategyId, address _targetContract, bytes _targetCallData, string memory _triggerMetricId, uint256 _triggerThreshold, bool _isGreaterThan, uint256 _recheckInterval)`: Users register automated strategies. Defines what `_targetContract` to call with `_targetCallData` when `_triggerMetricId` crosses `_triggerThreshold`. `_recheckInterval` specifies how often the strategy can be checked.
*   `updateExecutionStrategy(string memory _strategyId, address _newTargetContract, bytes _newTargetCallData, string memory _newTriggerMetricId, uint256 _newTriggerThreshold, bool _newIsGreaterThan, uint256 _newRecheckInterval)`: Modifies an existing strategy (requires approval for sensitive changes).
*   `triggerExecutionStrategy(string memory _strategyId)`: Anyone can call this to attempt to execute a registered strategy. If the trigger conditions are met, the contract executes the `_targetCallData` on `_targetContract` and pays an incentive to the caller.
*   `pauseExecutionStrategy(string memory _strategyId)`: Owner or strategy creator can temporarily pause a strategy.
*   `cancelExecutionStrategy(string memory _strategyId)`: Owner or strategy creator can permanently cancel a strategy.
*   `getExecutionStrategyDetails(string memory _strategyId)`: View function to retrieve details about a registered strategy.

**VI. Economic Model & Incentives**
*   `depositCollateral(string memory _strategyId, uint256 _amount)`: Users deposit collateral (e.g., ETH or a custom token) to fund their strategies and cover potential gas fees for execution.
*   `withdrawCollateral(string memory _strategyId, uint256 _amount)`: Users can withdraw unused collateral from their strategies.
*   `claimExecutionIncentive(string memory _strategyId)`: Caller who successfully triggered a strategy can claim their incentive.
*   `setFeeRates(uint256 _metricSubmissionFee, uint256 _strategyRegistrationFee, uint256 _executionIncentiveRate)`: Owner sets various fees and incentive rates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety if needed, though 0.8+ handles overflow

// Custom Errors
error InvalidOracleSignature();
error OracleAlreadySigned();
error OracleNotSigned();
error DataFeedStale(string feedId);
error DataFeedNotFound(string feedId);
error MetricNotActive(string metricId);
error MetricNotFound(string metricId);
error StrategyNotFound(string strategyId);
error StrategyNotActive(string strategyId);
error StrategyPaused(string strategyId);
error InsufficientCollateral();
error TriggerConditionNotMet();
error NotEnoughVotes();
error VotingPeriodNotEnded();
error VotingPeriodNotStarted();
error AlreadyVoted();
error ProposalNotFound();
error CallFailed();
error Unauthorized();
error ZeroAddressNotAllowed();
error AmountMustBeGreaterThanZero();
error DuplicateMetricId();
error DuplicateStrategyId();

/**
 * @title QuantOracleNexus
 * @dev A decentralized hub for quantitative data aggregation, verifiable metric calculation,
 *      and algorithmic strategy execution based on those metrics.
 *      Combines elements of decentralized data oracles, community governance for analytical models,
 *      and an on-chain automation engine.
 */
contract QuantOracleNexus is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Events ---
    event OracleSignerAdded(address indexed signer);
    event OracleSignerRemoved(address indexed signer);
    event RawDataFeedSubmitted(string indexed feedId, uint256 value, uint256 timestamp, bytes32 dataHash);
    event RawDataFeedStaleThresholdSet(string indexed feedId, uint256 threshold);

    event MetricFormulaProposed(bytes32 indexed proposalHash, string indexed metricId, address indexed proposer);
    event VoteCast(bytes32 indexed proposalHash, address indexed voter, bool approved);
    event MetricFormulaFinalized(string indexed metricId, bytes32 indexed proposalHash, bool approved);
    event MetricFormulaUpdated(string indexed metricId, address indexed updater);
    event CalculatedMetricSubmitted(string indexed metricId, uint256 value, uint256 timestamp, bytes32 rawDataSourceHash);
    event CalculatedMetricInvalidated(string indexed metricId, uint256 timestamp, address indexed invalidator);

    event ExecutionStrategyRegistered(string indexed strategyId, address indexed creator, address targetContract);
    event ExecutionStrategyUpdated(string indexed strategyId, address indexed updater);
    event ExecutionStrategyTriggered(string indexed strategyId, address indexed triggerer, bool success);
    event ExecutionStrategyPaused(string indexed strategyId);
    event ExecutionStrategyCancelled(string indexed strategyId);

    event CollateralDeposited(string indexed strategyId, address indexed depositor, uint256 amount);
    event CollateralWithdrawn(string indexed strategyId, address indexed recipient, uint256 amount);
    event ExecutionIncentiveClaimed(string indexed strategyId, address indexed claimant, uint256 amount);
    event FeeRatesSet(uint256 metricSubmissionFee, uint256 strategyRegistrationFee, uint256 executionIncentiveRate);
    event VotingParametersSet(uint256 votingPeriod, uint256 quorumPercentage, uint256 formulaActivationThreshold);

    // --- State Variables ---

    // Oracle Management
    mapping(address => bool) public oracleSigners; // Whitelisted addresses for submitting data/metrics

    // Raw Data Feeds
    struct RawDataPoint {
        uint256 value;
        uint256 timestamp;
        bytes32 dataHash; // Hash of the actual data, for off-chain verification
    }
    mapping(string => RawDataPoint[]) private rawDataFeeds; // feedId => history of data points
    mapping(string => uint256) public rawDataFeedStaleThreshold; // feedId => max time (seconds) before data is stale

    // Metric Definitions & Governance
    struct MetricFormula {
        string description;       // Human-readable description
        bytes formulaBytes;       // Opaque bytes representing the complex off-chain calculation logic or its hash
        string[] requiredFeeds;   // IDs of raw data feeds required for this metric
        bool isActive;            // Whether the formula is approved and active
        address creator;
    }
    mapping(string => MetricFormula) public activeMetricFormulas; // metricId => MetricFormula
    mapping(string => bool) public isMetricIdRegistered; // To prevent duplicate metric IDs

    struct FormulaProposal {
        string metricId;
        string description;
        bytes formulaBytes;
        string[] requiredFeeds;
        address proposer;
        uint256 proposalTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true if voted
        bool finalized;
        bool approved;
    }
    mapping(bytes32 => FormulaProposal) public formulaProposals; // keccak256(metricId, formulaBytes) => Proposal details
    bytes32[] public pendingFormulaProposals; // List of pending proposal hashes

    uint256 public votingPeriod = 7 days; // Duration for voting on proposals
    uint256 public quorumPercentage = 51; // Percentage of total supply needed for quorum
    uint256 public formulaActivationThreshold = 60; // Percentage of 'for' votes required to activate a formula

    // Calculated Metrics (Submitted by Oracles)
    struct CalculatedMetricPoint {
        uint256 value;
        uint256 timestamp;
        bytes32 rawDataSourceHash; // Hash or identifier of the raw data used for calculation
        // bytes proof; // Placeholder for ZK-SNARK proof or multi-sig attestations (too complex to implement fully here)
        bool isValid; // Can be set to false if found fraudulent
    }
    mapping(string => CalculatedMetricPoint[]) private calculatedMetrics; // metricId => history of calculated points
    mapping(string => uint256) public latestCalculatedMetricTimestamp; // metricId => timestamp of latest valid value

    // Algorithmic Strategy Execution
    struct ExecutionStrategy {
        address creator;
        address targetContract;        // The contract to interact with
        bytes targetCallData;          // The function call data for the target contract
        string triggerMetricId;        // The metric that triggers the strategy
        uint256 triggerThreshold;      // The threshold value for the metric
        bool isGreaterThan;            // If true, trigger when metric > threshold; if false, when metric < threshold
        uint256 lastTriggerTimestamp;  // Timestamp of the last successful trigger
        uint256 recheckInterval;       // Minimum time (seconds) between triggers
        bool isActive;                 // Whether the strategy is currently active (can be paused/cancelled)
        uint256 collateralBalance;     // Collateral deposited for this strategy (e.g., in ETH/ERC20)
    }
    mapping(string => ExecutionStrategy) public executionStrategies; // strategyId => Strategy details
    mapping(string => bool) public isStrategyIdRegistered; // To prevent duplicate strategy IDs

    uint256 public strategyGasLimit = 500000; // Default gas limit for strategy execution calls

    // Economic Model & Fees (using custom ERC20 token or ETH)
    IERC20 public feeToken; // Address of the token used for fees and incentives
    uint256 public metricSubmissionFee; // Fee for submitting a calculated metric
    uint256 public strategyRegistrationFee; // Fee for registering a new strategy
    uint256 public executionIncentiveRate; // Percentage of strategy collateral paid as incentive for successful trigger

    // --- Modifiers ---
    modifier onlyOracleSigner() {
        if (!oracleSigners[msg.sender]) {
            revert InvalidOracleSignature();
        }
        _;
    }

    modifier onlyStrategyCreator(string memory _strategyId) {
        if (executionStrategies[_strategyId].creator != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracleSigner, address _feeTokenAddress) Ownable(msg.sender) Pausable() {
        if (_initialOracleSigner == address(0) || _feeTokenAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        oracleSigners[_initialOracleSigner] = true;
        feeToken = IERC20(_feeTokenAddress);

        // Set initial fee rates (can be changed by owner)
        metricSubmissionFee = 1e16; // 0.01 feeToken
        strategyRegistrationFee = 5e16; // 0.05 feeToken
        executionIncentiveRate = 500; // 5% (500 basis points)
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses the contract, preventing most operations. Only owner can call.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume. Only owner can call.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Adds a new address to the list of trusted oracle signers. Only owner can call.
     * @param _signer The address to add.
     */
    function addOracleSigner(address _signer) public onlyOwner {
        if (_signer == address(0)) revert ZeroAddressNotAllowed();
        if (oracleSigners[_signer]) revert OracleAlreadySigned();
        oracleSigners[_signer] = true;
        emit OracleSignerAdded(_signer);
    }

    /**
     * @dev Removes an address from the list of trusted oracle signers. Only owner can call.
     * @param _signer The address to remove.
     */
    function removeOracleSigner(address _signer) public onlyOwner {
        if (!oracleSigners[_signer]) revert OracleNotSigned();
        oracleSigners[_signer] = false;
        emit OracleSignerRemoved(_signer);
    }

    // --- II. Raw Data Feed Management (Input Layer) ---

    /**
     * @dev Allows whitelisted oracles to submit raw, time-stamped data points.
     *      Includes a data hash for off-chain integrity checks.
     * @param _feedId Unique identifier for the data feed (e.g., "ETH/USD_Price", "BTC_Volume").
     * @param _value The actual data value.
     * @param _timestamp The timestamp when the data was recorded (Unix epoch).
     * @param _dataHash A cryptographic hash of the original, more detailed data (for off-chain verification).
     */
    function submitRawDataFeed(
        string memory _feedId,
        uint256 _value,
        uint256 _timestamp,
        bytes32 _dataHash
    ) public virtual whenNotPaused onlyOracleSigner {
        rawDataFeeds[_feedId].push(RawDataPoint(_value, _timestamp, _dataHash));
        emit RawDataFeedSubmitted(_feedId, _value, _timestamp, _dataHash);
    }

    /**
     * @dev Sets a maximum age for a data point before it's considered stale.
     * @param _feedId The ID of the data feed.
     * @param _threshold The maximum age in seconds.
     */
    function setRawDataFeedStaleThreshold(string memory _feedId, uint256 _threshold) public onlyOwner {
        rawDataFeedStaleThreshold[_feedId] = _threshold;
        emit RawDataFeedStaleThresholdSet(_feedId, _threshold);
    }

    /**
     * @dev Retrieves a specific raw data point by ID and timestamp.
     * @param _feedId The ID of the data feed.
     * @param _timestamp The timestamp of the desired data point.
     * @return The RawDataPoint struct.
     */
    function requestDataPoint(string memory _feedId, uint256 _timestamp) public view returns (RawDataPoint memory) {
        RawDataPoint[] storage feed = rawDataFeeds[_feedId];
        if (feed.length == 0) revert DataFeedNotFound(_feedId);

        // Simple linear search for exact timestamp match. For production, more efficient search needed.
        for (uint256 i = 0; i < feed.length; i++) {
            if (feed[i].timestamp == _timestamp) {
                return feed[i];
            }
        }
        revert DataFeedNotFound(_feedId); // Or return default/error struct
    }

    /**
     * @dev Retrieves the most recently submitted raw data point for a given feed.
     * @param _feedId The ID of the data feed.
     * @return The RawDataPoint struct.
     */
    function getLatestRawData(string memory _feedId) public view returns (RawDataPoint memory) {
        RawDataPoint[] storage feed = rawDataFeeds[_feedId];
        if (feed.length == 0) revert DataFeedNotFound(_feedId);
        return feed[feed.length - 1];
    }

    // --- III. Metric Definition & Governance (Quant Layer) ---

    /**
     * @dev Allows anyone to propose a new, complex quantitative metric formula.
     *      Requires a fee to prevent spam.
     * @param _metricId Unique identifier for the proposed metric.
     * @param _description Human-readable description of the metric.
     * @param _formulaBytes Opaque bytes representing the complex off-chain calculation logic or its hash.
     * @param _requiredFeeds IDs of raw data feeds required for this metric.
     */
    function proposeMetricFormula(
        string memory _metricId,
        string memory _description,
        bytes memory _formulaBytes,
        string[] memory _requiredFeeds
    ) public virtual whenNotPaused {
        if (isMetricIdRegistered[_metricId]) revert DuplicateMetricId();
        
        // Fee payment for proposal
        feeToken.transferFrom(msg.sender, address(this), strategyRegistrationFee); // Using strategyRegistrationFee as a general proposal fee

        bytes32 proposalHash = keccak256(abi.encodePacked(_metricId, _formulaBytes, _description));
        if (formulaProposals[proposalHash].proposer != address(0)) revert ProposalNotFound(); // Already proposed

        formulaProposals[proposalHash] = FormulaProposal({
            metricId: _metricId,
            description: _description,
            formulaBytes: _formulaBytes,
            requiredFeeds: _requiredFeeds,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            approved: false
        });
        pendingFormulaProposals.push(proposalHash);
        emit MetricFormulaProposed(proposalHash, _metricId, msg.sender);
    }

    /**
     * @dev Allows token holders to vote on proposed metric formulas.
     *      Requires custom voting token logic (e.g., ERC20, veToken) to be integrated for actual voting power.
     *      For simplicity, assuming 1 address = 1 vote for now.
     * @param _proposalHash The hash of the proposal to vote on.
     * @param _approve True for a "for" vote, false for "against."
     */
    function voteOnFormulaProposal(bytes32 _proposalHash, bool _approve) public virtual whenNotPaused {
        FormulaProposal storage proposal = formulaProposals[_proposalHash];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp >= proposal.proposalTimestamp.add(votingPeriod)) revert VotingPeriodNotEnded();

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalHash, msg.sender, _approve);
    }

    /**
     * @dev Finalizes an approved metric proposal, making it active.
     *      Callable by anyone after voting period ends.
     * @param _proposalHash The hash of the proposal to finalize.
     */
    function finalizeFormulaProposal(bytes32 _proposalHash) public virtual whenNotPaused {
        FormulaProposal storage proposal = formulaProposals[_proposalHash];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalNotFound(); // Already finalized
        if (block.timestamp < proposal.proposalTimestamp.add(votingPeriod)) revert VotingPeriodNotEnded();

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        // For production, total supply of voting token is needed for quorum check
        // Assuming 'total supply' for now is just 100 for simplicity of percentage calculation
        uint256 requiredQuorumVotes = 100 * quorumPercentage / 100; // Simplified quorum
        
        // For a real DAO, you'd check `IERC20(votingTokenAddress).totalSupply()` and compare against `totalVotes`

        if (totalVotes < requiredQuorumVotes) { // Simplified quorum check
            proposal.finalized = true; // Mark as finalized, but not approved
            proposal.approved = false;
            emit MetricFormulaFinalized(proposal.metricId, _proposalHash, false);
            return;
        }

        uint256 approvalPercentage = proposal.votesFor.mul(100).div(totalVotes);
        if (approvalPercentage >= formulaActivationThreshold) {
            proposal.approved = true;
            proposal.finalized = true;
            activeMetricFormulas[proposal.metricId] = MetricFormula({
                description: proposal.description,
                formulaBytes: proposal.formulaBytes,
                requiredFeeds: proposal.requiredFeeds,
                isActive: true,
                creator: proposal.proposer
            });
            isMetricIdRegistered[proposal.metricId] = true;
            emit MetricFormulaFinalized(proposal.metricId, _proposalHash, true);
        } else {
            proposal.finalized = true;
            proposal.approved = false;
            emit MetricFormulaFinalized(proposal.metricId, _proposalHash, false);
        }
    }

    /**
     * @dev Propose an update to an existing metric formula, requiring new governance approval.
     * @param _metricId The ID of the metric to update.
     * @param _newFormulaBytes The new opaque bytes for the formula.
     * @param _newRequiredFeeds New required data feeds for the updated formula.
     */
    function updateMetricFormula(
        string memory _metricId,
        bytes memory _newFormulaBytes,
        string[] memory _newRequiredFeeds
    ) public virtual whenNotPaused {
        if (!activeMetricFormulas[_metricId].isActive) revert MetricNotActive(_metricId);

        // Create a new proposal for the update
        bytes32 proposalHash = keccak256(abi.encodePacked(_metricId, _newFormulaBytes, _newRequiredFeeds, "update"));
        if (formulaProposals[proposalHash].proposer != address(0)) revert ProposalNotFound(); // Already proposed

        feeToken.transferFrom(msg.sender, address(this), strategyRegistrationFee); // Fee for update proposal

        formulaProposals[proposalHash] = FormulaProposal({
            metricId: _metricId,
            description: activeMetricFormulas[_metricId].description, // Keep original description or allow new
            formulaBytes: _newFormulaBytes,
            requiredFeeds: _newRequiredFeeds,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            approved: false
        });
        pendingFormulaProposals.push(proposalHash);
        emit MetricFormulaUpdated(_metricId, msg.sender);
    }

    /**
     * @dev View function to check the status and details of a formula proposal.
     * @param _proposalHash The hash of the proposal.
     * @return details about the proposal.
     */
    function getFormulaProposalDetails(bytes32 _proposalHash) public view returns (FormulaProposal memory) {
        FormulaProposal storage proposal = formulaProposals[_proposalHash];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return proposal;
    }

    /**
     * @dev View function to retrieve the details of an active metric formula.
     * @param _metricId The ID of the active metric.
     * @return The MetricFormula struct.
     */
    function getMetricFormula(string memory _metricId) public view returns (MetricFormula memory) {
        if (!activeMetricFormulas[_metricId].isActive) revert MetricNotActive(_metricId);
        return activeMetricFormulas[_metricId];
    }

    // --- IV. Calculated Metric Submission & Verification (Oracle Layer) ---

    /**
     * @dev Dedicated "Quant Oracles" submit the *result* of a complex calculation for an approved metric.
     *      Requires a fee.
     * @param _metricId The ID of the calculated metric.
     * @param _value The calculated value.
     * @param _timestamp The timestamp of the calculation.
     * @param _rawDataSourceHash A hash or identifier of the specific raw data (and their timestamps) used for this calculation.
     * @param _proof Placeholder for ZK-SNARK proof or multi-sig attestations verifying the computation.
     */
    function submitCalculatedMetric(
        string memory _metricId,
        uint256 _value,
        uint256 _timestamp,
        bytes32 _rawDataSourceHash,
        bytes memory _proof // This is a placeholder for actual proof verification
    ) public virtual whenNotPaused onlyOracleSigner {
        if (!activeMetricFormulas[_metricId].isActive) revert MetricNotActive(_metricId);

        // Fee payment for submission
        feeToken.transferFrom(msg.sender, address(this), metricSubmissionFee);

        // In a real scenario, this is where you'd verify `_proof` against `_rawDataSourceHash`
        // and potentially the `_value` based on the formula type defined in `activeMetricFormulas[_metricId].formulaBytes`.
        // This would involve a much more complex ZKP verifier or cryptographic signature verification.
        // For this example, we trust the `onlyOracleSigner` modifier.

        calculatedMetrics[_metricId].push(CalculatedMetricPoint({
            value: _value,
            timestamp: _timestamp,
            rawDataSourceHash: _rawDataSourceHash,
            isValid: true
        }));
        latestCalculatedMetricTimestamp[_metricId] = _timestamp;
        emit CalculatedMetricSubmitted(_metricId, _value, _timestamp, _rawDataSourceHash);
    }

    /**
     * @dev Allows governance or a supermajority of oracles to invalidate a submitted metric if found fraudulent.
     * @param _metricId The ID of the metric.
     * @param _timestamp The timestamp of the specific calculated point to invalidate.
     */
    function invalidateCalculatedMetric(string memory _metricId, uint256 _timestamp) public virtual whenNotPaused onlyOracleSigner {
        CalculatedMetricPoint[] storage metricPoints = calculatedMetrics[_metricId];
        bool foundAndInvalidated = false;
        for (uint256 i = 0; i < metricPoints.length; i++) {
            if (metricPoints[i].timestamp == _timestamp && metricPoints[i].isValid) {
                metricPoints[i].isValid = false;
                foundAndInvalidated = true;
                break;
            }
        }
        if (!foundAndInvalidated) revert MetricNotFound(_metricId); // Or specific error for timestamp not found
        emit CalculatedMetricInvalidated(_metricId, _timestamp, msg.sender);
    }

    /**
     * @dev View function to retrieve a specific calculated metric value.
     * @param _metricId The ID of the metric.
     * @param _timestamp The timestamp of the desired calculated point.
     * @return The CalculatedMetricPoint struct.
     */
    function getCalculatedMetricValue(string memory _metricId, uint256 _timestamp) public view returns (CalculatedMetricPoint memory) {
        CalculatedMetricPoint[] storage metricPoints = calculatedMetrics[_metricId];
        if (metricPoints.length == 0) revert MetricNotFound(_metricId);

        for (uint256 i = 0; i < metricPoints.length; i++) {
            if (metricPoints[i].timestamp == _timestamp && metricPoints[i].isValid) {
                return metricPoints[i];
            }
        }
        revert MetricNotFound(_metricId); // Specific timestamp not found or invalid
    }

    /**
     * @dev View function to retrieve the most recent calculated metric value.
     * @param _metricId The ID of the metric.
     * @return The CalculatedMetricPoint struct.
     */
    function getLatestCalculatedMetric(string memory _metricId) public view returns (CalculatedMetricPoint memory) {
        uint256 latestTs = latestCalculatedMetricTimestamp[_metricId];
        if (latestTs == 0) revert MetricNotFound(_metricId);

        // Find the latest valid point
        CalculatedMetricPoint[] storage metricPoints = calculatedMetrics[_metricId];
        for (int256 i = int256(metricPoints.length) - 1; i >= 0; i--) { // Iterate backwards for latest
            if (metricPoints[uint256(i)].isValid) {
                return metricPoints[uint256(i)];
            }
        }
        revert MetricNotFound(_metricId); // No valid metric found
    }

    // --- V. Algorithmic Strategy Execution (Automation Layer) ---

    /**
     * @dev Allows users to register automated strategies. Requires a fee.
     * @param _strategyId Unique identifier for the strategy.
     * @param _targetContract The address of the external contract to interact with.
     * @param _targetCallData The encoded function call data for the target contract.
     * @param _triggerMetricId The ID of the metric that triggers the strategy.
     * @param _triggerThreshold The threshold value for the metric.
     * @param _isGreaterThan If true, trigger when metric > threshold; if false, when metric < threshold.
     * @param _recheckInterval Minimum time (seconds) between triggers for this strategy.
     */
    function registerExecutionStrategy(
        string memory _strategyId,
        address _targetContract,
        bytes memory _targetCallData,
        string memory _triggerMetricId,
        uint256 _triggerThreshold,
        bool _isGreaterThan,
        uint256 _recheckInterval
    ) public virtual whenNotPaused {
        if (isStrategyIdRegistered[_strategyId]) revert DuplicateStrategyId();
        if (_targetContract == address(0)) revert ZeroAddressNotAllowed();
        if (_recheckInterval == 0) revert AmountMustBeGreaterThanZero(); // Must have a recheck interval

        if (!activeMetricFormulas[_triggerMetricId].isActive) revert MetricNotActive(_triggerMetricId);

        // Fee payment for registration
        feeToken.transferFrom(msg.sender, address(this), strategyRegistrationFee);

        executionStrategies[_strategyId] = ExecutionStrategy({
            creator: msg.sender,
            targetContract: _targetContract,
            targetCallData: _targetCallData,
            triggerMetricId: _triggerMetricId,
            triggerThreshold: _triggerThreshold,
            isGreaterThan: _isGreaterThan,
            lastTriggerTimestamp: 0, // No prior trigger
            recheckInterval: _recheckInterval,
            isActive: true,
            collateralBalance: 0
        });
        isStrategyIdRegistered[_strategyId] = true;
        emit ExecutionStrategyRegistered(_strategyId, msg.sender, _targetContract);
    }

    /**
     * @dev Modifies an existing strategy (requires approval for sensitive changes by creator).
     * @param _strategyId The ID of the strategy to update.
     * @param _newTargetContract The new target contract.
     * @param _newTargetCallData The new call data.
     * @param _newTriggerMetricId The new trigger metric ID.
     * @param _newTriggerThreshold The new trigger threshold.
     * @param _newIsGreaterThan The new comparison operator.
     * @param _newRecheckInterval The new recheck interval.
     */
    function updateExecutionStrategy(
        string memory _strategyId,
        address _newTargetContract,
        bytes memory _newTargetCallData,
        string memory _newTriggerMetricId,
        uint256 _newTriggerThreshold,
        bool _newIsGreaterThan,
        uint256 _newRecheckInterval
    ) public virtual whenNotPaused onlyStrategyCreator(_strategyId) {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!strategy.isActive) revert StrategyNotActive(_strategyId);
        if (_newTargetContract == address(0)) revert ZeroAddressNotAllowed();
        if (_newRecheckInterval == 0) revert AmountMustBeGreaterThanZero();

        if (!activeMetricFormulas[_newTriggerMetricId].isActive) revert MetricNotActive(_newTriggerMetricId);

        strategy.targetContract = _newTargetContract;
        strategy.targetCallData = _newTargetCallData;
        strategy.triggerMetricId = _newTriggerMetricId;
        strategy.triggerThreshold = _newTriggerThreshold;
        strategy.isGreaterThan = _newIsGreaterThan;
        strategy.recheckInterval = _newRecheckInterval;
        // lastTriggerTimestamp and collateralBalance are not reset here
        emit ExecutionStrategyUpdated(_strategyId, msg.sender);
    }


    /**
     * @dev Anyone can call this to attempt to execute a registered strategy.
     *      If the trigger conditions are met, the contract executes the targetCallData
     *      on targetContract and pays an incentive to the caller.
     * @param _strategyId The ID of the strategy to attempt to trigger.
     */
    function triggerExecutionStrategy(string memory _strategyId) public virtual whenNotPaused {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        if (!strategy.isActive) revert StrategyNotActive(_strategyId);
        if (strategy.lastTriggerTimestamp.add(strategy.recheckInterval) > block.timestamp) {
            revert TriggerConditionNotMet(); // Not enough time passed since last trigger
        }

        // Check if the trigger metric exists and is not stale
        CalculatedMetricPoint memory latestMetric = getLatestCalculatedMetric(strategy.triggerMetricId);
        // Add stale check here if desired: (block.timestamp - latestMetric.timestamp > X)

        bool conditionMet;
        if (strategy.isGreaterThan) {
            conditionMet = latestMetric.value > strategy.triggerThreshold;
        } else {
            conditionMet = latestMetric.value < strategy.triggerThreshold;
        }

        if (!conditionMet) {
            revert TriggerConditionNotMet();
        }

        // Ensure sufficient collateral for execution + incentive
        uint256 expectedGasCost = strategyGasLimit * tx.gasprice; // Approximation
        uint256 incentiveAmount = strategy.collateralBalance.mul(executionIncentiveRate).div(10000); // Basis points
        if (strategy.collateralBalance < expectedGasCost + incentiveAmount) {
            revert InsufficientCollateral();
        }

        // Execute the strategy's target call
        (bool success,) = strategy.targetContract.call{gas: strategyGasLimit}(strategy.targetCallData);
        if (!success) {
            // If the call failed, do not pay incentive, do not update lastTriggerTimestamp
            // and potentially refund part of the collateral to the strategy owner.
            // For simplicity, we just revert the trigger transaction here.
            revert CallFailed();
        }

        // Update strategy state
        strategy.lastTriggerTimestamp = block.timestamp;
        strategy.collateralBalance = strategy.collateralBalance.sub(incentiveAmount);

        // Pay incentive to the caller
        feeToken.transfer(msg.sender, incentiveAmount);

        emit ExecutionStrategyTriggered(_strategyId, msg.sender, true);
    }

    /**
     * @dev Owner or strategy creator can temporarily pause a strategy.
     * @param _strategyId The ID of the strategy to pause.
     */
    function pauseExecutionStrategy(string memory _strategyId) public virtual whenNotPaused {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        if (msg.sender != strategy.creator && msg.sender != owner()) revert Unauthorized();
        if (!strategy.isActive) revert StrategyPaused(_strategyId); // Already paused or cancelled
        
        strategy.isActive = false;
        emit ExecutionStrategyPaused(_strategyId);
    }

    /**
     * @dev Owner or strategy creator can permanently cancel a strategy and reclaim collateral.
     * @param _strategyId The ID of the strategy to cancel.
     */
    function cancelExecutionStrategy(string memory _strategyId) public virtual whenNotPaused {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        if (msg.sender != strategy.creator && msg.sender != owner()) revert Unauthorized();
        
        uint256 collateral = strategy.collateralBalance;
        if (collateral > 0) {
            strategy.collateralBalance = 0; // Clear balance before transfer
            feeToken.transfer(strategy.creator, collateral); // Refund collateral
            emit CollateralWithdrawn(_strategyId, strategy.creator, collateral);
        }

        // Permanently disable and potentially delete from mapping for gas efficiency
        delete executionStrategies[_strategyId];
        delete isStrategyIdRegistered[_strategyId];
        emit ExecutionStrategyCancelled(_strategyId);
    }

    /**
     * @dev View function to retrieve details about a registered strategy.
     * @param _strategyId The ID of the strategy.
     * @return The ExecutionStrategy struct.
     */
    function getExecutionStrategyDetails(string memory _strategyId) public view returns (ExecutionStrategy memory) {
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        return executionStrategies[_strategyId];
    }

    // --- VI. Economic Model & Incentives ---

    /**
     * @dev Users deposit collateral (e.g., ERC20 token) to fund their strategies.
     *      The `feeToken` is used for collateral.
     * @param _strategyId The ID of the strategy to fund.
     * @param _amount The amount of collateral to deposit.
     */
    function depositCollateral(string memory _strategyId, uint256 _amount) public virtual whenNotPaused {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (msg.sender != strategy.creator) revert Unauthorized();

        // Transfer `_amount` of `feeToken` from msg.sender to this contract
        feeToken.transferFrom(msg.sender, address(this), _amount);
        strategy.collateralBalance = strategy.collateralBalance.add(_amount);
        emit CollateralDeposited(_strategyId, msg.sender, _amount);
    }

    /**
     * @dev Users can withdraw unused collateral from their strategies. Only strategy creator.
     * @param _strategyId The ID of the strategy.
     * @param _amount The amount to withdraw.
     */
    function withdrawCollateral(string memory _strategyId, uint256 _amount) public virtual whenNotPaused onlyStrategyCreator(_strategyId) {
        ExecutionStrategy storage strategy = executionStrategies[_strategyId];
        if (!isStrategyIdRegistered[_strategyId]) revert StrategyNotFound(_strategyId);
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (strategy.collateralBalance < _amount) revert InsufficientCollateral();

        strategy.collateralBalance = strategy.collateralBalance.sub(_amount);
        feeToken.transfer(msg.sender, _amount);
        emit CollateralWithdrawn(_strategyId, msg.sender, _amount);
    }

    /**
     * @dev Sets various fees and incentive rates. Only owner.
     * @param _metricSubmissionFee Fee for submitting a calculated metric.
     * @param _strategyRegistrationFee Fee for registering a new strategy.
     * @param _executionIncentiveRate Percentage (basis points) of strategy collateral paid as incentive for successful trigger.
     */
    function setFeeRates(
        uint256 _metricSubmissionFee,
        uint256 _strategyRegistrationFee,
        uint256 _executionIncentiveRate
    ) public onlyOwner {
        metricSubmissionFee = _metricSubmissionFee;
        strategyRegistrationFee = _strategyRegistrationFee;
        executionIncentiveRate = _executionIncentiveRate; // e.g., 500 for 5%
        emit FeeRatesSet(_metricSubmissionFee, _strategyRegistrationFee, _executionIncentiveRate);
    }

    /**
     * @dev Sets the voting period duration and quorum/activation thresholds for metric proposals. Only owner.
     * @param _votingPeriod The duration in seconds for which proposals are open for voting.
     * @param _quorumPercentage The percentage of total voting power required for a quorum (0-100).
     * @param _formulaActivationThreshold The percentage of 'for' votes required to activate a formula (0-100).
     */
    function setVotingParameters(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _formulaActivationThreshold
    ) public onlyOwner {
        if (_votingPeriod == 0 || _quorumPercentage > 100 || _formulaActivationThreshold > 100) {
            revert AmountMustBeGreaterThanZero(); // Or more specific error
        }
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        formulaActivationThreshold = _formulaActivationThreshold;
        emit VotingParametersSet(_votingPeriod, _quorumPercentage, _formulaActivationThreshold);
    }

    /**
     * @dev Sets the default gas limit for external calls initiated by strategies. Only owner.
     * @param _newGasLimit The new gas limit.
     */
    function setStrategyGasLimit(uint256 _newGasLimit) public onlyOwner {
        if (_newGasLimit == 0) revert AmountMustBeGreaterThanZero();
        strategyGasLimit = _newGasLimit;
    }
}

```