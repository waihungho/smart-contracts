Okay, this is an exciting challenge! Let's design a smart contract called "ChronoForge" that deals with time-sensitive, evolving NFTs (let's call them "Artifacts") and a complementary fungible token ("Essence") used for their manipulation and evolution. The core concept revolves around *temporal states*, *mutation entropy*, *prophecy alignment*, and *dimension shifting*.

We'll avoid direct duplication of common DeFi (Lending, AMM), PFP NFT collections, or generic DAO structures. Instead, we'll focus on the *life cycle and transformation* of digital assets with advanced mechanics.

---

## ChronoForge Smart Contract

**Concept:** ChronoForge is a protocol that enables the creation, evolution, and manipulation of unique, time-sensitive Non-Fungible Tokens (NFTs) called "Artifacts," powered by a fungible token called "Essence." Artifacts aren't static; they possess evolutionary stages, can undergo "transmutation," accrue "temporal aura," be influenced by external "prophecies," and even undergo "dimension shifts."

**Advanced Concepts & Creative Functions:**

1.  **Temporal States & Evolution:** Artifacts have `evolutionStage` and `genesisTimestamp`. Their properties or ability to evolve can be time-gated.
2.  **Transmutation Recipes:** Users can combine Essence and/or other Artifacts to "transmute" an existing Artifact into a new, higher-stage, or modified one, based on predefined recipes.
3.  **Mutation Entropy:** A mechanism to introduce controlled randomness into an Artifact's properties, costing Essence.
4.  **Temporal Aura & Harvesting:** Artifacts can generate passive "Essence" over time, which their owner can claim. This creates a "staking-like" utility for NFTs.
5.  **Prophecy Alignment (Oracle Integration Concept):** An Artifact's future evolution or properties can be influenced by external, verifiable data (simulated oracle for this example). This can unlock new stages or abilities.
6.  **Temporal Locking:** Ability to freeze an Artifact's current state, preventing further automatic evolution or decay (if decay was implemented).
7.  **Dimension Shifting:** A destructive process where an Artifact is "burned" (sent to a null address) in exchange for a random, potentially rarer, Artifact or a significant Essence refund. This introduces a "gambit" mechanic.
8.  **Provenance & History Tracking:** Each Artifact maintains a log of its significant transformations.
9.  **Dynamic Rarity Score:** A score calculated based on an Artifact's stage, mutations, and history.

---

### Outline

1.  **Interfaces:** Definitions for ERC-20 and ERC-721 to interact with external token contracts.
2.  **Error Handling:** Custom errors for clarity and gas efficiency.
3.  **Events:** To log significant actions on-chain.
4.  **Structs:**
    *   `ArtifactDetails`: Comprehensive data structure for each Artifact.
    *   `TransmutationRecipe`: Defines inputs and outputs for crafting.
5.  **State Variables:** Core contract configurations and mappings.
6.  **Modifiers:** Access control and state management.
7.  **Constructor:** Initializes contract dependencies.
8.  **Core ChronoForge Logic:**
    *   **Artifact Genesis & Management:** Functions for initial minting and basic queries.
    *   **Artifact Evolution & Transmutation:** The core mechanics for transforming Artifacts.
    *   **Temporal Aura & Harvesting:** Passive Essence generation.
    *   **Mutation & Entropy:** Introducing randomness.
    *   **Temporal State Control:** Locking/unlocking evolution.
    *   **Prophecy Integration:** Simulating external data influence.
    *   **Dimension Shifting:** Destructive transformation.
    *   **Recipe Management:** Admin functions for defining transmutation rules.
    *   **Admin & Utility:** Owner-only functions for contract management.
9.  **Internal Helper Functions:** Reusable logic.

---

### Function Summary (25+ Functions)

**I. Core Setup & Interfaces:**

1.  `constructor(address _essenceTokenAddress, address _artifactTokenAddress)`: Initializes the contract with addresses of the Essence (ERC-20) and Artifact (ERC-721) tokens.
2.  `setEssenceToken(address _essenceTokenAddress)`: (Admin) Updates the Essence ERC-20 token address.
3.  `setArtifactToken(address _artifactTokenAddress)`: (Admin) Updates the Artifact ERC-721 token address.
4.  `setOracleAddress(address _oracleAddress)`: (Admin) Sets the address allowed to call prophecy alignment functions.
5.  `pauseChronoForge()`: (Admin) Pauses certain core operations for maintenance or emergency.
6.  `unpauseChronoForge()`: (Admin) Unpauses the contract.
7.  `withdrawTreasuryFunds(address _to, uint256 _amount)`: (Admin) Allows the owner to withdraw accumulated Essence from the contract.

**II. Artifact Genesis & Management:**

8.  `initiateArtifactGenesis(address _to, uint256 _rarityScore)`: (Admin) Mints a new base Artifact NFT to a specified address, setting its initial rarity and genesis timestamp.
9.  `getArtifactDetails(uint256 _tokenId)`: Returns all stored details for a given Artifact ID.
10. `getArtifactHistory(uint256 _tokenId)`: Returns the historical log of transformations for an Artifact.

**III. Artifact Evolution & Transmutation:**

11. `transmuteArtifact(uint256 _targetArtifactId, uint256 _recipeId, uint256[] calldata _inputArtifactIds)`: The core forging function. Allows a user to transform a `_targetArtifactId` by consuming `_inputArtifactIds` and `Essence` based on a predefined `_recipeId`, creating a new (or evolved) Artifact.
12. `ascendArtifactStage(uint256 _tokenId, uint256 _essenceCost)`: Allows an Artifact to ascend to the next evolutionary stage if specific time conditions are met and Essence is paid. This is a linear progression.

**IV. Temporal Aura & Harvesting:**

13. `activateTemporalAura(uint256 _tokenId, uint256 _essenceActivationFee)`: Activates passive Essence generation for an Artifact, costing an initial fee.
14. `harvestTemporalEssence(uint256 _tokenId)`: Allows the owner to claim accumulated Essence generated by their Artifact's temporal aura.
15. `deactivateTemporalAura(uint256 _tokenId)`: Deactivates passive Essence generation for an Artifact.

**V. Mutation & Entropy:**

16. `applyEntropyMutation(uint256 _tokenId, uint256 _essenceCost)`: Applies a controlled random mutation to an Artifact's properties, potentially changing its `mutationEntropy` and `rarityScore`, costing Essence.

