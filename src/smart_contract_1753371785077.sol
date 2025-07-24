That's an exciting challenge! Creating something truly unique in the open-source blockchain space is tough, as many core concepts are iterated upon. However, we can create a novel *combination* of advanced functionalities with a creative theme.

Let's call this contract "ChronoNest".

**ChronoNest: Programmable Digital Legacy & Conditional Future Contracts**

**Concept:** ChronoNest allows users to create "Nests" (think of them as digital time capsules or conditional vaults). These Nests can contain various digital assets (ETH, ERC20, ERC721) or execute arbitrary function calls, but they only become accessible or triggerable when a set of predefined, verifiable *future conditions* are met. These conditions can be time-based, linked to external oracle attestations (e.g., a "liveness" check, a specific real-world event), or even require the original owner's "heartbeat" (periodic check-in). It incorporates a self-governing dispute resolution mechanism for edge cases.

---

## **I. Contract Outline:**

1.  **Overview & Core Idea:** Programmable digital legacy, conditional asset release, and future contract execution.
2.  **Solidity Version & Licenses:** Pragmas and SPDX.
3.  **Dependencies:** OpenZeppelin contracts (Ownable, Pausable, ReentrancyGuard, ERC721/ERC20 interfaces).
4.  **Error Handling:** Custom errors for clarity and gas efficiency.
5.  **Data Structures:**
    *   `AttestationCondition`: Defines a specific external data point (e.g., "isAlive" flag, a specific event ID).
    *   `NestCondition`: Aggregates time, heartbeat, and attestation conditions.
    *   `NestContent`: Abstract struct for any type of asset/call.
    *   `WrappedAsset`: Handles ETH, ERC20, ERC721 payloads.
    *   `Beneficiary`: Address and allocated share.
    *   `NestStatus` (Enum): Tracks lifecycle (Pending, Active, Claimable, Disputed, Cancelled).
    *   `Nest`: Main struct containing all details of a created "Nest".
    *   `OracleInfo`: Details about registered attestation oracles.
6.  **State Variables:** Mappings for Nests, Oracles, Nest IDs, etc. Counters for unique IDs.
7.  **Events:** For all major state changes (creation, activation, claims, disputes, etc.).
8.  **Access Control:** `Ownable` for core contract admin, modifiers for specific roles/owners.
9.  **Oracle Management:** Registration and attestation reporting for external data feeds.
10. **Nest Management:**
    *   Creation with complex conditions.
    *   Adding various content types (ETH, ERC20, ERC721, arbitrary calls).
    *   Updating conditions/beneficiaries (with restrictions).
    *   Owner "heartbeat" check-in.
    *   Cancellation/Transfer of ownership.
11. **Nest Activation & Claiming:**
    *   Public function to attempt activation once conditions are met.
    *   Beneficiary claiming of contents.
12. **Dispute Resolution & Governance (Advanced):**
    *   Initiating a dispute if activation is contested.
    *   Contract owner/DAO (simulated) resolution of disputes.
13. **View Functions:** For querying Nest status, conditions, contents, and oracle data.

---

## **II. Function Summary (25+ functions):**

**A. Core Contract Management & Access Control:**
1.  **`constructor(address _initialOracleRegistrar)`**: Initializes the contract owner and sets an initial address that can register attestation oracles.
2.  **`pause()`**: Pauses contract functionality (admin only). Inherited from `Pausable`.
3.  **`unpause()`**: Unpauses contract functionality (admin only). Inherited from `Pausable`.
4.  **`setOracleRegistrar(address _newRegistrar)`**: Changes the address authorized to register/deregister attestation oracles.
5.  **`registerAttestationOracle(bytes32 _oracleId, address _oracleAddress, string memory _description)`**: Registers a new external attestation oracle.
6.  **`deregisterAttestationOracle(bytes32 _oracleId)`**: Deregisters an existing oracle.
7.  **`reportAttestationValue(bytes32 _oracleId, bytes32 _attestationKey, uint256 _value)`**: Called by a registered oracle to report an attestation value (e.g., `_attestationKey`="isAlive", `_value`=0 for false, 1 for true).

**B. ChronoNest Creation & Management:**
8.  **`createChronoNest(NestCondition memory _conditions, Beneficiary[] memory _beneficiaries, string memory _nestDescription)`**: Creates a new ChronoNest with specified conditions, beneficiaries, and a description. Returns the unique `nestId`.
9.  **`addNestContent_ETH(uint256 _nestId) payable`**: Allows the Nest owner to deposit ETH into an existing Nest.
10. **`addNestContent_ERC20(uint256 _nestId, address _tokenAddress, uint256 _amount)`**: Allows the Nest owner to deposit ERC20 tokens into an existing Nest (requires prior approval).
11. **`addNestContent_ERC721(uint256 _nestId, address _tokenAddress, uint256 _tokenId)`**: Allows the Nest owner to deposit an ERC721 NFT into an existing Nest (requires prior approval/transfer).
12. **`addNestContent_ArbitraryCall(uint256 _nestId, address _target, bytes memory _callData)`**: Allows the Nest owner to define an arbitrary function call to be executed when the Nest activates. This is powerful for advanced DeFi interactions.
13. **`updateChronoNestConditions(uint256 _nestId, NestCondition memory _newConditions)`**: Allows the Nest owner to modify the activation conditions *before* activation (some restrictions apply, e.g., cannot remove critical conditions if already close to activation).
14. **`updateChronoNestBeneficiaries(uint256 _nestId, Beneficiary[] memory _newBeneficiaries)`**: Allows the Nest owner to modify beneficiaries and their shares *before* activation.
15. **`performHeartbeat(uint256 _nestId)`**: The Nest owner calls this to reset their "liveness" timer, preventing activation via the heartbeat condition.
16. **`transferNestOwnership(uint256 _nestId, address _newOwner)`**: Transfers ownership of a pending or active Nest to a new address.
17. **`cancelChronoNest(uint256 _nestId)`**: Allows the Nest owner to cancel a pending or active Nest and reclaim all contents.

