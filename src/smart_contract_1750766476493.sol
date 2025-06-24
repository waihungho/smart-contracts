Okay, let's design a smart contract that creates unique, evolving digital entities. We'll call them "Essences". These Essences will be ERC-721 tokens, but with dynamic traits that change over time based on user interaction (nurturing with a specific "fuel" token) and potential random events (mutation, fusion, replication).

This concept incorporates:
*   **ERC-721 Standard:** Core non-fungible tokens.
*   **Dynamic Traits:** Traits stored on-chain that change.
*   **Time-Based Mechanics:** Decay and growth influenced by block timestamps.
*   **Resource Management:** Bonding/spending an ERC-20 token (`EssenceFuel`) to influence the entity.
*   **Algorithmic Evolution:** Mutation, fusion, and replication processes with on-chain logic.
*   **On-chain Randomness (Pseudo):** Using block data for demonstration, with a note on recommending Chainlink VRF for production.
*   **Scarcity:** Maximum supply limit.
*   **Ownership & Access Control:** Using Ownable.

This combines elements often seen separately in generative art, virtual pets/ Tamagotchis, and DeFi staking mechanics, aiming for a relatively novel blend within a single contract.

---

**Smart Contract: DigitalEssence**

**Outline:**

1.  **License & Version:** SPDX License Identifier and Pragma.
2.  **Imports:** ERC721, Ownable, IERC20.
3.  **Error Definitions:** Custom errors for better error handling.
4.  **Events:** Log important actions.
5.  **Interfaces:** IERC20 for the fuel token.
6.  **Structs:** Define the `Essence` struct holding its state.
7.  **State Variables:**
    *   ERC721 internal state.
    *   Mapping from tokenId to Essence struct.
    *   Configuration parameters (decay rates, costs, bounds).
    *   Token counters and supply limits.
    *   Address of the EssenceFuel token contract.
    *   Pseudo-random seed.
    *   Owner address.
8.  **Constructor:** Initialize the contract with basic settings.
9.  **Modifiers:** Custom modifiers for access control and state checks.
10. **Internal Helper Functions:**
    *   Generating pseudo-randomness.
    *   Applying trait bounds.
    *   Calculating current traits based on time and fuel.
    *   Checking essence liveness.
11. **ERC-721 Standard Functions (Overridden/Implemented):**
    *   `balanceOf`
    *   `ownerOf`
    *   `safeTransferFrom` (overloaded)
    *   `transferFrom`
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
    *   `_safeMint` (internal override)
    *   `_burn` (internal override)
12. **Public/External Functions:**
    *   **Minting:**
        *   `spawnEssence`: Create a new Essence (requires fuel, respects supply).
    *   **Essence State & Getters:**
        *   `getEssenceDetails`: Get all current calculated traits and state.
        *   `getEssenceRawData`: Get the stored raw data.
        *   `calculateCurrentTraits`: Helper to just calculate traits for a given token.
        *   `isEssenceAlive`: Check if an essence is currently alive.
        *   `getEssenceFuelBonded`: Get the amount of fuel currently bonded.
    *   **Core Mechanics:**
        *   `nurtureEssence`: Bond fuel to an essence to prevent decay/encourage growth.
        *   `unbondFuel`: Withdraw bonded fuel (potentially with cost).
        *   `mutateEssence`: Attempt to randomly change traits (requires fuel).
        *   `fuseEssences`: Combine two essences into a new one (burns originals, requires fuel).
        *   `replicateEssence`: Create a new essence from a single parent (requires high traits, fuel, respects supply).
    *   **Information:**
        *   `getCurrentSupply`: Get the number of Essences minted.
        *   `getMaxSupply`: Get the maximum allowed supply.
        *   `getEssenceFuelAddress`: Get the address of the fuel token contract.
        *   `getConfig`: Get current configuration parameters.
    *   **Configuration (Owner Only):**
        *   `setMaxSupply`: Set the maximum supply limit.
        *   `setEssenceFuelAddress`: Set the address of the fuel token.
        *   `setDecayRate`: Set the rate at which traits decay over time.
        *   `setGrowthRate`: Set the rate at which traits grow when nurtured.
        *   `setNurtureThreshold`: Set the fuel amount needed to trigger growth instead of decay.
        *   `setMutationCost`: Set the fuel cost for mutation.
        *   `setFusionCost`: Set the fuel cost for fusion.
        *   `setReplicationCost`: Set the fuel cost for replication.
        *   `setTraitBounds`: Set the min/max values for traits.
        *   `setLivenessThreshold`: Set the minimum trait sum needed for liveness.
    *   **Ownership:**
        *   `transferOwnership`: Transfer contract ownership.

**Function Summary (27 Functions):**

