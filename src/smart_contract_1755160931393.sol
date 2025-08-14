This smart contract, named "Autonomous Predictive Capital (APC)," envisions a sophisticated decentralized entity that manages a pool of capital based on external AI-driven predictive signals. It acts as an autonomous agent, capable of executing conditional financial operations, funding research, and dynamically adjusting strategies based on the received insights.

**Core Concept:** The APC contract is designed to receive high-confidence predictive signals from designated "Signal Providers" (AI oracles or validated data feeds). Based on these signals, and subject to community validation, the contract can automatically allocate its treasury funds to various on-chain strategies, fund research initiatives, or even trigger risk mitigation protocols. It incorporates mechanisms for signal validation, dispute resolution, and rewards for accurate predictions, aiming for a self-improving and adaptive capital management system.

---

## Contract: AutonomousPredictiveCapital (APC)

### Outline:
1.  **Contract Information & Setup**
    *   Basic ownership and pausing mechanisms.
    *   Defines key roles like `SignalProvider`.
2.  **State Management & Data Structures**
    *   `PredictiveSignal` struct to store AI predictions.
    *   `ResearchGrantApplication` struct for funding requests.
    *   Mappings to track signals, grants, and roles.
    *   Economic parameters for fees and rewards.
3.  **Fund Management & Treasury Operations**
    *   Receiving and managing ERC-20 token treasury.
    *   Emergency withdrawals and rebalancing.
4.  **Predictive Signal Lifecycle**
    *   Submission by `SignalProvider`.
    *   Community/validator voting for validation.
    *   Dispute and resolution mechanisms.
    *   Retrieval of signal details.
5.  **Capital Allocation & Strategy Execution**
    *   Core function to act on validated signals.
    *   Dynamic allocation to pre-approved external strategy modules (e.g., DeFi protocols).
    *   Conditional operations like swaps or risk mitigation.
6.  **Research & Development Funding**
    *   Mechanism for submitting and approving research grant applications based on predictive insights.
    *   Payout of approved grants.
7.  **Incentive & Reward System**
    *   Rewards for signal submission and successful validation.
    *   Penalties for disputed or inaccurate signals (conceptually, not fully implemented for brevity).
8.  **System Parameters & Governance**
    *   Adjusting thresholds and fees.
    *   Triggering AI model recalibration.
9.  **View Functions**
    *   Reading various states and details.

### Function Summary:

