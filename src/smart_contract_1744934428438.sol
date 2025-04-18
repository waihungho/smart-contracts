```solidity
/**
 * @title Decentralized Collaborative Storytelling Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract enabling decentralized, collaborative story creation and management.
 *
 * **Outline:**
 * 1. **Story Creation and Management:**
 *    - `createStory(string _title, string _genre, string _initialParagraph)`: Allows users to create a new story with title, genre, and initial paragraph.
 *    - `pauseStory(uint256 _storyId)`: Allows the story creator to temporarily pause contributions to a story.
 *    - `resumeStory(uint256 _storyId)`: Allows the story creator to resume contributions to a paused story.
 *    - `closeStoryForContributions(uint256 _storyId)`:  Allows the story creator to permanently close a story for new contributions.
 *    - `archiveStory(uint256 _storyId)`:  Archives a completed or closed story.
 *    - `reportStory(uint256 _storyId, string _reportReason)`: Allows users to report a story for inappropriate content.
 *    - `resolveReport(uint256 _storyId)`: (Admin function) Resolves a report on a story, potentially archiving it.
 *
 * 2. **Contribution System:**
 *    - `contributeToStory(uint256 _storyId, string _paragraph)`: Allows users to contribute a new paragraph to an active story.
 *    - `upvoteContribution(uint256 _storyId, uint256 _contributionId)`: Allows users to upvote a specific contribution.
 *    - `downvoteContribution(uint256 _storyId, uint256 _contributionId)`: Allows users to downvote a specific contribution.
 *    - `flagContribution(uint256 _storyId, uint256 _contributionId, string _flagReason)`: Allows users to flag a contribution for review.
 *    - `reviewContribution(uint256 _storyId, uint256 _contributionId, bool _isApproved)`: (Admin function) Reviews and approves or rejects a flagged contribution.
 *    - `removeContribution(uint256 _storyId, uint256 _contributionId)`: (Admin function) Removes a contribution from a story.
 *
 * 3. **Story Retrieval and Display:**
 *    - `getStoryDetails(uint256 _storyId)`: Retrieves detailed information about a specific story.
 *    - `getStoryParagraphs(uint256 _storyId)`: Retrieves all approved paragraphs for a given story in order.
 *    - `getContributionDetails(uint256 _storyId, uint256 _contributionId)`: Retrieves details of a specific contribution.
 *    - `getContributionsForStory(uint256 _storyId)`: Retrieves all contributions (pending and approved) for a story.
 *    - `getPendingContributionsForStory(uint256 _storyId)`: Retrieves only pending contributions for a story.
 *    - `getApprovedContributionsForStory(uint256 _storyId)`: Retrieves only approved contributions for a story.
 *    - `getAllStories()`: Retrieves a list of all story IDs.
 *    - `getActiveStories()`: Retrieves a list of IDs for stories currently open for contributions.
 *    - `getArchivedStories()`: Retrieves a list of IDs for archived stories.
 *
 * **Function Summary:**
 * - `createStory`: Initialize a new collaborative story.
 * - `pauseStory`: Temporarily halt contributions to a story.
 * - `resumeStory`: Reopen a paused story for contributions.
 * - `closeStoryForContributions`: Permanently stop new contributions to a story.
 * - `archiveStory`: Move a story to an archive status.
 * - `reportStory`: Allow users to report a story for issues.
 * - `resolveReport`: Admin function to handle story reports.
 * - `contributeToStory`: Add a paragraph to an active story.
 * - `upvoteContribution`: Users can upvote a contribution.
 * - `downvoteContribution`: Users can downvote a contribution.
 * - `flagContribution`: Users can flag a contribution for review.
 * - `reviewContribution`: Admin function to approve or reject flagged contributions.
 * - `removeContribution`: Admin function to delete a contribution.
 * - `getStoryDetails`: Fetch detailed information about a story.
 * - `getStoryParagraphs`: Retrieve approved paragraphs of a story.
 * - `getContributionDetails`: Fetch details of a specific contribution.
 * - `getContributionsForStory`: Get all contributions for a story (all statuses).
 * - `getPendingContributionsForStory`: Get only pending contributions.
 * - `getApprovedContributionsForStory`: Get only approved contributions.
 * - `getAllStories`: List all story IDs.
 * - `getActiveStories`: List IDs of stories currently open for contributions.
 * - `getArchivedStories`: List IDs of archived stories.
 */
pragma solidity ^0.8.0;

contract CollaborativeStory {

    // --- Structs and Enums ---

    enum StoryStatus { Active, Paused, Closed, Archived }
    enum ContributionStatus { Pending, Approved, Rejected }

    struct Story {
        address creator;
        string title;
        string genre;
        string initialParagraph;
        StoryStatus status;
        uint256 createdAt;
        uint256 contributionCount;
        uint256 reportCount;
    }

    struct Contribution {
        address author;
        string paragraph;
        ContributionStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 createdAt;
        string flagReason;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 reportedAt;
        bool resolved;
    }

    // --- State Variables ---

    mapping(uint256 => Story) public stories;
    mapping(uint256 => mapping(uint256 => Contribution)) public contributions;
    mapping(uint256 => Report) public storyReports; // StoryId to Report
    uint256 public storyCount;
    uint256 public contributionCount;
    address public admin; // Address of the contract administrator

    // --- Events ---

    event StoryCreated(uint256 storyId, address creator, string title);
    event StoryStatusUpdated(uint256 storyId, StoryStatus newStatus);
    event ContributionSubmitted(uint256 storyId, uint256 contributionId, address author);
    event ContributionUpvoted(uint256 storyId, uint256 contributionId, address voter);
    event ContributionDownvoted(uint256 storyId, uint256 contributionId, address voter);
    event ContributionFlagged(uint256 storyId, uint256 contributionId, address flagger, string reason);
    event ContributionReviewed(uint256 storyId, uint256 contributionId, bool isApproved);
    event ContributionRemoved(uint256 storyId, uint256 contributionId);
    event StoryReported(uint256 storyId, address reporter, string reason);
    event StoryReportResolved(uint256 storyId);

    // --- Modifiers ---

    modifier onlyStoryCreator(uint256 _storyId) {
        require(stories[_storyId].creator == msg.sender, "Only story creator can perform this action.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier validStoryId(uint256 _storyId) {
        require(_storyId > 0 && _storyId <= storyCount, "Invalid story ID.");
        _;
    }

    modifier validContributionId(uint256 _storyId, uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= stories[_storyId].contributionCount, "Invalid contribution ID.");
        _;
    }

    modifier storyInStatus(uint256 _storyId, StoryStatus _status) {
        require(stories[_storyId].status == _status, "Story is not in the required status.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender; // Set the contract deployer as the initial admin
        storyCount = 0;
        contributionCount = 0;
    }

    // --- 1. Story Creation and Management Functions ---

    function createStory(string memory _title, string memory _genre, string memory _initialParagraph) public {
        storyCount++;
        stories[storyCount] = Story({
            creator: msg.sender,
            title: _title,
            genre: _genre,
            initialParagraph: _initialParagraph,
            status: StoryStatus.Active,
            createdAt: block.timestamp,
            contributionCount: 0,
            reportCount: 0
        });
        emit StoryCreated(storyCount, msg.sender, _title);
    }

    function pauseStory(uint256 _storyId) public validStoryId(_storyId) onlyStoryCreator(_storyId) storyInStatus(_storyId, StoryStatus.Active) {
        stories[_storyId].status = StoryStatus.Paused;
        emit StoryStatusUpdated(_storyId, StoryStatus.Paused);
    }

    function resumeStory(uint256 _storyId) public validStoryId(_storyId) onlyStoryCreator(_storyId) storyInStatus(_storyId, StoryStatus.Paused) {
        stories[_storyId].status = StoryStatus.Active;
        emit StoryStatusUpdated(_storyId, StoryStatus.Active);
    }

    function closeStoryForContributions(uint256 _storyId) public validStoryId(_storyId) onlyStoryCreator(_storyId) storyInStatus(_storyId, StoryStatus.Active) {
        stories[_storyId].status = StoryStatus.Closed;
        emit StoryStatusUpdated(_storyId, StoryStatus.Closed);
    }

    function archiveStory(uint256 _storyId) public validStoryId(_storyId) onlyStoryCreator(_storyId) {
        stories[_storyId].status = StoryStatus.Archived;
        emit StoryStatusUpdated(_storyId, StoryStatus.Archived);
    }

    function reportStory(uint256 _storyId, string memory _reportReason) public validStoryId(_storyId) {
        require(storyReports[_storyId].resolved == false, "Story already reported and pending resolution.");
        stories[_storyId].reportCount++;
        storyReports[_storyId] = Report({
            reporter: msg.sender,
            reason: _reportReason,
            reportedAt: block.timestamp,
            resolved: false
        });
        emit StoryReported(_storyId, msg.sender, _reportReason);
    }

    function resolveReport(uint256 _storyId) public validStoryId(_storyId) onlyAdmin {
        require(storyReports[_storyId].resolved == false, "Report already resolved.");
        storyReports[_storyId].resolved = true;
        // Potentially archive the story upon report resolution - can be customized
        if (stories[_storyId].reportCount > 0) { // Simple condition, can be made more sophisticated
            stories[_storyId].status = StoryStatus.Archived;
            emit StoryStatusUpdated(_storyId, StoryStatus.Archived);
        }
        emit StoryReportResolved(_storyId);
    }


    // --- 2. Contribution System Functions ---

    function contributeToStory(uint256 _storyId, string memory _paragraph) public validStoryId(_storyId) storyInStatus(_storyId, StoryStatus.Active) {
        contributionCount++;
        stories[_storyId].contributionCount++;
        contributions[_storyId][stories[_storyId].contributionCount] = Contribution({
            author: msg.sender,
            paragraph: _paragraph,
            status: ContributionStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            createdAt: block.timestamp,
            flagReason: ""
        });
        emit ContributionSubmitted(_storyId, stories[_storyId].contributionCount, msg.sender);
    }

    function upvoteContribution(uint256 _storyId, uint256 _contributionId) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) {
        contributions[_storyId][_contributionId].upvotes++;
        emit ContributionUpvoted(_storyId, _contributionId, msg.sender);
    }

    function downvoteContribution(uint256 _storyId, uint256 _contributionId) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) {
        contributions[_storyId][_contributionId].downvotes++;
        emit ContributionDownvoted(_storyId, _contributionId, msg.sender);
    }

    function flagContribution(uint256 _storyId, uint256 _contributionId, string memory _flagReason) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) {
        contributions[_storyId][_contributionId].flagReason = _flagReason;
        emit ContributionFlagged(_storyId, _contributionId, msg.sender, _flagReason);
    }

    function reviewContribution(uint256 _storyId, uint256 _contributionId, bool _isApproved) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyAdmin {
        if (_isApproved) {
            contributions[_storyId][_contributionId].status = ContributionStatus.Approved;
        } else {
            contributions[_storyId][_contributionId].status = ContributionStatus.Rejected;
        }
        emit ContributionReviewed(_storyId, _contributionId, _isApproved);
    }

    function removeContribution(uint256 _storyId, uint256 _contributionId) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyAdmin {
        contributions[_storyId][_contributionId].status = ContributionStatus.Rejected; // Mark as rejected instead of deleting for record keeping
        emit ContributionRemoved(_storyId, _contributionId);
    }


    // --- 3. Story Retrieval and Display Functions ---

    function getStoryDetails(uint256 _storyId) public view validStoryId(_storyId) returns (Story memory) {
        return stories[_storyId];
    }

    function getStoryParagraphs(uint256 _storyId) public view validStoryId(_storyId) returns (string[] memory) {
        string[] memory approvedParagraphs = new string[](stories[_storyId].contributionCount);
        uint256 paragraphIndex = 0;
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.Approved) {
                approvedParagraphs[paragraphIndex] = contributions[_storyId][i].paragraph;
                paragraphIndex++;
            }
        }
        // Resize the array to remove empty slots if there were rejected contributions
        assembly {
            mstore(approvedParagraphs, paragraphIndex) // Update the length of the array
        }
        return approvedParagraphs;
    }


    function getContributionDetails(uint256 _storyId, uint256 _contributionId) public view validStoryId(_storyId) validContributionId(_storyId, _contributionId) returns (Contribution memory) {
        return contributions[_storyId][_contributionId];
    }

    function getContributionsForStory(uint256 _storyId) public view validStoryId(_storyId) returns (Contribution[] memory) {
        Contribution[] memory allContributions = new Contribution[](stories[_storyId].contributionCount);
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            allContributions[i-1] = contributions[_storyId][_contributionId];
        }
        return allContributions;
    }

    function getPendingContributionsForStory(uint256 _storyId) public view validStoryId(_storyId) returns (Contribution[] memory) {
        uint256 pendingCount = 0;
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.Pending) {
                pendingCount++;
            }
        }
        Contribution[] memory pendingContributions = new Contribution[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.Pending) {
                pendingContributions[index] = contributions[_storyId][i];
                index++;
            }
        }
        return pendingContributions;
    }


    function getApprovedContributionsForStory(uint256 _storyId) public view validStoryId(_storyId) returns (Contribution[] memory) {
        uint256 approvedCount = 0;
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.Approved) {
                approvedCount++;
            }
        }
        Contribution[] memory approvedContributions = new Contribution[](approvedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= stories[_storyId].contributionCount; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.Approved) {
                approvedContributions[index] = contributions[_storyId][i];
                index++;
            }
        }
        return approvedContributions;
    }

    function getAllStories() public view returns (uint256[] memory) {
        uint256[] memory storyIds = new uint256[](storyCount);
        for (uint256 i = 1; i <= storyCount; i++) {
            storyIds[i - 1] = i;
        }
        return storyIds;
    }

    function getActiveStories() public view returns (uint256[] memory) {
        uint256 activeStoryCount = 0;
        for (uint256 i = 1; i <= storyCount; i++) {
            if (stories[i].status == StoryStatus.Active) {
                activeStoryCount++;
            }
        }
        uint256[] memory activeStoryIds = new uint256[](activeStoryCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= storyCount; i++) {
            if (stories[i].status == StoryStatus.Active) {
                activeStoryIds[index] = i;
                index++;
            }
        }
        return activeStoryIds;
    }

    function getArchivedStories() public view returns (uint256[] memory) {
        uint256 archivedStoryCount = 0;
        for (uint256 i = 1; i <= storyCount; i++) {
            if (stories[i].status == StoryStatus.Archived) {
                archivedStoryCount++;
            }
        }
        uint256[] memory archivedStoryIds = new uint256[](archivedStoryCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= storyCount; i++) {
            if (stories[i].status == StoryStatus.Archived) {
                archivedStoryIds[index] = i;
                index++;
            }
        }
        return archivedStoryIds;
    }
}
```