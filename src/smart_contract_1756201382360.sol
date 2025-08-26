This smart contract, named `AdaptiveIntentFulfillmentNetwork (AIFN)`, introduces a sophisticated, intent-based protocol designed to be dynamic, self-improving, and resilient. It moves beyond traditional atomic transactions by allowing users to express desired outcomes ("intents") and leverages a network of "fulfillers" to achieve these, guided by an adaptive strategy engine and a reputation system.

---

## Adaptive Intent Fulfillment Network (AIFN)

### Outline

1.  **Contract Overview:** High-level description of the Adaptive Intent Fulfillment Network (AIFN) and its core objectives.
2.  **Key Concepts:** Detailed explanation of the innovative features:
    *   **Intent-Based Architecture:** Users declare desired outcomes, not precise transaction paths.
    *   **Adaptive Strategy Engine:** Protocol parameters evolve based on collective feedback and governance.
    *   **Fulfiller Reputation System:** Incentivizes reliability and penalizes poor performance.
    *   **Dynamic Fee Mechanism:** Fees adjust based on network utilization and market conditions.
    *   **Lightweight On-chain Governance:** Stakers propose and vote on key protocol parameters.
3.  **Data Structures:** Definitions of `Intent` and `Proposal` structs.
4.  **Error Definitions:** Custom error types for robust error handling.
5.  **Events:** List of all emitted events for off-chain monitoring.
6.  **Functions Summary:** Categorized list of all public and external functions with brief descriptions.

---

### Key Concepts

*   **Intent-Based Architecture:** Instead of users specifying a precise DEX path or lending pool, they simply state what they want (e.g., "I want to acquire X tokens for Y ETH, with at least Z output"). The protocol then facilitates this, allowing a network of "fulfillers" to compete to execute these intents optimally.
*   **Adaptive Strategy Engine:** This is a simplified "learning" mechanism. Key protocol parameters (like `defaultSlippageBps`, `minReputationForComplexIntent`, or implicit weights for preferred liquidity sources) are stored on-chain. These parameters can be adjusted via governance proposals, which are informed by aggregated user/fulfiller feedback on past intent fulfillments. The `queryOptimalStrategy` function then provides recommendations based on these current, adaptively tuned parameters.
*   **Fulfiller Reputation System:** Fulfillers stake collateral to participate. Their reputation score increases with successful, user-rated fulfillments and decreases with failures or slashing incidents. This encourages high-quality service and allows for differentiated access to more complex or high-value intents.
*   **Dynamic Fee Mechanism:** The protocol automatically adjusts its transaction fees based on its `protocolUtilizationMetric`. Higher utilization (more intents) can lead to slightly higher fees, ensuring sustainability during peak demand, while lower fees during quiet periods can incentivize usage.
*   **Lightweight On-chain Governance:** Staked fulfillers possess voting power to propose and vote on changes to the protocol's core parameters, including the adaptive strategy parameters and base fee rates. This ensures the protocol remains decentralized and responsive to its community.

---

### Data Structures

*   **`Intent`**: Represents a user's desired outcome. Includes details like input/output assets and amounts, expiration, status, assigned fulfiller, and a reward for the fulfiller.
*   **`Proposal`**: Represents a governance proposal. Includes description, `callData` for the target function to execute if passed, vote counts, and expiration time.

---

### Error Definitions

Custom errors provide more specific and gas-efficient error handling compared to `require()` with string messages.

---

### Events

*   `IntentPosted`, `IntentCancelled`, `IntentExecuted`, `IntentResolved`, `IntentReverted`
*   `FulfillerRegistered`, `FulfillerDeregistered`, `FulfillerSlashed`, `FulfillerReputationUpdated`
*   `StrategyFeedbackSubmitted`, `StrategyParameterChanged`
*   `FeeAdjusted`
*   `ProposalCreated`, `VoteCast`, `ProposalExecuted`
*   `AdminRoleGranted`, `AdminRoleRevoked`

---

### Functions Summary

**1. Core Intent Management (5 Functions)**
*   `postIntent()`: Allows a user to declare a new intent, specifying assets, amounts, expiration, and a fulfiller reward.
*   `cancelIntent()`: Enables a user to cancel their pending intent and reclaim their funds.
*   `executeIntentOffer()`: A registered fulfiller takes on a pending intent, committing to its execution.
*   `resolveIntent()`: Called by the fulfiller upon successful intent execution, updating status and reputation.
*   `revertIntentExecution()`: Called by the fulfiller if an intent execution fails, returning funds to the protocol for the user.

**2. Fulfiller Management (3 Functions)**
*   `registerFulfiller()`: Allows an address to become a fulfiller by staking ETH.
*   `deregisterFulfiller()`: Permits a fulfiller to unstake their ETH and exit the network.
*   `slashFulfillerStake()`: Penalizes a fulfiller's stake and reputation for malicious or poor performance (callable by admin/governance).

