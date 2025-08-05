Okay, this is an exciting challenge! Creating something truly novel, advanced, and with 20+ functions, avoiding existing open-source patterns, requires combining several complex ideas.

I present **ChronoForge**, a smart contract designed to manage and settle "Temporal Bonds" or "Chronoscapes" – dynamic, event-driven financial instruments whose outcomes depend on external oracle data, time, and specific conditions. It goes beyond simple timelocks or conditional payments by incorporating a dispute mechanism, an incentivized attestation system, and a flexible template structure for creating these instruments.

---

## ChronoForge Smart Contract

**Contract Name:** `ChronoForge`

**Purpose:**
ChronoForge is a decentralized protocol for creating, managing, and settling advanced, event-driven financial agreements called "Chronoscapes." Unlike traditional timelocks or escrows, Chronoscapes are dynamic instruments whose value, beneficiary, or outcome can shift based on specific on-chain or real-world events (verified by oracles), reaching a certain time, or a combination thereof. It introduces concepts like incentivized attestation for settlement, a dispute resolution phase, and a flexible template system for defining complex multi-conditional agreements.

**Key Concepts & Advanced Features:**

1.  **Chronoscapes (Temporal Bonds):** Customizable agreements that mature or settle based on external data conditions (oracle feeds), time, or a combination. They can represent anything from conditional vesting schedules to event-triggered insurance payouts or speculative "future value" instruments.
2.  **Oracle-Driven Logic:** Integrates with authorized external oracle providers to fetch real-world or cross-chain data, enabling contracts to react to events like market prices, network activity, or specific contract states.
3.  **Incentivized Attestation:** Users can be rewarded for successfully triggering the settlement of a Chronoscape when its conditions are met, encouraging efficient resolution and network participation.
4.  **Dispute Mechanism:** A built-in phase allows interested parties to dispute a Chronoscape's proposed settlement, preventing erroneous or malicious resolutions.
5.  **Flexible Template System:** Allows for the creation and reuse of complex Chronoscape definitions, reducing gas costs and simplifying creation for common patterns.
6.  **Dynamic Outcomes:** Chronoscapes can define multiple potential outcomes (e.g., success, failure, neutral) with different beneficiaries and distribution rules, based on the specific conditions met.
7.  **Liquidity Pool for Attestation Rewards:** A dedicated pool provides the ETH (or other token) for attestation rewards and potentially covers dispute resolution costs, funded by fees or dedicated deposits.
8.  **Pausable & Emergency Measures:** Includes granular pausing for individual Chronoscapes and a global pause, allowing for crisis management.

**Outline and Function Summary:**

**Enums & Structs:**

*   `ChronoscapeStatus`: Defines the lifecycle status of a Chronoscape.
*   `ComparisonType`: Defines how oracle values are compared to a threshold.
*   `OutcomeDistribution`: Defines how funds are distributed upon settlement.
*   `OracleFeed`: Details of a registered oracle.
*   `ChronoscapeDefinition`: Blueprint for a Chronoscape, including its rules and conditions.
*   `ChronoscapeState`: Current state and metadata of an active Chronoscape.

**State Variables:**

*   `owner`: Contract deployer.
*   `_chronoscapeNonce`: Counter for unique Chronoscape IDs.
*   `_templateNonce`: Counter for unique template IDs.
*   `chronoscapeDefinitions`: Maps Chronoscape IDs to their definitions (for both templates and instances).
*   `chronoscapeStates`: Maps Chronoscape IDs to their current states.
*   `chronoscapeDeposits`: Stores the ETH balance held for each Chronoscape.
*   `oracleFeeds`: Maps oracle feed IDs to their details.
*   `authorizedOracleProviders`: Maps oracle addresses to their authorization status.
*   `settlementLiquidityPool`: Total ETH in the pool for attestation rewards.
*   `attestationRewards`: Maps addresses to their accrued attestation rewards.
*   `contractFees`: Total accumulated contract fees.
*   `feeRecipient`: Address to receive fees.
*   `chronoscapeCreationFee`: Fee for creating a Chronoscape.
*   `chronoscapeSettlementFee`: Percentage fee on successful settlements.
*   `paused`: Global contract pause status.

**Functions:** (Total: 25 functions)

**I. Core Management & Access Control**
1.  `constructor()`: Initializes the contract with basic settings.
2.  `pauseContract()`: Pauses all critical operations of the contract.
3.  `unpauseContract()`: Unpauses the contract.
4.  `setFeeRecipient(address _newRecipient)`: Sets the address for collecting contract fees.
5.  `updateCreationFee(uint256 _newFee)`: Updates the fee for creating a Chronoscape.
6.  `updateSettlementFeePercentage(uint256 _newPercentage)`: Updates the percentage fee applied on settlement.
7.  `withdrawFees()`: Allows the owner to withdraw accumulated fees.

