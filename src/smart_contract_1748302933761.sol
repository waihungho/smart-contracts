Okay, here is a Solidity smart contract featuring a unique blend of concepts: a time-sensitive, state-accumulating system influenced by external conditions (via a simplified oracle model) and internal user actions, with programmable conditional triggers.

It's called "Synaptic Chronicle" and involves accumulating non-transferrable "Synapses" which decay but can be stimulated, and converting them into semi-fungible "Chronicle Points" based on complex rules, often triggered by oracle-verified conditions defined by users.

**Outline and Function Summary**

**Contract Name:** `SynapticChronicle`

**Purpose:**
This contract manages two core, interconnected state units: "Synapses" and "Chronicle Points". Synapses are non-transferrable points tied to an address, accumulating over time but also decaying if not stimulated. Their accumulation rate can be influenced by various factors. Chronicle Points are derived from Synapses through specific processes and represent a more concrete form of "influence" or "reward" within the system, potentially having unique transfer or utility restrictions (represented here internally). The system allows users to define "Conditional Protocols" that, when triggered by external oracle-verified conditions, execute predefined actions, often related to Synapse or Chronicle Point manipulation.

**Core Concepts:**
1.  **Synapses:** Time-dependent, address-bound, decaying, stimulable unit. Represents presence or activity.
2.  **Chronicle Points (CP):** Derived from Synapses, represents accumulated value/influence, semi-fungible internally.
3.  **Oracles:** External data providers (simplified representation here) that verify conditions.
4.  **Conditional Protocols (CPs):** User-defined `IF Condition THEN Action` rules triggered by oracle data.
5.  **Actions:** Predefined internal functions that CPs can execute (e.g., mint CP, boost synapse rate).
6.  **State Management:** Accumulation, decay, and manipulation of Synapses and CPs based on time, actions, and triggered protocols.

**Function Summary (25 Public/External Functions):**

