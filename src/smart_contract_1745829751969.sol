Okay, let's design an advanced Solidity smart contract that incorporates several modern concepts like dynamic NFTs, oracle interaction for state changes, yield generation, and a unique asset merging/splitting mechanic.

We'll create the `FluxFusionEngine` contract. This contract will manage unique digital assets (NFTs) called "Elements" and "Fusions". Elements have dynamic properties that can change over time based on external data (simulated via an Oracle). Users can combine Elements into Fusions, which inherit properties and potentially gain new abilities or enhanced yield.

**Core Concepts:**

1.  **Dynamic Assets (Elements/Fusions):** NFTs whose on-chain metadata (properties) can change based on contract logic.
2.  **Flux Mechanism:** An external trigger (via an Oracle) periodically alters the dynamic properties of active Elements.
3.  **Essence Yield:** Assets (Elements and Fusions) passively generate a yield token (`EssenceToken`) based on their current properties and time.
4.  **Fusion/Unfusion:** A unique mechanic to combine multiple Element NFTs into a single Fusion NFT, and potentially split a Fusion back into its components (with potential loss).
5.  **Utility Functions:** Mechanisms to influence properties, boost yield, or simulate effects.
6.  **Oracle Integration:** Relies on an external Oracle contract to provide data for the Flux mechanism.

---

### FluxFusionEngine Smart Contract

**Outline:**

