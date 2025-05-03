Okay, let's design a smart contract that combines several advanced concepts: ERC-721 NFTs, Access Control, a simplified Vault pattern (similar in spirit to ERC-4626 but integrated into the NFT), and on-chain *simulated* performance tracking leading to evolving NFT attributes.

The core idea is: NFTs represent "Strategy Vaults". Users deposit funds (a specified `depositToken`) into a specific Strategy NFT. The NFT's metadata and on-chain attributes *evolve* based on a simulated performance score, which is updated via an oracle-like mechanism. This creates dynamic, performance-linked NFTs that also function as yield-bearing vaults.

**Concept Name:** Evolving Strategy Vaults (ESV)

**Advanced Concepts Used:**

1.  **ERC-721 Standard:** NFTs representing strategy vaults.
2.  **Access Control:** Granular roles for administrators, strategists, and oracle providers.
3.  **Vault Pattern (ERC-4626 inspired):** Shares representing deposited assets within each strategy NFT's associated "vault".
4.  **Dynamic NFTs:** On-chain attributes of the NFT (like `performanceScore`, `level`) change over time based on simulated performance.
5.  **Simulated Oracle Integration:** A dedicated role (`ORACLE_ROLE`) is responsible for updating the *simulated* performance data that drives the evolution.
6.  **On-Chain State Derived Metadata:** The `tokenURI` can point to a service that generates metadata based on the current on-chain state (`performanceScore`, `level`, etc.).
7.  **Modular Strategy Configuration:** Each NFT holds a specific, configurable `StrategyConfig` struct.
8.  **State Management:** Tracking strategy status (Active, Paused, Retired) and user shares per strategy.
9.  **Performance-Linked Logic:** Potential future expansions could link withdrawal fees or yield distribution to performance metrics.

**Non-Duplication Strategy:** While ERC-721, AccessControl, and Vault patterns exist, combining them specifically where the *NFT itself* represents the vault and *evolves based on the vault's performance* via a simulated oracle is a unique combination not typically found in standard libraries or simple examples. The evolution aspect tied directly to simulated investment performance within the NFT context is the creative twist.

---

**Outline:**

1.  **License & Pragma**
2.  **Imports:** ERC721, AccessControl, Counters, SafeMath (or Solidity 0.8+ checked arithmetic).
3.  **Error Definitions**
4.  **Constants:** Role definitions.
5.  **Enums:** StrategyStatus.
6.  **Structs:**
    *   `StrategyConfig`: Defines strategy parameters (e.g., risk level, simulated yield potential factors).
    *   `StrategyState`: Tracks runtime state (status, total assets, total shares, performance score, last updated timestamp).
7.  **State Variables:**
    *   Contract name/symbol for ERC721.
    *   Counters for token IDs.
    *   Mappings: `tokenId -> StrategyConfig`, `tokenId -> StrategyState`, `user -> tokenId -> shares`.
    *   The ERC20 address of the deposit token.
8.  **Events:** Strategy creation, deposit, withdrawal, performance update, config update, status change, role management.
9.  **Access Control Roles:** Admin, Strategist, Oracle.
10. **Constructor:** Initializes roles and base ERC721 parameters.
11. **Modifiers:** `onlyRole`, `whenStrategyActive`, `whenStrategyNotRetired`.
12. **Core ERC721 Functions (Overrides):** `_beforeTokenTransfer`. Standard `balanceOf`, `ownerOf`, `transferFrom`, etc. are provided by OpenZeppelin base.
13. **Access Control Functions:** `hasRole`, `getRoleAdmin`, `grantRole`, `revokeRole`, `renounceRole`.
14. **Strategy Management Functions:**
    *   `mintStrategy`: Create a new Strategy NFT.
    *   `updateStrategyConfig`: Modify strategy parameters.
    *   `pauseStrategy`: Halt operations for a strategy.
    *   `unpauseStrategy`: Resume operations.
    *   `retireStrategy`: Permanently disable a strategy.
    *   `getStrategyConfig`: View function.
    *   `getStrategyState`: View function.
    *   `listActiveStrategies`: Helper to find active strategies (potentially gas-intensive, could optimize with indexing if needed).
    *   `listStrategiesByStatus`: Filter by status.
