Okay, here is a smart contract concept focused on a "Quantum-Inspired Probabilistic Vault". It combines ideas of timed/conditional access, probabilistic outcomes, and state management inspired (loosely!) by quantum states collapsing upon observation. This is not a literal quantum simulation (which is impossible on EVM), but uses the concepts for creative access control.

It aims to be advanced by:
1.  **Complex State Management:** Assets can be in various states beyond simple locked/unlocked.
2.  **Conditional Logic:** Access depends on multiple, potentially external, conditions.
3.  **Probabilistic Outcomes:** Access attempts don't guarantee success; they trigger a resolution process based on calculated probabilities and external randomness/data.
4.  **Roles & Permissions:** Differentiated roles for owner, depositors, observers (who trigger state collapse), and authorized resolvers (who report condition outcomes).
5.  **Multi-Asset Support:** Designed to handle ETH, ERC20, ERC721, and ERC1155.
6.  **Dynamic Parameters:** Probabilities and fees can potentially be influenced by conditions or governance.

**Disclaimer:** This is a complex, experimental concept. It is provided for educational and creative purposes. Deploying such a contract requires significant security audits, robust oracle infrastructure (for external conditions), and careful consideration of economic incentives for observers/resolvers. The "quantum-inspired" aspect is a metaphor for probabilistic state transitions triggered by external events ("observation").

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/SafeERC1155.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For uint -> uint multiplication if needed, or use 0.8.x built-ins
import "@openzeppelin/contracts/utils/Counters.sol"; // For condition IDs

// --- Outline ---
// 1. Contract Definition: Inherits Ownable, defines state variables, enums, structs.
// 2. Enums: Define possible states of assets and types of assets/conditions.
// 3. Structs: Define data structures for Conditions and Asset Information.
// 4. State Variables: Storage for assets, conditions, roles, configurations.
// 5. Events: Log key actions and state changes.
// 6. Modifiers: Define custom access control logic.
// 7. Constructor: Initialize contract owner and key parameters.
// 8. Core Logic (Probabilistic Access):
//    - deposit*: Functions to deposit various asset types.
//    - defineCondition: Create or update a condition struct.
//    - removeCondition: Deactivate a condition.
//    - linkConditionToAsset: Associate conditions with a specific asset or the vault.
//    - unlinkConditionFromAsset: Remove condition association.
//    - setAssetBaseProbability: Set the inherent probability for an asset's access.
//    - attemptWithdrawal: The "observation" - triggers the state change from PROBABILISTIC_ACCESS.
//    - resolveState: Called by authorized parties (Oracle/Resolvers) to report condition outcomes and resolve the probabilistic state.
//    - withdrawResolvedAsset: Allows withdrawal if state was resolved successfully.
// 9. Configuration & Management:
//    - setOracleAddress: Set the trusted oracle address.
//    - addResolver/removeResolver: Manage addresses authorized to call resolveState.
//    - stakeObserver/unstakeObserver: Manage stakes for observers (potential feature).
//    - updateConfig: Generic function for updating various parameters (fees, cooldowns).
//    - emergencyClassicWithdraw: Owner override for asset retrieval.
// 10. View Functions: Read state information without changing it.
//    - getAssetDetails
//    - getConditionDetails
//    - getAssetProbability
//    - getVaultState
//    - getObserverStake

// --- Function Summary ---
// (Functions are listed roughly in implementation order, not necessarily the outline order)

// State Management & Configuration
// constructor(address initialOracle): Initializes contract with owner and oracle address.
// setOracleAddress(address newOracle): Sets the trusted address for oracle callbacks (Owner only).
// addResolver(address resolver): Grants permission to an address to call resolveState (Owner only).
// removeResolver(address resolver): Revokes resolver permission (Owner only).
// updateConfig(uint256 newWithdrawalFeeRate, uint256 newAttemptCooldown): Updates contract parameters (Owner only).
// emergencyClassicWithdraw(bytes32 assetId): Allows owner to withdraw a specific asset bypassing conditions (Owner only).
// setVaultState(VaultState newState): Allows owner to explicitly set the global vault state (Owner only).

