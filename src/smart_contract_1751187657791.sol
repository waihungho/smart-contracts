Okay, here is a smart contract concept called `QuantumVault`. It simulates some abstract concepts from quantum mechanics like "superposition" (multiple potential outcomes for deposited funds) and "observation" (collapsing the state to a single outcome), plus an "entanglement" feature where observing one vault affects another.

**Important Note:** This contract simulates quantum concepts metaphorically within the deterministic environment of the blockchain. It does *not* involve actual quantum computing or leverage quantum phenomena. The "randomness" for state collapse uses standard on-chain methods (`block.timestamp`, `block.difficulty`, `msg.sender`, and a provided `_seed`) which are *not* truly random or secure against sophisticated attacks (like miner front-running) for high-value applications. This is a conceptual demonstration of complex state management and interaction patterns.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **License and Version:** SPDX license and Solidity version.
2.  **Imports:** Necessary libraries (e.g., ReentrancyGuard).
3.  **Error Definitions:** Custom errors for clarity.
4.  **Enums:** `VaultStatus` (Superposition, Observed, Withdrawn).
5.  **Structs:**
    *   `PotentialState`: Represents a possible outcome amount.
    *   `Vault`: Stores vault data (owner, states, status, balances, entanglement, etc.).
6.  **State Variables:**
    *   Mapping `vaults` (uint256 ID -> Vault struct).
    *   `vaultCounter` (unique ID generator).
    *   Mapping `vaultBalances` (uint256 ID -> uint256 balance) to track ETH per vault.
    *   Mapping `entangledPairs` (uint256 ID -> uint256 partner ID).
    *   Mapping `userToVaults` (address -> uint256[] list of vault IDs). (Note: Reading full arrays can be expensive).
7.  **Events:** For key actions (creation, deposit, observation, withdrawal, entanglement, etc.).
8.  **Modifiers:** Access control and state checks (`onlyVaultOwner`, `whenInStatus`, `whenNotInStatus`, `whenNotEntangled`, `whenEntangled`).
9.  **Functions (>= 20):**
    *   **Vault Creation & Management:**
        *   `createVault`: Creates a new vault with initial potential outcomes.
        *   `addPotentialState`: Adds a potential outcome before observation.
        *   `removePotentialState`: Removes a potential outcome before observation.
        *   `transferVaultOwnership`: Transfers ownership of a vault.
        *   `revokeVaultOwnership`: Revokes ownership (sets to zero address).
        *   `setObservationDelay`: Sets a minimum time before observation is possible.
    *   **Fund Handling:**
        *   `deposit`: Deposits ETH into a vault.
        *   `withdraw`: Withdraws funds based on the observed state.
        *   `emergencyWithdrawPartial`: Allows withdrawing a fraction regardless of state (e.g., if observed state is 0).
    *   **Quantum State Simulation:**
        *   `enterSuperposition`: Transitions vault to Superposition status.
        *   `observeVault`: Collapses the state of a single vault based on seed/entropy.
        *   `observeEntangledPair`: Collapses the state of an entangled pair, correlating outcomes.
    *   **Entanglement Management:**
        *   `entangleVaults`: Links two vaults.
        *   `disentangleVaults`: Unlinks two vaults.
    *   **Read Functions:**
        *   `getVaultInfo`: Retrieves core vault data.
        *   `getPotentialStates`: Retrieves the list of potential outcomes.
        *   `getObservedAmount`: Retrieves the final observed amount.
        *   `getVaultStatus`: Retrieves the current status.
        *   `getVaultBalance`: Retrieves the ETH balance associated with a vault.
        *   `isEntangled`: Checks if a vault is entangled.
        *   `getEntangledPartner`: Retrieves the partner ID of an entangled vault.
        *   `canObserve`: Checks if observation conditions (like delay) are met.
        *   `getUserVaults`: Gets the list of vaults owned by an address.
        *   `getTotalVaultCount`: Gets the total number of vaults created.

---

**Function Summary:**