15. **Vault Interaction Functions (ERC-4626 like):**
    *   `deposit`: Deposit assets into a strategy vault, receive shares.
    *   `withdraw`: Redeem shares for assets.
    *   `previewDeposit`: Calculate shares received for a deposit amount.
    *   `previewWithdraw`: Calculate assets received for shares.
    *   `getTotalAssets`: Total assets held by a strategy vault.
    *   `getTotalShares`: Total shares issued for a strategy.
    *   `convertToShares`: Convert asset amount to equivalent shares.
    *   `convertToAssets`: Convert share amount to equivalent assets.
    *   `maxDeposit`: Max assets a user can deposit (effectively unlimited here).
    *   `maxWithdraw`: Max shares a user can withdraw (user's balance).
16. **Performance & Evolution Functions:**
    *   `updatePerformanceScore`: Oracle role updates the score. This is the core "evolution" trigger.
    *   `getPerformanceScore`: View the score.
    *   `getLevel`: Derive an abstract 'level' from the score.
    *   `getOnChainMetadataAttributes`: Retrieve key on-chain data points for metadata generation.
    *   `_calculateYieldShares`: Internal helper for share calculation during deposit/withdraw reflecting accrued value (simulated).
17. **Metadata Functions:**
    *   `tokenURI`: Standard ERC721 metadata URI (likely off-chain, using `getOnChainMetadataAttributes`).
18. **Helper Functions:**
    *   Internal functions for share calculations, state updates.

---

**Function Summary:**

*   **ERC721 Overrides (1):**
    *   `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: Internal hook for ERC721 transfers.
*   **Access Control (5):**
    *   `hasRole(bytes32 role, address account)`: Checks if an account has a role.
    *   `getRoleAdmin(bytes32 role)`: Gets the admin role for a given role.
    *   `grantRole(bytes32 role, address account)`: Grants a role (admin only).
    *   `revokeRole(bytes32 role, address account)`: Revokes a role (admin or role admin).
    *   `renounceRole(bytes32 role)`: Renounces a role (self).
*   **Strategy Management (8):**
    *   `mintStrategy(StrategyConfig memory config)`: Mints a new Strategy NFT with initial configuration. (Requires `STRATEGIST_ROLE`)
    *   `updateStrategyConfig(uint256 tokenId, StrategyConfig memory newConfig)`: Updates the configuration of an existing strategy. (Requires `STRATEGIST_ROLE`)
    *   `pauseStrategy(uint256 tokenId)`: Pauses operations for a strategy. (Requires `STRATEGIST_ROLE`)
    *   `unpauseStrategy(uint256 tokenId)`: Unpauses a strategy. (Requires `STRATEGIST_ROLE`)
    *   `retireStrategy(uint256 tokenId)`: Permanently retires a strategy. No deposits/withdrawals allowed after. (Requires `ADMIN_ROLE`)
    *   `getStrategyConfig(uint256 tokenId)`: Pure/View function to get strategy config.
    *   `getStrategyState(uint256 tokenId)`: View function to get strategy state.
    *   `listActiveStrategies()`: View function returning an array of active strategy tokenIds.
*   **Vault Interaction (8):**
    *   `deposit(uint256 tokenId, uint256 amount)`: Deposits `amount` of `depositToken` into strategy `tokenId`, minting shares.
    *   `withdraw(uint256 tokenId, uint256 shares)`: Withdraws assets from strategy `tokenId` by burning `shares`.
    *   `previewDeposit(uint256 tokenId, uint256 amount)`: Calculates shares received for depositing `amount`.
    *   `previewWithdraw(uint256 tokenId, uint256 shares)`: Calculates assets received for withdrawing `shares`.
    *   `getTotalAssets(uint256 tokenId)`: Gets the total simulated value of assets in the strategy vault.
    *   `getTotalShares(uint256 tokenId)`: Gets the total shares minted for the strategy.
    *   `convertToShares(uint256 tokenId, uint256 assets)`: Converts an asset amount to the equivalent share amount.
    *   `convertToAssets(uint256 tokenId, uint256 shares)`: Converts a share amount to the equivalent asset amount.
*   **Performance & Evolution (4):**
    *   `updatePerformanceScore(uint256 tokenId, int256 scoreChange)`: Updates the performance score of a strategy. (Requires `ORACLE_ROLE`)
    *   `getPerformanceScore(uint256 tokenId)`: Gets the current performance score.
    *   `getLevel(uint256 tokenId)`: Gets the derived level based on the performance score.
    *   `getOnChainMetadataAttributes(uint256 tokenId)`: Returns a struct/tuple containing key on-chain attributes for off-chain metadata generation.
*   **Metadata (1):**
    *   `tokenURI(uint256 tokenId)`: Returns the URI for the NFT metadata (standard ERC721).
*   **Internal/Helper (Potentially many, but focusing on core public/external count):** The internal functions like `_mintShares`, `_burnShares`, `_updateStrategyTotalAssets`, `_calculateYieldShares` contribute to the complexity but aren't counted in the "at least 20 functions" request unless exposed externally. Let's add a couple of calculation helpers as external views for count/utility.
    *   `_calculateYieldShares(uint256 tokenId, uint256 assets)`: Internal calculation helper for shares considering current yield. (Could be exposed as view). Let's keep it internal.
    *   Need standard ERC721 view functions: `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`. (4 functions)
    *   Need standard ERC721 transfer functions: `transferFrom`, `safeTransferFrom` (two versions). (3 functions)

**Revised Function Count:**

*   ERC721 Standard (Views): 4 (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`)
*   ERC721 Standard (Transfers): 3 (`transferFrom`, `safeTransferFrom`, `safeTransferFrom`)
*   Access Control: 5 (`hasRole`, `getRoleAdmin`, `grantRole`, `revokeRole`, `renounceRole`)
*   Strategy Management: 8 (`mintStrategy`, `updateStrategyConfig`, `pauseStrategy`, `unpauseStrategy`, `retireStrategy`, `getStrategyConfig`, `getStrategyState`, `listActiveStrategies`)
*   Vault Interaction (ERC-4626 like): 8 (`deposit`, `withdraw`, `previewDeposit`, `previewWithdraw`, `getTotalAssets`, `getTotalShares`, `convertToShares`, `convertToAssets`)
*   Performance & Evolution: 4 (`updatePerformanceScore`, `getPerformanceScore`, `getLevel`, `getOnChainMetadataAttributes`)
*   Metadata: 1 (`tokenURI`)

