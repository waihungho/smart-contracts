Okay, let's design an advanced smart contract called `QuantumVault`. This contract will allow users to deposit assets (ETH, ERC20, ERC721) into vaults with complex, multi-part conditions that must *all* be met before beneficiaries can claim. It combines concepts of time-locks, external triggers, NFT requirements, and conditional access.

It aims for complexity beyond simple vesting or escrow by requiring *multiple* potentially unrelated conditions to be simultaneously true for unlocking.

---

**QuantumVault Smart Contract Outline**

1.  **Contract Description:** A sophisticated vault for holding various digital assets under a combination of programmable, multi-part conditions.
2.  **State Variables:**
    *   `vaults`: Mapping from a unique ID to a `Vault` struct.
    *   `nextVaultId`: Counter for generating new vault IDs.
    *   Mappings to track vault IDs per owner and beneficiary for efficient querying.
3.  **Enums:**
    *   `VaultStatus`: `Locked`, `ConditionsMet`, `Claimed`, `Failed`, `Cancelled`.
    *   `AssetType`: `Ether`, `ERC20`, `ERC721`.
    *   `ConditionType`: `TimeLock`, `ExternalTrigger`, `RequiresNFT`, `SpecificCaller`.
4.  **Structs:**
    *   `Condition`: Defines a single condition part with type and parameters.
    *   `Beneficiary`: Defines an account and their percentage share of the assets.
    *   `Vault`: Contains all details about a specific vault instance (owner, asset, status, beneficiaries, conditions, claim status).
5.  **Events:**
    *   `VaultCreated`: Logs details upon vault creation.
    *   `ConditionsMet`: Logs when all conditions for a vault are finally met.
    *   `AssetsClaimed`: Logs when a beneficiary claims assets.
    *   `VaultCancelled`: Logs when a vault is cancelled by the owner.
    *   `VaultFailed`: Logs when a vault transitions to failed state.
    *   `VaultOwnershipTransferred`: Logs vault-specific ownership changes.
    *   `BeneficiaryAdded`: Logs when a new beneficiary is added.
    *   `ExternalConditionSignaled`: Logs when an external trigger condition is met.
6.  **Modifiers:**
    *   `onlyVaultOwner`: Restricts function calls to the owner of a specific vault.
    *   `whenLocked`: Restricts function calls to vaults in the `Locked` state.
    *   `whenConditionsMet`: Restricts function calls to vaults in the `ConditionsMet` state.
    *   `whenNotClaimed`: Restricts function calls to vaults not fully claimed.
    *   `whenFailed`: Restricts function calls to vaults in the `Failed` state.
7.  **Core Logic Functions (Creation, Signaling, Unlocking, Claiming):**
    *   `createEtherVault`: Creates a vault for Ether deposit.
    *   `createERC20Vault`: Creates a vault for ERC20 token deposit.
    *   `createERC721Vault`: Creates a vault for ERC721 token deposit.
    *   `signalExternalConditionMet`: Allows an authorized address to signal an external condition is met.
    *   `attemptUnlock`: Checks *all* conditions for a vault and updates status if met.
    *   `claimEther`: Allows a beneficiary to claim their share of Ether.
    *   `claimERC20`: Allows a beneficiary to claim their share of ERC20 tokens.
    *   `claimERC721`: Allows the single beneficiary to claim the NFT.
8.  **Management Functions (Vault Owner):**
    *   `cancelVault`: Allows owner to cancel a locked vault.
    *   `markVaultAsFailed`: Allows owner to mark a vault as failed if conditions cannot be met.
    *   `reclaimFailedVaultAssets`: Allows owner to reclaim assets from a failed vault.
    *   `addBeneficiaryToVault`: Allows owner to add a new beneficiary to a locked vault.
    *   `transferVaultOwnership`: Allows owner to transfer vault management rights.
9.  **Query Functions (Read-Only):**
    *   `getVaultDetails`: Retrieves basic info for a vault.
    *   `getVaultConditions`: Retrieves all conditions for a vault.
    *   `getVaultStatus`: Gets the current status of a vault.
    *   `isVaultUnlocked`: Checks if conditions are met (status is `ConditionsMet`).
    *   `isConditionMet`: Checks the status of a specific condition (internal state + real-time check).
    *   `getBeneficiaryClaimStatus`: Checks if a beneficiary has claimed from an unlocked vault.
    *   `getBeneficiaryClaimableAmount`: Calculates claimable Ether/ERC20 for a beneficiary.
    *   `getBeneficiaryClaimableNFT`: Checks if the NFT is claimable by a beneficiary.
    *   `getVaultIdsByOwner`: Lists vault IDs owned by an address.
    *   `getVaultIdsByBeneficiary`: Lists vault IDs where an address is a beneficiary.
    *   `getTotalVaultCount`: Gets the total number of vaults created.

---

**Function Summary**