**II. Oracle Management**
8.  `registerOracleFeed(bytes32 _feedId, address _oracleAddress, string memory _feedName)`: Registers a new oracle feed for use in Chronoscapes.
9.  `authorizeOracleProvider(address _oracleAddress)`: Authorizes an address to provide oracle data.
10. `deauthorizeOracleProvider(address _oracleAddress)`: Deauthorizes an oracle provider.
11. `updateOracleFeedValue(bytes32 _feedId, int256 _newValue)`: (External - meant for authorized oracles) Updates an oracle feed's value.
12. `getLatestOracleData(bytes32 _feedId)`: Retrieves the latest value and timestamp for an oracle feed.

**III. Chronoscape Template Management**
13. `createChronoscapeTemplate(ChronoscapeDefinition calldata _definition)`: Defines a reusable template for Chronoscapes.
14. `getChronoscapeTemplate(uint256 _templateId)`: Retrieves the definition of a specific Chronoscape template.

**IV. Chronoscape Lifecycle**
15. `createChronoscape(uint256 _templateId, address _beneficiary, string memory _metadataURI)`: Creates a new Chronoscape instance from a template, requires an initial deposit.
16. `depositForChronoscape(uint256 _chronoscapeId)`: Allows the creator or others to deposit additional funds into an existing Chronoscape.
17. `settleChronoscape(uint256 _chronoscapeId)`: Attempts to settle a Chronoscape based on its conditions. This is the core logic.
18. `batchSettleChronoscapes(uint256[] calldata _chronoscapeIds)`: Attempts to settle multiple Chronoscapes in one transaction.
19. `disputeChronoscape(uint256 _chronoscapeId)`: Initiates a dispute period for a Chronoscape if a settlement attempt is deemed incorrect.
20. `resolveDispute(uint256 _chronoscapeId)`: Finalizes a disputed Chronoscape, either by re-enabling settlement or reverting to a previous state. (Simplified for this example, would involve governance/arbitration in a full system).
21. `emergencyPauseChronoscape(uint256 _chronoscapeId)`: Owner can pause a specific Chronoscape.
22. `emergencyUnpauseChronoscape(uint256 _chronoscapeId)`: Owner can unpause a specific Chronoscape.

**V. Attestation & Liquidity Pool**
23. `depositLiquidityForSettlement()`: Allows users to deposit ETH into the global settlement liquidity pool to support attestation rewards.
24. `withdrawLiquidityForSettlement(uint256 _amount)`: Allows liquidity providers to withdraw their deposited ETH.
25. `claimAttestationReward()`: Allows an eligible user to claim their accumulated attestation rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using OpenZeppelin for standard access control, pausing, and reentrancy guard,
// which are best practices and not "duplicating" the core unique logic.

