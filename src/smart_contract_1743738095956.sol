```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a decentralized platform that manages dynamic content access, reputation-based rewards,
 *         and community governance. This contract implements advanced concepts such as conditional content releases,
 *         reputation-based access control, dynamic pricing, decentralized moderation, and community-driven features.
 *
 * Function Summary:
 *
 * ### Content Management & Access Control
 * 1.  `createContent(string memory _contentHash, uint256 _basePrice, uint256 _releaseTimestamp)`: Allows platform owner to create new content with a hash, base price, and release timestamp.
 * 2.  `setContentDynamicPrice(uint256 _contentId, uint256 _newPrice, uint256 _reputationThresholdForDiscount)`: Sets a dynamic price for content, potentially based on user reputation.
 * 3.  `purchaseContent(uint256 _contentId)`: Allows users to purchase access to content, handling dynamic pricing and reputation discounts.
 * 4.  `accessContent(uint256 _contentId)`: Checks if a user has purchased content and returns the content hash if access is granted.
 * 5.  `setContentReleaseCondition(uint256 _contentId, uint256 _requiredReputation, uint256 _requiredPurchases)`: Sets conditions (reputation, purchases) for content release, making it dynamically accessible.
 * 6.  `updateContentReleaseTimestamp(uint256 _contentId, uint256 _newTimestamp)`: Updates the release timestamp for content that hasn't been released yet.
 *
 * ### Reputation & Reward System
 * 7.  `contributeToContent(uint256 _contentId, string memory _contributionHash)`: Allows users to contribute to content (e.g., translations, enhancements), earning reputation points.
 * 8.  `reportContent(uint256 _contentId, string memory _reportReason)`: Allows users to report content for moderation, influencing reputation of content creators/moderators.
 * 9.  `upvoteContribution(uint256 _contentId, uint256 _contributionIndex)`: Allows users to upvote contributions, further rewarding contributors with reputation.
 * 10. `downvoteContribution(uint256 _contentId, uint256 _contributionIndex)`: Allows users to downvote contributions, potentially reducing contributor reputation.
 * 11. `setReputationRewardForContribution(uint256 _reputationPoints)`: Platform owner can set the reputation points awarded for content contributions.
 * 12. `setReputationPenaltyForReport(uint256 _reputationPoints)`: Platform owner can set the reputation penalty for submitting false content reports.
 *
 * ### Community Governance & Platform Features
 * 13. `proposeGovernanceChange(string memory _proposalDescription, bytes memory _proposalData)`: Allows users with sufficient reputation to propose changes to platform parameters.
 * 14. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows users with voting power (based on reputation or content ownership) to vote on governance proposals.
 * 15. `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal if it reaches the required quorum and support.
 * 16. `setGovernanceVotingThreshold(uint256 _thresholdPercentage)`: Platform owner can set the voting threshold required for governance proposals to pass.
 * 17. `setVotingPowerBasedOnContentOwnership(bool _enabled)`: Platform owner can toggle if voting power is also based on content owned, not just reputation.
 * 18. `withdrawPlatformFees(address payable _recipient)`: Platform owner can withdraw accumulated platform fees.
 * 19. `pauseContract()`: Allows platform owner to pause contract operations in case of emergency.
 * 20. `unpauseContract()`: Allows platform owner to unpause contract operations.
 * 21. `getContentDetails(uint256 _contentId)`: Returns detailed information about a specific content item.
 * 22. `getUserReputation(address _user)`: Returns the reputation score of a specific user.
 *
 */
