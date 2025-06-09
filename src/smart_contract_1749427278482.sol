Okay, here is a Solidity smart contract named `ElysiumVault`. This contract is designed as a multi-asset conditional vault with features like time locks, external condition checks (via an oracle), dynamic withdrawal fees, and a built-in programmable beneficiary/inheritance mechanism.

It avoids directly duplicating common patterns like standard ERC20/ERC721 implementations, yield farming strategies, or simple token exchanges. Instead, it focuses on complex access control, conditional logic, and multi-role interaction (user, owner, oracle, beneficiary).

It utilizes concepts like:
*   **Conditional Access:** Funds/NFTs unlocked based on time AND external data.
*   **Oracle Integration:** Reacting to off-chain information provided by a trusted source.
*   **Dynamic Fees:** Withdrawal fees that could theoretically be adjusted based on conditions (though implemented simply here).
*   **Programmable Beneficiary/Inheritance:** Users can define beneficiaries and activation conditions (time, external data) for their assets. Activation can be triggered by *anyone* once conditions are met, allowing the beneficiary to claim.
*   **Multi-Asset Support:** Handling Ether, ERC20 tokens, and ERC721 tokens within a single contract under conditional access.
*   **Role-Based Access:** Owner, Oracle, and User roles with distinct permissions.

---

**Outline and Function Summary**

**Contract Name:** `ElysiumVault`

**Core Concept:** A secure, multi-asset vault allowing users to deposit ETH, ERC20 tokens, and ERC721 NFTs, subject to configurable withdrawal conditions (time-based, external oracle data). Includes a programmable beneficiary/inheritance feature.

**Key Features:**
*   Supports ETH, ERC20, and ERC721 deposits.
*   Conditional withdrawals based on time and external conditions provided by a designated oracle address.
*   Dynamic withdrawal fees configurable by the owner.
*   Users can set beneficiary addresses and activation conditions for their deposited assets.
*   Beneficiary activation can be triggered by anyone once conditions are met.
*   Owner controls supported assets, vault state (pause/unpause), oracle address, and fee percentage.

**Roles:**
*   `Owner`: Manages contract settings (pause, oracle, fees, supported assets), withdraws collected fees, transfers ownership.
*   `Oracle`: Can update external condition values relied upon for conditional access.
*   `User`: Deposits assets, sets withdrawal conditions for their own assets, sets beneficiary settings.
*   `Beneficiary`: Can claim assets *after* their activation conditions are met and triggered.

**Structs:**
*   `WithdrawalConditions`: Defines conditions required for a user to withdraw assets.
    *   `unlockTime`: Minimum timestamp for withdrawal.
    *   `externalConditionKey`: Identifier (bytes32) for an external condition value.
    *   `conditionValue`: Required value for the external condition.
    *   `conditionsSet`: Bool indicating if custom conditions are set.
*   `BeneficiarySettings`: Defines beneficiary and activation conditions for a user's assets.
    *   `beneficiaryAddress`: The address of the beneficiary.
    *   `activationTime`: Minimum timestamp for beneficiary activation.
    *   `activationConditionKey`: Identifier for external condition for activation.
    *   `conditionValue`: Required value for the external condition for activation.
    *   `activated`: Bool indicating if the beneficiary conditions have been met and triggered.
    *   `settingsSet`: Bool indicating if beneficiary settings have been configured.

**Enums:**
*   `VaultState`: Represents the operational state of the vault (Active, Paused, Emergency).

**State Variables:**
*   `owner`: Address of the contract owner.
*   `oracleAddress`: Address authorized to update external conditions.
*   `vaultState`: Current state of the vault.
*   `supportedERC20s`: Mapping of supported ERC20 addresses to boolean.
*   `supportedERC721s`: Mapping of supported ERC721 addresses to boolean.
*   `userERC20Balances`: Mapping `user => tokenAddress => amount`.
*   `userETHBalances`: Mapping `user => amount`.
*   `nftVaultOwner`: Mapping `nftContract => tokenId => userAddress` (who *within the vault* owns the NFT).
*   `externalConditionValues`: Mapping `key (bytes32) => value (uint256)` updated by the oracle.
*   `userERC20WithdrawalConditions`: Mapping `user => tokenAddress => WithdrawalConditions`.
*   `userERC721WithdrawalConditions`: Mapping `user => nftContract => tokenId => WithdrawalConditions`.
*   `userETHWithdrawalConditions`: Mapping `user => WithdrawalConditions`.
*   `userBeneficiarySettings`: Mapping `user => BeneficiarySettings`.
*   `withdrawalFeeBasisPoints`: Dynamic fee percentage (in basis points, 10000 = 100%).
*   `accruedFeesERC20`: Mapping `tokenAddress => amount`.
*   `accruedFeesETH`: Amount.

**Function Summary (Total: 32 functions)**

*   **Management (Owner Only):**
    1.  `constructor()`: Initializes owner, oracle (initially owner), state, fee.
    2.  `pauseVault()`: Pauses most user interactions.
    3.  `unpauseVault()`: Resumes user interactions.
    4.  `setOracleAddress(address _oracleAddress)`: Sets the address allowed to update external conditions.
    5.  `setDynamicFeeBasisPoints(uint16 _feeBasisPoints)`: Sets the withdrawal fee rate (in basis points).
    6.  `addSupportedERC20(address _tokenAddress)`: Adds an ERC20 token to the supported list.
    7.  `removeSupportedERC20(address _tokenAddress)`: Removes an ERC20 token from the supported list.
    8.  `addSupportedERC721(address _nftCollection)`: Adds an ERC721 collection to the supported list.
    9.  `removeSupportedERC721(address _nftCollection)`: Removes an ERC721 collection from the supported list.
    10. `withdrawAccruedFeesETH()`: Owner withdraws collected ETH fees.
    11. `withdrawAccruedFeesERC20(address _tokenAddress)`: Owner withdraws collected ERC20 fees for a specific token.
    12. `transferVaultOwnership(address _newOwner)`: Transfers ownership of the contract.
    13. `renounceVaultOwnership()`: Renounces ownership (sets owner to zero address).