1.  `createEtherVault(Beneficiary[] memory _beneficiaries, uint256[] memory _distributionPercentages, Condition[] memory _conditions)`: Creates a new vault holding sent Ether, defining beneficiaries, their proportional distribution, and the list of unlocking conditions. Payable function.
2.  `createERC20Vault(address _tokenAddress, uint256 _amount, Beneficiary[] memory _beneficiaries, uint256[] memory _distributionPercentages, Condition[] memory _conditions)`: Creates a new vault for a specified ERC20 token amount. Requires prior approval using `approve` on the token contract.
3.  `createERC721Vault(address _tokenAddress, uint256 _tokenId, address _beneficiary, Condition[] memory _conditions)`: Creates a new vault for a specific ERC721 token. Requires prior approval using `approve` or `setApprovalForAll` on the token contract. ERC721 vaults support only one beneficiary.
4.  `signalExternalConditionMet(uint256 _vaultId, uint256 _conditionIndex)`: Marks an `ExternalTrigger` condition as met for a specific vault. Can only be called by the authorized address specified in the condition parameters. Automatically attempts to unlock if all conditions are met.
5.  `attemptUnlock(uint256 _vaultId)`: Public function to check if all conditions for a vault are currently met. If they are, the vault status is updated to `ConditionsMet`. Anyone can call this to trigger the check.
6.  `claimEther(uint256 _vaultId)`: Allows a beneficiary of a vault (with `ConditionsMet` status) to claim their entitled share of Ether.
7.  `claimERC20(uint256 _vaultId, address _tokenAddress)`: Allows a beneficiary of an ERC20 vault (with `ConditionsMet` status) to claim their entitled share of the specified token.
8.  `claimERC721(uint256 _vaultId)`: Allows the beneficiary of an ERC721 vault (with `ConditionsMet` status) to claim the NFT.
9.  `cancelVault(uint256 _vaultId)`: Allows the vault owner to cancel a vault that is still `Locked`. Assets are returned to the owner.
10. `markVaultAsFailed(uint256 _vaultId)`: Allows the vault owner to mark a vault as `Failed` if conditions are impossible to meet (e.g., time expired without trigger, required NFT burned). Requires proof or simple owner declaration (simple declaration implemented for brevity).
11. `reclaimFailedVaultAssets(uint256 _vaultId)`: Allows the vault owner to retrieve assets from a vault marked as `Failed`.
12. `addBeneficiaryToVault(uint256 _vaultId, address _beneficiary, uint256 _percentage)`: Allows the vault owner to add a new beneficiary to a vault that is still `Locked`. The new beneficiary's percentage is added to the distribution list; total percentage can exceed 100%, resulting in proportional distribution.
13. `transferVaultOwnership(uint256 _vaultId, address _newOwner)`: Allows the current vault owner to transfer the management rights for a specific vault to a new address.
14. `getVaultDetails(uint256 _vaultId)`: Returns core details about a vault: owner, asset type, token address/id, amount, current status.
15. `getVaultConditions(uint256 _vaultId)`: Returns the list of conditions required for a specific vault.
16. `getVaultStatus(uint256 _vaultId)`: Returns the current `VaultStatus` enum value for a vault.
17. `isVaultUnlocked(uint256 _vaultId)`: Returns true if the vault's status is `ConditionsMet`.
18. `isConditionMet(uint256 _vaultId, uint256 _conditionIndex)`: Checks and returns the current boolean status of a *specific* condition for a vault. This performs real-time checks for TimeLock, RequiresNFT, SpecificCaller and checks internal state for ExternalTrigger.
19. `getBeneficiaryClaimStatus(uint256 _vaultId, address _beneficiary)`: Returns true if a specific beneficiary has claimed their share from an unlocked vault.
20. `getBeneficiaryClaimableAmount(uint256 _vaultId, address _beneficiary)`: Calculates and returns the amount of Ether or ERC20 tokens a specific beneficiary is entitled to claim from an unlocked vault, considering amounts already claimed. Returns 0 if not applicable or claimable.
21. `getBeneficiaryClaimableNFT(uint256 _vaultId, address _beneficiary)`: Returns true if the specific beneficiary is entitled to claim the NFT from an unlocked ERC721 vault.
22. `getVaultIdsByOwner(address _owner)`: Returns an array of vault IDs created by a specific owner. (Note: Requires iterating a mapping, which is gas-intensive for large data sets, or maintaining an array/mapping, which adds complexity on mutations. Simple iteration implemented).
23. `getVaultIdsByBeneficiary(address _beneficiary)`: Returns an array of vault IDs where a specific address is listed as a beneficiary. (Similar gas consideration as above).
24. `getTotalVaultCount()`: Returns the total number of vaults ever created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- QuantumVault Smart Contract Outline ---
// 1. Contract Description: A sophisticated vault for holding various digital assets under a combination of programmable, multi-part conditions.
// 2. State Variables: vaults, nextVaultId, mappings for owner/beneficiary vault lists.
// 3. Enums: VaultStatus, AssetType, ConditionType.
// 4. Structs: Condition, Beneficiary, Vault.
// 5. Events: VaultCreated, ConditionsMet, AssetsClaimed, VaultCancelled, VaultFailed, VaultOwnershipTransferred, BeneficiaryAdded, ExternalConditionSignaled.
// 6. Modifiers: onlyVaultOwner, whenLocked, whenConditionsMet, whenNotClaimed, whenFailed.
// 7. Core Logic Functions: createEtherVault, createERC20Vault, createERC721Vault, signalExternalConditionMet, attemptUnlock, claimEther, claimERC20, claimERC721.
// 8. Management Functions (Vault Owner): cancelVault, markVaultAsFailed, reclaimFailedVaultAssets, addBeneficiaryToVault, transferVaultOwnership.
// 9. Query Functions (Read-Only): getVaultDetails, getVaultConditions, getVaultStatus, isVaultUnlocked, isConditionMet, getBeneficiaryClaimStatus, getBeneficiaryClaimableAmount, getBeneficiaryClaimableNFT, getVaultIdsByOwner, getVaultIdsByBeneficiary, getTotalVaultCount.

