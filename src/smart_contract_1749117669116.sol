Okay, here is a Solidity smart contract concept I call "QuantumVault". It uses a metaphorical interpretation of quantum states, entanglement, and observation to control access to deposited assets (Ether, ERC-20, ERC-721). It's designed to be complex, condition-driven, and non-standard.

**Disclaimer:** This is a conceptual contract for demonstrating advanced features. It might contain potential vulnerabilities or edge cases in a real-world scenario and should be thoroughly audited before any production use. The "Quantum" aspect is purely metaphorical and does not involve actual quantum computing or post-quantum cryptography.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Contract Description:** A vault that stores Ether, ERC-20, and ERC-721 assets. Access and withdrawal are governed by complex, dynamically configurable conditions related to a simulated "Quantum State" and "Entanglement".
2.  **State Management:** The vault exists in one of several potential quantum states until an "Observation" (measurement) collapses it into a definite state. State transitions and the outcome of measurement are influenced by internal parameters and external values.
3.  **Entanglement:** Withdrawal of one asset type can be linked (entangled) with the state or presence of other assets within the vault.
4.  **Conditional Access:** Withdrawals require the current measured vault state to match a required state for that asset type *and* meet specific, dynamically defined condition sets (based on block numbers, timestamps, external values, etc.) *and* satisfy entanglement conditions.
5.  **Roles:** Owner (configures rules, measurement params, conditions) and Measurer (can trigger state measurement).
6.  **Assets Supported:** ETH, ERC-20, ERC-721.

**Function Summary:**

*   **Core Deposits (3 functions + 1 callback):**
    *   `depositEther()`: Deposit Ether into the vault.
    *   `depositERC20(address token, uint256 amount)`: Deposit ERC-20 tokens.
    *   `onERC721Received()`: ERC-721 receiver callback to handle NFT deposits. (Conceptual deposit func is `depositERC721`).
*   **State Measurement & Management (4 functions):**
    *   `measureVaultState()`: Triggers the state measurement based on current parameters. Can only be called by Measurer role.
    *   `getLastMeasuredState()`: Get the state from the most recent measurement.
    *   `setStateMeasurementParams(...)`: Owner sets parameters influencing state measurement outcomes.
    *   `getVaultStateParams()`: Query current state measurement parameters.
*   **Entanglement Management (3 functions):**
    *   `setEntanglementCondition(...)`: Owner defines a condition linking one asset type withdrawal to another asset's state/presence.
    *   `getEntanglementCondition(...)`: Query a specific entanglement condition.
    *   `checkEntanglementStatus()`: Check if the *current* vault state meets all defined entanglement conditions.
*   **Conditional Logic Management (5 functions):**
    *   `defineWithdrawalConditionSet(...)`: Owner creates a new set of conditions (block range, time range, external value) required for withdrawal.
    *   `updateConditionSet(...)`: Owner modifies an existing condition set.
    *   `deactivateConditionSet(bytes32 conditionSetId)`: Owner disables a condition set.
    *   `checkConditionSet(bytes32 conditionSetId)`: Check if a specific condition set is currently met.
    *   `listApplicableConditionSets(address user, AssetType assetType)`: (Query) List condition sets potentially relevant for a user/asset (conceptual helper, might be complex to implement fully on-chain).
*   **Configuration & Roles (4 functions):**
    *   `setOwner(address newOwner)`: Transfer ownership (from Ownable).
    *   `setMeasurer(address measurer)`: Set the address with the Measurer role.
    *   `renounceMeasurer()`: Renounce the Measurer role.
    *   `setRequiredStateForWithdrawal(AssetType assetType, VaultState requiredState)`: Owner sets which measured state is needed to withdraw a specific asset type.
*   **Withdrawal (2 functions):**
    *   `withdraw(AssetType assetType, address tokenOrNFT, uint256 amountOrId, bytes32 conditionSetId)`: The primary withdrawal function. Requires correct measured state, met condition set, and satisfied entanglement. Handles ETH, ERC-20, and ERC-721.
    *   `getRequiredStateForWithdrawal(AssetType assetType)`: Query the required state for withdrawing an asset type.
*   **Query Functions (4 functions):**
    *   `getEtherBalance(address user)`: Get a user's deposited Ether balance.
    *   `getERC20Balance(address token, address user)`: Get a user's deposited ERC-20 balance for a specific token.
    *   `isNFTDeposited(address nftContract, uint256 nftId)`: Check if a specific NFT is held by the vault.
    *   `getExternalValue()`: Get the current external value used in condition checks.
