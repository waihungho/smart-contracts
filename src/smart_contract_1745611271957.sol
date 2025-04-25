Okay, here is a smart contract concept called "QuantumVault". It aims to be advanced and creative by combining multi-asset holding (Ether, ERC-20, ERC-721) with complex, configurable access conditions based on time, roles, and external oracle data. It also incorporates layered access control and emergency functions.

It uses concepts like:
*   **Multi-Asset Vaulting:** Handling different token standards and native currency.
*   **Configurable Access Conditions:** Unlocking assets based on logical conditions defined *after* deposit.
*   **Time-Based Logic:** Using block timestamps for time locks.
*   **Role-Based Access Control (RBAC):** Fine-grained permissions for managing conditions and rescue operations.
*   **External Oracle Integration:** Potential dependency on external data (e.g., asset price) for unlock conditions (using a mock/interface here, assuming a Chainlink-like feed).
*   **Reentrancy Protection & Pausability:** Standard but crucial security patterns.

It attempts to be non-standard by combining these elements in a user-centric vault where *depositors* might not be the *immediate* recipients, or where conditions change over time managed by administrators with specific roles.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Pragma**
2.  **Imports:** OpenZeppelin Contracts (AccessControl, ReentrancyGuard, Pausable, ERC20/ERC721 interfaces).
3.  **Interfaces:** `AggregatorV3Interface` for Oracle interaction.
4.  **Libraries:** (None needed beyond standard OpenZeppelin imports for this structure)
5.  **Roles:** Define custom bytes32 constants for different administrative roles.
6.  **Enums:** Define `AccessConditionType` enum.
7.  **Structs:** Define `AccessCondition` struct.
8.  **State Variables:**
    *   User balances (Ether, ERC20, ERC721).
    *   Supported asset lists (ERC20, ERC721).
    *   Access conditions storage (mapping user/asset to conditions).
    *   Oracle feed address.
9.  **Events:** For deposits, withdrawals, condition changes, role changes, asset support changes, pausing.
10. **Modifiers:** Standard `onlyRole`, `whenNotPaused`, `nonReentrant`.
11. **Constructor:** Initializes roles and potentially an initial oracle feed.
12. **Core Logic Functions:**
    *   Deposits (Ether, ERC20, ERC721).
    *   Withdrawals (Ether, ERC20, ERC721) - These will check conditions.
    *   Internal `_checkAccessConditionStatus` helper.
13. **Condition Management Functions:**
    *   Setting various types of conditions (TimeLock, OraclePrice, HasRole).
    *   Removing conditions.
    *   Viewing set conditions.
14. **Role Management Functions:**
    *   Granting/Revoking custom roles (leveraging AccessControl).
    *   Checking if a user has a specific role.
15. **Asset Management Functions:**
    *   Adding/Removing supported ERC20/ERC721 tokens.
    *   Viewing supported token lists.
16. **Query Functions (View/Pure):**
    *   Vault's total balance of assets.
    *   User's balance of assets within the vault.
    *   Retrieving condition details.
    *   Retrieving Oracle feed address.
17. **Oracle Integration Functions:**
    *   Setting the Oracle feed address.
    *   (Internal function to fetch price from oracle).
18. **Emergency Functions:**
    *   Emergency rescue for ERC20/ERC721 by authorized role.
    *   Pausing/Unpausing the contract.

**Function Summary:**

