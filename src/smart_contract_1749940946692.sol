Okay, let's design a smart contract that embodies several advanced, interconnected concepts without directly copying standard libraries like OpenZeppelin's ERC-721 or Ownable wholesale (we'll implement the core logic ourselves).

We'll create a system called "QuantumCatalyst" where unique digital assets (Catalysts) have dynamic states, parameters, and interactions influenced by time, external oracle data, verifiable randomness, and internal system conditions. It will include concepts like conditional state transitions, asset fusion, temporal decay/growth, oracle-driven dynamics, and a form of conditional governance.

**Contract Name:** `QuantumCatalyst`

**Concepts:**
1.  **Dynamic Assets:** Assets with changing states and parameters.
2.  **State Transitions:** Catalysts move between predefined states based on conditions.
3.  **Oracle Dependency:** State transitions or parameters can be influenced by external data via oracles.
4.  **Verifiable Randomness:** Introducing unpredictable elements to state changes or interactions.
5.  **Asset Fusion:** Combining multiple assets to create a new one.
6.  **Asset Linking/Entanglement:** Two assets can be linked, making their states partially interdependent.
7.  **Temporal Dynamics:** Parameters can decay or grow over time.
8.  **Conditional Governance:** Certain system parameters can only be changed if specific on-chain conditions are met.
9.  **Flash Interaction:** A complex atomic operation based on temporary state checks.

---

**Outline:**

1.  **License and Pragma**
2.  **Error Definitions**
3.  **Interfaces (Mocking External Dependencies)**
    *   `IOracle`: Interface for interacting with oracle feeds.
    *   `IVRFConsumer`: Interface for a Verifiable Randomness Function callback (mocked).
4.  **State Variables**
    *   Owner address
    *   Counter for unique Catalyst IDs
    *   Mappings for Catalyst data, ownership, approvals (manual ERC721-like)
    *   Enum for Catalyst states
    *   Struct for Catalyst data
    *   Mappings for registered oracles, VRF requests/results
    *   Global system parameters (subject to conditional governance)
    *   Mapping for linked Catalysts
5.  **Events**
6.  **Access Control (Simple Owner Implementation)**
7.  **Constructor**
8.  **Internal/Helper Functions**
    *   `_exists`, `_isApprovedOrOwner`, `_transfer`, `_mint`, `_burn` (Basic ERC721-like helpers)
    *   `_getStateBasedOnConditions`: Logic to determine potential next state.
    *   `_applyTimeDecay`: Logic for temporal parameter changes.
    *   `_checkConditionalRule`: Logic for evaluating conditional governance rules.
9.  **Core Asset Management (ERC721-like, Manual Implementation)**
    *   `balanceOf`
    *   `ownerOf`
    *   `transferFrom`
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
10. **Catalyst Lifecycle & Dynamics Functions**
    *   `mintCatalyst`
    *   `burnCatalyst`
    *   `triggerStateChange`
    *   `queryCatalystState`
    *   `applyTemporalDecay`
11. **Oracle Integration Functions**
    *   `registerOracle` (Conditional Governance)
    *   `updateCatalystOracleDependency`
    *   `getOracleDataForCatalyst` (View)
12. **Randomness Functions (Mocked VRF)**
    *   `requestRandomnessForCatalyst`
    *   `fulfillRandomness` (Callback)
13. **Catalyst Interaction Functions**
    *   `fuseCatalysts`
    *   `linkCatalysts`
    *   `breakLink`
14. **Conditional Governance & Parameter Functions**
    *   `setGlobalStateTransitionParameter` (Conditional)
    *   `setTemporalDecayRate` (Conditional)
    *   `setFusionCriteriaThreshold` (Conditional)
    *   `checkSystemCondition` (View)
15. **Advanced Interaction Function**
    *   `performConditionalAction` (Flash-like temporary condition check)
16. **Query Functions**
    *   `getCatalystDetails`
    *   `getAllCatalystsOwnedBy`
    *   `getTotalSupply`
    *   `getLinkedCatalyst`

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the deployer as the owner.
2.  `balanceOf(address owner)`: Returns the number of Catalysts owned by an address (ERC721-like).
3.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Catalyst (ERC721-like).
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a Catalyst (ERC721-like).
5.  `approve(address to, uint256 tokenId)`: Approves an address to manage a Catalyst (ERC721-like).
6.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all Catalysts (ERC721-like).
7.  `getApproved(uint256 tokenId)`: Returns the approved address for a Catalyst (ERC721-like).
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all Catalysts (ERC721-like).
9.  `mintCatalyst(address recipient, CatalystState initialState, uint256 param1, uint256 param2, uint256 oracleDepId)`: Mints a new Catalyst with initial properties. Callable only by owner/authorized? (Let's make it owner initially for simplicity).
10. `burnCatalyst(uint256 tokenId)`: Burns/destroys a Catalyst. Maybe add conditions later (e.g., only if state is Decayed).
11. `triggerStateChange(uint256 tokenId)`: Attempts to transition the state of a Catalyst based on current conditions (time, oracle, linked catalyst, randomness).
12. `queryCatalystState(uint256 tokenId)`: Returns the current state and relevant parameters of a Catalyst (View).
13. `applyTemporalDecay(uint256 tokenId)`: Applies time-based decay/growth logic to a Catalyst's parameters based on its state and elapsed time. Can be called by anyone (if profitable/necessary) or a keeper bot.
14. `registerOracle(uint256 oracleId, address oracleAddress, uint256 conditionType, uint256 conditionValue)`: Registers an oracle address for a data ID. This function itself is subject to a pre-defined *conditional governance* rule (e.g., only if contract balance > X).
15. `updateCatalystOracleDependency(uint256 tokenId, uint256 newOracleDepId)`: Updates the oracle dependency for a specific Catalyst. Subject to a conditional rule (e.g., owner must hold > Y Catalysts).
16. `getOracleDataForCatalyst(uint256 tokenId)`: Retrieves the latest data from the oracle linked to a Catalyst (View).
17. `requestRandomnessForCatalyst(uint256 tokenId)`: Initiates a randomness request (mocked VRF call) for a Catalyst. Once fulfilled, the randomness result can influence future state changes or interactions.
18. `fulfillRandomness(uint256 requestId, uint256 randomness)`: Mock callback function (intended to be called by VRF system). Stores the randomness result for a request.
19. `fuseCatalysts(uint256 tokenId1, uint256 tokenId2)`: Attempts to fuse two Catalysts. If criteria are met (based on states, parameters, randomness results), burns the two and mints a new one with derived properties.
20. `linkCatalysts(uint256 tokenId1, uint256 tokenId2)`: Creates a bidirectional link between two Catalysts, potentially making their state changes interdependent. Subject to a conditional rule (e.g., requires a specific oracle condition).
21. `breakLink(uint256 tokenId)`: Breaks the link associated with a Catalyst.
22. `setGlobalStateTransitionParameter(uint256 newValue, uint256 conditionType, uint256 conditionValue)`: Sets a global parameter affecting state transitions. *Only callable if a specified on-chain condition is met*.
23. `setTemporalDecayRate(uint256 newValue, uint256 conditionType, uint256 conditionValue)`: Sets the rate of parameter decay/growth. *Only callable if a specified on-chain condition is met*.
24. `setFusionCriteriaThreshold(uint256 newValue, uint256 conditionType, uint256 conditionValue)`: Sets a threshold for successful fusion. *Only callable if a specified on-chain condition is met*.
25. `checkSystemCondition(uint256 conditionType, uint256 conditionValue)`: Helper view function to check if a given system condition is met.
26. `performConditionalAction(uint256 tokenId, uint256 actionParam, uint256 conditionType, uint256 conditionValue)`: An advanced function that executes an internal action on a Catalyst *only if* a specified condition is met within the same transaction context (flash-like check). Example action: temporarily boosts parameter based on actionParam if oracle condition met.
27. `getCatalystDetails(uint256 tokenId)`: Returns all details of a specific Catalyst (View).
28. `getAllCatalystsOwnedBy(address owner)`: Returns an array of Catalyst IDs owned by an address (View).
29. `getTotalSupply()`: Returns the total number of Catalysts minted (View).
30. `getLinkedCatalyst(uint256 tokenId)`: Returns the ID of the Catalyst linked to this one (View).

This provides well over the 20 function minimum and incorporates several interlinked advanced concepts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Error Definitions ---
error NotOwner();
error NotApprovedOrOwner();
error InvalidTokenId();
error AlreadyExists();
error TransferCallerNotOwnerApproved();
error MintToZeroAddress();
error ApproveToOwner();
error BurnFromZeroAddress();
error CannotTriggerStateChangeYet();
error OracleNotRegistered();
error RandomnessPending();
error NotEnoughCatalystsForFusion();
error InvalidFusionCriteria();
error CatalystsAlreadyLinked();
error CatalystsNotLinked();
error SystemConditionNotMet();
error InvalidConditionalAction();


// --- Interfaces (Mocking External Dependencies) ---

// Mock Oracle Interface
// Represents a simplified external oracle providing different data feeds
interface IOracle {
    function getData(uint256 dataId) external view returns (uint256);
}

// Mock VRF Consumer Interface
// Represents a simplified Verifiable Randomness Function callback
interface IVRFConsumer {
    function fulfillRandomness(uint256 requestId, uint256 randomness) external;
}


// --- Contract: QuantumCatalyst ---

contract QuantumCatalyst {

    // --- State Variables ---

    address private _owner; // Simple owner implementation
    uint256 private _catalystCounter; // Counter for unique token IDs

    enum CatalystState {
        Dormant,     // Inactive, waiting for conditions
        Active,      // Currently active, parameters might change rapidly
        Volatile,    // Unpredictable state, high randomness influence
        Stable,      // Parameters are steady, less influenced by external factors
        Decayed,     // Parameters have degraded, limited interactions
        Staked       // Temporarily locked for specific protocols (not fully implemented dynamic state here, but as an example)
    }

    struct Catalyst {
        uint256 id;
        address owner;
        CatalystState state;
        uint256 creationTime; // Timestamp of creation
        uint256 lastStateChangeTime; // Timestamp of last state transition
        uint256 complexParameter1; // Example dynamic parameter
        uint256 complexParameter2; // Another example dynamic parameter
        uint256 oracleDependencyId; // Which oracle feed this Catalyst is tied to
        uint256 randomnessSeed; // Seed used for randomness requests
        uint256 linkedCatalystId; // ID of another Catalyst this one is linked to (0 if none)
        uint256 randomnessRequestId; // ID of the pending randomness request (0 if none)
    }

    mapping(uint256 => Catalyst) public catalysts; // Storage for Catalyst data
    mapping(uint256 => address) private _tokenApprovals; // ERC721-like token approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC721-like operator approvals
    mapping(address => uint256[] private) _ownerCatalysts; // Helper to track tokens by owner (Enumerable-like)

    mapping(uint256 => address) public registeredOracles; // Mapping from oracle ID to oracle address
    mapping(uint256 => uint256) public randomnessRequests; // Mapping from randomness request ID to Catalyst ID
    mapping(uint256 => uint256) public randomnessResults; // Mapping from randomness request ID to result

    // Global system parameters, subject to conditional governance
    uint256 public globalStateTransitionCooldown = 1 hours; // Min time between state changes
    uint256 public temporalDecayRate = 1; // Rate multiplier for parameter decay/growth
    uint256 public fusionCriteriaThreshold = 100; // Threshold for parameter sum for fusion

    // Conditional Governance Rules: Map RuleType to address/value required
    // This is a simplified example. A real system would need more sophisticated rule definition.
    // RuleType.MinCatalystsCreated: requires _catalystCounter >= ruleValue
    // RuleType.OracleThresholdMet: requires getData(ruleValue) >= someThreshold (needs oracleId + threshold)
    // RuleType.OwnerTokenBalance: requires owner.balanceOf(_owner) >= ruleValue (needs token address + min balance)
    // etc. - this is a placeholder complexity
    enum GovernanceConditionType { None, MinCatalystsCreated, OracleValueAboveThreshold, TotalSupplyAbove }
    mapping(uint256 => GovernanceConditionType) public parameterChangeConditionType;
    mapping(uint256 => uint256) public parameterChangeConditionValue;
    // We'll map parameter indices (e.g., 1 for globalStateTransitionCooldown) to conditions


    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event CatalystMinted(uint256 indexed tokenId, address indexed owner, CatalystState initialState);
    event CatalystBurned(uint256 indexed tokenId, address indexed owner);
    event CatalystStateChanged(uint256 indexed tokenId, CatalystState oldState, CatalystState newState, uint256 timestamp);
    event CatalystParametersUpdated(uint256 indexed tokenId, uint256 param1, uint256 param2);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress);
    event CatalystOracleDependencyUpdated(uint256 indexed tokenId, uint256 oldOracleId, uint256 newOracleId);
    event RandomnessRequested(uint256 indexed requestId, uint256 indexed tokenId);
    event RandomnessFulfilled(uint256 indexed requestId, uint256 randomness);
    event CatalystsFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newCatalystId);
    event CatalystsLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event LinkBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event GlobalParameterUpdated(string parameterName, uint256 newValue);
    event ConditionalActionExecuted(uint256 indexed tokenId, uint256 actionParam, uint256 conditionType);


    // --- Access Control (Simple Owner Implementation) ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        _catalystCounter = 0; // Token IDs start from 1

        // Set initial conditional governance rules (example)
        // Rule for globalStateTransitionCooldown (parameter index 1)
        parameterChangeConditionType[1] = GovernanceConditionType.MinCatalystsCreated;
        parameterChangeConditionValue[1] = 50; // Can only change if > 50 catalysts exist

        // Rule for temporalDecayRate (parameter index 2)
        parameterChangeConditionType[2] = GovernanceConditionType.OracleValueAboveThreshold;
        parameterChangeConditionValue[2] = 101; // Requires oracle data ID 101 value > 500
        // Note: Needs more complex structure to specify oracleId + threshold.
        // Simplified here: Assumes conditionValue encodes both or hardcoded logic.
        // For this example, let's assume value > 500 for oracle ID 101.

         // Rule for fusionCriteriaThreshold (parameter index 3)
        parameterChangeConditionType[3] = GovernanceConditionType.TotalSupplyAbove;
        parameterChangeConditionValue[3] = 200; // Can only change if > 200 total catalysts exist
    }


    // --- Internal/Helper Functions ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return catalysts[tokenId].id != 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = catalysts[tokenId].owner;
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (_ownerOf(tokenId) != from) revert TransferCallerNotOwnerApproved(); // Should technically check msg.sender, but this is helper
        if (to == address(0)) revert TransferCallerNotOwnerApproved(); // Equivalent to ERC721 transfer(address(0)) check

        _beforeTokenTransfer(from, to, tokenId); // Hook

        // Remove from old owner's list (simple swap logic)
        uint256[] storage ownerTokens = _ownerCatalysts[from];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == tokenId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }

        // Add to new owner's list
        _ownerCatalysts[to].push(tokenId);

        // Update catalyst ownership
        catalysts[tokenId].owner = to;

        // Clear approvals
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 initialState, uint256 param1, uint256 param2, uint256 oracleDepId) internal returns (uint256) {
        if (to == address(0)) revert MintToZeroAddress();

        _catalystCounter++;
        uint256 newItemId = _catalystCounter;

        catalysts[newItemId] = Catalyst({
            id: newItemId,
            owner: to,
            state: CatalystState(initialState),
            creationTime: block.timestamp,
            lastStateChangeTime: block.timestamp,
            complexParameter1: param1,
            complexParameter2: param2,
            oracleDependencyId: oracleDepId,
            randomnessSeed: 0, // Set later upon request
            linkedCatalystId: 0,
            randomnessRequestId: 0
        });

        _ownerCatalysts[to].push(newItemId); // Add to owner's list

        _afterTokenTransfer(address(0), to, newItemId); // Hook

        emit CatalystMinted(newItemId, to, CatalystState(initialState));
        emit Transfer(address(0), to, newItemId);

        return newItemId;
    }

    function _burn(uint256 tokenId) internal {
         address owner = _ownerOf(tokenId);
         if (owner == address(0)) revert InvalidTokenId(); // ERC721 standard check for existence

         _beforeTokenTransfer(owner, address(0), tokenId); // Hook

         // Clear approvals
         if (_tokenApprovals[tokenId] != address(0)) {
             delete _tokenApprovals[tokenId];
         }
         delete _operatorApprovals[owner][msg.sender]; // Clear operator approval if burning by operator

         // Remove from owner's list (simple swap logic)
         uint256[] storage ownerTokens = _ownerCatalysts[owner];
         for (uint256 i = 0; i < ownerTokens.length; i++) {
             if (ownerTokens[i] == tokenId) {
                 ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                 ownerTokens.pop();
                 break;
             }
         }

         // Unlink if linked
         if (catalysts[tokenId].linkedCatalystId != 0) {
             _breakLinkInternal(tokenId, catalysts[tokenId].linkedCatalystId);
         }


         // Delete the Catalyst data
         delete catalysts[tokenId];

         _afterTokenTransfer(owner, address(0), tokenId); // Hook

         emit CatalystBurned(tokenId, owner);
         emit Transfer(owner, address(0), tokenId);
    }

    // ERC721 Hooks (simplified)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal {}

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return catalysts[tokenId].owner; // Access struct directly
    }


    // Complex logic to determine the *potential* next state based on current conditions
    function _getStateBasedOnConditions(uint256 tokenId) internal view returns (CatalystState) {
        require(_exists(tokenId), "Catalyst does not exist");
        Catalyst storage c = catalysts[tokenId];

        // Base state is current state
        CatalystState potentialNextState = c.state;

        uint256 timeElapsedSinceLastChange = block.timestamp - c.lastStateChangeTime;

        // Condition 1: Time-based transition
        if (timeElapsedSinceLastChange >= globalStateTransitionCooldown) {
            // Simple example: After cooldown, Dormant -> Active, Active -> Stable, Stable -> Dormant, Volatile <-> Active, Decayed stays Decayed
            if (c.state == CatalystState.Dormant) potentialNextState = CatalystState.Active;
            else if (c.state == CatalystState.Active) potentialNextState = CatalystState.Stable;
            else if (c.state == CatalystState.Stable) potentialNextState = CatalystState.Dormant;
            // Volatile state might oscillate, Decayed is terminal
            else if (c.state == CatalystState.Volatile && (block.timestamp % 2 == 0)) potentialNextState = CatalystState.Active; // Simple time check
            else if (c.state == CatalystState.Active && (block.timestamp % 3 == 0)) potentialNextState = CatalystState.Volatile; // Simple time check
        }

        // Condition 2: Oracle influence (if linked and oracle registered)
        if (c.oracleDependencyId != 0 && registeredOracles[c.oracleDependencyId] != address(0)) {
            try IOracle(registeredOracles[c.oracleDependencyId]).getData(c.oracleDependencyId) returns (uint256 oracleValue) {
                // Example: If oracle value is high (>1000) and in Active state, maybe go Volatile
                if (oracleValue > 1000 && potentialNextState == CatalystState.Active) {
                    potentialNextState = CatalystState.Volatile;
                }
                 // Example: If oracle value is low (<100) and in Volatile state, maybe go Dormant
                if (oracleValue < 100 && potentialNextState == CatalystState.Volatile) {
                    potentialNextState = CatalystState.Dormant;
                }
                 // Example: Oracle influences decay rate temporarily (handled in applyTemporalDecay)
            } catch {
                // If oracle call fails, state transition might be blocked or default logic applies
                // For simplicity, we'll just ignore oracle influence if call fails.
            }
        }

        // Condition 3: Randomness influence (if a request has been fulfilled)
        if (c.randomnessRequestId != 0 && randomnessResults[c.randomnessRequestId] != 0) {
             uint256 randomValue = randomnessResults[c.randomnessRequestId];
             // Example: Randomness influences state transition probability
             if (randomValue % 10 < 2 && potentialNextState != CatalystState.Volatile && c.state != CatalystState.Decayed) {
                 potentialNextState = CatalystState.Volatile; // Small chance of going Volatile
             } else if (randomValue % 10 > 7 && potentialNextState != CatalystState.Stable && c.state != CatalystState.Decayed) {
                 potentialNextState = CatalystState.Stable; // Small chance of going Stable
             }
             // Clear the used randomness result? Or let it linger? Let it linger for now.
             // delete randomnessResults[c.randomnessRequestId]; // Could clear it
             // c.randomnessRequestId = 0; // Reset request ID
        }

        // Condition 4: Linked Catalyst influence
        if (c.linkedCatalystId != 0 && _exists(c.linkedCatalystId)) {
            Catalyst storage linkedC = catalysts[c.linkedCatalystId];
            // Example: If linked catalyst is Volatile, this one is more likely to go Active/Volatile
            if (linkedC.state == CatalystState.Volatile && potentialNextState == CatalystState.Dormant) {
                potentialNextState = CatalystState.Active;
            }
            // Example: If linked catalyst is Stable, this one is more likely to go Stable/Dormant
             if (linkedC.state == CatalystState.Stable && potentialNextState == CatalystState.Active) {
                potentialNextState = CatalystState.Stable;
            }
        }

        // Add more complex conditions as needed...

        return potentialNextState;
    }

    // Applies temporal decay/growth to parameters based on state and time
    function _applyTimeDecay(uint256 tokenId) internal {
        require(_exists(tokenId), "Catalyst does not exist");
        Catalyst storage c = catalysts[tokenId];

        uint256 timeElapsed = block.timestamp - c.lastStateChangeTime; // Time in current state
        if (timeElapsed == 0) return; // No time passed

        uint256 decayFactor = temporalDecayRate; // Base decay rate

        // Example: State influences decay/growth
        if (c.state == CatalystState.Active) {
             decayFactor = decayFactor * 2; // Faster change
        } else if (c.state == CatalystState.Volatile) {
            decayFactor = decayFactor * 3; // Even faster change
        } else if (c.state == CatalystState.Stable) {
            decayFactor = decayFactor / 2; // Slower change
        } else if (c.state == CatalystState.Decayed) {
             // Parameters might decay to zero over time
             if (c.complexParameter1 > 0) c.complexParameter1 = c.complexParameter1 > decayFactor * timeElapsed ? c.complexParameter1 - decayFactor * timeElapsed : 0;
             if (c.complexParameter2 > 0) c.complexParameter2 = c.complexParameter2 > decayFactor * timeElapsed ? c.complexParameter2 - decayFactor * timeElapsed : 0;
              emit CatalystParametersUpdated(tokenId, c.complexParameter1, c.complexParameter2);
              return; // Decay logic differs
        }


        // Apply decay/growth (example: parameter1 grows, parameter2 decays)
        // Ensure no overflow/underflow based on specific parameter meaning
        c.complexParameter1 = c.complexParameter1 + (decayFactor * timeElapsed);
        if (c.complexParameter2 > 0) { // Prevent underflow if parameter can't be negative
             c.complexParameter2 = c.complexParameter2 > (decayFactor * timeElapsed) ? c.complexParameter2 - (decayFactor * timeElapsed) : 0;
        }


        emit CatalystParametersUpdated(tokenId, c.complexParameter1, c.complexParameter2);
    }

    // Helper to check if a system condition for governance is met
    function _checkSystemCondition(GovernanceConditionType conditionType, uint256 conditionValue) internal view returns (bool) {
        if (conditionType == GovernanceConditionType.None) {
            return true; // No condition required
        } else if (conditionType == GovernanceConditionType.MinCatalystsCreated) {
            return _catalystCounter >= conditionValue;
        } else if (conditionType == GovernanceConditionType.OracleValueAboveThreshold) {
            // This needs more info - which oracle? What threshold?
            // Simplified example: requires data from oracle 101 to be > conditionValue
            address oracleAddress = registeredOracles[101]; // Hardcoded example oracle ID
            if (oracleAddress == address(0)) return false; // Oracle not registered
            try IOracle(oracleAddress).getData(101) returns (uint256 oracleValue) {
                return oracleValue > conditionValue;
            } catch {
                return false; // Oracle call failed
            }
        } else if (conditionType == GovernanceConditionType.TotalSupplyAbove) {
             return _catalystCounter > conditionValue;
        }
        // Add more condition types here...
        return false; // Unknown condition type
    }

    // --- Core Asset Management (ERC721-like, Manual Implementation) ---

    // Note: These functions replicate core ERC721 behaviors without importing OZ library.
    // They are not a complete ERC721 implementation (e.g., no metadata, enumeration helpers beyond basic list).

    function balanceOf(address owner) public view returns (uint256) {
        return _ownerCatalysts[owner].length;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = catalysts[tokenId].owner;
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert TransferCallerNotOwnerApproved(); // msg.sender must be owner or approved
        if (_ownerOf(tokenId) != from) revert TransferCallerNotOwnerApproved(); // Check `from` is actual owner
        if (to == address(0)) revert TransferCallerNotOwnerApproved(); // Cannot transfer to zero address

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = _ownerOf(tokenId); // Checks if token exists implicitly
        if (msg.sender != owner) {
            if (!_operatorApprovals[owner][msg.sender]) {
                revert NotApprovedOrOwner(); // Only owner or approved operator can set approval
            }
        }
        if (to == owner) revert ApproveToOwner();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert NotApprovedOrOwner(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "Catalyst does not exist"); // Check token exists
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    // --- Catalyst Lifecycle & Dynamics Functions ---

    // Mint a new Catalyst (Owner only initially)
    function mintCatalyst(address recipient, uint256 initialState, uint256 param1, uint256 param2, uint256 oracleDepId) public onlyOwner returns (uint256) {
        return _mint(recipient, initialState, param1, param2, oracleDepId);
    }

    // Burn a Catalyst (Callable by owner/approved)
    // Added condition: Can only burn if in Decayed state as an example
    function burnCatalyst(uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();
        if (catalysts[tokenId].state != CatalystState.Decayed) {
            // Allow burning if not decayed, but add a cost? Or just require decayed?
            // Let's require Decayed state for this example of conditional burn.
             revert("Can only burn Decayed catalysts");
        }
        _burn(tokenId);
    }

    // Trigger a state change attempt for a Catalyst
    // Can be called by anyone, the contract logic determines if a change occurs
    function triggerStateChange(uint256 tokenId) public {
        require(_exists(tokenId), "Catalyst does not exist");
        Catalyst storage c = catalysts[tokenId];

        // Optional: Add a cooldown before attempting state change again
        // if (block.timestamp - c.lastStateChangeTime < globalStateTransitionCooldown && c.state != CatalystState.Dormant) {
        //      revert CannotTriggerStateChangeYet();
        // }

        // Apply temporal effects before checking conditions for state change
        _applyTimeDecay(tokenId);

        // Determine the potential next state
        CatalystState potentialNextState = _getStateBasedOnConditions(tokenId);

        // If potential state is different, apply it
        if (potentialNextState != c.state) {
            CatalystState oldState = c.state;
            c.state = potentialNextState;
            c.lastStateChangeTime = block.timestamp;
            emit CatalystStateChanged(tokenId, oldState, c.state, block.timestamp);

            // Optional: Trigger new randomness request upon state change
            requestRandomnessForCatalyst(tokenId);
        } else {
            // No state change this time
            // Emit an event indicating attempt but no change? Or do nothing.
        }
    }

     // View function to query the current state of a Catalyst
    function queryCatalystState(uint256 tokenId) public view returns (CatalystState) {
        require(_exists(tokenId), "Catalyst does not exist");
        return catalysts[tokenId].state;
    }

    // Explicitly apply temporal decay/growth to a Catalyst's parameters
    // Can be called by anyone, useful for keeping parameters updated
    function applyTemporalDecay(uint256 tokenId) public {
        require(_exists(tokenId), "Catalyst does not exist");
        _applyTimeDecay(tokenId);
        // Update last state change time to prevent immediate re-application
        // But this might interfere with state transitions. Let's *not* update lastStateChangeTime here,
        // only when the state itself changes via triggerStateChange.
        // catalysts[tokenId].lastStateChangeTime = block.timestamp; // Decided against this
    }


    // --- Oracle Integration Functions ---

    // Register an oracle address for a data ID (Conditional Governance)
    // Parameter index 0 for oracle registration rule example
    function registerOracle(uint256 oracleId, address oracleAddress, uint256 conditionValue) public onlyOwner {
        // Example: Requires MinCatalystsCreated condition to register new oracles
        if (!_checkSystemCondition(GovernanceConditionType.MinCatalystsCreated, conditionValue)) {
             revert SystemConditionNotMet();
        }
        if (oracleAddress == address(0)) revert OracleNotRegistered(); // Use error for zero address

        registeredOracles[oracleId] = oracleAddress;
        emit OracleRegistered(oracleId, oracleAddress);
    }

    // Update the oracle dependency for a specific Catalyst
    // Parameter index 0 for oracle update dependency rule example
    function updateCatalystOracleDependency(uint256 tokenId, uint256 newOracleDepId, uint256 conditionValue) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
         // Example: Requires OracleValueAboveThreshold condition to update oracle dependency
        if (!_checkSystemCondition(GovernanceConditionType.OracleValueAboveThreshold, conditionValue)) {
             revert SystemConditionNotMet();
        }
        if (newOracleDepId != 0 && registeredOracles[newOracleDepId] == address(0)) revert OracleNotRegistered();


        uint256 oldOracleId = catalysts[tokenId].oracleDependencyId;
        catalysts[tokenId].oracleDependencyId = newOracleDepId;
        emit CatalystOracleDependencyUpdated(tokenId, oldOracleId, newOracleDepId);
    }

    // View function to get data from the Catalyst's linked oracle
    function getOracleDataForCatalyst(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Catalyst does not exist");
        uint256 oracleId = catalysts[tokenId].oracleDependencyId;
        if (oracleId == 0 || registeredOracles[oracleId] == address(0)) return 0; // No oracle linked or registered

        try IOracle(registeredOracles[oracleId]).getData(oracleId) returns (uint256 oracleValue) {
             return oracleValue;
        } catch {
            // Handle oracle query failure - return 0 or specific error?
            // Returning 0 is safer for view function.
            return 0;
        }
    }


    // --- Randomness Functions (Mocked VRF) ---

    // Request randomness for a Catalyst
    // A real VRF integration would consume gas and require a separate VRFCoordinator contract
    function requestRandomnessForCatalyst(uint256 tokenId) public {
        require(_exists(tokenId), "Catalyst does not exist");
        // Can add conditions here (e.g., only in Volatile state, cooldown)
        // If catalysts[tokenId].state != CatalystState.Volatile revert(...);

        // Mocking: Generate a request ID and associate it with the token
        uint256 requestId = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender, block.difficulty)));
        catalysts[tokenId].randomnessRequestId = requestId;
        randomnessRequests[requestId] = tokenId;

        // In a real system, this would call VRFCoordinator.requestRandomness(...)
        // which would asynchronously call back fulfillRandomness.

        emit RandomnessRequested(requestId, tokenId);
    }

    // Mock callback function for VRF result
    // In a real system, this would have checks to ensure it's called by the trusted VRF coordinator
    function fulfillRandomness(uint256 requestId, uint256 randomness) public {
         // In a real system:
         // require(msg.sender == VRF_COORDINATOR_ADDRESS, "Only VRF Coordinator");
         // require(randomnessRequests[requestId] != 0, "Request ID not found");

         // Mocking:
         uint256 tokenId = randomnessRequests[requestId];
         if (tokenId == 0) {
             // This request wasn't made by this contract, or already fulfilled
             return;
         }

         randomnessResults[requestId] = randomness;
         // We don't reset randomnessRequestId on the Catalyst immediately,
         // so _getStateBasedOnConditions can check for a fulfilled result.

         emit RandomnessFulfilled(requestId, randomness);
    }


    // --- Catalyst Interaction Functions ---

    // Attempt to fuse two Catalysts into a new one
    function fuseCatalysts(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Catalyst 1 does not exist");
        require(_exists(tokenId2), "Catalyst 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot fuse a catalyst with itself");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Caller not authorized for Catalyst 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Caller not authorized for Catalyst 2");
        require(_ownerOf(tokenId1) == _ownerOf(tokenId2), "Catalysts must have same owner to fuse"); // Or allow cross-owner with approval? Same owner simpler.

        Catalyst storage c1 = catalysts[tokenId1];
        Catalyst storage c2 = catalysts[tokenId2];

        // Fusion Criteria (Example):
        // 1. Must be in Active or Volatile states
        // 2. Sum of complexParameter1 must exceed fusionCriteriaThreshold
        // 3. Optional: Check randomness result if pending on either catalyst

        if ((c1.state != CatalystState.Active && c1.state != CatalystState.Volatile) ||
            (c2.state != CatalystState.Active && c2.state != CatalystState.Volatile)) {
             revert InvalidFusionCriteria();
        }

        if (c1.complexParameter1 + c2.complexParameter1 < fusionCriteriaThreshold) {
             revert InvalidFusionCriteria();
        }

        // Check randomness if pending - Example: Fusion requires random value above 50
        uint256 randomInfluence1 = c1.randomnessRequestId != 0 ? randomnessResults[c1.randomnessRequestId] : 0;
        uint256 randomInfluence2 = c2.randomnessRequestId != 0 ? randomnessResults[c2.randomnessRequestId] : 0;

        // If randomness was requested for *either* and fulfilled, it influences fusion outcome
        // This logic can be highly variable. Example: require average randomness > 50 if applicable
        if ((c1.randomnessRequestId != 0 && randomInfluence1 == 0) || (c2.randomnessRequestId != 0 && randomInfluence2 == 0)) {
            // One has pending randomness, maybe wait? Or assume failure if not fulfilled?
            // Let's require randomness to be fulfilled IF requested
            revert RandomnessPending();
        }

        uint256 totalRandomInfluence = randomInfluence1 + randomInfluence2;
        if ((c1.randomnessRequestId != 0 || c2.randomnessRequestId != 0) && totalRandomInfluence / ((c1.randomnessRequestId != 0 ? 1 : 0) + (c2.randomnessRequestId != 0 ? 1 : 0)) <= 50) {
             revert InvalidFusionCriteria(); // Example random check
        }


        // --- Fusion Successful ---

        // Burn the original two catalysts
        address owner = _ownerOf(tokenId1); // Same owner check passed
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new Catalyst with combined/derived properties
        uint256 newParam1 = (c1.complexParameter1 + c2.complexParameter1) / 2; // Average or sum? Average.
        uint256 newParam2 = (c1.complexParameter2 + c2.complexParameter2) * 2; // Different combination logic
        uint256 newOracleDep = c1.oracleDependencyId != 0 ? c1.oracleDependencyId : c2.oracleDependencyId; // Inherit oracle dependency?
        CatalystState newState = CatalystState.Stable; // Fused catalyst starts Stable

        uint256 newCatalystId = _mint(owner, uint256(newState), newParam1, newParam2, newOracleDep);

        emit CatalystsFused(tokenId1, tokenId2, newCatalystId);
    }

    // Link two Catalysts together ("entangle")
    function linkCatalysts(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Catalyst 1 does not exist");
        require(_exists(tokenId2), "Catalyst 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot link a catalyst to itself");
        require(_ownerOf(tokenId1) == msg.sender || isApprovedForAll(_ownerOf(tokenId1), msg.sender), "Caller not authorized for Catalyst 1");
        require(_ownerOf(tokenId2) == msg.sender || isApprovedForAll(_ownerOf(tokenId2), msg.sender), "Caller not authorized for Catalyst 2");
         require(_ownerOf(tokenId1) == _ownerOf(tokenId2), "Catalysts must have same owner to link"); // Or allow cross-owner with approval? Same owner simpler.

        if (catalysts[tokenId1].linkedCatalystId != 0 || catalysts[tokenId2].linkedCatalystId != 0) {
            revert CatalystsAlreadyLinked();
        }

        // Add a conditional rule for linking (Example: requires OracleValueAboveThreshold condition)
        // Parameter index 0 for linking rule example - needs separate mapping if different rule per function
         if (!_checkSystemCondition(GovernanceConditionType.OracleValueAboveThreshold, 600)) { // Example: requires oracle 101 value > 600
             revert SystemConditionNotMet();
        }


        catalysts[tokenId1].linkedCatalystId = tokenId2;
        catalysts[tokenId2].linkedCatalystId = tokenId1; // Bidirectional link

        emit CatalystsLinked(tokenId1, tokenId2);
    }

    // Break the link between two Catalysts
    function breakLink(uint256 tokenId) public {
        require(_exists(tokenId), "Catalyst does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller not authorized");

        uint256 linkedId = catalysts[tokenId].linkedCatalystId;
        if (linkedId == 0 || !_exists(linkedId) || catalysts[linkedId].linkedCatalystId != tokenId) {
            revert CatalystsNotLinked(); // Not linked or link is broken/invalid
        }

        _breakLinkInternal(tokenId, linkedId);
    }

    // Internal helper to break link
    function _breakLinkInternal(uint256 tokenId1, uint256 tokenId2) internal {
         catalysts[tokenId1].linkedCatalystId = 0;
         catalysts[tokenId2].linkedCatalystId = 0;
         emit LinkBroken(tokenId1, tokenId2);
    }


    // --- Conditional Governance & Parameter Functions ---

    // Set globalStateTransitionCooldown, conditional on a rule
    // Parameter index 1 corresponds to this setting
    function setGlobalStateTransitionParameter(uint256 newValue) public onlyOwner {
         GovernanceConditionType condType = parameterChangeConditionType[1];
         uint256 condValue = parameterChangeConditionValue[1];
         if (!_checkSystemCondition(condType, condValue)) {
             revert SystemConditionNotMet();
         }
        globalStateTransitionCooldown = newValue;
        emit GlobalParameterUpdated("globalStateTransitionCooldown", newValue);
    }

     // Set temporalDecayRate, conditional on a rule
     // Parameter index 2 corresponds to this setting
    function setTemporalDecayRate(uint256 newValue) public onlyOwner {
         GovernanceConditionType condType = parameterChangeConditionType[2];
         uint256 condValue = parameterChangeConditionValue[2];
         if (!_checkSystemCondition(condType, condValue)) {
             revert SystemConditionNotMet();
         }
        temporalDecayRate = newValue;
        emit GlobalParameterUpdated("temporalDecayRate", newValue);
    }

     // Set fusionCriteriaThreshold, conditional on a rule
     // Parameter index 3 corresponds to this setting
    function setFusionCriteriaThreshold(uint256 newValue) public onlyOwner {
         GovernanceConditionType condType = parameterChangeConditionType[3];
         uint256 condValue = parameterChangeConditionValue[3];
         if (!_checkSystemCondition(condType, condValue)) {
             revert SystemConditionNotMet();
         }
        fusionCriteriaThreshold = newValue;
        emit GlobalParameterUpdated("fusionCriteriaThreshold", newValue);
    }

    // View function to check if a generic system condition is met
    function checkSystemCondition(uint256 conditionType, uint256 conditionValue) public view returns (bool) {
        return _checkSystemCondition(GovernanceConditionType(conditionType), conditionValue);
    }


    // --- Advanced Interaction Function ---

    // Executes an action on a Catalyst *only if* a specified condition is met within the same transaction.
    // Similar concept to a flash loan, but checking on-chain state/oracle data instead of solvency.
    // ActionType example: 1=BoostParam1Temporarily
    function performConditionalAction(uint256 tokenId, uint256 actionType, uint256 actionParam, uint256 conditionType, uint256 conditionValue) public {
        require(_exists(tokenId), "Catalyst does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller not authorized");

        // Check the specified condition *before* executing the action
        if (!_checkSystemCondition(GovernanceConditionType(conditionType), conditionValue)) {
            revert SystemConditionNotMet();
        }

        Catalyst storage c = catalysts[tokenId];
        uint256 oldParam1 = c.complexParameter1;
        uint256 oldParam2 = c.complexParameter2;

        // Execute the action based on actionType
        if (actionType == 1) { // Example: BoostParam1Temporarily
            // Apply a temporary boost to parameter 1 using actionParam
            // This is simplified; a real "temporary" effect needs more state/logic (e.g., expiresAfter)
            c.complexParameter1 = c.complexParameter1 + actionParam;
             emit ConditionalActionExecuted(tokenId, actionParam, conditionType);
             emit CatalystParametersUpdated(tokenId, c.complexParameter1, c.complexParameter2);

            // In a real system, you might add checks *after* the action here and revert if invariants are broken.
            // Example: require(c.complexParameter1 < someMaxLimit, "Boosted param too high");

        } else {
            revert InvalidConditionalAction();
        }

        // Note: For true atomicity, you'd perform a sequence of complex steps here
        // and then verify conditions at the very end, reverting the entire tx if checks fail.
        // This single-action example demonstrates the conditional execution *concept*.
    }


    // --- Query Functions ---

    function getCatalystDetails(uint256 tokenId) public view returns (
        uint256 id,
        address owner,
        CatalystState state,
        uint256 creationTime,
        uint256 lastStateChangeTime,
        uint256 complexParameter1,
        uint256 complexParameter2,
        uint256 oracleDependencyId,
        uint256 randomnessSeed,
        uint256 linkedCatalystId,
        uint256 randomnessRequestId
    ) {
        require(_exists(tokenId), "Catalyst does not exist");
        Catalyst storage c = catalysts[tokenId];
        return (
            c.id,
            c.owner,
            c.state,
            c.creationTime,
            c.lastStateChangeTime,
            c.complexParameter1,
            c.complexParameter2,
            c.oracleDependencyId,
            c.randomnessSeed,
            c.linkedCatalystId,
            c.randomnessRequestId
        );
    }

     function getAllCatalystsOwnedBy(address owner) public view returns (uint256[] memory) {
        return _ownerCatalysts[owner];
    }

    function getTotalSupply() public view returns (uint256) {
        return _catalystCounter; // Current total number of catalysts minted
    }

    function getLinkedCatalyst(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Catalyst does not exist");
        return catalysts[tokenId].linkedCatalystId;
    }

    // --- Owner-only helpers (optional, but good for maintenance) ---
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        _owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}
```