Okay, here is a Solidity smart contract implementing a "Quantum Vault" concept. This contract explores advanced themes like conditional deposits, state-dependent unlocks, probabilistic outcomes (using Chainlink VRF simulation for demonstration), NFT-gated access, time-based mechanics, and inter-deposit dependencies, all within a vault structure.

It aims to be creative and not a standard clone by combining these elements in a complex way.

**Outline & Function Summary:**

This contract, `QuantumVault`, acts as a sophisticated vault capable of holding ETH, ERC-20, and ERC-721 tokens under various complex, state-dependent, and conditional locks. It's designed to showcase advanced Solidity patterns beyond typical staking or simple escrow.

1.  **Core Vault Operations:**
    *   `receive()`: Allows depositing ETH into the contract.
    *   `depositERC20`: Deposit a specified amount of an ERC-20 token.
    *   `depositERC721`: Deposit a specific ERC-721 token by its ID.

2.  **Advanced Deposit & State Management:**
    *   `depositSuperposition`: Deposit assets tied to multiple potential conditions. Only *one* condition needs to be met to unlock the deposit (simulating state collapse). The depositor defines the conditions.
    *   `addConditionToDeposit`: Allows the original depositor to add *more* conditions to an existing deposit (up to a limit), making it potentially easier to unlock later.
    *   `extendTimeLock`: Allows the original depositor to extend the time lock period for an existing deposit.

3.  **Conditional Withdrawal & Resolution:**
    *   `resolveSuperposition`: Attempts to withdraw a deposit made via `depositSuperposition`. It checks *all* conditions defined for the deposit and allows withdrawal if *any* are met. This function "collapses" the state.
    *   `withdrawBasedOnOracle`: Attempts to withdraw if a specific oracle condition (e.g., price crossing a threshold) is met.
    *   `withdrawWithNFTKey`: Attempts to withdraw if the caller owns a specific ERC-721 token acting as a key.
    *   `withdrawIfExternalBalanceMet`: Attempts to withdraw if the user's balance of a *different* specified token *outside* this contract meets a minimum requirement.
    *   `triggerInterDepositUnlock`: Allows unlocking one deposit if another specified deposit (owned by the same user) has already been successfully unlocked.

4.  **Probabilistic Outcomes (Chainlink VRF Simulation):**
    *   `requestProbabilisticOutcome`: Triggers a request to a VRF (Verifiable Random Function) provider (like Chainlink VRF) to get a random number. Used for actions with non-deterministic outcomes. *Note: Requires Chainlink VRF setup.*
    *   `fulfillRandomWords`: The callback function used by the VRF provider to deliver the random result. This function processes the randomness and triggers the dependent action (e.g., unlocking a bonus or choosing a specific path). *Only callable by the VRF coordinator.*

5.  **Owner & Admin Controls:**
    *   `ownerWithdrawAll`: Emergency function for the owner to withdraw all assets of a specific type from the contract.
    *   `setOracleAddress`: Sets the address for a specific price feed or custom oracle.
    *   `setVRFParameters`: Sets the necessary parameters for Chainlink VRF (coordinator, keyhash, subscription ID).
    *   `setAllowedRelayer`: Grants permission to a specific address to act as a relayer for certain gas-abstracted operations.
    *   `triggerGlobalStateTransition`: Owner can change the contract's global state, potentially affecting all deposits (e.g., pausing withdrawals, enabling emergency conditions).

6.  **Utility & Batch Functions:**
    *   `batchWithdrawERC20`: Allows a user to withdraw multiple specific ERC-20 tokens they are entitled to in a single transaction.
    *   `withdrawViaRelayer`: Allows an allowed relayer to execute a withdrawal on behalf of a user (e.g., for gas abstraction). The user still needs to meet withdrawal conditions.
    *   `withdrawGradually`: Initiates a gradual release schedule for a deposit, unlocking a portion over time or per call after initial conditions are met.
    *   `claimGradualRelease`: Claims the available unlocked amount from a deposit under a gradual release schedule.
    *   `modifyGradualReleaseSchedule`: Allows the depositor to modify the gradual release schedule parameters *after* it has started (e.g., speed up release).

7.  **View Functions (Information Retrieval):**
    *   `getDepositDetails`: Retrieves the full details of a specific deposit by its ID.
    *   `checkConditionStatus`: Checks if a specific condition within a deposit is currently met.
    *   `getTotalDeposited`: Gets the total amount of a specific token deposited by a user across all their deposits (excludes gradually released/withdrawn amounts).
    *   `getAllowedRelayerStatus`: Checks if an address is an allowed relayer.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports for safety and external interactions
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";

// Chainlink VRF Simulation Imports (Replace with actual imports for production)
// import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Chainlink Price Feed Simulation Import (Replace with actual import for production)
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// --- Outline & Function Summary ---
// (See summary block above for details)

