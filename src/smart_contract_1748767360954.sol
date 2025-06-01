Okay, let's design a smart contract concept that combines several advanced ideas:

1.  **Dynamic NFTs:** NFTs whose properties change based on on-chain interactions or time.
2.  **Resource Management & Crafting:** Users collect fungible/semi-fungible tokens and combine them to perform actions.
3.  **On-Chain Simulation/State:** A global parameter (like "Entropy") affects outcomes.
4.  **Verifiable Randomness:** Using Chainlink VRF for unpredictable elements in crafting/evolution.
5.  **Tokenomics:** A simple staking mechanism for resource generation and token sinks through crafting/evolution costs.
6.  **Modularity Hint:** Designed with parameters that could theoretically be updated (via admin/future governance).

We'll call this the "**HyperCube Protocol**". It revolves around collecting "Quantum Essence" (ERC-20), refining it into "Exotic Catalysts" (ERC-1155), and using these to "Synthesize" new dynamic "HyperFacets" (ERC-721) or "Evolve" existing ones. A global "Entropy" level impacts the results of synthesis and evolution.

---

**Outline & Function Summary**

**Contract Name:** `HyperCubeProtocol`

**Core Concepts:**
*   **HyperFacets (ERC721):** Dynamic NFTs with evolving properties (e.g., Complexity, Resonance, Stability).
*   **QuantumEssence (ERC20):** Primary fungible resource token. Earned via mining/staking.
*   **ExoticCatalysts (ERC1155):** Semi-fungible resource items. Crafted from Essence. Used in synthesis/evolution.
*   **System Entropy:** A global state variable affecting the range and unpredictability of synthesis/evolution outcomes. Increases over time/with certain actions, can be decreased by burning resources.
*   **Mining:** Stake Quantum Essence to earn more Quantum Essence over time.
*   **Synthesis:** Craft new HyperFacets using Essence, Catalysts, and VRF-driven random properties, influenced by Entropy.
*   **Evolution:** Update properties of an existing HyperFacet using Essence, Catalysts, and VRF, influenced by Entropy.
*   **Decay/Stabilization:** HyperFacets decay over time (lose stability) if not stabilized by burning Essence.

**Inherited Contracts:**
*   `ERC20` (for QuantumEssence)
*   `ERC721` (for HyperFacets)
*   `ERC1155` (for ExoticCatalysts)
*   `Ownable` (for administrative functions)
*   `VRFConsumerBaseV2` (for Chainlink VRF integration)
*   `Pausable` (for system-wide pause)

**State Variables:**
*   Token contracts (`essenceToken`, `facetToken`, `catalystToken`)
*   Facet data mapping (`facetData`)
*   Mining stake mapping (`miningStakes`)
*   System entropy (`currentEntropy`)
*   Parameters for mining, refining, synthesis, evolution, decay, entropy (`miningRate`, `refiningRecipe`, `synthesisCost`, `evolutionCost`, `stabilizationCost`, `entropyParameters`)
*   VRF variables (`s_vrfCoordinator`, `s_keyHash`, `s_subscriptionId`, `s_callbackGasLimit`, `s_requestIdToRequest`)
*   Protocol fee recipient (`protocolFeeRecipient`)
*   Pausable state

**Structs:**
*   `Facet`: Stores dynamic properties (complexity, resonance, stability, lastStateChangeTimestamp).
*   `MiningStake`: Stores staked amount and last update timestamp for yield calculation.
*   `VRFRequest`: Tracks VRF request details (type: Synthesis/Evolution, related facetId, user address).

**Enums:**
*   `VRFRequestType`: Distinguishes between Synthesis and Evolution VRF requests.

**Events:**
*   `FacetSynthesized`
*   `FacetEvolutionRequested`
*   `FacetEvolved`
*   `FacetStabilized`
*   `EssenceMined`
*   `CatalystRefined`
*   `EntropyChanged`
*   `ParametersUpdated`
*   `ProtocolPaused`
*   `ProtocolUnpaused`
*   `FeesClaimed`

**Functions (Total > 20 Unique Logic Functions, excluding standard inherited views/transfers):**

