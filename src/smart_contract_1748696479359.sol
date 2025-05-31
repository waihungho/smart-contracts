Okay, here is a Solidity smart contract incorporating several advanced and creative concepts beyond typical ERC721 standards. It represents a system for dynamic, evolving "ChronoPets" with gamified interactions, on-chain state, delegation, and faction mechanics.

It aims for novelty by combining:
1.  **Dynamic State:** Pet stats (hunger, mood, level, etc.) change over time and with interactions.
2.  **On-Chain Evolution/Mutation:** Traits can change or unlock based on conditions.
3.  **Gamified Mechanics:** Feeding, playing, training, sacrificing, breeding, merging.
4.  **Time-Based Decay:** Pet states deteriorate over time if not cared for.
5.  **Delegated Interaction:** Owners can grant temporary rights to others to care for/interact with their pets.
6.  **Faction System:** Pets can join factions with potential future benefits (though the benefits themselves are complex and outlined conceptually).
7.  **Complex Minting Logic:** Breeding and Merging create new tokens based on input token states.

---

**Contract Outline:**

1.  **Imports:** Standard libraries (ERC721, Ownable, ReentrancyGuard).
2.  **Events:** Significant actions logged for transparency and off-chain tracking.
3.  **Enums & Structs:** Define possible states, traits, and data structures for pets, delegations, and factions.
4.  **State Variables:** Mappings and counters to store contract data (pet info, delegations, factions, parameters).
5.  **Modifiers:** Custom access control (e.g., `onlyPetOwner`, `onlyPetOwnerOrDelegatee`).
6.  **Constructor:** Initialize base contract settings.
7.  **ERC721 Standard Overrides:** Implement `tokenURI` to reflect dynamic state.
8.  **Pet Management & Minting:**
    *   `mintPet`
    *   `batchMintPets`
    *   `breedPets`
    *   `mergePets`
    *   `sacrificePetForXP`
9.  **Dynamic State Interaction:**
    *   `feedPet`
    *   `playWithPet`
    *   `trainPet`
    *   `decayPetState` (internal helper)
10. **Evolution & Traits:**
    *   `evolvePet`
    *   `lockTraits`
    *   `unlockTraits`
11. **Delegation:**
    *   `delegatePetOwnership`
    *   `revokeDelegation`
12. **Faction System:**
    *   `registerFaction`
    *   `joinFaction`
    *   `leaveFaction`
    *   `transferFactionOwnership`
13. **View Functions (Getters):** Access various aspects of pet, delegation, and faction state.
    *   `getPetStatus`
    *   `getPetTraits`
    *   `getPetTimestamps`
    *   `getPetAge`
    *   `isEvolutionReady`
    *   `getDelegationInfo`
    *   `getFaction`
    *   `getFactionInfo`
14. **Admin Functions:** Contract owner controls for parameters and rescue.
    *   `setBaseURI`
    *   `setMinBreedLevel`
    *   `setEvolutionCost`
    *   `setTraitLockCost`
    *   `setDecayRate`
    *   `pause`
    *   `unpause`
    *   `withdrawEth`
    *   `getContractBalance`
15. **Internal/Helper Functions:** Logic encapsulated for clarity and reuse.

---

**Function Summary (Beyond Standard ERC721):**

