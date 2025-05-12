Okay, here is a Solidity smart contract combining several interesting, advanced, creative, and trendy concepts, including:

1.  **Dynamic NFTs (ChronoGlyphs):** NFTs whose properties (like 'Charge') change over time and based on owner interaction (charging).
2.  **On-Chain Reputation System:** Users earn a reputation score based on their actions within the contract.
3.  **Internal Utility Token ($REPUTE):** A token minted based on user activity and reputation, used for charging NFTs and potentially staking. (Simulated ERC-20 logic).
4.  **Staking with Boosts:** Staking the utility token provides a temporary boost to reputation gain.
5.  **Reputation-Based Delegation:** Users can delegate their *reputation's influence* (not voting power directly, but a score used in calculations) to another address.
6.  **Parameterized Mechanics:** Key aspects of the system (minting thresholds, earning rates, decay rates) are parameters that could eventually be governed.
7.  **Achievement/Action System:** A simplified way for users to trigger reputation/token gain.
8.  **Standard Compliance (Simulated):** Implementing core logic resembling ERC-721 and ERC-20 interfaces without inheriting full standard libraries directly, offering a unique implementation.
9.  **Time-Based Mechanics:** Decay and accrual logic relies on `block.timestamp`.
10. **Pausing Mechanism:** Standard safety feature, but integrated into the custom logic.

This contract is designed to be complex and illustrative, demonstrating the combination of these ideas. It's *not* audited or production-ready, and security considerations for a real-world deployment would require significant further work.

---

**Outline and Function Summary**

**Contract Name:** `ChronoGlyphsAndReputationEngine`

**Core Concepts:**
*   Dynamic NFTs (ChronoGlyphs)
*   On-chain User Reputation
*   Internal Utility Token ($REPUTE)
*   Staking with Boosts
*   Reputation Delegation
*   Parameterized Game Mechanics

**State Variables:**
*   `owner`: Contract deployer, controls parameters and pausing.
*   `reputeTokenName`/`reputeTokenSymbol`: Metadata for the internal token.
*   `chronoGlyphName`/`chronoGlyphSymbol`: Metadata for the NFTs.
*   `_reputeTotalSupply`: Total $REPUTE minted.
*   `_reputeBalances`: User $REPUTE balances.
*   `_userReputation`: User reputation scores.
*   `_lastActionTime`: Timestamp of user's last action (for rate limiting/accrual).
*   `_reputeStakes`: User staked $REPUTE.
*   `_reputationDelegates`: Maps delegator to delegatee.
*   `_delegationTimestamps`: Tracks when delegation occurred.
*   `_allGlyphs`: List of all ChronoGlyph token IDs.
*   `_glyphData`: Maps Glyph ID to its metadata (`Glyph` struct).
*   `_glyphOwners`: Maps Glyph ID to its owner.
*   `_glyphApprovals`: Maps Glyph ID to approved address (ERC721).
*   `_operatorApprovals`: Maps owner => operator => approved (ERC721).
*   `_ownerGlyphCount`: Maps owner to number of owned Glyphs.
*   `paused`: Boolean flag for pausing functionality.
*   `_reputeEarnRate`: Parameter controlling $REPUTE earning.
*   `_reputationActionGain`: Parameter controlling reputation gain per action.
*   `_glyphMintThreshold`: Reputation required to mint a Glyph.
*   `_glyphDecayRate`: Parameter controlling Glyph charge decay.
*   `_glyphChargeCost`: $REPUTE cost to charge a Glyph.
*   `_reputationBoostFactor`: Parameter for staking boost.
*   `_delegationBoostFactor`: Parameter for delegation boost (potential use).
*   `_nextTokenId`: Counter for unique Glyph IDs.

**Structs:**
*   `Glyph`: Represents a ChronoGlyph with `creationTime`, `lastChargedTime`, `totalChargeApplied`.
*   `UserInfo`: Represents user data with `reputation`, `lastActionTime`, `stakedRepute`, `delegatee`. (Mapping is used instead of a struct for UserInfo for direct access).

**Events:**
*   `ReputeMinted`: When $REPUTE is issued.
*   `ReputeTransferred`: When $REPUTE is transferred (internal sim).
*   `ReputeBurned`: When $REPUTE is burned.
*   `ReputationUpdated`: When user reputation changes.
*   `ActionPerformed`: When a user performs an action.
*   `GlyphMinted`: When a new ChronoGlyph is minted.
*   `GlyphTransferred`: When a Glyph changes owner.
*   `GlyphCharged`: When a Glyph is charged.
*   `ReputeStaked`: When $REPUTE is staked.
*   `ReputeUnstaked`: When $REPUTE is unstaked.
*   `ReputationDelegated`: When reputation power is delegated.
*   `ReputationDelegationRevoked`: When delegation is revoked.
*   `ParameterChanged`: When a system parameter is updated.
*   `Paused`/`Unpaused`: When the system is paused/unpaused.
*   `Approval`/`ApprovalForAll`: ERC721 standard events.

**Custom Errors:**
*   `TransferFromIncorrectOwner`
*   `ApproveCallerIsNotOwnerNorApproved`
*   `TransferToNonERC721ReceiverImplementer`
*   `InvalidTokenId`
*   `InsufficientRepute`
*   `InsufficientReputation`
*   `CannotMintYet`
*   `CannotChargeYet`
*   `MustBeOwnerOrApproved`
*   `TransferRequiresReputation` (Example of custom transfer logic constraint)
*   `SystemPaused`
*   `NotOwner`
*   `CannotDelegateToSelf`
*   `NoActiveDelegation`
*   `InsufficientStake`

**Functions (>= 30):**

