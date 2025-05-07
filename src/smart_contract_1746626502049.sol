Okay, let's create a smart contract that acts as a sophisticated, multi-conditional vault. We'll call it `QuantumVault`.

The concept is that assets (ETH, ERC20, ERC721, ERC1155) can be locked in the vault and associated with one or *multiple* sets of release conditions simultaneously (the "quantum superposition" concept). The *first* condition set that is met triggers the release of the associated assets to a designated beneficiary (the "measurement").

Conditions can be varied: time-based, oracle price feeds, external contract states, verifiable randomness, manual oracle verification, or even the state of another `QuantumVault`.

This goes beyond simple time-locks or single-condition escrows.

---

### `QuantumVault` Smart Contract Outline

1.  **Purpose:** A multi-asset, multi-conditional escrow/vault contract. Assets are locked and released based on complex, user-defined condition sets.
2.  **Core Concepts:**
    *   **Multi-Asset Support:** Handles ETH, ERC20, ERC721, ERC1155.
    *   **Condition Sets:** Bundles of conditions that must *all* be met for release.
    *   **Condition Superposition:** The *same* locked assets can be linked to *multiple* condition sets.
    *   **Measurement/Trigger:** The first condition set linked to specific assets that becomes true triggers their release.
    *   **Varied Conditions:** Supports time, external data (simulated oracle), contract state, randomness, manual oracle approval, nested vault state.
    *   **Roles:** Owner, Condition Oracle (for manual approvals), Asset Controller (for initial locking).
3.  **Key State Variables:**
    *   Counters for unique IDs (Condition Sets, Conditions, Locked Assets).
    *   Mappings for `ConditionSet` details.
    *   Mappings for `Condition` details.
    *   Mappings for `LockedAssetInfo`.
    *   Mapping linking `ConditionSet` IDs to `LockedAssetInfo` IDs (the "superposition" link).
    *   Mapping tracking roles (`ConditionOracle`, `AssetController`).
    *   Mapping for manual Oracle approvals.
    *   Mapping for tracking VRF requests (if using Chainlink VRF).
    *   Mapping for external contract call conditions.
