Here's a smart contract in Solidity called "Aetherius," designed to be an advanced, creative, and trendy platform for decentralized AI insights, knowledge orchestration, and reputation management. It avoids duplicating existing open-source projects by combining several concepts like decentralized AI agent coordination, on-chain verifiable claims, dynamic reputation, and a basic knowledge graph, all within a governed ecosystem.

---

### **Aetherius - Decentralized AI Consensus & Knowledge Oracle Network**

**Concept:**
Aetherius establishes a decentralized platform for AI-powered insights, data validation, and knowledge orchestration. It connects 'Insight Oracles' (AI agents or data providers) with 'Query Requesters' (users/dApps seeking insights), all governed by a community-driven reputation and dispute system. The contract primarily manages the lifecycle, reputation, and coordination of these off-chain AI services, abstracting complex AI operations into verifiable on-chain claims and consensus mechanisms, rather than running AI computations directly on-chain.

---

### **Contract Outline:**

1.  **Core Data Structures:** Defines structs for `InsightOracle`, `InsightQuery`, `InsightDispute`, and `KnowledgeNode` to organize on-chain data.
2.  **State Variables:** Mappings to store instances of the core data structures, global counters for unique IDs, and critical protocol parameters.
3.  **Events:** Emitted to provide off-chain listeners with updates on significant state changes within the contract.
4.  **Custom Errors:** For robust and gas-efficient error handling.
5.  **Modifiers:** Access control and common validation checks.
6.  **Admin & Governance Functions:** (AetheriusDAO Operations): Functions controlled by the `daoAdmin` or an evolving governance mechanism to manage protocol parameters and roles.
7.  **Oracle Management Functions:** Functions allowing AI agents (Oracles) to register, manage their profiles, stake collateral, and manage their lifecycle.
8.  **Query & Insight Functions:** For users to request AI insights and for Oracles to accept, submit, and claim rewards for fulfilling these queries.
9.  **Reputation & Dispute Functions:** The core mechanism for maintaining trust, allowing participants to dispute incorrect insights, validators to vote, and disputes to be resolved, impacting Oracle reputation and stake.
10. **Knowledge Graph Functions:** Enables Oracles to contribute structured, verifiable pieces of information to build an on-chain knowledge graph.
11. **Utility & View Functions:** Read-only functions to query the state of the contract and retrieve information about Oracles, Queries, Disputes, and Knowledge Nodes.

---

### **Function Summary (25 Functions):**

**A. Admin & Governance (AetheriusDAO Operations)**

1.  `constructor(address _initialDaoAdmin)`: Initializes the contract, setting the initial address that can manage core protocol parameters and roles.
2.  `setProtocolParameter(bytes32 _paramName, uint256 _value)`: Allows the DAO admin to adjust key network parameters like minimum stake, cooldown periods, or dispute fees.
3.  `assignValidatorRole(address _newValidator)`: Grants an address the privilege to act as a validator in the dispute resolution process.
4.  `revokeValidatorRole(address _validator)`: Revokes validator privileges from an address.
5.  `withdrawProtocolFees(address _recipient, uint256 _amount)`: Allows the DAO admin to withdraw accumulated protocol fees (e.g., from dispute fees) to a specified address.

**B. Oracle Management**

6.  `registerInsightOracle(string memory _name, string memory _description, string memory _externalAIModelRef) payable`: Registers a new AI agent/data provider as an `InsightOracle`. Requires an initial ETH stake to ensure commitment and accountability. Mints a unique Oracle ID.
7.  `updateOracleProfile(uint256 _oracleId, string memory _newDescription, string memory _newExternalRef)`: Allows an oracle owner to update their registered profile metadata, such as a new description or an updated reference to their off-chain AI model.
8.  `stakeCollateral(uint256 _oracleId) payable`: Allows an oracle owner to add more ETH collateral to their existing stake, increasing their security deposit and potential trust score.
9.  `initiateUnstake(uint256 _oracleId, uint256 _amount)`: Initiates the process of unstaking collateral. Funds are locked for a predefined cooldown period to prevent flash withdrawals.
10. `completeUnstake(uint256 _oracleId)`: Completes the unstaking process after the cooldown period has elapsed, releasing the requested funds back to the oracle owner.
11. `deregisterInsightOracle(uint256 _oracleId)`: Allows an oracle to gracefully exit the network. This might involve a final stake lockup or a reputation check.

**C. Query & Insight Provision**

12. `requestInsightQuery(string memory _queryTopic, uint256 _rewardAmount, uint256 _deadline) payable`: A user or dApp initiates a request for an AI insight. They specify the topic, commit a reward amount, and set a deadline for fulfillment.
13. `acceptQuery(uint256 _queryId, uint256 _oracleId)`: An registered `InsightOracle` commits to fulfilling a specific insight query, signaling their intention to the network.
14. `submitInsightResult(uint256 _queryId, bytes32 _insightHash, string memory _dataRef, bytes memory _verifiableProof)`: An Oracle submits the hash of their computed insight, a reference to the off-chain data (e.g., IPFS link), and a placeholder for an abstract "verifiable proof" (e.g., a ZKP attestation, Merkle proof, or other computational integrity proof).
15. `claimQueryReward(uint256 _queryId)`: The Oracle claims the committed reward for a successfully submitted and validated insight. This function will check if the insight has passed any implicit or explicit validation.

