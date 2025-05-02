Okay, let's design an interesting and advanced smart contract that incorporates concepts like conditional state transitions, external data dependency (simulated via an oracle interface), time-based logic, and potentially managing multiple distinct "states" or configurations within a single instance.

We'll create a "Quantum Vault" contract. The core idea is that assets deposited into the vault exist in a state of "superposition" across multiple potential release configurations until a specific "measurement" event occurs. This event evaluates the conditions for each configuration, collapses the state into one winning configuration (or none), and makes the assets claimable only according to the winning configuration.

This is a metaphorical interpretation of quantum concepts applied to a smart contract state.

Here's the outline and function summary:

---

**Smart Contract: QuantumVault**

**Concept:**
A vault that holds ERC-20 and ERC-721 tokens in a state of "superposition" across multiple predefined release configurations. The state "collapses" to one specific configuration (or remains in superposition if no conditions are met) when a `measureAndCollapseVault` function is called, based on evaluating conditions tied to time, external data (via an oracle interface), and holding specific "entanglement key" NFTs.

**Core States:**
1.  `Superposition`: Initial state after deposit; multiple potential release configurations exist.
2.  `Collapsed`: State after measurement; one configuration has been selected as the winner.
3.  `Paused`: Contract-level pause state (standard admin function).

**Key Features:**
*   **Multiple Configurations:** Define several possible ways assets *could* be released (to different recipients, different amounts/tokens) tied to different conditions.
*   **Conditional Release:** Each configuration has conditions (time lock, required NFT, oracle data check).
*   **Measurement Event:** A specific transaction triggers the evaluation of all configuration conditions.
*   **State Collapse:** Only one configuration wins if its conditions are met (first one found in definition order, for simplicity). Assets are then locked to *only* that winning configuration's recipient and distribution.
*   **Entanglement Keys:** Integrates with a hypothetical ERC-721 contract where owning specific NFTs acts as an "entanglement key" condition for unlocking configurations.
*   **Oracle Integration:** Includes a placeholder for external data checks via a defined interface.
*   **Vault Instantiation:** Each deposit creates a unique "Vault" instance with its own ID, allowing one contract to manage multiple independent quantum vaults.

**Outline & Function Summary:**

1.  **State Variables:**
    *   `nextVaultId`: Counter for unique vault instances.
    *   `vaults`: Mapping from `vaultId` to `Vault` struct containing vault state, deposit info, balances, configurations, etc.
    *   `entanglementKeyContract`: Address of the ERC-721 contract used for key conditions.
    *   `oracleAddress`: Address of the oracle contract used for data conditions.
    *   `allowedOracleConditionTypes`: Mapping of allowed oracle condition types (uint256) => bool.
    *   `isVaultCreationPaused`: Global pause flag.

2.  **Structs:**
    *   `VaultConfiguration`: Defines a potential release state (recipient, assets, conditions: time, NFT, oracle checks).
    *   `OracleCondition`: Defines a single oracle check requirement (type, data).
    *   `Vault`: Contains the state of a single vault instance (depositor, time, current state, collapsed config ID, internal balances, configurations map, configuration IDs array).

3.  **Enums:**
    *   `VaultState`: `Superposition`, `Collapsed`, `Paused`.

4.  **Events:**
    *   `VaultCreated`: Logs creation of a new vault instance.
    *   `ConfigurationDefined`: Logs creation of a new configuration for a vault.
    *   `ConfigurationCancelled`: Logs cancellation of a configuration.
    *   `VaultMeasured`: Logs the measurement event and the winning configuration ID (or none).
    *   `ERC20Withdrawn`: Logs ERC20 withdrawal from a collapsed vault.
    *   `ERC721Withdrawn`: Logs ERC721 withdrawal from a collapsed vault.
    *   `EntanglementKeyContractSet`: Admin sets key contract address.
    *   `OracleAddressSet`: Admin sets oracle contract address.
    *   `AllowedOracleConditionTypeAdded`: Admin adds allowed type.
    *   `AllowedOracleConditionTypeRemoved`: Admin removes allowed type.
    *   `VaultCreationPaused`: Admin pauses creation.
    *   `VaultCreationUnpaused`: Admin unpauses creation.
    *   `EmergencyAdminWithdrawal`: Admin performs emergency withdrawal.

5.  **Modifiers:**
    *   `whenNotPausedGlobal`: Checks if global creation is not paused.
    *   `whenVaultNotCollapsed(uint256 _vaultId)`: Checks if specific vault is in Superposition state.
    *   `whenVaultIsCollapsed(uint256 _vaultId)`: Checks if specific vault is in Collapsed state.
    *   `onlyVaultDepositor(uint256 _vaultId)`: Checks if caller is the original depositor.
    *   `onlyVaultCollapsedRecipient(uint256 _vaultId)`: Checks if caller is the intended recipient of the collapsed state.