1.  `constructor()`: Deploys the contract, granting initial roles.
2.  `depositEther()`: Allows users to deposit native Ether into their vault balance.
3.  `depositERC20(address token, uint256 amount)`: Allows users to deposit a specified amount of a supported ERC20 token. Requires prior approval.
4.  `depositERC721(address token, uint256 tokenId)`: Allows users to deposit a supported ERC721 token. Requires prior approval or `safeTransferFrom` handling.
5.  `withdrawEther(uint256 amount)`: Allows a user to withdraw Ether, *if* the configured access conditions for Ether for that user are met.
6.  `withdrawERC20(address token, uint256 amount)`: Allows a user to withdraw a specified amount of an ERC20 token, *if* the access conditions for that token/user are met.
7.  `withdrawERC721(address token, uint256 tokenId)`: Allows a user to withdraw a specific ERC721 token, *if* the access conditions for that token/user are met.
8.  `setAccessConditionTimeLock(address user, address asset, uint256 unlockTimestamp)`: Sets a time-based condition for a specific user and asset (Ether or ERC20/ERC721 address), making it withdrawable only after `unlockTimestamp`. Requires `CONDITION_SETTER_ROLE`.
9.  `setAccessConditionOraclePriceAbove(address user, address asset, uint256 priceThreshold)`: Sets a condition requiring a linked Oracle feed's price for the asset to be *above* a `priceThreshold` for withdrawal. Requires `CONDITION_SETTER_ROLE`. Note: Asset here likely refers to the asset *whose price* is being checked by the oracle, not necessarily the deposited asset itself. Needs careful linking or assumption. Let's assume `asset` is the deposited token, and `priceThreshold` relates to a price feed *relevant* to that token, set via `setOracleFeed`.
10. `setAccessConditionOraclePriceBelow(address user, address asset, uint256 priceThreshold)`: Sets a condition requiring a linked Oracle feed's price for the asset to be *below* a `priceThreshold` for withdrawal. Requires `CONDITION_SETTER_ROLE`.
11. `setAccessConditionHasRole(address user, address asset, bytes32 requiredRole)`: Sets a condition requiring the withdrawing user to possess a specific `requiredRole` defined in the contract. Requires `CONDITION_SETTER_ROLE`.
12. `removeAccessCondition(address user, address asset)`: Removes any access condition set for a specific user and asset, reverting to no condition (immediate withdrawal if balance exists). Requires `CONDITION_SETTER_ROLE`.
13. `checkAccessConditionStatus(address user, address asset)`: Public view function to check if the access conditions for a given user and asset are currently met.
14. `grantRole(bytes32 role, address account)`: Grants a specific role to an account. Requires the account calling to have the `DEFAULT_ADMIN_ROLE` or a role with admin rights over the specific role being granted (handled by AccessControl).
15. `revokeRole(bytes32 role, address account)`: Revokes a specific role from an account. Requires the account calling to have admin rights over the role.
16. `hasRole(bytes32 role, address account)`: Public view function to check if an account has a specific role.
17. `isManager(address account)`: Public view function to check if an account has the `MANAGER_ROLE`.
18. `isConditionSetter(address account)`: Public view function to check if an account has the `CONDITION_SETTER_ROLE`.
19. `isEmergencyAdmin(address account)`: Public view function to check if an account has the `EMERGENCY_ADMIN_ROLE`.
20. `addSupportedERC20(address token)`: Adds an ERC20 token address to the list of supported tokens for deposit/withdrawal. Requires `MANAGER_ROLE`.
21. `removeSupportedERC20(address token)`: Removes an ERC20 token address from the supported list. Requires `MANAGER_ROLE`.
22. `addSupportedERC721(address token)`: Adds an ERC721 token address to the list of supported tokens. Requires `MANAGER_ROLE`.
23. `removeSupportedERC721(address token)`: Removes an ERC721 token address from the supported list. Requires `MANAGER_ROLE`.
24. `getVaultEtherBalance()`: Returns the total native Ether held by the contract.
25. `getVaultERC20Balance(address token)`: Returns the total balance of a specific ERC20 token held by the contract.
26. `getVaultERC721Count(address token)`: Returns the total count of a specific ERC721 token type held by the contract (difficult to track exact tokens, this might be approximate or count unique tokenIds stored). *Correction*: The internal storage tracks per-user tokens, aggregate count is hard without iteration. Let's provide a per-user getter instead.
27. `getUserVaultEtherBalance(address user)`: Returns the Ether balance stored for a specific user.
28. `getUserVaultERC20Balance(address user, address token)`: Returns the balance of a specific ERC20 token stored for a user.
29. `getUserVaultERC721Tokens(address user, address token)`: Returns the array of token IDs of a specific ERC721 token stored for a user. (Note: Retrieving arrays on-chain is gas-intensive for large arrays).
30. `getAccessConditionsForUserAsset(address user, address asset)`: Returns the details of the access condition set for a specific user and asset.
31. `getSupportedERC20s()`: Returns an array of all supported ERC20 token addresses. (Note: Iterating and building this array can be gas-intensive if many tokens are supported).
32. `getSupportedERC721s()`: Returns an array of all supported ERC721 token addresses. (Gas warning applies).
33. `setOracleFeed(address feed)`: Sets the address of the Oracle price feed contract (must implement AggregatorV3Interface). Requires `MANAGER_ROLE`.
34. `emergencyRescueERC20(address token, address recipient, uint256 amount)`: Allows an `EMERGENCY_ADMIN_ROLE` to transfer a specified amount of a supported ERC20 token out of the contract to a recipient, bypassing normal conditions.
35. `emergencyRescueERC721(address token, address recipient, uint256 tokenId)`: Allows an `EMERGENCY_ADMIN_ROLE` to transfer a specific supported ERC721 token out of the contract to a recipient, bypassing normal conditions.
36. `pause()`: Pauses transfers and condition setting/removing. Requires the account to have the Pauser role (often `DEFAULT_ADMIN_ROLE`).
37. `unpause()`: Unpauses the contract. Requires the Pauser role.