**D. Reputation & Dispute System**

16. `disputeInsight(uint256 _queryId, uint256 _oracleId, string memory _reason) payable`: Any network participant can raise a formal dispute against an oracle's submitted insight if they believe it's inaccurate or fraudulent. Requires a dispute fee.
17. `voteOnInsightQuality(uint256 _disputeId, bool _isAccurate)`: Registered `validator` roles can vote on the accuracy of a disputed insight. This function records their verdict.
18. `resolveDispute(uint256 _disputeId)`: The DAO admin or a designated entity triggers the final resolution of a dispute based on validator votes. This function updates the involved oracle's reputation and potentially slashes or refunds their stake/dispute fees.
19. `updateOracleReputation(uint256 _oracleId, int256 _reputationChange)`: An internal or DAO-callable function to programmatically adjust an oracle's reputation score, typically as a result of dispute resolutions or successful query fulfillments.

**E. Knowledge Graph Contribution**

20. `registerKnowledgeNode(uint256 _oracleId, string memory _nodeTitle, string memory _nodeContentHash, uint256 _parentNodeId)`: Allows an Oracle to contribute a verifiable piece of structured knowledge to the network. This node can optionally be linked to a `parentNodeId`, effectively building a decentralized, on-chain knowledge graph where insights can be connected and contextualized.

**F. Utility & View Functions**

21. `getOracleDetails(uint256 _oracleId) view`: Retrieves all public details about a specific `InsightOracle` including its profile, current stake, and status.
22. `getOracleReputation(uint256 _oracleId) view`: Returns the current reputation score of an `InsightOracle`.
23. `getQueryDetails(uint256 _queryId) view`: Retrieves comprehensive details about an `InsightQuery`, including its topic, reward, deadline, and current status.
24. `getDisputeDetails(uint256 _disputeId) view`: Retrieves all information pertaining to a specific dispute, including its status, involved parties, and reasons.
25. `getKnowledgeNodeDetails(uint256 _nodeId) view`: Retrieves detailed information about a specific knowledge node registered on the network, including its content hash and parent linkages.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // For initial DAO admin ownership

/**
 * @title Aetherius - Decentralized AI Consensus & Knowledge Oracle Network
 * @author YourName (simulated by AI)
 * @notice This smart contract establishes "Aetherius," a decentralized platform for AI-powered insights,
 *         data validation, and knowledge orchestration. It connects 'Insight Oracles' (AI agents or
 *         data providers) with 'Query Requesters' (users/dApps seeking insights), governed by a
 *         community-driven reputation and dispute system. The contract primarily manages the lifecycle,
 *         reputation, and coordination of these off-chain AI services, abstracting complex AI
 *         operations into verifiable on-chain claims and consensus mechanisms.
 *
 * @dev This contract uses basic ETH transfers for payments. In a production environment,
 *      an ERC-20 token would likely be used for more flexible economic models.
 *      The "verifiable proof" (bytes memory _verifiableProof) is an abstract placeholder
 *      for off-chain zero-knowledge proofs, attestations, or other computational integrity checks.
 *      Actual on-chain verification of complex ZKPs requires precompiles or specialized libraries
 *      not fully implemented here.
 */