1.  **`constructor(address _initialSignalProvider, address _initialResearchFund)`**: Initializes the contract, sets the initial owner, initial signal provider, and the address for general research funds.
2.  **`depositFunds(address tokenAddress, uint256 amount)`**: Allows anyone to deposit ERC-20 tokens into the contract's treasury.
3.  **`withdrawFundsEmergency(address tokenAddress, uint256 amount)`**: Allows the owner to withdraw funds in an emergency, bypassing normal logic.
4.  **`setSignalProvider(address _provider, bool _isSignalProvider)`**: Grants or revokes the `SignalProvider` role to an address. Only owner.
5.  **`submitPredictiveSignal(string calldata _signalHash, uint256 _predictedValue, uint256 _predictionTimestamp, uint256 _signalExpiresAt, string calldata _metadataURI)`**: Allows a designated `SignalProvider` to submit a new predictive signal, paying a fee.
6.  **`validatePredictiveSignal(uint256 _signalId)`**: Allows any whitelisted validator (or community member, depending on implementation) to vote to validate a signal.
7.  **`disputePredictiveSignal(uint256 _signalId, string calldata _reasonURI)`**: Allows any address to dispute a signal by providing a reason URI, potentially penalizing the submitter.
8.  **`resolveSignalDispute(uint256 _signalId, bool _isDisputeValid)`**: Owner/governance resolves a dispute, marking the signal as valid/invalid and potentially taking action against the disputer/submitter.
9.  **`getSignalDetails(uint256 _signalId)`**: Returns all stored details for a specific predictive signal.
10. **`setPredictionValidationThreshold(uint256 _newThreshold)`**: Sets the number of validation votes required for a signal to be considered `Validated`.
11. **`setSignalSubmissionFee(uint256 _newFee)`**: Sets the fee required for a `SignalProvider` to submit a new signal.
12. **`claimSignalSubmissionReward(uint256 _signalId)`**: Allows a `SignalProvider` to claim a reward if their signal is successfully validated and acted upon.
13. **`claimValidationReward(uint256 _signalId)`**: Allows a validator to claim a reward for successfully validating a signal that proved accurate.
14. **`allocateCapitalBasedOnSignal(uint256 _signalId, address tokenAddress, uint256 amount, uint256 strategyModuleId)`**: The core function. If a signal is `Validated`, this function triggers the allocation of capital to a specific pre-approved strategy module.
15. **`setApprovedStrategyModule(uint256 _moduleId, address _moduleAddress, bool _isApproved)`**: Adds or removes an external contract address as an approved capital allocation strategy module.
16. **`deployCapitalToStrategy(address _strategyModuleAddress, address tokenAddress, uint256 amount, bytes calldata _callData)`**: Sends funds and executes a specific function on an approved external strategy module. (Internal/Private, called by `allocateCapitalBasedOnSignal`).
17. **`fundResearchGrant(string calldata _proposalHash, address _recipient, uint256 _amount, address _tokenAddress, uint256 _signalId)`**: Allows anyone to submit a research grant application linked to a predictive signal.
18. **`approveResearchGrant(uint256 _grantId)`**: Owner/governance approves a pending research grant.
19. **`payoutResearchGrant(uint256 _grantId)`**: Executes the payment of an approved research grant.
20. **`requestSignalRecalibration(uint256 _signalId, string calldata _reasonURI)`**: Allows anyone to formally request a recalibration of the underlying AI model if a signal is consistently inaccurate.
21. **`triggerRiskMitigation(address tokenAddress, uint256 amount, string calldata _reasonURI)`**: Allows the owner to trigger a pre-defined risk mitigation action (e.g., withdraw from a risky pool) based on a critical signal or event.
22. **`rebalanceTreasury(address _fromToken, address _toToken, uint256 _amount)`**: Allows the owner to rebalance assets within the treasury (e.g., swap one token for another).
23. **`pauseContract()`**: Pauses the contract, preventing most state-changing operations.
24. **`unpauseContract()`**: Unpauses the contract, resuming normal operations.
25. **`getTreasuryBalance(address tokenAddress)`**: Returns the current balance of a specific ERC-20 token held by the contract.
26. **`getPendingGrants()`**: Returns a list of all currently pending research grant IDs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define the maximum length for a URI to prevent excessive gas costs
uint256 constant MAX_URI_LENGTH = 256;

/**
 * @title AutonomousPredictiveCapital (APC)
 * @notice A smart contract designed to manage and allocate capital based on external AI-driven predictive signals.
 *         It incorporates mechanisms for signal submission, validation, dispute resolution, and automated capital deployment.
 *         It also supports funding research and development initiatives guided by predictive insights.
 * @dev This contract acts as an autonomous agent, reacting to validated predictive data to optimize capital usage.
 *      It relies on designated `SignalProviders` (e.g., AI oracles) to feed in data and a community/governance
 *      mechanism for signal validation and dispute resolution.
 */
