Okay, let's design an interesting and relatively advanced smart contract concept: **A Multi-Dimensional NFT (MultiDimNFT)**.

This NFT represents an asset with several distinct, evolving "dimensions" or properties. These dimensions can be upgraded, changed, or influenced by on-chain actions, interaction with other tokens (hypothetical, not fully implemented here for simplicity but part of the concept), or potentially external data (via oracle simulation). The metadata (`tokenURI`) for each NFT is *dynamic*, reflecting its current state across these dimensions.

Here's the concept breakdown and the contract implementation:

---

**Contract Concept: MultiDimNFT**

A novel ERC721 NFT where each token possesses multiple conceptual "dimensions". These dimensions are not just static attributes but dynamic states, levels, or traits that can be modified through specific interactions with the contract.

*   **Dimensions:** Each NFT has several quantifiable or qualitative dimensions (e.g., State, Attribute Set, Visual Stage, Energy Pool, Unlocked Traits).
*   **Dynamic State:** The values of these dimensions are stored on-chain and can change over time.
*   **Progression:** Users can interact with the contract (potentially paying fees or meeting requirements) to activate, upgrade, advance, or refill these dimensions.
*   **Dynamic Metadata:** The `tokenURI` function doesn't return a static link but constructs a unique identifier based on the NFT's *current* dimension states. This identifier is expected to resolve (off-chain) to metadata describing the NFT's real-time characteristics.
*   **Energy System:** A key dimension is an 'Energy Pool' that replenishes over time but can be consumed for actions like upgrades or unlocking traits.
*   **Trait Unlocking:** Specific boolean flags represent unique traits that can be permanently unlocked.
*   **Configuration:** The contract owner can configure costs, refill rates, requirements, and dimension parameters.

**Advanced/Creative/Trendy Aspects:**

1.  **Truly Dynamic NFTs:** Not just changing metadata off-chain, but the *on-chain state* driving the metadata is programmable and changes based on user interaction.
2.  **Multi-faceted Evolution:** Instead of a single 'level', the NFT evolves across multiple distinct dimensions simultaneously.
3.  **On-chain Energy System:** An internal resource mechanic managed within the contract, tying actions to resource availability and time.
4.  **Programmable Progression:** Actions require specific states, costs, and energy, creating decision points for the owner.
5.  **Modular Dimension Concept:** While fixed in this implementation, the concept could be extended to more complex, potentially even user-defined dimensions in a more advanced version.
6.  **Non-duplication:** The combination of multiple distinct, interactive dimensions, a time-based energy system tied to progression, and dynamic metadata reflecting this complex state isn't a standard ERC721 extension or a common open-source pattern like fractionalization or basic staking.

---

**Outline and Function Summary**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for clarity and gas efficiency
error InvalidTokenId();
error NotTokenOwner();
error NotPaused();
error IsPaused();
error InsufficientFunds(uint256 required, uint256 provided);
error InsufficientEnergy(uint256 required, uint256 available);
error RequirementNotMet(string requirement);
error TraitAlreadyUnlocked();
error InvalidEnergyAmount();

