Okay, here is a smart contract concept and implementation attempting to be interesting, advanced, creative, and trendy, while aiming to avoid direct duplication of common open-source patterns.

This contract implements a system of dynamic, time-sensitive assets ("ChronoCrystals") that require maintenance ("Charge") using a fungible resource ("Energy"). Crystals can form "Bonds" to modify their behavior, and users can "Harvest" accumulated charge into Energy.

**Concept:** ChronoCrystals are stateful NFTs that possess a decaying resource ("Charge"). Users must spend an internal fungible token ("Energy") to "Recharge" the crystals. Bonded crystals can share or modify decay rates and charge capacities, creating network dynamics. Charge can be converted back into Energy, creating a loop. This simulates resource management, time-based mechanics, and network effects within the smart contract.

**Outline:**

1.  **Pragma and Licenses**
2.  **Imports** (Ownable, Pausable for standard controls)
3.  **Error Definitions** (Custom errors for gas efficiency)
4.  **Events** (Signals important state changes)
5.  **Data Structures** (`Crystal`, `CrystalParams`)
6.  **State Variables** (Mappings, counters, parameters)
7.  **Modifiers** (Custom checks)
8.  **Ownable/Pausable Implementation**
9.  **Internal Helper Functions** (e.g., `_updateCharge`, `_calculateEffective...`)
10. **Constructor** (Initializes basic params)
11. **Core Asset (Crystal) Management** (Mint, Transfer, Burn, Query state)
12. **Core Resource (Energy) Management** (Transfer, Query balance/supply)
13. **Crystal Interaction & Mechanics** (Recharge, Bond, Unbond, Harvest)
14. **Parameter & Type Management** (Admin functions)
15. **Query Functions** (Various getters)

**Function Summary (29 Functions):**

*   **Asset Management:**
    1.  `createCrystal(uint8 crystalType)`: Mints a new ChronoCrystal of a specified type.
    2.  `transferCrystal(address to, uint256 crystalId)`: Transfers ownership of a Crystal.
    3.  `burnCrystal(uint256 crystalId)`: Destroys a Crystal (requires owner).
    4.  `getCrystalState(uint256 crystalId)`: Returns the current state of a Crystal, including calculated current charge.
    5.  `getCrystalOwner(uint256 crystalId)`: Gets the owner address of a Crystal.
    6.  `getCrystalType(uint256 crystalId)`: Gets the type of a Crystal.
    7.  `getCrystalLastCharged(uint256 crystalId)`: Gets the last timestamp a Crystal's charge was updated.
    8.  `getBondedPartner(uint256 crystalId)`: Gets the ID of the Crystal's bonded partner (0 if none).
    9.  `getTotalCrystals()`: Gets the total number of Crystals minted.
*   **Resource Management (Energy):**
    10. `getEnergyBalance(address owner)`: Gets the Energy token balance for an address.
    11. `transferEnergy(address to, uint256 amount)`: Transfers Energy tokens.
    12. `getTotalEnergySupply()`: Gets the total supply of Energy tokens.
*   **Crystal Interaction & Mechanics:**
    13. `rechargeCrystal(uint256 crystalId, uint256 energyAmount)`: Uses Energy to increase a Crystal's Charge.
    14. `bondCrystals(uint256 crystalId1, uint256 crystalId2)`: Bonds two Crystals together.
    15. `unbondCrystal(uint256 crystalId)`: Unbonds a Crystal from its partner.
    16. `harvestCharge(uint256 crystalId)`: Converts a Crystal's current Charge into Energy tokens.
    17. `calculateCurrentCharge(uint256 crystalId)`: Calculates the current Charge of a Crystal based on decay.
    18. `getEffectiveMaxCharge(uint256 crystalId)`: Calculates the effective max charge, considering bonding bonuses.
    19. `getEffectiveDecayRate(uint256 crystalId)`: Calculates the effective decay rate, considering bonding bonuses.
    20. `isBonded(uint256 crystalId)`: Checks if a Crystal is currently bonded.
*   **Parameter & Type Management (Admin):**
    21. `setCrystalTypeParams(uint8 crystalType, uint256 maxCharge, uint256 decayRatePerSecond, uint256 bondBonusPercentage)`: Sets parameters for a specific Crystal type.
    22. `addAllowedCrystalType(uint8 crystalType)`: Adds a Crystal type that can be created.
    23. `removeAllowedCrystalType(uint8 crystalType)`: Removes a Crystal type from allowed creation.
    24. `setChargeHarvestRate(uint256 rate)`: Sets the conversion rate from Charge to Energy during harvest.
    25. `setBondFee(uint256 fee)`: Sets the fee required to bond crystals.
    26. `withdrawFees(address recipient)`: Allows owner to withdraw accumulated fees.
