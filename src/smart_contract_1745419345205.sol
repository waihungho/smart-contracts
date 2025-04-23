Okay, here is a Solidity smart contract incorporating several advanced, creative, and interconnected concepts around digital artifacts that evolve over time and through user interaction.

It's structured as an ERC-721 NFT collection where each token represents a unique "Quantum Artifact". These artifacts have parameters that change based on time decay and specific actions users take, consuming and generating an internal resource token called "Quantum Energy". The mechanics include fusion, stabilization/destabilization, charging, challenging, and time-based decay.

This design aims to be unique by combining:
1.  **Evolving NFTs:** Parameters change over time (`decayProcess`) and via interaction.
2.  **On-Chain Simulation:** Basic time-based decay and state transitions are calculated on-chain.
3.  **Internal Resource Management:** An internal token (`QuantumEnergy`) is used for actions and rewards, simplifying the interaction within a single contract.
4.  **Procedural Generation:** Initial parameters use block data for a touch of on-chain randomness (deterministic, but unique per mint).
5.  **Gamified Mechanics:** Fusion, challenge, stabilization add interactive game-like elements.
6.  **Variable State:** Artifacts have states (Stable, Unstable, Critical) based on their parameters.

---

## Smart Contract Outline: QuantumFusion

**Contract:** `QuantumFusion`
**Inherits:** ERC721, Ownable, Pausable
**Concept:** A collection of dynamic, evolving "Quantum Artifact" NFTs. Artifacts have parameters (Entropy, Stability, Charge, DecayRate) that change over time and through user actions. Interactions use/generate an internal `QuantumEnergy` resource token.

**Data Structures:**
*   `ArtifactState` (Enum): `Stable`, `Unstable`, `Critical`
*   `Artifact` (Struct): Stores parameters, last interaction time, associated energy balance.

**State Variables:**
*   NFT mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   Artifact data mapping (`_artifactData`).
*   Total supply counter (`_tokenIdCounter`).
*   Internal `QuantumEnergy` balances (`_energyBalances`).
*   Costs and rewards (`mintCostETH`, `mintCostEnergy`, `stabilizeCost`, `destabilizeCost`, `chargeCost`, `extractRate`, `stabilityRewardRate`, `fusionCostEnergy`, `challengeCostEnergy`, `upgradeCostEnergy`).
*   Parameter thresholds for states (`unstableThreshold`, `criticalThreshold`).
*   Global decay rate base (`_globalDecayRateBase`).
*   Admin control (`_owner`, `_paused`).

**Events:**
*   Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`).
*   Custom events: `ArtifactMinted`, `ArtifactStateChanged`, `EnergyTransferred`, `EnergyMinted`, `EnergyBurned`, `ArtifactFused`, `ArtifactDecayed`, `ParameterUpgraded`, `ArtifactChallenged`, `StabilityRewardClaimed`, `ContractPaused`, `ContractUnpaused`.

**Modifiers:**
*   `onlyOwner`: Restricts access to contract owner.
*   `whenNotPaused`: Restricts access when contract is not paused.
*   `whenPaused`: Restricts access when contract is paused.
*   `isValidArtifact`: Checks if a token ID exists.

**Internal Functions (Helpers):**
*   `_safeMint`, `_mint`, `_burn`, `_transfer`: Standard ERC721 internal helpers.
*   `_updateArtifactState`: Applies time decay to an artifact's parameters.
*   `_calculateCurrentEntropy`, `_calculateCurrentStability`: Pure functions calculating potential current params after decay.
*   `_checkArtifactState`: Pure function determining state from parameters.
*   `_generateInitialParameters`: Generates params procedurally during minting.
*   `_mintEnergy`, `_burnEnergy`, `_transferEnergy`: Internal energy management.
*   `_beforeTokenTransfer`: ERC721 hook for state updates before transfer.

**External/Public Functions (Grouped):**

**ERC-721 Standard Functions (Required for interface):**
1.  `supportsInterface(bytes4 interfaceId)`: Checks ERC standard support.
2.  `balanceOf(address owner)`: Returns number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId)`: Returns owner of a specific token.
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
6.  `transferFrom(address from, address to, uint256 tokenId)`: Unsafe transfer.
7.  `approve(address to, uint256 tokenId)`: Approve an address to take ownership.
8.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all tokens.
9.  `getApproved(uint256 tokenId)`: Get the approved address for a token.
10. `isApprovedForAll(address owner, address operator)`: Check if an operator is approved.

**Core Quantum Mechanics Functions:**
11. `mintArtifact(bytes32 salt)`: Mints a new artifact, pays cost, generates initial params.
12. `fuseArtifacts(uint256 tokenIdPrimary, uint256 tokenIdSecondary)`: Fuses two artifacts, burns secondary, modifies primary.
13. `destabilizeArtifact(uint256 tokenId)`: Increases entropy, decreases stability (cost energy).
14. `stabilizeArtifact(uint256 tokenId)`: Decreases entropy, increases stability (cost energy).
15. `chargeArtifact(uint256 tokenId, uint256 amount)`: Adds charge to artifact (cost energy).
16. `dischargeArtifact(uint256 tokenId, uint256 amount)`: Reduces charge, potentially generates energy.
17. `extractArtifactEnergy(uint256 tokenId, uint256 amount)`: Converts stability/charge to QuantumEnergy.
18. `decayArtifactProcess(uint256 tokenId)`: Explicitly applies time decay to an artifact (can be called by anyone).
19. `claimStabilityReward(uint256 tokenId)`: Claim energy reward if artifact is in Stable state.
20. `challengeArtifact(uint256 tokenIdChallenger, uint256 tokenIdTarget)`: Abstract interaction affecting both artifacts based on parameters.
21. `burnArtifact(uint256 tokenId)`: Burns an artifact, owner gets some energy back.
22. `upgradeArtifactParameter(uint256 tokenId, uint8 paramType)`: Upgrades a specific parameter's influence (cost energy).

