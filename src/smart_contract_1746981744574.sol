Okay, let's design an advanced, creative, and trendy smart contract called "QuantumForge". This contract will simulate a crafting/forging process where users combine different digital "Elements" (ERC-1155) and "Energy" (ERC-20) to produce "Particles" (ERC-1155) or "Artifacts" (ERC-721). The process will involve on-chain randomness via Chainlink VRF and potential influence from external data simulated by an oracle factor. It will feature complex state management, different types of recipes, success/failure outcomes, and potential NFT enhancement.

**Concept:**

The QuantumForge is a smart contract platform where users can submit ingredients (ERC-1155 Element tokens and ERC-20 Energy tokens) according to defined "recipes". The forging process is non-deterministic, with outcomes (success, failure, critical success, mutation) determined by a combination of Chainlink VRF randomness and an "Oracle Influence Factor" which simulates external, unpredictable cosmic conditions affecting the forge. Successful synthesis yields ERC-1155 Particles or ERC-721 Artifacts. Artifacts can potentially be further enhanced by locking Particles into them.

**Advanced Concepts Included:**

1.  **Cross-Token Interaction:** Handles ERC-20, ERC-1155, and ERC-721 interactions (burning inputs, minting outputs, potentially interacting with target NFTs).
2.  **Chainlink VRF v2 Integration:** Uses verifiable randomness for process outcomes.
3.  **Complex State Management:** Tracks individual user forging processes, their states (initiated, VRF pending, completed, claimed), associated data, and outcomes.
4.  **Probabilistic Outcomes:** Success/failure/mutation rates based on randomness and influencing factors.
5.  **Recipe System:** Admin-managed recipes defining inputs and potential outputs.
6.  **Simulated Oracle Influence:** A state variable (`oracleInfluenceFactor`) modifiable by a privileged role, affecting probabilities, simulating external data dependency.
7.  **Role-Based Access Control:** Using OpenZeppelin AccessControl for different administrative privileges (Admin, Recipe Manager, Oracle Updater).
8.  **Pausable System:** Ability to pause core operations.
9.  **NFT Enhancement Mechanic:** A function allowing users to "lock" ERC-1155 Particles into a target ERC-721 Artifact, requiring the Artifact contract to support a receiving function or state update.
10. **Event-Driven State Changes:** Extensive events to track process lifecycle and outcomes.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Imports ---
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Basic interface, might need extension for enhancement
import "@openzeppelin/contracts/token/ERC1155/utils/IERC1155Receiver.sol"; // For ERC-1155 safety (though Forge pulls)
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// --- Interfaces ---

// Interface for the specific Artifact NFT contract that supports enhancement
interface IEnhanceableArtifact is IERC721 {
    // Function the Forge will call to enhance an artifact
    // bytes calldata data could contain particle types/amounts
    function enhance(uint256 tokenId, address user, bytes calldata enhancementData) external;
    // Potentially other view functions to see enhancements on a token
    // function getEnhancementData(uint256 tokenId) external view returns (bytes memory);
}

// --- Contract Definition ---

/**
 * @title QuantumForge
 * @dev A complex smart contract simulating a probabilistic crafting/forging system.
 *      Users submit tokens (Elements, Energy) to initiate processes that
 *      produce new tokens (Particles, Artifacts) with outcomes
 *      influenced by randomness (VRF) and external factors (Oracle).
 */
