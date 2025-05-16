Okay, let's design an advanced and creative smart contract. We'll call it the `QuantumVault`. The concept is a highly customizable vault that releases assets (ETH or ERC20s) only when *multiple, diverse, and potentially external conditions* are simultaneously met. This goes beyond simple time-locks or multisigs by allowing integration with oracles, proofs, roles, signatures, and more.

It's "Quantum" in the sense that access depends on a combination of seemingly unrelated, multi-dimensional factors being aligned, rather than any relation to quantum computing itself.

We will leverage:
1.  **Complex Conditional Logic:** Multiple condition types (`TimeLock`, `OracleCheck`, `ProofSubmission`, `SignatureVerification`, `RoleCheck`).
2.  **External Data Integration:** Mechanisms to incorporate data from oracles or off-chain proofs.
3.  **Role-Based Condition Fulfillment:** Specific addresses might be required to provide proofs or data.
4.  **Multi-Asset Support:** Holding and distributing different types of assets.
5.  **Partial Claims:** Recipients can claim their share incrementally as conditions are met.
6.  **Configurable Recipients:** Assets distributed to specific addresses with defined shares.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary libraries (OpenZeppelin for Ownable, Pausable, SafeERC20, ReentrancyGuard).
2.  **Interfaces:** Define interface for ERC20 tokens.
3.  **Errors:** Custom error definitions.
4.  **Enums:** Define `ConditionType`.
5.  **Structs:**
    *   `Condition`: Defines a single requirement (type, status, parameters).
    *   `Recipient`: Defines an address and their proportional share.
    *   `VaultAsset`: Defines an asset (address) and total amount held in the vault.
    *   `Vault`: Aggregates all details for a single locked vault (depositor, assets, recipients, conditions).
6.  **State Variables:**
    *   Owner, vault counter.
    *   Mappings for vaults, total locked assets, claimed amounts per recipient/asset.
    *   Addresses for trusted roles (oracle, proof verifier, signer).
    *   Mapping for condition roles.
7.  **Events:** Notify listeners about key actions (Vault creation, asset added, condition met, claim, role changes).
8.  **Modifiers:** `onlyOwner`, `vaultExists`, `onlyRole`, `whenNotPaused`, `whenPaused`, `nonReentrant`.
9.  **Constructor:** Set initial owner.
10. **Core Vault Management Functions:**
    *   `createVault`: Create a new vault with assets, recipients, and conditions.
    *   `addAssetsToVault`: Add more assets to an existing vault.
    *   `cancelVault`: Cancel a vault and return assets to the depositor (if conditions unmet/not claimed).
11. **Condition Management & Fulfillment Functions:**
    *   `checkVaultConditionsMet`: Check if *all* conditions for a vault are currently met. (View)
    *   `getVaultConditionStatus`: Get the status of each *individual* condition. (View)
    *   `provideProofForCondition`: Fulfill a `ProofSubmission` condition.
    *   `updateOracleDataForCondition`: Fulfill an `OracleCheck` condition (called by trusted oracle address).
    *   `provideSignatureForCondition`: Fulfill a `SignatureVerification` condition.
    *   `setTrustedAddresses`: Set trusted addresses for Oracle, Proof Verifier, Signature Signer.
12. **Recipient Claim Functions:**
    *   `claimAssets`: Allow a recipient to claim their share if all conditions are met.
    *   `getRecipientClaimableAmount`: Calculate how much a recipient can currently claim from a vault. (View)
13. **Role Management Functions:**
    *   `grantConditionRole`: Grant an address a specific role required for certain conditions.
    *   `revokeConditionRole`: Revoke a specific role.
    *   `hasConditionRole`: Check if an address has a role. (View)
14. **View Functions (Getters):**
    *   `getVaultDetails`: Retrieve all details of a vault.
    *   `getVaultAssetBalance`: Get the current balance of a specific asset within a vault.
    *   `getTotalLockedBalanceETH`: Total ETH held by the contract.
    *   `getTotalLockedBalanceERC20`: Total of a specific ERC20 held.
    *   `listVaultIds`: Get a list of all active vault IDs.
15. **Emergency/Admin Functions:**
    *   `pause`: Pause certain contract operations.
    *   `unpause`: Unpause contract operations.
    *   `emergencyWithdrawETH`: Owner emergency withdrawal of ETH.
    *   `emergencyWithdrawERC20`: Owner emergency withdrawal of ERC20.
    *   `transferOwnership`: Transfer contract ownership.
    *   `renounceOwnership`: Renounce contract ownership.

**Function Summary (at least 20 functions):**

