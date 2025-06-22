Okay, here is a Solidity smart contract implementing a "Generative Asset Protocol". This contract combines aspects of NFTs (ERC721), dynamic state based on interactions and time, parameterized on-chain logic, and a custom role-based access control system. It aims to be a bit more complex than a standard static NFT or simple game contract.

**Concept:** The contract manages unique digital entities (Assets) that possess dynamic traits and properties. These properties can change over time and through various on-chain interactions like 'evolving', 'mutating', 'feeding', 'challenging', and even 'breeding'. The behavior of these interactions is controlled by adjustable parameters.

**Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic On-Chain State:** Assets' traits and stats are not static metadata but stored and manipulated directly on-chain.
2.  **Parameterized Behavior:** Key game mechanics (costs, success rates, stat changes) are controlled by contract parameters that can be adjusted by specific roles.
3.  **Time-Based Evolution/Decay:** Asset properties can change based on how much time has passed since their last interaction or creation.
4.  **On-chain Pseudo-Randomness:** Used for mutations, discoveries, and challenge outcomes (with a strong note about its limitations).
5.  **Role-Based Access Control:** A custom system beyond `Ownable` for managing different permissions (e.g., Minter, ParameterManager, GlobalEvoker).
6.  **Generative/Evolving Logic:** Multiple distinct functions (`evolve`, `mutate`, `feed`, `challenge`, `breed`) that deterministically (or pseudo-randomly) alter asset state based on current state and parameters.
7.  **Global Evolution Event:** A privileged function to trigger system-wide changes based on global parameters.
8.  **Trait Discovery:** A mechanism to potentially add entirely new trait types to an asset.
9.  **Breeding Logic:** A complex interaction creating new assets by combining aspects of existing ones.
10. **Pausable System:** A standard safety mechanism, but crucial for complex protocols.
11. **ERC-165 Support:** Standard interface detection.
12. **Basic ERC-721 Implementation:** Core NFT functionality integrated with dynamic state.
13. **Reentrancy Guard:** Protection for withdrawal functions.
14. **Configurable Traits:** Ability to define allowed trait types.
15. **Event-Driven State Changes:** Comprehensive events emitted for all significant state mutations.

---

**Outline and Function Summary**

**I. Contract Setup and Imports**
    *   Imports necessary OpenZeppelin contracts (ERC721, Context, Ownable, ReentrancyGuard, Pausable).
    *   Define roles using constants.

**II. State Variables**
    *   ERC721 standard variables (`_name`, `_symbol`, `_tokenCounter`, `_owners`, `_tokenApprovals`, `_operatorApprovals`).
    *   Token-specific data (`_assetProperties`, `_numericalTraits`, `_stringTraits`).
    *   Global parameters (`_globalParams`).
    *   Role management (`_roles`).
    *   Allowed trait types (`_allowedNumericalTraitTypes`, `_allowedStringTraitTypes`).

**III. Structs**
    *   `AssetProperties`: Basic info per token (creation time, generation, last interaction time, etc.).
    *   `GlobalParams`: Stores parameters governing interactions (costs, rates, cooldowns, etc.).

**IV. Events**
    *   Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`).
    *   Protocol-specific events (`AssetMinted`, `AssetBurned`, `AssetEvolved`, `AssetMutated`, `AssetFed`, `AssetChallenged`, `AssetBred`, `TraitChanged`, `TraitDiscovered`, `ParameterSet`, `RoleGranted`, `RoleRevoked`, `Paused`, `Unpaused`).

**V. Modifiers**
    *   `onlyRole(bytes32 role)`: Restricts function access to addresses with the specified role.

**VI. Constructor**
    *   Initializes the ERC721 contract, sets up initial roles (Owner gets all roles), and sets initial global parameters.

**VII. ERC721 Core Functions**
    *   `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of `tokenId`.
    *   `approve(address to, uint256 tokenId)`: Approves `to` to spend `tokenId`.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
    *   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer variant.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer variant with data.

**VIII. ERC165 Interface Support**
    *   `supportsInterface(bytes4 interfaceId)`: Reports which interfaces the contract supports.

**IX. Internal Helpers**
    *   `_mint(address to, uint256 tokenId)`: Internal function to mint a token.
    *   `_burn(uint256 tokenId)`: Internal function to burn a token.
    *   `_baseURI()`: Returns the base URI for token metadata (placeholder).
    *   `_exists(uint256 tokenId)`: Checks if a token exists.
    *   `_requireOwnedBy(uint256 tokenId, address account)`: Checks if `account` owns `tokenId`.
    *   `_isApprovedOrOwner(address spender, uint256 tokenId)`: Checks if `spender` is approved or owner.
    *   `_updateAssetLastInteraction(uint256 tokenId)`: Updates `lastInteractionTime`.
    *   `_calculatePseudoRandom(uint256 seed)`: Simple pseudo-random number generator (with limitations warning).
    *   `_grantRole(bytes32 role, address account)`: Grants a role.
    *   `_revokeRole(bytes32 role, address account)`: Revokes a role.

**X. Core Asset Management (Public/External)**
    *   `publicMint(uint256 initialSeed)`: Mints a new asset, initializing properties based on parameters and seed. Costs ETH.
    *   `burnAsset(uint256 tokenId)`: Burns an asset (requires ownership or approval).
    *   `getTokenProperties(uint256 tokenId)`: Returns basic properties of an asset.
    *   `getTokenNumericalTrait(uint256 tokenId, string memory traitType)`: Returns a specific numerical trait value.
    *   `getTokenStringTrait(uint256 tokenId, string memory traitType)`: Returns a specific string trait value.
    *   `getTotalSupply()`: Returns the total number of assets minted.

**XI. Generative/Evolution Functions (Public/External)**
    *   `evolveAsset(uint256 tokenId)`: Attempts to evolve an asset. May change properties based on time, current stats, and global parameters. Costs ETH.
    *   `mutateAsset(uint256 tokenId, uint256 mutationSeed)`: Attempts to mutate a random trait of an asset. Success based on parameters and seed. Costs ETH.
    *   `feedAsset(uint256 tokenId, string memory numericalTraitType, uint256 amount)`: Increases a specific numerical trait. Costs ETH.
    *   `challengeAsset(uint256 tokenId, uint256 challengeSeed)`: Simulates a challenge. Outcome is pseudo-random and affects stats. Costs ETH.
    *   `breedAssets(uint256 parent1Id, uint256 parent2Id, uint256 breedingSeed)`: Creates a new asset inheriting traits from two parents. Requires owning both, costs ETH.
    *   `decayStats(uint256 tokenId)`: Manually triggers potential decay of stats based on time since last interaction. (Could also be integrated into other functions or require external keepers).
    *   `triggerGlobalEvolution(uint256 globalEvolutionSeed)`: Role-restricted function that can apply global changes (e.g., universal stat decay/growth, unlock new traits) to *all* assets.
    *   `discoverNewTrait(uint256 tokenId, uint256 discoverySeed)`: Attempts to add a *new* allowed trait type to an asset that it didn't previously have. Pseudo-random chance. Costs ETH.