**3. Adaptive Strategy & Feedback (2 Functions)**
*   `submitStrategyFeedback()`: Allows users or fulfillers to provide a rating for an intent's execution, influencing fulfiller reputation.
*   `proposeStrategyParameterChange()`: Initiates a governance proposal to modify a specific adaptive strategy parameter.

**4. Dynamic Fee Mechanism (3 Functions)**
*   `setBaseFeeRate()`: Sets the base fee rate for the protocol (governance-controlled).
*   `_updateProtocolUtilization()`: Internal function to track network activity for dynamic fee calculation.
*   `getApplicableFee()`: Calculates the total fee for an intent, combining base and dynamic adjustments.

**5. Governance & Protocol Management (5 Functions)**
*   `_createProposal()`: Internal helper for creating new governance proposals.
*   `voteOnProposal()`: Allows staked fulfillers to cast their votes on active proposals.
*   `executeProposal()`: Executes a proposal that has met its voting threshold after the voting period ends.
*   `updateStrategyParameter()`: Admin function, primarily called by `executeProposal`, to change strategy parameters.
*   `grantAdminRole()`: Grants an address administrative privileges (owner only).
*   `revokeAdminRole()`: Revokes administrative privileges (owner only).

**6. View Functions (8 Functions)**
*   `getIntentDetails()`: Retrieves all details for a given intent ID.
*   `getUserIntents()`: Returns a list of intent IDs associated with a specific user.
*   `getFulfillerDetails()`: Fetches the stake, reputation, and active status of a fulfiller.
*   `queryOptimalStrategy()`: Provides recommendations for intent fulfillment based on current adaptive parameters.
*   `getProposalDetails()`: Retrieves details of a specific governance proposal.
*   `getVotingPower()`: Calculates the voting power of an address (based on stake).
*   `getProtocolUtilizationMetric()`: Returns the current network activity metric.
*   `getFulfillerStakeRequirement()`: Returns the minimum ETH required to register as a fulfiller.

**7. Admin/Owner Utilities (1 Function)**
*   `recoverERC20()`: Allows the contract owner to recover ERC20 tokens mistakenly sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Adaptive Intent Fulfillment Network (AIFN)
 * @author YourNameHere (or leave as is)
 * @dev This contract implements a novel decentralized protocol where users can post "intents"
 *      (e.g., "I want to swap X for Y at Z price within T time"). The protocol then facilitates
 *      these intents by allowing "fulfillers" to execute them.
 *      Key advanced concepts include:
 *      1.  **Intent-Based Architecture:** Users declare desired outcomes, not precise transaction paths.
 *      2.  **Adaptive Strategy Engine:** A simplified "learning" mechanism where protocol parameters
 *          (e.g., preferred liquidity sources, acceptable slippage) are adjusted based on
 *          collective feedback and governance proposals, influencing recommended fulfillment strategies.
 *      3.  **Fulfiller Reputation System:** Incentivizes reliable fulfillers and penalizes poor performance.
 *      4.  **Dynamic Fee Mechanism:** Fees adjust based on network utilization and market conditions
 *          to optimize protocol engagement and sustainability.
 *      5.  **Lightweight On-chain Governance:** Allows stakers to propose and vote on key protocol
 *          parameters, including the adaptive strategy adjustments.
 *      The goal is to create a more resilient, efficient, and user-centric DeFi primitive that
 *      evolves with market conditions and community input without duplicating existing open-source
 *      DEXs, lending protocols, or bridges.
 */