**VI. Temporal State Control:**

17. `lockTemporalState(uint256 _tokenId)`: Freezes an Artifact's current evolutionary stage and prevents further aura generation or mutations.
18. `unlockTemporalState(uint256 _tokenId)`: Unlocks a previously locked Artifact, allowing it to continue its temporal processes.

**VII. Prophecy Integration (Oracle-like):**

19. `alignCosmicProphecy(uint256 _tokenId, bytes32 _externalDataHash, uint256 _alignedStageUnlock)`: (Only Oracle) Allows an authorized oracle to "align" an Artifact with external data, potentially unlocking a new evolutionary stage or unique properties.

**VIII. Dimension Shifting:**

20. `initiateDimensionShift(uint256 _tokenId)`: Burns an Artifact (transfers to address(0)) in exchange for a chance to receive a different, potentially rarer, Artifact, or a significant refund of Essence. The outcome is determined by internal logic and the burned Artifact's properties.
21. `setDimensionShiftOutcomes(uint256 _rarityThreshold, uint256 _newArtifactChance, uint256 _essenceRefundPercentage)`: (Admin) Configures the probabilities and outcomes for dimension shifts.

**IX. Recipe Management:**

22. `registerTransmutationRecipe(uint256 _recipeId, uint256 _targetStageMin, uint256 _essenceCost, uint256[] calldata _requiredInputArtifactStages, uint256 _outputStage, uint256 _outputRarityBonus)`: (Admin) Defines a new transmutation recipe.
23. `deregisterTransmutationRecipe(uint256 _recipeId)`: (Admin) Removes an existing transmutation recipe.
24. `getTransmutationRecipe(uint256 _recipeId)`: Views the details of a specific transmutation recipe.
25. `getAvailableRecipesForArtifact(uint256 _tokenId)`: Returns a list of recipe IDs applicable to a given Artifact's current state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs

// --- ChronoForge Smart Contract ---
//
// Concept: ChronoForge is a protocol that enables the creation, evolution,
// and manipulation of unique, time-sensitive Non-Fungible Tokens (NFTs)
// called "Artifacts," powered by a fungible token called "Essence."
// Artifacts aren't static; they possess evolutionary stages, can undergo
// "transmutation," accrue "temporal aura," be influenced by external
// "prophecies," and even undergo "dimension shifts."
//
// Advanced Concepts & Creative Functions:
// 1. Temporal States & Evolution: Artifacts have `evolutionStage` and `genesisTimestamp`.
//    Their properties or ability to evolve can be time-gated.
// 2. Transmutation Recipes: Users can combine Essence and/or other Artifacts
//    to "transmute" an existing Artifact into a new, higher-stage, or modified one.
// 3. Mutation Entropy: A mechanism to introduce controlled randomness into an
//    Artifact's properties, costing Essence.
// 4. Temporal Aura & Harvesting: Artifacts can generate passive "Essence" over time.
// 5. Prophecy Alignment (Oracle Integration Concept): An Artifact's future evolution
//    or properties can be influenced by external, verifiable data.
// 6. Temporal Locking: Ability to freeze an Artifact's current state.
// 7. Dimension Shifting: A destructive process where an Artifact is "burned"
//    in exchange for a random, potentially rarer, Artifact or a significant Essence refund.
// 8. Provenance & History Tracking: Each Artifact maintains a log of its significant transformations.
// 9. Dynamic Rarity Score: A score calculated based on an Artifact's stage, mutations, and history.
//
// --- Function Summary (25+ Functions) ---
//
// I. Core Setup & Interfaces:
//  1. constructor(address _essenceTokenAddress, address _artifactTokenAddress)
//  2. setEssenceToken(address _essenceTokenAddress)
//  3. setArtifactToken(address _artifactTokenAddress)
//  4. setOracleAddress(address _oracleAddress)
//  5. pauseChronoForge()
//  6. unpauseChronoForge()
//  7. withdrawTreasuryFunds(address _to, uint256 _amount)
//
// II. Artifact Genesis & Management:
//  8. initiateArtifactGenesis(address _to, uint256 _rarityScore)
//  9. getArtifactDetails(uint256 _tokenId)
// 10. getArtifactHistory(uint256 _tokenId)
//
// III. Artifact Evolution & Transmutation:
// 11. transmuteArtifact(uint256 _targetArtifactId, uint256 _recipeId, uint256[] calldata _inputArtifactIds)
// 12. ascendArtifactStage(uint256 _tokenId, uint256 _essenceCost)
//
// IV. Temporal Aura & Harvesting:
// 13. activateTemporalAura(uint256 _tokenId, uint256 _essenceActivationFee)
// 14. harvestTemporalEssence(uint256 _tokenId)
// 15. deactivateTemporalAura(uint256 _tokenId)
//
// V. Mutation & Entropy:
// 16. applyEntropyMutation(uint256 _tokenId, uint256 _essenceCost)
//
// VI. Temporal State Control:
// 17. lockTemporalState(uint256 _tokenId)
// 18. unlockTemporalState(uint256 _tokenId)
//
// VII. Prophecy Integration (Oracle-like):
// 19. alignCosmicProphecy(uint256 _tokenId, bytes32 _externalDataHash, uint256 _alignedStageUnlock)
//
// VIII. Dimension Shifting:
// 20. initiateDimensionShift(uint256 _tokenId)
// 21. setDimensionShiftOutcomes(uint256 _rarityThreshold, uint256 _newArtifactChance, uint256 _essenceRefundPercentage)
//
// IX. Recipe Management:
// 22. registerTransmutationRecipe(uint256 _recipeId, uint256 _targetStageMin, uint256 _essenceCost, uint256[] calldata _requiredInputArtifactStages, uint256 _outputStage, uint256 _outputRarityBonus)
// 23. deregisterTransmutationRecipe(uint256 _recipeId)
// 24. getTransmutationRecipe(uint256 _recipeId)
// 25. getAvailableRecipesForArtifact(uint256 _tokenId)


interface IChronoEssence is IERC20 {}
interface IChronoArtifact is IERC721 {}