1.  `constructor()`: Initializes the contract, setting the deployer as owner and initial parameters.
2.  `setOwner(address newOwner)`: Allows the current owner to transfer ownership.
3.  `pauseContract()`: Allows the owner to pause critical contract functions (using `Pausable`).
4.  `unpauseContract()`: Allows the owner to unpause the contract.
5.  `setBaseSynapseAccumulationRate(uint256 ratePerSecond)`: Owner sets the base rate at which Synapses accrue per second for active users.
6.  `setSynapseDecayRate(uint256 ratePerSecond)`: Owner sets the rate at which Synapses decay per second if not stimulated.
7.  `setCPRegistrationCost(uint256 cost)`: Owner sets the cost (in Ether) to register a new Conditional Protocol.
8.  `setCPActivationCost(uint256 cost)`: Owner sets the cost (in Ether) to activate a registered Conditional Protocol.
9.  `registerOracle(bytes32 oracleId, address oracleAddress)`: Owner registers an address as a trusted oracle for a given ID.
10. `unregisterOracle(bytes32 oracleId)`: Owner unregisters an oracle address.
11. `registerConditionalProtocol(bytes32 protocolId, ConditionType conditionType, bytes memory conditionParams, ActionType actionType, bytes memory actionParams)`: Allows a user to register a new Conditional Protocol definition by specifying its ID, condition type and parameters, and action type and parameters. Requires registration cost.
12. `activateConditionalProtocol(bytes32 protocolId)`: Allows the protocol owner to activate a registered protocol. Requires activation cost and the protocol must be registered.
13. `deactivateConditionalProtocol(bytes32 protocolId)`: Allows the protocol owner to deactivate an active protocol.
14. `checkAndTriggerProtocols(uint256 batchSize, uint256 startIndex)`: Public function (potentially called by keepers/oracles) to check a batch of active protocols for their conditions and trigger actions if met. Returns the next index to continue batching. *Gas intensive - requires off-chain batching/keeper implementation.*
15. `checkAndTriggerSpecificProtocol(bytes32 protocolId, bytes memory oracleProof)`: Allows an oracle or keeper (with valid proof) to check and trigger a specific protocol. The `oracleProof` is a placeholder for verification data.
16. `stimulateSynapses()`: Allows a user to interact and "stimulate" their Synapses, resetting their last update time to prevent decay and potentially giving a small boost (logic simplified in example).
17. `claimChroniclePoints(uint256 amountOfSynapsesToConvert)`: Allows a user to convert a specified amount of their current Synapses into Chronicle Points, burning the converted Synapses.
18. `getUserSynapseBalance(address user)`: View function returning the *currently calculated* Synapse balance for a user, including accrual/decay up to the current block timestamp.
19. `getUserRawSynapseDetails(address user)`: View function returning the raw stored Synapse balance and the last update timestamp. Useful for debugging accumulation logic.
20. `getCPDetails(bytes32 protocolId)`: View function returning details about a registered Conditional Protocol.
21. `getUserProtocols(address user)`: View function returning a list of protocol IDs registered by a user. (Returns hashes only for gas efficiency).
22. `getOracleAddress(bytes32 oracleId)`: View function returning the address registered for a specific oracle ID.
23. `isOracle(address account)`: View function checking if an address is registered as an oracle (placeholder check based on registration).
24. `getProtocolStatus(bytes32 protocolId)`: View function returning the active status of a protocol.
25. `withdrawFunds(uint256 amount)`: Owner function to withdraw Ether from the contract (e.g., collected registration/activation fees).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
// Contract Name: SynapticChronicle
// Purpose: Manages time-sensitive, decaying "Synapses" and derivable "Chronicle Points".
// Allows users to register and activate "Conditional Protocols" (IF condition THEN action)
// triggered by external oracle data to influence state (Synapse/CP balances).
//
// Core Concepts: Synapses (non-transferrable, time-dependent, decaying),
//                Chronicle Points (semi-fungible, derived),
//                Oracles (external data sources - simplified),
//                Conditional Protocols (programmable triggers),
//                Actions (internal state modifications).
//
// Function Summary (25 Public/External Functions):
// 1.  constructor()
// 2.  setOwner(address newOwner)
// 3.  pauseContract()
// 4.  unpauseContract()
// 5.  setBaseSynapseAccumulationRate(uint256 ratePerSecond)
// 6.  setSynapseDecayRate(uint256 ratePerSecond)
// 7.  setCPRegistrationCost(uint256 cost)
// 8.  setCPActivationCost(uint256 cost)
// 9.  registerOracle(bytes32 oracleId, address oracleAddress)
// 10. unregisterOracle(bytes32 oracleId)
// 11. registerConditionalProtocol(bytes32 protocolId, ConditionType conditionType, bytes memory conditionParams, ActionType actionType, bytes memory actionParams)
// 12. activateConditionalProtocol(bytes32 protocolId)
// 13. deactivateConditionalProtocol(bytes32 protocolId)
// 14. checkAndTriggerProtocols(uint256 batchSize, uint256 startIndex) - Gas Warning!
// 15. checkAndTriggerSpecificProtocol(bytes32 protocolId, bytes memory oracleProof) - Placeholder proof
// 16. stimulateSynapses()
// 17. claimChroniclePoints(uint256 amountOfSynapsesToConvert)
// 18. getUserSynapseBalance(address user) - Calculated
// 19. getUserRawSynapseDetails(address user) - Raw state
// 20. getCPDetails(bytes32 protocolId)
// 21. getUserProtocols(address user) - Returns hashes
// 22. getOracleAddress(bytes32 oracleId)
// 23. isOracle(address account) - Placeholder check
// 24. getProtocolStatus(bytes32 protocolId)
// 25. withdrawFunds(uint256 amount)
// --- End Outline and Function Summary ---


