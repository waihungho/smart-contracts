Okay, let's create a smart contract for a "Dynamic Parameterized NFT" (dNFT). This contract will represent digital assets (NFTs) that have on-chain attributes that can change over time or based on interactions. It will combine concepts like dynamic metadata, time-based state changes, attribute management, and basic game-like mechanics, while allowing admin configuration.

We will inherit from OpenZeppelin's ERC721 for standard compliance, but the core logic for attribute management and dynamics will be custom.

**Core Concepts:**

1.  **Dynamic Attributes:** Each NFT instance has properties (like Level, Energy, Experience, Growth Stage, Element) stored directly in the contract.
2.  **Time-Based Dynamics:** Some attributes (like Energy) might regenerate over time since the last interaction. Age/Growth Stage can also be derived from creation time.
3.  **Interaction-Based Dynamics:** Users can interact with their NFTs (e.g., Feed, Train) which consume/gain attributes.
4.  **Conditional State Changes:** Leveling up requires meeting experience thresholds; changing element might have costs or requirements. Growth stages change based on age.
5.  **On-Chain State for Metadata:** The `tokenURI` function will reference the *current* on-chain state of the attributes to suggest how metadata should be generated (typically by an off-chain service reading these on-chain values).
6.  **Admin Configurability:** Key parameters (like energy regen rates, experience needed for levels, growth stage durations) can be set by the contract owner.

---

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import OpenZeppelin libraries.
2.  **Interfaces:** Define necessary interfaces (ERC721, ERC721Metadata).
3.  **Errors:** Custom error definitions for clarity and gas efficiency.
4.  **Enums:** Define enums for fixed states (e.g., Element, GrowthStage).
5.  **Structs:** Define the `TokenAttributes` struct to hold dynamic data for each NFT.
6.  **State Variables:**
    *   ERC721 standard mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
    *   Total supply.
    *   Base URI for metadata.
    *   Mapping for token attributes (`_tokenAttributes`).
    *   Admin configurable parameters (energy regen rate, exp needed per level, growth stage durations, costs).
    *   Owner address (via `Ownable`).
7.  **Events:** Standard ERC721 events + custom events for state changes.
8.  **Modifiers:** Standard `onlyOwner`.
9.  **Constructor:** Initialize the contract owner and potentially a base URI.
10. **ERC721 Standard Functions:** Implement or override standard ERC721 functions (`name`, `symbol`, `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`).
11. **Core Dynamic Logic Functions:**
    *   `mint`: Create a new NFT with initial attributes.
    *   `burn`: Destroy an NFT.
    *   `feed`: User action to potentially restore energy/gain exp.
    *   `train`: User action to gain exp, potentially consuming energy.
    *   `levelUp`: Advance the NFT's level if conditions are met.
    *   `changeElement`: Change the NFT's element if conditions are met.
    *   `rest`: User action to trigger energy regeneration calculation.
    *   `commitGrowthStage`: User or admin action to update the persistent growth stage based on age.
12. **View/Pure Functions (Reading State & Calculations):**
    *   `getPlayerState`: Get all attributes for a token.
    *   `getLevel`, `getExperience`, `getEnergy`, `getElement`, `getGrowthStage`: Get specific attributes.
    *   `getCreationTime`, `getLastActionTime`: Get time values.
    *   `calculateAgeInSeconds`: Calculate age based on current time and creation time.
    *   `calculateGrowthStage`: Determine the growth stage based on age.
    *   `calculateEffectiveEnergy`: Calculate current energy including regeneration since last check.
    *   `getElementWeakness`: Pure function to determine element interaction (example).
13. **Admin Functions:**
    *   `setBaseURI`: Update the metadata base URI.
    *   `setEnergyRegenRate`: Set the energy regeneration rate.
    *   `setExperienceNeededForLevel`: Set exp thresholds for levels.
    *   `setGrowthStageDurations`: Set the time needed for each growth stage.
    *   `setFeedingParameters`: Set how feeding affects stats.
    *   `setTrainingParameters`: Set how training affects stats.
    *   `setElementChangeFee`: Set the cost (e.g., in ETH, requires payable) for changing element.
    *   `withdrawETH`: Withdraw collected ETH (if any).
    *   `setAttributeOverride`: Admin override for specific attributes (for maintenance/fixes - advanced concept).
