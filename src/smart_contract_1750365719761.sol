Okay, let's design a smart contract based on an advanced, creative concept that avoids direct duplication of common open-source patterns.

The concept: A "Quantum Vault". This vault holds assets (ETH and ERC20s) whose release conditions and beneficiaries exist in a state of "superposition" initially. Only after a specific "measurement" event occurs (triggered by external data or an internal state check) does the vault "collapse" into a single, defined outcome, allowing funds to be claimed according to the *one* specific condition that was met.

This simulates quantum ideas:
*   **Superposition:** Multiple potential outcome states are committed to initially but not fully revealed.
*   **Entanglement:** The outcome (who gets what) for each state is tied to the specific condition of that state.
*   **Measurement:** An external trigger or data point forces the contract state to collapse into one specific, verifiable outcome based on the committed conditions.
*   **Resolution:** Funds are distributed according to the collapsed state.

This is distinct from simple timelocks, multisigs, or single-condition escrows.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **State Management:** Defines the lifecycle of the vault (Setup, Committed, Revealed, Measured, Resolved, Cancelled).
2.  **Data Structures:** Structs to define potential conditions, distributions, and committed/revealed states.
3.  **Core Logic:**
    *   Depositing assets.
    *   Adding commitments for potential future states (condition + distribution hashes).
    *   Locking the setup phase.
    *   Revealing the actual conditions and distributions corresponding to commitments.
    *   Setting external measurement data (simulated oracle).
    *   Triggering the "measurement" event to determine which condition is met.
    *   Resolving the vault based on the measured state.
    *   Allowing beneficiaries to claim funds.
    *   Handling fallback scenarios (no condition met, timeout).
4.  **Access Control:** Depositor/Owner management, state-based restrictions.
5.  **Utility:** Pausing, emergency withdrawal (restricted), querying state.

**Function Summary:**

