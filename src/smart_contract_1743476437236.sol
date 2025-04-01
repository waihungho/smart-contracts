```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Content Marketplace with Dynamic Royalties and Collaborative Curation
 * @author Bard (Example - Not for Production)
 *
 * @dev This contract implements a decentralized content marketplace where creators can upload content,
 * set dynamic royalties, and the community collaboratively curates and moderates the platform.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Functionality - Content Management:**
 *    - `uploadContent(string _contentHash, string _metadataURI, uint256 _initialPrice, uint256 _initialRoyaltyPercentage)`: Allows creators to upload content with metadata, price, and initial royalty.
 *    - `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`: Allows creators to update content metadata.
 *    - `updateContentPrice(uint256 _contentId, uint256 _newPrice)`: Allows creators to update content price.
 *    - `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 *    - `getContentList(uint256 _start, uint256 _count)`: Retrieves a paginated list of content IDs.
 *    - `getContentCount()`: Returns the total number of content items.
 *
 * **2. Dynamic Royalties & Revenue Sharing:**
 *    - `setDynamicRoyaltyCurve(uint256 _contentId, uint256[] memory _salesThresholds, uint256[] memory _royaltyPercentages)`: Allows creators to define a dynamic royalty curve based on sales volume.
 *    - `purchaseContent(uint256 _contentId)`: Allows users to purchase content, triggering royalty calculations based on the dynamic curve.
 *    - `withdrawCreatorEarnings()`: Allows creators to withdraw their accumulated earnings.
 *    - `getCreatorEarnings(address _creator)`: Retrieves the current earnings balance of a creator.
 *
 * **3. Collaborative Curation & Moderation:**
 *    - `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 *    - `voteOnContentReport(uint256 _reportId, bool _approve)`: Allows designated moderators to vote on content reports.
 *    - `moderateContent(uint256 _contentId)`: Executes moderation actions on content based on report voting results (e.g., hide content).
 *    - `addModerator(address _moderator)`: Allows the contract owner to add moderators.
 *    - `removeModerator(address _moderator)`: Allows the contract owner to remove moderators.
 *    - `getModeratorList()`: Retrieves a list of current moderators.
 *
 * **4. Reputation System (Basic):**
 *    - `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (e.g., for positive contributions).
 *    - `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (e.g., for negative actions).
 *    - `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 *
 * **5. Advanced Features & Governance (Simplified):**
 *    - `setPlatformFeePercentage(uint256 _newFeePercentage)`: Allows the contract owner to set the platform fee percentage charged on sales.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows the contract owner to pause core functionalities in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to unpause core functionalities.
 */