**View Functions:**
23. `getArtifactParameters(uint256 tokenId)`: Get current calculated parameters including decay.
24. `getArtifactState(uint256 tokenId)`: Get current calculated state including decay.
25. `getEnergyBalance(address owner)`: Get an address's QuantumEnergy balance.
26. `getTotalArtifactSupply()`: Get the total number of artifacts minted.
27. `getUserArtifacts(address owner)`: Get a list of token IDs owned by an address.

**Admin Functions (Owner only):**
28. `setGlobalDecayRate(uint256 rate)`: Sets the base rate for time decay.
29. `pauseContract()`: Pauses core mechanics.
30. `unpauseContract()`: Unpauses core mechanics.
31. `withdrawEther()`: Withdraws ETH balance from contract.
32. `withdrawExcessEnergy(uint256 amount)`: Withdraws QuantumEnergy from contract's balance (if any accumulates).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example for potential future use or complex interaction
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract Outline: QuantumFusion ---
//
// Contract: QuantumFusion
// Inherits: ERC721, Ownable, Pausable
// Concept: A collection of dynamic, evolving "Quantum Artifact" NFTs. Artifacts have parameters (Entropy, Stability, Charge, DecayRate) that change over time and through user actions. Interactions use/generate an internal `QuantumEnergy` resource token.
//
// Data Structures:
// - ArtifactState (Enum): Stable, Unstable, Critical
// - Artifact (Struct): Stores parameters, last interaction time, associated energy balance.
//
// State Variables:
// - NFT mappings (_owners, _balances, _tokenApprovals, _operatorApprovals).
// - Artifact data mapping (_artifactData).
// - Total supply counter (_tokenIdCounter).
// - Internal QuantumEnergy balances (_energyBalances).
// - Costs and rewards (mintCostETH, mintCostEnergy, stabilizeCost, destabilizeCost, chargeCost, extractRate, stabilityRewardRate, fusionCostEnergy, challengeCostEnergy, upgradeCostEnergy).
// - Parameter thresholds for states (unstableThreshold, criticalThreshold).
// - Global decay rate base (_globalDecayRateBase).
// - Admin control (_owner, _paused).
//
// Events:
// - Standard ERC721 events (Transfer, Approval, ApprovalForAll).
// - Custom events: ArtifactMinted, ArtifactStateChanged, EnergyTransferred, EnergyMinted, EnergyBurned, ArtifactFused, ArtifactDecayed, ParameterUpgraded, ArtifactChallenged, StabilityRewardClaimed, ContractPaused, ContractUnpaused.
//
// Modifiers:
// - onlyOwner, whenNotPaused, whenPaused, isValidArtifact.
//
// Internal Functions (Helpers):
// - _safeMint, _mint, _burn, _transfer (Standard ERC721).
// - _updateArtifactState: Applies time decay.
// - _calculateCurrentEntropy, _calculateCurrentStability: Calculates parameters after decay.
// - _checkArtifactState: Determines state from parameters.
// - _generateInitialParameters: Procedural generation.
// - _mintEnergy, _burnEnergy, _transferEnergy: Internal energy management.
// - _beforeTokenTransfer: ERC721 hook.
//
// External/Public Functions:
//
// ERC-721 Standard Functions (Required for interface):
// 1. supportsInterface
// 2. balanceOf
// 3. ownerOf
// 4. safeTransferFrom (2 overloads)
// 5. transferFrom
// 6. approve
// 7. setApprovalForAll
// 8. getApproved
// 9. isApprovedForAll
//
// Core Quantum Mechanics Functions:
// 10. mintArtifact
// 11. fuseArtifacts
// 12. destabilizeArtifact
// 13. stabilizeArtifact
// 14. chargeArtifact
// 15. dischargeArtifact
// 16. extractArtifactEnergy
// 17. decayArtifactProcess
// 18. claimStabilityReward
// 19. challengeArtifact
// 20. burnArtifact
// 21. upgradeArtifactParameter
//
// View Functions:
// 22. getArtifactParameters
// 23. getArtifactState
// 24. getEnergyBalance
// 25. getTotalArtifactSupply
// 26. getUserArtifacts
//
// Admin Functions (Owner only):
// 27. setGlobalDecayRate
// 28. pauseContract
// 29. unpauseContract
// 30. withdrawEther
// 31. withdrawExcessEnergy
//
// --- End Outline ---