contract MultiDimNFT is ERC721, Ownable, Pausable {

    // --- Outline ---
    // 1. State Variables & Constants
    // 2. Enums & Structs (Representing Dimensions and configs)
    // 3. Events
    // 4. Core ERC721 Overrides
    // 5. Minting
    // 6. Dimension State Storage & Management
    // 7. Dynamic Metadata Generation (_generateTokenMetadataURI, tokenURI)
    // 8. Energy System Logic (_calculateCurrentEnergy, consumeEnergy, refillEnergy)
    // 9. Interaction Functions (Activate, Upgrade, Advance Visual Stage, Unlock Trait)
    // 10. Configuration & Admin Functions (Set costs, Set rates, Set base URI, Pause, Withdraw)
    // 11. View Functions (Get dimension states, Get costs, Get total supply, etc.)
    // 12. Internal/Helper Functions

    // --- Function Summary ---

    // ERC721 Standard Functions (Inherited and Overridden)
    // name() external view returns (string memory) - Returns the token name (from ERC721).
    // symbol() external view returns (string memory) - Returns the token symbol (from ERC721).
    // totalSupply() public view returns (uint256) - Returns the total number of tokens minted (from ERC721).
    // balanceOf(address owner) public view returns (uint256) - Returns the balance of an owner (from ERC721).
    // ownerOf(uint256 tokenId) public view returns (address owner) - Returns the owner of a token (from ERC721).
    // approve(address to, uint256 tokenId) public virtual - Approves an address to spend a token (from ERC721).
    // getApproved(uint256 tokenId) public view virtual returns (address) - Returns the approved address for a token (from ERC721).
    // setApprovalForAll(address operator, bool approved) public virtual - Sets approval for an operator for all tokens (from ERC721).
    // isApprovedForAll(address owner, address operator) public view virtual returns (bool) - Checks if an operator is approved for all tokens (from ERC721).
    // transferFrom(address from, address to, uint256 tokenId) public virtual - Transfers a token (from ERC721).
    // safeTransferFrom(address from, address to, uint256 tokenId) public virtual - Safely transfers a token (from ERC721).
    // tokenURI(uint256 tokenId) public view override returns (string memory) - **OVERRIDDEN** Returns the dynamic metadata URI for a token.
    // supportsInterface(bytes4 interfaceId) public view override returns (bool) - Checks supported interfaces (from ERC721).

    // Minting
    // mint() external payable whenNotPaused returns (uint256) - Mints a new MultiDimNFT token.

    // Dimension State View Functions
    // getTokenDimensions(uint256 tokenId) public view returns (TokenDimensions memory) - Returns all dimension states for a token.
    // getDimensionState(uint256 tokenId) public view returns (DimensionState) - Returns the State dimension for a token.
    // getAttributeSet(uint256 tokenId) public view returns (AttributeSet) - Returns the Attribute Set dimension for a token.
    // getVisualStage(uint256 tokenId) public view returns (VisualStage) - Returns the Visual Stage dimension for a token.
    // getEnergyLevel(uint256 tokenId) public view returns (uint256) - Returns the current calculated Energy Level for a token.
    // getUnlockedTraits(uint256 tokenId) public view returns (TraitFlags memory) - Returns the unlocked traits flags for a token.

    // Dimension Interaction Functions (Require token ownership and potentially costs/energy)
    // activateDimensionState(uint256 tokenId) external payable whenNotPaused - Activates the State dimension for a token.
    // upgradeAttributeSet(uint256 tokenId) external payable whenNotPaused - Upgrades the Attribute Set dimension for a token.
    // advanceVisualStage(uint256 tokenId) external payable whenNotPaused - Advances the Visual Stage dimension for a token.
    // consumeEnergy(uint256 tokenId, uint256 amount) external whenNotPaused - Consumes energy from a token's energy pool.
    // refillEnergy(uint256 tokenId, uint256 amount) external payable whenNotPaused - Refills energy for a token (might have a cost).
    // unlockTrait(uint256 tokenId, Trait trait) external payable whenNotPaused - Unlocks a specific trait for a token.

    // Configuration & Admin Functions (Owner Only)
    // setBaseMetadataURI(string memory baseURI) external onlyOwner - Sets the base URI for dynamic metadata.
    // setMintCost(uint256 cost) external onlyOwner - Sets the cost to mint a new token.
    // setActivationCost(DimensionState state, uint256 cost, uint256 energyCost) external onlyOwner - Sets costs for activating State dimensions.
    // setAttributeUpgradeCost(AttributeSet currentSet, AttributeSet nextSet, uint256 cost, uint256 energyCost) external onlyOwner - Sets costs for upgrading Attribute Sets.
    // setVisualStageAdvanceCost(VisualStage currentStage, VisualStage nextStage, uint256 cost, uint256 energyCost) external onlyOwner - Sets costs for advancing Visual Stages.
    // setTraitUnlockCost(Trait trait, uint256 cost, uint256 energyCost) external onlyOwner - Sets costs for unlocking traits.
    // setEnergyRefillCost(uint256 costPerUnit) external onlyOwner - Sets the cost per unit of energy refilled.
    // setEnergyRefillRate(uint256 ratePerSecond) external onlyOwner - Sets the energy refill rate per second.
    // setMaxEnergy(uint256 maxEnergy) external onlyOwner - Sets the maximum energy a token can hold.
    // pause() external onlyOwner whenNotPaused - Pauses the contract actions.
    // unpause() external onlyOwner whenPaused - Unpauses the contract actions.
    // withdraw() external onlyOwner - Withdraws accumulated Ether from the contract.

    // View Functions (Public or Owner Only)
    // getMintCost() public view returns (uint256) - Returns the current mint cost.
    // getActivationCost(DimensionState state) public view returns (uint256 cost, uint256 energyCost) - Returns costs for activating a specific State dimension.
    // getAttributeUpgradeCost(AttributeSet currentSet, AttributeSet nextSet) public view returns (uint256 cost, uint256 energyCost) - Returns costs for upgrading between Attribute Sets.
    // getVisualStageAdvanceCost(VisualStage currentStage, VisualStage nextStage) public view returns (uint256 cost, uint256 energyCost) - Returns costs for advancing between Visual Stages.
    // getTraitUnlockCost(Trait trait) public view returns (uint256 cost, uint256 energyCost) - Returns costs for unlocking a specific trait.
    // getEnergyRefillCost() public view returns (uint256) - Returns the cost per unit of energy refilled.
    // getEnergyRefillRate() public view returns (uint256) - Returns the energy refill rate per second.
    // getMaxEnergy() public view returns (uint256) - Returns the maximum energy.
    // _generateTokenMetadataURI(uint256 tokenId, TokenDimensions memory dims) internal pure returns (string memory) - **INTERNAL** Helper to generate a URI based on dimension states.
    // _calculateCurrentEnergy(uint256 tokenId) internal view returns (uint256) - **INTERNAL** Calculates current energy based on time and refill rate.
    // _getTokenData(uint256 tokenId) internal view returns (TokenData storage) - **INTERNAL** Helper to get storage for a token's data.
    // _requireTokenOwner(uint256 tokenId) internal view - **INTERNAL** Helper to check token ownership.
    // _updateLastEnergyTime(uint256 tokenId) internal - **INTERNAL** Updates the last energy update timestamp.

    // Total functions: 12 (ERC721 Overrides) + 1 (Mint) + 6 (Dimension Views) + 6 (Interaction) + 11 (Config/Admin) + 8 (Config Views) + 5 (Internal Helpers counted in description) = 49 functions (more than 20).

    // Note: Some internal helper functions are listed for clarity in the summary but might not be callable directly from outside. The user-facing/external/public view count is well over 20.

    // --- End Function Summary ---
```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For energy calculations

// --- Custom Errors ---
error InvalidTokenId();
error NotTokenOwner();
error NotPaused();
error IsPaused();
error InsufficientFunds(uint256 required, uint256 provided);
error InsufficientEnergy(uint256 required, uint256 available);
error RequirementNotMet(string requirement);
error TraitAlreadyUnlocked();
error InvalidEnergyAmount();
error CannotUpgradeFromOrTo(); // e.g., upgrading beyond max or from non-existent state
error InvalidTrait();
error EnergyAtMaxCapacity();
error NothingToWithdraw();

// --- Enums and Structs ---

// Represents the overall state dimension
enum DimensionState {
    Dormant,
    Active,
    Enhanced,
    Ascended // Example higher state
}

// Represents an attribute set dimension (e.g., elemental affinity)
enum AttributeSet {
    None,
    Fire,
    Water,
    Earth,
    Air
}

// Represents a visual progression stage dimension
enum VisualStage {
    Stage1,
    Stage2,
    Stage3
}

// Represents unlockable traits
enum Trait {
    ExtraEnergyBoost,
    ReducedUpgradeCost,
    DimensionShiftCapability // Example trait
}

// Struct to hold boolean flags for unlocked traits
struct TraitFlags {
    bool extraEnergyBoost;
    bool reducedUpgradeCost;
    bool dimensionShiftCapability;
}

// Struct to hold all dimension states for a token
struct TokenDimensions {
    DimensionState state;
    AttributeSet attributeSet;
    VisualStage visualStage;
    uint256 energyLevel; // Stored value, calculated dynamically
    uint48 lastEnergyUpdateTime; // Timestamp for energy calculation
    TraitFlags traits;
}

// Structs to define costs for actions
struct ActionCost {
    uint256 ethCost;
    uint256 energyCost;
}

// --- Contract Definition ---
contract MultiDimNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256; // For safe arithmetic

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to its dimension states
    mapping(uint256 => TokenDimensions) private _tokenDimensions;

    // Configuration variables
    string private _baseMetadataURI;
    uint256 private _mintCost = 0.05 ether; // Example mint cost

    // Costs for dimension activation/upgrades/unlocks
    mapping(DimensionState => ActionCost) private _activationCosts;
    mapping(AttributeSet => mapping(AttributeSet => ActionCost)) private _attributeUpgradeCosts;
    mapping(VisualStage => mapping(VisualStage => ActionCost)) private _visualStageAdvanceCosts;
    mapping(Trait => ActionCost) private _traitUnlockCosts;

    // Energy system configuration
    uint256 private _energyRefillRatePerSecond = 1; // Example: 1 unit per second
    uint256 private _energyRefillCostPerUnit = 0.001 ether; // Example cost to buy energy
    uint256 private _maxEnergy = 1000; // Example max energy capacity

    // --- Events ---

    event TokenMinted(uint256 indexed tokenId, address indexed owner);
    event DimensionStateActivated(uint256 indexed tokenId, DimensionState newState, uint256 ethSpent, uint256 energySpent);
    event AttributeSetUpgraded(uint256 indexed tokenId, AttributeSet oldSet, AttributeSet newSet, uint256 ethSpent, uint256 energySpent);
    event VisualStageAdvanced(uint256 indexed tokenId, VisualStage oldStage, VisualStage newStage, uint256 ethSpent, uint256 energySpent);
    event EnergyConsumed(uint256 indexed tokenId, uint256 amount);
    event EnergyRefilled(uint256 indexed tokenId, uint256 amount, uint256 ethSpent);
    event TraitUnlocked(uint256 indexed tokenId, Trait indexed unlockedTrait, uint256 ethSpent, uint256 energySpent);
    event CostsUpdated(string costType);
    event ConfigUpdated(string configName);

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable() // Initially not paused
    {}

    // --- Core ERC721 Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Overridden to generate a dynamic URI based on token dimensions.
     * The URI format is baseURI/tokenId/state_attribute_stage_traits.
     * This requires an off-chain service to interpret the path and serve appropriate metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Standard ERC721 check
        return _generateTokenMetadataURI(tokenId, _tokenDimensions[tokenId]);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * Overridden to include ERC721 and ERC721Metadata interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Minting ---

    /**
     * @dev Mints a new MultiDimNFT token.
     * Initializes dimensions to default/Dormant states.
     * Requires a minimum mint cost.
     */
    function mint() external payable whenNotPaused returns (uint256) {
        if (msg.value < _mintCost) {
            revert InsufficientFunds({required: _mintCost, provided: msg.value});
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);

        // Initialize dimensions to default values
        _tokenDimensions[newTokenId] = TokenDimensions({
            state: DimensionState.Dormant,
            attributeSet: AttributeSet.None,
            visualStage: VisualStage.Stage1,
            energyLevel: _maxEnergy, // Start with full energy
            lastEnergyUpdateTime: uint48(block.timestamp),
            traits: TraitFlags({
                extraEnergyBoost: false,
                reducedUpgradeCost: false,
                dimensionShiftCapability: false
            })
        });

        emit TokenMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    // --- Dimension State Storage & Management (Internal Helpers) ---

    /**
     * @dev Internal helper to get a reference to the token's dimension data storage.
     */
    function _getTokenData(uint256 tokenId) internal view returns (TokenDimensions storage) {
         // ERC721 already checks existence in _requireOwned, but good practice to be safe if used elsewhere
        if (!_exists(tokenId)) {
             revert InvalidTokenId();
         }
        return _tokenDimensions[tokenId];
    }

    /**
     * @dev Internal helper to check if msg.sender is the owner of the token.
     */
    function _requireTokenOwner(uint256 tokenId) internal view {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
    }


    // --- Dynamic Metadata Generation ---

    /**
     * @dev Internal helper to construct the dynamic metadata URI.
     * Encodes key dimension states into the URI path.
     */
    function _generateTokenMetadataURI(uint256 tokenId, TokenDimensions memory dims) internal pure returns (string memory) {
        // Example format: baseURI/tokenId/state_attribute_stage_traitsHash
        bytes memory abiEncoded = abi.encodePacked(
            dims.state,
            dims.attributeSet,
            dims.visualStage,
            dims.traits.extraEnergyBoost,
            dims.traits.reducedUpgradeCost,
            dims.traits.dimensionShiftCapability
        );
        bytes32 stateHash = keccak256(abiEncoded); // Simple way to encode trait flags and ensure state changes URI

        return string(abi.encodePacked(
            _baseMetadataURI,
            tokenId.toString(),
            "/",
            uint256(dims.state).toString(),
            "_",
            uint256(dims.attributeSet).toString(),
            "_",
            uint256(dims.visualStage).toString(),
             "_",
             Bytes.toHexString(stateHash) // Use hex hash for traits/full state representation
        ));
    }

     // --- Energy System Logic ---

    /**
     * @dev Internal helper to calculate the current energy level considering time passed.
     */
    function _calculateCurrentEnergy(uint256 tokenId) internal view returns (uint256) {
        TokenDimensions storage tokenData = _tokenDimensions[tokenId];
        uint256 timeElapsed = block.timestamp - tokenData.lastEnergyUpdateTime;
        uint256 energyGained = timeElapsed.mul(_energyRefillRatePerSecond);
        return tokenData.energyLevel.add(energyGained).min(_maxEnergy);
    }

     /**
     * @dev Internal helper to update the last energy update timestamp.
     */
    function _updateLastEnergyTime(uint256 tokenId) internal {
        TokenDimensions storage tokenData = _tokenDimensions[tokenId];
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
        tokenData.energyLevel = currentEnergy;
        tokenData.lastEnergyUpdateTime = uint48(block.timestamp);
    }

    // --- Dimension Interaction Functions ---

    /**
     * @dev Activates the next Dimension State for a token.
     * Requires token ownership, payment, and energy.
     */
    function activateDimensionState(uint256 tokenId) external payable whenNotPaused {
        _requireTokenOwner(tokenId);
        TokenDimensions storage tokenData = _getTokenData(tokenId);

        DimensionState currentState = tokenData.state;
        DimensionState nextState;

        // Determine the next state
        if (currentState == DimensionState.Dormant) {
            nextState = DimensionState.Active;
        } else if (currentState == DimensionState.Active) {
            nextState = DimensionState.Enhanced;
        } else if (currentState == DimensionState.Enhanced) {
            nextState = DimensionState.Ascended;
        } else {
            revert RequirementNotMet("State is already Ascended"); // Cannot activate further
        }

        ActionCost memory cost = _activationCosts[nextState]; // Cost is based on the *target* state

        // Check requirements
        if (msg.value < cost.ethCost) {
            revert InsufficientFunds({required: cost.ethCost, provided: msg.value});
        }
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
         if (currentEnergy < cost.energyCost) {
            revert InsufficientEnergy({required: cost.energyCost, available: currentEnergy});
        }

        // Deduct costs and update state
        if (cost.ethCost > 0) {
             // Send excess Ether back
            payable(msg.sender).transfer(msg.value - cost.ethCost);
            // The required Ether stays in the contract for withdraw()
        } else {
             // If cost is 0, return all Ether
             payable(msg.sender).transfer(msg.value);
        }


        _updateLastEnergyTime(tokenId); // Update timestamp before consuming
        tokenData.energyLevel = tokenData.energyLevel.sub(cost.energyCost);
        tokenData.state = nextState;

        emit DimensionStateActivated(tokenId, nextState, cost.ethCost, cost.energyCost);
    }


    /**
     * @dev Upgrades the Attribute Set dimension for a token.
     * Requires token ownership, payment, and energy.
     * This is a simple example, real implementation would need defined upgrade paths (e.g., None -> Fire, Fire -> Water, etc.)
     * Or a system where you can choose the next set. For simplicity, this assumes a pre-configured upgrade *path*.
     */
    function upgradeAttributeSet(uint256 tokenId) external payable whenNotPaused {
         _requireTokenOwner(tokenId);
        TokenDimensions storage tokenData = _getTokenData(tokenId);

        AttributeSet currentSet = tokenData.attributeSet;
        AttributeSet nextSet; // Determine based on currentSet - example sequential upgrade
        if (currentSet == AttributeSet.None) nextSet = AttributeSet.Fire;
        else if (currentSet == AttributeSet.Fire) nextSet = AttributeSet.Water;
        else if (currentSet == AttributeSet.Water) nextSet = AttributeSet.Earth;
        else if (currentSet == AttributeSet.Earth) nextSet = AttributeSet.Air;
        else revert RequirementNotMet("Attribute Set is already Air"); // Cannot upgrade further

        ActionCost memory cost = _attributeUpgradeCosts[currentSet][nextSet];

        // Check requirements
         if (msg.value < cost.ethCost) {
            revert InsufficientFunds({required: cost.ethCost, provided: msg.value});
        }
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
         if (currentEnergy < cost.energyCost) {
            revert InsufficientEnergy({required: cost.energyCost, available: currentEnergy});
        }

        // Deduct costs and update state
         if (cost.ethCost > 0) {
            payable(msg.sender).transfer(msg.value - cost.ethCost);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

        _updateLastEnergyTime(tokenId);
        tokenData.energyLevel = tokenData.energyLevel.sub(cost.energyCost);
        tokenData.attributeSet = nextSet;

        emit AttributeSetUpgraded(tokenId, currentSet, nextSet, cost.ethCost, cost.energyCost);
    }

     /**
     * @dev Advances the Visual Stage dimension for a token.
     * Requires token ownership, payment, and energy.
     */
    function advanceVisualStage(uint256 tokenId) external payable whenNotPaused {
         _requireTokenOwner(tokenId);
        TokenDimensions storage tokenData = _getTokenData(tokenId);

        VisualStage currentStage = tokenData.visualStage;
        VisualStage nextStage;
        if (currentStage == VisualStage.Stage1) nextStage = VisualStage.Stage2;
        else if (currentStage == VisualStage.Stage2) nextStage = VisualStage.Stage3;
        else revert RequirementNotMet("Visual Stage is already Stage3"); // Cannot advance further

        ActionCost memory cost = _visualStageAdvanceCosts[currentStage][nextStage];

         // Check requirements
         if (msg.value < cost.ethCost) {
            revert InsufficientFunds({required: cost.ethCost, provided: msg.value});
        }
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
         if (currentEnergy < cost.energyCost) {
            revert InsufficientEnergy({required: cost.energyCost, available: currentEnergy});
        }

        // Deduct costs and update state
         if (cost.ethCost > 0) {
            payable(msg.sender).transfer(msg.value - cost.ethCost);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

        _updateLastEnergyTime(tokenId);
        tokenData.energyLevel = tokenData.energyLevel.sub(cost.energyCost);
        tokenData.visualStage = nextStage;

        emit VisualStageAdvanced(tokenId, currentStage, nextStage, cost.ethCost, cost.energyCost);
    }

     /**
     * @dev Consumes energy from a token's energy pool.
     * Useful for hypothetical future interactions or actions.
     * Requires token ownership.
     */
    function consumeEnergy(uint256 tokenId, uint256 amount) external whenNotPaused {
        _requireTokenOwner(tokenId);
        if (amount == 0) revert InvalidEnergyAmount();

        TokenDimensions storage tokenData = _getTokenData(tokenId);
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);

        if (currentEnergy < amount) {
            revert InsufficientEnergy({required: amount, available: currentEnergy});
        }

        _updateLastEnergyTime(tokenId); // Update before consuming
        tokenData.energyLevel = tokenData.energyLevel.sub(amount);

        emit EnergyConsumed(tokenId, amount);
    }

     /**
     * @dev Refills energy for a token by paying Ether.
     * Requires token ownership and payment.
     */
    function refillEnergy(uint256 tokenId, uint256 amount) external payable whenNotPaused {
        _requireTokenOwner(tokenId);
        if (amount == 0) revert InvalidEnergyAmount();

        TokenDimensions storage tokenData = _getTokenData(tokenId);
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);

        if (currentEnergy >= _maxEnergy) {
             revert EnergyAtMaxCapacity();
        }

        uint256 energyToAdd = amount.min(_maxEnergy.sub(currentEnergy)); // Don't add more than max capacity
        uint256 requiredCost = energyToAdd.mul(_energyRefillCostPerUnit);

        if (msg.value < requiredCost) {
            revert InsufficientFunds({required: requiredCost, provided: msg.value});
        }

        // Deduct cost and update state
        if (requiredCost > 0) {
             payable(msg.sender).transfer(msg.value - requiredCost);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

        _updateLastEnergyTime(tokenId); // Update before adding
        tokenData.energyLevel = tokenData.energyLevel.add(energyToAdd);

        emit EnergyRefilled(tokenId, energyToAdd, requiredCost);
    }

    /**
     * @dev Unlocks a specific trait for a token.
     * Requires token ownership, payment, and energy.
     * Traits are boolean flags that, once set, cannot be unset.
     */
    function unlockTrait(uint256 tokenId, Trait trait) external payable whenNotPaused {
        _requireTokenOwner(tokenId);
        TokenDimensions storage tokenData = _getTokenData(tokenId);
        ActionCost memory cost = _traitUnlockCosts[trait];

         // Check if trait is already unlocked
         if (trait == Trait.ExtraEnergyBoost && tokenData.traits.extraEnergyBoost) revert TraitAlreadyUnlocked();
         if (trait == Trait.ReducedUpgradeCost && tokenData.traits.reducedUpgradeCost) revert TraitAlreadyUnlocked();
         if (trait == Trait.DimensionShiftCapability && tokenData.traits.dimensionShiftCapability) revert TraitAlreadyUnlocked();
         // Add checks for other traits here
         if (uint256(trait) > uint256(Trait.DimensionShiftCapability)) revert InvalidTrait();


         // Check requirements
         if (msg.value < cost.ethCost) {
            revert InsufficientFunds({required: cost.ethCost, provided: msg.value});
        }
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
         if (currentEnergy < cost.energyCost) {
            revert InsufficientEnergy({required: cost.energyCost, available: currentEnergy});
        }

        // Deduct costs and update state
         if (cost.ethCost > 0) {
            payable(msg.sender).transfer(msg.value - cost.ethCost);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

        _updateLastEnergyTime(tokenId);
        tokenData.energyLevel = tokenData.energyLevel.sub(cost.energyCost);

        // Set the trait flag
        if (trait == Trait.ExtraEnergyBoost) tokenData.traits.extraEnergyBoost = true;
        else if (trait == Trait.ReducedUpgradeCost) tokenData.traits.reducedUpgradeCost = true;
        else if (trait == Trait.DimensionShiftCapability) tokenData.traits.dimensionShiftCapability = true;


        emit TraitUnlocked(tokenId, trait, cost.ethCost, cost.energyCost);
    }

    // --- Configuration & Admin Functions (Owner Only) ---

    /**
     * @dev Sets the base URI for generating dynamic metadata.
     * Only callable by the owner.
     */
    function setBaseMetadataURI(string memory baseURI) external onlyOwner {
        _baseMetadataURI = baseURI;
        emit ConfigUpdated("BaseMetadataURI");
    }

    /**
     * @dev Sets the cost to mint a new token.
     * Only callable by the owner.
     */
    function setMintCost(uint256 cost) external onlyOwner {
        _mintCost = cost;
        emit CostsUpdated("MintCost");
    }

    /**
     * @dev Sets the costs (ETH and Energy) for activating a specific Dimension State.
     * Only callable by the owner.
     */
    function setActivationCost(DimensionState state, uint256 ethCost, uint256 energyCost) external onlyOwner {
        if (state == DimensionState.Dormant) revert CannotUpgradeFromOrTo(); // Cannot set cost for Dormant as a *target* state
        _activationCosts[state] = ActionCost(ethCost, energyCost);
        emit CostsUpdated(string(abi.encodePacked("ActivationCost_", uint256(state).toString())));
    }

     /**
     * @dev Sets the costs (ETH and Energy) for upgrading between two specific Attribute Sets.
     * Only callable by the owner.
     */
    function setAttributeUpgradeCost(AttributeSet currentSet, AttributeSet nextSet, uint256 ethCost, uint256 energyCost) external onlyOwner {
        if (currentSet == nextSet) revert CannotUpgradeFromOrTo();
         if (uint256(currentSet) > uint256(AttributeSet.Air) || uint256(nextSet) > uint256(AttributeSet.Air)) revert CannotUpgradeFromOrTo(); // Basic validation
        _attributeUpgradeCosts[currentSet][nextSet] = ActionCost(ethCost, energyCost);
         emit CostsUpdated(string(abi.encodePacked("AttributeUpgradeCost_", uint256(currentSet).toString(), "_to_", uint256(nextSet).toString())));
    }

     /**
     * @dev Sets the costs (ETH and Energy) for advancing between two specific Visual Stages.
     * Only callable by the owner.
     */
    function setVisualStageAdvanceCost(VisualStage currentStage, VisualStage nextStage, uint256 ethCost, uint256 energyCost) external onlyOwner {
         if (currentStage == nextStage) revert CannotUpgradeFromOrTo();
         if (uint256(currentStage) > uint256(VisualStage.Stage3) || uint256(nextStage) > uint256(VisualStage.Stage3)) revert CannotUpgradeFromOrTo(); // Basic validation
        _visualStageAdvanceCosts[currentStage][nextStage] = ActionCost(ethCost, energyCost);
         emit CostsUpdated(string(abi.encodePacked("VisualStageAdvanceCost_", uint256(currentStage).toString(), "_to_", uint256(nextStage).toString())));
    }

     /**
     * @dev Sets the costs (ETH and Energy) for unlocking a specific Trait.
     * Only callable by the owner.
     */
    function setTraitUnlockCost(Trait trait, uint256 ethCost, uint256 energyCost) external onlyOwner {
         if (uint256(trait) > uint256(Trait.DimensionShiftCapability)) revert InvalidTrait();
        _traitUnlockCosts[trait] = ActionCost(ethCost, energyCost);
        emit CostsUpdated(string(abi.encodePacked("TraitUnlockCost_", uint256(trait).toString())));
    }

     /**
     * @dev Sets the cost per unit of energy refilled using Ether.
     * Only callable by the owner.
     */
    function setEnergyRefillCost(uint256 costPerUnit) external onlyOwner {
        _energyRefillCostPerUnit = costPerUnit;
        emit CostsUpdated("EnergyRefillCost");
    }

     /**
     * @dev Sets the energy refill rate per second.
     * Only callable by the owner.
     */
    function setEnergyRefillRate(uint256 ratePerSecond) external onlyOwner {
        _energyRefillRatePerSecond = ratePerSecond;
        emit ConfigUpdated("EnergyRefillRate");
    }

     /**
     * @dev Sets the maximum energy a token can hold.
     * Only callable by the owner.
     */
    function setMaxEnergy(uint256 maxEnergy) external onlyOwner {
        _maxEnergy = maxEnergy;
        emit ConfigUpdated("MaxEnergy");
    }

    /**
     * @dev Pauses contract actions (minting, interactions).
     * Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ConfigUpdated("Paused");
    }

    /**
     * @dev Unpauses contract actions.
     * Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ConfigUpdated("Unpaused");
    }

    /**
     * @dev Withdraws accumulated Ether from the contract balance.
     * Only callable by the owner.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();
        payable(msg.sender).transfer(balance);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current mint cost.
     */
    function getMintCost() public view returns (uint256) {
        return _mintCost;
    }

    /**
     * @dev Returns the current costs for activating a specific Dimension State.
     */
    function getActivationCost(DimensionState state) public view returns (uint256 ethCost, uint256 energyCost) {
         if (state == DimensionState.Dormant) revert CannotUpgradeFromOrTo(); // Cannot get cost for Dormant target
        ActionCost memory cost = _activationCosts[state];
        return (cost.ethCost, cost.energyCost);
    }

    /**
     * @dev Returns the current costs for upgrading between two specific Attribute Sets.
     */
    function getAttributeUpgradeCost(AttributeSet currentSet, AttributeSet nextSet) public view returns (uint256 ethCost, uint256 energyCost) {
         if (currentSet == nextSet) revert CannotUpgradeFromOrTo();
         if (uint256(currentSet) > uint256(AttributeSet.Air) || uint256(nextSet) > uint256(AttributeSet.Air)) revert CannotUpgradeFromOrTo(); // Basic validation
        ActionCost memory cost = _attributeUpgradeCosts[currentSet][nextSet];
        return (cost.ethCost, cost.energyCost);
    }

     /**
     * @dev Returns the current costs for advancing between two specific Visual Stages.
     */
    function getVisualStageAdvanceCost(VisualStage currentStage, VisualStage nextStage) public view returns (uint256 ethCost, uint256 energyCost) {
         if (currentStage == nextStage) revert CannotUpgradeFromOrTo();
          if (uint256(currentStage) > uint256(VisualStage.Stage3) || uint256(nextStage) > uint256(VisualStage.Stage3)) revert CannotUpgradeFromOrTo(); // Basic validation
        ActionCost memory cost = _visualStageAdvanceCosts[currentStage][nextStage];
        return (cost.ethCost, cost.energyCost);
    }

     /**
     * @dev Returns the current costs for unlocking a specific Trait.
     */
    function getTraitUnlockCost(Trait trait) public view returns (uint256 ethCost, uint256 energyCost) {
        if (uint256(trait) > uint256(Trait.DimensionShiftCapability)) revert InvalidTrait();
        ActionCost memory cost = _traitUnlockCosts[trait];
        return (cost.ethCost, cost.energyCost);
    }


    /**
     * @dev Returns the current cost per unit of energy refilled using Ether.
     */
    function getEnergyRefillCost() public view returns (uint256) {
        return _energyRefillCostPerUnit;
    }

     /**
     * @dev Returns the current energy refill rate per second.
     */
    function getEnergyRefillRate() public view returns (uint256) {
        return _energyRefillRatePerSecond;
    }

    /**
     * @dev Returns the maximum energy a token can hold.
     */
    function getMaxEnergy() public view returns (uint256) {
        return _maxEnergy;
    }

    /**
     * @dev Returns all dimension states for a specific token.
     * Provides a comprehensive view of the NFT's current state.
     * Note: EnergyLevel returned here is the calculated current level.
     */
    function getTokenDimensions(uint256 tokenId) public view returns (TokenDimensions memory) {
        _requireOwned(tokenId); // Ensure token exists and sender is owner/approved (standard ERC721 _requireOwned behavior)
        // Or, for public view: if (!_exists(tokenId)) revert InvalidTokenId();
        TokenDimensions storage tokenData = _tokenDimensions[tokenId];
        return TokenDimensions({
            state: tokenData.state,
            attributeSet: tokenData.attributeSet,
            visualStage: tokenData.visualStage,
            energyLevel: _calculateCurrentEnergy(tokenId), // Calculate dynamic energy
            lastEnergyUpdateTime: tokenData.lastEnergyUpdateTime,
            traits: tokenData.traits
        });
    }

    /**
     * @dev Returns the current State dimension for a token.
     */
    function getDimensionState(uint256 tokenId) public view returns (DimensionState) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenDimensions[tokenId].state;
    }

     /**
     * @dev Returns the current Attribute Set dimension for a token.
     */
    function getAttributeSet(uint256 tokenId) public view returns (AttributeSet) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenDimensions[tokenId].attributeSet;
    }

    /**
     * @dev Returns the current Visual Stage dimension for a token.
     */
    function getVisualStage(uint256 tokenId) public view returns (VisualStage) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenDimensions[tokenId].visualStage;
    }

     /**
     * @dev Returns the current calculated Energy Level for a token.
     */
    function getEnergyLevel(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _calculateCurrentEnergy(tokenId);
    }

    /**
     * @dev Returns the unlocked traits flags for a token.
     */
    function getUnlockedTraits(uint256 tokenId) public view returns (TraitFlags memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenDimensions[tokenId].traits;
    }

    // --- Receive/Fallback for Ether ---

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}

// --- Helper Library for Bytes to HexString (Needed for tokenURI) ---
library Bytes {
    function toHexString(bytes memory _bytes) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + _bytes.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < _bytes.length; i++) {
            str[2 + i * 2] = alphabet[uint8(_bytes[i] >> 4)];
            str[2 + i * 2 + 1] = alphabet[uint8(_bytes[i] & 0x0f)];
        }
        return string(str);
    }
}
```

**Explanation of Advanced/Non-Standard Parts:**

1.  **Multi-Dimensional State:** Instead of just one or two properties, the `TokenDimensions` struct holds several (`state`, `attributeSet`, `visualStage`, `energy`, `traits`). Each has its own logic and potential upgrade path.
2.  **On-chain State Storage:** The `_tokenDimensions` mapping stores the *live state* of each NFT directly on the blockchain. This is crucial for programmable behavior.
3.  **Dynamic `tokenURI`:** The `tokenURI` is overridden to build a URI based on the NFT's *current* on-chain state (`state`, `attributeSet`, `visualStage`, and a hash of traits). This forces the off-chain metadata resolver to check the current state, making the NFT truly dynamic in its representation.
4.  **Energy System:** The `energyLevel` and `lastEnergyUpdateTime` fields, combined with the `_calculateCurrentEnergy` and `_updateLastEnergyTime` helpers, implement a time-based energy regeneration system directly in the contract. Actions like `consumeEnergy` and requiring energy for upgrades integrate this system.
5.  **Progression Mechanics:** Functions like `activateDimensionState`, `upgradeAttributeSet`, `advanceVisualStage`, and `unlockTrait` are specific mechanics for evolving the NFT. They include checks for requirements (costs, energy, potentially current state) and atomic state updates.
6.  **Configurable Mechanics:** The owner can set costs (`_mintCost`, `_activationCosts`, etc.), rates (`_energyRefillRatePerSecond`), and limits (`_maxEnergy`), allowing tuning of the game/system mechanics represented by the NFT's evolution.
7.  **Custom Errors:** Using `error` statements instead of `require` with strings is a gas-efficient pattern in newer Solidity versions.
8.  **SafeMath & uint48:** Using `SafeMath` prevents overflow/underflow (though less critical in 0.8+ with default checks) and using `uint48` for timestamps is a minor gas optimization if timestamps are guaranteed to fit within that range (which they are for many years).
9.  **Structured Costs/Configs:** Using mappings with enums/structs (`_activationCosts`, `_attributeUpgradeCosts`, etc.) provides a structured way to manage complex upgrade costs based on different dimensions and stages.
10. **Clear Events:** Events are emitted for all significant state changes and configurations, making tracking easier off-chain.

This contract provides a framework for building complex, interactive NFT experiences where the NFTs are not just static collectibles but active participants in a system defined by the smart contract.