```solidity
/**
 * @title Dynamic and Interactive Digital Asset Platform (DIAP)
 * @author Gemini AI
 * @dev A Smart Contract embodying advanced concepts for a dynamic digital asset platform.
 *
 * Function Summary:
 *
 * 1.  `initializePlatform(string _platformName, address _feeCollector)`: Initializes the platform with a name and fee collector address.
 * 2.  `createDigitalAssetClass(string _className, string _classSymbol, string _classDescription)`: Creates a new class of digital assets.
 * 3.  `mintDigitalAsset(uint256 _classId, string _assetURI, bytes _initialStateData)`: Mints a new digital asset within a specific class, with URI and initial state data.
 * 4.  `transferDigitalAsset(uint256 _assetId, address _to)`: Transfers ownership of a digital asset.
 * 5.  `updateDigitalAssetMetadata(uint256 _assetId, string _newAssetURI)`: Updates the metadata URI of a digital asset.
 * 6.  `interactWithAsset(uint256 _assetId, bytes _interactionData)`: Allows users to interact with a digital asset, triggering state changes based on predefined logic.
 * 7.  `setAssetInteractionLogic(uint256 _classId, bytes _logicCode)`: Sets or updates the interaction logic for a specific asset class (using bytecode/function selectors).
 * 8.  `getAssetCurrentState(uint256 _assetId)`: Retrieves the current state data of a digital asset.
 * 9.  `freezeDigitalAsset(uint256 _assetId)`: Freezes a digital asset, preventing further transfers or interactions.
 * 10. `unfreezeDigitalAsset(uint256 _assetId)`: Unfreezes a frozen digital asset.
 * 11. `setPlatformFee(uint256 _newFeePercentage)`: Sets the platform fee percentage for transactions.
 * 12. `withdrawPlatformFees()`: Allows the fee collector to withdraw accumulated platform fees.
 * 13. `supportNewInteractionType(string _interactionName, bytes4 _functionSelector)`: Adds support for a new type of interaction by registering its function selector.
 * 14. `getClassDetails(uint256 _classId)`: Retrieves details of a digital asset class.
 * 15. `getAssetDetails(uint256 _assetId)`: Retrieves details of a specific digital asset.
 * 16. `ownerOfAsset(uint256 _assetId)`: Returns the owner of a digital asset.
 * 17. `isAssetFrozen(uint256 _assetId)`: Checks if a digital asset is frozen.
 * 18. `getPlatformName()`: Returns the name of the platform.
 * 19. `getFeeCollector()`: Returns the address of the fee collector.
 * 20. `getSupportedInteractions()`: Returns a list of supported interaction names and their function selectors.
 * 21. `burnDigitalAsset(uint256 _assetId)`: Burns a digital asset, permanently removing it from circulation.
 * 22. `setAssetClassAdmin(uint256 _classId, address _newAdmin)`: Sets a new admin for a specific digital asset class.
 * 23. `getClassAdmin(uint256 _classId)`: Retrieves the admin address for a specific asset class.
 */

pragma solidity ^0.8.0;

contract DynamicDigitalAssetPlatform {
    string public platformName;
    address public feeCollector;
    uint256 public platformFeePercentage; // in basis points (e.g., 100 = 1%)
    uint256 public nextAssetClassId;
    uint256 public nextAssetId;

    struct DigitalAssetClass {
        string name;
        string symbol;
        string description;
        address admin; // Admin for managing assets within this class
        bytes interactionLogic; // Bytecode representing interaction logic
    }

    struct DigitalAsset {
        uint256 classId;
        string assetURI;
        address owner;
        bytes currentStateData;
        bool isFrozen;
    }

    mapping(uint256 => DigitalAssetClass) public assetClasses;
    mapping(uint256 => DigitalAsset) public digitalAssets;
    mapping(uint256 => address) public assetOwnership; // assetId => owner
    mapping(bytes4 => string) public supportedInteractions; // function selector => interaction name
    mapping(address => uint256) public collectedFees; // Collector balance

    address public platformOwner;
    bool public platformInitialized;

    event PlatformInitialized(string platformName, address feeCollector);
    event AssetClassCreated(uint256 classId, string className, string classSymbol, string classDescription, address admin);
    event DigitalAssetMinted(uint256 assetId, uint256 classId, address owner, string assetURI);
    event DigitalAssetTransferred(uint256 assetId, address from, address to);
    event AssetMetadataUpdated(uint256 assetId, string newAssetURI);
    event AssetInteraction(uint256 assetId, address initiator, string interactionType, bytes interactionData);
    event AssetInteractionLogicSet(uint256 classId, bytes logicCode);
    event AssetStateUpdated(uint256 assetId, bytes newStateData);
    event DigitalAssetFrozen(uint256 assetId);
    event DigitalAssetUnfrozen(uint256 assetId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address collector, uint256 amount);
    event InteractionTypeSupported(string interactionName, bytes4 functionSelector);
    event DigitalAssetBurned(uint256 assetId);
    event AssetClassAdminSet(uint256 classId, address newAdmin, address oldAdmin);

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier onlyClassAdmin(uint256 _classId) {
        require(msg.sender == assetClasses[_classId].admin, "Only class admin can call this function.");
        _;
    }

    modifier onlyAssetOwner(uint256 _assetId) {
        require(msg.sender == digitalAssets[_assetId].owner, "Only asset owner can call this function.");
        _;
    }

    modifier platformNotInitialized() {
        require(!platformInitialized, "Platform already initialized.");
        _;
    }

    modifier platformIsInitialized() {
        require(platformInitialized, "Platform not initialized yet.");
        _;
    }

    constructor() payable {
        platformOwner = msg.sender;
        platformInitialized = false;
        platformFeePercentage = 0; // Default to 0% fee
        nextAssetClassId = 1;
        nextAssetId = 1;
    }

    /// @notice Initializes the platform with a name and fee collector address.
    /// @param _platformName The name of the platform.
    /// @param _feeCollector The address that will collect platform fees.
    function initializePlatform(string memory _platformName, address _feeCollector)
        public
        onlyOwner
        platformNotInitialized
    {
        platformName = _platformName;
        feeCollector = _feeCollector;
        platformInitialized = true;
        emit PlatformInitialized(_platformName, _feeCollector);
    }

    /// @notice Creates a new class of digital assets.
    /// @param _className The name of the asset class.
    /// @param _classSymbol A short symbol for the asset class.
    /// @param _classDescription A description of the asset class.
    function createDigitalAssetClass(
        string memory _className,
        string memory _classSymbol,
        string memory _classDescription
    ) public onlyOwner platformIsInitialized {
        assetClasses[nextAssetClassId] = DigitalAssetClass({
            name: _className,
            symbol: _classSymbol,
            description: _classDescription,
            admin: msg.sender, // Creator is initially the class admin
            interactionLogic: bytes("") // Initially no interaction logic
        });
        emit AssetClassCreated(nextAssetClassId, _className, _classSymbol, _classDescription, msg.sender);
        nextAssetClassId++;
    }

    /// @notice Mints a new digital asset within a specific class.
    /// @param _classId The ID of the asset class to mint into.
    /// @param _assetURI URI pointing to the metadata of the asset.
    /// @param _initialStateData Initial state data for the asset.
    function mintDigitalAsset(
        uint256 _classId,
        string memory _assetURI,
        bytes memory _initialStateData
    ) public onlyClassAdmin(_classId) platformIsInitialized {
        require(assetClasses[_classId].name.length > 0, "Invalid asset class ID.");

        digitalAssets[nextAssetId] = DigitalAsset({
            classId: _classId,
            assetURI: _assetURI,
            owner: msg.sender,
            currentStateData: _initialStateData,
            isFrozen: false
        });
        assetOwnership[nextAssetId] = msg.sender; // Set initial ownership
        emit DigitalAssetMinted(nextAssetId, _classId, msg.sender, _assetURI);
        nextAssetId++;
    }

    /// @notice Transfers ownership of a digital asset.
    /// @param _assetId The ID of the asset to transfer.
    /// @param _to The address to transfer the asset to.
    function transferDigitalAsset(uint256 _assetId, address _to) public onlyAssetOwner(_assetId) platformIsInitialized {
        require(_to != address(0), "Cannot transfer to the zero address.");
        require(!digitalAssets[_assetId].isFrozen, "Asset is frozen and cannot be transferred.");

        address from = digitalAssets[_assetId].owner;
        digitalAssets[_assetId].owner = _to;
        assetOwnership[_assetId] = _to; // Update ownership mapping
        emit DigitalAssetTransferred(_assetId, from, _to);
    }

    /// @notice Updates the metadata URI of a digital asset.
    /// @param _assetId The ID of the asset to update.
    /// @param _newAssetURI The new metadata URI.
    function updateDigitalAssetMetadata(uint256 _assetId, string memory _newAssetURI)
        public
        onlyClassAdmin(digitalAssets[_assetId].classId)
        platformIsInitialized
    {
        digitalAssets[_assetId].assetURI = _newAssetURI;
        emit AssetMetadataUpdated(_assetId, _newAssetURI);
    }

    /// @notice Allows users to interact with a digital asset, triggering state changes.
    /// @param _assetId The ID of the asset to interact with.
    /// @param _interactionData Data specific to the interaction.
    function interactWithAsset(uint256 _assetId, bytes memory _interactionData) public platformIsInitialized {
        require(!digitalAssets[_assetId].isFrozen, "Asset is frozen and cannot be interacted with.");
        DigitalAssetClass storage assetClass = assetClasses[digitalAssets[_assetId].classId];
        require(assetClass.interactionLogic.length > 0, "No interaction logic defined for this asset class.");

        // Low-level call to execute interaction logic
        (bool success, bytes memory returnData) = address(this).delegatecall(
            abi.encodeWithSelector(bytes4(keccak256("executeInteraction(uint256,bytes)")), _assetId, _interactionData)
        );

        if (success) {
            // Assume interaction logic updates currentStateData and emits AssetStateUpdated event
            emit AssetInteraction(_assetId, msg.sender, "CustomInteraction", _interactionData); // Generic event, can be made more specific
        } else {
            // Revert if delegatecall fails (interaction logic error)
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    /// @notice Sets or updates the interaction logic for a specific asset class.
    /// @param _classId The ID of the asset class.
    /// @param _logicCode Bytecode representing the interaction logic.
    function setAssetInteractionLogic(uint256 _classId, bytes memory _logicCode)
        public
        onlyClassAdmin(_classId)
        platformIsInitialized
    {
        assetClasses[_classId].interactionLogic = _logicCode;
        emit AssetInteractionLogicSet(_classId, _logicCode);
    }

    /// @notice Retrieves the current state data of a digital asset.
    /// @param _assetId The ID of the asset.
    /// @return The current state data as bytes.
    function getAssetCurrentState(uint256 _assetId) public view platformIsInitialized returns (bytes memory) {
        return digitalAssets[_assetId].currentStateData;
    }

    /// @notice Freezes a digital asset, preventing transfers and interactions.
    /// @param _assetId The ID of the asset to freeze.
    function freezeDigitalAsset(uint256 _assetId) public onlyClassAdmin(digitalAssets[_assetId].classId) platformIsInitialized {
        digitalAssets[_assetId].isFrozen = true;
        emit DigitalAssetFrozen(_assetId);
    }

    /// @notice Unfreezes a frozen digital asset, allowing transfers and interactions.
    /// @param _assetId The ID of the asset to unfreeze.
    function unfreezeDigitalAsset(uint256 _assetId) public onlyClassAdmin(digitalAssets[_assetId].classId) platformIsInitialized {
        digitalAssets[_assetId].isFrozen = false;
        emit DigitalAssetUnfrozen(_assetId);
    }

    /// @notice Sets the platform fee percentage for transactions.
    /// @param _newFeePercentage The new fee percentage in basis points (e.g., 100 = 1%).
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner platformIsInitialized {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100% (10000 basis points)."); // Max 100%
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @notice Allows the fee collector to withdraw accumulated platform fees.
    function withdrawPlatformFees() public platformIsInitialized {
        require(msg.sender == feeCollector, "Only fee collector can withdraw fees.");
        uint256 amount = collectedFees[address(this)];
        collectedFees[address(this)] = 0; // Reset collected fees
        payable(feeCollector).transfer(amount);
        emit PlatformFeesWithdrawn(feeCollector, amount);
    }

    /// @notice Adds support for a new type of interaction by registering its function selector.
    /// @param _interactionName The name of the interaction type (e.g., "Upgrade", "PowerUp").
    /// @param _functionSelector The 4-byte function selector of the interaction function.
    function supportNewInteractionType(string memory _interactionName, bytes4 _functionSelector)
        public
        onlyOwner
        platformIsInitialized
    {
        supportedInteractions[_functionSelector] = _interactionName;
        emit InteractionTypeSupported(_interactionName, _functionSelector);
    }

    /// @notice Retrieves details of a digital asset class.
    /// @param _classId The ID of the asset class.
    /// @return class Name, Symbol, Description, Admin address.
    function getClassDetails(uint256 _classId)
        public
        view
        platformIsInitialized
        returns (
            string memory name,
            string memory symbol,
            string memory description,
            address admin
        )
    {
        DigitalAssetClass storage assetClass = assetClasses[_classId];
        return (assetClass.name, assetClass.symbol, assetClass.description, assetClass.admin);
    }

    /// @notice Retrieves details of a specific digital asset.
    /// @param _assetId The ID of the digital asset.
    /// @return classId, assetURI, owner, isFrozen, currentStateData.
    function getAssetDetails(uint256 _assetId)
        public
        view
        platformIsInitialized
        returns (
            uint256 classId,
            string memory assetURI,
            address owner,
            bool isFrozen,
            bytes memory currentStateData
        )
    {
        DigitalAsset storage asset = digitalAssets[_assetId];
        return (asset.classId, asset.assetURI, asset.owner, asset.isFrozen, asset.currentStateData);
    }

    /// @notice Returns the owner of a digital asset.
    /// @param _assetId The ID of the digital asset.
    /// @return The address of the owner.
    function ownerOfAsset(uint256 _assetId) public view platformIsInitialized returns (address) {
        return digitalAssets[_assetId].owner;
    }

    /// @notice Checks if a digital asset is frozen.
    /// @param _assetId The ID of the digital asset.
    /// @return True if frozen, false otherwise.
    function isAssetFrozen(uint256 _assetId) public view platformIsInitialized returns (bool) {
        return digitalAssets[_assetId].isFrozen;
    }

    /// @notice Returns the name of the platform.
    /// @return The platform name string.
    function getPlatformName() public view platformIsInitialized returns (string memory) {
        return platformName;
    }

    /// @notice Returns the address of the fee collector.
    /// @return The fee collector address.
    function getFeeCollector() public view platformIsInitialized returns (address) {
        return feeCollector;
    }

    /// @notice Returns a list of supported interaction names and their function selectors.
    /// @return Array of interaction names and selectors.
    function getSupportedInteractions()
        public
        view
        platformIsInitialized
        returns (
            string[] memory interactionNames,
            bytes4[] memory selectors
        )
    {
        uint256 count = 0;
        for (uint256 i = 0; i < supportedInteractions.length; i++) {
            if (bytes(supportedInteractions[bytes4(uint256(i))]).length > 0) {
                count++;
            }
        }

        interactionNames = new string[](count);
        selectors = new bytes4[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < supportedInteractions.length; i++) {
            if (bytes(supportedInteractions[bytes4(uint256(i))]).length > 0) {
                interactionNames[index] = supportedInteractions[bytes4(uint256(i))];
                selectors[index] = bytes4(uint256(i));
                index++;
            }
        }
        return (interactionNames, selectors);
    }

    /// @notice Burns a digital asset, permanently removing it from circulation.
    /// @param _assetId The ID of the asset to burn.
    function burnDigitalAsset(uint256 _assetId) public onlyAssetOwner(_assetId) platformIsInitialized {
        require(!digitalAssets[_assetId].isFrozen, "Frozen assets cannot be burned.");
        delete digitalAssets[_assetId];
        delete assetOwnership[_assetId];
        emit DigitalAssetBurned(_assetId);
    }

    /// @notice Sets a new admin for a specific digital asset class.
    /// @param _classId The ID of the asset class.
    /// @param _newAdmin The address of the new class admin.
    function setAssetClassAdmin(uint256 _classId, address _newAdmin) public onlyClassAdmin(_classId) platformIsInitialized {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        address oldAdmin = assetClasses[_classId].admin;
        assetClasses[_classId].admin = _newAdmin;
        emit AssetClassAdminSet(_classId, _newAdmin, oldAdmin);
    }

    /// @notice Retrieves the admin address for a specific asset class.
    /// @param _classId The ID of the asset class.
    /// @return The admin address.
    function getClassAdmin(uint256 _classId) public view platformIsInitialized returns (address) {
        return assetClasses[_classId].admin;
    }

    // --------------------------------------------------------------------
    //  Example Interaction Logic (This would typically be in separate contracts
    //  or dynamically loaded, but included here for demonstration)
    // --------------------------------------------------------------------

    /// @dev Example interaction function (Selector: 0x...) -  This should be defined based on `setAssetInteractionLogic`.
    /// @param _assetId The ID of the asset being interacted with.
    /// @param _interactionData Data specific to this interaction.
    function executeInteraction(uint256 _assetId, bytes memory _interactionData) public {
        // This function is called via delegatecall from `interactWithAsset`.
        // It's crucial that the logic here is safe and controlled by the class admin.
        // Example: Decode interaction data and update asset state based on it.

        DigitalAsset storage asset = digitalAssets[_assetId];
        require(msg.sender == asset.owner, "Only asset owner can trigger interactions."); // Example access control

        // Example: Decode interaction data (assuming it's a uint256 representing a "level up")
        uint256 levelUpValue = abi.decode(_interactionData, (uint256));

        // Example: Update state data (simple example, in real scenarios, state data might be more complex)
        bytes memory newStateData = abi.encode(levelUpValue); // For simplicity, just updating to the level
        asset.currentStateData = newStateData;

        emit AssetStateUpdated(_assetId, newStateData); // Important to emit state update events
    }

    // Fallback function to reject direct calls to interaction logic functions (if any are mistakenly called directly)
    fallback() external payable {
        revert("Direct calls to interaction logic functions are not allowed. Use interactWithAsset function.");
    }

    receive() external payable {}
}
```