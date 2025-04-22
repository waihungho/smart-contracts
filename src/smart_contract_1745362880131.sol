Okay, let's design an advanced, multi-faceted smart contract focused on conditional, time-locked asset management with delegation capabilities, interacting potentially with external data sources (via a simple oracle interface).

We'll call it `TimeVault`. Users can deposit ETH, ERC-20, or ERC-721 tokens into vaults. These vaults are locked until a set of customizable conditions are met. Conditions can include time, external oracle data, specific address interactions, or multi-party approval. Depositors can also delegate specific management rights to others for their vaults.

This contract goes beyond simple vesting or escrow by combining multiple asset types, diverse condition types, delegation, and an emergency unlock feature.

---

### **Contract Outline and Function Summary**

**Contract Name:** `TimeVault`

**Purpose:** A smart contract enabling users to lock various digital assets (ETH, ERC-20, ERC-721) within "Vaults". Each Vault is associated with a set of customizable conditions that must be met before the assets can be released to a designated beneficiary. The contract supports delegation of certain management rights and includes an emergency unlock mechanism. It also integrates with a basic oracle interface for external data conditions.

**Core Concepts:**
1.  **Vaults:** Containers for locked assets, linked to a depositor, beneficiary, and conditions.
2.  **Conditions:** Criteria (Time, Oracle Data, Address Interaction, MultiSig Approval) that must be fulfilled for a vault to transition towards unlock.
3.  **Delegation:** Depositors can grant limited management permissions (e.g., adding conditions, initiating emergency unlock) to other addresses.
4.  **Oracles:** Integration point for external data validated by registered oracle addresses.
5.  **State Machine:** Vaults transition through states (Pending, Locked, ConditionsMet, Unlocked, Cancelled, EmergencyUnlocked) based on actions and condition fulfillment.
6.  **Multi-Asset Support:** Handles ETH, ERC-20, and ERC-721 tokens.

**Function Summary:**

**Vault Creation & Setup (State: Pending -> Locked)**
1.  `createVaultETH(address _beneficiary, Condition[] calldata _initialConditions)`: Creates a new vault locking deposited ETH. Requires `payable`.
2.  `createVaultERC20(address _tokenAddress, uint256 _amount, address _beneficiary, Condition[] calldata _initialConditions)`: Creates a new vault locking specified ERC-20 tokens. Requires prior `approve` call by depositor.
3.  `createVaultERC721(address _tokenAddress, uint256 _tokenId, address _beneficiary, Condition[] calldata _initialConditions)`: Creates a new vault locking a specific ERC-721 token. Requires implementer of `onERC721Received`.
4.  `addConditionToVault(uint256 _vaultId, Condition calldata _condition)`: Adds a condition to a vault in `Pending` state. Only depositor or authorized delegate.
5.  `removeConditionFromVault(uint256 _vaultId, uint256 _conditionIndex)`: Removes a condition from a vault in `Pending` state. Only depositor or authorized delegate.
6.  `sealVault(uint256 _vaultId)`: Transitions a vault from `Pending` to `Locked`. Conditions become immutable. Only depositor.

**Condition Fulfillment & State Transitions (State: Locked -> ConditionsMet -> Unlocked)**
7.  `checkVaultConditionsAndTransition(uint256 _vaultId)`: Public function to check if all conditions for a locked vault are met. If so, transitions state from `Locked` to `ConditionsMet`. Callable by anyone (gas cost externalized).
8.  `updateOracleConditionStatus(uint256 _vaultId, uint256 _conditionIndex, bytes32 _oracleDataHash, bool _isMet)`: Called by a registered oracle to update the status of an `OracleValue` condition.
9.  `triggerAddressInteractionCondition(uint256 _vaultId, uint256 _conditionIndex)`: Called by the target address of an `AddressInteraction` condition to mark it as met.
10. `approveVaultCondition(uint256 _vaultId, uint256 _conditionIndex)`: Called by an authorized approver for a `MultiSigApproval` condition. Increments approval count.
11. `releaseVaultAssets(uint256 _vaultId)`: Transfers locked assets to the beneficiary. Requires vault state `ConditionsMet`. Transitions state to `Unlocked`. Callable by beneficiary or depositor.

**Emergency & Cancellation (State: Locked/ConditionsMet -> EmergencyUnlocked / Pending -> Cancelled)**
12. `initiateEmergencyUnlock(uint256 _vaultId)`: Initiates the emergency unlock process. Requires vault state `Locked` or `ConditionsMet`. Sets initiation time and transitions state to `EmergencyUnlocked`. Callable by depositor or authorized delegate.
13. `claimEmergencyUnlock(uint256 _vaultId)`: Claims assets after the emergency unlock delay period has passed. Requires state `EmergencyUnlocked`. Transitions state to `Unlocked`. Callable by depositor or beneficiary.
14. `cancelVault(uint256 _vaultId)`: Cancels a vault and returns assets to the depositor. Requires state `Pending`. Transitions state to `Cancelled`. Only depositor.

