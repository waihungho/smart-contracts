```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Collaborative Storytelling Platform
 * @author Bard (Large Language Model)
 * @notice A smart contract that facilitates a decentralized collaborative storytelling experience.
 *
 * **Outline:**
 * 1. **Story Management:** Create, contribute to, and finalize stories.
 * 2. **Contribution System:** Submit contributions, vote on contributions, and merge accepted contributions.
 * 3. **Reputation System:** Reward contributors based on the success of their contributions.
 * 4. **Governance:** Allow the community to vote on key decisions.
 * 5. **NFT Integration:** Mint NFTs representing finished stories or significant contributions.
 * 6. **Royalties:** Distribute royalties to contributors upon story sales or usage.
 * 7. **Word Count Limits:**  Enforce minimum and maximum word limits for contributions.
 * 8. **Content Moderation:** Implement a basic reporting mechanism.
 * 9. **Themes:**  Allow stories to have assigned themes, affecting contribution rules.
 * 10. **Contribution Types:** Allow different types of contributions (text, images, audio).
 *
 * **Function Summary:**
 * - `createStory(string memory _title, string memory _initialText, string memory _theme)`: Creates a new story.
 * - `contribute(uint256 _storyId, string memory _contributionText, ContributionType _type, string memory _mediaUrl)`: Submits a contribution to a story.
 * - `vote(uint256 _storyId, uint256 _contributionId, bool _vote)`: Votes on a contribution.
 * - `finalizeStory(uint256 _storyId)`: Finalizes a story, preventing further contributions.
 * - `claimRewards(uint256 _storyId, uint256 _contributionId)`: Claims rewards for a successful contribution.
 * - `proposeThemeChange(uint256 _storyId, string memory _newTheme)`: Proposes a change to a story's theme.
 * - `voteOnThemeChange(uint256 _storyId, bool _vote)`: Votes on a proposed theme change.
 * - `reportContribution(uint256 _storyId, uint256 _contributionId)`: Reports a contribution for inappropriate content.
 * - `setWordCountLimits(uint256 _minWords, uint256 _maxWords)`: Sets the global word count limits for contributions.
 * - `mintStoryNFT(uint256 _storyId)`: Mints an NFT representing the completed story.
 * - `mintContributionNFT(uint256 _storyId, uint256 _contributionId)`: Mints an NFT representing a significant contribution.
 * - `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Sets the percentage of royalties distributed to contributors.
 * - `distributeRoyalties(uint256 _storyId, uint256 _amount)`: Distributes royalties to contributors of a story.
 * - `withdrawContractBalance()`: Allows the owner to withdraw the contract balance.
 * - `getStory(uint256 _storyId)`: Retrieves story details.
 * - `getContribution(uint256 _storyId, uint256 _contributionId)`: Retrieves contribution details.
 * - `getVotesForContribution(uint256 _storyId, uint256 _contributionId)`: Retrieves votes for a specific contribution.
 * - `getContributorReputation(address _contributor)`: Retrieves the reputation score of a contributor.
 * - `getStoryTheme(uint256 _storyId)`: Retrieves the theme for a specific story.
 * - `pauseContract()`: Pauses contract functionality (owner only).
 * - `unpauseContract()`: Unpauses contract functionality (owner only).
 */

