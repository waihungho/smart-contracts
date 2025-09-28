Here's a smart contract in Solidity called "ChronosPact," designed with several advanced, creative, and trendy concepts:

**Concept: ChronosPact - Decentralized Future Commitments & Trust Protocol**

ChronosPact allows users to make on-chain "Pacts" – commitments to perform a specific action (e.g., transfer tokens, call another contract) at a future block/timestamp *or* upon the fulfillment of an on-chain condition. To ensure commitment, users stake collateral. The protocol features a dynamic "Trust Score" system that rewards users for fulfilling Pacts and penalizes failures. Additionally, a "Challenge" mechanism allows other users to stake against a Pact, essentially betting on its failure or success, adding a prediction market-like dynamic.

---

### **ChronosPact: Outline and Function Summary**

**I. Core Structures & Enums:**
*   `Pact`: Defines a commitment, including its creator, type, target, value/data, conditions, deadline, status, and collateral.
*   `TrustProfile`: Stores a user's accumulated trust score, and counts of fulfilled/failed/challenged pacts/challenges.
*   `Challenge`: Details an ongoing or resolved challenge against a Pact.
*   `PactType`: Differentiates between ERC-20 transfer, native token transfer, and generic contract call.
*   `PactStatus`: Tracks the lifecycle of a Pact (Pending, Fulfilled, Failed, Challenged, Canceled).
*   `ChallengeStatus`: Tracks the lifecycle of a Challenge (Active, Successful, Failed, Withdrawn).

**II. State Variables:**
*   `pacts`: Mapping from `pactId` to `Pact` struct.
*   `trustProfiles`: Mapping from `address` to `TrustProfile` struct.
*   `challenges`: Mapping from `challengeId` to `Challenge` struct.
*   `pactsByCreator`: Mapping for efficient retrieval of a user's pacts.
*   `challengesByPact`: Mapping for efficient retrieval of challenges on a pact.
*   Protocol parameters: `collateralRatio`, `challengeFee`, `pactGracePeriodBlocks`, `protocolFeePercentage`, `designatedCollateralToken`.
*   Counters for `nextPactId`, `nextChallengeId`.
*   `protocolFeesCollected`: Total fees accumulated by the protocol.

**III. Functions Summary (25+ functions):**

**A. Pact Creation (Commitment):**
1.  `constructor()`: Initializes the contract with `Ownable` and `Pausable` roles and sets initial protocol parameters.
2.  `createPact_ERC20Transfer()`: Allows a user to commit to an ERC-20 token transfer, providing collateral and specifying transfer details, conditions, and a deadline.
3.  `createPact_NativeTransfer()`: Allows a user to commit to a native token (ETH) transfer, providing collateral and specifying transfer details, conditions, and a deadline.
4.  `createPact_ContractCall()`: (Advanced) Allows a user to commit to a generic call to another contract, providing collateral and specifying call data, conditions, and a deadline. The condition can be a `view` function call on an external contract returning `bool`.

**B. Pact Resolution & Management:**
5.  `fulfillPact()`: Executes a `Pending` Pact if its conditions are met and it's within its fulfillment period. Creator gets collateral back plus a reward; Trust Score increases.
6.  `failPact()`: Allows the Pact creator to explicitly mark their `Pending` Pact as `Failed` (incurring penalties).
7.  `revokePact()`: Allows the Pact creator to cancel their `Pending` and `Unchallenged` Pact before its deadline, with a penalty.
8.  `batchFulfillPacts()`: (Utility) Allows a user to fulfill multiple eligible Pacts in a single transaction.
9.  `delegatePactExecution()`: Allows a Pact creator to assign another address the right to call `fulfillPact` on their behalf.

**C. Challenge System (Prediction Market Aspect):**
10. `challengePact()`: Allows any user to stake tokens to challenge a `Pending` Pact, essentially betting that it will fail.
11. `resolveChallenge()`: Determines the outcome of a `Challenged` Pact and its associated `Challenge(s)` based on whether the Pact was ultimately fulfilled or failed.
12. `claimChallengeReward()`: Allows a successful challenger to claim their reward from the failed Pact's collateral.
13. `withdrawChallengeCollateral()`: Allows an unsuccessful challenger to withdraw their staked collateral.

**D. Trust Profile & Data Query:**
14. `getTrustProfile()`: Returns the `TrustProfile` details for a given address.
15. `getPactDetails()`: Returns the full details of a specific Pact by its ID.
16. `getPactsByCreator()`: Returns an array of Pact IDs created by a given address.
17. `getChallengesForPact()`: Returns an array of Challenge IDs associated with a specific Pact.
18. `getChallengeDetails()`: Returns the full details of a specific Challenge by its ID.
19. `isPactFulfillable()`: (View) Checks if a given Pact is currently fulfillable based on its deadline and conditions.