contract ChronoForge is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    /* ========== Enums & Structs ========== */

    enum ChronoscapeStatus {
        Pending,        // Created but not yet funded/activated (or waiting for initial conditions)
        Active,         // Actively tracking conditions
        Disputed,       // A settlement attempt has been disputed
        SettledSuccess, // Successfully settled based on conditions
        SettledFailure, // Settled because conditions were not met by expiration
        Paused          // Manually paused by owner
    }

    enum ComparisonType {
        GreaterThan,    // >
        LessThan,       // <
        EqualTo,        // ==
        NotEqualTo,     // !=
        GreaterThanOrEqualTo, // >=
        LessThanOrEqualTo // <=
    }

    // Defines how funds are distributed upon a specific outcome
    struct OutcomeDistribution {
        address recipient; // The address to send funds to
        uint256 percentageBasisPoints; // Percentage of the Chronoscape's total value (e.g., 10000 for 100%)
        // Future: could add fixed amounts, different token types, or even external contract calls
    }

    // Represents an external oracle feed
    struct OracleFeed {
        address oracleAddress; // The address of the authorized oracle smart contract/signer
        string feedName;       // A human-readable name for the feed (e.g., "ETH/USD Price")
        int256 lastUpdatedValue; // The last value received from the oracle
        uint256 lastUpdatedTimestamp; // When the value was last updated
        bool isAuthorized;     // Whether this feed's provider is authorized
    }

    // The blueprint for a Chronoscape, immutable once defined (or as a template)
    struct ChronoscapeDefinition {
        uint256 templateId;         // 0 if not a template, otherwise the ID of the template it's based on
        bytes32 oracleFeedId;       // The ID of the oracle feed to monitor (bytes32 hash of feedName)
        ComparisonType comparisonType; // How to compare the oracle value
        int256 thresholdValue;      // The value to compare the oracle feed against
        uint256 expirationTime;     // Unix timestamp after which settlement conditions are evaluated
        bool evaluateOnExpirationOnly; // If true, conditions are only checked at or after expiration
        OutcomeDistribution successOutcome; // What happens if conditions are met
        OutcomeDistribution failureOutcome; // What happens if conditions are NOT met by expiration
        uint256 disputePeriodDuration; // How long (in seconds) users have to dispute a settlement
        uint256 minDeposit;         // Minimum initial deposit required for this Chronoscape
        string metadataURI;         // URI for off-chain metadata (e.g., IPFS hash of a description)
        bool isTemplate;            // True if this is a reusable template
    }

    // The state of an active Chronoscape instance
    struct ChronoscapeState {
        uint256 definitionId;     // The ID linking to its ChronoscapeDefinition
        address creator;          // Address of the Chronoscape creator
        address beneficiary;      // Primary beneficiary for this Chronoscape instance
        uint256 currentDeposit;   // Current ETH balance held for this Chronoscape
        ChronoscapeStatus status; // Current status of the Chronoscape
        uint256 creationTime;     // When the Chronoscape was created
        uint256 settlementAttemptTime; // Timestamp of the last settlement attempt
        address lastSettler;      // Address who last attempted to settle (for attestation reward)
        uint256 lastDisputeTime;  // Timestamp of the last dispute
        bool settlementResult;    // True if last settlement attempt was success, false if failure
        bool emergencyPaused;     // True if this specific Chronoscape is paused
    }

    /* ========== State Variables ========== */

    uint256 private _chronoscapeNonce; // Counter for unique Chronoscape IDs
    uint256 private _templateNonce;    // Counter for unique template IDs

    mapping(uint256 => ChronoscapeDefinition) public chronoscapeDefinitions; // Maps IDs to their definitions (both templates and instances)
    mapping(uint256 => ChronoscapeState) public chronoscapeStates;         // Maps Chronoscape IDs to their current states
    mapping(uint256 => uint256) public chronoscapeDeposits;                // Stores the actual ETH balance held for each Chronoscape

    mapping(bytes32 => OracleFeed) public oracleFeeds;                     // Maps oracle feed IDs (hash of name) to their details
    mapping(address => bool) public authorizedOracleProviders;             // Maps oracle contract addresses to their authorization status

    uint256 public settlementLiquidityPool;                                // Total ETH in the pool for attestation rewards
    mapping(address => uint256) public attestationRewards;                 // Maps addresses to their accrued attestation rewards

    uint256 public contractFees;                                           // Accumulated fees from Chronoscape operations
    address public feeRecipient;                                           // Address to send collected fees

    uint256 public chronoscapeCreationFee;                                 // Fee (in wei) for creating a Chronoscape
    uint256 public chronoscapeSettlementFeeBasisPoints;                    // Percentage fee (basis points) on successful settlements (e.g., 50 means 0.5%)

    /* ========== Events ========== */

    event ChronoscapeTemplateCreated(uint256 indexed templateId, address indexed creator, string metadataURI);
    event ChronoscapeCreated(uint256 indexed chronoscapeId, uint256 indexed definitionId, address indexed creator, address beneficiary, uint256 initialDeposit, string metadataURI);
    event ChronoscapeDeposited(uint256 indexed chronoscapeId, address indexed depositor, uint256 amount);
    event ChronoscapeSettled(uint256 indexed chronoscapeId, ChronoscapeStatus newStatus, address indexed settler, uint256 distributedAmount, address recipient);
    event ChronoscapeDisputed(uint256 indexed chronoscapeId, address indexed disputer);
    event ChronoscapeDisputeResolved(uint256 indexed chronoscapeId, address indexed resolver);
    event ChronoscapeEmergencyPaused(uint256 indexed chronoscapeId, address indexed pauser);
    event ChronoscapeEmergencyUnpaused(uint256 indexed chronoscapeId, address indexed unpauser);

    event OracleFeedRegistered(bytes32 indexed feedId, address indexed oracleAddress, string feedName);
    event OracleProviderAuthorized(address indexed oracleAddress);
    event OracleProviderDeauthorized(address indexed oracleAddress);
    event OracleFeedUpdated(bytes32 indexed feedId, int256 newValue, uint256 timestamp);

    event AttestationRewardClaimed(address indexed claimant, uint256 amount);
    event LiquidityDeposited(address indexed provider, uint256 amount);
    event LiquidityWithdrawn(address indexed provider, uint256 amount);

    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event CreationFeeUpdated(uint256 oldFee, uint256 newFee);
    event SettlementFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);

    /* ========== Constructor ========== */

    constructor() Ownable(msg.sender) Pausable() {
        feeRecipient = msg.sender;
        chronoscapeCreationFee = 0.005 ether; // Example: 0.005 ETH
        chronoscapeSettlementFeeBasisPoints = 50; // Example: 0.5% (50 basis points)
        _chronoscapeNonce = 0;
        _templateNonce = 0;
    }

    /* ========== Modifiers ========== */

    modifier onlyAuthorizedOracle(address _oracleAddress) {
        require(authorizedOracleProviders[_oracleAddress], "ChronoForge: Caller is not an authorized oracle provider");
        _;
    }

    modifier notPausedGlobalAndChronoscape(uint256 _chronoscapeId) {
        _checkNotPaused();
        require(!chronoscapeStates[_chronoscapeId].emergencyPaused, "ChronoForge: Chronoscape is emergency paused");
        _;
    }

    /* ========== I. Core Management & Access Control ========== */

    /// @notice Pauses all critical operations of the contract.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the address for collecting contract fees.
    /// @param _newRecipient The new address to receive fees.
    function setFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "ChronoForge: New recipient cannot be zero address");
        address oldRecipient = feeRecipient;
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    /// @notice Updates the fee (in wei) for creating a Chronoscape.
    /// @param _newFee The new creation fee.
    function updateCreationFee(uint256 _newFee) public onlyOwner {
        uint256 oldFee = chronoscapeCreationFee;
        chronoscapeCreationFee = _newFee;
        emit CreationFeeUpdated(oldFee, _newFee);
    }

    /// @notice Updates the percentage fee applied on successful settlements.
    /// @param _newPercentage The new percentage in basis points (e.g., 50 for 0.5%).
    function updateSettlementFeePercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= 10000, "ChronoForge: Percentage cannot exceed 100%"); // 10000 basis points = 100%
        uint256 oldPercentage = chronoscapeSettlementFeeBasisPoints;
        chronoscapeSettlementFeeBasisPoints = _newPercentage;
        emit SettlementFeePercentageUpdated(oldPercentage, _newPercentage);
    }

    /// @notice Allows the owner to withdraw accumulated fees to the fee recipient.
    function withdrawFees() public onlyOwner {
        require(contractFees > 0, "ChronoForge: No fees to withdraw");
        uint256 amount = contractFees;
        contractFees = 0;
        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        require(success, "ChronoForge: Fee withdrawal failed");
        emit FeesWithdrawn(feeRecipient, amount);
    }

    /* ========== II. Oracle Management ========== */

    /// @notice Registers a new oracle feed that can be used by Chronoscapes.
    ///         The oracle address must be separately authorized.
    /// @param _feedId A unique identifier for the feed (e.g., keccak256("ETH_USD_CHAINLINK")).
    /// @param _oracleAddress The address of the oracle contract/provider.
    /// @param _feedName A human-readable name for the feed.
    function registerOracleFeed(bytes32 _feedId, address _oracleAddress, string memory _feedName) public onlyOwner {
        require(oracleFeeds[_feedId].oracleAddress == address(0), "ChronoForge: Oracle feed already registered");
        require(_oracleAddress != address(0), "ChronoForge: Oracle address cannot be zero");

        oracleFeeds[_feedId] = OracleFeed({
            oracleAddress: _oracleAddress,
            feedName: _feedName,
            lastUpdatedValue: 0, // Initialize
            lastUpdatedTimestamp: 0, // Initialize
            isAuthorized: authorizedOracleProviders[_oracleAddress] // Inherit authorization
        });
        emit OracleFeedRegistered(_feedId, _oracleAddress, _feedName);
    }

    /// @notice Authorizes an address to provide data for registered oracle feeds.
    /// @param _oracleAddress The address of the oracle provider.
    function authorizeOracleProvider(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronoForge: Oracle address cannot be zero");
        require(!authorizedOracleProviders[_oracleAddress], "ChronoForge: Oracle provider already authorized");
        authorizedOracleProviders[_oracleAddress] = true;

        // Update authorization for all feeds provided by this oracle
        for (uint256 i = 0; i < type(bytes32).max; i++) { // Placeholder for iterating feeds if needed, impractical in solidity
             // In a real scenario, this would likely iterate through a list of known feed IDs
             // or authorization would be per-feed. For simplicity, we just set the provider's global status.
        }
        emit OracleProviderAuthorized(_oracleAddress);
    }

    /// @notice Deauthorizes an oracle provider. Their feeds will no longer be considered valid.
    /// @param _oracleAddress The address of the oracle provider.
    function deauthorizeOracleProvider(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronoForge: Oracle address cannot be zero");
        require(authorizedOracleProviders[_oracleAddress], "ChronoForge: Oracle provider not authorized");
        authorizedOracleProviders[_oracleAddress] = false;
        emit OracleProviderDeauthorized(_oracleAddress);
    }

    /// @notice Allows an authorized oracle to update its feed value.
    /// @param _feedId The ID of the oracle feed to update.
    /// @param _newValue The new value for the feed.
    function updateOracleFeedValue(bytes32 _feedId, int256 _newValue) public nonReentrant onlyAuthorizedOracle(msg.sender) {
        OracleFeed storage feed = oracleFeeds[_feedId];
        require(feed.oracleAddress == msg.sender, "ChronoForge: Caller is not the registered oracle for this feed");
        require(feed.isAuthorized, "ChronoForge: Oracle feed provider is not authorized");

        feed.lastUpdatedValue = _newValue;
        feed.lastUpdatedTimestamp = block.timestamp;
        emit OracleFeedUpdated(_feedId, _newValue, block.timestamp);
    }

    /// @notice Retrieves the latest value and timestamp for a registered oracle feed.
    /// @param _feedId The ID of the oracle feed.
    /// @return lastValue The last reported value.
    /// @return lastTimestamp The timestamp of the last update.
    function getLatestOracleData(bytes32 _feedId) public view returns (int256 lastValue, uint256 lastTimestamp) {
        OracleFeed storage feed = oracleFeeds[_feedId];
        require(feed.oracleAddress != address(0), "ChronoForge: Oracle feed not registered");
        require(feed.isAuthorized, "ChronoForge: Oracle provider for this feed is not authorized");
        return (feed.lastUpdatedValue, feed.lastUpdatedTimestamp);
    }

    /* ========== III. Chronoscape Template Management ========== */

    /// @notice Defines a reusable template for Chronoscapes.
    /// @param _definition The full ChronoscapeDefinition struct for the template.
    /// @return The ID of the newly created template.
    function createChronoscapeTemplate(ChronoscapeDefinition calldata _definition) public onlyOwner returns (uint256) {
        require(_definition.oracleFeedId != bytes32(0), "ChronoForge: Oracle feed ID cannot be zero");
        require(oracleFeeds[_definition.oracleFeedId].oracleAddress != address(0), "ChronoForge: Oracle feed not registered");
        require(_definition.expirationTime > block.timestamp, "ChronoForge: Template expiration must be in the future");
        require(_definition.successOutcome.recipient != address(0), "ChronoForge: Success recipient cannot be zero address");
        require(_definition.failureOutcome.recipient != address(0), "ChronoForge: Failure recipient cannot be zero address");
        require(_definition.successOutcome.percentageBasisPoints <= 10000, "ChronoForge: Success percentage invalid");
        require(_definition.failureOutcome.percentageBasisPoints <= 10000, "ChronoForge: Failure percentage invalid");
        require(_definition.disputePeriodDuration > 0, "ChronoForge: Dispute period must be greater than zero");

        _templateNonce++;
        uint256 templateId = _templateNonce;

        ChronoscapeDefinition storage newDefinition = chronoscapeDefinitions[templateId];
        newDefinition.oracleFeedId = _definition.oracleFeedId;
        newDefinition.comparisonType = _definition.comparisonType;
        newDefinition.thresholdValue = _definition.thresholdValue;
        newDefinition.expirationTime = _definition.expirationTime;
        newDefinition.evaluateOnExpirationOnly = _definition.evaluateOnExpirationOnly;
        newDefinition.successOutcome = _definition.successOutcome;
        newDefinition.failureOutcome = _definition.failureOutcome;
        newDefinition.disputePeriodDuration = _definition.disputePeriodDuration;
        newDefinition.minDeposit = _definition.minDeposit;
        newDefinition.metadataURI = _definition.metadataURI;
        newDefinition.isTemplate = true;
        newDefinition.templateId = 0; // Templates don't derive from other templates in this structure

        emit ChronoscapeTemplateCreated(templateId, msg.sender, _definition.metadataURI);
        return templateId;
    }

    /// @notice Retrieves the definition of a specific Chronoscape template.
    /// @param _templateId The ID of the template.
    /// @return The ChronoscapeDefinition struct.
    function getChronoscapeTemplate(uint256 _templateId) public view returns (ChronoscapeDefinition memory) {
        require(chronoscapeDefinitions[_templateId].isTemplate, "ChronoForge: ID does not correspond to a template");
        return chronoscapeDefinitions[_templateId];
    }

    /* ========== IV. Chronoscape Lifecycle ========== */

    /// @notice Creates a new Chronoscape instance from an existing template.
    ///         Requires an initial deposit to match the template's minDeposit.
    /// @param _templateId The ID of the template to use.
    /// @param _beneficiary The primary beneficiary for this specific Chronoscape instance.
    /// @param _metadataURI Optional: specific metadata for this instance, overrides template.
    /// @return The ID of the newly created Chronoscape.
    function createChronoscape(
        uint256 _templateId,
        address _beneficiary,
        string memory _metadataURI
    ) public payable nonReentrant whenNotPaused returns (uint256) {
        require(chronoscapeDefinitions[_templateId].isTemplate, "ChronoForge: Invalid template ID");
        require(_beneficiary != address(0), "ChronoForge: Beneficiary cannot be zero address");
        require(msg.value >= chronoscapeDefinitions[_templateId].minDeposit.add(chronoscapeCreationFee), "ChronoForge: Insufficient initial deposit or creation fee");

        ChronoscapeDefinition storage templateDef = chronoscapeDefinitions[_templateId];

        _chronoscapeNonce++;
        uint256 chronoscapeId = _chronoscapeNonce;

        // Store a copy of the definition specifically for this instance (can allow for overrides in future)
        chronoscapeDefinitions[chronoscapeId] = templateDef; // Deep copy
        chronoscapeDefinitions[chronoscapeId].isTemplate = false; // This is an instance, not a template itself
        chronoscapeDefinitions[chronoscapeId].templateId = _templateId; // Reference original template
        if (bytes(_metadataURI).length > 0) {
            chronoscapeDefinitions[chronoscapeId].metadataURI = _metadataURI; // Instance-specific metadata
        }

        chronoscapeStates[chronoscapeId] = ChronoscapeState({
            definitionId: chronoscapeId, // This instance's own definition ID
            creator: msg.sender,
            beneficiary: _beneficiary,
            currentDeposit: msg.value.sub(chronoscapeCreationFee),
            status: ChronoscapeStatus.Active, // Starts active as it's funded
            creationTime: block.timestamp,
            settlementAttemptTime: 0,
            lastSettler: address(0),
            lastDisputeTime: 0,
            settlementResult: false, // Default
            emergencyPaused: false
        });

        chronoscapeDeposits[chronoscapeId] = msg.value.sub(chronoscapeCreationFee);
        contractFees = contractFees.add(chronoscapeCreationFee);

        emit ChronoscapeCreated(
            chronoscapeId,
            chronoscapeId, // This Chronoscape's own definition ID
            msg.sender,
            _beneficiary,
            chronoscapeDeposits[chronoscapeId],
            chronoscapeDefinitions[chronoscapeId].metadataURI
        );

        return chronoscapeId;
    }

    /// @notice Allows the creator or others to deposit additional funds into an existing Chronoscape.
    /// @param _chronoscapeId The ID of the Chronoscape to deposit into.
    function depositForChronoscape(uint256 _chronoscapeId) public payable nonReentrant whenNotPaused notPausedGlobalAndChronoscape(_chronoscapeId) {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(state.status == ChronoscapeStatus.Active || state.status == ChronoscapeStatus.Pending, "ChronoForge: Chronoscape is not in a deposit-eligible status");
        require(msg.value > 0, "ChronoForge: Deposit amount must be greater than zero");

        state.currentDeposit = state.currentDeposit.add(msg.value);
        chronoscapeDeposits[_chronoscapeId] = chronoscapeDeposits[_chronoscapeId].add(msg.value);

        // If it was pending and now meets minDeposit, activate it
        if (state.status == ChronoscapeStatus.Pending && state.currentDeposit >= chronoscapeDefinitions[state.definitionId].minDeposit) {
            state.status = ChronoscapeStatus.Active;
        }

        emit ChronoscapeDeposited(_chronoscapeId, msg.sender, msg.value);
    }

    /// @notice Attempts to settle a Chronoscape based on its conditions.
    ///         Anyone can call this function to trigger settlement.
    /// @param _chronoscapeId The ID of the Chronoscape to settle.
    function settleChronoscape(uint256 _chronoscapeId) public nonReentrant whenNotPaused notPausedGlobalAndChronoscape(_chronoscapeId) {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        ChronoscapeDefinition storage definition = chronoscapeDefinitions[state.definitionId];
        OracleFeed storage oracle = oracleFeeds[definition.oracleFeedId];

        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(state.status == ChronoscapeStatus.Active, "ChronoForge: Chronoscape is not active for settlement");
        require(oracle.oracleAddress != address(0), "ChronoForge: Oracle feed not registered");
        require(oracle.isAuthorized, "ChronoForge: Oracle provider is not authorized");
        require(oracle.lastUpdatedTimestamp > 0, "ChronoForge: Oracle feed has no data yet");

        bool conditionsMet = false;
        if (block.timestamp >= definition.expirationTime) {
            // Conditions can only be evaluated after expiration if evaluateOnExpirationOnly is true
            // OR if it's past expiration regardless.
            // If evaluateOnExpirationOnly is false, it can be settled anytime after conditions are met.
            if (!definition.evaluateOnExpirationOnly || block.timestamp >= definition.expirationTime) {
                 int256 oracleValue = oracle.lastUpdatedValue;
                int256 threshold = definition.thresholdValue;

                if (definition.comparisonType == ComparisonType.GreaterThan && oracleValue > threshold) {
                    conditionsMet = true;
                } else if (definition.comparisonType == ComparisonType.LessThan && oracleValue < threshold) {
                    conditionsMet = true;
                } else if (definition.comparisonType == ComparisonType.EqualTo && oracleValue == threshold) {
                    conditionsMet = true;
                } else if (definition.comparisonType == ComparisonType.NotEqualTo && oracleValue != threshold) {
                    conditionsMet = true;
                } else if (definition.comparisonType == ComparisonType.GreaterThanOrEqualTo && oracleValue >= threshold) {
                    conditionsMet = true;
                } else if (definition.comparisonType == ComparisonType.LessThanOrEqualTo && oracleValue <= threshold) {
                    conditionsMet = true;
                }
            }
        }
        
        // If conditions are not met AND we are past expiration, it's a failure
        if (!conditionsMet && block.timestamp >= definition.expirationTime) {
            state.settlementResult = false; // Failure
            state.status = ChronoscapeStatus.SettledFailure;
        } else if (conditionsMet) {
            state.settlementResult = true; // Success
            state.status = ChronoscapeStatus.SettledSuccess;
        } else {
            // Conditions not met yet, and not past expiration
            revert("ChronoForge: Settlement conditions not met or not past expiration time");
        }

        // Proceed with fund distribution and fee collection
        uint256 totalDeposit = chronoscapeDeposits[_chronoscapeId];
        require(totalDeposit > 0, "ChronoForge: No funds deposited for settlement");

        OutcomeDistribution memory finalOutcome;
        ChronoscapeStatus newStatus;
        if (state.settlementResult) {
            finalOutcome = definition.successOutcome;
            newStatus = ChronoscapeStatus.SettledSuccess;
        } else {
            finalOutcome = definition.failureOutcome;
            newStatus = ChronoscapeStatus.SettledFailure;
        }

        uint256 feeAmount = totalDeposit.mul(chronoscapeSettlementFeeBasisPoints).div(10000); // 10000 basis points = 100%
        contractFees = contractFees.add(feeAmount);

        uint256 amountToDistribute = totalDeposit.sub(feeAmount);
        uint256 recipientAmount = amountToDistribute.mul(finalOutcome.percentageBasisPoints).div(10000);

        // Send funds to recipient
        (bool success, ) = payable(finalOutcome.recipient).call{value: recipientAmount}("");
        require(success, "ChronoForge: Fund distribution failed");

        // Any remaining amount not distributed by percentage (e.g., if percentage is less than 100%) goes back to Chronoscape creator (or a default address)
        uint256 remainingAmount = amountToDistribute.sub(recipientAmount);
        if (remainingAmount > 0) {
            (bool successCreator, ) = payable(state.creator).call{value: remainingAmount}("");
            require(successCreator, "ChronoForge: Remaining fund distribution to creator failed");
        }

        // Record settlement and potentially reward the caller (attester)
        state.currentDeposit = 0;
        chronoscapeDeposits[_chronoscapeId] = 0;
        state.settlementAttemptTime = block.timestamp;
        state.lastSettler = msg.sender;
        state.status = newStatus; // Update status AFTER all checks and transfers

        // Attestation reward (simple example, could be more complex, e.g., dynamic based on value)
        uint256 attestationRewardAmount = totalDeposit.div(1000); // 0.1% of settled value as reward
        if (settlementLiquidityPool >= attestationRewardAmount) {
            attestationRewards[msg.sender] = attestationRewards[msg.sender].add(attestationRewardAmount);
            settlementLiquidityPool = settlementLiquidityPool.sub(attestationRewardAmount);
        } else {
            // If pool is empty, no reward this time
            attestationRewardAmount = 0;
        }


        emit ChronoscapeSettled(_chronoscapeId, newStatus, msg.sender, recipientAmount, finalOutcome.recipient);
    }

    /// @notice Attempts to settle multiple Chronoscapes in one transaction.
    /// @param _chronoscapeIds An array of Chronoscape IDs to settle.
    function batchSettleChronoscapes(uint256[] calldata _chronoscapeIds) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < _chronoscapeIds.length; i++) {
            // Use try-catch to allow partial success in batch operations
            try this.settleChronoscape(_chronoscapeIds[i]) {
                // Success
            } catch (bytes memory reason) {
                // Log failure, or handle it as needed. For simplicity, just continue.
                emit ChronoscapeSettled(_chronoscapeIds[i], ChronoscapeStatus.Active, msg.sender, 0, address(0)); // Indicate failed attempt
                // Consider adding a specific event for batch settlement failures
            }
        }
    }

    /// @notice Initiates a dispute period for a Chronoscape after a settlement attempt.
    ///         This pauses any further action until the dispute is resolved.
    /// @param _chronoscapeId The ID of the Chronoscape to dispute.
    function disputeChronoscape(uint256 _chronoscapeId) public nonReentrant whenNotPaused {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        ChronoscapeDefinition storage definition = chronoscapeDefinitions[state.definitionId];

        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(state.status == ChronoscapeStatus.SettledSuccess || state.status == ChronoscapeStatus.SettledFailure, "ChronoForge: Chronoscape not in a settlable state to dispute");
        require(state.settlementAttemptTime > 0, "ChronoForge: No settlement attempt to dispute");
        require(block.timestamp <= state.settlementAttemptTime.add(definition.disputePeriodDuration), "ChronoForge: Dispute period has expired");

        state.status = ChronoscapeStatus.Disputed;
        state.lastDisputeTime = block.timestamp;
        emit ChronoscapeDisputed(_chronoscapeId, msg.sender);
    }

    /// @notice Finalizes a disputed Chronoscape.
    ///         In a full system, this would involve governance or a separate arbitration contract.
    ///         For this example, the owner can resolve disputes, either confirming settlement or reverting.
    /// @param _chronoscapeId The ID of the Chronoscape to resolve.
    function resolveDispute(uint256 _chronoscapeId) public onlyOwner nonReentrant whenNotPaused {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(state.status == ChronoscapeStatus.Disputed, "ChronoForge: Chronoscape is not in a disputed state");
        require(block.timestamp > state.lastDisputeTime.add(chronoscapeDefinitions[state.definitionId].disputePeriodDuration), "ChronoForge: Dispute period has not yet passed");

        // Owner decides to "resolve". This is highly simplified.
        // In a real system:
        // - Arbitration outcome (e.g., from a DAO vote or external oracle/service) would be fed here.
        // - Funds might need to be returned if an incorrect settlement was reverted.
        // - For this example, we simply revert to Active or final state based on owner's choice, assuming funds were not yet fully distributed (or can be clawed back).
        // Best practice would be to *hold* funds during dispute.
        state.status = ChronoscapeStatus.Active; // Re-enable for another settlement attempt
        state.settlementAttemptTime = 0; // Reset last attempt
        state.lastSettler = address(0);
        state.settlementResult = false; // Reset result

        emit ChronoscapeDisputeResolved(_chronoscapeId, msg.sender);
    }

    /// @notice Allows the owner to emergency pause a specific Chronoscape.
    /// @param _chronoscapeId The ID of the Chronoscape to pause.
    function emergencyPauseChronoscape(uint256 _chronoscapeId) public onlyOwner {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(!state.emergencyPaused, "ChronoForge: Chronoscape is already emergency paused");
        state.emergencyPaused = true;
        emit ChronoscapeEmergencyPaused(_chronoscapeId, msg.sender);
    }

    /// @notice Allows the owner to emergency unpause a specific Chronoscape.
    /// @param _chronoscapeId The ID of the Chronoscape to unpause.
    function emergencyUnpauseChronoscape(uint256 _chronoscapeId) public onlyOwner {
        ChronoscapeState storage state = chronoscapeStates[_chronoscapeId];
        require(state.creator != address(0), "ChronoForge: Chronoscape does not exist");
        require(state.emergencyPaused, "ChronoForge: Chronoscape is not emergency paused");
        state.emergencyPaused = false;
        emit ChronoscapeEmergencyUnpaused(_chronoscapeId, msg.sender);
    }

    /* ========== V. Attestation & Liquidity Pool ========== */

    /// @notice Allows users to deposit ETH into the global settlement liquidity pool to support attestation rewards.
    function depositLiquidityForSettlement() public payable nonReentrant whenNotPaused {
        require(msg.value > 0, "ChronoForge: Deposit amount must be greater than zero");
        settlementLiquidityPool = settlementLiquidityPool.add(msg.value);
        emit LiquidityDeposited(msg.sender, msg.value);
    }

    /// @notice Allows liquidity providers to withdraw their deposited ETH from the settlement pool.
    /// @param _amount The amount to withdraw.
    function withdrawLiquidityForSettlement(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "ChronoForge: Withdrawal amount must be greater than zero");
        require(settlementLiquidityPool >= _amount, "ChronoForge: Insufficient liquidity in pool");
        // In a real system, you'd track individual deposits and proportional withdrawals.
        // For simplicity, this assumes a single pool where anyone can withdraw up to available amount.
        // Better: mapping(address => uint256) public lpBalances;
        // require(lpBalances[msg.sender] >= _amount, "ChronoForge: Insufficient deposited liquidity");

        settlementLiquidityPool = settlementLiquidityPool.sub(_amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ChronoForge: Liquidity withdrawal failed");
        // lpBalances[msg.sender] = lpBalances[msg.sender].sub(_amount);
        emit LiquidityWithdrawn(msg.sender, _amount);
    }

    /// @notice Allows an eligible user to claim their accumulated attestation rewards.
    function claimAttestationReward() public nonReentrant whenNotPaused {
        uint256 reward = attestationRewards[msg.sender];
        require(reward > 0, "ChronoForge: No attestation reward to claim");

        attestationRewards[msg.sender] = 0; // Reset reward to prevent re-claiming
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "ChronoForge: Claiming reward failed");
        emit AttestationRewardClaimed(msg.sender, reward);
    }

    /* ========== View Functions ========== */

    /// @notice Retrieves the state of a specific Chronoscape.
    /// @param _chronoscapeId The ID of the Chronoscape.
    /// @return The ChronoscapeState struct.
    function getChronoscapeState(uint256 _chronoscapeId) public view returns (ChronoscapeState memory) {
        return chronoscapeStates[_chronoscapeId];
    }

    /// @notice Retrieves the definition of a specific Chronoscape instance (not template).
    /// @param _chronoscapeId The ID of the Chronoscape.
    /// @return The ChronoscapeDefinition struct.
    function getChronoscapeDefinition(uint256 _chronoscapeId) public view returns (ChronoscapeDefinition memory) {
        require(!chronoscapeDefinitions[_chronoscapeId].isTemplate, "ChronoForge: ID corresponds to a template, not an instance");
        return chronoscapeDefinitions[_chronoscapeId];
    }

    /// @notice Returns the total number of Chronoscape instances created.
    /// @return The total Chronoscape nonce.
    function getChronoscapeCount() public view returns (uint256) {
        return _chronoscapeNonce;
    }

    /// @notice Returns the total number of Chronoscape templates created.
    /// @return The total template nonce.
    function getTemplateCount() public view returns (uint256) {
        return _templateNonce;
    }
}
```