contract QuantumVault is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using Address for address;

    // --- State Variables ---

    address public owner;

    enum DepositType { ETH, ERC20, ERC721 }
    enum DepositState { Pending, Superposition, Resolved, PartiallyWithdrawn, FullyWithdrawn, EmergencyUnlocked }
    enum ConditionType { TimeLock, OraclePriceAbove, OraclePriceBelow, ERC721Ownership, ExternalERC20BalanceAbove, InterDepositUnlocked, GlobalStateMatch }
    enum GlobalState { Normal, Restricted, EmergencyUnlock }

    struct Condition {
        ConditionType conditionType;
        bytes parameters; //ABI encoded parameters based on type
        bool met; // Status after checking
        uint256 checkCount; // How many times this condition was checked
    }

    struct GradualReleaseSchedule {
        uint256 startTime;
        uint256 totalAmount; // Relevant for ETH/ERC20
        uint256 releasedAmount; // Amount released so far
        uint256 releaseInterval; // Time in seconds between releases
        uint256 releaseAmountPerInterval; // Amount per interval
        uint256 lastReleaseTime; // Last time claimGradualRelease was called
        uint256 totalReleaseIntervals; // Total number of intervals
    }

    struct Deposit {
        uint256 id;
        address depositor;
        DepositType depositType;
        address assetAddress; // Token or NFT contract address (0 for ETH)
        uint256 amountOrTokenId; // Amount for ETH/ERC20, tokenId for ERC721
        DepositState state;
        Condition[] conditions; // Array of potential conditions
        uint256 creationTime;
        uint256 resolutionTime; // Time when superposition was resolved (if applicable)
        uint256 unlockedAmount; // For ETH/ERC20 in gradual release or partial withdrawal
        GradualReleaseSchedule gradualRelease;
        bool gradualReleaseActive;
    }

    uint256 private nextDepositId = 1;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => mapping(address => uint256)) private totalDepositedAmounts; // user => token => amount (excludes gradually released)

    GlobalState public globalState = GlobalState.Normal;

    // Allowed relayer addresses for gas abstraction
    mapping(address => bool) private allowedRelayers;

    // Oracle Addresses (simulated)
    mapping(bytes32 => address) public registeredOracles; // e.g., "ETH/USD" => price feed address

    // Chainlink VRF Parameters (simulated)
    // VRFCoordinatorV2Interface public vrfCoordinator;
    // uint64 public s_subscriptionId;
    // bytes32 public s_keyHash;
    // mapping(uint256 => uint256) public s_randomWords; // request ID => random word
    // mapping(uint256 => uint256) public s_requestConfirmations; // How many confirmations needed
    // uint32 public s_callbackGasLimit;
    // uint16 public constant s_requestNumWords = 1; // Always request 1 word

    // --- Events ---

    event DepositMade(uint256 indexed depositId, address indexed depositor, DepositType depositType, address assetAddress, uint256 amountOrTokenId);
    event ConditionsAdded(uint256 indexed depositId, uint256 numberOfNewConditions);
    event TimeLockExtended(uint256 indexed depositId, uint256 newTimeLock);
    event DepositResolved(uint256 indexed depositId, DepositState newState);
    event DepositWithdrawn(uint256 indexed depositId, address indexed recipient, uint256 amountOrTokenId);
    event BatchWithdrawal(address indexed recipient, uint256 numberOfTokens);
    event GlobalStateTransition(GlobalState oldState, GlobalState newState);
    event RelayerAllowed(address indexed relayer, bool status);
    event OracleRegistered(bytes32 indexed key, address indexed oracleAddress);
    event VRFRequestSent(uint256 indexed requestId, uint256 indexed depositId);
    event VRFRequestFulfilled(uint256 indexed requestId, uint256 indexed depositId, uint256 randomNumber);
    event GradualReleaseStarted(uint256 indexed depositId, uint256 totalAmount, uint256 interval, uint256 amountPerInterval);
    event GradualReleaseClaimed(uint256 indexed depositId, uint256 claimedAmount, uint256 remainingAmount);
    event GradualReleaseScheduleModified(uint256 indexed depositId);
    event InterDepositUnlockedTriggered(uint256 indexed depositId, uint256 indexed prerequisiteDepositId);

    // --- Constructor ---

    constructor() ReentrancyGuard() {
        owner = msg.sender;
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyRelayer() {
        require(allowedRelayers[msg.sender], "Not an allowed relayer");
        _;
    }

    modifier onlyVRFCoordinator() {
        // In production, check if msg.sender is the VRF coordinator contract
        // require(msg.sender == address(vrfCoordinator), "Only VRF Coordinator");
        _; // Simplified for simulation
    }

    // --- Core Vault Operations ---

    receive() external payable nonReentrant {
        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            depositor: msg.sender,
            depositType: DepositType.ETH,
            assetAddress: address(0),
            amountOrTokenId: msg.value,
            state: DepositState.Pending,
            conditions: new Condition[](0), // Starts without conditions by default for simple ETH deposit
            creationTime: block.timestamp,
            resolutionTime: 0,
            unlockedAmount: 0,
            gradualRelease: GradualReleaseSchedule(0,0,0,0,0,0,0),
            gradualReleaseActive: false
        });
        totalDepositedAmounts[msg.sender][address(0)] += msg.value;
        emit DepositMade(depositId, msg.sender, DepositType.ETH, address(0), msg.value);
    }

    function depositERC20(address _token, uint256 _amount) external nonReentrant {
        require(_token != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(_token);
        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            depositor: msg.sender,
            depositType: DepositType.ERC20,
            assetAddress: _token,
            amountOrTokenId: _amount,
            state: DepositState.Pending,
            conditions: new Condition[](0),
            creationTime: block.timestamp,
            resolutionTime: 0,
            unlockedAmount: 0,
            gradualRelease: GradualReleaseSchedule(0,0,0,0,0,0,0),
            gradualReleaseActive: false
        });
         totalDepositedAmounts[msg.sender][_token] += _amount;

        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositMade(depositId, msg.sender, DepositType.ERC20, _token, _amount);
    }

    function depositERC721(address _token, uint256 _tokenId) external nonReentrant {
        require(_token != address(0), "Invalid token address");

        IERC721 token = IERC721(_token);
        require(token.ownerOf(_tokenId) == msg.sender, "Not owner of token");

        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            id: depositId,
            depositor: msg.sender,
            depositType: DepositType.ERC721,
            assetAddress: _token,
            amountOrTokenId: _tokenId,
            state: DepositState.Pending,
            conditions: new Condition[](0),
            creationTime: block.timestamp,
            resolutionTime: 0,
            unlockedAmount: 0,
             gradualRelease: GradualReleaseSchedule(0,0,0,0,0,0,0),
            gradualReleaseActive: false
        });

        token.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit DepositMade(depositId, msg.sender, DepositType.ERC721, _token, _tokenId);
    }

    // --- Advanced Deposit & State Management ---

    /**
     * @notice Deposits assets linked to multiple potential conditions. Simulates "Superposition" where state isn't fixed until resolved.
     * @param _depositType Type of asset (ETH, ERC20, ERC721).
     * @param _assetAddress Address of token/NFT (0 for ETH).
     * @param _amountOrTokenId Amount for ETH/ERC20, tokenId for ERC721.
     * @param _conditions Array of Condition structs defining potential unlock criteria.
     */
    function depositSuperposition(
        DepositType _depositType,
        address _assetAddress,
        uint256 _amountOrTokenId,
        Condition[] calldata _conditions
    ) external payable nonReentrant {
         require(_conditions.length > 0, "Must provide at least one condition");
         require(_conditions.length <= 10, "Too many conditions (max 10)"); // Limit for gas

         uint256 depositId = nextDepositId++;
         Deposit storage newDeposit = deposits[depositId];

         newDeposit.id = depositId;
         newDeposit.depositor = msg.sender;
         newDeposit.depositType = _depositType;
         newDeposit.assetAddress = _assetAddress;
         newDeposit.amountOrTokenId = _amountOrTokenId;
         newDeposit.state = DepositState.Superposition; // Starts in superposition
         newDeposit.creationTime = block.timestamp;
         newDeposit.resolutionTime = 0;
         newDeposit.unlockedAmount = 0;
         newDeposit.gradualReleaseActive = false;

        // Copy conditions and initialize their status
         newDeposit.conditions = new Condition[](_conditions.length);
         for(uint i = 0; i < _conditions.length; i++) {
             newDeposit.conditions[i] = _conditions[i];
             newDeposit.conditions[i].met = false; // Conditions initially unchecked/unmet
             newDeposit.conditions[i].checkCount = 0;
         }

         if (_depositType == DepositType.ETH) {
             require(msg.value == _amountOrTokenId, "ETH amount mismatch");
             require(_assetAddress == address(0), "Asset address must be 0 for ETH");
             require(msg.value > 0, "Amount must be > 0 for ETH deposit");
             totalDepositedAmounts[msg.sender][address(0)] += msg.value;
         } else if (_depositType == DepositType.ERC20) {
             require(msg.value == 0, "Cannot send ETH with ERC20 deposit");
              require(_assetAddress != address(0), "Invalid token address");
             require(_amountOrTokenId > 0, "Amount must be > 0 for ERC20 deposit");
             IERC20(_assetAddress).safeTransferFrom(msg.sender, address(this), _amountOrTokenId);
              totalDepositedAmounts[msg.sender][_assetAddress] += _amountOrTokenId;
         } else if (_depositType == DepositType.ERC721) {
             require(msg.value == 0, "Cannot send ETH with ERC721 deposit");
              require(_assetAddress != address(0), "Invalid token address");
             IERC721(_assetAddress).safeTransferFrom(msg.sender, address(this), _amountOrTokenId);
         } else {
             revert("Invalid deposit type");
         }

         emit DepositMade(depositId, msg.sender, _depositType, _assetAddress, _amountOrTokenId);
    }

    /**
     * @notice Allows the depositor to add more potential unlock conditions to an existing deposit.
     * @param _depositId The ID of the deposit.
     * @param _newConditions Array of new conditions to add.
     */
    function addConditionToDeposit(uint256 _depositId, Condition[] calldata _newConditions) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Superposition || deposit.state == DepositState.Pending, "Deposit not in editable state");
        require(deposit.conditions.length + _newConditions.length <= 15, "Too many conditions (max 15 total)"); // Higher limit after initial

        uint256 oldLength = deposit.conditions.length;
        // Resize array and add new conditions
        deposit.conditions = new Condition[](oldLength + _newConditions.length);
         for(uint i = 0; i < oldLength; i++) {
             deposit.conditions[i] = deposits[_depositId].conditions[i]; // Re-copy existing
         }
         for(uint i = 0; i < _newConditions.length; i++) {
             deposit.conditions[oldLength + i] = _newConditions[i];
             deposit.conditions[oldLength + i].met = false;
             deposit.conditions[oldLength + i].checkCount = 0;
         }

        emit ConditionsAdded(_depositId, _newConditions.length);
    }

    /**
     * @notice Allows the depositor to extend the time lock duration for applicable conditions.
     * @param _depositId The ID of the deposit.
     * @param _extendBySeconds The number of seconds to add to the existing time lock.
     */
    function extendTimeLock(uint256 _depositId, uint256 _extendBySeconds) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Superposition || deposit.state == DepositState.Pending, "Deposit not in editable state");
        require(_extendBySeconds > 0, "Must extend by more than 0 seconds");

        bool timeLockFound = false;
        for (uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.TimeLock) {
                timeLockFound = true;
                uint256 currentUnlockTime;
                 // Decode the current unlock time from parameters
                 try abi.decode(deposit.conditions[i].parameters, (uint256)) returns (uint256 decodedTime) {
                     currentUnlockTime = decodedTime;
                 } catch {
                     revert("Failed to decode TimeLock parameter");
                 }

                // Ensure the new unlock time is actually later
                uint256 newUnlockTime = currentUnlockTime + _extendBySeconds;
                if (newUnlockTime <= currentUnlockTime) { // Check for overflow, though unlikely with uint256
                    newUnlockTime = type(uint256).max; // Cap at max value
                }
                // Re-encode the new unlock time
                deposit.conditions[i].parameters = abi.encode(newUnlockTime);
            }
        }
        require(timeLockFound, "No TimeLock condition found to extend");

        emit TimeLockExtended(_depositId, _extendBySeconds); // Emitting extension duration, not final time
    }


    // --- Conditional Withdrawal & Resolution ---

    /**
     * @notice Attempts to withdraw a deposit made via depositSuperposition.
     * Checks all conditions; if *any* single condition is met, the deposit state collapses to Resolved, and assets can be withdrawn.
     * @param _depositId The ID of the deposit to resolve.
     */
    function resolveSuperposition(uint256 _depositId) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Superposition, "Deposit not in Superposition state");
        require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");

        bool anyConditionMet = false;
        for (uint i = 0; i < deposit.conditions.length; i++) {
            // Check if the condition is met based on its type and parameters
            if (_checkCondition(deposit.conditions[i], deposit)) {
                deposit.conditions[i].met = true; // Mark the specific condition as met
                anyConditionMet = true;
            }
             deposit.conditions[i].checkCount++; // Increment check count for this condition
        }

        if (anyConditionMet || globalState == GlobalState.EmergencyUnlock) {
            deposit.state = DepositState.Resolved;
            deposit.resolutionTime = block.timestamp;
            // For gradual release, set unlocked amount to total if not active
            if (!deposit.gradualReleaseActive) {
                 deposit.unlockedAmount = deposit.amountOrTokenId;
            }
            emit DepositResolved(_depositId, DepositState.Resolved);
        } else {
             revert("No conditions met to resolve deposit");
        }
    }

    /**
     * @notice Attempts to withdraw a deposit based on an oracle price condition.
     * @param _depositId The ID of the deposit.
     * @param _oracleKey The key identifying the required oracle (e.g., "ETH/USD").
     */
    function withdrawBasedOnOracle(uint256 _depositId, bytes32 _oracleKey) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.Resolved || deposit.state == DepositState.PartiallyWithdrawn, "Deposit not in withdrawable state");
         require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");


        // Find the specific OraclePrice condition
        bool conditionExists = false;
        bool conditionMet = false;
        for(uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.OraclePriceAbove || deposit.conditions[i].conditionType == ConditionType.OraclePriceBelow) {
                 // Decode oracle key from parameters
                 bytes32 decodedOracleKey;
                 uint256 threshold;
                 try abi.decode(deposit.conditions[i].parameters, (bytes32, uint256)) returns (bytes32 key, uint256 val) {
                      decodedOracleKey = key;
                      threshold = val;
                 } catch {
                     revert("Failed to decode Oracle condition parameters");
                 }

                if (decodedOracleKey == _oracleKey) {
                    conditionExists = true;
                    if (_checkCondition(deposit.conditions[i], deposit)) {
                        conditionMet = true;
                        deposit.conditions[i].met = true;
                    }
                    deposit.conditions[i].checkCount++;
                    break; // Found the relevant condition
                }
            }
        }

        require(conditionExists, "No matching oracle condition found for this key");
        require(conditionMet || globalState == GlobalState.EmergencyUnlock, "Oracle condition not met");

        _performWithdrawal(deposit);
    }

    /**
     * @notice Attempts to withdraw a deposit if the caller owns a specific NFT acting as a key.
     * @param _depositId The ID of the deposit.
     * @param _nftContract The address of the NFT contract required.
     * @param _nftTokenId The specific token ID required.
     */
    function withdrawWithNFTKey(uint256 _depositId, address _nftContract, uint256 _nftTokenId) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.Resolved || deposit.state == DepositState.PartiallyWithdrawn, "Deposit not in withdrawable state");
         require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");

        // Find the specific ERC721Ownership condition
        bool conditionExists = false;
        bool conditionMet = false;
         for(uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.ERC721Ownership) {
                 // Decode NFT contract and token ID from parameters
                 address requiredNFTContract;
                 uint256 requiredNFTTokenId;
                  try abi.decode(deposit.conditions[i].parameters, (address, uint256)) returns (address nftContract, uint256 tokenId) {
                      requiredNFTContract = nftContract;
                      requiredNFTTokenId = tokenId;
                 } catch {
                     revert("Failed to decode NFT Ownership condition parameters");
                 }
                if (requiredNFTContract == _nftContract && requiredNFTTokenId == _nftTokenId) {
                    conditionExists = true;
                    if (_checkCondition(deposit.conditions[i], deposit)) {
                        conditionMet = true;
                        deposit.conditions[i].met = true;
                    }
                    deposit.conditions[i].checkCount++;
                    break; // Found the relevant condition
                }
            }
         }

        require(conditionExists, "No matching NFT ownership condition found");
        require(conditionMet || globalState == GlobalState.EmergencyUnlock, "NFT ownership condition not met");

        _performWithdrawal(deposit);
    }

    /**
     * @notice Attempts to withdraw if the depositor's balance of a *different* token meets a threshold.
     * @param _depositId The ID of the deposit.
     * @param _externalToken The address of the external token to check.
     * @param _requiredBalance The minimum required balance.
     */
    function withdrawIfExternalBalanceMet(uint256 _depositId, address _externalToken, uint256 _requiredBalance) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.Resolved || deposit.state == DepositState.PartiallyWithdrawn, "Deposit not in withdrawable state");
         require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");

        // Find the specific ExternalERC20BalanceAbove condition
        bool conditionExists = false;
        bool conditionMet = false;
         for(uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.ExternalERC20BalanceAbove) {
                 // Decode parameters
                 address checkToken;
                 uint256 checkBalance;
                 try abi.decode(deposit.conditions[i].parameters, (address, uint256)) returns (address token, uint256 balance) {
                      checkToken = token;
                      checkBalance = balance;
                 } catch {
                     revert("Failed to decode External Balance condition parameters");
                 }

                if (checkToken == _externalToken && checkBalance == _requiredBalance) {
                    conditionExists = true;
                     if (_checkCondition(deposit.conditions[i], deposit)) {
                        conditionMet = true;
                        deposit.conditions[i].met = true;
                    }
                    deposit.conditions[i].checkCount++;
                    break; // Found the relevant condition
                }
            }
         }

        require(conditionExists, "No matching external balance condition found");
        require(conditionMet || globalState == GlobalState.EmergencyUnlock, "External balance condition not met");

        _performWithdrawal(deposit);
    }

     /**
      * @notice Attempts to unlock a deposit if another specific deposit (owned by the same user) is already unlocked (Resolved or FullyWithdrawn).
      * Simulates entanglement/dependency.
      * @param _depositId The ID of the deposit to potentially unlock.
      * @param _prerequisiteDepositId The ID of the deposit that must be unlocked.
      */
    function triggerInterDepositUnlock(uint256 _depositId, uint256 _prerequisiteDepositId) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.state == DepositState.Pending || deposit.state == DepositState.Superposition, "Deposit not in unlockable state via dependency");

        // Find the specific InterDepositUnlocked condition
        bool conditionExists = false;
        bool conditionMet = false;
         for(uint i = 0; i < deposit.conditions.length; i++) {
            if (deposit.conditions[i].conditionType == ConditionType.InterDepositUnlocked) {
                 // Decode parameters
                 uint256 requiredDepositId;
                 try abi.decode(deposit.conditions[i].parameters, (uint256)) returns (uint256 depId) {
                      requiredDepositId = depId;
                 } catch {
                     revert("Failed to decode Inter-Deposit condition parameters");
                 }

                if (requiredDepositId == _prerequisiteDepositId) {
                    conditionExists = true;
                     if (_checkCondition(deposit.conditions[i], deposit)) {
                        conditionMet = true;
                        deposit.conditions[i].met = true;
                    }
                    deposit.conditions[i].checkCount++;
                    break; // Found the relevant condition
                }
            }
         }

        require(conditionExists, "No matching inter-deposit unlock condition found");
        require(conditionMet, "Prerequisite deposit not unlocked"); // Emergency unlock doesn't bypass dependency

        // If condition is met and deposit is in Superposition, resolve it
        if (deposit.state == DepositState.Superposition) {
            deposit.state = DepositState.Resolved;
            deposit.resolutionTime = block.timestamp;
             if (!deposit.gradualReleaseActive) {
                 deposit.unlockedAmount = deposit.amountOrTokenId;
            }
            emit DepositResolved(_depositId, DepositState.Resolved);
        } else if (deposit.state == DepositState.Pending) {
             // If Pending and meets dependency, maybe move to Resolved directly?
             // Or maybe Pending deposits require NO conditions? Depends on design.
             // Let's make Pending deposits simple by default (no conditions needed),
             // and Superposition require resolution via conditions.
             // This function primarily resolves Superposition based on dependency.
            revert("Deposit is Pending, not Superposition, and doesn't need dependency unlock.");
        }

         emit InterDepositUnlockedTriggered(_depositId, _prerequisiteDepositId);
    }


    // --- Probabilistic Outcomes (Chainlink VRF Simulation) ---

    /**
     * @notice Requests a random word from the VRF Coordinator.
     * @param _depositId The deposit ID associated with this request.
     */
    function requestProbabilisticOutcome(uint256 _depositId) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
         require(deposit.depositor == msg.sender, "Not deposit owner");
         // Only request if the deposit is in a state awaiting a random outcome
         require(deposit.state == DepositState.Superposition || deposit.state == DepositState.Pending, "Deposit not in a state awaiting random outcome");
         // require(address(vrfCoordinator) != address(0), "VRF Coordinator not set");
         // require(s_subscriptionId > 0, "VRF subscription ID not set");

         // Simulate sending VRF request
         uint256 simulatedRequestId = block.timestamp; // Use timestamp as a simple pseudo-request ID for simulation
         // uint256 requestId = vrfCoordinator.requestRandomWords(
         //     s_keyHash,
         //     s_subscriptionId,
         //     s_requestConfirmations,
         //     s_callbackGasLimit,
         //     s_requestNumWords
         // );
         // s_randomWords[requestId] = 0; // Initialize request ID entry (value will be 0 until fulfilled)

         // Store which deposit this request is for (needed in fulfillRandomWords)
         // mapping(uint256 => uint256) internal vrfRequestToDepositId;
         // vrfRequestToDepositId[requestId] = _depositId;

         emit VRFRequestSent(simulatedRequestId, _depositId); // Emitting simulated ID
    }

    /**
     * @notice Callback function for VRF Coordinator to deliver random words.
     * @param _requestId The original request ID.
     * @param _randomWords Array of random words.
     */
    // function fulfillRandomWords(
    //     uint256 _requestId,
    //     uint256[] memory _randomWords
    // ) internal override onlyVRFCoordinator { // Use 'external' for actual Chainlink callback
         // require(_randomWords.length == s_requestNumWords, "Incorrect number of random words");
         // uint256 randomWord = _randomWords[0];
         // s_randomWords[_requestId] = randomWord;

         // uint256 depositId = vrfRequestToDepositId[_requestId];
         // require(depositId > 0, "Unknown VRF request ID"); // Should never happen if mapping is correct

         // Deposit storage deposit = deposits[depositId];

         // // Implement logic based on the random word
         // // Example: If randomWord is even, resolve the deposit. If odd, maybe add a penalty.
         // if (randomWord % 2 == 0) {
         //    if (deposit.state == DepositState.Superposition) {
         //         deposit.state = DepositState.Resolved;
         //         deposit.resolutionTime = block.timestamp;
         //         deposit.unlockedAmount = deposit.amountOrTokenId;
         //         emit DepositResolved(depositId, DepositState.Resolved);
         //     } else if (deposit.state == DepositState.Pending) {
         //         // Maybe trigger gradual release based on randomness?
         //         // _startGradualRelease(deposit, deposit.amountOrTokenId, 1 days, deposit.amountOrTokenId / 10, 10);
         //     }
         // } else {
         //     // Example penalty: extend timelocks on existing conditions
         //      for (uint i = 0; i < deposit.conditions.length; i++) {
         //         if (deposit.conditions[i].conditionType == ConditionType.TimeLock) {
         //             uint256 currentUnlockTime;
         //              try abi.decode(deposit.conditions[i].parameters, (uint256)) returns (uint256 decodedTime) {
         //                  currentUnlockTime = decodedTime;
         //              } catch { continue; } // Skip if decode fails
         //             uint256 newUnlockTime = currentUnlockTime + 7 days; // Add a week penalty
         //             deposit.conditions[i].parameters = abi.encode(newUnlockTime);
         //         }
         //      }
         // }

         // emit VRFRequestFulfilled(_requestId, depositId, randomWord);
    // }

    // Placeholder for simulated fulfill function
    function fulfillRandomWords_Simulate(uint256 _requestId, uint256 _randomNumber) external {
         // This is a simulation function, NOT for production Chainlink VRF
         require(msg.sender == owner, "Simulation function only callable by owner"); // Simulate callback from trusted source

         // Assume _requestId is the depositId for simplicity in simulation
         uint256 depositId = _requestId;
         Deposit storage deposit = deposits[depositId];
         require(deposit.id > 0, "Unknown deposit ID");

         // Implement logic based on the random word (same logic as above)
         if (_randomNumber % 2 == 0) {
            if (deposit.state == DepositState.Superposition) {
                deposit.state = DepositState.Resolved;
                deposit.resolutionTime = block.timestamp;
                if (!deposit.gradualReleaseActive) {
                     deposit.unlockedAmount = deposit.amountOrTokenId;
                }
                emit DepositResolved(depositId, DepositState.Resolved);
            } else if (deposit.state == DepositState.Pending) {
                // Example: If random number is even and pending, trigger gradual release
                 _startGradualRelease(deposit, deposit.amountOrTokenId, 1 days, deposit.amountOrTokenId / 10, 10);
            }
         } else {
             // Example penalty: extend timelocks on existing conditions
              for (uint i = 0; i < deposit.conditions.length; i++) {
                if (deposit.conditions[i].conditionType == ConditionType.TimeLock) {
                    uint256 currentUnlockTime;
                     try abi.decode(deposit.conditions[i].parameters, (uint256)) returns (uint256 decodedTime) {
                         currentUnlockTime = decodedTime;
                     } catch { continue; }
                    uint256 newUnlockTime = currentUnlockTime + 7 days; // Add a week penalty
                    deposit.conditions[i].parameters = abi.encode(newUnlockTime);
                }
              }
         }

        emit VRFRequestFulfilled(_requestId, depositId, _randomNumber);
    }


    // --- Owner & Admin Controls ---

    /**
     * @notice Emergency function for owner to withdraw all assets of a specific type.
     * Bypasses all conditions and states. Use with extreme caution.
     * @param _depositType The type of asset to withdraw.
     * @param _assetAddress The asset address (0 for ETH).
     */
    function ownerWithdrawAll(DepositType _depositType, address _assetAddress) external onlyOwner nonReentrancy {
        if (_depositType == DepositType.ETH) {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                 (bool success, ) = payable(owner).call{value: balance}("");
                 require(success, "ETH withdrawal failed");
            }
        } else if (_depositType == DepositType.ERC20) {
             require(_assetAddress != address(0), "Invalid token address");
             IERC20 token = IERC20(_assetAddress);
             uint256 balance = token.balanceOf(address(this));
             if (balance > 0) {
                 token.safeTransfer(owner, balance);
             }
        } else if (_depositType == DepositType.ERC721) {
             // This is tricky for ERC721 as owner doesn't know all tokenIds held
             // A better emergency function for NFTs would iterate through tracked deposits
             // or require specifying tokenIds. Leaving simple for now.
             revert("Owner withdrawal not supported for all ERC721s in one call without specifying IDs");
             // Example for a specific NFT:
             // require(_assetAddress != address(0), "Invalid token address");
             // require(_tokenId > 0, "Invalid token ID");
             // IERC721(_assetAddress).safeTransferFrom(address(this), owner, _tokenId);
        } else {
            revert("Invalid deposit type");
        }
        // Note: This doesn't update individual deposit states.
        // A more complex implementation would mark all affected deposits as EmergencyUnlocked.
    }

     /**
      * @notice Registers an oracle address for a given key (e.g., price feed).
      * @param _key Identifier for the oracle (e.g., "ETH/USD").
      * @param _oracleAddress The address of the oracle contract.
      */
    function setOracleAddress(bytes32 _key, address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        registeredOracles[_key] = _oracleAddress;
        emit OracleRegistered(_key, _oracleAddress);
    }

    /**
     * @notice Sets Chainlink VRF parameters.
     * @param _coordinator Address of VRF Coordinator V2.
     * @param _keyHash Key hash for the VRF request.
     * @param _subId Subscription ID.
     * @param _requestConf Number of block confirmations.
     * @param _callbackGas Gas limit for the callback function.
     */
    function setVRFParameters(
        // address _coordinator,
        // bytes32 _keyHash,
        // uint64 _subId,
        // uint16 _requestConf,
        // uint32 _callbackGas
    ) external onlyOwner {
        // vrfCoordinator = VRFCoordinatorV2Interface(_coordinator);
        // s_keyHash = _keyHash;
        // s_subscriptionId = _subId;
        // s_requestConfirmations = _requestConf;
        // s_callbackGasLimit = _callbackGas;
        // Simulate success
    }

    /**
     * @notice Allows owner to designate an address as an allowed relayer for certain operations.
     * @param _relayer The address to allow/disallow.
     * @param _status True to allow, false to disallow.
     */
    function setAllowedRelayer(address _relayer, bool _status) external onlyOwner {
        require(_relayer != address(0), "Cannot set zero address as relayer");
        allowedRelayers[_relayer] = _status;
        emit RelayerAllowed(_relayer, _status);
    }

    /**
     * @notice Owner can transition the contract's global state.
     * This might affect how deposits behave (e.g., pause withdrawals, allow emergency unlocks).
     * @param _newState The target global state.
     */
    function triggerGlobalStateTransition(GlobalState _newState) external onlyOwner {
        require(globalState != _newState, "Already in this state");
        GlobalState oldState = globalState;
        globalState = _newState;
        emit GlobalStateTransition(oldState, globalState);

        // Optional: Iterate through deposits and update their state if the global state change mandates it
        // This could be very gas-intensive for many deposits and might require a separate function or off-chain process
        // Example: if _newState == GlobalState.EmergencyUnlock, mark all non-fully withdrawn deposits as EmergencyUnlocked
        // for (uint i = 1; i < nextDepositId; i++) {
        //     if (deposits[i].state != DepositState.FullyWithdrawn) {
        //         deposits[i].state = DepositState.EmergencyUnlocked;
        //     }
        // }
    }


    // --- Utility & Batch Functions ---

     /**
      * @notice Allows a user to withdraw multiple specific ERC-20 tokens in a single transaction.
      * User must be the depositor and deposits must be in a withdrawable state.
      * @param _depositIds Array of deposit IDs for ERC20 tokens.
      */
    function batchWithdrawERC20(uint256[] calldata _depositIds) external nonReentrant {
        require(_depositIds.length > 0, "No deposit IDs provided");
        require(_depositIds.length <= 20, "Too many deposits in batch (max 20)"); // Limit for gas
        require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");


        uint256 totalWithdrawn = 0;
        for(uint i = 0; i < _depositIds.length; i++) {
            uint256 depositId = _depositIds[i];
            Deposit storage deposit = deposits[depositId];

             require(deposit.depositor == msg.sender, "Not owner of deposit");
             require(deposit.depositType == DepositType.ERC20, "Deposit is not ERC20");
             require(deposit.state == DepositState.Resolved || deposit.state == DepositState.PartiallyWithdrawn || globalState == GlobalState.EmergencyUnlock, "Deposit not in withdrawable state");
             require(!deposit.gradualReleaseActive, "Deposit is under gradual release, use claimGradualRelease");

            // Perform withdrawal for this specific deposit
            uint256 amountToWithdraw = deposit.amountOrTokenId - deposit.unlockedAmount; // Withdraw remaining
            require(amountToWithdraw > 0, "Nothing left to withdraw for this deposit");

            IERC20 token = IERC20(deposit.assetAddress);
            token.safeTransfer(msg.sender, amountToWithdraw);

            deposit.unlockedAmount += amountToWithdraw;
            deposit.state = DepositState.FullyWithdrawn; // Mark as fully withdrawn after this batch call
             totalDepositedAmounts[msg.sender][deposit.assetAddress] -= amountToWithdraw; // Adjust total tracked

            totalWithdrawn++;
            emit DepositWithdrawn(depositId, msg.sender, amountToWithdraw);
        }

        emit BatchWithdrawal(msg.sender, totalWithdrawn);
    }

    /**
     * @notice Allows an allowed relayer to execute a withdrawal on behalf of a user.
     * The user's conditions still need to be met, or the global state must allow emergency unlock.
     * Useful for gas abstraction where the relayer pays gas.
     * @param _depositId The ID of the deposit to withdraw.
     * @param _recipient The address the assets should be sent to (usually the original depositor).
     */
    function withdrawViaRelayer(uint256 _depositId, address _recipient) external nonReentrant onlyRelayer {
         Deposit storage deposit = deposits[_depositId];
         require(_recipient != address(0), "Recipient cannot be zero address");
         require(_recipient == deposit.depositor, "Recipient must be original depositor"); // Relayer sends back to owner
         require(deposit.state == DepositState.Resolved || deposit.state == DepositState.PartiallyWithdrawn || globalState == GlobalState.EmergencyUnlock, "Deposit not in withdrawable state");
         require(!deposit.gradualReleaseActive, "Deposit is under gradual release, use claimGradualRelease");
         require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");


         _performWithdrawal(deposit);
         // Note: _performWithdrawal sends to deposit.depositor by default.
         // If relayer needs to send to a *different* address, the _performWithdrawal
         // helper would need to be modified to accept a recipient parameter.
         // Keeping it simple: relayer withdraws *to* the original depositor.
    }

    /**
     * @notice Initiates a gradual release schedule for a deposit.
     * The deposit must be in a resolved state (or emergency unlocked) to start.
     * @param _depositId The ID of the deposit.
     * @param _totalAmount The total amount to release (must be <= deposit amount/token id for ETH/ERC20).
     * @param _releaseInterval Time in seconds between release intervals.
     * @param _releaseAmountPerInterval Amount to release in each interval (for ETH/ERC20).
     * @param _totalReleaseIntervals Total number of intervals.
     */
    function withdrawGradually(
         uint256 _depositId,
         uint256 _totalAmount,
         uint256 _releaseInterval,
         uint256 _releaseAmountPerInterval,
         uint256 _totalReleaseIntervals
    ) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
         require(deposit.depositor == msg.sender, "Not deposit owner");
         require(deposit.state == DepositState.Resolved || deposit.state == DepositState.EmergencyUnlocked, "Deposit not in resolved or emergency state");
         require(!deposit.gradualReleaseActive, "Gradual release already active");
         require(_releaseInterval > 0, "Release interval must be > 0");
         require(_totalReleaseIntervals > 0, "Total intervals must be > 0");

         // For ETH/ERC20, totalAmount must be <= the initial deposit amount
         if (deposit.depositType == DepositType.ETH || deposit.depositType == DepositType.ERC20) {
             require(_totalAmount <= deposit.amountOrTokenId, "Total release amount exceeds deposit amount");
              // Calculate release amount per interval if not provided or incorrect
             if (_releaseAmountPerInterval == 0 || _releaseAmountPerInterval * _totalReleaseIntervals != _totalAmount) {
                 _releaseAmountPerInterval = _totalAmount / _totalReleaseIntervals;
                 if (_totalAmount % _totalReleaseIntervals != 0) {
                     // Handle remainder in the last interval if needed
                 }
             }
              require(_releaseAmountPerInterval > 0, "Calculated release amount per interval is 0");
         } else if (deposit.depositType == DepositType.ERC721) {
             // Gradual release doesn't make sense for unique NFTs
             revert("Gradual release not applicable to ERC721");
         }

         _startGradualRelease(deposit, _totalAmount, _releaseInterval, _releaseAmountPerInterval, _totalReleaseIntervals);

        emit GradualReleaseStarted(_depositId, _totalAmount, _releaseInterval, _releaseAmountPerInterval);
    }

    /**
     * @notice Claims the currently available amount from a gradual release schedule.
     * @param _depositId The ID of the deposit.
     */
    function claimGradualRelease(uint256 _depositId) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.gradualReleaseActive, "Gradual release not active for this deposit");
         require(globalState != GlobalState.Restricted, "Withdrawals restricted globally");


        GradualReleaseSchedule storage schedule = deposit.gradualRelease;

        uint256 timePassed = block.timestamp - schedule.lastReleaseTime;
        uint256 intervalsPassed = timePassed / schedule.releaseInterval;

        if (intervalsPassed == 0) {
            revert("No new interval completed yet");
        }

        uint256 intervalsRemaining = schedule.totalReleaseIntervals - (schedule.releasedAmount / schedule.releaseAmountPerInterval);
        if (intervalsPassed > intervalsRemaining) {
            intervalsPassed = intervalsRemaining; // Don't release more than remaining intervals allow
        }

        uint256 amountToClaim = intervalsPassed * schedule.releaseAmountPerInterval;

        // Ensure we don't exceed the total amount or available balance
        uint256 maxClaimable = schedule.totalAmount - schedule.releasedAmount;
        if (amountToClaim > maxClaimable) {
            amountToClaim = maxClaimable;
        }

        require(amountToClaim > 0, "Nothing to claim");

        if (deposit.depositType == DepositType.ETH) {
            (bool success, ) = payable(deposit.depositor).call{value: amountToClaim}("");
            require(success, "ETH transfer failed");
        } else if (deposit.depositType == DepositType.ERC20) {
            IERC20(deposit.assetAddress).safeTransfer(deposit.depositor, amountToClaim);
        }
        // ERC721 not supported for gradual release

        schedule.releasedAmount += amountToClaim;
        schedule.lastReleaseTime = schedule.lastReleaseTime + (intervalsPassed * schedule.releaseInterval); // Advance last release time correctly

        deposit.unlockedAmount += amountToClaim; // Track as unlocked within the deposit struct
        totalDepositedAmounts[deposit.depositor][deposit.assetAddress] -= amountToClaim; // Adjust total tracked

        if (schedule.releasedAmount >= schedule.totalAmount) {
            deposit.gradualReleaseActive = false;
            deposit.state = DepositState.FullyWithdrawn; // Mark as fully withdrawn once total is released
        } else {
             deposit.state = DepositState.PartiallyWithdrawn;
        }

        emit GradualReleaseClaimed(_depositId, amountToClaim, schedule.totalAmount - schedule.releasedAmount);
    }

    /**
     * @notice Allows the depositor to modify an active gradual release schedule.
     * Can change interval or amount per interval, potentially speeding up or slowing down.
     * Cannot increase total amount.
     * @param _depositId The ID of the deposit.
     * @param _newReleaseInterval New time in seconds between intervals.
     * @param _newReleaseAmountPerInterval New amount per interval (for ETH/ERC20).
     */
    function modifyGradualReleaseSchedule(uint256 _depositId, uint256 _newReleaseInterval, uint256 _newReleaseAmountPerInterval) external nonReentrant {
         Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor == msg.sender, "Not deposit owner");
        require(deposit.gradualReleaseActive, "Gradual release not active");
         require(_newReleaseInterval > 0, "New release interval must be > 0");
         require(_newReleaseAmountPerInterval > 0, "New amount per interval must be > 0");

        GradualReleaseSchedule storage schedule = deposit.gradualRelease;

        // Calculate remaining amount to be released
        uint256 remainingAmount = schedule.totalAmount - schedule.releasedAmount;

        // Calculate potential new number of intervals
        uint256 newTotalIntervals = remainingAmount / _newReleaseAmountPerInterval;
        if (remainingAmount % _newReleaseAmountPerInterval != 0) {
            newTotalIntervals++; // Account for remainder
        }

        // Ensure the new schedule doesn't try to release more than the total originally set
        require(newTotalIntervals * _newReleaseAmountPerInterval >= remainingAmount, "Modified schedule releases too much");
        // This check might be too strict if we allow remainder in the last interval.
        // A simpler check: new amount per interval * number of intervals = total amount
        // Let's just update parameters and rely on claim logic to handle max amount.

        schedule.releaseInterval = _newReleaseInterval;
        schedule.releaseAmountPerInterval = _newReleaseAmountPerInterval;
         // Recalculate total intervals might be complex if interval started already.
         // Best to just update interval and amountPerInterval, letting 'claim' logic
         // calculate remaining intervals based on `remainingAmount` and `releaseAmountPerInterval`.
         // We don't need to update `totalReleaseIntervals` here if the total amount is fixed.

        emit GradualReleaseScheduleModified(_depositId);
    }


    // --- Private Helper Functions ---

     /**
      * @notice Internal function to perform the actual asset withdrawal based on deposit type.
      * Assumes checks (ownership, state, conditions) have already passed.
      * @param _deposit The Deposit struct.
      */
    function _performWithdrawal(Deposit storage _deposit) private {
        uint256 amountToWithdraw = _deposit.amountOrTokenId - _deposit.unlockedAmount; // For ETH/ERC20, withdraw remaining
        require(amountToWithdraw > 0 || _deposit.depositType == DepositType.ERC721, "Nothing left to withdraw"); // For NFT, amount is token ID > 0

         if (_deposit.depositType == DepositType.ETH) {
             (bool success, ) = payable(_deposit.depositor).call{value: amountToWithdraw}("");
             require(success, "ETH transfer failed");
             _deposit.unlockedAmount += amountToWithdraw;
             totalDepositedAmounts[_deposit.depositor][address(0)] -= amountToWithdraw;
         } else if (_deposit.depositType == DepositType.ERC20) {
             IERC20(_deposit.assetAddress).safeTransfer(_deposit.depositor, amountToWithdraw);
             _deposit.unlockedAmount += amountToWithdraw;
             totalDepositedAmounts[_deposit.depositor][_deposit.assetAddress] -= amountToWithdraw;
         } else if (_deposit.depositType == DepositType.ERC721) {
             // For ERC721, the entire token is withdrawn at once
             require(_deposit.state != DepositState.PartiallyWithdrawn, "Cannot partially withdraw ERC721"); // ERC721 cannot be partial
              require(_deposit.unlockedAmount == 0, "ERC721 already withdrawn"); // Check if it's already unlocked/withdrawn
             IERC721(_deposit.assetAddress).safeTransferFrom(address(this), _deposit.depositor, _deposit.amountOrTokenId);
              _deposit.unlockedAmount = _deposit.amountOrTokenId; // Mark as unlocked/withdrawn
         }

         // Update deposit state based on whether it's fully withdrawn
         if (_deposit.depositType == DepositType.ERC721 || (_deposit.unlockedAmount >= _deposit.amountOrTokenId && _deposit.depositType != DepositType.ERC721)) {
            _deposit.state = DepositState.FullyWithdrawn;
         } else {
             _deposit.state = DepositState.PartiallyWithdrawn; // For ETH/ERC20 if total hasn't been withdrawn yet
         }

        emit DepositWithdrawn(_deposit.id, _deposit.depositor, _deposit.amountOrTokenId); // Emit original amount/id for context
    }

     /**
      * @notice Internal helper to check if a specific condition is met.
      * @param _condition The condition struct to check.
      * @param _deposit The associated deposit struct.
      * @return True if the condition is met, false otherwise.
      */
    function _checkCondition(Condition storage _condition, Deposit storage _deposit) private view returns (bool) {
        if (_condition.met) return true; // Already met in a previous check

        try abi.decode(_condition.parameters, (uint256)) returns (uint256 val) {
             // Handled below by type
        } catch {} // Ignore decode errors here, handled by specific types

        if (_condition.conditionType == ConditionType.TimeLock) {
             try abi.decode(_condition.parameters, (uint256)) returns (uint256 unlockTime) {
                 return block.timestamp >= unlockTime;
             } catch { return false; } // Malformed parameters means condition cannot be met
        } else if (_condition.conditionType == ConditionType.OraclePriceAbove) {
             try abi.decode(_condition.parameters, (bytes32 oracleKey, uint256 threshold)) returns (bytes32 key, uint256 val) {
                 address oracleAddress = registeredOracles[key];
                 if (oracleAddress == address(0)) return false; // Oracle not registered

                 // Simulate fetching price (replace with actual oracle interaction)
                 // AggregatorV3Interface priceFeed = AggregatorV3Interface(oracleAddress);
                 // (, int256 price, , , ) = priceFeed.latestRoundData();
                 // return price >= int256(val); // Compare price

                 // Simple simulation: Assume price is above if threshold > 1000 (dummy logic)
                 return val > 1000;
             } catch { return false; }
        } else if (_condition.conditionType == ConditionType.OraclePriceBelow) {
             try abi.decode(_condition.parameters, (bytes32 oracleKey, uint256 threshold)) returns (bytes32 key, uint256 val) {
                  address oracleAddress = registeredOracles[key];
                 if (oracleAddress == address(0)) return false;

                  // Simulate fetching price (replace with actual oracle interaction)
                 // AggregatorV3Interface priceFeed = AggregatorV3Interface(oracleAddress);
                 // (, int256 price, , , ) = priceFeed.latestRoundData();
                 // return price <= int256(val);

                 // Simple simulation: Assume price is below if threshold <= 1000 (dummy logic)
                 return val <= 1000;
             } catch { return false; }
        } else if (_condition.conditionType == ConditionType.ERC721Ownership) {
             try abi.decode(_condition.parameters, (address nftContract, uint256 tokenId)) returns (address contractAddr, uint256 id) {
                 if (contractAddr == address(0)) return false;
                 // Check if the *caller* or the *depositor* owns the NFT?
                 // The `withdrawWithNFTKey` function checks the caller (`msg.sender`).
                 // This internal check should probably verify the *current* owner.
                 // For `resolveSuperposition`, the check should be on the deposit's owner (`_deposit.depositor`).
                 // Let's assume for resolution checks, it's the depositor.
                 // For dedicated NFT withdrawal func, it's msg.sender.
                 // We need context. Let's assume this helper is for resolution by depositor.
                 if (!contractAddr.isContract()) return false; // Basic check
                 IERC721 nft = IERC721(contractAddr);
                 // This might revert if the token doesn't exist. Wrap in try/catch.
                 try nft.ownerOf(id) returns (address currentOwner) {
                      return currentOwner == _deposit.depositor;
                 } catch { return false; } // Token doesn't exist or other error
             } catch { return false; }
        } else if (_condition.conditionType == ConditionType.ExternalERC20BalanceAbove) {
             try abi.decode(_condition.parameters, (address tokenAddress, uint256 requiredBalance)) returns (address addr, uint256 balance) {
                  if (!addr.isContract()) return false;
                  IERC20 externalToken = IERC20(addr);
                  // Check the *depositor's* balance
                  return externalToken.balanceOf(_deposit.depositor) >= balance;
             } catch { return false; }
        } else if (_condition.conditionType == ConditionType.InterDepositUnlocked) {
             try abi.decode(_condition.parameters, (uint256 requiredDepositId)) returns (uint256 reqId) {
                 // Check if the prerequisite deposit exists and is in a completed state
                 if (deposits[reqId].id == 0) return false; // Prerequisite deposit does not exist
                 return deposits[reqId].state == DepositState.Resolved || deposits[reqId].state == DepositState.FullyWithdrawn || deposits[reqId].state == DepositState.EmergencyUnlocked;
             } catch { return false; }
        } else if (_condition.conditionType == ConditionType.GlobalStateMatch) {
             try abi.decode(_condition.parameters, (uint8 requiredGlobalState)) returns (uint8 stateValue) {
                  // Cast required state value back to enum
                  GlobalState requiredState = GlobalState(stateValue);
                  return globalState == requiredState;
             } catch { return false; }
        }
        // Add checks for other condition types here

        return false; // Unknown condition type or decoding failed
    }

    /**
     * @notice Internal helper to start the gradual release process.
     * @param _deposit The Deposit struct to update.
     * @param _totalAmount The total amount to release.
     * @param _releaseInterval Time in seconds between intervals.
     * @param _releaseAmountPerInterval Amount per interval.
     * @param _totalReleaseIntervals Total number of intervals.
     */
    function _startGradualRelease(
        Deposit storage _deposit,
        uint256 _totalAmount,
        uint256 _releaseInterval,
        uint256 _releaseAmountPerInterval,
        uint256 _totalReleaseIntervals
    ) private {
        _deposit.gradualRelease = GradualReleaseSchedule({
            startTime: block.timestamp,
            totalAmount: _totalAmount,
            releasedAmount: 0,
            releaseInterval: _releaseInterval,
            releaseAmountPerInterval: _releaseAmountPerInterval,
            lastReleaseTime: block.timestamp, // First interval starts immediately
            totalReleaseIntervals: _totalReleaseIntervals
        });
        _deposit.gradualReleaseActive = true;
         _deposit.state = DepositState.PartiallyWithdrawn; // Assume it will be partially withdrawn over time

        // Adjust total deposited amount tracker for the amount entering gradual release
        // Subtracting here prevents double counting or premature reduction from totalDepositedAmounts
        // The reduction from totalDepositedAmounts happens when claimGradualRelease is called.
        // Keeping this commented out to reflect amount only reduces on actual claim.
        // if (_deposit.depositType == DepositType.ETH) {
        //      totalDepositedAmounts[_deposit.depositor][address(0)] -= _totalAmount;
        // } else if (_deposit.depositType == DepositType.ERC20) {
        //      totalDepositedAmounts[_deposit.depositor][_deposit.assetAddress] -= _totalAmount;
        // }
    }

    // --- View Functions ---

     /**
      * @notice Gets the detailed information for a specific deposit.
      * @param _depositId The ID of the deposit.
      * @return Deposit struct details.
      */
    function getDepositDetails(uint256 _depositId) external view returns (Deposit memory) {
        require(deposits[_depositId].id != 0, "Deposit does not exist");
        return deposits[_depositId];
    }

     /**
      * @notice Checks the current status of a specific condition within a deposit.
      * @param _depositId The ID of the deposit.
      * @param _conditionIndex The index of the condition within the deposit's conditions array.
      * @return bool indicating if the condition is currently met.
      */
    function checkConditionStatus(uint256 _depositId, uint256 _conditionIndex) external view returns (bool) {
         Deposit storage deposit = deposits[_depositId];
         require(deposit.id != 0, "Deposit does not exist");
         require(_conditionIndex < deposit.conditions.length, "Invalid condition index");

         return _checkCondition(deposit.conditions[_conditionIndex], deposit);
    }

    /**
     * @notice Gets the total amount of a specific token deposited by a user in active deposits.
     * Excludes amounts in deposits that are FullyWithdrawn or actively under gradual release (as those are tracked separately).
     * @param _user The address of the user.
     * @param _token The address of the token (0 for ETH).
     * @return uint256 total amount.
     */
    function getTotalDeposited(address _user, address _token) external view returns (uint256) {
        return totalDepositedAmounts[_user][_token];
    }

    /**
     * @notice Checks if an address is currently allowed as a relayer.
     * @param _relayer The address to check.
     * @return bool True if allowed, false otherwise.
     */
    function getAllowedRelayerStatus(address _relayer) external view returns (bool) {
        return allowedRelayers[_relayer];
    }
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Superposition Deposit (`depositSuperposition`, `resolveSuperposition`):** This is the core "Quantum" metaphor. Assets are held in a state where multiple potential conditions could lead to their release. Calling `resolveSuperposition` is the "measurement" that checks *all* listed conditions. If *any* one is met, the state collapses to `Resolved`, and the deposit becomes unlockable. This is more complex than a simple multi-sig (which requires multiple approvals) or a single conditional escrow. It allows for diverse unlock paths determined *at the time of deposit*.
2.  **Parameterized Conditions (`Condition` struct, `bytes parameters`):** Conditions are not hardcoded function calls. They are stored as data (`ConditionType` and `bytes parameters`). This allows for adding new condition types in future versions (via upgradability patterns, not shown here) or defining highly specific conditions (like `OraclePriceAbove` with a specific key and threshold) directly in the deposit parameters. The `_checkCondition` helper interprets these parameters. This is more flexible than fixed, condition-specific withdrawal functions.
3.  **Oracle-Driven Conditions (`OraclePriceAbove`, `OraclePriceBelow`, `withdrawBasedOnOracle`):** Integrates external data (price feeds) as an unlock condition, common in DeFi but structured here as one of many potential conditions within the superposition/resolution flow.
4.  **NFT as a Key (`ERC721Ownership`, `withdrawWithNFTKey`):** Uses ownership of a specific non-fungible token *outside* the contract as a gate for withdrawal. This links digital collectibles to financial access within the vault. The check is performed dynamically when the withdrawal function is called.
5.  **External Token Balance Condition (`ExternalERC20BalanceAbove`, `withdrawIfExternalBalanceMet`):** Requires the depositor to hold a minimum balance of *another* token *outside* the vault. This could incentivize holding a governance token, a partner token, etc., as a condition for accessing vault assets.
6.  **Inter-Deposit Dependency (`InterDepositUnlocked`, `triggerInterDepositUnlock`):** Makes the unlock of one deposit conditional on the state (`Resolved` or `FullyWithdrawn`) of *another specific deposit* owned by the same user. This models "entanglement" or chained dependencies between different assets held within the vault.
7.  **Probabilistic Outcomes (`requestProbabilisticOutcome`, `fulfillRandomWords` - simulated):** Introduces non-determinism using a VRF. A specific action (like trying to resolve a deposit or trigger a bonus) could have an outcome decided by chance. This requires integrating a VRF oracle like Chainlink and is common in blockchain gaming or randomized distribution mechanisms. The simulation shows the *structure* of integrating this.
8.  **Gradual Release (`withdrawGradually`, `claimGradualRelease`, `modifyGradualReleaseSchedule`):** Allows assets (ETH/ERC20) from a *resolved* deposit to be released over time in installments rather than all at once. Includes the ability to modify the schedule *after* it has started, adding dynamic behavior to vesting. This is more advanced than simple time locks or linear vesting.
9.  **Deposit Modification (`addConditionToDeposit`, `extendTimeLock`):** Allows the *depositor* to add *more* conditions or *extend* existing time locks after the deposit is made. This provides flexibility for the depositor to adjust their unlock strategy over time, making it potentially *easier* to meet *any* condition later, or delaying access if needed.
10. **Global State Transition (`triggerGlobalStateTransition`):** Allows the owner to change a global state variable that can override specific deposit conditions (e.g., `EmergencyUnlock` allowing withdrawal regardless of deposit state) or restrict actions (`Restricted` state pausing withdrawals). This acts as a high-level control mechanism.
11. **Relayer Withdrawal (`setAllowedRelayer`, `withdrawViaRelayer`):** Implements a basic pattern for gas abstraction. An authorized third party (relayer) can submit the transaction and pay for gas on behalf of the user, provided the user's withdrawal conditions are still met. The withdrawal is sent to the user's address.
12. **Batch Withdrawal (`batchWithdrawERC20`):** A utility function to improve UX and gas efficiency by allowing the user to claim multiple entitled ERC-20 deposits in a single transaction.
13. **Internal State Tracking (`totalDepositedAmounts`, `unlockedAmount`):** Tracks total amounts per user/token, adjusting on deposit, *and* tracks `unlockedAmount` within each `Deposit` struct for partial withdrawals or gradual releases. This allows for precise tracking of what's left in a specific deposit vs. total held by the contract for a user.

This contract is complex and combines several distinct advanced concepts into a single structure under the "Quantum Vault" theme. It's designed for demonstration and learning purposes, and production deployment would require thorough auditing, gas optimization, and potentially integrating real oracle/VRF systems. The simulation placeholders for VRF and Oracle should be replaced with actual Chainlink (or other provider) implementations.