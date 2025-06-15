Okay, let's design a smart contract for "Quantum Entities" - dynamic NFTs that can fuse, evolve, and have attributes influenced by time and probabilistic outcomes. This combines elements of gaming mechanics, dynamic NFTs, and configurable parameters.

We will create a contract called `QuantumFusionNFT` that inherits from ERC721 and includes custom logic for these features.

**Concepts Used:**

1.  **ERC721 Standard:** Basic NFT functionality.
2.  **Dynamic NFTs:** Token metadata (`tokenURI`) will depend on the NFT's current state (attributes stored on-chain). An off-chain service would read the state and generate the JSON metadata.
3.  **State Transitions:** NFTs change state through `fuseEntities` and `evolveEntity`.
4.  **Probabilistic Outcomes:** Fusion and Evolution can succeed or fail based on configurable rates and potentially entity attributes, introducing uncertainty ("Quantum" aspect).
5.  **Time-Based Mechanics:** Entity energy levels regenerate over time.
6.  **Attribute System:** Entities have structured attributes influencing gameplay.
7.  **Resource Management:** Actions like evolution might require fees (Ether). Energy is a resource consumed by actions.
8.  **Configurability:** Owner can adjust parameters like fusion/evolution fees and success rates.
9.  **Pausability:** Standard safety mechanism.
10. **Ownable:** Standard access control.

**Outline:**

1.  Pragma, Imports, Errors, Events.
2.  Struct for Entity Attributes.
3.  Enum for Entity Types.
4.  State Variables (mappings for attributes, counters, config, etc.).
5.  Modifiers (owner checks, pause checks, entity existence, owner checks).
6.  Constructor.
7.  ERC721 Standard Functions (`balanceOf`, `ownerOf`, `transferFrom`, etc.).
8.  ERC721 Metadata Function (`tokenURI`).
9.  Core Game Logic Functions (`mintInitialEntity`, `fuseEntities`, `evolveEntity`, `rechargeEnergy`, `burnEntity`).
10. Getter Functions (for attributes, state, config).
11. Admin/Configuration Functions (setters, withdraw, pause, ownership).
12. Internal Helper Functions (attribute generation, randomness simulation, energy calculation, logic for fusion/evolution outcomes).

**Function Summary:**

