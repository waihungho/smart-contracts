Okay, let's create a smart contract concept inspired by quantum mechanics principles like superposition, observation, and entanglement, applied metaphorically to asset locking and release conditions. We'll call it a "Quantum Vault".

The core idea is that assets are locked in a vault whose "state" is initially uncertain ("superposition") regarding its unlockability. This state can only be determined or "collapsed" by an explicit "observation" function call, which measures various conditions. The conditions themselves can be complex, involving time, external triggers, data derived from block hashes (as a form of 'environmental interaction'), and even the state of other vaults ('entanglement').

This is a creative, advanced concept going beyond simple timelocks or multi-sigs by introducing a required *interaction* to finalize the unlock conditions based on the state *at the time of interaction*.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Contract Purpose:** A vault for locking ETH or ERC20 tokens under complex, multi-conditional unlock criteria that are finalized upon a specific "state observation" or "collapse" event.
2.  **Core Concepts:**
    *   **Vaults:** Individual deposit instances with unique IDs.
    *   **Conditions:** A set of criteria (`VaultConditions` struct) defined by the depositor (e.g., min duration, required observations, external data thresholds, entanglement).
    *   **State:** The internal state of a vault (`VaultState` struct), including deposit details, current observation count, and a `stateCollapsed` flag.
    *   **Observation (`observeState`):** A function callable by a designated observer (or potentially anyone, depending on configuration) that updates the vault's state variables (like observation count) without necessarily collapsing the state.
    *   **Collapse (`tryCollapseState`):** A function callable by anyone that attempts to finalize the vault's state. If prerequisites are met (e.g., minimum observations reached, minimum time elapsed), it calculates and records final state factors (like a block hash-derived value) and checks *all* conditions to determine if the vault becomes immediately unlockable. This is the "measurement" that collapses the "superposition" of potential unlock states.
    *   **Entanglement:** A condition where one vault's unlock status is partially dependent on the `stateCollapsed` status of another specified vault.
3.  **Access Control:** Owner for critical admin tasks (like setting global parameters if any), Depositor for managing their specific vault's conditions (before collapse), Designated Observer for `observeState`, Anyone for `tryCollapseState` and `withdraw`.
4.  **Assets:** Handles native ETH and generic ERC20 tokens.

**Function Summary:**

*   **Deposit & Vault Management:**
    *   `depositETH`: Deposit Ether and create a vault.
    *   `depositERC20`: Deposit ERC20 tokens and create a vault.
    *   `setUnlockConditions`: Set or update the complex unlock conditions for a vault (only by depositor, before collapse).
    *   `updateConditionMinDuration`: Update a single condition parameter.
    *   `updateConditionObserverAddress`: Update a single condition parameter.
    *   `updateConditionMinObserverCount`: Update a single condition parameter.
    *   `updateConditionBlockHashThreshold`: Update a single condition parameter.
    *   `updateConditionEntangledVaultId`: Update a single condition parameter (requires specific checks).
*   **State Interaction:**
    *   `observeState`: Record an observation on a vault (by designated observer, before collapse).
    *   `tryCollapseState`: Attempt to collapse the vault's state, finalize conditions based on current state and block data, and determine if it's unlocked.
*   **Withdrawal:**
    *   `withdraw`: Withdraw assets from an unlocked and collapsed vault.
*   **Query (Read-Only):**
    *   `getVaultState`: Get the full state struct of a vault.
    *   `getVaultConditions`: Get the conditions struct of a vault.
    *   `getCurrentObservationCount`: Get the current observation count.
    *   `getBlockHashFactor`: Get the block hash derived factor (0 if not collapsed).
    *   `isStateCollapsed`: Check if the vault's state has been collapsed.
    *   `isVaultUnlocked`: Check if the vault is currently unlocked (requires state to be collapsed).
    *   `checkVaultStatus`: Check if a vault *would be* unlocked if state were collapsed *now* (useful for pre-checking, but the final check happens in `tryCollapseState`).
    *   `getDepositor`: Get the depositor's address for a vault.
    *   `getAssetAndAmount`: Get the asset address and deposited amount.
    *   `getDepositTime`: Get the deposit timestamp.
    *   `getEntangledVaultId`: Get the ID of an entangled vault.
    *   `getNextVaultId`: Get the ID for the next new vault.
    *   `getTotalDepositedByAsset`: Get the total amount deposited by a user for a specific asset across all their vaults.