1.  `createVault(uint256[] memory _potentialAmounts)`: Creates a new vault, setting its initial potential withdrawal amounts. Caller is the owner. Returns the new vault ID.
2.  `deposit(uint256 _vaultId)`: Allows the owner (or potentially anyone, decide design) to deposit ETH into a specific vault. Vault must not be Observed or Withdrawn.
3.  `addPotentialState(uint256 _vaultId, uint256 _amount)`: Allows the owner to add another potential outcome amount to a vault *before* it enters Superposition.
4.  `removePotentialState(uint256 _vaultId, uint256 _index)`: Allows the owner to remove a potential outcome by index *before* it enters Superposition.
5.  `transferVaultOwnership(uint256 _vaultId, address _newOwner)`: Transfers ownership of a vault to a new address.
6.  `revokeVaultOwnership(uint256 _vaultId)`: Sets vault ownership to the zero address. Can only be done if not entangled.
7.  `setObservationDelay(uint256 _vaultId, uint64 _delayInSeconds)`: Sets a minimum time relative to `enterSuperposition` before `observeVault` or `observeEntangledPair` can be called.
8.  `enterSuperposition(uint256 _vaultId)`: Transitions the vault's state from Created to Superposition. This finalizes the list of potential states.
9.  `observeVault(uint256 _vaultId, uint256 _seed)`: Triggers the state collapse for a single vault. Requires the vault to be in Superposition, meets observation delay, and not be entangled. The outcome is determined using block data and the provided seed, setting the `observedAmount` and status to Observed.
10. `entangleVaults(uint256 _vaultId1, uint256 _vaultId2)`: Links two vaults together. Both must be in Superposition, not already entangled, and have the *same number* of potential states for anti-correlation to work simply.
11. `disentangleVaults(uint256 _vaultId1, uint256 _vaultId2)`: Breaks the entanglement link between two vaults. Both must be in Superposition or Created status.
12. `observeEntangledPair(uint256 _vaultId1, uint256 _vaultId2, uint256 _seed)`: Triggers state collapse for two entangled vaults simultaneously. Both must be entangled, in Superposition, and meet observation delays. The outcome of the second vault is determined based on an anti-correlation principle relative to the first vault's outcome. Both statuses change to Observed.
13. `withdraw(uint256 _vaultId)`: Allows the owner to withdraw the `observedAmount` of ETH from the vault. Requires the vault to be in Observed status. Transfers the ETH and sets status to Withdrawn.
14. `emergencyWithdrawPartial(uint256 _vaultId)`: Allows the owner to withdraw a small, fixed percentage of the initial deposit regardless of the observed state, typically used if the observed amount is 0 or very low. Only available after observation.
15. `getVaultInfo(uint256 _vaultId) public view returns (...)`: Returns core information about a vault (owner, status, creation time, observation time, delay).
16. `getPotentialStates(uint256 _vaultId) public view returns (uint256[] memory)`: Returns the list of potential outcome amounts for a vault.
17. `getObservedAmount(uint256 _vaultId) public view returns (uint256)`: Returns the final observed amount for a vault. Returns 0 if not yet observed.
18. `getVaultStatus(uint256 _vaultId) public view returns (VaultStatus)`: Returns the current status of the vault.
19. `getVaultBalance(uint256 _vaultId) public view returns (uint256)`: Returns the ETH balance currently held by the contract for a specific vault.
20. `isEntangled(uint256 _vaultId) public view returns (bool)`: Checks if a vault is currently entangled with another.
21. `getEntangledPartner(uint256 _vaultId) public view returns (uint256)`: Returns the ID of the entangled partner vault, or 0 if not entangled.
22. `canObserve(uint256 _vaultId) public view returns (bool)`: Checks if a vault is in Superposition and its observation delay has passed.
23. `getUserVaults(address _user) public view returns (uint256[] memory)`: Returns an array of vault IDs owned by a specific user.
24. `getTotalVaultCount() public view returns (uint256)`: Returns the total number of vaults that have been created.
25. `getContractBalance() public view returns (uint256)`: Returns the total ETH balance held by the contract across all vaults.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors
error QuantumVault__VaultNotFound();
error QuantumVault__NotVaultOwner();
error QuantumVault__InvalidStatus(VaultStatus requiredStatus, VaultStatus currentStatus);
error QuantumVault__VaultAlreadyObserved();
error QuantumVault__VaultAlreadyWithdrawn();
error QuantumVault__NoPotentialStates();
error QuantumVault__InvalidStateIndex();
error QuantumVault__DepositRequired();
error QuantumVault__ObservationDelayNotPassed(uint256 timeRemaining);
error QuantumVault__VaultAlreadyEntangled();
error QuantumVault__VaultNotEntangled();
error QuantumVault__EntanglementRequiresSuperposition();
error QuantumVault__EntanglementRequiresSameNumberOfStates();
error QuantumVault__NotEntangledPair(uint256 vaultId1, uint256 vaultId2);
error QuantumVault__WithdrawalAmountZero();
error QuantumVault__NothingToWithdraw();
error QuantumVault__PartialWithdrawalNotAvailableYet();
error QuantumVault__PartialWithdrawalAlreadyDone();
error QuantumVault__VaultHasBalance(); // Cannot revoke ownership if balance exists
error QuantumVault__CannotEntangleWithSelf();


