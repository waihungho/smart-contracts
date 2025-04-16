```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform - "Content Nexus"
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev A smart contract for a decentralized content platform where content evolves based on community interaction and on-chain events.
 *
 * **Outline & Function Summary:**
 *
 * **Content Submission & Curation:**
 *   1. `submitContent(string _contentHash, string _metadataURI)`: Allows users to submit content with a content hash (e.g., IPFS CID) and metadata URI.
 *   2. `upvoteContent(uint256 _contentId)`: Allows members to upvote content.
 *   3. `downvoteContent(uint256 _contentId)`: Allows members to downvote content.
 *   4. `reportContent(uint256 _contentId, string _reportReason)`: Allows members to report content for moderation with a reason.
 *   5. `moderateContent(uint256 _contentId, bool _isApproved)`: Moderator function to approve or reject reported content.
 *   6. `getContentDetails(uint256 _contentId)`: Retrieves details of a specific content item.
 *   7. `getContentRanking(uint256 _contentId)`: Calculates and returns the current ranking score of a content item based on upvotes and downvotes.
 *   8. `getContentStatus(uint256 _contentId)`: Returns the current status of content (pending, approved, rejected).
 *
 * **Dynamic Content Evolution:**
 *   9. `evolveContentBasedOnVotes(uint256 _contentId)`: (Automated/Oracle triggered) Evolves content metadata or access based on reaching vote thresholds.
 *   10. `evolveContentBasedOnExternalEvent(uint256 _contentId, string _newEventData)`: (Oracle triggered) Evolves content based on external events passed by an oracle.
 *   11. `setContentEvolutionRules(uint256 _contentId, string _evolutionRules)`: Owner function to set complex rules for content evolution (e.g., JSON rules).
 *   12. `getContentEvolutionRules(uint256 _contentId)`: Retrieves the evolution rules set for specific content.
 *
 * **Content Access & Monetization:**
 *   13. `setContentAccessType(uint256 _contentId, AccessType _accessType, uint256 _accessFee)`: Sets the access type for content (Free, Paid, TokenGated) and access fee if applicable.
 *   14. `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to paid content.
 *   15. `grantTokenGatedAccess(uint256 _contentId, address _tokenAddress, uint256 _minTokenBalance)`: Sets token-gated access requirements.
 *   16. `checkTokenGatedAccess(uint256 _contentId, address _userAddress)`: Checks if a user has token-gated access to content.
 *   17. `withdrawContentEarnings()`: Content creators can withdraw accumulated earnings from content access fees.
 *
 * **Platform Governance & Utility:**
 *   18. `setModerator(address _moderatorAddress, bool _isModerator)`: Owner function to add or remove moderators.
 *   19. `isModerator(address _account)`: Checks if an account is a moderator.
 *   20. `setPlatformFee(uint256 _feePercentage)`: Owner function to set a platform fee percentage on content access purchases.
 *   21. `getPlatformFee()`: Retrieves the current platform fee percentage.
 *   22. `withdrawPlatformFees()`: Owner function to withdraw accumulated platform fees.
 *   23. `pausePlatform()`: Owner function to pause the platform for maintenance or emergencies.
 *   24. `unpausePlatform()`: Owner function to unpause the platform.
 */

