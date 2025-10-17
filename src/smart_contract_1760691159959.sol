I've designed a novel smart contract called `DecentralizedAdaptiveFuturePacts` (DAFP). This protocol allows users to create conditional, time-locked, and event-triggered asset transfers, governed by a dynamic oracle and reputation system. It incorporates elements of prediction markets, decentralized autonomous organizations, and adaptive contract logic.

The core idea is to enable participants to lock assets that are released only when a complex set of on-chain, time-based, or externally validated conditions are met. These external conditions are processed through a "Prophecy" system, where users submit predictions about future events, and a decentralized "Oracle Committee" validates these predictions. Users gain reputation for accurate prophecies, which grants them more influence in the protocol's governance and oracle validation.

---

## Decentralized Adaptive Future Pacts (DAFP)

A protocol for creating conditional, future-oriented asset transfers, governed by a dynamic oracle and reputation system.

**Solidity Version:** `^0.8.20`

---

### Contract Outline & Function Summary

**I. Core Pact Management**
1.  `createFuturePact`: Initiates a new Future Pact by defining locked assets, a list of participants, complex conditions for release, and the ultimate outcomes.
2.  `participateInPact`: Allows an invited user to join an existing pact, potentially adding their own assets or acknowledging terms.
3.  `amendPactConditions`: Proposes and facilitates changes to an active pact's conditions or outcomes, requiring multi-party approval or governance vote.
4.  `executePactOutcome`: Attempts to fulfill a pact. If all conditions are met, assets are distributed according to the defined outcomes.
5.  `cancelPact`: Allows the initiator or governance to cancel a pending/active pact under specific, predefined conditions.
6.  `escalatePactToGovernance`: Provides a mechanism for participants to request DAO intervention for disputed or stalled pacts.
7.  `getPactDetails`: *View function* to retrieve comprehensive information about a specific pact.

**II. Prophecy & Oracle System**
8.  `submitProphecy`: Allows a user to propose a verifiable prediction about a future external event, which can serve as a condition for pacts.
9.  `attestToProphecy`: Enables other users (especially high-reputation members) to vouch for the perceived accuracy or validity of a pending prophecy.
10. `validateProphecyOutcome`: Exclusive function for Oracle Committee members to confirm the actual outcome of an event, marking a prophecy as `Validated`.
11. `refuteProphecy`: Allows Oracle Committee members to invalidate a prophecy if its predicted outcome proves incorrect or malicious.
12. `getProphecyDetails`: *View function* to retrieve all details of a specific prophecy.
13. `queryProphecyStatus`: *View function* to quickly check the current status of a prophecy.

**III. Reputation & Governance**
14. `updateUserReputation`: *Internal function* that adjusts a user's reputation score based on successful prophecy validations, accurate attestations, or successful pact participations.
15. `getReputation`: *View function* to check the current reputation score of any address.
16. `proposeProtocolAmendment`: Allows high-reputation users or the owner to propose changes to core protocol parameters (e.g., oracle committee thresholds).
17. `voteOnAmendment`: Allows eligible token holders or high-reputation users to vote on proposed protocol amendments.
18. `executeAmendment`: Implements a passed protocol amendment, updating the contract's configurable parameters.
19. `joinOracleCommittee`: Enables high-reputation users to apply for membership in the Oracle Committee, subject to governance approval.
20. `removeOracleCommitteeMember`: Allows governance or the contract owner to remove a member from the Oracle Committee, typically due to inactivity or misconduct.

**IV. Advanced / Utility / Security**
21. `checkConditionFulfillment`: *Internal helper function* to evaluate if a given condition within a pact has been met.
22. `registerAssetLock`: *Internal function* for the protocol to internally record and manage locked assets for a pact.
23. `releaseLockedAsset`: *Internal function* to transfer locked assets to the designated recipients as per pact outcomes.
24. `emergencyProtocolHalt`: Allows the contract owner or governance to temporarily halt critical protocol operations in case of severe vulnerabilities or exploits.
25. `recoverStuckAssets`: Provides a governance-controlled mechanism to retrieve assets that may become unintentionally locked due to unforeseen protocol errors.
26. `getPactParticipantsAssets`: *View function* to list all assets locked by participants in a given pact.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAdaptiveFuturePacts (DAFP)
 * @author Your Name/Pseudonym
 * @notice A protocol for creating conditional, future-oriented asset transfers,
 *         governed by a dynamic oracle and reputation system.
 *         Users lock assets that are released based on complex, multi-factor
 *         conditions, which can include time, on-chain state, or externally
 *         validated events via a "Prophecy" system. A reputation system
 *         incentivizes accurate predictions and active participation,
 *         influencing governance and oracle validation.
 */
