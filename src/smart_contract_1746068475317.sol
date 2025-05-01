Okay, here is a smart contract concept called "QuantumVault". The idea is a secure vault that holds various assets (ETH, ERC20, ERC721) and releases them only when a set of potentially complex and data-driven "quantum" conditions are met. The "quantum" aspect is metaphorical, referring to the non-obvious and potentially unpredictable outcome based on the confluence of external data and internal state, rather than actual quantum computation.

It incorporates:
*   Multi-asset support.
*   Configurable release conditions (time-based, external signal via oracle manager, internal state).
*   State management (Locked, Conditions Met, Emergency).
*   Role-based access (Owner, Condition Manager, Beneficiaries, Depositors).
*   Emergency shutdown mechanism.
*   Tracking initial deposits for emergency recovery.

This design aims to be creative by combining conditional logic based on external signals with multi-asset storage and state transitions, going beyond a simple time-lock or multi-sig vault.

---

**Contract Name:** `QuantumVault`

**Purpose:** A secure smart contract vault designed to hold ETH, ERC20, and ERC721 tokens. Assets are locked until a predefined set of conditions are met, or until an emergency shutdown is triggered. The release conditions can be based on time, external data signals (verified by a designated Condition Manager), or internal contract state.

**Outline:**

1.  **State Variables:** Define essential contract state (owner, beneficiaries, balances, conditions, state machine, etc.).
2.  **Enums:** Define possible vault states and condition types.
3.  **Structs:** Define structure for release conditions and perhaps deposit tracking.
4.  **Events:** Define events for transparency and off-chain monitoring.
5.  **Modifiers:** Define access control modifiers.
6.  **Libraries:** Import necessary libraries (SafeERC20, ReentrancyGuard, Ownable - standard OpenZeppelin).
7.  **Core Logic:**
    *   **Constructor:** Initialize contract owner.
    *   **Admin Functions:** Functions for owner/admin to configure the vault (beneficiaries, condition manager, emergency states).
    *   **Deposit Functions:** Functions for users to deposit different asset types. Track initial deposits for emergency withdrawal.
    *   **Condition Management:** Functions to define and manage release conditions. Function for the Condition Manager to signal external conditions are met. Internal function to check condition status.
    *   **State Management:** Logic to transition between vault states based on conditions or emergency signals.
    *   **Withdrawal Functions:** Functions for beneficiaries to withdraw assets once conditions are met. Function for depositors to withdraw their initial deposit in an emergency.
    *   **Query Functions:** View functions to check contract state, balances, conditions, etc.

**Function Summary:**

