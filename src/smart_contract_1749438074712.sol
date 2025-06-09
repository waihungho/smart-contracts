Okay, let's create a smart contract that manages dynamic, evolving digital assets ("Quantum Estates") within a simulated ecosystem ("The Nexus"). It will incorporate concepts like time-based decay/growth (epochs), resource management, inter-asset interactions (entanglement), and dynamic properties (signatures, stability).

This concept is novel as it integrates several mechanics into a single ERC721-like system where assets are not static NFTs but mutable entities affected by time, resources, and interactions, managed by the central contract logic. It's not a standard game contract, NFT collection, or DeFi protocol, but borrows elements to create a unique simulation.

**Contract Name:** `QuantumEstateNexus`

**Core Concept:** A system where users own dynamic "Quantum Estates" represented as tokens. These estates have properties that change over time (epochs) and through user interaction using abstract resources ("Quantum Dust", "Chrono Particles"). Estates can be "entangled" affecting their linked state.

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, Pausable, AccessControl (from OpenZeppelin for robustness)
3.  **Errors:** Custom error definitions
4.  **Events:** To signal state changes
5.  **Enums & Structs:** Define types for resources, modules, and the Estate itself.
6.  **State Variables:** Store contract owner, epoch info, resource balances, estate data, entanglement data, module data, fees, etc.
7.  **Modifiers:** Access control and pausing.
8.  **Constructor:** Initialize contract, set roles.
9.  **ERC721 Core Functions:** Implement/Override basic ERC721 functionality (`transferFrom`, `approve`, `balanceOf`, `ownerOf`, `totalSupply`, etc.).
10. **Estate Management & Interaction Functions:**
    *   Minting new estates.
    *   Applying resources to estates.
    *   Attaching/detaching modules.
    *   Activating/deactivating estates.
    *   Attuning estate signatures.
11. **Resource Management Functions:**
    *   Transferring resources between users.
    *   Claiming epoch-based resource generation/rewards.
12. **Epoch & Evolution Functions:**
    *   Triggering epoch processing (internal or restricted external).
    *   Function to calculate current estate status (view).
13. **Inter-Estate Interaction Functions:**
    *   Entangling two estates.
    *   Dissipating entanglement.
    *   Scanning for resonance (view/simulation helper).
14. **Admin & Nexus Control Functions:**
    *   Setting epoch duration, resource rates, module effects.
    *   Pausing/unpausing.
    *   Withdrawing collected fees.
    *   Managing Nexus roles.
15. **View Functions:** To query detailed state.

**Function Summary:**

1.  `constructor()`: Initializes contract, sets admin role, initial epoch state.
2.  `mintEstate(address recipient, uint256 initialEnergy, uint256 initialStability, uint256 initialSignature)`: Mints a new Quantum Estate token for a recipient with specified initial properties.
3.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Standard ERC721 transfer. Modified to handle potential state like entanglement (dissipating on transfer).
4.  `approve(address to, uint256 tokenId)`: (ERC721) Standard ERC721 approval.
5.  `setApprovalForAll(address operator, bool approved)`: (ERC721) Standard ERC721 approval for all tokens.
6.  `balanceOf(address owner)`: (ERC721) Returns the number of estates owned by an address.
7.  `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of an estate.
8.  `totalSupply()`: (ERC721) Returns the total number of estates minted.
9.  `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for an estate.
10. `isApprovedForAll(address owner, address operator)`: (ERC721) Returns if an operator is approved for all of an owner's estates.
11. `applyQuantumDust(uint256 tokenId, uint256 amount)`: Applies Quantum Dust resource to an estate to boost stability or energy. Requires user to have enough dust.
12. `applyChronoParticles(uint256 tokenId, uint256 amount)`: Applies Chrono Particles resource to an estate to influence evolution or signature. Requires user to have enough particles.
13. `attachModule(uint256 tokenId, ModuleType module)`: Attaches a specified module type to an estate, granting passive effects. May have resource costs.
14. `detachModule(uint256 tokenId)`: Removes the currently attached module from an estate. May recover some resources or have a cost.
15. `activateEstate(uint256 tokenId)`: Marks an estate as active, potentially affecting epoch processing (e.g., resource generation, faster decay).
16. `deactivateEstate(uint256 tokenId)`: Marks an estate as inactive, potentially pausing decay or generation.
17. `attuneEstateSignature(uint256 tokenId, uint256 newSignature)`: Changes the signature of an estate, possibly consuming Chrono Particles and incurring a fee.
18. `entangleEstates(uint256 tokenId1, uint256 tokenId2)`: Creates an entanglement link between two estates, potentially affecting their state based on each other. Requires ownership of both.
19. `dissipateEntanglement(uint256 tokenId)`: Breaks the entanglement link involving a specific estate. Can be called by either owner.
20. `processEpoch(uint256[] tokenIds)`: Advances the state for a batch of estates for the current epoch, applying time-based decay/growth, module effects, and entanglement effects. *Can be called by anyone (with gas cost) but only processes estates needing updates.* Rewards might be distributed internally.
21. `claimEpochRewards()`: Allows users to claim accumulated resource rewards from processed epochs based on their active estates and roles.
22. `transferResource(ResourceType resourceType, address to, uint256 amount)`: Transfers a specified resource balance from the caller to another address.
23. `setEpochDuration(uint256 duration)`: (Admin) Sets the duration (in blocks or time) of an epoch.
24. `setResourceRates(ResourceType resourceType, ResourceRateType rateType, uint256 rate)`: (Admin) Sets parameters for resource generation, decay, or application effects.
25. `setModuleEffects(ModuleType module, uint256 energyBoost, uint256 stabilityBoost, int256 signatureInfluence)`: (Admin) Configures the effects of different module types.
26. `pause()`: (Admin) Pauses key contract functionalities (transfers, interactions, epoch processing).
27. `unpause()`: (Admin) Unpauses the contract.
28. `withdrawFees(address payable recipient)`: (Admin) Withdraws accumulated protocol fees (e.g., from signature tuning) to a recipient.
29. `grantNexusRole(bytes32 role, address account)`: (Admin) Grants a specific administrative or operational role within the Nexus (e.g., MINTER_ROLE, EPOCH_MANAGER_ROLE).
30. `revokeNexusRole(bytes32 role, address account)`: (Admin) Revokes a specific role.
31. `getUserResourceBalance(address user, ResourceType resourceType)`: (View) Returns the resource balance for a user.
32. `getEstateDetails(uint256 tokenId)`: (View) Returns comprehensive details about an estate's current state (energy, stability, signature, active status, module).
33. `getEpochInfo()`: (View) Returns information about the current epoch (number, start block/time, duration).
34. `getEntangledPair(uint256 tokenId)`: (View) Returns the token ID of the estate entangled with the given estate, or 0 if none.
35. `getEstateSignature(uint256 tokenId)`: (View) Returns the current signature of an estate.
36. `calculateCurrentEstateState(uint256 tokenId)`: (View) *Internal helper logic often exposed via `getEstateDetails`*. Calculates the *current* state accounting for time elapsed since last process, applying decay/growth based on rules, activity status, and modules.