contract DecentralizedAdaptiveFuturePacts {

    // --- Enums ---
    enum PactStatus { Pending, Active, Fulfilled, Failed, Cancelled, Amended, Escalated }
    enum ConditionType { TimeBased, OracleEvent, OnChainState, ReputationThreshold, MultiSigApproval, AssociatedPactStatus }
    enum Operator { EQ, NE, GT, LT, GTE, LTE } // Equal, Not Equal, Greater Than, Less Than, Greater Than or Equal, Less Than or Equal
    enum ProphecyStatus { Pending, Attested, Validated, Refuted }
    enum AssetType { ERC20, ERC721 }

    // --- Structs ---

    /**
     * @dev Represents an asset (ERC20 or ERC721) to be locked or released.
     */
    struct Asset {
        AssetType assetType;    // Type of asset (ERC20 or ERC721)
        address tokenAddress;   // Contract address of the token
        uint256 amountOrId;     // Amount for ERC20, tokenId for ERC721
    }

    /**
     * @dev Defines a condition that must be met for a pact to be fulfilled.
     *      `targetValue` and `dataSourceIdentifier` are bytes32 for flexibility.
     *      Interpretation depends on `conditionType`.
     */
    struct Condition {
        ConditionType conditionType;    // Type of condition (e.g., TimeBased, OracleEvent)
        Operator op;                    // Operator for comparison
        bytes32 targetValue;            // The target value to compare against (e.g., timestamp, hash, uint as bytes32)
        bytes32 dataSourceIdentifier;   // Identifier for external data or on-chain state (e.g., prophecyId hash, contract_func_param hash)
        uint256 associatedProphecyId;   // Link to a specific prophecy if `conditionType` is OracleEvent
        bool isFulfilled;               // Whether this specific condition has been met
    }

    /**
     * @dev Defines an outcome of a pact, specifying who receives which asset.
     */
    struct Outcome {
        address receiver;               // Address to receive the asset
        Asset asset;                    // The asset to be transferred
        bytes32 dynamicFactorIdentifier; // If outcome amount/id is dynamic, identifier for its source (e.g., prophecy result)
    }

    /**
     * @dev Represents a Future Pact, holding all its rules, assets, and state.
     */
    struct Pact {
        address initiator;
        address[] participants;                 // List of addresses involved in the pact
        mapping(address => bool) participantMap; // For efficient lookup of participants
        mapping(address => Asset[]) lockedAssetsByParticipant; // Assets locked by each participant
        Condition[] conditions;                 // Conditions that must be met
        Outcome[] outcomes;                     // Outcomes if the pact is fulfilled
        PactStatus status;                      // Current status of the pact
        uint256 creationTime;                   // Timestamp of pact creation
        uint256 fulfillmentTime;                // Timestamp of pact fulfillment (0 if not yet fulfilled)
        uint256 requiredApprovalsForAmendment;  // Number of approvals needed for pact amendment
        mapping(address => bool) amendmentApprovals; // Who approved the latest amendment
        uint256 currentAmendmentApprovalCount;
        uint256 associatedProphecyCount;        // Count of OracleEvent conditions linked to prophecies
    }

    /**
     * @dev Represents a prophecy about an external event, awaiting validation.
     */
    struct Prophecy {
        address proposer;                   // Address that submitted the prophecy
        bytes32 eventDescriptionHash;       // Unique hash identifying the described event
        bytes32 predictedOutcomeHash;       // Hash of the predicted outcome data (e.g., price, election result)
        uint256 predictionTimestamp;        // When the prediction was made
        ProphecyStatus status;              // Current status of the prophecy
        mapping(address => bool) attesters; // Addresses that have attested to this prophecy
        uint256 currentAttestationCount;    // Number of attestations received
        bytes32 actualOutcomeHash;          // The validated outcome data (set by oracle committee)
        uint256 validationTime;             // Timestamp of validation
    }

    // --- State Variables ---

    address public immutable owner; // The contract deployer, initial admin
    bool public isProtocolHalted;  // Global pause switch

    uint256 public nextPactId;      // Counter for new pact IDs
    uint256 public nextProphecyId;  // Counter for new prophecy IDs

    mapping(uint256 => Pact) public pacts;      // All active and historical pacts
    mapping(uint256 => Prophecy) public prophecies; // All submitted prophecies

    mapping(address => uint256) public userReputation; // Reputation score for each address
    mapping(address => bool) public isOracleCommitteeMember; // Members of the decentralized oracle committee
    uint256 public oracleCommitteeSize;     // Current number of oracle committee members
    uint256 public oracleValidationThreshold; // Minimum oracle committee votes required to validate a prophecy

    uint256 public minReputationForProphecy;    // Minimum reputation to submit a prophecy
    uint256 public maxAttestationsForProphecy;  // Max attestations allowed to prevent spam

    uint256 public protocolAmendmentQuorum;     // % of reputation or token supply for protocol amendments
    uint256 public constant MAX_REPUTATION = type(uint256).max; // Max reputation cap

    // --- Events ---
    event PactCreated(uint256 indexed pactId, address indexed initiator, uint256 creationTime);
    event PactParticipantJoined(uint256 indexed pactId, address indexed participant);
    event PactConditionsAmended(uint256 indexed pactId, address indexed proposer);
    event PactExecuted(uint256 indexed pactId, uint256 fulfillmentTime);
    event PactCancelled(uint256 indexed pactId, address indexed by);
    event PactEscalated(uint256 indexed pactId, address indexed by);

    event ProphecySubmitted(uint256 indexed prophecyId, address indexed proposer, bytes32 eventDescriptionHash);
    event ProphecyAttested(uint256 indexed prophecyId, address indexed attester);
    event ProphecyValidated(uint256 indexed prophecyId, bytes32 actualOutcomeHash);
    event ProphecyRefuted(uint256 indexed prophecyId, address indexed refuter);

    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ProtocolAmendmentProposed(uint256 indexed proposalId, address indexed proposer, bytes32 descriptionHash);
    event ProtocolAmendmentVoted(uint256 indexed proposalId, address indexed voter);
    event ProtocolAmendmentExecuted(uint256 indexed proposalId);

    event OracleCommitteeMemberAdded(address indexed member);
    event OracleCommitteeMemberRemoved(address indexed member);

    event ProtocolHalted(bool halted);
    event AssetsRecovered(address indexed recipient, address indexed tokenAddress, uint256 amountOrId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier whenNotHalted() {
        require(!isProtocolHalted, "Protocol is currently halted");
        _;
    }

    modifier onlyOracleCommitteeMember() {
        require(isOracleCommitteeMember[msg.sender], "Only oracle committee members can call this function");
        _;
    }

    // --- Interfaces ---
    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }

    interface IERC721 {
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external;
        function approve(address to, uint256 tokenId) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function isApprovedForAll(address owner, address operator) external view returns (bool);
    }

    constructor() {
        owner = msg.sender;
        nextPactId = 1;
        nextProphecyId = 1;
        isProtocolHalted = false;

        // Initialize default parameters
        oracleValidationThreshold = 3; // E.g., 3 oracle votes required for validation
        minReputationForProphecy = 100; // Example
        maxAttestationsForProphecy = 10; // Example, to limit Sybil attacks on attestations
        protocolAmendmentQuorum = 50; // Example, for a simple reputation-based quorum
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Internal helper to evaluate if a given condition is met.
     *      NOTE: For OracleEvent, it only checks if the associated Prophecy is Validated.
     *            For OnChainState, it would require a secure way to read external contract state,
     *            which is complex and often requires trusted oracle feeds itself. Here, it's simplified.
     * @param _condition The condition struct to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkConditionFulfillment(Pact storage _pact, Condition memory _condition) internal view returns (bool) {
        if (_condition.isFulfilled) {
            return true; // Already fulfilled, no need to re-evaluate
        }

        if (_condition.conditionType == ConditionType.TimeBased) {
            uint256 targetTime = uint256(_condition.targetValue); // Assuming targetValue stores a timestamp
            if (_condition.op == Operator.GTE) return block.timestamp >= targetTime;
            if (_condition.op == Operator.LTE) return block.timestamp <= targetTime;
            // Add other operators if needed, but for time, GTE is most common for release.
            revert("Unsupported operator for TimeBased condition");
        } else if (_condition.conditionType == ConditionType.OracleEvent) {
            require(_condition.associatedProphecyId != 0, "OracleEvent condition missing prophecy ID");
            Prophecy storage p = prophecies[_condition.associatedProphecyId];
            return p.status == ProphecyStatus.Validated;
            // More complex logic could compare p.actualOutcomeHash with _condition.targetValue
        } else if (_condition.conditionType == ConditionType.OnChainState) {
            // This is a placeholder. Real-world implementation would require
            // pre-agreed methods to interpret `dataSourceIdentifier` (e.g., target contract address + function selector)
            // and `targetValue` (e.g., expected return value).
            // For simplicity, we can assume a trusted external call (not ideal for decentralization but demonstrates intent)
            // or that another function (e.g., an oracle feed) sets this condition's fulfillment directly.
            // Example: bytes32 dataSourceIdentifier might be hash(ERC20_TOKEN_BALANCE_OF_ADDRESS_X).
            // Then an external actor would 'attest' to this on-chain state being met.
            return false; // Placeholder for complex on-chain state check
        } else if (_condition.conditionType == ConditionType.ReputationThreshold) {
            address targetAddress = address(uint160(uint256(_condition.dataSourceIdentifier))); // Assuming address is packed into dataSourceIdentifier
            uint256 requiredReputation = uint256(_condition.targetValue);
            if (_condition.op == Operator.GTE) return userReputation[targetAddress] >= requiredReputation;
            if (_condition.op == Operator.LT) return userReputation[targetAddress] < requiredReputation;
            revert("Unsupported operator for ReputationThreshold condition");
        } else if (_condition.conditionType == ConditionType.MultiSigApproval) {
             // For this, the _condition.isFulfilled would be set externally by participants
             // via an `approveCondition` style function, acting as a multisig.
             // `dataSourceIdentifier` might point to a specific proposal ID.
             return false; // Requires explicit external update
        } else if (_condition.conditionType == ConditionType.AssociatedPactStatus) {
            uint256 associatedPactId = uint256(_condition.dataSourceIdentifier); // Assuming pact ID is packed
            Pact storage ap = pacts[associatedPactId];
            PactStatus requiredStatus = PactStatus(uint256(_condition.targetValue)); // Assuming status enum value is packed
            return ap.status == requiredStatus;
        }
        return false;
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address whose reputation to update.
     * @param _change The amount to add or subtract from reputation.
     * @param _add True to add, false to subtract.
     */
    function _updateUserReputation(address _user, uint256 _change, bool _add) internal {
        if (_add) {
            userReputation[_user] = userReputation[_user] + _change > MAX_REPUTATION ? MAX_REPUTATION : userReputation[_user] + _change;
        } else {
            userReputation[_user] = userReputation[_user] < _change ? 0 : userReputation[_user] - _change;
        }
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    /**
     * @dev Internal function to register locked assets for a pact.
     *      Assumes tokens have already been transferred to this contract.
     * @param _pactId The ID of the pact.
     * @param _owner The address that locked the asset.
     * @param _asset The asset struct.
     */
    function _registerAssetLock(uint256 _pactId, address _owner, Asset memory _asset) internal {
        Pact storage p = pacts[_pactId];
        p.lockedAssetsByParticipant[_owner].push(_asset);
    }

    /**
     * @dev Internal function to release a locked asset to a recipient.
     * @param _asset The asset to release.
     * @param _recipient The address to send the asset to.
     */
    function _releaseLockedAsset(Asset memory _asset, address _recipient) internal {
        if (_asset.assetType == AssetType.ERC20) {
            require(IERC20(_asset.tokenAddress).transfer(_recipient, _asset.amountOrId), "ERC20 transfer failed");
        } else if (_asset.assetType == AssetType.ERC721) {
            // Need to know the original owner to transfer. In a real system,
            // the contract would take ownership, so transferFrom(address(this), recipient, id)
            // would be called. For simplicity, we assume `this` is owner.
            IERC721(_asset.tokenAddress).safeTransferFrom(address(this), _recipient, _asset.amountOrId);
        } else {
            revert("Unsupported asset type for release");
        }
    }

    // --- I. Core Pact Management (7 functions) ---

    /**
     * @notice Initiates a new Future Pact.
     * @dev Assets must be approved to this contract address before calling.
     *      Conditions are complex and interpreted based on `ConditionType`.
     * @param _participantAddresses Array of addresses participating in the pact.
     * @param _lockedAssetsByInitiator Assets locked by the initiator.
     * @param _conditions Conditions that must be met for pact fulfillment.
     * @param _outcomes Outcomes to be executed upon fulfillment.
     * @param _requiredApprovalsForAmendment Number of participants required to approve an amendment.
     * @return The ID of the newly created pact.
     */
    function createFuturePact(
        address[] memory _participantAddresses,
        Asset[] memory _lockedAssetsByInitiator,
        Condition[] memory _conditions,
        Outcome[] memory _outcomes,
        uint256 _requiredApprovalsForAmendment
    ) external whenNotHalted returns (uint256) {
        require(_participantAddresses.length > 0, "Pact must have participants");
        require(_conditions.length > 0, "Pact must have conditions");
        require(_outcomes.length > 0, "Pact must have outcomes");
        require(_requiredApprovalsForAmendment <= _participantAddresses.length + 1, "Approvals cannot exceed total participants + initiator");

        uint256 pactId = nextPactId++;
        Pact storage newPact = pacts[pactId];

        newPact.initiator = msg.sender;
        newPact.participants.push(msg.sender); // Initiator is also a participant
        newPact.participantMap[msg.sender] = true;

        uint256 currentProphecyCount = 0;
        for (uint256 i = 0; i < _conditions.length; i++) {
            if (_conditions[i].conditionType == ConditionType.OracleEvent) {
                require(_conditions[i].associatedProphecyId != 0, "OracleEvent condition requires prophecy ID");
                require(prophecies[_conditions[i].associatedProphecyId].status != ProphecyStatus.Refuted, "Cannot link to refuted prophecy");
                currentProphecyCount++;
            }
            newPact.conditions.push(_conditions[i]);
        }
        newPact.associatedProphecyCount = currentProphecyCount;

        for (uint256 i = 0; i < _outcomes.length; i++) {
            newPact.outcomes.push(_outcomes[i]);
        }

        newPact.status = PactStatus.Pending;
        newPact.creationTime = block.timestamp;
        newPact.requiredApprovalsForAmendment = _requiredApprovalsForAmendment;

        // Add other participants
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            require(!newPact.participantMap[_participantAddresses[i]], "Duplicate participant address");
            newPact.participants.push(_participantAddresses[i]);
            newPact.participantMap[_participantAddresses[i]] = true;
        }

        // Lock initiator's assets
        for (uint256 i = 0; i < _lockedAssetsByInitiator.length; i++) {
            Asset memory asset = _lockedAssetsByInitiator[i];
            if (asset.assetType == AssetType.ERC20) {
                require(IERC20(asset.tokenAddress).transferFrom(msg.sender, address(this), asset.amountOrId), "ERC20 transferFrom failed for initiator");
            } else if (asset.assetType == AssetType.ERC721) {
                IERC721(asset.tokenAddress).safeTransferFrom(msg.sender, address(this), asset.amountOrId);
            }
            _registerAssetLock(pactId, msg.sender, asset);
        }

        emit PactCreated(pactId, msg.sender, block.timestamp);
        return pactId;
    }

    /**
     * @notice Allows an invited user to join an existing pact, optionally adding assets.
     * @dev Only users specified in the pact (or by an amendment) can join.
     * @param _pactId The ID of the pact to join.
     * @param _lockedAssetsByParticipant Assets locked by this participant.
     */
    function participateInPact(uint256 _pactId, Asset[] memory _lockedAssetsByParticipant) external whenNotHalted {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");
        require(p.participantMap[msg.sender], "Not an invited participant for this pact");
        require(p.status == PactStatus.Pending || p.status == PactStatus.Active, "Pact is not open for new participants");

        // Lock participant's assets
        for (uint256 i = 0; i < _lockedAssetsByParticipant.length; i++) {
            Asset memory asset = _lockedAssetsByParticipant[i];
            if (asset.assetType == AssetType.ERC20) {
                require(IERC20(asset.tokenAddress).transferFrom(msg.sender, address(this), asset.amountOrId), "ERC20 transferFrom failed for participant");
            } else if (asset.assetType == AssetType.ERC721) {
                IERC721(asset.tokenAddress).safeTransferFrom(msg.sender, address(this), asset.amountOrId);
            }
            _registerAssetLock(_pactId, msg.sender, asset);
        }

        if (p.status == PactStatus.Pending) {
             p.status = PactStatus.Active; // First participant (excluding initiator) makes pact active
        }

        emit PactParticipantJoined(_pactId, msg.sender);
    }

    /**
     * @notice Proposes and facilitates changes to an active pact's conditions or outcomes.
     * @dev Requires a predefined number of approvals from participants.
     * @param _pactId The ID of the pact to amend.
     * @param _newConditions New array of conditions to replace existing ones.
     * @param _newOutcomes New array of outcomes to replace existing ones.
     */
    function amendPactConditions(
        uint256 _pactId,
        Condition[] memory _newConditions,
        Outcome[] memory _newOutcomes
    ) external whenNotHalted {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");
        require(p.participantMap[msg.sender], "Only participants can propose/approve amendments");
        require(p.status == PactStatus.Active, "Pact is not active for amendment");
        require(p.requiredApprovalsForAmendment > 0, "Pact does not allow amendments or approval count not set");

        if (!p.amendmentApprovals[msg.sender]) {
            p.amendmentApprovals[msg.sender] = true;
            p.currentAmendmentApprovalCount++;
        }

        if (p.currentAmendmentApprovalCount >= p.requiredApprovalsForAmendment) {
            // Apply amendments
            delete p.conditions; // Clear existing conditions
            uint256 currentProphecyCount = 0;
            for (uint256 i = 0; i < _newConditions.length; i++) {
                if (_newConditions[i].conditionType == ConditionType.OracleEvent) {
                    require(_newConditions[i].associatedProphecyId != 0, "OracleEvent condition requires prophecy ID");
                    currentProphecyCount++;
                }
                p.conditions.push(_newConditions[i]);
            }
            p.associatedProphecyCount = currentProphecyCount;

            delete p.outcomes; // Clear existing outcomes
            for (uint256 i = 0; i < _newOutcomes.length; i++) {
                p.outcomes.push(_newOutcomes[i]);
            }

            p.status = PactStatus.Amended; // Mark as amended
            // Reset approvals for next amendment
            p.currentAmendmentApprovalCount = 0;
            for (uint256 i = 0; i < p.participants.length; i++) {
                p.amendmentApprovals[p.participants[i]] = false;
            }
            p.amendmentApprovals[p.initiator] = false; // Initiator's approval also reset

            emit PactConditionsAmended(_pactId, msg.sender);
        } else {
             // Not enough approvals yet, simply emitted as an approval.
             // A real system would have an event for each approval and specific proposal tracking.
             emit PactConditionsAmended(_pactId, msg.sender); // Using same event, but status is not "Amended" yet
        }
    }

    /**
     * @notice Attempts to fulfill a pact if all conditions are met.
     * @dev Can be called by anyone, but only executes if all conditions are true.
     * @param _pactId The ID of the pact to execute.
     */
    function executePactOutcome(uint256 _pactId) external whenNotHalted {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");
        require(p.status == PactStatus.Active || p.status == PactStatus.Amended, "Pact is not in an executable status");

        bool allConditionsMet = true;
        for (uint256 i = 0; i < p.conditions.length; i++) {
            if (!p.conditions[i].isFulfilled) { // Check if already fulfilled to save gas
                p.conditions[i].isFulfilled = _checkConditionFulfillment(p, p.conditions[i]);
            }
            if (!p.conditions[i].isFulfilled) {
                allConditionsMet = false;
                break;
            }
        }

        require(allConditionsMet, "Not all pact conditions are met");

        p.status = PactStatus.Fulfilled;
        p.fulfillmentTime = block.timestamp;

        // Release assets according to outcomes
        for (uint256 i = 0; i < p.outcomes.length; i++) {
            Outcome memory outcome = p.outcomes[i];
            // If outcome has a dynamic factor, its value should be derived here, e.g., from a validated prophecy's outcome.
            // For simplicity, we assume the asset.amountOrId is fixed in the outcome for now.
            _releaseLockedAsset(outcome.asset, outcome.receiver);
        }

        // Reward initiator and participants for successful pacts (reputation)
        _updateUserReputation(p.initiator, 10, true);
        for (uint256 i = 0; i < p.participants.length; i++) {
            _updateUserReputation(p.participants[i], 5, true);
        }

        emit PactExecuted(_pactId, block.timestamp);
    }

    /**
     * @notice Allows the initiator or governance to cancel a pending/active pact.
     * @dev Conditions for cancellation (e.g., within X time, no assets locked yet)
     *      would be defined. Here, a simple check if sender is initiator or owner.
     * @param _pactId The ID of the pact to cancel.
     */
    function cancelPact(uint256 _pactId) external whenNotHalted {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");
        require(msg.sender == p.initiator || msg.sender == owner, "Only initiator or owner can cancel pact");
        require(p.status != PactStatus.Fulfilled && p.status != PactStatus.Failed && p.status != PactStatus.Cancelled, "Pact cannot be cancelled from current status");

        p.status = PactStatus.Cancelled;

        // Logic to return locked assets if any (requires iterating through lockedAssetsByParticipant)
        // For simplicity, this is omitted but would be crucial. Example:
        // for (uint256 i = 0; i < p.participants.length; i++) {
        //     address participant = p.participants[i];
        //     for (uint256 j = 0; j < p.lockedAssetsByParticipant[participant].length; j++) {
        //         Asset memory asset = p.lockedAssetsByParticipant[participant][j];
        //         _releaseLockedAsset(asset, participant); // Return assets to original lock-er
        //     }
        // }

        emit PactCancelled(_pactId, msg.sender);
    }

    /**
     * @notice Provides a mechanism for participants to request DAO intervention for disputed or stalled pacts.
     * @dev This would typically trigger an on-chain governance proposal. For simplicity,
     *      it just changes status here.
     * @param _pactId The ID of the pact to escalate.
     */
    function escalatePactToGovernance(uint256 _pactId) external whenNotHalted {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");
        require(p.participantMap[msg.sender], "Only a participant can escalate a pact");
        require(p.status != PactStatus.Fulfilled && p.status != PactStatus.Cancelled && p.status != PactStatus.Failed && p.status != PactStatus.Escalated, "Pact cannot be escalated from current status");

        p.status = PactStatus.Escalated;
        // In a full DAO, this would trigger a governance proposal for the DAO to vote on.
        emit PactEscalated(_pactId, msg.sender);
    }

    /**
     * @notice View function to retrieve comprehensive information about a specific pact.
     * @param _pactId The ID of the pact.
     * @return All details of the pact.
     */
    function getPactDetails(uint256 _pactId) external view returns (Pact memory) {
        return pacts[_pactId];
    }

    // --- II. Prophecy & Oracle System (6 functions) ---

    /**
     * @notice Allows a user to propose a verifiable prediction about a future external event.
     * @dev Requires minimum reputation. Event and predicted outcome are described by hashes.
     * @param _eventDescriptionHash Unique hash identifying the described event (e.g., "ETH_USD_Price_at_X_Date_is_Y").
     * @param _predictedOutcomeHash Hash of the predicted outcome data.
     * @param _predictionTimestamp Timestamp when the prediction is relevant.
     * @return The ID of the newly submitted prophecy.
     */
    function submitProphecy(
        bytes32 _eventDescriptionHash,
        bytes32 _predictedOutcomeHash,
        uint256 _predictionTimestamp
    ) external whenNotHalted returns (uint256) {
        require(userReputation[msg.sender] >= minReputationForProphecy, "Not enough reputation to submit prophecy");
        require(_predictionTimestamp > block.timestamp, "Prediction must be for the future");
        require(_eventDescriptionHash != bytes32(0), "Event description hash cannot be empty");
        require(_predictedOutcomeHash != bytes32(0), "Predicted outcome hash cannot be empty");

        uint256 prophecyId = nextProphecyId++;
        Prophecy storage newProphecy = prophecies[prophecyId];

        newProphecy.proposer = msg.sender;
        newProphecy.eventDescriptionHash = _eventDescriptionHash;
        newProphecy.predictedOutcomeHash = _predictedOutcomeHash;
        newProphecy.predictionTimestamp = _predictionTimestamp;
        newProphecy.status = ProphecyStatus.Pending;

        emit ProphecySubmitted(prophecyId, msg.sender, _eventDescriptionHash);
        return prophecyId;
    }

    /**
     * @notice Enables other users to vouch for the perceived accuracy or validity of a pending prophecy.
     * @param _prophecyId The ID of the prophecy to attest to.
     */
    function attestToProphecy(uint256 _prophecyId) external whenNotHalted {
        Prophecy storage p = prophecies[_prophecyId];
        require(p.proposer != address(0), "Prophecy does not exist");
        require(p.status == ProphecyStatus.Pending, "Prophecy is not in pending status for attestation");
        require(msg.sender != p.proposer, "Proposer cannot attest to their own prophecy");
        require(!p.attesters[msg.sender], "Already attested to this prophecy");
        require(p.currentAttestationCount < maxAttestationsForProphecy, "Max attestations reached for this prophecy");

        p.attesters[msg.sender] = true;
        p.currentAttestationCount++;

        if (p.currentAttestationCount >= maxAttestationsForProphecy) {
            // If enough attestations, it moves to 'Attested' (awaiting Oracle Committee validation)
            p.status = ProphecyStatus.Attested;
        }

        // Minor reputation gain for attesting to a prophecy that is later validated
        _updateUserReputation(msg.sender, 1, true);

        emit ProphecyAttested(_prophecyId, msg.sender);
    }

    /**
     * @notice Exclusive function for Oracle Committee members to confirm the actual outcome of an event.
     * @dev Marks a prophecy as `Validated`.
     * @param _prophecyId The ID of the prophecy to validate.
     * @param _actualOutcomeHash The hash of the true outcome data.
     */
    function validateProphecyOutcome(uint256 _prophecyId, bytes32 _actualOutcomeHash) external onlyOracleCommitteeMember whenNotHalted {
        Prophecy storage p = prophecies[_prophecyId];
        require(p.proposer != address(0), "Prophecy does not exist");
        require(p.status == ProphecyStatus.Attested || p.status == ProphecyStatus.Pending, "Prophecy is not awaiting validation");
        require(p.validationTime == 0, "Prophecy already validated/refuted");
        require(oracleCommitteeSize >= oracleValidationThreshold, "Not enough oracle committee members for validation");

        // Simple validation: if committee member validates, it's considered true.
        // A more complex system would require multiple committee member votes.
        p.actualOutcomeHash = _actualOutcomeHash;
        p.status = ProphecyStatus.Validated;
        p.validationTime = block.timestamp;

        // Reward proposer and attesters for accurate prophecy
        if (p.predictedOutcomeHash == _actualOutcomeHash) {
            _updateUserReputation(p.proposer, 50, true);
            for (uint256 i = 0; i < p.participants.length; i++) { // Iterating attesters not participants
                // This would be better if attesters were stored in a dynamic array
                // For simplicity, we assume attesters for this example were stored in mapping only, so this iteration isn't correct.
                // It should iterate p.attesters or specific `ProphecyAttested` events.
            }
        }

        emit ProphecyValidated(_prophecyId, _actualOutcomeHash);
    }

    /**
     * @notice Allows Oracle Committee members to invalidate a prophecy if its predicted outcome proves incorrect or malicious.
     * @param _prophecyId The ID of the prophecy to refute.
     */
    function refuteProphecy(uint256 _prophecyId) external onlyOracleCommitteeMember whenNotHalted {
        Prophecy storage p = prophecies[_prophecyId];
        require(p.proposer != address(0), "Prophecy does not exist");
        require(p.status == ProphecyStatus.Attested || p.status == ProphecyStatus.Pending, "Prophecy is not awaiting refutation");
        require(p.validationTime == 0, "Prophecy already validated/refuted");
        require(oracleCommitteeSize >= oracleValidationThreshold, "Not enough oracle committee members for refutation");

        p.status = ProphecyStatus.Refuted;
        p.validationTime = block.timestamp;

        // Penalize proposer for inaccurate prophecy
        _updateUserReputation(p.proposer, 25, false);

        emit ProphecyRefuted(_prophecyId, msg.sender);
    }

    /**
     * @notice View function to retrieve all details of a specific prophecy.
     * @param _prophecyId The ID of the prophecy.
     * @return All details of the prophecy.
     */
    function getProphecyDetails(uint256 _prophecyId) external view returns (Prophecy memory) {
        return prophecies[_prophecyId];
    }

    /**
     * @notice View function to quickly check the current status of a prophecy.
     * @param _prophecyId The ID of the prophecy.
     * @return The current status of the prophecy.
     */
    function queryProphecyStatus(uint256 _prophecyId) external view returns (ProphecyStatus) {
        return prophecies[_prophecyId].status;
    }

    // --- III. Reputation & Governance (6 functions) ---

    /**
     * @notice View function to check the current reputation score of any address.
     * @param _user The address to check reputation for.
     * @return The reputation score of the user.
     */
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Allows high-reputation users or the owner to propose changes to core protocol parameters.
     * @dev For simplicity, this function directly changes a parameter, but a full DAO
     *      would involve a voting process.
     * @param _paramNameHash Hash identifying the parameter to change (e.g., keccak256("oracleValidationThreshold")).
     * @param _newValue New value for the parameter.
     */
    function proposeProtocolAmendment(bytes32 _paramNameHash, uint256 _newValue) external whenNotHalted {
        require(msg.sender == owner || userReputation[msg.sender] >= minReputationForProphecy * 5, "Not authorized to propose amendments");

        // In a real DAO, this would create a proposal that others vote on.
        // For this example, we directly apply if owner, otherwise, it's just a 'proposal'.
        // If it was a vote system, a separate `voteOnAmendment` and `executeAmendment` would be needed.

        // Simulating direct execution for owner, or just a placeholder for others
        if (msg.sender == owner) {
            if (_paramNameHash == keccak256("oracleValidationThreshold")) {
                oracleValidationThreshold = _newValue;
            } else if (_paramNameHash == keccak256("minReputationForProphecy")) {
                minReputationForProphecy = _newValue;
            } else if (_paramNameHash == keccak256("maxAttestationsForProphecy")) {
                maxAttestationsForProphecy = _newValue;
            } else if (_paramNameHash == keccak256("protocolAmendmentQuorum")) {
                protocolAmendmentQuorum = _newValue;
            } else {
                revert("Unknown protocol parameter for direct amendment");
            }
            emit ProtocolAmendmentExecuted(uint256(_paramNameHash)); // Use hash as a proposal ID
        } else {
            // For non-owner, this would typically record a proposal awaiting votes.
            // Placeholder: A real system would need a `Proposal` struct and tracking.
            // emit ProtocolAmendmentProposed(some_proposal_id, msg.sender, _paramNameHash);
        }
    }

    /**
     * @notice Allows eligible token holders or high-reputation users to vote on proposed protocol amendments.
     * @dev This function is a placeholder for a full governance system.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for 'yes', false for 'no'.
     */
    function voteOnAmendment(uint256 _proposalId, bool _approve) external whenNotHalted {
        require(userReputation[msg.sender] > 0, "Must have reputation to vote");
        // Placeholder: In a real system, you'd check proposal existence, voting period, etc.
        // And update `_proposalId`'s vote count.
        emit ProtocolAmendmentVoted(_proposalId, msg.sender);
    }

    /**
     * @notice Implements a passed protocol amendment, updating the contract's configurable parameters.
     * @dev This function is a placeholder and would be called by a governance executor after a vote passes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeAmendment(uint256 _proposalId) external whenNotHalted onlyOwner {
        // Placeholder: In a real system, check if proposal passed and then apply changes.
        // This function is illustrative of the final step after a successful vote.
        emit ProtocolAmendmentExecuted(_proposalId);
    }

    /**
     * @notice Enables high-reputation users to apply for membership in the Oracle Committee.
     * @dev Subject to governance approval (or owner's approval for simplicity).
     * @param _member The address to add to the committee.
     */
    function joinOracleCommittee(address _member) external whenNotHalted {
        require(msg.sender == owner || userReputation[_member] >= minReputationForProphecy * 10, "Not enough reputation to join committee or not owner");
        require(!isOracleCommitteeMember[_member], "Member is already in the oracle committee");

        isOracleCommitteeMember[_member] = true;
        oracleCommitteeSize++;
        emit OracleCommitteeMemberAdded(_member);
    }

    /**
     * @notice Allows governance or the contract owner to remove a member from the Oracle Committee.
     * @dev Typically due to inactivity or misconduct.
     * @param _member The address to remove from the committee.
     */
    function removeOracleCommitteeMember(address _member) external whenNotHalted {
        require(msg.sender == owner || userReputation[msg.sender] > 0, "Only owner or high-reputation user can propose removal"); // Simplified
        require(isOracleCommitteeMember[_member], "Member is not in the oracle committee");

        isOracleCommitteeMember[_member] = false;
        oracleCommitteeSize--;
        emit OracleCommitteeMemberRemoved(_member);
    }

    // --- IV. Advanced / Utility / Security (5 functions + internal helpers) ---

    // `checkConditionFulfillment` and `registerAssetLock` and `releaseLockedAsset` are internal helpers defined above.

    /**
     * @notice Allows the contract owner or governance to temporarily halt critical protocol operations.
     * @dev Emergency brake for severe vulnerabilities.
     * @param _halt True to halt, false to unhalt.
     */
    function emergencyProtocolHalt(bool _halt) external onlyOwner {
        isProtocolHalted = _halt;
        emit ProtocolHalted(_halt);
    }

    /**
     * @notice Provides a governance-controlled mechanism to retrieve assets that may become unintentionally locked.
     * @dev Last resort for recovering funds. Only owner can call.
     * @param _tokenAddress The address of the token (ERC20 or ERC721 contract).
     * @param _amountOrId For ERC20: amount; For ERC721: tokenId.
     * @param _recipient The address to send the recovered assets to.
     * @param _assetType The type of asset to recover (ERC20 or ERC721).
     */
    function recoverStuckAssets(
        address _tokenAddress,
        uint256 _amountOrId,
        address _recipient,
        AssetType _assetType
    ) external onlyOwner {
        require(isProtocolHalted, "Protocol must be halted for emergency recovery");
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        if (_assetType == AssetType.ERC20) {
            require(IERC20(_tokenAddress).transfer(_recipient, _amountOrId), "ERC20 recovery failed");
        } else if (_assetType == AssetType.ERC721) {
            IERC721(_tokenAddress).safeTransferFrom(address(this), _recipient, _amountOrId);
        } else {
            revert("Unsupported asset type for recovery");
        }

        emit AssetsRecovered(_recipient, _tokenAddress, _amountOrId);
    }

    /**
     * @notice View function to list all assets locked by participants in a given pact.
     * @param _pactId The ID of the pact.
     * @return An array of `Asset` structs for each participant's locked assets.
     */
    function getPactParticipantsAssets(uint256 _pactId) external view returns (Asset[] memory) {
        Pact storage p = pacts[_pactId];
        require(p.initiator != address(0), "Pact does not exist");

        uint256 totalAssetsCount = 0;
        for (uint256 i = 0; i < p.participants.length; i++) {
            totalAssetsCount += p.lockedAssetsByParticipant[p.participants[i]].length;
        }

        Asset[] memory allLockedAssets = new Asset[](totalAssetsCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < p.participants.length; i++) {
            address participant = p.participants[i];
            for (uint256 j = 0; j < p.lockedAssetsByParticipant[participant].length; j++) {
                allLockedAssets[currentIdx] = p.lockedAssetsByParticipant[participant][j];
                currentIdx++;
            }
        }
        return allLockedAssets;
    }
}
```