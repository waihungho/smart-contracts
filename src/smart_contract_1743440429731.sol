```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Content Curation & Monetization Platform (DACCPM)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where content creators can submit their work,
 *      the community can curate and vote on it, and creators can monetize their approved content.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Content Management:**
 *    - `submitContent(string memory _title, string memory _contentURI, ContentType _contentType)`: Allows content creators to submit their content (e.g., articles, music, videos) with metadata URI and type.
 *    - `getContentDetails(uint256 _contentId)`: Retrieves details of a specific content item, including submitter, status, votes, and metadata.
 *    - `getAllContentIds()`: Returns a list of all content IDs submitted to the platform.
 *    - `getContentIdsByStatus(ContentStatus _status)`: Returns a list of content IDs filtered by a specific status (e.g., pending, approved, rejected).
 *    - `setContentMetadata(uint256 _contentId, string memory _newContentURI)`: Allows the content creator to update the metadata URI of their submitted content (before approval).
 *    - `getContentCreator(uint256 _contentId)`: Retrieves the address of the content creator for a given content ID.
 *
 * **2. Decentralized Curation & Voting:**
 *    - `voteForContent(uint256 _contentId, VoteType _vote)`: Allows community members to vote on submitted content (Approve or Reject).
 *    - `getContentVoteCounts(uint256 _contentId)`: Retrieves the current approval and rejection vote counts for a specific content item.
 *    - `hasVoted(uint256 _contentId, address _voter)`: Checks if a specific address has already voted on a particular content item.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Allows the contract owner to set or update the voting duration for content submissions (in blocks).
 *    - `getVotingDuration()`: Retrieves the currently set voting duration in blocks.
 *    - `setContentStatus(uint256 _contentId, ContentStatus _newStatus)`: Owner-only function to manually set the status of content (primarily for edge cases or manual moderation after voting).
 *
 * **3. Monetization & Revenue Sharing:**
 *    - `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to approved content, supporting creators and the platform.
 *    - `setContentPrice(uint256 _contentId, uint256 _price)`: Allows content creators to set the access price for their approved content (only after approval).
 *    - `getContentPrice(uint256 _contentId)`: Retrieves the access price for a specific content item.
 *    - `withdrawCreatorEarnings(uint256 _contentId)`: Allows content creators to withdraw their accumulated earnings from content access sales.
 *    - `getCreatorBalance(uint256 _contentId)`: Retrieves the current balance of earnings for a content creator related to a specific content ID.
 *    - `setPlatformFeePercentage(uint256 _percentage)`: Owner-only function to set the platform's fee percentage on content access purchases.
 *    - `getPlatformFeePercentage()`: Retrieves the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Owner-only function to withdraw accumulated platform fees.
 *    - `getPlatformBalance()`: Retrieves the current balance of platform fees.
 *
 * **4. Platform Governance & Utility (Potential extensions - not fully implemented in core logic for brevity, but outlined):**
 *    - `proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata)`: (Future extension for DAO governance) - Allow community to propose changes to platform parameters.
 *    - `voteOnGovernanceProposal(uint256 _proposalId, VoteType _vote)`: (Future extension for DAO governance) - Allow community to vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: (Future extension for DAO governance) - Execute approved governance proposals.
 *    - `setCuratorRole(address _curatorAddress, bool _isCurator)`: (Future extension for more advanced moderation roles) - Owner-only function to assign/revoke curator roles.
 *
 * **Advanced Concepts & Creativity:**
 *    - **Decentralized Curation:** Leverages community voting for content approval, moving away from centralized moderation.
 *    - **Dynamic Content Pricing:** Creators can set their own prices post-approval, enabling flexible monetization models.
 *    - **Platform Fee & Revenue Sharing:**  Balances creator rewards with platform sustainability through a configurable fee structure.
 *    - **Potential for DAO Governance:**  Outline includes functions for future expansion into decentralized governance, allowing the community to shape the platform's evolution.
 *    - **Content Type Flexibility:** Supports various content types (articles, music, videos, etc.) through a flexible `ContentType` enum and metadata URI.
 *    - **On-Chain Voting and Status Tracking:** All curation and content status are transparently recorded on the blockchain.
 */

