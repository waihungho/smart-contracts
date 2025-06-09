Okay, here is a smart contract combining concepts like evolving NFT state, oracle interaction simulation, predictive functions, parameter tuning, and passive accrual, implemented as "Cosmic Catalysts". It builds upon the ERC-721 standard but adds a significant layer of custom logic and state management for each token.

This contract is *not* a direct copy of standard open-source templates like basic ERC-721, simple staking, or governance tokens. It introduces custom state attributes per token (`charge`, `resonance`, `stability`), mechanisms for user interaction (`tune`, `attune`), external data dependency (`align` via simulated oracle), internal processes (`decay`, `charge` accumulation), evolution, predictive analysis, and dynamic parameters.

**Disclaimer:** This contract is for educational and illustrative purposes. It simulates external oracle interaction and time-based processes. Deploying complex contracts like this to a production environment requires rigorous auditing, testing, and careful consideration of real-world oracle implementations, gas costs, and potential attack vectors.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Contract Outline & Function Summary ---
// Concept: Cosmic Catalysts - ERC721 NFTs with dynamic, evolving states influenced by user interaction, time, and simulated external data (oracle).
// Each Catalyst has attributes (Charge, Resonance, Stability) and accumulates Energy.
// Catalysts can evolve through stages based on their state and actions.
// A simulated oracle influences Catalyst state through 'alignment'.
// Contract parameters are tunable by the owner.
// Includes predictive functions to analyze potential outcomes.

// STATE VARIABLES:
// - _catalysts: Mapping from tokenId to CatalystState struct. Stores the state of each NFT.
// - _currentTokenId: Counter for minting new tokens.
// - oracleAddress: Address of the simulated oracle (admin settable).
// - parameters: Mapping for dynamic contract parameters (decay rates, energy rates, etc.).
// - evolutionRequirements: Mapping storing min stats needed for evolution stages.

// STRUCTS:
// - CatalystState: Defines the attributes and state of a single Catalyst NFT.

// EVENTS:
// - CatalystMinted: Signals a new Catalyst was created.
// - CatalystStateUpdated: Indicates a Catalyst's state attributes changed.
// - EnergyClaimed: Records when energy is claimed from a Catalyst.
// - CatalystEvolved: Logs when a Catalyst reaches a new evolutionary stage.
// - ParametersUpdated: Signals a contract parameter was changed.
// - OracleAddressUpdated: Records the setting of a new oracle address.

// FUNCTIONS (26 Custom + 9 ERC721 = 35+ Total):

// Core ERC721 Functions (Implemented via Inheritance):
// 1. supportsInterface(bytes4 interfaceId) -> bool
// 2. balanceOf(address owner) -> uint256
// 3. ownerOf(uint256 tokenId) -> address
// 4. approve(address to, uint256 tokenId)
// 5. getApproved(uint256 tokenId) -> address
// 6. setApprovalForAll(address operator, bool approved)
// 7. isApprovedForAll(address owner, address operator) -> bool
// 8. transferFrom(address from, address to, uint256 tokenId)
// 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// 10. safeTransferFrom(address from, address to, uint256 tokenId)

// Minting Functions:
// 11. constructor(string name, string symbol): Initializes the contract, ERC721, Pausable, Ownable.
// 12. mintCatalyst(address to): Mints a new Catalyst NFT with initial state for an address.

// State Query Functions:
// 13. getTokenState(uint256 tokenId): Returns the current state struct for a specific Catalyst.
// 14. getEnergyBalance(uint256 tokenId): Calculates and returns the current accumulated energy for a Catalyst.
// 15. getGlobalCatalystStats(): Returns aggregated stats across all existing Catalysts (simulated/placeholder).
// 16. getParameter(bytes32 key): Returns the value of a dynamic contract parameter.
// 17. getEvolutionRequirements(uint8 stage): Returns the minimum stats required for a given evolution stage.
// 18. checkEvolutionEligibility(uint256 tokenId): Checks if a Catalyst meets the criteria for evolution.