contract ChronoForge is Ownable, Pausable, ReentrancyGuard, ERC721Holder {

    IChronoEssence public essenceToken;
    IChronoArtifact public artifactToken;

    address public oracleAddress; // Address authorized to submit prophecy alignments

    uint256 private _artifactCounter; // Counter for new artifact IDs

    // Struct to hold comprehensive details of an Artifact
    struct ArtifactDetails {
        uint256 genesisTimestamp;
        uint256 lastTransmutationTimestamp;
        uint256 evolutionStage; // 0 = primordial, 1 = nascent, etc.
        uint256 mutationEntropy; // Value representing accumulated random mutations
        uint256 rarityScore; // Dynamic score based on stage, mutations, history
        uint256 lastAuraHarvestTimestamp;
        bool isAuraActive;
        bool isTemporalLocked; // If true, cannot ascend, mutate, or generate aura
        uint256 auraAccruedEssence; // Essence generated but not yet harvested
        string[] historyLog; // Short log of major transformations
    }

    // Struct for defining transmutation recipes
    struct TransmutationRecipe {
        bool exists; // To check if recipe exists in mapping
        uint256 targetStageMin; // Minimum stage of the target artifact for this recipe to apply
        uint256 essenceCost; // Essence required for the transmutation
        uint256[] requiredInputArtifactStages; // Stages of artifacts needed as inputs (e.g., [1, 2] means one stage 1 and one stage 2 artifact)
        uint256 outputStage; // The stage of the resulting artifact
        uint256 outputRarityBonus; // Rarity bonus applied to the output artifact
        string recipeName;
    }

    // Struct for dimension shift outcomes
    struct DimensionShiftOutcome {
        uint256 rarityThreshold; // Min rarity for potential new artifact
        uint256 newArtifactChanceBasisPoints; // Chance (e.g., 500 = 5%) to mint new artifact
        uint256 essenceRefundPercentageBasisPoints; // % of initial mint cost refunded
    }

    // Mappings
    mapping(uint256 => ArtifactDetails) public artifactData;
    mapping(uint256 => TransmutationRecipe) public transmutationRecipes;
    mapping(address => uint256) public essenceAuraRatePerSecond; // How much essence an address's artifacts generate collectively per second

    // Dimension shift configuration
    DimensionShiftOutcome public dimensionShiftConfig;

    // --- Events ---
    event EssenceTokenSet(address indexed newAddress);
    event ArtifactTokenSet(address indexed newAddress);
    event OracleAddressSet(address indexed newAddress);
    event ArtifactGenesis(uint256 indexed tokenId, address indexed owner, uint256 rarityScore, uint256 evolutionStage);
    event ArtifactTransmuted(uint256 indexed targetArtifactId, uint256 indexed newArtifactId, uint256 recipeId);
    event ArtifactStageAscended(uint256 indexed tokenId, uint256 newStage);
    event TemporalAuraActivated(uint256 indexed tokenId, address indexed owner, uint256 activationFee);
    event TemporalEssenceHarvested(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event TemporalAuraDeactivated(uint256 indexed tokenId);
    event MutationApplied(uint256 indexed tokenId, uint256 newEntropy, uint256 newRarity);
    event TemporalStateLocked(uint256 indexed tokenId);
    event TemporalStateUnlocked(uint256 indexed tokenId);
    event CosmicProphecyAligned(uint256 indexed tokenId, bytes32 externalDataHash, uint256 newStage);
    event DimensionShiftInitiated(uint256 indexed tokenId, address indexed originalOwner, uint256 newArtifactId, uint256 essenceRefunded);
    event TransmutationRecipeRegistered(uint256 indexed recipeId, string recipeName, uint256 outputStage);
    event TransmutationRecipeDeregistered(uint256 indexed recipeId);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---
    error InvalidAddress();
    error NotEnoughEssence();
    error ArtifactNotFound();
    error NotArtifactOwner();
    error ArtifactNotApprovedForTransfer();
    error TransmutationFailed();
    error InvalidRecipe();
    error InsufficientArtifactStage();
    error InputArtifactMismatch();
    error AuraNotActive();
    error TemporalLocked();
    error TemporalUnlocked();
    error InvalidOracleAddress();
    error RandomnessFailed();
    error TransferFailed();
    error EmptyHistoryLog();
    error OnlyZeroAddressAllowed(); // For burning artifacts
    error TooManyRecipes(); // Limit on recipes for performance or storage
    error RecipeNotFound();

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert InvalidOracleAddress();
        }
        _;
    }

    modifier NotTemporalLocked(uint256 _tokenId) {
        if (artifactData[_tokenId].isTemporalLocked) {
            revert TemporalLocked();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _artifactTokenAddress) Ownable(msg.sender) Pausable(msg.sender) {
        if (_essenceTokenAddress == address(0) || _artifactTokenAddress == address(0)) {
            revert InvalidAddress();
        }
        essenceToken = IChronoEssence(_essenceTokenAddress);
        artifactToken = IChronoArtifact(_artifactTokenAddress);
        oracleAddress = owner(); // Owner is initial oracle

        // Initial dimension shift config: 50% chance for new artifact if rarity > 500, 25% essence refund
        dimensionShiftConfig = DimensionShiftOutcome({
            rarityThreshold: 500,
            newArtifactChanceBasisPoints: 5000, // 50%
            essenceRefundPercentageBasisPoints: 2500 // 25%
        });
    }

    // --- I. Core Setup & Interfaces ---

    /**
     * @notice Sets the address of the Essence ERC-20 token contract.
     * @dev Only callable by the contract owner.
     * @param _essenceTokenAddress The new address for the Essence token.
     */
    function setEssenceToken(address _essenceTokenAddress) external onlyOwner {
        if (_essenceTokenAddress == address(0)) {
            revert InvalidAddress();
        }
        essenceToken = IChronoEssence(_essenceTokenAddress);
        emit EssenceTokenSet(_essenceTokenAddress);
    }

    /**
     * @notice Sets the address of the Artifact ERC-721 token contract.
     * @dev Only callable by the contract owner.
     * @param _artifactTokenAddress The new address for the Artifact token.
     */
    function setArtifactToken(address _artifactTokenAddress) external onlyOwner {
        if (_artifactTokenAddress == address(0)) {
            revert InvalidAddress();
        }
        artifactToken = IChronoArtifact(_artifactTokenAddress);
        emit ArtifactTokenSet(_artifactTokenAddress);
    }

    /**
     * @notice Sets the address authorized to call prophecy alignment functions.
     * @dev Only callable by the contract owner.
     * @param _oracleAddress The new address for the oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) {
            revert InvalidAddress();
        }
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @notice Pauses certain core operations of the contract.
     * @dev Only callable by the contract owner. Prevents functions marked with `whenNotPaused` from being executed.
     */
    function pauseChronoForge() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing previously paused operations to resume.
     * @dev Only callable by the contract owner.
     */
    function unpauseChronoForge() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated Essence from the contract.
     * @dev This is for treasury management.
     * @param _to The address to send the Essence to.
     * @param _amount The amount of Essence to withdraw.
     */
    function withdrawTreasuryFunds(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_to == address(0)) {
            revert InvalidAddress();
        }
        _safeTransferEssence(address(this), _to, _amount);
        emit FundsWithdrawn(_to, _amount);
    }

    // --- II. Artifact Genesis & Management ---

    /**
     * @notice Mints a new base Artifact NFT and initializes its ChronoForge details.
     * @dev Only callable by the contract owner. This is the initial creation of an Artifact.
     * @param _to The address to mint the Artifact to.
     * @param _rarityScore The initial rarity score of the new Artifact.
     */
    function initiateArtifactGenesis(address _to, uint256 _rarityScore) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
        if (_to == address(0)) {
            revert InvalidAddress();
        }
        uint256 newTokenId = _artifactCounter;
        _artifactCounter++;

        artifactToken.mint(_to, newTokenId);

        artifactData[newTokenId] = ArtifactDetails({
            genesisTimestamp: block.timestamp,
            lastTransmutationTimestamp: block.timestamp,
            evolutionStage: 0, // Primordial stage
            mutationEntropy: 0,
            rarityScore: _rarityScore,
            lastAuraHarvestTimestamp: block.timestamp,
            isAuraActive: false,
            isTemporalLocked: false,
            auraAccruedEssence: 0,
            historyLog: new string[](0)
        });
        artifactData[newTokenId].historyLog.push("Genesis");

        emit ArtifactGenesis(newTokenId, _to, _rarityScore, 0);
        return newTokenId;
    }

    /**
     * @notice Retrieves all stored details for a given Artifact ID.
     * @param _tokenId The ID of the Artifact.
     * @return ArtifactDetails struct containing all relevant data.
     */
    function getArtifactDetails(uint256 _tokenId) public view returns (ArtifactDetails memory) {
        if (artifactData[_tokenId].genesisTimestamp == 0) { // Check if artifact exists by checking genesisTimestamp
            revert ArtifactNotFound();
        }
        return artifactData[_tokenId];
    }

    /**
     * @notice Retrieves the history log of transformations for an Artifact.
     * @param _tokenId The ID of the Artifact.
     * @return An array of strings representing the history log.
     */
    function getArtifactHistory(uint256 _tokenId) public view returns (string[] memory) {
        if (artifactData[_tokenId].genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (artifactData[_tokenId].historyLog.length == 0) {
            revert EmptyHistoryLog();
        }
        return artifactData[_tokenId].historyLog;
    }

    // --- III. Artifact Evolution & Transmutation ---

    /**
     * @notice Performs a transmutation of a target Artifact using Essence and optional input Artifacts based on a recipe.
     * @dev The target Artifact and input Artifacts must be owned by msg.sender and approved to this contract.
     * @param _targetArtifactId The ID of the Artifact to be transmuted.
     * @param _recipeId The ID of the transmutation recipe to use.
     * @param _inputArtifactIds An array of IDs of additional Artifacts required by the recipe.
     */
    function transmuteArtifact(
        uint256 _targetArtifactId,
        uint256 _recipeId,
        uint256[] calldata _inputArtifactIds
    ) external whenNotPaused nonReentrant NotTemporalLocked(_targetArtifactId) {
        // Validate target artifact
        if (artifactToken.ownerOf(_targetArtifactId) != msg.sender) {
            revert NotArtifactOwner();
        }
        if (artifactToken.getApproved(_targetArtifactId) != address(this) && !artifactToken.isApprovedForAll(msg.sender, address(this))) {
            revert ArtifactNotApprovedForTransfer();
        }
        ArtifactDetails storage targetArtifact = artifactData[_targetArtifactId];
        if (targetArtifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }

        // Validate recipe
        TransmutationRecipe storage recipe = transmutationRecipes[_recipeId];
        if (!recipe.exists) {
            revert InvalidRecipe();
        }
        if (targetArtifact.evolutionStage < recipe.targetStageMin) {
            revert InsufficientArtifactStage();
        }

        // Validate input artifacts and transfer them to this contract (burn them effectively)
        if (recipe.requiredInputArtifactStages.length != _inputArtifactIds.length) {
            revert InputArtifactMismatch();
        }
        for (uint256 i = 0; i < _inputArtifactIds.length; i++) {
            uint256 inputId = _inputArtifactIds[i];
            if (artifactToken.ownerOf(inputId) != msg.sender) {
                revert NotArtifactOwner();
            }
            if (artifactToken.getApproved(inputId) != address(this) && !artifactToken.isApprovedForAll(msg.sender, address(this))) {
                revert ArtifactNotApprovedForTransfer();
            }
            if (artifactData[inputId].evolutionStage != recipe.requiredInputArtifactStages[i]) {
                revert InputArtifactMismatch();
            }
            // Transfer input artifact to this contract (effectively burning it by sending to a managed null address)
            artifactToken.safeTransferFrom(msg.sender, address(this), inputId);
        }

        // Pay Essence cost
        _safeTransferEssence(msg.sender, address(this), recipe.essenceCost);

        // Perform transmutation: Update target artifact's properties
        targetArtifact.evolutionStage = recipe.outputStage;
        targetArtifact.rarityScore += recipe.outputRarityBonus;
        targetArtifact.lastTransmutationTimestamp = block.timestamp;
        targetArtifact.historyLog.push(string.concat("Transmuted (Recipe: ", recipe.recipeName, ")"));

        // If the artifact was active or had accrued essence, reset aura
        targetArtifact.isAuraActive = false;
        targetArtifact.auraAccruedEssence = 0;
        targetArtifact.lastAuraHarvestTimestamp = block.timestamp; // Reset timestamp

        emit ArtifactTransmuted(_targetArtifactId, _targetArtifactId, _recipeId); // Note: targetArtifactId is also the newArtifactId here as it's modified in place
    }

    /**
     * @notice Allows an Artifact to ascend to the next evolutionary stage if time conditions are met.
     * @dev Requires the Artifact to be owned by msg.sender and essence to be paid.
     * @param _tokenId The ID of the Artifact to ascend.
     * @param _essenceCost The Essence required for this stage ascension.
     */
    function ascendArtifactStage(uint256 _tokenId, uint256 _essenceCost) external whenNotPaused nonReentrant NotTemporalLocked(_tokenId) {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }

        // Example condition: Can only ascend after 30 days from last transmutation for current stage
        uint256 requiredTimeElapsed = (artifact.evolutionStage + 1) * 30 days; // Simple scaling
        if (block.timestamp < artifact.lastTransmutationTimestamp + requiredTimeElapsed) {
            revert InsufficientArtifactStage(); // Or a specific error like NotEnoughTimeElapsed()
        }

        _safeTransferEssence(msg.sender, address(this), _essenceCost);

        artifact.evolutionStage++;
        artifact.lastTransmutationTimestamp = block.timestamp;
        artifact.rarityScore += 50; // Small rarity bonus for natural ascension
        artifact.historyLog.push(string.concat("Ascended to Stage ", Strings.toString(artifact.evolutionStage)));

        emit ArtifactStageAscended(_tokenId, artifact.evolutionStage);
    }

    // --- IV. Temporal Aura & Harvesting ---

    /**
     * @notice Activates passive Essence generation for an Artifact.
     * @dev Requires the Artifact to be owned by msg.sender and an activation fee to be paid.
     * @param _tokenId The ID of the Artifact to activate aura for.
     * @param _essenceActivationFee The Essence fee to activate the aura.
     */
    function activateTemporalAura(uint256 _tokenId, uint256 _essenceActivationFee) external whenNotPaused nonReentrant NotTemporalLocked(_tokenId) {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (artifact.isAuraActive) {
            // Already active, just harvest current essence and update timestamp
            _calculateAccruedEssence(_tokenId);
        }

        _safeTransferEssence(msg.sender, address(this), _essenceActivationFee);

        artifact.isAuraActive = true;
        artifact.lastAuraHarvestTimestamp = block.timestamp; // Reset for new accumulation
        artifact.historyLog.push("Temporal Aura Activated");

        emit TemporalAuraActivated(_tokenId, msg.sender, _essenceActivationFee);
    }

    /**
     * @notice Allows the owner to claim accumulated Essence generated by their Artifact's temporal aura.
     * @param _tokenId The ID of the Artifact to harvest from.
     */
    function harvestTemporalEssence(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (!artifact.isAuraActive) {
            revert AuraNotActive();
        }

        _calculateAccruedEssence(_tokenId); // Update accrued essence

        uint256 amountToTransfer = artifact.auraAccruedEssence;
        if (amountToTransfer == 0) {
            // No essence accrued yet or already harvested.
            return;
        }

        artifact.auraAccruedEssence = 0;
        artifact.lastAuraHarvestTimestamp = block.timestamp; // Reset timestamp

        _safeTransferEssence(address(this), msg.sender, amountToTransfer);

        emit TemporalEssenceHarvested(_tokenId, msg.sender, amountToTransfer);
    }

    /**
     * @notice Deactivates passive Essence generation for an Artifact.
     * @dev Harvests any accrued Essence before deactivating.
     * @param _tokenId The ID of the Artifact to deactivate aura for.
     */
    function deactivateTemporalAura(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (!artifact.isAuraActive) {
            revert AuraNotActive();
        }

        harvestTemporalEssence(_tokenId); // Harvest any pending essence first

        artifact.isAuraActive = false;
        artifact.historyLog.push("Temporal Aura Deactivated");

        emit TemporalAuraDeactivated(_tokenId);
    }

    // --- V. Mutation & Entropy ---

    /**
     * @notice Applies a controlled random mutation to an Artifact's properties.
     * @dev Costs Essence. The actual mutation logic is simplified here; in a real dapp,
     *      this would influence metadata or visual traits.
     * @param _tokenId The ID of the Artifact to mutate.
     * @param _essenceCost The Essence required for the mutation.
     */
    function applyEntropyMutation(uint256 _tokenId, uint256 _essenceCost) external whenNotPaused nonReentrant NotTemporalLocked(_tokenId) {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }

        _safeTransferEssence(msg.sender, address(this), _essenceCost);

        // Simple mutation logic: increase entropy and slightly modify rarity
        uint256 newEntropy = (artifact.mutationEntropy + (block.timestamp % 100) + 1) % 1000; // Modulo to keep it within a range
        uint256 rarityChange = (block.timestamp % 2 == 0) ? 10 : (uint256(block.timestamp) % 3 == 0 ? 0 : -10); // Small random change

        artifact.mutationEntropy = newEntropy;
        artifact.rarityScore = artifact.rarityScore + rarityChange;
        artifact.historyLog.push(string.concat("Mutation Applied (Entropy: ", Strings.toString(newEntropy), ")"));

        emit MutationApplied(_tokenId, artifact.mutationEntropy, artifact.rarityScore);
    }

    // --- VI. Temporal State Control ---

    /**
     * @notice Freezes an Artifact's current evolutionary stage and prevents further aura generation or mutations.
     * @param _tokenId The ID of the Artifact to lock.
     */
    function lockTemporalState(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (artifact.isTemporalLocked) {
            revert TemporalLocked();
        }

        if (artifact.isAuraActive) {
            harvestTemporalEssence(_tokenId); // Harvest any pending essence before locking
            artifact.isAuraActive = false; // Aura is deactivated upon locking
        }

        artifact.isTemporalLocked = true;
        artifact.historyLog.push("Temporal State Locked");

        emit TemporalStateLocked(_tokenId);
    }

    /**
     * @notice Unlocks a previously locked Artifact, allowing it to continue its temporal processes.
     * @param _tokenId The ID of the Artifact to unlock.
     */
    function unlockTemporalState(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        if (!artifact.isTemporalLocked) {
            revert TemporalUnlocked();
        }

        artifact.isTemporalLocked = false;
        artifact.historyLog.push("Temporal State Unlocked");

        // When unlocked, aura state is not automatically restored, owner needs to reactivate.
        // lastAuraHarvestTimestamp is not updated here, so if aura was active before lock,
        // it implicitly resets the accumulation period upon reactivation.

        emit TemporalStateUnlocked(_tokenId);
    }

    // --- VII. Prophecy Integration (Oracle-like) ---

    /**
     * @notice Allows an authorized oracle to "align" an Artifact with external data,
     *         potentially unlocking a new evolutionary stage or unique properties.
     * @dev Callable only by the designated oracle address.
     * @param _tokenId The ID of the Artifact to align.
     * @param _externalDataHash A hash representing external verifiable data (e.g., from Chainlink).
     * @param _alignedStageUnlock The new stage to set if alignment is successful.
     */
    function alignCosmicProphecy(
        uint256 _tokenId,
        bytes32 _externalDataHash, // Placeholder for actual oracle data hash
        uint256 _alignedStageUnlock
    ) external onlyOracle whenNotPaused NotTemporalLocked(_tokenId) {
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        // In a real scenario, _externalDataHash would be verified against some on-chain state
        // or a Chainlink fulfilled request. Here, we just accept it from the oracle.

        if (_alignedStageUnlock <= artifact.evolutionStage) {
            // Can only align to a higher stage
            revert InsufficientArtifactStage(); // Or a custom error like ProphecyAlreadyFulfilled()
        }

        artifact.evolutionStage = _alignedStageUnlock;
        artifact.rarityScore += 200; // Significant rarity bonus for prophecy alignment
        artifact.lastTransmutationTimestamp = block.timestamp;
        artifact.historyLog.push(string.concat("Cosmic Prophecy Aligned (Stage: ", Strings.toString(_alignedStageUnlock), ")"));

        emit CosmicProphecyAligned(_tokenId, _externalDataHash, _alignedStageUnlock);
    }

    // --- VIII. Dimension Shifting ---

    /**
     * @notice Initiates a dimension shift for an Artifact. This is a destructive process
     *         where the Artifact is burned in exchange for a chance at a new, potentially rarer,
     *         Artifact or a significant Essence refund.
     * @dev The Artifact must be owned by msg.sender and approved to this contract.
     * @param _tokenId The ID of the Artifact to dimension shift.
     */
    function initiateDimensionShift(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (artifactToken.ownerOf(_tokenId) != msg.sender) {
            revert NotArtifactOwner();
        }
        if (artifactToken.getApproved(_tokenId) != address(this) && !artifactToken.isApprovedForAll(msg.sender, address(this))) {
            revert ArtifactNotApprovedForTransfer();
        }

        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (artifact.genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }

        address originalOwner = msg.sender;
        uint256 essenceRefundAmount = 0;
        uint256 newArtifactId = 0;

        // Determine outcome based on configured probabilities and artifact rarity
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, block.difficulty))) % 10000; // 0-9999

        if (artifact.rarityScore >= dimensionShiftConfig.rarityThreshold && randomValue < dimensionShiftConfig.newArtifactChanceBasisPoints) {
            // Outcome 1: Mint a new, potentially rarer, artifact
            newArtifactId = _artifactCounter;
            _artifactCounter++;
            artifactToken.mint(originalOwner, newArtifactId);

            // Initialize new artifact details (e.g., higher stage, boosted rarity)
            artifactData[newArtifactId] = ArtifactDetails({
                genesisTimestamp: block.timestamp,
                lastTransmutationTimestamp: block.timestamp,
                evolutionStage: artifact.evolutionStage + 1, // Ascend one stage for new artifact
                mutationEntropy: 0,
                rarityScore: artifact.rarityScore * 2, // Double rarity for new artifact
                lastAuraHarvestTimestamp: block.timestamp,
                isAuraActive: false,
                isTemporalLocked: false,
                auraAccruedEssence: 0,
                historyLog: new string[](0)
            });
            artifactData[newArtifactId].historyLog.push("Dimension Shift Outcome");

        } else {
            // Outcome 2: Refund Essence based on a percentage of an imaginary "initial mint cost"
            // For simplicity, let's assume a base mint cost or use rarityScore as a proxy for value
            // Here, we'll refund based on the global configured percentage
            uint256 deemedValue = artifact.rarityScore * 10 ether; // Example: 10 Essence per rarity point
            essenceRefundAmount = (deemedValue * dimensionShiftConfig.essenceRefundPercentageBasisPoints) / 10000;
            _safeTransferEssence(address(this), originalOwner, essenceRefundAmount);
        }

        // Burn the original Artifact
        artifactToken.safeTransferFrom(originalOwner, address(0), _tokenId); // Send to null address
        delete artifactData[_tokenId]; // Remove from our mapping

        emit DimensionShiftInitiated(
            _tokenId,
            originalOwner,
            newArtifactId,
            essenceRefundAmount
        );
    }

    /**
     * @notice Configures the probabilities and outcomes for dimension shifts.
     * @dev Only callable by the contract owner.
     * @param _rarityThreshold The minimum rarity score an Artifact needs to have a chance at a new Artifact.
     * @param _newArtifactChanceBasisPoints Chance (0-10000) for a new Artifact if threshold is met.
     * @param _essenceRefundPercentageBasisPoints Percentage (0-10000) of value refunded if no new Artifact.
     */
    function setDimensionShiftOutcomes(
        uint256 _rarityThreshold,
        uint256 _newArtifactChanceBasisPoints,
        uint256 _essenceRefundPercentageBasisPoints
    ) external onlyOwner {
        if (_newArtifactChanceBasisPoints > 10000 || _essenceRefundPercentageBasisPoints > 10000) {
            revert InvalidRecipe(); // Reusing error, should be a specific error like InvalidPercentage()
        }
        dimensionShiftConfig = DimensionShiftOutcome({
            rarityThreshold: _rarityThreshold,
            newArtifactChanceBasisPoints: _newArtifactChanceBasisPoints,
            essenceRefundPercentageBasisPoints: _essenceRefundPercentageBasisPoints
        });
    }

    // --- IX. Recipe Management ---

    /**
     * @notice Registers a new transmutation recipe.
     * @dev Only callable by the contract owner.
     * @param _recipeId Unique identifier for the recipe.
     * @param _targetStageMin Minimum evolution stage required for the target Artifact.
     * @param _essenceCost Essence required for this recipe.
     * @param _requiredInputArtifactStages Array of required input artifact stages (order matters if multiple).
     * @param _outputStage The evolution stage of the resulting artifact.
     * @param _outputRarityBonus Rarity bonus applied to the resulting artifact.
     * @param _recipeName A descriptive name for the recipe.
     */
    function registerTransmutationRecipe(
        uint256 _recipeId,
        uint256 _targetStageMin,
        uint256 _essenceCost,
        uint256[] calldata _requiredInputArtifactStages,
        uint256 _outputStage,
        uint256 _outputRarityBonus,
        string calldata _recipeName
    ) external onlyOwner {
        if (transmutationRecipes[_recipeId].exists) {
            revert InvalidRecipe(); // Recipe ID already exists
        }
        transmutationRecipes[_recipeId] = TransmutationRecipe({
            exists: true,
            targetStageMin: _targetStageMin,
            essenceCost: _essenceCost,
            requiredInputArtifactStages: _requiredInputArtifactStages,
            outputStage: _outputStage,
            outputRarityBonus: _outputRarityBonus,
            recipeName: _recipeName
        });
        emit TransmutationRecipeRegistered(_recipeId, _recipeName, _outputStage);
    }

    /**
     * @notice Deregisters an existing transmutation recipe.
     * @dev Only callable by the contract owner.
     * @param _recipeId The ID of the recipe to deregister.
     */
    function deregisterTransmutationRecipe(uint256 _recipeId) external onlyOwner {
        if (!transmutationRecipes[_recipeId].exists) {
            revert RecipeNotFound();
        }
        delete transmutationRecipes[_recipeId];
        emit TransmutationRecipeDeregistered(_recipeId);
    }

    /**
     * @notice Retrieves the details of a specific transmutation recipe.
     * @param _recipeId The ID of the recipe.
     * @return TransmutationRecipe struct.
     */
    function getTransmutationRecipe(uint256 _recipeId) public view returns (TransmutationRecipe memory) {
        if (!transmutationRecipes[_recipeId].exists) {
            revert RecipeNotFound();
        }
        return transmutationRecipes[_recipeId];
    }

    /**
     * @notice Returns a list of recipe IDs that are currently applicable to a given Artifact.
     * @dev Iterates through all known recipes, might be gas-intensive if many recipes.
     * @param _tokenId The ID of the Artifact to check against.
     * @return An array of applicable recipe IDs.
     */
    function getAvailableRecipesForArtifact(uint256 _tokenId) public view returns (uint256[] memory) {
        if (artifactData[_tokenId].genesisTimestamp == 0) {
            revert ArtifactNotFound();
        }
        uint256 currentStage = artifactData[_tokenId].evolutionStage;
        uint256[] memory applicableRecipes = new uint256[](100); // Max 100 recipes for this example. Adjust as needed.
        uint256 count = 0;

        // This is an inefficient way to iterate through map keys.
        // In a production system, you'd track recipe IDs in a dynamic array or use an iterable mapping.
        // For this example, we assume recipe IDs are reasonably dense or pre-known.
        for (uint256 i = 0; i < 100; i++) { // Max 100 assumed recipes
            if (transmutationRecipes[i].exists && currentStage >= transmutationRecipes[i].targetStageMin) {
                applicableRecipes[count] = i;
                count++;
            }
        }
        assembly {
            mstore(applicableRecipes, count) // Adjust array length
        }
        return applicableRecipes;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to safely transfer Essence tokens.
     * @param _from The address to transfer tokens from.
     * @param _to The address to transfer tokens to.
     * @param _amount The amount of tokens to transfer.
     */
    function _safeTransferEssence(address _from, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            if (_from == address(this)) {
                // Transfer from contract to user
                if (!essenceToken.transfer(_to, _amount)) {
                    revert TransferFailed();
                }
            } else {
                // Transfer from user to contract (or another user via allowance)
                if (!essenceToken.transferFrom(_from, _to, _amount)) {
                    revert TransferFailed();
                }
            }
        }
    }

    /**
     * @dev Internal function to calculate and update accrued Essence for an Artifact.
     * @param _tokenId The ID of the Artifact.
     */
    function _calculateAccruedEssence(uint256 _tokenId) internal {
        ArtifactDetails storage artifact = artifactData[_tokenId];
        if (!artifact.isAuraActive) {
            return;
        }

        uint256 timeElapsed = block.timestamp - artifact.lastAuraHarvestTimestamp;
        if (timeElapsed == 0) {
            return;
        }

        // Example: Aura rate grows with stage, entropy, and base rate
        uint256 auraRatePerSecond = (1 + artifact.evolutionStage) * 10 ** 12 // 10^12 wei per second per stage (adjust for your token decimals)
                                    + (artifact.mutationEntropy / 100) * 10 ** 11; // 1/1000th of entropy adds to aura

        artifact.auraAccruedEssence += auraRatePerSecond * timeElapsed;
        artifact.lastAuraHarvestTimestamp = block.timestamp;
    }

    // --- Override ERC721Holder for receiving NFTs (e.g. for burning or temporary holding) ---
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Only allow transfers to this contract if it's from itself (for "burning" or internal transfer)
        // Or for specific functions that expect a transfer (e.g., transmute input artifacts)
        // For security, a robust contract would check msg.sender == address(this) || expected_transmute_function_call.
        // For this example, we'll allow it for flexibility in testing the transmute function
        // which transfers inputs *to* the contract.
        return this.onERC721Received.selector;
    }
}