**E. Protocol Administration (Owner-Only):**
20. `updateProtocolParameters()`: Allows the contract owner to update core protocol parameters (e.g., `collateralRatio`, `challengeFee`, `protocolFeePercentage`).
21. `updatePactGracePeriod()`: Allows the owner to set the `pactGracePeriodBlocks`.
22. `setDesignatedCollateralToken()`: Allows the owner to change the ERC-20 token used for collateral.
23. `emergencyPause()`: (Pausable) Pauses all critical state-changing functions in an emergency.
24. `emergencyUnpause()`: (Pausable) Unpauses critical functions.
25. `withdrawProtocolFees()`: Allows the owner to withdraw accumulated `protocolFeesCollected` to a designated treasury address.
26. `rescueLostFunds()`: Allows the owner to recover accidentally sent ERC-20 tokens (not used as collateral) from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ChronosPact - Decentralized Future Commitments & Trust Protocol
 * @dev ChronosPact enables users to make on-chain commitments (Pacts) to perform future actions.
 *      Pacts are secured with collateral and can be contingent on on-chain conditions or deadlines.
 *      The protocol includes a Trust Score system that rewards fulfilled commitments and penalizes failures.
 *      A unique Challenge mechanism allows users to bet on the success or failure of Pacts, adding a prediction market element.
 *      This contract is designed to be interesting, advanced-concept, creative, and avoid duplicating existing open-source projects' core logic.
 */