contract QuantumFusion is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256; // For min/max

    Counters.Counter private _tokenIdCounter;

    enum ArtifactState {
        Stable,
        Unstable,
        Critical
    }

    struct Artifact {
        // Primary Evolving Parameters
        uint256 entropy;      // Increases over time/destabilization, decreases with stabilization
        uint256 stability;    // Decreases over time/destabilization, increases with stabilization
        uint256 charge;       // Accumulates via charging, used for actions
        uint256 decayRate;    // Influences how fast entropy increases/stability decreases

        // Time Tracking
        uint40 lastInteractionTime; // Last timestamp params were updated

        // Associated Resources (within the contract's scope)
        // uint256 internalEnergy; // Moved to _energyBalances mapping for simplicity and central tracking
    }

    // --- State Variables ---

    mapping(uint256 => Artifact) private _artifactData;

    // Internal Energy Token (QuantumEnergy)
    mapping(address => uint256) private _energyBalances;
    uint256 public energyTotalSupply; // Keep track of total internal energy

    // Configuration Costs and Rewards
    uint256 public mintCostETH = 0.01 ether;
    uint256 public mintCostEnergy = 100;
    uint256 public stabilizeCost = 50;      // Energy cost to stabilize
    uint256 public destabilizeCost = 20;   // Energy cost to destabilize (less than stabilize)
    uint256 public chargeCost = 1;         // Energy cost per unit of charge
    uint256 public extractRate = 2;        // How much energy extracted per unit of stability/charge
    uint256 public stabilityRewardRate = 10; // Energy reward per time unit in Stable state
    uint256 public fusionCostEnergy = 200;
    uint256 public challengeCostEnergy = 30;
    uint256 public upgradeCostEnergy = 500; // Base cost to upgrade a parameter

    // State Thresholds (adjust based on desired game balance)
    uint256 public unstableThreshold = 500;
    uint256 public criticalThreshold = 1000; // If entropy reaches this, it's critical

    // Global Decay Influence
    uint256 private _globalDecayRateBase = 1; // Base rate applied to decay calculation

    // --- Events ---

    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, uint256 entropy, uint256 stability, uint256 decayRate);
    event ArtifactStateChanged(uint256 indexed tokenId, ArtifactState newState, ArtifactState oldState);
    event EnergyMinted(address indexed account, uint256 amount);
    event EnergyBurned(address indexed account, uint256 amount);
    event EnergyTransferred(address indexed from, address indexed to, uint256 amount);
    event ArtifactFused(uint256 indexed tokenIdPrimary, uint256 indexed tokenIdSecondaryBurned, uint256 newEntropy, uint256 newStability);
    event ArtifactDecayed(uint256 indexed tokenId, uint256 timeElapsed, uint256 newEntropy, uint256 newStability);
    event ParameterUpgraded(uint256 indexed tokenId, uint8 indexed paramType, uint256 newDecayRate); // Example: decay rate upgrade
    event ArtifactChallenged(uint256 indexed tokenIdChallenger, uint256 indexed tokenIdTarget, bool success); // Abstract outcome
    event StabilityRewardClaimed(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Constructor ---

    constructor() ERC721("QuantumFusionArtifact", "QFA") Ownable(msg.sender) {
        // Initial energy supply for the owner or initial distribution
        _mintEnergy(msg.sender, 10000);
    }

    // --- Modifiers ---

    modifier isValidArtifact(uint256 tokenId) {
        require(_exists(tokenId), "QFA: Invalid token ID");
        _;
    }

    // --- Internal Energy Management ---

    function _mintEnergy(address account, uint256 amount) internal {
        require(account != address(0), "QFA: mint to the zero address");
        energyTotalSupply += amount;
        _energyBalances[account] += amount;
        emit EnergyMinted(account, amount);
    }

    function _burnEnergy(address account, uint256 amount) internal {
        require(account != address(0), "QFA: burn from the zero address");
        uint256 accountBalance = _energyBalances[account];
        require(accountBalance >= amount, "QFA: burn amount exceeds balance");
        unchecked {
            _energyBalances[account] = accountBalance - amount;
        }
        energyTotalSupply -= amount;
        emit EnergyBurned(account, amount);
    }

    function _transferEnergy(address from, address to, uint256 amount) internal {
        require(from != address(0), "QFA: transfer from the zero address");
        require(to != address(0), "QFA: transfer to the zero address");

        uint256 fromBalance = _energyBalances[from];
        require(fromBalance >= amount, "QFA: transfer amount exceeds balance");
        unchecked {
            _energyBalances[from] = fromBalance - amount;
        }
        _energyBalances[to] += amount;

        emit EnergyTransferred(from, to, amount);
    }

    // --- Artifact State Calculation and Update ---

    // Applies time decay and updates lastInteractionTime
    function _updateArtifactState(uint256 tokenId) internal {
        Artifact storage artifact = _artifactData[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - artifact.lastInteractionTime;

        if (timeElapsed > 0) {
            ArtifactState oldState = _checkArtifactState(artifact.entropy, artifact.stability);

            // Decay Logic: Entropy increases, Stability decreases over time
            // Simple linear decay based on time elapsed and decay rate
            uint256 decayAmount = (timeElapsed * artifact.decayRate * _globalDecayRateBase) / 1e18; // Scale appropriately if rates are large

            artifact.entropy += decayAmount;
            if (artifact.stability > decayAmount) {
                artifact.stability -= decayAmount;
            } else {
                artifact.stability = 0; // Cannot go below zero
            }

            artifact.lastInteractionTime = uint40(currentTime); // Update timestamp

            ArtifactState newState = _checkArtifactState(artifact.entropy, artifact.stability);
            if (newState != oldState) {
                emit ArtifactStateChanged(tokenId, newState, oldState);
            }
            emit ArtifactDecayed(tokenId, timeElapsed, artifact.entropy, artifact.stability);
        }
    }

    // Pure function to calculate CURRENT entropy considering decay *since* last update
    function _calculateCurrentEntropy(uint256 tokenId) internal view returns (uint256) {
        Artifact storage artifact = _artifactData[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - artifact.lastInteractionTime;
        uint256 decayAmount = (timeElapsed * artifact.decayRate * _globalDecayRateBase) / 1e18;
        return artifact.entropy + decayAmount;
    }

    // Pure function to calculate CURRENT stability considering decay *since* last update
    function _calculateCurrentStability(uint256 tokenId) internal view returns (uint256) {
        Artifact storage artifact = _artifactData[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - artifact.lastInteractionTime;
        uint256 decayAmount = (timeElapsed * artifact.decayRate * _globalDecayRateBase) / 1e18;
        return artifact.stability > decayAmount ? artifact.stability - decayAmount : 0;
    }

    // Pure function to determine state based on provided parameters
    function _checkArtifactState(uint256 currentEntropy, uint256 currentStability) internal view returns (ArtifactState) {
        // Priority: Critical (high entropy) > Unstable (lower stability) > Stable
        if (currentEntropy >= criticalThreshold) {
            return ArtifactState.Critical;
        } else if (currentStability <= unstableThreshold) {
            return ArtifactState.Unstable;
        } else {
            return ArtifactState.Stable;
        }
    }

    // Procedurally generate initial parameters (deterministic randomness)
    function _generateInitialParameters(uint256 tokenId, bytes32 salt) internal view returns (uint256 entropy, uint256 stability, uint256 decayRate) {
        // Use block hash, timestamp, sender, token ID, and salt for variability
        bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, tokenId, salt));

        // Simple scaling/mapping of hash output to parameters
        entropy = uint256(seed) % 200; // Initial entropy between 0-199
        stability = 1000 + (uint256(seed >> 32) % 500); // Initial stability between 1000-1499
        decayRate = 1 + (uint256(seed >> 64) % 10); // Initial decay rate between 1-10
    }

    // --- ERC721 Hooks ---

    // Called before any token transfer (including minting and burning)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // When transferring, update the state of the artifact being moved
        // This ensures its decay is applied before potentially changing hands
        if (_exists(tokenId)) {
             _updateArtifactState(tokenId);
             // Note: The artifact's internal energy balance (_energyBalances[tokenId] if we stored it per artifact)
             // would typically NOT transfer with the NFT in most designs.
             // Here, energy is tied to the wallet address (_energyBalances[owner]).
        }
    }

    // --- Core Quantum Mechanics Functions ---

    /**
     * @notice Mints a new Quantum Artifact NFT.
     * @param salt Additional randomness factor provided by the user.
     */
    function mintArtifact(bytes32 salt) external payable whenNotPaused {
        uint256 nextTokenId = _tokenIdCounter.current();

        require(msg.value >= mintCostETH, "QFA: Insufficient ETH for mint");
        require(_energyBalances[msg.sender] >= mintCostEnergy, "QFA: Insufficient Energy for mint");

        _burnEnergy(msg.sender, mintCostEnergy);
        // Contract keeps the ETH, can be withdrawn by owner

        (uint256 initialEntropy, uint256 initialStability, uint256 initialDecayRate) = _generateInitialParameters(nextTokenId, salt);

        _safeMint(msg.sender, nextTokenId);
        _artifactData[nextTokenId] = Artifact({
            entropy: initialEntropy,
            stability: initialStability,
            charge: 0,
            decayRate: initialDecayRate,
            lastInteractionTime: uint40(block.timestamp)
        });
        _tokenIdCounter.increment();

        emit ArtifactMinted(msg.sender, nextTokenId, initialEntropy, initialStability, initialDecayRate);
    }

    /**
     * @notice Fuses two artifacts. The secondary artifact is burned,
     *         and its parameters influence the primary artifact.
     * @param tokenIdPrimary The ID of the artifact that will remain and be modified.
     * @param tokenIdSecondary The ID of the artifact that will be burned.
     */
    function fuseArtifacts(uint256 tokenIdPrimary, uint256 tokenIdSecondary) external whenNotPaused isValidArtifact(tokenIdPrimary) isValidArtifact(tokenIdSecondary) {
        require(tokenIdPrimary != tokenIdSecondary, "QFA: Cannot fuse an artifact with itself");
        require(ownerOf(tokenIdPrimary) == msg.sender, "QFA: Must own the primary artifact");
        require(ownerOf(tokenIdSecondary) == msg.sender, "QFA: Must own the secondary artifact");
        require(_energyBalances[msg.sender] >= fusionCostEnergy, "QFA: Insufficient Energy for fusion");

        _burnEnergy(msg.sender, fusionCostEnergy);

        // Ensure both artifacts' states are up-to-date before fusion
        _updateArtifactState(tokenIdPrimary);
        _updateArtifactState(tokenIdSecondary);

        Artifact storage primary = _artifactData[tokenIdPrimary];
        Artifact storage secondary = _artifactData[tokenIdSecondary];

        // Fusion Logic: Simple weighted average, could be more complex
        // Secondary contributes a fraction of its parameters
        uint256 newEntropy = (primary.entropy + secondary.entropy / 2);
        uint256 newStability = (primary.stability + secondary.stability / 2);
        // Max decay rate, or average, depending on desired outcome
        uint256 newDecayRate = Math.max(primary.decayRate, secondary.decayRate);
        uint256 newCharge = primary.charge + secondary.charge; // Combine charge

        primary.entropy = newEntropy;
        primary.stability = newStability;
        primary.decayRate = newDecayRate;
        primary.charge = newCharge;
        primary.lastInteractionTime = uint40(block.timestamp); // Fusion counts as interaction

        // Burn the secondary artifact
        _burn(tokenIdSecondary);
        delete _artifactData[tokenIdSecondary]; // Clean up storage

        emit ArtifactFused(tokenIdPrimary, tokenIdSecondary, newEntropy, newStability);
         // Check state change for primary artifact after fusion
        ArtifactState newState = _checkArtifactState(primary.entropy, primary.stability);
        // We don't have the old state easily here after direct manipulation,
        // but we could store it if needed, or just rely on the Decay event state change.
        // For simplicity, we omit the state change emit *specifically* for the fused artifact here,
        // as decayProcess covers it.
    }

     /**
     * @notice Increases an artifact's entropy and decreases stability, costs energy.
     *         This is a risky action that pushes the artifact towards Unstable/Critical states.
     * @param tokenId The ID of the artifact to destabilize.
     */
    function destabilizeArtifact(uint256 tokenId) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");
        require(_energyBalances[msg.sender] >= destabilizeCost, "QFA: Insufficient Energy for destabilization");

        _burnEnergy(msg.sender, destabilizeCost);

        _updateArtifactState(tokenId); // Apply decay first

        Artifact storage artifact = _artifactData[tokenId];
        ArtifactState oldState = _checkArtifactState(artifact.entropy, artifact.stability);

        artifact.entropy += 100; // Example value
        if (artifact.stability >= 50) { // Example value
             artifact.stability -= 50;
        } else {
            artifact.stability = 0;
        }

        // No need to update lastInteractionTime here, decayProcess handles it
        // state change will be emitted by _updateArtifactState if it occurs

        ArtifactState newState = _checkArtifactState(artifact.entropy, artifact.stability);
        if (newState != oldState) {
             emit ArtifactStateChanged(tokenId, newState, oldState);
        }
    }

    /**
     * @notice Decreases an artifact's entropy and increases stability, costs more energy.
     *         Helps move the artifact towards the Stable state.
     * @param tokenId The ID of the artifact to stabilize.
     */
    function stabilizeArtifact(uint256 tokenId) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");
        require(_energyBalances[msg.sender] >= stabilizeCost, "QFA: Insufficient Energy for stabilization");

        _burnEnergy(msg.sender, stabilizeCost);

        _updateArtifactState(tokenId); // Apply decay first

        Artifact storage artifact = _artifactData[tokenId];
        ArtifactState oldState = _checkArtifactState(artifact.entropy, artifact.stability);

        if (artifact.entropy >= 75) { // Example value
             artifact.entropy -= 75;
        } else {
             artifact.entropy = 0;
        }
        artifact.stability += 75; // Example value

        // No need to update lastInteractionTime here, decayProcess handles it
        // state change will be emitted by _updateArtifactState if it occurs

        ArtifactState newState = _checkArtifactState(artifact.entropy, artifact.stability);
        if (newState != oldState) {
             emit ArtifactStateChanged(tokenId, newState, oldState);
        }
    }

    /**
     * @notice Adds charge to an artifact, costing energy. Charge can be used for other actions.
     * @param tokenId The ID of the artifact to charge.
     * @param amount The amount of charge to add.
     */
    function chargeArtifact(uint256 tokenId, uint256 amount) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");
        uint256 requiredEnergy = amount * chargeCost;
        require(_energyBalances[msg.sender] >= requiredEnergy, "QFA: Insufficient Energy to charge");

        _burnEnergy(msg.sender, requiredEnergy);

        _updateArtifactState(tokenId); // Apply decay first

        Artifact storage artifact = _artifactData[tokenId];
        artifact.charge += amount;
        // No need to update lastInteractionTime here
    }

    /**
     * @notice Uses charge from an artifact. Can be a prerequisite for other actions
     *         or potentially used to generate a small amount of energy.
     * @param tokenId The ID of the artifact to discharge.
     * @param amount The amount of charge to use.
     */
    function dischargeArtifact(uint256 tokenId, uint256 amount) external whenNotPaused isValidArtifact(tokenId) {
         require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");

         _updateArtifactState(tokenId); // Apply decay first

         Artifact storage artifact = _artifactData[tokenId];
         require(artifact.charge >= amount, "QFA: Insufficient charge on artifact");

         artifact.charge -= amount;

         // Optional: Gain a small amount of energy back from discharging
         uint256 energyGain = amount / 5; // Example: 20% efficiency
         if (energyGain > 0) {
             _mintEnergy(msg.sender, energyGain);
         }

         // No need to update lastInteractionTime here
    }

    /**
     * @notice Extracts QuantumEnergy from an artifact based on its current stability and charge.
     *         Reduces stability and charge proportionally.
     * @param tokenId The ID of the artifact to extract from.
     * @param amount The desired amount of energy to extract.
     */
    function extractArtifactEnergy(uint256 tokenId, uint256 amount) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");

        _updateArtifactState(tokenId); // Apply decay first

        Artifact storage artifact = _artifactData[tokenId];
        uint256 currentStability = _calculateCurrentStability(tokenId);
        uint256 currentCharge = artifact.charge; // Charge is not affected by time decay

        // Calculate how much stability/charge is needed per unit of energy
        // Example: 1 Energy = (1 Stability point + 1 Charge point) / extractRate
        uint256 pointsNeeded = (amount * extractRate);
        require(currentStability + currentCharge >= pointsNeeded, "QFA: Insufficient stability or charge to extract this much energy");

        // Reduce stability and charge proportionally (simple distribution)
        uint256 stabilityToUse = (currentStability * pointsNeeded) / (currentStability + currentCharge);
        uint256 chargeToUse = pointsNeeded - stabilityToUse; // The rest comes from charge

        if (artifact.stability >= stabilityToUse) {
             artifact.stability -= stabilityToUse;
        } else {
            artifact.stability = 0; // Should not happen with check above, but safe
        }

        if (artifact.charge >= chargeToUse) {
            artifact.charge -= chargeToUse;
        } else {
            artifact.charge = 0; // Should not happen
        }


        _mintEnergy(msg.sender, amount);

        // No need to update lastInteractionTime here
         // Check state change after stability reduction
        ArtifactState newState = _checkArtifactState(artifact.entropy, artifact.stability);
        // State change emit handled by _updateArtifactState potentially
    }


    /**
     * @notice Allows anyone to trigger the time decay process for a specific artifact.
     *         This is necessary because contracts cannot run code autonomously.
     *         Users or keeper bots would call this to update artifact states.
     * @param tokenId The ID of the artifact to decay.
     */
    function decayArtifactProcess(uint256 tokenId) external whenNotPaused isValidArtifact(tokenId) {
        // Anyone can call this to keep artifact states current
        _updateArtifactState(tokenId);
        // No return value, state change emitted by internal call
    }


    /**
     * @notice Allows the owner of a Stable artifact to claim a reward in QuantumEnergy.
     *         Rewards are based on the time elapsed since the last reward claim
     *         and the artifact's stability parameters.
     * @param tokenId The ID of the artifact to claim from.
     */
    function claimStabilityReward(uint256 tokenId) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");

        _updateArtifactState(tokenId); // Apply decay before checking state and claiming

        Artifact storage artifact = _artifactData[tokenId];
        require(_checkArtifactState(artifact.entropy, artifact.stability) == ArtifactState.Stable, "QFA: Artifact is not in Stable state");

        // Calculate reward based on time in stable state since last claim/interaction
        // Using lastInteractionTime as proxy for last claim/update
        uint256 currentTime = block.timestamp;
        uint256 timeInState = currentTime - artifact.lastInteractionTime; // Time since last state update/interaction

        // Simple reward calculation: time elapsed * stability * rate
        // Scale stability down to prevent massive rewards
        uint256 rewardAmount = (timeInState * (artifact.stability / 100) * stabilityRewardRate) / 1e18; // Scale appropriately

        require(rewardAmount > 0, "QFA: No reward accumulated yet");

        _mintEnergy(msg.sender, rewardAmount);

        // Update last interaction time after claiming
        artifact.lastInteractionTime = uint40(currentTime);

        emit StabilityRewardClaimed(tokenId, msg.sender, rewardAmount);
    }


    /**
     * @notice Abstract function representing one artifact challenging another.
     *         Consumes charge from the challenger and causes parameter changes
     *         in both artifacts based on some logic involving their parameters.
     *         Outcome is simplified/abstract.
     * @param tokenIdChallenger The ID of the challenging artifact.
     * @param tokenIdTarget The ID of the artifact being challenged.
     */
    function challengeArtifact(uint256 tokenIdChallenger, uint256 tokenIdTarget) external whenNotPaused isValidArtifact(tokenIdChallenger) isValidArtifact(tokenIdTarget) {
        require(ownerOf(tokenIdChallenger) == msg.sender, "QFA: Must own the challenger artifact");
        // Allow challenging artifacts owned by others
        require(tokenIdChallenger != tokenIdTarget, "QFA: Cannot challenge itself");
        require(_energyBalances[msg.sender] >= challengeCostEnergy, "QFA: Insufficient Energy for challenge");

         _burnEnergy(msg.sender, challengeCostEnergy);

        _updateArtifactState(tokenIdChallenger); // Apply decay first
        _updateArtifactState(tokenIdTarget);

        Artifact storage challenger = _artifactData[tokenIdChallenger];
        Artifact storage target = _artifactData[tokenIdTarget];

        // Require charge to initiate challenge
        uint256 chargeToUse = 50; // Example charge cost per challenge from artifact
        require(challenger.charge >= chargeToUse, "QFA: Challenger needs more charge");
        challenger.charge -= chargeToUse;

        // Abstract Logic: Challenger's high stability/low entropy vs Target's
        bool challengerSucceeds = (_checkArtifactState(challenger.entropy, challenger.stability) == ArtifactState.Stable) &&
                                  (_checkArtifactState(target.entropy, target.stability) != ArtifactState.Stable);

        if (challengerSucceeds) {
            // Challenger gets a small stability boost, Target loses stability
            challenger.stability += 20;
             if (target.stability >= 30) {
                 target.stability -= 30;
            } else {
                 target.stability = 0;
            }
             emit ArtifactChallenged(tokenIdChallenger, tokenIdTarget, true);
        } else {
            // Challenger loses some stability, Target gains a little
            if (challenger.stability >= 15) {
                challenger.stability -= 15;
            } else {
                challenger.stability = 0;
            }
            target.stability += 10;
            emit ArtifactChallenged(tokenIdChallenger, tokenIdTarget, false);
        }

        // Decay already updated, no need to update lastInteractionTime for challenge effect itself
         // Check state changes for both after challenge
        ArtifactState newChallengerState = _checkArtifactState(challenger.entropy, challenger.stability);
        ArtifactState newTargetState = _checkArtifactState(target.entropy, target.stability);
        // Emitting state changes would require knowing old states here
        // Or rely on subsequent calls to decayProcess to emit state changes
    }

    /**
     * @notice Burns an artifact. The owner receives some QuantumEnergy back based on the artifact's state/parameters.
     * @param tokenId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 tokenId) external whenNotPaused isValidArtifact(tokenId) {
         require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");

         _updateArtifactState(tokenId); // Apply decay before burning to determine final state/value

         Artifact storage artifact = _artifactData[tokenId];
         uint256 energyReturn = (artifact.stability + artifact.charge) / 10; // Example return calculation

         _mintEnergy(msg.sender, energyReturn); // Return energy to owner

         _burn(tokenId);
         delete _artifactData[tokenId];

         emit ArtifactBurned(msg.sender, tokenId, energyReturn);
    }


    /**
     * @notice Allows the owner to spend energy to upgrade a specific parameter's influence
     *         or ceiling on an artifact. This is a simplified example focusing on decay rate.
     * @param tokenId The ID of the artifact to upgrade.
     * @param paramType Identifier for the parameter type (e.g., 1 for DecayRate).
     */
    function upgradeArtifactParameter(uint256 tokenId, uint8 paramType) external whenNotPaused isValidArtifact(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QFA: Must own the artifact");
        require(_energyBalances[msg.sender] >= upgradeCostEnergy, "QFA: Insufficient Energy for upgrade");
        require(paramType == 1, "QFA: Only DecayRate upgrade (type 1) is supported in this version"); // Example

        _burnEnergy(msg.sender, upgradeCostEnergy);

         _updateArtifactState(tokenId); // Apply decay first

        Artifact storage artifact = _artifactData[tokenId];

        // Example Upgrade Logic: Reduce the decay rate permanently
        // Ensures decay rate doesn't go below a base minimum (e.g., 1)
        uint256 upgradeReduction = 2; // Example reduction amount
        if (artifact.decayRate > _globalDecayRateBase) { // Can only reduce if higher than global base
             if (artifact.decayRate >= _globalDecayRateBase + upgradeReduction) {
                  artifact.decayRate -= upgradeReduction;
             } else {
                  artifact.decayRate = _globalDecayRateBase;
             }
        } else {
            revert("QFA: Decay rate cannot be reduced further"); // Or add a different upgrade effect
        }


         emit ParameterUpgraded(tokenId, paramType, artifact.decayRate);
    }


    // --- View Functions ---

    /**
     * @notice Gets the current calculated parameters for an artifact, including time decay since last update.
     * @param tokenId The ID of the artifact.
     * @return entropy, stability, charge, decayRate, lastInteractionTime
     */
    function getArtifactParameters(uint256 tokenId) external view isValidArtifact(tokenId)
        returns (uint256 entropy, uint256 stability, uint256 charge, uint256 decayRate, uint40 lastInteractionTime)
    {
        Artifact storage artifact = _artifactData[tokenId];
        return (
            _calculateCurrentEntropy(tokenId),
            _calculateCurrentStability(tokenId),
            artifact.charge, // Charge is not affected by time decay
            artifact.decayRate,
            artifact.lastInteractionTime
        );
    }

    /**
     * @notice Gets the current calculated state of an artifact, including time decay since last update.
     * @param tokenId The ID of the artifact.
     * @return The current state (Stable, Unstable, Critical).
     */
    function getArtifactState(uint256 tokenId) external view isValidArtifact(tokenId) returns (ArtifactState) {
        uint256 currentEntropy = _calculateCurrentEntropy(tokenId);
        uint256 currentStability = _calculateCurrentStability(tokenId);
        return _checkArtifactState(currentEntropy, currentStability);
    }

    /**
     * @notice Gets the QuantumEnergy balance for an address.
     * @param owner The address to query.
     * @return The QuantumEnergy balance.
     */
    function getEnergyBalance(address owner) external view returns (uint256) {
        return _energyBalances[owner];
    }

    /**
     * @notice Gets the total number of Quantum Artifacts minted.
     * @return The total supply.
     */
    function getTotalArtifactSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @notice Gets a list of token IDs owned by an address.
     * @dev NOTE: This function can be gas-intensive for addresses owning many tokens.
     * @param owner The address to query.
     * @return An array of token IDs.
     */
    function getUserArtifacts(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // Iterating through all possible token IDs is inefficient if supply is huge.
        // A better approach for large collections involves iterating through owners/indices if needed,
        // or relying on external indexing services.
        // For this example, we iterate through potentially minted IDs up to current counter.
        // This is still inefficient for large gaps between minted tokens.
        // A robust implementation would need a linked list or similar structure per owner,
        // or simply accept the gas cost/use off-chain indexers.
        // We'll use a simple iteration up to the counter for demonstration.
        uint256 totalMinted = _tokenIdCounter.current();
        for (uint256 i = 0; i < totalMinted; i++) {
            if (_owners[i] == owner) {
                tokenIds[index] = i;
                index++;
                if (index == tokenCount) { // Optimization: Stop once all owned tokens are found
                     break;
                }
            }
        }
        return tokenIds;
    }


    // --- Admin Functions ---

    /**
     * @notice Allows the owner to set the base rate for time decay affecting all artifacts.
     * @param rate The new global decay rate base (scaled, e.g., 1e18 for 1).
     */
    function setGlobalDecayRate(uint256 rate) external onlyOwner {
        _globalDecayRateBase = rate;
    }

    /**
     * @notice Pauses core contract functionality like minting, fusing, actions.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @notice Allows the owner to withdraw accumulated Ether from the contract balance.
     */
    function withdrawEther() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @notice Allows the owner to withdraw excess QuantumEnergy from the contract's internal balance.
     *         The contract itself might accumulate energy from fees if they existed.
     * @param amount The amount of QuantumEnergy to withdraw.
     */
    function withdrawExcessEnergy(uint256 amount) external onlyOwner {
        // The contract address might hold energy if, for example, energy was burned *to* the contract.
        // In this design, energy primarily moves between users and is minted/burned.
        // This function assumes there might be a contract balance to withdraw.
        require(_energyBalances[address(this)] >= amount, "QFA: Contract has insufficient energy");
        _transferEnergy(address(this), owner(), amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```

**Explanation of Key Concepts & Functions:**

1.  **Evolving NFTs (`Artifact` Struct, `_artifactData`, `_updateArtifactState`, `decayArtifactProcess`, `getArtifactParameters`, `getArtifactState`):** Instead of static metadata, each NFT's `Artifact` struct stores dynamic parameters (`entropy`, `stability`, `charge`, `decayRate`, `lastInteractionTime`). The `_updateArtifactState` internal function calculates how these parameters change based on the time elapsed since the `lastInteractionTime` and the `decayRate`. The `decayArtifactProcess` external function is crucial – it's the mechanism by which users (or automated "keepers") trigger this decay calculation and parameter update for a specific token ID. View functions like `getArtifactParameters` and `getArtifactState` calculate the *potential* current values and state by simulating the decay since the last recorded `lastInteractionTime`.

2.  **Internal Resource (`QuantumEnergy`, `_energyBalances`, `_mintEnergy`, `_burnEnergy`, `_transferEnergy`, `getEnergyBalance`):** An internal token system is implemented via the `_energyBalances` mapping. This token (`QuantumEnergy`) is not a separate ERC-20 contract but lives entirely within the `QuantumFusion` contract. It's used as the cost for most actions (`mint`, `stabilize`, `destabilize`, `charge`, `fuse`, `challenge`, `upgrade`) and is generated as a reward (`claimStabilityReward`, `extractArtifactEnergy`, `burnArtifact`). This keeps interactions self-contained and avoids external token dependencies (except for the initial ETH mint cost).

3.  **Procedural Generation (`_generateInitialParameters`, `mintArtifact`):** When a new artifact is minted (`mintArtifact`), its initial parameters (`entropy`, `stability`, `decayRate`) are not fixed values. They are derived using a deterministic calculation (`_generateInitialParameters`) based on a combination of recent block data, the sender's address, the unique token ID, and a user-provided `salt`. This adds a layer of on-chain, unique initial properties for each artifact without relying on off-chain services.

4.  **Gamified Mechanics (`fuseArtifacts`, `destabilizeArtifact`, `stabilizeArtifact`, `chargeArtifact`, `dischargeArtifact`, `extractArtifactEnergy`, `challengeArtifact`, `upgradeArtifactParameter`, `claimStabilityReward`, `burnArtifact`):** These functions represent the core user interactions that drive the evolution and lifecycle of the artifacts. They consume `QuantumEnergy`, modify artifact parameters, and in some cases, involve interaction between two artifacts (`fuseArtifacts`, `challengeArtifact`). This creates a simple game loop where users manage their artifacts' state by spending energy to counter decay or enhance parameters, aiming for the `Stable` state to earn rewards.

5.  **State Machine (`ArtifactState`, `_checkArtifactState`, `ArtifactStateChanged` event):** Artifacts transition between `Stable`, `Unstable`, and `Critical` states based on their `entropy` and `stability` parameters. The `_checkArtifactState` function determines the current state. The `ArtifactStateChanged` event signals these transitions, allowing external applications to react.

6.  **Decentralized State Updates (`decayArtifactProcess`):** Since smart contracts can't run background processes, the time-based decay isn't automatic. It must be triggered by a transaction. The `decayArtifactProcess` function allows anyone to pay gas to perform this update for a specific artifact. In a real application, off-chain "keeper" bots would likely be used to call this function periodically for all active artifacts, keeping their states relatively current.

7.  **Admin Controls (`Ownable`, `Pausable`, admin functions):** Includes standard ownership and pausing mechanisms to provide control over the contract's operations if needed (e.g., for upgrades, emergency stops). Admin functions for withdrawing funds/energy are also included.

This contract provides a framework for dynamic, interactive NFTs with an internal economy, offering a more complex and engaging model than static digital collectibles. Remember that this is a simplified example; a production version would require extensive testing, gas optimization, potentially more robust randomness (like Chainlink VRF for challenge outcomes), and careful balancing of costs, rewards, and parameter effects.