6.  **Functions (27+):**
    *   `constructor()`: Initializes the contract, sets owner.
    *   `createQuantumVault(address _erc20Token, uint256 _erc20Amount, address _erc721Token, uint256[] calldata _erc721TokenIds)`: User deposits assets (one ERC20, one ERC721 type with multiple IDs) to create a new vault instance. Returns new vault ID. (2 ERC calls)
    *   `defineVaultConfiguration(uint256 _vaultId, VaultConfiguration memory _config)`: Depositor defines a potential release configuration for their vault.
    *   `cancelVaultConfiguration(uint256 _vaultId, uint256 _configId)`: Depositor cancels a previously defined configuration for their vault.
    *   `measureAndCollapseVault(uint256 _vaultId)`: Public function to trigger the state collapse for a specific vault. Evaluates conditions and selects the winning configuration.
    *   `withdrawCollapsedERC20(uint256 _vaultId)`: The recipient of the collapsed state claims the ERC20 tokens specified in the winning configuration.
    *   `withdrawCollapsedERC721(uint256 _vaultId, address _erc721Token, uint256[] calldata _tokenIds)`: The recipient of the collapsed state claims specific ERC721 tokens from the winning configuration.
    *   `setEntanglementKeyContract(address _keyContract)`: Admin function to set the address of the ERC-721 entanglement key contract.
    *   `setOracleAddress(address _oracle)`: Admin function to set the address of the oracle contract.
    *   `addAllowedOracleConditionType(uint256 _conditionType)`: Admin function to whitelist a type of oracle condition.
    *   `removeAllowedOracleConditionType(uint256 _conditionType)`: Admin function to de-whitelist an oracle condition type.
    *   `pauseGlobalVaultCreation()`: Admin function to pause new vault creation.
    *   `unpauseGlobalVaultCreation()`: Admin function to unpause new vault creation.
    *   `emergencyAdminWithdrawERC20(uint256 _vaultId, address _token)`: Admin can withdraw specific ERC20 from an *uncollapsed* vault in emergencies.
    *   `emergencyAdminWithdrawERC721(uint256 _vaultId, address _token, uint256[] calldata _tokenIds)`: Admin can withdraw specific ERC721s from an *uncollapsed* vault in emergencies.
    *   `getVaultState(uint256 _vaultId)`: Public view function to get the current state of a vault (Superposition/Collapsed/Paused).
    *   `getVaultDepositor(uint256 _vaultId)`: Public view function to get the original depositor of a vault.
    *   `getVaultDepositTime(uint256 _vaultId)`: Public view function to get the deposit timestamp.
    *   `getVaultCollapsedConfigId(uint256 _vaultId)`: Public view function to get the ID of the winning configuration if collapsed (0 if not).
    *   `getVaultConfigurationIds(uint256 _vaultId)`: Public view function to get all active configuration IDs for a vault.
    *   `getVaultConfigurationDetails(uint256 _vaultId, uint256 _configId)`: Public view function to get the details of a specific configuration.
    *   `getVaultCurrentERC20Balance(uint256 _vaultId, address _token)`: Public view function to check internal ERC20 balance for a specific token in a vault.
    *   `getVaultCurrentERC721Tokens(uint256 _vaultId, address _token)`: Public view function to check internal ERC721 token IDs for a specific token type in a vault.
    *   `getAllowedOracleConditionTypes()`: Public view function to get the list of allowed oracle types.
    *   `checkConfigurationConditions(uint256 _vaultId, uint256 _configId)`: Public view helper to check conditions of a specific config without collapsing state. *Note: Oracle call in view is gas-limited and depends on oracle implementation.*
    *   `transferOwnership(address newOwner)`: Standard OpenZeppelin Ownable function.
    *   `renounceOwnership()`: Standard OpenZeppelin Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Smart Contract: QuantumVault ---
// Concept:
// A vault that holds ERC-20 and ERC-721 tokens in a state of "superposition" across multiple
// predefined release configurations. The state "collapses" to one specific configuration
// (or remains in superposition if no conditions are met) when a `measureAndCollapseVault`
// function is called, based on evaluating conditions tied to time, external data (via an
// oracle interface), and holding specific "entanglement key" NFTs.
// This is a metaphorical interpretation of quantum concepts applied to a smart contract state.

// Core States:
// 1. Superposition: Initial state after deposit; multiple potential release configurations exist.
// 2. Collapsed: State after measurement; one configuration has been selected as the winner.
// 3. Paused: Contract-level pause state (standard admin function).

// Key Features:
// - Multiple Configurations: Define several possible ways assets could be released
//   (to different recipients, different amounts/tokens) tied to different conditions.
// - Conditional Release: Each configuration has conditions (time lock, required NFT, oracle data check).
// - Measurement Event: A specific transaction triggers the evaluation of all configuration conditions.
// - State Collapse: Only one configuration wins if its conditions are met (first one found
//   in definition order, for simplicity). Assets are then locked to only that winning configuration's
//   recipient and distribution.
// - Entanglement Keys: Integrates with a hypothetical ERC-721 contract where owning specific
//   NFTs acts as an "entanglement key" condition for unlocking configurations.
// - Oracle Integration: Includes a placeholder interface for external data checks.
// - Vault Instantiation: Each deposit creates a unique "Vault" instance with its own ID,
//   allowing one contract to manage multiple independent quantum vaults.

// Outline & Function Summary:

// 1. State Variables:
//    - nextVaultId: Counter for unique vault instances.
//    - vaults: Mapping from vaultId to Vault struct.
//    - entanglementKeyContract: Address of the ERC-721 contract for keys.
//    - oracleAddress: Address of the oracle contract.
//    - allowedOracleConditionTypes: Mapping for whitelisted oracle condition types.
//    - isVaultCreationPaused: Global pause flag for new vaults.

// 2. Structs:
//    - VaultConfiguration: Potential release state definition (recipient, assets, conditions).
//    - OracleCondition: Single oracle check requirement (type, data).
//    - Vault: State of a single vault instance (depositor, time, state, collapsed config ID, balances, configs).

// 3. Enums:
//    - VaultState: Superposition, Collapsed, Paused.