**Delegation**
15. `delegateManagement(uint256 _vaultId, address _delegate, DelegatePermissions calldata _permissions)`: Grants specific permissions to a delegate for a vault. Only depositor.
16. `revokeDelegateManagement(uint256 _vaultId, address _delegate)`: Revokes all permissions for a delegate for a vault. Only depositor.
17. `renounceDelegateManagement(uint256 _vaultId)`: Allows a delegate to remove their own permissions for a vault. Callable by the delegate.

**Querying & Viewing (View Functions)**
18. `getVaultDetails(uint256 _vaultId)`: Returns core details of a vault.
19. `getVaultConditions(uint256 _vaultId)`: Returns the list of conditions for a vault.
20. `getVaultDelegates(uint256 _vaultId)`: Returns the list of delegates and their permissions for a vault.
21. `getVaultState(uint256 _vaultId)`: Returns the current state of a vault.
22. `isVaultConditionMet(uint256 _vaultId, uint256 _conditionIndex)`: Checks if a specific condition in a vault is met.
23. `getMultiSigConditionApprovers(uint256 _vaultId, uint256 _conditionIndex)`: Returns the required approvers for a MultiSig condition.
24. `getMultiSigConditionApprovalCount(uint256 _vaultId, uint256 _conditionIndex)`: Returns the current approval count for a MultiSig condition.
25. `getVaultsByDepositor(address _depositor)`: Returns a list of vault IDs created by a specific depositor.
26. `getVaultsByBeneficiary(address _beneficiary)`: Returns a list of vault IDs where the address is the beneficiary.

**Admin (Optional but useful for Oracles)**
27. `registerOracle(address _oracle, bool _isRegistered)`: Grants or revokes registration status for an oracle address. (Assumes an owner/admin role, could be `Ownable` or a simple state variable). Let's add a simple owner.

**Helper / Internal / Standard Receivers**
*   `receive()`: Handles incoming ETH for `createVaultETH`.
*   `onERC721Received`: ERC721 standard receiver hook for `createVaultERC721`.
*   `_checkAllConditions(uint256 _vaultId)`: Internal logic to evaluate all conditions for a vault.
*   `_transferAssets(uint256 _vaultId)`: Internal logic to transfer assets based on asset type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Define a simple interface for an observable oracle
// An oracle implementation would provide the checkCondition method
interface IObservableOracle {
    // Checks if a specific condition (identified by dataHash) is met externally
    function checkCondition(bytes32 dataHash) external view returns (bool);
}

