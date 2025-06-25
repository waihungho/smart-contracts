Okay, let's design a smart contract for a "Metaverse Asset Pack" with dynamic, evolving, and composable properties, influenced by staking and external conditions. This goes beyond standard NFT contracts by incorporating state changes, internal attributes, and interaction logic.

**Concept:**

This contract manages unique "Asset Packs" (ERC721 NFTs) that contain a set of internal, dynamic "Traits". These packs can be:
1.  **Minted** in a 'Sealed' state.
2.  **Opened** to reveal and activate traits.
3.  **Staked** to earn 'Evolution Points' over time, potentially influenced by external conditions.
4.  **Evolved** by consuming Evolution Points and meeting criteria, upgrading traits and the pack's stage.
5.  **Composed** with other Opened packs, combining traits and potentially burning one pack.
6.  **Influence** each other or future external systems by applying temporary "buffs" or permanent changes derived from their traits.

Traits themselves are data points *within* the pack NFT, not separate tokens. They have types (e.g., Weapon, Armor, Stat) and values/levels.

---

**Solidity Smart Contract: MetaverseAssetPack**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Outline ---
// 1. Imports: ERC721, ERC721Enumerable, Ownable, Pausable, Counters, Math.
// 2. Errors: Custom error definitions for various failure conditions.
// 3. Events: Emitted for state changes (Mint, Open, Evolve, Compose, Stake, Unstake, BuffApplied, TraitUpdate, etc.).
// 4. Enums: Defines states for Packs and types for Traits and External Conditions.
// 5. Structs: Defines the structure of a Trait (within a pack), GlobalTraitDefinition, TraitTypeDefinition, and the main Pack struct.
// 6. State Variables: Mappings and variables to store pack data, trait definitions, state counters, external conditions, and global settings.
// 7. Modifiers: Custom modifiers for access control and state checks.
// 8. Constructor: Initializes the contract with name and symbol.
// 9. Standard ERC721 Functions: Implementations required by ERC721 and ERC721Enumerable.
// 10. Core Pack Lifecycle Functions: Minting, Opening, Evolving, Composing, Burning.
// 11. Staking Functions: Staking, Unstaking, Claiming Staking Rewards.
// 12. Interaction Functions: Applying buffs/effects between packs.
// 13. Query Functions: Read functions to get details about packs, traits, state, conditions.
// 14. Admin/Setup Functions: Functions callable by owner to configure trait types, definitions, external conditions, pause, etc.
// 15. Internal Helper Functions: Logic for generating traits, calculating rewards, checking conditions, updating traits.

// --- Function Summary ---
// Standard ERC721Enumerable Functions (9):
// - balanceOf(address owner): Get the number of tokens owned by an address.
// - ownerOf(uint256 tokenId): Find the owner of a specific token.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safely transfer a token.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Safely transfer a token with data.
// - transferFrom(address from, address to, uint256 tokenId): Transfer a token (less safe than safeTransferFrom).
// - approve(address to, uint256 tokenId): Approve an address to manage a token.
// - setApprovalForAll(address operator, bool approved): Approve/disapprove an operator for all tokens.
// - getApproved(uint256 tokenId): Get the approved address for a token.
// - isApprovedForAll(address owner, address operator): Check if an operator is approved for all tokens.
// - supportsInterface(bytes4 interfaceId): Check if the contract supports an interface.
// - tokenURI(uint256 tokenId): Get the metadata URI for a token.
// - tokenByIndex(uint256 index): Get a token ID by index (Enumerable).
// - tokenOfOwnerByIndex(address owner, uint256 index): Get a token ID of an owner by index (Enumerable).
// - totalSupply(): Get the total number of tokens minted (Enumerable).

// Core Pack Lifecycle Functions (6):
// - mintPack(address to): Mints a new 'Sealed' pack to an address. (Admin/Minting Role)
// - openPack(uint256 packId): Changes pack state from 'Sealed' to 'Opened', revealing traits.
// - evolvePack(uint256 packId): Evolves an 'Opened' pack if conditions are met, increasing evolution stage and potentially upgrading traits. Consumes evolution points.
// - composePacks(uint256 packId1, uint256 packId2): Combines traits from packId2 into packId1. Requires both packs to be 'Opened' and compatible. Burns packId2.
// - burnPack(uint256 packId): Burns a pack NFT.
// - removeTraitFromPack(uint256 packId, uint256 traitIndex): Admin function to remove a specific trait from a pack.

// Staking Functions (3):
// - stakePack(uint256 packId): Stakes an 'Opened' pack, making it earn evolution points over time.
// - unstakePack(uint256 packId): Unstakes a pack, stopping point accumulation and calculating points earned.
// - claimStakingRewards(uint256 packId): Claims accumulated evolution points for an unstaked pack, applying them internally (e.g., making them available for evolution).