*   **Initialization & Views (Basic & ERC-like):**
    1.  `constructor()`: Sets owner and basic names/symbols.
    2.  `reputeTotalSupply() view`: Total $REPUTE in existence.
    3.  `getUserReputeBalance(address account) view`: Get user's $REPUTE balance.
    4.  `getUserReputation(address account) view`: Get user's reputation score.
    5.  `getReputeTokenName() view`: Get $REPUTE token name.
    6.  `getReputeTokenSymbol() view`: Get $REPUTE token symbol.
    7.  `getTotalGlyphs() view`: Get total number of Glyphs minted.
    8.  `getGlyphOwner(uint256 tokenId) view`: Get owner of a Glyph (ERC721 ownerOf).
    9.  `balanceOf(address owner) view`: Get number of Glyphs owned by an address (ERC721 balanceOf).
    10. `getGlyphCreationTime(uint256 tokenId) view`: Get the creation timestamp of a Glyph.
    11. `supportsInterface(bytes4 interfaceId) view`: ERC165 support check (for ERC721).
    12. `getApproved(uint256 tokenId) view`: Get approved address for a Glyph (ERC721).
    13. `isApprovedForAll(address owner, address operator) view`: Check if operator is approved for all Glyphs (ERC721).

*   **Core Mechanics (Reputation, Repute, Glyphs):**
    14. `performAction(uint256 actionType)`: User performs an action to gain reputation and accrue $REPUTE.
    15. `claimAccruedRepute()`: User claims accrued $REPUTE based on reputation and time since last claim/action.
    16. `mintGlyph()`: User attempts to mint a new Glyph if they meet the reputation threshold.
    17. `chargeGlyph(uint256 tokenId, uint256 amount)`: User spends $REPUTE to increase a Glyph's total charge.
    18. `calculateGlyphCurrentCharge(uint256 tokenId) view`: Calculates the *current* effective charge of a Glyph based on total charge, decay rate, and time. (Dynamic property).
    19. `transferRepute(address to, uint256 amount)`: Simulate internal $REPUTE transfer.
    20. `burnRepute(uint256 amount)`: User burns their own $REPUTE.

*   **Staking:**
    21. `stakeReputeForBoost(uint256 amount)`: User stakes $REPUTE to get a reputation gain boost.
    22. `unstakeRepute(uint256 amount)`: User unstakes $REPUTE.
    23. `getUserStakedRepute(address account) view`: Get user's staked $REPUTE.

*   **Delegation (Creative Governance Element):**
    24. `delegateReputationPower(address delegatee)`: User delegates their reputation influence.
    25. `revokeReputationDelegation()`: User revokes delegation.
    26. `getReputationDelegatee(address account) view`: Get who a user has delegated to.
    27. `getReputationDelegateeOrSelf(address account) view`: Get the delegatee, or the user's address if no delegation. (Useful for calculations).