contract TimeVault is IERC721Receiver {
    using Address for address;

    address private immutable i_owner; // Simple owner for oracle registration

    enum AssetType { ETH, ERC20, ERC721 }
    enum VaultState {
        Pending,          // Initial state, conditions can be added/removed, can be cancelled
        Locked,           // Conditions are immutable, waiting for fulfillment
        ConditionsMet,    // All conditions met, ready for release
        Unlocked,         // Assets released
        Cancelled,        // Vault cancelled in Pending state
        EmergencyUnlocked // Emergency unlock initiated, waiting for delay
    }
    enum ConditionType {
        TimeAbsolute,       // Timestamp must be reached (parameter1 = timestamp)
        TimeRelative,       // Duration after vault creation (parameter1 = duration)
        OracleValue,        // External data condition via oracle (parameter2 = oracle address, parameter3 = data hash)
        AddressInteraction, // Specific address calls a function (parameter2 = target address)
        MultiSigApproval    // Requires N approvals from a defined set (parameter1 = required count, parameter3 = hash of approver list)
    }

    struct Condition {
        ConditionType conditionType;
        uint256 parameter1; // e.g., timestamp, duration, required count
        address parameter2; // e.g., oracle address, target address
        bytes32 parameter3; // e.g., data hash, approver list hash
        bool isMet;         // Current status of the condition
        bool requiresExternalUpdate; // True if oracle or interaction needed to update isMet
    }

    struct DelegatePermissions {
        bool canAddConditions; // While Pending
        bool canRemoveConditions; // While Pending
        bool canApproveConditions; // For MultiSig
        bool canInitiateEmergencyUnlock;
    }

    struct Vault {
        address depositor;
        address beneficiary;
        AssetType assetType;
        address tokenAddress; // For ERC20/ERC721
        uint256 tokenIdOrAmount; // Token ID for ERC721, amount for ETH/ERC20
        uint256 creationTime;
        Condition[] conditions;
        VaultState state;
        mapping(address => DelegatePermissions) delegates; // Delegate permissions per vault
        uint256 emergencyUnlockInitiatedTime; // Timestamp when emergency unlock was initiated
    }

    uint256 public vaultCount;
    mapping(uint256 => Vault) public vaults;
    mapping(address => uint256[]) public vaultsByDepositor;
    mapping(address => uint256[]) public vaultsByBeneficiary;

    mapping(address => bool) public registeredOracles;
    // Store multi-sig approvals per vault, per condition index, per approver
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private multiSigApprovals;
    // Store the actual list of approvers for MultiSig conditions, indexed by hash
    mapping(bytes32 => address[]) private multiSigApproverLists;
    // Emergency unlock delay duration (e.g., 7 days)
    uint256 public constant emergencyUnlockDelay = 7 days;
    // A small fee for emergency unlock could be added, but let's keep it simple for now.

    event VaultCreated(uint256 indexed vaultId, address indexed depositor, address indexed beneficiary, AssetType assetType, uint256 creationTime);
    event ConditionAdded(uint256 indexed vaultId, uint256 indexed conditionIndex, ConditionType conditionType);
    event ConditionRemoved(uint256 indexed vaultId, uint256 indexed conditionIndex);
    event VaultSealed(uint256 indexed vaultId);
    event ConditionsChecked(uint256 indexed vaultId, bool allMet);
    event VaultStateChanged(uint256 indexed vaultId, VaultState newState);
    event ConditionMet(uint256 indexed vaultId, uint256 indexed conditionIndex, ConditionType conditionType);
    event AssetsReleased(uint256 indexed vaultId, address indexed beneficiary, AssetType assetType);
    event EmergencyUnlockInitiated(uint256 indexed vaultId, address indexed initiator);
    event EmergencyUnlockClaimed(uint256 indexed vaultId);
    event VaultCancelled(uint256 indexed vaultId, address indexed depositor);
    event DelegateManagementGranted(uint256 indexed vaultId, address indexed delegator, address indexed delegate, DelegatePermissions permissions);
    event DelegateManagementRevoked(uint256 indexed vaultId, address indexed delegator, address indexed delegate);
    event DelegateRenounced(uint256 indexed vaultId, address indexed delegate);
    event OracleRegistered(address indexed oracle, bool registered);
    event MultiSigApproved(uint256 indexed vaultId, uint256 indexed conditionIndex, address indexed approver, uint256 currentApprovals);

    modifier onlyVaultDepositor(uint256 _vaultId) {
        require(msg.sender == vaults[_vaultId].depositor, "TV: Not vault depositor");
        _;
    }

    modifier onlyVaultDelegate(uint256 _vaultId) {
        require(vaults[_vaultId].delegates[msg.sender].canAddConditions || // Example checks, specific functions check required perm
                vaults[_vaultId].delegates[msg.sender].canRemoveConditions ||
                vaults[_vaultId].delegates[msg.sender].canApproveConditions ||
                vaults[_vaultId].delegates[msg.sender].canInitiateEmergencyUnlock,
                "TV: Not an authorized delegate");
        _;
    }

    modifier onlyOracle() {
        require(registeredOracles[msg.sender], "TV: Not a registered oracle");
        _;
    }

    modifier whenVaultStateIs(uint256 _vaultId, VaultState _expectedState) {
        require(vaults[_vaultId].state == _expectedState, "TV: Incorrect vault state");
        _;
    }
     modifier whenVaultStateIsNot(uint256 _vaultId, VaultState _unexpectedState) {
        require(vaults[_vaultId].state != _unexpectedState, "TV: Incorrect vault state");
        _;
    }


    constructor() {
        i_owner = msg.sender;
    }

    // Admin function to register trusted oracles
    function registerOracle(address _oracle, bool _isRegistered) external {
        require(msg.sender == i_owner, "TV: Only owner");
        registeredOracles[_oracle] = _isRegistered;
        emit OracleRegistered(_oracle, _isRegistered);
    }

    // --- Vault Creation Functions ---

    // Creates a vault for ETH
    receive() external payable {
        // This receive function is primarily to allow ETH to be sent to the contract.
        // Actual vault creation with ETH happens via createVaultETH
    }

    function createVaultETH(address _beneficiary, Condition[] calldata _initialConditions) external payable returns (uint256 vaultId) {
        require(msg.value > 0, "TV: ETH amount must be greater than 0");
        vaultId = ++vaultCount;
        Vault storage newVault = vaults[vaultId];
        newVault.depositor = msg.sender;
        newVault.beneficiary = _beneficiary;
        newVault.assetType = AssetType.ETH;
        newVault.tokenIdOrAmount = msg.value;
        newVault.creationTime = block.timestamp;
        newVault.state = VaultState.Pending;

        _addConditionsToVault(vaultId, _initialConditions);

        vaultsByDepositor[msg.sender].push(vaultId);
        vaultsByBeneficiary[_beneficiary].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, _beneficiary, AssetType.ETH, newVault.creationTime);
    }

    // Creates a vault for ERC-20 tokens
    // Assumes msg.sender has already called IERC20(tokenAddress).approve(address(this), amount)
    function createVaultERC20(address _tokenAddress, uint256 _amount, address _beneficiary, Condition[] calldata _initialConditions) external returns (uint256 vaultId) {
        require(_amount > 0, "TV: Token amount must be greater than 0");
        require(_tokenAddress != address(0), "TV: Invalid token address");

        vaultId = ++vaultCount;
        Vault storage newVault = vaults[vaultId];
        newVault.depositor = msg.sender;
        newVault.beneficiary = _beneficiary;
        newVault.assetType = AssetType.ERC20;
        newVault.tokenAddress = _tokenAddress;
        newVault.tokenIdOrAmount = _amount;
        newVault.creationTime = block.timestamp;
        newVault.state = VaultState.Pending;

        // Transfer tokens into the vault
        bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        require(success, "TV: ERC20 transfer failed. Check allowance or balance.");

        _addConditionsToVault(vaultId, _initialConditions);

        vaultsByDepositor[msg.sender].push(vaultId);
        vaultsByBeneficiary[_beneficiary].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, _beneficiary, AssetType.ERC20, newVault.creationTime);
    }

    // Creates a vault for ERC-721 tokens
    // This function will be called by the token contract after transfer
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // 'data' should contain ABI-encoded parameters: beneficiary address, Condition[]
         // Example: abi.encode(beneficiary, conditions)
         require(from != address(0), "TV: ERC721 transfer from zero address");
         require(operator != address(0), "TV: ERC721 transfer by zero operator");
         require(data.length > 0, "TV: ERC721 receiver data missing");

        (address beneficiary, Condition[] memory initialConditions) = abi.decode(data, (address, Condition[]));

        uint256 vaultId = ++vaultCount;
        Vault storage newVault = vaults[vaultId];
        newVault.depositor = from; // The actual owner before transfer
        newVault.beneficiary = beneficiary;
        newVault.assetType = AssetType.ERC721;
        newVault.tokenAddress = msg.sender; // The ERC721 contract address
        newVault.tokenIdOrAmount = tokenId;
        newVault.creationTime = block.timestamp;
        newVault.state = VaultState.Pending;

         _addConditionsToVault(vaultId, initialConditions);

        vaultsByDepositor[from].push(vaultId);
        vaultsByBeneficiary[beneficiary].push(vaultId);

        emit VaultCreated(vaultId, from, beneficiary, AssetType.ERC721, newVault.creationTime);

        // ERC721 standard requires returning this magic value
        return IERC721Receiver.onERC721Received.selector;
    }

    // Internal helper to add conditions (used by createVault functions)
    function _addConditionsToVault(uint256 _vaultId, Condition[] calldata _conditions) internal {
         Vault storage vault = vaults[_vaultId];
         for(uint i = 0; i < _conditions.length; i++){
             Condition memory newCondition = _conditions[i];
             // Basic validation for condition types
             if (newCondition.conditionType == ConditionType.OracleValue) {
                 require(newCondition.parameter2.isContract(), "TV: Oracle address must be a contract");
                 // We don't validate if it implements IObservableOracle here, relies on trust in `registerOracle`
                 newCondition.requiresExternalUpdate = true;
             } else if (newCondition.conditionType == ConditionType.AddressInteraction) {
                 require(newCondition.parameter2 != address(0), "TV: Target address cannot be zero");
                 newCondition.requiresExternalUpdate = true;
             } else if (newCondition.conditionType == ConditionType.MultiSigApproval) {
                  require(newCondition.parameter1 > 0, "TV: MultiSig requires > 0 approvals");
                  bytes32 approverListHash = newCondition.parameter3; // Expects hash of approvers
                  require(multiSigApproverLists[approverListHash].length > 0, "TV: MultiSig approver list not found for hash");
                  newCondition.requiresExternalUpdate = true; // Needs explicit approvals
             } else if (newCondition.conditionType == ConditionType.TimeAbsolute || newCondition.conditionType == ConditionType.TimeRelative) {
                 newCondition.requiresExternalUpdate = false; // Checked on-chain
                 newCondition.isMet = _checkSingleCondition(_vaultId, i, newCondition); // Check immediately if already met
             } else {
                  revert("TV: Unknown condition type"); // Should not happen with enum
             }

             vault.conditions.push(newCondition);
             emit ConditionAdded(_vaultId, vault.conditions.length - 1, newCondition.conditionType);
         }
    }

    // Add a condition to a vault in Pending state
    function addConditionToVault(uint256 _vaultId, Condition calldata _condition)
        external
        whenVaultStateIs(_vaultId, VaultState.Pending)
    {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.depositor || vault.delegates[msg.sender].canAddConditions, "TV: Not authorized to add conditions");
        // Basic validation for condition types (similar to _addConditionsToVault)
        if (_condition.conditionType == ConditionType.OracleValue) {
            require(_condition.parameter2.isContract(), "TV: Oracle address must be a contract");
            // No validation of oracle implementation, relies on `registerOracle`
            _condition.requiresExternalUpdate = true;
        } else if (_condition.conditionType == ConditionType.AddressInteraction) {
            require(_condition.parameter2 != address(0), "TV: Target address cannot be zero");
             _condition.requiresExternalUpdate = true;
        } else if (_condition.conditionType == ConditionType.MultiSigApproval) {
             require(_condition.parameter1 > 0, "TV: MultiSig requires > 0 approvals");
             bytes32 approverListHash = _condition.parameter3; // Expects hash of approvers
             require(multiSigApproverLists[approverListHash].length > 0, "TV: MultiSig approver list not found for hash");
             _condition.requiresExternalUpdate = true; // Needs explicit approvals
        } else if (_condition.conditionType == ConditionType.TimeAbsolute || _condition.conditionType == ConditionType.TimeRelative) {
             _condition.requiresExternalUpdate = false;
        } else {
             revert("TV: Unknown condition type");
        }

        uint256 conditionIndex = vault.conditions.length;
        vault.conditions.push(_condition);

        // Check time conditions immediately if added
        if(!vault.conditions[conditionIndex].requiresExternalUpdate) {
            vault.conditions[conditionIndex].isMet = _checkSingleCondition(_vaultId, conditionIndex, vault.conditions[conditionIndex]);
        }


        emit ConditionAdded(_vaultId, conditionIndex, _condition.conditionType);
    }

    // Remove a condition from a vault in Pending state
    function removeConditionFromVault(uint256 _vaultId, uint256 _conditionIndex)
        external
        whenVaultStateIs(_vaultId, VaultState.Pending)
    {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.depositor || vault.delegates[msg.sender].canRemoveConditions, "TV: Not authorized to remove conditions");
        require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");

        // Simple remove by swapping with last and popping (order changes)
        uint256 lastIndex = vault.conditions.length - 1;
        if (_conditionIndex != lastIndex) {
            vault.conditions[_conditionIndex] = vault.conditions[lastIndex];
             // Need to potentially update MultiSig approval mapping indices if they were tied to index
             // For this implementation, MultiSig approvals are tied to condition index *and* vault ID
             // Moving a condition means its old approvals mapping still exists for the old index
             // If the swapped condition was MultiSig, its old index mapping is now tied to the condition moved to this index
             // This is complex. A better approach for removal if order matters or state is tied to index:
             // 1. Mark as "removed" but keep array length (wasteful storage)
             // 2. Recreate the array excluding the element (gas intensive)
             // Let's stick to the swap-and-pop for simplicity in this example, accepting index-based state loss/confusion on swap.
             // Alternatively, use a linked list or mapping for conditions (more complex code).
             // For MultiSig approvals specifically, we need to clear or manage the old index mapping carefully.
             // Clearing seems safest for this example:
             if(vault.conditions[_conditionIndex].conditionType == ConditionType.MultiSigApproval) {
                  delete multiSigApprovals[_vaultId][_conditionIndex]; // Clear state tied to the new index location (which was the old last index)
             }
              if(vault.conditions[lastIndex].conditionType == ConditionType.MultiSigApproval) {
                  delete multiSigApprovals[_vaultId][lastIndex]; // Clear state tied to the old last index
             }
        }
        vault.conditions.pop();

        emit ConditionRemoved(_vaultId, _conditionIndex);
    }

    // Transition vault from Pending to Locked
    function sealVault(uint256 _vaultId)
        external
        onlyVaultDepositor(_vaultId)
        whenVaultStateIs(_vaultId, VaultState.Pending)
    {
        vaults[_vaultId].state = VaultState.Locked;
        emit VaultSealed(_vaultId);
        emit VaultStateChanged(_vaultId, VaultState.Locked);
    }

    // --- Condition Fulfillment Functions ---

    // Internal helper to check a single condition's status
    // Does NOT update the condition's isMet field in storage unless it's a non-external condition
    // For external conditions, relies on explicit update functions (oracle, interaction, multi-sig)
    function _checkSingleCondition(uint256 _vaultId, uint256 _conditionIndex, Condition memory _condition) internal view returns (bool) {
        if (_condition.requiresExternalUpdate) {
            // For external conditions, we trust the `isMet` status was updated by authorized callers
            return _condition.isMet;
        }

        // Evaluate non-external conditions on-chain
        if (_condition.conditionType == ConditionType.TimeAbsolute) {
            return block.timestamp >= _condition.parameter1;
        } else if (_condition.conditionType == ConditionType.TimeRelative) {
            return block.timestamp >= vaults[_vaultId].creationTime + _condition.parameter1;
        }
        // Should not reach here for other types
        return false;
    }

     // Public view function to check if a single condition is met
     function isVaultConditionMet(uint256 _vaultId, uint256 _conditionIndex) external view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");
        return _checkSingleCondition(_vaultId, _conditionIndex, vault.conditions[_conditionIndex]);
     }


    // Public function to check all conditions and transition state if met
    // Callable by anyone to trigger the state change, externalizing gas cost
    function checkVaultConditionsAndTransition(uint256 _vaultId)
        external
        whenVaultStateIs(_vaultId, VaultState.Locked)
    {
        Vault storage vault = vaults[_vaultId];
        bool allMet = true;
        for (uint i = 0; i < vault.conditions.length; i++) {
             // Update isMet status for Time conditions if they require no external update
            if (!vault.conditions[i].requiresExternalUpdate && !vault.conditions[i].isMet) {
                 if(_checkSingleCondition(_vaultId, i, vault.conditions[i])) {
                     vault.conditions[i].isMet = true;
                     emit ConditionMet(_vaultId, i, vault.conditions[i].conditionType);
                 }
            }
            // Check if the condition is met
            if (!vault.conditions[i].isMet) {
                allMet = false;
                break; // No need to check further if one is not met
            }
        }

        emit ConditionsChecked(_vaultId, allMet);

        if (allMet) {
            vault.state = VaultState.ConditionsMet;
            emit VaultStateChanged(_vaultId, VaultState.ConditionsMet);
        }
    }

    // Called by a registered oracle to update the status of an OracleValue condition
    function updateOracleConditionStatus(uint256 _vaultId, uint256 _conditionIndex, bytes32 _oracleDataHash, bool _isMet)
        external
        onlyOracle()
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
        whenVaultStateIsNot(_vaultId, VaultState.EmergencyUnlocked) // Oracle updates irrelevant once emergency unlocked
    {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.OracleValue, "TV: Not an OracleValue condition");
        require(condition.parameter2 == msg.sender, "TV: Not target oracle for condition");
        require(condition.parameter3 == _oracleDataHash, "TV: Data hash mismatch");

        if (condition.isMet != _isMet) {
            condition.isMet = _isMet;
            emit ConditionMet(_vaultId, _conditionIndex, condition.conditionType);
        }
    }

    // Called by the target address of an AddressInteraction condition to mark it as met
    function triggerAddressInteractionCondition(uint256 _vaultId, uint256 _conditionIndex)
        external
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
        whenVaultStateIsNot(_vaultId, VaultState.EmergencyUnlocked)
    {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.AddressInteraction, "TV: Not an AddressInteraction condition");
        require(condition.parameter2 == msg.sender, "TV: Not target address for interaction");
        require(!condition.isMet, "TV: Condition already met");

        condition.isMet = true;
        emit ConditionMet(_vaultId, _conditionIndex, condition.conditionType);
    }

    // Add a list of approvers for a MultiSig condition hash (called initially before condition added)
    // Returns the hash to be used as parameter3 in the Condition struct
    function setMultiSigApprovers(address[] calldata _approvers) external returns (bytes32 approverListHash) {
         require(_approvers.length > 0, "TV: Approver list cannot be empty");
         // Simple hash of sorted addresses to create a unique identifier
         bytes memory encodedApprovers = abi.encode(_approvers); // Note: sorting _approvers before encoding is better for canonical hash
         approverListHash = keccak256(encodedApprovers);
         require(multiSigApproverLists[approverListHash].length == 0, "TV: Approver list hash already exists");

         multiSigApproverLists[approverListHash] = _approvers;
         // No event needed, as this is just setting up a list hash for later use
    }

     // Called by an authorized approver for a MultiSigApproval condition
     // Delegate needs canApproveConditions permission OR msg.sender is vault depositor
    function approveVaultCondition(uint256 _vaultId, uint256 _conditionIndex)
        external
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
        whenVaultStateIsNot(_vaultId, VaultState.EmergencyUnlocked)
    {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.MultiSigApproval, "TV: Not a MultiSigApproval condition");
        require(!condition.isMet, "TV: Condition already met");

        bytes32 approverListHash = condition.parameter3;
        address[] storage approvers = multiSigApproverLists[approverListHash];
        bool isApprover = false;
        for(uint i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        require(isApprover, "TV: Not an authorized approver for this condition");

        require(!multiSigApprovals[_vaultId][_conditionIndex][msg.sender], "TV: Already approved this condition");

        multiSigApprovals[_vaultId][_conditionIndex][msg.sender] = true;

        uint256 currentApprovals = getMultiSigConditionApprovalCount(_vaultId, _conditionIndex); // Call view function

        emit MultiSigApproved(_vaultId, _conditionIndex, msg.sender, currentApprovals);

        if (currentApprovals >= condition.parameter1) {
            condition.isMet = true;
             emit ConditionMet(_vaultId, _conditionIndex, condition.conditionType);
        }
    }

    // --- Release and Cancellation ---

    // Transfers locked assets to the beneficiary
    function releaseVaultAssets(uint256 _vaultId)
        external
        whenVaultStateIs(_vaultId, VaultState.ConditionsMet)
    {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.beneficiary || msg.sender == vault.depositor, "TV: Not beneficiary or depositor");

        vault.state = VaultState.Unlocked;
        emit VaultStateChanged(_vaultId, VaultState.Unlocked);

        _transferAssets(_vaultId);

        emit AssetsReleased(_vaultId, vault.beneficiary, vault.assetType);
    }

    // Initiates the emergency unlock process
    function initiateEmergencyUnlock(uint256 _vaultId)
        external
        whenVaultStateIsNot(_vaultId, VaultState.Pending)
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
        whenVaultStateIsNot(_vaultId, VaultState.EmergencyUnlocked)
    {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.depositor || vault.delegates[msg.sender].canInitiateEmergencyUnlock, "TV: Not authorized to initiate emergency unlock");

        vault.emergencyUnlockInitiatedTime = block.timestamp;
        vault.state = VaultState.EmergencyUnlocked;
        emit EmergencyUnlockInitiated(_vaultId, msg.sender);
        emit VaultStateChanged(_vaultId, VaultState.EmergencyUnlocked);
    }

    // Claims assets after the emergency unlock delay
    function claimEmergencyUnlock(uint256 _vaultId)
        external
        whenVaultStateIs(_vaultId, VaultState.EmergencyUnlocked)
    {
        Vault storage vault = vaults[_vaultId];
        require(block.timestamp >= vault.emergencyUnlockInitiatedTime + emergencyUnlockDelay, "TV: Emergency unlock delay period not passed");
         require(msg.sender == vault.beneficiary || msg.sender == vault.depositor, "TV: Not beneficiary or depositor");


        vault.state = VaultState.Unlocked;
        emit VaultStateChanged(_vaultId, VaultState.Unlocked);
        emit EmergencyUnlockClaimed(_vaultId);

        _transferAssets(_vaultId);

        // No EmergencyUnlockClaimed event, AssetsReleased is sufficient
         emit AssetsReleased(_vaultId, vault.beneficiary, vault.assetType);
    }


    // Cancels a vault in Pending state and returns assets to depositor
    function cancelVault(uint256 _vaultId)
        external
        onlyVaultDepositor(_vaultId)
        whenVaultStateIs(_vaultId, VaultState.Pending)
    {
        Vault storage vault = vaults[_vaultId];
        vault.state = VaultState.Cancelled;
        emit VaultStateChanged(_vaultId, VaultState.Cancelled);
        emit VaultCancelled(_vaultId, msg.sender);

        // Return assets to the depositor
        if (vault.assetType == AssetType.ETH) {
             // Use call for safety
             (bool success, ) = payable(vault.depositor).call{value: vault.tokenIdOrAmount}("");
             require(success, "TV: ETH transfer failed during cancel");
        } else if (vault.assetType == AssetType.ERC20) {
             IERC20 erc20Token = IERC20(vault.tokenAddress);
             bool success = erc20Token.transfer(vault.depositor, vault.tokenIdOrAmount);
             require(success, "TV: ERC20 transfer failed during cancel");
        } else if (vault.assetType == AssetType.ERC721) {
             IERC721 erc721Token = IERC721(vault.tokenAddress);
             erc721Token.safeTransferFrom(address(this), vault.depositor, vault.tokenIdOrAmount);
        }
        // Clear vault data after transfer? Depends on whether we want to keep records.
        // For simplicity, we keep the record but mark it Cancelled.
    }


    // Internal helper to transfer assets based on type
    function _transferAssets(uint256 _vaultId) internal {
        Vault storage vault = vaults[_vaultId];

        if (vault.assetType == AssetType.ETH) {
            (bool success, ) = payable(vault.beneficiary).call{value: vault.tokenIdOrAmount}("");
            require(success, "TV: ETH transfer failed during release");
        } else if (vault.assetType == AssetType.ERC20) {
            IERC20 erc20Token = IERC20(vault.tokenAddress);
            bool success = erc20Token.transfer(vault.beneficiary, vault.tokenIdOrAmount);
            require(success, "TV: ERC20 transfer failed during release");
        } else if (vault.assetType == AssetType.ERC721) {
            IERC721 erc721Token = IERC721(vault.tokenAddress);
            erc721Token.safeTransferFrom(address(this), vault.beneficiary, vault.tokenIdOrAmount);
        } else {
             revert("TV: Unknown asset type for transfer"); // Should not happen
        }
    }

    // --- Delegation Functions ---

    // Grant specific permissions to a delegate for a vault
    function delegateManagement(uint256 _vaultId, address _delegate, DelegatePermissions calldata _permissions)
        external
        onlyVaultDepositor(_vaultId)
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
    {
         require(_delegate != address(0), "TV: Invalid delegate address");
         Vault storage vault = vaults[_vaultId];
         vault.delegates[_delegate] = _permissions;
         emit DelegateManagementGranted(_vaultId, msg.sender, _delegate, _permissions);
    }

    // Revoke all permissions for a delegate for a vault
    function revokeDelegateManagement(uint256 _vaultId, address _delegate)
        external
        onlyVaultDepositor(_vaultId)
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
    {
         require(_delegate != address(0), "TV: Invalid delegate address");
         Vault storage vault = vaults[_vaultId];
         delete vault.delegates[_delegate];
         emit DelegateManagementRevoked(_vaultId, msg.sender, _delegate);
    }

    // Allows a delegate to remove their own permissions for a vault
     function renounceDelegateManagement(uint256 _vaultId)
        external
        whenVaultStateIsNot(_vaultId, VaultState.Unlocked)
        whenVaultStateIsNot(_vaultId, VaultState.Cancelled)
     {
        Vault storage vault = vaults[_vaultId];
        require(vault.delegates[msg.sender].canAddConditions || // Check if sender is actually a delegate with any perm
                vault.delegates[msg.sender].canRemoveConditions ||
                vault.delegates[msg.sender].canApproveConditions ||
                vault.delegates[msg.sender].canInitiateEmergencyUnlock,
                "TV: Not a delegate for this vault");

         delete vault.delegates[msg.sender];
         emit DelegateRenounced(_vaultId, msg.sender);
     }

    // --- Querying & Viewing Functions ---

    // Returns core details of a vault
    function getVaultDetails(uint256 _vaultId)
        external
        view
        returns (address depositor, address beneficiary, AssetType assetType, address tokenAddress, uint256 tokenIdOrAmount, uint256 creationTime, VaultState state, uint256 emergencyUnlockInitiatedTime)
    {
        Vault storage vault = vaults[_vaultId];
        return (vault.depositor, vault.beneficiary, vault.assetType, vault.tokenAddress, vault.tokenIdOrAmount, vault.creationTime, vault.state, vault.emergencyUnlockInitiatedTime);
    }

    // Returns the list of conditions for a vault
    function getVaultConditions(uint256 _vaultId) external view returns (Condition[] memory) {
         return vaults[_vaultId].conditions;
    }

    // Returns the permissions for a specific delegate for a vault
    function getVaultDelegatePermissions(uint256 _vaultId, address _delegate) external view returns (DelegatePermissions memory) {
         return vaults[_vaultId].delegates[_delegate];
    }

     // Note: getVaultDelegates returning *all* delegates in a mapping is not directly possible in Solidity views without knowing all keys.
     // A workaround is needed if you need a list of delegate addresses. For this example, we provide a way to check a specific address.
     // Keeping the summary function name but noting implementation limitation. Users would query `getVaultDelegatePermissions(vaultId, address)` for specific addresses.
     // Renaming summary function name to reflect reality.
     // 20. (Renamed) `getVaultDelegatePermissions(uint256 _vaultId, address _delegate)`

    // Returns the current state of a vault
    function getVaultState(uint256 _vaultId) external view returns (VaultState) {
         return vaults[_vaultId].state;
    }

    // Returns the required approvers for a MultiSig condition, identified by its hash
    function getMultiSigConditionApprovers(bytes32 _approverListHash) external view returns (address[] memory) {
        return multiSigApproverLists[_approverListHash];
    }

    // Returns the current approval count for a MultiSig condition
    function getMultiSigConditionApprovalCount(uint256 _vaultId, uint256 _conditionIndex) external view returns (uint256 count) {
         Vault storage vault = vaults[_vaultId];
         require(_conditionIndex < vault.conditions.length, "TV: Invalid condition index");
         Condition storage condition = vault.conditions[_conditionIndex];
         require(condition.conditionType == ConditionType.MultiSigApproval, "TV: Not a MultiSigApproval condition");

         bytes32 approverListHash = condition.parameter3;
         address[] storage approvers = multiSigApproverLists[approverListHash];

         for(uint i = 0; i < approvers.length; i++) {
             if (multiSigApprovals[_vaultId][_conditionIndex][approvers[i]]) {
                 count++;
             }
         }
         return count;
    }

    // Returns a list of vault IDs created by a specific depositor
    function getVaultsByDepositor(address _depositor) external view returns (uint256[] memory) {
        return vaultsByDepositor[_depositor];
    }

    // Returns a list of vault IDs where the address is the beneficiary
    function getVaultsByBeneficiary(address _beneficiary) external view returns (uint256[] memory) {
        return vaultsByBeneficiary[_beneficiary];
    }

    // There were 27 functions in the summary, let's double check we implemented at least 20 external/public ones:
    // 1. createVaultETH
    // 2. createVaultERC20
    // 3. onERC721Received (Public, required by interface)
    // 4. addConditionToVault
    // 5. removeConditionFromVault
    // 6. sealVault
    // 7. checkVaultConditionsAndTransition
    // 8. updateOracleConditionStatus
    // 9. triggerAddressInteractionCondition
    // 10. setMultiSigApprovers (New helper for MultiSig setup)
    // 11. approveVaultCondition
    // 12. releaseVaultAssets
    // 13. initiateEmergencyUnlock
    // 14. claimEmergencyUnlock
    // 15. cancelVault
    // 16. delegateManagement
    // 17. revokeDelegateManagement
    // 18. renounceDelegateManagement
    // 19. getVaultDetails (View)
    // 20. getVaultConditions (View)
    // 21. getVaultDelegatePermissions (View) - Updated name
    // 22. getVaultState (View)
    // 23. isVaultConditionMet (View) - New helper view
    // 24. getMultiSigConditionApprovers (View)
    // 25. getMultiSigConditionApprovalCount (View)
    // 26. getVaultsByDepositor (View)
    // 27. getVaultsByBeneficiary (View)
    // 28. registerOracle

    // Yes, we have well over 20 external/public functions.

}
```