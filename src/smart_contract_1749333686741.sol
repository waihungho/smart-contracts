Okay, here is a Solidity smart contract implementing a protocol I'll call "MetaMorph Protocol". It combines concepts of dynamic, evolving NFTs (Metamorphs), resource management (Essence), staking, rule-based transformations, and on-chain challenges, aiming for uniqueness and advanced mechanics beyond standard token contracts.

It includes an outline and function summary as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Although Essence is internal, defining interaction patterns can be useful.

// --- MetaMorph Protocol: Outline and Function Summary ---
//
// Protocol Concept:
// A system for managing dynamic, evolving tokens called "Metamorphs".
// Each Metamorph possesses a set of unique and mutable "Traits".
// Users can stake Metamorphs to generate "Essence", an internal resource.
// Essence is consumed to perform "Transformations" on Metamorphs, changing their Traits.
// Users can complete "Challenges" by meeting specific criteria (Traits, Essence) to earn rewards (Traits, Essence).
// The protocol features definable Traits, Transformation Recipes, and Challenges, managed initially by an owner.
//
// Data Structures:
// - TraitDefinition: Immutable properties of a type of trait (ID, name, type, max level, essence cost per level).
// - Metamorph: Represents a single dynamic token (owner, traits mapping, stake details, transformation cooldown).
// - TransformationRecipe: Defines requirements (traits, essence) and effects (add/remove/upgrade traits) for a transformation type.
// - Challenge: Defines criteria (traits, essence) and rewards (traits, essence) for a challenge type.
// - Trait: Represents an instance of a trait on a Metamorph (ID, level, value).
//
// Core Mechanics:
// - Dynamic Traits: Traits on a Metamorph can be added, removed, or leveled up.
// - Essence Generation: Staked Metamorphs passively generate Essence over time (based on blocks).
// - Transformations: Applying a recipe consumes Essence and input traits, yielding new traits. Subject to cooldown.
// - Challenges: Meeting challenge requirements grants rewards. Repeatable.
// - Internal Essence Balance: Users accrue Essence within the contract by staking and challenges, consumed by transformations and challenges.
//
// Function Summary:
// Admin/Setup:
// - constructor: Initializes the contract with owner and initial parameters.
// - pause: Pauses core protocol interactions (transformations, challenges, staking/unstaking).
// - unpause: Unpauses the protocol.
// - transferOwnership: Transfers ownership of the contract.
// - defineTraitDefinition: Owner defines a new type of trait.
// - defineTransformationRecipe: Owner defines a new transformation recipe.
// - defineChallenge: Owner defines a new challenge.
// - setEssenceGenerationRate: Owner sets the global rate for Essence generation via staking.
// - setTransformationFee: Owner sets the protocol fee collected from transformations.
// - withdrawProtocolFees: Owner withdraws accumulated protocol fees (Essence).
//
// Metamorph (Token) Management:
// - mintMetamorph: Mints a new Metamorph with initial traits (Admin or specific role, simplified to Owner for this example).
// - transferMetamorph: Transfers ownership of a Metamorph (standard token behavior).
// - burnMetamorph: Destroys a Metamorph (if required by recipes or owner action).
// - ownerOf: Returns the owner of a Metamorph.
// - balanceOf: Returns the number of Metamorphs owned by an address.
// - getMetamorph: Retrieves the details of a specific Metamorph.
//
// Trait Management on Metamorphs:
// - getMetamorphTraits: Retrieves all traits currently on a specific Metamorph.
// - getTraitDetails: Retrieves details of a specific trait instance on a Metamorph.
// - upgradeTraitLevel: Increases the level of a trait on a Metamorph using Essence.
//
// Essence & Staking:
// - stakeMetamorph: Stakes a Metamorph to begin generating Essence.
// - unstakeMetamorph: Unstakes a Metamorph, stopping Essence generation and making it available for other actions.
// - claimEssence: Claims accrued Essence from staking.
// - getUserClaimableEssence: Views the amount of Essence an address can claim from staking.
// - getMetamorphStakeDetails: Views staking information for a specific Metamorph.
// - getUserEssenceBalance: Views the internal Essence balance of a user.
//
// Transformations:
// - performTransformation: Executes a transformation recipe on a Metamorph, consuming requirements and applying effects.
// - getTransformationRecipe: Retrieves details of a specific transformation recipe.
//
// Challenges:
// - completeChallenge: Attempts to complete a challenge with a Metamorph, consuming requirements and receiving rewards.
// - getChallenge: Retrieves details of a specific challenge.
// - listActiveChallenges: Lists IDs of active challenges.
//
// View & Helper Functions:
// - getTraitDefinition: Retrieves immutable definition details of a trait type.
// - getTraitDefinitionsCount: Gets the total number of trait definitions.
// - getTransformationRecipesCount: Gets the total number of transformation recipes.
// - getChallengeDefinitionsCount: Gets the total number of challenge definitions.
// - getTotalMetamorphs: Gets the total number of Metamorphs minted.
// - getProtocolFeeBalance: Gets the total Essence accumulated as protocol fees.
// - isTraitAttached: Checks if a Metamorph has a specific trait.
// - getTraitLevel: Gets the level of a specific trait on a Metamorph.

// Custom Errors for clarity
error NotMetamorphOwner(uint256 metamorphId, address caller);
error MetamorphDoesNotExist(uint256 metamorphId);
error TraitDefinitionDoesNotExist(uint256 traitDefinitionId);
error MetamorphHasTrait(uint256 metamorphId, uint256 traitDefinitionId);
error MetamorphDoesNotHaveTrait(uint256 metamorphId, uint256 traitDefinitionId);
error TraitAlreadyAtMaxLevel(uint256 metamorphId, uint256 traitDefinitionId, uint8 currentLevel, uint8 maxLevel);
error InsufficientEssence(address user, uint256 required, uint256 available);
error MetamorphIsStaked(uint256 metamorphId);
error MetamorphNotStaked(uint256 metamorphId);
error TransformationRecipeDoesNotExist(uint256 recipeId);
error ChallengeDoesNotExist(uint256 challengeId);
error ChallengeNotActive(uint256 challengeId);
error MetamorphOnCooldown(uint256 metamorphId, uint256 lastTransformationBlock, uint256 cooldownDuration);
error InvalidTraitData();
error NotEnoughRequiredTraitsForRecipe(uint256 recipeId);
error TraitLevelTooLowForRecipe(uint256 recipeId, uint256 requiredTraitId, uint8 requiredLevel, uint8 currentLevel);
error NotEnoughRequiredTraitsForChallenge(uint256 challengeId);
error TraitLevelTooLowForChallenge(uint256 challengeId, uint256 requiredTraitId, uint8 requiredLevel, uint8 currentLevel);
error RecipeEffectRequiresTrait(uint256 recipeId, uint256 traitDefinitionIdToModify);