contract Aetherius is Ownable {

    // --- Enums ---
    enum OracleStatus { Active, Inactive, Deregistered, Suspended }
    enum QueryStatus { Open, Accepted, Fulfilled, Disputed, Resolved, Expired }
    enum DisputeStatus { Open, Voting, ResolvedAccurate, ResolvedInaccurate }

    // --- Core Data Structures ---

    /**
     * @dev Represents an Insight Oracle (AI agent or data provider).
     * @param id Unique identifier for the oracle.
     * @param owner The Ethereum address that controls this oracle.
     * @param name User-friendly name for the oracle.
     * @param description A brief description of the oracle's capabilities or purpose.
     * @param externalAIModelRef A reference (e.g., IPFS hash, URL) to the off-chain AI model or service.
     * @param stake Current amount of collateral (ETH) staked by the oracle.
     * @param reputation Reputation score; higher is better. Can be negative.
     * @param status Current operational status of the oracle.
     * @param lastUnstakeRequestTimestamp Timestamp of the last unstake initiation.
     */
    struct InsightOracle {
        uint256 id;
        address owner;
        string name;
        string description;
        string externalAIModelRef;
        uint256 stake;
        int256 reputation; // Can be positive or negative
        OracleStatus status;
        uint256 lastUnstakeRequestTimestamp;
        uint256 unstakeAmountRequested;
    }

    /**
     * @dev Represents a request for an AI insight.
     * @param id Unique identifier for the query.
     * @param requester The address that initiated the query.
     * @param topic A description or prompt for the AI insight requested.
     * @param rewardAmount Amount of ETH offered as a reward for a correct insight.
     * @param deadline Timestamp by which the insight must be submitted.
     * @param fulfilledByOracleId The ID of the oracle that accepted and fulfilled this query.
     * @param insightHash Keccak256 hash of the submitted insight data.
     * @param dataRef Reference (e.g., IPFS hash) to the off-chain insight data.
     * @param status Current status of the query.
     * @param isDisputed True if the insight associated with this query is currently under dispute.
     */
    struct InsightQuery {
        uint256 id;
        address requester;
        string topic;
        uint256 rewardAmount;
        uint256 deadline;
        uint256 fulfilledByOracleId; // 0 if not yet fulfilled
        bytes32 insightHash; // Hash of the actual insight result
        string dataRef; // e.g., IPFS hash to the actual data
        QueryStatus status;
        bool isDisputed;
    }

    /**
     * @dev Represents a dispute initiated against an oracle's submitted insight.
     * @param id Unique identifier for the dispute.
     * @param queryId The ID of the query whose insight is being disputed.
     * @param challengedOracleId The ID of the oracle whose insight is challenged.
     * @param disputer The address that initiated the dispute.
     * @param reason A brief description of the reason for the dispute.
     * @param status Current status of the dispute.
     * @param totalVotesFor Total votes indicating accuracy.
     * @param totalVotesAgainst Total votes indicating inaccuracy.
     * @param hasBeenResolved True if the dispute has been finalized.
     * @param disputeFeeAmount The fee paid by the disputer.
     */
    struct InsightDispute {
        uint256 id;
        uint256 queryId;
        uint256 challengedOracleId;
        address disputer;
        string reason;
        DisputeStatus status;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
        bool hasBeenResolved;
        uint256 disputeFeeAmount;
    }

    /**
     * @dev Represents a verifiable piece of knowledge contributed by an Oracle, forming a graph.
     * @param id Unique identifier for the knowledge node.
     * @param creatorOracleId The ID of the oracle that contributed this knowledge.
     * @param title A title for the knowledge node.
     * @param contentHash Keccak256 hash of the knowledge content.
     * @param contentRef Reference (e.g., IPFS hash) to the off-chain knowledge content.
     * @param parentNodeId Optional: ID of a parent knowledge node, for graph structure (0 if root).
     * @param timestamp When the node was registered.
     */
    struct KnowledgeNode {
        uint256 id;
        uint256 creatorOracleId;
        string title;
        bytes32 contentHash;
        string contentRef;
        uint256 parentNodeId; // 0 if no parent
        uint256 timestamp;
    }

    // --- State Variables ---
    uint256 public nextOracleId;
    uint256 public nextQueryId;
    uint256 public nextDisputeId;
    uint256 public nextKnowledgeNodeId;

    mapping(uint256 => InsightOracle) public insightOracles;
    mapping(address => uint256) public oracleOwnerToId; // Map owner address to their primary oracle ID
    mapping(uint256 => InsightQuery) public insightQueries;
    mapping(uint256 => InsightDispute) public insightDisputes;
    mapping(uint256 => KnowledgeNode) public knowledgeNodes;

    mapping(bytes32 => uint256) public protocolParameters; // bytes32 for parameter name, uint256 for value
    mapping(address => bool) public isValidator; // Tracks addresses with validator role

    address public daoAdmin; // The address authorized to set protocol parameters and assign roles

    // --- Events ---
    event OracleRegistered(uint256 indexed oracleId, address indexed owner, string name, uint256 initialStake);
    event OracleProfileUpdated(uint256 indexed oracleId, string newDescription, string newExternalRef);
    event OracleStakeUpdated(uint256 indexed oracleId, uint256 newStake, bool isDeposit);
    event OracleUnstakeInitiated(uint256 indexed oracleId, uint256 amount, uint256 cooldownEnds);
    event OracleUnstakeCompleted(uint256 indexed oracleId, uint256 amount);
    event OracleDeregistered(uint256 indexed oracleId, address indexed owner);

    event QueryRequested(uint256 indexed queryId, address indexed requester, string topic, uint256 rewardAmount, uint256 deadline);
    event QueryAccepted(uint256 indexed queryId, uint256 indexed oracleId);
    event InsightResultSubmitted(uint256 indexed queryId, uint256 indexed oracleId, bytes32 insightHash, string dataRef);
    event QueryRewardClaimed(uint256 indexed queryId, uint256 indexed oracleId, uint256 rewardAmount);

    event InsightDisputed(uint256 indexed disputeId, uint256 indexed queryId, uint256 indexed challengedOracleId, address disputer, uint256 disputeFee);
    event ValidatorVoted(uint256 indexed disputeId, address indexed validator, bool isAccurate);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed queryId, DisputeStatus newStatus, int256 reputationChange, uint256 fundsMoved);

    event OracleReputationUpdated(uint256 indexed oracleId, int256 newReputation);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ValidatorRoleAssigned(address indexed newValidator);
    event ValidatorRoleRevoked(address indexed validator);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    event KnowledgeNodeRegistered(uint256 indexed nodeId, uint256 indexed creatorOracleId, bytes32 contentHash, uint256 parentNodeId);

    // --- Custom Errors ---
    error AlreadyRegistered();
    error OracleNotFound();
    error NotOracleOwner();
    error InvalidOracleStatus();
    error InsufficientStake(uint256 required, uint256 current);
    error InvalidAmount();
    error UnstakeCooldownActive(uint256 cooldownRemaining);
    error UnstakeAmountMismatch();
    error NotEnoughStakeToUnstake();

    error QueryNotFound();
    error QueryAlreadyAccepted();
    error QueryNotAcceptedByOracle();
    error QueryAlreadyFulfilled();
    error QueryExpired();
    error QueryNotFulfilled();
    error QueryNotReadyForClaim();
    error QueryCurrentlyDisputed();

    error InvalidProof(); // Placeholder for complex proof validation errors
    error NotAuthorized(); // Generic authorization error
    error OnlyValidator(); // Specific authorization error for validators
    error OnlyDisputerOrOracleInvolved(); // Specific authorization for dispute actions

    error DisputeNotFound();
    error DisputeAlreadyResolved();
    error DisputeNotOpenForVoting();
    error AlreadyVotedInDispute();

    error InvalidParameterName();
    error ParentKnowledgeNodeNotFound();

    // --- Modifiers ---
    modifier onlyOracleOwner(uint256 _oracleId) {
        if (insightOracles[_oracleId].owner != msg.sender) revert NotOracleOwner();
        _;
    }

    modifier onlyDaoAdmin() {
        if (msg.sender != daoAdmin) revert NotAuthorized();
        _;
    }

    modifier onlyValidator() {
        if (!isValidator[msg.sender]) revert OnlyValidator();
        _;
    }

    // --- Constructor ---
    constructor(address _initialDaoAdmin) Ownable(msg.sender) { // Ownable is inherited from OpenZeppelin, for _owner and transferOwnership
        daoAdmin = _initialDaoAdmin;

        // Initialize default protocol parameters (can be changed by DAO)
        protocolParameters[bytes32("MIN_ORACLE_STAKE")] = 1 ether; // Minimum ETH stake to register an oracle
        protocolParameters[bytes32("UNSTAKE_COOLDOWN_PERIOD")] = 7 days; // Cooldown period for unstaking
        protocolParameters[bytes32("DISPUTE_FEE")] = 0.1 ether; // Fee to initiate a dispute
        protocolParameters[bytes32("REPUTATION_FOR_ACCURATE_INSIGHT")] = 10; // Reputation points for correct insight
        protocolParameters[bytes32("REPUTATION_FOR_INACCURATE_INSIGHT")] = -50; // Reputation points for incorrect insight
        protocolParameters[bytes32("DISPUTE_RESOLUTION_QUORUM")] = 3; // Minimum votes needed to resolve a dispute
    }

    // --- A. Admin & Governance (AetheriusDAO Operations) ---

    /**
     * @notice Allows the DAO admin to adjust core network parameters.
     * @dev Examples: "MIN_ORACLE_STAKE", "UNSTAKE_COOLDOWN_PERIOD", "DISPUTE_FEE".
     *      Only the DAO admin can call this function.
     * @param _paramName The name of the parameter to set (bytes32 for gas efficiency).
     * @param _value The new value for the parameter.
     */
    function setProtocolParameter(bytes32 _paramName, uint256 _value) public onlyDaoAdmin {
        if (_paramName == bytes32(0)) revert InvalidParameterName();
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterUpdated(_paramName, _value);
    }

    /**
     * @notice Grants an address the privilege to act as a validator in disputes.
     * @dev Only the DAO admin can call this function.
     * @param _newValidator The address to grant validator role.
     */
    function assignValidatorRole(address _newValidator) public onlyDaoAdmin {
        isValidator[_newValidator] = true;
        emit ValidatorRoleAssigned(_newValidator);
    }

    /**
     * @notice Revokes validator privileges from an address.
     * @dev Only the DAO admin can call this function.
     * @param _validator The address to revoke validator role from.
     */
    function revokeValidatorRole(address _validator) public onlyDaoAdmin {
        isValidator[_validator] = false;
        emit ValidatorRoleRevoked(_validator);
    }

    /**
     * @notice Allows the DAO admin to withdraw accumulated protocol fees.
     * @dev Fees collected (e.g., from dispute fees) are held in the contract balance.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawProtocolFees(address _recipient, uint256 _amount) public onlyDaoAdmin {
        if (_amount == 0) revert InvalidAmount();
        if (address(this).balance < _amount) revert InvalidAmount(); // More specific error could be made
        (bool success,) = payable(_recipient).call{value: _amount}("");
        if (!success) revert NotAuthorized(); // Generic failure, could be more specific
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- B. Oracle Management ---

    /**
     * @notice Registers a new AI agent/data provider as an InsightOracle.
     * @dev Requires an initial ETH stake (`msg.value`) to ensure commitment and accountability.
     *      Each `msg.sender` can only register one oracle.
     * @param _name User-friendly name for the oracle.
     * @param _description A brief description of the oracle's capabilities or purpose.
     * @param _externalAIModelRef A reference (e.g., IPFS hash, URL) to the off-chain AI model or service.
     */
    function registerInsightOracle(
        string memory _name,
        string memory _description,
        string memory _externalAIModelRef
    ) public payable {
        if (oracleOwnerToId[msg.sender] != 0) revert AlreadyRegistered();
        if (msg.value < protocolParameters[bytes32("MIN_ORACLE_STAKE")]) {
            revert InsufficientStake(protocolParameters[bytes32("MIN_ORACLE_STAKE")], msg.value);
        }

        uint256 oracleId = ++nextOracleId;
        insightOracles[oracleId] = InsightOracle({
            id: oracleId,
            owner: msg.sender,
            name: _name,
            description: _description,
            externalAIModelRef: _externalAIModelRef,
            stake: msg.value,
            reputation: 0, // Starting reputation
            status: OracleStatus.Active,
            lastUnstakeRequestTimestamp: 0,
            unstakeAmountRequested: 0
        });
        oracleOwnerToId[msg.sender] = oracleId;
        emit OracleRegistered(oracleId, msg.sender, _name, msg.value);
    }

    /**
     * @notice Allows an oracle owner to update their profile metadata.
     * @param _oracleId The ID of the oracle to update.
     * @param _newDescription The new description for the oracle.
     * @param _newExternalRef The new external reference for the AI model/service.
     */
    function updateOracleProfile(
        uint256 _oracleId,
        string memory _newDescription,
        string memory _newExternalRef
    ) public onlyOracleOwner(_oracleId) {
        InsightOracle storage oracle = insightOracles[_oracleId];
        oracle.description = _newDescription;
        oracle.externalAIModelRef = _newExternalRef;
        emit OracleProfileUpdated(_oracleId, _newDescription, _newExternalRef);
    }

    /**
     * @notice Allows an oracle owner to add more ETH collateral to their existing stake.
     * @param _oracleId The ID of the oracle to add stake to.
     */
    function stakeCollateral(uint256 _oracleId) public payable onlyOracleOwner(_oracleId) {
        if (msg.value == 0) revert InvalidAmount();
        insightOracles[_oracleId].stake += msg.value;
        emit OracleStakeUpdated(_oracleId, insightOracles[_oracleId].stake, true);
    }

    /**
     * @notice Initiates the process of unstaking collateral.
     * @dev Funds are locked for a predefined cooldown period.
     * @param _oracleId The ID of the oracle.
     * @param _amount The amount of ETH to initiate unstake for.
     */
    function initiateUnstake(uint256 _oracleId, uint256 _amount) public onlyOracleOwner(_oracleId) {
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.stake < _amount) revert NotEnoughStakeToUnstake();
        if (_amount == 0) revert InvalidAmount();

        oracle.lastUnstakeRequestTimestamp = block.timestamp;
        oracle.unstakeAmountRequested = _amount;
        // Optionally, enforce minimum stake remaining.
        if (oracle.stake - _amount < protocolParameters[bytes32("MIN_ORACLE_STAKE")] && oracle.stake - _amount != 0) {
            revert InsufficientStake(protocolParameters[bytes32("MIN_ORACLE_STAKE")], oracle.stake - _amount);
        }

        emit OracleUnstakeInitiated(_oracleId, _amount, block.timestamp + protocolParameters[bytes32("UNSTAKE_COOLDOWN_PERIOD")]);
    }

    /**
     * @notice Completes the unstaking process after the cooldown period has elapsed.
     * @param _oracleId The ID of the oracle.
     */
    function completeUnstake(uint256 _oracleId) public onlyOracleOwner(_oracleId) {
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.lastUnstakeRequestTimestamp == 0) revert UnstakeAmountMismatch(); // No unstake initiated

        uint256 cooldownEnds = oracle.lastUnstakeRequestTimestamp + protocolParameters[bytes32("UNSTAKE_COOLDOWN_PERIOD")];
        if (block.timestamp < cooldownEnds) {
            revert UnstakeCooldownActive(cooldownEnds - block.timestamp);
        }

        uint256 amountToUnstake = oracle.unstakeAmountRequested;
        if (oracle.stake < amountToUnstake) revert NotEnoughStakeToUnstake(); // Should not happen if initiateUnstake checks
        
        oracle.stake -= amountToUnstake;
        oracle.lastUnstakeRequestTimestamp = 0; // Reset for next unstake
        oracle.unstakeAmountRequested = 0;

        (bool success,) = payable(oracle.owner).call{value: amountToUnstake}("");
        if (!success) revert NotAuthorized(); // Generic failure, can add more specific
        emit OracleUnstakeCompleted(_oracleId, amountToUnstake);
        emit OracleStakeUpdated(_oracleId, oracle.stake, false);
    }

    /**
     * @notice Allows an oracle to gracefully exit the network.
     * @dev This will refund their remaining stake after a cooldown/lockup period.
     *      May require resolving all active queries/disputes first.
     * @param _oracleId The ID of the oracle to deregister.
     */
    function deregisterInsightOracle(uint256 _oracleId) public onlyOracleOwner(_oracleId) {
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.status == OracleStatus.Deregistered) revert InvalidOracleStatus();

        // Implement checks: no active queries, no active disputes, final cooldown
        // For simplicity, we just change status and refund remaining stake immediately (can be improved)
        uint256 remainingStake = oracle.stake;
        oracle.status = OracleStatus.Deregistered;
        oracle.stake = 0;
        
        // Remove from lookup to allow owner to register new oracle or prevent further use
        delete oracleOwnerTo[oracle.owner];

        if (remainingStake > 0) {
            (bool success,) = payable(oracle.owner).call{value: remainingStake}("");
            if (!success) revert NotAuthorized(); // Failed to send ETH
            emit OracleStakeUpdated(_oracleId, 0, false);
        }
        emit OracleDeregistered(_oracleId, oracle.owner);
    }

    // --- C. Query & Insight Provision ---

    /**
     * @notice A user/dApp requests an AI insight.
     * @param _queryTopic A descriptive topic or prompt for the AI insight.
     * @param _rewardAmount The amount of ETH to pay the oracle for fulfilling the query.
     * @param _deadline The timestamp by which the insight must be submitted.
     */
    function requestInsightQuery(
        string memory _queryTopic,
        uint256 _rewardAmount,
        uint256 _deadline
    ) public payable {
        if (msg.value < _rewardAmount) revert InvalidAmount(); // Not enough ETH sent for reward
        if (_deadline <= block.timestamp) revert QueryExpired();

        uint256 queryId = ++nextQueryId;
        insightQueries[queryId] = InsightQuery({
            id: queryId,
            requester: msg.sender,
            topic: _queryTopic,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            fulfilledByOracleId: 0,
            insightHash: bytes32(0),
            dataRef: "",
            status: QueryStatus.Open,
            isDisputed: false
        });
        emit QueryRequested(queryId, msg.sender, _queryTopic, _rewardAmount, _deadline);
    }

    /**
     * @notice An registered Oracle commits to fulfilling a specific insight query.
     * @dev Only an active oracle can accept an open, unexpired query.
     * @param _queryId The ID of the query to accept.
     * @param _oracleId The ID of the oracle accepting the query.
     */
    function acceptQuery(uint256 _queryId, uint256 _oracleId) public onlyOracleOwner(_oracleId) {
        InsightQuery storage query = insightQueries[_queryId];
        if (query.id == 0) revert QueryNotFound();
        if (query.status != QueryStatus.Open) revert QueryAlreadyAccepted();
        if (query.deadline <= block.timestamp) revert QueryExpired();
        if (insightOracles[_oracleId].status != OracleStatus.Active) revert InvalidOracleStatus();

        query.fulfilledByOracleId = _oracleId;
        query.status = QueryStatus.Accepted;
        emit QueryAccepted(_queryId, _oracleId);
    }

    /**
     * @notice Oracle submits the hash of the computed insight, a reference to off-chain data,
     *         and a placeholder for a verifiable proof.
     * @dev The proof could be a ZKP, Merkle proof, or attestation from a trusted party.
     * @param _queryId The ID of the query being fulfilled.
     * @param _insightHash The Keccak256 hash of the off-chain insight data.
     * @param _dataRef A reference (e.g., IPFS hash) to the off-chain insight data.
     * @param _verifiableProof Abstract bytes for a computational integrity proof.
     */
    function submitInsightResult(
        uint256 _queryId,
        bytes32 _insightHash,
        string memory _dataRef,
        bytes memory _verifiableProof // Placeholder for ZKP, Merkle proof, attestation
    ) public {
        InsightQuery storage query = insightQueries[_queryId];
        if (query.id == 0) revert QueryNotFound();
        if (query.fulfilledByOracleId != oracleOwnerToId[msg.sender]) revert QueryNotAcceptedByOracle();
        if (query.status != QueryStatus.Accepted) revert QueryAlreadyFulfilled();
        if (query.deadline <= block.timestamp) revert QueryExpired();
        if (_insightHash == bytes32(0)) revert InvalidProof(); // Or more specific error

        // @dev Add actual (complex) verification logic for _verifiableProof here.
        // For example:
        // if (!VerifierContract.verifyProof(_verifiableProof, _insightHash, ...)) revert InvalidProof();

        query.insightHash = _insightHash;
        query.dataRef = _dataRef;
        query.status = QueryStatus.Fulfilled;
        emit InsightResultSubmitted(_queryId, query.fulfilledByOracleId, _insightHash, _dataRef);
    }

    /**
     * @notice The Oracle claims the reward for a successfully submitted and validated insight.
     * @dev This implies the insight has not been disputed or a dispute was resolved in their favor.
     * @param _queryId The ID of the query whose reward is to be claimed.
     */
    function claimQueryReward(uint256 _queryId) public {
        InsightQuery storage query = insightQueries[_queryId];
        if (query.id == 0) revert QueryNotFound();
        if (query.fulfilledByOracleId != oracleOwnerToId[msg.sender]) revert QueryNotAcceptedByOracle();
        if (query.status != QueryStatus.Fulfilled) revert QueryNotReadyForClaim();
        if (query.isDisputed) revert QueryCurrentlyDisputed();

        // In a more complex system, there might be a waiting period or explicit validation step
        // before claim is allowed, to give time for disputes. For simplicity, we assume
        // 'Fulfilled' status means it's ready unless disputed.

        query.status = QueryStatus.Resolved; // Mark as resolved after claim
        uint256 reward = query.rewardAmount;
        
        InsightOracle storage oracle = insightOracles[query.fulfilledByOracleId];
        oracle.reputation += int256(protocolParameters[bytes32("REPUTATION_FOR_ACCURATE_INSIGHT")]);
        emit OracleReputationUpdated(oracle.id, oracle.reputation);

        (bool success,) = payable(msg.sender).call{value: reward}("");
        if (!success) revert NotAuthorized(); // Failed to send ETH
        emit QueryRewardClaimed(_queryId, query.fulfilledByOracleId, reward);
    }

    // --- D. Reputation & Dispute System ---

    /**
     * @notice Any network participant can raise a formal dispute against an oracle's submitted insight.
     * @dev Requires a dispute fee, which is held in the contract.
     * @param _queryId The ID of the query whose insight is being disputed.
     * @param _oracleId The ID of the oracle whose insight is challenged.
     * @param _reason A brief description of the reason for the dispute.
     */
    function disputeInsight(
        uint256 _queryId,
        uint256 _oracleId,
        string memory _reason
    ) public payable {
        InsightQuery storage query = insightQueries[_queryId];
        if (query.id == 0) revert QueryNotFound();
        if (query.status != QueryStatus.Fulfilled) revert InsightNotSubmitted();
        if (query.isDisputed) revert QueryCurrentlyDisputed();
        if (query.fulfilledByOracleId != _oracleId) revert QueryNotAcceptedByOracle(); // Ensure correct oracle is disputed
        if (msg.value < protocolParameters[bytes32("DISPUTE_FEE")]) revert InsufficientStake(protocolParameters[bytes32("DISPUTE_FEE")], msg.value);

        query.isDisputed = true;
        query.status = QueryStatus.Disputed;

        uint256 disputeId = ++nextDisputeId;
        insightDisputes[disputeId] = InsightDispute({
            id: disputeId,
            queryId: _queryId,
            challengedOracleId: _oracleId,
            disputer: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasBeenResolved: false,
            disputeFeeAmount: msg.value
        });

        emit InsightDisputed(disputeId, _queryId, _oracleId, msg.sender, msg.value);
    }

    /**
     * @notice Registered validators vote on the accuracy of a disputed insight.
     * @param _disputeId The ID of the dispute.
     * @param _isAccurate True if the validator believes the insight is accurate, false otherwise.
     */
    function voteOnInsightQuality(uint256 _disputeId, bool _isAccurate) public onlyValidator {
        InsightDispute storage dispute = insightDisputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert DisputeNotOpenForVoting();
        if (dispute.hasVoted[msg.sender]) revert AlreadyVotedInDispute();

        dispute.hasVoted[msg.sender] = true;
        if (_isAccurate) {
            dispute.totalVotesFor++;
        } else {
            dispute.totalVotesAgainst++;
        }

        emit ValidatorVoted(_disputeId, msg.sender, _isAccurate);
    }

    /**
     * @notice The DAO admin triggers the resolution of a dispute based on validator votes.
     * @dev Impacts the oracle's reputation and redistributes stakes/fees.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) public onlyDaoAdmin {
        InsightDispute storage dispute = insightDisputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound();
        if (dispute.hasBeenResolved) revert DisputeAlreadyResolved();
        
        uint256 totalVotes = dispute.totalVotesFor + dispute.totalVotesAgainst;
        if (totalVotes < protocolParameters[bytes32("DISPUTE_RESOLUTION_QUORUM")]) {
            revert NotReadyForResolution(); // Custom error: Not enough votes to resolve
        }

        InsightOracle storage challengedOracle = insightOracles[dispute.challengedOracleId];
        InsightQuery storage query = insightQueries[dispute.queryId];

        int256 reputationChange;
        uint256 fundsToDistribute = dispute.disputeFeeAmount + query.rewardAmount; // Reward is also at stake

        if (dispute.totalVotesFor > dispute.totalVotesAgainst) {
            // Oracle wins: insight is accurate
            dispute.status = DisputeStatus.ResolvedAccurate;
            reputationChange = int256(protocolParameters[bytes32("REPUTATION_FOR_ACCURATE_INSIGHT")]);
            
            // Oracle gets reward + their own stake back (if applicable, not slashed)
            // Disputer's fee is lost to protocol fees (or burned/distributed)
            (bool success,) = payable(challengedOracle.owner).call{value: query.rewardAmount}("");
            if (!success) revert NotAuthorized(); // Failed to send ETH
            
        } else {
            // Oracle loses: insight is inaccurate
            dispute.status = DisputeStatus.ResolvedInaccurate;
            reputationChange = int256(protocolParameters[bytes32("REPUTATION_FOR_INACCURATE_INSIGHT")]);
            
            // Oracle's stake might be slashed (e.g., query.rewardAmount or more)
            uint256 slashAmount = query.rewardAmount; // Or a larger configurable amount
            if (challengedOracle.stake < slashAmount) slashAmount = challengedOracle.stake; // Slash all if not enough
            
            challengedOracle.stake -= slashAmount;
            
            // Disputer gets their fee back + a bonus (e.g., from slashed stake or reward)
            (bool success,) = payable(dispute.disputer).call{value: dispute.disputeFeeAmount + slashAmount}("");
            if (!success) revert NotAuthorized(); // Failed to send ETH
        }

        challengedOracle.reputation += reputationChange;
        dispute.hasBeenResolved = true;
        query.isDisputed = false;
        query.status = (dispute.status == DisputeStatus.ResolvedAccurate) ? QueryStatus.Resolved : QueryStatus.Expired; // Or a new status for failed queries

        emit OracleReputationUpdated(challengedOracle.id, challengedOracle.reputation);
        emit DisputeResolved(_disputeId, dispute.queryId, dispute.status, reputationChange, fundsToDistribute);
    }

    /**
     * @notice Internal/DAO function to adjust an oracle's reputation score.
     * @dev Used after dispute resolution or other network events.
     * @param _oracleId The ID of the oracle whose reputation to update.
     * @param _reputationChange The amount to add to (positive) or subtract from (negative) reputation.
     */
    function updateOracleReputation(uint256 _oracleId, int256 _reputationChange) public onlyDaoAdmin {
        // Can be called directly by DAO for special adjustments
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.id == 0) revert OracleNotFound();
        oracle.reputation += _reputationChange;
        emit OracleReputationUpdated(_oracleId, oracle.reputation);
    }

    // --- E. Knowledge Graph Contribution ---

    /**
     * @notice Allows an oracle to contribute a verifiable piece of knowledge to the network.
     * @dev This node can optionally be linked to a parentNodeId, building an on-chain knowledge graph.
     * @param _oracleId The ID of the oracle contributing the knowledge.
     * @param _nodeTitle A title for the knowledge node.
     * @param _nodeContentHash Keccak256 hash of the off-chain knowledge content.
     * @param _nodeContentRef Reference (e.g., IPFS hash) to the off-chain knowledge content.
     * @param _parentNodeId Optional: ID of a parent knowledge node (0 if it's a root node).
     */
    function registerKnowledgeNode(
        uint256 _oracleId,
        string memory _nodeTitle,
        bytes32 _nodeContentHash,
        string memory _nodeContentRef,
        uint256 _parentNodeId
    ) public onlyOracleOwner(_oracleId) {
        if (_nodeContentHash == bytes32(0)) revert InvalidProof(); // Content hash must be provided

        if (_parentNodeId != 0 && knowledgeNodes[_parentNodeId].id == 0) {
            revert ParentKnowledgeNodeNotFound();
        }

        uint256 nodeId = ++nextKnowledgeNodeId;
        knowledgeNodes[nodeId] = KnowledgeNode({
            id: nodeId,
            creatorOracleId: _oracleId,
            title: _nodeTitle,
            contentHash: _nodeContentHash,
            contentRef: _nodeContentRef,
            parentNodeId: _parentNodeId,
            timestamp: block.timestamp
        });

        emit KnowledgeNodeRegistered(nodeId, _oracleId, _nodeContentHash, _parentNodeId);
    }

    // --- F. Utility & View Functions ---

    /**
     * @notice Retrieves detailed information about a specific Insight Oracle.
     * @param _oracleId The ID of the oracle.
     * @return Tuple containing oracle ID, owner, name, description, external AI model reference,
     *         stake, reputation, and status.
     */
    function getOracleDetails(uint256 _oracleId)
        public view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory description,
            string memory externalAIModelRef,
            uint256 stake,
            int256 reputation,
            OracleStatus status
        )
    {
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.id == 0) revert OracleNotFound();
        return (
            oracle.id,
            oracle.owner,
            oracle.name,
            oracle.description,
            oracle.externalAIModelRef,
            oracle.stake,
            oracle.reputation,
            oracle.status
        );
    }

    /**
     * @notice Returns the current reputation score of an oracle.
     * @param _oracleId The ID of the oracle.
     * @return The oracle's reputation score.
     */
    function getOracleReputation(uint256 _oracleId) public view returns (int256) {
        InsightOracle storage oracle = insightOracles[_oracleId];
        if (oracle.id == 0) revert OracleNotFound();
        return oracle.reputation;
    }

    /**
     * @notice Retrieves detailed information about an insight query.
     * @param _queryId The ID of the query.
     * @return Tuple containing query ID, requester, topic, reward amount, deadline,
     *         fulfilling oracle ID, insight hash, data reference, status, and dispute status.
     */
    function getQueryDetails(uint256 _queryId)
        public view
        returns (
            uint256 id,
            address requester,
            string memory topic,
            uint256 rewardAmount,
            uint256 deadline,
            uint256 fulfilledByOracleId,
            bytes32 insightHash,
            string memory dataRef,
            QueryStatus status,
            bool isDisputed
        )
    {
        InsightQuery storage query = insightQueries[_queryId];
        if (query.id == 0) revert QueryNotFound();
        return (
            query.id,
            query.requester,
            query.topic,
            query.rewardAmount,
            query.deadline,
            query.fulfilledByOracleId,
            query.insightHash,
            query.dataRef,
            query.status,
            query.isDisputed
        );
    }

    /**
     * @notice Retrieves details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Tuple containing dispute ID, query ID, challenged oracle ID, disputer,
     *         reason, status, total votes for, total votes against, and resolution status.
     */
    function getDisputeDetails(uint256 _disputeId)
        public view
        returns (
            uint256 id,
            uint256 queryId,
            uint256 challengedOracleId,
            address disputer,
            string memory reason,
            DisputeStatus status,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            bool hasBeenResolved
        )
    {
        InsightDispute storage dispute = insightDisputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound();
        return (
            dispute.id,
            dispute.queryId,
            dispute.challengedOracleId,
            dispute.disputer,
            dispute.reason,
            dispute.status,
            dispute.totalVotesFor,
            dispute.totalVotesAgainst,
            dispute.hasBeenResolved
        );
    }

    /**
     * @notice Retrieves details of a specific knowledge node.
     * @param _nodeId The ID of the knowledge node.
     * @return Tuple containing node ID, creator oracle ID, title, content hash,
     *         content reference, parent node ID, and timestamp.
     */
    function getKnowledgeNodeDetails(uint256 _nodeId)
        public view
        returns (
            uint256 id,
            uint256 creatorOracleId,
            string memory title,
            bytes32 contentHash,
            string memory contentRef,
            uint256 parentNodeId,
            uint256 timestamp
        )
    {
        KnowledgeNode storage node = knowledgeNodes[_nodeId];
        if (node.id == 0) revert KnowledgeNodeNotFound(); // Custom error for knowledge node
        return (
            node.id,
            node.creatorOracleId,
            node.title,
            node.contentHash,
            node.contentRef,
            node.parentNodeId,
            node.timestamp
        );
    }
}

// Custom error for KnowledgeNodeNotFound (added after initial thought process)
error KnowledgeNodeNotFound();
error NotReadyForResolution(); // Custom error for resolveDispute when quorum not met
```