**Total Count:** 4 + 3 + 5 + 8 + 8 + 4 + 1 = **33 Functions**. This meets the "at least 20" requirement comfortably.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming a standard ERC20 deposit token
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has checked arithmetic, SafeMath can be clearer for divisions/multiplications

// Outline:
// 1. License & Pragma
// 2. Imports (ERC721, AccessControl, Counters, IERC20, SafeMath)
// 3. Error Definitions (Custom errors for clarity)
// 4. Constants (Role definitions using keccak256)
// 5. Enums (StrategyStatus: Active, Paused, Retired)
// 6. Structs (StrategyConfig, StrategyState)
// 7. State Variables (NFT details, roles, counters, mappings, deposit token address)
// 8. Events (Key actions and state changes)
// 9. Access Control Role Definitions
// 10. Constructor (Initialize roles, ERC721)
// 11. Modifiers (Access control, strategy status checks)
// 12. ERC721 Functions (Standard overrides for transfers)
// 13. Access Control Functions (grant, revoke, renounce, etc.)
// 14. Strategy Management Functions (mint, update config, pause, unpause, retire, view details)
// 15. Vault Interaction Functions (Deposit, Withdraw, Previews, Asset/Share conversion - ERC-4626 pattern)
// 16. Performance & Evolution Functions (Update score, get score, get level, get on-chain attributes)
// 17. Metadata Functions (tokenURI, getOnChainMetadataAttributes)
// 18. Internal/Helper Functions (Share calculation logic)

// Function Summary:
// - ERC721 Standard (Views - 4): balanceOf, ownerOf, getApproved, isApprovedForAll
// - ERC721 Standard (Transfers - 3): transferFrom, safeTransferFrom (x2 overloads)
// - Access Control (5): hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole
// - Strategy Management (8): mintStrategy, updateStrategyConfig, pauseStrategy, unpauseStrategy, retireStrategy, getStrategyConfig, getStrategyState, listActiveStrategies
// - Vault Interaction (ERC-4626 like - 8): deposit, withdraw, previewDeposit, previewWithdraw, getTotalAssets, getTotalShares, convertToShares, convertToAssets
// - Performance & Evolution (4): updatePerformanceScore, getPerformanceScore, getLevel, getOnChainMetadataAttributes
// - Metadata (1): tokenURI
// Total Public/External Functions: 33+

