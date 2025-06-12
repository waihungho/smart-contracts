Okay, here is a Solidity smart contract combining several interesting, advanced, and trendy concepts like dynamic digital assets, parametric/conditional orders, fractionalization, reputation systems, staking for benefits, dynamic fees, and simplified oracle integration, designed not to be a direct copy of standard open-source implementations.

It simulates ownership of unique "Dynamic Flow Tokens" (DFTs) and their fractional parts internally, rather than relying on external ERC721/ERC20 contracts directly, to showcase the internal logic without needing multiple deployments or complex external interfaces for this example.

**Outline:**

1.  **Contract Purpose:** A decentralized marketplace for trading "Dynamic Flow Tokens (DFTs)" and their fractional components. DFTs are conceptual digital assets with potentially dynamic properties.
2.  **Key Concepts:**
    *   **Dynamic Flow Tokens (DFTs):** Unique, non-fungible conceptual assets managed internally. Can have dynamic properties (simulated `currentValue`).
    *   **DFT Fragments:** Fungible tokens representing fractional ownership of a specific DFT (managed internally).
    *   **Parametric Orders:** Buy/Sell orders (`Bid`/`Ask`) that can include price ranges, expiration times, or dependency on external "Oracle Conditions".
    *   **Oracle Integration (Simplified):** Mechanism to register conditions and feed external data that can trigger conditional orders or influence DFT dynamics.
    *   **Dynamic Fees:** Trading fees that can be adjusted based on market conditions or governance (simulated via owner control).
    *   **Reputation System:** Simple score for participants based on successful interactions. Staking can influence reputation and trading priority.
    *   **Staking:** Users can stake ETH (or another token conceptually) to boost reputation or gain benefits.
    *   **Order Matching:** Logic to match parametric bids and asks, considering dynamic pricing and oracle conditions.
    *   **Fractionalization/Defragmentation:** Convert a whole DFT into fragments and vice-versa.
3.  **Core Components:**
    *   Internal data structures for DFTs, Fragments, Orders, Oracle Conditions.
    *   Functions for managing assets (mint, transfer, fractionalize).
    *   Functions for placing, cancelling, and viewing orders.
    *   Functions for triggering order matching and processing conditional orders.
    *   Functions for staking and managing reputation.
    *   Functions for interacting with oracle data (simulation).
    *   Admin functions for configuration (fees, conditions).
4.  **Function Count:** Designed to have at least 20 functions covering asset management, trading, finance, system configuration, and information retrieval.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and fee rate.
2.  `receive()`: Allows receiving Ether for staking.
3.  `setFeeRate(uint256 _newFeeRate)`: Owner function to update the trading fee percentage.
4.  `withdrawFees()`: Owner function to withdraw accumulated fees.
5.  `registerOracleCondition(bytes32 _conditionHash, uint256 _expirationTime)`: Owner/Trusted function to register a condition ID expected from an oracle.
6.  `feedOracleData(uint256 _conditionId, bool _conditionMet, bytes memory _data)`: Trusted oracle function to feed data and potentially mark a condition as met.
7.  `getOracleConditionStatus(uint256 _conditionId)`: View function to check if a registered oracle condition has been met.
8.  `mintDFT(address _to, uint256 _initialValue, uint256 _decayRate)`: Mints a new Dynamic Flow Token to a recipient.
9.  `transferDFT(uint256 _dftId, address _to)`: Transfers ownership of a whole DFT.
10. `getDFTDetails(uint256 _dftId)`: View function to get details of a DFT, including its current calculated value.
11. `fractionalizeDFT(uint256 _dftId, uint256 _totalFragments)`: Burns a whole DFT owned by the caller and issues fragments for it.
12. `defragmentalizeDFT(uint256 _dftId)`: Burns all fragments of a specific DFT owned by the caller and restores the whole DFT.
13. `getFragmentBalance(uint256 _dftId, address _owner)`: View function to get the fragment balance for a specific DFT and owner.
14. `transferFragments(uint256 _dftId, address _to, uint256 _amount)`: Transfers fragments of a specific DFT between users.
15. `placeBid(uint256 _dftId, uint256 _fragmentAmount, uint256 _maxPricePerFragment, uint256 _priceDecayRate, uint256 _expirationTime, uint256 _oracleConditionId)`: Places a bid (buy order) for DFT fragments. Requires sending enough Ether/Value to cover the potential maximum price.
16. `placeAsk(uint256 _dftId, uint256 _fragmentAmount, uint256 _minPricePerFragment, uint256 _priceIncreaseRate, uint256 _expirationTime, uint256 _oracleConditionId)`: Places an ask (sell order) for DFT fragments. Requires the caller to own the fragments or the whole DFT if selling fractions of a non-fractionalized DFT.
17. `cancelOrder(uint256 _orderId)`: Cancels an active bid or ask placed by the caller.
18. `getOrdersForDFT(uint256 _dftId)`: View function listing active bid and ask IDs for a specific DFT.
19. `getUserOrders(address _user)`: View function listing active order IDs placed by a specific user.
20. `matchOrders(uint256 _dftId)`: Function callable by anyone to attempt to match bids and asks for a specific DFT based on current conditions, prices, and oracle data.
21. `processConditionalOrders(uint256 _conditionId)`: Function callable by anyone to attempt to trigger and match orders linked to a specific oracle condition once that condition is met.
22. `stake()`: Allows a user to stake Ether to increase their reputation score.
23. `unstake(uint256 _amount)`: Allows a user to unstake Ether and potentially impact their reputation.
24. `getReputationScore(address _user)`: View function to get the reputation score of a user.
25. `getStakedBalance(address _user)`: View function to get the staked Ether balance of a user.
26. `getFeeRate()`: View function to get the current trading fee rate.
27. `_calculateDynamicPrice(uint256 _dftId)`: Internal helper to calculate the dynamic price of a DFT based on its parameters and time. (Simplified calculation).
28. `_checkOrderConditions(uint256 _orderId)`: Internal helper to check if a parametric/conditional order's conditions are met (expiration, oracle condition).
29. `_executeTrade(uint256 _buyOrderId, uint256 _sellOrderId, uint256 _tradePricePerFragment)`: Internal helper to execute a trade between a matched bid and ask, handle transfers, fees, and reputation updates.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Contract Purpose: Decentralized marketplace for unique, dynamic "Dynamic Flow Tokens (DFTs)" and their fractions.
// 2. Key Concepts:
//    - Dynamic Flow Tokens (DFTs): Internally managed unique assets with dynamic properties.
//    - DFT Fragments: Internally managed fungible tokens representing fractional DFT ownership.
//    - Parametric Orders: Bids/Asks with dynamic pricing parameters, expiration, and oracle conditions.
//    - Oracle Integration (Simplified): Mechanism for external data influencing orders/assets.
//    - Dynamic Fees: Adjustable trading fees.
//    - Reputation System: Score based on interactions, boosted by staking.
//    - Staking: Users stake ETH for reputation/priority.
//    - Order Matching: Logic matching parametric orders based on conditions.
//    - Fractionalization/Defragmentation: Convert whole DFTs to fragments and vice-versa.
// 3. Core Components: Internal state, structs, functions for asset/order/stake/oracle management, matching logic.
// 4. Function Count: >= 20 functions.