4.  **Interfaces/Libraries:** Ownable, SafeERC20, IERC20, IERC721, IERC1155. Chainlink VRF interfaces (if implementing VRF directly, for this example, we'll simulate/note the integration point).
5.  **Events:** Significant state changes (Locking, Release, ConditionSet creation, Role changes, Condition met, etc.).
6.  **Error Handling:** `require` statements for invalid input, permissions, state.
7.  **Functions (>= 20):** See detailed summary below.

### `QuantumVault` Function Summary

**Administrative & Roles (4)**
1.  `constructor`: Deploys the contract, sets owner.
2.  `addConditionOracle`: Grants the Condition Oracle role.
3.  `removeConditionOracle`: Revokes the Condition Oracle role.
4.  `addAssetController`: Grants the Asset Controller role.
5.  `removeAssetController`: Revokes the Asset Controller role.
6.  `transferOwnership`: Transfers contract ownership.
7.  `renounceOwnership`: Renounces contract ownership.

**Condition Set & Condition Management (7)**
8.  `createConditionSet`: Creates a new, empty set of conditions.
9.  `addConditionToSet`: Adds a single condition to an existing set.
10. `addConditionsToSet`: Adds multiple conditions to an existing set.
11. `removeConditionFromSet`: Removes a condition from a set (if not yet met).
12. `setConditionSetBeneficiary`: Sets the recipient address for assets released by this set.
13. `updateConditionSetBeneficiary`: Updates the recipient address (owner/oracle permissions).
14. `cancelConditionSet`: Cancels a condition set and potentially returns assets (owner/oracle permissions, only if assets aren't released yet).

**Asset Locking (4)**
15. `lockETH`: Locks Ether into the vault under a specified condition set(s).
16. `lockERC20`: Locks ERC20 tokens.
17. `lockERC721`: Locks ERC721 tokens.
18. `lockERC1155`: Locks ERC1155 tokens.

**Condition Linkage & Superposition (2)**
19. `linkAssetsToConditionSet`: Associates specific locked assets with an *additional* condition set ID (enabling superposition).
20. `unlinkAssetsFromConditionSet`: Removes the association between specific locked assets and a condition set (if the set hasn't triggered).

**Condition Checking & Triggering (5)**
21. `checkConditionSetStatus`: Checks if a specific condition set is currently met (view function).
22. `manualOracleConditionCheck`: Allows a Condition Oracle to manually approve/reject an `OracleApproval` type condition.
23. `requestRandomness`: Initiates a request for verifiable randomness (requires VRF integration).
24. `fulfillRandomness`: VRF callback function to receive randomness result and check associated conditions.
25. `triggerRelease`: Attempts to trigger the release of assets linked to a specific condition set. This function checks if the set is met and, if so, releases the assets and cleans up state.

**View Functions (>= 4)**
26. `getConditionSetDetails`: Retrieves the details of a condition set.
27. `getConditionDetails`: Retrieves the details of a specific condition.
28. `getLockedAssetInfo`: Retrieves details about a specific locked asset entry.
29. `getAssetsLinkedToConditionSet`: Lists locked assets linked to a specific condition set.
30. `getManualOracleApproval`: Checks the status of a manual oracle approval for a specific condition.

*(Note: The count easily reaches 20+ functions covering the outlined logic and state queries.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Assuming Chainlink VRF or similar for randomness - using dummy interface for example
interface IDummyVRFCoordinator {
    function requestRandomWords(uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords, bytes32 keyHash) external returns (uint256 requestId);
}

interface IDummyVRFConsumer {
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}

// Assuming a simple interface for external contract calls as conditions
interface IExternalConditionChecker {
    function checkCondition(bytes calldata data) external view returns (bool);
}

// Assuming a simple interface for nested QuantumVault state check
interface IQuantumVault {
    function checkConditionSetStatus(uint256 conditionSetId) external view returns (bool);
}


/**
 * @title QuantumVault
 * @dev A multi-asset, multi-conditional escrow/vault contract.
 * Assets can be locked and linked to multiple sets of release conditions (superposition).
 * The first condition set met triggers the release (measurement).
 * Supports ETH, ERC20, ERC721, ERC1155 and various condition types.
 * Includes roles for granular control.
 */
contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // --- Outline ---
    // 1. Purpose: Advanced multi-asset, multi-conditional escrow.
    // 2. Core Concepts: Multi-asset, Condition Sets, Superposition, Measurement/Trigger, Varied Conditions, Roles.
    // 3. Key State Variables: Counters, ConditionSet/Condition/LockedAsset Mappings, Superposition Links, Roles, Oracle Approvals, VRF tracking, External Call data.
    // 4. Interfaces/Libraries: Ownable, SafeERC20, ERC interfaces, Dummy VRF, Dummy External Checker, Dummy Nested Vault.
    // 5. Events: Locking, Release, ConditionSet Management, Role Changes, Condition Status, VRF.
    // 6. Error Handling: Require statements.
    // 7. Functions: Admin/Roles (7), Condition/Set Management (7), Asset Locking (4), Condition Linkage (2), Checking/Triggering (5), View (>=4). Total >= 20.

    // --- Function Summary ---
    // Admin & Roles:
    // constructor()
    // addConditionOracle(address account)
    // removeConditionOracle(address account)
    // addAssetController(address account)
    // removeAssetController(address account)
    // transferOwnership(address newOwner)
    // renounceOwnership()
    // Condition Set & Condition Management:
    // createConditionSet() returns (uint256)
    // addConditionToSet(uint256 setId, ConditionType _type, bytes memory params)
    // addConditionsToSet(uint256 setId, ConditionType[] memory _types, bytes[] memory params)
    // removeConditionFromSet(uint256 setId, uint256 conditionId)
    // setConditionSetBeneficiary(uint256 setId, address beneficiary)
    // updateConditionSetBeneficiary(uint256 setId, address newBeneficiary)
    // cancelConditionSet(uint256 setId)
    // Asset Locking:
    // lockETH(uint256 setId) payable
    // lockERC20(uint256 setId, address token, uint256 amount)
    // lockERC721(uint256 setId, address token, uint256 tokenId)
    // lockERC1155(uint256 setId, address token, uint256 id, uint256 amount)
    // Condition Linkage & Superposition:
    // linkAssetsToConditionSet(uint256[] memory assetIds, uint256 setId)
    // unlinkAssetsFromConditionSet(uint256[] memory assetIds, uint256 setId)
    // Condition Checking & Triggering:
    // checkConditionSetStatus(uint256 setId) public view returns (bool)
    // manualOracleConditionCheck(uint256 conditionId, bool approved)
    // requestRandomness(uint256 conditionId, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) returns (uint256) // Integrated with VRF
    // fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) // VRF callback
    // triggerRelease(uint256 setId)
    // View Functions:
    // getConditionSetDetails(uint256 setId) public view returns (...)
    // getConditionDetails(uint256 conditionId) public view returns (...)
    // getLockedAssetInfo(uint256 assetId) public view returns (...)
    // getAssetsLinkedToConditionSet(uint256 setId) public view returns (uint256[] memory)
    // getManualOracleApproval(uint256 conditionId) public view returns (bool approved, bool set)

    // --- State Variables ---

    uint256 private _nextConditionSetId = 1;
    uint256 private _nextConditionId = 1;
    uint256 private _nextLockedAssetId = 1;

    enum ConditionType {
        None,
        TimeLock,           // params: uint256 unlockTimestamp
        ERC20BalanceGE,     // params: address token, uint256 threshold, address accountToCheck
        ERC721Owned,        // params: address token, uint256 tokenId, address accountToCheck
        ERC1155BalanceGE,   // params: address token, uint256 id, uint256 threshold, address accountToCheck
        OraclePriceGE,      // params: address priceFeed, uint256 thresholdScaled (simulate using priceFeed address)
        OracleApproval,     // params: address oracleAddress (optional, any oracle can approve if 0x0)
        VerifiableRandomness,// params: bytes32 vrfKeyHash, uint256 modulus (random number % modulus == 0) - requires VRF
        ExternalContractCall,// params: address targetContract, bytes callData - requires interface like IExternalConditionChecker
        NestedVaultState    // params: address targetVault, uint256 targetConditionSetId - requires interface like IQuantumVault
    }

    struct Condition {
        ConditionType conditionType;
        bytes params; // Abi-encoded parameters specific to the condition type
    }

    struct ConditionSet {
        address beneficiary;
        uint256[] conditionIds;
        bool isMet;
        bool cancelled; // Owner/Oracle can cancel before met
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    struct LockedAssetInfo {
        AssetType assetType;
        address tokenAddress; // 0x0 for ETH
        uint256 amountOrId; // Amount for ETH/ERC20/ERC1155, tokenId for ERC721
        uint256 erc1155Value; // Amount for ERC1155, 0 otherwise
        uint256[] linkedConditionSets; // IDs of Condition Sets this asset is linked to (superposition)
        bool released; // True if already released
    }

    // Mappings for state
    mapping(uint256 => ConditionSet) public conditionSets;
    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => LockedAssetInfo) public lockedAssets;

    // Mapping for Superposition Linkage: ConditionSetId => Array of LockedAssetIds
    mapping(uint256 => uint256[]) private _conditionSetLinkedAssets;

    // Roles
    mapping(address => bool) public isConditionOracle;
    mapping(address => bool) public isAssetController; // Can lock assets (owner is also an Asset Controller)

    // State for Oracle Approval conditions
    mapping(uint256 => mapping(address => bool)) private _oracleConditionApproval; // conditionId => oracleAddress => approved
    mapping(uint256 => bool) private _oracleConditionSet; // conditionId => bool (whether approval has been set)

    // State for Verifiable Randomness conditions
    mapping(uint256 => uint256) private _vrfRequestConditionId; // requestId => conditionId
    mapping(uint256 => uint256[]) private _vrfResult; // conditionId => randomWords
    mapping(uint256 => bool) private _vrfFulfilled; // conditionId => bool (whether randomness is received)

    // Placeholder/example addresses for Oracles/VRF/External Contracts (replace with real ones)
    address public dummyPriceFeedAddress;
    IDummyVRFCoordinator public dummyVRFCoordinator;
    bytes32 public dummyVRFKeyHash; // Example key hash

    // Events
    event ConditionSetCreated(uint256 indexed setId, address indexed creator);
    event ConditionAdded(uint256 indexed setId, uint256 indexed conditionId, ConditionType conditionType);
    event ConditionRemoved(uint256 indexed setId, uint256 indexed conditionId);
    event ConditionSetBeneficiaryUpdated(uint256 indexed setId, address indexed oldBeneficiary, address indexed newBeneficiary);
    event ConditionSetCancelled(uint256 indexed setId);

    event AssetsLocked(uint256 indexed assetId, uint256 indexed setId, AssetType assetType, address indexed tokenAddress, uint256 amountOrId, uint256 erc1155Value);
    event AssetsLinked(uint256 indexed assetId, uint256 indexed setId);
    event AssetsUnlinked(uint256 indexed assetId, uint256 indexed setId);
    event AssetsReleased(uint256 indexed setId, address indexed beneficiary, uint256[] releasedAssetIds);

    event RoleGranted(address indexed account, string role);
    event RoleRevoked(address indexed account, string role);

    event OracleConditionApproved(uint256 indexed conditionId, address indexed oracle);
    event OracleConditionRejected(uint256 indexed conditionId, address indexed oracle);
    event VRFRandomnessRequested(uint256 indexed conditionId, uint256 indexed requestId);
    event VRFRandomnessReceived(uint256 indexed conditionId, uint256 indexed requestId);
    event ExternalConditionChecked(uint256 indexed conditionId, bool result);
    event NestedVaultConditionChecked(uint256 indexed conditionId, bool result);


    // --- Constructor ---

    constructor(address initialOracle, address initialAssetController) Ownable(msg.sender) {
        isConditionOracle[initialOracle] = true;
        emit RoleGranted(initialOracle, "ConditionOracle");
        isAssetController[initialAssetController] = true; // Owner is also an AssetController by default
        emit RoleGranted(initialAssetController, "AssetController");
        isAssetController[msg.sender] = true; // Owner is also an AssetController
        emit RoleGranted(msg.sender, "AssetController");

        // Initialize dummy oracle/VRF addresses for example (replace with actual in deployment)
        dummyPriceFeedAddress = initialOracle; // Using initialOracle address as dummy price feed for example
        // dummyVRFCoordinator = IDummyVRFCoordinator(0x...); // Replace with actual VRF Coordinator address
        // dummyVRFKeyHash = 0x...; // Replace with actual VRF key hash
    }

    // --- Admin & Roles Functions ---

    /**
     * @dev Grants the Condition Oracle role to an account.
     * Only callable by the Owner.
     * Condition Oracles can approve/reject manual `OracleApproval` conditions.
     */
    function addConditionOracle(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(!isConditionOracle[account], "Already an oracle");
        isConditionOracle[account] = true;
        emit RoleGranted(account, "ConditionOracle");
    }

    /**
     * @dev Revokes the Condition Oracle role from an account.
     * Only callable by the Owner.
     */
    function removeConditionOracle(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(isConditionOracle[account], "Not an oracle");
        isConditionOracle[account] = false;
        emit RoleRevoked(account, "ConditionOracle");
    }

    /**
     * @dev Grants the Asset Controller role to an account.
     * Only callable by the Owner.
     * Asset Controllers can lock assets into the vault.
     */
    function addAssetController(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(!isAssetController[account], "Already a controller");
        isAssetController[account] = true;
        emit RoleGranted(account, "AssetController");
    }

    /**
     * @dev Revokes the Asset Controller role from an account.
     * Only callable by the Owner.
     */
    function removeAssetController(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        require(isAssetController[account], "Not a controller");
        require(account != owner(), "Cannot remove owner role"); // Owner is always a controller
        isAssetController[account] = false;
        emit RoleRevoked(account, "AssetController");
    }

    // transferOwnership and renounceOwnership are inherited from Ownable

    // --- Condition Set & Condition Management Functions ---

    /**
     * @dev Creates a new, empty condition set.
     * Returns the ID of the newly created set.
     */
    function createConditionSet() external returns (uint256) {
        uint256 setId = _nextConditionSetId++;
        conditionSets[setId].beneficiary = address(0); // Must be set later
        conditionSets[setId].isMet = false;
        conditionSets[setId].cancelled = false;
        // conditionIds array is initialized empty
        emit ConditionSetCreated(setId, msg.sender);
        return setId;
    }

    /**
     * @dev Adds a single condition to an existing condition set.
     * Only callable by the Owner or Asset Controller who created the set (or owner if no controller specified).
     * Can only add conditions to sets that haven't been met or cancelled.
     * @param setId The ID of the condition set.
     * @param _type The type of condition.
     * @param params Abi-encoded parameters for the condition.
     */
    function addConditionToSet(uint256 setId, ConditionType _type, bytes memory params) external {
        // require(conditionSets[setId].beneficiary != address(0), "Beneficiary must be set first"); // Or allow adding conditions before beneficiary? Let's allow first.
        require(conditionSets[setId].beneficiary != address(0) || _conditionSetLinkedAssets[setId].length == 0, "Cannot add conditions to set with linked assets if beneficiary is not set");
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");
        // Ownership check: Only owner or the person who created/linked assets to this set can modify?
        // For simplicity, let's allow only the owner or initial Asset Controller for now.
        // require(msg.sender == owner() || (isAssetController[msg.sender] && ... check if this controller linked assets ...), "Unauthorized");
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access for example

        uint256 conditionId = _nextConditionId++;
        conditions[conditionId] = Condition(_type, params);
        conditionSets[setId].conditionIds.push(conditionId);

        emit ConditionAdded(setId, conditionId, _type);
    }

    /**
     * @dev Adds multiple conditions to an existing condition set.
     * @param setId The ID of the condition set.
     * @param _types Array of condition types.
     * @param params Array of abi-encoded parameters for conditions (must match _types length).
     */
    function addConditionsToSet(uint256 setId, ConditionType[] memory _types, bytes[] memory params) external {
        require(_types.length == params.length, "Mismatched types and params length");
         require(conditionSets[setId].beneficiary != address(0) || _conditionSetLinkedAssets[setId].length == 0, "Cannot add conditions to set with linked assets if beneficiary is not set");
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access

        for (uint i = 0; i < _types.length; i++) {
            uint256 conditionId = _nextConditionId++;
            conditions[conditionId] = Condition(_types[i], params[i]);
            conditionSets[setId].conditionIds.push(conditionId);
            emit ConditionAdded(setId, conditionId, _types[i]);
        }
    }

     /**
     * @dev Removes a condition from a set.
     * Can only be done by Owner or an Asset Controller before the set is met or cancelled.
     * Note: This shifts array elements, gas intensive for large sets.
     * @param setId The ID of the condition set.
     * @param conditionId The ID of the condition to remove.
     */
    function removeConditionFromSet(uint256 setId, uint256 conditionId) external {
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access
        require(conditionSets[setId].beneficiary != address(0) || _conditionSetLinkedAssets[setId].length == 0, "Cannot remove conditions from set with linked assets if beneficiary is not set");
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");

        uint256[] storage conditionIds = conditionSets[setId].conditionIds;
        bool found = false;
        for (uint i = 0; i < conditionIds.length; i++) {
            if (conditionIds[i] == conditionId) {
                // Remove by swapping with last element and popping
                conditionIds[i] = conditionIds[conditionIds.length - 1];
                conditionIds.pop();
                found = true;
                // Optionally, mark the individual condition as invalid
                // conditions[conditionId].conditionType = ConditionType.None;
                break;
            }
        }
        require(found, "Condition not found in set");
        emit ConditionRemoved(setId, conditionId);
    }


    /**
     * @dev Sets the beneficiary address for a condition set.
     * Must be set before linking assets.
     * Can only be done by Owner or the Asset Controller who created the set.
     * @param setId The ID of the condition set.
     * @param beneficiary The address to receive assets when the set is met.
     */
    function setConditionSetBeneficiary(uint256 setId, address beneficiary) external {
        require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access
        require(beneficiary != address(0), "Zero address beneficiary");
        require(conditionSets[setId].beneficiary == address(0), "Beneficiary already set"); // Cannot overwrite
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");

        conditionSets[setId].beneficiary = beneficiary;
        emit ConditionSetBeneficiaryUpdated(setId, address(0), beneficiary);
    }

    /**
     * @dev Updates the beneficiary address for a condition set.
     * Can only be done by Owner or Condition Oracle *before* the set is met or cancelled.
     * @param setId The ID of the condition set.
     * @param newBeneficiary The new address to receive assets.
     */
    function updateConditionSetBeneficiary(uint256 setId, address newBeneficiary) external {
        require(msg.sender == owner() || isConditionOracle[msg.sender], "Unauthorized");
        require(newBeneficiary != address(0), "Zero address beneficiary");
        require(conditionSets[setId].beneficiary != address(0), "Beneficiary not set");
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");

        address oldBeneficiary = conditionSets[setId].beneficiary;
        conditionSets[setId].beneficiary = newBeneficiary;
        emit ConditionSetBeneficiaryUpdated(setId, oldBeneficiary, newBeneficiary);
    }

    /**
     * @dev Cancels a condition set.
     * Can only be done by the Owner or a Condition Oracle before the set is met.
     * Linked assets might become inaccessible if this was their only linked set,
     * unless `unlinkAssetsFromConditionSet` is used first or another set is linked.
     * Assets remain locked unless relinked or the vault is shut down (emergency).
     * @param setId The ID of the condition set to cancel.
     */
    function cancelConditionSet(uint256 setId) external {
        require(msg.sender == owner() || isConditionOracle[msg.sender], "Unauthorized");
        require(conditionSets[setId].beneficiary != address(0), "Condition set does not exist or beneficiary not set"); // Simple existence check
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set already cancelled");

        conditionSets[setId].cancelled = true;
        // Note: Assets are NOT automatically returned upon cancellation.
        // They remain locked unless linked to another active condition set or manually handled.
        emit ConditionSetCancelled(setId);
    }


    // --- Asset Locking Functions ---

    /**
     * @dev Locks ETH in the vault and links it to one or more condition sets.
     * Caller must be an Asset Controller.
     * Requires beneficiary to be set for all specified sets.
     * @param setIds IDs of the condition sets to link this ETH deposit to.
     */
    function lockETH(uint256[] memory setIds) external payable {
        require(isAssetController[msg.sender], "Not an Asset Controller");
        require(msg.value > 0, "Must send ETH");
        require(setIds.length > 0, "Must link to at least one condition set");

        uint256 assetId = _nextLockedAssetId++;
        lockedAssets[assetId] = LockedAssetInfo(AssetType.ETH, address(0), msg.value, 0, new uint256[](0), false);

        _linkAssetToSets(assetId, setIds);

        for(uint i = 0; i < setIds.length; i++) {
             require(conditionSets[setIds[i]].beneficiary != address(0), "Beneficiary not set for one or more condition sets");
             require(!conditionSets[setIds[i]].isMet && !conditionSets[setIds[i]].cancelled, "Cannot link to met or cancelled set");
        }

        emit AssetsLocked(assetId, setIds[0], AssetType.ETH, address(0), msg.value, 0); // Log with first set ID for simplicity
    }

    /**
     * @dev Locks ERC20 tokens.
     * Caller must be an Asset Controller and must have approved the contract to spend the tokens.
     * Requires beneficiary to be set for all specified sets.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to lock.
     * @param setIds IDs of the condition sets to link these tokens to.
     */
    function lockERC20(address token, uint256 amount, uint256[] memory setIds) external {
        require(isAssetController[msg.sender], "Not an Asset Controller");
        require(amount > 0, "Amount must be greater than 0");
        require(setIds.length > 0, "Must link to at least one condition set");

        IERC20 erc20 = IERC20(token);
        erc20.safeTransferFrom(msg.sender, address(this), amount);

        uint256 assetId = _nextLockedAssetId++;
        lockedAssets[assetId] = LockedAssetInfo(AssetType.ERC20, token, amount, 0, new uint256[](0), false);

        _linkAssetToSets(assetId, setIds);

         for(uint i = 0; i < setIds.length; i++) {
             require(conditionSets[setIds[i]].beneficiary != address(0), "Beneficiary not set for one or more condition sets");
             require(!conditionSets[setIds[i]].isMet && !conditionSets[setIds[i]].cancelled, "Cannot link to met or cancelled set");
        }

        emit AssetsLocked(assetId, setIds[0], AssetType.ERC20, token, amount, 0);
    }

    /**
     * @dev Locks ERC721 tokens.
     * Caller must be an Asset Controller and must have approved the contract or all tokens.
     * Requires beneficiary to be set for all specified sets.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to lock.
     * @param setIds IDs of the condition sets to link this token to.
     */
    function lockERC721(address token, uint256 tokenId, uint256[] memory setIds) external {
        require(isAssetController[msg.sender], "Not an Asset Controller");
        require(setIds.length > 0, "Must link to at least one condition set");

        IERC721 erc721 = IERC721(token);
        require(erc721.ownerOf(tokenId) == msg.sender, "Caller does not own the token");
        erc721.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 assetId = _nextLockedAssetId++;
        // For ERC721, amountOrId is the tokenId, erc1155Value is 0
        lockedAssets[assetId] = LockedAssetInfo(AssetType.ERC721, token, tokenId, 0, new uint256[](0), false);

        _linkAssetToSets(assetId, setIds);

        for(uint i = 0; i < setIds.length; i++) {
             require(conditionSets[setIds[i]].beneficiary != address(0), "Beneficiary not set for one or more condition sets");
             require(!conditionSets[setIds[i]].isMet && !conditionSets[setIds[i]].cancelled, "Cannot link to met or cancelled set");
        }

        emit AssetsLocked(assetId, setIds[0], AssetType.ERC721, token, tokenId, 0);
    }

    /**
     * @dev Locks ERC1155 tokens.
     * Caller must be an Asset Controller and must have approved the contract.
     * Requires beneficiary to be set for all specified sets.
     * @param token The address of the ERC1155 token.
     * @param id The ID of the token type.
     * @param amount The amount of tokens to lock.
     * @param setIds IDs of the condition sets to link these tokens to.
     */
    function lockERC1155(address token, uint256 id, uint256 amount, uint256[] memory setIds) external {
        require(isAssetController[msg.sender], "Not an Asset Controller");
        require(amount > 0, "Amount must be greater than 0");
        require(setIds.length > 0, "Must link to at least one condition set");

        IERC1155 erc1155 = IERC1155(token);
        require(erc1155.balanceOf(msg.sender, id) >= amount, "Caller does not have sufficient balance");
        erc1155.safeTransferFrom(msg.sender, address(this), msg.sender, id, amount, "");

        uint256 assetId = _nextLockedAssetId++;
        // For ERC1155, amountOrId is the id, erc1155Value is the amount
        lockedAssets[assetId] = LockedAssetInfo(AssetType.ERC1155, token, id, amount, new uint256[](0), false);

        _linkAssetToSets(assetId, setIds);

        for(uint i = 0; i < setIds.length; i++) {
             require(conditionSets[setIds[i]].beneficiary != address(0), "Beneficiary not set for one or more condition sets");
             require(!conditionSets[setIds[i]].isMet && !conditionSets[setIds[i]].cancelled, "Cannot link to met or cancelled set");
        }

        emit AssetsLocked(assetId, setIds[0], AssetType.ERC1155, token, id, amount);
    }


    // --- Condition Linkage & Superposition Functions ---

    /**
     * @dev Internal helper to link assets to multiple condition sets.
     * Ensures sets exist, are not met/cancelled, and have a beneficiary.
     * @param assetId The ID of the locked asset entry.
     * @param setIds The IDs of the condition sets to link to.
     */
    function _linkAssetToSets(uint256 assetId, uint256[] memory setIds) internal {
        LockedAssetInfo storage asset = lockedAssets[assetId];
        require(!asset.released, "Asset already released");

        for (uint i = 0; i < setIds.length; i++) {
            uint256 setId = setIds[i];
            require(conditionSets[setId].beneficiary != address(0), "Condition set does not exist or beneficiary not set");
            require(!conditionSets[setId].isMet, "Condition set already met");
            require(!conditionSets[setId].cancelled, "Condition set cancelled");

            // Check if already linked to prevent duplicates in linkedConditionSets
            bool alreadyLinked = false;
            for (uint j = 0; j < asset.linkedConditionSets.length; j++) {
                if (asset.linkedConditionSets[j] == setId) {
                    alreadyLinked = true;
                    break;
                }
            }
            if (!alreadyLinked) {
                asset.linkedConditionSets.push(setId);
                _conditionSetLinkedAssets[setId].push(assetId); // Maintain reverse mapping
                emit AssetsLinked(assetId, setId);
            }
        }
    }

    /**
     * @dev Associates specific locked assets with an *additional* condition set ID.
     * This enables the "superposition" where assets can be released by multiple criteria.
     * Can only be done by Owner or Asset Controller who locked the asset (or owner if no controller specified).
     * Sets must exist, not be met/cancelled, and have a beneficiary.
     * @param assetIds IDs of the locked asset entries.
     * @param setId The ID of the condition set to link to.
     */
    function linkAssetsToConditionSet(uint256[] memory assetIds, uint256 setId) external {
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access

        for (uint i = 0; i < assetIds.length; i++) {
            _linkAssetToSets(assetIds[i], new uint256[](1). 어떻게 linkAssetsToConditionSet 함수를 구현할 때, assetIds 배열과 setId를 인자로 받아서 _linkAssetToSets 내부 함수를 호출하는 부분을 수정해야 하나요? _linkAssetToSets 함수는 assetId와 setIds 배열을 받는데, 외부 함수 linkAssetsToConditionSet에서는 assetIds 배열과 setId 하나를 받습니다. assetIds의 각 요소에 대해 setId를 담은 배열을 만들어 전달해야 합니다.

수정된 부분: `_linkAssetToSets(assetIds[i], new uint256[](1).push(setId));` 이 부분은 solidity에서 지원하는 방식이 아닙니다. `new uint256[](1)`은 고정 크기 배열을 생성하고 `push`는 동적 배열에 사용하는 메서드입니다. 고정 크기 배열은 `push`를 지원하지 않습니다.

수정된 코드 제안: 각 `assetIds[i]`에 대해 `setId` 하나만 담은 임시 배열을 생성하여 `_linkAssetToSets`에 전달해야 합니다.

```solidity
    /**
     * @dev Associates specific locked assets with an *additional* condition set ID.
     * This enables the "superposition" where assets can be released by multiple criteria.
     * Can only be done by Owner or Asset Controller who locked the asset (or owner if no controller specified).
     * Sets must exist, not be met/cancelled, and have a beneficiary.
     * @param assetIds IDs of the locked asset entries.
     * @param setId The ID of the condition set to link to.
     */
    function linkAssetsToConditionSet(uint256[] memory assetIds, uint256 setId) external {
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access

        for (uint i = 0; i < assetIds.length; i++) {
            // Create a temporary array with just the single setId
            uint256[] memory singleSetIdArray = new uint256[](1);
            singleSetIdArray[0] = setId;
            _linkAssetToSets(assetIds[i], singleSetIdArray);
        }
    }
```
This revised `linkAssetsToConditionSet` function correctly creates a single-element array containing `setId` for each `assetId` before calling the internal `_linkAssetToSets`.

Let's continue with the rest of the contract functions, ensuring we have at least 20 public/external functions and fulfilling all requirements.

```solidity
// ... (previous code)

    /**
     * @dev Associates specific locked assets with an *additional* condition set ID.
     * This enables the "superposition" where assets can be released by multiple criteria.
     * Can only be done by Owner or Asset Controller who locked the asset (or owner if no controller specified).
     * Sets must exist, not be met/cancelled, and have a beneficiary.
     * @param assetIds IDs of the locked asset entries.
     * @param setId The ID of the condition set to link to.
     */
    function linkAssetsToConditionSet(uint256[] memory assetIds, uint256 setId) external {
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access

        for (uint i = 0; i < assetIds.length; i++) {
            // Create a temporary array with just the single setId
            uint256[] memory singleSetIdArray = new uint256[](1);
            singleSetIdArray[0] = setId;
            _linkAssetToSets(assetIds[i], singleSetIdArray);
        }
    }


     /**
     * @dev Unlinks specific locked assets from a condition set.
     * The assets remain locked but are no longer releasable by this specific set.
     * Can only be done by Owner or Asset Controller before the set is met or cancelled.
     * Note: This shifts array elements, gas intensive.
     * @param assetIds IDs of the locked asset entries.
     * @param setId The ID of the condition set to unlink from.
     */
    function unlinkAssetsFromConditionSet(uint256[] memory assetIds, uint256 setId) external {
         require(msg.sender == owner() || isAssetController[msg.sender], "Unauthorized"); // Simplified access
        require(conditionSets[setId].beneficiary != address(0), "Condition set does not exist"); // Basic check
        require(!conditionSets[setId].isMet, "Condition set already met");
        require(!conditionSets[setId].cancelled, "Condition set cancelled");

        for (uint i = 0; i < assetIds.length; i++) {
            uint256 assetId = assetIds[i];
            LockedAssetInfo storage asset = lockedAssets[assetId];
            require(!asset.released, "Asset already released");

            uint256[] storage linkedSets = asset.linkedConditionSets;
            bool found = false;
            for (uint j = 0; j < linkedSets.length; j++) {
                if (linkedSets[j] == setId) {
                    // Remove by swapping with last element and popping
                    linkedSets[j] = linkedSets[linkedSets.length - 1];
                    linkedSets.pop();
                    found = true;
                    emit AssetsUnlinked(assetId, setId);

                    // Remove from reverse mapping (_conditionSetLinkedAssets) as well
                    uint256[] storage assetsInSet = _conditionSetLinkedAssets[setId];
                     for (uint k = 0; k < assetsInSet.length; k++) {
                        if (assetsInSet[k] == assetId) {
                            assetsInSet[k] = assetsInSet[assetsInSet.length - 1];
                            assetsInSet.pop();
                            break; // Found in reverse mapping, stop inner loop
                        }
                    }
                    break; // Found in asset's linked sets, stop middle loop
                }
            }
             // Note: We don't require `found` here, allows unlinking idempotently if asset wasn't linked.
        }
    }


    // --- Condition Checking & Triggering Functions ---

    /**
     * @dev Internal helper to check if a single condition is met.
     * @param conditionId The ID of the condition to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(uint256 conditionId) internal view returns (bool) {
        Condition storage cond = conditions[conditionId];

        if (cond.conditionType == ConditionType.None) {
            return false; // Invalid condition ID
        }

        // Decode parameters based on type
        if (cond.conditionType == ConditionType.TimeLock) {
            uint256 unlockTimestamp = abi.decode(cond.params, (uint256));
            return block.timestamp >= unlockTimestamp;
        }
        else if (cond.conditionType == ConditionType.ERC20BalanceGE) {
             (address token, uint256 threshold, address accountToCheck) = abi.decode(cond.params, (address, uint256, address));
             return IERC20(token).balanceOf(accountToCheck) >= threshold;
        }
         else if (cond.conditionType == ConditionType.ERC721Owned) {
            (address token, uint256 tokenId, address accountToCheck) = abi.decode(cond.params, (address, uint256, address));
             // ownerOf will revert if token does not exist or token is burned, handle carefully or assume valid input
             try IERC721(token).ownerOf(tokenId) returns (address ownerAddress) {
                 return ownerAddress == accountToCheck;
             } catch {
                 return false; // Token not found or error checking ownership
             }
        }
         else if (cond.conditionType == ConditionType.ERC1155BalanceGE) {
             (address token, uint256 id, uint256 threshold, address accountToCheck) = abi.decode(cond.params, (address, uint256, uint256, address));
             return IERC1155(token).balanceOf(accountToCheck, id) >= threshold;
        }
         else if (cond.conditionType == ConditionType.OraclePriceGE) {
            // Simulation: Decode priceFeed address and threshold, assume priceFeed returns price / 1e8
            // In a real contract, this would call a Chainlink Price Feed or similar
             (address priceFeed, uint256 thresholdScaled) = abi.decode(cond.params, (address, uint256));
             // Dummy call: In reality, call priceFeed.latestAnswer() or similar
             // For this example, let's just assume a condition based on the price feed address itself (dummy logic)
             // REPLACE THIS DUMMY LOGIC WITH ACTUAL ORACLE CALLS IF DEPLOYING
             return uint160(priceFeed) > uint160(dummyPriceFeedAddress); // Dummy check based on addresses
        }
         else if (cond.conditionType == ConditionType.OracleApproval) {
            // Check if a Condition Oracle has manually approved this specific condition
            // If oracleAddress in params is 0x0, any oracle can approve. Otherwise, specific oracle must approve.
             (address requiredOracle) = abi.decode(cond.params, (address));
             if (requiredOracle != address(0)) {
                return _oracleConditionApproval[conditionId][requiredOracle] && _oracleConditionSet[conditionId];
             } else {
                // Check if ANY oracle has approved this condition
                // This requires iterating through all oracles or tracking approvals differently.
                // For simplicity, let's just require that *some* oracle has approved it,
                // tracked via a simple flag set by `manualOracleConditionCheck`.
                return _oracleConditionSet[conditionId] && _oracleConditionApproval[conditionId][msg.sender]; // This implies the check is done by the approving oracle
                // A better way is to store the approving oracle's address when approved. Let's stick to the simple check for now.
                 // A flag set by *any* oracle: return _oracleConditionSet[conditionId]; // This is simpler but less secure if multiple oracles
             }
        }
         else if (cond.conditionType == ConditionType.VerifiableRandomness) {
             // Check if VRF result is available and meets the criteria
             (bytes32 vrfKeyHash, uint256 modulus) = abi.decode(cond.params, (bytes32, uint256));
             // Check if randomness for this specific condition ID has been fulfilled and meets the modulus condition
             if (_vrfFulfilled[conditionId] && _vrfResult[conditionId].length > 0) {
                 // Assuming we only need one random number from the result
                 uint256 randomNumber = _vrfResult[conditionId][0];
                 return modulus == 0 || (randomNumber % modulus == 0); // If modulus is 0, any result counts as met
             }
             return false;
        }
         else if (cond.conditionType == ConditionType.ExternalContractCall) {
             // Call another contract to check a condition
             (address targetContract, bytes memory callData) = abi.decode(cond.params, (address, bytes));
             try IExternalConditionChecker(targetContract).checkCondition(callData) returns (bool result) {
                 emit ExternalConditionChecked(conditionId, result);
                 return result;
             } catch {
                 return false; // Call failed
             }
        }
         else if (cond.conditionType == ConditionType.NestedVaultState) {
             // Check the state of a condition set in another QuantumVault contract
             (address targetVault, uint256 targetConditionSetId) = abi.decode(cond.params, (address, uint256));
             try IQuantumVault(targetVault).checkConditionSetStatus(targetConditionSetId) returns (bool result) {
                  emit NestedVaultConditionChecked(conditionId, result);
                 return result;
             } catch {
                 return false; // Call failed or target vault/set doesn't exist
             }
        }

        return false; // Unknown condition type
    }


    /**
     * @dev Internal helper to check if ALL conditions in a set are met.
     * @param setId The ID of the condition set.
     * @return True if all conditions are met, false otherwise.
     */
    function _isConditionSetMet(uint256 setId) internal view returns (bool) {
        ConditionSet storage set = conditionSets[setId];
        if (set.beneficiary == address(0) || set.isMet || set.cancelled) {
            return false; // Set not valid for triggering
        }

        if (set.conditionIds.length == 0) {
            return false; // Cannot trigger if no conditions defined
        }

        for (uint i = 0; i < set.conditionIds.length; i++) {
            uint256 conditionId = set.conditionIds[i];
            if (!_checkCondition(conditionId)) {
                return false; // At least one condition is not met
            }
        }

        return true; // All conditions are met
    }

    /**
     * @dev Allows a Condition Oracle to manually approve/reject an `OracleApproval` type condition.
     * This sets the state checked by `_checkCondition`.
     * @param conditionId The ID of the `OracleApproval` condition.
     * @param approved True to approve, false to reject.
     */
    function manualOracleConditionCheck(uint256 conditionId, bool approved) external {
        require(isConditionOracle[msg.sender], "Not a Condition Oracle");
        Condition storage cond = conditions[conditionId];
        require(cond.conditionType == ConditionType.OracleApproval, "Not an Oracle Approval condition");

        // Check if a specific oracle was required
        (address requiredOracle) = abi.decode(cond.params, (address));
        if (requiredOracle != address(0)) {
            require(msg.sender == requiredOracle, "Only the designated oracle can approve this condition");
        }

        // Prevent re-setting after approval (or rejection)
        require(!_oracleConditionSet[conditionId], "Oracle approval already set for this condition");

        _oracleConditionApproval[conditionId][msg.sender] = approved;
        _oracleConditionSet[conditionId] = true; // Mark as set by *an* oracle (or the required one)

        if (approved) {
            emit OracleConditionApproved(conditionId, msg.sender);
        } else {
            emit OracleConditionRejected(conditionId, msg.sender);
        }
    }

    /**
     * @dev Initiates a request for verifiable randomness for a VRF condition.
     * Can only be called by an account (Owner/Oracle/Controller?) maybe only Owner for security.
     * Requires Chainlink VRF integration.
     * @param conditionId The ID of the VerifiableRandomness condition.
     * @param keyHash VRF key hash.
     * @param callbackGasLimit Gas limit for the fulfillment callback.
     * @param requestConfirmations Minimum block confirmations.
     * @param numWords Number of random words requested.
     * @return The requestId generated by the VRF coordinator.
     */
    function requestRandomness(uint256 conditionId, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) external onlyOwner returns (uint256) {
         // Dummy VRF Coordinator call - replace with actual Chainlink VRF logic
         // Ensure `dummyVRFCoordinator` is set to the actual VRF Coordinator address
         require(address(dummyVRFCoordinator) != address(0), "VRF Coordinator not set");
         require(conditions[conditionId].conditionType == ConditionType.VerifiableRandomness, "Not a VRF condition");
         require(!_vrfFulfilled[conditionId], "Randomness already fulfilled for this condition");

         uint256 requestId = dummyVRFCoordinator.requestRandomWords(callbackGasLimit, requestConfirmations, numWords, keyHash);
         _vrfRequestConditionId[requestId] = conditionId;
         emit VRFRandomnessRequested(conditionId, requestId);
         return requestId;
    }

     /**
     * @dev VRF callback function to receive randomness result.
     * Only callable by the VRF Coordinator.
     * Part of the Chainlink VRF Consumer pattern.
     * @param requestId The ID of the VR VRF request.
     * @param randomWords The array of random words.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        // Dummy VRF Coordinator check - replace with actual Chainlink VRF security check
        // require(msg.sender == address(dummyVRFCoordinator), "Only VRF Coordinator can call this"); // Example check
        // Chainlink VRF callback has its own security mechanism via the `rawFulfillRandomWords` override

        uint256 conditionId = _vrfRequestConditionId[requestId];
        require(conditionId != 0, "Unknown requestId"); // requestId must map to a conditionId
        require(!_vrfFulfilled[conditionId], "Randomness already fulfilled for this condition");
        require(conditions[conditionId].conditionType == ConditionType.VerifiableRandomness, "Condition is not VRF type"); // Sanity check

        _vrfResult[conditionId] = randomWords;
        _vrfFulfilled[conditionId] = true;

        emit VRFRandomnessReceived(conditionId, requestId);

        // Optionally, automatically attempt to trigger releases linked to this condition
        // after randomness is fulfilled. This could be gas intensive.
        // For now, require a separate trigger call.
    }

    /**
     * @dev Attempts to trigger the release of assets linked to a specific condition set.
     * Callable by anyone. If the condition set is met, the assets are released to the beneficiary.
     * Cleans up the state for the released assets and the condition set.
     * @param setId The ID of the condition set to check and trigger.
     */
    function triggerRelease(uint256 setId) external {
        ConditionSet storage set = conditionSets[setId];

        require(set.beneficiary != address(0), "Condition set does not exist or has no beneficiary");
        require(!set.isMet, "Condition set already met");
        require(!set.cancelled, "Condition set cancelled");

        // Check if ALL conditions in the set are met
        require(_isConditionSetMet(setId), "Conditions not met for this set");

        // Mark the set as met BEFORE transferring assets to prevent reentrancy issues
        set.isMet = true;

        uint256[] memory releasedAssetIds = new uint256[](_conditionSetLinkedAssets[setId].length);
        uint256 releasedCount = 0;

        // Iterate through assets linked to this set
        for (uint i = 0; i < _conditionSetLinkedAssets[setId].length; i++) {
            uint256 assetId = _conditionSetLinkedAssets[setId][i];
            LockedAssetInfo storage asset = lockedAssets[assetId];

            // Only release if the asset hasn't been released by another condition set yet
            if (!asset.released) {
                asset.released = true; // Mark as released immediately

                // Perform the asset transfer
                if (asset.assetType == AssetType.ETH) {
                     // Use sendValue for safety
                     payable(set.beneficiary).sendValue(asset.amountOrId);
                } else if (asset.assetType == AssetType.ERC20) {
                     IERC20(asset.tokenAddress).safeTransfer(set.beneficiary, asset.amountOrId);
                } else if (asset.assetType == AssetType.ERC721) {
                     IERC721(asset.tokenAddress).safeTransferFrom(address(this), set.beneficiary, asset.amountOrId);
                } else if (asset.assetType == AssetType.ERC1155) {
                     IERC1155(asset.tokenAddress).safeTransferFrom(address(this), set.beneficiary, address(this), asset.amountOrId, asset.erc1155Value, "");
                }
                // Note: ERC1155 safeTransferFrom from address(this) requires onERC1155Received/Batch in receiving contract if it's a contract.
                // Standard wallets don't implement this. Consider using transfer/safeTransfer if recipient is EOA.
                // For simplicity here, assuming standard wallet or compatible contract.

                releasedAssetIds[releasedCount] = assetId;
                releasedCount++;

                 // Optional: Clean up linkedConditionSets for the released asset
                 // This might be complex with multiple linked sets.
                 // For now, rely on the `released` flag.
            }
        }

        // Resize the releasedAssetIds array to the actual number released
        assembly {
             mstore(releasedAssetIds, releasedCount)
        }

        emit AssetsReleased(setId, set.beneficiary, releasedAssetIds);

        // Note: State cleanup (deleting mappings) can be added for gas efficiency
        // if assets and condition sets are no longer needed after release/cancellation.
        // For simplicity, data persists unless explicitly deleted.
    }


    // --- View Functions ---

    /**
     * @dev Checks if a specific condition set is currently met.
     * Does not trigger release.
     * @param setId The ID of the condition set.
     * @return True if all conditions in the set are met, false otherwise.
     */
    function checkConditionSetStatus(uint256 setId) public view returns (bool) {
        return _isConditionSetMet(setId);
    }

    /**
     * @dev Retrieves the details of a condition set.
     * @param setId The ID of the condition set.
     * @return beneficiary Address, conditionIds Array, isMet status, cancelled status.
     */
    function getConditionSetDetails(uint256 setId) public view returns (
        address beneficiary,
        uint256[] memory conditionIds,
        bool isMet,
        bool cancelled
    ) {
        ConditionSet storage set = conditionSets[setId];
        return (set.beneficiary, set.conditionIds, set.isMet, set.cancelled);
    }

    /**
     * @dev Retrieves the details of a specific condition.
     * @param conditionId The ID of the condition.
     * @return conditionType Type of the condition, params Abi-encoded parameters.
     */
    function getConditionDetails(uint256 conditionId) public view returns (
        ConditionType conditionType,
        bytes memory params
    ) {
        Condition storage cond = conditions[conditionId];
        return (cond.conditionType, cond.params);
    }

    /**
     * @dev Retrieves details about a specific locked asset entry.
     * @param assetId The ID of the locked asset entry.
     * @return assetType Type, tokenAddress, amountOrId, erc1155Value, linkedConditionSets, released status.
     */
    function getLockedAssetInfo(uint256 assetId) public view returns (
        AssetType assetType,
        address tokenAddress,
        uint256 amountOrId,
        uint256 erc1155Value,
        uint256[] memory linkedConditionSets,
        bool released
    ) {
        LockedAssetInfo storage asset = lockedAssets[assetId];
        return (asset.assetType, asset.tokenAddress, asset.amountOrId, asset.erc1155Value, asset.linkedConditionSets, asset.released);
    }

    /**
     * @dev Lists the IDs of locked assets currently linked to a specific condition set.
     * Note: This array is managed for linking/unlinking but released assets remain in it until cleanup.
     * Check `getLockedAssetInfo` for `released` status.
     * @param setId The ID of the condition set.
     * @return An array of locked asset IDs.
     */
    function getAssetsLinkedToConditionSet(uint256 setId) public view returns (uint256[] memory) {
        return _conditionSetLinkedAssets[setId];
    }

    /**
     * @dev Checks the status of a manual oracle approval for a specific condition.
     * @param conditionId The ID of the OracleApproval condition.
     * @param oracleAddress The address of the oracle to check.
     * @return approved True if the oracle approved it, false otherwise.
     * @return set True if the approval status has been set by *any* oracle (or the required one).
     */
    function getManualOracleApproval(uint256 conditionId, address oracleAddress) public view returns (bool approved, bool set) {
         // Note: This view function shows approval per specific oracle address.
         // The _checkCondition logic might be simpler (just checking if _oracleConditionSet[conditionId] is true if no specific oracle required).
         // This view helps inspect individual oracle actions.
        return (_oracleConditionApproval[conditionId][oracleAddress], _oracleConditionSet[conditionId]);
    }


    // --- ERC1155 Receiving Hook (for contract interactions) ---
    // If the recipient of ERC1155 is a contract, it needs to implement these hooks.
    // Our vault itself doesn't need complex receiving logic, just forwarding.
    // If the vault were to *receive* ERC1155 from another contract, it would need these.
    // Since it only receives from EOA or approved AssetControllers, standard transfer is fine.
    // Including hooks for completeness if receiving from other contracts becomes a feature.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // Fallback function to receive ETH for lockETH
    receive() external payable {}
}
```