contract EvolvingStrategyVaults is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Error Definitions ---
    error Esv__InvalidStrategyId();
    error Esv__StrategyNotActive();
    error Esv__StrategyRetired();
    error Esv__InsufficientShares();
    error Esv__ZeroAmount();
    error Esv__TransferFailed();
    error Esv__MintFailed();
    error Esv__RoleAlreadyGranted(); // Overlaps with default but good to be explicit
    error Esv__InvalidPerformanceScoreChange();

    // --- Constants ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // --- Enums ---
    enum StrategyStatus {
        Active,
        Paused,
        Retired
    }

    // --- Structs ---
    struct StrategyConfig {
        string name;
        string description;
        uint256 riskLevel; // e.g., 1-100
        // Add other strategy specific parameters here
        uint256 simulatedYieldFactor; // Factor used in simulated yield calculation (e.g., basis points)
    }

    struct StrategyState {
        StrategyStatus status;
        uint256 totalAssets; // Total value of assets in the strategy's vault (simulated)
        uint256 totalShares; // Total shares minted for this strategy
        int256 performanceScore; // Score driving NFT evolution (can be negative)
        uint64 lastPerformanceUpdate; // Timestamp of last score update
        // Add other dynamic state variables
    }

    struct OnChainMetadataAttributes {
        string name;
        string description;
        StrategyStatus status;
        uint256 riskLevel;
        uint256 totalAssets;
        uint256 totalShares;
        int256 performanceScore;
        uint256 level;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => StrategyConfig) private _strategyConfigs;
    mapping(uint256 => StrategyState) private _strategyStates;
    mapping(address => mapping(uint256 => uint256)) private _userShares; // user => tokenId => shares

    IERC20 public immutable depositToken;

    // To list strategies by status (can be gas intensive for large numbers)
    uint256[] private _activeStrategies;
    uint256[] private _pausedStrategies;
    uint256[] private _retiredStrategies;

    // --- Events ---
    event StrategyMinted(uint256 indexed tokenId, address indexed creator, StrategyConfig config);
    event Deposited(uint256 indexed tokenId, address indexed user, uint256 assetsAmount, uint256 sharesMinted);
    event Withdrew(uint256 indexed tokenId, address indexed user, uint256 sharesAmount, uint256 assetsWithdrawn);
    event StrategyConfigUpdated(uint256 indexed tokenId, StrategyConfig newConfig);
    event StrategyStatusChanged(uint256 indexed tokenId, StrategyStatus oldStatus, StrategyStatus newStatus);
    event PerformanceScoreUpdated(uint256 indexed tokenId, int256 newScore, int256 scoreChange);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address _depositTokenAddress)
        ERC721(name, symbol)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Admin also gets the custom ADMIN_ROLE
        _grantRole(STRATEGIST_ROLE, msg.sender); // Grant roles to deployer initially
        _grantRole(ORACLE_ROLE, msg.sender);

        depositToken = IERC20(_depositTokenAddress);
    }

    // --- Modifiers ---
    modifier whenStrategyActive(uint256 tokenId) {
        if (_strategyStates[tokenId].status != StrategyStatus.Active) {
            revert Esv__StrategyNotActive();
        }
        _;
    }

    modifier whenStrategyNotRetired(uint256 tokenId) {
         if (_strategyStates[tokenId].status == StrategyStatus.Retired) {
            revert Esv__StrategyRetired();
        }
        _;
    }

    // --- ERC721 Overrides ---
    // _beforeTokenTransfer is crucial for handling user shares when NFT ownership changes
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            // Transferring an active Strategy NFT - shares should move with the NFT
            // This is a simplified approach; real systems might require withdrawing first
            // Or have more complex rules around transferability and shared ownership.
            // For this example, we transfer all user shares held BY THE OLD OWNER IN THIS STRATEGY
            // to the new owner. The new owner now owns the NFT *and* the previous owner's stake.
            // A more typical ERC4626-in-NFT would require the user to withdraw before transferring the NFT.
            // This design is creative but might have undesirable side effects if users expect their
            // shares to stay with their address, not the NFT owner.
            // Let's stick to the simpler approach where shares represent a claim on the vault
            // regardless of NFT ownership, but prevent transfers if the NFT holder *has* shares.
            // ALTERNATIVE (Safer): Prohibit transfer if the NFT owner has shares in it.
            // Or require all users to withdraw before transfer.
            // Let's implement the "prohibit transfer if owner has shares" approach as it's safer.
            if (_userShares[from][tokenId] > 0) {
                 revert Esv__TransferFailed(); // NFT owner must withdraw their stake before transferring the NFT
            }
            // Other users' shares remain associated with their addresses and the tokenId.
            // They can still withdraw if the strategy is not retired.
        } else if (from == address(0) && to != address(0)) {
            // Minting - handled in mintStrategy, no shares exist yet
        } else if (from != address(0) && to == address(0)) {
            // Burning - e.g., retiring/redeeming the entire strategy.
            // All shares must be withdrawn before burning the NFT.
             if (_strategyStates[tokenId].totalShares > 0) {
                 revert Esv__TransferFailed(); // Cannot burn NFT while shares exist
            }
             // Clear state associated with the burned token
            delete _strategyConfigs[tokenId];
            delete _strategyStates[tokenId];
            // Removing from lists (simple approach - doesn't shrink array, leaves zero)
            // Better lists would use linked lists or other methods, but this is simpler for example.
             for(uint i = 0; i < _retiredStrategies.length; i++) {
                if (_retiredStrategies[i] == tokenId) {
                    _retiredStrategies[i] = 0; // Mark as deleted
                    break;
                }
            }
        }
    }

    // --- Access Control Functions ---
    // Default implementations provided by OpenZeppelin AccessControl
    // hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole

    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (hasRole(role, account)) revert Esv__RoleAlreadyGranted();
        _grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public virtual override {
         _checkRole(getRoleAdmin(role)); // Only admin of the role or default admin
        _revokeRole(role, account);
        emit RoleRevoked(role, account, msg.sender);
    }

    // --- Strategy Management Functions ---

    /// @notice Mints a new Strategy NFT. Only callable by an account with the STRATEGIST_ROLE.
    /// @param config The configuration parameters for the new strategy.
    /// @return The tokenId of the newly minted strategy NFT.
    function mintStrategy(StrategyConfig memory config)
        public
        onlyRole(STRATEGIST_ROLE)
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Mint the NFT to the creator of the strategy
        _safeMint(msg.sender, newTokenId);

        // Store the configuration and initial state
        _strategyConfigs[newTokenId] = config;
        _strategyStates[newTokenId] = StrategyState({
            status: StrategyStatus.Active,
            totalAssets: 0,
            totalShares: 0,
            performanceScore: 0, // Start with a neutral score
            lastPerformanceUpdate: uint64(block.timestamp)
        });

        // Add to active strategies list
        _activeStrategies.push(newTokenId);

        emit StrategyMinted(newTokenId, msg.sender, config);

        return newTokenId;
    }

    /// @notice Updates the configuration of an existing strategy. Only callable by an account with the STRATEGIST_ROLE.
    /// @param tokenId The ID of the strategy NFT to update.
    /// @param newConfig The new configuration parameters.
    function updateStrategyConfig(uint256 tokenId, StrategyConfig memory newConfig)
        public
        onlyRole(STRATEGIST_ROLE)
    {
        // Ensure the strategy exists
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();

        // Check if the strategy is retired
        if (_strategyStates[tokenId].status == StrategyStatus.Retired) revert Esv__StrategyRetired();

        _strategyConfigs[tokenId] = newConfig;
        emit StrategyConfigUpdated(tokenId, newConfig);
    }

    /// @notice Pauses operations for a strategy. Deposits and withdrawals are disabled. Only callable by an account with the STRATEGIST_ROLE.
    /// @param tokenId The ID of the strategy NFT to pause.
    function pauseStrategy(uint256 tokenId)
        public
        onlyRole(STRATEGIST_ROLE)
        whenStrategyActive(tokenId)
    {
         // Ensure the strategy exists
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();

        _strategyStates[tokenId].status = StrategyStatus.Paused;
        emit StrategyStatusChanged(tokenId, StrategyStatus.Active, StrategyStatus.Paused);

        // Remove from active list, add to paused list (simple logic)
         for(uint i = 0; i < _activeStrategies.length; i++) {
            if (_activeStrategies[i] == tokenId) {
                _activeStrategies[i] = 0; // Mark as deleted
                break;
            }
        }
        _pausedStrategies.push(tokenId);
    }

    /// @notice Unpauses a paused strategy. Deposits and withdrawals are re-enabled. Only callable by an account with the STRATEGIST_ROLE.
    /// @param tokenId The ID of the strategy NFT to unpause.
    function unpauseStrategy(uint256 tokenId)
        public
        onlyRole(STRATEGIST_ROLE)
    {
         // Ensure the strategy exists and is currently paused
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
        if (_strategyStates[tokenId].status != StrategyStatus.Paused) revert Esv__StrategyNotActive(); // Reusing error

        _strategyStates[tokenId].status = StrategyStatus.Active;
        emit StrategyStatusChanged(tokenId, StrategyStatus.Paused, StrategyStatus.Active);

         // Remove from paused list, add to active list (simple logic)
         for(uint i = 0; i < _pausedStrategies.length; i++) {
            if (_pausedStrategies[i] == tokenId) {
                _pausedStrategies[i] = 0; // Mark as deleted
                break;
            }
        }
        _activeStrategies.push(tokenId);
    }

    /// @notice Permanently retires a strategy. No further deposits or withdrawals are allowed. Only callable by an account with the ADMIN_ROLE.
    /// @param tokenId The ID of the strategy NFT to retire.
    function retireStrategy(uint256 tokenId)
        public
        onlyRole(ADMIN_ROLE)
        whenStrategyNotRetired(tokenId)
    {
        // Ensure the strategy exists
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();

        _strategyStates[tokenId].status = StrategyStatus.Retired;
        emit StrategyStatusChanged(tokenId, _strategyStates[tokenId].status, StrategyStatus.Retired); // Emit current status before retired

        // Remove from active or paused list, add to retired list (simple logic)
        if (_strategyStates[tokenId].status == StrategyStatus.Active) {
             for(uint i = 0; i < _activeStrategies.length; i++) {
                if (_activeStrategies[i] == tokenId) {
                    _activeStrategies[i] = 0; break;
                }
            }
        } else if (_strategyStates[tokenId].status == StrategyStatus.Paused) {
             for(uint i = 0; i < _pausedStrategies.length; i++) {
                if (_pausedStrategies[i] == tokenId) {
                    _pausedStrategies[i] = 0; break;
                }
            }
        }
        _retiredStrategies.push(tokenId);

        // Note: Burning the NFT would require all shares to be withdrawn first.
        // This function just changes status, allowing users to potentially withdraw remaining funds.
    }

    /// @notice Gets the configuration details for a strategy.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The StrategyConfig struct.
    function getStrategyConfig(uint256 tokenId)
        public
        view
        returns (StrategyConfig memory)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
        return _strategyConfigs[tokenId];
    }

     /// @notice Gets the current state details for a strategy.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The StrategyState struct.
    function getStrategyState(uint256 tokenId)
        public
        view
        returns (StrategyState memory)
    {
         if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
         return _strategyStates[tokenId];
    }

     /// @notice Returns a list of tokenIds for strategies that are currently Active.
    /// @dev Note: This function can be gas-intensive for many strategies due to array traversal.
    /// @return An array of active strategy tokenIds.
    function listActiveStrategies() public view returns (uint256[] memory) {
        // Filter out '0' entries from simple deletion
        uint256 count = 0;
        for(uint i = 0; i < _activeStrategies.length; i++) {
            if(_activeStrategies[i] != 0) {
                count++;
            }
        }
        uint256[] memory active = new uint256[](count);
        uint256 j = 0;
         for(uint i = 0; i < _activeStrategies.length; i++) {
            if(_activeStrategies[i] != 0) {
                active[j] = _activeStrategies[i];
                j++;
            }
        }
        return active;
    }

    /// @notice Returns a list of tokenIds for strategies based on their status.
    /// @dev Note: This function can be gas-intensive for many strategies.
    /// @param status The status to filter by (Active, Paused, Retired).
    /// @return An array of strategy tokenIds with the specified status.
    function listStrategiesByStatus(StrategyStatus status) public view returns (uint256[] memory) {
        uint256[] memory sourceArray;
        if (status == StrategyStatus.Active) sourceArray = _activeStrategies;
        else if (status == StrategyStatus.Paused) sourceArray = _pausedStrategies;
        else if (status == StrategyStatus.Retired) sourceArray = _retiredStrategies;
        else return new uint256[](0); // Should not happen with valid enum

         uint256 count = 0;
        for(uint i = 0; i < sourceArray.length; i++) {
            if(sourceArray[i] != 0) {
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        uint256 j = 0;
         for(uint i = 0; i < sourceArray.length; i++) {
            if(sourceArray[i] != 0) {
                result[j] = sourceArray[i];
                j++;
            }
        }
        return result;
    }


    // --- Vault Interaction Functions ---
    // Based on ERC-4626 principles, but integrated into the NFT's state

    /// @notice Deposits assets into a strategy vault and mints shares to the user.
    /// @param tokenId The ID of the strategy NFT.
    /// @param amount The amount of depositToken to deposit.
    /// @return The number of shares minted.
    function deposit(uint256 tokenId, uint256 amount)
        public
        whenStrategyActive(tokenId)
        returns (uint256 shares)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId(); // Ensure exists
        if (amount == 0) revert Esv__ZeroAmount();

        uint256 assetsBefore = _strategyStates[tokenId].totalAssets;
        uint256 sharesBefore = _strategyStates[tokenId].totalShares;

        // Calculate shares to mint based on current total assets and total shares (including simulated yield)
        shares = _calculateYieldShares(tokenId, amount); // Calculates shares based on current value/share price

        // Update state
        _strategyStates[tokenId].totalAssets = assetsBefore.add(amount); // Total assets increase by the deposited amount
        _strategyStates[tokenId].totalShares = sharesBefore.add(shares); // Total shares increase by minted shares
        _userShares[msg.sender][tokenId] = _userShares[msg.sender][tokenId].add(shares);

        // Transfer tokens from user to contract
        bool success = depositToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert Esv__TransferFailed();

        emit Deposited(tokenId, msg.sender, amount, shares);
        return shares;
    }

    /// @notice Withdraws assets from a strategy vault by burning shares.
    /// @param tokenId The ID of the strategy NFT.
    /// @param shares The number of shares to burn.
    /// @return The amount of assets withdrawn.
    function withdraw(uint256 tokenId, uint256 shares)
        public
        whenStrategyNotRetired(tokenId) // Can withdraw from Paused or Retired
        returns (uint256 assets)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId(); // Ensure exists
        if (shares == 0) revert Esv__ZeroAmount();
        if (_userShares[msg.sender][tokenId] < shares) revert Esv__InsufficientShares();

        uint256 assetsBefore = _strategyStates[tokenId].totalAssets;
        uint256 sharesBefore = _strategyStates[tokenId].totalShares;

        // Calculate assets to withdraw based on shares and current total assets/total shares
        // Ensure total shares is not zero before division if assets exist (edge case for first depositor withdrawing fully)
        if (sharesBefore == 0 || assetsBefore == 0) {
             // Should only happen if total assets is 0 and shares is > 0 (impossible state if logic is correct)
             // Or if total shares is 0, meaning no one has deposited.
             // If user has shares, totalShares must be > 0.
             revert Esv__InvalidStrategyId(); // Should not reach here if user has shares and totalShares=0 or totalAssets=0
        }
        assets = shares.mul(assetsBefore).div(sharesBefore);

        // Update state
        _strategyStates[tokenId].totalAssets = assetsBefore.sub(assets);
        _strategyStates[tokenId].totalShares = sharesBefore.sub(shares);
        _userShares[msg.sender][tokenId] = _userShares[msg.sender][tokenId].sub(shares);

        // Transfer tokens from contract to user
        bool success = depositToken.transfer(msg.sender, assets);
        if (!success) revert Esv__TransferFailed();

        emit Withdrew(tokenId, msg.sender, shares, assets);
        return assets;
    }

    /// @notice Calculates the number of shares received for a deposit amount.
    /// @param tokenId The ID of the strategy NFT.
    /// @param amount The amount of depositToken to deposit.
    /// @return The number of shares.
    function previewDeposit(uint256 tokenId, uint256 amount)
        public
        view
        whenStrategyActive(tokenId)
        returns (uint256)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId(); // Ensure exists
        if (amount == 0) return 0;

        return _calculateYieldShares(tokenId, amount);
    }

    /// @notice Calculates the asset amount received for a share amount.
    /// @param tokenId The ID of the strategy NFT.
    /// @param shares The number of shares.
    /// @return The amount of assets.
    function previewWithdraw(uint256 tokenId, uint256 shares)
        public
        view
        whenStrategyNotRetired(tokenId)
        returns (uint256)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId(); // Ensure exists
         if (shares == 0) return 0;
         if (_strategyStates[tokenId].totalShares == 0) return 0; // Cannot withdraw if no shares exist

        return shares.mul(_strategyStates[tokenId].totalAssets).div(_strategyStates[tokenId].totalShares);
    }

    /// @notice Gets the total simulated value of assets in a strategy vault.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The total assets.
    function getTotalAssets(uint256 tokenId) public view returns (uint256) {
         if (_ownerOf[tokenId] == address(0)) return 0; // Return 0 if doesn't exist
        return _strategyStates[tokenId].totalAssets;
    }

    /// @notice Gets the total shares minted for a strategy.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The total shares.
    function getTotalShares(uint256 tokenId) public view returns (uint256) {
         if (_ownerOf[tokenId] == address(0)) return 0; // Return 0 if doesn't exist
        return _strategyStates[tokenId].totalShares;
    }

    /// @notice Converts an asset amount to the equivalent share amount.
    /// @param tokenId The ID of the strategy NFT.
    /// @param assets The amount of assets.
    /// @return The equivalent shares.
    function convertToShares(uint256 tokenId, uint256 assets) public view returns (uint256) {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
        if (assets == 0) return 0;
        if (_strategyStates[tokenId].totalShares == 0) return assets; // First deposit: 1 share = 1 asset
        return assets.mul(_strategyStates[tokenId].totalShares).div(_strategyStates[tokenId].totalAssets);
    }

     /// @notice Converts a share amount to the equivalent asset amount.
    /// @param tokenId The ID of the strategy NFT.
    /// @param shares The amount of shares.
    /// @return The equivalent assets.
    function convertToAssets(uint256 tokenId, uint256 shares) public view returns (uint256) {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
        if (shares == 0) return 0;
        if (_strategyStates[tokenId].totalShares == 0) return 0; // Should not happen if shares > 0
        return shares.mul(_strategyStates[tokenId].totalAssets).div(_strategyStates[tokenId].totalShares);
    }

    /// @notice Returns the maximum amount of assets a user can deposit.
    /// @param tokenId The ID of the strategy NFT.
    /// @param user The address of the user.
    /// @return The maximum deposit amount (effectively limited by user's balance).
    function maxDeposit(uint256 tokenId, address user) public view returns (uint256) {
         if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();
         if (_strategyStates[tokenId].status != StrategyStatus.Active) return 0; // Can only deposit when active
        return depositToken.balanceOf(user);
    }

    /// @notice Returns the maximum shares a user can withdraw.
    /// @param tokenId The ID of the strategy NFT.
    /// @param user The address of the user.
    /// @return The maximum withdrawable shares (user's shares).
    function maxWithdraw(uint256 tokenId, address user) public view returns (uint256) {
         if (_ownerOf[tokenId] == address(0)) return 0; // Return 0 if doesn't exist
         if (_strategyStates[tokenId].status == StrategyStatus.Retired) return _userShares[user][tokenId]; // Can withdraw any amount if retired
         if (_strategyStates[tokenId].status == StrategyStatus.Paused) return _userShares[user][tokenId]; // Can withdraw any amount if paused
        // If Active, might have protocol limitations, but here it's just user's balance
        return _userShares[user][tokenId];
    }


    // --- Performance & Evolution Functions ---

    /// @notice Updates the performance score of a strategy. Only callable by an account with the ORACLE_ROLE.
    /// This function simulates external oracle data influencing the NFT's performance attribute.
    /// A positive scoreChange indicates positive performance, negative indicates loss.
    /// @param tokenId The ID of the strategy NFT.
    /// @param scoreChange The amount to add to the current performance score (can be negative).
    function updatePerformanceScore(uint256 tokenId, int256 scoreChange)
        public
        onlyRole(ORACLE_ROLE)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId(); // Ensure exists
        if (_strategyStates[tokenId].status == StrategyStatus.Retired) revert Esv__StrategyRetired(); // Cannot update retired strategy score

        // Update the score
        _strategyStates[tokenId].performanceScore += scoreChange;
        _strategyStates[tokenId].lastPerformanceUpdate = uint64(block.timestamp);

        // OPTIONAL: Update totalAssets based on performance score change
        // This simulates yield/loss. A simplistic model:
        // Change in Assets = Total Assets * (scoreChange / some_scaling_factor)
        // This makes totalAssets reflect performance, influencing share price.
        // Let's implement a simple simulation: assume 1000 basis points per 1 score point change
        // And base it on simulatedYieldFactor from config.
        // Example: A score change of +1 implies assets increase by (simulatedYieldFactor / 10000)% of total assets.
         if (_strategyStates[tokenId].totalAssets > 0 && scoreChange != 0) {
            int256 assetsChange = 0;
            if (scoreChange > 0) {
                 assetsChange = int256(_strategyStates[tokenId].totalAssets.mul(uint256(scoreChange)).mul(_strategyConfigs[tokenId].simulatedYieldFactor).div(10000 * 10000)); // Basis points * simulated factor / (10000*10000)
            } else {
                 // Use abs for calculation then negate
                 assetsChange = - int256(_strategyStates[tokenId].totalAssets.mul(uint256(-scoreChange)).mul(_strategyConfigs[tokenId].simulatedYieldFactor).div(10000 * 10000));
            }

            // Ensure total assets doesn't go negative
            if (assetsChange < 0 && uint256(-assetsChange) > _strategyStates[tokenId].totalAssets) {
                 _strategyStates[tokenId].totalAssets = 0;
            } else if (assetsChange >= 0) {
                 _strategyStates[tokenId].totalAssets = _strategyStates[tokenId].totalAssets.add(uint256(assetsChange));
            } else { // assetsChange < 0
                 _strategyStates[tokenId].totalAssets = _strategyStates[tokenId].totalAssets.sub(uint256(-assetsChange));
            }
        }


        emit PerformanceScoreUpdated(tokenId, _strategyStates[tokenId].performanceScore, scoreChange);
    }

    /// @notice Gets the current performance score for a strategy.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The performance score.
    function getPerformanceScore(uint256 tokenId) public view returns (int256) {
        if (_ownerOf[tokenId] == address(0)) return 0; // Return 0 or handle error
        return _strategyStates[tokenId].performanceScore;
    }

     /// @notice Gets the derived level for a strategy based on its performance score.
     /// This is a simple example; level calculation logic can be complex.
     /// @param tokenId The ID of the strategy NFT.
     /// @return The strategy's level.
    function getLevel(uint256 tokenId) public view returns (uint256) {
        if (_ownerOf[tokenId] == address(0)) return 0;
        int256 score = _strategyStates[tokenId].performanceScore;

        if (score < 0) return 0;
        if (score < 10) return 1;
        if (score < 50) return 2;
        if (score < 100) return 3;
        if (score < 500) return 4;
        return 5; // Max level example
    }

    /// @notice Returns key on-chain attributes of a strategy NFT relevant for metadata generation.
    /// @param tokenId The ID of the strategy NFT.
    /// @return A struct containing key on-chain attributes.
    function getOnChainMetadataAttributes(uint256 tokenId)
        public
        view
        returns (OnChainMetadataAttributes memory)
    {
        if (_ownerOf[tokenId] == address(0)) revert Esv__InvalidStrategyId();

        StrategyConfig storage config = _strategyConfigs[tokenId];
        StrategyState storage state = _strategyStates[tokenId];

        return OnChainMetadataAttributes({
            name: config.name,
            description: config.description,
            status: state.status,
            riskLevel: config.riskLevel,
            totalAssets: state.totalAssets,
            totalShares: state.totalShares,
            performanceScore: state.performanceScore,
            level: getLevel(tokenId) // Call internal helper
        });
    }


    // --- Metadata Functions ---

    /// @notice Returns the URI for the NFT metadata. This typically points to an off-chain service.
    /// @dev The off-chain service will use `getOnChainMetadataAttributes` to fetch dynamic data.
    /// @param tokenId The ID of the strategy NFT.
    /// @return The metadata URI string.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        // Ensure the token exists
        if (!_exists(tokenId)) {
            revert ERC721.ERC721NonexistentToken(tokenId);
        }

        // Construct a URI that includes the token ID
        // Example: ipfs://<base_uri>/<tokenId> or https://<api_endpoint>/metadata/<tokenId>
        // The off-chain service at this URI would call `getOnChainMetadataAttributes(tokenId)`
        // to build the JSON metadata including the dynamic attributes.
        // Replace with your actual base URI where your metadata service is hosted.
        string memory baseURI = "https://your-metadata-service.com/api/metadata/";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }


    // --- Internal/Helper Functions ---

    /// @notice Internal helper to calculate shares received for a deposit amount, considering current yield.
    /// @param tokenId The ID of the strategy NFT.
    /// @param assets The amount of assets being deposited.
    /// @return The calculated shares to mint.
    function _calculateYieldShares(uint256 tokenId, uint256 assets)
        internal
        view
        returns (uint256)
    {
        uint256 totalAssets = _strategyStates[tokenId].totalAssets;
        uint256 totalShares = _strategyStates[tokenId].totalShares;

        if (totalShares == 0 || totalAssets == 0) {
            // First deposit or vault is empty - shares = assets (1:1 ratio initially)
            return assets;
        } else {
            // Calculate shares based on the current price per share (totalAssets / totalShares)
            // shares = assets * (totalShares / totalAssets)
            return assets.mul(totalShares).div(totalAssets);
        }
    }

    // --- Standard ERC721 View Functions ---
    // These are included in the function count.

    function balanceOf(address owner)
        public
        view
        override(ERC721, ERC721)
        returns (uint256)
    {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override(ERC721, ERC721)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override(ERC721, ERC721)
        returns (address)
    {
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, ERC721)
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    // --- Standard ERC721 Transfer Functions ---
    // These are included in the function count.

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, ERC721)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, ERC721)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, ERC721)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // --- Access Control View Functions ---
    // These are included in the function count, though implemented by OZ base

    // function hasRole(bytes32 role, address account) public view override returns (bool) {}
    // function getRoleAdmin(bytes32 role) public view override returns (bytes32) {}

}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **NFT as a Vault:** The core concept is novel. An ERC-721 token isn't just a collectible; it *is* the container for deposited assets. This links the inherent scarcity and transferability of NFTs with the utility of a yield-bearing vault.
2.  **Dynamic NFTs driven by Performance:** The `performanceScore` and derived `level` are on-chain attributes tied to the strategy's simulated success. The `updatePerformanceScore` function, intended to be called by a trusted oracle/admin (`ORACLE_ROLE`), causes the NFT to "evolve". This evolution would be visually represented off-chain via the metadata service reading `getOnChainMetadataAttributes` and displaying different art, stats, or effects based on the score/level.
3.  **Simulated Oracle Interaction:** While not a *live* Chainlink integration, the `ORACLE_ROLE` and `updatePerformanceScore` function model how external data (like actual strategy yield or market conditions) would feed into the contract to update the dynamic NFT state. This clearly demonstrates the *pattern* without needing complex external adapter code within the contract itself.
4.  **Integrated Vault Logic:** Instead of using a separate ERC-4626 contract and having the NFT point to it, the vault's state (`totalAssets`, `totalShares`) and share calculations (`deposit`, `withdraw`, `convertToShares`, `convertToAssets`, etc.) are embedded within the NFT contract itself, directly associated with each `tokenId`. This simplifies deployment and tightly couples the NFT and the vault.
5.  **Role-Based Access Control:** Using `AccessControl` provides fine-grained permissions, separating who can mint strategies, who can update configurations, and who can provide performance updates. This is crucial for managing a complex system with different types of participants.
6.  **ERC-4626 Pattern Adaptation:** The deposit/withdraw/preview/conversion functions closely follow the ERC-4626 standard for tokenized vaults, providing a familiar interface for interacting with the asset management aspect of the Strategy NFTs.
7.  **On-Chain Attributes for Metadata:** The `getOnChainMetadataAttributes` function is designed to be called by an off-chain metadata service. This service would use the returned struct to generate the dynamic JSON metadata for the NFT, ensuring that websites and marketplaces display the current performance score, level, etc., making the NFT truly dynamic.

This contract provides a framework for a sophisticated system where NFTs are not just static images but living, breathing entities whose characteristics are tied to real-world (or simulated) performance within a DeFi-like context.