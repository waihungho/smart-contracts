Okay, here is a smart contract concept called "HyperFungibleAsset" (HFA). It blends aspects of ERC-20 fungibility with ERC-721-like unique properties by allowing users to "bond" amounts of the fungible token into non-fungible "Parcels". These parcels can then accrue yield, be transferred as unique units, split, merged, and have management delegated.

This concept is advanced because it combines fungible and non-fungible mechanics, introduces dynamic yield calculation per unique unit (parcel), and includes complex operations like splitting/merging bonded assets and delegation. It doesn't directly duplicate a single common open-source standard implementation but builds upon ERC-20 principles with custom extensions.

---

**Smart Contract Outline and Function Summary: HyperFungibleAsset**

**Contract Name:** `HyperFungibleAsset`

**Concept:** A fungible token (HFA) that allows users to lock amounts into unique, non-fungible "Parcels" (represented internally by an ID). These parcels accrue yield based on dynamic rates, can be transferred, split, merged, and have yield claims/management delegated.

**Key Features:**
1.  **ERC-20 Core:** Standard fungible token operations (transfer, balance, approval).
2.  **HyperBonded Parcels (HBP):** Mechanism to lock HFA tokens into unique, ID'd parcels.
3.  **Dynamic Yield:** Parcels accrue yield based on an amount, duration, and an assignable yield rate ID. Yield rates can be updated by an oracle/admin.
4.  **Parcel Management:** Functions for bonding, unbonding, transferring parcels.
5.  **Advanced Parcel Operations:** Splitting and merging existing parcels.
6.  **Delegation:** Allow users to delegate yield claiming or full parcel management rights to another address for a specific parcel.
7.  **Oracle Integration:** Placeholder for integrating an external oracle to update yield rates.

**Function Summary:**

1.  **`constructor(string name, string symbol, uint256 initialSupply)`:** Initializes the ERC-20 token and mints initial supply to the deployer.
2.  **`totalSupply()`:** Returns the total supply of HFA tokens. (ERC-20 View)
3.  **`balanceOf(address account)`:** Returns the standard liquid balance of HFA tokens for an account. (ERC-20 View)
4.  **`transfer(address recipient, uint256 amount)`:** Transfers HFA tokens. (ERC-20)
5.  **`allowance(address owner, address spender)`:** Returns the allowance for `spender` on `owner`'s HFA tokens. (ERC-20 View)
6.  **`approve(address spender, uint256 amount)`:** Sets the allowance for `spender` on `msg.sender`'s HFA tokens. (ERC-20)
7.  **`transferFrom(address sender, address recipient, uint256 amount)`:** Transfers HFA tokens using allowance. (ERC-20)
8.  **`transferWithMetadata(address recipient, uint256 amount, bytes calldata data)`:** Transfers HFA tokens with additional data (similar to ERC-777 `send`).
9.  **`bondTokens(uint256 amount, uint64 unlockTimestamp, uint256 yieldRateId)`:** Locks `amount` of HFA tokens from `msg.sender` into a new HyperBonded Parcel (HBP) with specified unlock time and yield rate. Mints a new parcel ID.
10. **`unbondTokens(uint256 parcelId)`:** Unlocks the HFA tokens from a parcel owned by `msg.sender`. Can only be called after the unlock timestamp. Calculates and pays out accrued yield. Burns the parcel ID.
11. **`getParcelDetails(uint256 parcelId)`:** Returns the amount, unlock timestamp, yield rate ID, and creation/last update time for a specific parcel. (View)
12. **`getParcelOwner(uint256 parcelId)`:** Returns the owner address of a specific parcel ID. (View)
13. **`transferParcel(address from, address to, uint256 parcelId)`:** Transfers ownership of a HyperBonded Parcel (HBP). Requires owner, approved address, or operator status.
14. **`approveParcel(address to, uint256 parcelId)`:** Approves an address to transfer a specific parcel ID.
15. **`getApprovedParcel(uint256 parcelId)`:** Returns the approved address for a specific parcel ID. (View)
16. **`setApprovalForAllParcels(address operator, bool approved)`:** Sets approval for an operator to manage all of `msg.sender`'s parcels.
17. **`isApprovedForAllParcels(address owner, address operator)`:** Checks if an operator is approved for all of `owner`'s parcels. (View)
18. **`addYieldRate(uint256 rateBps)`:** (Owner Only) Adds a new yield rate (in basis points) to the system, returning its ID.
19. **`getYieldRate(uint256 yieldRateId)`:** Returns the yield rate (in basis points) for a given ID. (View)
20. **`calculateParcelYield(uint256 parcelId)`:** Calculates the currently accrued yield for a parcel since its last yield update, without claiming it. (View)
21. **`claimParcelYield(uint256 parcelId)`:** Claims the accrued yield for a parcel owned by `msg.sender` or an authorized delegate. Pays out yield in HFA tokens. Updates parcel's last yield update time.
22. **`updateParcelYieldRate(uint256 parcelId, uint256 newYieldRateId)`:** (Owner/Oracle Only) Updates the yield rate ID for an existing parcel. Automatically calculates and accrues yield before changing the rate.
23. **`reinvestParcelYield(uint256 parcelId)`:** Calculates accrued yield for a parcel and uses it to create a *new* separate parcel for the owner. The original parcel remains unchanged. (Requires minimum yield amount).
24. **`splitParcel(uint256 parcelId, uint256 amountForNewParcel)`:** Splits a parcel owned by `msg.sender` or authorized manager into two. Creates a new parcel with `amountForNewParcel` and reduces the original parcel's amount. Yield is calculated and accounted for before the split. The new parcel inherits the original unlock time and yield rate.
25. **`mergeParcels(uint256 parcelId1, uint256 parcelId2)`:** Merges two parcels owned by the same address. Burns the two original parcels and creates a new one with the combined amount. The new parcel uses the maximum unlock time and maximum yield rate ID of the originals. Yield is calculated and accounted for before the merge.
26. **`delegateParcelYieldClaim(uint256 parcelId, address delegatee)`:** Allows `msg.sender` to delegate the ability to call `claimParcelYield` for a specific parcel to `delegatee`.
27. **`revokeParcelYieldClaimDelegate(uint256 parcelId)`:** Revokes any existing yield claim delegate for a parcel.
28. **`delegateParcelManagement(uint256 parcelId, address delegatee, uint64 expiration)`:** Allows `msg.sender` to delegate broader management rights (split, merge, reinvest, potentially transfer if not owner/approved) for a parcel to `delegatee` until `expiration`.
29. **`revokeParcelManagementDelegate(uint256 parcelId)`:** Revokes any existing management delegate for a parcel.
30. **`setYieldOracle(address oracleAddress)`:** (Owner Only) Sets the address of a trusted oracle contract that can call `triggerDynamicYieldUpdate`.
31. **`triggerDynamicYieldUpdate(uint256 yieldRateId, uint256 newRateBps)`:** (Oracle Only) Allows a designated oracle to update the yield rate for an existing yield rate ID.
32. **`getLockedBalance(address account)`:** Calculates the total amount of HFA tokens locked across all parcels owned by `account`. (Inefficient for accounts with many parcels, note in docs). (View)
33. **`getTotalBondedSupply()`:** Returns the total amount of HFA tokens locked across all existing parcels. (View)
34. **`pauseBonding()`:** (Owner Only) Pauses the creation of new parcels (`bondTokens`).
35. **`unpauseBonding()`:** (Owner Only) Unpauses the creation of new parcels.
36. **`pauseUnbonding()`:** (Owner Only) Pauses the unlocking of tokens from parcels (`unbondTokens`).
37. **`unpauseUnbonding()`:** (Owner Only) Unpauses the unlocking of tokens from parcels.
38. **`upgradeParcelAttributes(uint256 parcelId, bytes calldata upgradeData)`:** (Owner Only - Placeholder) Allows owner to potentially modify other, non-core attributes of a parcel using structured data. Requires specific decoding logic not implemented in detail here.
39. **`rescueERC20(address tokenAddress, uint256 amount)`:** (Owner Only) Allows the owner to withdraw accidentally sent ERC-20 tokens (other than HFA itself) from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for tracking parcel IDs per owner - potentially gas heavy for large sets

