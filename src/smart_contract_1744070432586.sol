```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Storytelling (DAS) Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract enabling collaborative and decentralized storytelling.
 *
 * Outline and Function Summary:
 *
 * 1.  **Story Management:**
 *     - `startStory(string _title, string _genre, string _initialSection)`: Initializes a new story with a title, genre, and the first section.
 *     - `addChapter(uint256 _storyId, string _chapterTitle)`: Adds a new chapter to an existing story.
 *     - `openSectionForContribution(uint256 _storyId, uint256 _chapterId)`: Opens a new section within a chapter for user contributions.
 *     - `finalizeSection(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _winningContributionId)`:  Closes a section by selecting the winning contribution.
 *     - `publishChapter(uint256 _storyId, uint256 _chapterId)`: Marks a chapter as published, making it publicly viewable.
 *     - `getStoryDetails(uint256 _storyId)`: Retrieves detailed information about a story.
 *     - `getChapterDetails(uint256 _storyId, uint256 _chapterId)`: Retrieves details of a specific chapter.
 *     - `getSectionDetails(uint256 _storyId, uint256 _chapterId, uint256 _sectionId)`: Retrieves details of a section.
 *
 * 2.  **Contribution and Voting:**
 *     - `contributeToSection(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, string _contributionText)`: Allows users to submit a contribution to an open section.
 *     - `voteForContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId)`: Enables registered users to vote for a contribution in an open section.
 *     - `getUserContributionDetails(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, address _user)`:  Allows users to view their contribution details in a section.
 *     - `getSectionContributions(uint256 _storyId, uint256 _chapterId, uint256 _sectionId)`: Retrieves all contributions submitted to a specific section.
 *     - `getContributionVoteCount(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId)`: Gets the vote count for a specific contribution.
 *
 * 3.  **User Registration and Reputation (Basic):**
 *     - `registerUser(string _username)`: Allows users to register with a unique username (basic reputation system could be built upon this).
 *     - `getUserDetails(address _user)`: Retrieves details of a registered user.
 *     - `getUsername(address _user)`: Retrieves the username of a registered user.
 *
 * 4.  **Governance and Moderation (Simple):**
 *     - `setVotingDuration(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _durationInSeconds)`: Allows the story creator to set the voting duration for a section.
 *     - `reportContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId, string _reportReason)`: Allows users to report a contribution for moderation (basic moderation concept).
 *     - `resolveReport(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId, bool _removeContribution)`: Owner function to resolve reports and potentially remove contributions.
 *
 * 5.  **Utility and Information:**
 *     - `isSectionOpenForContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId)`: Checks if a section is currently open for contributions.
 *     - `isUserRegistered(address _user)`: Checks if an address is registered as a user.
 */
contract DecentralizedAutonomousStorytelling {

    // --- Structs & Enums ---

    enum SectionStatus { Open, Voting, Finalized, Published }

    struct Story {
        string title;
        string genre;
        address creator;
        uint256 chapterCount;
    }

    struct Chapter {
        string title;
        uint256 sectionCount;
        bool published;
    }

    struct Section {
        SectionStatus status;
        string prompt; // Optional prompt for the section
        uint256 contributionCount;
        uint256 votingEndTime;
        uint256 winningContributionId;
    }

    struct Contribution {
        address contributor;
        string text;
        uint256 voteCount;
        string reportReason; // For basic moderation tracking
        bool reported;
        bool removed;
    }

    struct User {
        string username;
        bool registered;
    }

    // --- State Variables ---

    mapping(uint256 => Story) public stories; // storyId => Story
    uint256 public storyCount;

    mapping(uint256 => mapping(uint256 => Chapter)) public chapters; // storyId => (chapterId => Chapter)
    mapping(uint256 => mapping(uint256 => uint256)) public chapterCounts; // storyId => (chapterId => sectionCount)

    mapping(uint256 => mapping(uint256 => mapping(uint256 => Section))) public sections; // storyId => (chapterId => (sectionId => Section))
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public sectionCounts; // storyId => (chapterId => (sectionId => contributionCount))

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => Contribution)))) public contributions; // storyId => (chapterId => (sectionId => (contributionId => Contribution)))
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => bool)))) public hasVoted; // storyId => (chapterId => (sectionId => (voterAddress => voted)))

    mapping(address => User) public users; // userAddress => User
    mapping(string => address) public usernamesToAddress; // username => userAddress


    uint256 public defaultVotingDuration = 86400; // 24 hours in seconds
    address public owner;

    // --- Events ---

    event StoryStarted(uint256 storyId, string title, address creator);
    event ChapterAdded(uint256 storyId, uint256 chapterId, string title);
    event SectionOpened(uint256 storyId, uint256 chapterId, uint256 sectionId);
    event ContributionSubmitted(uint256 storyId, uint256 chapterId, uint256 sectionId, uint256 contributionId, address contributor);
    event VoteCast(uint256 storyId, uint256 chapterId, uint256 sectionId, uint256 contributionId, address voter);
    event SectionFinalized(uint256 storyId, uint256 chapterId, uint256 sectionId, uint256 winningContributionId);
    event ChapterPublished(uint256 storyId, uint256 chapterId);
    event UserRegistered(address userAddress, string username);
    event ContributionReported(uint256 storyId, uint256 chapterId, uint256 sectionId, uint256 contributionId, address reporter, string reason);
    event ContributionResolved(uint256 storyId, uint256 chapterId, uint256 sectionId, uint256 contributionId, bool removed);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].registered, "You must be a registered user.");
        _;
    }

    modifier validStory(uint256 _storyId) {
        require(_storyId > 0 && _storyId <= storyCount, "Invalid story ID.");
        _;
    }

    modifier validChapter(uint256 _storyId, uint256 _chapterId) {
        require(_chapterId > 0 && _chapterId <= stories[_storyId].chapterCount, "Invalid chapter ID.");
        _;
    }

    modifier validSection(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) {
        require(_sectionId > 0 && _sectionId <= chapters[_storyId][_chapterId].sectionCount, "Invalid section ID.");
        _;
    }

    modifier sectionIsOpenForContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) {
        require(sections[_storyId][_chapterId][_sectionId].status == SectionStatus.Open, "Section is not open for contributions.");
        _;
    }

    modifier sectionIsOpenForVoting(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) {
        require(sections[_storyId][_chapterId][_sectionId].status == SectionStatus.Voting, "Section is not open for voting.");
        _;
    }

    modifier contributionExists(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= sections[_storyId][_chapterId][_sectionId].contributionCount, "Invalid contribution ID.");
        _;
    }

    modifier notAlreadyVoted(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) {
        require(!hasVoted[_storyId][_chapterId][_sectionId][msg.sender], "You have already voted in this section.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- 1. Story Management Functions ---

    function startStory(string memory _title, string memory _genre, string memory _initialSection) public onlyRegisteredUser returns (uint256 storyId) {
        storyCount++;
        storyId = storyCount;
        stories[storyId] = Story({
            title: _title,
            genre: _genre,
            creator: msg.sender,
            chapterCount: 0
        });
        emit StoryStarted(storyId, _title, msg.sender);
        addChapter(storyId, "Chapter 1"); // Automatically create first chapter
        openSectionForContribution(storyId, 1); // Automatically open first section
        contributeToSection(storyId, 1, 1, _initialSection); // Add initial section as first contribution
        return storyId;
    }

    function addChapter(uint256 _storyId, string memory _chapterTitle) public validStory(_storyId) onlyRegisteredUser returns (uint256 chapterId) {
        require(stories[_storyId].creator == msg.sender, "Only story creator can add chapters.");
        stories[_storyId].chapterCount++;
        chapterId = stories[_storyId].chapterCount;
        chapters[_storyId][chapterId] = Chapter({
            title: _chapterTitle,
            sectionCount: 0,
            published: false
        });
        emit ChapterAdded(_storyId, chapterId, _chapterTitle);
        return chapterId;
    }

    function openSectionForContribution(uint256 _storyId, uint256 _chapterId) public validStory(_storyId) validChapter(_storyId, _chapterId) onlyRegisteredUser {
        require(chapters[_storyId][_chapterId].published == false, "Chapter is already published, cannot add sections.");
        require(stories[_storyId].creator == msg.sender, "Only story creator can open sections.");
        chapters[_storyId][_chapterId].sectionCount++;
        uint256 sectionId = chapters[_storyId][_chapterId].sectionCount;
        sections[_storyId][_chapterId][sectionId] = Section({
            status: SectionStatus.Open,
            prompt: "", // Can be extended to add prompts in future
            contributionCount: 0,
            votingEndTime: 0,
            winningContributionId: 0
        });
        emit SectionOpened(_storyId, _chapterId, sectionId);
    }

    function finalizeSection(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _winningContributionId) public validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) onlyRegisteredUser {
        require(stories[_storyId].creator == msg.sender, "Only story creator can finalize sections.");
        require(sections[_storyId][_chapterId][_sectionId].status == SectionStatus.Voting, "Section is not in voting status.");
        require(_winningContributionId > 0 && _winningContributionId <= sections[_storyId][_chapterId][_sectionId].contributionCount, "Invalid winning contribution ID.");
        sections[_storyId][_chapterId][_sectionId].status = SectionStatus.Finalized;
        sections[_storyId][_chapterId][_sectionId].winningContributionId = _winningContributionId;
        emit SectionFinalized(_storyId, _chapterId, _sectionId, _winningContributionId);
    }

    function publishChapter(uint256 _storyId, uint256 _chapterId) public validStory(_storyId) validChapter(_storyId, _chapterId) onlyRegisteredUser {
        require(stories[_storyId].creator == msg.sender, "Only story creator can publish chapters.");
        require(chapters[_storyId][_chapterId].published == false, "Chapter is already published.");
        for (uint256 i = 1; i <= chapters[_storyId][_chapterId].sectionCount; i++) {
            require(sections[_storyId][_chapterId][i].status == SectionStatus.Finalized, "All sections in chapter must be finalized before publishing.");
        }
        chapters[_storyId][_chapterId].published = true;
        emit ChapterPublished(_storyId, _chapterId);
    }

    function getStoryDetails(uint256 _storyId) public view validStory(_storyId) returns (Story memory) {
        return stories[_storyId];
    }

    function getChapterDetails(uint256 _storyId, uint256 _chapterId) public view validStory(_storyId) validChapter(_storyId, _chapterId) returns (Chapter memory) {
        return chapters[_storyId][_chapterId];
    }

    function getSectionDetails(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) public view validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) returns (Section memory) {
        return sections[_storyId][_chapterId][_sectionId];
    }


    // --- 2. Contribution and Voting Functions ---

    function contributeToSection(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, string memory _contributionText) public validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) sectionIsOpenForContribution(_storyId, _chapterId, _sectionId) onlyRegisteredUser {
        sections[_storyId][_chapterId][_sectionId].contributionCount++;
        uint256 contributionId = sections[_storyId][_chapterId][_sectionId].contributionCount;
        contributions[_storyId][_chapterId][_sectionId][contributionId] = Contribution({
            contributor: msg.sender,
            text: _contributionText,
            voteCount: 0,
            reportReason: "",
            reported: false,
            removed: false
        });
        emit ContributionSubmitted(_storyId, _chapterId, _sectionId, contributionId, msg.sender);
    }

    function voteForContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId) public validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) sectionIsOpenForVoting(_storyId, _chapterId, _sectionId) contributionExists(_storyId, _chapterId, _sectionId, _contributionId) onlyRegisteredUser notAlreadyVoted(_storyId, _chapterId, _sectionId) {
        contributions[_storyId][_chapterId][_sectionId][_contributionId].voteCount++;
        hasVoted[_storyId][_chapterId][_sectionId][msg.sender] = true;
        emit VoteCast(_storyId, _chapterId, _sectionId, _contributionId, msg.sender);
    }

    function getUserContributionDetails(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, address _user) public view validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) returns (Contribution memory) {
        for (uint256 i = 1; i <= sections[_storyId][_chapterId][_sectionId].contributionCount; i++) {
            if (contributions[_storyId][_chapterId][_sectionId][i].contributor == _user) {
                return contributions[_storyId][_chapterId][_sectionId][i];
            }
        }
        revert("User has not contributed to this section.");
    }

    function getSectionContributions(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) public view validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) returns (Contribution[] memory) {
        uint256 contributionCount = sections[_storyId][_chapterId][_sectionId].contributionCount;
        Contribution[] memory sectionContributions = new Contribution[](contributionCount);
        for (uint256 i = 1; i <= contributionCount; i++) {
            sectionContributions[i-1] = contributions[_storyId][_chapterId][_sectionId][i];
        }
        return sectionContributions;
    }

    function getContributionVoteCount(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId) public view validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) contributionExists(_storyId, _chapterId, _sectionId, _contributionId) returns (uint256) {
        return contributions[_storyId][_chapterId][_sectionId][_contributionId].voteCount;
    }


    // --- 3. User Registration and Reputation (Basic) Functions ---

    function registerUser(string memory _username) public returns (bool success) {
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(usernamesToAddress[_username] == address(0), "Username already taken.");
        users[msg.sender] = User({
            username: _username,
            registered: true
        });
        usernamesToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
        return true;
    }

    function getUserDetails(address _user) public view returns (User memory) {
        return users[_user];
    }

    function getUsername(address _user) public view returns (string memory) {
        return users[_user].username;
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return users[_user].registered;
    }


    // --- 4. Governance and Moderation (Simple) Functions ---

    function setVotingDuration(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _durationInSeconds) public validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) onlyRegisteredUser {
        require(stories[_storyId].creator == msg.sender, "Only story creator can set voting duration.");
        require(sections[_storyId][_chapterId][_sectionId].status == SectionStatus.Open, "Voting can only be set for open sections.");
        sections[_storyId][_chapterId][_sectionId].status = SectionStatus.Voting;
        sections[_storyId][_chapterId][_sectionId].votingEndTime = block.timestamp + _durationInSeconds;
    }

    function reportContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId, string memory _reportReason) public validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) contributionExists(_storyId, _chapterId, _sectionId, _contributionId) onlyRegisteredUser {
        require(!contributions[_storyId][_chapterId][_sectionId][_contributionId].reported, "Contribution already reported.");
        contributions[_storyId][_chapterId][_sectionId][_contributionId].reported = true;
        contributions[_storyId][_chapterId][_sectionId][_contributionId].reportReason = _reportReason;
        emit ContributionReported(_storyId, _chapterId, _sectionId, _contributionId, msg.sender, _reportReason);
    }

    function resolveReport(uint256 _storyId, uint256 _chapterId, uint256 _sectionId, uint256 _contributionId, bool _removeContribution) public onlyOwner validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) contributionExists(_storyId, _chapterId, _sectionId, _contributionId) {
        if (_removeContribution) {
            contributions[_storyId][_chapterId][_sectionId][_contributionId].removed = true;
        }
        contributions[_storyId][_chapterId][_sectionId][_contributionId].reported = false; // Reset report status
        emit ContributionResolved(_storyId, _chapterId, _sectionId, _contributionId, _removeContribution);
    }


    // --- 5. Utility and Information Functions ---

    function isSectionOpenForContribution(uint256 _storyId, uint256 _chapterId, uint256 _sectionId) public view validStory(_storyId) validChapter(_storyId, _chapterId) validSection(_storyId, _chapterId, _sectionId) returns (bool) {
        return sections[_storyId][_chapterId][_sectionId].status == SectionStatus.Open;
    }
}
```