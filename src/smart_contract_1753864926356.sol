Okay, this is an exciting challenge! Let's build something truly unique that combines dynamic NFTs, probabilistic state transitions, resource distribution, and oracle-driven adaptability.

I'll call this protocol **"QuantumLeap Protocol"**.

**Core Concept:**
The QuantumLeap Protocol manages **Entangled Assets (EAs)**, which are dynamic, probabilistic NFTs. These assets exist in various **Quantum States**, each with unique properties and probabilities of transitioning to other states. Users can influence these transitions by setting "attractors" on their assets, which modify the base probabilities. The protocol also features **Graviton Pools**, which are resource pools that distribute their contents to Entangled Assets based on their current Quantum State and how long they've been in "Superposition Staking". External data from an **Oracle Nexus** can dynamically adjust global state probabilities or Graviton Pool distributions. The core mechanic is `executeQuantumLeap`, a function that performs a probabilistic state transition for an Entangled Asset.

---

## QuantumLeap Protocol: Outline and Function Summary

**Contract Name:** `QuantumLeapProtocol`

**Core Idea:** A protocol for dynamic, probabilistic non-fungible tokens (Entangled Assets) whose "Quantum States" evolve based on internal and external factors, influencing resource distribution from "Graviton Pools".

**Key Components:**
1.  **Entangled Assets (EAs):** ERC721-compliant NFTs that possess unique `attractors` and a mutable `quantumStateId`.
2.  **Quantum States:** Pre-defined states (e.g., "Stable," "Volatile," "Ascendant") each with base transition probabilities to other states.
3.  **Graviton Pools:** ERC20/Ether reservoirs that distribute resources (yield) to Entangled Assets based on their current Quantum State and time staked in "Superposition".
4.  **Oracle Nexus:** A module to integrate external, real-world data that can dynamically influence state transition probabilities or Graviton Pool distributions.
5.  **Superposition Staking:** A mechanism where EAs can be staked, putting them into a "superposition" of potential states, accumulating yield, and potentially affecting future leaps.

---

**Function Summary (26 Functions):**

**I. Core Protocol Administration & Setup (Owner-only)**
1.  `addQuantumState`: Defines a new possible Quantum State with its base properties.
2.  `updateQuantumStateProbabilities`: Adjusts the base probability of transitioning from one state to another.
3.  `createGravitonPool`: Initializes a new resource pool for distribution.
4.  `setOracleAddress`: Registers the address of a trusted external oracle.
5.  `updateOracleDataValidityPeriod`: Sets how long oracle data is considered fresh.
6.  `setLeapGasCost`: Configures the base ETH cost for performing a `QuantumLeap`.
7.  `setSuperpositionYieldRate`: Sets the base yield rate for Superposition Staking.
8.  `setAttractorInfluenceMultiplier`: Defines how much an asset's `attractors` influence leap probabilities.
9.  `togglePause`: Pauses/unpauses core contract functionalities in an emergency.

**II. Entangled Asset (EA) Management & Evolution**
10. `mintEntangledAsset`: Mints a new Entangled Asset to a recipient, assigning an initial state.
11. `executeQuantumLeap`: The core dynamic function. Triggers a probabilistic state transition for an EA based on its current state, `attractors`, global probabilities, and oracle data.
12. `setAssetAttractors`: Allows the EA owner to define or update their asset's custom "attractor" values, influencing its future leaps.
13. `transferFrom`: Standard ERC721 function to transfer ownership of an EA.
14. `approve`: Standard ERC721 function to approve another address to transfer an EA.
15. `setApprovalForAll`: Standard ERC721 function to approve an operator for all EAs.

**III. Superposition Staking (Dynamic Yield)**
16. `enterSuperpositionStake`: Stakes an Entangled Asset, making it eligible for Graviton Pool yields and potentially influencing its future leap outcomes.
17. `exitSuperpositionStake`: Unstakes an Entangled Asset, stopping yield accumulation.
18. `claimSuperpositionYield`: Allows stakers to claim accumulated yield from Graviton Pools.

**IV. Graviton Pool Operations**
19. `depositIntoGravitonPool`: Allows users/protocols to deposit funds (e.g., ERC20, ETH) into a Graviton Pool.
20. `distributeGravitons`: Triggers the distribution of funds from a Graviton Pool to eligible Entangled Assets based on their current state and staking status.
21. `claimGravitonShare`: Allows Entangled Asset owners to claim their distributed share from a Graviton Pool.

**V. Oracle Integration (Simulated/Advanced)**
22. `requestOracleData`: (Simulated) Initiates a request for specific off-chain data from the Oracle Nexus.
23. `fulfillOracleData`: (Callback from Oracle, simulated as owner-only for demonstration) Updates internal state based on received oracle data, which then influences probabilities or distributions.

**VI. Query & View Functions**
24. `getAssetDetails`: Returns all relevant details of an Entangled Asset (owner, state, attractors, staking info).
25. `getQuantumStateDetails`: Returns the properties of a specific Quantum State.
26. `calculateLeapOutcomeProbability`: Estimates the probability of an Entangled Asset transitioning to a specific target state if `executeQuantumLeap` were called.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For Graviton Pools holding ERC20s