*   `balanceOf(address owner) public view returns (uint256)`: Returns the number of tokens owned by `owner`. (ERC721)
*   `ownerOf(uint256 tokenId) public view returns (address)`: Returns the owner of the `tokenId` token. (ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId) public payable`: Safely transfers `tokenId` token from `from` to `to`. (ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public payable`: Safely transfers `tokenId` token from `from` to `to`, with data. (ERC721)
*   `transferFrom(address from, address to, uint256 tokenId) public payable`: Transfers `tokenId` token from `from` to `to`. (ERC721)
*   `approve(address to, uint256 tokenId) public`: Gives permission to `to` to transfer `tokenId` token. (ERC721)
*   `setApprovalForAll(address operator, bool approved) public`: Gives or removes permission to `operator` to manage all tokens of the caller. (ERC721)
*   `getApproved(uint256 tokenId) public view returns (address)`: Returns the account approved for `tokenId` token. (ERC721)
*   `isApprovedForAll(address owner, address operator) public view returns (bool)`: Returns if `operator` is approved to manage all of `owner`'s tokens. (ERC721)
*   `spawnEssence(address owner_) public`: Mints a new Essence token to `owner_`, requiring `spawnCost` fuel and checks supply limits. (Minting)
*   `getEssenceDetails(uint256 tokenId) public view returns (Essence memory currentDetails)`: Returns the calculated current traits and state (including liveness) for `tokenId`. (Essence State & Getters)
*   `getEssenceRawData(uint256 tokenId) public view returns (Essence storageData)`: Returns the raw stored data for `tokenId` *without* calculating decay/growth. (Essence State & Getters)
*   `calculateCurrentTraits(uint256 tokenId) public view returns (uint256 traitA, uint256 traitB, uint256 traitC, uint256 traitD)`: Calculates and returns the current traits of an essence based on time and bonded fuel. (Essence State & Getters)
*   `isEssenceAlive(uint256 tokenId) public view returns (bool)`: Returns true if the essence's traits meet the liveness threshold. (Essence State & Getters)
*   `getEssenceFuelBonded(uint256 tokenId) public view returns (uint256)`: Returns the amount of EssenceFuel bonded to `tokenId`. (Essence State & Getters)
*   `nurtureEssence(uint256 tokenId, uint256 amount) public`: Bonds `amount` of EssenceFuel to `tokenId`, updating its last nurtured time. (Core Mechanics)
*   `unbondFuel(uint256 tokenId, uint256 amount) public`: Unbonds `amount` of EssenceFuel from `tokenId` and transfers it back to the owner. (Core Mechanics)
*   `mutateEssence(uint256 tokenId) public`: Attempts to randomly mutate the traits of `tokenId`, costing `mutationCost` fuel. (Core Mechanics)
*   `fuseEssences(uint256 tokenId1, uint256 tokenId2) public`: Fuses `tokenId1` and `tokenId2` into a new essence, burning the originals and costing `fusionCost` fuel. (Core Mechanics)
*   `replicateEssence(uint256 tokenId) public`: Attempts to replicate `tokenId` into a new essence, requiring high traits, costing `replicateCost` fuel, and respecting supply limits. (Core Mechanics)
*   `getCurrentSupply() public view returns (uint256)`: Returns the total number of Essences minted. (Information)
*   `getMaxSupply() public view returns (uint256)`: Returns the maximum allowed supply of Essences. (Information)
*   `getEssenceFuelAddress() public view returns (address)`: Returns the address of the EssenceFuel ERC-20 token. (Information)
*   `getConfig() public view returns (uint256 decayRate, uint256 growthRate, uint256 nurtureThreshold, uint256 mutationCost, uint256 fusionCost, uint256 replicationCost, uint256 minTraitValue, uint256 maxTraitValue, uint256 livenessThreshold, uint256 spawnCost)`: Returns all current configuration parameters. (Information)
*   `setMaxSupply(uint256 _maxSupply) public onlyOwner`: Sets the maximum supply of Essences. (Configuration)
*   `setEssenceFuelAddress(address _essenceFuelAddress) public onlyOwner`: Sets the address of the EssenceFuel token contract. (Configuration)
*   `setDecayGrowthRates(uint256 _decayRate, uint256 _growthRate) public onlyOwner`: Sets the decay and growth rates for traits. (Configuration)
*   `setNurtureThreshold(uint256 _nurtureThreshold) public onlyOwner`: Sets the fuel amount threshold for growth vs decay. (Configuration)
*   `setInteractionCosts(uint256 _mutationCost, uint256 _fusionCost, uint256 _replicationCost, uint256 _spawnCost) public onlyOwner`: Sets the fuel costs for core interactions. (Configuration)
*   `setTraitBounds(uint256 _minTraitValue, uint256 _maxTraitValue) public onlyOwner`: Sets the minimum and maximum possible values for traits. (Configuration)
*   `setLivenessThreshold(uint256 _livenessThreshold) public onlyOwner`: Sets the minimum sum of traits required for an essence to be considered "alive". (Configuration)
*   `transferOwnership(address newOwner) public override onlyOwner`: Transfers ownership of the contract. (Ownership)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice if adding complex external calls later

// Outline:
// 1. License & Version
// 2. Imports
// 3. Error Definitions
// 4. Events
// 5. Interfaces
// 6. Structs
// 7. State Variables
// 8. Constructor
// 9. Modifiers
// 10. Internal Helper Functions
// 11. ERC-721 Standard Functions (Overridden)
// 12. Public/External Functions (Minting, Getters, Mechanics, Info, Config, Ownership)

// Function Summary: (Total 27 functions)
// ERC-721 Standard (8 functions): balanceOf, ownerOf, safeTransferFrom(x2), transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll
// Minting (1 function): spawnEssence
// Essence State & Getters (5 functions): getEssenceDetails, getEssenceRawData, calculateCurrentTraits, isEssenceAlive, getEssenceFuelBonded
// Core Mechanics (5 functions): nurtureEssence, unbondFuel, mutateEssence, fuseEssences, replicateEssence
// Information (4 functions): getCurrentSupply, getMaxSupply, getEssenceFuelAddress, getConfig
// Configuration (7 functions): setMaxSupply, setEssenceFuelAddress, setDecayGrowthRates, setNurtureThreshold, setInteractionCosts, setTraitBounds, setLivenessThreshold
// Ownership (1 function): transferOwnership

