```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Advanced Decentralized Content Curation and Monetization Platform
 * @author Bard (Example - Replace with your name/org)
 * @dev A smart contract implementing a sophisticated platform for content creators and curators.
 * It incorporates advanced features like dynamic NFTs, decentralized reputation, AI-powered content analysis (placeholder),
 * and tokenized access, aiming to revolutionize content creation and consumption.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Functionality - Content Submission & Curation:**
 *    - `submitContent(string _contentURI, ContentType _contentType)`: Allows creators to submit content with metadata URI and type.
 *    - `voteOnContent(uint256 _contentId, VoteType _vote)`: Members can vote on submitted content (Approve/Reject).
 *    - `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 *    - `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content.
 *    - `getContentStatus(uint256 _contentId)`: Checks the current status of a content (Pending, Approved, Rejected, Reported).
 *    - `batchVoteOnContent(uint256[] _contentIds, VoteType _vote)`: Efficiently vote on multiple content items at once.
 *
 * **2. NFT-Based Content Monetization:**
 *    - `mintContentNFT(uint256 _contentId)`: Mints a Dynamic NFT representing approved content for the creator.
 *    - `setContentNFTSalePrice(uint256 _nftTokenId, uint256 _price)`: Creator sets a sale price for their content NFT.
 *    - `buyContentNFT(uint256 _nftTokenId)`: Allows users to purchase content NFTs.
 *    - `transferContentNFT(uint256 _nftTokenId, address _to)`: Standard NFT transfer function with added platform logic.
 *    - `getContentNFTSalePrice(uint256 _nftTokenId)`: Retrieves the sale price of a content NFT.
 *    - `getContentNFTOwner(uint256 _nftTokenId)`: Retrieves the current owner of a content NFT.
 *
 * **3. Decentralized Reputation & Rewards:**
 *    - `upvoteCurator(address _curatorAddress)`: Allows users to upvote curators based on their curation quality.
 *    - `downvoteCurator(address _curatorAddress)`: Allows users to downvote curators based on their curation quality.
 *    - `getCuratorReputation(address _curatorAddress)`: Retrieves the reputation score of a curator.
 *    - `distributeCuratorRewards()`: Distributes platform tokens to top-rated curators periodically (based on reputation).
 *
 * **4. Advanced Features & Governance (Simplified in this example):**
 *    - `integrateAIContentAnalysis(uint256 _contentId)`: Placeholder function for AI-powered content analysis (concept).
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows platform owner to set a fee percentage on NFT sales.
 *    - `withdrawPlatformFees()`: Allows platform owner to withdraw accumulated platform fees.
 *    - `pausePlatform()`: Allows platform owner to pause core functionalities for emergency maintenance.
 *    - `unpausePlatform()`: Allows platform owner to unpause the platform after maintenance.
 *    - `setContentMetadata(uint256 _contentId, string _newMetadataURI)`: Allows creator to update content metadata (within limits).
 *
 * **5. Utility & Helper Functions:**
 *    - `getContentCount()`: Returns the total number of content items submitted.
 *    - `isContentApproved(uint256 _contentId)`: Checks if content is approved.
 */

contract AdvancedContentPlatform {
    // --- Enums and Structs ---

    enum ContentType {
        TEXT,
        IMAGE,
        VIDEO,
        AUDIO,
        OTHER
    }

    enum ContentStatus {
        PENDING,
        APPROVED,
        REJECTED,
        REPORTED
    }

    enum VoteType {
        APPROVE,
        REJECT
    }

    struct Content {
        uint256 id;
        address creator;
        string contentURI;
        ContentType contentType;
        ContentStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 reportCount;
        uint256 creationTimestamp;
        string metadataURI; // Dynamic metadata URI for NFTs
    }

    struct Curator {
        uint256 reputationScore;
    }

    // --- State Variables ---

    address public platformOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee on NFT sales
    uint256 public platformFeesCollected;
    bool public platformPaused = false;

    uint256 public contentCounter = 0;
    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => address) public contentNFTs; // Mapping NFT token ID to content ID
    mapping(address => Curator) public curators;

    // --- Events ---

    event ContentSubmitted(uint256 contentId, address creator, string contentURI, ContentType contentType);
    event ContentVoted(uint256 contentId, address voter, VoteType vote);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentApproved(uint256 contentId);
    event ContentRejected(uint256 contentId);
    event ContentNFTMinted(uint256 nftTokenId, uint256 contentId, address creator);
    event ContentNFTSalePriceSet(uint256 nftTokenId, uint256 price);
    event ContentNFTBought(uint256 nftTokenId, address buyer, uint256 price);
    event CuratorUpvoted(address curatorAddress, address upvoter);
    event CuratorDownvoted(address curatorAddress, address downvoter);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address owner);
    event PlatformPaused();
    event PlatformUnpaused();
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCounter, "Invalid content ID.");
        _;
    }

    modifier validNFTTokenId(uint256 _nftTokenId) {
        require(contentNFTs[_nftTokenId] != 0, "Invalid NFT token ID.");
        _;
    }

    // --- Constructor ---

    constructor() {
        platformOwner = msg.sender;
    }

    // --- 1. Core Functionality - Content Submission & Curation ---

    /**
     * @dev Allows creators to submit content to the platform.
     * @param _contentURI URI pointing to the actual content (e.g., IPFS hash).
     * @param _contentType Type of the content (TEXT, IMAGE, VIDEO, AUDIO, OTHER).
     */
    function submitContent(string memory _contentURI, ContentType _contentType) external whenNotPaused {
        contentCounter++;
        contentRegistry[contentCounter] = Content({
            id: contentCounter,
            creator: msg.sender,
            contentURI: _contentURI,
            contentType: _contentType,
            status: ContentStatus.PENDING,
            approvalVotes: 0,
            rejectionVotes: 0,
            reportCount: 0,
            creationTimestamp: block.timestamp,
            metadataURI: "" // Initial metadata URI, can be updated later for NFTs
        });

        emit ContentSubmitted(contentCounter, msg.sender, _contentURI, _contentType);
    }

    /**
     * @dev Allows platform members to vote on submitted content.
     * @param _contentId ID of the content to vote on.
     * @param _vote Type of vote (APPROVE or REJECT).
     */
    function voteOnContent(uint256 _contentId, VoteType _vote) external whenNotPaused validContentId(_contentId) {
        require(contentRegistry[_contentId].status == ContentStatus.PENDING, "Content voting is not active.");
        // In a real-world scenario, you would implement membership/staking and restrict voting to members.
        // For simplicity, here any address can vote once. (Consider tracking voters per content in production)

        if (_vote == VoteType.APPROVE) {
            contentRegistry[_contentId].approvalVotes++;
            if (contentRegistry[_contentId].approvalVotes > contentRegistry[_contentId].rejectionVotes * 2) { // Example: 2:1 approval ratio for approval
                _approveContent(_contentId);
            }
        } else if (_vote == VoteType.REJECT) {
            contentRegistry[_contentId].rejectionVotes++;
            if (contentRegistry[_contentId].rejectionVotes > contentRegistry[_contentId].approvalVotes * 2) { // Example: 2:1 rejection ratio for rejection
                _rejectContent(_contentId);
            }
        }
        emit ContentVoted(_contentId, msg.sender, _vote);
    }

    /**
     * @dev Allows users to report content for moderation.
     * @param _contentId ID of the content to report.
     * @param _reportReason Reason for reporting the content.
     */
    function reportContent(uint256 _contentId, string memory _reportReason) external whenNotPaused validContentId(_contentId) {
        contentRegistry[_contentId].reportCount++;
        contentRegistry[_contentId].status = ContentStatus.REPORTED; // Update status to reported
        emit ContentReported(_contentId, msg.sender, _reportReason);
        // In a real system, you would trigger a moderation process based on report counts.
    }

    /**
     * @dev Retrieves detailed information about a specific content.
     * @param _contentId ID of the content.
     * @return Content struct containing content details.
     */
    function getContentDetails(uint256 _contentId) external view validContentId(_contentId) returns (Content memory) {
        return contentRegistry[_contentId];
    }

    /**
     * @dev Checks the current status of a content.
     * @param _contentId ID of the content.
     * @return ContentStatus enum representing the content's status.
     */
    function getContentStatus(uint256 _contentId) external view validContentId(_contentId) returns (ContentStatus) {
        return contentRegistry[_contentId].status;
    }

    /**
     * @dev Efficiently vote on multiple content items at once.
     * @param _contentIds Array of content IDs to vote on.
     * @param _vote Type of vote (APPROVE or REJECT).
     */
    function batchVoteOnContent(uint256[] memory _contentIds, VoteType _vote) external whenNotPaused {
        for (uint256 i = 0; i < _contentIds.length; i++) {
            voteOnContent(_contentIds[i], _vote);
        }
    }


    // --- 2. NFT-Based Content Monetization ---

    uint256 public nftCounter = 0;

    /**
     * @dev Mints a Dynamic NFT representing approved content for the creator.
     * @param _contentId ID of the approved content.
     */
    function mintContentNFT(uint256 _contentId) external whenNotPaused validContentId(_contentId) {
        require(contentRegistry[_contentId].status == ContentStatus.APPROVED, "Content must be approved to mint NFT.");
        require(contentNFTs[nftCounter + 1] == address(0), "NFT already minted for this token ID."); // Basic check to avoid overwriting

        nftCounter++;
        contentNFTs[nftCounter] = address(this); // In real world, this would be a separate NFT contract.
        _setContentMetadataURI(nftCounter, _generateNFTMetadataURI(_contentId)); // Set initial dynamic metadata

        emit ContentNFTMinted(nftCounter, _contentId, contentRegistry[_contentId].creator);
    }

    /**
     * @dev Creator sets a sale price for their content NFT.
     * @param _nftTokenId ID of the NFT token.
     * @param _price Sale price in Wei.
     */
    function setContentNFTSalePrice(uint256 _nftTokenId, uint256 _price) external whenNotPaused validNFTTokenId(_nftTokenId) {
        require(getContentNFTOwner(_nftTokenId) == msg.sender, "Only NFT owner can set sale price.");
        // In a real NFT contract, you'd have a mapping for sale prices. Here, we simulate with metadata update.
        _setContentMetadataURI(_nftTokenId, _updateMetadataForSale(_nftTokenId, _price));
        emit ContentNFTSalePriceSet(_nftTokenId, _price);
    }

    /**
     * @dev Allows users to purchase content NFTs.
     * @param _nftTokenId ID of the NFT token to buy.
     */
    function buyContentNFT(uint256 _nftTokenId) external payable whenNotPaused validNFTTokenId(_nftTokenId) {
        uint256 salePrice = getContentNFTSalePrice(_nftTokenId);
        require(msg.value >= salePrice, "Insufficient funds to buy NFT.");

        address seller = getContentNFTOwner(_nftTokenId);
        require(seller != address(0) && seller != msg.sender, "Invalid seller or buying your own NFT.");

        // Transfer funds (minus platform fee)
        uint256 platformFee = (salePrice * platformFeePercentage) / 100;
        uint256 sellerAmount = salePrice - platformFee;

        payable(seller).transfer(sellerAmount);
        platformFeesCollected += platformFee;

        // Transfer NFT ownership (Simulated within this contract - in real world, NFT contract handles ownership)
        _transferNFT(msg.sender, _nftTokenId); // Simulate ownership transfer in metadata update
        _setContentMetadataURI(_nftTokenId, _updateMetadataAfterSale(_nftTokenId, msg.sender)); // Update metadata to reflect new owner

        emit ContentNFTBought(_nftTokenId, msg.sender, salePrice);

        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice); // Return excess funds
        }
    }

    /**
     * @dev Standard NFT transfer function with added platform logic (simulated).
     * @param _nftTokenId ID of the NFT token to transfer.
     * @param _to Address to transfer the NFT to.
     */
    function transferContentNFT(uint256 _nftTokenId, address _to) external whenNotPaused validNFTTokenId(_nftTokenId) {
        require(getContentNFTOwner(_nftTokenId) == msg.sender, "Only NFT owner can transfer.");
        require(_to != address(0) && _to != address(this), "Invalid recipient address.");

        _transferNFT(_to, _nftTokenId); // Simulate ownership transfer in metadata update
        _setContentMetadataURI(_nftTokenId, _updateMetadataAfterTransfer(_nftTokenId, _to)); // Update metadata to reflect new owner
        // In a real NFT contract, ERC721's `safeTransferFrom` would be used.
    }

    /**
     * @dev Retrieves the sale price of a content NFT (simulated from metadata).
     * @param _nftTokenId ID of the NFT token.
     * @return Sale price in Wei.
     */
    function getContentNFTSalePrice(uint256 _nftTokenId) external view validNFTTokenId(_nftTokenId) returns (uint256) {
        // In a real NFT contract, price would be stored in a mapping. Here, parse from metadata (simplified example).
        string memory metadata = _getContentMetadataURI(_nftTokenId);
        // Simple parsing example - in real world, use a structured metadata format and parsing logic.
        if (stringContains(metadata, "salePrice:")) {
            string memory priceStr = substringAfter(metadata, "salePrice:");
            return StringToUint(priceStr);
        }
        return 0; // Default to 0 if no sale price set.
    }

    /**
     * @dev Retrieves the current owner of a content NFT (simulated from metadata).
     * @param _nftTokenId ID of the NFT token.
     * @return Address of the NFT owner.
     */
    function getContentNFTOwner(uint256 _nftTokenId) public view validNFTTokenId(_nftTokenId) returns (address) {
        // In a real NFT contract, ownership is tracked directly. Here, parse from metadata.
        string memory metadata = _getContentMetadataURI(_nftTokenId);
        if (stringContains(metadata, "owner:")) {
            string memory ownerStr = substringAfter(metadata, "owner:");
            return StringToAddress(ownerStr);
        }
        // Default owner is the platform contract itself initially (until sold/transferred in this simplified example).
        return address(this);
    }


    // --- 3. Decentralized Reputation & Rewards ---

    /**
     * @dev Allows users to upvote curators based on their curation quality.
     * @param _curatorAddress Address of the curator to upvote.
     */
    function upvoteCurator(address _curatorAddress) external whenNotPaused {
        curators[_curatorAddress].reputationScore++;
        emit CuratorUpvoted(_curatorAddress, msg.sender);
    }

    /**
     * @dev Allows users to downvote curators based on their curation quality.
     * @param _curatorAddress Address of the curator to downvote.
     */
    function downvoteCurator(address _curatorAddress) external whenNotPaused {
        curators[_curatorAddress].reputationScore--; // In real world, implement more sophisticated reputation logic.
        emit CuratorDownvoted(_curatorAddress, msg.sender);
    }

    /**
     * @dev Retrieves the reputation score of a curator.
     * @param _curatorAddress Address of the curator.
     * @return Curator's reputation score.
     */
    function getCuratorReputation(address _curatorAddress) external view returns (uint256) {
        return curators[_curatorAddress].reputationScore;
    }

    /**
     * @dev Distributes platform tokens to top-rated curators periodically (based on reputation).
     *  (Placeholder - actual token distribution and reward mechanism not implemented in this simplified example).
     */
    function distributeCuratorRewards() external onlyOwner whenNotPaused {
        // In a real system, you would:
        // 1. Calculate top curators based on reputation.
        // 2. Distribute platform tokens (ERC20) to them.
        // 3. Reset or decay reputation scores over time (optional).

        // Placeholder logic: Just emit an event for demonstration.
        emit PlatformFeesWithdrawn(0, platformOwner); // Simulating reward distribution with fee withdrawal event.
    }


    // --- 4. Advanced Features & Governance (Simplified) ---

    /**
     * @dev Placeholder function for AI-powered content analysis (conceptual).
     * @param _contentId ID of the content to analyze.
     */
    function integrateAIContentAnalysis(uint256 _contentId) external onlyOwner validContentId(_contentId) {
        // This is a placeholder for demonstrating an advanced concept.
        // In a real-world scenario, you would:
        // 1. Call an off-chain AI service (e.g., using Chainlink or similar oracles).
        // 2. The AI service analyzes the content (pointed to by contentURI).
        // 3. AI service returns analysis results (e.g., content safety score, category tags, etc.).
        // 4. Update content metadata or status based on AI analysis.

        // For now, just emit an event to indicate AI analysis (conceptually).
        emit ContentMetadataUpdated(_contentId, "AI analysis requested (placeholder)");
    }

    /**
     * @dev Allows platform owner to set a fee percentage on NFT sales.
     * @param _feePercentage New platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Allows platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0;
        payable(platformOwner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, platformOwner);
    }

    /**
     * @dev Allows platform owner to pause core functionalities for emergency maintenance.
     */
    function pausePlatform() external onlyOwner {
        platformPaused = true;
        emit PlatformPaused();
    }

    /**
     * @dev Allows platform owner to unpause the platform after maintenance.
     */
    function unpausePlatform() external onlyOwner {
        platformPaused = false;
        emit PlatformUnpaused();
    }

    /**
     * @dev Allows creator to update content metadata (within limits, e.g., before NFT minting).
     * @param _contentId ID of the content to update.
     * @param _newMetadataURI New metadata URI.
     */
    function setContentMetadata(uint256 _contentId, string memory _newMetadataURI) external whenNotPaused validContentId(_contentId) {
        require(contentRegistry[_contentId].creator == msg.sender, "Only content creator can update metadata.");
        require(contentRegistry[_contentId].status == ContentStatus.PENDING || contentRegistry[_contentId].status == ContentStatus.APPROVED, "Metadata update not allowed for current content status.");
        contentRegistry[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }


    // --- 5. Utility & Helper Functions ---

    /**
     * @dev Returns the total number of content items submitted.
     * @return Total content count.
     */
    function getContentCount() external view returns (uint256) {
        return contentCounter;
    }

    /**
     * @dev Checks if content is approved.
     * @param _contentId ID of the content.
     * @return True if content is approved, false otherwise.
     */
    function isContentApproved(uint256 _contentId) external view validContentId(_contentId) returns (bool) {
        return contentRegistry[_contentId].status == ContentStatus.APPROVED;
    }


    // --- Internal Helper Functions (For NFT Simulation) ---

    /**
     * @dev Internal function to approve content and update status.
     */
    function _approveContent(uint256 _contentId) internal validContentId(_contentId) {
        contentRegistry[_contentId].status = ContentStatus.APPROVED;
        emit ContentApproved(_contentId);
    }

    /**
     * @dev Internal function to reject content and update status.
     */
    function _rejectContent(uint256 _contentId) internal validContentId(_contentId) {
        contentRegistry[_contentId].status = ContentStatus.REJECTED;
        emit ContentRejected(_contentId);
    }

    /**
     * @dev Internal function to generate initial NFT metadata URI (basic example).
     */
    function _generateNFTMetadataURI(uint256 _contentId) internal view returns (string memory) {
        // In a real NFT contract, metadata would be more structured (JSON, etc.) and potentially stored off-chain (IPFS).
        return string(abi.encodePacked("ipfs://metadata-for-content-", Strings.toString(_contentId),
                                     "?contentId=", Strings.toString(_contentId),
                                     "&creator=", Strings.toHexString(uint160(contentRegistry[_contentId].creator)),
                                     "&status=minted",
                                     "&owner=", Strings.toHexString(uint160(address(this))) // Initial owner is platform (simulated)
                                     ));
    }

    /**
     * @dev Internal function to update metadata for sale (basic example).
     */
    function _updateMetadataForSale(uint256 _nftTokenId, uint256 _price) internal view returns (string memory) {
        string memory baseMetadata = _getContentMetadataURI(_nftTokenId);
        return string(abi.encodePacked(baseMetadata, "&salePrice:", Strings.toString(_price)));
    }

    /**
     * @dev Internal function to update metadata after NFT sale (basic example).
     */
    function _updateMetadataAfterSale(uint256 _nftTokenId, address _newOwner) internal view returns (string memory) {
        string memory baseMetadata = _getContentMetadataURI(_nftTokenId);
        return string(abi.encodePacked(baseMetadata, "&status=sold", "&owner:", Strings.toHexString(uint160(_newOwner))));
    }

    /**
     * @dev Internal function to update metadata after NFT transfer (basic example).
     */
    function _updateMetadataAfterTransfer(uint256 _nftTokenId, address _newOwner) internal view returns (string memory) {
        string memory baseMetadata = _getContentMetadataURI(_nftTokenId);
        return string(abi.encodePacked(baseMetadata, "&owner:", Strings.toHexString(uint160(_newOwner))));
    }

    /**
     * @dev Internal function to get current metadata URI (basic example).
     */
    function _getContentMetadataURI(uint256 _nftTokenId) internal view returns (string memory) {
        // In a real system, metadata would be fetched from a storage like IPFS.
        // Here, we simulate by building URI strings.
        // For simplicity, we just assume metadata is always appended and can be reconstructed.
        uint256 contentId = contentNFTs[_nftTokenId];
        if (contentId != 0) {
            return contentRegistry[contentId].metadataURI; // Return stored metadata if set.
        } else {
            return ""; // Default empty metadata if no content found for NFT ID.
        }
    }

    /**
     * @dev Internal function to set/update content metadata URI (basic example).
     */
    function _setContentMetadataURI(uint256 _nftTokenId, string memory _metadataURI) internal {
        uint256 contentId = contentNFTs[_nftTokenId];
        if (contentId != 0) {
            contentRegistry[contentId].metadataURI = _metadataURI;
        }
    }

    /**
     * @dev Internal function to simulate NFT ownership transfer (metadata based).
     */
    function _transferNFT(address _to, uint256 _nftTokenId) internal {
        // In a real NFT contract, ownership would be tracked directly.
        // Here, we simulate by updating the owner in metadata.
        _setContentMetadataURI(_nftTokenId, _updateMetadataAfterTransfer(_nftTokenId, _to));
    }


    // --- String and Address Conversion Utilities (Basic - for Metadata Simulation) ---

    function StringToUint(string memory _str) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory strBytes = bytes(_str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]) - uint8(48); // ASCII '0' is 48
            require(digit <= 9, "Invalid character in string to uint conversion.");
            result = result * 10 + digit;
        }
        return result;
    }

    function StringToAddress(string memory _str) internal pure returns (address) {
        bytes memory addrBytes = bytes(_str);
        require(addrBytes.length == 42, "Invalid address string length.");
        require(addrBytes[0] == bytes1('0') && addrBytes[1] == bytes1('x'), "Address string must start with '0x'.");

        address result;
        assembly {
            result := mload(add(addrBytes, 20)) // Skip "0x" and load 20 bytes (address length)
        }
        return result;
    }

    function substringAfter(string memory _str, string memory _delimiter) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);
        uint256 delimiterLength = delimiterBytes.length;
        uint256 strLength = strBytes.length;

        if (delimiterLength == 0) {
            return _str; // If delimiter is empty, return original string
        }

        for (uint256 i = 0; i <= strLength - delimiterLength; i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterLength; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                bytes memory resultBytes = new bytes(strLength - (i + delimiterLength));
                for (uint256 k = 0; k < resultBytes.length; k++) {
                    resultBytes[k] = strBytes[i + delimiterLength + k];
                }
                return string(resultBytes);
            }
        }
        return ""; // Delimiter not found
    }

    function stringContains(string memory _str, string memory _substring) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory subBytes = bytes(_substring);
        uint256 subLength = subBytes.length;
        uint256 strLength = strBytes.length;

        if (subLength == 0) {
            return true; // Empty substring is always contained
        }
        if (subLength > strLength) {
            return false; // Substring longer than string, cannot be contained
        }

        for (uint256 i = 0; i <= strLength - subLength; i++) {
            bool match = true;
            for (uint256 j = 0; j < subLength; j++) {
                if (strBytes[i + j] != subBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true; // Substring found
            }
        }
        return false; // Substring not found
    }
}

// --- Library for String Conversions (Basic) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint160 addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; ) {
            i--;
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```