// User Interaction Functions:
// 19. tuneCatalyst(uint256 tokenId): User action to adjust Catalyst state (e.g., increase Resonance, decrease Stability). Requires token ownership.
// 20. attuneCatalyst(uint256 tokenId): User action to adjust Catalyst state differently (e.g., increase Stability, decrease Charge). Requires token ownership.
// 21. infuseCatalyst(uint256 tokenId): Allows user to send Ether to boost Catalyst attributes. Requires token ownership.
// 22. claimEnergy(uint256 tokenId): Allows user to claim accumulated energy from a Catalyst. Requires token ownership.
// 23. evolveCatalyst(uint256 tokenId): Attempts to evolve a Catalyst to the next stage if eligible. Requires token ownership.
// 24. batchTuneCatalysts(uint256[] tokenIds): Allows tuning multiple owned Catalysts in a single transaction.

// Internal/Time-Based/External Interaction Functions:
// 25. _calculateEnergyAccrued(uint256 tokenId): Internal helper to calculate energy accumulated since last interaction.
// 26. _applyDecay(uint256 tokenId): Internal helper to apply state decay based on time since last interaction.
// 27. alignCatalyst(uint256 tokenId, int256 oracleValue): Simulates external data influencing Catalyst state. Can be called by anyone (or restricted via modifier/role).
// 28. decayCatalysts(uint256[] tokenIds): Allows anyone (or restricted) to trigger decay for a batch of Catalysts (e.g., for off-chain automation).

// Predictive Functions (Read-Only Simulation):
// 29. predictAlignmentOutcome(uint256 tokenId, int256 hypotheticalOracleValue): Simulates the state change from alignment without modifying state.

// Admin Functions (Owner Only):
// 30. setOracleAddress(address _oracle): Sets the address of the simulated oracle.
// 31. setParameter(bytes32 key, uint256 value): Sets a dynamic contract parameter.
// 32. setEvolutionRequirements(uint8 stage, uint256 minCharge, uint256 minResonance, uint256 minStability): Sets requirements for evolving to a specific stage.
// 33. pause(): Pauses contract interactions (except admin functions).
// 34. unpause(): Unpauses the contract.
// 35. withdrawFunds(): Withdraws accumulated Ether from the contract.

// Modifiers:
// - onlyTokenOwner(uint256 tokenId): Ensures the caller owns the specified token.

