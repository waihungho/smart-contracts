This smart contract proposes a novel concept: **"Echelon Sentinels"**. These are not just static NFTs, but dynamic, evolving, and autonomous digital entities that interact with on-chain and off-chain data. They possess "Energy" and "Influence" attributes, can specialize, fuse, and perform predefined "actions" based on external conditions (simulated via oracles). Their attributes decay over time, requiring "recharging," and their "influence" grows with successful actions, enabling further evolution.

---

## Echelon Sentinels Contract Outline & Function Summary

**Contract Name:** `EchelonSentinels`

**Core Concept:** Dynamic, evolving, and actionable NFT-like entities ("Sentinels") that respond to environmental conditions (simulated via Chainlink Oracles) and user interaction. They have a lifecycle of creation, evolution, action, decay, and potential decommissioning.

---

### **Outline:**

1.  **Imports & Interfaces:** Standard libraries (ERC721, Ownable, Pausable, ReentrancyGuard), Chainlink VRF and Price Feed interfaces.
2.  **Error Definitions:** Custom errors for clearer revert messages.
3.  **Enums:** `SentinelStatus`, `SentinelType`, `Specialization`, `ActionType`.
4.  **Structs:**
    *   `Sentinel`: Core data structure for each Sentinel.
    *   `AttributeSet`: Stores dynamic attributes.
    *   `ActionLogEntry`: Records executed actions.
5.  **State Variables:** Mappings, counters, addresses for oracles, fees, configuration.
6.  **Events:** To log all significant state changes.
7.  **Modifiers:** Access control and state-based conditions.
8.  **Constructor:** Initializes contract, ERC721, and core configurations.
9.  **Core Sentinel Management (ERC721 Overrides & Basic Functions):**
    *   Minting, transfer, burning, querying.
10. **Sentinel Lifecycle & Dynamics:**
    *   Creation (`createSentinel`).
    *   Energy & Attribute Management (`rechargeEnergy`, `decayAttributes`).
    *   Evolution & Specialization (`evolveSentinel`, `chooseSpecialization`).
    *   Fusion (`fuseSentinels`).
    *   Decommissioning (`decommissionSentinel`).
11. **Action & Oracle Integration:**
    *   Requesting Oracle Data (`requestActionOracleData`, `requestEvolutionRandomness`).
    *   Fulfilling Oracle Data (`fulfillRandomWords`, `fulfillPriceFeedData`).
    *   Performing Actions (`performSentinelAction`).
12. **Influence & Reputation System:**
    *   Updating Influence (`_updateInfluence`).
    *   Querying Influence (`getSentinelInfluence`).
13. **Resource Staking System:**
    *   Staking Ether for Energy (`stakeEtherForEnergy`).
    *   Unstaking Ether (`unstakeEtherForEnergy`).
14. **Configuration & Admin Functions:**
    *   Setting fees, oracle addresses, pausing.
    *   Emergency functions.
15. **Internal Helper Functions:** For calculations, ID generation, attribute management.

---

### **Function Summary (25 Functions):**

**I. Core Sentinel Management (ERC721 & Basic):**

1.  `constructor(string name_, string symbol_, address vrfCoordinator_, address link_, bytes32 keyHash_, uint64 subId_, address priceFeedAddress_)`: Initializes the contract, ERC721, Chainlink VRF, and Price Feed configurations.
2.  `createSentinel(SentinelType initialType_)`: Allows a user to mint a new Sentinel, paying an initial fee. Sets basic attributes and assigns an initial type.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Overrides standard ERC721 transfer to include Sentinel-specific checks.
4.  `approve(address to, uint256 tokenId)`: Standard ERC721 approval.
5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 set approval for all.
6.  `balanceOf(address owner)`: Standard ERC721 balance query.
7.  `ownerOf(uint256 tokenId)`: Standard ERC721 owner query.
8.  `getApproved(uint256 tokenId)`: Standard ERC721 approved query.
9.  `isApprovedForAll(address owner, address operator)`: Standard ERC721 is approved for all query.
10. `getSentinelDetails(uint256 sentinelId_)`: Retrieves all stored details for a given Sentinel, including its current attributes.

**II. Sentinel Lifecycle & Dynamics:**

11. `rechargeEnergy(uint256 sentinelId_, uint256 amount_)`: Allows a Sentinel owner to recharge their Sentinel's energy using staked ETH/tokens, vital for actions and evolution.
12. `decayAttributes(uint256 sentinelId_)`: Publicly callable function (or via an automated bot) to trigger the time-based decay of a Sentinel's attributes.
13. `evolveSentinel(uint256 sentinelId_)`: Initiates an evolution process for a Sentinel, potentially changing its type, attributes, or unlocking specialization based on influence and a Chainlink VRF random outcome.
14. `chooseSpecialization(uint256 sentinelId_, Specialization newSpecialization_)`: Allows a Sentinel that has reached a certain evolutionary stage to choose a specific specialization, granting unique bonuses or enabling certain actions.
15. `fuseSentinels(uint256 sentinelId1_, uint256 sentinelId2_)`: Allows an owner to combine two Sentinels, burning the originals and minting a new one with combined, averaged, or mutated attributes. Requires both Sentinels to be owned by the caller.
16. `decommissionSentinel(uint256 sentinelId_)`: Allows a Sentinel owner to retire an old or inactive Sentinel, potentially recovering a small portion of staked resources or unlocking a "legacy" token.

