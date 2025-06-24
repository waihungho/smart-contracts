Okay, here is a Solidity smart contract named `QuantumFluxChronicles`.

This contract implements a dynamic NFT concept where tokens represent "Chronicles" with evolving properties based on time, interactions, and potentially external data (simulated via privileged functions). It combines elements of NFTs, timed mechanics, resource generation/consumption, configuration profiles, delegation, and state transitions, aiming for a creative and advanced combination of concepts not typically found in a single standard open-source contract.

It uses OpenZeppelin's battle-tested ERC721 and AccessControl libraries for foundational security and standards compliance while adding significant custom logic.

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary libraries (ERC721, AccessControl, Context).
2.  **Errors:** Define custom errors for gas efficiency.
3.  **Events:** Define events to signal important state changes.
4.  **Roles:** Define Access Control roles.
5.  **Structs:** Define data structures for `Chronicle` and `ChronicleConfig`.
6.  **State Variables:** Declare mappings, counters, and default values.
7.  **Constructor:** Initialize roles and basic contract state.
8.  **Modifiers:** Define custom modifiers for common checks.
9.  **Configuration Management:** Functions to add and update `ChronicleConfig` profiles.
10. **Minting:** Functions to create new Chronicle NFTs.
11. **Core Dynamic Logic:** Function to apply "Flux" (time-based state evolution).
12. **External Interaction Logic:** Function to apply flux based on external data (simulated).
13. **State & Resource Management:** Functions to transition state, consume potential, and claim rewards.
14. **Chronicle Properties Management:** Functions to seal/unseal and toggle traits.
15. **Advanced/Novel Mechanics:** Functions for merging Chronicles, delegating flux application, and predictive calculations.
16. **Access Control:** Standard functions from `AccessControl`.
17. **ERC721 Standard Functions:** Required functions from `ERC721` (some potentially overridden with hooks).
18. **Query Functions:** Read-only functions to retrieve Chronicle and config data.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets admin roles, and optionally sets initial configurations.
2.  `supportsInterface(bytes4 interfaceId)`: ERC165 standard function to declare interface support.
3.  `balanceOf(address owner)`: ERC721 standard function.
4.  `ownerOf(uint256 tokenId)`: ERC721 standard function.
5.  `approve(address to, uint256 tokenId)`: ERC721 standard function.
6.  `getApproved(uint256 tokenId)`: ERC721 standard function.
7.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard function.
8.  `isApprovedForAll(address owner, address operator)`: ERC721 standard function.
9.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard function (hooked for sealed check).
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard function (hooked for sealed check).
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard function (hooked for sealed check).
12. `getRoleAdmin(bytes32 role)`: AccessControl standard function.
13. `grantRole(bytes32 role, address account)`: AccessControl standard function.
14. `revokeRole(bytes32 role, address account)`: AccessControl standard function.
15. `renounceRole(bytes32 role, address account)`: AccessControl standard function.
16. `addChronicleConfig(uint16 configId, uint32 baseFluxRate, uint32 potentialPerFlux, uint32 stateTransitionFluxThreshold, uint32 maxFluxLevel)`: Adds or updates a Chronicle configuration profile (Admin only).
17. `updateChronicleConfig(uint16 configId, uint32 baseFluxRate, uint32 potentialPerFlux, uint32 stateTransitionFluxThreshold, uint32 maxFluxLevel)`: Updates an existing Chronicle configuration profile (Admin only).
18. `mintChronicle(address owner, uint16 configId)`: Mints a new Chronicle NFT for `owner` with a specific configuration.
19. `mintRandomChronicle(address owner)`: Mints a new Chronicle NFT for `owner` with properties potentially influenced by current block data (basic entropy source).
20. `applyFlux(uint256 tokenId)`: Allows anyone to trigger the time-based state evolution for a Chronicle, updating its flux level and potential based on time elapsed since last application and its configuration.
21. `applyExternalFlux(uint256 tokenId, uint32 fluxAmount)`: Allows a privileged address (e.g., Oracle role) to apply a specific amount of flux, simulating influence from external events.
22. `transitionState(uint256 tokenId)`: Attempts to advance the Chronicle's state identifier if its current flux level meets the configured threshold. Resets flux level upon successful transition.
23. `consumePotential(uint256 tokenId, uint96 amount)`: Allows the owner or approved address to spend the accumulated potential resource from a Chronicle.
24. `claimPotentialReward(uint256 tokenId)`: Allows the owner or approved address to "cash out" accumulated potential, emitting an event for off-chain processing or transferring a reward (simplified to emitting an event). Resets potential.
25. `sealChronicle(uint256 tokenId, uint48 duration)`: Locks the Chronicle NFT from transfer for a specified duration (Owner/Approved only).
26. `unsealChronicle(uint256 tokenId)`: Unlocks the Chronicle NFT if the sealed duration has passed (Owner/Approved only).
27. `toggleTrait(uint256 tokenId, uint8 traitIndex)`: Toggles a specific boolean trait bit within the Chronicle's state (Owner/Approved only).
28. `mergeChronicles(uint256 tokenId1, uint256 tokenId2)`: Merges the state (flux, potential, etc.) of `tokenId2` into `tokenId1`, effectively burning `tokenId2` (Owner/Approved of both or operator only).
29. `delegateFluxApplication(uint256 tokenId, address delegate)`: Allows the owner to designate an address that can call `applyFlux` and `applyExternalFlux` for this specific token, potentially useful for gas sponsorship or automated systems.
30. `prognosticateFlux(uint256 tokenId, uint48 futureTime)`: A view function that calculates the *predicted* flux level and potential accumulation for a Chronicle at a specified future timestamp, based on its current state and config (pure calculation, no state change).
31. `purityCheck(uint256 tokenId)`: A view function that returns a hypothetical "purity" score or value based on the Chronicle's historical interactions (e.g., number of state transitions, potential claims). Simplified logic for example.
32. `getChronicleDetails(uint256 tokenId)`: View function to get all stored data for a specific Chronicle.
33. `getCurrentFluxLevel(uint256 tokenId)`: View function to get the current flux level of a Chronicle.
34. `isChronicleSealed(uint256 tokenId)`: View function to check if a Chronicle is currently sealed.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Using Enumerable for listChroniclesByOwner

