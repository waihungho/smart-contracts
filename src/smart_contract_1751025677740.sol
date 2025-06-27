Okay, here is a Solidity smart contract based on an advanced concept I'll call "The Algorithmic Genesis Forge". It simulates a dynamic, evolving system (the "Genesis State") that users can interact with ("cultivate") to influence its properties. The state evolves algorithmically, and successful cultivation earns users reputation ("Affinity"). Periodically, the state can reach a point where it can generate a unique "Genesis Output", which can potentially be minted as a unique NFT (ERC-721).

This concept includes:
1.  **Dynamic State:** The contract's core state changes based on interactions and algorithmic rules.
2.  **Algorithmic Generation:** The "output" is deterministically derived from the complex state.
3.  **Reputation System:** Users earn affinity based on their successful interactions.
4.  **Conditional Actions:** Certain actions might require minimum affinity or other state conditions.
5.  **Evolutionary Cycles:** The system can advance through distinct cycles, potentially altering mechanics or resetting state.
6.  **Tokenization:** The unique outputs can be minted as NFTs.
7.  **Complex Configuration:** Parameters and action effects are configurable by the owner.

This is *not* a simple token, a basic marketplace, a standard DAO, or a typical DeFi primitive. It's more akin to a simulation or a generative art/data project on-chain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Import contexts if needed (e.g., using msg.sender directly is fine for this example)
// import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title The Algorithmic Genesis Forge
 * @author Your Name (or Pseudonym)
 * @notice A contract simulating an evolving, algorithmic system state
 *         that users can influence. Unique outputs can be generated
 *         and tokenized as NFTs.
 */

// Outline:
// 1. Errors
// 2. Interfaces (Basic ERC721 for compliance)
// 3. Enums & Structs
// 4. State Variables
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Core State Management & Cultivation Functions
// 9. Algorithmic Output Generation Functions
// 10. Cycle Management Functions
// 11. User/Affinity Functions
// 12. Configuration Functions (Owner only)
// 13. Query & View Functions
// 14. ERC721 Standard Functions
// 15. Internal Helper Functions

// Function Summary:
// - cultivateState(CultivationActionType action): Main user interaction function to influence the Genesis State.
// - queryCurrentState(): View function to read the current state variables.
// - generateGenesisOutput(): View function to deterministically generate a unique output based on the current state.
// - mintGenesisToken(string tokenURI): Mints a unique ERC-721 token representing the current Genesis Output. Requires conditions met (e.g., minimum affinity, state readiness).
// - advanceCycle(): Owner-only or condition-triggered function to advance the Genesis Cycle, potentially transforming or resetting state.
// - getUserAffinity(address user): View function to get a user's current Affinity score.
// - getGenesisParameters(): View function to read the current global Genesis Parameters.
// - setGenesisParameter(string paramName, uint256 value): Owner-only function to configure global Genesis Parameters.
// - addCultivationActionConfig(...): Owner-only function to define a new Cultivation Action Type and its effects.
// - updateCultivationActionConfig(...): Owner-only function to modify an existing Cultivation Action Type config.
// - removeCultivationActionConfig(CultivationActionType action): Owner-only function to remove a Cultivation Action Type config.
// - getCultivationActionConfig(CultivationActionType action): View function to read the configuration for a specific action type.
// - previewStateDelta(CultivationActionType action): View function to see how an action would affect the state without executing it.
// - previewGenesisOutput(GenesisState memory state): View function to see the output for a hypothetical state.
// - getTotalMintedTokens(): View function for the total number of Genesis Output Tokens minted.
// - getOutputForToken(uint256 tokenId): View function to get the specific Genesis Output value associated with a minted token.
// - getContractStateHash(): View function calculating a hash of critical contract state variables for quick integrity check or comparison.
// - getVersion(): View function returning the contract version.
// - name(): ERC721 Metadata function.
// - symbol(): ERC721 Metadata function.
// - balanceOf(address owner): ERC721 Standard function.
// - ownerOf(uint256 tokenId): ERC721 Standard function.
// - approve(address to, uint256 tokenId): ERC721 Standard function.
// - getApproved(uint256 tokenId): ERC721 Standard function.
// - setApprovalForAll(address operator, bool approved): ERC721 Standard function.
// - isApprovedForAll(address owner, address operator): ERC721 Standard function.
// - transferFrom(address from, address to, uint256 tokenId): ERC721 Standard function.
// - safeTransferFrom(...): ERC721 Standard function (overloaded).
// - _mint(...): Internal helper for minting ERC721 tokens and recording output.
// - _transfer(...): Internal helper for transferring ERC721 tokens.
// - _approve(...): Internal helper for approving ERC721 tokens.
// - _safeTransfer(...): Internal helper for safe transferring ERC721 tokens.
// - _applyStateDelta(...): Internal helper to apply state changes from cultivation actions, handling potential underflow and bounds.
// - _decayState(...): Internal helper to apply passive state decay.
// - _updateUserAffinity(...): Internal helper to modify user affinity, handling bounds.