*   `constructor`: Initializes the vault with the depositor.
*   `depositETH`: Allows the depositor to deposit ETH.
*   `depositERC20`: Allows the depositor to deposit a supported ERC20 token.
*   `addSupportedERC20`: Allows the depositor to register ERC20 tokens for use in distributions.
*   `removeSupportedERC20`: Allows the depositor to unregister ERC20 tokens.
*   `addConditionalStateCommitment`: Adds a commitment hash representing a potential condition and its corresponding distribution.
*   `removeConditionalStateCommitment`: Removes a commitment before the setup is locked.
*   `lockSetupPhase`: Transitions the vault from 'Setup' to 'Committed', preventing further commitments.
*   `revealConditionalState`: Reveals the actual condition and distribution details for a previously committed hash.
*   `setMeasurementOracleAddress`: Sets the address allowed to push external measurement data.
*   `setExternalMeasurementData`: *Simulates* an oracle pushing external data used for condition evaluation.
*   `triggerMeasurement`: Evaluates revealed conditions against current state/external data to find the *single* met condition. Transitions to 'Measured'.
*   `resolveVault`: Executes the distribution rules for the condition identified during `triggerMeasurement`. Transitions to 'Resolved'.
*   `claimFunds`: Allows a beneficiary to claim their allocated tokens after the vault is 'Resolved'.
*   `setDefaultRecipient`: Sets a fallback address if no condition is met by timeout.
*   `setTimeout`: Sets the duration after `triggerMeasurement` when the fallback can be triggered.
*   `resolveToDefault`: Triggers the fallback distribution if timeout is reached and no condition was met.
*   `pauseVault`: Pauses certain operations (measurement, resolution).
*   `unpauseVault`: Unpauses the vault.
*   `cancelSetup`: Allows the depositor to cancel the vault *before* locking setup. Refunds deposits.
*   `emergencyWithdraw`: Restricted withdrawal for the depositor under specific, limited circumstances.
*   `getVaultState`: Returns the current lifecycle state of the vault. (View)
*   `getTotalETHBalance`: Returns the current ETH balance. (View)
*   `getTotalERC20Balance`: Returns the balance of a specific ERC20 token. (View)
*   `getDepositor`: Returns the depositor's address. (View)
*   `getConditionalStateCommitments`: Returns a list of active commitment hashes. (View)
*   `getRevealedConditionalState`: Returns the revealed details for a specific state ID. (View)
*   `getMetConditionDetails`: Returns the details of the condition that was met after measurement. (View)
*   `getBeneficiaryClaimableAmount`: Returns the amount of a specific token a beneficiary can claim after resolution. (View)
*   `isVaultResolved`: Checks if the vault is in the 'Resolved' state. (View)
*   `getSupportedERC20s`: Returns the list of supported ERC20 tokens. (View)
*   `getDefaultRecipient`: Returns the fallback recipient. (View)
*   `getTimeout`: Returns the timeout duration. (View)
*   `getMeasurementTimestamp`: Returns the timestamp of the last external data measurement. (View)
*   `getMeasurementOracleAddress`: Returns the address allowed to push measurement data. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// QuantumVault Smart Contract
//
// Outline:
// 1. State Management: Defines the lifecycle of the vault (Setup, Committed, Revealed, Measured, Resolved, Cancelled).
// 2. Data Structures: Structs to define potential conditions, distributions, and committed/revealed states.
// 3. Core Logic: Depositing, adding commitments, locking setup, revealing states, simulating measurement data, triggering measurement, resolving, claiming, fallback handling.
// 4. Access Control: Depositor/Owner management, state-based restrictions.
// 5. Utility: Pausing, emergency withdrawal (restricted), querying state.
//
// Function Summary:
// - constructor: Initializes the vault with the depositor.
// - depositETH: Allows the depositor to deposit ETH.
// - depositERC20: Allows the depositor to deposit a supported ERC20 token.
// - addSupportedERC20: Allows the depositor to register ERC20 tokens for use in distributions.
// - removeSupportedERC20: Allows the depositor to unregister ERC20 tokens.
// - addConditionalStateCommitment: Adds a commitment hash representing a potential condition and its corresponding distribution.
// - removeConditionalStateCommitment: Removes a commitment before the setup is locked.
// - lockSetupPhase: Transitions the vault from 'Setup' to 'Committed', preventing further commitments.
// - revealConditionalState: Reveals the actual condition and distribution details for a previously committed hash.
// - setMeasurementOracleAddress: Sets the address allowed to push external measurement data.
// - setExternalMeasurementData: *Simulates* an oracle pushing external data used for condition evaluation.
// - triggerMeasurement: Evaluates revealed conditions against current state/external data to find the *single* met condition. Transitions to 'Measured'.
// - resolveVault: Executes the distribution rules for the condition identified during `triggerMeasurement`. Transitions to 'Resolved'.
// - claimFunds: Allows a beneficiary to claim their allocated tokens after the vault is 'Resolved'.
// - setDefaultRecipient: Sets a fallback address if no condition is met by timeout.
// - setTimeout: Sets the duration after `triggerMeasurement` when the fallback can be triggered.
// - resolveToDefault: Triggers the fallback distribution if timeout is reached and no condition was met.
// - pauseVault: Pauses certain operations (measurement, resolution).
// - unpauseVault: Unpauses the vault.
// - cancelSetup: Allows the depositor to cancel the vault *before* locking setup. Refunds deposits.
// - emergencyWithdraw: Restricted withdrawal for the depositor under specific, limited circumstances.
// - getVaultState: Returns the current lifecycle state of the vault. (View)
// - getTotalETHBalance: Returns the current ETH balance. (View)
// - getTotalERC20Balance: Returns the balance of a specific ERC20 token. (View)
// - getDepositor: Returns the depositor's address. (View)
// - getConditionalStateCommitments: Returns a list of active commitment hashes. (View)
// - getRevealedConditionalState: Returns the revealed details for a specific state ID. (View)
// - getMetConditionDetails: Returns the details of the condition that was met after measurement. (View)
// - getBeneficiaryClaimableAmount: Returns the amount of a specific token a beneficiary can claim after resolution. (View)
// - isVaultResolved: Checks if the vault is in the 'Resolved' state. (View)
// - getSupportedERC20s: Returns the list of supported ERC20 tokens. (View)
// - getDefaultRecipient: Returns the fallback recipient. (View)
// - getTimeout: Returns the timeout duration. (View)
// - getMeasurementTimestamp: Returns the timestamp of the last external data measurement. (View)
// - getMeasurementOracleAddress: Returns the address allowed to push measurement data. (View)


contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    enum VaultState {
        Setup,      // Initial state: Depositor can add funds & commitments
        Committed,  // Setup locked: Commitments fixed, ready for reveals
        Revealed,   // All or some commitments revealed, ready for measurement
        Measured,   // Measurement triggered, one state identified (or none)
        Resolved,   // Funds distributed based on measured state
        Cancelled   // Vault cancelled before lockup
    }

    // Represents different types of conditions
    enum ConditionType {
        None,           // Represents no specific condition type (e.g., a default state)
        TimestampGT,    // Timestamp Greater Than
        TimestampLT,    // Timestamp Less Than
        ETHBalanceGT,   // Contract ETH Balance Greater Than
        ETHBalanceLT,   // Contract ETH Balance Less Than
        ERC20BalanceGT, // Contract ERC20 Balance Greater Than
        ERC20BalanceLT, // Contract ERC20 Balance Less Than
        ExternalUintEQ, // External uint Data Equal To
        ExternalUintGT, // External uint Data Greater Than
        ExternalUintLT, // External uint Data Less Than
        ExternalBoolEQ, // External bool Data Equal To
        ExternalAddressEQ // External address Data Equal To
        // Add more complex condition types as needed
    }

    // Data structure for a condition
    struct ConditionData {
        ConditionType conditionType;
        uint256 uintValue;      // Used for Timestamp, Balance, ExternalUint
        address addressValue;   // Used for ERC20 token address or ExternalAddress
        bool boolValue;         // Used for ExternalBool
        // Future: bytes data for more complex arbitrary checks
    }

    // Data structure for a single beneficiary's share
    struct BeneficiaryShare {
        address recipient;
        address tokenAddress; // Address(0) for ETH
        uint256 amount;       // Can be absolute amount OR percentage base (e.g., 100 for 100%)
        bool isPercentage;    // True if amount is a percentage of total relevant token balance
    }

    // Data structure for a distribution across multiple beneficiaries
    struct DistributionData {
        BeneficiaryShare[] shares;
    }

    // Represents a potential state in the vault's superposition
    struct PotentialState {
        bytes32 commitmentHash; // keccak256(abi.encode(condition, distribution))
        bool isRevealed;
        ConditionData condition;      // Only populated after reveal
        DistributionData distribution; // Only populated after reveal
    }

    address public depositor;
    VaultState public currentVaultState;
    uint256 private _stateCounter; // Used to generate unique IDs for states

    // Mapping from state ID to PotentialState data
    mapping(uint256 => PotentialState) public potentialStates;
    // Mapping from commitment hash to state ID (for quick lookup during reveal)
    mapping(bytes32 => uint256) private commitmentToStateId;
    // List of state IDs with active commitments
    uint256[] public stateIds;

    // Measurement related variables
    address public measurementOracleAddress; // Address authorized to push measurement data
    uint256 public lastMeasurementTimestamp; // Timestamp when external data was last set
    uint256 public externalUintData;         // Simulated external data (uint)
    bool public externalBoolData;            // Simulated external data (bool)
    address public externalAddressData;      // Simulated external data (address)
    uint256 public metConditionStateId;      // ID of the state whose condition was met

    // Fallback variables
    address public defaultRecipient;
    uint256 public measurementTimeout; // Duration after measurementTriggeredAt

    // State after resolution
    mapping(address => mapping(address => uint256)) private claimableFunds; // beneficiary => token => amount

    // Supported ERC20 tokens for distributions
    mapping(address => bool) public isSupportedERC20;
    address[] private supportedERC20s;

    // Events
    event ETHDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event SupportedERC20Added(address indexed token);
    event SupportedERC20Removed(address indexed token);
    event ConditionalStateCommitmentAdded(address indexed depositor, uint256 stateId, bytes32 commitmentHash);
    event ConditionalStateCommitmentRemoved(address indexed depositor, uint256 stateId, bytes32 commitmentHash);
    event SetupLocked(address indexed depositor);
    event ConditionalStateRevealed(address indexed depositor, uint256 stateId, bytes32 commitmentHash);
    event ExternalMeasurementDataSet(address indexed oracle, uint256 timestamp);
    event MeasurementTriggered(address indexed trigger, uint256 metStateId, bool conditionMet);
    event VaultResolved(uint256 indexed metStateId);
    event FundsClaimed(address indexed beneficiary, address indexed token, uint256 amount);
    event DefaultRecipientSet(address indexed recipient);
    event TimeoutSet(uint256 timeout);
    event ResolvedToDefault(address indexed recipient);
    event VaultPaused(address account);
    event VaultUnpaused(address account);
    event VaultCancelled(address indexed depositor);
    event EmergencyWithdrawal(address indexed depositor, address indexed token, uint256 amount);
    event VaultStateChanged(VaultState newState);


    modifier onlyDepositor() {
        require(msg.sender == depositor, "Not depositor");
        _;
    }

    modifier whenState(VaultState _state) {
        require(currentVaultState == _state, "Invalid vault state");
        _;
    }

    modifier notState(VaultState _state) {
         require(currentVaultState != _state, "Invalid vault state");
        _;
    }


    constructor(address _depositor) Ownable(msg.sender) Pausable(false) {
        depositor = _depositor;
        currentVaultState = VaultState.Setup;
        _stateCounter = 0;
        metConditionStateId = 0; // 0 signifies no condition met initially
        emit VaultStateChanged(currentVaultState);
    }

    receive() external payable whenState(VaultState.Setup) {
        depositETH();
    }

    /// @notice Allows the depositor to deposit ETH into the vault during the Setup phase.
    function depositETH() public payable onlyDepositor whenState(VaultState.Setup) {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit ETHDeposited(depositor, msg.value);
    }

    /// @notice Allows the depositor to deposit a supported ERC20 token into the vault during the Setup phase.
    /// @param _token Address of the ERC20 token.
    /// @param _amount Amount of tokens to deposit.
    function depositERC20(address _token, uint256 _amount) public onlyDepositor whenState(VaultState.Setup) {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(isSupportedERC20[_token], "Token not supported for deposit");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit ERC20Deposited(depositor, _token, _amount);
    }

    /// @notice Allows the depositor to register an ERC20 token to be potentially used in distributions.
    /// Can only be called during the Setup phase.
    /// @param _token Address of the ERC20 token.
    function addSupportedERC20(address _token) public onlyDepositor whenState(VaultState.Setup) {
        require(_token != address(0), "Invalid token address");
        require(!isSupportedERC20[_token], "Token already supported");
        isSupportedERC20[_token] = true;
        supportedERC20s.push(_token);
        emit SupportedERC20Added(_token);
    }

    /// @notice Allows the depositor to unregister a supported ERC20 token.
    /// Can only be called during the Setup phase.
    /// @param _token Address of the ERC20 token.
    function removeSupportedERC20(address _token) public onlyDepositor whenState(VaultState.Setup) {
        require(_token != address(0), "Invalid token address");
        require(isSupportedERC20[_token], "Token not supported");
        isSupportedERC20[_token] = false;
        // Simple removal from array (O(n)), optimize if many tokens
        for (uint i = 0; i < supportedERC20s.length; i++) {
            if (supportedERC20s[i] == _token) {
                supportedERC20s[i] = supportedERC20s[supportedERC20s.length - 1];
                supportedERC20s.pop();
                break;
            }
        }
        emit SupportedERC20Removed(_token);
    }

    /// @notice Allows the depositor to add a commitment hash for a potential condition and its distribution.
    /// This hash represents one possible 'superposition' state.
    /// Can only be called during the Setup phase.
    /// @param _commitmentHash The keccak256 hash of the abi.encoded ConditionData and DistributionData.
    function addConditionalStateCommitment(bytes32 _commitmentHash) public onlyDepositor whenState(VaultState.Setup) {
        require(_commitmentHash != bytes32(0), "Commitment hash cannot be zero");
        require(commitmentToStateId[_commitmentHash] == 0, "Commitment hash already exists");

        _stateCounter++;
        uint256 newStateId = _stateCounter;
        potentialStates[newStateId].commitmentHash = _commitmentHash;
        potentialStates[newStateId].isRevealed = false; // Not revealed initially

        commitmentToStateId[_commitmentHash] = newStateId;
        stateIds.push(newStateId);

        emit ConditionalStateCommitmentAdded(depositor, newStateId, _commitmentHash);
    }

    /// @notice Allows the depositor to remove a commitment hash before the setup is locked.
    /// Can only be called during the Setup phase.
    /// @param _commitmentHash The commitment hash to remove.
    function removeConditionalStateCommitment(bytes32 _commitmentHash) public onlyDepositor whenState(VaultState.Setup) {
        uint256 stateIdToRemove = commitmentToStateId[_commitmentHash];
        require(stateIdToRemove != 0 && potentialStates[stateIdToRemove].commitmentHash != bytes32(0), "Commitment hash not found");
        require(!potentialStates[stateIdToRemove].isRevealed, "Cannot remove revealed commitment");

        // Remove from mapping and stateIds array
        delete commitmentToStateId[_commitmentHash];
        delete potentialStates[stateIdToRemove]; // Clears the struct

        // Remove from stateIds array (simple O(n))
        for (uint i = 0; i < stateIds.length; i++) {
            if (stateIds[i] == stateIdToRemove) {
                stateIds[i] = stateIds[stateIds.length - 1];
                stateIds.pop();
                break;
            }
        }

        emit ConditionalStateCommitmentRemoved(depositor, stateIdToRemove, _commitmentHash);
    }


    /// @notice Locks the setup phase, preventing further deposits or commitment changes.
    /// Transitions the vault state from 'Setup' to 'Committed'.
    /// Requires at least one commitment to be added.
    function lockSetupPhase() public onlyDepositor whenState(VaultState.Setup) {
        require(stateIds.length > 0, "Must add at least one commitment before locking");
        currentVaultState = VaultState.Committed;
        emit SetupLocked(depositor);
        emit VaultStateChanged(currentVaultState);
    }

    /// @notice Allows the depositor to reveal the actual condition and distribution data for a commitment.
    /// This must match the previously submitted commitment hash.
    /// Can be called during 'Committed' or 'Revealed' states.
    /// @param _condition The actual condition data.
    /// @param _distribution The actual distribution data.
    function revealConditionalState(ConditionData calldata _condition, DistributionData calldata _distribution) public onlyDepositor whenState(VaultState.Committed) {
        // Re-calculate the hash from the revealed data
        bytes32 calculatedHash = keccak256(abi.encode(_condition, _distribution));

        // Find the state ID associated with this hash
        uint256 stateId = commitmentToStateId[calculatedHash];

        require(stateId != 0 && potentialStates[stateId].commitmentHash == calculatedHash, "Revealed data does not match any active commitment");
        require(!potentialStates[stateId].isRevealed, "State already revealed");

        // Store the revealed data
        potentialStates[stateId].isRevealed = true;
        potentialStates[stateId].condition = _condition;
        potentialStates[stateId].distribution = _distribution;

        // Basic validation on distribution
        for (uint i = 0; i < _distribution.shares.length; i++) {
            require(_distribution.shares[i].recipient != address(0), "Beneficiary address cannot be zero");
             if (_distribution.shares[i].tokenAddress != address(0)) { // Not ETH
                require(isSupportedERC20[_distribution.shares[i].tokenAddress], "Distribution token not supported");
            }
            if (_distribution.shares[i].isPercentage) {
                 require(_distribution.shares[i].amount <= 10000, "Percentage must be <= 10000 (for 100%)"); // Use 100 = 1%, 10000 = 100%
            }
        }

        currentVaultState = VaultState.Revealed;
        emit ConditionalStateRevealed(depositor, stateId, calculatedHash);
        emit VaultStateChanged(currentVaultState);
    }

    /// @notice Sets the address authorized to push external measurement data.
    /// Can only be called by the depositor in Setup or Committed states.
    /// @param _oracleAddress The address of the measurement oracle.
    function setMeasurementOracleAddress(address _oracleAddress) public onlyDepositor whenState(VaultState.Setup) {
         require(_oracleAddress != address(0), "Oracle address cannot be zero");
        measurementOracleAddress = _oracleAddress;
    }

     /// @notice Allows the designated oracle address to set external data for measurement.
     /// This data is used by `triggerMeasurement` to evaluate conditions.
     /// Can only be called by the designated measurement oracle address.
     /// @param _uintData External unsigned integer data.
     /// @param _boolData External boolean data.
     /// @param _addressData External address data.
    function setExternalMeasurementData(uint256 _uintData, bool _boolData, address _addressData) public {
        require(msg.sender == measurementOracleAddress, "Only designated oracle can set data");
        externalUintData = _uintData;
        externalBoolData = _boolData;
        externalAddressData = _addressData;
        lastMeasurementTimestamp = block.timestamp;
        emit ExternalMeasurementDataSet(msg.sender, block.timestamp);
    }


    /// @notice Triggers the "measurement" process. This evaluates all revealed conditions
    /// against the current state and external data to find the single condition that is met.
    /// If multiple are met, the first one processed is selected. If none, `metConditionStateId` remains 0.
    /// Can only be called once the vault is in the 'Revealed' state and not paused.
    function triggerMeasurement() public whenState(VaultState.Revealed) whenNotPaused {
        require(lastMeasurementTimestamp > 0, "External measurement data must be set first");
        require(block.timestamp >= lastMeasurementTimestamp, "Cannot measure against future data"); // Basic sanity check

        uint256 potentialStateId;
        bool conditionMet = false;
        uint256 numRevealed = 0;

        // Iterate through all state IDs
        for (uint i = 0; i < stateIds.length; i++) {
            potentialStateId = stateIds[i];
            // Only check revealed states
            if (potentialStates[potentialStateId].isRevealed) {
                 numRevealed++;
                 if (checkCondition(potentialStates[potentialStateId].condition)) {
                    // Found the first met condition
                    metConditionStateId = potentialStateId;
                    conditionMet = true;
                    break; // Only the first met condition matters
                 }
            }
        }

        // Require at least one state was revealed before triggering measurement
        require(numRevealed > 0, "No conditions have been revealed yet");

        // Transition state regardless of whether a condition was met
        currentVaultState = VaultState.Measured;
        emit MeasurementTriggered(msg.sender, metConditionStateId, conditionMet);
        emit VaultStateChanged(currentVaultState);
    }

    /// @notice Checks if a given condition is met based on the current vault state and external data.
    /// @param _condition The condition data to check.
    /// @return True if the condition is met, false otherwise.
    function checkCondition(ConditionData storage _condition) internal view returns (bool) {
        if (_condition.conditionType == ConditionType.None) {
             return true; // A state with no condition is always met (can be used as a default revealed state)
        } else if (_condition.conditionType == ConditionType.TimestampGT) {
            return block.timestamp > _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.TimestampLT) {
            return block.timestamp < _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ETHBalanceGT) {
            return address(this).balance > _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ETHBalanceLT) {
             return address(this).balance < _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ERC20BalanceGT) {
             require(_condition.addressValue != address(0), "ERC20 address needed for balance check");
             return IERC20(_condition.addressValue).balanceOf(address(this)) > _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ERC20BalanceLT) {
             require(_condition.addressValue != address(0), "ERC20 address needed for balance check");
            return IERC20(_condition.addressValue).balanceOf(address(this)) < _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ExternalUintEQ) {
            return externalUintData == _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ExternalUintGT) {
            return externalUintData > _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ExternalUintLT) {
             return externalUintData < _condition.uintValue;
        } else if (_condition.conditionType == ConditionType.ExternalBoolEQ) {
            return externalBoolData == _condition.boolValue;
        } else if (_condition.conditionType == ConditionType.ExternalAddressEQ) {
            return externalAddressData == _condition.addressValue;
        }
        // Add checks for other condition types here
        return false; // Unknown condition type
    }


    /// @notice Resolves the vault, executing the distribution defined by the met condition.
    /// If no condition was met (`metConditionStateId == 0`), this function does nothing,
    /// and the vault remains in the 'Measured' state until `resolveToDefault` is potentially called.
    /// Can only be called once the vault is in the 'Measured' state and not paused.
    function resolveVault() public whenState(VaultState.Measured) whenNotPaused {
        require(metConditionStateId != 0, "No condition was met during measurement");

        PotentialState storage metState = potentialStates[metConditionStateId];
        require(metState.isRevealed, "Met state was not revealed (internal error)");

        // Calculate and record claimable amounts
        for (uint i = 0; i < metState.distribution.shares.length; i++) {
            BeneficiaryShare storage share = metState.distribution.shares[i];
            address token = share.tokenAddress;
            uint256 amountToDistribute;

            if (token == address(0)) { // ETH
                 amountToDistribute = address(this).balance;
            } else { // ERC20
                 amountToDistribute = IERC20(token).balanceOf(address(this));
            }

            uint256 beneficiaryAmount;
            if (share.isPercentage) {
                 // Percentage: amount is in basis points (10000 = 100%)
                 beneficiaryAmount = (amountToDistribute * share.amount) / 10000;
            } else {
                 // Absolute amount
                 beneficiaryAmount = share.amount;
            }

            // Add to claimable funds. Don't transfer yet.
             claimableFunds[share.recipient][token] += beneficiaryAmount;
        }

        // Transition state
        currentVaultState = VaultState.Resolved;
        emit VaultResolved(metConditionStateId);
        emit VaultStateChanged(currentVaultState);
    }


    /// @notice Allows a beneficiary to claim their allocated funds after the vault is in the 'Resolved' state.
    /// A beneficiary can claim multiple times until their allocated amount for a token is zero.
    /// @param _token Address of the token to claim (Address(0) for ETH).
    function claimFunds(address _token) public whenState(VaultState.Resolved) {
        uint256 amountToClaim = claimableFunds[msg.sender][_token];
        require(amountToClaim > 0, "No funds to claim for this token");

        claimableFunds[msg.sender][_token] = 0; // Clear the claimable amount first

        if (_token == address(0)) { // ETH
            (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
            require(success, "ETH transfer failed");
        } else { // ERC20
            IERC20(_token).safeTransfer(msg.sender, amountToClaim);
        }

        emit FundsClaimed(msg.sender, _token, amountToClaim);
    }

    /// @notice Sets the default recipient address for fallback scenarios.
    /// Can only be called by the depositor during the Setup phase.
    /// @param _recipient The address to receive funds if no condition is met by timeout.
    function setDefaultRecipient(address _recipient) public onlyDepositor whenState(VaultState.Setup) {
        require(_recipient != address(0), "Default recipient cannot be zero");
        defaultRecipient = _recipient;
        emit DefaultRecipientSet(_recipient);
    }

    /// @notice Sets the timeout duration after `triggerMeasurement` is called.
    /// If no condition is met and this timeout passes, `resolveToDefault` can be called.
    /// Can only be called by the depositor during the Setup phase.
    /// @param _timeout The duration in seconds.
    function setTimeout(uint256 _timeout) public onlyDepositor whenState(VaultState.Setup) {
        timeout = _timeout;
        emit TimeoutSet(_timeout);
    }

    /// @notice Triggers the fallback mechanism if the vault is in the 'Measured' state,
    /// no condition was met (`metConditionStateId == 0`), and the timeout has passed.
    /// Transfers remaining funds to the default recipient.
    function resolveToDefault() public whenState(VaultState.Measured) whenNotPaused {
        require(metConditionStateId == 0, "A condition was met, cannot resolve to default");
        require(defaultRecipient != address(0), "Default recipient not set");
        require(lastMeasurementTimestamp > 0 && block.timestamp >= lastMeasurementTimestamp + timeout, "Timeout has not passed");

        // Transfer remaining ETH
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
             (bool success, ) = payable(defaultRecipient).call{value: ethBalance}("");
             require(success, "Default recipient ETH transfer failed");
        }

        // Transfer remaining supported ERC20s
        for (uint i = 0; i < supportedERC20s.length; i++) {
             address token = supportedERC20s[i];
             uint256 tokenBalance = IERC20(token).balanceOf(address(this));
             if (tokenBalance > 0) {
                IERC20(token).safeTransfer(defaultRecipient, tokenBalance);
             }
        }

        currentVaultState = VaultState.Resolved; // Vault is resolved via fallback
        emit ResolvedToDefault(defaultRecipient);
        emit VaultStateChanged(currentVaultState);
    }

    /// @notice Pauses operations like `triggerMeasurement` and `resolveVault`.
    function pauseVault() public onlyOwner {
        _pause();
        emit VaultPaused(msg.sender);
    }

    /// @notice Unpauses the vault.
    function unpauseVault() public onlyOwner {
        _unpause();
        emit VaultUnpaused(msg.sender);
    }

    /// @notice Allows the depositor to cancel the vault *before* the setup phase is locked.
    /// All deposited funds are returned to the depositor.
    function cancelSetup() public onlyDepositor whenState(VaultState.Setup) {
        // Transfer remaining ETH back to depositor
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = payable(depositor).call{value: ethBalance}("");
            require(success, "ETH transfer failed during cancellation");
        }

        // Transfer remaining supported ERC20s back to depositor
        for (uint i = 0; i < supportedERC20s.length; i++) {
            address token = supportedERC20s[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance > 0) {
                 IERC20(token).safeTransfer(depositor, tokenBalance);
            }
        }

        currentVaultState = VaultState.Cancelled;
        // Clear mappings/arrays for cleanup (optional, but good practice)
        for(uint i = 0; i < stateIds.length; i++){
            delete potentialStates[stateIds[i]];
            delete commitmentToStateId[potentialStates[stateIds[i]].commitmentHash]; // Hash might be zeroed, check needed
        }
        delete stateIds;
         // Note: isSupportedERC20 and supportedERC20s remain, but contract state is cancelled
        // If full reset is needed, add logic here.

        emit VaultCancelled(depositor);
        emit VaultStateChanged(currentVaultState);
    }


    /// @notice Allows the depositor to withdraw funds in specific, limited scenarios:
    /// 1. If the vault is paused and in Setup state (though cancelSetup is preferred)
    /// 2. If the vault is paused, in Measured state, but *no* condition was met, and timeout hasn't passed.
    /// This is a safety valve, not the primary withdrawal mechanism.
    /// @param _token Address of the token to withdraw (Address(0) for ETH).
    function emergencyWithdraw(address _token) public onlyDepositor whenPaused {
        bool allowed = false;
        if (currentVaultState == VaultState.Setup) {
            allowed = true; // Allow withdrawal during paused setup
        } else if (currentVaultState == VaultState.Measured && metConditionStateId == 0) {
             // Allow withdrawal if paused, measured, no condition met, and timeout not reached yet
             // After timeout, resolveToDefault is the path.
             if (lastMeasurementTimestamp == 0 || block.timestamp < lastMeasurementTimestamp + timeout) {
                allowed = true;
             }
        }

        require(allowed, "Emergency withdraw not allowed in current state/conditions");

        uint256 amount;
        if (_token == address(0)) { // ETH
            amount = address(this).balance;
            (bool success, ) = payable(depositor).call{value: amount}("");
            require(success, "ETH emergency transfer failed");
        } else { // ERC20
            require(isSupportedERC20[_token], "Token not supported for withdrawal");
            amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(depositor, amount);
        }

        emit EmergencyWithdrawal(depositor, _token, amount);
    }


    // --- View Functions ---

    /// @notice Returns the current lifecycle state of the vault.
    /// @return The current VaultState enum value.
    function getVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    /// @notice Returns the current ETH balance held by the vault.
    /// @return The ETH balance in wei.
    function getTotalETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the balance of a specific ERC20 token held by the vault.
    /// @param _token The address of the ERC20 token.
    /// @return The ERC20 token balance.
    function getTotalERC20Balance(address _token) public view returns (uint256) {
        require(_token != address(0), "Invalid token address");
        // Allow checking balance of any token, even if not 'supported' for distributions
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Returns the address of the vault depositor.
    /// @return The depositor's address.
    function getDepositor() public view returns (address) {
        return depositor;
    }

    /// @notice Returns a list of state IDs for commitments that have been added.
    /// @return An array of state IDs.
    function getConditionalStateCommitments() public view returns (uint256[] memory) {
        return stateIds;
    }

    /// @notice Returns the revealed details for a specific potential state.
    /// Requires the state to be revealed.
    /// @param _stateId The ID of the state.
    /// @return The ConditionData and DistributionData for the revealed state.
    function getRevealedConditionalState(uint256 _stateId) public view returns (ConditionData memory, DistributionData memory) {
        require(_stateId > 0 && _stateId <= _stateCounter && potentialStates[_stateId].isRevealed, "State not found or not revealed");
        return (potentialStates[_stateId].condition, potentialStates[_stateId].distribution);
    }

    /// @notice Returns the details of the condition that was met during measurement.
    /// Requires the vault state to be 'Measured' or 'Resolved'.
    /// @return The State ID that was met, and its ConditionData.
    function getMetConditionDetails() public view returns (uint256, ConditionData memory) {
        require(currentVaultState == VaultState.Measured || currentVaultState == VaultState.Resolved, "Vault not measured or resolved");
        if (metConditionStateId == 0) {
             return (0, ConditionData(ConditionType.None, 0, address(0), false)); // Indicate no condition met
        }
        return (metConditionStateId, potentialStates[metConditionStateId].condition);
    }


    /// @notice Returns the amount of a specific token a beneficiary can claim after the vault is resolved.
    /// @param _beneficiary The address of the beneficiary.
    /// @param _token The address of the token (Address(0) for ETH).
    /// @return The claimable amount.
    function getBeneficiaryClaimableAmount(address _beneficiary, address _token) public view returns (uint256) {
        require(currentVaultState == VaultState.Resolved, "Vault is not resolved");
        return claimableFunds[_beneficiary][_token];
    }

     /// @notice Checks if the vault has reached the 'Resolved' state.
     /// @return True if the vault is resolved, false otherwise.
    function isVaultResolved() public view returns (bool) {
        return currentVaultState == VaultState.Resolved;
    }

    /// @notice Returns the list of ERC20 tokens supported for distributions.
    /// @return An array of supported ERC20 token addresses.
    function getSupportedERC20s() public view returns (address[] memory) {
        return supportedERC20s;
    }

    /// @notice Returns the default recipient address for fallback.
    /// @return The default recipient address.
    function getDefaultRecipient() public view returns (address) {
        return defaultRecipient;
    }

    /// @notice Returns the timeout duration after measurement.
    /// @return The timeout duration in seconds.
    function getTimeout() public view returns (uint256) {
        return timeout;
    }

    /// @notice Returns the timestamp when external measurement data was last set.
    /// @return The timestamp (Unix epoch).
    function getMeasurementTimestamp() public view returns (uint256) {
        return lastMeasurementTimestamp;
    }

    /// @notice Returns the address authorized to push measurement data.
    /// @return The oracle address.
    function getMeasurementOracleAddress() public view returns (address) {
        return measurementOracleAddress;
    }
}
```