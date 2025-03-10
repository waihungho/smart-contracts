```solidity
/**
 * @title Decentralized Content Monetization and Curation Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform that allows creators to monetize their content,
 *      users to curate content by staking and voting, and introduces dynamic content pricing based on demand.
 *
 * **Outline and Function Summary:**
 *
 * **Data Structures:**
 *   - `Content`: Struct to store content metadata (id, creator, title, description, contentURI, price, subscriptionPrice, creationTimestamp, curationScore).
 *   - `UserProfile`: Struct to store user profile information (address, username, joinTimestamp).
 *   - `Stake`: Struct to track user stakes for content curation (user, contentId, stakeAmount, stakeTimestamp).
 *   - `Proposal`: Struct to represent governance proposals (proposalId, proposer, proposalType, targetContentId, newPrice, newSubscriptionPrice, votingStartTime, votingEndTime, votesFor, votesAgainst, executed, executionTimestamp).
 *
 * **Enums:**
 *   - `ProposalType`: Enum to define types of governance proposals (e.g., PriceChange, VisibilityControl).
 *
 * **Mappings:**
 *   - `contentRegistry`: Maps contentId to `Content` struct.
 *   - `userProfiles`: Maps user address to `UserProfile` struct.
 *   - `contentCreators`: Maps creator address to a list of contentIds they created.
 *   - `userStakes`: Maps user address to a list of `Stake` structs representing their active stakes.
 *   - `proposalRegistry`: Maps proposalId to `Proposal` struct.
 *   - `contentCurationScores`: Maps contentId to its current curation score.
 *   - `contentPurchasers`: Maps contentId to a list of addresses who have purchased it.
 *   - `contentSubscribers`: Maps contentId to a list of addresses who are subscribed.
 *
 * **State Variables:**
 *   - `platformOwner`: Address of the platform owner.
 *   - `platformFeePercentage`: Percentage fee charged on content purchases (e.g., 5%).
 *   - `nextContentId`: Counter for generating unique content IDs.
 *   - `nextProposalId`: Counter for generating unique proposal IDs.
 *   - `minStakeAmount`: Minimum amount of tokens required to stake for curation.
 *   - `stakingRewardPercentage`: Percentage of platform fees distributed as curation rewards.
 *   - `proposalVotingDuration`: Default duration for governance voting periods.
 *   - `platformToken`: Address of the platform's ERC20 token contract (for staking and rewards).
 *
 * **Functions:**
 *
 * **Content Creation & Management:**
 *   1. `createContent(string memory _title, string memory _description, string memory _contentURI, uint256 _price, uint256 _subscriptionPrice)`: Allows creators to register new content.
 *   2. `setContentMetadata(uint256 _contentId, string memory _title, string memory _description, string memory _contentURI)`: Allows creators to update content metadata.
 *   3. `setContentPrice(uint256 _contentId, uint256 _newPrice)`: Allows creators to update the purchase price of their content.
 *   4. `setContentSubscriptionPrice(uint256 _contentId, uint256 _newSubscriptionPrice)`: Allows creators to update the subscription price of their content.
 *   5. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 *   6. `getContentCreator(uint256 _contentId)`: Retrieves the creator address of a content item.
 *   7. `getContentCurationScore(uint256 _contentId)`: Retrieves the current curation score of a content item.
 *   8. `getContentPurchaseCount(uint256 _contentId)`: Retrieves the number of purchases for a content item.
 *   9. `getContentSubscriptionCount(uint256 _contentId)`: Retrieves the number of subscriptions for a content item.
 *   10. `withdrawContentEarnings(uint256 _contentId)`: Allows creators to withdraw their accumulated earnings from content sales and subscriptions.
 *
 * **User & Profile Management:**
 *   11. `createUserProfile(string memory _username)`: Allows users to create a profile with a username.
 *   12. `updateUserProfile(string memory _username)`: Allows users to update their username.
 *   13. `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 *
 * **Content Access & Monetization:**
 *   14. `purchaseContent(uint256 _contentId)`: Allows users to purchase content for a one-time access.
 *   15. `subscribeToContent(uint256 _contentId)`: Allows users to subscribe to content for recurring access.
 *   16. `tipCreator(uint256 _contentId)`: Allows users to send tips to content creators.
 *
 * **Curation & Staking:**
 *   17. `stakeForContent(uint256 _contentId, uint256 _amount)`: Allows users to stake tokens to curate content, increasing its visibility.
 *   18. `unstakeForContent(uint256 _contentId)`: Allows users to unstake their tokens, reducing their curation influence.
 *   19. `distributeCurationRewards()`: Distributes a portion of platform fees as rewards to users based on their staking activity and curation influence.
 *
 * **Governance & Platform Management:**
 *   20. `proposePriceChange(uint256 _contentId, uint256 _newPrice)`: Allows users to propose a change in content price through governance.
 *   21. `proposeSubscriptionPriceChange(uint256 _contentId, uint256 _newSubscriptionPrice)`: Allows users to propose a change in content subscription price through governance.
 *   22. `voteOnProposal(uint256 _proposalId, bool _voteFor)`: Allows users to vote on active governance proposals.
 *   23. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if it passes based on voting.
 *   24. `setPlatformFeePercentage(uint256 _newFeePercentage)`: Allows the platform owner to set the platform fee percentage.
 *   25. `setPlatformToken(address _tokenAddress)`: Allows the platform owner to set the platform's ERC20 token address.
 *   26. `setStakingRewardPercentage(uint256 _newRewardPercentage)`: Allows the platform owner to set the percentage of fees for curation rewards.
 *   27. `setProposalVotingDuration(uint256 _newDuration)`: Allows the platform owner to set the default proposal voting duration.
 *   28. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedContentPlatform is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Data Structures
    struct Content {
        uint256 id;
        address creator;
        string title;
        string description;
        string contentURI;
        uint256 price;
        uint256 subscriptionPrice;
        uint256 creationTimestamp;
        int256 curationScore; // Can be negative to represent negative curation
    }

    struct UserProfile {
        address userAddress;
        string username;
        uint256 joinTimestamp;
    }

    struct Stake {
        address user;
        uint256 contentId;
        uint256 stakeAmount;
        uint256 stakeTimestamp;
    }

    enum ProposalType {
        PriceChange,
        SubscriptionPriceChange,
        VisibilityControl // Future use, e.g., content flagging/unflagging
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        uint256 targetContentId;
        uint256 newPrice;
        uint256 newSubscriptionPrice;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 executionTimestamp;
    }

    // Mappings
    mapping(uint256 => Content) public contentRegistry;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => uint256[]) public contentCreators; // List of content IDs created by a user
    mapping(address => Stake[]) public userStakes; // List of active stakes by a user
    mapping(uint256 => Proposal) public proposalRegistry;
    mapping(uint256 => int256) public contentCurationScores;
    mapping(uint256 => address[]) public contentPurchasers;
    mapping(uint256 => address[]) public contentSubscribers;

    // State Variables
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    Counters.Counter private _contentIdCounter;
    Counters.Counter private _proposalIdCounter;
    uint256 public minStakeAmount = 100 * 10**18; // Minimum 100 platform tokens to stake
    uint256 public stakingRewardPercentage = 20; // 20% of platform fees for curation rewards
    uint256 public proposalVotingDuration = 7 days; // 7 days default voting duration
    address public platformToken; // Address of the platform's ERC20 token contract

    event ContentCreated(uint256 contentId, address creator, string title);
    event ContentMetadataUpdated(uint256 contentId, string title);
    event ContentPriceUpdated(uint256 contentId, uint256 newPrice);
    event ContentSubscriptionPriceUpdated(uint256 contentId, uint256 newSubscriptionPrice);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string username);
    event ContentPurchased(uint256 contentId, address purchaser);
    event ContentSubscribed(uint256 contentId, address subscriber);
    event CreatorTipped(uint256 contentId, address tipper, uint256 amount);
    event StakeAdded(address staker, uint256 contentId, uint256 amount);
    event StakeRemoved(address staker, uint256 contentId, uint256 amount);
    event CurationRewardsDistributed(uint256 totalRewardsDistributed);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, uint256 contentId, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool voteFor);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType, uint256 contentId);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event PlatformTokenSet(address tokenAddress);
    event StakingRewardPercentageSet(uint256 newRewardPercentage);
    event ProposalVotingDurationSet(uint256 newDuration);
    event PlatformFeesWithdrawn(address owner, uint256 amount);
    event ContentEarningsWithdrawn(uint256 contentId, address creator, uint256 amount);

    constructor(address _platformToken) Ownable() {
        platformToken = _platformToken;
    }

    modifier onlyContentCreator(uint256 _contentId) {
        require(contentRegistry[_contentId].creator == msg.sender, "Only content creator can perform this action.");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(contentRegistry[_contentId].id != 0, "Invalid content ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(proposalRegistry[_proposalId].proposalId != 0, "Invalid proposal ID.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].userAddress != address(0), "User profile not registered.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp >= proposalRegistry[_proposalId].votingStartTime && block.timestamp <= proposalRegistry[_proposalId].votingEndTime, "Proposal voting period is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposalRegistry[_proposalId].executed, "Proposal already executed.");
        _;
    }


    // 1. Create Content
    function createContent(
        string memory _title,
        string memory _description,
        string memory _contentURI,
        uint256 _price,
        uint256 _subscriptionPrice
    ) public onlyRegisteredUser {
        _contentIdCounter.increment();
        uint256 contentId = _contentIdCounter.current();

        contentRegistry[contentId] = Content({
            id: contentId,
            creator: msg.sender,
            title: _title,
            description: _description,
            contentURI: _contentURI,
            price: _price,
            subscriptionPrice: _subscriptionPrice,
            creationTimestamp: block.timestamp,
            curationScore: 0 // Initial curation score is 0
        });
        contentCreators[msg.sender].push(contentId);

        emit ContentCreated(contentId, msg.sender, _title);
    }

    // 2. Set Content Metadata
    function setContentMetadata(
        uint256 _contentId,
        string memory _title,
        string memory _description,
        string memory _contentURI
    ) public onlyContentCreator(_contentId) validContentId(_contentId) {
        Content storage content = contentRegistry[_contentId];
        content.title = _title;
        content.description = _description;
        content.contentURI = _contentURI;

        emit ContentMetadataUpdated(_contentId, _title);
    }

    // 3. Set Content Price
    function setContentPrice(uint256 _contentId, uint256 _newPrice) public onlyContentCreator(_contentId) validContentId(_contentId) {
        contentRegistry[_contentId].price = _newPrice;
        emit ContentPriceUpdated(_contentId, _newPrice);
    }

    // 4. Set Content Subscription Price
    function setContentSubscriptionPrice(uint256 _contentId, uint256 _newSubscriptionPrice) public onlyContentCreator(_contentId) validContentId(_contentId) {
        contentRegistry[_contentId].subscriptionPrice = _newSubscriptionPrice;
        emit ContentSubscriptionPriceUpdated(_contentId, _newSubscriptionPrice);
    }

    // 5. Get Content Details
    function getContentDetails(uint256 _contentId) public view validContentId(_contentId) returns (Content memory) {
        return contentRegistry[_contentId];
    }

    // 6. Get Content Creator
    function getContentCreator(uint256 _contentId) public view validContentId(_contentId) returns (address) {
        return contentRegistry[_contentId].creator;
    }

    // 7. Get Content Curation Score
    function getContentCurationScore(uint256 _contentId) public view validContentId(_contentId) returns (int256) {
        return contentCurationScores[_contentId];
    }

    // 8. Get Content Purchase Count
    function getContentPurchaseCount(uint256 _contentId) public view validContentId(_contentId) returns (uint256) {
        return contentPurchasers[_contentId].length;
    }

    // 9. Get Content Subscription Count
    function getContentSubscriptionCount(uint256 _contentId) public view validContentId(_contentId) returns (uint256) {
        return contentSubscribers[_contentId].length;
    }

    // 10. Withdraw Content Earnings
    function withdrawContentEarnings(uint256 _contentId) public onlyContentCreator(_contentId) validContentId(_contentId) {
        uint256 balance = address(this).balance; // Assuming earnings are accumulated in contract balance
        uint256 creatorEarnings = 0; // In a real system, track individual content earnings more precisely.
        // For simplicity in this example, assume all contract balance is content earnings.
        // In a more complex system, you would track earnings per content item or creator.

        creatorEarnings = balance; // For this example, withdraw all contract balance

        if (creatorEarnings > 0) {
            payable(msg.sender).transfer(creatorEarnings);
            emit ContentEarningsWithdrawn(_contentId, msg.sender, creatorEarnings);
        }
    }

    // 11. Create User Profile
    function createUserProfile(string memory _username) public {
        require(userProfiles[msg.sender].userAddress == address(0), "User profile already exists.");
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            joinTimestamp: block.timestamp
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    // 12. Update User Profile
    function updateUserProfile(string memory _username) public onlyRegisteredUser {
        userProfiles[msg.sender].username = _username;
        emit UserProfileUpdated(msg.sender, _username);
    }

    // 13. Get User Profile
    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    // 14. Purchase Content
    function purchaseContent(uint256 _contentId) public payable validContentId(_contentId) onlyRegisteredUser {
        uint256 price = contentRegistry[_contentId].price;
        require(msg.value >= price, "Insufficient payment for content purchase.");

        // Transfer platform fee and creator earnings
        uint256 platformFee = price.mul(platformFeePercentage).div(100);
        uint256 creatorEarning = price.sub(platformFee);

        payable(contentRegistry[_contentId].creator).transfer(creatorEarning);
        // Platform fees remain in the contract to be withdrawn by the owner and potentially distributed as rewards.

        contentPurchasers[_contentId].push(msg.sender);
        emit ContentPurchased(_contentId, msg.sender);

        // Refund any excess payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // 15. Subscribe to Content (Recurring Payment - Simplified, real implementation needs more complexity for recurring payments)
    function subscribeToContent(uint256 _contentId) public payable validContentId(_contentId) onlyRegisteredUser {
        uint256 subscriptionPrice = contentRegistry[_contentId].subscriptionPrice;
        require(msg.value >= subscriptionPrice, "Insufficient payment for subscription.");

        // Transfer platform fee and creator earnings
        uint256 platformFee = subscriptionPrice.mul(platformFeePercentage).div(100);
        uint256 creatorEarning = subscriptionPrice.sub(platformFee);

        payable(contentRegistry[_contentId].creator).transfer(creatorEarning);
        // Platform fees remain in the contract.

        contentSubscribers[_contentId].push(msg.sender);
        emit ContentSubscribed(_contentId, msg.sender);

        // Refund any excess payment
        if (msg.value > subscriptionPrice) {
            payable(msg.sender).transfer(msg.value - subscriptionPrice);
        }

        // In a real subscription system, you'd need to handle recurring payments, expiration, etc.
        // This is a simplified example for demonstration.
    }

    // 16. Tip Creator
    function tipCreator(uint256 _contentId) public payable validContentId(_contentId) onlyRegisteredUser {
        require(msg.value > 0, "Tip amount must be greater than zero.");
        payable(contentRegistry[_contentId].creator).transfer(msg.value);
        emit CreatorTipped(_contentId, msg.sender, msg.value);
    }

    // 17. Stake For Content
    function stakeForContent(uint256 _contentId, uint256 _amount) public validContentId(_contentId) onlyRegisteredUser {
        require(platformToken != address(0), "Platform token address not set.");
        require(_amount >= minStakeAmount, "Stake amount below minimum.");

        IERC20 token = IERC20(platformToken);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        userStakes[msg.sender].push(Stake({
            user: msg.sender,
            contentId: _contentId,
            stakeAmount: _amount,
            stakeTimestamp: block.timestamp
        }));

        contentCurationScores[_contentId] = contentCurationScores[_contentId].add(int256(_amount)); // Increase curation score
        emit StakeAdded(msg.sender, _contentId, _amount);
    }

    // 18. Unstake For Content
    function unstakeForContent(uint256 _contentId) public validContentId(_contentId) onlyRegisteredUser {
        IERC20 token = IERC20(platformToken);
        uint256 totalUnstakedAmount = 0;
        Stake[] storage stakes = userStakes[msg.sender];
        uint256 stakeIndexToRemove = type(uint256).max; // Initialize to max to indicate no stake found

        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].contentId == _contentId) {
                totalUnstakedAmount = totalUnstakedAmount.add(stakes[i].stakeAmount);
                stakeIndexToRemove = i;
                break; // Assuming only one stake per user per content for simplicity. In a real system, you might allow multiple stakes and need to decide which one to unstake.
            }
        }

        require(stakeIndexToRemove != type(uint256).max, "No stake found for this content.");

        if (totalUnstakedAmount > 0) {
            require(token.transfer(msg.sender, totalUnstakedAmount), "Token transfer back failed.");
            contentCurationScores[_contentId] = contentCurationScores[_contentId].sub(int256(totalUnstakedAmount)); // Decrease curation score
            emit StakeRemoved(msg.sender, _contentId, totalUnstakedAmount);

            // Remove the stake from the user's stake list (shifting elements)
            for (uint256 j = stakeIndexToRemove; j < stakes.length - 1; j++) {
                stakes[j] = stakes[j + 1];
            }
            stakes.pop(); // Remove the last element (which is now a duplicate or irrelevant)
        }
    }

    // 19. Distribute Curation Rewards
    function distributeCurationRewards() public onlyOwner {
        uint256 platformBalance = address(this).balance; // Fees accumulated in contract balance
        uint256 totalRewards = platformBalance.mul(stakingRewardPercentage).div(100);
        uint256 remainingFees = platformBalance.sub(totalRewards);

        // In a real system, calculate rewards based on stake amount and duration for each staker.
        // For simplicity, this example distributes rewards proportionally to total stake amount.
        uint256 totalStakeAmount = 0;
        for (uint256 contentId = 1; contentId <= _contentIdCounter.current(); contentId++) {
            totalStakeAmount = totalStakeAmount.add(uint256(contentCurationScores[contentId])); // Sum up all positive curation scores as an approximation of total stake
        }

        if (totalStakeAmount > 0 && totalRewards > 0) {
            uint256 rewardsDistributed = 0;
            for (uint256 contentId = 1; contentId <= _contentIdCounter.current(); contentId++) {
                int256 contentStake = contentCurationScores[contentId];
                if (contentStake > 0) { // Only reward for positive stakes
                    uint256 rewardAmount = totalRewards.mul(uint256(contentStake)).div(totalStakeAmount);
                    // In a real system, track stakers per content and distribute proportionally within each content's stakers.
                    // This simplified example just distributes based on total curation score.
                    // This part would need significant refinement for a production system.

                    // For simplicity, send rewards to content creator as a proxy in this example.
                    // In a real system, track individual stakers and their rewards.
                    if (rewardAmount > 0) {
                        payable(contentRegistry[contentId].creator).transfer(rewardAmount);
                        rewardsDistributed = rewardsDistributed.add(rewardAmount);
                    }
                }
            }
            emit CurationRewardsDistributed(rewardsDistributed);
        }

        // Keep remainingFees in the contract for platform owner withdrawal
    }


    // 20. Propose Price Change
    function proposePriceChange(uint256 _contentId, uint256 _newPrice) public onlyRegisteredUser validContentId(_contentId) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposalRegistry[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.PriceChange,
            targetContentId: _contentId,
            newPrice: _newPrice,
            newSubscriptionPrice: 0, // Not relevant for price change proposal
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0
        });

        emit ProposalCreated(proposalId, ProposalType.PriceChange, _contentId, msg.sender);
    }

    // 21. Propose Subscription Price Change
    function proposeSubscriptionPriceChange(uint256 _contentId, uint256 _newSubscriptionPrice) public onlyRegisteredUser validContentId(_contentId) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposalRegistry[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.SubscriptionPriceChange,
            targetContentId: _contentId,
            newPrice: 0, // Not relevant for subscription price change proposal
            newSubscriptionPrice: _newSubscriptionPrice,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0
        });

        emit ProposalCreated(proposalId, ProposalType.SubscriptionPriceChange, _contentId, msg.sender);
    }

    // 22. Vote on Proposal
    function voteOnProposal(uint256 _proposalId, bool _voteFor) public onlyRegisteredUser validProposalId(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        Proposal storage proposal = proposalRegistry[_proposalId];

        // To prevent double voting, you might track voters per proposal. For simplicity, skipping here.
        if (_voteFor) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        emit VoteCast(_proposalId, msg.sender, _voteFor);
    }

    // 23. Execute Proposal
    function executeProposal(uint256 _proposalId) public validProposalId(_proposalId) proposalNotExecuted(_proposalId) {
        Proposal storage proposal = proposalRegistry[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended yet.");

        if (proposal.votesFor > proposal.votesAgainst) { // Simple majority for now. Can be adjusted for more complex governance.
            proposal.executed = true;
            proposal.executionTimestamp = block.timestamp;

            if (proposal.proposalType == ProposalType.PriceChange) {
                setContentPrice(proposal.targetContentId, proposal.newPrice);
                emit ProposalExecuted(_proposalId, ProposalType.PriceChange, proposal.targetContentId);
            } else if (proposal.proposalType == ProposalType.SubscriptionPriceChange) {
                setContentSubscriptionPrice(proposal.targetContentId, proposal.newSubscriptionPrice);
                emit ProposalExecuted(_proposalId, ProposalType.SubscriptionPriceChange, proposal.targetContentId);
            }
            // Add more proposal types here as needed (e.g., VisibilityControl)
        } else {
            proposal.executed = true; // Mark as executed even if it fails to prevent re-execution attempts.
            proposal.executionTimestamp = block.timestamp;
        }
    }

    // 24. Set Platform Fee Percentage
    function setPlatformFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageSet(_newFeePercentage);
    }

    // 25. Set Platform Token
    function setPlatformToken(address _tokenAddress) public onlyOwner {
        platformToken = _tokenAddress;
        emit PlatformTokenSet(_tokenAddress);
    }

    // 26. Set Staking Reward Percentage
    function setStakingRewardPercentage(uint256 _newRewardPercentage) public onlyOwner {
        stakingRewardPercentage = _newRewardPercentage;
        emit StakingRewardPercentageSet(_newRewardPercentage);
    }

    // 27. Set Proposal Voting Duration
    function setProposalVotingDuration(uint256 _newDuration) public onlyOwner {
        proposalVotingDuration = _newDuration;
        emit ProposalVotingDurationSet(_newDuration);
    }

    // 28. Withdraw Platform Fees
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
            emit PlatformFeesWithdrawn(owner(), balance);
        }
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```