contract AdaptiveIntentFulfillmentNetwork is Ownable, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                ERROR DEFINITIONS
    //////////////////////////////////////////////////////////////*/

    error InvalidIntentId();
    error IntentNotActive();
    error IntentNotPending();
    error IntentExpired();
    error IntentAlreadyFulfilled();
    error UnauthorizedCaller();
    error FulfillerNotRegistered();
    error FulfillerAlreadyRegistered();
    error InsufficientFulfillerStake();
    error InvalidAmount();
    error TransferFailed();
    error InvalidProposalId();
    error ProposalAlreadyExecuted();
    error ProposalExpired();
    error AlreadyVoted();
    error NotEnoughVotingPower();
    error StrategyParameterNotFound(); // Not explicitly used but good for future extension
    error InvalidStrategyFeedbackScore();
    error FulfillerHasActiveIntents(); // For deregistration check

    /*///////////////////////////////////////////////////////////////
                                INTERFACES
    //////////////////////////////////////////////////////////////*/

    // Minimal ERC20 interface to interact with tokens
    interface IERC20 {
        function transfer(address to, uint256 amount) external returns (bool);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }

    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    enum IntentStatus { Pending, Fulfilled, Cancelled, Expired, FailedExecution }

    struct Intent {
        uint256 id;
        address user;
        address assetIn;
        uint256 amountIn; // Amount specifically for the swap, excluding fee and reward
        address assetOut;
        uint256 minAmountOut; // Minimum amount of assetOut the user expects
        uint256 protocolFeeAmount; // Fee paid to the protocol, stored here
        uint256 creationTime;
        uint256 expirationTime;
        IntentStatus status;
        address fulfiller; // Address of the fulfiller if intent is being executed/fulfilled
        uint256 fulfillerReward; // Reward for the fulfiller, paid in assetIn
        bool feedbackProvided; // To ensure feedback is submitted only once per user
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if proposal passes
        address targetContract; // Contract address to call
        uint256 voteThresholdBps; // Required percentage of total voting power in basis points (e.g., 5100 for 51%)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 expirationTime;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks who has voted
    }

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public intentCounter;
    mapping(uint256 => Intent) public intents;
    mapping(address => uint256[]) public userIntentIds; // To query intents by user

    uint256 public fulfillerStakeAmount = 1 ether; // Minimum stake required for a fulfiller (in ETH)
    mapping(address => uint256) public fulfillerStakes; // Amount staked by a fulfiller (in ETH)
    mapping(address => int256) public fulfillerReputations; // Reputation score (can be negative)
    mapping(address => bool) public isFulfillerActive; // Indicates if an address is a registered fulfiller
    address[] private activeFulfillers; // A dynamic array to iterate over active fulfillers

    // Adaptive Strategy Parameters (e.g., "maxSlippageBps", "preferredDexWeight_Uniswap")
    mapping(string => uint256) public strategyParameters;

    uint256 public baseFeeRateBps = 100; // Base fee rate in basis points (1% = 100 bps)
    uint256 public dynamicFeeFactorBps = 10; // How much dynamic fee adjusts per utilization unit
    uint256 public protocolUtilizationMetric; // Simple metric for protocol activity, resets periodically
    uint256 public lastFeeAdjustmentTime;
    uint256 public constant UTILIZATION_PERIOD = 1 days; // Period to reset utilization metric

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant MIN_VOTING_POWER = 1 ether; // Minimum fulfiller stake to vote (in ETH)

    // Admin role for initial setup/emergency, can be transferred to governance later
    mapping(address => bool) public isAdmin;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event IntentPosted(uint256 indexed intentId, address indexed user, address assetIn, uint256 amountIn, address assetOut, uint256 minAmountOut, uint256 expirationTime);
    event IntentCancelled(uint256 indexed intentId, address indexed user);
    event IntentExecuted(uint256 indexed intentId, address indexed fulfiller);
    event IntentResolved(uint256 indexed intentId, address indexed fulfiller, uint256 fulfillerReward, uint256 protocolFee);
    event IntentReverted(uint256 indexed intentId, address indexed fulfiller);

    event FulfillerRegistered(address indexed fulfiller, uint256 stake);
    event FulfillerDeregistered(address indexed fulfiller);
    event FulfillerSlashed(address indexed fulfiller, uint256 amount, string reason);
    event FulfillerReputationUpdated(address indexed fulfiller, int256 newReputation);

    event StrategyFeedbackSubmitted(uint256 indexed intentId, address indexed submitter, uint8 score);
    event StrategyParameterChanged(string indexed paramName, uint256 newValue, address indexed changer);

    event FeeAdjusted(uint256 newBaseFeeRateBps, uint256 currentDynamicFeeBps);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 expirationTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyFulfiller() {
        if (!isFulfillerActive[msg.sender]) revert FulfillerNotRegistered();
        _;
    }

    modifier onlyAdmin() {
        if (!isAdmin[msg.sender] && msg.sender != owner()) revert UnauthorizedCaller();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
        // Initial setup for owner as admin
        isAdmin[msg.sender] = true;
        emit AdminRoleGranted(msg.sender);

        // Set initial strategy parameters
        strategyParameters["defaultSlippageBps"] = 50; // 0.5%
        strategyParameters["minReputationForComplexIntent"] = 50;
        strategyParameters["maxExecutionTimeBuffer"] = 300; // 5 minutes (how long a fulfiller has to start execution)
        // More parameters could be added, e.g., weights for different DEXs or specific asset types.

        lastFeeAdjustmentTime = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                        CORE INTENT MANAGEMENT FUNCTIONS (5)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows a user to post a new intent.
     * @dev The user approves 'amountIn' + 'fulfillerReward' + 'protocolFeeAmount' to this contract beforehand.
     * @param _assetIn The ERC20 token to be given by the user.
     * @param _amountIn The amount of _assetIn the user is willing to give for the swap itself.
     * @param _assetOut The ERC20 token the user wants to receive.
     * @param _minAmountOut The minimum amount of _assetOut the user expects.
     * @param _expirationTime The timestamp after which the intent becomes invalid.
     * @param _fulfillerReward The reward amount for the fulfiller, paid in assetIn.
     */
    function postIntent(
        address _assetIn,
        uint256 _amountIn,
        address _assetOut,
        uint256 _minAmountOut,
        uint256 _expirationTime,
        uint256 _fulfillerReward
    ) external nonReentrant {
        if (_amountIn == 0 || _minAmountOut == 0 || _assetIn == address(0) || _assetOut == address(0) || _assetIn == _assetOut) {
            revert InvalidAmount();
        }
        if (_expirationTime <= block.timestamp) {
            revert IntentExpired();
        }
        if (_fulfillerReward >= _amountIn) {
            revert InvalidAmount(); // Fulfiller reward cannot be more than the input amount for swap
        }

        uint256 totalIntentValue = _amountIn + _fulfillerReward;
        uint256 currentProtocolFee = getApplicableFee(totalIntentValue);
        uint256 totalAmountToTransfer = totalIntentValue + currentProtocolFee;

        // Transfer _assetIn + fulfillerReward + protocol fee from user to contract
        if (!IERC20(_assetIn).transferFrom(msg.sender, address(this), totalAmountToTransfer)) {
            revert TransferFailed();
        }

        intentCounter++;
        uint256 newIntentId = intentCounter;

        intents[newIntentId] = Intent({
            id: newIntentId,
            user: msg.sender,
            assetIn: _assetIn,
            amountIn: _amountIn,
            assetOut: _assetOut,
            minAmountOut: _minAmountOut,
            protocolFeeAmount: currentProtocolFee,
            creationTime: block.timestamp,
            expirationTime: _expirationTime,
            status: IntentStatus.Pending,
            fulfiller: address(0),
            fulfillerReward: _fulfillerReward,
            feedbackProvided: false
        });

        userIntentIds[msg.sender].push(newIntentId);
        _updateProtocolUtilization(); // Update utilization metric

        emit IntentPosted(newIntentId, msg.sender, _assetIn, _amountIn, _assetOut, _minAmountOut, _expirationTime);
    }

    /**
     * @notice Allows the original user to cancel their pending intent.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) external nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.user != msg.sender) revert UnauthorizedCaller();
        if (intent.status != IntentStatus.Pending) revert IntentNotPending();
        if (block.timestamp >= intent.expirationTime) revert IntentExpired();

        intent.status = IntentStatus.Cancelled;

        // Refund assetIn, fulfillerReward, and protocolFeeAmount back to the user
        uint256 totalRefundAmount = intent.amountIn + intent.fulfillerReward + intent.protocolFeeAmount;
        if (!IERC20(intent.assetIn).transfer(intent.user, totalRefundAmount)) {
            revert TransferFailed(); // Critical failure, funds stuck or require manual recovery
        }

        emit IntentCancelled(_intentId, msg.sender);
    }

    /**
     * @notice A registered fulfiller attempts to execute a pending intent.
     * @dev This function marks the intent as "being executed" and transfers the input amount
     *      to the fulfiller. The fulfiller is responsible for performing the actual swap
     *      off-chain and then calling `resolveIntent` or `revertIntentExecution`.
     * @param _intentId The ID of the intent to execute.
     */
    function executeIntentOffer(uint256 _intentId) external onlyFulfiller nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.status != IntentStatus.Pending) revert IntentNotPending();
        if (block.timestamp >= intent.expirationTime) revert IntentExpired();

        // Assign fulfiller and change status to indicate it's being processed
        intent.fulfiller = msg.sender;
        intent.status = IntentStatus.FailedExecution; // Temporarily mark as failed until resolved, safer for reentrancy

        // Transfer the actual amount for swap + fulfiller reward to the fulfiller
        uint256 amountForFulfiller = intent.amountIn + intent.fulfillerReward;
        if (!IERC20(intent.assetIn).transfer(msg.sender, amountForFulfiller)) {
            // Revert status if transfer fails
            intent.fulfiller = address(0);
            intent.status = IntentStatus.Pending;
            revert TransferFailed();
        }

        emit IntentExecuted(_intentId, msg.sender);
    }

    /**
     * @notice Called by the fulfiller after successfully executing an intent.
     * @dev The fulfiller must have already transferred 'assetOut' to the user.
     *      The contract keeps the 'protocolFeeAmount'.
     * @param _intentId The ID of the fulfilled intent.
     * @param _actualAmountOut The actual amount of `assetOut` received by the user.
     */
    function resolveIntent(uint256 _intentId, uint256 _actualAmountOut) external onlyFulfiller nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.fulfiller != msg.sender) revert UnauthorizedCaller(); // Only assigned fulfiller can resolve
        if (intent.status != IntentStatus.FailedExecution) revert IntentNotActive(); // Must be in execution phase
        if (_actualAmountOut < intent.minAmountOut) revert InvalidAmount(); // Failed to meet min output

        intent.status = IntentStatus.Fulfilled;
        fulfillerReputations[msg.sender] += 10; // Reward good reputation
        emit FulfillerReputationUpdated(msg.sender, fulfillerReputations[msg.sender]);

        // Protocol fee (protocolFeeAmount) remains in the contract as revenue.
        // No tokens are transferred by the protocol here, as the fulfiller handled the actual swap and delivery.

        emit IntentResolved(_intentId, msg.sender, intent.fulfillerReward, intent.protocolFeeAmount);
    }

    /**
     * @notice Called by the fulfiller if an intent execution fails (e.g., slippage, network issues).
     * @dev Fulfiller must return the `amountIn` and `fulfillerReward` back to the contract.
     * @param _intentId The ID of the intent that failed execution.
     */
    function revertIntentExecution(uint256 _intentId) external onlyFulfiller nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.fulfiller != msg.sender) revert UnauthorizedCaller();
        if (intent.status != IntentStatus.FailedExecution) revert IntentNotActive();

        // The fulfiller must transfer back the assetIn + their potential reward.
        uint256 amountToReturn = intent.amountIn + intent.fulfillerReward;
        if (!IERC20(intent.assetIn).transferFrom(msg.sender, address(this), amountToReturn)) {
            revert TransferFailed();
        }

        intent.status = IntentStatus.Pending; // Return to pending for another fulfiller
        intent.fulfiller = address(0); // Clear fulfiller
        fulfillerReputations[msg.sender] -= 5; // Slight reputation penalty for failure
        emit FulfillerReputationUpdated(msg.sender, fulfillerReputations[msg.sender]);

        emit IntentReverted(_intentId, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            FULFILLER MANAGEMENT FUNCTIONS (3)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an address to register as a fulfiller by staking collateral (ETH).
     * @dev Requires `fulfillerStakeAmount` to be sent with the transaction.
     */
    function registerFulfiller() external payable nonReentrant {
        if (isFulfillerActive[msg.sender]) revert FulfillerAlreadyRegistered();
        if (msg.value < fulfillerStakeAmount) revert InsufficientFulfillerStake();

        fulfillerStakes[msg.sender] = msg.value; // Store the stake
        isFulfillerActive[msg.sender] = true;
        fulfillerReputations[msg.sender] = 0; // Initialize reputation
        activeFulfillers.push(msg.sender); // Add to dynamic list

        emit FulfillerRegistered(msg.sender, fulfillerStakes[msg.sender]);
    }

    /**
     * @notice Allows a registered fulfiller to deregister and unstake their collateral.
     * @dev Fulfiller must not have any active intents (`Pending` or `FailedExecution`).
     */
    function deregisterFulfiller() external onlyFulfiller nonReentrant {
        // Check if fulfiller has any active intents
        for (uint256 i = 0; i < userIntentIds[msg.sender].length; i++) {
            uint256 intentId = userIntentIds[msg.sender][i];
            if (intents[intentId].status == IntentStatus.Pending || intents[intentId].status == IntentStatus.FailedExecution) {
                if (intents[intentId].fulfiller == msg.sender || intents[intentId].user == msg.sender) { // Check both if user and fulfiller for current intents
                    revert FulfillerHasActiveIntents();
                }
            }
        }

        uint256 stake = fulfillerStakes[msg.sender];
        if (stake == 0) revert FulfillerNotRegistered(); // Should not happen with onlyFulfiller

        isFulfillerActive[msg.sender] = false;
        fulfillerStakes[msg.sender] = 0;

        // Remove from activeFulfillers array
        for (uint256 i = 0; i < activeFulfillers.length; i++) {
            if (activeFulfillers[i] == msg.sender) {
                activeFulfillers[i] = activeFulfillers[activeFulfillers.length - 1];
                activeFulfillers.pop();
                break;
            }
        }

        // Refund stake to fulfiller (ETH)
        (bool success,) = msg.sender.call{value: stake}("");
        if (!success) {
            // If refund fails, need to re-activate fulfiller or implement emergency recovery.
            isFulfillerActive[msg.sender] = true;
            fulfillerStakes[msg.sender] = stake;
            activeFulfillers.push(msg.sender); // Add back to active list
            revert TransferFailed();
        }

        emit FulfillerDeregistered(msg.sender);
    }

    /**
     * @notice Slashes a fulfiller's stake due to malicious behavior or severe performance issues.
     * @dev Callable by owner or via governance proposal.
     * @param _fulfiller The address of the fulfiller to slash.
     * @param _amount The amount of stake to slash (in ETH).
     * @param _reason A string describing the reason for slashing.
     */
    function slashFulfillerStake(address _fulfiller, uint256 _amount, string calldata _reason) external onlyAdmin nonReentrant {
        if (!isFulfillerActive[_fulfiller]) revert FulfillerNotRegistered();
        if (_amount == 0 || _amount > fulfillerStakes[_fulfiller]) revert InvalidAmount();

        fulfillerStakes[_fulfiller] -= _amount;
        fulfillerReputations[_fulfiller] -= 50; // Significant reputation penalty

        // If stake drops below requirement, deregister them automatically
        if (fulfillerStakes[_fulfiller] < fulfillerStakeAmount) {
             isFulfillerActive[_fulfiller] = false;
             // Remove from activeFulfillers array
            for (uint256 i = 0; i < activeFulfillers.length; i++) {
                if (activeFulfillers[i] == _fulfiller) {
                    activeFulfillers[i] = activeFulfillers[activeFulfillers.length - 1];
                    activeFulfillers.pop();
                    break;
                }
            }
        }

        // The slashed amount is kept by the protocol or sent to a treasury
        emit FulfillerSlashed(_fulfiller, _amount, _reason);
        emit FulfillerReputationUpdated(_fulfiller, fulfillerReputations[_fulfiller]);
    }

    /*///////////////////////////////////////////////////////////////
                        ADAPTIVE STRATEGY & FEEDBACK FUNCTIONS (2)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to submit feedback on an intent's execution.
     * @dev This feedback directly influences fulfiller reputation.
     * @param _intentId The ID of the intent being rated.
     * @param _score A score from 1-10, where 10 is excellent and 1 is very poor.
     */
    function submitStrategyFeedback(uint256 _intentId, uint8 _score) external {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (_score == 0 || _score > 10) revert InvalidStrategyFeedbackScore();
        if (intent.feedbackProvided) revert UnauthorizedCaller(); // Feedback only once per intent

        // Only the user who posted can submit feedback for now
        if (msg.sender != intent.user) revert UnauthorizedCaller();
        if (intent.status != IntentStatus.Fulfilled) revert IntentNotActive(); // Only rate fulfilled intents

        // User rating directly affects fulfiller reputation based on score
        int256 reputationChange = int256(_score) - 5; // Score 5=0 change, 10=+5, 1=-4
        fulfillerReputations[intent.fulfiller] += reputationChange;
        emit FulfillerReputationUpdated(intent.fulfiller, fulfillerReputations[intent.fulfiller]);
        
        intent.feedbackProvided = true;

        emit StrategyFeedbackSubmitted(_intentId, msg.sender, _score);
    }

    /**
     * @notice Allows an address to propose a change to a strategy parameter.
     * @dev This will create a governance proposal that needs to be voted on.
     * @param _paramName The name of the strategy parameter (e.g., "defaultSlippageBps").
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed change.
     * @param _voteThresholdBps The required percentage of total voting power for the proposal to pass (e.g., 5100 for 51%).
     * @param _votingPeriod The duration in seconds for voting.
     */
    function proposeStrategyParameterChange(
        string calldata _paramName,
        uint256 _newValue,
        string calldata _description,
        uint256 _voteThresholdBps,
        uint256 _votingPeriod
    ) external nonReentrant {
        // Encode the function call to `updateStrategyParameter`
        bytes memory callData = abi.encodeWithSelector(
            this.updateStrategyParameter.selector,
            _paramName,
            _newValue
        );

        _createProposal(msg.sender, _description, callData, address(this), _voteThresholdBps, _votingPeriod);
    }

    /*///////////////////////////////////////////////////////////////
                            DYNAMIC FEE MECHANISM FUNCTIONS (3)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the base fee rate for the protocol (in basis points).
     * @dev Only callable by admin/governance.
     * @param _newRateBps The new base fee rate in basis points (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setBaseFeeRate(uint256 _newRateBps) external onlyAdmin {
        if (_newRateBps > 10000) revert InvalidAmount();
        baseFeeRateBps = _newRateBps;
        emit FeeAdjusted(baseFeeRateBps, _calculateDynamicFeeBps());
    }

    /**
     * @notice Internal function to update the protocol utilization metric.
     * @dev Called after an intent is posted to track activity. Resets periodically.
     */
    function _updateProtocolUtilization() internal {
        if (block.timestamp - lastFeeAdjustmentTime >= UTILIZATION_PERIOD) {
            protocolUtilizationMetric = 1; // Reset and count new activity
            lastFeeAdjustmentTime = block.timestamp;
        } else {
            protocolUtilizationMetric++;
        }
    }

    /**
     * @notice Calculates the current dynamic fee in basis points based on utilization.
     * @dev This is a simplified example; a real system might use moving averages, etc.
     * @return The dynamic fee in basis points.
     */
    function _calculateDynamicFeeBps() internal view returns (uint256) {
        // Simple linear scaling: higher utilization, higher dynamic fee
        uint256 dynamicFee = protocolUtilizationMetric * dynamicFeeFactorBps;
        return dynamicFee > 1000 ? 1000 : dynamicFee; // Cap dynamic fee at 10%
    }

    /**
     * @notice Calculates the total applicable fee for an intent.
     * @param _amount The base amount upon which the fee is calculated.
     * @return The total fee amount to be paid.
     */
    function getApplicableFee(uint256 _amount) public view returns (uint256) {
        uint256 dynamicFeeBps = _calculateDynamicFeeBps();
        uint256 totalFeeBps = baseFeeRateBps + dynamicFeeBps;
        if (totalFeeBps > 10000) totalFeeBps = 10000; // Cap at 100%

        return (_amount * totalFeeBps) / 10000; // 10000 basis points = 100%
    }

    /*///////////////////////////////////////////////////////////////
                            GOVERNANCE FUNCTIONS (5)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal helper to create a new governance proposal.
     */
    function _createProposal(
        address _proposer,
        string memory _description,
        bytes memory _callData,
        address _targetContract,
        uint256 _voteThresholdBps,
        uint256 _votingPeriod
    ) internal returns (uint256) {
        if (_voteThresholdBps == 0 || _voteThresholdBps > 10000) revert InvalidAmount();
        if (_votingPeriod == 0) revert InvalidAmount();

        proposalCounter++;
        uint256 newProposalId = proposalCounter;
        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: _proposer,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            voteThresholdBps: _voteThresholdBps,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            expirationTime: block.timestamp + _votingPeriod,
            status: ProposalStatus.Pending,
            hasVoted: new Proposal.hasVoted() // Initialize empty mapping
        });
        emit ProposalCreated(newProposalId, _proposer, _description, proposals[newProposalId].expirationTime);
        return newProposalId;
    }

    /**
     * @notice Allows a user with sufficient voting power (staked fulfillers) to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.status != ProposalStatus.Pending) revert ProposalAlreadyExecuted(); // Already passed/failed
        if (block.timestamp >= proposal.expirationTime) revert ProposalExpired();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (getVotingPower(msg.sender) < MIN_VOTING_POWER) revert NotEnoughVotingPower();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += getVotingPower(msg.sender);
        } else {
            proposal.votesAgainst += getVotingPower(msg.sender);
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a proposal if it has passed its voting threshold and period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.status != ProposalStatus.Pending) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.expirationTime) revert ProposalExpired(); // Voting period must be over

        uint256 currentTotalVotingPower = 0;
        for (uint256 i = 0; i < activeFulfillers.length; i++) {
            currentTotalVotingPower += fulfillerStakes[activeFulfillers[i]];
        }
        
        // If no active fulfillers, total voting power is 0. A proposal cannot pass.
        // Or, a minimum threshold could be enforced for currentTotalVotingPower.
        if (currentTotalVotingPower == 0) {
            proposal.status = ProposalStatus.Rejected;
            return;
        }

        uint256 requiredVotes = (currentTotalVotingPower * proposal.voteThresholdBps) / 10000;

        if (proposal.votesFor > requiredVotes && proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed
            proposal.status = ProposalStatus.Approved;

            // Execute the proposed action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            if (!success) {
                // If execution fails, mark as rejected and potentially log error
                proposal.status = ProposalStatus.Rejected;
                revert("Proposal execution failed");
            }
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    /**
     * @notice Admin function to change a specific strategy parameter.
     * @dev This function is intended to be called via a successful governance proposal.
     * @param _paramName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function updateStrategyParameter(string calldata _paramName, uint256 _newValue) external onlyAdmin {
        // This function should primarily be called by `executeProposal`.
        // The `onlyAdmin` modifier allows the owner to set initial parameters or for emergency.
        strategyParameters[_paramName] = _newValue;
        emit StrategyParameterChanged(_paramName, _newValue, msg.sender);
    }

    /**
     * @notice Grants an address admin privileges.
     * @dev Only the current owner can call this. Admin can set base fees and slash stakes.
     * @param _account The address to grant admin role.
     */
    function grantAdminRole(address _account) external onlyOwner {
        if (isAdmin[_account]) return; // Already an admin
        isAdmin[_account] = true;
        emit AdminRoleGranted(_account);
    }

    /**
     * @notice Revokes admin privileges from an address.
     * @dev Only the current owner can call this.
     * @param _account The address to revoke admin role.
     */
    function revokeAdminRole(address _account) external onlyOwner {
        if (!isAdmin[_account]) return; // Not an admin
        isAdmin[_account] = false;
        emit AdminRoleRevoked(_account);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS (8)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves the details of a specific intent.
     * @param _intentId The ID of the intent.
     * @return The Intent struct.
     */
    function getIntentDetails(uint256 _intentId) external view returns (Intent memory) {
        if (intents[_intentId].id == 0) revert InvalidIntentId();
        return intents[_intentId];
    }

    /**
     * @notice Retrieves all intent IDs associated with a specific user.
     * @param _user The address of the user.
     * @return An array of intent IDs.
     */
    function getUserIntents(address _user) external view returns (uint256[] memory) {
        return userIntentIds[_user];
    }

    /**
     * @notice Retrieves the stake, reputation, and active status of a fulfiller.
     * @param _fulfiller The address of the fulfiller.
     * @return stake The staked amount (in ETH).
     * @return reputation The current reputation score.
     * @return isActive True if the fulfiller is currently active.
     */
    function getFulfillerDetails(address _fulfiller) external view returns (uint256 stake, int256 reputation, bool isActive) {
        return (fulfillerStakes[_fulfiller], fulfillerReputations[_fulfiller], isFulfillerActive[_fulfiller]);
    }

    /**
     * @notice Returns the total number of currently active fulfillers.
     */
    function getActiveFulfillerCount() external view returns (uint256) {
        return activeFulfillers.length;
    }

    /**
     * @notice Queries the recommended optimal strategy based on current adaptive parameters.
     * @dev This is a heuristic. Off-chain solvers would use these parameters as guidance.
     * @param _assetIn The input asset.
     * @param _assetOut The output asset.
     * @param _amountIn The amount of input asset.
     * @return recommendedSlippageBps Recommended slippage in basis points.
     * @return preferredDex A string indicating a preferred decentralized exchange (example).
     * @return minFulfillerReputation Minimum reputation score for fulfillers for this type of intent.
     */
    function queryOptimalStrategy(
        address _assetIn, // Can be used for asset-specific strategies
        address _assetOut, // Can be used for asset-specific strategies
        uint256 _amountIn // Can influence strategy (e.g., large amounts might need different DEXs)
    ) external view returns (uint256 recommendedSlippageBps, string memory preferredDex, int256 minFulfillerReputation) {
        // Example logic:
        // Use a default slippage unless specific conditions apply.
        recommendedSlippageBps = strategyParameters["defaultSlippageBps"];

        // For simplicity, hardcode a preferred DEX based on a parameter or general preference.
        // In a real system, weights for various DEXs would be stored and used to select.
        // This could be dynamic based on asset pairs, volume, current fees on DEXs, etc.
        preferredDex = "Uniswap V3"; 

        // Minimum fulfiller reputation might be higher for more complex/larger intents
        minFulfillerReputation = strategyParameters["minReputationForComplexIntent"];
        if (_amountIn > 1000 ether) { // Example: higher reputation for large value intents
            minFulfillerReputation += 50;
        }

        return (recommendedSlippageBps, preferredDex, minFulfillerReputation);
    }

    /**
     * @notice Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct (excluding the internal hasVoted mapping).
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            bytes memory callData,
            address targetContract,
            uint256 voteThresholdBps,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 creationTime,
            uint256 expirationTime,
            ProposalStatus status
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.callData,
            proposal.targetContract,
            proposal.voteThresholdBps,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.creationTime,
            proposal.expirationTime,
            proposal.status
        );
    }

    /**
     * @notice Returns the voting power of an address.
     * @dev Currently, voting power is directly tied to fulfiller stake (in ETH).
     * @param _voter The address to check voting power for.
     * @return The voting power (stake amount) of the address.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        if (!isFulfillerActive[_voter]) return 0;
        return fulfillerStakes[_voter];
    }

    /**
     * @notice Returns the current protocol utilization metric.
     */
    function getProtocolUtilizationMetric() external view returns (uint256) {
        return protocolUtilizationMetric;
    }
    
    /**
     * @notice Returns the current fulfiller stake requirement (in ETH).
     */
    function getFulfillerStakeRequirement() external view returns (uint256) {
        return fulfillerStakeAmount;
    }


    /*///////////////////////////////////////////////////////////////
                            ADMIN/OWNER UTILITIES (1)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the owner to recover any ERC20 tokens accidentally sent to the contract.
     * @dev Crucial for avoiding lost funds.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to recover.
     */
    function recoverERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (!IERC20(_tokenAddress).transfer(owner(), _amount)) {
            revert TransferFailed();
        }
    }
}
```