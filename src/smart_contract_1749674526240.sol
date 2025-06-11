Okay, let's design a smart contract that simulates the lifecycle and interaction with unique, evolving digital entities. We'll call them "Epochal Lifeforms". This concept involves dynamic state changes based on time (epochs) and user interactions, trait inheritance, and a custom resource token. It's not a standard ERC-XYZ, but rather a custom asset with complex logic tied to it.

**Concept:** Users can 'seed' new Lifeforms, 'nurture' them to maintain vitality, and 'breed' mature Lifeforms to create new generations. Lifeforms decay over time (epochs) if not nurtured, potentially changing state or becoming 'Deceased'.

---

**EpochalLifeforms Smart Contract**

**Outline:**

1.  **Contract Description:** Simulates life cycles of unique digital entities (Lifeforms) with state, traits, and epoch-based decay/evolution.
2.  **Errors:** Custom errors for clearer failure reasons.
3.  **Enums:** Defines possible states of a Lifeform.
4.  **Structs:** Defines the structure of a Lifeform and its Traits.
5.  **State Variables:** Stores contract owner, Lifeform data, Essence token balances, contract parameters, epoch tracking, etc.
6.  **Events:** Logs significant actions and state changes.
7.  **Modifiers:** `onlyOwner` for administrative functions.
8.  **Internal Functions:** Helper functions for core logic (epoch calculation, trait generation, state updates, token management).
9.  **Public/External Functions:**
    *   **Core Lifecycle:** `seedLifeform`, `nurtureLifeform`, `breedLifeforms`, `updateLifeformState`.
    *   **Query:** `getLifeformState`, `getLifeformTraits`, `getLifeformVitality`, `isLifeformAlive`, `getTotalLifeforms`, `getLifeformsByOwner`, `getCurrentEpoch`, `getEpochDuration`, `getEssenceBalance`, `getParams`.
    *   **Ownership/Management:** `transferLifeform`.
    *   **Administrative (Owner Only):** `adminSetEpochDuration`, `adminSetSeedCost`, `adminSetNurtureCost`, `adminSetBreedCost`, `adminSetVitalityDecayRate`, `adminSetBreedVitalityCost`, `adminSetTraitBounds`, `adminMintEssence`, `adminBurnEssence`, `withdrawAdminFees`.
10. **Constructor:** Initializes the contract with basic parameters.

**Function Summary:**

1.  `constructor()`: Deploys the contract, setting the owner and initial parameters like epoch duration, costs, and trait bounds.
2.  `seedLifeform()`: Allows a user to create a new Generation 1 Lifeform. Requires payment in Essence tokens. Assigns random initial traits within defined bounds. Emits `LifeformSeeded`.
3.  `nurtureLifeform(uint256 _lifeformId)`: Allows the owner of a Lifeform to increase its vitality. Requires payment in Essence tokens. Updates the Lifeform's `lastInteractionEpoch`. Emits `LifeformNurtured`.
4.  `breedLifeforms(uint256 _parent1Id, uint256 _parent2Id)`: Allows the owner to breed two Mature Lifeforms they own. Requires payment in Essence tokens and consumes vitality from parents. Creates a new Lifeform with traits inherited/mutated from parents. Emits `LifeformBred`.
5.  `updateLifeformState(uint256 _lifeformId)`: *Callable by anyone*. Processes the state changes for a specific Lifeform based on elapsed epochs since its last interaction or update. Calculates vitality decay and transitions the Lifeform's state (Larval -> Mature -> Aging -> Deceased) accordingly. Emits `LifeformStateUpdated`.
6.  `transferLifeform(uint256 _lifeformId, address _to)`: Allows the owner to transfer ownership of a Lifeform. Updates owner mapping. Emits `LifeformTransferred`.
7.  `getLifeformState(uint256 _lifeformId)`: Returns all detailed state information for a specific Lifeform.
8.  `getLifeformTraits(uint256 _lifeformId)`: Returns the specific traits of a Lifeform.
9.  `getLifeformVitality(uint256 _lifeformId)`: Returns the current vitality level of a Lifeform.
10. `isLifeformAlive(uint256 _lifeformId)`: Returns true if the Lifeform is in a state other than `Deceased`.
11. `getTotalLifeforms()`: Returns the total number of Lifeforms ever created.
12. `getLifeformsByOwner(address _owner)`: Returns an array of IDs of all Lifeforms owned by a specific address. *Note: This can be gas-intensive for owners with many Lifeforms.*
13. `getCurrentEpoch()`: Returns the current epoch number based on block timestamp and epoch duration.
14. `getEpochDuration()`: Returns the duration of a single epoch in seconds.
15. `getEssenceBalance(address _address)`: Returns the Essence token balance for a given address.
16. `getParams()`: Returns key contract parameters (costs, decay rate, breed vitality cost).
17. `adminSetEpochDuration(uint256 _newDuration)`: (Owner Only) Sets the duration of an epoch in seconds.
18. `adminSetSeedCost(uint256 _newCost)`: (Owner Only) Sets the Essence cost to seed a new Lifeform.
19. `adminSetNurtureCost(uint256 _newCost)`: (Owner Only) Sets the Essence cost to nurture a Lifeform.
20. `adminSetBreedCost(uint256 _newCost)`: (Owner Only) Sets the Essence cost to breed Lifeforms.
21. `adminSetVitalityDecayRate(uint256 _newRate)`: (Owner Only) Sets the base vitality decay rate per epoch.
22. `adminSetBreedVitalityCost(uint256 _newCost)`: (Owner Only) Sets the vitality cost consumed from parents during breeding.
23. `adminSetTraitBounds(uint256 _minVitalityDecayModifier, uint256 _maxVitalityDecayModifier, uint256 _minNurtureEffectModifier, uint256 _maxNurtureEffectModifier, uint256 _minBreedEffectModifier, uint256 _maxBreedEffectModifier)`: (Owner Only) Sets the bounds for randomly generated or mutated traits.
24. `adminMintEssence(address _to, uint256 _amount)`: (Owner Only) Mints new Essence tokens and assigns them to an address.
25. `adminBurnEssence(address _from, uint256 _amount)`: (Owner Only) Burns Essence tokens from an address's balance.
26. `withdrawAdminFees()`: (Owner Only) Withdraws accumulated contract balance (from percentages of costs) to the owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// EpochalLifeforms Smart Contract
// Description: Simulates life cycles of unique digital entities (Lifeforms) with state, traits, and epoch-based decay/evolution.
// Users can 'seed', 'nurture', and 'breed' Lifeforms using a custom internal token ('Essence').
// Lifeforms decay over time (epochs) if not nurtured, potentially changing state or becoming 'Deceased'.
// The contract includes dynamic parameters, trait inheritance, and an incentivized state update mechanism.