1.  `mintPet(address receiver)`: Mints a new ChronoPet token to the receiver, initializing its state.
2.  `batchMintPets(address[] receivers)`: Mints multiple pets in a single transaction.
3.  `breedPets(uint256 parent1Id, uint256 parent2Id)`: Creates a new ChronoPet (token) from two existing pets, consuming breeding costs and potentially influencing child traits based on parents and state. Requires pets to meet criteria (level, state, not on cooldown). Uses ETH cost.
4.  `mergePets(uint256 pet1Id, uint256 pet2Id)`: Burns two existing ChronoPets to create a single, potentially stronger/higher-level new pet, combining aspects or granting bonuses. Uses ETH cost.
5.  `sacrificePetForXP(uint256 sacrificedPetId, uint256 recipientPetId)`: Burns one pet to grant a significant amount of XP to another pet.
6.  `feedPet(uint256 tokenId)`: Improves the pet's hunger state and updates the last fed timestamp. May gain small XP. Applies time-based decay before improving.
7.  `playWithPet(uint256 tokenId)`: Improves the pet's mood state and updates the last played timestamp. May gain small XP. Applies time-based decay before improving.
8.  `trainPet(uint256 tokenId)`: Grants significant XP to the pet. Can trigger leveling up. Applies time-based decay before training.
9.  `evolvePet(uint256 tokenId)`: Attempts to evolve the pet based on its current level, age, and state. Changes pet traits and potentially type. Requires an ETH cost.
10. `lockTraits(uint256 tokenId)`: Locks the pet's current traits, preventing future evolution or mutation from changing them. Requires an ETH cost.
11. `unlockTraits(uint256 tokenId)`: Unlocks the pet's traits, allowing future changes. Requires an ETH cost.
12. `delegatePetOwnership(uint256 tokenId, address delegatee, uint64 duration)`: Allows the pet owner to grant a delegatee the ability to interact with the pet (feed, play, train, etc.) for a specified duration without transferring ownership.
13. `revokeDelegation(uint256 tokenId)`: Revokes any active delegation for the specified pet.
14. `registerFaction(string memory name)`: Allows the contract owner (or potentially a future DAO) to register a new faction that pets can join.
15. `joinFaction(uint256 tokenId, uint256 factionId)`: Assigns a pet to a registered faction. Requires pet owner/delegatee.
16. `leaveFaction(uint256 tokenId)`: Removes a pet from its current faction. Requires pet owner/delegatee.
17. `transferFactionOwnership(uint256 factionId, address newOwner)`: Transfers ownership/management rights of a faction (callable by current faction owner).
18. `getPetStatus(uint256 tokenId)`: Reads and returns the current dynamic status of a pet (level, xp, hunger, mood).
19. `getPetTraits(uint256 tokenId)`: Reads and returns the current traits of a pet.
20. `getPetAge(uint256 tokenId)`: Calculates and returns the age of the pet in seconds since minting.
21. `isEvolutionReady(uint256 tokenId)`: Checks if a pet meets the minimum criteria for evolution (but doesn't trigger it).
22. `getDelegationInfo(uint256 tokenId)`: Returns the current delegatee and expiry time for a pet, if any.
23. `getFaction(uint256 tokenId)`: Returns the faction ID the pet belongs to, or 0 if none.
24. `getFactionInfo(uint256 factionId)`: Returns the details (name, owner) of a registered faction.
25. `setMinBreedLevel(uint256 level)`: Admin function to set the minimum level required for pets to breed.
26. `setEvolutionCost(uint256 cost)`: Admin function to set the ETH cost for evolving a pet.
27. `setTraitLockCost(uint256 cost)`: Admin function to set the ETH cost for locking/unlocking pet traits.
28. `setDecayRate(uint256 rate)`: Admin function to set the decay rate for hunger and mood (e.g., points lost per hour).

*(Note: The contract includes standard ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `name`, `symbol` which are part of the base implementation, but the creative functions are listed above)*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

// ChronoPets: Dynamic, evolving NFTs with gamified mechanics, delegation, and factions.

// --- Contract Outline ---
// 1. Imports
// 2. Events
// 3. Enums & Structs
// 4. State Variables
// 5. Modifiers
// 6. Constructor
// 7. ERC721 Standard Overrides
// 8. Pet Management & Minting
// 9. Dynamic State Interaction
// 10. Evolution & Traits
// 11. Delegation
// 12. Faction System
// 13. View Functions (Getters)
// 14. Admin Functions
// 15. Internal/Helper Functions

// --- Function Summary (Beyond Standard ERC721) ---
// 1. mintPet(address receiver)
// 2. batchMintPets(address[] receivers)
// 3. breedPets(uint256 parent1Id, uint256 parent2Id)
// 4. mergePets(uint256 pet1Id, uint256 pet2Id)
// 5. sacrificePetForXP(uint256 sacrificedPetId, uint256 recipientPetId)
// 6. feedPet(uint256 tokenId)
// 7. playWithPet(uint256 tokenId)
// 8. trainPet(uint256 tokenId)
// 9. evolvePet(uint256 tokenId)
// 10. lockTraits(uint256 tokenId)
// 11. unlockTraits(uint256 tokenId)
// 12. delegatePetOwnership(uint256 tokenId, address delegatee, uint64 duration)
// 13. revokeDelegation(uint256 tokenId)
// 14. registerFaction(string memory name)
// 15. joinFaction(uint256 tokenId, uint256 factionId)
// 16. leaveFaction(uint256 tokenId)
// 17. transferFactionOwnership(uint256 factionId, address newOwner)
// 18. getPetStatus(uint256 tokenId)
// 19. getPetTraits(uint256 tokenId)
// 20. getPetAge(uint256 tokenId)
// 21. isEvolutionReady(uint256 tokenId)
// 22. getDelegationInfo(uint256 tokenId)
// 23. getFaction(uint256 tokenId)
// 24. getFactionInfo(uint256 factionId)
// 25. setMinBreedLevel(uint256 level) (Admin)
// 26. setEvolutionCost(uint256 cost) (Admin)
// 27. setTraitLockCost(uint256 cost) (Admin)
// 28. setDecayRate(uint256 rate) (Admin)
// (Plus standard ERC721 functions)

contract ChronoPets is ERC721, Ownable, ReentrancyGuard, ERC721Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _factionIdCounter;

    // --- Enums ---
    enum PetType { Unknown, Elemental, Mystic, Robotic, Organic }
    enum PetMood { Content, Neutral, Grumpy, Sad }
    enum PetHunger { Full, Satisfied, Hungry, Starving }
    enum PetTrait { None, Fire, Water, Earth, Air, Arcane, Tech, Nature, Radiant, Shadow } // Example traits

    // --- Structs ---
    struct PetStatus {
        uint16 level;
        uint32 xp;
        PetMood mood;
        PetHunger hunger;
        uint256 lastFedTime;
        uint256 lastPlayedTime;
        uint256 lastTrainedTime;
        uint256 mintTime;
        uint256 lastDecayCalcTime; // Track when decay was last applied
        uint256 factionId;
    }

    struct PetTraits {
        PetType petType;
        PetTrait primaryTrait;
        PetTrait secondaryTrait;
        bool traitsLocked;
        uint8 evolutionStage; // 0 = egg/basic, 1, 2, etc.
    }

    struct DelegationInfo {
        address delegatee;
        uint64 expiryTime; // Timestamp when delegation expires
    }

    struct FactionInfo {
        string name;
        address owner; // Owner/manager of the faction
        bool exists; // Helper to check if factionId is valid
    }

    // --- State Variables ---
    mapping(uint256 => PetStatus) private _petStatuses;
    mapping(uint256 => PetTraits) private _petTraits;
    mapping(uint256 => DelegationInfo) private _petDelegations; // tokenId => delegation info
    mapping(uint256 => FactionInfo) private _factions; // factionId => faction info

    string private _baseTokenURI;

    uint256 public minBreedLevel = 5; // Minimum level required for pets to breed
    uint256 public evolutionCost = 0.01 ether; // ETH cost for evolution
    uint256 public traitLockCost = 0.005 ether; // ETH cost for locking/unlocking traits
    uint256 public decayRatePerHour = 5; // Points of hunger/mood lost per hour

    // --- Events ---
    event PetMinted(uint256 indexed tokenId, address indexed owner, PetType initialType);
    event PetStatusUpdated(uint256 indexed tokenId, PetStatus newStatus);
    event PetTraitsUpdated(uint256 indexed tokenId, PetTraits newTraits);
    event PetLeveledUp(uint256 indexed tokenId, uint16 newLevel);
    event PetEvolved(uint256 indexed tokenId, uint8 newStage, PetType newType, PetTrait newPrimaryTrait);
    event PetTraitsLocked(uint256 indexed tokenId);
    event PetTraitsUnlocked(uint256 indexed tokenId);
    event PetDelegated(uint256 indexed tokenId, address indexed delegatee, uint64 expiryTime);
    event PetDelegationRevoked(uint256 indexed tokenId);
    event FactionRegistered(uint256 indexed factionId, string name, address indexed owner);
    event PetJoinedFaction(uint256 indexed tokenId, uint256 indexed factionId);
    event PetLeftFaction(uint256 indexed tokenId, uint256 indexed factionId);
    event FactionOwnershipTransferred(uint256 indexed factionId, address indexed oldOwner, address indexed newOwner);
    event PetsBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event PetsMerged(uint256 indexed pet1Id, uint256 indexed pet2Id, uint256 indexed newPetId);
    event PetSacrificedForXP(uint256 indexed sacrificedPetId, uint256 indexed recipientPetId, uint32 xpGained);

    // --- Modifiers ---
    modifier onlyPetOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized for this pet");
        _;
    }

    modifier onlyPetOwnerOrDelegatee(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId) || _isDelegated(tokenId, msg.sender), "Not authorized for this pet");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        ERC721Pausable()
    {
        _baseTokenURI = baseURI;
        _factionIdCounter.increment(); // Reserve faction ID 0 as "None"
    }

    // --- ERC721 Standard Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This override incorporates dynamic pet state into the metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        string memory statePrefix = _getStatePrefix(tokenId);
        // Assuming the base URI endpoint can handle a path like /metadata/{statePrefix}/{tokenId}
        // Or the base URI already includes a final slash and we just append statePrefix/tokenId
        return string(abi.encodePacked(base, statePrefix, "/", Strings.toString(tokenId)));
    }

    /**
     * @dev Internal helper to generate a prefix for the token URI based on pet state.
     * This allows off-chain metadata services to quickly identify pets needing updates
     * or categorize them based on critical state (e.g., "hungry", "evolved", "level10").
     * This is a simple example; a real implementation might use a hash of key states.
     */
    function _getStatePrefix(uint256 tokenId) internal view returns (string memory) {
        PetStatus storage status = _petStatuses[tokenId];
        PetTraits storage traits = _petTraits[tokenId];

        if (status.hunger == PetHunger.Starving) return "starving";
        if (status.mood == PetMood.Sad) return "sad";
        if (traits.evolutionStage > 0) return string(abi.encodePacked("stage", Strings.toString(traits.evolutionStage)));
        if (status.level >= 10) return "highlevel";

        return "basic";
    }


    // --- Pet Management & Minting ---

    /**
     * @dev Mints a new ChronoPet token.
     * @param receiver The address to mint the token to.
     * @return uint256 The ID of the newly minted token.
     */
    function mintPet(address receiver) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(receiver, newTokenId);

        // Initialize random-ish state (simplified - true randomness needs oracles)
        PetStatus memory newStatus;
        newStatus.level = 1;
        newStatus.xp = 0;
        newStatus.mood = PetMood.Content;
        newStatus.hunger = PetHunger.Full;
        newStatus.mintTime = block.timestamp;
        newStatus.lastFedTime = block.timestamp;
        newStatus.lastPlayedTime = block.timestamp;
        newStatus.lastTrainedTime = block.timestamp;
        newStatus.lastDecayCalcTime = block.timestamp;
        newStatus.factionId = 0; // No faction initially

        PetTraits memory newTraits;
        newTraits.petType = _getRandomPetType(newTokenId); // Pseudo-random based on tokenId
        newTraits.primaryTrait = _getRandomTrait(newTokenId + 1); // Pseudo-random
        newTraits.secondaryTrait = _getRandomTrait(newTokenId + 2); // Pseudo-random
        newTraits.traitsLocked = false;
        newTraits.evolutionStage = 0;

        _petStatuses[newTokenId] = newStatus;
        _petTraits[newTokenId] = newTraits;

        emit PetMinted(newTokenId, receiver, newTraits.petType);
        emit PetStatusUpdated(newTokenId, newStatus);
        emit PetTraitsUpdated(newTokenId, newTraits);

        return newTokenId;
    }

    /**
     * @dev Mints multiple ChronoPet tokens in a batch.
     * @param receivers An array of addresses to mint tokens to.
     */
    function batchMintPets(address[] calldata receivers) public onlyOwner whenNotPaused {
        for (uint i = 0; i < receivers.length; i++) {
            mintPet(receivers[i]); // Reuses single mint logic
        }
    }

    /**
     * @dev Breeds two pets to create a new one. Requires both parents to meet criteria and costs ETH.
     * Parents remain owned but may get breeding cooldowns (not implemented here).
     * Traits/type inheritance is simplified.
     */
    function breedPets(uint256 parent1Id, uint256 parent2Id) public payable nonReentrant whenNotPaused onlyPetOwnerOrDelegatee(parent1Id) onlyPetOwnerOrDelegatee(parent2Id) {
        address parent1Owner = ownerOf(parent1Id);
        address parent2Owner = ownerOf(parent2Id);

        require(msg.value >= evolutionCost, "Insufficient ETH for breeding");
        require(parent1Owner == parent2Owner, "Parents must have the same owner for breeding"); // Simplified: owner breeds their own pets
        require(parent1Id != parent2Id, "Cannot breed a pet with itself");
        require(_petStatuses[parent1Id].level >= minBreedLevel && _petStatuses[parent2Id].level >= minBreedLevel, "Parents must meet minimum breed level");
        // Add checks for hunger/mood/breeding cooldowns in a real implementation

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        _safeMint(parent1Owner, childTokenId); // Child minted to the owner of both parents

        // Initialize child state (simplified inheritance/randomness)
        PetStatus memory childStatus;
        childStatus.level = 1;
        childStatus.xp = 0;
        childStatus.mood = PetMood.Content; // Start happy and full
        childStatus.hunger = PetHunger.Full;
        childStatus.mintTime = block.timestamp;
        childStatus.lastFedTime = block.timestamp;
        childStatus.lastPlayedTime = block.timestamp;
        childStatus.lastTrainedTime = block.timestamp;
        childStatus.lastDecayCalcTime = block.timestamp;
        childStatus.factionId = 0; // Children start factionless

        PetTraits memory childTraits;
        // Simplified trait inheritance: Randomly pick type/traits from parents or new
        if (uint256(keccak256(abi.encodePacked(childTokenId, block.timestamp))) % 2 == 0) {
             childTraits.petType = _petTraits[parent1Id].petType;
        } else {
             childTraits.petType = _petTraits[parent2Id].petType;
        }
         if (uint256(keccak256(abi.encodePacked(childTokenId, block.timestamp, 1))) % 2 == 0) {
             childTraits.primaryTrait = _petTraits[parent1Id].primaryTrait;
        } else {
             childTraits.primaryTrait = _petTraits[parent2Id].primaryTrait;
        }
         if (uint256(keccak256(abi.encodePacked(childTokenId, block.timestamp, 2))) % 2 == 0) {
             childTraits.secondaryTrait = _petTraits[parent1Id].secondaryTrait;
        } else {
             childTraits.secondaryTrait = _petTraits[parent2Id].secondaryTrait;
        }
        // Add logic for trait combination/mutation
        childTraits.traitsLocked = false; // Traits unlocked upon birth
        childTraits.evolutionStage = 0;

        _petStatuses[childTokenId] = childStatus;
        _petTraits[childTokenId] = childTraits;

        // Add logic to apply breeding cooldowns to parents

        emit PetsBred(parent1Id, parent2Id, childTokenId);
        emit PetMinted(childTokenId, parent1Owner, childTraits.petType);
        emit PetStatusUpdated(childTokenId, childStatus);
        emit PetTraitsUpdated(childTokenId, childTraits);
        // Refund excess ETH if any
        if (msg.value > evolutionCost) {
            payable(msg.sender).transfer(msg.value - evolutionCost);
        }
    }

    /**
     * @dev Merges two pets into a new one, burning the originals. Costs ETH.
     * New pet inherits combined XP/levels or gets a bonus.
     */
    function mergePets(uint256 pet1Id, uint256 pet2Id) public payable nonReentrant whenNotPaused onlyPetOwnerOrDelegatee(pet1Id) onlyPetOwnerOrDelegatee(pet2Id) {
        address pet1Owner = ownerOf(pet1Id);
        address pet2Owner = ownerOf(pet2Id);

        require(msg.value >= evolutionCost, "Insufficient ETH for merging"); // Use same cost for simplicity
        require(pet1Owner == pet2Owner, "Pets must have the same owner for merging");
        require(pet1Id != pet2Id, "Cannot merge a pet with itself");
        // Add checks for state/eligibility

        uint16 mergedLevel = _petStatuses[pet1Id].level + _petStatuses[pet2Id].level;
        uint32 mergedXp = _petStatuses[pet1Id].xp + _petStatuses[pet2Id].xp;
        // Add logic for trait/type combination/mutation

        _burn(pet1Id);
        _burn(pet2Id);

        _tokenIdCounter.increment();
        uint256 newPetId = _tokenIdCounter.current();

        _safeMint(pet1Owner, newPetId);

        PetStatus memory newStatus;
        newStatus.level = mergedLevel; // Combined level
        newStatus.xp = mergedXp;       // Combined XP
        newStatus.mood = PetMood.Content;
        newStatus.hunger = PetHunger.Full;
        newStatus.mintTime = block.timestamp;
        newStatus.lastFedTime = block.timestamp;
        newStatus.lastPlayedTime = block.timestamp;
        newStatus.lastTrainedTime = block.timestamp;
        newStatus.lastDecayCalcTime = block.timestamp;
         newStatus.factionId = 0; // Merged pets start factionless

        PetTraits memory newTraits = _petTraits[pet1Id]; // Simplified: inherit traits from pet1
        // Add logic for trait combination/mutation
        newTraits.evolutionStage = newTraits.evolutionStage + 1; // Merge increases evolution stage

        _petStatuses[newPetId] = newStatus;
        _petTraits[newPetId] = newTraits;

        emit PetsMerged(pet1Id, pet2Id, newPetId);
        emit PetMinted(newPetId, pet1Owner, newTraits.petType);
         emit PetStatusUpdated(newPetId, newStatus);
        emit PetTraitsUpdated(newPetId, newTraits);

         // Refund excess ETH if any
        if (msg.value > evolutionCost) {
            payable(msg.sender).transfer(msg.value - evolutionCost);
        }
    }

    /**
     * @dev Sacrifices one pet to grant its XP (or a portion) to another.
     * The sacrificed pet is burned.
     */
    function sacrificePetForXP(uint256 sacrificedPetId, uint256 recipientPetId) public nonReentrant whenNotPaused {
        address sacrificedOwner = ownerOf(sacrificedPetId);
        address recipientOwner = ownerOf(recipientPetId);

        require(sacrificedOwner == msg.sender || _isApprovedOrOwner(msg.sender, sacrificedPetId), "Not authorized for sacrificed pet");
        require(recipientOwner == msg.sender || _isApprovedOrOwner(msg.sender, recipientPetId), "Not authorized for recipient pet");
        require(sacrificedOwner == recipientOwner, "Pets must have the same owner for sacrifice");
        require(sacrificedPetId != recipientPetId, "Cannot sacrifice a pet to itself");

        PetStatus storage sacrificedStatus = _petStatuses[sacrificedPetId];
        uint32 xpToTransfer = sacrificedStatus.xp; // Transfer all XP for simplicity

        _burn(sacrificedPetId);

        // Apply decay to recipient before adding XP
        _calculateDecay(recipientPetId);
        PetStatus storage recipientStatus = _petStatuses[recipientPetId];
        recipientStatus.xp += xpToTransfer;

        // Check for level up on the recipient
        _checkLevelUp(recipientPetId, recipientStatus);

        emit PetSacrificedForXP(sacrificedPetId, recipientPetId, xpToTransfer);
        emit PetStatusUpdated(recipientPetId, recipientStatus);
    }


    // --- Dynamic State Interaction ---

    /**
     * @dev Feeds a pet, improving its hunger state.
     */
    function feedPet(uint256 tokenId) public whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        _calculateDecay(tokenId);
        PetStatus storage status = _petStatuses[tokenId];

        if (status.hunger > PetHunger.Full) {
            status.hunger = PetHunger(uint8(status.hunger) - 1);
        }
        status.lastFedTime = block.timestamp;
        status.xp += 10; // Small XP gain for feeding

        _checkLevelUp(tokenId, status);
        emit PetStatusUpdated(tokenId, status);
    }

    /**
     * @dev Plays with a pet, improving its mood state.
     */
    function playWithPet(uint256 tokenId) public whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        _calculateDecay(tokenId);
        PetStatus storage status = _petStatuses[tokenId];

        if (status.mood > PetMood.Content) {
            status.mood = PetMood(uint8(status.mood) - 1);
        }
        status.lastPlayedTime = block.timestamp;
        status.xp += 10; // Small XP gain for playing

        _checkLevelUp(tokenId, status);
        emit PetStatusUpdated(tokenId, status);
    }

    /**
     * @dev Trains a pet, granting XP.
     */
    function trainPet(uint256 tokenId) public whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        _calculateDecay(tokenId);
        PetStatus storage status = _petStatuses[tokenId];

        // Add logic for training cooldown if needed
        status.lastTrainedTime = block.timestamp;
        status.xp += 50; // Significant XP gain

        _checkLevelUp(tokenId, status);
        emit PetStatusUpdated(tokenId, status);
    }

    /**
     * @dev Internal function to calculate and apply time-based state decay.
     * Called before any interaction functions (feed, play, train).
     */
    function _calculateDecay(uint256 tokenId) internal {
        PetStatus storage status = _petStatuses[tokenId];
        uint256 timePassed = block.timestamp - status.lastDecayCalcTime;
        status.lastDecayCalcTime = block.timestamp;

        if (timePassed == 0) return; // No time passed, no decay

        uint256 hoursPassed = timePassed / 3600; // Calculate full hours passed
        uint256 decayPoints = hoursPassed * decayRatePerHour;

        if (decayPoints > 0) {
            // Apply decay to hunger (min 0, max PetHunger.Starving)
            uint8 currentHunger = uint8(status.hunger);
            uint8 newHunger = uint8(Math.min(currentHunger + decayPoints, uint256(PetHunger.Starving)));
            status.hunger = PetHunger(newHunger);

            // Apply decay to mood (min 0, max PetMood.Sad)
            uint8 currentMood = uint8(status.mood);
            uint8 newMood = uint8(Math.min(currentMood + decayPoints, uint256(PetMood.Sad)));
            status.mood = PetMood(newMood);

            // Optional: Add XP loss for neglect
            // status.xp = uint32(Math.max(0, int256(status.xp) - int256(decayPoints * 2)));
        }
    }

    /**
     * @dev Internal function to check if a pet has leveled up based on XP and update level.
     */
    function _checkLevelUp(uint256 tokenId, PetStatus storage status) internal {
        // Simplified XP required per level
        uint32 xpForNextLevel = status.level * 100 + 100; // Example: Level 1 needs 200, Level 2 needs 300, etc.

        while (status.xp >= xpForNextLevel) {
            status.xp -= xpForNextLevel; // Subtract XP for level up
            status.level += 1;           // Increment level
            emit PetLeveledUp(tokenId, status.level);
            xpForNextLevel = status.level * 100 + 100; // Calculate XP for the *new* next level
        }
    }


    // --- Evolution & Traits ---

    /**
     * @dev Attempts to evolve the pet. Requires ETH and meeting conditions.
     * Changes pet traits and evolution stage.
     */
    function evolvePet(uint256 tokenId) public payable nonReentrant whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        require(msg.value >= evolutionCost, "Insufficient ETH for evolution");
        require(!_petTraits[tokenId].traitsLocked, "Pet traits are locked");
        require(isEvolutionReady(tokenId), "Pet is not ready to evolve");

        PetTraits storage traits = _petTraits[tokenId];
        PetStatus storage status = _petStatuses[tokenId];

        traits.evolutionStage += 1;
        // Simplified trait change on evolution (pseudo-random based on current stage and timestamp)
        traits.petType = _getRandomPetType(tokenId + traits.evolutionStage * 100 + block.timestamp);
        traits.primaryTrait = _getRandomTrait(tokenId + traits.evolutionStage * 200 + block.timestamp);
        traits.secondaryTrait = _getRandomTrait(tokenId + traits.evolutionStage * 300 + block.timestamp);

        // Reset some state upon evolution? E.g., full hunger/mood.
        status.mood = PetMood.Content;
        status.hunger = PetHunger.Full;
        status.lastFedTime = block.timestamp;
        status.lastPlayedTime = block.timestamp;
        status.lastDecayCalcTime = block.timestamp;


        emit PetEvolved(tokenId, traits.evolutionStage, traits.petType, traits.primaryTrait);
        emit PetTraitsUpdated(tokenId, traits);
         emit PetStatusUpdated(tokenId, status);

        // Refund excess ETH if any
        if (msg.value > evolutionCost) {
            payable(msg.sender).transfer(msg.value - evolutionCost);
        }
    }

    /**
     * @dev Checks if a pet meets the minimum requirements to attempt evolution.
     * Does not guarantee evolution success if other factors apply (e.g., specific hidden states).
     */
    function isEvolutionReady(uint256 tokenId) public view returns (bool) {
        // Simplified check: Requires minimum level and age
        PetStatus storage status = _petStatuses[tokenId];
        // Check if token exists and is owned
        if (ownerOf(tokenId) == address(0)) return false;

        uint256 ageInSeconds = block.timestamp - status.mintTime;
        uint16 minLevel = 5; // Example minimum level
        uint256 minAgeInSeconds = 7 * 24 * 3600; // Example minimum age (7 days)

        return status.level >= minLevel && ageInSeconds >= minAgeInSeconds && !_petTraits[tokenId].traitsLocked;
        // A real implementation might also check hunger/mood state
    }


    /**
     * @dev Locks the pet's current traits, preventing changes from evolution or other events.
     */
    function lockTraits(uint256 tokenId) public payable whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        require(msg.value >= traitLockCost, "Insufficient ETH for locking traits");
        require(!_petTraits[tokenId].traitsLocked, "Traits are already locked");

        _petTraits[tokenId].traitsLocked = true;
        emit PetTraitsLocked(tokenId);
         emit PetTraitsUpdated(tokenId, _petTraits[tokenId]);

        // Refund excess ETH if any
        if (msg.value > traitLockCost) {
            payable(msg.sender).transfer(msg.value - traitLockCost);
        }
    }

    /**
     * @dev Unlocks the pet's traits, allowing future changes.
     */
    function unlockTraits(uint256 tokenId) public payable whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
         require(msg.value >= traitLockCost, "Insufficient ETH for unlocking traits");
        require(_petTraits[tokenId].traitsLocked, "Traits are already unlocked");

        _petTraits[tokenId].traitsLocked = false;
        emit PetTraitsUnlocked(tokenId);
        emit PetTraitsUpdated(tokenId, _petTraits[tokenId]);

        // Refund excess ETH if any
        if (msg.value > traitLockCost) {
            payable(msg.sender).transfer(msg.value - traitLockCost);
        }
    }


    // --- Delegation ---

    /**
     * @dev Delegates temporary control of pet interaction to another address.
     * Delegatee cannot transfer or approve the token itself.
     * @param tokenId The ID of the pet to delegate.
     * @param delegatee The address to delegate control to.
     * @param duration The duration (in seconds) of the delegation.
     */
    function delegatePetOwnership(uint256 tokenId, address delegatee, uint64 duration) public whenNotPaused onlyPetOwner(tokenId) {
        require(delegatee != address(0), "Cannot delegate to zero address");
        require(duration > 0, "Delegation duration must be greater than 0");

        _petDelegations[tokenId] = DelegationInfo({
            delegatee: delegatee,
            expiryTime: uint64(block.timestamp) + duration
        });

        emit PetDelegated(tokenId, delegatee, uint64(block.timestamp) + duration);
    }

     /**
     * @dev Revokes an active delegation for a pet. Can be called by owner or the delegatee.
     */
    function revokeDelegation(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender || _petDelegations[tokenId].delegatee == msg.sender, "Not authorized to revoke delegation");
        require(_isDelegated(tokenId, _petDelegations[tokenId].delegatee), "No active delegation for this pet");

        delete _petDelegations[tokenId];

        emit PetDelegationRevoked(tokenId);
    }

    /**
     * @dev Internal helper to check if an address is currently delegated for a pet.
     */
    function _isDelegated(uint256 tokenId, address potentialDelegatee) internal view returns (bool) {
        DelegationInfo storage delegation = _petDelegations[tokenId];
        return delegation.delegatee != address(0) && delegation.delegatee == potentialDelegatee && delegation.expiryTime > block.timestamp;
    }


    // --- Faction System ---

     /**
     * @dev Registers a new faction that pets can join. Only callable by contract owner.
     * @param name The name of the faction.
     * @return uint256 The ID of the newly registered faction.
     */
    function registerFaction(string memory name) public onlyOwner whenNotPaused returns (uint256) {
        _factionIdCounter.increment();
        uint256 newFactionId = _factionIdCounter.current();

        _factions[newFactionId] = FactionInfo({
            name: name,
            owner: msg.sender, // Initial faction owner is contract owner
            exists: true
        });

        emit FactionRegistered(newFactionId, name, msg.sender);
        return newFactionId;
    }

     /**
     * @dev Allows a pet to join a registered faction.
     * @param tokenId The ID of the pet.
     * @param factionId The ID of the faction to join.
     */
    function joinFaction(uint256 tokenId, uint256 factionId) public whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        require(_factions[factionId].exists, "Faction does not exist");
        require(_petStatuses[tokenId].factionId == 0, "Pet is already in a faction"); // Simple: only join if factionless

        _petStatuses[tokenId].factionId = factionId;
        emit PetJoinedFaction(tokenId, factionId);
         emit PetStatusUpdated(tokenId, _petStatuses[tokenId]);
    }

    /**
     * @dev Allows a pet to leave its current faction.
     * @param tokenId The ID of the pet.
     */
    function leaveFaction(uint256 tokenId) public whenNotPaused onlyPetOwnerOrDelegatee(tokenId) {
        require(_petStatuses[tokenId].factionId != 0, "Pet is not in a faction");

        uint256 oldFactionId = _petStatuses[tokenId].factionId;
        _petStatuses[tokenId].factionId = 0;
        emit PetLeftFaction(tokenId, oldFactionId);
         emit PetStatusUpdated(tokenId, _petStatuses[tokenId]);
    }

     /**
     * @dev Transfers the management ownership of a faction.
     * @param factionId The ID of the faction.
     * @param newOwner The address of the new owner.
     */
    function transferFactionOwnership(uint256 factionId, address newOwner) public whenNotPaused {
        require(_factions[factionId].exists, "Faction does not exist");
        require(_factions[factionId].owner == msg.sender, "Not the faction owner");
        require(newOwner != address(0), "Cannot transfer ownership to zero address");

        address oldOwner = _factions[factionId].owner;
        _factions[factionId].owner = newOwner;

        emit FactionOwnershipTransferred(factionId, oldOwner, newOwner);
    }


    // --- View Functions (Getters) ---

     /**
     * @dev Gets the dynamic status of a pet.
     */
    function getPetStatus(uint256 tokenId) public view returns (PetStatus memory) {
         _requireOwned(tokenId);
        return _petStatuses[tokenId];
    }

     /**
     * @dev Gets the traits of a pet.
     */
    function getPetTraits(uint256 tokenId) public view returns (PetTraits memory) {
        _requireOwned(tokenId);
        return _petTraits[tokenId];
    }

     /**
     * @dev Gets the timestamps associated with pet interactions and minting.
     */
     function getPetTimestamps(uint256 tokenId) public view returns (uint256 mintTime, uint256 lastFedTime, uint256 lastPlayedTime, uint256 lastTrainedTime, uint256 lastDecayCalcTime) {
         _requireOwned(tokenId);
         PetStatus storage status = _petStatuses[tokenId];
         return (status.mintTime, status.lastFedTime, status.lastPlayedTime, status.lastTrainedTime, status.lastDecayCalcTime);
     }

     /**
      * @dev Calculates and returns the current age of the pet in seconds.
      */
     function getPetAge(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
         return block.timestamp - _petStatuses[tokenId].mintTime;
     }

    /**
     * @dev Gets the current delegation info for a pet.
     */
    function getDelegationInfo(uint256 tokenId) public view returns (address delegatee, uint64 expiryTime) {
        _requireOwned(tokenId);
        DelegationInfo storage delegation = _petDelegations[tokenId];
        return (delegation.delegatee, delegation.expiryTime);
    }

     /**
     * @dev Gets the faction ID a pet belongs to.
     */
     function getFaction(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
         return _petStatuses[tokenId].factionId;
     }

     /**
     * @dev Gets the information for a registered faction.
     */
     function getFactionInfo(uint256 factionId) public view returns (FactionInfo memory) {
         require(_factions[factionId].exists, "Faction does not exist");
         return _factions[factionId];
     }

     /**
      * @dev Gets the total number of registered factions (including faction 0 which is reserved).
      */
     function getFactionCount() public view returns (uint256) {
         return _factionIdCounter.current();
     }


    // --- Admin Functions ---

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setMinBreedLevel(uint256 level) public onlyOwner {
        minBreedLevel = level;
    }

    function setEvolutionCost(uint256 cost) public onlyOwner {
        evolutionCost = cost;
    }

    function setTraitLockCost(uint256 cost) public onlyOwner {
        traitLockCost = cost;
    }

    function setDecayRate(uint256 rate) public onlyOwner {
        decayRatePerHour = rate;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawEth() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        require(balance > 0, "Contract has no ETH");
        payable(msg.sender).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Internal/Helper Functions ---

     /**
      * @dev Internal helper to require that a token exists and is owned by someone.
      * Overrides the one from ERC721.sol to provide a clearer error message.
      */
    function _requireOwned(uint256 tokenId) internal view virtual {
        require(_ownerOf(tokenId) != address(0), "ERC721: invalid token ID");
    }


    /**
     * @dev Pseudo-random number generator for initial pet type.
     * NOTE: On-chain pseudo-randomness is predictable. Do not use for security-sensitive features.
     */
    function _getRandomPetType(uint256 seed) internal pure returns (PetType) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty)));
        return PetType(rand % 4 + 1); // Skip Unknown (0)
    }

     /**
     * @dev Pseudo-random number generator for initial pet trait.
     * NOTE: On-chain pseudo-randomness is predictable.
     */
    function _getRandomTrait(uint256 seed) internal pure returns (PetTrait) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty)));
         return PetTrait(rand % 9 + 1); // Skip None (0)
    }

    // Override _update and _increaseBalance to potentially add custom logic if needed
    // Example: add logic for burning (balance decreases), but standard ERC721 handles this.
    // If you needed to track *total* burned, you'd override _burn.

     // Need to override ERC721's _requireOwned if we use it internally, or just use our custom one.
     // ERC721 uses _ownerOf(tokenId) != address(0) already, so _requireOwned is redundant if just checking existence.
     // Let's use the standard one and keep our custom one for clarity in the pet-specific modifiers.

     // ERC721's _beforeTokenTransfer hook could be used to reset state like delegation on transfer if desired,
     // but keeping state persistent across transfers is also a valid design choice. For this example,
     // state persists, but delegation doesn't automatically transfer. A new owner would need to delegate again.

}
```