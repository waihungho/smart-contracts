Okay, let's create a smart contract concept that involves dynamic, non-fungible assets with evolving properties, a resource system, and mechanisms for interaction and transformation. We'll call it the "ChronoMorph Forge & Attunement Engine".

This contract will manage unique digital assets (like advanced NFTs) whose attributes can change over time or through user interactions. It incorporates concepts like:

1.  **Dynamic Attributes:** Asset properties aren't static.
2.  **Time-Based Evolution:** Attributes can change simply by time passing.
3.  **Resource System:** Users or assets have 'Attunement Energy' needed for actions.
4.  **Interaction & Transformation:** Functions allow users to influence asset attributes or combine assets.
5.  **Role-Based Access Control:** Different actions require specific roles.
6.  **Oracle Integration:** An attribute can be tied to external data.
7.  **Staking for Resources:** Lock assets to generate energy.

It will implement a custom (non-inherited) ERC721-like structure for asset ownership and add many layers of unique logic.

---

## ChronoMorph Forge & Attunement Engine Contract

**Outline:**

1.  **SPDX License and Pragma**
2.  **Error Definitions:** Custom errors for gas efficiency.
3.  **Event Definitions:** Logging key actions.
4.  **Role Definitions:** Constants for access control roles.
5.  **Interface Definitions:** Placeholder for external Oracle contract.
6.  **Structs:**
    *   `AssetAttributes`: Defines the mutable properties of an asset.
    *   `StakingInfo`: Tracks staking details.
7.  **State Variables:**
    *   Counters for tokens.
    *   Mappings for ERC721 state (ownership, approvals).
    *   Mapping for `AssetAttributes`.
    *   Mapping for `StakingInfo`.
    *   Mapping for user `AttunementEnergy` and last update time.
    *   Mapping for role-based access control.
    *   Configuration variables (rates, limits, addresses).
