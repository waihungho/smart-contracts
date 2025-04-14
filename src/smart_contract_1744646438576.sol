```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where users can create, curate, and dynamically update content.
 *
 * Function Summary:
 *
 * 1.  registerContentCreator(): Allows users to register as content creators on the platform.
 * 2.  createContentSpace(string memory _spaceName, string memory _spaceDescription): Content creators can create their own content spaces.
 * 3.  addContentToSpace(uint256 _spaceId, string memory _contentHash, string memory _metadataURI, uint256 _validUntil): Add content to a specific content space, with IPFS hash and metadata URI, and expiry.
 * 4.  updateContentMetadata(uint256 _spaceId, uint256 _contentId, string memory _newMetadataURI): Update the metadata URI of existing content.
 * 5.  setContentExpiry(uint256 _spaceId, uint256 _contentId, uint256 _newValidUntil): Change the expiry timestamp of content.
 * 6.  reportContent(uint256 _spaceId, uint256 _contentId, string memory _reportReason): Users can report content for violations.
 * 7.  voteOnReport(uint256 _spaceId, uint256 _contentId, uint256 _reportId, bool _supportReport): Registered curators can vote on content reports.
 * 8.  resolveContentReport(uint256 _spaceId, uint256 _contentId, uint256 _reportId): Admin function to resolve a content report after curator voting.
 * 9.  getContentSpaceDetails(uint256 _spaceId): Retrieve details of a content space, including content IDs and creator.
 * 10. getContentDetails(uint256 _spaceId, uint256 _contentId): Get specific details of content within a space.
 * 11. getContentReportDetails(uint256 _spaceId, uint256 _contentId, uint256 _reportId): Fetch details of a specific content report.
 * 12. subscribeToSpace(uint256 _spaceId): Users can subscribe to a content space for updates (future notification mechanism).
 * 13. unsubscribeFromSpace(uint256 _spaceId): Users can unsubscribe from a content space.
 * 14. getContentSpaceSubscriberCount(uint256 _spaceId): Get the number of subscribers to a content space.
 * 15. setCuratorRole(address _user): Admin function to assign curator role to an address for content moderation.
 * 16. removeCuratorRole(address _user): Admin function to remove curator role from an address.
 * 17. isCurator(address _user): Check if an address has curator role.
 * 18. setPlatformFee(uint256 _newFeePercentage): Admin function to set a platform fee percentage on content spaces (potential revenue model).
 * 19. withdrawPlatformFees(address _recipient): Admin function to withdraw accumulated platform fees to a recipient address.
 * 20. pauseContract(): Admin function to pause all content creation and updates.
 * 21. unpauseContract(): Admin function to resume contract functionality.
 * 22. getContentSpacesByCreator(address _creator): Get a list of content space IDs created by a specific address.
 * 23. getContentCountInSpace(uint256 _spaceId): Get the total count of content items in a specific space.
 * 24. getActiveContentInSpace(uint256 _spaceId): Get a list of content IDs that are currently active (not expired) in a space.
 * 25. getExpiredContentInSpace(uint256 _spaceId): Get a list of content IDs that are expired in a space.
 */

contract DecentralizedDynamicContentPlatform {

    // --- State Variables ---

    address public admin;
    uint256 public platformFeePercentage; // Fee taken from content space creation (example revenue model)
    uint256 public platformFeesCollected;
    bool public paused;

    uint256 public contentSpaceCounter;
    uint256 public contentCounter;
    uint256 public reportCounter;

    mapping(address => bool) public isContentCreator;
    mapping(address => bool) public isCurator;

    struct ContentSpace {
        address creator;
        string spaceName;
        string spaceDescription;
        uint256 creationTimestamp;
        mapping(uint256 => ContentItem) contentItems; // contentId => ContentItem
        uint256 contentCount;
        mapping(address => bool) subscribers; // Subscriber addresses
        uint256 subscriberCount;
        uint256 platformFee; // Fee percentage for this space (can be space-specific or platform default)
    }
    mapping(uint256 => ContentSpace) public contentSpaces; // spaceId => ContentSpace

    struct ContentItem {
        uint256 spaceId;
        address creator;
        string contentHash; // IPFS hash of the actual content
        string metadataURI; // URI to metadata about the content (e.g., JSON on IPFS)
        uint256 creationTimestamp;
        uint256 validUntil; // Timestamp until which content is considered valid/active
        bool isActive;
        mapping(uint256 => ContentReport) reports; // reportId => ContentReport
        uint256 reportCount;
    }
    mapping(uint256 => ContentItem) public contentItemsGlobal; // contentCounter => ContentItem (for global access if needed)

    struct ContentReport {
        uint256 spaceId;
        uint256 contentId;
        address reporter;
        string reportReason;
        uint256 reportTimestamp;
        mapping(address => bool) curatorVotes; // curatorAddress => vote (true=support, false=reject)
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool resolved;
        bool reportApproved; // Result after resolution
    }
    mapping(uint256 => ContentReport) public contentReportsGlobal; // reportCounter => ContentReport


    // --- Events ---

    event ContentCreatorRegistered(address creator);
    event ContentSpaceCreated(uint256 spaceId, address creator, string spaceName);
    event ContentAdded(uint256 spaceId, uint256 contentId, address creator, string contentHash);
    event ContentMetadataUpdated(uint256 spaceId, uint256 contentId, string newMetadataURI);
    event ContentExpiryUpdated(uint256 spaceId, uint256 contentId, uint256 newValidUntil);
    event ContentReported(uint256 spaceId, uint256 contentId, uint256 reportId, address reporter, string reportReason);
    event ReportVoteCast(uint256 spaceId, uint256 contentId, uint256 reportId, address curator, bool supportReport);
    event ReportResolved(uint256 spaceId, uint256 contentId, uint256 reportId, bool reportApproved);
    event ContentSpaceSubscribed(uint256 spaceId, address subscriber);
    event ContentSpaceUnsubscribed(uint256 spaceId, address subscriber);
    event CuratorRoleSet(address curator);
    event CuratorRoleRemoved(address curator);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyContentCreator() {
        require(isContentCreator[msg.sender], "You are not registered as a content creator.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "You are not a registered curator.");
        _;
    }

    modifier spaceExists(uint256 _spaceId) {
        require(_spaceId > 0 && _spaceId <= contentSpaceCounter, "Content space does not exist.");
        _;
    }

    modifier contentExists(uint256 _spaceId, uint256 _contentId) {
        require(contentSpaces[_spaceId].contentItems[_contentId].creator != address(0), "Content does not exist in this space.");
        _;
    }

    modifier reportExists(uint256 _spaceId, uint256 _contentId, uint256 _reportId) {
        require(contentSpaces[_spaceId].contentItems[_contentId].reports[_reportId].reporter != address(0), "Report does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        platformFeePercentage = 0; // Default platform fee is 0%
        paused = false;
        contentSpaceCounter = 0;
        contentCounter = 0;
        reportCounter = 0;
    }


    // --- Functions ---

    /// @notice Allows users to register as content creators on the platform.
    function registerContentCreator() external notPaused {
        require(!isContentCreator[msg.sender], "You are already a registered content creator.");
        isContentCreator[msg.sender] = true;
        emit ContentCreatorRegistered(msg.sender);
    }

    /// @notice Content creators can create their own content spaces.
    /// @param _spaceName The name of the content space.
    /// @param _spaceDescription A brief description of the content space.
    function createContentSpace(string memory _spaceName, string memory _spaceDescription) external onlyContentCreator notPaused {
        contentSpaceCounter++;
        contentSpaces[contentSpaceCounter] = ContentSpace({
            creator: msg.sender,
            spaceName: _spaceName,
            spaceDescription: _spaceDescription,
            creationTimestamp: block.timestamp,
            contentCount: 0,
            subscriberCount: 0,
            platformFee: platformFeePercentage // Initially set to platform default, can be modified later if needed
        });

        // Example of platform fee collection (can be modified as needed)
        if (platformFeePercentage > 0) {
            uint256 feeAmount = (platformFeePercentage * 1 ether) / 100; // Example fee amount - adjust logic based on fee structure
            platformFeesCollected += feeAmount; // Track collected fees
            // In a real-world scenario, you might transfer tokens or ETH here
            // For simplicity, we are just tracking the collected fees in this example.
        }

        emit ContentSpaceCreated(contentSpaceCounter, msg.sender, _spaceName);
    }

    /// @notice Add content to a specific content space, with IPFS hash and metadata URI, and expiry.
    /// @param _spaceId The ID of the content space to add content to.
    /// @param _contentHash The IPFS hash of the content itself.
    /// @param _metadataURI URI pointing to the content's metadata (e.g., JSON on IPFS).
    /// @param _validUntil Timestamp until which the content is considered valid/active. Set to 0 for no expiry.
    function addContentToSpace(uint256 _spaceId, string memory _contentHash, string memory _metadataURI, uint256 _validUntil)
        external
        onlyContentCreator
        spaceExists(_spaceId)
        notPaused
    {
        require(contentSpaces[_spaceId].creator == msg.sender, "Only the space creator can add content.");
        contentCounter++;
        contentSpaces[_spaceId].contentCount++;

        ContentItem memory newItem = ContentItem({
            spaceId: _spaceId,
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            creationTimestamp: block.timestamp,
            validUntil: _validUntil,
            isActive: (_validUntil == 0 || block.timestamp < _validUntil), // Initially active if no expiry or not expired
            reportCount: 0
        });
        contentSpaces[_spaceId].contentItems[contentCounter] = newItem;
        contentItemsGlobal[contentCounter] = newItem; // Store globally for potential cross-space queries

        emit ContentAdded(_spaceId, contentCounter, msg.sender, _contentHash);
    }

    /// @notice Update the metadata URI of existing content.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item to update.
    /// @param _newMetadataURI The new metadata URI.
    function updateContentMetadata(uint256 _spaceId, uint256 _contentId, string memory _newMetadataURI)
        external
        onlyContentCreator
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        notPaused
    {
        require(contentSpaces[_spaceId].contentItems[_contentId].creator == msg.sender, "Only the content creator can update metadata.");
        contentSpaces[_spaceId].contentItems[_contentId].metadataURI = _newMetadataURI;
        contentItemsGlobal[_contentId].metadataURI = _newMetadataURI; // Update global as well
        emit ContentMetadataUpdated(_spaceId, _contentId, _newMetadataURI);
    }

    /// @notice Change the expiry timestamp of content.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item to update.
    /// @param _newValidUntil The new expiry timestamp. Set to 0 for no expiry.
    function setContentExpiry(uint256 _spaceId, uint256 _contentId, uint256 _newValidUntil)
        external
        onlyContentCreator
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        notPaused
    {
        require(contentSpaces[_spaceId].contentItems[_contentId].creator == msg.sender, "Only the content creator can set expiry.");
        contentSpaces[_spaceId].contentItems[_contentId].validUntil = _newValidUntil;
        contentSpaces[_spaceId].contentItems[_contentId].isActive = (_newValidUntil == 0 || block.timestamp < _newValidUntil);
        contentItemsGlobal[_contentId].validUntil = _newValidUntil;
        contentItemsGlobal[_contentId].isActive = (_newValidUntil == 0 || block.timestamp < _newValidUntil);
        emit ContentExpiryUpdated(_spaceId, _contentId, _newValidUntil);
    }

    /// @notice Users can report content for violations.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _spaceId, uint256 _contentId, string memory _reportReason)
        external
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        notPaused
    {
        reportCounter++;
        uint256 reportId = reportCounter;
        ContentReport memory newReport = ContentReport({
            spaceId: _spaceId,
            contentId: _contentId,
            reporter: msg.sender,
            reportReason: _reportReason,
            reportTimestamp: block.timestamp,
            positiveVotes: 0,
            negativeVotes: 0,
            resolved: false,
            reportApproved: false
        });
        contentSpaces[_spaceId].contentItems[_contentId].reports[reportId] = newReport;
        contentSpaces[_spaceId].contentItems[_contentId].reportCount++;
        contentReportsGlobal[reportId] = newReport;

        emit ContentReported(_spaceId, _contentId, reportId, msg.sender, _reportReason);
    }

    /// @notice Registered curators can vote on content reports.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item being reported.
    /// @param _reportId The ID of the report.
    /// @param _supportReport True to support the report (content violation), false to reject.
    function voteOnReport(uint256 _spaceId, uint256 _contentId, uint256 _reportId, bool _supportReport)
        external
        onlyCurator
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        reportExists(_spaceId, _contentId, _reportId)
        notPaused
    {
        ContentReport storage report = contentSpaces[_spaceId].contentItems[_contentId].reports[_reportId];
        require(!report.resolved, "Report is already resolved.");
        require(!report.curatorVotes[msg.sender], "You have already voted on this report.");

        report.curatorVotes[msg.sender] = _supportReport;
        if (_supportReport) {
            report.positiveVotes++;
        } else {
            report.negativeVotes++;
        }
        emit ReportVoteCast(_spaceId, _contentId, _reportId, msg.sender, _supportReport);
    }

    /// @notice Admin function to resolve a content report after curator voting.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item being reported.
    /// @param _reportId The ID of the report to resolve.
    function resolveContentReport(uint256 _spaceId, uint256 _contentId, uint256 _reportId)
        external
        onlyAdmin
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        reportExists(_spaceId, _contentId, _reportId)
        notPaused
    {
        ContentReport storage report = contentSpaces[_spaceId].contentItems[_contentId].reports[_reportId];
        require(!report.resolved, "Report is already resolved.");

        // Example resolution logic: If more positive votes than negative votes, approve report
        if (report.positiveVotes > report.negativeVotes) {
            report.reportApproved = true;
            // Implement content removal or other action based on report approval here.
            // For example, you could set content to inactive:
            contentSpaces[_spaceId].contentItems[_contentId].isActive = false;
            contentItemsGlobal[_contentId].isActive = false;
        } else {
            report.reportApproved = false;
        }
        report.resolved = true;
        emit ReportResolved(_spaceId, _contentId, _reportId, report.reportApproved);
    }

    /// @notice Retrieve details of a content space, including content IDs and creator.
    /// @param _spaceId The ID of the content space.
    /// @return spaceCreator, spaceName, spaceDescription, creationTimestamp, contentCount, subscriberCount
    function getContentSpaceDetails(uint256 _spaceId)
        external
        view
        spaceExists(_spaceId)
        returns (address spaceCreator, string memory spaceName, string memory spaceDescription, uint256 creationTimestamp, uint256 contentCount, uint256 subscriberCount)
    {
        ContentSpace storage space = contentSpaces[_spaceId];
        return (space.creator, space.spaceName, space.spaceDescription, space.creationTimestamp, space.contentCount, space.subscriberCount);
    }

    /// @notice Get specific details of content within a space.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item.
    /// @return creator, contentHash, metadataURI, creationTimestamp, validUntil, isActive, reportCount
    function getContentDetails(uint256 _spaceId, uint256 _contentId)
        external
        view
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        returns (address creator, string memory contentHash, string memory metadataURI, uint256 creationTimestamp, uint256 validUntil, bool isActive, uint256 reportCount)
    {
        ContentItem storage content = contentSpaces[_spaceId].contentItems[_contentId];
        return (content.creator, content.contentHash, content.metadataURI, content.creationTimestamp, content.validUntil, content.isActive, content.reportCount);
    }

    /// @notice Fetch details of a specific content report.
    /// @param _spaceId The ID of the content space.
    /// @param _contentId The ID of the content item being reported.
    /// @param _reportId The ID of the report.
    /// @return reporter, reportReason, reportTimestamp, positiveVotes, negativeVotes, resolved, reportApproved
    function getContentReportDetails(uint256 _spaceId, uint256 _contentId, uint256 _reportId)
        external
        view
        spaceExists(_spaceId)
        contentExists(_spaceId, _contentId)
        reportExists(_spaceId, _contentId, _reportId)
        returns (address reporter, string memory reportReason, uint256 reportTimestamp, uint256 positiveVotes, uint256 negativeVotes, bool resolved, bool reportApproved)
    {
        ContentReport storage report = contentSpaces[_spaceId].contentItems[_contentId].reports[_reportId];
        return (report.reporter, report.reportReason, report.reportTimestamp, report.positiveVotes, report.negativeVotes, report.resolved, report.reportApproved);
    }

    /// @notice Users can subscribe to a content space for updates (future notification mechanism).
    /// @param _spaceId The ID of the content space to subscribe to.
    function subscribeToSpace(uint256 _spaceId) external spaceExists(_spaceId) notPaused {
        require(!contentSpaces[_spaceId].subscribers[msg.sender], "Already subscribed to this space.");
        contentSpaces[_spaceId].subscribers[msg.sender] = true;
        contentSpaces[_spaceId].subscriberCount++;
        emit ContentSpaceSubscribed(_spaceId, msg.sender);
    }

    /// @notice Users can unsubscribe from a content space.
    /// @param _spaceId The ID of the content space to unsubscribe from.
    function unsubscribeFromSpace(uint256 _spaceId) external spaceExists(_spaceId) notPaused {
        require(contentSpaces[_spaceId].subscribers[msg.sender], "Not subscribed to this space.");
        delete contentSpaces[_spaceId].subscribers[msg.sender];
        contentSpaces[_spaceId].subscriberCount--;
        emit ContentSpaceUnsubscribed(_spaceId, msg.sender);
    }

    /// @notice Get the number of subscribers to a content space.
    /// @param _spaceId The ID of the content space.
    /// @return The number of subscribers.
    function getContentSpaceSubscriberCount(uint256 _spaceId) external view spaceExists(_spaceId) returns (uint256) {
        return contentSpaces[_spaceId].subscriberCount;
    }

    /// @notice Admin function to assign curator role to an address for content moderation.
    /// @param _user The address to be assigned the curator role.
    function setCuratorRole(address _user) external onlyAdmin notPaused {
        isCurator[_user] = true;
        emit CuratorRoleSet(_user);
    }

    /// @notice Admin function to remove curator role from an address.
    /// @param _user The address to remove the curator role from.
    function removeCuratorRole(address _user) external onlyAdmin notPaused {
        isCurator[_user] = false;
        emit CuratorRoleRemoved(_user);
    }

    /// @notice Check if an address has curator role.
    /// @param _user The address to check.
    /// @return True if the address is a curator, false otherwise.
    function isCurator(address _user) external view returns (bool) {
        return isCurator[_user];
    }

    /// @notice Admin function to set a platform fee percentage on content spaces (potential revenue model).
    /// @param _newFeePercentage The new platform fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _newFeePercentage) external onlyAdmin notPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @notice Admin function to withdraw accumulated platform fees to a recipient address.
    /// @param _recipient The address to receive the withdrawn fees.
    function withdrawPlatformFees(address _recipient) external onlyAdmin notPaused {
        require(platformFeesCollected > 0, "No platform fees collected to withdraw.");
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0;
        // In a real-world scenario, you would transfer tokens or ETH to _recipient here.
        // For simplicity, we are just emitting an event and resetting the collected fees.
        emit PlatformFeesWithdrawn(_recipient, amountToWithdraw);
    }

    /// @notice Admin function to pause all content creation and updates.
    function pauseContract() external onlyAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to resume contract functionality.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Get a list of content space IDs created by a specific address.
    /// @param _creator The address of the content creator.
    /// @return An array of content space IDs.
    function getContentSpacesByCreator(address _creator) external view returns (uint256[] memory) {
        uint256[] memory spaceIds = new uint256[](contentSpaceCounter); // Maximum possible spaces
        uint256 count = 0;
        for (uint256 i = 1; i <= contentSpaceCounter; i++) {
            if (contentSpaces[i].creator == _creator) {
                spaceIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of spaces found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = spaceIds[i];
        }
        return result;
    }

    /// @notice Get the total count of content items in a specific space.
    /// @param _spaceId The ID of the content space.
    /// @return The number of content items in the space.
    function getContentCountInSpace(uint256 _spaceId) external view spaceExists(_spaceId) returns (uint256) {
        return contentSpaces[_spaceId].contentCount;
    }

    /// @notice Get a list of content IDs that are currently active (not expired) in a space.
    /// @param _spaceId The ID of the content space.
    /// @return An array of active content IDs.
    function getActiveContentInSpace(uint256 _spaceId) external view spaceExists(_spaceId) returns (uint256[] memory) {
        uint256[] memory activeContentIds = new uint256[](contentSpaces[_spaceId].contentCount); // Max possible active content
        uint256 count = 0;
        for (uint256 i = 1; i <= contentCounter; i++) {
            if (contentItemsGlobal[i].spaceId == _spaceId && contentItemsGlobal[i].isActive) {
                activeContentIds[count] = i;
                count++;
            }
        }
        // Resize the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeContentIds[i];
        }
        return result;
    }

    /// @notice Get a list of content IDs that are expired in a space.
    /// @param _spaceId The ID of the content space.
    /// @return An array of expired content IDs.
    function getExpiredContentInSpace(uint256 _spaceId) external view spaceExists(_spaceId) returns (uint256[] memory) {
        uint256[] memory expiredContentIds = new uint256[](contentSpaces[_spaceId].contentCount); // Max possible expired content
        uint256 count = 0;
        for (uint256 i = 1; i <= contentCounter; i++) {
            if (contentItemsGlobal[i].spaceId == _spaceId && !contentItemsGlobal[i].isActive) {
                expiredContentIds[count] = i;
                count++;
            }
        }
        // Resize the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = expiredContentIds[i];
        }
        return result;
    }
}
```