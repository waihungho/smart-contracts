Okay, here is a smart contract concept combining Decentralized Content Syndication, Curator Staking, Reputation, and Dynamic Access Control based on reputation. This is more complex than standard ERC-20/721/1155 or basic marketplaces/DAOs.

**Concept:** Decentralized Content Syndicator with Curator Staking and Reputation-Based Access.
*   **Creators:** Publish content metadata (like IPFS hashes).
*   **Curators:** Stake tokens to become active curators. They can then "syndicate" (endorse, feature) content they find valuable.
*   **Reputation:** Users (creators and curators) earn reputation scores based on successful actions (publishing content that gets syndicated, syndicating content that is viewed/accessed).
*   **Rewards:** Curators earn rewards based on their stake amount and the duration they are actively staked. Future versions could link rewards to syndication success (e.g., content view counts, though that's hard on-chain without oracles).
*   **Dynamic Access:** Creators can mark content as "gated," requiring users to have a minimum reputation score to view the actual content hash.

---

**Outline:**

1.  **License & Pragma**
2.  **Enums & Structs:** Define Content Status, Content Struct, Curator Info Struct, Syndication Info Struct.
3.  **State Variables:** Mappings for content, user reputation, curator info, curator stakes, active syndications, parameters, counters. Owner address.
4.  **Events:** Track key actions like content publishing, syndication, staking, reputation updates, rewards, parameter changes, gating.
5.  **Modifiers:** Define access control modifiers (only owner, only creator, only curator, content existence, active curator).
6.  **Core Logic:**
    *   **Constructor:** Initialize contract owner and initial parameters.
    *   **Content Management:** Functions for creators to publish, update, and manage their content. Functions for viewing content details.
    *   **Curator Staking & Management:** Functions for users to stake, become active curators, withdraw stakes.
    *   **Content Syndication:** Functions for active curators to syndicate and unsyndicate content.
    *   **Reputation System:** Internal and external functions to update and query user reputation. Reputation is gained through successful actions.
    *   **Reward System:** Functions for curators to claim accumulated staking rewards.
    *   **Dynamic Access Control (Gating):** Functions for creators/owner to gate content and set reputation requirements. Function to check access and retrieve gated content hash.
    *   **Parameter Management:** Owner-only functions to adjust key system parameters.
    *   **View/Utility Functions:** Functions to query contract state, parameters, counts, etc.

---

**Function Summary:**

*   `constructor()`: Initializes the contract with the owner and default parameters.
*   `publishContent(string title, string description, string ipfsHash)`: Allows a creator to publish new content. Assigns unique ID.
*   `updateContent(uint256 contentId, string newTitle, string newDescription, string newIpfsHash)`: Allows the creator to update content details (if not currently syndicated).
*   `archiveContent(uint256 contentId)`: Allows the creator or owner to archive content, making it inactive.
*   `stakeAsCurator()`: Allows a user to stake the required amount of ETH to become an active curator.
*   `withdrawCuratorStake()`: Allows an active curator to withdraw their stake and claim pending rewards (must unsyndicate all content first).
*   `syndicateContent(uint256 contentId)`: Allows an active curator to syndicate published content. Records the start time of the syndication.
*   `unsyndicateContent(uint256 contentId)`: Allows a curator to stop syndicating content they previously syndicated. Updates syndication state.
*   `claimRewards()`: Allows an active curator to claim accrued staking rewards.
*   `gateContent(uint256 contentId, uint256 minReputationRequired)`: Allows the content creator or owner to mark content as gated, requiring a minimum reputation to view the hash.
*   `ungateContent(uint256 contentId)`: Allows the content creator or owner to remove gating from content.
*   `updateReputation(address user, uint256 amount)`: Internal function to increase a user's reputation score. (Could be triggered by specific events like successful syndication duration or content views via oracle).
*   `setCuratorStakeAmount(uint256 amount)`: Owner-only function to set the required ETH stake for curators.
*   `setReputationIncreaseRate(uint256 rate)`: Owner-only function to set the base reputation increase rate per successful action (simplified model).
*   `setRewardRatePerStakeUnitPerTime(uint256 rate)`: Owner-only function to set the reward rate for staked curators (e.g., wei per staked unit per second).
*   `getContent(uint256 contentId)`: View function to retrieve content metadata (excluding IPFS hash if gated and access is denied).
*   `getCuratorInfo(address curator)`: View function to retrieve a curator's staking status and details.
*   `getReputation(address user)`: View function to retrieve a user's current reputation score.
*   `getAccruedRewards(address curator)`: View function to calculate (but not claim) a curator's currently accrued rewards.
*   `isContentSyndicatedByCurator(uint256 contentId, address curator)`: View function to check if a specific curator is currently syndicating specific content.
*   `isCuratorActive(address curator)`: View function to check if a user is currently an active, staked curator.
*   `canAccessContent(uint256 contentId, address user)`: View function to check if a user meets the reputation requirement for gated content.
*   `viewContentHash(uint256 contentId)`: View function to retrieve the content's IPFS hash. Applies gating logic: only returns the hash if the content is not gated or the user meets the reputation requirement.
*   `getTotalContentCount()`: View function returning the total number of content items published.
*   `getCuratorStakeAmount()`: View function returning the currently required curator stake amount.
*   `getRewardRatePerStakeUnitPerTime()`: View function returning the current staking reward rate.
*   `getContentStatus(uint256 contentId)`: View function returning the status of a content item.
*   `isContentGated(uint256 contentId)`: View function checking if content is marked as gated.
*   `getMinReputationRequired(uint256 contentId)`: View function returning the minimum reputation needed for gated content access.
*   `getSyndicationStartTime(uint256 contentId, address curator)`: View function returning the timestamp when a curator started syndicating content.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License & Pragma
// 2. Enums & Structs: ContentStatus, ContentItem, CuratorInfo, SyndicationInfo.
// 3. State Variables: Mappings for content, reputation, curators, stakes, syndications, params. Counters. Owner.
// 4. Events: ContentPublished, ContentUpdated, ContentArchived, CuratorStaked, CuratorStakeWithdrawn,
//            ContentSyndicated, ContentUnsyndicated, ReputationUpdated, RewardsClaimed, ParametersUpdated,
//            ContentGated, ContentAccessUpdated.
// 5. Modifiers: onlyOwner, onlyCreator, onlyCurator, contentExists, isActiveCurator.
// 6. Core Logic:
//    - Constructor
//    - Content Management (Publish, Update, Archive, Getters)
//    - Curator Staking & Management (Stake, Withdraw, Getters)
//    - Content Syndication (Syndicate, Unsyndicate, Checkers)
//    - Reputation System (Internal Update, Getter)
//    - Reward System (Claim, Accrued Getter)
//    - Dynamic Access Control (Gate, Ungate, Access Check, Gated View)
//    - Parameter Management (Setters)
//    - View/Utility Functions (Counts, Statuses, Parameters)

// Function Summary:
// constructor() - Initializes owner and parameters.
// publishContent(string title, string description, string ipfsHash) - Creator publishes content.
// updateContent(uint256 contentId, string newTitle, string newDescription, string newIpfsHash) - Creator updates content if not syndicated.
// archiveContent(uint256 contentId) - Creator/Owner archives content.
// stakeAsCurator() - User stakes ETH to become a curator.
// withdrawCuratorStake() - Curator withdraws stake and claims rewards (must unsyndicate all content).
// syndicateContent(uint256 contentId) - Active curator syndicates content.
// unsyndicateContent(uint256 contentId) - Curator stops syndicating content.
// claimRewards() - Curator claims accrued staking rewards.
// gateContent(uint256 contentId, uint256 minReputationRequired) - Creator/Owner gates content, sets min reputation.
// ungateContent(uint256 contentId) - Creator/Owner ungates content.
// updateReputation(address user, uint256 amount) - Internal/Triggered reputation update.
// setCuratorStakeAmount(uint256 amount) - Owner sets curator stake amount.
// setReputationIncreaseRate(uint256 rate) - Owner sets reputation increase rate.
// setRewardRatePerStakeUnitPerTime(uint256 rate) - Owner sets staking reward rate.
// getContent(uint256 contentId) - Get basic content info (excluding potentially gated hash).
// getCuratorInfo(address curator) - Get curator staking info.
// getReputation(address user) - Get user's reputation score.
// getAccruedRewards(address curator) - Calculate a curator's currently accrued rewards.
// isContentSyndicatedByCurator(uint256 contentId, address curator) - Check if a curator syndicates content.
// isCuratorActive(address curator) - Check if a user is an active curator.
// canAccessContent(uint256 contentId, address user) - Check if user meets gating requirement.
// viewContentHash(uint256 contentId) - Get IPFS hash, applying gating access control.
// getTotalContentCount() - Get total published content count.
// getCuratorStakeAmount() - Get required curator stake amount.
// getRewardRatePerStakeUnitPerTime() - Get current staking reward rate.
// getContentStatus(uint256 contentId) - Get content status.
// isContentGated(uint256 contentId) - Check if content is gated.
// getMinReputationRequired(uint256 contentId) - Get min reputation for gated content.
// getSyndicationStartTime(uint256 contentId, address curator) - Get syndication start time for pair.

contract DecentralizedContentSyndicator {

    address public owner;

    enum ContentStatus { Draft, Published, Archived }

    struct ContentItem {
        uint256 id;
        address creator;
        string title;
        string description;
        string ipfsHash; // Link to content data
        ContentStatus status;
        uint64 publishTimestamp;
        bool isGated;
        uint256 minReputationRequired;
    }

    struct CuratorInfo {
        uint256 stakeAmount;
        bool isActive;
        uint64 stakeStartTime;
        uint64 lastRewardClaimTime;
    }

    // Tracks which curator is syndicating which content and when they started
    mapping(address => mapping(uint256 => uint64)) public syndicationStartTime; // curatorAddress => contentId => startTimestamp (0 if not syndicating)

    mapping(uint256 => ContentItem) public contentItems;
    uint256 private _contentCounter;

    mapping(address => uint256) public userReputation; // user address => reputation score

    mapping(address => CuratorInfo) public curatorInfo;
    mapping(address => uint256) public curatorStakes; // Tracks actual staked balance

    uint256 public curatorStakeAmount; // Required ETH to stake as curator
    uint256 public reputationIncreaseRate; // Base amount reputation increases per relevant action
    uint224 public rewardRatePerStakeUnitPerTime; // Wei per wei staked per second

    event ContentPublished(uint256 indexed contentId, address indexed creator, string title, uint64 timestamp);
    event ContentUpdated(uint256 indexed contentId, address indexed creator, uint64 timestamp);
    event ContentArchived(uint256 indexed contentId, address indexed user, uint64 timestamp);
    event CuratorStaked(address indexed curator, uint256 amount, uint64 timestamp);
    event CuratorStakeWithdrawn(address indexed curator, uint256 returnedAmount, uint256 rewardsClaimed, uint64 timestamp);
    event ContentSyndicated(uint256 indexed contentId, address indexed curator, uint64 timestamp);
    event ContentUnsyndicated(uint256 indexed contentId, address indexed curator, uint64 timestamp);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event RewardsClaimed(address indexed curator, uint256 amount, uint64 timestamp);
    event ParametersUpdated(address indexed updater, uint256 newStakeAmount, uint256 newReputationRate, uint256 newRewardRate);
    event ContentGated(uint256 indexed contentId, uint256 indexed minReputationRequired, uint64 timestamp);
    event ContentAccessUpdated(uint256 indexed contentId, bool isGated, uint256 minReputation);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyCreator(uint256 contentId) {
        require(contentItems[contentId].creator == msg.sender, "Only content creator");
        _;
    }

    modifier contentExists(uint256 contentId) {
        require(contentItems[contentId].creator != address(0), "Content does not exist"); // creator != address(0) implies content exists
        _;
    }

    modifier isActiveCurator(address _curator) {
        require(curatorInfo[_curator].isActive, "Not an active curator");
        _;
    }

    constructor() {
        owner = msg.sender;
        _contentCounter = 0;
        curatorStakeAmount = 1 ether; // Example default: 1 ETH stake
        reputationIncreaseRate = 10; // Example default increase
        rewardRatePerStakeUnitPerTime = 1; // Example default: 1 wei per wei staked per second
        emit ParametersUpdated(owner, curatorStakeAmount, reputationIncreaseRate, rewardRatePerStakeUnitPerTime);
    }

    // --- Content Management ---

    function publishContent(string calldata title, string calldata description, string calldata ipfsHash) external {
        _contentCounter++;
        uint256 contentId = _contentCounter;

        contentItems[contentId] = ContentItem({
            id: contentId,
            creator: msg.sender,
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            status: ContentStatus.Published,
            publishTimestamp: uint64(block.timestamp),
            isGated: false,
            minReputationRequired: 0
        });

        // Optionally increase creator reputation upon successful publish
        // _updateReputation(msg.sender, reputationIncreaseRate);

        emit ContentPublished(contentId, msg.sender, title, uint64(block.timestamp));
    }

    function updateContent(uint256 contentId, string calldata newTitle, string calldata newDescription, string calldata newIpfsHash)
        external
        contentExists(contentId)
        onlyCreator(contentId)
    {
        // Prevent updates if content is currently syndicated by ANY curator (simplification)
        // A more complex version could allow updates if *this specific* curator isn't syndicating, or notify syndicators.
        require(!_isContentSyndicatedByAny(contentId), "Content is currently syndicated and cannot be updated");

        ContentItem storage content = contentItems[contentId];
        content.title = newTitle;
        content.description = newDescription;
        content.ipfsHash = newIpfsHash;

        emit ContentUpdated(contentId, msg.sender, uint64(block.timestamp));
    }

    function archiveContent(uint256 contentId)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner");
        require(contentItems[contentId].status != ContentStatus.Archived, "Content already archived");

        contentItems[contentId].status = ContentStatus.Archived;

        // Unsyndicate by all active curators if archived
        _unsyndicateContentForAllCurators(contentId); // Internal helper handles this

        emit ContentArchived(contentId, msg.sender, uint64(block.timestamp));
    }

    // --- Curator Staking & Management ---

    function stakeAsCurator() external payable {
        require(!curatorInfo[msg.sender].isActive, "Already an active curator");
        require(msg.value >= curatorStakeAmount, "Must send required stake amount");

        curatorInfo[msg.sender] = CuratorInfo({
            stakeAmount: msg.value,
            isActive: true,
            stakeStartTime: uint64(block.timestamp),
            lastRewardClaimTime: uint64(block.timestamp)
        });
        curatorStakes[msg.sender] = msg.value; // Track staked balance explicitly

        // Refund excess ETH if sent more than required
        if (msg.value > curatorStakeAmount) {
            payable(msg.sender).transfer(msg.value - curatorStakeAmount);
        }

        emit CuratorStaked(msg.sender, curatorInfo[msg.sender].stakeAmount, uint64(block.timestamp));
    }

    function withdrawCuratorStake() external isActiveCurator(msg.sender) {
        require(!_isCuratorSyndicatingAny(msg.sender), "Must unsyndicate all content before withdrawing stake");

        CuratorInfo storage info = curatorInfo[msg.sender];
        uint256 stakedAmount = curatorStakes[msg.sender]; // Use tracked balance

        // Calculate and claim any accrued rewards before withdrawing principal
        uint256 rewards = _calculateRewards(msg.sender);
        uint256 totalPayout = stakedAmount + rewards;

        info.isActive = false;
        info.stakeAmount = 0; // Reset stake amount in info struct
        info.lastRewardClaimTime = uint64(block.timestamp); // Update timestamp
        curatorStakes[msg.sender] = 0; // Clear staked balance

        // Transfer stake + rewards
        payable(msg.sender).transfer(totalPayout);

        emit RewardsClaimed(msg.sender, rewards, uint64(block.timestamp)); // Emit reward event too
        emit CuratorStakeWithdrawn(msg.sender, stakedAmount, rewards, uint64(block.timestamp));
    }

    // --- Content Syndication ---

    function syndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(contentItems[contentId].status == ContentStatus.Published, "Content is not published");
        require(syndicationStartTime[msg.sender][contentId] == 0, "Content already syndicated by this curator");

        syndicationStartTime[msg.sender][contentId] = uint64(block.timestamp);

        // Optionally update creator reputation when their content gets syndicated
        // _updateReputation(contentItems[contentId].creator, reputationIncreaseRate);
        // Optionally update curator reputation for syndicating content
        // _updateReputation(msg.sender, reputationIncreaseRate / 2); // Less than creator rep increase?

        emit ContentSyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    function unsyndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(syndicationStartTime[msg.sender][contentId] > 0, "Content not currently syndicated by this curator");

        // Reset syndication start time
        syndicationStartTime[msg.sender][contentId] = 0;

        // No rewards accrued specifically for syndication duration in this model.
        // Reputation updates could happen here based on *how long* it was syndicated,
        // but that's complex to track and attribute on-chain. Keeping it simple.

        emit ContentUnsyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    // --- Reputation System ---

    // Internal function to update reputation
    function _updateReputation(address user, uint256 amount) internal {
        userReputation[user] += amount;
        emit ReputationUpdated(user, userReputation[user]);
    }

    // Note: A more advanced reputation system could involve:
    // - Decay over time
    // - Votes/endorsements from other high-reputation users
    // - Oracle integration for off-chain engagement signals (views, shares, likes)

    // --- Reward System ---

    // Internal helper to calculate rewards
    function _calculateRewards(address curator) internal view returns (uint256) {
        CuratorInfo storage info = curatorInfo[curator];
        if (!info.isActive) {
             // Cannot calculate rewards for inactive curator, should be claimed/calculated upon deactivation
             return 0;
        }
        uint256 stakedAmount = curatorStakes[curator]; // Use tracked balance
        uint64 timeStaked = uint64(block.timestamp) - info.lastRewardClaimTime;

        // Reward = stake amount * rate per stake unit per second * time staked
        // Using uint224 for rate to potentially fit within 256 bits calculation without overflow for reasonable values
        // Assumes stakedAmount is in wei, rate is wei/wei/sec, timeStaked is in seconds
        // Potential for precision loss if rate is very small. Consider fixed-point math or different units.
        // This is a simplified calculation.
        uint256 rewards = (stakedAmount * rewardRatePerStakeUnitPerTime * timeStaked);

        return rewards;
    }

    function claimRewards() external isActiveCurator(msg.sender) {
        uint256 rewards = _calculateRewards(msg.sender);
        require(rewards > 0, "No rewards accrued");

        curatorInfo[msg.sender].lastRewardClaimTime = uint64(block.timestamp); // Update timestamp before transfer

        payable(msg.sender).transfer(rewards);

        emit RewardsClaimed(msg.sender, rewards, uint64(block.timestamp));
    }

    // --- Dynamic Access Control (Gating) ---

    function gateContent(uint256 contentId, uint256 minReputationRequired)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner can gate");
        require(contentItems[contentId].status == ContentStatus.Published, "Only published content can be gated");
        require(minReputationRequired >= 0, "Min reputation cannot be negative"); // Solidity uint handles this, but good practice

        ContentItem storage content = contentItems[contentId];
        content.isGated = true;
        content.minReputationRequired = minReputationRequired;

        emit ContentGated(contentId, minReputationRequired, uint64(block.timestamp));
        emit ContentAccessUpdated(contentId, true, minReputationRequired);
    }

    function ungateContent(uint256 contentId)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner can ungate");
        require(contentItems[contentId].isGated, "Content is not currently gated");

        ContentItem storage content = contentItems[contentId];
        content.isGated = false;
        content.minReputationRequired = 0; // Reset required reputation

        emit ContentAccessUpdated(contentId, false, 0);
    }

    function canAccessContent(uint256 contentId, address user) public view contentExists(contentId) returns (bool) {
        ContentItem storage content = contentItems[contentId];
        if (!content.isGated) {
            return true; // Not gated, access granted
        }
        // Check if user's reputation meets or exceeds the minimum required
        return userReputation[user] >= content.minReputationRequired;
    }

    // This is the function users call to get the actual content link, subject to gating
    function viewContentHash(uint256 contentId) external view contentExists(contentId) returns (string memory) {
        require(canAccessContent(contentId, msg.sender), "Insufficient reputation to access this content");
        return contentItems[contentId].ipfsHash;
    }

    // --- Parameter Management ---

    function setCuratorStakeAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Stake amount must be greater than 0");
        // Note: Changing this value only affects *new* stakers. Existing curators
        // remain staked with their original amount. Need logic for upgrade/migration
        // if existing stakes need to match the new minimum. (Out of scope for this example)
        curatorStakeAmount = amount;
        emit ParametersUpdated(msg.sender, curatorStakeAmount, reputationIncreaseRate, rewardRatePerStakeUnitPerTime);
    }

    function setReputationIncreaseRate(uint256 rate) external onlyOwner {
        reputationIncreaseRate = rate;
        emit ParametersUpdated(msg.sender, curatorStakeAmount, reputationIncreaseRate, rewardRatePerStakeUnitPerTime);
    }

    function setRewardRatePerStakeUnitPerTime(uint224 rate) external onlyOwner {
         // Be careful with the units and potential overflow/underflow here.
         // This rate assumes wei per wei staked per second.
        rewardRatePerStakeUnitPerTime = rate;
        emit ParametersUpdated(msg.sender, curatorStakeAmount, reputationIncreaseRate, rewardRatePerStakeUnitPerTime);
    }


    // --- View / Utility Functions (Total: 31 functions including constructor) ---

    function getContent(uint256 contentId)
        external
        view
        contentExists(contentId)
        returns (uint256 id, address creator, string memory title, string memory description, ContentStatus status, uint64 publishTimestamp)
    {
         ContentItem storage item = contentItems[contentId];
         // Note: IPFS hash is excluded here to force users to use viewContentHash for gated content checks
         return (item.id, item.creator, item.title, item.description, item.status, item.publishTimestamp);
    }

    function getCuratorInfo(address curator)
        external
        view
        returns (uint256 stakeAmount, bool isActive, uint64 stakeStartTime, uint64 lastRewardClaimTime)
    {
        CuratorInfo storage info = curatorInfo[curator];
        return (info.stakeAmount, info.isActive, info.stakeStartTime, info.lastRewardClaimTime);
    }

    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    function getAccruedRewards(address curator) external view isActiveCurator(curator) returns (uint256) {
        return _calculateRewards(curator);
    }

    function isContentSyndicatedByCurator(uint256 contentId, address curator) external view contentExists(contentId) returns (bool) {
        return syndicationStartTime[curator][contentId] > 0;
    }

    function isCuratorActive(address curator) external view returns (bool) {
        return curatorInfo[curator].isActive;
    }

    function getTotalContentCount() external view returns (uint256) {
        return _contentCounter;
    }

    function getCuratorStakeAmount() external view returns (uint256) {
        return curatorStakeAmount;
    }

    function getRewardRatePerStakeUnitPerTime() external view returns (uint224) {
        return rewardRatePerStakeUnitPerTime;
    }

    function getContentStatus(uint256 contentId) external view contentExists(contentId) returns (ContentStatus) {
        return contentItems[contentId].status;
    }

     function isContentGated(uint256 contentId) external view contentExists(contentId) returns (bool) {
        return contentItems[contentId].isGated;
    }

    function getMinReputationRequired(uint256 contentId) external view contentExists(contentId) returns (uint256) {
        return contentItems[contentId].minReputationRequired;
    }

    function getSyndicationStartTime(uint256 contentId, address curator) external view contentExists(contentId) returns (uint64) {
        // Returns 0 if the curator is not syndicating this content
        return syndicationStartTime[curator][contentId];
    }

    // --- Internal Helpers ---

    // Checks if content is syndicated by *any* curator (requires iterating active curators, which is inefficient)
    // A better approach for production would be to maintain a list/mapping of curators per content item,
    // or rely on off-chain indexing to check this efficiently.
    // For this example, we'll use a simple check that might be gas-intensive with many curators/syndications.
    // Alternative simpler check (implemented): Just check if *any* syndication start time > 0 for this content across known curators. Still bad.
    // Let's refine: The simple check assumes we *know* all curators. A true decentralized system can't easily iterate all stakers or all syndications on-chain.
    // A pragmatic approach for `updateContent` check is to only allow updates if `msg.sender` curator isn't syndicating it, or rely on off-chain state.
    // Let's revert the updateContent check to only check if *that specific creator* is syndicating (which shouldn't happen) or simplify the rule.
    // Okay, let's add a mapping to track if *any* curator is syndicating a piece of content for simpler checks.
    mapping(uint256 => bool) private _isSyndicatedByAnyCurator;

    // Update syndicateContent and unsyndicateContent to manage _isSyndicatedByAnyCurator
    function syndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(contentItems[contentId].status == ContentStatus.Published, "Content is not published");
        require(syndicationStartTime[msg.sender][contentId] == 0, "Content already syndicated by this curator");

        syndicationStartTime[msg.sender][contentId] = uint64(block.timestamp);
        _isSyndicatedByAnyCurator[contentId] = true; // Mark content as syndicated by at least one curator

        emit ContentSyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    function unsyndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(syndicationStartTime[msg.sender][contentId] > 0, "Content not currently syndicated by this curator");

        syndicationStartTime[msg.sender][contentId] = 0;

        // Check if ANY other curator is still syndicating this content. This still requires iteration,
        // or maintaining a counter per content item. Let's add a counter.
        mapping(uint256 => uint256) private _syndicationCount; // contentId => number of curators syndicating it

        // Update publishContent:
        // _syndicationCount[_contentCounter] = 0;

        // Update syndicateContent:
        // _syndicationCount[contentId]++;
        // _isSyndicatedByAnyCurator[contentId] = _syndicationCount[contentId] > 0; // Ensure consistency

        // Update unsyndicateContent:
        // _syndicationCount[contentId]--;
        // _isSyndicatedByAnyCurator[contentId] = _syndicationCount[contentId] > 0; // Update based on count

        // Let's implement the counter. Need to add to struct or state variables.
        // Adding to struct makes it part of contentItems.
        // struct ContentItem { ... uint256 syndicationCount; }
        // Need to update publishContent, syndicateContent, unsyndicateContent, archiveContent accordingly.

        // Let's stick to the simpler `_isSyndicatedByAnyCurator` boolean for now, and acknowledge the limitation.
        // Checking if there are *other* curators still syndicating to reset `_isSyndicatedByAnyCurator` is complex/costly.
        // A simple approach: `_isSyndicatedByAnyCurator` remains true once *any* curator syndicates, until the content is archived or explicitly cleared by owner/governance.
        // This simplifies the `updateContent` check: `require(!_isSyndicatedByAnyCurator[contentId], "Content has been syndicated");`

        emit ContentUnsyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    // Helper to check if content is syndicated by *any* curator (using the simplified boolean flag)
    function _isContentSyndicatedByAny(uint256 contentId) internal view returns (bool) {
        return _isSyndicatedByAnyCurator[contentId];
    }

     // Helper to check if a specific curator is syndicating any content (requires iteration, inefficient)
     // A better approach would be to maintain a list/mapping of contentIds per curator.
     // For this example, we omit functions that require iterating over large unknown collections.
     // The `withdrawCuratorStake` check `_isCuratorSyndicatingAny` needs a fix or simplification.
     // Option 1: Keep a list per curator. `mapping(address => uint256[]) activeSyndicatedContentIds;` - array push/pop costly.
     // Option 2: Track count per curator. `mapping(address => uint256) curatorActiveSyndicationCount;`
     // Let's implement the count. Need to update syndicateContent, unsyndicateContent, archiveContent.
     mapping(address => uint256) private _curatorActiveSyndicationCount;

     // Update syndicateContent:
     // _curatorActiveSyndicationCount[msg.sender]++;

     // Update unsyndicateContent:
     // _curatorActiveSyndicationCount[msg.sender]--;

     // Update withdrawCuratorStake:
     // require(_curatorActiveSyndicationCount[msg.sender] == 0, "Must unsyndicate all content before withdrawing stake");

     function _isCuratorSyndicatingAny(address curator) internal view returns (bool) {
         return _curatorActiveSyndicationCount[curator] > 0;
     }

     // Helper to unsyndicate content for all curators (needed for archive).
     // This requires iterating over potentially many syndications. Very gas intensive.
     // A better approach would be an off-chain process to find all syndicators and call `unsyndicateContent` individually,
     // or rely on the `syndicationStartTime` mapping lookup becoming zero when the content is archived/invalidated.
     // Let's add a simple placeholder function but note its inefficiency or rely on off-chain cleanup.
     // A more practical on-chain approach: when content is archived, simply checking `contentItems[contentId].status != ContentStatus.Published` in `viewContentHash` and `syndicateContent` implicitly invalidates active syndications for that content, without needing to explicitly iterate and update `syndicationStartTime` for everyone. The `syndicationStartTime` remains recorded but becomes irrelevant for active status.
     // This is simpler and more gas-efficient. The `_isContentSyndicatedByAnyCurator` flag might become less useful then.

     // Let's adjust: `updateContent` cannot happen if content is *published*. Archiving changes status to Archived. Unsyndication just removes the link for a specific curator.
     // `updateContent`: require(contentItems[contentId].status != ContentStatus.Published, "Content status must not be Published to update"); // Allow draft/archived updates? Or specific updates only? Let's allow updates only if archived or if creator/owner has special permission. Keep it simple: No updates if Published. Creator can archive and then publish new version.

     // Revisit `archiveContent`: It sets status to Archived. This implicitly invalidates syndication. No need for `_unsyndicateContentForAllCurators`.
     // The `_isSyndicatedByAnyCurator` flag is still useful for the `updateContent` check.

     // Final approach for `updateContent` check: `require(syndicationStartTime[msg.sender][contentId] == 0, "Cannot update content currently syndicated by you");` - this is creator trying to update. But what if *another* curator is syndicating?
     // A robust system needs a way to prevent updates while *any* curator is syndicating.
     // The `_isSyndicatedByAnyCurator` flag is the simplest approach, but setting it back to false is hard.
     // Let's assume for this example that once syndicated, the content can only be archived by creator/owner, not updated.

     // Final plan for internal helpers and checks:
     // - `_isCuratorSyndicatingAny`: Use the `_curatorActiveSyndicationCount`. Update count in `syndicateContent`, `unsyndicateContent`, and `archiveContent` (when a curator's syndication is invalidated by archiving). Need to iterate curator's active syndications on archive... this is the expensive part.
     // - Let's simplify: `archiveContent` just sets status. Active syndications for that content become ineffective because `viewContentHash` requires status == Published. `withdrawCuratorStake` requires `_curatorActiveSyndicationCount[msg.sender] == 0`. A curator *must* manually unsyndicate *all* their content *before* withdrawing stake. This pushes the iteration cost off-chain or to the user. This is a common pattern.

     // So, the state variables and functions seem mostly fine with this last simplification.
     // Add _curatorActiveSyndicationCount and update it.

     // Let's re-read the 20+ function requirement and summary. Everything looks good.

     // Add _curatorActiveSyndicationCount:
     // mapping(address => uint256) private _curatorActiveSyndicationCount; // curatorAddress => count of content items they are actively syndicating

     // Update constructor:
     // _curatorActiveSyndicationCount is initialized to 0 by default for all addresses.

     // Update syndicateContent:
     // _curatorActiveSyndicationCount[msg.sender]++;
     // _isSyndicatedByAnyCurator[contentId] = true; // Content is now syndicated by at least one

     // Update unsyndicateContent:
     // _curatorActiveSyndicationCount[msg.sender]--;
     // Need to potentially update _isSyndicatedByAnyCurator[contentId] if _syndicationCount drops to 0...
     // This requires knowing the total syndication count for this content, which isn't stored.
     // Let's remove _isSyndicatedByAnyCurator and rely on the check `isContentSyndicatedByCurator` for specific curator checks
     // and accept that preventing *any* update while *any* curator syndicates is hard/expensive on-chain without iteration.
     // The update rule will be: `require(syndicationStartTime[msg.sender][contentId] == 0, "Cannot update content while you are syndicating it");` - This is a weaker but gas-efficient rule.

     // Let's commit to the simpler rule: Creator *cannot* update content if *they* are currently syndicating it.
     // This doesn't prevent another curator from syndicating. This is a design choice/limitation for on-chain efficiency.

     // Final check on function list count and complexity:
     // 1. constructor
     // 2. publishContent
     // 3. updateContent
     // 4. archiveContent
     // 5. stakeAsCurator
     // 6. withdrawCuratorStake
     // 7. syndicateContent
     // 8. unsyndicateContent
     // 9. claimRewards
     // 10. gateContent
     // 11. ungateContent
     // 12. updateReputation (internal, could add public trigger later) - Let's make it internal for now.
     // 13. setCuratorStakeAmount
     // 14. setReputationIncreaseRate
     // 15. setRewardRatePerStakeUnitPerTime
     // 16. getContent
     // 17. getCuratorInfo
     // 18. getReputation
     // 19. getAccruedRewards
     // 20. isContentSyndicatedByCurator
     // 21. isCuratorActive
     // 22. canAccessContent
     // 23. viewContentHash
     // 24. getTotalContentCount
     // 25. getCuratorStakeAmount (getter for parameter) - duplicate name, let's rename the state var `_curatorStakeAmount`.
     // 26. getRewardRatePerStakeUnitPerTime (getter for parameter) - duplicate name, rename state var `_rewardRatePerStakeUnitPerTime`.
     // 27. getContentStatus
     // 28. isContentGated
     // 29. getMinReputationRequired
     // 30. getSyndicationStartTime

     // Renaming parameters for clarity as state variables:
     uint256 public _curatorStakeAmount;
     uint256 public _reputationIncreaseRate;
     uint224 public _rewardRatePerStakeUnitPerTime;

     // Update constructor, setters, and getters to use the new names.

     // Let's also add a function to retrieve the creator's address for content.
     // 31. getCreator(uint256 contentId) - already part of getContent, but could be separate. Let's add for function count.

     // Let's add a function to check if content exists explicitly.
     // 32. contentExists(uint256 contentId) - already modifier, but useful public getter.

     // Total functions = 32. Plenty over 20.

     // Ensure all calls to parameters use the new names.

     // Add check in updateContent: require(syndicationStartTime[msg.sender][contentId] == 0, "Cannot update content while you are syndicating it"); // Keep this simple rule.

     // Add `_curatorActiveSyndicationCount` and update it in syndicate/unsyndicate.

     mapping(address => uint256) private _curatorActiveSyndicationCount; // curatorAddress => count of content items they are actively syndicating

     // Update syndicateContent: _curatorActiveSyndicationCount[msg.sender]++;
     // Update unsyndicateContent: _curatorActiveSyndicationCount[msg.sender]--;
     // Update withdrawCuratorStake: require(_curatorActiveSyndicationCount[msg.sender] == 0, ...);

     // Looks good.

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License & Pragma
// 2. Enums & Structs: ContentStatus, ContentItem, CuratorInfo.
// 3. State Variables: Mappings for content, reputation, curators, stakes, syndications, params. Counters. Owner.
// 4. Events: ContentPublished, ContentUpdated, ContentArchived, CuratorStaked, CuratorStakeWithdrawn,
//            ContentSyndicated, ContentUnsyndicated, ReputationUpdated, RewardsClaimed, ParametersUpdated,
//            ContentGated, ContentAccessUpdated.
// 5. Modifiers: onlyOwner, onlyCreator, contentExists, isActiveCurator.
// 6. Core Logic:
//    - Constructor
//    - Content Management (Publish, Update, Archive, Getters)
//    - Curator Staking & Management (Stake, Withdraw, Getters)
//    - Content Syndication (Syndicate, Unsyndicate, Checkers)
//    - Reputation System (Internal Update, Getter)
//    - Reward System (Claim, Accrued Getter)
//    - Dynamic Access Control (Gate, Ungate, Access Check, Gated View)
//    - Parameter Management (Setters)
//    - View/Utility Functions (Counts, Statuses, Parameters, Basic Getters)