contract ChronosPact is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Enums ---
    enum PactType {
        ERC20_TRANSFER,
        NATIVE_TRANSFER,
        CONTRACT_CALL
    }

    enum PactStatus {
        Pending,        // Awaiting fulfillment or challenge
        Fulfilled,      // Action completed successfully
        Failed,         // Action not completed (deadline passed, or explicitly failed)
        Challenged,     // Under active challenge
        Canceled        // Revoked by creator or admin
    }

    enum ChallengeStatus {
        Active,         // Challenge is ongoing
        Successful,     // Challenger won (Pact failed)
        Failed,         // Challenger lost (Pact fulfilled)
        Withdrawn       // Challenger withdrew collateral (if possible, e.g., if pact canceled)
    }

    // --- Structs ---

    /**
     * @dev Represents a user's commitment.
     *      A Pact can be for an ERC-20 transfer, native token transfer, or a generic contract call.
     *      It can have a block deadline or a dynamic on-chain condition.
     */
    struct Pact {
        address creator;
        PactType pactType;
        address tokenAddress;       // For ERC20_TRANSFER
        uint256 amountOrValue;      // ERC20 amount, Native ETH value
        address targetAddress;      // Recipient for transfers, contract address for calls
        bytes callData;             // For CONTRACT_CALL (function selector + encoded args)

        uint256 createdBlock;
        uint256 fulfillmentDeadline; // Block number by which the pact must be fulfilled
        uint256 conditionalTriggerBlock; // If 0, only deadline matters. If >0, condition must be met AFTER this block.

        // Advanced Conditional Fulfillment: A staticcall to a target contract's view function
        address conditionalTargetContract; // Address of contract to query
        bytes conditionalCallData;       // Function selector + encoded args for a view function returning bool

        PactStatus status;
        uint256 collateralAmount;
        uint256 lastUpdateBlock;
        uint256 fulfillmentBlock; // Block when pact was fulfilled/failed
        address delegatedExecutor; // Address allowed to fulfill the pact
    }

    /**
     * @dev Represents a user's reputation and activity within the protocol.
     *      Trust score impacts future collateral requirements or reward multipliers (not yet implemented, but planned extension).
     */
    struct TrustProfile {
        uint256 score;              // Accumulated trust score
        uint256 fulfilledPacts;     // Pacts created by this user that were fulfilled
        uint256 failedPacts;        // Pacts created by this user that failed
        uint256 challengedPacts;    // Pacts created by this user that faced challenges
        uint256 successfulChallenges; // Challenges initiated by this user that were successful
        uint256 failedChallenges;   // Challenges initiated by this user that failed
    }

    /**
     * @dev Represents a challenge against a Pact.
     *      Challengers stake collateral, betting on the failure of a Pact.
     */
    struct Challenge {
        address challenger;
        uint256 pactId;
        uint256 challengeBlock;
        uint256 collateral;
        ChallengeStatus status;
    }

    // --- State Variables ---

    uint256 public nextPactId;
    uint256 public nextChallengeId;

    mapping(uint256 => Pact) public pacts;
    mapping(address => TrustProfile) public trustProfiles;
    mapping(uint256 => Challenge) public challenges;

    // For efficient retrieval
    mapping(address => uint256[]) public pactsByCreator;
    mapping(uint256 => uint256[]) public challengesByPact;

    // Protocol Parameters (Owner-adjustable)
    uint256 public collateralRatio;            // Basis points (e.g., 1000 = 10% of committed value)
    uint256 public challengeFee;               // Flat fee for initiating a challenge (in collateral token)
    uint256 public pactGracePeriodBlocks;      // Number of blocks after deadline to still allow fulfillment
    uint256 public protocolFeePercentage;      // Percentage of collateral taken as protocol fee on failed pacts (basis points)
    uint256 public trustScoreRewardFactor;     // Multiplier for trust score increase on fulfillment
    uint256 public trustScorePenaltyFactor;    // Multiplier for trust score decrease on failure

    IERC20 public designatedCollateralToken;
    uint256 public protocolFeesCollected;

    // --- Events ---
    event PactCreated(uint256 indexed pactId, address indexed creator, PactType pactType, uint256 amountOrValue, address targetAddress, uint256 deadline, uint256 collateral);
    event PactFulfilled(uint256 indexed pactId, address indexed creator, uint256 blockNumber, uint256 trustScoreChange);
    event PactFailed(uint256 indexed pactId, address indexed creator, uint256 blockNumber, uint256 penaltyAmount, uint256 protocolFee, uint256 trustScoreChange);
    event PactRevoked(uint256 indexed pactId, address indexed creator, uint256 penaltyAmount);
    event PactCanceled(uint256 indexed pactId, address indexed creator, address indexed canceledBy);
    event PactDelegationUpdated(uint256 indexed pactId, address indexed creator, address indexed newDelegatedExecutor);

    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed pactId, address indexed challenger, uint256 collateral);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed pactId, ChallengeStatus status);
    event ChallengeRewardClaimed(uint256 indexed challengeId, uint256 indexed pactId, address indexed challenger, uint256 rewardAmount);
    event ChallengeCollateralWithdrawn(uint256 indexed challengeId, uint256 indexed pactId, address indexed challenger, uint256 collateralAmount);

    event ProtocolParametersUpdated(uint256 newCollateralRatio, uint256 newChallengeFee, uint256 newProtocolFeePercentage, uint256 newTrustScoreReward, uint256 newTrustScorePenalty);
    event DesignatedCollateralTokenUpdated(address newAddress);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event FundsRescued(address indexed token, address indexed recipient, uint256 amount);

    // --- Constructor ---
    /**
     * @dev Initializes the ChronosPact contract.
     * @param _owner The address that will own the contract.
     * @param _collateralToken The ERC-20 token to be used for collateral.
     * @param _initialCollateralRatio Initial collateral ratio in basis points (e.g., 1000 for 10%).
     * @param _initialChallengeFee Initial flat fee for challenging a pact.
     * @param _initialGracePeriodBlocks Initial number of blocks after deadline for fulfillment.
     * @param _initialProtocolFeePercentage Initial protocol fee percentage in basis points (e.g., 500 for 5%).
     * @param _initialTrustScoreRewardFactor Initial factor for trust score increase.
     * @param _initialTrustScorePenaltyFactor Initial factor for trust score decrease.
     */
    constructor(
        address _owner,
        address _collateralToken,
        uint256 _initialCollateralRatio,
        uint256 _initialChallengeFee,
        uint256 _initialGracePeriodBlocks,
        uint256 _initialProtocolFeePercentage,
        uint256 _initialTrustScoreRewardFactor,
        uint256 _initialTrustScorePenaltyFactor
    ) Ownable(_owner) Pausable() {
        require(_collateralToken != address(0), "Invalid collateral token address");
        require(_initialCollateralRatio <= 10000, "Collateral ratio must be <= 100%");
        require(_initialProtocolFeePercentage <= 10000, "Protocol fee percentage must be <= 100%");

        designatedCollateralToken = IERC20(_collateralToken);
        collateralRatio = _initialCollateralRatio;
        challengeFee = _initialChallengeFee;
        pactGracePeriodBlocks = _initialGracePeriodBlocks;
        protocolFeePercentage = _initialProtocolFeePercentage;
        trustScoreRewardFactor = _initialTrustScoreRewardFactor;
        trustScorePenaltyFactor = _initialTrustScorePenaltyFactor;

        nextPactId = 1;
        nextChallengeId = 1;
    }

    // --- Modifiers ---
    modifier onlyPactCreator(uint256 _pactId) {
        require(pacts[_pactId].creator == _msgSender(), "Only pact creator can call this function");
        _;
    }

    modifier onlyPactCreatorOrDelegatedExecutor(uint256 _pactId) {
        require(pacts[_pactId].creator == _msgSender() || pacts[_pactId].delegatedExecutor == _msgSender(),
            "Only pact creator or delegated executor can call this function");
        _;
    }

    // --- Pact Creation Functions (3) ---

    /**
     * @dev 2. createPact_ERC20Transfer
     * @notice Creates a pact to transfer an ERC-20 token after conditions are met or deadline.
     * @param _tokenAddress The ERC-20 token to be transferred.
     * @param _amount The amount of ERC-20 tokens to transfer.
     * @param _targetAddress The recipient of the ERC-20 tokens.
     * @param _fulfillmentDeadline The block number by which the pact must be fulfilled.
     * @param _conditionalTargetContract Optional: Address of a contract to query for a boolean condition.
     * @param _conditionalCallData Optional: Bytes for a staticcall to _conditionalTargetContract (must return bool).
     * @param _conditionalTriggerBlock Optional: The block number after which the condition becomes active/can be checked.
     * @return The ID of the created pact.
     */
    function createPact_ERC20Transfer(
        address _tokenAddress,
        uint256 _amount,
        address _targetAddress,
        uint256 _fulfillmentDeadline,
        address _conditionalTargetContract,
        bytes calldata _conditionalCallData,
        uint256 _conditionalTriggerBlock
    ) external payable whenNotPaused returns (uint256) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than zero");
        require(_targetAddress != address(0), "Invalid target address");
        require(_fulfillmentDeadline > block.number, "Deadline must be in the future");
        
        if (_conditionalTargetContract != address(0)) {
            require(_conditionalCallData.length > 0, "Call data required for conditional contract");
        } else {
            require(_conditionalCallData.length == 0, "Call data not allowed without conditional target");
            require(_conditionalTriggerBlock == 0, "Trigger block not allowed without conditional target");
        }

        uint256 requiredCollateral = (_amount * collateralRatio) / 10000;
        require(requiredCollateral > 0, "Collateral amount must be positive");
        
        // Transfer collateral
        designatedCollateralToken.safeTransferFrom(_msgSender(), address(this), requiredCollateral);

        uint256 currentPactId = nextPactId++;
        pacts[currentPactId] = Pact({
            creator: _msgSender(),
            pactType: PactType.ERC20_TRANSFER,
            tokenAddress: _tokenAddress,
            amountOrValue: _amount,
            targetAddress: _targetAddress,
            callData: "", // Not applicable for simple transfer
            createdBlock: block.number,
            fulfillmentDeadline: _fulfillmentDeadline,
            conditionalTriggerBlock: _conditionalTriggerBlock,
            conditionalTargetContract: _conditionalTargetContract,
            conditionalCallData: _conditionalCallData,
            status: PactStatus.Pending,
            collateralAmount: requiredCollateral,
            lastUpdateBlock: block.number,
            fulfillmentBlock: 0,
            delegatedExecutor: address(0)
        });

        pactsByCreator[_msgSender()].push(currentPactId);
        emit PactCreated(currentPactId, _msgSender(), PactType.ERC20_TRANSFER, _amount, _targetAddress, _fulfillmentDeadline, requiredCollateral);
        return currentPactId;
    }

    /**
     * @dev 3. createPact_NativeTransfer
     * @notice Creates a pact to transfer native ETH after conditions are met or deadline.
     * @param _amount The amount of native ETH to transfer.
     * @param _targetAddress The recipient of the native ETH.
     * @param _fulfillmentDeadline The block number by which the pact must be fulfilled.
     * @param _conditionalTargetContract Optional: Address of a contract to query for a boolean condition.
     * @param _conditionalCallData Optional: Bytes for a staticcall to _conditionalTargetContract (must return bool).
     * @param _conditionalTriggerBlock Optional: The block number after which the condition becomes active/can be checked.
     * @return The ID of the created pact.
     */
    function createPact_NativeTransfer(
        uint256 _amount,
        address _targetAddress,
        uint256 _fulfillmentDeadline,
        address _conditionalTargetContract,
        bytes calldata _conditionalCallData,
        uint256 _conditionalTriggerBlock
    ) external payable whenNotPaused returns (uint256) {
        require(_amount > 0, "Amount must be greater than zero");
        require(_targetAddress != address(0), "Invalid target address");
        require(_fulfillmentDeadline > block.number, "Deadline must be in the future");

        if (_conditionalTargetContract != address(0)) {
            require(_conditionalCallData.length > 0, "Call data required for conditional contract");
        } else {
            require(_conditionalCallData.length == 0, "Call data not allowed without conditional target");
            require(_conditionalTriggerBlock == 0, "Trigger block not allowed without conditional target");
        }

        uint256 requiredCollateral = (_amount * collateralRatio) / 10000;
        require(requiredCollateral > 0, "Collateral amount must be positive");
        
        // Transfer collateral
        designatedCollateralToken.safeTransferFrom(_msgSender(), address(this), requiredCollateral);

        uint256 currentPactId = nextPactId++;
        pacts[currentPactId] = Pact({
            creator: _msgSender(),
            pactType: PactType.NATIVE_TRANSFER,
            tokenAddress: address(0), // Not applicable for native transfer
            amountOrValue: _amount,
            targetAddress: _targetAddress,
            callData: "", // Not applicable for simple transfer
            createdBlock: block.number,
            fulfillmentDeadline: _fulfillmentDeadline,
            conditionalTriggerBlock: _conditionalTriggerBlock,
            conditionalTargetContract: _conditionalTargetContract,
            conditionalCallData: _conditionalCallData,
            status: PactStatus.Pending,
            collateralAmount: requiredCollateral,
            lastUpdateBlock: block.number,
            fulfillmentBlock: 0,
            delegatedExecutor: address(0)
        });

        pactsByCreator[_msgSender()].push(currentPactId);
        emit PactCreated(currentPactId, _msgSender(), PactType.NATIVE_TRANSFER, _amount, _targetAddress, _fulfillmentDeadline, requiredCollateral);
        return currentPactId;
    }

    /**
     * @dev 4. createPact_ContractCall
     * @notice Creates a pact to make a generic call to another contract.
     *         This function allows for complex on-chain commitments.
     * @param _targetAddress The address of the contract to call.
     * @param _callData The encoded function call (selector + arguments) for the target contract.
     * @param _ethValue The amount of ETH to send with the call (0 for non-payable functions).
     * @param _fulfillmentDeadline The block number by which the pact must be fulfilled.
     * @param _conditionalTargetContract Optional: Address of a contract to query for a boolean condition.
     * @param _conditionalCallData Optional: Bytes for a staticcall to _conditionalTargetContract (must return bool).
     * @param _conditionalTriggerBlock Optional: The block number after which the condition becomes active/can be checked.
     * @return The ID of the created pact.
     */
    function createPact_ContractCall(
        address _targetAddress,
        bytes calldata _callData,
        uint256 _ethValue,
        uint256 _fulfillmentDeadline,
        address _conditionalTargetContract,
        bytes calldata _conditionalCallData,
        uint256 _conditionalTriggerBlock
    ) external payable whenNotPaused returns (uint256) {
        require(_targetAddress != address(0), "Invalid target address");
        require(_callData.length > 0, "Call data cannot be empty");
        require(_fulfillmentDeadline > block.number, "Deadline must be in the future");
        
        if (_conditionalTargetContract != address(0)) {
            require(_conditionalCallData.length > 0, "Call data required for conditional contract");
        } else {
            require(_conditionalCallData.length == 0, "Call data not allowed without conditional target");
            require(_conditionalTriggerBlock == 0, "Trigger block not allowed without conditional target");
        }

        uint256 requiredCollateral = (_ethValue * collateralRatio) / 10000;
        // If _ethValue is 0, collateral is still required based on a minimal pact value, or we could skip collateral.
        // For simplicity, let's say 0 ETH value means 0 collateral for now.
        // Or we enforce a minimal pact value/collateral if 0 ETH.
        if (requiredCollateral == 0) { // Enforce a minimum collateral for non-ETH value calls
            requiredCollateral = challengeFee; // Use challenge fee as a baseline minimum
        }
        
        // Transfer collateral
        designatedCollateralToken.safeTransferFrom(_msgSender(), address(this), requiredCollateral);

        uint256 currentPactId = nextPactId++;
        pacts[currentPactId] = Pact({
            creator: _msgSender(),
            pactType: PactType.CONTRACT_CALL,
            tokenAddress: address(0), // Not applicable for generic call
            amountOrValue: _ethValue,
            targetAddress: _targetAddress,
            callData: _callData,
            createdBlock: block.number,
            fulfillmentDeadline: _fulfillmentDeadline,
            conditionalTriggerBlock: _conditionalTriggerBlock,
            conditionalTargetContract: _conditionalTargetContract,
            conditionalCallData: _conditionalCallData,
            status: PactStatus.Pending,
            collateralAmount: requiredCollateral,
            lastUpdateBlock: block.number,
            fulfillmentBlock: 0,
            delegatedExecutor: address(0)
        });

        pactsByCreator[_msgSender()].push(currentPactId);
        emit PactCreated(currentPactId, _msgSender(), PactType.CONTRACT_CALL, _ethValue, _targetAddress, _fulfillmentDeadline, requiredCollateral);
        return currentPactId;
    }

    // --- Pact Resolution & Management (5) ---

    /**
     * @dev 5. fulfillPact
     * @notice Allows the pact creator or delegated executor to fulfill a pending pact.
     *         Transfers collateral back to creator, applies trust score update, and performs the committed action.
     * @param _pactId The ID of the pact to fulfill.
     */
    function fulfillPact(uint256 _pactId) external payable onlyPactCreatorOrDelegatedExecutor(_pactId) whenNotPaused {
        Pact storage pact = pacts[_pactId];
        require(pact.status == PactStatus.Pending || pact.status == PactStatus.Challenged, "Pact is not pending or challenged");
        require(isPactFulfillable(_pactId), "Pact is not yet fulfillable or deadline passed without grace");

        // Execute the committed action
        bool success;
        bytes memory returnData;
        if (pact.pactType == PactType.ERC20_TRANSFER) {
            IERC20(pact.tokenAddress).safeTransfer(pact.targetAddress, pact.amountOrValue);
            success = true;
        } else if (pact.pactType == PactType.NATIVE_TRANSFER) {
            (success,) = pact.targetAddress.call{value: pact.amountOrValue}("");
        } else if (pact.pactType == PactType.CONTRACT_CALL) {
            (success, returnData) = pact.targetAddress.call{value: pact.amountOrValue}(pact.callData);
        } else {
            revert("Unknown PactType");
        }
        require(success, "Pact action failed to execute");

        pact.status = PactStatus.Fulfilled;
        pact.fulfillmentBlock = block.number;
        pact.lastUpdateBlock = block.number;

        // Update Trust Profile
        TrustProfile storage creatorProfile = trustProfiles[pact.creator];
        creatorProfile.fulfilledPacts++;
        creatorProfile.score += trustScoreRewardFactor; // Increase score

        // Return collateral to creator
        designatedCollateralToken.safeTransfer(pact.creator, pact.collateralAmount);

        emit PactFulfilled(_pactId, pact.creator, block.number, trustScoreRewardFactor);

        // If pact was challenged, resolve challenges
        if (challengesByPact[_pactId].length > 0) {
            for (uint256 i = 0; i < challengesByPact[_pactId].length; i++) {
                resolveChallenge(challengesByPact[_pactId][i]);
            }
        }
    }

    /**
     * @dev 6. failPact
     * @notice Allows the pact creator to explicitly mark their pending pact as failed.
     *         This incurs penalties and updates trust score.
     * @param _pactId The ID of the pact to fail.
     */
    function failPact(uint256 _pactId) external onlyPactCreator(_pactId) whenNotPaused {
        Pact storage pact = pacts[_pactId];
        require(pact.status == PactStatus.Pending || pact.status == PactStatus.Challenged, "Pact is not pending or challenged");
        require(block.number < pact.fulfillmentDeadline + pactGracePeriodBlocks, "Cannot explicitly fail after grace period");

        _handlePactFailure(_pactId, pact.creator, pact.collateralAmount);
    }

    /**
     * @dev 7. revokePact
     * @notice Allows a pact creator to revoke their pending and unchallenged pact before its deadline.
     *         A penalty is applied, and the remaining collateral is returned.
     * @param _pactId The ID of the pact to revoke.
     */
    function revokePact(uint256 _pactId) external onlyPactCreator(_pactId) whenNotPaused {
        Pact storage pact = pacts[_pactId];
        require(pact.status == PactStatus.Pending, "Pact must be pending to be revoked");
        require(challengesByPact[_pactId].length == 0, "Cannot revoke a challenged pact");
        require(block.number < pact.fulfillmentDeadline, "Cannot revoke after deadline");

        pact.status = PactStatus.Canceled;
        pact.lastUpdateBlock = block.number;

        uint256 penaltyAmount = (pact.collateralAmount * protocolFeePercentage) / 10000;
        uint256 creatorRefund = pact.collateralAmount - penaltyAmount;
        
        protocolFeesCollected += penaltyAmount;
        designatedCollateralToken.safeTransfer(pact.creator, creatorRefund);

        emit PactRevoked(_pactId, pact.creator, penaltyAmount);
    }

    /**
     * @dev 8. batchFulfillPacts
     * @notice Allows a user to fulfill multiple eligible Pacts in a single transaction.
     * @param _pactIds An array of Pact IDs to fulfill.
     */
    function batchFulfillPacts(uint256[] calldata _pactIds) external payable whenNotPaused {
        for (uint256 i = 0; i < _pactIds.length; i++) {
            Pact storage pact = pacts[_pactIds[i]];
            require(pact.creator == _msgSender() || pact.delegatedExecutor == _msgSender(),
                "Sender is not creator or delegated executor for pact");
            fulfillPact(_pactIds[i]); // Re-use fulfillPact logic
        }
    }

    /**
     * @dev 9. delegatePactExecution
     * @notice Allows a Pact creator to delegate the right to fulfill their pact to another address.
     * @param _pactId The ID of the pact.
     * @param _delegatedExecutor The address to delegate execution rights to.
     */
    function delegatePactExecution(uint256 _pactId, address _delegatedExecutor) external onlyPactCreator(_pactId) whenNotPaused {
        Pact storage pact = pacts[_pactId];
        require(pact.status == PactStatus.Pending || pact.status == PactStatus.Challenged, "Pact is not pending or challenged");
        require(_delegatedExecutor != address(0), "Delegated executor cannot be zero address");
        pact.delegatedExecutor = _delegatedExecutor;
        emit PactDelegationUpdated(_pactId, pact.creator, _delegatedExecutor);
    }

    // Internal helper for pact failure logic
    function _handlePactFailure(uint256 _pactId, address _creator, uint256 _collateralAmount) internal {
        Pact storage pact = pacts[_pactId];
        pact.status = PactStatus.Failed;
        pact.fulfillmentBlock = block.number;
        pact.lastUpdateBlock = block.number;

        // Update Trust Profile
        TrustProfile storage creatorProfile = trustProfiles[_creator];
        creatorProfile.failedPacts++;
        if (creatorProfile.score >= trustScorePenaltyFactor) {
            creatorProfile.score -= trustScorePenaltyFactor; // Decrease score
        } else {
            creatorProfile.score = 0; // Don't go below zero
        }

        uint256 protocolFee = (_collateralAmount * protocolFeePercentage) / 10000;
        protocolFeesCollected += protocolFee;

        emit PactFailed(_pactId, _creator, block.number, _collateralAmount, protocolFee, trustScorePenaltyFactor);

        // Resolve any challenges against this pact (they should now be successful)
        if (challengesByPact[_pactId].length > 0) {
            for (uint256 i = 0; i < challengesByPact[_pactId].length; i++) {
                resolveChallenge(challengesByPact[_pactId][i]);
            }
        }
    }

    // --- Challenge System (4) ---

    /**
     * @dev 10. challengePact
     * @notice Allows a user to stake collateral to challenge a pending pact.
     *         If the pact fails, the challenger earns a reward from the pact creator's collateral.
     * @param _pactId The ID of the pact to challenge.
     */
    function challengePact(uint256 _pactId) external whenNotPaused returns (uint256) {
        Pact storage pact = pacts[_pactId];
        require(pact.status == PactStatus.Pending, "Pact must be pending to be challenged");
        require(block.number < pact.fulfillmentDeadline, "Cannot challenge after pact deadline");
        require(_msgSender() != pact.creator, "Cannot challenge your own pact");

        // Transfer challenge fee collateral
        designatedCollateralToken.safeTransferFrom(_msgSender(), address(this), challengeFee);

        uint256 currentChallengeId = nextChallengeId++;
        challenges[currentChallengeId] = Challenge({
            challenger: _msgSender(),
            pactId: _pactId,
            challengeBlock: block.number,
            collateral: challengeFee,
            status: ChallengeStatus.Active
        });

        pact.status = PactStatus.Challenged; // Mark pact as challenged
        pact.lastUpdateBlock = block.number;
        
        TrustProfile storage creatorProfile = trustProfiles[pact.creator];
        creatorProfile.challengedPacts++;

        challengesByPact[_pactId].push(currentChallengeId);
        emit ChallengeCreated(currentChallengeId, _pactId, _msgSender(), challengeFee);
        return currentChallengeId;
    }

    /**
     * @dev 11. resolveChallenge
     * @notice Determines the outcome of a challenge based on its associated pact's status.
     *         This can be called automatically by fulfillPact/failPact, or manually after grace period.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Active, "Challenge is not active");

        Pact storage pact = pacts[challenge.pactId];
        
        // Manual resolution only after grace period
        if (pact.status == PactStatus.Pending || pact.status == PactStatus.Challenged) {
             require(block.number >= pact.fulfillmentDeadline + pactGracePeriodBlocks, "Pact not yet expired for resolution");
             // If manual resolution after grace period, and pact is still pending/challenged, it has failed.
             _handlePactFailure(challenge.pactId, pact.creator, pact.collateralAmount);
        }

        TrustProfile storage challengerProfile = trustProfiles[challenge.challenger];
        if (pact.status == PactStatus.Failed) {
            challenge.status = ChallengeStatus.Successful;
            challengerProfile.successfulChallenges++;
        } else if (pact.status == PactStatus.Fulfilled || pact.status == PactStatus.Canceled) { // If canceled, challenger loses their stake
            challenge.status = ChallengeStatus.Failed;
            challengerProfile.failedChallenges++;
        } else {
            revert("Pact status not in a resolvable state");
        }
        
        emit ChallengeResolved(_challengeId, challenge.pactId, challenge.status);
    }

    /**
     * @dev 12. claimChallengeReward
     * @notice Allows a successful challenger to claim their reward from a failed pact's collateral.
     *         The reward is the challenger's original stake plus a portion of the creator's forfeited collateral.
     * @param _challengeId The ID of the challenge.
     */
    function claimChallengeReward(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger == _msgSender(), "Only challenger can claim reward");
        require(challenge.status == ChallengeStatus.Successful, "Challenge is not successful");

        Pact storage pact = pacts[challenge.pactId];
        require(pact.status == PactStatus.Failed, "Associated pact must be failed");

        // Reward is challenger's collateral + a portion of pact's forfeited collateral
        // For simplicity, let's say the challenger gets their collateral back + half of the non-protocol-fee portion
        uint256 pactPenalty = pact.collateralAmount - ((pact.collateralAmount * protocolFeePercentage) / 10000); // What's left after protocol fee
        uint256 rewardAmount = challenge.collateral + (pactPenalty / 2); // Split penalty with protocol
        protocolFeesCollected += pactPenalty - (pactPenalty / 2); // The other half of pact penalty goes to protocol

        designatedCollateralToken.safeTransfer(_msgSender(), rewardAmount);
        challenge.status = ChallengeStatus.Withdrawn; // Mark challenge as withdrawn
        emit ChallengeRewardClaimed(_challengeId, challenge.pactId, _msgSender(), rewardAmount);
    }

    /**
     * @dev 13. withdrawChallengeCollateral
     * @notice Allows an unsuccessful challenger to withdraw their staked collateral.
     * @param _challengeId The ID of the challenge.
     */
    function withdrawChallengeCollateral(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger == _msgSender(), "Only challenger can withdraw collateral");
        require(challenge.status == ChallengeStatus.Failed, "Challenge is not failed");

        designatedCollateralToken.safeTransfer(_msgSender(), challenge.collateral);
        challenge.status = ChallengeStatus.Withdrawn; // Mark challenge as withdrawn
        emit ChallengeCollateralWithdrawn(_challengeId, challenge.pactId, _msgSender(), challenge.collateral);
    }

    // --- Trust Profile & Data Query (6) ---

    /**
     * @dev 14. getTrustProfile
     * @notice Returns the trust profile for a given address.
     * @param _user The address to query.
     * @return TrustProfile struct.
     */
    function getTrustProfile(address _user) external view returns (TrustProfile memory) {
        return trustProfiles[_user];
    }

    /**
     * @dev 15. getPactDetails
     * @notice Returns the full details of a specific Pact.
     * @param _pactId The ID of the pact.
     * @return Pact struct.
     */
    function getPactDetails(uint256 _pactId) external view returns (Pact memory) {
        return pacts[_pactId];
    }

    /**
     * @dev 16. getPactsByCreator
     * @notice Returns an array of Pact IDs created by a given address.
     * @param _creator The address of the creator.
     * @return An array of Pact IDs.
     */
    function getPactsByCreator(address _creator) external view returns (uint256[] memory) {
        return pactsByCreator[_creator];
    }

    /**
     * @dev 17. getChallengesForPact
     * @notice Returns an array of Challenge IDs associated with a specific Pact.
     * @param _pactId The ID of the pact.
     * @return An array of Challenge IDs.
     */
    function getChallengesForPact(uint256 _pactId) external view returns (uint256[] memory) {
        return challengesByPact[_pactId];
    }

    /**
     * @dev 18. getChallengeDetails
     * @notice Returns the full details of a specific Challenge.
     * @param _challengeId The ID of the challenge.
     * @return Challenge struct.
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (Challenge memory) {
        return challenges[_challengeId];
    }

    /**
     * @dev 19. isPactFulfillable
     * @notice Checks if a given Pact is currently fulfillable based on its deadline and conditions.
     * @param _pactId The ID of the pact to check.
     * @return True if the pact can be fulfilled, false otherwise.
     */
    function isPactFulfillable(uint256 _pactId) public view returns (bool) {
        Pact storage pact = pacts[_pactId];
        
        // Check deadline
        bool withinDeadline = block.number <= pact.fulfillmentDeadline + pactGracePeriodBlocks;
        if (!withinDeadline) {
            return false;
        }

        // Check conditional trigger block
        if (pact.conditionalTriggerBlock > 0 && block.number < pact.conditionalTriggerBlock) {
            return false;
        }

        // Check dynamic on-chain condition (if applicable)
        if (pact.conditionalTargetContract != address(0)) {
            (bool success, bytes memory result) = pact.conditionalTargetContract.staticcall(pact.conditionalCallData);
            if (!success || result.length != 32) { // Expecting a boolean (32 bytes for Solidity)
                return false; // Conditional call failed or returned unexpected data
            }
            // Decode the boolean result (true = 0x01, false = 0x00 for 32 bytes)
            return abi.decode(result, (bool));
        }

        return true; // No specific conditions, or all conditions met
    }

    // --- Protocol Administration (Owner-Only) (7) ---

    /**
     * @dev 20. updateProtocolParameters
     * @notice Allows the contract owner to update core protocol parameters.
     * @param _newCollateralRatio New collateral ratio in basis points (e.g., 1000 for 10%).
     * @param _newChallengeFee New flat fee for challenging a pact (in collateral token).
     * @param _newProtocolFeePercentage New protocol fee percentage in basis points.
     * @param _newTrustScoreRewardFactor New factor for trust score increase.
     * @param _newTrustScorePenaltyFactor New factor for trust score decrease.
     */
    function updateProtocolParameters(
        uint256 _newCollateralRatio,
        uint256 _newChallengeFee,
        uint256 _newProtocolFeePercentage,
        uint256 _newTrustScoreRewardFactor,
        uint256 _newTrustScorePenaltyFactor
    ) external onlyOwner {
        require(_newCollateralRatio <= 10000, "Collateral ratio must be <= 100%");
        require(_newProtocolFeePercentage <= 10000, "Protocol fee percentage must be <= 100%");

        collateralRatio = _newCollateralRatio;
        challengeFee = _newChallengeFee;
        protocolFeePercentage = _newProtocolFeePercentage;
        trustScoreRewardFactor = _newTrustScoreRewardFactor;
        trustScorePenaltyFactor = _newTrustScorePenaltyFactor;

        emit ProtocolParametersUpdated(_newCollateralRatio, _newChallengeFee, _newProtocolFeePercentage, _newTrustScoreRewardFactor, _newTrustScorePenaltyFactor);
    }

    /**
     * @dev 21. updatePactGracePeriod
     * @notice Allows the owner to set the number of blocks after the deadline for pact fulfillment.
     * @param _newGracePeriodBlocks New grace period in blocks.
     */
    function updatePactGracePeriod(uint256 _newGracePeriodBlocks) external onlyOwner {
        pactGracePeriodBlocks = _newGracePeriodBlocks;
    }

    /**
     * @dev 22. setDesignatedCollateralToken
     * @notice Allows the owner to change the ERC-20 token used for collateral.
     *         Careful: This only affects *future* pacts. Existing pacts remain with their original collateral.
     * @param _newCollateralToken The address of the new ERC-20 collateral token.
     */
    function setDesignatedCollateralToken(address _newCollateralToken) external onlyOwner {
        require(_newCollateralToken != address(0), "Invalid collateral token address");
        designatedCollateralToken = IERC20(_newCollateralToken);
        emit DesignatedCollateralTokenUpdated(_newCollateralToken);
    }

    /**
     * @dev 23. emergencyPause
     * @notice Pauses critical functions in an emergency. Inherited from Pausable.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 24. emergencyUnpause
     * @notice Unpauses critical functions. Inherited from Pausable.
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev 25. withdrawProtocolFees
     * @notice Allows the owner to withdraw accumulated protocol fees to a designated treasury address.
     * @param _recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        uint256 amount = protocolFeesCollected;
        protocolFeesCollected = 0;
        designatedCollateralToken.safeTransfer(_recipient, amount);
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    /**
     * @dev 26. rescueLostFunds
     * @notice Allows the owner to recover ERC-20 tokens accidentally sent to the contract
     *         that are not designated collateral or part of active pacts/challenges.
     * @param _tokenAddress The address of the ERC-20 token to rescue.
     * @param _recipient The address to send the rescued tokens to.
     */
    function rescueLostFunds(address _tokenAddress, address _recipient) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_recipient != address(0), "Invalid recipient address");
        require(_tokenAddress != address(designatedCollateralToken), "Cannot rescue designated collateral token this way");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue");

        token.safeTransfer(_recipient, balance);
        emit FundsRescued(_tokenAddress, _recipient, balance);
    }

    // Fallback function to prevent accidental ETH transfers to contract
    receive() external payable {
        revert("ETH not directly receivable. Use native transfer pacts.");
    }
}
```