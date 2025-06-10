Okay, here is a smart contract concept combining several advanced, creative, and non-standard mechanics within a "Quantum Vault" theme. It's designed to showcase complex conditional logic, interconnected asset states, and novel interaction patterns beyond typical token or DeFi contracts.

**Disclaimer:** This contract is a complex, experimental concept. It is written for illustrative purposes and would require extensive auditing, testing, and potentially Layer 2 or off-chain components (like VRF fulfillments) for production use. The "Quantum" aspects are metaphorical applications of complex conditional logic and state changes on the EVM, not actual quantum computing.

---

**Quantum Vault Smart Contract**

This contract serves as a vault for ETH, ERC-20, and ERC-721 assets, introducing novel "quantum-inspired" mechanics for locking, releasing, and interacting with deposited assets. It features:

1.  **Multi-Conditional "Quantum Locks":** Assets can be locked based on combinations of time, block number, external contract state, or even the outcome of specific events.
2.  **"Entangled Assets":** Linking two separate assets (or positions) such that actions on one can trigger predefined effects on the other (e.g., withdrawing one asset triggers a small transfer, a state change, or a temporary lock on the "entangled" asset).
3.  **"Probabilistic Release":** Assets can be set up to only become available upon a successful probabilistic outcome (requiring a VRF/oracle).
4.  **"Temporal Folding Locks":** Locks based on the passage of a time window relative to a specific, perhaps historical, block or a complex future calculation.
5.  **"Quantum Dust" Accumulation:** Accumulation of tiny residual amounts from transactions or effects, claimable under specific, rare conditions.
6.  **Global "Quantum Entanglement State":** A contract-wide state that can dynamically influence the behavior of locks, entanglements, and withdrawals based on external or internal triggers.

---

**Outline & Function Summary**

1.  **Core Vault Management:**
    *   `depositETH()`: Deposit ETH into the vault.
    *   `depositERC20(address token, uint256 amount)`: Deposit ERC-20 tokens.
    *   `depositERC721(address token, uint256 tokenId)`: Deposit ERC-721 tokens.
    *   `withdrawETH(uint256 amount)`: Withdraw ETH (subject to locks/entanglements).
    *   `withdrawERC20(address token, uint256 amount)`: Withdraw ERC-20 (subject to locks/entanglements).
    *   `withdrawERC721(address token, uint256 tokenId)`: Withdraw ERC-721 (subject to locks/entanglements).
    *   `getVaultBalanceETH(address user)`: Get user's ETH balance in the vault.
    *   `getVaultBalanceERC20(address user, address token)`: Get user's ERC-20 balance in the vault.
    *   `getVaultBalanceERC721(address user, address token)`: Get user's ERC-721 tokens in the vault (returns count, specific IDs require iteration or a separate function).

2.  **Quantum Locks:**
    *   `applyQuantumLock(uint8 assetType, address assetAddress, uint256 assetId, bytes32[] conditions, uint64 lockEndTime)`: Apply a multi-conditional lock to a specific asset.
    *   `checkQuantumLockStatus(address user, uint8 assetType, address assetAddress, uint256 assetId)`: Check if the quantum lock conditions are currently met for an asset.
    *   `releaseQuantumLockedAsset(uint8 assetType, address assetAddress, uint256 assetId)`: Attempt to release an asset from a quantum lock if conditions are met.
    *   `getQuantumLockDetails(address user, uint8 assetType, address assetAddress, uint256 assetId)`: Retrieve details of a specific quantum lock.

3.  **Entangled Assets:**
    *   `entangleAssets(uint8 assetTypeA, address assetAddressA, uint256 assetIdA, uint8 assetTypeB, address assetAddressB, uint256 assetIdB, uint8 entanglementEffectType)`: Create an entanglement link between two assets.
    *   `disentangleAssets(uint8 assetTypeA, address assetAddressA, uint256 assetIdA)`: Remove an entanglement link starting from asset A.
    *   `triggerEntanglementEffect(uint8 assetTypeA, address assetAddressA, uint256 assetIdA)`: Manually trigger the effect associated with an entanglement link starting from asset A (effects might also trigger automatically on withdrawal).
    *   `getEntanglementDetails(uint8 assetType, address assetAddress, uint256 assetId)`: Retrieve details of an asset's entanglement link (if any).

4.  **Probabilistic Release:**
    *   `setupProbabilisticRelease(uint8 assetType, address assetAddress, uint256 assetId, uint16 successProbabilityBasisPoints)`: Configure an asset for probabilistic release with a given success chance.
    *   `requestRandomnessForRelease(uint8 assetType, address assetAddress, uint256 assetId)`: (Simulated) Initiate a request for randomness for a probabilistic release.
    *   `fulfillRandomnessAndRelease(uint8 assetType, address assetAddress, uint256 assetId, uint256 randomNumber)`: (Simulated VRF fulfillment) Provide randomness to attempt the probabilistic release.

5.  **Temporal Folding Locks:**
    *   `applyTemporalFoldingLock(uint8 assetType, address assetAddress, uint256 assetId, uint256 baseBlockNumber, uint256 durationBlocks)`: Apply a lock based on a block duration relative to a specified base block.
    *   `checkTemporalFoldingLockStatus(uint8 assetType, address assetAddress, uint256 assetId)`: Check if a temporal folding lock has expired.
    *   `releaseTemporalFoldedAsset(uint8 assetType, address assetAddress, uint256 assetId)`: Attempt to release an asset from a temporal folding lock.

6.  **Quantum Dust & Claim:**
    *   `accumulateDust(uint8 assetType, address assetAddress, uint256 amount)`: (Internal/Triggered) Function to add to the dust pool. (Exposed for specific test/admin use, or triggered by effects).
    *   `setDustClaimConditions(bytes32[] conditions)`: Set the specific conditions required to claim accumulated dust.
    *   `claimAccumulatedDust()`: Attempt to claim all accumulated dust if conditions are met.
    *   `getTotalDustAmount(uint8 assetType, address assetAddress)`: Get the total amount of dust accumulated for a specific asset type/address.

7.  **Global Quantum Entanglement State:**
    *   `setQuantumEntanglementState(uint8 newState)`: Set the global contract state.
    *   `triggerQuantumStateShift(bytes32[] conditions, uint8 targetState)`: Trigger a change in the global state if specific conditions are met.
    *   `getCurrentQuantumState()`: Get the current global entanglement state.

