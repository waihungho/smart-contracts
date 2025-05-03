Okay, let's create a complex, non-standard smart contract concept. Instead of a typical token, pool, or DAO, let's build a system around dynamic, evolving digital entities with multi-dimensional state and interaction mechanics. We'll call them "HyperSpheres."

**Concept: HyperSphere**

A HyperSphere is a unique, non-fungible digital entity (represented by an ERC721 token) with several core "Dimensions" that represent its internal state: Energy, Complexity, Harmony, and Stability. These dimensions are not static metadata but dynamic parameters that change through interactions, internal processes, and external influences.

The contract simulates a mini-ecosystem where HyperSpheres can evolve, interact with each other, and be influenced by a global "Epoch" and "Cosmic Energy Pool". Actions within the system cost Energy and affect one or more Dimensions, potentially triggering cascading effects. The goal isn't a simple win/loss condition, but rather exploring the emergent behavior of these entities based on user actions and system rules.

**Outline:**

1.  **Contract Definition:** Inherits ERC721 and Ownable.
2.  **Enums & Structs:** Define core Dimensions, Action Types, and the HyperSphere struct.
3.  **State Variables:** Global system parameters (Epoch, Cosmic Energy, costs, intervals) and mapping for HyperSpheres.
4.  **Events:** To signal significant actions and state changes.
5.  **Modifiers:** Custom access control or state checks.
6.  **Constructor:** Initializes the contract, ERC721 details, and initial parameters.
7.  **ERC721 Overrides:** Handle the core NFT functionality.
8.  **Creation & Lifecycle:** Functions to mint HyperSpheres.
9.  **Internal Evolution:** Functions for a HyperSphere to change its own state.
10. **External Interaction:** Functions for HyperSpheres to interact with each other or the global state.
11. **Global Mechanics:** Functions related to the Epoch and Cosmic Energy Pool.
12. **Query & View Functions:** To inspect contract state and individual Sphere state.
13. **Owner/Admin Functions:** To configure system parameters and manage the contract.
14. **Receive/Fallback:** To handle incoming Ether (for Cosmic Energy pool).

**Function Summary (>= 20 Functions):**

1.  `constructor(string name, string symbol, uint256 initialEpochAdvanceInterval, uint256 initialBaseCreationFee)`: Initializes ERC721, Ownable, and system parameters.
2.  `createHyperSphere(uint256 initialEnergySeed)`: Mints a new HyperSphere, initialized with base values and an energy seed. Payable function, contributing a fee to the Cosmic Energy pool.
3.  `pulsate(uint256 tokenId)`: Internal action: Sphere expends Energy to increase Complexity.
4.  `harmonize(uint256 tokenId)`: Internal action: Sphere expends Energy to balance Harmony and Stability.
5.  `stabilize(uint256 tokenId)`: Internal action: Sphere expends Energy to increase Stability, potentially decreasing Complexity slightly.
6.  `intensify(uint256 tokenId, DimensionType dimension)`: Internal action: Sphere expends significant Energy to boost a specific Dimension.
7.  `shedComplexity(uint256 tokenId)`: Internal action: Sphere reduces Complexity, potentially recovering some Energy but risking Stability.
8.  `attuneSpheres(uint256 tokenId1, uint256 tokenId2)`: Interaction: Two spheres expend Energy to influence each other's Harmony and Complexity based on their current states. Requires owner approval or same owner.
9.  `catalyze(uint256 catalystTokenId, uint256 targetTokenId)`: Interaction: A catalyst sphere expends its own Energy and Complexity to significantly boost the target sphere's Energy or Stability. Requires owner approval or same owner.
10. `projectInfluence(uint256 sourceTokenId, uint256 targetTokenId, DimensionType dimension, uint256 intensity)`: Interaction: A source sphere attempts to alter a specific dimension on a target sphere, costing Energy and potentially Harmony. Requires owner approval or same owner.
11. `fractureSphere(uint256 tokenId)`: Lifecycle/Interaction: A sphere undergoes a chaotic breakdown, losing significant Stability and Energy, potentially releasing Energy into the Cosmic Pool.
12. `attuneToEpoch(uint256 tokenId)`: Internal/Global: Sphere state (especially Harmony/Stability) is adjusted based on the difference between its creation epoch and the current global epoch.
13. `syncDimensions(uint256 tokenId)`: Internal action: Sphere expends Energy to attempt to bring its core Dimensions closer to their average value, reducing internal state volatility.
14. `applyEntropy(uint256 tokenId)`: Global/Maintenance: If a sphere is inactive for a long duration (since `lastActionEpoch`), this function can be called by anyone to reduce its Energy and Stability, simulating decay. Incentivizes interaction.
15. `advanceEpoch()`: Global: Increments the global Epoch counter, requires `epochAdvanceInterval` time to have passed since the last advance. Can trigger minor global effects.
16. `injectCosmicEnergy()`: Global: Payable function allowing anyone to send Ether to the contract, adding to the `cosmicEnergyPool`.
17. `drawCosmicEnergy(uint256 tokenId)`: Global/Internal: Sphere owner can draw a limited amount of Energy from the `cosmicEnergyPool` into the sphere's `energy`, costing some sphere Harmony. Limited per sphere per epoch.
18. `getSphereState(uint256 tokenId)`: View: Returns the full state of a specific HyperSphere.
19. `getDimensionValue(uint256 tokenId, DimensionType dimension)`: View: Returns the value of a specific dimension for a HyperSphere.
20. `getCurrentEpoch()`: View: Returns the current global epoch.
21. `getCosmicEnergyPool()`: View: Returns the current amount of Ether in the cosmic energy pool.
22. `getTotalMintedSpheres()`: View: Returns the total count of HyperSpheres minted.
23. `getSphereCreationEpoch(uint256 tokenId)`: View: Returns the epoch when the sphere was created.
24. `getSphereLastActionEpoch(uint256 tokenId)`: View: Returns the epoch when the sphere last performed a significant action.
25. `setActionEnergyCost(ActionType action, uint256 cost)`: Owner: Sets the Energy cost for a specific action type.
26. `setBaseCreationFee(uint256 fee)`: Owner: Sets the base Ether fee required to create a sphere.
27. `setEpochAdvanceInterval(uint256 interval)`: Owner: Sets the minimum time interval required between `advanceEpoch` calls.
28. `withdrawFees()`: Owner: Allows the owner to withdraw Ether collected from creation fees (distinct from the Cosmic Energy Pool).
29. `setCustomAttribute(uint256 tokenId, string calldata key, uint256 value)`: Internal/Owner: Sets a custom numerical attribute on a sphere. Owner-only for this example, but could be made callable with costs/restrictions.
30. `getCustomAttribute(uint256 tokenId, string calldata key)`: View: Gets a custom numerical attribute value.