// --- OpenZeppelin Contracts (Included for completeness) ---
// These would typically be imported from node_modules/@openzeppelin/contracts

// contracts/access/Ownable.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// abstract contract Ownable {
//     address private _owner;
//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
//     constructor(address initialOwner) {
//         if (initialOwner == address(0)) revert OwnableInvalidOwner(address(0));
//         _transferOwnership(initialOwner);
//     }
//     function owner() public view virtual returns (address) {
//         return _owner;
//     }
//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }
//     function _checkOwner() internal view virtual {
//         if (owner() != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
//     }
//     function renounceOwnership() public virtual onlyOwner {
//         _transferOwnership(address(0));
//     }
//     function transferOwnership(address newOwner) public virtual onlyOwner {
//         if (newOwner == address(0)) revert OwnableInvalidOwner(address(0));
//         _transferOwnership(newOwner);
//     }
//     function _transferOwnership(address newOwner) internal virtual {
//         address oldOwner = _owner;
//         _owner = newOwner;
//         emit OwnershipTransferred(oldOwner, newOwner);
//     }
//     error OwnableInvalidOwner(address owner);
//     error OwnableUnauthorizedAccount(address account);
// }

// contracts/security/Pausable.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// abstract contract Pausable is Ownable {
//     bool private _paused;
//     event Paused(address account);
//     event Unpaused(address account);
//     constructor(address initialOwner) Ownable(initialOwner) {
//         _paused = false;
//     }
//     function paused() public view virtual returns (bool) {
//         return _paused;
//     }
//     modifier whenNotPaused() {
//         _requireNotPaused();
//         _;
//     }
//     modifier whenPaused() {
//         _requirePaused();
//         _;
//     }
//     function _requireNotPaused() internal view virtual {
//         if (paused()) revert PausablePaused();
//     }
//     function _requirePaused() internal view virtual {
//         if (!paused()) revert PausableNotPaused();
//     }
//     function _pause() internal virtual onlyOwner {
//         _paused = true;
//         emit Paused(msg.sender);
//     }
//     function _unpause() internal virtual onlyOwner {
//         _paused = false;
//         emit Unpaused(msg.sender);
//     }
//     error PausablePaused();
//     error PausableNotPaused();
// }

