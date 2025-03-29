```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Data Oracle & Event-Driven Marketplace
 * @author Gemini AI (Conceptual Contract)
 * @notice This contract implements a dynamic data oracle integrated with an event-driven marketplace.
 *         It allows the contract owner to define data sources (simulated in this example), update data,
 *         and create event triggers based on data changes. These triggers can automatically adjust
 *         marketplace item prices, availability, or other parameters, creating a reactive and
 *         dynamic marketplace environment.
 *
 * Function Summary:
 *
 * **Oracle Management:**
 * - setOracleDataSource(string _dataSource): Sets the data source for the oracle (e.g., API endpoint, simulated data).
 * - updateOracleData(string _dataKey, uint256 _dataValue): Updates a specific data point in the oracle.
 * - getOracleData(string _dataKey): Retrieves the current value of a data point from the oracle.
 * - addOracleDataKey(string _dataKey, string _dataType): Adds a new data key to the oracle schema.
 * - removeOracleDataKey(string _dataKey): Removes a data key from the oracle schema.
 * - pauseOracle(): Pauses oracle data updates and event processing.
 * - unpauseOracle(): Resumes oracle data updates and event processing.
 *
 * **Marketplace Item Management:**
 * - listItem(uint256 _itemId, string _itemName, uint256 _initialPrice, uint256 _quantity, string _itemData): Lists a new item on the marketplace.
 * - delistItem(uint256 _itemId): Removes an item from the marketplace.
 * - updateItemPrice(uint256 _itemId, uint256 _newPrice): Updates the price of an item.
 * - updateItemQuantity(uint256 _itemId, uint256 _newQuantity): Updates the available quantity of an item.
 * - buyItem(uint256 _itemId, uint256 _quantity): Allows users to purchase items.
 * - getItemDetails(uint256 _itemId): Retrieves details of a specific item.
 * - setMarketplaceFee(uint256 _feePercentage): Sets the marketplace fee percentage.
 * - withdrawFees(): Allows the contract owner to withdraw accumulated marketplace fees.
 *
 * **Event Trigger & Action Management:**
 * - defineEventTrigger(uint256 _eventId, string _dataKey, uint256 _threshold, ComparisonType _comparisonType): Defines a new event trigger based on oracle data.
 * - defineEventAction(uint256 _eventId, ActionType _actionType, uint256 _itemId, uint256 _actionValue): Defines an action to be taken when an event trigger is fired.
 * - getEventTriggerDetails(uint256 _eventId): Retrieves details of a specific event trigger.
 * - getEventActionDetails(uint256 _eventId): Retrieves details of a specific event action.
 * - removeEventTrigger(uint256 _eventId): Removes an existing event trigger.
 * - processOracleEvent(string _dataKey, uint256 _dataValue): Internal function to process oracle data updates and trigger events.
 *
 * **Utility & Control:**
 * - pauseMarketplace(): Pauses marketplace trading activity.
 * - unpauseMarketplace(): Resumes marketplace trading activity.
 * - transferOwnership(address _newOwner): Transfers contract ownership to a new address.
 * - getContractBalance(): Retrieves the current contract balance.
 */
contract DynamicDataEventMarketplace {
    // --- State Variables ---

    address public owner;
    string public oracleDataSource; // e.g., "Simulated Data", "Chainlink API", etc.
    mapping(string => uint256) public oracleData; // Key-value store for oracle data (string key, uint256 value)
    mapping(string => string) public oracleDataType; // Store data type for each key (e.g., "price", "temperature")

    struct Item {
        string itemName;
        uint256 price;
        uint256 quantity;
        string itemData; // Additional item metadata
        bool isListed;
    }
    mapping(uint256 => Item) public items;
    uint256 public nextItemId = 1;

    uint256 public marketplaceFeePercentage = 2; // 2% default fee
    uint256 public accumulatedFees;

    enum ComparisonType { GREATER_THAN, LESS_THAN, EQUAL_TO }
    enum ActionType { PRICE_ADJUST, QUANTITY_ADJUST, DELIST_ITEM }

    struct EventTrigger {
        string dataKey;
        uint256 threshold;
        ComparisonType comparisonType;
        bool isActive;
    }
    mapping(uint256 => EventTrigger) public eventTriggers;
    uint256 public nextEventId = 1;

    struct EventAction {
        ActionType actionType;
        uint256 itemId;
        uint256 actionValue; // Price adjustment percentage, quantity adjustment value, etc.
        bool isActive;
    }
    mapping(uint256 => EventAction) public eventActions;

    bool public isOracleActive = true;
    bool public isMarketplaceActive = true;

    // --- Events ---
    event OracleDataSourceSet(string dataSource);
    event OracleDataUpdated(string dataKey, uint256 dataValue);
    event OracleDataKeyAdded(string dataKey, string dataType);
    event OracleDataKeyRemoved(string dataKey);
    event OraclePaused();
    event OracleUnpaused();

    event ItemListed(uint256 itemId, string itemName, uint256 price, uint256 quantity);
    event ItemDelisted(uint256 itemId);
    event ItemPriceUpdated(uint256 itemId, uint256 newPrice);
    event ItemQuantityUpdated(uint256 itemId, uint256 newQuantity);
    event ItemBought(uint256 itemId, address buyer, uint256 quantity, uint256 totalPrice);
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(uint256 amount, address withdrawnBy);

    event EventTriggerDefined(uint256 eventId, string dataKey, uint256 threshold, ComparisonType comparisonType);
    event EventActionDefined(uint256 eventId, ActionType actionType, uint256 itemId, uint256 actionValue);
    event EventTriggerRemoved(uint256 eventId);
    event OracleEventProcessed(string dataKey, uint256 dataValue, uint256 eventId, ActionType actionType, uint256 itemId, uint256 actionValue);

    event MarketplacePaused();
    event MarketplaceUnpaused();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier oracleActive() {
        require(isOracleActive, "Oracle is currently paused.");
        _;
    }

    modifier marketplaceActive() {
        require(isMarketplaceActive, "Marketplace is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        oracleDataSource = "Simulated Data - Example"; // Default data source
    }

    // --- Oracle Management Functions ---

    /**
     * @dev Sets the data source for the oracle. Only callable by the contract owner.
     * @param _dataSource Description of the data source (e.g., API endpoint, name).
     */
    function setOracleDataSource(string memory _dataSource) external onlyOwner {
        oracleDataSource = _dataSource;
        emit OracleDataSourceSet(_dataSource);
    }

    /**
     * @dev Updates a specific data point in the oracle. Only callable by the contract owner.
     * @param _dataKey The key of the data point to update.
     * @param _dataValue The new value for the data point.
     */
    function updateOracleData(string memory _dataKey, uint256 _dataValue) external onlyOwner oracleActive {
        oracleData[_dataKey] = _dataValue;
        emit OracleDataUpdated(_dataKey, _dataValue);
        _processOracleEvent(_dataKey, _dataValue); // Trigger event processing
    }

    /**
     * @dev Retrieves the current value of a data point from the oracle.
     * @param _dataKey The key of the data point to retrieve.
     * @return The current value of the data point.
     */
    function getOracleData(string memory _dataKey) external view returns (uint256) {
        return oracleData[_dataKey];
    }

    /**
     * @dev Adds a new data key to the oracle schema. Only callable by the contract owner.
     * @param _dataKey The new data key to add.
     * @param _dataType Description of the data type (e.g., "price", "temperature").
     */
    function addOracleDataKey(string memory _dataKey, string memory _dataType) external onlyOwner {
        require(bytes(oracleDataType[_dataKey]).length == 0, "Data key already exists.");
        oracleDataType[_dataKey] = _dataType;
        emit OracleDataKeyAdded(_dataKey, _dataType);
    }

    /**
     * @dev Removes a data key from the oracle schema. Only callable by the contract owner.
     * @param _dataKey The data key to remove.
     */
    function removeOracleDataKey(string memory _dataKey) external onlyOwner {
        require(bytes(oracleDataType[_dataKey]).length > 0, "Data key does not exist.");
        delete oracleDataType[_dataKey];
        delete oracleData[_dataKey];
        emit OracleDataKeyRemoved(_dataKey);
    }

    /**
     * @dev Pauses oracle data updates and event processing. Only callable by the contract owner.
     */
    function pauseOracle() external onlyOwner {
        isOracleActive = false;
        emit OraclePaused();
    }

    /**
     * @dev Resumes oracle data updates and event processing. Only callable by the contract owner.
     */
    function unpauseOracle() external onlyOwner {
        isOracleActive = true;
        emit OracleUnpaused();
    }

    // --- Marketplace Item Management Functions ---

    /**
     * @dev Lists a new item on the marketplace. Only callable by the contract owner (for simplicity in this example, could be extended to allow sellers).
     * @param _itemId Unique identifier for the item.
     * @param _itemName Name of the item.
     * @param _initialPrice Initial price of the item in wei.
     * @param _quantity Initial quantity of the item available.
     * @param _itemData Additional metadata about the item (e.g., description, image URL).
     */
    function listItem(
        uint256 _itemId,
        string memory _itemName,
        uint256 _initialPrice,
        uint256 _quantity,
        string memory _itemData
    ) external onlyOwner marketplaceActive {
        require(bytes(items[_itemId].itemName).length == 0, "Item ID already exists."); // Ensure item ID is unique
        items[_itemId] = Item({
            itemName: _itemName,
            price: _initialPrice,
            quantity: _quantity,
            itemData: _itemData,
            isListed: true
        });
        emit ItemListed(_itemId, _itemName, _initialPrice, _quantity);
    }

    /**
     * @dev Removes an item from the marketplace. Only callable by the contract owner.
     * @param _itemId The ID of the item to delist.
     */
    function delistItem(uint256 _itemId) external onlyOwner marketplaceActive {
        require(items[_itemId].isListed, "Item is not currently listed.");
        items[_itemId].isListed = false;
        emit ItemDelisted(_itemId);
    }

    /**
     * @dev Updates the price of an item. Only callable by the contract owner.
     * @param _itemId The ID of the item to update.
     * @param _newPrice The new price of the item in wei.
     */
    function updateItemPrice(uint256 _itemId, uint256 _newPrice) external onlyOwner marketplaceActive {
        require(items[_itemId].isListed, "Item is not currently listed.");
        items[_itemId].price = _newPrice;
        emit ItemPriceUpdated(_itemId, _newPrice);
    }

    /**
     * @dev Updates the available quantity of an item. Only callable by the contract owner.
     * @param _itemId The ID of the item to update.
     * @param _newQuantity The new quantity of the item.
     */
    function updateItemQuantity(uint256 _itemId, uint256 _newQuantity) external onlyOwner marketplaceActive {
        require(items[_itemId].isListed, "Item is not currently listed.");
        items[_itemId].quantity = _newQuantity;
        emit ItemQuantityUpdated(_itemId, _newQuantity);
    }

    /**
     * @dev Allows users to purchase items from the marketplace.
     * @param _itemId The ID of the item to purchase.
     * @param _quantity The quantity of the item to purchase.
     */
    function buyItem(uint256 _itemId, uint256 _quantity) external payable marketplaceActive {
        require(items[_itemId].isListed, "Item is not currently listed.");
        require(items[_itemId].quantity >= _quantity, "Insufficient item quantity available.");
        require(msg.value >= items[_itemId].price * _quantity, "Insufficient payment provided.");

        uint256 totalPrice = items[_itemId].price * _quantity;
        uint256 feeAmount = (totalPrice * marketplaceFeePercentage) / 100;
        uint256 netPrice = totalPrice - feeAmount;

        items[_itemId].quantity -= _quantity;
        accumulatedFees += feeAmount;

        payable(owner).transfer(feeAmount); // Transfer fees to owner
        payable(msg.sender).transfer(netPrice); // Transfer net price to the buyer (in a real marketplace, this would go to the seller)

        emit ItemBought(_itemId, msg.sender, _quantity, totalPrice);
    }

    /**
     * @dev Retrieves details of a specific item.
     * @param _itemId The ID of the item to retrieve details for.
     * @return Item details (itemName, price, quantity, itemData, isListed).
     */
    function getItemDetails(uint256 _itemId) external view returns (string memory itemName, uint256 price, uint256 quantity, string memory itemData, bool isListed) {
        Item storage item = items[_itemId];
        return (item.itemName, item.price, item.quantity, item.itemData, item.isListed);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new marketplace fee percentage (0-100).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amountToWithdraw = accumulatedFees;
        accumulatedFees = 0;
        payable(owner).transfer(amountToWithdraw);
        emit FeesWithdrawn(amountToWithdraw, owner);
    }


    // --- Event Trigger & Action Management Functions ---

    /**
     * @dev Defines a new event trigger based on oracle data. Only callable by the contract owner.
     * @param _eventId Unique identifier for the event trigger.
     * @param _dataKey The oracle data key to monitor for the trigger.
     * @param _threshold The threshold value for the trigger.
     * @param _comparisonType The type of comparison to use (GREATER_THAN, LESS_THAN, EQUAL_TO).
     */
    function defineEventTrigger(
        uint256 _eventId,
        string memory _dataKey,
        uint256 _threshold,
        ComparisonType _comparisonType
    ) external onlyOwner {
        require(bytes(eventTriggers[_eventId].dataKey).length == 0, "Event ID already exists."); // Ensure event ID is unique
        require(bytes(oracleDataType[_dataKey]).length > 0, "Data key must exist in oracle.");

        eventTriggers[_eventId] = EventTrigger({
            dataKey: _dataKey,
            threshold: _threshold,
            comparisonType: _comparisonType,
            isActive: true
        });
        emit EventTriggerDefined(_eventId, _dataKey, _threshold, _comparisonType);
    }

    /**
     * @dev Defines an action to be taken when an event trigger is fired. Only callable by the contract owner.
     * @param _eventId The ID of the event trigger this action is associated with.
     * @param _actionType The type of action to take (PRICE_ADJUST, QUANTITY_ADJUST, DELIST_ITEM).
     * @param _itemId The ID of the marketplace item to apply the action to.
     * @param _actionValue The value associated with the action (e.g., price adjustment percentage, quantity adjustment value).
     */
    function defineEventAction(
        uint256 _eventId,
        ActionType _actionType,
        uint256 _itemId,
        uint256 _actionValue
    ) external onlyOwner {
        require(bytes(eventActions[_eventId].actionType) == 0, "Event action already defined for this event ID."); // Ensure only one action per event ID
        require(items[_itemId].isListed || _actionType == DELIST_ITEM, "Item must be listed for price or quantity adjustments, or can be delisted regardless.");
        require(bytes(eventTriggers[_eventId].dataKey).length > 0, "Event trigger must be defined first.");

        eventActions[_eventId] = EventAction({
            actionType: _actionType,
            itemId: _itemId,
            actionValue: _actionValue,
            isActive: true
        });
        emit EventActionDefined(_eventId, _actionType, _itemId, _actionValue);
    }

    /**
     * @dev Retrieves details of a specific event trigger.
     * @param _eventId The ID of the event trigger to retrieve details for.
     * @return Event trigger details (dataKey, threshold, comparisonType, isActive).
     */
    function getEventTriggerDetails(uint256 _eventId) external view returns (string memory dataKey, uint256 threshold, ComparisonType comparisonType, bool isActive) {
        EventTrigger storage trigger = eventTriggers[_eventId];
        return (trigger.dataKey, trigger.threshold, trigger.comparisonType, trigger.isActive);
    }

    /**
     * @dev Retrieves details of a specific event action.
     * @param _eventId The ID of the event action to retrieve details for.
     * @return Event action details (actionType, itemId, actionValue, isActive).
     */
    function getEventActionDetails(uint256 _eventId) external view returns (ActionType actionType, uint256 itemId, uint256 actionValue, bool isActive) {
        EventAction storage action = eventActions[_eventId];
        return (action.actionType, action.itemId, action.actionValue, action.isActive);
    }

    /**
     * @dev Removes an existing event trigger and its associated action (if any). Only callable by the contract owner.
     * @param _eventId The ID of the event trigger to remove.
     */
    function removeEventTrigger(uint256 _eventId) external onlyOwner {
        require(bytes(eventTriggers[_eventId].dataKey).length > 0, "Event trigger does not exist.");
        delete eventTriggers[_eventId];
        delete eventActions[_eventId]; // Remove associated action as well
        emit EventTriggerRemoved(_eventId);
    }

    /**
     * @dev Internal function to process oracle data updates and trigger relevant events and actions.
     * @param _dataKey The data key that was updated.
     * @param _dataValue The new value of the data point.
     */
    function _processOracleEvent(string memory _dataKey, uint256 _dataValue) internal {
        for (uint256 eventId = 1; eventId < nextEventId; eventId++) { // Iterate through event triggers
            if (eventTriggers[eventId].isActive && keccak256(bytes(eventTriggers[eventId].dataKey)) == keccak256(bytes(_dataKey))) {
                EventTrigger storage trigger = eventTriggers[eventId];
                EventAction storage action = eventActions[eventId]; // Assumes one action per trigger for simplicity

                bool triggerFired = false;
                if (trigger.comparisonType == ComparisonType.GREATER_THAN && _dataValue > trigger.threshold) {
                    triggerFired = true;
                } else if (trigger.comparisonType == ComparisonType.LESS_THAN && _dataValue < trigger.threshold) {
                    triggerFired = true;
                } else if (trigger.comparisonType == ComparisonType.EQUAL_TO && _dataValue == trigger.threshold) {
                    triggerFired = true;
                }

                if (triggerFired && action.isActive) {
                    if (action.actionType == ActionType.PRICE_ADJUST) {
                        uint256 priceAdjustment = (items[action.itemId].price * action.actionValue) / 100; // Assume actionValue is percentage
                        uint256 newPrice = items[action.itemId].price + priceAdjustment; // Example: Increase price
                        updateItemPrice(action.itemId, newPrice);
                        emit OracleEventProcessed(_dataKey, _dataValue, eventId, action.actionType, action.itemId, action.actionValue);
                    } else if (action.actionType == ActionType.QUANTITY_ADJUST) {
                        updateItemQuantity(action.itemId, items[action.itemId].quantity + action.actionValue); // Example: Increase quantity
                        emit OracleEventProcessed(_dataKey, _dataValue, eventId, action.actionType, action.itemId, action.actionValue);
                    } else if (action.actionType == ActionType.DELIST_ITEM) {
                        delistItem(action.itemId);
                        emit OracleEventProcessed(_dataKey, _dataValue, eventId, action.actionType, action.itemId, action.actionValue);
                    }
                }
            }
        }
    }

    // --- Utility & Control Functions ---

    /**
     * @dev Pauses marketplace trading activity. Only callable by the contract owner.
     */
    function pauseMarketplace() external onlyOwner {
        isMarketplaceActive = false;
        emit MarketplacePaused();
    }

    /**
     * @dev Resumes marketplace trading activity. Only callable by the contract owner.
     */
    function unpauseMarketplace() external onlyOwner {
        isMarketplaceActive = true;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Transfers contract ownership to a new address. Only callable by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Retrieves the current contract balance.
     * @return The contract balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Fallback and Receive Functions (Optional, for receiving Ether directly) ---
    receive() external payable {}
    fallback() external payable {}
}
```