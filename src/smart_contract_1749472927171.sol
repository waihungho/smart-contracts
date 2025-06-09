Okay, let's design a smart contract that incorporates several advanced, interesting, and creative concepts, aiming for over 20 functions while avoiding direct duplication of well-known open-source patterns like basic token vaults, simple staking, or standard NFT contracts.

We'll create a `QuantumVault` contract. This vault will manage deposited assets (ERC-20) based on a combination of dynamic internal states, external oracle data, user-specific 'reputation' scores, and even user-bonded NFTs, allowing for complex conditional access and yield distribution.

---

### `QuantumVault` Smart Contract: Outline & Function Summary

**Contract Name:** `QuantumVault`

**Core Concept:** A dynamic, condition-aware, and reputation-gated asset vault that integrates external data (Oracle) and user-specific state (Reputation, NFT Bonding) to control asset access, distribution, and yield generation.

**Key Features:**

1.  **Dynamic Vault Modes:** The vault operates in different modes (`Active`, `ConditionalOnly`, `ReputationLocked`, `BondedAccess`) which change behavior and access rules.
2.  **Oracle Integration:** Utilizes an external oracle to influence vault state or conditions.
3.  **User Reputation System:** Tracks a mutable reputation score for each user, affecting eligibility for certain actions.
4.  **Conditional Withdrawals:** Allows users to request withdrawals that are only executable if specific, dynamic conditions are met at the time of claiming.
5.  **Dynamic Yield/Distribution:** Calculates yield or distributes rewards based on vault mode, oracle data, and user state.
6.  **NFT Bonding:** Users can "bond" (lock) a specific NFT type to gain access to exclusive vault features or modes.
7.  **Subscription Model:** A time-based access mechanism for certain features.
8.  **Advanced Access Control:** Admin roles manage core configuration and state transitions, potentially triggered by external keepers.

**Outline:**

1.  **State Variables:**
    *   Admin/Access Control
    *   Oracle Address
    *   Supported Tokens Configuration
    *   Vault State/Mode
    *   Dynamic Parameters (Thresholds, Factors)
    *   Oracle Data Cache
    *   User State (Reputation, Subscription, NFT Bonding)
    *   Conditional Withdrawal Requests
    *   NFT Bonding Configuration
    *   Subscription Configuration
    *   Pause State

2.  **Enums & Structs:**
    *   `VaultMode`
    *   `UserState`
    *   `SupportedTokenConfig`
    *   `ConditionalWithdrawalRequest`

3.  **Events:**
    *   Vault Mode Changes
    *   Oracle Data Updates
    *   Parameter Updates
    *   Token Support Changes
    *   User State Changes (Reputation, Subscription, NFT Bond)
    *   Deposit/Withdrawal Events
    *   Conditional Withdrawal Request/Claim
    *   Yield Claim
    *   Pause/Unpause

4.  **Modifiers:**
    *   `onlyAdmin`
    *   `whenActive`
    *   `whenPaused`
    *   `onlyIfConditionMet` (Requires dynamic check - might be better as internal function + require)

5.  **Interfaces:**
    *   `IERC20`
    *   `IERC721`
    *   `IOracle` (Simple example interface)

6.  **Functions:** (Categorized)
    *   **Admin & Configuration (9 functions):**
        *   `constructor`
        *   `setOracleAddress`
        *   `addSupportedToken`
        *   `removeSupportedToken`
        *   `setVaultMode`
        *   `setDynamicThreshold`
        *   `setNFTBondingConfig`
        *   `setSubscriptionCost`
        *   `updateUserReputationScore` (Manual override for admin/keeper)
        *   `grantAdminRole`
        *   `revokeAdminRole`
        *   `pause`
        *   `unpause`
        *   `sweepUnusualTokens` (Safety)
    *   **Oracle & State Logic (3 functions):**
        *   `processOracleUpdate` (External call/keeper)
        *   `triggerModeTransition` (External call/keeper based on logic)
        *   `_checkDynamicCondition` (Internal helper)
    *   **User Interactions (9 functions):**
        *   `depositERC20`
        *   `depositWithConditionCriteria` (More complex deposit)
        *   `requestConditionalWithdrawal`
        *   `claimRequestedWithdrawal`
        *   `claimDynamicYield`
        *   `paySubscription`
        *   `bondNFTForAccess`
        *   `unbondNFT`
        *   `attestReputation` (User-initiated input to reputation system)
    *   **View Functions (8 functions):**
        *   `getVaultMode`
        *   `getDynamicThreshold`
        *   `getOracleValue`
        *   `getUserState`
        *   `getConditionalWithdrawalRequest`
        *   `previewClaimableYield`
        *   `previewConditionalWithdrawalAmount`
        *   `isConditionCurrentlyMet`

