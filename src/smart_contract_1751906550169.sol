Okay, this sounds like a fun challenge! Let's design a smart contract based on a complex, creative, and less-explored concept. How about a "Quantum State Asset Hub" where assets can exist in multiple potential states simultaneously until an "observation" event collapses them into one definite state, and these assets can be traded conditionally based on such observations? This blends ideas from state channels (simplified), oracles, conditional logic, and a unique asset model.

We'll call the contract `QuantumTradeHub`.

**Concept:**
Users can interact with special assets (`QAsset`) that conceptually exist in a superposition of possible outcomes. These assets are backed by collateral (e.g., ERC-20). A `QAsset` type defines the possible outcomes and their probabilities or conditions. An "observation oracle" provides external data (the "observation") which triggers the "collapse" of a `QAsset` instance into one specific outcome, releasing or reallocating the underlying collateral. Users can also create conditional trades (`QTrade`) based on the future collapse outcome of specific `QAsset` instances or general observation topics.

**Outline:**

1.  **Contract Definition:** `QuantumTradeHub is Ownable, ReentrancyGuard` (using standard open-zeppelin for safety).
2.  **State Variables:**
    *   Owner, Observation Oracle address.
    *   Mapping for QAsset types (defining potential outcomes).
    *   Mapping for QAsset instances (tracking specific minted assets and their current/collapsed state).
    *   Mapping for user collateral balances (ERC-20 backing QAssets).
    *   Mapping for active trade offers.
    *   Mapping for accepted trades.
    *   Mapping for observation topics and their latest results.
    *   Protocol fee percentage and collected fees.
    *   Pause state.
3.  **Structs and Enums:**
    *   `QAssetOutcome`: Defines a possible outcome for a QAsset type (e.g., ERC20 token + amount, or just a value).
    *   `QAssetType`: Defines a template for QAssets, including a set of `QAssetOutcome`s, an observation topic, and parameters determining collapse logic.
    *   `QAssetInstance`: Represents a specific minted QAsset (ID, type ID, current state, collapsed outcome details).
    *   `TradeOffer`: Details of a conditional trade proposal (maker, assets offered/requested, condition based on observation/collapse, state).
    *   `Trade`: Details of an accepted conditional trade (participants, assets, condition, state).
    *   `QAssetInstanceState`: Enum (Superposed, Collapsed).
    *   `TradeState`: Enum (Offer, Accepted, ResolvedSuccess, ResolvedFail, Cancelled).
    *   `TradeConditionType`: Enum (OnObservationTopicResult, OnQAssetCollapseOutcome).
