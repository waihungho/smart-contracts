Okay, let's design a smart contract for dynamic, evolving digital assets. We'll call it "Quantum Pixel Forge". These NFTs represent unique "pixels" that can be mutated, combined, decay over time, and reach a 'stable' state based on complex interactions and on-chain state.

It will incorporate:
*   Dynamic state based on time and interactions (decay).
*   On-chain pseudo-randomness influence on mutations.
*   State-dependent function availability.
*   Combining NFTs to create new ones (burning the old).
*   Multi-stage lifecycle (Initial, Active, Hibernating, Decaying, Stable, Annihilated).
*   Energy/Stability mechanics.
*   ERC721 standard for ownership.
*   Pausable and Ownable for basic contract management.

**Outline:**

1.  **License and Pragma**
2.  **Imports** (ERC721, Ownable, Pausable, Counters)
3.  **Error Definitions**
4.  **Enums** (PixelState)
5.  **Structs** (Pixel)
6.  **State Variables** (Mappings, counters, admin settings, costs)
7.  **Events**
8.  **Function Summary** (Detailed list of all 20+ functions)
9.  **Constructor**
10. **Modifiers** (Ownable, Pausable, state checks)
11. **Internal Helpers** (`_generateInitialProperties`, `_applyDecay`, `_updatePixelState`, ERC721 internal helpers)
12. **Core Pixel Interaction Functions** (`mint`, `chargePixel`, `observePixel`, `fortifyPixel`, `splicePixel`, `fusePixels`, `hibernatePixel`, `wakePixel`, `stabilizePixel`, `annihilatePixel`, `checkAndApplyDecay`)
13. **View Functions** (`getPixelProperties`, `getPixelState`, `getPixelCreationData`, `getPixelGeneration`, `getTotalActivePixels`, `getOperationCosts`, `getStabilizationRequirements`, `getContractState`, `tokenURI`)
14. **Admin Functions** (`setDecayRate`, `setOperationCosts`, `setStabilizationRequirements`, `pauseContract`, `unpauseContract`, `withdrawFees`)
15. **ERC721 Standard Implementations** (`balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `totalSupply`, `supportsInterface`)

**Function Summary:**

*   `constructor()`: Initializes the contract with basic settings.
*   `mint(address to)`: Creates a new Quantum Pixel NFT for the specified address with initial properties based on on-chain data. Costs a fee.
*   `chargePixel(uint256 tokenId)`: Increases the energy level of a pixel. Costs Ether. Requires pixel to be Active. Applies decay first.
*   `observePixel(uint256 tokenId)`: A low-cost interaction to update the pixel's last interaction block, slowing decay. Costs minimal Ether/energy. Requires pixel to be Active. Applies decay first.
*   `fortifyPixel(uint256 tokenId)`: Increases the stability of a pixel. Consumes energy and costs Ether. Requires pixel to be Active. Applies decay first.
*   `splicePixel(uint256 tokenId)`: Attempts to mutate the pixel's properties (color, genes, energy, stability) based on its current state and a pseudo-random on-chain seed. High energy/Ether cost. Outcome is state-dependent and probabilistic. Requires pixel to be Active. Applies decay first.
*   `fusePixels(uint256 tokenAId, uint256 tokenBId)`: Combines two owned pixels into a single new, higher-generation pixel, burning the originals. New pixel properties are derived from the parents. High energy/Ether cost. Requires both pixels to be Active. Applies decay to both first.
*   `hibernatePixel(uint256 tokenId)`: Changes the pixel's state to Hibernating, temporarily halting decay but preventing most interactions. Requires pixel to be Active. Applies decay first.
*   `wakePixel(uint256 tokenId)`: Changes a pixel's state from Hibernating back to Active. Applies decay based on hibernated duration before activating.
*   `stabilizePixel(uint256 tokenId)`: Attempts to make a pixel permanently Stable if it meets specific criteria (high stability, energy, specific gene patterns). Costs Ether. Requires pixel to be Active. Applies decay first.
*   `annihilatePixel(uint256 tokenId)`: Allows the owner to permanently burn a pixel. Changes state to Annihilated.
*   `checkAndApplyDecay(uint256 tokenId)`: Public function to manually trigger the decay process for a pixel based on time elapsed since last interaction. Automatically called by most interaction functions.
*   `getPixelProperties(uint256 tokenId)`: View function returning the core numeric properties of a pixel.
*   `getPixelState(uint256 tokenId)`: View function returning the current lifecycle state of a pixel.
*   `getPixelCreationData(uint256 tokenId)`: View function returning the block number the pixel was created and its generation.
*   `getPixelGeneration(uint256 tokenId)`: View function returning the pixel's generation number.
*   `getTotalActivePixels()`: View function returning the count of pixels currently in the `Active` state.
*   `getOperationCosts()`: View function returning the current Ether costs for various operations.
*   `getStabilizationRequirements()`: View function returning the current criteria needed to make a pixel Stable.
*   `getContractState()`: View function returning the contract's paused status and owner address.
*   `tokenURI(uint256 tokenId)`: ERC721 standard view function returning the JSON metadata URI for a pixel. This will dynamically generate the JSON based on the pixel's current state.
*   `setDecayRate(uint16 _rate)`: Admin function to set the blocks-per-decay rate.
*   `setOperationCosts(uint256 _mintCost, uint256 _chargeCost, uint256 _observeCost, uint256 _fortifyCost, uint256 _spliceCost, uint256 _fusionCost, uint256 _stabilizeCost)`: Admin function to set the Ether costs for various operations.
*   `setStabilizationRequirements(uint16 _minStability, uint16 _minEnergy, bytes32 _requiredGenePattern)`: Admin function to set the criteria for stabilizing a pixel.
*   `pauseContract()`: Admin function to pause core interactions.
*   `unpauseContract()`: Admin function to unpause core interactions.
*   `withdrawFees(address payable recipient)`: Admin function to withdraw accumulated Ether fees.
*   `balanceOf(address owner)`: ERC721 standard.
*   `ownerOf(uint256 tokenId)`: ERC721 standard.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard (two versions).
*   `approve(address to, uint256 tokenId)`: ERC721 standard.
*   `getApproved(uint256 tokenId)`: ERC721 standard.
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
*   `isApprovedForAll(address owner, address operator)`: ERC721 standard.
*   `totalSupply()`: ERC721 standard helper.
*   `supportsInterface(bytes4 interfaceId)`: ERC721 standard.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For on-chain metadata encoding

// Quantum Pixel Forge: A dynamic and evolving NFT collection.
// Pixels decay over time, require maintenance, can be mutated, fused,
// and potentially stabilized based on complex state interactions.

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Error Definitions
// 4. Enums (PixelState)
// 5. Structs (Pixel, OperationCosts, StabilizationRequirements)
// 6. State Variables (Mappings, counters, admin settings)
// 7. Events
// 8. Function Summary (Detailed list - See above comments)
// 9. Constructor
// 10. Modifiers (Ownable, Pausable, state checks)
// 11. Internal Helpers (_generateInitialProperties, _applyDecay, _updatePixelState, ERC721 internal helpers, _generateRandomSeed)
// 12. Core Pixel Interaction Functions
// 13. View Functions
// 14. Admin Functions
// 15. ERC721 Standard Implementations

// Function Summary:
// constructor(): Initializes the contract with basic settings.
// mint(address to): Creates a new Quantum Pixel NFT. Costs a fee.
// chargePixel(uint256 tokenId): Increases pixel energy. Costs Ether. Requires Active. Applies decay.
// observePixel(uint256 tokenId): Low-cost interaction to slow decay. Costs minimal. Requires Active. Applies decay.
// fortifyPixel(uint256 tokenId): Increases pixel stability. Consumes energy, costs Ether. Requires Active. Applies decay.
// splicePixel(uint256 tokenId): Attempts to mutate pixel properties based on state and random seed. High cost. Requires Active. Applies decay.
// fusePixels(uint256 tokenAId, uint256 tokenBId): Combines two pixels into one new. Burns originals. High cost. Requires Active. Applies decay.
// hibernatePixel(uint256 tokenId): Puts pixel in Hibernating state, halting decay. Requires Active. Applies decay.
// wakePixel(uint256 tokenId): Wakes pixel from Hibernating to Active. Applies decay for hibernation duration.
// stabilizePixel(uint256 tokenId): Attempts to make pixel Stable if criteria met. Costs Ether. Requires Active. Applies decay.
// annihilatePixel(uint256 tokenId): Burns a pixel permanently.
// checkAndApplyDecay(uint256 tokenId): Manually triggers decay for a pixel.
// getPixelProperties(uint256 tokenId): View function for pixel numeric properties.
// getPixelState(uint256 tokenId): View function for pixel state enum.
// getPixelCreationData(uint256 tokenId): View function for creation block and generation.
// getPixelGeneration(uint256 tokenId): View function for generation number.
// getTotalActivePixels(): View function for count of Active pixels.
// getOperationCosts(): View function for current operation costs.
// getStabilizationRequirements(): View function for stabilization criteria.
// getContractState(): View function for contract paused status and owner.
// tokenURI(uint256 tokenId): ERC721 dynamic metadata URI generation.
// setDecayRate(uint16 _rate): Admin function to set decay rate.
// setOperationCosts(...): Admin function to set operation costs.
// setStabilizationRequirements(...): Admin function to set stabilization criteria.
// pauseContract(): Admin function to pause interactions.
// unpauseContract(): Admin function to unpause interactions.
// withdrawFees(address payable recipient): Admin function to withdraw fees.
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// approve(address to, uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// setApprovalForAll(address operator, bool approved): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.
// totalSupply(): ERC721 standard helper.
// supportsInterface(bytes4 interfaceId): ERC721 standard.

contract QuantumPixelForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Error Definitions ---
    error NotOwnerOrApproved();
    error TokenDoesNotExist();
    error InvalidTokenState(PixelState requiredState, PixelState currentState);
    error InsufficientFunds(uint256 required, uint256 provided);
    error InsufficientEnergy(uint16 required, uint16 provided);
    error InsufficientStability(uint16 required, uint16 provided);
    error CannotFuseDifferentOwners();
    error CannotFuseSelf();
    error StabilizationRequirementsNotMet();
    error CannotAnnihilateStable();
    error AlreadyInState(PixelState currentState);
    error MustBeInState(PixelState requiredState, PixelState currentState);

    // --- Enums ---
    enum PixelState {
        Initial,    // Just minted, pre-interactions
        Active,     // Can be interacted with, decays
        Hibernating, // Decay paused, most interactions blocked
        Decaying,   // Stability reached zero, requires intervention
        Stable,     // Permanently stable, no decay, special properties
        Annihilated // Burned, no longer exists
    }

    // --- Structs ---
    struct Pixel {
        uint24 color;              // RGB color (e.g., 0xFF0000 for red)
        uint16 stability;          // Resistance to decay (0-65535)
        uint16 energy;             // Resource for interactions (0-65535)
        bytes32 genes;             // Genetic code influencing mutations
        uint40 lastInteractionBlock; // Block number of last interaction (decay calculation)
        PixelState state;          // Current state of the pixel
        uint8 generation;          // Generation number (0 for minted, increases on fusion)
        uint40 creationBlock;      // Block number the pixel was minted
    }

    struct OperationCosts {
        uint256 mintCost;
        uint256 chargeCost;
        uint256 observeCost;
        uint256 fortifyCost;
        uint256 spliceCost;
        uint256 fusionCost;
        uint256 stabilizeCost;
    }

    struct StabilizationRequirements {
        uint16 minStability;
        uint16 minEnergy;
        bytes32 requiredGenePattern; // A pattern to match against (e.g., starting bytes)
        bytes32 genePatternMask;     // Mask to apply before matching the pattern
    }

    // --- State Variables ---
    mapping(uint256 => Pixel) private _pixels;

    uint16 public decayRatePerBlock = 1; // How much stability is lost per block when Active

    OperationCosts public operationCosts;

    StabilizationRequirements public stabilizationRequirements;

    mapping(PixelState => uint256) private _stateCounts; // Track counts per state

    // --- Events ---
    event PixelMinted(uint256 indexed tokenId, address indexed owner, uint24 color, bytes32 genes);
    event PixelPropertiesUpdated(uint256 indexed tokenId, uint24 color, uint16 stability, uint16 energy, bytes32 genes);
    event PixelStateChanged(uint256 indexed tokenId, PixelState oldState, PixelState newState);
    event PixelCharged(uint256 indexed tokenId, uint16 amount, uint16 newEnergy);
    event PixelFortified(uint256 indexed tokenId, uint16 amount, uint16 newStability);
    event PixelMutated(uint256 indexed tokenId, bytes32 indexed seed, bool success, uint24 newColor, bytes32 newGenes);
    event PixelFused(uint256 indexed tokenAId, uint256 indexed tokenBId, uint256 indexed newTokenId, uint8 newGeneration);
    event PixelStabilized(uint256 indexed tokenId);
    event PixelAnnihilated(uint256 indexed tokenId);
    event DecayApplied(uint256 indexed tokenId, uint16 stabilityLost, uint16 newStability);
    event OperationCostsUpdated(OperationCosts costs);
    event StabilizationRequirementsUpdated(StabilizationRequirements reqs);
    event DecayRateUpdated(uint16 rate);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        // Initial costs (can be updated by owner)
        operationCosts = OperationCosts({
            mintCost: 0.01 ether,
            chargeCost: 0.001 ether,
            observeCost: 0.0001 ether,
            fortifyCost: 0.002 ether,
            spliceCost: 0.005 ether,
            fusionCost: 0.015 ether,
            stabilizeCost: 0.008 ether
        });

        // Initial stabilization requirements (can be updated by owner)
        stabilizationRequirements = StabilizationRequirements({
            minStability: 60000,
            minEnergy: 60000,
            requiredGenePattern: bytes32(0), // Default: no specific pattern required
            genePatternMask: bytes32(0)
        });

         _stateCounts[PixelState.Initial] = 0;
         _stateCounts[PixelState.Active] = 0;
         _stateCounts[PixelState.Hibernating] = 0;
         _stateCounts[PixelState.Decaying] = 0;
         _stateCounts[PixelState.Stable] = 0;
         _stateCounts[PixelState.Annihilated] = 0;
    }

    // --- Modifiers ---
    modifier onlyPixelOwnerOrApproved(uint256 tokenId) {
        if (_ownerOf(tokenId) != _msgSender() && !isApprovedForAll(_ownerOf(tokenId), _msgSender()) && getApproved(tokenId) != _msgSender()) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    modifier onlyPixelState(uint256 tokenId, PixelState requiredState) {
         if (_pixels[tokenId].state != requiredState) {
             revert InvalidTokenState(requiredState, _pixels[tokenId].state);
         }
         _;
    }

    modifier notPixelState(uint256 tokenId, PixelState forbiddenState) {
         if (_pixels[tokenId].state == forbiddenState) {
             revert AlreadyInState(forbiddenState);
         }
         _;
    }

    // --- Internal Helpers ---

    // Generate pseudo-random initial properties based on input and block data
    function _generateInitialProperties(address ownerAddress, uint256 blockNum) internal view returns (uint24 color, uint16 stability, uint16 energy, bytes32 genes) {
        bytes32 seed = keccak256(abi.encodePacked(ownerAddress, blockNum, block.timestamp, block.difficulty)); // Mix common and unique data

        color = uint24(seed % (2**24)); // Random color
        stability = uint16((uint256(seed) >> 24) % 60000 + 5000); // Start with decent stability
        energy = uint16((uint256(seed) >> 40) % 10000 + 2000); // Start with some energy
        genes = keccak256(abi.encodePacked(seed, "initial_genes")); // Derive genes from seed
    }

     // Generate a dynamic pseudo-random seed for interactions like splicing
     function _generateRandomSeed(uint256 tokenId) internal view returns (bytes32) {
        // Mix block data with pixel-specific data for unique seeds
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender,
            tokenId,
            _pixels[tokenId].color,
            _pixels[tokenId].stability,
            _pixels[tokenId].energy,
            _pixels[tokenId].genes
        ));
        return seed;
    }


    // Applies decay to a pixel based on time elapsed since last interaction
    // Called before most state-changing operations on Active pixels.
    function _applyDecay(uint256 tokenId) internal {
        Pixel storage pixel = _pixels[tokenId];

        // Decay only applies to Active state
        if (pixel.state != PixelState.Active && pixel.state != PixelState.Hibernating) {
            return;
        }

        uint40 blocksPassed;
        if (pixel.state == PixelState.Active) {
             blocksPassed = block.number - pixel.lastInteractionBlock;
        } else { // If hibernating, decay applies based on time *spent hibernating* when waking up
             // This implementation applies decay based on *active* time only.
             // To apply decay for hibernation:
             // uint40 hibernationDuration = block.number - pixel.lastInteractionBlock;
             // (Potentially use a different rate for hibernation decay)
             // For this version, hibernation prevents decay entirely.
             return; // No decay while hibernating
        }


        if (blocksPassed == 0 || decayRatePerBlock == 0) {
            return; // No time passed or decay is disabled
        }

        uint256 stabilityLost = uint256(blocksPassed) * decayRatePerBlock;

        if (stabilityLost >= pixel.stability) {
            uint16 lost = pixel.stability;
            pixel.stability = 0;
            _updatePixelState(tokenId, PixelState.Decaying);
            emit DecayApplied(tokenId, lost, pixel.stability);
        } else {
            uint16 lost = uint16(stabilityLost);
            pixel.stability -= lost;
            emit DecayApplied(tokenId, lost, pixel.stability);
        }

        // Update last interaction block ONLY IF DECAY WAS APPLIED/CHECKED while Active
        // If called on Hibernating, we don't update it until woken.
        if (pixel.state != PixelState.Hibernating) {
             pixel.lastInteractionBlock = uint40(block.number);
        }
    }

     // Updates the state of a pixel and emits an event, managing state counts
     function _updatePixelState(uint256 tokenId, PixelState newState) internal {
        Pixel storage pixel = _pixels[tokenId];
        if (pixel.state == newState) {
            return;
        }

        PixelState oldState = pixel.state;
        // Decrement old state count
        if (_stateCounts[oldState] > 0) {
            _stateCounts[oldState]--;
        }
        // Increment new state count
        _stateCounts[newState]++;
        pixel.state = newState;

        // Special handling for Annihilated state
        if (newState == PixelState.Annihilated) {
             _burn(tokenId); // Burn the token using ERC721 helper
             // Note: Struct remains in storage but is effectively inert and inaccessible via standard owner/balance methods
             // Might be better to clear the struct or use a mapping to track burned tokens if needed.
             // For this example, burning is enough.
        }

        emit PixelStateChanged(tokenId, oldState, newState);
    }

     // Checks if a token exists (is not the zero-address owner)
     function _exists(uint256 tokenId) internal view returns (bool) {
        // Use ERC721 internal ownerOf method to check existence
        return _ownerOf(tokenId) != address(0);
    }


    // --- Core Pixel Interaction Functions ---

    /// @notice Mints a new Quantum Pixel NFT.
    /// @param to The address to mint the pixel to.
    /// @dev Costs Ether according to `operationCosts.mintCost`.
    function mint(address to) public payable whenNotPaused returns (uint256) {
        if (msg.value < operationCosts.mintCost) {
            revert InsufficientFunds(operationCosts.mintCost, msg.value);
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Generate initial properties
        (uint24 initialColor, uint16 initialStability, uint16 initialEnergy, bytes32 initialGenes) = _generateInitialProperties(to, block.number);

        _pixels[newTokenId] = Pixel({
            color: initialColor,
            stability: initialStability,
            energy: initialEnergy,
            genes: initialGenes,
            lastInteractionBlock: uint40(block.number),
            state: PixelState.Initial, // Starts in Initial state
            generation: 0,
            creationBlock: uint40(block.number)
        });

        _safeMint(to, newTokenId);
        _updatePixelState(newTokenId, PixelState.Active); // Immediately move to Active state after minting
        emit PixelMinted(newTokenId, to, initialColor, initialGenes);

        // Refund excess Ether
        if (msg.value > operationCosts.mintCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.mintCost);
        }

        return newTokenId;
    }

    /// @notice Charges a pixel, increasing its energy.
    /// @param tokenId The ID of the pixel.
    /// @dev Costs Ether and requires the pixel to be Active. Applies decay first.
    function chargePixel(uint256 tokenId) public payable whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        _applyDecay(tokenId);
        Pixel storage pixel = _pixels[tokenId];
        if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

        if (msg.value < operationCosts.chargeCost) {
            revert InsufficientFunds(operationCosts.chargeCost, msg.value);
        }

        uint16 energyToAdd = uint16(msg.value / (operationCosts.chargeCost / 1000) * 1000); // Simple calculation for energy gained per ether
        // Prevent overflow, cap at max uint16
        uint16 currentEnergy = pixel.energy;
        uint16 newEnergy = currentEnergy + energyToAdd;
        if (newEnergy < currentEnergy) { // Check for overflow
            newEnergy = type(uint16).max;
        }
        pixel.energy = newEnergy;

        pixel.lastInteractionBlock = uint40(block.number); // Update interaction block
        emit PixelCharged(tokenId, energyToAdd, pixel.energy);

        // Refund excess Ether
         if (msg.value > operationCosts.chargeCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.chargeCost);
        }
    }

    /// @notice Observes a pixel, updating its last interaction block to slow decay.
    /// @param tokenId The ID of the pixel.
    /// @dev Costs minimal Ether and requires the pixel to be Active. Applies decay first.
    function observePixel(uint256 tokenId) public payable whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        _applyDecay(tokenId);
        Pixel storage pixel = _pixels[tokenId];
        if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

         if (msg.value < operationCosts.observeCost) {
            revert InsufficientFunds(operationCosts.observeCost, msg.value);
        }

        // Minimal cost/energy consumption
        if (pixel.energy > 0) pixel.energy -= 1; // Optional minimal energy cost

        pixel.lastInteractionBlock = uint40(block.number); // Crucial: update interaction block
        // No specific event other than the potential DecayApplied if triggered.
        // Could add a PixelObserved event if desired.
        emit PixelPropertiesUpdated(tokenId, pixel.color, pixel.stability, pixel.energy, pixel.genes); // Use a generic update event
         // Refund excess Ether
         if (msg.value > operationCosts.observeCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.observeCost);
        }
    }

    /// @notice Fortifies a pixel, increasing its stability.
    /// @param tokenId The ID of the pixel.
    /// @dev Consumes energy and costs Ether. Requires pixel to be Active. Applies decay first.
    function fortifyPixel(uint256 tokenId) public payable whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        _applyDecay(tokenId);
        Pixel storage pixel = _pixels[tokenId];
        if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

        if (msg.value < operationCosts.fortifyCost) {
            revert InsufficientFunds(operationCosts.fortifyCost, msg.value);
        }

        uint16 energyRequired = 1000; // Example energy cost
        if (pixel.energy < energyRequired) {
            revert InsufficientEnergy(energyRequired, pixel.energy);
        }

        pixel.energy -= energyRequired;
        uint16 stabilityGain = uint16(msg.value / (operationCosts.fortifyCost / 1000) * 500); // Example stability gained per ether

        // Prevent overflow, cap at max uint16
        uint16 currentStability = pixel.stability;
        uint16 newStability = currentStability + stabilityGain;
        if (newStability < currentStability) { // Check for overflow
            newStability = type(uint16).max;
        }
        pixel.stability = newStability;


        pixel.lastInteractionBlock = uint40(block.number);
        emit PixelFortified(tokenId, stabilityGain, pixel.stability);
         // Refund excess Ether
         if (msg.value > operationCosts.fortifyCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.fortifyCost);
        }
    }

    /// @notice Attempts to mutate the pixel's properties.
    /// @param tokenId The ID of the pixel.
    /// @dev High energy/Ether cost. Outcome is based on pixel state and pseudo-random seed. Requires pixel to be Active. Applies decay first.
    function splicePixel(uint256 tokenId) public payable whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        _applyDecay(tokenId);
        Pixel storage pixel = _pixels[tokenId];
        if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

         if (msg.value < operationCosts.spliceCost) {
            revert InsufficientFunds(operationCosts.spliceCost, msg.value);
        }

        uint16 energyRequired = 2000; // Example energy cost
        if (pixel.energy < energyRequired) {
            revert InsufficientEnergy(energyRequired, pixel.energy);
        }

        pixel.energy -= energyRequired;

        bytes32 seed = _generateRandomSeed(tokenId);
        uint256 rand = uint256(seed);

        bool success = false;
        uint24 oldColor = pixel.color;
        bytes32 oldGenes = pixel.genes;

        // --- Simple Mutation Logic based on seed and current state ---
        // This is a simplified example; complex gene/state interactions can be added
        uint16 mutationChance = 5000; // Base chance out of 65535
        mutationChance += pixel.energy / 10; // More energy = higher chance
        mutationChance += pixel.stability / 20; // More stability = higher chance

        if (rand % 65536 < mutationChance) {
            success = true;
            // Mutate color: shift bytes, mix with seed
            pixel.color = uint24((uint256(pixel.color) << 8 | (rand % 256)) % (2**24));
            // Mutate genes: mix with seed and current genes
            pixel.genes = keccak256(abi.encodePacked(pixel.genes, seed));

            // Small random effect on stats
            if (rand % 2 == 0) {
                pixel.stability = pixel.stability + uint16(rand % 1000);
            } else {
                 if (pixel.stability > uint16(rand % 500)) pixel.stability -= uint16(rand % 500); else pixel.stability = 0;
            }
             if (pixel.energy > 0) pixel.energy = pixel.energy + uint16(rand % 500); else pixel.energy = uint16(rand % 500);

             // Cap stats at max
             if (pixel.stability > type(uint16).max) pixel.stability = type(uint16).max;
             if (pixel.energy > type(uint16).max) pixel.energy = type(uint16).max;

        } else {
            // Failed mutation: minor negative effects
            if (pixel.stability > 500) pixel.stability -= 500; else pixel.stability = 0;
            if (pixel.energy > 200) pixel.energy -= 200; else pixel.energy = 0;
        }

        pixel.lastInteractionBlock = uint40(block.number);
        emit PixelMutated(tokenId, seed, success, pixel.color, pixel.genes);
        emit PixelPropertiesUpdated(tokenId, pixel.color, pixel.stability, pixel.energy, pixel.genes);
        // Refund excess Ether
         if (msg.value > operationCosts.spliceCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.spliceCost);
        }
    }

    /// @notice Fuses two pixels into one new pixel, burning the originals.
    /// @param tokenAId The ID of the first pixel.
    /// @param tokenBId The ID of the second pixel.
    /// @dev Requires both pixels to be owned by the caller and in Active state. High energy/Ether cost. Applies decay to both first.
    function fusePixels(uint256 tokenAId, uint256 tokenBId) public payable whenNotPaused {
        if (!_exists(tokenAId)) revert TokenDoesNotExist();
        if (!_exists(tokenBId)) revert TokenDoesNotExist();
        if (tokenAId == tokenBId) revert CannotFuseSelf();

        address owner = _msgSender();
        if (_ownerOf(tokenAId) != owner || _ownerOf(tokenBId) != owner) {
             revert CannotFuseDifferentOwners();
        }

        _applyDecay(tokenAId);
        _applyDecay(tokenBId);

        Pixel storage pixelA = _pixels[tokenAId];
        Pixel storage pixelB = _pixels[tokenBId];

        if (pixelA.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixelA.state);
        if (pixelB.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixelB.state);

         if (msg.value < operationCosts.fusionCost) {
            revert InsufficientFunds(operationCosts.fusionCost, msg.value);
        }

        uint16 energyRequiredA = 1500; // Example energy costs for fusion
        uint16 energyRequiredB = 1500;
         if (pixelA.energy < energyRequiredA) revert InsufficientEnergy(energyRequiredA, pixelA.energy);
         if (pixelB.energy < energyRequiredB) revert InsufficientEnergy(energyRequiredB, pixelB.energy);

        pixelA.energy -= energyRequiredA;
        pixelB.energy -= energyRequiredB;


        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // --- Fusion Logic (Example: weighted average/mix) ---
        uint24 newColor = uint24(((uint256(pixelA.color) + uint256(pixelB.color)) / 2) % (2**24));
        uint16 newStability = uint16((uint256(pixelA.stability) + uint256(pixelB.stability)) / 2);
        uint16 newEnergy = uint16((uint256(pixelA.energy) + uint256(pixelB.energy)) / 2);
        bytes32 newGenes = keccak256(abi.encodePacked(pixelA.genes, pixelB.genes, _generateRandomSeed(0))); // Combine genes and add randomness
        uint8 newGeneration = Math.max(pixelA.generation, pixelB.generation) + 1;

        _pixels[newTokenId] = Pixel({
            color: newColor,
            stability: newStability,
            energy: newEnergy,
            genes: newGenes,
            lastInteractionBlock: uint40(block.number),
            state: PixelState.Initial, // Starts in Initial before moving to Active
            generation: newGeneration,
            creationBlock: uint40(block.number)
        });

        _safeMint(owner, newTokenId);
        _updatePixelState(newTokenId, PixelState.Active); // Immediately move to Active

        // Burn the original tokens (changes their state to Annihilated)
        _updatePixelState(tokenAId, PixelState.Annihilated);
        _updatePixelState(tokenBId, PixelState.Annihilated);

        emit PixelFused(tokenAId, tokenBId, newTokenId, newGeneration);
        emit PixelMinted(newTokenId, owner, newColor, newGenes); // Also emit mint event for the new token

         // Refund excess Ether
         if (msg.value > operationCosts.fusionCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.fusionCost);
        }
    }

    /// @notice Puts a pixel into hibernation. Decay is paused.
    /// @param tokenId The ID of the pixel.
    /// @dev Requires pixel to be Active. Applies decay first.
    function hibernatePixel(uint256 tokenId) public whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         _applyDecay(tokenId); // Apply decay before hibernating
         Pixel storage pixel = _pixels[tokenId];
         if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

         _updatePixelState(tokenId, PixelState.Hibernating);
         // lastInteractionBlock is NOT updated here. It stays as the block it entered hibernation.
         // When waking up, decay is calculated from that last interaction block.
    }

    /// @notice Wakes a pixel from hibernation. Decay resumes.
    /// @param tokenId The ID of the pixel.
    /// @dev Requires pixel to be Hibernating. Applies decay based on hibernation duration.
    function wakePixel(uint256 tokenId) public whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         Pixel storage pixel = _pixels[tokenId];
         if (pixel.state != PixelState.Hibernating) revert MustBeInState(PixelState.Hibernating, pixel.state);

         // Apply decay for the duration it was hibernating, using the rate defined for active state.
         // A more complex version could have a separate hibernation decay rate.
         _applyDecay(tokenId); // This will calculate decay from lastInteractionBlock (when it went into hibernation)

         // Check if decay reduced it to Decaying state upon waking
         if (pixel.state == PixelState.Hibernating) {
             // Only transition to Active if it's still Hibernating after decay check
            _updatePixelState(tokenId, PixelState.Active);
            pixel.lastInteractionBlock = uint40(block.number); // Reset interaction block
         }
         // If decay made it Decaying, the state is already updated by _applyDecay.
    }


    /// @notice Attempts to make a pixel permanently Stable.
    /// @param tokenId The ID of the pixel.
    /// @dev Requires pixel to be Active, meet stabilization requirements (stability, energy, gene pattern), and costs Ether. Applies decay first.
    function stabilizePixel(uint256 tokenId) public payable whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         _applyDecay(tokenId);
         Pixel storage pixel = _pixels[tokenId];
         if (pixel.state != PixelState.Active) revert MustBeInState(PixelState.Active, pixel.state);

         if (msg.value < operationCosts.stabilizeCost) {
            revert InsufficientFunds(operationCosts.stabilizeCost, msg.value);
         }

         // Check Stabilization Requirements
         bool meetsRequirements = pixel.stability >= stabilizationRequirements.minStability &&
                                  pixel.energy >= stabilizationRequirements.minEnergy &&
                                  ((pixel.genes ^ stabilizationRequirements.requiredGenePattern) & stabilizationRequirements.genePatternMask) == bytes32(0);

         if (!meetsRequirements) {
             revert StabilizationRequirementsNotMet();
         }

         // Consume resources (optional, but makes sense)
         pixel.energy = pixel.energy > stabilizationRequirements.minEnergy ? pixel.energy - stabilizationRequirements.minEnergy : 0;
         // Don't reduce stability, that's the point of stabilizing it.

         _updatePixelState(tokenId, PixelState.Stable);
         // lastInteractionBlock becomes irrelevant in Stable state

         emit PixelStabilized(tokenId);

         // Refund excess Ether
         if (msg.value > operationCosts.stabilizeCost) {
            payable(msg.sender).transfer(msg.value - operationCosts.stabilizeCost);
        }
    }

    /// @notice Allows the owner to permanently burn a pixel.
    /// @param tokenId The ID of the pixel.
    /// @dev Cannot annihilate a Stable pixel.
    function annihilatePixel(uint256 tokenId) public whenNotPaused onlyPixelOwnerOrApproved(tokenId) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         Pixel storage pixel = _pixels[tokenId];
         if (pixel.state == PixelState.Stable) revert CannotAnnihilateStable();
         if (pixel.state == PixelState.Annihilated) revert AlreadyInState(PixelState.Annihilated); // Already burned

         _updatePixelState(tokenId, PixelState.Annihilated);
         emit PixelAnnihilated(tokenId);
         // Note: ERC721 _burn already handles token ownership and supply.
         // The struct data remains but is not accessible via standard ERC721 calls.
    }

    /// @notice Allows anyone to trigger decay for a specific pixel.
    /// @param tokenId The ID of the pixel.
    /// @dev Only applies decay if the pixel is in the Active state.
    function checkAndApplyDecay(uint256 tokenId) public {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         _applyDecay(tokenId); // This function handles the state check internally
    }


    // --- View Functions ---

    /// @notice Gets the core numeric properties of a pixel.
    /// @param tokenId The ID of the pixel.
    /// @return color, stability, energy, genes, lastInteractionBlock
    function getPixelProperties(uint256 tokenId) public view returns (uint24 color, uint16 stability, uint16 energy, bytes32 genes, uint40 lastInteractionBlock) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         Pixel storage pixel = _pixels[tokenId];
         return (pixel.color, pixel.stability, pixel.energy, pixel.genes, pixel.lastInteractionBlock);
    }

    /// @notice Gets the current lifecycle state of a pixel.
    /// @param tokenId The ID of the pixel.
    /// @return The PixelState enum value.
    function getPixelState(uint256 tokenId) public view returns (PixelState) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return _pixels[tokenId].state;
    }

    /// @notice Gets the creation data for a pixel.
    /// @param tokenId The ID of the pixel.
    /// @return creationBlock, generation
    function getPixelCreationData(uint256 tokenId) public view returns (uint40 creationBlock, uint8 generation) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         Pixel storage pixel = _pixels[tokenId];
         return (pixel.creationBlock, pixel.generation);
    }

     /// @notice Gets the generation number of a pixel.
     /// @param tokenId The ID of the pixel.
     /// @return The generation number (0 for minted, 1+ for fused).
    function getPixelGeneration(uint256 tokenId) public view returns (uint8) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return _pixels[tokenId].generation;
    }

     /// @notice Gets the total count of pixels in the Active state.
     /// @return The count of Active pixels.
    function getTotalActivePixels() public view returns (uint256) {
        return _stateCounts[PixelState.Active];
    }

     /// @notice Gets the current Ether costs for various operations.
     /// @return operationCosts struct.
    function getOperationCosts() public view returns (OperationCosts) {
        return operationCosts;
    }

    /// @notice Gets the current criteria needed to make a pixel Stable.
    /// @return stabilizationRequirements struct.
    function getStabilizationRequirements() public view returns (StabilizationRequirements) {
        return stabilizationRequirements;
    }

     /// @notice Gets the contract's paused status and owner address.
     /// @return isPaused, ownerAddress
    function getContractState() public view returns (bool isPaused, address ownerAddress) {
        return (paused(), owner());
    }


    /// @notice Generates the dynamic JSON metadata for a pixel.
    /// @param tokenId The ID of the pixel.
    /// @return A data URI containing the Base64 encoded JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        Pixel storage pixel = _pixels[tokenId];
        address owner = _ownerOf(tokenId); // Get the owner using ERC721's internal function

        string memory name = string(abi.encodePacked("Quantum Pixel #", Strings.toString(tokenId)));
        string memory description = "A dynamic Quantum Pixel, evolving based on on-chain interactions and time.";

        string memory image = ""; // Placeholder for an image URL, could be generated dynamically off-chain based on properties or point to a static base image.
        // Example: could point to an API endpoint that renders the pixel based on its color/state/genes.
        // For a purely on-chain version, you might encode a very simple SVG or color data.

        // Dynamic attributes array
        string memory attributes = string(abi.encodePacked(
            "[",
            '{"trait_type": "State", "value": "', pixelStateToString(pixel.state), '"},',
            '{"trait_type": "Generation", "value": ', Strings.toString(pixel.generation), '},',
            '{"trait_type": "Stability", "value": ', Strings.toString(pixel.stability), '},',
            '{"trait_type": "Energy", "value": ', Strings.toString(pixel.energy), '},',
            '{"trait_type": "Color (RGB)", "value": "#', bytesToHex(bytes32(uint256(pixel.color))), '"}', // Hex representation of color
            // Add other properties as needed
            "]"
        ));

        string memory json = string(abi.encodePacked(
            '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', image, '",',
                '"attributes": ', attributes,
            '}'
        ));

        bytes memory jsonBytes = bytes(json);
        string memory base64Json = Base64.encode(jsonBytes);

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    // Helper to convert PixelState enum to string for metadata
    function pixelStateToString(PixelState state) internal pure returns (string memory) {
        if (state == PixelState.Initial) return "Initial";
        if (state == PixelState.Active) return "Active";
        if (state == PixelState.Hibernating) return "Hibernating";
        if (state == PixelState.Decaying) return "Decaying";
        if (state == PixelState.Stable) return "Stable";
        if (state == PixelState.Annihilated) return "Annihilated";
        return "Unknown"; // Should not happen
    }

    // Helper to convert bytes to hex string (simplified for uint24 color)
    function bytesToHex(bytes32 b) internal pure returns (string memory) {
        bytes memory s = new bytes(6); // For uint24, we need 6 hex chars
        bytes memory alphabet = "0123456789abcdef";
        for (uint i = 0; i < 3; i++) { // Only take the first 3 bytes (uint24)
            s[i*2] = alphabet[uint8(b[i] >> 4)];
            s[i*2+1] = alphabet[uint8(b[i] & 0x0f)];
        }
         return string(s);
    }


    // --- Admin Functions ---

    /// @notice Sets the rate of decay per block for Active pixels.
    /// @param _rate The new decay rate (stability points per block).
    function setDecayRate(uint16 _rate) public onlyOwner {
        decayRatePerBlock = _rate;
        emit DecayRateUpdated(_rate);
    }

    /// @notice Sets the Ether costs for various operations.
    /// @param _costs The struct containing the new costs.
    function setOperationCosts(OperationCosts calldata _costs) public onlyOwner {
        operationCosts = _costs;
        emit OperationCostsUpdated(_costs);
    }

    /// @notice Sets the criteria needed to make a pixel Stable.
    /// @param _reqs The struct containing the new requirements.
    function setStabilizationRequirements(StabilizationRequirements calldata _reqs) public onlyOwner {
        stabilizationRequirements = _reqs;
        emit StabilizationRequirementsUpdated(_reqs);
    }

    /// @notice Pauses core pixel interactions (mint, charge, fortify, splice, fuse).
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core pixel interactions.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Withdraws accumulated Ether fees to a recipient.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        recipient.transfer(balance);
    }


    // --- ERC721 Standard Implementations ---
    // Standard ERC721 functions are mostly inherited or use internal helpers from OpenZeppelin.
    // We only need to ensure they interact correctly with our _pixels mapping if necessary,
    // but OpenZeppelin's _safeMint, _transfer, _burn handle the core ERC721 state.

    // Override required functions if needed, but OpenZeppelin handles most.
    // _beforeTokenTransfer and _afterTokenTransfer could be hooks if we needed them.
    // For this contract, the custom state (`_pixels` mapping and `Pixel` struct) is managed
    // alongside the standard ERC721 state (ownership, approvals).

    // Most standard functions delegate to OpenZeppelin's implementation:
    // balanceOf(address owner) is implemented by ERC721
    // ownerOf(uint256 tokenId) is implemented by ERC721
    // transferFrom(address from, address to, uint256 tokenId) is implemented by ERC721
    // safeTransferFrom(address from, address to, uint256 tokenId) is implemented by ERC721 (two versions)
    // approve(address to, uint256 tokenId) is implemented by ERC721
    // getApproved(uint256 tokenId) is implemented by ERC721
    // setApprovalForAll(address operator, bool approved) is implemented by ERC721
    // isApprovedForAll(address owner, address operator) is implemented by ERC721
    // supportsInterface(bytes4 interfaceId) is implemented by ERC721

    // totalSupply requires a counter if not all token IDs are minted consecutively.
    // OpenZeppelin's ERC721 typically tracks supply via balance mapping.
    // If we rely on `_tokenIdCounter`, we need to be careful about burned tokens affecting the count.
    // A simple total supply is the highest minted ID, but includes burned tokens.
    // If we wanted *non-burned* supply, we'd need another counter or state tracking.
    // Let's provide the total count of *minted* tokens (including burned) as the standard totalSupply.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Optional: Override _beforeTokenTransfer to add custom logic if needed (e.g., preventing transfer in certain states)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //      // Example: Prevent transferring Decaying pixels
    //     if (from != address(0) && to != address(0)) { // Only on actual transfers, not minting/burning
    //         Pixel storage pixel = _pixels[tokenId];
    //         if (pixel.state == PixelState.Decaying) {
    //             revert InvalidTokenState(PixelState.Active, pixel.state); // Or a more specific error
    //         }
    //         // Can also prevent transfer while Hibernating, etc.
    //     }
    // }


    // Receive Ether function to accept payments for operations
    receive() external payable {}

    // Fallback function (optional, could also accept Ether or revert)
    fallback() external payable {
         revert("Invalid transaction"); // Or handle as receive()
    }
}
```

**Explanation of Advanced Concepts:**

1.  **Dynamic State & Decay:** The `PixelState` enum and the `stability` property, combined with the `_applyDecay` function, create a system where NFTs are not static. Their "health" (stability) degrades over time if not interacted with (`lastInteractionBlock`). This encourages engagement and maintenance. The `checkAndApplyDecay` allows anyone to trigger this check, distributing computation.
2.  **On-Chain Pseudo-Randomness:** The `_generateRandomSeed` and its use in `splicePixel` simulate random outcomes based on block data and pixel properties. While not truly unpredictable due to blockchain transparency, it provides variable results for mutation *within* the deterministic environment of the EVM, influencing color, genes, and stats in a non-linear way.
3.  **State-Dependent Logic:** Most interaction functions (`chargePixel`, `fortifyPixel`, `splicePixel`, `fusePixels`, `hibernatePixel`, `stabilizePixel`) require the pixel to be in a specific `PixelState` (`Active`). This creates a lifecycle where different actions are possible or necessary depending on the pixel's current condition. `CannotAnnihilateStable` is another example of a state-based restriction.
4.  **NFT Fusion:** The `fusePixels` function introduces a creative way to combine two existing NFTs (burning them) to produce a new, higher-generation NFT. This adds a deflationary mechanic for the parent tokens and a progression system for the new token. The properties of the new token are derived on-chain.
5.  **Stabilization/Ascension:** The `stabilizePixel` function allows pixels meeting specific, configurable criteria (high stability, energy, gene pattern match) to enter a permanent `Stable` state, halting decay and representing a desired endpoint or achievement within the system.
6.  **On-Chain Metadata Generation:** The `tokenURI` function doesn't point to an external JSON file. Instead, it dynamically constructs the JSON metadata *on-chain* using `Base64.encode` and `Strings.toString`, reflecting the pixel's *current* properties and state. This means the NFT's appearance/description changes over time as its on-chain state changes, making it truly dynamic without relying on off-chain infrastructure (other than something to render the data URI).
7.  **Gene System (`bytes32 genes`):** While the mutation/stabilization logic is simplified, the `genes` property and the `stabilizationRequirements` using a `genePatternMask` lay the groundwork for a more complex genetic system influencing traits and outcomes.
8.  **Resource Management:** The `energy` property acts as an internal resource consumed by actions like `splice` and `fortify`, creating another layer of management for the owner.

This contract combines standard ERC721 ownership with a rich, dynamic state model and unique interaction mechanics, moving beyond simple static NFT ownership.