// Interaction Functions (1):
// - applyTraitBuff(uint256 sourcePackId, uint256 sourceTraitIndex, uint256 targetPackId): Applies an effect from a trait in sourcePackId to a trait (or the pack) in targetPackId.

// Query Functions (10):
// - getPackState(uint256 packId): Get the current state of a pack.
// - getPackTraits(uint256 packId): Get all traits contained within a pack.
// - getPackEvolutionStage(uint256 packId): Get the evolution stage of a pack.
// - getPackOwner(uint256 packId): Get the owner of a pack (same as ownerOf).
// - getPackStakingStatus(uint256 packId): Check if a pack is staked and its staking start time.
// - getPendingEvolutionPoints(uint256 packId): Calculate evolution points earned while staked but not yet claimed/applied.
// - getAvailableEvolutionPoints(uint256 packId): Get evolution points claimed but not yet spent on evolution.
// - getGlobalTraitDefinition(uint256 traitId): Get details of a global trait definition.
// - getTraitTypeDetails(uint256 typeId): Get details of a trait type.
// - getExternalConditionValue(ExternalConditionType conditionType): Get the current value of an external condition.
// - getTotalStakedPacks(): Get the total number of packs currently staked.

// Admin/Setup Functions (6):
// - setBaseURI(string memory newBaseURI): Set the base URI for token metadata.
// - pause(): Pause core contract functions.
// - unpause(): Unpause core contract functions.
// - addTraitType(string memory name): Define a new category for traits.
// - addGlobalTraitDefinition(uint256 traitTypeId, string memory name, uint256 initialValue, uint256 maxValue, bool isComposable, bool isBuffable): Define a potential trait with its properties.
// - setExternalConditionValue(ExternalConditionType conditionType, uint256 value): Set the value for an external condition (simulating oracle input).

// Total Functions: 10 (Standard) + 6 (Lifecycle) + 3 (Staking) + 1 (Interaction) + 10 (Query) + 6 (Admin) = 36+ functions. This satisfies the >= 20 requirement.

