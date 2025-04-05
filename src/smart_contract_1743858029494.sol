```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where content can be created, evolve dynamically, and interact with oracles.
 *
 * **Outline and Function Summary:**
 *
 * **Content Management:**
 * 1. `createContent(string _initialMetadataURI, ContentType _contentType)`: Allows users to create new content, storing initial metadata URI and content type.
 * 2. `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`:  Allows content creators to update the metadata URI of their content.
 * 3. `setContentState(uint256 _contentId, ContentState _newState)`: Allows content creators (and admins) to change the state of their content (e.g., active, inactive, draft).
 * 4. `getContentMetadataURI(uint256 _contentId)`: Retrieves the current metadata URI for a given content ID.
 * 5. `getContentState(uint256 _contentId)`: Retrieves the current state of a given content ID.
 * 6. `getContentCreator(uint256 _contentId)`: Retrieves the address of the creator of a given content ID.
 * 7. `getContentType(uint256 _contentId)`: Retrieves the content type of a given content ID.
 * 8. `getContentCreationTimestamp(uint256 _contentId)`: Retrieves the timestamp when the content was created.
 * 9. `getContentLastUpdatedTimestamp(uint256 _contentId)`: Retrieves the timestamp of the last metadata update for content.
 * 10. `deleteContent(uint256 _contentId)`: Allows content creators (and admins) to delete content (marks as deleted, doesn't actually remove data).
 *
 * **Dynamic Content & Oracles:**
 * 11. `registerOracle(address _oracleAddress, OracleType _oracleType)`: Allows admins to register trusted oracle addresses and their types.
 * 12. `requestDynamicUpdate(uint256 _contentId, OracleType _oracleType, bytes _oracleQueryData)`: Allows content creators to request a dynamic update based on oracle data.
 * 13. `fulfillDynamicUpdate(uint256 _contentId, OracleType _oracleType, bytes _oracleResponseData)`:  Callable by registered oracles to provide data for dynamic content updates.
 * 14. `getContentDynamicData(uint256 _contentId, OracleType _oracleType)`: Retrieves the dynamic data associated with content and a specific oracle type.
 *
 * **Content Interaction & Community:**
 * 15. `voteOnContent(uint256 _contentId, VoteType _voteType)`: Allows users to vote on content (e.g., upvote, downvote).
 * 16. `getContentVotes(uint256 _contentId, VoteType _voteType)`: Retrieves the vote count for a specific content and vote type.
 * 17. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 * 18. `getContentReports(uint256 _contentId)`: Retrieves the list of reports for a given content ID (admin function).
 *
 * **Admin & Utility:**
 * 19. `addAdmin(address _newAdmin)`: Allows current admins to add new admin addresses.
 * 20. `removeAdmin(address _adminToRemove)`: Allows current admins to remove admin addresses.
 * 21. `isAdmin(address _address)`: Checks if an address is an admin.
 * 22. `pauseContract()`: Allows admins to pause the contract, halting critical functions.
 * 23. `unpauseContract()`: Allows admins to unpause the contract.
 * 24. `isPaused()`: Checks if the contract is currently paused.
 * 25. `withdrawContractBalance(address _recipient)`: Allows admins to withdraw contract balance (e.g., fees collected).
 */
contract DynamicContentPlatform {

    // Enums
    enum ContentType { ARTICLE, VIDEO, IMAGE, AUDIO, DOCUMENT, OTHER }
    enum ContentState { DRAFT, ACTIVE, INACTIVE, DELETED, PENDING_REVIEW }
    enum OracleType { WEATHER, NEWS, SPORTS, FINANCE, CUSTOM }
    enum VoteType { UPVOTE, DOWNVOTE }

    // Structs
    struct Content {
        address creator;
        string metadataURI;
        ContentType contentType;
        ContentState state;
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        bool exists; // Flag to indicate if content was ever created (even if deleted)
    }

    struct Oracle {
        OracleType oracleType;
        bool isRegistered;
    }

    struct DynamicData {
        bytes data;
        uint256 lastUpdated;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
    }


    // State Variables
    mapping(uint256 => Content) public contents; // Content ID => Content Struct
    uint256 public contentCount;

    mapping(address => Oracle) public oracles; // Oracle Address => Oracle Struct
    address[] public oracleAddresses;

    mapping(uint256 => mapping(OracleType => DynamicData)) public contentDynamicData; // Content ID => OracleType => Dynamic Data

    mapping(uint256 => mapping(VoteType => uint256)) public contentVotes; // Content ID => VoteType => Vote Count
    mapping(uint256 => Report[]) public contentReports; // Content ID => Array of Reports

    mapping(address => bool) public admins;
    address[] public adminAddresses;
    bool public paused;

    // Events
    event ContentCreated(uint256 contentId, address creator, string metadataURI, ContentType contentType);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentStateChanged(uint256 contentId, ContentState newState);
    event ContentDeleted(uint256 contentId);
    event OracleRegistered(address oracleAddress, OracleType oracleType);
    event DynamicUpdateRequestRequested(uint256 contentId, OracleType oracleType, address requester);
    event DynamicUpdateFulfilled(uint256 contentId, OracleType oracleType, address oracle);
    event ContentVoted(uint256 contentId, address voter, VoteType voteType);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event AdminAdded(address newAdmin, address addedBy);
    event AdminRemoved(address removedAdmin, address removedBy);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event BalanceWithdrawn(address recipient, uint256 amount);


    // Modifiers
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contents[_contentId].exists, "Content does not exist.");
        _;
    }

    modifier contentCreatorOnly(uint256 _contentId) {
        require(contents[_contentId].creator == msg.sender, "Only content creator can perform this action.");
        _;
    }

    modifier validOracle(address _oracleAddress) {
        require(oracles[_oracleAddress].isRegistered, "Oracle address is not registered.");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");
        _;
    }


    // Constructor
    constructor() {
        admins[msg.sender] = true; // Deployer is initial admin
        adminAddresses.push(msg.sender);
    }


    // ------------------------ Content Management Functions ------------------------

    /**
     * @dev Creates new content.
     * @param _initialMetadataURI URI pointing to the initial metadata of the content.
     * @param _contentType Type of the content (e.g., ARTICLE, VIDEO).
     */
    function createContent(string memory _initialMetadataURI, ContentType _contentType) external whenNotPaused {
        contentCount++;
        contents[contentCount] = Content({
            creator: msg.sender,
            metadataURI: _initialMetadataURI,
            contentType: _contentType,
            state: ContentState.DRAFT, // Initial state is draft
            creationTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            exists: true
        });
        emit ContentCreated(contentCount, msg.sender, _initialMetadataURI, _contentType);
    }

    /**
     * @dev Updates the metadata URI of existing content. Only content creator can update.
     * @param _contentId ID of the content to update.
     * @param _newMetadataURI New URI pointing to the content's metadata.
     */
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) external whenNotPaused validContentId contentExists(_contentId) contentCreatorOnly(_contentId) {
        contents[_contentId].metadataURI = _newMetadataURI;
        contents[_contentId].lastUpdatedTimestamp = block.timestamp;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /**
     * @dev Sets the state of content. Content creator or admin can change state.
     * @param _contentId ID of the content to update.
     * @param _newState New state of the content (e.g., ACTIVE, INACTIVE).
     */
    function setContentState(uint256 _contentId, ContentState _newState) external whenNotPaused validContentId contentExists(_contentId) {
        require(contents[_contentId].creator == msg.sender || isAdmin(msg.sender), "Only creator or admin can set content state.");
        contents[_contentId].state = _newState;
        emit ContentStateChanged(_contentId, _newState);
    }

    /**
     * @dev Retrieves the metadata URI for a given content ID.
     * @param _contentId ID of the content.
     * @return string Metadata URI of the content.
     */
    function getContentMetadataURI(uint256 _contentId) external view validContentId contentExists(_contentId) returns (string memory) {
        return contents[_contentId].metadataURI;
    }

    /**
     * @dev Retrieves the state of a given content ID.
     * @param _contentId ID of the content.
     * @return ContentState State of the content.
     */
    function getContentState(uint256 _contentId) external view validContentId contentExists(_contentId) returns (ContentState) {
        return contents[_contentId].state;
    }

    /**
     * @dev Retrieves the creator address of a given content ID.
     * @param _contentId ID of the content.
     * @return address Creator address.
     */
    function getContentCreator(uint256 _contentId) external view validContentId contentExists(_contentId) returns (address) {
        return contents[_contentId].creator;
    }

    /**
     * @dev Retrieves the content type of a given content ID.
     * @param _contentId ID of the content.
     * @return ContentType Type of the content.
     */
    function getContentType(uint256 _contentId) external view validContentId contentExists(_contentId) returns (ContentType) {
        return contents[_contentId].contentType;
    }

    /**
     * @dev Retrieves the creation timestamp of a given content ID.
     * @param _contentId ID of the content.
     * @return uint256 Creation timestamp.
     */
    function getContentCreationTimestamp(uint256 _contentId) external view validContentId contentExists(_contentId) returns (uint256) {
        return contents[_contentId].creationTimestamp;
    }

    /**
     * @dev Retrieves the last updated timestamp of a given content ID.
     * @param _contentId ID of the content.
     * @return uint256 Last updated timestamp.
     */
    function getContentLastUpdatedTimestamp(uint256 _contentId) external view validContentId contentExists(_contentId) returns (uint256) {
        return contents[_contentId].lastUpdatedTimestamp;
    }

    /**
     * @dev Marks content as deleted. Content creator or admin can delete.
     * @param _contentId ID of the content to delete.
     */
    function deleteContent(uint256 _contentId) external whenNotPaused validContentId contentExists(_contentId) {
        require(contents[_contentId].creator == msg.sender || isAdmin(msg.sender), "Only creator or admin can delete content.");
        contents[_contentId].state = ContentState.DELETED;
        emit ContentDeleted(_contentId);
    }


    // ------------------------ Dynamic Content & Oracle Functions ------------------------

    /**
     * @dev Registers a new oracle address and its type. Only admins can register oracles.
     * @param _oracleAddress Address of the oracle contract or account.
     * @param _oracleType Type of data the oracle provides (e.g., WEATHER, NEWS).
     */
    function registerOracle(address _oracleAddress, OracleType _oracleType) external onlyAdmin whenNotPaused {
        require(!oracles[_oracleAddress].isRegistered, "Oracle already registered.");
        oracles[_oracleAddress] = Oracle({oracleType: _oracleType, isRegistered: true});
        oracleAddresses.push(_oracleAddress);
        emit OracleRegistered(_oracleAddress, _oracleType);
    }

    /**
     * @dev Allows content creators to request a dynamic update for their content from a registered oracle.
     * @param _contentId ID of the content to be updated dynamically.
     * @param _oracleType Type of oracle to be used for the update.
     * @param _oracleQueryData Data to be sent to the oracle as part of the request.
     */
    function requestDynamicUpdate(uint256 _contentId, OracleType _oracleType, bytes memory _oracleQueryData) external whenNotPaused validContentId contentExists(_contentId) contentCreatorOnly(_contentId) {
        // In a real application, you would likely emit an event here that an off-chain service (oracle listener) would pick up.
        // For simplicity in this example, we're assuming a direct call to `fulfillDynamicUpdate` from a simulated oracle.
        emit DynamicUpdateRequestRequested(_contentId, _oracleType, msg.sender);
        // In a real system, trigger oracle call here (e.g., via Chainlink, Band Protocol, etc.)
        // For this example, we will simulate oracle response in `fulfillDynamicUpdate`
    }

    /**
     * @dev Function for registered oracles to fulfill a dynamic update request.
     * @param _contentId ID of the content being updated.
     * @param _oracleType Type of oracle fulfilling the request.
     * @param _oracleResponseData Data provided by the oracle as the dynamic update.
     */
    function fulfillDynamicUpdate(uint256 _contentId, OracleType _oracleType, bytes memory _oracleResponseData) external validOracle(msg.sender) whenNotPaused validContentId contentExists(_contentId) {
        require(oracles[msg.sender].oracleType == _oracleType, "Oracle type mismatch.");
        contentDynamicData[_contentId][_oracleType] = DynamicData({
            data: _oracleResponseData,
            lastUpdated: block.timestamp
        });
        emit DynamicUpdateFulfilled(_contentId, _oracleType, msg.sender);
    }

    /**
     * @dev Retrieves the dynamic data associated with content for a specific oracle type.
     * @param _contentId ID of the content.
     * @param _oracleType Type of oracle data to retrieve.
     * @return bytes Dynamic data provided by the oracle.
     */
    function getContentDynamicData(uint256 _contentId, OracleType _oracleType) external view validContentId contentExists(_contentId) returns (bytes memory) {
        return contentDynamicData[_contentId][_oracleType].data;
    }


    // ------------------------ Content Interaction & Community Functions ------------------------

    /**
     * @dev Allows users to vote on content.
     * @param _contentId ID of the content to vote on.
     * @param _voteType Type of vote (UPVOTE or DOWNVOTE).
     */
    function voteOnContent(uint256 _contentId, VoteType _voteType) external whenNotPaused validContentId contentExists(_contentId) {
        contentVotes[_contentId][_voteType]++;
        emit ContentVoted(_contentId, msg.sender, _voteType);
    }

    /**
     * @dev Retrieves the vote count for a specific content and vote type.
     * @param _contentId ID of the content.
     * @param _voteType Type of vote to count (UPVOTE or DOWNVOTE).
     * @return uint256 Vote count.
     */
    function getContentVotes(uint256 _contentId, VoteType _voteType) external view validContentId contentExists(_contentId) returns (uint256) {
        return contentVotes[_contentId][_voteType];
    }

    /**
     * @dev Allows users to report content for moderation.
     * @param _contentId ID of the content being reported.
     * @param _reportReason Reason for reporting the content.
     */
    function reportContent(uint256 _contentId, string memory _reportReason) external whenNotPaused validContentId contentExists(_contentId) {
        contentReports[_contentId].push(Report({
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp
        }));
        emit ContentReported(_contentId, msg.sender, _reportReason);
    }

    /**
     * @dev Retrieves the list of reports for a given content ID. Only admins can access reports.
     * @param _contentId ID of the content.
     * @return Report[] Array of reports for the content.
     */
    function getContentReports(uint256 _contentId) external view onlyAdmin validContentId contentExists(_contentId) returns (Report[] memory) {
        return contentReports[_contentId];
    }


    // ------------------------ Admin & Utility Functions ------------------------

    /**
     * @dev Adds a new admin address. Only existing admins can add new admins.
     * @param _newAdmin Address to be added as an admin.
     */
    function addAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(!admins[_newAdmin], "Address is already an admin.");
        admins[_newAdmin] = true;
        adminAddresses.push(_newAdmin);
        emit AdminAdded(_newAdmin, msg.sender);
    }

    /**
     * @dev Removes an admin address. Only existing admins can remove admins. Cannot remove self.
     * @param _adminToRemove Address to be removed from admins.
     */
    function removeAdmin(address _adminToRemove) external onlyAdmin whenNotPaused {
        require(_adminToRemove != msg.sender, "Cannot remove yourself as admin.");
        require(admins[_adminToRemove], "Address is not an admin.");
        admins[_adminToRemove] = false;
        // Remove from adminAddresses array (optional, for cleaner admin list)
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == _adminToRemove) {
                adminAddresses[i] = adminAddresses[adminAddresses.length - 1];
                adminAddresses.pop();
                break;
            }
        }
        emit AdminRemoved(_adminToRemove, msg.sender);
    }

    /**
     * @dev Checks if an address is an admin.
     * @param _address Address to check.
     * @return bool True if address is admin, false otherwise.
     */
    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    /**
     * @dev Pauses the contract, preventing critical functions from being executed. Only admins can pause.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing functions to be executed again. Only admins can unpause.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return bool True if contract is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Allows admins to withdraw the contract's balance to a specified address.
     * @param _recipient Address to receive the withdrawn balance.
     */
    function withdrawContractBalance(address payable _recipient) external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero.");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Withdrawal failed.");
        emit BalanceWithdrawn(_recipient, balance);
    }

    // Fallback function to receive Ether (optional, for collecting platform fees etc.)
    receive() external payable {}
}
```