/**
 * @title QuantumLeapProtocol
 * @dev A novel protocol for dynamic, probabilistic NFTs (Entangled Assets) that evolve
 *      based on internal attributes, probabilistic leaps, external oracle data, and
 *      influence resource distribution from Graviton Pools.
 *      Inspired by quantum mechanics concepts like superposition and state transitions.
 *
 * Outline and Function Summary:
 *
 * I. Core Protocol Administration & Setup (Owner-only)
 *    1. addQuantumState: Defines a new possible Quantum State.
 *    2. updateQuantumStateProbabilities: Adjusts transition probabilities between states.
 *    3. createGravitonPool: Initializes a new resource pool.
 *    4. setOracleAddress: Registers the address of a trusted external oracle.
 *    5. updateOracleDataValidityPeriod: Sets how long oracle data is considered fresh.
 *    6. setLeapGasCost: Configures the base ETH cost for performing a QuantumLeap.
 *    7. setSuperpositionYieldRate: Sets the base yield rate for Superposition Staking.
 *    8. setAttractorInfluenceMultiplier: Defines influence of asset's attractors on leaps.
 *    9. togglePause: Pauses/unpauses core contract functionalities.
 *
 * II. Entangled Asset (EA) Management & Evolution
 *    10. mintEntangledAsset: Mints a new Entangled Asset (EA).
 *    11. executeQuantumLeap: Triggers a probabilistic state transition for an EA.
 *    12. setAssetAttractors: Allows EA owners to define custom "attractor" values.
 *    13. transferFrom: Standard ERC721 transfer.
 *    14. approve: Standard ERC721 approval.
 *    15. setApprovalForAll: Standard ERC721 operator approval.
 *
 * III. Superposition Staking (Dynamic Yield)
 *    16. enterSuperpositionStake: Stakes an EA for yield and leap influence.
 *    17. exitSuperpositionStake: Unstakes an EA.
 *    18. claimSuperpositionYield: Claims accumulated yield from pools.
 *
 * IV. Graviton Pool Operations
 *    19. depositIntoGravitonPool: Deposits funds into a Graviton Pool.
 *    20. distributeGravitons: Triggers distribution of funds from a pool.
 *    21. claimGravitonShare: Claims distributed share from a pool.
 *
 * V. Oracle Integration (Simulated/Advanced)
 *    22. requestOracleData: (Simulated) Initiates an off-chain data request.
 *    23. fulfillOracleData: (Simulated Callback) Updates internal state from oracle data.
 *
 * VI. Query & View Functions
 *    24. getAssetDetails: Returns details of an Entangled Asset.
 *    25. getQuantumStateDetails: Returns properties of a Quantum State.
 *    26. calculateLeapOutcomeProbability: Estimates a specific leap probability.
 */