*   **Glyph Management (ERC721-like):**
    28. `transferFrom(address from, address to, uint256 tokenId)`: Transfer Glyph (ERC721). Includes a potential custom reputation check.
    29. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe Transfer Glyph (ERC721).
    30. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe Transfer Glyph with data (ERC721).
    31. `approve(address to, uint256 tokenId)`: Approve address for a Glyph (ERC721).
    32. `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all Glyphs (ERC721).
    33. `setBaseURI(string memory baseURI_)`: Set base URI for token metadata.
    34. `tokenURI(uint256 tokenId) view`: Get token metadata URI (ERC721).

*   **Governance & Parameters (Owner Only for Simplicity):**
    35. `setParameter_ReputeEarnRate(uint256 rate)`: Owner sets $REPUTE earning rate.
    36. `setParameter_ReputationActionGain(uint256 gain)`: Owner sets reputation gain per action.
    37. `setParameter_GlyphMintThreshold(uint256 threshold)`: Owner sets Glyph minting reputation threshold.
    38. `setParameter_GlyphDecayRate(uint256 rate)`: Owner sets Glyph charge decay rate.
    39. `setParameter_GlyphChargeCost(uint256 cost)`: Owner sets Glyph charging cost.
    40. `setParameter_ReputationBoostFactor(uint256 factor)`: Owner sets staking boost factor.
    41. `getParameter_ReputeEarnRate() view`: View $REPUTE earn rate.
    42. `getParameter_GlyphMintThreshold() view`: View Glyph mint threshold.
    43. `getParameter_GlyphDecayRate() view`: View Glyph decay rate.

*   **System Control:**
    44. `emergencyPause()`: Owner pauses key functions.
    45. `emergencyUnpause()`: Owner unpauses key functions.
    46. `transferAnyERC20Token(address tokenAddress, address recipient, uint256 amount)`: Owner can recover accidentally sent ERC20s.

*(Note: Function count is 46, well over the requested 20.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using this only for type hinting owner rescue function

// Note: OpenZeppelin imports are for interfaces/safety helper (SafeERC20) and type hinting.
// The core logic for ERC-20/721/Reputation/Glyphs/Staking/Delegation is implemented within this contract
// and not directly inherited from OpenZeppelin's standard implementations, adhering to the 'do not duplicate'
// spirit by presenting a custom system build.

/**
 * @title ChronoGlyphsAndReputationEngine
 * @notice A creative smart contract combining dynamic NFTs, an on-chain reputation system,
 *         internal utility token ($REPUTE)omics, staking with boosts, and reputation delegation.
 *         Users perform actions to earn reputation and $REPUTE, mint dynamic NFTs (ChronoGlyphs)
 *         based on reputation thresholds, charge Glyphs with $REPUTE, stake $REPUTE for reputation boosts,
 *         and delegate their reputation influence.
 *         Key parameters are owner-controlled, simulating a pathway to future governance.
 *         Implements core logic mimicking ERC-721 and ERC-20 standards internally.
 *
 * Outline and Function Summary:
 *
 * Core Concepts: Dynamic NFTs (ChronoGlyphs), On-chain User Reputation, Internal Utility Token ($REPUTE),
 *                Staking with Boosts, Reputation Delegation, Parameterized Game Mechanics.
 *
 * State Variables: owner, reputeTokenName, reputeTokenSymbol, chronoGlyphName, chronoGlyphSymbol,
 *                  _reputeTotalSupply, _reputeBalances, _userReputation, _lastActionTime,
 *                  _reputeStakes, _reputationDelegates, _delegationTimestamps, _allGlyphs,
 *                  _glyphData, _glyphOwners, _glyphApprovals, _operatorApprovals, _ownerGlyphCount,
 *                  paused, _reputeEarnRate, _reputationActionGain, _glyphMintThreshold,
 *                  _glyphDecayRate, _glyphChargeCost, _reputationBoostFactor, _delegationBoostFactor,
 *                  _nextTokenId.
 *
 * Structs: Glyph { creationTime, lastChargedTime, totalChargeApplied }
 *
 * Events: ReputeMinted, ReputeTransferred, ReputeBurned, ReputationUpdated, ActionPerformed,
 *         GlyphMinted, GlyphTransferred, GlyphCharged, ReputeStaked, ReputeUnstaked,
 *         ReputationDelegated, ReputationDelegationRevoked, ParameterChanged, Paused, Unpaused,
 *         Approval (ERC721), ApprovalForAll (ERC721).
 *
 * Custom Errors: TransferFromIncorrectOwner, ApproveCallerIsNotOwnerNorApproved, TransferToNonERC721ReceiverImplementer,
 *                InvalidTokenId, InsufficientRepute, InsufficientReputation, CannotMintYet, CannotChargeYet,
 *                MustBeOwnerOrApproved, TransferRequiresReputation, SystemPaused, NotOwner, CannotDelegateToSelf,
 *                NoActiveDelegation, InsufficientStake.
 *
 * Functions (> 30):
 *    - Initialization & Views (Basic & ERC-like): constructor, reputeTotalSupply, getUserReputeBalance,
 *      getUserReputation, getReputeTokenName, getReputeTokenSymbol, getTotalGlyphs, getGlyphOwner,
 *      balanceOf, getGlyphCreationTime, supportsInterface, getApproved, isApprovedForAll.
 *    - Core Mechanics: performAction, claimAccruedRepute, mintGlyph, chargeGlyph, calculateGlyphCurrentCharge,
 *      transferRepute, burnRepute.
 *    - Staking: stakeReputeForBoost, unstakeRepute, getUserStakedRepute.
 *    - Delegation: delegateReputationPower, revokeReputationDelegation, getReputationDelegatee,
 *      getReputationDelegateeOrSelf.
 *    - Glyph Management (ERC721-like): transferFrom, safeTransferFrom, safeTransferFrom(with data),
 *      approve, setApprovalForAll, setBaseURI, tokenURI.
 *    - Governance & Parameters (Owner Only): setParameter_ReputeEarnRate, setParameter_ReputationActionGain,
 *      setParameter_GlyphMintThreshold, setParameter_GlyphDecayRate, setParameter_GlyphChargeCost,
 *      setParameter_ReputationBoostFactor, getParameter_ReputeEarnRate, getParameter_GlyphMintThreshold,
 *      getParameter_GlyphDecayRate.
 *    - System Control: emergencyPause, emergencyUnpause, transferAnyERC20Token.
 */
contract ChronoGlyphsAndReputationEngine is IERC721, IERC165 {
    // --- State Variables ---

    address public owner;

    // Repute Token State (Simulated ERC-20)
    string public reputeTokenName = "Repute";
    string public reputeTokenSymbol = "REPUTE";
    uint256 private _reputeTotalSupply;
    mapping(address => uint256) private _reputeBalances;
    // Note: Approvals/allowances are not implemented for the internal REPUTE token
    // to keep focus on the novel mechanics, but could be added.

    // Reputation System State
    mapping(address => uint256) private _userReputation;
    mapping(address => uint256) private _lastActionTime; // Timestamp for rate limiting/accrual base

    // Staking State
    mapping(address => uint256) private _reputeStakes;

    // Reputation Delegation State
    mapping(address => address) private _reputationDelegates; // delegator => delegatee
    mapping(address => uint256) private _delegationTimestamps; // delegator => timestamp of delegation start

    // ChronoGlyph NFT State (Simulated ERC-721)
    string public chronoGlyphName = "ChronoGlyph";
    string public chronoGlyphSymbol = "GLYPH";
    string private _baseURI = ""; // Base URI for token metadata
    uint256[] private _allGlyphs; // List of all token IDs (can be gas intensive for large collections)
    mapping(uint256 => uint256) private _allGlyphsIndex; // token ID => index in _allGlyphs
    mapping(uint256 => address) private _glyphOwners; // token ID => owner
    mapping(address => uint256) private _ownerGlyphCount; // owner => count of owned tokens
    mapping(uint256 => address) private _glyphApprovals; // token ID => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // ChronoGlyph Dynamic Data
    struct Glyph {
        uint64 creationTime;       // When the Glyph was minted
        uint64 lastChargedTime;    // Last time charge was added
        uint256 totalChargeApplied; // Sum of all REPUTE ever applied as charge
    }
    mapping(uint256 => Glyph) private _glyphData;
    uint256 private _nextTokenId; // Counter for minting new token IDs

    // System Parameters (Owner Controlled)
    uint256 public _reputeEarnRate;         // REPUTE earned per reputation point per unit time (scaled)
    uint256 public _reputationActionGain;   // Reputation gained per action
    uint256 public _glyphMintThreshold;     // Minimum reputation required to mint a Glyph
    uint256 public _glyphDecayRate;         // Rate at which Glyph charge decays over time (scaled)
    uint256 public _glyphChargeCost;        // Amount of REPUTE required per unit of charge added to a Glyph
    uint256 public _reputationBoostFactor;  // Factor for reputation boost from staking (e.g., 120 for 20% boost)
    uint256 public _delegationBoostFactor = 100; // Factor for potential future delegation boost (e.g., 100 = no boost)

    // System Control
    bool public paused = false;

    // --- Events ---

    event ReputeMinted(address indexed account, uint256 amount);
    event ReputeTransferred(address indexed from, address indexed to, uint256 amount); // Internal Repute transfer event
    event ReputeBurned(address indexed account, uint256 amount);
    event ReputationUpdated(address indexed account, uint256 newReputation);
    event ActionPerformed(address indexed account, uint256 actionType, uint256 reputationGained, uint256 reputeAccrued);
    event GlyphMinted(address indexed owner, uint256 indexed tokenId, uint256 creationTime);
    event GlyphTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event GlyphCharged(uint256 indexed tokenId, address indexed account, uint256 amount, uint256 newTotalCharge);
    event ReputeStaked(address indexed account, uint256 amount, uint256 newStakeBalance);
    event ReputeUnstaked(address indexed account, uint256 amount, uint256 newStakeBalance);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationDelegationRevoked(address indexed delegator, address indexed previouslyDelegatee);
    event ParameterChanged(string parameterName, uint256 newValue);
    event Paused(address account);
    event Unpaused(address account);

    // ERC721 Standard Events
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Custom Errors ---

    error TransferFromIncorrectOwner();
    error ApproveCallerIsNotOwnerNorApproved();
    error TransferToNonERC721ReceiverImplementer();
    error InvalidTokenId();
    error InsufficientRepute();
    error InsufficientReputation();
    error CannotMintYet();
    error CannotChargeYet(); // E.g., charge amount too small or not enough repute
    error MustBeOwnerOrApproved(); // Used for functions like transferFrom
    error TransferRequiresReputation(); // Example: require minimum reputation to transfer NFT
    error SystemPaused();
    error NotOwner();
    error CannotDelegateToSelf();
    error NoActiveDelegation();
    error InsufficientStake();
    error AmountMustBeGreaterThanZero();


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SystemPaused();
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1

        // Set some initial parameters (these could also be set later by owner/governance)
        _reputeEarnRate = 1e15; // Example: 1 repute per rep per second (scaled by 1e18) -> 0.001 repute per rep per second
        _reputationActionGain = 10; // Gain 10 reputation per action
        _glyphMintThreshold = 100; // Need 100 reputation to mint a Glyph
        _glyphDecayRate = 1e14; // Example: 0.0001 charge decay per second (scaled by 1e18)
        _glyphChargeCost = 1e18; // 1 REPUTE per unit of charge
        _reputationBoostFactor = 120; // 20% boost from staking
    }

    // --- Initialization & Views (Basic & ERC-like) ---

    /**
     * @notice Returns the total supply of the internal REPUTE token.
     * @return The total supply.
     */
    function reputeTotalSupply() external view returns (uint256) {
        return _reputeTotalSupply;
    }

    /**
     * @notice Returns the REPUTE balance of an account.
     * @param account The account to query.
     * @return The REPUTE balance.
     */
    function getUserReputeBalance(address account) external view returns (uint256) {
        return _reputeBalances[account];
    }

    /**
     * @notice Returns the current reputation score of an account.
     * @param account The account to query.
     * @return The reputation score.
     */
    function getUserReputation(address account) external view returns (uint256) {
        return _userReputation[account];
    }

    /**
     * @notice Returns the name of the internal REPUTE token.
     */
    function getReputeTokenName() external view returns (string memory) {
        return reputeTokenName;
    }

    /**
     * @notice Returns the symbol of the internal REPUTE token.
     */
    function getReputeTokenSymbol() external view returns (string memory) {
        return reputeTokenSymbol;
    }

    /**
     * @notice Returns the total number of ChronoGlyphs minted.
     */
    function getTotalGlyphs() external view returns (uint256) {
        return _allGlyphs.length;
    }

    /**
     * @notice Returns the owner of the ChronoGlyph with the given token ID.
     * @dev Implements ERC721 `ownerOf`.
     * @param tokenId The ID of the token to query.
     * @return The owner's address.
     * @custom:error InvalidTokenId If the token ID does not exist.
     */
    function getGlyphOwner(uint256 tokenId) public view returns (address) {
        address owner = _glyphOwners[tokenId];
        if (owner == address(0)) {
            revert InvalidTokenId();
        }
        return owner;
    }

    /**
     * @notice Returns the number of Glyphs owned by an account.
     * @dev Implements ERC721 `balanceOf`.
     * @param owner The account to query.
     * @return The number of tokens owned.
     */
    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) {
            // Standard ERC721 behavior for address zero
            revert InvalidTokenId(); // Or a specific error like ERC721Enumerable.EnumerableZeroAddress
        }
        return _ownerGlyphCount[owner];
    }


    /**
     * @notice Returns the creation timestamp of a specific Glyph.
     * @param tokenId The ID of the Glyph.
     * @return The Unix timestamp of creation.
     * @custom:error InvalidTokenId If the token ID does not exist.
     */
    function getGlyphCreationTime(uint256 tokenId) external view returns (uint256) {
        _exists(tokenId); // Check if token exists
        return _glyphData[tokenId].creationTime;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     * @dev Implements ERC165 support for ERC721 and its metadata extension.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // ERC721, ERC721Metadata
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || super.supportsInterface(interfaceId);
        // Adding `super.supportsInterface` allows composition if inheriting from other ERC165 contracts.
        // Since we don't inherit ERC165 here, it could just be the two checks.
        // Leaving it as is for potential future inheritance.
    }

    /**
     * @notice Get the approved address for a single Glyph.
     * @dev Implements ERC721 `getApproved`.
     * @param tokenId The ID of the token to query.
     * @return The approved address, or address(0) if no approval.
     * @custom:error InvalidTokenId If the token ID does not exist.
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        _exists(tokenId); // Check if token exists
        return _glyphApprovals[tokenId];
    }

    /**
     * @notice Checks if an address is an approved operator for another address.
     * @dev Implements ERC721 `isApprovedForAll`.
     * @param owner The address that owns the tokens.
     * @param operator The address that may be approved as operator.
     * @return True if `operator` is approved for `owner`, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    // --- Core Mechanics (Reputation, Repute, Glyphs) ---

    /**
     * @notice Allows a user to perform an action within the system.
     * @dev This function is the primary driver for earning reputation and accruing REPUTE.
     *      The actual logic for 'actionType' and its effects can be extended.
     *      Accrued REPUTE must be claimed separately.
     * @param actionType A identifier for the type of action performed.
     */
    function performAction(uint256 actionType) external whenNotPaused {
        address account = msg.sender;
        uint256 currentReputation = _userReputation[account];
        uint256 lastAction = _lastActionTime[account];
        uint256 currentTime = block.timestamp;

        // Calculate time delta since last action/claim for REPUTE accrual
        uint256 timeDelta = currentTime - lastAction;

        // Calculate potential REPUTE accrued based on reputation and time
        // Using delegatee's reputation for accrual if delegated
        address delegateeOrSelf = getReputationDelegateeOrSelf(account);
        uint256 effectiveReputation = _userReputation[delegateeOrSelf];

        // Apply staking boost to effective reputation for accrual calculation
        uint256 boostedReputation = effectiveReputation;
        if (_reputeStakes[account] > 0 && _reputationBoostFactor > 100) {
             // Boost formula: effectiveRep * boostFactor / 100
            boostedReputation = (effectiveReputation * _reputationBoostFactor) / 100;
        }

        // Avoid overflow if parameters are huge, or time delta is huge
        // For simplicity here, basic multiplication is used. A real system might need scaling/caps.
        uint256 potentialReputeAccrued = (boostedReputation * _reputeEarnRate * timeDelta) / (1e18); // Scale down by 1e18 for rate

        // Update last action time AFTER calculating accrual
        _lastActionTime[account] = currentTime;

        // --- Apply effects of the action ---
        // Gain reputation directly
        uint256 reputationGained = _reputationActionGain; // Simple gain, could be actionType-dependent
        _userReputation[account] = currentReputation + reputationGained;

        // Emit events
        emit ActionPerformed(account, actionType, reputationGained, potentialReputeAccrued);
        emit ReputationUpdated(account, _userReputation[account]);
        // Note: REPUTE isn't minted/transferred here, only accrued potential.

    }

    /**
     * @notice Allows a user to claim the REPUTE they have accrued since their last action/claim.
     * @dev This function triggers the actual minting of REPUTE.
     */
    function claimAccruedRepute() external whenNotPaused {
        address account = msg.sender;
        uint256 lastAction = _lastActionTime[account];
        uint256 currentTime = block.timestamp;

        // Calculate time delta since last action/claim
        uint256 timeDelta = currentTime - lastAction;

        // Calculate REPUTE to mint based on effective reputation and time
        address delegateeOrSelf = getReputationDelegateeOrSelf(account);
        uint256 effectiveReputation = _userReputation[delegateeOrSelf];

        // Apply staking boost
        uint256 boostedReputation = effectiveReputation;
         if (_reputeStakes[account] > 0 && _reputationBoostFactor > 100) {
            boostedReputation = (effectiveReputation * _reputationBoostFactor) / 100;
        }

        uint256 reputeToMint = (boostedReputation * _reputeEarnRate * timeDelta) / (1e18); // Scale down by 1e18

        if (reputeToMint == 0) {
            // Nothing to claim
            return;
        }

        // Mint the REPUTE
        _mintRepute(account, reputeToMint);

        // Update last action time to now, resetting the accrual period
        _lastActionTime[account] = currentTime;

        // Emit event (minting is done in _mintRepute)
    }

    /**
     * @notice Allows a user to mint a ChronoGlyph NFT if they meet the reputation threshold.
     * @dev Each user can likely only mint a limited number or this is a one-time claim per threshold level.
     *      For simplicity, this version allows minting one if the threshold is met, regardless of how many
     *      they already minted, though a counter per user would be more realistic.
     * @custom:error CannotMintYet If the user does not meet the reputation threshold.
     */
    function mintGlyph() external whenNotPaused {
        address account = msg.sender;

        // Check if user meets the reputation threshold (using effective reputation via delegation)
        address delegateeOrSelf = getReputationDelegateeOrSelf(account);
        if (_userReputation[delegateeOrSelf] < _glyphMintThreshold) {
            revert CannotMintYet();
        }

        // Mint the new Glyph
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(account, tokenId); // Handles ERC721 minting logic

        // Store Glyph specific data
        _glyphData[tokenId].creationTime = uint64(block.timestamp);
        _glyphData[tokenId].lastChargedTime = uint64(block.timestamp); // Initialize last charged time
        _glyphData[tokenId].totalChargeApplied = 0;

        emit GlyphMinted(account, tokenId, block.timestamp);
    }

    /**
     * @notice Allows a user to spend REPUTE to charge a ChronoGlyph, boosting its total charge.
     * @dev The `amount` here refers to the amount of REPUTE spent, not the charge units.
     *      Charge units are derived from REPUTE spent via `_glyphChargeCost`.
     * @param tokenId The ID of the Glyph to charge.
     * @param amount The amount of REPUTE to spend on charging.
     * @custom:error InvalidTokenId If the token does not exist.
     * @custom:error MustBeOwnerOrApproved If the caller is not the owner or approved for the token.
     * @custom:error InsufficientRepute If the user doesn't have enough REPUTE.
     * @custom:error CannotChargeYet If the charge amount is too small or other custom constraints.
     */
    function chargeGlyph(uint256 tokenId, uint256 amount) external whenNotPaused {
        address account = msg.sender;
        address owner = getGlyphOwner(tokenId); // Will revert if invalid token
        address approved = _glyphApprovals[tokenId];

        // Check ownership or approval
        if (owner != account && approved != account && !_operatorApprovals[owner][account]) {
            revert MustBeOwnerOrApproved();
        }

        // Check if caller is the owner (or approved operator acting on behalf of owner)
        // For simplicity, we require the caller to have the repute, so require caller is owner.
        // A more complex system might allow approved operators to spend the owner's repute.
         if (owner != account) revert MustBeOwnerOrApproved(); // Restrict to owner for simplicity of REPUTE spending

        if (amount == 0) revert CannotChargeYet(); // Minimum charge amount

        // Check REPUTE balance
        if (_reputeBalances[account] < amount) {
            revert InsufficientRepute();
        }

        // Spend REPUTE
        _burnRepute(account, amount); // Internal burn

        // Calculate charge units added
        uint256 chargeUnitsAdded = amount / _glyphChargeCost;
        if (chargeUnitsAdded == 0) {
             // Refund REPUTE if it resulted in 0 charge units, or simply disallow
             // Let's disallow small amounts for simplicity
            _mintRepute(account, amount); // Refund
            revert CannotChargeYet(); // Amount too small to add meaningful charge
        }


        // Update Glyph data
        _glyphData[tokenId].totalChargeApplied += chargeUnitsAdded;
        _glyphData[tokenId].lastChargedTime = uint64(block.timestamp);

        emit GlyphCharged(tokenId, account, amount, _glyphData[tokenId].totalChargeApplied);
    }

    /**
     * @notice Calculates the current effective charge of a ChronoGlyph.
     * @dev The charge decays over time based on `_glyphDecayRate`.
     * @param tokenId The ID of the Glyph.
     * @return The current effective charge.
     * @custom:error InvalidTokenId If the token does not exist.
     */
    function calculateGlyphCurrentCharge(uint256 tokenId) public view returns (uint256) {
         _exists(tokenId); // Check if token exists

        Glyph memory glyph = _glyphData[tokenId];
        uint256 totalCharge = glyph.totalChargeApplied;
        uint256 lastCharged = glyph.lastChargedTime;
        uint256 creationTime = glyph.creationTime;
        uint256 currentTime = block.timestamp;

        uint256 effectiveTimeSinceLastCharge = currentTime - lastCharged;
        uint256 effectiveTimeSinceCreation = currentTime - creationTime;

        // Determine the time delta relevant for decay calculation.
        // Decay happens from the last time charge was added or creation if never charged.
        uint256 timeDeltaForDecay = (lastCharged > 0 && lastCharged >= creationTime) ? effectiveTimeSinceLastCharge : effectiveTimeSinceCreation;


        uint256 decayAmount = 0;
        // Avoid overflow if timeDelta is huge
        if (timeDeltaForDecay > 0 && _glyphDecayRate > 0) {
             // decay = timeDelta * decayRate / 1e18 (scaled)
            decayAmount = (timeDeltaForDecay * _glyphDecayRate) / (1e18);
        }

        // Current charge is total charge minus decay, minimum 0
        uint256 currentCharge = totalCharge > decayAmount ? totalCharge - decayAmount : 0;

        return currentCharge;
    }


     /**
      * @notice Simulates an internal REPUTE transfer between two addresses.
      * @dev This does not fully implement ERC-20 `transfer` as it lacks approvals/allowances.
      *      It's used for internal token movements like claims, burns, staking.
      * @param from The sender's address.
      * @param to The recipient's address.
      * @param amount The amount of REPUTE to transfer.
      * @custom:error InsufficientRepute If the sender's balance is insufficient.
      */
    function transferRepute(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert InvalidTokenId(); // Should not transfer from zero address
        if (to == address(0)) revert InvalidTokenId(); // Should not transfer to zero address
        if (amount == 0) return; // No-op for zero amount

        if (_reputeBalances[from] < amount) revert InsufficientRepute();

        _reputeBalances[from] -= amount;
        _reputeBalances[to] += amount;

        emit ReputeTransferred(from, to, amount);
    }

    /**
     * @notice Allows a user to burn their own REPUTE tokens.
     * @param amount The amount of REPUTE to burn.
     * @custom:error InsufficientRepute If the user doesn't have enough REPUTE.
     * @custom:error AmountMustBeGreaterThanZero If amount is zero.
     */
    function burnRepute(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        _burnRepute(msg.sender, amount);
    }


    // --- Staking ---

    /**
     * @notice Allows a user to stake REPUTE tokens to gain a reputation boost.
     * @param amount The amount of REPUTE to stake.
     * @custom:error InsufficientRepute If the user doesn't have enough REPUTE.
     * @custom:error AmountMustBeGreaterThanZero If amount is zero.
     */
    function stakeReputeForBoost(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        address account = msg.sender;

        // Check balance and move REPUTE from balance to stake
        if (_reputeBalances[account] < amount) revert InsufficientRepute();
        _reputeBalances[account] -= amount;
        _reputeStakes[account] += amount;

        emit ReputeStaked(account, amount, _reputeStakes[account]);
    }

    /**
     * @notice Allows a user to unstake their REPUTE tokens.
     * @param amount The amount of REPUTE to unstake.
     * @custom:error InsufficientStake If the user doesn't have enough staked REPUTE.
     * @custom:error AmountMustBeGreaterThanZero If amount is zero.
     */
    function unstakeRepute(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        address account = msg.sender;

        // Check stake balance and move REPUTE from stake to balance
        if (_reputeStakes[account] < amount) revert InsufficientStake();
        _reputeStakes[account] -= amount;
        _reputeBalances[account] += amount;

        emit ReputeUnstaked(account, amount, _reputeStakes[account]);
    }

     /**
     * @notice Returns the amount of REPUTE staked by an account.
     * @param account The account to query.
     * @return The staked REPUTE amount.
     */
    function getUserStakedRepute(address account) external view returns (uint256) {
        return _reputeStakes[account];
    }


    // --- Delegation (Creative Governance Element) ---

    /**
     * @notice Delegates this account's reputation influence to a delegatee.
     * @dev The delegatee's reputation might be used in calculations affecting
     *      accrual rates or minting eligibility for the delegator.
     *      This does *not* transfer ownership or control of reputation points,
     *      only how they are *used* in certain calculations defined in the contract.
     * @param delegatee The address to delegate reputation influence to. Use address(0) to revoke.
     * @custom:error CannotDelegateToSelf If attempting to delegate to self.
     */
    function delegateReputationPower(address delegatee) external whenNotPaused {
        address delegator = msg.sender;
        if (delegator == delegatee) revert CannotDelegateToSelf();

        address currentDelegatee = _reputationDelegates[delegator];
        if (currentDelegatee == delegatee) {
            // No change needed
            return;
        }

        _reputationDelegates[delegator] = delegatee;
        _delegationTimestamps[delegator] = block.timestamp;

        if (delegatee == address(0)) {
             emit ReputationDelegationRevoked(delegator, currentDelegatee);
        } else {
             emit ReputationDelegated(delegator, delegatee);
        }
    }

    /**
     * @notice Revokes any active reputation delegation for the caller.
     * @custom:error NoActiveDelegation If there is no delegation to revoke.
     */
    function revokeReputationDelegation() external whenNotPaused {
         address delegator = msg.sender;
         address currentDelegatee = _reputationDelegates[delegator];
         if (currentDelegatee == address(0)) revert NoActiveDelegation();

         _reputationDelegates[delegator] = address(0);
         _delegationTimestamps[delegator] = 0;

         emit ReputationDelegationRevoked(delegator, currentDelegatee);
    }

    /**
     * @notice Gets the address the account has delegated their reputation influence to.
     * @param account The account to query.
     * @return The delegatee's address, or address(0) if no delegation.
     */
    function getReputationDelegatee(address account) external view returns (address) {
        return _reputationDelegates[account];
    }

     /**
      * @notice Returns the account's delegatee if set, otherwise returns the account's own address.
      * @dev Useful for internal calculations where the "effective" address for reputation is needed.
      * @param account The account to query.
      * @return The delegatee's address or the account's address.
      */
    function getReputationDelegateeOrSelf(address account) public view returns (address) {
        address delegatee = _reputationDelegates[account];
        return delegatee == address(0) ? account : delegatee;
    }


    // --- Glyph Management (ERC721-like Internal Logic) ---

    /**
     * @dev Internal function to check if a token ID exists.
     * @custom:error InvalidTokenId If the token does not exist.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
         if (_glyphOwners[tokenId] == address(0) && tokenId != 0) { // token 0 is typically invalid in ERC721
             revert InvalidTokenId();
         }
         // Return true if owner is not address(0), implying it exists
         return _glyphOwners[tokenId] != address(0);
    }

    /**
     * @dev Internal function to get the owner of a token without reverting on invalid ID.
     */
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _glyphOwners[tokenId];
    }

    /**
     * @dev Internal function to clear current approval for a token ID.
     */
    function _clearApproval(uint256 tokenId) internal {
        if (_glyphApprovals[tokenId] != address(0)) {
            _glyphApprovals[tokenId] = address(0);
        }
    }

    /**
     * @dev Internal minting function.
     * @param to The recipient address.
     * @param tokenId The ID of the token to mint.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address"); // Standard ERC721 check
        require(!_exists(tokenId), "ERC721: token already minted"); // Should not happen with _nextTokenId

        _ownerGlyphCount[to]++;
        _glyphOwners[tokenId] = to;
        _allGlyphs.push(tokenId);
        _allGlyphsIndex[tokenId] = _allGlyphs.length - 1;

        emit GlyphTransferred(address(0), to, tokenId); // Standard ERC721 mint event
    }

    /**
     * @dev Internal safe minting function with receiver check.
     * @param to The recipient address.
     * @param tokenId The ID of the token to mint.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        // Check if receiver is a contract and if it supports ERC721Receiver
        if (to.code.length > 0) {
             // Use a try-catch block for safety
             try IERC721Receiver(to).onERC721Received(msg.sender, address(0), tokenId, "") returns (bytes4 retval) {
                 if (retval != IERC721Receiver.onERC721Received.selector) {
                      revert TransferToNonERC721ReceiverImplementer();
                 }
             } catch {
                  revert TransferToNonERC721ReceiverImplementer();
             }
        }
    }

    /**
     * @dev Internal transfer function.
     * @param from The current owner.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner"); // Standard ERC721 check
        require(to != address(0), "ERC721: transfer to the zero address"); // Standard ERC721 check

        _clearApproval(tokenId);

        _ownerGlyphCount[from]--;
        _ownerGlyphCount[to]++;
        _glyphOwners[tokenId] = to;

        emit GlyphTransferred(from, to, tokenId); // Standard ERC721 transfer event
    }

    /**
     * @notice Transfers a ChronoGlyph.
     * @dev Implements ERC721 `transferFrom`. Requires caller to be owner, approved, or operator.
     *      Includes a custom check requiring the sender (`from`) to have a minimum reputation.
     * @param from The current owner.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     * @custom:error MustBeOwnerOrApproved If the caller is not authorized.
     * @custom:error TransferRequiresReputation If the sender (`from`) doesn't meet reputation requirement.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
         // Standard ERC721 checks for authorization
         if (!_isApprovedOrOwner(msg.sender, tokenId)) {
             revert MustBeOwnerOrApproved();
         }

         // Custom check: requires the *sender* (the 'from' address) to have minimum reputation
         // This adds a unique constraint to transferring the dynamic NFTs.
         // Example: require minimum reputation 50 to transfer any Glyph.
         if (_userReputation[from] < 50) { // Example threshold, could be a parameter
             revert TransferRequiresReputation();
         }


        _transfer(from, to, tokenId);
    }

    /**
     * @notice Safely transfers a ChronoGlyph.
     * @dev Implements ERC721 `safeTransferFrom`. Includes custom reputation check.
     * @param from The current owner.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

     /**
     * @notice Safely transfers a ChronoGlyph with data.
     * @dev Implements ERC721 `safeTransferFrom` with data. Includes custom reputation check.
     * @param from The current owner.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     * @param data Additional data to pass to the receiver.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused {
        // Note: This calls the standard `transferFrom` which includes our custom reputation check.
        transferFrom(from, to, tokenId);

        // Check if receiver is a contract and if it supports ERC721Receiver
        if (to.code.length > 0) {
             try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                 if (retval != IERC721Receiver.onERC721Received.selector) {
                     revert TransferToNonERC721ReceiverImplementer();
                 }
             } catch {
                 revert TransferToNonERC721ReceiverImplementer();
             }
        }
    }

    /**
     * @dev Internal function to check if a caller is the owner or approved/operator for a token.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _ownerOf(tokenId); // Will revert if invalid token
        return (spender == owner || _glyphApprovals[tokenId] == spender || _operatorApprovals[owner][spender]);
    }


    /**
     * @notice Approves an address to manage a specific Glyph.
     * @dev Implements ERC721 `approve`. Caller must be the owner or an approved operator.
     * @param to The address to approve.
     * @param tokenId The ID of the token to approve.
     * @custom:error ApproveCallerIsNotOwnerNorApproved If the caller is not authorized.
     * @custom:error InvalidTokenId If the token does not exist.
     */
    function approve(address to, uint256 tokenId) public virtual override whenNotPaused {
        address owner = getGlyphOwner(tokenId); // Will revert if invalid token
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert ApproveCallerIsNotOwnerNorApproved();
        }
        // Standard ERC721: cannot approve owner, must clear approval if approving zero address
        if (to == owner) {
             _clearApproval(tokenId);
        } else {
            _glyphApprovals[tokenId] = to;
        }

        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Approves or disapproves an operator for all Glyphs owned by the caller.
     * @dev Implements ERC721 `setApprovalForAll`.
     * @param operator The address to approve or disapprove as operator.
     * @param approved True to approve, false to disapprove.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

     /**
      * @notice Sets the base URI for ChronoGlyph token metadata.
      * @dev Only callable by the owner.
      * @param baseURI_ The new base URI.
      */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * @notice Returns the token URI for a ChronoGlyph.
     * @dev Implements ERC721Metadata `tokenURI`. Concatenates base URI with token ID.
     * @param tokenId The ID of the token.
     * @return The full token URI.
     * @custom:error InvalidTokenId If the token does not exist.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        _exists(tokenId); // Ensure token exists

        if (bytes(_baseURI).length == 0) {
            return "";
        }

        // Concatenate base URI and token ID
        return string(abi.encodePacked(_baseURI, _toString(tokenId)));
    }

    // Helper function for tokenURI (convert uint256 to string) - Basic implementation
     function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Governance & Parameters (Owner Only for Simplicity) ---

    /**
     * @notice Sets the rate at which REPUTE is earned based on reputation and time.
     * @dev Only callable by the owner. Value is scaled by 1e18.
     * @param rate The new REPUTE earn rate.
     */
    function setParameter_ReputeEarnRate(uint256 rate) external onlyOwner {
        _reputeEarnRate = rate;
        emit ParameterChanged("ReputeEarnRate", rate);
    }

     /**
     * @notice Sets the reputation gained per action performed.
     * @dev Only callable by the owner.
     * @param gain The new reputation gain per action.
     */
    function setParameter_ReputationActionGain(uint256 gain) external onlyOwner {
        _reputationActionGain = gain;
         emit ParameterChanged("ReputationActionGain", gain);
    }

    /**
     * @notice Sets the minimum reputation required to mint a ChronoGlyph.
     * @dev Only callable by the owner.
     * @param threshold The new reputation threshold.
     */
    function setParameter_GlyphMintThreshold(uint256 threshold) external onlyOwner {
        _glyphMintThreshold = threshold;
        emit ParameterChanged("GlyphMintThreshold", threshold);
    }

    /**
     * @notice Sets the rate at which ChronoGlyph charge decays over time.
     * @dev Only callable by the owner. Value is scaled by 1e18.
     * @param rate The new decay rate.
     */
    function setParameter_GlyphDecayRate(uint256 rate) external onlyOwner {
        _glyphDecayRate = rate;
        emit ParameterChanged("GlyphDecayRate", rate);
    }

     /**
     * @notice Sets the REPUTE cost per unit of charge added to a Glyph.
     * @dev Only callable by the owner.
     * @param cost The new charge cost.
     */
    function setParameter_GlyphChargeCost(uint256 cost) external onlyOwner {
        _glyphChargeCost = cost;
        emit ParameterChanged("GlyphChargeCost", cost);
    }

     /**
     * @notice Sets the boost factor applied to reputation gain from staking.
     * @dev Only callable by the owner. Value is scaled by 100 (e.g., 120 = 20% boost).
     * @param factor The new boost factor.
     */
    function setParameter_ReputationBoostFactor(uint256 factor) external onlyOwner {
        _reputationBoostFactor = factor;
        emit ParameterChanged("ReputationBoostFactor", factor);
    }

     /**
     * @notice Gets the current REPUTE earn rate parameter.
     * @dev Value is scaled by 1e18.
     */
    function getParameter_ReputeEarnRate() external view returns (uint256) {
        return _reputeEarnRate;
    }

     /**
     * @notice Gets the current Glyph minting reputation threshold parameter.
     */
    function getParameter_GlyphMintThreshold() external view returns (uint256) {
        return _glyphMintThreshold;
    }

    /**
     * @notice Gets the current Glyph charge decay rate parameter.
     * @dev Value is scaled by 1e18.
     */
    function getParameter_GlyphDecayRate() external view returns (uint256) {
        return _glyphDecayRate;
    }


    // --- System Control ---

    /**
     * @notice Pauses key state-changing functions in the contract.
     * @dev Only callable by the owner.
     */
    function emergencyPause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, re-enabling state-changing functions.
     * @dev Only callable by the owner.
     */
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to transfer any ERC20 token stuck in the contract.
     * @dev Standard safety function.
     * @param tokenAddress The address of the ERC20 token.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function transferAnyERC20Token(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(tokenAddress), recipient, amount);
    }


    // --- Internal Repute Token Logic ---

    /**
     * @dev Internal function to mint REPUTE tokens.
     * @param account The recipient address.
     * @param amount The amount to mint.
     */
    function _mintRepute(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidTokenId();
        _reputeTotalSupply += amount;
        _reputeBalances[account] += amount;
        emit ReputeMinted(account, amount);
        emit ReputeTransferred(address(0), account, amount); // Standard ERC-20 Mint is transfer from address(0)
    }

    /**
     * @dev Internal function to burn REPUTE tokens.
     * @param account The account burning tokens.
     * @param amount The amount to burn.
     * @custom:error InsufficientRepute If the account doesn't have enough REPUTE.
     */
    function _burnRepute(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidTokenId();
        if (_reputeBalances[account] < amount) revert InsufficientRepute();

        _reputeBalances[account] -= amount;
        _reputeTotalSupply -= amount;
        emit ReputeBurned(account, amount);
        emit ReputeTransferred(account, address(0), amount); // Standard ERC-20 Burn is transfer to address(0)
    }
}
```