*   **Access Control (Inherited/Standard):**
    27. `pause()`: Pauses contract functionality.
    28. `unpause()`: Unpauses contract functionality.
    29. `transferOwnership(address newOwner)`: Transfers contract ownership.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, SafeMath adds clarity for complex calcs

// --- Outline ---
// 1. Pragma and Licenses
// 2. Imports
// 3. Error Definitions
// 4. Events
// 5. Data Structures (Crystal, CrystalParams)
// 6. State Variables (Mappings, counters, parameters)
// 7. Modifiers (Custom checks)
// 8. Ownable/Pausable Implementation
// 9. Internal Helper Functions (e.g., _updateCharge, _calculateEffective...)
// 10. Constructor (Initializes basic params)
// 11. Core Asset (Crystal) Management (Mint, Transfer, Burn, Query state)
// 12. Core Resource (Energy) Management (Transfer, Query balance/supply)
// 13. Crystal Interaction & Mechanics (Recharge, Bond, Unbond, Harvest)
// 14. Parameter & Type Management (Admin functions)
// 15. Query Functions (Various getters)

// --- Function Summary ---
// Asset Management:
// createCrystal(uint8 crystalType): Mints a new ChronoCrystal.
// transferCrystal(address to, uint256 crystalId): Transfers Crystal ownership.
// burnCrystal(uint256 crystalId): Destroys a Crystal.
// getCrystalState(uint256 crystalId): Gets current Crystal state.
// getCrystalOwner(uint256 crystalId): Gets Crystal owner.
// getCrystalType(uint256 crystalId): Gets Crystal type.
// getCrystalLastCharged(uint256 crystalId): Gets Crystal last charge timestamp.
// getBondedPartner(uint256 crystalId): Gets bonded partner ID.
// getTotalCrystals(): Gets total Crystal count.
// Resource Management (Energy):
// getEnergyBalance(address owner): Gets Energy balance.
// transferEnergy(address to, uint256 amount): Transfers Energy.
// getTotalEnergySupply(): Gets total Energy supply.
// Crystal Interaction & Mechanics:
// rechargeCrystal(uint256 crystalId, uint256 energyAmount): Use Energy to add Charge.
// bondCrystals(uint256 crystalId1, uint256 crystalId2): Bonds two Crystals.
// unbondCrystal(uint256 crystalId): Unbonds a Crystal.
// harvestCharge(uint256 crystalId): Convert Charge to Energy.
// calculateCurrentCharge(uint256 crystalId): Calculate decayed Charge.
// getEffectiveMaxCharge(uint256 crystalId): Get max charge with bond bonus.
// getEffectiveDecayRate(uint256 crystalId): Get decay rate with bond bonus.
// isBonded(uint256 crystalId): Check if bonded.
// Parameter & Type Management (Admin):
// setCrystalTypeParams(uint8 type, uint256 maxCharge, uint256 decayRatePerSecond, uint256 bondBonusPercentage): Set type params.
// addAllowedCrystalType(uint8 crystalType): Add allowed type.
// removeAllowedCrystalType(uint8 crystalType): Remove allowed type.
// setChargeHarvestRate(uint256 rate): Set harvest rate.
// setBondFee(uint256 fee): Set bond fee.
// withdrawFees(address recipient): Withdraw accumulated fees.
// Access Control (Standard):
// pause(): Pause contract.
// unpause(): Unpause contract.
// transferOwnership(address newOwner): Transfer ownership.


