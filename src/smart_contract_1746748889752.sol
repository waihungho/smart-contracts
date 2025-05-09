Okay, here is a Solidity smart contract concept called "AetheriumForge" that combines elements of dynamic NFTs, staking, crafting/transmutation with randomness, and role-based access control.

It manages two main assets:
1.  **Runes (ERC-721):** Unique NFTs with dynamic properties like 'charge' and 'runeType'.
2.  **Essence (Internal ERC-20):** A utility token used for charging Runes, crafting, and earned via staking.

**Advanced Concepts / Trendy Functions:**

*   **Dynamic NFTs:** Rune properties (`charge`, `runeType`) can change based on contract interactions (`chargeRune`, `decayRunes`, `combineRunes`). `tokenURI` reflects this state.
*   **Staking with Yield:** Stake Runes to earn Essence over time.
*   **Crafting/Transmutation:** Combine multiple Runes and Essence (with a 'Catalyst' concept via parameters) to create a new Rune with an outcome influenced by randomness.
*   **On-Chain Randomness Integration:** Designed to integrate with Chainlink VRF for randomness in crafting.
*   **Role-Based Access Control:** Granular permissions for different actions (minting, pausing, forging, setting parameters).
*   **Pausable:** Ability to pause critical functions in case of issues.
*   **Upgradeable Design:** Uses OpenZeppelin's UUPS standard for potential upgrades (though the proxy is not included).
*   **Batch Operations:** Example of a batch transfer function.
*   **Time-Based Decay:** Runes can lose 'charge' over time.
*   **Parameterized Mechanics:** Admin can set costs, yields, forging rules via parameters.

---

### AetheriumForge Smart Contract

**Outline:**

1.  **License & Pragma:** SPDX License Identifier and Solidity version.
2.  **Imports:** OpenZeppelin contracts (ERC721, ERC721Enumerable, AccessControl, Pausable, Initializable, UUPSUpgradeable) and Chainlink VRFConsumerBaseV2.
3.  **Error Definitions:** Custom errors for clarity.
4.  **Interfaces:** (None needed internally, but would be for external interactions).
5.  **Contract Definition:** Inherits from relevant base contracts.
6.  **Roles:** Define custom roles for AccessControl.
7.  **State Variables:**
    *   ERC721 (Runes) state: name, symbol, token counter, ownerOf, balance, approvals, etc. (handled by OZ base).
    *   Dynamic Rune State: Mappings for rune type, charge, last interaction time per token ID.
    *   ERC20 (Essence) state: name, symbol, total supply, balances, allowances.
    *   Staking State: Mappings for staked status, stake start time, accumulated yield per token ID.
    *   Crafting Parameters: Mappings/structs for defining crafting recipes/outcomes, Catalyst data.
    *   Yield Parameters: Rate of Essence generation per staked Rune.
    *   Randomness (VRF) State: VRF coordinator address, key hash, request IDs mapping, pending requests.
    *   Admin/System State: Base URI for metadata, pauser address, fee recipient, collected fees.
8.  **Events:** Events for key actions (Mint, Charge, Decay, Forge, Stake, Unstake, ClaimYield, ParametersUpdated, RoleGranted, etc.).
9.  **Modifiers:** (Handled by inherited Pausable and AccessControl).
10. **Initialization:** `initializer` function for proxy setup.
11. **ERC-721 Implementations:** Basic ERC-721 functions (handled by OZ), custom `tokenURI` logic.
12. **Internal Essence (ERC-20) Implementations:** Basic `balanceOf`, `transfer`, `approve`, `transferFrom`.
13. **Dynamic Rune Functionality:**
    *   `mintRune`
    *   `burnRune`
    *   `chargeRune`
    *   `decayRunes`
    *   `getRuneState`
14. **Staking Functionality:**
    *   `stakeRune`
    *   `unstakeRune`
    *   `claimEssenceYield`
    *   `getRuneStakeInfo`
    *   `setYieldParameters`
15. **Crafting/Forging Functionality:**
    *   `requestCombineRunes` (Initiates VRF request)
    *   `fulfillRandomness` (VRF callback, executes forging logic)
    *   `setForgingCatalystData`
    *   `getForgingParameters`
    *   `getCombinedRunePreview` (Deterministic part)
16. **Administrative & System:**
    *   `grantRole`, `revokeRole` (from AccessControl)
    *   `pause`, `unpause` (from Pausable)
    *   `setPauseGuardian`
    *   `setRuneMetadataBaseURI`
    *   `setRandomnessProvider`
    *   `setRandomnessRequestFee`
    *   `collectContractFees`
    *   `batchTransferRunes` (Example batch op)
    *   `upgradeTo` (from UUPSUpgradeable)
17. **Internal Helper Functions:** Logic for yield calculation, randomness outcome interpretation, etc.

---

**Function Summary (Approx. 30+ functions including inherited/internal OZ):**