*(Note: Some standard ERC721 functions like `tokenURI`, `tokenByIndex`, `tokenOfOwnerByIndex` are omitted for brevity and focus on the unique mechanics, but would be included in a full implementation.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- Error Definitions ---
error QuantumEstateNexus__OnlyEstateOwner(uint256 tokenId);
error QuantumEstateNexus__OnlyEstateOwnerOrApproved(uint256 tokenId);
error QuantumEstateNexus__EstateDoesNotExist(uint256 tokenId);
error QuantumEstateNexus__NotEnoughResources(ResourceType resourceType, uint256 required, uint256 available);
error QuantumEstateNexus__ModuleAlreadyAttached(uint256 tokenId);
error QuantumEstateNexus__NoModuleAttached(uint256 tokenId);
error QuantumEstateNexus__EstatesAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
error QuantumEstateNexus__EstatesNotEntangled(uint256 tokenId1, uint256 tokenId2);
error QuantumEstateNexus__CannotEntangleSelf();
error QuantumEstateNexus__EstateNotYetProcessedForEpoch(uint256 tokenId, uint256 currentEpoch);
error QuantumEstateNexus__TransferOfEntangledEstateForbidden(uint256 tokenId);


// --- Event Definitions ---
event EstateMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 initialStability, uint256 initialSignature);
event ResourcesApplied(uint256 indexed tokenId, ResourceType indexed resourceType, uint256 amount, uint256 newEnergy, uint256 newStability);
event ModuleAttached(uint256 indexed tokenId, ModuleType indexed module);
event ModuleDetached(uint256 indexed tokenId, ModuleType indexed module);
event EstateActivated(uint256 indexed tokenId);
event EstateDeactivated(uint256 indexed tokenId);
event SignatureAttuned(uint256 indexed tokenId, uint256 oldSignature, uint256 newSignature, uint256 feePaid);
event EstatesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
event EntanglementDissipated(uint256 indexed tokenId1, uint256 indexed tokenId2);
event EpochProcessed(uint256 indexed epoch, uint256 indexed tokenId, uint256 energyChange, uint256 stabilityChange, uint256 resourcesGenerated);
event EpochRewardsClaimed(address indexed user, uint256 quantumDustClaimed, uint256 chronoParticlesClaimed);
event ResourceTransfer(address indexed from, address indexed to, ResourceType indexed resourceType, uint256 amount);
event EpochDurationSet(uint256 newDuration);
event ResourceRatesSet(ResourceType indexed resourceType, ResourceRateType indexed rateType, uint256 rate);
event ModuleEffectsSet(ModuleType indexed module, uint256 energyBoost, uint256 stabilityBoost, int256 signatureInfluence);
event FeesWithdrawn(address indexed recipient, uint256 amount);


// --- Enums & Structs ---

enum ResourceType { QuantumDust, ChronoParticles }
enum ResourceRateType { DecayRate, GrowthRate, ApplicationEffectEnergy, ApplicationEffectStability, SignatureAttunementCost, SignatureAttunementFee, EpochGenerationActive, EpochGenerationInactive }
enum ModuleType { None, StabilityEnhancer, EnergyAmplifier, SignatureStabilizer, ChronoAccelerator } // Example Modules

