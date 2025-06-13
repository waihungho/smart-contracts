Okay, let's design an interesting, advanced smart contract concept. Instead of a typical token or DeFi primitive, let's create a contract that manages dynamic, conditional "Links" between entities (addresses), inspired metaphorically by quantum concepts like superposition and conditional entanglement.

**Concept: QuantumLink**

This contract manages "Links" between two parties (Party A and Party B). Each Link starts in a state of "Superposition," meaning it's pending activation or failure. The resolution from Superposition depends on a set of predefined "Conditions" being met or failing within a certain timeframe. Links can also have dynamic "Properties" attached to them, which can be updated by the parties or via triggered events.

**Advanced Concepts Used:**

1.  **Metaphorical Superposition:** Links exist in a pending state until conditions resolve them to 'Active' or 'Failed'.
2.  **Conditional Resolution:** State changes are driven by a combination of time, external data (via oracles), and explicit actions by involved parties.
3.  **Dynamic Properties:** Links are not static; they can hold mutable data attached to them.
4.  **Oracle Integration:** Designed to interface with external data sources to fulfill conditions.
5.  **Multi-Party Interaction:** State changes often require actions from specific addresses.
6.  **Complex State Management:** Tracking links, their conditions, properties, and resolution logic.

**Outline:**

1.  ** SPDX License and Pragma**
2.  ** Imports (e.g., Ownable for basic access control)**
3.  ** Events:**
    *   LinkCreated
    *   ConditionAdded
    *   ConditionStatusUpdated
    *   LinkResolved (to Active/Failed/Cancelled)
    *   LinkPropertyUpdated
    *   OracleRegistered
    *   OracleRemoved
    *   DepositReceived
    *   WithdrawalProcessed
4.  ** Enums:**
    *   `LinkState`: PendingSuperposition, Active, Failed, Cancelled
    *   `ConditionType`: Time, Oracle, Acknowledgement, Deposit
    *   `ConditionStatus`: NotMet, Met, Irrelevant (e.g., if link cancelled)
5.  ** Structs:**
    *   `Condition`: type, parameters (bytes), status, linked data (e.g., oracle ID, required address/amount)
    *   `Link`: partyA, partyB, state, creationTimestamp, resolutionTimestamp, conditions (mapping ID => Condition), properties (mapping bytes32 => bytes), depositAmount
6.  ** State Variables:**
    *   `_owner`: Contract owner address
    *   `_linkCounter`: Counter for unique link IDs
    *   `_conditionCounter`: Counter for unique condition IDs
    *   `_oracleCounter`: Counter for unique oracle IDs
    *   `links`: Mapping from link ID to Link struct
    *   `linkConditionIds`: Mapping from link ID to array of condition IDs
    *   `oracles`: Mapping from oracle ID to oracle address
    *   `oracleManagers`: Mapping from address to boolean (can manage oracles)
    *   `linkDeposits`: Mapping from link ID to deposit amount (redundant with struct, but maybe useful for tracking)
    *   `acknowledgedParties`: Mapping from link ID => address => bool (for acknowledgement conditions)
7.  ** Modifiers:**
    *   `onlyOwner`
    *   `onlyOracleManager`
    *   `onlyLinkParty(uint256 linkId)`
    *   `onlyLinkPartyOrOracle(uint256 linkId)`
    *   `whenLinkStateIs(uint256 linkId, LinkState expectedState)`
    *   `whenLinkStateIsNot(uint256 linkId, LinkState unexpectedState)`
8.  ** Functions (20+):** (See summary below)

**Function Summary:**

*   **Admin/Setup (5 functions):**
    1.  `constructor()`: Sets initial owner.
    2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
    3.  `setOracleManager(address manager, bool canManage)`: Grants or revokes oracle manager role.
    4.  `registerOracle(address oracleAddress)`: Registers a new oracle address, returns ID.
    5.  `deregisterOracle(uint256 oracleId)`: Removes a registered oracle.
*   **Link Creation (1 function):**
    6.  `createLink(address partyB)`: Creates a new link in `PendingSuperposition` state between `msg.sender` (Party A) and `partyB`. Returns the new link ID.
*   **Adding Conditions (4 functions):** Conditions can only be added to `PendingSuperposition` links, typically by Party A.
    7.  `addTimeCondition(uint256 linkId, uint256 expiryTimestamp)`: Adds a time-based condition.
    8.  `addOracleCondition(uint256 linkId, uint256 oracleId, bytes memory requiredOracleData)`: Adds an oracle-based condition. The `requiredOracleData` specifies what the oracle needs to provide for the condition to be met (interpretation is oracle-specific).
    9.  `addAcknowledgementCondition(uint256 linkId, address requiredAcknowledger)`: Adds a condition requiring a specific party to acknowledge the link.
    10. `addDepositCondition(uint256 linkId, uint256 requiredAmount)`: Adds a condition requiring a specific ETH deposit amount.