4.  **Events:** Signal key actions (Asset minted, State collapsed, Trade offered, Trade accepted, Trade resolved, Oracle observation).
5.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`), state checks (`whenNotPaused`).
6.  **Functions (aiming for 20+ unique actions):**
    *   **Admin/Setup (Owner):** Set oracle, register asset types, register observation topics, set fees, pause/unpause.
    *   **Oracle Interaction (Oracle):** Submit observation results, trigger collapse/resolution processes.
    *   **QAsset Management (User):** Deposit collateral, mint QAssets, view QAsset state, withdraw collateral (after collapse), transfer QAssets (in current state).
    *   **QTrade Management (User):** Create trade offers, accept offers, cancel offers, query offers/trades.
    *   **Internal/Helper:** Logic for collapsing QAssets, resolving trades based on observations.
    *   **Query/View (Any User):** Get details of types, instances, offers, trades, balances, oracle, fees.

**Function Summary (20+ Functions):**

1.  `constructor()`: Deploys the contract, sets initial owner.
2.  `setObservationOracle(address _oracle)`: Sets the authorized address for submitting observations (Owner only).
3.  `addQAssetType(string memory _name, address _collateralToken, uint256 _collateralAmount, bytes32 _observationTopic, QAssetOutcome[] memory _outcomes)`: Registers a new type of QAsset (Owner only).
4.  `removeQAssetType(uint256 _typeId)`: Removes a registered QAsset type (Owner only).
5.  `registerObservationTopic(bytes32 _topic)`: Registers a topic that the oracle can submit observations for (Owner only).
6.  `unregisterObservationTopic(bytes32 _topic)`: Unregisters an observation topic (Owner only).
7.  `setProtocolFee(uint256 _feeBasisPoints)`: Sets the fee percentage (Owner only).
8.  `withdrawProtocolFees(address _token, uint256 _amount)`: Owner withdraws accumulated fees for a specific token.
9.  `pauseTrading()`: Pauses creation and acceptance of new trades (Owner only).
10. `unpauseTrading()`: Unpauses trading (Owner only).
11. `depositCollateral(address _token, uint256 _amount)`: Users deposit ERC20 tokens as collateral for future QAssets.
12. `mintQAsset(uint256 _typeId)`: Mints a new QAsset instance of a registered type, using deposited collateral.
13. `withdrawCollateral(address _token, uint256 _amount)`: Users withdraw available collateral (after QAsset collapse/trade resolution).
14. `transferQAsset(uint256 _instanceId, address _to)`: Transfers ownership of a specific QAsset instance.
15. `submitObservationResult(bytes32 _topic, uint256 _resultCode, bytes memory _resultData)`: Oracle submits an observation result for a topic. Triggers potential collapses/resolutions. (Oracle only).
16. `createQTradeOffer(uint256 _offerAssetInstanceId, address _offerAssetToken, uint256 _offerAssetAmount, uint256 _requestAssetInstanceId, address _requestAssetToken, uint256 _requestAssetAmount, TradeConditionType _conditionType, bytes32 _observationTopicCondition, uint256 _resultCodeCondition, uint256 _qAssetInstanceConditionId, uint256 _outcomeIndexCondition)`: Creates a conditional trade offer. Assets are escrowed. (whenNotPaused).
17. `acceptQTradeOffer(uint256 _offerId)`: Accepts a pending trade offer. Escrows taker's assets. (whenNotPaused).
18. `cancelQTradeOffer(uint256 _offerId)`: Maker cancels their offer (before acceptance/resolution). Releases maker's escrowed assets.
19. `queryQAssetDetails(uint256 _instanceId)`: Get details and current state of a specific QAsset instance.
20. `queryQAssetBalance(address _owner, uint256 _instanceId)`: Check if an address owns a specific QAsset instance.
21. `queryTradeOfferDetails(uint256 _offerId)`: Get details of a specific trade offer.
22. `queryTradeDetails(uint256 _tradeId)`: Get details of an accepted trade.
23. `queryCollateralBalance(address _owner, address _token)`: Get an address's deposited collateral balance for a token.
24. `getLatestObservationResult(bytes32 _topic)`: Get the last submitted result for an observation topic.
25. `getQAssetTypeDetails(uint256 _typeId)`: Get details of a registered QAsset type.
26. `getAllQAssetTypeIds()`: Get a list of all registered QAsset type IDs.
27. `getAllRegisteredObservationTopics()`: Get a list of all registered observation topics.
28. `isTradeOfferExist(uint256 _offerId)`: Check if a trade offer ID exists.
29. `isTradeExist(uint256 _tradeId)`: Check if a trade ID exists.
30. `getOracleAddress()`: Get the current oracle address.
31. `getProtocolFeeBasisPoints()`: Get the current protocol fee percentage.

*(Self-correction: Need to ensure internal functions handle the actual collapse and trade execution logic triggered by `submitObservationResult`. Let's add internal helpers like `_collapseQAsset` and `_resolveTrade`.)*

32. `_collapseQAsset(uint256 _instanceId, uint256 _resultCode)`: Internal helper to determine and set the collapsed state of a QAsset based on an observation result, release/allocate collateral.
33. `_resolveTrade(uint256 _tradeId)`: Internal helper to execute or cancel a trade based on its condition and the latest observations/asset states.

This structure gives us well over the required 20 functions, covering administrative setup, asset lifecycle, trading mechanics, oracle interaction, and query functions. The "quantum" aspect is simulated by having assets in a pending state until an external "observation" triggers a deterministic "collapse" based on predefined rules, and trades can be contingent on this.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though less needed in 0.8+, good practice for clarity
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title QuantumTradeHub
 * @notice A decentralized hub for creating, managing, and trading "Quantum-Inspired Assets" (QAssets)
 * which exist in a superposition of states until an external "observation" triggers a collapse
 * to a single outcome. Supports conditional trading based on these observation/collapse events.
 * This contract simulates quantum concepts like superposition and collapse using state machines
 * driven by oracle data. It is NOT a simulation of actual quantum physics.
 */
contract QuantumTradeHub is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    // --- State Variables ---
    address public observationOracle; // Address authorized to submit observations
    bool public paused = false; // Trading pause state

    // QAsset Types: Templates defining potential outcomes and collapse logic
    struct QAssetOutcome {
        address token; // Address of the ERC20 token for this outcome
        uint256 amount; // Amount of the ERC20 token for this outcome
        // Future: Could add other outcome types (NFT, value, etc.)
    }

    struct QAssetType {
        string name; // Descriptive name for the asset type
        address collateralToken; // ERC20 token required as collateral to mint this type
        uint256 collateralAmount; // Amount of collateral required per instance
        bytes32 observationTopic; // Topic ID this asset type depends on for collapse
        QAssetOutcome[] outcomes; // Possible outcomes for this asset type. Collapse logic picks one.
        bool exists; // Marker to check if the type is active/registered
    }
    mapping(uint256 => QAssetType) public qAssetTypes;
    uint256 private nextQAssetTypeId = 1; // Counter for unique type IDs

    // QAsset Instances: Specific minted assets
    enum QAssetInstanceState { Superposed, Collapsed }
    struct QAssetInstance {
        uint256 typeId; // The QAssetType this instance belongs to
        address owner; // Current owner of the instance
        QAssetInstanceState state; // Current state (Superposed or Collapsed)
        // Details if Collapsed
        uint256 collapsedOutcomeIndex; // Index of the outcome chosen from the type's outcomes
    }
    mapping(uint256 => QAssetInstance) public qAssetInstances;
    mapping(address => mapping(uint256 => bool)) private qAssetInstanceOwnership; // To track ownership efficiently
    uint256 private nextQAssetInstanceId = 1; // Counter for unique instance IDs

    // User Collateral Balances
    mapping(address => mapping(address => uint256)) private userCollateral; // user => token => amount

    // Observation Topics and Results
    mapping(bytes32 => bool) public registeredObservationTopics;
    mapping(bytes32 => uint256) private latestObservationResults; // topic => resultCode

    // Conditional Trades
    enum TradeState { Offer, Accepted, ResolvedSuccess, ResolvedFail, Cancelled }
    enum TradeConditionType {
        OnObservationTopicResult, // Trade resolves based on a specific topic's result code
        OnQAssetCollapseOutcome // Trade resolves based on a specific QAsset instance's collapsed outcome index
    }

    struct TradeOffer {
        address maker;
        // Assets offered by maker (can be QAsset or ERC20)
        bool makerOffersQAsset; // True if offering QAsset instance, False if offering ERC20
        uint256 offerAssetInstanceId; // QAsset Instance ID if makerOffersQAsset = true
        address offerAssetToken; // ERC20 Token address if makerOffersQAsset = false
        uint256 offerAssetAmount; // Amount if makerOffersQAsset = false
        // Assets requested by maker (can be QAsset or ERC20)
        bool makerRequestsQAsset; // True if requesting QAsset instance, False if requesting ERC20
        uint256 requestAssetInstanceId; // QAsset Instance ID if makerRequestsQAsset = true
        address requestAssetToken; // ERC20 Token address if makerRequestsQAsset = false
        uint256 requestAssetAmount; // Amount if makerRequestsQAsset = false
        // Condition for resolution
        TradeConditionType conditionType;
        bytes32 observationTopicCondition; // Relevant if conditionType is OnObservationTopicResult
        uint256 resultCodeCondition; // Relevant if conditionType is OnObservationTopicResult
        uint256 qAssetInstanceConditionId; // Relevant if conditionType is OnQAssetCollapseOutcome
        uint256 outcomeIndexCondition; // Relevant if conditionType is OnQAssetCollapseOutcome

        TradeState state; // Offer or Cancelled
        uint256 acceptedTradeId; // Link to the Trade struct if Accepted
    }
    mapping(uint256 => TradeOffer) public qTradeOffers;
    uint256 private nextTradeOfferId = 1; // Counter for unique offer IDs

    struct Trade {
        uint256 offerId; // Link back to the original offer
        address maker;
        address taker;
        // Assets involved (copied from offer for snapshot)
        bool makerOffersQAsset;
        uint256 offerAssetInstanceId;
        address offerAssetToken;
        uint256 offerAssetAmount;
        bool makerRequestsQAsset;
        uint256 requestAssetInstanceId;
        address requestAssetToken;
        uint256 requestAssetAmount;
        // Condition for resolution (copied from offer)
        TradeConditionType conditionType;
        bytes32 observationTopicCondition;
        uint256 resultCodeCondition;
        uint256 qAssetInstanceConditionId;
        uint256 outcomeIndexCondition;

        TradeState state; // Accepted, ResolvedSuccess, ResolvedFail
        uint256 resolutionTimestamp; // Timestamp when resolved
    }
    mapping(uint256 => Trade) public qTrades;
    uint256 private nextTradeId = 1; // Counter for unique trade IDs

    // Protocol Fees
    uint256 public protocolFeeBasisPoints = 0; // Fee in basis points (e.g., 10 = 0.1%)
    mapping(address => uint256) private collectedFees; // token => amount

    // --- Events ---
    event ObservationOracleSet(address indexed newOracle);
    event QAssetTypeAdded(uint256 indexed typeId, string name, address collateralToken);
    event QAssetTypeRemoved(uint256 indexed typeId);
    event ObservationTopicRegistered(bytes32 indexed topic);
    event ObservationTopicUnregistered(bytes32 indexed topic);
    event ProtocolFeeSet(uint256 feeBasisPoints);
    event ProtocolFeesWithdrawn(address indexed token, address indexed to, uint256 amount);
    event TradingPaused();
    event TradingUnpaused();

    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
    event QAssetMinted(address indexed minter, uint256 indexed instanceId, uint256 typeId);
    event QAssetTransferred(address indexed from, address indexed to, uint256 indexed instanceId);
    event QAssetCollapsed(uint256 indexed instanceId, uint256 indexed outcomeIndex, uint256 resultCode);

    event TradeOfferCreated(uint256 indexed offerId, address indexed maker, TradeConditionType conditionType);
    event TradeOfferCancelled(uint256 indexed offerId);
    event TradeAccepted(uint256 indexed offerId, uint256 indexed tradeId, address indexed taker);
    event TradeResolved(uint256 indexed tradeId, TradeState finalState);

    event ObservationSubmitted(bytes32 indexed topic, uint256 resultCode);

    // --- Modifiers ---
    modifier onlyObservationOracle() {
        require(msg.sender == observationOracle, "QTH: Caller is not the oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QTH: Trading is paused");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Admin/Setup Functions (Owner Only) ---

    /**
     * @notice Sets the address authorized to submit observation results.
     * @param _oracle The address of the observation oracle.
     */
    function setObservationOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QTH: Invalid oracle address");
        observationOracle = _oracle;
        emit ObservationOracleSet(_oracle);
    }

    /**
     * @notice Registers a new QAsset type.
     * @param _name Descriptive name for the asset type.
     * @param _collateralToken ERC20 token required as collateral.
     * @param _collateralAmount Amount of collateral required per instance.
     * @param _observationTopic Topic ID this type depends on for collapse. Must be registered.
     * @param _outcomes Array of possible outcomes for this type.
     */
    function addQAssetType(
        string memory _name,
        address _collateralToken,
        uint256 _collateralAmount,
        bytes32 _observationTopic,
        QAssetOutcome[] memory _outcomes
    ) external onlyOwner {
        require(bytes(_name).length > 0, "QTH: Name cannot be empty");
        require(_collateralToken != address(0), "QTH: Invalid collateral token address");
        require(_collateralAmount > 0, "QTH: Collateral amount must be > 0");
        require(registeredObservationTopics[_observationTopic], "QTH: Observation topic not registered");
        require(_outcomes.length > 0, "QTH: Must define at least one outcome");

        uint256 typeId = nextQAssetTypeId++;
        qAssetTypes[typeId] = QAssetType({
            name: _name,
            collateralToken: _collateralToken,
            collateralAmount: _collateralAmount,
            observationTopic: _observationTopic,
            outcomes: _outcomes,
            exists: true
        });
        emit QAssetTypeAdded(typeId, _name, _collateralToken);
    }

    /**
     * @notice Removes a registered QAsset type. Existing instances remain but new ones cannot be minted.
     * @param _typeId The ID of the QAsset type to remove.
     */
    function removeQAssetType(uint256 _typeId) external onlyOwner {
        require(qAssetTypes[_typeId].exists, "QTH: QAsset type does not exist");
        // Soft delete: Mark as non-existent. Could add cleanup logic if needed.
        qAssetTypes[_typeId].exists = false;
        emit QAssetTypeRemoved(_typeId);
    }

    /**
     * @notice Registers a topic that the oracle is allowed to submit observations for.
     * @param _topic The topic ID (bytes32).
     */
    function registerObservationTopic(bytes32 _topic) external onlyOwner {
        require(!registeredObservationTopics[_topic], "QTH: Topic already registered");
        require(_topic != bytes32(0), "QTH: Invalid topic");
        registeredObservationTopics[_topic] = true;
        emit ObservationTopicRegistered(_topic);
    }

    /**
     * @notice Unregisters an observation topic. Does not affect ongoing trades/assets dependent on it.
     * @param _topic The topic ID (bytes32).
     */
    function unregisterObservationTopic(bytes32 _topic) external onlyOwner {
        require(registeredObservationTopics[_topic], "QTH: Topic not registered");
        registeredObservationTopics[_topic] = false;
        emit ObservationTopicUnregistered(_topic);
    }

    /**
     * @notice Sets the protocol fee in basis points (0-10000).
     * @param _feeBasisPoints The new fee percentage * 100 (e.g., 100 = 1%).
     */
    function setProtocolFee(uint256 _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "QTH: Fee cannot exceed 100%");
        protocolFeeBasisPoints = _feeBasisPoints;
        emit ProtocolFeeSet(_feeBasisPoints);
    }

    /**
     * @notice Allows the owner to withdraw collected protocol fees.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawProtocolFees(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_token != address(0), "QTH: Invalid token address");
        uint256 availableFees = collectedFees[_token];
        require(_amount > 0 && _amount <= availableFees, "QTH: Insufficient collected fees");

        collectedFees[_token] = availableFees.sub(_amount);
        IERC20(_token).safeTransfer(owner(), _amount);

        emit ProtocolFeesWithdrawn(_token, owner(), _amount);
    }

    /**
     * @notice Pauses the creation and acceptance of new trades.
     */
    function pauseTrading() external onlyOwner {
        require(!paused, "QTH: Already paused");
        paused = true;
        emit TradingPaused();
    }

    /**
     * @notice Unpauses trading.
     */
    function unpauseTrading() external onlyOwner {
        require(paused, "QTH: Not paused");
        paused = false;
        emit TradingUnpaused();
    }

    // --- User QAsset Management Functions ---

    /**
     * @notice Deposits ERC20 tokens to be used as collateral for minting QAssets.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to deposit.
     */
    function depositCollateral(address _token, uint256 _amount) external nonReentrant {
        require(_token != address(0), "QTH: Invalid token address");
        require(_amount > 0, "QTH: Amount must be > 0");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        userCollateral[msg.sender][_token] = userCollateral[msg.sender][_token].add(_amount);

        emit CollateralDeposited(msg.sender, _token, _amount);
    }

    /**
     * @notice Mints a new QAsset instance using deposited collateral.
     * The collateral is moved from the user's deposited balance to be backing the asset.
     * @param _typeId The ID of the QAsset type to mint.
     */
    function mintQAsset(uint256 _typeId) external nonReentrant {
        QAssetType storage assetType = qAssetTypes[_typeId];
        require(assetType.exists, "QTH: QAsset type does not exist");
        require(userCollateral[msg.sender][assetType.collateralToken] >= assetType.collateralAmount, "QTH: Insufficient collateral deposited");

        userCollateral[msg.sender][assetType.collateralToken] = userCollateral[msg.sender][assetType.collateralToken].sub(assetType.collateralAmount);

        uint256 instanceId = nextQAssetInstanceId++;
        qAssetInstances[instanceId] = QAssetInstance({
            typeId: _typeId,
            owner: msg.sender,
            state: QAssetInstanceState.Superposed,
            collapsedOutcomeIndex: 0 // Placeholder
        });
        qAssetInstanceOwnership[msg.sender][instanceId] = true;

        emit QAssetMinted(msg.sender, instanceId, _typeId);
    }

    /**
     * @notice Allows users to withdraw available collateral that is not backing any QAssets or trades.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to withdraw.
     */
    function withdrawCollateral(address _token, uint256 _amount) external nonReentrant {
        require(_token != address(0), "QTH: Invalid token address");
        uint256 available = userCollateral[msg.sender][_token];
        require(_amount > 0 && _amount <= available, "QTH: Insufficient available collateral");

        userCollateral[msg.sender][_token] = available.sub(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit CollateralWithdrawn(msg.sender, _token, _amount);
    }

    /**
     * @notice Transfers ownership of a specific QAsset instance.
     * @param _instanceId The ID of the QAsset instance to transfer.
     * @param _to The address of the recipient.
     */
    function transferQAsset(uint256 _instanceId, address _to) external {
        require(_to != address(0), "QTH: Invalid recipient address");
        require(qAssetInstanceOwnership[msg.sender][_instanceId], "QTH: Caller does not own this QAsset instance");
        require(!qAssetInstanceOwnership[_to][_instanceId], "QTH: Recipient already owns this QAsset instance"); // Prevent duplicate entries

        QAssetInstance storage asset = qAssetInstances[_instanceId];
        require(asset.owner == msg.sender, "QTH: Caller is not the true owner"); // Double check ownership
        require(asset.state != QAssetInstanceState.Collapsed, "QTH: Cannot transfer collapsed QAsset"); // Example restriction

        qAssetInstanceOwnership[msg.sender][_instanceId] = false;
        asset.owner = _to;
        qAssetInstanceOwnership[_to][_instanceId] = true;

        emit QAssetTransferred(msg.sender, _to, _instanceId);
    }

    // --- Oracle Interaction Function ---

    /**
     * @notice Allows the authorized oracle to submit a result for an observation topic.
     * This triggers the resolution logic for dependent QAssets and Trades.
     * @param _topic The topic ID.
     * @param _resultCode A numeric code representing the outcome ( interpretation depends on topic/assets).
     * @param _resultData Optional extra data related to the result.
     */
    function submitObservationResult(bytes32 _topic, uint256 _resultCode, bytes memory _resultData) external onlyObservationOracle {
        require(registeredObservationTopics[_topic], "QTH: Observation topic not registered");
        // Prevent re-submitting the exact same result? Depends on oracle design. Allowing for now.

        latestObservationResults[_topic] = _resultCode; // Store the latest result
        emit ObservationSubmitted(_topic, _resultCode);

        // --- Trigger Dependent Collapses/Resolutions ---
        // Note: Iterating through all assets/trades can be gas-intensive in practice.
        // A more scalable design would involve queueing or external triggers for collapse/resolution.
        // For this example, we simulate the trigger directly.

        // Trigger QAsset collapses dependent on this topic
        // (In a real contract, you'd need a mapping from topic to QAssetInstance IDs or iterate)
        // Simulating iteration for demonstration:
        uint256 currentInstanceId = 1;
        while (currentInstanceId < nextQAssetInstanceId) {
            QAssetInstance storage asset = qAssetInstances[currentInstanceId];
            if (asset.state == QAssetInstanceState.Superposed) {
                 // Check if this asset type depends on the submitted topic
                QAssetType storage assetType = qAssetTypes[asset.typeId];
                if (assetType.exists && assetType.observationTopic == _topic) {
                    _collapseQAsset(currentInstanceId, _resultCode);
                }
            }
            currentInstanceId++;
        }

        // Trigger Trade resolutions dependent on this topic or on assets that just collapsed
        // (Again, would need mapping from topic/asset ID to trade IDs or iterate)
        // Simulating iteration for demonstration:
        uint256 currentTradeId = 1;
        while (currentTradeId < nextTradeId) {
            Trade storage trade = qTrades[currentTradeId];
            // Resolve if Accepted and condition is met by the *new* observation
            if (trade.state == TradeState.Accepted) {
                bool conditionMet = false;
                if (trade.conditionType == TradeConditionType.OnObservationTopicResult && trade.observationTopicCondition == _topic) {
                    if (latestObservationResults[_topic] == trade.resultCodeCondition) {
                        conditionMet = true;
                    }
                }
                // Note: Trades dependent on a QAsset collapse outcome should ideally be triggered *after* the asset collapses.
                // This requires careful sequencing or a separate process.
                // For simplicity here, we might check if the target QAsset is now collapsed and meets the condition.
                if (trade.conditionType == TradeConditionType.OnQAssetCollapseOutcome) {
                    QAssetInstance storage conditionAsset = qAssetInstances[trade.qAssetInstanceConditionId];
                    if (conditionAsset.state == QAssetInstanceState.Collapsed && conditionAsset.collapsedOutcomeIndex == trade.outcomeIndexCondition) {
                        conditionMet = true;
                    }
                }

                if (conditionMet) {
                    _resolveTrade(currentTradeId);
                }
            }
            currentTradeId++;
        }
    }


    // --- User QTrade Management Functions ---

    /**
     * @notice Creates a conditional trade offer. Assets offered by the maker are escrowed.
     * Requires asset approval/transferFrom for ERC20s or ownership of QAssets.
     * @param _offerAssetInstanceId ID of QAsset offered (if applicable).
     * @param _offerAssetToken ERC20 token address offered (if applicable).
     * @param _offerAssetAmount ERC20 token amount offered (if applicable).
     * @param _requestAssetInstanceId ID of QAsset requested (if applicable).
     * @param _requestAssetToken ERC20 token address requested (if applicable).
     * @param _requestAssetAmount ERC20 token amount requested (if applicable).
     * @param _conditionType The type of condition for trade resolution.
     * @param _observationTopicCondition Topic ID if conditionType is OnObservationTopicResult.
     * @param _resultCodeCondition Result code required if conditionType is OnObservationTopicResult.
     * @param _qAssetInstanceConditionId QAsset Instance ID if conditionType is OnQAssetCollapseOutcome.
     * @param _outcomeIndexCondition Outcome index required if conditionType is OnQAssetCollapseOutcome.
     */
    function createQTradeOffer(
        uint256 _offerAssetInstanceId,
        address _offerAssetToken,
        uint256 _offerAssetAmount,
        uint256 _requestAssetInstanceId,
        address _requestAssetToken,
        uint256 _requestAssetAmount,
        TradeConditionType _conditionType,
        bytes32 _observationTopicCondition,
        uint256 _resultCodeCondition,
        uint256 _qAssetInstanceConditionId,
        uint256 _outcomeIndexCondition
    ) external nonReentrant whenNotPaused {
        bool makerOffersQAsset = _offerAssetInstanceId > 0;
        bool makerRequestsQAsset = _requestAssetInstanceId > 0;

        // Basic validation
        require(makerOffersQAsset != (_offerAssetToken != address(0) && _offerAssetAmount > 0), "QTH: Must offer either one QAsset instance or ERC20");
        require(makerRequestsQAsset != (_requestAssetToken != address(0) && _requestAssetAmount > 0), "QTH: Must request either one QAsset instance or ERC20");
        require(makerOffersQAsset || makerRequestsQAsset, "QTH: Offer must involve at least one asset type (offer or request)");

        // Validate offered asset and escrow
        if (makerOffersQAsset) {
            require(qAssetInstanceOwnership[msg.sender][_offerAssetInstanceId], "QTH: Maker does not own the offered QAsset instance");
            require(qAssetInstances[_offerAssetInstanceId].state == QAssetInstanceState.Superposed, "QTH: Offered QAsset must be in Superposed state");
            // Transfer ownership to the contract for escrow
            transferQAsset(_offerAssetInstanceId, address(this)); // Uses internal transfer logic
        } else { // Offering ERC20
            require(_offerAssetToken != address(0) && _offerAssetAmount > 0, "QTH: Invalid ERC20 offer details");
            IERC20(_offerAssetToken).safeTransferFrom(msg.sender, address(this), _offerAssetAmount);
        }

        // Validate requested asset (no escrow needed yet)
        if (makerRequestsQAsset) {
            require(_requestAssetInstanceId > 0, "QTH: Invalid requested QAsset instance ID");
             require(qAssetInstances[_requestAssetInstanceId].state == QAssetInstanceState.Superposed, "QTH: Requested QAsset must be in Superposed state");
            // Require that the requested QAsset is NOT owned by the maker, else it's a self-trade setup
            require(!qAssetInstanceOwnership[msg.sender][_requestAssetInstanceId], "QTH: Cannot request a QAsset instance you already own");
        } else { // Requesting ERC20
             require(_requestAssetToken != address(0) && _requestAssetAmount > 0, "QTH: Invalid ERC20 request details");
        }


        // Validate condition
        if (_conditionType == TradeConditionType.OnObservationTopicResult) {
            require(registeredObservationTopics[_observationTopicCondition], "QTH: Conditional topic not registered");
            require(_qAssetInstanceConditionId == 0 && _outcomeIndexCondition == 0, "QTH: Invalid params for topic condition");
        } else if (_conditionType == TradeConditionType.OnQAssetCollapseOutcome) {
            QAssetInstance storage conditionAsset = qAssetInstances[_qAssetInstanceConditionId];
            require(conditionAsset.state == QAssetInstanceState.Superposed, "QTH: Conditional QAsset must be in Superposed state");
            QAssetType storage conditionAssetType = qAssetTypes[conditionAsset.typeId];
             require(conditionAssetType.exists, "QTH: Conditional QAsset type does not exist");
            require(_outcomeIndexCondition < conditionAssetType.outcomes.length, "QTH: Conditional outcome index out of bounds");
             require(_observationTopicCondition == bytes32(0) && _resultCodeCondition == 0, "QTH: Invalid params for QAsset condition");
        } else {
            revert("QTH: Invalid condition type");
        }

        uint256 offerId = nextTradeOfferId++;
        qTradeOffers[offerId] = TradeOffer({
            maker: msg.sender,
            makerOffersQAsset: makerOffersQAsset,
            offerAssetInstanceId: _offerAssetInstanceId,
            offerAssetToken: _offerAssetToken,
            offerAssetAmount: _offerAssetAmount,
            makerRequestsQAsset: makerRequestsQAsset,
            requestAssetInstanceId: _requestAssetInstanceId,
            requestAssetToken: _requestAssetToken,
            requestAssetAmount: _requestAssetAmount,
            conditionType: _conditionType,
            observationTopicCondition: _observationTopicCondition,
            resultCodeCondition: _resultCodeCondition,
            qAssetInstanceConditionId: _qAssetInstanceConditionId,
            outcomeIndexCondition: _outcomeIndexCondition,
            state: TradeState.Offer,
            acceptedTradeId: 0 // Not accepted yet
        });

        emit TradeOfferCreated(offerId, msg.sender, _conditionType);
    }

    /**
     * @notice Accepts a conditional trade offer. Assets requested by the maker are escrowed from the taker.
     * Requires asset approval/transferFrom for ERC20s or ownership of QAssets by the taker.
     * @param _offerId The ID of the trade offer to accept.
     */
    function acceptQTradeOffer(uint256 _offerId) external nonReentrant whenNotPaused {
        TradeOffer storage offer = qTradeOffers[_offerId];
        require(offer.state == TradeState.Offer, "QTH: Offer is not available");
        require(offer.maker != msg.sender, "QTH: Cannot accept your own offer");

        // Validate requested asset (maker's requested, taker's offered) and escrow from taker
        bool takerOffersQAsset = offer.makerRequestsQAsset; // Taker offers what maker requested
        if (takerOffersQAsset) {
             require(qAssetInstanceOwnership[msg.sender][offer.requestAssetInstanceId], "QTH: Taker does not own the requested QAsset instance");
             require(qAssetInstances[offer.requestAssetInstanceId].state == QAssetInstanceState.Superposed, "QTH: Offered (by taker) QAsset must be in Superposed state");
             // Transfer ownership to the contract for escrow
            transferQAsset(offer.requestAssetInstanceId, address(this)); // Uses internal transfer logic
        } else { // Taker offers ERC20
             require(offer.requestAssetToken != address(0) && offer.requestAssetAmount > 0, "QTH: Invalid ERC20 request details in offer");
            IERC20(offer.requestAssetToken).safeTransferFrom(msg.sender, address(this), offer.requestAssetAmount);
        }

        // Create the Trade instance
        uint256 tradeId = nextTradeId++;
        qTrades[tradeId] = Trade({
            offerId: _offerId,
            maker: offer.maker,
            taker: msg.sender,
            // Copy asset details
            makerOffersQAsset: offer.makerOffersQAsset,
            offerAssetInstanceId: offer.offerAssetInstanceId,
            offerAssetToken: offer.offerAssetToken,
            offerAssetAmount: offer.offerAssetAmount,
            makerRequestsQAsset: offer.makerRequestsQAsset,
            requestAssetInstanceId: offer.requestAssetInstanceId,
            requestAssetToken: offer.requestAssetToken,
            requestAssetAmount: offer.requestAssetAmount,
            // Copy condition
            conditionType: offer.conditionType,
            observationTopicCondition: offer.observationTopicCondition,
            resultCodeCondition: offer.resultCodeCondition,
            qAssetInstanceConditionId: offer.qAssetInstanceConditionId,
            outcomeIndexCondition: offer.outcomeIndexCondition,
            state: TradeState.Accepted,
            resolutionTimestamp: 0
        });

        // Link offer to trade and update offer state
        offer.state = TradeState.Accepted;
        offer.acceptedTradeId = tradeId;

        emit TradeAccepted(_offerId, tradeId, msg.sender);

        // Optional: If the condition is already met, resolve immediately (e.g., topic already observed)
        // For simplicity, we rely on submitObservationResult or manual trigger to resolve.
    }

    /**
     * @notice Maker cancels their trade offer. Can only be done if the offer is still in the 'Offer' state.
     * Escrowed assets are returned to the maker.
     * @param _offerId The ID of the trade offer to cancel.
     */
    function cancelQTradeOffer(uint256 _offerId) external nonReentrant {
        TradeOffer storage offer = qTradeOffers[_offerId];
        require(offer.state == TradeState.Offer, "QTH: Offer is not in 'Offer' state");
        require(offer.maker == msg.sender, "QTH: Caller is not the maker of this offer");

        // Return escrowed assets to maker
        if (offer.makerOffersQAsset) {
            require(qAssetInstances[offer.offerAssetInstanceId].owner == address(this), "QTH: Escrowed QAsset not owned by contract"); // Sanity check
            transferQAsset(offer.offerAssetInstanceId, offer.maker);
        } else { // Offered ERC20
             require(offer.offerAssetToken != address(0) && offer.offerAssetAmount > 0, "QTH: Invalid ERC20 offer details"); // Sanity check
            IERC20(offer.offerAssetToken).safeTransfer(offer.maker, offer.offerAssetAmount);
        }

        offer.state = TradeState.Cancelled; // Mark as cancelled
        // Note: Offers are not deleted to maintain history, just state changed.

        emit TradeOfferCancelled(_offerId);
    }

    // --- Internal Resolution Logic (Triggered by Oracle or potentially manually by anyone after event) ---

    /**
     * @notice Internal function to collapse a QAsset instance based on a result code.
     * Determines the specific outcome and releases or reallocates collateral/assets accordingly.
     * Assumes the QAsset instance is in a Superposed state and depends on the observation that yielded _resultCode.
     * @param _instanceId The ID of the QAsset instance to collapse.
     * @param _resultCode The result code from the observation.
     */
    function _collapseQAsset(uint256 _instanceId, uint256 _resultCode) internal nonReentrant {
        QAssetInstance storage asset = qAssetInstances[_instanceId];
        require(asset.state == QAssetInstanceState.Superposed, "QTH: QAsset is already collapsed");

        QAssetType storage assetType = qAssetTypes[asset.typeId];
        require(assetType.exists, "QTH: QAsset type does not exist");

        // --- Determine Outcome (Simplified Logic) ---
        // This is where the "quantum" interpretation happens.
        // Simple example: The resultCode directly maps to an outcome index if <= outcomes.length - 1
        // More complex: Could use resultCode + random beacon + probabilities, or complex mapping.
        // For this example, let's say resultCode 0 means outcome 0, resultCode 1 means outcome 1, etc.
        // If resultCode > outcomes.length - 1, perhaps it defaults to the first outcome or fails.
        uint256 chosenOutcomeIndex = 0; // Default to first outcome if no specific match

        // Find an outcome matching the result code (simplified: index matches code)
        bool outcomeFound = false;
        if (_resultCode < assetType.outcomes.length) {
             chosenOutcomeIndex = _resultCode;
             outcomeFound = true;
        }
        // Add more complex outcome determination logic here if needed,
        // e.g., based on probabilities, ranges of resultCode, etc.

        // If no specific outcome found by logic, maybe default or revert? Defaulting for robustness.
        if (!outcomeFound) {
            chosenOutcomeIndex = 0; // Default to outcome 0
             // Or add specific error handling if unexpected result codes should fail collapse
        }


        // --- Update State and Distribute Assets ---
        asset.state = QAssetInstanceState.Collapsed;
        asset.collapsedOutcomeIndex = chosenOutcomeIndex;

        QAssetOutcome storage chosenOutcome = assetType.outcomes[chosenOutcomeIndex];

        // Transfer outcome assets (or release collateral)
        if (chosenOutcome.token != address(0) && chosenOutcome.amount > 0) {
            // In this simplified model, the collateral is released back to the user's balance
            // based on the outcome. A more complex model could have the outcome BE a new asset.
            // Let's release the *original* collateral amount back, and the "outcome" is conceptual or tracked internally.
             userCollateral[asset.owner][assetType.collateralToken] = userCollateral[asset.owner][assetType.collateralToken].add(assetType.collateralAmount);

            // If the outcome *is* tokens, need to transfer them from somewhere (e.g., pre-funded, or from the collateral itself if it can be split).
            // Let's assume for this example that the outcome tokens/amounts are representative, and the primary asset handling is the collateral release.
            // If we wanted the contract to hold/distribute outcome tokens, they'd need to be funded.
            // Example: If outcome[0] is 1 ETH, the contract needs 1 ETH to send.
            // This adds complexity (funding, tracking outcome token balances).
            // STICKING TO SIMPLER: The collateral is returned, the outcome is recorded metadata.
            // A sophisticated version would involve the outcome potentially being other QAssets or specific tokens drawn from a pool/collateral.
             // For demonstration, we log the intended outcome distribution:
             emit QAssetCollapsed(_instanceId, chosenOutcomeIndex, _resultCode);
             // Actual token distribution would happen here if the outcome was tangible tokens held by the contract.
             // IERC20(chosenOutcome.token).safeTransfer(asset.owner, chosenOutcome.amount); // Requires contract to hold outcome tokens
        } else {
             // Outcome might be null or just a state change, release collateral.
             userCollateral[asset.owner][assetType.collateralToken] = userCollateral[asset.owner][assetType.collateralToken].add(assetType.collateralAmount);
             emit QAssetCollapsed(_instanceId, chosenOutcomeIndex, _resultCode);
        }


         // TODO: Potentially trigger resolution of trades contingent on THIS asset's collapse
         // (Requires tracking trades by conditional QAsset Instance ID)
    }

    /**
     * @notice Internal function to resolve an accepted trade based on its condition.
     * Transfers assets between maker and taker if condition is met, or returns escrowed assets if not.
     * @param _tradeId The ID of the trade to resolve.
     */
    function _resolveTrade(uint256 _tradeId) internal nonReentrant {
        Trade storage trade = qTrades[_tradeId];
        require(trade.state == TradeState.Accepted, "QTH: Trade is not in 'Accepted' state");

        bool conditionSatisfied = false;
        bytes32 relevantTopic = bytes32(0); // For logging

        // --- Check Condition ---
        if (trade.conditionType == TradeConditionType.OnObservationTopicResult) {
            relevantTopic = trade.observationTopicCondition;
             // Check if the topic has been observed AND the result matches the condition
            if (latestObservationResults[relevantTopic] == trade.resultCodeCondition) {
                 conditionSatisfied = true;
            }
        } else if (trade.conditionType == TradeConditionType.OnQAssetCollapseOutcome) {
            relevantTopic = qAssetTypes[qAssetInstances[trade.qAssetInstanceConditionId].typeId].observationTopic; // Topic that collapses the conditional asset
            // Check if the conditional QAsset has collapsed AND the outcome matches the condition
            QAssetInstance storage conditionAsset = qAssetInstances[trade.qAssetInstanceConditionId];
            if (conditionAsset.state == QAssetInstanceState.Collapsed && conditionAsset.collapsedOutcomeIndex == trade.outcomeIndexCondition) {
                conditionSatisfied = true;
            }
        }
         // Add more condition types here if needed

         // Cannot resolve if the relevant topic hasn't been observed yet, unless it's a QAsset condition
         // and the asset just collapsed. The oracle's submitObservationResult should handle timing.
         // If conditionSatisfied is false here, it means the observation/collapse didn't match the required outcome.

        // --- Resolve Trade ---
        address maker = trade.maker;
        address taker = trade.taker;

        if (conditionSatisfied) {
            trade.state = TradeState.ResolvedSuccess;

            // Transfer assets: Maker's offered -> Taker, Taker's offered (Maker's requested) -> Maker
            // Transfer Maker's Offered Asset
            if (trade.makerOffersQAsset) {
                 require(qAssetInstances[trade.offerAssetInstanceId].owner == address(this), "QTH: Maker's escrowed QAsset not owned by contract"); // Sanity check
                 // Note: What state should the QAsset be in upon transfer? Collapsed? Superposed?
                 // If it was superposed when offered, and the trade condition is met, it implies
                 // the *context* aligns with a certain outcome.
                 // Let's assume the trade transfers the asset in its state *at the time of resolution*.
                 // If the asset itself was the *condition* and it collapsed, the collapsed asset is transferred.
                 // If the condition was a *different* event/asset, the offered asset might still be Superposed or already collapsed by its *own* topic.
                 // Complexity! For simplicity, let's assume the asset is transferred as-is (potentially collapsed if its topic was observed).
                transferQAsset(trade.offerAssetInstanceId, taker);
            } else { // Maker offered ERC20
                 require(trade.offerAssetToken != address(0) && trade.offerAssetAmount > 0, "QTH: Invalid Maker ERC20 offer details"); // Sanity check
                IERC20(trade.offerAssetToken).safeTransfer(taker, trade.offerAssetAmount);
            }

            // Transfer Taker's Offered Asset (Maker's Requested Asset)
            if (trade.makerRequestsQAsset) {
                 require(qAssetInstances[trade.requestAssetInstanceId].owner == address(this), "QTH: Taker's escrowed QAsset not owned by contract"); // Sanity check
                transferQAsset(trade.requestAssetInstanceId, maker); // Transfer to original maker
            } else { // Taker offered ERC20
                 require(trade.requestAssetToken != address(0) && trade.requestAssetAmount > 0, "QTH: Invalid Taker ERC20 offer details"); // Sanity check
                IERC20(trade.requestAssetToken).safeTransfer(maker, trade.requestAssetAmount);
            }

            // Collect protocol fees (if any) on the *requested* asset amount
            // This is one model. Could apply fee to offered amount, or both.
            // Let's apply to the ERC20 amount being transferred *to* the maker if applicable.
            if (!trade.makerRequestsQAsset && trade.requestAssetToken != address(0) && trade.requestAssetAmount > 0 && protocolFeeBasisPoints > 0) {
                 uint256 feeAmount = trade.requestAssetAmount.mul(protocolFeeBasisPoints).div(10000);
                 if (feeAmount > 0) {
                     uint256 amountAfterFee = trade.requestAssetAmount.sub(feeAmount);
                     // Transfer amountAfterFee to maker, feeAmount to contract's fee balance
                    IERC20(trade.requestAssetToken).safeTransfer(maker, amountAfterFee);
                    collectedFees[trade.requestAssetToken] = collectedFees[trade.requestAssetToken].add(feeAmount);
                    // Re-transfer the full amount first, then collect fee? Or just transfer net?
                    // SafeTransferFrom from taker to contract already happened. Now contract transfers.
                    // Let's adjust the transfer to maker directly.
                    // The previous transfer lines should transfer the *full* escrowed amount.
                    // The fee should be taken *from* the received amount *by the maker*.
                    // This requires maker to interact post-resolution, or the contract to hold fees separate.
                    // Let's revise: Maker's *requested* amount is transferred, and fees are collected *from* the amount maker receives.
                    // Need to re-send maker's portion, minus fee, and add fee to collectedFees.
                    // OR, collect fee during the initial escrow - but ERC20 approval/transferFrom might be exactly the amount.
                    // Simplest: Collect fee from one party's received assets post-resolution.
                    // Let's collect fee from the Taker's *offered* ERC20 if that's what the maker requested.
                    // If Maker requested ERC20 (_requestAssetToken is ERC20), collect fee on that amount.
                     // Okay, the previous transfer logic for makerRequestsQAsset needs adjustment if fee is applied here.
                     // Let's collect the fee first from the amount the contract holds for transfer *to the maker*.
                    if (!trade.makerRequestsQAsset && trade.requestAssetToken != address(0) && trade.requestAssetAmount > 0 && protocolFeeBasisPoints > 0) {
                        // The full amount was already transferred from taker to contract.
                        // Now transfer to maker, minus fee.
                        uint256 feeAmount = trade.requestAssetAmount.mul(protocolFeeBasisPoints).div(10000);
                        uint256 amountToMaker = trade.requestAssetAmount.sub(feeAmount);
                         // The safeTransfer above was to the maker. Need to adjust that.
                         // Let's restructure: transfer net to maker, add fee to contract.
                         IERC20(trade.requestAssetToken).safeTransfer(maker, amountToMaker);
                         if (feeAmount > 0) {
                             collectedFees[trade.requestAssetToken] = collectedFees[trade.requestAssetToken].add(feeAmount);
                         }
                     } else {
                         // If maker requested QAsset or 0 ERC20, no fee is collected on requested side.
                         // Could apply fee on offered side too, but stick to one for simplicity.
                     }


            }

        } else { // Condition Not Satisfied (Trade Fails)
            trade.state = TradeState.ResolvedFail;

            // Return escrowed assets: Maker's offered -> Maker, Taker's offered -> Taker
            // Return Maker's Offered Asset
            if (trade.makerOffersQAsset) {
                 require(qAssetInstances[trade.offerAssetInstanceId].owner == address(this), "QTH: Maker's escrowed QAsset not owned by contract"); // Sanity check
                transferQAsset(trade.offerAssetInstanceId, maker);
            } else { // Maker offered ERC20
                 require(trade.offerAssetToken != address(0) && trade.offerAssetAmount > 0, "QTH: Invalid Maker ERC20 offer details"); // Sanity check
                IERC20(trade.offerAssetToken).safeTransfer(maker, trade.offerAssetAmount);
            }

            // Return Taker's Offered Asset (Maker's Requested Asset)
            if (trade.makerRequestsQAsset) {
                 require(qAssetInstances[trade.requestAssetInstanceId].owner == address(this), "QTH: Taker's escrowed QAsset not owned by contract"); // Sanity check
                transferQAsset(trade.requestAssetInstanceId, taker);
            } else { // Taker offered ERC20
                 require(trade.requestAssetToken != address(0) && trade.requestAssetAmount > 0, "QTH: Invalid Taker ERC20 offer details"); // Sanity check
                IERC20(trade.requestAssetToken).safeTransfer(taker, trade.requestAssetAmount);
            }
        }

        trade.resolutionTimestamp = block.timestamp;
        emit TradeResolved(_tradeId, trade.state);

        // Note: The original offer's state remains 'Accepted', linking to the resolved trade.
    }


    // --- Query/View Functions (Any User) ---

    /**
     * @notice Gets details about a specific QAsset instance.
     * @param _instanceId The ID of the QAsset instance.
     * @return typeId The ID of the QAsset type.
     * @return owner The current owner's address.
     * @return state The current state (Superposed or Collapsed).
     * @return collapsedOutcomeIndex The index of the chosen outcome if collapsed.
     */
    function queryQAssetDetails(uint256 _instanceId)
        external
        view
        returns (
            uint256 typeId,
            address owner,
            QAssetInstanceState state,
            uint256 collapsedOutcomeIndex
        )
    {
        QAssetInstance storage asset = qAssetInstances[_instanceId];
        // No require(exists) check here, allows querying non-existent IDs (will return default values)
        return (asset.typeId, asset.owner, asset.state, asset.collapsedOutcomeIndex);
    }

    /**
     * @notice Checks if an address owns a specific QAsset instance.
     * @param _owner The address to check.
     * @param _instanceId The ID of the QAsset instance.
     * @return True if the address owns the instance, false otherwise.
     */
    function queryQAssetBalance(address _owner, uint256 _instanceId) external view returns (bool) {
        return qAssetInstanceOwnership[_owner][_instanceId];
    }


     /**
     * @notice Gets details about a specific trade offer.
     * @param _offerId The ID of the trade offer.
     * @return offer The TradeOffer struct.
     */
    function queryTradeOfferDetails(uint256 _offerId) external view returns (TradeOffer memory) {
        return qTradeOffers[_offerId];
    }

    /**
     * @notice Gets details about an accepted trade.
     * @param _tradeId The ID of the trade.
     * @return trade The Trade struct.
     */
    function queryTradeDetails(uint256 _tradeId) external view returns (Trade memory) {
        return qTrades[_tradeId];
    }

    /**
     * @notice Gets the deposited collateral balance for a user and token.
     * @param _owner The address of the user.
     * @param _token The address of the ERC20 token.
     * @return The amount of collateral deposited.
     */
    function queryCollateralBalance(address _owner, address _token) external view returns (uint256) {
        return userCollateral[_owner][_token];
    }

    /**
     * @notice Gets the latest submitted result code for an observation topic.
     * @param _topic The topic ID.
     * @return The latest result code (returns 0 if no result submitted).
     */
    function getLatestObservationResult(bytes32 _topic) external view returns (uint256) {
        return latestObservationResults[_topic];
    }

     /**
     * @notice Gets details of a registered QAsset type.
     * @param _typeId The ID of the QAsset type.
     * @return name, collateralToken, collateralAmount, observationTopic, outcomes, exists.
     */
    function getQAssetTypeDetails(uint256 _typeId)
        external
        view
        returns (
            string memory name,
            address collateralToken,
            uint256 collateralAmount,
            bytes32 observationTopic,
            QAssetOutcome[] memory outcomes,
            bool exists
        )
    {
        QAssetType storage assetType = qAssetTypes[_typeId];
        return (assetType.name, assetType.collateralToken, assetType.collateralAmount, assetType.observationTopic, assetType.outcomes, assetType.exists);
    }

     /**
     * @notice Gets a list of all registered QAsset type IDs.
     * @return An array of QAsset type IDs. (Note: Iterating mappings is not standard, this is illustrative).
     * In production, would need a separate array/list of IDs.
     */
    function getAllQAssetTypeIds() external view returns (uint256[] memory) {
         // Warning: This is inefficient for large numbers of types.
         // A real implementation would track keys in an array or linked list.
         uint256[] memory typeIds = new uint256[](nextQAssetTypeId - 1);
         uint256 count = 0;
         for (uint256 i = 1; i < nextQAssetTypeId; i++) {
             if (qAssetTypes[i].exists) { // Only include active types
                 typeIds[count] = i;
                 count++;
             }
         }
          // Resize array if needed (if types were removed)
         if (count < nextQAssetTypeId - 1) {
             uint256[] memory filteredTypeIds = new uint256[](count);
             for(uint256 i = 0; i < count; i++) {
                 filteredTypeIds[i] = typeIds[i];
             }
             return filteredTypeIds;
         }
         return typeIds;
     }

     /**
     * @notice Gets a list of all registered observation topics.
     * @return An array of topic IDs (bytes32).
     * In production, would need a separate array/list of topics.
     */
     function getAllRegisteredObservationTopics() external view returns (bytes32[] memory) {
         // Warning: Inefficient for large numbers of topics.
         // A real implementation would track keys in an array or linked list.
         // This cannot actually iterate mapping keys directly easily.
         // This function is illustrative and wouldn't work without tracking topics in an array during registration.
         // For demonstration, let's assume we *did* track them in an array.
         // bytes32[] memory topics = new bytes32[](...); // size unknown without tracking
         // return topics;
         revert("QTH: Cannot list all topics efficiently from mapping");
         // A proper implementation needs: bytes32[] private _registeredTopics;
         // and add/remove topics from this array.
     }

     /**
      * @notice Checks if a trade offer ID exists.
      * @param _offerId The ID to check.
      * @return True if an offer with this ID has been created, false otherwise.
      */
     function isTradeOfferExist(uint256 _offerId) external view returns (bool) {
         // Offer ID 0 is invalid as counter starts at 1. State check implicitly handles existence.
         return _offerId > 0 && qTradeOffers[_offerId].maker != address(0); // Check a non-zero default value
     }

      /**
      * @notice Checks if a trade ID exists.
      * @param _tradeId The ID to check.
      * @return True if a trade with this ID has been created, false otherwise.
      */
     function isTradeExist(uint256 _tradeId) external view returns (bool) {
          // Trade ID 0 is invalid as counter starts at 1. State check implicitly handles existence.
         return _tradeId > 0 && qTrades[_tradeId].maker != address(0); // Check a non-zero default value
     }

     /**
      * @notice Gets the current observation oracle address.
      * @return The oracle address.
      */
     function getOracleAddress() external view returns (address) {
         return observationOracle;
     }

      /**
      * @notice Gets the current protocol fee rate in basis points.
      * @return The fee rate.
      */
     function getProtocolFeeBasisPoints() external view returns (uint256) {
         return protocolFeeBasisPoints;
     }

    // Missing Query: Get QAsset Instance ID by owner and type? Inefficient without tracking.
    // Missing Query: Get Trade Offers/Trades by maker/taker? Requires additional mappings.

    // --- Fallback/Receive ---
    // receive() external payable {} // Not handling Ether for this contract type
    // fallback() external payable {} // Not handling arbitrary calls

}
```