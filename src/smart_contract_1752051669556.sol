Okay, here is a Solidity smart contract concept that attempts to be interesting, advanced, creative, and avoids duplicating common open-source patterns. It's based on abstract "Realms" with complex, state-dependent, and probabilistic interactions driven by different "Essence" types.

It includes concepts like:
1.  **Abstract Resources:** Different types of "Essence" (`Aether`, `Chronon`, `Void`, `Gleam`).
2.  **Stateful Entities:** "Realms" with different states (`Pure`, `Unstable`, `Collapsed`, `Entangled`, `Dormant`).
3.  **Probabilistic Outcomes:** Using block data and internal state to introduce pseudo-randomness for interaction results and state changes.
4.  **State Transitions:** Interactions can cause realms to change states based on probabilities and requirements.
5.  **Entanglement:** Linking two realms where interactions with one can affect the other.
6.  **Resource Synthesis/Harvesting:** Users can harvest essence from realms or synthesize new essence types.
7.  **Prediction Helper:** A `view` function to help users understand the *potential* outcome probabilities of interactions before committing gas.
8.  **Complex Interaction Logic:** The core interaction function considers multiple factors (realm state, essence used, global parameters, internal probability).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * QuantumRealm: An Abstract State-Based Interaction Engine
 *
 * This contract simulates an abstract environment of 'Realms' and 'Essences'.
 * Users interact with Realms using different types of Essence.
 * Realms have various 'States' (Pure, Unstable, Collapsed, Entangled, Dormant)
 * and interacting with them can consume Essence, yield new Essence, and
 * probabilistically change the Realm's State based on complex internal rules.
 * Realms can become 'Entangled', where interactions with one may affect the other.
 *
 * Concepts:
 * - Essence: Abstract resources (Aether, Chronon, Void, Gleam) held by users.
 * - Realms: Stateful entities with unique IDs, properties (yields, requirements),
 *           and a current state.
 * - States: Different modes for a Realm influencing interaction outcomes.
 * - Probability: Outcomes determined by a pseudo-random factor derived from
 *                block data and state variables.
 * - Entanglement: A link between two Realms affecting interaction outcomes.
 * - Synthesis: Converting one type of Essence into another.
 * - Harvesting: Collecting accrued yield from Realms.
 *
 * Disclaimer: This is a complex, experimental concept designed to explore
 * advanced Solidity features and patterns. It is not production-ready,
 * has not been audited, and may contain significant bugs or security vulnerabilities.
 * The probabilistic logic is pseudo-random and should NOT be used for
 * high-value applications requiring true unpredictability or fairness against
 * sophisticated attackers (e.g., casino games). Miners can influence block data.
 */

/*
 * Contract Outline:
 *
 * 1. Enums
 * 2. Structs
 * 3. State Variables
 * 4. Events
 * 5. Modifiers
 * 6. Probability Helpers (Internal & View)
 * 7. Admin/Setup Functions (Owner only)
 * 8. Core User Interaction Functions
 * 9. Essence Management Functions
 * 10. Realm Management Functions
 * 11. Read-Only Functions (View/Pure)
 */

/*
 * Function Summary:
 *
 * Admin/Setup Functions (Requires Ownership):
 * 1. constructor(): Initializes the contract owner and sets initial parameters.
 * 2. transferOwnership(address newOwner): Transfers contract ownership.
 * 3. setEssenceYieldParams(uint256 realmId, EssenceType[] essenceTypes, uint256[] amounts): Sets the yield amounts for specific essence types from a realm upon successful interaction.
 * 4. setEssenceRequirementParams(uint256 realmId, EssenceType[] essenceTypes, uint256[] amounts): Sets the essence required for interacting with a realm.
 * 5. setGlobalProbabilityFactor(uint256 factor): Sets a global factor influencing probabilistic outcomes. Higher factor means probabilities are scaled.
 * 6. setStateTransitionProbability(RealmState fromState, RealmState toState, uint256 probabilityBasis): Sets the base probability (out of 10000) for a specific state transition.
 * 7. withdrawEther(): Allows the owner to withdraw accumulated Ether (e.g., from realm creation fees).
 *
 * Core User Interaction Functions:
 * 8. createRealm(uint256 initialProbabilityFactor): Allows a user to create a new realm by paying a fee. Returns the new realm ID.
 * 9. interactWithRealm(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed): The main interaction function. Consumes essence, applies probabilistic logic based on realm state and parameters, potentially yields essence and changes realm state.
 * 10. attemptStateCollapse(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed): User explicitly tries to collapse an Unstable realm to Collapsed. Probabilistic outcome.
 * 11. attemptEntangleRealm(uint256 realmId1, uint256 realmId2, EssenceType essenceUsed, uint256 amountUsed): Attempts to create an entanglement link between two realms. Probabilistic outcome. Requires realms to be in specific states (e.g., Pure, Unstable).
 * 12. breakEntanglement(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed): Attempts to break an existing entanglement link from a realm. Probabilistic outcome.
 * 13. harvestEssenceFromRealm(uint256 realmId): Allows a user to collect accumulated yield essence from a realm (yield accumulates during interactions).
 * 14. synthesizeEssence(EssenceType inputType, uint256 inputAmount, EssenceType outputType): Allows a user to convert input essence into output essence based on a fixed ratio. Burns input, mints output.
 * 15. sacrificeEssenceForProbabilityBoost(EssenceType essenceType, uint256 amount, uint256 durationBlocks): Allows a user to burn essence for a temporary, time-limited boost to interaction probabilities.
 *
 * Essence Management Functions:
 * 16. transferEssence(EssenceType essenceType, address recipient, uint256 amount): Allows a user to transfer essence to another address.
 * 17. burnEssence(EssenceType essenceType, uint256 amount): Allows a user to explicitly burn their essence.
 *
 * Realm Management Functions:
 * 18. mutateRealmProperties(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed, EssenceType targetEssence, uint256 newYieldAmount, uint256 newRequirementAmount): Attempts to change a specific yield or requirement property of a realm. Probabilistic.
 *
 * Read-Only Functions (View/Pure):
 * 19. predictInteractionOutcome(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed) view: Calculates and returns the potential outcomes (state change probabilities, yield amounts) for a given interaction *without* executing it. Uses current state and block data for simulation.
 * 20. getRealmDetails(uint256 realmId) view: Returns all details of a specific realm.
 * 21. getEssenceBalance(address account, EssenceType essenceType) view: Returns the essence balance for a specific account and essence type.
 * 22. getTotalEssenceSupply(EssenceType essenceType) view: Returns the total minted supply of a specific essence type.
 * 23. getEntangledRealm(uint256 realmId) view: Returns the ID of the realm entangled with the given realm (0 if none).
 * 24. getStateTransitionProbability(RealmState fromState, RealmState toState) view: Returns the base probability basis for a specific state transition.
 * 25. getGlobalProbabilityFactor() view: Returns the current global probability factor.
 */