*   **`initializer(...)`**: Initializes the contract state and roles (proxy pattern).
*   **`pause()`**: Pauses transferable functions (Admin Role).
*   **`unpause()`**: Unpauses the contract (Pauser Role).
*   **`setPauseGuardian(address)`**: Sets the separate address for the Pauser role (Admin Role).
*   **`grantRole(bytes32, address)`**: Grants a specific role to an account (Admin Role).
*   **`revokeRole(bytes32, address)`**: Revokes a specific role from an account (Admin Role).
*   **`hasRole(bytes32, address)`**: Checks if an account has a role (View).
*   **`getRoleAdmin(bytes32)`**: Gets the admin role for a given role (View).
*   **`supportsInterface(bytes4)`**: Standard ERC165 interface support check (View).
*   **`name()`**: Returns the ERC721 name (View).
*   **`symbol()`**: Returns the ERC721 symbol (View).
*   **`balanceOf(address)`**: Returns the number of Runes owned by an address (View).
*   **`ownerOf(uint256)`**: Returns the owner of a specific Rune (View).
*   **`approve(address, uint256)`**: Approves an address to manage a Rune.
*   **`getApproved(uint256)`**: Gets the approved address for a Rune (View).
*   **`setApprovalForAll(address, bool)`**: Approves or revokes approval for an operator for all Runes.
*   **`isApprovedForAll(address, address)`**: Checks if an operator is approved for an owner (View).
*   **`transferFrom(address, address, uint256)`**: Transfers a Rune (Standard ERC721, *might be restricted when staked*).
*   **`safeTransferFrom(address, address, uint256)`**: Safe transfer of a Rune.
*   **`safeTransferFrom(address, address, uint256, bytes)`**: Safe transfer with data.
*   **`tokenURI(uint256)`**: Returns the dynamic metadata URI for a Rune (View).
*   **`setRuneMetadataBaseURI(string)`**: Sets the base URI for token metadata (Admin Role).
*   **`mintRune(address, uint8)`**: Mints a new Rune of a specific type to an address (Minter Role).
*   **`burnRune(uint256)`**: Burns a Rune owned by the caller.
*   **`chargeRune(uint256, uint256)`**: Uses Essence to increase a Rune's charge state (Owner).
*   **`decayRunes(uint256[])`**: Admin function to apply time-based decay to a list of Runes (Admin Role).
*   **`getRuneState(uint256)`**: Gets the current dynamic state (type, charge, last charged time) of a Rune (View).
*   **`requestCombineRunes(uint256[], uint256, bytes)`**: Initiates the crafting process for a set of Runes using Essence and Catalyst data, requests randomness (Forger Role/Specific User).
*   **`fulfillRandomness(uint256, uint256)`**: VRF callback function to process the randomness result and execute the forging outcome (VRF Coordinator only).
*   **`setForgingCatalystData(bytes32, bytes)`**: Sets parameters or 'Catalyst' data used in forging recipes (Admin Role).
*   **`getForgingParameters(bytes32)`**: Retrieves stored forging catalyst data (View).
*   **`getCombinedRunePreview(uint256[], bytes)`**: Provides a preview of the *deterministic* part of a forging outcome (View).
*   **`disenchantRune(uint256)`**: Burns a Rune and returns a calculated amount of Essence (Owner).
*   **`stakeRune(uint256)`**: Stakes an owned Rune in the contract to earn yield (Owner).
*   **`unstakeRune(uint256)`**: Unstakes a previously staked Rune (Owner).
*   **`claimEssenceYield()`**: Claims accumulated Essence yield from all of the caller's staked Runes.
*   **`getRuneStakeInfo(uint256)`**: Gets the staking status and yield information for a Rune (View).
*   **`setYieldParameters(uint256)`**: Sets the Essence yield rate per staked Rune per time period (Admin Role).
*   **`balanceOfEssence(address)`**: Returns the Essence balance of an address (View, internal ERC20).
*   **`transferEssence(address, uint256)`**: Transfers Essence from caller's balance (Internal ERC20).
*   **`approveEssence(address, uint256)`**: Approves spender for Essence (Internal ERC20).
*   **`transferFromEssence(address, address, uint256)`**: Transfers Essence on behalf of owner (Internal ERC20).
*   **`setRandomnessProvider(address, bytes32, uint256)`**: Sets the VRF Coordinator address, key hash, and subscription ID (Admin Role).
*   **`setRandomnessRequestFee(uint96)`**: Sets the fee required for VRF requests (Admin Role).
*   **`collectContractFees(address)`**: Admin function to withdraw accumulated Essence or Ether collected by the contract (Admin Role).
*   **`batchTransferRunes(address[], uint256[])`**: Example function to transfer multiple Runes in one transaction (Owner/Approved).
*   **`upgradeTo(address)`**: Initiates the contract upgrade to a new implementation address (Admin Role, UUPS).
*   **`_authorizeUpgrade(address)`**: Internal check for UUPS upgrade authorization (Admin Role).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License & Pragma
// 2. Imports: OpenZeppelin (ERC721, AccessControl, Pausable, Initializable, UUPSUpgradeable), Chainlink VRFConsumerBaseV2
// 3. Error Definitions
// 4. Contract Definition & Inheritances
// 5. Roles Definition (bytes32 constants)
// 6. State Variables: ERC721 state (implicit via OZ), Dynamic Rune State, Internal Essence (ERC20) State, Staking State, Crafting Parameters, Yield Parameters, VRF State, Admin/System State.
// 7. Events
// 8. Initializer Function
// 9. ERC-721 Implementation (including dynamic tokenURI)
// 10. Internal Essence (ERC-20) Implementation
// 11. Dynamic Rune Logic (Charge, Decay, Get State)
// 12. Staking Logic (Stake, Unstake, Claim, Get Info, Set Params)
// 13. Crafting/Forging Logic (Request Randomness, Fulfill Randomness, Set Params, Preview)
// 14. Administrative & System Functions (Roles, Pause, Set URIs, Set VRF, Collect Fees, Batch Transfer, Upgrade)
// 15. Internal Helper Functions (Yield calculation, Forging outcome logic)

