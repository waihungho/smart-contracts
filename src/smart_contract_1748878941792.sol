Okay, here is an advanced, multi-asset smart contract concept focusing on conditional releases, internal asset management, and controlled external interactions, designed with over 20 functions. It's called `AdvancedEtherealVault`.

It incorporates concepts like:
1.  **Multi-Asset Holding:** Manages ETH, ERC-20, ERC-721, and ERC-1155 tokens.
2.  **Conditional Releases:** Assets can be locked and released based on various predefined conditions (time, external signal, multisig).
3.  **Internal Asset Transfer:** Allows users to transfer assets between their balances *within* the vault without moving them out and back in.
4.  **Controlled External Interaction:** An owner-controlled mechanism to interact with *approved* external protocols (like DEXs or staking pools) using the vault's assets, mitigating some risks of direct arbitrary calls.
5.  **Batch Operations:** Examples for ERC-20.
6.  **Vault Fees:** A mechanism to collect small fees on certain operations.
7.  **Basic Pausability and Emergency Withdraw:** Standard safety features adapted.
8.  **Multisig Approval:** A condition type requiring multiple vault participants to approve.

This contract is for demonstration and learning purposes. Deploying such a complex contract requires thorough auditing and testing.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. State Variables & Events
//    - Owner, FeeRecipient, FeeRate
//    - Asset balances (ETH, ERC20, ERC721, ERC1155) mappings per user
//    - Conditional Release structs and mappings
//    - Pausability flag, Reentrancy guard
//    - Approved external interactions mapping (conceptual/simplified)
//    - Events for key actions
// 2. Modifiers
//    - onlyOwner, nonReentrant, whenNotPaused
// 3. Constructor
//    - Initialize owner and fee recipient
// 4. Asset Deposit Functions (4 functions)
//    - depositEth, depositErc20, depositErc721, depositErc1155
// 5. Asset Withdrawal Functions (4 functions)
//    - withdrawEth, withdrawErc20, withdrawErc721, withdrawErc1155
// 6. Batch Operations (2 functions)
//    - batchDepositErc20, batchWithdrawErc20
// 7. Conditional Release Functions (4+ functions)
//    - defineConditionalRelease
//    - triggerConditionalRelease
//    - addMultisigApproval (for Multisig condition)
//    - cancelConditionalRelease (by depositor/owner)
// 8. Internal Vault Operations (1 function)
//    - transferVaultAssetInternally
// 9. Controlled External Interaction (1 function)
//    - executeApprovedInteraction (Owner controlled low-level call)
// 10. Vault Management & Fees (4+ functions)
//     - pauseVault, unpauseVault
//     - emergencyOwnerWithdraw
//     - setVaultFeeRecipient, setVaultFeeRate
//     - withdrawVaultFees
// 11. View Functions (Getters) (7+ functions)
//     - getVaultEthBalance, getUserEthBalance
//     - getVaultErc20Balance, getUserErc20Balance
//     - getVaultErc721Owner
//     - getVaultErc1155Balance, getUserErc1155Balance
//     - getConditionalReleaseDetails
//     - getMultisigApprovals
//     - isPaused
//     - getOwner, getFeeRecipient, getFeeRate
//
// Total functions: Constructor (1) + Deposit (4) + Withdraw (4) + Batch (2) + Conditional Release (4) + Internal Transfer (1) + External Interaction (1) + Management/Fees (4) + Views (>=7) = 28+ functions.

// --- Function Summary ---
// constructor(): Initializes the contract owner and default fee recipient.
// depositEth(): Allows sending ETH to the vault, adding it to the user's balance.
// depositErc20(): Deposits ERC-20 tokens into the vault for the user. Requires prior approval.
// depositErc721(): Deposits an ERC-721 token into the vault for the user. Requires prior approval or approval for all.
// depositErc1155(): Deposits ERC-1155 tokens into the vault for the user. Requires prior approval for all.
// withdrawEth(): Withdraws ETH from the user's vault balance.
// withdrawErc20(): Withdraws ERC-20 tokens from the user's vault balance.
// withdrawErc721(): Withdraws an ERC-721 token from the user's vault balance.
// withdrawErc1155(): Withdraws ERC-1155 tokens from the user's vault balance.
// batchDepositErc20(): Deposits multiple types or amounts of ERC-20 tokens in a single transaction.
// batchWithdrawErc20(): Withdraws multiple types or amounts of ERC-20 tokens in a single transaction.
// defineConditionalRelease(): Allows a user to define conditions under which deposited assets can be released to a recipient.
// triggerConditionalRelease(): Checks if the conditions for a specific release are met and executes the transfer if true. Can be called by anyone.
// addMultisigApproval(): Adds an approval for a conditional release of type Multisig.
// cancelConditionalRelease(): Allows the depositor or owner to cancel a pending conditional release.
// transferVaultAssetInternally(): Transfers an asset from the caller's balance within the vault to another user's balance within the vault, without external transfer.
// executeApprovedInteraction(): Owner-controlled function to make a low-level call to an approved external contract using vault assets or ETH. Requires careful whitelisting/parameters in a real scenario.
// pauseVault(): Owner can pause certain operations (deposits, withdrawals, transfers).
// unpauseVault(): Owner can unpause the vault.
// emergencyOwnerWithdraw(): Allows the owner to withdraw all contract ETH and approved ERC-20 tokens in an emergency. Does not handle NFTs or ERC-1155 or user balances.
// setVaultFeeRecipient(): Owner sets the address to receive vault fees.
// setVaultFeeRate(): Owner sets the percentage fee applied to certain operations (e.g., internal transfers, maybe withdrawals).
// withdrawVaultFees(): Fee recipient can withdraw collected fees.
// getVaultEthBalance(): Gets the total ETH balance held by the vault contract.
// getUserEthBalance(): Gets the ETH balance for a specific user held within the vault's tracking.
// getVaultErc20Balance(): Gets the total balance of a specific ERC-20 held by the vault contract.
// getUserErc20Balance(): Gets the balance of a specific ERC-20 for a specific user held within the vault's tracking.
// getVaultErc721Owner(): Checks if the vault owns a specific ERC-721 token by token ID. (Returns owner, which should be this contract if true).
// getVaultErc1155Balance(): Gets the total balance of a specific ERC-1155 token type held by the vault contract.
// getUserErc1155Balance(): Gets the balance of a specific ERC-1155 token type for a specific user held within the vault's tracking.
// getConditionalReleaseDetails(): Retrieves the details of a specific conditional release.
// getMultisigApprovals(): Retrieves the current approvals and required threshold for a Multisig conditional release.
// isPaused(): Checks if the vault is currently paused.
// getOwner(): Returns the contract owner.
// getFeeRecipient(): Returns the current fee recipient address.
// getFeeRate(): Returns the current vault fee rate.