// --- Outline ---
// 1. Pragma & Imports
// 2. Errors
// 3. Events
// 4. Roles
// 5. Structs
// 6. State Variables
// 7. Constructor
// 8. Modifiers
// 9. Configuration Management
// 10. Minting
// 11. Core Dynamic Logic (applyFlux)
// 12. External Interaction Logic (applyExternalFlux)
// 13. State & Resource Management (transitionState, consumePotential, claimPotentialReward)
// 14. Chronicle Properties Management (seal/unseal, toggleTrait)
// 15. Advanced/Novel Mechanics (mergeChronicles, delegateFluxApplication, prognosticateFlux, purityCheck)
// 16. Access Control (standard functions)
// 17. ERC721 Standard Functions (required, some hooked)
// 18. Query Functions

// --- Function Summary ---
// constructor()
// supportsInterface(bytes4 interfaceId)
// balanceOf(address owner)
// ownerOf(uint256 tokenId)
// approve(address to, uint256 tokenId)
// getApproved(uint256 tokenId)
// setApprovalForAll(address operator, bool approved)
// isApprovedForAll(address owner, address operator)
// transferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// getRoleAdmin(bytes32 role)
// grantRole(bytes32 role, address account)
// revokeRole(bytes32 role, address account)
// renounceRole(bytes32 role, address account)
// addChronicleConfig(uint16 configId, uint32 baseFluxRate, ...)
// updateChronicleConfig(uint16 configId, uint32 baseFluxRate, ...)
// mintChronicle(address owner, uint16 configId)
// mintRandomChronicle(address owner)
// applyFlux(uint256 tokenId)
// applyExternalFlux(uint256 tokenId, uint32 fluxAmount)
// transitionState(uint256 tokenId)
// consumePotential(uint256 tokenId, uint96 amount)
// claimPotentialReward(uint256 tokenId)
// sealChronicle(uint256 tokenId, uint48 duration)
// unsealChronicle(uint256 tokenId)
// toggleTrait(uint256 tokenId, uint8 traitIndex)
// mergeChronicles(uint256 tokenId1, uint256 tokenId2)
// delegateFluxApplication(uint256 tokenId, address delegate)
// prognosticateFlux(uint256 tokenId, uint48 futureTime)
// purityCheck(uint256 tokenId)
// getChronicleDetails(uint256 tokenId)
// getCurrentFluxLevel(uint256 tokenId)
// isChronicleSealed(uint256 tokenId)
// listChroniclesByOwner(address owner) // Added from Enumerable