contract QuantumRealm {

    // --- 1. Enums ---
    enum EssenceType { Aether, Chronon, Void, Gleam }
    enum RealmState { Pure, Unstable, Collapsed, Entangled, Dormant }

    // --- 2. Structs ---
    struct Realm {
        uint256 id;
        RealmState currentState;
        mapping(EssenceType => uint256) essenceRequirements;
        mapping(EssenceType => uint256) essenceYields;
        uint256 entangledRealmId; // 0 if not entangled
        uint256 creationBlock;
        uint256 lastInteractionBlock;
        uint256 probabilityFactor; // Realm-specific factor
        mapping(EssenceType => uint256) accumulatedYield; // Yield waiting to be harvested
        uint256 interactionCount; // Nonce for probability calculation
    }

    // --- 3. State Variables ---
    address private _owner;
    uint256 private _nextRealmId = 1;

    mapping(uint256 => Realm) private _realms;
    mapping(address => mapping(EssenceType => uint256)) private _essenceBalances;
    mapping(EssenceType => uint256) private _totalEssenceSupply;

    uint256 private _globalProbabilityFactor; // Base factor influencing all probabilities

    // Base probability for state transitions (basis points out of 10000)
    mapping(RealmState => mapping(RealmState => uint256)) private _stateTransitionProbabilities;

    uint256 private _realmCreationFee = 0.01 ether; // Example fee
    uint256 private constant ESSENCE_SYNTHESIS_RATIO = 2; // 2 input essence for 1 output

    // Temporary probability boosts for users
    mapping(address => uint256) private _userProbabilityBoostEndBlock;
    mapping(address => uint256) private _userProbabilityBoostFactor; // Added factor

    // Nonce for probability calculation within the same block
    mapping(address => uint256) private _userInteractionCount;

    // --- 4. Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RealmCreated(uint256 indexed realmId, address indexed creator, uint256 creationBlock);
    event EssenceHarvested(uint256 indexed realmId, address indexed user, EssenceType essenceType, uint256 amount);
    event RealmStateChanged(uint256 indexed realmId, RealmState indexed oldState, RealmState indexed newState);
    event EssenceSynthesized(address indexed user, EssenceType indexed inputType, uint256 inputAmount, EssenceType indexed outputType, uint256 outputAmount);
    event EssenceTransferred(address indexed from, address indexed to, EssenceType indexed essenceType, uint256 amount);
    event EssenceBurned(address indexed user, EssenceType indexed essenceType, uint256 amount);
    event InteractedWithRealm(uint256 indexed realmId, address indexed user, EssenceType indexed essenceUsed, uint256 amountUsed, uint256 outcomeEntropy);
    event ProbabilityBoostUsed(address indexed user, EssenceType indexed essenceSacrificed, uint256 amount, uint256 boostEndBlock);
    event RealmPropertiesMutated(uint256 indexed realmId, address indexed user, EssenceType indexed targetEssence, uint256 newYield, uint256 newRequirement, bool success);
    event RealmEntangled(uint256 indexed realmId1, uint256 indexed realmId2, address indexed user);
    event RealmDisentangled(uint256 indexed realmId, address indexed user);

    // --- 5. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyRealmExists(uint256 realmId) {
        require(_realms[realmId].id != 0, "Realm does not exist");
        _;
    }

    // --- 6. Probability Helpers ---

    /// @notice Calculates a pseudo-random factor based on block data, sender, state nonces, and realm/global factors.
    /// @param realmId The ID of the realm involved (0 if not realm-specific).
    /// @return uint256 A derived pseudo-random number.
    function _calculateEntropy(uint256 realmId) internal returns (uint256) {
        uint256 realmNonce = _realms[realmId].interactionCount;
        uint256 userNonce = _userInteractionCount[msg.sender];

        // Increment nonces immediately before calculating entropy
        if (realmId != 0) {
             _realms[realmId].interactionCount++;
        }
        _userInteractionCount[msg.sender]++;

        // Mix various factors including block data and state-based nonces
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            blockhash(block.number > 0 ? block.number - 1 : block.number), // Use previous block hash if possible
            block.timestamp,
            msg.sender,
            realmId,
            realmNonce,
            userNonce,
            _globalProbabilityFactor,
            _realms[realmId].probabilityFactor // Use realm-specific factor if realmId is valid
        )));

        return entropy;
    }

    /// @notice Determines if an action succeeds based on entropy, base chance, and factors.
    /// @param entropy The pseudo-random number generated by _calculateEntropy.
    /// @param baseChanceBasis The base probability in basis points (e.g., 5000 for 50%).
    /// @param realmId The ID of the realm involved (0 if not realm-specific).
    /// @return bool True if the action succeeds probabilistically.
    function _checkProbabilisticSuccess(uint256 entropy, uint256 baseChanceBasis, uint256 realmId) internal view returns (bool) {
        uint256 effectiveFactor = _globalProbabilityFactor;
        if (realmId != 0 && _realms[realmId].id != 0) { // Add realm-specific factor if applicable
            effectiveFactor = (effectiveFactor * _realms[realmId].probabilityFactor) / 100; // Example scaling
        }

        // Add user boost if active
        if (block.number <= _userProbabilityBoostEndBlock[msg.sender]) {
             effectiveFactor = effectiveFactor + _userProbabilityBoostFactor[msg.sender];
        }

        // Scale the base chance by the effective factor
        uint256 scaledChance = (baseChanceBasis * effectiveFactor) / 100; // Scale probability

        // Ensure scaledChance doesn't exceed max basis points (10000)
        if (scaledChance > 10000) {
            scaledChance = 10000;
        }

        // Use the entropy to determine success (e.g., entropy % 10000 < scaledChance)
        return (entropy % 10000) < scaledChance;
    }

     /// @notice Calculates the effective probability chance for a given base probability, considering factors.
     /// @param baseChanceBasis The base probability in basis points (e.g., 5000 for 50%).
     /// @param realmId The ID of the realm involved (0 if not realm-specific).
     /// @param user The address of the user (for user boost calculation).
     /// @return uint256 The effective probability in basis points (max 10000).
     function calcEffectiveProbability(uint256 baseChanceBasis, uint256 realmId, address user) public view returns (uint256) {
        uint256 effectiveFactor = _globalProbabilityFactor;
        if (realmId != 0 && _realms[realmId].id != 0) {
            effectiveFactor = (effectiveFactor * _realms[realmId].probabilityFactor) / 100;
        }

        // Add user boost if active
        if (block.number <= _userProbabilityBoostEndBlock[user]) {
             effectiveFactor = effectiveFactor + _userProbabilityBoostFactor[user];
        }

        uint256 scaledChance = (baseChanceBasis * effectiveFactor) / 100;

        if (scaledChance > 10000) {
            scaledChance = 10000;
        }
        return scaledChance;
     }

     /// @notice Exposes the raw pseudo-random entropy for transparency.
     /// @param realmId The ID of the realm involved (0 if not realm-specific).
     /// @param user The address of the user.
     /// @param realmNonce The realm's interaction count.
     /// @param userNonce The user's interaction count.
     /// @return uint256 The calculated entropy value.
     function calcRawProbabilityEntropy(uint256 realmId, address user, uint256 realmNonce, uint256 userNonce) public view returns (uint256) {
         uint256 blockNum = block.number;
         uint256 prevBlockHash = (blockNum > 0 ? uint256(blockhash(blockNum - 1)) : 0); // Handle block 0

         uint256 entropy = uint256(keccak256(abi.encodePacked(
             prevBlockHash,
             block.timestamp,
             user,
             realmId,
             realmNonce,
             userNonce,
             _globalProbabilityFactor,
             _realms[realmId].id != 0 ? _realms[realmId].probabilityFactor : 0 // Include realm factor only if realm exists
         )));
         return entropy;
     }


    // --- 7. Admin/Setup Functions ---

    constructor(uint256 initialGlobalProbabilityFactor) payable {
        _owner = msg.sender;
        _globalProbabilityFactor = initialGlobalProbabilityFactor; // e.g., 100 for 1x scaling
        emit OwnershipTransferred(address(0), _owner);

        // Set some initial state transition probabilities (examples in basis points)
        _stateTransitionProbabilities[RealmState.Pure][RealmState.Unstable] = 2000; // 20%
        _stateTransitionProbabilities[RealmState.Unstable][RealmState.Collapsed] = 3000; // 30%
        _stateTransitionProbabilities[RealmState.Unstable][RealmState.Entangled] = 1000; // 10%
        _stateTransitionProbabilities[RealmState.Entangled][RealmState.Dormant] = 500; // 5%
         // Add more state transition probabilities as needed...
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setEssenceYieldParams(uint256 realmId, EssenceType[] essenceTypes, uint256[] amounts) public onlyOwner onlyRealmExists(realmId) {
        require(essenceTypes.length == amounts.length, "Array lengths must match");
        Realm storage realm = _realms[realmId];
        for (uint i = 0; i < essenceTypes.length; i++) {
            realm.essenceYields[essenceTypes[i]] = amounts[i];
        }
    }

    function setEssenceRequirementParams(uint256 realmId, EssenceType[] essenceTypes, uint256[] amounts) public onlyOwner onlyRealmExists(realmId) {
        require(essenceTypes.length == amounts.length, "Array lengths must match");
        Realm storage realm = _realms[realmId];
        for (uint i = 0; i < essenceTypes.length; i++) {
            realm.essenceRequirements[essenceTypes[i]] = amounts[i];
        }
    }

    function setGlobalProbabilityFactor(uint256 factor) public onlyOwner {
        _globalProbabilityFactor = factor;
    }

    function setStateTransitionProbability(RealmState fromState, RealmState toState, uint256 probabilityBasis) public onlyOwner {
        require(probabilityBasis <= 10000, "Probability basis cannot exceed 10000");
        _stateTransitionProbabilities[fromState][toState] = probabilityBasis;
    }

    function withdrawEther() public onlyOwner {
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Ether withdrawal failed");
    }

    // --- 8. Core User Interaction Functions ---

    function createRealm(uint256 initialProbabilityFactor) public payable returns (uint256) {
        require(msg.value >= _realmCreationFee, "Insufficient fee to create realm");

        uint256 newId = _nextRealmId++;
        Realm storage newRealm = _realms[newId];

        newRealm.id = newId;
        newRealm.currentState = RealmState.Pure; // New realms start Pure
        newRealm.creationBlock = block.number;
        newRealm.lastInteractionBlock = block.number; // Initialize
        newRealm.probabilityFactor = initialProbabilityFactor; // Set initial realm-specific factor
        newRealm.entangledRealmId = 0; // Not entangled initially
        newRealm.interactionCount = 0;

        // Example: Set some default requirements/yields for newly created realms
        // In a real system, these might be determined probabilistically or based on creation parameters
        newRealm.essenceRequirements[EssenceType.Aether] = 10;
        newRealm.essenceYields[EssenceType.Aether] = 5;
        newRealm.essenceYields[EssenceType.Chronon] = 2;


        emit RealmCreated(newId, msg.sender, block.number);

        // Any excess Ether is sent back
        if (msg.value > _realmCreationFee) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - _realmCreationFee}("");
             require(success, "Excess Ether return failed");
        }

        return newId;
    }

    function interactWithRealm(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed) public onlyRealmExists(realmId) {
        Realm storage realm = _realms[realmId];
        require(_essenceBalances[msg.sender][essenceUsed] >= amountUsed, "Insufficient essence balance");
        require(amountUsed > 0, "Amount used must be greater than 0");

        // Check specific essence requirements (can be zero if not required)
        require(amountUsed >= realm.essenceRequirements[essenceUsed], "Did not meet minimum essence requirement for this type");

        // Consume essence
        _burn(msg.sender, essenceUsed, amountUsed);

        uint256 entropy = _calculateEntropy(realmId);
        emit InteractedWithRealm(realmId, msg.sender, essenceUsed, amountUsed, entropy);

        // --- Core Interaction Logic ---
        RealmState oldState = realm.currentState;
        bool stateChanged = false;

        // 1. Process Potential State Changes based on Current State and Probability
        RealmState nextState = oldState;

        if (oldState == RealmState.Pure) {
            // Pure realms might become Unstable
            if (_checkProbabilisticSuccess(entropy, _stateTransitionProbabilities[RealmState.Pure][RealmState.Unstable], realmId)) {
                nextState = RealmState.Unstable;
                stateChanged = true;
            }
        } else if (oldState == RealmState.Unstable) {
            // Unstable realms might Collapse or become Entangled
             if (_checkProbabilisticSuccess(entropy, _stateTransitionProbabilities[RealmState.Unstable][RealmState.Collapsed], realmId)) {
                nextState = RealmState.Collapsed;
                stateChanged = true;
            } else if (_checkProbabilisticSuccess(entropy, _stateTransitionProbabilities[RealmState.Unstable][RealmState.Entangled], realmId)) {
                // To become entangled, need another available realm (e.g., Pure or Unstable)
                // This requires more complex logic: finding a suitable realm and linking them.
                // For this example, we'll simulate a self-entanglement or failure if no partner found.
                // A real implementation would need a mechanism to find/select a partner realm.
                 // Let's simplify: a successful attempt *might* make it ready for entanglement, or self-entangle for now.
                 // A proper implementation would require the user to propose entanglement with another realm ID.
                 // Let's use the `attemptEntangleRealm` explicitly for this.
                 // If Unstable *could* become Entangled via general interaction, it might just transition to a "ReadyForEntanglement" state, or fail this check.
                 // Let's adjust: Unstable -> Collapsed or Unstable (remains Unstable). Entanglement requires explicit action.
                 // This simplifies the general interaction flow.
                 // If the check above for Collapsed failed, it remains Unstable.
            }
        } else if (oldState == RealmState.Entangled) {
             // Interacting with an Entangled realm can have side effects on the linked realm.
             // It might also transition to Dormant.
             if (_checkProbabilisticSuccess(entropy, _stateTransitionProbabilities[RealmState.Entangled][RealmState.Dormant], realmId)) {
                nextState = RealmState.Dormant;
                stateChanged = true;
                // Breaking entanglement happens when it becomes Dormant or explicitly via breakEntanglement
                if (realm.entangledRealmId != 0) {
                    _realms[realm.entangledRealmId].entangledRealmId = 0; // Break the link on the other side
                    emit RealmDisentangled(realm.entangledRealmId, address(0)); // Signal disentanglement
                    realm.entangledRealmId = 0;
                    emit RealmDisentangled(realmId, msg.sender);
                }
             } else if (realm.entangledRealmId != 0) {
                 // Example side effect: interacting with one Entangled realm has a chance to add yield to the other
                 uint256 sideEffectEntropy = _calculateEntropy(realm.entangledRealmId); // Calculate entropy for the other realm
                 if (_checkProbabilisticSuccess(sideEffectEntropy, 5000, realm.entangledRealmId)) { // 50% chance of side effect
                     Realm storage entangledRealm = _realms[realm.entangledRealmId];
                     entangledRealm.accumulatedYield[essenceUsed] += amountUsed / 10; // Add 10% of used essence as yield to the other
                 }
             }
        }
        // Collapsed and Dormant realms might be inert or require specific interactions to change state.
        // For this example, let's say general interaction doesn't change their state, but harvest still works.

        // Apply state change
        if (stateChanged) {
            realm.currentState = nextState;
            emit RealmStateChanged(realmId, oldState, nextState);
        }

        // 2. Process Yield Generation (Happens regardless of state change, if not Dormant)
        if (realm.currentState != RealmState.Dormant) {
            // Calculate yield based on realm yields and amount used
            for (uint i = 0; i < 4; i++) { // Iterate through all essence types
                EssenceType yieldType = EssenceType(i);
                uint256 yieldAmount = (amountUsed * realm.essenceYields[yieldType]) / 100; // Example: Yield is percentage of amount used
                if (yieldAmount > 0) {
                     // Yield accumulates, user must call harvestEssenceFromRealm to claim
                    realm.accumulatedYield[yieldType] += yieldAmount;
                }
            }
        }

        realm.lastInteractionBlock = block.number;
    }

    function attemptStateCollapse(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed) public onlyRealmExists(realmId) {
        Realm storage realm = _realms[realmId];
        require(realm.currentState == RealmState.Unstable, "Realm is not in Unstable state");
        require(_essenceBalances[msg.sender][essenceUsed] >= amountUsed, "Insufficient essence balance");

        // Additional requirement for collapse attempt? e.g., specific essence type
        require(essenceUsed == EssenceType.Chronon, "Only Chronon essence can attempt state collapse");

        // Consume essence
        _burn(msg.sender, essenceUsed, amountUsed);

        uint256 entropy = _calculateEntropy(realmId);

        // Check probability of collapsing
        uint256 collapseChanceBasis = _stateTransitionProbabilities[RealmState.Unstable][RealmState.Collapsed]; // Use the defined probability

        if (_checkProbabilisticSuccess(entropy, collapseChanceBasis, realmId)) {
             emit RealmStateChanged(realmId, RealmState.Unstable, RealmState.Collapsed);
             realm.currentState = RealmState.Collapsed;
        } else {
             // On failure, maybe add some yield, or increase instability (represented by prob factor)?
             // For simplicity, failure just consumes essence.
        }
         realm.lastInteractionBlock = block.number;
    }


    function attemptEntangleRealm(uint256 realmId1, uint256 realmId2, EssenceType essenceUsed, uint256 amountUsed) public onlyRealmExists(realmId1) onlyRealmExists(realmId2) {
        require(realmId1 != realmId2, "Cannot entangle a realm with itself");
        Realm storage realm1 = _realms[realmId1];
        Realm storage realm2 = _realms[realmId2];

        require(realm1.entangledRealmId == 0 && realm2.entangledRealmId == 0, "One or both realms are already entangled");
        require(realm1.currentState != RealmState.Collapsed && realm1.currentState != RealmState.Dormant, "Realm 1 state not suitable for entanglement");
        require(realm2.currentState != RealmState.Collapsed && realm2.currentState != RealmState.Dormant, "Realm 2 state not suitable for entanglement");

        require(_essenceBalances[msg.sender][essenceUsed] >= amountUsed, "Insufficient essence balance");
        // Requirement: specific essence and amount
        require(essenceUsed == EssenceType.Void && amountUsed >= 50, "Requires 50 or more Void essence to attempt entanglement");

        // Consume essence
        _burn(msg.sender, essenceUsed, amountUsed);

        uint256 entropy = _calculateEntropy(realmId1); // Base entropy on realm1
        uint256 entanglementChanceBasis = 4000; // Example: 40% base chance (can be admin set)

        if (_checkProbabilisticSuccess(entropy, entanglementChanceBasis, 0)) { // Use 0 for realmId if probability is not realm-specific
             realm1.entangledRealmId = realmId2;
             realm2.entangledRealmId = realmId1;
             // Both realms transition to Entangled state upon successful entanglement
             emit RealmStateChanged(realmId1, realm1.currentState, RealmState.Entangled);
             realm1.currentState = RealmState.Entangled;
             emit RealmStateChanged(realmId2, realm2.currentState, RealmState.Entangled);
             realm2.currentState = RealmState.Entangled;

             emit RealmEntangled(realmId1, realmId2, msg.sender);
        } else {
             // On failure, essence is consumed, nothing happens.
        }
        realm1.lastInteractionBlock = block.number;
        realm2.lastInteractionBlock = block.number; // Also update linked realm
    }

    function breakEntanglement(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed) public onlyRealmExists(realmId) {
        Realm storage realm = _realms[realmId];
        require(realm.entangledRealmId != 0, "Realm is not entangled");
        require(_essenceBalances[msg.sender][essenceUsed] >= amountUsed, "Insufficient essence balance");
        // Requirement: specific essence and amount
        require(essenceUsed == EssenceType.Gleam && amountUsed >= 30, "Requires 30 or more Gleam essence to attempt breaking entanglement");

        // Consume essence
        _burn(msg.sender, essenceUsed, amountUsed);

        uint256 entropy = _calculateEntropy(realmId);
        uint256 breakChanceBasis = 6000; // Example: 60% base chance (can be admin set)

        if (_checkProbabilisticSuccess(entropy, breakChanceBasis, 0)) { // Use 0 for realmId if probability is not realm-specific
            uint256 entangledId = realm.entangledRealmId;
            Realm storage entangledRealm = _realms[entangledId];

            realm.entangledRealmId = 0;
            entangledRealm.entangledRealmId = 0;

            // Disentangled realms return to Unstable or Dormant state? Let's make them Unstable.
            if (realm.currentState == RealmState.Entangled) {
                 emit RealmStateChanged(realmId, RealmState.Entangled, RealmState.Unstable);
                 realm.currentState = RealmState.Unstable;
            }
             if (entangledRealm.currentState == RealmState.Entangled) {
                 emit RealmStateChanged(entangledId, RealmState.Entangled, RealmState.Unstable);
                 entangledRealm.currentState = RealmState.Unstable;
             }

            emit RealmDisentangled(realmId, msg.sender);
            emit RealmDisentangled(entangledId, msg.sender); // Signal for the other side
        } else {
             // On failure, essence is consumed.
        }
        realm.lastInteractionBlock = block.number;
        if (_realms[realm.entangledRealmId].id != 0) { // Update if still entangled (failure case)
             _realms[realm.entangledRealmId].lastInteractionBlock = block.number;
        }
    }

    function harvestEssenceFromRealm(uint256 realmId) public onlyRealmExists(realmId) {
        Realm storage realm = _realms[realmId];
        bool harvested = false;
        for (uint i = 0; i < 4; i++) {
            EssenceType yieldType = EssenceType(i);
            uint256 amount = realm.accumulatedYield[yieldType];
            if (amount > 0) {
                _mint(msg.sender, yieldType, amount);
                realm.accumulatedYield[yieldType] = 0;
                emit EssenceHarvested(realmId, msg.sender, yieldType, amount);
                harvested = true;
            }
        }
        require(harvested, "No accumulated yield to harvest");
    }

    function synthesizeEssence(EssenceType inputType, uint256 inputAmount, EssenceType outputType) public {
        require(inputType != outputType, "Input and output essence types must be different");
        require(inputAmount > 0, "Input amount must be greater than 0");
        require(_essenceBalances[msg.sender][inputType] >= inputAmount, "Insufficient input essence balance");
        require(inputAmount % ESSENCE_SYNTHESIS_RATIO == 0, "Input amount must be a multiple of synthesis ratio");

        uint256 outputAmount = inputAmount / ESSENCE_SYNTHESIS_RATIO;

        _burn(msg.sender, inputType, inputAmount);
        _mint(msg.sender, outputType, outputAmount);

        emit EssenceSynthesized(msg.sender, inputType, inputAmount, outputType, outputAmount);
    }

    function sacrificeEssenceForProbabilityBoost(EssenceType essenceType, uint256 amount, uint256 durationBlocks) public {
        require(amount > 0, "Amount must be greater than 0");
        require(durationBlocks > 0, "Duration must be greater than 0 blocks");
        require(_essenceBalances[msg.sender][essenceType] >= amount, "Insufficient essence balance");
        require(essenceType == EssenceType.Chronon || essenceType == EssenceType.Gleam, "Only Chronon or Gleam essence can be sacrificed for boost"); // Example restriction

        _burn(msg.sender, essenceType, amount);

        // Calculate boost amount based on sacrificed essence type and amount
        uint256 boostFactor = 0;
        if (essenceType == EssenceType.Chronon) {
             boostFactor = amount / 10; // Example: 10 Chronon gives 1 boost point
        } else if (essenceType == EssenceType.Gleam) {
             boostFactor = amount / 5; // Example: 5 Gleam gives 1 boost point (Gleam is more potent)
        }

        // Update user's boost end block and factor. If already boosted, extend/increase.
        uint256 newBoostEndBlock = block.number + durationBlocks;
        if (newBoostEndBlock > _userProbabilityBoostEndBlock[msg.sender]) {
             _userProbabilityBoostEndBlock[msg.sender] = newBoostEndBlock;
             _userProbabilityBoostFactor[msg.sender] = boostFactor; // Replace with new factor if duration is extended
        } else {
             // If extending a longer current boost, just add the factor? Or average? Let's just add.
             _userProbabilityBoostFactor[msg.sender] += boostFactor;
        }


        emit ProbabilityBoostUsed(msg.sender, essenceType, amount, _userProbabilityBoostEndBlock[msg.sender]);
    }


    // --- 9. Essence Management Functions (Internal Helpers) ---

    function _mint(address account, EssenceType essenceType, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        _essenceBalances[account][essenceType] += amount;
        _totalEssenceSupply[essenceType] += amount;
    }

    function _burn(address account, EssenceType essenceType, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        require(_essenceBalances[account][essenceType] >= amount, "Burn amount exceeds balance");
        _essenceBalances[account][essenceType] -= amount;
        _totalEssenceSupply[essenceType] -= amount;
    }

    function transferEssence(EssenceType essenceType, address recipient, uint256 amount) public {
        require(msg.sender != recipient, "Cannot transfer to yourself");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than 0");
        require(_essenceBalances[msg.sender][essenceType] >= amount, "Insufficient balance");

        _burn(msg.sender, essenceType, amount);
        _mint(recipient, essenceType, amount);

        emit EssenceTransferred(msg.sender, recipient, essenceType, amount);
    }

    function burnEssence(EssenceType essenceType, uint256 amount) public {
        require(amount > 0, "Burn amount must be greater than 0");
        _burn(msg.sender, essenceType, amount);
        emit EssenceBurned(msg.sender, essenceType, amount);
    }

    // --- 10. Realm Management Functions ---

     function mutateRealmProperties(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed, EssenceType targetEssence, uint256 newYieldAmount, uint256 newRequirementAmount) public onlyRealmExists(realmId) {
        Realm storage realm = _realms[realmId];
        require(realm.currentState != RealmState.Collapsed && realm.currentState != RealmState.Dormant, "Realm state not suitable for property mutation");
        require(_essenceBalances[msg.sender][essenceUsed] >= amountUsed, "Insufficient essence balance");
        // Requirement: specific essence for mutation
        require(essenceUsed == EssenceType.Aether || essenceUsed == EssenceType.Void, "Only Aether or Void essence can attempt mutation");

        // Consume essence
        _burn(msg.sender, essenceUsed, amountUsed);

        uint256 entropy = _calculateEntropy(realmId);
        uint256 mutationChanceBasis = 2500; // Example: 25% base chance (can be admin set)

        bool success = _checkProbabilisticSuccess(entropy, mutationChanceBasis, realmId);

        if (success) {
             // Mutate properties based on the target essence and new amounts
             realm.essenceYields[targetEssence] = newYieldAmount;
             realm.essenceRequirements[targetEssence] = newRequirementAmount;
        } else {
             // On failure, essence is consumed, properties don't change.
        }

        emit RealmPropertiesMutated(realmId, msg.sender, targetEssence, newYieldAmount, newRequirementAmount, success);
        realm.lastInteractionBlock = block.number;
     }


    // --- 11. Read-Only Functions (View/Pure) ---

    /// @notice Simulates the outcome probabilities of interactWithRealm for transparency.
    /// Does NOT change state or consume gas based on state writes.
    /// @param realmId The ID of the realm to predict interaction with.
    /// @param essenceUsed The type of essence intended to be used.
    /// @param amountUsed The amount of essence intended to be used.
    /// @return currentRealmState The state of the realm before interaction.
    /// @return potentialNextStateProbabilities An array of potential next states and their probabilities (basis points).
    /// @return predictedYields An array of essence types and the amounts predicted to accumulate as yield.
    function predictInteractionOutcome(uint256 realmId, EssenceType essenceUsed, uint256 amountUsed)
        public view onlyRealmExists(realmId)
        returns (
            RealmState currentRealmState,
            uint256[4] memory predictedYields, // Yield for each essence type
            uint256[] memory potentialNextStateProbabilities, // probabilities in basis points
            RealmState[] memory potentialNextStates
        )
    {
        Realm storage realm = _realms[realmId];
        currentRealmState = realm.currentState;

        // This prediction cannot use _calculateEntropy directly as it would change nonce state.
        // Instead, it calculates the *effective probability* for each potential outcome.
        // The actual outcome still depends on the entropy generated at transaction time.

        // Predict Yield Generation (assuming it happens if not Dormant)
        if (realm.currentState != RealmState.Dormant) {
             for (uint i = 0; i < 4; i++) {
                 EssenceType yieldType = EssenceType(i);
                 predictedYields[i] = (amountUsed * realm.essenceYields[yieldType]) / 100; // Example: Yield is percentage of amount used
             }
        } else {
             // No yield if Dormant
             for (uint i = 0; i < 4; i++) {
                predictedYields[i] = 0;
             }
        }


        // Predict State Change Probabilities
        // This simulation assumes the entropy rolled will check against defined transition probabilities.
        // It calculates the *chance* of each possible transition given the current state and effective probability factors.
        // Note: The *actual* transition depends on the single entropy roll in the actual transaction.
        // This function only shows which transitions *are possible* and their chance *if* that specific check is performed by the logic.

        RealmState[] memory possibleStates = new RealmState[](5); // Max possible transitions from one state to another + staying
        uint256[] memory probabilities = new uint256[](5);
        uint256 count = 0;

         // Calculate probabilities for potential next states
         if (currentRealmState == RealmState.Pure) {
             // Pure -> Unstable possibility
             uint256 chance = calcEffectiveProbability(_stateTransitionProbabilities[RealmState.Pure][RealmState.Unstable], realmId, msg.sender);
             if (chance > 0) {
                 possibleStates[count] = RealmState.Unstable;
                 probabilities[count] = chance;
                 count++;
             }
             // Stays Pure possibility (complement of transitioning)
             possibleStates[count] = RealmState.Pure;
             probabilities[count] = 10000 - chance;
             count++;
         } else if (currentRealmState == RealmState.Unstable) {
             // Unstable -> Collapsed possibility
             uint256 collapseChance = calcEffectiveProbability(_stateTransitionProbabilities[RealmState.Unstable][RealmState.Collapsed], realmId, msg.sender);
             if (collapseChance > 0) {
                 possibleStates[count] = RealmState.Collapsed;
                 probabilities[count] = collapseChance;
                 count++;
             }
             // Unstable -> Entangled possibility (if explicit attemptEntangleRealm was used, not general interaction)
             // This general interaction simulation only shows the collapse possibility or staying Unstable.
             possibleStates[count] = RealmState.Unstable;
             probabilities[count] = 10000 - collapseChance; // Stays Unstable if Collapse fails
             count++;
         } else if (currentRealmState == RealmState.Entangled) {
              // Entangled -> Dormant possibility
             uint256 dormantChance = calcEffectiveProbability(_stateTransitionProbabilities[RealmState.Entangled][RealmState.Dormant], realmId, msg.sender);
             if (dormantChance > 0) {
                 possibleStates[count] = RealmState.Dormant;
                 probabilities[count] = dormantChance;
                 count++;
             }
             // Stays Entangled possibility
             possibleStates[count] = RealmState.Entangled;
             probabilities[count] = 10000 - dormantChance;
             count++;
         } else { // Collapsed or Dormant
             // Assume these states don't change via general interaction
             possibleStates[count] = currentRealmState;
             probabilities[count] = 10000;
             count++;
         }

         // Resize arrays to actual count
         potentialNextStates = new RealmState[](count);
         potentialNextStateProbabilities = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             potentialNextStates[i] = possibleStates[i];
             potentialNextStateProbabilities[i] = probabilities[i];
         }

         return (currentRealmState, predictedYields, potentialNextStateProbabilities, potentialNextStates);
    }


    function getRealmDetails(uint256 realmId) public view onlyRealmExists(realmId)
        returns (
            uint256 id,
            RealmState currentState,
            uint256 entangledRealmId,
            uint256 creationBlock,
            uint256 lastInteractionBlock,
            uint256 probabilityFactor,
            uint256[4] memory essenceRequirements,
            uint256[4] memory essenceYields,
            uint256[4] memory accumulatedYield,
            uint256 interactionCount
        )
    {
        Realm storage realm = _realms[realmId];
        id = realm.id;
        currentState = realm.currentState;
        entangledRealmId = realm.entangledRealmId;
        creationBlock = realm.creationBlock;
        lastInteractionBlock = realm.lastInteractionBlock;
        probabilityFactor = realm.probabilityFactor;
        interactionCount = realm.interactionCount;

        for (uint i = 0; i < 4; i++) {
            EssenceType type_ = EssenceType(i);
            essenceRequirements[i] = realm.essenceRequirements[type_];
            essenceYields[i] = realm.essenceYields[type_];
            accumulatedYield[i] = realm.accumulatedYield[type_];
        }
    }

    function getEssenceBalance(address account, EssenceType essenceType) public view returns (uint256) {
        return _essenceBalances[account][essenceType];
    }

    function getTotalEssenceSupply(EssenceType essenceType) public view returns (uint256) {
        return _totalEssenceSupply[essenceType];
    }

    function getEntangledRealm(uint256 realmId) public view onlyRealmExists(realmId) returns (uint256) {
        return _realms[realmId].entangledRealmId;
    }

    function getStateTransitionProbability(RealmState fromState, RealmState toState) public view returns (uint256) {
        return _stateTransitionProbabilities[fromState][toState];
    }

    function getGlobalProbabilityFactor() public view returns (uint256) {
        return _globalProbabilityFactor;
    }

    // Helper to get a user's current probability boost info
    function getUserProbabilityBoost(address user) public view returns (uint256 endBlock, uint256 boostFactor) {
        return (_userProbabilityBoostEndBlock[user], _userProbabilityBoostFactor[user]);
    }

    // Helper to get the next realm ID that will be created
    function getNextRealmId() public view returns (uint256) {
        return _nextRealmId;
    }
}
```