```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform - "ContentNexus"
 * @author Bard (Example Smart Contract - Conceptual and Not Audited)
 * @dev A smart contract for a dynamic content platform where content evolves based on community interaction,
 *      incorporating advanced concepts like content mutations, reputation-based access, decentralized governance,
 *      and dynamic royalties. This is a conceptual example and requires thorough security auditing and
 *      further development for production use.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 * 1. `registerContent(string _initialContentHash, string _metadataURI)`: Allows creators to register new content, represented by a content hash (e.g., IPFS CID) and metadata URI.
 * 2. `getContentMetadata(uint256 _contentId)`: Retrieves the metadata URI for a specific content ID.
 * 3. `getCurrentContentHash(uint256 _contentId)`: Gets the current content hash for a specific content ID, reflecting mutations.
 * 4. `mutateContent(uint256 _contentId, string _mutationProposalHash, string _mutationDescription)`: Allows users to propose content mutations, storing the proposal hash and description.
 * 5. `voteOnMutation(uint256 _contentId, uint256 _mutationId, bool _approve)`: Users with reputation can vote on content mutation proposals.
 * 6. `applyMutation(uint256 _contentId, uint256 _mutationId)`: Applies an approved mutation to the content, updating the content hash.
 * 7. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for policy violations.
 * 8. `resolveContentReport(uint256 _contentId, uint256 _reportId, bool _isViolation)`: Governance or designated moderators can resolve content reports.
 * 9. `getContentAccessLevel(uint256 _contentId, address _user)`: Dynamically determines the access level of a user to specific content based on reputation and content settings.
 * 10. `setContentAccessLevelRequirement(uint256 _contentId, uint256 _minReputation)`: Allows content creators to set a minimum reputation score for accessing their content.

 * **Reputation and Governance:**
 * 11. `upvoteContent(uint256 _contentId)`: Allows users to upvote content, contributing to creator reputation.
 * 12. `downvoteContent(uint256 _contentId)`: Allows users to downvote content, potentially reducing creator reputation.
 * 13. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 14. `delegateGovernance(address _delegatee)`: Allows users to delegate their governance voting power to another address.
 * 15. `createGovernanceProposal(string _proposalDescription, bytes _calldata)`: Allows users with sufficient reputation to create governance proposals.
 * 16. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Users with governance power can vote on proposals.
 * 17. `executeGovernanceProposal(uint256 _proposalId)`: Executes a passed governance proposal.

 * **Dynamic Royalties and Creator Economy:**
 * 18. `setDynamicRoyalty(uint256 _contentId, uint256 _initialRoyaltyPercentage, uint256 _mutationRoyaltyPercentage)`: Sets dynamic royalty percentages for initial content and mutations.
 * 19. `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to content, paying royalties to the creator and mutation proposers (if applicable).
 * 20. `withdrawCreatorEarnings()`: Allows content creators to withdraw their accumulated earnings.
 * 21. `donateToCreator(uint256 _contentId)`: Allows users to directly donate to content creators.
 * 22. `setPlatformFee(uint256 _feePercentage)`: Governance function to set a platform fee on content access purchases.

 * **Utility and Admin Functions:**
 * 23. `pauseContract()`: Pauses core functionalities of the contract (admin only).
 * 24. `unpauseContract()`: Resumes paused functionalities (admin only).
 * 25. `setGovernanceThreshold(uint256 _threshold)`: Sets the reputation threshold required for governance participation (admin/governance).
 * 26. `setMutationVoteThreshold(uint256 _threshold)`: Sets the percentage of votes required for mutation approval (governance).
 * 27. `setDefaultAccessLevelRequirement(uint256 _minReputation)`: Sets a default minimum reputation for accessing content (governance).
 */