**XII. Parameter Management (Role-Restricted)**
    *   `setGlobalParams(uint256 newMintCost, uint256 newEvolveCost, uint256 newMutateCost, uint256 newFeedCost, uint256 newChallengeCost, uint256 newBreedingCost, uint256 newDiscoveryCost, uint256 newEvolveCooldown, uint256 newDecayRatePerDay, uint256 newMutationSuccessRate, uint256 newBreedingCooldown)`: Sets multiple global parameters.
    *   `addAllowedNumericalTraitType(string memory traitType)`: Adds a trait type that can be used for numerical traits.
    *   `removeAllowedNumericalTraitType(string memory traitType)`: Removes an allowed numerical trait type.
    *   `addAllowedStringTraitType(string memory traitType)`: Adds a trait type for string traits.
    *   `removeAllowedStringTraitType(string memory traitType)`: Removes an allowed string trait type.
    *   `setBaseNumericalTrait(string memory traitType, uint256 baseValue)`: Sets the initial value for a numerical trait type on new mints. (Needs storage, let's add a mapping `_baseNumericalTraits`).
    *   `setBaseStringTrait(string memory traitType, string memory baseValue)`: Sets the initial value for a string trait type on new mints. (Needs storage, let's add a mapping `_baseStringTraits`).

**XIII. Role Management (Owner-Only)**
    *   `grantRole(bytes32 role, address account)`: Grants a specific role to an address.
    *   `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address.
    *   `hasRole(bytes32 role, address account)`: Checks if an address has a role.

**XIV. Pausable System**
    *   `pause()`: Pauses transfers and most interactions (Role-restricted).
    *   `unpause()`: Unpauses the contract (Role-restricted).

**XV. Withdrawal Functions (Role-Restricted, Reentrancy Guarded)**
    *   `withdrawETH(address payable to, uint256 amount)`: Withdraws accumulated ETH.
    *   `withdrawToken(address tokenAddress, address to, uint256 amount)`: Withdraws other ERC20 tokens held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial role setup, will extend with custom roles
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// I. Contract Setup and Imports
// II. State Variables
// III. Structs
// IV. Events
// V. Modifiers
// VI. Constructor
// VII. ERC721 Core Functions (8 + 2 SafeTransfer variants)
//     balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2)
// VIII. ERC165 Interface Support (1 function)
//      supportsInterface
// IX. Internal Helpers
//      _mint, _burn, _baseURI, _exists, _requireOwnedBy, _isApprovedOrOwner, _updateAssetLastInteraction, _calculatePseudoRandom, _grantRole, _revokeRole
// X. Core Asset Management (Public/External - 6 functions)
//     publicMint, burnAsset, getTokenProperties, getTokenNumericalTrait, getTokenStringTrait, getTotalSupply
// XI. Generative/Evolution Functions (Public/External - 8 functions)
//     evolveAsset, mutateAsset, feedAsset, challengeAsset, breedAssets, decayStats, triggerGlobalEvolution, discoverNewTrait
// XII. Parameter Management (Role-Restricted - 7 functions)
//      setGlobalParams, addAllowedNumericalTraitType, removeAllowedNumericalTraitType, addAllowedStringTraitType, removeAllowedStringTraitType, setBaseNumericalTrait, setBaseStringTrait
// XIII. Role Management (Owner-Only - 3 functions)
//       grantRole, revokeRole, hasRole
// XIV. Pausable System (Role-Restricted - 2 functions)
//       pause, unpause
// XV. Withdrawal Functions (Role-Restricted, Reentrancy Guarded - 2 functions)
//      withdrawETH, withdrawToken
// Total Public/External Functions: 8 (ERC721) + 1 (ERC165) + 6 (Asset Mgmt) + 8 (Generative) + 7 (Params) + 3 (Roles) + 2 (Pausable) + 2 (Withdraw) = 37 functions.

contract GenerativeAssetProtocol is ERC721, ERC165, Ownable, ReentrancyGuard, Pausable {

    // --- II. State Variables ---

    // ERC721 Standard storage (simplified, relying on internal OZ implementation where possible)
    // We only explicitly store owner/approvals if necessary, typically OZ handles this in mappings.
    // For this example, let's assume standard OZ ERC721 state variables are managed internally.
    uint256 private _tokenCounter; // Tracks the total number of tokens minted

    // Token-specific dynamic data
    struct AssetProperties {
        uint64 creationTime;      // When the asset was created
        uint32 generation;        // How many times it has 'evolved' or been 'bred'
        uint64 lastInteractionTime; // Last time a generative action (evolve, feed, etc.) happened
        uint256 parent1Id;        // For bred assets, parent 1
        uint256 parent2Id;        // For bred assets, parent 2
        // Add other core properties here if needed, e.g., 'energy', 'health', etc.
        // For simplicity, core stats are handled by numerical traits below.
    }
    mapping(uint256 => AssetProperties) private _assetProperties;

    // Dynamic Traits: Stored in mappings per token ID
    mapping(uint256 => mapping(string => uint256)) private _numericalTraits;
    mapping(uint256 => mapping(string => string)) private _stringTraits;

    // Global parameters governing interactions and mechanics
    struct GlobalParams {
        uint256 mintCost;           // Cost to public mint an asset
        uint256 evolveCost;         // Cost to evolve an asset
        uint256 mutateCost;         // Cost to mutate an asset
        uint256 feedCost;           // Cost to feed an asset
        uint256 challengeCost;      // Cost to challenge an asset
        uint256 breedingCost;       // Cost to breed assets
        uint256 discoveryCost;      // Cost to attempt trait discovery

        uint64 evolveCooldown;      // Time (seconds) required between evolve attempts
        uint64 breedingCooldown;    // Time (seconds) required between breeding attempts for a parent

        uint256 decayRatePerDay;    // Rate of numerical trait decay per day (percentage points)
        uint256 mutationSuccessRate; // Percentage chance of successful mutation
        uint256 breedingSuccessRate; // Percentage chance of successful breeding

        // Add other global parameters here as complexity grows
    }
    GlobalParams private _globalParams;

    // Base stats/traits for newly minted assets
    mapping(string => uint256) private _baseNumericalTraits;
    mapping(string => string) private _baseStringTraits;

    // Allowed trait types
    mapping(string => bool) private _allowedNumericalTraitTypes;
    mapping(string => bool) private _allowedStringTraitTypes;

    // Custom Role-Based Access Control (simple mapping approach)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PARAMETER_MANAGER_ROLE = keccak256("PARAMETER_MANAGER_ROLE");
    bytes32 public constant GLOBAL_EVOKER_ROLE = keccak256("GLOBAL_EVOKER_ROLE");

    mapping(bytes32 => mapping(address => bool)) private _roles;

    // --- IV. Events ---

    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint256 initialSeed, uint64 creationTime);
    event AssetBurned(uint256 indexed tokenId, address indexed owner);
    event AssetEvolved(uint256 indexed tokenId, uint32 newGeneration, uint64 lastInteractionTime);
    event AssetMutated(uint256 indexed tokenId, string indexed traitType, uint256 oldValueNum, uint256 newValueNum, string oldValueStr, string newValueStr); // Emits based on which trait type changed
    event AssetFed(uint256 indexed tokenId, string indexed traitType, uint256 amount, uint256 newTraitValue);
    event AssetChallenged(uint256 indexed tokenId, uint256 challengeSeed, bool success, string outcomeDescription);
    event AssetBred(uint256 indexed newTokenId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event TraitChanged(uint256 indexed tokenId, string indexed traitType, uint256 newValueNum, string newValueStr); // General event for trait updates
    event TraitDiscovered(uint256 indexed tokenId, string indexed traitType, bool isNumerical);
    event ParameterSet(string indexed paramName, uint256 indexed newValue); // Simple event for param changes
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // --- V. Modifiers ---

    modifier onlyRole(bytes32 role) {
        require(_roles[role][_msgSender()], "GenerativeAssetProtocol: missing role");
        _;
    }

    // --- VI. Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(_msgSender()) // Owner is initially the deployer
        Pausable()
    {
        _tokenCounter = 0; // Token IDs start from 1
        // Grant initial roles to the contract owner
        _roles[MINTER_ROLE][_msgSender()] = true;
        _roles[PARAMETER_MANAGER_ROLE][_msgSender()] = true;
        _roles[GLOBAL_EVOKER_ROLE][_msgSender()] = true;

        // Set initial global parameters (example values)
        _globalParams = GlobalParams({
            mintCost: 0.01 ether,
            evolveCost: 0.005 ether,
            mutateCost: 0.002 ether,
            feedCost: 0.001 ether,
            challengeCost: 0.003 ether,
            breedingCost: 0.02 ether,
            discoveryCost: 0.004 ether,
            evolveCooldown: 1 days,
            breedingCooldown: 7 days,
            decayRatePerDay: 5, // 5% decay per day for numerical traits
            mutationSuccessRate: 70, // 70% chance
            breedingSuccessRate: 80 // 80% chance
        });

        // Add some initial allowed trait types (example)
        _allowedNumericalTraitTypes["Strength"] = true;
        _allowedNumericalTraitTypes["Dexterity"] = true;
        _allowedNumericalTraitTypes["Stamina"] = true;
        _allowedNumericalTraitTypes["Intelligence"] = true;

        _allowedStringTraitTypes["Name"] = true;
        _allowedStringTraitTypes["Color"] = true;
        _allowedStringTraitTypes["Element"] = true;

        // Set some base traits (example)
        _baseNumericalTraits["Strength"] = 10;
        _baseNumericalTraits["Dexterity"] = 10;
        _baseNumericalTraits["Stamina"] = 10;
        _baseNumericalTraits["Intelligence"] = 10;

        _baseStringTraits["Name"] = "Genesis Entity";
        _baseStringTraits["Color"] = "Gray";
        _baseStringTraits["Element"] = "Neutral";

        // Emit initial role grants
        emit RoleGranted(MINTER_ROLE, _msgSender(), _msgSender());
        emit RoleGranted(PARAMETER_MANAGER_ROLE, _msgSender(), _msgSender());
        emit RoleGranted(GLOBAL_EVOKER_ROLE, _msgSender(), _msgSender());
    }

    // --- VII. ERC721 Core Functions ---
    // Inherited from OpenZeppelin ERC721.sol.
    // We override _update and _beforeTokenTransfer if we need custom logic there,
    // but for dynamic traits, we mainly interact with our custom state variables
    // in the generative/evolution functions.
    // standard functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom

    // --- VIII. ERC165 Interface Support ---
    // Inherited from OpenZeppelin ERC721.sol, which supports ERC721 and ERC165.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        // Additional interfaces could be supported here if needed
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- IX. Internal Helpers ---

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted"); // Should not happen with _tokenCounter

        _tokenCounter++; // Increment before assigning to ensure unique IDs starting from 1
        uint256 newTokenId = _tokenCounter; // Assign the next ID

        // Update internal OpenZeppelin state
        _owners[newTokenId] = to; // Directly update owner mapping as _safeMint uses it

        emit Transfer(address(0), to, newTokenId); // Standard ERC721 Transfer event
    }

    function _burn(uint256 tokenId) internal {
        address owner = ERC721.ownerOf(tokenId); // Use ERC721's ownerOf which checks existence
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        // Clear approvals
        _approve(address(0), tokenId);

        // Remove owner mapping
        delete _owners[tokenId];

        // Delete custom asset data
        delete _assetProperties[tokenId];
        delete _numericalTraits[tokenId];
        delete _stringTraits[tokenId];

        emit Transfer(owner, address(0), tokenId); // Standard ERC721 Transfer event
    }

    function _baseURI() internal view virtual override returns (string memory) {
        // Implement logic to return a base URI for metadata if needed
        // For dynamic traits, metadata would typically be generated off-chain via an API
        // that queries the on-chain state using getTokenProperties and trait functions.
        return ""; // Placeholder
    }

    // Overrides to hook into ERC721 transfer process if needed (optional)
    // For this contract, dynamic state changes happen via generative functions, not transfers.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
    //     super._afterTokenTransfer(from, to, tokenId, batchSize);
    // }

    // Helper to check if a token exists (uses OZ internal state)
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0); // OZ ERC721 internal existence check
    }

    // Helper to require ownership or approval
    function _requireOwnedBy(uint256 tokenId, address account) internal view {
        require(_isApprovedOrOwner(account, tokenId), "GenerativeAssetProtocol: caller is not owner or approved");
    }

    // Helper to check if spender is approved or owner
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ERC721.ownerOf(tokenId); // Use ERC721's ownerOf
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _updateAssetLastInteraction(uint256 tokenId) internal {
        _assetProperties[tokenId].lastInteractionTime = uint64(block.timestamp);
    }

    /**
     * @dev Simple pseudo-random number generator.
     * WARNING: This is not cryptographically secure and should NOT be used
     * for high-value decisions in a production environment where adversaries
     * can manipulate inputs or guess outcomes. For production, consider
     * Chainlink VRF or similar verifiable random functions.
     */
    function _calculatePseudoRandom(uint256 seed) internal view returns (uint256) {
        // Combine block data, transaction data, and a seed for (weak) randomness
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Use a recent, but finalized block hash
            block.timestamp,
            _msgSender(),
            tx.origin,
            tx.gasprice,
            seed // Incorporate user-provided seed
        )));
        return randomness;
    }

    // Internal role management - grants only allowed from accounts with specific roles
    function _grantRole(bytes32 role, address account) internal onlyRole(DEFAULT_ADMIN_ROLE) { // Using Ownable's DEFAULT_ADMIN_ROLE for granting/revoking
        require(account != address(0), "GenerativeAssetProtocol: account is the zero address");
        _roles[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal onlyRole(DEFAULT_ADMIN_ROLE) { // Using Ownable's DEFAULT_ADMIN_ROLE for granting/revoking
        require(account != address(0), "GenerativeAssetProtocol: account is the zero address");
        _roles[role][account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }

    // --- X. Core Asset Management (Public/External) ---

    /// @notice Mints a new asset. Requires ETH payment. Restricted by Pausable.
    /// @param initialSeed A seed provided by the minter influencing initial traits.
    function publicMint(uint256 initialSeed) external payable whenNotPaused returns (uint256) {
        require(msg.value >= _globalParams.mintCost, "GenerativeAssetProtocol: Insufficient ETH for mint");
        require(hasRole(MINTER_ROLE, _msgSender()), "GenerativeAssetProtocol: caller is not a minter");

        _tokenCounter++; // Increment first to get the next ID
        uint256 newTokenId = _tokenCounter; // The actual ID to mint

        // Check max supply if applicable (add a max supply parameter if needed)
        // require(newTokenId <= MAX_SUPPLY, "GenerativeAssetProtocol: Max supply reached");

        _mint(_msgSender(), newTokenId); // Mint the token

        // Initialize asset properties
        _assetProperties[newTokenId] = AssetProperties({
            creationTime: uint64(block.timestamp),
            generation: 0,
            lastInteractionTime: uint64(block.timestamp),
            parent1Id: 0, // Not bred
            parent2Id: 0  // Not bred
        });

        // Initialize traits based on base values and seed
        uint256 baseRandomness = _calculatePseudoRandom(initialSeed);
        uint256 index = 0; // Simple index for seed variation

        // Initialize numerical traits
        for (uint i = 0; i < 10; i++) { // Iterate up to 10 times to find allowed traits
            string memory traitType = "";
            // Simple way to get a trait type - needs improvement for large sets
            if (i == 0 && _allowedNumericalTraitTypes["Strength"]) traitType = "Strength";
            else if (i == 1 && _allowedNumericalTraitTypes["Dexterity"]) traitType = "Dexterity";
            else if (i == 2 && _allowedNumericalTraitTypes["Stamina"]) traitType = "Stamina";
            else if (i == 3 && _allowedNumericalTraitTypes["Intelligence"]) traitType = "Intelligence";
            // ... add more if needed, or use a stored array of trait keys

            if (bytes(traitType).length > 0) {
                 if (_allowedNumericalTraitTypes[traitType]) {
                    uint256 baseValue = _baseNumericalTraits[traitType];
                    // Add some randomness influence
                    uint256 randomInfluence = (_calculatePseudoRandom(baseRandomness + index) % (baseValue / 2 + 1)) - (baseValue / 4); // +/- 25% range example
                    int256 initialValue = int256(baseValue) + int256(randomInfluence);
                    _numericalTraits[newTokenId][traitType] = uint256(initialValue > 0 ? uint256(initialValue) : 0);
                    index++;
                    emit TraitChanged(newTokenId, traitType, _numericalTraits[newTokenId][traitType], "");
                }
            }
        }

        // Initialize string traits (simple base value assignment for now)
        for (uint i = 0; i < 10; i++) { // Iterate up to 10 times
            string memory traitType = "";
             if (i == 0 && _allowedStringTraitTypes["Name"]) traitType = "Name";
            else if (i == 1 && _allowedStringTraitTypes["Color"]) traitType = "Color";
            else if (i == 2 && _allowedStringTraitTypes["Element"]) traitType = "Element";
             // ... add more if needed

            if (bytes(traitType).length > 0) {
                if (_allowedStringTraitTypes[traitType]) {
                    _stringTraits[newTokenId][traitType] = _baseStringTraits[traitType];
                    emit TraitChanged(newTokenId, traitType, 0, _stringTraits[newTokenId][traitType]);
                }
            }
        }


        emit AssetMinted(newTokenId, _msgSender(), initialSeed, _assetProperties[newTokenId].creationTime);

        return newTokenId;
    }

    /// @notice Burns an existing asset. Requires ownership or approval. Restricted by Pausable.
    /// @param tokenId The ID of the asset to burn.
    function burnAsset(uint256 tokenId) external whenNotPaused {
        _requireOwnedBy(tokenId, _msgSender()); // Ensure caller can burn this token
        address owner = ERC721.ownerOf(tokenId); // Get owner before burning

        _burn(tokenId); // Burn the token and clear associated data

        emit AssetBurned(tokenId, owner);
    }

    /// @notice Gets the core properties of an asset.
    /// @param tokenId The ID of the asset.
    /// @return creationTime, generation, lastInteractionTime, parent1Id, parent2Id
    function getTokenProperties(uint256 tokenId) public view returns (uint64 creationTime, uint32 generation, uint64 lastInteractionTime, uint256 parent1Id, uint256 parent2Id) {
        require(_exists(tokenId), "GenerativeAssetProtocol: token does not exist");
        AssetProperties storage props = _assetProperties[tokenId];
        return (props.creationTime, props.generation, props.lastInteractionTime, props.parent1Id, props.parent2Id);
    }

    /// @notice Gets a specific numerical trait value for an asset.
    /// @param tokenId The ID of the asset.
    /// @param traitType The type of the numerical trait (e.g., "Strength").
    /// @return The value of the numerical trait. Returns 0 if trait does not exist.
    function getTokenNumericalTrait(uint256 tokenId, string memory traitType) public view returns (uint256) {
        require(_exists(tokenId), "GenerativeAssetProtocol: token does not exist");
        // No require for trait existence, just return 0 if not set
        return _numericalTraits[tokenId][traitType];
    }

    /// @notice Gets a specific string trait value for an asset.
    /// @param tokenId The ID of the asset.
    /// @param traitType The type of the string trait (e.g., "Name").
    /// @return The value of the string trait. Returns empty string if trait does not exist.
    function getTokenStringTrait(uint256 tokenId, string memory traitType) public view returns (string memory) {
        require(_exists(tokenId), "GenerativeAssetProtocol: token does not exist");
        // No require for trait existence, just return empty string if not set
        return _stringTraits[tokenId][traitType];
    }

     /// @notice Gets the total number of assets minted.
     /// @return The total supply.
    function getTotalSupply() public view returns (uint256) {
        return _tokenCounter;
    }


    // --- XI. Generative/Evolution Functions (Public/External) ---

    /// @notice Attempts to evolve an asset. Changes properties based on time, generation, and parameters. Costs ETH. Restricted by Pausable.
    /// @param tokenId The ID of the asset to evolve.
    function evolveAsset(uint256 tokenId) external payable whenNotPaused {
        _requireOwnedBy(tokenId, _msgSender());
        require(msg.value >= _globalParams.evolveCost, "GenerativeAssetProtocol: Insufficient ETH for evolve");
        require(_assetProperties[tokenId].lastInteractionTime + _globalParams.evolveCooldown <= block.timestamp, "GenerativeAssetProtocol: Evolve is on cooldown");

        AssetProperties storage props = _assetProperties[tokenId];

        // Example evolution logic:
        // Increase generation
        props.generation++;

        // Boost some stats based on generation
        uint256 generationBoost = props.generation * 2; // Example calculation
        if (_allowedNumericalTraitTypes["Strength"]) {
             uint256 currentStrength = _numericalTraits[tokenId]["Strength"];
             _numericalTraits[tokenId]["Strength"] = currentStrength + generationBoost;
             emit TraitChanged(tokenId, "Strength", _numericalTraits[tokenId]["Strength"], "");
        }
         if (_allowedNumericalTraitTypes["Intelligence"]) {
            uint256 currentInt = _numericalTraits[tokenId]["Intelligence"];
            _numericalTraits[tokenId]["Intelligence"] = currentInt + generationBoost;
            emit TraitChanged(tokenId, "Intelligence", _numericalTraits[tokenId]["Intelligence"], "");
         }


        _updateAssetLastInteraction(tokenId);

        emit AssetEvolved(tokenId, props.generation, props.lastInteractionTime);
    }

    /// @notice Attempts to mutate a random trait of an asset. Costs ETH. Restricted by Pausable.
    /// @param tokenId The ID of the asset to mutate.
    /// @param mutationSeed A seed provided by the caller.
    function mutateAsset(uint256 tokenId, uint256 mutationSeed) external payable whenNotPaused {
        _requireOwnedBy(tokenId, _msgSender());
        require(msg.value >= _globalParams.mutateCost, "GenerativeAssetProtocol: Insufficient ETH for mutate");

        uint256 randomness = _calculatePseudoRandom(mutationSeed);
        uint256 successRoll = randomness % 100;

        if (successRoll < _globalParams.mutationSuccessRate) {
            // Mutation successful
            uint256 traitCount = 0;
            // Find all present traits (could be optimized by storing traits in arrays/sets per token)
            string[] memory numericalTraits = new string[](10); // Max 10 numerical traits for simplicity
            string[] memory stringTraits = new string[](10);  // Max 10 string traits for simplicity
            uint256 numNumerical = 0;
            uint256 numString = 0;

             // Iterate through allowed types to see which the asset has
             // This is inefficient for many allowed types; better to track active traits per token.
            if (_allowedNumericalTraitTypes["Strength"] && _numericalTraits[tokenId]["Strength"] > 0) { numericalTraits[numNumerical++] = "Strength"; traitCount++; }
            if (_allowedNumericalTraitTypes["Dexterity"] && _numericalTraits[tokenId]["Dexterity"] > 0) { numericalTraits[numNumerical++] = "Dexterity"; traitCount++; }
            if (_allowedNumericalTraitTypes["Stamina"] && _numericalTraits[tokenId]["Stamina"] > 0) { numericalTraits[numNumerical++] = "Stamina"; traitCount++; }
            if (_allowedNumericalTraitTypes["Intelligence"] && _numericalTraits[tokenId]["Intelligence"] > 0) { numericalTraits[numNumerical++] = "Intelligence"; traitCount++; }
            // Add more checks for numerical traits

            if (_allowedStringTraitTypes["Name"] && bytes(_stringTraits[tokenId]["Name"]).length > 0) { stringTraits[numString++] = "Name"; traitCount++; }
            if (_allowedStringTraitTypes["Color"] && bytes(_stringTraits[tokenId]["Color"]).length > 0) { stringTraits[numString++] = "Color"; traitCount++; }
            if (_allowedStringTraitTypes["Element"] && bytes(_stringTraits[tokenId]["Element"]).length > 0) { stringTraits[numString++] = "Element"; traitCount++; }
            // Add more checks for string traits

            if (traitCount > 0) {
                uint256 chosenTraitIndex = (randomness / 100) % traitCount; // Use remaining randomness

                if (chosenTraitIndex < numNumerical) {
                    // Mutate a numerical trait
                    string memory traitType = numericalTraits[chosenTraitIndex];
                    uint256 oldValue = _numericalTraits[tokenId][traitType];
                    // Example mutation: small random change (+/- 10)
                    int256 change = int256((randomness / 1000) % 21) - 10; // Random number between -10 and +10
                    int256 newValue = int256(oldValue) + change;
                    _numericalTraits[tokenId][traitType] = uint256(newValue > 0 ? uint256(newValue) : 0);
                    emit AssetMutated(tokenId, traitType, oldValue, _numericalTraits[tokenId][traitType], "", "");
                    emit TraitChanged(tokenId, traitType, _numericalTraits[tokenId][traitType], "");
                } else {
                    // Mutate a string trait
                    string memory traitType = stringTraits[chosenTraitIndex - numNumerical];
                    string memory oldValue = _stringTraits[tokenId][traitType];
                    // Example mutation: simple change, needs a list of possible values
                    string memory newValue = "Mutated"; // Placeholder - needs logic to pick a new value
                     if (keccak256(bytes(traitType)) == keccak256(bytes("Color"))) {
                         string[] memory colors = new string[](4);
                         colors[0] = "Red"; colors[1] = "Green"; colors[2] = "Blue"; colors[3] = "Yellow";
                         newValue = colors[randomness / 2000 % 4];
                     } else if (keccak256(bytes(traitType)) == keccak256(bytes("Element"))) {
                          string[] memory elements = new string[](4);
                         elements[0] = "Fire"; elements[1] = "Water"; elements[2] = "Earth"; elements[3] = "Air";
                         newValue = elements[randomness / 3000 % 4];
                     } else {
                         newValue = string(abi.encodePacked("Mutated ", Strings.toString(tokenId)));
                     }

                    _stringTraits[tokenId][traitType] = newValue;
                     emit AssetMutated(tokenId, traitType, 0, 0, oldValue, _stringTraits[tokenId][traitType]);
                     emit TraitChanged(tokenId, traitType, 0, _stringTraits[tokenId][traitType]);
                }
                 _updateAssetLastInteraction(tokenId);
            } else {
                // No traits to mutate
                 // Consider refunding cost or having a different outcome
                 revert("GenerativeAssetProtocol: Asset has no mutable traits");
            }

        } else {
            // Mutation failed - maybe emit event
            // Optional: Emit a "MutationFailed" event
        }
    }

    /// @notice Increases a specific numerical trait of an asset. Costs ETH. Restricted by Pausable.
    /// @param tokenId The ID of the asset.
    /// @param numericalTraitType The type of numerical trait to increase.
    /// @param amount The amount to increase the trait by.
    function feedAsset(uint256 tokenId, string memory numericalTraitType, uint256 amount) external payable whenNotPaused {
         _requireOwnedBy(tokenId, _msgSender());
         require(msg.value >= _globalParams.feedCost, "GenerativeAssetProtocol: Insufficient ETH for feed");
         require(_allowedNumericalTraitTypes[numericalTraitType], "GenerativeAssetProtocol: Invalid numerical trait type");
         require(amount > 0, "GenerativeAssetProtocol: Feed amount must be positive");

        // Ensure the trait exists for the asset (or add it if allowed)
        // For simplicity, we allow adding it if it's an allowed type.
         uint256 currentTraitValue = _numericalTraits[tokenId][numericalTraitType];
         _numericalTraits[tokenId][numericalTraitType] = currentTraitValue + amount;

         _updateAssetLastInteraction(tokenId);

         emit AssetFed(tokenId, numericalTraitType, amount, _numericalTraits[tokenId][numericalTraitType]);
         emit TraitChanged(tokenId, numericalTraitType, _numericalTraits[tokenId][numericalTraitType], "");
    }

     /// @notice Simulates a challenge interaction. Outcome is pseudo-random and affects stats. Costs ETH. Restricted by Pausable.
     /// @param tokenId The ID of the asset being challenged.
     /// @param challengeSeed A seed provided by the caller.
    function challengeAsset(uint256 tokenId, uint256 challengeSeed) external payable whenNotPaused {
        _requireOwnedBy(tokenId, _msgSender());
        require(msg.value >= _globalParams.challengeCost, "GenerativeAssetProtocol: Insufficient ETH for challenge");

        uint256 randomness = _calculatePseudoRandom(challengeSeed);
        bool success = (randomness % 100) < 50; // 50% chance of success example

        string memory outcomeDescription;
        if (success) {
            outcomeDescription = "Challenge Successful!";
            // Example: Boost a random stat
            if (_allowedNumericalTraitTypes["Strength"]) {
                 _numericalTraits[tokenId]["Strength"] = _numericalTraits[tokenId]["Strength"] + 5;
                 emit TraitChanged(tokenId, "Strength", _numericalTraits[tokenId]["Strength"], "");
            }
             if (_allowedNumericalTraitTypes["Dexterity"]) {
                 _numericalTraits[tokenId]["Dexterity"] = _numericalTraits[tokenId]["Dexterity"] + 5;
                  emit TraitChanged(tokenId, "Dexterity", _numericalTraits[tokenId]["Dexterity"], "");
            }

        } else {
            outcomeDescription = "Challenge Failed!";
            // Example: Decrease a random stat
             if (_allowedNumericalTraitTypes["Stamina"]) {
                uint256 currentStamina = _numericalTraits[tokenId]["Stamina"];
                 if (currentStamina >= 5) {
                    _numericalTraits[tokenId]["Stamina"] = currentStamina - 5;
                 } else {
                     _numericalTraits[tokenId]["Stamina"] = 0;
                 }
                  emit TraitChanged(tokenId, "Stamina", _numericalTraits[tokenId]["Stamina"], "");
             }
             if (_allowedNumericalTraitTypes["Intelligence"]) {
                 uint256 currentInt = _numericalTraits[tokenId]["Intelligence"];
                 if (currentInt >= 5) {
                    _numericalTraits[tokenId]["Intelligence"] = currentInt - 5;
                 } else {
                     _numericalTraits[tokenId]["Intelligence"] = 0;
                 }
                 emit TraitChanged(tokenId, "Intelligence", _numericalTraits[tokenId]["Intelligence"], "");
             }
        }

        _updateAssetLastInteraction(tokenId);

        emit AssetChallenged(tokenId, challengeSeed, success, outcomeDescription);
    }

    /// @notice Attempts to breed two assets to create a new one. Requires owning both parents and costs ETH. Restricted by Pausable.
    /// @param parent1Id The ID of the first parent.
    /// @param parent2Id The ID of the second parent.
    /// @param breedingSeed A seed provided by the caller.
    /// @return The ID of the new child asset, or 0 if breeding failed.
    function breedAssets(uint256 parent1Id, uint256 parent2Id, uint256 breedingSeed) external payable whenNotPaused returns (uint256 newTokenId) {
        require(parent1Id != parent2Id, "GenerativeAssetProtocol: Cannot breed with self");
        _requireOwnedBy(parent1Id, _msgSender());
        _requireOwnedBy(parent2Id, _msgSender());
         require(msg.value >= _globalParams.breedingCost, "GenerativeAssetProtocol: Insufficient ETH for breeding");
         require(_assetProperties[parent1Id].lastInteractionTime + _globalParams.breedingCooldown <= block.timestamp, "GenerativeAssetProtocol: Parent 1 is on breeding cooldown");
         require(_assetProperties[parent2Id].lastInteractionTime + _globalParams.breedingCooldown <= block.timestamp, "GenerativeAssetProtocol: Parent 2 is on breeding cooldown");

        uint256 randomness = _calculatePseudoRandom(breedingSeed);
        bool success = (randomness % 100) < _globalParams.breedingSuccessRate;

        newTokenId = 0; // Default to 0 if failed

        if (success) {
            _tokenCounter++;
            newTokenId = _tokenCounter;

            _mint(_msgSender(), newTokenId); // Mint the new token

            // Initialize child properties
            _assetProperties[newTokenId] = AssetProperties({
                creationTime: uint64(block.timestamp),
                generation: 1, // Start at generation 1 for bred assets
                lastInteractionTime: uint64(block.timestamp),
                parent1Id: parent1Id,
                parent2Id: parent2Id
            });

            // Inherit/Combine traits from parents (example logic)
            uint256 traitRandomness = randomness / 100; // Use different part of randomness
            uint256 index = 0;

            // Numerical traits: average + randomness
            if (_allowedNumericalTraitTypes["Strength"]) {
                 uint256 avgStrength = (_numericalTraits[parent1Id]["Strength"] + _numericalTraits[parent2Id]["Strength"]) / 2;
                 uint256 randomInfluence = (_calculatePseudoRandom(traitRandomness + index) % (avgStrength / 4 + 1)) - (avgStrength / 8); // +/- 12.5%
                 int256 childValue = int256(avgStrength) + int256(randomInfluence);
                _numericalTraits[newTokenId]["Strength"] = uint256(childValue > 0 ? uint256(childValue) : 0);
                 emit TraitChanged(newTokenId, "Strength", _numericalTraits[newTokenId]["Strength"], "");
                 index++;
            }
             if (_allowedNumericalTraitTypes["Dexterity"]) {
                 uint256 avgDex = (_numericalTraits[parent1Id]["Dexterity"] + _numericalTraits[parent2Id]["Dexterity"]) / 2;
                 uint256 randomInfluence = (_calculatePseudoRandom(traitRandomness + index) % (avgDex / 4 + 1)) - (avgDex / 8);
                 int256 childValue = int256(avgDex) + int256(randomInfluence);
                _numericalTraits[newTokenId]["Dexterity"] = uint256(childValue > 0 ? uint256(childValue) : 0);
                 emit TraitChanged(newTokenId, "Dexterity", _numericalTraits[newTokenId]["Dexterity"], "");
                 index++;
            }
            // ... add more for other numerical traits

            // String traits: inherit from one parent randomly
             if (_allowedStringTraitTypes["Color"]) {
                 string memory inheritedColor = (_calculatePseudoRandom(traitRandomness + index) % 2 == 0) ? _stringTraits[parent1Id]["Color"] : _stringTraits[parent2Id]["Color"];
                 _stringTraits[newTokenId]["Color"] = inheritedColor;
                  emit TraitChanged(newTokenId, "Color", 0, _stringTraits[newTokenId]["Color"]);
                 index++;
            }
             if (_allowedStringTraitTypes["Element"]) {
                 string memory inheritedElement = (_calculatePseudoRandom(traitRandomness + index) % 2 == 0) ? _stringTraits[parent1Id]["Element"] : _stringTraits[parent2Id]["Element"];
                 _stringTraits[newTokenId]["Element"] = inheritedElement;
                 emit TraitChanged(newTokenId, "Element", 0, _stringTraits[newTokenId]["Element"]);
                 index++;
            }
            // Name could be a combination or new random name
             _stringTraits[newTokenId]["Name"] = string(abi.encodePacked("Bred Entity #", Strings.toString(newTokenId)));
             emit TraitChanged(newTokenId, "Name", 0, _stringTraits[newTokenId]["Name"]);


            _updateAssetLastInteraction(parent1Id); // Parents go on cooldown
            _updateAssetLastInteraction(parent2Id);

            emit AssetBred(newTokenId, parent1Id, parent2Id);

        } else {
            // Breeding failed
            // Optional: Emit a "BreedingFailed" event
        }
         return newTokenId; // Return 0 if failed, or new ID if success
    }

    /// @notice Manually triggers potential decay of an asset's numerical stats based on time since last interaction.
    /// Can be called by anyone, but only applies if decay is due. Restricted by Pausable.
    /// @param tokenId The ID of the asset.
    function decayStats(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "GenerativeAssetProtocol: token does not exist");

        uint64 lastInteraction = _assetProperties[tokenId].lastInteractionTime;
        uint64 timeElapsed = uint64(block.timestamp) - lastInteraction;
        uint256 daysElapsed = timeElapsed / 1 days; // Integer division

        if (daysElapsed > 0 && _globalParams.decayRatePerDay > 0) {
            uint256 totalDecayPercentage = daysElapsed * _globalParams.decayRatePerDay;
            // Cap decay at 100%
            if (totalDecayPercentage > 100) {
                totalDecayPercentage = 100;
            }

            // Apply decay to all numerical traits
            // Again, iterating over allowed types is inefficient. Better to iterate over owned traits.
             if (_allowedNumericalTraitTypes["Strength"]) {
                 uint256 currentValue = _numericalTraits[tokenId]["Strength"];
                 uint256 decayAmount = (currentValue * totalDecayPercentage) / 100;
                 _numericalTraits[tokenId]["Strength"] = currentValue > decayAmount ? currentValue - decayAmount : 0;
                 emit TraitChanged(tokenId, "Strength", _numericalTraits[tokenId]["Strength"], "");
             }
             if (_allowedNumericalTraitTypes["Dexterity"]) {
                 uint256 currentValue = _numericalTraits[tokenId]["Dexterity"];
                 uint256 decayAmount = (currentValue * totalDecayPercentage) / 100;
                 _numericalTraits[tokenId]["Dexterity"] = currentValue > decayAmount ? currentValue - decayAmount : 0;
                 emit TraitChanged(tokenId, "Dexterity", _numericalTraits[tokenId]["Dexterity"], "");
             }
              if (_allowedNumericalTraitTypes["Stamina"]) {
                 uint256 currentValue = _numericalTraits[tokenId]["Stamina"];
                 uint256 decayAmount = (currentValue * totalDecayPercentage) / 100;
                 _numericalTraits[tokenId]["Stamina"] = currentValue > decayAmount ? currentValue - decayAmount : 0;
                 emit TraitChanged(tokenId, "Stamina", _numericalTraits[tokenId]["Stamina"], "");
             }
              if (_allowedNumericalTraitTypes["Intelligence"]) {
                 uint256 currentValue = _numericalTraits[tokenId]["Intelligence"];
                 uint256 decayAmount = (currentValue * totalDecayPercentage) / 100;
                 _numericalTraits[tokenId]["Intelligence"] = currentValue > decayAmount ? currentValue - decayAmount : 0;
                 emit TraitChanged(tokenId, "Intelligence", _numericalTraits[tokenId]["Intelligence"], "");
             }
            // Apply to other numerical traits...

            // Update last interaction time *only* up to the time decay was calculated for,
            // so if more time passes, subsequent calls calculate decay from that point.
            // Or, simply update to now if decay resets the timer for subsequent decay calculations.
            // Let's update to now for simplicity, meaning decay 'uses up' the time elapsed.
             _updateAssetLastInteraction(tokenId); // Resets the decay timer
        }
    }

    /// @notice Triggers a global evolution event affecting all assets. Restricted to GLOBAL_EVOKER_ROLE. Restricted by Pausable.
    /// @param globalEvolutionSeed A seed for randomness in global effects.
    function triggerGlobalEvolution(uint256 globalEvolutionSeed) external onlyRole(GLOBAL_EVOKER_ROLE) whenNotPaused {
        // This function is complex as it potentially iterates over all tokens.
        // On-chain iteration is expensive and can hit gas limits.
        // In a real application, this might need to be broken up, handled off-chain by a keeper,
        // or use a different mechanism (e.g., users triggering checks individually after the global event).
        // For demonstration, we'll show the *intent*, assuming a small number of tokens or a system
        // that can handle the gas cost (e.g., L2, or careful gas limits).

        // Example global effect: universal stats boost + potential new trait discovery chance
        uint256 randomness = _calculatePseudoRandom(globalEvolutionSeed);
        uint256 statBoost = (randomness % 10) + 1; // Boost between 1 and 10

        // Iterate through all token IDs from 1 to _tokenCounter
        for (uint256 i = 1; i <= _tokenCounter; i++) {
            if (_exists(i)) { // Ensure the token hasn't been burned
                // Apply universal stat boost
                 if (_allowedNumericalTraitTypes["Stamina"]) {
                     _numericalTraits[i]["Stamina"] += statBoost;
                     emit TraitChanged(i, "Stamina", _numericalTraits[i]["Stamina"], "");
                 }
                 if (_allowedNumericalTraitTypes["Intelligence"]) {
                     _numericalTraits[i]["Intelligence"] += statBoost;
                      emit TraitChanged(i, "Intelligence", _numericalTraits[i]["Intelligence"], "");
                 }
                // Apply to other numerical traits...

                // Chance to discover a new trait type?
                // This check needs a list of trait types the asset *doesn't* have yet.
                // Too complex to implement efficiently on-chain here.
                // Example: Small chance to get a "Lucky" trait
                // if (_calculatePseudoRandom(globalEvolutionSeed + i) % 100 < 5 && _allowedNumericalTraitTypes["Luck"] && _numericalTraits[i]["Luck"] == 0) {
                //     _numericalTraits[i]["Luck"] = 1;
                //     emit TraitDiscovered(i, "Luck", true);
                // }

                // Update interaction time (optional, depending on if global event resets timers)
                // _updateAssetLastInteraction(i);
            }
        }
        // Emit a global event signaling the evolution happened
        // emit GlobalEvolutionTriggered(block.timestamp, statBoost, globalEvolutionSeed); // Need to define this event
    }

     /// @notice Attempts to add a *new* allowed trait type to an asset. Costs ETH. Restricted by Pausable.
     /// Asset must not already have this trait type. Pseudo-random chance.
     /// @param tokenId The ID of the asset.
     /// @param discoverySeed A seed provided by the caller.
     function discoverNewTrait(uint256 tokenId, uint256 discoverySeed) external payable whenNotPaused {
        _requireOwnedBy(tokenId, _msgSender());
         require(msg.value >= _globalParams.discoveryCost, "GenerativeAssetProtocol: Insufficient ETH for discovery");

         uint256 randomness = _calculatePseudoRandom(discoverySeed);
         uint256 discoveryRoll = randomness % 100;
         uint256 discoveryChance = 30; // Example: 30% chance

        if (discoveryRoll < discoveryChance) {
            // Discovery successful, find a new trait type the asset doesn't have
            string memory discoveredNumericalTrait = "";
            string memory discoveredStringTrait = "";

            // Inefficient iteration: iterate through allowed types
            // Check for numerical traits not present
             if (_allowedNumericalTraitTypes["Strength"] && _numericalTraits[tokenId]["Strength"] == 0) discoveredNumericalTrait = "Strength";
             else if (_allowedNumericalTraitTypes["Dexterity"] && _numericalTraits[tokenId]["Dexterity"] == 0) discoveredNumericalTrait = "Dexterity";
             else if (_allowedNumericalTraitTypes["Stamina"] && _numericalTraits[tokenId]["Stamina"] == 0) discoveredNumericalTrait = "Stamina";
             else if (_allowedNumericalTraitTypes["Intelligence"] && _numericalTraits[tokenId]["Intelligence"] == 0) discoveredNumericalTrait = "Intelligence";
             // Add more checks...

            // Check for string traits not present
             if (bytes(discoveredNumericalTrait).length == 0) { // Only look for string if no numerical found
                 if (_allowedStringTraitTypes["Name"] && bytes(_stringTraits[tokenId]["Name"]).length == 0) discoveredStringTrait = "Name"; // Name usually starts with something, unlikely to be empty
                 else if (_allowedStringTraitTypes["Color"] && bytes(_stringTraits[tokenId]["Color"]).length == 0) discoveredStringTrait = "Color";
                 else if (_allowedStringTraitTypes["Element"] && bytes(_stringTraits[tokenId]["Element"]).length == 0) discoveredStringTrait = "Element";
                // Add more checks...
             }


            if (bytes(discoveredNumericalTrait).length > 0) {
                // Assign a base value to the new numerical trait
                 string memory traitType = discoveredNumericalTrait;
                 uint256 baseValue = _baseNumericalTraits[traitType]; // Use base value
                 _numericalTraits[tokenId][traitType] = baseValue;
                 emit TraitDiscovered(tokenId, traitType, true);
                 emit TraitChanged(tokenId, traitType, _numericalTraits[tokenId][traitType], "");

            } else if (bytes(discoveredStringTrait).length > 0) {
                // Assign a base value to the new string trait
                 string memory traitType = discoveredStringTrait;
                 string memory baseValue = _baseStringTraits[traitType]; // Use base value
                 _stringTraits[tokenId][traitType] = baseValue;
                 emit TraitDiscovered(tokenId, traitType, false);
                 emit TraitChanged(tokenId, traitType, 0, _stringTraits[tokenId][traitType]);

            } else {
                // No new traits available to discover for this asset
                // Optional: Refund cost or emit specific event
                revert("GenerativeAssetProtocol: No new traits available for discovery");
            }

             _updateAssetLastInteraction(tokenId);
        } else {
            // Discovery failed
            // Optional: Emit DiscoveryFailed event
        }
     }


    // --- XII. Parameter Management (Role-Restricted) ---

     /// @notice Sets multiple global parameters for the protocol. Restricted to PARAMETER_MANAGER_ROLE.
     // Note: This function is large and might exceed gas limits depending on the number of parameters.
    function setGlobalParams(
        uint256 newMintCost,
        uint256 newEvolveCost,
        uint256 newMutateCost,
        uint256 newFeedCost,
        uint256 newChallengeCost,
        uint256 newBreedingCost,
        uint256 newDiscoveryCost,
        uint64 newEvolveCooldown,
        uint64 newBreedingCooldown,
        uint256 newDecayRatePerDay,
        uint256 newMutationSuccessRate,
        uint256 newBreedingSuccessRate
    ) external onlyRole(PARAMETER_MANAGER_ROLE) {
        _globalParams.mintCost = newMintCost;
        _globalParams.evolveCost = newEvolveCost;
        _globalParams.mutateCost = newMutateCost;
        _globalParams.feedCost = newFeedCost;
        _globalParams.challengeCost = newChallengeCost;
        _globalParams.breedingCost = newBreedingCost;
        _globalParams.discoveryCost = newDiscoveryCost;
        _globalParams.evolveCooldown = newEvolveCooldown;
        _globalParams.breedingCooldown = newBreedingCooldown;
        _globalParams.decayRatePerDay = newDecayRatePerDay;
        _globalParams.mutationSuccessRate = newMutationSuccessRate;
        _globalParams.breedingSuccessRate = newBreedingSuccessRate;

        // Emit ParameterSet events for each parameter if needed for detailed logging
        emit ParameterSet("mintCost", newMintCost);
        // ... emit for others
    }

    /// @notice Adds a new allowed trait type for numerical traits. Restricted to PARAMETER_MANAGER_ROLE.
    /// @param traitType The name of the new numerical trait type.
    function addAllowedNumericalTraitType(string memory traitType) external onlyRole(PARAMETER_MANAGER_ROLE) {
        require(bytes(traitType).length > 0, "GenerativeAssetProtocol: Trait type cannot be empty");
        _allowedNumericalTraitTypes[traitType] = true;
        // Optional: Emit event for adding trait type
    }

     /// @notice Removes an allowed trait type for numerical traits. Restricted to PARAMETER_MANAGER_ROLE.
     /// @param traitType The name of the numerical trait type to remove.
    function removeAllowedNumericalTraitType(string memory traitType) external onlyRole(PARAMETER_MANAGER_ROLE) {
         require(bytes(traitType).length > 0, "GenerativeAssetProtocol: Trait type cannot be empty");
        _allowedNumericalTraitTypes[traitType] = false;
        // Note: This does NOT remove the trait from existing assets.
        // Optional: Emit event for removing trait type
    }

    /// @notice Adds a new allowed trait type for string traits. Restricted to PARAMETER_MANAGER_ROLE.
    /// @param traitType The name of the new string trait type.
    function addAllowedStringTraitType(string memory traitType) external onlyRole(PARAMETER_MANAGER_ROLE) {
         require(bytes(traitType).length > 0, "GenerativeAssetProtocol: Trait type cannot be empty");
        _allowedStringTraitTypes[traitType] = true;
         // Optional: Emit event
    }

     /// @notice Removes an allowed trait type for string traits. Restricted to PARAMETER_MANAGER_ROLE.
     /// @param traitType The name of the string trait type to remove.
    function removeAllowedStringTraitType(string memory traitType) external onlyRole(PARAMETER_MANAGER_ROLE) {
         require(bytes(traitType).length > 0, "GenerativeAssetProtocol: Trait type cannot be empty");
        _allowedStringTraitTypes[traitType] = false;
        // Note: This does NOT remove the trait from existing assets.
        // Optional: Emit event
    }

    /// @notice Sets the base value for a numerical trait type for new mints. Restricted to PARAMETER_MANAGER_ROLE.
    /// @param traitType The name of the numerical trait type.
    /// @param baseValue The new base value.
    function setBaseNumericalTrait(string memory traitType, uint256 baseValue) external onlyRole(PARAMETER_MANAGER_ROLE) {
        require(_allowedNumericalTraitTypes[traitType], "GenerativeAssetProtocol: Trait type not allowed");
        _baseNumericalTraits[traitType] = baseValue;
        // Optional: Emit event
    }

    /// @notice Sets the base value for a string trait type for new mints. Restricted to PARAMETER_MANAGER_ROLE.
    /// @param traitType The name of the string trait type.
    /// @param baseValue The new base value.
    function setBaseStringTrait(string memory traitType, string memory baseValue) external onlyRole(PARAMETER_MANAGER_ROLE) {
        require(_allowedStringTraitTypes[traitType], "GenerativeAssetProtocol: Trait type not allowed");
        _baseStringTraits[traitType] = baseValue;
        // Optional: Emit event
    }


    // --- XIII. Role Management (Owner-Only) ---
    // Using Ownable's DEFAULT_ADMIN_ROLE which is the owner.

    /// @notice Grants a specific role to an account. Restricted to contract owner.
    /// @param role The role to grant.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) external onlyOwner {
        _grantRole(role, account);
    }

    /// @notice Revokes a specific role from an account. Restricted to contract owner.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) external onlyOwner {
        _revokeRole(role, account);
    }

    /// @notice Checks if an account has a specific role.
    /// @param role The role to check.
    /// @param account The address to check.
    /// @return True if the account has the role, false otherwise.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        // Owner implicitly has all custom roles granted in constructor,
        // but this check specifically looks at the custom mapping.
        // Could add an 'isOwner() || _roles[role][account]' check if owner should always override.
        return _roles[role][account];
    }

    // --- XIV. Pausable System ---
    // Inherited from OpenZeppelin Pausable.sol.

    /// @notice Pauses the contract. Restricted to PARAMETER_MANAGER_ROLE (example role for this).
    function pause() external onlyRole(PARAMETER_MANAGER_ROLE) whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Restricted to PARAMETER_MANAGER_ROLE (example role for this).
    function unpause() external onlyRole(PARAMETER_MANAGER_ROLE) whenPaused {
        _unpause();
    }


    // --- XV. Withdrawal Functions (Role-Restricted, Reentrancy Guarded) ---

    /// @notice Allows a ROLE_MANAGER to withdraw ETH accumulated in the contract.
    /// @param payable to The address to send the ETH to.
    /// @param amount The amount of ETH to withdraw.
    function withdrawETH(address payable to, uint256 amount) external onlyRole(PARAMETER_MANAGER_ROLE) nonReentrant {
        require(amount <= address(this).balance, "GenerativeAssetProtocol: insufficient balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "GenerativeAssetProtocol: ETH transfer failed");
    }

    /// @notice Allows a ROLE_MANAGER to withdraw a specific ERC20 token accumulated in the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param to The address to send the tokens to.
    /// @param amount The amount of tokens to withdraw.
    function withdrawToken(address tokenAddress, address to, uint256 amount) external onlyRole(PARAMETER_MANAGER_ROLE) nonReentrant {
        require(tokenAddress != address(0), "GenerativeAssetProtocol: zero token address");
        require(to != address(0), "GenerativeAssetProtocol: zero recipient address");

        // Using interface directly without requiring the full ERC20 contract
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "GenerativeAssetProtocol: insufficient token balance");

        // Perform the transfer
        require(token.transfer(to, amount), "GenerativeAssetProtocol: token transfer failed");
    }

    // Provide a fallback function to receive ETH
    receive() external payable {
        // ETH received, presumably from minting or interaction costs
        // No action needed other than receiving
    }
}

// Minimal IERC20 interface just for the withdrawToken function
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
```