// Deposit Functions
// depositETH(): Deposit Ether into the vault, receiving an assetId.
// depositERC20(IERC20 token, uint256 amount): Deposit ERC20 tokens into the vault, receiving an assetId.
// depositERC721(IERC721 token, uint256 tokenId): Deposit an ERC721 token into the vault, receiving an assetId.
// depositERC1155(IERC1155 token, uint256 tokenId, uint256 amount): Deposit ERC1155 tokens into the vault, receiving an assetId.

// Condition Management
// defineCondition(bytes32 conditionId, ConditionType conditionType, bytes calldata parameters, uint256 associatedProbabilityWeight): Defines or updates a condition with specific parameters and probability impact (Owner only).
// removeCondition(bytes32 conditionId): Marks a condition as inactive (Owner only).
// linkConditionToAsset(bytes32 assetId, bytes32 conditionId): Links a defined condition to a specific asset (Owner only).
// unlinkConditionFromAsset(bytes32 assetId, bytes32 conditionId): Removes a link between a condition and an asset (Owner only).
// setAssetBaseProbability(bytes32 assetId, uint256 baseProbability): Sets the starting access probability for an asset (Owner only).

// Core Probabilistic Access Functions
// attemptWithdrawal(bytes32 assetId): The "observation" function called by an authorized observer or the asset owner. Triggers the resolution phase for the asset.
// resolveState(bytes32 assetId, int256 oracleConditionOutcomeReport, uint256 randomSeedFromOracle): Called by an authorized resolver/oracle to report external condition checks and a random seed, triggering the probabilistic outcome resolution for the asset.
// withdrawResolvedAsset(bytes32 assetId): Allows the asset owner to withdraw the asset if its state has been resolved to ACCESS_RESOLVED_SUCCESS.

// Observer Functions (Conceptual, staking not fully implemented here)
// stakeObserver(uint256 amount): Placeholder for an observer staking mechanism.
// unstakeObserver(uint256 amount): Placeholder for an observer unstaking mechanism.

// View Functions
// getAssetDetails(bytes32 assetId): Returns details about a specific asset.
// getConditionDetails(bytes32 conditionId): Returns details about a specific condition.
// getAssetProbability(bytes32 assetId): Calculates and returns the current potential access probability for an asset based on linked active conditions. (Note: This is the *potential* probability before resolution).
// getVaultState(): Returns the current global state of the vault.
// getObserverStake(address observer): Returns the stake amount for a given observer (Placeholder).
// isResolver(address account): Checks if an address is authorized to resolve states.
// getLinkedConditions(bytes32 assetId): Returns the list of condition IDs linked to an asset.

contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using SafeERC1155 for IERC1155;
    using Counters for Counters.Counter;

    // --- Enums ---
    enum AssetType {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    enum VaultState {
        ACTIVE,         // Normal operation
        PAUSED,         // All operations halted except emergency withdraw
        MAINTENANCE     // Limited operations, potentially owner-only config
    }

    enum AssetState {
        LOCKED,                  // Asset is deposited, no access attempts made
        PROBABILISTIC_ACCESS,    // An attempt has been made, state is pending resolution
        ACCESS_RESOLVED_SUCCESS, // State collapsed successfully, withdrawal is possible
        ACCESS_RESOLVED_FAIL,    // State collapsed unsuccessfully, withdrawal is currently not possible (may require another attempt after cooldown)
        WITHDRAWN                // Asset has been withdrawn
    }

    enum ConditionType {
        EXTERNAL_ORACLE_CHECK, // Condition depends on external data reported by oracle
        TIME_BASED,            // Condition depends on block.timestamp or block.number
        VAULT_STATE_BASED,     // Condition depends on the current VaultState
        BALANCE_BASED,         // Condition depends on a balance check (e.g., user holds min tokens)
        CUSTOM                 // Reserved for more complex, contract-specific logic evaluated by resolver
    }

    // --- Structs ---
    struct Condition {
        bytes32 id;                     // Unique ID for the condition
        ConditionType conditionType;    // Type of condition
        bytes parameters;               // Encoded parameters specific to the condition type (e.g., time, address, minimum value)
        uint256 associatedProbabilityWeight; // How much this condition influences the probability (positive or negative)
        bool isActive;                  // Can this condition be used?
    }

    struct AssetInfo {
        AssetType assetType;
        address tokenAddress; // Address for ERC20, ERC721, ERC1155
        uint256 tokenId;      // Token ID for ERC721, ERC1155
        uint256 amount;       // Amount for ETH, ERC20, ERC1155
        address owner;        // Original depositor/owner
        AssetState currentState;
        bytes32[] linkedConditionIds; // Conditions associated with this asset
        uint256 baseProbability;      // Base probability (in basis points, 0-10000) for access before conditions
        uint256 lastAttemptTimestamp; // Timestamp of the last attemptWithdrawal
    }

    // --- State Variables ---
    mapping(bytes32 => AssetInfo) public assets;
    mapping(bytes32 => Condition) public conditions;
    mapping(address => bool) public authorizedResolvers; // Addresses allowed to call resolveState
    mapping(address => uint256) public observerStakes; // Conceptual observer staking (amount) - not fully integrated resolution incentives

    bytes32[] public allAssetIds; // To iterate or track total assets (careful with size)
    bytes32[] public allConditionIds; // To iterate or track total conditions

    VaultState public currentVaultState;
    address public oracleAddress;

    // Configuration parameters (simplified)
    uint256 public withdrawalFeeRate; // Basis points (0-10000)
    uint256 public attemptCooldown;   // Time in seconds between withdrawal attempts

    // --- Events ---
    event AssetDeposited(bytes32 indexed assetId, AssetType indexed assetType, address indexed owner, address tokenAddress, uint256 tokenId, uint256 amount);
    event ConditionDefined(bytes32 indexed conditionId, ConditionType indexed conditionType, bool isActive);
    event ConditionRemoved(bytes32 indexed conditionId);
    event ConditionLinked(bytes32 indexed assetId, bytes32 indexed conditionId);
    event ConditionUnlinked(bytes32 indexed assetId, bytes32 indexed conditionId);
    event AssetBaseProbabilityUpdated(bytes32 indexed assetId, uint256 newProbability);
    event WithdrawalAttempted(bytes32 indexed assetId, address indexed by, uint256 timestamp);
    event StateResolved(bytes32 indexed assetId, AssetState indexed newState, int256 oracleReportOutcome, uint256 finalCalculatedProbability, uint256 randomFactor, string message);
    event AssetWithdrawn(bytes32 indexed assetId, address indexed to, uint256 feeAmount);
    event EmergencyWithdrawal(bytes32 indexed assetId, address indexed owner);
    event OracleAddressUpdated(address indexed newOracle);
    event ResolverAdded(address indexed resolver);
    event ResolverRemoved(address indexed resolver);
    event VaultStateUpdated(VaultState indexed newState);
    event ConfigUpdated(uint256 newWithdrawalFeeRate, uint256 newAttemptCooldown);
    event ObserverStaked(address indexed observer, uint256 amount);
    event ObserverUnstaked(address indexed observer, uint256 amount);

    // --- Modifiers ---
    modifier onlyResolver() {
        require(authorizedResolvers[msg.sender] || msg.sender == oracleAddress, "QV: Not authorized resolver");
        _;
    }

    modifier whenVaultActive() {
        require(currentVaultState == VaultState.ACTIVE, "QV: Vault not active");
        _;
    }

    modifier whenVaultNotPaused() {
        require(currentVaultState != VaultState.PAUSED, "QV: Vault is paused");
        _;
    }

    modifier onlyAssetOwner(bytes32 assetId) {
        require(assets[assetId].owner == msg.sender, "QV: Not asset owner");
        _;
    }

    // --- Constructor ---
    constructor(address initialOracle) Ownable(msg.sender) {
        oracleAddress = initialOracle;
        currentVaultState = VaultState.ACTIVE;
        withdrawalFeeRate = 100; // 1% fee by default
        attemptCooldown = 60; // 60 seconds cooldown
    }

    // --- Configuration & Management ---

    function setOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "QV: Invalid oracle address");
        oracleAddress = newOracle;
        emit OracleAddressUpdated(newOracle);
    }

    function addResolver(address resolver) public onlyOwner {
        require(resolver != address(0), "QV: Invalid resolver address");
        authorizedResolvers[resolver] = true;
        emit ResolverAdded(resolver);
    }

    function removeResolver(address resolver) public onlyOwner {
        require(resolver != address(0), "QV: Invalid resolver address");
        authorizedResolvers[resolver] = false;
        emit ResolverRemoved(resolver);
    }

    function updateConfig(uint256 newWithdrawalFeeRateBps, uint256 newAttemptCooldownSeconds) public onlyOwner {
        require(newWithdrawalFeeRateBps <= 10000, "QV: Fee rate must be <= 10000");
        withdrawalFeeRate = newWithdrawalFeeRateBps;
        attemptCooldown = newAttemptCooldownSeconds;
        emit ConfigUpdated(withdrawalFeeRate, attemptCooldown);
    }

    function emergencyClassicWithdraw(bytes32 assetId) public onlyOwner whenVaultNotPaused {
        AssetInfo storage asset = assets[assetId];
        require(asset.owner != address(0), "QV: Asset not found");
        require(asset.currentState != AssetState.WITHDRAWN, "QV: Asset already withdrawn");

        // Transfer asset to original owner bypassing state and conditions
        _transferAssetOut(assetId, asset.owner, 0); // 0 fee for emergency

        asset.currentState = AssetState.WITHDRAWN; // Mark as withdrawn

        emit EmergencyWithdrawal(assetId, asset.owner);
    }

    function setVaultState(VaultState newState) public onlyOwner {
        currentVaultState = newState;
        emit VaultStateUpdated(newState);
    }

    // --- Deposit Functions ---

    function depositETH() public payable whenVaultActive returns (bytes32 assetId) {
        require(msg.value > 0, "QV: Must send ETH");
        assetId = keccak256(abi.encodePacked(msg.sender, AssetType.ETH, address(0), block.timestamp, block.difficulty, allAssetIds.length));
        require(assets[assetId].owner == address(0), "QV: ID collision"); // Basic collision check

        assets[assetId] = AssetInfo({
            assetType: AssetType.ETH,
            tokenAddress: address(0),
            tokenId: 0,
            amount: msg.value,
            owner: msg.sender,
            currentState: AssetState.LOCKED,
            linkedConditionIds: new bytes32[](0),
            baseProbability: 5000, // Default 50% base probability
            lastAttemptTimestamp: 0
        });

        allAssetIds.push(assetId);

        emit AssetDeposited(assetId, AssetType.ETH, msg.sender, address(0), 0, msg.value);
        return assetId;
    }

    function depositERC20(IERC20 token, uint256 amount) public whenVaultActive returns (bytes32 assetId) {
        require(amount > 0, "QV: Must send amount");
        token.safeTransferFrom(msg.sender, address(this), amount);

        assetId = keccak256(abi.encodePacked(msg.sender, AssetType.ERC20, token, block.timestamp, block.difficulty, allAssetIds.length));
        require(assets[assetId].owner == address(0), "QV: ID collision");

        assets[assetId] = AssetInfo({
            assetType: AssetType.ERC20,
            tokenAddress: address(token),
            tokenId: 0,
            amount: amount,
            owner: msg.sender,
            currentState: AssetState.LOCKED,
            linkedConditionIds: new bytes32[](0),
            baseProbability: 5000, // Default 50% base probability
            lastAttemptTimestamp: 0
        });

        allAssetIds.push(assetId);

        emit AssetDeposited(assetId, AssetType.ERC20, msg.sender, address(token), 0, amount);
        return assetId;
    }

    function depositERC721(IERC721 token, uint256 tokenId) public whenVaultActive returns (bytes32 assetId) {
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        assetId = keccak256(abi.encodePacked(msg.sender, AssetType.ERC721, token, tokenId, block.timestamp, block.difficulty, allAssetIds.length));
        require(assets[assetId].owner == address(0), "QV: ID collision");

        assets[assetId] = AssetInfo({
            assetType: AssetType.ERC721,
            tokenAddress: address(token),
            tokenId: tokenId,
            amount: 1, // Amount is 1 for ERC721
            owner: msg.sender,
            currentState: AssetState.LOCKED,
            linkedConditionIds: new bytes32[](0),
            baseProbability: 5000, // Default 50% base probability
            lastAttemptTimestamp: 0
        });

        allAssetIds.push(assetId);

        emit AssetDeposited(assetId, AssetType.ERC721, msg.sender, address(token), tokenId, 1);
        return assetId;
    }

    function depositERC1155(IERC1155 token, uint256 tokenId, uint256 amount) public whenVaultActive returns (bytes32 assetId) {
        require(amount > 0, "QV: Must send amount");
        // Note: ERC1155 requires the vault to implement ERC1155Receiver or use safeTransferFrom with data
        // For simplicity, assuming safeTransferFrom is called correctly by the depositor before this.
        // A more robust implementation would use onERC1155Received.
        token.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        assetId = keccak256(abi.encodePacked(msg.sender, AssetType.ERC1155, token, tokenId, block.timestamp, block.difficulty, allAssetIds.length));
        require(assets[assetId].owner == address(0), "QV: ID collision");

        assets[assetId] = AssetInfo({
            assetType: AssetType.ERC1155,
            tokenAddress: address(token),
            tokenId: tokenId,
            amount: amount,
            owner: msg.sender,
            currentState: AssetState.LOCKED,
            linkedConditionIds: new bytes32[](0),
            baseProbability: 5000, // Default 50% base probability
            lastAttemptTimestamp: 0
        });

        allAssetIds.push(assetId);

        emit AssetDeposited(assetId, AssetType.ERC1155, msg.sender, address(token), tokenId, amount);
        return assetId;
    }

    // --- Condition Management ---

    function defineCondition(bytes32 conditionId, ConditionType conditionType, bytes calldata parameters, int256 associatedProbabilityWeight) public onlyOwner {
        // Simple check if ID exists, could be update or new define
        bool isUpdate = conditions[conditionId].id != bytes32(0);

        conditions[conditionId] = Condition({
            id: conditionId,
            conditionType: conditionType,
            parameters: parameters,
            associatedProbabilityWeight: uint256(associatedProbabilityWeight), // Store as uint, interpret as signed later
            isActive: true // Newly defined/updated conditions are active
        });

        if (!isUpdate) {
             allConditionIds.push(conditionId); // Only push if new ID
        }

        // associatedProbabilityWeight is stored as uint, but used in calculation as int256
        // Using int256 in signature for clarity on its purpose (can be negative weight)
        // Storing as uint here for simpler struct layout, casting back when used.
        // This requires careful handling when calculating total probability impact.

        emit ConditionDefined(conditionId, conditionType, true);
    }

    function removeCondition(bytes32 conditionId) public onlyOwner {
        require(conditions[conditionId].id != bytes32(0), "QV: Condition not found");
        conditions[conditionId].isActive = false; // Mark as inactive instead of deleting

        emit ConditionRemoved(conditionId);
    }

    function linkConditionToAsset(bytes32 assetId, bytes32 conditionId) public onlyOwner {
        require(assets[assetId].owner != address(0), "QV: Asset not found");
        require(conditions[conditionId].id != bytes32(0) && conditions[conditionId].isActive, "QV: Condition not found or not active");

        // Check if already linked (simple linear scan for now, could use mapping for large numbers)
        bool alreadyLinked = false;
        for (uint i = 0; i < assets[assetId].linkedConditionIds.length; i++) {
            if (assets[assetId].linkedConditionIds[i] == conditionId) {
                alreadyLinked = true;
                break;
            }
        }
        require(!alreadyLinked, "QV: Condition already linked");

        assets[assetId].linkedConditionIds.push(conditionId);

        emit ConditionLinked(assetId, conditionId);
    }

    function unlinkConditionFromAsset(bytes32 assetId, bytes32 conditionId) public onlyOwner {
        require(assets[assetId].owner != address(0), "QV: Asset not found");

        bytes32[] storage linked = assets[assetId].linkedConditionIds;
        bool found = false;
        for (uint i = 0; i < linked.length; i++) {
            if (linked[i] == conditionId) {
                // Simple removal by swapping with last element
                linked[i] = linked[linked.length - 1];
                linked.pop();
                found = true;
                break;
            }
        }
        require(found, "QV: Condition not linked to asset");

        emit ConditionUnlinked(assetId, conditionId);
    }

    function setAssetBaseProbability(bytes32 assetId, uint256 baseProbability) public onlyOwner {
        require(assets[assetId].owner != address(0), "QV: Asset not found");
        require(baseProbability <= 10000, "QV: Probability must be <= 10000");
        assets[assetId].baseProbability = baseProbability;

        emit AssetBaseProbabilityUpdated(assetId, baseProbability);
    }


    // --- Core Probabilistic Access Functions ---

    // attemptWithdrawal - The "Observation"
    // This function doesn't perform the withdrawal.
    // It changes the asset state from LOCKED to PROBABILISTIC_ACCESS,
    // signaling that an external resolver/oracle should now evaluate the conditions
    // and call resolveState to "collapse" the state.
    // Can be called by the asset owner or potentially an authorized observer (staking concept).
    function attemptWithdrawal(bytes32 assetId) public whenVaultActive {
        AssetInfo storage asset = assets[assetId];
        require(asset.owner != address(0), "QV: Asset not found");
        require(msg.sender == asset.owner, "QV: Not asset owner"); // Basic check, could add observer logic
        require(asset.currentState == AssetState.LOCKED || asset.currentState == AssetState.ACCESS_RESOLVED_FAIL, "QV: Asset not in withdrawable attempt state");
        require(block.timestamp >= asset.lastAttemptTimestamp + attemptCooldown, "QV: Cooldown period active");

        asset.currentState = AssetState.PROBABILISTIC_ACCESS;
        asset.lastAttemptTimestamp = block.timestamp;

        emit WithdrawalAttempted(assetId, msg.sender, block.timestamp);
    }

    // resolveState - The "State Collapse"
    // This function is called by an authorized resolver (likely an oracle)
    // after evaluating the external conditions linked to the asset and obtaining
    // a source of randomness.
    // It calculates the final probability, uses the random seed to determine
    // success or failure, and updates the asset's state.
    function resolveState(bytes32 assetId, int256 oracleConditionOutcomeReport, uint256 randomSeedFromOracle) public onlyResolver whenVaultActive {
        AssetInfo storage asset = assets[assetId];
        require(asset.owner != address(0), "QV: Asset not found");
        require(asset.currentState == AssetState.PROBABILISTIC_ACCESS, "QV: Asset not in probabilistic state");

        // --- Probability Calculation Logic ---
        // Calculate the combined probability impact from linked conditions
        // Simplified logic: Sum of associatedProbabilityWeight from active conditions + baseProbability
        // Weights can be positive or negative. Ensure result stays within 0-10000 range.
        int256 totalProbabilityImpact = int256(asset.baseProbability);

        for (uint i = 0; i < asset.linkedConditionIds.length; i++) {
            bytes32 conditionId = asset.linkedConditionIds[i];
            Condition storage condition = conditions[conditionId];
            if (condition.isActive) {
                 // The oracleConditionOutcomeReport is expected to be a weighted sum or score
                 // derived by the oracle based on the *actual* state of the conditions.
                 // This part is highly dependent on the *off-chain* oracle implementation.
                 // For this contract, we trust the oracle's report and apply it.
                 // A sophisticated system might involve ZK proofs here.
                 totalProbabilityImpact += oracleConditionOutcomeReport; // Example: adding oracle's report

                 // Also add static condition weight
                 totalProbabilityImpact += int256(condition.associatedProbabilityWeight);
            }
        }

        // Clamp probability between 0 and 10000 (0% to 100%)
        uint256 finalProbability = uint256(Math.max(int256(0), Math.min(int256(10000), totalProbabilityImpact)));

        // --- Probabilistic Outcome Determination ---
        // Use the provided random seed to simulate the probabilistic outcome.
        // The oracle *must* provide a verifiable random seed (e.g., Chainlink VRF)
        // otherwise, the resolver can manipulate the outcome.
        // Simple example using block data and the seed:
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(assetId, randomSeedFromOracle, block.timestamp, block.difficulty)));
        uint256 outcomeDeterminant = randomNumber % 10001; // Result between 0 and 10000

        AssetState newState;
        string memory message;
        if (outcomeDeterminant < finalProbability) {
            newState = AssetState.ACCESS_RESOLVED_SUCCESS;
            message = "State collapsed successfully";
        } else {
            newState = AssetState.ACCESS_RESOLVED_FAIL;
            message = "State collapsed unsuccessfully";
        }

        asset.currentState = newState;

        emit StateResolved(assetId, newState, oracleConditionOutcomeReport, finalProbability, randomNumber, message);

        // Optional: If state resolved to success, allow immediate withdrawal by owner
        // This could be a config option. For now, owner must call withdrawResolvedAsset.
    }

    // withdrawResolvedAsset - The "Access"
    // Allows the asset owner to withdraw if the state has been resolved to success.
    function withdrawResolvedAsset(bytes32 assetId) public whenVaultActive onlyAssetOwner(assetId) {
        AssetInfo storage asset = assets[assetId];
        require(asset.currentState == AssetState.ACCESS_RESOLVED_SUCCESS, "QV: Asset not in ACCESS_RESOLVED_SUCCESS state");

        // Calculate withdrawal fee
        uint256 feeAmount = 0;
        if (withdrawalFeeRate > 0) {
            // Calculate fee based on asset value. Needs price oracle for tokens.
            // For simplicity here, let's just take a percentage of ETH amount,
            // or a fixed fee for tokens/NFTs. A real implementation needs a
            // sophisticated fee calculation potentially based on asset type/value.
            // As a placeholder, applying fee only to ETH.
            if (asset.assetType == AssetType.ETH) {
                 feeAmount = (asset.amount * withdrawalFeeRate) / 10000;
            } else if (asset.assetType == AssetType.ERC20) {
                 // Fee calculation for ERC20 is complex (value depends on price).
                 // Could take a percentage of tokens, or require a separate fee payment.
                 // Placeholder: No fee on token amount directly, could require fee in ETH/stablecoin
            }
            // Add logic for ERC721/ERC1155 fees (could be fixed ETH/token fee)
        }

        _transferAssetOut(assetId, asset.owner, feeAmount);

        asset.currentState = AssetState.WITHDRAWN;

        emit AssetWithdrawn(assetId, asset.owner, feeAmount);
    }

    // Internal helper function to handle asset transfers
    function _transferAssetOut(bytes32 assetId, address to, uint256 feeAmount) internal {
        AssetInfo storage asset = assets[assetId];
        uint256 amountToSend = asset.amount;

        if (asset.assetType == AssetType.ETH) {
            uint256 ethFee = feeAmount; // Fee was calculated in ETH in withdrawResolvedAsset
            require(amountToSend >= ethFee, "QV: Insufficient ETH for fee");
            payable(to).transfer(amountToSend - ethFee);
            // Fee ETH stays in contract or sent elsewhere
        } else if (asset.assetType == AssetType.ERC20) {
            // ERC20 fee logic needs careful design.
            // For this example, assuming fee is paid separately or not taken from token amount directly.
            // If fee is taken from amount: uint256 tokenFee = (amountToSend * withdrawalFeeRate) / 10000;
            // IERC20(asset.tokenAddress).safeTransfer(to, amountToSend - tokenFee);
            IERC20(asset.tokenAddress).safeTransfer(to, amountToSend); // Transfer full amount, fee handled elsewhere
        } else if (asset.assetType == AssetType.ERC721) {
            // ERC721 fee logic also needs careful design (e.g., fixed ETH/token fee)
            // Assuming no fee taken from the NFT itself.
            IERC721(asset.tokenAddress).safeTransferFrom(address(this), to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC1155) {
            // ERC1155 fee logic similar to ERC20 or ERC721 depending on design
            // Assuming no fee taken from the 1155 amount directly.
            IERC1155(asset.tokenAddress).safeTransferFrom(address(this), to, asset.tokenId, amountToSend, "");
        }
    }

    // --- Observer Functions (Conceptual) ---
    // These are placeholders for a more complex system where observers might stake
    // tokens to gain the right to call attemptWithdrawal, potentially earning
    // a portion of withdrawal fees for triggering successful resolutions.
    function stakeObserver(uint256 amount) public payable {
        // Example: Stake ETH
        require(msg.value == amount, "QV: Send required stake amount");
        observerStakes[msg.sender] += amount;
        // Could add requirements: minimum stake, specific token, etc.
        emit ObserverStaked(msg.sender, amount);
    }

    function unstakeObserver(uint256 amount) public {
        // Example: Unstake ETH
        require(observerStakes[msg.sender] >= amount, "QV: Insufficient stake");
        observerStakes[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit ObserverUnstaked(msg.sender, amount);
    }


    // --- View Functions ---

    function getAssetDetails(bytes32 assetId) public view returns (
        AssetType assetType,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address owner,
        AssetState currentState,
        bytes32[] memory linkedConditionIds,
        uint256 baseProbability,
        uint256 lastAttemptTimestamp
    ) {
        AssetInfo storage asset = assets[assetId];
        require(asset.owner != address(0), "QV: Asset not found"); // Use owner presence as existence check

        return (
            asset.assetType,
            asset.tokenAddress,
            asset.tokenId,
            asset.amount,
            asset.owner,
            asset.currentState,
            asset.linkedConditionIds,
            asset.baseProbability,
            asset.lastAttemptTimestamp
        );
    }

    function getConditionDetails(bytes32 conditionId) public view returns (
        bytes32 id,
        ConditionType conditionType,
        bytes memory parameters,
        uint256 associatedProbabilityWeight,
        bool isActive
    ) {
        Condition storage condition = conditions[conditionId];
        require(condition.id != bytes32(0), "QV: Condition not found");

        return (
            condition.id,
            condition.conditionType,
            condition.parameters,
            condition.associatedProbabilityWeight,
            condition.isActive
        );
    }

    // This calculates the potential probability *before* resolution, based on active conditions
    function getAssetProbability(bytes32 assetId) public view returns (uint256 potentialProbability) {
        AssetInfo storage asset = assets[assetId];
        require(asset.owner != address(0), "QV: Asset not found");

        int256 totalProbabilityImpact = int256(asset.baseProbability);

        for (uint i = 0; i < asset.linkedConditionIds.length; i++) {
            bytes32 conditionId = asset.linkedConditionIds[i];
            Condition storage condition = conditions[conditionId];
            if (condition.isActive) {
                 // Only add the static weight here, as the oracle report isn't available yet
                 totalProbabilityImpact += int256(condition.associatedProbabilityWeight);
            }
        }

        return uint256(Math.max(int256(0), Math.min(int256(10000), totalProbabilityImpact)));
    }

    function getVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    function getObserverStake(address observer) public view returns (uint256) {
        return observerStakes[observer];
    }

    function isResolver(address account) public view returns (bool) {
        return authorizedResolvers[account] || account == oracleAddress;
    }

    function getLinkedConditions(bytes32 assetId) public view returns (bytes32[] memory) {
         AssetInfo storage asset = assets[assetId];
         require(asset.owner != address(0), "QV: Asset not found");
         return asset.linkedConditionIds;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Required for ERC721/ERC1155 transfers if using safeTransferFrom
    // This is a minimal implementation. A full receiver would validate sender/data.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return IERC721.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data) external returns (bytes4) {
         return IERC1155.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external returns (bytes4) {
         return IERC1155.onERC1155BatchReceived.selector;
    }
}
```