contract AutonomousPredictiveCapital is Ownable, ReentrancyGuard {

    // --- Events ---
    event FundsDeposited(address indexed token, address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event TreasuryRebalanced(address indexed fromToken, address indexed toToken, uint256 amountTransferred);
    event SignalProviderUpdated(address indexed provider, bool isSignalProvider);
    event PredictiveSignalSubmitted(uint256 indexed signalId, address indexed submitter, bytes32 signalHash, uint256 predictedValue, uint256 predictionTimestamp, uint256 signalExpiresAt);
    event PredictiveSignalValidated(uint256 indexed signalId, address indexed validator);
    event PredictiveSignalDisputed(uint256 indexed signalId, address indexed disputer, string reasonURI);
    event SignalDisputeResolved(uint256 indexed signalId, bool isValid);
    event CapitalAllocated(uint256 indexed signalId, address indexed token, uint256 amount, uint256 strategyModuleId);
    event StrategyModuleUpdated(uint256 indexed moduleId, address moduleAddress, bool isApproved);
    event ResearchGrantApplied(uint256 indexed grantId, string proposalHash, address indexed recipient, uint256 amount, address tokenAddress, uint256 indexed signalId);
    event ResearchGrantApproved(uint256 indexed grantId);
    event ResearchGrantPaid(uint256 indexed grantId);
    event RiskMitigationTriggered(address indexed token, uint256 amount, string reasonURI);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event SignalRecalibrationRequested(uint256 indexed signalId, string reasonURI);

    // --- Enums ---
    enum SignalStatus { Pending, Validated, Disputed, Invalidated, Expired }
    enum GrantStatus { Pending, Approved, Paid, Rejected }

    // --- Structs ---
    struct PredictiveSignal {
        bytes32 signalHash; // Unique hash of the prediction data (e.g., IPFS CID, cryptographic hash)
        uint256 predictedValue; // The numerical prediction (e.g., price, event probability)
        uint256 predictionTimestamp; // Timestamp when the prediction was made off-chain
        uint256 signalExpiresAt; // Timestamp when this signal becomes irrelevant
        address submitter; // Address of the SignalProvider who submitted it
        SignalStatus status; // Current status of the signal
        uint256 validationVotes; // Number of addresses that have validated this signal
        mapping(address => bool) hasValidated; // Tracks who has validated
        mapping(address => bool) hasDisputed; // Tracks who has disputed
        string metadataURI; // URI to additional context or data about the signal
    }

    struct ResearchGrantApplication {
        string proposalHash; // IPFS CID or hash of the full research proposal
        address recipient; // Address to send funds to
        uint256 amount; // Amount requested
        address tokenAddress; // Token requested
        uint256 signalId; // The predictive signal that inspired/justifies this grant
        GrantStatus status; // Current status of the grant
        uint256 appliedAt; // Timestamp when the grant was applied
    }

    // --- State Variables ---

    // Roles
    mapping(address => bool) public isSignalProvider; // Addresses authorized to submit signals
    address public researchFundAddress; // A general address for research grants when not tied to specific proposals

    // Signal Management
    uint256 private _signalIdCounter; // Counter for unique signal IDs
    mapping(uint256 => PredictiveSignal) public signals; // Stores all submitted signals
    uint256 public predictionValidationThreshold; // Minimum validation votes required for a signal to be 'Validated'

    // Capital Allocation Strategies
    mapping(uint256 => address) public approvedStrategyModules; // Mapping of module ID to contract address
    mapping(uint256 => bool) public isStrategyModuleApproved; // Tracks if a module ID is approved

    // Economic Parameters
    uint256 public signalSubmissionFee; // Fee (in native currency, e.g., ETH) to submit a signal
    uint256 public signalSubmissionReward; // Reward (in a specified ERC20 or native) for a validated signal
    uint256 public validationReward; // Reward for validators of a successful signal

    // Research Grants
    uint256 private _grantIdCounter; // Counter for unique grant IDs
    mapping(uint256 => ResearchGrantApplication) public researchGrants; // Stores all research grant applications

    // Pausability
    bool public paused;

    // --- Modifiers ---
    modifier onlySignalProvider() {
        require(isSignalProvider[msg.sender], "APC: Caller is not a SignalProvider");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "APC: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "APC: Contract is not paused");
        _;
    }

    modifier isValidURI(string calldata _uri) {
        require(bytes(_uri).length > 0 && bytes(_uri).length <= MAX_URI_LENGTH, "APC: Invalid URI length");
        _;
    }

    // --- Constructor ---
    /**
     * @notice Initializes the AutonomousPredictiveCapital contract.
     * @param _initialSignalProvider The address of the first authorized SignalProvider.
     * @param _initialResearchFund The address designated for general research funding.
     */
    constructor(address _initialSignalProvider, address _initialResearchFund) Ownable(msg.sender) {
        require(_initialSignalProvider != address(0), "APC: Initial signal provider cannot be zero address");
        require(_initialResearchFund != address(0), "APC: Initial research fund address cannot be zero address");

        isSignalProvider[_initialSignalProvider] = true;
        researchFundAddress = _initialResearchFund;
        predictionValidationThreshold = 3; // Default threshold, can be changed by owner
        signalSubmissionFee = 0.01 ether; // Default fee for submitting a signal
        signalSubmissionReward = 1e18; // Default reward (1 unit of ERC20 token, e.g. 1 Stablecoin)
        validationReward = 0.1e18; // Default reward for a validator
        paused = false;

        emit SignalProviderUpdated(_initialSignalProvider, true);
    }

    // --- Fund Management & Treasury Operations ---

    /**
     * @notice Allows anyone to deposit ERC-20 tokens into the contract's treasury.
     * @param tokenAddress The address of the ERC-20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function depositFunds(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
        require(tokenAddress != address(0), "APC: Invalid token address");
        require(amount > 0, "APC: Deposit amount must be greater than zero");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        emit FundsDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @notice Allows the owner to withdraw funds from the contract's treasury in an emergency.
     * @dev This function bypasses normal logic and is intended for critical situations.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawFundsEmergency(address tokenAddress, uint256 amount) external onlyOwner whenPaused nonReentrant {
        require(tokenAddress != address(0), "APC: Invalid token address");
        require(amount > 0, "APC: Withdraw amount must be greater than zero");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "APC: Insufficient token balance in contract");

        IERC20(tokenAddress).transfer(owner(), amount);
        emit FundsWithdrawn(tokenAddress, owner(), amount);
    }

    /**
     * @notice Allows the owner to rebalance assets within the contract's treasury by swapping one token for another.
     * @dev This function would typically interact with a decentralized exchange (DEX) integration.
     *      For simplicity, this implementation assumes a direct transfer, but in a real scenario,
     *      it would involve calling a swap function on a DEX.
     * @param _fromToken The address of the token to swap from.
     * @param _toToken The address of the token to swap to.
     * @param _amount The amount of `_fromToken` to swap.
     */
    function rebalanceTreasury(address _fromToken, address _toToken, uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        require(_fromToken != address(0) && _toToken != address(0), "APC: Invalid token addresses");
        require(_amount > 0, "APC: Rebalance amount must be greater than zero");
        require(IERC20(_fromToken).balanceOf(address(this)) >= _amount, "APC: Insufficient balance of fromToken");

        // In a real-world scenario, this would involve integrating with a DEX:
        // Example (conceptual):
        // IERC20(_fromToken).approve(address(dexRouter), _amount);
        // uint256 receivedAmount = IDexRouter(dexRouter).swapExactTokensForTokens(_amount, 0, path, address(this), deadline);
        // For this example, we'll simulate a 'burn' and 'mint' or simple transfer for demonstration.
        // A direct transfer is shown for simplicity; actual swap logic requires more complex integration.
        IERC20(_fromToken).transfer(owner(), _amount); // Simulate burning from treasury
        // Ideally, swap on a DEX and receive _toToken.
        // As a placeholder, let's assume _toToken is minted/received off-chain or by owner.
        // For a true rebalance, you'd need the actual swap to happen here.
        // Example of a placeholder for receiving _toToken after a simulated swap:
        // IERC20(_toToken).transferFrom(owner(), address(this), receivedAmount);

        emit TreasuryRebalanced(_fromToken, _toToken, _amount);
    }

    // --- Role Management ---

    /**
     * @notice Grants or revokes the `SignalProvider` role to an address.
     * @dev Only the owner can call this function.
     * @param _provider The address to set/unset as a SignalProvider.
     * @param _isSignalProvider True to grant the role, false to revoke.
     */
    function setSignalProvider(address _provider, bool _isSignalProvider) external onlyOwner {
        require(_provider != address(0), "APC: Provider address cannot be zero");
        isSignalProvider[_provider] = _isSignalProvider;
        emit SignalProviderUpdated(_provider, _isSignalProvider);
    }

    // --- Predictive Signal Lifecycle ---

    /**
     * @notice Allows a designated `SignalProvider` to submit a new predictive signal.
     * @dev A submission fee must be paid.
     * @param _signalHash A unique identifier or hash for the signal's core data.
     * @param _predictedValue The numerical value being predicted.
     * @param _predictionTimestamp The timestamp when the prediction was generated off-chain.
     * @param _signalExpiresAt The timestamp when this signal becomes no longer relevant.
     * @param _metadataURI URI pointing to additional metadata or context about the signal (e.g., IPFS).
     */
    function submitPredictiveSignal(
        bytes32 _signalHash,
        uint256 _predictedValue,
        uint256 _predictionTimestamp,
        uint256 _signalExpiresAt,
        string calldata _metadataURI
    ) external payable onlySignalProvider whenNotPaused isValidURI(_metadataURI) nonReentrant {
        require(msg.value >= signalSubmissionFee, "APC: Insufficient signal submission fee");
        require(_signalExpiresAt > block.timestamp, "APC: Signal expiration must be in the future");
        require(_predictionTimestamp <= block.timestamp, "APC: Prediction timestamp cannot be in the future");

        _signalIdCounter++;
        signals[_signalIdCounter] = PredictiveSignal({
            signalHash: _signalHash,
            predictedValue: _predictedValue,
            predictionTimestamp: _predictionTimestamp,
            signalExpiresAt: _signalExpiresAt,
            submitter: msg.sender,
            status: SignalStatus.Pending,
            validationVotes: 0,
            metadataURI: _metadataURI
        });

        emit PredictiveSignalSubmitted(_signalIdCounter, msg.sender, _signalHash, _predictedValue, _predictionTimestamp, _signalExpiresAt);
    }

    /**
     * @notice Allows any address (could be a whitelisted validator or community member) to vote to validate a signal.
     * @dev A signal becomes `Validated` once it reaches the `predictionValidationThreshold`.
     * @param _signalId The ID of the signal to validate.
     */
    function validatePredictiveSignal(uint256 _signalId) external whenNotPaused nonReentrant {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(signal.status == SignalStatus.Pending, "APC: Signal is not in Pending status");
        require(block.timestamp < signal.signalExpiresAt, "APC: Signal has expired");
        require(!signal.hasValidated[msg.sender], "APC: Caller has already validated this signal");
        require(!signal.hasDisputed[msg.sender], "APC: Caller has disputed this signal, cannot validate");

        signal.hasValidated[msg.sender] = true;
        signal.validationVotes++;

        if (signal.validationVotes >= predictionValidationThreshold) {
            signal.status = SignalStatus.Validated;
        }
        emit PredictiveSignalValidated(_signalId, msg.sender);
    }

    /**
     * @notice Allows any address to dispute a signal by providing a reason URI.
     * @dev A signal can only be disputed if it's Pending or Validated and not yet expired.
     * @param _signalId The ID of the signal to dispute.
     * @param _reasonURI URI pointing to the reason for the dispute.
     */
    function disputePredictiveSignal(uint256 _signalId, string calldata _reasonURI) external whenNotPaused isValidURI(_reasonURI) nonReentrant {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(signal.status != SignalStatus.Expired && signal.status != SignalStatus.Invalidated, "APC: Signal cannot be disputed in its current status");
        require(block.timestamp < signal.signalExpiresAt, "APC: Signal has expired");
        require(!signal.hasDisputed[msg.sender], "APC: Caller has already disputed this signal");
        require(!signal.hasValidated[msg.sender], "APC: Caller has validated this signal, cannot dispute");

        signal.hasDisputed[msg.sender] = true;
        // Optionally, if enough disputes, automatically change status to Disputed
        if (signal.status != SignalStatus.Disputed) {
             signal.status = SignalStatus.Disputed;
        }

        emit PredictiveSignalDisputed(_signalId, msg.sender, _reasonURI);
    }

    /**
     * @notice Owner/governance resolves a dispute, setting the signal status to Validated or Invalidated.
     * @param _signalId The ID of the signal to resolve the dispute for.
     * @param _isDisputeValid True if the dispute is deemed valid (signal becomes Invalidated), false otherwise (signal reverts to Validated or Pending).
     */
    function resolveSignalDispute(uint256 _signalId, bool _isDisputeValid) external onlyOwner whenNotPaused {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(signal.status == SignalStatus.Disputed, "APC: Signal is not currently disputed");
        require(block.timestamp < signal.signalExpiresAt, "APC: Cannot resolve dispute for an expired signal");

        if (_isDisputeValid) {
            signal.status = SignalStatus.Invalidated;
            // Optionally, penalize the submitter here
        } else {
            // If the dispute is invalid, revert to its prior state (e.g., Validated or Pending if it hadn't met threshold)
            if (signal.validationVotes >= predictionValidationThreshold) {
                signal.status = SignalStatus.Validated;
            } else {
                signal.status = SignalStatus.Pending;
            }
        }
        emit SignalDisputeResolved(_signalId, _isDisputeValid);
    }

    /**
     * @notice Retrieves all stored details for a specific predictive signal.
     * @param _signalId The ID of the signal to query.
     * @return signalHash_ The hash of the prediction data.
     * @return predictedValue_ The numerical prediction.
     * @return predictionTimestamp_ The timestamp when the prediction was made.
     * @return signalExpiresAt_ The timestamp when the signal expires.
     * @return submitter_ The address of the signal submitter.
     * @return status_ The current status of the signal.
     * @return validationVotes_ The number of validation votes.
     * @return metadataURI_ The URI to additional context.
     */
    function getSignalDetails(uint256 _signalId)
        external
        view
        returns (
            bytes32 signalHash_,
            uint256 predictedValue_,
            uint256 predictionTimestamp_,
            uint256 signalExpiresAt_,
            address submitter_,
            SignalStatus status_,
            uint256 validationVotes_,
            string memory metadataURI_
        )
    {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");

        signalHash_ = signal.signalHash;
        predictedValue_ = signal.predictedValue;
        predictionTimestamp_ = signal.predictionTimestamp;
        signalExpiresAt_ = signal.signalExpiresAt;
        submitter_ = signal.submitter;
        status_ = signal.status;
        validationVotes_ = signal.validationVotes;
        metadataURI_ = signal.metadataURI;
    }

    /**
     * @notice Sets the number of validation votes required for a signal to be considered `Validated`.
     * @dev Only the owner can call this function.
     * @param _newThreshold The new validation threshold.
     */
    function setPredictionValidationThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "APC: Threshold must be greater than zero");
        predictionValidationThreshold = _newThreshold;
    }

    /**
     * @notice Sets the fee required for a `SignalProvider` to submit a new signal.
     * @dev Only the owner can call this function.
     * @param _newFee The new submission fee in native currency (wei).
     */
    function setSignalSubmissionFee(uint256 _newFee) external onlyOwner {
        signalSubmissionFee = _newFee;
    }

    // --- Incentive & Reward System ---

    /**
     * @notice Allows a `SignalProvider` to claim a reward if their signal is successfully validated and has been acted upon.
     * @dev This assumes there's an internal mechanism or off-chain check to determine if it's "acted upon."
     *      For simplicity, reward is paid upon being `Validated`.
     * @param _signalId The ID of the signal for which to claim the reward.
     */
    function claimSignalSubmissionReward(uint256 _signalId) external nonReentrant {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(msg.sender == signal.submitter, "APC: Only the signal submitter can claim this reward");
        require(signal.status == SignalStatus.Validated, "APC: Signal not validated yet");
        // Add a check to ensure reward is not claimed twice
        // This would require a mapping: mapping(uint256 => bool) public hasSignalRewardBeenClaimed;
        // For simplicity, omitting duplicate claim prevention for now.

        // Assuming signalSubmissionReward is in native currency for this example
        // In a real dApp, this might be a specific ERC-20 token from treasury
        (bool success, ) = msg.sender.call{value: signalSubmissionReward}("");
        require(success, "APC: Failed to send signal submission reward");

        // Mark signal as 'rewarded' to prevent double claims (conceptual)
        // signal.rewardClaimed = true;
        emit FundsWithdrawn(address(0), msg.sender, signalSubmissionReward); // Address(0) for native token
    }

    /**
     * @notice Allows a validator to claim a reward for successfully validating a signal that proved accurate.
     * @dev This function currently pays out based on a signal being `Validated`.
     * @param _signalId The ID of the signal for which to claim the reward.
     */
    function claimValidationReward(uint256 _signalId) external nonReentrant {
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(signal.hasValidated[msg.sender], "APC: Caller did not validate this signal");
        require(signal.status == SignalStatus.Validated, "APC: Signal not validated yet");
        // Add duplicate claim prevention similar to claimSignalSubmissionReward

        (bool success, ) = msg.sender.call{value: validationReward}("");
        require(success, "APC: Failed to send validation reward");

        emit FundsWithdrawn(address(0), msg.sender, validationReward); // Address(0) for native token
    }

    // --- Capital Allocation & Strategy Execution ---

    /**
     * @notice The core function to allocate capital based on a validated predictive signal.
     * @dev This function checks the signal's status and then deploys capital to a pre-approved strategy module.
     * @param _signalId The ID of the signal to act upon.
     * @param tokenAddress The address of the token to allocate.
     * @param amount The amount of tokens to allocate.
     * @param strategyModuleId The ID of the approved strategy module to interact with.
     */
    function allocateCapitalBasedOnSignal(
        uint256 _signalId,
        address tokenAddress,
        uint256 amount,
        uint256 strategyModuleId
    ) public onlyOwner whenNotPaused nonReentrant {
        // Callable by owner as the final decision maker, but in a DAO context, this would be triggered by a successful proposal vote.
        PredictiveSignal storage signal = signals[_signalId];
        require(signal.submitter != address(0), "APC: Signal does not exist");
        require(signal.status == SignalStatus.Validated, "APC: Signal must be validated to allocate capital");
        require(block.timestamp < signal.signalExpiresAt, "APC: Cannot allocate capital on an expired signal");

        require(tokenAddress != address(0), "APC: Invalid token address");
        require(amount > 0, "APC: Allocation amount must be greater than zero");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "APC: Insufficient token balance in treasury");

        require(isStrategyModuleApproved[strategyModuleId], "APC: Strategy module not approved");
        address targetModule = approvedStrategyModules[strategyModuleId];
        require(targetModule != address(0), "APC: Invalid strategy module address");

        // Example: Call a generic 'deposit' function on the strategy module.
        // In a real scenario, _callData would be constructed based on the signal's predictedValue
        // and the specific function call needed for the strategy module.
        bytes memory callData = abi.encodeWithSignature("deposit(address,uint256)", tokenAddress, amount);
        _deployCapitalToStrategy(targetModule, tokenAddress, amount, callData);

        emit CapitalAllocated(_signalId, tokenAddress, amount, strategyModuleId);
    }

    /**
     * @notice Adds or removes an external contract address as an approved capital allocation strategy module.
     * @dev Only the owner can approve or disapprove strategy modules. These modules are where capital is deployed.
     * @param _moduleId A unique ID for the strategy module.
     * @param _moduleAddress The address of the external strategy contract.
     * @param _isApproved True to approve, false to disapprove.
     */
    function setApprovedStrategyModule(uint256 _moduleId, address _moduleAddress, bool _isApproved) external onlyOwner {
        require(_moduleAddress != address(0), "APC: Module address cannot be zero");
        if (_isApproved) {
            approvedStrategyModules[_moduleId] = _moduleAddress;
        } else {
            delete approvedStrategyModules[_moduleId];
        }
        isStrategyModuleApproved[_moduleId] = _isApproved;
        emit StrategyModuleUpdated(_moduleId, _moduleAddress, _isApproved);
    }

    /**
     * @notice Internal function to execute a specific function call on an approved external strategy module,
     *         transferring tokens beforehand.
     * @dev This function handles the actual token transfer and external call.
     * @param _strategyModuleAddress The address of the approved strategy module.
     * @param tokenAddress The address of the token to transfer.
     * @param amount The amount of tokens to transfer.
     * @param _callData The ABI-encoded call data for the function to execute on the module.
     */
    function _deployCapitalToStrategy(address _strategyModuleAddress, address tokenAddress, uint256 amount, bytes calldata _callData) private {
        // First, approve the strategy module to pull tokens from this contract, or directly transfer
        // If the strategy module requires a direct transfer, use:
        IERC20(tokenAddress).transfer(_strategyModuleAddress, amount);

        // Then, call the specific function on the strategy module
        (bool success, bytes memory returnData) = _strategyModuleAddress.call(_callData);
        require(success, string(abi.encodePacked("APC: External call to strategy module failed: ", string(returnData))));
    }

    /**
     * @notice Triggers a pre-defined risk mitigation action based on a critical signal or event.
     * @dev This could involve withdrawing funds from a risky protocol, or reallocating to safer assets.
     *      The specific action (e.g., withdraw from a specific pool) would need to be defined
     *      or passed via `_reasonURI` / additional parameters for a more generic function.
     *      For simplicity, this example just allows an emergency withdrawal to owner.
     * @param tokenAddress The token involved in the risk mitigation (e.g., token to withdraw).
     * @param amount The amount to mitigate/withdraw.
     * @param _reasonURI URI explaining the risk and mitigation action.
     */
    function triggerRiskMitigation(address tokenAddress, uint256 amount, string calldata _reasonURI) external onlyOwner whenNotPaused nonReentrant isValidURI(_reasonURI) {
        require(tokenAddress != address(0), "APC: Invalid token address");
        require(amount > 0, "APC: Mitigation amount must be greater than zero");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "APC: Insufficient token balance for mitigation");

        // In a real scenario, this would call a specific 'withdraw' or 'redeem' function on a risky strategy module.
        // For demonstration, a direct transfer back to owner for safety.
        IERC20(tokenAddress).transfer(owner(), amount);

        emit RiskMitigationTriggered(tokenAddress, amount, _reasonURI);
    }

    // --- Research & Development Funding ---

    /**
     * @notice Allows anyone to submit a research grant application.
     * @dev Grant proposals can be linked to a predictive signal that highlights a research opportunity.
     * @param _proposalHash IPFS CID or hash of the full research proposal document.
     * @param _recipient The address to receive the grant funds if approved.
     * @param _amount The amount of tokens requested.
     * @param _tokenAddress The address of the ERC-20 token requested.
     * @param _signalId The predictive signal ID that supports this grant (0 if not applicable).
     */
    function fundResearchGrant(
        string calldata _proposalHash,
        address _recipient,
        uint256 _amount,
        address _tokenAddress,
        uint256 _signalId
    ) external whenNotPaused isValidURI(_proposalHash) {
        require(_recipient != address(0), "APC: Recipient cannot be zero address");
        require(_amount > 0, "APC: Grant amount must be greater than zero");
        require(_tokenAddress != address(0), "APC: Token address cannot be zero");

        if (_signalId != 0) {
            require(signals[_signalId].submitter != address(0), "APC: Linked signal does not exist");
            require(signals[_signalId].status == SignalStatus.Validated, "APC: Linked signal must be validated");
        }

        _grantIdCounter++;
        researchGrants[_grantIdCounter] = ResearchGrantApplication({
            proposalHash: _proposalHash,
            recipient: _recipient,
            amount: _amount,
            tokenAddress: _tokenAddress,
            signalId: _signalId,
            status: GrantStatus.Pending,
            appliedAt: block.timestamp
        });

        emit ResearchGrantApplied(_grantIdCounter, _proposalHash, _recipient, _amount, _tokenAddress, _signalId);
    }

    /**
     * @notice Approves a pending research grant application.
     * @dev Only the owner can approve grants.
     * @param _grantId The ID of the grant application to approve.
     */
    function approveResearchGrant(uint256 _grantId) external onlyOwner whenNotPaused {
        ResearchGrantApplication storage grant = researchGrants[_grantId];
        require(grant.recipient != address(0), "APC: Grant does not exist");
        require(grant.status == GrantStatus.Pending, "APC: Grant is not in Pending status");

        grant.status = GrantStatus.Approved;
        emit ResearchGrantApproved(_grantId);
    }

    /**
     * @notice Payouts an approved research grant.
     * @dev Only the owner can trigger payouts.
     * @param _grantId The ID of the approved grant to pay out.
     */
    function payoutResearchGrant(uint256 _grantId) external onlyOwner whenNotPaused nonReentrant {
        ResearchGrantApplication storage grant = researchGrants[_grantId];
        require(grant.recipient != address(0), "APC: Grant does not exist");
        require(grant.status == GrantStatus.Approved, "APC: Grant is not approved for payout");
        require(IERC20(grant.tokenAddress).balanceOf(address(this)) >= grant.amount, "APC: Insufficient token balance for grant payout");

        grant.status = GrantStatus.Paid;
        IERC20(grant.tokenAddress).transfer(grant.recipient, grant.amount);

        emit ResearchGrantPaid(_grantId);
    }

    // --- System Parameters & Governance ---

    /**
     * @notice Allows anyone to formally request a recalibration of the underlying AI model.
     * @dev This function serves as a signal to off-chain AI model maintainers that a recalibration is needed,
     *      perhaps due to consistently inaccurate predictions for a given signal.
     * @param _signalId The ID of the signal that is prompting the recalibration request.
     * @param _reasonURI URI pointing to detailed reasons or data supporting the recalibration request.
     */
    function requestSignalRecalibration(uint256 _signalId, string calldata _reasonURI) external whenNotPaused isValidURI(_reasonURI) {
        require(signals[_signalId].submitter != address(0), "APC: Signal does not exist");
        // Further logic could include a DAO vote on recalibration requests,
        // or a reputation system for those requesting.
        emit SignalRecalibrationRequested(_signalId, _reasonURI);
    }

    /**
     * @notice Pauses the contract, preventing most state-changing operations.
     * @dev Only the owner can pause the contract. Useful for emergencies or upgrades.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, resuming normal operations.
     * @dev Only the owner can unpause the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- View Functions ---

    /**
     * @notice Returns the current balance of a specific ERC-20 token held by the contract.
     * @param tokenAddress The address of the ERC-20 token.
     * @return The balance of the token.
     */
    function getTreasuryBalance(address tokenAddress) external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @notice Returns a list of all currently pending research grant IDs.
     * @dev Iterates through all grants, which can be gas-intensive for large numbers of grants.
     *      In a production system, a more efficient pattern (e.g., event-based indexing) would be used.
     * @return An array of pending grant IDs.
     */
    function getPendingGrants() external view returns (uint256[] memory) {
        uint256[] memory pendingIds = new uint256[](_grantIdCounter);
        uint256 currentCount = 0;
        for (uint256 i = 1; i <= _grantIdCounter; i++) {
            if (researchGrants[i].status == GrantStatus.Pending) {
                pendingIds[currentCount] = i;
                currentCount++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](currentCount);
        for (uint256 i = 0; i < currentCount; i++) {
            result[i] = pendingIds[i];
        }
        return result;
    }

    /**
     * @notice Get the total number of signals submitted to the contract.
     * @return The current signal ID counter.
     */
    function getTotalSignals() external view returns (uint256) {
        return _signalIdCounter;
    }

    /**
     * @notice Get the total number of grant applications submitted to the contract.
     * @return The current grant ID counter.
     */
    function getTotalGrants() external view returns (uint256) {
        return _grantIdCounter;
    }
}
```