contract DecentralizedArtCollective {

    // -------- Enums & Structs --------

    enum ContentStatus { Pending, Approved, Rejected }
    enum ContentType { Article, Music, Video, Image, Other }
    enum VoteType { Approve, Reject }

    struct ContentItem {
        address creator;
        string title;
        string contentURI;
        ContentType contentType;
        ContentStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 price; // Access price for approved content
        uint256 creatorBalance; // Accumulated earnings for the creator
        uint256 votingEndTime;
    }

    // -------- State Variables --------

    mapping(uint256 => ContentItem) public contentItems; // Content ID => Content Details
    uint256 public nextContentId = 1;
    uint256 public votingDurationInBlocks = 100; // Default voting duration in blocks
    uint256 public platformFeePercentage = 10; // Default platform fee percentage (10%)
    address public owner;
    mapping(uint256 => mapping(address => VoteType)) public contentVotes; // Content ID => Voter Address => Vote Type
    uint256 public platformBalance; // Accumulated platform fees

    // -------- Events --------

    event ContentSubmitted(uint256 contentId, address creator, string title, ContentType contentType);
    event ContentVoted(uint256 contentId, address voter, VoteType vote);
    event ContentStatusUpdated(uint256 contentId, ContentStatus newStatus);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentAccessPurchased(uint256 contentId, address buyer, uint256 price);
    event CreatorEarningsWithdrawn(uint256 contentId, address creator, uint256 amount);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event VotingDurationUpdated(uint256 newDuration);
    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event ContentMetadataUpdated(uint256 contentId, string newContentURI);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contentItems[_contentId].creator != address(0), "Content does not exist.");
        _;
    }

    modifier validContentStatus(uint256 _contentId, ContentStatus _status) {
        require(contentItems[_contentId].status == _status, "Content status is not valid for this action.");
        _;
    }

    modifier isContentCreator(uint256 _contentId) {
        require(contentItems[_contentId].creator == msg.sender, "You are not the content creator.");
        _;
    }

    modifier votingNotEnded(uint256 _contentId) {
        require(block.number <= contentItems[_contentId].votingEndTime, "Voting period has ended.");
        _;
    }

    modifier notVotedYet(uint256 _contentId) {
        require(contentVotes[_contentId][msg.sender] == VoteType(0), "You have already voted on this content.");
        _;
    }

    modifier contentApproved(uint256 _contentId) {
        require(contentItems[_contentId].status == ContentStatus.Approved, "Content is not approved yet.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
    }

    // -------- 1. Core Content Management Functions --------

    function submitContent(string memory _title, string memory _contentURI, ContentType _contentType) public {
        uint256 contentId = nextContentId++;
        contentItems[contentId] = ContentItem({
            creator: msg.sender,
            title: _title,
            contentURI: _contentURI,
            contentType: _contentType,
            status: ContentStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            price: 0, // Default price is 0, creator can set later if approved
            creatorBalance: 0,
            votingEndTime: block.number + votingDurationInBlocks
        });
        emit ContentSubmitted(contentId, msg.sender, _title, _contentType);
    }

    function getContentDetails(uint256 _contentId) public view contentExists(_contentId) returns (ContentItem memory) {
        return contentItems[_contentId];
    }

    function getAllContentIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](nextContentId - 1);
        uint256 index = 0;
        for (uint256 i = 1; i < nextContentId; i++) {
            if (contentItems[i].creator != address(0)) { // Check if content exists (wasn't overwritten or deleted, though deletion is not implemented here)
                ids[index++] = i;
            }
        }
        // Resize the array to the actual number of content items found (remove trailing zeros if any)
        assembly {
            mstore(ids, index) // Update the length in memory directly
        }
        return ids;
    }


    function getContentIdsByStatus(ContentStatus _status) public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](nextContentId - 1);
        uint256 index = 0;
        for (uint256 i = 1; i < nextContentId; i++) {
            if (contentItems[i].creator != address(0) && contentItems[i].status == _status) {
                ids[index++] = i;
            }
        }
        // Resize the array to the actual number of content items found
        assembly {
            mstore(ids, index)
        }
        return ids;
    }

    function setContentMetadata(uint256 _contentId, string memory _newContentURI) public contentExists(_contentId) isContentCreator(_contentId) validContentStatus(_contentId, ContentStatus.Pending) {
        contentItems[_contentId].contentURI = _newContentURI;
        emit ContentMetadataUpdated(_contentId, _newContentURI);
    }

    function getContentCreator(uint256 _contentId) public view contentExists(_contentId) returns (address) {
        return contentItems[_contentId].creator;
    }


    // -------- 2. Decentralized Curation & Voting Functions --------

    function voteForContent(uint256 _contentId, VoteType _vote) public contentExists(_contentId) votingNotEnded(_contentId) notVotedYet(_contentId) validContentStatus(_contentId, ContentStatus.Pending) {
        contentVotes[_contentId][msg.sender] = _vote;
        if (_vote == VoteType.Approve) {
            contentItems[_contentId].approvalVotes++;
        } else if (_vote == VoteType.Reject) {
            contentItems[_contentId].rejectionVotes++;
        }
        emit ContentVoted(_contentId, msg.sender, _vote);

        // Automatically update status based on simple majority (can be made more sophisticated)
        if (contentItems[_contentId].approvalVotes > contentItems[_contentId].rejectionVotes) {
            setContentStatusInternal(_contentId, ContentStatus.Approved);
        } else if (contentItems[_contentId].rejectionVotes > contentItems[_contentId].approvalVotes * 2) { // Example: More than double rejections to reject
            setContentStatusInternal(_contentId, ContentStatus.Rejected);
        }
    }

    function getContentVoteCounts(uint256 _contentId) public view contentExists(_contentId) returns (uint256 approvalVotes, uint256 rejectionVotes) {
        return (contentItems[_contentId].approvalVotes, contentItems[_contentId].rejectionVotes);
    }

    function hasVoted(uint256 _contentId, address _voter) public view contentExists(_contentId) returns (bool) {
        return contentVotes[_contentId][_voter] != VoteType(0);
    }

    function setVotingDuration(uint256 _durationInBlocks) public onlyOwner {
        votingDurationInBlocks = _durationInBlocks;
        emit VotingDurationUpdated(_durationInBlocks);
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDurationInBlocks;
    }

    function setContentStatus(uint256 _contentId, ContentStatus _newStatus) public onlyOwner contentExists(_contentId) {
        setContentStatusInternal(_contentId, _newStatus);
    }

    // Internal function to set content status and emit event (reused in voteForContent and setContentStatus)
    function setContentStatusInternal(uint256 _contentId, ContentStatus _newStatus) private {
        contentItems[_contentId].status = _newStatus;
        emit ContentStatusUpdated(_contentId, _newStatus);
    }


    // -------- 3. Monetization & Revenue Sharing Functions --------

    function purchaseContentAccess(uint256 _contentId) public payable contentExists(_contentId) contentApproved(_contentId) {
        uint256 price = contentItems[_contentId].price;
        require(msg.value >= price, "Insufficient payment for content access.");

        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 creatorShare = price - platformFee;

        contentItems[_contentId].creatorBalance += creatorShare;
        platformBalance += platformFee;

        payable(contentItems[_contentId].creator).transfer(creatorShare); // Directly transfer creator share for immediate reward (optional, can also accumulate)
        platformBalance += platformFee; // Add platform fee to platform balance

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price); // Refund excess payment
        }

        emit ContentAccessPurchased(_contentId, msg.sender, price);
    }

    function setContentPrice(uint256 _contentId, uint256 _price) public contentExists(_contentId) isContentCreator(_contentId) contentApproved(_contentId) {
        contentItems[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    function getContentPrice(uint256 _contentId) public view contentExists(_contentId) returns (uint256) {
        return contentItems[_contentId].price;
    }

    function withdrawCreatorEarnings(uint256 _contentId) public contentExists(_contentId) isContentCreator(_contentId) {
        uint256 balance = contentItems[_contentId].creatorBalance;
        require(balance > 0, "No earnings to withdraw.");
        contentItems[_contentId].creatorBalance = 0; // Reset balance to 0 after withdrawal
        payable(msg.sender).transfer(balance);
        emit CreatorEarningsWithdrawn(_contentId, msg.sender, balance);
    }

    function getCreatorBalance(uint256 _contentId) public view contentExists(_contentId) isContentCreator(_contentId) returns (uint256) {
        return contentItems[_contentId].creatorBalance;
    }

    function setPlatformFeePercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageUpdated(_percentage);
    }

    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    function withdrawPlatformFees() public onlyOwner {
        require(platformBalance > 0, "No platform fees to withdraw.");
        uint256 balance = platformBalance;
        platformBalance = 0;
        payable(owner).transfer(balance);
        emit PlatformFeesWithdrawn(owner, balance);
    }

    function getPlatformBalance() public view onlyOwner returns (uint256) { // Owner-only view for platform balance
        return platformBalance;
    }

    // -------- Fallback function to receive ETH for content purchases --------
    receive() external payable {}
}
```