contract QuantumLeapProtocol is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _assetIds;
    Counters.Counter private _quantumStateIds;
    Counters.Counter private _gravitonPoolIds;

    // --- Data Structures ---

    struct EntangledAsset {
        uint256 id;
        uint256 quantumStateId; // Current state ID
        mapping(string => uint256) attractors; // Custom attributes influencing leaps (e.g., "energy": 100, "resilience": 50)
        uint256 lastLeapTimestamp; // Cooldown for leaps
        bool isInSuperposition; // True if staked
        uint256 superpositionStakeTimestamp; // When staking began
        uint256 totalYieldClaimed; // Total yield claimed by this asset
    }

    struct QuantumState {
        uint256 id;
        string name;
        string description;
        bool exists; // To check if stateId is valid
    }

    // Mapping from sourceStateId -> targetStateId -> baseProbability (out of 10000)
    mapping(uint256 => mapping(uint256 => uint256)) public quantumStateBaseProbabilities;

    struct GravitonPool {
        uint256 id;
        string name;
        address assetAddress; // Address of the ERC20 token, or address(0) for native ETH
        uint256 totalDistributedAmount; // Total amount distributed from this pool
        uint256 lastDistributionTimestamp; // Timestamp of the last distribution
        uint256 distributionInterval; // How often distribution can occur (e.g., 1 day)
        uint256 totalEligibleSuperpositionTime; // Accumulator for distribution calculations
    }

    struct OracleData {
        uint256 value; // The actual data (e.g., market volatility index)
        uint256 lastUpdateTimestamp;
    }

    // --- Mappings ---
    mapping(uint255 => EntangledAsset) public entangledAssets; // assetId => EntangledAsset
    mapping(uint255 => uint256) public assetQuantumState; // assetId => current quantumStateId
    mapping(uint256 => QuantumState) public quantumStates; // stateId => QuantumState
    mapping(uint256 => GravitonPool) public gravitonPools; // poolId => GravitonPool

    // Staking tracking: assetId => poolId => claimed share
    mapping(uint256 => mapping(uint256 => uint256)) public assetGravitonShareClaimed;

    // Oracle Nexus: dataSourceKey (e.g., "ETH_VOLATILITY") => OracleData
    mapping(string => OracleData) public oracleNexus;

    // Mapping for per-state oracle influence: stateId => oracleDataSourceKey => influenceMultiplier (e.g., 100 = 1x)
    mapping(uint256 => mapping(string => uint256)) public stateOracleInfluence;

    // --- Configuration Variables ---
    uint256 public leapGasCost = 0.005 ether; // Default gas cost in ETH
    uint256 public superpositionYieldRatePerSec = 1000; // Basis points per second for yield calculation (e.g., 1000 = 0.01%)
    uint256 public attractorInfluenceMultiplier = 100; // Multiplier for how much attractors affect probabilities (e.g., 100 = 1x)
    address public oracleAddress; // Address authorized to fulfill oracle data requests
    uint256 public oracleDataValidityPeriod = 24 * 3600; // 24 hours in seconds

    bool public paused = false;

    // --- Events ---
    event EntangledAssetMinted(uint256 indexed assetId, address indexed owner, uint256 initialStateId);
    event QuantumLeapExecuted(uint256 indexed assetId, uint256 oldStateId, uint256 newStateId, uint256 randomSeed);
    event AssetAttractorsUpdated(uint256 indexed assetId, string attractorName, uint256 value);
    event SuperpositionStakeEntered(uint256 indexed assetId, address indexed owner);
    event SuperpositionStakeExited(uint256 indexed assetId, address indexed owner);
    event SuperpositionYieldClaimed(uint256 indexed assetId, address indexed owner, uint256 amount);
    event QuantumStateAdded(uint256 indexed stateId, string name);
    event QuantumStateProbabilitiesUpdated(uint256 indexed fromStateId, uint256 indexed toStateId, uint256 newProbability);
    event GravitonPoolCreated(uint256 indexed poolId, string name, address assetAddress);
    event FundsDepositedIntoPool(uint256 indexed poolId, address indexed depositor, uint256 amount);
    event GravitonsDistributed(uint256 indexed poolId, uint256 totalAmountDistributed);
    event GravitonShareClaimed(uint256 indexed poolId, uint256 indexed assetId, address indexed claimant, uint256 amount);
    event OracleDataRequested(string indexed dataSourceKey);
    event OracleDataFulfilled(string indexed dataSourceKey, uint256 value, uint256 timestamp);
    event ProtocolPaused(bool _paused);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Protocol: Paused");
        _;
    }

    modifier assetExists(uint256 _assetId) {
        require(_exists(_assetId), "Asset: Does not exist");
        _;
    }

    modifier isQuantumState(uint256 _stateId) {
        require(quantumStates[_stateId].exists, "State: Does not exist");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the Oracle");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("EntangledAsset", "EA") Ownable(msg.sender) {
        // Add an initial default Quantum State (e.g., "Stable")
        _quantumStateIds.increment();
        uint256 initialStateId = _quantumStateIds.current();
        quantumStates[initialStateId] = QuantumState(initialStateId, "Stable", "Initial stable state", true);
        emit QuantumStateAdded(initialStateId, "Stable");

        // Set a default oracle address for demonstration (can be updated by owner)
        oracleAddress = owner(); // For testing, owner acts as oracle
    }

    // --- I. Core Protocol Administration & Setup ---

    /**
     * @dev Adds a new Quantum State to the protocol.
     * @param _name The name of the new state (e.g., "Volatile", "Ascendant").
     * @param _description A brief description of the state.
     */
    function addQuantumState(string calldata _name, string calldata _description) external onlyOwner {
        _quantumStateIds.increment();
        uint256 newId = _quantumStateIds.current();
        quantumStates[newId] = QuantumState(newId, _name, _description, true);
        emit QuantumStateAdded(newId, _name);
    }

    /**
     * @dev Updates the base probability of transitioning from a source state to a target state.
     *      Probabilities are out of 10000 (e.g., 5000 = 50%).
     *      All outgoing probabilities from a source state must sum up to 10000.
     *      This function sets individual probabilities, requiring owner to manage sum externally.
     *      In a production system, this might be managed by a DAO or a more complex probability curve.
     * @param _fromStateId The ID of the source Quantum State.
     * @param _toStateId The ID of the target Quantum State.
     * @param _probability The new base probability (0-10000).
     */
    function updateQuantumStateProbabilities(
        uint256 _fromStateId,
        uint256 _toStateId,
        uint256 _probability
    ) external onlyOwner isQuantumState(_fromStateId) isQuantumState(_toStateId) {
        require(_probability <= 10000, "Probability must be <= 10000");
        quantumStateBaseProbabilities[_fromStateId][_toStateId] = _probability;
        emit QuantumStateProbabilitiesUpdated(_fromStateId, _toStateId, _probability);
    }

    /**
     * @dev Creates a new Graviton Pool for resource distribution.
     * @param _name The name of the Graviton Pool.
     * @param _assetAddress The address of the ERC20 token to be held/distributed, or address(0) for native ETH.
     * @param _distributionInterval The time interval (in seconds) between distributions.
     */
    function createGravitonPool(
        string calldata _name,
        address _assetAddress,
        uint256 _distributionInterval
    ) external onlyOwner {
        _gravitonPoolIds.increment();
        uint256 newPoolId = _gravitonPoolIds.current();
        gravitonPools[newPoolId] = GravitonPool(
            newPoolId,
            _name,
            _assetAddress,
            0, // totalDistributedAmount
            block.timestamp, // lastDistributionTimestamp (initial)
            _distributionInterval,
            0 // totalEligibleSuperpositionTime
        );
        emit GravitonPoolCreated(newPoolId, _name, _assetAddress);
    }

    /**
     * @dev Sets the address of the trusted external oracle. Only this address can call `fulfillOracleData`.
     * @param _oracleAddress The address of the oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Updates the period for which oracle data is considered valid/fresh.
     * @param _period The validity period in seconds.
     */
    function updateOracleDataValidityPeriod(uint256 _period) external onlyOwner {
        oracleDataValidityPeriod = _period;
    }

    /**
     * @dev Sets the base ETH cost required to execute a QuantumLeap.
     * @param _cost The new cost in wei.
     */
    function setLeapGasCost(uint256 _cost) external onlyOwner {
        leapGasCost = _cost;
    }

    /**
     * @dev Sets the base yield rate for assets in Superposition Staking.
     *      Expressed in basis points per second (e.g., 1000 = 0.1% per second).
     * @param _rate The new yield rate.
     */
    function setSuperpositionYieldRate(uint256 _rate) external onlyOwner {
        superpositionYieldRatePerSec = _rate;
    }

    /**
     * @dev Sets the multiplier for how much an asset's `attractors` influence leap probabilities.
     * @param _multiplier The new multiplier (e.g., 100 for 1x influence).
     */
    function setAttractorInfluenceMultiplier(uint256 _multiplier) external onlyOwner {
        attractorInfluenceMultiplier = _multiplier;
    }

    /**
     * @dev Toggles the paused state of the protocol. When paused, core functions are disabled.
     * @param _paused True to pause, false to unpause.
     */
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        emit ProtocolPaused(_paused);
    }

    // --- II. Entangled Asset (EA) Management & Evolution ---

    /**
     * @dev Mints a new Entangled Asset to a specified recipient.
     * @param _to The address to mint the asset to.
     * @param _initialStateId The initial Quantum State ID for the new asset.
     */
    function mintEntangledAsset(address _to, uint256 _initialStateId)
        external
        whenNotPaused
        isQuantumState(_initialStateId)
        returns (uint256)
    {
        _assetIds.increment();
        uint256 newAssetId = _assetIds.current();

        _safeMint(_to, newAssetId); // ERC721 minting

        entangledAssets[newAssetId] = EntangledAsset({
            id: newAssetId,
            quantumStateId: _initialStateId,
            lastLeapTimestamp: block.timestamp,
            isInSuperposition: false,
            superpositionStakeTimestamp: 0,
            totalYieldClaimed: 0
        });
        assetQuantumState[newAssetId] = _initialStateId;

        emit EntangledAssetMinted(newAssetId, _to, _initialStateId);
        return newAssetId;
    }

    /**
     * @dev Executes a Quantum Leap for an Entangled Asset,
     *      probabilistically transitioning it to a new Quantum State.
     *      Requires payment of `leapGasCost`.
     *      The randomness is pseudo-random for demonstration; use Chainlink VRF or similar in production.
     * @param _assetId The ID of the Entangled Asset to leap.
     */
    function executeQuantumLeap(uint256 _assetId)
        external
        payable
        whenNotPaused
        assetExists(_assetId)
    {
        require(msg.sender == ownerOf(_assetId), "Leap: Not asset owner");
        require(msg.value >= leapGasCost, "Leap: Insufficient payment");

        // Simple pseudo-randomness for demonstration. Use Chainlink VRF for production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _assetId))) % 10000;

        uint256 currentQuantumStateId = assetQuantumState[_assetId];
        EntangledAsset storage asset = entangledAssets[_assetId];

        // Ensure sufficient time has passed since last leap to prevent spamming
        // (This would ideally be a configurable cooldown based on state or asset traits)
        require(block.timestamp >= asset.lastLeapTimestamp + 10, "Leap: Cooldown active (10s)"); // Example cooldown

        uint256 accumulatedProbability = 0;
        uint256 newStateId = currentQuantumStateId; // Default to current state if no other state is chosen

        // Calculate total probability weight for normalization
        uint256 totalWeight = 0;
        for (uint256 i = 1; i <= _quantumStateIds.current(); i++) {
            if (quantumStates[i].exists) {
                totalWeight = totalWeight.add(_calculateLeapProbability(_assetId, currentQuantumStateId, i));
            }
        }
        // Avoid division by zero if somehow no states are reachable or probabilities sum to 0
        require(totalWeight > 0, "Leap: No reachable states or probabilities sum to zero");


        // Determine the next state based on probabilities
        for (uint256 i = 1; i <= _quantumStateIds.current(); i++) {
            if (quantumStates[i].exists) {
                uint256 probForTargetState = _calculateLeapProbability(_assetId, currentQuantumStateId, i);
                uint256 normalizedProb = probForTargetState.mul(10000).div(totalWeight); // Normalize to 10000

                accumulatedProbability = accumulatedProbability.add(normalizedProb);

                if (randomNumber < accumulatedProbability) {
                    newStateId = i;
                    break;
                }
            }
        }

        // Update asset's state and timestamp
        asset.quantumStateId = newStateId;
        assetQuantumState[_assetId] = newStateId;
        asset.lastLeapTimestamp = block.timestamp;

        // Refund any excess ETH paid
        if (msg.value > leapGasCost) {
            payable(msg.sender).transfer(msg.value.sub(leapGasCost));
        }

        emit QuantumLeapExecuted(_assetId, currentQuantumStateId, newStateId, randomNumber);
    }

    /**
     * @dev Allows the owner of an Entangled Asset to set its custom "attractor" values.
     *      Attractors influence the outcome probabilities of future Quantum Leaps.
     * @param _assetId The ID of the Entangled Asset.
     * @param _attractorName The name of the attractor (e.g., "energy", "affinity_to_stable").
     * @param _value The value for this attractor.
     */
    function setAssetAttractors(uint256 _assetId, string calldata _attractorName, uint256 _value)
        external
        whenNotPaused
        assetExists(_assetId)
    {
        require(msg.sender == ownerOf(_assetId), "Attractor: Not asset owner");
        entangledAssets[_assetId].attractors[_attractorName] = _value;
        emit AssetAttractorsUpdated(_assetId, _attractorName, _value);
    }

    // --- Standard ERC721 Functions (Inherited but listed for clarity) ---
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override;
    // function approve(address to, uint256 tokenId) public virtual override;
    // function setApprovalForAll(address operator, bool approved) public virtual override;

    // --- III. Superposition Staking (Dynamic Yield) ---

    /**
     * @dev Stakes an Entangled Asset, making it eligible for Graviton Pool yields
     *      and potentially influencing its future leap outcomes (though influence logic isn't explicit here).
     * @param _assetId The ID of the Entangled Asset to stake.
     */
    function enterSuperpositionStake(uint256 _assetId) external whenNotPaused assetExists(_assetId) {
        require(msg.sender == ownerOf(_assetId), "Stake: Not asset owner");
        require(!entangledAssets[_assetId].isInSuperposition, "Stake: Asset already staked");

        entangledAssets[_assetId].isInSuperposition = true;
        entangledAssets[_assetId].superpositionStakeTimestamp = block.timestamp;

        emit SuperpositionStakeEntered(_assetId, msg.sender);
    }

    /**
     * @dev Unstakes an Entangled Asset.
     * @param _assetId The ID of the Entangled Asset to unstake.
     */
    function exitSuperpositionStake(uint256 _assetId) external whenNotPaused assetExists(_assetId) {
        require(msg.sender == ownerOf(_assetId), "Unstake: Not asset owner");
        require(entangledAssets[_assetId].isInSuperposition, "Unstake: Asset not staked");

        // Before unstaking, update totalEligibleSuperpositionTime for current pool distribution cycle
        for (uint256 i = 1; i <= _gravitonPoolIds.current(); i++) {
            if (gravitonPools[i].assetAddress != address(0) && gravitonPools[i].distributionInterval > 0) {
                // Ensure to account for time spent in superposition since last distribution or stake
                gravitonPools[i].totalEligibleSuperpositionTime =
                    gravitonPools[i].totalEligibleSuperpositionTime.add(
                        block.timestamp.sub(entangledAssets[_assetId].superpositionStakeTimestamp)
                    );
            }
        }

        entangledAssets[_assetId].isInSuperposition = false;
        entangledAssets[_assetId].superpositionStakeTimestamp = 0; // Reset timestamp

        emit SuperpositionStakeExited(_assetId, msg.sender);
    }

    /**
     * @dev Allows stakers to claim accumulated yield from Graviton Pools.
     *      Yield calculation is simplified here for demonstration.
     *      In a real system, this would involve complex pro-rata distribution
     *      based on state, time staked, and pool distribution logic.
     * @param _assetId The ID of the Entangled Asset to claim yield for.
     */
    function claimSuperpositionYield(uint256 _assetId) external whenNotPaused assetExists(_assetId) {
        require(msg.sender == ownerOf(_assetId), "Claim: Not asset owner");
        require(entangledAssets[_assetId].isInSuperposition, "Claim: Asset not staked");

        uint256 unclaimedYield = 0;
        // Simplified yield calculation: based on time staked since last claim/stake
        // A more complex system would track per-pool accumulated yield
        uint256 timeStaked = block.timestamp.sub(entangledAssets[_assetId].superpositionStakeTimestamp);
        unclaimedYield = timeStaked.mul(superpositionYieldRatePerSec).div(10000); // Scale by basis points

        require(unclaimedYield > 0, "Claim: No yield accumulated");

        // This would involve transferring actual tokens/ETH from a pool or a separate treasury.
        // For demonstration, we just update the internal state.
        entangledAssets[_assetId].totalYieldClaimed = entangledAssets[_assetId].totalYieldClaimed.add(unclaimedYield);
        entangledAssets[_assetId].superpositionStakeTimestamp = block.timestamp; // Reset time for next calculation

        // Example: Transfer a "yield token" or base currency if a pool is setup for this
        // If this were connected to a specific Graviton Pool, the funds would come from there.
        // For now, we simulate.
        // payable(msg.sender).transfer(unclaimedYield); // If claiming native ETH
        // IERC20(yieldTokenAddress).transfer(msg.sender, unclaimedYield); // If claiming ERC20

        emit SuperpositionYieldClaimed(_assetId, msg.sender, unclaimedYield);
    }

    // --- IV. Graviton Pool Operations ---

    /**
     * @dev Allows users to deposit funds into a Graviton Pool.
     *      Supports native ETH (if _assetAddress is address(0)) or ERC20 tokens.
     * @param _poolId The ID of the Graviton Pool.
     * @param _amount The amount to deposit.
     * @param _erc20TokenAddress The address of the ERC20 token, or address(0) for ETH.
     */
    function depositIntoGravitonPool(uint256 _poolId, uint256 _amount, address _erc20TokenAddress)
        external
        payable
        whenNotPaused
    {
        GravitonPool storage pool = gravitonPools[_poolId];
        require(pool.assetAddress != address(0) || _erc20TokenAddress == address(0), "Pool: Invalid asset type");
        require(pool.assetAddress == _erc20TokenAddress, "Pool: Mismatched token address");

        if (pool.assetAddress == address(0)) {
            // Native ETH deposit
            require(msg.value == _amount, "Deposit: Mismatched ETH amount");
            // ETH is already sent to the contract
        } else {
            // ERC20 token deposit
            require(msg.value == 0, "Deposit: No ETH allowed for ERC20 deposit");
            IERC20(pool.assetAddress).transferFrom(msg.sender, address(this), _amount);
        }

        emit FundsDepositedIntoPool(_poolId, msg.sender, _amount);
    }

    /**
     * @dev Triggers the distribution of funds from a Graviton Pool to eligible Entangled Assets.
     *      Can be called by anyone, but subject to `distributionInterval`.
     *      This is a simplified example; a full distribution would be highly complex
     *      considering all assets, their states, and stake times.
     * @param _poolId The ID of the Graviton Pool to distribute from.
     */
    function distributeGravitons(uint256 _poolId) external whenNotPaused {
        GravitonPool storage pool = gravitonPools[_poolId];
        require(pool.assetAddress != address(0) || address(this).balance > 0, "Pool: No funds to distribute");
        require(block.timestamp >= pool.lastDistributionTimestamp.add(pool.distributionInterval), "Pool: Cooldown active");

        uint256 distributableAmount;
        if (pool.assetAddress == address(0)) {
            distributableAmount = address(this).balance; // All ETH in contract
        } else {
            distributableAmount = IERC20(pool.assetAddress).balanceOf(address(this));
        }
        require(distributableAmount > 0, "Pool: No funds available for distribution");

        // Calculate total eligible "share units" based on current states and superposition status
        // This is a placeholder. A real implementation needs to track accumulated eligible time
        // for each asset and each pool between distributions.
        // For simplicity, let's say all staked assets equally share the current distributable amount.
        uint256 totalStakedAssets = 0;
        for (uint256 i = 1; i <= _assetIds.current(); i++) {
            if (_exists(i) && entangledAssets[i].isInSuperposition) {
                totalStakedAssets++;
                // Accumulate eligible time for each asset in pool
                pool.totalEligibleSuperpositionTime = pool.totalEligibleSuperpositionTime.add(
                    block.timestamp.sub(entangledAssets[i].superpositionStakeTimestamp)
                );
            }
        }

        require(totalStakedAssets > 0, "Distribution: No eligible assets");

        // Distribute proportionally based on totalEligibleSuperpositionTime, then reset for next cycle
        // This implies that funds are 'earmarked' for assets based on their participation.
        pool.totalDistributedAmount = pool.totalDistributedAmount.add(distributableAmount);
        pool.lastDistributionTimestamp = block.timestamp;
        
        // This logic is highly simplified. A real system would track per-asset, per-pool shares.
        // The funds aren't transferred here, but marked as distributed. Users claim with `claimGravitonShare`.
        emit GravitonsDistributed(_poolId, distributableAmount);
    }

    /**
     * @dev Allows an Entangled Asset owner to claim their accumulated share from a Graviton Pool.
     *      This assumes `distributeGravitons` has already run and calculated each asset's share.
     *      The actual distribution logic for `claimGravitonShare` needs detailed tracking.
     * @param _poolId The ID of the Graviton Pool.
     * @param _assetId The ID of the Entangled Asset.
     */
    function claimGravitonShare(uint256 _poolId, uint256 _assetId)
        external
        whenNotPaused
        assetExists(_assetId)
    {
        require(msg.sender == ownerOf(_assetId), "Claim: Not asset owner");
        require(gravitonPools[_poolId].assetAddress != address(0) || address(this).balance > 0, "Pool: Not active");

        // This is where the calculated share for _assetId from _poolId would be retrieved.
        // For simplicity, let's assume `assetGravitonShareClaimed` tracks what's available
        // in a more complex system, this would be computed dynamically based on a snapshot
        // taken during `distributeGravitons` and how long the asset was staked.
        uint256 claimableAmount = 0; // Placeholder: this needs real logic
        // Example: If a distribution happened and this asset was eligible, its share would be calculated.
        // Let's make a mock calculation for now to show the flow.
        uint256 totalTimeInPool = block.timestamp.sub(entangledAssets[_assetId].superpositionStakeTimestamp);
        uint256 yieldPerTimeUnit = superpositionYieldRatePerSec; // Reuse for simplicity, would be pool specific

        claimableAmount = totalTimeInPool.mul(yieldPerTimeUnit).div(10000);
        
        // Reset stake timestamp for future calculations
        entangledAssets[_assetId].superpositionStakeTimestamp = block.timestamp;


        require(claimableAmount > 0, "Claim: No share available");

        assetGravitonShareClaimed[_assetId][_poolId] = assetGravitonShareClaimed[_assetId][_poolId].add(claimableAmount);

        if (gravitonPools[_poolId].assetAddress == address(0)) {
            payable(msg.sender).transfer(claimableAmount);
        } else {
            IERC20(gravitonPools[_poolId].assetAddress).transfer(msg.sender, claimableAmount);
        }

        emit GravitonShareClaimed(_poolId, _assetId, msg.sender, claimableAmount);
    }

    // --- V. Oracle Integration (Simulated/Advanced) ---

    /**
     * @dev (Simulated) Initiates a request for specific off-chain data from the Oracle Nexus.
     *      In a real system, this would trigger a Chainlink VRF request or similar.
     * @param _dataSourceKey A string key identifying the data source (e.g., "GLOBAL_VOLATILITY", "ENERGY_PRICES").
     */
    function requestOracleData(string calldata _dataSourceKey) external whenNotPaused {
        // In a real dApp, this would make an external call to Chainlink VRF or a custom oracle.
        // For this example, it's just an event.
        emit OracleDataRequested(_dataSourceKey);
    }

    /**
     * @dev (Callback from Oracle, simulated as owner-only for demonstration)
     *      Updates internal state based on received oracle data. This data then influences
     *      Quantum Leap probabilities or Graviton Pool distributions.
     * @param _dataSourceKey The key of the data source.
     * @param _value The value received from the oracle.
     */
    function fulfillOracleData(string calldata _dataSourceKey, uint256 _value) external onlyOracle {
        oracleNexus[_dataSourceKey] = OracleData(_value, block.timestamp);
        emit OracleDataFulfilled(_dataSourceKey, _value, block.timestamp);
    }

    /**
     * @dev Sets how much a specific oracle data source influences the probability
     *      of transitioning to a certain state.
     * @param _stateId The ID of the Quantum State whose probability is influenced.
     * @param _dataSourceKey The key of the oracle data source.
     * @param _influenceMultiplier A multiplier (e.g., 100 for 1x, 200 for 2x).
     */
    function setOracleInfluenceForState(uint256 _stateId, string calldata _dataSourceKey, uint256 _influenceMultiplier)
        external
        onlyOwner
        isQuantumState(_stateId)
    {
        stateOracleInfluence[_stateId][_dataSourceKey] = _influenceMultiplier;
    }

    // --- VI. Query & View Functions ---

    /**
     * @dev Returns all relevant details of an Entangled Asset.
     * @param _assetId The ID of the Entangled Asset.
     * @return owner Address of the asset owner.
     * @return stateId Current Quantum State ID.
     * @return lastLeapTs Timestamp of the last leap.
     * @return inSuperposition Whether the asset is staked.
     * @return stakeTs Timestamp when staking began.
     * @return totalYieldC Total yield claimed by this asset.
     */
    function getAssetDetails(uint256 _assetId)
        external
        view
        assetExists(_assetId)
        returns (address owner, uint256 stateId, uint256 lastLeapTs, bool inSuperposition, uint256 stakeTs, uint256 totalYieldC)
    {
        EntangledAsset storage asset = entangledAssets[_assetId];
        return (
            ownerOf(_assetId),
            asset.quantumStateId,
            asset.lastLeapTimestamp,
            asset.isInSuperposition,
            asset.superpositionStakeTimestamp,
            asset.totalYieldClaimed
        );
    }

    /**
     * @dev Returns the value of a specific attractor for an Entangled Asset.
     * @param _assetId The ID of the Entangled Asset.
     * @param _attractorName The name of the attractor.
     * @return The value of the attractor.
     */
    function getAssetAttractor(uint256 _assetId, string calldata _attractorName)
        external
        view
        assetExists(_assetId)
        returns (uint256)
    {
        return entangledAssets[_assetId].attractors[_attractorName];
    }

    /**
     * @dev Returns the properties of a specific Quantum State.
     * @param _stateId The ID of the Quantum State.
     * @return id The state ID.
     * @return name The state name.
     * @return description The state description.
     */
    function getQuantumStateDetails(uint256 _stateId)
        external
        view
        isQuantumState(_stateId)
        returns (uint256 id, string memory name, string memory description)
    {
        QuantumState storage state = quantumStates[_stateId];
        return (state.id, state.name, state.description);
    }

    /**
     * @dev Returns the details of a Graviton Pool.
     * @param _poolId The ID of the Graviton Pool.
     * @return name The pool name.
     * @return assetAddress The address of the asset held in the pool.
     * @return balance The current balance of the pool.
     * @return lastDistributionTs Timestamp of the last distribution.
     * @return distributionIntervals The interval between distributions.
     */
    function getGravitonPoolDetails(uint256 _poolId)
        external
        view
        returns (string memory name, address assetAddress, uint256 balance, uint256 lastDistributionTs, uint256 distributionIntervals)
    {
        GravitonPool storage pool = gravitonPools[_poolId];
        uint256 currentBalance = (pool.assetAddress == address(0)) ? address(this).balance : IERC20(pool.assetAddress).balanceOf(address(this));
        return (pool.name, pool.assetAddress, currentBalance, pool.lastDistributionTimestamp, pool.distributionInterval);
    }

    /**
     * @dev Returns the current value and last update timestamp for a given oracle data key.
     * @param _dataSourceKey The key for the oracle data.
     * @return value The data value.
     * @return timestamp The last update timestamp.
     * @return isValid Whether the data is still within its validity period.
     */
    function getOracleData(string calldata _dataSourceKey)
        external
        view
        returns (uint256 value, uint256 timestamp, bool isValid)
    {
        OracleData storage data = oracleNexus[_dataSourceKey];
        bool _isValid = data.lastUpdateTimestamp != 0 && (block.timestamp.sub(data.lastUpdateTimestamp) <= oracleDataValidityPeriod);
        return (data.value, data.lastUpdateTimestamp, _isValid);
    }

    /**
     * @dev Calculates the effective probability of an Entangled Asset transitioning to a specific target state.
     *      Takes into account base probabilities, asset's attractors, and oracle data.
     * @param _assetId The ID of the Entangled Asset.
     * @param _fromStateId The ID of the current Quantum State.
     * @param _toStateId The ID of the target Quantum State.
     * @return The calculated probability (out of 10000).
     */
    function calculateLeapOutcomeProbability(uint256 _assetId, uint256 _fromStateId, uint256 _toStateId)
        public
        view
        assetExists(_assetId)
        isQuantumState(_fromStateId)
        isQuantumState(_toStateId)
        returns (uint256)
    {
        return _calculateLeapProbability(_assetId, _fromStateId, _toStateId);
    }

    /**
     * @dev Internal function to calculate the effective probability of a leap.
     * @param _assetId The ID of the Entangled Asset.
     * @param _fromStateId The ID of the current Quantum State.
     * @param _toStateId The ID of the target Quantum State.
     * @return The calculated probability (scaled, not necessarily out of 10000 yet).
     */
    function _calculateLeapProbability(uint256 _assetId, uint256 _fromStateId, uint256 _toStateId)
        internal
        view
        returns (uint256)
    {
        uint256 baseProb = quantumStateBaseProbabilities[_fromStateId][_toStateId];
        EntangledAsset storage asset = entangledAssets[_assetId];

        uint256 modifiedProb = baseProb;

        // Influence from Asset Attractors (Example: "affinity" attractor)
        // This logic can be greatly expanded.
        uint256 assetAffinity = asset.attractors["affinity_to_state"]; // Example attractor
        if (assetAffinity > 0) {
            // Apply a simple linear influence based on attractor value
            modifiedProb = modifiedProb.add(assetAffinity.mul(attractorInfluenceMultiplier).div(100));
        }

        // Influence from Oracle Data
        // Example: If an oracle provides "GLOBAL_VOLATILITY", it might increase/decrease
        // probabilities for certain states.
        string memory oracleKey = "GLOBAL_VOLATILITY"; // Example oracle data key
        OracleData storage oracleData = oracleNexus[oracleKey];
        uint256 oracleInfluence = stateOracleInfluence[_toStateId][oracleKey];

        if (oracleData.lastUpdateTimestamp != 0 && (block.timestamp.sub(oracleData.lastUpdateTimestamp) <= oracleDataValidityPeriod)) {
            // Example: Higher volatility (oracleData.value) might increase probability to "Volatile" state
            // and decrease to "Stable" state. This logic needs to be carefully designed.
            if (oracleInfluence > 0) {
                 modifiedProb = modifiedProb.add(oracleData.value.mul(oracleInfluence).div(100));
            } else {
                 // If oracleInfluence is 0, or negative means it's a dampener
                 modifiedProb = modifiedProb.sub(oracleData.value.mul(100).div(100)); // Just arbitrary dampening
            }
        }

        return modifiedProb;
    }
}
```