// contracts/security/ReentrancyGuard.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// abstract contract ReentrancyGuard {
//     uint256 private constant _NOT_ENTERED = 1;
//     uint256 private constant _ENTERED = 2;
//     uint256 private _status;
//     constructor() {
//         _status = _NOT_ENTERED;
//     }
//     modifier nonReentrant() {
//         _nonReentrantBefore();
//         _;
//         _nonReentrantAfter();
//     }
//     function _nonReentrantBefore() private {
//         if (_status == _ENTERED) {
//             revert ReentrancyGuardReentrantCall();
//         }
//         _status = _ENTERED;
//     }
//     function _nonReentrantAfter() private {
//         _status = _NOT_ENTERED;
//     }
//     error ReentrancyGuardReentrantCall();
// }

// contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// interface IERC20 {
//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(address indexed owner, address indexed spender, uint256 value);
//     function totalSupply() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address to, uint256 value) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 value) external returns (bool);
//     function transferFrom(address from, address to, uint256 value) external returns (bool);
// }

// contracts/token/ERC721/IERC721.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// interface IERC721 {
//     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
//     event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
//     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
//     function balanceOf(address owner) external view returns (uint256 balance);
//     function ownerOf(uint256 tokenId) external view returns (address owner);
//     function safeTransferFrom(address from, address to, uint256 tokenId) external;
//     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
//     function transferFrom(address from, address to, uint256 tokenId) external;
//     function approve(address to, uint256 tokenId) external;
//     function getApproved(uint256 tokenId) external view returns (address operator);
//     function setApprovalForAll(address operator, bool _approved) external;
//     function isApprovedForAll(address owner, address operator) external view returns (bool);
// }