contract ContentNexus {
    // --- State Variables ---
    uint256 public contentCounter;
    uint256 public mutationCounter;
    uint256 public reportCounter;
    uint256 public governanceProposalCounter;

    uint256 public governanceThreshold = 100; // Reputation needed for governance
    uint256 public mutationVoteThreshold = 50; // Percentage of votes for mutation approval
    uint256 public defaultAccessLevelRequirement = 0; // Default reputation needed to access content
    uint256 public platformFeePercentage = 2; // Platform fee percentage on content purchases (e.g., 2%)

    address public admin;
    bool public paused = false;

    mapping(uint256 => Content) public contents;
    mapping(uint256 => mapping(uint256 => MutationProposal)) public contentMutations;
    mapping(uint256 => ContentReport) public contentReports;
    mapping(address => uint256) public userReputation;
    mapping(address => address) public governanceDelegation;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Structs ---
    struct Content {
        address creator;
        string initialContentHash;
        string metadataURI;
        string currentContentHash; // Initially the same as initialContentHash, updated after mutations
        uint256 accessLevelRequirement; // Minimum reputation to access, defaults to contract-wide setting
        uint256 initialRoyaltyPercentage;
        uint256 mutationRoyaltyPercentage;
        uint256 earnings;
    }

    struct MutationProposal {
        address proposer;
        string proposalHash; // Hash of the mutation proposal content itself (e.g., diff, patch)
        string description;
        uint256 upvotes;
        uint256 downvotes;
        bool applied;
        mapping(address => bool) votes; // Users who have voted
    }

    struct ContentReport {
        address reporter;
        string reason;
        bool isViolation;
        bool resolved;
    }

    struct GovernanceProposal {
        address proposer;
        string description;
        bytes calldata; // Calldata to execute if proposal passes
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
        mapping(address => bool) votes;
    }

    // --- Events ---
    event ContentRegistered(uint256 contentId, address creator, string initialContentHash, string metadataURI);
    event ContentMutated(uint256 contentId, string newContentHash, uint256 mutationId);
    event MutationProposed(uint256 contentId, uint256 mutationId, address proposer, string proposalHash, string description);
    event MutationVoteCast(uint256 contentId, uint256 mutationId, address voter, bool approve);
    event ContentReported(uint256 contentId, uint256 reportId, address reporter, string reason);
    event ContentReportResolved(uint256 contentId, uint256 reportId, bool isViolation);
    event ReputationUpdated(address user, int256 reputationChange, uint256 newReputation);
    event GovernanceDelegated(address delegator, address delegatee);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ContentAccessPurchased(uint256 contentId, address purchaser, uint256 royaltyAmount);
    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event DonationReceived(uint256 contentId, address donor, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event PlatformFeeSet(uint256 feePercentage);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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
        require(contents[_contentId].creator != address(0), "Content does not exist.");
        _;
    }

    modifier mutationExists(uint256 _contentId, uint256 _mutationId) {
        require(contentMutations[_contentId][_mutationId].proposer != address(0), "Mutation proposal does not exist.");
        _;
    }

    modifier reportExists(uint256 _reportId) {
        require(contentReports[_reportId].reporter != address(0), "Report does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal does not exist.");
        _;
    }

    modifier reputationAtLeast(address _user, uint256 _minReputation) {
        require(getUserReputation(_user) >= _minReputation, "Insufficient reputation.");
        _;
    }

    modifier hasGovernancePower(address _user) {
        address effectiveVoter = governanceDelegation[_user] != address(0) ? governanceDelegation[_user] : _user;
        require(getUserReputation(effectiveVoter) >= governanceThreshold, "Insufficient governance reputation.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        contentCounter = 0;
        mutationCounter = 0;
        reportCounter = 0;
        governanceProposalCounter = 0;
    }

    // --- Core Functionality ---

    /// @notice Registers new content on the platform.
    /// @param _initialContentHash Hash of the initial content (e.g., IPFS CID).
    /// @param _metadataURI URI pointing to the content's metadata (e.g., IPFS path to JSON).
    function registerContent(string memory _initialContentHash, string memory _metadataURI) public whenNotPaused {
        contentCounter++;
        contents[contentCounter] = Content({
            creator: msg.sender,
            initialContentHash: _initialContentHash,
            metadataURI: _metadataURI,
            currentContentHash: _initialContentHash,
            accessLevelRequirement: defaultAccessLevelRequirement,
            initialRoyaltyPercentage: 5, // Default initial royalty percentage
            mutationRoyaltyPercentage: 2, // Default mutation royalty percentage
            earnings: 0
        });
        emit ContentRegistered(contentCounter, msg.sender, _initialContentHash, _metadataURI);
    }

    /// @notice Retrieves the metadata URI associated with a content ID.
    /// @param _contentId ID of the content.
    /// @return Metadata URI string.
    function getContentMetadata(uint256 _contentId) public view contentExists(_contentId) returns (string memory) {
        return contents[_contentId].metadataURI;
    }

    /// @notice Gets the current content hash for a content ID, reflecting any applied mutations.
    /// @param _contentId ID of the content.
    /// @return Current content hash string.
    function getCurrentContentHash(uint256 _contentId) public view contentExists(_contentId) returns (string memory) {
        return contents[_contentId].currentContentHash;
    }

    /// @notice Allows users to propose a mutation to existing content.
    /// @param _contentId ID of the content to mutate.
    /// @param _mutationProposalHash Hash of the mutation proposal content (e.g., diff file).
    /// @param _mutationDescription Description of the proposed mutation.
    function mutateContent(uint256 _contentId, string memory _mutationProposalHash, string memory _mutationDescription) public whenNotPaused contentExists(_contentId) {
        mutationCounter++;
        contentMutations[_contentId][mutationCounter] = MutationProposal({
            proposer: msg.sender,
            proposalHash: _mutationProposalHash,
            description: _mutationDescription,
            upvotes: 0,
            downvotes: 0,
            applied: false,
            votes: mapping(address => bool)()
        });
        emit MutationProposed(_contentId, mutationCounter, msg.sender, _mutationProposalHash, _mutationDescription);
    }

    /// @notice Allows users with sufficient reputation to vote on a mutation proposal.
    /// @param _contentId ID of the content being mutated.
    /// @param _mutationId ID of the mutation proposal.
    /// @param _approve True to approve the mutation, false to reject.
    function voteOnMutation(uint256 _contentId, uint256 _mutationId, bool _approve) public whenNotPaused contentExists(_contentId) mutationExists(_contentId, _mutationId) reputationAtLeast(msg.sender, governanceThreshold) {
        MutationProposal storage mutation = contentMutations[_contentId][_mutationId];
        require(!mutation.votes[msg.sender], "User has already voted on this mutation.");
        mutation.votes[msg.sender] = true;

        if (_approve) {
            mutation.upvotes++;
        } else {
            mutation.downvotes++;
        }
        emit MutationVoteCast(_contentId, _mutationId, msg.sender, _approve);
    }

    /// @notice Applies a mutation to the content if it has received enough positive votes.
    /// @param _contentId ID of the content to mutate.
    /// @param _mutationId ID of the mutation proposal.
    function applyMutation(uint256 _contentId, uint256 _mutationId) public whenNotPaused contentExists(_contentId) mutationExists(_contentId, _mutationId) {
        MutationProposal storage mutation = contentMutations[_contentId][_mutationId];
        require(!mutation.applied, "Mutation already applied.");
        uint256 totalVotes = mutation.upvotes + mutation.downvotes;
        require(totalVotes > 0, "No votes cast yet."); // Prevent division by zero
        uint256 approvalPercentage = (mutation.upvotes * 100) / totalVotes; // Calculate percentage with integer division

        require(approvalPercentage >= mutationVoteThreshold, "Mutation proposal not approved.");

        contents[_contentId].currentContentHash = mutation.proposalHash; // Update content hash to mutation hash
        mutation.applied = true;
        emit ContentMutated(_contentId, mutation.proposalHash, _mutationId);

        // Optionally, reward the mutation proposer with reputation or a small royalty split upon content access purchase.
        updateReputation(mutation.proposer, 10); // Example: Reward proposer with 10 reputation points.
    }

    /// @notice Allows users to report content for policy violations.
    /// @param _contentId ID of the content being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _contentId, string memory _reportReason) public whenNotPaused contentExists(_contentId) {
        reportCounter++;
        contentReports[reportCounter] = ContentReport({
            reporter: msg.sender,
            reason: _reportReason,
            isViolation: false, // Initially false, needs resolution
            resolved: false
        });
        emit ContentReported(_contentId, reportCounter, msg.sender, _reportReason);
    }

    /// @notice Allows governance or designated moderators to resolve a content report.
    /// @param _contentId ID of the content being reported.
    /// @param _reportId ID of the content report.
    /// @param _isViolation True if the report is deemed a violation, false otherwise.
    function resolveContentReport(uint256 _contentId, uint256 _reportId, bool _isViolation) public whenNotPaused reportExists(_reportId) hasGovernancePower(msg.sender) {
        ContentReport storage report = contentReports[_reportId];
        require(!report.resolved, "Report already resolved.");
        report.isViolation = _isViolation;
        report.resolved = true;
        emit ContentReportResolved(_contentId, _reportId, _isViolation);

        // Implement actions based on _isViolation, e.g., content removal, creator penalty.
        if (_isViolation) {
            // Example: Reduce creator reputation if content is a violation.
            updateReputation(contents[_contentId].creator, -20);
        }
    }

    /// @notice Dynamically determines the access level required for a user to access specific content.
    /// @param _contentId ID of the content.
    /// @param _user Address of the user requesting access.
    /// @return True if the user meets the access requirements, false otherwise.
    function getContentAccessLevel(uint256 _contentId, address _user) public view contentExists(_contentId) returns (bool) {
        uint256 requiredReputation = contents[_contentId].accessLevelRequirement;
        return getUserReputation(_user) >= requiredReputation;
    }

    /// @notice Allows content creators to set a minimum reputation score required to access their content.
    /// @param _contentId ID of the content.
    /// @param _minReputation Minimum reputation score required for access.
    function setContentAccessLevelRequirement(uint256 _contentId, uint256 _minReputation) public whenNotPaused contentExists(_contentId) {
        require(contents[_contentId].creator == msg.sender, "Only content creator can set access level.");
        contents[_contentId].accessLevelRequirement = _minReputation;
    }


    // --- Reputation and Governance ---

    /// @notice Allows users to upvote content, increasing the creator's reputation.
    /// @param _contentId ID of the content being upvoted.
    function upvoteContent(uint256 _contentId) public whenNotPaused contentExists(_contentId) {
        updateReputation(contents[_contentId].creator, 5); // Example: +5 reputation for upvote
    }

    /// @notice Allows users to downvote content, potentially decreasing the creator's reputation.
    /// @param _contentId ID of the content being downvoted.
    function downvoteContent(uint256 _contentId) public whenNotPaused contentExists(_contentId) {
        updateReputation(contents[_contentId].creator, -3); // Example: -3 reputation for downvote
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user Address of the user.
    /// @return User's reputation score.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Allows users to delegate their governance voting power to another address.
    /// @param _delegatee Address to delegate governance power to. Set to address(0) to undelegate.
    function delegateGovernance(address _delegatee) public whenNotPaused {
        governanceDelegation[msg.sender] = _delegatee;
        emit GovernanceDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows users with sufficient reputation to create governance proposals.
    /// @param _proposalDescription Description of the governance proposal.
    /// @param _calldata Calldata to execute if the proposal passes (e.g., function call and parameters).
    function createGovernanceProposal(string memory _proposalDescription, bytes memory _calldata) public whenNotPaused reputationAtLeast(msg.sender, governanceThreshold) {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            calldata: _calldata,
            upvotes: 0,
            downvotes: 0,
            executed: false,
            votes: mapping(address => bool)()
        });
        emit GovernanceProposalCreated(governanceProposalCounter, msg.sender, _proposalDescription);
    }

    /// @notice Allows users with governance power to vote on governance proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _support True to support the proposal, false to oppose.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalExists(_proposalId) hasGovernancePower(msg.sender) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.votes[msg.sender], "User has already voted on this proposal.");
        proposal.votes[msg.sender] = true;

        if (_support) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed governance proposal if it has received enough positive votes.
    /// @param _proposalId ID of the governance proposal.
    function executeGovernanceProposal(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) hasGovernancePower(msg.sender) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        uint256 totalVotes = proposal.upvotes + proposal.downvotes;
        require(totalVotes > 0, "No votes cast yet."); // Prevent division by zero
        uint256 supportPercentage = (proposal.upvotes * 100) / totalVotes; // Calculate percentage with integer division

        require(supportPercentage > 50, "Governance proposal not passed."); // Simple majority for execution

        proposal.executed = true;
        (bool success, ) = address(this).call(proposal.calldata); // Execute the calldata
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }


    // --- Dynamic Royalties and Creator Economy ---

    /// @notice Sets dynamic royalty percentages for initial content and mutations.
    /// @param _contentId ID of the content.
    /// @param _initialRoyaltyPercentage Royalty percentage for accessing the initial content.
    /// @param _mutationRoyaltyPercentage Royalty percentage for accessing mutated content (split with mutation proposer).
    function setDynamicRoyalty(uint256 _contentId, uint256 _initialRoyaltyPercentage, uint256 _mutationRoyaltyPercentage) public whenNotPaused contentExists(_contentId) {
        require(contents[_contentId].creator == msg.sender, "Only content creator can set royalties.");
        require(_initialRoyaltyPercentage <= 100 && _mutationRoyaltyPercentage <= 100, "Royalty percentages must be <= 100.");
        contents[_contentId].initialRoyaltyPercentage = _initialRoyaltyPercentage;
        contents[_contentId].mutationRoyaltyPercentage = _mutationRoyaltyPercentage;
    }

    /// @notice Allows users to purchase access to content, paying royalties to the creator and mutation proposers (if applicable).
    /// @param _contentId ID of the content to access.
    function purchaseContentAccess(uint256 _contentId) public payable whenNotPaused contentExists(_contentId) {
        require(getContentAccessLevel(_contentId, msg.sender), "Insufficient reputation to access content.");

        uint256 initialRoyalty = (msg.value * contents[_contentId].initialRoyaltyPercentage) / 100;
        uint256 mutationRoyalty = (msg.value * contents[_contentId].mutationRoyaltyPercentage) / 100;
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorShare = initialRoyalty + mutationRoyalty; // Creator gets both initial and mutation royalties for simplicity in this example.

        // Transfer royalties to creator
        (bool successCreator, ) = payable(contents[_contentId].creator).call{value: creatorShare}("");
        require(successCreator, "Royalty transfer to creator failed.");
        contents[_contentId].earnings += creatorShare;

        // Transfer platform fee to contract (admin can withdraw later)
        (bool successPlatform, ) = payable(admin).call{value: platformFee}(""); // For simplicity, platform fee goes to admin in this example.
        require(successPlatform, "Platform fee transfer failed.");

        emit ContentAccessPurchased(_contentId, msg.sender, creatorShare);
    }


    /// @notice Allows content creators to withdraw their accumulated earnings.
    function withdrawCreatorEarnings() public whenNotPaused {
        uint256 earnings = contents[contentCounter].earnings; // Assuming contentCounter is the last registered content for simplicity, in real app, iterate over content owned by user
        require(earnings > 0, "No earnings to withdraw.");
        require(contents[contentCounter].creator == msg.sender, "Only content creator can withdraw earnings."); // Again, simplifying for example, in real app, check ownership

        contents[contentCounter].earnings = 0; // Reset earnings after withdrawal
        (bool success, ) = payable(msg.sender).call{value: earnings}("");
        require(success, "Withdrawal failed.");
        emit CreatorEarningsWithdrawn(msg.sender, earnings);
    }

    /// @notice Allows users to directly donate to content creators.
    /// @param _contentId ID of the content to donate to.
    function donateToCreator(uint256 _contentId) public payable whenNotPaused contentExists(_contentId) {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        (bool success, ) = payable(contents[_contentId].creator).call{value: msg.value}("");
        require(success, "Donation transfer failed.");
        contents[_contentId].earnings += msg.value; // Add donation to creator earnings
        emit DonationReceived(_contentId, msg.sender, msg.value);
    }

    /// @notice Governance function to set the platform fee percentage on content access purchases.
    /// @param _feePercentage New platform fee percentage (0-100).
    function setPlatformFee(uint256 _feePercentage) public whenNotPaused onlyAdmin { // In real app, this should be governance controlled
        require(_feePercentage <= 100, "Platform fee percentage must be <= 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }


    // --- Utility and Admin Functions ---

    /// @notice Pauses core functionalities of the contract.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes paused functionalities of the contract.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets the reputation threshold required for governance participation.
    /// @param _threshold New reputation threshold.
    function setGovernanceThreshold(uint256 _threshold) public onlyAdmin { // In real app, this should be governance controlled
        governanceThreshold = _threshold;
    }

    /// @notice Sets the percentage of votes required for mutation approval.
    /// @param _threshold New mutation vote threshold percentage (0-100).
    function setMutationVoteThreshold(uint256 _threshold) public onlyAdmin { // In real app, this should be governance controlled
        require(_threshold <= 100, "Mutation vote threshold must be <= 100.");
        mutationVoteThreshold = _threshold;
    }

    /// @notice Sets the default minimum reputation required for accessing content.
    /// @param _minReputation New default minimum reputation.
    function setDefaultAccessLevelRequirement(uint256 _minReputation) public onlyAdmin { // In real app, this should be governance controlled
        defaultAccessLevelRequirement = _minReputation;
    }

    // --- Internal Helper Functions ---
    function updateReputation(address _user, int256 _reputationChange) internal {
        int256 currentReputation = int256(userReputation[_user]); // Cast to int256 to handle negative changes
        int256 newReputation = currentReputation + _reputationChange;

        // Ensure reputation doesn't go below 0
        if (newReputation < 0) {
            newReputation = 0;
        }

        userReputation[_user] = uint256(newReputation); // Cast back to uint256 for storage
        emit ReputationUpdated(_user, _reputationChange, uint256(newReputation));
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```