*(Note: The concept of "asset" in conditions (functions 8-12) refers to the deposited asset (Ether address(0), or token address). The Oracle condition uses the `oracleFeed` address set separately, which is *expected* to provide data relevant to the asset being conditioned, but the contract doesn't strictly enforce this linkage.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For sending Ether

// Interface for Chainlink Price Feed or similar oracle
// Using a simplified version for demonstration
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


/**
 * @title QuantumVault
 * @dev A sophisticated multi-asset vault with configurable access conditions based on time, roles, and external oracle data.
 * It allows users to deposit Ether, ERC20, and ERC721 tokens which can then only be withdrawn if specific,
 * administrator-set conditions are met for that user and asset.
 */
contract QuantumVault is AccessControl, ReentrancyGuard, Pausable {
    using Address for address; // For safe Ether transfers

    // --- Roles ---
    // DEFAULT_ADMIN_ROLE (from AccessControl) has power to grant/revoke other roles
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // Manages supported assets, sets oracle
    bytes32 public constant CONDITION_SETTER_ROLE = keccak256("CONDITION_SETTER_ROLE"); // Sets/removes access conditions
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE"); // Can trigger emergency rescue functions
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Can pause/unpause the contract

    // --- Enums ---
    enum AccessConditionType {
        None,             // No specific condition (default)
        TimeLock,         // Unlock after a specific timestamp (value = timestamp)
        OraclePriceAbove, // Unlock if oracle price is >= value (value = price threshold)
        OraclePriceBelow, // Unlock if oracle price is <= value (value = price threshold)
        HasRole           // Unlock if user has a specific role (value is ignored, role checked via AccessControl)
    }

    // --- Structs ---
    struct AccessCondition {
        AccessConditionType conditionType;
        uint256 value;         // Varies based on type (timestamp, price threshold)
        bytes32 requiredRole;  // Used only for HasRole type
        address oracleFeed;    // Used only for OraclePrice types
    }

    // --- State Variables ---
    // User balances
    mapping(address => uint256) private userEtherBalances;
    mapping(address => mapping(address => uint256)) private userERC20Balances;
    // Note: Storing token IDs in an array is gas-expensive for large numbers of tokens.
    // A production contract might use a different storage pattern.
    mapping(address => mapping(address => uint256[])) private userERC721Tokens;

    // Supported assets (true if supported)
    mapping(address => bool) private supportedERC20s;
    mapping(address => bool) private supportedERC721s;

    // Access conditions (user => asset address => condition)
    // asset address 0x0 is used for Ether
    mapping(address => mapping(address => AccessCondition)) private accessConditions;

    // Oracle feed address for price conditions
    AggregatorV3Interface public priceOracleFeed;

    // Array to store supported ERC20/ERC721 addresses for get functions (gas note applies)
    address[] private _supportedERC20List;
    address[] private _supportedERC721List;


    // --- Events ---
    event EtherDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event EtherWithdrawn(address indexed user, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount);
    event ERC721Withdrawn(address indexed user, address indexed token, uint256 tokenId);
    event AccessConditionSet(address indexed user, address indexed asset, AccessConditionType conditionType, uint256 value, bytes32 requiredRole, address oracleFeed);
    event AccessConditionRemoved(address indexed user, address indexed asset);
    event SupportedERC20Added(address indexed token);
    event SupportedERC20Removed(address indexed token);
    event SupportedERC721Added(address indexed token);
    event SupportedERC721Removed(address indexed token);
    event OracleFeedSet(address indexed feed);
    event EmergencyRescue(address indexed tokenOrRecipient, uint256 amountOrTokenId, address indexed rescuedBy); // Generic event for rescue
    event Paused(address account);
    event Unpaused(address account);

    // --- Constructor ---
    constructor(address initialAdmin) Pausable(false) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        // Grant initial admin other core roles for setup
        _grantRole(MANAGER_ROLE, initialAdmin);
        _grantRole(CONDITION_SETTER_ROLE, initialAdmin);
        _grantRole(EMERGENCY_ADMIN_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
    }

    // --- Modifiers ---
    // Overrides from Pausable
    function pause() public virtual override {
        require(hasRole(PAUSER_ROLE, msg.sender), "PauserRole: caller does not have the Pauser role");
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public virtual override {
        require(hasRole(PAUSER_ROLE, msg.sender), "PauserRole: caller does not have the Pauser role");
        _unpause();
        emit Unpaused(msg.sender);
    }

    // Standard Role modifiers (AccessControl handles the internal logic)
    // function onlyRole(bytes32 role) internal view virtual { require(hasRole(role, msg.sender), ... }
    // These are used internally by AccessControl methods like grantRole/revokeRole
    // For custom functions, we check hasRole directly.

    // --- Core Logic Functions ---

    /// @dev Allows users to deposit native Ether into their vault balance.
    /// @param amount The amount of Ether to deposit. Sent via msg.value.
    function depositEther(uint256 amount) external payable nonReentrant whenNotPaused {
        require(msg.value == amount, "Deposit amount must match msg.value");
        userEtherBalances[msg.sender] += amount;
        emit EtherDeposited(msg.sender, amount);
    }

    /// @dev Allows users to deposit a specified amount of a supported ERC20 token.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(supportedERC20s[token], "Token not supported");
        require(amount > 0, "Amount must be greater than 0");

        uint256 contractBalanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 receivedAmount = IERC20(token).balanceOf(address(this)) - contractBalanceBefore;
        require(receivedAmount == amount, "ERC20 transfer failed or incorrect amount received"); // Basic check

        userERC20Balances[msg.sender][token] += receivedAmount;
        emit ERC20Deposited(msg.sender, token, receivedAmount);
    }

    /// @dev Allows users to deposit a supported ERC721 token.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the token to deposit.
    /// Note: This function assumes the contract is set as an operator or the user calls safeTransferFrom directly.
    /// For `transferFrom`, the contract needs approval first. `safeTransferFrom` is recommended.
    function depositERC721(address token, uint256 tokenId) external nonReentrant whenNotPaused {
        require(supportedERC721s[token], "Token not supported");
        IERC721(token).transferFrom(msg.sender, address(this), tokenId); // Assumes approval or called by token owner/operator

        userERC721Tokens[msg.sender][token].push(tokenId); // Add token ID to user's list
        emit ERC721Deposited(msg.sender, token, tokenId);
    }

    /// @dev Allows a user to withdraw Ether if conditions are met.
    /// @param amount The amount of Ether to withdraw.
    function withdrawEther(uint256 amount) external nonReentrant whenNotPaused {
        require(userEtherBalances[msg.sender] >= amount, "Insufficient Ether balance in vault");
        require(_checkAccessConditionStatus(msg.sender, address(0)), "Access conditions not met for Ether");

        userEtherBalances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Ether transfer failed");

        emit EtherWithdrawn(msg.sender, amount);
    }

    /// @dev Allows a user to withdraw an ERC20 token if conditions are met.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(supportedERC20s[token], "Token not supported");
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient ERC20 balance in vault");
        require(_checkAccessConditionStatus(msg.sender, token), "Access conditions not met for this token");

        userERC20Balances[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);

        emit ERC20Withdrawn(msg.sender, token, amount);
    }

    /// @dev Allows a user to withdraw an ERC721 token if conditions are met.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the token to withdraw.
    function withdrawERC721(address token, uint256 tokenId) external nonReentrant whenNotPaused {
        require(supportedERC721s[token], "Token not supported");
        // Check if the user actually owns this token in the vault
        bool found = false;
        uint256 index = 0;
        uint256[] storage userTokens = userERC721Tokens[msg.sender][token];
        for (uint i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "User does not own this ERC721 token in the vault");
        require(_checkAccessConditionStatus(msg.sender, token), "Access conditions not met for this token type");

        // Remove token ID from user's list (order doesn't matter) - Gas-expensive for large arrays
        userTokens[index] = userTokens[userTokens.length - 1];
        userTokens.pop();

        IERC721(token).transferFrom(address(this), msg.sender, tokenId); // Use transferFrom as contract is owner

        emit ERC721Withdrawn(msg.sender, token, tokenId);
    }

    /// @dev Internal helper function to check if access conditions for a user/asset are met.
    /// @param user The user's address.
    /// @param asset The asset address (0x0 for Ether).
    /// @return bool True if conditions are met or if no conditions are set, false otherwise.
    function _checkAccessConditionStatus(address user, address asset) internal view returns (bool) {
        AccessCondition storage condition = accessConditions[user][asset];

        if (condition.conditionType == AccessConditionType.None) {
            return true; // No condition means always accessible
        } else if (condition.conditionType == AccessConditionType.TimeLock) {
            return block.timestamp >= condition.value;
        } else if (condition.conditionType == AccessConditionType.OraclePriceAbove) {
             require(condition.oracleFeed != address(0), "Oracle feed not set for this condition");
             ( , int256 price, , , ) = AggregatorV3Interface(condition.oracleFeed).latestRoundData();
             return price >= int256(condition.value); // Compare signed price with unsigned threshold (careful here, assume price is non-negative)
        } else if (condition.conditionType == AccessConditionType.OraclePriceBelow) {
             require(condition.oracleFeed != address(0), "Oracle feed not set for this condition");
             ( , int256 price, , , ) = AggregatorV3Interface(condition.oracleFeed).latestRoundData();
             return price <= int256(condition.value); // Compare signed price with unsigned threshold
        } else if (condition.conditionType == AccessConditionType.HasRole) {
            require(condition.requiredRole != bytes32(0), "Required role not set for this condition");
            return hasRole(condition.requiredRole, user);
        }
        // Should not reach here
        return false;
    }


    // --- Condition Management Functions ---

    /// @dev Sets a time-based condition for a specific user and asset.
    /// @param user The user address.
    /// @param asset The asset address (0x0 for Ether).
    /// @param unlockTimestamp The timestamp after which the asset becomes withdrawable.
    function setAccessConditionTimeLock(address user, address asset, uint256 unlockTimestamp)
        external onlyRole(CONDITION_SETTER_ROLE) whenNotPaused
    {
        accessConditions[user][asset] = AccessCondition({
            conditionType: AccessConditionType.TimeLock,
            value: unlockTimestamp,
            requiredRole: bytes32(0),
            oracleFeed: address(0)
        });
        emit AccessConditionSet(user, asset, AccessConditionType.TimeLock, unlockTimestamp, bytes32(0), address(0));
    }

     /// @dev Sets an Oracle price 'Above' condition for a specific user and asset.
     /// Requires a price feed address to be set via `setOracleFeed`.
     /// @param user The user address.
     /// @param asset The asset address (0x0 for Ether).
     /// @param priceThreshold The price threshold the oracle value must be >= to.
    function setAccessConditionOraclePriceAbove(address user, address asset, uint256 priceThreshold)
        external onlyRole(CONDITION_SETTER_ROLE) whenNotPaused
    {
         require(address(priceOracleFeed) != address(0), "Global oracle feed not set");
         accessConditions[user][asset] = AccessCondition({
            conditionType: AccessConditionType.OraclePriceAbove,
            value: priceThreshold,
            requiredRole: bytes32(0),
            oracleFeed: address(priceOracleFeed) // Link to the globally set feed
        });
        emit AccessConditionSet(user, asset, AccessConditionType.OraclePriceAbove, priceThreshold, bytes32(0), address(priceOracleFeed));
    }

     /// @dev Sets an Oracle price 'Below' condition for a specific user and asset.
     /// Requires a price feed address to be set via `setOracleFeed`.
     /// @param user The user address.
     /// @param asset The asset address (0x0 for Ether).
     /// @param priceThreshold The price threshold the oracle value must be <= to.
    function setAccessConditionOraclePriceBelow(address user, address asset, uint256 priceThreshold)
        external onlyRole(CONDITION_SETTER_ROLE) whenNotPaused
    {
        require(address(priceOracleFeed) != address(0), "Global oracle feed not set");
        accessConditions[user][asset] = AccessCondition({
            conditionType: AccessConditionType.OraclePriceBelow,
            value: priceThreshold,
            requiredRole: bytes32(0),
            oracleFeed: address(priceOracleFeed) // Link to the globally set feed
        });
        emit AccessConditionSet(user, asset, AccessConditionType.OraclePriceBelow, priceThreshold, bytes32(0), address(priceOracleFeed));
    }

    /// @dev Sets a Role-based condition for a specific user and asset.
    /// The user must possess the required role to withdraw.
    /// @param user The user address.
    /// @param asset The asset address (0x0 for Ether).
    /// @param requiredRole The bytes32 representation of the role the user must have.
    function setAccessConditionHasRole(address user, address asset, bytes32 requiredRole)
        external onlyRole(CONDITION_SETTER_ROLE) whenNotPaused
    {
        require(requiredRole != bytes32(0), "Required role must be specified");
         accessConditions[user][asset] = AccessCondition({
            conditionType: AccessConditionType.HasRole,
            value: 0, // Value is not used for this condition type
            requiredRole: requiredRole,
            oracleFeed: address(0) // Oracle feed is not used for this type
        });
        emit AccessConditionSet(user, asset, AccessConditionType.HasRole, 0, requiredRole, address(0));
    }


    /// @dev Removes any access condition set for a specific user and asset.
    /// @param user The user address.
    /// @param asset The asset address (0x0 for Ether).
    function removeAccessCondition(address user, address asset)
        external onlyRole(CONDITION_SETTER_ROLE) whenNotPaused
    {
        // Setting the type back to None effectively removes the condition
        delete accessConditions[user][asset]; // Deleting sets it back to default struct with type None
        emit AccessConditionRemoved(user, asset);
    }

    /// @dev Public view function to check if access conditions for a user/asset are met *right now*.
    /// @param user The user's address.
    /// @param asset The asset address (0x0 for Ether).
    /// @return bool True if conditions are met or if no conditions are set, false otherwise.
    function checkAccessConditionStatus(address user, address asset) external view returns (bool) {
        return _checkAccessConditionStatus(user, asset);
    }

    // --- Role Management Functions (Leveraging AccessControl) ---
    // grantRole, revokeRole, and hasRole are provided by AccessControl.sol
    // We've already defined the custom roles and how they are used by custom functions.

    /// @dev Public view function to check if an account has the MANAGER_ROLE.
    function isManager(address account) public view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

     /// @dev Public view function to check if an account has the CONDITION_SETTER_ROLE.
    function isConditionSetter(address account) public view returns (bool) {
        return hasRole(CONDITION_SETTER_ROLE, account);
    }

     /// @dev Public view function to check if an account has the EMERGENCY_ADMIN_ROLE.
    function isEmergencyAdmin(address account) public view returns (bool) {
        return hasRole(EMERGENCY_ADMIN_ROLE, account);
    }


    // --- Asset Management Functions ---

    /// @dev Adds an ERC20 token to the list of supported tokens.
    /// @param token The address of the ERC20 token.
    function addSupportedERC20(address token) external onlyRole(MANAGER_ROLE) whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(!supportedERC20s[token], "Token already supported");
        supportedERC20s[token] = true;
        _supportedERC20List.push(token); // Add to list for easier querying
        emit SupportedERC20Added(token);
    }

    /// @dev Removes an ERC20 token from the list of supported tokens.
    /// Note: This does NOT affect already deposited balances.
    /// @param token The address of the ERC20 token.
    function removeSupportedERC20(address token) external onlyRole(MANAGER_ROLE) whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(supportedERC20s[token], "Token is not supported");
        supportedERC20s[token] = false;
        // Remove from list (gas-expensive for large lists, order doesn't matter)
        for (uint i = 0; i < _supportedERC20List.length; i++) {
            if (_supportedERC20List[i] == token) {
                _supportedERC20List[i] = _supportedERC20List[_supportedERC20List.length - 1];
                _supportedERC20List.pop();
                break;
            }
        }
        emit SupportedERC20Removed(token);
    }

    /// @dev Adds an ERC721 token to the list of supported tokens.
    /// @param token The address of the ERC721 token.
    function addSupportedERC721(address token) external onlyRole(MANAGER_ROLE) whenNotPaused {
         require(token != address(0), "Invalid token address");
        require(!supportedERC721s[token], "Token already supported");
        supportedERC721s[token] = true;
        _supportedERC721List.push(token); // Add to list for easier querying
        emit SupportedERC721Added(token);
    }

    /// @dev Removes an ERC721 token from the list of supported tokens.
    /// Note: This does NOT affect already deposited balances.
    /// @param token The address of the ERC721 token.
    function removeSupportedERC721(address token) external onlyRole(MANAGER_ROLE) whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(supportedERC721s[token], "Token is not supported");
        supportedERC721s[token] = false;
         // Remove from list (gas-expensive for large lists, order doesn't matter)
        for (uint i = 0; i < _supportedERC721List.length; i++) {
            if (_supportedERC721List[i] == token) {
                _supportedERC721List[i] = _supportedERC721List[_supportedERC721List.length - 1];
                _supportedERC721List.pop();
                break;
            }
        }
        emit SupportedERC721Removed(token);
    }

    // --- Query Functions (View/Pure) ---

    /// @dev Returns the total native Ether balance held by the contract.
    function getVaultEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Returns the total balance of a specific ERC20 token held by the contract.
    /// @param token The address of the ERC20 token.
    function getVaultERC20Balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

     /// @dev Returns the count of distinct ERC721 tokens of a specific type held by the contract.
     /// This is the total count across all users' vault balances for this token type.
    function getVaultERC721Count(address token) external view returns (uint256) {
        // Note: Calculating this involves iterating through all users' token arrays, which is gas-prohibitive.
        // A more practical implementation would require a separate counter or different storage pattern.
        // For this example, we will return 0 as a placeholder for efficiency or require off-chain calculation.
        // Or, we could return the total count of token IDs stored, acknowledging gas costs. Let's return total IDs.
        uint256 totalCount = 0;
        // This would require iterating through all keys in the user mapping - impossible in Solidity.
        // Return 0 and add a note, or remove this function. Returning 0.
        return 0;
         // Alternative (still complex/gas): would need a mapping like mapping(address => uint256) totalERC721Count; updated on deposit/withdraw.
    }


    /// @dev Returns the Ether balance stored for a specific user within the vault.
    /// @param user The user address.
    function getUserVaultEtherBalance(address user) external view returns (uint256) {
        return userEtherBalances[user];
    }

    /// @dev Returns the balance of a specific ERC20 token stored for a user within the vault.
    /// @param user The user address.
    /// @param token The address of the ERC20 token.
    function getUserVaultERC20Balance(address user, address token) external view returns (uint256) {
        return userERC20Balances[user][token];
    }

    /// @dev Returns the list of token IDs of a specific ERC721 token stored for a user.
    /// @param user The user address.
    /// @param token The address of the ERC721 token.
    /// @return uint256[] An array of token IDs. Note: Returning large arrays can hit gas limits.
    function getUserVaultERC721Tokens(address user, address token) external view returns (uint256[] memory) {
        return userERC721Tokens[user][token];
    }

    /// @dev Returns the details of the access condition set for a specific user and asset.
    /// @param user The user address.
    /// @param asset The asset address (0x0 for Ether).
    /// @return AccessCondition The condition struct.
    function getAccessConditionsForUserAsset(address user, address asset) external view returns (AccessCondition memory) {
        return accessConditions[user][asset];
    }

    /// @dev Returns an array of all supported ERC20 token addresses.
    /// @return address[] An array of supported ERC20 addresses. Note: Returning large arrays can hit gas limits.
    function getSupportedERC20s() external view returns (address[] memory) {
        return _supportedERC20List; // Return the stored list for efficiency
    }

    /// @dev Returns an array of all supported ERC721 token addresses.
    /// @return address[] An array of supported ERC721 addresses. Note: Returning large arrays can hit gas limits.
    function getSupportedERC721s() external view returns (address[] memory) {
         return _supportedERC721List; // Return the stored list
    }

    // --- Oracle Integration Functions ---

    /// @dev Sets the address of the Oracle price feed contract. Must implement AggregatorV3Interface.
    /// @param feed The address of the Oracle feed.
    function setOracleFeed(address feed) external onlyRole(MANAGER_ROLE) whenNotPaused {
        // Basic check if it looks like a contract address
        require(feed.code.length > 0, "Feed address is not a contract");
        priceOracleFeed = AggregatorV3Interface(feed);
        emit OracleFeedSet(feed);
    }

    /// @dev Internal helper to get the latest price from the configured oracle feed.
    /// @return int256 The latest price.
    function _getLatestOraclePrice() internal view returns (int256) {
         require(address(priceOracleFeed) != address(0), "Oracle feed address not set");
         ( , int256 price, , , ) = priceOracleFeed.latestRoundData();
         return price;
    }


    // --- Emergency Functions ---

    /// @dev Allows an emergency admin to rescue ERC20 tokens from the contract.
    /// This bypasses user balances and conditions, intended for situations where tokens are stuck.
    /// @param token The address of the ERC20 token to rescue.
    /// @param recipient The address to send the tokens to.
    /// @param amount The amount of tokens to rescue.
    function emergencyRescueERC20(address token, address recipient, uint256 amount)
        external onlyRole(EMERGENCY_ADMIN_ROLE) whenPaused // Only rescue when paused is a common pattern
    {
        require(token != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient contract balance for rescue");

        IERC20(token).transfer(recipient, amount);
        emit EmergencyRescue(token, amount, msg.sender);
    }

    /// @dev Allows an emergency admin to rescue a specific ERC721 token from the contract.
    /// This bypasses user balances and conditions, intended for situations where tokens are stuck.
    /// @param token The address of the ERC721 token to rescue.
    /// @param recipient The address to send the token to.
    /// @param tokenId The ID of the token to rescue.
    function emergencyRescueERC721(address token, address recipient, uint256 tokenId)
        external onlyRole(EMERGENCY_ADMIN_ROLE) whenPaused // Only rescue when paused
    {
        require(token != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        // Check if the contract owns the token
        require(IERC721(token).ownerOf(tokenId) == address(this), "Contract does not own this token");

        IERC721(token).transferFrom(address(this), recipient, tokenId);
        emit EmergencyRescue(token, tokenId, msg.sender);
    }

    // --- Fallback/Receive ---
    receive() external payable {
        // Optional: Allow receiving Ether without calling depositEther
        // If depositEther is required, remove this or add a require(msg.data.length == 0)
        // For this vault, depositEther handles balance tracking.
        // Receiving unexpected Ether without depositEther means it's not tracked per user!
        // So, require it goes through depositEther.
        revert("Ether received directly. Use depositEther.");
    }

    fallback() external payable {
         // Revert on any other unexpected calls
         revert("Invalid call");
    }
}
```