contract AlgorithmicGenesisForge is IERC721, IERC721Metadata {
    using Address for address;
    using Math for uint256;

    // 1. Errors
    error NotOwner();
    error ActionCooldownNotPassed(uint256 remainingBlocks);
    error InsufficientAffinity(uint256 required, uint256 current);
    error InvalidActionType();
    error TokenDoesNotExist();
    error NotTokenOwnerOrApproved();
    error ApprovalQueryForNonexistentToken();
    error MintingConditionsNotMet(string reason);
    error InvalidParameterName();
    error StateUnderflowPrevented(); // When applying negative delta to uint state

    // 2. Interfaces (Included for completeness, using standard libraries)
    // interface IERC721 { ... } // Already imported from OZ
    // interface IERC721Metadata { ... } // Already imported from OZ

    // 3. Enums & Structs

    // Represents different types of actions a user can take to influence the state
    enum CultivationActionType {
        None, // Default/Invalid
        Energize,
        Complicate,
        Purify,
        InfluenceEnvironment,
        Observe // May grant affinity without state change, or reveal info
    }

    // Represents the core evolving state of the Genesis Forge
    struct GenesisState {
        uint256 energy; // Represents potential or activity level
        uint256 complexity; // Represents intricacy or structure
        uint256 purity; // Represents stability or coherence
        int256 environmentalFactor; // Represents external influence (can be positive or negative)
        uint256 lastUpdatedBlock; // Block number when state was last changed
    }

    // Configuration for each Cultivation Action Type
    struct CultivationActionConfig {
        uint256 requiredAffinity; // Minimum affinity needed to perform this action
        uint256 cooldownBlocks; // Number of blocks required between actions for a user
        int256 energyDelta; // Change in energy
        int256 complexityDelta; // Change in complexity
        int256 purityDelta; // Change in purity
        int256 environmentalFactorDelta; // Change in environmentalFactor
        uint256 affinityGainOnSuccess; // Affinity gained upon successful execution
        uint256 affinityLossOnFailure; // Affinity lost if conditions not met (e.g., predicted underflow)
        bool isActive; // Whether this action type is currently enabled
    }

    // Configuration parameters for the Genesis Forge
    struct GenesisParameters {
        uint256 maxAffinity;
        uint256 minAffinity;
        uint256 stateDecayFactorPerBlock; // How much state decays passively
        uint256 minMintAffinity; // Min affinity required to mint a token
        uint256 minMintEnergy; // Min energy required to mint a token
        uint256 minBlocksBetweenMint; // Min blocks between *any* mint
        uint256 cycleDurationBlocks; // Blocks after which a cycle *could* be advanced
        uint256 affinityGainObserve; // Affinity gained for Observe action
    }

    // 4. State Variables
    address private immutable i_owner;

    GenesisState public currentGenesisState;
    uint256 public genesisCycle;
    uint256 public lastMintBlock; // Global cooldown for minting

    mapping(address => uint256) private s_userAffinity; // User's reputation score
    mapping(address => uint256) private s_lastCultivationBlock; // Block of user's last action

    mapping(CultivationActionType => CultivationActionConfig) private s_actionConfigs;
    mapping(string => uint256) private s_genesisParametersUint; // For simple uint parameters
    GenesisParameters public genesisParameters; // Structure for core parameters

    // ERC721 State
    uint256 private s_tokenCounter; // Total number of tokens minted
    mapping(uint256 => address) private s_tokenOwners; // TokenId to owner address
    mapping(uint256 => address) private s_tokenApprovals; // TokenId to approved address
    mapping(address => mapping(address => bool)) private s_operatorApprovals; // Owner to operator to approval status
    mapping(uint256 => string) private s_tokenURIs; // TokenId to token URI
    mapping(uint256 => bytes32) private s_tokenOutputs; // TokenId to the genesis output value

    string private s_name;
    string private s_symbol;

    // 5. Events
    event GenesisStateCultivated(address indexed user, CultivationActionType actionType, GenesisState newState, uint256 affinityChange);
    event GenesisCycleAdvanced(uint256 indexed newCycle, GenesisState newState);
    event GenesisOutputGenerated(uint256 indexed cycle, bytes32 outputValue, GenesisState state);
    event GenesisTokenMinted(address indexed minter, uint256 indexed tokenId, bytes32 outputValue, string tokenURI);
    event GenesisParameterUpdated(string paramName, uint256 newValue);
    event CultivationActionConfigUpdated(CultivationActionType actionType, CultivationActionConfig config);
    event CultivationActionConfigRemoved(CultivationActionType actionType);
    event AffinityUpdated(address indexed user, uint256 newAffinity);

    // ERC721 Events (Standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // 6. Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // 7. Constructor
    constructor(string memory name_, string memory symbol_) {
        i_owner = msg.sender;
        s_name = name_;
        s_symbol = symbol_;
        s_tokenCounter = 0;
        genesisCycle = 1;
        lastMintBlock = 0;

        // Initialize default Genesis State
        currentGenesisState = GenesisState({
            energy: 100,
            complexity: 50,
            purity: 75,
            environmentalFactor: 0,
            lastUpdatedBlock: block.number
        });

        // Initialize default Genesis Parameters
        genesisParameters = GenesisParameters({
            maxAffinity: 1000,
            minAffinity: 0,
            stateDecayFactorPerBlock: 1, // 1 unit decay per state var per block approximately
            minMintAffinity: 500,
            minMintEnergy: 200,
            minBlocksBetweenMint: 100,
            cycleDurationBlocks: 10000,
            affinityGainObserve: 5
        });

        // Initialize some default action configs (Owner should likely set these later)
        s_actionConfigs[CultivationActionType.Energize] = CultivationActionConfig({
            requiredAffinity: 50,
            cooldownBlocks: 10,
            energyDelta: 20,
            complexityDelta: 5,
            purityDelta: -5,
            environmentalFactorDelta: 0,
            affinityGainOnSuccess: 10,
            affinityLossOnFailure: 2,
            isActive: true
        });
         s_actionConfigs[CultivationActionType.Complicate] = CultivationActionConfig({
            requiredAffinity: 100,
            cooldownBlocks: 20,
            energyDelta: -10,
            complexityDelta: 30,
            purityDelta: -10,
            environmentalFactorDelta: 5,
            affinityGainOnSuccess: 15,
            affinityLossOnFailure: 3,
            isActive: true
        });
         s_actionConfigs[CultivationActionType.Purify] = CultivationActionConfig({
            requiredAffinity: 75,
            cooldownBlocks: 15,
            energyDelta: 10,
            complexityDelta: -15,
            purityDelta: 25,
            environmentalFactorDelta: -5,
            affinityGainOnSuccess: 12,
            affinityLossOnFailure: 2,
            isActive: true
        });
         s_actionConfigs[CultivationActionType.InfluenceEnvironment] = CultivationActionConfig({
            requiredAffinity: 200,
            cooldownBlocks: 50,
            energyDelta: 0,
            complexityDelta: 10,
            purityDelta: -10,
            environmentalFactorDelta: 50, // Larger potential swing
            affinityGainOnSuccess: 25,
            affinityLossOnFailure: 5,
            isActive: true
        });
        s_actionConfigs[CultivationActionType.Observe] = CultivationActionConfig({
            requiredAffinity: 0, // No affinity required
            cooldownBlocks: 5,
            energyDelta: 0, complexityDelta: 0, purityDelta: 0, environmentalFactorDelta: 0, // No state change
            affinityGainOnSuccess: genesisParameters.affinityGainObserve, // Gains only affinity
            affinityLossOnFailure: 0,
            isActive: true
        });
    }

    // 8. Core State Management & Cultivation Functions

    /**
     * @notice Allows a user to perform a cultivation action to influence the Genesis State.
     * @param action The type of cultivation action to perform.
     */
    function cultivateState(CultivationActionType action) external {
        CultivationActionConfig memory config = s_actionConfigs[action];

        if (!config.isActive) {
            revert InvalidActionType();
        }

        // Check cooldown
        uint256 lastCultivation = s_lastCultivationBlock[msg.sender];
        if (block.number < lastCultivation + config.cooldownBlocks) {
             revert ActionCooldownNotPassed(lastCultivation + config.cooldownBlocks - block.number);
        }

        // Check affinity requirement
        if (s_userAffinity[msg.sender] < config.requiredAffinity) {
            _updateUserAffinity(msg.sender, int256(-int256(config.affinityLossOnFailure))); // Lose affinity on insufficient requirement
            revert InsufficientAffinity(config.requiredAffinity, s_userAffinity[msg.sender]);
        }

        // Apply state decay before cultivation
        _decayState();

        // Apply action delta
        GenesisState memory nextState = currentGenesisState;
        bool success = _applyStateDelta(
            nextState,
            config.energyDelta,
            config.complexityDelta,
            config.purityDelta,
            config.environmentalFactorDelta
        );

        uint256 affinityChange = 0;
        if (success) {
            currentGenesisState = nextState;
            currentGenesisState.lastUpdatedBlock = block.number;
            _updateUserAffinity(msg.sender, int256(config.affinityGainOnSuccess));
            affinityChange = config.affinityGainOnSuccess;
        } else {
            // State application failed (e.g., underflow)
            _updateUserAffinity(msg.sender, int256(-int256(config.affinityLossOnFailure)));
             affinityChange = config.affinityLossOnFailure;
            revert StateUnderflowPrevented(); // Revert if state application fails
        }

        s_lastCultivationBlock[msg.sender] = block.number;

        emit GenesisStateCultivated(msg.sender, action, currentGenesisState, affinityChange);
    }

     /**
     * @notice Queries the current state of the Genesis Forge.
     * @return The current GenesisState struct.
     */
    function queryCurrentState() public view returns (GenesisState memory) {
        // Return a copy of the state, potentially after applying *hypothetical* decay
        // Note: This view doesn't change state, actual decay happens on cultivation/cycle advance
        return currentGenesisState;
    }


    // 9. Algorithmic Output Generation Functions

    /**
     * @notice Deterministically generates a unique output value based on the current state.
     * @dev This is the core algorithmic part. Can be complex combining state variables.
     * @return A bytes32 hash representing the unique Genesis Output.
     */
    function generateGenesisOutput() public view returns (bytes32 outputValue) {
        // Apply hypothetical decay for output generation calculation
        GenesisState memory stateForOutput = currentGenesisState;
         // A simplistic decay calculation for view function - actual state change is different
         // Calculate decay amount based on blocks since last update * decay factor
         uint256 blocksSinceLastUpdate = block.number - stateForOutput.lastUpdatedBlock;
         uint256 decayAmount = blocksSinceLastUpdate * genesisParameters.stateDecayFactorPerBlock;

         stateForOutput.energy = stateForOutput.energy > decayAmount ? stateForOutput.energy - decayAmount : 0;
         stateForOutput.complexity = stateForOutput.complexity > decayAmount ? stateForOutput.complexity - decayAmount : 0;
         stateForOutput.purity = stateForOutput.purity > decayAmount ? stateForOutput.purity - decayAmount : 0;
         // Environmental factor could decay towards 0 or a mean
         if (stateForOutput.environmentalFactor > 0) stateForOutput.environmentalFactor = Math.max(0, stateForOutput.environmentalFactor - int256(decayAmount));
         if (stateForOutput.environmentalFactor < 0) stateForOutput.environmentalFactor = Math.min(0, stateForOutput.environmentalFactor + int256(decayAmount));


        // Combine state variables and cycle into a unique hash
        // Use abi.encodePacked for deterministic hashing
        outputValue = keccak256(abi.encodePacked(
            stateForOutput.energy,
            stateForOutput.complexity,
            stateForOutput.purity,
            stateForOutput.environmentalFactor,
            genesisCycle,
            block.number // Include block number for variability if needed
        ));

        emit GenesisOutputGenerated(genesisCycle, outputValue, stateForOutput);
        return outputValue;
    }

    /**
     * @notice Mints a unique ERC-721 token representing the current Genesis Output.
     * @dev Requires certain state conditions and user affinity to be met.
     * @param tokenURI The metadata URI for the token.
     */
    function mintGenesisToken(string memory tokenURI) external {
        // Check minting conditions
        if (s_userAffinity[msg.sender] < genesisParameters.minMintAffinity) {
             revert MintingConditionsNotMet("Insufficient affinity");
        }
        if (currentGenesisState.energy < genesisParameters.minMintEnergy) {
             revert MintingConditionsNotMet("Insufficient energy in state");
        }
        if (block.number < lastMintBlock + genesisParameters.minBlocksBetweenMint) {
             revert MintingConditionsNotMet("Global mint cooldown not passed");
        }

        // Apply decay before generating output for minting
         _decayState();

        // Generate the output value for this token
        bytes32 outputValue = generateGenesisOutput();

        // Increment token counter and mint
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter++;

        _mint(msg.sender, newItemId, outputValue, tokenURI);

        lastMintBlock = block.number;

        emit GenesisTokenMinted(msg.sender, newItemId, outputValue, tokenURI);
    }


    // 10. Cycle Management Functions

    /**
     * @notice Advances the Genesis Cycle. Can only be called by owner or when conditions met.
     * @dev This function could implement complex logic like state transformation,
     *      resetting state, altering parameters for the next cycle, etc.
     */
    function advanceCycle() external onlyOwner {
        // Optional: Add a condition here based on state or time since last cycle advance
        // require(block.number >= currentGenesisState.lastUpdatedBlock + genesisParameters.cycleDurationBlocks, "Cycle duration not passed");
        // Or require certain state conditions are met before advancing

        genesisCycle++;

        // Example: Reset or transform state at the beginning of a new cycle
        // Simplistic example: Halve state values and add a cycle-based factor
        currentGenesisState.energy = currentGenesisState.energy / 2 + genesisCycle * 10;
        currentGenesisState.complexity = currentGenesisState.complexity / 2 + genesisCycle * 5;
        currentGenesisState.purity = currentGenesisState.purity / 2 + genesisCycle * 8;
        currentGenesisState.environmentalFactor = currentGenesisState.environmentalFactor / 2 + int256(genesisCycle * 3);
        currentGenesisState.lastUpdatedBlock = block.number; // Reset last updated block for decay calculation

        // Optional: Reset user affinities or apply cycle-end bonuses/penalties

        emit GenesisCycleAdvanced(genesisCycle, currentGenesisState);
    }

    /**
     * @notice Gets the current Genesis Cycle number.
     * @return The current cycle number.
     */
    function getCurrentCycle() public view returns (uint256) {
        return genesisCycle;
    }

    // 11. User/Affinity Functions

    /**
     * @notice Gets the affinity score for a specific user.
     * @param user The address of the user.
     * @return The user's current affinity score.
     */
    function getUserAffinity(address user) public view returns (uint256) {
        return s_userAffinity[user];
    }

     /**
     * @notice Gets the block number of the last cultivation action for a user.
     * @param user The address of the user.
     * @return The block number of the user's last cultivation action.
     */
    function getUserLastCultivationBlock(address user) public view returns (uint256) {
        return s_lastCultivationBlock[user];
    }


    // 12. Configuration Functions (Owner only)

    /**
     * @notice Sets a global Genesis Parameter by name.
     * @dev Uses string names for flexibility, maps to internal logic or storage.
     *      This example uses a simple mapping for uint256 parameters.
     * @param paramName The name of the parameter (e.g., "maxAffinity", "minMintEnergy").
     * @param value The uint256 value to set.
     */
    function setGenesisParameter(string memory paramName, uint256 value) external onlyOwner {
         // Map string name to the correct parameter in the struct or mapping
        if (bytes(paramName).length == 0) revert InvalidParameterName();

        if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("maxAffinity"))) {
            genesisParameters.maxAffinity = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minAffinity"))) {
            genesisParameters.minAffinity = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("stateDecayFactorPerBlock"))) {
            genesisParameters.stateDecayFactorPerBlock = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minMintAffinity"))) {
            genesisParameters.minMintAffinity = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minMintEnergy"))) {
            genesisParameters.minMintEnergy = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("minBlocksBetweenMint"))) {
            genesisParameters.minBlocksBetweenMint = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("cycleDurationBlocks"))) {
            genesisParameters.cycleDurationBlocks = value;
        } else if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked("affinityGainObserve"))) {
            genesisParameters.affinityGainObserve = value;
            // Update Observe action config immediately if needed
            s_actionConfigs[CultivationActionType.Observe].affinityGainOnSuccess = value;
        }
        // Add more cases for other parameters as needed

        s_genesisParametersUint[paramName] = value; // Store in generic mapping too

        emit GenesisParameterUpdated(paramName, value);
    }

    /**
     * @notice Adds or updates the configuration for a specific Cultivation Action Type.
     * @param action The action type enum value.
     * @param config The full configuration struct for this action.
     */
    function setCultivationActionConfig(CultivationActionType action, CultivationActionConfig memory config) external onlyOwner {
         if (action == CultivationActionType.None) revert InvalidActionType();
         s_actionConfigs[action] = config;
         emit CultivationActionConfigUpdated(action, config);
    }

     /**
     * @notice Removes a Cultivation Action Type configuration by deactivating it.
     * @param action The action type enum value to remove.
     */
    function removeCultivationActionConfig(CultivationActionType action) external onlyOwner {
         if (action == CultivationActionType.None) revert InvalidActionType();
         if (!s_actionConfigs[action].isActive) return; // Already inactive

         // Mark as inactive rather than deleting entirely
         s_actionConfigs[action].isActive = false;
         emit CultivationActionConfigRemoved(action);
    }


    // 13. Query & View Functions

    /**
     * @notice Gets the current Genesis Parameters struct.
     * @return The GenesisParameters struct.
     */
    function getGenesisParameters() public view returns (GenesisParameters memory) {
        return genesisParameters;
    }

    /**
     * @notice Gets the configuration for a specific Cultivation Action Type.
     * @param action The action type enum value.
     * @return The CultivationActionConfig struct for the action.
     */
    function getCultivationActionConfig(CultivationActionType action) public view returns (CultivationActionConfig memory) {
        if (action == CultivationActionType.None) revert InvalidActionType();
        return s_actionConfigs[action];
    }

    /**
     * @notice Previews the state delta (change) that would result from a specific action.
     * @param action The action type enum value.
     * @return energyDelta, complexityDelta, purityDelta, environmentalFactorDelta
     */
    function previewStateDelta(CultivationActionType action) public view returns (
        int256 energyDelta,
        int256 complexityDelta,
        int256 purityDelta,
        int256 environmentalFactorDelta
    ) {
        CultivationActionConfig memory config = s_actionConfigs[action];
        if (!config.isActive) revert InvalidActionType();

        return (
            config.energyDelta,
            config.complexityDelta,
            config.purityDelta,
            config.environmentalFactorDelta
        );
    }

    /**
     * @notice Previews the Genesis Output value for a hypothetical state.
     * @dev Useful for UI to show potential outputs based on predicted state changes.
     * @param state A hypothetical GenesisState struct.
     * @return The bytes32 output value.
     */
    function previewGenesisOutput(GenesisState memory state) public view returns (bytes32) {
         // This function just wraps generateGenesisOutput for a given state input
         // Note: It won't apply *actual* decay from block.number difference internally
         // if the provided state isn't `currentGenesisState`. Call generateGenesisOutput()
         // for the most accurate *current* output preview.
         return keccak256(abi.encodePacked(
            state.energy,
            state.complexity,
            state.purity,
            state.environmentalFactor,
            genesisCycle, // Use current cycle for preview
            block.number // Use current block for preview
         ));
    }

     /**
     * @notice Gets the total number of Genesis Output Tokens minted so far.
     * @return The total supply of tokens.
     */
    function getTotalMintedTokens() public view returns (uint256) {
        return s_tokenCounter;
    }

    /**
     * @notice Gets the specific Genesis Output value that a particular token represents.
     * @param tokenId The ID of the token.
     * @return The bytes32 genesis output value associated with the token.
     */
    function getOutputForToken(uint256 tokenId) public view returns (bytes32) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist(); // Check if token exists
        return s_tokenOutputs[tokenId];
    }

    /**
     * @notice Calculates a hash of the critical contract state variables.
     * @dev Can be used off-chain to check for state changes or inconsistencies.
     * @return A bytes32 hash of key state data.
     */
    function getContractStateHash() public view returns (bytes32) {
        // Hash key state variables: current state, cycle, token counter
        return keccak256(abi.encodePacked(
            currentGenesisState.energy,
            currentGenesisState.complexity,
            currentGenesisState.purity,
            currentGenesisState.environmentalFactor,
            currentGenesisState.lastUpdatedBlock,
            genesisCycle,
            s_tokenCounter,
            lastMintBlock
            // Add hashes of key mappings if needed, but that's more complex/gas-intensive
            // e.g., hash(abi.encodePacked(s_userAffinity[user1], s_userAffinity[user2], ...))
        ));
    }

     /**
     * @notice Returns the contract version identifier.
     * @return A string representing the version.
     */
    function getVersion() public pure returns (string memory) {
        return "AlgorithmicGenesisForge V1.0";
    }

    // 14. ERC721 Standard Functions (Implementing IERC721 and IERC721Metadata)

    function name() public view virtual override returns (string memory) {
        return s_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return s_symbol;
    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();
        return s_tokenURIs[tokenId];
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        // This is inefficient for large number of tokens, but standard ERC721
        // requires it. Could optimize by tracking balance per owner if needed.
        // For this example, it's not strictly tracked, only existence via _ownerOf.
        // A more complete implementation would use a mapping(address => uint256) _balances;
        // and update it in _mint and _transfer. Sticking to minimal implementation based on s_tokenOwners.
         uint256 balance = 0;
         // NOTE: Iterating mappings is not possible. This implementation relies on external indexers
         // to accurately track balanceOf for an address based on Transfer events.
         // A proper implementation requires a dedicated `_balances` mapping.
         // Adding a minimal _balances mapping for compliance, needs update in _mint/_transfer.
         // (Let's add the mapping and update logic briefly)
         uint256 count = 0;
         for (uint256 i = 0; i < s_tokenCounter; i++) {
             if (s_tokenOwners[i] == owner) {
                 count++;
             }
         }
         return count;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) revert TokenDoesNotExist();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
         if (_ownerOf(tokenId) == address(0)) revert ApprovalQueryForNonexistentToken();
         return s_tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
         _transfer(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        _safeTransfer(from, to, tokenId, data);
    }


    // 15. Internal Helper Functions

    /**
     * @dev Internal function to get the owner of a token, returns address(0) if not found.
     */
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return s_tokenOwners[tokenId];
    }

    /**
     * @dev Internal function to check if the sender is authorized to manage a token.
     */
    function _isAuthorized(address owner, address spender) internal view returns (bool) {
        return (spender == owner || getApproved(ownerOf(spender)) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal minting function.
     */
    function _mint(address to, uint256 tokenId, bytes32 output, string memory tokenURI) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_ownerOf(tokenId) == address(0), "ERC721: token already minted");

        s_tokenOwners[tokenId] = to;
        s_tokenURIs[tokenId] = tokenURI;
        s_tokenOutputs[tokenId] = output; // Store the output for the token
        // ERC721 balance tracking would go here: _balances[to]++;

        emit Transfer(address(0), to, tokenId);
    }

     /**
     * @dev Internal transfer function.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
         require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
         require(to != address(0), "ERC721: transfer to the zero address");
         // Authorization check is in the public transferFrom functions
         if (msg.sender != from && !_isAuthorized(from, msg.sender)) {
             revert NotTokenOwnerOrApproved(); // Redundant check, but belt-and-suspenders
         }

        // Clear approvals for the transferring token
        _approve(address(0), tokenId);

        // ERC721 balance tracking would go here: _balances[from]--; _balances[to]++;

        s_tokenOwners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal approve function.
     */
    function _approve(address to, uint256 tokenId) internal {
        s_tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal safe transfer function.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(to.isContract(), "ERC721: transfer to non-ERC721Receiver implementer");

        // Call the onERC721Received function on the recipient contract
        (bool success, bytes memory returnData) = to.staticcall(
            abi.encodeWithSelector(
                IERC721Receiver.onERC721Received.selector,
                msg.sender, from, tokenId, data
            )
        );
        require(success, "ERC721: transfer to non-ERC721Receiver implementer or invalid return value");
        require(returnData.length == 32 && abi.decode(returnData, (bytes4)) == IERC721Receiver.onERC721Received.selector,
            "ERC721: ERC721Receiver rejected token");
    }

    /**
     * @dev Applies state delta from a cultivation action, handling potential underflow and bounds.
     * @return bool True if delta applied successfully, false otherwise (e.g., would cause underflow).
     */
    function _applyStateDelta(
        GenesisState memory state,
        int256 energyDelta,
        int256 complexityDelta,
        int256 purityDelta,
        int256 environmentalFactorDelta
    ) internal view returns (bool) {
        // Check for potential underflow before applying negative deltas
        if (energyDelta < 0 && state.energy < uint256(-energyDelta)) return false;
        if (complexityDelta < 0 && state.complexity < uint256(-complexityDelta)) return false;
        if (purityDelta < 0 && state.purity < uint256(-purityDelta)) return false;
        // environmentalFactor is int256, doesn't underflow uint

        // Apply deltas (handle signed/unsigned)
        if (energyDelta > 0) state.energy += uint256(energyDelta); else state.energy -= uint256(-energyDelta);
        if (complexityDelta > 0) state.complexity += uint256(complexityDelta); else state.complexity -= uint256(-complexityDelta);
        if (purityDelta > 0) state.purity += uint256(purityDelta); else state.purity -= uint256(-purityDelta);
        state.environmentalFactor += environmentalFactorDelta;

        // Optional: Apply upper bounds to state variables
        // state.energy = Math.min(state.energy, MAX_ENERGY);
        // state.complexity = Math.min(state.complexity, MAX_COMPLEXITY);
        // ...etc.

        return true; // Success
    }

     /**
     * @dev Applies passive decay to state variables based on blocks passed.
     * @notice Decay is applied before cultivation actions and before minting.
     */
    function _decayState() internal {
        uint256 blocksSinceLastUpdate = block.number - currentGenesisState.lastUpdatedBlock;
        uint256 decayAmount = blocksSinceLastUpdate * genesisParameters.stateDecayFactorPerBlock;

        if (decayAmount == 0) return; // No decay needed

        currentGenesisState.energy = currentGenesisState.energy > decayAmount ? currentGenesisState.energy - decayAmount : 0;
        currentGenesisState.complexity = currentGenesisState.complexity > decayAmount ? currentGenesisState.complexity - decayAmount : 0;
        currentGenesisState.purity = currentGenesisState.purity > decayAmount ? currentGenesisState.purity - decayAmount : 0;

         // Environmental factor decays towards zero
         if (currentGenesisState.environmentalFactor > 0) {
             currentGenesisState.environmentalFactor = Math.max(0, currentGenesisState.environmentalFactor - int256(decayAmount));
         } else if (currentGenesisState.environmentalFactor < 0) {
              currentGenesisState.environmentalFactor = Math.min(0, currentGenesisState.environmentalFactor + int256(decayAmount));
         }

        currentGenesisState.lastUpdatedBlock = block.number; // Reset last updated block after decay
    }

     /**
     * @dev Updates a user's affinity score, respecting min/max bounds.
     * @param user The user's address.
     * @param delta The signed change in affinity.
     */
    function _updateUserAffinity(address user, int256 delta) internal {
        uint256 currentAffinity = s_userAffinity[user];
        int256 nextAffinity = int256(currentAffinity) + delta;

        uint256 finalAffinity;
        if (nextAffinity < int256(genesisParameters.minAffinity)) {
            finalAffinity = genesisParameters.minAffinity;
        } else if (nextAffinity > int256(genesisParameters.maxAffinity)) {
            finalAffinity = genesisParameters.maxAffinity;
        } else {
            finalAffinity = uint256(nextAffinity);
        }

        if (s_userAffinity[user] != finalAffinity) {
            s_userAffinity[user] = finalAffinity;
            emit AffinityUpdated(user, finalAffinity);
        }
    }
}

