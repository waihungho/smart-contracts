```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a decentralized platform where content creators can publish dynamic content,
 *        and users can interact with it through various mechanisms, including staking, voting, and personalized feeds.
 *
 * Function Summary:
 *
 * 1.  registerContentCreator(string _creatorName, string _profileURL): Allows users to register as content creators.
 * 2.  createContentStream(string _streamTitle, string _initialContentURI, uint256 _stakeRequirement): Creators initiate a content stream with initial content and stake requirement.
 * 3.  updateContentURI(uint256 _streamId, string _newContentURI): Creators update the content URI of their stream.
 * 4.  stakeOnStream(uint256 _streamId): Users stake ETH to access and support a content stream.
 * 5.  unstakeFromStream(uint256 _streamId): Users unstake ETH from a stream, losing access if stake falls below requirement.
 * 6.  getContentStreamDetails(uint256 _streamId): Retrieves detailed information about a specific content stream.
 * 7.  getContentCreatorProfile(address _creatorAddress): Fetches profile information of a content creator.
 * 8.  getTrendingStreams(uint256 _count): Returns a list of trending content stream IDs based on staking activity.
 * 9.  voteOnContent(uint256 _streamId, uint256 _voteValue): Users vote on content streams (e.g., quality, relevance).
 * 10. getContentStreamRating(uint256 _streamId): Returns the aggregated rating of a content stream based on user votes.
 * 11. reportContentStream(uint256 _streamId, string _reportReason): Users can report content streams for policy violations.
 * 12. moderateContentStream(uint256 _streamId, bool _isApproved): Platform moderators can approve or disapprove reported content streams.
 * 13. setModerator(address _moderatorAddress, bool _isModerator): Contract owner can assign/revoke moderator roles.
 * 14. withdrawCreatorEarnings(uint256 _streamId): Content creators can withdraw accumulated earnings from staked funds.
 * 15. setPlatformFee(uint256 _feePercentage): Contract owner can set the platform fee percentage on staking.
 * 16. getPlatformFee(): Returns the current platform fee percentage.
 * 17. getContentStreamsByCreator(address _creatorAddress): Retrieves a list of content streams created by a specific address.
 * 18. getStakedStreamsByUser(address _userAddress): Returns a list of content streams a user has staked on.
 * 19. emergencyWithdraw(): Allows contract owner to withdraw all contract balance in case of emergency.
 * 20. pauseContract(): Allows contract owner to pause all critical functions of the contract for maintenance.
 * 21. unpauseContract(): Allows contract owner to resume contract functions after maintenance.
 * 22. getContentStreamStakeRequirement(uint256 _streamId): Retrieves the stake requirement for a specific content stream.
 */

contract DecentralizedDynamicContentPlatform {

    // --- Data Structures ---
    struct ContentCreator {
        string creatorName;
        string profileURL;
        bool isRegistered;
    }

    struct ContentStream {
        address creator;
        string streamTitle;
        string contentURI;
        uint256 stakeRequirement;
        uint256 totalStaked;
        uint256 ratingScore; // Sum of all votes
        uint256 voteCount;
        bool isApproved;
    }

    // --- State Variables ---
    mapping(address => ContentCreator) public contentCreators;
    mapping(uint256 => ContentStream) public contentStreams;
    mapping(uint256 => mapping(address => uint256)) public streamStakes; // streamId => user => stakeAmount
    mapping(uint256 => mapping(address => uint256)) public streamVotes;  // streamId => user => voteValue
    mapping(uint256 => address[]) public streamReporters; // streamId => array of reporter addresses
    mapping(address => bool) public moderators;
    address public contractOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public streamCounter = 0;
    bool public paused = false;

    // --- Events ---
    event CreatorRegistered(address creatorAddress, string creatorName);
    event ContentStreamCreated(uint256 streamId, address creatorAddress, string streamTitle);
    event ContentURIUpdated(uint256 streamId, string newContentURI);
    event StakeAdded(uint256 streamId, address staker, uint256 amount);
    event StakeRemoved(uint256 streamId, address unstaker, uint256 amount);
    event ContentVoted(uint256 streamId, address voter, uint256 voteValue);
    event ContentReported(uint256 streamId, address reporter, string reason);
    event ContentModerated(uint256 streamId, bool isApproved, address moderator);
    event ModeratorSet(address moderator, bool isModerator);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event EmergencyWithdrawal(address owner, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier onlyRegisteredCreator() {
        require(contentCreators[msg.sender].isRegistered, "Only registered content creators can call this function.");
        _;
    }

    modifier streamExists(uint256 _streamId) {
        require(contentStreams[_streamId].creator != address(0), "Content stream does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
        moderators[msg.sender] = true; // Owner is also a moderator by default
    }

    // --- Content Creator Functions ---

    /// @notice Allows users to register as content creators.
    /// @param _creatorName The name of the content creator.
    /// @param _profileURL URL to the creator's profile or website.
    function registerContentCreator(string memory _creatorName, string memory _profileURL) external notPaused {
        require(!contentCreators[msg.sender].isRegistered, "Already registered as a creator.");
        contentCreators[msg.sender] = ContentCreator({
            creatorName: _creatorName,
            profileURL: _profileURL,
            isRegistered: true
        });
        emit CreatorRegistered(msg.sender, _creatorName);
    }

    /// @notice Allows registered creators to initiate a new content stream.
    /// @param _streamTitle Title of the content stream.
    /// @param _initialContentURI Initial URI pointing to the content.
    /// @param _stakeRequirement Minimum ETH stake required to access the stream.
    function createContentStream(
        string memory _streamTitle,
        string memory _initialContentURI,
        uint256 _stakeRequirement
    ) external onlyRegisteredCreator notPaused {
        streamCounter++;
        contentStreams[streamCounter] = ContentStream({
            creator: msg.sender,
            streamTitle: _streamTitle,
            contentURI: _initialContentURI,
            stakeRequirement: _stakeRequirement,
            totalStaked: 0,
            ratingScore: 0,
            voteCount: 0,
            isApproved: true // Initially approved, can be moderated later
        });
        emit ContentStreamCreated(streamCounter, msg.sender, _streamTitle);
    }

    /// @notice Allows creators to update the content URI of their stream.
    /// @param _streamId ID of the content stream to update.
    /// @param _newContentURI New URI pointing to the updated content.
    function updateContentURI(uint256 _streamId, string memory _newContentURI)
        external
        onlyRegisteredCreator
        streamExists(_streamId)
        notPaused
    {
        require(contentStreams[_streamId].creator == msg.sender, "Only the stream creator can update content URI.");
        contentStreams[_streamId].contentURI = _newContentURI;
        emit ContentURIUpdated(_streamId, _newContentURI);
    }

    // --- User Interaction Functions ---

    /// @notice Allows users to stake ETH on a content stream to access and support it.
    /// @param _streamId ID of the content stream to stake on.
    function stakeOnStream(uint256 _streamId) external payable streamExists(_streamId) notPaused {
        uint256 currentStake = streamStakes[_streamId][msg.sender];
        uint256 newStake = currentStake + msg.value;
        streamStakes[_streamId][msg.sender] = newStake;
        contentStreams[_streamId].totalStaked += msg.value;
        emit StakeAdded(_streamId, msg.sender, msg.value);
    }

    /// @notice Allows users to unstake ETH from a content stream.
    /// @param _streamId ID of the content stream to unstake from.
    function unstakeFromStream(uint256 _streamId) external streamExists(_streamId) notPaused {
        uint256 currentStake = streamStakes[_streamId][msg.sender];
        require(currentStake > 0, "No stake to withdraw.");

        uint256 amountToWithdraw = currentStake; // Users can withdraw their entire stake for simplicity
        streamStakes[_streamId][msg.sender] = 0;
        contentStreams[_streamId].totalStaked -= amountToWithdraw;

        payable(msg.sender).transfer(amountToWithdraw);
        emit StakeRemoved(_streamId, msg.sender, amountToWithdraw);
    }

    /// @notice Allows users to vote on a content stream.
    /// @param _streamId ID of the content stream to vote on.
    /// @param _voteValue Vote value (e.g., 1 to 5 stars).
    function voteOnContent(uint256 _streamId, uint256 _voteValue) external streamExists(_streamId) notPaused {
        require(_voteValue >= 1 && _voteValue <= 5, "Vote value must be between 1 and 5.");
        require(streamStakes[_streamId][msg.sender] >= contentStreams[_streamId].stakeRequirement, "Must be staked to vote.");
        require(streamVotes[_streamId][msg.sender] == 0, "Already voted on this stream."); // Prevent multiple voting

        streamVotes[_streamId][msg.sender] = _voteValue;
        contentStreams[_streamId].ratingScore += _voteValue;
        contentStreams[_streamId].voteCount++;
        emit ContentVoted(_streamId, msg.sender, _voteValue);
    }

    /// @notice Allows users to report a content stream for policy violations.
    /// @param _streamId ID of the content stream to report.
    /// @param _reportReason Reason for reporting the content stream.
    function reportContentStream(uint256 _streamId, string memory _reportReason) external streamExists(_streamId) notPaused {
        // Basic check to prevent duplicate reports from the same user (can be improved)
        bool alreadyReported = false;
        for (uint256 i = 0; i < streamReporters[_streamId].length; i++) {
            if (streamReporters[_streamId][i] == msg.sender) {
                alreadyReported = true;
                break;
            }
        }
        require(!alreadyReported, "Already reported this stream.");

        streamReporters[_streamId].push(msg.sender);
        emit ContentReported(_streamId, msg.sender, _reportReason);
    }

    // --- Moderator Functions ---

    /// @notice Allows moderators to approve or disapprove a reported content stream.
    /// @param _streamId ID of the content stream to moderate.
    /// @param _isApproved Boolean indicating whether to approve (true) or disapprove (false).
    function moderateContentStream(uint256 _streamId, bool _isApproved) external onlyModerator streamExists(_streamId) notPaused {
        contentStreams[_streamId].isApproved = _isApproved;
        emit ContentModerated(_streamId, _isApproved, msg.sender);
    }

    /// @notice Allows the contract owner to set or revoke moderator roles.
    /// @param _moderatorAddress Address of the user to set/revoke moderator role.
    /// @param _isModerator Boolean indicating whether to grant (true) or revoke (false) moderator role.
    function setModerator(address _moderatorAddress, bool _isModerator) external onlyOwner notPaused {
        moderators[_moderatorAddress] = _isModerator;
        emit ModeratorSet(_moderatorAddress, _isModerator);
    }


    // --- Creator Earnings and Platform Fee Functions ---

    /// @notice Allows content creators to withdraw their earnings from staked funds, minus platform fee.
    /// @param _streamId ID of the content stream to withdraw earnings from.
    function withdrawCreatorEarnings(uint256 _streamId) external onlyRegisteredCreator streamExists(_streamId) notPaused {
        require(contentStreams[_streamId].creator == msg.sender, "Only the stream creator can withdraw earnings.");
        uint256 totalStake = contentStreams[_streamId].totalStaked;
        uint256 platformFee = (totalStake * platformFeePercentage) / 100;
        uint256 creatorEarnings = totalStake - platformFee;

        require(creatorEarnings > 0, "No earnings to withdraw after platform fee.");
        contentStreams[_streamId].totalStaked = 0; // Reset staked amount after withdrawal (simplified model)

        payable(msg.sender).transfer(creatorEarnings);
        // Platform fee can be handled in a more sophisticated way, e.g., transferred to a platform wallet.
        // For simplicity, in this example, it's just deducted from the creator's withdrawal.
    }

    /// @notice Allows the contract owner to set the platform fee percentage.
    /// @param _feePercentage New platform fee percentage (0 to 100).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner notPaused {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /// @notice Returns the current platform fee percentage.
    /// @return The current platform fee percentage.
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    // --- Data Retrieval Functions ---

    /// @notice Retrieves detailed information about a specific content stream.
    /// @param _streamId ID of the content stream.
    /// @return ContentStream struct containing stream details.
    function getContentStreamDetails(uint256 _streamId) external view streamExists(_streamId) returns (ContentStream memory) {
        return contentStreams[_streamId];
    }

    /// @notice Retrieves profile information of a content creator.
    /// @param _creatorAddress Address of the content creator.
    /// @return ContentCreator struct containing creator profile details.
    function getContentCreatorProfile(address _creatorAddress) external view returns (ContentCreator memory) {
        return contentCreators[_creatorAddress];
    }

    /// @notice Retrieves a list of trending content stream IDs based on total staked amount.
    /// @param _count Number of trending streams to retrieve.
    /// @return Array of content stream IDs, sorted by total staked amount in descending order.
    function getTrendingStreams(uint256 _count) external view returns (uint256[] memory) {
        uint256[] memory allStreamIds = new uint256[](streamCounter);
        for (uint256 i = 1; i <= streamCounter; i++) {
            allStreamIds[i - 1] = i;
        }

        // Simple bubble sort for demonstration. In production, consider more efficient sorting.
        for (uint256 i = 0; i < streamCounter - 1; i++) {
            for (uint256 j = 0; j < streamCounter - i - 1; j++) {
                if (contentStreams[allStreamIds[j]].totalStaked < contentStreams[allStreamIds[j + 1]].totalStaked) {
                    uint256 temp = allStreamIds[j];
                    allStreamIds[j] = allStreamIds[j + 1];
                    allStreamIds[j + 1] = temp;
                }
            }
        }

        uint256 actualCount = _count > streamCounter ? streamCounter : _count;
        uint256[] memory trendingStreamIds = new uint256[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            trendingStreamIds[i] = allStreamIds[i];
        }
        return trendingStreamIds;
    }

    /// @notice Returns the aggregated rating of a content stream based on user votes.
    /// @param _streamId ID of the content stream.
    /// @return Average rating of the content stream (0 if no votes).
    function getContentStreamRating(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        if (contentStreams[_streamId].voteCount == 0) {
            return 0;
        }
        return contentStreams[_streamId].ratingScore / contentStreams[_streamId].voteCount;
    }

    /// @notice Retrieves a list of content streams created by a specific address.
    /// @param _creatorAddress Address of the content creator.
    /// @return Array of content stream IDs created by the specified address.
    function getContentStreamsByCreator(address _creatorAddress) external view returns (uint256[] memory) {
        uint256[] memory creatorStreams = new uint256[](streamCounter); // Max size, may have empty slots
        uint256 streamCount = 0;
        for (uint256 i = 1; i <= streamCounter; i++) {
            if (contentStreams[i].creator == _creatorAddress) {
                creatorStreams[streamCount] = i;
                streamCount++;
            }
        }
        // Resize array to actual number of streams
        uint256[] memory resultStreams = new uint256[](streamCount);
        for (uint256 i = 0; i < streamCount; i++) {
            resultStreams[i] = creatorStreams[i];
        }
        return resultStreams;
    }

    /// @notice Retrieves a list of content streams a user has staked on.
    /// @param _userAddress Address of the user.
    /// @return Array of content stream IDs the user has staked on.
    function getStakedStreamsByUser(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory stakedStreams = new uint256[](streamCounter); // Max size, may have empty slots
        uint256 streamCount = 0;
        for (uint256 i = 1; i <= streamCounter; i++) {
            if (streamStakes[i][_userAddress] > 0) {
                stakedStreams[streamCount] = i;
                streamCount++;
            }
        }
        // Resize array to actual number of streams
        uint256[] memory resultStreams = new uint256[](streamCount);
        for (uint256 i = 0; i < streamCount; i++) {
            resultStreams[i] = stakedStreams[i];
        }
        return resultStreams;
    }

    /// @notice Retrieves the stake requirement for a specific content stream.
    /// @param _streamId ID of the content stream.
    /// @return Stake requirement amount in Wei.
    function getContentStreamStakeRequirement(uint256 _streamId) external view streamExists(_streamId) returns (uint256) {
        return contentStreams[_streamId].stakeRequirement;
    }

    // --- Emergency and Maintenance Functions ---

    /// @notice Allows the contract owner to withdraw all ETH from the contract in case of emergency.
    function emergencyWithdraw() external onlyOwner notPaused {
        uint256 contractBalance = address(this).balance;
        payable(contractOwner).transfer(contractBalance);
        emit EmergencyWithdrawal(contractOwner, contractBalance);
    }

    /// @notice Pauses the contract, preventing critical functions from being executed.
    function pauseContract() external onlyOwner notPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, resuming normal operations.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
}
```