*   **`constructor()`:** Initializes the contract setting the deployer as the owner.
*   **`transferOwnership(address newOwner)`:** Transfers contract ownership (Owner only).
*   **`addBeneficiary(address _beneficiary)`:** Adds an address to the list of beneficiaries who can withdraw assets when conditions are met (Owner only).
*   **`removeBeneficiary(address _beneficiary)`:** Removes an address from the beneficiary list (Owner only).
*   **`setConditionManager(address _conditionManager)`:** Sets the address authorized to signal external conditions (Owner only).
*   **`configureReleaseCondition(uint256 _conditionId, ConditionType _type, bytes memory _params)`:** Defines or updates a specific release condition using a unique ID and parameters based on the type (Owner only).
*   **`removeReleaseCondition(uint256 _conditionId)`:** Removes a previously configured condition (Owner only).
*   **`signalConditionalMet(uint256 _conditionId)`:** Called by the Condition Manager to signal that a specific external condition (_type == TYPE_EXTERNAL_SIGNAL) has been met. Checks if all conditions are now met and updates state.
*   **`emergencyShutdown()`:** Initiates an emergency shutdown state, potentially after a delay, allowing initial depositors to withdraw their assets (Owner only).
*   **`cancelEmergencyShutdown()`:** Cancels the emergency shutdown state if not past the activation delay (Owner only).
*   **`depositETH()`:** Allows anyone to deposit native ETH into the vault. Records the initial deposit amount for the depositor.
*   **`depositERC20(IERC20 _token, uint256 _amount)`:** Allows anyone to deposit a specified amount of an ERC20 token. Requires prior approval. Records the initial deposit amount for the depositor (using SafeERC20).
*   **`depositERC721(IERC721 _token, uint256 _tokenId)`:** Allows anyone to deposit a specific ERC721 token. Requires prior approval or `setApprovalForAll`. Records the initial deposit of this specific token ID by the depositor.
*   **`withdrawETH(uint256 _amount)`:** Allows a beneficiary to withdraw a specified amount of ETH if the vault is in `ConditionsMet` state.
*   **`withdrawERC20(IERC20 _token, uint256 _amount)`:** Allows a beneficiary to withdraw a specified amount of an ERC20 token if the vault is in `ConditionsMet` state (using SafeERC20).
*   **`withdrawERC721(IERC721 _token, uint256 _tokenId)`:** Allows a beneficiary to withdraw a specific ERC721 token if the vault is in `ConditionsMet` state.
*   **`withdrawERC721Batch(IERC721 _token, uint256[] memory _tokenIds)`:** Allows a beneficiary to withdraw multiple ERC721 tokens of the same type in one transaction if the vault is in `ConditionsMet` state.
*   **`withdrawInEmergencyETH(uint256 _amount)`:** Allows an original depositor to withdraw up to their initial deposited ETH amount during the `EmergencyShutdown` state (after activation delay).
*   **`withdrawInEmergencyERC20(IERC20 _token, uint256 _amount)`:** Allows an original depositor to withdraw up to their initial deposited ERC20 amount for a specific token during the `EmergencyShutdown` state (after activation delay).
*   **`withdrawInEmergencyERC721(IERC721 _token, uint256 _tokenId)`:** Allows an original depositor to withdraw a specific ERC721 token they initially deposited during the `EmergencyShutdown` state (after activation delay).
*   **`checkConditionStatus(uint256 _conditionId)`:** View function to check if a specific configured condition has been met.
*   **`checkAllConditionsMet()`:** View function to check if all currently configured conditions are met.
*   **`getTotalDepositedETH()`:** View function to get the total balance of ETH held in the vault.
*   **`getTotalDepositedERC20(IERC20 _token)`:** View function to get the total balance of a specific ERC20 token held in the vault.
*   **`getTotalDepositedERC721Count(IERC721 _token)`:** View function to get the total count of a specific ERC721 token type held in the vault.
*   **`getBeneficiaries()`:** View function to get the list of beneficiary addresses.
*   **`getConditions()`:** View function to get details of all configured conditions.
*   **`getVaultState()`:** View function to get the current state of the vault.

Total Functions: 28 (Excluding internal helper functions) - This meets the requirement of at least 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title QuantumVault
/// @author [Your Name/Alias]
/// @notice A secure smart contract vault for ETH, ERC20, and ERC721 tokens.
/// Assets are released only upon meeting configurable, potentially data-driven conditions,
/// or via an emergency shutdown mechanism allowing initial depositors to reclaim.

// Outline:
// 1. State Variables: owner, conditionManager, beneficiaries, vault state, balances, conditions, emergency state
// 2. Enums: VaultState, ConditionType
// 3. Structs: ReleaseCondition
// 4. Events: Deposit, Withdrawal, ConditionConfigured, ConditionMet, StateChange, EmergencyShutdown, CancelEmergencyShutdown
// 5. Modifiers: onlyConditionManager, onlyBeneficiary
// 6. Libraries: SafeERC20, ReentrancyGuard, Ownable, EnumerableSet
// 7. Core Logic:
//    - Constructor
//    - Admin Functions (Ownerable overrides, setConditionManager, add/removeBeneficiary, configure/removeCondition, emergencyShutdown, cancelEmergencyShutdown)
//    - Deposit Functions (depositETH, depositERC20, depositERC721) - Track initial deposits
//    - Condition Management (_checkCondition, signalConditionalMet, checkConditionStatus, checkAllConditionsMet)
//    - Withdrawal Functions (withdrawETH, withdrawERC20, withdrawERC721, withdrawERC721Batch) - Conditional withdrawal
//    - Emergency Withdrawal Functions (withdrawInEmergencyETH, withdrawInEmergencyERC20, withdrawInEmergencyERC721) - Emergency recovery
//    - Query Functions (getTotalDeposited*, getBeneficiaries, getConditions, getConditionStatus, getVaultState)

contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet; // For tracking NFT token IDs

    // --- State Variables ---

    /// @dev Address authorized to signal external conditions met.
    address public conditionManager;

    /// @dev Set of addresses allowed to withdraw assets once conditions are met.
    EnumerableSet.AddressSet private beneficiaries;

    /// @dev Current state of the vault.
    VaultState public vaultState;

    /// @dev Mapping to track deposited ETH total.
    uint256 private totalDepositedETH;
    /// @dev Mapping to track deposited ERC20 totals per token address.
    mapping(address => uint256) private totalDepositedERC20;
    /// @dev Mapping to track deposited ERC721 token IDs per token address.
    mapping(address => EnumerableSet.UintSet) private totalDepositedERC721;

    // --- Initial Deposit Tracking for Emergency Recovery ---
    /// @dev Tracks initial ETH deposit amounts per depositor.
    mapping(address => uint256) private initialETHDeposits;
    /// @dev Tracks initial ERC20 deposit amounts per depositor and token address.
    mapping(address => mapping(address => uint256)) private initialERC20Deposits;
    /// @dev Tracks initial ERC721 token IDs deposited per depositor and token address.
    mapping(address => mapping(address => EnumerableSet.UintSet)) private initialERC721Deposits;

    // --- Condition Management ---
    /// @dev Unique counter for condition IDs.
    uint256 private conditionCounter;
    /// @dev Mapping from condition ID to the condition configuration.
    mapping(uint256 => ReleaseCondition) private releaseConditions;
    /// @dev Mapping from condition ID to its current met status.
    mapping(uint256 => bool) private conditionMetStatus;
    /// @dev Set of all configured condition IDs.
    EnumerableSet.UintSet private configuredConditionIds;

    // --- Emergency State ---
    /// @dev Timestamp when emergency shutdown can be fully activated (after a delay).
    uint256 public emergencyActivationTime;
    /// @dev Delay period before emergency shutdown becomes active (e.g., 2 days).
    uint256 public constant EMERGENCY_ACTIVATION_DELAY = 2 days; // Example delay

    // --- Enums ---

    /// @dev Possible states of the Quantum Vault.
    enum VaultState {
        Locked,           // Assets are locked, waiting for conditions
        ConditionsMet,    // All conditions are met, beneficiaries can withdraw
        EmergencyShutdown // Emergency triggered, initial depositors can reclaim
    }

    /// @dev Types of conditions that can be configured.
    enum ConditionType {
        TYPE_TIME_UNIX,           // Release after a specific Unix timestamp
        TYPE_EXTERNAL_SIGNAL,     // Requires a signal from the Condition Manager
        TYPE_TOTAL_ETH_DEPOSITED_ABOVE, // Total ETH in vault exceeds a threshold
        TYPE_TOTAL_ERC20_DEPOSITED_ABOVE // Total ERC20 of specific token exceeds a threshold
        // Add more types as needed (e.g., Oracle price feeds, DAO votes, etc.)
    }

    // --- Structs ---

    /// @dev Structure defining a release condition.
    struct ReleaseCondition {
        ConditionType conditionType;
        bytes params; // Flexible parameter encoding based on condition type
        bool configured; // True if this ID is actively configured
    }

    // --- Events ---

    /// @dev Emitted when native ETH is deposited.
    event ETHDeposited(address indexed depositor, uint256 amount);
    /// @dev Emitted when an ERC20 token is deposited.
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    /// @dev Emitted when an ERC721 token is deposited.
    event ERC721Deposited(address indexed depositor, address indexed token, uint256 tokenId);
    /// @dev Emitted when native ETH is withdrawn.
    event ETHWithdrawn(address indexed recipient, uint256 amount);
    /// @dev Emitted when an ERC20 token is withdrawn.
    event ERC20Withdrawn(address indexed recipient, address indexed token, uint256 amount);
    /// @dev Emitted when an ERC721 token is withdrawn.
    event ERC721Withdrawn(address indexed recipient, address indexed token, uint256 tokenId);
     /// @dev Emitted when an ERC721 batch is withdrawn.
    event ERC721BatchWithdrawn(address indexed recipient, address indexed token, uint256[] tokenIds);
    /// @dev Emitted when a beneficiary is added.
    event BeneficiaryAdded(address indexed beneficiary);
    /// @dev Emitted when a beneficiary is removed.
    event BeneficiaryRemoved(address indexed beneficiary);
    /// @dev Emitted when the condition manager is set.
    event ConditionManagerSet(address indexed conditionManager);
    /// @dev Emitted when a release condition is configured.
    event ConditionConfigured(uint256 indexed conditionId, ConditionType conditionType, bytes params);
    /// @dev Emitted when a release condition is removed.
    event ConditionRemoved(uint256 indexed conditionId);
    /// @dev Emitted when a specific condition is signaled as met.
    event ConditionSignaledMet(uint256 indexed conditionId, bool allConditionsNowMet);
    /// @dev Emitted when the vault state changes.
    event VaultStateChanged(VaultState oldState, VaultState newState);
    /// @dev Emitted when emergency shutdown is triggered.
    event EmergencyShutdownTriggered(uint256 activationTime);
    /// @dev Emitted when emergency shutdown is canceled.
    event EmergencyShutdownCanceled();

    // --- Modifiers ---

    /// @dev Modifier to restrict access to the condition manager.
    modifier onlyConditionManager() {
        require(msg.sender == conditionManager, "QV: Not condition manager");
        _;
    }

    /// @dev Modifier to restrict access to beneficiaries.
    modifier onlyBeneficiary() {
        require(beneficiaries.contains(msg.sender), "QV: Not a beneficiary");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        vaultState = VaultState.Locked;
        emit VaultStateChanged(VaultState.Locked, VaultState.Locked);
    }

    // --- Admin Functions ---

    /// @dev See {Ownable-transferOwnership}.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @dev Sets the address authorized to signal external conditions.
    /// @param _conditionManager The address of the new condition manager.
    function setConditionManager(address _conditionManager) public onlyOwner {
        require(_conditionManager != address(0), "QV: Zero address not allowed");
        conditionManager = _conditionManager;
        emit ConditionManagerSet(_conditionManager);
    }

    /// @dev Adds an address to the list of beneficiaries.
    /// @param _beneficiary The address to add.
    function addBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "QV: Zero address not allowed");
        require(beneficiaries.add(_beneficiary), "QV: Already a beneficiary");
        emit BeneficiaryAdded(_beneficiary);
    }

    /// @dev Removes an address from the list of beneficiaries.
    /// @param _beneficiary The address to remove.
    function removeBeneficiary(address _beneficiary) public onlyOwner {
        require(beneficiaries.remove(_beneficiary), "QV: Not a beneficiary");
        emit BeneficiaryRemoved(_beneficiary);
    }

    /// @dev Configures or updates a release condition.
    /// Uses a unique ID to identify the condition. Use `bytes` for flexible parameters.
    /// Example params for TYPE_TIME_UNIX: `abi.encode(uint256(unixTimestamp))`
    /// Example params for TYPE_TOTAL_ETH_DEPOSITED_ABOVE: `abi.encode(uint256(thresholdAmount))`
    /// Example params for TYPE_TOTAL_ERC20_DEPOSITED_ABOVE: `abi.encode(address(tokenAddress), uint256(thresholdAmount))`
    /// @param _conditionId The ID of the condition to configure/update.
    /// @param _type The type of the condition.
    /// @param _params The parameters for the condition based on its type.
    function configureReleaseCondition(uint256 _conditionId, ConditionType _type, bytes memory _params) public onlyOwner {
        require(_conditionId > 0, "QV: Condition ID must be positive");
        releaseConditions[_conditionId] = ReleaseCondition(_type, _params, true);
        configuredConditionIds.add(_conditionId);
        conditionMetStatus[_conditionId] = false; // Reset status on configuration/update
        emit ConditionConfigured(_conditionId, _type, _params);
    }

     /// @dev Removes a previously configured condition.
     /// @param _conditionId The ID of the condition to remove.
    function removeReleaseCondition(uint256 _conditionId) public onlyOwner {
        require(releaseConditions[_conditionId].configured, "QV: Condition not configured");
        delete releaseConditions[_conditionId];
        delete conditionMetStatus[_conditionId]; // Also remove met status
        configuredConditionIds.remove(_conditionId);
        emit ConditionRemoved(_conditionId);

        // If we removed a condition, re-check if all *remaining* conditions are met
        if (vaultState == VaultState.Locked && configuredConditionIds.length() > 0) {
             if (checkAllConditionsMet()) {
                VaultState oldState = vaultState;
                vaultState = VaultState.ConditionsMet;
                emit VaultStateChanged(oldState, vaultState);
            }
        }
    }

    /// @dev Triggers the emergency shutdown process. Assets can be reclaimed by original
    /// depositors after a delay specified by `EMERGENCY_ACTIVATION_DELAY`.
    function emergencyShutdown() public onlyOwner {
        require(vaultState != VaultState.EmergencyShutdown, "QV: Already in emergency");
        VaultState oldState = vaultState;
        vaultState = VaultState.EmergencyShutdown;
        emergencyActivationTime = block.timestamp + EMERGENCY_ACTIVATION_DELAY;
        emit VaultStateChanged(oldState, vaultState);
        emit EmergencyShutdownTriggered(emergencyActivationTime);
    }

    /// @dev Cancels the emergency shutdown process if it hasn't been fully activated yet.
    function cancelEmergencyShutdown() public onlyOwner {
        require(vaultState == VaultState.EmergencyShutdown, "QV: Not in emergency");
        require(block.timestamp < emergencyActivationTime, "QV: Emergency already active");
        VaultState oldState = vaultState;
        vaultState = VaultState.Locked;
        emergencyActivationTime = 0; // Reset activation time
        emit VaultStateChanged(oldState, vaultState);
        emit EmergencyShutdownCanceled();
    }

    // --- Deposit Functions ---

    /// @dev Deposits native ETH into the vault.
    receive() external payable nonReentrant {
        depositETH();
    }

    /// @dev Deposits native ETH into the vault.
    function depositETH() public payable nonReentrant {
        require(msg.value > 0, "QV: ETH amount must be > 0");
        require(vaultState == VaultState.Locked, "QV: Vault not in Locked state");

        initialETHDeposits[msg.sender] += msg.value;
        totalDepositedETH += msg.value;

        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @dev Deposits ERC20 tokens into the vault.
    /// Requires the sender to have approved this contract beforehand.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of tokens to deposit.
    function depositERC20(IERC20 _token, uint256 _amount) public nonReentrant {
        require(_amount > 0, "QV: Amount must be > 0");
        require(vaultState == VaultState.Locked, "QV: Vault not in Locked state");

        _token.safeTransferFrom(msg.sender, address(this), _amount);

        initialERC20Deposits[msg.sender][address(_token)] += _amount;
        totalDepositedERC20[address(_token)] += _amount;

        emit ERC20Deposited(msg.sender, address(_token), _amount);
    }

    /// @dev Deposits an ERC721 token into the vault.
    /// Requires the sender to have approved this contract or setApprovalForAll beforehand.
    /// @param _token The address of the ERC721 token contract.
    /// @param _tokenId The ID of the token to deposit.
    function depositERC721(IERC721 _token, uint256 _tokenId) public nonReentrant {
         require(vaultState == VaultState.Locked, "QV: Vault not in Locked state");

        // Check ownership before transferFrom (safer, though transferFrom also checks)
        require(_token.ownerOf(_tokenId) == msg.sender, "QV: Caller does not own token");

        _token.transferFrom(msg.sender, address(this), _tokenId);

        // Track initial deposit of this specific NFT by this depositor
        initialERC721Deposits[msg.sender][address(_token)].add(_tokenId);
        totalDepositedERC721[address(_token)].add(_tokenId);

        emit ERC721Deposited(msg.sender, address(_token), _tokenId);
    }


    // --- Condition Management ---

    /// @dev Internal function to check if a specific condition is met based on its type and parameters.
    /// @param _conditionId The ID of the condition to check.
    /// @return bool True if the condition is met.
    function _checkCondition(uint256 _conditionId) internal view returns (bool) {
        ReleaseCondition storage condition = releaseConditions[_conditionId];
        require(condition.configured, "QV: Condition not configured");

        if (condition.conditionType == ConditionType.TYPE_TIME_UNIX) {
            uint256 requiredTimestamp = abi.decode(condition.params, (uint256));
            return block.timestamp >= requiredTimestamp;
        } else if (condition.conditionType == ConditionType.TYPE_EXTERNAL_SIGNAL) {
            // Status is updated via signalConditionalMet
            return conditionMetStatus[_conditionId];
        } else if (condition.conditionType == ConditionType.TYPE_TOTAL_ETH_DEPOSITED_ABOVE) {
             uint256 threshold = abi.decode(condition.params, (uint256));
             return totalDepositedETH >= threshold;
        } else if (condition.conditionType == ConditionType.TYPE_TOTAL_ERC20_DEPOSITED_ABOVE) {
             (address tokenAddress, uint256 threshold) = abi.decode(condition.params, (address, uint256));
             return totalDepositedERC20[tokenAddress] >= threshold;
        }
        // Add checks for other ConditionTypes here
        return false; // Default to false if type is unknown or not met
    }

    /// @dev Called by the Condition Manager to signal that a specific external condition is met.
    /// This function updates the internal status for `TYPE_EXTERNAL_SIGNAL` conditions.
    /// After updating, it checks if *all* configured conditions are now met.
    /// @param _conditionId The ID of the external condition that is now met.
    function signalConditionalMet(uint256 _conditionId) public onlyConditionManager {
        ReleaseCondition storage condition = releaseConditions[_conditionId];
        require(condition.configured, "QV: Condition not configured");
        require(condition.conditionType == ConditionType.TYPE_EXTERNAL_SIGNAL, "QV: Not an external signal condition");
        require(!conditionMetStatus[_conditionId], "QV: Condition already signaled as met");
        require(vaultState == VaultState.Locked, "QV: Vault not in Locked state");

        conditionMetStatus[_conditionId] = true;
        bool allMet = checkAllConditionsMet();
        emit ConditionSignaledMet(_conditionId, allMet);

        if (allMet) {
            VaultState oldState = vaultState;
            vaultState = VaultState.ConditionsMet;
            emit VaultStateChanged(oldState, vaultState);
        }
    }

    /// @dev Checks if a specific configured condition is currently met.
    /// @param _conditionId The ID of the condition to check.
    /// @return bool True if the condition is met, false otherwise.
    function checkConditionStatus(uint256 _conditionId) public view returns (bool) {
         require(releaseConditions[_conditionId].configured, "QV: Condition not configured");
         return _checkCondition(_conditionId);
    }

    /// @dev Checks if *all* currently configured conditions are met.
    /// This determines if the vault transitions to `ConditionsMet` state.
    /// @return bool True if all configured conditions are met, false otherwise.
    function checkAllConditionsMet() public view returns (bool) {
        uint256[] memory conditionIds = configuredConditionIds.values();
        if (conditionIds.length == 0) {
            return false; // Cannot transition if no conditions are set
        }
        for (uint256 i = 0; i < conditionIds.length; i++) {
            if (!_checkCondition(conditionIds[i])) {
                return false; // At least one condition is not met
            }
        }
        return true; // All configured conditions are met
    }


    // --- Withdrawal Functions (Conditional) ---

    /// @dev Allows a beneficiary to withdraw ETH once conditions are met.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _amount) public nonReentrant onlyBeneficiary {
        require(_amount > 0, "QV: Amount must be > 0");
        require(vaultState == VaultState.ConditionsMet, "QV: Vault not in ConditionsMet state");
        require(totalDepositedETH >= _amount, "QV: Insufficient ETH balance in vault");

        totalDepositedETH -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "QV: ETH withdrawal failed");

        emit ETHWithdrawn(msg.sender, _amount);
    }

    /// @dev Allows a beneficiary to withdraw ERC20 tokens once conditions are met.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawERC20(IERC20 _token, uint256 _amount) public nonReentrant onlyBeneficiary {
        require(_amount > 0, "QV: Amount must be > 0");
        require(vaultState == VaultState.ConditionsMet, "QV: Vault not in ConditionsMet state");
        require(totalDepositedERC20[address(_token)] >= _amount, "QV: Insufficient ERC20 balance in vault");

        totalDepositedERC20[address(_token)] -= _amount;

        _token.safeTransfer(msg.sender, _amount);

        emit ERC20Withdrawn(msg.sender, address(_token), _amount);
    }

    /// @dev Allows a beneficiary to withdraw an ERC721 token once conditions are met.
    /// @param _token The address of the ERC721 token contract.
    /// @param _tokenId The ID of the token to withdraw.
    function withdrawERC721(IERC721 _token, uint256 _tokenId) public nonReentrant onlyBeneficiary {
        require(vaultState == VaultState.ConditionsMet, "QV: Vault not in ConditionsMet state");
        require(totalDepositedERC721[address(_token)].contains(_tokenId), "QV: Token not in vault");

        totalDepositedERC721[address(_token)].remove(_tokenId);

        _token.transferFrom(address(this), msg.sender, _tokenId);

        emit ERC721Withdrawn(msg.sender, address(_token), _tokenId);
    }

    /// @dev Allows a beneficiary to withdraw multiple ERC721 tokens of the same type once conditions are met.
    /// @param _token The address of the ERC721 token contract.
    /// @param _tokenIds An array of token IDs to withdraw.
    function withdrawERC721Batch(IERC721 _token, uint256[] memory _tokenIds) public nonReentrant onlyBeneficiary {
        require(vaultState == VaultState.ConditionsMet, "QV: Vault not in ConditionsMet state");
        require(_tokenIds.length > 0, "QV: No token IDs provided");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
             uint256 tokenId = _tokenIds[i];
             require(totalDepositedERC721[address(_token)].contains(tokenId), "QV: Token not in vault or already withdrawn");
             totalDepositedERC721[address(_token)].remove(tokenId);
             _token.transferFrom(address(this), msg.sender, tokenId);
             emit ERC721Withdrawn(msg.sender, address(_token), tokenId); // Emit for each token
        }
        emit ERC721BatchWithdrawn(msg.sender, address(_token), _tokenIds); // Emit batch event as well
    }


    // --- Emergency Withdrawal Functions ---

    /// @dev Allows an original depositor to withdraw up to their initial ETH deposit
    /// during the Emergency Shutdown state, but only after the activation delay.
    /// @param _amount The amount of ETH to withdraw. Cannot exceed initial deposit.
    function withdrawInEmergencyETH(uint256 _amount) public nonReentrant {
        require(vaultState == VaultState.EmergencyShutdown, "QV: Not in EmergencyShutdown state");
        require(block.timestamp >= emergencyActivationTime, "QV: Emergency not yet active");
        require(_amount > 0, "QV: Amount must be > 0");

        // Crucially, check against initial deposit, not current balance
        uint256 availableToWithdraw = initialETHDeposits[msg.sender];
        require(availableToWithdraw >= _amount, "QV: Exceeds initial deposit or already withdrawn");

        // Reduce the amount the depositor can claim in emergency
        initialETHDeposits[msg.sender] -= _amount;
        // Note: We don't reduce totalDepositedETH here, as that tracks overall vault balance.
        // Emergency withdrawal is about reclaiming initial stake, not reducing the general pool.
        // This means if some funds are emergency-withdrawn, the total deposited counts might be misleading
        // in emergency, but they are accurate in Locked/ConditionsMet state.

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "QV: Emergency ETH withdrawal failed");

        // Consider adding a specific emergency withdrawal event
        // emit EmergencyETHWithdrawn(msg.sender, _amount);
        emit ETHWithdrawn(msg.sender, _amount); // Using the standard event for simplicity
    }

    /// @dev Allows an original depositor to withdraw up to their initial ERC20 deposit for a token
    /// during the Emergency Shutdown state, but only after the activation delay.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of tokens to withdraw. Cannot exceed initial deposit for this token.
    function withdrawInEmergencyERC20(IERC20 _token, uint256 _amount) public nonReentrant {
        require(vaultState == VaultState.EmergencyShutdown, "QV: Not in EmergencyShutdown state");
        require(block.timestamp >= emergencyActivationTime, "QV: Emergency not yet active");
        require(_amount > 0, "QV: Amount must be > 0");

        uint256 availableToWithdraw = initialERC20Deposits[msg.sender][address(_token)];
        require(availableToWithdraw >= _amount, "QV: Exceeds initial deposit or already withdrawn");

        initialERC20Deposits[msg.sender][address(_token)] -= _amount;
        // See note in withdrawInEmergencyETH regarding total balance tracking

        _token.safeTransfer(msg.sender, _amount);

        // emit EmergencyERC20Withdrawn(msg.sender, address(_token), _amount);
        emit ERC20Withdrawn(msg.sender, address(_token), _amount);
    }

    /// @dev Allows an original depositor to withdraw a specific ERC721 token they initially deposited
    /// during the Emergency Shutdown state, but only after the activation delay.
    /// @param _token The address of the ERC721 token contract.
    /// @param _tokenId The ID of the token to withdraw.
    function withdrawInEmergencyERC721(IERC721 _token, uint256 _tokenId) public nonReentrant {
        require(vaultState == VaultState.EmergencyShutdown, "QV: Not in EmergencyShutdown state");
        require(block.timestamp >= emergencyActivationTime, "QV: Emergency not yet active");

        // Check if this specific token ID was initially deposited by the caller
        require(initialERC721Deposits[msg.sender][address(_token)].contains(_tokenId), "QV: Token not initially deposited by caller");
        // Check if the token is still in the vault (not withdrawn by anyone else in emergency)
        require(totalDepositedERC721[address(_token)].contains(_tokenId), "QV: Token not in vault");


        // Remove from initial tracking for this depositor
        initialERC721Deposits[msg.sender][address(_token)].remove(_tokenId);
        // Remove from total vault tracking
        totalDepositedERC721[address(_token)].remove(_tokenId);


        _token.transferFrom(address(this), msg.sender, _tokenId);

        // emit EmergencyERC721Withdrawn(msg.sender, address(_token), _tokenId);
        emit ERC721Withdrawn(msg.sender, address(_token), _tokenId);
    }


    // --- Query Functions ---

    /// @dev Returns the total balance of ETH held in the vault.
    function getTotalDepositedETH() public view returns (uint256) {
        return totalDepositedETH;
    }

    /// @dev Returns the total balance of a specific ERC20 token held in the vault.
    /// @param _token The address of the ERC20 token.
    function getTotalDepositedERC20(IERC20 _token) public view returns (uint256) {
        return totalDepositedERC20[address(_token)];
    }

     /// @dev Returns the total count of a specific ERC721 token type held in the vault.
     /// Note: Does not return token IDs, just the count.
     /// @param _token The address of the ERC721 token contract.
    function getTotalDepositedERC721Count(IERC721 _token) public view returns (uint256) {
        return totalDepositedERC721[address(_token)].length();
    }

     /// @dev Returns the list of all beneficiaries.
    function getBeneficiaries() public view returns (address[] memory) {
        return beneficiaries.values();
    }

    /// @dev Returns the list of all configured condition IDs.
    function getConfiguredConditionIds() public view returns (uint256[] memory) {
        return configuredConditionIds.values();
    }

    /// @dev Returns the details of a specific configured condition.
    /// @param _conditionId The ID of the condition.
    /// @return conditionType The type of the condition.
    /// @return params The encoded parameters of the condition.
    /// @return configured True if the condition is configured.
    function getConditionDetails(uint256 _conditionId) public view returns (ConditionType conditionType, bytes memory params, bool configured) {
        ReleaseCondition storage condition = releaseConditions[_conditionId];
        return (condition.conditionType, condition.params, condition.configured);
    }

    /// @dev Returns the current met status of a specific condition.
    /// @param _conditionId The ID of the condition.
    /// @return bool True if the condition's status is met.
    function getConditionMetStatus(uint256 _conditionId) public view returns (bool) {
        require(releaseConditions[_conditionId].configured, "QV: Condition not configured");
        // For non-external signal types, this checks the current state.
        // For external signal types, this returns the signaled status.
        // To get the *actual* current status for external signals based on oracle,
        // you'd need another function interacting with the oracle contract directly,
        // or rely on the conditionManager to keep the signal updated.
        // This function provides the *internal* status based on the last check/signal.
         if (releaseConditions[_conditionId].conditionType == ConditionType.TYPE_EXTERNAL_SIGNAL) {
             return conditionMetStatus[_conditionId];
         } else {
             return _checkCondition(_conditionId);
         }
    }


    /// @dev Returns the current state of the vault.
    function getVaultState() public view returns (VaultState) {
        return vaultState;
    }

    /// @dev Returns the timestamp when emergency shutdown becomes active. 0 if not triggered or canceled.
    function getEmergencyActivationTime() public view returns (uint256) {
        return emergencyActivationTime;
    }

    /// @dev Returns the initial ETH deposited by a specific address.
    /// @param _depositor The address of the depositor.
    function getInitialDepositedETH(address _depositor) public view returns (uint256) {
        return initialETHDeposits[_depositor];
    }

    /// @dev Returns the initial ERC20 deposited by a specific address for a given token.
    /// @param _depositor The address of the depositor.
    /// @param _token The address of the ERC20 token.
    function getInitialDepositedERC20(address _depositor, address _token) public view returns (uint256) {
        return initialERC20Deposits[_depositor][address(_token)];
    }

    /// @dev Returns the list of ERC721 token IDs initially deposited by a specific address for a given token contract.
    /// @param _depositor The address of the depositor.
    /// @param _token The address of the ERC721 token contract.
    function getInitialDepositedERC721(address _depositor, address _token) public view returns (uint256[] memory) {
        return initialERC721Deposits[_depositor][address(_token)].values();
    }
}
```