contract SynapticChronicle is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Core Balances
    mapping(address => uint256) private synapseBalances;
    mapping(address => uint48) private lastSynapseUpdateTime; // uint48 saves space, covers ~9 trillion seconds (~280k years)

    // Chronicle Points (Semi-fungible, managed internally)
    mapping(address => uint256) private chroniclePointBalances;

    // Configuration Parameters (Owner configurable)
    uint256 public baseSynapseAccumulationRatePerSecond; // Synapses per second for active users
    uint256 public synapseDecayRatePerSecond; // Synapses decay rate per second
    uint256 public cpRegistrationCost; // Cost to register a protocol (in wei)
    uint256 public cpActivationCost; // Cost to activate a protocol (in wei)
    uint256 public constant SYNAPSE_TO_CP_RATE = 1000; // Example: 1000 Synapses per 1 CP conversion

    // Oracle Management (Simplified)
    mapping(bytes32 => address) private registeredOracles;
    mapping(address => bool) private isRegisteredOracleAddress; // For quick lookup

    // Conditional Protocols
    enum ConditionType {
        None,
        OraclePriceAbove,   // bytes: oracleId, priceThreshold (uint256)
        OraclePriceBelow,   // bytes: oracleId, priceThreshold (uint256)
        UserSynapseAbove,   // bytes: synapseThreshold (uint256)
        UserSynapseBelow,   // bytes: synapseThreshold (uint256)
        ContractBalanceAbove // bytes: balanceThreshold (uint256)
        // Add more complex/creative conditions here (e.g., time-based, combined)
    }

    enum ActionType {
        None,
        MintChroniclePoints, // bytes: amount (uint256)
        BoostSynapseRate,    // bytes: percentage (uint256, e.g., 100 for 100%), duration (uint32)
        BurnChroniclePoints, // bytes: amount (uint256)
        TriggerEvent // bytes: eventId (bytes32) - For external listeners
        // Add more internal actions here
    }

    struct ConditionalProtocol {
        address owner;
        ConditionType conditionType;
        bytes conditionParams;
        ActionType actionType;
        bytes actionParams;
        uint48 lastTriggerTime; // To prevent rapid re-triggering (e.g., cooldown)
        bool isActive;
    }

    mapping(bytes32 => ConditionalProtocol) private conditionalProtocols;
    bytes32[] private registeredProtocolIds; // To iterate through protocols (careful with size!)
    mapping(address => bytes32[]) private userProtocols; // Protocols registered by a user

    uint256 public constant MIN_TRIGGER_COOLDOWN = 1 minutes; // Cooldown between protocol triggers

    // --- Events ---

    event SynapsesAccrued(address indexed user, uint256 amount, uint256 newBalance);
    event SynapsesDecayed(address indexed user, uint256 amount, uint256 newBalance);
    event ChroniclePointsMinted(address indexed user, uint256 amount, uint256 newBalance);
    event ChroniclePointsBurnt(address indexed user, uint256 amount, uint256 newBalance);
    event CPRegistered(bytes32 indexed protocolId, address indexed owner, ConditionType conditionType, ActionType actionType);
    event CPActivated(bytes32 indexed protocolId);
    event CPDeactivated(bytes32 indexed protocolId);
    event CPTriggered(bytes32 indexed protocolId, address indexed user);
    event ActionPerformed(address indexed user, ActionType actionType, bytes actionParams); // Generic action event
    event OracleRegistered(bytes32 indexed oracleId, address indexed oracleAddress);
    event OracleUnregistered(bytes32 indexed oracleId);
    event ParamUpdated(string paramName, uint256 newValue); // Generic parameter update event

    // --- Modifiers ---

    modifier onlyOracle(bytes32 oracleId) {
        require(msg.sender == registeredOracles[oracleId], "Not a registered oracle for this ID");
        _;
    }

    // Custom modifier for protocol ownership/existence
    modifier onlyProtocolOwner(bytes32 protocolId) {
        require(conditionalProtocols[protocolId].owner != address(0), "Protocol not registered");
        require(conditionalProtocols[protocolId].owner == msg.sender, "Not protocol owner");
        _;
    }

     modifier whenCPActivated(bytes32 protocolId) {
        require(conditionalProtocols[protocolId].isActive, "Protocol is not active");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        baseSynapseAccumulationRatePerSecond = 1e15; // Example: 0.001 Synapse per second (using 18 decimals implicitly)
        synapseDecayRatePerSecond = 1e14; // Example: 0.0001 Synapse per second decay
        cpRegistrationCost = 0.01 ether; // Example cost
        cpActivationCost = 0.05 ether; // Example cost
        emit ParamUpdated("baseSynapseAccumulationRatePerSecond", baseSynapseAccumulationRatePerSecond);
        emit ParamUpdated("synapseDecayRatePerSecond", synapseDecayRatePerSecond);
        emit ParamUpdated("cpRegistrationCost", cpRegistrationCost);
        emit ParamUpdated("cpActivationCost", cpActivationCost);
    }

    // --- Admin Functions (Owner) ---

    function setBaseSynapseAccumulationRate(uint256 ratePerSecond) external onlyOwner {
        baseSynapseAccumulationRatePerSecond = ratePerSecond;
        emit ParamUpdated("baseSynapseAccumulationRatePerSecond", ratePerSecond);
    }

    function setSynapseDecayRate(uint256 ratePerSecond) external onlyOwner {
        synapseDecayRatePerSecond = ratePerSecond;
        emit ParamUpdated("synapseDecayRatePerSecond", ratePerSecond);
    }

    function setCPRegistrationCost(uint256 cost) external onlyOwner {
        cpRegistrationCost = cost;
        emit ParamUpdated("cpRegistrationCost", cost);
    }

    function setCPActivationCost(uint256 cost) external onlyOwner {
        cpActivationCost = cost;
        emit ParamUpdated("cpActivationCost", cost);
    }

    function registerOracle(bytes32 oracleId, address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Zero address not allowed for oracle");
        require(registeredOracles[oracleId] == address(0), "Oracle ID already registered");
        registeredOracles[oracleId] = oracleAddress;
        isRegisteredOracleAddress[oracleAddress] = true; // Simplified check
        emit OracleRegistered(oracleId, oracleAddress);
    }

    function unregisterOracle(bytes32 oracleId) external onlyOwner {
        require(registeredOracles[oracleId] != address(0), "Oracle ID not registered");
        address oracleAddressToRemove = registeredOracles[oracleId];
        delete registeredOracles[oracleId];
        delete isRegisteredOracleAddress[oracleAddressToRemove]; // Simplified check
        emit OracleUnregistered(oracleId);
    }

    function withdrawFunds(uint256 amount) external onlyOwner whenNotPaused {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner()).transfer(amount);
    }

    // --- Internal Synapse & CP Management ---

    // Calculates and updates synapse balance based on time elapsed since last update
    function _updateSynapseBalance(address user) internal {
        uint48 currentTime = uint48(block.timestamp);
        uint48 lastUpdate = lastSynapseUpdateTime[user];

        // Handle first time update or significant time jump
        if (lastUpdate == 0 || currentTime <= lastUpdate) {
             // If currentTime == lastUpdate, no time passed for accrual/decay.
             // If lastUpdate == 0, this is the first update.
             // If currentTime < lastUpdate (unlikely due to blockchain), treat as no time passed.
             if (lastUpdate == 0) {
                 lastSynapseUpdateTime[user] = currentTime;
             }
             return; // No time passed for calculation
        }

        uint256 timeElapsed = currentTime - lastUpdate;
        uint256 currentBalance = synapseBalances[user];

        // Calculate accrual
        uint256 accrual = timeElapsed.mul(baseSynapseAccumulationRatePerSecond);

        // Apply decay (only if balance is positive)
        uint256 decay = 0;
        if (currentBalance > 0 && synapseDecayRatePerSecond > 0) {
             decay = timeElapsed.mul(synapseDecayRatePerSecond);
             if (decay > currentBalance) {
                 decay = currentBalance; // Don't decay below zero
             }
        }

        // Update balance
        uint256 newBalance = currentBalance.add(accrual).sub(decay);
        synapseBalances[user] = newBalance;
        lastSynapseUpdateTime[user] = currentTime;

        if (accrual > 0) emit SynapsesAccrued(user, accrual, newBalance);
        if (decay > 0) emit SynapsesDecayed(user, decay, newBalance);
    }

    // Performs the internal action based on type and parameters
    function _performAction(address user, ActionType aType, bytes memory aParams) internal whenNotPaused {
        emit ActionPerformed(user, aType, aParams); // Log the action attempt

        if (aType == ActionType.MintChroniclePoints) {
            require(aParams.length == 32, "Invalid MintCP params");
            uint256 amount = abi.decode(aParams, (uint256));
            chroniclePointBalances[user] = chroniclePointBalances[user].add(amount);
            emit ChroniclePointsMinted(user, amount, chroniclePointBalances[user]);
        } else if (aType == ActionType.BoostSynapseRate) {
            // Example: Apply temporary boost. Requires more complex state management (user boosts mapping, expiry)
            // For simplicity here, we'll just log it as a potential future action.
             // (bytes: percentage (uint256), duration (uint32))
             require(aParams.length == 32 + 32, "Invalid BoostSynapse params"); // percentage(uint256), duration(uint32) - decode requires fixed size, pad uint32
             (uint256 percentage, uint32 duration) = abi.decode(aParams, (uint256, uint32));
             // In a real contract: Store boost details (percentage, duration, expiry) for the user
             // Modify _updateSynapseBalance to apply boost if active.
             // This is a complex feature, simplified here to just emitting the event.
             emit ActionPerformed(user, aType, aParams); // Log the action attempt
             // Example: Placeholder for applying boost logic...
             // userBoosts[user] = UserBoost({ percentage: percentage, expiry: block.timestamp + duration });
        } else if (aType == ActionType.BurnChroniclePoints) {
             require(aParams.length == 32, "Invalid BurnCP params");
             uint256 amount = abi.decode(aParams, (uint256));
             require(chroniclePointBalances[user] >= amount, "Insufficient CP balance to burn");
             chroniclePointBalances[user] = chroniclePointBalances[user].sub(amount);
             emit ChroniclePointsBurnt(user, amount, chroniclePointBalances[user]);
        } else if (aType == ActionType.TriggerEvent) {
             require(aParams.length == 32, "Invalid TriggerEvent params");
             bytes32 eventId = abi.decode(aParams, (bytes32));
             emit ActionPerformed(user, aType, aParams); // Log the action attempt
             // External systems would listen for this generic ActionPerformed event and filter by ActionType and params
        }
        // Add more actions here
    }

    // Checks if the condition for a protocol is met (simplified oracle interaction)
    function _checkCondition(address user, ConditionType cType, bytes memory cParams) internal view returns (bool) {
        // Note: In a real oracle integration, this function would
        // verify cryptographic proofs or check state reported by trusted oracles
        // off-chain and passed as cParams/oracleProof.
        // This is a simplified example where cParams *contain* the 'oracle data' or state needed.

        if (cType == ConditionType.OraclePriceAbove) {
            require(cParams.length == 32 + 32, "Invalid OraclePriceAbove params"); // oracleId (bytes32), priceThreshold (uint256)
            (bytes32 oracleId, uint256 priceThreshold) = abi.decode(cParams, (bytes32, uint256));
            address oracleAddress = registeredOracles[oracleId];
            require(oracleAddress != address(0), "Condition uses unregistered oracle");
            // --- SIMULATION ---
            // In reality, you'd query the oracle contract here or verify data provided in cParams/oracleProof
            // Example: uint256 currentPrice = SomeOracleContract(oracleAddress).getPrice();
            // For this example, we'll assume `priceThreshold` *is* the 'oracle data' and we check against a hardcoded value or another state variable.
            // A more realistic approach would be to pass the *actual* oracle reading in the `checkAndTriggerSpecificProtocol` call
            // and verify it here against the threshold stored in the protocol.
            // Let's SIMULATE by checking if a hardcoded "latest price" (which a keeper would update) is above the threshold.
             uint256 simulatedLatestPrice = 1000e18; // Example simulated price (1000 with 18 decimals)
             return simulatedLatestPrice > priceThreshold;
            // --- END SIMULATION ---

        } else if (cType == ConditionType.OraclePriceBelow) {
            require(cParams.length == 32 + 32, "Invalid OraclePriceBelow params"); // oracleId (bytes32), priceThreshold (uint256)
            (bytes32 oracleId, uint256 priceThreshold) = abi.decode(cParams, (bytes32, uint256));
             address oracleAddress = registeredOracles[oracleId];
            require(oracleAddress != address(0), "Condition uses unregistered oracle");
             // --- SIMULATION ---
             uint256 simulatedLatestPrice = 1000e18; // Example simulated price
             return simulatedLatestPrice < priceThreshold;
             // --- END SIMULATION ---

        } else if (cType == ConditionType.UserSynapseAbove) {
             require(cParams.length == 32, "Invalid UserSynapseAbove params");
             uint256 synapseThreshold = abi.decode(cParams, (uint256));
             // Calculate current balance including pending accrual/decay
             uint256 currentUserSynapses = getUserSynapseBalance(user);
             return currentUserSynapses > synapseThreshold;

        } else if (cType == ConditionType.UserSynapseBelow) {
             require(cParams.length == 32, "Invalid UserSynapseBelow params");
             uint256 synapseThreshold = abi.decode(cParams, (uint256));
             uint256 currentUserSynapses = getUserSynapseBalance(user);
             return currentUserSynapses < synapseThreshold;

        } else if (cType == ConditionType.ContractBalanceAbove) {
             require(cParams.length == 32, "Invalid ContractBalanceAbove params");
             uint256 balanceThreshold = abi.decode(cParams, (uint256));
             return address(this).balance > balanceThreshold;
        }

        return false; // Default: No condition met or invalid type
    }


    // --- Conditional Protocol Functions ---

    function registerConditionalProtocol(
        bytes32 protocolId,
        ConditionType conditionType,
        bytes memory conditionParams,
        ActionType actionType,
        bytes memory actionParams
    ) external payable whenNotPaused {
        require(conditionalProtocols[protocolId].owner == address(0), "Protocol ID already exists");
        require(conditionType != ConditionType.None, "Invalid condition type");
        require(actionType != ActionType.None, "Invalid action type");
        require(msg.value >= cpRegistrationCost, "Insufficient registration cost");

        conditionalProtocols[protocolId] = ConditionalProtocol({
            owner: msg.sender,
            conditionType: conditionType,
            conditionParams: conditionParams,
            actionType: actionType,
            actionParams: actionParams,
            lastTriggerTime: 0,
            isActive: false
        });

        registeredProtocolIds.push(protocolId); // Add to the list for iteration
        userProtocols[msg.sender].push(protocolId); // Track protocols per user

        // Refund any excess Ether
        if (msg.value > cpRegistrationCost) {
            payable(msg.sender).transfer(msg.value - cpRegistrationCost);
        }

        emit CPRegistered(protocolId, msg.sender, conditionType, actionType);
    }

    function activateConditionalProtocol(bytes32 protocolId) external payable onlyProtocolOwner(protocolId) whenNotPaused {
        require(!conditionalProtocols[protocolId].isActive, "Protocol is already active");
        require(msg.value >= cpActivationCost, "Insufficient activation cost");

        conditionalProtocols[protocolId].isActive = true;
        // Refund any excess Ether
         if (msg.value > cpActivationCost) {
            payable(msg.sender).transfer(msg.value - cpActivationCost);
        }

        emit CPActivated(protocolId);
    }

    function deactivateConditionalProtocol(bytes32 protocolId) external onlyProtocolOwner(protocolId) whenNotPaused {
        require(conditionalProtocols[protocolId].isActive, "Protocol is not active");
        conditionalProtocols[protocolId].isActive = false;
        emit CPDeactivated(protocolId);
    }

    // Batch check and trigger for active protocols
    // WARNING: This function can consume a lot of gas depending on batchSize and the complexity of conditions/actions.
    // Should ideally be called by a decentralized keeper network or carefully batched off-chain.
    function checkAndTriggerProtocols(uint256 batchSize, uint256 startIndex) external whenNotPaused {
        require(startIndex < registeredProtocolIds.length, "startIndex out of bounds");
        uint256 endIndex = startIndex.add(batchSize);
        if (endIndex > registeredProtocolIds.length) {
            endIndex = registeredProtocolIds.length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            bytes32 protocolId = registeredProtocolIds[i];
            ConditionalProtocol storage cp = conditionalProtocols[protocolId];

            // Only process if active and sufficient time has passed since last trigger
            if (cp.isActive && block.timestamp >= cp.lastTriggerTime.add(MIN_TRIGGER_COOLDOWN)) {
                 // Check the condition (internal simplified check)
                 bool conditionMet = _checkCondition(cp.owner, cp.conditionType, cp.conditionParams);

                if (conditionMet) {
                    // Trigger the action
                    _performAction(cp.owner, cp.actionType, cp.actionParams);
                    cp.lastTriggerTime = uint48(block.timestamp); // Update last triggered time
                    emit CPTriggered(protocolId, cp.owner);
                }
            }
        }
        // A real implementation might return the *next* startIndex or a boolean indicating if more exist.
        // For this example, the caller needs to manage iteration.
    }

    // Check and trigger a single specific protocol
    // The `oracleProof` is a placeholder. In a real system, this might contain
    // signed oracle data, Chainlink VRF proof, etc., that is verified on-chain.
    // For this example, we simplify and just check the condition.
    function checkAndTriggerSpecificProtocol(bytes32 protocolId, bytes memory oracleProof) external whenNotPaused {
        ConditionalProtocol storage cp = conditionalProtocols[protocolId];
        require(cp.owner != address(0), "Protocol not registered");
        require(cp.isActive, "Protocol is not active");
        require(block.timestamp >= cp.lastTriggerTime.add(MIN_TRIGGER_COOLDOWN), "Protocol in cooldown");

        // --- Placeholder for Oracle Proof Verification ---
        // In a real contract, verify the `oracleProof` here against the registered oracle(s)
        // involved in `cp.conditionType`. This proof would attest to the oracle data
        // needed for `_checkCondition`. The `_checkCondition` function might then
        // *use* the verified data from the proof rather than simulating it.
        // Example: require(OracleProofVerifier(verifierAddress).verify(oracleProof, cp.conditionType, cp.conditionParams), "Invalid oracle proof");
        // --- End Placeholder ---

        // Check the condition (using the simplified internal check)
        bool conditionMet = _checkCondition(cp.owner, cp.conditionType, cp.conditionParams);

        if (conditionMet) {
            // Trigger the action
            _performAction(cp.owner, cp.actionType, cp.actionParams);
            cp.lastTriggerTime = uint48(block.timestamp); // Update last triggered time
            emit CPTriggered(protocolId, cp.owner);
        }
    }


    // --- User Interaction Functions ---

    // Allows a user to interact and 'stimulate' their synapses, preventing decay
    // and updating their balance. Could potentially include a small instant boost.
    function stimulateSynapses() external whenNotPaused {
        _updateSynapseBalance(msg.sender);
        // Optional: Add a small instant Synapse grant or temporary boost here
        // synapseBalances[msg.sender] = synapseBalances[msg.sender].add(1e16); // Example: Add 0.01 instantly
        // emit SynapsesAccrued(msg.sender, 1e16, synapseBalances[msg.sender]);
    }

    // Allows a user to convert Synapses to Chronicle Points
    function claimChroniclePoints(uint256 amountOfSynapsesToConvert) external whenNotPaused {
        require(amountOfSynapsesToConvert > 0, "Amount must be positive");

        // Ensure synapse balance is up-to-date before claiming
        _updateSynapseBalance(msg.sender);

        require(synapseBalances[msg.sender] >= amountOfSynapsesToConvert, "Insufficient synapses");

        uint256 pointsToMint = amountOfSynapsesToConvert.div(SYNAPSE_TO_CP_RATE);
        require(pointsToMint > 0, "Amount too small to yield any points");

        synapseBalances[msg.sender] = synapseBalances[msg.sender].sub(amountOfSynapsesToConvert);
        chroniclePointBalances[msg.sender] = chroniclePointBalances[msg.sender].add(pointsToMint);

        emit SynapsesDecayed(msg.sender, amountOfSynapsesToConvert, synapseBalances[msg.sender]); // Synapses are "burnt" or reduced via conversion
        emit ChroniclePointsMinted(msg.sender, pointsToMint, chroniclePointBalances[msg.sender]);
    }


    // --- View Functions ---

    // Get currently calculated synapse balance (includes pending accrual/decay)
    function getUserSynapseBalance(address user) public view returns (uint256) {
        uint48 currentTime = uint48(block.timestamp);
        uint48 lastUpdate = lastSynapseUpdateTime[user];
        uint256 currentBalance = synapseBalances[user];

         if (lastUpdate == 0 || currentTime <= lastUpdate) {
             return currentBalance; // No time passed or first update
         }

        uint256 timeElapsed = currentTime - lastUpdate;
        uint256 accrual = timeElapsed.mul(baseSynapseAccumulationRatePerSecond);

        uint256 decay = 0;
        if (currentBalance > 0 && synapseDecayRatePerSecond > 0) {
             decay = timeElapsed.mul(synapseDecayRatePerSecond);
             if (decay > currentBalance) {
                 decay = currentBalance;
             }
        }

        // Calculate pending balance without modifying state
        return currentBalance.add(accrual).sub(decay);
    }

    // Get raw stored synapse details (balance and last update timestamp)
    function getUserRawSynapseDetails(address user) external view returns (uint256 rawBalance, uint48 lastUpdateTime) {
        return (synapseBalances[user], lastSynapseUpdateTime[user]);
    }

    // Get Chronicle Point balance
    function getChroniclePointsBalance(address user) external view returns (uint256) {
        return chroniclePointBalances[user];
    }

    // Get details of a specific Conditional Protocol
    function getCPDetails(bytes32 protocolId) external view returns (
        address owner,
        ConditionType conditionType,
        bytes memory conditionParams,
        ActionType actionType,
        bytes memory actionParams,
        uint48 lastTriggerTime,
        bool isActive
    ) {
        ConditionalProtocol storage cp = conditionalProtocols[protocolId];
        require(cp.owner != address(0), "Protocol not registered"); // Ensure protocol exists
        return (
            cp.owner,
            cp.conditionType,
            cp.conditionParams,
            cp.actionType,
            cp.actionParams,
            cp.lastTriggerTime,
            cp.isActive
        );
    }

    // Get list of protocol IDs registered by a user
    // NOTE: Returning large arrays can be gas-intensive for view calls.
    // This returns only IDs. Fetching full details requires separate calls.
    function getUserProtocols(address user) external view returns (bytes32[] memory) {
        return userProtocols[user];
    }

    // Get the address registered for a specific oracle ID
    function getOracleAddress(bytes32 oracleId) external view returns (address) {
        return registeredOracles[oracleId];
    }

    // Check if an address is registered as an oracle (simplified)
    function isOracle(address account) external view returns (bool) {
        return isRegisteredOracleAddress[account]; // Simplified lookup
    }

    // Get the active status of a protocol
    function getProtocolStatus(bytes32 protocolId) external view returns (bool) {
        return conditionalProtocols[protocolId].isActive;
    }

    // Get the total number of registered protocols (for batching iteration)
    function getTotalRegisteredProtocols() external view returns (uint256) {
        return registeredProtocolIds.length;
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Time-Based, Decaying, Stimulable State (Synapses):** Most tokens are static balances. Synapses introduce a dynamic element where holding isn't enough; activity (implied by `_updateSynapseBalance` calls, often triggered by user actions like `stimulateSynapses` or potentially by keepers) is needed to maintain or grow the balance. The decay mechanism adds game theory – users are incentivized to interact. The non-transferrability links it to identity/reputation (like Soulbound Tokens), though less strict.
2.  **Semi-Fungible/Internally Managed Units (Chronicle Points):** CP is derived from the dynamic Synapses but is managed internally. This allows for potential future extensions where CP might have unique transfer rules (e.g., transferrable only to specific contract types, or with fees, or time locks) without adhering strictly to ERC-20, creating a customized internal economy.
3.  **Programmable Conditional Logic (Conditional Protocols):** Users can define on-chain "if this happens (external/internal condition), then do this (predefined action)". This moves beyond simple `approve`/`transfer` or fixed staking rules into a reactive, user-customizable system.
4.  **Oracle Integration (Simplified):** The system is designed to react to external real-world or blockchain data (like prices, other contract states) verified by oracles. While the oracle mechanism is simplified in this example, the structure (`ConditionType`, `conditionParams`, `checkAndTrigger...`) is built to integrate with actual oracle networks and data verification patterns.
5.  **Action Registry/Execution:** Instead of CPs directly calling arbitrary code (unsafe!), they trigger predefined `ActionType`s handled by the trusted `_performAction` internal function. This is a modular approach allowing the contract's capabilities to be extended safely.
6.  **Batching and Keeper Reliance:** The `checkAndTriggerProtocols` function acknowledges the reality of gas costs for iterating over potentially many items. It's designed to be called in batches, implying reliance on off-chain keepers or a decentralized network to monitor conditions and call the contract when necessary, which is a common advanced pattern for efficient on-chain execution of off-chain logic.
7.  **Gas Optimization Considerations:** Using `uint48` for timestamps, returning only hashes in `getUserProtocols`, and implementing batching are examples of considering gas efficiency, which is crucial for complex contracts.

This contract attempts to create a dynamic, reactive system where user state is influenced by time, activity, and external events, all orchestrated through user-defined, oracle-triggered logic, stepping away from standard token or simple contract paradigms.