// Function Summary:
// initializer(): Initialize contract, roles, and basic settings (Proxy setup).
// pause(): Pause key operations (Pauser Role).
// unpause(): Unpause key operations (Pauser Role).
// setPauseGuardian(address): Set address with Pauser role (Admin Role).
// grantRole(bytes32, address): Grant a role (Admin Role).
// revokeRole(bytes32, address): Revoke a role (Admin Role).
// hasRole(bytes32, address): Check role (View).
// getRoleAdmin(bytes32): Get admin role for a role (View).
// supportsInterface(bytes4): ERC165 interface check (View).
// name(): ERC721 name (View).
// symbol(): ERC721 symbol (View).
// balanceOf(address): ERC721 balance (View).
// ownerOf(uint256): ERC721 owner (View).
// approve(address, uint256): ERC721 approve.
// getApproved(uint256): ERC721 get approved (View).
// setApprovalForAll(address, bool): ERC721 set approval for all.
// isApprovedForAll(address, address): ERC721 is approved for all (View).
// transferFrom(address, address, uint256): ERC721 transfer (restricted if staked).
// safeTransferFrom(address, address, uint256): ERC721 safe transfer.
// safeTransferFrom(address, address, uint256, bytes): ERC721 safe transfer with data.
// tokenURI(uint256): Dynamic metadata URI for Rune (View).
// setRuneMetadataBaseURI(string): Set base URI (Admin Role).
// mintRune(address, uint8): Mint new Rune (Minter Role).
// burnRune(uint256): Burn a Rune (Owner).
// chargeRune(uint256, uint256): Increase Rune charge using Essence (Owner).
// decayRunes(uint256[]): Apply time-based decay to Runes (Admin Role, Batch).
// getRuneState(uint256): Get Rune dynamic state (View).
// requestCombineRunes(uint256[], uint256, bytes): Initiate forging, consume inputs, request randomness (Forger Role/User).
// fulfillRandomness(uint256, uint256): VRF callback, execute forging outcome (VRF Coordinator).
// setForgingCatalystData(bytes32, bytes): Set forging parameters/recipes (Admin Role).
// getForgingParameters(bytes32): Get forging parameters (View).
// getCombinedRunePreview(uint256[], bytes): Preview deterministic forge outcome (View).
// disenchantRune(uint256): Burn Rune, get Essence back (Owner).
// stakeRune(uint256): Stake Rune for yield (Owner).
// unstakeRune(uint256): Unstake Rune (Owner).
// claimEssenceYield(): Claim accumulated Essence yield (User).
// getRuneStakeInfo(uint256): Get Rune staking info (View).
// setYieldParameters(uint256): Set Essence yield rate (Admin Role).
// balanceOfEssence(address): Get Essence balance (View, Internal ERC20).
// transferEssence(address, uint256): Transfer Essence (Internal ERC20).
// approveEssence(address, uint256): Approve spender for Essence (Internal ERC20).
// transferFromEssence(address, address, uint256): Transfer Essence on behalf of owner (Internal ERC20).
// setRandomnessProvider(address, bytes32, uint256): Set VRF params (Admin Role).
// setRandomnessRequestFee(uint96): Set VRF fee (Admin Role).
// collectContractFees(address): Withdraw collected fees (Admin Role).
// batchTransferRunes(address[], uint256[]): Batch transfer example (Owner/Approved).
// upgradeTo(address): Upgrade contract implementation (Admin Role).
// _authorizeUpgrade(address): Internal UUPS authorization check.
// _calculateYield(uint256): Internal yield calculation helper.
// _generateForgingOutcome(uint256[]): Internal forging outcome logic based on randomness.

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol"; // Useful for listing staked tokens
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For ERC20 ops