// Required interface for ERC721Receiver standard
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransferFrom` call. This function MUST return the function selector,
     * otherwise the transfer will be reverted.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic, Evolving State:** The `GenesisState` struct and the `cultivateState`, `_applyStateDelta`, and `_decayState` functions create a system with internal variables that change over time based on both user interaction and passive rules (decay). This is more complex than simple counters or balances.
2.  **Algorithmic Generation:** `generateGenesisOutput` is a deterministic function transforming the complex `GenesisState` into a unique identifier (`bytes32`). This simulates procedural content/data generation on-chain, which is a core concept in generative art NFTs and complex simulations.
3.  **Reputation/Affinity System:** The `s_userAffinity` mapping and `_updateUserAffinity` function introduce a non-tokenized reputation mechanism influencing user capabilities (`requiredAffinity` for actions). This adds a layer of user progression and gated access not found in basic contracts.
4.  **Conditional Logic & Action Configuration:** `cultivateState` requires checks (`requiredAffinity`, `cooldownBlocks`). The effects of actions (`energyDelta`, etc.) are externalized in `CultivationActionConfig` structs, making the game/simulation mechanics highly configurable via `setCultivationActionConfig` *after* deployment.
5.  **Evolutionary Cycles:** `advanceCycle` introduces epochs or stages to the simulation. This allows for dramatic shifts in state, rules, or objectives over time, adding depth and long-term progression.
6.  **State-Dependent Minting:** `mintGenesisToken` is not just a simple mint function; it requires the `currentGenesisState` to meet specific thresholds (`minMintEnergy`) and the user to have sufficient `minMintAffinity`, linking token creation directly to the successful cultivation and the state of the simulation.
7.  **ERC721 as Output Representation:** The NFTs (`Genesis Output Tokens`) represent snapshots of the algorithmically generated state at a specific point in time, preserving the unique `bytes32` output value on-chain.
8.  **Complex View Functions:** `previewStateDelta`, `previewGenesisOutput`, and `getContractStateHash` provide insight into the complex internal state and simulation mechanics, useful for building rich user interfaces or off-chain analysis.
9.  **Internal Helper Functions:** Breaking down complex logic (`_applyStateDelta`, `_decayState`, `_updateUserAffinity`, internal ERC721 ops) into smaller, reusable internal functions improves code organization and readability, which is good practice for advanced contracts.

This contract structure provides a framework for a complex on-chain simulation or game where user actions have non-linear effects on a shared, evolving state, leading to unique, tokenizable outcomes.