**C. Nest Activation & Claiming:**
18. **`tryActivateNest(uint256 _nestId)`**: Public function that anyone can call to attempt to activate a Nest. It checks if all conditions are met and, if so, transitions the Nest to `Claimable` status and executes any `ArbitraryCall` contents.
19. **`claimNestContents(uint256 _nestId)`**: Allows a verified beneficiary to claim their share of a `Claimable` Nest's contents.

**D. Dispute Resolution:**
20. **`initiateDispute(uint256 _nestId, string memory _reason)`**: Allows any interested party (owner, beneficiary, or even a third party) to initiate a dispute if they believe a Nest was wrongly activated/not activated or its conditions are being misapplied. Sets Nest status to `Disputed`.
21. **`resolveDispute(uint256 _nestId, NestStatus _finalStatus, bool _revertActivation)`**: Callable only by the contract owner (or a DAO-governed multisig in a more advanced setup). This function resolves a dispute, setting the Nest to a final status (e.g., `Active`, `Claimable`, `Cancelled`), and potentially reverting a faulty activation (sending assets back to original owner).

**E. View Functions (Read-Only):**
22. **`getNestDetails(uint256 _nestId)`**: Returns all non-sensitive details of a Nest.
23. **`getNestConditions(uint256 _nestId)`**: Returns the specific conditions set for a Nest.
24. **`getNestBeneficiaries(uint256 _nestId)`**: Returns the list of beneficiaries and their shares.
25. **`getNestContents(uint256 _nestId)`**: Returns a list of contents held within a Nest (type, address, amount/tokenId).
26. **`checkNestActivationStatus(uint256 _nestId)`**: Publicly callable to check if a Nest's conditions are currently met, without activating it.
27. **`getAttestationOracleDetails(bytes32 _oracleId)`**: Returns the address and description of a registered oracle.

---

## **III. Solidity Smart Contract Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// --- Custom Errors for Gas Efficiency & Clarity ---
error ChronoNest__NestNotFound(uint256 nestId);
error ChronoNest__NestNotOwner();
error ChronoNest__NestNotActiveOrClaimable();
error ChronoNest__NestNotClaimable();
error ChronoNest__NestInvalidStatus();
error ChronoNest__NestAlreadyClaimed();
error ChronoNest__NestAlreadyDisputed();
error ChronoNest__NestNotInDispute();
error ChronoNest__NestConditionsNotMet();
error ChronoNest__BeneficiaryNotEligible();
error ChronoNest__OracleNotRegistered(bytes32 oracleId);
error ChronoNest__InvalidShareDistribution();
error ChronoNest__InsufficientFunds(uint256 required, uint256 provided);
error ChronoNest__ERC20TransferFailed();
error ChronoNest__ERC721TransferFailed();
error ChronoNest__ETHTransferFailed();
error ChronoNest__ArbitraryCallFailed();
error ChronoNest__HeartbeatNotDue();
error ChronoNest__ConditionCannotBeModified();
error ChronoNest__OracleRegistrarOnly();


/**
 * @title ChronoNest: Programmable Digital Legacy & Conditional Future Contracts
 * @dev This contract allows users to create conditional "Nests" that hold assets or execute calls,
 *      unlocking only when specific time, liveness, or external oracle conditions are met.
 *      It includes dispute resolution and flexible content types.
 */