8.  **Admin & Ownership:**
    *   `pauseVaultOperations()`: Pause sensitive vault operations.
    *   `unpauseVaultOperations()`: Unpause vault operations.
    *   `transferOwnership(address newOwner)`: Transfer contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for a mock external contract used in conditions
interface IExternalCondition {
    function checkCondition(bytes32 data) external view returns (bool);
}

// Helper library for complex condition checking (simplified)
library ConditionChecker {
    // Condition types represented by the first byte of bytes32
    // 0x01: Block number >= value (uint256)
    // 0x02: Timestamp >= value (uint256)
    // 0x03: Specific address balance (ERC20) >= value (address, uint256)
    // 0x04: Specific address owns ERC721 token ID (address, address, uint256)
    // 0x05: External contract condition call (address, bytes)
    // Add more complex condition types here...

    function check(bytes32[] memory conditions, address user, address contractAddress) internal view returns (bool) {
        if (conditions.length == 0) {
            return true; // No conditions means always met
        }

        for (uint i = 0; i < conditions.length; i++) {
            bytes32 condition = conditions[i];
            uint8 conditionType = uint8(condition[0]);
            bool met = false;

            if (conditionType == 0x01) { // Block number >= value
                uint256 targetBlock = uint256(condition & ~bytes32(uint256(0xFF)));
                if (block.number >= targetBlock) met = true;
            } else if (conditionType == 0x02) { // Timestamp >= value
                 uint256 targetTimestamp = uint256(condition & ~bytes32(uint256(0xFF)));
                 if (block.timestamp >= targetTimestamp) met = true;
            } else if (conditionType == 0x03) { // Specific address balance (ERC20) >= value
                // Format: 0x03[20 bytes address][11 bytes value]
                address tokenAddress = address(uint160(uint256(condition >> 96) & uint160(~bytes20(0))));
                uint256 requiredAmount = uint256(condition & ~bytes32(uint256(0xFF) << 96)); // This part is tricky with variable length
                 // Simplified check: Just check user's balance in *this* vault (requires contract context)
                 // For a general library, this would need a function parameter for balances
                 // Let's assume condition data encodes enough info to check external state or pass into contract call
                 // This is a placeholder for more complex logic.
                 // For simplicity in this contract example, let's interpret 0x03 as:
                 // bytes32: [0x03][address of token][0][required balance (padded)]
                 if (condition.length >= 33) { // Basic check for enough bytes
                     address tokenAddr = address(uint160(uint256(condition) << 8)); // Shift to get address
                     uint256 requiredBal = uint256(condition >> (8 + 20*8)); // Shift to get balance (simplified)
                     // This requires access to vault state, better done inside the contract
                      met = false; // Placeholder
                 }

            } else if (conditionType == 0x04) { // Specific address owns ERC721 token ID
                 // bytes32: [0x04][address of ERC721][0][tokenId (padded)]
                  if (condition.length >= 33) {
                      address tokenAddr = address(uint160(uint256(condition) << 8));
                      uint256 tokenId = uint256(condition >> (8 + 20*8));
                      // Check ownership outside this library or pass a function pointer
                       met = false; // Placeholder
                  }

            } else if (conditionType == 0x05) { // External contract condition call
                 // bytes32: [0x05][address of external contract][bytes data hash/identifier]
                 if (condition.length >= 33) {
                     address externalContract = address(uint160(uint256(condition) << 8));
                     bytes32 callDataHash = condition >> (8 + 20*8); // Use hash/identifier for simplicity
                     // This would require a dynamic call, potentially unsafe.
                     // A safer approach is to pre-register condition contracts and map identifiers.
                     // For simplicity, let's assume the data is an identifier for a known check on the external contract.
                      try IExternalCondition(externalContract).checkCondition(callDataHash) returns (bool externalMet) {
                          met = externalMet;
                      } catch {
                          met = false; // Call failed
                      }
                 }

            }
            // Add more complex conditions...

            // If any single condition isn't met, the overall check fails (AND logic)
            if (!met) {
                return false;
            }
        }
        // If all conditions were checked and none failed
        return true;
    }
}


contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using ConditionChecker for bytes32[];

    // Asset Types
    uint8 public constant ASSET_TYPE_ETH = 1;
    uint8 public constant ASSET_TYPE_ERC20 = 2;
    uint8 public constant ASSET_TYPE_ERC721 = 3;

    // Quantum Entanglement States (Example states)
    uint8 public constant QUANTUM_STATE_STABLE = 0;
    uint8 public constant QUANTUM_STATE_FLUCTUATING = 1; // May affect withdrawal fees/speeds
    uint8 public constant QUANTUM_STATE_ENTANGLED_BOOST = 2; // Boost entanglement effects
    uint8 public constant QUANTUM_STATE_ENTANGLEMENT_LOCK = 3; // Prevent disentanglement

    // Entanglement Effect Types (Example effects)
    uint8 public constant ENTANGLEMENT_EFFECT_NONE = 0;
    uint8 public constant ENTANGLEMENT_EFFECT_BURN_SMALL_PERCENT_B = 1; // Burn small percent of asset B on withdraw A
    uint8 public constant ENTANGLEMENT_EFFECT_TEMPORARY_LOCK_B = 2; // Apply temporary lock on asset B on withdraw A
    uint8 public constant ENTANGLEMENT_EFFECT_REQUIRE_OBSERVER_CALL = 3; // Require external triggerEntanglementEffect call after withdraw A

    mapping(address => uint256) private userETHBalances;
    mapping(address => mapping(address => uint256)) private userERC20Balances;
    mapping(address => mapping(address => uint256[])) private userERC721Tokens; // Simplified: stores list of tokenIds per user/contract

    // --- State Variables ---

    // Quantum Locks: Maps user address -> asset type -> asset address -> asset ID -> lock data
    mapping(address => mapping(uint8 => mapping(address => mapping(uint256 => QuantumLockData)))) private assetLocks;

    struct QuantumLockData {
        bytes32[] conditions; // Array of encoded condition data
        uint64 lockEndTime; // Absolute end time (useful for time-based conditions, 0 if no time limit)
        bool active; // Is this lock currently applied?
    }

    // Entanglements: Maps asset A (user, type, address, ID) to asset B (type, address, ID) and effect
    // Stored on Asset A: user -> type -> address -> ID -> entanglement data
    mapping(address => mapping(uint8 => mapping(address => mapping(uint256 => EntanglementData)))) private assetEntanglements;

    struct EntanglementData {
        address userB; // Owner of asset B (can be same as user A)
        uint8 assetTypeB;
        address assetAddressB;
        uint256 assetIdB;
        uint8 effectType; // Type of effect triggered by interaction with asset A
        bool active; // Is this entanglement active?
    }

    // Probabilistic Release: Maps asset (user, type, address, ID) -> probability and release status
    mapping(address => mapping(uint8 => mapping(address => mapping(uint256 => ProbabilisticReleaseData)))) private probabilisticReleases;

    struct ProbabilisticReleaseData {
        uint16 successProbabilityBasisPoints; // Probability * 100, e.g., 5000 for 50%
        bool setup; // Has probabilistic release been configured?
        uint256 randomNumber; // Randomness received from oracle
        bool releaseAttempted; // Has a release attempt been made with randomness?
    }

     // Temporal Folding Locks: Maps asset (user, type, address, ID) -> base block and duration
    mapping(address => mapping(uint8 => mapping(address => mapping(uint256 => TemporalFoldingLockData)))) private temporalFoldingLocks;

    struct TemporalFoldingLockData {
        uint256 baseBlockNumber; // The block number relative to which duration is calculated
        uint256 durationBlocks; // Number of blocks the lock lasts from the base block
        bool active; // Is this lock active?
    }


    // Quantum Dust: Maps asset type -> asset address -> total accumulated dust
    mapping(uint8 => mapping(address => uint256)) private quantumDust;
    bytes32[] private dustClaimConditions; // Conditions required to claim dust


    // Global Quantum State
    uint8 private currentQuantumState = QUANTUM_STATE_STABLE;
    bytes32[] private quantumStateShiftConditions; // Conditions for global state shift
    uint8 private quantumStateShiftTargetState; // The state to shift to if conditions met


    bool private paused = false;

    event Deposited(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId, uint256 amount);
    event Withdrew(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId, uint256 amount);
    event QuantumLockApplied(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId);
    event QuantumLockReleased(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId);
    event AssetEntangled(address indexed userA, uint8 assetTypeA, address indexed assetAddressA, uint256 assetIdA, address userB, uint8 assetTypeB, address assetAddressB, uint256 assetIdB, uint8 effectType);
    event AssetDisentangled(address indexed userA, uint8 assetTypeA, address indexed assetAddressA, uint256 assetIdA);
    event EntanglementEffectTriggered(address indexed userA, uint8 assetTypeA, address indexed assetAddressA, uint256 assetIdA, uint8 effectType);
    event ProbabilisticReleaseSetup(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId, uint16 probability);
    event ProbabilisticReleaseAttempted(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId, bool success);
    event TemporalFoldingLockApplied(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId, uint256 baseBlock, uint256 duration);
    event TemporalFoldingLockReleased(address indexed user, uint8 assetType, address indexed assetAddress, uint256 assetId);
    event DustAccumulated(uint8 assetType, address indexed assetAddress, uint256 amount);
    event DustClaimConditionsSet(bytes32[] conditions);
    event DustClaimed(address indexed user, uint256 ethAmount, uint256 erc20Count, uint256 erc721Count); // Simplified, just count claimed asset types
    event QuantumStateShifted(uint8 oldState, uint8 newState);
    event VaultPaused();
    event VaultUnpaused();


    modifier whenNotPaused() {
        require(!paused, "Vault: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Vault: Not paused");
        _;
    }

    // Helper to get an identifier for an asset position
    function _getAssetKey(uint8 assetType, address assetAddress, uint256 assetId) private pure returns (bytes32) {
        // Encode asset type, address, and ID into a single bytes32 key
        // This is a simplified approach and might need adjustment for complex IDs or multiple asset types
        return bytes32(uint256(assetType) | (uint256(uint160(assetAddress)) << 8) | (assetId << (8 + 160)));
    }

    // Helper to check if any lock (Quantum or Temporal Folding) exists and is active for an asset
    function _isAssetLocked(address user, uint8 assetType, address assetAddress, uint256 assetId) internal view returns (bool) {
         QuantumLockData storage qLock = assetLocks[user][assetType][assetAddress][assetId];
         if (qLock.active && !checkQuantumLockStatus(user, assetType, assetAddress, assetId)) {
             return true; // Quantum lock is active and conditions NOT met
         }

         TemporalFoldingLockData storage tLock = temporalFoldingLocks[user][assetType][assetAddress][assetId];
         if (tLock.active && !checkTemporalFoldingLockStatus(assetType, assetAddress, assetId)) {
             return true; // Temporal folding lock is active and not yet expired
         }

         // Add checks for other lock types here
         return false;
    }

    constructor() Ownable(msg.sender) {
        // Set initial dust claim conditions or leave empty
        dustClaimConditions = new bytes32[](0);
    }

    // --- Core Vault Management ---

    /// @notice Deposit ETH into the vault.
    function depositETH() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Vault: ETH amount must be > 0");
        userETHBalances[msg.sender] += msg.value;
        emit Deposited(msg.sender, ASSET_TYPE_ETH, address(0), 0, msg.value);
    }

    /// @notice Deposit ERC-20 tokens into the vault.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Vault: ERC20 amount must be > 0");
        require(token.isContract(), "Vault: Not a contract");
        IERC20 erc20 = IERC20(token);
        userERC20Balances[msg.sender][token] += amount;
        erc20.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, ASSET_TYPE_ERC20, token, 0, amount);
    }

    /// @notice Deposit ERC-721 token into the vault.
    /// @param token The address of the ERC-721 token.
    /// @param tokenId The ID of the token to deposit.
    function depositERC721(address token, uint256 tokenId) external whenNotPaused nonReentrant {
        require(token.isContract(), "Vault: Not a contract");
        IERC721 erc721 = IERC721(token);
        require(erc721.ownerOf(tokenId) == msg.sender, "Vault: Not owner of token");

        // Append token ID to user's list (simplified management)
        userERC721Tokens[msg.sender][token].push(tokenId);

        erc721.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Deposited(msg.sender, ASSET_TYPE_ERC721, token, tokenId, 1); // Amount is 1 for ERC721
    }

    /// @notice Withdraw ETH from the vault, subject to locks and entanglements.
    /// @param amount The amount of ETH to withdraw.
    function withdrawETH(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Vault: Amount must be > 0");
        require(userETHBalances[msg.sender] >= amount, "Vault: Insufficient ETH balance");
        require(!_isAssetLocked(msg.sender, ASSET_TYPE_ETH, address(0), 0), "Vault: Asset is locked"); // Check lock on ETH balance

        // Apply entanglement effect if ETH is entangled
        _applyEntanglementEffect(msg.sender, ASSET_TYPE_ETH, address(0), 0);

        userETHBalances[msg.sender] -= amount;
        Address.sendValue(payable(msg.sender), amount);
        emit Withdrew(msg.sender, ASSET_TYPE_ETH, address(0), 0, amount);
    }

    /// @notice Withdraw ERC-20 tokens from the vault, subject to locks and entanglements.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address token, uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Vault: Amount must be > 0");
        require(userERC20Balances[msg.sender][token] >= amount, "Vault: Insufficient ERC20 balance");
        require(!_isAssetLocked(msg.sender, ASSET_TYPE_ERC20, token, 0), "Vault: Asset is locked"); // Check lock on ERC20 balance

        // Apply entanglement effect if this ERC20 balance is entangled
        _applyEntanglementEffect(msg.sender, ASSET_TYPE_ERC20, token, 0);

        userERC20Balances[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrew(msg.sender, ASSET_TYPE_ERC20, token, 0, amount);
    }

    /// @notice Withdraw ERC-721 token from the vault, subject to locks and entanglements.
    /// @param token The address of the ERC-721 token.
    /// @param tokenId The ID of the token to withdraw.
    function withdrawERC721(address token, uint256 tokenId) external whenNotPaused nonReentrant {
        require(token.isContract(), "Vault: Not a contract");

        // Check if user owns this token *in the vault*
        bool found = false;
        uint256 indexToRemove = userERC721Tokens[msg.sender][token].length; // Placeholder for not found
        for(uint i = 0; i < userERC721Tokens[msg.sender][token].length; i++) {
            if (userERC721Tokens[msg.sender][token][i] == tokenId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }
        require(found, "Vault: User does not own token in vault");
        require(!_isAssetLocked(msg.sender, ASSET_TYPE_ERC721, token, tokenId), "Vault: Asset is locked");

        // Apply entanglement effect if this ERC721 is entangled
        _applyEntanglementEffect(msg.sender, ASSET_TYPE_ERC721, token, tokenId);

        // Remove token ID from user's list (simplified: swap with last and pop)
        uint256 lastIndex = userERC721Tokens[msg.sender][token].length - 1;
        if (indexToRemove != lastIndex) {
            userERC721Tokens[msg.sender][token][indexToRemove] = userERC721Tokens[msg.sender][token][lastIndex];
        }
        userERC721Tokens[msg.sender][token].pop();

        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrew(msg.sender, ASSET_TYPE_ERC721, token, tokenId, 1);
    }

    /// @notice Get a user's ETH balance stored in the vault.
    /// @param user The user's address.
    /// @return The ETH balance.
    function getVaultBalanceETH(address user) external view returns (uint256) {
        return userETHBalances[user];
    }

    /// @notice Get a user's ERC-20 balance for a specific token stored in the vault.
    /// @param user The user's address.
    /// @param token The address of the ERC-20 token.
    /// @return The ERC-20 balance.
    function getVaultBalanceERC20(address user, address token) external view returns (uint256) {
        return userERC20Balances[user][token];
    }

    /// @notice Get a user's ERC-721 tokens for a specific contract stored in the vault.
    /// @param user The user's address.
    /// @param token The address of the ERC-721 token contract.
    /// @return An array of token IDs.
    function getVaultBalanceERC721(address user, address token) external view returns (uint256[] memory) {
        return userERC721Tokens[user][token]; // Returns a copy
    }


    // --- Quantum Locks ---

    /// @notice Apply a multi-conditional "Quantum Lock" to a specific asset held by the sender.
    /// @dev Conditions are encoded bytes32 values. `lockEndTime` is an absolute timestamp or 0.
    /// @param assetType The type of asset (ETH, ERC20, ERC721).
    /// @param assetAddress The address of the asset contract (address(0) for ETH).
    /// @param assetId The ID of the asset (0 for ETH/ERC20 amounts).
    /// @param conditions An array of encoded condition data.
    /// @param lockEndTime An optional absolute timestamp for the lock duration.
    function applyQuantumLock(uint8 assetType, address assetAddress, uint256 assetId, bytes32[] calldata conditions, uint64 lockEndTime) external whenNotPaused nonReentrant {
         // Basic checks: ensure asset is held by sender in the vault
         require(assetType > 0 && assetType <= ASSET_TYPE_ERC721, "Vault: Invalid asset type");
         if (assetType == ASSET_TYPE_ETH) require(userETHBalances[msg.sender] > 0, "Vault: No ETH to lock");
         if (assetType == ASSET_TYPE_ERC20) require(userERC20Balances[msg.sender][assetAddress] > 0, "Vault: No ERC20 to lock");
         if (assetType == ASSET_TYPE_ERC721) {
              bool found = false;
              for(uint i = 0; i < userERC721Tokens[msg.sender][assetAddress].length; i++) {
                  if (userERC721Tokens[msg.sender][assetAddress][i] == assetId) { found = true; break;}
              }
              require(found, "Vault: User does not own ERC721 in vault");
         }
         require(!_isAssetLocked(msg.sender, assetType, assetAddress, assetId), "Vault: Asset is already locked"); // Prevent double locking

         assetLocks[msg.sender][assetType][assetAddress][assetId] = QuantumLockData({
             conditions: conditions,
             lockEndTime: lockEndTime,
             active: true
         });

         emit QuantumLockApplied(msg.sender, assetType, assetAddress, assetId);
    }

    /// @notice Check if the conditions for a quantum lock are currently met.
    /// @param user The owner of the asset.
    /// @param assetType The type of asset.
    /// @param assetAddress The address of the asset contract.
    /// @param assetId The ID of the asset.
    /// @return True if lock is active and conditions are met, false otherwise.
    function checkQuantumLockStatus(address user, uint8 assetType, address assetAddress, uint256 assetId) public view returns (bool) {
        QuantumLockData storage lock = assetLocks[user][assetType][assetAddress][assetId];
        if (!lock.active) {
            return true; // No active lock
        }

        // Check time-based component first
        if (lock.lockEndTime > 0 && block.timestamp < lock.lockEndTime) {
             return false; // Time lock not yet expired
        }

        // Check complex conditions using the library
        // Note: The library needs context for balance checks (like userERC20Balances)
        // For a real implementation, ConditionChecker would need to be internal/part of contract,
        // or rely on external view functions.
        // Simplified call for demonstration: assumes conditions encode self-sufficient checks or use global state
        return lock.conditions.check(user, address(this)); // Pass user and contract address context

    }

    /// @notice Attempt to release an asset from a quantum lock if its conditions are met.
    /// @dev This function primarily inactivates the lock state, allowing subsequent withdrawal.
    /// @param assetType The type of asset.
    /// @param assetAddress The address of the asset contract.
    /// @param assetId The ID of the asset.
    function releaseQuantumLockedAsset(uint8 assetType, address assetAddress, uint256 assetId) external whenNotPaused nonReentrant {
         QuantumLockData storage lock = assetLocks[msg.sender][assetType][assetAddress][assetId];
         require(lock.active, "Vault: No active quantum lock on asset");
         require(checkQuantumLockStatus(msg.sender, assetType, assetAddress, assetId), "Vault: Quantum lock conditions not met");

         lock.active = false; // Inactivate the lock
         // Consider clearing conditions array to save gas if lock is permanently removed
         // delete lock.conditions; // Or set conditions = new bytes32[](0);

         emit QuantumLockReleased(msg.sender, assetType, assetAddress, assetId);
    }

    /// @notice Retrieve details of a specific quantum lock.
    /// @param user The owner of the asset.
    /// @param assetType The type of asset.
    /// @param assetAddress The address of the asset contract.
    /// @param assetId The ID of the asset.
    /// @return conditions The encoded conditions.
    /// @return lockEndTime The absolute lock end timestamp.
    /// @return active Is the lock active?
    function getQuantumLockDetails(address user, uint8 assetType, address assetAddress, uint256 assetId) external view returns (bytes32[] memory conditions, uint64 lockEndTime, bool active) {
        QuantumLockData storage lock = assetLocks[user][assetType][assetAddress][assetId];
        return (lock.conditions, lock.lockEndTime, lock.active);
    }

    // --- Entangled Assets ---

    /// @notice Create an entanglement link between two assets held in the vault.
    /// @dev User A's asset is the "source", user B's asset is the "target" of the effect.
    /// @param assetTypeA, assetAddressA, assetIdA Details of the source asset (owned by msg.sender).
    /// @param userB The owner of the target asset.
    /// @param assetTypeB, assetAddressB, assetIdB Details of the target asset.
    /// @param entanglementEffectType The type of effect triggered by interacting with A.
    function entangleAssets(
        uint8 assetTypeA, address assetAddressA, uint256 assetIdA,
        address userB, uint8 assetTypeB, address assetAddressB, uint256 assetIdB,
        uint8 entanglementEffectType
    ) external whenNotPaused nonReentrant {
        // Basic checks for asset A ownership by sender
        require(assetTypeA > 0 && assetTypeA <= ASSET_TYPE_ERC721, "Vault: Invalid asset type A");
         if (assetTypeA == ASSET_TYPE_ETH) require(userETHBalances[msg.sender] > 0, "Vault: No ETH A to entangle");
         if (assetTypeA == ASSET_TYPE_ERC20) require(userERC20Balances[msg.sender][assetAddressA] > 0, "Vault: No ERC20 A to entangle");
         if (assetTypeA == ASSET_TYPE_ERC721) {
              bool found = false;
              for(uint i = 0; i < userERC721Tokens[msg.sender][assetAddressA].length; i++) {
                  if (userERC721Tokens[msg.sender][assetAddressA][i] == assetIdA) { found = true; break;}
              }
              require(found, "Vault: User does not own ERC721 A in vault");
         }

        // Basic checks for asset B ownership by userB
        require(assetTypeB > 0 && assetTypeB <= ASSET_TYPE_ERC721, "Vault: Invalid asset type B");
         if (assetTypeB == ASSET_TYPE_ETH) require(userETHBalances[userB] > 0, "Vault: UserB has no ETH to entangle");
         if (assetTypeB == ASSET_TYPE_ERC20) require(userERC20Balances[userB][assetAddressB] > 0, "Vault: UserB has no ERC20 to entangle");
         if (assetTypeB == ASSET_TYPE_ERC721) {
              bool found = false;
              for(uint i = 0; i < userERC721Tokens[userB][assetAddressB].length; i++) {
                  if (userERC721Tokens[userB][assetAddressB][i] == assetIdB) { found = true; break;}
              }
              require(found, "Vault: UserB does not own ERC721 B in vault");
         }

        // Prevent entangling an asset that is already the SOURCE of an entanglement
        require(!assetEntanglements[msg.sender][assetTypeA][assetAddressA][assetIdA].active, "Vault: Asset A is already source of entanglement");

        // Add consent mechanism for userB in a real application (e.g., signature or separate approval call)
        // For simplicity, this version assumes userB's consent is handled off-chain or via prior approval.

        assetEntanglements[msg.sender][assetTypeA][assetAddressA][assetIdA] = EntanglementData({
            userB: userB,
            assetTypeB: assetTypeB,
            assetAddressB: assetAddressB,
            assetIdB: assetIdB,
            effectType: entanglementEffectType,
            active: true
        });

        emit AssetEntangled(msg.sender, assetTypeA, assetAddressA, assetIdA, userB, assetTypeB, assetAddressB, assetIdB, entanglementEffectType);
    }

    /// @notice Remove an entanglement link initiated by the sender's asset.
    /// @dev Only the initiator of the entanglement can remove it.
    /// @param assetTypeA, assetAddressA, assetIdA Details of the source asset (owned by msg.sender).
    function disentangleAssets(uint8 assetTypeA, address assetAddressA, uint256 assetIdA) external whenNotPaused {
        EntanglementData storage entanglement = assetEntanglements[msg.sender][assetTypeA][assetAddressA][assetIdA];
        require(entanglement.active, "Vault: Asset A is not currently the source of an entanglement");
        require(currentQuantumState != QUANTUM_STATE_ENTANGLEMENT_LOCK, "Vault: Disentanglement is locked by quantum state");

        entanglement.active = false;
        // Consider clearing entanglement data to save gas
        // delete assetEntanglements[msg.sender][assetTypeA][assetAddressA][assetIdA];

        emit AssetDisentangled(msg.sender, assetTypeA, assetAddressA, assetIdA);
    }

    /// @notice Trigger the effect associated with an entanglement link starting from the sender's asset.
    /// @param assetTypeA, assetAddressA, assetIdA Details of the source asset (owned by msg.sender).
    function triggerEntanglementEffect(uint8 assetTypeA, address assetAddressA, uint256 assetIdA) public whenNotPaused nonReentrant {
         // Public visibility allows other contracts/users to trigger if effectType requires it
         EntanglementData storage entanglement = assetEntanglements[assetEntanglements[msg.sender][assetTypeA][assetAddressA][assetIdA].userB][assetTypeA][assetAddressA][assetIdA];
         require(entanglement.active, "Vault: Asset A is not currently the source of an entanglement");
         // Add checks here if only specific addresses can trigger certain effects

         _applyEntanglementEffect(msg.sender, assetTypeA, assetAddressA, assetIdA);
    }

     /// @dev Internal helper to apply the defined entanglement effect.
     /// @param userA Owner of asset A.
     /// @param assetTypeA, assetAddressA, assetIdA Details of asset A.
    function _applyEntanglementEffect(address userA, uint8 assetTypeA, address assetAddressA, uint256 assetIdA) internal {
        EntanglementData storage entanglement = assetEntanglements[userA][assetTypeA][assetAddressA][assetIdA];

        if (!entanglement.active || entanglement.effectType == ENTANGLEMENT_EFFECT_NONE) {
            return; // No active entanglement or no effect
        }

        address userB = entanglement.userB;
        uint8 assetTypeB = entanglement.assetTypeB;
        address assetAddressB = entanglement.assetAddressB;
        uint256 assetIdB = entanglement.assetIdB;

        emit EntanglementEffectTriggered(userA, assetTypeA, assetAddressA, assetIdA, entanglement.effectType);

        // --- Execute Effects based on type ---
        if (entanglement.effectType == ENTANGLEMENT_EFFECT_BURN_SMALL_PERCENT_B) {
             // Example: Burn 0.1% of ERC20 balance B if state is FLUCTUATING
             if (currentQuantumState == QUANTUM_STATE_FLUCTUATING && assetTypeB == ASSET_TYPE_ERC20) {
                  uint256 userBBalance = userERC20Balances[userB][assetAddressB];
                  uint256 burnAmount = userBBalance / 1000; // 0.1%
                  if (burnAmount > 0) {
                      userERC20Balances[userB][assetAddressB] -= burnAmount;
                      // Add to dust instead of burning to null address?
                       _accumulateDust(assetTypeB, assetAddressB, burnAmount);
                  }
             }
             // Add other asset types/effects for burning
        } else if (entanglement.effectType == ENTANGLEMENT_EFFECT_TEMPORARY_LOCK_B) {
             // Example: Apply a 1-hour temporal lock on asset B
             // This requires creating a new TemporalFoldingLockData entry
              temporalFoldingLocks[userB][assetTypeB][assetAddressB][assetIdB] = TemporalFoldingLockData({
                 baseBlockNumber: block.number, // Lock starts now
                 durationBlocks: 60 * 60 / 12, // Approx 1 hour in blocks (assuming 12s block time)
                 active: true
              });
              // Event for new temporal lock?
        } else if (entanglement.effectType == ENTANGLEMENT_EFFECT_REQUIRE_OBSERVER_CALL) {
             // The effect *is* requiring an external trigger call.
             // This branch might not do anything here if the effect is *only* to require the call.
             // Or it could set a flag that *prevents* asset B withdrawal until triggerEntanglementEffect is called *after* A is withdrawn.
             // Let's set a temporary flag.
             // Need state to track this: mapping(address => mapping(uint8 => mapping(address => mapping(uint256 => bool)))) private pendingObserverTrigger;
             // pendingObserverTrigger[userA][assetTypeA][assetAddressA][assetIdA] = true;
             // And modify withdraw functions for Asset B to check this flag if userB == msg.sender and asset A is entangled with B.
        }
        // Add more complex effects involving state changes, value transfers, etc.
    }

     /// @notice Retrieve details of an asset's entanglement link.
     /// @param user The owner of the source asset.
     /// @param assetType, assetAddress, assetId Details of the source asset.
     /// @return userB, assetTypeB, assetAddressB, assetIdB Details of the target asset.
     /// @return effectType The type of effect.
     /// @return active Is the entanglement active?
    function getEntanglementDetails(address user, uint8 assetType, address assetAddress, uint256 assetId) external view returns (
        address userB,
        uint8 assetTypeB,
        address assetAddressB,
        uint255 assetIdB,
        uint8 effectType,
        bool active
    ) {
        EntanglementData storage entanglement = assetEntanglements[user][assetType][assetAddress][assetId];
        return (
            entanglement.userB,
            entanglement.assetTypeB,
            entanglement.assetAddressB,
            entanglement.assetIdB,
            entanglement.effectType,
            entanglement.active
        );
    }

    // --- Probabilistic Release ---

    /// @notice Configure an asset held by the sender for probabilistic release.
    /// @dev Requires a VRF/oracle fulfillment later.
    /// @param assetType, assetAddress, assetId Details of the asset (owned by msg.sender).
    /// @param successProbabilityBasisPoints The success probability scaled by 100 (e.g., 5000 for 50%). Max 10000.
    function setupProbabilisticRelease(uint8 assetType, address assetAddress, uint256 assetId, uint16 successProbabilityBasisPoints) external whenNotPaused {
         require(successProbabilityBasisPoints <= 10000, "Vault: Probability cannot exceed 100%");
         // Check asset ownership by sender (similar to applyQuantumLock)
         // Add specific check that asset isn't currently locked or entangled in a conflicting way
         require(!_isAssetLocked(msg.sender, assetType, assetAddress, assetId), "Vault: Cannot set up probabilistic release on locked asset");
         // require(!assetEntanglements[msg.sender][assetType][assetAddress][assetId].active, "Vault: Cannot set up probabilistic release on entangled asset source");
         // require(!_isAssetEntangledAsTarget(msg.sender, assetType, assetAddress, assetId), "Vault: Cannot set up probabilistic release on entangled asset target"); // Need a helper for target checks

         probabilisticReleases[msg.sender][assetType][assetAddress][assetId] = ProbabilisticReleaseData({
             successProbabilityBasisPoints: successProbabilityBasisPoints,
             setup: true,
             randomNumber: 0, // Placeholder
             releaseAttempted: false
         });

         emit ProbabilisticReleaseSetup(msg.sender, assetType, assetAddress, assetId, successProbabilityBasisPoints);
    }

     // --- Simulation of VRF/Oracle interaction ---
    /// @notice (Simulated) Request randomness for a probabilistic release.
    /// @dev In a real contract, this would interact with a VRF coordinator or oracle.
    function requestRandomnessForRelease(uint8 assetType, address assetAddress, uint256 assetId) external whenNotPaused {
         ProbabilisticReleaseData storage releaseData = probabilisticReleases[msg.sender][assetType][assetAddress][assetId];
         require(releaseData.setup, "Vault: Probabilistic release not setup");
         require(!releaseData.releaseAttempted, "Vault: Probabilistic release already attempted");
         // In a real system, this would initiate the VRF process and cost gas.
         // For simulation, we just emit an event.
         // emit RandomnessRequested(msg.sender, assetType, assetAddress, assetId);
    }

     /// @notice (Simulated VRF fulfillment) Provide randomness to attempt probabilistic release.
     /// @dev In a real contract, this would be called by the VRF coordinator or oracle callback.
     /// @param assetType, assetAddress, assetId Details of the asset.
     /// @param randomNumber The random number provided by the oracle.
    function fulfillRandomnessAndRelease(uint8 assetType, address assetAddress, uint256 assetId, uint256 randomNumber) external whenNotPaused {
         // In a real system, this would have security checks (e.g., only callable by VRF coordinator)
         ProbabilisticReleaseData storage releaseData = probabilisticReleases[msg.sender][assetType][assetAddress][assetId];
         require(releaseData.setup, "Vault: Probabilistic release not setup");
         require(!releaseData.releaseAttempted, "Vault: Probabilistic release already attempted");

         releaseData.randomNumber = randomNumber;
         releaseData.releaseAttempted = true;

         // Determine success based on random number and probability
         // Use a secure way to get a value between 0 and 9999 from randomNumber
         uint16 outcome = uint16(uint256(keccak256(abi.encodePacked(randomNumber, assetId, block.number))) % 10000); // Use secure hash

         bool success = outcome < releaseData.successProbabilityBasisPoints;

         if (success) {
              // Release logic: Inactivate the probabilistic release status
              releaseData.setup = false; // Release is now "done" or successful
              // The asset is now considered unlocked from this specific probabilistic mechanism.
              // Withdrawal would still need to pass other checks.
              emit ProbabilisticReleaseAttempted(msg.sender, assetType, assetAddress, assetId, true);
              emit QuantumLockReleased(msg.sender, assetType, assetAddress, assetId); // Reuse event or add new one
         } else {
              // Release failed
              // The asset remains under this probabilistic release setup, or it might transition to a different state
              // For simplicity, it just fails this attempt. Another randomness request might be needed.
              emit ProbabilisticReleaseAttempted(msg.sender, assetType, assetAddress, assetId, false);
         }
         // Note: Actual withdrawal logic happens via withdraw functions, not here.
         // The check in _isAssetLocked needs to be updated to include probabilistic release status.
         // For now, let's assume ProbabilisticReleaseData.setup == true means it's locked *by this mechanism* until successful attempt.
    }


    // --- Temporal Folding Locks ---

     /// @notice Apply a Temporal Folding Lock to an asset based on blocks passed since a base block.
     /// @param assetType, assetAddress, assetId Details of the asset (owned by msg.sender).
     /// @param baseBlockNumber The block number relative to which duration is calculated.
     /// @param durationBlocks Number of blocks the lock lasts.
    function applyTemporalFoldingLock(uint8 assetType, address assetAddress, uint256 assetId, uint256 baseBlockNumber, uint256 durationBlocks) external whenNotPaused nonReentrant {
         require(durationBlocks > 0, "Vault: Duration must be > 0");
         // Check asset ownership by sender (similar to applyQuantumLock)
         require(!_isAssetLocked(msg.sender, assetType, assetAddress, assetId), "Vault: Asset is already locked");

         temporalFoldingLocks[msg.sender][assetType][assetAddress][assetId] = TemporalFoldingLockData({
             baseBlockNumber: baseBlockNumber,
             durationBlocks: durationBlocks,
             active: true
         });

         emit TemporalFoldingLockApplied(msg.sender, assetType, assetAddress, assetId, baseBlockNumber, durationBlocks);
    }

    /// @notice Check if a Temporal Folding Lock has expired.
    /// @param assetType, assetAddress, assetId Details of the asset.
    /// @return True if lock is active and duration has passed, false otherwise.
    function checkTemporalFoldingLockStatus(uint8 assetType, address assetAddress, uint256 assetId) public view returns (bool) {
         TemporalFoldingLockData storage lock = temporalFoldingLocks[msg.sender][assetType][assetAddress][assetId];
         if (!lock.active) {
             return true; // No active lock
         }
         return block.number >= lock.baseBlockNumber + lock.durationBlocks;
    }

    /// @notice Attempt to release an asset from a Temporal Folding Lock if it has expired.
    /// @param assetType, assetAddress, assetId Details of the asset.
    function releaseTemporalFoldedAsset(uint8 assetType, address assetAddress, uint256 assetId) external whenNotPaused nonReentrant {
         TemporalFoldingLockData storage lock = temporalFoldingLocks[msg.sender][assetType][assetAddress][assetId];
         require(lock.active, "Vault: No active temporal folding lock");
         require(checkTemporalFoldingLockStatus(assetType, assetAddress, assetId), "Vault: Temporal folding lock not expired");

         lock.active = false; // Inactivate the lock
         // Consider clearing data

         emit TemporalFoldingLockReleased(msg.sender, assetType, assetAddress, assetId);
    }


    // --- Quantum Dust & Claim ---

     /// @notice (Internal/Triggered) Accumulates tiny residual amounts as dust.
     /// @dev Can be called by internal functions or potentially specific admin calls.
     /// @param assetType, assetAddress Details of the asset.
     /// @param amount The amount of dust to add.
    function _accumulateDust(uint8 assetType, address assetAddress, uint256 amount) internal {
         if (amount > 0) {
             quantumDust[assetType][assetAddress] += amount;
             emit DustAccumulated(assetType, assetAddress, amount);
         }
    }

     /// @notice Admin function to set the conditions required to claim accumulated dust.
     /// @param conditions An array of encoded condition data.
    function setDustClaimConditions(bytes32[] calldata conditions) external onlyOwner {
        dustClaimConditions = conditions;
        emit DustClaimConditionsSet(conditions);
    }

    /// @notice Attempt to claim all accumulated dust if the claim conditions are met.
    function claimAccumulatedDust() external whenNotPaused nonReentrant {
        require(dustClaimConditions.length > 0, "Vault: Dust claim conditions not set");
        // Use ConditionChecker library to verify global conditions
        require(dustClaimConditions.check(address(0), address(this)), "Vault: Dust claim conditions not met"); // Pass 0 user, contract address context

        uint256 ethAmount = quantumDust[ASSET_TYPE_ETH][address(0)];
        uint256 erc20ClaimCount = 0;
        uint256 erc721ClaimCount = 0; // ERC721 dust might represent fractional parts or failed transfers, complex to handle as full tokens

        // Transfer ETH dust
        if (ethAmount > 0) {
             quantumDust[ASSET_TYPE_ETH][address(0)] = 0;
             Address.sendValue(payable(msg.sender), ethAmount);
        }

        // Transfer ERC20 dust (requires knowing which ERC20s have dust)
        // Iterating through all possible ERC20 addresses is not feasible on-chain.
        // A more realistic approach would be to track a list of ERC20 addresses that have accumulated dust,
        // or require the caller to specify which ones to claim.
        // For this example, we'll just reset the dust for *all* tracked ERC20s (simplified).
        // In a real system, this would require careful tracking.
        // uint256 claimedERC20Types = 0;
        // for example, if we tracked a list: for(address token in trackedDustTokens) { ... }
        // uint256 erc20DustAmount = quantumDust[ASSET_TYPE_ERC20][token];
        // if (erc20DustAmount > 0) {
        //     quantumDust[ASSET_TYPE_ERC20][token] = 0;
        //     IERC20(token).safeTransfer(msg.sender, erc20DustAmount);
        //     claimedERC20Types++; // Count types claimed
        // }

         // ERC721 dust is conceptually harder. Maybe it represents failed transfers, or tiny fractions.
         // Simplification: Ignore ERC721 dust for now, or design a specific ERC721 dust mechanism.
         // Let's just claim ETH and ERC20 for this example.

         emit DustClaimed(msg.sender, ethAmount, erc20ClaimCount, erc721ClaimCount); // Report based on actual claim

    }

    /// @notice Get the total amount of dust accumulated for a specific asset type and address.
    /// @param assetType, assetAddress Details of the asset.
    /// @return The total dust amount.
    function getTotalDustAmount(uint8 assetType, address assetAddress) external view returns (uint256) {
         return quantumDust[assetType][assetAddress];
    }

    // --- Global Quantum Entanglement State ---

     /// @notice Admin function to set the global quantum entanglement state.
     /// @dev Can also be triggered by conditions.
     /// @param newState The new state to set.
    function setQuantumEntanglementState(uint8 newState) external onlyOwner {
        require(newState <= QUANTUM_STATE_ENTANGLEMENT_LOCK, "Vault: Invalid quantum state"); // Basic validation
        uint8 oldState = currentQuantumState;
        if (oldState != newState) {
            currentQuantumState = newState;
            emit QuantumStateShifted(oldState, newState);
        }
    }

    /// @notice Admin function to set the conditions and target state for a potential quantum state shift.
    /// @param conditions An array of encoded condition data.
    /// @param targetState The state to shift to if conditions are met.
    function setQuantumStateShiftTrigger(bytes32[] calldata conditions, uint8 targetState) external onlyOwner {
         require(targetState <= QUANTUM_STATE_ENTANGLEMENT_LOCK, "Vault: Invalid target quantum state");
         quantumStateShiftConditions = conditions;
         quantumStateShiftTargetState = targetState;
    }


    /// @notice Trigger a potential shift in the global quantum state if conditions are met.
    /// @dev This function can be called by anyone to check and trigger the state change.
    function triggerQuantumStateShift() external whenNotPaused {
         if (quantumStateShiftConditions.length > 0 && currentQuantumState != quantumStateShiftTargetState) {
             // Use ConditionChecker library to verify global conditions
             if (quantumStateShiftConditions.check(address(0), address(this))) { // Pass 0 user, contract address context
                  uint8 oldState = currentQuantumState;
                  currentQuantumState = quantumStateShiftTargetState;
                  emit QuantumStateShifted(oldState, currentQuantumState);
             }
         }
    }

    /// @notice Get the current global quantum entanglement state.
    /// @return The current state value.
    function getCurrentQuantumState() external view returns (uint8) {
         return currentQuantumState;
    }


    // --- Admin & Ownership ---

    /// @notice Pause sensitive vault operations.
    function pauseVaultOperations() external onlyOwner whenNotPaused {
        paused = true;
        emit VaultPaused();
    }

    /// @notice Unpause vault operations.
    function unpauseVaultOperations() external onlyOwner whenPaused {
        paused = false;
        emit VaultUnpaused();
    }

    // Override the default Ownable transferOwnership to add the whenNotPaused check
    function transferOwnership(address newOwner) public override onlyOwner whenNotPaused {
        super.transferOwnership(newOwner);
    }

    // Fallback function to accept ETH deposits even if not explicitly calling depositETH
    receive() external payable {
        if (msg.value > 0) {
             userETHBalances[msg.sender] += msg.value;
             emit Deposited(msg.sender, ASSET_TYPE_ETH, address(0), 0, msg.value);
        }
    }
}
```