// --- Standard Interfaces (simplified for example, use OpenZeppelin for production) ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data) external returns (bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external returns (bytes4);
}

// --- Error Definitions ---
error NotOwner();
error NotFeeRecipient();
error Paused();
error NotPaused();
error ReentrantCall();
error EthTransferFailed();
error TokenTransferFailed();
error ZeroAmount();
error ZeroAddress();
error InsufficientEthBalance();
error InsufficientErc20Balance();
error InsufficientErc721Balance(); // For vault-level check
error InsufficientErc1155Balance();
error Erc721NotOwnedByVault();
error Erc721NotOwnedByUserInVault(); // User is not the "virtual" owner in vault state
error BatchOperationMismatch();
error ReleaseNotFound();
error ReleaseAlreadyTriggered();
error ReleaseConditionNotMet();
error ReleaseCancelled();
error InvalidReleaseConditionType();
error InvalidMultisigApproval();
error AlreadyApproved();
error InsufficientMultisigApprovalsRequired();
error ReleaseNotCancellable();
error InternalTransferToSelf();
error ExternalInteractionNotApproved();
error CallFailed();
error InvalidFeeRate();
error NoFeesToWithdraw();


contract AdvancedEtherealVault is IERC721, IERC1155 { // Implement NFT/SFT receiver interfaces

    // --- State Variables ---
    address private immutable i_owner;
    address private s_feeRecipient;
    uint256 private s_feeRateBasisPoints; // Fee rate in basis points (e.g., 10 = 0.1%, 100 = 1%)
    uint256 private s_totalFeesCollectedEth;
    mapping(address => mapping(address => uint256)) private s_totalFeesCollectedErc20; // token => amount

    // User balances tracked internally
    mapping(address => uint256) private s_userEthBalances;
    mapping(address => mapping(address => uint256)) private s_userErc20Balances; // user => token => amount
    mapping(address => mapping(uint256 => bool)) private s_userErc721Ownership; // user => tokenId => owned? (Simplified tracking)
    mapping(address => mapping(uint256 => uint256)) private s_userErc1155Balances; // user => id => amount

    // Vault's actual holdings (for ERC721/1155 tracking, ERC20 matches sum of user balances usually)
    mapping(uint256 => address) private s_erc721Owners; // tokenId => userAddress (internal tracking)
    mapping(uint256 => uint256) private s_erc1155TotalSupply; // id => total amount in vault (sum of user balances)

    // Conditional Releases
    enum ConditionType {
        None,
        TimeBased,      // Unlock after a specific timestamp
        ExternalSignal, // Unlock when a specific named boolean signal is set true by owner/oracle
        Multisig        // Unlock when a threshold of vault participants approve
    }

    struct ConditionalRelease {
        bytes32 releaseId; // Unique ID for the release
        address depositor; // User who deposited assets and defined the condition
        address recipient; // Address to receive assets when condition met
        AssetType assetType; // Type of asset (ETH, ERC20, ERC721, ERC1155)
        address assetAddress; // Address of the token contract (0x0 for ETH)
        uint256 tokenId;    // Token ID for ERC721/ERC1155 (0 for ETH/ERC20)
        uint256 amount;     // Amount for ETH/ERC20/ERC1155 (1 for ERC721)
        ConditionType conditionType;
        uint256 unlockTime; // For TimeBased
        bytes32 signalName; // For ExternalSignal
        uint256 requiredApprovals; // For Multisig
        mapping(address => bool) approvals; // For Multisig: approver => approved?
        uint256 currentApprovals; // For Multisig
        bool triggered; // Flag to prevent double triggering
        bool cancelled; // Flag if cancelled
    }

    // Mapping: depositor => releaseId => ConditionalRelease struct
    mapping(address => mapping(bytes32 => ConditionalRelease)) private s_conditionalReleases;

    // External Signals controlled by owner/trusted oracle
    mapping(bytes32 => bool) private s_externalSignals;

    // Approved External Interactions (conceptual whitelist/parameters)
    mapping(address => bool) private s_approvedInteractionTargets; // Address can be called

    // Pausability
    bool private s_paused;

    // Reentrancy Guard
    uint256 private s_nonReentrant = 1;

    // Asset Type Enum
    enum AssetType {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    // --- Events ---
    event EthDeposited(address indexed user, uint256 amount);
    event Erc20Deposited(address indexed user, address indexed token, uint256 amount);
    event Erc721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event Erc1155Deposited(address indexed user, address indexed token, uint256 id, uint256 amount);
    event EthWithdrawal(address indexed user, uint256 amount);
    event Erc20Withdrawal(address indexed user, address indexed token, uint256 amount);
    event Erc721Withdrawal(address indexed user, address indexed token, uint256 tokenId);
    event Erc1155Withdrawal(address indexed user, address indexed token, uint256 id, uint256 amount);
    event InternalTransfer(address indexed fromUser, address indexed toUser, AssetType assetType, address assetAddress, uint256 tokenId, uint256 amount);
    event ConditionalReleaseDefined(address indexed depositor, address indexed recipient, bytes32 releaseId, AssetType assetType, address assetAddress, uint256 tokenId, uint256 amount, ConditionType conditionType);
    event ConditionalReleaseTriggered(address indexed releaseId, address indexed recipient, bytes32 triggeredBy);
    event ConditionalReleaseCancelled(address indexed releaseId, address indexed cancelledBy);
    event MultisigApprovalAdded(address indexed releaseId, address indexed approver, uint256 currentApprovals, uint256 requiredApprovals);
    event ExternalInteractionExecuted(address indexed target, uint256 value, bytes data);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyOwnerWithdrawal(uint256 ethAmount, uint256 numErc20Tokens);
    event FeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event FeeRateSet(uint256 indexed oldRate, uint256 indexed newRate);
    event FeesWithdrawn(address indexed recipient, uint256 ethAmount, uint256 numErc20Tokens);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (s_nonReentrant == 0) revert ReentrantCall();
        s_nonReentrant = 0;
        _;
        s_nonReentrant = 1;
    }

    modifier whenNotPaused() {
        if (s_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor(address initialFeeRecipient, uint256 initialFeeRateBasisPoints) payable {
        if (initialFeeRecipient == address(0)) revert ZeroAddress();
        if (initialFeeRateBasisPoints > 10000) revert InvalidFeeRate(); // Max 100%
        i_owner = msg.sender;
        s_feeRecipient = initialFeeRecipient;
        s_feeRateBasisPoints = initialFeeRateBasisPoints;

        // Any ETH sent during deployment is treated as owner deposit initially
        if (msg.value > 0) {
            s_userEthBalances[msg.sender] += msg.value;
            emit EthDeposited(msg.sender, msg.value);
        }

         // Note: In a real scenario, initialize approvedInteractionTargets
         // s_approvedInteractionTargets[target_address_1] = true;
         // s_approvedInteractionTargets[target_address_2] = true;
    }

    receive() external payable whenNotPaused nonReentrant {
        // Treat direct ETH sends as deposits for the sender
        if (msg.value > 0) {
            s_userEthBalances[msg.sender] += msg.value;
            emit EthDeposited(msg.sender, msg.value);
        }
    }


    // --- 4. Asset Deposit Functions ---

    function depositEth() external payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert ZeroAmount();
        s_userEthBalances[msg.sender] += msg.value;
        emit EthDeposited(msg.sender, msg.value);
    }

    function depositErc20(address _tokenAddress, uint256 _amount) external whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        IERC20 token = IERC20(_tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        // transferFrom requires sender to have approved this contract
        if (!token.transferFrom(msg.sender, address(this), _amount)) revert TokenTransferFailed();
        uint256 actualTransferAmount = token.balanceOf(address(this)) - balanceBefore; // Account for potential transfer fees
        if (actualTransferAmount == 0) revert TokenTransferFailed(); // Check if transfer actually happened

        s_userErc20Balances[msg.sender][_tokenAddress] += actualTransferAmount;
        emit Erc20Deposited(msg.sender, _tokenAddress, actualTransferAmount);
    }

    function depositErc721(address _tokenAddress, uint256 _tokenId) external whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress();
        // The ERC721 standard requires the contract to implement onERC721Received to receive tokens.
        // safeTransferFrom from the user to this contract is the standard way.
        // This function acts as a wrapper/entry point for the user action.
        // The actual balance update happens in onERC721Received.
        IERC721 token = IERC721(_tokenAddress);
        // Check if user is owner (or approved) - safeTransferFrom will handle this, but explicit check improves error clarity
        if (token.ownerOf(_tokenId) != msg.sender && !token.isApprovedForAll(msg.sender, address(this)) && token.getApproved(_tokenId) != address(this) ) {
            // Note: getApproved might not exist on all ERC721 implementations, isApprovedForAll is safer.
            // Or simply rely on safeTransferFrom revert. Let's rely on safeTransferFrom.
        }

        token.safeTransferFrom(msg.sender, address(this), _tokenId);
        // Actual tracking update happens in onERC721Received
        emit Erc721Deposited(msg.sender, _tokenAddress, _tokenId);
    }

    // ERC721 Receiver Hook
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        // Only accept transfers from ERC721 contracts
        require(msg.sender.code.length > 0, "ERC721: transfer caller is not contract"); // Basic check

        // Track internal ownership for the 'from' address
        s_userErc721Ownership[from][tokenId] = true;
        s_erc721Owners[tokenId] = from;

        return this.onERC721Received.selector;
    }

    function depositErc1155(address _tokenAddress, uint256 _id, uint256 _amount, bytes calldata _data) external whenNotPaused nonReentrant {
         if (_tokenAddress == address(0)) revert ZeroAddress();
         if (_amount == 0) revert ZeroAmount();
         // Similar to ERC721, the actual balance update happens in onERC1155Received/BatchReceived
         // This function is the entry point for the user calling safeTransferFrom
         IERC1155 token = IERC1155(_tokenAddress);
         // isApprovedForAll check
         if (!token.isApprovedForAll(msg.sender, address(this))) {
              // Rely on safeTransferFrom to revert if not approved
         }

         token.safeTransferFrom(msg.sender, address(this), _id, _amount, _data);
         // Actual tracking update happens in onERC1155Received/BatchReceived
         emit Erc1155Deposited(msg.sender, _tokenAddress, _id, _amount);
    }

     function depositErc1155Batch(address _tokenAddress, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external whenNotPaused nonReentrant {
         if (_tokenAddress == address(0)) revert ZeroAddress();
         if (_ids.length == 0 || _ids.length != _amounts.length) revert BatchOperationMismatch();

         IERC1155 token = IERC1155(_tokenAddress);
         if (!token.isApprovedForAll(msg.sender, address(this))) {
              // Rely on safeBatchTransferFrom to revert
         }

         token.safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, _data);
         // Actual tracking update happens in onERC1155Received/BatchReceived
         for(uint i = 0; i < _ids.length; i++) {
              emit Erc1155Deposited(msg.sender, _tokenAddress, _ids[i], _amounts[i]);
         }
    }

    // ERC1155 Receiver Hooks
    function onERC1155Received(address, address from, uint256 id, uint256 amount, bytes calldata) external override returns (bytes4) {
        require(msg.sender.code.length > 0, "ERC1155: transfer caller is not contract"); // Basic check

        // Track internal balance for the 'from' address
        s_userErc1155Balances[from][id] += amount;
        s_erc1155TotalSupply[id] += amount;

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata) external override returns (bytes4) {
        require(msg.sender.code.length > 0, "ERC1155: transfer caller is not contract"); // Basic check
        if (ids.length != amounts.length) revert BatchOperationMismatch();

        // Track internal balances for the 'from' address
        for (uint i = 0; i < ids.length; i++) {
            s_userErc1155Balances[from][ids[i]] += amounts[i];
            s_erc1155TotalSupply[ids[i]] += amounts[i];
        }

        return this.onERC1155BatchReceived.selector;
    }


    // --- 5. Asset Withdrawal Functions ---

    function withdrawEth(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (s_userEthBalances[msg.sender] < _amount) revert InsufficientEthBalance();

        s_userEthBalances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
             // Revert balance update if ETH transfer fails
            s_userEthBalances[msg.sender] += _amount;
            revert EthTransferFailed();
        }
        emit EthWithdrawal(msg.sender, _amount);
    }

    function withdrawErc20(address _tokenAddress, uint256 _amount) external whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        if (s_userErc20Balances[msg.sender][_tokenAddress] < _amount) revert InsufficientErc20Balance();

        s_userErc20Balances[msg.sender][_tokenAddress] -= _amount;

        IERC20 token = IERC20(_tokenAddress);
        if (!token.transfer(msg.sender, _amount)) {
            // Revert balance update if token transfer fails
             s_userErc20Balances[msg.sender][_tokenAddress] += _amount;
             revert TokenTransferFailed();
        }
        emit Erc20Withdrawal(msg.sender, _tokenAddress, _amount);
    }

    function withdrawErc721(address _tokenAddress, uint256 _tokenId) external whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress();
        // Check if user virtually owns the NFT in the vault state
        if (!s_userErc721Ownership[msg.sender][_tokenId]) revert Erc721NotOwnedByUserInVault();
        // Double-check if the vault actually owns the token (redundant if deposits are only way in, but safe)
         if (IERC721(_tokenAddress).ownerOf(_tokenId) != address(this)) revert Erc721NotOwnedByVault();


        s_userErc721Ownership[msg.sender][_tokenId] = false; // Update virtual ownership
        delete s_erc721Owners[_tokenId]; // Remove from vault's tracking map

        IERC721 token = IERC721(_tokenAddress);
        token.safeTransferFrom(address(this), msg.sender, _tokenId); // Transfer from vault to user
        emit Erc721Withdrawal(msg.sender, _tokenAddress, _tokenId);
    }

    function withdrawErc1155(address _tokenAddress, uint256 _id, uint256 _amount) external whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        if (s_userErc1155Balances[msg.sender][_id] < _amount) revert InsufficientErc1155Balance();

        s_userErc1155Balances[msg.sender][_id] -= _amount;
        s_erc1155TotalSupply[_id] -= _amount; // Update vault's total tracking

        IERC1155 token = IERC1155(_tokenAddress);
        // Safe transfer from vault to user
        token.safeTransferFrom(address(this), msg.sender, _id, _amount, "");
        emit Erc1155Withdrawal(msg.sender, _tokenAddress, _id, _amount);
    }


    // --- 6. Batch Operations ---

    function batchDepositErc20(address[] calldata _tokenAddresses, uint256[] calldata _amounts) external whenNotPaused nonReentrant {
        if (_tokenAddresses.length == 0 || _tokenAddresses.length != _amounts.length) revert BatchOperationMismatch();

        for (uint i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint256 amount = _amounts[i];

            if (tokenAddress == address(0)) revert ZeroAddress(); // Ensure no zero addresses in batch
            if (amount == 0) continue; // Skip zero amount deposits

            IERC20 token = IERC20(tokenAddress);
            uint256 balanceBefore = token.balanceOf(address(this));
            if (!token.transferFrom(msg.sender, address(this), amount)) revert TokenTransferFailed();
            uint256 actualTransferAmount = token.balanceOf(address(this)) - balanceBefore; // Account for fees
            if (actualTransferAmount == 0 && amount > 0) revert TokenTransferFailed(); // Check if transfer actually happened

            s_userErc20Balances[msg.sender][tokenAddress] += actualTransferAmount;
            emit Erc20Deposited(msg.sender, tokenAddress, actualTransferAmount);
        }
    }

    function batchWithdrawErc20(address[] calldata _tokenAddresses, uint256[] calldata _amounts) external whenNotPaused nonReentrant {
        if (_tokenAddresses.length == 0 || _tokenAddresses.length != _amounts.length) revert BatchOperationMismatch();

        for (uint i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint256 amount = _amounts[i];

            if (tokenAddress == address(0)) revert ZeroAddress(); // Ensure no zero addresses in batch
             if (amount == 0) continue; // Skip zero amount withdrawals

            if (s_userErc20Balances[msg.sender][tokenAddress] < amount) revert InsufficientErc20Balance();

            s_userErc20Balances[msg.sender][tokenAddress] -= amount;

            IERC20 token = IERC20(tokenAddress);
             if (!token.transfer(msg.sender, amount)) {
                // Revert all previous balance updates in this batch if any transfer fails (requires careful consideration or different pattern)
                // For simplicity in this example, we re-add the current token's balance and revert.
                // A more robust batch system might require checkpointing or separate tx for each withdrawal.
                 s_userErc20Balances[msg.sender][tokenAddress] += amount;
                 revert TokenTransferFailed();
            }
            emit Erc20Withdrawal(msg.sender, tokenAddress, amount);
        }
    }


    // --- 7. Conditional Release Functions ---

    function defineConditionalRelease(
        bytes32 _releaseId, // User-defined unique ID
        address _recipient,
        AssetType _assetType,
        address _assetAddress, // 0x0 for ETH
        uint256 _tokenId,    // 0 for ETH/ERC20
        uint256 _amount,     // 1 for ERC721
        ConditionType _conditionType,
        uint256 _unlockTime, // For TimeBased
        bytes32 _signalName, // For ExternalSignal
        uint256 _requiredApprovals // For Multisig
    ) external whenNotPaused nonReentrant {
        if (_releaseId == bytes32(0)) revert ZeroAddress(); // Using bytes32(0) as indicator
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount == 0 && _assetType != AssetType.ERC721) revert ZeroAmount();
        if (_assetType == AssetType.ERC721 && _amount != 1) revert InvalidReleaseConditionType(); // ERC721 amount must be 1

        // Check if release ID already exists for this depositor
        if (s_conditionalReleases[msg.sender][_releaseId].releaseId != bytes32(0)) revert ReleaseAlreadyTriggered(); // Using triggered flag/ID existence

        // Check if depositor has enough balance to define the release
        if (_assetType == AssetType.ETH) {
            if (s_userEthBalances[msg.sender] < _amount) revert InsufficientEthBalance();
            s_userEthBalances[msg.sender] -= _amount; // Deduct from balance immediately
        } else if (_assetType == AssetType.ERC20) {
            if (_assetAddress == address(0)) revert ZeroAddress();
            if (s_userErc20Balances[msg.sender][_assetAddress] < _amount) revert InsufficientErc20Balance();
            s_userErc20Balances[msg.sender][_assetAddress] -= _amount; // Deduct
        } else if (_assetType == AssetType.ERC721) {
            if (_assetAddress == address(0)) revert ZeroAddress();
            if (!s_userErc721Ownership[msg.sender][_tokenId]) revert Erc721NotOwnedByUserInVault();
            s_userErc721Ownership[msg.sender][_tokenId] = false; // Deduct virtual ownership
            delete s_erc721Owners[_tokenId]; // Remove from vault's direct tracking ownership (transferred to pending release state)
        } else if (_assetType == AssetType.ERC1155) {
             if (_assetAddress == address(0)) revert ZeroAddress();
            if (s_userErc1155Balances[msg.sender][_id] < _amount) revert InsufficientErc1155Balance();
            s_userErc1155Balances[msg.sender][_assetAddress] -= _amount; // Deduct
            s_erc1155TotalSupply[_id] -= _amount; // Deduct from vault total
        } else {
             revert InvalidReleaseConditionType();
        }

        // Store the release details
        ConditionalRelease storage release = s_conditionalReleases[msg.sender][_releaseId];
        release.releaseId = _releaseId;
        release.depositor = msg.sender;
        release.recipient = _recipient;
        release.assetType = _assetType;
        release.assetAddress = _assetAddress;
        release.tokenId = _tokenId;
        release.amount = _amount;
        release.conditionType = _conditionType;
        release.unlockTime = _unlockTime;
        release.signalName = _signalName;
        release.requiredApprovals = _requiredApprovals;
        release.currentApprovals = 0;
        release.triggered = false;
        release.cancelled = false;

        // Basic validation for condition parameters
        if (_conditionType == ConditionType.TimeBased && _unlockTime == 0) revert InvalidReleaseConditionType();
        if (_conditionType == ConditionType.ExternalSignal && _signalName == bytes32(0)) revert InvalidReleaseConditionType();
        if (_conditionType == ConditionType.Multisig && _requiredApprovals == 0) revert InvalidReleaseConditionType();
        if (_conditionType == ConditionType.Multisig && _recipient == address(0)) revert InvalidReleaseConditionType(); // Recipient must be set for multisig


        emit ConditionalReleaseDefined(
            msg.sender,
            _recipient,
            _releaseId,
            _assetType,
            _assetAddress,
            _tokenId,
            _amount,
            _conditionType
        );
    }

    function checkConditionStatus(address _depositor, bytes32 _releaseId) public view returns (bool conditionMet, bool releaseExists, bool triggered, bool cancelled) {
         ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];

         releaseExists = (release.releaseId != bytes32(0));
         if (!releaseExists) return (false, false, false, false); // Release not found

         triggered = release.triggered;
         cancelled = release.cancelled;

         if (triggered || cancelled) return (false, true, triggered, cancelled); // Already triggered or cancelled

         // Check condition based on type
         if (release.conditionType == ConditionType.TimeBased) {
             conditionMet = block.timestamp >= release.unlockTime;
         } else if (release.conditionType == ConditionType.ExternalSignal) {
             conditionMet = s_externalSignals[release.signalName];
         } else if (release.conditionType == ConditionType.Multisig) {
              conditionMet = release.currentApprovals >= release.requiredApprovals;
         } else {
             conditionMet = false; // Unknown or None type
         }

         return (conditionMet, true, triggered, cancelled);
    }


    function triggerConditionalRelease(address _depositor, bytes32 _releaseId) external nonReentrant {
         ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];

         if (release.releaseId == bytes32(0)) revert ReleaseNotFound();
         if (release.triggered) revert ReleaseAlreadyTriggered();
         if (release.cancelled) revert ReleaseCancelled();

         (bool conditionMet,,, bool cancelledCheck) = checkConditionStatus(_depositor, _releaseId);
         if (!conditionMet) revert ReleaseConditionNotMet();
         if (cancelledCheck) revert ReleaseCancelled(); // Double check cancellation


         release.triggered = true; // Mark as triggered immediately

         // Execute the transfer
         if (release.assetType == AssetType.ETH) {
             (bool success, ) = payable(release.recipient).call{value: release.amount}("");
             if (!success) {
                // Revert triggered status if transfer fails
                release.triggered = false;
                revert EthTransferFailed();
             }
         } else if (release.assetType == AssetType.ERC20) {
              IERC20 token = IERC20(release.assetAddress);
             if (!token.transfer(release.recipient, release.amount)) {
                release.triggered = false; // Revert triggered status
                revert TokenTransferFailed();
             }
         } else if (release.assetType == AssetType.ERC721) {
             IERC721 token = IERC721(release.assetAddress);
             token.safeTransferFrom(address(this), release.recipient, release.tokenId); // Transfer from vault to recipient
              // Note: ERC721 tracking is simpler, we don't need to 'revert' virtual ownership here on fail,
              // as safeTransferFrom will revert the whole transaction including the 'triggered' flag update.
         } else if (release.assetType == AssetType.ERC1155) {
              IERC1155 token = IERC1155(release.assetAddress);
              token.safeTransferFrom(address(this), release.recipient, release.tokenId, release.amount, ""); // Transfer from vault to recipient
               // Same logic as ERC721 regarding revert.
         } else {
              // This should not happen if defineConditionalRelease validates correctly, but as a safeguard:
             release.triggered = false;
             revert InvalidReleaseConditionType();
         }

         emit ConditionalReleaseTriggered(_releaseId, release.recipient, bytes32(uint256(uint160(msg.sender)))); // Log sender bytes32 truncated

         // Clean up or mark as completed (leaving triggered=true is sufficient for checkConditionStatus)
         // Optional: delete s_conditionalReleases[_depositor][_releaseId];
    }

    function addMultisigApproval(address _depositor, bytes32 _releaseId) external whenNotPaused nonReentrant {
         ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];

         if (release.releaseId == bytes32(0)) revert ReleaseNotFound();
         if (release.triggered) revert ReleaseAlreadyTriggered();
         if (release.cancelled) revert ReleaseCancelled();
         if (release.conditionType != ConditionType.Multisig) revert InvalidMultisigApproval();
         if (msg.sender == release.depositor || msg.sender == release.recipient) revert InvalidMultisigApproval(); // Depositor/Recipient cannot approve

         // Anyone can approve if they are a valid 'participant' in the vault (e.g., hold some assets)
         // For simplicity, any address that isn't depositor/recipient can approve here.
         // In a real system, this might be restricted to a specific set of addresses (e.g., DAO members).

         if (release.approvals[msg.sender]) revert AlreadyApproved(); // Cannot approve twice

         release.approvals[msg.sender] = true;
         release.currentApprovals++;

         emit MultisigApprovalAdded(_releaseId, msg.sender, release.currentApprovals, release.requiredApprovals);

         // Optional: Automatically trigger if threshold is met
         if (release.currentApprovals >= release.requiredApprovals) {
             triggerConditionalRelease(_depositor, _releaseId);
         }
    }

    function cancelConditionalRelease(address _depositor, bytes32 _releaseId) external whenNotPaused nonReentrant {
         ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];

         if (release.releaseId == bytes32(0)) revert ReleaseNotFound();
         if (release.triggered) revert ReleaseAlreadyTriggered();
         if (release.cancelled) revert ReleaseCancelled();
         if (msg.sender != release.depositor && msg.sender != i_owner) revert ReleaseNotCancellable(); // Only depositor or owner can cancel

         release.cancelled = true; // Mark as cancelled

         // Return assets to depositor's internal balance
         if (release.assetType == AssetType.ETH) {
             s_userEthBalances[release.depositor] += release.amount;
         } else if (release.assetType == AssetType.ERC20) {
             s_userErc20Balances[release.depositor][release.assetAddress] += release.amount;
         } else if (release.assetType == AssetType.ERC721) {
              s_userErc721Ownership[release.depositor][release.tokenId] = true; // Restore virtual ownership
              s_erc721Owners[release.tokenId] = release.depositor; // Restore vault tracking ownership
         } else if (release.assetType == AssetType.ERC1155) {
              s_userErc1155Balances[release.depositor][release.assetAddress] += release.amount; // Restore balance
              s_erc1155TotalSupply[release.tokenId] += release.amount; // Restore vault total
         } // else InvalidReleaseConditionType, but already validated on definition

         emit ConditionalReleaseCancelled(_releaseId, bytes32(uint256(uint160(msg.sender))));
    }


    // --- 8. Internal Vault Operations ---

    function transferVaultAssetInternally(address _toUser, AssetType _assetType, address _assetAddress, uint256 _tokenId, uint256 _amount) external whenNotPaused nonReentrant {
         if (_toUser == address(0)) revert ZeroAddress();
         if (_toUser == msg.sender) revert InternalTransferToSelf();
         if (_amount == 0 && _assetType != AssetType.ERC721) revert ZeroAmount();
         if (_assetType == AssetType.ERC721 && _amount != 1) revert InvalidReleaseConditionType(); // ERC721 amount must be 1

         uint256 feeAmount = 0;
         if (s_feeRateBasisPoints > 0) {
             // Apply fee only on internal transfers? Or withdrawals? Let's apply to internal transfers for demo.
             // Fee calculation depends on asset type and amount. Simplified here.
             // Could make fees configurable per asset type.
             if (_assetType == AssetType.ETH || _assetType == AssetType.ERC20) {
                 feeAmount = (_amount * s_feeRateBasisPoints) / 10000;
                 if (_amount < feeAmount) feeAmount = _amount; // Cap fee at amount
             } // No fees on NFTs/SFTs for simplicity in this example
         }
         uint256 amountToSend = _amount - feeAmount;


         if (_assetType == AssetType.ETH) {
             if (s_userEthBalances[msg.sender] < _amount) revert InsufficientEthBalance();
             s_userEthBalances[msg.sender] -= _amount;
             s_userEthBalances[_toUser] += amountToSend;
             if (feeAmount > 0) s_totalFeesCollectedEth += feeAmount;
         } else if (_assetType == AssetType.ERC20) {
             if (_assetAddress == address(0)) revert ZeroAddress();
             if (s_userErc20Balances[msg.sender][_assetAddress] < _amount) revert InsufficientErc20Balance();
             s_userErc20Balances[msg.sender][_assetAddress] -= _amount;
             s_userErc20Balances[_toUser][_assetAddress] += amountToSend;
             if (feeAmount > 0) s_totalFeesCollectedErc20[_assetAddress][address(0)] += feeAmount; // Collect fees under zero address for token
         } else if (_assetType == AssetType.ERC721) {
             if (_assetAddress == address(0)) revert ZeroAddress();
             if (!s_userErc721Ownership[msg.sender][_tokenId]) revert Erc721NotOwnedByUserInVault();
             s_userErc721Ownership[msg.sender][_tokenId] = false; // Remove virtual ownership from sender
             s_userErc721Ownership[_toUser][_tokenId] = true; // Add virtual ownership to recipient
              s_erc721Owners[_tokenId] = _toUser; // Update vault's internal tracking ownership
         } else if (_assetType == AssetType.ERC1155) {
              if (_assetAddress == address(0)) revert ZeroAddress();
              if (s_userErc1155Balances[msg.sender][_tokenId] < _amount) revert InsufficientErc1155Balance();
              s_userErc1155Balances[msg.sender][_tokenId] -= _amount;
              s_userErc1155Balances[_toUser][_tokenId] += _amount; // No fee on SFT for this demo
              // Total supply tracking doesn't change for internal SFT transfer
         } else {
             revert InvalidReleaseConditionType(); // Should not happen with valid AssetType
         }

         emit InternalTransfer(msg.sender, _toUser, _assetType, _assetAddress, _tokenId, _amount);
         // Optionally emit FeeCollected event
    }


    // --- 9. Controlled External Interaction ---

    function executeApprovedInteraction(address _target, uint256 _value, bytes calldata _data) external onlyOwner nonReentrant {
        if (_target == address(0)) revert ZeroAddress();
        // In a real contract, s_approvedInteractionTargets should be populated by the owner
        // with addresses of trusted protocols (DEX routers, staking pools, etc.)
        // and potentially require stricter controls on _data based on the target.
        // For this example, we'll skip the s_approvedInteractionTargets check, assuming the owner
        // uses this function responsibly and knows _target is approved.
        // if (!s_approvedInteractionTargets[_target]) revert ExternalInteractionNotApproved(); // Example check

        // Value check
        if (_value > address(this).balance) revert InsufficientEthBalance();


        // Use low-level call. This is powerful and risky.
        // It allows interacting with any contract provided the target and calldata.
        // Only the owner can call this, and should only use it with trusted targets and validated calldata.
        (bool success, bytes memory returnData) = _target.call{value: _value}(_data);

        if (!success) {
            // Attempt to decode revert reason or return raw data
            if (returnData.length > 0) {
                // Try to decode Error(string)
                try abi.decode(returnData, (string)) returns (string memory reason) {
                    revert(string(abi.encodePacked("External call failed: ", reason)));
                } catch {
                    // If decoding fails, revert with raw data
                    revert(string(abi.encodePacked("External call failed with data: ", returnData)));
                }
            } else {
                revert CallFailed();
            }
        }

        emit ExternalInteractionExecuted(_target, _value, _data);
        // Note: ETH/token transfers executed by the external call are not tracked by the vault state,
        // potentially desyncing internal balances from actual contract balances if not handled carefully
        // within the _data logic or external contract interaction pattern.
        // This function is best used for owner-driven rebalancing/yield farming strategies.
    }


    // --- 10. Vault Management & Fees ---

    function pauseVault() external onlyOwner whenNotPaused {
        s_paused = true;
        emit Paused(msg.sender);
    }

    function unpauseVault() external onlyOwner whenPaused {
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    function emergencyOwnerWithdraw(address[] calldata _erc20Tokens) external onlyOwner nonReentrant {
         // This withdraws ALL ETH and specified ERC20s from the contract's balance,
         // NOT user-tracked balances or conditional release amounts.
         // It's meant for emergencies if contract logic is frozen or needs draining.
         // Does NOT handle ERC721 or ERC1155.
         uint256 ethBalance = address(this).balance;
         if (ethBalance > 0) {
             (bool success, ) = payable(msg.sender).call{value: ethBalance}("");
             if (!success) revert EthTransferFailed(); // Transaction reverts if ETH fails
         }

         for (uint i = 0; i < _erc20Tokens.length; i++) {
             address tokenAddress = _erc20Tokens[i];
             if (tokenAddress == address(0)) continue;
             IERC20 token = IERC20(tokenAddress);
             uint256 tokenBalance = token.balanceOf(address(this));
             if (tokenBalance > 0) {
                 if (!token.transfer(msg.sender, tokenBalance)) {
                     // Log failure but continue with other tokens? Or revert all?
                     // Reverting all on single token failure is safer usually.
                     revert TokenTransferFailed();
                 }
             }
         }
         emit EmergencyOwnerWithdrawal(ethBalance, _erc20Tokens.length);
    }

     function setVaultFeeRecipient(address _newRecipient) external onlyOwner {
         if (_newRecipient == address(0)) revert ZeroAddress();
         emit FeeRecipientSet(s_feeRecipient, _newRecipient);
         s_feeRecipient = _newRecipient;
     }

     function setVaultFeeRate(uint256 _newRateBasisPoints) external onlyOwner {
         if (_newRateBasisPoints > 10000) revert InvalidFeeRate();
         emit FeeRateSet(s_feeRateBasisPoints, _newRateBasisPoints);
         s_feeRateBasisPoints = _newRateBasisPoints;
     }

    function withdrawVaultFees(address[] calldata _erc20Tokens) external nonReentrant {
        if (msg.sender != s_feeRecipient) revert NotFeeRecipient();

        uint256 ethFees = s_totalFeesCollectedEth;
        s_totalFeesCollectedEth = 0; // Reset ETH fees immediately

        if (ethFees > 0) {
            (bool success, ) = payable(s_feeRecipient).call{value: ethFees}("");
             if (!success) {
                 s_totalFeesCollectedEth += ethFees; // Restore balance if transfer fails
                 revert EthTransferFailed();
             }
        }

        uint256 numErc20FeesWithdrawn = 0;
        for (uint i = 0; i < _erc20Tokens.length; i++) {
            address tokenAddress = _erc20Tokens[i];
            if (tokenAddress == address(0)) continue;

            uint256 tokenFees = s_totalFeesCollectedErc20[tokenAddress][address(0)];
            if (tokenFees > 0) {
                s_totalFeesCollectedErc20[tokenAddress][address(0)] = 0; // Reset token fees

                 IERC20 token = IERC20(tokenAddress);
                 if (!token.transfer(s_feeRecipient, tokenFees)) {
                      // Restore fee balance if transfer fails
                      s_totalFeesCollectedErc20[tokenAddress][address(0)] += tokenFees;
                      // Decide whether to revert the whole transaction or log and continue
                      // For simplicity, we'll revert the whole transaction on first failure
                      revert TokenTransferFailed();
                 }
                 numErc20FeesWithdrawn++;
            }
        }

        if (ethFees == 0 && numErc20FeesWithdrawn == 0) revert NoFeesToWithdraw();

        emit FeesWithdrawn(s_feeRecipient, ethFees, numErc20FeesWithdrawn);
    }


    // --- 11. View Functions (Getters) ---

    function getVaultEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserEthBalance(address _user) external view returns (uint256) {
        return s_userEthBalances[_user];
    }

    function getVaultErc20Balance(address _tokenAddress) external view returns (uint256) {
         if (_tokenAddress == address(0)) return 0;
         return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getUserErc20Balance(address _user, address _tokenAddress) external view returns (uint256) {
         if (_user == address(0) || _tokenAddress == address(0)) return 0;
         return s_userErc20Balances[_user][_tokenAddress];
    }

     function getVaultErc721Owner(uint256 _tokenId) external view returns (address) {
        // This returns the user address who virtually owns the token in the vault
        // The actual owner is always the vault contract itself if it holds the token.
        return s_erc721Owners[_tokenId];
     }

    function getVaultErc1155Balance(address _tokenAddress, uint256 _id) external view returns (uint256) {
         if (_tokenAddress == address(0)) return 0;
         return s_erc1155TotalSupply[_id]; // Total amount in the vault
    }

    function getUserErc1155Balance(address _user, address _tokenAddress, uint256 _id) external view returns (uint256) {
         if (_user == address(0) || _tokenAddress == address(0)) return 0;
         return s_userErc1155Balances[_user][_id];
    }

    function getConditionalReleaseDetails(address _depositor, bytes32 _releaseId) external view returns (
        bytes32 releaseId,
        address depositor,
        address recipient,
        AssetType assetType,
        address assetAddress,
        uint256 tokenId,
        uint256 amount,
        ConditionType conditionType,
        uint256 unlockTime,
        bytes32 signalName,
        uint256 requiredApprovals,
        uint256 currentApprovals,
        bool triggered,
        bool cancelled
    ) {
        ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];
        return (
            release.releaseId,
            release.depositor,
            release.recipient,
            release.assetType,
            release.assetAddress,
            release.tokenId,
            release.amount,
            release.conditionType,
            release.unlockTime,
            release.signalName,
            release.requiredApprovals,
            release.currentApprovals,
            release.triggered,
            release.cancelled
        );
    }

    function getMultisigApprovals(address _depositor, bytes32 _releaseId, address[] calldata _checkApprovers) external view returns (bool[] memory approvedStatus) {
         ConditionalRelease storage release = s_conditionalReleases[_depositor][_releaseId];
         approvedStatus = new bool[](_checkApprovers.length);
         for(uint i = 0; i < _checkApprovers.length; i++) {
             approvedStatus[i] = release.approvals[_checkApprovers[i]];
         }
         // Note: This view function iterates through provided addresses.
         // Retrieving *all* approvers without providing addresses is not possible/efficient in Solidity mappings.
         // You'd need to track approvers in an array inside the struct if you needed to list them all.
         return approvedStatus;
    }

     function isPaused() external view returns (bool) {
         return s_paused;
     }

     function getOwner() external view returns (address) {
         return i_owner;
     }

     function getFeeRecipient() external view returns (address) {
         return s_feeRecipient;
     }

     function getFeeRate() external view returns (uint256) {
         return s_feeRateBasisPoints;
     }

     function getVaultEthFeesCollected() external view returns (uint256) {
         return s_totalFeesCollectedEth;
     }

     function getVaultErc20FeesCollected(address _tokenAddress) external view returns (uint256) {
         if (_tokenAddress == address(0)) return 0;
         return s_totalFeesCollectedErc20[_tokenAddress][address(0)];
     }

      // Owner controlled signal setter for ExternalSignal condition type
      function setExternalSignal(bytes32 _signalName, bool _status) external onlyOwner {
          if (_signalName == bytes32(0)) revert ZeroAddress();
          s_externalSignals[_signalName] = _status;
          // Optional: Event for signal change
      }

      // View function to check an external signal status
      function getExternalSignalStatus(bytes32 _signalName) external view returns (bool) {
          return s_externalSignals[_signalName];
      }
}

```