14. **Internal/Helper Functions:**
    *   `_updateLastActionTime`: Helper to update the timestamp on attribute-changing actions.
    *   `_getAttribute`: Internal helper to retrieve attributes securely.
    *   `_setAttribute`: Internal helper to set attributes.
    *   `_updateAttributes`: Internal helper to apply attribute changes atomically.

---

**Function Summary:**

1.  `constructor(string memory name_, string memory symbol_, string memory baseURI_)`: Initializes the contract, ERC721 parameters, and sets the initial base URI.
2.  `mint(address to, uint256 tokenId, uint256 initialElement)`: Creates a new NFT with a specific ID, assigns it to `to`, and sets initial dynamic attributes (Level 1, 0 Exp, full Energy, Child stage, specified Element, current time as creation/last action). Requires `tokenId` to not exist.
3.  `burn(uint256 tokenId)`: Destroys an NFT by its owner or approved operator. Removes attributes.
4.  `feed(uint256 tokenId)`: Allows the owner/approved to "feed" the NFT. Increases Energy and potentially Experience. Updates last action time. May have requirements (e.g., not already full energy).
5.  `train(uint256 tokenId)`: Allows the owner/approved to "train" the NFT. Increases Experience, consumes Energy. Updates last action time. Requires sufficient energy.
6.  `levelUp(uint256 tokenId)`: Allows the owner/approved to level up the NFT if its Experience meets the requirement for the next level. Resets Experience, increases Level, potentially boosts stats.
7.  `changeElement(uint256 tokenId, uint256 newElement)`: Allows the owner/approved to change the NFT's element. May require payment (making the function `payable`) or meeting certain conditions (e.g., level). Consumes fee/resource.
8.  `rest(uint256 tokenId)`: Triggers an update to energy and last action time, calculating regeneration since the last interaction. No direct cost, just commits current state.
9.  `commitGrowthStage(uint256 tokenId)`: Updates the on-chain `growthStage` attribute based on the current age calculation.
10. `getPlayerState(uint256 tokenId)`: View function. Returns the full `TokenAttributes` struct for a given token ID.
11. `getLevel(uint256 tokenId)`: View function. Returns the current level.
12. `getExperience(uint256 tokenId)`: View function. Returns the current experience.
13. `getEnergy(uint256 tokenId)`: View function. Returns the *persisted* energy value (not calculated regen).
14. `getElement(uint256 tokenId)`: View function. Returns the current element.
15. `getGrowthStage(uint256 tokenId)`: View function. Returns the *persisted* growth stage.
16. `getCreationTime(uint256 tokenId)`: View function. Returns the NFT's creation timestamp.
17. `getLastActionTime(uint256 tokenId)`: View function. Returns the timestamp of the last action that consumed/regenerated time-based stats.
18. `calculateAgeInSeconds(uint256 tokenId)`: View function. Calculates the NFT's current age in seconds based on `creationTime` and `block.timestamp`.
19. `calculateGrowthStage(uint256 tokenId)`: View function. Calculates and returns the current `GrowthStage` based on `calculateAgeInSeconds`.
20. `calculateEffectiveEnergy(uint256 tokenId)`: View function. Calculates and returns the current energy value including regeneration based on `energyRegenRate`, `lastActionTime`, and `block.timestamp`.
21. `getElementWeakness(uint256 element)`: Pure function. Example logic to determine which element `element` is weak against. Useful for potential off-chain game logic referencing the contract.
22. `setBaseURI(string memory baseURI_)`: Admin function. Sets the base part of the URI returned by `tokenURI`.
23. `setEnergyRegenRate(uint256 ratePerSecond)`: Admin function. Sets the energy regeneration rate per second.
24. `setExperienceNeededForLevel(uint256 level, uint256 requiredExp)`: Admin function. Sets the experience required to reach a specific level.
25. `setGrowthStageDurations(uint256 stage, uint256 durationInSeconds)`: Admin function. Sets the duration for a specific growth stage (e.g., how long stage 0 lasts before moving to stage 1).
26. `setFeedingParameters(uint256 energyGain, uint256 expGain)`: Admin function. Configures the benefits of the `feed` action.
27. `setTrainingParameters(uint256 energyCost, uint256 expGain)`: Admin function. Configures the cost and benefit of the `train` action.
28. `setElementChangeFee(uint256 fee)`: Admin function. Sets the fee required for the `changeElement` action (assuming fee is in ETH).
29. `withdrawETH(address payable _to, uint256 _amount)`: Admin function. Allows the owner to withdraw ETH collected (e.g., from element change fees) to a specified address.
30. `setAttributeOverride(uint256 tokenId, uint256 newLevel, uint256 newExp, uint256 newEnergy, uint256 newElement, uint256 newGrowthStage, uint256 newLastActionTime)`: Admin function. Allows the owner to directly set all dynamic attributes for a token (useful for fixes or special cases).