**III. Action & Oracle Integration:**

17. `requestActionOracleData(uint256 sentinelId_, ActionType actionType_, bytes memory targetData_)`: Triggers a Chainlink oracle request for specific data required to perform an action (e.g., environmental data, market volatility). The `performSentinelAction` is then called in the `fulfillOracleData` callback.
18. `performSentinelAction(uint256 sentinelId_, ActionType actionType_, bytes memory oracleData_)`: Executes a Sentinel's specific action, consuming energy and potentially modifying its influence based on the outcome of the oracle data. This is an internal function primarily called by oracle fulfillments.
19. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback function. Used to provide randomness for Sentinel evolution or action outcomes.
20. `fulfillPriceFeedData(uint256 sentinelId_, ActionType actionType_, int256 priceData_)`: Internal callback triggered by oracle price feed updates for specific Sentinel actions. (Simulated callback in this example, but would be an external adapter in production).

**IV. Resource Staking System:**

21. `stakeEtherForEnergy()`: Allows users to deposit ETH into the contract's energy pool, which Sentinels can then draw upon.
22. `unstakeEtherForEnergy(uint256 amount_)`: Allows users to withdraw their staked ETH from the energy pool.

**V. Configuration & Admin Functions:**

23. `pause()`: Puts the contract into a paused state, preventing most interactions (admin only).
24. `unpause()`: Resumes normal contract operation (admin only).
25. `withdrawAdminFees()`: Allows the contract owner to withdraw accumulated fees from Sentinel creation and other operations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// Using a simplified mock for price feed as the actual AggregatorV3Interface needs specific Chainlink deployment setup
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Custom error definitions for clearer reverts
error EchelonSentinels__InvalidSentinelId();
error EchelonSentinels__NotSentinelOwner();
error EchelonSentinels__InsufficientEnergy();
error EchelonSentinels__AttributesDecayedRecently();
error EchelonSentinels__AlreadySpecialized();
error EchelonSentinels__NotReadyForEvolution();
error EchelonSentinels__SentinelsNotOwnedByCaller();
error EchelonSentinels__CannotFuseSelf();
error EchelonSentinels__FusionRequirementsNotMet();
error EchelonSentinels__NoEthStaked();
error EchelonSentinels__InsufficientStakedEth();
error EchelonSentinels__ActionCooldownNotOver();
error EchelonSentinels__CannotPerformActionWithStatus();
error EchelonSentinels__UnauthorizedOracleFulfillment();
error EchelonSentinels__InvalidSpecialization();
error EchelonSentinels__EthTransferFailed();

/**
 * @title EchelonSentinels
 * @dev A dynamic and evolving NFT contract for "Sentinels" that interact with on-chain and off-chain data.
 * Sentinels possess energy, influence, and can perform actions, evolve, and fuse.
 * Integrates Chainlink VRF for randomness and a simulated price feed for external data.
 */