contract AetheriumForge is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable, VRFConsumerBaseV2 {
    using Strings for uint256;
    using SafeMath for uint256; // For Essence token math

    // --- Errors ---
    error NotOwnerOrApproved();
    error NotEnoughEssence(uint256 required, uint256 has);
    error RuneNotChargeable(uint256 tokenId);
    error RuneAlreadyStaked(uint256 tokenId);
    error RuneNotStaked(uint256 tokenId);
    error NothingToClaim();
    error InvalidForgingInput(string reason);
    error VRFRequestFailed();
    error ForgingOutcomeNotReady();
    error BatchTransferMismatch();
    error EssenceTransferFailed();

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Separate role for pausing
    bytes32 public constant FORGER_ROLE = keccak256("FORGER_ROLE"); // Role allowed to initiate forging

    // --- State Variables: ERC721 Runes (Extended) ---
    struct RuneState {
        uint8 runeType; // Defines base properties (e.g., Fire, Water, Earth, Air - or specific IDs)
        uint256 charge; // Dynamic property, consumed by actions, gained by charging/staking
        uint64 lastInteractionTime; // Timestamp of last charge/decay/stake/unstake
    }
    mapping(uint256 => RuneState) private _runeStates;
    string private _baseTokenURI;
    uint256 private _nextTokenId;

    // --- State Variables: Internal Essence (ERC-20) ---
    string private _essenceName;
    string private _essenceSymbol;
    uint256 private _totalSupplyEssence;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // --- State Variables: Staking ---
    mapping(uint256 => bool) private _stakedRunes; // tokenId => isStaked
    mapping(uint256 => uint64) private _stakeStartTime; // tokenId => timestamp
    uint256 public essenceYieldRate; // Essence per second per staked Rune (example rate)
    mapping(address => uint256) private _userAccumulatedYield; // User's total yield from all their staked tokens
    mapping(uint256 => uint256) private _runeAccumulatedYield; // Yield accumulated by a specific rune since last claim/interaction

    // --- State Variables: Crafting/Forging ---
    // This is a placeholder. Real logic would involve complex mappings
    // defining recipes, input requirements (types, charge), output probabilities, etc.
    mapping(bytes32 => bytes) public forgingCatalystData; // Generic storage for crafting parameters/recipes
    mapping(uint256 => bytes32) private _pendingForges; // VRF request ID => unique forge ID/params
    struct ForgeRequest {
        address user;
        uint256[] inputTokenIds;
        bytes catalystData;
        uint256 essenceCost;
    }
    mapping(bytes32 => ForgeRequest) private _forgeRequests; // unique forge ID => request details
    mapping(bytes32 => uint256) private _forgeRandomWords; // unique forge ID => random result

    // --- State Variables: Randomness (VRF) ---
    address private _vrfCoordinator;
    bytes32 private _keyHash;
    uint690 private _subscriptionId; // Use uint64, as per chainlink docs
    uint96 private _randomnessRequestFee; // Fee to request randomness

    // --- State Variables: Admin/System ---
    address public feeRecipient; // Address to receive collected fees (Essence/Ether)

    // --- Events ---
    event RuneMinted(address indexed to, uint256 indexed tokenId, uint8 runeType);
    event RuneBurned(uint256 indexed tokenId);
    event RuneCharged(uint256 indexed tokenId, uint256 amount);
    event RunesDecayed(uint256[] indexed tokenIds, uint256 amountPer);
    event RuneStateUpdated(uint256 indexed tokenId, uint8 newType, uint256 newCharge, uint64 timestamp);
    event ForgingRequested(address indexed user, bytes32 indexed forgeId, uint256[] inputTokenIds, uint256 essenceCost);
    event ForgingOutcome(address indexed user, bytes32 indexed forgeId, uint256 randomWord, uint256[] consumedTokenIds, uint256[] createdTokenIds, uint8 createdRuneType); // Created could be empty if failure
    event RuneDisenchanted(uint256 indexed tokenId, uint256 essenceReturned);
    event RuneStaked(address indexed owner, uint256 indexed tokenId, uint64 stakeTime);
    event RuneUnstaked(address indexed owner, uint256 indexed tokenId, uint64 unstakeTime, uint256 claimedYield);
    event EssenceClaimed(address indexed owner, uint256 amount);
    event YieldParametersUpdated(uint256 newRate);
    event ForgingCatalystDataUpdated(bytes32 indexed key, bytes data);
    event RandomnessProviderUpdated(address indexed coordinator, bytes32 keyHash, uint64 subscriptionId);
    event RandomnessRequestFeeUpdated(uint96 fee);
    event FeesCollected(address indexed recipient, uint256 essenceAmount, uint256 ethAmount);
    event BatchTransfer(address indexed from, address indexed to, uint256[] indexed tokenIds);

    /// @custom:oz-initializer
    function initialize(
        string memory name,
        string memory symbol,
        string memory essenceName_,
        string memory essenceSymbol_,
        address defaultAdmin,
        address pauser,
        address minter,
        address forger,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint96 randomnessRequestFee_,
        uint256 initialYieldRate,
        address feeRecipient_
    ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init(); // Initialize enumerable extension
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        VRFConsumerBaseV2(vrfCoordinator).__VRFConsumerBaseV2_init(vrfCoordinator);

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(FORGER_ROLE, forger);

        _essenceName = essenceName_;
        _essenceSymbol = essenceSymbol_;
        _totalSupplyEssence = 0; // Essence is minted later

        _baseTokenURI = ""; // Should be set by admin later
        _nextTokenId = 1;

        _vrfCoordinator = vrfCoordinator;
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
        _randomnessRequestFee = randomnessRequestFee_;

        essenceYieldRate = initialYieldRate;
        feeRecipient = feeRecipient_;
    }

    // --- ERC-721 Overrides ---

    // Need to override _update, _increaseBalance, _beforeTokenTransfer to handle enumerable and staking state
    // OpenZeppelin upgradeable contracts require manual hooks
    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if staked
        if (_stakedRunes[tokenId]) {
            revert RuneAlreadyStaked(tokenId); // Or a more specific error like TransferNotAllowedWhileStaked
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if token exists (handled by ERC721 internal logic)
        // require(_exists(tokenId), "ERC721: token query for nonexistent token"); // Not needed, OZ handles

        RuneState storage state = _runeStates[tokenId];
        if (state.runeType == 0 && state.charge == 0 && state.lastInteractionTime == 0) {
             // This might happen if token exists but state wasn't set (e.g., error during mint).
             // Or, if runeType 0 is a valid "empty" type. Adjust logic if needed.
             // For now, assume type 0 means uninitialized or invalid.
             return ""; // Or a default error URI
        }

        // Construct dynamic metadata URL
        // Example: ipfs://[base_cid]/[token_id]_[type]_[charge]_[staked].json
        // The metadata server at base_cid would serve JSON based on these parameters.
        string memory stakedStatus = _stakedRunes[tokenId] ? "staked" : "notstaked";
        string memory dynamicPart = string(abi.encodePacked(
            tokenId.toString(),
            "_", state.runeType.toString(),
            "_", state.charge.toString(),
            "_", stakedStatus,
            ".json" // Or .json, or no extension depending on server
        ));

        return string(abi.encodePacked(_baseTokenURI, dynamicPart));
    }

    // --- Internal Essence (ERC-20 Basic Implementation) ---

    function essenceName() public view returns (string memory) { return _essenceName; }
    function essenceSymbol() public view returns (string memory) { return _essenceSymbol; }
    function totalSupplyEssence() public view returns (uint256) { return _totalSupplyEssence; }
    function balanceOfEssence(address account) public view returns (uint256) { return _essenceBalances[account]; }
    function allowanceEssence(address owner, address spender) public view returns (uint256) { return _essenceAllowances[owner][spender]; }

    // Basic transfer function (internal to the contract)
    function transferEssence(address to, uint256 amount) public virtual whenNotPaused returns (bool) {
        address owner = _msgSender();
        _transferEssence(owner, to, amount);
        // Events implicitly handled by _transferEssence internal
        return true;
    }

    // Basic approve function
    function approveEssence(address spender, uint256 amount) public virtual whenNotPaused returns (bool) {
        address owner = _msgSender();
        _approveEssence(owner, spender, amount);
        // Events implicitly handled by _approveEssence internal
        return true;
    }

    // Basic transferFrom function
    function transferFromEssence(address from, address to, uint256 amount) public virtual whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowanceEssence(from, spender, amount);
        _transferEssence(from, to, amount);
        // Events implicitly handled by internal functions
        return true;
    }

    // Internal Essence minting (controlled by MINTER_ROLE)
    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        // Potentially add a minting limit or cap here
        _totalSupplyEssence = _totalSupplyEssence.add(amount);
        _essenceBalances[account] = _essenceBalances[account].add(amount);
        // emit Transfer(address(0), account, amount); // ERC20 standard event
    }

    // Internal Essence burning
    function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _essenceBalances[account] = _essenceBalances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupplyEssence = _totalSupplyEssence.sub(amount);
        // emit Transfer(account, address(0), amount); // ERC20 standard event
    }

    // Internal Essence transfer logic
    function _transferEssence(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _essenceBalances[from] = _essenceBalances[from].sub(amount, "ERC20: transfer amount exceeds balance");
        _essenceBalances[to] = _essenceBalances[to].add(amount);
        // emit Transfer(from, to, amount); // ERC20 standard event
    }

    // Internal Essence approval logic
    function _approveEssence(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _essenceAllowances[owner][spender] = amount;
        // emit Approval(owner, spender, amount); // ERC20 standard event
    }

    // Internal Essence allowance spending logic
    function _spendAllowanceEssence(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _essenceAllowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approveEssence(owner, spender, currentAllowance - amount);
            }
        }
    }


    // --- Dynamic Rune Functionality ---

    function setRuneMetadataBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function mintRune(address to, uint8 runeType) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);

        _runeStates[tokenId] = RuneState({
            runeType: runeType,
            charge: 0, // Newly minted runes start with 0 charge
            lastInteractionTime: uint64(block.timestamp)
        });

        emit RuneMinted(to, tokenId, runeType);
        emit RuneStateUpdated(tokenId, runeType, 0, uint64(block.timestamp));
        return tokenId;
    }

    function burnRune(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), "AetheriumForge: caller is not owner nor approved");
        require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId)); // Cannot burn staked runes

        _burn(tokenId);
        delete _runeStates[tokenId]; // Remove dynamic state
        // Note: ERC721Enumerable handles removing from owner's list

        emit RuneBurned(tokenId);
    }

    function chargeRune(uint256 tokenId, uint256 amountEssence) public whenNotPaused {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), "AetheriumForge: caller is not owner nor approved");
        require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId)); // Cannot charge staked runes directly
        require(_essenceBalances[_msgSender()] >= amountEssence, NotEnoughEssence(amountEssence, _essenceBalances[_msgSender()]));

        // Decay before charging
        _applyDecay(tokenId);

        _burnEssence(_msgSender(), amountEssence); // User pays Essence

        RuneState storage state = _runeStates[tokenId];
        state.charge = state.charge.add(amountEssence); // Charge increases by Essence amount (example)
        state.lastInteractionTime = uint64(block.timestamp);

        emit RuneCharged(tokenId, amountEssence);
        emit RuneStateUpdated(tokenId, state.runeType, state.charge, state.lastInteractionTime);
    }

    // Admin/privileged function to apply decay to multiple runes
    // In a real game, this might be triggered off-chain periodically or by users paying gas
    function decayRunes(uint256[] calldata tokenIds) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        uint256 decayAmountPerRune = 10; // Example decay amount per time unit (e.g., 10 charge per day)
        uint256 decayTimeUnit = 1 days; // Example time unit

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Only decay if the token exists and is not staked
            if (_exists(tokenId) && !_stakedRunes[tokenId]) {
                 _applyDecay(tokenId); // Apply decay to this rune
            }
        }
        emit RunesDecayed(tokenIds, decayAmountPerRune); // Emitting average/parameter decay
    }

    // Internal helper to apply decay to a single rune
    function _applyDecay(uint256 tokenId) internal {
         RuneState storage state = _runeStates[tokenId];
         uint64 timeElapsed = uint64(block.timestamp) - state.lastInteractionTime;
         uint256 decayAmount = (timeElapsed * essenceYieldRate) / 10000; // Example decay proportional to time elapsed/yield rate

         if (state.charge > decayAmount) {
             state.charge -= decayAmount;
         } else {
             state.charge = 0;
         }
         state.lastInteractionTime = uint64(block.timestamp);
         emit RuneStateUpdated(tokenId, state.runeType, state.charge, state.lastInteractionTime);
    }


    function getRuneState(uint256 tokenId) public view returns (uint8 runeType, uint256 charge, uint64 lastInteractionTime) {
        require(_exists(tokenId), "AetheriumForge: token does not exist");
        RuneState storage state = _runeStates[tokenId];
        return (state.runeType, state.charge, state.lastInteractionTime);
    }

    // --- Staking Functionality ---

    function stakeRune(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), "AetheriumForge: caller is not owner nor approved");
        require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId));

        // Calculate and add any pending yield from this specific rune before staking it
        _calculateAndAddRuneYield(tokenId, owner);

        // Transfer the Rune to the contract
        _transfer(owner, address(this), tokenId);

        _stakedRunes[tokenId] = true;
        _stakeStartTime[tokenId] = uint64(block.timestamp);
        _runeAccumulatedYield[tokenId] = 0; // Reset rune-specific yield counter
        _runeStates[tokenId].lastInteractionTime = uint64(block.timestamp); // Update last interaction

        emit RuneStaked(owner, tokenId, uint64(block.timestamp));
    }

    function unstakeRune(uint256 tokenId) public whenNotPaused {
        // Owner check is implicit because only owner of staked rune can unstake it
        // The owner of a staked rune *is* the contract address technically, but we track the original staker.
        // A mapping like `_staker[tokenId] => address` would be better if multiple stakers existed.
        // For this example, we'll assume `_msgSender()` must be the one who called `stakeRune`.
        // A more robust solution would track staker address.
        require(_stakedRunes[tokenId], RuneNotStaked(tokenId));
        address staker = ERC721Upgradeable.ownerOf(tokenId); // This will be THIS contract address. We need to know the original staker.
        // Let's add a staker mapping for robustness.
        mapping(uint256 => address) private _staker; // tokenId => original staker

        // Add this to stakeRune:
        // _staker[tokenId] = owner; // Set staker when staking

        // Add this to unstakeRune:
        require(_staker[tokenId] == _msgSender(), "AetheriumForge: caller is not the staker");

        // Calculate and add pending yield before unstaking
        _calculateAndAddRuneYield(tokenId, _msgSender());

        _stakedRunes[tokenId] = false;
        delete _stakeStartTime[tokenId];
        delete _staker[tokenId]; // Clean up staker mapping
        uint256 claimedYield = _runeAccumulatedYield[tokenId];
        delete _runeAccumulatedYield[tokenId]; // Clean up rune yield counter
        _runeStates[tokenId].lastInteractionTime = uint64(block.timestamp); // Update last interaction

        // Transfer Rune back to the original staker
        _transfer(address(this), _msgSender(), tokenId);


        emit RuneUnstaked(_msgSender(), tokenId, uint64(block.timestamp), claimedYield);
    }


    function claimEssenceYield() public whenNotPaused {
        uint256 totalYield = _userAccumulatedYield[_msgSender()];
        require(totalYield > 0, NothingToClaim());

        // Iterate through all staked runes owned by the user and calculate pending yield
        // This approach is gas-intensive if a user has many staked runes.
        // A better approach is to calculate yield on stake/unstake/claim *per token*
        // and store/add to a user's total. Let's refactor the yield calculation/claiming.

        // REFACTORED YIELD LOGIC:
        // 1. When staking: Record start time, reset token yield.
        // 2. When unstaking: Calculate yield for this token since stake time (or last interaction), add to user's total, reset token yield.
        // 3. When claiming: Iterate user's *staked* tokens, calculate yield since last interaction, add to user's total, update last interaction time for token. Then transfer user's total.

        // Let's implement the REFACTORED logic. Need a way to list user's staked tokens.
        // ERC721Enumerable can help list *all* tokens, but filtering by owner (this contract)
        // and then checking `_stakedRunes` is still needed.
        // A mapping `address => uint256[]` of staked token IDs per user would be more efficient for claiming.
        // For simplicity in this example, let's update the existing `claimEssenceYield` to calculate yield
        // for the user's *currently staked* tokens and add it to their total before transferring.

        address user = _msgSender();
        uint256 pendingYield = 0;
        uint256[] memory userStakedTokenIds = new uint256[](balanceOf(address(this))); // Array size is max possible

        uint256 stakedCount = 0;
        // This loop iterates *all* tokens in the contract. INEFFICIENT for many tokens.
        // ERC721Enumerable's `tokenOfOwnerByIndex` is for *owned* tokens, which here means owned by the contract.
        // We need to iterate tokens the *user* staked. Need the mapping `_staker[tokenId]`.
        uint256 totalStakedRunes = balanceOf(address(this)); // Total runes held by the contract
        for (uint i = 0; i < totalStakedRunes; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(address(this), i);
             if (_stakedRunes[tokenId] && _staker[tokenId] == user) { // Check if staked AND belongs to this user
                 userStakedTokenIds[stakedCount] = tokenId;
                 stakedCount++;

                 // Calculate yield for this specific rune since last interaction
                 uint64 last = _runeStates[tokenId].lastInteractionTime;
                 uint64 timeElapsed = uint64(block.timestamp) - last;
                 uint256 yieldFromThisRune = (timeElapsed * essenceYieldRate); // Calculate based on time

                 _runeAccumulatedYield[tokenId] = _runeAccumulatedYield[tokenId].add(yieldFromThisRune); // Add to rune's accumulated yield
                 _runeStates[tokenId].lastInteractionTime = uint64(block.timestamp); // Update last interaction time for yield calculation
             }
        }

        // Sum up all the yield accumulated per rune for this user
        for(uint i = 0; i < stakedCount; i++){
            uint256 tokenId = userStakedTokenIds[i];
            pendingYield = pendingYield.add(_runeAccumulatedYield[tokenId]);
            _runeAccumulatedYield[tokenId] = 0; // Reset rune's yield after adding to user's total
        }

        totalYield = _userAccumulatedYield[user].add(pendingYield); // Add newly calculated yield to user's total

        require(totalYield > 0, NothingToClaim());

        _userAccumulatedYield[user] = 0; // Reset user's claimable balance
        _mintEssence(user, totalYield); // Mint and transfer Essence

        emit EssenceClaimed(user, totalYield);
    }

    // Internal helper to calculate and add yield for a *single* rune to the user's total
    function _calculateAndAddRuneYield(uint256 tokenId, address user) internal {
         require(_stakedRunes[tokenId], RuneNotStaked(tokenId));
         require(_staker[tokenId] == user, "AetheriumForge: not the staker");

         uint64 last = _runeStates[tokenId].lastInteractionTime;
         uint64 timeElapsed = uint64(block.timestamp) - last;
         uint256 yieldFromThisRune = (timeElapsed * essenceYieldRate);

         _runeAccumulatedYield[tokenId] = _runeAccumulatedYield[tokenId].add(yieldFromThisRune);
         _userAccumulatedYield[user] = _userAccumulatedYield[user].add(_runeAccumulatedYield[tokenId]); // Add to user's total
         _runeAccumulatedYield[tokenId] = 0; // Reset rune's yield counter after adding to user total
         _runeStates[tokenId].lastInteractionTime = uint64(block.timestamp); // Update last interaction
    }


    function getRuneStakeInfo(uint256 tokenId) public view returns (bool isStaked, uint64 stakeTime, uint256 accumulatedYield, address staker) {
        // Requires _staker mapping to be implemented for 'staker' return value
        require(_exists(tokenId), "AetheriumForge: token does not exist");
        return (_stakedRunes[tokenId], _stakeStartTime[tokenId], _runeAccumulatedYield[tokenId], _staker[tokenId]); // Include _runeAccumulatedYield
    }

    function setYieldParameters(uint256 newRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        essenceYieldRate = newRate;
        emit YieldParametersUpdated(newRate);
    }


    // --- Crafting/Forging Functionality ---

    // Requires Chainlink VRF V2 setup (Coordinator, Subscription, Funding)
    function setRandomnessProvider(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _vrfCoordinator = vrfCoordinator;
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
        // Need to update the VRFConsumerBaseV2 state as well if changing provider mid-contract life.
        // VRFConsumerBaseV2 doesn't expose a public setter. Re-initializing might be an option in upgrade or careful state management.
        // For this example, assume set once during initialize or before use.
        emit RandomnessProviderUpdated(vrfCoordinator, keyHash, subscriptionId);
    }

    function setRandomnessRequestFee(uint96 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _randomnessRequestFee = fee;
        emit RandomnessRequestFeeUpdated(fee);
    }

    function requestCombineRunes(uint256[] calldata inputTokenIds, uint256 essenceCost, bytes calldata catalystData) public whenNotPaused onlyRole(FORGER_ROLE) {
        require(inputTokenIds.length > 0, InvalidForgingInput("no input tokens"));
        require(inputTokenIds.length <= 5, InvalidForgingInput("too many input tokens")); // Example limit

        address user = _msgSender();
        require(_essenceBalances[user] >= essenceCost, NotEnoughEssence(essenceCost, _essenceBalances[user]));

        bytes32 forgeId = keccak256(abi.encodePacked(user, block.timestamp, inputTokenIds, catalystData, block.number)); // Unique ID for this forge request

        // Validate inputs and transfer runes to the contract (or burn them immediately?)
        // Transfer to contract is safer until randomness result is known.
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            address currentOwner = ownerOf(tokenId);
            require(currentOwner == user || isApprovedForAll(currentOwner, user), "AetheriumForge: caller is not owner or approved for input rune");
            require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId)); // Cannot use staked runes

            // Transfer Rune to the contract temporarily
            _transfer(currentOwner, address(this), tokenId);

            // Decay and record last interaction before forging
            _applyDecay(tokenId);
            _runeStates[tokenId].lastInteractionTime = uint64(block.timestamp);
        }

        // Pay Essence cost
        _burnEssence(user, essenceCost);

        // Store request details
        _forgeRequests[forgeId] = ForgeRequest({
            user: user,
            inputTokenIds: inputTokenIds,
            catalystData: catalystData,
            essenceCost: essenceCost
        });

        // Request randomness from VRF Coordinator
        uint256 requestId = requestRandomness(_keyHash, _subscriptionId, _randomnessRequestFee, 1); // Request 1 random word
        _pendingForges[requestId] = forgeId; // Link VRF request ID to forge request ID

        emit ForgingRequested(user, forgeId, inputTokenIds, essenceCost);
    }

    // Chainlink VRF callback function
    function fulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override {
        bytes32 forgeId = _pendingForges[requestId];
        require(forgeId != bytes32(0), "AetheriumForge: Unknown VRF request ID");
        delete _pendingForges[requestId]; // Clean up pending request mapping

        ForgeRequest storage forgeReq = _forgeRequests[forgeId];
        require(forgeReq.user != address(0), "AetheriumForge: Forge request not found");

        _forgeRandomWords[forgeId] = randomWords[0]; // Store the random word

        // --- EXECUTE FORGING OUTCOME ---
        // This is where the core crafting logic happens, using the random word.
        // Based on inputRunes (types, charge), catalystData, and randomWord,
        // determine the outcome:
        // - Success/Failure?
        // - What Rune type is created?
        // - How much charge does it have?
        // - Do input runes get burned or modified? (Burned is typical for crafting)

        uint8 newRuneType = 0; // Placeholder outcome
        uint256 newCharge = 0; // Placeholder outcome
        uint256[] memory consumedTokenIds = forgeReq.inputTokenIds;
        uint256[] memory createdTokenIds = new uint256[](0); // Array for created tokens

        // Example very simple deterministic outcome based on random word:
        uint256 randomResult = randomWords[0];
        bool success = randomResult % 100 < 80; // 80% chance of success

        if (success) {
            // Burn the input runes
             for (uint i = 0; i < consumedTokenIds.length; i++) {
                 uint256 tokenId = consumedTokenIds[i];
                 // Ensure the contract still owns it (should be from requestCombineRunes)
                 require(ownerOf(tokenId) == address(this), "AetheriumForge: contract does not own input rune for forging");
                 _burn(tokenId); // Burn the input rune
                 delete _runeStates[tokenId]; // Delete dynamic state
             }

            // Determine output rune type based on random word and inputs/catalyst
            // This logic would be complex in a real implementation, reading `forgingCatalystData`
            // For example, combine types of inputs + randomness to pick output type.
            newRuneType = uint8((randomResult / 100) % 5) + 1; // Example: new type 1-5
            newCharge = (randomResult % 500) + 100; // Example: random charge 100-600

            // Mint the new rune
            uint256 newTokenId = _nextTokenId++;
            _mint(forgeReq.user, newTokenId); // Mint directly to the user

            _runeStates[newTokenId] = RuneState({
                runeType: newRuneType,
                charge: newCharge,
                lastInteractionTime: uint64(block.timestamp)
            });
             createdTokenIds = new uint256[](1);
             createdTokenIds[0] = newTokenId;

            emit RuneMinted(forgeReq.user, newTokenId, newRuneType);
             emit RuneStateUpdated(newTokenId, newRuneType, newCharge, uint64(block.timestamp));

        } else {
            // Failure: Input runes are lost (burned)
            for (uint i = 0; i < consumedTokenIds.length; i++) {
                 uint256 tokenId = consumedTokenIds[i];
                 require(ownerOf(tokenId) == address(this), "AetheriumForge: contract does not own input rune for failed forging");
                 _burn(tokenId); // Burn the input rune
                 delete _runeStates[tokenId]; // Delete dynamic state
             }
            // Maybe refund some essence on failure? Or give a different item?
            // For now, failure means inputs are lost.
        }

        delete _forgeRequests[forgeId]; // Clean up request after processing

        emit ForgingOutcome(forgeReq.user, forgeId, randomWords[0], consumedTokenIds, createdTokenIds, newRuneType);
    }

    function setForgingCatalystData(bytes32 key, bytes memory data) public onlyRole(DEFAULT_ADMIN_ROLE) {
        forgingCatalystData[key] = data;
        emit ForgingCatalystDataUpdated(key, data);
    }

    function getForgingParameters(bytes32 key) public view returns (bytes memory) {
        return forgingCatalystData[key];
    }

     // Helper for users to see the deterministic part of a forge outcome
     // (Doesn't include randomness effects like success chance or random charge/type)
     // The actual outcome logic needs to be duplicated here deterministic part
    function getCombinedRunePreview(uint256[] calldata inputTokenIds, bytes calldata catalystData) public view returns (uint8 potentialOutputRuneType) {
         // This function would contain the deterministic part of the forging logic
         // based on input runes and catalyst data, but without the randomness.
         // E.g., combining Fire + Water runes *always* yields a Steam rune type *if* successful.
         // Success chance, charge, etc. would be based on randomness.

         // Example placeholder logic: output type is sum of input types % max type + 1
         uint8 sumTypes = 0;
         for (uint i = 0; i < inputTokenIds.length; i++) {
              if (_exists(inputTokenIds[i])) { // Only consider existing runes
                 sumTypes += _runeStates[inputTokenIds[i]].runeType;
              }
         }
         // Add some logic based on catalystData
         // For this example, return a dummy value based on sum
         if (sumTypes == 0) return 0; // Indicate no valid inputs
         return uint8((sumTypes % 5) + 1); // Example: returns a type between 1 and 5

    }


    function disenchantRune(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), "AetheriumForge: caller is not owner nor approved");
        require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId)); // Cannot disenchant staked runes

        RuneState storage state = _runeStates[tokenId];
        // Example disenchant logic: return Essence based on rune type and current charge
        uint256 essenceReturn = (state.charge / 2) + (state.runeType * 10); // Example calculation

        _burn(tokenId); // Burn the rune
        delete _runeStates[tokenId]; // Remove dynamic state

        if (essenceReturn > 0) {
            _mintEssence(_msgSender(), essenceReturn); // Mint and transfer Essence
        }

        emit RuneDisenchanted(tokenId, essenceReturn);
    }


    // --- Administrative & System ---

    // AccessControl functions are inherited

    // Pausable functions are inherited (`pause()`, `unpause()`)
    // Override _authorizeUpgrade for UUPS
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function setPauseGuardian(address guardian) public onlyRole(DEFAULT_ADMIN_ROLE) {
         // Remove role from existing guardian if applicable
         bytes32 pauserRole = PAUSER_ROLE; // Avoid stack too deep
         address currentGuardian = getRoleMember(pauserRole, 0); // Only supports getting first member easily
         // Need a way to check if an address currently has the role without iterating
         if (hasRole(pauserRole, currentGuardian)) {
             revokeRole(pauserRole, currentGuardian);
         }
        grantRole(PAUSER_ROLE, guardian);
    }


    function collectContractFees(address payable recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 essenceBalance = _essenceBalances[address(this)];
        if (essenceBalance > 0) {
            _transferEssence(address(this), recipient, essenceBalance);
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
             (bool success, ) = recipient.call{value: ethBalance}("");
             if (!success) {
                 // Handle failure: log, or send back to admin, or leave in contract
                 // For this example, let's revert or just log (revert safer)
                 revert("AetheriumForge: ETH transfer failed");
             }
        }

        emit FeesCollected(recipient, essenceBalance, ethBalance);
    }

    // Example Batch Operation
    function batchTransferRunes(address[] calldata recipients, uint256[] calldata tokenIds) public whenNotPaused {
        require(recipients.length == tokenIds.length, BatchTransferMismatch());

        address sender = _msgSender(); // Assuming caller is owner or approved operator

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address recipient = recipients[i];
            address currentOwner = ownerOf(tokenId);

            // Check permissions for each transfer
            require(currentOwner == sender || isApprovedForAll(currentOwner, sender), "AetheriumForge: caller is not owner or approved for batch transfer");
            require(!_stakedRunes[tokenId], RuneAlreadyStaked(tokenId)); // Cannot batch transfer staked runes

            // Execute the transfer
            _transfer(currentOwner, recipient, tokenId); // Using internal _transfer which handles permissions and checks
        }
        emit BatchTransfer(sender, address(0), tokenIds); // Emit a single event for the batch
    }


    // --- Internal Helper Functions ---

    // Renamed _calculateYield to _calculateAndAddRuneYield and moved logic
    // Keeping this section header for clarity but referring to the updated logic above.

    // Forging outcome generation based on randomness - internal to fulfillRandomness

    // Receive ETH (if needed, e.g., for fees or future features)
    receive() external payable {}
    fallback() external payable {}
}
```