// contracts/token/ERC721/utils/ERC721Holder.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// import "../IERC721Receiver.sol";
// abstract contract ERC721Holder is IERC721Receiver {
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) public virtual override returns (bytes4) {
//         return this.onERC721Received.selector;
//     }
// }

// contracts/token/ERC721/IERC721Receiver.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// interface IERC721Receiver {
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external returns (bytes4);
// }

// contracts/utils/Strings.sol
// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// library Strings {
//     bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
//     function toString(uint256 value) internal pure returns (string memory) {
//         if (value == 0) {
//             return "0";
//         }
//         uint256 temp = value;
//         uint256 digits;
//         while (temp != 0) {
//             digits++;
//             temp /= 10;
//         }
//         bytes memory buffer = new bytes(digits);
//         while (value != 0) {
//             digits--;
//             buffer[digits] = bytes1(_HEX_SYMBOLS[value % 10]);
//             value /= 10;
//         }
//         return string(buffer);
//     }
//     function toHexString(uint256 value) internal pure returns (string memory) {
//         bytes memory buffer = new bytes(2 * Math.log2(value) / 8 + 1);
//         // This is a placeholder for actual toHexString logic
//         // return actual conversion logic
//         return string(abi.encodePacked("0x", toHexString(bytes32(value))));
//     }
//     function toHexString(address value) internal pure returns (string memory) {
//         return toHexString(uint256(uint160(value)), 20);
//     }
//     function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
//         bytes memory buffer = new bytes(2 * length);
//         // This is a placeholder for actual toHexString logic
//         // return actual conversion logic
//         return string(abi.encodePacked("0x", toHexString(bytes32(value), length)));
//     }
//     function toHexString(bytes32 value, uint256 length) internal pure returns (string memory) {
//         bytes memory buffer = new bytes(2 * length);
//         for (uint256 i = 0; i < length; i++) {
//             buffer[i * 2] = _HEX_SYMBOLS[uint8(value[i] >> 4)];
//             buffer[i * 2 + 1] = _HEX_SYMBOLS[uint8(value[i] & 0x0f)];
//         }
//         return string(abi.encodePacked("0x", buffer));
//     }
// }
// // Minimal Math for Strings.sol
// library Math {
//     function log2(uint256 value) internal pure returns (uint256) {
//         uint256 result = 0;
//         unchecked {
//             if (value >> 128 > 0) {
//                 value >>= 128;
//                 result += 128;
//             }
//             if (value >> 64 > 0) {
//                 value >>= 64;
//                 result += 64;
//             }
//             if (value >> 32 > 0) {
//                 value >>= 32;
//                 result += 32;
//             }
//             if (value >> 16 > 0) {
//                 value >>= 16;
//                 result += 16;
//             }
//             if (value >> 8 > 0) {
//                 value >>= 8;
//                 result += 8;
//             }
//             if (value >> 4 > 0) {
//                 value >>= 4;
//                 result += 4;
//             }
//             if (value >> 2 > 0) {
//                 value >>= 2;
//                 result += 2;
//             }
//             if (value >> 1 > 0) {
//                 result += 1;
//             }
//         }
//         return result;
//     }
// }

```