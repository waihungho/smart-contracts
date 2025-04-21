```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Storytelling (DAS) Contract
 * @author Bard (Example - Creative Smart Contract)
 * @notice This contract implements a decentralized platform for collaborative storytelling.
 *         Users can contribute chapters, vote on the story's direction, earn rewards, and more.
 *         It explores concepts like dynamic NFTs, reputation systems, and decentralized governance within storytelling.
 *
 * Function Summary:
 * -----------------
 * Story Management:
 *   1. createStory(string _title, string _initialChapterContent, string _genre, string _theme): Allows users to create a new story with initial details.
 *   2. setStoryMetadata(uint256 _storyId, string _genre, string _theme): Allows the story creator to update the story's genre and theme.
 *   3. getStoryDetails(uint256 _storyId): Retrieves detailed information about a specific story.
 *   4. getStoryChapterCount(uint256 _storyId): Returns the number of chapters in a given story.
 *   5. getLatestChapterId(uint256 _storyId): Returns the ID of the latest chapter in a story.
 *   6. getChapterContent(uint256 _storyId, uint256 _chapterId): Retrieves the content of a specific chapter within a story.
 *   7. getStoryChapterIds(uint256 _storyId): Returns a list of chapter IDs for a given story.
 *
 * Chapter Contribution & Voting:
 *   8. contributeChapter(uint256 _storyId, string _chapterContent, uint256 _votingDuration): Allows users to propose a new chapter for a story, initiating a voting period.
 *   9. voteForChapter(uint256 _storyId, uint256 _chapterId): Allows registered users to vote in favor of a proposed chapter.
 *  10. voteAgainstChapter(uint256 _storyId, uint256 _chapterId): Allows registered users to vote against a proposed chapter.
 *  11. finalizeChapterVoting(uint256 _storyId, uint256 _chapterId): Ends the voting period for a chapter and determines if it's accepted based on votes.
 *  12. getChapterVotingStatus(uint256 _storyId, uint256 _chapterId): Retrieves the current voting status of a chapter (pending, accepted, rejected).
 *
 * User & Reputation Management:
 *  13. registerUser(string _username): Allows users to register on the platform with a unique username.
 *  14. getUserReputation(address _user): Returns the reputation score of a user.
 *  15. increaseUserReputation(address _user, uint256 _amount): Increases a user's reputation score (admin/governance function).
 *  16. decreaseUserReputation(address _user, uint256 _amount): Decreases a user's reputation score (admin/governance function).
 *  17. getUserStoriesCount(address _user): Returns the number of stories created by a user.
 *  18. getUserContributionsCount(address _user): Returns the number of chapters contributed by a user.
 *
 * Dynamic NFT & Rewards (Concept):
 *  19. mintChapterNFT(uint256 _storyId, uint256 _chapterId): Mints a dynamic NFT representing a specific chapter of a story (Concept - Requires NFT implementation and dynamic metadata update).
 *  20. rewardContributor(address _contributor, uint256 _storyId, uint256 _chapterId): Rewards a chapter contributor (using platform tokens or reputation) upon successful chapter acceptance (Concept - Requires token integration).
 *
 * Governance & Admin (Concept):
 *  21. pauseContract(): Pauses core functionalities of the contract (admin/governance function).
 *  22. unpauseContract(): Resumes core functionalities of the contract (admin/governance function).
 *  23. setVotingQuorum(uint256 _quorumPercentage): Sets the minimum percentage of votes required to accept a chapter (admin/governance function).
 *  24. setPlatformFee(uint256 _feePercentage): Sets a platform fee for story creation or other actions (admin/governance function - Concept).
 *
 * Utility & Info:
 *  25. getPlatformName(): Returns the name of the Decentralized Storytelling Platform.
 *  26. getContractVersion(): Returns the version of the smart contract.
 */

contract DecentralizedAutonomousStorytelling {

    string public platformName = "Decentralized Autonomous Storytelling Platform";
    string public contractVersion = "1.0.0";

    // --- Structs & Enums ---
    enum StoryStatus { CREATING, ACTIVE, COMPLETED, PAUSED }
    enum ChapterStatus { PROPOSED, VOTING, ACCEPTED, REJECTED }
    enum VoteType { FOR, AGAINST }

    struct Story {
        uint256 storyId;
        address creator;
        string title;
        string genre;
        string theme;
        StoryStatus status;
        uint256 chapterCount;
        uint256 latestChapterId;
        uint256 creationTimestamp;
    }

    struct Chapter {
        uint256 chapterId;
        uint256 storyId;
        address contributor;
        string content;
        ChapterStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 votingEndTime;
        uint256 contributionTimestamp;
    }

    struct User {
        address userAddress;
        string username;
        uint256 reputation;
        uint256 storiesCreatedCount;
        uint256 chaptersContributedCount;
        bool isRegistered;
    }

    // --- State Variables ---
    uint256 public storyCounter;
    uint256 public chapterCounter;
    mapping(uint256 => Story) public stories;
    mapping(uint256 => mapping(uint256 => Chapter)) public chapters; // storyId => chapterId => Chapter
    mapping(address => User) public users;
    mapping(uint256 => mapping(uint256 => mapping(address => VoteType))) public chapterVotes; // storyId => chapterId => voterAddress => VoteType
    mapping(string => address) public usernameToAddress; // username => user address
    mapping(address => string) public addressToUsername; // address => username

    address public contractOwner;
    bool public paused;
    uint256 public votingQuorumPercentage = 50; // Default 50% quorum
    uint256 public platformFeePercentage = 0; // Default 0% fee (Concept)

    // --- Events ---
    event StoryCreated(uint256 storyId, address creator, string title);
    event ChapterProposed(uint256 storyId, uint256 chapterId, address contributor);
    event ChapterVoted(uint256 storyId, uint256 chapterId, address voter, VoteType voteType);
    event ChapterVotingFinalized(uint256 storyId, uint256 chapterId, ChapterStatus status);
    event UserRegistered(address userAddress, string username);
    event ReputationChanged(address userAddress, uint256 newReputation);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
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

    modifier onlyRegisteredUsers() {
        require(users[msg.sender].isRegistered, "Only registered users can call this function.");
        _;
    }

    modifier validStoryId(uint256 _storyId) {
        require(stories[_storyId].storyId == _storyId, "Invalid story ID.");
        _;
    }

    modifier validChapterId(uint256 _storyId, uint256 _chapterId) {
        require(chapters[_storyId][_chapterId].chapterId == _chapterId, "Invalid chapter ID for this story.");
        _;
    }

    modifier chapterInVoting(uint256 _storyId, uint256 _chapterId) {
        require(chapters[_storyId][_chapterId].status == ChapterStatus.VOTING, "Chapter voting is not active.");
        _;
    }

    modifier chapterNotVoting(uint256 _storyId, uint256 _chapterId) {
        require(chapters[_storyId][_chapterId].status != ChapterStatus.VOTING, "Chapter voting is currently active.");
        _;
    }

    modifier chapterProposed(uint256 _storyId, uint256 _chapterId) {
        require(chapters[_storyId][_chapterId].status == ChapterStatus.PROPOSED, "Chapter is not in proposed status.");
        _;
    }


    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
        storyCounter = 0;
        chapterCounter = 0;
        paused = false;
    }

    // -------------------------------------------------------------------------
    // --- Story Management Functions ---
    // -------------------------------------------------------------------------

    /// @notice Allows users to create a new story with initial details.
    /// @param _title The title of the story.
    /// @param _initialChapterContent The content of the first chapter.
    /// @param _genre The genre of the story (e.g., Fantasy, Sci-Fi, Mystery).
    /// @param _theme The overarching theme of the story (e.g., Hope, Despair, Love).
    function createStory(
        string memory _title,
        string memory _initialChapterContent,
        string memory _genre,
        string memory _theme
    ) external onlyRegisteredUsers whenNotPaused {
        storyCounter++;
        uint256 currentStoryId = storyCounter;

        stories[currentStoryId] = Story({
            storyId: currentStoryId,
            creator: msg.sender,
            title: _title,
            genre: _genre,
            theme: _theme,
            status: StoryStatus.CREATING, // Initial status
            chapterCount: 0,
            latestChapterId: 0,
            creationTimestamp: block.timestamp
        });
        users[msg.sender].storiesCreatedCount++;

        // Create the initial chapter (Chapter 1)
        chapterCounter++;
        uint256 initialChapterId = chapterCounter;
        chapters[currentStoryId][initialChapterId] = Chapter({
            chapterId: initialChapterId,
            storyId: currentStoryId,
            contributor: msg.sender,
            content: _initialChapterContent,
            status: ChapterStatus.ACCEPTED, // Initial chapter is automatically accepted
            upvotes: 0,
            downvotes: 0,
            votingEndTime: 0,
            contributionTimestamp: block.timestamp
        });
        stories[currentStoryId].chapterCount = 1;
        stories[currentStoryId].latestChapterId = initialChapterId;
        stories[currentStoryId].status = StoryStatus.ACTIVE; // Move story to active status

        emit StoryCreated(currentStoryId, msg.sender, _title);
    }

    /// @notice Allows the story creator to update the story's genre and theme.
    /// @param _storyId The ID of the story to update.
    /// @param _genre The new genre of the story.
    /// @param _theme The new theme of the story.
    function setStoryMetadata(uint256 _storyId, string memory _genre, string memory _theme)
        external
        validStoryId(_storyId)
        whenNotPaused
    {
        require(stories[_storyId].creator == msg.sender, "Only story creator can set metadata.");
        stories[_storyId].genre = _genre;
        stories[_storyId].theme = _theme;
    }

    /// @notice Retrieves detailed information about a specific story.
    /// @param _storyId The ID of the story.
    /// @return Story struct containing story details.
    function getStoryDetails(uint256 _storyId)
        external
        view
        validStoryId(_storyId)
        returns (Story memory)
    {
        return stories[_storyId];
    }

    /// @notice Returns the number of chapters in a given story.
    /// @param _storyId The ID of the story.
    /// @return The chapter count.
    function getStoryChapterCount(uint256 _storyId)
        external
        view
        validStoryId(_storyId)
        returns (uint256)
    {
        return stories[_storyId].chapterCount;
    }

    /// @notice Returns the ID of the latest chapter in a story.
    /// @param _storyId The ID of the story.
    /// @return The latest chapter ID.
    function getLatestChapterId(uint256 _storyId)
        external
        view
        validStoryId(_storyId)
        returns (uint256)
    {
        return stories[_storyId].latestChapterId;
    }

    /// @notice Retrieves the content of a specific chapter within a story.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter.
    /// @return The content of the chapter.
    function getChapterContent(uint256 _storyId, uint256 _chapterId)
        external
        view
        validStoryId(_storyId)
        validChapterId(_storyId, _chapterId)
        returns (string memory)
    {
        return chapters[_storyId][_chapterId].content;
    }

    /// @notice Returns a list of chapter IDs for a given story.
    /// @param _storyId The ID of the story.
    /// @return An array of chapter IDs.
    function getStoryChapterIds(uint256 _storyId)
        external
        view
        validStoryId(_storyId)
        returns (uint256[] memory)
    {
        uint256 chapterCount = stories[_storyId].chapterCount;
        uint256[] memory chapterIds = new uint256[](chapterCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= chapterCounter; i++) { // Iterate through all chapter IDs (could be optimized if needed for very large stories)
            if (chapters[_storyId][i].storyId == _storyId && chapters[_storyId][i].chapterId != 0) {
                chapterIds[index] = i;
                index++;
            }
        }
        return chapterIds;
    }

    // -------------------------------------------------------------------------
    // --- Chapter Contribution & Voting Functions ---
    // -------------------------------------------------------------------------

    /// @notice Allows users to propose a new chapter for a story, initiating a voting period.
    /// @param _storyId The ID of the story to contribute to.
    /// @param _chapterContent The content of the proposed chapter.
    /// @param _votingDuration The duration of the voting period in seconds.
    function contributeChapter(uint256 _storyId, string memory _chapterContent, uint256 _votingDuration)
        external
        onlyRegisteredUsers
        validStoryId(_storyId)
        whenNotPaused
    {
        require(stories[_storyId].status == StoryStatus.ACTIVE, "Story is not active for contributions.");
        chapterCounter++;
        uint256 currentChapterId = chapterCounter;

        chapters[_storyId][currentChapterId] = Chapter({
            chapterId: currentChapterId,
            storyId: _storyId,
            contributor: msg.sender,
            content: _chapterContent,
            status: ChapterStatus.PROPOSED,
            upvotes: 0,
            downvotes: 0,
            votingEndTime: block.timestamp + _votingDuration,
            contributionTimestamp: block.timestamp
        });
        users[msg.sender].chaptersContributedCount++;

        emit ChapterProposed(_storyId, currentChapterId, msg.sender);
    }

    /// @notice Allows registered users to vote in favor of a proposed chapter.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter to vote for.
    function voteForChapter(uint256 _storyId, uint256 _chapterId)
        external
        onlyRegisteredUsers
        validStoryId(_storyId)
        validChapterId(_storyId, _chapterId)
        chapterProposed(_storyId, _chapterId) // Only vote on proposed chapters. Voting starts when finalized.
        whenNotPaused
    {
        require(chapterVotes[_storyId][_chapterId][msg.sender] == VoteType.FOR || chapterVotes[_storyId][_chapterId][msg.sender] == VoteType.AGAINST || chapterVotes[_storyId][_chapterId][msg.sender] == VoteType(0), "User has already voted on this chapter."); // ensure user has not voted already.
        chapterVotes[_storyId][_chapterId][msg.sender] = VoteType.FOR;
        chapters[_storyId][_chapterId].upvotes++;
        emit ChapterVoted(_storyId, _chapterId, msg.sender, VoteType.FOR);
    }

    /// @notice Allows registered users to vote against a proposed chapter.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter to vote against.
    function voteAgainstChapter(uint256 _storyId, uint256 _chapterId)
        external
        onlyRegisteredUsers
        validStoryId(_storyId)
        validChapterId(_storyId, _chapterId)
        chapterProposed(_storyId, _chapterId) // Only vote on proposed chapters. Voting starts when finalized.
        whenNotPaused
    {
        require(chapterVotes[_storyId][_chapterId][msg.sender] == VoteType.FOR || chapterVotes[_storyId][_chapterId][msg.sender] == VoteType.AGAINST || chapterVotes[_storyId][_chapterId][msg.sender] == VoteType(0), "User has already voted on this chapter."); // ensure user has not voted already.
        chapterVotes[_storyId][_chapterId][msg.sender] = VoteType.AGAINST;
        chapters[_storyId][_chapterId].downvotes++;
        emit ChapterVoted(_storyId, _chapterId, msg.sender, VoteType.AGAINST);
    }

    /// @notice Ends the voting period for a chapter and determines if it's accepted based on votes.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter to finalize voting for.
    function finalizeChapterVoting(uint256 _storyId, uint256 _chapterId)
        external
        validStoryId(_storyId)
        validChapterId(_storyId, _chapterId)
        chapterProposed(_storyId, _chapterId) // Only finalize voting for proposed chapters
        whenNotPaused
    {
        require(block.timestamp >= chapters[_storyId][_chapterId].votingEndTime, "Voting period is not over yet.");

        uint256 totalVotes = chapters[_storyId][_chapterId].upvotes + chapters[_storyId][_chapterId].downvotes;
        uint256 quorumThreshold = (totalVotes * votingQuorumPercentage) / 100; // Calculate quorum based on total votes cast, not registered users.

        ChapterStatus newStatus;
        if (chapters[_storyId][_chapterId].upvotes > chapters[_storyId][_chapterId].downvotes && chapters[_storyId][_chapterId].upvotes >= quorumThreshold) {
            newStatus = ChapterStatus.ACCEPTED;
            stories[_storyId].chapterCount++;
            stories[_storyId].latestChapterId = _chapterId;
            rewardContributor(chapters[_storyId][_chapterId].contributor, _storyId, _chapterId); // Concept - Reward contributor upon acceptance
        } else {
            newStatus = ChapterStatus.REJECTED;
        }

        chapters[_storyId][_chapterId].status = newStatus;
        emit ChapterVotingFinalized(_storyId, _chapterId, newStatus);
    }

    /// @notice Retrieves the current voting status of a chapter (pending, accepted, rejected).
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter.
    /// @return The voting status of the chapter.
    function getChapterVotingStatus(uint256 _storyId, uint256 _chapterId)
        external
        view
        validStoryId(_storyId)
        validChapterId(_storyId, _chapterId)
        returns (ChapterStatus)
    {
        return chapters[_storyId][_chapterId].status;
    }

    // -------------------------------------------------------------------------
    // --- User & Reputation Management Functions ---
    // -------------------------------------------------------------------------

    /// @notice Allows users to register on the platform with a unique username.
    /// @param _username The desired username.
    function registerUser(string memory _username) external whenNotPaused {
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        require(users[msg.sender].isRegistered == false, "User is already registered.");

        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            reputation: 0, // Initial reputation
            storiesCreatedCount: 0,
            chaptersContributedCount: 0,
            isRegistered: true
        });
        usernameToAddress[_username] = msg.sender;
        addressToUsername[msg.sender] = _username;
        emit UserRegistered(msg.sender, _username);
    }

    /// @notice Returns the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return users[_user].reputation;
    }

    /// @notice Increases a user's reputation score (admin/governance function).
    /// @param _user The address of the user to increase reputation for.
    /// @param _amount The amount to increase reputation by.
    function increaseUserReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        users[_user].reputation += _amount;
        emit ReputationChanged(_user, users[_user].reputation);
    }

    /// @notice Decreases a user's reputation score (admin/governance function).
    /// @param _user The address of the user to decrease reputation for.
    /// @param _amount The amount to decrease reputation by.
    function decreaseUserReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        require(users[_user].reputation >= _amount, "Reputation cannot be negative.");
        users[_user].reputation -= _amount;
        emit ReputationChanged(_user, users[_user].reputation);
    }

    /// @notice Returns the number of stories created by a user.
    /// @param _user The address of the user.
    /// @return The number of stories created.
    function getUserStoriesCount(address _user) external view returns (uint256) {
        return users[_user].storiesCreatedCount;
    }

    /// @notice Returns the number of chapters contributed by a user.
    /// @param _user The address of the user.
    /// @return The number of chapters contributed.
    function getUserContributionsCount(address _user) external view returns (uint256) {
        return users[_user].chaptersContributedCount;
    }

    // -------------------------------------------------------------------------
    // --- Dynamic NFT & Rewards (Concept) ---
    // -------------------------------------------------------------------------

    /// @notice Mints a dynamic NFT representing a specific chapter of a story (Concept - Requires NFT implementation and dynamic metadata update).
    /// @dev This is a conceptual function. Actual NFT minting and dynamic metadata update would require integration with an NFT contract (e.g., ERC721 or ERC1155) and off-chain metadata services.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the chapter to mint as NFT.
    function mintChapterNFT(uint256 _storyId, uint256 _chapterId) external onlyRegisteredUsers validStoryId(_storyId) validChapterId(_storyId, _chapterId) whenNotPaused {
        // --- Conceptual NFT Minting Logic ---
        // 1. Check if the chapter is accepted.
        require(chapters[_storyId][_chapterId].status == ChapterStatus.ACCEPTED, "Chapter must be accepted to mint NFT.");
        // 2. (Conceptual) Interact with an NFT contract to mint a new NFT.
        //    - This would likely involve calling a function on an external NFT contract.
        //    - The token URI for the NFT would be dynamically generated based on the chapter content, story details, etc.
        //    - Example (Conceptual - Not actual Solidity code for NFT interaction):
        //      NFTContract.mintNFT(msg.sender, generateChapterMetadataURI(_storyId, _chapterId));
        // 3. (Conceptual) Update the NFT metadata dynamically as the story evolves or the chapter is further interacted with.
        //    - This might involve off-chain services to update the metadata associated with the NFT based on events on this contract.

        // For this example, we'll just emit an event indicating NFT minting (conceptually).
        // emit ChapterNFTMinted(_storyId, _chapterId, msg.sender); // Conceptual event
        // --- End Conceptual NFT Minting Logic ---

        // In a real implementation, you would replace the comments above with actual NFT contract interactions.
        // You would need to define an NFT contract and interact with it from this smart contract.
        // Dynamic metadata update typically requires off-chain infrastructure (e.g., IPFS, decentralized storage, and metadata update services).
        // This function serves as a placeholder to illustrate the concept of dynamic chapter NFTs.
        // For a complete implementation, you would need to:
        // 1. Deploy an NFT contract (ERC721 or ERC1155).
        // 2. Implement the necessary interfaces to interact with the NFT contract.
        // 3. Design a dynamic metadata structure for chapter NFTs.
        // 4. Potentially use off-chain services to handle metadata updates and storage.

        // For now, as a simplified representation, we'll just emit an event.
        emit ChapterNFTMintedConcept(_storyId, _chapterId, msg.sender);
    }

    event ChapterNFTMintedConcept(uint256 storyId, uint256 chapterId, address minter); // Conceptual Event for NFT minting.

    /// @notice Rewards a chapter contributor (using platform tokens or reputation) upon successful chapter acceptance (Concept - Requires token integration).
    /// @dev This is a conceptual function. Actual reward implementation would require integration with a token contract (e.g., ERC20) or a more sophisticated reputation/reward system.
    /// @param _contributor The address of the chapter contributor to reward.
    /// @param _storyId The ID of the story.
    /// @param _chapterId The ID of the accepted chapter.
    function rewardContributor(address _contributor, uint256 _storyId, uint256 _chapterId) internal {
        // --- Conceptual Reward Logic ---
        // 1. (Conceptual) Transfer platform tokens to the contributor.
        //    - This would involve interacting with a platform token contract (e.g., ERC20).
        //    - Example (Conceptual - Not actual Solidity code for token transfer):
        //      PlatformToken.transfer(_contributor, rewardAmount); // rewardAmount would be determined based on story/chapter parameters.

        // 2. (Conceptual) Increase the contributor's reputation score.
        increaseUserReputation(_contributor, 10); // Example reputation reward (adjust as needed)

        // For this example, we'll just emit an event indicating reward (conceptually).
        // emit ContributorRewarded(_contributor, _storyId, _chapterId, rewardAmount); // Conceptual event
        // --- End Conceptual Reward Logic ---

        // In a real implementation, you would replace the comments above with actual token contract interactions or more complex reward logic.
        // You would need to define a platform token contract (ERC20 or similar) and integrate it with this smart contract.
        // The reward amount could be based on various factors (e.g., story popularity, chapter length, reputation of the contributor, etc.).

        // For now, as a simplified representation, we'll just emit an event and increase reputation.
        emit ContributorRewardedConcept(_contributor, _storyId, _chapterId);
    }

    event ContributorRewardedConcept(address contributor, uint256 storyId, uint256 chapterId); // Conceptual Event for rewarding contributor.

    // -------------------------------------------------------------------------
    // --- Governance & Admin (Concept) ---
    // -------------------------------------------------------------------------

    /// @notice Pauses core functionalities of the contract (admin/governance function).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes core functionalities of the contract (admin/governance function).
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets the minimum percentage of votes required to accept a chapter (admin/governance function).
    /// @param _quorumPercentage The new quorum percentage (e.g., 50 for 50%).
    function setVotingQuorum(uint256 _quorumPercentage) external onlyOwner whenNotPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
    }

    /// @notice Sets a platform fee for story creation or other actions (admin/governance function - Concept).
    /// @dev This is a conceptual function. Actual fee implementation would require handling token transfers and fee distribution.
    /// @param _feePercentage The new platform fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        // --- Conceptual Fee Implementation ---
        // In a real implementation, you would likely apply this fee during actions like story creation or chapter contribution.
        // When a fee-requiring action is performed, you would calculate the fee amount based on _feePercentage and potentially transfer tokens from the user to the platform owner or a designated platform treasury.
        // --- End Conceptual Fee Implementation ---
    }

    // -------------------------------------------------------------------------
    // --- Utility & Info Functions ---
    // -------------------------------------------------------------------------

    /// @notice Returns the name of the Decentralized Storytelling Platform.
    /// @return The platform name.
    function getPlatformName() external view returns (string memory) {
        return platformName;
    }

    /// @notice Returns the version of the smart contract.
    /// @return The contract version string.
    function getContractVersion() external view returns (string memory) {
        return contractVersion;
    }
}
```