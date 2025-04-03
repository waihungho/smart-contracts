```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized platform for dynamic content creation and consumption.
 *      This platform allows creators to publish evolving content, users to subscribe to content streams,
 *      and incorporates advanced concepts like content morphing, collaborative narratives, and dynamic NFTs.
 *
 * ## Outline and Function Summary:
 *
 * **1. Content Creation and Management:**
 *     - `createContentStream(string _initialContentURI, string _contentType, uint256 _subscriptionFee, uint255 _morphingDuration)`: Allows creators to initiate a new content stream.
 *     - `updateContentURI(uint256 _streamId, string _newContentURI)`: Allows creators to update the content URI for a stream, triggering content morphing.
 *     - `setContentMorphingDuration(uint256 _streamId, uint255 _newDuration)`: Adjusts the morphing duration for a content stream.
 *     - `getContentStreamDetails(uint256 _streamId)`: Retrieves details of a specific content stream (creator, URI, type, fee, morphing duration, subscriber count).
 *     - `getContentStreamsByCreator(address _creator)`: Returns a list of stream IDs owned by a creator.
 *     - `getContentStreamCount()`: Returns the total number of content streams.
 *
 * **2. Subscription and Access Control:**
 *     - `subscribeToStream(uint256 _streamId)`: Allows users to subscribe to a content stream by paying the subscription fee.
 *     - `unsubscribeFromStream(uint256 _streamId)`: Allows users to unsubscribe from a content stream.
 *     - `isSubscriber(uint256 _streamId, address _user)`: Checks if a user is subscribed to a content stream.
 *     - `getSubscribersCount(uint256 _streamId)`: Returns the number of subscribers for a content stream.
 *     - `getSubscribedStreamsByUser(address _user)`: Returns a list of stream IDs a user is subscribed to.
 *
 * **3. Content Morphing and Evolution:**
 *     - `getLastContentMorphTimestamp(uint256 _streamId)`: Returns the timestamp of the last content morph for a stream.
 *     - `getContentMorphingDuration(uint256 _streamId)`: Returns the morphing duration for a stream.
 *     - `isContentMorphing(uint256 _streamId)`: Checks if a content stream is currently in a morphing state.
 *
 * **4. Collaborative Narrative (Voting and Content Influence):**
 *     - `proposeNarrativeBranch(uint256 _streamId, string _branchDescription, string _proposedContentURI)`: Subscribers can propose narrative branches for content evolution.
 *     - `voteForNarrativeBranch(uint256 _streamId, uint256 _branchId)`: Subscribers can vote for proposed narrative branches.
 *     - `getNarrativeBranchDetails(uint256 _streamId, uint256 _branchId)`: Retrieves details of a narrative branch proposal.
 *     - `executeNarrativeBranch(uint256 _streamId, uint256 _branchId)`: Creator can execute a winning narrative branch, updating the content URI.
 *     - `getWinningNarrativeBranch(uint256 _streamId)`: Returns the ID of the winning narrative branch (if voting is concluded).
 *
 * **5. Dynamic NFT Integration (Optional - Could be extended with NFT contract interaction):**
 *     - `mintDynamicNFT(uint256 _streamId)`: (Placeholder - Concept for minting dynamic NFTs representing stream subscriptions, evolving with content).
 *
 * **6. Platform Utility and Governance (Simple - Can be expanded):**
 *     - `setPlatformFeePercentage(uint256 _percentage)`: Platform owner can set a fee percentage on subscriptions.
 *     - `withdrawPlatformFees()`: Platform owner can withdraw accumulated platform fees.
 *     - `getPlatformFeePercentage()`: Returns the current platform fee percentage.
 *
 * **7. Emergency and Admin Functions:**
 *     - `pauseContract()`: Allows platform owner to pause core functionalities in case of emergency.
 *     - `unpauseContract()`: Allows platform owner to resume contract functionalities.
 *     - `isContractPaused()`: Checks if the contract is currently paused.
 */
contract DecentralizedDynamicContentPlatform {

    // --- Structs and Enums ---

    struct ContentStream {
        address creator;
        string currentContentURI;
        string contentType;
        uint256 subscriptionFee;
        uint256 morphingDuration; // Duration of content morphing in seconds
        uint256 lastMorphTimestamp;
        uint256 subscriberCount;
        bool exists;
    }

    struct NarrativeBranchProposal {
        address proposer;
        string description;
        string proposedContentURI;
        uint256 voteCount;
        bool executed;
        bool exists;
    }

    enum ContentStreamState {
        ACTIVE,
        MORPHING,
        PAUSED
    }

    // --- State Variables ---

    mapping(uint256 => ContentStream) public contentStreams; // Stream ID => ContentStream details
    mapping(uint256 => mapping(uint256 => NarrativeBranchProposal)) public narrativeBranches; // Stream ID => Branch ID => NarrativeBranchProposal details
    mapping(uint256 => mapping(address => bool)) public subscribers; // Stream ID => User Address => Is Subscriber
    mapping(address => uint256[]) public creatorStreams; // Creator Address => Array of Stream IDs they created
    mapping(address => uint256[]) public userSubscriptions; // User Address => Array of Stream IDs they are subscribed to

    uint256 public nextStreamId = 1;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    address public platformOwner;
    bool public contractPaused = false;

    // --- Events ---

    event ContentStreamCreated(uint256 streamId, address creator, string initialContentURI, string contentType, uint256 subscriptionFee, uint256 morphingDuration);
    event ContentURIUpdated(uint256 streamId, string newContentURI, uint256 timestamp);
    event SubscriptionStarted(uint256 streamId, address subscriber);
    event SubscriptionEnded(uint256 streamId, address subscriber);
    event NarrativeBranchProposed(uint256 streamId, uint256 branchId, address proposer, string description, string proposedContentURI);
    event NarrativeBranchVoted(uint256 streamId, uint256 branchId, address voter);
    event NarrativeBranchExecuted(uint256 streamId, uint256 branchId, string newContentURI);
    event PlatformFeePercentageSet(uint256 percentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier streamExists(uint256 _streamId) {
        require(contentStreams[_streamId].exists, "Content stream does not exist.");
        _;
    }

    modifier narrativeBranchExists(uint256 _streamId, uint256 _branchId) {
        require(narrativeBranches[_streamId][_branchId].exists, "Narrative branch does not exist.");
        _;
    }

    modifier onlyStreamCreator(uint256 _streamId) {
        require(contentStreams[_streamId].creator == msg.sender, "Only stream creator can call this function.");
        _;
    }

    modifier onlySubscriber(uint256 _streamId) {
        require(subscribers[_streamId][msg.sender], "You are not subscribed to this stream.");
        _;
    }

    modifier notSubscriber(uint256 _streamId) {
        require(!subscribers[_streamId][msg.sender], "You are already subscribed to this stream.");
        _;
    }

    modifier contractNotPaused() {
        require(!contractPaused, "Contract is currently paused.");
        _;
    }


    // --- Constructor ---

    constructor() {
        platformOwner = msg.sender;
    }

    // --- 1. Content Creation and Management ---

    /// @notice Allows creators to initiate a new content stream.
    /// @param _initialContentURI URI pointing to the initial content.
    /// @param _contentType Type of content (e.g., "image", "text", "audio", "video").
    /// @param _subscriptionFee Fee to subscribe to the stream in wei.
    /// @param _morphingDuration Duration in seconds for content to morph smoothly after URI update.
    function createContentStream(
        string memory _initialContentURI,
        string memory _contentType,
        uint256 _subscriptionFee,
        uint256 _morphingDuration
    ) external contractNotPaused {
        require(bytes(_initialContentURI).length > 0, "Initial content URI cannot be empty.");
        require(bytes(_contentType).length > 0, "Content type cannot be empty.");

        uint256 streamId = nextStreamId++;
        contentStreams[streamId] = ContentStream({
            creator: msg.sender,
            currentContentURI: _initialContentURI,
            contentType: _contentType,
            subscriptionFee: _subscriptionFee,
            morphingDuration: _morphingDuration,
            lastMorphTimestamp: block.timestamp,
            subscriberCount: 0,
            exists: true
        });
        creatorStreams[msg.sender].push(streamId);

        emit ContentStreamCreated(streamId, msg.sender, _initialContentURI, _contentType, _subscriptionFee, _morphingDuration);
    }

    /// @notice Allows creators to update the content URI for a stream, triggering content morphing.
    /// @param _streamId ID of the content stream.
    /// @param _newContentURI New URI pointing to the updated content.
    function updateContentURI(uint256 _streamId, string memory _newContentURI) external streamExists(_streamId) onlyStreamCreator(_streamId) contractNotPaused {
        require(bytes(_newContentURI).length > 0, "New content URI cannot be empty.");
        contentStreams[_streamId].currentContentURI = _newContentURI;
        contentStreams[_streamId].lastMorphTimestamp = block.timestamp;
        emit ContentURIUpdated(_streamId, _newContentURI, block.timestamp);
    }

    /// @notice Adjusts the morphing duration for a content stream.
    /// @param _streamId ID of the content stream.
    /// @param _newDuration New morphing duration in seconds.
    function setContentMorphingDuration(uint256 _streamId, uint256 _newDuration) external streamExists(_streamId) onlyStreamCreator(_streamId) contractNotPaused {
        contentStreams[_streamId].morphingDuration = _newDuration;
    }

    /// @notice Retrieves details of a specific content stream.
    /// @param _streamId ID of the content stream.
    /// @return creator, currentContentURI, contentType, subscriptionFee, morphingDuration, lastMorphTimestamp, subscriberCount, exists
    function getContentStreamDetails(uint256 _streamId) external view streamExists(_streamId) returns (
        address creator,
        string memory currentContentURI,
        string memory contentType,
        uint256 subscriptionFee,
        uint256 morphingDuration,
        uint256 lastMorphTimestamp,
        uint256 subscriberCount,
        bool exists
    ) {
        ContentStream storage stream = contentStreams[_streamId];
        return (
            stream.creator,
            stream.currentContentURI,
            stream.contentType,
            stream.subscriptionFee,
            stream.morphingDuration,
            stream.lastMorphTimestamp,
            stream.subscriberCount,
            stream.exists
        );
    }

    /// @notice Returns a list of stream IDs owned by a creator.
    /// @param _creator Address of the creator.
    /// @return Array of stream IDs.
    function getContentStreamsByCreator(address _creator) external view returns (uint256[] memory) {
        return creatorStreams[_creator];
    }

    /// @notice Returns the total number of content streams.
    /// @return Total number of content streams.
    function getContentStreamCount() external view returns (uint256) {
        return nextStreamId - 1;
    }


    // --- 2. Subscription and Access Control ---

    /// @notice Allows users to subscribe to a content stream by paying the subscription fee.
    /// @param _streamId ID of the content stream to subscribe to.
    function subscribeToStream(uint256 _streamId) external payable streamExists(_streamId) notSubscriber(_streamId) contractNotPaused {
        require(msg.value >= contentStreams[_streamId].subscriptionFee, "Insufficient subscription fee sent.");

        subscribers[_streamId][msg.sender] = true;
        contentStreams[_streamId].subscriberCount++;
        userSubscriptions[msg.sender].push(_streamId);

        // Transfer subscription fee to creator (minus platform fee)
        uint256 platformFee = (contentStreams[_streamId].subscriptionFee * platformFeePercentage) / 100;
        uint256 creatorShare = contentStreams[_streamId].subscriptionFee - platformFee;

        payable(contentStreams[_streamId].creator).transfer(creatorShare);
        // Platform fees are accumulated in the contract and withdrawn by the platform owner.

        emit SubscriptionStarted(_streamId, msg.sender);

        // Return any excess ETH sent.
        if (msg.value > contentStreams[_streamId].subscriptionFee) {
            payable(msg.sender).transfer(msg.value - contentStreams[_streamId].subscriptionFee);
        }
    }

    /// @notice Allows users to unsubscribe from a content stream.
    /// @param _streamId ID of the content stream to unsubscribe from.
    function unsubscribeFromStream(uint256 _streamId) external streamExists(_streamId) onlySubscriber(_streamId) contractNotPaused {
        subscribers[_streamId][msg.sender] = false;
        contentStreams[_streamId].subscriberCount--;

        // Remove streamId from userSubscriptions array (inefficient in Solidity, consider alternative if scale is critical)
        uint256[] storage subscriptionsList = userSubscriptions[msg.sender];
        for (uint256 i = 0; i < subscriptionsList.length; i++) {
            if (subscriptionsList[i] == _streamId) {
                subscriptionsList[i] = subscriptionsList[subscriptionsList.length - 1];
                subscriptionsList.pop();
                break;
            }
        }

        emit SubscriptionEnded(_streamId, msg.sender);
    }

    /// @notice Checks if a user is subscribed to a content stream.
    /// @param _streamId ID of the content stream.
    /// @param _user Address of the user.
    /// @return True if subscribed, false otherwise.
    function isSubscriber(uint256 _streamId, address _user) external view streamExists(_streamId) returns (bool) {
        return subscribers[_streamId][_user];
    }

    /// @notice Returns the number of subscribers for a content stream.
    /// @param _streamId ID of the content stream.
    /// @return Number of subscribers.
    function getSubscribersCount(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        return contentStreams[_streamId].subscriberCount;
    }

    /// @notice Returns a list of stream IDs a user is subscribed to.
    /// @param _user Address of the user.
    /// @return Array of stream IDs.
    function getSubscribedStreamsByUser(address _user) external view returns (uint256[] memory) {
        return userSubscriptions[_user];
    }


    // --- 3. Content Morphing and Evolution ---

    /// @notice Returns the timestamp of the last content morph for a stream.
    /// @param _streamId ID of the content stream.
    /// @return Timestamp of last morph.
    function getLastContentMorphTimestamp(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        return contentStreams[_streamId].lastMorphTimestamp;
    }

    /// @notice Returns the morphing duration for a stream.
    /// @param _streamId ID of the content stream.
    /// @return Morphing duration in seconds.
    function getContentMorphingDuration(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        return contentStreams[_streamId].morphingDuration;
    }

    /// @notice Checks if a content stream is currently in a morphing state.
    /// @param _streamId ID of the content stream.
    /// @return True if morphing, false otherwise.
    function isContentMorphing(uint256 _streamId) external view streamExists(_streamId) returns (bool) {
        return block.timestamp <= (contentStreams[_streamId].lastMorphTimestamp + contentStreams[_streamId].morphingDuration);
    }


    // --- 4. Collaborative Narrative (Voting and Content Influence) ---

    uint256 public nextBranchId = 1; // Global branch ID counter (can be per stream for isolation)

    /// @notice Subscribers can propose narrative branches for content evolution.
    /// @param _streamId ID of the content stream.
    /// @param _branchDescription Description of the narrative branch.
    /// @param _proposedContentURI URI pointing to the proposed content for this branch.
    function proposeNarrativeBranch(uint256 _streamId, string memory _branchDescription, string memory _proposedContentURI) external streamExists(_streamId) onlySubscriber(_streamId) contractNotPaused {
        require(bytes(_branchDescription).length > 0, "Branch description cannot be empty.");
        require(bytes(_proposedContentURI).length > 0, "Proposed content URI cannot be empty.");

        uint256 branchId = nextBranchId++; // Consider stream-specific branch IDs for isolation.
        narrativeBranches[_streamId][branchId] = NarrativeBranchProposal({
            proposer: msg.sender,
            description: _branchDescription,
            proposedContentURI: _proposedContentURI,
            voteCount: 0,
            executed: false,
            exists: true
        });

        emit NarrativeBranchProposed(_streamId, branchId, msg.sender, _branchDescription, _proposedContentURI);
    }

    /// @notice Subscribers can vote for proposed narrative branches.
    /// @param _streamId ID of the content stream.
    /// @param _branchId ID of the narrative branch to vote for.
    function voteForNarrativeBranch(uint256 _streamId, uint256 _branchId) external streamExists(_streamId) narrativeBranchExists(_streamId, _branchId) onlySubscriber(_streamId) contractNotPaused {
        narrativeBranches[_streamId][_branchId].voteCount++;
        emit NarrativeBranchVoted(_streamId, _branchId, msg.sender);
    }

    /// @notice Retrieves details of a narrative branch proposal.
    /// @param _streamId ID of the content stream.
    /// @param _branchId ID of the narrative branch.
    /// @return proposer, description, proposedContentURI, voteCount, executed, exists
    function getNarrativeBranchDetails(uint256 _streamId, uint256 _branchId) external view streamExists(_streamId) narrativeBranchExists(_streamId, _branchId) returns (
        address proposer,
        string memory description,
        string memory proposedContentURI,
        uint256 voteCount,
        bool executed,
        bool exists
    ) {
        NarrativeBranchProposal storage branch = narrativeBranches[_streamId][_branchId];
        return (
            branch.proposer,
            branch.description,
            branch.proposedContentURI,
            branch.voteCount,
            branch.executed,
            branch.exists
        );
    }

    /// @notice Creator can execute a winning narrative branch, updating the content URI.
    /// @dev In a real scenario, you might have a voting period and determine winning branch based on highest votes.
    ///      This is a simplified example where creator chooses to execute any branch.
    /// @param _streamId ID of the content stream.
    /// @param _branchId ID of the narrative branch to execute.
    function executeNarrativeBranch(uint256 _streamId, uint256 _branchId) external streamExists(_streamId) narrativeBranchExists(_streamId, _branchId) onlyStreamCreator(_streamId) contractNotPaused {
        require(!narrativeBranches[_streamId][_branchId].executed, "Narrative branch already executed.");
        contentStreams[_streamId].currentContentURI = narrativeBranches[_streamId][_branchId].proposedContentURI;
        contentStreams[_streamId].lastMorphTimestamp = block.timestamp;
        narrativeBranches[_streamId][_branchId].executed = true;

        emit NarrativeBranchExecuted(_streamId, _branchId, contentStreams[_streamId].currentContentURI);
    }

    /// @notice Returns the ID of the winning narrative branch (if voting is concluded - simplified, always returns highest voted for now).
    /// @param _streamId ID of the content stream.
    /// @return Winning branch ID (or 0 if no branches or voting not concluded).
    function getWinningNarrativeBranch(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        uint256 winningBranchId = 0;
        uint256 maxVotes = 0;
        for (uint256 branchId = 1; branchId < nextBranchId; branchId++) { // Iterate all branches (inefficient, consider better approach)
            if (narrativeBranches[_streamId][branchId].exists && narrativeBranches[_streamId][branchId].voteCount > maxVotes) {
                maxVotes = narrativeBranches[_streamId][branchId].voteCount;
                winningBranchId = branchId;
            }
        }
        return winningBranchId;
    }


    // --- 5. Dynamic NFT Integration (Placeholder) ---

    /// @notice (Placeholder) Concept for minting dynamic NFTs representing stream subscriptions, evolving with content.
    /// @param _streamId ID of the content stream.
    function mintDynamicNFT(uint256 _streamId) external streamExists(_streamId) onlySubscriber(_streamId) contractNotPaused {
        // --- Placeholder Logic ---
        // In a real implementation, this would interact with an NFT contract (ERC721 or ERC1155).
        // The NFT metadata could dynamically update to reflect the current content URI or stream state.
        // ---
        // Example:
        // IERC721 nftContract = IERC721(nftContractAddress); // Assume nftContractAddress is a state variable
        // nftContract.mint(msg.sender, generateDynamicTokenMetadataURI(_streamId));
        // ---
        // For simplicity, this example just emits an event.
        emit SubscriptionStarted(_streamId, msg.sender); // Reusing event for now as placeholder.
        // In real implementation, emit a specific NFT Minted event.
    }


    // --- 6. Platform Utility and Governance ---

    /// @notice Platform owner can set a fee percentage on subscriptions.
    /// @param _percentage New platform fee percentage (0-100).
    function setPlatformFeePercentage(uint256 _percentage) external onlyPlatformOwner contractNotPaused {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    /// @notice Platform owner can withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyPlatformOwner contractNotPaused {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = 0;
        for (uint256 streamId = 1; streamId < nextStreamId; streamId++) {
            if (contentStreams[streamId].exists) {
                withdrawableAmount += (contentStreams[streamId].subscriptionFee * platformFeePercentage) / 100 * contentStreams[streamId].subscriberCount; //Rough estimation, needs refinement for accurate fee tracking
            }
        }

        // In a real system, you'd need to track platform fees more accurately per subscription.
        // This is a simplified approximation.
        uint256 actualWithdrawAmount = balance; // Simplified - withdraw all contract balance for this example.
        payable(platformOwner).transfer(actualWithdrawAmount);
        emit PlatformFeesWithdrawn(platformOwner, actualWithdrawAmount);
    }

    /// @notice Returns the current platform fee percentage.
    /// @return Platform fee percentage.
    function getPlatformFeePercentage() external view returns (uint256) {
        return platformFeePercentage;
    }


    // --- 7. Emergency and Admin Functions ---

    /// @notice Allows platform owner to pause core functionalities in case of emergency.
    function pauseContract() external onlyPlatformOwner {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Allows platform owner to resume contract functionalities.
    function unpauseContract() external onlyPlatformOwner {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return contractPaused;
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```