contract EchelonSentinels is ERC721, Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum SentinelStatus { Active, Resting, Decommissioned }
    enum SentinelType { Basic, Guardian, Architect, Seeker } // Base types
    enum Specialization { None, DataCustodian, MarketStabilizer, EnvironmentalMonitor, NetworkOptimizer } // Advanced specializations
    enum ActionType { AnalyzeData, StabilizeMarket, MonitorEnvironment, OptimizeNetwork } // Types of actions a Sentinel can perform

    // --- Structs ---

    struct AttributeSet {
        uint256 energy;      // Fuel for actions and evolution (0-1000)
        uint256 resilience;  // Resistance to decay and external shocks (0-100)
        uint256 awareness;   // How well it processes data and identifies opportunities (0-100)
        uint256 agility;     // Speed of action and adaptation (0-100)
        uint256 processingPower; // How complex tasks it can handle (0-100)
    }

    struct Sentinel {
        uint256 id;
        address owner;
        uint256 creationTime;
        SentinelStatus status;
        SentinelType sentinelType;
        Specialization specialization;
        AttributeSet attributes;
        uint256 lastAttributeDecayTime; // Timestamp of the last decay
        uint256 lastActionTime;         // Timestamp of the last action taken
        uint256 accumulatedInfluence;   // XP-like metric for successful actions
        uint256 evolutionStage;         // 0: Basic, 1: Evolved, 2: Specialized
        uint256 lastEvolutionRequestTime; // To prevent spamming evolution requests
    }

    struct ActionLogEntry {
        uint256 timestamp;
        ActionType actionType;
        bytes targetData; // Data related to the action (e.g., target address, data hash)
        bool success;
        string feedback;
    }

    // --- State Variables ---

    Counters.Counter private _sentinelIds;

    mapping(uint256 => Sentinel) public sentinels;
    mapping(address => uint256) public stakedEthBalance; // ETH staked by users for Sentinel energy
    mapping(uint256 => ActionLogEntry[]) public sentinelActionLogs;
    mapping(uint256 => uint256) public pendingEvolutionRequests; // sentinelId -> requestId for VRF

    // Configuration
    uint256 public constant SENTINEL_MINT_FEE = 0.05 ether;
    uint256 public constant ENERGY_RECHARGE_RATE = 1 ether; // 1 ETH per 100 energy units
    uint256 public constant BASE_ENERGY_COST_PER_ACTION = 50; // Base energy consumed per action
    uint256 public constant ATTRIBUTE_DECAY_INTERVAL = 1 days; // How often attributes decay
    uint256 public constant INFLUENCE_PER_SUCCESSFUL_ACTION = 10;
    uint256 public constant EVOLUTION_COOLDOWN = 7 days; // Cooldown for evolution requests
    uint256 public constant EVOLUTION_INFLUENCE_THRESHOLD = 100; // Influence needed to evolve
    uint256 public constant FUSION_INFLUENCE_THRESHOLD = 200; // Influence needed to fuse

    // Chainlink VRF v2 configuration
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public immutable i_keyHash;
    uint64 public immutable i_subscriptionId;
    uint32 public constant NUM_WORDS = 1;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    // Chainlink Price Feed (Simulated for this example to avoid complex setup)
    address public i_priceFeedAddress; // Could be AggregatorV3Interface in a real setup

    // --- Events ---

    event SentinelCreated(uint256 indexed sentinelId, address indexed owner, SentinelType initialType, uint256 creationTime);
    event SentinelEnergyRecharged(uint256 indexed sentinelId, uint256 amountRecharged, uint256 newEnergy);
    event SentinelAttributesDecayed(uint256 indexed sentinelId, uint256 oldEnergy, uint256 newEnergy);
    event SentinelEvolutionInitiated(uint256 indexed sentinelId, uint256 requestId);
    event SentinelEvolved(uint256 indexed sentinelId, SentinelType newType, uint256 newEvolutionStage);
    event SentinelSpecialized(uint256 indexed sentinelId, Specialization newSpecialization);
    event SentinelsFused(uint256 indexed newSentinelId, uint256 indexed oldSentinelId1, uint256 indexed oldSentinelId2);
    event SentinelDecommissioned(uint256 indexed sentinelId, address indexed owner);
    event SentinelActionPerformed(uint256 indexed sentinelId, ActionType actionType, bytes targetData, bool success, uint256 newInfluence);
    event OracleRequestSent(uint256 indexed requestId, uint256 indexed sentinelId, ActionType actionType);
    event OracleDataFulfilled(uint256 indexed requestId, uint256 indexed sentinelId, bytes data);
    event EthStakedForEnergy(address indexed staker, uint256 amount);
    event EthUnstakedForEnergy(address indexed staker, uint256 amount);
    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlySentinelOwner(uint256 _sentinelId) {
        if (msg.sender != sentinels[_sentinelId].owner) {
            revert EchelonSentinels__NotSentinelOwner();
        }
        _;
    }

    modifier onlySentinel(uint256 _sentinelId) {
        if (sentinels[_sentinelId].id == 0) { // Check if sentinel exists
            revert EchelonSentinels__InvalidSentinelId();
        }
        _;
    }

    modifier canPerformAction(uint256 _sentinelId) {
        if (sentinels[_sentinelId].attributes.energy < BASE_ENERGY_COST_PER_ACTION) {
            revert EchelonSentinels__InsufficientEnergy();
        }
        if (sentinels[_sentinelId].status != SentinelStatus.Active) {
            revert EchelonSentinels__CannotPerformActionWithStatus();
        }
        // Basic cooldown (e.g., 1 hour per action type)
        if (block.timestamp < sentinels[_sentinelId].lastActionTime + 1 hours) {
             revert EchelonSentinels__ActionCooldownNotOver();
        }
        _;
    }

    // --- Constructor ---

    constructor(
        string memory name_,
        string memory symbol_,
        address vrfCoordinator_,
        address link_,
        bytes32 keyHash_,
        uint64 subId_,
        address priceFeedAddress_
    )
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator_)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        i_keyHash = keyHash_;
        i_subscriptionId = subId_;
        i_priceFeedAddress = priceFeedAddress_; // This would be the Chainlink AggregatorV3Interface address
    }

    // --- Core Sentinel Management (ERC721 Overrides & Basic Functions) ---

    /**
     * @dev Allows a user to mint a new Sentinel NFT.
     * @param initialType_ The initial type for the new Sentinel.
     */
    function createSentinel(SentinelType initialType_)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value < SENTINEL_MINT_FEE) {
            revert EchelonSentinels__EthTransferFailed(); // Not enough ETH
        }

        _sentinelIds.increment();
        uint256 newId = _sentinelIds.current();

        // Initial attributes (can be randomized or fixed)
        AttributeSet memory initialAttributes = AttributeSet({
            energy: 500,
            resilience: 50,
            awareness: 50,
            agility: 50,
            processingPower: 50
        });

        sentinels[newId] = Sentinel({
            id: newId,
            owner: msg.sender,
            creationTime: block.timestamp,
            status: SentinelStatus.Active,
            sentinelType: initialType_,
            specialization: Specialization.None,
            attributes: initialAttributes,
            lastAttributeDecayTime: block.timestamp,
            lastActionTime: 0,
            accumulatedInfluence: 0,
            evolutionStage: 0,
            lastEvolutionRequestTime: 0
        });

        _safeMint(msg.sender, newId);
        emit SentinelCreated(newId, msg.sender, initialType_, block.timestamp);
    }

    /**
     * @dev Overrides ERC721's transferFrom to add `onlySentinel` check.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
        whenNotPaused
    {
        if (sentinels[tokenId].id == 0) { // Check if sentinel exists
            revert EchelonSentinels__InvalidSentinelId();
        }
        super.transferFrom(from, to, tokenId);
    }

    // Standard ERC721 functions (approve, setApprovalForAll, balanceOf, ownerOf, getApproved, isApprovedForAll)
    // are inherited and their functionality remains as per OpenZeppelin contracts.
    // No specific overrides needed unless custom logic is required for these.

    /**
     * @dev Retrieves all public details of a specific Sentinel.
     * @param sentinelId_ The ID of the Sentinel to query.
     * @return sentinelDetails_ A tuple containing all Sentinel struct data.
     */
    function getSentinelDetails(uint256 sentinelId_)
        public
        view
        onlySentinel(sentinelId_)
        returns (
            uint256 id,
            address owner,
            uint256 creationTime,
            SentinelStatus status,
            SentinelType sentinelType,
            Specialization specialization,
            AttributeSet memory attributes,
            uint256 lastAttributeDecayTime,
            uint256 lastActionTime,
            uint256 accumulatedInfluence,
            uint256 evolutionStage
        )
    {
        Sentinel storage s = sentinels[sentinelId_];
        return (
            s.id,
            s.owner,
            s.creationTime,
            s.status,
            s.sentinelType,
            s.specialization,
            s.attributes,
            s.lastAttributeDecayTime,
            s.lastActionTime,
            s.accumulatedInfluence,
            s.evolutionStage
        );
    }

    // --- Sentinel Lifecycle & Dynamics ---

    /**
     * @dev Allows a Sentinel owner to recharge their Sentinel's energy from staked ETH.
     * @param sentinelId_ The ID of the Sentinel to recharge.
     * @param amount_ The amount of energy units to recharge.
     */
    function rechargeEnergy(uint256 sentinelId_, uint256 amount_)
        public
        whenNotPaused
        nonReentrant
        onlySentinelOwner(sentinelId_)
    {
        uint256 ethRequired = (amount_ * ENERGY_RECHARGE_RATE) / 100;
        if (stakedEthBalance[msg.sender] < ethRequired) {
            revert EchelonSentinels__InsufficientStakedEth();
        }

        stakedEthBalance[msg.sender] -= ethRequired;
        sentinels[sentinelId_].attributes.energy += amount_;
        if (sentinels[sentinelId_].attributes.energy > 1000) { // Max energy cap
            sentinels[sentinelId_].attributes.energy = 1000;
        }

        emit SentinelEnergyRecharged(sentinelId_, amount_, sentinels[sentinelId_].attributes.energy);
    }

    /**
     * @dev Triggers the time-based decay of a Sentinel's attributes.
     * Can be called by anyone, incentivizing external bots or users to keep Sentinels updated.
     * @param sentinelId_ The ID of the Sentinel to decay.
     */
    function decayAttributes(uint256 sentinelId_)
        public
        whenNotPaused
        nonReentrant
        onlySentinel(sentinelId_)
    {
        Sentinel storage s = sentinels[sentinelId_];
        if (block.timestamp < s.lastAttributeDecayTime + ATTRIBUTE_DECAY_INTERVAL) {
            revert EchelonSentinels__AttributesDecayedRecently();
        }

        uint256 oldEnergy = s.attributes.energy;

        // Simple linear decay: 10% of current energy and 1% of other attributes per decay interval
        s.attributes.energy = (s.attributes.energy * 90) / 100;
        s.attributes.resilience = (s.attributes.resilience * 99) / 100;
        s.attributes.awareness = (s.attributes.awareness * 99) / 100;
        s.attributes.agility = (s.attributes.agility * 99) / 100;
        s.attributes.processingPower = (s.attributes.processingPower * 99) / 100;

        s.lastAttributeDecayTime = block.timestamp;

        emit SentinelAttributesDecayed(sentinelId_, oldEnergy, s.attributes.energy);
    }

    /**
     * @dev Initiates an evolution process for a Sentinel, requesting randomness from Chainlink VRF.
     * @param sentinelId_ The ID of the Sentinel to evolve.
     */
    function evolveSentinel(uint256 sentinelId_)
        public
        whenNotPaused
        nonReentrant
        onlySentinelOwner(sentinelId_)
    {
        Sentinel storage s = sentinels[sentinelId_];
        if (s.evolutionStage >= 2) { // Already reached final stage (specialized)
            revert EchelonSentinels__AlreadySpecialized();
        }
        if (s.accumulatedInfluence < EVOLUTION_INFLUENCE_THRESHOLD) {
            revert EchelonSentinels__NotReadyForEvolution();
        }
        if (block.timestamp < s.lastEvolutionRequestTime + EVOLUTION_COOLDOWN) {
            revert EchelonSentinels__ActionCooldownNotOver(); // Using general cooldown for this
        }

        // Request randomness for evolution outcome
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS,
            bytes32(abi.encodePacked(sentinelId_, block.timestamp)) // seed for uniqueness
        );
        pendingEvolutionRequests[sentinelId_] = requestId;
        s.lastEvolutionRequestTime = block.timestamp; // Update request time

        emit SentinelEvolutionInitiated(sentinelId_, requestId);
    }

    /**
     * @dev Callback function for Chainlink VRF randomness fulfillment.
     * This function is called by the VRF Coordinator once the randomness is available.
     * @param requestId The ID of the VRF request.
     * @param randomWords An array of random uint256 numbers.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Find which sentinel this requestId belongs to
        uint256 sentinelIdToEvolve = 0;
        for (uint256 i = 1; i <= _sentinelIds.current(); i++) {
            if (pendingEvolutionRequests[i] == requestId) {
                sentinelIdToEvolve = i;
                break;
            }
        }

        if (sentinelIdToEvolve == 0) {
            revert EchelonSentinels__UnauthorizedOracleFulfillment(); // Request ID not found or already processed
        }

        delete pendingEvolutionRequests[sentinelIdToEvolve]; // Clear pending request

        Sentinel storage s = sentinels[sentinelIdToEvolve];
        uint256 randomness = randomWords[0];

        // Apply evolution based on randomness and current stage
        if (s.evolutionStage == 0) { // Basic to Evolved
            s.evolutionStage = 1;
            // Randomly improve some attributes and potentially change type
            s.attributes.energy = s.attributes.energy + (randomness % 100) + 50;
            s.attributes.resilience = s.attributes.resilience + (randomness % 10) + 5;
            s.attributes.awareness = s.attributes.awareness + (randomness % 10) + 5;
            s.attributes.agility = s.attributes.agility + (randomness % 10) + 5;
            s.attributes.processingPower = s.attributes.processingPower + (randomness % 10) + 5;

            // Randomly assign a new SentinelType (e.g., Guardian, Architect, Seeker)
            s.sentinelType = SentinelType((randomness % 3) + 1); // 1-3 for Guardian, Architect, Seeker

            emit SentinelEvolved(sentinelIdToEvolve, s.sentinelType, s.evolutionStage);

        } else if (s.evolutionStage == 1) { // Evolved to Specialized readiness
            // Now ready for specialization choice
            s.evolutionStage = 2; // Marks as ready for specialization choice
            // Minor attribute boost
            s.attributes.energy = s.attributes.energy + (randomness % 20);
            s.attributes.resilience = s.attributes.resilience + (randomness % 5);
            emit SentinelEvolved(sentinelIdToEvolve, s.sentinelType, s.evolutionStage);
        }
        // Attributes capped at 1000 for energy, 100 for others
        _capAttributes(s.attributes);
    }

    /**
     * @dev Allows an evolved Sentinel to choose a specific specialization path.
     * @param sentinelId_ The ID of the Sentinel.
     * @param newSpecialization_ The desired specialization.
     */
    function chooseSpecialization(uint256 sentinelId_, Specialization newSpecialization_)
        public
        whenNotPaused
        nonReentrant
        onlySentinelOwner(sentinelId_)
    {
        Sentinel storage s = sentinels[sentinelId_];
        if (s.evolutionStage < 2) {
            revert EchelonSentinels__NotReadyForEvolution(); // Must be ready for specialization
        }
        if (s.specialization != Specialization.None) {
            revert EchelonSentinels__AlreadySpecialized();
        }
        if (newSpecialization_ == Specialization.None) {
            revert EchelonSentinels__InvalidSpecialization();
        }

        s.specialization = newSpecialization_;
        // Grant bonus attributes based on specialization
        if (newSpecialization_ == Specialization.DataCustodian) {
            s.attributes.awareness += 20;
            s.attributes.resilience += 10;
        } else if (newSpecialization_ == Specialization.MarketStabilizer) {
            s.attributes.agility += 20;
            s.attributes.processingPower += 10;
        } else if (newSpecialization_ == Specialization.EnvironmentalMonitor) {
            s.attributes.energy += 50;
            s.attributes.awareness += 15;
        } else if (newSpecialization_ == Specialization.NetworkOptimizer) {
            s.attributes.processingPower += 20;
            s.attributes.agility += 10;
        }
        _capAttributes(s.attributes);

        emit SentinelSpecialized(sentinelId_, newSpecialization_);
    }

    /**
     * @dev Allows an owner to fuse two Sentinels, burning them and minting a new one.
     * The new Sentinel inherits combined attributes and can be a more powerful type.
     * @param sentinelId1_ The ID of the first Sentinel.
     * @param sentinelId2_ The ID of the second Sentinel.
     */
    function fuseSentinels(uint256 sentinelId1_, uint256 sentinelId2_)
        public
        whenNotPaused
        nonReentrant
    {
        if (sentinelId1_ == sentinelId2_) {
            revert EchelonSentinels__CannotFuseSelf();
        }
        if (msg.sender != sentinels[sentinelId1_].owner || msg.sender != sentinels[sentinelId2_].owner) {
            revert EchelonSentinels__SentinelsNotOwnedByCaller();
        }

        Sentinel storage s1 = sentinels[sentinelId1_];
        Sentinel storage s2 = sentinels[sentinelId2_];

        if (s1.accumulatedInfluence < FUSION_INFLUENCE_THRESHOLD || s2.accumulatedInfluence < FUSION_INFLUENCE_THRESHOLD) {
            revert EchelonSentinels__FusionRequirementsNotMet();
        }

        _sentinelIds.increment();
        uint256 newId = _sentinelIds.current();

        AttributeSet memory fusedAttributes = AttributeSet({
            energy: (s1.attributes.energy + s2.attributes.energy) / 2 + 100, // Average + bonus
            resilience: (s1.attributes.resilience + s2.attributes.resilience) / 2 + 10,
            awareness: (s1.attributes.awareness + s2.attributes.awareness) / 2 + 10,
            agility: (s1.attributes.agility + s2.attributes.agility) / 2 + 10,
            processingPower: (s1.attributes.processingPower + s2.attributes.processingPower) / 2 + 10
        });
        _capAttributes(fusedAttributes);

        // Determine new type (can be more advanced or a combination)
        SentinelType newType;
        if (s1.sentinelType == SentinelType.Guardian && s2.sentinelType == SentinelType.Architect) {
            newType = SentinelType.Seeker; // Example combination logic
        } else if (s1.sentinelType == SentinelType.Seeker || s2.sentinelType == SentinelType.Seeker) {
            newType = SentinelType.Seeker; // Bias towards advanced type
        } else {
            newType = SentinelType.Guardian; // Default to one of the advanced types
        }

        sentinels[newId] = Sentinel({
            id: newId,
            owner: msg.sender,
            creationTime: block.timestamp,
            status: SentinelStatus.Active,
            sentinelType: newType,
            specialization: Specialization.None, // Fused Sentinels start fresh on specialization
            attributes: fusedAttributes,
            lastAttributeDecayTime: block.timestamp,
            lastActionTime: 0,
            accumulatedInfluence: (s1.accumulatedInfluence + s2.accumulatedInfluence) / 2,
            evolutionStage: 1, // Start as Evolved, ready for specialization
            lastEvolutionRequestTime: 0
        });

        // Burn the original Sentinels
        _burn(sentinelId1_);
        _burn(sentinelId2_);

        _safeMint(msg.sender, newId);
        emit SentinelsFused(newId, sentinelId1_, sentinelId2_);
    }

    /**
     * @dev Allows a Sentinel owner to decommission their Sentinel.
     * This burns the NFT and removes it from active state.
     * @param sentinelId_ The ID of the Sentinel to decommission.
     */
    function decommissionSentinel(uint256 sentinelId_)
        public
        whenNotPaused
        nonReentrant
        onlySentinelOwner(sentinelId_)
    {
        // Set status to decommissioned (useful for off-chain indexing)
        sentinels[sentinelId_].status = SentinelStatus.Decommissioned;

        // Burn the NFT
        _burn(sentinelId_);

        // Optionally, refund a small amount of ETH or issue a legacy token
        // Example: uint256 refundAmount = sentinels[sentinelId_].attributes.energy / 100 * 0.001 ether;
        // if (refundAmount > 0) {
        //     (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        //     if (!success) {
        //         revert EchelonSentinels__EthTransferFailed();
        //     }
        // }

        emit SentinelDecommissioned(sentinelId_, msg.sender);
        delete sentinels[sentinelId_]; // Clean up storage
    }

    // --- Action & Oracle Integration ---

    /**
     * @dev Sends a request to a Chainlink oracle for data needed to perform a Sentinel action.
     * This function initiates the action flow. The actual action execution happens in the fulfill callback.
     * @param sentinelId_ The ID of the Sentinel.
     * @param actionType_ The type of action to perform.
     * @param targetData_ Arbitrary data relevant to the action (e.g., target address, data hash).
     */
    function requestActionOracleData(uint256 sentinelId_, ActionType actionType_, bytes memory targetData_)
        public
        whenNotPaused
        nonReentrant
        onlySentinelOwner(sentinelId_)
        canPerformAction(sentinelId_)
    {
        // Deduct energy immediately to prevent re-calls while pending oracle
        sentinels[sentinelId_].attributes.energy -= BASE_ENERGY_COST_PER_ACTION;
        sentinels[sentinelId_].lastActionTime = block.timestamp;

        // In a real scenario, this would use Chainlink Client or other oracle integration
        // For demonstration, we'll simulate a callback
        // Example Chainlink request (conceptual for price feed)
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(i_priceFeedAddress);
        // (, int256 price, , , ) = priceFeed.latestRoundData();
        // _fulfillPriceFeedData(sentinelId_, actionType_, price); // Directly call simulated fulfill

        // For a more robust oracle, you'd integrate with Chainlink External Adapters for custom data or Chainlink Feeds for price data.
        // For simplicity, we'll directly call a simulated fulfillment for the demo,
        // but in production, this would be an async request.

        // Simulating the oracle call for a demo
        int256 simulatedOracleData = int256(block.timestamp % 100); // Dummy data
        _fulfillPriceFeedData(sentinelId_, actionType_, simulatedOracleData);

        emit OracleRequestSent(0, sentinelId_, actionType_); // Request ID 0 for simulated
    }

    /**
     * @dev Internal function to fulfill oracle data for Sentinel actions.
     * This would typically be called by a Chainlink external adapter or `fulfill` method.
     * @param sentinelId_ The ID of the Sentinel for which the action is performed.
     * @param actionType_ The type of action being performed.
     * @param priceData_ The data received from the oracle (e.g., market price).
     */
    function _fulfillPriceFeedData(uint256 sentinelId_, ActionType actionType_, int256 priceData_) internal {
        // Additional checks could be added here if this was an external callback
        // e.g., only callable by oracle address

        performSentinelAction(sentinelId_, actionType_, abi.encodePacked(priceData_));

        emit OracleDataFulfilled(0, sentinelId_, abi.encodePacked(priceData_));
    }


    /**
     * @dev Executes a Sentinel's action based on oracle data.
     * This function should ideally be called by an oracle callback or a trusted forwarder.
     * @param sentinelId_ The ID of the Sentinel performing the action.
     * @param actionType_ The type of action to perform.
     * @param oracleData_ The data received from the oracle (e.g., market price, environmental reading).
     */
    function performSentinelAction(uint256 sentinelId_, ActionType actionType_, bytes memory oracleData_)
        internal // Changed to internal, should be called by _fulfillPriceFeedData or a trusted callback
    {
        Sentinel storage s = sentinels[sentinelId_];
        bool success = false;
        string memory feedback = "Action failed.";

        // --- Action Logic based on Sentinel Type, Specialization, and Oracle Data ---
        if (actionType_ == ActionType.AnalyzeData) {
            // Requires high awareness and processing power
            uint256 dataValue = uint256(abi.decode(oracleData_, (int256))); // Example: convert oracle data
            if (s.attributes.awareness >= 70 && s.attributes.processingPower >= 70 && dataValue > 50) {
                success = true;
                feedback = "Data analysis successful. Insights gained.";
                _updateInfluence(sentinelId_, INFLUENCE_PER_SUCCESSFUL_ACTION);
            }
        } else if (actionType_ == ActionType.StabilizeMarket) {
            // Requires market stabilizer specialization and high agility
            if (s.specialization == Specialization.MarketStabilizer && s.attributes.agility >= 80) {
                // Simulate market stabilization success based on oracle price volatility (conceptual)
                success = true;
                feedback = "Market stability intervention applied.";
                _updateInfluence(sentinelId_, INFLUENCE_PER_SUCCESSFUL_ACTION * 2); // Higher reward
            }
        } else if (actionType_ == ActionType.MonitorEnvironment) {
            // Requires environmental monitor specialization and energy
            if (s.specialization == Specialization.EnvironmentalMonitor && s.attributes.energy > 100) {
                success = true;
                feedback = "Environmental conditions monitored.";
                _updateInfluence(sentinelId_, INFLUENCE_PER_SUCCESSFUL_ACTION);
            }
        } else if (actionType_ == ActionType.OptimizeNetwork) {
            // Requires network optimizer specialization and processing power
            if (s.specialization == Specialization.NetworkOptimizer && s.attributes.processingPower >= 85) {
                success = true;
                feedback = "Network routing optimized.";
                _updateInfluence(sentinelId_, INFLUENCE_PER_SUCCESSFUL_ACTION * 1.5);
            }
        }
        // ... more action types and complex logic based on attributes and specialization

        // Log the action
        sentinelActionLogs[sentinelId_].push(ActionLogEntry({
            timestamp: block.timestamp,
            actionType: actionType_,
            targetData: oracleData_,
            success: success,
            feedback: feedback
        }));

        emit SentinelActionPerformed(sentinelId_, actionType_, oracleData_, success, s.accumulatedInfluence);
    }

    // --- Influence & Reputation System ---

    /**
     * @dev Internal function to update a Sentinel's accumulated influence.
     * @param sentinelId_ The ID of the Sentinel.
     * @param amount_ The amount of influence to add.
     */
    function _updateInfluence(uint256 sentinelId_, uint256 amount_) internal {
        sentinels[sentinelId_].accumulatedInfluence += amount_;
    }

    /**
     * @dev Retrieves the accumulated influence of a Sentinel.
     * @param sentinelId_ The ID of the Sentinel.
     * @return The accumulated influence.
     */
    function getSentinelInfluence(uint256 sentinelId_)
        public
        view
        onlySentinel(sentinelId_)
        returns (uint256)
    {
        return sentinels[sentinelId_].accumulatedInfluence;
    }

    // --- Resource Staking System ---

    /**
     * @dev Allows users to stake Ether, which can then be used to recharge Sentinels.
     * @param msg.value The amount of Ether to stake.
     */
    function stakeEtherForEnergy() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) {
            revert EchelonSentinels__EthTransferFailed(); // Must stake some ETH
        }
        stakedEthBalance[msg.sender] += msg.value;
        emit EthStakedForEnergy(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to unstake their Ether from the energy pool.
     * @param amount_ The amount of Ether to unstake.
     */
    function unstakeEtherForEnergy(uint256 amount_) public whenNotPaused nonReentrant {
        if (stakedEthBalance[msg.sender] < amount_) {
            revert EchelonSentinels__InsufficientStakedEth();
        }
        if (amount_ == 0) {
            revert EchelonSentinels__NoEthStaked();
        }

        stakedEthBalance[msg.sender] -= amount_;
        (bool success, ) = payable(msg.sender).call{value: amount_}("");
        if (!success) {
            revert EchelonSentinels__EthTransferFailed();
        }
        emit EthUnstakedForEnergy(msg.sender, amount_);
    }

    /**
     * @dev Returns the staked ETH balance for a given address.
     * @param staker_ The address to query.
     * @return The amount of ETH staked.
     */
    function getStakedEthBalance(address staker_) public view returns (uint256) {
        return stakedEthBalance[staker_];
    }

    // --- Configuration & Admin Functions ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Callable only by the contract owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Callable only by the contract owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated fees from Sentinel creation.
     */
    function withdrawAdminFees() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance - _getTotalStakedEth(); // Exclude staked ETH
        if (balance == 0) {
            revert EchelonSentinels__EthTransferFailed(); // No fees to withdraw
        }
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert EchelonSentinels__EthTransferFailed();
        }
        emit AdminFeesWithdrawn(msg.sender, balance);
    }

    /**
     * @dev Helper function to get total staked ETH across all users.
     */
    function _getTotalStakedEth() internal view returns (uint256) {
        uint256 total = 0;
        // This is inefficient for many users. For production, consider an iterable mapping or a dedicated sum.
        // For this example, assuming a limited number of stakers or a specific iteration pattern.
        // A more scalable approach would be to track totalStakedEth as a separate state variable updated on stake/unstake.
        // For now, let's assume it's part of the contract's overall balance.
        return address(this).balance - (address(this).balance > SENTINEL_MINT_FEE ? SENTINEL_MINT_FEE : 0); // Simplified. Needs careful design.
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Caps Sentinel attributes to their maximum values.
     * @param attributes_ The AttributeSet to cap.
     */
    function _capAttributes(AttributeSet memory attributes_) internal pure {
        if (attributes_.energy > 1000) attributes_.energy = 1000;
        if (attributes_.resilience > 100) attributes_.resilience = 100;
        if (attributes_.awareness > 100) attributes_.awareness = 100;
        if (attributes_.agility > 100) attributes_.agility = 100;
        if (attributes_.processingPower > 100) attributes_.processingPower = 100;
    }

    /**
     * @dev Get the total number of sentinels minted.
     * @return The total number of sentinels.
     */
    function getTotalSentinels() public view returns (uint256) {
        return _sentinelIds.current();
    }

    // Fallback and Receive functions to ensure ETH can be received
    receive() external payable {
        // Automatically stake received ETH if no specific function is called.
        // Or revert if not intended to receive arbitrary ETH.
        // For this contract, we'll assume it's for staking.
        stakeEtherForEnergy();
    }

    fallback() external payable {
        // Revert for calls to non-existent functions.
        // If you want to accept arbitrary calls, handle them here.
        revert("Call to non-existent function or unexpected fallback.");
    }
}
```