```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content NFT with Reputation and Royalties
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic NFT that can evolve based on user reputation
 *      and includes a royalty system for creators and reputation-based features.
 *
 * **Outline:**
 * 1. **NFT Core Functionality:** Minting, Transfer, Metadata URI, Ownership.
 * 2. **Dynamic Content:**  NFT metadata (image, attributes) can change based on reputation score.
 * 3. **Reputation System:** Users earn reputation by engaging with the platform (e.g., voting, contributing).
 * 4. **Reputation Tiers:**  NFT appearance and functionality can unlock based on reputation tiers.
 * 5. **Royalties:** Creators receive royalties on secondary sales, configurable and dynamic.
 * 6. **Content Moderation (Decentralized):**  Reputation-weighted voting for content moderation.
 * 7. **Community Governance (Basic):**  Reputation-based voting for platform upgrades (parameter changes).
 * 8. **Task & Bounty System:** Users can create tasks, and others can complete them for reputation and rewards.
 * 9. **Skill-Based Matching:** Tasks can be tagged with required skills, and users can declare skills.
 * 10. **Reputation-Boosted Features:**  Higher reputation unlocks access to premium features or benefits.
 * 11. **NFT Staking for Reputation:** Stake NFTs to boost reputation gain or access exclusive features.
 * 12. **Reputation Decay/Inactivity Penalty:** Reputation can decrease over time if inactive.
 * 13. **Customizable NFT Traits:**  Creators can define traits and their dynamic behavior based on reputation.
 * 14. **Decentralized Content Storage (Placeholder):**  Integration point for decentralized storage (IPFS, Arweave).
 * 15. **Emergency Pause Function:**  Owner can pause critical functionalities in case of emergencies.
 * 16. **Royalty Recipient Management:**  Flexible management of royalty recipients (creators, collaborators).
 * 17. **Reputation Transfer/Delegation (Optional):**  Ability to transfer or delegate reputation (carefully considered).
 * 18. **Batch Minting & Gifting:**  Efficient minting and gifting of NFTs.
 * 19. **On-Chain Reputation Oracle (Simplified):**  Contract manages its own reputation scoring and tiers.
 * 20. **Metadata Refresh Mechanism:**  Function to trigger metadata refresh when reputation changes.
 *
 * **Function Summary:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic Content NFT to a specified address.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another (internal use).
 * 3. `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: Safely transfers an NFT, compatible with ERC721.
 * 4. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 * 5. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT, dynamically generated.
 * 6. `getBaseURI()`: Returns the base URI for NFT metadata.
 * 7. `setBaseURI(string memory _newBaseURI)`: Sets a new base URI for NFT metadata (owner only).
 * 8. `getUserReputation(address _user)`: Returns the reputation score of a user.
 * 9. `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (internal, triggered by platform actions).
 * 10. `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (internal, triggered by negative actions).
 * 11. `getReputationTier(address _user)`: Returns the reputation tier of a user based on their score.
 * 12. `getNFTMetadata(uint256 _tokenId)`:  Generates and returns the dynamic metadata for an NFT, based on the owner's reputation.
 * 13. `setRoyaltyPercentage(uint256 _percentage)`: Sets the royalty percentage for secondary sales (owner only).
 * 14. `getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)`: Returns royalty information for a given NFT and sale price.
 * 15. `submitTask(string memory _taskDescription, string[] memory _requiredSkills, uint256 _bounty)`: Allows users to submit a task with description, skills, and bounty.
 * 16. `bidOnTask(uint256 _taskId)`: Allows users to bid on a task.
 * 17. `acceptBid(uint256 _taskId, address _bidder)`: Allows task creator to accept a bid and assign the task.
 * 18. `completeTask(uint256 _taskId)`: Allows the assigned user to mark a task as completed.
 * 19. `reviewTaskCompletion(uint256 _taskId, bool _approved)`: Allows task creator to review and approve or reject task completion.
 * 20. `voteForModeration(uint256 _contentId, bool _upvote)`: Allows users to vote on content moderation, weighted by reputation.
 * 21. `pauseContract()`: Pauses critical contract functionalities (owner only).
 * 22. `unpauseContract()`: Resumes paused contract functionalities (owner only).
 * 23. `withdrawBounty(uint256 _taskId)`: Allows the task completer to withdraw their bounty after successful completion.
 * 24. `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.
 * 25. `reportContent(uint256 _contentId, string memory _reason)`: Allows users to report content for moderation.
 * 26. `setReputationThresholdForTier(uint256 _tier, uint256 _threshold)`: Allows owner to set reputation threshold for each tier.
 * 27. `getStakedNFTCount(address _user)`: Returns the number of NFTs staked by a user. (Example of reputation boost feature - can be expanded)
 * 28. `stakeNFTForReputationBoost(uint256 _tokenId)`: Allows users to stake their NFTs for reputation boost. (Example of reputation boost feature - can be expanded)
 * 29. `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs. (Example of reputation boost feature - can be expanded)
 */