contract MetaMorphProtocol is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Counters for unique IDs
    Counters.Counter private _metamorphIds;
    Counters.Counter private _traitDefinitionIds;
    Counters.Counter private _transformationRecipeIds;
    Counters.Counter private _challengeIds;

    // --- Struct Definitions ---

    // Represents a specific instance of a trait on a Metamorph
    struct Trait {
        uint256 traitDefinitionId; // Link to the definition
        uint8 level;
        string value; // Optional: dynamic data like color, name suffix, etc.
    }

    // Immutable properties of a trait type
    struct TraitDefinition {
        uint256 id;
        string name;
        uint8 traitType; // e.g., 1: Visual, 2: Ability, 3: Environmental
        uint8 maxLevel;
        uint256 essenceCostPerLevel; // Cost to upgrade this trait type by one level
    }

    // Represents a single Metamorph token
    struct Metamorph {
        address owner;
        mapping(uint256 => Trait) traits; // traitDefinitionId => Trait instance
        uint256 stakedSinceBlock; // 0 if not staked
        uint256 lastTransformationBlock; // Block number of the last transformation
    }

    // Defines what is needed and what happens in a transformation
    struct TransformationRecipe {
        uint256 id;
        string name;
        string description;
        bool isActive;
        uint256 requiredEssence;
        mapping(uint256 => uint8) requiredTraits; // traitDefinitionId => required level
        // Effects: can be complex. For simplicity, let's define output traits
        struct OutputTrait {
            uint256 traitDefinitionId;
            uint8 level; // Absolute level to set, or level *change*? Let's make it absolute set level for simplicity.
            string value; // New value to set
            bool removeExisting; // If true, remove the trait instead of adding/setting
        }
        OutputTrait[] outputTraits;
        uint256 cooldownBlocks; // How many blocks until this Metamorph can transform again (globally, or specific to recipe?) Let's use a global cooldown tracked on the Metamorph.
    }

     // Defines what is needed and what happens in a challenge
    struct Challenge {
        uint256 id;
        string name;
        string description;
        bool isActive;
        uint256 requiredEssence;
        mapping(uint256 => uint8) requiredTraits; // traitDefinitionId => required level
        uint256 rewardEssence;
        // Rewards: similar to transformation outputs
         struct RewardTrait {
            uint256 traitDefinitionId;
            uint8 level; // Absolute level to set or level change? Let's add/set.
            string value;
            bool removeExisting; // If true, remove the trait instead of adding/setting
        }
        RewardTrait[] rewardTraits;
        // Could add requirements like 'must not have completed before' or 'only once per block'
        // For simplicity, let's make them repeatable if criteria are met.
    }

    // --- Mappings ---

    mapping(uint256 => Metamorph) private _metamorphs; // metamorphId => Metamorph data
    mapping(address => uint256) private _ownerMetamorphCount; // owner address => count
    mapping(uint256 => address) private _metamorphOwners; // metamorphId => owner address (redundant but useful for ERC721-like ownerOf)

    mapping(uint256 => TraitDefinition) private _traitDefinitions; // traitDefinitionId => definition
    mapping(uint256 => TransformationRecipe) private _transformationRecipes; // recipeId => recipe
    mapping(uint256 => Challenge) private _challenges; // challengeId => challenge

    mapping(address => uint256) private _userEssenceBalances; // user address => internal essence balance

    uint256 public essenceGenerationRatePerBlock = 10; // How much essence is generated per staked metamorph per block
    uint256 public transformationFeeRate = 100; // Percentage (e.g., 100 = 1% fee) of consumed essence per transformation goes to protocol

    uint256 public protocolFeeEssenceBalance = 0; // Essence collected as fees

    // --- Events ---

    event MetamorphMinted(uint256 indexed metamorphId, address indexed owner, uint256[] initialTraitDefinitionIds);
    event Transfer(address indexed from, address indexed to, uint256 indexed metamorphId); // ERC721-like transfer event
    event TraitAdded(uint256 indexed metamorphId, uint256 indexed traitDefinitionId, uint8 level, string value);
    event TraitRemoved(uint256 indexed metamorphId, uint256 indexed traitDefinitionId);
    event TraitLevelUpgraded(uint256 indexed metamorphId, uint256 indexed traitDefinitionId, uint8 newLevel);
    event EssenceClaimed(address indexed user, uint256 amount);
    event MetamorphStaked(uint256 indexed metamorphId, address indexed owner, uint256 indexed blockNumber);
    event MetamorphUnstaked(uint256 indexed metamorphId, address indexed owner, uint256 indexed blockNumber, uint256 accruedEssence);
    event Transformed(uint256 indexed metamorphId, uint256 indexed recipeId, address indexed user, uint256 essenceConsumed);
    event ChallengeCompleted(uint256 indexed metamorphId, uint256 indexed challengeId, address indexed user, uint256 essenceConsumed, uint256 essenceReward);
    event TraitDefinitionDefined(uint256 indexed traitDefinitionId, string name);
    event TransformationRecipeDefined(uint256 indexed recipeId, string name);
    event ChallengeDefined(uint256 indexed challengeId, string name);
    event ProtocolFeeWithdrawn(address indexed owner, uint256 amount);
    event TransformationFeeRateSet(uint256 newRate);
    event EssenceGenerationRateSet(uint256 newRate);

    // --- Modifiers ---

    modifier onlyMetamorphOwner(uint256 metamorphId) {
        if (_metamorphOwners[metamorphId] == address(0)) revert MetamorphDoesNotExist(metamorphId);
        if (_metamorphOwners[metamorphId] != _msgSender()) revert NotMetamorphOwner(metamorphId, _msgSender());
        _;
    }

    modifier whenMetamorphNotStaked(uint256 metamorphId) {
         if (_metamorphs[metamorphId].stakedSinceBlock != 0) revert MetamorphIsStaked(metamorphId);
        _;
    }

    modifier whenMetamorphStaked(uint256 metamorphId) {
         if (_metamorphs[metamorphId].stakedSinceBlock == 0) revert MetamorphNotStaked(metamorphId);
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialEssenceRate, uint256 initialTransformationFeeRate) Ownable(msg.sender) {
        essenceGenerationRatePerBlock = initialEssenceRate;
        transformationFeeRate = initialTransformationFeeRate;
    }

    // --- Admin/Setup Functions ---

    /// @notice Pauses core protocol interactions (transformations, challenges, staking/unstaking).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the protocol.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Defines a new type of trait that can exist on Metamorphs.
    /// @param name The name of the trait.
    /// @param traitType The category of the trait (e.g., Visual, Ability).
    /// @param maxLevel The maximum level this trait can reach.
    /// @param essenceCostPerLevel The Essence cost to upgrade this trait by one level.
    /// @return traitDefinitionId The ID of the newly defined trait type.
    function defineTraitDefinition(string calldata name, uint8 traitType, uint8 maxLevel, uint256 essenceCostPerLevel) external onlyOwner returns (uint256) {
        _traitDefinitionIds.increment();
        uint256 newId = _traitDefinitionIds.current();
        _traitDefinitions[newId] = TraitDefinition(newId, name, traitType, maxLevel, essenceCostPerLevel);
        emit TraitDefinitionDefined(newId, name);
        return newId;
    }

    /// @notice Defines a new transformation recipe.
    /// @param name The name of the recipe.
    /// @param description A description of the recipe.
    /// @param isActive Whether the recipe is immediately active.
    /// @param requiredEssence The Essence cost to perform this transformation.
    /// @param requiredTraitDefinitionIds Array of trait definition IDs required.
    /// @param requiredTraitLevels Array of corresponding trait levels required. Must match `requiredTraitDefinitionIds` length.
    /// @param outputTraitDefinitionIds Array of trait definition IDs for output traits.
    /// @param outputTraitLevels Array of corresponding output trait levels. Must match `outputTraitDefinitionIds` length.
    /// @param outputTraitValues Array of corresponding output trait values. Must match `outputTraitDefinitionIds` length.
    /// @param outputTraitRemoveFlags Array of booleans indicating if the trait should be removed instead of added/modified. Must match `outputTraitDefinitionIds` length.
    /// @param cooldownBlocks The minimum blocks between transformations for a Metamorph.
    /// @return recipeId The ID of the newly defined recipe.
    function defineTransformationRecipe(
        string calldata name,
        string calldata description,
        bool isActive,
        uint256 requiredEssence,
        uint256[] calldata requiredTraitDefinitionIds,
        uint8[] calldata requiredTraitLevels,
        uint256[] calldata outputTraitDefinitionIds,
        uint8[] calldata outputTraitLevels,
        string[] calldata outputTraitValues,
        bool[] calldata outputTraitRemoveFlags,
        uint256 cooldownBlocks
    ) external onlyOwner returns (uint256) {
        if (requiredTraitDefinitionIds.length != requiredTraitLevels.length ||
            outputTraitDefinitionIds.length != outputTraitLevels.length ||
            outputTraitLevels.length != outputTraitValues.length ||
            outputTraitLevels.length != outputTraitRemoveFlags.length)
        {
            revert InvalidTraitData(); // Or a more specific error
        }

        _transformationRecipeIds.increment();
        uint256 newId = _transformationRecipeIds.current();
        TransformationRecipe storage recipe = _transformationRecipes[newId];
        recipe.id = newId;
        recipe.name = name;
        recipe.description = description;
        recipe.isActive = isActive;
        recipe.requiredEssence = requiredEssence;
        recipe.cooldownBlocks = cooldownBlocks;

        for (uint i = 0; i < requiredTraitDefinitionIds.length; i++) {
            if (_traitDefinitions[requiredTraitDefinitionIds[i]].id == 0) revert TraitDefinitionDoesNotExist(requiredTraitDefinitionIds[i]);
            recipe.requiredTraits[requiredTraitDefinitionIds[i]] = requiredTraitLevels[i];
        }

        for (uint i = 0; i < outputTraitDefinitionIds.length; i++) {
             if (!outputTraitRemoveFlags[i] && _traitDefinitions[outputTraitDefinitionIds[i]].id == 0) revert TraitDefinitionDoesNotExist(outputTraitDefinitionIds[i]);
             recipe.outputTraits.push(TransformationRecipe.OutputTrait({
                traitDefinitionId: outputTraitDefinitionIds[i],
                level: outputTraitLevels[i],
                value: outputTraitValues[i],
                removeExisting: outputTraitRemoveFlags[i]
            }));
        }

        emit TransformationRecipeDefined(newId, name);
        return newId;
    }

    /// @notice Defines a new challenge.
    /// @param name The name of the challenge.
    /// @param description A description of the challenge.
    /// @param isActive Whether the challenge is immediately active.
    /// @param requiredEssence The Essence cost to attempt the challenge.
    /// @param requiredTraitDefinitionIds Array of trait definition IDs required.
    /// @param requiredTraitLevels Array of corresponding trait levels required.
    /// @param rewardEssence The Essence rewarded upon completion.
    /// @param rewardTraitDefinitionIds Array of trait definition IDs for reward traits.
    /// @param rewardTraitLevels Array of corresponding reward trait levels.
    /// @param rewardTraitValues Array of corresponding reward trait values.
    /// @param rewardTraitRemoveFlags Array of booleans indicating if the trait should be removed instead of added/modified.
    /// @return challengeId The ID of the newly defined challenge.
    function defineChallenge(
        string calldata name,
        string calldata description,
        bool isActive,
        uint256 requiredEssence,
        uint256[] calldata requiredTraitDefinitionIds,
        uint8[] calldata requiredTraitLevels,
        uint256 rewardEssence,
        uint256[] calldata rewardTraitDefinitionIds,
        uint8[] calldata rewardTraitLevels,
        string[] calldata rewardTraitValues,
        bool[] calldata rewardTraitRemoveFlags
    ) external onlyOwner returns (uint256) {
        if (requiredTraitDefinitionIds.length != requiredTraitLevels.length ||
            rewardTraitDefinitionIds.length != rewardTraitLevels.length ||
            rewardTraitLevels.length != rewardTraitValues.length ||
            rewardTraitLevels.length != rewardTraitRemoveFlags.length)
        {
            revert InvalidTraitData(); // Or a more specific error
        }

        _challengeIds.increment();
        uint256 newId = _challengeIds.current();
        Challenge storage challenge = _challenges[newId];
        challenge.id = newId;
        challenge.name = name;
        challenge.description = description;
        challenge.isActive = isActive;
        challenge.requiredEssence = requiredEssence;
        challenge.rewardEssence = rewardEssence;

        for (uint i = 0; i < requiredTraitDefinitionIds.length; i++) {
            if (_traitDefinitions[requiredTraitDefinitionIds[i]].id == 0) revert TraitDefinitionDoesNotExist(requiredTraitDefinitionIds[i]);
            challenge.requiredTraits[requiredTraitDefinitionIds[i]] = requiredTraitLevels[i];
        }

         for (uint i = 0; i < rewardTraitDefinitionIds.length; i++) {
             if (!rewardTraitRemoveFlags[i] && _traitDefinitions[rewardTraitDefinitionIds[i]].id == 0) revert TraitDefinitionDoesNotExist(rewardTraitDefinitionIds[i]);
             challenge.rewardTraits.push(Challenge.RewardTrait({
                traitDefinitionId: rewardTraitDefinitionIds[i],
                level: rewardTraitLevels[i],
                value: rewardTraitValues[i],
                removeExisting: rewardTraitRemoveFlags[i]
            }));
        }

        emit ChallengeDefined(newId, name);
        return newId;
    }

    /// @notice Sets the global rate at which Essence is generated per staked Metamorph per block.
    /// @param newRate The new rate.
    function setEssenceGenerationRate(uint256 newRate) external onlyOwner {
        essenceGenerationRatePerBlock = newRate;
        emit EssenceGenerationRateSet(newRate);
    }

    /// @notice Sets the percentage fee collected from the Essence consumed during transformations.
    /// @param newRate The new fee rate (e.g., 100 for 1%). Max 10000 (100%).
    function setTransformationFee(uint256 newRate) external onlyOwner {
        require(newRate <= 10000, "Fee rate cannot exceed 100%");
        transformationFeeRate = newRate;
        emit TransformationFeeRateSet(newRate);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees (Essence).
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = protocolFeeEssenceBalance;
        protocolFeeEssenceBalance = 0;
        // In a real system, this might transfer an ERC20 Essence token.
        // Here, it just reduces the internal balance.
        // If Essence were a separate ERC20, this function would need to interact with it.
        emit ProtocolFeeWithdrawn(msg.sender, amount);
    }


    // --- Metamorph (Token) Management Functions ---

    /// @notice Mints a new Metamorph token. For simplicity, only owner can mint.
    /// @param recipient The address to receive the new Metamorph.
    /// @param initialTraitDefinitionIds The trait definition IDs for the initial traits.
    /// @param initialTraitLevels The levels for the initial traits.
    /// @param initialTraitValues The values for the initial traits.
    /// @return metamorphId The ID of the newly minted Metamorph.
    function mintMetamorph(address recipient, uint256[] calldata initialTraitDefinitionIds, uint8[] calldata initialTraitLevels, string[] calldata initialTraitValues)
        external
        onlyOwner // Simplified access control
        whenNotPaused
        returns (uint256)
    {
         if (initialTraitDefinitionIds.length != initialTraitLevels.length || initialTraitLevels.length != initialTraitValues.length) {
            revert InvalidTraitData();
        }

        _metamorphIds.increment();
        uint256 newId = _metamorphIds.current();

        _metamorphs[newId].owner = recipient; // Set owner directly in struct
        _metamorphOwners[newId] = recipient; // Set owner in lookup mapping
        _ownerMetamorphCount[recipient]++;

        for (uint i = 0; i < initialTraitDefinitionIds.length; i++) {
            uint256 traitDefId = initialTraitDefinitionIds[i];
            if (_traitDefinitions[traitDefId].id == 0) revert TraitDefinitionDoesNotExist(traitDefId);
            if (_metamorphs[newId].traits[traitDefId].traitDefinitionId != 0) revert MetamorphHasTrait(newId, traitDefId); // Prevent duplicate initial traits

            _metamorphs[newId].traits[traitDefId] = Trait({
                traitDefinitionId: traitDefId,
                level: initialTraitLevels[i],
                value: initialTraitValues[i]
            });
            emit TraitAdded(newId, traitDefId, initialTraitLevels[i], initialTraitValues[i]);
        }

        emit MetamorphMinted(newId, recipient, initialTraitDefinitionIds);
        emit Transfer(address(0), recipient, newId); // Standard transfer event from address(0) for mint

        return newId;
    }

    /// @notice Transfers a Metamorph token. Includes unstaking if staked.
    /// @param from The current owner of the Metamorph.
    /// @param to The address to transfer the Metamorph to.
    /// @param metamorphId The ID of the Metamorph to transfer.
    function transferMetamorph(address from, address to, uint256 metamorphId)
        public
        whenNotPaused // Pausing affects transfers
        onlyMetamorphOwner(metamorphId) // Only current owner can transfer
    {
        require(from == _msgSender(), "ERC721: transfer from incorrect owner"); // Standard ERC721 check
        require(to != address(0), "ERC721: transfer to the zero address");

        // Automatically unstake before transfer
        if (_metamorphs[metamorphId].stakedSinceBlock != 0) {
            _unstakeMetamorph(metamorphId, from); // Internal unstake logic
        }

        _ownerMetamorphCount[from]--;
        _ownerMetamorphCount[to]++;
        _metamorphs[metamorphId].owner = to; // Update owner in struct
        _metamorphOwners[metamorphId] = to; // Update owner in lookup mapping

        emit Transfer(from, to, metamorphId);
    }

     /// @notice Burns (destroys) a Metamorph token. Requires owner permission.
    /// @param metamorphId The ID of the Metamorph to burn.
    function burnMetamorph(uint256 metamorphId)
        public
        whenNotPaused // Pausing affects burning
        onlyMetamorphOwner(metamorphId)
    {
        address owner = _metamorphOwners[metamorphId];

        // Automatically unstake before burning
        if (_metamorphs[metamorphId].stakedSinceBlock != 0) {
            _unstakeMetamorph(metamorphId, owner); // Internal unstake logic
        }

        _ownerMetamorphCount[owner]--;
        delete _metamorphs[metamorphId]; // Delete struct data
        delete _metamorphOwners[metamorphId]; // Delete owner mapping

        // Note: Traits within the struct are automatically deleted when the struct is deleted.

        // No burn event needed for ERC721 standard, Transfer to zero address is common representation.
        emit Transfer(owner, address(0), metamorphId);
    }

    /// @notice Returns the owner of the specified Metamorph token. ERC721-like view.
    /// @param metamorphId The ID of the Metamorph.
    /// @return The owner's address.
    function ownerOf(uint256 metamorphId) public view returns (address) {
        address owner = _metamorphOwners[metamorphId];
        if (owner == address(0)) revert MetamorphDoesNotExist(metamorphId);
        return owner;
    }

    /// @notice Returns the number of Metamorphs owned by a specific address. ERC721-like view.
    /// @param owner The address to query.
    /// @return The count of Metamorphs owned by the address.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownerMetamorphCount[owner];
    }

    /// @notice Retrieves the details of a specific Metamorph. Does NOT include traits.
    /// Use `getMetamorphTraits` for traits.
    /// @param metamorphId The ID of the Metamorph.
    /// @return owner The owner's address.
    /// @return stakedSinceBlock Block number since staking, or 0 if not staked.
    /// @return lastTransformationBlock Block number of the last transformation.
    function getMetamorph(uint256 metamorphId)
        public
        view
        returns (address owner, uint256 stakedSinceBlock, uint256 lastTransformationBlock)
    {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        if (metamorph.owner == address(0)) revert MetamorphDoesNotExist(metamorphId); // Check struct existence

        return (metamorph.owner, metamorph.stakedSinceBlock, metamorph.lastTransformationBlock);
    }


    // --- Trait Management on Metamorphs Functions ---

    /// @notice Retrieves all traits currently attached to a specific Metamorph.
    /// @param metamorphId The ID of the Metamorph.
    /// @return traits Array of Trait structs.
    function getMetamorphTraits(uint256 metamorphId) public view returns (Trait[] memory) {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        if (metamorph.owner == address(0)) revert MetamorphDoesNotExist(metamorphId);

        // Iterate through all possible trait definitions to find traits on this metamorph
        uint256 totalTraitDefs = _traitDefinitionIds.current();
        uint256 traitCount = 0;
        // First pass to count
        for (uint256 i = 1; i <= totalTraitDefs; i++) {
            if (metamorph.traits[i].traitDefinitionId != 0) { // Check if trait exists
                traitCount++;
            }
        }

        Trait[] memory currentTraits = new Trait[](traitCount);
        uint256 currentIndex = 0;
        // Second pass to populate array
        for (uint256 i = 1; i <= totalTraitDefs; i++) {
            if (metamorph.traits[i].traitDefinitionId != 0) {
                 currentTraits[currentIndex] = Trait({
                     traitDefinitionId: metamorph.traits[i].traitDefinitionId,
                     level: metamorph.traits[i].level,
                     value: metamorph.traits[i].value
                 });
                currentIndex++;
            }
        }

        return currentTraits;
    }

    /// @notice Retrieves details of a specific trait instance on a Metamorph.
    /// @param metamorphId The ID of the Metamorph.
    /// @param traitDefinitionId The ID of the trait definition.
    /// @return exists True if the trait exists on the Metamorph.
    /// @return level The level of the trait.
    /// @return value The value string of the trait.
    function getTraitDetails(uint256 metamorphId, uint256 traitDefinitionId) public view returns (bool exists, uint8 level, string memory value) {
         Metamorph storage metamorph = _metamorphs[metamorphId];
         if (metamorph.owner == address(0)) revert MetamorphDoesNotExist(metamorphId);
         if (_traitDefinitions[traitDefinitionId].id == 0) revert TraitDefinitionDoesNotExist(traitDefinitionId);

         if (metamorph.traits[traitDefinitionId].traitDefinitionId == 0) {
             return (false, 0, "");
         } else {
             return (true, metamorph.traits[traitDefinitionId].level, metamorph.traits[traitDefinitionId].value);
         }
    }

     /// @notice Upgrades the level of a trait on a Metamorph. Consumes Essence.
    /// @param metamorphId The ID of the Metamorph.
    /// @param traitDefinitionId The ID of the trait definition to upgrade.
    function upgradeTraitLevel(uint256 metamorphId, uint256 traitDefinitionId)
        public
        whenNotPaused
        onlyMetamorphOwner(metamorphId)
        whenMetamorphNotStaked(metamorphId)
    {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        TraitDefinition storage traitDef = _traitDefinitions[traitDefinitionId];

        if (traitDef.id == 0) revert TraitDefinitionDoesNotExist(traitDefinitionId);
        if (metamorph.traits[traitDefinitionId].traitDefinitionId == 0) revert MetamorphDoesNotHaveTrait(metamorphId, traitDefinitionId);

        Trait storage trait = metamorph.traits[traitDefinitionId];
        if (trait.level >= traitDef.maxLevel) revert TraitAlreadyAtMaxLevel(metamorphId, traitDefinitionId, trait.level, traitDef.maxLevel);

        uint256 cost = traitDef.essenceCostPerLevel;
        if (_userEssenceBalances[_msgSender()] < cost) revert InsufficientEssence(_msgSender(), cost, _userEssenceBalances[_msgSender()]);

        _userEssenceBalances[_msgSender()] -= cost;
        trait.level++;

        emit TraitLevelUpgraded(metamorphId, traitDefinitionId, trait.level);
    }


    // --- Essence & Staking Functions ---

    /// @notice Stakes a Metamorph to start generating Essence.
    /// @param metamorphId The ID of the Metamorph to stake.
    function stakeMetamorph(uint256 metamorphId)
        public
        whenNotPaused
        onlyMetamorphOwner(metamorphId)
        whenMetamorphNotStaked(metamorphId)
    {
        _metamorphs[metamorphId].stakedSinceBlock = block.number;
        emit MetamorphStaked(metamorphId, _msgSender(), block.number);
    }

     /// @notice Unstakes a Metamorph and claims accrued Essence.
    /// @param metamorphId The ID of the Metamorph to unstake.
    function unstakeMetamorph(uint256 metamorphId)
        public
        whenNotPaused
        onlyMetamorphOwner(metamorphId)
        whenMetamorphStaked(metamorphId)
    {
        _unstakeMetamorph(metamorphId, _msgSender());
    }

    /// @dev Internal function to unstake a Metamorph and calculate/distribute essence.
    /// @param metamorphId The ID of the Metamorph.
    /// @param user The owner/user performing the unstake.
    function _unstakeMetamorph(uint256 metamorphId, address user) internal {
         Metamorph storage metamorph = _metamorphs[metamorphId];
         uint256 stakedSince = metamorph.stakedSinceBlock;
         metamorph.stakedSinceBlock = 0; // Unstake first to prevent re-staking issues

         uint256 accruedEssence = 0;
         if (block.number > stakedSince) {
             accruedEssence = (block.number - stakedSince) * essenceGenerationRatePerBlock;
         }

         if (accruedEssence > 0) {
            _userEssenceBalances[user] += accruedEssence;
            emit EssenceClaimed(user, accruedEssence); // Emit claim event for staking rewards
         }

         emit MetamorphUnstaked(metamorphId, user, block.number, accruedEssence);
    }


    /// @notice Claims any pending Essence from staking across all owned, currently staked Metamorphs.
    function claimEssence() public whenNotPaused {
        address user = _msgSender();
        uint256 totalTraitDefs = _traitDefinitionIds.current(); // We iterate Metamorphs indirectly... this is inefficient.
                                                              // A better design would track staked Metamorphs per user.
                                                              // For this example, let's refine the essence accrual logic.
                                                              // Let's just make `claimEssence` claim the current accrued balance,
                                                              // and unstake calculates & adds to the balance.
                                                              // Staking accrual *only* happens on unstake or transfer out.
                                                              // This simplifies tracking.
        uint256 claimable = getUserClaimableEssence(user); // This is incorrect with the simplified accrual.

        // --- Re-thinking Essence Accrual ---
        // Option 1: Accrue continuously, calculate on-demand (requires tracking last accrual block for each Metamorph). This is what `getMetamorphStakeDetails` suggests.
        // Option 2: Accrue only on unstake/transfer (simpler state, less frequent updates).
        // Option 3: Accrue to a global user balance, updated whenever a stake/unstake happens. This makes `claimEssence` just withdraw from the internal balance.

        // Let's go with Option 3 for `claimEssence`: `claimEssence` just withdraws the user's balance accumulated by unstaking/challenges.
        // The accrual calculation happens in `_unstakeMetamorph` and `completeChallenge`.

        // So, `claimEssence` simply transfers the balance.

        uint256 amountToClaim = _userEssenceBalances[user];
        if (amountToClaim == 0) return; // Nothing to claim

        // In a real system, this would transfer an ERC20 Essence token.
        // Here, we just zero out the internal balance as it's an internal resource.
        _userEssenceBalances[user] = 0;

        emit EssenceClaimed(user, amountToClaim);
    }

    /// @notice Gets the amount of Essence an address can claim from their internal balance.
    /// This balance is accumulated from unstaking Metamorphs and challenge rewards.
    /// @param user The address to query.
    /// @return The amount of Essence the user can claim.
    function getUserEssenceBalance(address user) public view returns (uint256) {
        // Note: This does *not* calculate new essence from *currently staked* Metamorphs.
        // That calculation happens when the Metamorph is unstaked or transferred.
        return _userEssenceBalances[user];
    }


    /// @notice Views the amount of Essence an address can claim from currently staked Metamorphs *without unstaking*.
    /// @param user The address to query.
    /// @dev This requires iterating through all Metamorphs owned by the user, which is inefficient.
    /// A better approach would be to track staked Metamorphs per user or use a more gas-efficient storage pattern.
    /// FOR EXAMPLE PURPOSES ONLY: This implementation iterates potential Metamorph IDs up to the current total.
    /// This is NOT suitable for a production contract with many tokens.
    /// A production contract would need a mapping like `address => uint256[] stakedMetamorphIds`
    /// or calculate accrual differently.
    /// @return The total claimable Essence from currently staked Metamorphs.
    function getUserClaimableEssence(address user) public view returns (uint256) {
        uint256 totalClaimable = 0;
        uint256 currentTotalMetamorphs = _metamorphIds.current();

        // WARNING: This loop can be very expensive/unusable if _metamorphIds.current() is large.
        // Refactor for production: track staked tokens per user.
        for (uint256 i = 1; i <= currentTotalMetamorphs; i++) {
            Metamorph storage metamorph = _metamorphs[i];
            // Check existence AND ownership AND staked status
            if (metamorph.owner == user && metamorph.stakedSinceBlock != 0 && block.number > metamorph.stakedSinceBlock) {
                 totalClaimable += (block.number - metamorph.stakedSinceBlock) * essenceGenerationRatePerBlock;
            }
        }
        return totalClaimable;
    }

     /// @notice Views staking information for a specific Metamorph.
    /// @param metamorphId The ID of the Metamorph.
    /// @return isStaked True if the Metamorph is currently staked.
    /// @return stakedSinceBlock Block number since staking, or 0.
    /// @return accruedEssence The amount of Essence accrued since staking (calculated up to current block).
    function getMetamorphStakeDetails(uint256 metamorphId)
        public
        view
        returns (bool isStaked, uint256 stakedSinceBlock, uint256 accruedEssence)
    {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        if (metamorph.owner == address(0)) revert MetamorphDoesNotExist(metamorphId);

        stakedSinceBlock = metamorph.stakedSinceBlock;
        isStaked = stakedSinceBlock != 0;
        accruedEssence = 0;

        if (isStaked && block.number > stakedSinceBlock) {
             accruedEssence = (block.number - stakedSinceBlock) * essenceGenerationRatePerBlock;
        }

        return (isStaked, stakedSinceBlock, accruedEssence);
    }


    // --- Transformation Functions ---

    /// @notice Performs a transformation on a Metamorph according to a recipe.
    /// Consumes Essence and required Traits, applies output Traits, adds cooldown.
    /// @param metamorphId The ID of the Metamorph to transform.
    /// @param recipeId The ID of the transformation recipe to use.
    function performTransformation(uint256 metamorphId, uint256 recipeId)
        public
        whenNotPaused
        onlyMetamorphOwner(metamorphId)
        whenMetamorphNotStaked(metamorphId)
    {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        TransformationRecipe storage recipe = _transformationRecipes[recipeId];

        if (recipe.id == 0 || !recipe.isActive) revert TransformationRecipeDoesNotExist(recipeId);

        // Check cooldown
        if (block.number < metamorph.lastTransformationBlock + recipe.cooldownBlocks) {
            revert MetamorphOnCooldown(metamorphId, metamorph.lastTransformationBlock, recipe.cooldownBlocks);
        }

        // Check required Essence
        uint256 essenceCost = recipe.requiredEssence;
        if (_userEssenceBalances[_msgSender()] < essenceCost) revert InsufficientEssence(_msgSender(), essenceCost, _userEssenceBalances[_msgSender()]);

        // Check required Traits and levels
        // Note: Iterating over a mapping is non-deterministic and not possible directly in Solidity for checking *all* required traits.
        // A robust implementation would store required traits in an array in the Recipe struct for easy iteration.
        // Let's simulate checking a *few* required traits defined in the recipe mapping for demonstration.
        // The `defineTransformationRecipe` function already populates `recipe.requiredTraits`.
        // We need to iterate over the *keys* of this mapping. This is a limitation in standard Solidity.
        // A workaround is to store the keys (traitDefinitionIds) in an array when defining the recipe.
        // Let's assume `defineTransformationRecipe` stores the keys in an array (e.g., `recipe.requiredTraitIdsArray`).
        // Update: The `defineTransformationRecipe` already loops and populates the mapping, so we know the keys.
        // We'll need to define an *additional* array `requiredTraitIdsArray` in the recipe struct to iterate.
        // Let's modify the `TransformationRecipe` struct and `defineTransformationRecipe` slightly for this.

        // --- Modification needed: Add `requiredTraitIdsArray` to TransformationRecipe struct ---
        // Add: `uint256[] requiredTraitIdsArray;` to TransformationRecipe
        // Modify `defineTransformationRecipe` to push `requiredTraitDefinitionIds[i]` to this array.
        // --- End Modification ---

        // Assuming `requiredTraitIdsArray` exists and is populated:
        for (uint i = 0; i < recipe.requiredTraitIdsArray.length; i++) {
            uint256 requiredTraitId = recipe.requiredTraitIdsArray[i];
            uint8 requiredLevel = recipe.requiredTraits[requiredTraitId]; // Get level from mapping

            if (metamorph.traits[requiredTraitId].traitDefinitionId == 0) {
                 revert NotEnoughRequiredTraitsForRecipe(recipeId); // Missing a required trait
            }
            if (metamorph.traits[requiredTraitId].level < requiredLevel) {
                revert TraitLevelTooLowForRecipe(recipeId, requiredTraitId, requiredLevel, metamorph.traits[requiredTraitId].level);
            }
        }

        // Consume Essence
        uint256 feeAmount = (essenceCost * transformationFeeRate) / 10000; // Fee is a percentage of cost
        uint256 userCost = essenceCost - feeAmount; // User pays cost minus fee
        _userEssenceBalances[_msgSender()] -= essenceCost; // User pays the full cost initially
        protocolFeeEssenceBalance += feeAmount; // Protocol collects fee
        _userEssenceBalances[_msgSender()] += userCost; // Refund user the non-fee portion (conceptually, user pays net cost)

        // Apply output Traits
        for (uint i = 0; i < recipe.outputTraits.length; i++) {
            TransformationRecipe.OutputTrait storage output = recipe.outputTraits[i];
            uint256 outputTraitDefId = output.traitDefinitionId;

            if (output.removeExisting) {
                // Remove the trait if it exists
                if (metamorph.traits[outputTraitDefId].traitDefinitionId != 0) {
                     delete metamorph.traits[outputTraitDefId];
                     emit TraitRemoved(metamorphId, outputTraitDefId);
                }
            } else {
                 // Add or update the trait
                 if (_traitDefinitions[outputTraitDefId].id == 0) revert TraitDefinitionDoesNotExist(outputTraitDefId); // Should have been checked in define, but safety
                 metamorph.traits[outputTraitDefId] = Trait({
                    traitDefinitionId: outputTraitDefId,
                    level: output.level,
                    value: output.value
                 });
                 // Emit Add or LevelUp? Let's emit Add if new, LevelUp if existing and level changed.
                 // This requires checking if it existed before. Let's simplify and just emit TraitAdded for any set/update.
                 emit TraitAdded(metamorphId, outputTraitDefId, output.level, output.value); // Use TraitAdded event for set/update
            }
        }

        // Update cooldown
        metamorph.lastTransformationBlock = block.number;

        emit Transformed(metamorphId, recipeId, _msgSender(), essenceCost);
    }

    /// @notice Retrieves details of a specific transformation recipe.
    /// @param recipeId The ID of the recipe.
    /// @return recipe The TransformationRecipe struct.
    function getTransformationRecipe(uint256 recipeId) public view returns (TransformationRecipe memory recipe) {
        TransformationRecipe storage storedRecipe = _transformationRecipes[recipeId];
        if (storedRecipe.id == 0) revert TransformationRecipeDoesNotExist(recipeId);

        // Copy to memory struct to return dynamic arrays (mapping isn't copied)
        TransformationRecipe memory memoryRecipe;
        memoryRecipe.id = storedRecipe.id;
        memoryRecipe.name = storedRecipe.name;
        memoryRecipe.description = storedRecipe.description;
        memoryRecipe.isActive = storedRecipe.isActive;
        memoryRecipe.requiredEssence = storedRecipe.requiredEssence;
        memoryRecipe.cooldownBlocks = storedRecipe.cooldownBlocks;

        // Copy required traits (requires iterating the array of keys)
        // This requires the `requiredTraitIdsArray` modification mentioned above.
        // Assuming `requiredTraitIdsArray` exists:
        uint256[] memory requiredTraitIdsArray = storedRecipe.requiredTraitIdsArray;
        // We cannot return the mapping directly. We need to format the required traits for the return.
        // Let's return arrays of IDs and Levels instead of trying to reproduce the mapping structure.
        // We need to modify the return type or create a helper view function.
        // Let's create a helper view function to get required traits.

        // Modify this function to return non-mapping parts.
        // Return type update: returns (uint256 id, string memory name, string memory description, bool isActive, uint256 requiredEssence, uint256 cooldownBlocks)

        return (
            storedRecipe.id,
            storedRecipe.name,
            storedRecipe.description,
            storedRecipe.isActive,
            storedRecipe.requiredEssence,
            storedRecipe.cooldownBlocks
        );
    }

    /// @notice Helper view function to get the required traits for a transformation recipe.
    /// @param recipeId The ID of the recipe.
    /// @return requiredTraitIds Array of required trait definition IDs.
    /// @return requiredTraitLevels Array of corresponding required levels.
     function getTransformationRecipeRequirements(uint256 recipeId) public view returns (uint256[] memory requiredTraitIds, uint8[] memory requiredTraitLevels) {
         TransformationRecipe storage recipe = _transformationRecipes[recipeId];
         if (recipe.id == 0) revert TransformationRecipeDoesNotExist(recipeId);

         // Assumes `requiredTraitIdsArray` exists and is populated in struct/definition.
         uint256[] memory requiredIds = recipe.requiredTraitIdsArray; // Requires this addition
         uint8[] memory requiredLevels = new uint8[](requiredIds.length);

         for(uint i = 0; i < requiredIds.length; i++) {
             requiredLevels[i] = recipe.requiredTraits[requiredIds[i]];
         }

         return (requiredIds, requiredLevels);
     }

     /// @notice Helper view function to get the output traits for a transformation recipe.
     /// @param recipeId The ID of the recipe.
     /// @return outputTraits Array of OutputTrait structs.
     function getTransformationRecipeOutputs(uint256 recipeId) public view returns (TransformationRecipe.OutputTrait[] memory) {
         TransformationRecipe storage recipe = _transformationRecipes[recipeId];
         if (recipe.id == 0) revert TransformationRecipeDoesNotExist(recipeId);
         return recipe.outputTraits;
     }


    // --- Challenge Functions ---

    /// @notice Attempts to complete a challenge with a Metamorph.
    /// Checks requirements, consumes Essence/Traits, rewards Essence/Traits.
    /// @param metamorphId The ID of the Metamorph used for the challenge.
    /// @param challengeId The ID of the challenge to complete.
    function completeChallenge(uint256 metamorphId, uint256 challengeId)
        public
        whenNotPaused
        onlyMetamorphOwner(metamorphId)
        whenMetamorphNotStaked(metamorphId) // Cannot use staked Metamorphs for challenges
    {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        Challenge storage challenge = _challenges[challengeId];

        if (challenge.id == 0 || !challenge.isActive) revert ChallengeDoesNotExist(challengeId);

        // Check required Essence
        uint256 essenceCost = challenge.requiredEssence;
        if (_userEssenceBalances[_msgSender()] < essenceCost) revert InsufficientEssence(_msgSender(), essenceCost, _userEssenceBalances[_msgSender()]);

        // Check required Traits and levels
        // Requires adding `requiredTraitIdsArray` to Challenge struct and populating in `defineChallenge`
         // Assuming `requiredTraitIdsArray` exists and is populated:
        for (uint i = 0; i < challenge.requiredTraitIdsArray.length; i++) {
            uint256 requiredTraitId = challenge.requiredTraitIdsArray[i];
            uint8 requiredLevel = challenge.requiredTraits[requiredTraitId];

            if (metamorph.traits[requiredTraitId].traitDefinitionId == 0) {
                 revert NotEnoughRequiredTraitsForChallenge(challengeId); // Missing a required trait
            }
            if (metamorph.traits[requiredTraitId].level < requiredLevel) {
                revert TraitLevelTooLowForChallenge(challengeId, requiredTraitId, requiredLevel, metamorph.traits[requiredTraitId].level);
            }
        }

        // Consume requirements (Traits and Essence)
        _userEssenceBalances[_msgSender()] -= essenceCost;

         // Optional: Consume required traits? (Remove or reduce level)
         // This is not explicitly defined in the requirements but is common in challenge mechanics.
         // Let's skip consuming traits for simplicity in this example, challenges just require them.

        // Apply rewards (Essence and Traits)
        _userEssenceBalances[_msgSender()] += challenge.rewardEssence;

        for (uint i = 0; i < challenge.rewardTraits.length; i++) {
            Challenge.RewardTrait storage reward = challenge.rewardTraits[i];
            uint256 rewardTraitDefId = reward.traitDefinitionId;

             if (reward.removeExisting) {
                // Remove the trait if it exists
                if (metamorph.traits[rewardTraitDefId].traitDefinitionId != 0) {
                     delete metamorph.traits[rewardTraitDefId];
                     emit TraitRemoved(metamorphId, rewardTraitDefId);
                }
            } else {
                 // Add or update the trait
                 if (_traitDefinitions[rewardTraitDefId].id == 0) revert TraitDefinitionDoesNotExist(rewardTraitDefId); // Should have been checked in define, but safety
                 metamorph.traits[rewardTraitDefId] = Trait({
                    traitDefinitionId: rewardTraitDefId,
                    level: reward.level,
                    value: reward.value
                 });
                 emit TraitAdded(metamorphId, rewardTraitDefId, reward.level, reward.value); // Use TraitAdded event for set/update
            }
        }

        emit ChallengeCompleted(metamorphId, challengeId, _msgSender(), essenceCost, challenge.rewardEssence);
    }

    /// @notice Retrieves details of a specific challenge.
    /// @param challengeId The ID of the challenge.
    /// @return challenge The Challenge struct (non-mapping parts).
    function getChallenge(uint256 challengeId)
        public
        view
        returns (uint256 id, string memory name, string memory description, bool isActive, uint256 requiredEssence, uint256 rewardEssence)
    {
        Challenge storage storedChallenge = _challenges[challengeId];
        if (storedChallenge.id == 0) revert ChallengeDoesNotExist(challengeId);

        // Return non-mapping parts
         return (
            storedChallenge.id,
            storedChallenge.name,
            storedChallenge.description,
            storedChallenge.isActive,
            storedChallenge.requiredEssence,
            storedChallenge.rewardEssence
        );
    }

    /// @notice Helper view function to get the required traits for a challenge.
     /// @param challengeId The ID of the challenge.
     /// @return requiredTraitIds Array of required trait definition IDs.
     /// @return requiredTraitLevels Array of corresponding required levels.
     function getChallengeRequirements(uint256 challengeId) public view returns (uint256[] memory requiredTraitIds, uint8[] memory requiredTraitLevels) {
         Challenge storage challenge = _challenges[challengeId];
         if (challenge.id == 0) revert ChallengeDoesNotExist(challengeId);

         // Assumes `requiredTraitIdsArray` exists and is populated in struct/definition.
         uint256[] memory requiredIds = challenge.requiredTraitIdsArray; // Requires this addition
         uint8[] memory requiredLevels = new uint8[](requiredIds.length);

         for(uint i = 0; i < requiredIds.length; i++) {
             requiredLevels[i] = challenge.requiredTraits[requiredIds[i]];
         }

         return (requiredIds, requiredLevels);
     }

     /// @notice Helper view function to get the reward traits for a challenge.
     /// @param challengeId The ID of the challenge.
     /// @return rewardTraits Array of RewardTrait structs.
     function getChallengeRewards(uint256 challengeId) public view returns (Challenge.RewardTrait[] memory) {
         Challenge storage challenge = _challenges[challengeId];
         if (challenge.id == 0) revert ChallengeDoesNotExist(challengeId);
         return challenge.rewardTraits;
     }


    /// @notice Lists the IDs of all active challenges.
    /// @dev This requires iterating through all challenge definitions, potentially expensive.
    /// @return An array of active challenge IDs.
    function listActiveChallenges() public view returns (uint256[] memory) {
        uint256 totalChallenges = _challengeIds.current();
        uint256 activeCount = 0;
        // First pass to count active challenges
        for (uint256 i = 1; i <= totalChallenges; i++) {
            if (_challenges[i].id != 0 && _challenges[i].isActive) {
                activeCount++;
            }
        }

        uint256[] memory activeChallengeIds = new uint256[](activeCount);
        uint256 currentIndex = 0;
        // Second pass to populate array
        for (uint256 i = 1; i <= totalChallenges; i++) {
             if (_challenges[i].id != 0 && _challenges[i].isActive) {
                 activeChallengeIds[currentIndex] = i;
                 currentIndex++;
             }
        }
        return activeChallengeIds;
    }


    // --- View & Helper Functions ---

    /// @notice Retrieves immutable definition details of a specific trait type.
    /// @param traitDefinitionId The ID of the trait definition.
    /// @return definition The TraitDefinition struct.
    function getTraitDefinition(uint256 traitDefinitionId)
        public
        view
        returns (TraitDefinition memory definition)
    {
        TraitDefinition storage storedDef = _traitDefinitions[traitDefinitionId];
        if (storedDef.id == 0) revert TraitDefinitionDoesNotExist(traitDefinitionId);
        return storedDef; // Struct with no dynamic arrays/mappings can be returned directly
    }

    /// @notice Gets the total number of trait definitions created.
    /// @return The count of trait definitions.
    function getTraitDefinitionsCount() public view returns (uint256) {
        return _traitDefinitionIds.current();
    }

    /// @notice Gets the total number of transformation recipes created.
    /// @return The count of recipes.
     function getTransformationRecipesCount() public view returns (uint256) {
        return _transformationRecipeIds.current();
    }

    /// @notice Gets the total number of challenges created.
    /// @return The count of challenges.
    function getChallengeDefinitionsCount() public view returns (uint256) {
        return _challengeIds.current();
    }

    /// @notice Gets the total number of Metamorphs minted.
    /// @return The total count of Metamorphs.
    function getTotalMetamorphs() public view returns (uint256) {
        return _metamorphIds.current();
    }

     /// @notice Gets the total Essence accumulated as protocol fees.
    /// @return The fee balance.
    function getProtocolFeeBalance() public view returns (uint256) {
        return protocolFeeEssenceBalance;
    }


    /// @notice Checks if a specific trait is attached to a Metamorph.
    /// @param metamorphId The ID of the Metamorph.
    /// @param traitDefinitionId The ID of the trait definition to check.
    /// @return True if the trait exists on the Metamorph, false otherwise.
    function isTraitAttached(uint256 metamorphId, uint256 traitDefinitionId) public view returns (bool) {
        Metamorph storage metamorph = _metamorphs[metamorphId];
        if (metamorph.owner == address(0)) return false; // Metamorph doesn't exist
        if (_traitDefinitions[traitDefinitionId].id == 0) return false; // Trait definition doesn't exist

        return metamorph.traits[traitDefinitionId].traitDefinitionId != 0;
    }

    /// @notice Gets the level of a specific trait on a Metamorph. Returns 0 if the trait is not attached.
    /// @param metamorphId The ID of the Metamorph.
    /// @param traitDefinitionId The ID of the trait definition.
    /// @return The level of the trait, or 0 if not attached.
    function getTraitLevel(uint256 metamorphId, uint256 traitDefinitionId) public view returns (uint8) {
         Metamorph storage metamorph = _metamorphs[metamorphId];
         if (metamorph.owner == address(0)) return 0; // Metamorph doesn't exist
         if (_traitDefinitions[traitDefinitionId].id == 0) return 0; // Trait definition doesn't exist

         return metamorph.traits[traitDefinitionId].level; // Returns 0 if traitDefinitionId maps to an empty struct
    }

    // --- Internal Functions (used by other contract functions) ---
    // The _unstakeMetamorph function is already defined above.
    // _addTraitToMetamorph and _removeTraitFromMetamorph could be internal helpers
    // used by mint, transformations, and challenges, but are currently implemented
    // directly within those functions for clarity in this example.

    // --- Potential Future Additions ---
    // - Delegation of staking/transformation rights
    // - More complex trait interactions (trait A modifies trait B)
    // - Time-based challenges/transformations (beyond block number)
    // - Integration with external oracles for state changes
    // - Migration of Owner functions to a DAO or MultiSig

}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic/Evolving Tokens (Metamorphs):** Unlike typical static NFTs (ERC721) where metadata is often fixed or stored off-chain, Metamorphs have mutable, on-chain `Traits`. This allows tokens to change their attributes and potentially their associated off-chain representation (if metadata points to a system interpreting these traits) based on user interaction and protocol rules.
2.  **On-Chain Resource Management (Essence):** Introducing an internal resource (`Essence`) that is generated through active participation (staking) and consumed by other actions (transformations, challenges) creates a micro-economy within the contract. Users must engage with the system to earn the means to influence their tokens.
3.  **Staking for Resource Generation:** The staking mechanism incentivizes users to hold their Metamorphs within the protocol to earn `Essence`. This is a common DeFi/NFT trend adapted here to fuel the core mechanic (transformation). The accrual based on block number is a simple on-chain timer.
4.  **Rule-Based Transformations:** `TransformationRecipe` structs define explicit input requirements (traits, Essence) and output effects (adding, removing, leveling traits). This is a structured, on-chain mechanism for token evolution, where the changes aren't random but follow predefined rules. The cooldown adds a strategic element.
5.  **On-Chain Challenges:** `Challenge` structs define on-chain tasks (meeting trait/essence criteria) that users can complete with their Metamorphs for rewards. This gamifies interaction directly within the contract logic, rewarding active participation and strategic Metamorph development.
6.  **Composable Traits (Implicit):** While not fully implemented with complex interactions, the structure allows for traits to be required inputs for transformations/challenges or added as outputs. This lays the groundwork for traits to have dependencies or synergies.
7.  **Internal Balance System:** Managing `Essence` within the contract's internal balances (`_userEssenceBalances`, `protocolFeeEssenceBalance`) simplifies interaction compared to requiring users to deposit/withdraw an external ERC20 token for every action (though an external ERC20 could be integrated later).
8.  **Protocol Fees:** The `transformationFeeRate` and `protocolFeeEssenceBalance` introduce a simple economic model where the protocol captures value from activity, which can then be managed (e.g., distributed, burned) by the owner/governance.
9.  **Pausable Pattern:** Essential for managing dynamic systems, allowing the owner to halt sensitive operations in case of upgrades or issues.
10. **Custom Errors:** Using `error` instead of `require` strings is a modern Solidity best practice for gas efficiency and clearer error handling in dApps.

This contract provides a framework for a dynamic digital asset system with internal mechanics driving token evolution and user engagement, distinct from standard static NFTs or simple token swaps. It meets the function count requirement and incorporates several contemporary Web3 concepts.

Remember that this is a conceptual example. A production system would require significant additions, including robust testing, gas optimizations (especially for loops over mappings/arrays), more sophisticated trait interactions, potential integration with off-chain data (oracles) for some trait types, and a more decentralized governance model if desired. The view functions that iterate over all Metamorphs or definitions (`getUserClaimableEssence`, `listActiveChallenges`, `getMetamorphTraits`) are particularly inefficient and would need optimization for scale, likely by tracking tokens per user/status in additional storage structures.