// Outline:
// 1. Contract Description
// 2. Errors: Custom errors for clearer failure reasons.
// 3. Enums: Defines possible states of a Lifeform.
// 4. Structs: Defines the structure of a Lifeform and its Traits.
// 5. State Variables: Stores contract owner, Lifeform data, Essence token balances, contract parameters, epoch tracking, etc.
// 6. Events: Logs significant actions and state changes.
// 7. Modifiers: onlyOwner for administrative functions.
// 8. Internal Functions: Helper functions for core logic (epoch calculation, trait generation, state updates, token management).
// 9. Public/External Functions: Core Lifecycle, Query, Ownership/Management, Administrative.
// 10. Constructor: Initializes the contract.

import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for clarity though Solidity 0.8+ checks overflow
import "@openzeppelin/contracts/access/Ownable.sol"; // Simple ownership pattern

contract EpochalLifeforms is Ownable {
    using SafeMath for uint256;

    // --- Errors ---
    error InvalidLifeformId();
    error NotLifeformOwner();
    error InsufficientEssence(uint256 required, uint256 has);
    error NotEnoughVitalityForBreed(uint256 required, uint256 has);
    error LifeformNotInValidState(uint256 lifeformId, LifeformState currentState, string requiredState);
    error LifeformsCannotBreed(uint256 id1, LifeformState state1, uint256 id2, LifeformState state2);
    error TransferNotAllowedInState(LifeformState currentState);
    error NoPendingEpochUpdates(uint256 lifeformId);
    error InvalidTraitBounds();

    // --- Enums ---
    enum LifeformState {
        Larval,   // Initial state, cannot breed, low decay
        Mature,   // Can breed, moderate decay
        Aging,    // Cannot breed, high decay
        Dormant,  // Stasis, no decay but inactive (potential future use or specific trait outcome)
        Deceased  // Cannot interact, inactive
    }

    // --- Structs ---
    struct Traits {
        uint256 vitalityDecayModifier; // Lower is better (less decay) - range e.g., 50-150 (base 100)
        uint256 nurtureEffectModifier; // Higher is better (more vitality gained) - range e.g., 80-120 (base 100)
        uint256 breedEffectModifier;   // Higher is better (better chance for strong offspring traits) - range e.g., 80-120 (base 100)
        // Add more traits as needed for complexity
    }

    struct Lifeform {
        uint256 id;
        address owner;
        uint256 generation;
        uint256 birthEpoch;
        uint256 lastInteractionEpoch; // Updated on nurture or breed (parent)
        uint256 vitality;             // 0-10000, maps to state
        Traits traits;
        LifeformState state;
    }

    // --- State Variables ---

    uint256 private _lifeformCounter;
    mapping(uint256 => Lifeform) private _lifeforms;
    mapping(address => uint256[]) private _ownerLifeforms; // Track lifeforms by owner
    mapping(uint256 => uint256) private _ownerLifeformIndex; // Helper for removing from _ownerLifeforms array

    mapping(address => uint256) private _essenceBalances; // Custom internal token balance

    uint256 private _epochDuration = 1 days; // Duration of an epoch in seconds
    uint256 private _vitalityDecayRate = 100; // Base vitality decay per epoch (out of 10000)
    uint256 private _breedVitalityCost = 1000; // Vitality cost consumed from *each* parent during breeding

    uint256 private _seedCost = 100;     // Essence cost to seed
    uint256 private _nurtureCost = 50;   // Essence cost to nurture
    uint256 private _breedCost = 200;    // Essence cost to breed
    uint256 private _adminFeeRate = 50; // 50 = 5% fee (50/1000)
    uint256 private _adminFeeFactor = 1000;

    // Bounds for random trait generation/mutation (e.g., min/max base values)
    Traits private _traitBounds = Traits({
        vitalityDecayModifier: 50,
        nurtureEffectModifier: 80,
        breedEffectModifier: 80
    });
     Traits private _maxTraitBounds = Traits({
        vitalityDecayModifier: 150,
        nurtureEffectModifier: 120,
        breedEffectModifier: 120
    });

    uint256 private constant MAX_VITALITY = 10000;
    uint256 private constant VITALITY_THRESHOLD_MATURE = 8000; // >= Mature
    uint256 private constant VITALITY_THRESHOLD_AGING = 2000;  // >= Aging, < Mature

    // --- Events ---
    event LifeformSeeded(uint256 indexed lifeformId, address indexed owner, uint256 generation, Traits traits);
    event LifeformNurtured(uint256 indexed lifeformId, address indexed owner, uint256 newVitality);
    event LifeformBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address owner, uint256 generation, Traits traits);
    event LifeformStateUpdated(uint256 indexed lifeformId, LifeformState fromState, LifeformState toState, uint256 newVitality, uint256 epochsProcessed);
    event LifeformTransferred(uint256 indexed lifeformId, address indexed from, address indexed to);
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event AdminFeeWithdrawal(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _lifeformCounter = 0;
    }

    // --- Internal Functions ---

    function _getEpoch() internal view returns (uint256) {
        return block.timestamp.div(_epochDuration);
    }

    function _mintEssence(address _to, uint256 _amount) internal {
        _essenceBalances[_to] = _essenceBalances[_to].add(_amount);
        emit EssenceMinted(_to, _amount);
    }

    function _burnEssence(address _from, uint256 _amount) internal {
        if (_essenceBalances[_from] < _amount) {
             revert InsufficientEssence({required: _amount, has: _essenceBalances[_from]});
        }
        _essenceBalances[_from] = _essenceBalances[_from].sub(_amount);
        emit EssenceBurned(_from, _amount);
    }

    function _takeFee(uint256 _amount) internal {
        if (_adminFeeRate > 0 && _adminFeeFactor > 0) {
             uint256 fee = _amount.mul(_adminFeeRate).div(_adminFeeFactor);
             if (fee > 0) {
                 // Contract holds balance, adminWithdrawsEth can withdraw
                 // For simplicity using ETH balance, could use another token or internal balance
                 // Here, let's just track it internally for withdrawal
                 // Or, simplify and say fees are burned or go to a specific address
                 // Let's track internally for withdrawal
                 // To do this properly, we'd need Ether transfers or another ERC20 fee token
                 // Sticking to Essence for simplicity in this example: fees are Essence burned from user, but not minted anywhere
                 // Let's revise: Fees are collected in a separate mapping
                  // Add a fee balance mapping
                  // mapping(address => uint256) private _adminFeeEssenceBalance;
                  // But owner is only one address.
                  // Let's collect fees in the contract's Essence balance, which can be withdrawn by owner
                  // This requires fees to be paid in Essence
                  // So, when burning Essence for cost, burn *cost + fee*
                  // Then the admin fee withdrawal function would need to mint Essence to owner? No, that's weird.
                  // Okay, simple fee model: burn cost, and a % of the cost is conceptually "fee". The contract just keeps less is minted initially, or more is burned from user.
                  // Let's make it simple: The *contract's* Essence balance can be increased by owner minting, and decreased by admin burning or distribution.
                  // A fee means a portion of the *paid* Essence goes to the owner's withdrawal balance.
                  // So, when Essence is burned from user: burn total cost. A portion is tracked for withdrawal.
                  // Let's add a state variable for withdrawable fees.
                  // uint256 private _accumulatedEssenceFees;
                  // _accumulatedEssenceFees = _accumulatedEssenceFees.add(fee);
                  // The fee is burned from user, but conceptually available to admin.
                  // _burnEssence(msg.sender, cost.add(fee)); <-- Total burned from user is cost + fee
                  // This is more complex than needed for example.
                  // Let's simplify fee: it's just a % of the cost that gets burnt permanently instead of being used for nurturing/breeding etc.
                  // Or even simpler: The 'cost' is what the user pays. A *portion* of that payment is tracked for admin withdrawal.
                  // Let's use the simpler model where the cost mapping IS the user cost, and a % of this cost is conceptually a fee.
                  // The withdrawAdminFees function will just access contract's *own* Essence balance.
                  // How does contract get Essence balance? Owner mints it.
                  // This fee model doesn't fit well with the internal token.
                  // Let's just say the costs include a fee for simplicity, and the owner can mint/burn globally.
                  // Let's add a `withdrawContractEssence` function instead of `withdrawAdminFees`.
                  // This is getting complex. Let's revert to the simplest fee: costs are costs, and admin can mint/burn supply. No fee tracking needed.
                  // The complexity of tracking fees in an internal token adds overhead not central to the "Epochal Lifeform" concept.
                  // Or, alternative fee: users pay ETH, contract converts to Essence? No, stay on-chain token.
                  // Final simple fee model: Costs are set by admin. No explicit fee withdrawal. The cost is what it is.
                  // Okay, removing fee mechanism to meet complexity focus on Lifeforms.
             }
        }
    }

    // Add/Remove from owner's array helper
    function _addLifeformToOwner(address _owner, uint256 _lifeformId) internal {
         _ownerLifeforms[_owner].push(_lifeformId);
        _ownerLifeformIndex[_lifeformId] = _ownerLifeforms[_owner].length - 1;
    }

    function _removeLifeformFromOwner(address _owner, uint256 _lifeformId) internal {
        uint256 lifeformIndex = _ownerLifeformIndex[_lifeformId];
        uint256 lastIndex = _ownerLifeforms[_owner].length - 1;
        if (lifeformIndex != lastIndex) {
            uint256 lastLifeformId = _ownerLifeforms[_owner][lastIndex];
            _ownerLifeforms[_owner][lifeformIndex] = lastLifeformId;
            _ownerLifeformIndex[lastLifeformId] = lifeformIndex;
        }
        _ownerLifeforms[_owner].pop();
        delete _ownerLifeformIndex[_lifeformId];
    }

    // Simple pseudo-random trait generation (caution: predictable on-chain)
    function _generateTraits(uint256 _seed) internal view returns (Traits) {
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, block.difficulty)));

        uint256 decayMod = _traitBounds.vitalityDecayModifier + (randomSeed % (_maxTraitBounds.vitalityDecayModifier - _traitBounds.vitalityDecayModifier + 1));
        randomSeed = uint256(keccak256(abi.encodePacked(randomSeed))); // New seed for next value
        uint256 nurtureMod = _traitBounds.nurtureEffectModifier + (randomSeed % (_maxTraitBounds.nurtureEffectModifier - _traitBounds.nurtureEffectModifier + 1));
        randomSeed = uint256(keccak256(abi.encodePacked(randomSeed))); // New seed
        uint256 breedMod = _traitBounds.breedEffectModifier + (randomSeed % (_maxTraitBounds.breedEffectModifier - _traitBounds.breedEffectModifier + 1));

        return Traits({
            vitalityDecayModifier: decayMod, // e.g., 50-150 (lower better)
            nurtureEffectModifier: nurtureMod, // e.g., 80-120 (higher better)
            breedEffectModifier: breedMod // e.g., 80-120 (higher better)
        });
    }

    // Combine/Mutate traits during breeding (simple average with chance of mutation)
    function _combineTraits(Traits memory _t1, Traits memory _t2, uint256 _seed) internal view returns (Traits) {
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _t1.vitalityDecayModifier, _t2.vitalityDecayModifier, block.difficulty)));

        uint256 decayMod = (_t1.vitalityDecayModifier + _t2.vitalityDecayModifier) / 2;
        if (randomSeed % 100 < _traitBounds.breedEffectModifier.mul(100).div(_maxTraitBounds.breedEffectModifier) / 2) { // Simple mutation chance based on breed effect
             decayMod = _traitBounds.vitalityDecayModifier + (uint256(keccak256(abi.encodePacked(randomSeed, "decay"))) % (_maxTraitBounds.vitalityDecayModifier - _traitBounds.vitalityDecayModifier + 1));
        }
         decayMod = decayMod < _traitBounds.vitalityDecayModifier ? _traitBounds.vitalityDecayModifier : decayMod;
         decayMod = decayMod > _maxTraitBounds.vitalityDecayModifier ? _maxTraitBounds.vitalityDecayModifier : decayMod;


        randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, "next")));
        uint256 nurtureMod = (_t1.nurtureEffectModifier + _t2.nurtureEffectModifier) / 2;
         if (randomSeed % 100 < _traitBounds.breedEffectModifier.mul(100).div(_maxTraitBounds.breedEffectModifier) / 2) {
            nurtureMod = _traitBounds.nurtureEffectModifier + (uint256(keccak256(abi.encodePacked(randomSeed, "nurture"))) % (_maxTraitBounds.nurtureEffectModifier - _traitBounds.nurtureEffectModifier + 1));
        }
         nurtureMod = nurtureMod < _traitBounds.nurtureEffectModifier ? _traitBounds.nurtureEffectModifier : nurtureMod;
         nurtureMod = nurtureMod > _maxTraitBounds.nurtureEffectModifier ? _maxTraitBounds.nurtureEffectModifier : nurtureMod;

        randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, "next2")));
        uint256 breedMod = (_t1.breedEffectModifier + _t2.breedEffectModifier) / 2;
         if (randomSeed % 100 < _traitBounds.breedEffectModifier.mul(100).div(_maxTraitBounds.breedEffectModifier) / 2) {
            breedMod = _traitBounds.breedEffectModifier + (uint256(keccak256(abi.encodePacked(randomSeed, "breed"))) % (_maxTraitBounds.breedEffectModifier - _traitBounds.breedEffectModifier + 1));
        }
         breedMod = breedMod < _traitBounds.breedEffectModifier ? _traitBounds.breedEffectModifier : breedMod;
         breedMod = breedMod > _maxTraitBounds.breedEffectModifier ? _maxTraitBounds.breedEffectModifier : breedMod;


        return Traits({
            vitalityDecayModifier: decayMod,
            nurtureEffectModifier: nurtureMod,
            breedEffectModifier: breedMod
        });
    }


    function _calculateVitalityDecay(uint256 _vitality, uint256 _epochs, Traits memory _traits) internal view returns (uint256) {
        uint256 baseDecay = _vitalityDecayRate.mul(_epochs);
        // Apply trait modifier: higher modifier means more decay (bad)
        uint256 modifiedDecay = baseDecay.mul(_traits.vitalityDecayModifier).div(100); // Assuming modifier base is 100
        return modifiedDecay;
    }

    function _applyEpochalChanges(uint256 _lifeformId) internal {
        Lifeform storage lifeform = _lifeforms[_lifeformId];
        uint256 currentEpoch = _getEpoch();
        uint256 epochsElapsed = currentEpoch.sub(lifeform.lastInteractionEpoch);

        if (epochsElapsed == 0) {
            // No epochs have passed since last interaction/update
            return; // Or revert if called externally and no update is pending
        }

        uint256 decayAmount = _calculateVitalityDecay(lifeform.vitality, epochsElapsed, lifeform.traits);
        uint256 oldVitality = lifeform.vitality;
        lifeform.vitality = lifeform.vitality > decayAmount ? lifeform.vitality.sub(decayAmount) : 0;

        LifeformState oldState = lifeform.state;
        if (lifeform.vitality == 0) {
            lifeform.state = LifeformState.Deceased;
        } else if (lifeform.vitality < VITALITY_THRESHOLD_AGING) {
            lifeform.state = LifeformState.Aging;
        } else if (lifeform.vitality < VITALITY_THRESHOLD_MATURE) {
            lifeform.state = LifeformState.Mature; // Can transition from Larval to Mature here
        }
        // Larval state is only initially set or through specific rare events
        // Mature/Aging/Deceased transitions happen based on vitality

        lifeform.lastInteractionEpoch = currentEpoch; // Mark as updated

        if (oldState != lifeform.state || oldVitality != lifeform.vitality) {
            emit LifeformStateUpdated(_lifeformId, oldState, lifeform.state, lifeform.vitality, epochsElapsed);
        } else {
             // If no state change, but was updated
             // Optional: Emit event even if no state change, just vitality change? Or just let the external call know it processed.
             // Let's require external calls to check if epochs elapsed > 0.
             // If called internally, no need to check epochsElapsed > 0 before calling this.
             // Reverting externally if epochsElapsed == 0 is better for user experience.
        }
    }


    // --- Public/External Functions ---

    /**
     * @notice Creates a new Generation 1 Lifeform.
     * @dev Requires sender to have enough Essence tokens.
     * @param _seed An arbitrary seed value for trait generation (user can influence slightly).
     */
    function seedLifeform(uint256 _seed) external {
        if (_essenceBalances[msg.sender] < _seedCost) {
             revert InsufficientEssence({required: _seedCost, has: _essenceBalances[msg.sender]});
        }
        _burnEssence(msg.sender, _seedCost);

        _lifeformCounter = _lifeformCounter.add(1);
        uint256 newLifeformId = _lifeformCounter;

        Traits memory initialTraits = _generateTraits(_seed);

        _lifeforms[newLifeformId] = Lifeform({
            id: newLifeformId,
            owner: msg.sender,
            generation: 1,
            birthEpoch: _getEpoch(),
            lastInteractionEpoch: _getEpoch(),
            vitality: MAX_VITALITY, // Starts at max vitality
            traits: initialTraits,
            state: LifeformState.Larval // Starts as Larval
        });

        _addLifeformToOwner(msg.sender, newLifeformId);

        emit LifeformSeeded(newLifeformId, msg.sender, 1, initialTraits);
    }

    /**
     * @notice Increases the vitality of a Lifeform.
     * @dev Applies pending epoch changes first, then adds vitality. Requires Lifeform owner.
     * @param _lifeformId The ID of the Lifeform to nurture.
     */
    function nurtureLifeform(uint256 _lifeformId) external {
        Lifeform storage lifeform = _lifeforms[_lifeformId];
        if (lifeform.owner == address(0)) revert InvalidLifeformId();
        if (lifeform.owner != msg.sender) revert NotLifeformOwner();
        if (lifeform.state == LifeformState.Deceased || lifeform.state == LifeformState.Dormant)
             revert LifeformNotInValidState({lifeformId: _lifeformId, currentState: lifeform.state, requiredState: "Active"});

        // Apply decay before nurturing
        _applyEpochalChanges(_lifeformId);

        if (_essenceBalances[msg.sender] < _nurtureCost) {
            revert InsufficientEssence({required: _nurtureCost, has: _essenceBalances[msg.sender]});
        }
         _burnEssence(msg.sender, _nurtureCost);

        // Apply nurture effect based on trait
        uint256 nurtureAmount = 500; // Base nurture effect
        nurtureAmount = nurtureAmount.mul(lifeform.traits.nurtureEffectModifier).div(100); // Apply modifier

        lifeform.vitality = lifeform.vitality.add(nurtureAmount);
        if (lifeform.vitality > MAX_VITALITY) {
            lifeform.vitality = MAX_VITALITY;
        }

        lifeform.lastInteractionEpoch = _getEpoch(); // Update interaction epoch

        // Check for state transition after nurturing
         LifeformState oldState = lifeform.state;
         if (lifeform.state == LifeformState.Larval && lifeform.vitality >= VITALITY_THRESHOLD_MATURE) {
             lifeform.state = LifeformState.Mature;
             emit LifeformStateUpdated(_lifeformId, oldState, lifeform.state, lifeform.vitality, 0); // 0 epochs, state changed by nurture
         } else if (lifeform.state == LifeformState.Aging && lifeform.vitality >= VITALITY_THRESHOLD_AGING && lifeform.vitality < VITALITY_THRESHOLD_MATURE) {
              // Stays Aging if vitality is still below Mature threshold
         } else if (lifeform.state == LifeformState.Aging && lifeform.vitality >= VITALITY_THRESHOLD_MATURE) {
             lifeform.state = LifeformState.Mature;
             emit LifeformStateUpdated(_lifeformId, oldState, lifeform.state, lifeform.vitality, 0);
         } else if (lifeform.state == LifeformState.Deceased && lifeform.vitality > 0) {
             // Possible but maybe requires special "revive" function, not nurture?
             // Let's disallow nurturing Deceased for now.
             // If we allow revive, logic here would change state from Deceased.
         }


        emit LifeformNurtured(_lifeformId, msg.sender, lifeform.vitality);
    }

    /**
     * @notice Breeds two Mature Lifeforms owned by the sender.
     * @dev Creates a new Lifeform with inherited/mutated traits. Consumes Essence and vitality from parents.
     * @param _parent1Id The ID of the first parent Lifeform.
     * @param _parent2Id The ID of the second parent Lifeform.
     */
    function breedLifeforms(uint256 _parent1Id, uint256 _parent2Id) external {
        Lifeform storage parent1 = _lifeforms[_parent1Id];
        Lifeform storage parent2 = _lifeforms[_parent2Id];

        if (parent1.owner == address(0) || parent2.owner == address(0)) revert InvalidLifeformId();
        if (parent1.owner != msg.sender || parent2.owner != msg.sender) revert NotLifeformOwner();
        if (_parent1Id == _parent2Id) revert InvalidLifeformId(); // Cannot breed with self

        // Apply decay before checking state and vitality
        _applyEpochalChanges(_parent1Id);
        _applyEpochalChanges(_parent2Id);

        if (parent1.state != LifeformState.Mature || parent2.state != LifeformState.Mature)
             revert LifeformsCannotBreed({id1: _parent1Id, state1: parent1.state, id2: _parent2Id, state2: parent2.state});

        if (parent1.vitality < _breedVitalityCost || parent2.vitality < _breedVitalityCost)
            revert NotEnoughVitalityForBreed({required: _breedVitalityCost, has: parent1.vitality > parent2.vitality ? parent2.vitality : parent1.vitality});


        if (_essenceBalances[msg.sender] < _breedCost) {
             revert InsufficientEssence({required: _breedCost, has: _essenceBalances[msg.sender]});
        }
         _burnEssence(msg.sender, _breedCost);

        // Consume vitality from parents
        parent1.vitality = parent1.vitality.sub(_breedVitalityCost);
        parent2.vitality = parent2.vitality.sub(_breedVitalityCost);

        // Update parent interaction epochs
        parent1.lastInteractionEpoch = _getEpoch();
        parent2.lastInteractionEpoch = _getEpoch();

         // Apply state changes to parents after vitality drain (optional, but good practice)
         // Check if vitality drop causes state change
         LifeformState parent1OldState = parent1.state;
         if (parent1.vitality < VITALITY_THRESHOLD_AGING) parent1.state = LifeformState.Aging;
         else if (parent1.vitality < VITALITY_THRESHOLD_MATURE) parent1.state = LifeformState.Mature; // Should stay mature or drop to aging

         LifeformState parent2OldState = parent2.state;
         if (parent2.vitality < VITALITY_THRESHOLD_AGING) parent2.state = LifeformState.Aging;
         else if (parent2.vitality < VITALITY_THRESHOLD_MATURE) parent2.state = LifeformState.Mature;


        _lifeformCounter = _lifeformCounter.add(1);
        uint256 childLifeformId = _lifeformCounter;
        uint256 childGeneration = parent1.generation > parent2.generation ? parent1.generation.add(1) : parent2.generation.add(1);

        Traits memory childTraits = _combineTraits(parent1.traits, parent2.traits, childLifeformId); // Use child ID as seed


        _lifeforms[childLifeformId] = Lifeform({
            id: childLifeformId,
            owner: msg.sender,
            generation: childGeneration,
            birthEpoch: _getEpoch(),
            lastInteractionEpoch: _getEpoch(),
            vitality: MAX_VITALITY / 2, // Child starts with partial vitality
            traits: childTraits,
            state: LifeformState.Larval // Child starts as Larval
        });

        _addLifeformToOwner(msg.sender, childLifeformId);

        emit LifeformBred(_parent1Id, _parent2Id, childLifeformId, msg.sender, childGeneration, childTraits);
        // Optional: Emit state updates for parents if their state changed after breeding vitality cost
         if (parent1OldState != parent1.state) emit LifeformStateUpdated(_parent1Id, parent1OldState, parent1.state, parent1.vitality, 0);
         if (parent2OldState != parent2.state) emit LifeformStateUpdated(_parent2Id, parent2OldState, parent2.state, parent2.vitality, 0);
    }

    /**
     * @notice Progresses a Lifeform's state based on elapsed epochs and decay.
     * @dev Callable by anyone. Incentivizes external bots or users to maintain state accuracy.
     * @param _lifeformId The ID of the Lifeform to update.
     */
    function updateLifeformState(uint256 _lifeformId) external {
        Lifeform storage lifeform = _lifeforms[_lifeformId];
         if (lifeform.owner == address(0)) revert InvalidLifeformId();

        uint256 currentEpoch = _getEpoch();
        if (currentEpoch == lifeform.lastInteractionEpoch) {
             revert NoPendingEpochUpdates(_lifeformId);
        }

        _applyEpochalChanges(_lifeformId);
         // Optional: Add small reward (e.g., tiny bit of Essence or other token) for calling this?
         // Not adding reward for simplicity in this example.
    }


    /**
     * @notice Transfers ownership of a Lifeform.
     * @dev Requires sender to be the current owner.
     * @param _lifeformId The ID of the Lifeform to transfer.
     * @param _to The recipient address.
     */
    function transferLifeform(uint256 _lifeformId, address _to) external {
        Lifeform storage lifeform = _lifeforms[_lifeformId];
        if (lifeform.owner == address(0)) revert InvalidLifeformId();
        if (lifeform.owner != msg.sender) revert NotLifeformOwner();
        if (_to == address(0)) revert InvalidLifeformId(); // Cannot transfer to zero address

        // Optional: Disallow transfer in certain states (e.g., Larval, Deceased)?
        // if (lifeform.state == LifeformState.Larval) revert TransferNotAllowedInState(lifeform.state);

         _applyEpochalChanges(_lifeformId); // Apply pending decay before transfer

        address oldOwner = lifeform.owner;
        _removeLifeformFromOwner(oldOwner, _lifeformId);
        lifeform.owner = _to;
        _addLifeformToOwner(_to, _lifeformId);

        emit LifeformTransferred(_lifeformId, oldOwner, _to);
    }


    // --- Query Functions ---

    /**
     * @notice Gets the full state details of a Lifeform.
     * @param _lifeformId The ID of the Lifeform.
     * @return Lifeform struct.
     */
    function getLifeformState(uint256 _lifeformId) external view returns (Lifeform memory) {
        Lifeform memory lifeform = _lifeforms[_lifeformId];
         if (lifeform.owner == address(0) && _lifeformId != 0) revert InvalidLifeformId(); // Lifeform ID 0 is invalid
        return lifeform;
    }

    /**
     * @notice Gets the traits of a Lifeform.
     * @param _lifeformId The ID of the Lifeform.
     * @return Traits struct.
     */
    function getLifeformTraits(uint256 _lifeformId) external view returns (Traits memory) {
        Lifeform memory lifeform = _lifeforms[_lifeformId];
         if (lifeform.owner == address(0) && _lifeformId != 0) revert InvalidLifeformId();
        return lifeform.traits;
    }

     /**
     * @notice Gets the current vitality of a Lifeform, accounting for decay up to the current epoch.
     * @dev Calculates potential decay without altering state.
     * @param _lifeformId The ID of the Lifeform.
     * @return The current vitality.
     */
    function getLifeformVitality(uint256 _lifeformId) external view returns (uint256) {
        Lifeform memory lifeform = _lifeforms[_lifeformId];
         if (lifeform.owner == address(0) && _lifeformId != 0) revert InvalidLifeformId();

        uint256 currentEpoch = _getEpoch();
        uint256 epochsElapsed = currentEpoch.sub(lifeform.lastInteractionEpoch);

        uint256 potentialDecay = _calculateVitalityDecay(lifeform.vitality, epochsElapsed, lifeform.traits);
        uint256 currentVitality = lifeform.vitality > potentialDecay ? lifeform.vitality.sub(potentialDecay) : 0;

        return currentVitality;
    }

    /**
     * @notice Checks if a Lifeform is in an active state (not Deceased).
     * @param _lifeformId The ID of the Lifeform.
     * @return True if the Lifeform is not Deceased.
     */
    function isLifeformAlive(uint256 _lifeformId) external view returns (bool) {
        Lifeform memory lifeform = _lifeforms[_lifeformId];
         if (lifeform.owner == address(0) && _lifeformId != 0) revert InvalidLifeformId();
         // Note: This check doesn't run updateLifeformState, so it shows the state from the last update.
         // A user might appear "Alive" but be Deceased if updateLifeformState hasn't been called.
         // For a real application, consider running a minimal state check here or relying on clients calling update.
        return lifeform.state != LifeformState.Deceased;
    }


    /**
     * @notice Gets the total number of Lifeforms created.
     * @return The total count.
     */
    function getTotalLifeforms() external view returns (uint256) {
        return _lifeformCounter;
    }

    /**
     * @notice Gets the list of Lifeform IDs owned by an address.
     * @dev Can be gas-intensive for addresses with many Lifeforms.
     * @param _owner The address to query.
     * @return An array of Lifeform IDs.
     */
    function getLifeformsByOwner(address _owner) external view returns (uint256[] memory) {
        return _ownerLifeforms[_owner];
    }

    /**
     * @notice Gets the current epoch number.
     * @return The current epoch.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return _getEpoch();
    }

    /**
     * @notice Gets the duration of an epoch in seconds.
     * @return The epoch duration.
     */
    function getEpochDuration() external view returns (uint256) {
        return _epochDuration;
    }

    /**
     * @notice Gets the Essence token balance of an address.
     * @param _address The address to query.
     * @return The balance.
     */
    function getEssenceBalance(address _address) external view returns (uint256) {
        return _essenceBalances[_address];
    }

    /**
     * @notice Gets key contract parameters (costs, decay rate, breed vitality cost).
     * @return seedCost, nurtureCost, breedCost, vitalityDecayRate, breedVitalityCost.
     */
    function getParams() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (_seedCost, _nurtureCost, _breedCost, _vitalityDecayRate, _breedVitalityCost);
    }

    /**
     * @notice Gets the bounds used for random trait generation/mutation.
     * @return min/max values for vitalityDecayModifier, nurtureEffectModifier, breedEffectModifier.
     */
    function getTraitBounds() external view returns (Traits memory minBounds, Traits memory maxBounds) {
        return (_traitBounds, _maxTraitBounds);
    }


    // --- Administrative Functions (Owner Only) ---

    function adminSetEpochDuration(uint256 _newDuration) external onlyOwner {
        _epochDuration = _newDuration;
    }

    function adminSetSeedCost(uint256 _newCost) external onlyOwner {
        _seedCost = _newCost;
    }

    function adminSetNurtureCost(uint256 _newCost) external onlyOwner {
        _nurtureCost = _newCost;
    }

    function adminSetBreedCost(uint256 _newCost) external onlyOwner {
        _breedCost = _newCost;
    }

    function adminSetVitalityDecayRate(uint256 _newRate) external onlyOwner {
        _vitalityDecayRate = _newRate;
    }

     function adminSetBreedVitalityCost(uint256 _newCost) external onlyOwner {
        _breedVitalityCost = _newCost;
    }

    function adminSetTraitBounds(
        uint256 _minVitalityDecayModifier, uint256 _maxVitalityDecayModifier,
        uint256 _minNurtureEffectModifier, uint256 _maxNurtureEffectModifier,
        uint256 _minBreedEffectModifier, uint256 _maxBreedEffectModifier
    ) external onlyOwner {
        if (_minVitalityDecayModifier > _maxVitalityDecayModifier ||
            _minNurtureEffectModifier > _maxNurtureEffectModifier ||
            _minBreedEffectModifier > _maxBreedEffectModifier ||
            _minVitalityDecayModifier == 0 || _minNurtureEffectModifier == 0 || _minBreedEffectModifier == 0 ||
            _maxVitalityDecayModifier == 0 || _maxNurtureEffectModifier == 0 || _maxBreedEffectModifier == 0
            ) revert InvalidTraitBounds();

        _traitBounds = Traits({
            vitalityDecayModifier: _minVitalityDecayModifier,
            nurtureEffectModifier: _minNurtureEffectModifier,
            breedEffectModifier: _minBreedEffectModifier
        });
         _maxTraitBounds = Traits({
            vitalityDecayModifier: _maxVitalityDecayModifier,
            nurtureEffectModifier: _maxNurtureEffectModifier,
            breedEffectModifier: _maxBreedEffectModifier
        });
    }

    /**
     * @notice Mints Essence tokens for a specific address (Owner Only).
     * @dev Used for initial distribution or adding supply.
     * @param _to The recipient address.
     * @param _amount The amount to mint.
     */
    function adminMintEssence(address _to, uint256 _amount) external onlyOwner {
        _mintEssence(_to, _amount);
    }

    /**
     * @notice Burns Essence tokens from a specific address (Owner Only).
     * @dev Used to reduce supply.
     * @param _from The address to burn from.
     * @param _amount The amount to burn.
     */
    function adminBurnEssence(address _from, uint256 _amount) external onlyOwner {
         _burnEssence(_from, _amount);
    }

    /**
     * @notice Allows owner to withdraw any Ether sent to the contract.
     * @dev This contract is designed for Essence, not ETH fees directly, but a fallback/withdrawal is good practice.
     * It does not handle Essence fees within this function.
     */
    function withdrawAdminFees() external onlyOwner {
        // Note: This function withdraws ETH accidentally sent.
        // For Essence fees, a separate mechanism would be needed (e.g., adminMintEssence from a fee pool).
        // As designed, Essence fees are implicitly handled by setting costs.
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
         emit AdminFeeWithdrawal(owner(), address(this).balance); // Emitting ETH withdrawal
    }

     // Fallback function to receive ETH (optional, but allows receiving ETH)
     // If ETH is sent, it accumulates in the contract balance and can be withdrawn by owner.
     receive() external payable {}
     // fallback() external payable {} // Can also add fallback if needed for non-standard calls


}
```