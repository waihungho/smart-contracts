Okay, here is a Solidity smart contract implementing a Dynamic NFT (DNFT) Forge concept. This contract focuses on NFTs whose attributes and metadata can change based on on-chain interactions, time, and contract-level events. It incorporates concepts like state evolution, timed decay, role-based attribute modification, and dynamic metadata based on on-chain state.

It builds upon standard ERC721 but adds significant custom logic beyond basic minting, transferring, and ownership. The functions listed in the summary are the *custom* functions implemented for the dynamic features, aiming for well over the requested 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Contract: DynamicNFTForge ---
// Outline:
// 1. Inherits ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard.
// 2. Defines custom errors for clarity and gas efficiency.
// 3. Defines structs for TokenAttributes and AttributeModifiers.
// 4. Defines enums for AttributeTypes and GlobalEvents.
// 5. Stores core contract state: token attributes, forge level, global event state, modifiers, prices, supply.
// 6. Emits events for significant state changes (mint, attribute update, level up, interaction, event trigger).
// 7. Constructor initializes base contract, owner, and initial state.
// 8. Includes functions for:
//    - Minting with dynamic initial attributes and price.
//    - Token interaction and evolution (leveling, attribute decay).
//    - Contract-level dynamics (forge upgrades, global events, seasonal changes).
//    - Admin/Owner controls (pausing, setting prices, modifiers, max supply, withdrawing funds).
//    - View functions to query token state, contract state, and dynamic properties.
//    - Overrides tokenURI to reflect dynamic on-chain state.

// Function Summary (Custom Functions > 20):
// Minting & Supply:
// 1. mint() payable: Mints a new token, assigns initial attributes based on contract state/randomness.
// 2. batchMint(uint256 count) payable: Mints multiple tokens.
// 3. setMintPrice(uint256 price): Sets the price for minting a token.
// 4. setMaxSupply(uint256 maxSupply): Sets the maximum number of tokens that can be minted.
// 5. getCurrentSupply() view: Gets the current total supply of minted tokens.
//
// Token Interaction & Evolution:
// 6. interact(uint256 tokenId): User interaction function. Updates last interaction time, potentially applies temporary buffs.
// 7. levelUp(uint256 tokenId): Allows token owner to attempt leveling up a token if conditions are met.
// 8. decayAttributes(uint256 tokenId): Applies attribute decay based on inactivity. Can be called by anyone (incentivized off-chain or batch by owner).
//
// Dynamic Attribute Management:
// 9. getTokenAttributes(uint256 tokenId) view: Gets the mutable attributes of a specific token.
// 10. getMutableMetadata(uint256 tokenId) view: Gets the core data needed by an off-chain service to generate dynamic metadata.
// 11. calculateCurrentAttributes(uint256 tokenId) view: Calculates effective attributes including decay and global/seasonal modifiers.
// 12. calculatePotentialDecay(uint256 tokenId) view: Shows how much decay would apply now based on inactivity.
// 13. setAttributeBaseCap(AttributeType attributeType, uint256 cap): Sets the base maximum value for an attribute type.
// 14. getAttributeBaseCap(AttributeType attributeType) view: Gets the base maximum value for an attribute type.
// 15. getAttributeEffectiveCap(AttributeType attributeType) view: Gets the effective maximum value considering forge level.
//
// Contract-Level Dynamics (Admin/Oracle):
// 16. upgradeForgeLevel(): Increases the contract's 'forge level', potentially unlocking higher attribute caps.
// 17. setForgeAttributeModifiers(AttributeModifiers calldata modifiers): Sets attribute modifiers based on the current forge level.
// 18. applySeasonalModifier(AttributeModifiers calldata modifiers): Sets contract-wide seasonal attribute modifiers.
// 19. triggerGlobalEvent(GlobalEvent eventType, AttributeModifiers calldata modifiers, uint64 duration): Activates a global event with specific modifiers for a duration.
// 20. endGlobalEvent(): Ends the current global event.
// 21. getForgeLevel() view: Gets the current forge level of the forge.
// 22. getAppliedAttributeModifiers() view: Gets the currently active global/seasonal attribute modifiers.
// 23. getGlobalEventState() view: Gets information about the active global event.
//
// Admin & Utility:
// 24. pauseContract(): Pauses minting and interactions.
// 25. unpauseContract(): Unpauses the contract.
// 26. withdrawFunds(): Withdraws accumulated Ether from minting.
// 27. setBaseURI(string memory baseURI): Sets the base URI for token metadata.
// 28. getTokenCreationTime(uint256 tokenId) view: Gets the timestamp when a token was minted.
// 29. setInteractionCooldown(uint64 cooldown): Sets the minimum time between interactions for a token.
// 30. getInteractionCooldown() view: Gets the interaction cooldown duration.
// 31. setLevelUpRequirements(uint256 level, uint256 interactionsRequired, uint64 minTimeBetweenInteractions): Sets criteria for leveling up.
// 32. getLevelUpRequirements(uint256 level) view: Gets criteria for a specific level.