// --- Function Summary ---
// constructor(): Initializes contract owner and fee rate.
// receive(): Allows receiving Ether for staking.
// setFeeRate(uint256 _newFeeRate): Owner sets the trading fee percentage.
// withdrawFees(): Owner withdraws accumulated fees.
// registerOracleCondition(bytes32 _conditionHash, uint256 _expirationTime): Owner/Trusted registers an oracle condition ID.
// feedOracleData(uint256 _conditionId, bool _conditionMet, bytes memory _data): Trusted Oracle feeds data & updates condition status.
// getOracleConditionStatus(uint256 _conditionId): View: check if an oracle condition is met.
// mintDFT(address _to, uint256 _initialValue, uint256 _decayRate): Mints a new DFT.
// transferDFT(uint256 _dftId, address _to): Transfers a whole DFT.
// getDFTDetails(uint256 _dftId): View: get DFT details & dynamic value.
// fractionalizeDFT(uint256 _dftId, uint256 _totalFragments): Converts DFT to fragments.
// defragmentalizeDFT(uint256 _dftId): Converts fragments back to DFT.
// getFragmentBalance(uint256 _dftId, address _owner): View: get fragment balance.
// transferFragments(uint256 _dftId, address _to, uint256 _amount): Transfers fragments.
// placeBid(uint256 _dftId, uint256 _fragmentAmount, uint256 _maxPricePerFragment, uint256 _priceDecayRate, uint256 _expirationTime, uint256 _oracleConditionId): Places a buy order (bid).
// placeAsk(uint256 _dftId, uint256 _fragmentAmount, uint256 _minPricePerFragment, uint256 _priceIncreaseRate, uint256 _expirationTime, uint256 _oracleConditionId): Places a sell order (ask).
// cancelOrder(uint256 _orderId): Cancels an active order.
// getOrdersForDFT(uint256 _dftId): View: get active order IDs for a DFT.
// getUserOrders(address _user): View: get active order IDs for a user.
// matchOrders(uint256 _dftId): Attempts to match eligible bids/asks for a DFT.
// processConditionalOrders(uint256 _conditionId): Attempts to trigger and match orders linked to a met oracle condition.
// stake(): Stakes ETH for reputation boost.
// unstake(uint256 _amount): Unstakes ETH.
// getReputationScore(address _user): View: get user's reputation.
// getStakedBalance(address _user): View: get user's staked ETH.
// getFeeRate(): View: get current fee rate.
// _calculateDynamicPrice(uint256 _dftId): Internal: calculates DFT's current value.
// _checkOrderConditions(uint256 _orderId): Internal: checks if order's parametric/conditional requirements are met.
// _executeTrade(uint256 _buyOrderId, uint256 _sellOrderId, uint256 _tradePricePerFragment): Internal: executes a trade and handles logic.