// 4. Events:
//    - VaultCreated, ConfigurationDefined, ConfigurationCancelled, VaultMeasured,
//      ERC20Withdrawn, ERC721Withdrawn, EntanglementKeyContractSet, OracleAddressSet,
//      AllowedOracleConditionTypeAdded, AllowedOracleConditionTypeRemoved,
//      VaultCreationPaused, VaultCreationUnpaused, EmergencyAdminWithdrawal.

// 5. Modifiers:
//    - whenNotPausedGlobal, whenVaultNotCollapsed, whenVaultIsCollapsed,
//    - onlyVaultDepositor, onlyVaultCollapsedRecipient.

// 6. Functions (27+):
//    - constructor()
//    - createQuantumVault()
//    - defineVaultConfiguration()
//    - cancelVaultConfiguration()
//    - measureAndCollapseVault()
//    - withdrawCollapsedERC20()
//    - withdrawCollapsedERC721()
//    - setEntanglementKeyContract()
//    - setOracleAddress()
//    - addAllowedOracleConditionType()
//    - removeAllowedOracleConditionType()
//    - pauseGlobalVaultCreation()
//    - unpauseGlobalVaultCreation()
//    - emergencyAdminWithdrawERC20()
//    - emergencyAdminWithdrawERC721()
//    - getVaultState()
//    - getVaultDepositor()
//    - getVaultDepositTime()
//    - getVaultCollapsedConfigId()
//    - getVaultConfigurationIds()
//    - getVaultConfigurationDetails()
//    - getVaultCurrentERC20Balance()
//    - getVaultCurrentERC721Tokens()
//    - getAllowedOracleConditionTypes()
//    - checkConfigurationConditions()
//    - transferOwnership() (from Ownable)
//    - renounceOwnership() (from Ownable)

// --- End of Outline & Summary ---


// Placeholder interface for Oracle contract
// An actual oracle would implement logic in checkCondition based on type and data
interface IQuantumOracle {
    function checkCondition(uint256 conditionType, bytes calldata data) external view returns (bool);
}

contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    // --- Enums ---
    enum VaultState { Superposition, Collapsed, Paused } // VaultState.Paused implies globally paused creation

    // --- Structs ---
    struct OracleCondition {
        uint256 conditionType; // Type identifier recognized by the Oracle contract
        bytes data;            // ABI-encoded data for the Oracle contract (e.g., pair, threshold)
    }

    struct VaultConfiguration {
        uint256 configId;
        address intendedRecipient;
        address erc20Token;       // Single ERC20 type per config for simplicity
        uint256 erc20Amount;
        address erc721Token;      // Single ERC721 type per config for simplicity
        uint256[] erc721TokenIds; // Specific ERC721 tokens to potentially release
        uint256 unlockTime;       // Timestamp after which this config is potentially valid
        address requiredEntanglementKeyContract; // Address of the key NFT contract
        uint256 requiredEntanglementKeyId;     // Specific token ID of the required key NFT
        OracleCondition[] oracleConditions;  // Array of conditions requiring oracle check
        bool isValid; // True if config is still a potential outcome, false after collapse (unless it won)
    }

    struct Vault {
        address depositor;
        uint256 depositTime;
        VaultState state;
        uint256 collapsedConfigId; // The configId that won (0 if no collapse or no winner)

        // Assets held *within* this specific vault instance
        mapping(address => uint256) currentERC20Balances;
        mapping(address => uint256[]) currentERC721Tokens; // Token address => list of IDs

        // Configurations for this vault instance
        mapping(uint256 => VaultConfiguration) configurations;
        uint256[] configurationIds; // Keep track of config IDs for iteration

        uint256 nextConfigId; // Counter for configs within this vault
    }

    // --- State Variables ---
    uint256 public nextVaultId;
    mapping(uint256 => Vault) public vaults;

    address public entanglementKeyContract; // ERC721 contract address for keys
    address public oracleAddress;           // Oracle contract address

    // Whitelist oracle condition types that the admin trusts
    mapping(uint256 => bool) public allowedOracleConditionTypes;

    bool public isVaultCreationPaused;

    // --- Events ---
    event VaultCreated(uint256 indexed vaultId, address indexed depositor, address erc20Token, uint256 erc20Amount, address erc721Token, uint256[] erc721TokenIds);
    event ConfigurationDefined(uint256 indexed vaultId, uint256 indexed configId, address indexed intendedRecipient);
    event ConfigurationCancelled(uint256 indexed vaultId, uint256 indexed configId);
    event VaultMeasured(uint256 indexed vaultId, VaultState newState, uint256 indexed winningConfigId);
    event ERC20Withdrawn(uint256 indexed vaultId, uint256 indexed configId, address indexed recipient, address token, uint256 amount);
    event ERC721Withdrawn(uint256 indexed vaultId, uint256 indexed configId, address indexed recipient, address token, uint256[] tokenIds);
    event EntanglementKeyContractSet(address indexed oldAddress, address indexed newAddress);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event AllowedOracleConditionTypeAdded(uint256 indexed conditionType);
    event AllowedOracleConditionTypeRemoved(uint256 indexed conditionType);
    event VaultCreationPaused();
    event VaultCreationUnpaused();
    event EmergencyAdminWithdrawal(uint256 indexed vaultId, address indexed token, uint256 erc20Amount, uint256[] erc721TokenIds, address indexed admin);

    // --- Modifiers ---
    modifier whenNotPausedGlobal() {
        require(!isVaultCreationPaused, "Vault creation is paused");
        _;
    }

    modifier whenVaultExists(uint256 _vaultId) {
        require(_vaultId > 0 && _vaultId < nextVaultId, "Vault does not exist");
        _;
    }

    modifier whenVaultNotCollapsed(uint256 _vaultId) {
        require(vaults[_vaultId].state == VaultState.Superposition, "Vault is not in Superposition state");
        _;
    }

    modifier whenVaultIsCollapsed(uint256 _vaultId) {
        require(vaults[_vaultId].state == VaultState.Collapsed, "Vault is not in Collapsed state");
        _;
    }

    modifier onlyVaultDepositor(uint256 _vaultId) {
        require(vaults[_vaultId].depositor == msg.sender, "Only depositor can perform this action");
        _;
    }

    // Checks if the caller is the intended recipient of the *collapsed* configuration
    modifier onlyVaultCollapsedRecipient(uint256 _vaultId) {
        require(vaults[_vaultId].state == VaultState.Collapsed, "Vault is not collapsed");
        uint256 collapsedConfigId = vaults[_vaultId].collapsedConfigId;
        require(collapsedConfigId != 0, "No winning configuration found after collapse");
        require(vaults[_vaultId].configurations[collapsedConfigId].intendedRecipient == msg.sender, "Only collapsed state recipient can perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address initialEntanglementKeyContract, address initialOracleAddress) Ownable(msg.sender) {
         // Owner is set by Ownable
         nextVaultId = 1; // Start vault IDs from 1
         entanglementKeyContract = initialEntanglementKeyContract;
         oracleAddress = initialOracleAddress;
    }

    // --- Core Functions ---

    /**
     * @notice Creates a new Quantum Vault instance by depositing assets.
     * @param _erc20Token Address of the ERC20 token to deposit.
     * @param _erc20Amount Amount of ERC20 tokens to deposit.
     * @param _erc721Token Address of the ERC721 token contract for NFTs to deposit.
     * @param _erc721TokenIds Array of ERC721 token IDs to deposit.
     * @return vaultId The unique ID of the newly created vault instance.
     */
    function createQuantumVault(
        address _erc20Token,
        uint256 _erc20Amount,
        address _erc721Token,
        uint256[] calldata _erc721TokenIds
    ) external payable whenNotPausedGlobal nonReentrant returns (uint256 vaultId) {
        vaultId = nextVaultId++;
        Vault storage newVault = vaults[vaultId];

        newVault.depositor = msg.sender;
        newVault.depositTime = block.timestamp;
        newVault.state = VaultState.Superposition;
        newVault.collapsedConfigId = 0; // Initially no collapsed config
        newVault.nextConfigId = 1;    // Start config IDs from 1 for this vault

        // Deposit ERC20
        if (_erc20Amount > 0) {
            IERC20(_erc20Token).safeTransferFrom(msg.sender, address(this), _erc20Amount);
            newVault.currentERC20Balances[_erc20Token] = _erc20Amount;
        }

        // Deposit ERC721s
        if (_erc721Token != address(0) && _erc721TokenIds.length > 0) {
            for (uint256 i = 0; i < _erc721TokenIds.length; i++) {
                 IERC721(_erc721Token).safeTransferFrom(msg.sender, address(this), _erc721TokenIds[i]);
            }
            newVault.currentERC721Tokens[_erc721Token] = _erc721TokenIds; // Store list of IDs
        }

        emit VaultCreated(vaultId, msg.sender, _erc20Token, _erc20Amount, _erc721Token, _erc721TokenIds);
    }

    /**
     * @notice Defines a potential release configuration for a specific vault instance.
     * Can only be called by the depositor when the vault is in Superposition.
     * @param _vaultId The ID of the vault instance.
     * @param _config The configuration details.
     */
    function defineVaultConfiguration(uint256 _vaultId, VaultConfiguration memory _config)
        external
        whenVaultExists(_vaultId)
        onlyVaultDepositor(_vaultId)
        whenVaultNotCollapsed(_vaultId)
    {
        Vault storage currentVault = vaults[_vaultId];
        uint256 configId = currentVault.nextConfigId++;

        // Basic validation for the configuration
        require(_config.intendedRecipient != address(0), "Recipient cannot be zero address");
        // Add checks that requested assets *could* be potentially released (e.g., amounts/ids don't exceed total deposit)
        // This validation is complex and might be better handled during withdrawal,
        // but basic checks like non-zero amounts/token addresses for specified assets are good.
        require(_config.erc20Amount == 0 || _config.erc20Token != address(0), "ERC20 amount requires token address");
         require(_config.erc721TokenIds.length == 0 || _config.erc721Token != address(0), "ERC721 IDs require token address");


        // Add conditions validation (e.g., oracle types are allowed)
        for(uint256 i = 0; i < _config.oracleConditions.length; i++) {
             require(allowedOracleConditionTypes[_config.oracleConditions[i].conditionType], "Oracle condition type not allowed");
        }

        _config.configId = configId;
        _config.isValid = true; // Initially valid
        currentVault.configurations[configId] = _config;
        currentVault.configurationIds.push(configId);

        emit ConfigurationDefined(vaultId, configId, _config.intendedRecipient);
    }

     /**
     * @notice Cancels a specific configuration for a vault instance.
     * Can only be called by the depositor when the vault is in Superposition.
     * @param _vaultId The ID of the vault instance.
     * @param _configId The ID of the configuration to cancel.
     */
    function cancelVaultConfiguration(uint256 _vaultId, uint256 _configId)
        external
        whenVaultExists(_vaultId)
        onlyVaultDepositor(_vaultId)
        whenVaultNotCollapsed(_vaultId)
    {
        Vault storage currentVault = vaults[_vaultId];
        VaultConfiguration storage config = currentVault.configurations[_configId];

        require(config.configId != 0, "Configuration does not exist"); // configId 0 is default for non-existent map entry
        require(config.isValid, "Configuration is already invalid or cancelled");

        config.isValid = false; // Mark as invalid
        // To actually remove from the array and map would be gas-intensive. Marking as invalid is sufficient.

        emit ConfigurationCancelled(_vaultId, _configId);
    }


    /**
     * @notice Triggers the state collapse for a specific vault instance.
     * Evaluates conditions for all valid configurations and selects the first one whose
     * conditions are met. If none are met, the vault remains in Superposition.
     * @param _vaultId The ID of the vault instance.
     */
    function measureAndCollapseVault(uint256 _vaultId)
        external
        whenVaultExists(_vaultId)
        whenVaultNotCollapsed(_vaultId)
        nonReentrant // Important, especially with potential oracle calls
    {
        Vault storage currentVault = vaults[_vaultId];
        uint256 winningConfigId = 0; // 0 means no winner found

        for (uint256 i = 0; i < currentVault.configurationIds.length; i++) {
            uint256 configId = currentVault.configurationIds[i];
            VaultConfiguration storage config = currentVault.configurations[configId];

            if (config.isValid) {
                // Check all conditions for this configuration
                bool conditionsMet = true;

                // 1. Time Condition
                if (block.timestamp < config.unlockTime) {
                    conditionsMet = false;
                }

                // 2. Entanglement Key Condition (requires the recipient to hold the specific NFT)
                if (conditionsMet && config.requiredEntanglementKeyContract != address(0) && config.requiredEntanglementKeyId != 0) {
                    require(entanglementKeyContract != address(0), "Entanglement key contract not set"); // Check if global key contract is set
                    try IERC721(entanglementKeyContract).ownerOf(config.requiredEntanglementKeyId) returns (address nftOwner) {
                         if (nftOwner != config.intendedRecipient) {
                             conditionsMet = false;
                         }
                    } catch {
                         // If ownerOf fails (e.g., token doesn't exist), condition is not met
                         conditionsMet = false;
                    }
                }

                // 3. Oracle Conditions
                if (conditionsMet) {
                    require(oracleAddress != address(0) || config.oracleConditions.length == 0, "Oracle address not set for required conditions"); // Check if global oracle is set only if conditions exist

                    for (uint256 j = 0; j < config.oracleConditions.length; j++) {
                        OracleCondition memory oCond = config.oracleConditions[j];
                         // Check if oracle condition type is allowed by admin
                         require(allowedOracleConditionTypes[oCond.conditionType], "Oracle condition type not allowed by admin");

                        try IQuantumOracle(oracleAddress).checkCondition(oCond.conditionType, oCond.data) returns (bool oracleResult) {
                            if (!oracleResult) {
                                conditionsMet = false;
                                break; // If any oracle condition fails, break inner loop
                            }
                        } catch {
                            // If oracle call fails, condition is not met
                            conditionsMet = false;
                            break; // If oracle call fails, break inner loop
                        }
                    }
                }

                if (conditionsMet) {
                    winningConfigId = configId;
                    break; // Found the first winning configuration, collapse to this one
                }
            }
        }

        if (winningConfigId != 0) {
            // Collapse state
            currentVault.state = VaultState.Collapsed;
            currentVault.collapsedConfigId = winningConfigId;

            // Invalidate all other configurations for this vault
            for (uint256 i = 0; i < currentVault.configurationIds.length; i++) {
                 uint256 configId = currentVault.configurationIds[i];
                 if (configId != winningConfigId) {
                      currentVault.configurations[configId].isValid = false;
                 }
            }
            emit VaultMeasured(vaultId, VaultState.Collapsed, winningConfigId);

        } else {
             // No configuration conditions were met
             // Vault remains in Superposition
             emit VaultMeasured(vaultId, VaultState.Superposition, 0); // Indicate no winner
        }
    }

    /**
     * @notice Allows the intended recipient of the collapsed state to withdraw ERC20 tokens.
     * @param _vaultId The ID of the vault instance.
     */
    function withdrawCollapsedERC20(uint256 _vaultId)
        external
        whenVaultExists(_vaultId)
        whenVaultIsCollapsed(_vaultId)
        onlyVaultCollapsedRecipient(_vaultId)
        nonReentrant
    {
        Vault storage currentVault = vaults[_vaultId];
        uint256 collapsedConfigId = currentVault.collapsedConfigId;
        VaultConfiguration storage winningConfig = currentVault.configurations[collapsedConfigId];

        require(winningConfig.erc20Token != address(0) && winningConfig.erc20Amount > 0, "No ERC20 specified or amount is zero in winning config");
        require(currentVault.currentERC20Balances[winningConfig.erc20Token] >= winningConfig.erc20Amount, "Insufficient ERC20 balance in vault for winning config");

        uint256 amountToTransfer = winningConfig.erc20Amount;
        address tokenAddress = winningConfig.erc20Token;
        address recipient = winningConfig.intendedRecipient;

        // Update internal balance tracking *before* transfer
        currentVault.currentERC20Balances[tokenAddress] -= amountToTransfer;

        // Transfer tokens
        IERC20(tokenAddress).safeTransfer(recipient, amountToTransfer);

        emit ERC20Withdrawn(_vaultId, collapsedConfigId, recipient, tokenAddress, amountToTransfer);

        // Note: ERC721s must be withdrawn separately
    }

    /**
     * @notice Allows the intended recipient of the collapsed state to withdraw specific ERC721 tokens.
     * @param _vaultId The ID of the vault instance.
     * @param _erc721Token The contract address of the ERC721 token.
     * @param _tokenIds Array of specific token IDs to withdraw.
     */
    function withdrawCollapsedERC721(uint256 _vaultId, address _erc721Token, uint256[] calldata _tokenIds)
        external
        whenVaultExists(_vaultId)
        whenVaultIsCollapsed(_vaultId)
        onlyVaultCollapsedRecipient(_vaultId)
        nonReentrant
    {
        Vault storage currentVault = vaults[_vaultId];
        uint256 collapsedConfigId = currentVault.collapsedConfigId;
        VaultConfiguration storage winningConfig = currentVault.configurations[collapsedConfigId];

        require(_erc721Token != address(0) && _tokenIds.length > 0, "No ERC721 token or IDs specified for withdrawal");
        require(winningConfig.erc721Token == _erc721Token, "ERC721 token address in winning config does not match");

        // Basic check: ensure requested IDs are part of the winning config's list
        // A more robust check would verify ownership *within the vault* for each requested ID
        // and remove them from the vault's internal list. This is simplified here.
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            bool foundInConfig = false;
            for (uint256 j = 0; j < winningConfig.erc721TokenIds.length; j++) {
                 if (_tokenIds[i] == winningConfig.erc721TokenIds[j]) {
                      foundInConfig = true;
                      break;
                 }
            }
            require(foundInConfig, "Requested ERC721 ID is not in the winning configuration list");

            // Verify the contract owns the token before transferring
            require(IERC721(_erc721Token).ownerOf(_tokenIds[i]) == address(this), "Vault does not own requested ERC721 token");
        }

        address recipient = winningConfig.intendedRecipient;

        // Transfer tokens
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_erc721Token).safeTransfer(recipient, _tokenIds[i]);
        }

        // Note: Removing withdrawn IDs from `currentVault.currentERC721Tokens[_erc721Token]` is complex for arrays
        // and omitted here for simplicity. The contract will still technically track them, but they are external.
        // A production contract would need a more robust internal ERC721 tracking mechanism (e.g., mapping ID to owner).

        emit ERC721Withdrawn(_vaultId, collapsedConfigId, recipient, _erc721Token, _tokenIds);
    }

    // --- Admin Functions (from Ownable + Custom) ---

    /**
     * @notice Sets the address of the Entanglement Key (ERC721) contract. Only callable by owner.
     * @param _keyContract The new address of the key contract.
     */
    function setEntanglementKeyContract(address _keyContract) external onlyOwner {
        require(_keyContract != address(0), "Key contract address cannot be zero");
        emit EntanglementKeyContractSet(entanglementKeyContract, _keyContract);
        entanglementKeyContract = _keyContract;
    }

    /**
     * @notice Sets the address of the Oracle contract. Only callable by owner.
     * @param _oracle The new address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

    /**
     * @notice Whitelists an oracle condition type that the contract is allowed to check. Only callable by owner.
     * @param _conditionType The oracle condition type ID to allow.
     */
    function addAllowedOracleConditionType(uint256 _conditionType) external onlyOwner {
        require(!allowedOracleConditionTypes[_conditionType], "Condition type already allowed");
        allowedOracleConditionTypes[_conditionType] = true;
        emit AllowedOracleConditionTypeAdded(_conditionType);
    }

    /**
     * @notice De-whitelists an oracle condition type. Only callable by owner.
     * @param _conditionType The oracle condition type ID to remove.
     */
    function removeAllowedOracleConditionType(uint256 _conditionType) external onlyOwner {
        require(allowedOracleConditionTypes[_conditionType], "Condition type not currently allowed");
        allowedOracleConditionTypes[_conditionType] = false;
        emit AllowedOracleConditionTypeRemoved(_conditionType);
    }

    /**
     * @notice Pauses the creation of new vault instances. Only callable by owner.
     */
    function pauseGlobalVaultCreation() external onlyOwner {
        require(!isVaultCreationPaused, "Vault creation is already paused");
        isVaultCreationPaused = true;
        emit VaultCreationPaused();
    }

    /**
     * @notice Unpauses the creation of new vault instances. Only callable by owner.
     */
    function unpauseGlobalVaultCreation() external onlyOwner {
        require(isVaultCreationPaused, "Vault creation is not paused");
        isVaultCreationPaused = false;
        emit VaultCreationUnpaused();
    }

    /**
     * @notice Allows the owner to withdraw ERC20 tokens from an uncollapsed vault in emergencies.
     * This bypasses configurations and conditions.
     * @param _vaultId The ID of the vault instance.
     * @param _token The address of the ERC20 token.
     */
    function emergencyAdminWithdrawERC20(uint256 _vaultId, address _token)
        external
        onlyOwner
        whenVaultExists(_vaultId)
        whenVaultNotCollapsed(_vaultId) // Only emergency withdraw from uncollapsed vaults
        nonReentrant
    {
        Vault storage currentVault = vaults[_vaultId];
        uint256 amount = currentVault.currentERC20Balances[_token];
        require(amount > 0, "No ERC20 balance of this token in the vault");

        currentVault.currentERC20Balances[_token] = 0;
        IERC20(_token).safeTransfer(owner(), amount);

        emit EmergencyAdminWithdrawal(_vaultId, _token, amount, new uint256[](0), owner());
    }

     /**
     * @notice Allows the owner to withdraw ERC721 tokens from an uncollapsed vault in emergencies.
     * This bypasses configurations and conditions.
     * @param _vaultId The ID of the vault instance.
     * @param _token The address of the ERC721 token contract.
     * @param _tokenIds Array of specific token IDs to withdraw.
     */
    function emergencyAdminWithdrawERC721(uint256 _vaultId, address _token, uint256[] calldata _tokenIds)
        external
        onlyOwner
        whenVaultExists(_vaultId)
        whenVaultNotCollapsed(_vaultId) // Only emergency withdraw from uncollapsed vaults
        nonReentrant
    {
        Vault storage currentVault = vaults[_vaultId];
         require(_tokenIds.length > 0, "No token IDs specified for emergency withdrawal");

        // A more robust implementation would track internal ERC721s better.
        // Here, we simply verify contract ownership and transfer, clearing the internal tracking list (simplistic).
        uint256[] memory withdrawnIds = new uint256[](_tokenIds.length); // To emit in event

        for (uint256 i = 0; i < _tokenIds.length; i++) {
             require(IERC721(_token).ownerOf(_tokenIds[i]) == address(this), "Vault does not own requested ERC721 token for emergency withdrawal");
             IERC721(_token).safeTransfer(owner(), _tokenIds[i]);
             withdrawnIds[i] = _tokenIds[i];
        }

        // Note: Clearing the internal list `currentVault.currentERC721Tokens[_token]` for arbitrary IDs is hard.
        // This simplified version just clears the entire list for that token type, which is not ideal.
        // currentVault.currentERC721Tokens[_token] should be updated more granularly in a real contract.
        delete currentVault.currentERC721Tokens[_token]; // Simplified: clear all tracking for this token type


        emit EmergencyAdminWithdrawal(_vaultId, _token, 0, withdrawnIds, owner());
    }


    // --- Query Functions ---

    /**
     * @notice Gets the current state of a specific vault.
     * @param _vaultId The ID of the vault instance.
     * @return state The current VaultState (Superposition, Collapsed, Paused).
     */
    function getVaultState(uint256 _vaultId) external view whenVaultExists(_vaultId) returns (VaultState) {
        return vaults[_vaultId].state;
    }

     /**
     * @notice Gets the original depositor of a specific vault.
     * @param _vaultId The ID of the vault instance.
     * @return depositor The address of the depositor.
     */
    function getVaultDepositor(uint256 _vaultId) external view whenVaultExists(_vaultId) returns (address) {
        return vaults[_vaultId].depositor;
    }

     /**
     * @notice Gets the deposit timestamp of a specific vault.
     * @param _vaultId The ID of the vault instance.
     * @return depositTime The timestamp of creation.
     */
    function getVaultDepositTime(uint256 _vaultId) external view whenVaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].depositTime;
    }

     /**
     * @notice Gets the configuration ID that won if the vault is in Collapsed state.
     * @param _vaultId The ID of the vault instance.
     * @return configId The winning configuration ID (0 if not collapsed or no winner).
     */
    function getVaultCollapsedConfigId(uint256 _vaultId) external view whenVaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].collapsedConfigId;
    }

    /**
     * @notice Gets the list of configuration IDs defined for a specific vault.
     * @param _vaultId The ID of the vault instance.
     * @return configIds Array of configuration IDs. Note: Includes invalid/cancelled ones.
     */
    function getVaultConfigurationIds(uint256 _vaultId) external view whenVaultExists(_vaultId) returns (uint256[] memory) {
        return vaults[_vaultId].configurationIds;
    }

    /**
     * @notice Gets the details of a specific configuration within a vault.
     * @param _vaultId The ID of the vault instance.
     * @param _configId The ID of the configuration.
     * @return config The VaultConfiguration struct.
     */
    function getVaultConfigurationDetails(uint256 _vaultId, uint256 _configId) external view whenVaultExists(_vaultId) returns (VaultConfiguration memory) {
        require(vaults[_vaultId].configurations[_configId].configId != 0, "Configuration does not exist");
        return vaults[_vaultId].configurations[_configId];
    }

     /**
     * @notice Gets the current internal balance of a specific ERC20 token within a vault instance.
     * @param _vaultId The ID of the vault instance.
     * @param _token The address of the ERC20 token.
     * @return balance The amount of the token held in the vault.
     */
    function getVaultCurrentERC20Balance(uint256 _vaultId, address _token) external view whenVaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].currentERC20Balances[_token];
    }

    /**
     * @notice Gets the list of ERC721 token IDs held within a vault instance for a specific token contract.
     * Note: This list might be inaccurate after emergency withdrawals in the current simplified implementation.
     * @param _vaultId The ID of the vault instance.
     * @param _token The address of the ERC721 token contract.
     * @return tokenIds Array of token IDs held.
     */
    function getVaultCurrentERC721Tokens(uint256 _vaultId, address _token) external view whenVaultExists(_vaultId) returns (uint256[] memory) {
        return vaults[_vaultId].currentERC721Tokens[_token];
    }

     /**
     * @notice Gets the list of oracle condition types allowed by the admin.
     * Note: Iterating over mappings is not possible directly. This requires a helper array or emitting events.
     * This function is a placeholder - a real implementation would need a better way to expose this.
     * For simplicity, we return a hardcoded placeholder or require external tracking of allowed types.
     * Returning keys from a mapping is not standard Solidity. A common pattern is to use an array + mapping.
     * Let's add an internal array for this.
     */
    // Internal array to track allowed oracle condition types (to make getAllowedOracleConditionTypes possible)
    uint256[] private _allowedOracleConditionTypesArray;
    mapping(uint256 => bool) private _allowedOracleConditionTypesArrayHelper; // Helper to prevent duplicates

     /**
     * @notice Adds an allowed oracle condition type and updates the internal array. Only callable by owner.
     * @param _conditionType The oracle condition type ID to allow.
     */
    function addAllowedOracleConditionType(uint256 _conditionType) override external onlyOwner {
        require(!allowedOracleConditionTypes[_conditionType], "Condition type already allowed");
        allowedOracleConditionTypes[_conditionType] = true;
        if (!_allowedOracleConditionTypesArrayHelper[_conditionType]) {
             _allowedOracleConditionTypesArray.push(_conditionType);
             _allowedOracleConditionTypesArrayHelper[_conditionType] = true;
        }
        emit AllowedOracleConditionTypeAdded(_conditionType);
    }

    /**
     * @notice Removes an allowed oracle condition type and updates the internal array. Only callable by owner.
     * @param _conditionType The oracle condition type ID to remove.
     */
    function removeAllowedOracleConditionType(uint256 _conditionType) override external onlyOwner {
        require(allowedOracleConditionTypes[_conditionType], "Condition type not currently allowed");
        allowedOracleConditionTypes[_conditionType] = false;
        // Removing from _allowedOracleConditionTypesArray is gas intensive (requires finding index).
        // We'll leave it in the array but rely on the `allowedOracleConditionTypes` mapping for actual checks.
        // A production contract might rebuild the array periodically or use a different structure.
        _allowedOracleConditionTypesArrayHelper[_conditionType] = false; // Mark as not currently allowed

        emit AllowedOracleConditionTypeRemoved(_conditionType);
    }

    /**
     * @notice Gets the list of oracle condition types allowed by the admin.
     * Note: The returned array might contain types that are no longer allowed (check mapping).
     * @return conditionTypes Array of allowed condition types.
     */
    function getAllowedOracleConditionTypes() external view returns (uint256[] memory) {
        // Filter out types marked as not allowed in the mapping
        uint256[] memory activeTypes = new uint256[](_allowedOracleConditionTypesArray.length);
        uint256 count = 0;
        for(uint256 i = 0; i < _allowedOracleConditionTypesArray.length; i++) {
            uint256 typeId = _allowedOracleConditionTypesArray[i];
            if (allowedOracleConditionTypes[typeId]) { // Check against the mapping
                 activeTypes[count] = typeId;
                 count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
             result[i] = activeTypes[i];
        }
        return result;
    }


     /**
     * @notice Checks the conditions of a specific configuration without collapsing the vault state.
     * Useful for users to see if a configuration *would* win the measurement.
     * NOTE: Calling an oracle from a view function might fail or be inconsistent depending on the oracle implementation and gas limits.
     * @param _vaultId The ID of the vault instance.
     * @param _configId The ID of the configuration.
     * @return conditionsMet True if all conditions for this config are met based on current state/time/oracle data.
     */
    function checkConfigurationConditions(uint256 _vaultId, uint256 _configId)
        external
        view
        whenVaultExists(_vaultId)
        whenVaultNotCollapsed(_vaultId) // Can only check conditions on uncollapsed vaults
        returns (bool conditionsMet)
    {
        Vault storage currentVault = vaults[_vaultId];
        VaultConfiguration storage config = currentVault.configurations[_configId];

        require(config.configId != 0, "Configuration does not exist");
        require(config.isValid, "Configuration is not valid");

        conditionsMet = true; // Assume true until a condition fails

        // 1. Time Condition
        if (block.timestamp < config.unlockTime) {
            conditionsMet = false;
        }

        // 2. Entanglement Key Condition (requires the recipient to hold the specific NFT)
        if (conditionsMet && config.requiredEntanglementKeyContract != address(0) && config.requiredEntanglementKeyId != 0) {
             if (entanglementKeyContract == address(0)) { // Check if global key contract is set
                  conditionsMet = false; // Cannot check if key contract is not set
             } else {
                 try IERC721(entanglementKeyContract).ownerOf(config.requiredEntanglementKeyId) returns (address nftOwner) {
                      if (nftOwner != config.intendedRecipient) {
                          conditionsMet = false;
                      }
                 } catch {
                      // If ownerOf fails (e.g., token doesn't exist), condition is not met
                      conditionsMet = false;
                 }
             }
        }

        // 3. Oracle Conditions
        if (conditionsMet && config.oracleConditions.length > 0) {
            if (oracleAddress == address(0)) { // Check if global oracle is set
                 conditionsMet = false; // Cannot check if oracle is not set
            } else {
                 for (uint256 j = 0; j < config.oracleConditions.length; j++) {
                      OracleCondition memory oCond = config.oracleConditions[j];
                      // Check if oracle condition type is allowed by admin
                       if (!allowedOracleConditionTypes[oCond.conditionType]) {
                            conditionsMet = false; // Cannot check if type is not allowed
                            break;
                       }
                      try IQuantumOracle(oracleAddress).checkCondition(oCond.conditionType, oCond.data) returns (bool oracleResult) {
                           if (!oracleResult) {
                               conditionsMet = false;
                               break; // If any oracle condition fails, break inner loop
                           }
                      } catch {
                           // If oracle call fails, condition is not met
                           conditionsMet = false;
                           break; // If oracle call fails, break inner loop
                      }
                 }
            }
        }

        return conditionsMet;
    }

    // Inherited from Ownable:
    // - owner()
    // - transferOwnership(address newOwner)
    // - renounceOwnership()

    // Total functions (excluding inherited owner(), but including transferOwnership, renounceOwnership):
    // 27 (Custom + Ownable) = 29 total public/external functions listed

}
```