contract DecentralizedDynamicContentPlatform {
    address public owner;
    bool public paused;

    // --- Data Structures ---

    struct Content {
        string contentHash;
        uint256 basePrice;
        uint256 dynamicPrice;
        uint256 reputationThresholdForDiscount;
        uint256 releaseTimestamp;
        uint256 requiredReputationForRelease;
        uint256 requiredPurchasesForRelease;
        bool released;
        mapping(uint256 => Contribution) contributions; // Contributions to this content
        uint256 contributionCount;
    }

    struct Contribution {
        address contributor;
        string contributionHash;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct GovernanceProposal {
        string description;
        bytes proposalData; // Encoded data for contract function calls
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }

    mapping(uint256 => Content) public contentRegistry;
    uint256 public contentCount;

    mapping(address => uint256) public userReputation;
    mapping(address => mapping(uint256 => bool)) public contentPurchased; // User -> ContentId -> Purchased
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalCount;

    uint256 public reputationRewardForContribution = 10;
    uint256 public reputationPenaltyForReport = 5;
    uint256 public governanceVotingThresholdPercentage = 51; // Default 51% for simple majority
    bool public votingPowerBasedOnContentOwnershipEnabled = false;

    uint256 public platformFeePercentage = 5; // 5% platform fee on content purchases

    // --- Events ---
    event ContentCreated(uint256 contentId, string contentHash, uint256 basePrice, uint256 releaseTimestamp);
    event ContentPriceUpdated(uint256 contentId, uint256 newPrice, uint256 reputationThreshold);
    event ContentPurchased(uint256 contentId, address buyer, uint256 pricePaid);
    event ContentAccessed(uint256 contentId, address user);
    event ContentReleaseConditionsSet(uint256 contentId, uint256 reputation, uint256 purchases);
    event ContentReleaseTimestampUpdated(uint256 contentId, uint256 newTimestamp);
    event ContributionSubmitted(uint256 contentId, uint256 contributionIndex, address contributor, string contributionHash);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContributionUpvoted(uint256 contentId, uint256 contributionIndex, address voter);
    event ContributionDownvoted(uint256 contentId, uint256 contributionIndex, address voter);
    event ReputationRewardSet(uint256 reputationPoints);
    event ReputationPenaltySet(uint256 reputationPoints);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceVotingThresholdUpdated(uint256 thresholdPercentage);
    event VotingPowerContentOwnershipToggled(bool enabled);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
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

    modifier contentExists(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCount, "Content does not exist.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
    }

    // --- Content Management & Access Control Functions ---

    /// @notice Creates new content on the platform. Only the owner can call this function.
    /// @param _contentHash IPFS hash or similar identifier for the content.
    /// @param _basePrice Base price for accessing the content in wei.
    /// @param _releaseTimestamp Unix timestamp for when the content should be released.
    function createContent(string memory _contentHash, uint256 _basePrice, uint256 _releaseTimestamp) external onlyOwner whenNotPaused {
        contentCount++;
        contentRegistry[contentCount] = Content({
            contentHash: _contentHash,
            basePrice: _basePrice,
            dynamicPrice: _basePrice, // Initially dynamic price is the base price
            reputationThresholdForDiscount: 0, // No discount initially
            releaseTimestamp: _releaseTimestamp,
            requiredReputationForRelease: 0,
            requiredPurchasesForRelease: 0,
            released: false,
            contributionCount: 0
        });
        emit ContentCreated(contentCount, _contentHash, _basePrice, _releaseTimestamp);
    }

    /// @notice Sets a dynamic price for content, potentially offering discounts based on user reputation. Only the owner can call this function.
    /// @param _contentId ID of the content to update.
    /// @param _newPrice New dynamic price for the content in wei.
    /// @param _reputationThresholdForDiscount Reputation score required to get the dynamic price.
    function setContentDynamicPrice(uint256 _contentId, uint256 _newPrice, uint256 _reputationThresholdForDiscount) external onlyOwner contentExists(_contentId) whenNotPaused {
        contentRegistry[_contentId].dynamicPrice = _newPrice;
        contentRegistry[_contentId].reputationThresholdForDiscount = _reputationThresholdForDiscount;
        emit ContentPriceUpdated(_contentId, _newPrice, _reputationThresholdForDiscount);
    }

    /// @notice Allows a user to purchase access to content. Handles dynamic pricing based on reputation and platform fees.
    /// @param _contentId ID of the content to purchase.
    function purchaseContent(uint256 _contentId) external payable contentExists(_contentId) whenNotPaused {
        require(!contentPurchased[msg.sender][_contentId], "You have already purchased this content.");
        require(block.timestamp >= contentRegistry[_contentId].releaseTimestamp || contentRegistry[_contentId].released, "Content is not yet released.");

        uint256 priceToPay = contentRegistry[_contentId].dynamicPrice;
        if (userReputation[msg.sender] >= contentRegistry[_contentId].reputationThresholdForDiscount) {
            priceToPay = contentRegistry[_contentId].dynamicPrice; // Dynamic price is already set, no further discount logic here.
        } else {
            priceToPay = contentRegistry[_contentId].basePrice; // Fallback to base price if reputation is below threshold
        }

        require(msg.value >= priceToPay, "Insufficient payment sent.");

        uint256 platformFee = (priceToPay * platformFeePercentage) / 100;
        uint256 creatorEarnings = priceToPay - platformFee;

        payable(owner).transfer(platformFee); // Platform fee goes to owner
        // In a real application, creator earnings should be handled more robustly (e.g., creator address stored in Content struct).
        // For simplicity, we assume owner is also the content creator in this example.
        payable(owner).transfer(creatorEarnings); // Creator earnings (simplified to owner in this example)


        contentPurchased[msg.sender][_contentId] = true;
        emit ContentPurchased(_contentId, msg.sender, priceToPay);
    }

    /// @notice Allows a user to access content they have purchased. Returns the content hash if access is granted.
    /// @param _contentId ID of the content to access.
    /// @return contentHash String representing the content hash.
    function accessContent(uint256 _contentId) external view contentExists(_contentId) whenNotPaused returns (string memory contentHash) {
        require(contentPurchased[msg.sender][_contentId], "You have not purchased this content.");
        require(block.timestamp >= contentRegistry[_contentId].releaseTimestamp || contentRegistry[_contentId].released, "Content is not yet released.");
        emit ContentAccessed(_contentId, msg.sender);
        return contentRegistry[_contentId].contentHash;
    }

    /// @notice Sets conditions for content release based on reputation and number of purchases. Owner only.
    /// @param _contentId ID of the content to modify.
    /// @param _requiredReputation Reputation needed for content to be released.
    /// @param _requiredPurchases Number of purchases needed for content to be released.
    function setContentReleaseCondition(uint256 _contentId, uint256 _requiredReputation, uint256 _requiredPurchases) external onlyOwner contentExists(_contentId) whenNotPaused {
        contentRegistry[_contentId].requiredReputationForRelease = _requiredReputation;
        contentRegistry[_contentId].requiredPurchasesForRelease = _requiredPurchases;
        emit ContentReleaseConditionsSet(_contentId, _requiredReputation, _requiredPurchases);
    }

    /// @notice Updates the release timestamp for content that hasn't been released yet. Owner only.
    /// @param _contentId ID of the content to modify.
    /// @param _newTimestamp New Unix timestamp for content release.
    function updateContentReleaseTimestamp(uint256 _contentId, uint256 _newTimestamp) external onlyOwner contentExists(_contentId) whenNotPaused {
        require(!contentRegistry[_contentId].released, "Cannot update release timestamp for already released content.");
        contentRegistry[_contentId].releaseTimestamp = _newTimestamp;
        emit ContentReleaseTimestampUpdated(_contentId, _newTimestamp);
    }

    // --- Reputation & Reward System Functions ---

    /// @notice Allows users to contribute to content, earning reputation points.
    /// @param _contentId ID of the content being contributed to.
    /// @param _contributionHash IPFS hash of the contribution.
    function contributeToContent(uint256 _contentId, string memory _contributionHash) external contentExists(_contentId) whenNotPaused {
        uint256 contributionIndex = contentRegistry[_contentId].contributionCount;
        contentRegistry[_contentId].contributions[contributionIndex] = Contribution({
            contributor: msg.sender,
            contributionHash: _contributionHash,
            upvotes: 0,
            downvotes: 0
        });
        contentRegistry[_contentId].contributionCount++;
        userReputation[msg.sender] += reputationRewardForContribution;
        emit ContributionSubmitted(_contentId, contributionIndex, msg.sender, _contributionHash);
    }

    /// @notice Allows users to report content for moderation.
    /// @param _contentId ID of the content being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _contentId, string memory _reportReason) external contentExists(_contentId) whenNotPaused {
        // In a real application, implement moderation logic here.
        // For simplicity, this just emits an event and potentially reduces reporter reputation if misused.
        // Advanced moderation could involve voting, designated moderators, etc.

        // Simple penalty for reporting (can be adjusted/removed) - to discourage frivolous reports
        userReputation[msg.sender] -= reputationPenaltyForReport;
        if (userReputation[msg.sender] < 0) {
            userReputation[msg.sender] = 0; // Reputation cannot be negative
        }

        emit ContentReported(_contentId, msg.sender, _reportReason);
    }

    /// @notice Allows users to upvote a contribution to content.
    /// @param _contentId ID of the content.
    /// @param _contributionIndex Index of the contribution within the content.
    function upvoteContribution(uint256 _contentId, uint256 _contributionIndex) external contentExists(_contentId) whenNotPaused {
        require(contentRegistry[_contentId].contributions[_contributionIndex].contributor != address(0), "Contribution does not exist.");
        contentRegistry[_contentId].contributions[_contributionIndex].upvotes++;
        // Optionally, reward the contributor for upvotes (e.g., more reputation).
        emit ContributionUpvoted(_contentId, _contributionIndex, msg.sender);
    }

    /// @notice Allows users to downvote a contribution to content.
    /// @param _contentId ID of the content.
    /// @param _contributionIndex Index of the contribution within the content.
    function downvoteContribution(uint256 _contentId, uint256 _contributionIndex) external contentExists(_contentId) whenNotPaused {
        require(contentRegistry[_contentId].contributions[_contributionIndex].contributor != address(0), "Contribution does not exist.");
        contentRegistry[_contentId].contributions[_contributionIndex].downvotes++;
        // Optionally, penalize the contributor for downvotes (e.g., less reputation).
        emit ContributionDownvoted(_contentId, _contributionIndex, msg.sender);
    }

    /// @notice Sets the reputation points awarded for contributing to content. Owner only.
    /// @param _reputationPoints Number of reputation points to award.
    function setReputationRewardForContribution(uint256 _reputationPoints) external onlyOwner whenNotPaused {
        reputationRewardForContribution = _reputationPoints;
        emit ReputationRewardSet(_reputationPoints);
    }

    /// @notice Sets the reputation penalty for submitting false content reports. Owner only.
    /// @param _reputationPoints Number of reputation points to penalize.
    function setReputationPenaltyForReport(uint256 _reputationPoints) external onlyOwner whenNotPaused {
        reputationPenaltyForReport = _reputationPoints;
        emit ReputationPenaltySet(_reputationPoints);
    }

    // --- Community Governance & Platform Features Functions ---

    /// @notice Allows users with sufficient reputation to propose governance changes.
    /// @param _proposalDescription Text description of the proposal.
    /// @param _proposalData Encoded data to be executed if the proposal passes (e.g., function signature and parameters).
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _proposalData) external whenNotPaused {
        require(userReputation[msg.sender] >= 50, "Insufficient reputation to propose governance changes."); // Example reputation threshold for proposing
        proposalCount++;
        governanceProposals[proposalCount] = GovernanceProposal({
            description: _proposalDescription,
            proposalData: _proposalData,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });
        emit GovernanceProposalCreated(proposalCount, msg.sender, _proposalDescription);
    }

    /// @notice Allows users to vote on active governance proposals. Voting power can be based on reputation and/or content ownership.
    /// @param _proposalId ID of the governance proposal to vote on.
    /// @param _support Boolean indicating support (true) or opposition (false) to the proposal.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(governanceProposals[_proposalId].startTime != 0, "Proposal does not exist.");
        require(block.timestamp >= governanceProposals[_proposalId].startTime && block.timestamp <= governanceProposals[_proposalId].endTime, "Voting is not active for this proposal.");

        // In a real application, track voters to prevent double voting per proposal.
        // For simplicity, this example does not implement voter tracking.

        uint256 votingPower = userReputation[msg.sender];
        if (votingPowerBasedOnContentOwnershipEnabled) {
            // Example: 1 vote per content owned. In a real app, track content ownership more precisely.
            // For simplicity, assuming contentCount represents a rough proxy for "platform activity/ownership"
            votingPower += contentCount / 100; // Scale down content count to reasonable voting power contribution
        }

        if (_support) {
            governanceProposals[_proposalId].votesFor += votingPower;
        } else {
            governanceProposals[_proposalId].votesAgainst += votingPower;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal if it has passed the voting threshold. Owner or anyone can trigger execution after voting period.
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused {
        require(governanceProposals[_proposalId].startTime != 0, "Proposal does not exist.");
        require(block.timestamp > governanceProposals[_proposalId].endTime, "Voting period is not over.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = governanceProposals[_proposalId].votesFor + governanceProposals[_proposalId].votesAgainst;
        uint256 requiredVotes = (totalVotes * governanceVotingThresholdPercentage) / 100;

        if (governanceProposals[_proposalId].votesFor >= requiredVotes) {
            (bool success, ) = address(this).call(governanceProposals[_proposalId].proposalData); // Execute proposal data
            require(success, "Governance proposal execution failed.");
            governanceProposals[_proposalId].executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            revert("Governance proposal did not pass voting threshold.");
        }
    }

    /// @notice Sets the percentage threshold required for governance proposals to pass. Owner only.
    /// @param _thresholdPercentage Percentage (e.g., 51 for 51%).
    function setGovernanceVotingThreshold(uint256 _thresholdPercentage) external onlyOwner whenNotPaused {
        require(_thresholdPercentage > 0 && _thresholdPercentage <= 100, "Invalid voting threshold percentage.");
        governanceVotingThresholdPercentage = _thresholdPercentage;
        emit GovernanceVotingThresholdUpdated(_thresholdPercentage);
    }

    /// @notice Enables or disables voting power based on content ownership (in addition to reputation). Owner only.
    /// @param _enabled True to enable content ownership based voting power, false to disable.
    function setVotingPowerBasedOnContentOwnership(bool _enabled) external onlyOwner whenNotPaused {
        votingPowerBasedOnContentOwnershipEnabled = _enabled;
        emit VotingPowerContentOwnershipToggled(_enabled);
    }


    /// @notice Allows the platform owner to withdraw accumulated platform fees. Owner only.
    /// @param _recipient Address to which the fees should be withdrawn.
    function withdrawPlatformFees(address payable _recipient) external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance; // Simplification: withdraw all balance. In real app, track platform fees separately.
        require(withdrawableAmount > 0, "No platform fees to withdraw.");
        (bool success, ) = _recipient.call{value: withdrawableAmount}("");
        require(success, "Withdrawal failed.");
        emit PlatformFeesWithdrawn(_recipient, withdrawableAmount);
    }


    // --- Utility & Admin Functions ---

    /// @notice Pauses the contract, preventing most operations. Owner only.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, resuming normal operations. Owner only.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Gets detailed information about a specific content item.
    /// @param _contentId ID of the content.
    /// @return content Details of the content.
    function getContentDetails(uint256 _contentId) external view contentExists(_contentId) whenNotPaused returns (Content memory content) {
        return contentRegistry[_contentId];
    }

    /// @notice Gets the reputation score of a specific user.
    /// @param _user Address of the user.
    /// @return reputation User's reputation score.
    function getUserReputation(address _user) external view whenNotPaused returns (uint256 reputation) {
        return userReputation[_user];
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```