contract ChronoCrystals is Ownable, Pausable {
    using SafeMath for uint256; // Using SafeMath for clarity in calculations
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error CrystalNotFound(uint256 crystalId);
    error NotCrystalOwner(address caller, uint256 crystalId);
    error InsufficientEnergy(address caller, uint256 requested, uint256 available);
    error CrystalNotRechargeable(uint256 crystalId, uint256 currentCharge, uint256 maxCharge);
    error CannotBondSelf(uint256 crystalId);
    error CrystalsAlreadyBonded(uint256 crystalId1, uint256 crystalId2);
    error CrystalAlreadyBonded(uint256 crystalId);
    error CrystalsNotBonded(uint256 crystalId1, uint256 crystalId2); // Although bond check is simpler
    error InvalidCrystalType(uint8 crystalType);
    error InsufficientChargeToHarvest(uint256 crystalId, uint256 currentCharge, uint256 required);
    error InsufficientBondFee(uint256 required, uint256 sent);
    error NoFeesToWithdraw();

    // --- Events ---
    event CrystalCreated(uint256 indexed crystalId, address indexed owner, uint8 crystalType, uint256 timestamp);
    event CrystalTransfer(uint256 indexed crystalId, address indexed from, address indexed to);
    event CrystalBurned(uint256 indexed crystalId, address indexed owner);
    event CrystalCharged(uint256 indexed crystalId, address indexed chager, uint256 energyUsed, uint256 newCharge);
    event CrystalsBonded(uint256 indexed crystalId1, uint256 indexed crystalId2, address indexed bonder, uint256 timestamp);
    event CrystalUnbonded(uint256 indexed crystalId, uint256 indexed partnerId, uint256 timestamp);
    event ChargeHarvested(uint256 indexed crystalId, address indexed harvester, uint256 chargeConsumed, uint256 energyMinted);
    event EnergyTransfer(address indexed from, address indexed to, uint256 amount);
    event CrystalTypeParamsUpdated(uint8 crystalType, uint256 maxCharge, uint256 decayRatePerSecond, uint256 bondBonusPercentage);
    event AllowedCrystalTypeAdded(uint8 crystalType);
    event AllowedCrystalTypeRemoved(uint8 crystalType);
    event ChargeHarvestRateUpdated(uint256 rate);
    event BondFeeUpdated(uint256 fee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Data Structures ---
    struct Crystal {
        uint256 id;
        address owner;
        uint8 crystalType;
        uint256 charge; // Current charge amount
        uint256 lastChargedTimestamp; // Timestamp when charge was last updated
        uint256 bondedPartnerId; // ID of the crystal it's bonded to (0 if none)
    }

    struct CrystalParams {
        uint256 maxCharge; // Maximum charge capacity
        uint256 decayRatePerSecond; // Charge lost per second
        uint256 bondBonusPercentage; // Percentage bonus applied to maxCharge and reduction to decayRate when bonded
    }

    // --- State Variables ---
    mapping(uint256 => Crystal) private _crystals;
    mapping(address => uint256) private _energyBalances;
    mapping(uint8 => CrystalParams) private _crystalTypeParams;
    mapping(uint8 => bool) private _allowedCrystalTypes;

    Counters.Counter private _crystalIds;
    uint256 private _totalEnergySupply;
    uint256 private _chargeHarvestRate = 1; // Default: 1 unit of Charge = 1 unit of Energy
    uint256 private _bondFee = 0; // Fee required to bond crystals
    uint256 private _accumulatedFees = 0; // ETH/native token accumulated from fees

    // --- Modifiers ---
    modifier onlyCrystalOwner(uint256 crystalId) {
        if (_crystals[crystalId].owner != msg.sender) {
            revert NotCrystalOwner(msg.sender, crystalId);
        }
        _;
    }

    modifier whenCrystalExists(uint256 crystalId) {
        if (_crystals[crystalId].owner == address(0)) { // Check if crystal exists by owner being non-zero
             revert CrystalNotFound(crystalId);
        }
        _;
    }

    modifier onlyAllowedCrystalType(uint8 crystalType) {
        if (!_allowedCrystalTypes[crystalType]) {
            revert InvalidCrystalType(crystalType);
        }
        _;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the amount of charge decayed since last update and applies it.
     * Updates the crystal's charge and lastChargedTimestamp.
     * @param crystalId The ID of the crystal to update.
     * @return uint256 The charge amount after decay.
     */
    function _updateCharge(uint256 crystalId) internal returns (uint256) {
        Crystal storage crystal = _crystals[crystalId];
        uint256 timePassed = block.timestamp.sub(crystal.lastChargedTimestamp);
        uint256 effectiveDecayRate = _calculateEffectiveDecayRate(crystalId);

        uint256 decayAmount = timePassed.mul(effectiveDecayRate);

        if (decayAmount >= crystal.charge) {
            crystal.charge = 0;
        } else {
            crystal.charge = crystal.charge.sub(decayAmount);
        }

        crystal.lastChargedTimestamp = block.timestamp;
        return crystal.charge;
    }

    /**
     * @dev Calculates the current charge without updating the crystal state.
     * Useful for pure view functions.
     * @param crystalId The ID of the crystal.
     * @return uint256 The current charge amount.
     */
    function _getCurrentCharge(uint256 crystalId) internal view returns (uint256) {
         Crystal storage crystal = _crystals[crystalId];
         uint256 timePassed = block.timestamp.sub(crystal.lastChargedTimestamp);
         uint256 effectiveDecayRate = _calculateEffectiveDecayRate(crystalId);

         uint256 decayAmount = timePassed.mul(effectiveDecayRate);

         if (decayAmount >= crystal.charge) {
             return 0;
         } else {
             return crystal.charge.sub(decayAmount);
         }
    }

    /**
     * @dev Calculates the effective max charge considering bonding bonuses.
     * @param crystalId The ID of the crystal.
     * @return uint256 The effective max charge.
     */
    function _calculateEffectiveMaxCharge(uint256 crystalId) internal view returns (uint256) {
        Crystal storage crystal = _crystals[crystalId];
        CrystalParams storage params = _crystalTypeParams[crystal.crystalType];
        uint256 baseMaxCharge = params.maxCharge;

        if (crystal.bondedPartnerId != 0) {
            uint256 bonus = baseMaxCharge.mul(params.bondBonusPercentage).div(100);
            return baseMaxCharge.add(bonus);
        }
        return baseMaxCharge;
    }

    /**
     * @dev Calculates the effective decay rate considering bonding bonuses.
     * @param crystalId The ID of the crystal.
     * @return uint256 The effective decay rate per second.
     */
    function _calculateEffectiveDecayRate(uint256 crystalId) internal view returns (uint256) {
        Crystal storage crystal = _crystals[crystalId];
        CrystalParams storage params = _crystalTypeParams[crystal.crystalType];
        uint256 baseDecayRate = params.decayRatePerSecond;

        if (crystal.bondedPartnerId != 0) {
            uint256 reduction = baseDecayRate.mul(params.bondBonusPercentage).div(100);
            if (reduction > baseDecayRate) reduction = baseDecayRate; // Cap reduction
            return baseDecayRate.sub(reduction);
        }
        return baseDecayRate;
    }


    // --- Constructor ---
    constructor() Ownable(msg.sender) {} // Sets initial owner to deployer

    // --- Core Asset (Crystal) Management ---

    /**
     * @dev Mints a new ChronoCrystal.
     * @param crystalType The type of crystal to create.
     */
    function createCrystal(uint8 crystalType) public whenNotPaused onlyAllowedCrystalType(crystalType) {
        _crystalIds.increment();
        uint256 newItemId = _crystalIds.current();

        _crystals[newItemId] = Crystal({
            id: newItemId,
            owner: msg.sender,
            crystalType: crystalType,
            charge: 0, // Starts with no charge
            lastChargedTimestamp: block.timestamp,
            bondedPartnerId: 0 // Not bonded initially
        });

        emit CrystalCreated(newItemId, msg.sender, crystalType, block.timestamp);
    }

    /**
     * @dev Transfers ownership of a ChronoCrystal.
     * @param to The address to transfer to.
     * @param crystalId The ID of the crystal to transfer.
     */
    function transferCrystal(address to, uint256 crystalId) public whenNotPaused onlyCrystalOwner(crystalId) whenCrystalExists(crystalId) {
        require(to != address(0), "Transfer to the zero address");

        // If bonded, unbond first? Or transfer whole pair? Let's require unbonding first.
        // This simplifies logic and prevents unexpected state issues.
        require(_crystals[crystalId].bondedPartnerId == 0, "Crystal must be unbonded before transfer");

        address from = msg.sender;
        _crystals[crystalId].owner = to;

        emit CrystalTransfer(crystalId, from, to);
    }

    /**
     * @dev Burns (destroys) a ChronoCrystal.
     * @param crystalId The ID of the crystal to burn.
     */
    function burnCrystal(uint256 crystalId) public whenNotPaused onlyCrystalOwner(crystalId) whenCrystalExists(crystalId) {
         // Must be unbonded to burn
        require(_crystals[crystalId].bondedPartnerId == 0, "Crystal must be unbonded before burning");

        address owner = _crystals[crystalId].owner;
        delete _crystals[crystalId]; // Removes the crystal data

        // Note: This doesn't decrement _crystalIds counter, which is standard behavior.

        emit CrystalBurned(crystalId, owner);
    }

    /**
     * @dev Gets the current state of a ChronoCrystal, including calculated current charge.
     * @param crystalId The ID of the crystal.
     * @return Crystal The crystal struct.
     */
    function getCrystalState(uint256 crystalId) public view whenCrystalExists(crystalId) returns (Crystal memory) {
         Crystal storage crystal = _crystals[crystalId];
         // Return a copy with the calculated current charge
         return Crystal({
             id: crystal.id,
             owner: crystal.owner,
             crystalType: crystal.crystalType,
             charge: _getCurrentCharge(crystalId), // Calculate current charge for view
             lastChargedTimestamp: crystal.lastChargedTimestamp,
             bondedPartnerId: crystal.bondedPartnerId
         });
    }

     /**
     * @dev Gets the owner of a Crystal.
     * @param crystalId The ID of the crystal.
     * @return address The owner's address.
     */
    function getCrystalOwner(uint256 crystalId) public view whenCrystalExists(crystalId) returns (address) {
        return _crystals[crystalId].owner;
    }

     /**
     * @dev Gets the type of a Crystal.
     * @param crystalId The ID of the crystal.
     * @return uint8 The crystal type.
     */
    function getCrystalType(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint8) {
        return _crystals[crystalId].crystalType;
    }

     /**
     * @dev Gets the last timestamp a Crystal's charge was updated.
     * @param crystalId The ID of the crystal.
     * @return uint256 Timestamp.
     */
    function getCrystalLastCharged(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint256) {
        return _crystals[crystalId].lastChargedTimestamp;
    }

    /**
     * @dev Gets the ID of the Crystal's bonded partner.
     * @param crystalId The ID of the crystal.
     * @return uint256 Partner ID (0 if none).
     */
    function getBondedPartner(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint256) {
        return _crystals[crystalId].bondedPartnerId;
    }

    /**
     * @dev Gets the total number of Crystals ever minted.
     * Note: This does not decrease when crystals are burned.
     * @return uint256 Total crystal count.
     */
    function getTotalCrystals() public view returns (uint256) {
        return _crystalIds.current();
    }


    // --- Core Resource (Energy) Management ---
    // Energy is a fungible resource managed internally.

    /**
     * @dev Gets the Energy token balance for an address.
     * @param owner The address to query.
     * @return uint256 The Energy balance.
     */
    function getEnergyBalance(address owner) public view returns (uint256) {
        return _energyBalances[owner];
    }

    /**
     * @dev Transfers Energy tokens from caller's balance to another address.
     * @param to The recipient address.
     * @param amount The amount of Energy to transfer.
     */
    function transferEnergy(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "Transfer to the zero address");
        if (_energyBalances[msg.sender] < amount) {
            revert InsufficientEnergy(msg.sender, amount, _energyBalances[msg.sender]);
        }

        _energyBalances[msg.sender] = _energyBalances[msg.sender].sub(amount);
        _energyBalances[to] = _energyBalances[to].add(amount);

        emit EnergyTransfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the total supply of Energy tokens.
     * @return uint256 Total supply.
     */
    function getTotalEnergySupply() public view returns (uint256) {
        return _totalEnergySupply;
    }


    // --- Crystal Interaction & Mechanics ---

    /**
     * @dev Uses Energy to increase a Crystal's Charge.
     * @param crystalId The ID of the crystal to recharge.
     * @param energyAmount The amount of Energy to spend.
     */
    function rechargeCrystal(uint256 crystalId, uint256 energyAmount) public whenNotPaused onlyCrystalOwner(crystalId) whenCrystalExists(crystalId) {
        require(energyAmount > 0, "Cannot recharge with 0 energy");
        if (_energyBalances[msg.sender] < energyAmount) {
            revert InsufficientEnergy(msg.sender, energyAmount, _energyBalances[msg.sender]);
        }

        Crystal storage crystal = _crystals[crystalId];
        uint256 effectiveMaxCharge = _calculateEffectiveMaxCharge(crystalId);
        uint256 currentCharge = _updateCharge(crystalId); // Apply decay before adding charge

        uint256 chargeToAdd = energyAmount; // Simple 1:1 conversion from Energy to Charge

        if (currentCharge >= effectiveMaxCharge) {
             revert CrystalNotRechargeable(crystalId, currentCharge, effectiveMaxCharge);
        }

        uint256 newCharge = currentCharge.add(chargeToAdd);
        if (newCharge > effectiveMaxCharge) {
            // Refund excess energy if charging beyond max capacity
            uint256 chargeAdded = effectiveMaxCharge.sub(currentCharge);
            uint256 energyRefund = chargeAdded; // Assuming 1:1, refund matches added charge
            energyAmount = chargeAdded; // Only consume energy matching added charge
            newCharge = effectiveMaxCharge;

             // If energyAmount was initially greater than chargeAdded, refund the difference
            if (energyAmount < chargeToAdd) {
                 uint256 refund = chargeToAdd.sub(energyAmount);
                 _energyBalances[msg.sender] = _energyBalances[msg.sender].add(refund);
                 // Emit refund event? Or rely on Recharge + implicit balance check?
                 // For simplicity, let's adjust energyAmount used here and check balance before.
                 // The initial check `if (_energyBalances[msg.sender] < energyAmount)` is sufficient.
                 // No, need to adjust energyAmount *after* calculating max capacity fill.
                 // Re-calculate energyAmount based on chargeToAdd to cap consumption.
                 energyAmount = chargeAdded; // This is the actual energy consumed
            }
        }

        _energyBalances[msg.sender] = _energyBalances[msg.sender].sub(energyAmount);
        crystal.charge = newCharge;

        emit CrystalCharged(crystalId, msg.sender, energyAmount, newCharge);
    }

    /**
     * @dev Bonds two ChronoCrystals together. Requires ownership of both.
     * Pays the bond fee.
     * @param crystalId1 The ID of the first crystal.
     * @param crystalId2 The ID of the second crystal.
     */
    function bondCrystals(uint256 crystalId1, uint256 crystalId2) public payable whenNotPaused {
        if (crystalId1 == crystalId2) revert CannotBondSelf(crystalId1);
        if (msg.value < _bondFee) revert InsufficientBondFee(_bondFee, msg.value);

        // Ensure both crystals exist and are owned by the caller
        require(_crystals[crystalId1].owner == msg.sender, "Caller must own crystal 1"); // Custom error later
        require(_crystals[crystalId2].owner == msg.sender, "Caller must own crystal 2"); // Custom error later

        // Ensure neither is already bonded
        if (_crystals[crystalId1].bondedPartnerId != 0 || _crystals[crystalId2].bondedPartnerId != 0) {
            revert CrystalsAlreadyBonded(crystalId1, crystalId2);
        }

        // Apply decay to update charge state before bonding
        _updateCharge(crystalId1);
        _updateCharge(crystalId2);

        // Perform the bonding
        _crystals[crystalId1].bondedPartnerId = crystalId2;
        _crystals[crystalId2].bondedPartnerId = crystalId1;

        // Accumulate fee
        if (msg.value > 0) {
             _accumulatedFees = _accumulatedFees.add(msg.value);
        }

        emit CrystalsBonded(crystalId1, crystalId2, msg.sender, block.timestamp);
    }

    /**
     * @dev Unbonds a ChronoCrystal from its partner. Can be called by owner of either crystal.
     * @param crystalId The ID of the crystal to unbond.
     */
    function unbondCrystal(uint256 crystalId) public whenNotPaused whenCrystalExists(crystalId) {
        uint256 partnerId = _crystals[crystalId].bondedPartnerId;
        if (partnerId == 0) revert CrystalAlreadyBonded(crystalId); // It's not bonded

        // Require ownership of either crystal
        require(_crystals[crystalId].owner == msg.sender || _crystals[partnerId].owner == msg.sender, "Caller must own one of the bonded crystals");

        // Apply decay to update charge state before unbonding
        _updateCharge(crystalId);
        _updateCharge(partnerId);

        // Perform the unbonding
        _crystals[crystalId].bondedPartnerId = 0;
        _crystals[partnerId].bondedPartnerId = 0;

        emit CrystalUnbonded(crystalId, partnerId, block.timestamp);
    }

    /**
     * @dev Converts a Crystal's current Charge into Energy tokens.
     * Consumes the charge and mints energy for the crystal owner.
     * @param crystalId The ID of the crystal to harvest from.
     */
    function harvestCharge(uint256 crystalId) public whenNotPaused onlyCrystalOwner(crystalId) whenCrystalExists(crystalId) {
        // Apply decay to get current harvestable charge
        uint256 harvestableCharge = _updateCharge(crystalId);

        if (harvestableCharge == 0) {
            revert InsufficientChargeToHarvest(crystalId, 0, 1); // Need at least 1 charge
        }

        uint256 energyToMint = harvestableCharge.mul(_chargeHarvestRate); // Use the conversion rate

        // Consume all available harvestable charge
        _crystals[crystalId].charge = _crystals[crystalId].charge.sub(harvestableCharge); // Should become 0 after updateCharge if harvestable is all

        // Mint energy tokens
        _energyBalances[msg.sender] = _energyBalances[msg.sender].add(energyToMint);
        _totalEnergySupply = _totalEnergySupply.add(energyToMint); // Update total supply

        emit ChargeHarvested(crystalId, msg.sender, harvestableCharge, energyToMint);
        emit EnergyTransfer(address(0), msg.sender, energyToMint); // Emit Energy transfer event for minting
    }

    /**
     * @dev Calculates the current Charge of a Crystal, accounting for decay.
     * Does NOT modify the crystal state.
     * @param crystalId The ID of the crystal.
     * @return uint256 The current charge.
     */
    function calculateCurrentCharge(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint256) {
        return _getCurrentCharge(crystalId);
    }

     /**
     * @dev Gets the effective max charge of a Crystal, accounting for bond bonuses.
     * @param crystalId The ID of the crystal.
     * @return uint256 The effective max charge.
     */
    function getEffectiveMaxCharge(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint256) {
        return _calculateEffectiveMaxCharge(crystalId);
    }

    /**
     * @dev Gets the effective decay rate of a Crystal, accounting for bond bonuses.
     * @param crystalId The ID of the crystal.
     * @return uint256 The effective decay rate per second.
     */
    function getEffectiveDecayRate(uint256 crystalId) public view whenCrystalExists(crystalId) returns (uint256) {
        return _calculateEffectiveDecayRate(crystalId);
    }

    /**
     * @dev Checks if a Crystal is currently bonded.
     * @param crystalId The ID of the crystal.
     * @return bool True if bonded, false otherwise.
     */
    function isBonded(uint256 crystalId) public view whenCrystalExists(crystalId) returns (bool) {
        return _crystals[crystalId].bondedPartnerId != 0;
    }


    // --- Parameter & Type Management (Admin) ---

    /**
     * @dev Sets or updates parameters for a specific Crystal type. Only callable by owner.
     * @param crystalType The crystal type ID.
     * @param maxCharge The maximum charge capacity.
     * @param decayRatePerSecond The charge lost per second.
     * @param bondBonusPercentage The percentage bonus/reduction when bonded (0-100).
     */
    function setCrystalTypeParams(
        uint8 crystalType,
        uint256 maxCharge,
        uint256 decayRatePerSecond,
        uint256 bondBonusPercentage
    ) public onlyOwner {
        require(bondBonusPercentage <= 100, "Bond bonus percentage cannot exceed 100");
        _crystalTypeParams[crystalType] = CrystalParams(maxCharge, decayRatePerSecond, bondBonusPercentage);
        emit CrystalTypeParamsUpdated(crystalType, maxCharge, decayRatePerSecond, bondBonusPercentage);
    }

    /**
     * @dev Adds a Crystal type that can be created. Only callable by owner.
     * Type parameters must be set first using `setCrystalTypeParams`.
     * @param crystalType The crystal type ID to allow.
     */
    function addAllowedCrystalType(uint8 crystalType) public onlyOwner {
         require(_crystalTypeParams[crystalType].maxCharge > 0, "Crystal type params must be set before allowing");
        _allowedCrystalTypes[crystalType] = true;
        emit AllowedCrystalTypeAdded(crystalType);
    }

    /**
     * @dev Removes a Crystal type from allowed creation. Only callable by owner.
     * Existing crystals of this type are unaffected.
     * @param crystalType The crystal type ID to disallow.
     */
    function removeAllowedCrystalType(uint8 crystalType) public onlyOwner {
        _allowedCrystalTypes[crystalType] = false;
        emit AllowedCrystalTypeRemoved(crystalType);
    }

    /**
     * @dev Sets the conversion rate from Charge to Energy during harvest. Only callable by owner.
     * E.g., rate = 2 means 1 Charge becomes 2 Energy.
     * @param rate The new charge harvest rate.
     */
    function setChargeHarvestRate(uint256 rate) public onlyOwner {
        require(rate > 0, "Harvest rate must be greater than 0");
        _chargeHarvestRate = rate;
        emit ChargeHarvestRateUpdated(rate);
    }

    /**
     * @dev Sets the fee required to bond crystals. Paid in native token (ETH/MATIC).
     * @param fee The new bond fee amount.
     */
    function setBondFee(uint256 fee) public onlyOwner {
        _bondFee = fee;
        emit BondFeeUpdated(fee);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated native token fees from bonding.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address recipient) public onlyOwner {
        uint256 amount = _accumulatedFees;
        if (amount == 0) revert NoFeesToWithdraw();

        _accumulatedFees = 0;
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(recipient, amount);
    }

    // --- Query Functions ---

    /**
     * @dev Gets the parameters for a specific Crystal type.
     * @param crystalType The crystal type ID.
     * @return maxCharge The maximum charge capacity.
     * @return decayRatePerSecond The charge lost per second.
     * @return bondBonusPercentage The percentage bonus/reduction when bonded.
     */
    function getCrystalTypeParams(uint8 crystalType) public view returns (uint256 maxCharge, uint256 decayRatePerSecond, uint256 bondBonusPercentage) {
        CrystalParams storage params = _crystalTypeParams[crystalType];
        return (params.maxCharge, params.decayRatePerSecond, params.bondBonusPercentage);
    }

    /**
     * @dev Checks if a Crystal type is allowed to be created.
     * @param crystalType The crystal type ID.
     * @return bool True if allowed, false otherwise.
     */
    function isAllowedCrystalType(uint8 crystalType) public view returns (bool) {
        return _allowedCrystalTypes[crystalType];
    }

     /**
     * @dev Gets the current conversion rate from Charge to Energy during harvest.
     * @return uint256 The harvest rate.
     */
    function getChargeHarvestRate() public view returns (uint256) {
        return _chargeHarvestRate;
    }

     /**
     * @dev Gets the current fee required to bond crystals.
     * @return uint256 The bond fee.
     */
    function getBondFee() public view returns (uint256) {
        return _bondFee;
    }

     /**
     * @dev Gets the total accumulated fees available for withdrawal.
     * @return uint256 The accumulated fee amount.
     */
    function getAccumulatedFees() public view returns (uint256) {
        return _accumulatedFees;
    }

    // --- Access Control (Inherited) ---

    // Inherits pause(), unpause(), and transferOwnership() from Pausable and Ownable
    // Note: Pausable only applies `whenNotPaused` modifier to functions.
    // The owner can still call owner-only functions even when paused, unless overridden.
    // We added `whenNotPaused` to most user-facing functions.

    /**
     * @dev Pauses all `whenNotPaused` functions. Only callable by owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership is inherited and publicly available.
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic, Time-Sensitive Assets:** ChronoCrystals are not static NFTs. Their "Charge" resource constantly decays over time based on a defined rate. This introduces a maintenance cost and strategic element (users must recharge them).
2.  **Internal Fungible Resource:** The "Energy" token is a core, internally managed resource. It's not a standard ERC-20 listed on external exchanges but exists solely within the contract's ecosystem, defining the economy of recharging.
3.  **Resource Conversion Cycle:** The system creates a loop where Energy is used to gain Charge (recharge), and Charge can be converted back into Energy (harvest). This creates an internal economy and flow of value based on managing the state of the non-fungible assets.
4.  **Asset Relationship / Bonding:** Crystals can be "Bonded" together. This isn't just a metadata tag; it modifies the *behavior* of the assets (e.g., reducing decay rate, increasing max charge). This introduces concepts of network effects, pairing strategy, and interdependency between assets.
5.  **Parameterizable Asset Types:** Different `crystalType` values can have distinct `maxCharge`, `decayRate`, and `bondBonusPercentage` parameters. This allows for varied asset classes with different economic profiles and use cases within the system.
6.  **Calculation of Current State:** The contract doesn't store the absolute "current" charge in storage every second. Instead, it stores the last updated time and calculates the decay amount whenever the charge is needed (`_updateCharge`, `_getCurrentCharge`). This is a common optimization pattern for time-based mechanics on EVM.
7.  **Bond Bonus Logic:** The `bondBonusPercentage` applies a calculated bonus to max charge and a reduction to decay rate for *both* bonded crystals, introducing shared benefit.
8.  **Controlled Minting/Burning:** Crystal creation and destruction (`createCrystal`, `burnCrystal`) are handled by specific contract functions, not open-ended minting/burning, allowing control over the asset supply based on design.
9.  **Explicit Resource Consumption/Generation:** Actions like `rechargeCrystal` explicitly reduce the user's Energy balance and increase the Crystal's charge. `harvestCharge` explicitly reduces Crystal charge and increases the user's Energy balance (and total supply).
10. **Bond Fee Mechanism:** Introduces a cost in native currency (ETH/MATIC) for a specific action (`bondCrystals`), with collected fees managed by the contract owner.

This contract provides a framework for a sophisticated on-chain simulation or game where users manage dynamic assets, strategize bonding, and participate in a resource economy, all within the logic of the smart contract itself. It goes beyond simple token ownership or static NFTs.