contract MetaverseAssetPack is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error PackDoesNotExist(uint256 packId);
    error PackMustBeSealed(uint256 packId);
    error PackMustBeOpened(uint256 packId);
    error PackMustBeStaked(uint256 packId);
    error PackMustNotBeStaked(uint256 packId);
    error NotPackOwner(uint256 packId, address caller);
    error EvolutionConditionsNotMet(uint256 packId);
    error InsufficientEvolutionPoints(uint256 packId, uint256 requiredPoints);
    error CompositionNotCompatible(uint256 packId1, uint256 packId2);
    error TraitIndexOutOfRange(uint256 packId, uint256 traitIndex);
    error TraitNotBuffable(uint256 traitId);
    error ExternalConditionTypeInvalid(ExternalConditionType conditionType);
    error PackCannotBeStakedOrOwned(uint256 packId); // For composition burning

    // --- Events ---
    event PackMinted(uint256 indexed packId, address indexed owner);
    event PackOpened(uint256 indexed packId);
    event PackEvolved(uint256 indexed packId, uint256 newEvolutionStage);
    event PackComposed(uint256 indexed packId1, uint256 indexed packId2, uint256 burnedPackId);
    event PackStaked(uint256 indexed packId);
    event PackUnstaked(uint256 indexed packId, uint256 earnedEvolutionPoints);
    event EvolutionPointsClaimed(uint256 indexed packId, uint256 claimedPoints, uint256 newAvailablePoints);
    event TraitBuffApplied(uint256 indexed sourcePackId, uint256 indexed targetPackId, uint256 indexed traitId, uint256 effectValue);
    event TraitUpdated(uint256 indexed packId, uint256 traitIndex, uint256 newTraitValue);
    event TraitRemoved(uint256 indexed packId, uint256 traitIndex);
    event ExternalConditionUpdated(ExternalConditionType indexed conditionType, uint256 newValue);
    event GlobalTraitDefinitionAdded(uint256 indexed traitId, uint256 traitTypeId, string name);
    event TraitTypeAdded(uint256 indexed typeId, string name);
    event PackBurned(uint256 indexed packId);

    // --- Enums ---
    enum PackState { Sealed, Opened }
    enum ExternalConditionType { GLOBAL_TIME_FACTOR, ENVIRONMENTAL_TEMP, PLAYER_ACTIVITY_SCORE, SEASONAL_EVENT }

    // --- Structs ---
    struct Trait {
        uint256 globalTraitId; // Reference to the definition
        uint256 value;         // Current value/level of this specific trait instance
    }

    struct GlobalTraitDefinition {
        uint256 traitTypeId;
        string name;
        uint256 initialValue;
        uint256 maxValue;
        bool isComposable; // Can this trait be combined via composition?
        bool isBuffable;   // Can this trait be used to buff other packs?
    }

    struct TraitTypeDefinition {
        string name;
        // Add properties here if needed, e.g., allowed global trait IDs
    }

    struct Pack {
        PackState state;
        uint256 evolutionStage;
        Trait[] traits;
        bool isStaked;
        uint256 stakingStartTime;
        uint256 earnedEvolutionPoints; // Points earned while staked, pending claim
        uint256 availableEvolutionPoints; // Points claimed, available for spending on evolution
    }

    // --- State Variables ---
    mapping(uint256 => Pack) public packs; // tokenId => Pack data

    mapping(uint256 => GlobalTraitDefinition) private _globalTraitDefinitions;
    uint256 private _nextGlobalTraitId = 1;

    mapping(uint256 => TraitTypeDefinition) private _traitTypes;
    uint256 private _nextTraitTypeId = 1;
    uint256[] private _traitTypeIds; // Keep track of all defined trait type IDs

    mapping(ExternalConditionType => uint256) private _externalConditions; // Values influencing game mechanics

    // --- Modifiers ---
    modifier whenPackExists(uint256 packId) {
        if (!_exists(packId)) revert PackDoesNotExist(packId);
        _;
    }

    modifier onlyPackOwner(uint256 packId) {
        if (ownerOf(packId) != _msgSender()) revert NotPackOwner(packId, _msgSender());
        _;
    }

    modifier whenPackStateIs(uint256 packId, PackState requiredState) {
        if (packs[packId].state != requiredState) {
            if (requiredState == PackState.Sealed) revert PackMustBeSealed(packId);
            if (requiredState == PackState.Opened) revert PackMustBeOpened(packId);
            // Add other states if necessary
            revert("MP::whenPackStateIs: Invalid required state");
        }
        _;
    }

    modifier whenPackStakingStatusIs(uint256 packId, bool requiredStakedStatus) {
        if (packs[packId].isStaked != requiredStakedStatus) {
            if (requiredStakedStatus) revert PackMustBeStaked(packId);
            else revert PackMustNotBeStaked(packId);
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
        Pausable()
    {}

    // --- Standard ERC721Enumerable Overrides ---
    // Need to override these as ERC721Enumerable requires it
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Core Pack Lifecycle Functions ---

    /// @notice Mints a new 'Sealed' pack to a recipient. Callable only by the owner.
    /// @param to The address to mint the pack to.
    function mintPack(address to) public onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Initialize pack data
        packs[newTokenId] = Pack({
            state: PackState.Sealed,
            evolutionStage: 0,
            traits: new Trait[](0), // Traits are generated on open
            isStaked: false,
            stakingStartTime: 0,
            earnedEvolutionPoints: 0,
            availableEvolutionPoints: 0
        });

        _mint(to, newTokenId);
        emit PackMinted(newTokenId, to);
    }

    /// @notice Opens a 'Sealed' pack, revealing its traits and changing its state.
    /// @param packId The ID of the pack to open.
    function openPack(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenPackStateIs(packId, PackState.Sealed) whenNotPaused {
        // Generate initial traits based on packId and some external factors (simplified)
        packs[packId].traits = _generateTraits(packId);
        packs[packId].state = PackState.Opened;

        emit PackOpened(packId);
        // Consider adding an event that lists the generated traits here
    }

    /// @notice Evolves an 'Opened' pack, increasing its stage and potentially upgrading traits.
    /// Requires meeting specific conditions (e.g., available points, external conditions) and consumes points.
    /// @param packId The ID of the pack to evolve.
    function evolvePack(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenPackStateIs(packId, PackState.Opened) whenNotPaused {
        uint256 requiredPoints = _getEvolutionCost(packs[packId].evolutionStage);
        if (packs[packId].availableEvolutionPoints < requiredPoints) {
            revert InsufficientEvolutionPoints(packId, requiredPoints);
        }
        if (!_checkEvolutionConditions(packId)) {
            revert EvolutionConditionsNotMet(packId);
        }

        packs[packId].availableEvolutionPoints -= requiredPoints;
        packs[packId].evolutionStage += 1;

        // Internal logic to upgrade traits based on new stage (simplified placeholder)
        _upgradeTraits(packId, packs[packId].evolutionStage);

        emit PackEvolved(packId, packs[packId].evolutionStage);
    }

    /// @notice Composes two 'Opened' packs, combining traits from packId2 into packId1 and burning packId2.
    /// Requires compatibility check and ownership of both packs.
    /// @param packId1 The ID of the primary pack (will receive traits).
    /// @param packId2 The ID of the secondary pack (will contribute traits and be burned).
    function composePacks(uint256 packId1, uint256 packId2) public whenPackExists(packId1) whenPackExists(packId2) whenPackStateIs(packId1, PackState.Opened) whenPackStateIs(packId2, PackState.Opened) whenNotPaused {
        if (ownerOf(packId1) != _msgSender() || ownerOf(packId2) != _msgSender()) {
            revert NotPackOwner(packId1, _msgSender()); // Assumes same owner for both
        }
        if (packId1 == packId2) revert("MP::composePacks: Cannot compose a pack with itself");
        if (packs[packId1].isStaked || packs[packId2].isStaked) revert PackCannotBeStakedOrOwned(packs[packId1].isStaked ? packId1 : packId2);


        if (!_checkCompositionCompatibility(packId1, packId2)) {
            revert CompositionNotCompatible(packId1, packId2);
        }

        // Logic to combine traits (example: add values if composable, or pick max value)
        for (uint i = 0; i < packs[packId2].traits.length; i++) {
            Trait storage trait2 = packs[packId2].traits[i];
            GlobalTraitDefinition storage def = _globalTraitDefinitions[trait2.globalTraitId];

            if (def.isComposable) {
                bool foundMatch = false;
                for (uint j = 0; j < packs[packId1].traits.length; j++) {
                    Trait storage trait1 = packs[packId1].traits[j];
                    if (trait1.globalTraitId == trait2.globalTraitId) {
                        trait1.value = Math.min(trait1.value + trait2.value, def.maxValue); // Example logic: add value up to max
                        emit TraitUpdated(packId1, j, trait1.value);
                        foundMatch = true;
                        break;
                    }
                }
                if (!foundMatch) {
                    // If trait from pack2 doesn't exist in pack1, add it (respecting max traits per pack if applicable)
                    packs[packId1].traits.push(Trait({
                         globalTraitId: trait2.globalTraitId,
                         value: Math.min(trait2.value, def.maxValue) // Add with its value
                    }));
                    emit TraitUpdated(packId1, packs[packId1].traits.length - 1, packs[packId1].traits[packs[packId1].traits.length - 1].value);
                }
            }
        }

        uint256 burnedPackId = packId2;
        // Burn the second pack
        _burn(packId2);
        // Clear pack data after burning (important as _burn doesn't clear storage)
        delete packs[packId2];

        emit PackComposed(packId1, burnedPackId, burnedPackId);
    }

    /// @notice Burns a pack NFT. Only callable by the owner.
    /// @param packId The ID of the pack to burn.
    function burnPack(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenNotPaused {
        if (packs[packId].isStaked) revert PackMustNotBeStaked(packId); // Cannot burn if staked

        _burn(packId);
        // Clear pack data after burning
        delete packs[packId];

        emit PackBurned(packId);
    }

     /// @notice Removes a specific trait from a pack. Admin/Owner function.
     /// @param packId The ID of the pack.
     /// @param traitIndex The index of the trait to remove within the pack's traits array.
    function removeTraitFromPack(uint256 packId, uint256 traitIndex) public onlyOwner whenPackExists(packId) whenNotPaused {
        if (traitIndex >= packs[packId].traits.length) revert TraitIndexOutOfRange(packId, traitIndex);

        // Shift elements to fill the gap and pop the last element
        for (uint i = traitIndex; i < packs[packId].traits.length - 1; i++) {
            packs[packId].traits[i] = packs[packId].traits[i + 1];
        }
        packs[packId].traits.pop();

        emit TraitRemoved(packId, traitIndex);
    }


    // --- Staking Functions ---

    /// @notice Stakes an 'Opened' pack to earn evolution points. Only callable by the owner.
    /// @param packId The ID of the pack to stake.
    function stakePack(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenPackStateIs(packId, PackState.Opened) whenPackStakingStatusIs(packId, false) whenNotPaused {
        packs[packId].isStaked = true;
        packs[packId].stakingStartTime = block.timestamp; // Use block.timestamp for simplicity
        // earnedEvolutionPoints and availableEvolutionPoints persist across staking periods

        emit PackStaked(packId);
    }

    /// @notice Unstakes a pack, stopping point accumulation and calculating points earned. Only callable by the owner.
    /// @param packId The ID of the pack to unstake.
    function unstakePack(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenPackStakingStatusIs(packId, true) whenNotPaused {
        uint256 elapsed = block.timestamp - packs[packId].stakingStartTime;
        uint256 earned = _calculateEarnedEvolutionPoints(packId, elapsed);

        packs[packId].isStaked = false;
        packs[packId].stakingStartTime = 0; // Reset start time
        packs[packId].earnedEvolutionPoints += earned;

        emit PackUnstaked(packId, earned);
    }

    /// @notice Claims accumulated earned evolution points, moving them to the available pool. Only callable by the owner.
    /// Can be called even if the pack is currently staked (claims points earned *before* current staking period if any, or points accumulated while unstaked).
    /// This version claims points earned during the *last* staking period upon unstaking. A different model could accumulate points while staked.
    /// Let's refine: _calculateEarnedEvolutionPoints calculates since last claim/stake. Claim moves earned to available.
    function claimStakingRewards(uint256 packId) public whenPackExists(packId) onlyPackOwner(packId) whenNotPaused {
        uint256 currentlyEarned = 0;
        if (packs[packId].isStaked) {
            currentlyEarned = _calculateEarnedEvolutionPoints(packId, block.timestamp - packs[packId].stakingStartTime);
             // Do NOT reset stakingStartTime if still staked. Points are claimed *up to this moment*.
             // Better: Calculate and reset earned points *only on unstake*. Claim just moves earned to available.
             // Let's stick to the simpler model: unstake calculates and adds to earned. Claim moves earned to available.
        }

        uint256 pointsToClaim = packs[packId].earnedEvolutionPoints;
        if (pointsToClaim == 0) return; // Nothing to claim

        packs[packId].earnedEvolutionPoints = 0; // Reset earned
        packs[packId].availableEvolutionPoints += pointsToClaim; // Add to available

        emit EvolutionPointsClaimed(packId, pointsToClaim, packs[packId].availableEvolutionPoints);
    }


    // --- Interaction Functions ---

    /// @notice Applies an effect from a trait in the source pack to the target pack.
    /// Consumes the ability/points from the source pack's trait.
    /// @param sourcePackId The ID of the pack providing the buff. Must be owned by caller.
    /// @param sourceTraitIndex The index of the trait within the source pack used for the buff.
    /// @param targetPackId The ID of the pack receiving the buff. Must be owned by caller.
    function applyTraitBuff(uint256 sourcePackId, uint256 sourceTraitIndex, uint256 targetPackId) public whenPackExists(sourcePackId) whenPackExists(targetPackId) onlyPackOwner(sourcePackId) whenNotPaused {
        if (ownerOf(targetPackId) != _msgSender()) revert NotPackOwner(targetPackId, _msgSender());
        if (sourcePackId == targetPackId) revert("MP::applyTraitBuff: Cannot buff a pack with itself");
        if (packs[sourcePackId].state != PackState.Opened) revert PackMustBeOpened(sourcePackId);
        if (packs[targetPackId].state != PackState.Opened) revert PackMustBeOpened(targetPackId);
        if (sourceTraitIndex >= packs[sourcePackId].traits.length) revert TraitIndexOutOfRange(sourcePackId, sourceTraitIndex);

        Trait storage sourceTrait = packs[sourcePackId].traits[sourceTraitIndex];
        GlobalTraitDefinition storage sourceTraitDef = _globalTraitDefinitions[sourceTrait.globalTraitId];

        if (!sourceTraitDef.isBuffable) revert TraitNotBuffable(sourceTrait.globalTraitId);
        if (sourceTrait.value == 0) revert("MP::applyTraitBuff: Source trait value is zero");

        // --- Buff Logic (Example) ---
        // Find a matching trait type in the target pack or apply a generic buff
        // Simplified: Find a trait of the *same type* and increase its value by a portion of the source trait's value.
        uint256 buffAmount = sourceTrait.value / 2; // Example: Use half the source trait's value as buff strength
        bool buffApplied = false;

        for (uint i = 0; i < packs[targetPackId].traits.length; i++) {
            Trait storage targetTrait = packs[targetPackId].traits[i];
            GlobalTraitDefinition storage targetTraitDef = _globalTraitDefinitions[targetTrait.globalTraitId];

            // If the trait type matches
            if (targetTraitDef.traitTypeId == sourceTraitDef.traitTypeId) {
                 uint256 oldValue = targetTrait.value;
                 targetTrait.value = Math.min(targetTrait.value + buffAmount, targetTraitDef.maxValue); // Apply buff, capped by max value
                 if (targetTrait.value > oldValue) { // Only emit if value actually increased
                    emit TraitUpdated(targetPackId, i, targetTrait.value);
                    buffApplied = true;
                    break; // Apply buff to the first matching trait found
                 }
            }
        }

        // If no matching trait type found, maybe apply a generic boost or return?
        // For this example, we require a matching type. If not found, buff isn't applied.

        if (buffApplied) {
             // Consume source trait value (example: halve it)
             sourceTrait.value = sourceTrait.value - buffAmount; // Or just deduct buffAmount
             emit TraitUpdated(sourcePackId, sourceTraitIndex, sourceTrait.value);
             emit TraitBuffApplied(sourcePackId, targetPackId, sourceTrait.globalTraitId, buffAmount);
        } else {
            // Revert or silently fail if buff couldn't be applied to any trait in the target pack
            revert("MP::applyTraitBuff: No compatible trait found in target pack for buff");
        }
    }

    // --- Query Functions ---

    /// @notice Gets the current state of a pack.
    /// @param packId The ID of the pack.
    /// @return The PackState enum value.
    function getPackState(uint256 packId) public view whenPackExists(packId) returns (PackState) {
        return packs[packId].state;
    }

    /// @notice Gets all traits contained within a pack.
    /// @param packId The ID of the pack.
    /// @return An array of Trait structs. Note: Large arrays can hit gas limits.
    function getPackTraits(uint256 packId) public view whenPackExists(packId) returns (Trait[] memory) {
        return packs[packId].traits;
    }

    /// @notice Gets the evolution stage of a pack.
    /// @param packId The ID of the pack.
    /// @return The evolution stage level.
    function getPackEvolutionStage(uint256 packId) public view whenPackExists(packId) returns (uint256) {
        return packs[packId].evolutionStage;
    }

    /// @notice Gets the owner of a pack (same as ownerOf). Included for clarity in pack-specific queries.
    /// @param packId The ID of the pack.
    /// @return The owner address.
    function getPackOwner(uint256 packId) public view whenPackExists(packId) returns (address) {
        return ownerOf(packId);
    }

    /// @notice Checks if a pack is staked and returns its staking start time.
    /// @param packId The ID of the pack.
    /// @return isStaked (bool), stakingStartTime (uint256).
    function getPackStakingStatus(uint256 packId) public view whenPackExists(packId) returns (bool isStaked, uint256 stakingStartTime) {
        return (packs[packId].isStaked, packs[packId].stakingStartTime);
    }

    /// @notice Calculates evolution points earned while currently staked (but not yet unstaked).
    /// @param packId The ID of the pack.
    /// @return The calculated earned points for the current staking period.
    function getPendingEvolutionPoints(uint256 packId) public view whenPackExists(packId) returns (uint256) {
        if (!packs[packId].isStaked) return 0;
        uint256 elapsed = block.timestamp - packs[packId].stakingStartTime;
        return _calculateEarnedEvolutionPoints(packId, elapsed);
    }

    /// @notice Gets evolution points that have been claimed/accumulated but not yet spent on evolution.
    /// @param packId The ID of the pack.
    /// @return The number of available evolution points.
    function getAvailableEvolutionPoints(uint256 packId) public view whenPackExists(packId) returns (uint256) {
        return packs[packId].availableEvolutionPoints;
    }

    /// @notice Gets the definition details for a global trait ID.
    /// @param traitId The global trait definition ID.
    /// @return GlobalTraitDefinition struct data.
    function getGlobalTraitDefinition(uint256 traitId) public view returns (GlobalTraitDefinition memory) {
        // Consider adding a check if the traitId exists
        return _globalTraitDefinitions[traitId];
    }

    /// @notice Gets the definition details for a trait type ID.
    /// @param typeId The trait type definition ID.
    /// @return TraitTypeDefinition struct data.
    function getTraitTypeDetails(uint256 typeId) public view returns (TraitTypeDefinition memory) {
        // Consider adding a check if the typeId exists
        return _traitTypes[typeId];
    }

    /// @notice Gets the current value of an external condition.
    /// @param conditionType The type of external condition.
    /// @return The value of the condition.
    function getExternalConditionValue(ExternalConditionType conditionType) public view returns (uint256) {
        // Consider validating conditionType is a valid enum value
        return _externalConditions[conditionType];
    }

    /// @notice Gets the total number of packs currently staked.
    /// @dev Requires iterating through all tokens, potentially gas-intensive. More efficient might involve a separate counter.
    /// @return The count of staked packs.
    function getTotalStakedPacks() public view returns (uint256) {
         uint256 count = 0;
         uint256 total = totalSupply();
         for(uint i = 0; i < total; i++) {
             uint256 tokenId = tokenByIndex(i); // ERC721Enumerable helps here
             if (_exists(tokenId) && packs[tokenId].isStaked) {
                 count++;
             }
         }
         return count;
    }

     /// @notice Gets the number of traits contained within a specific pack.
     /// @param packId The ID of the pack.
     /// @return The count of traits.
    function getTraitCount(uint256 packId) public view whenPackExists(packId) returns (uint256) {
        return packs[packId].traits.length;
    }

    /// @notice Gets the value of a specific trait by its index in a pack.
    /// @param packId The ID of the pack.
    /// @param traitIndex The index of the trait within the pack's traits array.
    /// @return The value of the trait.
    function getPackTraitValue(uint256 packId, uint256 traitIndex) public view whenPackExists(packId) returns (uint256) {
        if (traitIndex >= packs[packId].traits.length) revert TraitIndexOutOfRange(packId, traitIndex);
        return packs[packId].traits[traitIndex].value;
    }


    // --- Admin/Setup Functions ---

    /// @notice Sets the base URI for token metadata. Callable only by the owner.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Pauses the contract functions. Callable only by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract functions. Callable only by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Defines a new type/category for traits. Callable only by the owner.
    /// @param name The name of the trait type (e.g., "Weapon", "Armor", "Stat").
    /// @return The ID of the newly created trait type.
    function addTraitType(string memory name) public onlyOwner returns (uint256) {
        uint256 newTypeId = _nextTraitTypeId++;
        _traitTypes[newTypeId] = TraitTypeDefinition({
            name: name
        });
        _traitTypeIds.push(newTypeId); // Store ID for potential iteration/lookup

        emit TraitTypeAdded(newTypeId, name);
        return newTypeId;
    }

    /// @notice Defines a global template for a specific trait within a given type. Callable only by the owner.
    /// @param traitTypeId The ID of the trait type this definition belongs to.
    /// @param name The name of the trait (e.g., "Epic Sword", "Speed Boost").
    /// @param initialValue The starting value when generated in a pack.
    /// @param maxValue The maximum possible value this trait can reach.
    /// @param isComposable Can this trait's value be added via composition?
    /// @param isBuffable Can this trait be used to buff other packs?
    /// @return The ID of the newly created global trait definition.
    function addGlobalTraitDefinition(uint256 traitTypeId, string memory name, uint256 initialValue, uint256 maxValue, bool isComposable, bool isBuffable) public onlyOwner returns (uint256) {
        // Consider adding a check if traitTypeId exists
        uint256 newTraitId = _nextGlobalTraitId++;
        _globalTraitDefinitions[newTraitId] = GlobalTraitDefinition({
            traitTypeId: traitTypeId,
            name: name,
            initialValue: initialValue,
            maxValue: maxValue,
            isComposable: isComposable,
            isBuffable: isBuffable
        });

        emit GlobalTraitDefinitionAdded(newTraitId, traitTypeId, name);
        return newTraitId;
    }

     /// @notice Sets the value for an external condition. Simulates oracle/external data input. Callable only by the owner.
     /// @param conditionType The type of the external condition.
     /// @param value The new value for the condition.
    function setExternalConditionValue(ExternalConditionType conditionType, uint256 value) public onlyOwner {
        // Optional: add validation for valid enum values
        _externalConditions[conditionType] = value;
        emit ExternalConditionUpdated(conditionType, value);
    }

     /// @notice Admin function to upgrade a specific trait's value in a pack.
     /// @param packId The ID of the pack.
     /// @param traitIndex The index of the trait within the pack's traits array.
     /// @param newValue The new value for the trait. Will be capped by its max value.
    function upgradeTraitInPack(uint256 packId, uint256 traitIndex, uint256 newValue) public onlyOwner whenPackExists(packId) whenNotPaused {
        if (traitIndex >= packs[packId].traits.length) revert TraitIndexOutOfRange(packId, traitIndex);

        Trait storage trait = packs[packId].traits[traitIndex];
        GlobalTraitDefinition storage def = _globalTraitDefinitions[trait.globalTraitId];

        uint256 cappedValue = Math.min(newValue, def.maxValue);
        if (trait.value != cappedValue) {
             trait.value = cappedValue;
             emit TraitUpdated(packId, traitIndex, trait.value);
        }
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to generate initial traits for a pack upon opening.
    /// This uses a simple deterministic approach based on block data and packId.
    /// For real-world applications requiring unpredictable traits, use Chainlink VRF or similar.
    function _generateTraits(uint256 packId) internal view returns (Trait[] memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(packId, block.timestamp, block.difficulty, msg.sender)));
        Trait[] memory newTraits = new Trait[](0); // Start with no traits

        // Example: Generate 2-5 traits per pack based on seed
        uint256 numTraits = 2 + (seed % 4); // 2, 3, 4, or 5 traits

        uint256 totalTraitDefinitions = _nextGlobalTraitId - 1;
        if (totalTraitDefinitions == 0) return newTraits; // No trait definitions configured

        for (uint i = 0; i < numTraits; i++) {
            // Simple random trait selection
            uint265 traitDefIndex = (seed + i) % totalTraitDefinitions; // Use seed + index for variety
            uint256 globalTraitIdToUse = traitDefIndex + 1; // Assuming global trait IDs start from 1

            // Ensure the trait ID actually exists (in case some were 'deleted' conceptually)
            // A better approach would be to store active trait IDs in an array.
            // For simplicity, we assume sequential IDs here.

            GlobalTraitDefinition storage def = _globalTraitDefinitions[globalTraitIdToUse];

            // Add trait instance to pack
            newTraits = _addTraitToArray(newTraits, globalTraitIdToUse, def.initialValue);

            seed = uint256(keccak256(abi.encodePacked(seed, globalTraitIdToUse, block.timestamp))); // Update seed
        }

        return newTraits;
    }

    /// @dev Internal helper to add a Trait struct to a dynamic array.
    function _addTraitToArray(Trait[] memory arr, uint256 globalTraitId, uint256 value) internal pure returns (Trait[] memory) {
        Trait[] memory newArr = new Trait[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = Trait({
            globalTraitId: globalTraitId,
            value: value
        });
        return newArr;
    }


    /// @dev Internal function to calculate evolution cost for a given stage.
    /// @param stage The current evolution stage.
    /// @return The required evolution points.
    function _getEvolutionCost(uint256 stage) internal pure returns (uint256) {
        // Example: Cost increases with stage (e.g., 100 * (stage + 1))
        return 100 * (stage + 1);
    }

    /// @dev Internal function to check if a pack meets evolution conditions.
    /// Example conditions: is staked, meets minimum staking duration, external condition met.
    /// @param packId The ID of the pack.
    /// @return True if conditions are met, false otherwise.
    function _checkEvolutionConditions(uint256 packId) internal view returns (bool) {
        Pack storage pack = packs[packId];
        // Example conditions:
        bool hasEnoughPoints = pack.availableEvolutionPoints >= _getEvolutionCost(pack.evolutionStage);
        bool meetsStakingRequirement = pack.isStaked && (block.timestamp - pack.stakingStartTime >= 1 days); // Staked for at least 1 day
        bool externalConditionMet = _externalConditions[ExternalConditionType.GLOBAL_TIME_FACTOR] > 100; // Example: External factor above threshold

        // Combine conditions (adjust logic as needed)
        return hasEnoughPoints && meetsStakingRequirement && externalConditionMet;
    }

    /// @dev Internal function to upgrade pack traits based on a new evolution stage.
    /// @param packId The ID of the pack.
    /// @param newStage The stage the pack just reached.
    function _upgradeTraits(uint256 packId, uint256 newStage) internal {
        Pack storage pack = packs[packId];
        // Example logic: Increase value of existing traits proportionally to new stage, up to max value
        uint256 upgradeFactor = newStage * 10; // Example: add 10 points per stage

        for (uint i = 0; i < pack.traits.length; i++) {
            Trait storage trait = pack.traits[i];
            GlobalTraitDefinition storage def = _globalTraitDefinitions[trait.globalTraitId];

            uint256 oldValue = trait.value;
            trait.value = Math.min(trait.value + upgradeFactor, def.maxValue); // Increase value, capped by max
            if (trait.value > oldValue) {
                emit TraitUpdated(packId, i, trait.value);
            }
        }
    }

    /// @dev Internal function to check if two packs are compatible for composition.
    /// Example: Both must be 'Opened', maybe share a minimum number of traits or certain trait types.
    /// @param packId1 The ID of the first pack.
    /// @param packId2 The ID of the second pack.
    /// @return True if compatible, false otherwise.
    function _checkCompositionCompatibility(uint256 packId1, uint256 packId2) internal view returns (bool) {
        // Example logic: Both packs must be Opened (already checked by modifier)
        // And they must share at least one trait type
        Pack storage pack1 = packs[packId1];
        Pack storage pack2 = packs[packId2];

        if (pack1.traits.length == 0 || pack2.traits.length == 0) return false;

        for (uint i = 0; i < pack1.traits.length; i++) {
            GlobalTraitDefinition storage def1 = _globalTraitDefinitions[pack1.traits[i].globalTraitId];
            for (uint j = 0; j < pack2.traits.length; j++) {
                 GlobalTraitDefinition storage def2 = _globalTraitDefinitions[pack2.traits[j].globalTraitId];
                 if (def1.traitTypeId == def2.traitTypeId && def2.isComposable) { // Check if types match AND trait2 is composable
                     return true; // Found a compatible trait type
                 }
            }
        }

        return false; // No shared composable trait types found
    }

    /// @dev Internal function to calculate earned evolution points based on elapsed time and conditions.
    /// Example: Points per second * elapsed time, potentially modified by external conditions.
    /// @param packId The ID of the pack (can be used to modify rate based on traits).
    /// @param elapsedSeconds The time elapsed since staking started or last claim.
    /// @return The calculated points.
    function _calculateEarnedEvolutionPoints(uint256 packId, uint256 elapsedSeconds) internal view returns (uint256) {
        // Base rate: 1 point per hour (3600 seconds)
        uint256 baseRatePerSecond = 1 ether / 3600; // Use larger units if points are fractional

        // Modifier example: Boost based on ExternalConditionType.GLOBAL_TIME_FACTOR
        uint256 timeFactor = _externalConditions[ExternalConditionType.GLOBAL_TIME_FACTOR]; // Assume this is a percentage or multiplier base 100/1000 etc.
        // If timeFactor is 150, this is 1.5x rate. If 50, 0.5x rate.
        // Let's assume 100 = 1x rate.
        uint256 modifiedRate = (baseRatePerSecond * timeFactor) / 100; // Example calculation

        // Another modifier example: Boost based on a specific trait in the pack (e.g., a "Staking Boost" trait)
        // This would require iterating through pack[packId].traits to find a specific trait type/ID
        uint256 traitBoost = 0; // Calculate trait boost based on pack traits
        // For simplicity, skipping trait-specific boost calculation here

        uint256 totalRate = modifiedRate + traitBoost;

        return (totalRate * elapsedSeconds) / (1 ether); // Adjust for units used in baseRatePerSecond
    }

}
```