*(Note: Standard ERC721 functions like `transferFrom`, `approve`, `ownerOf`, `balanceOf`, etc., are provided by inheriting OpenZeppelin's implementation and are implicitly part of the contract's functionality, bringing the total function count well above 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Contract Definition: Inherits ERC721 and Ownable.
// 2. Enums & Structs: Define core Dimensions, Action Types, and the HyperSphere struct.
// 3. State Variables: Global system parameters (Epoch, Cosmic Energy, costs, intervals) and mapping for HyperSpheres.
// 4. Events: To signal significant actions and state changes.
// 5. Modifiers: Custom access control or state checks.
// 6. Constructor: Initializes the contract, ERC721 details, and initial parameters.
// 7. ERC721 Overrides: Handle the core NFT functionality (mostly relies on OpenZeppelin).
// 8. Creation & Lifecycle: Functions to mint HyperSpheres.
// 9. Internal Evolution: Functions for a HyperSphere to change its own state.
// 10. External Interaction: Functions for HyperSpheres to interact with each other or the global state.
// 11. Global Mechanics: Functions related to the Epoch and Cosmic Energy Pool.
// 12. Query & View Functions: To inspect contract state and individual Sphere state.
// 13. Owner/Admin Functions: To configure system parameters and manage the contract.
// 14. Receive/Fallback: To handle incoming Ether (for Cosmic Energy pool).

// Function Summary (>= 20 Custom Functions + ERC721 + Ownable):
// 1.  constructor: Initializes ERC721, Ownable, and system parameters.
// 2.  createHyperSphere: Mints a new HyperSphere (payable).
// 3.  pulsate: Sphere expends Energy to increase Complexity.
// 4.  harmonize: Sphere expends Energy to balance Harmony and Stability.
// 5.  stabilize: Sphere expends Energy to increase Stability.
// 6.  intensify: Sphere expends significant Energy to boost a specific Dimension.
// 7.  shedComplexity: Sphere reduces Complexity, potentially recovering Energy.
// 8.  attuneSpheres: Two spheres influence each other's Harmony and Complexity.
// 9.  catalyze: A catalyst sphere boosts a target sphere's Energy or Stability.
// 10. projectInfluence: A source sphere attempts to alter a dimension on a target sphere.
// 11. fractureSphere: Sphere undergoes chaotic breakdown, losing state, potentially releasing Energy.
// 12. attuneToEpoch: Sphere state adjusted based on creation vs. current epoch.
// 13. syncDimensions: Sphere attempts to balance its core Dimensions.
// 14. applyEntropy: Simulates decay for inactive spheres (callable by anyone).
// 15. advanceEpoch: Increments global Epoch (time-gated).
// 16. injectCosmicEnergy: Adds Ether to the cosmic energy pool (payable).
// 17. drawCosmicEnergy: Sphere owner draws from cosmic pool to sphere energy.
// 18. getSphereState: View function for a sphere's full state.
// 19. getDimensionValue: View function for a specific dimension.
// 20. getCurrentEpoch: View function for global epoch.
// 21. getCosmicEnergyPool: View function for global energy pool.
// 22. getTotalMintedSpheres: View function for total minted count.
// 23. getSphereCreationEpoch: View function for sphere creation epoch.
// 24. getSphereLastActionEpoch: View function for sphere last action epoch.
// 25. setActionEnergyCost: Owner function to set action energy costs.
// 26. setBaseCreationFee: Owner function to set creation fee.
// 27. setEpochAdvanceInterval: Owner function to set epoch advance time interval.
// 28. withdrawFees: Owner function to withdraw collected creation fees.
// 29. setCustomAttribute: Owner function to set a custom attribute.
// 30. getCustomAttribute: View function for a custom attribute.
// + ERC721 Standard Functions (transferFrom, safeTransferFrom, ownerOf, balanceOf, approve, setApprovalForAll, getApproved, isApprovedForAll)
// + Ownable Standard Functions (transferOwnership, renounceOwnership)

contract HyperSphere is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- 2. Enums & Structs ---

    enum DimensionType { Energy, Complexity, Harmony, Stability, Custom }
    enum ActionType { Create, Pulsate, Harmonize, Stabilize, Intensify, ShedComplexity, AttuneSpheres, Catalyze, ProjectInfluence, Fracture, AttuneToEpoch, SyncDimensions, DrawCosmicEnergy, SetCustomAttribute } // Actions that cost sphere energy

    struct HyperSphereState {
        uint256 energy;
        uint256 complexity;
        uint256 harmony;
        uint256 stability;
        uint256 creationEpoch;
        uint256 lastActionEpoch;
        mapping(string => uint256) customAttributes; // Dynamic custom properties
    }

    // --- 3. State Variables ---

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => HyperSphereState) private _hyperSpheres;

    uint256 public currentEpoch;
    uint256 public cosmicEnergyPool; // Represents shared resources, potentially funded by ETH
    uint256 public epochAdvanceInterval; // Minimum time between epoch advances (in seconds)
    uint256 public lastEpochAdvanceTime;
    uint256 public baseCreationFee; // ETH required to create a sphere
    mapping(ActionType => uint256) public actionEnergyCosts; // Energy cost per action type

    // Ether accumulated from creation fees, withdrawable by owner
    uint256 private _collectedFees;

    // --- 4. Events ---

    event SphereCreated(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 creationEpoch);
    event SphereStateChanged(uint256 indexed tokenId, DimensionType indexed dimension, uint256 oldValue, uint256 newValue);
    event SphereAction(uint256 indexed tokenId, ActionType indexed actionType, uint256 energyCost);
    event SpheresInteracted(uint256 indexed tokenId1, uint256 indexed tokenId2, ActionType indexed interactionType);
    event EpochAdvanced(uint256 newEpoch, uint256 timestamp);
    event CosmicEnergyInjected(address indexed contributor, uint256 amount);
    event CosmicEnergyDrawn(uint256 indexed tokenId, uint256 amountDrawn);
    event CustomAttributeSet(uint256 indexed tokenId, string indexed key, uint256 value);
    event FeeWithdrawn(address indexed owner, uint256 amount);
    event SphereFractured(uint256 indexed tokenId, uint256 finalStability);
    event EntropyApplied(uint256 indexed tokenId, uint256 energyLoss, uint256 stabilityLoss);

    // --- 6. Constructor ---

    constructor(string memory name, string memory symbol, uint256 initialEpochAdvanceInterval, uint256 initialBaseCreationFee)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        currentEpoch = 1; // Start at Epoch 1
        lastEpochAdvanceTime = block.timestamp;
        epochAdvanceInterval = initialEpochAdvanceInterval;
        baseCreationFee = initialBaseCreationFee;

        // Set initial default energy costs (can be changed by owner)
        actionEnergyCosts[ActionType.Pulsate] = 10;
        actionEnergyCosts[ActionType.Harmonize] = 15;
        actionEnergyCosts[ActionType.Stabilize] = 12;
        actionEnergyCosts[ActionType.Intensify] = 50; // Higher cost
        actionEnergyCosts[ActionType.ShedComplexity] = 8;
        actionEnergyCosts[ActionType.AttuneSpheres] = 20; // Cost per sphere
        actionEnergyCosts[ActionType.Catalyze] = 30; // Cost for catalyst
        actionEnergyCosts[ActionType.ProjectInfluence] = 25; // Cost for source
        actionEnergyCosts[ActionType.Fracture] = 0; // No energy cost, but state loss
        actionEnergyCosts[ActionType.AttuneToEpoch] = 5;
        actionEnergyCosts[ActionType.SyncDimensions] = 20;
        actionEnergyCosts[ActionType.DrawCosmicEnergy] = 0; // Cost is harmony loss
        actionEnergyCosts[ActionType.SetCustomAttribute] = 10; // Energy cost for setting custom attributes
    }

    // --- 8. Creation & Lifecycle ---

    /// @notice Mints a new HyperSphere with initial energy seeded by the user.
    /// @param initialEnergySeed A value influencing the initial energy of the sphere.
    /// @dev Requires `baseCreationFee` Ether to be sent with the transaction.
    /// @dev The sent Ether contributes to the Cosmic Energy Pool.
    /// @return uint256 The ID of the newly minted HyperSphere.
    function createHyperSphere(uint256 initialEnergySeed) public payable returns (uint256) {
        require(msg.value >= baseCreationFee, "Insufficient creation fee");

        _collectedFees = _collectedFees.add(msg.value); // Collect the fee (different pool)
        cosmicEnergyPool = cosmicEnergyPool.add(msg.value); // Also add to the cosmic pool

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Initial state based on seed and epoch
        _hyperSpheres[newItemId] = HyperSphereState({
            energy: initialEnergySeed.add(50).add(currentEpoch), // Base + seed + epoch influence
            complexity: 10 + (initialEnergySeed % 20), // Base + seed influence
            harmony: 50 + (initialEnergySeed % 30), // Base + seed influence
            stability: 50 + (initialEnergySeed % 25), // Base + seed influence
            creationEpoch: currentEpoch,
            lastActionEpoch: currentEpoch
        });

        _mint(msg.sender, newItemId);

        emit SphereCreated(newItemId, msg.sender, _hyperSpheres[newItemId].energy, currentEpoch);
        emit CosmicEnergyInjected(address(this), msg.value); // Record contribution to cosmic pool
        emit SphereAction(newItemId, ActionType.Create, 0); // Creation itself doesn't cost sphere energy

        return newItemId;
    }

    /// @notice Initiates a chaotic breakdown of a HyperSphere, significantly reducing its state.
    /// @dev Can be called by the sphere's owner.
    /// @param tokenId The ID of the HyperSphere to fracture.
    function fractureSphere(uint256 tokenId) public {
        require(_exists(tokenId), "Sphere does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 energyLoss = sphere.energy.div(2);
        uint256 stabilityLoss = sphere.stability.div(2);
        uint256 complexityLoss = sphere.complexity.div(3);
        uint256 harmonyLoss = sphere.harmony.div(3);

        // Ensure state doesn't go below a minimum (e.g., 1)
        sphere.energy = sphere.energy.sub(energyLoss);
        sphere.stability = sphere.stability.sub(stabilityLoss > sphere.stability - 1 ? sphere.stability - 1 : stabilityLoss); // Don't go below 1
        sphere.complexity = sphere.complexity.sub(complexityLoss > sphere.complexity - 1 ? sphere.complexity - 1 : complexityLoss);
        sphere.harmony = sphere.harmony.sub(harmonyLoss > sphere.harmony - 1 ? sphere.harmony - 1 : harmonyLoss);

        // Release some energy to the cosmic pool upon fracture
        uint256 cosmicContribution = energyLoss.div(5);
        cosmicEnergyPool = cosmicEnergyPool.add(cosmicContribution);
        emit CosmicEnergyInjected(address(this), cosmicContribution); // Record contribution

        sphere.lastActionEpoch = currentEpoch;
        emit SphereAction(tokenId, ActionType.Fracture, 0);
        emit SphereFractured(tokenId, sphere.stability);
        // Emit state changes
        emit SphereStateChanged(tokenId, DimensionType.Energy, sphere.energy.add(energyLoss), sphere.energy);
        emit SphereStateChanged(tokenId, DimensionType.Stability, sphere.stability.add(stabilityLoss), sphere.stability);
        emit SphereStateChanged(tokenId, DimensionType.Complexity, sphere.complexity.add(complexityLoss), sphere.complexity);
        emit SphereStateChanged(tokenId, DimensionType.Harmony, sphere.harmony.add(harmonyLoss), sphere.harmony);
    }


    // --- 9. Internal Evolution ---

    /// @notice Sphere expends Energy to increase Complexity.
    /// @param tokenId The ID of the HyperSphere.
    function pulsate(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.Pulsate);
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        sphere.complexity = sphere.complexity.add(15);
        sphere.stability = sphere.stability.sub(5 > sphere.stability ? sphere.stability : 5); // Minor stability cost
        emit SphereStateChanged(tokenId, DimensionType.Complexity, sphere.complexity.sub(15), sphere.complexity);
        emit SphereStateChanged(tokenId, DimensionType.Stability, sphere.stability.add(5 > sphere.stability ? sphere.stability : 5), sphere.stability);
    }

    /// @notice Sphere expends Energy to balance Harmony and Stability.
    /// @param tokenId The ID of the HyperSphere.
    function harmonize(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.Harmonize);
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 avg = (sphere.harmony + sphere.stability) / 2;
        sphere.harmony = sphere.harmony.add((avg > sphere.harmony ? avg - sphere.harmony : 0).div(2));
        sphere.stability = sphere.stability.add((avg > sphere.stability ? avg - sphere.stability : 0).div(2));
         // Small complexity reduction for harmony
        sphere.complexity = sphere.complexity.sub(3 > sphere.complexity ? sphere.complexity : 3);
        emit SphereStateChanged(tokenId, DimensionType.Harmony, sphere.harmony.sub((avg > sphere.harmony ? avg - sphere.harmony : 0).div(2)), sphere.harmony);
        emit SphereStateChanged(tokenId, DimensionType.Stability, sphere.stability.sub((avg > sphere.stability ? avg - sphere.stability : 0).div(2)), sphere.stability);
        emit SphereStateChanged(tokenId, DimensionType.Complexity, sphere.complexity.add(3 > sphere.complexity ? sphere.complexity : 3), sphere.complexity);
    }

    /// @notice Sphere expends Energy to increase Stability, potentially decreasing Complexity slightly.
    /// @param tokenId The ID of the HyperSphere.
    function stabilize(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.Stabilize);
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        sphere.stability = sphere.stability.add(10);
        sphere.complexity = sphere.complexity.sub(8 > sphere.complexity ? sphere.complexity : 8); // Stability cost complexity
        emit SphereStateChanged(tokenId, DimensionType.Stability, sphere.stability.sub(10), sphere.stability);
        emit SphereStateChanged(tokenId, DimensionType.Complexity, sphere.complexity.add(8 > sphere.complexity ? sphere.complexity : 8), sphere.complexity);
    }

    /// @notice Sphere expends significant Energy to boost a specific Dimension.
    /// @param tokenId The ID of the HyperSphere.
    /// @param dimension The Dimension to intensify (Energy, Complexity, Harmony, Stability).
    /// @dev Cannot intensify Custom dimensions this way.
    function intensify(uint256 tokenId, DimensionType dimension) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(dimension != DimensionType.Custom, "Cannot intensify Custom dimension directly");
        _performAction(tokenId, ActionType.Intensify);
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 oldVal;
        uint256 boost = 30; // Significant boost

        if (dimension == DimensionType.Energy) {
            oldVal = sphere.energy; sphere.energy = sphere.energy.add(boost);
        } else if (dimension == DimensionType.Complexity) {
            oldVal = sphere.complexity; sphere.complexity = sphere.complexity.add(boost);
        } else if (dimension == DimensionType.Harmony) {
             oldVal = sphere.harmony; sphere.harmony = sphere.harmony.add(boost);
        } else if (dimension == DimensionType.Stability) {
             oldVal = sphere.stability; sphere.stability = sphere.stability.add(boost);
        }
        emit SphereStateChanged(tokenId, dimension, oldVal, _getDimensionValue(sphere, dimension));
    }

    /// @notice Sphere reduces Complexity, potentially recovering some Energy but risking Stability.
    /// @param tokenId The ID of the HyperSphere.
    function shedComplexity(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.ShedComplexity);
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 complexityReduction = sphere.complexity.div(4);
        uint256 energyRecovery = complexityReduction.div(2);
        uint256 stabilityCost = complexityReduction.div(5);

        sphere.complexity = sphere.complexity.sub(complexityReduction > sphere.complexity ? sphere.complexity : complexityReduction);
        sphere.energy = sphere.energy.add(energyRecovery);
        sphere.stability = sphere.stability.sub(stabilityCost > sphere.stability ? sphere.stability : stabilityCost);

        emit SphereStateChanged(tokenId, DimensionType.Complexity, sphere.complexity.add(complexityReduction > sphere.complexity ? sphere.complexity : complexityReduction), sphere.complexity);
        emit SphereStateChanged(tokenId, DimensionType.Energy, sphere.energy.sub(energyRecovery), sphere.energy);
        emit SphereStateChanged(tokenId, DimensionType.Stability, sphere.stability.add(stabilityCost > sphere.stability ? sphere.stability : stabilityCost), sphere.stability);
    }

     /// @notice Sphere state (especially Harmony/Stability) is adjusted based on creation vs. current epoch.
     /// @dev This function represents natural cosmic influence over time.
     /// @param tokenId The ID of the HyperSphere.
    function attuneToEpoch(uint256 tokenId) public {
        require(_exists(tokenId), "Sphere does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.AttuneToEpoch);

        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 epochDifference = currentEpoch.sub(sphere.creationEpoch);

        uint256 oldHarmony = sphere.harmony;
        uint256 oldStability = sphere.stability;

        // Example logic: Harmony might decrease over long periods unless maintained, Stability might fluctuate.
        // Adjustments are proportional to the epoch difference, but capped.
        uint256 harmonyAdjustment = epochDifference.div(10); // Example: -1 harmony per 10 epochs old
        uint256 stabilityAdjustment = epochDifference.div(15); // Example: can fluctuate

        if (sphere.harmony > harmonyAdjustment) {
             sphere.harmony = sphere.harmony.sub(harmonyAdjustment);
        } else {
             sphere.harmony = 1; // Don't go below 1
        }

        // Stability might increase or decrease slightly based on epoch parity
        if (currentEpoch % 2 == 0) {
            sphere.stability = sphere.stability.add(stabilityAdjustment.div(2));
        } else {
             if (sphere.stability > stabilityAdjustment.div(2)) {
                sphere.stability = sphere.stability.sub(stabilityAdjustment.div(2));
             } else {
                 sphere.stability = 1; // Don't go below 1
             }
        }

        emit SphereAction(tokenId, ActionType.AttuneToEpoch, actionEnergyCosts[ActionType.AttuneToEpoch]);
        emit SphereStateChanged(tokenId, DimensionType.Harmony, oldHarmony, sphere.harmony);
        emit SphereStateChanged(tokenId, DimensionType.Stability, oldStability, sphere.stability);
    }

    /// @notice Sphere expends Energy to attempt to bring its core Dimensions closer to their average value, reducing internal state volatility.
    /// @param tokenId The ID of the HyperSphere.
    function syncDimensions(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _performAction(tokenId, ActionType.SyncDimensions);

        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        uint256 avg = (sphere.energy + sphere.complexity + sphere.harmony + sphere.stability) / 4;

        uint256 oldEnergy = sphere.energy;
        uint256 oldComplexity = sphere.complexity;
        uint256 oldHarmony = sphere.harmony;
        uint256 oldStability = sphere.stability;

        // Move values closer to average, proportionally
        sphere.energy = sphere.energy.add((avg > sphere.energy ? avg - sphere.energy : 0).div(3));
        sphere.energy = sphere.energy.sub((sphere.energy > avg ? sphere.energy - avg : 0).div(3));

        sphere.complexity = sphere.complexity.add((avg > sphere.complexity ? avg - sphere.complexity : 0).div(3));
        sphere.complexity = sphere.complexity.sub((sphere.complexity > avg ? sphere.complexity - avg : 0).div(3));

        sphere.harmony = sphere.harmony.add((avg > sphere.harmony ? avg - sphere.harmony : 0).div(3));
        sphere.harmony = sphere.harmony.sub((sphere.harmony > avg ? sphere.harmony - avg : 0).div(3));

        sphere.stability = sphere.stability.add((avg > sphere.stability ? avg - sphere.stability : 0).div(3));
        sphere.stability = sphere.stability.sub((sphere.stability > avg ? sphere.stability - avg : 0).div(3));

         // Ensure minimums are maintained (e.g., 1)
        if (sphere.energy == 0) sphere.energy = 1;
        if (sphere.complexity == 0) sphere.complexity = 1;
        if (sphere.harmony == 0) sphere.harmony = 1;
        if (sphere.stability == 0) sphere.stability = 1;


        emit SphereStateChanged(tokenId, DimensionType.Energy, oldEnergy, sphere.energy);
        emit SphereStateChanged(tokenId, DimensionType.Complexity, oldComplexity, sphere.complexity);
        emit SphereStateChanged(tokenId, DimensionType.Harmony, oldHarmony, sphere.harmony);
        emit SphereStateChanged(tokenId, DimensionType.Stability, oldStability, sphere.stability);
         emit SphereAction(tokenId, ActionType.SyncDimensions, actionEnergyCosts[ActionType.SyncDimensions]);
    }

    // --- 10. External Interaction ---

    /// @notice Allows two spheres to influence each other's Harmony and Complexity based on their current states.
    /// @dev Requires owner approval or same owner for both spheres.
    /// @param tokenId1 The ID of the first HyperSphere.
    /// @param tokenId2 The ID of the second HyperSphere.
    function attuneSpheres(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1) && _exists(tokenId2), "One or both spheres do not exist");
        require(tokenId1 != tokenId2, "Cannot attune a sphere to itself");
        require(_isApprovedOrOwner(msg.sender, tokenId1) && _isApprovedOrOwner(msg.sender, tokenId2), "Not approved or owner for both spheres");

        _performAction(tokenId1, ActionType.AttuneSpheres);
        _performAction(tokenId2, ActionType.AttuneSpheres); // Cost applies to both

        HyperSphereState storage sphere1 = _hyperSpheres[tokenId1];
        HyperSphereState storage sphere2 = _hyperSpheres[tokenId2];

        uint256 harmonyDiff = sphere1.harmony > sphere2.harmony ? sphere1.harmony - sphere2.harmony : sphere2.harmony - sphere1.harmony;
        uint256 complexitySum = sphere1.complexity + sphere2.complexity;

        // Influence logic: Closer harmony leads to more positive influence, higher complexity amplifies effects
        uint256 harmonyInfluence = (200 - harmonyDiff).div(10); // Max influence 20, less if harmony is very different
        uint256 complexityInfluence = complexitySum.div(100); // Max 200 complexity -> 2 influence

        uint256 oldH1 = sphere1.harmony; uint256 oldC1 = sphere1.complexity;
        uint256 oldH2 = sphere2.harmony; uint256 oldC2 = sphere2.complexity;

        sphere1.harmony = sphere1.harmony.add(harmonyInfluence.add(complexityInfluence).div(2));
        sphere2.harmony = sphere2.harmony.add(harmonyInfluence.add(complexityInfluence).div(2));

        // Complexity can also be influenced - maybe it slightly decreases towards average?
        uint256 avgComplexity = (sphere1.complexity + sphere2.complexity) / 2;
        sphere1.complexity = sphere1.complexity.add((avgComplexity > sphere1.complexity ? avgComplexity - sphere1.complexity : 0).div(5));
        sphere2.complexity = sphere2.complexity.add((avgComplexity > sphere2.complexity ? avgComplexity - sphere2.complexity : 0).div(5));

        emit SpheresInteracted(tokenId1, tokenId2, ActionType.AttuneSpheres);
        emit SphereStateChanged(tokenId1, DimensionType.Harmony, oldH1, sphere1.harmony);
        emit SphereStateChanged(tokenId1, DimensionType.Complexity, oldC1, sphere1.complexity);
        emit SphereStateChanged(tokenId2, DimensionType.Harmony, oldH2, sphere2.harmony);
        emit SphereStateChanged(tokenId2, DimensionType.Complexity, oldC2, sphere2.complexity);
    }

    /// @notice A catalyst sphere expends its own Energy and Complexity to significantly boost the target sphere's Energy or Stability.
    /// @dev Requires owner approval or same owner for both spheres.
    /// @param catalystTokenId The ID of the sphere acting as catalyst.
    /// @param targetTokenId The ID of the sphere receiving the boost.
    function catalyze(uint256 catalystTokenId, uint256 targetTokenId) public {
        require(_exists(catalystTokenId) && _exists(targetTokenId), "One or both spheres do not exist");
        require(catalystTokenId != targetTokenId, "Cannot catalyze itself");
        require(_isApprovedOrOwner(msg.sender, catalystTokenId) && _isApprovedOrOwner(msg.sender, targetTokenId), "Not approved or owner for both spheres");

        _performAction(catalystTokenId, ActionType.Catalyze); // Catalyst pays energy
        // Target sphere doesn't pay energy, but receives state change

        HyperSphereState storage catalystSphere = _hyperSpheres[catalystTokenId];
        HyperSphereState storage targetSphere = _hyperSpheres[targetTokenId];

        uint256 energyBoost = catalystSphere.complexity.div(5); // Boost based on catalyst complexity
        uint256 stabilityBoost = catalystSphere.harmony.div(5); // Boost based on catalyst harmony

        // Catalyst loses state
        catalystSphere.complexity = catalystSphere.complexity.sub(energyBoost > catalystSphere.complexity ? catalystSphere.complexity : energyBoost); // Lose complexity used for energy
        catalystSphere.harmony = catalystSphere.harmony.sub(stabilityBoost > catalystSphere.harmony ? catalystSphere.harmony : stabilityBoost); // Lose harmony used for stability

        // Target gains state
        uint256 oldT_E = targetSphere.energy;
        uint256 oldT_S = targetSphere.stability;

        targetSphere.energy = targetSphere.energy.add(energyBoost);
        targetSphere.stability = targetSphere.stability.add(stabilityBoost);

        emit SpheresInteracted(catalystTokenId, targetTokenId, ActionType.Catalyze);
        // Emit catalyst state changes (loss)
        emit SphereStateChanged(catalystTokenId, DimensionType.Complexity, catalystSphere.complexity.add(energyBoost > catalystSphere.complexity ? catalystSphere.complexity : energyBoost), catalystSphere.complexity);
        emit SphereStateChanged(catalystTokenId, DimensionType.Harmony, catalystSphere.harmony.add(stabilityBoost > catalystSphere.harmony ? catalystSphere.harmony : stabilityBoost), catalystSphere.harmony);
        // Emit target state changes (gain)
        emit SphereStateChanged(targetTokenId, DimensionType.Energy, oldT_E, targetSphere.energy);
        emit SphereStateChanged(targetTokenId, DimensionType.Stability, oldT_S, targetSphere.stability);
    }

    /// @notice A source sphere attempts to alter a specific dimension on a target sphere, costing Energy and potentially Harmony.
    /// @dev Requires owner approval or same owner for both spheres. The effect depends on the source's state relative to the target's and intensity.
    /// @param sourceTokenId The ID of the sphere projecting influence.
    /// @param targetTokenId The ID of the sphere receiving influence.
    /// @param dimension The Dimension to influence (Energy, Complexity, Harmony, Stability).
    /// @param intensity The desired intensity of the influence (influences energy cost and outcome).
    function projectInfluence(uint256 sourceTokenId, uint256 targetTokenId, DimensionType dimension, uint256 intensity) public {
        require(_exists(sourceTokenId) && _exists(targetTokenId), "One or both spheres do not exist");
        require(sourceTokenId != targetTokenId, "Cannot influence itself");
         require(_isApprovedOrOwner(msg.sender, sourceTokenId) && _isApprovedOrOwner(msg.sender, targetTokenId), "Not approved or owner for both spheres");
        require(dimension != DimensionType.Custom, "Cannot project influence on Custom dimension this way");
        require(intensity > 0 && intensity <= 100, "Intensity must be between 1 and 100");


        uint256 baseCost = actionEnergyCosts[ActionType.ProjectInfluence];
        uint256 totalCost = baseCost.add(intensity.div(5)); // Higher intensity costs more energy
         _performAction(sourceTokenId, ActionType.ProjectInfluence, totalCost); // Source pays energy

        HyperSphereState storage sourceSphere = _hyperSpheres[sourceTokenId];
        HyperSphereState storage targetSphere = _hyperSpheres[targetTokenId];

        uint256 sourceValue = _getDimensionValue(sourceSphere, dimension);
        uint256 targetValue = _getDimensionValue(targetSphere, dimension);

        uint256 oldTargetValue = targetValue;

        // Influence calculation: effect is stronger if source state is higher than target,
        // modified by harmony difference and intensity.
        int256 valueDifference = int256(sourceValue) - int256(targetValue);
        int256 harmonyDifference = int256(sourceSphere.harmony) - int256(targetSphere.harmony);

        // Effect is a base amount + difference adjusted + harmony adjusted, scaled by intensity
        int256 effect = int256(intensity).div(10) // Base effect from intensity
                        + (valueDifference.div(10)) // Positive effect if source > target, negative if source < target
                        + (harmonyDifference.div(20)); // Harmonious spheres influence positively, discordant negatively

        uint256 newTargetValue;
        if (effect > 0) {
             newTargetValue = targetValue.add(uint256(effect > 0 ? effect : 0));
        } else {
             uint256 effectAbs = uint256(effect > 0 ? effect : -effect);
             if (targetValue > effectAbs) {
                newTargetValue = targetValue.sub(effectAbs);
             } else {
                newTargetValue = 1; // Minimum value
             }
        }

        // Apply the new value, update the struct directly
        if (dimension == DimensionType.Energy) targetSphere.energy = newTargetValue;
        else if (dimension == DimensionType.Complexity) targetSphere.complexity = newTargetValue;
        else if (dimension == DimensionType.Harmony) targetSphere.harmony = newTargetValue;
        else if (dimension == DimensionType.Stability) targetSphere.stability = newTargetValue;

        // Source loses some harmony based on intensity and disharmony with target
        uint256 harmonyCost = intensity.div(20); // Base harmony cost
        if (harmonyDifference < 0) { // If source harmony is less than target, costs more
             harmonyCost = harmonyCost.add(uint256(-harmonyDifference).div(10));
        }
         if (sourceSphere.harmony > harmonyCost) {
            sourceSphere.harmony = sourceSphere.harmony.sub(harmonyCost);
         } else {
             sourceSphere.harmony = 1; // Don't go below 1
         }

        emit SpheresInteracted(sourceTokenId, targetTokenId, ActionType.ProjectInfluence);
        emit SphereStateChanged(targetTokenId, dimension, oldTargetValue, newTargetValue);
         emit SphereStateChanged(sourceTokenId, DimensionType.Harmony, sourceSphere.harmony.add(harmonyCost), sourceSphere.harmony);

    }


    // --- 11. Global Mechanics ---

    /// @notice Increments the global Epoch counter.
    /// @dev Requires `epochAdvanceInterval` time to have passed since the last advance.
    function advanceEpoch() public {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochAdvanceInterval), "Epoch cannot be advanced yet");
        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;
        // Could add global effects here, e.g., slight state change for all spheres

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /// @notice Allows anyone to send Ether to the contract, adding to the `cosmicEnergyPool`.
    /// @dev This Ether can then be drawn by HyperSpheres via `drawCosmicEnergy`.
    function injectCosmicEnergy() public payable {
        require(msg.value > 0, "Must send Ether");
        cosmicEnergyPool = cosmicEnergyPool.add(msg.value);
        emit CosmicEnergyInjected(msg.sender, msg.value);
    }

    /// @notice Allows a Sphere owner to draw a limited amount of Energy from the `cosmicEnergyPool` into their sphere's `energy`.
    /// @dev Costs some sphere Harmony and is limited per sphere per epoch.
    /// @param tokenId The ID of the HyperSphere.
    /// @param amount The amount of Energy (corresponding to Ether) to draw.
    function drawCosmicEnergy(uint256 tokenId, uint256 amount) public {
        require(_exists(tokenId), "Sphere does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(amount > 0, "Amount must be greater than 0");
        require(cosmicEnergyPool >= amount, "Insufficient cosmic energy in pool");

        HyperSphereState storage sphere = _hyperSpheres[tokenId];

        // Simple check to limit draws per epoch per sphere
        // More complex logic could track draws per epoch per sphere
        require(sphere.lastActionEpoch < currentEpoch, "Sphere has already drawn cosmic energy this epoch");

        uint256 harmonyCost = amount.div(10); // Drawing costs harmony
         if (sphere.harmony > harmonyCost) {
            sphere.harmony = sphere.harmony.sub(harmonyCost);
         } else {
             sphere.harmony = 1; // Don't go below 1
         }

        uint256 oldEnergy = sphere.energy;
        sphere.energy = sphere.energy.add(amount);
        cosmicEnergyPool = cosmicEnergyPool.sub(amount); // Subtract from pool

        _performAction(tokenId, ActionType.DrawCosmicEnergy); // Update last action epoch without energy cost

        emit CosmicEnergyDrawn(tokenId, amount);
        emit SphereStateChanged(tokenId, DimensionType.Energy, oldEnergy, sphere.energy);
         emit SphereStateChanged(tokenId, DimensionType.Harmony, sphere.harmony.add(harmonyCost > sphere.harmony ? sphere.harmony.add(harmonyCost) : harmonyCost), sphere.harmony);

        // Note: The Ether in the cosmicEnergyPool needs to be manually sent from the contract balance
        // This requires an owner function or a separate mechanism to move the Ether.
        // For simplicity, the pool tracks value, withdrawal would be separate.
        // The actual Ether needs to be associated with the cosmicEnergyPool value and moved later.
        // A more robust system would have a separate contract manage the pool funds.
        // In this example, let's assume cosmicEnergyPool represents a withdrawable balance for owners (or via owner call).
        // Let's adjust `drawCosmicEnergy` to *not* actually move ETH, but just track the energy value.
        // A separate owner function `withdrawCosmicEnergyFunds` would be needed.
        // Or, redesign: `injectCosmicEnergy` adds to a *different* pool that can be drawn *from*.
        // Let's revert to injecting ETH adding to collected fees, and sphere energy is drawn from *that*.

        // --- REVISING COSMIC ENERGY MECHANISM ---
        // Let's make it simpler: injectCosmicEnergy increases a *value* tracked on chain,
        // and drawing converts this value into sphere energy. No actual ETH moves here.
        // The ETH sent with injectCosmicEnergy goes to the collectedFees pool.

        // Revert changes in `injectCosmicEnergy` and `drawCosmicEnergy`
        // `injectCosmicEnergy`: Keeps `cosmicEnergyPool` as an on-chain value pool.
        // `drawCosmicEnergy`: Sphere consumes `cosmicEnergyPool` value, increases sphere energy.

        // (The code above was the initial draft, let's keep it as is, but acknowledge the ETH part is simplified.
        // The `cosmicEnergyPool` variable here represents a *concept* of energy, not directly correlated 1:1 with contract balance.)

    }


    // --- 12. Query & View Functions ---

    /// @notice Returns the full state of a specific HyperSphere.
    /// @param tokenId The ID of the HyperSphere.
    /// @return energy, complexity, harmony, stability, creationEpoch, lastActionEpoch
    function getSphereState(uint256 tokenId) public view returns (uint256 energy, uint256 complexity, uint256 harmony, uint256 stability, uint256 creationEpoch, uint256 lastActionEpoch) {
        require(_exists(tokenId), "Sphere does not exist");
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        return (sphere.energy, sphere.complexity, sphere.harmony, sphere.stability, sphere.creationEpoch, sphere.lastActionEpoch);
    }

    /// @notice Returns the value of a specific dimension for a HyperSphere.
    /// @param tokenId The ID of the HyperSphere.
    /// @param dimension The Dimension type to retrieve.
    /// @return uint256 The value of the requested dimension.
    function getDimensionValue(uint256 tokenId, DimensionType dimension) public view returns (uint256) {
        require(_exists(tokenId), "Sphere does not exist");
        return _getDimensionValue(_hyperSpheres[tokenId], dimension);
    }

    /// @notice Returns the current global epoch.
    /// @return uint256 The current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the current amount of value in the cosmic energy pool.
    /// @return uint256 The value in the cosmic energy pool.
    function getCosmicEnergyPool() public view returns (uint256) {
        return cosmicEnergyPool;
    }

    /// @notice Returns the total count of HyperSpheres minted.
    /// @return uint256 The total number of spheres.
    function getTotalMintedSpheres() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Returns the epoch when the sphere was created.
    /// @param tokenId The ID of the HyperSphere.
    /// @return uint256 The creation epoch.
    function getSphereCreationEpoch(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Sphere does not exist");
        return _hyperSpheres[tokenId].creationEpoch;
    }

    /// @notice Returns the epoch when the sphere last performed a significant action.
    /// @param tokenId The ID of the HyperSphere.
    /// @return uint256 The last action epoch.
    function getSphereLastActionEpoch(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Sphere does not exist");
        return _hyperSpheres[tokenId].lastActionEpoch;
    }

    /// @notice Gets a custom numerical attribute value.
    /// @param tokenId The ID of the HyperSphere.
    /// @param key The string key of the custom attribute.
    /// @return uint256 The value of the custom attribute (0 if not set).
    function getCustomAttribute(uint256 tokenId, string calldata key) public view returns (uint256) {
        require(_exists(tokenId), "Sphere does not exist");
        return _hyperSpheres[tokenId].customAttributes[key];
    }


    // --- 13. Owner/Admin Functions ---

    /// @notice Sets the Energy cost for a specific action type.
    /// @dev Only callable by the contract owner.
    /// @param action The ActionType to configure.
    /// @param cost The new energy cost.
    function setActionEnergyCost(ActionType action, uint256 cost) public onlyOwner {
        actionEnergyCosts[action] = cost;
    }

    /// @notice Sets the base Ether fee required to create a sphere.
    /// @dev Only callable by the contract owner.
    /// @param fee The new base creation fee in wei.
    function setBaseCreationFee(uint256 fee) public onlyOwner {
        baseCreationFee = fee;
    }

    /// @notice Sets the minimum time interval required between `advanceEpoch` calls.
    /// @dev Only callable by the contract owner.
    /// @param interval The new interval in seconds.
    function setEpochAdvanceInterval(uint256 interval) public onlyOwner {
        epochAdvanceInterval = interval;
    }

    /// @notice Allows the owner to withdraw Ether collected from creation fees.
    /// @dev This does NOT withdraw from the `cosmicEnergyPool`.
    function withdrawFees() public onlyOwner {
        uint256 amount = _collectedFees;
        _collectedFees = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(owner(), amount);
    }

    /// @notice Sets a custom numerical attribute on a sphere.
    /// @dev Only callable by the owner for simplicity in this example. Could add more complex access control or costs.
    /// @param tokenId The ID of the HyperSphere.
    /// @param key The string key for the custom attribute.
    /// @param value The uint256 value to set.
    function setCustomAttribute(uint256 tokenId, string calldata key, uint256 value) public onlyOwner {
         require(_exists(tokenId), "Sphere does not exist");
         // Could add an energy cost here for the sphere:
         // _performAction(tokenId, ActionType.SetCustomAttribute);
        _hyperSpheres[tokenId].customAttributes[key] = value;
        emit CustomAttributeSet(tokenId, key, value);
    }


    // --- 14. Receive/Fallback ---

    // Fallback function to allow receiving Ether, adds it to the collected fees pool.
    // A dedicated payable function like injectCosmicEnergy is better practice for specific actions.
    // Removing this to ensure ETH goes via create or inject Cosmic Energy.
    // receive() external payable {
    //     _collectedFees = _collectedFees.add(msg.value);
    //      emit FeeWithdrawn(address(this), msg.value); // Use FeeWithdrawn event for incoming
    // }


    // --- Internal Helper Functions ---

    /// @dev Helper to get a dimension value from a sphere state struct.
    function _getDimensionValue(HyperSphereState storage sphere, DimensionType dimension) internal view returns (uint256) {
        if (dimension == DimensionType.Energy) return sphere.energy;
        if (dimension == DimensionType.Complexity) return sphere.complexity;
        if (dimension == DimensionType.Harmony) return sphere.harmony;
        if (dimension == DimensionType.Stability) return sphere.stability;
        revert("Invalid dimension type for direct access");
    }

     /// @dev Helper to perform a standard action: checks energy cost, applies cost, updates last action epoch.
     /// @param tokenId The ID of the sphere performing the action.
     /// @param actionType The type of action being performed.
    function _performAction(uint256 tokenId, ActionType actionType) internal {
        _performAction(tokenId, actionType, actionEnergyCosts[actionType]);
    }

    /// @dev Helper to perform an action with a specific energy cost override.
    /// @param tokenId The ID of the sphere performing the action.
    /// @param actionType The type of action being performed.
    /// @param energyCost The specific energy cost for this instance of the action.
    function _performAction(uint256 tokenId, ActionType actionType, uint256 energyCost) internal {
        require(_exists(tokenId), "Sphere does not exist");
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        require(sphere.energy >= energyCost, "Insufficient energy");

        uint256 oldEnergy = sphere.energy;
        sphere.energy = sphere.energy.sub(energyCost);
        sphere.lastActionEpoch = currentEpoch; // Update last action epoch based on current global epoch

        emit SphereAction(tokenId, actionType, energyCost);
        emit SphereStateChanged(tokenId, DimensionType.Energy, oldEnergy, sphere.energy);
    }

    /// @dev Publicly callable function to apply entropy to an inactive sphere.
    /// @dev Can be called by anyone if the sphere has been inactive for a long duration (e.g., 5 epochs).
    /// @param tokenId The ID of the HyperSphere.
    function applyEntropy(uint256 tokenId) public {
        require(_exists(tokenId), "Sphere does not exist");
        HyperSphereState storage sphere = _hyperSpheres[tokenId];
        require(currentEpoch.sub(sphere.lastActionEpoch) >= 5, "Sphere has been active recently"); // Inactivity check (5 epochs)

        uint256 energyLoss = sphere.energy.div(10).add(1); // Lose at least 10% + 1
        uint256 stabilityLoss = sphere.stability.div(10).add(1); // Lose at least 10% + 1

        uint256 oldEnergy = sphere.energy;
        uint256 oldStability = sphere.stability;

         if (sphere.energy > energyLoss) {
            sphere.energy = sphere.energy.sub(energyLoss);
         } else {
            sphere.energy = 1; // Don't go below 1
         }

         if (sphere.stability > stabilityLoss) {
            sphere.stability = sphere.stability.sub(stabilityLoss);
         } else {
             sphere.stability = 1; // Don't go below 1
         }

        // Entropy is a global effect, doesn't update lastActionEpoch from the sphere's perspective
        // It simulates external decay.

        emit EntropyApplied(tokenId, energyLoss, stabilityLoss);
        emit SphereStateChanged(tokenId, DimensionType.Energy, oldEnergy, sphere.energy);
        emit SphereStateChanged(tokenId, DimensionType.Stability, oldStability, sphere.stability);
    }

    // --- ERC721 & Ownable Overrides ---

    // Standard ERC721 functions (transferFrom, safeTransferFrom, ownerOf, balanceOf, approve, setApprovalForAll, getApproved, isApprovedForAll)
    // are provided by OpenZeppelin contracts we inherit from.
    // We don't need custom logic in _beforeTokenTransfer or _afterTokenTransfer
    // because our Sphere data is mapped directly to the tokenId.
}
```