*   **`constructor()`:** Initializes the contract, setting basic ERC721 details and owner.
*   **`supportsInterface(bytes4 interfaceId)`:** ERC165 standard compliance.
*   **`name()`:** Returns the ERC721 collection name.
*   **`symbol()`:** Returns the ERC721 collection symbol.
*   **`balanceOf(address owner)`:** Returns the number of NFTs owned by an address.
*   **`ownerOf(uint256 tokenId)`:** Returns the owner of a specific NFT.
*   **`approve(address to, uint256 tokenId)`:** Grants approval for one NFT.
*   **`getApproved(uint256 tokenId)`:** Gets the approved address for an NFT.
*   **`setApprovalForAll(address operator, bool approved)`:** Grants/revokes approval for all NFTs.
*   **`isApprovedForAll(address owner, address operator)`:** Checks if an operator is approved for all NFTs of an owner.
*   **`transferFrom(address from, address to, uint256 tokenId)`:** Transfers ownership of an NFT.
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`:** Safe transfer, checks receiver.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`:** Safe transfer with data.
*   **`tokenURI(uint256 tokenId)`:** Returns the metadata URI for an NFT. (Dynamic aspect)
*   **`mintInitialEntity(address recipient, uint256 initialType)`:** Mints a new Quantum Entity with initial randomized attributes based on type.
*   **`fuseEntities(uint256 tokenId1, uint256 tokenId2)`:** Attempts to fuse two entities. Burns inputs. May create a new entity based on success rate and attributes. (Advanced/Creative: Complex state transition, probabilistic outcome)
*   **`evolveEntity(uint256 tokenId)`:** Attempts to evolve an entity. Requires energy and fee. May increase level/attributes based on success rate. (Advanced/Creative: Complex state transition, probabilistic outcome, resource consumption)
*   **`rechargeEnergy(uint256 tokenId)`:** Updates an entity's energy based on elapsed time. (Advanced/Creative: Time-based mechanic)
*   **`burnEntity(uint256 tokenId)`:** Removes an entity from existence.
*   **`getEntityAttributes(uint256 tokenId)`:** Gets all attributes for an entity.
*   **`getEntityLevel(uint256 tokenId)`:** Gets the level of an entity.
*   **`getEntityEnergy(uint256 tokenId)`:** Gets the current calculated energy of an entity. (Advanced/Creative: Calculated state)
*   **`getEntityStability(uint256 tokenId)`:** Gets the stability of an entity.
*   **`getEntityType(uint256 tokenId)`:** Gets the type of an entity.
*   **`getTotalEntitiesMinted()`:** Gets the total number of entities ever minted.
*   **`setBaseURI(string memory baseURI)`:** Sets the base URI for token metadata.
*   **`setFusionFee(uint256 fee)`:** Sets the Ether fee required for fusion.
*   **`setEvolutionFee(uint256 fee)`:** Sets the Ether fee required for evolution.
*   **`setMinFusionLevelForFusion(uint256 minLevel)`:** Sets the minimum level an entity must have to participate in fusion. (Game balance config)
*   **`setFusionSuccessRate(uint256 rate)`:** Sets the base probability (0-10000 for 0-100%) of fusion success. (Game balance config)
*   **`setEvolutionSuccessRate(uint256 rate)`:** Sets the base probability (0-10000) of evolution success. (Game balance config)
*   **`getFusionFee()`:** Gets the current fusion fee.
*   **`getEvolutionFee()`:** Gets the current evolution fee.
*   **`getMinFusionLevelForFusion()`:** Gets the minimum fusion level.
*   **`getFusionSuccessRate()`:** Gets the fusion success rate.
*   **`getEvolutionSuccessRate()`:** Gets the evolution success rate.
*   **`pause()`:** Pauses contract operations (minting, fusion, evolution, etc.).
*   **`unpause()`:** Unpauses contract operations.
*   **`paused()`:** Checks if the contract is paused.
*   **`withdrawFees()`:** Allows the owner to withdraw collected Ether fees.
*   **`transferOwnership(address newOwner)`:** Transfers contract ownership.
*   **`renounceOwnership()`:** Renounces contract ownership (makes it unowned).

This list includes 13 standard ERC721 functions (including the two safeTransferFrom versions and supportsInterface) + 23 custom/config/admin functions = **36 functions**, easily exceeding the requirement of 20.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // For burning NFTs
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/average if needed
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI helper

// --- OUTLINE ---
// 1. Pragmas, Imports, Errors, Events
// 2. Structs & Enums for Entity Data
// 3. State Variables
// 4. Modifiers
// 5. Constructor
// 6. ERC721 Standard Functions
// 7. ERC721 Metadata Function (Dynamic)
// 8. Core Game Logic: Mint, Fuse, Evolve, Recharge, Burn
// 9. Getter Functions (for entity state and contract config)
// 10. Admin & Configuration Functions (Setters, Withdraw, Pause, Ownership)
// 11. Internal Helper Functions