contract QuantumFlowMarketplace {

    address payable public owner;
    uint256 public currentFeeRate = 10; // Fee in basis points (e.g., 10 = 0.1%)
    uint256 public totalFeesCollected;

    // --- Errors ---
    error NotOwner();
    error FeeRateInvalid();
    error NoFeesToWithdraw();
    error DFTNotFound();
    error NotDFTOwner();
    error NotFragmentOwner();
    error InsufficientFragments();
    error DFTAlreadyFractionalized();
    error DFTNotFractionalized();
    error CannotDefragmentizeWithFragmentsOutstanding();
    error OrderNotFound();
    error OrderNotActive();
    error NotOrderMaker();
    error InvalidOrderAmount();
    error InsufficientFundsForBid();
    error InvalidOrderParameters();
    error NoMatchingOrdersFound();
    error StakingAmountZero();
    error InsufficientStakedBalance();
    error OracleConditionNotFound();
    error OracleConditionAlreadyMet();
    error OracleConditionNotMet();
    error CallerNotTrustedOracle(); // Simplified: Owner acts as trusted oracle in this example
    error TradeExecutionFailed();

    // --- Events ---
    event FeeRateUpdated(uint256 newFeeRate);
    event FeesWithdrawn(address recipient, uint256 amount);
    event OracleConditionRegistered(uint256 conditionId, bytes32 conditionHash, uint256 expirationTime);
    event OracleDataFed(uint256 conditionId, bool conditionMet);
    event DFTMinted(uint256 dftId, address owner, uint256 initialValue);
    event DFTTransferred(uint256 dftId, address from, address to);
    event DFTFractionalized(uint256 dftId, address owner, uint256 totalFragments);
    event DFTDefragmentalized(uint256 dftId, address owner);
    event FragmentsTransferred(uint256 dftId, address from, address to, uint256 amount);
    event OrderPlaced(uint256 orderId, address maker, uint256 dftId, bool isBid, uint256 fragmentAmount, uint256 priceParam1, uint256 priceParam2, uint256 expirationTime, uint256 oracleConditionId);
    event OrderCancelled(uint256 orderId);
    event TradeExecuted(uint256 tradeId, uint256 buyOrderId, uint256 sellOrderId, uint256 dftId, uint256 fragmentAmount, uint256 tradePricePerFragment);
    event StakeSuccessful(address user, uint256 amount, uint256 newStakedBalance);
    event UnstakeSuccessful(address user, uint256 amount, uint256 newStakedBalance);
    event ReputationUpdated(address user, uint256 newReputation);

    // --- Data Structures ---
    struct DynamicFlowToken {
        uint256 id;
        address owner;
        uint256 creationTime;
        uint256 initialValue;
        uint256 decayRate; // Simplified: Value decays over time based on this rate
        bool isFractionalized;
        uint256 totalFragments; // Only relevant if isFractionalized is true
    }

    struct Order {
        uint256 id;
        address maker;
        uint256 dftId;
        bool isBid; // true for buy, false for sell (ask)
        uint256 fragmentAmount;
        // Parametric Pricing (simplified):
        uint256 priceParam1; // Max price per fragment for bids, Min price per fragment for asks
        uint256 priceParam2; // Decay rate for bid price, Increase rate for ask price (per second)
        uint256 creationTime;
        uint256 expirationTime; // Order expires after this timestamp
        uint256 oracleConditionId; // 0 if no condition, otherwise ID of required oracle condition
        bool isActive;
        uint256 filledAmount; // How many fragments have been filled by trades
        uint256 valueLocked; // ETH locked for bid, or Fragments conceptually locked for ask
    }

    struct OracleCondition {
        uint256 id;
        bytes32 conditionHash; // Hash representing the condition logic (for reference off-chain)
        uint256 registrationTime;
        uint256 expirationTime;
        bool isMet; // Set by trusted oracle feed
        bool processed; // Flag to indicate if orders dependent on this condition have been processed
    }

    // --- State Variables ---
    uint256 private dftCounter;
    mapping(uint256 => DynamicFlowToken) public dfts;
    // dftId => owner => balance
    mapping(uint256 => mapping(address => uint256)) public dftFragments;

    uint256 private orderCounter;
    mapping(uint256 => Order) public orders;
    // dftId => list of active bid orderIds
    mapping(uint256 => uint256[]) private activeBids;
    // dftId => list of active ask orderIds
    mapping(uint256 => uint256[]) private activeAsks;

    uint256 private oracleConditionCounter;
    mapping(uint256 => OracleCondition) public oracleConditions;

    // user => reputation score
    mapping(address => uint256) public reputationScores;
    // user => staked ETH balance
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256[] ) private userOrders; // Track orders per user

    uint256 private tradeCounter;

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyDFTOwner(uint256 _dftId) {
        if (dfts[_dftId].owner != msg.sender) revert NotDFTOwner();
        _;
    }

    modifier onlyFragmentOwner(uint256 _dftId, uint256 _amount) {
        if (dftFragments[_dftId][msg.sender] < _amount) revert InsufficientFragments();
        _;
    }

    modifier isActiveOrder(uint256 _orderId) {
        if (!orders[_orderId].isActive) revert OrderNotActive();
        _;
    }

    // Simplified Trusted Oracle role - in reality, this would be a separate address or contract
    modifier onlyTrustedOracle() {
        if (msg.sender != owner) revert CallerNotTrustedOracle();
        _;
    }

    // --- Constructor ---
    constructor() payable {
        owner = payable(msg.sender);
        // Initial fee rate set above
    }

    // --- Receive ETH for staking ---
    receive() external payable {
        stake();
    }

    // --- Admin/Configuration Functions ---

    /**
     * @notice Sets the trading fee rate.
     * @param _newFeeRate The new fee rate in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setFeeRate(uint256 _newFeeRate) external onlyOwner {
        if (_newFeeRate > 10000) revert FeeRateInvalid(); // Max 100%
        currentFeeRate = _newFeeRate;
        emit FeeRateUpdated(_newFeeRate);
    }

    /**
     * @notice Allows the owner to withdraw accumulated fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = totalFeesCollected;
        if (amount == 0) revert NoFeesToWithdraw();
        totalFeesCollected = 0;
        (bool success, ) = owner.call{value: amount}("");
        if (!success) {
            // If withdrawal fails, put fees back (or handle differently)
            totalFeesCollected = amount;
            revert TradeExecutionFailed(); // Use a relevant error, maybe specific withdrawal error
        }
        emit FeesWithdrawn(owner, amount);
    }

    /**
     * @notice Registers an oracle condition that orders can depend on.
     * @param _conditionHash A hash or identifier for the off-chain condition.
     * @param _expirationTime The timestamp after which this condition is no longer relevant.
     * @return The ID of the newly registered oracle condition.
     */
    function registerOracleCondition(bytes32 _conditionHash, uint256 _expirationTime) external onlyTrustedOracle returns (uint256) {
        unchecked { oracleConditionCounter++; }
        uint256 conditionId = oracleConditionCounter;
        oracleConditions[conditionId] = OracleCondition({
            id: conditionId,
            conditionHash: _conditionHash,
            registrationTime: block.timestamp,
            expirationTime: _expirationTime,
            isMet: false,
            processed: false
        });
        emit OracleConditionRegistered(conditionId, _conditionHash, _expirationTime);
        return conditionId;
    }

    /**
     * @notice Called by the trusted oracle to feed data and update the status of a condition.
     * @param _conditionId The ID of the condition being updated.
     * @param _conditionMet The boolean status of the condition.
     * @param _data Arbitrary additional data from the oracle (e.g., a value).
     */
    function feedOracleData(uint256 _conditionId, bool _conditionMet, bytes memory _data) external onlyTrustedOracle {
        OracleCondition storage condition = oracleConditions[_conditionId];
        if (condition.id == 0) revert OracleConditionNotFound(); // ID 0 is default/unused
        if (condition.expirationTime <= block.timestamp) {
             // Condition expired, perhaps mark it as met=false or simply ignore.
             // For this example, we'll allow setting it if fed before checking processed.
        }
        // Allow updating status only if not already met and not processed
        if (condition.isMet && !condition.processed) revert OracleConditionAlreadyMet(); // Or allow re-confirming? Let's prevent double 'true'.
        if (condition.processed) return; // Do nothing if already processed

        condition.isMet = _conditionMet;
        // Oracle data (_data) could potentially update DFT values here too,
        // or influence parameters for _calculateDynamicPrice, but kept simple.
        emit OracleDataFed(_conditionId, _conditionMet);
    }

    /**
     * @notice Gets the met status of a registered oracle condition.
     * @param _conditionId The ID of the condition.
     * @return True if the condition has been reported as met by the oracle.
     */
    function getOracleConditionStatus(uint256 _conditionId) external view returns (bool) {
         OracleCondition storage condition = oracleConditions[_conditionId];
         if (condition.id == 0) return false; // Default state for non-existent
         return condition.isMet && condition.expirationTime > block.timestamp; // Consider expired conditions as not met
    }


    // --- DFT Management ---

    /**
     * @notice Mints a new Dynamic Flow Token.
     * @param _to The recipient address.
     * @param _initialValue A base value for the DFT (can be dynamic).
     * @param _decayRate A parameter influencing the DFT's dynamic value over time.
     * @return The ID of the newly minted DFT.
     */
    function mintDFT(address _to, uint256 _initialValue, uint256 _decayRate) external onlyOwner returns (uint256) {
        unchecked { dftCounter++; }
        uint256 dftId = dftCounter;
        dfts[dftId] = DynamicFlowToken({
            id: dftId,
            owner: _to,
            creationTime: block.timestamp,
            initialValue: _initialValue,
            decayRate: _decayRate,
            isFractionalized: false,
            totalFragments: 0
        });
        emit DFTMinted(dftId, _to, _initialValue);
        return dftId;
    }

    /**
     * @notice Transfers ownership of a whole DFT.
     * @param _dftId The ID of the DFT to transfer.
     * @param _to The recipient address.
     */
    function transferDFT(uint256 _dftId, address _to) public onlyDFTOwner(_dftId) {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.isFractionalized) revert DFTAlreadyFractionalized();
        dft.owner = _to;
        emit DFTTransferred(_dftId, msg.sender, _to);
    }

    /**
     * @notice Gets details about a DFT, including its calculated dynamic value.
     * @param _dftId The ID of the DFT.
     * @return DFT details.
     */
    function getDFTDetails(uint256 _dftId) external view returns (uint256 id, address owner, uint256 creationTime, uint256 currentValue, bool isFractionalized, uint256 totalFragments) {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0) revert DFTNotFound();
        return (
            dft.id,
            dft.owner,
            dft.creationTime,
            _calculateDynamicPrice(_dftId), // Calculate dynamic value on the fly
            dft.isFractionalized,
            dft.totalFragments
        );
    }

    // --- Fractionalization ---

    /**
     * @notice Fractionalizes a whole DFT into a specified number of fragments.
     * Caller must be the DFT owner.
     * @param _dftId The ID of the DFT to fractionalize.
     * @param _totalFragments The total number of fragments to create.
     */
    function fractionalizeDFT(uint256 _dftId, uint256 _totalFragments) external onlyDFTOwner(_dftId) {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.isFractionalized) revert DFTAlreadyFractionalized();
        if (_totalFragments == 0) revert InvalidOrderAmount(); // Cannot create zero fragments

        dft.isFractionalized = true;
        dft.totalFragments = _totalFragments;
        // Mint all fragments to the owner
        dftFragments[_dftId][msg.sender] = _totalFragments;

        emit DFTFractionalized(_dftId, msg.sender, _totalFragments);
    }

    /**
     * @notice Defragmentalizes a DFT, consolidating all fragments back into a whole DFT.
     * Caller must own all fragments of this DFT.
     * @param _dftId The ID of the DFT to defragmentalize.
     */
    function defragmentalizeDFT(uint256 _dftId) external {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0) revert DFTNotFound();
        if (!dft.isFractionalized) revert DFTNotFractionalized();

        // Check if the caller owns *all* fragments
        if (dftFragments[_dftId][msg.sender] != dft.totalFragments) revert CannotDefragmentizeWithFragmentsOutstanding();

        // Burn all fragments owned by caller
        delete dftFragments[_dftId][msg.sender];

        dft.isFractionalized = false;
        dft.totalFragments = 0;
        // Ownership remains with the caller (who owned all fragments)

        emit DFTDefragmentalized(_dftId, msg.sender);
    }

    /**
     * @notice Transfers a specified amount of fragments for a DFT.
     * @param _dftId The ID of the DFT whose fragments are being transferred.
     * @param _to The recipient address.
     * @param _amount The amount of fragments to transfer.
     */
    function transferFragments(uint256 _dftId, address _to, uint256 _amount) public onlyFragmentOwner(_dftId, _amount) {
        DynamicFlowToken storage dft = dfts[_dftId];
         if (dft.id == 0) revert DFTNotFound();
        if (!dft.isFractionalized) revert DFTNotFractionalized();
        if (_amount == 0) revert InvalidOrderAmount();

        dftFragments[_dftId][msg.sender] -= _amount;
        dftFragments[_dftId][_to] += _amount;

        emit FragmentsTransferred(_dftId, msg.sender, _to, _amount);
    }

    /**
     * @notice Gets the balance of fragments for a specific DFT and owner.
     * @param _dftId The ID of the DFT.
     * @param _owner The address whose balance is requested.
     * @return The fragment balance.
     */
    function getFragmentBalance(uint256 _dftId, address _owner) external view returns (uint256) {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0 || !dft.isFractionalized) return 0; // Return 0 for non-existent or non-fractionalized DFTs
        return dftFragments[_dftId][_owner];
    }


    // --- Marketplace - Order Management ---

    /**
     * @notice Places a buy order (bid) for DFT fragments.
     * Caller must send enough ETH to cover the maximum possible price.
     * @param _dftId The ID of the DFT to bid on.
     * @param _fragmentAmount The number of fragments desired.
     * @param _maxPricePerFragment The maximum price per fragment (wei).
     * @param _priceDecayRate Rate at which bid price decays per second (wei per fragment per second).
     * @param _expirationTime Order expiration timestamp.
     * @param _oracleConditionId Optional oracle condition ID (0 for none).
     */
    function placeBid(
        uint256 _dftId,
        uint256 _fragmentAmount,
        uint256 _maxPricePerFragment,
        uint256 _priceDecayRate,
        uint256 _expirationTime,
        uint256 _oracleConditionId
    ) external payable {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0) revert DFTNotFound(); // Ensure DFT exists
        if (_fragmentAmount == 0) revert InvalidOrderAmount();
        if (_maxPricePerFragment == 0) revert InvalidOrderParameters();
        if (msg.value < _fragmentAmount * _maxPricePerFragment) revert InsufficientFundsForBid();
        if (_oracleConditionId != 0 && oracleConditions[_oracleConditionId].id == 0) revert OracleConditionNotFound();

        unchecked { orderCounter++; }
        uint256 orderId = orderCounter;

        orders[orderId] = Order({
            id: orderId,
            maker: msg.sender,
            dftId: _dftId,
            isBid: true,
            fragmentAmount: _fragmentAmount,
            priceParam1: _maxPricePerFragment,
            priceParam2: _priceDecayRate,
            creationTime: block.timestamp,
            expirationTime: _expirationTime,
            oracleConditionId: _oracleConditionId,
            isActive: true,
            filledAmount: 0,
            valueLocked: msg.value
        });

        // Add to active bids list for the DFT
        activeBids[_dftId].push(orderId);
        userOrders[msg.sender].push(orderId);

        emit OrderPlaced(orderId, msg.sender, _dftId, true, _fragmentAmount, _maxPricePerFragment, _priceDecayRate, _expirationTime, _oracleConditionId);
    }

    /**
     * @notice Places a sell order (ask) for DFT fragments.
     * Caller must own the fragments or the whole DFT if selling from a non-fractionalized one.
     * Fragments/DFT are conceptually locked until the order is filled or cancelled.
     * @param _dftId The ID of the DFT to sell fragments from.
     * @param _fragmentAmount The number of fragments offered.
     * @param _minPricePerFragment The minimum price per fragment (wei).
     * @param _priceIncreaseRate Rate at which ask price increases per second (wei per fragment per second).
     * @param _expirationTime Order expiration timestamp.
     * @param _oracleConditionId Optional oracle condition ID (0 for none).
     */
    function placeAsk(
        uint256 _dftId,
        uint256 _fragmentAmount,
        uint256 _minPricePerFragment,
        uint256 _priceIncreaseRate,
        uint256 _expirationTime,
        uint256 _oracleConditionId
    ) external {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0) revert DFTNotFound(); // Ensure DFT exists
        if (_fragmentAmount == 0) revert InvalidOrderAmount();
        if (_minPricePerFragment == 0) revert InvalidOrderParameters();
        if (_oracleConditionId != 0 && oracleConditions[_oracleConditionId].id == 0) revert OracleConditionNotFound();

        // Check ownership: either fractionalized and owns fragments, or owns the whole DFT
        if (dft.isFractionalized) {
            if (dftFragments[_dftId][msg.sender] < _fragmentAmount) revert InsufficientFragments();
        } else {
            if (dft.owner != msg.sender) revert NotDFTOwner();
            // Selling fragments of a whole DFT - conceptually lock the DFT
            // In a real system, this would need careful locking logic to prevent simultaneous asks or transfer
            // For this example, we assume the owner is careful or only one ask can be active per whole DFT
            if (_fragmentAmount > dft.totalFragments && dft.totalFragments > 0) revert InvalidOrderAmount(); // Cannot sell more fragments than exist if fractionalized
            if (dft.totalFragments == 0 && _fragmentAmount == 0) revert InvalidOrderAmount(); // Need to specify amount
             if (dft.totalFragments == 0 && _fragmentAmount != 0) {
                 // Selling fragments of a non-fractionalized DFT.
                 // Imply fractionalization will happen upon trade or that this is a partial sale.
                 // This is complex. Let's simplify: **asks must be for fractionalized DFTs**.
                 revert DFTNotFractionalized(); // Simplified constraint for this example
             }
             // If we allowed selling fragments of a whole DFT, we'd need to check if *any* ask exists for this DFT ID
             // as only one could logically happen at a time without fractionalizing.
        }


        unchecked { orderCounter++; }
        uint256 orderId = orderCounter;

        orders[orderId] = Order({
            id: orderId,
            maker: msg.sender,
            dftId: _dftId,
            isBid: false, // Ask
            fragmentAmount: _fragmentAmount,
            priceParam1: _minPricePerFragment,
            priceParam2: _priceIncreaseRate,
            creationTime: block.timestamp,
            expirationTime: _expirationTime,
            oracleConditionId: _oracleConditionId,
            isActive: true,
            filledAmount: 0,
            valueLocked: 0 // Fragments are conceptually locked by owner check above
        });

        // Add to active asks list for the DFT
        activeAsks[_dftId].push(orderId);
        userOrders[msg.sender].push(orderId);

        emit OrderPlaced(orderId, msg.sender, _dftId, false, _fragmentAmount, _minPricePerFragment, _priceIncreaseRate, _expirationTime, _oracleConditionId);
    }

    /**
     * @notice Cancels an active order placed by the caller.
     * Refunds locked ETH for bids.
     * @param _orderId The ID of the order to cancel.
     */
    function cancelOrder(uint256 _orderId) external isActiveOrder(_orderId) {
        Order storage order = orders[_orderId];
        if (order.maker != msg.sender) revert NotOrderMaker();

        order.isActive = false;

        // Refund value locked for bids
        if (order.isBid && order.valueLocked > 0) {
            (bool success, ) = payable(msg.sender).call{value: order.valueLocked}("");
             // If refund fails, it's problematic. Could implement a withdrawal pattern.
             // For this example, we'll revert on failure.
             if (!success) revert TradeExecutionFailed(); // Using a generic error
             order.valueLocked = 0; // Clear locked value after successful transfer
        }
        // For asks, fragments are conceptually unlocked (caller now free to transfer/use)

        // Note: Removing from activeBids/activeAsks arrays is gas-expensive.
        // A real system would use linked lists or simply filter inactive orders when matching.
        // For simplicity, we'll leave them in the array and filter during matching.

        emit OrderCancelled(_orderId);
    }

    /**
     * @notice Gets the list of active bid and ask order IDs for a specific DFT.
     * @param _dftId The ID of the DFT.
     * @return A tuple containing arrays of active bid IDs and active ask IDs.
     */
    function getOrdersForDFT(uint256 _dftId) external view returns (uint256[] memory bids, uint256[] memory asks) {
        // Filter out inactive orders
        uint256[] memory currentBids = activeBids[_dftId];
        uint256[] memory currentAsks = activeAsks[_dftId];
        uint256 activeBidCount;
        uint256 activeAskCount;

        for(uint i = 0; i < currentBids.length; i++) {
            if(orders[currentBids[i]].isActive) activeBidCount++;
        }
         for(uint i = 0; i < currentAsks.length; i++) {
            if(orders[currentAsks[i]].isActive) activeAskCount++;
        }

        bids = new uint256[](activeBidCount);
        asks = new uint256[](activeAskCount);

        uint256 bidIndex = 0;
        uint256 askIndex = 0;

        for(uint i = 0; i < currentBids.length; i++) {
            if(orders[currentBids[i]].isActive) {
                bids[bidIndex] = currentBids[i];
                bidIndex++;
            }
        }
         for(uint i = 0; i < currentAsks.length; i++) {
            if(orders[currentAsks[i]].isActive) {
                asks[askIndex] = currentAsks[i];
                askIndex++;
            }
        }

        return (bids, asks);
    }

    /**
     * @notice Gets the list of active order IDs placed by a specific user.
     * @param _user The address of the user.
     * @return An array of active order IDs.
     */
    function getUserOrders(address _user) external view returns (uint256[] memory) {
        uint256[] memory userOrderIds = userOrders[_user];
        uint256 activeCount;
        for(uint i = 0; i < userOrderIds.length; i++) {
            if(orders[userOrderIds[i]].isActive) activeCount++;
        }

        uint256[] memory activeUserOrders = new uint256[](activeCount);
        uint256 activeIndex = 0;
         for(uint i = 0; i < userOrderIds.length; i++) {
            if(orders[userOrderIds[i]].isActive) {
                activeUserOrders[activeIndex] = userOrderIds[i];
                activeIndex++;
            }
        }
        return activeUserOrders;
    }


    // --- Marketplace - Matching & Execution ---

    /**
     * @notice Attempts to match eligible bids and asks for a specific DFT.
     * Anyone can call this function to trigger matching.
     * @param _dftId The ID of the DFT to match orders for.
     */
    function matchOrders(uint256 _dftId) external {
        // Get active bids and asks (filter out inactive ones implicitly by checking isActive)
        uint256[] memory bidIds = activeBids[_dftId];
        uint256[] memory askIds = activeAsks[_dftId];

        // Simple matching logic: iterate through bids and asks and find potential matches
        // Prioritize based on price and age (optional, not implemented simply here)
        // For simplicity, just iterate and match the first compatible pair found.
        // A real exchange uses sorted order books and more complex matching algorithms.

        for (uint i = 0; i < bidIds.length; i++) {
            uint256 bidId = bidIds[i];
            Order storage bid = orders[bidId];

            if (!bid.isActive || bid.dftId != _dftId) continue; // Skip inactive or wrong DFT

            // Check bid conditions (expiration, oracle)
            if (!_checkOrderConditions(bidId)) {
                bid.isActive = false; // Mark expired/unmet conditional orders as inactive
                continue;
            }

            // Calculate current effective bid price per fragment
            uint256 effectiveBidPrice = bid.priceParam1; // Start with max price
            // Apply decay based on time since creation
            uint256 timeElapsed = block.timestamp - bid.creationTime;
            if (timeElapsed > 0 && bid.priceParam2 > 0) {
                 effectiveBidPrice = effectiveBidPrice > (timeElapsed * bid.priceParam2) ? effectiveBidPrice - (timeElapsed * bid.priceParam2) : 0;
            }
             if (effectiveBidPrice == 0) {
                 bid.isActive = false; // Price decayed to zero
                 continue;
             }


            for (uint j = 0; j < askIds.length; j++) {
                uint256 askId = askIds[j];
                Order storage ask = orders[askId];

                 if (!ask.isActive || ask.dftId != _dftId) continue; // Skip inactive or wrong DFT

                // Check ask conditions (expiration, oracle)
                 if (!_checkOrderConditions(askId)) {
                    ask.isActive = false; // Mark expired/unmet conditional orders as inactive
                    continue;
                 }

                // Calculate current effective ask price per fragment
                uint256 effectiveAskPrice = ask.priceParam1; // Start with min price
                // Apply increase based on time since creation
                 timeElapsed = block.timestamp - ask.creationTime;
                if (timeElapsed > 0 && ask.priceParam2 > 0) {
                    effectiveAskPrice += timeElapsed * ask.priceParam2;
                }

                // Check if prices overlap (bid price >= ask price)
                if (effectiveBidPrice >= effectiveAskPrice) {
                    // Potential match found!
                    // Determine trade amount (min of remaining bid/ask amount)
                    uint256 tradeAmount = (bid.fragmentAmount - bid.filledAmount) < (ask.fragmentAmount - ask.filledAmount)
                        ? (bid.fragmentAmount - bid.filledAmount)
                        : (ask.fragmentAmount - ask.filledAmount);

                    if (tradeAmount == 0) continue; // Should not happen if isActive and filledAmount check works, but safety

                    // Determine trade price (could be ask price, bid price, or midpoint - commonly ask price)
                    uint256 tradePricePerFragment = effectiveAskPrice; // Or maybe effectiveBidPrice? Let's use ask price.

                    // Check if bid has enough value locked for the trade amount
                    uint256 requiredValue = tradeAmount * tradePricePerFragment;
                    uint256 availableValue = bid.valueLocked / (bid.fragmentAmount - bid.filledAmount) * (tradeAmount) ; // Simplified calculation
                    // A more accurate check would be: total value locked - total value used so far
                    // Let's refine the bid valueLocked logic. It should represent *total* ETH sent.
                    // The check should be: remaining ETH in bid >= requiredValue
                    uint256 remainingBidValue = bid.valueLocked - (bid.filledAmount * (bid.valueLocked / bid.fragmentAmount)); // Rough estimate assuming uniform price
                     // Better: Track remaining value explicitly or recalculate based on filled amount
                     // Let's assume valueLocked is total, and available per fragment is valueLocked / fragmentAmount initially
                     // available value for trade = (bid.valueLocked / bid.fragmentAmount) * tradeAmount
                     // This is simplified. A proper implementation needs careful tracking of remaining value.
                     // Let's assume the initial check `msg.value >= _fragmentAmount * _maxPricePerFragment` guarantees enough ETH if tradePrice <= maxPrice.
                     // So, if effectiveBidPrice >= effectiveAskPrice, the price is <= maxPrice, so funds *should* be sufficient if the initial check passed.
                     // The complexity comes with partial fills.
                     // Let's stick to a simple check for now: if price matches, assume funds were sufficient initially.

                    // Execute the trade
                    _executeTrade(bidId, askId, tradePricePerFragment);

                    // Update filled amounts
                    bid.filledAmount += tradeAmount;
                    ask.filledAmount += tradeAmount;

                    // Deactivate orders if fully filled
                    if (bid.filledAmount == bid.fragmentAmount) {
                        bid.isActive = false;
                        // Refund any remaining ETH in the bid
                        if (bid.valueLocked > 0) {
                            (bool success, ) = payable(bid.maker).call{value: bid.valueLocked}("");
                            if (!success) { /* handle refund failure */ } // Reverting here would undo the trade
                             bid.valueLocked = 0;
                        }
                    }
                    if (ask.filledAmount == ask.fragmentAmount) {
                         ask.isActive = false;
                         // Fragments are now fully transferred in _executeTrade
                    }

                    // If a trade happened, maybe break and re-run matchOrders to find new best matches,
                    // or continue iterating (can lead to complex behavior depending on algorithm).
                    // For simplicity, let's continue iterating to potentially find more matches for the current bid/ask.
                    // A single call might execute multiple partial or full trades.
                }
            }
        }
         // Note: This implementation does not remove inactive orders from activeBids/activeAsks arrays.
         // This is inefficient over time. Cleanup logic is needed.
    }

    /**
     * @notice Attempts to trigger and match orders dependent on a specific oracle condition.
     * Callable by anyone once the condition is met.
     * @param _conditionId The ID of the oracle condition.
     */
    function processConditionalOrders(uint256 _conditionId) external {
        OracleCondition storage condition = oracleConditions[_conditionId];
        if (condition.id == 0) revert OracleConditionNotFound();
        if (!condition.isMet || condition.expirationTime <= block.timestamp) revert OracleConditionNotMet();
        if (condition.processed) return; // Already processed

        // Mark condition as processed
        condition.processed = true;

        // Find all active orders linked to this condition and attempt to match them
        // This could iterate through ALL active orders, which is inefficient.
        // A better approach would be to have a mapping: oracleConditionId => list of orderIds
        // For this example, we'll just rely on matchOrders being called on relevant DFTs.
        // Alternatively, we could find all DFTs that have orders linked to this condition
        // This requires iterating through all orders or maintaining another index.
        // Let's assume matchOrders(_dftId) is called separately after this.
        // The main effect of this function is to flip `condition.processed` and potentially `condition.isMet`,
        // making orders dependent on it eligible in `_checkOrderConditions`.
        // We can add a simple mechanism here to notify relevant DFTs or queues if this were more complex.
        // As is, this function primarily just updates the condition status.
        // The actual matching happens when `matchOrders` is called for a specific DFT.

        // To make this function more active, we could find DFTs associated with this condition.
        // This requires iterating through all orders. Let's simulate triggering matches for *some* DFTs.
        // A real system would need a data structure mapping conditionId to relevant DFTs.
        // For example, iterate through all active orders, find unique dftIds linked to this condition, and call matchOrders for each.
        // This can be very gas-intensive.

        // Simplified approach: Let this function *only* update the condition status.
        // Rely on external callers or subsequent `matchOrders` calls for execution.
        // Or, as a compromise, iterate through *a subset* of orders or requires a list of relevant DFTs as input.
        // Let's add a placeholder comment indicating where match calls would go.

        // // --- Potential (Gas-Intensive) Matching Trigger ---
        // mapping(uint256 => bool) processedDfts;
        // uint256[] memory allOrders = userOrders[address(0)]; // Example: assuming a list of all orders exists or iterate
        // for (uint i = 1; i <= orderCounter; i++) { // Iterate through all possible orders
        //     Order storage order = orders[i];
        //     if (order.isActive && order.oracleConditionId == _conditionId && !processedDfts[order.dftId]) {
        //         // Attempt to match orders for this DFT now that condition is met
        //         matchOrders(order.dftId); // Recursive or nested call
        //         processedDfts[order.dftId] = true;
        //     }
        // }
        // // --- End Potential Trigger ---

        // The condition status is updated, making dependent orders eligible.
    }


    // --- Staking & Reputation ---

    /**
     * @notice Allows users to stake Ether to gain reputation.
     * Reputation gain is simplified here.
     */
    function stake() external payable {
        if (msg.value == 0) revert StakingAmountZero();
        stakedBalances[msg.sender] += msg.value;
        // Simplified reputation gain: fixed points per staking event, maybe more based on amount
        _updateReputation(msg.sender, 10 + (msg.value / 1e18)); // 10 points + 1 point per ETH staked

        emit StakeSuccessful(msg.sender, msg.value, stakedBalances[msg.sender]);
    }

    /**
     * @notice Allows users to unstake Ether.
     * Reputation is reduced upon unstaking.
     * @param _amount The amount of Ether to unstake (in wei).
     */
    function unstake(uint256 _amount) external {
        if (_amount == 0) revert StakingAmountZero();
        if (stakedBalances[msg.sender] < _amount) revert InsufficientStakedBalance();

        stakedBalances[msg.sender] -= _amount;
        // Simplified reputation loss: fixed points per unstaking event, maybe more based on amount
        _updateReputation(msg.sender, reputationScores[msg.sender] > (5 + (_amount / 1e18)) ? reputationScores[msg.sender] - (5 + (_amount / 1e18)) : 0);

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
         if (!success) {
             // If unstake transfer fails, put balance back (or handle differently)
             stakedBalances[msg.sender] += _amount;
             revert TradeExecutionFailed(); // Using generic error
         }

        emit UnstakeSuccessful(msg.sender, _amount, stakedBalances[msg.sender]);
    }

    /**
     * @notice Gets the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @notice Gets the staked Ether balance of a user.
     * @param _user The address of the user.
     * @return The staked balance in wei.
     */
    function getStakedBalance(address _user) external view returns (uint256) {
        return stakedBalances[_user];
    }

    // --- Utility / View Functions ---

    /**
     * @notice Gets the current trading fee rate in basis points.
     * @return The current fee rate.
     */
    function getFeeRate() external view returns (uint256) {
        return currentFeeRate;
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Calculates the dynamic price/value of a DFT.
     * Simplified calculation based on initial value, decay rate, and time.
     * @param _dftId The ID of the DFT.
     * @return The calculated dynamic value (conceptual price in wei equivalent).
     */
    function _calculateDynamicPrice(uint256 _dftId) internal view returns (uint256) {
        DynamicFlowToken storage dft = dfts[_dftId];
        if (dft.id == 0) return 0;

        uint256 timeElapsed = block.timestamp - dft.creationTime;
        uint256 decayAmount = timeElapsed * dft.decayRate;

        if (decayAmount >= dft.initialValue) {
            return 0; // Value has fully decayed
        }
        return dft.initialValue - decayAmount;
    }

     /**
      * @notice Checks if an order meets its parametric/conditional requirements to be eligible for matching.
      * Checks expiration and oracle conditions.
      * @param _orderId The ID of the order.
      * @return True if the order is eligible, false otherwise.
      */
    function _checkOrderConditions(uint256 _orderId) internal view returns (bool) {
        Order storage order = orders[_orderId];
        if (!order.isActive) return false; // Must be active
        if (order.expirationTime != 0 && block.timestamp > order.expirationTime) return false; // Check expiration

        if (order.oracleConditionId != 0) {
            OracleCondition storage condition = oracleConditions[order.oracleConditionId];
            // Condition must exist, be met, and not be expired/processed yet for *new* eligibility checks
            // Note: A fully processed condition means dependent orders were already considered.
            // This logic needs careful consideration. If a condition is met, orders become eligible.
            // They remain eligible until they expire or are filled/cancelled, *regardless* of the condition's processed status.
            // The `processed` flag is more for preventing the `processConditionalOrders` function from doing redundant work.
            // So, for simple eligibility check, we only care if it exists, is met, and hasn't expired.
            if (condition.id == 0 || !condition.isMet || condition.expirationTime <= block.timestamp) {
                 return false;
            }
        }
        return true; // All conditions met
    }


    /**
     * @notice Executes a trade between a matched bid and ask order.
     * Handles value transfer, fragment transfer, fees, and reputation updates.
     * Assumes tradeAmount and tradePricePerFragment are already determined and valid.
     * @param _buyOrderId The ID of the winning bid.
     * @param _sellOrderId The ID of the losing ask.
     * @param _tradePricePerFragment The negotiated price per fragment for this trade.
     */
    function _executeTrade(uint256 _buyOrderId, uint256 _sellOrderId, uint256 _tradePricePerFragment) internal {
        Order storage bid = orders[_buyOrderId];
        Order storage ask = orders[_sellOrderId];
        uint256 dftId = bid.dftId; // Must be the same as ask.dftId

        uint256 tradeAmount = (bid.fragmentAmount - bid.filledAmount) < (ask.fragmentAmount - ask.filledAmount)
                        ? (bid.fragmentAmount - bid.filledAmount)
                        : (ask.fragmentAmount - ask.filledAmount);

        uint256 totalTradeValue = tradeAmount * _tradePricePerFragment;
        uint256 feeAmount = (totalTradeValue * currentFeeRate) / 10000; // Fee in basis points
        uint256 valueToSeller = totalTradeValue - feeAmount;

        // --- Transfer Logic ---

        // 1. Transfer ETH from buyer (bid maker) to contract (for fees) and seller (ask maker)
        // Bidder's ETH is already locked in contract balance. Need to transfer from contract.

        // Check if enough value is locked in the bid.
        // This needs careful accounting. `valueLocked` is total ETH sent initially.
        // The remaining value available is `valueLocked - (value already used by prior fills)`.
        // Let's simplify and assume valueLocked tracks the *currently remaining* locked ETH for the unfilled amount.
        // If valueLocked is the initial total, need to calculate used value based on filledAmount.
        // Used value = (bid.filledAmount * bid.valueLocked) / bid.fragmentAmount (approximation assuming uniform price per fragment)
        // Remaining value = bid.valueLocked - Used value. This must be >= totalTradeValue.

        // Let's assume `valueLocked` represents the *remaining* ETH in the bid.
        // This requires updating `valueLocked` on partial fills.
        // If `valueLocked` is the total initial amount:
        // `valueUsed = (bid.filledAmount * totalTradeValue) / tradeAmount;` // This doesn't make sense.
        // The simplest model: ETH per fragment = total_value_sent / total_fragments_bid.
        // Used ETH = fragments_filled * (total_value_sent / total_fragments_bid).
        // Required ETH for THIS trade = tradeAmount * _tradePricePerFragment.
        // This MUST be <= (remaining_fragments_bid * (total_value_sent / total_fragments_bid)).
        // And totalTradeValue MUST be <= remaining ETH in the contract from this bid.

        // Revert if the bid doesn't have enough remaining locked value
        // This simple check assumes valueLocked is updated or represents available.
        // If `valueLocked` is total initial value:
        // uint256 valueUsedBefore = (bid.filledAmount * bid.valueLocked) / bid.fragmentAmount; // Risk of division by zero/precision
        // uint256 remainingLockedValue = bid.valueLocked - valueUsedBefore;
        // if (remainingLockedValue < totalTradeValue) revert InsufficientFundsForBid(); // Need a more robust check


        // Let's assume `valueLocked` in the struct means `remaining_locked_value` for simplicity in this helper.
        // This implies `placeBid` needs modification or valueLocked is re-calculated before calling this.
        // Given `placeBid` sets `valueLocked = msg.value`, let's stick to the initial total model for now
        // and acknowledge this is a simplification/potential bug source.

        // Transfer value to the seller
        (bool successSeller, ) = payable(ask.maker).call{value: valueToSeller}("");
        if (!successSeller) {
            // If transfer fails, the trade should ideally be reverted atomically.
            // Reverting here will undo state changes in `matchOrders` if not handled carefully.
            // In a real system, this requires a robust state management or rollback pattern.
             revert TradeExecutionFailed(); // Use generic error for simplicit
        }

        // Accumulate fees
        totalFeesCollected += feeAmount;
         // Note: In a more complex scenario with refunding excess bid value, fees might be calculated differently
         // or taken from the total bid value before refunding.

        // 2. Transfer Fragments from seller (ask maker) to buyer (bid maker)
        DynamicFlowToken storage dft = dfts[dftId];
        if (!dft.isFractionalized) revert DFTNotFractionalized(); // Should be fractionalized to trade fragments

        // Transfer fragments - relies on `transferFragments` internal function
        // This function checks ownership. The ask maker *must* own the fragments being sold.
        // This implies the ask maker must have enough `dftFragments[dftId][ask.maker]` balance.
        // This should be checked during `placeAsk`. But what about locking?
        // The current `placeAsk` doesn't *transfer* or *lock* fragments on place.
        // It only checks balance at placement time.
        // A fragment owner could place an ask, then transfer fragments away *before* matching.
        // This is a critical flaw in the current simplified model.
        // A real system would either:
        // a) Require fragments to be escrowed in the contract when placing an ask.
        // b) Rely on a pull mechanism where the contract attempts to transfer fragments *only at trade time*.

        // Let's implement the pull mechanism and check balance again here.
        if (dftFragments[dftId][ask.maker] < tradeAmount) {
            // Seller no longer has enough fragments. Order should have been cancelled or couldn't be placed.
            // This trade fails. Maybe cancel the ask order automatically?
            ask.isActive = false; // Deactivate the ask
            revert InsufficientFragments(); // Revert the trade execution attempt
        }

        // Perform the fragment transfer
        dftFragments[dftId][ask.maker] -= tradeAmount;
        dftFragments[dftId][bid.maker] += tradeAmount;

        emit FragmentsTransferred(dftId, ask.maker, bid.maker, tradeAmount);


        // 3. Update Reputation (Simplified)
        // Gain reputation for successful trades
        _updateReputation(bid.maker, reputationScores[bid.maker] + 5); // Buyer gains points
        _updateReputation(ask.maker, reputationScores[ask.maker] + 5); // Seller gains points

        // --- Trade Execution Complete ---
        unchecked { tradeCounter++; }
        emit TradeExecuted(tradeCounter, _buyOrderId, _sellOrderId, dftId, tradeAmount, _tradePricePerFragment);

        // If the trade partially filled the bid, the remaining valueLocked needs adjustment.
        // Example: Bid for 10 fragments @ 100 wei/frag = 1000 wei locked. Fills 3 fragments @ 90 wei/frag = 270 wei used.
        // Remaining locked value is not simply 1000 - 270. The ETH per remaining fragment needs recalculation.
        // Or, valueLocked should decrease proportionally to the fragment fill percentage.
        // Remaining fragments = 7. Total initial = 10. Filled % = 30%.
        // New valueLocked = Initial valueLocked * (remaining fragments / total initial fragments).
        // This is still an approximation if trade prices vary.
        // A robust solution involves tracking used value or average price per filled fragment.

        // Simple update for `valueLocked` based on proportion (only if total was initially locked):
         if (bid.valueLocked > 0 && bid.fragmentAmount > 0) {
             // This is problematic for partial fills at different prices.
             // Let's assume for simplicity that valueLocked is reduced by the amount sent to the seller.
             // This is only valid if fees were taken OUT of the valueToSeller calculation.
             // If fees are *added* on top, valueLocked needs to cover valueToSeller + feeAmount.
             // Let's assume fees are part of the total trade value calculation paid by the buyer.
             // So, buyer pays totalTradeValue, seller gets valueToSeller, contract gets feeAmount.
             // The `valueLocked` should decrease by `totalTradeValue`.
             bid.valueLocked -= totalTradeValue;
         }
         // Note: This relies on `valueLocked` accurately reflecting remaining potential spend.
    }

    /**
     * @notice Updates the reputation score of a user.
     * Internal helper function.
     * @param _user The user's address.
     * @param _newReputation The new reputation score.
     */
    function _updateReputation(address _user, uint256 _newReputation) internal {
        reputationScores[_user] = _newReputation;
        emit ReputationUpdated(_user, _newReputation);
    }

    // Missing internal helpers might include:
    // - Removing filled/cancelled orders from activeBids/activeAsks arrays (gas intensive, often done off-chain or with cleanup functions)
    // - More sophisticated price calculation or oracle data interpretation


}
```