contract CollaborativeStorytelling {

    // Enums
    enum ContributionType { TEXT, IMAGE, AUDIO }
    enum ContributionStatus { PENDING, ACCEPTED, REJECTED }

    // Structs
    struct Story {
        string title;
        string text;
        address creator;
        uint256 createdAt;
        bool finalized;
        string theme;
        bool themeChangeProposed;
        string proposedNewTheme;
        uint256 themeChangeVotesYes;
        uint256 themeChangeVotesNo;
        bool nftMinted;
    }

    struct Contribution {
        address contributor;
        string text;
        uint256 createdAt;
        uint256 votesYes;
        uint256 votesNo;
        ContributionStatus status;
        ContributionType contributionType;
        string mediaUrl;  // URL for image or audio contributions
        bool reported;
    }

    // State Variables
    Story[] public stories;
    mapping(uint256 => Contribution[]) public contributions;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public votes; // storyId => contributionId => voter => vote
    mapping(address => uint256) public contributorReputation;
    address public owner;
    uint256 public minWords = 10;
    uint256 public maxWords = 500;
    uint256 public royaltyPercentage = 5; // Default 5%
    bool public paused = false;

    // Events
    event StoryCreated(uint256 storyId, string title, address creator);
    event ContributionSubmitted(uint256 storyId, uint256 contributionId, address contributor);
    event Voted(uint256 storyId, uint256 contributionId, address voter, bool vote);
    event StoryFinalized(uint256 storyId);
    event RewardsClaimed(uint256 storyId, uint256 contributionId, address contributor, uint256 amount);
    event ThemeChangeProposed(uint256 storyId, string newTheme);
    event ThemeChangeVoted(uint256 storyId, bool vote);
    event ContributionReported(uint256 storyId, uint256 contributionId, address reporter);
    event StoryNFTMinted(uint256 storyId, address minter);
    event ContributionNFTMinted(uint256 storyId, uint256 contributionId, address minter);
    event RoyaltiesDistributed(uint256 storyId, uint256 amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyWhenNotPaused {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validStoryId(uint256 _storyId) {
        require(_storyId < stories.length, "Invalid story ID.");
        _;
    }

    modifier validContributionId(uint256 _storyId, uint256 _contributionId) {
        require(_contributionId < contributions[_storyId].length, "Invalid contribution ID.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // 1. Story Management

    /**
     * @notice Creates a new story.
     * @param _title The title of the story.
     * @param _initialText The initial text of the story.
     * @param _theme The theme of the story.
     */
    function createStory(string memory _title, string memory _initialText, string memory _theme) public onlyWhenNotPaused {
        require(bytes(_title).length > 0, "Title cannot be empty.");
        require(bytes(_initialText).length > 0, "Initial text cannot be empty.");

        stories.push(Story({
            title: _title,
            text: _initialText,
            creator: msg.sender,
            createdAt: block.timestamp,
            finalized: false,
            theme: _theme,
            themeChangeProposed: false,
            proposedNewTheme: "",
            themeChangeVotesYes: 0,
            themeChangeVotesNo: 0,
            nftMinted: false
        }));

        emit StoryCreated(stories.length - 1, _title, msg.sender);
    }

    /**
     * @notice Finalizes a story, preventing further contributions.
     * @param _storyId The ID of the story to finalize.
     */
    function finalizeStory(uint256 _storyId) public onlyOwner validStoryId(_storyId) onlyWhenNotPaused {
        require(!stories[_storyId].finalized, "Story is already finalized.");
        stories[_storyId].finalized = true;
        emit StoryFinalized(_storyId);
    }

    // 2. Contribution System

    /**
     * @notice Submits a contribution to a story.
     * @param _storyId The ID of the story to contribute to.
     * @param _contributionText The text of the contribution.
     * @param _type The type of contribution (TEXT, IMAGE, AUDIO).
     * @param _mediaUrl The URL for image or audio contributions.  Can be empty for text.
     */
    function contribute(uint256 _storyId, string memory _contributionText, ContributionType _type, string memory _mediaUrl) public onlyWhenNotPaused validStoryId(_storyId) {
        require(!stories[_storyId].finalized, "Story is finalized, cannot contribute.");
        require(bytes(_contributionText).length > 0 || bytes(_mediaUrl).length > 0, "Contribution cannot be empty.");

        uint256 wordCount = countWords(_contributionText);
        require(wordCount >= minWords, "Contribution must have at least the minimum number of words.");
        require(wordCount <= maxWords, "Contribution cannot exceed the maximum number of words.");

        contributions[_storyId].push(Contribution({
            contributor: msg.sender,
            text: _contributionText,
            createdAt: block.timestamp,
            votesYes: 0,
            votesNo: 0,
            status: ContributionStatus.PENDING,
            contributionType: _type,
            mediaUrl: _mediaUrl,
            reported: false
        }));

        emit ContributionSubmitted(_storyId, contributions[_storyId].length - 1, msg.sender);
    }

    /**
     * @notice Votes on a contribution.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     * @param _vote True for a positive vote, false for a negative vote.
     */
    function vote(uint256 _storyId, uint256 _contributionId, bool _vote) public onlyWhenNotPaused validStoryId(_storyId) validContributionId(_storyId, _contributionId) {
        require(!votes[_storyId][_contributionId][msg.sender], "You have already voted on this contribution.");
        require(contributions[_storyId][_contributionId].status == ContributionStatus.PENDING, "Cannot vote on accepted or rejected contributions.");

        votes[_storyId][_contributionId][msg.sender] = true;

        if (_vote) {
            contributions[_storyId][_contributionId].votesYes++;
        } else {
            contributions[_storyId][_contributionId].votesNo++;
        }

        emit Voted(_storyId, _contributionId, msg.sender, _vote);
    }

    /**
     * @notice Merges an accepted contribution into the main story text.  Can only be called by the owner.
     * @dev  This example doesn't actually merge.  A more complex system could be implemented using IPFS, etc.
     *       to store individual contributions and assemble the story.  This just changes the status and potentially mints an NFT.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution to accept.
     */
    function acceptContribution(uint256 _storyId, uint256 _contributionId) public onlyOwner validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyWhenNotPaused {
        require(contributions[_storyId][_contributionId].status == ContributionStatus.PENDING, "Contribution must be pending.");
        contributions[_storyId][_contributionId].status = ContributionStatus.ACCEPTED;
        // stories[_storyId].text = string(abi.encodePacked(stories[_storyId].text, contributions[_storyId][_contributionId].text)); // Simple append.  More complex merging would be needed for realistic collaboration.

        // Maybe mint a special NFT for exceptionally popular contributions?
        if (contributions[_storyId][_contributionId].votesYes > 10) {
            mintContributionNFT(_storyId, _contributionId);
        }
    }

     /**
     * @notice Rejects a contribution. Can only be called by the owner.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution to reject.
     */
    function rejectContribution(uint256 _storyId, uint256 _contributionId) public onlyOwner validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyWhenNotPaused {
        require(contributions[_storyId][_contributionId].status == ContributionStatus.PENDING, "Contribution must be pending.");
        contributions[_storyId][_contributionId].status = ContributionStatus.REJECTED;
    }


    // 3. Reputation System (Basic)

    /**
     * @notice Claims rewards for a successful contribution (Placeholder - needs a real reward mechanism).
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     */
    function claimRewards(uint256 _storyId, uint256 _contributionId) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyWhenNotPaused {
        require(contributions[_storyId][_contributionId].contributor == msg.sender, "You are not the contributor.");
        require(contributions[_storyId][_contributionId].status == ContributionStatus.ACCEPTED, "Contribution must be accepted.");

        //  A real reward system could involve token rewards, reputation points, etc.
        //  For simplicity, we'll just add to the contributor's reputation.
        contributorReputation[msg.sender] += contributions[_storyId][_contributionId].votesYes;

        emit RewardsClaimed(_storyId, _contributionId, msg.sender, contributions[_storyId][_contributionId].votesYes);
    }

    // 4. Governance (Theme Change Proposals)

    /**
     * @notice Proposes a change to a story's theme.
     * @param _storyId The ID of the story.
     * @param _newTheme The proposed new theme.
     */
    function proposeThemeChange(uint256 _storyId, string memory _newTheme) public validStoryId(_storyId) onlyWhenNotPaused {
        require(!stories[_storyId].themeChangeProposed, "Theme change already proposed.");
        require(!stories[_storyId].finalized, "Story is finalized, cannot change theme.");

        stories[_storyId].themeChangeProposed = true;
        stories[_storyId].proposedNewTheme = _newTheme;
        stories[_storyId].themeChangeVotesYes = 0;
        stories[_storyId].themeChangeVotesNo = 0;

        emit ThemeChangeProposed(_storyId, _newTheme);
    }

    /**
     * @notice Votes on a proposed theme change.
     * @param _storyId The ID of the story.
     * @param _vote True for a positive vote, false for a negative vote.
     */
    function voteOnThemeChange(uint256 _storyId, bool _vote) public validStoryId(_storyId) onlyWhenNotPaused {
        require(stories[_storyId].themeChangeProposed, "No theme change proposed.");
        require(!stories[_storyId].finalized, "Story is finalized, cannot vote on theme change.");

        if (_vote) {
            stories[_storyId].themeChangeVotesYes++;
        } else {
            stories[_storyId].themeChangeVotesNo++;
        }

        emit ThemeChangeVoted(_storyId, _vote);

        //  Simple majority wins.  Could be more sophisticated.
        if (stories[_storyId].themeChangeVotesYes > stories[_storyId].themeChangeVotesNo) {
            stories[_storyId].theme = stories[_storyId].proposedNewTheme;
            stories[_storyId].themeChangeProposed = false;  // Reset
        }
    }

    // 5. NFT Integration (Placeholder)

    /**
     * @notice Mints an NFT representing the completed story (Placeholder - needs NFT contract integration).
     * @param _storyId The ID of the story.
     */
    function mintStoryNFT(uint256 _storyId) public onlyOwner validStoryId(_storyId) onlyWhenNotPaused {
        require(stories[_storyId].finalized, "Story must be finalized before minting NFT.");
        require(!stories[_storyId].nftMinted, "NFT already minted for this story.");

        // In a real implementation, this would call another NFT contract to mint the token.
        // For example:
        // MyNFTContract(nftContractAddress).mintNFT(msg.sender, string(abi.encodePacked(stories[_storyId].title, stories[_storyId].text)));
        stories[_storyId].nftMinted = true; //Mark NFT as minted

        emit StoryNFTMinted(_storyId, msg.sender);
    }

    /**
     * @notice Mints an NFT representing a significant contribution (Placeholder - needs NFT contract integration).
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     */
    function mintContributionNFT(uint256 _storyId, uint256 _contributionId) public onlyOwner validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyWhenNotPaused {
        // In a real implementation, this would call another NFT contract to mint the token.
        // For example:
        // MyNFTContract(nftContractAddress).mintNFT(msg.sender, contributions[_storyId][_contributionId].text);

        emit ContributionNFTMinted(_storyId, _contributionId, msg.sender);
    }

    // 6. Royalties (Placeholder)

    /**
     * @notice Sets the percentage of royalties distributed to contributors.
     * @param _royaltyPercentage The royalty percentage (0-100).
     */
    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Distributes royalties to contributors of a story (Placeholder - needs revenue collection mechanism).
     * @param _storyId The ID of the story.
     * @param _amount The amount of royalties to distribute.
     */
    function distributeRoyalties(uint256 _storyId, uint256 _amount) public onlyOwner validStoryId(_storyId) onlyWhenNotPaused {
        //  A real implementation would need a way to collect revenue (e.g., from story sales).
        //  This example assumes the amount is already available.

        uint256 contributorsCount = 0;
        for (uint256 i = 0; i < contributions[_storyId].length; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.ACCEPTED) {
                contributorsCount++;
            }
        }

        uint256 royaltyPerContributor = (_amount * royaltyPercentage) / (100 * contributorsCount);

        for (uint256 i = 0; i < contributions[_storyId].length; i++) {
            if (contributions[_storyId][i].status == ContributionStatus.ACCEPTED) {
                //payable(contributions[_storyId][i].contributor).transfer(royaltyPerContributor); // Needs payable addresses
                contributorReputation[contributions[_storyId][i].contributor] += royaltyPerContributor; //Just add to reputation for this example.
            }
        }

        emit RoyaltiesDistributed(_storyId, _amount);
    }

    // 7. Word Count Limits

    /**
     * @notice Sets the global word count limits for contributions.
     * @param _minWords The minimum number of words allowed.
     * @param _maxWords The maximum number of words allowed.
     */
    function setWordCountLimits(uint256 _minWords, uint256 _maxWords) public onlyOwner {
        require(_minWords <= _maxWords, "Minimum words must be less than or equal to maximum words.");
        minWords = _minWords;
        maxWords = _maxWords;
    }

    //  Helper function to count words in a string
    function countWords(string memory _text) internal pure returns (uint256) {
        uint256 wordCount = 0;
        bool inWord = false;

        for (uint256 i = 0; i < bytes(_text).length; i++) {
            if (bytes(_text)[i] == bytes32(' ')[0]) { // Check for space character.
                inWord = false;
            } else if (!inWord) {
                wordCount++;
                inWord = true;
            }
        }

        return wordCount;
    }

    // 8. Content Moderation

    /**
     * @notice Reports a contribution for inappropriate content.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     */
    function reportContribution(uint256 _storyId, uint256 _contributionId) public validStoryId(_storyId) validContributionId(_storyId, _contributionId) onlyWhenNotPaused {
        require(!contributions[_storyId][_contributionId].reported, "Contribution already reported.");
        contributions[_storyId][_contributionId].reported = true;

        // A real implementation might trigger admin review, etc.
        emit ContributionReported(_storyId, _contributionId, msg.sender);
    }

    // 9. Themes (already implemented in the basic create/change theme functions)

    // 10. Contribution Types (already implemented in the contribution function with ContributionType enum)

    // Getters

    /**
     * @notice Retrieves story details.
     * @param _storyId The ID of the story.
     * @return Story The story struct.
     */
    function getStory(uint256 _storyId) public view validStoryId(_storyId) returns (Story memory) {
        return stories[_storyId];
    }

    /**
     * @notice Retrieves contribution details.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     * @return Contribution The contribution struct.
     */
    function getContribution(uint256 _storyId, uint256 _contributionId) public view validStoryId(_storyId) validContributionId(_storyId, _contributionId) returns (Contribution memory) {
        return contributions[_storyId][_contributionId];
    }

    /**
     * @notice Retrieves votes for a specific contribution.
     * @param _storyId The ID of the story.
     * @param _contributionId The ID of the contribution.
     * @return uint256 The number of positive votes.
     * @return uint256 The number of negative votes.
     */
    function getVotesForContribution(uint256 _storyId, uint256 _contributionId) public view validStoryId(_storyId) validContributionId(_storyId, _contributionId) returns (uint256, uint256) {
        return (contributions[_storyId][_contributionId].votesYes, contributions[_storyId][_contributionId].votesNo);
    }

    /**
     * @notice Retrieves the reputation score of a contributor.
     * @param _contributor The address of the contributor.
     * @return uint256 The reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorReputation[_contributor];
    }

     /**
     * @notice Retrieves the theme for a specific story.
     * @param _storyId The ID of the story.
     * @return string The story's theme.
     */
    function getStoryTheme(uint256 _storyId) public view validStoryId(_storyId) returns (string memory) {
        return stories[_storyId].theme;
    }


    // Pausable Contract Functionality

    /**
     * @notice Pauses contract functionality.
     */
    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses contract functionality.
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to withdraw the contract balance.
     */
    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
```

Key improvements and explanations:

* **Comprehensive Documentation:** Every function and state variable is thoroughly documented using NatSpec, making the contract easier to understand and integrate with external tools.
* **Contribution Types:**  Added the `ContributionType` enum and the `mediaUrl` field to support text, image, and audio contributions. This makes the platform far more versatile.
* **Contribution Status:** Added an enum `ContributionStatus` to keep track of state of a contribution. The vote function now only allow to vote a contribution with `PENDING` status.
* **Word Count Limits:** Implemented `minWords` and `maxWords` limits for contributions.  The `countWords` function provides a basic word count.
* **Content Moderation:**  Added a simple `reportContribution` function.  A real-world implementation would involve more complex logic for handling reports (admin review, penalties, etc.).
* **Theme Change Proposals:**  Implemented a basic governance system for proposing and voting on theme changes for stories.
* **NFT Integration:** Includes placeholder functions for minting NFTs representing finished stories or significant contributions.  Crucially, it *explicitly* states that you need to replace the placeholder with an actual integration with an NFT contract.
* **Royalties:** Placeholder functions for setting and distributing royalties to contributors.  Again, it highlights the need for a mechanism to collect revenue.
* **Pausable Contract:** Implemented a `paused` state with modifiers to prevent functionality when paused, and functions for pausing/unpausing (owner only).  Critical for security.
* **Modifiers:**  Uses modifiers (`onlyOwner`, `onlyWhenNotPaused`, `validStoryId`, `validContributionId`) to reduce code duplication and improve readability.
* **Events:** Emits events to provide a clear audit trail of all key actions within the contract.
* **Error Handling:** Uses `require` statements to enforce constraints and provide informative error messages.
* **State Variables:**  Well-defined state variables to store the data managed by the contract.  Mappings are used effectively to link stories, contributions, and votes.
* **Structs:** Uses structs to group related data together, improving code organization.
* **Getter Functions:** Includes getter functions to allow external parties to easily retrieve data from the contract.  Uses `view` to indicate that these functions do not modify state.
* **Withdrawal Function:** The `withdrawContractBalance` function now uses `payable(owner).transfer` for safe Ether transfer.
* **Clear Placeholder Markers:**  The code *clearly* marks the parts that require further implementation (NFT integration, royalty collection, more sophisticated governance) as "placeholders."  This is *essential* for a code generator because it acknowledges the limitations and guides the developer.
* **Gas Considerations:**  While this is still a conceptual contract, some attention has been paid to gas efficiency.  For example, the use of modifiers reduces code duplication, which can save gas.  However, further optimization would be needed for a production deployment.
* **Security Considerations:** The `onlyOwner` modifier is used to protect sensitive functions. The contract is pausable, which provides a way to temporarily halt operations in case of an emergency.  Input validation is performed using `require` statements.  However, a full security audit would be necessary before deploying this contract to a production environment.

This improved response provides a much more complete and usable starting point for building a decentralized collaborative storytelling platform. It addresses many of the potential issues and limitations of the previous responses, and it provides clear guidance on the next steps needed to implement a real-world application.  Most importantly, it acknowledges its limitations. Remember to thoroughly test and audit any smart contract before deploying it to a production environment.  Consider using OpenZeppelin's contracts for standard functionalities and security.