// --- FUNCTION SUMMARY ---
// constructor(): Initialize contract with name, symbol, and owner.
// supportsInterface(bytes4 interfaceId): ERC165 interface check.
// name(): ERC721: Returns the collection name.
// symbol(): ERC721: Returns the collection symbol.
// balanceOf(address owner): ERC721: Returns NFT count for an address.
// ownerOf(uint256 tokenId): ERC721: Returns the owner of a token.
// approve(address to, uint256 tokenId): ERC721: Approve one token.
// getApproved(uint256 tokenId): ERC721: Get approved address for a token.
// setApprovalForAll(address operator, bool approved): ERC721: Approve operator for all tokens.
// isApprovedForAll(address owner, address operator): ERC721: Check operator approval.
// transferFrom(address from, address to, uint256 tokenId): ERC721: Transfer token.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721: Safe transfer (checks receiver).
// safeTransferFrom(address from, address to, uint256 tokenId, bytes data): ERC721: Safe transfer with data.
// tokenURI(uint256 tokenId): ERC721 Metadata: Returns URI for dynamic metadata.
// mintInitialEntity(address recipient, uint256 initialType): Mints a new entity with attributes.
// fuseEntities(uint256 tokenId1, uint256 tokenId2): Attempts to fuse two entities into potentially one new one (probabilistic). Burns inputs.
// evolveEntity(uint256 tokenId): Attempts to evolve an entity (probabilistic). Requires energy and fee.
// rechargeEnergy(uint256 tokenId): Calculates and updates energy based on time.
// burnEntity(uint256 tokenId): Burns (destroys) an entity. Inherited from ERC721Burnable.
// getEntityAttributes(uint256 tokenId): Get all attributes for an entity.
// getEntityLevel(uint256 tokenId): Get the level of an entity.
// getEntityEnergy(uint256 tokenId): Get the current calculated energy.
// getEntityStability(uint256 tokenId): Get the stability of an entity.
// getEntityType(uint256 tokenId): Get the type of an entity.
// getTotalEntitiesMinted(): Get the total number of entities ever minted.
// setBaseURI(string memory baseURI): Admin: Set the base URI for metadata.
// setFusionFee(uint256 fee): Admin: Set the ETH fee for fusion.
// setEvolutionFee(uint256 fee): Admin: Set the ETH fee for evolution.
// setMinFusionLevelForFusion(uint256 minLevel): Admin: Set min level required for fusion participation.
// setFusionSuccessRate(uint256 rate): Admin: Set base fusion success chance (0-10000).
// setEvolutionSuccessRate(uint256 rate): Admin: Set base evolution success chance (0-10000).
// getFusionFee(): Getter for fusion fee.
// getEvolutionFee(): Getter for evolution fee.
// getMinFusionLevelForFusion(): Getter for min fusion level.
// getFusionSuccessRate(): Getter for fusion success rate.
// getEvolutionSuccessRate(): Getter for evolution success rate.
// pause(): Admin: Pause core operations.
// unpause(): Admin: Unpause core operations.
// paused(): Getter: Check if contract is paused.
// withdrawFees(): Admin: Withdraw accumulated ETH fees.
// transferOwnership(address newOwner): Admin: Transfer contract ownership.
// renounceOwnership(): Admin: Renounce contract ownership.