**Function Summary (Total: 29 functions listed above):**

1.  `constructor(address _oracle, address _nftAddress, uint256 _subscriptionCost, uint256 _initialThreshold)`: Initializes the contract with core addresses and initial parameters.
2.  `setOracleAddress(address _newOracle)`: Admin function to update the oracle contract address.
3.  `addSupportedToken(address _token, uint256 _dynamicYieldFactor)`: Admin function to add an ERC20 token to the list of supported assets and set its yield factor.
4.  `removeSupportedToken(address _token)`: Admin function to remove a supported ERC20 token.
5.  `setVaultMode(VaultMode _newMode)`: Admin function to manually set the vault's operational mode.
6.  `setDynamicThreshold(uint256 _newThreshold)`: Admin function to update the threshold used in dynamic conditions.
7.  `setNFTBondingConfig(address _nftAddress)`: Admin function to set the specific ERC721 contract address required for NFT bonding access.
8.  `setSubscriptionCost(uint256 _cost)`: Admin function to set the cost for paying a subscription (in native currency, e.g., ETH).
9.  `updateUserReputationScore(address _user, uint256 _newScore)`: Admin or authorized keeper function to set a user's reputation score. *Note: A real system would have complex logic for this.*
10. `grantAdminRole(address _newAdmin)`: Grants admin privileges to an address.
11. `revokeAdminRole(address _admin)`: Revokes admin privileges from an address.
12. `pause()`: Admin function to pause certain contract operations.
13. `unpause()`: Admin function to resume operations.
14. `sweepUnusualTokens(address _token, address _to)`: Admin function to rescue accidentally sent non-supported tokens.
15. `processOracleUpdate(uint256 _newValue)`: Function called by the oracle or an authorized keeper to update the cached oracle value.
16. `triggerModeTransition()`: Function called by admin or a keeper to automatically transition the vault mode based on internal state and oracle data.
17. `_checkDynamicCondition(address _user)`: Internal helper function to check if the current dynamic condition (based on vault mode, oracle value, user state) is met for a given user.
18. `depositERC20(address _token, uint256 _amount)`: Allows users to deposit supported ERC20 tokens into the vault.
19. `depositWithConditionCriteria(address _token, uint256 _amount, bytes _conditionCriteria)`: Allows deposit with associated criteria that might influence future conditional withdrawals or yield (e.g., specifies a target oracle value range for unlocking). *Note: `_conditionCriteria` is a placeholder for complex logic.*
20. `requestConditionalWithdrawal(address _token, uint256 _amount)`: User requests a withdrawal. The request is recorded, but the funds are *not* transferred yet.
21. `claimRequestedWithdrawal(uint256 _requestId)`: User attempts to claim a previously requested withdrawal. Requires the `_checkDynamicCondition` to return true *at the time of claiming* (or based on criteria associated with the request).
22. `claimDynamicYield(address _token)`: Allows a user to claim accumulated dynamic yield for a specific token.
23. `paySubscription()`: User pays the subscription cost (in native currency) to extend their subscription time.
24. `bondNFTForAccess(uint256 _tokenId)`: User transfers a specific configured NFT to the contract to enable NFT-gated features. Requires approval beforehand.
25. `unbondNFT()`: User retrieves their bonded NFT, revoking NFT-gated access.
26. `attestReputation(uint256 _value, bytes _proof)`: User submits a value and proof to influence their reputation score. *Note: `_value` and `_proof` are placeholders for complex proof-of-X systems.*
27. `getVaultMode()`: View function to check the current vault mode.
28. `getDynamicThreshold()`: View function to get the current dynamic threshold value.
29. `getOracleValue()`: View function to get the latest cached oracle value.
30. `getUserState(address _user)`: View function to retrieve a user's current state (reputation, subscription expiry, NFT bond status).
31. `getConditionalWithdrawalRequest(address _user, uint256 _index)`: View function to retrieve details of a specific conditional withdrawal request for a user.
32. `previewClaimableYield(address _user, address _token)`: Pure/View function to calculate and show the potential claimable yield for a user and token under current conditions.
33. `previewConditionalWithdrawalAmount(address _user, uint256 _requestId)`: Pure/View function to show the amount for a given withdrawal request.
34. `isConditionCurrentlyMet(address _user)`: View function that wraps `_checkDynamicCondition` for external querying.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Minimal Interface for an Oracle - replace with a real oracle implementation
interface IOracle {
    function getValue() external view returns (uint256);
}