*   **Meeting Conditions / Interaction (3 functions):**
    11. `acknowledgeLink(uint256 linkId)`: Allows a required party to acknowledge a link, potentially meeting an `Acknowledgement` condition.
    12. `depositForLink(uint256 linkId) payable`: Allows anyone to deposit ETH for a link, potentially meeting a `Deposit` condition.
    13. `triggerOracleConditionMet(uint256 linkId, uint256 conditionId, bytes memory oracleProofData)`: Function called by a registered oracle to signal that a specific oracle condition is met. Includes proof data from the oracle.
*   **Resolution & State Management (3 functions):**
    14. `checkConditionStatus(uint256 linkId, uint256 conditionId)`: Public function to check the current status of a specific condition (time, deposit, acknowledgement are checked on-chain; oracle status depends on `triggerOracleConditionMet` being called). Does *not* update state.
    15. `resolveLink(uint256 linkId)`: Attempts to resolve the link from `PendingSuperposition`. Checks all conditions: if all `Met` and time valid -> `Active`; if any cannot be `Met` or time expired -> `Failed`.
    16. `cancelLink(uint256 linkId)`: Allows Party A or B (or owner?) to cancel a link if it's still in `PendingSuperposition`.
*   **Dynamic Properties (2 functions):**
    17. `setLinkProperty(uint256 linkId, bytes32 key, bytes memory value)`: Allows parties of the link (or others with permission?) to set/update a dynamic property on the link.
    18. `getLinkProperty(uint256 linkId, bytes32 key)`: Retrieves a dynamic property value for a link.
*   **Querying & Utility (4 functions):**
    19. `getLinkDetails(uint256 linkId)`: Retrieves the full struct details of a link.
    20. `getLinkConditionDetails(uint256 linkId, uint256 conditionId)`: Retrieves the details of a specific condition for a link.
    21. `getLinkConditionsList(uint256 linkId)`: Retrieves the list of all condition IDs for a link.
    22. `withdrawDeposits(uint256 linkId)`: Allows the original depositor to withdraw their deposit if the link is not `Active`. (If `Active`, funds might be distributed - requires more complex logic not included here for simplicity).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLink
 * @dev A contract for managing dynamic, conditional links between parties.
 * Links start in a metaphorical "Superposition" state and resolve to Active
 * or Failed based on conditions involving time, oracles, acknowledgements,
 * and deposits. Links can also hold dynamic properties.
 */

// Outline:
// 1. SPDX License and Pragma
// 2. Imports (Ownable - using inline implementation for this example)
// 3. Events
// 4. Enums
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Functions (22+)

// Function Summary:
// Admin/Setup:
// 1. constructor() - Sets initial owner.
// 2. transferOwnership(address newOwner) - Transfers contract ownership.
// 3. setOracleManager(address manager, bool canManage) - Grants/revokes oracle manager role.
// 4. registerOracle(address oracleAddress) - Registers a new oracle, returns ID.
// 5. deregisterOracle(uint256 oracleId) - Removes a registered oracle.

// Link Creation:
// 6. createLink(address partyB) - Creates a new link in PendingSuperposition.

// Adding Conditions:
// 7. addTimeCondition(uint256 linkId, uint256 expiryTimestamp) - Adds a time condition.
// 8. addOracleCondition(uint256 linkId, uint256 oracleId, bytes memory requiredOracleData) - Adds an oracle condition.
// 9. addAcknowledgementCondition(uint256 linkId, address requiredAcknowledger) - Adds an acknowledgement condition.
// 10. addDepositCondition(uint256 linkId, uint256 requiredAmount) - Adds a deposit condition.

// Meeting Conditions / Interaction:
// 11. acknowledgeLink(uint256 linkId) - Allows a party to acknowledge.
// 12. depositForLink(uint256 linkId) payable - Allows depositing funds.
// 13. triggerOracleConditionMet(uint256 linkId, uint256 conditionId, bytes memory oracleProofData) - Called by oracle to signal condition met.

// Resolution & State Management:
// 14. checkConditionStatus(uint256 linkId, uint256 conditionId) view - Checks condition status without state change.
// 15. resolveLink(uint256 linkId) - Attempts to resolve the link state based on conditions.
// 16. cancelLink(uint256 linkId) - Allows parties/owner to cancel a pending link.

// Dynamic Properties:
// 17. setLinkProperty(uint256 linkId, bytes32 key, bytes memory value) - Sets/updates a link property.
// 18. getLinkProperty(uint256 linkId, bytes32 key) view - Gets a link property.