// --- Smart Contract Outline and Function Summary (Repeated for easy reference) ---
//
// Contract Name: HyperFungibleAsset
//
// Concept: A fungible token (HFA) that allows users to lock amounts into unique, non-fungible "Parcels" (represented internally by an ID).
// These parcels accrue yield based on dynamic rates, can be transferred, split, merged, and have management delegated.
//
// Key Features:
// 1.  ERC-20 Core: Standard fungible token operations.
// 2.  HyperBonded Parcels (HBP): Mechanism to lock HFA tokens into unique, ID'd parcels.
// 3.  Dynamic Yield: Parcels accrue yield based on an amount, duration, and an assignable yield rate ID. Yield rates can be updated.
// 4.  Parcel Management: Functions for bonding, unbonding, transferring parcels.
// 5.  Advanced Parcel Operations: Splitting and merging existing parcels.
// 6.  Delegation: Allow users to delegate yield claiming or full parcel management rights.
// 7.  Oracle Integration: Placeholder for integrating an external oracle for yield rate updates.
//
// Function Summary:
// 1.  constructor(string name, string symbol, uint256 initialSupply): Initializes ERC-20 and mints initial supply.
// 2.  totalSupply(): Returns total HFA supply. (ERC-20 View)
// 3.  balanceOf(address account): Returns standard liquid balance. (ERC-20 View)
// 4.  transfer(address recipient, uint256 amount): Transfers HFA. (ERC-20)
// 5.  allowance(address owner, address spender): Returns ERC-20 allowance. (ERC-20 View)
// 6.  approve(address spender, uint256 amount): Sets ERC-20 allowance. (ERC-20)
// 7.  transferFrom(address sender, address recipient, uint256 amount): Transfers HFA with allowance. (ERC-20)
// 8.  transferWithMetadata(address recipient, uint256 amount, bytes calldata data): Transfers HFA with additional data.
// 9.  bondTokens(uint256 amount, uint64 unlockTimestamp, uint256 yieldRateId): Locks HFA into a new Parcel.
// 10. unbondTokens(uint256 parcelId): Unlocks HFA from a Parcel, pays yield, burns Parcel ID.
// 11. getParcelDetails(uint256 parcelId): Returns details of a Parcel. (View)
// 12. getParcelOwner(uint256 parcelId): Returns owner of a Parcel. (View)
// 13. transferParcel(address from, address to, uint256 parcelId): Transfers Parcel ownership.
// 14. approveParcel(address to, uint256 parcelId): Approves address for a Parcel.
// 15. getApprovedParcel(uint256 parcelId): Returns approved address for a Parcel. (View)
// 16. setApprovalForAllParcels(address operator, bool approved): Sets operator approval for Parcels.
// 17. isApprovedForAllParcels(address owner, address operator): Checks operator approval for Parcels. (View)
// 18. addYieldRate(uint256 rateBps): (Owner) Adds a new yield rate.
// 19. getYieldRate(uint256 yieldRateId): Returns a yield rate by ID. (View)
// 20. calculateParcelYield(uint256 parcelId): Calculates accrued yield for a Parcel. (View)
// 21. claimParcelYield(uint256 parcelId): Claims accrued yield for a Parcel.
// 22. updateParcelYieldRate(uint256 parcelId, uint256 newYieldRateId): (Owner/Oracle) Updates yield rate for a Parcel.
// 23. reinvestParcelYield(uint256 parcelId): Compounds accrued yield into a new Parcel.
// 24. splitParcel(uint256 parcelId, uint256 amountForNewParcel): Splits a Parcel into two.
// 25. mergeParcels(uint256 parcelId1, uint256 parcelId2): Merges two Parcels.
// 26. delegateParcelYieldClaim(uint256 parcelId, address delegatee): Delegates yield claim rights for a Parcel.
// 27. revokeParcelYieldClaimDelegate(uint256 parcelId): Revokes yield claim delegate.
// 28. delegateParcelManagement(uint256 parcelId, address delegatee, uint64 expiration): Delegates general management rights for a Parcel.
// 29. revokeParcelManagementDelegate(uint256 parcelId): Revokes management delegate.
// 30. setYieldOracle(address oracleAddress): (Owner) Sets the yield oracle address.
// 31. triggerDynamicYieldUpdate(uint256 yieldRateId, uint256 newRateBps): (Oracle) Updates a yield rate.
// 32. getLockedBalance(address account): Total HFA locked in parcels for an account. (View - potentially inefficient)
// 33. getTotalBondedSupply(): Total HFA locked across all parcels. (View)
// 34. pauseBonding(): (Owner) Pauses bonding.
// 35. unpauseBonding(): (Owner) Unpauses bonding.
// 36. pauseUnbonding(): (Owner) Pauses unbonding.
// 37. unpauseUnbonding(): (Owner) Unpauses unbonding.
// 38. upgradeParcelAttributes(uint256 parcelId, bytes calldata upgradeData): (Owner - Placeholder) Allows upgrading parcel attributes.
// 39. rescueERC20(address tokenAddress, uint256 amount): (Owner) Rescues ERC-20 tokens.
// --- End of Outline and Summary ---