struct Estate {
    uint256 energy;      // Represents vitality, can decay
    uint256 stability;   // Represents resilience, decays slower, affects energy decay
    uint256 signature;   // Dynamic property, can be tuned, used for resonance
    uint64 locationHash; // Abstract location identifier (e.g., hash of coordinates) - simplified
    bool isActive;       // Affects epoch processing rules (generation/decay)
    ModuleType module;   // Attached module type
    uint48 lastProcessedTimestamp; // Timestamp of the last epoch processing for this specific estate
    uint32 lastProcessedEpoch; // Epoch number of the last processing
}

struct EpochState {
    uint32 epochNumber;
    uint48 startTimestamp;
}

// --- State Variables ---

bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 public constant EPOCH_MANAGER_ROLE = keccak256("EPOCH_MANAGER_ROLE");
bytes32 public constant RESOURCE_MANAGER_ROLE = keccak256("RESOURCE_MANAGER_ROLE"); // For setting rates etc.

using Counters for Counters.Counter;
Counters.Counter private _estateIds;

// ERC721 state handled by inheritance

mapping(uint256 => Estate) private _estates; // tokenId => Estate details
mapping(address => mapping(ResourceType => uint256)) private _userResources; // user => resourceType => balance
mapping(uint256 => uint256) private _entangledPairs; // tokenId1 => tokenId2 (symmetric)
mapping(ResourceType => mapping(ResourceRateType => uint256)) private _resourceRates; // resourceType => rateType => rate value
mapping(ModuleType => ModuleEffects) private _moduleEffects; // moduleType => effects
mapping(address => mapping(ResourceType => uint256)) private _epochResourceRewards; // user => resourceType => unclaimed rewards

struct ModuleEffects {
    uint256 energyBoost;
    uint256 stabilityBoost;
    int256 signatureInfluence; // Can be positive or negative
}

EpochState public currentEpochState;
uint256 public epochDuration = 1 days; // Example: 1 day in seconds

uint256 public nexusFeesCollected;


// --- Contract Implementation ---