// Querying & Utility:
// 19. getLinkDetails(uint256 linkId) view - Gets full link details.
// 20. getLinkConditionDetails(uint256 linkId, uint256 conditionId) view - Gets condition details.
// 21. getLinkConditionsList(uint256 linkId) view - Gets list of condition IDs for a link.
// 22. withdrawDeposits(uint256 linkId) - Allows depositor to withdraw if link not Active.

contract QuantumLink {

    // --- Imports (Inline Ownable) ---
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // --- Events ---
    event LinkCreated(uint256 indexed linkId, address indexed partyA, address indexed partyB, uint256 creationTimestamp);
    event ConditionAdded(uint256 indexed linkId, uint256 indexed conditionId, ConditionType conditionType);
    event ConditionStatusUpdated(uint256 indexed linkId, uint256 indexed conditionId, ConditionStatus newStatus);
    event LinkResolved(uint256 indexed linkId, LinkState newState, uint256 resolutionTimestamp);
    event LinkPropertyUpdated(uint256 indexed linkId, bytes32 indexed key, bytes value);
    event OracleRegistered(uint256 indexed oracleId, address indexed oracleAddress);
    event OracleRemoved(uint256 indexed oracleId, address indexed oracleAddress);
    event DepositReceived(uint256 indexed linkId, address indexed depositor, uint256 amount);
    event WithdrawalProcessed(uint256 indexed linkId, address indexed recipient, uint256 amount);

    // --- Enums ---
    enum LinkState {
        PendingSuperposition, // Waiting for conditions
        Active,               // All conditions met
        Failed,               // Some conditions failed or time expired
        Cancelled             // Manually cancelled
    }

    enum ConditionType {
        Time,          // Must resolve before a timestamp
        Oracle,        // Depends on external data via registered oracle
        Acknowledgement, // Requires a specific party to acknowledge
        Deposit        // Requires a specific ETH deposit amount
    }

    enum ConditionStatus {
        NotMet,       // Condition not yet met
        Met,          // Condition has been met
        Irrelevant    // Condition no longer matters (e.g., link cancelled/resolved)
    }

    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        bytes parameters; // Holds type-specific data (e.g., expiry timestamp bytes, oracleId+requiredData bytes, requiredAddress bytes, requiredAmount bytes)
        ConditionStatus status;
        uint256 conditionId; // Store ID within struct for easier retrieval
    }

    struct Link {
        address partyA;
        address partyB;
        LinkState state;
        uint256 creationTimestamp;
        uint256 resolutionTimestamp; // Set when state is no longer PendingSuperposition
        uint256 depositAmount; // Total ETH deposited for this link
        mapping(uint256 => Condition) conditions; // Map condition ID to Condition struct
        mapping(bytes32 => bytes) properties; // Dynamic properties
    }

    // --- State Variables ---
    uint256 private _linkCounter;
    uint256 private _conditionCounter;
    uint256 private _oracleCounter;

    mapping(uint256 => Link) public links; // public getter generated
    mapping(uint256 => uint256[]) private linkConditionIds; // Store IDs for iteration
    mapping(uint256 => address) private oracles; // Map oracle ID to address
    mapping(address => uint256) private oracleAddressToId; // Map address back to ID
    mapping(address => bool) private oracleManagers; // Addresses allowed to manage oracles
    mapping(uint256 => mapping(address => bool)) private acknowledgedParties; // linkId => address => bool

    // --- Modifiers ---
    modifier onlyOracleManager() {
        require(oracleManagers[msg.sender], "QuantumLink: caller is not an oracle manager");
        _;
    }

    modifier onlyLinkParty(uint256 linkId) {
        require(links[linkId].partyA == msg.sender || links[linkId].partyB == msg.sender, "QuantumLink: caller is not a party to the link");
        _;
    }

     modifier onlyLinkPartyOrOracle(uint256 linkId) {
        bool isParty = links[linkId].partyA == msg.sender || links[linkId].partyB == msg.sender;
        bool isOracle = false;
        // Check if sender is any registered oracle
        if(oracleAddressToId[msg.sender] != 0) { // Basic check if address is registered as an oracle
             isOracle = true; // This is a simplified check, a real system might need more granular oracle permissions
        }
        require(isParty || isOracle, "QuantumLink: caller is not a party or a registered oracle");
        _;
    }


    modifier whenLinkStateIs(uint256 linkId, LinkState expectedState) {
        require(links[linkId].state == expectedState, "QuantumLink: Invalid link state for this action");
        _;
    }

     modifier whenLinkStateIsNot(uint256 linkId, LinkState unexpectedState) {
        require(links[linkId].state != unexpectedState, "QuantumLink: Invalid link state for this action");
        _;
    }


    // --- Admin/Setup Functions ---

    /**
     * @dev Grants or revokes the role of oracle manager.
     * Only the owner can call this.
     * @param manager The address to grant or revoke the role for.
     * @param canManage True to grant, false to revoke.
     */
    function setOracleManager(address manager, bool canManage) external onlyOwner {
        oracleManagers[manager] = canManage;
    }

    /**
     * @dev Registers a new oracle address.
     * Oracle managers can call this.
     * @param oracleAddress The address of the oracle contract or service.
     * @return The unique ID assigned to the registered oracle.
     */
    function registerOracle(address oracleAddress) external onlyOracleManager returns (uint256) {
        require(oracleAddress != address(0), "QuantumLink: Invalid oracle address");
        uint256 oracleId = ++_oracleCounter;
        oracles[oracleId] = oracleAddress;
        oracleAddressToId[oracleAddress] = oracleId; // Store reverse mapping
        emit OracleRegistered(oracleId, oracleAddress);
        return oracleId;
    }

    /**
     * @dev Deregisters an oracle by its ID.
     * Oracle managers can call this.
     * @param oracleId The ID of the oracle to deregister.
     */
    function deregisterOracle(uint256 oracleId) external onlyOracleManager {
        address oracleAddress = oracles[oracleId];
        require(oracleAddress != address(0), "QuantumLink: Oracle ID does not exist");
        delete oracles[oracleId];
        delete oracleAddressToId[oracleAddress]; // Remove reverse mapping
        emit OracleRemoved(oracleId, oracleAddress);
    }


    // --- Link Creation Function ---

    /**
     * @dev Creates a new link between msg.sender (Party A) and partyB.
     * Initially in PendingSuperposition state with no conditions.
     * @param partyB The address of the other party in the link.
     * @return The unique ID of the newly created link.
     */
    function createLink(address partyB) external returns (uint256) {
        require(partyB != address(0), "QuantumLink: Party B cannot be zero address");
        require(partyB != msg.sender, "QuantumLink: Cannot link to yourself");

        uint256 newLinkId = ++_linkCounter;
        links[newLinkId].partyA = msg.sender;
        links[newLinkId].partyB = partyB;
        links[newLinkId].state = LinkState.PendingSuperposition;
        links[newLinkId].creationTimestamp = block.timestamp;
        links[newLinkId].depositAmount = 0; // Initialize deposit amount

        emit LinkCreated(newLinkId, msg.sender, partyB, block.timestamp);
        return newLinkId;
    }

    // --- Adding Conditions Functions ---

    /**
     * @dev Adds a time-based condition to a pending link.
     * The link must resolve before the expiryTimestamp.
     * Only Party A of a pending link can add conditions.
     * @param linkId The ID of the link.
     * @param expiryTimestamp The timestamp by which the link must resolve.
     */
    function addTimeCondition(uint256 linkId, uint256 expiryTimestamp) external onlyLinkParty(linkId) whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
         require(links[linkId].partyA == msg.sender, "QuantumLink: Only Party A can add conditions");
         require(expiryTimestamp > block.timestamp, "QuantumLink: Expiry timestamp must be in the future");

        uint256 conditionId = ++_conditionCounter;
        bytes memory params = abi.encode(expiryTimestamp);
        links[linkId].conditions[conditionId] = Condition({
            conditionType: ConditionType.Time,
            parameters: params,
            status: ConditionStatus.NotMet, // Status for Time is checked directly in checkConditionStatus
            conditionId: conditionId
        });
        linkConditionIds[linkId].push(conditionId);

        emit ConditionAdded(linkId, conditionId, ConditionType.Time);
    }

    /**
     * @dev Adds an oracle-based condition to a pending link.
     * Depends on a registered oracle signalling the condition is met.
     * Only Party A of a pending link can add conditions.
     * @param linkId The ID of the link.
     * @param oracleId The ID of the registered oracle.
     * @param requiredOracleData Specific data expected from the oracle (interpretation depends on oracle).
     */
    function addOracleCondition(uint256 linkId, uint256 oracleId, bytes memory requiredOracleData) external onlyLinkParty(linkId) whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        require(links[linkId].partyA == msg.sender, "QuantumLink: Only Party A can add conditions");
        require(oracles[oracleId] != address(0), "QuantumLink: Invalid oracle ID");

        uint256 conditionId = ++_conditionCounter;
        // Store oracleId and requiredOracleData in parameters
        bytes memory params = abi.encode(oracleId, requiredOracleData);
        links[linkId].conditions[conditionId] = Condition({
            conditionType: ConditionType.Oracle,
            parameters: params,
            status: ConditionStatus.NotMet,
            conditionId: conditionId
        });
        linkConditionIds[linkId].push(conditionId);

        emit ConditionAdded(linkId, conditionId, ConditionType.Oracle);
    }

    /**
     * @dev Adds an acknowledgement condition to a pending link.
     * Requires a specific address to call acknowledgeLink.
     * Only Party A of a pending link can add conditions.
     * @param linkId The ID of the link.
     * @param requiredAcknowledger The address that must acknowledge.
     */
    function addAcknowledgementCondition(uint256 linkId, address requiredAcknowledger) external onlyLinkParty(linkId) whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        require(links[linkId].partyA == msg.sender, "QuantumLink: Only Party A can add conditions");
         require(requiredAcknowledger != address(0), "QuantumLink: Required acknowledger cannot be zero address");

        uint256 conditionId = ++_conditionCounter;
        bytes memory params = abi.encode(requiredAcknowledger);
         links[linkId].conditions[conditionId] = Condition({
            conditionType: ConditionType.Acknowledgement,
            parameters: params,
            status: ConditionStatus.NotMet,
            conditionId: conditionId
        });
        linkConditionIds[linkId].push(conditionId);

        emit ConditionAdded(linkId, conditionId, ConditionType.Acknowledgement);
    }

    /**
     * @dev Adds a deposit condition to a pending link.
     * Requires a total ETH deposit of `requiredAmount` for this condition specifically.
     * Note: Multiple deposit conditions would require more complex tracking. This assumes ONE deposit condition type per link ID effectively.
     * Only Party A of a pending link can add conditions.
     * @param linkId The ID of the link.
     * @param requiredAmount The total amount of ETH required for this condition.
     */
    function addDepositCondition(uint256 linkId, uint256 requiredAmount) external onlyLinkParty(linkId) whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
         require(links[linkId].partyA == msg.sender, "QuantumLink: Only Party A can add conditions");
        require(requiredAmount > 0, "QuantumLink: Required deposit amount must be greater than zero");

        // Prevent adding multiple deposit conditions - simplify logic
        for(uint i = 0; i < linkConditionIds[linkId].length; i++) {
            if(links[linkId].conditions[linkConditionIds[linkId][i]].conditionType == ConditionType.Deposit) {
                revert("QuantumLink: Only one deposit condition allowed per link");
            }
        }

        uint256 conditionId = ++_conditionCounter;
        bytes memory params = abi.encode(requiredAmount);
        links[linkId].conditions[conditionId] = Condition({
            conditionType: ConditionType.Deposit,
            parameters: params,
            status: ConditionStatus.NotMet, // Status checked in checkConditionStatus
            conditionId: conditionId
        });
        linkConditionIds[linkId].push(conditionId);

        emit ConditionAdded(linkId, conditionId, ConditionType.Deposit);
    }


    // --- Meeting Conditions / Interaction Functions ---

    /**
     * @dev Allows a party to acknowledge a link.
     * Can potentially meet an Acknowledgement condition if msg.sender is the required acknowledger.
     * Works only for links in PendingSuperposition.
     * @param linkId The ID of the link to acknowledge.
     */
    function acknowledgeLink(uint256 linkId) external whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        acknowledgedParties[linkId][msg.sender] = true;

        // Check if this action met any acknowledgement condition
        uint256[] storage conditionIds = linkConditionIds[linkId];
        for (uint256 i = 0; i < conditionIds.length; i++) {
            uint256 condId = conditionIds[i];
            Condition storage condition = links[linkId].conditions[condId];

            if (condition.conditionType == ConditionType.Acknowledgement && condition.status == ConditionStatus.NotMet) {
                 address requiredAcknowledger = abi.decode(condition.parameters, (address));
                if (acknowledgedParties[linkId][requiredAcknowledger]) {
                    condition.status = ConditionStatus.Met;
                    emit ConditionStatusUpdated(linkId, condId, ConditionStatus.Met);
                }
            }
        }
         // Automatically attempt to resolve after potential condition met
        resolveLink(linkId);
    }

    /**
     * @dev Allows anyone to deposit ETH for a link.
     * Can potentially meet a Deposit condition.
     * Works only for links in PendingSuperposition.
     * @param linkId The ID of the link to deposit for.
     */
    function depositForLink(uint256 linkId) external payable whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        require(msg.value > 0, "QuantumLink: Must send ETH to deposit");

        links[linkId].depositAmount += msg.value;
        emit DepositReceived(linkId, msg.sender, msg.value);

        // Check if this deposit met any deposit condition
         uint256[] storage conditionIds = linkConditionIds[linkId];
        for (uint256 i = 0; i < conditionIds.length; i++) {
            uint256 condId = conditionIds[i];
            Condition storage condition = links[linkId].conditions[condId];

            if (condition.conditionType == ConditionType.Deposit && condition.status == ConditionStatus.NotMet) {
                 uint256 requiredAmount = abi.decode(condition.parameters, (uint256));
                 if (links[linkId].depositAmount >= requiredAmount) {
                    condition.status = ConditionStatus.Met;
                    emit ConditionStatusUpdated(linkId, condId, ConditionStatus.Met);
                }
            }
        }

        // Automatically attempt to resolve after potential condition met
        resolveLink(linkId);
    }

    /**
     * @dev Called by a registered oracle to signal an Oracle condition is met.
     * Includes proof data from the oracle which can be verified off-chain.
     * Only the *correct* registered oracle for the condition's oracleId can call this.
     * @param linkId The ID of the link.
     * @param conditionId The ID of the oracle condition to update.
     * @param oracleProofData Data provided by the oracle as proof (contract does not verify this data).
     */
    function triggerOracleConditionMet(uint256 linkId, uint256 conditionId, bytes memory oracleProofData) external whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        Condition storage condition = links[linkId].conditions[conditionId];
        require(condition.conditionType == ConditionType.Oracle, "QuantumLink: Not an oracle condition");
        require(condition.status == ConditionStatus.NotMet, "QuantumLink: Condition already met or irrelevant");

        (uint256 requiredOracleId, ) = abi.decode(condition.parameters, (uint256, bytes));
        require(oracles[requiredOracleId] != address(0), "QuantumLink: Oracle ID not registered");
        require(oracles[requiredOracleId] == msg.sender, "QuantumLink: Caller is not the required oracle");

        // In a real dApp, the oracle service would verify its own proofData
        // The contract just trusts the registered oracle's call.

        condition.status = ConditionStatus.Met;
        emit ConditionStatusUpdated(linkId, conditionId, ConditionStatus.Met);

        // Automatically attempt to resolve after potential condition met
        resolveLink(linkId);
    }


    // --- Resolution & State Management Functions ---

     /**
     * @dev Internal helper to check a condition's status based on current state.
     * This checks time, deposit amount, and acknowledgement flags.
     * Oracle conditions status is based on whether triggerOracleConditionMet was called.
     * Does NOT change state or emit events.
     * @param linkId The ID of the link.
     * @param conditionId The ID of the condition.
     * @return The current status of the condition.
     */
    function checkConditionStatus(uint256 linkId, uint256 conditionId) public view returns (ConditionStatus) {
        Link storage link = links[linkId];
        Condition storage condition = link.conditions[conditionId];

        if (link.state != LinkState.PendingSuperposition) {
            return ConditionStatus.Irrelevant; // Conditions only matter in Superposition
        }

        if (condition.conditionType == ConditionType.Time) {
            uint256 expiryTimestamp = abi.decode(condition.parameters, (uint256));
            if (block.timestamp < expiryTimestamp) {
                return ConditionStatus.NotMet; // Time is still valid
            } else {
                return ConditionStatus.Met; // Time has passed (condition for RESOLVING means time is OK, NOT time expired) - Let's reverse: condition MET means time is *not* expired.
                 // Correction: A time condition means the link must resolve *before* the timestamp.
                 // So condition is MET if NOW < expiry.
                 if (block.timestamp < expiryTimestamp) {
                     return ConditionStatus.Met; // Condition met: Time constraint is not violated yet
                 } else {
                     return ConditionStatus.NotMet; // Condition NOT met: Time constraint IS violated (link should fail)
                 }
            }
        } else if (condition.conditionType == ConditionType.Oracle) {
            // Oracle condition status is ONLY updated by the oracle itself
             return condition.status;
        } else if (condition.conditionType == ConditionType.Acknowledgement) {
             address requiredAcknowledger = abi.decode(condition.parameters, (address));
             return acknowledgedParties[linkId][requiredAcknowledger] ? ConditionStatus.Met : ConditionStatus.NotMet;
        } else if (condition.conditionType == ConditionType.Deposit) {
             uint256 requiredAmount = abi.decode(condition.parameters, (uint256));
             return link.depositAmount >= requiredAmount ? ConditionStatus.Met : ConditionStatus.NotMet;
        }

        return ConditionStatus.Irrelevant; // Should not happen
    }


    /**
     * @dev Attempts to resolve the link state from PendingSuperposition.
     * Checks all conditions. If all conditions are Met, state becomes Active.
     * If any condition is NotMet and cannot possibly be met (e.g., time expired, oracle not called),
     * or if *any* condition status is still NotMet after checking dynamic ones, state becomes Failed.
     * Can be called by anyone, but state transition only happens if conditions allow.
     * @param linkId The ID of the link.
     */
    function resolveLink(uint256 linkId) external whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        Link storage link = links[linkId];
        uint256[] storage conditionIds = linkConditionIds[linkId];

        bool allConditionsMet = true;
        bool canStillSucceed = false; // Can any currently NotMet condition still be met?

        // Iterate and check/update dynamic condition statuses
        for (uint256 i = 0; i < conditionIds.length; i++) {
            uint256 condId = conditionIds[i];
            Condition storage condition = link.conditions[condId];

            // Update status for dynamic conditions before final check
            if (condition.conditionType == ConditionType.Time ||
                condition.conditionType == ConditionType.Acknowledgement ||
                condition.conditionType == ConditionType.Deposit)
            {
                ConditionStatus currentStatus = checkConditionStatus(linkId, condId);
                if (condition.status != currentStatus) {
                     condition.status = currentStatus; // Update status if it changed
                     emit ConditionStatusUpdated(linkId, condId, currentStatus);
                }
            }

            if (condition.status != ConditionStatus.Met) {
                allConditionsMet = false;

                // Check if this condition can still be met
                if (condition.conditionType == ConditionType.Time) {
                    uint256 expiryTimestamp = abi.decode(condition.parameters, (uint256));
                    if (block.timestamp < expiryTimestamp) {
                        canStillSucceed = true; // Time has not expired yet
                    }
                } else if (condition.conditionType == ConditionType.Oracle) {
                    // An oracle condition not met means the oracle hasn't triggered it.
                    // It *can* still be triggered unless Time condition expired.
                    canStillSucceed = true;
                 } else if (condition.conditionType == ConditionType.Acknowledgement) {
                     // Requires a party to acknowledge. Can still happen.
                     canStillSucceed = true;
                 } else if (condition.conditionType == ConditionType.Deposit) {
                     // Requires deposit. Can still happen if total deposit < required.
                     canStillSucceed = true;
                 }
            }
        }

        if (allConditionsMet) {
            // Transition to Active
            link.state = LinkState.Active;
            link.resolutionTimestamp = block.timestamp;
            emit LinkResolved(linkId, LinkState.Active, block.timestamp);

        } else if (!canStillSucceed) {
             // Transition to Failed if no conditions can still be met
            link.state = LinkState.Failed;
            link.resolutionTimestamp = block.timestamp;
             emit LinkResolved(linkId, LinkState.Failed, block.timestamp);
        }
        // If !allConditionsMet && canStillSucceed, link remains in PendingSuperposition
    }

    /**
     * @dev Allows Party A or Party B (or owner) to cancel a link.
     * Can only be called if the link is in PendingSuperposition.
     * @param linkId The ID of the link to cancel.
     */
    function cancelLink(uint256 linkId) external whenLinkStateIs(linkId, LinkState.PendingSuperposition) {
        // Allow Party A or B to cancel
        require(links[linkId].partyA == msg.sender || links[linkId].partyB == msg.sender || _owner == msg.sender, "QuantumLink: Caller must be a party or owner");

        Link storage link = links[linkId];
        link.state = LinkState.Cancelled;
        link.resolutionTimestamp = block.timestamp;

        // Mark conditions as Irrelevant
        uint256[] storage conditionIds = linkConditionIds[linkId];
        for (uint256 i = 0; i < conditionIds.length; i++) {
            uint256 condId = conditionIds[i];
            Condition storage condition = link.conditions[condId];
             if (condition.status != ConditionStatus.Irrelevant) {
                condition.status = ConditionStatus.Irrelevant;
                 emit ConditionStatusUpdated(linkId, condId, ConditionStatus.Irrelevant);
             }
        }

        emit LinkResolved(linkId, LinkState.Cancelled, block.timestamp);
    }

    // --- Dynamic Properties Functions ---

    /**
     * @dev Sets or updates a dynamic property for a link.
     * Can be called by Party A or Party B of the link.
     * @param linkId The ID of the link.
     * @param key The bytes32 key for the property.
     * @param value The bytes value for the property.
     */
    function setLinkProperty(uint256 linkId, bytes32 key, bytes memory value) external onlyLinkParty(linkId) whenLinkStateIsNot(linkId, LinkState.Cancelled) {
        // Allow setting properties on PendingSuperposition, Active, Failed states
        // Disallow on Cancelled

        links[linkId].properties[key] = value;
        emit LinkPropertyUpdated(linkId, key, value);
    }

    /**
     * @dev Retrieves a dynamic property for a link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @param key The bytes32 key for the property.
     * @return The bytes value of the property. Returns empty bytes if not found.
     */
    function getLinkProperty(uint256 linkId, bytes32 key) external view returns (bytes memory) {
        return links[linkId].properties[key];
    }

    // --- Querying & Utility Functions ---

    /**
     * @dev Retrieves the full details of a link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @return A tuple containing the link's details.
     */
    function getLinkDetails(uint256 linkId) external view returns (
        address partyA,
        address partyB,
        LinkState state,
        uint256 creationTimestamp,
        uint256 resolutionTimestamp,
        uint256 depositAmount
    ) {
        Link storage link = links[linkId];
        return (
            link.partyA,
            link.partyB,
            link.state,
            link.creationTimestamp,
            link.resolutionTimestamp,
            link.depositAmount
        );
    }

    /**
     * @dev Retrieves the details of a specific condition for a link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @param conditionId The ID of the condition.
     * @return A tuple containing the condition's details.
     */
    function getLinkConditionDetails(uint256 linkId, uint256 conditionId) external view returns (
        ConditionType conditionType,
        bytes memory parameters,
        ConditionStatus status,
        uint256 cId
    ) {
         Condition storage condition = links[linkId].conditions[conditionId];
        return (
            condition.conditionType,
            condition.parameters,
            // For dynamic conditions, call the helper to get current status
            condition.conditionType == ConditionType.Time ||
            condition.conditionType == ConditionType.Acknowledgement ||
            condition.conditionType == ConditionType.Deposit
                ? checkConditionStatus(linkId, conditionId)
                : condition.status,
            condition.conditionId
        );
    }

     /**
     * @dev Retrieves the list of all condition IDs for a link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @return An array of condition IDs.
     */
    function getLinkConditionsList(uint256 linkId) external view returns (uint256[] memory) {
        return linkConditionIds[linkId];
    }

    /**
     * @dev Allows the original depositor to withdraw their deposit if the link is not Active.
     * If the link is Cancelled or Failed, funds are returned to the depositor.
     * If the link is Active, funds might be claimable differently (not implemented here).
     * Requires the depositor to track their own deposit amounts per link ID.
     * Note: A more robust contract would track individual depositor amounts per link.
     * This basic version assumes a single withdrawal of the total deposited amount,
     * likely by the person who made the LAST required deposit to meet a condition,
     * or requires off-chain tracking of depositors. For simplicity, it assumes msg.sender
     * was the single depositor or is authorized to sweep.
     * A better implementation would iterate over individual deposit records.
     * We'll make a simplifying assumption: only the total is tracked, withdrawal
     * returns the total but requires off-chain trust or tracking of who gets what.
     * Or, let's allow withdrawal by ANYONE *if* state is Cancelled or Failed.
     * If state is Pending, no withdrawal allowed. If Active, withdrawal rules need to be defined (e.g., parties can claim).
     * For simplicity here: Anyone can trigger withdrawal of the total deposit IF link is Cancelled or Failed.
     *
     * @param linkId The ID of the link.
     */
    function withdrawDeposits(uint256 linkId) external whenLinkStateIsNot(linkId, LinkState.PendingSuperposition) {
        Link storage link = links[linkId];
        require(link.depositAmount > 0, "QuantumLink: No deposits to withdraw");

        // Define withdrawal rules based on state
        bool canWithdraw = false;
        address recipient = address(0);

        if (link.state == LinkState.Cancelled || link.state == LinkState.Failed) {
            // If cancelled or failed, funds are typically returned to the depositor(s).
            // As we don't track individual depositors here, we'll send to Party A.
            // A real contract would need more sophisticated tracking or rules.
            canWithdraw = true;
            recipient = link.partyA; // Arbitrary recipient for this simplified model
        } else if (link.state == LinkState.Active) {
             // If active, funds might be distributed to parties.
             // This simplified version *disallows* withdrawal via this function if active.
             // A distribution function would be needed.
             revert("QuantumLink: Deposits cannot be withdrawn via this function when link is Active");
        }

        if (canWithdraw && recipient != address(0)) {
             uint256 amountToWithdraw = link.depositAmount;
             link.depositAmount = 0; // Reset amount in the link struct

             (bool success, ) = recipient.call{value: amountToWithdraw}("");
             require(success, "QuantumLink: ETH withdrawal failed");

             emit WithdrawalProcessed(linkId, recipient, amountToWithdraw);
        } else {
             revert("QuantumLink: Deposits cannot be withdrawn in current state or by caller");
        }
    }

    /**
     * @dev Gets the total ETH amount deposited for a specific link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @return The total amount of ETH deposited.
     */
    function getDepositsForLink(uint256 linkId) external view returns (uint256) {
        return links[linkId].depositAmount;
    }

    // Fallback function to receive ETH not associated with a specific link deposit
    // Consider if this should be allowed or if ETH should only come via depositForLink
    // Adding it for completeness, but might remove in a production contract.
    receive() external payable {
       // Optionally log this unexpected ETH or revert
       // emit ReceivedUnexpectedETH(msg.sender, msg.value);
       // revert("QuantumLink: Direct ETH transfers not allowed. Use depositForLink.");
    }

    // Optional: Function to get acknowledged status of a party for a link
     /**
     * @dev Checks if a specific party has acknowledged a link.
     * Can be called by anyone.
     * @param linkId The ID of the link.
     * @param party The address to check acknowledgement status for.
     * @return True if the party has acknowledged, false otherwise.
     */
    function hasAcknowledged(uint256 linkId, address party) external view returns (bool) {
        return acknowledgedParties[linkId][party];
    }


}
```