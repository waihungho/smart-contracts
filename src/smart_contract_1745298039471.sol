```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill-Based Community Platform with Dynamic Reputation and Governance
 * @author Bard (Example Contract - Not for Production)
 * @dev This contract outlines a platform where users can offer and request skills, build reputation,
 *      participate in community governance, and engage in decentralized dispute resolution.
 *      It incorporates dynamic reputation based on endorsements, community-driven rule proposals,
 *      and a voting mechanism for dispute resolution.
 *
 * Function Summary:
 * -----------------
 * User Management:
 * 1. createUserProfile(string _username, string _bio) - Allows users to create a profile.
 * 2. updateUserProfile(string _bio) - Allows users to update their profile bio.
 * 3. getUserProfile(address _user) view returns (string username, string bio, uint256 reputation) - Retrieves user profile information.
 * 4. isRegisteredUser(address _user) view returns (bool) - Checks if an address is a registered user.
 *
 * Skill Management:
 * 5. addSkillCategory(string _categoryName) - Allows platform owner to add skill categories.
 * 6. addSkill(uint256 _categoryId, string _skillName) - Allows platform owner to add skills under a category.
 * 7. getSkillCategories() view returns (string[] categoryNames) - Retrieves all skill category names.
 * 8. getSkillsInCategory(uint256 _categoryId) view returns (string[] skillNames) - Retrieves skills within a specific category.
 *
 * Job/Task Management (Skill Offers & Requests):
 * 9. createSkillOffer(string _title, string _description, uint256 _skillCategoryId, uint256 _skillId, uint256 _price) payable - Users offer their skills for a price.
 * 10. createSkillRequest(string _title, string _description, uint256 _skillCategoryId, uint256 _skillId, uint256 _budget) payable - Users request skills with a budget.
 * 11. acceptSkillRequest(uint256 _requestId) - Users (skill providers) accept a skill request.
 * 12. completeSkillOffer(uint256 _offerId) - User (skill provider) marks a skill offer as completed.
 * 13. completeSkillRequest(uint256 _requestId) - User (skill requester) marks a skill request as completed and pays the provider.
 * 14. reportIssue(uint256 _jobId, string _reportDescription) - Users report an issue with a skill offer or request.
 *
 * Reputation & Endorsement:
 * 15. endorseSkill(address _userToEndorse, uint256 _skillId) - Users endorse another user for a specific skill, increasing their reputation.
 * 16. getReputation(address _user) view returns (uint256) - Retrieves the reputation score of a user.
 *
 * Governance & Platform Rules:
 * 17. proposeNewRule(string _ruleDescription) - Registered users can propose new platform rules.
 * 18. voteOnRuleProposal(uint256 _proposalId, bool _vote) - Registered users can vote on rule proposals.
 * 19. executeRuleProposal(uint256 _proposalId) - Platform owner executes an approved rule proposal.
 *
 * Dispute Resolution (Decentralized):
 * 20. openDispute(uint256 _jobId, string _disputeDescription) - Users open a dispute for a job.
 * 21. voteOnDispute(uint256 _disputeId, bool _resolutionFavorRequester) - Registered users vote on dispute resolution, favoring requester or provider.
 * 22. resolveDispute(uint256 _disputeId) - Platform owner executes the dispute resolution based on community vote.
 *
 * Platform Settings:
 * 23. setPlatformFee(uint256 _feePercentage) - Allows platform owner to set a platform fee percentage.
 * 24. withdrawPlatformFees() - Allows platform owner to withdraw accumulated platform fees.
 */

contract SkillCommunityPlatform {
    // State Variables

    // Platform Owner
    address public owner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public accumulatedPlatformFees;

    // User Profiles
    struct UserProfile {
        string username;
        string bio;
        uint256 reputation;
        bool isRegistered;
    }
    mapping(address => UserProfile) public userProfiles;
    address[] public registeredUsers;

    // Skill Categories and Skills
    string[] public skillCategories;
    mapping(uint256 => string[]) public skillsInCategory;
    uint256 public nextCategoryId = 1; // Start category IDs from 1

    // Skill Offers
    struct SkillOffer {
        uint256 offerId;
        address provider;
        string title;
        string description;
        uint256 skillCategoryId;
        uint256 skillId;
        uint256 price;
        bool isCompleted;
        uint256 createdAt;
    }
    mapping(uint256 => SkillOffer) public skillOffers;
    uint256 public offerIdCounter;

    // Skill Requests
    struct SkillRequest {
        uint256 requestId;
        address requester;
        address provider; // Assigned provider after acceptance
        string title;
        string description;
        uint256 skillCategoryId;
        uint256 skillId;
        uint256 budget;
        bool isCompleted;
        uint256 createdAt;
        RequestStatus status;
    }
    enum RequestStatus { Open, Accepted, Completed, Disputed }
    mapping(uint256 => SkillRequest) public skillRequests;
    uint256 public requestIdCounter;

    // Reputation System
    mapping(address => mapping(uint256 => bool)) public skillEndorsements; // user => skillId => endorsed?

    // Governance - Rule Proposals
    struct RuleProposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        uint256 createdAt;
    }
    mapping(uint256 => RuleProposal) public ruleProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => user => votedFor?
    uint256 public proposalIdCounter;
    uint256 public ruleProposalVoteDuration = 7 days; // 7 days for voting
    uint256 public ruleProposalQuorumPercentage = 20; // 20% of registered users quorum

    // Dispute Resolution
    struct Dispute {
        uint256 disputeId;
        uint256 jobId; // Offer or Request ID
        address reporter;
        string description;
        uint256 votesForRequester;
        uint256 votesForProvider;
        bool isResolved;
        DisputeResolution resolution;
        uint256 createdAt;
    }
    enum DisputeResolution { Pending, FavorRequester, FavorProvider, PlatformDecision }
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public disputeVotes; // disputeId => user => votedForRequester?
    uint256 public disputeIdCounter;
    uint256 public disputeVoteDuration = 3 days; // 3 days for voting
    uint256 public disputeQuorumPercentage = 15; // 15% of registered users quorum

    // Events
    event UserProfileCreated(address user, string username);
    event UserProfileUpdated(address user, string bio);
    event SkillCategoryAdded(uint256 categoryId, string categoryName);
    event SkillAdded(uint256 categoryId, uint256 skillId, string skillName);
    event SkillOfferCreated(uint256 offerId, address provider, string title);
    event SkillRequestCreated(uint256 requestId, address requester, string title);
    event SkillRequestAccepted(uint256 requestId, address provider);
    event SkillOfferCompleted(uint256 offerId, address provider);
    event SkillRequestCompleted(uint256 requestId, address requester, address provider, uint256 amountPaid);
    event IssueReported(uint256 jobId, address reporter, string description);
    event SkillEndorsed(address endorser, address endorsedUser, uint256 skillId);
    event RuleProposalCreated(uint256 proposalId, address proposer, string description);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleProposalExecuted(uint256 proposalId);
    event DisputeOpened(uint256 disputeId, uint256 jobId, address reporter, string description);
    event DisputeVoted(uint256 disputeId, address voter, bool voteForRequester);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(_msgSender() == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isRegisteredUser(_msgSender()), "You must be a registered user to perform this action.");
        _;
    }

    modifier validCategoryId(uint256 _categoryId) {
        require(_categoryId > 0 && _categoryId <= skillCategories.length, "Invalid skill category ID.");
        _;
    }

    modifier validSkillId(uint256 _categoryId, uint256 _skillId) {
        require(_skillId > 0 && _skillId <= skillsInCategory[_categoryId].length, "Invalid skill ID.");
        _;
        _;
    }

    modifier validOfferId(uint256 _offerId) {
        require(skillOffers[_offerId].offerId == _offerId, "Invalid skill offer ID.");
        _;
    }

    modifier validRequestId(uint256 _requestId) {
        require(skillRequests[_requestId].requestId == _requestId, "Invalid skill request ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(ruleProposals[_proposalId].proposalId == _proposalId, "Invalid rule proposal ID.");
        _;
    }

    modifier validDisputeId(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId == _disputeId, "Invalid dispute ID.");
        _;
    }


    // Constructor
    constructor() {
        owner = _msgSender();
        addSkillCategory("Technology"); // Initialize with a default category
        addSkillCategory("Design");
        addSkillCategory("Writing & Translation");
        addSkillCategory("Business");
        addSkill(1, "Web Development"); // Example skill in Technology
        addSkill(1, "Mobile App Development");
        addSkill(2, "Graphic Design"); // Example skill in Design
        addSkill(2, "UI/UX Design");
        addSkill(3, "Content Writing"); // Example skill in Writing & Translation
        addSkill(3, "Translation");
        addSkill(4, "Marketing Strategy"); // Example skill in Business
        addSkill(4, "Financial Consulting");
    }

    // ------------------------ User Management ------------------------

    function createUserProfile(string memory _username, string memory _bio) external {
        require(!isRegisteredUser(_msgSender()), "User profile already exists.");
        userProfiles[_msgSender()] = UserProfile({
            username: _username,
            bio: _bio,
            reputation: 0,
            isRegistered: true
        });
        registeredUsers.push(_msgSender());
        emit UserProfileCreated(_msgSender(), _username);
    }

    function updateUserProfile(string memory _bio) external onlyRegisteredUser {
        userProfiles[_msgSender()].bio = _bio;
        emit UserProfileUpdated(_msgSender(), _bio);
    }

    function getUserProfile(address _user) external view returns (string memory username, string memory bio, uint256 reputation) {
        UserProfile storage profile = userProfiles[_user];
        require(profile.isRegistered, "User profile not found.");
        return (profile.username, profile.bio, profile.reputation);
    }

    function isRegisteredUser(address _user) public view returns (bool) {
        return userProfiles[_user].isRegistered;
    }

    // ------------------------ Skill Management ------------------------

    function addSkillCategory(string memory _categoryName) public onlyOwner {
        skillCategories.push(_categoryName);
        emit SkillCategoryAdded(nextCategoryId, _categoryName);
        nextCategoryId++;
    }

    function addSkill(uint256 _categoryId, string memory _skillName) public onlyOwner validCategoryId(_categoryId) {
        skillsInCategory[_categoryId].push(_skillName);
        emit SkillAdded(_categoryId, skillsInCategory[_categoryId].length, _skillName);
    }

    function getSkillCategories() external view returns (string[] memory categoryNames) {
        return skillCategories;
    }

    function getSkillsInCategory(uint256 _categoryId) external view validCategoryId(_categoryId) returns (string[] memory skillNames) {
        return skillsInCategory[_categoryId];
    }

    // ------------------------ Job/Task Management (Skill Offers & Requests) ------------------------

    function createSkillOffer(
        string memory _title,
        string memory _description,
        uint256 _skillCategoryId,
        uint256 _skillId,
        uint256 _price
    ) external payable onlyRegisteredUser validCategoryId(_skillCategoryId) validSkillId(_skillCategoryId, _skillId) {
        offerIdCounter++;
        skillOffers[offerIdCounter] = SkillOffer({
            offerId: offerIdCounter,
            provider: _msgSender(),
            title: _title,
            description: _description,
            skillCategoryId: _skillCategoryId,
            skillId: _skillId,
            price: _price,
            isCompleted: false,
            createdAt: block.timestamp
        });
        emit SkillOfferCreated(offerIdCounter, _msgSender(), _title);
    }

    function createSkillRequest(
        string memory _title,
        string memory _description,
        uint256 _skillCategoryId,
        uint256 _skillId,
        uint256 _budget
    ) external payable onlyRegisteredUser validCategoryId(_skillCategoryId) validSkillId(_skillCategoryId, _skillId) {
        require(msg.value >= _budget, "Insufficient funds sent to cover the budget.");
        requestIdCounter++;
        skillRequests[requestIdCounter] = SkillRequest({
            requestId: requestIdCounter,
            requester: _msgSender(),
            provider: address(0), // Initially no provider assigned
            title: _title,
            description: _description,
            skillCategoryId: _skillCategoryId,
            skillId: _skillId,
            budget: _budget,
            isCompleted: false,
            createdAt: block.timestamp,
            status: RequestStatus.Open
        });
        emit SkillRequestCreated(requestIdCounter, _msgSender(), _title);
    }

    function acceptSkillRequest(uint256 _requestId) external onlyRegisteredUser validRequestId(_requestId) {
        SkillRequest storage request = skillRequests[_requestId];
        require(request.status == RequestStatus.Open, "Request is not open for acceptance.");
        require(request.requester != _msgSender(), "Requester cannot accept their own request.");
        request.provider = _msgSender();
        request.status = RequestStatus.Accepted;
        emit SkillRequestAccepted(_requestId, _msgSender());
    }

    function completeSkillOffer(uint256 _offerId) external onlyRegisteredUser validOfferId(_offerId) {
        SkillOffer storage offer = skillOffers[_offerId];
        require(offer.provider == _msgSender(), "Only the skill provider can complete the offer.");
        require(!offer.isCompleted, "Offer already completed.");
        offer.isCompleted = true;
        emit SkillOfferCompleted(_offerId, _msgSender());
    }

    function completeSkillRequest(uint256 _requestId) external payable onlyRegisteredUser validRequestId(_requestId) {
        SkillRequest storage request = skillRequests[_requestId];
        require(request.requester == _msgSender(), "Only the skill requester can complete the request.");
        require(request.status == RequestStatus.Accepted, "Request must be accepted before completion.");
        require(!request.isCompleted, "Request already completed.");
        require(msg.value >= request.budget, "Insufficient funds sent to complete the request.");

        uint256 platformFee = (request.budget * platformFeePercentage) / 100;
        uint256 providerPayment = request.budget - platformFee;

        // Transfer payment to provider and platform fee to contract
        payable(request.provider).transfer(providerPayment);
        accumulatedPlatformFees += platformFee;
        request.isCompleted = true;
        request.status = RequestStatus.Completed;

        emit SkillRequestCompleted(_requestId, _msgSender(), request.provider, providerPayment);
    }

    function reportIssue(uint256 _jobId, string memory _reportDescription) external onlyRegisteredUser {
        // Assuming _jobId can be either offerId or requestId (needs better job ID handling in a real system)
        emit IssueReported(_jobId, _msgSender(), _reportDescription);
        // In a real system, you'd likely want to store issue reports and trigger a dispute process.
    }

    // ------------------------ Reputation & Endorsement ------------------------

    function endorseSkill(address _userToEndorse, uint256 _skillId) external onlyRegisteredUser validSkillId(skillOffers[1].skillCategoryId, _skillId) { //Simplified skill category validation, adjust as needed
        require(_userToEndorse != _msgSender(), "You cannot endorse yourself.");
        require(!skillEndorsements[_msgSender()][_skillId], "You have already endorsed this user for this skill.");

        skillEndorsements[_msgSender()][_skillId] = true;
        userProfiles[_userToEndorse].reputation++; // Simple reputation increase
        emit SkillEndorsed(_msgSender(), _userToEndorse, _skillId);
    }

    function getReputation(address _user) external view returns (uint256) {
        return userProfiles[_user].reputation;
    }

    // ------------------------ Governance & Platform Rules ------------------------

    function proposeNewRule(string memory _ruleDescription) external onlyRegisteredUser {
        proposalIdCounter++;
        ruleProposals[proposalIdCounter] = RuleProposal({
            proposalId: proposalIdCounter,
            proposer: _msgSender(),
            description: _ruleDescription,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            createdAt: block.timestamp
        });
        emit RuleProposalCreated(proposalIdCounter, _msgSender(), _ruleDescription);
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _vote) external onlyRegisteredUser validProposalId(_proposalId) {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");
        require(block.timestamp < proposal.createdAt + ruleProposalVoteDuration, "Voting period ended.");
        require(!proposalVotes[_proposalId][_msgSender()], "You have already voted on this proposal.");

        proposalVotes[_proposalId][_msgSender()] = _vote;
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit RuleProposalVoted(_proposalId, _msgSender(), _vote);

        // Auto-execute if quorum and threshold are met (simplified for example)
        uint256 quorumNeeded = (registeredUsers.length * ruleProposalQuorumPercentage) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) { // Simple majority for now
            executeRuleProposal(_proposalId); // Auto-execute if conditions met
        }
    }

    function executeRuleProposal(uint256 _proposalId) public onlyOwner validProposalId(_proposalId) {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");
        require(block.timestamp >= proposal.createdAt + ruleProposalVoteDuration, "Voting period not ended yet or already executed.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass."); // Ensure it passed based on votes

        proposal.isExecuted = true;
        emit RuleProposalExecuted(_proposalId);
        // Here, you would implement the logic to apply the proposed rule.
        // For example, if the rule was to change the platform fee, you would update platformFeePercentage.
        // In this example, we just mark it as executed.
    }

    // ------------------------ Dispute Resolution (Decentralized) ------------------------

    function openDispute(uint256 _jobId, string memory _disputeDescription) external onlyRegisteredUser {
        disputeIdCounter++;
        disputes[disputeIdCounter] = Dispute({
            disputeId: disputeIdCounter,
            jobId: _jobId,
            reporter: _msgSender(),
            description: _disputeDescription,
            votesForRequester: 0,
            votesForProvider: 0,
            isResolved: false,
            resolution: DisputeResolution.Pending,
            createdAt: block.timestamp
        });
        emit DisputeOpened(disputeIdCounter, _jobId, _msgSender(), _disputeDescription);
    }

    function voteOnDispute(uint256 _disputeId, bool _resolutionFavorRequester) external onlyRegisteredUser validDisputeId(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.isResolved, "Dispute already resolved.");
        require(block.timestamp < dispute.createdAt + disputeVoteDuration, "Voting period ended.");
        require(!disputeVotes[_disputeId][_msgSender()], "You have already voted on this dispute.");

        disputeVotes[_disputeId][_msgSender()] = _resolutionFavorRequester;
        if (_resolutionFavorRequester) {
            dispute.votesForRequester++;
        } else {
            dispute.votesForProvider++;
        }
        emit DisputeVoted(_disputeId, _msgSender(), _resolutionFavorRequester);

        // Auto-resolve if quorum and threshold are met (simplified for example)
        uint256 quorumNeeded = (registeredUsers.length * disputeQuorumPercentage) / 100;
        uint256 totalVotes = dispute.votesForRequester + dispute.votesForProvider;
        if (totalVotes >= quorumNeeded) {
            if (dispute.votesForRequester > dispute.votesForProvider) {
                resolveDispute(_disputeId); // Auto-resolve favoring requester
            } else if (dispute.votesForProvider > dispute.votesForRequester) {
                resolveDispute(_disputeId); // Auto-resolve favoring provider
            }
            // In case of a tie, you might need a platform decision or further voting rounds.
        }
    }

    function resolveDispute(uint256 _disputeId) public onlyOwner validDisputeId(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.isResolved, "Dispute already resolved.");
        require(block.timestamp >= dispute.createdAt + disputeVoteDuration, "Voting period not ended yet or already resolved.");

        if (dispute.votesForRequester > dispute.votesForProvider) {
            dispute.resolution = DisputeResolution.FavorRequester;
            // Implement logic to refund requester, penalize provider (if needed), etc.
            // Example: Refund budget to requester (simplified, needs proper fund management)
            SkillRequest storage request = skillRequests[dispute.jobId];
            if (request.requester != address(0)) { // Check if requester is valid
                payable(request.requester).transfer(request.budget); // Refund full budget
                accumulatedPlatformFees -= (request.budget * platformFeePercentage) / 100; // Adjust platform fees
            }

        } else if (dispute.votesForProvider > dispute.votesForRequester) {
            dispute.resolution = DisputeResolution.FavorProvider;
            // Implement logic to pay provider (if payment was held), potentially penalize requester (if needed), etc.
            // Example: Pay provider (if payment was held, assuming request payment is held in contract - not implemented here)
            SkillRequest storage request = skillRequests[dispute.jobId];
            if (request.provider != address(0)) { // Check if provider is valid
                payable(request.provider).transfer(request.budget - (request.budget * platformFeePercentage) / 100); // Pay provider minus fee
                accumulatedPlatformFees += (request.budget * platformFeePercentage) / 100;
            }

        } else {
            dispute.resolution = DisputeResolution.PlatformDecision;
            // In case of a tie or other complex scenarios, platform owner can manually intervene
            // For simplicity, we'll just mark it as PlatformDecision.
            // In a real system, you'd have more elaborate platform intervention logic.
        }
        dispute.isResolved = true;
        emit DisputeResolved(_disputeId, dispute.resolution);
    }


    // ------------------------ Platform Settings ------------------------

    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(owner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw);
    }

    // Internal function to get the sender address consistently
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```