// Function Summary:
// constructor() - Initializes owner and parameters. (1)
// publishContent(string title, string description, string ipfsHash) - Creator publishes content. (2)
// updateContent(uint256 contentId, string newTitle, string newDescription, string newIpfsHash) - Creator updates content if they are not syndicating it and it's not archived. (3)
// archiveContent(uint256 contentId) - Creator/Owner archives content. (4)
// stakeAsCurator() - User stakes ETH to become a curator. (5)
// withdrawCuratorStake() - Curator withdraws stake and claims rewards (must unsyndicate all content). (6)
// syndicateContent(uint256 contentId) - Active curator syndicates published content. (7)
// unsyndicateContent(uint256 contentId) - Curator stops syndicating content. (8)
// claimRewards() - Curator claims accrued staking rewards. (9)
// gateContent(uint256 contentId, uint256 minReputationRequired) - Creator/Owner gates content, sets min reputation. (10)
// ungateContent(uint256 contentId) - Creator/Owner ungates content. (11)
// updateReputation(address user, uint256 amount) - Internal function for reputation updates. (12)
// setCuratorStakeAmount(uint256 amount) - Owner sets curator stake amount. (13)
// setReputationIncreaseRate(uint256 rate) - Owner sets reputation increase rate. (14)
// setRewardRatePerStakeUnitPerTime(uint224 rate) - Owner sets staking reward rate. (15)
// getContent(uint256 contentId) - Get basic content info (excluding potentially gated hash). (16)
// getCuratorInfo(address curator) - Get curator staking info. (17)
// getReputation(address user) - Get user's reputation score. (18)
// getAccruedRewards(address curator) - Calculate a curator's currently accrued rewards. (19)
// isContentSyndicatedByCurator(uint256 contentId, address curator) - Check if a curator syndicates content. (20)
// isCuratorActive(address curator) - Check if a user is an active curator. (21)
// canAccessContent(uint256 contentId, address user) - Check if user meets gating requirement. (22)
// viewContentHash(uint256 contentId) - Get IPFS hash, applying gating access control. (23)
// getTotalContentCount() - Get total published content count. (24)
// getCuratorStakeAmount() - Get required curator stake amount parameter. (25)
// getRewardRatePerStakeUnitPerTime() - Get current staking reward rate parameter. (26)
// getContentStatus(uint256 contentId) - Get content status. (27)
// isContentGated(uint256 contentId) - Check if content is gated. (28)
// getMinReputationRequired(uint256 contentId) - Get min reputation for gated content. (29)
// getSyndicationStartTime(uint256 contentId, address curator) - Get syndication start time for pair. (30)
// getCreator(uint256 contentId) - Get the address of the content creator. (31)
// contentExists(uint256 contentId) - Check if a content item exists. (32)