contract ChronoNest is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum NestStatus {
        Pending,        // Created but not yet active
        Active,         // Conditions being monitored, owner can interact
        Claimable,      // Conditions met, ready for beneficiaries to claim
        Disputed,       // Status contested, awaiting resolution
        Cancelled       // Owner cancelled, contents reclaimed
    }

    enum ConditionType {
        TimeLock,       // Unlocks after a specific timestamp
        Heartbeat,      // Requires owner to *not* perform heartbeat for a duration
        Attestation     // Requires an external oracle to report a specific value
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC721,
        ArbitraryCall
    }

    // --- Structs ---

    /**
     * @dev Defines an external attestation condition.
     *      e.g., oracleId = hash("Chainlink"), attestationKey = hash("isAlive"), requiredValue = 0 (for dead)
     */
    struct AttestationCondition {
        bytes32 oracleId;
        bytes32 attestationKey;
        uint256 requiredValue;
    }

    /**
     * @dev Aggregates various conditions for Nest activation.
     *      All specified conditions must be met for activation.
     */
    struct NestCondition {
        uint64 activationTimestamp;         // 0 if not used. Nest activates AFTER this time.
        uint64 heartbeatTimeoutSeconds;     // 0 if not used. Nest activates if owner *no longer* performs heartbeat for this duration.
        uint64 lastHeartbeat;               // Timestamp of the owner's last heartbeat.
        AttestationCondition[] attestations; // List of external oracle attestations required.
        string conditionDescription;        // Human-readable description of conditions.
    }

    /**
     * @dev Represents a beneficiary and their share of the Nest contents.
     */
    struct Beneficiary {
        address recipient;
        uint16 shareBps; // Basis points (e.g., 5000 for 50%)
        bool claimed;    // Whether this beneficiary has claimed their share
    }

    /**
     * @dev Generic wrapper for various asset types that can be stored in a Nest.
     */
    struct WrappedAsset {
        AssetType assetType;
        address assetAddress; // Token address for ERC20/ERC721, target for ArbitraryCall, 0x0 for ETH
        uint256 amountOrId;   // Amount for ETH/ERC20, tokenId for ERC721
        bytes callData;       // For ArbitraryCall, the full calldata
    }

    /**
     * @dev Main Nest structure holding all relevant data.
     */
    struct Nest {
        address owner;
        NestStatus status;
        NestCondition conditions;
        Beneficiary[] beneficiaries;
        WrappedAsset[] contents;
        uint256 totalETHValue;
        bool arbitraryCallExecuted; // To ensure calls are only made once
        uint64 creationTimestamp;
        string description;
        address lastDisputeInitiator; // Address that initiated the last dispute
        string disputeReason;         // Reason provided for the last dispute
    }

    /**
     * @dev Information about a registered attestation oracle.
     */
    struct OracleInfo {
        address oracleAddress;
        string description;
        mapping(bytes32 => uint256) latestAttestations; // attestationKey => value
    }

    // --- State Variables ---

    uint256 private s_nestIdCounter; // Counter for unique Nest IDs
    uint256 private constant MAX_BENEFICIARIES = 10;
    uint256 private constant MAX_ATTESTATIONS_PER_NEST = 5;

    // Mapping: nestId => Nest
    mapping(uint256 => Nest) private s_nests;
    // Mapping: owner address => array of nestIds owned by them
    mapping(address => uint256[]) private s_ownerNests;
    // Mapping: oracleId => OracleInfo
    mapping(bytes32 => OracleInfo) private s_oracles;

    address public oracleRegistrar; // Address authorized to register and deregister oracles

    // --- Events ---

    event NestCreated(
        uint256 indexed nestId,
        address indexed owner,
        NestStatus newStatus,
        string description,
        uint64 creationTimestamp
    );
    event NestStatusChanged(
        uint256 indexed nestId,
        NestStatus oldStatus,
        NestStatus newStatus
    );
    event NestConditionsUpdated(
        uint256 indexed nestId,
        address indexed updater,
        NestCondition newConditions
    );
    event NestBeneficiariesUpdated(
        uint256 indexed nestId,
        address indexed updater
    );
    event NestContentAdded(
        uint256 indexed nestId,
        AssetType assetType,
        address assetAddress,
        uint256 amountOrId
    );
    event NestClaimed(
        uint256 indexed nestId,
        address indexed beneficiary,
        AssetType assetType,
        address assetAddress,
        uint256 amountOrId
    );
    event NestCancelled(
        uint256 indexed nestId,
        address indexed owner
    );
    event NestOwnershipTransferred(
        uint256 indexed nestId,
        address indexed oldOwner,
        address indexed newOwner
    );
    event HeartbeatPerformed(
        uint256 indexed nestId,
        address indexed owner,
        uint64 timestamp
    );
    event DisputeInitiated(
        uint256 indexed nestId,
        address indexed initiator,
        string reason
    );
    event DisputeResolved(
        uint256 indexed nestId,
        address indexed resolver,
        NestStatus finalStatus,
        bool revertedActivation
    );
    event OracleRegistered(
        bytes32 indexed oracleId,
        address indexed oracleAddress,
        string description
    );
    event OracleDeregistered(
        bytes32 indexed oracleId,
        address indexed oracleAddress
    );
    event AttestationReported(
        bytes32 indexed oracleId,
        bytes32 indexed attestationKey,
        uint256 value,
        uint64 timestamp
    );
    event ArbitraryCallExecuted(
        uint256 indexed nestId,
        address indexed target,
        bytes callData,
        bool success
    );


    // --- Modifiers ---

    modifier onlyNestOwner(uint256 _nestId) {
        if (s_nests[_nestId].owner != msg.sender) revert ChronoNest__NestNotOwner();
        _;
    }

    modifier nestExists(uint256 _nestId) {
        if (s_nests[_nestId].owner == address(0)) revert ChronoNest__NestNotFound(_nestId);
        _;
    }

    modifier nestStatusIs(uint256 _nestId, NestStatus _status) {
        if (s_nests[_nestId].status != _status) revert ChronoNest__NestInvalidStatus();
        _;
    }

    modifier nestStatusIsNot(uint256 _nestId, NestStatus _status) {
        if (s_nests[_nestId].status == _status) revert ChronoNest__NestInvalidStatus();
        _;
        return;
    }

    // --- Constructor ---

    constructor(address _initialOracleRegistrar) Ownable(msg.sender) {
        oracleRegistrar = _initialOracleRegistrar;
    }

    // --- Oracle Management ---

    /**
     * @dev Sets the address authorized to register and deregister attestation oracles.
     * @param _newRegistrar The new address of the oracle registrar.
     */
    function setOracleRegistrar(address _newRegistrar) external onlyOwner {
        oracleRegistrar = _newRegistrar;
    }

    /**
     * @dev Registers a new external attestation oracle. Only callable by the oracleRegistrar.
     * @param _oracleId A unique identifier for the oracle (e.g., hash of its name).
     * @param _oracleAddress The on-chain address of the oracle contract/EOA.
     * @param _description A human-readable description of the oracle.
     */
    function registerAttestationOracle(bytes32 _oracleId, address _oracleAddress, string memory _description)
        external
        whenNotPaused
    {
        if (msg.sender != oracleRegistrar) revert ChronoNest__OracleRegistrarOnly();
        s_oracles[_oracleId].oracleAddress = _oracleAddress;
        s_oracles[_oracleId].description = _description;
        emit OracleRegistered(_oracleId, _oracleAddress, _description);
    }

    /**
     * @dev Deregisters an existing oracle. Only callable by the oracleRegistrar.
     * @param _oracleId The unique identifier of the oracle to deregister.
     */
    function deregisterAttestationOracle(bytes32 _oracleId)
        external
        whenNotPaused
    {
        if (msg.sender != oracleRegistrar) revert ChronoNest__OracleRegistrarOnly();
        if (s_oracles[_oracleId].oracleAddress == address(0)) revert ChronoNest__OracleNotRegistered(_oracleId);
        address _oracleAddress = s_oracles[_oracleId].oracleAddress;
        delete s_oracles[_oracleId];
        emit OracleDeregistered(_oracleId, _oracleAddress);
    }

    /**
     * @dev Called by a registered oracle to report an attestation value.
     *      Only the registered oracle address can call this for its specific ID.
     * @param _oracleId The unique identifier of the oracle.
     * @param _attestationKey The specific key for the attestation (e.g., hash("isAlive"), hash("eventHappened")).
     * @param _value The value being attested (e.g., 0 for false, 1 for true, or any numerical value).
     */
    function reportAttestationValue(bytes32 _oracleId, bytes32 _attestationKey, uint256 _value)
        external
        whenNotPaused
    {
        if (s_oracles[_oracleId].oracleAddress == address(0) || s_oracles[_oracleId].oracleAddress != msg.sender) {
            revert ChronoNest__OracleNotRegistered(_oracleId);
        }
        s_oracles[_oracleId].latestAttestations[_attestationKey] = _value;
        emit AttestationReported(_oracleId, _attestationKey, _value, uint64(block.timestamp));
    }

    // --- ChronoNest Creation & Management ---

    /**
     * @dev Creates a new ChronoNest with specified conditions and beneficiaries.
     * @param _conditions The set of conditions for the Nest to activate.
     * @param _beneficiaries An array of beneficiaries and their share of the contents.
     *                       Total shares must sum to 10000 (100%).
     * @param _nestDescription A human-readable description of the Nest's purpose.
     * @return The unique ID of the newly created Nest.
     */
    function createChronoNest(
        NestCondition memory _conditions,
        Beneficiary[] memory _beneficiaries,
        string memory _nestDescription
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (_beneficiaries.length == 0 || _beneficiaries.length > MAX_BENEFICIARIES) {
            revert ChronoNest__InvalidShareDistribution();
        }

        uint16 totalShares;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalShares += _beneficiaries[i].shareBps;
            // Ensure no 0x0 beneficiaries
            if (_beneficiaries[i].recipient == address(0)) {
                revert ChronoNest__InvalidShareDistribution();
            }
        }
        if (totalShares != 10000) revert ChronoNest__InvalidShareDistribution();

        // Validate attestation conditions
        if (_conditions.attestations.length > MAX_ATTESTATIONS_PER_NEST) {
            revert ChronoNest__ConditionCannotBeModified(); // Too many attestations
        }
        for (uint256 i = 0; i < _conditions.attestations.length; i++) {
            if (s_oracles[_conditions.attestations[i].oracleId].oracleAddress == address(0)) {
                revert ChronoNest__OracleNotRegistered(_conditions.attestations[i].oracleId);
            }
        }

        s_nestIdCounter++;
        uint256 newNestId = s_nestIdCounter;

        s_nests[newNestId] = Nest({
            owner: msg.sender,
            status: NestStatus.Pending,
            conditions: _conditions,
            beneficiaries: _beneficiaries,
            contents: new WrappedAsset[](0), // Initialize empty
            totalETHValue: 0,
            arbitraryCallExecuted: false,
            creationTimestamp: uint64(block.timestamp),
            description: _nestDescription,
            lastDisputeInitiator: address(0),
            disputeReason: ""
        });

        // Initialize lastHeartbeat if heartbeat condition is set
        if (_conditions.heartbeatTimeoutSeconds > 0) {
            s_nests[newNestId].conditions.lastHeartbeat = uint64(block.timestamp);
        }

        s_ownerNests[msg.sender].push(newNestId);

        emit NestCreated(newNestId, msg.sender, NestStatus.Pending, _nestDescription, uint64(block.timestamp));
        return newNestId;
    }

    /**
     * @dev Allows the Nest owner to deposit ETH into an existing Nest.
     * @param _nestId The ID of the Nest.
     */
    function addNestContent_ETH(uint256 _nestId)
        external
        payable
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        if (msg.value == 0) revert ChronoNest__InsufficientFunds(1, 0);

        s_nests[_nestId].contents.push(WrappedAsset({
            assetType: AssetType.ETH,
            assetAddress: address(0),
            amountOrId: msg.value,
            callData: ""
        }));
        s_nests[_nestId].totalETHValue += msg.value;
        emit NestContentAdded(_nestId, AssetType.ETH, address(0), msg.value);
    }

    /**
     * @dev Allows the Nest owner to deposit ERC20 tokens into an existing Nest.
     *      Requires prior approval (ERC20 `approve`) to this contract.
     * @param _nestId The ID of the Nest.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of ERC20 tokens to deposit.
     */
    function addNestContent_ERC20(uint256 _nestId, address _tokenAddress, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        if (!IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount)) {
            revert ChronoNest__ERC20TransferFailed();
        }

        s_nests[_nestId].contents.push(WrappedAsset({
            assetType: AssetType.ERC20,
            assetAddress: _tokenAddress,
            amountOrId: _amount,
            callData: ""
        }));
        emit NestContentAdded(_nestId, AssetType.ERC20, _tokenAddress, _amount);
    }

    /**
     * @dev Allows the Nest owner to deposit an ERC721 NFT into an existing Nest.
     *      Requires prior approval (ERC721 `approve` or `setApprovalForAll`) to this contract.
     * @param _nestId The ID of the Nest.
     * @param _tokenAddress The address of the ERC721 token.
     * @param _tokenId The ID of the NFT to deposit.
     */
    function addNestContent_ERC721(uint256 _nestId, address _tokenAddress, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);

        s_nests[_nestId].contents.push(WrappedAsset({
            assetType: AssetType.ERC721,
            assetAddress: _tokenAddress,
            amountOrId: _tokenId,
            callData: ""
        }));
        emit NestContentAdded(_nestId, AssetType.ERC721, _tokenAddress, _tokenId);
    }

    /**
     * @dev Allows the Nest owner to define an arbitrary function call to be executed when the Nest activates.
     *      This is useful for complex DeFi interactions, protocol calls, etc.
     * @param _nestId The ID of the Nest.
     * @param _target The address of the contract to call.
     * @param _callData The calldata for the function call.
     */
    function addNestContent_ArbitraryCall(uint256 _nestId, address _target, bytes memory _callData)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        // One arbitrary call per nest to prevent re-entrancy issues with complex calls
        // and simplify logic for now. Can be extended.
        for (uint256 i = 0; i < s_nests[_nestId].contents.length; i++) {
            if (s_nests[_nestId].contents[i].assetType == AssetType.ArbitraryCall) {
                revert ChronoNest__ConditionCannotBeModified(); // Already an arbitrary call
            }
        }

        s_nests[_nestId].contents.push(WrappedAsset({
            assetType: AssetType.ArbitraryCall,
            assetAddress: _target,
            amountOrId: 0, // Not applicable for arbitrary calls
            callData: _callData
        }));
        emit NestContentAdded(_nestId, AssetType.ArbitraryCall, _target, 0);
    }

    /**
     * @dev Allows the Nest owner to modify the activation conditions *before* activation.
     *      Cannot be called if the Nest is already active, claimable, disputed, or cancelled.
     *      Some conditions (like heartbeat expiry) might be restricted if too close to triggering.
     * @param _nestId The ID of the Nest.
     * @param _newConditions The new set of conditions.
     */
    function updateChronoNestConditions(uint256 _nestId, NestCondition memory _newConditions)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        Nest storage nest = s_nests[_nestId];
        if (nest.status == NestStatus.Active || nest.status == NestStatus.Pending) {
            // Further checks could be added here, e.g., disallowing changes if time condition is within X seconds
            // For now, simpler: allow modification unless already activated/claimed/disputed/cancelled.

            // Validate new attestation conditions
            if (_newConditions.attestations.length > MAX_ATTESTATIONS_PER_NEST) {
                revert ChronoNest__ConditionCannotBeModified();
            }
            for (uint256 i = 0; i < _newConditions.attestations.length; i++) {
                if (s_oracles[_newConditions.attestations[i].oracleId].oracleAddress == address(0)) {
                    revert ChronoNest__OracleNotRegistered(_newConditions.attestations[i].oracleId);
                }
            }

            nest.conditions = _newConditions;
            // If new conditions include heartbeat, reset its lastHeartbeat to now
            if (nest.conditions.heartbeatTimeoutSeconds > 0) {
                nest.conditions.lastHeartbeat = uint64(block.timestamp);
            }
            emit NestConditionsUpdated(_nestId, msg.sender, _newConditions);
        } else {
            revert ChronoNest__NestInvalidStatus();
        }
    }

    /**
     * @dev Allows the Nest owner to modify beneficiaries and their shares *before* activation.
     * @param _nestId The ID of the Nest.
     * @param _newBeneficiaries The new array of beneficiaries. Total shares must sum to 10000.
     */
    function updateChronoNestBeneficiaries(uint256 _nestId, Beneficiary[] memory _newBeneficiaries)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        Nest storage nest = s_nests[_nestId];
        if (_newBeneficiaries.length == 0 || _newBeneficiaries.length > MAX_BENEFICIARIES) {
            revert ChronoNest__InvalidShareDistribution();
        }

        uint16 totalShares;
        for (uint256 i = 0; i < _newBeneficiaries.length; i++) {
            totalShares += _newBeneficiaries[i].shareBps;
            if (_newBeneficiaries[i].recipient == address(0)) {
                revert ChronoNest__InvalidShareDistribution();
            }
        }
        if (totalShares != 10000) revert ChronoNest__InvalidShareDistribution();

        nest.beneficiaries = _newBeneficiaries;
        emit NestBeneficiariesUpdated(_nestId, msg.sender);
    }

    /**
     * @dev The Nest owner calls this to reset their "liveness" timer, preventing activation
     *      via the heartbeat condition.
     * @param _nestId The ID of the Nest.
     */
    function performHeartbeat(uint256 _nestId)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        Nest storage nest = s_nests[_nestId];
        if (nest.conditions.heartbeatTimeoutSeconds == 0) revert ChronoNest__HeartbeatNotDue();

        nest.conditions.lastHeartbeat = uint64(block.timestamp);
        emit HeartbeatPerformed(_nestId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Transfers ownership of a pending or active Nest to a new address.
     * @param _nestId The ID of the Nest.
     * @param _newOwner The address of the new owner.
     */
    function transferNestOwnership(uint256 _nestId, address _newOwner)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        if (_newOwner == address(0)) revert ChronoNest__NestInvalidStatus(); // Invalid owner

        Nest storage nest = s_nests[_nestId];
        address oldOwner = nest.owner;
        nest.owner = _newOwner;

        // Remove from old owner's list (simplified, in a real scenario, might need a more efficient removal)
        // For simplicity, we just add to new owner's list, and old owner's list might have stale IDs.
        // A more robust solution might involve a `mapping(address => mapping(uint256 => bool))` or explicit removal.
        s_ownerNests[_newOwner].push(_nestId);
        // Note: s_ownerNests[oldOwner] might retain _nestId. For a real dApp, you'd iterate and remove.
        // For this example, we accept potential stale entries for simplicity in this helper mapping.

        emit NestOwnershipTransferred(_nestId, oldOwner, _newOwner);
    }


    /**
     * @dev Allows the Nest owner to cancel a pending or active Nest and reclaim all contents.
     *      Cannot be cancelled if already claimable or disputed.
     * @param _nestId The ID of the Nest to cancel.
     */
    function cancelChronoNest(uint256 _nestId)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        onlyNestOwner(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        Nest storage nest = s_nests[_nestId];
        NestStatus oldStatus = nest.status;
        nest.status = NestStatus.Cancelled;

        _transferAllContents(nest.owner, nest);

        emit NestStatusChanged(_nestId, oldStatus, NestStatus.Cancelled);
        emit NestCancelled(_nestId, msg.sender);
    }

    // --- Nest Activation & Claiming ---

    /**
     * @dev Public function that anyone can call to attempt to activate a Nest.
     *      It checks if all conditions are met and, if so, transitions the Nest to `Claimable` status
     *      and executes any `ArbitraryCall` contents.
     * @param _nestId The ID of the Nest to activate.
     */
    function tryActivateNest(uint256 _nestId)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Claimable)
        nestStatusIsNot(_nestId, NestStatus.Disputed)
        nestStatusIsNot(_nestId, NestStatus.Cancelled)
    {
        Nest storage nest = s_nests[_nestId];

        // Check if conditions are met
        if (!_checkConditionsMet(nest.conditions)) {
            revert ChronoNest__NestConditionsNotMet();
        }

        NestStatus oldStatus = nest.status;
        nest.status = NestStatus.Claimable;

        // Execute arbitrary calls *after* status update to prevent re-entrancy issues
        // if the arbitrary call tries to re-enter this contract before state is final.
        for (uint256 i = 0; i < nest.contents.length; i++) {
            if (nest.contents[i].assetType == AssetType.ArbitraryCall && !nest.arbitraryCallExecuted) {
                (bool success,) = nest.contents[i].assetAddress.call(nest.contents[i].callData);
                nest.arbitraryCallExecuted = true; // Ensure it only runs once per Nest activation
                emit ArbitraryCallExecuted(_nestId, nest.contents[i].assetAddress, nest.contents[i].callData, success);
                if (!success) {
                    // Consider what to do here: revert, or just log failure?
                    // For legacy, we might want the rest to go through even if one call fails.
                    // For now, we continue, but log.
                    // revert ChronoNest__ArbitraryCallFailed(); // If we want to strictly fail activation on call failure
                }
            }
        }

        emit NestStatusChanged(_nestId, oldStatus, NestStatus.Claimable);
    }


    /**
     * @dev Allows a verified beneficiary to claim their share of a `Claimable` Nest's contents.
     *      Each beneficiary can only claim once.
     * @param _nestId The ID of the Nest.
     */
    function claimNestContents(uint256 _nestId)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        nestStatusIs(_nestId, NestStatus.Claimable)
    {
        Nest storage nest = s_nests[_nestId];
        bool isBeneficiary = false;
        uint16 beneficiaryShare = 0;
        uint256 beneficiaryIndex = 0;

        for (uint256 i = 0; i < nest.beneficiaries.length; i++) {
            if (nest.beneficiaries[i].recipient == msg.sender) {
                if (nest.beneficiaries[i].claimed) revert ChronoNest__NestAlreadyClaimed();
                isBeneficiary = true;
                beneficiaryShare = nest.beneficiaries[i].shareBps;
                beneficiaryIndex = i;
                break;
            }
        }

        if (!isBeneficiary) revert ChronoNest__BeneficiaryNotEligible();

        // Mark as claimed immediately to prevent re-entrancy / double claims
        nest.beneficiaries[beneficiaryIndex].claimed = true;

        for (uint256 i = 0; i < nest.contents.length; i++) {
            WrappedAsset storage content = nest.contents[i];
            if (content.assetType == AssetType.ETH) {
                uint256 amount = (content.amountOrId * beneficiaryShare) / 10000;
                if (amount > 0) {
                    (bool success,) = msg.sender.call{value: amount}("");
                    if (!success) {
                        // Revert the claim if ETH transfer fails
                        nest.beneficiaries[beneficiaryIndex].claimed = false; // Revert claimed status
                        revert ChronoNest__ETHTransferFailed();
                    }
                    emit NestClaimed(_nestId, msg.sender, AssetType.ETH, address(0), amount);
                }
            } else if (content.assetType == AssetType.ERC20) {
                uint256 amount = (content.amountOrId * beneficiaryShare) / 10000;
                if (amount > 0) {
                    if (!IERC20(content.assetAddress).transfer(msg.sender, amount)) {
                        nest.beneficiaries[beneficiaryIndex].claimed = false;
                        revert ChronoNest__ERC20TransferFailed();
                    }
                    emit NestClaimed(_nestId, msg.sender, AssetType.ERC20, content.assetAddress, amount);
                }
            } else if (content.assetType == AssetType.ERC721) {
                // For NFTs, we typically don't split. A specific beneficiary gets the whole NFT.
                // This requires a more complex logic, e.g., mapping NFT to a specific beneficiary.
                // For simplicity here, we assume NFTs are only for single beneficiaries or a separate claim.
                // Or, if multiple, only one claim takes it if not specifically assigned.
                // This example assigns the NFT to the *first* eligible beneficiary to claim it
                // OR we can make a rule that NFTs are always for the 100% beneficiary.
                // Let's implement that only the highest share beneficiary (or first if equal highest) can claim NFTs
                // This means the NFT should not be distributed via shares. Let's make a decision:
                // NFTs are ONLY claimable if beneficiary has 100% share, or a specific rule.
                // For now, only allow distribution for fungible tokens.
                // To distribute NFTs, you would need specific rules (e.g., first to claim, or specific beneficiary).
                // Let's assume NFTs are assigned directly or go to the first claimant if no specific assignment.
                // Here, we transfer if the beneficiary is the sole beneficiary (100% share).
                if (nest.beneficiaries.length == 1 && beneficiaryShare == 10000) {
                    IERC721(content.assetAddress).transferFrom(address(this), msg.sender, content.amountOrId);
                    emit NestClaimed(_nestId, msg.sender, AssetType.ERC721, content.assetAddress, content.amountOrId);
                } else {
                    // If multiple beneficiaries, NFTs are not split/claimed this way.
                    // A more advanced system might define which beneficiary gets which specific NFT.
                    // For now, non-100% share beneficiaries cannot claim NFTs through this general function.
                    // This means NFTs for multiple beneficiaries need a different claim process or specific rules.
                }
            }
            // ArbitraryCall is executed at activation, not claimed.
        }
    }

    // --- Dispute Resolution ---

    /**
     * @dev Allows any interested party (owner, beneficiary, or even a third party) to initiate a dispute
     *      if they believe a Nest was wrongly activated/not activated or its conditions are being misapplied.
     *      Sets Nest status to `Disputed`.
     * @param _nestId The ID of the Nest.
     * @param _reason A string explaining the reason for the dispute.
     */
    function initiateDispute(uint256 _nestId, string memory _reason)
        external
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        nestStatusIsNot(_nestId, NestStatus.Disputed) // Can't dispute an already disputed Nest
        nestStatusIsNot(_nestId, NestStatus.Cancelled) // Can't dispute a cancelled Nest
    {
        Nest storage nest = s_nests[_nestId];
        NestStatus oldStatus = nest.status;
        nest.status = NestStatus.Disputed;
        nest.lastDisputeInitiator = msg.sender;
        nest.disputeReason = _reason;

        emit NestStatusChanged(_nestId, oldStatus, NestStatus.Disputed);
        emit DisputeInitiated(_nestId, msg.sender, _reason);
    }

    /**
     * @dev Callable only by the contract owner (or a DAO-governed multisig in a more advanced setup).
     *      This function resolves a dispute, setting the Nest to a final status
     *      (e.g., `Active`, `Claimable`, `Cancelled`), and potentially reverting a faulty activation
     *      (sending assets back to original owner).
     * @param _nestId The ID of the Nest.
     * @param _finalStatus The status the Nest should transition to after resolution (e.g., Active, Claimable, Cancelled).
     * @param _revertActivation If true, and the original status was `Claimable`, all assets are returned to the owner.
     *                          This should only be used if a Nest was erroneously activated.
     */
    function resolveDispute(uint256 _nestId, NestStatus _finalStatus, bool _revertActivation)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
        nestExists(_nestId)
        nestStatusIs(_nestId, NestStatus.Disputed)
    {
        Nest storage nest = s_nests[_nestId];
        NestStatus oldStatus = nest.status;

        // Reset dispute info
        nest.lastDisputeInitiator = address(0);
        nest.disputeReason = "";

        if (_revertActivation) {
            // Only revert if it was originally in Claimable state
            if (oldStatus == NestStatus.Claimable) {
                // Return all contents to the original owner
                _transferAllContents(nest.owner, nest);
                // Reset claimed status for all beneficiaries if reverting
                for (uint256 i = 0; i < nest.beneficiaries.length; i++) {
                    nest.beneficiaries[i].claimed = false;
                }
            } else {
                revert ChronoNest__NestInvalidStatus(); // Cannot revert activation if not claimable
            }
        }

        // Set the final status based on the resolution
        nest.status = _finalStatus;

        emit NestStatusChanged(_nestId, oldStatus, _finalStatus);
        emit DisputeResolved(_nestId, msg.sender, _finalStatus, _revertActivation);
    }

    // --- View Functions ---

    /**
     * @dev Returns all non-sensitive details of a Nest.
     * @param _nestId The ID of the Nest.
     * @return A tuple containing Nest details.
     */
    function getNestDetails(uint256 _nestId)
        external
        view
        nestExists(_nestId)
        returns (
            address owner,
            NestStatus status,
            uint256 totalETHValue,
            uint64 creationTimestamp,
            string memory description,
            address lastDisputeInitiator,
            string memory disputeReason
        )
    {
        Nest storage nest = s_nests[_nestId];
        return (
            nest.owner,
            nest.status,
            nest.totalETHValue,
            nest.creationTimestamp,
            nest.description,
            nest.lastDisputeInitiator,
            nest.disputeReason
        );
    }

    /**
     * @dev Returns the specific conditions set for a Nest.
     * @param _nestId The ID of the Nest.
     * @return A tuple containing the Nest's conditions.
     */
    function getNestConditions(uint256 _nestId)
        external
        view
        nestExists(_nestId)
        returns (
            uint64 activationTimestamp,
            uint64 heartbeatTimeoutSeconds,
            uint64 lastHeartbeat,
            AttestationCondition[] memory attestations,
            string memory conditionDescription
        )
    {
        Nest storage nest = s_nests[_nestId];
        return (
            nest.conditions.activationTimestamp,
            nest.conditions.heartbeatTimeoutSeconds,
            nest.conditions.lastHeartbeat,
            nest.conditions.attestations,
            nest.conditions.conditionDescription
        );
    }

    /**
     * @dev Returns the list of beneficiaries and their shares for a Nest.
     * @param _nestId The ID of the Nest.
     * @return An array of Beneficiary structs.
     */
    function getNestBeneficiaries(uint256 _nestId)
        external
        view
        nestExists(_nestId)
        returns (Beneficiary[] memory)
    {
        return s_nests[_nestId].beneficiaries;
    }

    /**
     * @dev Returns a list of contents held within a Nest.
     * @param _nestId The ID of the Nest.
     * @return An array of WrappedAsset structs.
     */
    function getNestContents(uint256 _nestId)
        external
        view
        nestExists(_nestId)
        returns (WrappedAsset[] memory)
    {
        return s_nests[_nestId].contents;
    }

    /**
     * @dev Publicly callable to check if a Nest's conditions are currently met, without activating it.
     * @param _nestId The ID of the Nest.
     * @return True if all conditions are met, false otherwise.
     */
    function checkNestActivationStatus(uint256 _nestId)
        public
        view
        nestExists(_nestId)
        returns (bool)
    {
        Nest storage nest = s_nests[_nestId];
        return _checkConditionsMet(nest.conditions);
    }

    /**
     * @dev Returns the address and description of a registered oracle.
     * @param _oracleId The unique identifier of the oracle.
     * @return The oracle's address and description.
     */
    function getAttestationOracleDetails(bytes32 _oracleId)
        external
        view
        returns (address oracleAddress, string memory description)
    {
        OracleInfo storage info = s_oracles[_oracleId];
        if (info.oracleAddress == address(0)) revert ChronoNest__OracleNotRegistered(_oracleId);
        return (info.oracleAddress, info.description);
    }

    /**
     * @dev Returns the latest reported attestation value for a specific oracle and key.
     * @param _oracleId The unique identifier of the oracle.
     * @param _attestationKey The specific key for the attestation.
     * @return The latest value reported by the oracle for that key.
     */
    function getLatestAttestationValue(bytes32 _oracleId, bytes32 _attestationKey)
        external
        view
        returns (uint256)
    {
        OracleInfo storage info = s_oracles[_oracleId];
        if (info.oracleAddress == address(0)) revert ChronoNest__OracleNotRegistered(_oracleId);
        return info.latestAttestations[_attestationKey];
    }

    // --- Internal / Private Helper Functions ---

    /**
     * @dev Internal function to check if all conditions for a Nest are met.
     * @param _conditions The NestCondition struct to check.
     * @return True if all conditions are met, false otherwise.
     */
    function _checkConditionsMet(NestCondition memory _conditions) private view returns (bool) {
        uint64 currentTime = uint64(block.timestamp);

        // 1. TimeLock Condition
        if (_conditions.activationTimestamp > 0 && currentTime < _conditions.activationTimestamp) {
            return false;
        }

        // 2. Heartbeat Condition (Owner must *not* have performed a heartbeat for X seconds)
        if (_conditions.heartbeatTimeoutSeconds > 0 &&
            _conditions.lastHeartbeat > 0 && // Only if heartbeat was initialized
            currentTime < (_conditions.lastHeartbeat + _conditions.heartbeatTimeoutSeconds)) {
            return false;
        }

        // 3. Attestation Conditions
        for (uint256 i = 0; i < _conditions.attestations.length; i++) {
            AttestationCondition memory attestation = _conditions.attestations[i];
            OracleInfo storage oracleInfo = s_oracles[attestation.oracleId];
            if (oracleInfo.oracleAddress == address(0)) {
                // If an oracle is not registered, its condition cannot be met
                // This means the contract expects all relevant oracles to be registered.
                return false;
            }
            if (oracleInfo.latestAttestations[attestation.attestationKey] != attestation.requiredValue) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Internal function to transfer all contents of a Nest to a recipient.
     *      Used for cancellation or dispute resolution.
     * @param _recipient The address to send all assets to.
     * @param _nest The Nest struct containing the contents.
     */
    function _transferAllContents(address _recipient, Nest storage _nest) private {
        // Collect all ERC20s and ERC721s to transfer
        // Note: ETH is transferred separately as it modifies `address(this).balance`
        for (uint256 i = 0; i < _nest.contents.length; i++) {
            WrappedAsset storage content = _nest.contents[i];
            if (content.assetType == AssetType.ERC20) {
                if (IERC20(content.assetAddress).balanceOf(address(this)) >= content.amountOrId) {
                    if (!IERC20(content.assetAddress).transfer(_recipient, content.amountOrId)) {
                        revert ChronoNest__ERC20TransferFailed();
                    }
                }
            } else if (content.assetType == AssetType.ERC721) {
                // Ensure the contract still owns the NFT
                if (IERC721(content.assetAddress).ownerOf(content.amountOrId) == address(this)) {
                    IERC721(content.assetAddress).transferFrom(address(this), _recipient, content.amountOrId);
                }
            }
            // ArbitraryCall contents are not transferred, they are just definitions
        }

        // Transfer remaining ETH
        if (_nest.totalETHValue > 0) {
            (bool success,) = payable(_recipient).call{value: _nest.totalETHValue}("");
            if (!success) {
                revert ChronoNest__ETHTransferFailed();
            }
            _nest.totalETHValue = 0; // Reset ETH value after transfer
        }
    }
}
```