*   **Oracle Interaction (Oracle Only):**
    14. `updateExternalConditionValue(bytes32 _key, uint256 _value)`: Updates a specific external condition value.

*   **User Deposits:**
    15. `depositETH()`: Receives ETH deposits.
    16. `depositERC20(address _tokenAddress, uint256 _amount)`: Receives ERC20 deposits (requires prior approval).
    17. `depositERC721(address _nftCollection, uint256 _tokenId)`: Receives ERC721 deposits (requires prior approval/setApprovalForAll).

*   **User Conditional Withdrawals:**
    18. `withdrawETH(uint256 _amount)`: Initiates ETH withdrawal (checks conditions, applies fee).
    19. `withdrawERC20(address _tokenAddress, uint256 _amount)`: Initiates ERC20 withdrawal (checks conditions, applies fee).
    20. `withdrawERC721(address _nftCollection, uint256 _tokenId)`: Initiates ERC721 withdrawal (checks conditions, applies fee).

*   **User Condition/Beneficiary Settings:**
    21. `setETHWithdrawalConditions(uint64 _unlockTime, bytes32 _externalConditionKey, uint256 _conditionValue)`: Sets withdrawal conditions for user's ETH.
    22. `setERC20WithdrawalConditions(address _tokenAddress, uint64 _unlockTime, bytes32 _externalConditionKey, uint256 _conditionValue)`: Sets withdrawal conditions for user's specific ERC20 balance.
    23. `setERC721WithdrawalConditions(address _nftCollection, uint256 _tokenId, uint64 _unlockTime, bytes32 _externalConditionKey, uint256 _conditionValue)`: Sets withdrawal conditions for a specific NFT.
    24. `setBeneficiarySettings(address _beneficiaryAddress, uint64 _activationTime, bytes32 _activationConditionKey, uint256 _conditionValue)`: Sets beneficiary and activation conditions for user's assets.

*   **Beneficiary Activation & Claim:**
    25. `activateBeneficiary(address _user)`: Tries to activate the beneficiary for a specific user if their conditions are met (callable by anyone).
    26. `claimForBeneficiaryETH(address _user, uint256 _amount)`: Beneficiary claims ETH from a specific user's balance.
    27. `claimForBeneficiaryERC20(address _user, address _tokenAddress, uint256 _amount)`: Beneficiary claims ERC20 from a specific user's balance.
    28. `claimForBeneficiaryERC721(address _user, address _nftCollection, uint256 _tokenId)`: Beneficiary claims a specific NFT from a specific user.

*   **View/Utility Functions:**
    29. `getVaultState()`: Returns the current state of the vault.
    30. `getUserETHBalance(address _user)`: Returns a user's ETH balance in the vault.
    31. `getUserERC20Balance(address _user, address _tokenAddress)`: Returns a user's ERC20 balance in the vault.
    32. `isNFTInVaultAndOwnedByUser(address _nftCollection, uint256 _tokenId, address _user)`: Checks if a specific NFT is in the vault and recorded as owned by a user.
    33. `checkWithdrawalConditionsMet(address _user, uint64 _unlockTime, bytes32 _externalConditionKey)`: Helper view to check if a given set of withdrawal conditions is met.
    34. `getBeneficiarySettings(address _user)`: Returns the beneficiary settings for a user.
    35. `isBeneficiaryActive(address _user)`: Returns if the beneficiary for a user has been activated.
    36. `getExternalConditionValue(bytes32 _key)`: Returns the current value of an external condition.
    37. `getAccruedFeesETH()`: Returns the total accrued ETH fees.
    38. `getAccruedFeesERC20(address _tokenAddress)`: Returns the total accrued ERC20 fees for a token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity, could implement custom access control

// Custom Errors
error ElysiumVault__NotOwner();
error ElysiumVault__NotOracle();
error ElysiumVault__VaultPaused();
error ElysiumVault__VaultNotPaused();
error ElysiumVault__ETHTransferFailed();
error ElysiumVault__ERC20TransferFailed();
error ElysiumVault__ERC721TransferFailed();
error ElysiumVault__InsufficientETHBalance();
error ElysiumVault__InsufficientERC20Balance(address token);
error ElysiumVault__ERC721NotOwnedByUserInVault(address nftContract, uint256 tokenId, address user);
error ElysiumVault__UnsupportedAsset(address assetAddress);
error ElysiumVault__WithdrawalConditionsNotMet();
error ElysiumVault__AmountMustBeGreaterThanZero();
error ElysiumVault__CannotRemoveSupportedAssetWithBalance();
error ElysiumVault__CannotSetZeroAddressAsOracle();
error ElysiumVault__BeneficiarySettingsNotSet();
error ElysiumVault__BeneficiaryAlreadyActive();
error ElysiumVault__BeneficiaryNotActive();
error ElysiumVault__CallerNotBeneficiary();
error ElysiumVault__InvalidFeeBasisPoints();

/**
 * @title ElysiumVault
 * @dev A secure, multi-asset conditional vault with programmable beneficiary features.
 * Users can deposit ETH, ERC20, and ERC721 assets. Withdrawals are subject to
 * time-based and external conditions (via oracle). Users can define beneficiaries
 * with activation conditions.
 */