// Note: This contract uses placeholder logic for randomness and external data dependency (like oracles for seasonal events).
// In a real application, you would integrate with Chainlink VRF for randomness and Chainlink Keepers/Oracles for off-chain data/timed events.
// The `tokenURI` expects an off-chain service that queries the on-chain state via the provided view functions
// (like `getMutableMetadata`, `getAppliedAttributeModifiers`) to generate the final metadata JSON.

contract DynamicNFTForge is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Custom Errors ---
    error MaxSupplyReached();
    error InsufficientPayment();
    error InvalidTokenId();
    error NotTokenOwner();
    error ForgeAlreadyMaxLevel();
    error LevelUpRequirementsNotMet();
    error InteractionCooldownActive();
    error InvalidAttributeType();
    error GlobalEventNotActive();

    // --- Structs ---

    // Represents the core mutable attributes of a token
    struct TokenAttributes {
        uint256 strength;
        uint256 speed;
        uint256 endurance;
        uint256 level;
        uint64 lastInteractionTimestamp;
        uint64 creationTimestamp;
        // Add other mutable attributes here
    }

    // Represents modifiers applied to attributes (e.g., from forge level, season, event)
    // Value is applied as a flat modifier (can be positive or negative)
    struct AttributeModifiers {
        int256 strengthModifier;
        int256 speedModifier;
        int256 enduranceModifier;
        // Add modifiers for other attributes here
    }

    // Represents the state of an active global event
    struct GlobalEventState {
        GlobalEvent eventType;
        AttributeModifiers modifiers;
        uint64 endTime;
        bool isActive;
    }

    // --- Enums ---
    enum AttributeType { Strength, Speed, Endurance }
    enum GlobalEvent { None, Seasonal, SpecialEvent1, SpecialEvent2 } // Define types of events

    // --- State Variables ---

    // Token Data
    mapping(uint256 => TokenAttributes) private _tokenAttributes;
    mapping(AttributeType => uint256) private _attributeBaseCaps; // Base max value for attributes before forge level

    // Contract State
    uint256 private _currentTokenId;
    uint256 private _maxSupply;
    uint256 private _mintPrice;
    uint256 private _forgeLevel; // Represents the overall progress/tier of the forge
    AttributeModifiers private _forgeAttributeModifiers; // Modifiers based on forge level
    AttributeModifiers private _seasonalAttributeModifiers; // Modifiers based on 'season' (updated by owner/oracle)
    GlobalEventState private _currentGlobalEvent;

    uint64 private _interactionCooldown = 1 days; // Cooldown duration between interactions
    mapping(uint256 => uint256) private _interactionsCount; // Example: track total interactions for level up
    mapping(uint256 => uint256) private _levelUpRequirementsInteractions; // Interactions needed per level
    mapping(uint256 => uint64) private _levelUpRequirementsMinTimeBetweenInteractions; // Minimum time between interactions for leveling

    // Randomness source - placeholder, ideally Chainlink VRF
    address private _randomnessSource;

    // Oracle address - placeholder for potential external data triggers
    address private _oracleAddress;

    // --- Events ---
    event TokenMinted(address indexed owner, uint256 indexed tokenId, TokenAttributes initialAttributes);
    event TokenAttributesUpdated(uint256 indexed tokenId, TokenAttributes newAttributes);
    event TokenLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event TokenInteracted(uint256 indexed tokenId, uint64 interactionTimestamp);
    event ForgeLevelUpgraded(uint256 newLevel);
    event ForgeAttributeModifiersUpdated(AttributeModifiers modifiers);
    event SeasonalModifiersUpdated(AttributeModifiers modifiers);
    event GlobalEventTriggered(GlobalEvent indexed eventType, uint64 endTime);
    event GlobalEventEnded(GlobalEvent indexed eventType);
    event MintPriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event InteractionCooldownUpdated(uint64 newCooldown);
    event LevelUpRequirementsUpdated(uint256 level, uint256 interactionsRequired, uint64 minTimeBetweenInteractions);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialMintPrice, uint256 initialMaxSupply)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721URIStorage()
        Ownable(msg.sender)
        Pausable()
        ReentrancyGuard()
    {
        _mintPrice = initialMintPrice;
        _maxSupply = initialMaxSupply;
        _forgeLevel = 1; // Start at level 1

        // Set some default base attribute caps
        _attributeBaseCaps[AttributeType.Strength] = 100;
        _attributeBaseCaps[AttributeType.Speed] = 100;
        _attributeBaseCaps[AttributeType.Endurance] = 100;

        // Set default level up requirements (example: level 2 requires 5 interactions)
        _levelUpRequirementsInteractions[1] = 5;
        _levelUpRequirementsMinTimeBetweenInteractions[1] = 1 hours; // E.g., interactions must be at least 1 hour apart to count towards leveling

        // Set placeholder addresses (should be configured later)
        _randomnessSource = address(0); // Replace with actual VRF Coordinator address
        _oracleAddress = address(0); // Replace with actual Oracle address
    }

    // --- Receive Ether for Minting ---
    receive() external payable {
        // Allow receiving ether for minting
    }

    // --- Minting Functions ---

    /// @notice Mints a new token with initial dynamic attributes.
    /// @dev Requires payment equal to the current mint price. Attributes are initialized based on forge level and randomness (placeholder).
    /// @param to The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mint(address to) external payable whenNotPaused nonReentrancy returns (uint256) {
        if (totalSupply() >= _maxSupply) {
            revert MaxSupplyReached();
        }
        if (msg.value < _mintPrice) {
            revert InsufficientPayment();
        }

        uint256 newTokenId = _currentTokenId++;
        _safeMint(to, newTokenId);

        // Initialize token attributes dynamically
        // In a real contract, this would involve more complex logic, potentially randomness (VRF),
        // and factors like forge level, global events, etc.
        // Placeholder: Basic initialization based on forge level
        _tokenAttributes[newTokenId] = TokenAttributes({
            strength: 10 + (_forgeLevel * 5), // Base + level boost
            speed: 10 + (_forgeLevel * 5),
            endurance: 10 + (_forgeLevel * 5),
            level: 1,
            lastInteractionTimestamp: uint64(block.timestamp), // Start fresh
            creationTimestamp: uint64(block.timestamp)
        });
        _interactionsCount[newTokenId] = 0; // Reset interaction count for new token

        emit TokenMinted(to, newTokenId, _tokenAttributes[newTokenId]);

        // Refund excess Ether if any
        if (msg.value > _mintPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - _mintPrice}("");
            require(success, "Refund failed");
        }

        return newTokenId;
    }

    /// @notice Mints multiple tokens in a single transaction.
    /// @dev Requires total payment equal to count * mint price.
    /// @param to The address to mint tokens to.
    /// @param count The number of tokens to mint.
    function batchMint(address to, uint256 count) external payable whenNotPaused nonReentrancy {
        uint256 totalPrice = _mintPrice.mul(count);
        if (msg.value < totalPrice) {
            revert InsufficientPayment();
        }
        if (totalSupply().add(count) > _maxSupply) {
            revert MaxSupplyReached();
        }

        for (uint i = 0; i < count; i++) {
            uint256 newTokenId = _currentTokenId++;
            _safeMint(to, newTokenId);

            // Initialize token attributes (can be diversified based on index, randomness etc.)
             _tokenAttributes[newTokenId] = TokenAttributes({
                strength: 10 + (_forgeLevel * 5), // Base + level boost
                speed: 10 + (_forgeLevel * 5),
                endurance: 10 + (_forgeLevel * 5),
                level: 1,
                lastInteractionTimestamp: uint64(block.timestamp), // Start fresh
                creationTimestamp: uint64(block.timestamp)
            });
            _interactionsCount[newTokenId] = 0; // Reset interaction count for new token

            emit TokenMinted(to, newTokenId, _tokenAttributes[newTokenId]);
        }

        // Refund excess Ether
        if (msg.value > totalPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Batch refund failed");
        }
    }

    /// @notice Sets the price for minting a new token.
    /// @dev Only callable by the contract owner.
    /// @param price The new mint price in Wei.
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit MintPriceUpdated(price);
    }

    /// @notice Sets the maximum total supply of tokens that can be minted.
    /// @dev Only callable by the contract owner. Cannot set max supply below current supply.
    /// @param maxSupply The new maximum supply.
    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        require(maxSupply >= totalSupply(), "New max supply must be >= current supply");
        _maxSupply = maxSupply;
        emit MaxSupplyUpdated(maxSupply);
    }

    /// @notice Gets the current total supply of minted tokens.
    function getCurrentSupply() external view returns (uint256) {
        return totalSupply();
    }

    // --- Token Interaction & Evolution Functions ---

    /// @notice Allows a token owner to interact with their token.
    /// @dev Updates the last interaction timestamp. Can only be called by the token owner.
    /// Cooldown period applies between interactions.
    /// @param tokenId The ID of the token to interact with.
    function interact(uint256 tokenId) external nonReentrancy whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        TokenAttributes storage token = _tokenAttributes[tokenId];
        if (block.timestamp < token.lastInteractionTimestamp + _interactionCooldown) {
            revert InteractionCooldownActive();
        }

        token.lastInteractionTimestamp = uint64(block.timestamp);
        _interactionsCount[tokenId]++; // Increment interaction count for level up checks

        // Optional: Apply a temporary buff or small attribute gain on interaction
        // This could decay over time.
        // Example: token.speed += 1; (This would need careful management and decay logic)

        emit TokenInteracted(tokenId, token.lastInteractionTimestamp);
        emit TokenAttributesUpdated(tokenId, token); // Emit update event as timestamp changed
    }

    /// @notice Allows a token owner to attempt leveling up their token.
    /// @dev Requires meeting specific criteria (e.g., number of interactions, interaction frequency, forge level).
    /// Consumes the 'interactionsCount' and increases token level and potentially attributes.
    /// @param tokenId The ID of the token to level up.
    function levelUp(uint256 tokenId) external nonReentrancy whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        TokenAttributes storage token = _tokenAttributes[tokenId];
        uint256 currentLevel = token.level;
        uint256 nextLevel = currentLevel + 1;

        // Check if max level is reached (example cap)
        uint256 maxLevel = _forgeLevel * 5; // Example: max level depends on forge level
        if (currentLevel >= maxLevel) {
             revert LevelUpRequirementsNotMet(); // Or a specific MaxLevelReached error
        }

        // Check level-up requirements
        uint256 requiredInteractions = _levelUpRequirementsInteractions[currentLevel];
        uint64 requiredMinTimeBetween = _levelUpRequirementsMinTimeBetweenInteractions[currentLevel];

        // This is a simplified check. More advanced logic could track *when* interactions happened.
        // Here, we check total count and if the last interaction meets frequency criteria (a bit weak).
        // A better approach would be to store interaction timestamps or check a derived metric.
        // Simplified Check: Enough interactions and last interaction was recent enough?
        // Let's refine: Check if total interactions SINCE last level up meets requirement AND last interaction meets cooldown
        // This simplified check is still not perfect for the "minTimeBetweenInteractions" but works for total count.
        // A robust system would require more state (e.g., array of last N interaction timestamps).
        // For this example, let's just check total count >= required and last interaction is recent (within cooldown window is actually the opposite check, let's check *long enough* since last level?)
        // Simpler level up condition: Check total interactions count since last level up AND if enough time has passed since the *creation* or *last level up* to allow for interactions.
        // Let's stick to the initial simple interpretation: Enough *total* interactions and last interaction wasn't too long ago (or specific frequency check).
        // Refined simple check: Total interactions since MINITING >= required AND last interaction was recent enough (e.g., within last week) or meets a frequency pattern.
        // Let's simplify: Just check total interactions since *minting* or *last level* up meets req. AND the token is not "stale" (last interaction within a generous window).
        // New Plan: Check `_interactionsCount[tokenId]` >= required interactions for this level. Reset `_interactionsCount[tokenId]` on level up. Add a check that the token isn't extremely inactive (last interaction < 30 days ago?).
        // Let's use the simpler check: `_interactionsCount[tokenId]` >= requiredInteractions
         if (_interactionsCount[tokenId] < requiredInteractions) {
             revert LevelUpRequirementsNotMet(); // Not enough interactions
         }

        // Potential check for interaction frequency requirement (example)
        // This requires more state. Let's omit for this example complexity.
        // If we had interaction timestamps: Check if average time between interactions >= requiredMinTimeBetween.

        token.level = nextLevel;
        _interactionsCount[tokenId] = 0; // Reset interaction count for the new level progression

        // Increase attributes upon leveling up
        // This can incorporate randomness (placeholder) and level-specific boosts
        token.strength += 5 + (_forgeLevel / 2); // Example: static boost + small boost from forge level
        token.speed += 5 + (_forgeLevel / 2);
        token.endurance += 5 + (_forgeLevel / 2);

        // Cap attributes at their effective max (base cap + forge level modifier)
        token.strength = token.strength.min(getAttributeEffectiveCap(AttributeType.Strength));
        token.speed = token.speed.min(getAttributeEffectiveCap(AttributeType.Speed));
        token.endurance = token.endurance.min(getAttributeEffectiveCap(AttributeType.Endurance));


        emit TokenLeveledUp(tokenId, token.level);
        emit TokenAttributesUpdated(tokenId, token);
    }

    /// @notice Applies attribute decay to a token based on inactivity.
    /// @dev Can be called by anyone. Provides an incentive for keeping tokens active.
    /// Decay amount depends on time since last interaction and token level.
    /// @param tokenId The ID of the token to apply decay to.
    function decayAttributes(uint256 tokenId) external nonReentrancy whenNotPaused {
         if (!_exists(tokenId)) revert InvalidTokenId();

         TokenAttributes storage token = _tokenAttributes[tokenId];
         uint64 timeSinceLastInteraction = uint64(block.timestamp) - token.lastInteractionTimestamp;

         // No decay if recently interacted or already at base level (example: level 1 has no decay)
         if (timeSinceLastInteraction < 30 days || token.level <= 1) { // Example: decay starts after 30 days inactivity
             return;
         }

         // Calculate decay amount (example: percentage decay based on time and level)
         // Decay increases with inactivity time and token level (higher level = more to lose)
         uint256 decayFactor = timeSinceLastInteraction / (30 days); // 1x decay per 30 days inactive
         uint256 levelMultiplier = token.level > 0 ? token.level : 1; // Avoid div by zero, higher level = more potential decay

         // Example decay: (decayFactor * levelMultiplier)% of current value, minimum 1 unit lost per attribute
         uint256 decayAmountStrength = token.strength > 0 ? (token.strength * decayFactor * levelMultiplier / 100).max(1) : 0;
         uint256 decayAmountSpeed = token.speed > 0 ? (token.speed * decayFactor * levelMultiplier / 100).max(1) : 0;
         uint256 decayAmountEndurance = token.endurance > 0 ? (token.endurance * decayFactor * levelMultiplier / 100).max(1) : 0;

        // Apply decay, ensuring attributes don't go below a minimum (e.g., 1) or the base cap
        // Base cap might be too high, let's use a fixed minimum like 10, or tie to creation value
        // Let's use 10 as a minimum base value floor
        uint256 floor = 10;

         token.strength = token.strength > decayAmountStrength ? token.strength - decayAmountStrength : floor;
         token.speed = token.speed > decayAmountSpeed ? token.speed - decayAmountSpeed : floor;
         token.endurance = token.endurance > decayAmountEndurance ? token.endurance - decayAmountEndurance : floor;

         // Ensure attributes don't drop below a minimum floor (e.g., creation value or hardcoded minimum)
         // This part needs careful design. Should decay go below initial value? Below base cap?
         // Let's cap decay so attributes don't go below a minimum floor (e.g. 10)
         token.strength = token.strength < floor ? floor : token.strength;
         token.speed = token.speed < floor ? floor : token.speed;
         token.endurance = token.endurance < floor ? floor : token.endurance;


         emit TokenAttributesUpdated(tokenId, token);
    }

    // --- Dynamic Attribute View Functions ---

    /// @notice Gets the raw mutable attributes stored for a token.
    /// @dev These are the base attributes before decay or global/seasonal modifiers are applied.
    /// @param tokenId The ID of the token.
    /// @return The TokenAttributes struct.
    function getTokenAttributes(uint256 tokenId) public view returns (TokenAttributes memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenAttributes[tokenId];
    }

    /// @notice Gets the core mutable data needed by an off-chain metadata service.
    /// @dev This function provides the on-chain state necessary to generate dynamic metadata.
    /// @param tokenId The ID of the token.
    /// @return struct containing token attributes, current level, last interaction, etc.
    function getMutableMetadata(uint256 tokenId) public view returns (TokenAttributes memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        // This function simply returns the base attributes, interaction time, level etc.
        // The off-chain service combines this with contract-level state (forge level, global events)
        // by calling other view functions (`getForgeLevel`, `getAppliedAttributeModifiers`, `getGlobalEventState`)
        // to generate the final effective attributes and description.
        return _tokenAttributes[tokenId];
    }

    /// @notice Calculates the effective attributes of a token including decay and all active modifiers.
    /// @dev This is the 'live' state of the token's attributes.
    /// @param tokenId The ID of the token.
    /// @return Effective strength, speed, endurance.
    function calculateCurrentAttributes(uint256 tokenId) public view returns (uint256 strength, uint256 speed, uint256 endurance) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        TokenAttributes memory token = _tokenAttributes[tokenId];
        AttributeModifiers memory totalModifiers = getAppliedAttributeModifiers();

        // Apply decay (calculate decay based on current time)
        uint64 timeSinceLastInteraction = uint64(block.timestamp) - token.lastInteractionTimestamp;
         if (timeSinceLastInteraction >= 30 days && token.level > 1) { // Example decay logic
             uint256 decayFactor = timeSinceLastInteraction / (30 days);
             uint256 levelMultiplier = token.level;
             uint256 decayAmountStrength = token.strength > 0 ? (token.strength * decayFactor * levelMultiplier / 100).max(1) : 0;
             uint256 decayAmountSpeed = token.speed > 0 ? (token.speed * decayFactor * levelMultiplier / 100).max(1) : 0;
             uint256 decayAmountEndurance = token.endurance > 0 ? (token.endurance * decayFactor * levelMultiplier / 100).max(1) : 0;

             strength = token.strength > decayAmountStrength ? token.strength - decayAmountStrength : 10; // Minimum floor
             speed = token.speed > decayAmountSpeed ? token.speed - decayAmountSpeed : 10; // Minimum floor
             endurance = token.endurance > decayAmountEndurance ? token.endurance - decayAmountEndurance : 10; // Minimum floor
         } else {
             strength = token.strength;
             speed = token.speed;
             endurance = token.endurance;
         }

        // Apply modifiers
        strength = uint256(int256(strength) + totalModifiers.strengthModifier);
        speed = uint256(int256(speed) + totalModifiers.speedModifier);
        endurance = uint256(int256(endurance) + totalModifiers.enduranceModifier);

        // Ensure attributes don't exceed effective caps
        strength = strength.min(getAttributeEffectiveCap(AttributeType.Strength));
        speed = speed.min(getAttributeEffectiveCap(AttributeType.Speed));
        endurance = endurance.min(getAttributeEffectiveCap(AttributeType.Endurance));

        // Ensure attributes don't drop below minimum floor after modifiers (e.g., 10)
        strength = strength < 10 ? 10 : strength;
        speed = speed < 10 ? 10 : speed;
        endurance = endurance < 10 ? 10 : endurance;
    }

    /// @notice Calculates the potential attribute decay that would apply to a token if `decayAttributes` were called now.
    /// @dev Useful for off-chain services to display potential decay.
    /// @param tokenId The ID of the token.
    /// @return Potential decay for strength, speed, endurance.
    function calculatePotentialDecay(uint256 tokenId) public view returns (uint256 strengthDecay, uint256 speedDecay, uint256 enduranceDecay) {
         if (!_exists(tokenId)) revert InvalidTokenId();

         TokenAttributes memory token = _tokenAttributes[tokenId];
         uint64 timeSinceLastInteraction = uint64(block.timestamp) - token.lastInteractionTimestamp;

         if (timeSinceLastInteraction < 30 days || token.level <= 1) { // Example: decay starts after 30 days inactivity
             return (0, 0, 0);
         }

         uint256 decayFactor = timeSinceLastInteraction / (30 days);
         uint256 levelMultiplier = token.level > 0 ? token.level : 1;

         strengthDecay = token.strength > 0 ? (token.strength * decayFactor * levelMultiplier / 100).max(1) : 0;
         speedDecay = token.speed > 0 ? (token.speed * decayFactor * levelMultiplier / 100).max(1) : 0;
         enduranceDecay = token.endurance > 0 ? (token.endurance * decayFactor * levelMultiplier / 100).max(1) : 0;

         // Ensure decay doesn't reduce attributes below the floor (e.g. 10)
         strengthDecay = token.strength > (token.strength - strengthDecay).min(10) ? strengthDecay : token.strength - 10;
         speedDecay = token.speed > (token.speed - speedDecay).min(10) ? speedDecay : token.speed - 10;
         enduranceDecay = token.endurance > (token.endurance - enduranceDecay).min(10) ? enduranceDecay : token.endurance - 10;
    }

    /// @notice Sets the base maximum value for a specific attribute type.
    /// @dev Only callable by the contract owner. The effective cap may be higher due to forge level.
    /// @param attributeType The type of attribute to set the cap for.
    /// @param cap The base maximum value.
    function setAttributeBaseCap(AttributeType attributeType, uint256 cap) external onlyOwner {
        _attributeBaseCaps[attributeType] = cap;
    }

    /// @notice Gets the base maximum value for a specific attribute type.
    /// @dev This is the cap before considering the forge level bonus.
    /// @param attributeType The type of attribute.
    /// @return The base cap.
    function getAttributeBaseCap(AttributeType attributeType) public view returns (uint256) {
        return _attributeBaseCaps[attributeType];
    }

    /// @notice Gets the effective maximum value for a specific attribute type, considering the forge level.
    /// @dev Effective cap = Base Cap + (Forge Level * Cap Bonus per Level).
    /// @param attributeType The type of attribute.
    /// @return The effective cap.
    function getAttributeEffectiveCap(AttributeType attributeType) public view returns (uint256) {
        // Example calculation: Base Cap + (Forge Level * 10)
        return _attributeBaseCaps[attributeType] + (_forgeLevel * 10);
    }


    // --- Contract-Level Dynamics Functions ---

    /// @notice Upgrades the forge level.
    /// @dev Only callable by the contract owner. Increases the overall potential/tier of the forge and tokens.
    /// @return The new forge level.
    function upgradeForgeLevel() external onlyOwner returns (uint256) {
        // Add conditions for upgrading, e.g., require burning a special token, reaching a global interaction count etc.
        // For this example, it's owner-controlled.
        uint256 maxForgeLevel = 10; // Example max forge level
        if (_forgeLevel >= maxForgeLevel) {
             revert ForgeAlreadyMaxLevel();
        }
        _forgeLevel++;
        emit ForgeLevelUpgraded(_forgeLevel);
        return _forgeLevel;
    }

    /// @notice Sets attribute modifiers that apply based on the current forge level.
    /// @dev Only callable by the contract owner, typically after a forge level upgrade.
    /// @param modifiers The AttributeModifiers struct for the current forge level.
    function setForgeAttributeModifiers(AttributeModifiers calldata modifiers) external onlyOwner {
        _forgeAttributeModifiers = modifiers;
        emit ForgeAttributeModifiersUpdated(modifiers);
    }

     /// @notice Sets attribute modifiers that apply based on the 'season'.
    /// @dev Only callable by the contract owner or a designated oracle address.
    /// Represents a long-term global state change.
    /// @param modifiers The AttributeModifiers struct for the current season.
    function applySeasonalModifier(AttributeModifiers calldata modifiers) external onlyOwner {
        // In a real system, this might be triggered by an oracle based on real-world time/season
        _seasonalAttributeModifiers = modifiers;
        emit SeasonalModifiersUpdated(modifiers);
    }

    /// @notice Triggers a temporary global event that applies attribute modifiers to all tokens.
    /// @dev Only callable by the contract owner or a designated oracle address. Overrides seasonal modifiers while active.
    /// @param eventType The type of global event.
    /// @param modifiers The AttributeModifiers struct for the event.
    /// @param duration The duration of the event in seconds.
    function triggerGlobalEvent(GlobalEvent eventType, AttributeModifiers calldata modifiers, uint64 duration) external onlyOwner {
         // In a real system, this might be triggered by an oracle
         _currentGlobalEvent = GlobalEventState({
             eventType: eventType,
             modifiers: modifiers,
             endTime: uint64(block.timestamp) + duration,
             isActive: true
         });
         emit GlobalEventTriggered(eventType, _currentGlobalEvent.endTime);
     }

    /// @notice Ends the current global event prematurely.
    /// @dev Only callable by the contract owner or a designated oracle address.
    function endGlobalEvent() external onlyOwner {
        if (!_currentGlobalEvent.isActive) revert GlobalEventNotActive();
        GlobalEvent endedEventType = _currentGlobalEvent.eventType;
        _currentGlobalEvent.isActive = false;
        // Modifiers are reset implicitly when isActive becomes false
        emit GlobalEventEnded(endedEventType);
    }

    /// @notice Gets the current forge level of the forge.
    function getForgeLevel() external view returns (uint256) {
        return _forgeLevel;
    }

    /// @notice Gets the currently active global and seasonal attribute modifiers.
    /// @dev Global event modifiers take precedence over seasonal modifiers if an event is active.
    /// @return The combined AttributeModifiers struct.
    function getAppliedAttributeModifiers() public view returns (AttributeModifiers memory) {
        if (_currentGlobalEvent.isActive && block.timestamp < _currentGlobalEvent.endTime) {
            return _currentGlobalEvent.modifiers;
        }
        return _seasonalAttributeModifiers; // If no active event, apply seasonal
        // Note: Forge modifiers are NOT included here, they are typically baked into base attributes or effective caps
        // If forge added *additional* modifiers, they would be added here.
        // Let's combine them for simplicity in this example.
        AttributeModifiers memory totalModifiers = _seasonalAttributeModifiers;
        totalModifiers.strengthModifier += _forgeAttributeModifiers.strengthModifier;
        totalModifiers.speedModifier += _forgeAttributeModifiers.speedModifier;
        totalModifiers.enduranceModifier += _forgeAttributeModifiers.enduranceModifier;

         if (_currentGlobalEvent.isActive && block.timestamp < _currentGlobalEvent.endTime) {
            totalModifiers.strengthModifier += _currentGlobalEvent.modifiers.strengthModifier;
            totalModifiers.speedModifier += _currentGlobalEvent.modifiers.speedModifier;
            totalModifiers.enduranceModifier += _currentGlobalEvent.modifiers.enduranceModifier;
         }

        return totalModifiers;
    }

    /// @notice Gets the state of the current global event.
    /// @dev Returns event type, end time, and whether it is active.
    /// @return GlobalEventState struct.
    function getGlobalEventState() public view returns (GlobalEventState memory) {
        return _currentGlobalEvent;
    }


    // --- Admin & Utility Functions ---

    /// @notice Pauses contract interactions (minting, interaction, leveling, decay).
    /// @dev Only callable by the contract owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract interactions.
    /// @dev Only callable by the contract owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Withdraws accumulated Ether (from minting fees) to the owner's address.
    /// @dev Only callable by the contract owner.
    function withdrawFunds() external onlyOwner nonReentrancy {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Sets the base URI for token metadata.
    /// @dev This URI should point to a service that can serve dynamic metadata based on the tokenId.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /// @notice Gets the timestamp when a specific token was minted.
    /// @param tokenId The ID of the token.
    /// @return The creation timestamp.
    function getTokenCreationTime(uint256 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenAttributes[tokenId].creationTimestamp;
    }

    /// @notice Sets the minimum time required between interactions for a token.
    /// @dev Only callable by the contract owner. Affects the `interact` function cooldown.
    /// @param cooldown The cooldown duration in seconds.
    function setInteractionCooldown(uint64 cooldown) external onlyOwner {
        _interactionCooldown = cooldown;
        emit InteractionCooldownUpdated(cooldown);
    }

    /// @notice Gets the minimum time required between interactions for a token.
    /// @return The cooldown duration in seconds.
    function getInteractionCooldown() external view returns (uint64) {
        return _interactionCooldown;
    }

    /// @notice Sets the requirements for a token to level up to a specific level.
    /// @dev Only callable by the contract owner.
    /// @param level The level being configured (e.g., level 1 for upgrading to level 2).
    /// @param interactionsRequired The number of interactions needed since the previous level up.
    /// @param minTimeBetweenInteractions The minimum time *between* interactions for them to count towards this level requirement. (Note: this specific requirement logic is simplified in `levelUp` function, a more complex check would be needed for robustness).
    function setLevelUpRequirements(uint256 level, uint256 interactionsRequired, uint64 minTimeBetweenInteractions) external onlyOwner {
        _levelUpRequirementsInteractions[level] = interactionsRequired;
        _levelUpRequirementsMinTimeBetweenInteractions[level] = minTimeBetweenInteractions;
        emit LevelUpRequirementsUpdated(level, interactionsRequired, minTimeBetweenInteractions);
    }

    /// @notice Gets the requirements for a token to level up from the given level.
    /// @param level The level to query requirements for.
    /// @return interactionsRequired, minTimeBetweenInteractions.
    function getLevelUpRequirements(uint256 level) external view returns (uint256 interactionsRequired, uint64 minTimeBetweenInteractions) {
        return (_levelUpRequirementsInteractions[level], _levelUpRequirementsMinTimeBetweenInteractions[level]);
    }

     // --- Overrides ---

    /// @dev See {ERC721URIStorage-tokenURI}.
    /// The overridden function points to a service that fetches dynamic data from the contract.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        string memory base = _baseURI();
        // Append tokenId. The service at base + tokenId will then query the contract
        // using getMutableMetadata(), getAppliedAttributeModifiers(), getForgeLevel(), etc.
        // to generate the dynamic metadata JSON and image.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // The following functions are required for ERC721Enumerable.
    // They are implemented in the imported OpenZeppelin contract.
    // We just need to override them to make the compiler happy.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // Internal function overrides needed for ERC721Enumerable and ERC721URIStorage interaction
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        // Clean up dynamic state when a token is burned
        delete _tokenAttributes[tokenId];
        delete _interactionsCount[tokenId];
        // Note: This is where you'd handle any other token-specific state cleanup
    }
}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic Attributes & State:** The core concept revolves around the `TokenAttributes` struct which is stored *on-chain* per token (`_tokenAttributes` mapping). These are not static properties.
2.  **On-Chain Interaction:** The `interact()` function allows users to perform an action that updates the token's `lastInteractionTimestamp` and an internal counter (`_interactionsCount`). This on-chain interaction directly affects the token's state and potential for evolution.
3.  **Time-Based Decay:** The `decayAttributes()` function introduces a time-based mechanic. Attributes can decrease if the token is inactive for too long. This incentivizes owners to interact with their NFTs and makes the token state truly dynamic over time. Crucially, this can be triggered by *anyone*, not just the owner, providing a potential external incentive mechanism (e.g., a service that sweeps and calls this function).
4.  **State-Based Evolution (Leveling):** The `levelUp()` function allows tokens to evolve by increasing their `level` and base attributes. This evolution is gated by on-chain criteria (`_interactionsCount`) and potentially time requirements (`_levelUpRequirementsMinTimeBetweenInteractions`), making the evolution a consequence of owner activity.
5.  **Contract-Level Dynamics:** The contract itself has state that influences all tokens: `_forgeLevel`, `_seasonalAttributeModifiers`, and `_currentGlobalEvent`.
6.  **Forge Level System:** `upgradeForgeLevel()` and `setForgeAttributeModifiers()` introduce a system where the overall "forge" (the contract) can level up, increasing potential attribute caps (`getAttributeEffectiveCap`) and potentially adding global modifiers for newly minted or existing tokens.
7.  **Global Events & Seasonal Changes:** `applySeasonalModifier()`, `triggerGlobalEvent()`, and `endGlobalEvent()` allow for system-wide attribute modifiers to be applied, representing game seasons or special events. These modifiers (`getAppliedAttributeModifiers()`) affect the *effective* attributes of *all* tokens dynamically. Global events can have a duration.
8.  **Dynamic Metadata (`tokenURI` override):** The `tokenURI` is overridden to point to a base URI plus the token ID. The *key* here is the expectation that the service hosting the metadata at that URI will *call back to the contract* using view functions like `getMutableMetadata()`, `calculateCurrentAttributes()`, `getAppliedAttributeModifiers()`, `getForgeLevel()`, and `getGlobalEventState()` to build the metadata JSON *dynamically* based on the token's current on-chain state. This is crucial for DNFTs where the image/description needs to reflect changing attributes, level, decay status, or active events.
9.  **Calculated Attributes:** `calculateCurrentAttributes()` is a view function that computes the *effective* attributes by combining the base stored attributes, current decay (calculated on the fly), and all active global/seasonal modifiers. This is the "true" value of an attribute at any given moment.
10. **Calculated Decay Preview:** `calculatePotentialDecay()` provides a separate view function to show users/services how much decay *would* be applied, without performing the state change.
11. **Modular Level Up Requirements:** `setLevelUpRequirements()` allows the owner to configure the criteria needed to reach each specific level, adding flexibility to the progression system.
12. **Custom Errors:** Using `error` instead of `require(..., "string")` is a gas-efficient practice in modern Solidity.
13. **Pausable & ReentrancyGuard:** Standard but important security patterns. Pausable allows stopping critical functions in emergencies. ReentrancyGuard prevents a specific type of attack.
14. **Ownable & Placeholder Roles:** Uses Ownable for basic admin, but the structure implies roles (`_oracleAddress`, `_randomnessSource`) could be further developed for more granular permissions or integration with external systems.
15. **SafeMath:** Although less critical in Solidity 0.8+ due to default overflow checks, explicit use of SafeMath functions like `mul` can still improve code clarity and express intent, especially in calculations involving potential edge cases.

This contract provides a foundation for a game or application where NFTs are living entities that change and evolve based on player interaction and world state.