contract QuantumFluxChronicles is ERC721Enumerable, AccessControl {

    // --- Errors ---
    error InvalidConfigId();
    error ConfigAlreadyExists(uint16 configId);
    error ConfigNotFound(uint16 configId);
    error ChronicleNotFound(uint256 tokenId);
    error ChronicleSealed(uint256 tokenId, uint48 sealedUntil);
    error InsufficientPotential(uint256 tokenId, uint96 requested, uint96 available);
    error CannotMergeSelf();
    error NotApprovedOrOwner(uint256 tokenId, address caller);
    error OnlyOwnerOrApprovedOrDelegate(uint256 tokenId, address caller);
    error InvalidTraitIndex(uint8 traitIndex);
    error MergeRequiresDifferentConfigs(); // Example: Can only merge different types
    error DelegationAlreadySet(uint256 tokenId, address delegate);
    error NoDelegateSet(uint256 tokenId);

    // --- Events ---
    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, uint16 configId, uint48 creationTime);
    event FluxApplied(uint256 indexed tokenId, address indexed applicator, uint32 timeFlux, uint32 externalFlux, uint32 newFluxLevel, uint96 potentialGained);
    event StateTransitioned(uint256 indexed tokenId, uint16 oldState, uint16 newState, uint32 fluxConsumed);
    event PotentialConsumed(uint256 indexed tokenId, address indexed consumer, uint96 amount);
    event PotentialClaimed(uint256 indexed tokenId, address indexedclaimer, uint96 amountClaimed);
    event ChronicleSealedEvent(uint256 indexed tokenId, uint48 sealedUntil);
    event ChronicleUnsealedEvent(uint256 indexed tokenId);
    event TraitToggled(uint256 indexed tokenId, uint8 indexed traitIndex, bool newState);
    event ChroniclesMerged(uint256 indexed primaryTokenId, uint256 indexed burnedTokenId, address indexed merger);
    event FluxDelegationSet(uint256 indexed tokenId, address indexed delegate, address indexed delegator);
    event FluxDelegationRemoved(uint256 indexed tokenId, address indexed previousDelegate, address indexed delegator);
    event ChronicleConfigAdded(uint16 indexed configId, uint32 baseFluxRate);
    event ChronicleConfigUpdated(uint16 indexed configId, uint32 baseFluxRate);


    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONFIG_MANAGER_ROLE = keccak256("CONFIG_MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For applying external flux

    // --- Structs ---
    struct ChronicleConfig {
        uint32 baseFluxRate;                // Flux generated per second of elapsed time
        uint32 potentialPerFlux;            // Potential gained per unit of flux applied
        uint32 stateTransitionFluxThreshold;// Flux level required to transition state
        uint32 maxFluxLevel;                // Maximum flux level before needing reset/transition
    }

    struct Chronicle {
        uint48 creationTime;        // When the chronicle was minted (seconds since epoch)
        uint48 lastFluxTime;        // Last time flux was applied (seconds since epoch)
        uint32 fluxLevel;           // Current accumulated flux level
        uint16 stateIdentifier;     // Represents the current "phase" or type of the chronicle
        uint96 accumulatedPotential;// Resource/score generated over time/flux
        uint16 configId;            // Link to the configuration profile
        uint48 sealedUntil;         // Timestamp until which transfers are locked
        uint256 traits;             // Bitmask for boolean traits (up to 256)
        address delegate;           // Address authorized to apply flux on behalf of owner
        uint32 stateTransitionsCount; // Counter for purity check / history
        uint96 totalPotentialClaimed; // Counter for purity check / history
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => Chronicle) private _chronicles;
    mapping(uint16 => ChronicleConfig) private _chronicleConfigs;
    uint16 private _chronicleConfigCounter; // To auto-generate config IDs if needed, or just track existence
    mapping(uint16 => bool) private _configExists;


    // --- Constructor ---
    constructor(address defaultAdmin) ERC721("Quantum Flux Chronicle", "QFC") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin); // Custom Admin Role
    }

    // --- Modifiers ---
    modifier onlyConfigManager() {
        _checkRole(CONFIG_MANAGER_ROLE);
        _;
    }

    modifier onlyOracle() {
        _checkRole(ORACLE_ROLE);
        _;
    }

    modifier chronicleExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert ChronicleNotFound(tokenId);
        }
        _;
    }

    modifier whenNotSealed(uint256 tokenId) {
        uint48 sealedUntil = _chronicles[tokenId].sealedUntil;
        if (sealedUntil > block.timestamp) {
            revert ChronicleSealed(tokenId, sealedUntil);
        }
        _;
    }

     /**
     * @dev Checks if `caller` is the owner of `tokenId`, is approved for `tokenId`,
     * or is approved for all of the owner.
     */
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        address owner = ERC721.ownerOf(tokenId);
        address caller = _msgSender();
        if (owner != caller && getApproved(tokenId) != caller && !isApprovedForAll(owner, caller)) {
            revert NotApprovedOrOwner(tokenId, caller);
        }
        _;
    }

    /**
     * @dev Checks if `caller` is the owner, approved, or the registered delegate for flux application.
     */
    modifier onlyOwnerOrApprovedOrDelegateForFlux(uint256 tokenId) {
        address owner = ERC721.ownerOf(tokenId);
        address caller = _msgSender();
        if (owner != caller && getApproved(tokenId) != caller && !isApprovedForAll(owner, caller) && _chronicles[tokenId].delegate != caller) {
             revert OnlyOwnerOrApprovedOrDelegate(tokenId, caller);
        }
        _;
    }


    // --- Configuration Management ---

    /**
     * @notice Adds a new Chronicle configuration profile.
     * @param configId The unique ID for the configuration.
     * @param baseFluxRate Rate of natural flux accumulation per second.
     * @param potentialPerFlux Potential gained per unit of flux applied.
     * @param stateTransitionFluxThreshold Flux level required for state transition.
     * @param maxFluxLevel Maximum flux level before potential reset/transition.
     */
    function addChronicleConfig(
        uint16 configId,
        uint32 baseFluxRate,
        uint32 potentialPerFlux,
        uint32 stateTransitionFluxThreshold,
        uint32 maxFluxLevel
    ) external onlyConfigManager {
        if (_configExists[configId]) {
            revert ConfigAlreadyExists(configId);
        }
        _chronicleConfigs[configId] = ChronicleConfig({
            baseFluxRate: baseFluxRate,
            potentialPerFlux: potentialPerFlux,
            stateTransitionFluxThreshold: stateTransitionFluxThreshold,
            maxFluxLevel: maxFluxLevel
        });
        _configExists[configId] = true;
        _chronicleConfigCounter++; // Simple counter, not strictly necessary for this map key approach
        emit ChronicleConfigAdded(configId, baseFluxRate);
    }

     /**
     * @notice Updates an existing Chronicle configuration profile.
     * @param configId The ID of the configuration to update.
     * @param baseFluxRate Rate of natural flux accumulation per second.
     * @param potentialPerFlux Potential gained per unit of flux applied.
     * @param stateTransitionFluxThreshold Flux level required for state transition.
     * @param maxFluxLevel Maximum flux level before potential reset/transition.
     */
    function updateChronicleConfig(
        uint16 configId,
        uint32 baseFluxRate,
        uint32 potentialPerFlux,
        uint32 stateTransitionFluxThreshold,
        uint32 maxFluxLevel
    ) external onlyConfigManager {
        if (!_configExists[configId]) {
            revert ConfigNotFound(configId);
        }
         _chronicleConfigs[configId] = ChronicleConfig({
            baseFluxRate: baseFluxRate,
            potentialPerFlux: potentialPerFlux,
            stateTransitionFluxThreshold: stateTransitionFluxThreshold,
            maxFluxLevel: maxFluxLevel
        });
        emit ChronicleConfigUpdated(configId, baseFluxRate);
    }


    // --- Minting ---

    /**
     * @notice Mints a new Chronicle NFT with a specified configuration.
     * @param owner The address that will receive the new NFT.
     * @param configId The ID of the configuration profile for this Chronicle.
     */
    function mintChronicle(address owner, uint16 configId) external onlyConfigManager {
        if (!_configExists[configId]) {
            revert InvalidConfigId();
        }

        uint256 tokenId = _nextTokenId++;
        uint48 currentTime = uint48(block.timestamp);

        _chronicles[tokenId] = Chronicle({
            creationTime: currentTime,
            lastFluxTime: currentTime,
            fluxLevel: 0,
            stateIdentifier: 1, // Start at state 1
            accumulatedPotential: 0,
            configId: configId,
            sealedUntil: 0,
            traits: 0, // No traits initially
            delegate: address(0),
            stateTransitionsCount: 0,
            totalPotentialClaimed: 0
        });

        _safeMint(owner, tokenId);
        emit ChronicleMinted(tokenId, owner, configId, currentTime);
    }

    /**
     * @notice Mints a new Chronicle NFT with properties influenced by block data.
     * This provides basic on-chain "randomness" for initial state, not cryptographically secure.
     * Configuration is chosen based on a simple hash function.
     * @param owner The address that will receive the new NFT.
     */
    function mintRandomChronicle(address owner) external onlyConfigManager {
        // Use block data for simple entropy (predictable, do not use for high-value randomness)
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextTokenId)));
        uint16 configId = uint16((entropy % _chronicleConfigCounter) + 1); // Simple config selection
        // Ensure the derived configId actually exists
         while(!_configExists[configId] && _chronicleConfigCounter > 0) {
             configId = uint16((configId % _chronicleConfigCounter) + 1);
         }
         if (!_configExists[configId]) {
             // Fallback if no configs exist or derivation fails
             revert InvalidConfigId();
         }

        uint256 tokenId = _nextTokenId++;
        uint48 currentTime = uint48(block.timestamp);

         _chronicles[tokenId] = Chronicle({
            creationTime: currentTime,
            lastFluxTime: currentTime,
            fluxLevel: uint32(entropy % _chronicleConfigs[configId].maxFluxLevel), // Random initial flux
            stateIdentifier: uint16((entropy >> 32) % 5 + 1), // Random initial state (1-5)
            accumulatedPotential: uint96((entropy >> 48) % 1000), // Random initial potential
            configId: configId,
            sealedUntil: 0,
            traits: uint256(entropy >> 64), // Random initial traits
            delegate: address(0),
            stateTransitionsCount: 0,
            totalPotentialClaimed: 0
        });

        _safeMint(owner, tokenId);
        emit ChronicleMinted(tokenId, owner, configId, currentTime);
    }


    // --- Core Dynamic Logic ---

    /**
     * @notice Applies natural, time-based flux accumulation to a Chronicle.
     * Can be called by anyone (owner, delegate, or third party) to advance the state.
     * The caller pays gas, but the potential gain accrues to the owner's token.
     * @param tokenId The ID of the Chronicle.
     */
    function applyFlux(uint256 tokenId)
        external
        chronicleExists(tokenId)
        onlyOwnerOrApprovedOrDelegateForFlux(tokenId)
    {
        Chronicle storage chronicle = _chronicles[tokenId];
        ChronicleConfig storage config = _chronicleConfigs[chronicle.configId];

        uint48 currentTime = uint48(block.timestamp);
        uint48 timeElapsed = currentTime - chronicle.lastFluxTime;

        // Calculate flux gained from time passing
        uint32 timeFluxGained = config.baseFluxRate * timeElapsed;

        // Update flux level, capped by maxFluxLevel
        uint32 newFluxLevel = chronicle.fluxLevel + timeFluxGained;
        if (newFluxLevel > config.maxFluxLevel) {
            newFluxLevel = config.maxFluxLevel;
        }

        // Calculate potential gained
        uint96 potentialGained = uint96((newFluxLevel - chronicle.fluxLevel)) * config.potentialPerFlux;

        chronicle.fluxLevel = newFluxLevel;
        chronicle.accumulatedPotential += potentialGained;
        chronicle.lastFluxTime = currentTime;

        emit FluxApplied(tokenId, _msgSender(), timeFluxGained, 0, newFluxLevel, potentialGained);
    }

    // --- External Interaction Logic ---

    /**
     * @notice Allows a privileged address (ORACLE_ROLE) to apply flux to a Chronicle,
     * simulating influence from external data or events.
     * @param tokenId The ID of the Chronicle.
     * @param fluxAmount The amount of external flux to apply.
     */
    function applyExternalFlux(uint256 tokenId, uint32 fluxAmount)
        external
        onlyOracle
        chronicleExists(tokenId)
        onlyOwnerOrApprovedOrDelegateForFlux(tokenId) // Still requires owner/approved/delegate context
    {
        Chronicle storage chronicle = _chronicles[tokenId];
        ChronicleConfig storage config = _chronicleConfigs[chronicle.configId];

         // Update flux level, capped by maxFluxLevel
        uint32 newFluxLevel = chronicle.fluxLevel + fluxAmount;
        if (newFluxLevel > config.maxFluxLevel) {
            newFluxLevel = config.maxFluxLevel;
        }

        // Calculate potential gained *only* from external flux applied
        uint96 potentialGained = uint96(fluxAmount) * config.potentialPerFlux;

        chronicle.fluxLevel = newFluxLevel;
        chronicle.accumulatedPotential += potentialGained;
        // Note: lastFluxTime is only updated by applyFlux() based on time elapsed
        // External flux is an additive event separate from natural decay/accumulation timers.

        emit FluxApplied(tokenId, _msgSender(), 0, fluxAmount, newFluxLevel, potentialGained);
    }


    // --- State & Resource Management ---

    /**
     * @notice Attempts to transition the Chronicle to the next state if its flux level
     * meets or exceeds the configured threshold. Resets flux level on success.
     * @param tokenId The ID of the Chronicle.
     */
    function transitionState(uint256 tokenId) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        ChronicleConfig storage config = _chronicleConfigs[chronicle.configId];

        if (chronicle.fluxLevel >= config.stateTransitionFluxThreshold) {
            uint16 oldState = chronicle.stateIdentifier;
            uint32 fluxConsumed = chronicle.fluxLevel; // Consume all current flux for transition

            chronicle.stateIdentifier = oldState + 1; // Simple sequential state transition
            chronicle.fluxLevel = 0; // Reset flux after transition
            chronicle.stateTransitionsCount++;

            emit StateTransitioned(tokenId, oldState, chronicle.stateIdentifier, fluxConsumed);
        }
        // No state change if threshold not met (no error, just does nothing)
    }

    /**
     * @notice Consumes a specified amount of accumulated potential from a Chronicle.
     * Simulates spending the resource within the ecosystem.
     * @param tokenId The ID of the Chronicle.
     * @param amount The amount of potential to consume.
     */
    function consumePotential(uint256 tokenId, uint96 amount) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        if (chronicle.accumulatedPotential < amount) {
            revert InsufficientPotential(tokenId, amount, chronicle.accumulatedPotential);
        }
        chronicle.accumulatedPotential -= amount;
        emit PotentialConsumed(tokenId, _msgSender(), amount);
    }

    /**
     * @notice Allows the owner/approved to "claim" the accumulated potential.
     * Here, it emits an event and resets potential. In a real dApp, this might
     * trigger a token transfer or other reward mechanism off-chain or via another contract.
     * @param tokenId The ID of the Chronicle.
     */
    function claimPotentialReward(uint256 tokenId) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint96 amountClaimed = chronicle.accumulatedPotential;

        if (amountClaimed > 0) {
            chronicle.accumulatedPotential = 0;
            chronicle.totalPotentialClaimed += amountClaimed;
            emit PotentialClaimed(tokenId, _msgSender(), amountClaimed);
        }
        // If amount is 0, nothing happens (no error)
    }


    // --- Chronicle Properties Management ---

    /**
     * @notice Seals a Chronicle, preventing its transfer until the specified time.
     * @param tokenId The ID of the Chronicle.
     * @param duration The duration in seconds from now for which the Chronicle should be sealed.
     */
    function sealChronicle(uint256 tokenId, uint48 duration) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint48 sealUntilTime = uint48(block.timestamp + duration);
        // Allow extending the seal, but not reducing it before expiry
        if (sealUntilTime > chronicle.sealedUntil) {
            chronicle.sealedUntil = sealUntilTime;
            emit ChronicleSealedEvent(tokenId, sealUntilTime);
        }
    }

    /**
     * @notice Unseals a Chronicle if the seal duration has passed.
     * Callable by anyone once the time is up, or by owner/approved at any time?
     * Let's make it callable by anyone after expiry, or owner/approved anytime.
     * @param tokenId The ID of the Chronicle.
     */
    function unsealChronicle(uint256 tokenId) external chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint48 sealedUntil = chronicle.sealedUntil;

        if (sealedUntil > block.timestamp) {
            // Check if caller is owner/approved to break the seal early
            address owner = ERC721.ownerOf(tokenId);
            address caller = _msgSender();
            if (owner != caller && getApproved(tokenId) != caller && !isApprovedForAll(owner, caller)) {
                 revert ChronicleSealed(tokenId, sealedUntil); // Not authorized to break early
            }
        }

        if (chronicle.sealedUntil > 0) {
             chronicle.sealedUntil = 0;
             emit ChronicleUnsealedEvent(tokenId);
        }
         // If already unsealed (0), nothing happens
    }


    /**
     * @notice Toggles a specific boolean trait for a Chronicle.
     * Traits are stored as bits in a uint256.
     * @param tokenId The ID of the Chronicle.
     * @param traitIndex The index of the trait (0 to 255).
     */
    function toggleTrait(uint256 tokenId, uint8 traitIndex) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        if (traitIndex >= 256) { // Should not happen with uint8, but good practice
             revert InvalidTraitIndex(traitIndex);
        }
        Chronicle storage chronicle = _chronicles[tokenId];
        uint256 traitMask = 1 << traitIndex;
        bool currentState = (chronicle.traits & traitMask) != 0;
        chronicle.traits ^= traitMask; // Toggle the bit
        emit TraitToggled(tokenId, traitIndex, !currentState);
    }


    // --- Advanced/Novel Mechanics ---

    /**
     * @notice Merges the accumulated state (flux, potential, state identifier progression)
     * of one Chronicle (`tokenId2`) into another (`tokenId1`), and burns `tokenId2`.
     * Requires owner/approved status for *both* tokens or operator status for both owners.
     * Example constraint: Can only merge different configuration types.
     * @param tokenId1 The ID of the primary Chronicle (state is merged into, token persists).
     * @param tokenId2 The ID of the secondary Chronicle (state is merged from, token is burned).
     */
    function mergeChronicles(uint256 tokenId1, uint256 tokenId2) external chronicleExists(tokenId1) chronicleExists(tokenId2) {
        if (tokenId1 == tokenId2) {
            revert CannotMergeSelf();
        }

        address owner1 = ERC721.ownerOf(tokenId1);
        address owner2 = ERC721.ownerOf(tokenId2);
        address caller = _msgSender();

        // Check permissions for both tokens
        bool callerIsOwner1 = owner1 == caller;
        bool callerIsApproved1 = getApproved(tokenId1) == caller || isApprovedForAll(owner1, caller);
        bool callerIsOwner2 = owner2 == caller;
        bool callerIsApproved2 = getApproved(tokenId2) == caller || isApprovedForAll(owner2, caller);

        if (!((callerIsOwner1 || callerIsApproved1) && (callerIsOwner2 || callerIsApproved2))) {
             revert NotApprovedOrOwner(tokenId1, caller); // Or specific error for merge auth
        }

        Chronicle storage chronicle1 = _chronicles[tokenId1];
        Chronicle storage chronicle2 = _chronicles[tokenId2];

        // Example Merge Logic:
        // Add flux levels (capped)
        // Add potential
        // Combine state transitions counts
        // Combine total potential claimed
        // Maybe combine traits (e.g., OR the trait masks)
        // State identifier could advance or take the max? Let's just add transition count for simplicity.
        // Config ID of tokenId1 remains.

        ChronicleConfig storage config1 = _chronicleConfigs[chronicle1.configId];
        ChronicleConfig storage config2 = _chronicleConfigs[chronicle2.configId];

        // Example: Constraint - only merge different config types
        if (chronicle1.configId == chronicle2.configId) {
            revert MergeRequiresDifferentConfigs();
        }


        uint32 mergedFluxLevel = chronicle1.fluxLevel + chronicle2.fluxLevel;
        if (mergedFluxLevel > config1.maxFluxLevel) { // Cap merged flux by primary token's config
            mergedFluxLevel = config1.maxFluxLevel;
        }
        chronicle1.fluxLevel = mergedFluxLevel;

        chronicle1.accumulatedPotential += chronicle2.accumulatedPotential;
        chronicle1.stateTransitionsCount += chronicle2.stateTransitionsCount;
        chronicle1.totalPotentialClaimed += chronicle2.totalPotentialClaimed;
        chronicle1.traits |= chronicle2.traits; // Combine traits using bitwise OR

        // Burn the second token
        _burn(tokenId2);

        // Clean up storage for the burned token (optional but good practice for complex structs)
        delete _chronicles[tokenId2];

        emit ChroniclesMerged(tokenId1, tokenId2, caller);
    }

    /**
     * @notice Allows the owner to delegate the ability to call `applyFlux` and `applyExternalFlux`
     * for a specific token to another address. Useful for automation or gas sponsorship.
     * Does NOT delegate transfer rights.
     * @param tokenId The ID of the Chronicle.
     * @param delegate The address to grant delegation to (address(0) to remove delegation).
     */
    function delegateFluxApplication(uint256 tokenId, address delegate) external onlyOwnerOrApproved(tokenId) chronicleExists(tokenId) {
        Chronicle storage chronicle = _chronicles[tokenId];
        address oldDelegate = chronicle.delegate;

        if (oldDelegate == delegate) {
            // No change
            return;
        }

        chronicle.delegate = delegate;

        if (delegate != address(0)) {
            emit FluxDelegationSet(tokenId, delegate, _msgSender());
        } else {
             emit FluxDelegationRemoved(tokenId, oldDelegate, _msgSender());
        }
    }

    /**
     * @notice Calculates the predicted state (flux level and potential) of a Chronicle
     * at a specified future timestamp, assuming only natural flux accumulation.
     * This is a read-only (pure/view) function.
     * @param tokenId The ID of the Chronicle.
     * @param futureTime The future timestamp to prognosticate to (seconds since epoch).
     * @return predictedFluxLevel Predicted flux level at `futureTime`.
     * @return predictedPotential Predicted accumulated potential at `futureTime`.
     */
    function prognosticateFlux(uint256 tokenId, uint48 futureTime)
        public
        view
        chronicleExists(tokenId) // Use view function compatibility
        returns (uint32 predictedFluxLevel, uint96 predictedPotential)
    {
        Chronicle storage chronicle = _chronicles[tokenId];
        ChronicleConfig storage config = _chronicleConfigs[chronicle.configId];

        uint48 timeElapsed = futureTime > chronicle.lastFluxTime ? futureTime - chronicle.lastFluxTime : 0;

        // Calculate flux gained from time passing
        uint32 timeFluxGained = config.baseFluxRate * timeElapsed;

        // Calculate potential gained from this predicted flux
        uint96 potentialGained = uint96(timeFluxGained) * config.potentialPerFlux;


        // Calculate predicted flux level, capped by maxFluxLevel
        predictedFluxLevel = chronicle.fluxLevel + timeFluxGained;
        if (predictedFluxLevel > config.maxFluxLevel) {
            predictedFluxLevel = config.maxFluxLevel;
        }

        // Add potential gained to current potential
        predictedPotential = chronicle.accumulatedPotential + potentialGained;

        // Note: This does NOT account for state transitions, external flux,
        // consumption, or sealing effects between now and futureTime.
        // It's a simple prediction based *only* on time-based accumulation.
    }

     /**
     * @notice Calculates a hypothetical "purity" score for a Chronicle based on its history.
     * Example: Score decreases with more state transitions or claims, increases with time held, etc.
     * Simplified logic for this example.
     * @param tokenId The ID of the Chronicle.
     * @return purityScore A calculated score representing the Chronicle's "purity".
     */
    function purityCheck(uint256 tokenId) public view chronicleExists(tokenId) returns (uint256 purityScore) {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint48 currentTime = uint48(block.timestamp);
        uint48 age = currentTime - chronicle.creationTime;

        // Example Purity Logic (arbitrary):
        // Starts high, penalized by transitions and claims, rewarded by age and current potential.
        // Max score: 10000 (arbitrary base)
        uint256 base = 10000;
        uint256 transitionPenalty = uint256(chronicle.stateTransitionsCount) * 100; // Lose 100 per transition
        uint256 claimPenalty = uint256(chronicle.totalPotentialClaimed) / 100; // Lose 1 for every 100 potential claimed
        uint256 ageBonus = uint256(age) / 1 days; // Gain 1 per day of age
        uint256 potentialBonus = uint256(chronicle.accumulatedPotential) / 50; // Gain 1 for every 50 current potential

        // Calculate raw score
        uint256 rawScore = base + ageBonus + potentialBonus;
        if (rawScore > transitionPenalty + claimPenalty) {
            purityScore = rawScore - transitionPenalty - claimPenalty;
        } else {
            purityScore = 0; // Cannot go below 0
        }

        // Cap score (optional)
        if (purityScore > 20000) purityScore = 20000; // Example cap
    }


    // --- Access Control ---

    // Inherited from AccessControl:
    // getRoleAdmin(bytes32 role)
    // grantRole(bytes32 role, address account)
    // revokeRole(bytes32 role, address account)
    // renounceRole(bytes32 role)


    // --- ERC721 Standard Functions ---

    // Override _beforeTokenTransfer to check for sealed status
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Only apply seal check if transferring a single token (batchSize == 1)
        // and it's not a mint (from != address(0)) or burn (to != address(0))
        if (batchSize == 1 && from != address(0) && to != address(0)) {
             uint48 sealedUntil = _chronicles[tokenId].sealedUntil;
            if (sealedUntil > block.timestamp) {
                revert ChronicleSealed(tokenId, sealedUntil);
            }
        }
    }

    // Override _afterTokenTransfer for potential future hooks (e.g., clearing approvals)
    // Not strictly needed for this example but common pattern.
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
         // Example: clear delegate upon transfer
         if (batchSize == 1 && from != address(0) && to != address(0)) {
             // Only clear if it's a standard transfer, not mint/burn
              _chronicles[tokenId].delegate = address(0); // Clear delegation on transfer
         }
    }

    // Implement supportsInterface required by ERC721 and AccessControl
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     // Other standard ERC721 functions are inherited or overridden minimally above.
     // balanceOf(address owner) -> Inherited from ERC721Enumerable
     // ownerOf(uint256 tokenId) -> Inherited
     // approve(address to, uint256 tokenId) -> Inherited
     // getApproved(uint256 tokenId) -> Inherited
     // setApprovalForAll(address operator, bool approved) -> Inherited
     // isApprovedForAll(address owner, address operator) -> Inherited
     // transferFrom(address from, address to, uint256 tokenId) -> Inherited, hooked
     // safeTransferFrom(address from, address to, uint256 tokenId) -> Inherited, hooked
     // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) -> Inherited, hooked

     // From ERC721Enumerable:
     // totalSupply()
     // tokenOfOwnerByIndex(address owner, uint256 index)
     // tokenByIndex(uint256 index)
     // listChroniclesByOwner (manual helper leveraging tokenOfOwnerByIndex)


    // --- Query Functions ---

    /**
     * @notice Gets all details for a specific Chronicle.
     * @param tokenId The ID of the Chronicle.
     * @return Chronicle struct containing all its data.
     */
    function getChronicleDetails(uint256 tokenId) public view chronicleExists(tokenId) returns (Chronicle memory) {
        return _chronicles[tokenId];
    }

     /**
     * @notice Gets the current flux level of a specific Chronicle.
     * @param tokenId The ID of the Chronicle.
     * @return currentFluxLevel The current flux level.
     */
    function getCurrentFluxLevel(uint256 tokenId) public view chronicleExists(tokenId) returns (uint32 currentFluxLevel) {
        return _chronicles[tokenId].fluxLevel;
    }

    /**
     * @notice Checks if a Chronicle is currently sealed against transfers.
     * @param tokenId The ID of the Chronicle.
     * @return bool True if sealed, false otherwise.
     * @return sealedUntil The timestamp the seal expires (0 if not sealed).
     */
    function isChronicleSealed(uint256 tokenId) public view chronicleExists(tokenId) returns (bool, uint48) {
        uint48 sealedUntil = _chronicles[tokenId].sealedUntil;
        return (sealedUntil > block.timestamp, sealedUntil);
    }

    /**
     * @notice Gets the state of a specific trait for a Chronicle.
     * @param tokenId The ID of the Chronicle.
     * @param traitIndex The index of the trait (0 to 255).
     * @return bool True if the trait is set, false otherwise.
     */
    function getTokenTrait(uint256 tokenId, uint8 traitIndex) public view chronicleExists(tokenId) returns (bool) {
         if (traitIndex >= 256) {
             return false; // Or revert? Let's return false for a view function.
         }
        return (_chronicles[tokenId].traits & (1 << traitIndex)) != 0;
    }

    /**
     * @notice Gets details for a specific Chronicle configuration.
     * @param configId The ID of the configuration.
     * @return ChronicleConfig struct containing configuration data.
     */
    function getConfigDetails(uint16 configId) public view returns (ChronicleConfig memory) {
        if (!_configExists[configId]) {
             // Return zeroed struct for non-existent config, or revert?
             // Reverting is clearer for programmatic use.
             revert ConfigNotFound(configId);
        }
        return _chronicleConfigs[configId];
    }

     /**
     * @notice Gets a list of all Chronicle token IDs owned by a specific address.
     * Leverages ERC721Enumerable.
     * @param owner The address to query.
     * @return tokenIds An array of token IDs owned by the address.
     */
    function listChroniclesByOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

     // totalConfigsCount() - Helper query
     function totalConfigsCount() public view returns (uint16) {
         return _chronicleConfigCounter;
     }
}
```