contract DynamicContentNFT is ERC721Enumerable, ERC2981 {
    using Strings for uint256;

    string public name = "DynamicContentNFT";
    string public symbol = "DCNFT";
    string public baseURI;
    address public owner;
    uint256 public royaltyPercentage = 500; // 5% royalty (500/10000)
    uint256 public nextTokenId = 1;
    bool public paused = false;

    // Reputation System
    mapping(address => uint256) public userReputation;
    uint256[] public reputationTiers = [100, 500, 1000, 5000]; // Example tiers
    mapping(uint256 => uint256) public reputationThresholds; // Tier => Threshold

    // Task & Bounty System
    struct Task {
        address creator;
        string description;
        string[] requiredSkills;
        uint256 bounty;
        address assignedTo;
        bool completed;
        bool approved;
    }
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId = 1;
    mapping(uint256 => mapping(address => bool)) public taskBids; // taskId => bidder => hasBid

    // Content Moderation (Simplified) - ContentId could be NFT TokenId or TaskId or general content
    struct ContentModeration {
        uint256 upvotes;
        uint256 downvotes;
        string reportReason;
        bool flagged;
    }
    mapping(uint256 => ContentModeration) public contentModeration;
    uint256 public nextContentId = 1; // For general content moderation (outside NFTs/Tasks, if needed)

    // Reputation Boost through NFT Staking (Example Feature)
    mapping(address => mapping(uint256 => bool)) public stakedNFTs; // user => tokenId => isStaked
    mapping(address => uint256) public stakedNFTCount; // user => count of staked NFTs


    // Events
    event NFTMinted(address indexed to, uint256 tokenId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event TaskSubmitted(uint256 taskId, address creator);
    event TaskBidSubmitted(uint256 taskId, address bidder);
    event TaskBidAccepted(uint256 taskId, address creator, address bidder);
    event TaskCompleted(uint256 taskId, address completer);
    event TaskReviewed(uint256 taskId, address creator, bool approved);
    event ContentModerationVote(uint256 contentId, address voter, bool upvote);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContractPaused(address owner);
    event ContractUnpaused(address owner);
    event NFTStaked(address user, uint256 tokenId);
    event NFTUnstaked(address user, uint256 tokenId);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor(string memory _baseURI) ERC721(name, symbol) {
        owner = msg.sender;
        baseURI = _baseURI;
        _setDefaultRoyalty(address(this), royaltyPercentage); // Default royalty to contract itself (can be adjusted)
        // Initialize reputation thresholds - Example
        for (uint256 i = 0; i < reputationTiers.length; i++) {
            reputationThresholds[i] = reputationTiers[i];
        }
    }

    // ==== NFT Core Functionality ====

    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        _mint(_to, nextTokenId);
        _setTokenURI(nextTokenId, string(abi.encodePacked(_baseURI, "/", Strings.toString(nextTokenId), ".json"))); // Example metadata URI construction
        emit NFTMinted(_to, nextTokenId);
        nextTokenId++;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic before token transfer if needed, e.g., reputation adjustments upon transfer
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        return getNFTMetadata(_tokenId); // Dynamically generate metadata based on reputation
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // ==== Reputation System ====

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    function increaseReputation(address _user, uint256 _amount) internal {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputation[_user]);
    }

    function decreaseReputation(address _user, uint256 _amount) internal {
        if (userReputation[_user] >= _amount) {
            userReputation[_user] -= _amount;
        } else {
            userReputation[_user] = 0; // Avoid underflow, or handle differently as per design
        }
        emit ReputationDecreased(_user, _amount, userReputation[_user]);
    }

    function getReputationTier(address _user) public view returns (uint256) {
        uint256 reputation = userReputation[_user];
        for (uint256 i = reputationTiers.length; i > 0; i--) { // Iterate from highest tier down
            if (reputation >= reputationThresholds[i-1]) {
                return i; // Tier number (1-based)
            }
        }
        return 0; // Tier 0 if reputation is below the lowest threshold
    }

    function setReputationThresholdForTier(uint256 _tier, uint256 _threshold) public onlyOwner {
        require(_tier > 0 && _tier <= reputationTiers.length, "Invalid tier number");
        reputationThresholds[_tier - 1] = _threshold;
    }


    // ==== Dynamic NFT Metadata Generation ====

    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        address ownerAddress = ownerOf(_tokenId);
        uint256 reputationTier = getReputationTier(ownerAddress);

        // Example dynamic metadata generation logic - Customize based on your NFT design
        string memory imageName = string(abi.encodePacked("nft_tier_", Strings.toString(reputationTier), ".png"));
        string memory description = string(abi.encodePacked("A Dynamic Content NFT, Tier: ", Strings.toString(reputationTier)));

        // Construct JSON metadata string - Example, adapt to your metadata schema
        string memory metadata = string(abi.encodePacked(
            '{"name": "', name, ' #', Strings.toString(_tokenId), '",',
            '"description": "', description, '",',
            '"image": "', baseURI, "/images/", imageName, '",',
            '"attributes": [',
                '{"trait_type": "Reputation Tier", "value": "', Strings.toString(reputationTier), '"}',
            ']',
            '}'
        ));
        return metadata;
    }


    // ==== Royalty Functionality (ERC2981) ====

    function setRoyaltyPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 10000, "Royalty percentage cannot exceed 100%");
        royaltyPercentage = _percentage;
        _setDefaultRoyalty(address(this), royaltyPercentage); // Update default royalty
    }

    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        (receiver, royaltyAmount) = royaltyInfo(_tokenId, _salePrice);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        // Example: Royalties go to the contract itself - can be modified to creator/artist etc.
        receiver = address(this);
        royaltyAmount = (_salePrice * royaltyPercentage) / 10000;
    }


    // ==== Task & Bounty System ====

    function submitTask(string memory _taskDescription, string[] memory _requiredSkills, uint256 _bounty) public payable whenNotPaused {
        require(msg.value >= _bounty, "Bounty amount must be sent with task submission.");
        tasks[nextTaskId] = Task({
            creator: msg.sender,
            description: _taskDescription,
            requiredSkills: _requiredSkills,
            bounty: _bounty,
            assignedTo: address(0),
            completed: false,
            approved: false
        });
        payable(address(this)).transfer(msg.value); // Contract holds the bounty
        emit TaskSubmitted(nextTaskId, msg.sender);
        nextTaskId++;
    }

    function bidOnTask(uint256 _taskId) public whenNotPaused {
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot bid on their own task.");
        require(tasks[_taskId].assignedTo == address(0), "Task already assigned.");
        require(!taskBids[_taskId][msg.sender], "Already bid on this task."); // Prevent double bidding
        taskBids[_taskId][msg.sender] = true;
        emit TaskBidSubmitted(_taskId, msg.sender);
    }

    function acceptBid(uint256 _taskId, address _bidder) public whenNotPaused {
        require(msg.sender == tasks[_taskId].creator, "Only task creator can accept bids.");
        require(taskBids[_taskId][_bidder], "Bidder must have placed a bid.");
        require(tasks[_taskId].assignedTo == address(0), "Task already assigned.");
        tasks[_taskId].assignedTo = _bidder;
        emit TaskBidAccepted(_taskId, msg.sender, _bidder);
    }

    function completeTask(uint256 _taskId) public whenNotPaused {
        require(msg.sender == tasks[_taskId].assignedTo, "Only assigned user can complete the task.");
        require(!tasks[_taskId].completed, "Task already marked as completed.");
        tasks[_taskId].completed = true;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function reviewTaskCompletion(uint256 _taskId, bool _approved) public whenNotPaused {
        require(msg.sender == tasks[_taskId].creator, "Only task creator can review completion.");
        require(tasks[_taskId].completed, "Task must be marked as completed to review.");
        require(!tasks[_taskId].approved, "Task already reviewed."); // Prevent double review
        tasks[_taskId].approved = _approved;
        if (_approved) {
            increaseReputation(tasks[_taskId].assignedTo, 50); // Example reputation reward for successful task completion
        } else {
            decreaseReputation(tasks[_taskId].assignedTo, 20); // Example reputation penalty for failed task (optional)
        }
        emit TaskReviewed(_taskId, msg.sender, _approved);
    }

    function withdrawBounty(uint256 _taskId) public whenNotPaused {
        require(tasks[_taskId].approved, "Task completion must be approved to withdraw bounty.");
        require(msg.sender == tasks[_taskId].assignedTo, "Only assigned user can withdraw bounty.");
        require(tasks[_taskId].bounty > 0, "No bounty available for withdrawal.");
        uint256 bountyAmount = tasks[_taskId].bounty;
        tasks[_taskId].bounty = 0; // Prevent double withdrawal (optional - could also remove bounty from struct on withdraw)
        payable(msg.sender).transfer(bountyAmount);
    }

    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }


    // ==== Content Moderation (Simplified Reputation-Weighted Voting) ====

    function voteForModeration(uint256 _contentId, bool _upvote) public whenNotPaused {
        if (contentModeration[_contentId].flagged) {
            return; // Cannot vote on already flagged content
        }
        uint256 reputationWeight = getUserReputation(msg.sender) / 100; // Example weight, adjust as needed
        if (_upvote) {
            contentModeration[_contentId].upvotes += reputationWeight + 1; // Add at least 1 vote + reputation weight
        } else {
            contentModeration[_contentId].downvotes += reputationWeight + 1;
        }
        emit ContentModerationVote(_contentId, msg.sender, _upvote);
        _checkModerationThreshold(_contentId); // Check if content should be flagged after voting
    }

    function reportContent(uint256 _contentId, string memory _reason) public whenNotPaused {
        contentModeration[nextContentId].reportReason = _reason; // Basic report, can be expanded
        emit ContentReported(_contentId, msg.sender, _reason);
        // In a real system, reporting would trigger further moderation processes
    }

    function _checkModerationThreshold(uint256 _contentId) internal {
        if (contentModeration[_contentId].upvotes < contentModeration[_contentId].downvotes * 2) { // Example ratio for flagging
            contentModeration[_contentId].flagged = true;
            // Implement actions for flagged content - e.g., hide content, notify admins, etc.
        }
    }


    // ==== Pause Function ====

    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }

    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }

    // ==== Reputation Boost Feature Example (NFT Staking) ====

    function getStakedNFTCount(address _user) public view returns (uint256) {
        return stakedNFTCount[_user];
    }

    function stakeNFTForReputationBoost(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!stakedNFTs[msg.sender][_tokenId], "NFT already staked.");
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(ownerOf(_tokenId), address(this)), "Contract not approved to transfer NFT.");

        _safeTransferFrom(msg.sender, address(this), _tokenId); // Transfer NFT to contract for staking
        stakedNFTs[msg.sender][_tokenId] = true;
        stakedNFTCount[msg.sender]++;
        emit NFTStaked(msg.sender, _tokenId);
        // Optionally increase reputation immediately upon staking, or adjust reputation gain rates while staked
    }

    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(stakedNFTs[msg.sender][_tokenId], "NFT not staked.");
        delete stakedNFTs[msg.sender][_tokenId];
        stakedNFTCount[msg.sender]--;
        _safeTransferFrom(address(this), msg.sender, _tokenId); // Return NFT to owner
        emit NFTUnstaked(msg.sender, _tokenId);
        // Optionally decrease reputation upon unstaking, or adjust reputation gain rates after unstaking
    }

    // ==== Fallback and Receive (for bounty payments) ====

    receive() external payable {}
    fallback() external payable {}
}
```