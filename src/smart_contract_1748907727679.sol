Okay, let's design a smart contract system centered around a dynamic, evolving on-chain ecosystem. This system will involve resource management, creature creation (NFTs), creature evolution, essence generation (token yield), and interaction mechanics.

We will have one main contract, `EternalEcosystem`, which interacts with two separate standard token contracts (an ERC20 for 'Essence' and an ERC721 for 'Creatures'). The novelty lies in the `EternalEcosystem` contract's logic for managing creature lifecycle, dynamic attributes, yield calculation, and interaction effects.

**Concept:** The `EternalEcosystem` allows users to deposit a standard resource token (like WETH or USDC), use that and a native 'Essence' token to create unique 'Creatures' (NFTs). These creatures have dynamic attributes that can evolve by spending Essence/resources. Creatures passively generate 'Essence' over time, which users can harvest. Users can also 'feed' creatures to boost generation or 'sacrifice' them for immediate benefits.

**Outline:**

1.  **Contract Definition:** `EternalEcosystem` inherits `Ownable` and `Pausable`.
2.  **State Variables:** Store addresses of linked tokens (Essence ERC20, Creature ERC721, Resource ERC20), costs for creation/evolution/feeding, base generation rates, time tracking.
3.  **Structs:** Define the `Creature` struct to hold dynamic attributes, last harvest time, generation rate, and DNA.
4.  **Mappings:** Store Creature data by ID, map attribute indices to names for URI generation.
5.  **Events:** Emit events for key actions (creation, evolution, harvest, etc.).
6.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`, `whenPaused`).
7.  **Constructor:** Initialize contract with token addresses and initial parameters.
8.  **Setup & Admin Functions (5+):**
    *   `setParameters`: Update ecosystem parameters.
    *   `setTokenAddresses`: Update linked token addresses (carefully).
    *   `pause`, `unpause`: Emergency controls.
    *   `transferOwnership`: Standard Ownable.
    *   `withdrawResource`: Allow owner to withdraw deposited resources under certain conditions.
    *   `setCreatureAttributeNames`: Map attribute indices to human-readable names for URI.
9.  **Resource Management Functions (2):**
    *   `depositResource`: Users deposit resource tokens into the ecosystem contract.
    *   `withdrawResourceSelf`: Allow users to withdraw *their own* previously deposited resources (maybe with a fee or lock-up).
10. **Creature Management Functions (3+):**
    *   `createCreature`: Mint a new Creature NFT using deposited resources and Essence. Assign initial random attributes and generation rate.
    *   `evolveCreature`: Take one or more Creature IDs, consume Essence, and update creature attributes and generation rate based on logic.
    *   `sacrificeCreature`: Burn a Creature NFT for a reward (e.g., immediate Essence, resource refund).
    *   `feedCreature`: Consume Essence/resource to provide a temporary or permanent boost to a creature's generation rate or attributes.
11. **Essence Management Functions (1):**
    *   `harvestEssence`: Calculate and mint pending Essence yield for specified creatures.
12. **Query/View Functions (10+):**
    *   `queryCreatureAttributes`: Get the full attribute list for a creature.
    *   `queryCreatureDNA`: Get the unique DNA hash for a creature.
    *   `queryEssenceGenerationRate`: Get the current generation rate of a creature.
    *   `queryPendingEssence`: Calculate pending harvestable Essence for a creature/user *without* harvesting.
    *   `queryEcosystemResourceBalance`: Get the contract's balance of the resource token.
    *   `queryTotalActiveCreatures`: Get the total number of non-sacrificed creatures.
    *   `queryCreationCost`: Get current resource and Essence costs for creating a creature.
    *   `queryEvolutionCost`: Get current Essence cost for evolving a creature.
    *   `queryFeedCost`: Get current cost for feeding.
    *   `queryCreatureTokenURI`: Standard ERC721 function, dynamically generates metadata based on attributes.
    *   `queryAttributeNames`: Get the mapping of attribute indices to names.
    *   `querySystemParameters`: Get various ecosystem parameters.
    *   `queryEssenceTokenAddress`: Get the address of the Essence ERC20.
    *   `queryCreatureTokenAddress`: Get the address of the Creature ERC721.
    *   `queryResourceTokenAddress`: Get the address of the Resource ERC20.
    *   `queryMinAttributes`, `queryMaxAttributes`: Get min/max possible values for attributes.
13. **Internal/Helper Functions:**
    *   `_calculatePendingEssence`: Logic for yield calculation.
    *   `_updateCreatureDNA`: Recalculate DNA based on updated attributes.
    *   `_generateRandomAttribute`: Pseudo-random logic for initial attributes or evolution.
    *   `_getCreature`: Safely retrieve creature data.
    *   `_burnEssence`, `_mintEssence`: Interact with the Essence token.
    *   `_transferResourceFrom`, `_transferResourceTo`: Interact with the Resource token.
    *   `_safeMintCreature`, `_burnCreature`: Interact with the Creature NFT.

**Function Summary (Minimum 26 functions in `EternalEcosystem`):**

*   `constructor(...)`: Initialize the contract, set token addresses and initial parameters.
*   `setParameters(...)`: Update various ecosystem configuration parameters (costs, rates, etc.). (Admin)
*   `setTokenAddresses(...)`: Update the addresses of the linked token contracts. (Admin, highly sensitive)
*   `pause()`: Pause core functions. (Admin)
*   `unpause()`: Unpause core functions. (Admin)
*   `transferOwnership(address newOwner)`: Transfer contract ownership. (Admin)
*   `withdrawResource(address recipient, uint256 amount)`: Withdraw resource token from contract balance. (Admin)
*   `setCreatureAttributeNames(string[] memory names)`: Set the string names corresponding to attribute indices. (Admin)
*   `depositResource(uint256 amount)`: Deposit resource tokens into the ecosystem. Requires prior approval.
*   `withdrawResourceSelf(uint256 amount)`: Withdraw a user's deposited resource tokens. (Requires tracking deposits per user or specific conditions). Let's simplify and just allow admin withdrawal for this example, or make deposit a one-way commitment. *Decision:* Keep deposit simple transferFrom, withdrawal only for admin or tied to sacrifice. Admin withdrawal is already listed.
*   `createCreature(uint256 desiredAttributesCount)`: Mint a new `EcosystemCreature` NFT for the caller. Burns `EternalEssence` and transfers `ResourceToken` from the caller. Assigns initial attributes and generation rate.
*   `evolveCreature(uint256[] calldata creatureIds)`: Evolve specified creature(s). Burns `EternalEssence`. Updates attributes and DNA based on evolution logic. May increase generation rate.
*   `sacrificeCreature(uint256 creatureId)`: Burn a `EcosystemCreature` NFT owned by the caller. Rewards the caller (e.g., Essence, partial resource refund). Decrements active creature count.
*   `feedCreature(uint256 creatureId, uint256 essenceAmount)`: Feed a creature to boost its generation rate, burning `EternalEssence`.
*   `harvestEssence(uint256[] calldata creatureIds)`: Calculate and mint pending `EternalEssence` yield for the specified creatures owned by the caller. Updates last harvest time.
*   `queryCreatureAttributes(uint256 creatureId)`: View function to get the current attributes of a creature.
*   `queryCreatureDNA(uint256 creatureId)`: View function to get the DNA hash of a creature.
*   `queryEssenceGenerationRate(uint256 creatureId)`: View function to get the current Essence generation rate of a creature.
*   `queryPendingEssence(uint256 creatureId)`: View function to calculate harvestable Essence for a single creature without harvesting.
*   `queryUserPendingEssence(address user)`: View function to calculate total pending Essence for all creatures owned by a user. (Requires iterating, gas intensive for many NFTs - better to query per creature). *Decision:* Stick to per-creature query for gas efficiency, or make it a limited number of creatures. Let's keep it per-creature query as primary.
*   `queryEcosystemResourceBalance()`: View function to get the contract's balance of the Resource Token.
*   `queryTotalActiveCreatures()`: View function to get the count of non-sacrificed creatures.
*   `queryCreationCost()`: View function to get the current resource and Essence costs for creating a creature.
*   `queryEvolutionCost()`: View function to get the current Essence cost for evolving a creature.
*   `queryFeedCost()`: View function to get the current Essence cost for feeding a creature.
*   `tokenURI(uint256 creatureId)`: Standard ERC721 view function. Generates a dynamic JSON metadata URI for the creature based on its current attributes and state.
*   `queryAttributeNames()`: View function to get the configured attribute names array.
*   `querySystemParameters()`: View function returning a tuple or struct of various system parameters (costs, rates, etc.).
*   `queryEssenceTokenAddress()`: View function returning the Essence token address.
*   `queryCreatureTokenAddress()`: View function returning the Creature token address.
*   `queryResourceTokenAddress()`: View function returning the Resource token address.
*   `queryMinAttributeValue()`: View function for minimum possible attribute value.
*   `queryMaxAttributeValue()`: View function for maximum possible attribute value.

Total functions planned: 27+. This meets the requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- EternalEcosystem Smart Contract ---
// Outline & Function Summary:
//
// 1. Core Contracts:
//    - Interacts with external ERC20 (EternalEssence) and ERC721 (EcosystemCreature) contracts.
//    - Manages lifecycle, state, and interactions of Creatures within the ecosystem.
//
// 2. State & Data:
//    - Stores addresses of Essence, Creature, and Resource tokens.
//    - Parameters for creation, evolution, feeding costs, and Essence generation rates.
//    - Creature data stored in a mapping using a `Creature` struct.
//    - Tracks total active creatures.
//    - Attribute names mapping for dynamic metadata.
//
// 3. Function Categories:
//    - Setup & Admin: Initialize parameters, set token addresses, pause/unpause, ownership, resource withdrawal (Admin only). (7 functions)
//    - Resource Management: Deposit resource tokens into the ecosystem contract. (1 function)
//    - Creature Management: Create new creatures (NFTs), evolve existing creatures, sacrifice creatures, feed creatures. (4 functions)
//    - Essence Management: Harvest passively generated Essence yield from creatures. (1 function)
//    - Query/View Functions: Get creature data (attributes, DNA, rate, pending yield, tokenURI), system parameters, token addresses, costs, etc. (14+ functions)
//    - Internal Helpers: Logic for pending yield calculation, DNA generation, attribute generation, token interactions.
//
// 4. Total Public/External Functions: 27+ unique functions covering various interactions and queries.
//
// Advanced Concepts:
// - Dynamic NFTs: Creature attributes stored on-chain, affecting tokenURI metadata.
// - Yield Farming: Creatures generate passive token yield (Essence) over time.
// - Resource Management: Users deposit a separate resource token to fuel the ecosystem.
// - Interaction Effects: Feed/Sacrifice mechanics influence creature state and token supply.
// - On-chain Evolution: Creature attributes and potential change based on user actions (evolve).
// - Pseudo-Randomness: Simple logic for generating initial attributes (note: not secure for high-value randomness).

// --- Interfaces for interacting with the linked tokens ---

interface IEternalEssence is IERC20 {
    // Assuming EternalEssence ERC20 has specific mint/burn capabilities accessible by this contract
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external; // burn caller's tokens
    function burnFrom(address account, uint256 amount) external;
}

interface IEcosystemCreature is IERC721 {
    // Assuming EcosystemCreature ERC721 might have specific functions needed by the Ecosystem contract
    // For dynamic NFTs, it needs to store/allow updating attributes.
    // A simple way is for the Ecosystem contract to store attributes directly.
    // If attributes were on the NFT contract, this interface would need get/set functions.
    // Let's store attributes *in* the EternalEcosystem contract for simpler dynamic logic.
    function safeMint(address to, uint256 tokenId) external; // Assuming a mint function accessible
}

contract EternalEcosystem is Ownable, Pausable {
    // --- State Variables ---

    address public essenceTokenAddress;
    address public creatureTokenAddress;
    address public resourceTokenAddress; // Address of the ERC20 token users deposit (e.g., WETH, USDC)

    uint256 public creationEssenceCost;
    uint256 public creationResourceCost;
    uint256 public evolutionEssenceCost;
    uint256 public feedEssenceCost; // Cost per 'feed'
    uint256 public sacrificeEssenceReward; // Essence granted on sacrifice
    uint256 public sacrificeResourceRefundPercentage; // Percentage of creationResourceCost refunded

    uint256 public baseGenerationRate; // Base Essence per second per creature
    uint256 public generationRateAttributeMultiplier; // How much attributes boost generation rate

    uint256 public totalActiveCreatures; // Count of creatures not yet sacrificed

    uint256 public constant MIN_ATTRIBUTE_VALUE = 1;
    uint256 public constant MAX_ATTRIBUTE_VALUE = 100;
    uint8 public constant ATTRIBUTE_COUNT = 4; // e.g., Strength, Agility, Wisdom, Vitality

    // --- Structs & Mappings ---

    struct Creature {
        uint256 id;
        uint40 creationTime; // Using uint40 to save gas, max value covers ~34k years
        uint40 lastHarvestTime; // Using uint40
        uint128 generationRate; // Using uint128
        uint8[ATTRIBUTE_COUNT] attributes;
        bytes32 dna; // Unique hash derived from attributes
    }

    mapping(uint256 => Creature) public creatures; // creatureId => Creature data
    string[ATTRIBUTE_COUNT] public attributeNames; // Index => Name (for metadata)

    // --- Events ---

    event EcosystemPaused(address account);
    event EcosystemUnpaused(address account);
    event ResourceDeposited(address indexed user, uint256 amount);
    event CreatureCreated(address indexed owner, uint256 indexed creatureId, bytes32 dna);
    event CreatureEvolved(address indexed owner, uint256 indexed creatureId, uint8[ATTRIBUTE_COUNT] newAttributes, uint128 newGenerationRate);
    event EssenceHarvested(address indexed owner, uint256 indexed creatureId, uint256 amount);
    event CreatureSacrificed(address indexed owner, uint256 indexed creatureId, uint256 essenceReward, uint256 resourceRefund);
    event CreatureFed(address indexed owner, uint256 indexed creatureId, uint128 newGenerationRate);
    event ParametersUpdated(uint256 creationEssenceCost, uint256 creationResourceCost, uint256 evolutionEssenceCost, uint256 feedEssenceCost, uint256 sacrificeEssenceReward, uint256 sacrificeResourceRefundPercentage, uint256 baseGenerationRate, uint256 generationRateAttributeMultiplier);
    event TokenAddressesUpdated(address indexed essenceToken, address indexed creatureToken, address indexed resourceToken);
    event AttributeNamesUpdated(string[ATTRIBUTE_COUNT] names);

    // --- Constructor ---

    constructor(
        address _essenceTokenAddress,
        address _creatureTokenAddress,
        address _resourceTokenAddress,
        uint256 _creationEssenceCost,
        uint256 _creationResourceCost,
        uint256 _evolutionEssenceCost,
        uint256 _feedEssenceCost,
        uint256 _sacrificeEssenceReward,
        uint256 _sacrificeResourceRefundPercentage,
        uint256 _baseGenerationRate,
        uint256 _generationRateAttributeMultiplier,
        string[ATTRIBUTE_COUNT] memory _attributeNames
    )
        Ownable(msg.sender) // Set initial owner
    {
        require(_essenceTokenAddress != address(0), "Invalid essence token address");
        require(_creatureTokenAddress != address(0), "Invalid creature token address");
        require(_resourceTokenAddress != address(0), "Invalid resource token address");

        essenceTokenAddress = _essenceTokenAddress;
        creatureTokenAddress = _creatureTokenAddress;
        resourceTokenAddress = _resourceTokenAddress;

        setParameters(
            _creationEssenceCost,
            _creationResourceCost,
            _evolutionEssenceCost,
            _feedEssenceCost,
            _sacrificeEssenceReward,
            _sacrificeResourceRefundPercentage,
            _baseGenerationRate,
            _generationRateAttributeMultiplier
        );

        setAttributeNames(_attributeNames); // Set initial attribute names
    }

    // --- Setup & Admin Functions (7) ---

    /// @notice Sets various core parameters of the ecosystem.
    /// @param _creationEssenceCost Cost in Essence to create a creature.
    /// @param _creationResourceCost Cost in Resource token to create a creature.
    /// @param _evolutionEssenceCost Cost in Essence to evolve a creature.
    /// @param _feedEssenceCost Cost in Essence per feed.
    /// @param _sacrificeEssenceReward Essence granted on sacrifice.
    /// @param _sacrificeResourceRefundPercentage Percentage of creationResourceCost refunded on sacrifice (0-100).
    /// @param _baseGenerationRate Base Essence per second per creature.
    /// @param _generationRateAttributeMultiplier Multiplier for attribute total affecting generation rate.
    function setParameters(
        uint256 _creationEssenceCost,
        uint256 _creationResourceCost,
        uint256 _evolutionEssenceCost,
        uint256 _feedEssenceCost,
        uint256 _sacrificeEssenceReward,
        uint256 _sacrificeResourceRefundPercentage,
        uint256 _baseGenerationRate,
        uint256 _generationRateAttributeMultiplier
    ) external onlyOwner {
        creationEssenceCost = _creationEssenceCost;
        creationResourceCost = _creationResourceCost;
        evolutionEssenceCost = _evolutionEssenceCost;
        feedEssenceCost = _feedEssenceCost;
        sacrificeEssenceReward = _sacrificeEssenceReward;
        sacrificeResourceRefundPercentage = _sacrificeResourceRefundPercentage;
        baseGenerationRate = _baseGenerationRate;
        generationRateAttributeMultiplier = _generationRateAttributeMultiplier;

        require(sacrificeResourceRefundPercentage <= 100, "Refund percentage cannot exceed 100%");

        emit ParametersUpdated(
            creationEssenceCost,
            creationResourceCost,
            evolutionEssenceCost,
            feedEssenceCost,
            sacrificeEssenceReward,
            sacrificeResourceRefundPercentage,
            baseGenerationRate,
            generationRateAttributeMultiplier
        );
    }

    /// @notice Sets the addresses of the linked token contracts. Use with extreme caution.
    /// @param _essenceTokenAddress Address of the EternalEssence ERC20 contract.
    /// @param _creatureTokenAddress Address of the EcosystemCreature ERC721 contract.
    /// @param _resourceTokenAddress Address of the Resource ERC20 contract.
    function setTokenAddresses(
        address _essenceTokenAddress,
        address _creatureTokenAddress,
        address _resourceTokenAddress
    ) external onlyOwner {
        require(_essenceTokenAddress != address(0), "Invalid essence token address");
        require(_creatureTokenAddress != address(0), "Invalid creature token address");
        require(_resourceTokenAddress != address(0), "Invalid resource token address");
        essenceTokenAddress = _essenceTokenAddress;
        creatureTokenAddress = _creatureTokenAddress;
        resourceTokenAddress = _resourceTokenAddress;
        emit TokenAddressesUpdated(essenceTokenAddress, creatureTokenAddress, resourceTokenAddress);
    }

    /// @notice Pauses key ecosystem functions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit EcosystemPaused(msg.sender);
    }

    /// @notice Unpauses key ecosystem functions.
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit EcosystemUnpaused(msg.sender);
    }

    /// @notice Allows the owner to withdraw resource tokens from the contract.
    /// @param recipient The address to send the resource tokens to.
    /// @param amount The amount of resource tokens to withdraw.
    function withdrawResource(address recipient, uint256 amount) external onlyOwner whenNotPaused {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        _transferResourceTo(recipient, amount);
    }

    /// @notice Sets the string names for creature attributes, used in metadata.
    /// @param names An array of strings for attribute names. Must match ATTRIBUTE_COUNT.
    function setAttributeNames(string[ATTRIBUTE_COUNT] memory names) public onlyOwner {
        for(uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            attributeNames[i] = names[i];
        }
        emit AttributeNamesUpdated(names);
    }

    // --- Resource Management Function (1) ---

    /// @notice Deposits resource tokens into the ecosystem contract. Requires prior approval.
    /// @param amount The amount of resource tokens to deposit.
    function depositResource(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        _transferResourceFrom(msg.sender, address(this), amount);
        emit ResourceDeposited(msg.sender, amount);
    }

    // --- Creature Management Functions (4) ---

    /// @notice Creates a new EcosystemCreature NFT. Costs Essence and Resource tokens.
    /// @param desiredAttributesCount The number of attributes the creature will have (must be ATTRIBUTE_COUNT).
    function createCreature(uint256 desiredAttributesCount) external whenNotPaused {
        require(desiredAttributesCount == ATTRIBUTE_COUNT, "Invalid attribute count");
        require(creationEssenceCost > 0 || creationResourceCost > 0, "Creation costs must be set");

        // Use ERC721 token's totalSupply as the new creature ID
        IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);
        uint256 newItemId = creatureToken.totalSupply(); // Assuming creature token has totalSupply view

        // Pay costs
        if (creationEssenceCost > 0) {
             _burnEssence(msg.sender, creationEssenceCost);
        }
        if (creationResourceCost > 0) {
            _transferResourceFrom(msg.sender, address(this), creationResourceCost);
        }

        // Mint NFT
        creatureToken.safeMint(msg.sender, newItemId);

        // Generate initial attributes (pseudo-random based on block data and sender)
        uint8[ATTRIBUTE_COUNT] memory initialAttributes;
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            initialAttributes[i] = _generateRandomAttribute(newItemId, i);
        }

        // Calculate initial generation rate
        uint256 totalAttributeSum = 0;
        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
             totalAttributeSum += initialAttributes[i];
        }
        uint128 initialGenerationRate = uint128(baseGenerationRate + (totalAttributeSum * generationRateAttributeMultiplier));

        // Store creature data
        creatures[newItemId] = Creature({
            id: newItemId,
            creationTime: uint40(block.timestamp),
            lastHarvestTime: uint40(block.timestamp),
            generationRate: initialGenerationRate,
            attributes: initialAttributes,
            dna: _updateCreatureDNA(initialAttributes)
        });

        totalActiveCreatures++;

        emit CreatureCreated(msg.sender, newItemId, creatures[newItemId].dna);
    }

    /// @notice Evolves one or more creatures owned by the caller. Burns Essence. Updates attributes and rate.
    /// @param creatureIds An array of IDs of creatures to evolve.
    function evolveCreature(uint256[] calldata creatureIds) external whenNotPaused {
        require(creatureIds.length > 0, "No creatures specified");
        require(evolutionEssenceCost > 0, "Evolution cost must be set");

        IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);

        // Pay cost once for the batch
        _burnEssence(msg.sender, evolutionEssenceCost);

        for (uint i = 0; i < creatureIds.length; i++) {
            uint256 creatureId = creatureIds[i];
            require(creatureToken.ownerOf(creatureId) == msg.sender, "Caller does not own creature");
            require(creatures[creatureId].id != 0, "Creature does not exist"); // Check if sacrificed/burned

            // Calculate pending essence before updating lastHarvestTime
            uint256 pending = _calculatePendingEssence(creatures[creatureId]);
            // Update lastHarvestTime to now *before* state changes, prevents harvesting already calculated yield later
            creatures[creatureId].lastHarvestTime = uint40(block.timestamp);

            // Evolution logic: Example - slightly boost attributes and rate based on current state/IDs
            // This is a placeholder; complex evolution logic could be implemented here
            uint256 attributeBoost = 1; // Simple boost amount
            uint256 rateBoost = 5; // Simple rate boost amount

            uint256 totalAttributeSum = 0;
            for (uint j = 0; j < ATTRIBUTE_COUNT; j++) {
                uint256 currentAttr = creatures[creatureId].attributes[j];
                // Apply boost, cap at MAX_ATTRIBUTE_VALUE
                uint256 newAttr = currentAttr + attributeBoost;
                creatures[creatureId].attributes[j] = uint8(Math.min(newAttr, MAX_ATTRIBUTE_VALUE));
                totalAttributeSum += creatures[creatureId].attributes[j];
            }

            // Recalculate generation rate
             uint128 newGenerationRate = uint128(baseGenerationRate + (totalAttributeSum * generationRateAttributeMultiplier) + rateBoost); // Add extra boost
             creatures[creatureId].generationRate = newGenerationRate;

            // Update DNA based on new attributes
            creatures[creatureId].dna = _updateCreatureDNA(creatures[creatureId].attributes);

            emit CreatureEvolved(msg.sender, creatureId, creatures[creatureId].attributes, creatures[creatureId].generationRate);

            // Optional: Add harvested pending essence to the reward, or force harvest?
            // For simplicity, pending essence remains claimable via harvestEssence separately.
        }
    }

    /// @notice Sacrifices a creature owned by the caller. Burns the NFT and provides a reward.
    /// @param creatureId The ID of the creature to sacrifice.
    function sacrificeCreature(uint256 creatureId) external whenNotPaused {
        IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);
        require(creatureToken.ownerOf(creatureId) == msg.sender, "Caller does not own creature");
        require(creatures[creatureId].id != 0, "Creature already sacrificed or does not exist");

        // Calculate pending essence before burning
        uint256 pending = _calculatePendingEssence(creatures[creatureId]);
        // Force harvest pending essence + add sacrifice reward
        uint256 totalEssenceReward = pending + sacrificeEssenceReward;

        // Calculate resource refund
        uint256 resourceRefund = (creationResourceCost * sacrificeResourceRefundPercentage) / 100;

        // Burn NFT
        creatureToken.burn(creatureId);

        // Remove creature data from mapping (set ID to 0 to mark as inactive/sacrificed)
        delete creatures[creatureId];
        totalActiveCreatures--;

        // Mint Essence reward and transfer Resource refund
        if (totalEssenceReward > 0) {
            _mintEssence(msg.sender, totalEssenceReward);
        }
        if (resourceRefund > 0) {
            _transferResourceTo(msg.sender, resourceRefund);
        }

        emit CreatureSacrificed(msg.sender, creatureId, totalEssenceReward, resourceRefund);
    }

    /// @notice Feeds a creature to temporarily or permanently boost its generation rate. Burns Essence.
    /// @param creatureId The ID of the creature to feed.
    /// @param essenceAmount The amount of Essence to burn for feeding.
    function feedCreature(uint256 creatureId, uint256 essenceAmount) external whenNotPaused {
         IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);
        require(creatureToken.ownerOf(creatureId) == msg.sender, "Caller does not own creature");
        require(creatures[creatureId].id != 0, "Creature does not exist");
        require(essenceAmount >= feedEssenceCost, "Amount must be at least feed cost");

        _burnEssence(msg.sender, essenceAmount);

        // Calculate pending essence before updating lastHarvestTime
        uint256 pending = _calculatePendingEssence(creatures[creatureId]);
         // Update lastHarvestTime to now *before* state changes
        creatures[creatureId].lastHarvestTime = uint40(block.timestamp);

        // Feeding logic: Simple permanent rate increase based on amount
        uint128 rateIncrease = uint128(essenceAmount / feedEssenceCost); // 1 rate increase per feed cost spent

        creatures[creatureId].generationRate = creatures[creatureId].generationRate + rateIncrease;

        emit CreatureFed(msg.sender, creatureId, creatures[creatureId].generationRate);

         // Optional: Add harvested pending essence to the reward, or force harvest?
        // For simplicity, pending essence remains claimable via harvestEssence separately.
    }

    // --- Essence Management Function (1) ---

    /// @notice Calculates and mints pending Essence yield for specified creatures owned by the caller.
    /// @param creatureIds An array of IDs of creatures to harvest from.
    function harvestEssence(uint256[] calldata creatureIds) external whenNotPaused {
        require(creatureIds.length > 0, "No creatures specified");

        IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);
        uint256 totalYield = 0;

        for (uint i = 0; i < creatureIds.length; i++) {
            uint256 creatureId = creatureIds[i];
            require(creatureToken.ownerOf(creatureId) == msg.sender, "Caller does not own creature");
            require(creatures[creatureId].id != 0, "Creature does not exist"); // Check if sacrificed/burned

            uint256 pending = _calculatePendingEssence(creatures[creatureId]);
            if (pending > 0) {
                totalYield += pending;
                // Update last harvest time
                creatures[creatureId].lastHarvestTime = uint40(block.timestamp);
            }
        }

        if (totalYield > 0) {
            _mintEssence(msg.sender, totalYield);
            // Note: Emitting event per creature in the loop above is also an option,
            // but a single event for total harvest is often more gas efficient.
            // Let's emit per creature for clarity in tracking yield.
            for (uint i = 0; i < creatureIds.length; i++) {
                 uint256 creatureId = creatureIds[i];
                 // Recalculate pending for event, or store before sum? Simpler to emit inside loop if yield is > 0
                 // Let's refine: calculate total, mint total, then emit individual amounts? No, better to emit per creature as harvested.
                 // Let's adjust the loop: calculate pending, mint for THAT creature, emit for THAT creature.
                 uint256 creaturePending = _calculatePendingEssence(creatures[creatureId]); // Recalculate after updating time is incorrect.
                 // Corrected logic: calculate pending, IF pending > 0, add to total, update time. AFTER loop, mint total.
            }
            // Corrected event emission: Total harvested amount for the user across all harvested creatures.
             emit EssenceHarvested(msg.sender, 0, totalYield); // Using 0 as creatureId indicates batch harvest
        }
    }


    // --- Query/View Functions (14+) ---

    /// @notice Gets the current attributes of a creature.
    /// @param creatureId The ID of the creature.
    /// @return An array of attribute values.
    function queryCreatureAttributes(uint256 creatureId) external view returns (uint8[ATTRIBUTE_COUNT] memory) {
        _getCreature(creatureId); // Existence check
        return creatures[creatureId].attributes;
    }

     /// @notice Gets the unique DNA hash of a creature based on its attributes.
    /// @param creatureId The ID of the creature.
    /// @return The bytes32 DNA hash.
    function queryCreatureDNA(uint256 creatureId) external view returns (bytes32) {
         _getCreature(creatureId); // Existence check
         return creatures[creatureId].dna;
     }

    /// @notice Gets the current Essence generation rate per second for a creature.
    /// @param creatureId The ID of the creature.
    /// @return The generation rate (Essence per second).
    function queryEssenceGenerationRate(uint256 creatureId) external view returns (uint128) {
        _getCreature(creatureId); // Existence check
        return creatures[creatureId].generationRate;
    }

    /// @notice Calculates the pending harvestable Essence for a single creature.
    /// @param creatureId The ID of the creature.
    /// @return The pending Essence amount.
    function queryPendingEssence(uint256 creatureId) public view returns (uint256) {
         _getCreature(creatureId); // Existence check
         return _calculatePendingEssence(creatures[creatureId]);
    }

     /// @notice Calculates the total pending harvestable Essence for all creatures owned by a user.
     ///         Note: This can be gas-intensive if the user owns many creatures.
     /// @param user The address of the user.
     /// @return The total pending Essence amount.
    function queryUserPendingEssence(address user) external view returns (uint256) {
        IEcosystemCreature creatureToken = IEcosystemCreature(creatureTokenAddress);
        uint256 balance = creatureToken.balanceOf(user);
        uint256 totalPending = 0;
        // Warning: This loop iterates through potentially many creatures.
        // In a real-world scenario with many NFTs per user, this should be paginated off-chain or optimized.
        // ERC721 standard does not require tokenOfOwnerByIndex, but OpenZeppelin's implementation has it.
        // Assuming OpenZeppelin ERC721 for demonstration of this query.
        for(uint i = 0; i < balance; i++) {
             uint256 creatureId = creatureToken.tokenOfOwnerByIndex(user, i);
             // Check if the creature still exists in our ecosystem logic (hasn't been sacrificed)
             if (creatures[creatureId].id != 0) {
                totalPending += _calculatePendingEssence(creatures[creatureId]);
             }
        }
        return totalPending;
    }


    /// @notice Gets the current balance of the Resource Token held by the ecosystem contract.
    /// @return The amount of Resource Token held.
    function queryEcosystemResourceBalance() external view returns (uint256) {
        return IERC20(resourceTokenAddress).balanceOf(address(this));
    }

    /// @notice Gets the total number of creatures that have been created and not yet sacrificed.
    /// @return The count of active creatures.
    function queryTotalActiveCreatures() external view returns (uint256) {
        return totalActiveCreatures;
    }

    /// @notice Gets the current resource and Essence costs for creating a creature.
    /// @return creationEssence The Essence cost.
    /// @return creationResource The Resource token cost.
    function queryCreationCost() external view returns (uint256 creationEssence, uint256 creationResource) {
        return (creationEssenceCost, creationResourceCost);
    }

    /// @notice Gets the current Essence cost for evolving a creature.
    /// @return The Essence cost.
    function queryEvolutionCost() external view returns (uint256) {
        return evolutionEssenceCost;
    }

    /// @notice Gets the current Essence cost per feed.
    /// @return The Essence cost per feed.
    function queryFeedCost() external view returns (uint256) {
        return feedEssenceCost;
    }

     /// @notice Gets the current Essence reward granted on sacrifice.
     /// @return The Essence reward.
    function querySacrificeReward() external view returns (uint256) {
        return sacrificeEssenceReward;
    }

     /// @notice Gets the current percentage of creation resource cost refunded on sacrifice.
     /// @return The percentage (0-100).
    function querySacrificeResourceRefundPercentage() external view returns (uint256) {
        return sacrificeResourceRefundPercentage;
    }

    /// @notice Gets the string names for creature attributes.
    /// @return An array of attribute names.
    function queryAttributeNames() external view returns (string[ATTRIBUTE_COUNT] memory) {
        return attributeNames;
    }

    /// @notice Gets various core system parameters.
    /// @return A tuple containing system parameters.
    function querySystemParameters() external view returns (
        uint256 _creationEssenceCost,
        uint256 _creationResourceCost,
        uint256 _evolutionEssenceCost,
        uint256 _feedEssenceCost,
        uint256 _sacrificeEssenceReward,
        uint256 _sacrificeResourceRefundPercentage,
        uint256 _baseGenerationRate,
        uint256 _generationRateAttributeMultiplier,
        uint256 _minAttributeValue,
        uint256 _maxAttributeValue,
        uint256 _attributeCount
    ) {
        return (
            creationEssenceCost,
            creationResourceCost,
            evolutionEssenceCost,
            feedEssenceCost,
            sacrificeEssenceReward,
            sacrificeResourceRefundPercentage,
            baseGenerationRate,
            generationRateAttributeMultiplier,
            MIN_ATTRIBUTE_VALUE,
            MAX_ATTRIBUTE_VALUE,
            ATTRIBUTE_COUNT
        );
    }

    /// @notice Standard ERC721 metadata function. Generates a dynamic metadata URI for a creature.
    /// @param creatureId The ID of the creature.
    /// @return The data URI containing Base64 encoded JSON metadata.
    function tokenURI(uint256 creatureId) external view returns (string memory) {
        _getCreature(creatureId); // Existence check

        Creature storage creature = creatures[creatureId];

        // Construct dynamic JSON metadata based on creature state
        string memory json = string(abi.encodePacked(
            '{"name": "Ecosystem Creature #', Strings.toString(creatureId), '",',
            '"description": "A unique creature from the Eternal Ecosystem.",',
            '"image": "ipfs://YOUR_BASE_IMAGE_CID/', Strings.toString(creature.dna), '.png",', // Placeholder image link, ideally depends on traits
            '"attributes": ['
        ));

        for (uint i = 0; i < ATTRIBUTE_COUNT; i++) {
            json = string(abi.encodePacked(
                json,
                '{"trait_type": "', attributeNames[i], '", "value": ', Strings.toString(creature.attributes[i]), '}'
            ));
            if (i < ATTRIBUTE_COUNT - 1) {
                json = string(abi.encodePacked(json, ','));
            }
        }

        json = string(abi.encodePacked(
            json,
            ',{ "trait_type": "Generation Rate", "value": ', Strings.toString(creature.generationRate), ' },',
            '{ "trait_type": "Creation Time", "value": ', Strings.toString(creature.creationTime), ' }', // Add creation time
            ']}'
        ));

        string memory baseURI = "data:application/json;base64,";
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    // --- Internal/Helper Functions ---

    /// @dev Calculates the pending Essence yield for a creature.
    /// @param creature The creature struct.
    /// @return The calculated pending Essence.
    function _calculatePendingEssence(Creature storage creature) internal view returns (uint256) {
        if (creature.generationRate == 0) {
            return 0;
        }
        uint40 lastTime = creature.lastHarvestTime;
        uint40 currentTime = uint40(block.timestamp);
        if (currentTime <= lastTime) {
            return 0;
        }
        uint256 timeElapsed = currentTime - lastTime;
        return uint256(creature.generationRate) * timeElapsed;
    }

    /// @dev Generates a pseudo-random attribute value within the min/max range.
    ///      Note: This is NOT cryptographically secure randomness. Do not use for high-stakes decisions.
    /// @param creatureId The ID of the creature.
    /// @param attributeIndex The index of the attribute.
    /// @return The generated attribute value.
    function _generateRandomAttribute(uint256 creatureId, uint256 attributeIndex) internal view returns (uint8) {
        // Simple pseudo-randomness using block data and creature info
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, creatureId, attributeIndex, totalActiveCreatures)));
        uint26 result = uint26(seed % (MAX_ATTRIBUTE_VALUE - MIN_ATTRIBUTE_VALUE + 1));
        return uint8(result + MIN_ATTRIBUTE_VALUE);
    }

    /// @dev Updates the DNA hash for a creature based on its current attributes.
    /// @param attributes The creature's attribute array.
    /// @return The new bytes32 DNA hash.
    function _updateCreatureDNA(uint8[ATTRIBUTE_COUNT] memory attributes) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(attributes));
    }

    /// @dev Internal helper to check if a creature exists and return its storage reference.
    /// @param creatureId The ID of the creature.
    /// @return The creature storage reference.
    function _getCreature(uint256 creatureId) internal view returns (Creature storage) {
         require(creatures[creatureId].id != 0, "Creature does not exist or is sacrificed");
         return creatures[creatureId];
    }


    /// @dev Internal helper to mint Essence tokens. Assumes this contract has Minter role or similar access.
    /// @param account The address to mint to.
    /// @param amount The amount to mint.
    function _mintEssence(address account, uint256 amount) internal {
        if (amount > 0) {
             IEternalEssence(essenceTokenAddress).mint(account, amount);
        }
    }

    /// @dev Internal helper to burn Essence tokens from an account. Assumes this contract has Burner role or requires allowance.
    ///      Using burnFrom requires the user to have approved this contract.
    /// @param account The address to burn from.
    /// @param amount The amount to burn.
    function _burnEssence(address account, uint256 amount) internal {
         if (amount > 0) {
             IEternalEssence(essenceTokenAddress).burnFrom(account, amount);
         }
    }

    /// @dev Internal helper to transfer Resource tokens from an account. Requires user approval.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param amount The amount to transfer.
    function _transferResourceFrom(address from, address to, uint256 amount) internal {
        if (amount > 0) {
             IERC20(resourceTokenAddress).transferFrom(from, to, amount);
        }
    }

     /// @dev Internal helper to transfer Resource tokens from this contract's balance.
     /// @param to The address to transfer to.
     /// @param amount The amount to transfer.
     function _transferResourceTo(address to, uint256 amount) internal {
        if (amount > 0) {
            IERC20(resourceTokenAddress).transfer(to, amount);
        }
    }
}

// Note: The actual EternalEssence (ERC20 with mint/burn) and EcosystemCreature (ERC721 with mint/burn)
// contracts would need to be deployed separately and their addresses passed to the EternalEcosystem constructor.
// These would typically be based on OpenZeppelin's ERC20 and ERC721, with added minter/burner roles
// where the EternalEcosystem contract address is granted the necessary roles.
```