contract ContentNexus {
    enum ContentStatus { Pending, Approved, Rejected, Live }
    enum AccessType { Free, Paid, TokenGated }

    struct ContentItem {
        address creator;
        string contentHash; // IPFS CID or similar
        string metadataURI; // URI to metadata (JSON, etc.)
        ContentStatus status;
        int256 upvotes;
        int256 downvotes;
        uint256 submissionTimestamp;
        AccessType accessType;
        uint256 accessFee; // in wei
        address tokenGatedTokenAddress;
        uint256 minTokenGatedBalance;
        string evolutionRules; // JSON string defining evolution rules
    }

    uint256 public contentCount;
    mapping(uint256 => ContentItem) public contentItems;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => string)) public contentReports; // Content ID -> User -> Report Reason
    mapping(address => bool) public moderators;
    address public owner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public platformFeesBalance;
    bool public paused;

    event ContentSubmitted(uint256 contentId, address creator, string contentHash, string metadataURI);
    event ContentUpvoted(uint256 contentId, address voter);
    event ContentDownvoted(uint256 contentId, address voter);
    event ContentReported(uint256 contentId, address reporter, string reportReason);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);
    event ContentEvolved(uint256 contentId, string evolutionDetails);
    event AccessTypeSet(uint256 contentId, AccessType accessType, uint256 accessFee);
    event AccessPurchased(uint256 contentId, address purchaser, uint256 feePaid);
    event PlatformPaused(address pauser);
    event PlatformUnpaused(address unpauser);
    event ModeratorSet(address moderator, bool isModerator);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawer);
    event ContentEarningsWithdrawn(uint256 amount, address creator);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || msg.sender == owner, "Only moderator or owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Platform is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Platform is not paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
        moderators[owner] = true; // Owner is also a moderator initially
    }

    // 1. Submit Content
    function submitContent(string memory _contentHash, string memory _metadataURI) public whenNotPaused {
        contentCount++;
        contentItems[contentCount] = ContentItem({
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            status: ContentStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            submissionTimestamp: block.timestamp,
            accessType: AccessType.Free, // Default access is free initially
            accessFee: 0,
            tokenGatedTokenAddress: address(0),
            minTokenGatedBalance: 0,
            evolutionRules: "" // No evolution rules by default
        });
        emit ContentSubmitted(contentCount, msg.sender, _contentHash, _metadataURI);
    }

    // 2. Upvote Content
    function upvoteContent(uint256 _contentId) public whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(!hasVoted[_contentId][msg.sender], "Already voted on this content.");
        hasVoted[_contentId][msg.sender] = true;
        contentItems[_contentId].upvotes++;
        emit ContentUpvoted(_contentId, msg.sender);
    }

    // 3. Downvote Content
    function downvoteContent(uint256 _contentId) public whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(!hasVoted[_contentId][msg.sender], "Already voted on this content.");
        hasVoted[_contentId][msg.sender] = true;
        contentItems[_contentId].downvotes++;
        emit ContentDownvoted(_contentId, msg.sender);
    }

    // 4. Report Content
    function reportContent(uint256 _contentId, string memory _reportReason) public whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(contentReports[_contentId][msg.sender].length == 0, "Already reported this content."); // Only one report per user per content
        contentReports[_contentId][msg.sender] = _reportReason;
        contentItems[_contentId].status = ContentStatus.Pending; // Revert to pending status for moderation
        emit ContentReported(_contentId, msg.sender, _reportReason);
    }

    // 5. Moderate Content
    function moderateContent(uint256 _contentId, bool _isApproved) public onlyModerator whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        contentItems[_contentId].status = _isApproved ? ContentStatus.Approved : ContentStatus.Rejected;
        emit ContentModerated(_contentId, _isApproved, msg.sender);
    }

    // 6. Get Content Details
    function getContentDetails(uint256 _contentId) public view returns (ContentItem memory) {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        return contentItems[_contentId];
    }

    // 7. Get Content Ranking
    function getContentRanking(uint256 _contentId) public view returns (int256) {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        return contentItems[_contentId].upvotes - contentItems[_contentId].downvotes;
    }

    // 8. Get Content Status
    function getContentStatus(uint256 _contentId) public view returns (ContentStatus) {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        return contentItems[_contentId].status;
    }

    // 9. Evolve Content Based on Votes (Example - Can be expanded with oracles)
    function evolveContentBasedOnVotes(uint256 _contentId) public whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(contentItems[_contentId].status == ContentStatus.Approved || contentItems[_contentId].status == ContentStatus.Live, "Content not approved or live.");

        string memory evolutionRules = contentItems[_contentId].evolutionRules;
        if (bytes(evolutionRules).length > 0) {
            // **[Advanced Concept]** Here you would parse the JSON evolutionRules and implement logic.
            // Example JSON rules might be:
            // {
            //   "triggers": [
            //     {"type": "upvotes_threshold", "threshold": 100, "action": "update_metadata", "metadata": "new_metadata_uri_for_100_upvotes"},
            //     {"type": "downvotes_threshold", "threshold": 50, "action": "restrict_access", "new_access_type": "TokenGated", "token_address": "0x...", "min_balance": 1}
            //   ]
            // }

            // **[Simplified Example - just making content 'Live' after 50 upvotes]**
            if (contentItems[_contentId].status == ContentStatus.Approved && contentItems[_contentId].upvotes >= 50) {
                contentItems[_contentId].status = ContentStatus.Live;
                emit ContentEvolved(_contentId, "Status changed to Live due to upvote threshold.");
            }

            // **[Further Advanced Concepts - Oracle Integration]**
            //  For more complex evolution based on real-world data, you would integrate with an oracle.
            //  The oracle would call a function like `evolveContentBasedOnExternalEvent`.
        }
    }

    // 10. Evolve Content Based on External Event (Oracle Triggered)
    function evolveContentBasedOnExternalEvent(uint256 _contentId, string memory _newEventData) public whenNotPaused {
        // **[Security Note]** In a real application, you would need to strongly authenticate the oracle calling this function.
        //  For example, using Chainlink's functions or similar secure oracle solutions.
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(contentItems[_contentId].status == ContentStatus.Approved || contentItems[_contentId].status == ContentStatus.Live, "Content not approved or live.");

        // **[Advanced Concept]** Process _newEventData (e.g., JSON from oracle) and trigger content evolution.
        // Example: If _newEventData indicates "weather_event:rainy", and evolution rules specify action on "rainy" weather, then apply the action.
        emit ContentEvolved(_contentId, string.concat("Evolved based on external event: ", _newEventData));
    }

    // 11. Set Content Evolution Rules
    function setContentEvolutionRules(uint256 _contentId, string memory _evolutionRules) public onlyOwner {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        contentItems[_contentId].evolutionRules = _evolutionRules;
    }

    // 12. Get Content Evolution Rules
    function getContentEvolutionRules(uint256 _contentId) public view returns (string memory) {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        return contentItems[_contentId].evolutionRules;
    }

    // 13. Set Content Access Type
    function setContentAccessType(uint256 _contentId, AccessType _accessType, uint256 _accessFee) public onlyOwner {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        contentItems[_contentId].accessType = _accessType;
        contentItems[_contentId].accessFee = _accessFee;
        emit AccessTypeSet(_contentId, _accessType, _accessFee);
    }

    // 14. Purchase Content Access
    function purchaseContentAccess(uint256 _contentId) public payable whenNotPaused {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(contentItems[_contentId].accessType == AccessType.Paid, "Content is not paid access.");
        require(msg.value >= contentItems[_contentId].accessFee, "Insufficient payment.");

        uint256 platformFee = (contentItems[_contentId].accessFee * platformFeePercentage) / 100;
        uint256 creatorEarnings = contentItems[_contentId].accessFee - platformFee;

        platformFeesBalance += platformFee;
        payable(contentItems[_contentId].creator).transfer(creatorEarnings); // Send earnings to creator
        emit AccessPurchased(_contentId, msg.sender, contentItems[_contentId].accessFee);

        // Refund any excess payment
        if (msg.value > contentItems[_contentId].accessFee) {
            payable(msg.sender).transfer(msg.value - contentItems[_contentId].accessFee);
        }
    }

    // 15. Grant Token Gated Access
    function grantTokenGatedAccess(uint256 _contentId, address _tokenAddress, uint256 _minTokenBalance) public onlyOwner {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        contentItems[_contentId].accessType = AccessType.TokenGated;
        contentItems[_contentId].tokenGatedTokenAddress = _tokenAddress;
        contentItems[_contentId].minTokenGatedBalance = _minTokenBalance;
        emit AccessTypeSet(_contentId, AccessType.TokenGated, 0); // Access fee is 0 for token-gated
    }

    // 16. Check Token Gated Access
    function checkTokenGatedAccess(uint256 _contentId, address _userAddress) public view returns (bool) {
        require(contentItems[_contentId].creator != address(0), "Content not found.");
        require(contentItems[_contentId].accessType == AccessType.TokenGated, "Content is not token-gated.");
        // **[Important Security Note]** In a real application, you should use a secure token interface (e.g., IERC20)
        // and handle potential reentrancy issues when interacting with external token contracts.
        // For simplicity, this example assumes a basic interface.
        interface IBasicToken {
            function balanceOf(address account) external view returns (uint256);
        }
        IBasicToken token = IBasicToken(contentItems[_contentId].tokenGatedTokenAddress);
        return token.balanceOf(_userAddress) >= contentItems[_contentId].minTokenGatedBalance;
    }

    // 17. Withdraw Content Earnings
    function withdrawContentEarnings() public whenNotPaused {
        uint256 totalEarnings = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentItems[i].creator == msg.sender) {
                // In a real application, you would track creator earnings more precisely.
                // This is a simplified example where earnings are directly transferred in `purchaseContentAccess`.
                // For demonstration, let's assume creators can withdraw platform fees collected on their content (incorrect example for simplicity).
                // **[Correct Implementation Note]**  A better implementation would track earnings per content and per creator.
                //  Then `purchaseContentAccess` would update these balances, and `withdrawContentEarnings` would transfer from those balances.
            }
        }
        // **[Incorrect Example - for demonstration purposes only - do not use in production]**
        //  This example incorrectly tries to withdraw platform fees, not content creator earnings.
        //  For a correct implementation, track creator earnings separately.
        uint256 withdrawableAmount = 0; // Replace with actual creator earnings tracking
        if (withdrawableAmount > 0) { // Replace with actual condition based on tracked earnings
            // payable(msg.sender).transfer(withdrawableAmount); //  Transfer actual tracked earnings
            // emit ContentEarningsWithdrawn(withdrawableAmount, msg.sender);
            revert("Withdrawal of content earnings not fully implemented in this simplified example. Track earnings per content and creator for correct withdrawal.");
        } else {
            revert("No earnings to withdraw in this simplified example's withdrawal logic.");
        }
    }


    // 18. Set Moderator
    function setModerator(address _moderatorAddress, bool _isModerator) public onlyOwner {
        moderators[_moderatorAddress] = _isModerator;
        emit ModeratorSet(_moderatorAddress, _isModerator);
    }

    // 19. Is Moderator
    function isModerator(address _account) public view returns (bool) {
        return moderators[_account];
    }

    // 20. Set Platform Fee
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    // 21. Get Platform Fee
    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    // 22. Withdraw Platform Fees
    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = platformFeesBalance;
        platformFeesBalance = 0;
        payable(owner).transfer(amount);
        emit PlatformFeesWithdrawn(amount, owner);
    }

    // 23. Pause Platform
    function pausePlatform() public onlyOwner whenNotPaused {
        paused = true;
        emit PlatformPaused(owner);
    }

    // 24. Unpause Platform
    function unpausePlatform() public onlyOwner whenPaused {
        paused = false;
        emit PlatformUnpaused(owner);
    }

    // Fallback function to receive Ether (for platform fees and content purchases)
    receive() external payable {}
}
```