*(Note: We've listed 30 functions, ensuring we meet the minimum 20 requirement comfortably, including standard ERC721 functions and custom dynamic ones.)*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. Pragma and Imports
// 2. Errors
// 3. Enums
// 4. Structs
// 5. State Variables
// 6. Events
// 7. Constructor
// 8. ERC721 Standard Functions
// 9. Core Dynamic Logic Functions
// 10. View/Pure Functions (Reading State & Calculations)
// 11. Admin Functions
// 12. Internal/Helper Functions

// Function Summary:
// constructor(string memory name_, string memory symbol_, string memory baseURI_): Initializes contract, ERC721, owner, and base URI.
// mint(address to, uint256 tokenId, uint256 initialElement): Mints a new dNFT with initial attributes.
// burn(uint256 tokenId): Burns an existing dNFT.
// feed(uint256 tokenId): Increases NFT's energy and experience.
// train(uint256 tokenId): Increases NFT's experience, consumes energy.
// levelUp(uint256 tokenId): Levels up NFT if experience requirement met.
// changeElement(uint256 tokenId, uint256 newElement): Changes NFT's elemental type, potentially costs ETH.
// rest(uint256 tokenId): Updates energy based on regeneration time.
// commitGrowthStage(uint256 tokenId): Updates persisted growth stage based on age.
// getPlayerState(uint256 tokenId): View. Returns all dynamic attributes.
// getLevel(uint256 tokenId): View. Returns level.
// getExperience(uint256 tokenId): View. Returns experience.
// getEnergy(uint256 tokenId): View. Returns base energy (before regeneration calc).
// getElement(uint256 tokenId): View. Returns element.
// getGrowthStage(uint256 tokenId): View. Returns persisted growth stage.
// getCreationTime(uint256 tokenId): View. Returns creation timestamp.
// getLastActionTime(uint256 tokenId): View. Returns last action timestamp.
// calculateAgeInSeconds(uint256 tokenId): View. Calculates current age in seconds.
// calculateGrowthStage(uint256 tokenId): View. Calculates current growth stage based on age.
// calculateEffectiveEnergy(uint256 tokenId): View. Calculates energy including regeneration.
// getElementWeakness(uint256 element): Pure. Returns element 'element' is weak against.
// setBaseURI(string memory baseURI_): Admin. Sets the base token URI.
// setEnergyRegenRate(uint256 ratePerSecond): Admin. Sets energy regen rate.
// setExperienceNeededForLevel(uint256 level, uint256 requiredExp): Admin. Sets XP needed for a level.
// setGrowthStageDurations(uint256 stage, uint256 durationInSeconds): Admin. Sets duration for growth stages.
// setFeedingParameters(uint256 energyGain, uint256 expGain): Admin. Sets feed effects.
// setTrainingParameters(uint256 energyCost, uint256 expGain): Admin. Sets train effects.
// setElementChangeFee(uint256 fee): Admin. Sets element change ETH fee.
// withdrawETH(address payable _to, uint256 _amount): Admin. Withdraws contract ETH.
// setAttributeOverride(uint256 tokenId, uint256 newLevel, uint256 newExp, uint256 newEnergy, uint256 newElement, uint256 newGrowthStage, uint256 newLastActionTime): Admin. Directly sets all attributes.
// Plus standard ERC721 functions: name, symbol, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(bytes). (Total >= 30)


contract DynamicNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // 2. Errors
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwnerOrApproved(uint256 tokenId);
    error InvalidElement(uint256 element);
    error InsufficientEnergy(uint256 currentEnergy, uint256 requiredEnergy);
    error NotEnoughExperience(uint256 currentExp, uint256 requiredExp);
    error MaxLevelReached(uint256 currentLevel);
    error InvalidGrowthStage(uint256 stage);
    error CannotChangeToSameElement(uint256 currentElement, uint256 newElement);
    error InsufficientPayment(uint256 sent, uint256 required);
    error WithdrawFailed();

    // 3. Enums
    enum GrowthStage {
        Child,
        Teenager,
        Adult,
        Elder
    }

    enum Element {
        None, // Default or Unassigned
        Fire,
        Water,
        Earth,
        Air,
        Count // Sentinel for number of elements
    }

    // 4. Structs
    struct TokenAttributes {
        uint256 level;
        uint256 experience;
        uint256 energy; // Current energy points
        uint256 creationTime; // Timestamp of creation
        uint256 lastActionTime; // Timestamp of last action affecting time-based stats
        uint8 growthStage; // Corresponds to GrowthStage enum
        uint8 element; // Corresponds to Element enum
    }

    // 5. State Variables
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => TokenAttributes) private _tokenAttributes;

    string private _baseTokenURI;

    // Admin configurable parameters
    uint256 public energyRegenRate = 1; // Energy points regenerated per second
    mapping(uint256 => uint256) public experienceNeededForLevel; // level => requiredExp
    mapping(uint256 => uint256) public growthStageDurations; // stage (uint8) => duration in seconds
    uint256 public feedingEnergyGain = 10;
    uint256 public feedingExpGain = 5;
    uint256 public trainingEnergyCost = 5;
    uint256 public trainingExpGain = 15;
    uint256 public elementChangeFee = 0; // Fee in wei

    uint256 private constant MAX_ENERGY = 100;
    uint256 private constant MAX_LEVEL = 100;

    // 6. Events
    event AttributesUpdated(uint256 indexed tokenId, TokenAttributes newAttributes);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel);
    event EnergyChanged(uint256 indexed tokenId, uint256 oldEnergy, uint256 newEnergy);
    event ExperienceChanged(uint256 indexed tokenId, uint256 oldExp, uint256 newExp);
    event ElementChanged(uint256 indexed tokenId, uint256 oldElement, uint256 newElement);
    event GrowthStageChanged(uint256 indexed tokenId, GrowthStage oldStage, GrowthStage newStage);
    event BaseURIUpdated(string newBaseURI);
    event ParametersUpdated(); // Generic event for admin parameter changes

    // 7. Constructor
    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI_;

        // Set initial default parameter values
        experienceNeededForLevel[1] = 10;
        experienceNeededForLevel[2] = 30;
        experienceNeededForLevel[3] = 60;
        experienceNeededForLevel[4] = 100;
        experienceNeededForLevel[5] = 150;
        // ... add more levels or use a formula

        growthStageDurations[uint8(GrowthStage.Child)] = 7 days; // Example: Child for 7 days
        growthStageDurations[uint8(GrowthStage.Teenager)] = 30 days; // Teenager for 30 days
        growthStageDurations[uint8(GrowthStage.Adult)] = 365 days; // Adult for 365 days (then Elder)
        growthStageDurations[uint8(GrowthStage.Elder)] = type(uint256).max; // Elder forever
    }

    // 8. ERC721 Standard Functions

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is valid

        // Note: This implementation provides a base URI + token ID.
        // A sophisticated dynamic metadata system would involve an off-chain service
        // reading the state returned by getPlayerState() and generating JSON metadata dynamically
        // based on the *current* attributes (level, energy, stage, etc.).
        // The service would be hosted at the baseURI.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // ERC721 required overrides
    // These are often handled internally by OpenZeppelin's ERC721
    // For clarity, listing them as implemented by inheriting ERC721
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { ... }
    // function balanceOf(address owner) public view virtual override returns (uint256) { ... }
    // function ownerOf(uint256 tokenId) public view virtual override returns (address) { ... }
    // function approve(address to, uint256 tokenId) public virtual override { ... }
    // function getApproved(uint256 tokenId) public view virtual override returns (address) { ... }
    // function setApprovalForAll(address operator, bool approved) public virtual override { ... }
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) { ... }
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override { ... }
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override { ... }
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public virtual override { ... }


    // 9. Core Dynamic Logic Functions

    function mint(address to, uint256 tokenId, uint256 initialElement) public onlyOwner {
        if (initialElement >= uint256(Element.Count) || initialElement == uint256(Element.None)) {
            revert InvalidElement(initialElement);
        }

        // Use a specific tokenId instead of counter for flexibility, ensuring it's not minted
        _safeMint(to, tokenId); // Will revert if tokenId already exists

        uint256 currentTime = block.timestamp;

        _tokenAttributes[tokenId] = TokenAttributes({
            level: 1,
            experience: 0,
            energy: MAX_ENERGY, // Start with full energy
            creationTime: currentTime,
            lastActionTime: currentTime,
            growthStage: uint8(GrowthStage.Child),
            element: uint8(initialElement)
        });

        emit AttributesUpdated(tokenId, _tokenAttributes[tokenId]);
    }

    function burn(uint256 tokenId) public virtual {
        // Check existence and access control (owner or approved)
        address owner = ownerOf(tokenId); // Reverts if token doesn't exist
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        // Use OpenZeppelin's _burn which handles checks and ERC721 state
        _burn(tokenId);

        // Remove attributes after burning
        delete _tokenAttributes[tokenId];

        // No specific event for attribute deletion, but AttributesUpdated could signal all-zero state if needed
        // or just rely on the Burn event from ERC721
    }


    function feed(uint256 tokenId) public {
        _requireOwned(tokenId); // Checks existence and ownership
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        TokenAttributes storage attributes = _getAttribute(tokenId);

        uint256 currentEnergy = calculateEffectiveEnergy(tokenId);
        uint256 oldEnergy = attributes.energy; // Base energy before regen calc
        uint256 oldExp = attributes.experience;

        // Apply regeneration first to get the latest base energy state
        _applyEnergyRegen(tokenId, attributes);

        // Add energy up to max
        attributes.energy = Math.min(attributes.energy + feedingEnergyGain, MAX_ENERGY);
        attributes.experience += feedingExpGain;

        // Update last action time after applying changes
        attributes.lastActionTime = block.timestamp;

        emit AttributesUpdated(tokenId, attributes);
        if (attributes.energy != oldEnergy) {
             // Note: This event uses the base energy value, consider emitting effective energy change if needed
             emit EnergyChanged(tokenId, oldEnergy, attributes.energy);
        }
        if (attributes.experience != oldExp) {
             emit ExperienceChanged(tokenId, oldExp, attributes.experience);
        }
    }

    function train(uint256 tokenId) public {
        _requireOwned(tokenId);
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        TokenAttributes storage attributes = _getAttribute(tokenId);

        uint256 currentEnergy = calculateEffectiveEnergy(tokenId);
        if (currentEnergy < trainingEnergyCost) {
            revert InsufficientEnergy(currentEnergy, trainingEnergyCost);
        }

        uint256 oldEnergy = attributes.energy;
        uint256 oldExp = attributes.experience;

        // Apply regeneration *before* spending energy
        _applyEnergyRegen(tokenId, attributes);

        // Spend energy
        attributes.energy = attributes.energy - trainingEnergyCost;
        attributes.experience += trainingExpGain;

        // Update last action time
        attributes.lastActionTime = block.timestamp;

        emit AttributesUpdated(tokenId, attributes);
        if (attributes.energy != oldEnergy) {
             emit EnergyChanged(tokenId, oldEnergy, attributes.energy);
        }
         if (attributes.experience != oldExp) {
             emit ExperienceChanged(tokenId, oldExp, attributes.experience);
        }
    }

    function levelUp(uint256 tokenId) public {
        _requireOwned(tokenId);
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        TokenAttributes storage attributes = _getAttribute(tokenId);

        if (attributes.level >= MAX_LEVEL) {
            revert MaxLevelReached(attributes.level);
        }

        uint256 requiredExp = experienceNeededForLevel[attributes.level];
        if (attributes.experience < requiredExp) {
            revert NotEnoughExperience(attributes.experience, requiredExp);
        }

        // Level up!
        uint256 oldLevel = attributes.level;
        uint256 oldExp = attributes.experience; // Will be reset
        attributes.level += 1;
        attributes.experience = attributes.experience - requiredExp; // Carry over remaining exp, or set to 0

        // Optional: Boost stats or grant skills here based on level
        // attributes.some_stat += level_boost;

        emit AttributesUpdated(tokenId, attributes);
        emit LevelUp(tokenId, attributes.level);
         if (attributes.experience != oldExp) {
             emit ExperienceChanged(tokenId, oldExp, attributes.experience);
        }
    }

    function changeElement(uint256 tokenId, uint256 newElement) public payable {
         _requireOwned(tokenId);
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        if (newElement >= uint256(Element.Count) || newElement == uint256(Element.None)) {
            revert InvalidElement(newElement);
        }

        TokenAttributes storage attributes = _getAttribute(tokenId);

        if (attributes.element == newElement) {
             revert CannotChangeToSameElement(attributes.element, newElement);
        }

        if (msg.value < elementChangeFee) {
            revert InsufficientPayment(msg.value, elementChangeFee);
        }

        uint8 oldElement = attributes.element;
        attributes.element = uint8(newElement);

        // Update last action time as this is a significant interaction
        attributes.lastActionTime = block.timestamp;


        emit AttributesUpdated(tokenId, attributes);
        emit ElementChanged(tokenId, oldElement, attributes.element);

        // Any excess payment is kept by the contract, withdrawable by owner
    }

    function rest(uint256 tokenId) public {
        _requireOwned(tokenId);
        if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
             revert NotTokenOwnerOrApproved(tokenId);
        }

        TokenAttributes storage attributes = _getAttribute(tokenId);
        uint256 oldEnergy = attributes.energy;

        // Apply regeneration to commit the current energy state
        _applyEnergyRegen(tokenId, attributes);

        // Update last action time
        attributes.lastActionTime = block.timestamp;

        emit AttributesUpdated(tokenId, attributes);
         if (attributes.energy != oldEnergy) {
             emit EnergyChanged(tokenId, oldEnergy, attributes.energy);
        }
    }

    function commitGrowthStage(uint256 tokenId) public {
         _requireOwned(tokenId);
        // Anyone can call this to update the stage, even if they aren't owner/approved,
        // as it's just updating state based on time. Let's allow anyone.
        // if (_isApprovedOrOwner(msg.sender, tokenId) == false) {
        //      revert NotTokenOwnerOrApproved(tokenId);
        // }

        TokenAttributes storage attributes = _getAttribute(tokenId);
        uint8 oldStage = attributes.growthStage;
        uint8 calculatedStage = calculateGrowthStage(tokenId);

        if (oldStage != calculatedStage) {
            attributes.growthStage = calculatedStage;
            emit AttributesUpdated(tokenId, attributes);
            emit GrowthStageChanged(tokenId, GrowthStage(oldStage), GrowthStage(calculatedStage));
        }
        // If stage hasn't changed, do nothing (saves gas)
    }

    // 10. View/Pure Functions

    function getPlayerState(uint256 tokenId) public view returns (TokenAttributes memory) {
        _requireOwned(tokenId); // Check if token exists
        return _tokenAttributes[tokenId];
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
        return getPlayerState(tokenId).level;
    }

    function getExperience(uint256 tokenId) public view returns (uint256) {
        return getPlayerState(tokenId).experience;
    }

    function getEnergy(uint256 tokenId) public view returns (uint256) {
        return getPlayerState(tokenId).energy; // Returns stored value, not effective
    }

    function getElement(uint256 tokenId) public view returns (Element) {
        return Element(getPlayerState(tokenId).element);
    }

    function getGrowthStage(uint256 tokenId) public view returns (GrowthStage) {
        return GrowthStage(getPlayerState(tokenId).growthStage); // Returns stored value
    }

     function getCreationTime(uint256 tokenId) public view returns (uint256) {
        return getPlayerState(tokenId).creationTime;
    }

    function getLastActionTime(uint256 tokenId) public view returns (uint256) {
        return getPlayerState(tokenId).lastActionTime;
    }

    function calculateAgeInSeconds(uint256 tokenId) public view returns (uint256) {
        TokenAttributes memory attributes = getPlayerState(tokenId);
        // Avoid issues if creationTime is somehow in the future (though unlikely with block.timestamp)
        if (block.timestamp < attributes.creationTime) {
            return 0;
        }
        return block.timestamp - attributes.creationTime;
    }

    function calculateGrowthStage(uint256 tokenId) public view returns (uint8) {
        uint256 age = calculateAgeInSeconds(tokenId);

        uint256 cumulativeDuration = 0;
        for (uint8 i = 0; i < uint8(GrowthStage.Count); i++) {
            uint256 stageDuration = growthStageDurations[i];
            if (stageDuration == 0 && i < uint8(GrowthStage.Count) - 1) {
                 // Handle stages with 0 duration (shouldn't happen if configured correctly, assume it means instant transition)
                 continue;
            }
            if (age < cumulativeDuration + stageDuration || stageDuration == type(uint256).max) {
                 // Found the stage, or reached the final infinite stage
                 return i;
            }
             // Prevent overflow if stageDuration is max(uint256)
             if (cumulativeDuration + stageDuration < cumulativeDuration) {
                  cumulativeDuration = type(uint256).max; // Cap at max
             } else {
                  cumulativeDuration += stageDuration;
             }
        }
        // Should not reach here if GrowthStage.Count and durations are set correctly,
        // default to the last stage if loop finishes (e.g., Elder)
        return uint8(GrowthStage.Count) - 1;
    }


    function calculateEffectiveEnergy(uint256 tokenId) public view returns (uint256) {
         TokenAttributes memory attributes = getPlayerState(tokenId);
         uint256 timePassed = block.timestamp - attributes.lastActionTime;
         uint256 regenerated = timePassed * energyRegenRate;
         return Math.min(attributes.energy + regenerated, MAX_ENERGY);
    }

    // Example of a pure function for game logic reference
    function getElementWeakness(uint256 element) public pure returns (Element) {
        if (element == uint8(Element.Fire)) return Element.Water;
        if (element == uint8(Element.Water)) return Element.Earth;
        if (element == uint8(Element.Earth)) return Element.Air;
        if (element == uint8(Element.Air)) return Element.Fire;
        return Element.None; // Or a specific 'WeakAgainstNone' element
    }


    // 11. Admin Functions

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    function setEnergyRegenRate(uint256 ratePerSecond) public onlyOwner {
        energyRegenRate = ratePerSecond;
        emit ParametersUpdated();
    }

    function setExperienceNeededForLevel(uint256 level, uint256 requiredExp) public onlyOwner {
        // Prevent setting requirement for level 0 or 1 (level 1 is base)
        if (level == 0) revert("Level must be greater than 0"); // Or specific error
        experienceNeededForLevel[level] = requiredExp;
        emit ParametersUpdated();
    }

    function setGrowthStageDurations(uint256 stage, uint256 durationInSeconds) public onlyOwner {
        if (stage >= uint8(GrowthStage.Count)) {
             revert InvalidGrowthStage(stage);
        }
        growthStageDurations[uint8(stage)] = durationInSeconds;
         emit ParametersUpdated();
    }

    function setFeedingParameters(uint256 energyGain, uint256 expGain) public onlyOwner {
        feedingEnergyGain = energyGain;
        feedingExpGain = expGain;
        emit ParametersUpdated();
    }

    function setTrainingParameters(uint256 energyCost, uint256 expGain) public onlyOwner {
        trainingEnergyCost = energyCost;
        trainingExpGain = expGain;
        emit ParametersUpdated();
    }

    function setElementChangeFee(uint256 fee) public onlyOwner {
        elementChangeFee = fee;
        emit ParametersUpdated();
    }

    function withdrawETH(address payable _to, uint256 _amount) public onlyOwner {
        if (_amount == 0 || address(this).balance < _amount) {
             revert("Insufficient contract balance or amount is zero"); // Or specific error
        }
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function setAttributeOverride(
        uint256 tokenId,
        uint256 newLevel,
        uint256 newExp,
        uint256 newEnergy,
        uint256 newElement,
        uint256 newGrowthStage,
        uint256 newLastActionTime // Allow overriding time for specific scenarios
    ) public onlyOwner {
         _requireOwned(tokenId); // Ensure token exists

         if (newElement >= uint256(Element.Count)) revert InvalidElement(newElement);
         if (newGrowthStage >= uint8(GrowthStage.Count)) revert InvalidGrowthStage(newGrowthStage);
         if (newEnergy > MAX_ENERGY) newEnergy = MAX_ENERGY; // Clamp energy

         TokenAttributes storage attributes = _getAttribute(tokenId);

         attributes.level = newLevel;
         attributes.experience = newExp;
         attributes.energy = newEnergy;
         attributes.element = uint8(newElement);
         attributes.growthStage = uint8(newGrowthStage);
         attributes.lastActionTime = newLastActionTime;
         // Note: creationTime is immutable once minted

         emit AttributesUpdated(tokenId, attributes);
         // Specific events (LevelUp, EnergyChanged, etc.) could be emitted here too,
         // but AttributesUpdated signals a direct admin change.
    }


    // 12. Internal/Helper Functions

    // Internal function to retrieve mutable attributes
    function _getAttribute(uint256 tokenId) internal view returns (TokenAttributes storage) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        return _tokenAttributes[tokenId];
    }

    // Applies pending energy regeneration
    function _applyEnergyRegen(uint256 tokenId, TokenAttributes storage attributes) internal {
         uint256 oldEnergy = attributes.energy;
         uint256 timePassed = block.timestamp - attributes.lastActionTime;
         uint256 regenerated = timePassed * energyRegenRate;
         attributes.energy = Math.min(attributes.energy + regenerated, MAX_ENERGY);

         if (attributes.energy != oldEnergy) {
              emit EnergyChanged(tokenId, oldEnergy, attributes.energy);
         }
    }


    // Override required by ERC721 for _beforeTokenTransfer
    function _update(address to, uint256 tokenId, address auth) internal virtual override {
        if (_exists(tokenId)) {
            // Apply any pending regeneration/time-based updates before transfer
            TokenAttributes storage attributes = _getAttribute(tokenId);
             // Note: This might be gas-intensive on transfer. Consider if this is necessary or if the state is
             // only updated on explicit user actions (feed, train, rest, commitGrowthStage).
             // For this example, let's keep it simple and assume state is updated via user actions.
             // If regeneration *must* be applied on transfer, uncomment and implement _applyEnergyRegen logic here.
             // _applyEnergyRegen(tokenId, attributes);
             attributes.lastActionTime = block.timestamp; // Update time on transfer/approval
        }
         super._update(to, tokenId, auth);
    }


    // Required ERC721 hook for burning
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Optional: Logic before transfer (e.g., if staked, unstake)
        // This design doesn't include staking, but this is where you'd add such checks.
    }

     // Required ERC721 hook for minting/burning
     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        // Optional: Logic after transfer (e.g., if minting, initialize more state)
        // Minting initialization is done in the public mint function for more control over parameters.
    }

    // Fallback function to receive ETH, needed for payable functions like changeElement
    receive() external payable {}

    // Include OpenZeppelin's Math library for min function
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```