// Enums
enum VaultStatus {
    Created,      // Vault exists, states can be added/removed, no funds deposited yet, not in superposition
    Funded,       // Funds deposited, but not yet in superposition. States can still be modified.
    Superposition,// States finalized, funds potentially deposited, awaiting observation
    Observed,     // State has collapsed, observedAmount determined, ready for withdrawal
    Withdrawn     // Funds have been withdrawn
}

// Structs
struct PotentialState {
    uint256 amount; // Potential withdrawal amount in wei
}

struct Vault {
    address owner;
    PotentialState[] potentialStates;
    VaultStatus status;
    uint256 observedAmount; // The amount after state collapse
    uint256 creationTime;
    uint64 observationDelay; // Minimum seconds after entering Superposition before observation is allowed
    uint64 superpositionTime; // Timestamp when entering Superposition
    uint256 entangledPartnerId; // ID of the entangled vault, 0 if not entangled
    bool partialWithdrawalDone; // Flag for emergency partial withdrawal
}

contract QuantumVault is ReentrancyGuard {

    // State Variables
    mapping(uint256 => Vault) private vaults;
    uint256 private vaultCounter; // Starts from 1
    mapping(uint256 => uint256) private vaultBalances; // Tracks balance per vault ID
    mapping(address => uint256[]) private userToVaults; // Maps user addresses to vault IDs they own

    // Constants
    uint256 private constant PARTIAL_WITHDRAWAL_PERCENTAGE = 5; // 5% for emergency withdrawal

    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, uint256 initialStatesCount);
    event Deposited(uint256 indexed vaultId, address indexed sender, uint256 amount);
    event PotentialStateAdded(uint256 indexed vaultId, uint256 amount, uint256 index);
    event PotentialStateRemoved(uint256 indexed vaultId, uint256 index);
    event OwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner);
    event OwnershipRevoked(uint256 indexed vaultId, address indexed oldOwner);
    event ObservationDelaySet(uint256 indexed vaultId, uint64 delayInSeconds);
    event SuperpositionEntered(uint256 indexed vaultId, uint64 timestamp);
    event VaultObserved(uint256 indexed vaultId, uint256 indexed observedStateIndex, uint256 observedAmount);
    event VaultsEntangled(uint256 indexed vaultId1, uint256 indexed vaultId2);
    event VaultsDisentangled(uint256 indexed vaultId1, uint256 indexed vaultId2);
    event EntangledPairObserved(uint256 indexed vaultId1, uint256 indexed vaultId2, uint256 observedStateIndex1, uint256 observedAmount1, uint256 observedStateIndex2, uint256 observedAmount2);
    event Withdrawn(uint256 indexed vaultId, address indexed recipient, uint256 amount);
    event EmergencyWithdrawalPartial(uint256 indexed vaultId, address indexed recipient, uint256 amount);

    // Modifiers
    modifier onlyVaultOwner(uint256 _vaultId) {
        if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        if (vaults[_vaultId].owner != msg.sender) revert QuantumVault__NotVaultOwner();
        _;
    }

    modifier whenInStatus(uint256 _vaultId, VaultStatus _status) {
        if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        if (vaults[_vaultId].status != _status) revert QuantumVault__InvalidStatus(_status, vaults[_vaultId].status);
        _;
    }

    modifier whenNotInStatus(uint256 _vaultId, VaultStatus _status) {
         if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        if (vaults[_vaultId].status == _status) revert QuantumVault__InvalidStatus(_status, vaults[_vaultId].status);
        _;
    }

    modifier whenNotEntangled(uint256 _vaultId) {
        if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        if (vaults[_vaultId].entangledPartnerId != 0) revert QuantumVault__VaultAlreadyEntangled();
        _;
    }

     modifier whenEntangled(uint256 _vaultId) {
        if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        if (vaults[_vaultId].entangledPartnerId == 0) revert QuantumVault__VaultNotEntangled();
        _;
    }

    modifier requireVaultExists(uint256 _vaultId) {
        if (vaults[_vaultId].owner == address(0)) revert QuantumVault__VaultNotFound();
        _;
    }

    constructor() ReentrancyGuard() {
        vaultCounter = 0; // Initialize counter (vault IDs will start from 1)
    }

    /// @notice Creates a new Quantum Vault with initial potential outcome amounts.
    /// @param _potentialAmounts Array of possible ETH withdrawal amounts in wei.
    /// @return vaultId The ID of the newly created vault.
    function createVault(uint256[] memory _potentialAmounts) public returns (uint256 vaultId) {
        vaultCounter++;
        vaultId = vaultCounter;

        PotentialState[] memory initialStates = new PotentialState[](_potentialAmounts.length);
        for (uint i = 0; i < _potentialAmounts.length; i++) {
            initialStates[i] = PotentialState(_potentialAmounts[i]);
        }

        vaults[vaultId] = Vault({
            owner: msg.sender,
            potentialStates: initialStates,
            status: VaultStatus.Created,
            observedAmount: 0,
            creationTime: block.timestamp,
            observationDelay: 0,
            superpositionTime: 0,
            entangledPartnerId: 0,
            partialWithdrawalDone: false
        });

        userToVaults[msg.sender].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, _potentialAmounts.length);
    }

    /// @notice Allows depositing ETH into a specific vault.
    /// @param _vaultId The ID of the vault to deposit into.
    function deposit(uint256 _vaultId) public payable requireVaultExists(_vaultId) nonReentrant {
        Vault storage vault = vaults[_vaultId];
        if (vault.status == VaultStatus.Observed) revert QuantumVault__VaultAlreadyObserved();
        if (vault.status == VaultStatus.Withdrawn) revert QuantumVault__VaultAlreadyWithdrawn();
        if (msg.value == 0) revert QuantumVault__DepositRequired();

        vaultBalances[_vaultId] += msg.value;
        vault.status = VaultStatus.Funded; // Transition to Funded upon first deposit

        emit Deposited(_vaultId, msg.sender, msg.value);
    }

    /// @notice Adds a potential outcome amount to a vault before it enters Superposition.
    /// @param _vaultId The ID of the vault.
    /// @param _amount The potential outcome amount in wei.
    function addPotentialState(uint256 _vaultId, uint256 _amount) public onlyVaultOwner(_vaultId) whenNotInStatus(_vaultId, VaultStatus.Superposition) whenNotInStatus(_vaultId, VaultStatus.Observed) whenNotInStatus(_vaultId, VaultStatus.Withdrawn) {
        Vault storage vault = vaults[_vaultId];
        vault.potentialStates.push(PotentialState(_amount));
        emit PotentialStateAdded(_vaultId, _amount, vault.potentialStates.length - 1);
    }

    /// @notice Removes a potential outcome amount from a vault by index before it enters Superposition.
    /// @param _vaultId The ID of the vault.
    /// @param _index The index of the state to remove.
    function removePotentialState(uint256 _vaultId, uint256 _index) public onlyVaultOwner(_vaultId) whenNotInStatus(_vaultId, VaultStatus.Superposition) whenNotInStatus(_vaultId, VaultStatus.Observed) whenNotInStatus(_vaultId, VaultStatus.Withdrawn) {
        Vault storage vault = vaults[_vaultId];
        if (_index >= vault.potentialStates.length) revert QuantumVault__InvalidStateIndex();
        if (vault.potentialStates.length <= 1) revert QuantumVault__NoPotentialStates(); // Must leave at least one state

        // Shift elements left to remove the one at index
        for (uint i = _index; i < vault.potentialStates.length - 1; i++) {
            vault.potentialStates[i] = vault.potentialStates[i + 1];
        }
        vault.potentialStates.pop(); // Remove the last element

        emit PotentialStateRemoved(_vaultId, _index);
    }

    /// @notice Transfers ownership of a vault.
    /// @param _vaultId The ID of the vault.
    /// @param _newOwner The address of the new owner.
    function transferVaultOwnership(uint256 _vaultId, address _newOwner) public onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        address oldOwner = vault.owner;
        vault.owner = _newOwner;

        // Update userToVaults mapping (this part is simplified and might be gas intensive/complex for many vaults)
        // A more robust approach for production would avoid large arrays in storage
        uint256[] storage oldOwnerVaults = userToVaults[oldOwner];
        for (uint i = 0; i < oldOwnerVaults.length; i++) {
            if (oldOwnerVaults[i] == _vaultId) {
                oldOwnerVaults[i] = oldOwnerVaults[oldOwnerVaults.length - 1];
                oldOwnerVaults.pop();
                break;
            }
        }
        userToVaults[_newOwner].push(_vaultId);

        emit OwnershipTransferred(_vaultId, oldOwner, _newOwner);
    }

     /// @notice Revokes ownership of a vault by setting owner to address(0). Requires no balance and not entangled.
     /// @param _vaultId The ID of the vault.
    function revokeVaultOwnership(uint256 _vaultId) public onlyVaultOwner(_vaultId) whenNotEntangled(_vaultId) {
        Vault storage vault = vaults[_vaultId];
         if (vaultBalances[_vaultId] > 0) revert QuantumVault__VaultHasBalance();

        address oldOwner = vault.owner;
        vault.owner = address(0); // Revoke ownership

        // Update userToVaults mapping (simplified)
        uint256[] storage oldOwnerVaults = userToVaults[oldOwner];
        for (uint i = 0; i < oldOwnerVaults.length; i++) {
            if (oldOwnerVaults[i] == _vaultId) {
                oldOwnerVaults[i] = oldOwnerVaults[oldOwnerVaults.length - 1];
                oldOwnerVaults.pop();
                break;
            }
        }

        emit OwnershipRevoked(_vaultId, oldOwner);
    }


    /// @notice Sets a minimum time requirement after entering Superposition before observation is possible.
    /// @param _vaultId The ID of the vault.
    /// @param _delayInSeconds The delay in seconds.
    function setObservationDelay(uint256 _vaultId, uint64 _delayInSeconds) public onlyVaultOwner(_vaultId) whenInStatus(_vaultId, VaultStatus.Created) {
         Vault storage vault = vaults[_vaultId];
         vault.observationDelay = _delayInSeconds;
         emit ObservationDelaySet(_vaultId, _delayInSeconds);
    }


    /// @notice Transitions the vault into the Superposition state. No more state modifications allowed after this.
    /// @param _vaultId The ID of the vault.
    function enterSuperposition(uint256 _vaultId) public onlyVaultOwner(_vaultId) whenNotInStatus(_vaultId, VaultStatus.Superposition) whenNotInStatus(_vaultId, VaultStatus.Observed) whenNotInStatus(_vaultId, VaultStatus.Withdrawn) {
        Vault storage vault = vaults[_vaultId];
        if (vault.potentialStates.length == 0) revert QuantumVault__NoPotentialStates();

        vault.status = VaultStatus.Superposition;
        vault.superpositionTime = uint64(block.timestamp); // Record the time of entering superposition

        emit SuperpositionEntered(_vaultId, vault.superpositionTime);
    }

    /// @notice Triggers the observation process for a single, non-entangled vault, collapsing its state.
    /// @param _vaultId The ID of the vault.
    /// @param _seed An external seed provided by the caller to influence the outcome.
    function observeVault(uint256 _vaultId, uint256 _seed) public onlyVaultOwner(_vaultId) whenInStatus(_vaultId, VaultStatus.Superposition) whenNotEntangled(_vaultId) nonReentrant {
        Vault storage vault = vaults[_vaultId];

        // Check if observation delay has passed
        if (block.timestamp < vault.superpositionTime + vault.observationDelay) {
            revert QuantumVault__ObservationDelayNotPassed(vault.superpositionTime + vault.observationDelay - block.timestamp);
        }

        // Determine the outcome index (pseudo-randomly)
        uint256 chosenIndex = _determineState(_vaultId, _seed, vault.potentialStates.length);

        // Set the observed amount and update status
        vault.observedAmount = vault.potentialStates[chosenIndex].amount;
        vault.status = VaultStatus.Observed;

        // Clear potential states to save gas/storage after observation (optional but good practice)
        delete vault.potentialStates;

        emit VaultObserved(_vaultId, chosenIndex, vault.observedAmount);
    }

    /// @notice Links two vaults into an entangled pair. Requires both to be in Superposition and have the same number of potential states.
    /// @param _vaultId1 The ID of the first vault.
    /// @param _vaultId2 The ID of the second vault.
    function entangleVaults(uint256 _vaultId1, uint256 _vaultId2) public onlyVaultOwner(_vaultId1) nonReentrant {
        if (_vaultId1 == _vaultId2) revert QuantumVault__CannotEntangleWithSelf();
        Vault storage vault1 = vaults[_vaultId1];
        Vault storage vault2 = vaults[_vaultId2]; // Require vault2 exists and is owned by sender? Or allow entangling owned with non-owned? Let's require sender owns both.
        if (vault2.owner != msg.sender) revert QuantumVault__NotVaultOwner(); // Ensure sender owns both

        if (vault1.status != VaultStatus.Superposition || vault2.status != VaultStatus.Superposition) {
            revert QuantumVault__EntanglementRequiresSuperposition();
        }
        if (vault1.entangledPartnerId != 0 || vault2.entangledPartnerId != 0) {
             revert QuantumVault__VaultAlreadyEntangled();
        }
        if (vault1.potentialStates.length != vault2.potentialStates.length) {
            revert QuantumVault__EntanglementRequiresSameNumberOfStates();
        }

        vault1.entangledPartnerId = _vaultId2;
        vault2.entangledPartnerId = _vaultId1;

        emit VaultsEntangled(_vaultId1, _vaultId2);
    }

    /// @notice Unlinks two entangled vaults. Requires both to be in Superposition or Created/Funded status.
    /// @param _vaultId1 The ID of the first vault.
    /// @param _vaultId2 The ID of the second vault.
    function disentangleVaults(uint256 _vaultId1, uint256 _vaultId2) public onlyVaultOwner(_vaultId1) nonReentrant {
        Vault storage vault1 = vaults[_vaultId1];
         Vault storage vault2 = vaults[_vaultId2];
         if (vault2.owner != msg.sender) revert QuantumVault__NotVaultOwner(); // Ensure sender owns both

        if (vault1.entangledPartnerId != _vaultId2 || vault2.entangledPartnerId != _vaultId1) {
            revert QuantumVault__NotEntangledPair(_vaultId1, _vaultId2);
        }
         if (vault1.status == VaultStatus.Observed || vault1.status == VaultStatus.Withdrawn ||
             vault2.status == VaultStatus.Observed || vault2.status == VaultStatus.Withdrawn) {
            revert QuantumVault__InvalidStatus(VaultStatus.Superposition, vault1.status); // Cannot disentangle after observation/withdrawal
        }

        vault1.entangledPartnerId = 0;
        vault2.entangledPartnerId = 0;

        emit VaultsDisentangled(_vaultId1, _vaultId2);
    }


    /// @notice Triggers the observation process for an entangled pair. Observing one instantly affects the other.
    /// @param _vaultId1 The ID of the first vault in the entangled pair.
    /// @param _vaultId2 The ID of the second vault in the entangled pair.
    /// @param _seed An external seed provided by the caller to influence the outcome.
    function observeEntangledPair(uint256 _vaultId1, uint256 _vaultId2, uint256 _seed) public onlyVaultOwner(_vaultId1) nonReentrant {
         Vault storage vault1 = vaults[_vaultId1];
         Vault storage vault2 = vaults[_vaultId2];
         // Ensure sender owns both or decide on a rule (e.g., owner of _vaultId1 can observe the pair)
         if (vault2.owner != msg.sender && vault1.owner != msg.sender) revert QuantumVault__NotVaultOwner();
         // Let's simplify and say sender must own _vaultId1, which implies they can observe the pair they initiated or transferred ownership of.

        if (vault1.entangledPartnerId != _vaultId2 || vault2.entangledPartnerId != _vaultId1) {
            revert QuantumVault__NotEntangledPair(_vaultId1, _vaultId2);
        }
        if (vault1.status != VaultStatus.Superposition || vault2.status != VaultStatus.Superposition) {
            revert QuantumVault__EntanglementRequiresSuperposition();
        }

         // Check observation delay for both (or just the first one used for timing?) Let's check the first one.
         if (block.timestamp < vault1.superpositionTime + vault1.observationDelay) {
            revert QuantumVault__ObservationDelayNotPassed(vault1.superpositionTime + vault1.observationDelay - block.timestamp);
        }
        if (block.timestamp < vault2.superpositionTime + vault2.observationDelay) {
            // Decide behavior: require both delays met, or use the later one?
            // Let's require both delays are met for simplicity.
            revert QuantumVault__ObservationDelayNotPassed(vault2.superpositionTime + vault2.observationDelay - block.timestamp);
        }


        // Determine the outcome for the first vault (pseudo-randomly)
        uint256 chosenIndex1 = _determineState(_vaultId1, _seed, vault1.potentialStates.length);

        // Determine the outcome for the second vault based on anti-correlation
        // Simple anti-correlation: index2 = totalStates - 1 - index1
        uint256 chosenIndex2 = (vault1.potentialStates.length - 1) - chosenIndex1;
        // Note: This assumes indices correspond to some ordered property and equal lengths.

        // Set observed amounts and update status for both
        vault1.observedAmount = vault1.potentialStates[chosenIndex1].amount;
        vault1.status = VaultStatus.Observed;
        vault2.observedAmount = vault2.potentialStates[chosenIndex2].amount;
        vault2.status = VaultStatus.Observed;

        // Disentangle automatically upon observation
        vault1.entangledPartnerId = 0;
        vault2.entangledPartnerId = 0;

        // Clear potential states
        delete vault1.potentialStates;
        delete vault2.potentialStates;

        emit EntangledPairObserved(_vaultId1, _vaultId2, chosenIndex1, vault1.observedAmount, chosenIndex2, vault2.observedAmount);
    }


    /// @notice Allows the owner to withdraw the observed amount of ETH from the vault.
    /// @param _vaultId The ID of the vault.
    function withdraw(uint256 _vaultId) public onlyVaultOwner(_vaultId) whenInStatus(_vaultId, VaultStatus.Observed) nonReentrant {
        Vault storage vault = vaults[_vaultId];
        uint256 amountToWithdraw = vault.observedAmount;

        if (amountToWithdraw == 0) revert WithdrawalAmountZero(); // If the observed amount is 0
        if (vaultBalances[_vaultId] < amountToWithdraw) {
             // This shouldn't happen if deposit tracking is correct, but safety check
             revert NothingToWithdraw();
        }

        vaultBalances[_vaultId] -= amountToWithdraw;
        vault.status = VaultStatus.Withdrawn;
        vault.observedAmount = 0; // Clear observed amount after withdrawal

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Transfer failed.");

        emit Withdrawn(_vaultId, msg.sender, amountToWithdraw);
    }

     /// @notice Allows a partial withdrawal of a fixed percentage after observation, regardless of the observed amount.
     /// Can only be done once per vault. Useful if observedAmount is 0.
     /// @param _vaultId The ID of the vault.
    function emergencyWithdrawPartial(uint256 _vaultId) public onlyVaultOwner(_vaultId) whenInStatus(_vaultId, VaultStatus.Observed) nonReentrant {
        Vault storage vault = vaults[_vaultId];
        if (vault.partialWithdrawalDone) revert QuantumVault__PartialWithdrawalAlreadyDone();
        if (vaultBalances[_vaultId] == 0) revert NothingToWithdraw();

        // Calculate amount based on the *current* balance in the vault
        uint256 amountToWithdraw = (vaultBalances[_vaultId] * PARTIAL_WITHDRAWAL_PERCENTAGE) / 100;

        if (amountToWithdraw == 0) revert NothingToWithdraw(); // Prevent 0 withdrawal if balance is too low

        vaultBalances[_vaultId] -= amountToWithdraw;
        vault.partialWithdrawalDone = true;

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Partial transfer failed.");

        emit EmergencyWithdrawalPartial(_vaultId, msg.sender, amountToWithdraw);
    }


    // --- Read Functions ---

    /// @notice Gets core information about a vault.
    /// @param _vaultId The ID of the vault.
    /// @return owner The vault owner.
    /// @return status The current status of the vault.
    /// @return observedAmount The amount after observation (0 if not observed).
    /// @return creationTime The timestamp the vault was created.
    /// @return observationDelay The set observation delay.
    /// @return superpositionTime The timestamp the vault entered superposition (0 if not yet).
    /// @return entangledPartnerId The ID of the entangled partner (0 if not entangled).
     /// @return partialWithdrawalDone Flag indicating if partial withdrawal was done.
    function getVaultInfo(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (address owner, VaultStatus status, uint256 observedAmount, uint256 creationTime, uint64 observationDelay, uint64 superpositionTime, uint256 entangledPartnerId, bool partialWithdrawalDone) {
        Vault storage vault = vaults[_vaultId];
        return (
            vault.owner,
            vault.status,
            vault.observedAmount,
            vault.creationTime,
            vault.observationDelay,
            vault.superpositionTime,
            vault.entangledPartnerId,
            vault.partialWithdrawalDone
        );
    }

    /// @notice Gets the potential outcome amounts for a vault.
    /// @param _vaultId The ID of the vault.
    /// @return potentialAmounts Array of potential withdrawal amounts.
    function getPotentialStates(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (uint256[] memory) {
        Vault storage vault = vaults[_vaultId];
        uint256[] memory amounts = new uint256[](vault.potentialStates.length);
        for (uint i = 0; i < vault.potentialStates.length; i++) {
            amounts[i] = vault.potentialStates[i].amount;
        }
        return amounts;
    }

    /// @notice Gets the final observed amount for a vault.
    /// @param _vaultId The ID of the vault.
    /// @return observedAmount The observed amount (0 if not observed).
    function getObservedAmount(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].observedAmount;
    }

    /// @notice Gets the current status of a vault.
    /// @param _vaultId The ID of the vault.
    /// @return status The current VaultStatus enum.
    function getVaultStatus(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (VaultStatus) {
        return vaults[_vaultId].status;
    }

    /// @notice Gets the ETH balance currently held by the contract for a specific vault.
    /// @param _vaultId The ID of the vault.
    /// @return balance The ETH balance in wei.
    function getVaultBalance(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (uint256) {
        return vaultBalances[_vaultId];
    }

    /// @notice Checks if a vault is currently entangled.
    /// @param _vaultId The ID of the vault.
    /// @return isEntangled True if entangled, false otherwise.
    function isEntangled(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (bool) {
        return vaults[_vaultId].entangledPartnerId != 0;
    }

    /// @notice Gets the ID of the entangled partner vault.
    /// @param _vaultId The ID of the vault.
    /// @return partnerId The ID of the entangled partner (0 if not entangled).
    function getEntangledPartner(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (uint256) {
        return vaults[_vaultId].entangledPartnerId;
    }

    /// @notice Checks if a vault in Superposition has met its observation delay.
    /// @param _vaultId The ID of the vault.
    /// @return canObserve True if observation delay has passed, false otherwise or if not in Superposition.
    function canObserve(uint256 _vaultId) public view requireVaultExists(_vaultId) returns (bool) {
        Vault storage vault = vaults[_vaultId];
        if (vault.status != VaultStatus.Superposition) {
            return false;
        }
        return block.timestamp >= vault.superpositionTime + vault.observationDelay;
    }

    /// @notice Gets the list of vault IDs owned by a specific user.
    /// @param _user The address of the user.
    /// @return vaultIds Array of vault IDs.
    function getUserVaults(address _user) public view returns (uint256[] memory) {
        return userToVaults[_user];
    }

    /// @notice Gets the total number of vaults created.
    /// @return count The total count of vaults.
    function getTotalVaultCount() public view returns (uint256) {
        return vaultCounter;
    }

     /// @notice Gets the total ETH balance held by the contract across all vaults.
     /// @return balance The total ETH balance in wei.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Internal Logic ---

    /// @dev Determines the chosen state index using a pseudo-random calculation based on block data and a seed.
    ///      NOTE: This is NOT cryptographically secure randomness and should not be used for high-stakes outcomes.
    ///      Miners/validators can influence or predict this outcome.
    /// @param _vaultId The ID of the vault.
    /// @param _seed An external seed to mix in.
    /// @param _numStates The total number of potential states.
    /// @return chosenIndex The determined index for the observed state.
    function _determineState(uint256 _vaultId, uint256 _seed, uint256 _numStates) internal view returns (uint256) {
        if (_numStates == 0) {
            // Should not happen if checks are in place, but safety
            return 0;
        }
        // Using block.difficulty is deprecated on PoS, using block.timestamp is also weak.
        // This is for conceptual demonstration. For real applications, use Chainlink VRF or similar.
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.chainid, // Include chain ID for robustness across networks
            msg.sender,    // Include sender address
            _vaultId,
            _seed          // External seed
        )));
        return entropy % _numStates;
    }

}
```