1.  `constructor()`: Deploys the contract and sets the initial owner.
2.  `createVault(VaultAsset[] _assets, Recipient[] _recipients, Condition[] _conditions)`: Creates a new secure vault. Deposits required assets into the contract. Defines the conditions that must be met for withdrawal and the recipients who can claim with their shares.
3.  `addAssetsToVault(uint256 _vaultId, VaultAsset[] _assets)`: Allows the original depositor to add more assets to an existing vault.
4.  `cancelVault(uint256 _vaultId)`: Allows the owner or original depositor to cancel a vault and retrieve remaining assets, provided no claims have been made from it yet.
5.  `checkVaultConditionsMet(uint256 _vaultId)`: *View function*. Checks if *all* conditions defined for a specific vault ID are currently marked as met.
6.  `getVaultConditionStatus(uint256 _vaultId, uint256 _conditionIndex)`: *View function*. Returns the specific details and met status of a single condition within a vault.
7.  `provideProofForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes32 _proofHash)`: Called by an address with the `PROOF_PROVIDER_ROLE`. Updates a `ProofSubmission` condition to 'met' if the provided hash matches the required hash stored in the condition data. (Requires off-chain knowledge to compute the preimage).
8.  `updateOracleDataForCondition(uint256 _vaultId, uint256 _conditionIndex, uint256 _oracleValue)`: Called by the trusted `oracleAddress`. Updates an `OracleCheck` condition to 'met' if the provided `_oracleValue` meets the criteria defined in the condition data (e.g., greater than a threshold).
9.  `provideSignatureForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes memory _signature)`: Called by an address with the `SIGNATURE_PROVIDER_ROLE`. Verifies the provided ECDSA `_signature` against a predefined message (hashed vault ID + condition index) signed by the trusted `signatureSignerAddress`. Marks condition as 'met' if valid.
10. `setTrustedAddresses(address _oracle, address _proofVerifier, address _signatureSigner)`: Owner function to set the addresses trusted for fulfilling `OracleCheck`, `ProofSubmission`, and `SignatureVerification` conditions globally.
11. `claimAssets(uint256 _vaultId)`: Allows a recipient of the vault to claim their proportional share of assets *if* all conditions for the vault are met. Handles partial claims based on already claimed amounts.
12. `getRecipientClaimableAmount(uint256 _vaultId, address _recipientAddress, address _assetAddress)`: *View function*. Calculates the remaining amount of a specific asset that a given recipient is eligible to claim from a vault, based on their share and already claimed amounts (does *not* check if conditions are met).
13. `grantConditionRole(address _address, bytes32 _role)`: Owner function to grant a specific role (e.g., `PROOF_PROVIDER_ROLE`, `SIGNATURE_PROVIDER_ROLE`) to an address, allowing them to fulfill corresponding condition types across any vault.
14. `revokeConditionRole(address _address, bytes32 _role)`: Owner function to revoke a specific role from an address.
15. `hasConditionRole(address _address, bytes32 _role)`: *View function*. Checks if an address has a specific condition fulfillment role.
16. `getVaultDetails(uint256 _vaultId)`: *View function*. Returns comprehensive details about a specific vault (depositor, assets, recipients, conditions).
17. `getVaultAssetBalance(uint256 _vaultId, address _assetAddress)`: *View function*. Returns the current total balance of a specific asset held within a given vault ID.
18. `getTotalLockedBalanceETH()`: *View function*. Returns the total amount of native ETH currently held by the contract across all vaults.
19. `getTotalLockedBalanceERC20(address _assetAddress)`: *View function*. Returns the total amount of a specific ERC20 token currently held by the contract across all vaults.
20. `listVaultIds()`: *View function*. Returns an array of all active vault IDs managed by the contract.
21. `pause()`: Owner function to pause sensitive operations (claiming, adding assets).
22. `unpause()`: Owner function to unpause contract operations.
23. `emergencyWithdrawETH(uint256 _amount, address _recipient)`: Owner function to withdraw ETH in case of emergency while the contract is paused. Bypasses vault conditions.
24. `emergencyWithdrawERC20(address _tokenAddress, uint256 _amount, address _recipient)`: Owner function to withdraw ERC20 tokens in case of emergency while the contract is paused. Bypasses vault conditions.
25. `transferOwnership(address newOwner)`: Standard OpenZeppelin function to transfer contract ownership.
26. `renounceOwnership()`: Standard OpenZeppelin function to renounce contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// QuantumVault Smart Contract
//
// Outline:
// 1. Pragma and Imports
// 2. Interfaces
// 3. Errors
// 4. Enums: Define ConditionType
// 5. Structs: Condition, Recipient, VaultAsset, Vault
// 6. State Variables: Owner, vault counter, mappings for vaults, balances, claimed amounts, roles, trusted addresses.
// 7. Events: Notify about key actions.
// 8. Modifiers: Standard access control and state checks.
// 9. Constructor: Initialize contract owner.
// 10. Core Vault Management Functions: Create, add assets, cancel.
// 11. Condition Management & Fulfillment Functions: Check status, provide proofs/data, set trusted addresses.
// 12. Recipient Claim Functions: Claim assets, check claimable amount.
// 13. Role Management Functions: Grant/revoke/check condition roles.
// 14. View Functions (Getters): Retrieve vault/balance details, list vaults.
// 15. Emergency/Admin Functions: Pause, unpause, emergency withdraw, ownership transfer.
//
// Function Summary (at least 20 functions):
// 1. constructor()
// 2. createVault(VaultAsset[] _assets, Recipient[] _recipients, Condition[] _conditions)
// 3. addAssetsToVault(uint256 _vaultId, VaultAsset[] _assets)
// 4. cancelVault(uint256 _vaultId)
// 5. checkVaultConditionsMet(uint256 _vaultId) (View)
// 6. getVaultConditionStatus(uint256 _vaultId, uint256 _conditionIndex) (View)
// 7. provideProofForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes32 _proofHash)
// 8. updateOracleDataForCondition(uint256 _vaultId, uint256 _conditionIndex, uint256 _oracleValue)
// 9. provideSignatureForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes memory _signature)
// 10. setTrustedAddresses(address _oracle, address _proofVerifier, address _signatureSigner)
// 11. claimAssets(uint256 _vaultId)
// 12. getRecipientClaimableAmount(uint256 _vaultId, address _recipientAddress, address _assetAddress) (View)
// 13. grantConditionRole(address _address, bytes32 _role)
// 14. revokeConditionRole(address _address, bytes32 _role)
// 15. hasConditionRole(address _address, bytes32 _role) (View)
// 16. getVaultDetails(uint256 _vaultId) (View)
// 17. getVaultAssetBalance(uint256 _vaultId, address _assetAddress) (View)
// 18. getTotalLockedBalanceETH() (View)
// 19. getTotalLockedBalanceERC20(address _assetAddress) (View)
// 20. listVaultIds() (View)
// 21. pause()
// 22. unpause()
// 23. emergencyWithdrawETH(uint256 _amount, address _recipient)
// 24. emergencyWithdrawERC20(address _tokenAddress, uint256 _amount, address _recipient)
// 25. transferOwnership(address newOwner)
// 26. renounceOwnership()


contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // --- Errors ---
    error VaultDoesNotExist(uint256 vaultId);
    error VaultAlreadyClaimed(uint256 vaultId);
    error ConditionsNotMet(uint256 vaultId);
    error InvalidShareDistribution();
    error NoAssetsToClaim();
    error ZeroAmount();
    error ConditionNotFound(uint256 vaultId, uint256 conditionIndex);
    error ConditionAlreadyMet(uint256 vaultId, uint256 conditionIndex);
    error InvalidConditionType(uint256 conditionType);
    error ProofMismatch(uint256 vaultId, uint256 conditionIndex);
    error SignatureVerificationFailed(uint256 vaultId, uint256 conditionIndex);
    error UnauthorizedConditionFulfillment(bytes32 requiredRole);
    error NotDepositorOrOwner();
    error VaultNotEmpty(uint256 vaultId);
    error CannotAddAssetsToClaimedVault(uint256 vaultId);
    error InsufficientAssetAmount(address assetAddress, uint256 requested, uint256 available);
    error InvalidRecipientShare(address recipient);
    error InvalidTrustedAddress();

    // --- Enums ---
    enum ConditionType {
        TimeLock,          // value = unlock timestamp
        OracleCheck,       // value = minimum/exact value, targetAddress = oracle address, data = abi encoded call? Or simple value check. Let's do simple value check.
        ProofSubmission,   // data = required hash (bytes32), targetAddress = required prover role holder or specific address
        SignatureVerification, // data = predefined message hash, targetAddress = address whose signature is required
        RoleCheck          // value = ignored, targetAddress = address to check, data = role hash (bytes32)
    }

    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        bool met;
        uint256 value;       // Used for time lock (timestamp), oracle check (threshold/value)
        address targetAddress; // Used for Oracle, Proof, Signature (verifier/signer address), Role Check (address with role)
        bytes data;          // Used for Proof (required hash), Signature (message hash)
        string description;  // Optional description for clarity
    }

    struct Recipient {
        address addr;
        uint256 share; // e.g., percentage * 100 (for 100% total = 10000)
    }

    struct VaultAsset {
        address assetAddress; // address(0) for ETH
        uint256 totalAmount;
    }

    struct Vault {
        address depositor;
        VaultAsset[] assets;
        Recipient[] recipients;
        Condition[] conditions;
        bool isCancelled;
        // Note: isClaimed status is implicitly managed by claimedAmounts mapping
    }

    // --- State Variables ---
    uint256 private _vaultCounter;
    mapping(uint256 => Vault) private _vaults;
    mapping(uint256 => mapping(address => mapping(address => uint256))) private _claimedAmounts; // vaultId => recipient => assetAddress => amountClaimed
    mapping(address => mapping(bytes32 => bool)) private _conditionRoles; // address => roleHash => hasRole
    mapping(uint256 => bool) private _activeVaultIds; // Simple way to track active IDs
    uint256[] private _vaultIds; // Array to list active vault IDs

    // Trusted addresses for condition fulfillment - set by owner
    address public oracleAddress;
    address public proofVerifierAddress; // Address expected to call provideProofForCondition
    address public signatureSignerAddress; // Address whose signature is verified

    // Role definitions (example hashes)
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");
    bytes32 public constant PROOF_PROVIDER_ROLE = keccak256("PROOF_PROVIDER_ROLE");
    bytes32 public constant SIGNATURE_PROVIDER_ROLE = keccak256("SIGNATURE_PROVIDER_ROLE");

    // --- Events ---
    event VaultCreated(uint256 indexed vaultId, address indexed depositor, address[] assetAddresses, uint256[] assetAmounts);
    event AssetsAddedToVault(uint256 indexed vaultId, address indexed caller, address[] assetAddresses, uint256[] assetAmounts);
    event VaultCancelled(uint256 indexed vaultId, address indexed caller, address indexed depositor);
    event ConditionStatusUpdated(uint256 indexed vaultId, uint256 indexed conditionIndex, bool newStatus);
    event AssetsClaimed(uint256 indexed vaultId, address indexed recipient, address indexed assetAddress, uint256 amount);
    event RoleGranted(address indexed account, bytes32 indexed role, address indexed grantor);
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed revoker);
    event TrustedAddressesSet(address oracle, address proofVerifier, address signatureSigner);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event EmergencyWithdrawal(address indexed assetAddress, uint256 amount, address indexed recipient);

    // --- Modifiers ---
    modifier vaultExists(uint256 _vaultId) {
        if (_vaults[_vaultId].depositor == address(0) || _vaults[_vaultId].isCancelled) {
            revert VaultDoesNotExist(_vaultId);
        }
        _;
    }

    modifier onlyRole(bytes32 role) {
        if (!_conditionRoles[msg.sender][role] && owner() != msg.sender) { // Owner can bypass roles
             revert UnauthorizedConditionFulfillment(role);
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        _vaultCounter = 0;
    }

    // --- Core Vault Management Functions ---

    /**
     * @notice Creates a new vault, deposits assets, defines recipients and required conditions.
     * @param _assets Array of VaultAsset structs specifying assets and amounts. ETH is address(0).
     * @param _recipients Array of Recipient structs specifying recipients and their share.
     * @param _conditions Array of Condition structs defining unlock requirements.
     */
    function createVault(VaultAsset[] memory _assets, Recipient[] memory _recipients, Condition[] memory _conditions)
        public
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 vaultId)
    {
        if (_assets.length == 0 || _recipients.length == 0 || _conditions.length == 0) {
            revert ZeroAmount(); // Or more specific error
        }

        // Validate recipient shares
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i].addr == address(0)) revert InvalidRecipientShare(address(0));
            totalShares += _recipients[i].share;
        }
        if (totalShares == 0) revert InvalidShareDistribution(); // Shares must sum up to a non-zero value

        // Calculate total ETH and ERC20 values being sent
        uint256 totalEthAmount = 0;
        mapping(address => uint256) totalErc20Amounts;
        address[] memory assetAddresses = new address[](_assets.length);
        uint256[] memory assetAmounts = new uint256[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i].totalAmount == 0) revert ZeroAmount();
            assetAddresses[i] = _assets[i].assetAddress;
            assetAmounts[i] = _assets[i].totalAmount;

            if (_assets[i].assetAddress == address(0)) {
                totalEthAmount += _assets[i].totalAmount;
            } else {
                totalErc20Amounts[_assets[i].assetAddress] += _assets[i].totalAmount;
            }
        }

        // Verify received ETH matches declared amount
        if (msg.value != totalEthAmount) revert InsufficientAssetAmount(address(0), totalEthAmount, msg.value);

        // Verify and transfer ERC20 tokens
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i].assetAddress != address(0)) {
                // Ensure the contract is approved to transfer tokens *before* calling this function
                // Or use permit() flow if tokens support it. Standard is require allowance.
                IERC20 token = IERC20(_assets[i].assetAddress);
                if (token.allowance(msg.sender, address(this)) < _assets[i].totalAmount) {
                     revert InsufficientAssetAmount(_assets[i].assetAddress, _assets[i].totalAmount, token.allowance(msg.sender, address(this)));
                }
                token.safeTransferFrom(msg.sender, address(this), _assets[i].totalAmount);
            }
        }

        // Increment vault counter and store vault
        vaultId = ++_vaultCounter;
        _vaults[vaultId].depositor = msg.sender;
        _vaults[vaultId].assets = _assets; // Store asset amounts as declared
        _vaults[vaultId].recipients = _recipients;
        _vaults[vaultId].conditions = _conditions; // Store conditions initially unmet

        _activeVaultIds[vaultId] = true;
        _vaultIds.push(vaultId);

        emit VaultCreated(vaultId, msg.sender, assetAddresses, assetAmounts);
    }

    /**
     * @notice Adds more assets to an existing vault. Only callable by the original depositor.
     * @param _vaultId The ID of the vault.
     * @param _assets Array of VaultAsset structs specifying assets and amounts to add.
     */
    function addAssetsToVault(uint256 _vaultId, VaultAsset[] memory _assets)
        public
        payable
        vaultExists(_vaultId)
        whenNotPaused
        nonReentrant
    {
        Vault storage vault = _vaults[_vaultId];
        if (msg.sender != vault.depositor) revert NotDepositorOrOwner();
        // Cannot add assets if vault has already been cancelled or fully claimed
        if (vault.isCancelled) revert VaultDoesNotExist(_vaultId); // Vault is cancelled
        // Check if any asset in the vault has been fully claimed
        for(uint i=0; i < vault.assets.length; i++) {
            uint256 totalClaimedForAsset = 0;
            for(uint j=0; j < vault.recipients.length; j++){
                totalClaimedForAsset += _claimedAmounts[_vaultId][vault.recipients[j].addr][vault.assets[i].assetAddress];
            }
            if(totalClaimedForAsset >= vault.assets[i].totalAmount) revert CannotAddAssetsToClaimedVault(_vaultId);
        }


        uint256 totalEthAmount = 0;
        address[] memory assetAddresses = new address[](_assets.length);
        uint256[] memory assetAmounts = new uint256[](_assets.length);

        mapping(address => uint256) amountsToAdd;
         for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i].totalAmount == 0) revert ZeroAmount();
             amountsToAdd[_assets[i].assetAddress] += _assets[i].totalAmount; // Sum up amounts for same asset
             assetAddresses[i] = _assets[i].assetAddress; // for event
             assetAmounts[i] = _assets[i].totalAmount; // for event
        }


        for (uint265 i = 0; i < _assets.length; i++) {
            if (_assets[i].assetAddress == address(0)) {
                totalEthAmount += _assets[i].totalAmount;
            } else {
                 // No need to check allowance here if adding directly to contract, but need transferFrom
            }
        }

        // Verify received ETH matches declared amount
        if (msg.value != totalEthAmount) revert InsufficientAssetAmount(address(0), totalEthAmount, msg.value);

         // Update total amounts in the vault struct
        for (uint256 i = 0; i < _assets.length; i++) {
            bool found = false;
            for(uint j = 0; j < vault.assets.length; j++){
                if(vault.assets[j].assetAddress == _assets[i].assetAddress){
                    vault.assets[j].totalAmount += _assets[i].totalAmount;
                    found = true;
                    break;
                }
            }
            // If asset not previously in the vault, add it
            if(!found) {
                 vault.assets.push(_assets[i]);
            }

             // Transfer ERC20 tokens if applicable
            if (_assets[i].assetAddress != address(0)) {
                IERC20 token = IERC20(_assets[i].assetAddress);
                 // Ensure the contract is approved to transfer tokens *before* calling this function
                // Or use permit() flow. Standard is require allowance.
                if (token.allowance(msg.sender, address(this)) < _assets[i].totalAmount) {
                     revert InsufficientAssetAmount(_assets[i].assetAddress, _assets[i].totalAmount, token.allowance(msg.sender, address(this)));
                }
                token.safeTransferFrom(msg.sender, address(this), _assets[i].totalAmount);
            }
        }

        emit AssetsAddedToVault(_vaultId, msg.sender, assetAddresses, assetAmounts);
    }

    /**
     * @notice Allows the depositor or owner to cancel a vault and retrieve remaining assets.
     * Can only be cancelled if no assets have been claimed yet.
     * @param _vaultId The ID of the vault to cancel.
     */
    function cancelVault(uint256 _vaultId)
        public
        vaultExists(_vaultId)
        whenNotPaused
        nonReentrant
    {
        Vault storage vault = _vaults[_vaultId];
        if (msg.sender != vault.depositor && msg.sender != owner()) revert NotDepositorOrOwner();

        // Check if any assets have been claimed
        for (uint i = 0; i < vault.assets.length; i++) {
            address currentAsset = vault.assets[i].assetAddress;
            for (uint j = 0; j < vault.recipients.length; j++) {
                if (_claimedAmounts[_vaultId][vault.recipients[j].addr][currentAsset] > 0) {
                    revert VaultNotEmpty(_vaultId); // Assets have already been claimed
                }
            }
        }

        vault.isCancelled = true;
        // Remove from active vault list - expensive loop, maybe keep mapping? Yes, mapping is better.
        _activeVaultIds[_vaultId] = false;

        // Transfer assets back to depositor
        for (uint i = 0; i < vault.assets.length; i++) {
            address currentAsset = vault.assets[i].assetAddress;
            uint256 remainingAmount = vault.assets[i].totalAmount; // No claims, so total == remaining

            if (remainingAmount > 0) {
                 if (currentAsset == address(0)) {
                    (bool success, ) = payable(vault.depositor).call{value: remainingAmount}("");
                    if (!success) {
                         // This is critical - handle ETH transfer failure.
                         // Ideally re-attempt or have a recovery mechanism.
                         // For simplicity here, we just revert.
                        revert InsufficientAssetAmount(currentAsset, 0, remainingAmount); // Use InsufficientAssetAmount for lack of a better specific error
                    }
                } else {
                    IERC20 token = IERC20(currentAsset);
                    token.safeTransfer(vault.depositor, remainingAmount);
                }
            }
        }

        emit VaultCancelled(_vaultId, msg.sender, vault.depositor);
        // Vault data remains for historical lookup, just marked cancelled
    }


    // --- Condition Management & Fulfillment Functions ---

    /**
     * @notice Checks if all conditions for a specific vault ID are currently met.
     * @param _vaultId The ID of the vault.
     * @return bool True if all conditions are met, false otherwise.
     */
    function checkVaultConditionsMet(uint256 _vaultId)
        public
        view
        vaultExists(_vaultId)
        returns (bool)
    {
        Vault storage vault = _vaults[_vaultId];
        for (uint i = 0; i < vault.conditions.length; i++) {
            // Note: The `met` flag in the struct tracks if the specific fulfillment
            // function (e.g., provideProof) has been called successfully.
            // TimeLock conditions are checked directly here.
            if (vault.conditions[i].conditionType == ConditionType.TimeLock) {
                if (block.timestamp < vault.conditions[i].value) {
                    return false; // TimeLock not met
                }
            } else if (!vault.conditions[i].met) {
                return false; // Other conditions must be explicitly marked as met
            }
        }
        return true; // All conditions met
    }

    /**
     * @notice Gets the status and details of a single condition within a vault.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition in the vault's conditions array.
     * @return condition The Condition struct details.
     */
    function getVaultConditionStatus(uint256 _vaultId, uint256 _conditionIndex)
        public
        view
        vaultExists(_vaultId)
        returns (Condition memory)
    {
        Vault storage vault = _vaults[_vaultId];
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);
        return vault.conditions[_conditionIndex];
    }


    /**
     * @notice Fulfills a ProofSubmission condition by providing a hash.
     * Requires the caller to have the PROOF_PROVIDER_ROLE or be the contract owner.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the ProofSubmission condition.
     * @param _proofHash The hash that satisfies the condition.
     */
    function provideProofForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes32 _proofHash)
        public
        onlyRole(PROOF_PROVIDER_ROLE)
        vaultExists(_vaultId)
        whenNotPaused
        nonReentrant
    {
        Vault storage vault = _vaults[_vaultId];
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);
        Condition storage condition = vault.conditions[_conditionIndex];

        if (condition.conditionType != ConditionType.ProofSubmission) revert InvalidConditionType(uint256(condition.conditionType));
        if (condition.met) revert ConditionAlreadyMet(_vaultId, _conditionIndex);

        // The data in the condition is the required hash (bytes32)
        if (condition.data.length != 32) revert ProofMismatch(_vaultId, _conditionIndex); // Should not happen if set correctly
        bytes32 requiredHash = bytes32(condition.data);

        if (_proofHash != requiredHash) revert ProofMismatch(_vaultId, _conditionIndex);

        condition.met = true;
        emit ConditionStatusUpdated(_vaultId, _conditionIndex, true);
    }

    /**
     * @notice Fulfills an OracleCheck condition by providing an oracle value.
     * Requires the caller to be the trusted oracleAddress or the contract owner.
     * This is a simplified example; a real oracle integration would be more complex.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the OracleCheck condition.
     * @param _oracleValue The value provided by the oracle.
     */
    function updateOracleDataForCondition(uint256 _vaultId, uint256 _conditionIndex, uint256 _oracleValue)
        public
        vaultExists(_vaultId)
        whenNotPaused
        nonReentrant
    {
         // Only trusted oracle address or owner can call this
        if (msg.sender != oracleAddress && msg.sender != owner()) revert UnauthorizedConditionFulfillment(ORACLE_UPDATER_ROLE);


        Vault storage vault = _vaults[_vaultId];
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);
        Condition storage condition = vault.conditions[_conditionIndex];

        if (condition.conditionType != ConditionType.OracleCheck) revert InvalidConditionType(uint256(condition.conditionType));
        if (condition.met) revert ConditionAlreadyMet(_vaultId, _conditionIndex);

        // Example check: is oracle value >= required value?
        if (_oracleValue < condition.value) {
            // Condition still not met, could log this
            return;
        }

        condition.met = true;
        emit ConditionStatusUpdated(_vaultId, _conditionIndex, true);
    }

     /**
     * @notice Fulfills a SignatureVerification condition by providing a signature.
     * Requires the caller to have the SIGNATURE_PROVIDER_ROLE or be the contract owner.
     * Verifies the signature against a standard message hash signed by the trusted signatureSignerAddress.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the SignatureVerification condition.
     * @param _signature The ECDSA signature bytes.
     */
    function provideSignatureForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes memory _signature)
        public
        onlyRole(SIGNATURE_PROVIDER_ROLE)
        vaultExists(_vaultId)
        whenNotPaused
        nonReentrant
    {
        Vault storage vault = _vaults[_vaultId];
        if (_conditionIndex >= vault.conditions.length) revert ConditionNotFound(_vaultId, _conditionIndex);
        Condition storage condition = vault.conditions[_conditionIndex];

        if (condition.conditionType != ConditionType.SignatureVerification) revert InvalidConditionType(uint256(condition.conditionType));
        if (condition.met) revert ConditionAlreadyMet(_vaultId, _conditionIndex);

        // Define the message hash that was expected to be signed
        // Using vaultId and conditionIndex makes each required signature unique
        bytes32 messageHash = keccak256(abi.encodePacked(vault.depositor, _vaultId, _conditionIndex, "QuantumVaultSignatureVerification"));
        bytes32 prefixedMessageHash = messageHash.toEthSignedMessageHash();

        // Recover the signer's address
        address signer = prefixedMessageHash.recover(_signature);

        // Check if the recovered signer is the trusted address or owner (owner bypass role check implicitly)
        if (signer != signatureSignerAddress && owner() != msg.sender) revert SignatureVerificationFailed(_vaultId, _conditionIndex);


        condition.met = true;
        emit ConditionStatusUpdated(_vaultId, _conditionIndex, true);
    }

    /**
     * @notice Sets the trusted addresses for specific condition types. Only callable by the owner.
     * @param _oracle The address of the trusted oracle.
     * @param _proofVerifier The address expected to provide proofs.
     * @param _signatureSigner The address whose signature will be verified.
     */
    function setTrustedAddresses(address _oracle, address _proofVerifier, address _signatureSigner)
        public
        onlyOwner
    {
        if (_oracle == address(0) || _proofVerifier == address(0) || _signatureSigner == address(0)) {
            revert InvalidTrustedAddress();
        }
        oracleAddress = _oracle;
        proofVerifierAddress = _proofVerifier;
        signatureSignerAddress = _signatureSigner;

        // Grant roles to the designated addresses automatically (owner also has implicit role)
        _conditionRoles[proofVerifierAddress][PROOF_PROVIDER_ROLE] = true;
        _conditionRoles[oracleAddress][ORACLE_UPDATER_ROLE] = true;
        _conditionRoles[signatureSignerAddress][SIGNATURE_PROVIDER_ROLE] = true;

        emit TrustedAddressesSet(_oracle, _proofVerifier, _signatureSigner);
    }


    // --- Recipient Claim Functions ---

    /**
     * @notice Allows a recipient to claim their share of assets from a vault.
     * All vault conditions must be met.
     * @param _vaultId The ID of the vault to claim from.
     */
    function claimAssets(uint256 _vaultId)
        public
        nonReentrant
        whenNotPaused
        vaultExists(_vaultId)
    {
        Vault storage vault = _vaults[_vaultId];

        // Check if caller is a valid recipient
        bool isRecipient = false;
        uint256 recipientShare = 0;
        for (uint i = 0; i < vault.recipients.length; i++) {
            if (vault.recipients[i].addr == msg.sender) {
                isRecipient = true;
                recipientShare = vault.recipients[i].share;
                break;
            }
        }
        if (!isRecipient) revert InvalidRecipientShare(msg.sender); // Not a recipient

        // Check if all conditions are met
        if (!checkVaultConditionsMet(_vaultId)) revert ConditionsNotMet(_vaultId);

        bool assetsTransferred = false;

        for (uint i = 0; i < vault.assets.length; i++) {
            address assetAddress = vault.assets[i].assetAddress;
            uint256 totalVaultAmount = vault.assets[i].totalAmount;
            uint256 totalShares = 0;
            for(uint j=0; j < vault.recipients.length; j++){
                totalShares += vault.recipients[j].share;
            }

            // Calculate total amount this recipient is entitled to for this asset
            // Handle potential precision loss by doing multiplication first
            uint256 recipientTotalEntitlement = (totalVaultAmount * recipientShare) / totalShares;

            // Calculate amount already claimed by this recipient for this asset
            uint256 claimed = _claimedAmounts[_vaultId][msg.sender][assetAddress];

            // Calculate the remaining claimable amount for this asset
            uint256 amountToTransfer = recipientTotalEntitlement - claimed;

            if (amountToTransfer > 0) {
                // Update claimed amount BEFORE transfer to prevent reentrancy issues
                _claimedAmounts[_vaultId][msg.sender][assetAddress] += amountToTransfer;

                if (assetAddress == address(0)) {
                    (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
                     if (!success) {
                        // CRITICAL: ETH transfer failed. Revert claimed amount update.
                        _claimedAmounts[_vaultId][msg.sender][assetAddress] -= amountToTransfer;
                         revert InsufficientAssetAmount(assetAddress, 0, amountToTransfer); // Use InsufficientAssetAmount for lack of a better specific error
                     }
                } else {
                    IERC20 token = IERC20(assetAddress);
                    // safeTransfer will revert on failure
                    token.safeTransfer(msg.sender, amountToTransfer);
                }
                assetsTransferred = true;
                emit AssetsClaimed(_vaultId, msg.sender, assetAddress, amountToTransfer);
            }
        }

        if (!assetsTransferred) revert NoAssetsToClaim(); // Either already claimed or entitlement is zero
    }

     /**
     * @notice Calculates the remaining amount of a specific asset a recipient can claim.
     * Does NOT check if vault conditions are met.
     * @param _vaultId The ID of the vault.
     * @param _recipientAddress The address of the recipient.
     * @param _assetAddress The address of the asset (address(0) for ETH).
     * @return uint256 The amount claimable.
     */
    function getRecipientClaimableAmount(uint256 _vaultId, address _recipientAddress, address _assetAddress)
        public
        view
        vaultExists(_vaultId)
        returns (uint256)
    {
        Vault storage vault = _vaults[_vaultId];

        // Find recipient share
        uint256 recipientShare = 0;
        bool isRecipient = false;
         for (uint i = 0; i < vault.recipients.length; i++) {
            if (vault.recipients[i].addr == _recipientAddress) {
                isRecipient = true;
                recipientShare = vault.recipients[i].share;
                break;
            }
        }
        if (!isRecipient) return 0; // Not a recipient

        // Find total asset amount in vault
        uint256 totalVaultAmount = 0;
        bool assetFound = false;
        for (uint i = 0; i < vault.assets.length; i++) {
            if (vault.assets[i].assetAddress == _assetAddress) {
                totalVaultAmount = vault.assets[i].totalAmount;
                assetFound = true;
                break;
            }
        }
        if (!assetFound || totalVaultAmount == 0) return 0; // Asset not in vault or total amount is zero

        // Calculate total shares for this vault
        uint256 totalShares = 0;
        for(uint j=0; j < vault.recipients.length; j++){
            totalShares += vault.recipients[j].share;
        }
        if (totalShares == 0) return 0; // Should not happen if vault created correctly

        // Calculate total amount this recipient is entitled to for this asset
        uint256 recipientTotalEntitlement = (totalVaultAmount * recipientShare) / totalShares;

        // Calculate amount already claimed by this recipient for this asset
        uint256 claimed = _claimedAmounts[_vaultId][_recipientAddress][_assetAddress];

        // Calculate the remaining claimable amount
        return recipientTotalEntitlement > claimed ? recipientTotalEntitlement - claimed : 0;
    }


    // --- Role Management Functions ---

    /**
     * @notice Grants a specific condition fulfillment role to an address. Only owner can grant roles.
     * @param _address The address to grant the role to.
     * @param _role The role hash (e.g., PROOF_PROVIDER_ROLE).
     */
    function grantConditionRole(address _address, bytes32 _role)
        public
        onlyOwner
    {
        if (_address == address(0)) revert InvalidTrustedAddress();
        _conditionRoles[_address][_role] = true;
        emit RoleGranted(_address, _role, msg.sender);
    }

    /**
     * @notice Revokes a specific condition fulfillment role from an address. Only owner can revoke roles.
     * @param _address The address to revoke the role from.
     * @param _role The role hash (e.g., PROOF_PROVIDER_ROLE).
     */
    function revokeConditionRole(address _address, bytes32 _role)
        public
        onlyOwner
    {
        if (_address == address(0)) revert InvalidTrustedAddress();
        _conditionRoles[_address][_role] = false;
        emit RoleRevoked(_address, _role, msg.sender);
    }

    /**
     * @notice Checks if an address has a specific condition fulfillment role. Owner implicitly has all roles.
     * @param _address The address to check.
     * @param _role The role hash.
     * @return bool True if the address has the role or is the owner, false otherwise.
     */
    function hasConditionRole(address _address, bytes32 _role)
        public
        view
        returns (bool)
    {
        return _conditionRoles[_address][_role] || _address == owner();
    }


    // --- View Functions (Getters) ---

    /**
     * @notice Returns all details for a specific vault.
     * @param _vaultId The ID of the vault.
     * @return Vault struct containing vault details.
     */
    function getVaultDetails(uint256 _vaultId)
        public
        view
        vaultExists(_vaultId)
        returns (Vault memory)
    {
        return _vaults[_vaultId];
    }

    /**
     * @notice Returns the current total balance of a specific asset within a vault.
     * This is the *remaining* amount after claims, if any.
     * @param _vaultId The ID of the vault.
     * @param _assetAddress The address of the asset (address(0) for ETH).
     * @return uint256 The current balance of the asset in the vault.
     */
     function getVaultAssetBalance(uint256 _vaultId, address _assetAddress)
        public
        view
        vaultExists(_vaultId)
        returns (uint256)
    {
        Vault storage vault = _vaults[_vaultId];
        uint256 totalVaultAmount = 0;
         for (uint i = 0; i < vault.assets.length; i++) {
            if (vault.assets[i].assetAddress == _assetAddress) {
                totalVaultAmount = vault.assets[i].totalAmount;
                break;
            }
        }

        uint265 totalClaimedForAsset = 0;
         for(uint j=0; j < vault.recipients.length; j++){
            totalClaimedForAsset += _claimedAmounts[_vaultId][vault.recipients[j].addr][_assetAddress];
        }

        return totalVaultAmount > totalClaimedForAsset ? totalVaultAmount - totalClaimedForAsset : 0;
    }


    /**
     * @notice Returns the total amount of native ETH currently held by the contract.
     * @return uint256 Total ETH balance.
     */
    function getTotalLockedBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the total amount of a specific ERC20 token held by the contract.
     * @param _assetAddress The address of the ERC20 token.
     * @return uint256 Total ERC20 balance.
     */
    function getTotalLockedBalanceERC20(address _assetAddress) public view returns (uint256) {
        if (_assetAddress == address(0)) revert InvalidAssetAddress(); // Use a more specific error if available
        IERC20 token = IERC20(_assetAddress);
        return token.balanceOf(address(this));
    }

    /**
     * @notice Returns an array of all active vault IDs managed by the contract.
     * Note: Iterating through all IDs can be gas-intensive for a very large number of vaults.
     * @return uint256[] An array of vault IDs.
     */
    function listVaultIds() public view returns (uint256[] memory) {
        // Return a filtered list of active vault IDs if needed, or just the raw list.
        // Filtering requires iterating, so returning the raw list is simpler/cheaper.
        // Users would need to check isCancelled status if necessary.
        return _vaultIds;
    }


    // --- Emergency/Admin Functions ---

    /**
     * @notice Pauses the contract, disabling certain critical functions. Only owner.
     * Inherited from Pausable.sol.
     */
    function pause() public onlyOwner {
        _pause();
         emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, enabling critical functions. Only owner.
     * Inherited from Pausable.sol.
     */
    function unpause() public onlyOwner {
        _unpause();
         emit ContractUnpaused(msg.sender);
    }


    /**
     * @notice Allows the owner to withdraw ETH in an emergency, bypassing vault conditions.
     * Can only be called when the contract is paused.
     * @param _amount The amount of ETH to withdraw.
     * @param _recipient The address to send the ETH to.
     */
    function emergencyWithdrawETH(uint256 _amount, address _recipient)
        public
        onlyOwner
        whenPaused
        nonReentrant
    {
        if (_amount == 0) revert ZeroAmount();
        if (_recipient == address(0)) revert InvalidRecipientShare(address(0));
        if (address(this).balance < _amount) revert InsufficientAssetAmount(address(0), _amount, address(this).balance);

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
             // This is critical - handle ETH transfer failure.
             // For simplicity here, we just revert.
            revert InsufficientAssetAmount(address(0), 0, _amount);
        }

        emit EmergencyWithdrawal(address(0), _amount, _recipient);
    }

    /**
     * @notice Allows the owner to withdraw ERC20 tokens in an emergency, bypassing vault conditions.
     * Can only be called when the contract is paused.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     * @param _recipient The address to send the tokens to.
     */
    function emergencyWithdrawERC20(address _tokenAddress, uint256 _amount, address _recipient)
        public
        onlyOwner
        whenPaused
        nonReentrant
    {
        if (_tokenAddress == address(0)) revert InvalidAssetAddress(); // Use a more specific error
        if (_amount == 0) revert ZeroAmount();
        if (_recipient == address(0)) revert InvalidRecipientShare(address(0));

        IERC20 token = IERC20(_tokenAddress);
        if (token.balanceOf(address(this)) < _amount) revert InsufficientAssetAmount(_tokenAddress, _amount, token.balanceOf(address(this)));

        token.safeTransfer(_recipient, _amount);
        emit EmergencyWithdrawal(_tokenAddress, _amount, _recipient);
    }

    // Inherited from Ownable:
    // function transferOwnership(address newOwner)
    // function renounceOwnership()

    // Fallback/Receive functions to accept ETH
    receive() external payable {}
    fallback() external payable {}
}
```