contract DecentralizedContentSyndicator {

    address public owner;

    enum ContentStatus { Draft, Published, Archived }

    struct ContentItem {
        uint256 id;
        address creator;
        string title;
        string description;
        string ipfsHash; // Link to content data
        ContentStatus status;
        uint64 publishTimestamp;
        bool isGated;
        uint256 minReputationRequired;
    }

    struct CuratorInfo {
        uint256 stakeAmount; // Amount of ETH staked by the curator
        bool isActive; // Is the curator actively staked and participating
        uint64 stakeStartTime; // Timestamp when the curator staked
        uint64 lastRewardClaimTime; // Timestamp of the last reward claim
    }

    // Tracks when a specific curator started syndicating a specific content item.
    // A value of 0 means the curator is not currently syndicating this content.
    mapping(address => mapping(uint256 => uint64)) public syndicationStartTime; // curatorAddress => contentId => startTimestamp

    // Content storage: Maps unique content IDs to ContentItem structs.
    mapping(uint256 => ContentItem) public contentItems;
    // Counter for generating unique content IDs. Starts from 1.
    uint256 private _contentCounter;

    // User reputation scores. Starts at 0 for all addresses.
    mapping(address => uint256) public userReputation; // user address => reputation score

    // Curator information: Maps curator addresses to CuratorInfo structs.
    mapping(address => CuratorInfo) public curatorInfo;
    // Explicitly tracks staked balance for a curator. Used for reward calculation and withdrawal.
    mapping(address => uint256) public curatorStakes; // Tracks actual staked balance (should match CuratorInfo.stakeAmount if active)

    // Tracks how many content items a curator is currently syndicating.
    // Used to prevent stake withdrawal while still syndicating content.
    mapping(address => uint256) private _curatorActiveSyndicationCount; // curatorAddress => count of content items they are actively syndicating

    // System parameters configurable by the owner.
    uint256 public _curatorStakeAmount; // Required ETH to stake as curator
    uint256 public _reputationIncreaseRate; // Base amount reputation increases per relevant action (simplified)
    uint224 public _rewardRatePerStakeUnitPerTime; // Wei per wei staked per second for curators

    // --- Events ---

    event ContentPublished(uint256 indexed contentId, address indexed creator, string title, uint64 timestamp);
    event ContentUpdated(uint256 indexed contentId, address indexed creator, uint64 timestamp);
    event ContentArchived(uint256 indexed contentId, address indexed user, uint64 timestamp);
    event CuratorStaked(address indexed curator, uint256 amount, uint64 timestamp);
    event CuratorStakeWithdrawn(address indexed curator, uint256 returnedAmount, uint256 rewardsClaimed, uint64 timestamp);
    event ContentSyndicated(uint256 indexed contentId, address indexed curator, uint64 timestamp);
    event ContentUnsyndicated(uint256 indexed contentId, address indexed curator, uint64 timestamp);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event RewardsClaimed(address indexed curator, uint256 amount, uint64 timestamp);
    event ParametersUpdated(address indexed updater, uint256 newStakeAmount, uint256 newReputationRate, uint224 newRewardRate);
    event ContentGated(uint256 indexed contentId, uint256 indexed minReputationRequired, uint64 timestamp);
    event ContentAccessUpdated(uint256 indexed contentId, bool isGated, uint256 minReputation);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyCreator(uint256 contentId) {
        require(contentItems[contentId].creator == msg.sender, "Only content creator");
        _;
    }

    modifier contentExists(uint256 contentId) {
         // Checking if creator is not zero is a robust way to see if the struct was ever initialized
        require(contentItems[contentId].creator != address(0), "Content does not exist");
        _;
    }

    modifier isActiveCurator(address _curator) {
        require(curatorInfo[_curator].isActive, "Not an active curator");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _contentCounter = 0;
        // Set reasonable initial default parameters
        _curatorStakeAmount = 1 ether; // Example default: 1 ETH stake
        _reputationIncreaseRate = 10; // Example default increase for reputation events
        _rewardRatePerStakeUnitPerTime = 1; // Example default: 1 wei per wei staked per second
        emit ParametersUpdated(owner, _curatorStakeAmount, _reputationIncreaseRate, _rewardRatePerStakeUnitPerTime);
    }

    // --- Core Logic Functions (Count: 32) ---

    // 1. Constructor - See above

    // --- Content Management ---

    // 2. Publish new content
    function publishContent(string calldata title, string calldata description, string calldata ipfsHash) external {
        _contentCounter++;
        uint256 contentId = _contentCounter;

        contentItems[contentId] = ContentItem({
            id: contentId,
            creator: msg.sender,
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            status: ContentStatus.Published,
            publishTimestamp: uint64(block.timestamp),
            isGated: false, // Content is not gated by default
            minReputationRequired: 0 // No reputation required by default
        });

        // Optionally increase creator reputation upon successful publish
        // _updateReputation(msg.sender, _reputationIncreaseRate); // Example trigger

        emit ContentPublished(contentId, msg.sender, title, uint64(block.timestamp));
    }

    // 3. Update content details
    function updateContent(uint256 contentId, string calldata newTitle, string calldata newDescription, string calldata newIpfsHash)
        external
        contentExists(contentId)
        onlyCreator(contentId)
    {
        require(contentItems[contentId].status != ContentStatus.Archived, "Cannot update archived content");
        // Simple rule: Creator cannot update content while *they* are syndicating it.
        // A more complex system would require more sophisticated state tracking or off-chain checks.
        require(syndicationStartTime[msg.sender][contentId] == 0, "Cannot update content while you are syndicating it");

        ContentItem storage content = contentItems[contentId];
        content.title = newTitle;
        content.description = newDescription;
        content.ipfsHash = newIpfsHash;

        emit ContentUpdated(contentId, msg.sender, uint64(block.timestamp));
    }

    // 4. Archive content (making it inactive)
    function archiveContent(uint256 contentId)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner can archive");
        require(contentItems[contentId].status != ContentStatus.Archived, "Content already archived");

        contentItems[contentId].status = ContentStatus.Archived;

        // Note: Active syndications of this content are implicitly invalidated because `syndicateContent`
        // and `viewContentHash` check for `ContentStatus.Published`. Curators must manually unsyndicate to update their count.
        // This design choice simplifies the contract and avoids costly iteration.

        emit ContentArchived(contentId, msg.sender, uint64(block.timestamp));
    }

    // --- Curator Staking & Management ---

    // 5. Stake ETH to become a curator
    function stakeAsCurator() external payable {
        require(!curatorInfo[msg.sender].isActive, "Already an active curator");
        require(msg.value >= _curatorStakeAmount, "Must send required stake amount");

        // Initialize or update curator info
        curatorInfo[msg.sender] = CuratorInfo({
            stakeAmount: msg.value, // Store actual staked amount, allowing > required
            isActive: true,
            stakeStartTime: uint64(block.timestamp),
            lastRewardClaimTime: uint64(block.timestamp)
        });
        curatorStakes[msg.sender] = msg.value; // Track staked balance explicitly for transfers

        // Refund excess ETH if sent more than required minimum
        if (msg.value > _curatorStakeAmount) {
            payable(msg.sender).transfer(msg.value - _curatorStakeAmount);
        }

        emit CuratorStaked(msg.sender, curatorInfo[msg.sender].stakeAmount, uint64(block.timestamp));
    }

    // 6. Withdraw curator stake and claim accrued rewards
    function withdrawCuratorStake() external isActiveCurator(msg.sender) {
        require(_curatorActiveSyndicationCount[msg.sender] == 0, "Must unsyndicate all content before withdrawing stake");

        CuratorInfo storage info = curatorInfo[msg.sender];
        uint256 stakedAmount = curatorStakes[msg.sender]; // Use tracked balance

        // Calculate and claim any accrued rewards before returning principal
        uint256 rewards = _calculateRewards(msg.sender);
        uint256 totalPayout = stakedAmount + rewards;

        // Reset curator status and clear state
        info.isActive = false;
        info.stakeAmount = 0; // Reset stake amount in info struct
        info.lastRewardClaimTime = uint64(block.timestamp); // Update timestamp (important for reward calculation logic)
        curatorStakes[msg.sender] = 0; // Clear staked balance

        // Transfer stake + rewards
        payable(msg.sender).transfer(totalPayout);

        if (rewards > 0) {
             emit RewardsClaimed(msg.sender, rewards, uint64(block.timestamp)); // Emit reward event too
        }
        emit CuratorStakeWithdrawn(msg.sender, stakedAmount, rewards, uint64(block.timestamp));
    }

    // --- Content Syndication ---

    // 7. Curator syndicates published content
    function syndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(contentItems[contentId].status == ContentStatus.Published, "Content is not published");
        require(syndicationStartTime[msg.sender][contentId] == 0, "Content already syndicated by this curator");

        syndicationStartTime[msg.sender][contentId] = uint64(block.timestamp);
        _curatorActiveSyndicationCount[msg.sender]++; // Increment active syndication count for the curator

        // Optionally update creator reputation when their content gets syndicated
        // _updateReputation(contentItems[contentId].creator, _reputationIncreaseRate); // Example trigger
        // Optionally update curator reputation for syndicating content (perhaps later based on success)
        // _updateReputation(msg.sender, _reputationIncreaseRate / 2); // Example trigger

        emit ContentSyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    // 8. Curator stops syndicating content
    function unsyndicateContent(uint256 contentId) external isActiveCurator(msg.sender) contentExists(contentId) {
        require(syndicationStartTime[msg.sender][contentId] > 0, "Content not currently syndicated by this curator");
        require(_curatorActiveSyndicationCount[msg.sender] > 0, "Internal error: Syndication count mismatch"); // Should be > 0 if start time > 0

        syndicationStartTime[msg.sender][contentId] = 0; // Reset syndication start time
        _curatorActiveSyndicationCount[msg.sender]--; // Decrement active syndication count

        // No rewards accrued specifically for syndication duration in this model.
        // Reputation updates could happen here based on *how long* it was syndicated,
        // but that's complex to track and attribute on-chain. Keeping it simple.

        emit ContentUnsyndicated(contentId, msg.sender, uint64(block.timestamp));
    }

    // --- Reputation System ---

    // 12. Internal function to update reputation (can be called by owner or other trusted functions)
    function _updateReputation(address user, uint256 amount) internal {
        uint256 oldReputation = userReputation[user];
        userReputation[user] += amount;
        emit ReputationUpdated(user, oldReputation, userReputation[user]);
    }

    // Note: A more advanced reputation system could involve:
    // - Decay over time
    // - Votes/endorsements from other high-reputation users
    // - Oracle integration for off-chain engagement signals (views, shares, likes) triggering `_updateReputation` calls.

    // --- Reward System ---

    // Internal helper to calculate rewards based on stake duration and rate
    function _calculateRewards(address curator) internal view returns (uint256) {
        CuratorInfo storage info = curatorInfo[curator];
        // Rewards only accrue while the curator is active
        if (!info.isActive || curatorStakes[curator] == 0) {
             return 0;
        }

        uint256 stakedAmount = curatorStakes[curator]; // Use tracked balance
        // Prevent calculation issues if claim time is in the future (shouldn't happen)
        uint64 timeElapsed = 0;
        if (uint64(block.timestamp) > info.lastRewardClaimTime) {
            timeElapsed = uint64(block.timestamp) - info.lastRewardClaimTime;
        }

        // Reward = stake amount * rate per stake unit per second * time staked
        // Using uint224 for rate to potentially fit within 256 bits calculation without overflow for reasonable values
        // Assumes stakedAmount is in wei, rate is wei/wei/sec, timeElapsed is in seconds
        // Potential for precision loss if rate is very small or timeElapsed is large with large stake.
        // Consider checked arithmetic or different units for production.
        uint256 rewards = (stakedAmount * _rewardRatePerStakeUnitPerTime * timeElapsed);

        return rewards;
    }

    // 9. Curator claims accrued staking rewards
    function claimRewards() external isActiveCurator(msg.sender) {
        uint256 rewards = _calculateRewards(msg.sender);
        require(rewards > 0, "No rewards accrued");

        // Update the last claim time *before* transferring to prevent reentrancy issues
        curatorInfo[msg.sender].lastRewardClaimTime = uint64(block.timestamp);

        // Transfer the calculated rewards
        payable(msg.sender).transfer(rewards);

        emit RewardsClaimed(msg.sender, rewards, uint64(block.timestamp));
    }

    // --- Dynamic Access Control (Gating) ---

    // 10. Gate content, requiring minimum reputation to view IPFS hash
    function gateContent(uint256 contentId, uint256 minReputationRequired)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner can gate");
        require(contentItems[contentId].status == ContentStatus.Published, "Only published content can be gated");
        // minReputationRequired is uint256, so >= 0 is always true. Added for clarity.
        require(minReputationRequired >= 0, "Min reputation cannot be negative");

        ContentItem storage content = contentItems[contentId];
        content.isGated = true;
        content.minReputationRequired = minReputationRequired;

        emit ContentGated(contentId, minReputationRequired, uint64(block.timestamp));
        emit ContentAccessUpdated(contentId, true, minReputationRequired);
    }

    // 11. Remove gating from content
    function ungateContent(uint256 contentId)
        external
        contentExists(contentId)
    {
        require(contentItems[contentId].creator == msg.sender || owner == msg.sender, "Only creator or owner can ungate");
        require(contentItems[contentId].isGated, "Content is not currently gated");

        ContentItem storage content = contentItems[contentId];
        content.isGated = false;
        content.minReputationRequired = 0; // Reset required reputation

        emit ContentAccessUpdated(contentId, false, 0);
    }

    // 22. Check if a user can access potentially gated content
    function canAccessContent(uint256 contentId, address user) public view contentExists(contentId) returns (bool) {
        ContentItem storage content = contentItems[contentId];
        // If content is not gated, anyone can access
        if (!content.isGated) {
            return true;
        }
        // If gated, check if user's reputation meets or exceeds the minimum required
        return userReputation[user] >= content.minReputationRequired;
    }

    // 23. Retrieve the content's IPFS hash, applying gating access control
    function viewContentHash(uint256 contentId) external view contentExists(contentId) returns (string memory) {
        // Require content to be published to view the hash via this method
        require(contentItems[contentId].status == ContentStatus.Published, "Content is not published");
        // Apply the access control check
        require(canAccessContent(contentId, msg.sender), "Insufficient reputation to access this content");
        // If checks pass, return the hash
        return contentItems[contentId].ipfsHash;
    }

    // --- Parameter Management ---

    // 13. Set the required ETH stake amount for curators
    function setCuratorStakeAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Stake amount must be greater than 0");
        // Note: Changing this value only affects *new* stakers. Existing curators
        // remain staked with their original amount. A migration or upgrade path
        // might be needed in a real system if existing stakes must meet the new minimum.
        _curatorStakeAmount = amount;
        emit ParametersUpdated(msg.sender, _curatorStakeAmount, _reputationIncreaseRate, _rewardRatePerStakeUnitPerTime);
    }

    // 14. Set the base rate for reputation increase (used by internal triggers)
    function setReputationIncreaseRate(uint256 rate) external onlyOwner {
        _reputationIncreaseRate = rate;
        emit ParametersUpdated(msg.sender, _curatorStakeAmount, _reputationIncreaseRate, _rewardRatePerStakeUnitPerTime);
    }

    // 15. Set the staking reward rate
    function setRewardRatePerStakeUnitPerTime(uint224 rate) external onlyOwner {
         // Be careful with the units and potential overflow/underflow here.
         // This rate assumes wei per wei staked per second.
        _rewardRatePerStakeUnitPerTime = rate;
        emit ParametersUpdated(msg.sender, _curatorStakeAmount, _reputationIncreaseRate, _rewardRatePerStakeUnitPerTime);
    }


    // --- View / Utility Functions (Remaining functions to reach 32+) ---

    // 16. Get basic content info (excluding potentially gated hash)
    function getContent(uint256 contentId)
        public // Made public for potential internal/external calls
        view
        contentExists(contentId)
        returns (uint256 id, address creator, string memory title, string memory description, ContentStatus status, uint64 publishTimestamp)
    {
         ContentItem storage item = contentItems[contentId];
         // Note: IPFS hash is excluded here to force users to use viewContentHash for gated content checks
         return (item.id, item.creator, item.title, item.description, item.status, item.publishTimestamp);
    }

    // 17. Get curator staking information
    function getCuratorInfo(address curator)
        external
        view
        returns (uint256 stakeAmount, bool isActive, uint64 stakeStartTime, uint64 lastRewardClaimTime)
    {
        CuratorInfo storage info = curatorInfo[curator];
        return (info.stakeAmount, info.isActive, info.stakeStartTime, info.lastRewardClaimTime);
    }

    // 18. Get a user's current reputation score
    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    // 19. Calculate a curator's currently accrued rewards (does not claim)
    function getAccruedRewards(address curator) external view isActiveCurator(curator) returns (uint256) {
        return _calculateRewards(curator);
    }

    // 20. Check if a specific curator is currently syndicating specific content
    function isContentSyndicatedByCurator(uint256 contentId, address curator) external view contentExists(contentId) returns (bool) {
        return syndicationStartTime[curator][contentId] > 0;
    }

    // 21. Check if a user is currently an active, staked curator
    function isCuratorActive(address curator) external view returns (bool) {
        return curatorInfo[curator].isActive;
    }

    // 24. Get the total number of content items published (counter value)
    function getTotalContentCount() external view returns (uint256) {
        return _contentCounter;
    }

    // 25. Get the currently required curator stake amount parameter
    function getCuratorStakeAmount() external view returns (uint256) {
        return _curatorStakeAmount;
    }

    // 26. Get the current staking reward rate parameter
    function getRewardRatePerStakeUnitPerTime() external view returns (uint224) {
        return _rewardRatePerStakeUnitPerTime;
    }

    // 27. Get the status of a content item
    function getContentStatus(uint256 contentId) external view contentExists(contentId) returns (ContentStatus) {
        return contentItems[contentId].status;
    }

    // 28. Check if content is marked as gated
     function isContentGated(uint256 contentId) external view contentExists(contentId) returns (bool) {
        return contentItems[contentId].isGated;
    }

    // 29. Get the minimum reputation needed for gated content access
    function getMinReputationRequired(uint256 contentId) external view contentExists(contentId) returns (uint256) {
        return contentItems[contentId].minReputationRequired;
    }

    // 30. Get the timestamp when a specific curator started syndicating specific content
    // Returns 0 if the curator is not currently syndicating this content
    function getSyndicationStartTime(uint256 contentId, address curator) external view contentExists(contentId) returns (uint64) {
        return syndicationStartTime[curator][contentId];
    }

    // 31. Get the address of the content creator
    function getCreator(uint256 contentId) external view contentExists(contentId) returns (address) {
        return contentItems[contentId].creator;
    }

    // 32. Public check if a content item exists
    function contentExists(uint256 contentId) public view returns (bool) {
         // Checking if creator is not zero implies the struct was initialized
        return contentItems[contentId].creator != address(0);
    }

    // --- Fallback/Receive (Optional but good practice) ---
    receive() external payable {
        // Optional: Handle bare ETH sends, maybe log them or revert
        // require(msg.sender == address(0), "Direct ETH deposit not allowed"); // Example: Only allow via stake function
    }

    fallback() external payable {
        // Optional: Handle calls to non-existent functions, typically revert
        revert("Invalid function call");
    }

}
```