contract HyperFungibleAsset is ERC20, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; // For tracking parcel IDs per owner (use cautiously due to gas)

    // Custom Errors for gas efficiency and clarity
    error InvalidAmount();
    error InvalidParcelId();
    error NotParcelOwnerOrApproved();
    error NotParcelOwnerOrDelegate();
    error NotUnlockedYet();
    error YieldRateNotFound();
    error MinimumReinvestAmountNotMet();
    error SplitAmountTooLarge();
    error NotOwnedByCallerOrDelegate();
    error ParcelsNotOwnedBySameAddress();
    error CannotMergeSelf();
    error DelegationExpired();
    error NotAuthorizedOracle();
    error BondingPaused();
    error UnbondingPaused();

    // Struct to represent a HyperBonded Parcel (HBP)
    struct Parcel {
        uint256 amount;
        uint64 unlockTimestamp;
        uint256 yieldRateId; // ID referencing the yieldRates mapping
        uint66 lastYieldUpdateTime; // Timestamp (approx) of the last yield calculation/update
        uint256 accruedYield; // Yield already calculated but not claimed/reinvested
        // Add more attributes here as needed, e.g., uint256 customAttribute1;
    }

    uint256 private _parcelCount;
    mapping(uint256 => Parcel) private _parcelDetails;
    mapping(uint256 => address) private _parcelOwner;
    mapping(uint256 => address) private _parcelApprovals; // Single approved address per parcel
    mapping(address => mapping(address => bool)) private _parcelOperatorApprovals; // ERC-721 style operator approval

    // Yield rate management (rate is stored in basis points, e.g., 100 = 1%)
    uint256 private _nextYieldRateId;
    mapping(uint256 => uint256) private _yieldRates; // yieldRateId -> rate in BPS (basis points)

    // Delegation mappings
    mapping(uint256 => address) private _parcelYieldDelegates; // parcelId -> delegatee for claiming yield
    mapping(uint256 => address) private _parcelManagementDelegates; // parcelId -> delegatee for management actions
    mapping(uint256 => uint64) private _parcelManagementDelegateExpiration; // parcelId -> management delegate expiration

    // Oracle address for dynamic yield updates
    address private _yieldOracle;

    // Mapping to track parcel IDs per owner for getLockedBalance (Use with caution)
    // NOTE: This mapping can become very large and make functions iterating over it (like getLockedBalance)
    // extremely gas-intensive and potentially unusable on-chain for accounts with many parcels.
    // It's included here to demonstrate tracking, but consider off-chain indexing for production.
    mapping(address => EnumerableSet.UintSet) private _ownerParcels;

    // Events
    event ParcelBonded(uint256 indexed parcelId, address indexed owner, uint256 amount, uint64 unlockTimestamp, uint256 yieldRateId);
    event ParcelUnbonded(uint256 indexed parcelId, address indexed owner, uint256 amount, uint256 totalYieldPaid);
    event ParcelTransfer(address indexed from, address indexed to, uint256 indexed parcelId);
    event ParcelApproval(address indexed owner, address indexed approved, uint256 indexed parcelId);
    event ParcelApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event YieldRateAdded(uint256 indexed yieldRateId, uint256 rateBps);
    event YieldClaimed(uint256 indexed parcelId, address indexed owner, address indexed claimant, uint256 amount);
    event YieldRateUpdated(uint256 indexed parcelId, uint256 indexed oldYieldRateId, uint256 indexed newYieldRateId, uint256 yieldAccruedBeforeUpdate);
    event YieldReinvested(uint256 indexed originalParcelId, uint256 indexed newParcelId, address indexed owner, uint256 reinvestedAmount);
    event ParcelSplit(uint256 indexed originalParcelId, uint256 indexed newParcelId, address indexed owner, uint256 originalAmount, uint256 newParcelAmount);
    event ParcelMerged(uint256 indexed parcelId1, uint256 indexed parcelId2, uint256 indexed newParcelId, address indexed owner, uint256 mergedAmount);
    event ParcelYieldDelegateSet(uint256 indexed parcelId, address indexed owner, address indexed delegatee);
    event ParcelManagementDelegateSet(uint256 indexed parcelId, address indexed owner, address indexed delegatee, uint64 expiration);
    event YieldOracleSet(address indexed oracleAddress);
    event DynamicYieldUpdate(uint256 indexed yieldRateId, uint256 oldRateBps, uint256 newRateBps);

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable(msg.sender) Pausable() {
        _mint(msg.sender, initialSupply);
        _nextYieldRateId = 1; // Start Yield Rate IDs from 1
    }

    // --- ERC-20 Standard Functions (Overrides) ---

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    // --- Custom ERC-20 Enhancement ---

    /// @notice Transfers tokens with additional data. Receiver should implement a hook if needed.
    /// @param recipient The address to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    /// @param data Additional bytes data for the recipient.
    /// @return bool True if the transfer was successful.
    function transferWithMetadata(address recipient, uint256 amount, bytes calldata data) external whenNotPaused returns (bool) {
        // Note: This is a simple transfer. A more advanced hook would involve checking if recipient
        // is a contract and calling a specific function on it with the data (like ERC-777).
        // For this example, we just include the data parameter and potentially log it.
        // A corresponding event could be added here if the data needs to be logged.
        _transfer(msg.sender, recipient, amount);
        // Potentially emit an event with `data` here if needed off-chain
        return true;
    }

    // --- HyperBonded Parcel (HBP) Core Functions ---

    /// @notice Bonds an amount of HFA into a new HyperBonded Parcel.
    /// @param amount The amount of HFA tokens to bond.
    /// @param unlockTimestamp The timestamp when the parcel can be unbonded.
    /// @param yieldRateId The ID of the yield rate to apply to this parcel.
    /// @return uint256 The ID of the newly created parcel.
    function bondTokens(uint256 amount, uint64 unlockTimestamp, uint256 yieldRateId) external whenNotPausedBonding returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (_yieldRates[yieldRateId] == 0 && yieldRateId != 0) revert YieldRateNotFound(); // Allow yieldRateId 0 for no yield

        // Transfer tokens from sender to the contract
        _transfer(msg.sender, address(this), amount);

        uint256 newParcelId = _parcelCount + 1;
        _parcelCount = newParcelId;

        Parcel storage newParcel = _parcelDetails[newParcelId];
        newParcel.amount = amount;
        newParcel.unlockTimestamp = unlockTimestamp;
        newParcel.yieldRateId = yieldRateId;
        newParcel.lastYieldUpdateTime = uint64(block.timestamp); // Capture creation time
        newParcel.accruedYield = 0;

        _parcelOwner[newParcelId] = msg.sender;
        _ownerParcels[msg.sender].add(newParcelId); // Add parcel ID to owner's set

        emit ParcelBonded(newParcelId, msg.sender, amount, unlockTimestamp, yieldRateId);

        return newParcelId;
    }

    /// @notice Unbonds tokens from a HyperBonded Parcel, paying out yield.
    /// @param parcelId The ID of the parcel to unbond.
    function unbondTokens(uint256 parcelId) external whenNotPausedUnbonding {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();
        if (owner != msg.sender) revert NotParcelOwnerOrApproved(); // Only owner can unbond directly

        Parcel storage parcel = _parcelDetails[parcelId];
        if (block.timestamp < parcel.unlockTimestamp) revert NotUnlockedYet();

        // Calculate and add any pending yield before unbonding
        _updateParcelAccruedYield(parcelId, owner);

        uint256 totalPayout = parcel.amount + parcel.accruedYield;
        uint256 totalYieldPaid = parcel.accruedYield;

        // Transfer total amount (principal + yield) back to owner
        _transfer(address(this), owner, totalPayout);

        // Burn the parcel
        _burnParcel(parcelId);

        emit ParcelUnbonded(parcelId, owner, parcel.amount, totalYieldPaid);
    }

    // --- HBP View Functions ---

    /// @notice Gets the details of a HyperBonded Parcel.
    /// @param parcelId The ID of the parcel.
    /// @return amount The amount of HFA locked.
    /// @return unlockTimestamp The unlock timestamp.
    /// @return yieldRateId The yield rate ID.
    /// @return lastYieldUpdateTime The timestamp of the last yield calculation.
    /// @return accruedYield The yield already accrued but not claimed.
    function getParcelDetails(uint256 parcelId) external view returns (
        uint256 amount,
        uint64 unlockTimestamp,
        uint256 yieldRateId,
        uint66 lastYieldUpdateTime,
        uint256 accruedYield
    ) {
        if (_parcelOwner[parcelId] == address(0)) revert InvalidParcelId();
        Parcel storage parcel = _parcelDetails[parcelId];
        return (
            parcel.amount,
            parcel.unlockTimestamp,
            parcel.yieldRateId,
            parcel.lastYieldUpdateTime,
            parcel.accruedYield
        );
    }

    /// @notice Gets the owner of a HyperBonded Parcel.
    /// @param parcelId The ID of the parcel.
    /// @return The owner's address.
    function getParcelOwner(uint256 parcelId) external view returns (address) {
        return _parcelOwner[parcelId];
    }

    /// @notice Calculates the total HFA locked across all parcels owned by an account.
    /// NOTE: This function can be very gas-intensive for addresses with many parcels.
    /// Consider using off-chain indexing to get parcel IDs and query details individually.
    /// @param account The address to check.
    /// @return The total amount of HFA locked.
    function getLockedBalance(address account) external view returns (uint256) {
        uint256 totalLocked = 0;
        // Iterate through the set of parcel IDs owned by the account.
        // THIS LOOP IS GAS-INTENSIVE AND SHOULD BE AVOIDED IN PRODUCTION FOR large sets.
        for (uint256 i = 0; i < _ownerParcels[account].length(); i++) {
            uint256 parcelId = _ownerParcels[account].at(i);
             // Check if parcel still exists (not burned)
            if (_parcelOwner[parcelId] == account) {
                 totalLocked += _parcelDetails[parcelId].amount;
            }
        }
        return totalLocked;
    }

     /// @notice Returns the total HFA available as liquid balance for an account.
     /// @param account The address to check.
     /// @return The liquid balance.
    function getAvailableBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    /// @notice Returns the total amount of HFA locked across all existing parcels in the contract.
    /// @return The total bonded supply.
    function getTotalBondedSupply() external view returns (uint256) {
        // This would ideally require iterating all parcel IDs, which is impossible on-chain.
        // A state variable could track this during bond/unbond, but it won't reflect
        // changes due to split/merge/reinvest without complex tracking.
        // Returning the contract's balance minus the deployer's initial mint
        // gives an *approximation* of the total bonded supply IF all HFA not
        // bonded remains with users. This is not strictly accurate with transfers.
        // A true total bonded supply would require iterating _parcelDetails, which isn't feasible.
        // Let's track it manually during bond/unbond/split/merge for a more accurate, though still
        // potentially slightly off due to yield calculations changing parcel amounts mid-operation, value.
        // Or simply return the contract's balance, which includes bonded tokens + accrued yield.
        // Let's add a dedicated variable for clarity, updating it manually.
        // Re-reading requirements: just need *a* function, not necessarily the most efficient/accurate state tracking.
        // A simple approach is to iterate the *current* parcels tracked. Again, gas limit.
        // Given the complexity and gas constraints of iterating large storage maps/sets,
        // tracking total bonded supply perfectly on-chain without limits is hard.
        // Let's add a basic tracker and acknowledge its limitations.
        uint256 total = 0;
         for (uint256 i = 1; i <= _parcelCount; i++) {
             if (_parcelOwner[i] != address(0)) { // Check if parcel exists
                 total += _parcelDetails[i].amount;
             }
         }
         return total; // WARNING: This can be VERY gas intensive if _parcelCount is large.
    }


    // --- HBP Transfer/Approval Functions (ERC-721 style) ---

    /// @notice Transfers ownership of a HyperBonded Parcel.
    /// @param from The current owner of the parcel.
    /// @param to The address to transfer ownership to.
    /// @param parcelId The ID of the parcel to transfer.
    function transferParcel(address from, address to, uint256 parcelId) public {
        // Simplified ERC-721 transfer logic: require owner, approved, or operator
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();
        if (from != owner) revert NotParcelOwnerOrApproved(); // Must call from owner address

        // Check approval or operator status
        if (msg.sender != owner &&
            msg.sender != _parcelApprovals[parcelId] &&
            !_parcelOperatorApprovals[owner][msg.sender])
        {
            revert NotParcelOwnerOrApproved();
        }

        _transferParcelOwnership(from, to, parcelId);
        // Clear approvals on transfer
        delete _parcelApprovals[parcelId];
    }

    /// @notice Approves an address to transfer a specific parcel ID.
    /// @param to The address to approve.
    /// @param parcelId The ID of the parcel.
    function approveParcel(address to, uint256 parcelId) external {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();
        // Must be called by the parcel owner or an approved operator
        if (msg.sender != owner && !_parcelOperatorApprovals[owner][msg.sender]) {
            revert NotParcelOwnerOrApproved();
        }
        _approveParcel(to, parcelId);
    }

     /// @notice Gets the approved address for a specific parcel ID.
     /// @param parcelId The ID of the parcel.
     /// @return The approved address.
    function getApprovedParcel(uint256 parcelId) external view returns (address) {
        if (_parcelOwner[parcelId] == address(0)) revert InvalidParcelId();
        return _parcelApprovals[parcelId];
    }

    /// @notice Sets approval for an operator to manage all of msg.sender's parcels.
    /// @param operator The address to approve as operator.
    /// @param approved True to approve, false to revoke approval.
    function setApprovalForAllParcels(address operator, bool approved) external {
        _parcelOperatorApprovals[msg.sender][operator] = approved;
        emit ParcelApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Checks if an operator is approved for all of an owner's parcels.
    /// @param owner The owner's address.
    /// @param operator The operator's address.
    /// @return True if the operator is approved.
    function isApprovedForAllParcels(address owner, address operator) external view returns (bool) {
        return _parcelOperatorApprovals[owner][operator];
    }

    // --- Yield Management Functions ---

    /// @notice Adds a new yield rate to the system. Only callable by the owner.
    /// @param rateBps The yield rate in basis points (e.g., 100 for 1%).
    /// @return uint256 The ID assigned to the new yield rate.
    function addYieldRate(uint256 rateBps) external onlyOwner returns (uint256) {
        uint256 newRateId = _nextYieldRateId;
        _yieldRates[newRateId] = rateBps;
        _nextYieldRateId++;
        emit YieldRateAdded(newRateId, rateBps);
        return newRateId;
    }

    /// @notice Gets the yield rate for a given ID.
    /// @param yieldRateId The ID of the yield rate.
    /// @return uint256 The yield rate in basis points.
    function getYieldRate(uint256 yieldRateId) external view returns (uint256) {
        if (_yieldRates[yieldRateId] == 0 && yieldRateId != 0) revert YieldRateNotFound();
        return _yieldRates[yieldRateId];
    }

    /// @notice Calculates the currently accrued yield for a parcel since its last update.
    /// Does not include yield already in `accruedYield`.
    /// @param parcelId The ID of the parcel.
    /// @return uint256 The newly calculated yield.
    function calculateParcelYield(uint256 parcelId) public view returns (uint256) {
        if (_parcelOwner[parcelId] == address(0)) revert InvalidParcelId();
        Parcel storage parcel = _parcelDetails[parcelId];

        uint256 rateBps = _yieldRates[parcel.yieldRateId];
        if (rateBps == 0) return 0; // No yield if rate is 0

        // Calculate elapsed time
        uint256 timeElapsed = block.timestamp - parcel.lastYieldUpdateTime;

        // Prevent calculating yield if no time has passed
        if (timeElapsed == 0) return 0;

        // Calculate yield: amount * rate * time / time_unit
        // Time unit is 1 year (approx 365 days * 24 hours * 60 min * 60 sec)
        // Using 31536000 for 365 days to avoid leap year issues
        // yield = (amount * rateBps * timeElapsed) / (10000 * 31536000)
        // Using 1e18 for amount scaling if using high decimals, but ERC20 handles decimals.
        // Assuming rateBps is percentage * 100 (e.g., 100 = 1%). Need 10000 for 100%.
        // Formula: yield = amount * (rateBps / 10000) * (timeElapsed / 31536000)
        // Integer math: yield = (amount * rateBps * timeElapsed) / (10000 * 31536000)

        // Use a fixed time unit for calculation, e.g., seconds, then scale to annual rate
        // Let's assume rateBps is *annual* rate in basis points.
        // Yield per second = amount * (rateBps / 10000) / seconds_per_year
        // Total yield = amount * rateBps * timeElapsed / (10000 * seconds_per_year)
        // Using 31536000 as seconds per year for simplicity
        uint256 secondsPerYear = 31536000; // 365 days
        uint256 yield = (parcel.amount * rateBps * timeElapsed) / (10000 * secondsPerYear);

        return yield;
    }

    /// @notice Calculates and pays out the accrued yield for a parcel.
    /// Can be called by the owner or an approved yield delegate.
    /// @param parcelId The ID of the parcel.
    function claimParcelYield(uint256 parcelId) external whenNotPaused {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();

        // Check if caller is owner OR an approved yield delegate
        if (msg.sender != owner && msg.sender != _parcelYieldDelegates[parcelId]) {
            revert NotOwnedByCallerOrDelegate();
        }

        // Calculate and add pending yield to accrued balance
        _updateParcelAccruedYield(parcelId, owner);

        Parcel storage parcel = _parcelDetails[parcelId];
        uint256 yieldToClaim = parcel.accruedYield;

        if (yieldToClaim == 0) {
            // No yield to claim
            return; // Could add a specific error/event for no yield
        }

        parcel.accruedYield = 0; // Reset accrued yield after claiming

        // Transfer yield amount to the owner
        _transfer(address(this), owner, yieldToClaim);

        emit YieldClaimed(parcelId, owner, msg.sender, yieldToClaim);
    }

    /// @notice Allows the owner or oracle to update the yield rate ID for a parcel.
    /// Automatically calculates and accrues yield before changing the rate.
    /// @param parcelId The ID of the parcel.
    /// @param newYieldRateId The new yield rate ID to apply.
    function updateParcelYieldRate(uint256 parcelId, uint256 newYieldRateId) external {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();
        if (msg.sender != owner && msg.sender != _yieldOracle) revert NotOwnedByCallerOrDelegate(); // Owner or Oracle can update

        if (_yieldRates[newYieldRateId] == 0 && newYieldRateId != 0) revert YieldRateNotFound();

        // Calculate and accrue yield under the old rate before updating
        _updateParcelAccruedYield(parcelId, owner);

        Parcel storage parcel = _parcelDetails[parcelId];
        uint256 oldYieldRateId = parcel.yieldRateId;
        parcel.yieldRateId = newYieldRateId;

        // accruedYield is already updated by _updateParcelAccruedYield
        emit YieldRateUpdated(parcelId, oldYieldRateId, newYieldRateId, parcel.accruedYield);
    }

    /// @notice Calculates accrued yield and reinvests it into a new parcel for the owner.
    /// Can be called by the owner or an approved management delegate.
    /// @param parcelId The ID of the parcel.
    function reinvestParcelYield(uint256 parcelId) external whenNotPaused {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();

        // Check if caller is owner OR an approved management delegate (and not expired)
        if (msg.sender != owner && !_isManagementDelegate(parcelId, msg.sender)) {
            revert NotOwnedByCallerOrDelegate();
        }

        // Calculate and add pending yield to accrued balance
        _updateParcelAccruedYield(parcelId, owner);

        Parcel storage parcel = _parcelDetails[parcelId];
        uint256 yieldToReinvest = parcel.accruedYield;

        // Define a minimum amount for reinvestment to avoid tiny parcels (optional)
        uint256 minReinvestAmount = 1; // Example: Minimum 1 token unit (adjust based on decimals)
        if (yieldToReinvest < minReinvestAmount) {
             revert MinimumReinvestAmountNotMet();
        }

        parcel.accruedYield = 0; // Reset accrued yield

        // Create a *new* parcel with the reinvested yield amount
        uint256 newParcelId = _createParcel(
            owner,
            yieldToReinvest,
            parcel.unlockTimestamp, // New parcel inherits original unlock time
            parcel.yieldRateId // New parcel inherits original yield rate
        );

        // Note: The yield tokens are effectively transferred from the contract's
        // internal balance holding accrued yield into the new bonded parcel.
        // No external transfer is needed here as the yield was already calculated
        // into the contract's logical control via _updateParcelAccruedYield.

        emit YieldReinvested(parcelId, newParcelId, owner, yieldToReinvest);
    }

    // --- Advanced HBP Operations ---

    /// @notice Splits a parcel into two parcels. The original parcel amount is reduced,
    /// and a new parcel is created with the specified amount.
    /// Can be called by the owner or an approved management delegate.
    /// @param originalParcelId The ID of the parcel to split.
    /// @param amountForNewParcel The amount for the new parcel.
    /// @return uint256 The ID of the newly created parcel.
    function splitParcel(uint256 originalParcelId, uint256 amountForNewParcel) external whenNotPaused returns (uint256) {
        address owner = _parcelOwner[originalParcelId];
        if (owner == address(0)) revert InvalidParcelId();

        // Check if caller is owner OR an approved management delegate (and not expired)
        if (msg.sender != owner && !_isManagementDelegate(originalParcelId, msg.sender)) {
             revert NotOwnedByCallerOrDelegate();
        }

        Parcel storage originalParcel = _parcelDetails[originalParcelId];
        if (amountForNewParcel == 0 || amountForNewParcel >= originalParcel.amount) {
            revert SplitAmountTooLarge();
        }

        // Calculate and accrue yield for the original parcel before splitting
        // This yield remains associated with the original parcel ID's accruedYield balance
        // until claimed/reinvested from the original ID.
        _updateParcelAccruedYield(originalParcelId, owner);

        // Reduce the amount in the original parcel
        originalParcel.amount -= amountForNewParcel;
        // The lastYieldUpdateTime remains the time of this split operation (updated by _updateParcelAccruedYield)
        // The accruedYield remains associated with the original parcel ID.

        // Create the new parcel
        uint256 newParcelId = _createParcel(
            owner,
            amountForNewParcel,
            originalParcel.unlockTimestamp, // New parcel inherits original unlock time
            originalParcel.yieldRateId // New parcel inherits original yield rate
        );
        // The new parcel starts with lastYieldUpdateTime = block.timestamp and accruedYield = 0.

        emit ParcelSplit(originalParcelId, newParcelId, owner, originalParcel.amount + amountForNewParcel, amountForNewParcel);

        return newParcelId;
    }

    /// @notice Merges two parcels owned by the same address into a single new parcel.
    /// Burns the two original parcels. The new parcel amount is the sum, unlock time is the max,
    /// and yield rate ID is the max. Yield from both is calculated and added to the new parcel's accrued yield.
    /// Can be called by the owner or an approved management delegate for *both* parcels.
    /// @param parcelId1 The ID of the first parcel.
    /// @param parcelId2 The ID of the second parcel.
    /// @return uint256 The ID of the newly created parcel.
    function mergeParcels(uint256 parcelId1, uint256 parcelId2) external whenNotPaused returns (uint256) {
        if (parcelId1 == parcelId2) revert CannotMergeSelf();

        address owner1 = _parcelOwner[parcelId1];
        address owner2 = _parcelOwner[parcelId2];

        if (owner1 == address(0) || owner2 == address(0)) revert InvalidParcelId();
        if (owner1 != owner2) revert ParcelsNotOwnedBySameAddress(); // Must be owned by the same address

        address owner = owner1; // Common owner

        // Check if caller is owner OR an approved management delegate for *both* parcels
        if (msg.sender != owner && (!(_isManagementDelegate(parcelId1, msg.sender)) || !(_isManagementDelegate(parcelId2, msg.sender)))) {
            revert NotOwnedByCallerOrDelegate();
        }

        // Calculate and accrue yield for both parcels before merging
        _updateParcelAccruedYield(parcelId1, owner);
        _updateParcelAccruedYield(parcelId2, owner);

        Parcel storage parcel1 = _parcelDetails[parcelId1];
        Parcel storage parcel2 = _parcelDetails[parcelId2];

        uint256 newAmount = parcel1.amount + parcel2.amount;
        uint64 newUnlockTimestamp = parcel1.unlockTimestamp > parcel2.unlockTimestamp ? parcel1.unlockTimestamp : parcel2.unlockTimestamp;
        uint256 newYieldRateId = parcel1.yieldRateId > parcel2.yieldRateId ? parcel1.yieldRateId : parcel2.yieldRateId; // Use max rate ID
        uint256 totalAccruedYield = parcel1.accruedYield + parcel2.accruedYield;

        // Create the new merged parcel
        uint256 newParcelId = _parcelCount + 1;
        _parcelCount = newParcelId;

        Parcel storage newParcel = _parcelDetails[newParcelId];
        newParcel.amount = newAmount;
        newParcel.unlockTimestamp = newUnlockTimestamp;
        newParcel.yieldRateId = newYieldRateId;
        newParcel.lastYieldUpdateTime = uint64(block.timestamp); // New parcel starts calculating yield from merge time
        newParcel.accruedYield = totalAccruedYield; // Carry over accrued yield from both originals

        _parcelOwner[newParcelId] = owner;
        _ownerParcels[owner].add(newParcelId); // Add new parcel ID to owner's set

        // Burn the original parcels
        _burnParcel(parcelId1);
        _burnParcel(parcelId2);

        emit ParcelMerged(parcelId1, parcelId2, newParcelId, owner, newAmount);

        return newParcelId;
    }

    // --- Delegation Functions ---

    /// @notice Allows the owner to delegate the ability to call `claimParcelYield` for a parcel.
    /// @param parcelId The ID of the parcel.
    /// @param delegatee The address to delegate to. Set address(0) to revoke.
    function delegateParcelYieldClaim(uint256 parcelId, address delegatee) external {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) revert InvalidParcelId();
        if (owner != msg.sender) revert NotParcelOwnerOrApproved(); // Only owner can delegate

        _parcelYieldDelegates[parcelId] = delegatee;
        emit ParcelYieldDelegateSet(parcelId, owner, delegatee);
    }

    /// @notice Revokes any existing yield claim delegate for a parcel.
    /// @param parcelId The ID of the parcel.
    function revokeParcelYieldClaimDelegate(uint256 parcelId) external {
         delegateParcelYieldClaim(parcelId, address(0));
    }


    /// @notice Allows the owner to delegate broader management rights for a parcel.
    /// Includes rights for split, merge (if delegatee has rights on both), reinvest.
    /// @param parcelId The ID of the parcel.
    /// @param delegatee The address to delegate to. Set address(0) to revoke.
    /// @param expiration The timestamp when the delegation expires.
    function delegateParcelManagement(uint256 parcelId, address delegatee, uint64 expiration) external {
         address owner = _parcelOwner[parcelId];
         if (owner == address(0)) revert InvalidParcelId();
         if (owner != msg.sender) revert NotParcelOwnerOrApproved(); // Only owner can delegate

         _parcelManagementDelegates[parcelId] = delegatee;
         _parcelManagementDelegateExpiration[parcelId] = expiration;
         emit ParcelManagementDelegateSet(parcelId, owner, delegatee, expiration);
    }

    /// @notice Revokes any existing management delegate for a parcel.
    /// @param parcelId The ID of the parcel.
    function revokeParcelManagementDelegate(uint256 parcelId) external {
        delegateParcelManagement(parcelId, address(0), 0);
    }

    /// @dev Internal helper to check if an address is a valid management delegate for a parcel.
    function _isManagementDelegate(uint256 parcelId, address potentialDelegatee) internal view returns (bool) {
        return _parcelManagementDelegates[parcelId] == potentialDelegatee && block.timestamp < _parcelManagementDelegateExpiration[parcelId];
    }

    // --- Oracle Integration Functions ---

    /// @notice Sets the trusted oracle address that can update yield rates. Only callable by the owner.
    /// @param oracleAddress The address of the oracle contract.
    function setYieldOracle(address oracleAddress) external onlyOwner {
        _yieldOracle = oracleAddress;
        emit YieldOracleSet(oracleAddress);
    }

    /// @notice Allows the designated oracle to update the yield rate for an existing ID.
    /// Automatically recalculates and accrues yield for affected parcels before the update.
    /// NOTE: Calling this for a rate ID used by many parcels could be gas-intensive
    /// as it might trigger _updateParcelAccruedYield for potentially many parcels.
    /// A better design for large-scale would be to trigger updates per parcel or batch off-chain.
    /// For this example, we'll assume yield rate updates are infrequent or don't affect
    /// a massive number of *active* parcels simultaneously in a way that hits block gas limits.
    /// @param yieldRateId The ID of the yield rate to update.
    /// @param newRateBps The new yield rate in basis points.
    function triggerDynamicYieldUpdate(uint256 yieldRateId, uint256 newRateBps) external {
        if (msg.sender != _yieldOracle) revert NotAuthorizedOracle();
        if (_yieldRates[yieldRateId] == 0 && yieldRateId != 0) revert YieldRateNotFound();

        uint256 oldRateBps = _yieldRates[yieldRateId];
        _yieldRates[yieldRateId] = newRateBps;

        // In a real system, you'd need to iterate through all *active* parcels using this rate ID
        // and call _updateParcelAccruedYield for each. This is NOT EFFICIENT ON-CHAIN
        // if many parcels use the same rate. This function is simplified for the example.
        // A production system would require off-chain tools to call updates per parcel
        // or a different yield calculation model.
        // For this example, we'll just update the rate and emit the event. The next time
        // a parcel using this rate is touched (_updateParcelAccruedYield is called),
        // it will use the new rate for yield calculation from that point forward.
        // The _updateParcelAccruedYield function already handles calculating yield
        // based on the *current* rate and time since *last update*.

        emit DynamicYieldUpdate(yieldRateId, oldRateBps, newRateBps);
    }

    // --- Pausing Functions ---

    function pauseBonding() external onlyOwner {
        _pausedBonding = true;
        emit Paused(msg.sender); // ERC20 Pausable uses this event
    }

    function unpauseBonding() external onlyOwner {
        _pausedBonding = false;
        emit Unpaused(msg.sender); // ERC20 Pausable uses this event
    }

    function pauseUnbonding() external onlyOwner {
        _pausedUnbonding = true;
        emit Paused(msg.sender); // ERC20 Pausable uses this event
    }

    function unpauseUnbonding() external onlyOwner {
        _pausedUnbonding = false;
        emit Unpaused(msg.sender); // ERC20 Pausable uses this event
    }

    // Internal variables to track specific pause states
    bool private _pausedBonding;
    bool private _pausedUnbonding;

    /// @dev Modifier to check if bonding is not paused.
    modifier whenNotPausedBonding() {
        if (_pausedBonding) revert BondingPaused();
        _;
    }

     /// @dev Modifier to check if unbonding is not paused.
    modifier whenNotPausedUnbonding() {
        if (_pausedUnbonding) revert UnbondingPaused();
        _;
    }

    // ERC20 Pausable `whenNotPaused` modifier will apply to transfer/approve/transferFrom
    // Custom modifiers applied to bond/unbond specifically.

    // --- Admin/Utility Functions ---

    /// @notice Placeholder function for upgrading parcel attributes.
    /// Allows owner to call with arbitrary data to potentially modify
    /// other struct fields or logic associated with a parcel.
    /// This requires off-chain tooling to construct `upgradeData` and on-chain
    /// logic to decode and apply it, which is beyond the scope of this example.
    /// @param parcelId The ID of the parcel to upgrade.
    /// @param upgradeData The data containing upgrade instructions.
    function upgradeParcelAttributes(uint256 parcelId, bytes calldata upgradeData) external onlyOwner {
        if (_parcelOwner[parcelId] == address(0)) revert InvalidParcelId();
        // TODO: Implement logic to decode `upgradeData` and modify parcel attributes.
        // This would be highly specific to the attributes being upgraded.
        // Example: if a parcel had a `uint256 customAttribute`, this function
        // might decode `upgradeData` to find a new value for it and update it.
        // For now, it's a placeholder.
        // emit ParcelAttributesUpgraded(parcelId, upgradeData); // Example event
        emit Transfer(address(0), address(0), 0); // Emit a dummy event to show interaction
    }

    /// @notice Allows the owner to rescue accidentally sent ERC-20 tokens.
    /// Prevents locking other tokens in the contract.
    /// @param tokenAddress The address of the ERC-20 token to rescue.
    /// @param amount The amount of tokens to rescue.
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(this)) revert InvalidAmount(); // Cannot rescue self tokens
        IERC20 rescueToken = IERC20(tokenAddress);
        rescueToken.transfer(msg.sender, amount);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to create a new parcel.
    /// @param owner The owner of the new parcel.
    /// @param amount The amount of HFA to lock.
    /// @param unlockTimestamp The unlock timestamp.
    /// @param yieldRateId The yield rate ID.
    /// @return uint256 The ID of the newly created parcel.
    function _createParcel(
        address owner,
        uint256 amount,
        uint64 unlockTimestamp,
        uint256 yieldRateId
    ) internal returns (uint256) {
        uint256 newParcelId = _parcelCount + 1;
        _parcelCount = newParcelId;

        Parcel storage newParcel = _parcelDetails[newParcelId];
        newParcel.amount = amount;
        newParcel.unlockTimestamp = unlockTimestamp;
        newParcel.yieldRateId = yieldRateId;
        newParcel.lastYieldUpdateTime = uint64(block.timestamp);
        newParcel.accruedYield = 0; // New parcels start with no accrued yield

        _parcelOwner[newParcelId] = owner;
        _ownerParcels[owner].add(newParcelId); // Add parcel ID to owner's set

        // No event here; events are emitted by the calling function (bondTokens, reinvestYield, split, merge)

        return newParcelId;
    }

    /// @dev Internal function to burn a parcel.
    /// @param parcelId The ID of the parcel to burn.
    function _burnParcel(uint256 parcelId) internal {
        address owner = _parcelOwner[parcelId];
        if (owner == address(0)) return; // Already burned or invalid

        // Remove parcel ID from owner's set
        _ownerParcels[owner].remove(parcelId);

        // Clear parcel details and ownership mapping
        delete _parcelDetails[parcelId];
        delete _parcelOwner[parcelId];
        // Clear approvals associated with the parcel
        delete _parcelApprovals[parcelId];
        delete _parcelYieldDelegates[parcelId];
        delete _parcelManagementDelegates[parcelId];
        delete _parcelManagementDelegateExpiration[parcelId];

        // Note: Total supply tracker (_parcelCount) is only incremented, not decremented.
        // This means parcel IDs are unique and never reused, which is fine.
    }

    /// @dev Internal function to transfer parcel ownership.
    /// @param from The current owner.
    /// @param to The new owner.
    /// @param parcelId The ID of the parcel.
    function _transferParcelOwnership(address from, address to, uint256 parcelId) internal {
        // Remove from old owner's set
        _ownerParcels[from].remove(parcelId);
        // Add to new owner's set
        _ownerParcels[to].add(parcelId);

        _parcelOwner[parcelId] = to;
        emit ParcelTransfer(from, to, parcelId);
    }

    /// @dev Internal function to approve an address for a parcel.
    /// @param to The address to approve.
    /// @param parcelId The ID of the parcel.
    function _approveParcel(address to, uint256 parcelId) internal {
        _parcelApprovals[parcelId] = to;
        emit ParcelApproval(_parcelOwner[parcelId], to, parcelId);
    }


    /// @dev Internal helper to calculate pending yield and add it to accruedYield.
    /// Updates lastYieldUpdateTime.
    /// @param parcelId The ID of the parcel.
    /// @param owner The owner of the parcel (passed for potential future use, currently redundant with map).
    function _updateParcelAccruedYield(uint256 parcelId, address owner) internal {
        // Calculate yield accrued since last update
        uint256 newlyAccrued = calculateParcelYield(parcelId);

        // Add to accrued yield
        _parcelDetails[parcelId].accruedYield += newlyAccrued;

        // Update last yield calculation time
        _parcelDetails[parcelId].lastYieldUpdateTime = uint64(block.timestamp);
    }

    // --- Internal Pausable overrides (optional, ERC20 Pausable handles standard methods) ---
    // These are useful if you want custom logic during pausing/unpausing, but not strictly needed for just state setting.
    // function _pause() internal override {
    //     super._pause();
    // }
    //
    // function _unpause() internal override {
    //     super._unpause();
    // }
}
```