Okay, here is a smart contract concept focused on dynamic, time-sensitive digital assets with several interacting mechanics, aiming for complexity, creativity, and avoiding direct copies of standard open-source implementations.

It simulates a system of "Chrono-Flux Artifacts" that decay over time but can be reinforced by users, affected by a global "Cosmic Event" state, and involve resource sinks and potential future reward mechanisms.

---

## Smart Contract Outline and Function Summary

**Contract Name:** ChronoFluxArtifacts

**Concept:** This contract manages unique, non-fungible digital artifacts ("Artifacts") with dynamic properties that change over time and based on user interaction and a simulated external state. Each artifact has core properties like `fluxLevel`, `chronoDecayRate`, and `stabilityIndex`.

**Key Mechanics:**
1.  **Time Decay:** `fluxLevel` automatically decreases over time based on `chronoDecayRate`.
2.  **User Reinforcement:** Owners can spend Ether to increase `fluxLevel`, decrease `chronoDecayRate`, or improve `stabilityIndex`.
3.  **Sacrifice:** An owner can burn one artifact to boost another artifact or potentially contribute to a global pool/signal.
4.  **Harvesting/Essence Extraction:** Users can "harvest" `fluxLevel` from their artifacts to gain `essenceCredits`, signaling participation or eligibility for future rewards, while reducing the artifact's current flux.
5.  **Cosmic Events (Simulated Oracle):** A global state variable (`cosmicEventState`) can be updated by an admin. Artifact properties or interaction effects can be influenced by the current cosmic state.
6.  **Protocol Sinks:** Fees from minting and reinforcement are directed into a `fluxPool`, which can be managed by the owner (simulating protocol revenue or a treasury).
7.  **Pausable:** Standard emergency pause functionality.

**Function Summary (Public/External Functions - Targeting >= 20):**

1.  `constructor()`: Deploys the contract and sets the initial owner.
2.  `mintArtifact()`: Creates a new artifact, requires payment, initializes properties, and assigns ownership.
3.  `getArtifactDetails(uint256 artifactId)`: View function to retrieve detailed data for a specific artifact.
4.  `getTotalSupply()`: View function to get the total number of minted artifacts.
5.  `ownerOf(uint256 artifactId)`: View function to get the owner's address of an artifact (basic NFT owner check).
6.  `balanceOf(address owner)`: View function to get the number of artifacts owned by an address (basic NFT balance check).
7.  `calculateCurrentFlux(uint256 artifactId)`: View function to calculate the artifact's current `fluxLevel` accounting for decay since its last update time.
8.  `reinforceArtifact(uint256 artifactId)`: Allows owner to spend ETH to increase the artifact's `fluxLevel`.
9.  `applyStabilityBoost(uint256 artifactId)`: Allows owner to spend ETH to increase the artifact's `stabilityIndex`.
10. `updateChronoDecayRate(uint256 artifactId)`: Allows owner to spend ETH to decrease the artifact's `chronoDecayRate`.
11. `sacrificeArtifact(uint256 sourceArtifactId, uint256 targetArtifactId)`: Allows owner to burn `sourceArtifactId` to apply a boost to `targetArtifactId`.
12. `harvestEssence(uint256 artifactId, uint256 fluxAmountToExtract)`: Allows owner to extract `fluxAmountToExtract` from the artifact's `fluxLevel` and gain `essenceCredits`.
13. `getEssenceCredits(address user)`: View function to retrieve the total `essenceCredits` for a user.
14. `getFluxPoolBalance()`: View function to see the total ETH accumulated in the protocol's `fluxPool`.
15. `withdrawFluxPool(address payable recipient, uint256 amount)`: (Owner Only) Allows withdrawing ETH from the `fluxPool`.
16. `triggerCosmicEventUpdate(uint256 newCosmicState)`: (Owner Only) Updates the global `cosmicEventState`, subject to a cooldown.
17. `getCosmicEventState()`: View function for the current global `cosmicEventState`.
18. `getArtifactCosmicInfluence(uint256 artifactId)`: View function to calculate the current influence of the `cosmicEventState` on an artifact based on its properties.
19. `setMintCost(uint256 cost)`: (Owner Only) Sets the required ETH to mint an artifact.
20. `setReinforceCost(uint256 cost)`: (Owner Only) Sets the cost for `reinforceArtifact`.
21. `setStabilityBoostCost(uint256 cost)`: (Owner Only) Sets the cost for `applyStabilityBoost`.
22. `setDecaySlowCost(uint256 cost)`: (Owner Only) Sets the cost for `updateChronoDecayRate`.
23. `setSacrificeBoostMultiplier(uint256 multiplier)`: (Owner Only) Sets the effectiveness of the sacrifice boost.
24. `setEssenceHarvestRate(uint256 rate)`: (Owner Only) Sets the conversion rate from flux extracted to essence credits.
25. `setCosmicEventCooldown(uint256 cooldownInSeconds)`: (Owner Only) Sets the minimum time between cosmic event updates.
26. `pauseContract()`: (Owner Only) Pauses certain contract interactions.
27. `unpauseContract()`: (Owner Only) Unpauses the contract.
28. `paused()`: View function to check if the contract is paused.
29. `recoverStuckETH(address payable recipient)`: (Owner Only) Allows recovery of any mistakenly sent ETH not intended for protocol pools.
30. `getArtifactLastUpdateTime(uint256 artifactId)`: View function for an artifact's last update timestamp.
31. `getLastCosmicEventTime()`: View function for the last cosmic event update timestamp.
32. `getCosmicEventCooldown()`: View function for the cosmic event update cooldown.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoFluxArtifacts
 * @dev A smart contract managing dynamic digital artifacts with time-decaying properties,
 * user reinforcement, sacrifice mechanics, simulated cosmic event influence,
 * and resource sinks.
 * This contract implements a unique set of mechanics and does not replicate
 * standard open-source token contracts directly.
 */