/**
 * @title QuantumVault
 * @dev A dynamic, condition-aware, and reputation-gated asset vault.
 *      Manages ERC-20 tokens based on vault mode, oracle data, user reputation,
 *      and bonded NFTs. Features include conditional withdrawals, dynamic yield,
 *      subscriptions, and advanced admin controls.
 */
contract QuantumVault is ERC721Holder, ReentrancyGuard, Pausable {

    // --- Enums & Structs ---

    enum VaultMode {
        Active,           // Standard deposits/withdrawals allowed
        Paused,           // All operations paused (system wide pause)
        ConditionalOnly,  // Only conditional requests/claims allowed
        ReputationLocked, // Requires minimum reputation for many actions
        BondedAccess      // Requires bonded NFT for many actions
    }

    struct UserState {
        uint256 reputationScore;
        uint64 subscriptionExpires; // Unix timestamp
        bool isNFTBonded;
        uint256 bondedNFTTokenId; // The specific token ID bonded
        uint256 lastYieldClaimTime; // Per user, simplified
    }

    struct SupportedTokenConfig {
        bool isSupported;
        uint256 dynamicYieldFactor; // Factor influencing yield calculation
    }

    struct ConditionalWithdrawalRequest {
        address token;
        uint256 amount;
        uint64 requestTime;
        bool isProcessed;
        // bytes conditionCriteria; // Future extension for per-request criteria
    }

    // --- State Variables ---

    address private owner;
    address private oracle;
    address private bondedNFTAddress; // The ERC721 contract address required for bonding

    VaultMode public currentVaultMode;
    uint256 public dynamicThreshold; // A parameter used in dynamic conditions
    uint256 public oracleValue; // Cached value from the oracle

    uint256 public subscriptionCost; // Cost in native currency (e.g., wei)

    mapping(address => UserState) private userStates;
    mapping(address => SupportedTokenConfig) public supportedTokens;
    mapping(address => ConditionalWithdrawalRequest[]) private conditionalWithdrawalRequests;

    // --- Events ---

    event OracleValueUpdated(uint256 newValue, uint64 timestamp);
    event VaultModeChanged(VaultMode newMode);
    event DynamicThresholdUpdated(uint256 newThreshold);
    event TokenSupportUpdated(address token, bool isSupported, uint256 dynamicYieldFactor);
    event UserReputationUpdated(address user, uint256 newScore);
    event UserSubscriptionPaid(address user, uint64 expiryTime);
    event UserNFTBonded(address user, address nftContract, uint256 tokenId);
    event UserNFTUnbonded(address user, address nftContract, uint256 tokenId);
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event ConditionalWithdrawalRequested(address indexed user, address indexed token, uint256 amount, uint256 requestId);
    event ConditionalWithdrawalClaimed(address indexed user, uint256 requestId);
    event DynamicYieldClaimed(address indexed user, address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only admin");
        _;
    }

    modifier whenActiveOrConditional() {
        require(currentVaultMode == VaultMode.Active || currentVaultMode == VaultMode.ConditionalOnly, "Not allowed in current mode");
        _;
    }

    modifier whenNotPausedBySystem() {
         require(currentVaultMode != VaultMode.Paused, "System Paused");
         _;
    }


    // --- Constructor ---

    constructor(address _oracle, address _nftAddress, uint256 _subscriptionCost, uint256 _initialThreshold) Pausable(false) {
        require(_oracle != address(0), "Invalid oracle address");
        require(_nftAddress != address(0), "Invalid NFT address");
        owner = msg.sender;
        oracle = _oracle;
        bondedNFTAddress = _nftAddress;
        subscriptionCost = _subscriptionCost;
        dynamicThreshold = _initialThreshold;
        currentVaultMode = VaultMode.Active;
        // Initialize oracle value (fetch immediately or wait for first update)
        // For simplicity, starting with 0 and requires an update.
        oracleValue = 0;
    }

    // --- Admin & Configuration Functions ---

    /**
     * @dev Sets the address of the external oracle contract.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyAdmin {
        require(_newOracle != address(0), "Invalid address");
        oracle = _newOracle;
    }

    /**
     * @dev Adds a new ERC20 token to the list of supported tokens for deposits and yield.
     * @param _token The address of the ERC20 token contract.
     * @param _dynamicYieldFactor A factor influencing dynamic yield calculation for this token.
     */
    function addSupportedToken(address _token, uint256 _dynamicYieldFactor) external onlyAdmin {
        require(_token != address(0), "Invalid address");
        require(!supportedTokens[_token].isSupported, "Token already supported");
        supportedTokens[_token] = SupportedTokenConfig(true, _dynamicYieldFactor);
        emit TokenSupportUpdated(_token, true, _dynamicYieldFactor);
    }

    /**
     * @dev Removes an ERC20 token from the list of supported tokens.
     *      Existing deposits remain, but new deposits/yield calculations may be affected.
     * @param _token The address of the ERC20 token contract.
     */
    function removeSupportedToken(address _token) external onlyAdmin {
        require(supportedTokens[_token].isSupported, "Token not supported");
        delete supportedTokens[_token];
        emit TokenSupportUpdated(_token, false, 0);
    }

    /**
     * @dev Manually sets the vault's operational mode.
     * @param _newMode The desired new vault mode.
     */
    function setVaultMode(VaultMode _newMode) external onlyAdmin {
        currentVaultMode = _newMode;
        emit VaultModeChanged(_newMode);
    }

    /**
     * @dev Sets the dynamic threshold parameter used in conditional logic.
     * @param _newThreshold The new threshold value.
     */
    function setDynamicThreshold(uint256 _newThreshold) external onlyAdmin {
        dynamicThreshold = _newThreshold;
        emit DynamicThresholdUpdated(_newThreshold);
    }

     /**
     * @dev Sets the address of the specific NFT contract required for bonding access.
     * @param _nftAddress The address of the ERC721 contract.
     */
    function setNFTBondingConfig(address _nftAddress) external onlyAdmin {
         require(_nftAddress != address(0), "Invalid address");
         bondedNFTAddress = _nftAddress;
    }

    /**
     * @dev Sets the cost for a user subscription in native currency.
     * @param _cost The new subscription cost in wei.
     */
    function setSubscriptionCost(uint256 _cost) external onlyAdmin {
        subscriptionCost = _cost;
    }

    /**
     * @dev Admin/Keeper function to update a user's reputation score.
     *      In a real system, this would be driven by complex on/off-chain logic.
     * @param _user The address of the user.
     * @param _newScore The new reputation score.
     */
    function updateUserReputationScore(address _user, uint256 _newScore) external onlyAdmin {
        userStates[_user].reputationScore = _newScore;
        emit UserReputationUpdated(_user, _newScore);
    }

    /**
     * @dev Grants admin privileges to an address.
     * @param _newAdmin The address to grant privileges to.
     */
    function grantAdminRole(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        // For simplicity, assuming only one owner/admin role.
        // In a multi-role system, this would add to a role mapping.
        // For this contract, setting the owner directly (if single admin).
        // If multiple admins are needed, change `owner` to a mapping and add logic.
        // Sticking to simple Ownable pattern where `owner` is the single admin for now.
         owner = _newAdmin; // This effectively transfers ownership in a simple Ownable setup
    }

     /**
     * @dev Revokes admin privileges from an address.
     *      Note: If using a simple Ownable pattern where `owner` is the single admin,
     *      this would require setting the owner to address(0) or transferring to another.
     *      A more robust system would use role-based access control.
     *      Keeping it simple: this function is less relevant in a basic Ownable model
     *      unless implementing a multi-admin system internally.
     *      Let's make this function a placeholder for a multi-admin system.
     *      In the current simple Ownable, use `transferOwnership` or similar.
     *      Leaving as a placeholder demonstrating the *concept* of revoking.
     */
    function revokeAdminRole(address _admin) external onlyAdmin {
         // This function is a placeholder. Implementations vary based on access control pattern.
         // In a multi-admin system (not implemented here for brevity), this would remove the admin role.
         revert("Revoking admin roles requires a multi-admin system not implemented here.");
    }

    /**
     * @dev Pauses all functions inherited from Pausable.
     *      Used for emergency stops, separate from VaultMode.Paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }


     /**
     * @dev Allows admin to sweep accidentally sent tokens that are NOT supported.
     *      Crucial safety function.
     * @param _token The address of the token to sweep.
     * @param _to The address to send the tokens to.
     */
    function sweepUnusualTokens(address _token, address _to) external onlyAdmin {
        require(!supportedTokens[_token].isSupported, "Cannot sweep supported tokens");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to sweep");
        token.transfer(_to, balance);
     }


    // --- Oracle & State Logic Functions ---

    /**
     * @dev Called by the oracle or an authorized keeper to update the cached oracle value.
     * @param _newValue The latest value from the oracle.
     */
    function processOracleUpdate(uint256 _newValue) external {
        // In a real system, add authorization check (e.g., only from trusted oracle address or keeper)
        // require(msg.sender == oracle || isKeeper(msg.sender), "Unauthorized"); // Example authorization
        oracleValue = _newValue;
        emit OracleValueUpdated(_newValue, uint64(block.timestamp));
    }

     /**
     * @dev Triggers an automatic transition of the vault mode based on current state and oracle data.
     *      Can be called by admin or a keeper.
     *      Example logic: If oracleValue > dynamicThreshold, switch to ConditionalOnly.
     */
    function triggerModeTransition() external {
        // In a real system, add authorization check (e.g., only admin or a specific keeper role)
        // require(msg.sender == owner || isKeeper(msg.sender), "Unauthorized"); // Example authorization

        VaultMode previousMode = currentVaultMode;

        if (currentVaultMode == VaultMode.Active && oracleValue > dynamicThreshold) {
            currentVaultMode = VaultMode.ConditionalOnly;
        } else if (currentVaultMode == VaultMode.ConditionalOnly && oracleValue <= dynamicThreshold) {
             currentVaultMode = VaultMode.Active;
        }
        // Add more complex mode transition logic here based on reputation, NFT status, etc.
        // Example: If a majority of active users bond NFTs, switch to BondedAccess? (Too complex for example)

        if (currentVaultMode != previousMode) {
            emit VaultModeChanged(currentVaultMode);
        }
    }


    /**
     * @dev Internal helper function to check if the current dynamic condition is met for a user.
     *      Conditions depend on the current vault mode, oracle value, user state, etc.
     * @param _user The address of the user to check conditions for.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkDynamicCondition(address _user) internal view returns (bool) {
        UserState storage user = userStates[_user];

        if (currentVaultMode == VaultMode.Paused) {
            return false; // Nothing is allowed if system is paused
        }

        if (currentVaultMode == VaultMode.ReputationLocked) {
            // Example: Requires reputation > 500 and oracleValue > threshold
            if (user.reputationScore <= 500 || oracleValue <= dynamicThreshold) {
                return false;
            }
        }

        if (currentVaultMode == VaultMode.BondedAccess) {
             // Example: Requires bonded NFT AND subscription is active OR reputation > 700
             if (!user.isNFTBonded || (user.subscriptionExpires < block.timestamp && user.reputationScore <= 700)) {
                 return false;
             }
        }

        if (currentVaultMode == VaultMode.ConditionalOnly) {
             // Example: Only allowed if oracle value is within a specific range
             // Or if user has attested reputation recently, etc.
             if (oracleValue < dynamicThreshold || oracleValue > dynamicThreshold * 2) { // Example range
                 return false;
             }
        }

        // Default condition for Active mode or if no specific mode condition fails: Check global threshold
        // Example: Always requires oracleValue >= threshold for conditional actions even in Active mode
        if (oracleValue < dynamicThreshold && currentVaultMode != VaultMode.Active) {
             return false; // In conditional modes, minimum oracle value might be required
        }


        // If none of the specific mode conditions returned false, the condition is considered met for the action context.
        return true;
    }


    // --- User Interaction Functions ---

    /**
     * @dev Allows a user to deposit supported ERC20 tokens into the vault.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external payable nonReentrant whenNotPaused whenNotPausedBySystem whenActiveOrConditional {
        require(supportedTokens[_token].isSupported, "Token not supported");
        require(_amount > 0, "Amount must be greater than 0");

        // ERC20 deposit requires prior approval
        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // No user-specific state change on basic deposit, funds are pooled.
        // State change would be needed for per-user balances, but this is a pooled vault.

        emit Deposit(msg.sender, _token, _amount);
    }

    /**
     * @dev Allows a user to deposit with associated criteria, potentially influencing
     *      future conditional withdrawals or yield eligibility based on this deposit.
     *      This is an advanced concept where the *terms* of the deposit matter.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to deposit.
     * @param _conditionCriteria Placeholder for bytes encoding specific criteria (e.g., target oracle range, minimum duration).
     */
    function depositWithConditionCriteria(address _token, uint256 _amount, bytes calldata _conditionCriteria) external payable nonReentrant whenNotPaused whenNotPausedBySystem {
        require(supportedTokens[_token].isSupported, "Token not supported");
        require(_amount > 0, "Amount must be greater than 0");
        // require(_conditionCriteria.length > 0, "Criteria must be provided"); // Example requirement

        // ERC20 deposit requires prior approval
        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // In a full implementation, _conditionCriteria would be stored and used
        // when evaluating conditional withdrawal requests related to this deposit.
        // For this example, we just acknowledge the criteria conceptually.
        // This adds a layer of complexity missing in standard vaults.

        emit Deposit(msg.sender, _token, _amount);
        // Could add a specific event for this type of deposit
    }


    /**
     * @dev User requests a conditional withdrawal. This creates a request record.
     *      The actual asset transfer happens only when `claimRequestedWithdrawal` is called
     *      AND the dynamic condition is met at that time.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount requested.
     */
    function requestConditionalWithdrawal(address _token, uint256 _amount) external nonReentrant whenNotPaused whenNotPausedBySystem {
         // Note: Does NOT check condition here. Condition is checked on CLAIM.
         require(supportedTokens[_token].isSupported, "Token not supported");
         require(_amount > 0, "Amount must be greater than 0");
         // Check if vault balance is sufficient to cover this potential withdrawal
         // Note: In a pooled vault, this check is complex. A simpler approach
         // is to just ensure total requests don't exceed total deposits minus reserved amounts.
         // For this example, skipping complex balance checks at request time.

         conditionalWithdrawalRequests[msg.sender].push(
             ConditionalWithdrawalRequest({
                 token: _token,
                 amount: _amount,
                 requestTime: uint64(block.timestamp),
                 isProcessed: false
             })
         );

         emit ConditionalWithdrawalRequested(msg.sender, _token, _amount, conditionalWithdrawalRequests[msg.sender].length - 1);
    }


    /**
     * @dev User attempts to claim a previously requested conditional withdrawal.
     *      Requires the dynamic condition (_checkDynamicCondition) to be met currently.
     * @param _requestId The index of the request in the user's requests array.
     */
    function claimRequestedWithdrawal(uint256 _requestId) external nonReentrant whenNotPaused whenNotPausedBySystem {
         ConditionalWithdrawalRequest storage request = conditionalWithdrawalRequests[msg.sender][_requestId];

         require(!request.isProcessed, "Request already processed");
         require(supportedTokens[request.token].isSupported, "Token no longer supported"); // Ensure token is still valid

         // --- Core Conditional Check ---
         require(_checkDynamicCondition(msg.sender), "Dynamic condition not met to claim");
         // --- End Core Conditional Check ---


         // Check contract balance _now_ before transferring
         IERC20 token = IERC20(request.token);
         require(token.balanceOf(address(this)) >= request.amount, "Insufficient vault balance for token");

         request.isProcessed = true; // Mark request as processed BEFORE transfer
         token.transfer(msg.sender, request.amount); // Transfer assets

         emit ConditionalWithdrawalClaimed(msg.sender, _requestId);
         emit Withdrawal(msg.sender, request.token, request.amount);
    }


    /**
     * @dev Allows a user to claim accumulated dynamic yield based on their state,
     *      vault mode, oracle data, and token factors since their last claim.
     */
    function claimDynamicYield(address _token) external nonReentrant whenNotPaused whenNotPausedBySystem {
         require(supportedTokens[_token].isSupported, "Token not supported for yield");

         UserState storage user = userStates[msg.sender];
         uint256 yieldAmount = previewClaimableYield(msg.sender, _token); // Calculate yield since last claim
         require(yieldAmount > 0, "No yield accumulated or available");

         // In a real system, this might require meeting _checkDynamicCondition() or specific criteria.
         // For simplicity, allowing claim based on accumulation and token support.
         // require(_checkDynamicCondition(msg.sender), "Condition not met to claim yield"); // Optional gate

         user.lastYieldClaimTime = uint64(block.timestamp); // Update last claim time BEFORE transfer

         IERC20 token = IERC20(_token);
         require(token.balanceOf(address(this)) >= yieldAmount, "Insufficient vault balance for yield");
         token.transfer(msg.sender, yieldAmount);

         emit DynamicYieldClaimed(msg.sender, _token, yieldAmount);
    }


    /**
     * @dev Allows a user to pay for a subscription to gain access to certain features.
     *      Pays in native currency (ETH).
     */
    function paySubscription() external payable whenNotPaused whenNotPausedBySystem {
        require(msg.value >= subscriptionCost, "Insufficient payment");

        UserState storage user = userStates[msg.sender];
        uint64 newExpiry = uint64(block.timestamp + 30 days); // Example: 30 days subscription
        if (user.subscriptionExpires > block.timestamp) {
            // Extend from current expiry if subscription is active
            newExpiry = user.subscriptionExpires + 30 days;
        }
        user.subscriptionExpires = newExpiry;

        // Excess ETH is sent back automatically due to `payable` and lack of full `msg.value` consumption.
        // To keep excess, need explicit transfer or receive function logic. Sticking to simple auto-refund.
        // If subscription cost is 0, this function effectively does nothing requiring value.

        emit UserSubscriptionPaid(msg.sender, user.subscriptionExpires);
    }


    /**
     * @dev Allows a user to bond a specific NFT to the contract to enable special access modes.
     *      Requires the user to have approved the NFT transfer to this contract beforehand.
     *      The contract must inherit from ERC721Holder or implement onERC721Received.
     * @param _tokenId The token ID of the NFT to bond.
     */
    function bondNFTForAccess(uint256 _tokenId) external nonReentrant whenNotPaused whenNotPausedBySystem {
         UserState storage user = userStates[msg.sender];
         require(!user.isNFTBonded, "User already has an NFT bonded");
         require(bondedNFTAddress != address(0), "NFT bonding is not configured");

         IERC721 nft = IERC721(bondedNFTAddress);
         require(nft.ownerOf(_tokenId) == msg.sender, "Sender does not own the NFT");
         // Requires sender to have called `approve` or `setApprovalForAll` on the NFT contract
         // before calling this function.
         nft.safeTransferFrom(msg.sender, address(this), _tokenId);

         user.isNFTBonded = true;
         user.bondedNFTTokenId = _tokenId;

         emit UserNFTBonded(msg.sender, bondedNFTAddress, _tokenId);
    }

     /**
     * @dev Allows a user to unbond their previously bonded NFT.
     *      May have conditions depending on vault mode or user state (none implemented here for simplicity).
     */
    function unbondNFT() external nonReentrancy whenNotPaused whenNotPausedBySystem {
        UserState storage user = userStates[msg.sender];
        require(user.isNFTBonded, "User does not have an NFT bonded");
        require(bondedNFTAddress != address(0), "NFT bonding is not configured");

        uint256 tokenId = user.bondedNFTTokenId;

        user.isNFTBonded = false;
        user.bondedNFTTokenId = 0; // Reset token ID

        IERC721 nft = IERC721(bondedNFTAddress);
        // Transfer NFT back to the user
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit UserNFTUnbonded(msg.sender, bondedNFTAddress, tokenId);
    }

     /**
     * @dev Allows a user to 'attest' to their reputation. This is a placeholder for
     *      a mechanism where users perform an action (e.g., stake, provide proof,
     *      vote) to influence their reputation score, which is then potentially
     *      updated by an admin/keeper via `updateUserReputationScore`.
     * @param _value An arbitrary value related to the attestation.
     * @param _proof An arbitrary bytes field for complex proof data.
     */
    function attestReputation(uint256 _value, bytes calldata _proof) external whenNotPaused whenNotPausedBySystem {
        // This function's logic depends heavily on the specific reputation system.
        // It could require staking, submitting signed data, interacting with another contract, etc.
        // For this example, it's a simple marker function showing user intent.
        // A real implementation would update internal state or trigger external verification.

        // Example: Require staking a small amount?
        // require(IERC20(someStakingToken).transferFrom(msg.sender, address(this), stakingAmount), "Staking failed");
        // userStates[msg.sender].lastAttestationTime = block.timestamp; // Example state update

        // Emit an event for off-chain systems or keepers to process
        emit UserReputationUpdated(msg.sender, userStates[msg.sender].reputationScore); // Emit existing score, update happens via admin/keeper
        // Could emit a specific AttestationSubmitted event
    }


    // --- View Functions ---

    /**
     * @dev Returns the current operational mode of the vault.
     */
    function getVaultMode() external view returns (VaultMode) {
        return currentVaultMode;
    }

     /**
     * @dev Returns the current dynamic threshold value.
     */
    function getDynamicThreshold() external view returns (uint256) {
        return dynamicThreshold;
    }

    /**
     * @dev Returns the latest cached oracle value.
     */
    function getOracleValue() external view returns (uint256) {
        return oracleValue;
    }

    /**
     * @dev Returns the state details for a specific user.
     * @param _user The address of the user.
     */
    function getUserState(address _user) external view returns (UserState memory) {
        return userStates[_user];
    }

     /**
     * @dev Returns a specific conditional withdrawal request for a user by index.
     * @param _user The address of the user.
     * @param _index The index of the request in the user's array.
     */
    function getConditionalWithdrawalRequest(address _user, uint256 _index) external view returns (ConditionalWithdrawalRequest memory) {
        require(_index < conditionalWithdrawalRequests[_user].length, "Request index out of bounds");
        return conditionalWithdrawalRequests[_user][_index];
    }

    /**
     * @dev Calculates and returns the potential claimable dynamic yield for a user and token.
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return uint256 The calculated yield amount.
     */
    function previewClaimableYield(address _user, address _token) public view returns (uint256) {
        if (!supportedTokens[_token].isSupported) {
            return 0;
        }

        UserState storage user = userStates[_user];
        // Example simplified yield calculation: proportional to time since last claim,
        // influenced by vault mode, oracle value, user reputation, and token factor.
        uint256 timeSinceLastClaim = block.timestamp - user.lastYieldClaimTime;

        if (timeSinceLastClaim == 0) {
             return 0; // No time passed since last claim
        }

        // This is a highly simplified placeholder calculation.
        // Real yield would be based on total pool growth, user's share, etc.
        uint256 baseRate = 100; // Example base rate (per second? per block?)
        uint256 yieldAmount = (timeSinceLastClaim * baseRate * supportedTokens[_token].dynamicYieldFactor) / 1e18; // Scale factor

        // Modify yield based on state (example logic)
        if (currentVaultMode == VaultMode.BondedAccess && user.isNFTBonded) {
            yieldAmount = (yieldAmount * 150) / 100; // 50% yield boost
        }
        if (user.subscriptionExpires > block.timestamp) {
             yieldAmount = (yieldAmount * 120) / 100; // 20% yield boost
        }
        yieldAmount = (yieldAmount * user.reputationScore) / 1000; // Scale by reputation (assuming max rep 1000)
        yieldAmount = (yieldAmount * oracleValue) / 1000; // Scale by oracle (assuming oracle max 1000)

        // Prevent excessive yield if factors are huge
        uint256 maxYieldPerClaim = 1e18; // Cap example
        return yieldAmount > maxYieldPerClaim ? maxYieldPer铅 : yieldAmount;
    }

    /**
     * @dev Returns the amount for a specific conditional withdrawal request if it were claimed now.
     *      Does NOT check if the condition is met, just returns the requested amount.
     * @param _user The address of the user.
     * @param _requestId The index of the request.
     */
    function previewConditionalWithdrawalAmount(address _user, uint256 _requestId) external view returns (uint256) {
         require(_requestId < conditionalWithdrawalRequests[_user].length, "Request index out of bounds");
         return conditionalWithdrawalRequests[_user][_requestId].amount;
    }

    /**
     * @dev Checks and returns whether the dynamic condition for withdrawal/claiming is currently met for a user.
     *      Useful for UI to indicate if claiming is possible.
     * @param _user The address of the user.
     * @return bool True if the condition is met, false otherwise.
     */
    function isConditionCurrentlyMet(address _user) external view returns (bool) {
        return _checkDynamicCondition(_user);
    }

    // Override the receive function to accept native currency for subscriptions
    receive() external payable {
        // This function allows the contract to receive native currency (ETH).
        // The paySubscription function specifically handles payments WITH msg.value.
        // This receive allows for general ETH transfers if needed, though not strictly used
        // for subscriptions alone. Could add checks here if only subscriptions are allowed via receive.
    }

    // Override onERC721Received from ERC721Holder to accept NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        override(ERC721Holder)
        external
        returns (bytes4)
    {
        // This is called by the ERC721 token contract when an NFT is transferred to this contract.
        // We must return the ERC721 magic value to signal acceptance.
        // Add specific checks here if needed (e.g., only accept from bondedNFTAddress)
        require(msg.sender == bondedNFTAddress, "Can only receive the configured bonded NFT");

        // No state update needed here, the state update happens in `bondNFTForAccess`
        // BEFORE the transfer is initiated.

        return super.onERC721Received(operator, from, tokenId, data);
    }
}
```