// --- Function Summary ---
// 1. createEtherVault(Beneficiary[] memory _beneficiaries, uint256[] memory _distributionPercentages, Condition[] memory _conditions): Creates a new vault holding sent Ether.
// 2. createERC20Vault(address _tokenAddress, uint256 _amount, Beneficiary[] memory _beneficiaries, uint256[] memory _distributionPercentages, Condition[] memory _conditions): Creates a new vault for a specified ERC20 token amount.
// 3. createERC721Vault(address _tokenAddress, uint256 _tokenId, address _beneficiary, Condition[] memory _conditions): Creates a new vault for a specific ERC721 token (single beneficiary).
// 4. signalExternalConditionMet(uint256 _vaultId, uint256 _conditionIndex): Marks an ExternalTrigger condition as met.
// 5. attemptUnlock(uint256 _vaultId): Checks all conditions and updates vault status if met.
// 6. claimEther(uint256 _vaultId): Allows beneficiary to claim Ether share.
// 7. claimERC20(uint256 _vaultId, address _tokenAddress): Allows beneficiary to claim ERC20 share.
// 8. claimERC721(uint256 _vaultId): Allows beneficiary to claim NFT.
// 9. cancelVault(uint256 _vaultId): Owner cancels a locked vault, returns assets.
// 10. markVaultAsFailed(uint256 _vaultId): Owner marks vault as failed.
// 11. reclaimFailedVaultAssets(uint256 _vaultId): Owner reclaims from a failed vault.
// 12. addBeneficiaryToVault(uint256 _vaultId, address _beneficiary, uint256 _percentage): Owner adds new beneficiary to locked vault.
// 13. transferVaultOwnership(uint256 _vaultId, address _newOwner): Owner transfers vault management rights.
// 14. getVaultDetails(uint256 _vaultId): Returns core vault info.
// 15. getVaultConditions(uint256 _vaultId): Returns vault conditions.
// 16. getVaultStatus(uint256 _vaultId): Gets current vault status.
// 17. isVaultUnlocked(uint256 _vaultId): Checks if conditions are met.
// 18. isConditionMet(uint256 _vaultId, uint256 _conditionIndex): Checks status of a specific condition.
// 19. getBeneficiaryClaimStatus(uint256 _vaultId, address _beneficiary): Checks if beneficiary claimed.
// 20. getBeneficiaryClaimableAmount(uint256 _vaultId, address _beneficiary): Calculates claimable Ether/ERC20.
// 21. getBeneficiaryClaimableNFT(uint256 _vaultId, address _beneficiary): Checks if NFT is claimable.
// 22. getVaultIdsByOwner(address _owner): Lists vault IDs owned by an address.
// 23. getVaultIdsByBeneficiary(address _beneficiary): Lists vault IDs for a beneficiary.
// 24. getTotalVaultCount(): Gets total vault count.