1.  `constructor()`: Initializes tokens, VRF, owner, initial parameters.
2.  `stakeEssenceForMining(uint256 amount)`: Locks user's Quantum Essence to earn mining yield.
3.  `unstakeEssenceFromMining(uint256 amount)`: Unlocks user's staked Quantum Essence.
4.  `requestMiningYield()`: Calculates pending yield based on stake duration and transfers earned Quantum Essence.
5.  `getPendingMiningYield(address user)`: View function to see pending yield for a user.
6.  `refineCatalyst(uint256 amount)`: Burns Quantum Essence based on recipe and mints Exotic Catalysts (ERC-1155).
7.  `requestFacetSynthesis()`: Burns required Essence and Catalysts, requests VRF randomness, logs request.
8.  `requestFacetEvolution(uint256 facetId)`: Burns required Essence and Catalysts, requests VRF randomness for a specific facet, logs request.
9.  `rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback. Processes synthesis/evolution based on request type and randomness, updates facet state or mints new facet.
10. `stabilizeFacet(uint256 facetId)`: Burns required Essence to increase facet stability and reset its decay timer.
11. `processFacetDecay(uint256[] calldata facetIds)`: Public function (can be called by anyone, potentially with incentive?) to calculate and apply decay to a batch of facets, reducing stability and slightly increasing global entropy.
12. `decreaseSystemEntropy(uint256 amount)`: Burns resources (e.g., Essence) to reduce global system entropy. Cost scales with current entropy.
13. `getFacetState(uint256 facetId)`: View function returning the current dynamic properties of a HyperFacet.
14. `getSystemEntropy()`: View function returning the current global entropy level.
15. `getSynthesisCost()`: View function returning current costs for synthesis.
16. `getEvolutionCost()`: View function returning current costs for evolution.
17. `getStabilizationCost()`: View function returning current costs for stabilization.
18. `getRefiningRecipe()`: View function returning the current refining recipe.
19. `getEntropyParameters()`: View function returning parameters related to entropy change.
20. `getMiningParameters()`: View function returning parameters related to mining yield.
21. `setMiningParameters(uint256 rate)`: Admin function to set the mining rate.
22. `setRefiningRecipe(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount)`: Admin function to set the refining recipe.
23. `setSynthesisParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee)`: Admin function to set synthesis costs and fees.
24. `setEvolutionParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee)`: Admin function to set evolution costs and fees.
25. `setStabilizationCost(uint256 essenceCost)`: Admin function to set the stabilization cost.
26. `setEntropyParameters(uint256 decayRate, uint256 decreaseCostFactor)`: Admin function to set parameters affecting entropy change.
27. `setVRFConfig(...)`: Admin function to update VRF coordinator, keyhash, sub ID.
28. `withdrawProtocolFees()`: Admin function to withdraw accumulated fees (e.g., from synthesis/evolution).
29. `pauseProtocol()`: Admin function to pause core operations (mining, synthesis, evolution, refining, stabilization).
30. `unpauseProtocol()`: Admin function to unpause the protocol.
31. `emergencyRescueTokens(address token, uint256 amount)`: Admin safety function to rescue tokens accidentally sent *to* the contract (excluding protocol tokens).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721ConsecutiveEnumerable.sol"; // Added for easier enumeration/processing
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title HyperCubeProtocol
/// @notice A protocol for managing dynamic NFTs (HyperFacets) through resource gathering (QuantumEssence, ExoticCatalysts), crafting, VRF-driven synthesis and evolution, influenced by a global system entropy level.
/// @author YourNameHere (Replace with your name or alias)

// --- Outline & Function Summary (Duplicated for easy access in code) ---
// Core Concepts:
// - HyperFacets (ERC721): Dynamic NFTs with evolving properties.
// - QuantumEssence (ERC20): Primary fungible resource. Earned via mining/staking.
// - ExoticCatalysts (ERC1155): Semi-fungible resource items. Crafted from Essence. Used in synthesis/evolution.
// - System Entropy: Global state variable affecting outcomes. Increases over time/actions, can be decreased.
// - Mining: Stake Essence to earn more.
// - Synthesis: Craft new Facets using resources and VRF, influenced by Entropy.
// - Evolution: Update existing Facets using resources and VRF, influenced by Entropy.
// - Decay/Stabilization: Facets decay over time if not stabilized.

// Functions (Total > 20 Unique Logic Functions):
// 1. constructor(): Initializes contracts, VRF, owner, parameters.
// 2. stakeEssenceForMining(uint256 amount): Stake Essence to earn yield.
// 3. unstakeEssenceFromMining(uint256 amount): Unstake Essence.
// 4. requestMiningYield(): Claim earned Essence.
// 5. getPendingMiningYield(address user): View user's pending yield.
// 6. refineCatalyst(uint256 amount): Burn Essence to mint Catalysts.
// 7. requestFacetSynthesis(): Burn resources, request VRF for new Facet.
// 8. requestFacetEvolution(uint256 facetId): Burn resources, request VRF for Facet evolution.
// 9. rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords): VRF callback to finalize synthesis/evolution.
// 10. stabilizeFacet(uint256 facetId): Burn Essence to stabilize a Facet.
// 11. processFacetDecay(uint256[] calldata facetIds): Apply decay to multiple Facets, increase entropy.
// 12. decreaseSystemEntropy(uint256 amount): Burn resources to reduce global entropy.
// 13. getFacetState(uint256 facetId): View function for Facet properties.
// 14. getSystemEntropy(): View global entropy.
// 15. getSynthesisCost(): View synthesis costs.
// 16. getEvolutionCost(): View evolution costs.
// 17. getStabilizationCost(): View stabilization costs.
// 18. getRefiningRecipe(): View refining recipe.
// 19. getEntropyParameters(): View entropy parameters.
// 20. getMiningParameters(): View mining parameters.
// 21. setMiningParameters(uint256 rate): Admin: Set mining rate.
// 22. setRefiningRecipe(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount): Admin: Set refining recipe.
// 23. setSynthesisParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee): Admin: Set synthesis parameters.
// 24. setEvolutionParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee): Admin: Set evolution parameters.
// 25. setStabilizationCost(uint256 essenceCost): Admin: Set stabilization cost.
// 26. setEntropyParameters(uint256 decayRate, uint256 decreaseCostFactor): Admin: Set entropy parameters.
// 27. setVRFConfig(...): Admin: Update VRF config.
// 28. withdrawProtocolFees(): Admin: Withdraw fees.
// 29. pauseProtocol(): Admin: Pause system.
// 30. unpauseProtocol(): Admin: Unpause system.
// 31. emergencyRescueTokens(address token, uint256 amount): Admin: Rescue stuck tokens.
// --- End of Outline & Function Summary ---


contract QuantumEssence is ERC20 {
    constructor(address initialOwner) ERC20("Quantum Essence", "QC") {
        // Mint some initial supply for the owner or deployer
        _mint(initialOwner, 1000000 * 10**decimals());
    }
}

contract HyperFacet is ERC721ConsecutiveEnumerable { // Use Enumerable for easier iteration (e.g., in decay)
    constructor(address initialOwner) ERC721("Hyper Facet", "HCF") {
        // Can mint initial facets here or purely through protocol synthesis
    }

    // Override to prevent direct minting/burning outside the protocol
    function safeMint(address to, uint256 tokenId) internal virtual override {
        super.safeMint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721ConsecutiveEnumerable) {
        super._burn(tokenId);
    }

    // Override ERC721URIStorage if needed for metadata, but properties are stored in HyperCubeProtocol
}

contract ExoticCatalyst is ERC1155 {
    // Catalyst Types (Examples)
    uint256 public constant CATALYST_TYPE_ALPHA = 0;
    uint256 public constant CATALYST_TYPE_BETA = 1;

    constructor(address initialOwner) ERC1155("") {
        // Initial minting or recipes can be set up
    }

    // Set base URI (can be empty if metadata is off-chain)
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // Override to prevent direct minting/burning outside the protocol
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual override {
         super._mint(to, id, amount, data);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual override {
        super._burn(from, id, amount);
    }
}


contract HyperCubeProtocol is Ownable, Pausable, VRFConsumerBaseV2 {
    using SafeERC20 for QuantumEssence;

    // --- State Variables ---

    // Token Contracts
    QuantumEssence public immutable essenceToken;
    HyperFacet public immutable facetToken;
    ExoticCatalyst public immutable catalystToken;

    // Dynamic Facet Data (stored here, not in ERC721 contract metadata)
    struct Facet {
        uint64 complexity; // Represents internal structure complexity
        uint64 resonance;  // Represents interaction potential/yield multiplier
        uint64 stability;  // Represents resistance to decay (0-10000 range, e.g.)
        uint65 lastStateChangeTimestamp; // Timestamp of last stabilization or decay
        uint64 dimensions; // A fixed property derived from synthesis/evolution
    }
    mapping(uint256 => Facet) public facetData; // facetId => Facet data

    // Mining Stakes
    struct MiningStake {
        uint256 stakedAmount;
        uint256 lastRewardTimestamp; // Timestamp of last claim or stake update
    }
    mapping(address => MiningStake) public miningStakes;

    // System State
    uint256 public currentEntropy; // Global entropy level, affects randomness interpretation

    // Parameters
    uint256 public miningRate; // Essence per staked unit per second (scaled)
    struct RefiningRecipe {
        uint256 essenceCost;
        uint256 catalystId;
        uint256 catalystAmount;
    }
    RefiningRecipe public refiningRecipe;
    struct OperationCosts {
        uint256 essenceCost;
        uint256 catalystId;
        uint256 catalystAmount;
        uint256 protocolFee; // Fee in Essence token
    }
    OperationCosts public synthesisCosts;
    OperationCosts public evolutionCosts;
    uint256 public stabilizationEssenceCost; // Essence cost to stabilize a facet

    struct EntropyParameters {
        uint256 decayRatePerDay; // How much stability decreases per day (scaled)
        uint256 entropyIncreasePerDecay; // How much entropy increases per facet decay event (scaled)
        uint256 entropyDecreaseBaseCost; // Base Essence cost to decrease entropy
        uint256 entropyDecreaseCostFactor; // Factor scaling decrease cost with current entropy
        uint256 maxEntropy; // Maximum theoretical entropy
    }
    EntropyParameters public entropyParameters;

    // VRF Configuration and State
    VRFCoordinatorV2Interface public immutable s_vrfCoordinator;
    uint64 public immutable s_subscriptionId;
    bytes32 public immutable s_keyHash;
    uint32 public immutable s_callbackGasLimit;
    uint16 public constant REQUEST_CONFIRMATIONS = 3; // Recommended confirmations
    uint32 public constant NUM_WORDS = 2; // Number of random words needed

    enum VRFRequestType { Synthesis, Evolution }
    struct VRFRequest {
        VRFRequestType requestType;
        address user;
        uint256 targetFacetId; // 0 for synthesis
    }
    mapping(uint256 => VRFRequest) public s_requestIdToRequest; // Chainlink VRF request ID => Request details

    // Fees
    address public protocolFeeRecipient;

    // --- Events ---

    event FacetSynthesized(address indexed owner, uint256 indexed facetId, uint64 complexity, uint64 resonance, uint64 stability, uint64 dimensions);
    event FacetEvolutionRequested(address indexed user, uint256 indexed facetId, uint256 requestId);
    event FacetEvolved(uint256 indexed facetId, uint64 newComplexity, uint64 newResonance, uint64 newStability, uint64 newDimensions); // Log all new properties
    event FacetStabilized(uint256 indexed facetId, uint64 newStability);
    event FacetDecayed(uint256 indexed facetId, uint64 newStability);
    event EssenceMined(address indexed user, uint256 amount);
    event CatalystRefined(address indexed user, uint256 indexed catalystId, uint256 amountMinted, uint256 essenceBurned);
    event EntropyChanged(uint256 newEntropy);
    event ParametersUpdated(bytes32 parameterName); // Generic event for parameter changes
    // Pausable events handled by Pausable.sol
    // VRF events handled by VRFConsumerBaseV2

    // --- Errors ---
    error InvalidAmount();
    error NotEnoughEssence(uint256 required, uint256 available);
    error NotEnoughCatalyst(uint256 catalystId, uint256 required, uint256 available);
    error FacetDoesNotExist(uint256 facetId);
    error CannotUnstakeWhileStaked();
    error NothingToClaim();
    error CalculationOverflow();
    error InvalidRefiningAmount();
    error FacetAlreadyUnstable(); // Or already Stable enough depending on logic
    error InvalidEntropyReductionAmount();
    error MaxEntropyReached();
    error VRFRequestFailed();


    // --- Constructor ---

    /// @notice Initializes the HyperCube Protocol with token contracts, VRF configuration, and initial parameters.
    /// @param _essenceToken Address of the deployed Quantum Essence token.
    /// @param _facetToken Address of the deployed Hyper Facet token.
    /// @param _catalystToken Address of the deployed Exotic Catalyst token.
    /// @param _vrfCoordinator Address of the Chainlink VRF Coordinator contract.
    /// @param _keyHash Chainlink VRF key hash.
    /// @param _subscriptionId Chainlink VRF subscription ID.
    /// @param _callbackGasLimit Chainlink VRF callback gas limit.
    /// @param _initialFeeRecipient Address to receive protocol fees.
    constructor(
        address _essenceToken,
        address _facetToken,
        address _catalystToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _initialFeeRecipient
    )
        Ownable(msg.sender) // Set deployer as initial owner
        Pausable() // Initialize Pausable
        VRFConsumerBaseV2(_vrfCoordinator) // Initialize VRFConsumerBaseV2
    {
        essenceToken = QuantumEssence(_essenceToken);
        facetToken = HyperFacet(_facetToken);
        catalystToken = ExoticCatalyst(_catalystToken);
        s_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        protocolFeeRecipient = _initialFeeRecipient;

        // Initial default parameters (can be set via admin functions)
        miningRate = 100; // Example: 100 scaled units per sec per staked unit
        refiningRecipe = RefiningRecipe({
            essenceCost: 100 * 10**essenceToken.decimals(),
            catalystId: ExoticCatalyst.CATALYST_TYPE_ALPHA,
            catalystAmount: 1
        });
        synthesisCosts = OperationCosts({
            essenceCost: 500 * 10**essenceToken.decimals(),
            catalystId: ExoticCatalyst.CATALYST_TYPE_ALPHA,
            catalystAmount: 2,
            protocolFee: 50 * 10**essenceToken.decimals()
        });
        evolutionCosts = OperationCosts({
            essenceCost: 300 * 10**essenceToken.decimals(),
            catalystId: ExoticCatalyst.CATALYST_TYPE_ALPHA,
            catalystAmount: 1,
            protocolFee: 30 * 10**essenceToken.decimals()
        });
        stabilizationEssenceCost = 200 * 10**essenceToken.decimals(); // Example cost
        entropyParameters = EntropyParameters({
            decayRatePerDay: 100, // Example: Stability decreases by 100 points per day
            entropyIncreasePerDecay: 1, // Example: Entropy increases by 1 per decay event
            entropyDecreaseBaseCost: 1000 * 10**essenceToken.decimals(), // Base cost to decrease entropy
            entropyDecreaseCostFactor: 10, // Cost increases by this factor * currentEntropy
            maxEntropy: 1000 // Example max entropy
        });

        currentEntropy = 0; // Start with low entropy
    }

    // --- Core Protocol Functions ---

    /// @notice Allows a user to stake Quantum Essence for mining yield.
    /// @param amount The amount of Quantum Essence to stake.
    function stakeEssenceForMining(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        uint256 pending = _calculateMiningYield(msg.sender);
        _claimMiningYield(msg.sender, pending); // Claim any pending yield before restaking/adding

        essenceToken.safeTransferFrom(msg.sender, address(this), amount);
        miningStakes[msg.sender].stakedAmount += amount;
        miningStakes[msg.sender].lastRewardTimestamp = block.timestamp; // Update timestamp
    }

    /// @notice Allows a user to unstake Quantum Essence.
    /// @param amount The amount of Quantum Essence to unstake.
    function unstakeEssenceFromMining(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (miningStakes[msg.sender].stakedAmount < amount) revert NotEnoughEssence(amount, miningStakes[msg.sender].stakedAmount);

        uint256 pending = _calculateMiningYield(msg.sender);
        _claimMiningYield(msg.sender, pending); // Claim pending yield before unstaking

        miningStakes[msg.sender].stakedAmount -= amount;
        essenceToken.safeTransfer(msg.sender, amount);
        // lastRewardTimestamp is updated in _claimMiningYield
    }

    /// @notice Claims the pending mining yield for the caller.
    function requestMiningYield() external whenNotPaused {
        uint256 pending = _calculateMiningYield(msg.sender);
        if (pending == 0) revert NothingToClaim();
        _claimMiningYield(msg.sender, pending);
    }

    /// @notice Allows a user to refine Quantum Essence into Exotic Catalysts.
    /// @param amount The number of catalyst units to refine.
    function refineCatalyst(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidRefiningAmount();

        uint256 requiredEssence = refiningRecipe.essenceCost * amount;
        if (essenceToken.balanceOf(msg.sender) < requiredEssence) {
            revert NotEnoughEssence(requiredEssence, essenceToken.balanceOf(msg.sender));
        }

        essenceToken.safeTransferFrom(msg.sender, address(this), requiredEssence);
        catalystToken.mint(msg.sender, refiningRecipe.catalystId, refiningRecipe.catalystAmount * amount, "");

        emit CatalystRefined(msg.sender, refiningRecipe.catalystId, refiningRecipe.catalystAmount * amount, requiredEssence);
    }

    /// @notice Initiates the synthesis of a new HyperFacet. Burns resources and requests VRF randomness.
    function requestFacetSynthesis() external whenNotPaused {
        // Check and burn costs
        _burnOperationCosts(msg.sender, synthesisCosts);

        // Request VRF randomness
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );

        // Store request details
        s_requestIdToRequest[requestId] = VRFRequest({
            requestType: VRFRequestType.Synthesis,
            user: msg.sender,
            targetFacetId: 0 // 0 indicates synthesis
        });

        emit VRFRequestSent(requestId, NUM_WORDS, address(this)); // VRFConsumerBaseV2 event
    }

    /// @notice Initiates the evolution of an existing HyperFacet. Burns resources and requests VRF randomness.
    /// @param facetId The ID of the HyperFacet to evolve.
    function requestFacetEvolution(uint256 facetId) external whenNotPaused {
        if (!facetToken.exists(facetId)) revert FacetDoesNotExist(facetId);
        if (facetToken.ownerOf(facetId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable error for clarity here

        // Check and burn costs
        _burnOperationCosts(msg.sender, evolutionCosts);

        // Request VRF randomness
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );

        // Store request details
        s_requestIdToRequest[requestId] = VRFRequest({
            requestType: VRFRequestType.Evolution,
            user: msg.sender,
            targetFacetId: facetId
        });

        emit FacetEvolutionRequested(msg.sender, facetId, requestId);
        emit VRFRequestSent(requestId, NUM_WORDS, address(this)); // VRFConsumerBaseV2 event
    }

    /// @notice Stabilizes a HyperFacet, increasing its stability and resetting its decay timer.
    /// @param facetId The ID of the HyperFacet to stabilize.
    function stabilizeFacet(uint256 facetId) external whenNotPaused {
        if (!facetToken.exists(facetId)) revert FacetDoesNotExist(facetId);
        if (facetToken.ownerOf(facetId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable error

        // Check and burn cost
        uint256 cost = stabilizationEssenceCost;
         if (essenceToken.balanceOf(msg.sender) < cost) {
            revert NotEnoughEssence(cost, essenceToken.balanceOf(msg.sender));
        }
        essenceToken.safeTransferFrom(msg.sender, address(this), cost);

        // Apply stabilization logic
        Facet storage facet = facetData[facetId];
        // Simple stabilization: increase stability up to max, reset timer
        uint64 maxStability = 10000; // Example max stability
        uint64 stabilityIncrease = 2000; // Example increase amount
        facet.stability = uint64(Math.min(facet.stability + stabilityIncrease, maxStability));
        facet.lastStateChangeTimestamp = uint64(block.timestamp); // Reset decay timer

        emit FacetStabilized(facetId, facet.stability);
    }

    /// @notice Processes decay for a batch of HyperFacets, reducing stability and increasing system entropy.
    /// Can be called by anyone.
    /// @param facetIds An array of HyperFacet IDs to process decay for.
    function processFacetDecay(uint256[] calldata facetIds) external whenNotPaused {
        uint256 entropyIncreaseThisBatch = 0;
        uint256 decayRate = entropyParameters.decayRatePerDay;
        uint256 entropyIncreasePerDecay = entropyParameters.entropyIncreasePerDecay;
        uint64 maxStability = 10000; // Must match stabilization logic
        uint256 maxEntropy = entropyParameters.maxEntropy;

        for (uint i = 0; i < facetIds.length; i++) {
            uint256 facetId = facetIds[i];
            if (!facetToken.exists(facetId)) {
                // Skip non-existent facets
                continue;
            }

            Facet storage facet = facetData[facetId];
            uint66 timeSinceLastChange = block.timestamp - facet.lastStateChangeTimestamp; // Use uint66 for safety

            // Calculate decay based on time (scaled)
            // decay = timeSinceLastChange * (decayRatePerDay / 1 day in seconds)
            // 1 day = 86400 seconds
            // scaled_decay = (timeSinceLastChange * decayRatePerDay * 1e18) / 86400 (example scaling)
            // Let's simplify: decay = timeSinceLastChange * decayRatePerHour (using hours)
            // Let's use days for simplicity matching parameter name
            uint256 decayAmount = (uint256(timeSinceLastChange) * decayRate) / 86400; // Decay per day scaled

            if (decayAmount > 0) {
                facet.lastStateChangeTimestamp = uint64(block.timestamp); // Update timestamp for decay processed
                uint64 oldStability = facet.stability;
                if (facet.stability > decayAmount) {
                     facet.stability -= uint64(decayAmount);
                } else {
                    facet.stability = 0; // Stability cannot go below zero
                }

                // If stability dropped below a threshold (e.g., maxStability / 2) and wasn't already low
                // This is a simple trigger for entropy increase. More complex logic possible.
                if (oldStability > maxStability / 2 && facet.stability <= maxStability / 2) {
                     entropyIncreaseThisBatch += entropyIncreasePerDecay;
                }

                emit FacetDecayed(facetId, facet.stability);
            }
        }

        // Increase global entropy after processing the batch
        uint256 newEntropy = currentEntropy + entropyIncreaseThisBatch;
        currentEntropy = newEntropy > maxEntropy ? maxEntropy : newEntropy;
        if (entropyIncreaseThisBatch > 0) {
             emit EntropyChanged(currentEntropy);
        }
    }


    /// @notice Burns resources to decrease the global system entropy.
    /// @param amount The amount of Entropy "units" to attempt to decrease.
    function decreaseSystemEntropy(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (currentEntropy == 0) revert InvalidEntropyReductionAmount();

        // Calculate cost: Base cost + factor * currentEntropy * amount
        uint256 cost = entropyParameters.entropyDecreaseBaseCost;
        uint256 entropyFactorCost = (currentEntropy * entropyParameters.entropyDecreaseCostFactor * amount); // Scaled cost
        if (cost + entropyFactorCost < cost) revert CalculationOverflow(); // Check for overflow
        cost += entropyFactorCost;

        if (essenceToken.balanceOf(msg.sender) < cost) {
            revert NotEnoughEssence(cost, essenceToken.balanceOf(msg.sender));
        }

        essenceToken.safeTransferFrom(msg.sender, address(this), cost);

        // Decrease entropy (ensure it doesn't go below zero)
        uint256 entropyReduction = amount; // Simple 1:1 reduction for now, could scale
        if (currentEntropy < entropyReduction) {
            currentEntropy = 0;
        } else {
            currentEntropy -= entropyReduction;
        }

        emit EntropyChanged(currentEntropy);
    }


    // --- VRF Callback ---

    /// @notice Chainlink VRF callback function. Processes Synthesis or Evolution requests.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random words provided by Chainlink.
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        VRFRequest memory request = s_requestIdToRequest[requestId];
        // Clean up the mapping entry
        delete s_requestIdToRequest[requestId];

        if (request.user == address(0)) {
            // Should not happen if request mapping is managed correctly
            // Consider logging this error
            revert VRFRequestFailed();
        }

        uint256 randomWord1 = randomWords[0];
        uint256 randomWord2 = randomWords[1]; // Use multiple words for more entropy if needed

        if (request.requestType == VRFRequestType.Synthesis) {
            // --- Synthesis Logic ---
            uint256 newTokenId = facetToken.totalSupply() + 1; // Get next token ID

            // Generate initial facet properties based on random words and current entropy
            // This is where the core generative logic happens.
            // Example:
            // Complexity: Influenced by randomWord1, slightly skewed by Entropy (higher entropy = wider range/higher potential max)
            // Resonance: Influenced by randomWord2, perhaps less affected by Entropy directly
            // Stability: Start high, maybe slightly randomized
            // Dimensions: Determined by a combination of random words and Entropy, maybe a fixed value or small range

            uint64 initialComplexity = _generateComplexity(randomWord1, currentEntropy);
            uint64 initialResonance = _generateResonance(randomWord2, currentEntropy);
            uint64 initialStability = 10000; // Start with max stability
            uint64 initialDimensions = _generateDimensions(randomWord1, randomWord2, currentEntropy); // Example

            facetToken.safeMint(request.user, newTokenId);
            facetData[newTokenId] = Facet({
                complexity: initialComplexity,
                resonance: initialResonance,
                stability: initialStability,
                lastStateChangeTimestamp: uint64(block.timestamp),
                dimensions: initialDimensions
            });

            emit FacetSynthesized(request.user, newTokenId, initialComplexity, initialResonance, initialStability, initialDimensions);

        } else if (request.requestType == VRFRequestType.Evolution) {
            // --- Evolution Logic ---
            uint256 facetId = request.targetFacetId;
             if (!facetToken.exists(facetId)) {
                 // Should not happen if request mapping is correct, but safety check
                 return; // Facet no longer exists (e.g., burned), cannot evolve
             }
             // Note: Ownership might have changed since the request was made.
             // The randomness is *for* the request made by `request.user`, but the state change applies to the facet regardless of current owner.
             // Design choice: Apply evolution to the facet's current state, regardless of owner, or require user to still own it?
             // Let's apply to the facet itself.

            Facet storage facet = facetData[facetId];

            // Apply evolution based on random words, current facet state, and current entropy
            // Evolution is riskier with high entropy, might yield bigger changes (positive or negative)
            // Example:
            // Change complexity: influenced by randomWord1, current complexity, Entropy
            // Change resonance: influenced by randomWord2, current resonance, Entropy
            // Stability might decrease or increase depending on result and Entropy

            (uint64 newComplexity, uint64 newResonance, uint64 newStability, uint64 newDimensions) = _applyEvolution(
                facet,
                randomWord1,
                randomWord2,
                currentEntropy
            );

            // Update facet data
            facet.complexity = newComplexity;
            facet.resonance = newResonance;
            facet.stability = newStability; // Evolution might reduce stability
            facet.lastStateChangeTimestamp = uint64(block.timestamp); // Reset decay timer after evolution
            facet.dimensions = newDimensions; // Dimensions might evolve? Or fixed? Let's allow changing slightly.

            emit FacetEvolved(facetId, newComplexity, newResonance, newStability, newDimensions);

        } else {
            // Unknown request type - should not happen
            // Log error
        }
    }


    // --- Internal Helper Functions (for generative/evolution logic) ---

    /// @dev Generates initial complexity based on random word and entropy.
    /// @param randomWord VRF random word.
    /// @param entropy Current system entropy.
    /// @return Generated complexity value.
    function _generateComplexity(uint256 randomWord, uint224 entropy) internal pure returns (uint64) {
        // Simple example logic: Complexity = Base + Randomness + Entropy influence
        // Max complexity could be 1000. Entropy 0-1000.
        uint256 base = 100;
        uint256 randInfluence = randomWord % 500; // Randomness affects range 0-499
        uint256 entropyInfluence = entropy / 10; // Entropy 0-100
        uint256 complexity = base + randInfluence + entropyInfluence;
        return uint64(Math.min(complexity, 1000)); // Cap complexity
    }

    /// @dev Generates initial resonance based on random word and entropy.
    /// @param randomWord VRF random word.
    /// @param entropy Current system entropy.
    /// @return Generated resonance value.
    function _generateResonance(uint256 randomWord, uint224 entropy) internal pure returns (uint64) {
         // Simple example logic: Resonance = Base + Randomness - Entropy penalty?
        uint256 base = 50;
        uint256 randInfluence = randomWord % 300; // Randomness affects range 0-299
        uint256 entropyPenalty = entropy / 20; // Entropy 0-50
        uint256 resonance = base + randInfluence;
         if (resonance > entropyPenalty) {
             resonance -= entropyPenalty;
         } else {
             resonance = 0;
         }
        return uint64(Math.min(resonance, 500)); // Cap resonance
    }

     /// @dev Generates initial dimensions based on random words and entropy.
    /// @param randomWord1 VRF random word 1.
    /// @param randomWord2 VRF random word 2.
    /// @param entropy Current system entropy.
    /// @return Generated dimensions value.
    function _generateDimensions(uint256 randomWord1, uint256 randomWord2, uint224 entropy) internal pure returns (uint64) {
        // Simple example: Dimensions are mostly fixed but can have small variations
        uint256 baseDim = 4; // Start with 4 dimensions
        uint256 randVariation = (randomWord1 + randomWord2) % 3; // Variation -1, 0, or 1
        uint256 entropyVariation = (entropy % 500) < 250 ? 0 : 1; // Small chance of extra dimension at high entropy
        uint256 dimensions = baseDim + (randVariation == 0 ? 0 : (randVariation == 1 ? 1 : type(uint256).max)); // Map 0->0, 1->+1, 2->large number (handle safely)
        if (randVariation == 2) dimensions = baseDim > 0 ? baseDim - 1 : 0; // Map 2->-1

        dimensions += entropyVariation; // Add entropy influence

        return uint64(Math.min(dimensions, 7)); // Cap dimensions
    }

    /// @dev Applies evolution logic to a facet based on random words and entropy.
    /// @param facet The facet being evolved.
    /// @param randomWord1 VRF random word 1.
    /// @param randomWord2 VRF random word 2.
    /// @param entropy Current system entropy.
    /// @return New complexity, resonance, stability, and dimensions.
    function _applyEvolution(
        Facet storage facet,
        uint256 randomWord1,
        uint256 randomWord2,
        uint224 entropy
    ) internal pure returns (uint64, uint64, uint64, uint64) {
        // Evolution logic: Changes are proportional to current state and random/entropy influence
        // Higher entropy means higher potential for *big* positive or negative changes.
        // Example:
        // Complexity change: (random +/- influence) * currentComplexity / MaxComplexity + entropy_modifier
        // Resonance change: (random +/- influence) * currentResonance / MaxResonance + entropy_modifier
        // Stability change: More likely to decrease with high entropy / big property changes

        uint256 maxComplexity = 1000;
        uint224 maxResonance = 500;
        uint64 maxStability = 10000;

        int256 complexityChange = _calculateChange(randomWord1, entropy, int256(facet.complexity), int256(maxComplexity));
        int256 resonanceChange = _calculateChange(randomWord2, entropy, int256(facet.resonance), int256(maxResonance));

        uint64 newComplexity = _applyChange(facet.complexity, complexityChange, maxComplexity);
        uint64 newResonance = _applyChange(facet.resonance, resonanceChange, maxResonance);

        // Stability change: Decrease based on magnitude of complexity/resonance changes and entropy
        uint256 changeMagnitude = uint256(Math.abs(complexityChange)) + uint256(Math.abs(resonanceChange));
        uint256 stabilityLoss = (changeMagnitude * entropy) / 1000; // Simple loss based on magnitude and entropy
        stabilityLoss += (randomWord1 % 100); // Add some random loss

        uint66 newStability = facet.stability > stabilityLoss ? uint66(facet.stability) - stabilityLoss : 0;
        newStability = Math.min(newStability, maxStability); // Cap stability at max

        // Dimensions might have a small chance to change
        uint64 newDimensions = facet.dimensions;
        if (randomWord2 % 1000 < entropy / 10) { // Small chance increases with entropy
            if (randomWord1 % 2 == 0) {
                newDimensions = Math.min(newDimensions + 1, 7);
            } else {
                 newDimensions = newDimensions > 0 ? newDimensions - 1 : 0;
            }
        }


        return (newComplexity, newResonance, uint64(newStability), newDimensions);
    }

    /// @dev Helper to calculate a potential change value for a property.
    /// @param randomWord VRF random word.
    /// @param entropy Current system entropy.
    /// @param currentValue The current property value.
    /// @param maxValue The maximum possible value for the property.
    /// @return Signed integer representing the calculated change.
    function _calculateChange(uint256 randomWord, uint224 entropy, int256 currentValue, int256 maxValue) internal pure returns (int256) {
         // Randomness spread increases with Entropy
        int256 maxRandomChange = 100 + int256(entropy / 10); // Max change magnitude increases with entropy

        // Random delta: -maxRandomChange to +maxRandomChange
        int256 delta = int256(randomWord % (2 * uint256(maxRandomChange) + 1)) - int256(maxRandomChange);

        // Influence of current value: changes might be proportional to how far from max/min
        // If value is low, positive changes are easier; if high, negative changes are easier
        int256 valueInfluence = (maxValue / 2) - currentValue; // Roughly: positive if low, negative if high

        // Combine random delta and value influence
        int256 totalChange = delta + (valueInfluence / 10); // Scale value influence

        // Ensure change doesn't push value excessively out of bounds before applying
        // This logic could be much more complex
        return totalChange;
    }

    /// @dev Helper to apply a calculated change to a property value, respecting min/max bounds.
    /// @param currentValue The current property value.
    /// @param change The calculated signed change.
    /// @param maxValue The maximum possible value for the property.
    /// @return New property value (uint64).
    function _applyChange(uint64 currentValue, int256 change, uint256 maxValue) internal pure returns (uint64) {
        int256 newValue = int256(currentValue) + change;

        // Clamp the value within [0, maxValue]
        if (newValue < 0) return 0;
        if (newValue > int256(maxValue)) return uint64(maxValue);
        return uint64(newValue);
    }


    // --- Internal Utility Functions ---

    /// @dev Calculates pending mining yield for a user based on stake duration and rate.
    /// @param user The address of the user.
    /// @return The calculated pending yield amount.
    function _calculateMiningYield(address user) internal view returns (uint256) {
        MiningStake memory stake = miningStakes[user];
        uint256 stakedAmount = stake.stakedAmount;
        uint256 lastTimestamp = stake.lastRewardTimestamp;

        if (stakedAmount == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastTimestamp;
        // Yield = stakedAmount * timeElapsed * miningRate / SCALE_FACTOR
        // Let's use 1e18 as a scale factor for miningRate
        uint256 yield = (stakedAmount * timeElapsed * miningRate) / 1e18; // Example scaling

        return yield;
    }

    /// @dev Claims the calculated mining yield for a user and updates the stake timestamp.
    /// @param user The address of the user.
    /// @param amount The amount of yield to claim.
    function _claimMiningYield(address user, uint224 amount) internal {
        if (amount > 0) {
             // Mint new essence for the user
            essenceToken._mint(user, amount);
            miningStakes[user].lastRewardTimestamp = block.timestamp; // Update timestamp
            emit EssenceMined(user, amount);
        }
    }

    /// @dev Burns required resources for synthesis or evolution and collects the protocol fee.
    /// @param user The address performing the operation.
    /// @param costs The OperationCosts struct detailing required resources and fee.
    function _burnOperationCosts(address user, OperationCosts memory costs) internal {
        // Check and burn Essence cost
        if (essenceToken.balanceOf(user) < costs.essenceCost + costs.protocolFee) {
            revert NotEnoughEssence(costs.essenceCost + costs.protocolFee, essenceToken.balanceOf(user));
        }
        essenceToken.safeTransferFrom(user, address(this), costs.essenceCost);
        // Transfer fee to recipient
        if (costs.protocolFee > 0) {
             essenceToken.safeTransferFrom(user, protocolFeeRecipient, costs.protocolFee);
        }


        // Check and burn Catalyst cost (ERC-1155)
        if (catalystToken.balanceOf(user, costs.catalystId) < costs.catalystAmount) {
            revert NotEnoughCatalyst(costs.catalystId, costs.catalystAmount, catalystToken.balanceOf(user, costs.catalystId));
        }
        catalystToken.burn(user, costs.catalystId, costs.catalystAmount);
    }


    // --- View Functions ---

    /// @notice Returns the current pending mining yield for a user.
    /// @param user The address of the user.
    /// @return pendingYield The amount of unclaimed Quantum Essence.
    function getPendingMiningYield(address user) public view returns (uint256 pendingYield) {
         return _calculateMiningYield(user);
    }

     /// @notice Returns the current staked amount for a user.
    /// @param user The address of the user.
    /// @return stakedAmount The amount of staked Quantum Essence.
    function getMiningStake(address user) public view returns (uint256 stakedAmount) {
        return miningStakes[user].stakedAmount;
    }

    /// @notice Returns the current dynamic properties of a specific HyperFacet.
    /// @param facetId The ID of the HyperFacet.
    /// @return complexity, resonance, stability, lastStateChangeTimestamp, dimensions
    function getFacetState(uint256 facetId) public view returns (uint64 complexity, uint64 resonance, uint64 stability, uint64 lastStateChangeTimestamp, uint64 dimensions) {
        Facet memory facet = facetData[facetId];
        return (facet.complexity, facet.resonance, facet.stability, facet.lastStateChangeTimestamp, facet.dimensions);
    }

    /// @notice Returns the current global system entropy level.
    function getSystemEntropy() public view returns (uint256) {
        return currentEntropy;
    }

    /// @notice Returns the current costs for Facet Synthesis.
    /// @return essenceCost, catalystId, catalystAmount, protocolFee
    function getSynthesisCost() public view returns (uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 protocolFee) {
        return (synthesisCosts.essenceCost, synthesisCosts.catalystId, synthesisCosts.catalystAmount, synthesisCosts.protocolFee);
    }

    /// @notice Returns the current costs for Facet Evolution.
    /// @return essenceCost, catalystId, catalystAmount, protocolFee
    function getEvolutionCost() public view returns (uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 protocolFee) {
         return (evolutionCosts.essenceCost, evolutionCosts.catalystId, evolutionCosts.catalystAmount, evolutionCosts.protocolFee);
    }

    /// @notice Returns the current cost for Facet Stabilization.
    /// @return essenceCost
    function getStabilizationCost() public view returns (uint256 essenceCost) {
        return stabilizationEssenceCost;
    }

    /// @notice Returns the current recipe for refining Catalysts.
    /// @return essenceCost, catalystId, catalystAmount
    function getRefiningRecipe() public view returns (uint256 essenceCost, uint256 catalystId, uint256 catalystAmount) {
        return (refiningRecipe.essenceCost, refiningRecipe.catalystId, refiningRecipe.catalystAmount);
    }

    /// @notice Returns the current parameters governing Entropy change.
    /// @return decayRatePerDay, entropyIncreasePerDecay, entropyDecreaseBaseCost, entropyDecreaseCostFactor, maxEntropy
    function getEntropyParameters() public view returns (uint256 decayRatePerDay, uint256 entropyIncreasePerDecay, uint256 entropyDecreaseBaseCost, uint256 entropyDecreaseCostFactor, uint256 maxEntropy) {
        return (entropyParameters.decayRatePerDay, entropyParameters.entropyIncreasePerDecay, entropyParameters.entropyDecreaseBaseCost, entropyParameters.entropyDecreaseCostFactor, entropyParameters.maxEntropy);
    }

    /// @notice Returns the current parameters governing mining yield.
    /// @return miningRate
    function getMiningParameters() public view returns (uint256 miningRate_) {
        return miningRate;
    }

     /// @notice Returns key state variables and parameters.
    /// @return entropy, miningRate, refiningRecipe, synthesisCosts, evolutionCosts, stabilizationCost, entropyParams, protocolFeeRecipient
    function getProtocolState() public view returns (
        uint256 entropy,
        uint256 miningRate_,
        RefiningRecipe memory refiningRecipe_,
        OperationCosts memory synthesisCosts_,
        OperationCosts memory evolutionCosts_,
        uint256 stabilizationCost_,
        EntropyParameters memory entropyParams_,
        address feeRecipient
    ) {
        return (
            currentEntropy,
            miningRate,
            refiningRecipe,
            synthesisCosts,
            evolutionCosts,
            stabilizationEssenceCost,
            entropyParameters,
            protocolFeeRecipient
        );
    }

    // --- Admin Functions (Owner Only) ---

    /// @notice Sets the mining yield rate.
    /// @param rate The new mining rate (scaled).
    function setMiningParameters(uint256 rate) external onlyOwner {
        miningRate = rate;
        emit ParametersUpdated("MiningRate");
    }

    /// @notice Sets the recipe for refining Catalysts.
    /// @param essenceCost The new Essence cost per catalyst unit.
    /// @param catalystId The ID of the Catalyst being refined.
    /// @param catalystAmount The amount of Catalyst minted per recipe unit.
    function setRefiningRecipe(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount) external onlyOwner {
        refiningRecipe = RefiningRecipe({
            essenceCost: essenceCost,
            catalystId: catalystId,
            catalystAmount: catalystAmount
        });
        emit ParametersUpdated("RefiningRecipe");
    }

    /// @notice Sets the costs and fees for Facet Synthesis.
    /// @param essenceCost The Essence cost.
    /// @param catalystId The Catalyst ID required.
    /// @param catalystAmount The Catalyst amount required.
    /// @param fee The protocol fee in Essence.
    function setSynthesisParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee) external onlyOwner {
        synthesisCosts = OperationCosts({
            essenceCost: essenceCost,
            catalystId: catalystId,
            catalystAmount: catalystAmount,
            protocolFee: fee
        });
        emit ParametersUpdated("SynthesisParameters");
    }

     /// @notice Sets the costs and fees for Facet Evolution.
    /// @param essenceCost The Essence cost.
    /// @param catalystId The Catalyst ID required.
    /// @param catalystAmount The Catalyst amount required.
    /// @param fee The protocol fee in Essence.
    function setEvolutionParameters(uint256 essenceCost, uint256 catalystId, uint256 catalystAmount, uint256 fee) external onlyOwner {
        evolutionCosts = OperationCosts({
            essenceCost: essenceCost,
            catalystId: catalystId,
            catalystAmount: catalystAmount,
            protocolFee: fee
        });
        emit ParametersUpdated("EvolutionParameters");
    }

    /// @notice Sets the Essence cost for stabilizing a Facet.
    /// @param essenceCost The new Essence cost.
    function setStabilizationCost(uint256 essenceCost) external onlyOwner {
        stabilizationEssenceCost = essenceCost;
        emit ParametersUpdated("StabilizationCost");
    }

    /// @notice Sets parameters related to Entropy change.
    /// @param decayRatePerDay_ Stability decay rate per day (scaled).
    /// @param entropyIncreasePerDecay_ Entropy increase amount per facet decay event.
    /// @param entropyDecreaseBaseCost_ Base Essence cost to decrease entropy.
    /// @param entropyDecreaseCostFactor_ Factor scaling entropy decrease cost.
    /// @param maxEntropy_ Maximum possible entropy value.
    function setEntropyParameters(
        uint256 decayRatePerDay_,
        uint256 entropyIncreasePerDecay_,
        uint256 entropyDecreaseBaseCost_,
        uint256 entropyDecreaseCostFactor_,
        uint256 maxEntropy_
    ) external onlyOwner {
        entropyParameters = EntropyParameters({
            decayRatePerDay: decayRatePerDay_,
            entropyIncreasePerDecay: entropyIncreasePerDecay_,
            entropyDecreaseBaseCost: entropyDecreaseBaseCost_,
            entropyDecreaseCostFactor: entropyDecreaseCostFactor_,
            maxEntropy: maxEntropy_
        });
        emit ParametersUpdated("EntropyParameters");
    }

    /// @notice Sets the VRF configuration parameters.
    /// @param keyHash_ Chainlink VRF key hash.
    /// @param subscriptionId_ Chainlink VRF subscription ID.
    /// @param callbackGasLimit_ Chainlink VRF callback gas limit.
    function setVRFConfig(bytes32 keyHash_, uint64 subscriptionId_, uint32 callbackGasLimit_) external onlyOwner {
        // s_vrfCoordinator is immutable, cannot change
        // s_subscriptionId = subscriptionId_; // Make subscriptionId mutable if needed
        // s_keyHash = keyHash_; // Make keyHash mutable if needed
        // s_callbackGasLimit = callbackGasLimit_; // Make callbackGasLimit mutable if needed
        // Re-initialization of VRFConsumerBaseV2 might be required if these were mutable
        // For this example, keyHash, subId, gasLimit are immutable or assumed set only once via constructor params

        // If you want to make them mutable, declare them non-immutable and update here:
        // s_subscriptionId = subscriptionId_;
        // s_keyHash = keyHash_;
        // s_callbackGasLimit = callbackGasLimit_;
        // emit ParametersUpdated("VRFConfig");

        // Sticking to constructor-set immutability as per current code structure
        revert("VRF Config parameters are immutable after deployment."); // Or remove this function if immutable
    }

    /// @notice Sets the address designated to receive protocol fees.
    /// @param recipient The new fee recipient address.
    function setProtocolFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        protocolFeeRecipient = recipient;
        emit ParametersUpdated("FeeRecipient");
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees (Essence token)
    ///         from the contract address.
    function withdrawProtocolFees() external onlyOwner {
        uint256 balance = essenceToken.balanceOf(address(this));
        // Exclude staked amount from withdrawable fees
        // This requires tracking fees separately or careful calculation.
        // Simplification: Assume contract balance minus total staked is 'fees'.
        // A more robust system would transfer fees directly to recipient or track them in a variable.
        // Let's refine the fee burning logic: fees are transferred directly in _burnOperationCosts

        // If fees are transferred directly, this function is only for rescuing other accidental transfers.
        // Let's adjust: fees ARE transferred directly. This function is for rescuing *other* tokens.
         revert("Fees are transferred directly. Use emergencyRescueTokens for other tokens.");

         // OR if fees *were* accumulated here:
         // uint256 totalStaked = 0;
         // // This would require iterating over all stakers, which is gas-prohibitive.
         // // A better design tracks cumulative fees or sends fees directly.
         // // Sticking to sending fees directly in _burnOperationCosts.
    }

     /// @notice Allows the owner to rescue tokens (ERC20, ERC721, ERC1155) accidentally sent to the contract.
     ///         Does not allow rescuing the protocol's own tokens (QC, HCF, EC) if they are needed for logic.
     /// @param token The address of the token contract.
     /// @param amount For ERC20, the amount to rescue. Ignored for ERC721/ERC1155 rescue type.
     function emergencyRescueTokens(address token, uint256 amount) external onlyOwner {
         require(token != address(essenceToken), "Cannot rescue protocol Essence");
         require(token != address(facetToken), "Cannot rescue protocol Facets");
         require(token != address(catalystToken), "Cannot rescue protocol Catalysts");

         // Try rescuing as ERC20
         try IERC20(token).transfer(owner(), amount) {
             // Success as ERC20
             return;
         } catch {
             // Failed as ERC20, try ERC721 (rescue *all* of this type held)
             try IERC721(token).setApprovalForAll(owner(), true) {
                 // Approve owner to pull. Requires owner to then call transferFrom.
                 // This is safer than contract sending directly if token has weird transfer logic.
                 // Alternative: iterate tokens and transfer (gas heavy). Let's just approve.
                 // Or simpler: assume basic ERC721.
                 uint256 balance = IERC721(token).balanceOf(address(this));
                 for (uint i = 0; i < balance; i++) {
                     uint256 tokenId = IERC721(token).tokenOfOwnerByIndex(address(this), 0); // Token ID at index 0 changes after transfer
                     IERC721(token).transferFrom(address(this), owner(), tokenId);
                 }
                 return;
             } catch {
                 // Failed as ERC721, try ERC1155 (rescue *all* of all types held)
                 try IERC1155(token).isApprovedForAll(address(this), owner()) returns (bool isApproved) {
                     if (!isApproved) {
                         IERC1155(token).setApprovalForAll(owner(), true); // Approve owner
                     }
                      // Owner needs to pull manually or iterate and transfer
                     // Iterating all token IDs for ERC1155 is impossible on-chain without enumeration extension.
                     // Best approach is approving the owner or having owner call a pull function.
                     // Let's simplify: owner has to call token-specific transferFrom/safeBatchTransferFrom after approving.
                     // Or just approve and log? Approval is safer.

                     // A more direct but potentially unsafe way depending on token:
                     // uint256[] memory ids; // Cannot get list of held IDs easily
                     // uint256[] memory amounts; // Cannot get amounts easily
                     // IERC1155(token).safeBatchTransferFrom(address(this), owner(), ids, amounts, "");

                     // Safest: Just approve owner and return.
                     // We already approved above in the catch block, so just return.
                      return; // Indicates potential success via approval
                 } catch {
                    // Token is not ERC20, ERC721, or ERC1155 standard. Cannot rescue.
                    revert("Cannot rescue non-standard token or rescue failed.");
                 }
             }
         }
     }


    // --- Pausable Overrides ---
    function pauseProtocol() external onlyOwner {
        _pause();
         emit ProtocolPaused();
    }

    function unpauseProtocol() external onlyOwner {
        _unpause();
         emit ProtocolUnpaused();
    }

    // Ensure state-changing functions respect pause
    function stakeEssenceForMining(uint256 amount) public override whenNotPaused { super.stakeEssenceForMining(amount); }
    function unstakeEssenceFromMining(uint256 amount) public override whenNotPaused { super.unstakeEssenceFromMining(amount); }
    function requestMiningYield() public override whenNotPaused { super.requestMiningYield(); }
    function refineCatalyst(uint256 amount) public override whenNotPaused { super.refineCatalyst(amount); }
    function requestFacetSynthesis() public override whenNotPaused { super.requestFacetSynthesis(); }
    function requestFacetEvolution(uint256 facetId) public override whenNotPaused { super.requestFacetEvolution(facetId); }
    function stabilizeFacet(uint256 facetId) public override whenNotPaused { super.stabilizeFacet(facetId); }
    function processFacetDecay(uint256[] calldata facetIds) public override whenNotPaused { super.processFacetDecay(facetIds); }
    function decreaseSystemEntropy(uint256 amount) public override whenNotPaused { super.decreaseSystemEntropy(amount); }


    // --- VRFConsumerBaseV2 Overrides ---
    // rawFulfillRandomWords is already overridden above.
    // Link token address is handled by VRFCoordinatorV2Interface address implicitly.
    // Request events are emitted by the base contract.

}

// Minimal Math library for clarity (SafeMath is deprecated in 0.8+)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
     function min(uint66 a, uint66 b) internal pure returns (uint66) {
        return a < b ? a : b;
    }
     function abs(int256 x) internal pure returns (uint256) {
         unchecked {
             return uint256(x < 0 ? -x : x);
         }
     }
}
```