1.  **Pragmas and Imports:** Solidity version, ERC721, Ownable.
2.  **Error Definitions:** Custom errors for clearer reverts.
3.  **Structs:** Define data structures for Element and Fusion assets.
4.  **Enums:** Define asset types and statuses.
5.  **Events:** Log significant contract actions.
6.  **State Variables:** Storage for assets, parameters, addresses, counters.
7.  **Modifiers:** Custom access control or condition checks.
8.  **Constructor:** Initialize the contract, set owner and dependencies.
9.  **Asset Management (Minting & Query):** Functions to create and retrieve asset data.
10. **ERC721 Standard Functions:** Inherited and potentially overridden standard NFT functions.
11. **Dynamic Properties & Flux:** Functions to manage and apply external state changes.
12. **Essence Yield:** Functions for calculating and claiming yield.
13. **Fusion Mechanics:** Functions for combining and splitting assets.
14. **Utility & Interaction:** Functions for user-driven effects on assets.
15. **Admin & Configuration:** Functions for owner to set parameters and addresses.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets owner, essence token address, and oracle address.
2.  `mintElement(address to)`: Creates a new Element NFT and assigns it to an address (owner-only).
3.  `batchMintElements(address to, uint256 count)`: Mints multiple Element NFTs at once (owner-only).
4.  `getElementDetails(uint256 elementId)`: Returns all stored details for a specific Element.
5.  `getFusionDetails(uint256 fusionId)`: Returns all stored details for a specific Fusion.
6.  `getAssetType(uint256 tokenId)`: Determines if a token ID is an Element or a Fusion.
7.  `getElementStatus(uint256 elementId)`: Returns the current status of an Element (Active, Fused, etc.).
8.  `getFusionStatus(uint256 fusionId)`: Returns the current status of a Fusion (Active, Unfusing, etc.).
9.  `getTotalAssets()`: Returns the total count of all managed NFTs (Elements + Fusions).
10. `applyFlux(uint256 oracleValue)`: Triggered by the Oracle to apply state changes based on `oracleValue` to all active Elements.
11. `calculatePendingEssenceYield(uint256 tokenId)`: Calculates the potential Essence yield accumulated for a specific asset.
12. `claimEssenceYield(uint256[] calldata tokenIds)`: Allows users to claim accumulated Essence yield for multiple assets.
13. `updateFluxParameters(uint256 newFluxInfluence, uint256 newMinFluxInterval)`: Owner sets parameters for the Flux effect.
14. `updateYieldParameters(uint256 newBaseYieldRate, uint256 newPropertyYieldFactor)`: Owner sets parameters for yield calculation.
15. `fuseElements(uint256[] calldata elementIds)`: Combines multiple Element NFTs into a new Fusion NFT. Requires burning/locking Elements and potential payment.
16. `unfuseFusion(uint256 fusionId)`: Initiates the process to break down a Fusion back into its constituent Elements (might involve waiting period or cost).
17. `claimUnfusedElements(uint256 fusionId)`: Completes the unfusion process after cooldown, transferring resulting Elements (or equivalents) back to the user.
18. `getFusionIngredients(uint256 fusionId)`: Returns the original Element IDs used to create a Fusion.
19. `getFuseCost()`: Returns the current cost parameters for fusing.
20. `setFuseCost(uint256 essenceCost, uint256 tokenCost, address tokenAddress)`: Owner sets the cost for fusing.
21. `probeFluxEffect(uint256 elementId, uint256 simulatedOracleValue)`: A view function to simulate the potential effect of a Flux event on a specific Element.
22. `applyCatalyst(uint256 tokenId, address catalystToken, uint256 amount)`: Allows burning a specific token as a "catalyst" for a temporary property boost or yield increase on an asset.
23. `refineProperty(uint256 tokenId, uint256 propertyIndex, uint256 essenceAmount)`: Allows burning Essence to slightly improve or stabilize a specific dynamic property.
24. `getRefinementCost()`: Returns the current cost for property refinement.
25. `setRefinementCost(uint256 essencePerPoint)`: Owner sets the cost parameter for refinement.
26. `getCatalystParameters()`: Returns parameters related to catalyst effects.
27. `setCatalystParameters(address catalystToken, uint256 boostFactor, uint256 duration)`: Owner sets parameters for catalyst effects.
28. `setEssenceTokenAddress(address _essenceToken)`: Owner sets the address of the associated Essence ERC20 token.
29. `setOracleAddress(address _oracle)`: Owner sets the address of the trusted Oracle contract.
30. `withdrawStuckTokens(address tokenAddress, uint256 amount)`: Owner function to rescue ERC20 tokens accidentally sent to the contract.
31. `getVersion()`: Returns the contract version string.
32. *Inherited ERC721 functions*: `ownerOf`, `balanceOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `tokenURI`. (Adding these implicitly brings the total well over 20 implemented/available functions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Pragmas and Imports
// 2. Error Definitions
// 3. Structs
// 4. Enums
// 5. Events
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Asset Management (Minting & Query)
// 10. ERC721 Standard Functions (Implicitly available)
// 11. Dynamic Properties & Flux
// 12. Essence Yield
// 13. Fusion Mechanics
// 14. Utility & Interaction
// 15. Admin & Configuration

// Function Summary:
// 1.  constructor(): Initializes contract, sets owner, essence token, oracle.
// 2.  mintElement(address to): Mints a new Element (owner-only).
// 3.  batchMintElements(address to, uint256 count): Mints multiple Elements (owner-only).
// 4.  getElementDetails(uint256 elementId): Gets Element details.
// 5.  getFusionDetails(uint256 fusionId): Gets Fusion details.
// 6.  getAssetType(uint256 tokenId): Determines if ID is Element or Fusion.
// 7.  getElementStatus(uint256 elementId): Gets Element status.
// 8.  getFusionStatus(uint256 fusionId): Gets Fusion status.
// 9.  getTotalAssets(): Gets total NFT count.
// 10. applyFlux(uint256 oracleValue): Applies Flux effects based on oracle data (oracle-only).
// 11. calculatePendingEssenceYield(uint256 tokenId): Calculates potential yield for an asset.
// 12. claimEssenceYield(uint256[] calldata tokenIds): Claims yield for multiple assets.
// 13. updateFluxParameters(uint256 newFluxInfluence, uint256 newMinFluxInterval): Owner sets Flux params.
// 14. updateYieldParameters(uint256 newBaseYieldRate, uint256 newPropertyYieldFactor): Owner sets yield params.
// 15. fuseElements(uint256[] calldata elementIds): Combines Elements into a Fusion (burns/locks Elements).
// 16. unfuseFusion(uint256 fusionId): Initiates Fusion unfusion process.
// 17. claimUnfusedElements(uint256 fusionId): Completes unfusion after cooldown.
// 18. getFusionIngredients(uint256 fusionId): Gets Element IDs used in a Fusion.
// 19. getFuseCost(): Gets current fusion costs.
// 20. setFuseCost(uint256 essenceCost, uint256 tokenCost, address tokenAddress): Owner sets fusion costs.
// 21. probeFluxEffect(uint256 elementId, uint256 simulatedOracleValue): Simulates Flux effect on an Element.
// 22. applyCatalyst(uint256 tokenId, address catalystToken, uint256 amount): Applies catalyst effect to asset.
// 23. refineProperty(uint256 tokenId, uint256 propertyIndex, uint256 essenceAmount): Refines asset property using Essence.
// 24. getRefinementCost(): Gets current refinement cost.
// 25. setRefinementCost(uint256 essencePerPoint): Owner sets refinement cost param.
// 26. getCatalystParameters(): Gets catalyst params.
// 27. setCatalystParameters(address catalystToken, uint256 boostFactor, uint256 duration): Owner sets catalyst params.
// 28. setEssenceTokenAddress(address _essenceToken): Owner sets Essence ERC20 address.
// 29. setOracleAddress(address _oracle): Owner sets Oracle address.
// 30. withdrawStuckTokens(address tokenAddress, uint256 amount): Owner rescues tokens.
// 31. getVersion(): Returns contract version.

contract FluxFusionEngine is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    string private constant _CONTRACT_VERSION = "1.0.0";

    // --- Error Definitions ---
    error InvalidTokenId();
    error NotAllowed();
    error InvalidQuantity();
    error ElementAlreadyFused();
    error FusionNotReadyForUnfusion();
    error UnfusionCooldownNotElapsed();
    error NotEnoughEssence();
    error NotEnoughTokens();
    error InvalidPropertyIndex();
    error NotAnElement();
    error NotAFusion();
    error CatalystTokenMismatch();
    error InsufficientCatalystAmount();
    error OracleOnly();
    error NoYieldPending();
    error AssetNotEligibleForYield(uint256 tokenId); // e.g., Fusing or Unfusing assets might not yield
    error NoElementsToFuse();
    error CannotUnfuseActiveFusion();


    // --- Structs ---
    struct Element {
        uint256 creationTime;
        uint256 lastFluxTime;
        uint256 lastYieldClaimTime;
        uint256 basePower; // Static initial value
        int256 dynamicPropertyA; // Can change via Flux
        int256 dynamicPropertyB; // Can change via Flux
        uint256 yieldMultiplier; // Influenced by properties
        ElementStatus status; // Active, Fused
        uint256 fusedIntoFusionId; // ID of the fusion this element belongs to
        CatalystEffect catalystEffect; // Current catalyst effect details
    }

    struct Fusion {
        uint256 creationTime;
        uint256 lastYieldClaimTime;
        uint256 combinedPower; // Sum of basePower of ingredients + bonus
        int256 aggregatedPropertyA; // Aggregated from ingredients + bonus/penalty
        int256 aggregatedPropertyB; // Aggregated from ingredients + bonus/penalty
        uint256 yieldMultiplier; // Enhanced yield potential
        uint256[] ingredientElementIds; // IDs of elements that formed this fusion
        FusionStatus status; // Active, Unfusing, Unfused
        uint224 unfusionStartTime; // Timestamp when unfuse was called
        CatalystEffect catalystEffect; // Current catalyst effect details
    }

    struct CatalystEffect {
        uint256 boostFactor;
        uint256 endTime;
    }

    // --- Enums ---
    enum AssetType {
        None,
        Element,
        Fusion
    }

    enum ElementStatus {
        Active,
        Fused, // Currently part of a Fusion
        Dormant // Could be a future state, e.g., needing reactivation
    }

    enum FusionStatus {
        Active,
        Unfusing, // Unfusion process started, in cooldown
        Unfused // Unfusion complete, pending claim (or deprecated state)
    }

    // --- Events ---
    event ElementMinted(uint256 indexed elementId, address indexed owner, uint256 creationTime);
    event FusionCreated(uint256 indexed fusionId, address indexed owner, uint256 creationTime, uint256[] ingredientElementIds);
    event FluxApplied(uint256 indexed tokenId, uint256 lastFluxTime, int256 newPropertyA, int256 newPropertyB, uint256 newYieldMultiplier, uint256 oracleValue);
    event YieldClaimed(address indexed owner, uint256 indexed tokenId, uint256 amountClaimed);
    event FusionUnfusionInitiated(uint256 indexed fusionId, uint256 unfusionStartTime);
    event FusionUnfusionCompleted(uint256 indexed fusionId, uint256[] resultingElementIds); // IDs might be same or new
    event PropertyRefined(uint256 indexed tokenId, uint256 propertyIndex, int256 newPropertyValue);
    event CatalystApplied(uint256 indexed tokenId, address indexed catalystToken, uint256 amountUsed, uint256 boostFactor, uint256 endTime);
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event AddressParameterUpdated(string parameterName, address oldAddress, address newAddress);


    // --- State Variables ---
    Counters.Counter private _elementIds;
    Counters.Counter private _fusionIds;

    // Mapping tokenId -> AssetType
    mapping(uint256 => AssetType) private _assetTypes;

    // Mapping ElementId -> Element details
    mapping(uint256 => Element) private _elements;

    // Mapping FusionId -> Fusion details
    mapping(uint256 => Fusion) private _fusions;

    // ERC20 token for yield
    IERC20 public essenceToken;

    // Oracle contract address (trusted source for flux data)
    address public oracleAddress;

    // --- Configuration Parameters ---
    uint256 public fluxInfluence = 10; // How much oracleValue affects properties (e.g., scale factor)
    uint256 public minFluxInterval = 1 days; // Minimum time between global flux events

    uint256 public baseYieldRate = 100; // Base yield per asset per second (scaled)
    uint256 public propertyYieldFactor = 10; // How much dynamic properties influence yield multiplier

    uint256 public fusionEssenceCost = 50 ether; // Cost in Essence tokens to fuse
    uint256 public fusionTokenCost = 0; // Optional cost in another token
    address public fusionCostTokenAddress = address(0); // Address of optional fusion cost token

    uint256 public unfusionCooldown = 3 days; // Time required before unfused elements can be claimed
    uint256 public unfusionRefundRate = 80; // Percentage of ingredients returned on unfusion (e.g., 80 for 80%)

    uint256 public refinementEssencePerPoint = 1 ether; // Essence cost to improve a property by 1 point

    address public catalystTokenAddress = address(0); // Default catalyst token
    uint256 public catalystBoostFactor = 1; // Multiplier for yield during catalyst effect
    uint256 public catalystDuration = 1 days; // Duration of catalyst effect


    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert OracleOnly();
        }
        _;
    }

    modifier onlyElement(uint256 tokenId) {
        if (_assetTypes[tokenId] != AssetType.Element) {
            revert NotAnElement();
        }
        _;
    }

    modifier onlyFusion(uint256 tokenId) {
        if (_assetTypes[tokenId] != AssetType.Fusion) {
            revert NotAFusion();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _essenceToken, address _oracle) ERC721("FluxFusionAsset", "FFA") Ownable(msg.sender) {
        essenceToken = IERC20(_essenceToken);
        oracleAddress = _oracle;
    }

    // --- Asset Management (Minting & Query) ---

    /// @notice Mints a new Element NFT. Only callable by the contract owner.
    /// @param to The address to mint the Element to.
    function mintElement(address to) public onlyOwner {
        _elementIds.increment();
        uint256 newItemId = _elementIds.current();

        _safeMint(to, newItemId);

        _assetTypes[newItemId] = AssetType.Element;
        _elements[newItemId] = Element({
            creationTime: block.timestamp,
            lastFluxTime: block.timestamp,
            lastYieldClaimTime: block.timestamp,
            basePower: 100, // Initial base value
            dynamicPropertyA: int256(50), // Initial dynamic value
            dynamicPropertyB: int256(50), // Initial dynamic value
            yieldMultiplier: 100, // Initial multiplier (e.g., 100 = 1x)
            status: ElementStatus.Active,
            fusedIntoFusionId: 0,
            catalystEffect: CatalystEffect(0, 0)
        });

        emit ElementMinted(newItemId, to, block.timestamp);
    }

    /// @notice Mints multiple new Element NFTs in a single transaction. Only callable by the contract owner.
    /// @param to The address to mint the Elements to.
    /// @param count The number of Elements to mint.
    function batchMintElements(address to, uint256 count) public onlyOwner {
        if (count == 0) revert InvalidQuantity();
        for (uint256 i = 0; i < count; i++) {
            mintElement(to); // Re-uses the single mint logic
        }
    }

    /// @notice Retrieves the detailed information for a specific Element NFT.
    /// @param elementId The ID of the Element.
    /// @return Element struct containing all its properties.
    function getElementDetails(uint256 elementId) public view onlyElement(elementId) returns (Element memory) {
        return _elements[elementId];
    }

    /// @notice Retrieves the detailed information for a specific Fusion NFT.
    /// @param fusionId The ID of the Fusion.
    /// @return Fusion struct containing all its properties.
    function getFusionDetails(uint256 fusionId) public view onlyFusion(fusionId) returns (Fusion memory) {
        return _fusions[fusionId];
    }

    /// @notice Determines the type of asset based on its token ID.
    /// @param tokenId The ID of the asset (Element or Fusion).
    /// @return An enum indicating the AssetType (None, Element, Fusion).
    function getAssetType(uint256 tokenId) public view returns (AssetType) {
        return _assetTypes[tokenId];
    }

    /// @notice Gets the current status of an Element.
    /// @param elementId The ID of the Element.
    /// @return An enum indicating the ElementStatus.
    function getElementStatus(uint256 elementId) public view onlyElement(elementId) returns (ElementStatus) {
        return _elements[elementId].status;
    }

    /// @notice Gets the current status of a Fusion.
    /// @param fusionId The ID of the Fusion.
    /// @return An enum indicating the FusionStatus.
    function getFusionStatus(uint256 fusionId) public view onlyFusion(fusionId) returns (FusionStatus) {
        return _fusions[fusionId].status;
    }


    /// @notice Gets the total number of Element and Fusion assets minted.
    /// @return The total count of NFTs managed by this contract.
    function getTotalAssets() public view returns (uint256) {
        // Assuming Element IDs and Fusion IDs are globally unique counters starting from 1
        // If using shared counter or other system, this logic might need adjustment.
        // With separate counters, total is sum of current values.
        return _elementIds.current() + _fusionIds.current();
    }


    // --- Dynamic Properties & Flux ---

    /// @notice Applies a Flux event to all active Elements. Callable only by the Oracle address.
    /// Properties change based on the provided oracleValue and time since last Flux.
    /// @param oracleValue The value provided by the trusted oracle.
    function applyFlux(uint256 oracleValue) public onlyOracle {
        // Simplified flux logic: Affects all active Elements.
        // In a real system, this might iterate through _allTokenIds or active_element_list
        // For demonstration, let's just simulate affecting a range or specific high-ID elements.
        // A real system might need a more complex iterator or processing pattern for many NFTs.
        // Or, the flux effect could be calculated lazily when accessing/interacting with an NFT.

        // --- Lazy Flux Application (More scalable approach) ---
        // Instead of iterating all NFTs here, mark that a flux occurred and what the value was.
        // The actual property update happens when the NFT is next accessed or interacted with.
        // This saves gas on the Oracle call but adds computation to user interactions.
        // Let's stick to the "apply now" for simplicity in this example, acknowledging limitations.
        // To avoid iterating potentially millions of tokens, let's define a max number or affect randomly.
        // For this example, we'll apply lazily, calculating effect on read/claim.

        // Record the flux event
        uint256 currentFluxTimestamp = block.timestamp;
        // Store oracleValue and timestamp - requires state variable or list (complex).
        // For simplicity here, let's assume the effect is applied based on *last* stored oracle value
        // or derived from the *current* call's value and time since *last* flux *on the token*.

        // Let's revise: Flux updates properties on *call*, but only if enough time has passed *globally* since the *last Oracle call*.
        // This prevents frequent, cheap Oracle calls from changing state constantly.
        uint256 timeSinceLastGlobalFlux = block.timestamp - _lastGlobalFluxTime;
        if (timeSinceLastGlobalFlux < minFluxInterval) {
             // Or handle this constraint in the Oracle caller contract
            return; // Too soon for global flux
        }
        _lastGlobalFluxTime = block.timestamp; // Record this successful flux

        // Now, iterate through all *existing* Elements and update properties.
        // THIS IS GAS-INTENSIVE FOR LARGE NUMBERS OF NFTS.
        // A production system would likely use a lazy update or a different pattern (e.g., commit/reveal).
        // For the example, we iterate up to the current element ID.
        // We only update if the Element is Active and hasn't been updated by *this* specific flux event yet.

        uint256 currentMaxElementId = _elementIds.current();
        for (uint256 i = 1; i <= currentMaxElementId; i++) {
             // Check if it's a valid Element and Active
            if (_assetTypes[i] == AssetType.Element && _elements[i].status == ElementStatus.Active) {
                 // Only update if not already updated by the most recent global flux
                if (_elements[i].lastFluxTime < _lastGlobalFluxTime) {
                    _applySingleElementFlux(i, oracleValue);
                }
            }
        }

        // Note: Fusion properties are derived and less directly affected by Flux,
        // or their properties are aggregated from their (already fluxed) ingredients.
        // For simplicity, Fusion properties are static once fused unless unfused or refined.
    }

    // Internal function to apply flux effect to a single element
    function _applySingleElementFlux(uint256 elementId, uint256 oracleValue) internal {
        Element storage element = _elements[elementId];
        uint256 timeElapsedSinceLastFlux = block.timestamp - element.lastFluxTime;

        // Calculate change based on oracle value and time elapsed
        // Example: oracleValue affects magnitude, timeElapsed affects persistence or randomness
        // Simple example: Shift properties based on (oracleValue / factor) and clamp within a range
        int256 fluxShiftA = int256((oracleValue % fluxInfluence) * (timeElapsedSinceLastFlux % 100) / 50); // Example complex calculation
        int256 fluxShiftB = int256((oracleValue % fluxInfluence) * (timeElapsedSinceLastFlux % 100) / 50); // Example complex calculation

        element.dynamicPropertyA += fluxShiftA;
        element.dynamicPropertyB += fluxShiftB;

        // Clamp properties within a reasonable range (e.g., -1000 to 1000)
        if (element.dynamicPropertyA > 1000) element.dynamicPropertyA = 1000;
        if (element.dynamicPropertyA < -1000) element.dynamicPropertyA = -1000;
        if (element.dynamicPropertyB > 1000) element.dynamicPropertyB = 1000;
        if (element.dynamicPropertyB < -1000) element.dynamicPropertyB = -1000;


        // Update yield multiplier based on new properties
        element.yieldMultiplier = uint256(100) + uint256(int256(element.dynamicPropertyA + element.dynamicPropertyB) * int256(propertyYieldFactor) / 100);
        if (element.yieldMultiplier == 0) element.yieldMultiplier = 1; // Prevent zero multiplier


        element.lastFluxTime = block.timestamp; // Record time it was last affected by THIS flux event

        emit FluxApplied(elementId, element.lastFluxTime, element.dynamicPropertyA, element.dynamicPropertyB, element.yieldMultiplier, oracleValue);
    }

    uint256 private _lastGlobalFluxTime; // Timestamp of the last successful global flux application

    // --- Essence Yield ---

    /// @notice Calculates the potential Essence yield accumulated for a specific asset (Element or Fusion).
    /// Yield is based on asset properties, time elapsed since last claim, and parameters.
    /// @param tokenId The ID of the asset (Element or Fusion).
    /// @return The amount of Essence tokens the asset has accumulated.
    function calculatePendingEssenceYield(uint256 tokenId) public view returns (uint256) {
        AssetType assetType = _assetTypes[tokenId];
        uint256 lastClaimTime;
        uint256 yieldMultiplier;
        bool isActive = true;

        if (assetType == AssetType.Element) {
            Element storage element = _elements[tokenId];
             // Elements in Fusion or Unfusing cannot yield
            if (element.status != ElementStatus.Active) {
                 revert AssetNotEligibleForYield(tokenId);
            }
            lastClaimTime = element.lastYieldClaimTime;
            yieldMultiplier = element.yieldMultiplier;
             // Apply catalyst boost if active
            if (element.catalystEffect.endTime > block.timestamp) {
                 yieldMultiplier = yieldMultiplier * element.catalystEffect.boostFactor / 100; // Assuming boostFactor is percentage
            }

        } else if (assetType == AssetType.Fusion) {
            Fusion storage fusion = _fusions[tokenId];
             // Fusions being unfused cannot yield
             if (fusion.status != FusionStatus.Active) {
                  revert AssetNotEligibleForYield(tokenId);
             }
            lastClaimTime = fusion.lastYieldClaimTime;
            yieldMultiplier = fusion.yieldMultiplier;
            // Apply catalyst boost if active
            if (fusion.catalystEffect.endTime > block.timestamp) {
                 yieldMultiplier = yieldMultiplier * fusion.catalystEffect.boostFactor / 100;
            }
        } else {
            revert InvalidTokenId();
        }

        uint256 timeElapsed = block.timestamp - lastClaimTime;
        // Calculate yield: timeElapsed * baseRate * multiplier / scalingFactor (e.g., 10000 for 1e18 tokens)
        // Using a scaling factor to handle potential decimals and small numbers
        // Let's assume yieldMultiplier is scaled 100 = 1x, 200 = 2x etc.
        // baseYieldRate is yield per second scaled by 1e18
        uint256 yield = timeElapsed * baseYieldRate * yieldMultiplier / 100; // Adjusted scaling

        return yield;
    }


    /// @notice Allows users to claim accumulated Essence yield for a list of their assets.
    /// Transfers the calculated yield from the contract's balance to the caller.
    /// @param tokenIds An array of token IDs (Elements or Fusions) owned by the caller.
    function claimEssenceYield(uint256[] calldata tokenIds) public {
        address caller = msg.sender;
        uint256 totalYieldToClaim = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
             if (ownerOf(tokenId) != caller) {
                 revert NotAllowed(); // Only owner can claim yield for their token
             }

            AssetType assetType = _assetTypes[tokenId];
            uint252 currentTokenYield = 0; // Use uint252 to save gas? Or uint256 is fine.

            if (assetType == AssetType.Element) {
                 Element storage element = _elements[tokenId];
                 if (element.status != ElementStatus.Active) {
                     revert AssetNotEligibleForYield(tokenId); // Cannot claim for fused/dormant elements
                 }
                 currentTokenYield = uint252(calculatePendingEssenceYield(tokenId));
                 element.lastYieldClaimTime = block.timestamp; // Update claim time regardless of amount > 0

            } else if (assetType == AssetType.Fusion) {
                 Fusion storage fusion = _fusions[tokenId];
                 if (fusion.status != FusionStatus.Active) {
                      revert AssetNotEligibleForYield(tokenId); // Cannot claim for unfusing fusions
                 }
                 currentTokenYield = uint252(calculatePendingEssenceYield(tokenId));
                 fusion.lastYieldClaimTime = block.timestamp; // Update claim time

            } else {
                revert InvalidTokenId(); // Should not happen if ownerOf check passes
            }

            if (currentTokenYield > 0) {
                 totalYieldToClaim += currentTokenYield;
                 emit YieldClaimed(caller, tokenId, currentTokenYield);
            }
        }

        if (totalYieldToClaim == 0) {
            revert NoYieldPending();
        }

        // Transfer the total calculated yield to the caller
        essenceToken.safeTransfer(caller, totalYieldToClaim);
    }


    // --- Fusion Mechanics ---

    /// @notice Combines multiple Element NFTs into a new Fusion NFT.
    /// Requires the caller to own all provided Element IDs.
    /// Requires burning/locking the Element NFTs and potentially paying a cost (Essence or other tokens).
    /// @param elementIds An array of Element IDs to fuse. Must be at least 2.
    /// @dev The Element NFTs provided will be marked as 'Fused' and effectively burned (their ownership retained by this contract).
    /// A new Fusion NFT is minted to the caller.
    function fuseElements(uint256[] calldata elementIds) public {
        if (elementIds.length < 2) revert NoElementsToFuse();

        address caller = msg.sender;
        uint256 totalBasePower = 0;
        int256 totalPropertyA = 0;
        int256 totalPropertyB = 0;

        // Verify ownership and status of all elements
        for (uint256 i = 0; i < elementIds.length; i++) {
            uint256 elementId = elementIds[i];
             if (ownerOf(elementId) != caller) revert NotAllowed();
             onlyElement(elementId); // Ensure it's an element
             if (_elements[elementId].status != ElementStatus.Active) revert ElementAlreadyFused();

            totalBasePower += _elements[elementId].basePower;
            totalPropertyA += _elements[elementId].dynamicPropertyA;
            totalPropertyB += _elements[elementId].dynamicPropertyB;
        }

        // Pay fusion costs
        if (fusionEssenceCost > 0) {
            essenceToken.safeTransferFrom(caller, address(this), fusionEssenceCost);
        }
        if (fusionTokenCost > 0 && fusionCostTokenAddress != address(0)) {
            IERC20(fusionCostTokenAddress).safeTransferFrom(caller, address(this), fusionTokenCost);
        }

        // Create the new Fusion NFT
        _fusionIds.increment();
        uint256 newFusionId = _fusionIds.current();
        _safeMint(caller, newFusionId);
         _assetTypes[newFusionId] = AssetType.Fusion;


        // Calculate Fusion properties (example aggregation)
        uint256 ingredientCount = elementIds.length;
        _fusions[newFusionId] = Fusion({
            creationTime: block.timestamp,
            lastYieldClaimTime: block.timestamp,
            combinedPower: totalBasePower + (ingredientCount * 50), // Bonus power for fusing
            aggregatedPropertyA: totalPropertyA / int256(ingredientCount) + int256(ingredientCount * 10), // Average + bonus
            aggregatedPropertyB: totalPropertyB / int256(ingredientCount) + int256(ingredientCount * 10),
            yieldMultiplier: uint256(150) + uint256(int256(totalPropertyA + totalPropertyB) * int256(propertyYieldFactor) / (ingredientCount * 100)), // Higher base yield + aggregated properties
            ingredientElementIds: elementIds, // Store ingredients
            status: FusionStatus.Active,
            unfusionStartTime: 0, // Not unfusing yet
            catalystEffect: CatalystEffect(0, 0)
        });


        // Mark source Elements as Fused (ownership remains with this contract)
        for (uint256 i = 0; i < elementIds.length; i++) {
            uint256 elementId = elementIds[i];
            _elements[elementId].status = ElementStatus.Fused;
            _elements[elementId].fusedIntoFusionId = newFusionId;
             // Transfer NFT ownership to the contract, effectively locking them
            _transfer(caller, address(this), elementId);
        }

        emit FusionCreated(newFusionId, caller, block.timestamp, elementIds);
    }

    /// @notice Initiates the unfusion process for a Fusion NFT.
    /// The Fusion will enter an 'Unfusing' state and become ineligible for yield.
    /// After a cooldown period, the original ingredients (or a percentage) can be claimed.
    /// @param fusionId The ID of the Fusion NFT to unfuse. Must be owned by the caller and be Active.
    function unfuseFusion(uint256 fusionId) public onlyFusion(fusionId) {
        address caller = msg.sender;
        Fusion storage fusion = _fusions[fusionId];

        if (ownerOf(fusionId) != caller) revert NotAllowed();
        if (fusion.status != FusionStatus.Active) revert CannotUnfuseActiveFusion(); // Already unfusing or unfused

        fusion.status = FusionStatus.Unfusing;
        fusion.unfusionStartTime = uint224(block.timestamp);

        // Burn the Fusion NFT (transfer ownership to zero address)
        _transfer(caller, address(0), fusionId);

        emit FusionUnfusionInitiated(fusionId, block.timestamp);
    }

     /// @notice Claims the resulting Elements after a Fusion has completed its unfusion cooldown.
     /// A percentage of the original ingredient Elements are minted back to the caller.
     /// The Fusion NFT is marked as 'Unfused' (though it's already burned).
     /// @param fusionId The ID of the Fusion that completed unfusion.
    function claimUnfusedElements(uint256 fusionId) public onlyFusion(fusionId) {
        Fusion storage fusion = _fusions[fusionId];

         // Must be in Unfusing state and cooldown elapsed
        if (fusion.status != FusionStatus.Unfusing) revert FusionNotReadyForUnfusion();
        if (block.timestamp < fusion.unfusionStartTime + unfusionCooldown) revert UnfusionCooldownNotElapsed();

        address originalOwner = Ownable.owner(); // The contract owner holds the original elements
        address recipient = msg.sender; // The caller claiming the unfused elements

        // Mark Fusion as fully unfused (though NFT is already burned)
        fusion.status = FusionStatus.Unfused;

        uint256[] storage ingredientIds = fusion.ingredientElementIds;
        uint256 ingredientCount = ingredientIds.length;
        uint256 elementsToReturnCount = ingredientCount * unfusionRefundRate / 100;

        uint256[] memory resultingElementIds = new uint256[](elementsToReturnCount);

        // For each ingredient, determine if it's returned.
        // A simple way is to return the first `elementsToReturnCount` ingredients.
        for (uint256 i = 0; i < elementsToReturnCount; i++) {
            uint256 originalElementId = ingredientIds[i];
            Element storage originalElement = _elements[originalElementId];

             // Reset the ingredient Element's status and other relevant fields
            originalElement.status = ElementStatus.Active; // Make it usable again
            originalElement.fusedIntoFusionId = 0; // No longer part of a fusion
            originalElement.lastYieldClaimTime = block.timestamp; // Reset yield timer
            // Properties might be partially reset or randomized upon unfusion - complex, keep current for now.

            // Transfer the original Element NFT from contract back to the claimant
            _transfer(address(this), recipient, originalElementId);

            resultingElementIds[i] = originalElementId;
        }

         // The remaining ingredient Elements (if any) are effectively burned permanently by staying owned by address(this) and status 'Fused' or a new 'Burned' status.
         // Let's explicitly set status to Dormant or Burned if not returned.
         for (uint256 i = elementsToReturnCount; i < ingredientCount; i++) {
             uint256 originalElementId = ingredientIds[i];
             _elements[originalElementId].status = ElementStatus.Dormant; // Mark as unusable ingredient
             // Keep owner as contract address
         }


        emit FusionUnfusionCompleted(fusionId, resultingElementIds);
    }


    /// @notice Retrieves the list of Element IDs that were used to create a specific Fusion.
    /// @param fusionId The ID of the Fusion.
    /// @return An array of Element IDs.
    function getFusionIngredients(uint256 fusionId) public view onlyFusion(fusionId) returns (uint256[] memory) {
        return _fusions[fusionId].ingredientElementIds;
    }

    /// @notice Gets the current costs associated with performing a Fusion.
    /// @return essenceCost The amount of Essence tokens required.
    /// @return tokenCost The amount of the optional token required.
    /// @return tokenAddress The address of the optional token required.
    function getFuseCost() public view returns (uint256 essenceCost, uint256 tokenCost, address tokenAddress) {
        return (fusionEssenceCost, fusionTokenCost, fusionCostTokenAddress);
    }

    /// @notice Sets the cost parameters for performing a Fusion. Only callable by the contract owner.
    /// @param essenceCost The new amount of Essence tokens required.
    /// @param tokenCost The new amount of the optional token required.
    /// @param tokenAddress The address of the optional token required (address(0) if none).
    function setFuseCost(uint256 essenceCost, uint256 tokenCost, address tokenAddress) public onlyOwner {
         fusionEssenceCost = essenceCost;
         fusionTokenCost = tokenCost;
         fusionCostTokenAddress = tokenAddress;
         // Event for parameter update could be generic or specific
    }


    // --- Utility & Interaction ---

    /// @notice Simulates the effect of a potential Flux event on a specific Element without applying it.
    /// Useful for users to see potential property changes.
    /// @param elementId The ID of the Element to simulate on.
    /// @param simulatedOracleValue The oracle value to use for simulation.
    /// @return simulatedPropertyA The potential new value for dynamicPropertyA.
    /// @return simulatedPropertyB The potential new value for dynamicPropertyB.
    /// @return simulatedYieldMultiplier The potential new yield multiplier.
    function probeFluxEffect(uint256 elementId, uint256 simulatedOracleValue) public view onlyElement(elementId) returns (int256 simulatedPropertyA, int256 simulatedPropertyB, uint256 simulatedYieldMultiplier) {
        Element storage element = _elements[elementId];

        // Simulate the same logic as _applySingleElementFlux but without state changes
        uint256 timeElapsedSinceLastFlux = block.timestamp - element.lastFluxTime; // Use current time for simulation

        int256 fluxShiftA = int256((simulatedOracleValue % fluxInfluence) * (timeElapsedSinceLastFlux % 100) / 50);
        int256 fluxShiftB = int256((simulatedOracleValue % fluxInfluence) * (timeElapsedSinceLastFlux % 100) / 50);

        simulatedPropertyA = element.dynamicPropertyA + fluxShiftA;
        simulatedPropertyB = element.dynamicPropertyB + fluxShiftB;

        // Clamp simulated properties
        if (simulatedPropertyA > 1000) simulatedPropertyA = 1000;
        if (simulatedPropertyA < -1000) simulatedPropertyA = -1000;
        if (simulatedPropertyB > 1000) simulatedPropertyB = 1000;
        if (simulatedPropertyB < -1000) simulatedPropertyB = -1000;

        // Calculate simulated yield multiplier
        simulatedYieldMultiplier = uint256(100) + uint256(int256(simulatedPropertyA + simulatedPropertyB) * int256(propertyYieldFactor) / 100);
        if (simulatedYieldMultiplier == 0) simulatedYieldMultiplier = 1;

        return (simulatedPropertyA, simulatedPropertyB, simulatedYieldMultiplier);
    }


    /// @notice Allows applying a "catalyst" token to an asset for a temporary boost.
    /// Burns the specified catalyst token amount from the caller.
    /// @param tokenId The ID of the asset (Element or Fusion).
    /// @param catalystToken The address of the ERC20 token being used as catalyst.
    /// @param amount The amount of catalyst token to burn.
    /// @dev Requires the caller to own the asset and approve token transfer.
    function applyCatalyst(uint256 tokenId, address catalystToken, uint256 amount) public {
        address caller = msg.sender;
         if (ownerOf(tokenId) != caller) revert NotAllowed();
         if (amount == 0) revert InsufficientCatalystAmount();
         if (catalystToken != catalystTokenAddress) revert CatalystTokenMismatch(); // Only configured catalyst token allowed

        // Burn catalyst tokens
        IERC20(catalystToken).safeTransferFrom(caller, address(this), amount);

        // Apply catalyst effect
        AssetType assetType = _assetTypes[tokenId];
        uint256 currentBoostFactor = catalystBoostFactor; // Default from parameters
        uint256 effectEndTime = block.timestamp + catalystDuration; // Default duration

        // Could scale boost/duration based on amount used - complex, keep fixed for now.

        if (assetType == AssetType.Element) {
            Element storage element = _elements[tokenId];
            // If already has a boost, maybe extend or replace? Let's replace for simplicity.
            element.catalystEffect = CatalystEffect(currentBoostFactor, effectEndTime);
            emit CatalystApplied(tokenId, catalystToken, amount, currentBoostFactor, effectEndTime);

        } else if (assetType == AssetType.Fusion) {
            Fusion storage fusion = _fusions[tokenId];
            // If already has a boost, maybe extend or replace? Let's replace for simplicity.
            fusion.catalystEffect = CatalystEffect(currentBoostFactor, effectEndTime);
            emit CatalystApplied(tokenId, catalystToken, amount, currentBoostFactor, effectEndTime);
        } else {
             revert InvalidTokenId(); // Should not happen after ownerOf check
        }
    }

    /// @notice Allows burning Essence tokens to slightly improve or stabilize a dynamic property.
    /// @param tokenId The ID of the asset (Element or Fusion).
    /// @param propertyIndex Index indicating which property to refine (e.g., 0 for A, 1 for B).
    /// @param essenceAmount The amount of Essence tokens to burn for refinement.
    /// @dev Requires the caller to own the asset and approve Essence transfer.
    function refineProperty(uint256 tokenId, uint256 propertyIndex, uint256 essenceAmount) public {
        address caller = msg.sender;
        if (ownerOf(tokenId) != caller) revert NotAllowed();
        if (essenceAmount == 0 || refinementEssencePerPoint == 0) revert NotEnoughEssence(); // Also prevents division by zero

        uint256 pointsToImprove = essenceAmount / refinementEssencePerPoint;
        if (pointsToImprove == 0) revert NotEnoughEssence(); // Ensure enough Essence for at least 1 point

        // Burn Essence tokens
        essenceToken.safeTransferFrom(caller, address(this), essenceAmount);

        AssetType assetType = _assetTypes[tokenId];
        int256 points = int256(pointsToImprove);

        if (assetType == AssetType.Element) {
            Element storage element = _elements[tokenId];
            if (element.status != ElementStatus.Active) revert InvalidTokenId(); // Cannot refine Fused/Dormant Elements

            if (propertyIndex == 0) {
                element.dynamicPropertyA += points;
                 // Optional: Re-clamp or add bounds check
                if (element.dynamicPropertyA > 1000) element.dynamicPropertyA = 1000;
                if (element.dynamicPropertyA < -1000) element.dynamicPropertyA = -1000;
                 emit PropertyRefined(tokenId, propertyIndex, element.dynamicPropertyA);

            } else if (propertyIndex == 1) {
                element.dynamicPropertyB += points;
                 // Optional: Re-clamp or add bounds check
                if (element.dynamicPropertyB > 1000) element.dynamicPropertyB = 1000;
                if (element.dynamicPropertyB < -1000) element.dynamicPropertyB = -1000;
                 emit PropertyRefined(tokenId, propertyIndex, element.dynamicPropertyB);

            } else {
                revert InvalidPropertyIndex();
            }

            // Update yield multiplier after refinement
            element.yieldMultiplier = uint256(100) + uint256(int256(element.dynamicPropertyA + element.dynamicPropertyB) * int256(propertyYieldFactor) / 100);
             if (element.yieldMultiplier == 0) element.yieldMultiplier = 1;

        } else if (assetType == AssetType.Fusion) {
            Fusion storage fusion = _fusions[tokenId];
             if (fusion.status != FusionStatus.Active) revert InvalidTokenId(); // Cannot refine Unfusing Fusions

             if (propertyIndex == 0) {
                fusion.aggregatedPropertyA += points;
                 // Optional: Re-clamp or add bounds check
                if (fusion.aggregatedPropertyA > 1000) fusion.aggregatedPropertyA = 1000;
                if (fusion.aggregatedPropertyA < -1000) fusion.aggregatedPropertyA = -1000;
                 emit PropertyRefined(tokenId, propertyIndex, fusion.aggregatedPropertyA);

             } else if (propertyIndex == 1) {
                fusion.aggregatedPropertyB += points;
                // Optional: Re-clamp or add bounds check
                if (fusion.aggregatedPropertyB > 1000) fusion.aggregatedPropertyB = 1000;
                if (fusion.aggregatedPropertyB < -1000) fusion.aggregatedPropertyB = -1000;
                 emit PropertyRefined(tokenId, propertyIndex, fusion.aggregatedPropertyB);
             }
             else {
                revert InvalidPropertyIndex();
             }

            // Update yield multiplier after refinement
            fusion.yieldMultiplier = uint256(150) + uint256(int256(fusion.aggregatedPropertyA + fusion.aggregatedPropertyB) * int256(propertyYieldFactor) / 100); // Assuming fusion base is 150
             if (fusion.yieldMultiplier == 0) fusion.yieldMultiplier = 1;

        } else {
             revert InvalidTokenId(); // Should not happen after ownerOf check
        }
    }

    /// @notice Gets the current cost parameter for refining a property.
    /// @return The amount of Essence tokens required per 'point' of property improvement.
    function getRefinementCost() public view returns (uint256) {
        return refinementEssencePerPoint;
    }

    /// @notice Gets the current parameters for catalyst effects.
    /// @return catalystToken The address of the catalyst token.
    /// @return boostFactor The yield multiplier factor.
    /// @return duration The duration of the effect in seconds.
    function getCatalystParameters() public view returns (address catalystToken, uint256 boostFactor, uint256 duration) {
        return (catalystTokenAddress, catalystBoostFactor, catalystDuration);
    }


    // --- Admin & Configuration ---

    /// @notice Sets parameters governing the Flux mechanism. Only callable by the contract owner.
    /// @param newFluxInfluence The new scale factor for how much oracleValue affects properties.
    /// @param newMinFluxInterval The new minimum time required between global flux applications.
    function updateFluxParameters(uint256 newFluxInfluence, uint256 newMinFluxInterval) public onlyOwner {
        emit ParameterUpdated("fluxInfluence", fluxInfluence, newFluxInfluence);
        emit ParameterUpdated("minFluxInterval", minFluxInterval, newMinFluxInterval);
        fluxInfluence = newFluxInfluence;
        minFluxInterval = newMinFluxInterval;
    }

    /// @notice Sets parameters governing Essence yield calculation. Only callable by the contract owner.
    /// @param newBaseYieldRate The new base yield per asset per second (scaled).
    /// @param newPropertyYieldFactor The new factor for how much dynamic properties influence yield multiplier.
    function updateYieldParameters(uint256 newBaseYieldRate, uint256 newPropertyYieldFactor) public onlyOwner {
        emit ParameterUpdated("baseYieldRate", baseYieldRate, newBaseYieldRate);
        emit ParameterUpdated("propertyYieldFactor", propertyYieldFactor, newPropertyYieldFactor);
        baseYieldRate = newBaseYieldRate;
        propertyYieldFactor = newPropertyYieldFactor;
    }

    /// @notice Sets parameters governing the unfusion process. Only callable by the contract owner.
    /// @param newUnfusionCooldown The new cooldown period before unfused elements can be claimed.
    /// @param newUnfusionRefundRate The new percentage of ingredients returned on unfusion.
    function setUnfusionParameters(uint256 newUnfusionCooldown, uint256 newUnfusionRefundRate) public onlyOwner {
         if (newUnfusionRefundRate > 100) revert InvalidQuantity();
         emit ParameterUpdated("unfusionCooldown", unfusionCooldown, newUnfusionCooldown);
         emit ParameterUpdated("unfusionRefundRate", unfusionRefundRate, newUnfusionRefundRate);
         unfusionCooldown = newUnfusionCooldown;
         unfusionRefundRate = newUnfusionRefundRate;
    }


    /// @notice Sets the cost parameter for refining properties. Only callable by the contract owner.
    /// @param essencePerPoint The new amount of Essence tokens required per 'point' of property improvement.
    function setRefinementCost(uint256 essencePerPoint) public onlyOwner {
         emit ParameterUpdated("refinementEssencePerPoint", refinementEssencePerPoint, essencePerPoint);
         refinementEssencePerPoint = essencePerPoint;
    }

    /// @notice Sets the parameters for catalyst effects. Only callable by the contract owner.
    /// @param _catalystToken The address of the token to use as catalyst.
    /// @param _boostFactor The yield multiplier boost factor (e.g., 150 for 1.5x).
    /// @param _duration The duration of the boost in seconds.
    function setCatalystParameters(address _catalystToken, uint256 _boostFactor, uint256 _duration) public onlyOwner {
        emit AddressParameterUpdated("catalystTokenAddress", catalystTokenAddress, _catalystToken);
        emit ParameterUpdated("catalystBoostFactor", catalystBoostFactor, _boostFactor);
        emit ParameterUpdated("catalystDuration", catalystDuration, _duration);
        catalystTokenAddress = _catalystToken;
        catalystBoostFactor = _boostFactor;
        catalystDuration = _duration;
    }


    /// @notice Sets the address of the trusted Essence ERC20 token contract. Only callable by the contract owner.
    /// @param _essenceToken The address of the Essence ERC20 token.
    function setEssenceTokenAddress(address _essenceToken) public onlyOwner {
        if (_essenceToken == address(0)) revert InvalidQuantity(); // Use InvalidQuantity for non-zero address requirement
        emit AddressParameterUpdated("essenceToken", address(essenceToken), _essenceToken);
        essenceToken = IERC20(_essenceToken);
    }

    /// @notice Sets the address of the trusted Oracle contract. Only callable by the contract owner.
    /// @param _oracle The address of the Oracle contract.
    function setOracleAddress(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert InvalidQuantity(); // Use InvalidQuantity for non-zero address requirement
        emit AddressParameterUpdated("oracleAddress", oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

    /// @notice Allows the owner to rescue ERC20 tokens accidentally sent to the contract.
    /// Excludes the EssenceToken contract itself.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdrawStuckTokens(address tokenAddress, uint256 amount) public onlyOwner {
        // Prevent withdrawing the core EssenceToken used for yield
        if (tokenAddress == address(essenceToken)) revert NotAllowed();
         if (tokenAddress == address(this)) revert NotAllowed(); // Cannot withdraw ETH with SafeERC20
         if (tokenAddress == address(0)) revert NotAllowed();

        IERC20 stuckToken = IERC20(tokenAddress);
        stuckToken.safeTransfer(owner(), amount);
    }

    /// @notice Returns the contract version string.
    function getVersion() public pure returns (string memory) {
        return _CONTRACT_VERSION;
    }


    // --- Override ERC721 Functions for Custom Logic ---

    /// @inheritdoc ERC721
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When an Element or Fusion is transferred, claim its pending yield first.
        // This prevents yield accumulation while not owned by the primary user.
        // It also resets the yield timer.

        // Check if tokenId is managed by this contract
        if (_assetTypes[tokenId] != AssetType.None) {
            // Only claim yield if it's being transferred *from* a user address (not 0x0 or contract itself)
            // and *to* a user address (not 0x0 or contract itself, unless fusing/unfusing)
            // And ensure the asset is in a state eligible for yield calculation/claiming
            AssetType assetType = _assetTypes[tokenId];
            bool eligible = false;

            if (assetType == AssetType.Element) {
                 Element storage element = _elements[tokenId];
                 if (element.status == ElementStatus.Active) eligible = true;
            } else if (assetType == AssetType.Fusion) {
                 Fusion storage fusion = _fusions[tokenId];
                 if (fusion.status == FusionStatus.Active) eligible = true;
            }

            // Avoid claiming during mint (from == address(0)) or burn (to == address(0))
            // and avoid claiming when transfering to/from the contract itself for fusion/unfusion
            if (eligible && from != address(0) && to != address(0) && from != address(this) && to != address(this)) {
                uint256 pendingYield = calculatePendingEssenceYield(tokenId);
                if (pendingYield > 0) {
                    // Transfer yield to the *sender* before they lose ownership
                    essenceToken.safeTransfer(from, pendingYield);
                    emit YieldClaimed(from, tokenId, pendingYield);
                }
                // Reset last claim time upon transfer, even if yield was 0
                if (assetType == AssetType.Element) _elements[tokenId].lastYieldClaimTime = block.timestamp;
                else if (assetType == AssetType.Fusion) _fusions[tokenId].lastYieldClaimTime = block.timestamp;
            }
        }
    }

     /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // This is where you'd typically return a URL pointing to the NFT metadata JSON.
        // For dynamic NFTs, this metadata should reflect the current on-chain properties.
        // This usually requires an API service ("metadata server") off-chain that queries the contract state
        // for the given tokenId and formats the JSON.
        // Example: return string(abi.encodePacked("https://your-metadata-server.com/api/metadata/", Strings.toString(tokenId)));

        // For this example, we'll return a placeholder or basic info.
        // A real implementation would build a JSON string or return a URL.

        AssetType assetType = _assetTypes[tokenId];
        if (assetType == AssetType.None) revert InvalidTokenId();

        string memory base = super.tokenURI(tokenId); // If base URI is set
        string memory typeString = assetType == AssetType.Element ? "Element" : "Fusion";

        // Example basic JSON structure (simplified)
        // This is NOT a proper implementation, just illustrative
        // A real one would get properties from storage and format JSON.

        string memory propertiesData;
        if (assetType == AssetType.Element) {
            Element memory el = _elements[tokenId];
            propertiesData = string(abi.encodePacked(
                '"status": "', string(abi.encodePacked(uint256(el.status))), '", ',
                '"basePower": ', string(abi.encodePacked(el.basePower)), ', ',
                '"dynamicPropertyA": ', string(abi.encodePacked(el.dynamicPropertyA)), ', ',
                '"dynamicPropertyB": ', string(abi.encodePacked(el.dynamicPropertyB)), ', ',
                '"yieldMultiplier": ', string(abi.encodePacked(el.yieldMultiplier))
            ));
        } else if (assetType == AssetType.Fusion) {
            Fusion memory fu = _fusions[tokenId];
             propertiesData = string(abi.encodePacked(
                '"status": "', string(abi.encodePacked(uint256(fu.status))), '", ',
                '"combinedPower": ', string(abi.encodePacked(fu.combinedPower)), ', ',
                '"aggregatedPropertyA": ', string(abi.encodePacked(fu.aggregatedPropertyA)), ', ',
                '"aggregatedPropertyB": ', string(abi.encodePacked(fu.aggregatedPropertyB)), ', ',
                '"yieldMultiplier": ', string(abi.encodePacked(fu.yieldMultiplier))
            ));
        }

        // Construct a very basic, non-standard representation
        return string(abi.encodePacked(
            '{"name": "', typeString, ' #', string(abi.encodePacked(tokenId)), '", ',
            '"description": "A dynamic Flux Fusion Engine Asset.", ',
            '"attributes": {', propertiesData, '}}'
        ));

        // NOTE: For full compliance and complex metadata, an external service is required.
    }

}
```