contract QuantumEstateNexus is ERC721, Pausable, AccessControl {

    constructor(address admin)
        ERC721("QuantumEstateNexus", "QEN")
        Pausable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(EPOCH_MANAGER_ROLE, admin);
        _grantRole(RESOURCE_MANAGER_ROLE, admin);

        // Set initial epoch state
        currentEpochState.epochNumber = 1;
        currentEpochState.startTimestamp = uint48(block.timestamp);

        // Set some default resource rates (example values)
        _resourceRates[ResourceType.QuantumDust][ResourceRateType.ApplicationEffectEnergy] = 10; // 1 QD = 10 energy
        _resourceRates[ResourceType.QuantumDust][ResourceRateType.ApplicationEffectStability] = 5; // 1 QD = 5 stability
        _resourceRates[ResourceType.ChronoParticles][ResourceRateType.SignatureAttunementCost] = 100; // 100 CP per tuning
        _resourceRates[ResourceType.ChronoParticles][ResourceRateType.EpochGenerationActive] = 5; // 5 CP generated per active estate per epoch
        _resourceRates[ResourceType.QuantumDust][ResourceRateType.DecayRate] = 1; // Base energy decay per unit of time (per epoch)
        _resourceRates[ResourceType.QuantumDust][ResourceRateType.SignatureAttunementFee] = 10; // 10 QD fee per tuning

        // Set some default module effects
        _moduleEffects[ModuleType.StabilityEnhancer] = ModuleEffects({
            energyBoost: 0,
            stabilityBoost: 20,
            signatureInfluence: 0
        });
        _moduleEffects[ModuleType.EnergyAmplifier] = ModuleEffects({
            energyBoost: 30,
            stabilityBoost: 0,
            signatureInfluence: 0
        });
        _moduleEffects[ModuleType.SignatureStabilizer] = ModuleEffects({
            energyBoost: 5,
            stabilityBoost: 5,
            signatureInfluence: 0 // Prevents signature changes or reduces decay/randomness
        });
         _moduleEffects[ModuleType.ChronoAccelerator] = ModuleEffects({
            energyBoost: 0,
            stabilityBoost: 0,
            signatureInfluence: 5 // Might subtly shift signature over time
        });
    }

    // --- ERC721 Core Function Overrides ---

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
        whenNotPaused
    {
        // Dissipate entanglement before transfer
        if (_entangledPairs[tokenId] != 0) {
            revert QuantumEstateNexus__TransferOfEntangledEstateForbidden(tokenId);
             // Alternative: automatically dissipate entanglement:
             // dissipateEntanglement(tokenId);
             // This requires careful re-structuring or making _dissipateEntanglement internal
             // For simplicity here, disallow transfer of entangled estates.
        }
        super.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721)
        whenNotPaused
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721)
        whenNotPaused
    {
        super.setApprovalForAll(operator, approved);
    }

    // Standard ERC721 view functions like balanceOf, ownerOf, totalSupply, getApproved, isApprovedForAll are inherited

    // --- Estate Management & Interaction Functions ---

    /**
     * @notice Mints a new Quantum Estate token.
     * @param recipient The address to mint the estate for.
     * @param initialEnergy Initial energy level.
     * @param initialStability Initial stability level.
     * @param initialSignature Initial signature value.
     */
    function mintEstate(address recipient, uint256 initialEnergy, uint256 initialStability, uint256 initialSignature)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _estateIds.increment();
        uint256 tokenId = _estateIds.current();

        _safeMint(recipient, tokenId);

        _estates[tokenId] = Estate({
            energy: initialEnergy,
            stability: initialStability,
            signature: initialSignature,
            locationHash: uint64(keccak256(abi.encodePacked(tokenId))), // Simplified location
            isActive: true, // Default to active
            module: ModuleType.None,
            lastProcessedTimestamp: uint48(block.timestamp),
            lastProcessedEpoch: currentEpochState.epochNumber
        });

        emit EstateMinted(tokenId, recipient, initialEnergy, initialStability, initialSignature);
    }

    /**
     * @notice Applies Quantum Dust resource to an estate.
     * @param tokenId The ID of the estate.
     * @param amount The amount of Quantum Dust to apply.
     */
    function applyQuantumDust(uint256 tokenId, uint256 amount)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwnerOrApproved(tokenId);
        if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        if (_userResources[_msgSender()][ResourceType.QuantumDust] < amount) {
            revert QuantumEstateNexus__NotEnoughResources(ResourceType.QuantumDust, amount, _userResources[_msgSender()][ResourceType.QuantumDust]);
        }

        // Ensure estate state is reasonably up-to-date before applying resources
        // In a real system, processing might be needed first. Here, we'll add resources directly.
        uint256 currentEnergy = _estates[tokenId].energy;
        uint256 currentStability = _estates[tokenId].stability;

        uint256 energyBoost = amount * _resourceRates[ResourceType.QuantumDust][ResourceRateType.ApplicationEffectEnergy];
        uint256 stabilityBoost = amount * _resourceRates[ResourceType.QuantumDust][ResourceRateType.ApplicationEffectStability];

        _estates[tokenId].energy = currentEnergy + energyBoost;
        _estates[tokenId].stability = currentStability + stabilityBoost;

        _userResources[_msgSender()][ResourceType.QuantumDust] -= amount;

        emit ResourcesApplied(tokenId, ResourceType.QuantumDust, amount, _estates[tokenId].energy, _estates[tokenId].stability);
    }

     /**
     * @notice Applies Chrono Particles resource to an estate.
     * @param tokenId The ID of the estate.
     * @param amount The amount of Chrono Particles to apply.
     */
    function applyChronoParticles(uint256 tokenId, uint256 amount)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwnerOrApproved(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        if (_userResources[_msgSender()][ResourceType.ChronoParticles] < amount) {
            revert QuantumEstateNexus__NotEnoughResources(ResourceType.ChronoParticles, amount, _userResources[_msgSender()][ResourceType.ChronoParticles]);
        }

        // Example effect: maybe CP slightly boosts stability or influences signature change probability
        // Let's make it a small stability boost for simplicity here
        uint256 stabilityBoost = amount / 10; // Example: 10 CP gives 1 stability

        _estates[tokenId].stability += stabilityBoost;

        _userResources[_msgSender()][ResourceType.ChronoParticles] -= amount;

        emit ResourcesApplied(tokenId, ResourceType.ChronoParticles, amount, _estates[tokenId].energy, _estates[tokenId].stability);
    }

    /**
     * @notice Attaches a module to an estate.
     * @param tokenId The ID of the estate.
     * @param module The type of module to attach. Must not be ModuleType.None.
     */
    function attachModule(uint256 tokenId, ModuleType module)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        if (module == ModuleType.None) revert QuantumEstateNexus__NoModuleAttached(tokenId); // Or specific error
        if (_estates[tokenId].module != ModuleType.None) revert QuantumEstateNexus__ModuleAlreadyAttached(tokenId);

        // Add logic here for module costs or requirements (e.g., burning a separate module token)
        // For now, it's free to attach if you call the function

        _estates[tokenId].module = module;

        // Apply immediate effects, if any (or effects are only during epoch processing)
        // Let's make effects passive during epoch processing.

        emit ModuleAttached(tokenId, module);
    }

    /**
     * @notice Detaches the module from an estate.
     * @param tokenId The ID of the estate.
     */
    function detachModule(uint256 tokenId)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        if (_estates[tokenId].module == ModuleType.None) revert QuantumEstateNexus__NoModuleAttached(tokenId);

        ModuleType detachedModule = _estates[tokenId].module;
        _estates[tokenId].module = ModuleType.None;

        // Add logic here for resource recovery or cost upon detachment if needed

        emit ModuleDetached(tokenId, detachedModule);
    }

    /**
     * @notice Sets an estate to active status. Active estates may generate resources but decay faster.
     * @param tokenId The ID of the estate.
     */
    function activateEstate(uint256 tokenId)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        _estates[tokenId].isActive = true;
        emit EstateActivated(tokenId);
    }

    /**
     * @notice Sets an estate to inactive status. Inactive estates may not generate resources but decay slower or pause decay.
     * @param tokenId The ID of the estate.
     */
    function deactivateEstate(uint256 tokenId)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        _estates[tokenId].isActive = false;
        emit EstateDeactivated(tokenId);
    }

    /**
     * @notice Allows the owner to pay resources and fee to change the estate's signature.
     * @param tokenId The ID of the estate.
     * @param newSignature The new desired signature value.
     */
    function attuneEstateSignature(uint256 tokenId, uint256 newSignature)
        external
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        uint256 cpCost = _resourceRates[ResourceType.ChronoParticles][ResourceRateType.SignatureAttunementCost];
        uint256 dustFee = _resourceRates[ResourceType.QuantumDust][ResourceRateType.SignatureAttunementFee];

        if (_userResources[_msgSender()][ResourceType.ChronoParticles] < cpCost) {
            revert QuantumEstateNexus__NotEnoughResources(ResourceType.ChronoParticles, cpCost, _userResources[_msgSender()][ResourceType.ChronoParticles]);
        }
         if (_userResources[_msgSender()][ResourceType.QuantumDust] < dustFee) {
            revert QuantumEstateNexus__NotEnoughResources(ResourceType.QuantumDust, dustFee, _userResources[_msgSender()][ResourceType.QuantumDust]);
        }

        _userResources[_msgSender()][ResourceType.ChronoParticles] -= cpCost;
        _userResources[_msgSender()][ResourceType.QuantumDust] -= dustFee; // Burn or collect Dust fee

        nexusFeesCollected += dustFee; // Collect fee

        uint256 oldSignature = _estates[tokenId].signature;
        _estates[tokenId].signature = newSignature;

        emit SignatureAttuned(tokenId, oldSignature, newSignature, dustFee);
    }

    // --- Inter-Estate Interaction Functions ---

    /**
     * @notice Entangles two estates. Requires caller to own both.
     * @param tokenId1 The ID of the first estate.
     * @param tokenId2 The ID of the second estate.
     */
    function entangleEstates(uint256 tokenId1, uint256 tokenId2)
        external
        whenNotPaused
    {
        if (tokenId1 == tokenId2) revert QuantumEstateNexus__CannotEntangleSelf();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (owner1 != _msgSender() || owner2 != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId1); // Or more specific error

        if (_estates[tokenId1].energy == 0 && _estates[tokenId1].stability == 0 && _estates[tokenId1].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId1); // Check existence
        if (_estates[tokenId2].energy == 0 && _estates[tokenId2].stability == 0 && _estates[tokenId2].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId2); // Check existence

        if (_entangledPairs[tokenId1] != 0 || _entangledPairs[tokenId2] != 0) {
            revert QuantumEstateNexus__EstatesAlreadyEntangled(tokenId1, tokenId2);
        }

        _entangledPairs[tokenId1] = tokenId2;
        _entangledPairs[tokenId2] = tokenId1;

        // Entanglement might have immediate state effects or modify epoch processing

        emit EstatesEntangled(tokenId1, tokenId2);
    }

    /**
     * @notice Dissipates the entanglement involving a specific estate. Can be called by the owner of the estate.
     * @param tokenId The ID of the estate.
     */
    function dissipateEntanglement(uint256 tokenId)
        public // Made public so transferFrom could potentially call it (if logic changed)
        whenNotPaused
    {
        address estateOwner = ownerOf(tokenId);
        if (estateOwner != _msgSender()) revert QuantumEstateNexus__OnlyEstateOwner(tokenId);
         if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId); // Check existence

        uint256 entangledTokenId = _entangledPairs[tokenId];
        if (entangledTokenId == 0) revert QuantumEstateNexus__EstatesNotEntangled(tokenId, 0);

        // Ensure the other estate still exists and is entangled with this one
         if (_estates[entangledTokenId].energy == 0 && _estates[entangledTokenId].stability == 0 && _estates[entangledTokenId].signature == 0) {
             // Handle case where entangled estate was burned/destroyed - should auto-dissipate?
             delete _entangledPairs[tokenId];
             // Emit event anyway? Or separate event?
             emit EntanglementDissipated(tokenId, entangledTokenId);
             return;
         }
        if (_entangledPairs[entangledTokenId] != tokenId) revert QuantumEstateNexus__EstatesNotEntangled(tokenId, entangledTokenId);


        delete _entangledPairs[tokenId];
        delete _entangledPairs[entangledTokenId];

        emit EntanglementDissipated(tokenId, entangledTokenId);
    }

    /**
     * @notice Simulates scanning for estates with similar signatures within a conceptual range.
     * Note: On-chain simulation is limited. This is a placeholder/helper.
     * A real implementation might use off-chain indexing and provide proof or just query a subgraph.
     * @param tokenId The ID of the scanning estate.
     * @param threshold The similarity threshold for signatures.
     * @return A list of token IDs with signatures within the threshold. (Placeholder - returning empty array)
     */
    function scanForResonance(uint256 tokenId, uint256 threshold)
        external // external view is ok, but returning dynamic array of unknown size is gas risky for actual use
        view
        returns (uint256[] memory)
    {
        // Check existence
        if (_estates[tokenId].energy == 0 && _estates[tokenId].stability == 0 && _estates[tokenId].signature == 0) revert QuantumEstateNexus__EstateDoesNotExist(tokenId);

        // This function is highly gas-prohibitive for large numbers of estates.
        // A real implementation would require off-chain computation or a different approach.
        // Returning an empty array as a placeholder.
        return new uint256[](0);

        /*
        // Example concept (do NOT deploy this loop with many estates):
        uint256 scanningSignature = _estates[tokenId].signature;
        uint256 total = totalSupply();
        uint256[] memory resonantEstates = new uint256[](total); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= total; i++) {
            // Add checks for existence and that it's not the scanning estate itself
            if (_exists(i) && i != tokenId) {
                uint256 targetSignature = _estates[i].signature;
                uint256 diff = (scanningSignature > targetSignature) ? (scanningSignature - targetSignature) : (targetSignature - scanningSignature);
                if (diff <= threshold) {
                    resonantEstates[count] = i;
                    count++;
                }
            }
        }
        // Return a correctly sized array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = resonantEstates[i];
        }
        return result;
        */
    }


    // --- Epoch & Evolution Functions ---

    /**
     * @notice Processes the state evolution for a batch of estates based on elapsed time and epoch rules.
     * Can be called by anyone, paying gas, to advance state for specific estates.
     * Automatically advances epoch if duration passed and any estates from the new epoch need processing.
     * @param tokenIds A list of estate IDs to process.
     */
    function processEpoch(uint256[] calldata tokenIds)
        external
        whenNotPaused
    {
        uint48 currentTimestamp = uint48(block.timestamp);
        uint32 startingEpoch = currentEpochState.epochNumber;

        // Check if epoch needs to advance
        if (currentTimestamp >= currentEpochState.startTimestamp + epochDuration) {
             currentEpochState.epochNumber++;
             currentEpochState.startTimestamp = currentTimestamp; // Or currentEpochState.startTimestamp + epochDuration for strict intervals
        }

        uint32 epochToProcessFor = currentEpochState.epochNumber;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // Check if estate exists and needs processing for the current/new epoch
             if (!_exists(tokenId) || _estates[tokenId].lastProcessedEpoch >= epochToProcessFor) {
                 continue; // Skip if already processed for this epoch or doesn't exist
             }

            Estate storage estate = _estates[tokenId];

            // --- Apply Decay ---
            // Decay amount might depend on time since last process, stability, and modules
            uint256 decayRate = _resourceRates[ResourceType.QuantumDust][ResourceRateRateType.DecayRate]; // Base decay per epoch

            // Adjust decay based on stability (higher stability = less decay)
            // Example: decay = baseDecay * (100 - stability) / 100
            uint256 effectiveDecay = (decayRate * Math.max(0, 100 - estate.stability)) / 100;

            // Adjust decay based on activity (active decays faster)
            if (estate.isActive) {
                effectiveDecay = effectiveDecay * 2; // Example: active estates decay twice as fast
            }

             // Adjust decay based on modules (e.g., StabilityEnhancer reduces decay)
             ModuleEffects memory moduleEff = _moduleEffects[estate.module];
             // Example: stability boost from module reduces effective decay
             effectiveDecay = (effectiveDecay * 100) / Math.max(1, 100 + moduleEff.stabilityBoost);


            uint256 energyChange = 0; // Track changes for event
            uint256 stabilityChange = 0; // Track changes for event
            uint256 resourcesGenerated = 0; // Track generation for event

            if (estate.energy >= effectiveDecay) {
                estate.energy -= effectiveDecay;
                energyChange = effectiveDecay;
            } else {
                energyChange = estate.energy;
                estate.energy = 0; // Energy hits zero
                // Optional: Estate becomes dormant/unstable when energy hits zero
                // estate.isActive = false;
            }


            // --- Apply Growth/Generation (if any) ---
            if (estate.isActive) {
                 uint256 cpGenerationRate = _resourceRates[ResourceType.ChronoParticles][ResourceRateType.EpochGenerationActive];
                 // Add generation based on modules too? E.g., ChronoAccelerator boosts CP gen.
                 // uint256 generationBoostFromModule = (moduleEff.signatureInfluence > 0) ? uint256(moduleEff.signatureInfluence) : 0;
                 uint256 generatedCP = cpGenerationRate; // + generationBoostFromModule;

                 address estateOwner = ownerOf(tokenId);
                 _epochResourceRewards[estateOwner][ResourceType.ChronoParticles] += generatedCP;
                 resourcesGenerated = generatedCP;
            }

            // --- Apply Entanglement Effects ---
            uint256 entangledTokenId = _entangledPairs[tokenId];
            if (entangledTokenId != 0) {
                // Example: Entangled estates share average energy/stability after decay,
                // or one drains the other, or their signatures influence each other.
                // This requires fetching the entangled estate's state, processing it too (potentially),
                // and then applying interaction effects. This adds significant complexity.
                // For simplicity, let's say entanglement *might* influence decay/growth rates slightly,
                // or add a small signature drift based on the entangled partner's signature.
                // Example: Signature drifts towards entangled partner's signature by a small amount.
                // uint256 partnerSignature = _estates[entangledTokenId].signature;
                // int256 signatureDiff = int256(partnerSignature) - int256(estate.signature);
                // estate.signature = uint256(int256(estate.signature) + signatureDiff / 10); // Drift by 10% of difference
            }


            // --- Update Processing State ---
            estate.lastProcessedTimestamp = currentTimestamp;
            estate.lastProcessedEpoch = epochToProcessFor;

            emit EpochProcessed(epochToProcessFor, tokenId, energyChange, stabilityChange, resourcesGenerated);
        }
         // Note: This `processEpoch` is simplified. A robust system would need to handle:
         // 1. Ensuring processing covers the *correct* time duration since the last process, not just "per epoch".
         // 2. Handling many estates - potentially requiring off-chain workers to call this function for batches.
         // 3. Complex inter-estate effects needing entangled pairs processed together or in dependency order.
         // 4. Randomness for signature drift, critical events, etc. (requires Chainlink VRF or similar).
    }

    /**
     * @notice Allows users to claim resource rewards accumulated from active estates processed in epochs.
     */
    function claimEpochRewards()
        external
        whenNotPaused
    {
        uint256 dustRewards = _epochResourceRewards[_msgSender()][ResourceType.QuantumDust];
        uint256 cpRewards = _epochResourceRewards[_msgSender()][ResourceType.ChronoParticles];

        if (dustRewards == 0 && cpRewards == 0) return;

        _userResources[_msgSender()][ResourceType.QuantumDust] += dustRewards;
        _userResources[_msgSender()][ResourceType.ChronoParticles] += cpRewards;

        _epochResourceRewards[_msgSender()][ResourceType.QuantumDust] = 0;
        _epochResourceRewards[_msgSender()][ResourceType.ChronoParticles] = 0;

        emit EpochRewardsClaimed(_msgSender(), dustRewards, cpRewards);
    }


    // --- Resource Management Functions ---

    /**
     * @notice Transfers resource balance between users within the Nexus state.
     * @param resourceType The type of resource to transfer.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferResource(ResourceType resourceType, address to, uint256 amount)
        external
        whenNotPaused
    {
        if (_userResources[_msgSender()][resourceType] < amount) {
             revert QuantumEstateNexus__NotEnoughResources(resourceType, amount, _userResources[_msgSender()][resourceType]);
        }
        _userResources[_msgSender()][resourceType] -= amount;
        _userResources[to][resourceType] += amount;

        emit ResourceTransfer(_msgSender(), to, resourceType, amount);
    }


    // --- Admin & Nexus Control Functions ---

    /**
     * @notice Sets the duration of an epoch in seconds. Only callable by RESOURCE_MANAGER_ROLE or Admin.
     * @param duration The new duration in seconds.
     */
    function setEpochDuration(uint256 duration)
        external
        onlyRole(RESOURCE_MANAGER_ROLE)
        whenNotPaused // Can't change duration while paused? Maybe allow.
    {
        epochDuration = duration;
        // Optional: Adjust current epoch end time based on new duration? Or let it end naturally.
        emit EpochDurationSet(duration);
    }

     /**
     * @notice Sets various resource rates (decay, growth, application effects). Only callable by RESOURCE_MANAGER_ROLE or Admin.
     * @param resourceType The type of resource the rate applies to.
     * @param rateType The type of rate being set.
     * @param rate The new rate value.
     */
    function setResourceRates(ResourceType resourceType, ResourceRateType rateType, uint256 rate)
        external
        onlyRole(RESOURCE_MANAGER_ROLE)
        whenNotPaused
    {
        _resourceRates[resourceType][rateType] = rate;
        emit ResourceRatesSet(resourceType, rateType, rate);
    }

     /**
     * @notice Configures the effects granted by different module types. Only callable by RESOURCE_MANAGER_ROLE or Admin.
     * @param module The module type being configured.
     * @param energyBoost Boost to energy provided by the module (e.g., multiplier or flat add).
     * @param stabilityBoost Boost to stability.
     * @param signatureInfluence Influence on signature evolution (can be negative).
     */
    function setModuleEffects(ModuleType module, uint256 energyBoost, uint256 stabilityBoost, int256 signatureInfluence)
        external
        onlyRole(RESOURCE_MANAGER_ROLE)
        whenNotPaused
    {
        _moduleEffects[module] = ModuleEffects({
            energyBoost: energyBoost,
            stabilityBoost: stabilityBoost,
            signatureInfluence: signatureInfluence
        });
        emit ModuleEffectsSet(module, energyBoost, stabilityBoost, signatureInfluence);
    }

    /**
     * @notice Pauses key interactions with the contract. Only callable by DEFAULT_ADMIN_ROLE.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses key interactions with the contract. Only callable by DEFAULT_ADMIN_ROLE.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

     /**
     * @notice Withdraws accumulated protocol fees to a recipient. Only callable by DEFAULT_ADMIN_ROLE.
     * Fees are tracked internally as ResourceType balances (e.g., Quantum Dust collected from tuning).
     * This function withdraws accumulated *value*, not the resource units themselves externally.
     * Let's assume fees are tracked in a specific resource (like Quantum Dust fee from attuning).
     * A real system might use ether or a separate fee token. Here we withdraw the accumulated Dust 'value'.
     * Simplified: Assume fee is collected in QD and this function sends QD from a 'fee collector' address.
     * Let's make it withdraw the internal `nexusFeesCollected` balance, assumed to be QD units for this example.
     * A more robust fee system would involve separate balance tracking or ETH/token payments.
     * For this implementation, let's make `nexusFeesCollected` represent a withdrawable balance, like ETH/WEth collected.
     * We'll modify `attuneEstateSignature` to charge ETH/msg.value instead of burning Dust as fee.
     */
    function withdrawFees(address payable recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused // Cannot withdraw fees if paused? Maybe allow.
    {
        uint256 amount = nexusFeesCollected;
        if (amount == 0) return;

        nexusFeesCollected = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(recipient, amount);
    }

     /**
     * @notice Grants a specific role to an account. Wrapper for AccessControl.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantNexusRole(bytes32 role, address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(role, account);
    }

     /**
     * @notice Revokes a specific role from an account. Wrapper for AccessControl.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeNexusRole(bytes32 role, address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
         // Prevent revoking own admin role unless renouncing explicitly
        if (role == DEFAULT_ADMIN_ROLE && account == _msgSender()) {
            revert AccessControlUnauthorizedAccount(_msgSender(), role);
        }
        revokeRole(role, account);
    }

    // Renounce role is inherited from AccessControl


    // --- View Functions ---

     /**
     * @notice Returns the resource balance for a user.
     * @param user The user's address.
     * @param resourceType The type of resource.
     * @return The balance of the specified resource for the user.
     */
    function getUserResourceBalance(address user, ResourceType resourceType)
        external
        view
        returns (uint256)
    {
        return _userResources[user][resourceType];
    }

    /**
     * @notice Returns comprehensive details about an estate's current state.
     * Note: This function does NOT process the epoch effects. State might be outdated until processEpoch is called.
     * Use calculateCurrentEstateState (if implemented) for up-to-date values.
     * @param tokenId The ID of the estate.
     * @return estateDetails Struct containing the estate's properties.
     */
    function getEstateDetails(uint256 tokenId)
        external
        view
        returns (Estate memory estateDetails)
    {
        if (!_exists(tokenId)) revert QuantumEstateNexus__EstateDoesNotExist(tokenId);
        return _estates[tokenId];
    }

    /**
     * @notice Returns information about the current epoch.
     * @return epochNumber The current epoch number.
     * @return startTimestamp The timestamp when the current epoch started.
     * @return duration The duration of an epoch in seconds.
     */
    function getEpochInfo()
        external
        view
        returns (uint32 epochNumber, uint48 startTimestamp, uint256 duration)
    {
        return (currentEpochState.epochNumber, currentEpochState.startTimestamp, epochDuration);
    }

    /**
     * @notice Returns the token ID of the estate entangled with the given estate.
     * @param tokenId The ID of the estate.
     * @return The token ID of the entangled estate, or 0 if none.
     */
    function getEntangledPair(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        // Check existence? Or just return 0 if not found? Let's check existence.
        if (!_exists(tokenId)) revert QuantumEstateNexus__EstateDoesNotExist(tokenId);
        return _entangledPairs[tokenId];
    }

    /**
     * @notice Returns the current signature of an estate.
     * @param tokenId The ID of the estate.
     * @return The estate's signature.
     */
    function getEstateSignature(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        if (!_exists(tokenId)) revert QuantumEstateNexus__EstateDoesNotExist(tokenId);
        return _estates[tokenId].signature;
    }

     /**
     * @notice Returns the accumulated unclaimed resource rewards for a user.
     * @param user The user's address.
     * @param resourceType The type of resource.
     * @return The amount of unclaimed rewards for the specified resource.
     */
    function getUnclaimedEpochRewards(address user, ResourceType resourceType)
        external
        view
        returns (uint256)
    {
        return _epochResourceRewards[user][resourceType];
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // Internal helper to check estate existence robustly
    function _exists(uint256 tokenId) internal view returns (bool) {
         // ERC721's _exists is marked internal. Check owner.
        address owner = ERC721.ownerOf(tokenId); // Will revert if token doesn't exist standardly
        // We also need to check if it was minted but potentially zeroed out by logic,
        // but the current design doesn't zero out structs, only deletes map keys.
        // ownerOf(tokenId) will revert for non-existent tokens per standard ERC721.
        return owner != address(0); // ownerOf reverts for non-existent. This check is somewhat redundant but safer against potential future logic changes.
    }
}
```