*   **Admin (Owner-only):**
    *   `setEntropySource`: Set the address used as an entropy source for block hash calculations.
    *   `ownerForceCollapse`: Force the collapse of a vault's state under exceptional circumstances.
    *   `renounceOwnership`: (Inherited from Ownable)
    *   `transferOwnership`: (Inherited from Ownable)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Note: Using blockhash(block.number - 1) is not truly random and can be influenced by miners
// within a limited window. The 'entropySourceAddress' adds another layer of variability,
// but the system should not rely on this for high-security randomness. It's used here
// primarily for the "quantum" analogy of environmental interaction influencing state collapse.

/**
 * @title QuantumVault
 * @dev A contract inspired by quantum mechanics principles for complex, multi-conditional asset locking.
 * Assets are held in vaults whose unlock state depends on various factors resolved upon a 'state collapse' event.
 */
contract QuantumVault is Ownable {
    using SafeMath for uint256;

    // --- Structs ---

    /**
     * @dev Defines the complex conditions required for a vault to become unlockable.
     * These are set by the depositor (before state collapse).
     */
    struct VaultConditions {
        uint48 minLockDuration;         // Minimum time (in seconds) since deposit before unlock is possible
        address observerAddress;        // A specific address required to perform observations
        uint16 minObserverUnlockCount;  // Minimum number of observations required for potential unlock
        uint256 blockHashFactorThreshold; // A threshold for a value derived from a block hash and entropy
        uint256 entangledVaultId;       // Another vault ID this vault's unlock state is potentially entangled with (0 means no entanglement)
    }

    /**
     * @dev Represents the state of a single vault.
     */
    struct VaultState {
        address depositor;           // The address that created the vault
        address asset;               // The asset address (address(0) for ETH)
        uint256 amount;              // The amount of the asset locked
        uint48 depositTime;          // The timestamp when the vault was created
        VaultConditions conditions;  // The unlock conditions set for this vault
        uint16 observationCount;     // The number of times the observer has interacted
        uint256 blockHashFactor;     // A factor derived from blockhash and entropy, recorded upon state collapse
        bool stateCollapsed;         // True if the vault's state has been finalized/measured
        bool unlocked;               // True if the vault meets all conditions and is ready for withdrawal
    }

    // --- State Variables ---

    uint256 private nextVaultId; // Counter for unique vault IDs
    mapping(uint256 => VaultState) public vaults; // Stores the state of each vault
    mapping(address => mapping(address => uint256)) private totalDepositedByAsset; // Tracks total amount deposited per user/asset

    // Address used as an additional entropy source for block hash factor calculation
    address public entropySourceAddress;

    // --- Events ---

    event VaultDeposited(uint256 indexed vaultId, address indexed depositor, address indexed asset, uint256 amount, uint48 depositTime);
    event ConditionsSet(uint256 indexed vaultId, VaultConditions conditions);
    event StateObserved(uint256 indexed vaultId, address indexed observer, uint16 observationCount);
    event StateCollapsed(uint256 indexed vaultId, uint256 blockHashFactor, bool unlocked);
    event VaultUnlocked(uint256 indexed vaultId);
    event VaultWithdrawn(uint256 indexed vaultId, uint256 amount);
    event EntropySourceSet(address indexed oldSource, address indexed newSource);
    event OwnerForceCollapsed(uint256 indexed vaultId);

    // --- Constructor ---

    constructor(address _entropySourceAddress) Ownable(msg.sender) {
        require(_entropySourceAddress != address(0), "Entropy source cannot be zero address");
        entropySourceAddress = _entropySourceAddress;
        emit EntropySourceSet(address(0), _entropySourceAddress);
    }

    // --- Modifiers ---

    modifier onlyDepositor(uint256 _vaultId) {
        require(vaults[_vaultId].depositor == msg.sender, "Only depositor can call this function");
        _;
    }

    modifier onlyObserver(uint256 _vaultId) {
        require(vaults[_vaultId].conditions.observerAddress == address(0) || vaults[_vaultId].conditions.observerAddress == msg.sender, "Only designated observer can call this function");
        _;
    }

    modifier vaultExists(uint256 _vaultId) {
        require(vaults[_vaultId].depositor != address(0), "Vault does not exist");
        _;
    }

    modifier stateNotCollapsed(uint256 _vaultId) {
        require(!vaults[_vaultId].stateCollapsed, "Vault state is already collapsed");
        _;
    }

    modifier stateCollapsed(uint256 _vaultId) {
        require(vaults[_vaultId].stateCollapsed, "Vault state is not yet collapsed");
        _;
    }

    modifier vaultUnlocked(uint256 _vaultId) {
        require(vaults[_vaultId].unlocked, "Vault is not unlocked");
        _;
    }

    // --- Deposit Functions ---

    /**
     * @dev Deposits native ETH and creates a new vault.
     * @return The ID of the newly created vault.
     */
    function depositETH() external payable returns (uint256) {
        require(msg.value > 0, "Cannot deposit zero ETH");
        uint256 vaultId = nextVaultId++;
        vaults[vaultId] = VaultState({
            depositor: msg.sender,
            asset: address(0), // Use address(0) for ETH
            amount: msg.value,
            depositTime: uint48(block.timestamp), // Use uint48 to save gas
            conditions: VaultConditions(0, address(0), 0, 0, 0), // Default conditions
            observationCount: 0,
            blockHashFactor: 0,
            stateCollapsed: false,
            unlocked: false
        });
        totalDepositedByAsset[msg.sender][address(0)] = totalDepositedByAsset[msg.sender][address(0)].add(msg.value);
        emit VaultDeposited(vaultId, msg.sender, address(0), msg.value, uint48(block.timestamp));
        return vaultId;
    }

    /**
     * @dev Deposits ERC20 tokens and creates a new vault.
     * Requires the contract to have been approved to transfer the tokens.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @return The ID of the newly created vault.
     */
    function depositERC20(address _token, uint256 _amount) external returns (uint256) {
        require(_amount > 0, "Cannot deposit zero tokens");
        require(_token != address(0), "Cannot deposit zero address as token");
        require(_token != address(this), "Cannot deposit contract's own address as token"); // Prevent locking contract itself

        // Transfer tokens from the depositor to the contract
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 vaultId = nextVaultId++;
        vaults[vaultId] = VaultState({
            depositor: msg.sender,
            asset: _token,
            amount: _amount,
            depositTime: uint48(block.timestamp),
            conditions: VaultConditions(0, address(0), 0, 0, 0), // Default conditions
            observationCount: 0,
            blockHashFactor: 0,
            stateCollapsed: false,
            unlocked: false
        });
        totalDepositedByAsset[msg.sender][_token] = totalDepositedByAsset[msg.sender][_token].add(_amount);
        emit VaultDeposited(vaultId, msg.sender, _token, _amount, uint48(block.timestamp));
        return vaultId;
    }

    // --- Condition Management Functions ---

    /**
     * @dev Sets or updates the full set of unlock conditions for a vault.
     * Callable only by the depositor before the state is collapsed.
     * @param _vaultId The ID of the vault.
     * @param _conditions The new set of conditions.
     */
    function setUnlockConditions(uint256 _vaultId, VaultConditions memory _conditions)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        // Validate entanglement: cannot entangle with itself, entangled vault must exist (basic check)
        if (_conditions.entangledVaultId != 0) {
             require(_conditions.entangledVaultId != _vaultId, "Cannot entangle vault with itself");
             require(vaults[_conditions.entangledVaultId].depositor != address(0), "Entangled vault ID must exist");
             // Optional: Add more complex entanglement rules, e.g., requires permission from entangled vault depositor
        }

        vaults[_vaultId].conditions = _conditions;
        emit ConditionsSet(_vaultId, _conditions);
    }

    /**
     * @dev Updates only the minimum lock duration condition.
     * @param _vaultId The ID of the vault.
     * @param _newDuration The new minimum lock duration in seconds.
     */
    function updateConditionMinDuration(uint256 _vaultId, uint48 _newDuration)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        vaults[_vaultId].conditions.minLockDuration = _newDuration;
        emit ConditionsSet(_vaultId, vaults[_vaultId].conditions); // Emit full conditions for transparency
    }

    /**
     * @dev Updates only the observer address condition.
     * @param _vaultId The ID of the vault.
     * @param _newObserver The new observer address.
     */
    function updateConditionObserverAddress(uint256 _vaultId, address _newObserver)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        vaults[_vaultId].conditions.observerAddress = _newObserver;
         emit ConditionsSet(_vaultId, vaults[_vaultId].conditions);
    }

     /**
     * @dev Updates only the minimum observation count condition.
     * @param _vaultId The ID of the vault.
     * @param _newCount The new minimum observation count.
     */
    function updateConditionMinObserverCount(uint256 _vaultId, uint16 _newCount)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        vaults[_vaultId].conditions.minObserverUnlockCount = _newCount;
         emit ConditionsSet(_vaultId, vaults[_vaultId].conditions);
    }

     /**
     * @dev Updates only the block hash factor threshold condition.
     * @param _vaultId The ID of the vault.
     * @param _newThreshold The new block hash factor threshold.
     */
    function updateConditionBlockHashThreshold(uint256 _vaultId, uint256 _newThreshold)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        vaults[_vaultId].conditions.blockHashFactorThreshold = _newThreshold;
         emit ConditionsSet(_vaultId, vaults[_vaultId].conditions);
    }

     /**
     * @dev Updates only the entangled vault ID condition.
     * @param _vaultId The ID of the vault.
     * @param _newEntangledVaultId The new entangled vault ID (0 for no entanglement).
     */
    function updateConditionEntangledVaultId(uint256 _vaultId, uint256 _newEntangledVaultId)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
         // Validate entanglement: cannot entangle with itself, entangled vault must exist (basic check)
        if (_newEntangledVaultId != 0) {
             require(_newEntangledVaultId != _vaultId, "Cannot entangle vault with itself");
             require(vaults[_newEntangledVaultId].depositor != address(0), "Entangled vault ID must exist");
        }
        vaults[_vaultId].conditions.entangledVaultId = _newEntangledVaultId;
         emit ConditionsSet(_vaultId, vaults[_vaultId].conditions);
    }


    // --- State Interaction Functions ---

    /**
     * @dev Records an observation for a vault.
     * Callable by the designated observer (or anyone if observerAddress is address(0)) before state collapse.
     * Increments the observation counter.
     * @param _vaultId The ID of the vault.
     */
    function observeState(uint256 _vaultId)
        external
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
        onlyObserver(_vaultId) // Use the modifier
    {
        vaults[_vaultId].observationCount = vaults[_vaultId].observationCount.add(1);
        emit StateObserved(_vaultId, msg.sender, vaults[_vaultId].observationCount);
    }

    /**
     * @dev Attempts to collapse the state of a vault.
     * This function can be called by anyone. If preliminary conditions are met (time, observations),
     * it finalizes the state by calculating a block hash factor and then checks all conditions
     * to determine if the vault becomes unlocked.
     * @param _vaultId The ID of the vault.
     */
    function tryCollapseState(uint256 _vaultId)
        external
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        VaultState storage vault = vaults[_vaultId];
        VaultConditions storage conditions = vault.conditions;

        // --- Check preliminary conditions for state collapse ---
        // 1. Minimum time elapsed
        require(block.timestamp >= vault.depositTime.add(conditions.minLockDuration), "Minimum lock duration not met");

        // 2. Minimum observation count met (if observerAddress is set and count > 0)
        if (conditions.observerAddress != address(0) && conditions.minObserverUnlockCount > 0) {
             require(vault.observationCount >= conditions.minObserverUnlockCount, "Minimum observation count not met");
        }

        // --- Collapse the state: Record block hash factor and set collapsed flag ---
        // Get blockhash from the previous block for slight decentralization,
        // combine with entropy source and vault ID for a unique factor.
        // Note: blockhash(block.number - 1) is used here, block.number can't be used.
        // This value is only available for the last 256 blocks.
        uint256 hash = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), entropySourceAddress, _vaultId, block.timestamp)));
        vault.blockHashFactor = hash;
        vault.stateCollapsed = true;

        // --- Final Unlock Check after state collapse ---
        bool meetsAllConditions = true;

        // 1. Block Hash Factor Threshold
        if (conditions.blockHashFactorThreshold > 0 && vault.blockHashFactor < conditions.blockHashFactorThreshold) {
             meetsAllConditions = false;
        }

        // 2. Entanglement Condition
        if (conditions.entangledVaultId != 0) {
            // Check if the entangled vault exists and is already collapsed.
            // This creates a dependency: this vault can only unlock if the entangled one is collapsed.
            VaultState storage entangledVault = vaults[conditions.entangledVaultId];
            if (entangledVault.depositor == address(0) || !entangledVault.stateCollapsed) {
                meetsAllConditions = false; // Entangled vault doesn't exist or isn't collapsed
            }
            // Optional: Could add dependency on entangledVault.unlocked instead of .stateCollapsed
            // if (entangledVault.depositor == address(0) || !entangledVault.unlocked) {
            //     meetsAllConditions = false;
            // }
        }

        // If all conditions are met, mark as unlocked
        if (meetsAllConditions) {
            vault.unlocked = true;
            emit VaultUnlocked(_vaultId);
        }

        emit StateCollapsed(_vaultId, vault.blockHashFactor, vault.unlocked);
    }

    // --- Withdrawal Function ---

    /**
     * @dev Allows the depositor to withdraw assets from an unlocked vault.
     * @param _vaultId The ID of the vault.
     */
    function withdraw(uint256 _vaultId)
        external
        onlyDepositor(_vaultId)
        vaultExists(_vaultId)
        stateCollapsed(_vaultId) // Can only withdraw after state is collapsed
        vaultUnlocked(_vaultId)   // Can only withdraw if state collapsed to 'unlocked'
    {
        VaultState storage vault = vaults[_vaultId];
        uint256 amount = vault.amount;
        address asset = vault.asset;
        address depositor = vault.depositor; // Store locally before state is cleared

        // Clear the vault state to prevent double withdrawal
        delete vaults[_vaultId];

        // Update total deposited tracking
        totalDepositedByAsset[depositor][asset] = totalDepositedByAsset[depositor][asset].sub(amount);

        // Transfer assets
        if (asset == address(0)) {
            // ETH withdrawal
            (bool success, ) = payable(depositor).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(asset);
            token.transfer(depositor, amount);
        }

        emit VaultWithdrawn(_vaultId, amount);
    }

    // --- Query Functions (Read-Only) ---

    /**
     * @dev Gets the full state of a vault.
     * @param _vaultId The ID of the vault.
     * @return The VaultState struct.
     */
    function getVaultState(uint256 _vaultId) external view vaultExists(_vaultId) returns (VaultState memory) {
        return vaults[_vaultId];
    }

    /**
     * @dev Gets the unlock conditions for a vault.
     * @param _vaultId The ID of the vault.
     * @return The VaultConditions struct.
     */
    function getVaultConditions(uint256 _vaultId) external view vaultExists(_vaultId) returns (VaultConditions memory) {
         return vaults[_vaultId].conditions;
    }

    /**
     * @dev Gets the current number of observations recorded for a vault.
     * @param _vaultId The ID of the vault.
     * @return The observation count.
     */
    function getCurrentObservationCount(uint256 _vaultId) external view vaultExists(_vaultId) returns (uint16) {
        return vaults[_vaultId].observationCount;
    }

    /**
     * @dev Gets the block hash derived factor recorded upon state collapse.
     * @param _vaultId The ID of the vault.
     * @return The block hash factor (0 if state not collapsed).
     */
    function getBlockHashFactor(uint256 _vaultId) external view vaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].blockHashFactor;
    }

    /**
     * @dev Checks if the vault's state has been collapsed.
     * @param _vaultId The ID of the vault.
     * @return True if state is collapsed, false otherwise.
     */
    function isStateCollapsed(uint256 _vaultId) external view vaultExists(_vaultId) returns (bool) {
        return vaults[_vaultId].stateCollapsed;
    }

     /**
     * @dev Checks if the vault is unlocked and ready for withdrawal.
     * Requires the state to be collapsed first.
     * @param _vaultId The ID of the vault.
     * @return True if unlocked, false otherwise.
     */
    function isVaultUnlocked(uint256 _vaultId) external view vaultExists(_vaultId) returns (bool) {
        return vaults[_vaultId].unlocked;
    }

    /**
     * @dev Performs a read-only check to see if the vault conditions *would* be met
     * IF the state were collapsed *now* with a hypothetical block hash factor.
     * Useful for pre-checking but does NOT guarantee unlock until tryCollapseState is called.
     * Does NOT check block hash factor threshold or entanglement as they depend on the final state.
     * @param _vaultId The ID of the vault.
     * @return True if time and observation conditions are met, false otherwise.
     */
    function checkVaultStatus(uint256 _vaultId) external view vaultExists(_vaultId) returns (bool) {
         VaultState storage vault = vaults[_vaultId];
         VaultConditions storage conditions = vault.conditions;

         // Check time elapsed
         if (block.timestamp < vault.depositTime.add(conditions.minLockDuration)) {
              return false;
         }

         // Check minimum observation count (if applicable)
         if (conditions.observerAddress != address(0) && conditions.minObserverUnlockCount > 0) {
              if (vault.observationCount < conditions.minObserverUnlockCount) {
                return false;
              }
         }

         // Note: This view function cannot predict the final blockHashFactor or check entanglement state reliably.
         // It's a partial check. The definitive check happens in tryCollapseState.

         return true; // Conditions met based on current time and observations
    }

     /**
     * @dev Gets the depositor's address for a vault.
     * @param _vaultId The ID of the vault.
     * @return The depositor address.
     */
    function getDepositor(uint256 _vaultId) external view vaultExists(_vaultId) returns (address) {
        return vaults[_vaultId].depositor;
    }

    /**
     * @dev Gets the asset address and amount stored in a vault.
     * @param _vaultId The ID of the vault.
     * @return asset The asset address (address(0) for ETH).
     * @return amount The deposited amount.
     */
    function getAssetAndAmount(uint256 _vaultId) external view vaultExists(_vaultId) returns (address asset, uint256 amount) {
        VaultState storage vault = vaults[_vaultId];
        return (vault.asset, vault.amount);
    }

    /**
     * @dev Gets the deposit timestamp for a vault.
     * @param _vaultId The ID of the vault.
     * @return The deposit timestamp (uint48).
     */
    function getDepositTime(uint256 _vaultId) external view vaultExists(_vaultId) returns (uint48) {
        return vaults[_vaultId].depositTime;
    }

     /**
     * @dev Gets the ID of the entangled vault for a given vault.
     * @param _vaultId The ID of the vault.
     * @return The entangled vault ID (0 if none).
     */
    function getEntangledVaultId(uint256 _vaultId) external view vaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].conditions.entangledVaultId;
    }

     /**
     * @dev Gets the ID that will be assigned to the next new vault.
     * @return The next available vault ID.
     */
    function getNextVaultId() external view returns (uint256) {
        return nextVaultId;
    }

     /**
     * @dev Gets the total amount deposited by a user for a specific asset.
     * This includes assets in all their non-withdrawn vaults.
     * @param _user The user's address.
     * @param _asset The asset address (address(0) for ETH).
     * @return The total deposited amount.
     */
    function getTotalDepositedByAsset(address _user, address _asset) external view returns (uint256) {
        return totalDepositedByAsset[_user][_asset];
    }

    // --- Admin Functions (Owner-only) ---

    /**
     * @dev Sets the address used as an additional entropy source for block hash calculations.
     * Callable only by the contract owner.
     * @param _newSource The new entropy source address.
     */
    function setEntropySource(address _newSource) external onlyOwner {
        require(_newSource != address(0), "Entropy source cannot be zero address");
        address oldSource = entropySourceAddress;
        entropySourceAddress = _newSource;
        emit EntropySourceSet(oldSource, _newSource);
    }

    /**
     * @dev Forces the state collapse of a vault under exceptional circumstances.
     * This is a powerful admin function to be used cautiously, e.g., if a vault is stuck.
     * It does NOT necessarily unlock the vault, only finalizes its state.
     * Callable only by the contract owner.
     * @param _vaultId The ID of the vault to force collapse.
     */
    function ownerForceCollapse(uint256 _vaultId)
        external
        onlyOwner
        vaultExists(_vaultId)
        stateNotCollapsed(_vaultId)
    {
        VaultState storage vault = vaults[_vaultId];

        // Calculate and record block hash factor
        uint256 hash = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), entropySourceAddress, _vaultId, block.timestamp)));
        vault.blockHashFactor = hash;
        vault.stateCollapsed = true;

        // Note: This *does not* perform the full unlock condition check.
        // The vault's `unlocked` status remains false unless conditions are checked later
        // by a *subsequent* call to `tryCollapseState` (which would now run
        // on an already collapsed state, which is not the primary intended flow,
        // but the checks are structured to allow it, although `stateNotCollapsed`
        // modifier prevents it. The intent of force collapse is state finalization,
        // not necessarily forced unlock. A manual check via `isVaultUnlocked` or
        // a subsequent, slightly modified `tryCollapseState` call might be needed
        // if the owner wants to *also* force the unlock check).
        // For simplicity, this just forces the collapse flag and factor.
        // A subsequent *depositor* call to `withdraw` will still require `vault.unlocked` to be true.

        // If the owner needs to force unlock, they would need a separate, more powerful function,
        // which is deliberately omitted here to maintain some integrity of the vault logic.
        // Forcing collapse just moves it from 'superposition' to a definite, measured state.

        emit OwnerForceCollapsed(_vaultId);
        // Emit StateCollapsed with unlocked=false, as force collapse doesn't guarantee unlock
        emit StateCollapsed(_vaultId, vault.blockHashFactor, false);
    }

    // Inherited from Ownable:
    // function owner() public view virtual returns (address)
    // function renounceOwnership() public virtual onlyOwner
    // function transferOwnership(address newOwner) public virtual onlyOwner
}
```