contract QuantumForge is VRFConsumerBaseV2, AccessControl, Pausable {

    // --- State Variables ---

    // Core Token Addresses
    IERC20 public energyToken; // Token required as 'fuel' for forging
    IERC1155 public elementToken; // Base input tokens (different types)
    IERC1155 public particleToken; // Intermediate/refined tokens (different types)
    IEnhanceableArtifact public artifactToken; // Output NFT tokens (different types, enhanceable)

    // Chainlink VRF V2 Configuration
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public s_callbackGasLimit;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1; // Requesting 1 random word

    // Role Definitions
    bytes32 public constant RECIPE_MANAGER_ROLE = keccak256("RECIPE_MANAGER");
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER"); // Role to update the 'oracleInfluenceFactor'

    // Forging Process Management
    struct ForgingProcess {
        address user;
        uint256 processType; // 0 for Refine, 1 for Synthesize
        uint256 recipeId;
        uint256 vrfRequestId; // Chainlink VRF request ID
        uint256 randomWord;   // Resulting random word from VRF
        bool vrfFulfilled;    // True if VRF callback has been received
        uint256 outcome;      // 0: Pending, 1: Success, 2: Failure, 3: CriticalSuccess, 4: Mutation
        bool claimed;         // True if output/inputs have been claimed
        uint256 initiationTimestamp; // When the process started
        // Can add more state specific to inputs/outputs here if needed
    }

    uint256 private _nextProcessId; // Counter for unique process IDs
    mapping(uint256 => ForgingProcess) public forgingProcesses; // Map process ID to process details
    mapping(uint256 => uint256) private s_vrfRequestIdToProcessId; // Map VRF request ID to process ID
    mapping(address => uint256[]) private userProcessIds; // Map user to list of their process IDs

    // Recipe Management
    struct RecipeInput {
        uint256 tokenId; // ERC-1155 token ID (for elements/particles)
        uint256 amount;  // Required amount
    }

    struct RefineRecipe {
        uint256 energyCost;
        RecipeInput[] inputs; // Elements required
        uint256 outputParticleId; // Particle token ID produced on success
        uint256 outputAmount; // Amount produced on success
        uint256 successRateBasisPoints; // Probability of success (e.g., 7000 for 70%)
        uint256 criticalSuccessRateBasisPoints; // Probability of critical success (higher yield?)
        uint256 mutationRateBasisPoints; // Probability of mutation (different output?)
        // Total rate for success + critical + mutation must be <= 10000
    }

    struct SynthesisRecipe {
        uint256 energyCost;
        RecipeInput[] inputs; // Particles required
        uint256 outputArtifactId; // Artifact token ID produced on success
        uint256 successRateBasisPoints;
        uint256 criticalSuccessRateBasisPoints; // Potential for special artifact properties?
        uint256 mutationRateBasisPoints; // Potential for a different artifact or particle output?
    }

    mapping(uint256 => RefineRecipe) public refineRecipes; // Map recipe ID to refine recipe details
    mapping(uint256 => SynthesisRecipe) public synthesisRecipes; // Map recipe ID to synthesis recipe details
    uint256 private _nextRefineRecipeId;
    uint256 private _nextSynthesisRecipeId;

    // Oracle Influence Simulation
    // This factor (0-10000 basis points) influences process outcomes dynamically
    uint256 public oracleInfluenceFactor; // Set by ORACLE_UPDATER_ROLE

    // Process Cooldown
    mapping(address => uint256) private userLastProcessTimestamp;
    uint256 public processCooldownDuration = 60; // Default cooldown in seconds

    // --- Events ---
    event TokenAddressesSet(address indexed energy, address indexed element, address indexed particle, address indexed artifact);
    event VRFParametersSet(bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit);
    event ForgingProcessInitiated(uint256 indexed processId, address indexed user, uint256 processType, uint256 recipeId, uint256 initiationTimestamp);
    event VRFRequestedForProcess(uint256 indexed processId, uint256 vrfRequestId);
    event ForgingProcessCompleted(uint256 indexed processId, uint256 outcome, uint256 randomWord);
    event ForgingProcessClaimed(uint256 indexed processId, address indexed user);
    event RefineRecipeAdded(uint256 indexed recipeId, uint256 energyCost, uint256 outputParticleId, uint256 outputAmount);
    event SynthesisRecipeAdded(uint256 indexed recipeId, uint256 energyCost, uint256 outputArtifactId);
    event RecipeRemoved(uint256 indexed recipeId, uint256 processType);
    event RecipeUpdated(uint256 indexed recipeId, uint256 processType);
    event OracleInfluenceFactorUpdated(uint256 newFactor);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ProcessCooldownSet(uint256 duration);
    event ArtifactEnhanced(uint256 indexed artifactTokenId, address indexed user, uint256 indexed processId);

    // --- Constructor ---
    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    )
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is default admin
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        _nextProcessId = 1; // Start process IDs from 1
        _nextRefineRecipeId = 1; // Start recipe IDs from 1
        _nextSynthesisRecipeId = 1; // Start recipe IDs from 1
        oracleInfluenceFactor = 5000; // Default 50% influence base
    }

    // --- Admin & Configuration Functions ---

    /**
     * @summary 1. setTokenAddresses
     * @dev Sets the addresses for the required token contracts.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _energy ERC20 address
     * @param _element ERC1155 address for input elements
     * @param _particle ERC1155 address for output particles (from refining)
     * @param _artifact ERC721 address for output artifacts (from synthesizing)
     */
    function setTokenAddresses(address _energy, address _element, address _particle, address _artifact) external onlyRole(DEFAULT_ADMIN_ROLE) {
        energyToken = IERC20(_energy);
        elementToken = IERC1155(_element);
        particleToken = IERC1155(_particle);
        artifactToken = IEnhanceableArtifact(_artifact); // Use the custom interface
        emit TokenAddressesSet(_energy, _element, _particle, _artifact);
    }

    /**
     * @summary 2. setVRFParameters
     * @dev Sets the VRF parameters (key hash, subscription ID, callback gas limit).
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _callbackGasLimit Gas limit for the fulfillRandomWords callback
     */
    function setVRFParameters(bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        emit VRFParametersSet(_keyHash, _subscriptionId, _callbackGasLimit);
    }

    /**
     * @summary 3. withdrawFees
     * @dev Allows the admin to withdraw accumulated Energy tokens.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _to Address to send tokens to.
     */
    function withdrawFees(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        uint256 balance = energyToken.balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");
        energyToken.transfer(_to, balance);
        emit FeesWithdrawn(_to, balance);
    }

    /**
     * @summary 4. pauseForge
     * @dev Pauses forging operations (initiation and claiming).
     *      Requires DEFAULT_ADMIN_ROLE.
     */
    function pauseForge() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @summary 5. unpauseForge
     * @dev Unpauses forging operations.
     *      Requires DEFAULT_ADMIN_ROLE.
     */
    function unpauseForge() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @summary 6. grantRecipeManager
     * @dev Grants the RECIPE_MANAGER_ROLE.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _account Address to grant the role to.
     */
    function grantRecipeManager(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RECIPE_MANAGER_ROLE, _account);
    }

    /**
     * @summary 7. revokeRecipeManager
     * @dev Revokes the RECIPE_MANAGER_ROLE.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _account Address to revoke the role from.
     */
    function revokeRecipeManager(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(RECIPE_MANAGER_ROLE, _account);
    }

     /**
     * @summary 8. grantOracleUpdater
     * @dev Grants the ORACLE_UPDATER_ROLE.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _account Address to grant the role to.
     */
    function grantOracleUpdater(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORACLE_UPDATER_ROLE, _account);
    }

    /**
     * @summary 9. revokeOracleUpdater
     * @dev Revokes the ORACLE_UPDATER_ROLE.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _account Address to revoke the role from.
     */
    function revokeOracleUpdater(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ORACLE_UPDATER_ROLE, _account);
    }

    /**
     * @summary 10. setProcessCooldownDuration
     * @dev Sets the minimum time required between process initiations for a user.
     *      Requires DEFAULT_ADMIN_ROLE.
     * @param _duration Cooldown in seconds.
     */
    function setProcessCooldownDuration(uint256 _duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        processCooldownDuration = _duration;
        emit ProcessCooldownSet(_duration);
    }

    // --- Recipe Management Functions (Requires RECIPE_MANAGER_ROLE) ---

    /**
     * @summary 11. addRefineRecipe
     * @dev Adds a new refine recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipe Details of the new recipe.
     * @return The ID of the newly added recipe.
     */
    function addRefineRecipe(RefineRecipe calldata _recipe) external onlyRole(RECIPE_MANAGER_ROLE) returns (uint256) {
        uint256 newId = _nextRefineRecipeId++;
        refineRecipes[newId] = _recipe;
        require(_recipe.successRateBasisPoints + _recipe.criticalSuccessRateBasisPoints + _recipe.mutationRateBasisPoints <= 10000, "Rates exceed 100%");
        emit RefineRecipeAdded(newId, _recipe.energyCost, _recipe.outputParticleId, _recipe.outputAmount);
        return newId;
    }

    /**
     * @summary 12. updateRefineRecipe
     * @dev Updates an existing refine recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipeId The ID of the recipe to update.
     * @param _recipe Details of the updated recipe.
     */
    function updateRefineRecipe(uint256 _recipeId, RefineRecipe calldata _recipe) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(refineRecipes[_recipeId].energyCost > 0, "Recipe does not exist"); // Simple check if exists
        refineRecipes[_recipeId] = _recipe;
        require(_recipe.successRateBasisPoints + _recipe.criticalSuccessRateBasisPoints + _recipe.mutationRateBasisPoints <= 10000, "Rates exceed 100%");
        emit RecipeUpdated(_recipeId, 0); // 0 for Refine type
    }

    /**
     * @summary 13. removeRefineRecipe
     * @dev Removes a refine recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipeId The ID of the recipe to remove.
     */
    function removeRefineRecipe(uint256 _recipeId) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(refineRecipes[_recipeId].energyCost > 0, "Recipe does not exist");
        delete refineRecipes[_recipeId];
        emit RecipeRemoved(_recipeId, 0); // 0 for Refine type
    }

    /**
     * @summary 14. addSynthesisRecipe
     * @dev Adds a new synthesis recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipe Details of the new recipe.
     * @return The ID of the newly added recipe.
     */
    function addSynthesisRecipe(SynthesisRecipe calldata _recipe) external onlyRole(RECIPE_MANAGER_ROLE) returns (uint256) {
        uint256 newId = _nextSynthesisRecipeId++;
        synthesisRecipes[newId] = _recipe;
         require(_recipe.successRateBasisPoints + _recipe.criticalSuccessRateBasisPoints + _recipe.mutationRateBasisPoints <= 10000, "Rates exceed 100%");
        emit SynthesisRecipeAdded(newId, _recipe.energyCost, _recipe.outputArtifactId);
        return newId;
    }

    /**
     * @summary 15. updateSynthesisRecipe
     * @dev Updates an existing synthesis recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipeId The ID of the recipe to update.
     * @param _recipe Details of the updated recipe.
     */
    function updateSynthesisRecipe(uint256 _recipeId, SynthesisRecipe calldata _recipe) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(synthesisRecipes[_recipeId].energyCost > 0, "Recipe does not exist");
        synthesisRecipes[_recipeId] = _recipe;
        require(_recipe.successRateBasisPoints + _recipe.criticalSuccessRateBasisPoints + _recipe.mutationRateBasisPoints <= 10000, "Rates exceed 100%");
        emit RecipeUpdated(_recipeId, 1); // 1 for Synthesis type
    }

    /**
     * @summary 16. removeSynthesisRecipe
     * @dev Removes a synthesis recipe.
     *      Requires RECIPE_MANAGER_ROLE.
     * @param _recipeId The ID of the recipe to remove.
     */
    function removeSynthesisRecipe(uint256 _recipeId) external onlyRole(RECIPE_MANAGER_ROLE) {
        require(synthesisRecipes[_recipeId].energyCost > 0, "Recipe does not exist");
        delete synthesisRecipes[_recipeId];
        emit RecipeRemoved(_recipeId, 1); // 1 for Synthesis type
    }

    // --- Oracle Influence Function (Requires ORACLE_UPDATER_ROLE) ---

    /**
     * @summary 17. setOracleInfluenceFactor
     * @dev Sets the factor influencing probabilistic outcomes. Simulates oracle data.
     *      Requires ORACLE_UPDATER_ROLE.
     * @param _newFactor New factor (0-10000 basis points).
     */
    function setOracleInfluenceFactor(uint256 _newFactor) external onlyRole(ORACLE_UPDATER_ROLE) {
        require(_newFactor <= 10000, "Factor cannot exceed 10000");
        oracleInfluenceFactor = _newFactor;
        emit OracleInfluenceFactorUpdated(_newFactor);
    }

    // --- Core Forging Functions ---

    /**
     * @summary 18. initiateRefineElements
     * @dev Initiates a refinement process using a specific recipe.
     *      Requires user to approve Energy and Element tokens beforehand.
     *      Triggers a VRF request.
     * @param _recipeId The ID of the refine recipe to use.
     */
    function initiateRefineElements(uint256 _recipeId) external whenNotPaused {
        require(block.timestamp >= userLastProcessTimestamp[msg.sender] + processCooldownDuration, "Cooldown active");

        RefineRecipe storage recipe = refineRecipes[_recipeId];
        require(recipe.energyCost > 0, "Refine recipe not found");

        // Transfer required tokens from the user
        energyToken.transferFrom(msg.sender, address(this), recipe.energyCost);

        uint256[] memory elementIds = new uint256[](recipe.inputs.length);
        uint256[] memory elementAmounts = new uint256[](recipe.inputs.length);
        for (uint i = 0; i < recipe.inputs.length; i++) {
            elementIds[i] = recipe.inputs[i].tokenId;
            elementAmounts[i] = recipe.inputs[i].amount;
        }
        elementToken.safeBatchTransferFrom(msg.sender, address(this), elementIds, elementAmounts, "");

        // Request VRF randomness
        uint256 requestId = vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );

        // Store process details
        uint256 currentProcessId = _nextProcessId++;
        forgingProcesses[currentProcessId] = ForgingProcess({
            user: msg.sender,
            processType: 0, // 0 for Refine
            recipeId: _recipeId,
            vrfRequestId: requestId,
            randomWord: 0, // Placeholder, will be set by callback
            vrfFulfilled: false,
            outcome: 0, // 0 for Pending
            claimed: false,
            initiationTimestamp: block.timestamp
        });

        s_vrfRequestIdToProcessId[requestId] = currentProcessId;
        userProcessIds[msg.sender].push(currentProcessId);
        userLastProcessTimestamp[msg.sender] = block.timestamp;

        emit ForgingProcessInitiated(currentProcessId, msg.sender, 0, _recipeId, block.timestamp);
        emit VRFRequestedForProcess(currentProcessId, requestId);
    }

    /**
     * @summary 19. initiateSynthesizeArtifact
     * @dev Initiates an artifact synthesis process using a specific recipe.
     *      Requires user to approve Energy and Particle tokens beforehand.
     *      Triggers a VRF request.
     * @param _recipeId The ID of the synthesis recipe to use.
     */
    function initiateSynthesizeArtifact(uint256 _recipeId) external whenNotPaused {
        require(block.timestamp >= userLastProcessTimestamp[msg.sender] + processCooldownDuration, "Cooldown active");

        SynthesisRecipe storage recipe = synthesisRecipes[_recipeId];
        require(recipe.energyCost > 0, "Synthesis recipe not found");

        // Transfer required tokens from the user
        energyToken.transferFrom(msg.sender, address(this), recipe.energyCost);

        uint256[] memory particleIds = new uint256[](recipe.inputs.length);
        uint256[] memory particleAmounts = new uint256[](recipe.inputs.length);
        for (uint i = 0; i < recipe.inputs.length; i++) {
            particleIds[i] = recipe.inputs[i].tokenId;
            particleAmounts[i] = recipe.inputs[i].amount;
        }
        particleToken.safeBatchTransferFrom(msg.sender, address(this), particleIds, particleAmounts, "");

         // Request VRF randomness
        uint256 requestId = vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );

        // Store process details
        uint256 currentProcessId = _nextProcessId++;
         forgingProcesses[currentProcessId] = ForgingProcess({
            user: msg.sender,
            processType: 1, // 1 for Synthesize
            recipeId: _recipeId,
            vrfRequestId: requestId,
            randomWord: 0, // Placeholder
            vrfFulfilled: false,
            outcome: 0, // Pending
            claimed: false,
            initiationTimestamp: block.timestamp
        });

        s_vrfRequestIdToProcessId[requestId] = currentProcessId;
        userProcessIds[msg.sender].push(currentProcessId);
        userLastProcessTimestamp[msg.sender] = block.timestamp;

        emit ForgingProcessInitiated(currentProcessId, msg.sender, 1, _recipeId, block.timestamp);
        emit VRFRequestedForProcess(currentProcessId, requestId);
    }

    /**
     * @summary 20. fulfillRandomWords (VRF Callback)
     * @dev Chainlink VRF callback function. Internal.
     *      Determines the outcome of the forging process based on the random word and influence factor.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords Array of random words.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_vrfRequestIdToProcessId[_requestId] != 0, "VRF request ID not found");
        uint256 processId = s_vrfRequestIdToProcessId[_requestId];
        ForgingProcess storage process = forgingProcesses[processId];

        require(!process.vrfFulfilled, "VRF already fulfilled for this process");

        uint256 randomWord = _randomWords[0];
        process.randomWord = randomWord;
        process.vrfFulfilled = true;

        // Determine Outcome based on random word and oracle influence
        uint256 randomPercentage = (randomWord % 10000) + 1; // 1 to 10000

        uint256 successRate;
        uint256 criticalSuccessRate;
        uint256 mutationRate;
        // Adjust rates based on oracleInfluenceFactor (e.g., linear influence)
        // This logic can be complex. Example: rates shift towards success/critical if factor is high.
        uint256 influenceBasisPoints = oracleInfluenceFactor; // 0-10000

        if (process.processType == 0) { // Refine Process
            RefineRecipe storage recipe = refineRecipes[process.recipeId];
             // Example influence logic: If influence is high ( > 5000), boost success/critical, reduce failure.
            // If influence is low (< 5000), reduce success/critical, boost failure.
            // Simple linear interpolation example:
            int256 rateAdjustment = int256(influenceBasisPoints) - 5000; // -5000 to +5000
            successRate = _applyInfluence(recipe.successRateBasisPoints, rateAdjustment, 2000); // Max +-20% adj
            criticalSuccessRate = _applyInfluence(recipe.criticalSuccessRateBasisPoints, rateAdjustment, 1000); // Max +-10% adj
            mutationRate = _applyInfluence(recipe.mutationRateBasisPoints, -rateAdjustment, 500); // Inverse adjustment for mutation

            // Clamp rates to ensure they are within bounds and total <= 10000
            uint256 totalAdjustedRates = successRate + criticalSuccessRate + mutationRate;
             if (totalAdjustedRates > 10000) {
                uint256 excess = totalAdjustedRates - 10000;
                // Simple reduction: Proportional or subtract from lowest? Let's proportionally reduce for simplicity
                successRate = successRate * 10000 / totalAdjustedRates;
                criticalSuccessRate = criticalSuccessRate * 10000 / totalAdjustedRates;
                mutationRate = mutationRate * 10000 / totalAdjustedRates;
            }


            if (randomPercentage <= criticalSuccessRate) {
                process.outcome = 3; // Critical Success
            } else if (randomPercentage <= criticalSuccessRate + successRate) {
                process.outcome = 1; // Success
            } else if (randomPercentage <= criticalSuccessRate + successRate + mutationRate) {
                process.outcome = 4; // Mutation
            } else {
                process.outcome = 2; // Failure
            }

        } else if (process.processType == 1) { // Synthesize Process
             SynthesisRecipe storage recipe = synthesisRecipes[process.recipeId];
             int256 rateAdjustment = int256(influenceBasisPoints) - 5000; // -5000 to +5000
             successRate = _applyInfluence(recipe.successRateBasisPoints, rateAdjustment, 2000); // Max +-20% adj
             criticalSuccessRate = _applyInfluence(recipe.criticalSuccessRateBasisPoints, rateAdjustment, 1000); // Max +-10% adj
             mutationRate = _applyInfluence(recipe.mutationRateBasisPoints, -rateAdjustment, 500); // Inverse adjustment

             uint256 totalAdjustedRates = successRate + criticalSuccessRate + mutationRate;
              if (totalAdjustedRates > 10000) {
                successRate = successRate * 10000 / totalAdjustedRates;
                criticalSuccessRate = criticalSuccessRate * 10000 / totalAdjustedRates;
                mutationRate = mutationRate * 10000 / totalAdjustedRates;
            }

            if (randomPercentage <= criticalSuccessRate) {
                process.outcome = 3; // Critical Success
            } else if (randomPercentage <= criticalSuccessRate + successRate) {
                process.outcome = 1; // Success
            } else if (randomPercentage <= criticalSuccessRate + successRate + mutationRate) {
                process.outcome = 4; // Mutation
            } else {
                process.outcome = 2; // Failure
            }
        }
        // else { unknown process type error? Should not happen based on logic }

        emit ForgingProcessCompleted(processId, process.outcome, randomWord);
    }

    // Internal helper to apply influence to rates
    function _applyInfluence(uint256 baseRate, int256 adjustment, uint256 maxAdjustment) internal pure returns (uint256) {
        // adjustment is -5000 to +5000 (from oracleInfluenceFactor - 5000)
        // Max adjustment is applied at the extremes (0 or 10000 influence factor)
        // If influence is 0 (adjustment -5000), apply -maxAdjustment
        // If influence is 10000 (adjustment +5000), apply +maxAdjustment
        // Linear interpolation: adjustedRate = baseRate + adjustment/5000 * maxAdjustment
        int256 adjustedRate = int256(baseRate) + (adjustment * int256(maxAdjustment)) / 5000;

        // Clamp minimum rate at 0
        return uint256(adjustedRate > 0 ? adjustedRate : 0);
    }


    /**
     * @summary 21. claimRefinementOutput
     * @dev Allows the user to claim the output of a completed refinement process.
     *      Distributes particles based on outcome.
     * @param _processId The ID of the completed process.
     */
    function claimRefinementOutput(uint256 _processId) external whenNotPaused {
        ForgingProcess storage process = forgingProcesses[_processId];
        require(process.user == msg.sender, "Not your process");
        require(process.processType == 0, "Not a refinement process");
        require(process.vrfFulfilled, "VRF not fulfilled yet");
        require(!process.claimed, "Process already claimed");

        RefineRecipe storage recipe = refineRecipes[process.recipeId];
        uint256 outputAmount = 0; // Default failure/mutation output

        if (process.outcome == 1) { // Success
            outputAmount = recipe.outputAmount;
            particleToken.safeTransferFrom(address(this), msg.sender, recipe.outputParticleId, outputAmount, "");
        } else if (process.outcome == 3) { // Critical Success
            outputAmount = recipe.outputAmount * 150 / 100; // Example: 50% bonus yield
             particleToken.safeTransferFrom(address(this), msg.sender, recipe.outputParticleId, outputAmount, "");
        } else if (process.outcome == 4) { // Mutation
            // Example: Mutate into a different particle or a fraction of the original output
            uint256 mutatedParticleId = recipe.outputParticleId + 1; // Example: Just change token ID
            uint256 mutatedAmount = recipe.outputAmount / 2; // Example: Half amount
             particleToken.safeTransferFrom(address(this), msg.sender, mutatedParticleId, mutatedAmount, "");
             outputAmount = mutatedAmount; // Update outputAmount for event
             // Note: This requires particleToken contract to have supply for mutatedId or support minting
        } else { // Failure (outcome == 2)
            // Inputs are burned by being transferred to the contract, output is 0
            // Optionally could return a fraction of inputs or a different failure item
        }

        process.claimed = true;
        // Inputs (Elements, Energy) remain in the contract - they are considered 'consumed'/'burned'
        // If you wanted to allow claiming back failed inputs, the ForgingProcess struct would need to store inputs.

        emit ForgingProcessClaimed(_processId, msg.sender);
        // Add more specific events like RefinementSuccess, SynthesisFailure etc.
    }


    /**
     * @summary 22. claimSynthesisOutput
     * @dev Allows the user to claim the output of a completed synthesis process.
     *      Mints/transfers Artifact NFT based on outcome.
     * @param _processId The ID of the completed process.
     */
     function claimSynthesisOutput(uint256 _processId) external whenNotPaused {
        ForgingProcess storage process = forgingProcesses[_processId];
        require(process.user == msg.sender, "Not your process");
        require(process.processType == 1, "Not a synthesis process");
        require(process.vrfFulfilled, "VRF not fulfilled yet");
        require(!process.claimed, "Process already claimed");

        SynthesisRecipe storage recipe = synthesisRecipes[process.recipeId];
        uint256 outputArtifactId = 0; // Default

        if (process.outcome == 1) { // Success
            outputArtifactId = recipe.outputArtifactId;
            // Mint/transfer the Artifact NFT - assumes artifactToken contract supports minting/transfer
            // The target NFT contract needs to be configured to allow this contract to mint/transfer
            artifactToken.safeTransferFrom(address(this), msg.sender, outputArtifactId, ""); // Assumes Artifacts pre-exist or contract supports minting implicitly via transferFrom(0, user, tokenId)
        } else if (process.outcome == 3) { // Critical Success
             // Example: Mint a special version or grant extra item
             outputArtifactId = recipe.outputArtifactId + 1000; // Example: Higher ID for special version
             artifactToken.safeTransferFrom(address(this), msg.sender, outputArtifactId, "");
        } else if (process.outcome == 4) { // Mutation
            // Example: No artifact, but maybe some Particles are returned instead
            // For this simple example, Mutation also results in failure to mint artifact
             // Could add logic here to transfer Particle tokens back
        } else { // Failure (outcome == 2)
            // Inputs (Particles, Energy) remain in the contract (burned). No artifact minted.
        }

        process.claimed = true;
        // Inputs (Particles, Energy) remain in the contract (burned)

        emit ForgingProcessClaimed(_processId, msg.sender);
         if (outputArtifactId > 0) {
             // Assuming the artifact token ID minted/transferred is the outputArtifactId from the recipe or modified
             // A real implementation might need to get the *actual* minted token ID if the NFT contract assigns them sequentially or differently
         }
    }

    // --- Advanced / NFT Interaction ---

     /**
     * @summary 23. enhanceArtifact
     * @dev Allows a user to enhance a specific Artifact NFT they own by locking Particles into it.
     *      Requires user to approve Particle tokens and the Forge contract to be an operator on the Artifact.
     *      Calls the `enhance` function on the target Artifact contract.
     * @param _artifactTokenId The ID of the Artifact NFT to enhance.
     * @param _particleIds Array of Particle token IDs to use for enhancement.
     * @param _particleAmounts Array of amounts for each particle ID.
     * @param _enhancementData Optional data passed to the Artifact contract.
     */
    function enhanceArtifact(
        uint256 _artifactTokenId,
        uint256[] calldata _particleIds,
        uint256[] calldata _particleAmounts,
        bytes calldata _enhancementData
    ) external whenNotPaused {
        // Verify user owns the artifact (basic check, full check is done by NFT contract usually)
        require(artifactToken.ownerOf(_artifactTokenId) == msg.sender, "Caller does not own artifact");
        require(_particleIds.length == _particleAmounts.length, "Particle arrays mismatch");
        require(_particleIds.length > 0, "No particles provided for enhancement");

        // Transfer required particle tokens from the user to this contract
        particleToken.safeBatchTransferFrom(msg.sender, address(this), _particleIds, _particleAmounts, "");

        // Particles are now locked in this contract, associated with this enhancement event.
        // To make this fully featured, need a mapping to track locked particles per artifact ID.
        // For simplicity here, we just burn them or consider them locked forever.
        // A more complex system would track them and potentially allow 'unslotting' or transferring them *with* the NFT.
        // Let's add a placeholder event and assume the particles are 'consumed'.
        // A real system might require the Artifact contract to call back or check this contract's balance/state.

        // Call the enhance function on the target Artifact contract
        artifactToken.enhance(_artifactTokenId, msg.sender, _enhancementData);

        // Note: The `enhance` function on the Artifact contract needs to handle receiving the call,
        // verifying caller (this contract's address), potentially verifying the particle tokens
        // are held by this contract (or rely on the transferFrom call), and updating the NFT's state/metadata.

        // For the scope of this example, we assume `artifactToken.enhance` handles the logic
        // related to the particles being available to this contract address.

        emit ArtifactEnhanced(_artifactTokenId, msg.sender, _nextProcessId++); // Use a temporary ID or separate counter for enhancements
    }

    // --- View Functions (Read-Only) ---

    /**
     * @summary 24. getRefinementRecipe
     * @dev Gets the details of a specific refinement recipe.
     * @param _recipeId The ID of the recipe.
     * @return RefineRecipe struct.
     */
    function getRefinementRecipe(uint256 _recipeId) external view returns (RefineRecipe memory) {
        return refineRecipes[_recipeId];
    }

    /**
     * @summary 25. getSynthesisRecipe
     * @dev Gets the details of a specific synthesis recipe.
     * @param _recipeId The ID of the recipe.
     * @return SynthesisRecipe struct.
     */
    function getSynthesisRecipe(uint256 _recipeId) external view returns (SynthesisRecipe memory) {
        return synthesisRecipes[_recipeId];
    }

     /**
     * @summary 26. getProcessStatus
     * @dev Gets the status and details of a specific forging process.
     * @param _processId The ID of the process.
     * @return ForgingProcess struct.
     */
    function getProcessStatus(uint256 _processId) external view returns (ForgingProcess memory) {
        return forgingProcesses[_processId];
    }

    /**
     * @summary 27. getUserProcessIds
     * @dev Gets the list of process IDs initiated by a user.
     * @param _user The user's address.
     * @return Array of process IDs.
     */
    function getUserProcessIds(address _user) external view returns (uint256[] memory) {
        return userProcessIds[_user];
    }

    /**
     * @summary 28. getOracleInfluenceFactor
     * @dev Gets the current value of the oracle influence factor.
     * @return Current oracle influence factor (0-10000).
     */
    function getOracleInfluenceFactor() external view returns (uint256) {
        return oracleInfluenceFactor;
    }

    /**
     * @summary 29. getUserCooldown
     * @dev Calculates the remaining cooldown time for a user.
     * @param _user The user's address.
     * @return Remaining cooldown in seconds (0 if no cooldown active).
     */
    function getUserCooldown(address _user) external view returns (uint256) {
        uint256 lastProcess = userLastProcessTimestamp[_user];
        if (block.timestamp < lastProcess + processCooldownDuration) {
            return (lastProcess + processCooldownDuration) - block.timestamp;
        }
        return 0;
    }

    // --- ERC1155 Receiver Hook (Optional but good practice if contract might receive ERC1155) ---
    // The Forge pulls tokens using safeBatchTransferFrom, so receiving isn't standard.
    // However, implementing the hook is good practice in case tokens are sent unexpectedly.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Reject unexpected ERC1155 transfers unless logic is added to handle them
        revert("Unexpected ERC1155 reception");
        // return this.onERC1155Received.selector; // Return this selector if you want to accept
    }

     function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Reject unexpected ERC1155 transfers unless logic is added to handle them
         revert("Unexpected ERC1155 batch reception");
        // return this.onERC1155BatchReceived.selector; // Return this selector if you want to accept batch
    }

    // --- Inherited Functions (AccessControl) ---
    // function hasRole(bytes32 role, address account) public view virtual override returns (bool)
    // function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32)
    // function renounceRole(bytes32 role, address account) public virtual override
    // function revokeRole(bytes32 role, address account) public virtual override (Already implemented override)
    // function _setupRole(bytes32 role, address account) internal virtual override (Used in constructor)
    // function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual override

    // --- Inherited Functions (Pausable) ---
    // function paused() public view returns (bool)
    // function _pause() internal virtual (Used in pauseForge)
    // function _unpause() internal virtual (Used in unpauseForge)
    // function _beforeTokenTransfer() internal virtual override (Hook called by OZ tokens) - Not directly used as we call external tokens
    // function _whenNotPaused() internal view virtual override (Modifier)
    // function _whenPaused() internal view virtual override (Modifier)


    // --- Total Functions: 29 (excluding inherited, internal overrides, and hooks) ---
    // Counting based on the summary comments (1-29)
    // If you include standard inherited/overridden public/external functions, the count increases.
    // AccessControl adds: hasRole, getRoleAdmin, renounceRole, revokeRole (already counted grants/revokes for specific roles)
    // Pausable adds: paused
    // VRFConsumerBaseV2 adds: fulfillRandomWords (internal override, already counted)
    // ERC1155Receiver adds: onERC1155Received, onERC1155BatchReceived (hooks)
    // Total public/external functions callable by users/admin/other contracts:
    // 1. setTokenAddresses
    // 2. setVRFParameters
    // 3. withdrawFees
    // 4. pauseForge
    // 5. unpauseForge
    // 6. grantRecipeManager
    // 7. revokeRecipeManager
    // 8. grantOracleUpdater
    // 9. revokeOracleUpdater
    // 10. setProcessCooldownDuration
    // 11. addRefineRecipe
    // 12. updateRefineRecipe
    // 13. removeRefineRecipe
    // 14. addSynthesisRecipe
    // 15. updateSynthesisRecipe
    // 16. removeSynthesisRecipe
    // 17. setOracleInfluenceFactor
    // 18. initiateRefineElements
    // 19. initiateSynthesizeArtifact
    // 21. claimRefinementOutput
    // 22. claimSynthesisOutput
    // 23. enhanceArtifact
    // 24. getRefinementRecipe
    // 25. getSynthesisRecipe
    // 26. getProcessStatus
    // 27. getUserProcessIds
    // 28. getOracleInfluenceFactor
    // 29. getUserCooldown
    // + Inherited from AccessControl: hasRole, getRoleAdmin, renounceRole (3)
    // + Inherited from Pausable: paused (1)
    // + ERC1155Receiver hooks (if made external): onERC1155Received, onERC1155BatchReceived (2 - currently pure/reverting)
    // Total > 20 external functions callable by users/admin/other contracts.

    // --- Potential Enhancements (Beyond 20+ functions) ---
    // - More complex outcome logic (e.g., different mutation outputs per recipe).
    // - Store input token details in the ForgingProcess struct to allow claiming back failed inputs.
    // - Implement a mechanism for users to burn failed processes/inputs.
    // - Add fees for initiating processes (beyond energy cost).
    // - Implement a queueing system if VRF requests are slow or expensive.
    // - Allow cancelling processes before VRF fulfillment.
    // - Make Oracle Influence update push-based from an oracle contract instead of admin pull-based.
    // - Add more detailed events for specific outcomes (Success, Failure, Mutation).
    // - Implement ERC-165 `supportsInterface` for AccessControl, VRFConsumerBaseV2, ERC1155Receiver.
    // - More sophisticated recipe update/removal logic (e.g., prevent removing a recipe if processes are pending).
}
```

**Explanation of Key Parts:**

1.  **Interfaces:** Defines how the contract interacts with external ERC-20, ERC-1155, ERC-721 tokens and a custom `IEnhanceableArtifact` interface for the NFT enhancement feature.
2.  **State Variables:** Stores crucial data like token addresses, VRF parameters, role identifiers, details of ongoing and past forging processes, recipes, the oracle influence factor, and cooldown data.
3.  **Roles:** Uses OpenZeppelin's `AccessControl` to define distinct roles (Admin, Recipe Manager, Oracle Updater) for better permission management than simple `Ownable`.
4.  **ForgingProcess Struct:** Represents a single forging attempt, tracking its type (Refine/Synthesize), recipe used, VRF details, outcome, and claim status.
5.  **Recipes Structs:** Define the inputs, costs, and potential output properties for both refinement and synthesis processes, including base success rates.
6.  **Oracle Influence Factor:** A state variable that `ORACLE_UPDATER_ROLE` can set. The `fulfillRandomWords` logic uses this factor to slightly adjust the probabilistic outcomes, simulating external conditions.
7.  **Chainlink VRF Integration (`VRFConsumerBaseV2`):**
    *   `requestRandomWords`: Called internally by `initiateRefineElements` and `initiateSynthesizeArtifact` to get a random number.
    *   `fulfillRandomWords`: An internal callback automatically triggered by the Chainlink VRF coordinator after the random number is generated. This function reads the random word, determines the outcome based on the random number *and* the `oracleInfluenceFactor`, and updates the process state.
8.  **Initiation Functions (`initiateRefineElements`, `initiateSynthesizeArtifact`):** Handle input token transfers (requiring user approvals beforehand), store process details, and trigger the VRF request. Includes a per-user cooldown.
9.  **Claiming Functions (`claimRefinementOutput`, `claimSynthesisOutput`):** Called by the user *after* `fulfillRandomWords` has completed. These functions check the process outcome and transfer the appropriate output tokens/NFTs (or nothing on failure/mutation based on logic) to the user. Input tokens remain in the contract ("burned").
10. **Recipe Management:** Functions to add, update, and remove recipes, restricted to the `RECIPE_MANAGER_ROLE`.
11. **Oracle Influence Update:** A function (`setOracleInfluenceFactor`) allowing the `ORACLE_UPDATER_ROLE` to change the global influence factor.
12. **NFT Enhancement (`enhanceArtifact`):** Allows a user to send particles to the forge and then calls a specific function (`enhance`) on their target Artifact NFT. This requires the Artifact NFT contract to be designed to receive and handle this call, potentially updating the NFT's state based on the particles provided. The Forge locks/burns the particles.
13. **View Functions:** Provide ways for anyone to query recipe details, process status, user process lists, the current oracle factor, and user cooldowns.
14. **Pausable:** Standard OpenZeppelin functionality to halt sensitive operations in an emergency.
15. **ERC1155Receiver Hooks:** Included as a standard for contracts handling ERC-1155, though the Forge is designed to *pull* tokens via `transferFrom` rather than receive push transfers. The included implementation simply reverts for unexpected incoming transfers.

This contract goes beyond typical examples by combining several advanced concepts: cross-token type interaction, probabilistic crafting influenced by verifiable randomness and an external factor, complex per-user state tracking for ongoing processes, role-based access control, and a specific mechanic for NFT utility/enhancement. It provides a rich framework for a gamified or utility-driven token ecosystem.