contract ChronoFluxArtifacts {

    // --- State Variables ---

    // Represents a unique Chrono-Flux Artifact
    struct Artifact {
        uint256 fluxLevel;         // Represents the current power/intensity, decays over time
        uint256 chronoDecayRate;   // Rate at which flux decays per unit of time (lower is better)
        uint256 stabilityIndex;    // Resistance to decay and potentially cosmic events (higher is better)
        uint64 lastUpdateTime;     // Timestamp of the last interaction or state update (used for decay calc)
        uint256 creationTime;      // Timestamp of artifact creation
    }

    mapping(uint256 => Artifact) private _artifacts; // Artifact ID to Artifact data
    mapping(uint256 => address) private _owners;     // Artifact ID to Owner address
    mapping(address => uint256) private _balances;   // Owner address to number of artifacts owned

    uint256 private _nextTokenId; // Counter for assigning unique artifact IDs

    address payable public owner; // Contract owner/admin

    // Protocol Parameters
    uint256 public mintCost = 0.05 ether;
    uint256 public reinforceCost = 0.01 ether;
    uint256 public stabilityBoostCost = 0.02 ether;
    uint256 public decaySlowCost = 0.015 ether;
    uint256 public sacrificeBoostMultiplier = 150; // Boost target by source_flux * multiplier / 100
    uint256 public essenceHarvestRate = 100; // Flux extracted * rate / 100 = essence credits

    // Protocol Sink (accumulates fees)
    uint256 public fluxPool;

    // Essence Credits (accumulate from harvesting)
    mapping(address => uint256) public userEssenceCredits;

    // Simulated Global State
    uint256 public cosmicEventState = 0; // Represents different cosmic conditions (0, 1, 2...)
    uint64 public lastCosmicEventTime;
    uint256 public cosmicEventCooldown = 1 days; // Minimum time between cosmic state updates

    // Pausability
    bool public paused = false;

    // --- Events ---

    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, uint256 initialFlux, uint256 mintCostPaid);
    event ArtifactTransferred(uint256 indexed artifactId, address indexed from, address indexed to);
    event ArtifactPropertiesUpdated(uint256 indexed artifactId, string propertyName, uint256 oldValue, uint256 newValue, uint256 costPaid);
    event ArtifactSacrificed(uint256 indexed sourceArtifactId, uint256 indexed targetArtifactId, uint256 sourceFluxAtSacrifice, uint256 boostAppliedToTarget);
    event EssenceHarvested(uint256 indexed artifactId, address indexed owner, uint256 fluxExtracted, uint256 essenceCreditsEarned);
    event FluxPoolWithdrawn(address indexed recipient, uint256 amount);
    event CosmicEventTriggered(uint256 indexed newCosmicState, uint64 timestamp);
    event ParameterChanged(string indexed parameterName, uint256 newValue);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier artifactExists(uint256 artifactId) {
        require(_exists(artifactId), "Artifact does not exist");
        _;
    }

    modifier isArtifactOwner(uint256 artifactId) {
        require(_isOwner(msg.sender, artifactId), "Caller is not the artifact owner");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = payable(msg.sender);
        _nextTokenId = 1; // Start artifact IDs from 1
        lastCosmicEventTime = uint64(block.timestamp);
    }

    // --- Core Artifact Management (Basic NFT-like) ---

    /**
     * @dev Mints a new Chrono-Flux Artifact.
     * @param initialFlux Initial flux level for the new artifact.
     */
    function mintArtifact(uint256 initialFlux) external payable whenNotPaused {
        require(msg.value >= mintCost, "Insufficient ETH to mint");

        uint256 newArtifactId = _nextTokenId++;
        address minter = msg.sender;

        Artifact memory newArtifact = Artifact({
            fluxLevel: initialFlux,
            chronoDecayRate: 10, // Base decay rate (can be adjusted)
            stabilityIndex: 50,  // Base stability (can be adjusted)
            lastUpdateTime: uint64(block.timestamp),
            creationTime: uint64(block.timestamp)
        });

        _artifacts[newArtifactId] = newArtifact;
        _owners[newArtifactId] = minter;
        _balances[minter]++;

        // Process sink: part of mint cost goes to the flux pool
        uint256 sinkAmount = msg.value / 2; // Example: 50% goes to pool
        fluxPool += sinkAmount;

        // Refund any excess ETH
        if (msg.value > mintCost) {
            payable(minter).transfer(msg.value - mintCost);
        }

        emit ArtifactMinted(newArtifactId, minter, initialFlux, msg.value);
    }

    /**
     * @dev Transfers ownership of an artifact.
     * @param to The address to transfer the artifact to.
     * @param artifactId The ID of the artifact to transfer.
     */
    function transferArtifact(address to, uint256 artifactId)
        external
        whenNotPaused
        artifactExists(artifactId)
        isArtifactOwner(artifactId)
    {
        require(to != address(0), "Transfer to the zero address is not allowed");

        address from = msg.sender;

        // Update artifact state before transfer to account for decay up to this point
        _updateArtifactState(artifactId);

        _beforeTokenTransfer(from, to, artifactId);

        _balances[from]--;
        _owners[artifactId] = to;
        _balances[to]++;

        emit ArtifactTransferred(artifactId, from, to);
    }

    /**
     * @dev Gets the details of a specific artifact.
     * @param artifactId The ID of the artifact.
     * @return Artifact struct containing its properties.
     */
    function getArtifactDetails(uint256 artifactId) public view artifactExists(artifactId) returns (Artifact memory) {
        // Note: This returns the *stored* state. Use calculateCurrentFlux for decay-adjusted flux.
        return _artifacts[artifactId];
    }

    /**
     * @dev Returns the total number of artifacts minted.
     */
    function getTotalSupply() external view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @dev Returns the owner of a specific artifact.
     * @param artifactId The ID of the artifact.
     * @return The owner's address.
     */
    function ownerOf(uint256 artifactId) external view artifactExists(artifactId) returns (address) {
        return _owners[artifactId];
    }

    /**
     * @dev Returns the number of artifacts owned by an address.
     * @param owner The address to check.
     * @return The balance of artifacts for the address.
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    // --- Dynamic State Interaction & Calculation ---

    /**
     * @dev Calculates the current flux level of an artifact, accounting for decay
     * since its last update time. Does NOT modify the stored state.
     * @param artifactId The ID of the artifact.
     * @return The calculated current flux level.
     */
    function calculateCurrentFlux(uint256 artifactId) public view artifactExists(artifactId) returns (uint256) {
        Artifact storage artifact = _artifacts[artifactId];
        uint256 timeElapsed = block.timestamp - artifact.lastUpdateTime;

        // Decay calculation: Simple linear decay for demonstration
        // More complex decay models (e.g., exponential) could be used
        uint256 decayAmount = (timeElapsed * artifact.chronoDecayRate) / 1000; // Decay rate is per 1000 seconds for granularity

        // Apply stability influence (higher stability reduces decay)
        decayAmount = (decayAmount * (100 - artifact.stabilityIndex > 0 ? 100 - artifact.stabilityIndex : 0)) / 100; // Example influence

        if (decayAmount >= artifact.fluxLevel) {
            return 0;
        } else {
            return artifact.fluxLevel - decayAmount;
        }
    }

    /**
     * @dev Internal function to update an artifact's state by applying decay.
     * Called before interactions that rely on or change the flux level.
     * @param artifactId The ID of the artifact.
     */
    function _updateArtifactState(uint256 artifactId) internal artifactExists(artifactId) {
        Artifact storage artifact = _artifacts[artifactId];
        uint256 currentFlux = calculateCurrentFlux(artifactId);
        artifact.fluxLevel = currentFlux;
        artifact.lastUpdateTime = uint64(block.timestamp);
    }

    /**
     * @dev Spends ETH to increase an artifact's flux level.
     * @param artifactId The ID of the artifact to reinforce.
     */
    function reinforceArtifact(uint256 artifactId)
        external
        payable
        whenNotPaused
        artifactExists(artifactId)
        isArtifactOwner(artifactId)
    {
        require(msg.value >= reinforceCost, "Insufficient ETH to reinforce");

        _updateArtifactState(artifactId); // Apply decay before boosting

        Artifact storage artifact = _artifacts[artifactId];
        // Simple boost: add a flat amount based on cost or a parameter
        uint256 boostAmount = 100; // Example boost
        artifact.fluxLevel += boostAmount;

        // Process sink
        fluxPool += msg.value; // Entire cost goes to pool

        emit ArtifactPropertiesUpdated(artifactId, "fluxLevel", artifact.fluxLevel - boostAmount, artifact.fluxLevel, msg.value);

        // Refund any excess ETH
        if (msg.value > reinforceCost) {
            payable(msg.sender).transfer(msg.value - reinforceCost);
        }
    }

    /**
     * @dev Spends ETH to increase an artifact's stability index.
     * @param artifactId The ID of the artifact to boost.
     */
    function applyStabilityBoost(uint256 artifactId)
        external
        payable
        whenNotPaused
        artifactExists(artifactId)
        isArtifactOwner(artifactId)
    {
        require(msg.value >= stabilityBoostCost, "Insufficient ETH for stability boost");

        _updateArtifactState(artifactId); // Apply decay before boosting

        Artifact storage artifact = _artifacts[artifactId];
        uint256 oldStability = artifact.stabilityIndex;
        // Simple boost: add a flat amount, cap at 100
        artifact.stabilityIndex = artifact.stabilityIndex + 5 > 100 ? 100 : artifact.stabilityIndex + 5; // Example boost amount

        // Process sink
        fluxPool += msg.value;

        emit ArtifactPropertiesUpdated(artifactId, "stabilityIndex", oldStability, artifact.stabilityIndex, msg.value);

        // Refund any excess ETH
        if (msg.value > stabilityBoostCost) {
            payable(msg.sender).transfer(msg.value - stabilityBoostCost);
        }
    }

    /**
     * @dev Spends ETH to decrease an artifact's chrono decay rate.
     * @param artifactId The ID of the artifact to modify.
     */
    function updateChronoDecayRate(uint256 artifactId)
        external
        payable
        whenNotPaused
        artifactExists(artifactId)
        isArtifactOwner(artifactId)
    {
        require(msg.value >= decaySlowCost, "Insufficient ETH to slow decay");

        _updateArtifactState(artifactId); // Apply decay before modifying rate

        Artifact storage artifact = _artifacts[artifactId];
        uint256 oldRate = artifact.chronoDecayRate;
        // Simple decrease: subtract a flat amount, minimum rate of 1
        artifact.chronoDecayRate = artifact.chronoDecayRate < 2 ? 1 : artifact.chronoDecayRate - 1; // Example decrease

        // Process sink
        fluxPool += msg.value;

        emit ArtifactPropertiesUpdated(artifactId, "chronoDecayRate", oldRate, artifact.chronoDecayRate, msg.value);

        // Refund any excess ETH
        if (msg.value > decaySlowCost) {
            payable(msg.sender).transfer(msg.value - decaySlowCost);
        }
    }

    /**
     * @dev Sacrifices one artifact to boost another. The source artifact is burned.
     * @param sourceArtifactId The ID of the artifact to sacrifice.
     * @param targetArtifactId The ID of the artifact to boost.
     */
    function sacrificeArtifact(uint256 sourceArtifactId, uint256 targetArtifactId)
        external
        whenNotPaused
        artifactExists(sourceArtifactId)
        artifactExists(targetArtifactId)
        isArtifactOwner(sourceArtifactId)
        isArtifactOwner(targetArtifactId) // Requires owner to own both
    {
        require(sourceArtifactId != targetArtifactId, "Cannot sacrifice an artifact to itself");

        // Update states before calculating boost and burning
        _updateArtifactState(sourceArtifactId);
        _updateArtifactState(targetArtifactId);

        Artifact storage sourceArtifact = _artifacts[sourceArtifactId];
        Artifact storage targetArtifact = _artifacts[targetArtifactId];

        uint256 sourceFluxAtSacrifice = sourceArtifact.fluxLevel;

        // Calculate boost amount based on source flux and multiplier
        uint256 boostAmount = (sourceFluxAtSacrifice * sacrificeBoostMultiplier) / 100;

        // Apply boost to target artifact (e.g., flux level)
        targetArtifact.fluxLevel += boostAmount;

        // Burn the source artifact
        address ownerAddress = _owners[sourceArtifactId];
        _beforeTokenTransfer(ownerAddress, address(0), sourceArtifactId); // Signal burn

        _balances[ownerAddress]--;
        delete _owners[sourceArtifactId];
        delete _artifacts[sourceArtifactId]; // Remove artifact data

        emit ArtifactSacrificed(sourceArtifactId, targetArtifactId, sourceFluxAtSacrifice, boostAmount);
    }

    /**
     * @dev Extracts flux from an artifact to gain essence credits. Reduces the artifact's flux.
     * @param artifactId The ID of the artifact to harvest from.
     * @param fluxAmountToExtract The amount of flux to remove and convert to essence.
     */
    function harvestEssence(uint256 artifactId, uint256 fluxAmountToExtract)
        external
        whenNotPaused
        artifactExists(artifactId)
        isArtifactOwner(artifactId)
    {
        _updateArtifactState(artifactId); // Apply decay before harvesting

        Artifact storage artifact = _artifacts[artifactId];
        require(fluxAmountToExtract > 0, "Amount to extract must be greater than zero");
        require(artifact.fluxLevel >= fluxAmountToExtract, "Not enough flux in artifact to extract that amount");

        artifact.fluxLevel -= fluxAmountToExtract;

        // Calculate essence credits gained
        uint256 essenceEarned = (fluxAmountToExtract * essenceHarvestRate) / 100;
        userEssenceCredits[msg.sender] += essenceEarned;

        emit EssenceHarvested(artifactId, msg.sender, fluxAmountToExtract, essenceEarned);
    }

    /**
     * @dev Gets the total essence credits for a user.
     * @param user The address of the user.
     * @return The total essence credits.
     */
    function getEssenceCredits(address user) external view returns (uint256) {
        return userEssenceCredits[user];
    }


    // --- Resource & Pool Management ---

    /**
     * @dev Gets the current balance of the protocol's flux pool.
     */
    function getFluxPoolBalance() external view returns (uint256) {
        return address(this).balance - (msg.value); // Exclude current call's ETH if payable, but this is view
        // A more robust way if ETH could be sent to arbitrary functions: track balance internally
        // For this contract, ETH only enters via payable functions and goes to fluxPool/owner
        // So address(this).balance less owner's withdrawn amount is effectively the pool.
        // Let's just return the explicit fluxPool variable for clarity
        return fluxPool;
    }

    /**
     * @dev Allows the owner to withdraw from the flux pool.
     * @param recipient The address to send the ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawFluxPool(address payable recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(fluxPool >= amount, "Insufficient funds in flux pool");

        fluxPool -= amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit FluxPoolWithdrawn(recipient, amount);
    }

    // --- Global State & Simulated Oracle ---

    /**
     * @dev (Owner Only) Triggers an update to the cosmic event state.
     * Subject to a cooldown period.
     * @param newCosmicState The new state value (e.g., 1, 2, 3).
     */
    function triggerCosmicEventUpdate(uint256 newCosmicState) external onlyOwner {
        require(block.timestamp >= lastCosmicEventTime + cosmicEventCooldown, "Cosmic event update is on cooldown");
        cosmicEventState = newCosmicState;
        lastCosmicEventTime = uint64(block.timestamp);
        emit CosmicEventTriggered(newCosmicState, lastCosmicEventTime);
    }

    /**
     * @dev Gets the current global cosmic event state.
     */
    function getCosmicEventState() external view returns (uint256) {
        return cosmicEventState;
    }

    /**
     * @dev Calculates a potential influence value based on the artifact's properties
     * and the current cosmic event state. This is a *view* function demonstrating
     * how an artifact's state might interact with a global state.
     * Actual effects would be applied in other functions (e.g., boost/decay calculations).
     * @param artifactId The ID of the artifact.
     * @return An example influence value.
     */
    function getArtifactCosmicInfluence(uint256 artifactId) public view artifactExists(artifactId) returns (uint256) {
        Artifact storage artifact = _artifacts[artifactId];
        uint256 influence = 0;

        // Example logic:
        // State 0: No influence
        // State 1: Stability index matters more (e.g., adds to flux)
        // State 2: Decay rate matters more (e.g., reduces flux)
        // State > 2: Combination or different effects

        if (cosmicEventState == 1) {
            influence = (artifact.stabilityIndex * 10); // Higher stability, more positive influence
        } else if (cosmicEventState == 2) {
            influence = (artifact.chronoDecayRate * 5); // Higher decay rate, more negative influence (returns positive value here, interpretation is external)
        }
        // Note: This is a simplified example. Real influence would apply as multipliers/offsets
        // in functions like calculateCurrentFlux or reinforceArtifact.

        return influence;
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the required ETH to mint an artifact.
     * @param cost The new mint cost in wei.
     */
    function setMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
        emit ParameterChanged("mintCost", cost);
    }

     /**
     * @dev Sets the required ETH to reinforce an artifact.
     * @param cost The new reinforce cost in wei.
     */
    function setReinforceCost(uint256 cost) external onlyOwner {
        reinforceCost = cost;
        emit ParameterChanged("reinforceCost", cost);
    }

    /**
     * @dev Sets the required ETH for stability boost.
     * @param cost The new cost in wei.
     */
    function setStabilityBoostCost(uint256 cost) external onlyOwner {
        stabilityBoostCost = cost;
        emit ParameterChanged("stabilityBoostCost", cost);
    }

    /**
     * @dev Sets the required ETH to slow decay.
     * @param cost The new cost in wei.
     */
    function setDecaySlowCost(uint256 cost) external onlyOwner {
        decaySlowCost = cost;
        emit ParameterChanged("decaySlowCost", cost);
    }

    /**
     * @dev Sets the multiplier for the sacrifice boost calculation.
     * @param multiplier The new multiplier (e.g., 150 for 1.5x).
     */
    function setSacrificeBoostMultiplier(uint256 multiplier) external onlyOwner {
        sacrificeBoostMultiplier = multiplier;
        emit ParameterChanged("sacrificeBoostMultiplier", multiplier);
    }

     /**
     * @dev Sets the conversion rate from flux extracted to essence credits.
     * @param rate The new rate (e.g., 100 for 1:1).
     */
    function setEssenceHarvestRate(uint256 rate) external onlyOwner {
        essenceHarvestRate = rate;
        emit ParameterChanged("essenceHarvestRate", rate);
    }


    /**
     * @dev Sets the cooldown duration for cosmic event updates.
     * @param cooldownInSeconds The cooldown in seconds.
     */
    function setCosmicEventCooldown(uint256 cooldownInSeconds) external onlyOwner {
        cosmicEventCooldown = cooldownInSeconds;
        emit ParameterChanged("cosmicEventCooldown", cooldownInSeconds);
    }

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Returns the current pause status.
     */
    function paused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Allows owner to recover ETH accidentally sent to the contract
     * that is not part of the intended fluxPool.
     * @param recipient The address to send ETH to.
     */
    function recoverStuckETH(address payable recipient) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawable = contractBalance - fluxPool; // Assume any ETH not in fluxPool is stuck
        require(withdrawable > 0, "No stuck ETH to recover");

        (bool success, ) = recipient.call{value: withdrawable}("");
        require(success, "ETH transfer failed");
    }

    // --- View Helpers ---

     /**
     * @dev Gets the last update timestamp for an artifact.
     * @param artifactId The ID of the artifact.
     */
    function getArtifactLastUpdateTime(uint256 artifactId) external view artifactExists(artifactId) returns (uint64) {
        return _artifacts[artifactId].lastUpdateTime;
    }

     /**
     * @dev Gets the timestamp of the last cosmic event update.
     */
    function getLastCosmicEventTime() external view returns (uint64) {
        return lastCosmicEventTime;
    }

     /**
     * @dev Gets the cooldown duration for cosmic event updates.
     */
    function getCosmicEventCooldown() external view returns (uint256) {
        return cosmicEventCooldown;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Checks if an artifact exists.
     */
    function _exists(uint256 artifactId) internal view returns (bool) {
        // Artifacts are deleted on sacrifice, check owner existence
        return _owners[artifactId] != address(0);
    }

    /**
     * @dev Checks if an address is the owner of an artifact.
     */
    function _isOwner(address account, uint256 artifactId) internal view returns (bool) {
        return _owners[artifactId] == account;
    }

    /**
     * @dev Internal hook called before any token transfer (including minting and burning).
     * Not required for this contract's mechanics but useful for standard hooks.
     */
    function _beforeTokenTransfer(address from, address to, uint256 artifactId) internal {
        // Optional: Add custom logic here before transfer/mint/burn
        // e.g., snapshotting state, checking transfer conditions
    }

    // Receive and fallback functions to handle incoming ETH
    receive() external payable {
        // Optionally log or revert if unexpected ETH is sent
        // Revert by default if not handled by payable functions like mint
        revert("Unexpected ETH received. Use specific payable functions.");
    }

    fallback() external payable {
         // Optionally log or revert if unexpected ETH is sent to non-existent function
        revert("Call to non-existent function or unexpected ETH.");
    }
}
```