contract QuantumFusionNFT is ERC721, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- 1. Pragmas, Imports, Errors, Events ---

    error EntityNotFound(uint256 tokenId);
    error NotEntityOwner(uint256 tokenId, address caller);
    error FusionRequiresTwoEntities();
    error CannotFuseSameEntity();
    error FusionEntitiesMustBeOwnedByCaller();
    error EvolutionEntityMustBeOwnedByCaller();
    error EntityBelowMinFusionLevel(uint256 tokenId, uint256 requiredLevel);
    error InsufficientEnergy(uint256 tokenId, uint256 requiredEnergy);
    error InsufficientFusionFee(uint256 requiredFee, uint256 providedFee);
    error InsufficientEvolutionFee(uint256 requiredFee, uint256 providedFee);
    error InvalidRate(uint256 rate); // Rate expected 0-10000

    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256 entityType, uint256 initialLevel);
    event EntitiesFused(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner, uint256 outcome, uint256 resultTokenId); // outcome: 0=Failure, 1=Success, 2=Partial
    event EntityEvolved(uint256 indexed tokenId, address indexed owner, uint256 outcome, uint256 newLevel); // outcome: 0=Failure, 1=Success
    event EntityEnergyRecharged(uint256 indexed tokenId, uint256 newEnergyLevel);
    event EntityBurned(uint256 indexed tokenId, address indexed owner);
    event BaseURIUpdated(string newBaseURI);
    event FusionFeeUpdated(uint256 newFee);
    event EvolutionFeeUpdated(uint256 newFee);
    event MinFusionLevelUpdated(uint256 newMinLevel);
    event FusionSuccessRateUpdated(uint256 newRate);
    event EvolutionSuccessRateUpdated(uint256 newRate);
    event TimePerEnergyRegenUpdated(uint256 newTime);

    // --- 2. Structs & Enums ---

    enum EntityType { QuantumSpark, PlasmaOrb, VoidDrifter, ChronoShard, SingularityNode } // Example types

    struct EntityAttributes {
        uint256 entityType; // Corresponds to EntityType enum index
        uint256 level;
        uint256 energy; // Current calculated energy (not raw stored value)
        uint256 stability; // Affects success rates (e.g., 0-100)
        uint256 fusionCount; // How many times this entity has been part of a successful fusion (as input)
        uint256 evolutionCount; // How many times this entity has successfully evolved
        uint256 lastEnergyUpdateTime; // Timestamp of last energy update/action
        uint256 storedEnergy; // Raw stored energy value (energy is calculated based on this and time)
    }

    // --- 3. State Variables ---

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => EntityAttributes) private _entityAttributes;

    string private _baseTokenURI;

    uint256 public fusionFee = 0 ether; // Fee required to attempt fusion
    uint256 public evolutionFee = 0 ether; // Fee required to attempt evolution
    uint256 public minFusionLevelForFusion = 1; // Minimum level required for an entity to be used in fusion

    // Rates are 0-10000, representing 0% to 100% *base* success chance
    // Actual success chance might be modified by entity attributes like stability
    uint256 public fusionSuccessRate = 7000; // 70% base success chance
    uint256 public evolutionSuccessRate = 6000; // 60% base success chance

    // Time in seconds it takes to regenerate a certain amount of energy
    uint256 public timePerEnergyRegen = 1 hours; // Example: Regenerate 1 energy every hour
    uint256 public energyRegenAmount = 10; // Amount of energy regenerated per timePerEnergyRegen

    uint256 private constant MAX_ENERGY = 1000;
    uint256 private constant MAX_STABILITY = 100;
    uint256 private constant BASE_MIN_ENERGY_FOR_EVOLUTION = 50; // Base energy cost for evolution
    uint256 private constant BASE_MIN_ENERGY_FOR_FUSION = 100; // Base energy cost for fusion input

    // --- 4. Modifiers ---

    modifier entityExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert EntityNotFound(tokenId);
        }
        _;
    }

    modifier isEntityOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotEntityOwner(tokenId, _msgSender());
        }
        _;
    }

    modifier whenNotPausedAndExists(uint256 tokenId) {
        whenNotPaused();
        entityExists(tokenId);
        _;
    }

    modifier whenNotPausedAndOwner(uint256 tokenId) {
        whenNotPaused();
        isEntityOwner(tokenId);
        _;
    }

    modifier onlyRandomnessSource() {
        // In a real dApp, this would be a trusted oracle like Chainlink VRF
        // For this example, we'll just allow the owner or specific address
        // Or, for simplicity in this example, let the contract itself call it implicitly.
        // We won't make this a public modifier, but illustrate its concept.
        // require(msg.sender == randomnessOracleAddress, "Not randomness source");
        _; // Placeholder - logic is integrated directly for this example
    }


    // --- 5. Constructor ---

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {}

    // --- 6. ERC721 Standard Functions ---
    // (Most are inherited, but listed in summary. We implement tokenURI.)

    // --- 7. ERC721 Metadata Function (Dynamic) ---

    function tokenURI(uint256 tokenId) public view override entityExists(tokenId) returns (string memory) {
        // The actual metadata JSON should be generated off-chain by a service
        // that reads the current state of the NFT (attributes) from this contract
        // and combines it with static metadata.
        // This function just provides the pointer (URL) to that service endpoint.
        // The service would listen to events or poll contract state.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // Or a default URI indicating pending metadata
        }
        // Append the token ID to the base URI, e.g., "https://myapi.com/metadata/123"
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // --- 8. Core Game Logic ---

    /// @notice Mints a new Quantum Entity.
    /// @param recipient The address to mint the entity to.
    /// @param initialType The desired starting entity type (from EntityType enum index).
    function mintInitialEntity(address recipient, uint256 initialType) public onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Basic validation for initial type
        require(initialType < uint256(type(EntityType).max), "Invalid initial entity type");

        // Generate attributes - could be more complex based on initialType or randomness
        EntityAttributes memory newAttributes = _generateRandomAttributes(initialType);

        _entityAttributes[newTokenId] = newAttributes;
        _safeMint(recipient, newTokenId);

        emit EntityMinted(newTokenId, recipient, newAttributes.entityType, newAttributes.level);
    }

    /// @notice Attempts to fuse two Quantum Entities.
    /// Burns the two input entities. May create a new entity based on success rate.
    /// @param tokenId1 The ID of the first entity.
    /// @param tokenId2 The ID of the second entity.
    function fuseEntities(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused {
        if (tokenId1 == tokenId2) revert CannotFuseSameEntity();
        if (ownerOf(tokenId1) != _msgSender() || ownerOf(tokenId2) != _msgSender()) {
            revert FusionEntitiesMustBeOwnedByCaller();
        }
        if (msg.value < fusionFee) {
             revert InsufficientFusionFee(fusionFee, msg.value);
        }

        // Optional: Check minimum level for fusion participation
        if (_entityAttributes[tokenId1].level < minFusionLevelForFusion || _entityAttributes[tokenId2].level < minFusionLevelForFusion) {
             revert EntityBelowMinFusionLevel(
                _entityAttributes[tokenId1].level < minFusionLevelForFusion ? tokenId1 : tokenId2,
                minFusionLevelForFusion
            );
        }

        // Optional: Check minimum energy for fusion participation
         uint256 energy1 = _calculateCurrentEnergy(tokenId1);
         uint256 energy2 = _calculateCurrentEnergy(tokenId2);
         if (energy1 < BASE_MIN_ENERGY_FOR_FUSION || energy2 < BASE_MIN_ENERGY_FOR_FUSION) {
             revert InsufficientEnergy(
                 energy1 < BASE_MIN_ENERGY_FOR_FUSION ? tokenId1 : tokenId2,
                 BASE_MIN_ENERGY_FOR_FUSION
             );
         }

        // Consume energy immediately before potential burn
        _entityAttributes[tokenId1].storedEnergy = Math.max(0, _entityAttributes[tokenId1].storedEnergy - BASE_MIN_ENERGY_FOR_FUSION);
        _entityAttributes[tokenId1].lastEnergyUpdateTime = block.timestamp; // Update timestamp after consuming energy
        _entityAttributes[tokenId2].storedEnergy = Math.max(0, _entityAttributes[tokenId2].storedEnergy - BASE_MIN_ENERGY_FOR_FUSION);
        _entityAttributes[tokenId2].lastEnergyUpdateTime = block.timestamp; // Update timestamp after consuming energy


        // Burn the input entities first
        _burn(tokenId1);
        _burn(tokenId2);

        // Perform probabilistic fusion logic (using internal helper)
        // Note: Blockhash is NOT secure for randomness if outcomes are high value.
        // Use Chainlink VRF or similar in production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, tokenId1, tokenId2))) % 10000;

        uint256 resultTokenId = 0; // 0 indicates no new token
        uint256 outcome = 0; // 0=Failure, 1=Success, 2=Partial

        (outcome, resultTokenId) = _performFusionLogic(tokenId1, _entityAttributes[tokenId1], tokenId2, _entityAttributes[tokenId2], randomNumber);

        emit EntitiesFused(tokenId1, tokenId2, _msgSender(), outcome, resultTokenId);
    }

    /// @notice Attempts to evolve a Quantum Entity. Requires energy and fee.
    /// May increase level/attributes based on success rate.
    /// @param tokenId The ID of the entity to evolve.
    function evolveEntity(uint256 tokenId) public payable whenNotPausedAndOwner(tokenId) {
        EntityAttributes storage entity = _entityAttributes[tokenId]; // Use storage reference

        if (msg.value < evolutionFee) {
             revert InsufficientEvolutionFee(evolutionFee, msg.value);
        }

        // Calculate current energy and check requirement
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId);
        if (currentEnergy < BASE_MIN_ENERGY_FOR_EVOLUTION) {
            revert InsufficientEnergy(tokenId, BASE_MIN_ENERGY_FOR_EVOLUTION);
        }

        // Consume energy
        entity.storedEnergy = Math.max(0, entity.storedEnergy - BASE_MIN_ENERGY_FOR_EVOLUTION);
        entity.lastEnergyUpdateTime = block.timestamp; // Update timestamp after consuming energy

        // Perform probabilistic evolution logic
        // Note: Blockhash is NOT secure for randomness. Use Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, tokenId))) % 10000;

        uint256 outcome = 0; // 0=Failure, 1=Success
        uint256 oldLevel = entity.level;

        outcome = _performEvolutionLogic(tokenId, entity, randomNumber);

        emit EntityEvolved(tokenId, _msgSender(), outcome, entity.level);
    }

    /// @notice Calculates and updates an entity's stored energy based on elapsed time.
    /// This is primarily a helper function called internally, but exposing it allows users to trigger updates.
    /// @param tokenId The ID of the entity.
    function rechargeEnergy(uint256 tokenId) public whenNotPausedAndOwner(tokenId) {
        EntityAttributes storage entity = _entityAttributes[tokenId]; // Use storage reference
        uint256 calculatedEnergy = _calculateCurrentEnergy(tokenId); // This recalculates based on time

        // Update the stored energy based on the calculation
        entity.storedEnergy = calculatedEnergy;
        entity.lastEnergyUpdateTime = block.timestamp; // Update timestamp to "now" after calculating time-based regen

        emit EntityEnergyRecharged(tokenId, entity.storedEnergy);
    }

    /// @notice Burns (destroys) an entity. Inherited from ERC721Burnable.
    /// Included in summary for clarity, but uses inherited function.
    /// @param tokenId The ID of the entity to burn.
    // function burn(uint256 tokenId) public override(ERC721, ERC721Burnable) whenNotPausedAndOwner(tokenId) {
    //     _burn(tokenId); // Call the internal burn function
    //     // Clean up attributes mapping? Optional, but saves space for burned tokens
    //     // delete _entityAttributes[tokenId]; // Uncomment if desired
    //     emit EntityBurned(tokenId, _msgSender());
    // }
    // Overridden burn handles the checks already, just need to ensure Pausable check
    function burn(uint256 tokenId) public override whenNotPausedAndOwner(tokenId) {
        super.burn(tokenId);
         // Clean up attributes mapping? Optional, but saves space for burned tokens
         // delete _entityAttributes[tokenId]; // Uncomment if desired
         emit EntityBurned(tokenId, _msgSender());
    }


    // --- 9. Getter Functions ---

    function getEntityAttributes(uint256 tokenId) public view entityExists(tokenId) returns (EntityAttributes memory) {
        EntityAttributes storage entity = _entityAttributes[tokenId];
         // Need to calculate current energy for the returned struct
        EntityAttributes memory currentAttributes = entity; // Copy to memory
        currentAttributes.energy = _calculateCurrentEnergy(tokenId); // Overwrite with calculated energy
        return currentAttributes;
    }

    function getEntityLevel(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        return _entityAttributes[tokenId].level;
    }

    function getEntityEnergy(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        // Return the calculated current energy
        return _calculateCurrentEnergy(tokenId);
    }

    function getEntityStability(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        return _entityAttributes[tokenId].stability;
    }

     function getEntityType(uint256 tokenId) public view entityExists(tokenId) returns (EntityType) {
        return EntityType(_entityAttributes[tokenId].entityType);
    }

    function getTotalEntitiesMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Getters for config variables are implicitly public if not marked private
    // Example: `fusionFee` public state variable automatically gets a getter `fusionFee()`

    // Added explicit getters for consistency/completeness based on summary
    function getFusionFee() public view returns (uint256) { return fusionFee; }
    function getEvolutionFee() public view returns (uint256) { return evolutionFee; }
    function getMinFusionLevelForFusion() public view returns (uint256) { return minFusionLevelForFusion; }
    function getFusionSuccessRate() public view returns (uint256) { return fusionSuccessRate; }
    function getEvolutionSuccessRate() public view returns (uint256) { return evolutionSuccessRate; }
    function getTimePerEnergyRegen() public view returns (uint256) { return timePerEnergyRegen; }


    // --- 10. Admin & Configuration Functions ---

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    function setFusionFee(uint256 fee) public onlyOwner {
        fusionFee = fee;
        emit FusionFeeUpdated(fee);
    }

    function setEvolutionFee(uint256 fee) public onlyOwner {
        evolutionFee = fee;
        emit EvolutionFeeUpdated(fee);
    }

    function setMinFusionLevelForFusion(uint256 minLevel) public onlyOwner {
        minFusionLevelForFusion = minLevel;
        emit MinFusionLevelUpdated(minLevel);
    }

    /// @notice Sets the base fusion success rate. Rate is 0-10000 (0% to 100%).
    function setFusionSuccessRate(uint256 rate) public onlyOwner {
        if (rate > 10000) revert InvalidRate(rate);
        fusionSuccessRate = rate;
        emit FusionSuccessRateUpdated(rate);
    }

     /// @notice Sets the base evolution success rate. Rate is 0-10000 (0% to 100%).
    function setEvolutionSuccessRate(uint256 rate) public onlyOwner {
        if (rate > 10000) revert InvalidRate(rate);
        evolutionSuccessRate = rate;
        emit EvolutionSuccessRateUpdated(rate);
    }

    /// @notice Sets the time period for energy regeneration.
    /// @param timeInSeconds The duration in seconds.
    function setTimePerEnergyRegen(uint256 timeInSeconds, uint256 regenAmount) public onlyOwner {
        timePerEnergyRegen = timeInSeconds;
        energyRegenAmount = regenAmount;
        emit TimePerEnergyRegenUpdated(timeInSeconds);
        // Potentially add event for energyRegenAmount updated too
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // `paused()` getter is inherited from Pausable.

    function withdrawFees() public onlyOwner {
        // Send the balance of the contract to the owner
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Fee withdrawal failed");
    }

    // Ownership functions `transferOwnership` and `renounceOwnership` are inherited from Ownable.

    // --- 11. Internal Helper Functions ---

    /// @dev Calculates the current energy level of an entity based on time elapsed.
    function _calculateCurrentEnergy(uint256 tokenId) internal view entityExists(tokenId) returns (uint256) {
        EntityAttributes storage entity = _entityAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - entity.lastEnergyUpdateTime;
        uint256 regeneratedEnergy = (timeElapsed / timePerEnergyRegen) * energyRegenAmount;

        // Energy cannot exceed MAX_ENERGY
        return Math.min(entity.storedEnergy + regeneratedEnergy, MAX_ENERGY);
    }

     /// @dev Internal function to generate initial random-ish attributes for a new entity.
     /// Uses block data for simple randomness (not secure for high value outcomes).
     function _generateRandomAttributes(uint256 initialType) internal view returns (EntityAttributes memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, _tokenIdCounter.current())));

        // Simple attribute generation based on seed and type
        uint256 level = 1 + (seed % 5); // Level 1-5 initially
        uint256 energy = MAX_ENERGY / 2 + (seed % (MAX_ENERGY / 2)); // Start with some energy
        uint256 stability = 50 + (seed % 50); // Stability 50-100 initially

        return EntityAttributes({
            entityType: initialType,
            level: level,
            energy: energy, // This is the initial calculated energy
            stability: stability,
            fusionCount: 0,
            evolutionCount: 0,
            lastEnergyUpdateTime: block.timestamp, // Set initial update time
            storedEnergy: energy // Store the calculated initial energy
        });
    }

    /// @dev Internal logic for determining fusion outcome.
    /// Uses simple blockhash randomness (INSECURE for high value).
    function _performFusionLogic(
        uint256 tokenId1,
        EntityAttributes memory entity1,
        uint256 tokenId2,
        EntityAttributes memory entity2,
        uint256 randomNumber // Pass randomness in
    ) internal returns (uint256 outcome, uint256 resultTokenId) {
        // Calculate effective success chance (e.g., based on base rate and average stability)
        uint256 averageStability = (entity1.stability + entity2.stability) / 2;
        // Simple example: stability adds a bonus chance, capped at 100%
        uint256 effectiveSuccessRate = Math.min(10000, fusionSuccessRate + (averageStability * 100 / MAX_STABILITY)); // Adds up to 10000 (100%) bonus chance based on stability

        if (randomNumber < effectiveSuccessRate) {
            // Fusion Success!
            outcome = 1; // Success
            resultTokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            // Generate attributes for the new entity
            // Simple example: average level, average stability, full energy, increment counts
            EntityAttributes memory newAttributes;
            newAttributes.entityType = (entity1.entityType + entity2.entityType) / 2; // Example: Average type index, could be more complex
            newAttributes.level = ((entity1.level + entity2.level) / 2) + 1; // Level up on success
            newAttributes.energy = MAX_ENERGY; // New entity starts with full energy
            newAttributes.stability = (entity1.stability + entity2.stability) / 2; // Average stability
            newAttributes.fusionCount = entity1.fusionCount + entity2.fusionCount + 1; // Sum counts + 1 for this new entity being a result? Or just track inputs? Let's track inputs.
            newAttributes.evolutionCount = entity1.evolutionCount + entity2.evolutionCount; // Sum evolution counts
            newAttributes.lastEnergyUpdateTime = block.timestamp;
             newAttributes.storedEnergy = MAX_ENERGY; // Store max energy

            _entityAttributes[resultTokenId] = newAttributes;
            _safeMint(_msgSender(), resultTokenId); // Mint the new entity to the caller

        } else if (randomNumber < effectiveSuccessRate + (10000 - effectiveSuccessRate) / 2) { // 50% chance of failure vs partial success from the remaining chance
             // Fusion Failure
             outcome = 0; // Failure
             resultTokenId = 0; // No new token
             // Inputs were already burned
             // Could add negative effects on other entities owned by the user here
        }
        else {
             // Fusion Partial Success (Example: Creates a lower-level entity or different type)
             outcome = 2; // Partial
             resultTokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

             EntityAttributes memory newAttributes;
            newAttributes.entityType = randomNumber % uint256(type(EntityType).max); // Random type
            newAttributes.level = Math.max(1, ((entity1.level + entity2.level) / 4)); // Lower level
            newAttributes.energy = MAX_ENERGY / 4; // Lower energy
            newAttributes.stability = Math.max(10, (entity1.stability + entity2.stability) / 4); // Lower stability
            newAttributes.fusionCount = 0; // Reset counts for partial success?
            newAttributes.evolutionCount = 0;
            newAttributes.lastEnergyUpdateTime = block.timestamp;
             newAttributes.storedEnergy = MAX_ENERGY / 4;

            _entityAttributes[resultTokenId] = newAttributes;
            _safeMint(_msgSender(), resultTokenId); // Mint the new entity to the caller

        }

        return (outcome, resultTokenId);
    }

     /// @dev Internal logic for determining evolution outcome.
     /// Uses simple blockhash randomness (INSECURE for high value).
    function _performEvolutionLogic(
        uint256 tokenId,
        EntityAttributes storage entity, // Use storage reference to modify directly
        uint256 randomNumber // Pass randomness in
    ) internal returns (uint256 outcome) {
        // Calculate effective success chance (e.g., based on base rate and entity stability)
        uint256 effectiveSuccessRate = Math.min(10000, evolutionSuccessRate + (entity.stability * 100 / MAX_STABILITY)); // Adds up to 10000 (100%) bonus chance

        if (randomNumber < effectiveSuccessRate) {
            // Evolution Success!
            outcome = 1; // Success
            entity.level++; // Increase level
            entity.evolutionCount++; // Increment evolution count
            // Slightly boost or randomize other stats?
            uint256 statBoost = randomNumber % 10; // Small random boost
            entity.stability = Math.min(MAX_STABILITY, entity.stability + statBoost);
            // Energy was already consumed

        } else {
            // Evolution Failure
            outcome = 0; // Failure
            // Reduce stability on failure?
            entity.stability = Math.max(10, entity.stability - 5); // Reduce stability, but not below 10
            // Energy was already consumed
            // Level does not increase
        }
        return outcome;
    }

    // The ERC721 standard functions `_safeMint`, `_burn`, `_beforeTokenTransfer`, `_afterTokenTransfer`
    // are handled by the inherited OpenZeppelin contracts.

}
```