contract DecentralizedContentMarketplace {

    // -------- Structs and Enums --------

    struct Content {
        uint256 id;
        address creator;
        string contentHash;
        string metadataURI;
        uint256 price;
        uint256 royaltyPercentage; // Initial royalty percentage
        uint256 salesCount;
        bool isModerated;
        bool isHidden;
        uint256 uploadTimestamp;
        mapping(uint256 => uint256) dynamicRoyaltyCurve; // Sales threshold => Royalty percentage
    }

    struct ContentReport {
        uint256 id;
        uint256 contentId;
        address reporter;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool resolved;
        bool approved; // True if report is approved for moderation
    }

    // -------- State Variables --------

    address public owner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public contentCounter = 0;
    uint256 public reportCounter = 0;
    mapping(uint256 => Content) public contentItems;
    mapping(uint256 => ContentReport) public contentReports;
    mapping(address => uint256) public creatorEarnings;
    mapping(address => uint256) public userReputation;
    mapping(address => bool) public moderators;
    address[] public moderatorList;
    bool public paused = false;

    // -------- Events --------

    event ContentUploaded(uint256 contentId, address creator, string contentHash, string metadataURI, uint256 price, uint256 royaltyPercentage);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentPriceUpdated(uint256 contentId, uint256 newPrice);
    event ContentPurchased(uint256 contentId, address buyer, uint256 price, uint256 royaltyAmount, uint256 platformFee);
    event DynamicRoyaltyCurveSet(uint256 contentId);
    event ContentReported(uint256 reportId, uint256 contentId, address reporter, string reason);
    event ContentReportVoteCast(uint256 reportId, address moderator, bool approve);
    event ContentModerated(uint256 contentId, bool isHidden);
    event ModeratorAdded(address moderator);
    event ModeratorRemoved(address moderator);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event ContractPaused();
    event ContractUnpaused();
    event ReputationIncreased(address user, uint256 amount);
    event ReputationDecreased(address user, uint256 amount);


    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
    }

    // -------- 1. Core Functionality - Content Management --------

    /// @notice Allows creators to upload content to the marketplace.
    /// @param _contentHash Hash of the content file (e.g., IPFS hash).
    /// @param _metadataURI URI pointing to the content metadata (e.g., IPFS URI).
    /// @param _initialPrice Price of the content in wei.
    /// @param _initialRoyaltyPercentage Initial royalty percentage for the content (0-100).
    function uploadContent(
        string memory _contentHash,
        string memory _metadataURI,
        uint256 _initialPrice,
        uint256 _initialRoyaltyPercentage
    ) external whenNotPaused {
        require(bytes(_contentHash).length > 0 && bytes(_metadataURI).length > 0, "Content hash and metadata URI cannot be empty.");
        require(_initialPrice > 0, "Price must be greater than zero.");
        require(_initialRoyaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        contentCounter++;
        contentItems[contentCounter] = Content({
            id: contentCounter,
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            price: _initialPrice,
            royaltyPercentage: _initialRoyaltyPercentage,
            salesCount: 0,
            isModerated: false,
            isHidden: false,
            uploadTimestamp: block.timestamp,
            dynamicRoyaltyCurve: mapping(uint256 => uint256)() // Initialize empty dynamic royalty curve
        });

        emit ContentUploaded(contentCounter, msg.sender, _contentHash, _metadataURI, _initialPrice, _initialRoyaltyPercentage);
    }

    /// @notice Allows creators to update the metadata URI of their content.
    /// @param _contentId ID of the content to update.
    /// @param _newMetadataURI New metadata URI for the content.
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) external whenNotPaused {
        require(contentItems[_contentId].creator == msg.sender, "Only the content creator can update metadata.");
        require(bytes(_newMetadataURI).length > 0, "Metadata URI cannot be empty.");
        contentItems[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /// @notice Allows creators to update the price of their content.
    /// @param _contentId ID of the content to update.
    /// @param _newPrice New price for the content in wei.
    function updateContentPrice(uint256 _contentId, uint256 _newPrice) external whenNotPaused {
        require(contentItems[_contentId].creator == msg.sender, "Only the content creator can update price.");
        require(_newPrice > 0, "Price must be greater than zero.");
        contentItems[_contentId].price = _newPrice;
        emit ContentPriceUpdated(_contentId, _newPrice);
    }

    /// @notice Retrieves detailed information about a specific content item.
    /// @param _contentId ID of the content to retrieve.
    /// @return Content struct containing content details.
    function getContentDetails(uint256 _contentId) external view returns (Content memory) {
        require(_contentId > 0 && _contentId <= contentCounter, "Invalid content ID.");
        return contentItems[_contentId];
    }

    /// @notice Retrieves a paginated list of content IDs.
    /// @param _start Index to start retrieving content IDs from.
    /// @param _count Number of content IDs to retrieve.
    /// @return Array of content IDs.
    function getContentList(uint256 _start, uint256 _count) external view returns (uint256[] memory) {
        require(_start >= 0, "Start index must be non-negative.");
        require(_count > 0, "Count must be greater than zero.");

        uint256 endIndex = _start + _count;
        if (endIndex > contentCounter) {
            endIndex = contentCounter;
        }

        uint256[] memory contentIdList = new uint256[](endIndex - _start);
        uint256 index = 0;
        for (uint256 i = _start; i < endIndex; i++) {
            if (contentItems[i+1].id != 0) { // Check if content exists (to skip gaps if any, though unlikely in this implementation)
                contentIdList[index] = i + 1;
                index++;
            }
        }
        return contentIdList;
    }

    /// @notice Returns the total number of content items uploaded.
    function getContentCount() external view returns (uint256) {
        return contentCounter;
    }


    // -------- 2. Dynamic Royalties & Revenue Sharing --------

    /// @notice Allows creators to set a dynamic royalty curve for their content.
    /// @dev The curve is defined by sales thresholds and corresponding royalty percentages.
    /// @param _contentId ID of the content to set the curve for.
    /// @param _salesThresholds Array of sales count thresholds (e.g., [100, 1000, 10000]).
    /// @param _royaltyPercentages Array of royalty percentages corresponding to the thresholds (e.g., [15, 20, 25]).
    function setDynamicRoyaltyCurve(
        uint256 _contentId,
        uint256[] memory _salesThresholds,
        uint256[] memory _royaltyPercentages
    ) external whenNotPaused {
        require(contentItems[_contentId].creator == msg.sender, "Only the content creator can set dynamic royalty curve.");
        require(_salesThresholds.length == _royaltyPercentages.length, "Thresholds and percentages arrays must have the same length.");
        require(_salesThresholds.length > 0, "Dynamic royalty curve must have at least one threshold.");

        // Clear existing curve
        delete contentItems[_contentId].dynamicRoyaltyCurve;

        // Set new curve
        for (uint256 i = 0; i < _salesThresholds.length; i++) {
            require(_royaltyPercentages[i] <= 100, "Royalty percentage must be between 0 and 100.");
            contentItems[_contentId].dynamicRoyaltyCurve[_salesThresholds[i]] = _royaltyPercentages[i];
        }
        emit DynamicRoyaltyCurveSet(_contentId);
    }


    /// @notice Allows users to purchase content.
    /// @param _contentId ID of the content to purchase.
    function purchaseContent(uint256 _contentId) external payable whenNotPaused {
        require(_contentId > 0 && _contentId <= contentCounter, "Invalid content ID.");
        require(!contentItems[_contentId].isHidden, "Content is hidden and cannot be purchased.");
        require(msg.value >= contentItems[_contentId].price, "Insufficient payment.");

        uint256 contentPrice = contentItems[_contentId].price;
        uint256 royaltyPercentage = _getCurrentRoyaltyPercentage(_contentId);
        uint256 royaltyAmount = (contentPrice * royaltyPercentage) / 100;
        uint256 platformFee = (contentPrice * platformFeePercentage) / 100;
        uint256 creatorPayout = contentPrice - royaltyAmount - platformFee;

        // Transfer funds
        payable(contentItems[_contentId].creator).transfer(creatorPayout);
        payable(owner).transfer(platformFee);
        creatorEarnings[contentItems[_contentId].creator] += royaltyAmount; // Accumulate royalty earnings

        contentItems[_contentId].salesCount++;

        emit ContentPurchased(_contentId, msg.sender, contentPrice, royaltyAmount, platformFee);

        // Refund any excess payment
        if (msg.value > contentPrice) {
            payable(msg.sender).transfer(msg.value - contentPrice);
        }
    }

    /// @dev Internal function to determine the current royalty percentage based on the dynamic curve.
    /// @param _contentId ID of the content.
    /// @return Current royalty percentage.
    function _getCurrentRoyaltyPercentage(uint256 _contentId) internal view returns (uint256) {
        uint256 salesCount = contentItems[_contentId].salesCount;
        uint256 currentRoyaltyPercentage = contentItems[_contentId].royaltyPercentage; // Default to initial royalty

        uint256[] memory thresholds = _getSortedKeys(contentItems[_contentId].dynamicRoyaltyCurve);

        for (uint256 i = 0; i < thresholds.length; i++) {
            if (salesCount >= thresholds[i]) {
                currentRoyaltyPercentage = contentItems[_contentId].dynamicRoyaltyCurve[thresholds[i]];
            } else {
                break; // Stop once sales count is below the threshold
            }
        }
        return currentRoyaltyPercentage;
    }

    /// @dev Helper function to get sorted keys from a uint256 to uint256 mapping.
    function _getSortedKeys(mapping(uint256 => uint256) storage _map) internal view returns (uint256[] memory) {
        uint256[] memory keys = new uint256[](0);
        for (uint256 key in _map) {
            keys = _arrayPush(keys, key);
        }
        // Simple bubble sort for small arrays (for dynamic royalty thresholds, should be manageable size)
        for (uint256 i = 0; i < keys.length - 1; i++) {
            for (uint256 j = 0; j < keys.length - i - 1; j++) {
                if (keys[j] > keys[j + 1]) {
                    uint256 temp = keys[j];
                    keys[j] = keys[j + 1];
                    keys[j + 1] = temp;
                }
            }
        }
        return keys;
    }

    /// @dev Helper function to push to a dynamic array (Solidity limitations).
    function _arrayPush(uint256[] memory _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    /// @notice Allows creators to withdraw their accumulated royalty earnings.
    function withdrawCreatorEarnings() external whenNotPaused {
        uint256 earnings = creatorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        creatorEarnings[msg.sender] = 0; // Reset earnings to 0 before transfer to prevent re-entrancy issues (though less critical here)
        payable(msg.sender).transfer(earnings);
    }

    /// @notice Retrieves the current earnings balance of a creator.
    /// @param _creator Address of the creator.
    /// @return Creator's earnings balance.
    function getCreatorEarnings(address _creator) external view returns (uint256) {
        return creatorEarnings[_creator];
    }


    // -------- 3. Collaborative Curation & Moderation --------

    /// @notice Allows users to report content for moderation.
    /// @param _contentId ID of the content being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _contentId, string memory _reportReason) external whenNotPaused {
        require(_contentId > 0 && _contentId <= contentCounter, "Invalid content ID.");
        require(!contentReports[_contentId].resolved, "Content already reported and resolved.");
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");

        reportCounter++;
        contentReports[reportCounter] = ContentReport({
            id: reportCounter,
            contentId: _contentId,
            reporter: msg.sender,
            reason: _reportReason,
            upvotes: 0,
            downvotes: 0,
            resolved: false,
            approved: false
        });

        emit ContentReported(reportCounter, _contentId, msg.sender, _reportReason);

        // Increase reporter's reputation for contributing to moderation
        increaseReputation(msg.sender, 1); // Small reputation increase for reporting
    }

    /// @notice Allows moderators to vote on a content report.
    /// @param _reportId ID of the content report.
    /// @param _approve True to approve the report (flag for moderation), false to reject.
    function voteOnContentReport(uint256 _reportId, bool _approve) external onlyModerator whenNotPaused {
        require(_reportId > 0 && _reportId <= reportCounter, "Invalid report ID.");
        require(!contentReports[_reportId].resolved, "Report already resolved.");

        if (_approve) {
            contentReports[_reportId].upvotes++;
        } else {
            contentReports[_reportId].downvotes++;
        }

        emit ContentReportVoteCast(_reportId, msg.sender, _approve);

        // Check if report is resolved based on votes (simple majority for now, can be more complex)
        if (contentReports[_reportId].upvotes > contentReports[_reportId].downvotes) {
            contentReports[_reportId].resolved = true;
            contentReports[_reportId].approved = true;
            moderateContent(contentReports[_reportId].contentId); // Trigger moderation action
        } else if (contentReports[_reportId].downvotes >= contentReports[_reportId].upvotes) {
            contentReports[_reportId].resolved = true;
            contentReports[_reportId].approved = false;
            // No moderation action, report rejected
        }
    }

    /// @notice Executes moderation actions on content based on report voting results.
    /// @param _contentId ID of the content to moderate.
    function moderateContent(uint256 _contentId) internal whenNotPaused {
        require(_contentId > 0 && _contentId <= contentCounter, "Invalid content ID.");
        require(!contentItems[_contentId].isModerated, "Content already moderated.");

        if (contentReports[_getContentReportIdForContent(_contentId)].approved) { // Get report ID associated with content
            contentItems[_contentId].isHidden = true; // Hide content
            contentItems[_contentId].isModerated = true;
            emit ContentModerated(_contentId, true);

            // Decrease creator's reputation for moderated content
            decreaseReputation(contentItems[_contentId].creator, 10); // Significant reputation decrease

        } else {
             contentItems[_contentId].isModerated = true; // Mark as moderated even if not hidden (report rejected)
             emit ContentModerated(_contentId, false);
        }
    }

    /// @dev Helper function to get the latest report ID for a given content ID (assuming one active report at a time).
    function _getContentReportIdForContent(uint256 _contentId) internal view returns (uint256) {
        for (uint256 i = reportCounter; i >= 1; i--) {
            if (contentReports[i].contentId == _contentId && !contentReports[i].resolved) {
                return contentReports[i].id;
            }
        }
        return 0; // No active report found
    }


    /// @notice Allows the contract owner to add a moderator.
    /// @param _moderator Address of the moderator to add.
    function addModerator(address _moderator) external onlyOwner {
        require(!moderators[_moderator], "Address is already a moderator.");
        moderators[_moderator] = true;
        moderatorList.push(_moderator);
        emit ModeratorAdded(_moderator);
    }

    /// @notice Allows the contract owner to remove a moderator.
    /// @param _moderator Address of the moderator to remove.
    function removeModerator(address _moderator) external onlyOwner {
        require(moderators[_moderator], "Address is not a moderator.");
        moderators[_moderator] = false;

        // Remove from moderator list (inefficient for large lists, consider optimization if needed)
        for (uint256 i = 0; i < moderatorList.length; i++) {
            if (moderatorList[i] == _moderator) {
                moderatorList[i] = moderatorList[moderatorList.length - 1];
                moderatorList.pop();
                break;
            }
        }
        emit ModeratorRemoved(_moderator);
    }

    /// @notice Retrieves a list of current moderators.
    function getModeratorList() external view returns (address[] memory) {
        return moderatorList;
    }


    // -------- 4. Reputation System (Basic) --------

    /// @notice Increases a user's reputation score.
    /// @param _user Address of the user.
    /// @param _amount Amount to increase reputation by.
    function increaseReputation(address _user, uint256 _amount) internal { // Internal for controlled reputation updates
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount);
    }

    /// @notice Decreases a user's reputation score.
    /// @param _user Address of the user.
    /// @param _amount Amount to decrease reputation by.
    function decreaseReputation(address _user, uint256 _amount) internal { // Internal for controlled reputation updates
        if (userReputation[_user] >= _amount) {
            userReputation[_user] -= _amount;
        } else {
            userReputation[_user] = 0; // Prevent underflow, reputation cannot be negative
        }
        emit ReputationDecreased(_user, _amount);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user Address of the user.
    /// @return User's reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }


    // -------- 5. Advanced Features & Governance (Simplified) --------

    /// @notice Allows the contract owner to set the platform fee percentage.
    /// @param _newFeePercentage New platform fee percentage (0-100).
    function setPlatformFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageSet(_newFeePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance; // Get contract balance
        uint256 platformFees = balance - _getTotalCreatorEarnings(); // Assume remaining balance is platform fees (simplified)
        require(platformFees > 0, "No platform fees to withdraw.");
        payable(owner).transfer(platformFees);
        emit PlatformFeesWithdrawn(platformFees, owner);
    }

    /// @dev Helper function to calculate total creator earnings currently held in the contract.
    function _getTotalCreatorEarnings() internal view returns (uint256) {
        uint256 totalEarnings = 0;
        address[] memory creators = _getUniqueCreators(); // Get unique creator addresses
        for (uint256 i = 0; i < creators.length; i++) {
            totalEarnings += creatorEarnings[creators[i]];
        }
        return totalEarnings;
    }

    /// @dev Helper function to get a list of unique creators who have earnings (simplified, could be optimized).
    function _getUniqueCreators() internal view returns (address[] memory) {
        address[] memory creators = new address[](0);
        mapping(address => bool) seenCreators;

        for (uint256 i = 1; i <= contentCounter; i++) {
            address creatorAddress = contentItems[i].creator;
            if (!seenCreators[creatorAddress] && creatorEarnings[creatorAddress] > 0) { // Only add if earnings exist and not already added
                creators = _arrayPushAddress(creators, creatorAddress);
                seenCreators[creatorAddress] = true;
            }
        }
        return creators;
    }

    /// @dev Helper function to push to a dynamic array of addresses (Solidity limitations).
    function _arrayPushAddress(address[] memory _array, address _value) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    /// @notice Allows the contract owner to pause core functionalities.
    function pauseContract() external onlyOwner {
        require(!paused, "Contract is already paused.");
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows the contract owner to unpause core functionalities.
    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused.");
        paused = false;
        emit ContractUnpaused();
    }

    // -------- Fallback Function (Optional - for receiving ETH) --------
    receive() external payable {}
}
```