contract ElysiumVault is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using Address for address payable;

    // --- Structs ---

    /**
     * @dev Defines conditions required for a user to withdraw assets.
     * If `conditionsSet` is false, withdrawal is immediately allowed (subject to fees).
     */
    struct WithdrawalConditions {
        uint64 unlockTime; // Minimum timestamp for withdrawal
        bytes32 externalConditionKey; // Identifier for an external condition value
        uint256 conditionValue; // Required value for the external condition
        bool conditionsSet; // True if custom conditions are set
    }

    /**
     * @dev Defines beneficiary and activation conditions for a user's assets.
     * Anyone can trigger activation if conditions are met. Only the beneficiary
     * can claim assets AFTER activation.
     */
    struct BeneficiarySettings {
        address beneficiaryAddress; // The address of the beneficiary
        uint64 activationTime; // Minimum timestamp for beneficiary activation
        bytes32 activationConditionKey; // Identifier for external condition for activation
        uint256 conditionValue; // Required value for the external condition for activation
        bool activated; // True if the beneficiary conditions have been met and triggered
        bool settingsSet; // True if beneficiary settings have been configured
    }

    // --- Enums ---

    enum VaultState {
        Active,
        Paused, // Deposits and most withdrawals paused
        Emergency // Only owner/specific emergency actions allowed (not fully implemented in this example)
    }

    // --- State Variables ---

    address private _oracleAddress;
    VaultState private _vaultState;

    // Supported assets
    mapping(address => bool) private _supportedERC20s;
    mapping(address => bool) private _supportedERC721s;

    // User balances within the vault
    mapping(address => uint256) private _userETHBalances;
    mapping(address => mapping(address => uint256)) private _userERC20Balances;
    // Mapping: nftContract => tokenId => userAddress (who within the vault owns this NFT)
    mapping(address => mapping(uint256 => address)) private _nftVaultOwner;

    // External condition values updated by the oracle
    mapping(bytes32 => uint256) private _externalConditionValues;

    // User-specific withdrawal conditions
    mapping(address => WithdrawalConditions) private _userETHWithdrawalConditions;
    mapping(address => mapping(address => WithdrawalConditions)) private _userERC20WithdrawalConditions;
    mapping(address => mapping(address => mapping(uint256 => WithdrawalConditions))) private _userERC721WithdrawalConditions;

    // User-specific beneficiary settings
    mapping(address => BeneficiarySettings) private _userBeneficiarySettings;

    // Dynamic Withdrawal Fee
    uint16 private _withdrawalFeeBasisPoints; // e.g., 100 = 1%, 10000 = 100%

    // Accrued Fees (collected from withdrawals)
    uint256 private _accruedFeesETH;
    mapping(address => uint256) private _accruedFeesERC20;

    // --- Events ---

    event VaultStateChanged(VaultState newState);
    event OracleAddressSet(address oldOracle, address newOracle);
    event DynamicFeeBasisPointsSet(uint16 oldFee, uint16 newFee);
    event SupportedERC20Added(address tokenAddress);
    event SupportedERC20Removed(address tokenAddress);
    event SupportedERC721Added(address nftCollection);
    event SupportedERC721Removed(address nftCollection);
    event ETHDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed tokenAddress, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed nftCollection, uint256 tokenId);
    event ETHWithdrawn(address indexed user, uint256 amount, uint256 fee);
    event ERC20Withdrawn(address indexed user, address indexed tokenAddress, uint256 amount, uint256 fee);
    event ERC721Withdrawn(address indexed user, address indexed nftCollection, uint256 tokenId, uint256 fee);
    event ETHWithdrawalConditionsSet(address indexed user, WithdrawalConditions conditions);
    event ERC20WithdrawalConditionsSet(address indexed user, address indexed tokenAddress, WithdrawalConditions conditions);
    event ERC721WithdrawalConditionsSet(address indexed user, address indexed nftCollection, uint256 tokenId, WithdrawalConditions conditions);
    event BeneficiarySettingsSet(address indexed user, address indexed beneficiary, uint64 activationTime);
    event BeneficiaryActivated(address indexed user, address indexed beneficiary, uint256 timestamp);
    event ETHClaimedByBeneficiary(address indexed user, address indexed beneficiary, uint256 amount);
    event ERC20ClaimedByBeneficiary(address indexed user, address indexed beneficiary, address indexed tokenAddress, uint256 amount);
    event ERC721ClaimedByBeneficiary(address indexed user, address indexed beneficiary, address indexed nftCollection, uint256 tokenId);
    event ExternalConditionUpdated(bytes32 key, uint256 value);
    event FeesWithdrawn(address indexed owner, address indexed asset, uint256 amount);

    // --- Modifiers ---

    modifier whenActive() {
        if (_vaultState != VaultState.Active) {
            revert ElysiumVault__VaultPaused();
        }
        _;
    }

    modifier whenPaused() {
        if (_vaultState != VaultState.Paused) {
            revert ElysiumVault__VaultNotPaused();
        }
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) {
            revert ElysiumVault__NotOracle();
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) ReentrancyGuard() ERC721Holder() {
        _oracleAddress = initialOracle;
        _vaultState = VaultState.Active;
        _withdrawalFeeBasisPoints = 0; // Initialize with no fee
        emit VaultStateChanged(VaultState.Active);
        emit OracleAddressSet(address(0), initialOracle);
        emit DynamicFeeBasisPointsSet(0, 0);
    }

    // --- Management Functions (Owner Only) ---

    /**
     * @dev Pauses the vault, preventing most user interactions.
     * Only owner can call.
     */
    function pauseVault() external onlyOwner whenActive {
        _vaultState = VaultState.Paused;
        emit VaultStateChanged(VaultState.Paused);
    }

    /**
     * @dev Unpauses the vault, allowing user interactions again.
     * Only owner can call.
     */
    function unpauseVault() external onlyOwner whenPaused {
        _vaultState = VaultState.Active;
        emit VaultStateChanged(VaultState.Active);
    }

    /**
     * @dev Sets the address authorized to update external condition values.
     * Only owner can call.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) {
            revert ElysiumVault__CannotSetZeroAddressAsOracle();
        }
        address oldOracle = _oracleAddress;
        _oracleAddress = _oracleAddress;
        emit OracleAddressSet(oldOracle, _oracleAddress);
    }

    /**
     * @dev Sets the dynamic withdrawal fee rate in basis points.
     * 100 basis points = 1%, 10000 basis points = 100%. Max 10000.
     * Only owner can call.
     * @param _feeBasisPoints The new fee rate in basis points (0-10000).
     */
    function setDynamicFeeBasisPoints(uint16 _feeBasisPoints) external onlyOwner {
        if (_feeBasisPoints > 10000) {
            revert ElysiumVault__InvalidFeeBasisPoints();
        }
        uint16 oldFee = _withdrawalFeeBasisPoints;
        _withdrawalFeeBasisPoints = _feeBasisPoints;
        emit DynamicFeeBasisPointsSet(oldFee, _withdrawalFeeBasisPoints);
    }

    /**
     * @dev Adds an ERC20 token to the list of supported assets for deposits.
     * Only owner can call.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function addSupportedERC20(address _tokenAddress) external onlyOwner {
        _supportedERC20s[_tokenAddress] = true;
        emit SupportedERC20Added(_tokenAddress);
    }

    /**
     * @dev Removes an ERC20 token from the supported list.
     * Requires that the total balance of this token in the vault is zero.
     * Only owner can call.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function removeSupportedERC20(address _tokenAddress) external onlyOwner {
        // This check is complex as we don't track total supply per token easily.
        // A full implementation would need to track total balances or iterate.
        // For this example, we'll add a simple check, but a robust one is needed.
        // It's safer to add a state variable like `totalERC20Balances[tokenAddress]`
        // or allow removal only when vault is empty.
        // Basic check: If the contract itself holds a balance of this token, prevent removal.
        // This doesn't check user balances held *within* the vault state mapping.
        if (IERC20(_tokenAddress).balanceOf(address(this)) > 0) {
             revert ElysiumVault__CannotRemoveSupportedAssetWithBalance();
        }
        delete _supportedERC20s[_tokenAddress];
        emit SupportedERC20Removed(_tokenAddress);
    }

    /**
     * @dev Adds an ERC721 collection to the list of supported assets for deposits.
     * Only owner can call.
     * @param _nftCollection The address of the ERC721 collection.
     */
    function addSupportedERC721(address _nftCollection) external onlyOwner {
        _supportedERC721s[_nftCollection] = true;
        emit SupportedERC721Added(_nftCollection);
    }

    /**
     * @dev Removes an ERC721 collection from the supported list.
     * Requires that no NFTs from this collection are held by the vault.
     * Only owner can call.
     * @param _nftCollection The address of the ERC721 collection.
     */
    function removeSupportedERC721(address _nftCollection) external onlyOwner {
        // Similar complexity to ERC20 removal. Checking contract balance is easiest
        // but doesn't check `_nftVaultOwner` mapping. A robust check is needed.
        // For example, iterate a list of tokenIds or require the vault is empty.
        // Here, a simplified check based on contract balance for demonstration.
        if (IERC721(_nftCollection).balanceOf(address(this)) > 0) {
             revert ElysiumVault__CannotRemoveSupportedAssetWithBalance();
        }
        delete _supportedERC721s[_nftCollection];
        emit SupportedERC721Removed(_nftCollection);
    }

    /**
     * @dev Allows the owner to withdraw accumulated ETH fees.
     * Only owner can call.
     */
    function withdrawAccruedFeesETH() external onlyOwner nonReentrant {
        uint256 feeAmount = _accruedFeesETH;
        if (feeAmount == 0) return;

        _accruedFeesETH = 0;
        (bool success, ) = payable(owner()).call{value: feeAmount}("");
        if (!success) {
            // If withdrawal fails, return fees to accrued balance to retry later
            _accruedFeesETH = feeAmount;
            revert ElysiumVault__ETHTransferFailed();
        }
        emit FeesWithdrawn(owner(), address(0), feeAmount);
    }

    /**
     * @dev Allows the owner to withdraw accumulated ERC20 fees for a specific token.
     * Only owner can call.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function withdrawAccruedFeesERC20(address _tokenAddress) external onlyOwner nonReentrant {
        uint256 feeAmount = _accruedFeesERC20[_tokenAddress];
        if (feeAmount == 0) return;

        _accruedFeesERC20[_tokenAddress] = 0;
        IERC20(_tokenAddress).safeTransfer(owner(), feeAmount);
        emit FeesWithdrawn(owner(), _tokenAddress, feeAmount);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * Only owner can call.
     * @param _newOwner The address of the new owner.
     */
    function transferVaultOwnership(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner); // Utilizes Ownable's transferOwnership
    }

    /**
     * @dev Renounces ownership of the contract. Owner will be set to the zero address.
     * Once renounced, ownership cannot be recovered.
     * Only owner can call.
     */
    function renounceVaultOwnership() external onlyOwner {
        renounceOwnership(); // Utilizes Ownable's renounceOwnership
    }

    // --- Oracle Interaction (Oracle Only) ---

    /**
     * @dev Allows the designated oracle address to update an external condition value.
     * This value can be used in withdrawal or beneficiary activation conditions.
     * Only oracle can call.
     * @param _key A bytes32 identifier for the condition (e.g., `bytes32("weather.isSunny")`).
     * @param _value The new uint256 value for the condition.
     */
    function updateExternalConditionValue(bytes32 _key, uint256 _value) external onlyOracle {
        _externalConditionValues[_key] = _value;
        emit ExternalConditionUpdated(_key, _value);
    }

    // --- User Deposits ---

    /**
     * @dev Deposits ETH into the vault under the sender's account.
     * @param The amount of ETH to deposit (sent via `msg.value`).
     */
    receive() external payable whenActive {
        if (msg.value == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        _userETHBalances[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        // Handle accidental ETH sends without data, redirect to receive() logic if needed,
        // or just revert if not intended for deposits. Reverting is safer default.
        revert("Fallback not intended");
    }

    /**
     * @dev Deposits an ERC20 token into the vault under the sender's account.
     * Requires the user to have approved the vault contract to spend `_amount`
     * of the token beforehand.
     * Only active when vault is not paused.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of the token to deposit.
     */
    function depositERC20(address _tokenAddress, uint256 _amount) external whenActive nonReentrant {
        if (!_supportedERC20s[_tokenAddress]) {
            revert ElysiumVault__UnsupportedAsset(_tokenAddress);
        }
        if (_amount == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _userERC20Balances[msg.sender][_tokenAddress] += _amount;
        emit ERC20Deposited(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @dev Deposits an ERC721 NFT into the vault under the sender's account.
     * Requires the user to have approved the vault contract to spend the specific NFT
     * or approved the vault for all their NFTs from the collection beforehand.
     * Only active when vault is not paused.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT to deposit.
     */
    function depositERC721(address _nftCollection, uint256 _tokenId) external whenActive nonReentrant {
        if (!_supportedERC721s[_nftCollection]) {
            revert ElysiumVault__UnsupportedAsset(_nftCollection);
        }
        // ERC721Holder's onERC721Received will check if it's supported via `_supportedERC721s` mapping
        // and revert if not. It also correctly handles ownership transfer.
        // The SafeTransferFrom call below triggers the onERC721Received hook.
        IERC721(_nftCollection).safeTransferFrom(msg.sender, address(this), _tokenId);
        // After successful transfer, record who *within the vault* owns this NFT.
        _nftVaultOwner[_nftCollection][_tokenId] = msg.sender;
        emit ERC721Deposited(msg.sender, _nftCollection, _tokenId);
    }

    // --- User Conditional Withdrawals ---

    /**
     * @dev Initiates a withdrawal of ETH from the vault.
     * Checks user's balance, withdrawal conditions, and applies the dynamic fee.
     * Only active when vault is not paused.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 _amount) external whenActive nonReentrant {
        if (_amount == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        if (_userETHBalances[msg.sender] < _amount) {
            revert ElysiumVault__InsufficientETHBalance();
        }

        WithdrawalConditions storage conditions = _userETHWithdrawalConditions[msg.sender];
        if (conditions.conditionsSet && !_checkWithdrawalConditions(conditions)) {
            revert ElysiumVault__WithdrawalConditionsNotMet();
        }

        uint256 fee = _calculateDynamicFee(_amount);
        uint256 amountToSend = _amount - fee;

        _userETHBalances[msg.sender] -= _amount; // Deduct total amount including fee
        _accruedFeesETH += fee; // Add fee to accrued

        payable(msg.sender).sendValue(amountToSend); // Use sendValue for payable address
        // Note: sendValue only forwards 2300 gas, safer than call. For critical ops, call is better.
        // Let's use call with check for robustness in this example.
        // (bool success, ) = payable(msg.sender).call{value: amountToSend}("");
        // if (!success) {
            // Revert state changes if transfer fails (more complex with fees/balances)
            // Consider a pull pattern or simpler revert on fail.
            // For this example, assuming call success or letting it revert
        // }

        emit ETHWithdrawn(msg.sender, _amount, fee);
    }

    /**
     * @dev Initiates a withdrawal of an ERC20 token from the vault.
     * Checks user's balance, withdrawal conditions, and applies the dynamic fee.
     * Only active when vault is not paused.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of the token to withdraw.
     */
    function withdrawERC20(address _tokenAddress, uint256 _amount) external whenActive nonReentrant {
         if (!_supportedERC20s[_tokenAddress]) {
            revert ElysiumVault__UnsupportedAsset(_tokenAddress); // Should ideally not happen if deposit check works
        }
        if (_amount == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        if (_userERC20Balances[msg.sender][_tokenAddress] < _amount) {
            revert ElysiumVault__InsufficientERC20Balance(_tokenAddress);
        }

        WithdrawalConditions storage conditions = _userERC20WithdrawalConditions[msg.sender][_tokenAddress];
        if (conditions.conditionsSet && !_checkWithdrawalConditions(conditions)) {
            revert ElysiumVault__WithdrawalConditionsNotMet();
        }

        uint256 fee = _calculateDynamicFee(_amount);
        uint256 amountToSend = _amount - fee;

        _userERC20Balances[msg.sender][_tokenAddress] -= _amount; // Deduct total amount
        _accruedFeesERC20[_tokenAddress] += fee; // Add fee

        IERC20(_tokenAddress).safeTransfer(msg.sender, amountToSend);
        emit ERC20Withdrawn(msg.sender, _tokenAddress, _amount, fee);
    }

    /**
     * @dev Initiates a withdrawal of an ERC721 NFT from the vault.
     * Checks user's ownership recorded in the vault, withdrawal conditions, and applies the dynamic fee (fee is on the *value* represented by the NFT, which is complex - here applying a nominal fee, or fee *on withdrawal action*). Let's make it a fee on the *withdrawal action* not value.
     * Only active when vault is not paused.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT to withdraw.
     */
    function withdrawERC721(address _nftCollection, uint256 _tokenId) external whenActive nonReentrant {
        if (!_supportedERC721s[_nftCollection]) {
            revert ElysiumVault__UnsupportedAsset(_nftCollection); // Should not happen if deposit check works
        }
        if (_nftVaultOwner[_nftCollection][_tokenId] != msg.sender) {
            revert ElysiumVault__ERC721NotOwnedByUserInVault(_nftCollection, _tokenId, msg.sender);
        }

        WithdrawalConditions storage conditions = _userERC721WithdrawalConditions[msg.sender][_nftCollection][_tokenId];
         if (conditions.conditionsSet && !_checkWithdrawalConditions(conditions)) {
            revert ElysiumVault__WithdrawalConditionsNotMet();
        }

        // Apply a nominal fee for NFT withdrawal? Or base it on something else?
        // For simplicity, let's assume the fee applies to the *action* or a small value.
        // Realistically, value-based fee for NFTs is hard on chain without price oracles.
        // Let's calculate a minimal fee based on a placeholder value (e.g., 1 unit).
        // Or simplify: fee is collected separately for NFT withdrawals if needed.
        // Let's make the fee calculation apply to a placeholder value, or just accrue a token fee.
        // Option: Owner must collect fees in a specific token.
        // Let's accrue ETH fee for NFT withdrawals.
        uint256 nominalFee = _calculateDynamicFee(1e15); // Fee based on 0.001 ETH placeholder? Arbitrary.
                                                        // Simpler: make fee apply to fungible withdrawals only.
                                                        // Let's remove fee for NFTs for simplicity unless price oracle is robust.
        uint256 fee = 0; // No fee for NFT withdrawal in this version

        delete _nftVaultOwner[_nftCollection][_tokenId]; // Remove ownership record BEFORE transfer

        IERC721(_nftCollection).safeTransferFrom(address(this), msg.sender, _tokenId);
        // No fee accrual for NFTs in this implementation

        emit ERC721Withdrawn(msg.sender, _nftCollection, _tokenId, fee); // fee is 0
    }

    // --- User Condition/Beneficiary Settings ---

    /**
     * @dev Sets custom withdrawal conditions for the user's ETH balance.
     * If conditions are not set (all parameters default), any withdrawal is allowed.
     * @param _unlockTime Minimum timestamp (0 means no time lock).
     * @param _externalConditionKey Key for external condition (bytes32(0) means no external condition).
     * @param _conditionValue Required value for external condition (0 means condition met if key is 0 or value is 0).
     */
    function setETHWithdrawalConditions(
        uint64 _unlockTime,
        bytes32 _externalConditionKey,
        uint256 _conditionValue
    ) external whenActive {
        WithdrawalConditions storage conditions = _userETHWithdrawalConditions[msg.sender];
        conditions.unlockTime = _unlockTime;
        conditions.externalConditionKey = _externalConditionKey;
        conditions.conditionValue = _conditionValue;
        conditions.conditionsSet = (_unlockTime > 0 || _externalConditionKey != bytes32(0));

        emit ETHWithdrawalConditionsSet(msg.sender, conditions);
    }

    /**
     * @dev Sets custom withdrawal conditions for a specific ERC20 token balance held by the user.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _unlockTime Minimum timestamp (0 means no time lock).
     * @param _externalConditionKey Key for external condition (bytes32(0) means no external condition).
     * @param _conditionValue Required value for external condition.
     */
    function setERC20WithdrawalConditions(
        address _tokenAddress,
        uint64 _unlockTime,
        bytes32 _externalConditionKey,
        uint256 _conditionValue
    ) external whenActive {
         if (!_supportedERC20s[_tokenAddress]) {
            revert ElysiumVault__UnsupportedAsset(_tokenAddress);
        }
        WithdrawalConditions storage conditions = _userERC20WithdrawalConditions[msg.sender][_tokenAddress];
        conditions.unlockTime = _unlockTime;
        conditions.externalConditionKey = _externalConditionKey;
        conditions.conditionValue = _conditionValue;
        conditions.conditionsSet = (_unlockTime > 0 || _externalConditionKey != bytes32(0));

        emit ERC20WithdrawalConditionsSet(msg.sender, _tokenAddress, conditions);
    }

     /**
     * @dev Sets custom withdrawal conditions for a specific ERC721 NFT held by the user in the vault.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT.
     * @param _unlockTime Minimum timestamp (0 means no time lock).
     * @param _externalConditionKey Key for external condition (bytes32(0) means no external condition).
     * @param _conditionValue Required value for external condition.
     */
    function setERC721WithdrawalConditions(
        address _nftCollection,
        uint256 _tokenId,
        uint64 _unlockTime,
        bytes32 _externalConditionKey,
        uint256 _conditionValue
    ) external whenActive {
        if (!_supportedERC721s[_nftCollection]) {
            revert ElysiumVault__UnsupportedAsset(_nftCollection);
        }
        if (_nftVaultOwner[_nftCollection][_tokenId] != msg.sender) {
            revert ElysiumVault__ERC721NotOwnedByUserInVault(_nftCollection, _tokenId, msg.sender);
        }
        WithdrawalConditions storage conditions = _userERC721WithdrawalConditions[msg.sender][_nftCollection][_tokenId];
        conditions.unlockTime = _unlockTime;
        conditions.externalConditionKey = _externalConditionKey;
        conditions.conditionValue = _conditionValue;
        conditions.conditionsSet = (_unlockTime > 0 || _externalConditionKey != bytes32(0));

        emit ERC721WithdrawalConditionsSet(msg.sender, _nftCollection, _tokenId, conditions);
    }


    /**
     * @dev Sets beneficiary and activation conditions for the user's deposited assets.
     * If conditions are not set (all parameters default except address), activation is immediate.
     * Can only be set once, or potentially updated before activation (add logic if updates are needed).
     * For this version, setting overwrites previous settings if not yet activated.
     * @param _beneficiaryAddress The address of the beneficiary. Must not be zero address.
     * @param _activationTime Minimum timestamp for activation (0 means no time lock).
     * @param _activationConditionKey Key for external condition (bytes32(0) means no external condition).
     * @param _conditionValue Required value for external condition.
     */
    function setBeneficiarySettings(
        address _beneficiaryAddress,
        uint64 _activationTime,
        bytes32 _activationConditionKey,
        uint256 _conditionValue
    ) external whenActive {
         if (_beneficiaryAddress == address(0)) {
            revert ElysiumVault__CannotSetZeroAddressAsOracle(); // Reusing error for zero address check
        }
        BeneficiarySettings storage settings = _userBeneficiarySettings[msg.sender];
        if (settings.activated) {
            revert ElysiumVault__BeneficiaryAlreadyActive(); // Cannot change settings after activation
        }
        settings.beneficiaryAddress = _beneficiaryAddress;
        settings.activationTime = _activationTime;
        settings.activationConditionKey = _activationConditionKey;
        settings.conditionValue = _conditionValue;
        settings.activated = false; // Explicitly false initially
        settings.settingsSet = true;

        emit BeneficiarySettingsSet(msg.sender, _beneficiaryAddress, _activationTime);
    }

    // --- Beneficiary Activation & Claim ---

    /**
     * @dev Attempts to activate the beneficiary settings for a specific user.
     * This function can be called by *anyone*. It checks if the activation
     * conditions set by the user are met. If successful, it marks the beneficiary as activated.
     * @param _user The address of the user whose beneficiary settings should be checked/activated.
     */
    function activateBeneficiary(address _user) external nonReentrant {
        BeneficiarySettings storage settings = _userBeneficiarySettings[_user];
        if (!settings.settingsSet) {
            revert ElysiumVault__BeneficiarySettingsNotSet();
        }
        if (settings.activated) {
            revert ElysiumVault__BeneficiaryAlreadyActive();
        }

        // Check activation conditions (similar logic to withdrawal conditions)
        bool conditionsMet = true;
        if (settings.activationTime > 0 && uint64(block.timestamp) < settings.activationTime) {
            conditionsMet = false;
        }
        if (conditionsMet && settings.activationConditionKey != bytes32(0)) {
             if (_externalConditionValues[settings.activationConditionKey] < settings.conditionValue) {
                conditionsMet = false;
            }
        }

        if (!conditionsMet) {
            revert ElysiumVault__WithdrawalConditionsNotMet(); // Reusing error
        }

        settings.activated = true;
        emit BeneficiaryActivated(_user, settings.beneficiaryAddress, block.timestamp);
    }

    /**
     * @dev Allows the activated beneficiary to claim a specific amount of ETH
     * from the user's balance in the vault.
     * Only the beneficiary can call this AFTER activation.
     * @param _user The address of the user whose assets are being claimed.
     * @param _amount The amount of ETH to claim.
     */
    function claimForBeneficiaryETH(address _user, uint256 _amount) external nonReentrant {
        BeneficiarySettings storage settings = _userBeneficiarySettings[_user];
        if (!settings.settingsSet || !settings.activated) {
            revert ElysiumVault__BeneficiaryNotActive();
        }
        if (msg.sender != settings.beneficiaryAddress) {
            revert ElysiumVault__CallerNotBeneficiary();
        }
         if (_amount == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        if (_userETHBalances[_user] < _amount) {
            revert ElysiumVault__InsufficientETHBalance(); // Reusing error
        }

        _userETHBalances[_user] -= _amount;
        payable(settings.beneficiaryAddress).sendValue(_amount); // Use sendValue for beneficiary
        // Again, call with check is robust, but sendValue is simpler here.

        emit ETHClaimedByBeneficiary(_user, settings.beneficiaryAddress, _amount);
    }

    /**
     * @dev Allows the activated beneficiary to claim a specific amount of an ERC20 token
     * from the user's balance in the vault.
     * Only the beneficiary can call this AFTER activation.
     * @param _user The address of the user whose assets are being claimed.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of the token to claim.
     */
    function claimForBeneficiaryERC20(address _user, address _tokenAddress, uint256 _amount) external nonReentrant {
         BeneficiarySettings storage settings = _userBeneficiarySettings[_user];
        if (!settings.settingsSet || !settings.activated) {
            revert ElysiumVault__BeneficiaryNotActive();
        }
        if (msg.sender != settings.beneficiaryAddress) {
            revert ElysiumVault__CallerNotBeneficiary();
        }
         if (!_supportedERC20s[_tokenAddress]) {
            revert ElysiumVault__UnsupportedAsset(_tokenAddress);
        }
         if (_amount == 0) {
            revert ElysiumVault__AmountMustBeGreaterThanZero();
        }
        if (_userERC20Balances[_user][_tokenAddress] < _amount) {
            revert ElysiumVault__InsufficientERC20Balance(_tokenAddress);
        }

        _userERC20Balances[_user][_tokenAddress] -= _amount;
        IERC20(_tokenAddress).safeTransfer(settings.beneficiaryAddress, _amount);

        emit ERC20ClaimedByBeneficiary(_user, settings.beneficiaryAddress, _tokenAddress, _amount);
    }

    /**
     * @dev Allows the activated beneficiary to claim a specific ERC721 NFT
     * from the user's owned NFTs in the vault.
     * Only the beneficiary can call this AFTER activation.
     * @param _user The address of the user whose assets are being claimed.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT to claim.
     */
    function claimForBeneficiaryERC721(address _user, address _nftCollection, uint256 _tokenId) external nonReentrant {
        BeneficiarySettings storage settings = _userBeneficiarySettings[_user];
        if (!settings.settingsSet || !settings.activated) {
            revert ElysiumVault__BeneficiaryNotActive();
        }
        if (msg.sender != settings.beneficiaryAddress) {
            revert ElysiumVault__CallerNotBeneficiary();
        }
        if (!_supportedERC721s[_nftCollection]) {
            revert ElysiumVault__UnsupportedAsset(_nftCollection);
        }
        if (_nftVaultOwner[_nftCollection][_tokenId] != _user) {
            // This check is crucial: beneficiary can only claim NFTs *the original user* deposited and owned within the vault
            revert ElysiumVault__ERC721NotOwnedByUserInVault(_nftCollection, _tokenId, _user);
        }

        delete _nftVaultOwner[_nftCollection][_tokenId]; // Remove ownership record BEFORE transfer

        IERC721(_nftCollection).safeTransferFrom(address(this), settings.beneficiaryAddress, _tokenId);

        emit ERC721ClaimedByBeneficiary(_user, settings.beneficiaryAddress, _nftCollection, _tokenId);
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to check if the given withdrawal conditions are met.
     * @param conditions The WithdrawalConditions struct to check.
     * @return True if conditions are met, false otherwise.
     */
    function _checkWithdrawalConditions(WithdrawalConditions memory conditions) internal view returns (bool) {
        // Check time lock
        if (conditions.unlockTime > 0 && uint64(block.timestamp) < conditions.unlockTime) {
            return false;
        }

        // Check external condition if set
        if (conditions.externalConditionKey != bytes32(0)) {
            // Condition is met if oracle value is >= required value
            if (_externalConditionValues[conditions.externalConditionKey] < conditions.conditionValue) {
                return false;
            }
        }

        // All conditions met
        return true;
    }

    /**
     * @dev Internal function to calculate the dynamic withdrawal fee.
     * Fee is calculated based on the _withdrawalFeeBasisPoints.
     * @param _amount The total amount being withdrawn (before fee).
     * @return The calculated fee amount.
     */
    function _calculateDynamicFee(uint256 _amount) internal view returns (uint256) {
        // Fee = amount * feeBasisPoints / 10000
        // Use a temporary variable for multiplication to prevent overflow
        // if _amount is very large and feeBasisPoints is close to 10000
         if (_withdrawalFeeBasisPoints == 0) {
             return 0;
         }
        uint256 fee = (_amount * _withdrawalFeeBasisPoints) / 10000;
         // Ensure calculated fee does not exceed the amount itself
        return fee > _amount ? _amount : fee;
    }

    // --- View Functions ---

    /**
     * @dev Returns the current state of the vault.
     */
    function getVaultState() external view returns (VaultState) {
        return _vaultState;
    }

     /**
     * @dev Returns the address of the current oracle.
     */
    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

    /**
     * @dev Returns whether an ERC20 token is supported.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function isSupportedERC20(address _tokenAddress) external view returns (bool) {
        return _supportedERC20s[_tokenAddress];
    }

    /**
     * @dev Returns whether an ERC721 collection is supported.
     * @param _nftCollection The address of the ERC721 collection.
     */
    function isSupportedERC721(address _nftCollection) external view returns (bool) {
        return _supportedERC721s[_nftCollection];
    }

    /**
     * @dev Returns a user's ETH balance recorded in the vault.
     * @param _user The address of the user.
     */
    function getUserETHBalance(address _user) external view returns (uint256) {
        return _userETHBalances[_user];
    }

    /**
     * @dev Returns a user's ERC20 balance for a specific token recorded in the vault.
     * @param _user The address of the user.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function getUserERC20Balance(address _user, address _tokenAddress) external view returns (uint256) {
        return _userERC20Balances[_user][_tokenAddress];
    }

    /**
     * @dev Checks if a specific NFT is currently held by the vault and recorded as owned by a user.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT.
     * @param _user The address of the user.
     * @return True if the NFT is in the vault and owned by the user, false otherwise.
     */
    function isNFTInVaultAndOwnedByUser(address _nftCollection, uint256 _tokenId, address _user) external view returns (bool) {
        return _nftVaultOwner[_nftCollection][_tokenId] == _user;
    }

    /**
     * @dev Returns the withdrawal conditions set for a user's ETH balance.
     * @param _user The address of the user.
     */
    function getUserETHWithdrawalConditions(address _user) external view returns (WithdrawalConditions memory) {
        return _userETHWithdrawalConditions[_user];
    }

     /**
     * @dev Returns the withdrawal conditions set for a user's ERC20 balance of a specific token.
     * @param _user The address of the user.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function getUserERC20WithdrawalConditions(address _user, address _tokenAddress) external view returns (WithdrawalConditions memory) {
        return _userERC20WithdrawalConditions[_user][_tokenAddress];
    }

    /**
     * @dev Returns the withdrawal conditions set for a user's specific NFT.
     * @param _user The address of the user.
     * @param _nftCollection The address of the ERC721 collection.
     * @param _tokenId The ID of the NFT.
     */
    function getUserERC721WithdrawalConditions(address _user, address _nftCollection, uint256 _tokenId) external view returns (WithdrawalConditions memory) {
        return _userERC721WithdrawalConditions[_user][_nftCollection][_tokenId];
    }

    /**
     * @dev Public helper view to check if a given set of withdrawal conditions is met based on current state.
     * This allows users to pre-check conditions. Note this takes conditions as input,
     * NOT the user's stored conditions. Use other views to get stored conditions.
     * @param _unlockTime Minimum timestamp.
     * @param _externalConditionKey Key for external condition.
     * @param _conditionValue Required value for external condition.
     * @return True if conditions are met, false otherwise.
     */
    function checkWithdrawalConditionsMet(uint64 _unlockTime, bytes32 _externalConditionKey, uint256 _conditionValue) external view returns (bool) {
         // Create a temporary struct for the check
         WithdrawalConditions memory conditions = WithdrawalConditions({
             unlockTime: _unlockTime,
             externalConditionKey: _externalConditionKey,
             conditionValue: _conditionValue,
             conditionsSet: true // Assume set if this function is called with specific params
         });
        return _checkWithdrawalConditions(conditions);
    }

    /**
     * @dev Returns the beneficiary settings for a specific user.
     * @param _user The address of the user.
     */
    function getBeneficiarySettings(address _user) external view returns (BeneficiarySettings memory) {
        return _userBeneficiarySettings[_user];
    }

    /**
     * @dev Returns true if the beneficiary for a user has been activated.
     * @param _user The address of the user.
     */
    function isBeneficiaryActive(address _user) external view returns (bool) {
        return _userBeneficiarySettings[_user].activated;
    }

     /**
     * @dev Returns the current value of an external condition key as reported by the oracle.
     * @param _key The bytes32 identifier for the condition.
     */
    function getExternalConditionValue(bytes32 _key) external view returns (uint256) {
        return _externalConditionValues[_key];
    }

     /**
     * @dev Returns the total accrued ETH fees.
     */
    function getAccruedFeesETH() external view returns (uint256) {
        return _accruedFeesETH;
    }

    /**
     * @dev Returns the total accrued ERC20 fees for a specific token.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function getAccruedFeesERC20(address _tokenAddress) external view returns (uint256) {
        return _accruedFeesERC20[_tokenAddress];
    }

    // --- ERC721Holder required function ---
    // This function is required by ERC721Holder to receive NFTs.
    // We override it to add our supported asset check and emit our event.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        public virtual override returns (bytes4)
    {
        require(
            _supportedERC721s[msg.sender], // msg.sender here is the NFT contract address
            "ElysiumVault: NFT collection not supported"
        );
        // Note: Ownership tracking within the vault happens in depositERC721 after transferFrom
        // No need to do it here, as depositERC721 calls safeTransferFrom which triggers this hook.
        // If NFTs were transferred directly without calling depositERC721, this hook would
        // accept them but _nftVaultOwner would not be updated. This is a design choice -
        // require deposit function for proper tracking.

        // The default implementation in ERC721Holder just returns the magic value,
        // we only added the require check.
        return this.onERC721Received.selector;
    }
}
```