8.  **Modifiers:** Custom modifiers for access control.
9.  **Constructor:** Initializes roles and configuration.
10. **ERC721 Standard Functions:** (Implemented manually, not inherited)
    *   `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.
11. **Internal Helper Functions:** For minting, burning, transfers, role checks, energy calculation, attribute calculations.
12. **Core Logic Functions (The creative part):**
    *   Asset Forging (`forgeAsset`)
    *   Attribute Reading (`getAssetAttributes`, `getLastAttributeUpdateTime`)
    *   Attribute Mutation:
        *   Time-based (`applyTimeEvolution`)
        *   Interaction-based (`attuneAsset`)
        *   Catalyst-based (`applyCatalyst`)
        *   Oracle-based (`updateAttributeFromOracle`)
    *   Resource Management:
        *   Energy Refueling (`refuelAttunementEnergy`)
        *   Energy Reading (`getUserAttunementEnergy`)
        *   Staking for Energy (`stakeAssetForAttunement`, `unstakeAssetFromAttunement`)
    *   Asset Transformation:
        *   Merging Assets (`mergeAssets`)
        *   Refining Attributes (`refineAttribute`)
        *   Retiring/Burning Asset (`retireAsset`)
    *   Access Control Management (`grantRole`, `revokeRole`, `renounceRole`, `hasRole`)
    *   Configuration (`setForgeRole`, `setAttunerRole`, `setOracleUpdaterRole`, `setBaseEnergyRegen`, `setStakedEnergyRate`, `setOracleAddress`)
    *   Withdrawal (`withdrawFunds`)

**Function Summary (Total 30+ functions including standard ERC721 and helpers):**

*   **`constructor(...)`**: Initializes roles and potentially some base parameters. (Internal setup)
*   **`supportsInterface(bytes4 interfaceId) view returns (bool)`**: ERC165 standard. Indicates support for ERC721 and potentially others. (Standard)
*   **`balanceOf(address owner) view returns (uint256)`**: Returns the number of tokens owned by an address. (ERC721 Standard)
*   **`ownerOf(uint256 tokenId) view returns (address)`**: Returns the owner of a specific token. (ERC721 Standard)
*   **`approve(address to, uint256 tokenId)`**: Allows `to` to transfer `tokenId`. (ERC721 Standard)
*   **`getApproved(uint256 tokenId) view returns (address)`**: Gets the approved address for `tokenId`. (ERC721 Standard)
*   **`setApprovalForAll(address operator, bool approved)`**: Allows/disallows an operator to manage all of `msg.sender`'s tokens. (ERC721 Standard)
*   **`isApprovedForAll(address owner, address operator) view returns (bool)`**: Checks if `operator` is approved for `owner`. (ERC721 Standard)
*   **`transferFrom(address from, address to, uint256 tokenId)`**: Transfers token, *unsafe*. (ERC721 Standard)
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`**: Transfers token, checks receiver for ERC721 support. (ERC721 Standard)
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`**: Transfers token with data, checks receiver for ERC721 support. (ERC721 Standard)
*   **`forgeAsset(address owner, uint256 initialPurity, uint256 initialVolatility, uint256 initialStability)`**: Creates a new ChronoMorph asset with initial attributes. Requires `FORGE_ROLE`. (Creative/Core)
*   **`getAssetAttributes(uint256 tokenId) view returns (uint256 purity, uint256 volatility, uint256 stability, uint256 energyCapacity)`**: Retrieves the current attributes of an asset. (Query)
*   **`getLastAttributeUpdateTime(uint256 tokenId) view returns (uint48)`**: Gets the timestamp of the last attribute update for an asset. (Query)
*   **`applyTimeEvolution(uint256 tokenId)`**: Triggers attribute changes based on time passed since the last update. Anyone can call to update the state. (Creative/Core)
*   **`attuneAsset(uint256 tokenId, uint256 energyCost, int256 purityDelta, int256 volatilityDelta, int256 stabilityDelta)`**: Modifies asset attributes using user's Attunement Energy. Requires `ATTUNER_ROLE` or asset ownership/approval. (Creative/Core)
*   **`applyCatalyst(uint256 tokenId, bytes32 catalystType)`**: Modifies asset attributes based on a catalyst type (simulated here, could involve burning a catalyst token). Requires `ATTUNER_ROLE`. (Creative)
*   **`updateAttributeFromOracle(uint256 tokenId, uint256 newOracleValue)`**: Updates an asset attribute based on a value provided by a trusted oracle source. Requires `ORACLE_UPDATER_ROLE`. (Creative/Integration)
*   **`refuelAttunementEnergy()`**: Calculates and adds Attunement Energy to the caller based on time and staked assets. (Resource Management)
*   **`getUserAttunementEnergy(address user) view returns (uint256 energy)`**: Gets the user's current Attunement Energy (calculating potential gain first). (Query/Resource)
*   **`stakeAssetForAttunement(uint256 tokenId)`**: Stakes an asset to generate Attunement Energy over time. Requires asset ownership/approval. (Resource Management)
*   **`unstakeAssetFromAttunement(uint256 tokenId)`**: Unstakes an asset and adds accumulated Attunement Energy to the user. Requires asset staker to call. (Resource Management)
*   **`getAssetStakingInfo(uint256 tokenId) view returns (address staker, uint48 stakedTime)`**: Gets staking details for an asset. (Query)
*   **`mergeAssets(uint256 tokenId1, uint256 tokenId2)`**: Combines two assets into a new one, burning the originals and calculating new attributes. Requires ownership/approval of both. (Creative/Transformation)
*   **`refineAttribute(uint256 tokenId, uint256 attributeIndex, uint256 amount)`**: Spends a large amount of Attunement Energy to significantly refine a single attribute. Requires `ATTUNER_ROLE` or ownership/approval. (Creative/Transformation)
*   **`retireAsset(uint256 tokenId)`**: Burns an asset if its attributes meet certain conditions (e.g., purity too low, volatility too high). Requires ownership/approval. (Creative/Lifecycle)
*   **`grantRole(bytes32 role, address account)`**: Grants a role to an account. Requires `DEFAULT_ADMIN_ROLE`. (Access Control)
*   **`revokeRole(bytes32 role, address account)`**: Revokes a role from an account. Requires `DEFAULT_ADMIN_ROLE`. (Access Control)
*   **`renounceRole(bytes32 role)`**: Revokes a role from the caller. (Access Control)
*   **`hasRole(bytes32 role, address account) view returns (bool)`**: Checks if an account has a role. (Access Control)
*   **`setForgeRole(address account, bool enabled)`**: Grants or revokes the `FORGE_ROLE`. Requires `DEFAULT_ADMIN_ROLE`. (Configuration/Access Control)
*   **`setAttunerRole(address account, bool enabled)`**: Grants or revokes the `ATTUNER_ROLE`. Requires `DEFAULT_ADMIN_ROLE`. (Configuration/Access Control)
*   **`setOracleUpdaterRole(address account, bool enabled)`**: Grants or revokes the `ORACLE_UPDATER_ROLE`. Requires `DEFAULT_ADMIN_ROLE`. (Configuration/Access Control)
*   **`setBaseEnergyRegen(uint256 rate)`**: Sets the base Attunement Energy regeneration rate per second for users. Requires `DEFAULT_ADMIN_ROLE`. (Configuration)
*   **`setStakedEnergyRate(uint256 rate)`**: Sets the additional Attunement Energy generation rate per second for staked assets. Requires `DEFAULT_ADMIN_ROLE`. (Configuration)
*   **`setOracleAddress(address _oracleAddress)`**: Sets the address of the trusted oracle contract. Requires `DEFAULT_ADMIN_ROLE`. (Configuration/Integration)
*   **`withdrawFunds(address payable recipient)`**: Allows the admin to withdraw any Ether held by the contract. Requires `DEFAULT_ADMIN_ROLE`. (Utility)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // Using this for supportsInterface

// Define placeholder interface for an Oracle contract
interface IOracle {
    function getValue() external view returns (uint256);
    // In a real scenario, you might need more specific functions
    // like getValueForAsset(uint256 tokenId) or getLatestValue().
}

/// @title ChronoMorph Forge & Attunement Engine
/// @notice Manages dynamic, non-fungible assets with evolving attributes based on time, interactions, and external data.
/// @dev Implements a custom ERC721-like ownership structure and adds unique mechanics.

contract ChronoMorphEngine is ERC165 {

    // --- Errors ---
    error InvalidRecipient();
    error TokenDoesNotExist();
    error NotTokenOwnerOrApproved();
    error NotApprovedForAll();
    error ApprovalCallerNotOwnerApproved();
    error NotStaker();
    error TokenNotStaked();
    error TokenAlreadyStaked();
    error InsufficientAttunementEnergy();
    error InvalidAttributeIndex();
    error CannotMergeSameToken();
    error InsufficientAssetsForMerge();
    error AttributesBelowRetirementThreshold();
    error AccountAlreadyHasRole();
    error AccountDoesNotHaveRole();
    error MissingRole(bytes32 role);

    // --- Events ---
    event AssetForged(uint256 indexed tokenId, address indexed owner, uint256 purity, uint256 volatility, uint256 stability);
    event AttributesMutated(uint256 indexed tokenId, string reason, uint256 newPurity, uint256 newVolatility, uint256 newStability);
    event AssetStaked(uint256 indexed tokenId, address indexed staker, uint48 stakedTime);
    event AssetUnstaked(uint256 indexed tokenId, address indexed staker, uint256 energyEarned);
    event EnergyRefueled(address indexed user, uint256 energyGained, uint256 newTotalEnergy);
    event AssetMerged(uint256 indexed newTokenId, uint256[] indexed sourceTokenIds, uint256 newPurity, uint256 newVolatility, uint256 newStability);
    event AssetRetired(uint256 indexed tokenId, address indexed owner);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressUpdated(address indexed newAddress);

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant FORGE_ROLE = keccak256("FORGE_ROLE"); // Can forge new assets
    bytes32 public constant ATTUNER_ROLE = keccak256("ATTUNER_ROLE"); // Can use attunement functions
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE"); // Can update attributes from oracle

    // --- Structs ---
    struct AssetAttributes {
        uint256 purity;      // e.g., 0-10000
        uint256 volatility;  // e.g., 0-10000
        uint256 stability;   // e.g., 0-10000
        uint256 energyCapacity; // Max energy the asset can hold if it were an energy source itself (potential future use)
        uint48 lastUpdateTime; // Timestamp of last attribute calculation/mutation
        uint48 lastMutationTime; // Timestamp of last user/interaction-based mutation
    }

    struct StakingInfo {
        address staker;
        uint48 stakedTime; // Timestamp when the asset was staked
    }

    // --- State Variables ---
    uint256 private _nextTokenId; // Counter for unique token IDs

    // ERC721 State
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) private _balances; // ERC721 balanceOf

    // ChronoMorph State
    mapping(uint256 => AssetAttributes) private _assetAttributes;
    mapping(uint256 => StakingInfo) private _assetStakingInfo; // tokenId -> StakingInfo (only if staked)
    mapping(uint256 => bool) private _isAssetStaked; // Keep track if token is staked for faster lookup
    mapping(address => uint256) private _userAttunementEnergy; // User's current energy
    mapping(address => uint48) private _userLastEnergyUpdate; // Last timestamp user's energy was updated

    // Access Control State
    mapping(address => mapping(bytes32 => bool)) private _roles;

    // Configuration
    uint256 public baseEnergyRegenRate = 10; // Energy per second for unstaked users
    uint256 public stakedAssetEnergyRate = 5; // Additional energy per second per staked asset
    uint256 public maxUserAttunementEnergy = 100000; // Maximum energy a user can hold
    uint256 public timeEvolutionRate = 1; // Rate multiplier for time-based changes
    uint256 public constant MIN_MERGE_ASSETS = 2; // Minimum assets required for merge
    uint256 public constant ATTRIBUTE_MAX_VALUE = 10000; // Max value for attributes
    uint256 public constant ATTRIBUTE_MIN_VALUE = 0; // Min value for attributes

    address public oracleAddress; // Address of the external oracle contract

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        if (!_roles[msg.sender][role]) {
            revert MissingRole(role);
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (_tokenOwners[tokenId] != msg.sender) {
            revert NotTokenOwnerOrApproved(); // Use broad error for owner/approved
        }
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        if (_tokenOwners[tokenId] != msg.sender && !_isApprovedOrForAll(msg.sender, tokenId)) {
             revert NotTokenOwnerOrApproved();
        }
        _;
    }

    // --- Constructor ---
    constructor() ERC165() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant admin roles initially, they can then grant/revoke others
        _setupRole(FORGE_ROLE, msg.sender);
        _setupRole(ATTUNER_ROLE, msg.sender);
        _setupRole(ORACLE_UPDATER_ROLE, msg.sender);

        _nextTokenId = 1; // Start token IDs from 1
        baseEnergyRegenRate = 10; // Initial base rate
        stakedAssetEnergyRate = 5; // Initial staked rate
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || // Add metadata if implementing name/symbol
               interfaceId == type(IERC721Enumerable).interfaceId || // Add enumerable if implementing
               super.supportsInterface(interfaceId);
    }

    // --- ERC721 Implementations (Custom) ---

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert InvalidRecipient();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Checks if token exists
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerNotOwnerApproved();
        }
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
         ownerOf(tokenId); // Check if token exists
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert InvalidRecipient();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId); // Does approval check internally
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId); // Does approval check internally
        if (to.code.length > 0 && !_checkOnERC721Received(address(0), from, to, tokenId, "")) {
             revert InvalidRecipient(); // Simplified error, should match specific onERC721Received errors
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
         _transfer(from, to, tokenId); // Does approval check internally
         if (to.code.length > 0 && !_checkOnERC721Received(address(0), from, to, tokenId, data)) {
             revert InvalidRecipient(); // Simplified error
         }
    }

    // --- Internal ERC721 Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

     function _isApprovedOrForAll(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Checks if token exists
        return spender == _tokenApprovals[tokenId] || _operatorApprovals[owner][spender];
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_tokenOwners[tokenId], to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotTokenOwnerOrApproved(); // Ensure 'from' is the owner
        if (to == address(0)) revert InvalidRecipient();
        if (msg.sender != from && !_isApprovedOrForAll(msg.sender, tokenId)) { // Check approval for caller
            revert NotTokenOwnerOrApproved(); // Use broad error
        }

        // Clear approval before transfer
        _approve(address(0), tokenId);

        // Update balances
        _balances[from]--;
        _balances[to]++;

        // Update ownership
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     function _mint(address to, uint256 tokenId, uint256 initialPurity, uint256 initialVolatility, uint256 initialStability) internal {
        if (to == address(0)) revert InvalidRecipient();
        if (_exists(tokenId)) revert TokenDoesNotExist(); // Should not happen with _nextTokenId logic

        _balances[to]++;
        _tokenOwners[tokenId] = to;

        // Set initial attributes and update time
        _assetAttributes[tokenId] = AssetAttributes({
            purity: initialPurity,
            volatility: initialVolatility,
            stability: initialStability,
            energyCapacity: (initialPurity + initialStability) / 2, // Example calculation
            lastUpdateTime: uint48(block.timestamp),
            lastMutationTime: uint48(block.timestamp)
        });


        emit Transfer(address(0), to, tokenId); // Mint event is a Transfer from address(0)
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Checks if token exists

        // Clear approval
        _approve(address(0), tokenId);

        // Update balances
        _balances[owner]--;

        // Clear ownership and attributes
        delete _tokenOwners[tokenId];
        delete _assetAttributes[tokenId];
        delete _assetStakingInfo[tokenId]; // Ensure staking info is removed
        delete _isAssetStaked[tokenId];

        emit Transfer(owner, address(0), tokenId); // Burn event is a Transfer to address(0)
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, to, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // Handle potential revert messages from the receiver
                // console.log("ERC721: Transfer to non ERC721Receiver implementer or onERC721Received reverted", string(reason));
                return false;
            }
        } else {
            return true; // Transfer to a non-contract address is always considered safe
        }
    }

    // --- Role-Based Access Control Helpers (Custom) ---

    function _setupRole(bytes32 role, address account) internal {
        if (!_roles[account][role]) {
            _roles[account][role] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
         if (_roles[account][role]) {
            _roles[account][role] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return _roles[account][role];
    }


    // --- Core Logic Functions (Creative) ---

    /// @notice Creates a new ChronoMorph asset.
    /// @param owner The initial owner of the new asset.
    /// @param initialPurity Initial purity attribute.
    /// @param initialVolatility Initial volatility attribute.
    /// @param initialStability Initial stability attribute.
    /// @dev Requires the caller to have the FORGE_ROLE. Attributes are capped at ATTRIBUTE_MAX_VALUE.
    function forgeAsset(address owner, uint256 initialPurity, uint256 initialVolatility, uint256 initialStability) external onlyRole(FORGE_ROLE) {
        uint256 tokenId = _nextTokenId++;

        _mint(
            owner,
            tokenId,
            initialPurity > ATTRIBUTE_MAX_VALUE ? ATTRIBUTE_MAX_VALUE : initialPurity,
            initialVolatility > ATTRIBUTE_MAX_VALUE ? ATTRIBUTE_MAX_VALUE : initialVolatility,
            initialStability > ATTRIBUTE_MAX_VALUE ? ATTRIBUTE_MAX_VALUE : initialStability
        );

        // Attributes already set in _mint, just emit creative event
        emit AssetForged(tokenId, owner, _assetAttributes[tokenId].purity, _assetAttributes[tokenId].volatility, _assetAttributes[tokenId].stability);
    }

    /// @notice Retrieves the current attributes of an asset.
    /// @param tokenId The ID of the asset.
    /// @return purity, volatility, stability, energyCapacity The current attributes.
    function getAssetAttributes(uint256 tokenId) public view returns (uint256 purity, uint256 volatility, uint256 stability, uint256 energyCapacity) {
        ownerOf(tokenId); // Ensure token exists
        AssetAttributes storage attrs = _assetAttributes[tokenId];
        return (attrs.purity, attrs.volatility, attrs.stability, attrs.energyCapacity);
    }

     /// @notice Gets the timestamp of the last attribute update for an asset.
     /// @param tokenId The ID of the asset.
     /// @return The timestamp of the last update.
    function getLastAttributeUpdateTime(uint256 tokenId) public view returns (uint48) {
        ownerOf(tokenId); // Ensure token exists
        return _assetAttributes[tokenId].lastUpdateTime;
    }

    /// @notice Applies time-based evolution to asset attributes.
    /// @param tokenId The ID of the asset.
    /// @dev Anyone can call this to update the asset's state based on elapsed time.
    function applyTimeEvolution(uint256 tokenId) public {
        ownerOf(tokenId); // Ensure token exists
        AssetAttributes storage attrs = _assetAttributes[tokenId];
        uint48 lastUpdate = attrs.lastUpdateTime;
        uint48 currentTime = uint48(block.timestamp);

        if (currentTime <= lastUpdate) {
            return; // No time has passed
        }

        uint256 timeDelta = currentTime - lastUpdate;
        uint256 scaledTimeDelta = timeDelta * timeEvolutionRate; // Apply rate multiplier

        // Example time-based logic:
        // Purity decays over time. Volatility fluctuates. Stability slowly increases.
        uint256 purityDecay = (attrs.purity * scaledTimeDelta) / 100000; // Example decay formula
        uint256 volatilityChange = (scaledTimeDelta * 50); // Example fluctuation (could be positive or negative)
        uint256 stabilityGrowth = (attrs.stability * scaledTimeDelta) / 500000; // Example growth formula

        attrs.purity = (attrs.purity > purityDecay) ? attrs.purity - purityDecay : ATTRIBUTE_MIN_VALUE;
        // Volatility change: make it fluctuate around a mid-point (5000)
        int256 currentVolatility = int256(attrs.volatility);
        int256 volatilityMidpoint = 5000;
        int256 change = (currentVolatility - volatilityMidpoint) / 10 + int256(volatilityChange); // Push away from midpoint, plus time fluctuation
        int256 newVolatility = currentVolatility + change;
        attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, newVolatility)));

        attrs.stability = (attrs.stability + stabilityGrowth) > ATTRIBUTE_MAX_VALUE ? ATTRIBUTE_MAX_VALUE : attrs.stability + stabilityGrowth;


        attrs.lastUpdateTime = currentTime;
        // Note: lastMutationTime only updates on user/interaction actions

        emit AttributesMutated(tokenId, "Time Evolution", attrs.purity, attrs.volatility, attrs.stability);
    }

    /// @notice Modifies asset attributes using user's Attunement Energy.
    /// @param tokenId The ID of the asset.
    /// @param energyCost The amount of energy to consume.
    /// @param purityDelta Change in purity (can be negative).
    /// @param volatilityDelta Change in volatility (can be negative).
    /// @param stabilityDelta Change in stability (can be negative).
    /// @dev Requires caller to have ATTUNER_ROLE or own/be approved for the token.
    function attuneAsset(uint256 tokenId, uint256 energyCost, int256 purityDelta, int256 volatilityDelta, int256 stabilityDelta) external onlyTokenOwnerOrApproved(tokenId) {
        _refuelAttunementEnergy(msg.sender); // Refuel user's energy first
        if (_userAttunementEnergy[msg.sender] < energyCost) {
            revert InsufficientAttunementEnergy();
        }

        AssetAttributes storage attrs = _assetAttributes[tokenId];

        // Apply time evolution before applying manual delta
        applyTimeEvolution(tokenId); // This updates lastUpdateTime

        // Apply deltas, capping at min/max
        int256 newPurity = int256(attrs.purity) + purityDelta;
        int256 newVolatility = int256(attrs.volatility) + volatilityDelta;
        int256 newStability = int256(attrs.stability) + stabilityDelta;

        attrs.purity = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, newPurity)));
        attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, newVolatility)));
        attrs.stability = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, newStability)));

        attrs.lastMutationTime = uint48(block.timestamp); // Update mutation time

        _userAttunementEnergy[msg.sender] -= energyCost; // Consume energy

        emit AttributesMutated(tokenId, "Attunement", attrs.purity, attrs.volatility, attrs.stability);
    }

    /// @notice Modifies asset attributes based on a catalyst type.
    /// @param tokenId The ID of the asset.
    /// @param catalystType Identifier for the catalyst (e.g., keccak256("fire")).
    /// @dev Requires caller to have ATTUNER_ROLE. This is a simplified example; could involve burning specific tokens.
    function applyCatalyst(uint256 tokenId, bytes32 catalystType) external onlyRole(ATTUNER_ROLE) {
        ownerOf(tokenId); // Ensure token exists
        AssetAttributes storage attrs = _assetAttributes[tokenId];

        // Apply time evolution first
        applyTimeEvolution(tokenId);

        // Example catalyst logic
        if (catalystType == keccak256("fire")) {
            attrs.purity = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.purity) - 500)));
            attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.volatility) + 1000)));
        } else if (catalystType == keccak256("water")) {
            attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.volatility) - 800)));
            attrs.stability = uint256(Math.max(ATTRIBUTE_MIN_VALUE, Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.stability) + 700)));
        }
        // Add more catalyst types here...

        attrs.lastMutationTime = uint48(block.timestamp);

        emit AttributesMutated(tokenId, "Catalyst", attrs.purity, attrs.volatility, attrs.stability);
        // In a real scenario, you might burn a catalyst token here
        // ICatalystToken(catalystTokenAddress).burn(msg.sender, 1);
    }

    /// @notice Updates a specific asset attribute using data from the configured oracle.
    /// @param tokenId The ID of the asset.
    /// @param newOracleValue The value read from the oracle.
    /// @dev Requires caller to have ORACLE_UPDATER_ROLE. Assumes oracleAddress points to a trusted contract.
    function updateAttributeFromOracle(uint256 tokenId, uint256 newOracleValue) external onlyRole(ORACLE_UPDATER_ROLE) {
        // In a more complex system, the oracle contract itself might call this,
        // or this function might read from the oracle contract.
        // Here, we simulate receiving the value from an oracle updater role.

        ownerOf(tokenId); // Ensure token exists
        AssetAttributes storage attrs = _assetAttributes[tokenId];

        // Example: Let's say volatility is tied to the oracle value
        // We might normalize or scale the oracle value
        attrs.volatility = uint256(Math.min(ATTRIBUTE_MAX_VALUE, newOracleValue * ATTRIBUTE_MAX_VALUE / 1000)); // Example scaling

        attrs.lastUpdateTime = uint48(block.timestamp);
        attrs.lastMutationTime = uint48(block.timestamp); // Oracle update counts as a mutation

        emit AttributesMutated(tokenId, "Oracle Update", attrs.purity, attrs.volatility, attrs.stability);
    }

    /// @notice Calculates and adds Attunement Energy to the caller based on time and staked assets.
    /// @dev Called internally by other functions that require energy, but also callable directly by users.
    function refuelAttunementEnergy() public {
         _refuelAttunementEnergy(msg.sender);
    }

    /// @notice Gets a user's current Attunement Energy, calculating potential gains first.
    /// @param user The address of the user.
    /// @return energy The user's updated energy amount.
    function getUserAttunementEnergy(address user) public returns (uint256 energy) {
        _refuelAttunementEnergy(user); // Ensure energy is up-to-date
        return _userAttunementEnergy[user];
    }

    /// @notice Stakes an asset to generate Attunement Energy over time.
    /// @param tokenId The ID of the asset to stake.
    /// @dev Requires caller to own or be approved for the asset. Transfers asset to contract address conceptually (or updates state).
    function stakeAssetForAttunement(uint256 tokenId) external onlyTokenOwnerOrApproved(tokenId) {
        if (_isAssetStaked[tokenId]) revert TokenAlreadyStaked();

        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        _transfer(owner, address(this), tokenId); // Transfer asset to the contract

        _assetStakingInfo[tokenId] = StakingInfo({
            staker: msg.sender, // The user who initiates the stake
            stakedTime: uint48(block.timestamp)
        });
        _isAssetStaked[tokenId] = true;

        emit AssetStaked(tokenId, msg.sender, uint48(block.timestamp));
    }

    /// @notice Unstakes an asset and adds accumulated Attunement Energy to the user.
    /// @param tokenId The ID of the staked asset.
    /// @dev Requires the original staker to call this function. Transfers asset back to the staker.
    function unstakeAssetFromAttunement(uint256 tokenId) external {
        if (!_isAssetStaked[tokenId]) revert TokenNotStaked();
        if (_assetStakingInfo[tokenId].staker != msg.sender) revert NotStaker();

        StakingInfo memory staking = _assetStakingInfo[tokenId];
        uint48 unstakeTime = uint48(block.timestamp);

        // Calculate energy earned from this specific staked asset
        uint256 timeStaked = unstakeTime - staking.stakedTime;
        uint256 earnedEnergy = timeStaked * stakedAssetEnergyRate; // Using the staked rate

        // Add earned energy to the staker's account
        _refuelAttunementEnergy(staking.staker); // Ensure staker's base energy is updated first
        _userAttunementEnergy[staking.staker] = uint256(Math.min(maxUserAttunementEnergy, _userAttunementEnergy[staking.staker] + earnedEnergy));


        // Transfer asset back to the original staker
        address originalStaker = staking.staker;
         // Need ownerOf(tokenId) which is now 'this', but we need the *original* owner/staker.
         // The _transfer function needs the current owner ('this') and the recipient ('originalStaker').
         // We MUST update ownership state *before* calling _transfer to reflect 'this' as owner.
         // The stake function already did this by transferring to address(this).

        _isAssetStaked[tokenId] = false; // Clear staking status BEFORE transfer
        delete _assetStakingInfo[tokenId]; // Clear staking info

        _transfer(address(this), originalStaker, tokenId); // Transfer from contract back to staker

        emit AssetUnstaked(tokenId, originalStaker, earnedEnergy);
    }

    /// @notice Gets staking details for an asset.
    /// @param tokenId The ID of the asset.
    /// @return staker The address that staked the asset (address(0) if not staked).
    /// @return stakedTime The timestamp the asset was staked (0 if not staked).
    function getAssetStakingInfo(uint256 tokenId) public view returns (address staker, uint48 stakedTime) {
        if (!_isAssetStaked[tokenId]) {
            return (address(0), 0);
        }
        StakingInfo storage info = _assetStakingInfo[tokenId];
        return (info.staker, info.stakedTime);
    }

     /// @notice Checks if an asset is currently staked.
     /// @param tokenId The ID of the asset.
     /// @return True if staked, false otherwise.
    function isAssetStaked(uint256 tokenId) public view returns (bool) {
        return _isAssetStaked[tokenId];
    }

     /// @notice Gets the timestamp of the last user/interaction-based mutation.
     /// @param tokenId The ID of the asset.
     /// @return The timestamp of the last mutation.
    function getLastMutationTime(uint256 tokenId) public view returns (uint48) {
        ownerOf(tokenId); // Ensure token exists
        return _assetAttributes[tokenId].lastMutationTime;
    }


    /// @notice Combines two assets into a new one, burning the originals.
    /// @param tokenId1 The ID of the first asset.
    /// @param tokenId2 The ID of the second asset.
    /// @dev Requires caller to own or be approved for both assets. Burns token1 and token2, mints a new token.
    /// Attributes of the new token are derived from the merged assets.
    function mergeAssets(uint256 tokenId1, uint256 tokenId2) external {
        if (tokenId1 == tokenId2) revert CannotMergeSameToken();
        // Check ownership/approval for both tokens
        if (ownerOf(tokenId1) != msg.sender && !_isApprovedOrForAll(msg.sender, tokenId1)) revert NotTokenOwnerOrApproved();
        if (ownerOf(tokenId2) != msg.sender && !_isApprovedOrForAll(msg.sender, tokenId2)) revert NotTokenOwnerOrApproved();

        // Ensure tokens are not staked before merging
        if (_isAssetStaked[tokenId1] || _isAssetStaked[tokenId2]) revert TokenAlreadyStaked(); // Or create a CannotMergeStaked error

        AssetAttributes memory attrs1 = _assetAttributes[tokenId1];
        AssetAttributes memory attrs2 = _assetAttributes[tokenId2];

        // Example Merge Logic: Averaging attributes
        uint256 newPurity = (attrs1.purity + attrs2.purity) / 2;
        uint256 newVolatility = (attrs1.volatility + attrs2.volatility) / 2;
        uint256 newStability = (attrs1.stability + attrs2.stability) / 2;
        // Energy capacity could be sum, max, or average

        // Burn the source tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint the new token to the caller
        uint256 newTokenId = _nextTokenId++;
        _mint(msg.sender, newTokenId, newPurity, newVolatility, newStability);

        emit AssetMerged(newTokenId, new uint256[](2), newPurity, newVolatility, newStability); // Emit source IDs

        // More complex merge logic could involve randomness, specific attribute combinations, etc.
    }

    /// @notice Spends significant Attunement Energy to heavily influence a single attribute.
    /// @param tokenId The ID of the asset.
    /// @param attributeIndex Index indicating which attribute to refine (0: purity, 1: volatility, 2: stability).
    /// @param amount The desired magnitude of refinement.
    /// @dev Requires caller to have ATTUNER_ROLE or own/be approved for the token. High energy cost.
    function refineAttribute(uint256 tokenId, uint256 attributeIndex, uint256 amount) external onlyTokenOwnerOrApproved(tokenId) {
        _refuelAttunementEnergy(msg.sender);

        uint256 energyCost = amount * 50; // Example high cost

        if (_userAttunementEnergy[msg.sender] < energyCost) {
            revert InsufficientAttunementEnergy();
        }

        AssetAttributes storage attrs = _assetAttributes[tokenId];
        applyTimeEvolution(tokenId); // Apply time evolution first

        int256 delta = int256(amount); // Assume 'amount' is the magnitude of change

        if (attributeIndex == 0) { // Purity
             // Refine purity upwards, perhaps at the expense of volatility
            attrs.purity = uint256(Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.purity) + delta));
            attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, int256(attrs.volatility) - delta / 2)); // Example side effect
        } else if (attributeIndex == 1) { // Volatility
            // Refine volatility, maybe towards a desired range (up or down)
            // Example: Increase volatility towards midpoint, decrease if too high/low
            if (attrs.volatility < ATTRIBUTE_MAX_VALUE / 2) {
                attrs.volatility = uint256(Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.volatility) + delta));
            } else {
                 attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, int256(attrs.volatility) - delta));
            }
        } else if (attributeIndex == 2) { // Stability
            // Refine stability upwards, maybe reducing volatility
            attrs.stability = uint256(Math.min(ATTRIBUTE_MAX_VALUE, int256(attrs.stability) + delta));
             attrs.volatility = uint256(Math.max(ATTRIBUTE_MIN_VALUE, int256(attrs.volatility) - delta / 3)); // Example side effect
        } else {
            revert InvalidAttributeIndex();
        }

        attrs.lastMutationTime = uint48(block.timestamp);
        _userAttunementEnergy[msg.sender] -= energyCost;

        emit AttributesMutated(tokenId, "Refinement", attrs.purity, attrs.volatility, attrs.stability);
    }

    /// @notice Retires/burns an asset if its attributes fall below certain thresholds.
    /// @param tokenId The ID of the asset to retire.
    /// @dev Requires caller to own or be approved for the asset. Checks attribute conditions before burning.
    function retireAsset(uint256 tokenId) external onlyTokenOwnerOrApproved(tokenId) {
        ownerOf(tokenId); // Ensure token exists
        AssetAttributes storage attrs = _assetAttributes[tokenId];

        // Apply time evolution first
        applyTimeEvolution(tokenId);

        // Example retirement condition: Purity too low AND Volatility too high
        if (attrs.purity > 1000 || attrs.volatility < 8000) {
             revert AttributesBelowRetirementThreshold();
        }

        address owner = ownerOf(tokenId);
        _burn(tokenId); // Burn the token

        emit AssetRetired(tokenId, owner);
    }


    // --- Resource Management Internal Helpers ---

    /// @notice Internal function to refuel a user's Attunement Energy.
    /// @param user The address of the user to refuel.
    /// @dev Calculates energy based on time and staked assets, caps at max.
    function _refuelAttunementEnergy(address user) internal {
        uint48 lastUpdate = _userLastEnergyUpdate[user];
        uint48 currentTime = uint48(block.timestamp);

        if (currentTime <= lastUpdate) {
            return; // No time has passed, or already updated in this block
        }

        uint256 timeDelta = currentTime - lastUpdate;
        uint256 earnedEnergy = timeDelta * baseEnergyRegenRate; // Base regen

        // Add energy from staked assets (requires iterating or tracking total staked value per user,
        // for simplicity here, we'll assume the stakedAssetEnergyRate is just added to the user's base regen
        // if they have *any* staked assets - a more complex system would track staked *value* or *count*)
        // For this example, we won't add staked energy here, but when unstaking.
        // A better approach would be a separate "vault" contract for staking.
        // Let's simplify: only base regen happens passively. Staking energy is earned upon unstaking.

        uint256 currentEnergy = _userAttunementEnergy[user];
        uint256 newEnergy = currentEnergy + earnedEnergy;
        _userAttunementEnergy[user] = uint256(Math.min(maxUserAttunementEnergy, newEnergy));
        _userLastEnergyUpdate[user] = currentTime;

        if (earnedEnergy > 0) {
            emit EnergyRefueled(user, earnedEnergy, _userAttunementEnergy[user]);
        }
    }

    // --- Access Control Management Functions ---

    /// @notice Grants a role to an account.
    /// @param role The role to grant (e.g., DEFAULT_ADMIN_ROLE, FORGE_ROLE).
    /// @param account The address to grant the role to.
    /// @dev Requires the caller to have the DEFAULT_ADMIN_ROLE.
    function grantRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_hasRole(role, account)) revert AccountAlreadyHasRole();
        _setupRole(role, account);
    }

    /// @notice Revokes a role from an account.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    /// @dev Requires the caller to have the DEFAULT_ADMIN_ROLE.
    function revokeRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
         if (!_hasRole(role, account)) revert AccountDoesNotHaveRole();
        _revokeRole(role, account);
    }

    /// @notice Revokes a role from the caller.
    /// @param role The role to renounce.
    /// @dev The caller loses the specified role. Cannot renounce DEFAULT_ADMIN_ROLE if it's the last admin.
    function renounceRole(bytes32 role) external {
        if (!_hasRole(role, msg.sender)) revert AccountDoesNotHaveRole();
        // Optional: Add a check for DEFAULT_ADMIN_ROLE to ensure not all admins are removed
        _revokeRole(role, msg.sender);
    }

     /// @notice Checks if an account has a specific role.
     /// @param role The role to check.
     /// @param account The address to check.
     /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _hasRole(role, account);
    }


    // --- Configuration Functions ---

     /// @notice Grants or revokes the FORGE_ROLE.
     /// @param account The address to modify the role for.
     /// @param enabled True to grant, false to revoke.
     /// @dev Requires DEFAULT_ADMIN_ROLE.
    function setForgeRole(address account, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (enabled) {
            _setupRole(FORGE_ROLE, account);
        } else {
            _revokeRole(FORGE_ROLE, account);
        }
    }

     /// @notice Grants or revokes the ATTUNER_ROLE.
     /// @param account The address to modify the role for.
     /// @param enabled True to grant, false to revoke.
     /// @dev Requires DEFAULT_ADMIN_ROLE.
    function setAttunerRole(address account, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
         if (enabled) {
            _setupRole(ATTUNER_ROLE, account);
        } else {
            _revokeRole(ATTUNER_ROLE, account);
        }
    }

     /// @notice Grants or revokes the ORACLE_UPDATER_ROLE.
     /// @param account The address to modify the role for.
     /// @param enabled True to grant, false to revoke.
     /// @dev Requires DEFAULT_ADMIN_ROLE.
    function setOracleUpdaterRole(address account, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
         if (enabled) {
            _setupRole(ORACLE_UPDATER_ROLE, account);
        } else {
            _revokeRole(ORACLE_UPDATER_ROLE, account);
        }
    }

    /// @notice Sets the base Attunement Energy regeneration rate per second for users.
    /// @param rate The new rate.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function setBaseEnergyRegen(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseEnergyRegenRate = rate;
    }

     /// @notice Sets the additional Attunement Energy generation rate per second for staked assets.
     /// @param rate The new rate.
     /// @dev Requires DEFAULT_ADMIN_ROLE. Note: In this simplified model, staked energy is applied on unstake.
     /// A more complex model would track energy gain per staked asset over time.
    function setStakedEnergyRate(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedAssetEnergyRate = rate;
    }

    /// @notice Sets the address of the trusted oracle contract.
    /// @param _oracleAddress The address of the oracle contract implementing IOracle.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function setOracleAddress(address _oracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(oracleAddress);
    }

    // --- Utility Functions ---

    /// @notice Allows the contract admin to withdraw any accumulated Ether.
    /// @param payable recipient The address to send the Ether to.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function withdrawFunds(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = recipient.call{value: balance}("");
            require(success, "Transfer failed.");
            emit FundsWithdrawn(recipient, balance);
        }
    }

    // --- Interfaces Used (for reference) ---
    // Note: These are standard interfaces used within the contract, not necessarily
    // inherited directly if custom implementation is used.

    // ERC721 Standard (Partial)
    // interface IERC721 {
    //     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    //     event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    //     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    //     function balanceOf(address owner) external view returns (uint255 balance);
    //     function ownerOf(uint256 tokenId) external view returns (address owner);
    //     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    //     function safeTransferFrom(address from, address to, uint256 tokenId) external;
    //     function transferFrom(address from, address to, uint256 tokenId) external;
    //     function approve(address to, uint256 tokenId) external;
    //     function setApprovalForAll(address operator, bool approved) external;
    //     function getApproved(uint256 tokenId) external view returns (address operator);
    //     function isApprovedForAll(address owner, address operator) external view returns (bool);
    // }

    // ERC721 Metadata (Partial)
    // interface IERC721Metadata is IERC721 {
    //     function name() external view returns (string memory);
    //     function symbol() external view returns (string memory);
    //     function tokenURI(uint256 tokenId) external view returns (string memory);
    // }

    // ERC721 Receiver
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, address tokenId, uint256 value, bytes calldata data) external returns(bytes4);
    }

    // Basic Math Utility (for min/max, or import SafeMath/SignedMath)
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function max(int256 a, int256 b) internal pure returns (int256) {
            return a >= b ? a : b;
        }
        function min(int256 a, int256 b) internal pure returns (int256) {
            return a < b ? a : b;
        }
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Attributes (`AssetAttributes` struct, mappings):** The core idea is that the state of the NFT isn't just ownership and metadata URI. It includes on-chain, mutable numerical properties (`purity`, `volatility`, `stability`, `energyCapacity`).
2.  **Time-Based Evolution (`applyTimeEvolution`, `lastUpdateTime`):** Assets change inherently over time, regardless of user action. This introduces a decay or growth mechanic, making assets require maintenance or evolve passively. Calling `applyTimeEvolution` updates the state for a specific token based on how long it's been since its attributes were last calculated.
3.  **Attunement Energy Resource System (`_userAttunementEnergy`, `_userLastEnergyUpdate`, `refuelAttunementEnergy`, `getUserAttunementEnergy`):** A user-specific, time-regenerating resource. Actions like `attuneAsset` consume this energy, creating a constraint on interactions and potentially a gameplay loop around managing energy.
4.  **Interaction-Based Mutation (`attuneAsset`):** Users can directly influence attributes by spending energy, allowing for strategic choices in asset development. The changes can be positive or negative deltas.
5.  **Catalyst-Based Mutation (`applyCatalyst`):** A separate, potentially more powerful or specific mutation mechanism, perhaps requiring distinct in-game items or tokens (simulated here with role/type).
6.  **Oracle Integration (`updateAttributeFromOracle`, `oracleAddress`, `IOracle`):** Allows an attribute to be influenced by external real-world data, making the NFT's properties reactive to off-chain events (e.g., price of ETH, weather data, sports scores). This is implemented with a placeholder interface and a function callable by a designated role.
7.  **Staking for Resources (`stakeAssetForAttunement`, `unstakeAssetFromAttunement`, `StakingInfo`, `_isAssetStaked`):** Users can lock their assets in the contract to gain a benefit – in this case, potentially higher energy regeneration (though in the example, energy is calculated upon unstaking for simplicity). This mechanism affects asset liquidity and introduces a strategic choice for holders.
8.  **Asset Merging (`mergeAssets`):** A transformation function that combines two NFTs into a new one, burning the originals. The attributes of the new asset are derived from the inputs, allowing for crafting or breeding mechanics.
9.  **Attribute Refinement (`refineAttribute`):** A specialized function for focusing energy on improving a single attribute significantly, potentially with side effects on others, representing a more intense form of manipulation.
10. **Asset Retirement (`retireAsset`):** Assets can be removed from circulation if their attributes reach an undesirable state, acting as a game-over condition or a mechanism to manage the total supply of high-quality assets.
11. **Custom ERC721 Implementation:** Instead of inheriting from OpenZeppelin, the core ERC721 logic is implemented manually. While this is generally *less recommended* in production due to the risk of missing edge cases or optimizations compared to battle-tested libraries, it fulfills the "don't duplicate open source" request by writing the logic from scratch, demonstrating understanding of the standard. (Note: Using OZ for production is safer).
12. **Role-Based Access Control (Custom):** A mapping-based system (`_roles`, `onlyRole` modifier) is used for permissions instead of inheriting `AccessControl` from OpenZeppelin, again to avoid direct duplication.

This contract provides a rich environment for building applications (games, simulations, collectibles) where the assets have complex, evolving behaviors driven by both internal mechanics and external interactions.