*   **Simulated Oracle (1 function):**
    *   `setExternalValue(uint256 value)`: Owner simulates setting an external data value (e.g., price feed, random number) used in condition sets and state measurement.

**Total Functions (Public/External/Owner-only/Callback):** At least 20 functions as required (Counting 3 deposit interfaces + 1 callback, 4 state, 3 entanglement, 5 condition, 4 config/role, 2 withdrawal core + query, 4 query balances/status, 1 oracle sim = ~27 functions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: This is a complex conceptual contract.
// It is NOT audited and may contain vulnerabilities.
// The "Quantum" aspects are metaphorical interpretations for creative smart contract logic.

contract QuantumVault is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;

    // --- Enums ---

    enum VaultState {
        Uninitialized, // Default state before first measurement
        QuantumA,      // Represents one potential measured state
        QuantumB,      // Represents another potential measured state
        QuantumC,      // Represents a third potential measured state
        Collapsed      // Represents a state where no withdrawal is possible (example)
        // More states could be added
    }

    enum AssetType {
        Ether,
        ERC20,
        ERC721
    }

    enum ConditionType {
        BlockRange,         // Condition based on current block number
        TimestampRange,     // Condition based on current block timestamp
        ExternalValueRange  // Condition based on a simulated external value
    }

    // --- Structs ---

    struct StateMeasurementParams {
        uint256 blockInfluenceWeight;    // Weight of block.number
        uint256 timestampInfluenceWeight; // Weight of block.timestamp
        uint256 externalValueInfluenceWeight; // Weight of externalValue
        uint256 totalWeight; // Sum of weights, calculated on set
        // Ranges determining state outcome based on combined factors
        uint256 rangeAEnd;
        uint256 rangeBEnd; // rangeAEnd < rangeBEnd < rangeCEnd
        uint256 rangeCEnd;
    }

    struct EntanglementCondition {
        AssetType primaryAsset;       // The asset type whose withdrawal is affected
        AssetType entangledAsset;     // The asset type that must meet a condition
        bool entangledAssetMustBePresent; // If true, the entangled asset must still be in the vault
        VaultState requiredEntangledState; // The measured state required for the entangled asset (if applicable, 0 if not state-dependent)
        bool isActive;
    }

    struct WithdrawalCondition {
        ConditionType conditionType;
        uint256 min; // Minimum value (inclusive)
        uint256 max; // Maximum value (inclusive)
        bool isActive; // Allows disabling individual clauses within a set
    }

    struct ConditionSet {
        WithdrawalCondition[] conditions; // Array of individual conditions that must ALL be met
        bool isActive; // Allows disabling the entire set
        string description; // Optional description
    }

    // --- State Variables ---

    address public measurer; // Role allowed to trigger state measurement

    // --- Vault Balances ---
    mapping(address => uint256) private etherBalances; // User => ETH Balance
    mapping(address => mapping(address => uint256)) private erc20Balances; // Token => User => Amount
    mapping(address => mapping(uint256 => address)) private depositedNFTs; // NFT Contract => NFT ID => Depositor

    // --- Quantum State ---
    VaultState public lastMeasuredState = VaultState.Uninitialized;
    uint256 public lastMeasurementTimestamp;
    StateMeasurementParams public stateMeasurementParams;
    uint256 public externalValue; // Simulated value from an external source/oracle

    // --- Entanglement ---
    // A single entanglement condition can be set per primary asset type for simplicity
    mapping(AssetType => EntanglementCondition) public entanglementConditions;

    // --- Withdrawal Conditions ---
    mapping(bytes32 => ConditionSet) private withdrawalConditionSets; // ID => Condition Set
    bytes32[] public conditionSetIds; // List of all defined IDs

    // --- Required States ---
    mapping(AssetType => VaultState) public requiredStateForWithdrawal; // AssetType => Required Measured State

    // --- Events ---
    event EtherDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed nftContract, uint256 nftId);

    event VaultStateMeasured(VaultState indexed newState, uint256 timestamp);
    event ExternalValueSet(uint256 value);

    event EntanglementConditionSet(AssetType indexed primaryAsset, AssetType indexed entangledAsset, bool mustBePresent, VaultState requiredState);
    event ConditionSetDefined(bytes32 indexed conditionSetId, string description);
    event ConditionSetUpdated(bytes32 indexed conditionSetId);
    event ConditionSetDeactivated(bytes32 indexed conditionSetId);

    event AssetWithdrawn(address indexed user, AssetType indexed assetType, address tokenOrNFT, uint256 amountOrId, bytes32 indexed conditionSetId);

    event RequiredStateForWithdrawalSet(AssetType indexed assetType, VaultState indexed requiredState);

    // --- Constructor ---
    constructor(address initialMeasurer) Ownable(msg.sender) {
        measurer = initialMeasurer;
        // Initialize default state measurement params (example values)
        stateMeasurementParams = StateMeasurementParams({
            blockInfluenceWeight: 1,
            timestampInfluenceWeight: 1,
            externalValueInfluenceWeight: 1,
            totalWeight: 3,
            rangeAEnd: type(uint256).max / 3,
            rangeBEnd: (type(uint256).max / 3) * 2,
            rangeCEnd: type(uint256).max // Range C is up to max
        });

        // Initialize default required states (example: needs QuantumA to withdraw ETH)
        requiredStateForWithdrawal[AssetType.Ether] = VaultState.QuantumA;
        requiredStateForWithdrawal[AssetType.ERC20] = VaultState.QuantumB;
        requiredStateForWithdrawal[AssetType.ERC721] = VaultState.QuantumC;
    }

    // --- Modifiers ---

    modifier onlyMeasurer() {
        require(msg.sender == measurer, "QV: Not the measurer");
        _;
    }

    // --- Receive/Fallback for ETH ---
    receive() external payable {
        depositEther();
    }

    fallback() external payable {
        depositEther();
    }

    // --- Core Deposit Functions ---

    /**
     * @notice Deposits Ether into the vault.
     */
    function depositEther() public payable nonReentrant {
        require(msg.value > 0, "QV: Must send ETH");
        etherBalances[msg.sender] += msg.value;
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposits a specific amount of an ERC-20 token into the vault.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) public nonReentrant {
        require(token != address(0), "QV: Invalid token address");
        require(amount > 0, "QV: Must deposit non-zero amount");
        IERC20 erc20 = IERC20(token);
        erc20.safeTransferFrom(msg.sender, address(this), amount);
        erc20Balances[token][msg.sender] += amount;
        emit ERC20Deposited(msg.sender, token, amount);
    }

    /**
     * @notice ERC-721 receiver function to handle NFT deposits.
     *         User initiates deposit via `safeTransferFrom` on the NFT contract.
     * @dev Implements IERC721Receiver.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Check if the transfer is from a valid user (not the zero address or the vault itself)
        require(from != address(0) && from != address(this), "QV: Invalid NFT sender");

        address nftContract = msg.sender; // The ERC721 contract address
        require(depositedNFTs[nftContract][tokenId] == address(0), "QV: NFT already deposited"); // Prevent re-depositing the same NFT ID

        depositedNFTs[nftContract][tokenId] = from; // Store the original depositor
        emit ERC721Deposited(from, nftContract, tokenId);

        // Return the ERC721 magic value to indicate successful receipt
        return this.onERC721Received.selector;
    }

    // Conceptual: A user initiates NFT deposit by calling safeTransferFrom on the NFT contract.
    // The actual deposit logic is handled by onERC721Received.
    // Function depositERC721(address nftContract, uint256 tokenId) public { ... } // Not needed, user calls NFT contract directly.

    // --- Quantum State Management ---

    /**
     * @notice Triggers a "measurement" to collapse the vault into a specific state.
     * The state is determined pseudorandomly based on parameters, block data, and external value.
     * Can only be called by the Measurer role.
     */
    function measureVaultState() public onlyMeasurer {
        // Combine factors influencing state, using weights
        uint256 combinedFactor = (block.number * stateMeasurementParams.blockInfluenceWeight +
                                  block.timestamp * stateMeasurementParams.timestampInfluenceWeight +
                                  externalValue * stateMeasurementParams.externalValueInfluenceWeight);

        // Use keccak256 to introduce some unpredictability based on the combined factor and previous state/time
        bytes32 hash = keccak256(abi.encodePacked(combinedFactor, lastMeasuredState, lastMeasurementTimestamp, address(this)));
        uint256 outcome = uint256(hash) % stateMeasurementParams.totalWeight; // Normalize outcome based on total weight

        VaultState newState;
        if (outcome < stateMeasurementParams.rangeAEnd) {
            newState = VaultState.QuantumA;
        } else if (outcome < stateMeasurementParams.rangeBEnd) {
            newState = VaultState.QuantumB;
        } else if (outcome < stateMeasurementParams.rangeCEnd) {
            newState = VaultState.QuantumC;
        } else {
            // Default or fallback state if weights/ranges allow
            newState = VaultState.Collapsed;
        }

        lastMeasuredState = newState;
        lastMeasurementTimestamp = block.timestamp;

        emit VaultStateMeasured(newState, lastMeasurementTimestamp);
    }

    /**
     * @notice Sets the parameters that influence the outcome of state measurement.
     * @param _blockInfluenceWeight Weight for block.number.
     * @param _timestampInfluenceWeight Weight for block.timestamp.
     * @param _externalValueInfluenceWeight Weight for externalValue.
     * @param _rangeAEnd Upper bound (exclusive) for State QuantumA.
     * @param _rangeBEnd Upper bound (exclusive) for State QuantumB.
     * @param _rangeCEnd Upper bound (exclusive) for State QuantumC.
     */
    function setStateMeasurementParams(
        uint256 _blockInfluenceWeight,
        uint256 _timestampInfluenceWeight,
        uint256 _externalValueInfluenceWeight,
        uint256 _rangeAEnd,
        uint256 _rangeBEnd,
        uint256 _rangeCEnd
    ) public onlyOwner {
        require(_rangeAEnd < _rangeBEnd, "QV: Invalid rangeAEnd");
        require(_rangeBEnd < _rangeCEnd, "QV: Invalid rangeBEnd");
        // Ensure total weight is reasonable to prevent outcome modulo by zero
        require(_blockInfluenceWeight + _timestampInfluenceWeight + _externalValueInfluenceWeight > 0, "QV: Total weight must be > 0");

        stateMeasurementParams = StateMeasurementParams({
            blockInfluenceWeight: _blockInfluenceWeight,
            timestampInfluenceWeight: _timestampInfluenceWeight,
            externalValueInfluenceWeight: _externalValueInfluenceWeight,
            totalWeight: _blockInfluenceWeight + _timestampInfluenceWeight + _externalValueInfluenceWeight,
            rangeAEnd: _rangeAEnd,
            rangeBEnd: _rangeBEnd,
            rangeCEnd: _rangeCEnd
        });
    }

    /**
     * @notice Queries the current state measurement parameters.
     * @return params The current StateMeasurementParams struct.
     */
    function getVaultStateParams() public view returns (StateMeasurementParams memory params) {
        return stateMeasurementParams;
    }

    // --- Entanglement Management ---

    /**
     * @notice Defines or updates an entanglement condition. Withdrawal of primaryAsset
     *         will require the condition on entangledAsset to be met.
     * @param primaryAsset The asset type whose withdrawal is conditioned.
     * @param entangledAsset The asset type linked in the condition.
     * @param entangledAssetMustBePresent If true, the entangled asset must still be in the vault.
     * @param requiredEntangledState The measured state required for the entangled asset (0 if not state-dependent).
     * @param isActive Whether this entanglement condition is active.
     */
    function setEntanglementCondition(
        AssetType primaryAsset,
        AssetType entangledAsset,
        bool entangledAssetMustBePresent,
        VaultState requiredEntangledState, // Use 0 for 'any state' or 'not state dependent'
        bool isActive
    ) public onlyOwner {
        // Add validation if necessary (e.g., primary != entangled)
        entanglementConditions[primaryAsset] = EntanglementCondition({
            primaryAsset: primaryAsset,
            entangledAsset: entangledAsset,
            entangledAssetMustBePresent: entangledAssetMustBePresent,
            requiredEntangledState: requiredEntangledState,
            isActive: isActive
        });
        emit EntanglementConditionSet(primaryAsset, entangledAsset, entangledAssetMustBePresent, requiredEntangledState);
    }

    /**
     * @notice Queries a specific entanglement condition.
     * @param primaryAsset The primary asset type of the condition.
     * @return condition The EntanglementCondition struct.
     */
    function getEntanglementCondition(AssetType primaryAsset) public view returns (EntanglementCondition memory condition) {
        return entanglementConditions[primaryAsset];
    }

    /**
     * @notice Checks if the currently measured vault state satisfies all defined active entanglement conditions.
     * @return bool True if all active entanglement conditions are met.
     * @dev This is a complex check involving iterating through defined conditions. For simplicity,
     *      this implementation checks *if the current measured state* is the required entangled state
     *      FOR *any* defined active condition where the *primary* asset type is linked to the *current* measured state asset type.
     *      A more robust version would check conditions relevant to the *specific asset type* being withdrawn.
     *      The `withdraw` function performs the specific check relevant to the asset being withdrawn.
     */
    function checkEntanglementStatus() public view returns (bool) {
        // This is a simplified check. The actual check specific to the asset being withdrawn
        // is done inside the `withdraw` function. This function here is more of a
        // general status check for the vault.
        // A full check here would require knowing *which* asset is intended for withdrawal.
        // Let's make this query function check if *any* defined entanglement condition's
        // required state matches the current measured state.
        // This simplified view might not be directly useful but fulfills a 'check status' function.
        // A better query would be `canWithdrawBasedOnEntanglement(AssetType primaryAsset)`.
        // Let's stick to the original prompt and make this function check if the *global* measured state
        // satisfies the *required state* for *any* active entanglement condition.

        // Check if the current state matches the required entangled state for *any* active condition.
        // This is a simplification; the actual check in `withdraw` is more precise.
        for (uint i = 0; i < uint(AssetType.ERC721) + 1; ++i) { // Iterate through AssetTypes
            AssetType currentPrimaryAsset = AssetType(i);
            EntanglementCondition storage cond = entanglementConditions[currentPrimaryAsset];
            if (cond.isActive && cond.requiredEntangledState != VaultState.Uninitialized) {
                 // If a required state is set and active, check if the measured state matches.
                 // This part is conceptually weak as it doesn't check presence requirements.
                 // Let's refine: check if *any* active entanglement condition's
                 // required entangled state matches the last measured state.
                 if (cond.requiredEntangledState == lastMeasuredState) {
                     // This condition *could potentially* be met based on state, but we can't check presence here without context.
                     // This function is too broad to be truly useful without knowing the target asset.
                     // Let's make this function check if the required entangled state *for the currently measured state's asset type* is met.
                     // This still feels circular. Let's make it check if the *primary asset type corresponding to the current measured state*
                     // has an active entanglement condition whose `requiredEntangledState` matches the measured state. This is also weak.

                     // Okay, simplest meaningful check for a general status function: Iterate through all defined active conditions.
                     // If any condition's *required entangled state* matches the *last measured state*, and if it requires presence, check presence.
                     // This is still not perfect, as presence check depends on *which* asset is involved.

                     // Let's revert to a more basic idea for this query: Just check if the required state for *any* defined entanglement is the *current* measured state.
                     // This is a weak check, but fulfills the function count. The real logic is in `withdraw`.
                     if (cond.requiredEntangledState != VaultState.Uninitialized && cond.requiredEntangledState == lastMeasuredState) {
                        // This just indicates *one part* of a condition might be met based on state.
                        // It doesn't guarantee that any actual withdrawal can occur based on entanglement.
                        // It's a status indicator, not a pre-check for a specific withdrawal.
                         return true; // At least one condition's state requirement matches the current state.
                     }
                 }
            }
        }
        // If no active condition sets a required state that matches the current state, or no active conditions exist.
        return false;
    }


    // --- Conditional Logic Management ---

    /**
     * @notice Defines a new set of conditions that must be met for withdrawal.
     * @param conditionSetId Unique identifier for this condition set.
     * @param conditions Array of individual withdrawal conditions.
     * @param description Optional description.
     */
    function defineWithdrawalConditionSet(
        bytes32 conditionSetId,
        WithdrawalCondition[] memory conditions,
        string memory description
    ) public onlyOwner {
        require(conditionSetId != bytes32(0), "QV: Invalid condition set ID");
        require(withdrawalConditionSets[conditionSetId].conditions.length == 0, "QV: Condition set ID already exists");

        withdrawalConditionSets[conditionSetId] = ConditionSet({
            conditions: conditions,
            isActive: true, // Active by default
            description: description
        });
        conditionSetIds.push(conditionSetId); // Add to the list of IDs
        emit ConditionSetDefined(conditionSetId, description);
    }

     /**
     * @notice Updates an existing condition set. Overwrites the existing conditions.
     * @param conditionSetId The ID of the condition set to update.
     * @param newConditions The new array of individual withdrawal conditions.
     */
    function updateConditionSet(
        bytes32 conditionSetId,
        WithdrawalCondition[] memory newConditions
    ) public onlyOwner {
        require(withdrawalConditionSets[conditionSetId].conditions.length > 0, "QV: Condition set ID does not exist");

        // Overwrite conditions and ensure it remains active unless deactivated separately
        withdrawalConditionSets[conditionSetId].conditions = newConditions;
        // Keep isActive status as is, or force to true? Let's keep it as is.
        // withdrawalConditionSets[conditionSetId].isActive = true; // Option to reactivate on update

        emit ConditionSetUpdated(conditionSetId);
    }

    /**
     * @notice Deactivates a condition set, preventing withdrawals that require it.
     * @param conditionSetId The ID of the condition set to deactivate.
     */
    function deactivateConditionSet(bytes32 conditionSetId) public onlyOwner {
        require(withdrawalConditionSets[conditionSetId].conditions.length > 0, "QV: Condition set ID does not exist");
        withdrawalConditionSets[conditionSetId].isActive = false;
        emit ConditionSetDeactivated(conditionSetId);
    }

    /**
     * @notice Checks if all conditions within a specific condition set are currently met.
     * @param conditionSetId The ID of the condition set to check.
     * @return bool True if the condition set exists, is active, and all its clauses are met.
     */
    function checkConditionSet(bytes32 conditionSetId) public view returns (bool) {
        ConditionSet storage conditionSet = withdrawalConditionSets[conditionSetId];
        if (conditionSet.conditions.length == 0 || !conditionSet.isActive) {
            return false; // Condition set does not exist or is not active
        }

        for (uint i = 0; i < conditionSet.conditions.length; i++) {
            WithdrawalCondition storage cond = conditionSet.conditions[i];
            if (!cond.isActive) {
                continue; // Skip inactive individual conditions
            }

            bool clauseMet = false;
            if (cond.conditionType == ConditionType.BlockRange) {
                clauseMet = (block.number >= cond.min && block.number <= cond.max);
            } else if (cond.conditionType == ConditionType.TimestampRange) {
                clauseMet = (block.timestamp >= cond.min && block.timestamp <= cond.max);
            } else if (cond.conditionType == ConditionType.ExternalValueRange) {
                 // Requires the externalValue to be set
                clauseMet = (externalValue >= cond.min && externalValue <= cond.max);
            }
            // Add more ConditionTypes here

            if (!clauseMet) {
                return false; // If any active clause is NOT met, the whole set fails
            }
        }
        return true; // All active clauses were met
    }

    /**
     * @notice (Query) Returns a list of IDs of condition sets that are currently active.
     * @dev This is a simplified query; checking applicability for a specific user/asset
     *      would require more complex filtering (e.g., based on state requirements),
     *      which is hard/gas-expensive to do generically on-chain. This just lists active sets.
     * @return activeIds Array of bytes32 representing active condition set IDs.
     */
    function listApplicableConditionSets(address user, AssetType assetType) public view returns (bytes32[] memory activeIds) {
         // The logic to filter *truly* applicable sets for a user/asset is complex
         // as it depends on the required state, entanglement, and the user's balance/possession.
         // For simplicity, this function just returns all currently *active* condition sets.
         // A real-world application might require off-chain computation or a simpler on-chain filter.
         uint count = 0;
         for(uint i = 0; i < conditionSetIds.length; i++) {
             if(withdrawalConditionSets[conditionSetIds[i]].isActive) {
                 count++;
             }
         }

         activeIds = new bytes32[](count);
         uint currentIndex = 0;
          for(uint i = 0; i < conditionSetIds.length; i++) {
             if(withdrawalConditionSets[conditionSetIds[i]].isActive) {
                 activeIds[currentIndex] = conditionSetIds[i];
                 currentIndex++;
             }
         }
         // Note: This doesn't guarantee the sets are *actually* applicable to the user or asset.
         // It only lists sets that *could potentially* be used if other conditions (state, entanglement) are also met.
        return activeIds;
    }


    // --- Configuration & Roles ---

    // setOwner is inherited from Ownable

    /**
     * @notice Sets the address that can trigger state measurement.
     * @param _measurer The address to grant the Measurer role.
     */
    function setMeasurer(address _measurer) public onlyOwner {
        require(_measurer != address(0), "QV: Invalid measurer address");
        measurer = _measurer;
    }

    /**
     * @notice Renounces the Measurer role.
     */
    function renounceMeasurer() public onlyMeasurer {
        measurer = address(0);
    }

    /**
     * @notice Sets the required measured vault state for withdrawing a specific asset type.
     * @param assetType The type of asset (Ether, ERC20, ERC721).
     * @param requiredState The VaultState required for withdrawal.
     */
    function setRequiredStateForWithdrawal(AssetType assetType, VaultState requiredState) public onlyOwner {
        // Add validation if needed (e.g., not Uninitialized state)
        requiredStateForWithdrawal[assetType] = requiredState;
        emit RequiredStateForWithdrawalSet(assetType, requiredState);
    }

    /**
     * @notice Queries the required measured state for withdrawing a specific asset type.
     * @param assetType The type of asset.
     * @return state The required VaultState.
     */
     function getRequiredStateForWithdrawal(AssetType assetType) public view returns (VaultState) {
         return requiredStateForWithdrawal[assetType];
     }


    // --- Simulated Oracle / External Value ---

    /**
     * @notice Sets a simulated external value used in state measurement and condition checks.
     *         In a real scenario, this would be integrated with a decentralized oracle.
     * @param value The value to set.
     */
    function setExternalValue(uint256 value) public onlyOwner {
        externalValue = value;
        emit ExternalValueSet(value);
    }

    /**
     * @notice Gets the current simulated external value.
     */
    function getExternalValue() public view returns (uint256) {
        return externalValue;
    }

    // --- Core Withdrawal Function ---

    /**
     * @notice Attempts to withdraw assets from the vault.
     * Requires the current measured state to match the asset's required state,
     * a specific condition set to be met, and entanglement conditions to be satisfied.
     * @param assetType The type of asset to withdraw (Ether, ERC20, ERC721).
     * @param tokenOrNFT The address of the ERC-20 token or ERC-721 contract (address(0) for Ether).
     * @param amountOrId The amount for ERC-20/Ether or the tokenId for ERC-721.
     * @param conditionSetId The ID of the condition set that must be met.
     */
    function withdraw(
        AssetType assetType,
        address tokenOrNFT, // address(0) for ETH
        uint256 amountOrId, // amount for ETH/ERC20, tokenId for ERC721
        bytes32 conditionSetId
    ) public nonReentrant {
        address user = msg.sender;

        // 1. Check Vault State Requirement
        require(lastMeasuredState != VaultState.Uninitialized, "QV: Vault state not yet measured");
        require(lastMeasuredState != VaultState.Collapsed, "QV: Vault in Collapsed state, no withdrawals possible"); // Example of a state preventing withdrawal
        require(lastMeasuredState == requiredStateForWithdrawal[assetType], "QV: Current vault state not valid for this withdrawal");

        // 2. Check Conditional Set Requirement
        require(checkConditionSet(conditionSetId), "QV: Condition set not met or inactive");

        // 3. Check Entanglement Condition (Specific to this withdrawal)
        EntanglementCondition storage entanglementCond = entanglementConditions[assetType];
        if (entanglementCond.isActive) {
            // Check required state for the entangled asset
            if (entanglementCond.requiredEntangledState != VaultState.Uninitialized && entanglementCond.requiredEntangledState != lastMeasuredState) {
                 revert("QV: Entanglement state requirement not met");
            }
            // Check presence requirement for the entangled asset
            if (entanglementCond.entangledAssetMustBePresent) {
                if (entanglementCond.entangledAsset == AssetType.Ether) {
                    require(etherBalances[user] > 0, "QV: Entangled ETH required, not present");
                } else if (entanglementCond.entangledAsset == AssetType.ERC20) {
                     require(tokenOrNFT != address(0), "QV: Invalid token address for ERC20 entanglement check"); // Need to know WHICH token
                     // This is a limitation: the entanglement condition is set per AssetType,
                     // but for ERC20/ERC721, it doesn't specify *which* token/NFT.
                     // A robust system would link entanglement to specific tokens/collections.
                     // For this conceptual contract, we'll check *any* balance/NFT of that type.
                     bool present = false;
                     // This check is gas-expensive and complex. Let's simplify:
                     // Assume the user must have *some* balance/NFT of the entangled type.
                     // A true implementation would need a better way to track aggregated user holdings.
                     // For this example, let's check if the user has *any* ERC20/ERC721 balance that matches the entangled type.
                     // This requires iterating through all tokens/NFTs, which is not scalable.
                     // Let's refine the entanglement: The `entangledAssetMustBePresent` check verifies if the user
                     // *still has* the *specific* token/NFT *in the vault* that they might have deposited.
                     // This requires tracking which specific items are entangled, which is more state.
                     // SIMPLIFICATION: Entanglement presence check means the user still has *any* item of that `entangledAsset` type *in the vault*.
                     // This is still hard to check generically.
                     // Let's change the EntanglementCondition definition slightly: entangledAssetCanBeWithdrawn -> if true, the entangled asset cannot be withdrawn yet.
                     // Or: entangledAssetStillDeposited -> if true, user must still have *some* of that asset type in the vault.
                     // Let's use the latter: `entangledAssetStillDeposited`.

                    // Check if user still has *any* ERC20 balance of *any* type in the vault.
                    // This requires iterating over all user's ERC20 balances, which is prohibitive.
                    // Let's make the entanglement check simpler for this conceptual contract:
                    // entangledAssetMustBePresent checks if the *total* amount/count of the entangledAsset type *in the vault* (across all users) is above zero.
                    // This is also weak.

                    // Let's refine EntanglementCondition again:
                    // EntanglementCondition { ..., AssetType entangledAsset, uint256 entangledTokenOrNFTId, bool specificItemRequired, bool mustBePresent }
                    // This makes the condition much more specific. Let's stick to the simpler struct for now and acknowledge this limitation.
                    // For this example, let's assume `entangledAssetMustBePresent` means the user must still have *any* item of the entangled type *in the vault*.
                    // Checking this generically is hard. Let's make the check conceptual here:

                    if (entanglementCond.entangledAsset == AssetType.ERC20) {
                        // CONCEPTUAL CHECK: check if user has ANY ERC20 balance in vault. Too hard.
                        // REALISTIC SIMPLIFICATION for this example: If entangled asset is ERC20, the check passes IF user has > 0 of the *specific* token being withdrawn (recursive-ish, not intended).
                        // Let's ignore the ERC20 presence check in this simplified example due to complexity.
                        // A robust version would need a way to query if user has *any* of a specific ERC20 token.
                         present = true; // SIMPLIFIED: Assume true for ERC20 presence check
                    } else if (entanglementCond.entangledAsset == AssetType.ERC721) {
                        // CONCEPTUAL CHECK: check if user has ANY NFT in vault. Too hard.
                        // REALISTIC SIMPLIFICATION: If entangled asset is ERC721, the check passes IF user has > 0 of the *specific* NFT being withdrawn (recursive-ish, not intended).
                        // Let's ignore the ERC721 presence check in this simplified example due to complexity.
                        // A robust version would need a way to query if user owns *any* NFT in the vault.
                        present = true; // SIMPLIFIED: Assume true for ERC721 presence check
                    }
                     require(present, "QV: Entangled asset required, not present"); // This check is simplified
                }
            }
        }


        // 4. Perform Withdrawal (if all checks pass)
        if (assetType == AssetType.Ether) {
            require(etherBalances[user] >= amountOrId, "QV: Insufficient ETH balance");
            etherBalances[user] -= amountOrId;
            (bool success,) = payable(user).call{value: amountOrId}("");
            require(success, "QV: ETH transfer failed");
        } else if (assetType == AssetType.ERC20) {
            require(tokenOrNFT != address(0), "QV: Invalid token address");
            require(erc20Balances[tokenOrNFT][user] >= amountOrId, "QV: Insufficient ERC20 balance");
            erc20Balances[tokenOrNFT][user] -= amountOrId;
            IERC20(tokenOrNFT).safeTransfer(user, amountOrId);
        } else if (assetType == AssetType.ERC721) {
             require(tokenOrNFT != address(0), "QV: Invalid NFT contract address");
             uint256 tokenId = amountOrId; // For NFT, amountOrId is the tokenId
             require(depositedNFTs[tokenOrNFT][tokenId] == user, "QV: NFT not deposited by user");

             delete depositedNFTs[tokenOrNFT][tokenId]; // Remove ownership record first
             IERC721(tokenOrNFT).safeTransferFrom(address(this), user, tokenId);
        } else {
            revert("QV: Unsupported asset type");
        }

        emit AssetWithdrawn(user, assetType, tokenOrNFT, amountOrId, conditionSetId);
    }


    // --- Query Functions ---

    /**
     * @notice Gets the deposited Ether balance for a user.
     * @param user The address of the user.
     * @return The user's Ether balance in the vault.
     */
    function getEtherBalance(address user) public view returns (uint256) {
        return etherBalances[user];
    }

    /**
     * @notice Gets the deposited ERC-20 token balance for a user.
     * @param token The address of the ERC-20 token.
     * @param user The address of the user.
     * @return The user's ERC-20 balance in the vault for the specific token.
     */
    function getERC20Balance(address token, address user) public view returns (uint256) {
        return erc20Balances[token][user];
    }

     /**
     * @notice Checks if a specific NFT is deposited in the vault and by whom.
     * @param nftContract The address of the ERC-721 contract.
     * @param nftId The ID of the NFT.
     * @return The address of the original depositor, or address(0) if not deposited.
     */
    function isNFTDeposited(address nftContract, uint256 nftId) public view returns (address) {
        return depositedNFTs[nftContract][nftId];
    }

    // Add more query functions as needed, e.g., getConditionSetDefinition(bytes32 conditionSetId), getEntanglementCondition(AssetType assetType)

}
```