contract CosmicCatalysts is ERC721, Ownable, Pausable, ReentrancyGuard {

    struct CatalystState {
        uint256 charge;      // Represents power/potential
        uint256 resonance;   // Represents alignment/sensitivity
        uint256 stability;   // Represents resilience/integrity
        uint8 stage;         // Evolutionary stage (0, 1, 2, ...)
        uint256 lastInteraction; // Timestamp of last state-changing interaction
        uint256 energyAccrued; // Accumulated energy ready to be claimed
    }

    mapping(uint256 => CatalystState) private _catalysts;
    uint256 private _currentTokenId;

    address public oracleAddress; // Address expected to provide oracle data (simulated)

    // Dynamic parameters storage: e.g., keccak256("decayRate"), keccak256("energyPerSecond"), keccak256("infuseMultiplier")
    mapping(bytes32 => uint256) public parameters;

    // Evolution requirements: stage => minCharge, minResonance, minStability
    mapping(uint8 => struct { uint256 minCharge; uint256 minResonance; uint256 minStability; }) public evolutionRequirements;

    // --- Events ---
    event CatalystMinted(address indexed to, uint256 indexed tokenId, uint256 initialCharge, uint256 initialResonance, uint256 initialStability);
    event CatalystStateUpdated(uint256 indexed tokenId, uint256 charge, uint256 resonance, uint256 stability, uint8 stage);
    event EnergyClaimed(uint256 indexed tokenId, uint256 amountClaimed);
    event CatalystEvolved(uint256 indexed tokenId, uint8 oldStage, uint8 newStage);
    event ParametersUpdated(bytes32 indexed key, uint256 value);
    event OracleAddressUpdated(address indexed newOracleAddress);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        // Initialize some default parameters (can be changed later)
        parameters[keccak256("decayRate")] = 1; // Units of decay per second
        parameters[keccak256("energyPerSecond")] = 10; // Units of energy generated per second per unit of Charge * Resonance
        parameters[keccak256("infuseMultiplier")] = 1 ether / 100; // 1 ETH adds 100 units total stats (example)

        // Initialize evolution requirements (example)
        setEvolutionRequirements(1, 500, 500, 500); // Stage 1 requires 500+ of each
        setEvolutionRequirements(2, 1500, 1500, 1500); // Stage 2 requires 1500+ of each
        // Add more stages as needed
    }

    // --- Modifiers ---
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_exists(tokenId), "CosmicCatalysts: token does not exist");
        require(ownerOf(tokenId) == msg.sender, "CosmicCatalysts: not token owner");
        _;
    }

    // --- State Query Functions ---

    /// @notice Returns the current state struct for a specific Catalyst NFT.
    /// @param tokenId The ID of the Catalyst.
    /// @return CatalystState The state of the Catalyst.
    function getTokenState(uint256 tokenId) public view returns (CatalystState memory) {
        require(_exists(tokenId), "CosmicCatalysts: token does not exist");
        return _catalysts[tokenId];
    }

    /// @notice Calculates and returns the current accumulated energy for a Catalyst.
    /// @param tokenId The ID of the Catalyst.
    /// @return uint256 The amount of energy ready to be claimed.
    function getEnergyBalance(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "CosmicCatalysts: token does not exist");
         return _catalysts[tokenId].energyAccrued + _calculateEnergyAccrued(tokenId);
    }

    /// @notice Returns aggregated statistics across all existing Catalysts. (Simplified simulation)
    /// @dev This is a basic example. Realistically, this would require iterating or maintaining aggregate state.
    /// @return uint256 totalCatalysts The total number of Catalysts minted.
    /// @return uint256 nextTokenId The ID of the next token to be minted.
    function getGlobalCatalystStats() public view returns (uint256 totalCatalysts, uint256 nextTokenId) {
        // In a real contract, iterating or maintaining sums could be gas-intensive.
        // This is a simplified view.
        return (_currentTokenId, _currentTokenId + 1);
    }

    /// @notice Returns the value of a dynamic contract parameter.
    /// @param key The keccak256 hash of the parameter name (e.g., keccak256("decayRate")).
    /// @return uint256 The parameter value.
    function getParameter(bytes32 key) public view returns (uint256) {
        return parameters[key];
    }

    /// @notice Returns the minimum stats required for a given evolutionary stage.
    /// @param stage The evolutionary stage.
    /// @return minCharge Minimum charge needed.
    /// @return minResonance Minimum resonance needed.
    /// @return minStability Minimum stability needed.
    function getEvolutionRequirements(uint8 stage) public view returns (uint256 minCharge, uint256 minResonance, uint256 minStability) {
        require(stage > 0, "CosmicCatalysts: Stage 0 has no requirements");
        require(evolutionRequirements[stage].minCharge > 0 || evolutionRequirements[stage].minResonance > 0 || evolutionRequirements[stage].minStability > 0, "CosmicCatalysts: Requirements not set for this stage");
        return (evolutionRequirements[stage].minCharge, evolutionRequirements[stage].minResonance, evolutionRequirements[stage].minStability);
    }

    /// @notice Checks if a Catalyst meets the criteria for evolution to the next stage.
    /// @param tokenId The ID of the Catalyst.
    /// @return bool True if eligible, false otherwise.
    /// @return uint8 nextStage The next stage the catalyst could evolve into.
    function checkEvolutionEligibility(uint256 tokenId) public view returns (bool, uint8 nextStage) {
        require(_exists(tokenId), "CosmicCatalysts: token does not exist");
        CatalystState memory state = _catalysts[tokenId];
        nextStage = state.stage + 1;
        if (evolutionRequirements[nextStage].minCharge == 0 && evolutionRequirements[nextStage].minResonance == 0 && evolutionRequirements[nextStage].minStability == 0) {
             // No requirements set for this stage, maybe max stage reached or not configured
             return (false, nextStage);
        }

        bool eligible = state.charge >= evolutionRequirements[nextStage].minCharge &&
                        state.resonance >= evolutionRequirements[nextStage].minResonance &&
                        state.stability >= evolutionRequirements[nextStage].minStability;
        // Add potential time-based requirement, cost requirement, etc. here
        // For simplicity, only stat requirements checked here.
        return (eligible, nextStage);
    }


    // --- Minting ---

    /// @notice Mints a new Catalyst NFT for a recipient address with initial random-ish state.
    /// @param to The address to mint the token to.
    /// @return uint256 The ID of the newly minted Catalyst.
    function mintCatalyst(address to) public onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = _currentTokenId++;
        _safeMint(to, tokenId);

        // Initialize state (simple pseudo-randomness based on block data)
        _catalysts[tokenId] = CatalystState({
            charge: uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId))) % 100 + 100, // Base 100-200
            resonance: uint256(keccak256(abi.encodePacked(block.number, gasleft(), tx.origin, tokenId))) % 100 + 100, // Base 100-200
            stability: uint256(keccak256(abi.encodePacked(msg.sender, tx.gasprice, tokenId))) % 100 + 100, // Base 100-200
            stage: 0,
            lastInteraction: block.timestamp,
            energyAccrued: 0
        });

        emit CatalystMinted(to, tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalyst[tokenId].stability);
        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalyst[tokenId].stability, _catalysts[tokenId].stage);

        return tokenId;
    }

    // --- User Interaction Functions ---

    /// @notice Allows the token owner to 'tune' their Catalyst, adjusting its state.
    /// @dev Example: Increases Resonance, slightly decreases Stability. Applies decay first.
    /// @param tokenId The ID of the Catalyst to tune.
    function tuneCatalyst(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
        _applyDecay(tokenId);
        _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId); // Add accrued energy before updating timestamp

        _catalysts[tokenId].resonance += 50; // Example stat changes
        if (_catalysts[tokenId].stability >= 10) {
             _catalysts[tokenId].stability -= 10;
        } else {
             _catalysts[tokenId].stability = 0;
        }
        // Charge might fluctuate slightly too

        _catalysts[tokenId].lastInteraction = block.timestamp; // Update interaction time

        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalysts[tokenId].stability, _catalysts[tokenId].stage);
    }

    /// @notice Allows the token owner to 'attune' their Catalyst, adjusting its state differently.
    /// @dev Example: Increases Stability, slightly decreases Resonance. Applies decay first.
    /// @param tokenId The ID of the Catalyst to attune.
    function attuneCatalyst(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
        _applyDecay(tokenId);
        _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId); // Add accrued energy before updating timestamp

        _catalysts[tokenId].stability += 50; // Example stat changes
        if (_catalysts[tokenId].resonance >= 10) {
             _catalysts[tokenId].resonance -= 10;
        } else {
             _catalysts[tokenId].resonance = 0;
        }
        // Charge might fluctuate slightly too

        _catalysts[tokenId].lastInteraction = block.timestamp; // Update interaction time

        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalysts[tokenId].stability, _catalysts[tokenId].stage);
    }

    /// @notice Allows the token owner to send Ether to infuse their Catalyst, boosting attributes.
    /// @dev Example: Ether value boosts Charge and Stability. Applies decay first.
    /// @param tokenId The ID of the Catalyst to infuse.
    function infuseCatalyst(uint256 tokenId) public payable whenNotPaused onlyTokenOwner(tokenId) {
        require(msg.value > 0, "CosmicCatalysts: must send Ether to infuse");

        _applyDecay(tokenId);
        _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId); // Add accrued energy before updating timestamp

        uint256 infuseBoost = (msg.value * parameters[keccak256("infuseMultiplier")]) / 1 ether; // Calculate boost based on sent ETH

        _catalysts[tokenId].charge += infuseBoost;
        _catalysts[tokenId].stability += infuseBoost;

        _catalysts[tokenId].lastInteraction = block.timestamp; // Update interaction time

        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalysts[tokenId].stability, _catalysts[tokenId].stage);
        // Ether remains in the contract, withdrawable by owner via withdrawFunds()
    }

    /// @notice Allows the token owner to claim accumulated energy from a Catalyst.
    /// @dev Resets accrued energy after claiming. Applies decay first.
    /// @param tokenId The ID of the Catalyst.
    function claimEnergy(uint256 tokenId) public nonReentrant whenNotPaused onlyTokenOwner(tokenId) {
        // First, calculate and add any energy accrued since the last state change/claim
        _applyDecay(tokenId); // Decay affects current stats which affect energy accrual
        uint256 newlyAccrued = _calculateEnergyAccrued(tokenId);
        _catalysts[tokenId].energyAccrued += newlyAccrued;

        uint256 amountToClaim = _catalysts[tokenId].energyAccrued;
        _catalysts[tokenId].energyAccrued = 0; // Reset accrued energy

        _catalysts[tokenId].lastInteraction = block.timestamp; // Claiming is an interaction

        // TODO: Implement what claiming energy *does*. Send tokens? Unlock features?
        // For this example, energy is an internal contract value.
        // A real use case might involve minting/transferring a separate ERC20 token.
        // For now, we just emit the event and reset.

        emit EnergyClaimed(tokenId, amountToClaim);
        // State updated event is triggered implicitly by _applyDecay
    }

    /// @notice Attempts to evolve a Catalyst to the next stage if it meets the requirements.
    /// @param tokenId The ID of the Catalyst.
    function evolveCatalyst(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) {
        (bool eligible, uint8 nextStage) = checkEvolutionEligibility(tokenId);
        require(eligible, "CosmicCatalysts: not eligible for evolution yet");

        _applyDecay(tokenId); // Apply decay before evolution check (state might drop below threshold)
        _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId); // Add accrued energy

        // Re-check after decay
        (eligible, nextStage) = checkEvolutionEligibility(tokenId);
        require(eligible, "CosmicCatalysts: not eligible for evolution after decay");


        uint8 oldStage = _catalysts[tokenId].stage;
        _catalysts[tokenId].stage = nextStage;

        // Optional: Modify stats upon evolution, reset energy, etc.
        // Example: Stats get a boost but energy is consumed.
        _catalysts[tokenId].charge += 100 * nextStage;
        _catalysts[tokenId].resonance += 100 * nextStage;
        _catalysts[tokenId].stability += 100 * nextStage;
        // Maybe consume energy? require(_catalysts[tokenId].energyAccrued >= evolutionCost, "Not enough energy"); _catalysts[tokenId].energyAccrued -= evolutionCost;

        _catalysts[tokenId].lastInteraction = block.timestamp; // Evolution is an interaction

        emit CatalystEvolved(tokenId, oldStage, nextStage);
        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalysts[tokenId].stability, _catalysts[tokenId].stage);
    }

    /// @notice Allows the token owner to tune multiple Catalysts in a single transaction.
    /// @param tokenIds An array of Catalyst IDs to tune.
    function batchTuneCatalysts(uint256[] memory tokenIds) public whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            // Ensure caller owns each token. Reverts if any token is not owned or doesn't exist.
            require(_exists(tokenIds[i]), "CosmicCatalysts: token does not exist");
            require(ownerOf(tokenIds[i]) == msg.sender, "CosmicCatalysts: not owner of all tokens");

            // Call the core tune logic for each token
            _applyDecay(tokenIds[i]);
            _catalysts[tokenIds[i]].energyAccrued += _calculateEnergyAccrued(tokenIds[i]);

            _catalysts[tokenIds[i]].resonance += 50;
            if (_catalysts[tokenIds[i]].stability >= 10) {
                 _catalysts[tokenIds[i]].stability -= 10;
            } else {
                 _catalysts[tokenIds[i]].stability = 0;
            }

            _catalysts[tokenIds[i]].lastInteraction = block.timestamp;

            emit CatalystStateUpdated(tokenIds[i], _catalysts[tokenIds[i]].charge, _catalysts[tokenIds[i]].resonance, _catalysts[tokenIds[i]].stability, _catalysts[tokenIds[i]].stage);
        }
    }


    // --- Internal/Time-Based/External Interaction Functions ---

    /// @notice Internal helper to calculate energy accumulated since the last interaction.
    /// @dev Energy accrual rate is based on current stats and contract parameters.
    /// @param tokenId The ID of the Catalyst.
    /// @return uint256 The amount of energy accrued since lastInteraction.
    function _calculateEnergyAccrued(uint256 tokenId) internal view returns (uint256) {
        CatalystState storage state = _catalysts[tokenId];
        uint256 timePassed = block.timestamp - state.lastInteraction;
        // Simple energy formula: Charge * Resonance * time * rate (scaled)
        // Prevent overflow by checking multipliers
        uint256 energyPerSecondRate = parameters[keccak256("energyPerSecond")];
        if (state.charge == 0 || state.resonance == 0 || timePassed == 0 || energyPerSecondRate == 0) {
            return 0;
        }
        // Use safe multiplication if necessary, but for typical uint256 values, direct multiplication is okay if result fits.
        // Here, assuming rate is scaled appropriately (e.g., energyPerSecond is 10^18 for 1 token unit).
        uint256 potentialEnergy = state.charge * state.resonance;
        // Scale down potentially large intermediate result if needed. E.g., potentialEnergy / 1000 * timePassed * rate / 1000
         return (potentialEnergy / 100) * timePassed * energyPerSecondRate / 1000; // Example scaling
    }

    /// @notice Internal helper to apply state decay based on time since the last interaction.
    /// @dev Decay reduces stats if the catalyst is not interacted with.
    /// @param tokenId The ID of the Catalyst.
    function _applyDecay(uint256 tokenId) internal {
        CatalystState storage state = _catalysts[tokenId];
        uint256 timePassed = block.timestamp - state.lastInteraction;
        uint256 decayRate = parameters[keccak256("decayRate")];

        if (timePassed > 0 && decayRate > 0) {
            uint256 decayAmount = timePassed * decayRate;

            // Apply decay, but not below a certain minimum (e.g., 1)
            state.charge = state.charge > decayAmount ? state.charge - decayAmount : 1;
            state.resonance = state.resonance > decayAmount ? state.resonance - decayAmount : 1;
            state.stability = state.stability > decayAmount ? state.stability - decayAmount : 1;

            emit CatalystStateUpdated(tokenId, state.charge, state.resonance, state.stability, state.stage);
        }
        // Note: lastInteraction is updated in the calling function (tune, attune, claim, infuse, evolve)
        // Energy accrual is calculated *before* decay potentially reduces stats influencing the rate.
    }

    /// @notice Simulates external data influencing Catalyst state based on an oracle value.
    /// @dev This function would typically be callable by a trusted oracle address or service.
    /// For this example, it's public, but a real contract would restrict access.
    /// @param tokenId The ID of the Catalyst.
    /// @param oracleValue A signed integer value from the oracle (e.g., weather temp, market volatility index change).
    function alignCatalyst(uint256 tokenId, int256 oracleValue) public whenNotPaused { // Add 'onlyOracle' modifier in real app
        require(_exists(tokenId), "CosmicCatalysts: token does not exist");
        // require(msg.sender == oracleAddress, "CosmicCatalysts: only oracle can align"); // Uncomment in real app

        _applyDecay(tokenId);
        _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId); // Add accrued energy

        // Logic for how oracle value affects state (example)
        if (oracleValue > 0) {
            _catalysts[tokenId].charge += uint256(oracleValue) * 10; // Positive value increases charge
            if (_catalysts[tokenId].resonance >= uint256(oracleValue)) {
                 _catalysts[tokenId].resonance -= uint256(oracleValue); // Maybe decreases resonance slightly
            } else {
                 _catalysts[tokenId].resonance = 0;
            }
        } else if (oracleValue < 0) {
            uint256 absOracleValue = uint256(-oracleValue);
             if (_catalysts[tokenId].charge >= absOracleValue * 5) {
                _catalysts[tokenId].charge -= absOracleValue * 5; // Negative value decreases charge significantly
             } else {
                _catalysts[tokenId].charge = 1;
             }
            _catalysts[tokenId].stability += absOracleValue * 10; // But increases stability
        } else {
            // OracleValue is 0 - maybe a small boost to stability or resonance?
             _catalysts[tokenId].stability += 5;
        }

        _catalysts[tokenId].lastInteraction = block.timestamp; // Alignment is an interaction

        emit CatalystStateUpdated(tokenId, _catalysts[tokenId].charge, _catalysts[tokenId].resonance, _catalysts[tokenId].stability, _catalysts[tokenId].stage);
    }

    /// @notice Allows applying decay to a batch of Catalysts.
    /// @dev Can be called by anyone (or restricted) to facilitate off-chain maintenance.
    /// @param tokenIds An array of Catalyst IDs to apply decay to.
    function decayCatalysts(uint256[] memory tokenIds) public whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
             if (_exists(tokenIds[i])) { // Check existence as caller might not be owner
                 _applyDecay(tokenIds[i]);
                 // Note: Energy accrued is calculated in _calculateEnergyAccrued but only ADDED when claimed or another state-changing action occurs.
                 // Applying decay doesn't reset lastInteraction or add energy.
            }
        }
    }


    // --- Predictive Functions (Read-Only Simulation) ---

    /// @notice Simulates the state change of a Catalyst if an alignment with a hypothetical oracle value occurred, without changing state.
    /// @dev Useful for users to predict the outcome of alignment.
    /// @param tokenId The ID of the Catalyst.
    /// @param hypotheticalOracleValue A hypothetical oracle value to simulate the effect of.
    /// @return predictedState The state struct of the Catalyst after applying the hypothetical alignment logic.
    function predictAlignmentOutcome(uint256 tokenId, int256 hypotheticalOracleValue) public view returns (CatalystState memory predictedState) {
        require(_exists(tokenId), "CosmicCatalysts: token does not exist");

        predictedState = _catalysts[tokenId]; // Start with current state

        // Calculate decay FIRST based on *current* time difference, as if alignment happens now.
        uint256 timePassed = block.timestamp - predictedState.lastInteraction;
        uint256 decayRate = parameters[keccak256("decayRate")];

        if (timePassed > 0 && decayRate > 0) {
            uint256 decayAmount = timePassed * decayRate;
            predictedState.charge = predictedState.charge > decayAmount ? predictedState.charge - decayAmount : 1;
            predictedState.resonance = predictedState.resonance > decayAmount ? predictedState.resonance - decayAmount : 1;
            predictedState.stability = predictedState.stability > decayAmount ? predictedState.stability - decayAmount : 1;
        }

        // Calculate accrued energy since last interaction based on decayed state *before* applying alignment changes.
        // This is how it would work if state change added energy before updating timestamp.
        // Note: This prediction doesn't simulate the *claim* effect, only the state change effect.
        // If prediction included claim, energyAccrued would be added to total and then reset.
        // For simplicity, prediction just shows resulting stats, not energy effect.

        // Apply hypothetical oracle logic
        if (hypotheticalOracleValue > 0) {
            predictedState.charge += uint256(hypotheticalOracleValue) * 10;
            if (predictedState.resonance >= uint256(hypotheticalOracleValue)) {
                 predictedState.resonance -= uint256(hypotheticalOracleValue);
            } else {
                 predictedState.resonance = 0;
            }
        } else if (hypotheticalOracleValue < 0) {
            uint256 absOracleValue = uint256(-hypotheticalOracleValue);
             if (predictedState.charge >= absOracleValue * 5) {
                predictedState.charge -= absOracleValue * 5;
             } else {
                predictedState.charge = 1;
             }
            predictedState.stability += absOracleValue * 10;
        } else {
             predictedState.stability += 5;
        }

        // Note: lastInteraction and energyAccrued state *would* change in the actual function,
        // but in this view function, we just return the predicted stat values.

        return predictedState;
    }


    // --- Admin Functions (Owner Only) ---

    /// @notice Sets the address of the simulated oracle.
    /// @param _oracle The new oracle address.
    function setOracleAddress(address _oracle) public onlyOwner {
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    /// @notice Sets a dynamic contract parameter.
    /// @dev Use keccak256("parameterName") for the key.
    /// @param key The keccak256 hash of the parameter name.
    /// @param value The new value for the parameter.
    function setParameter(bytes32 key, uint256 value) public onlyOwner {
        parameters[key] = value;
        emit ParametersUpdated(key, value);
    }

    /// @notice Sets the minimum stats required for a specific evolutionary stage.
    /// @param stage The evolutionary stage to configure (must be > 0).
    /// @param minCharge Minimum charge needed for this stage.
    /// @param minResonance Minimum resonance needed for this stage.
    /// @param minStability Minimum stability needed for this stage.
    function setEvolutionRequirements(uint8 stage, uint256 minCharge, uint256 minResonance, uint256 minStability) public onlyOwner {
        require(stage > 0, "CosmicCatalysts: Cannot set requirements for stage 0");
        evolutionRequirements[stage].minCharge = minCharge;
        evolutionRequirements[stage].minResonance = minResonance;
        evolutionRequirements[stage].minStability = minStability;
    }

    /// @notice Pauses the contract, preventing most user interactions.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing user interactions again.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw any accumulated Ether from the contract.
    /// @dev Ether is collected from infuseCatalyst().
    function withdrawFunds() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "CosmicCatalysts: Ether withdrawal failed");
    }


    // --- Overrides and ERC721 required functions ---

    /// @dev See {ERC721-_baseURI}.
    // function _baseURI() internal view override returns (string memory) {
    //     // Optional: Return a base URI for token metadata (off-chain)
    //     // return "ipfs://YOUR_METADATA_CID/";
    //     revert("CosmicCatalysts: baseURI not set"); // Or implement as needed
    // }

    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Logic to generate a dynamic tokenURI based on Catalyst state
        // This would typically point to an off-chain service or IPFS file
        // that generates metadata (name, description, image, attributes)
        // based on the state returned by getTokenState(tokenId).
        // For simplicity, returning a placeholder.
        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name": "Cosmic Catalyst #', toString(tokenId),
                '", "description": "An evolving digital entity.",',
                '"attributes": [',
                    '{"trait_type": "Stage", "value": ', toString(_catalysts[tokenId].stage), '},',
                    '{"trait_type": "Charge", "value": ', toString(_catalysts[tokenId].charge), '},',
                    '{"trait_type": "Resonance", "value": ', toString(_catalysts[tokenId].resonance), '},',
                    '{"trait_type": "Stability", "value": ', toString(_catalysts[tokenId].stability), '}',
                ']}'
            )))
        ));
    }

    // Helper for tokenURI (OpenZeppelin's String library or roll your own)
    // Simple toString for uint256
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // ERC721 transfer overrides - automatically apply decay and energy accrual on transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) { // Not a mint
             _applyDecay(tokenId);
             _catalysts[tokenId].energyAccrued += _calculateEnergyAccrued(tokenId);
             _catalysts[tokenId].lastInteraction = block.timestamp; // Transfer is an interaction for decay/energy purposes
        }
    }

    // ERC721 burn override - clean up state
    function _beforeTokenBurn(address owner, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenBurn(owner, tokenId, batchSize);
        if (_exists(tokenId)) {
            // Clear the state storage when burned
            delete _catalysts[tokenId];
        }
    }

    /// @notice Allows burning a Catalyst token, removing it from existence.
    /// @param tokenId The ID of the Catalyst to burn.
    function burnCatalyst(uint256 tokenId) public onlyTokenOwner(tokenId) whenNotPaused {
        _burn(tokenId);
        // State cleanup handled by _beforeTokenBurn
    }

    // Need Base64 encoding for data URI (simple implementation)
    // Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol (adjust for ^0.8.20)
    bytes constant _base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function Base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the alphabet bytes:
        bytes memory alphabet = _base64Alphabet;

        // total length of converted bytes
        uint256 encodedLen = (data.length * 8 + 5) / 6;
        // padded length of converted bytes
        uint256 paddedLen = encodedLen + (3 - (encodedLen % 3)) % 3;
        bytes memory encoded = new bytes(paddedLen);

        // encode
        uint256 i;
        uint256 j;
        for (i = 0; i < data.length; i += 3) {
            uint256 z = (data[i] << 16) | (data.length > i + 1 ? data[i + 1] << 8 : 0) | (data.length > i + 2 ? data[i + 2] : 0);

            encoded[j] = alphabet[(z >> 18) & 0x3F];
            encoded[j + 1] = alphabet[(z >> 12) & 0x3F];
            encoded[j + 2] = data.length > i + 1 ? alphabet[(z >> 6) & 0x3F] : bytes1('=');
            encoded[j + 3] = data.length > i + 2 ? alphabet[z & 0x3F] : bytes1('=');
            j += 4;
        }

        return string(encoded);
    }

}
```