contract DigitalEssence is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Error Definitions ---
    error DigitalEssence__InvalidTokenId();
    error DigitalEssence__MaxSupplyReached();
    error DigitalEssence__InsufficientFuel();
    error DigitalEssence__ApprovalOrOwnershipRequired();
    error DigitalEssence__EssenceNotAlive();
    error DigitalEssence__FusionRequiresTwoDifferentEssences();
    error DigitalEssence__ReplicationConditionsNotMet();
    error DigitalEssence__InvalidAmount();
    error DigitalEssence__TraitBoundsInvalid();
    error DigitalEssence__EssenceFuelAddressNotSet();
    error DigitalEssence__SupplyLimitMustBeAboveCurrentSupply();

    // --- Events ---
    event EssenceSpawned(uint256 indexed tokenId, address indexed owner, uint256 creationTime);
    event EssenceNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 amountBonded, uint256 newFuelBonded);
    event FuelUnbonded(uint256 indexed tokenId, address indexed recipient, uint256 amountUnbonded, uint256 newFuelBonded);
    event EssenceMutated(uint256 indexed tokenId, uint256 newTraitA, uint256 newTraitB, uint256 newTraitC, uint256 newTraitD);
    event EssencesFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId, uint256 newTraitA, uint256 newTraitB, uint256 newTraitC, uint256 newTraitD);
    event EssenceReplicated(uint256 indexed parentTokenId, uint256 indexed newTokenId, uint256 newTraitA, uint256 newTraitB, uint256 newTraitC, uint256 newTraitD);
    event EssenceDeceased(uint256 indexed tokenId, uint256 timeOfDeath);
    event ConfigUpdated();

    // --- Structs ---
    struct Essence {
        uint256 creationTime;
        uint256 lastNurtureTime; // Or last interaction time affecting state
        uint256 fuelBonded;
        // Core Traits (Representing different attributes)
        uint256 traitA; // e.g., Strength, Energy
        uint256 traitB; // e.g., Resilience, Stamina
        uint256 traitC; // e.g., Intelligence, Adaptability
        uint256 traitD; // e.g., Rarity, Potential
        // Could add more traits or different data types
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => Essence) private _essences;
    address private s_essenceFuelAddress;

    uint256 private s_maxSupply;

    // Configuration Parameters (Scaled by 100 for precision, e.g., 500 = 5.00)
    uint256 private s_decayRatePerSecond; // Rate at which traits decay per second without nurture
    uint256 private s_growthRatePerSecond; // Rate at which traits grow per second with sufficient nurture
    uint256 private s_nurtureThreshold; // Amount of fuel bonded to trigger growth instead of decay
    uint256 private s_mutationCost; // Fuel cost to mutate
    uint256 private s_fusionCost; // Fuel cost to fuse
    uint256 private s_replicationCost; // Fuel cost to replicate
    uint256 private s_spawnCost; // Fuel cost to spawn initially

    uint256 private s_minTraitValue; // Minimum possible value for any trait
    uint256 private s_maxTraitValue; // Maximum possible value for any trait
    uint256 private s_livenessThreshold; // Minimum sum of traits for an essence to be considered alive (e.g., sum of traitA+B+C+D)

    uint256 private s_lastRandomSeed; // Simple pseudo-random seed for on-chain demo

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        address essenceFuelAddress_,
        uint256 decayRatePerSecond_,
        uint256 growthRatePerSecond_,
        uint256 nurtureThreshold_,
        uint256 mutationCost_,
        uint256 fusionCost_,
        uint256 replicationCost_,
        uint256 spawnCost_,
        uint256 minTraitValue_,
        uint256 maxTraitValue_,
        uint256 livenessThreshold_
    ) ERC721(name, symbol) Ownable(msg.sender) {
        require(maxSupply_ > 0, "Max supply must be greater than 0");
        require(essenceFuelAddress_ != address(0), "Essence fuel address cannot be zero");
        require(minTraitValue_ < maxTraitValue_, "Min trait must be less than max");
        require(livenessThreshold_ >= minTraitValue_ * 4, "Liveness threshold seems too low"); // Sanity check
        require(livenessThreshold_ <= maxTraitValue_ * 4, "Liveness threshold seems too high"); // Sanity check


        s_maxSupply = maxSupply_;
        s_essenceFuelAddress = essenceFuelAddress_;

        s_decayRatePerSecond = decayRatePerSecond_;
        s_growthRatePerSecond = growthRatePerSecond_;
        s_nurtureThreshold = nurtureThreshold_;
        s_mutationCost = mutationCost_;
        s_fusionCost = fusionCost_;
        s_replicationCost = replicationCost_;
        s_spawnCost = spawnCost_;

        s_minTraitValue = minTraitValue_;
        s_maxTraitValue = maxTraitValue_;
        s_livenessThreshold = livenessThreshold_;

        s_lastRandomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))); // Initial seed
    }

    // --- Modifiers ---
    modifier whenEssenceExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert DigitalEssence__InvalidTokenId();
        }
        _;
    }

    modifier whenEssenceExistsAndAlive(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert DigitalEssence__InvalidTokenId();
        }
        if (!isEssenceAlive(tokenId)) { // Calls the public view function which calculates liveness
            revert DigitalEssence__EssenceNotAlive();
        }
        _;
    }

    modifier requiresEssenceFuel() {
        if (s_essenceFuelAddress == address(0)) {
             revert DigitalEssence__EssenceFuelAddressNotSet();
        }
        _;
    }


    // --- Internal Helper Functions ---

    // Simple Pseudo-Random Number Generator (NOT secure for high-value applications)
    // For production, consider Chainlink VRF or similar decentralized oracle.
    function _generateRandomSeed() internal returns (uint256) {
        s_lastRandomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenIdCounter.current(), s_lastRandomSeed)));
        return s_lastRandomSeed;
    }

    function _randomRange(uint256 min, uint256 max) internal returns (uint256) {
        require(max >= min, "Max must be >= min");
        if (min == max) return min;
        return (_generateRandomSeed() % (max - min + 1)) + min;
    }

    function _applyTraitBounds(uint256 value) internal view returns (uint256) {
        return Math.max(s_minTraitValue, Math.min(s_maxTraitValue, value));
    }

    // Helper to calculate current traits considering time and nurture state
    // Does NOT update storage.
    function _calculateCurrentTraits(uint256 tokenId) internal view returns (uint256 traitA, uint256 traitB, uint256 traitC, uint256 traitD) {
        Essence storage essence = _essences[tokenId];
        uint256 timeElapsed = block.timestamp - essence.lastNurtureTime; // Time since last state update

        uint256 decayAmount = timeElapsed.mul(s_decayRatePerSecond); // Calculate potential decay
        uint256 growthAmount = timeElapsed.mul(s_growthRatePerSecond); // Calculate potential growth

        // Determine net change based on nurture threshold
        int256 netChangePerTrait; // Use int256 to handle potential decrease
        if (essence.fuelBonded < s_nurtureThreshold) {
            // Decay phase: Traits decrease
            netChangePerTrait = -int256(decayAmount);
        } else {
            // Growth phase: Traits increase
            netChangePerTrait = int256(growthAmount);
        }

        // Apply change to traits, ensuring they stay within bounds
        traitA = _applyTraitBounds(essence.traitA.toUint256() + netChangePerTrait);
        traitB = _applyTraitBounds(essence.traitB.toUint256() + netChangePerTrait);
        traitC = _applyTraitBounds(essence.traitC.toUint256() + netChangePerTrait);
        traitD = _applyTraitBounds(essence.traitD.toUint256() + netChangePerTrait);
    }

    // Internal function to check liveness based on calculated current traits
    function _isEssenceAlive(uint256 tokenId) internal view returns (bool) {
        (uint256 traitA, uint256 traitB, uint256 traitC, uint256 traitD) = _calculateCurrentTraits(tokenId);
        return (traitA + traitB + traitC + traitD) >= s_livenessThreshold;
    }

    // --- ERC-721 Standard Functions (Overrides) ---
    // We override internal _safeMint and _burn to handle our custom Essence struct
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        // Initial state for the new Essence
        _essences[tokenId] = Essence({
            creationTime: block.timestamp,
            lastNurtureTime: block.timestamp,
            fuelBonded: 0,
            traitA: _randomRange(s_minTraitValue, s_maxTraitValue),
            traitB: _randomRange(s_minTraitValue, s_maxTraitValue),
            traitC: _randomRange(s_minTraitValue, s_maxTraitValue),
            traitD: _randomRange(s_minTraitValue, s_maxTraitValue)
        });
        // Update random seed after using it for trait generation
        _generateRandomSeed();
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
         // Optional: Before burning, check if it's due to decay and emit Deceased event
        if (_exists(tokenId) && !_isEssenceAlive(tokenId)) {
             // We need to temporarily load the struct to check state
             Essence storage essence = _essences[tokenId];
             // Calculate current state without modifying storage to decide on event
             (uint256 currentA, uint256 currentB, uint256 currentC, uint256 currentD) = _calculateCurrentTraits(tokenId);
             if ((currentA + currentB + currentC + currentD) < s_livenessThreshold) {
                 emit EssenceDeceased(tokenId, block.timestamp);
             }
        }
        super._burn(tokenId);
        delete _essences[tokenId]; // Clean up the Essence struct storage
    }

     // Override transfer function hook to potentially check liveness before transfer (optional)
     // This prevents transferring 'dead' essences. Comment out if you want dead essences to be transferable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Check liveness only when transferring an existing token (not during minting or burning to zero)
        if (from != address(0) && to != address(0)) {
            if (!_isEssenceAlive(tokenId)) {
                revert DigitalEssence__EssenceNotAlive();
            }
        }
    }


    // --- Public/External Functions ---

    // --- Minting ---
    /**
     * @notice Spawns a new Digital Essence token. Requires the caller to have approved EssenceFuel.
     * @param owner_ The address that will receive the new Essence token.
     */
    function spawnEssence(address owner_) public payable requiresEssenceFuel nonReentrant {
        if (_tokenIdCounter.current() >= s_maxSupply) {
            revert DigitalEssence__MaxSupplyReached();
        }
        if (s_essenceFuelAddress == address(0)) {
            revert DigitalEssence__EssenceFuelAddressNotSet();
        }

        // Transfer spawn cost from the caller to the contract
        bool success = IERC20(s_essenceFuelAddress).transferFrom(msg.sender, address(this), s_spawnCost);
        if (!success) {
            revert DigitalEssence__InsufficientFuel();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // _safeMint will initialize the Essence struct with random traits within bounds
        _safeMint(owner_, newTokenId);

        emit EssenceSpawned(newTokenId, owner_, block.timestamp);
    }

    // --- Essence State & Getters ---

    /**
     * @notice Gets the current calculated details of an Essence, accounting for time-based decay/growth.
     * @param tokenId The ID of the Essence.
     * @return currentDetails The Essence struct with calculated current traits and liveness status.
     */
    function getEssenceDetails(uint256 tokenId) public view whenEssenceExists(tokenId) returns (Essence memory currentDetails) {
        Essence storage storedData = _essences[tokenId];
        (uint256 currentA, uint256 currentB, uint256 currentC, uint256 currentD) = _calculateCurrentTraits(tokenId);

        currentDetails = storedData; // Copy stored data
        currentDetails.traitA = currentA;
        currentDetails.traitB = currentB;
        currentDetails.traitC = currentC;
        currentDetails.traitD = currentD;
        // Note: isAlive is calculated separately and not part of the stored struct
        // For a more robust return, consider a custom struct or multiple return values
        // Adding a calculated 'isAlive' field to the returned memory struct for convenience:
         uint256 totalTraits = currentA + currentB + currentC + currentD;
         // Simulating adding isAlive to the struct by returning an extra boolean or a dedicated view struct
         // Let's return it as part of a tuple for clarity, or a dedicated view struct
         // For simplicity with the struct return, we'll rely on the separate isEssenceAlive getter or sum the traits.
         // Let's create a dedicated view struct for returning calculated state.
    }

    // --- Dedicated view struct for calculated state ---
    struct CalculatedEssenceState {
         uint256 creationTime;
         uint256 lastNurtureTime;
         uint256 fuelBonded;
         uint256 traitA;
         uint256 traitB;
         uint256 traitC;
         uint256 traitD;
         bool isAlive;
    }

     /**
     * @notice Gets the current calculated details of an Essence, including its liveness status.
     * @param tokenId The ID of the Essence.
     * @return state The calculated state of the Essence.
     */
    function getCalculatedEssenceState(uint256 tokenId) public view whenEssenceExists(tokenId) returns (CalculatedEssenceState memory state) {
        Essence storage storedData = _essences[tokenId];
        (uint256 currentA, uint256 currentB, uint256 currentC, uint256 currentD) = _calculateCurrentTraits(tokenId);
        uint256 totalTraits = currentA + currentB + currentC + currentD;

        state.creationTime = storedData.creationTime;
        state.lastNurtureTime = storedData.lastNurtureTime;
        state.fuelBonded = storedData.fuelBonded;
        state.traitA = currentA;
        state.traitB = currentB;
        state.traitC = currentC;
        state.traitD = currentD;
        state.isAlive = (totalTraits >= s_livenessThreshold);
    }


    /**
     * @notice Gets the raw stored data of an Essence, without calculating time-based decay/growth.
     * @param tokenId The ID of the Essence.
     * @return storageData The raw Essence struct from storage.
     */
    function getEssenceRawData(uint256 tokenId) public view whenEssenceExists(tokenId) returns (Essence storage storageData) {
        return _essences[tokenId];
    }

    /**
     * @notice Calculates and returns the current traits of an Essence based on time and bonded fuel.
     * @param tokenId The ID of the Essence.
     * @return traitA Current calculated traitA.
     * @return traitB Current calculated traitB.
     * @return traitC Current calculated traitC.
     * @return traitD Current calculated traitD.
     */
    function calculateCurrentTraits(uint256 tokenId) public view whenEssenceExists(tokenId) returns (uint256 traitA, uint256 traitB, uint256 traitC, uint256 traitD) {
         return _calculateCurrentTraits(tokenId);
    }

    /**
     * @notice Checks if an Essence is currently considered alive based on its calculated traits.
     * @param tokenId The ID of the Essence.
     * @return bool True if the essence is alive, false otherwise.
     */
    function isEssenceAlive(uint256 tokenId) public view whenEssenceExists(tokenId) returns (bool) {
        return _isEssenceAlive(tokenId);
    }

     /**
      * @notice Gets the amount of EssenceFuel currently bonded to an Essence.
      * @param tokenId The ID of the Essence.
      * @return uint256 The amount of fuel bonded.
      */
    function getEssenceFuelBonded(uint256 tokenId) public view whenEssenceExists(tokenId) returns (uint256) {
        return _essences[tokenId].fuelBonded;
    }


    // --- Core Mechanics ---

    /**
     * @notice Bonds EssenceFuel to an Essence, influencing its time-based evolution. Requires approval.
     * @param tokenId The ID of the Essence to nurture.
     * @param amount The amount of EssenceFuel to bond.
     */
    function nurtureEssence(uint256 tokenId, uint256 amount) public nonReentrant requiresEssenceFuel whenEssenceExistsAndAlive(tokenId) {
        if (amount == 0) revert DigitalEssence__InvalidAmount();

        // Check ownership or approval for interaction
        address essenceOwner = ownerOf(tokenId);
        if (msg.sender != essenceOwner && !isApprovedForAll(essenceOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert DigitalEssence__ApprovalOrOwnershipRequired();
        }

        // Transfer fuel from nurturer to contract
        bool success = IERC20(s_essenceFuelAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert DigitalEssence__InsufficientFuel();
        }

        // Update essence state
        _essences[tokenId].fuelBonded = _essences[tokenId].fuelBonded.add(amount);
        _essences[tokenId].lastNurtureTime = block.timestamp; // Reset time for decay/growth calculation

        emit EssenceNurtured(tokenId, msg.sender, amount, _essences[tokenId].fuelBonded);
    }

    /**
     * @notice Unbonds EssenceFuel from an Essence and transfers it back to the owner.
     * @param tokenId The ID of the Essence.
     * @param amount The amount of EssenceFuel to unbond.
     */
    function unbondFuel(uint256 tokenId, uint256 amount) public nonReentrant requiresEssenceFuel whenEssenceExists(tokenId) { // Can unbond from dead essence
        if (amount == 0) revert DigitalEssence__InvalidAmount();

        address essenceOwner = ownerOf(tokenId);
        // Only owner can unbond fuel
        if (msg.sender != essenceOwner) {
            revert DigitalEssence__ApprovalOrOwnershipRequired(); // Or create a specific unbond error
        }

        Essence storage essence = _essences[tokenId];
        if (essence.fuelBonded < amount) {
            revert DigitalEssence__InsufficientFuel(); // Not enough bonded fuel
        }

        // Update essence state
        essence.fuelBonded = essence.fuelBonded.sub(amount);
        essence.lastNurtureTime = block.timestamp; // Reset time after state change

        // Transfer fuel back to owner
        bool success = IERC20(s_essenceFuelAddress).transfer(essenceOwner, amount);
        if (!success) {
            // This is problematic - fuel is removed from essence but not transferred.
            // A more robust system might use pull patterns or handle this error explicitly.
            // For this example, we'll revert.
            revert DigitalEssence__InsufficientFuel(); // Should not happen if balance > amount
        }

        emit FuelUnbonded(tokenId, essenceOwner, amount, essence.fuelBonded);
    }

    /**
     * @notice Attempts to randomly mutate the traits of an Essence. Costs fuel. Requires approval.
     * @param tokenId The ID of the Essence to mutate.
     */
    function mutateEssence(uint256 tokenId) public nonReentrant requiresEssenceFuel whenEssenceExistsAndAlive(tokenId) {
         // Check ownership or approval for interaction
        address essenceOwner = ownerOf(tokenId);
        if (msg.sender != essenceOwner && !isApprovedForAll(essenceOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert DigitalEssence__ApprovalOrOwnershipRequired();
        }

        // Transfer mutation cost
        bool success = IERC20(s_essenceFuelAddress).transferFrom(msg.sender, address(this), s_mutationCost);
         if (!success) {
            revert DigitalEssence__InsufficientFuel();
        }

        // Apply mutation: Randomly change traits within a range
        // Get current traits first
        (uint256 currentA, uint256 currentB, uint256 currentC, uint256 currentD) = _calculateCurrentTraits(tokenId);

        // Simple mutation logic: add/subtract a random value from each trait
        int256 mutationAmountA = int256(_randomRange(0, s_maxTraitValue / 10)).mul(_randomRange(0, 1) == 0 ? 1 : -1);
        int256 mutationAmountB = int256(_randomRange(0, s_maxTraitValue / 10)).mul(_randomRange(0, 1) == 0 ? 1 : -1);
        int256 mutationAmountC = int256(_randomRange(0, s_maxTraitValue / 10)).mul(_randomRange(0, 1) == 0 ? 1 : -1);
        int256 mutationAmountD = int256(_randomRange(0, s_maxTraitValue / 10)).mul(_randomRange(0, 1) == 0 ? 1 : -1);

        Essence storage essence = _essences[tokenId];
        essence.traitA = _applyTraitBounds(currentA.toUint256() + mutationAmountA);
        essence.traitB = _applyTraitBounds(currentB.toUint256() + mutationAmountB);
        essence.traitC = _applyTraitBounds(currentC.toUint256() + mutationAmountC);
        essence.traitD = _applyTraitBounds(currentD.toUint256() + mutationAmountD);
        essence.lastNurtureTime = block.timestamp; // Reset time after state change

        // Update random seed after use
        _generateRandomSeed();

        // Re-check liveness after mutation (optional, could let it die if traits drop)
        // If you want mutation to potentially kill the essence, remove this check:
        // if (!_isEssenceAlive(tokenId)) { ... handle death ... }

        emit EssenceMutated(tokenId, essence.traitA, essence.traitB, essence.traitC, essence.traitD);
    }

    /**
     * @notice Fuses two Essences into a single new one. Burns the two originals. Costs fuel. Requires approval for both.
     * @param tokenId1 The ID of the first Essence.
     * @param tokenId2 The ID of the second Essence.
     */
    function fuseEssences(uint256 tokenId1, uint256 tokenId2) public nonReentrant requiresEssenceFuel whenEssenceExistsAndAlive(tokenId1) whenEssenceExistsAndAlive(tokenId2) {
        if (tokenId1 == tokenId2) revert DigitalEssence__FusionRequiresTwoDifferentEssences();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Both must be owned by msg.sender OR msg.sender must be approved for both
        bool senderIsOwner1 = msg.sender == owner1;
        bool senderIsOwner2 = msg.sender == owner2;
        bool senderIsApproved1 = isApprovedForAll(owner1, msg.sender) || getApproved(tokenId1) == msg.sender;
        bool senderIsApproved2 = isApprovedForAll(owner2, msg.sender) || getApproved(tokenId2) == msg.sender;

        if (!( (senderIsOwner1 || senderIsApproved1) && (senderIsOwner2 || senderIsApproved2) )) {
            revert DigitalEssence__ApprovalOrOwnershipRequired();
        }

        // Transfer fusion cost from the caller
        bool success = IERC20(s_essenceFuelAddress).transferFrom(msg.sender, address(this), s_fusionCost);
         if (!success) {
            revert DigitalEssence__InsufficientFuel();
        }

        if (_tokenIdCounter.current() >= s_maxSupply) {
            revert DigitalEssence__MaxSupplyReached(); // Fusion also counts towards supply limit
        }

        // Burn the two parent essences
        _burn(tokenId1);
        _burn(tokenId2);

        // Create a new essence
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        address newEssenceOwner = msg.sender; // The owner of the new essence is the one who initiated fusion

        // Determine traits for the new essence
        // Get calculated traits before burning (data is still in storage)
        (uint256 traits1A, uint256 traits1B, uint256 traits1C, uint256 traits1D) = _calculateCurrentTraits(tokenId1);
        (uint256 traits2A, uint256 traits2B, uint256 traits2C, uint256 traits2D) = _calculateCurrentTraits(tokenId2);

        // Fusion logic: Simple average + a small random variation
        uint256 newTraitA = _applyTraitBounds(traits1A.add(traits2A).div(2).add(_randomRange(0, s_maxTraitValue / 20)).sub(_randomRange(0, s_maxTraitValue / 20)));
        uint256 newTraitB = _applyTraitBounds(traits1B.add(traits2B).div(2).add(_randomRange(0, s_maxTraitValue / 20)).sub(_randomRange(0, s_maxTraitValue / 20)));
        uint256 newTraitC = _applyTraitBounds(traits1C.add(traits2C).div(2).add(_randomRange(0, s_maxTraitValue / 20)).sub(_randomRange(0, s_maxTraitValue / 20)));
        uint256 newTraitD = _applyTraitBounds(traits1D.add(traits2D).div(2).add(_randomRange(0, s_maxTraitValue / 20)).sub(_randomRange(0, s_maxTraitValue / 20)));


        // Mint the new token and set its traits directly (bypassing _safeMint's random init)
        super._safeMint(newEssenceOwner, newTokenId);
        _essences[newTokenId].traitA = newTraitA;
        _essences[newTokenId].traitB = newTraitB;
        _essences[newTokenId].traitC = newTraitC;
        _essences[newTokenId].traitD = newTraitD;
        _essences[newTokenId].creationTime = block.timestamp;
        _essences[newTokenId].lastNurtureTime = block.timestamp;
        _essences[newTokenId].fuelBonded = 0; // New essence starts fresh

        // Update random seed
        _generateRandomSeed();


        emit EssencesFused(tokenId1, tokenId2, newTokenId, newTraitA, newTraitB, newTraitC, newTraitD);
    }

     /**
     * @notice Attempts to replicate an Essence into a new one. Requires high traits and costs fuel. Requires approval.
     * @param tokenId The ID of the Essence to replicate.
     */
    function replicateEssence(uint256 tokenId) public nonReentrant requiresEssenceFuel whenEssenceExistsAndAlive(tokenId) {
         // Check ownership or approval for interaction
        address essenceOwner = ownerOf(tokenId);
        if (msg.sender != essenceOwner && !isApprovedForAll(essenceOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert DigitalEssence__ApprovalOrOwnershipRequired();
        }

        // Check if replication conditions are met (e.g., sum of traits must be very high)
        (uint256 currentA, uint256 currentB, uint256 currentC, uint256 currentD) = _calculateCurrentTraits(tokenId);
        uint256 totalTraits = currentA + currentB + currentC + currentD;

        // Define a replication threshold (example: 90% of max possible total traits)
        uint256 replicationThreshold = s_maxTraitValue.mul(4).mul(90).div(100); // 4 traits * max value * 90%
        if (totalTraits < replicationThreshold) {
            revert DigitalEssence__ReplicationConditionsNotMet();
        }

        // Check supply limit BEFORE transferring fuel
        if (_tokenIdCounter.current() >= s_maxSupply) {
            revert DigitalEssence__MaxSupplyReached();
        }

        // Transfer replication cost
        bool success = IERC20(s_essenceFuelAddress).transferFrom(msg.sender, address(this), s_replicationCost);
         if (!success) {
            revert DigitalEssence__InsufficientFuel();
        }

        // Create a new essence
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        address newEssenceOwner = msg.sender; // The owner of the new essence is the one who initiated replication

        // Determine traits for the new essence (e.g., based on parent traits with slight variation)
        uint256 newTraitA = _applyTraitBounds(currentA.mul(90).div(100).add(_randomRange(0, s_maxTraitValue / 15)).sub(_randomRange(0, s_maxTraitValue / 15)));
        uint256 newTraitB = _applyTraitBounds(currentB.mul(90).div(100).add(_randomRange(0, s_maxTraitValue / 15)).sub(_randomRange(0, s_maxTraitValue / 15)));
        uint256 newTraitC = _applyTraitBounds(currentC.mul(90).div(100).add(_randomRange(0, s_maxTraitValue / 15)).sub(_randomRange(0, s_maxTraitValue / 15)));
        uint256 newTraitD = _applyTraitBounds(currentD.mul(90).div(100).add(_randomRange(0, s_maxTraitValue / 15)).sub(_randomRange(0, s_maxTraitValue / 15)));

        // Mint the new token and set its traits directly
        super._safeMint(newEssenceOwner, newTokenId);
         _essences[newTokenId].traitA = newTraitA;
        _essences[newTokenId].traitB = newTraitB;
        _essences[newTokenId].traitC = newTraitC;
        _essences[newTokenId].traitD = newTraitD;
        _essences[newTokenId].creationTime = block.timestamp;
        _essences[newTokenId].lastNurtureTime = block.timestamp;
        _essences[newTokenId].fuelBonded = 0; // New essence starts fresh

        // Update random seed
        _generateRandomSeed();

        emit EssenceReplicated(tokenId, newTokenId, newTraitA, newTraitB, newTraitC, newTraitD);
    }


    // --- Information ---

    /**
     * @notice Returns the total number of Essences that have been minted.
     */
    function getCurrentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @notice Returns the maximum number of Essences that can be minted.
     */
    function getMaxSupply() public view returns (uint256) {
        return s_maxSupply;
    }

     /**
      * @notice Returns the address of the EssenceFuel ERC-20 token used by this contract.
      */
    function getEssenceFuelAddress() public view returns (address) {
        return s_essenceFuelAddress;
    }

    /**
     * @notice Returns the current configuration parameters of the contract.
     */
    function getConfig() public view returns (
        uint256 decayRate,
        uint256 growthRate,
        uint256 nurtureThreshold,
        uint256 mutationCost,
        uint256 fusionCost,
        uint256 replicationCost,
        uint256 minTraitValue,
        uint256 maxTraitValue,
        uint256 livenessThreshold,
        uint256 spawnCost
    ) {
        return (
            s_decayRatePerSecond,
            s_growthRatePerSecond,
            s_nurtureThreshold,
            s_mutationCost,
            s_fusionCost,
            s_replicationCost,
            s_minTraitValue,
            s_maxTraitValue,
            s_livenessThreshold,
            s_spawnCost
        );
    }

    // --- Configuration (Owner Only) ---

    /**
     * @notice Sets the maximum supply of Essences that can be minted. Must be greater than current supply.
     * @param _maxSupply The new maximum supply.
     */
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        if (_maxSupply < _tokenIdCounter.current()) {
            revert DigitalEssence__SupplyLimitMustBeAboveCurrentSupply();
        }
        s_maxSupply = _maxSupply;
        emit ConfigUpdated();
    }

    /**
     * @notice Sets the address of the EssenceFuel ERC-20 token.
     * @param _essenceFuelAddress The new address of the EssenceFuel token.
     */
    function setEssenceFuelAddress(address _essenceFuelAddress) public onlyOwner {
        require(_essenceFuelAddress != address(0), "Essence fuel address cannot be zero");
        s_essenceFuelAddress = _essenceFuelAddress;
        emit ConfigUpdated();
    }

    /**
     * @notice Sets the decay and growth rates per second for traits.
     * @param _decayRatePerSecond The new decay rate (scaled).
     * @param _growthRatePerSecond The new growth rate (scaled).
     */
    function setDecayGrowthRates(uint256 _decayRatePerSecond, uint256 _growthRatePerSecond) public onlyOwner {
        s_decayRatePerSecond = _decayRatePerSecond;
        s_growthRatePerSecond = _growthRatePerSecond;
        emit ConfigUpdated();
    }

    /**
     * @notice Sets the amount of fuel bonded needed to trigger trait growth instead of decay.
     * @param _nurtureThreshold The new nurture threshold.
     */
    function setNurtureThreshold(uint256 _nurtureThreshold) public onlyOwner {
        s_nurtureThreshold = _nurtureThreshold;
        emit ConfigUpdated();
    }

    /**
     * @notice Sets the fuel costs for the core interaction mechanics.
     * @param _mutationCost New mutation cost.
     * @param _fusionCost New fusion cost.
     * @param _replicationCost New replication cost.
     * @param _spawnCost New spawn cost.
     */
    function setInteractionCosts(uint256 _mutationCost, uint256 _fusionCost, uint256 _replicationCost, uint256 _spawnCost) public onlyOwner {
        s_mutationCost = _mutationCost;
        s_fusionCost = _fusionCost;
        s_replicationCost = _replicationCost;
        s_spawnCost = _spawnCost;
        emit ConfigUpdated();
    }

     /**
     * @notice Sets the minimum and maximum possible values for traits. Affects calculations and bounds.
     * @param _minTraitValue New minimum trait value (scaled).
     * @param _maxTraitValue New maximum trait value (scaled).
     */
    function setTraitBounds(uint256 _minTraitValue, uint256 _maxTraitValue) public onlyOwner {
        require(_minTraitValue < _maxTraitValue, "Min trait must be less than max");
        s_minTraitValue = _minTraitValue;
        s_maxTraitValue = _maxTraitValue;
        emit ConfigUpdated();
    }

     /**
     * @notice Sets the minimum sum of traits required for an Essence to be considered alive.
     * @param _livenessThreshold The new liveness threshold.
     */
    function setLivenessThreshold(uint256 _livenessThreshold) public onlyOwner {
         require(_livenessThreshold >= s_minTraitValue * 4, "Liveness threshold seems too low based on min traits");
         require(_livenessThreshold <= s_maxTraitValue * 4, "Liveness threshold seems too high based on max traits");
        s_livenessThreshold = _livenessThreshold;
        emit ConfigUpdated();
    }

    // --- Ownership ---
    // transferOwnership is inherited from Ownable and marked public override

}
```

---

**Explanation of Concepts and Design Choices:**

1.  **Dynamic On-Chain Traits:** Instead of traditional NFTs where metadata points to an off-chain image/JSON with static properties, traits (`traitA`, `traitB`, `traitC`, `traitD`) are stored directly in the contract's storage (`_essences` mapping). These traits are `uint256` values, which can represent various abstract qualities or numerical attributes (like power, speed, intelligence, beauty, etc.). The values are scaled (e.g., by 100) to allow for fractional mechanics without using floating-point numbers.

2.  **Time-Based Evolution (Decay/Growth):**
    *   Each essence tracks its `lastNurtureTime`.
    *   The `calculateCurrentTraits` function uses `block.timestamp` and `lastNurtureTime` to determine how much time has passed since the state was last considered for evolution.
    *   Based on whether the `fuelBonded` is above or below `s_nurtureThreshold`, traits either decay or grow over this elapsed time at rates `s_decayRatePerSecond` or `s_growthRatePerSecond`.
    *   This calculation is done *on the fly* in view functions (`getEssenceDetails`, `isEssenceAlive`, etc.) and *before* state-changing operations (`mutate`, `fuse`, `replicate`) that depend on the current state. This avoids needing frequent, gas-costly updates to storage.
    *   The `lastNurtureTime` is updated whenever a state-changing action (nurture, unbond, mutate, fuse, replicate) occurs, effectively "resetting" the time elapsed for the next calculation.

3.  **Resource Bonding (`EssenceFuel`):**
    *   An external ERC-20 token (`s_essenceFuelAddress`) is used as a resource.
    *   Users `nurtureEssence` by transferring `EssenceFuel` to the contract, which is then recorded in the essence's `fuelBonded` amount.
    *   Bonded fuel is not spent (unless configured differently), but *held* by the contract, linked to the essence.
    *   The amount of `fuelBonded` determines whether the essence's traits decay or grow over time.
    *   Fuel can be `unbondFuel` by the owner.
    *   Core actions like `spawn`, `mutate`, `fuse`, and `replicate` *consume* fuel (transferred from the caller to the contract and not returned).

4.  **Algorithmic Interaction (Mutation, Fusion, Replication):**
    *   **Mutation:** A probabilistic process where an essence's traits are randomly altered within a range. Requires fuel and utilizes the pseudo-randomness.
    *   **Fusion:** Combines two existing essences (`_burn` two tokens) into a single new one (`_safeMint` one token). The new essence's traits are derived from the parents (e.g., weighted average with randomness) and it costs fuel.
    *   **Replication:** Creates a new essence from a single high-trait parent. Requires the parent essence to have very high cumulative traits and costs fuel. It's a way to breed high-quality essences, limited by the overall supply.
    *   These mechanics add game-like depth and influence the population's composition and evolution.

5.  **On-chain Pseudo-Randomness:**
    *   Uses `block.timestamp`, `block.difficulty` (or `block.number`), `msg.sender`, and previous seed to generate a seed for randomness.
    *   **IMPORTANT:** This is *not* cryptographically secure and is susceptible to miner manipulation (miners can choose not to publish a block if the outcome of a transaction based on randomness is unfavorable to them). For production systems where outcomes must be truly random and unmanipulable, integrating Chainlink VRF or a similar decentralized oracle is necessary. This implementation serves demonstration purposes for the concept.

6.  **Liveness and Decay to Zero:**
    *   Essences have a `s_livenessThreshold` based on the sum of their calculated traits.
    *   If `isEssenceAlive` returns false, the essence is considered "dead".
    *   Attempting actions like `nurture`, `mutate`, `fuse`, or `replicate` on a dead essence will revert using the `whenEssenceExistsAndAlive` modifier.
    *   The `_beforeTokenTransfer` override prevents transferring a dead essence.
    *   When an essence is burned (`_burn`), if its state prior to burning indicates it was dead, an `EssenceDeceased` event is emitted. This could happen due to decay if not nurtured.

7.  **Configuration:** Many parameters (`s_maxSupply`, rates, costs, bounds) are configurable by the owner, allowing tuning of the game mechanics after deployment.

8.  **OpenZeppelin Usage:** Leverages standard, audited libraries (`ERC721`, `Ownable`, `SafeMath`, `Counters`, `ReentrancyGuard`) for common functionalities, focusing custom logic on the unique mechanics.

**Potential Future Extensions/Ideas (beyond the 20+ functions):**

*   **Trait-Specific Decay/Growth:** Different traits decay/grow at different rates or are influenced by different types of nurture.
*   **Environmental Factors:** Introduce contract-level state variables that act as "environmental factors" influencing all essences (e.g., a global "condition" that affects decay/growth rates).
*   **Token-Bound Accounts (ERC-6551):** Give each Essence its own smart contract wallet, allowing it to hold tokens or other NFTs, opening up complex interactions.
*   **On-chain Combat/Interaction:** Essences could fight or interact directly, using their traits in on-chain battles, potentially leading to trait changes, burning, or rewards.
*   **Visual Representation:** Develop an off-chain renderer that takes the on-chain trait data and generates unique visual art corresponding to the Essence's state. This could also be dynamic.
*   **Delegated Nurturing:** Allow owners to delegate nurturing rights to specific addresses without full approval.
*   **DAO Governance:** Transition ownership and configuration control to a Decentralized Autonomous Organization (DAO).
*   **Tiered Essences:** Different classes or tiers of essences with different trait ranges or mechanics.
*   **Quests/Tasks:** Essences could be "sent on quests" (represented by staking or locking) which affect their traits or yield rewards.

This contract provides a framework for a complex digital ecosystem built on evolving, resource-dependent NFTs, moving beyond simple static collectibles.