contract QuantumVault {
    using Address for address payable;

    enum VaultStatus {
        Locked,         // Conditions not yet met
        ConditionsMet,  // All conditions met, assets claimable
        Claimed,        // All assets claimed by beneficiaries
        Failed,         // Conditions failed or impossible
        Cancelled       // Cancelled by owner before conditions met
    }

    enum AssetType {
        Ether,
        ERC20,
        ERC721
    }

    enum ConditionType {
        TimeLock,         // param1: unlockTimestamp (uint256)
        ExternalTrigger,  // paramAddress: authorizedSignaler (address)
        RequiresNFT,      // paramAddress: nftContract (address), param1: requiredTokenId (uint256, 0 for any in collection owned by msg.sender)
        SpecificCaller    // paramAddress: requiredCaller (address) - checks msg.sender of attemptUnlock or relevant call
    }

    struct Condition {
        ConditionType conditionType;
        uint256 param1;
        uint256 param2; // Reserved for future use or complex params
        address paramAddress;
        bool met; // Internal state for external triggers
    }

    struct Beneficiary {
        address account;
        uint256 percentage; // Scaled by PERCENTAGE_SCALE (e.g., 5000 for 50%)
    }

    struct Vault {
        address payable vaultOwner;
        AssetType assetType;
        address tokenAddress; // 0x0 for Ether
        uint256 tokenId;      // 0 for Ether/ERC20
        uint256 amount;       // for Ether/ERC20
        Beneficiary[] beneficiaries;
        Condition[] conditions;
        VaultStatus status;
        uint40 unlockedTimestamp; // Using uint40 for gas efficiency for timestamps

        // Claim tracking
        mapping(address => uint256) claimedAmounts; // For Ether/ERC20: address => amount claimed
        mapping(address => bool) claimedNFTs;      // For ERC721: address => claimed status (only one beneficiary)
    }

    mapping(uint256 => Vault) private vaults;
    uint256 private nextVaultId = 1;

    // Helper mappings for querying (can be gas intensive for large sets)
    mapping(address => uint256[]) private ownerVaultIds;
    mapping(address => uint256[]) private beneficiaryVaultIds;

    uint256 private constant PERCENTAGE_SCALE = 10000; // Represents 100%

    event VaultCreated(uint256 indexed vaultId, address indexed owner, AssetType assetType, address tokenAddress, uint256 amountOrTokenId);
    event ConditionsMet(uint256 indexed vaultId, uint256 timestamp);
    event AssetsClaimed(uint256 indexed vaultId, address indexed beneficiary, AssetType assetType, uint256 amountOrTokenId);
    event VaultCancelled(uint256 indexed vaultId, address indexed owner);
    event VaultFailed(uint256 indexed vaultId, address indexed owner);
    event VaultOwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner);
    event BeneficiaryAdded(uint256 indexed vaultId, address indexed beneficiary, uint256 percentage);
    event ExternalConditionSignaled(uint256 indexed vaultId, uint256 indexed conditionIndex, address indexed signaler);

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(vaults[_vaultId].vaultOwner == msg.sender, "Not vault owner");
        _;
    }

    modifier whenLocked(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.Locked, "Vault not in Locked state");
        _;
    }

    modifier whenConditionsMet(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.ConditionsMet, "Vault not in ConditionsMet state");
        _;
    }

    modifier whenNotClaimed(uint256 _vaultId) {
        // This modifier is slightly complex as claim status depends on asset type and if all shares are claimed
        // Using internal logic within claim functions is often clearer.
        // Leaving as a placeholder or removing depending on specific use case.
        _;
    }

    modifier whenFailed(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.Failed, "Vault not in Failed state");
        _;
    }

    // --- Internal Helper Functions ---

    /// @dev Checks if a single condition is met based on its type and current state.
    function _checkCondition(uint256 _vaultId, uint256 _conditionIndex) internal view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        Condition storage condition = vault.conditions[_conditionIndex];

        if (condition.conditionType == ConditionType.TimeLock) {
            return block.timestamp >= condition.param1;
        } else if (condition.conditionType == ConditionType.ExternalTrigger) {
            return condition.met; // Relies on external signal
        } else if (condition.conditionType == ConditionType.RequiresNFT) {
            // Check if the *caller* of attemptUnlock owns the required NFT
            // A more flexible design might require the *beneficiary* to own it during claim.
            // Let's implement it as the *beneficiary* must own it at the time of *claim*.
            // This function is primarily for `attemptUnlock`, so maybe it checks if *any* beneficiary owns it?
            // That's complex. Let's simplify: this condition is checked during `attemptUnlock`
            // and requires the *vault owner* or *creator* (or specific address?) to hold it?
            // Or the *person attempting to unlock*?
            // Let's make it check if *any* of the current beneficiaries own the NFT.
            // This makes `attemptUnlock` check potentially require a beneficiary to call it, or iterate.
            // Iterating beneficiaries is expensive. Let's require the NFT be held by *a specific address* defined in the condition.
            // paramAddress = required NFT holder.
            require(condition.paramAddress != address(0), "NFT condition needs holder address");
            IERC721 nft = IERC721(condition.paramAddress); // condition.paramAddress holds the NFT contract address
            uint256 requiredTokenId = condition.param1; // condition.param1 holds the required token ID

            if (requiredTokenId == 0) {
                 // Requires owning *any* NFT from the collection by the specified holder
                 // Checking for *any* token ID owned by an address requires iterating external contract state, which is impossible/gas-prohibitive.
                 // Let's restrict RequiresNFT to require a *specific* token ID (`param1 > 0`).
                 revert("RequiresNFT condition must specify a token ID (param1 > 0)");
            }
            // Checks if the specified holder owns the specific token ID
            return nft.ownerOf(requiredTokenId) == condition.paramAddress;

        } else if (condition.conditionType == ConditionType.SpecificCaller) {
            // This condition is checked by the function that *initiates* the state change based on conditions.
            // For attemptUnlock, it would check msg.sender of attemptUnlock.
            // For signalExternalConditionMet, the modifier/check handles who can signal.
            // Let's design SpecificCaller condition to check the `msg.sender` of the `attemptUnlock` function.
             return msg.sender == condition.paramAddress;
        }
        // Should not reach here
        return false;
    }

    /// @dev Checks if all conditions for a vault are met.
    function _checkAllConditions(uint256 _vaultId) internal view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        if (vault.status != VaultStatus.Locked) {
            return false; // Already unlocked, failed, or cancelled
        }

        for (uint i = 0; i < vault.conditions.length; i++) {
            if (!_checkCondition(_vaultId, i)) {
                return false; // At least one condition is not met
            }
        }
        return true; // All conditions are met
    }

    /// @dev Adds a vault ID to an address's list (for owner or beneficiary).
    function _addVaultToList(address _account, uint256 _vaultId, bool isOwner) internal {
        if (isOwner) {
            ownerVaultIds[_account].push(_vaultId);
        } else {
            beneficiaryVaultIds[_account].push(_vaultId);
        }
    }

     /// @dev Calculates the total distribution percentage for a vault.
    function _getTotalDistributionPercentage(uint256 _vaultId) internal view returns (uint256 totalPercentage) {
        Vault storage vault = vaults[_vaultId];
        for (uint i = 0; i < vault.beneficiaries.length; i++) {
            totalPercentage += vault.beneficiaries[i].percentage;
        }
    }


    // --- Core Logic Functions ---

    /**
     * @dev Creates a new vault for depositing Ether.
     * @param _beneficiaries Array of beneficiary addresses and their percentages.
     * @param _distributionPercentages Array of percentages corresponding to _beneficiaries. Must sum <= PERCENTAGE_SCALE.
     * @param _conditions Array of conditions that must be met to unlock the vault.
     */
    function createEtherVault(
        Beneficiary[] memory _beneficiaries,
        uint256[] memory _distributionPercentages,
        Condition[] memory _conditions
    ) external payable returns (uint256 vaultId) {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(_beneficiaries.length == _distributionPercentages.length, "Beneficiaries and percentages mismatch");
        require(_beneficiaries.length > 0, "Must have at least one beneficiary");
        require(_conditions.length > 0, "Must have at least one condition");

        uint256 totalPercentage = 0;
        for (uint i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i].account != address(0), "Beneficiary address cannot be zero");
            _beneficiaries[i].percentage = _distributionPercentages[i]; // Assign percentage from separate array
            totalPercentage += _beneficiaries[i].percentage;
        }
        require(totalPercentage <= PERCENTAGE_SCALE, "Total percentage exceeds 100%");

        vaultId = nextVaultId++;
        vaults[vaultId] = Vault({
            vaultOwner: payable(msg.sender),
            assetType: AssetType.Ether,
            tokenAddress: address(0),
            tokenId: 0,
            amount: msg.value,
            beneficiaries: _beneficiaries, // Use the modified array
            conditions: _conditions,
            status: VaultStatus.Locked,
            unlockedTimestamp: 0,
            claimedAmounts: new mapping(address => uint256),
            claimedNFTs: new mapping(address => bool)
        });

        _addVaultToList(msg.sender, vaultId, true);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            _addVaultToList(_beneficiaries[i].account, vaultId, false);
        }

        emit VaultCreated(vaultId, msg.sender, AssetType.Ether, address(0), msg.value);
    }

    /**
     * @dev Creates a new vault for depositing ERC20 tokens. Requires caller to approve token transfer beforehand.
     * @param _tokenAddress Address of the ERC20 token contract.
     * @param _amount Amount of tokens to deposit (in token's smallest unit).
     * @param _beneficiaries Array of beneficiary addresses.
     * @param _distributionPercentages Array of percentages corresponding to _beneficiaries. Must sum <= PERCENTAGE_SCALE.
     * @param _conditions Array of conditions that must be met to unlock the vault.
     */
    function createERC20Vault(
        address _tokenAddress,
        uint256 _amount,
        Beneficiary[] memory _beneficiaries,
        uint256[] memory _distributionPercentages,
        Condition[] memory _conditions
    ) external returns (uint256 vaultId) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(_beneficiaries.length == _distributionPercentages.length, "Beneficiaries and percentages mismatch");
        require(_beneficiaries.length > 0, "Must have at least one beneficiary");
        require(_conditions.length > 0, "Must have at least one condition");

        uint256 totalPercentage = 0;
        for (uint i = 0; i < _beneficiaries.length; i++) {
             require(_beneficiaries[i].account != address(0), "Beneficiary address cannot be zero");
            _beneficiaries[i].percentage = _distributionPercentages[i]; // Assign percentage
            totalPercentage += _beneficiaries[i].percentage;
        }
        require(totalPercentage <= PERCENTAGE_SCALE, "Total percentage exceeds 100%");

        vaultId = nextVaultId++;
        vaults[vaultId] = Vault({
            vaultOwner: payable(msg.sender),
            assetType: AssetType.ERC20,
            tokenAddress: _tokenAddress,
            tokenId: 0,
            amount: _amount,
            beneficiaries: _beneficiaries, // Use modified array
            conditions: _conditions,
            status: VaultStatus.Locked,
            unlockedTimestamp: 0,
            claimedAmounts: new mapping(address => uint256),
            claimedNFTs: new mapping(address => bool)
        });

        // Transfer tokens to the contract
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        _addVaultToList(msg.sender, vaultId, true);
        for (uint i = 0; i < _beneficiaries.length; i++) {
             _addVaultToList(_beneficiaries[i].account, vaultId, false);
        }

        emit VaultCreated(vaultId, msg.sender, AssetType.ERC20, _tokenAddress, _amount);
    }

    /**
     * @dev Creates a new vault for depositing a single ERC721 token. Requires caller to approve token transfer beforehand.
     * ERC721 vaults only support one beneficiary.
     * @param _tokenAddress Address of the ERC721 token contract.
     * @param _tokenId ID of the token to deposit.
     * @param _beneficiary Address of the single beneficiary.
     * @param _conditions Array of conditions that must be met to unlock the vault.
     */
    function createERC721Vault(
        address _tokenAddress,
        uint256 _tokenId,
        address _beneficiary,
        Condition[] memory _conditions
    ) external returns (uint256 vaultId) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_conditions.length > 0, "Must have at least one condition");

        // ERC721 vaults have a single beneficiary with 100% share implicitly
        Beneficiary[] memory beneficiaries = new Beneficiary[](1);
        beneficiaries[0] = Beneficiary({account: _beneficiary, percentage: PERCENTAGE_SCALE});

        vaultId = nextVaultId++;
        vaults[vaultId] = Vault({
            vaultOwner: payable(msg.sender),
            assetType: AssetType.ERC721,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: 0, // Not applicable for ERC721 in this struct field
            beneficiaries: beneficiaries,
            conditions: _conditions,
            status: VaultStatus.Locked,
            unlockedTimestamp: 0,
            claimedAmounts: new mapping(address => uint256), // Not applicable for ERC721
            claimedNFTs: new mapping(address => bool)
        });

        // Transfer token to the contract
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);

        _addVaultToList(msg.sender, vaultId, true);
        _addVaultToList(_beneficiary, vaultId, false);

        emit VaultCreated(vaultId, msg.sender, AssetType.ERC721, _tokenAddress, _tokenId);
    }

    /**
     * @dev Allows an authorized external address to signal that a specific ConditionType.ExternalTrigger is met.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the ConditionType.ExternalTrigger condition within the vault's conditions array.
     */
    function signalExternalConditionMet(uint256 _vaultId, uint256 _conditionIndex) external whenLocked(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];

        require(condition.conditionType == ConditionType.ExternalTrigger, "Condition is not an ExternalTrigger");
        require(condition.paramAddress != address(0), "ExternalTrigger condition requires authorized signaler address");
        require(msg.sender == condition.paramAddress, "Not authorized signaler for this condition");
        require(!condition.met, "Condition already signaled as met");

        condition.met = true; // Mark this specific external trigger condition as met

        emit ExternalConditionSignaled(_vaultId, _conditionIndex, msg.sender);

        // Automatically attempt to unlock if this signal might fulfill all conditions
        if (_checkAllConditions(_vaultId)) {
            vault.status = VaultStatus.ConditionsMet;
            vault.unlockedTimestamp = uint40(block.timestamp);
            emit ConditionsMet(_vaultId, block.timestamp);
        }
    }

    /**
     * @dev Attempts to unlock a vault by checking if all its conditions are met.
     * Can be called by anyone.
     * @param _vaultId The ID of the vault to attempt to unlock.
     */
    function attemptUnlock(uint256 _vaultId) external whenLocked(_vaultId) {
        if (_checkAllConditions(_vaultId)) {
            vaults[_vaultId].status = VaultStatus.ConditionsMet;
            vaults[_vaultId].unlockedTimestamp = uint40(block.timestamp);
            emit ConditionsMet(_vaultId, block.timestamp);
        }
        // If conditions are not met, the status remains Locked.
    }

    /**
     * @dev Allows a beneficiary to claim their share of Ether from an unlocked vault.
     * @param _vaultId The ID of the vault.
     */
    function claimEther(uint256 _vaultId) external whenConditionsMet(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.assetType == AssetType.Ether, "Vault does not contain Ether");

        uint256 totalPercentage = _getTotalDistributionPercentage(_vaultId);
        require(totalPercentage > 0, "No valid beneficiaries or distribution percentage");

        uint256 claimable = 0;
        bool isBeneficiary = false;
        for (uint i = 0; i < vault.beneficiaries.length; i++) {
            if (vault.beneficiaries[i].account == msg.sender) {
                isBeneficiary = true;
                // Calculate the raw share based on the beneficiary's percentage
                uint256 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / PERCENTAGE_SCALE;
                // If total percentage > 100%, pro-rata distribution applies
                if (totalPercentage > PERCENTAGE_SCALE) {
                     rawShare = (vault.amount * vault.beneficiaries[i].percentage) / totalPercentage;
                }
                // Subtract amount already claimed
                claimable = rawShare - vault.claimedAmounts[msg.sender];
                break;
            }
        }

        require(isBeneficiary, "Not a beneficiary of this vault");
        require(claimable > 0, "No claimable amount or already claimed");

        // Update claimed amount BEFORE sending to prevent reentrancy
        vault.claimedAmounts[msg.sender] += claimable;

        // Send Ether
        payable(msg.sender).sendValue(claimable);

        emit AssetsClaimed(_vaultId, msg.sender, AssetType.Ether, claimable);

        // Check if all Ether has been claimed to update vault status
        uint256 totalClaimed = 0;
         for (uint i = 0; i < vault.beneficiaries.length; i++) {
            uint256 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / PERCENTAGE_SCALE;
             if (totalPercentage > PERCENTAGE_SCALE) {
                 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / totalPercentage;
             }
            totalClaimed += vault.claimedAmounts[vault.beneficiaries[i].account];
        }

        // Allow small tolerance for dust/rounding if percentages don't exactly sum up
        if (vault.amount <= totalClaimed + vault.beneficiaries.length * 100) { // Adding a small buffer per beneficiary
             vault.status = VaultStatus.Claimed;
        }
    }

    /**
     * @dev Allows a beneficiary to claim their share of ERC20 tokens from an unlocked vault.
     * @param _vaultId The ID of the vault.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function claimERC20(uint256 _vaultId, address _tokenAddress) external whenConditionsMet(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.assetType == AssetType.ERC20, "Vault does not contain ERC20");
        require(vault.tokenAddress == _tokenAddress, "Token address mismatch");

        uint256 totalPercentage = _getTotalDistributionPercentage(_vaultId);
        require(totalPercentage > 0, "No valid beneficiaries or distribution percentage");

        uint256 claimable = 0;
        bool isBeneficiary = false;
         for (uint i = 0; i < vault.beneficiaries.length; i++) {
            if (vault.beneficiaries[i].account == msg.sender) {
                isBeneficiary = true;
                 uint256 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / PERCENTAGE_SCALE;
                 if (totalPercentage > PERCENTAGE_SCALE) {
                     rawShare = (vault.amount * vault.beneficiaries[i].percentage) / totalPercentage;
                 }
                claimable = rawShare - vault.claimedAmounts[msg.sender];
                break;
            }
        }

        require(isBeneficiary, "Not a beneficiary of this vault");
        require(claimable > 0, "No claimable amount or already claimed");

         // Update claimed amount BEFORE transferring to prevent reentrancy
        vault.claimedAmounts[msg.sender] += claimable;

        // Transfer tokens
        IERC20(_tokenAddress).transfer(msg.sender, claimable);

        emit AssetsClaimed(_vaultId, msg.sender, AssetType.ERC20, claimable);

         // Check if all tokens have been claimed
        uint256 totalClaimed = 0;
         for (uint i = 0; i < vault.beneficiaries.length; i++) {
             uint256 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / PERCENTAGE_SCALE;
             if (totalPercentage > PERCENTAGE_SCALE) {
                 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / totalPercentage;
             }
            totalClaimed += vault.claimedAmounts[vault.beneficiaries[i].account];
        }

         if (vault.amount <= totalClaimed + vault.beneficiaries.length * 100) { // Adding a small buffer
             vault.status = VaultStatus.Claimed;
        }
    }

     /**
     * @dev Allows the single beneficiary to claim the ERC721 token from an unlocked vault.
     * @param _vaultId The ID of the vault.
     */
    function claimERC721(uint256 _vaultId) external whenConditionsMet(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.assetType == AssetType.ERC721, "Vault does not contain ERC721");
        require(vault.beneficiaries.length == 1 && vault.beneficiaries[0].account == msg.sender, "Not the designated beneficiary for this NFT vault");
        require(!vault.claimedNFTs[msg.sender], "NFT already claimed by this beneficiary");

        vault.claimedNFTs[msg.sender] = true; // Mark as claimed BEFORE transfer

        // Transfer NFT
        IERC721(vault.tokenAddress).transferFrom(address(this), msg.sender, vault.tokenId);

        emit AssetsClaimed(_vaultId, msg.sender, AssetType.ERC721, vault.tokenId);

        // Mark vault as claimed once the single NFT is claimed
        vault.status = VaultStatus.Claimed;
    }


    // --- Management Functions ---

    /**
     * @dev Allows the vault owner to cancel a vault that is still Locked. Assets are returned.
     * @param _vaultId The ID of the vault to cancel.
     */
    function cancelVault(uint256 _vaultId) external onlyVaultOwner(_vaultId) whenLocked(_vaultId) {
        Vault storage vault = vaults[_vaultId];

        vault.status = VaultStatus.Cancelled;

        if (vault.assetType == AssetType.Ether) {
            payable(vault.vaultOwner).sendValue(vault.amount);
        } else if (vault.assetType == AssetType.ERC20) {
            IERC20(vault.tokenAddress).transfer(vault.vaultOwner, vault.amount);
        } else if (vault.assetType == AssetType.ERC721) {
            IERC721(vault.tokenAddress).transferFrom(address(this), vault.vaultOwner, vault.tokenId);
        }

        // Note: For large numbers of vaults, cleaning up ownerVaultIds/beneficiaryVaultIds arrays is gas-intensive.
        // Leaving them as-is might be acceptable, or implement cleanup iteration if necessary.

        emit VaultCancelled(_vaultId, msg.sender);
    }

    /**
     * @dev Allows the vault owner to mark a vault as Failed. This is typically used if conditions become impossible.
     * Once failed, assets can be reclaimed by the owner.
     * @param _vaultId The ID of the vault.
     */
    function markVaultAsFailed(uint256 _vaultId) external onlyVaultOwner(_vaultId) whenLocked(_vaultId) {
        // A real implementation might require proof conditions are impossible (e.g., timestamp passed, required NFT burned).
        // For simplicity, this version allows the owner to declare failure on a locked vault.
        vaults[_vaultId].status = VaultStatus.Failed;
        emit VaultFailed(_vaultId, msg.sender);
    }

    /**
     * @dev Allows the vault owner to reclaim assets from a vault that has been marked as Failed.
     * @param _vaultId The ID of the vault.
     */
    function reclaimFailedVaultAssets(uint256 _vaultId) external onlyVaultOwner(_vaultId) whenFailed(_vaultId) {
         Vault storage vault = vaults[_vaultId];

        if (vault.assetType == AssetType.Ether) {
            payable(vault.vaultOwner).sendValue(vault.amount);
        } else if (vault.assetType == AssetType.ERC20) {
            IERC20(vault.tokenAddress).transfer(vault.vaultOwner, vault.amount);
        } else if (vault.assetType == AssetType.ERC721) {
            IERC721(vault.tokenAddress).transferFrom(address(this), vault.vaultOwner, vault.tokenId);
        }

        // Transition to claimed state as assets are gone
        vault.status = VaultStatus.Claimed; // Or another final state like Reclaimed

        emit AssetsClaimed(_vaultId, vault.vaultOwner, vault.assetType, vault.amount > 0 ? vault.amount : vault.tokenId); // Use amount or tokenId for logging
    }

    /**
     * @dev Allows the vault owner to add a new beneficiary to a vault that is still Locked.
     * The percentage is added to the distribution list. Total percentage can exceed 100%,
     * resulting in proportional distribution among ALL beneficiaries during claim.
     * @param _vaultId The ID of the vault.
     * @param _beneficiary The address of the new beneficiary.
     * @param _percentage The distribution percentage for the new beneficiary (scaled by PERCENTAGE_SCALE).
     */
    function addBeneficiaryToVault(uint256 _vaultId, address _beneficiary, uint256 _percentage) external onlyVaultOwner(_vaultId) whenLocked(_vaultId) {
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_percentage > 0, "Percentage must be greater than zero");

        Vault storage vault = vaults[_vaultId];
        require(vault.assetType != AssetType.ERC721, "Cannot add multiple beneficiaries to ERC721 vaults"); // ERC721 is single beneficiary

        // Check if beneficiary already exists (optional, but good practice)
        for (uint i = 0; i < vault.beneficiaries.length; i++) {
            if (vault.beneficiaries[i].account == _beneficiary) {
                revert("Beneficiary already exists"); // Or update their percentage? Let's keep it simple and just add.
            }
        }

        vault.beneficiaries.push(Beneficiary({account: _beneficiary, percentage: _percentage}));
        _addVaultToList(_beneficiary, _vaultId, false);

        emit BeneficiaryAdded(_vaultId, _beneficiary, _percentage);
    }

    /**
     * @dev Allows the current vault owner to transfer ownership of a specific vault to a new address.
     * The new owner gains management rights (cancel, fail, add beneficiary, transfer ownership).
     * @param _vaultId The ID of the vault.
     * @param _newOwner The address of the new vault owner.
     */
    function transferVaultOwnership(uint256 _vaultId, address payable _newOwner) external onlyVaultOwner(_vaultId) {
        require(_newOwner != address(0), "New owner address cannot be zero");
        require(_newOwner != vaults[_vaultId].vaultOwner, "New owner is already the current owner");

        address oldOwner = vaults[_vaultId].vaultOwner;
        vaults[_vaultId].vaultOwner = _newOwner;

        // Note: Cleaning up ownerVaultIds for the old owner is gas-intensive.
        // The new owner's list is not updated here for simplicity, meaning querying
        // by ownerVaultIds for the new owner won't immediately show transferred vaults.
        // A robust implementation might require managing these arrays more carefully on transfers/cancellations.

        emit VaultOwnershipTransferred(_vaultId, oldOwner, _newOwner);
    }


    // --- Query Functions ---

    /**
     * @dev Gets core details about a vault.
     * @param _vaultId The ID of the vault.
     * @return owner Vault owner address.
     * @return assetType Type of asset held.
     * @return tokenAddress Address of token contract (0x0 for Ether).
     * @return tokenId ID of the token for ERC721 (0 for Ether/ERC20).
     * @return amount Amount of asset for Ether/ERC20 (0 for ERC721).
     * @return status Current status of the vault.
     */
    function getVaultDetails(uint256 _vaultId) external view returns (
        address owner,
        AssetType assetType,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        VaultStatus status
    ) {
        Vault storage vault = vaults[_vaultId];
        require(vault.vaultOwner != address(0), "Vault does not exist"); // Check if vault is initialized

        return (
            vault.vaultOwner,
            vault.assetType,
            vault.tokenAddress,
            vault.tokenId,
            vault.amount,
            vault.status
        );
    }

    /**
     * @dev Gets the list of conditions for a vault.
     * @param _vaultId The ID of the vault.
     * @return Array of Condition structs. Note: 'met' field is internal state for ExternalTrigger only.
     */
    function getVaultConditions(uint256 _vaultId) external view returns (Condition[] memory) {
         Vault storage vault = vaults[_vaultId];
         require(vault.vaultOwner != address(0), "Vault does not exist");
         return vault.conditions;
    }

    /**
     * @dev Gets the current status of a vault.
     * @param _vaultId The ID of the vault.
     * @return The VaultStatus enum value.
     */
    function getVaultStatus(uint256 _vaultId) external view returns (VaultStatus) {
        Vault storage vault = vaults[_vaultId];
        require(vault.vaultOwner != address(0), "Vault does not exist");
        return vault.status;
    }

    /**
     * @dev Checks if the conditions for a vault have been met (status is ConditionsMet).
     * @param _vaultId The ID of the vault.
     * @return True if the vault is unlocked, false otherwise.
     */
    function isVaultUnlocked(uint256 _vaultId) external view returns (bool) {
         Vault storage vault = vaults[_vaultId];
         require(vault.vaultOwner != address(0), "Vault does not exist");
         return vault.status == VaultStatus.ConditionsMet;
    }

     /**
     * @dev Checks the current status of a specific condition for a vault.
     * Performs real-time checks for relevant condition types.
     * @param _vaultId The ID of the vault.
     * @param _conditionIndex The index of the condition in the vault's conditions array.
     * @return True if the specific condition is met, false otherwise.
     */
    function isConditionMet(uint256 _vaultId, uint256 _conditionIndex) external view returns (bool) {
         Vault storage vault = vaults[_vaultId];
         require(vault.vaultOwner != address(0), "Vault does not exist");
         require(_conditionIndex < vault.conditions.length, "Invalid condition index");

         // Use the internal helper function for checking the condition state
         return _checkCondition(_vaultId, _conditionIndex);
    }

    /**
     * @dev Checks if a specific beneficiary has claimed any assets from an unlocked vault.
     * For ERC721, checks if the NFT is claimed. For Ether/ERC20, checks if claimedAmount is > 0.
     * @param _vaultId The ID of the vault.
     * @param _beneficiary The address of the beneficiary.
     * @return True if the beneficiary has claimed, false otherwise.
     */
    function getBeneficiaryClaimStatus(uint256 _vaultId, address _beneficiary) external view returns (bool) {
         Vault storage vault = vaults[_vaultId];
         require(vault.vaultOwner != address(0), "Vault does not exist");
         require(_beneficiary != address(0), "Beneficiary address cannot be zero");

         if (vault.assetType == AssetType.ERC721) {
            // For NFT vaults, check if the beneficiary claimed the single NFT
             require(vault.beneficiaries.length == 1 && vault.beneficiaries[0].account == _beneficiary, "Address is not the NFT beneficiary");
            return vault.claimedNFTs[_beneficiary];
         } else {
            // For Ether/ERC20 vaults, check if they claimed any amount
            bool isBeneficiary = false;
            for(uint i=0; i < vault.beneficiaries.length; i++) {
                if (vault.beneficiaries[i].account == _beneficiary) {
                    isBeneficiary = true;
                    break;
                }
            }
            require(isBeneficiary, "Address is not a beneficiary of this vault");
            return vault.claimedAmounts[_beneficiary] > 0;
         }
    }

     /**
     * @dev Calculates the amount of Ether or ERC20 tokens a beneficiary is currently able to claim from an unlocked vault.
     * Does not perform checks on vault status; assumes caller checks isVaultUnlocked.
     * @param _vaultId The ID of the vault.
     * @param _beneficiary The address of the beneficiary.
     * @return The claimable amount in the asset's smallest unit. Returns 0 if not applicable or nothing claimable.
     */
    function getBeneficiaryClaimableAmount(uint256 _vaultId, address _beneficiary) external view returns (uint256) {
         Vault storage vault = vaults[_vaultId];
         require(vault.vaultOwner != address(0), "Vault does not exist");
         require(vault.assetType != AssetType.ERC721, "Not applicable for ERC721 vaults");
         require(_beneficiary != address(0), "Beneficiary address cannot be zero");

         uint256 totalPercentage = _getTotalDistributionPercentage(_vaultId);
         if (totalPercentage == 0) return 0; // No valid beneficiaries or distribution

         uint256 claimable = 0;
         bool isBeneficiary = false;
         for (uint i = 0; i < vault.beneficiaries.length; i++) {
             if (vault.beneficiaries[i].account == _beneficiary) {
                 isBeneficiary = true;
                 uint256 rawShare = (vault.amount * vault.beneficiaries[i].percentage) / PERCENTAGE_SCALE;
                 if (totalPercentage > PERCENTAGE_SCALE) {
                     rawShare = (vault.amount * vault.beneficiaries[i].percentage) / totalPercentage;
                 }
                 claimable = rawShare - vault.claimedAmounts[_beneficiary];
                 break;
             }
         }

         if (!isBeneficiary) return 0; // Not a beneficiary

         return claimable;
    }

    /**
     * @dev Checks if the NFT in an ERC721 vault is claimable by the designated beneficiary.
     * Does not perform checks on vault status; assumes caller checks isVaultUnlocked.
     * @param _vaultId The ID of the vault.
     * @param _beneficiary The address of the beneficiary.
     * @return True if the NFT is claimable by this beneficiary, false otherwise.
     */
    function getBeneficiaryClaimableNFT(uint256 _vaultId, address _beneficiary) external view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        require(vault.vaultOwner != address(0), "Vault does not exist");
        require(vault.assetType == AssetType.ERC721, "Vault does not contain ERC721");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");

        // ERC721 vaults have only one beneficiary
        require(vault.beneficiaries.length == 1 && vault.beneficiaries[0].account == _beneficiary, "Address is not the designated beneficiary for this NFT vault");

        return !vault.claimedNFTs[_beneficiary]; // Claimable if not already claimed
    }

    /**
     * @dev Returns an array of vault IDs created by a specific owner.
     * Note: This iterates through an array. Gas cost increases with the number of vaults.
     * @param _owner The owner's address.
     * @return An array of vault IDs.
     */
    function getVaultIdsByOwner(address _owner) external view returns (uint256[] memory) {
        // Returning the stored array directly. Modifications (cancel, transfer) do *not* prune this array
        // in this simplified version due to gas costs.
        return ownerVaultIds[_owner];
    }

    /**
     * @dev Returns an array of vault IDs where a specific address is listed as a beneficiary.
     * Note: This iterates through an array. Gas cost increases with the number of vaults.
     * @param _beneficiary The beneficiary's address.
     * @return An array of vault IDs.
     */
    function getVaultIdsByBeneficiary(address _beneficiary) external view returns (uint256[] memory) {
        // Returning the stored array directly.
        return beneficiaryVaultIds[_beneficiary];
    }

    /**
     * @dev Returns the total number of vaults that have been created.
     * @return The total count of vaults.
     */
    function getTotalVaultCount() external view returns (uint256) {
        return nextVaultId - 1; // nextVaultId is 1-based counter
    }

    // Fallback function to receive Ether if needed (though createEtherVault is preferred)
    receive() external payable {}
}
```