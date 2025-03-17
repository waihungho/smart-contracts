```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Skill-Based Reputation and Challenge Platform
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized platform where users can earn skill-based reputation,
 * participate in dynamic challenges, and contribute to a community-driven ecosystem.
 *
 * **Outline and Function Summary:**
 *
 * **Core Concepts:**
 * 1. **Skill Badges (NFTs):** Represent verifiable skills or achievements.
 * 2. **Reputation System:**  Tracks user skill and contribution levels, influencing access and rewards.
 * 3. **Dynamic Challenges:**  Evolving tasks with varying difficulty and rewards, driven by community or admin.
 * 4. **Reputation-Based Governance:**  Users with higher reputation have more influence on platform decisions.
 * 5. **Decentralized Skill Marketplace (Potential Extension):**  Users can offer services based on their verified skills (not fully implemented in this example to keep it focused).
 *
 * **Functions (20+):**
 *
 * **Admin Functions (Controlled by contract owner):**
 * 1. `setPlatformAdmin(address _newAdmin)`:  Change the platform administrator.
 * 2. `createSkillBadgeType(string memory _badgeName, string memory _badgeDescription, string memory _badgeURI)`: Define a new type of skill badge.
 * 3. `updateSkillBadgeType(uint256 _badgeTypeId, string memory _badgeName, string memory _badgeDescription, string memory _badgeURI)`: Modify details of an existing skill badge type.
 * 4. `setChallengeEvaluator(uint256 _challengeId, address _evaluator)`: Designate an evaluator for a specific challenge.
 * 5. `setDefaultChallengeEvaluator(address _defaultEvaluator)`: Set a default evaluator for new challenges if not specified.
 * 6. `setPlatformFee(uint256 _newFeePercentage)`:  Update the platform fee percentage for challenges (optional, for future monetization).
 * 7. `pauseContract()`:  Pause core contract functionalities.
 * 8. `unpauseContract()`:  Resume contract functionalities after pausing.
 * 9. `withdrawPlatformFees()`:  Withdraw accumulated platform fees (if implemented).
 *
 * **Challenge Management Functions:**
 * 10. `createChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _rewardReputation, uint256 _deadline, uint256 _badgeTypeId)`: Create a new skill-based challenge.
 * 11. `updateChallengeDetails(uint256 _challengeId, string memory _challengeTitle, string memory _challengeDescription, uint256 _rewardReputation, uint256 _deadline, uint256 _badgeTypeId)`: Modify details of an existing challenge.
 * 12. `cancelChallenge(uint256 _challengeId)`: Cancel an active challenge.
 * 13. `submitChallengeSolution(uint256 _challengeId, string memory _solutionURI)`:  Users submit their solutions for a challenge.
 * 14. `evaluateChallengeSolution(uint256 _challengeId, address _user, bool _isApproved, string memory _evaluationFeedback)`: Evaluator approves or rejects a user's challenge solution.
 *
 * **Reputation and Badge Functions:**
 * 15. `getReputation(address _user)`: View a user's current reputation score.
 * 16. `getSkillBadgeBalance(address _user, uint256 _badgeTypeId)`: Check how many badges of a specific type a user holds.
 * 17. `transferSkillBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount)`: Transfer skill badges to another user (optional for specific badge types).
 * 18. `burnSkillBadge(uint256 _badgeTypeId, uint256 _amount)`: Burn skill badges (optional, for badge type management).
 *
 * **Governance/Community Functions (Reputation-Based):**
 * 19. `proposeNewBadgeType(string memory _badgeName, string memory _badgeDescription, string memory _badgeURI)`: Users with sufficient reputation can propose new badge types.
 * 20. `voteOnBadgeTypeProposal(uint256 _proposalId, bool _vote)`: Users with reputation vote on badge type proposals.
 * 21. `executeBadgeTypeProposal(uint256 _proposalId)`: If a proposal passes, execute it and create the new badge type.
 * 22. `reportInappropriateContent(uint256 _challengeId, string memory _reportReason)`: Users can report challenges they deem inappropriate (governance extension).
 *
 * **View Functions (Informational):**
 * 23. `getChallengeDetails(uint256 _challengeId)`: Retrieve detailed information about a specific challenge.
 * 24. `getSkillBadgeTypeDetails(uint256 _badgeTypeId)`: Get details of a specific skill badge type.
 * 25. `getPlatformAdmin()`:  Get the current platform administrator address.
 * 26. `isContractPaused()`: Check if the contract is currently paused.
 * 27. `getPlatformFeePercentage()`: Get the current platform fee percentage.
 * 28. `getTotalSkillBadgeTypes()`: Get the total number of skill badge types defined.
 * 29. `getTotalChallenges()`: Get the total number of challenges created.
 * 30. `getBadgeTypeProposalDetails(uint256 _proposalId)`: View details of a badge type proposal.
 */
contract DynamicSkillPlatform {
    // --- State Variables ---

    address public platformAdmin;
    address public defaultChallengeEvaluator;
    uint256 public platformFeePercentage; // Example: 2% fee = 200 (out of 10000 basis points)
    bool public paused;

    uint256 public nextBadgeTypeId = 1;
    mapping(uint256 => SkillBadgeType) public skillBadgeTypes;
    mapping(uint256 => uint256) public totalBadgesMintedOfType; // Track total minted per badge type

    uint256 public nextChallengeId = 1;
    mapping(uint256 => Challenge) public challenges;

    mapping(address => uint256) public userReputation;
    mapping(address => mapping(uint256 => uint256)) public userSkillBadgeBalances; // user => badgeTypeId => balance

    uint256 public nextBadgeTypeProposalId = 1;
    mapping(uint256 => BadgeTypeProposal) public badgeTypeProposals;

    // --- Structs ---

    struct SkillBadgeType {
        uint256 id;
        string name;
        string description;
        string badgeURI; // URI for badge metadata (e.g., IPFS link)
        bool isActive;
    }

    struct Challenge {
        uint256 id;
        string title;
        string description;
        uint256 rewardReputation;
        uint256 deadline; // Unix timestamp
        uint256 badgeTypeId;
        address evaluator;
        ChallengeStatus status;
        mapping(address => SolutionSubmission) submissions; // user => submission details
    }

    struct SolutionSubmission {
        string solutionURI;
        SubmissionStatus status;
        string evaluationFeedback;
    }

    struct BadgeTypeProposal {
        uint256 id;
        string name;
        string description;
        string badgeURI;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }

    // --- Enums ---

    enum ChallengeStatus {
        Active,
        Completed,
        Cancelled
    }

    enum SubmissionStatus {
        Pending,
        Approved,
        Rejected
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    // --- Events ---

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event SkillBadgeTypeCreated(uint256 badgeTypeId, string badgeName);
    event SkillBadgeTypeUpdated(uint256 badgeTypeId, string badgeName);
    event SkillBadgeMinted(address indexed recipient, uint256 badgeTypeId, uint256 amount);
    event SkillBadgeTransferred(address indexed from, address indexed to, uint256 badgeTypeId, uint256 amount);
    event SkillBadgeBurned(address indexed burner, uint256 badgeTypeId, uint256 amount);
    event ChallengeCreated(uint256 challengeId, string challengeTitle, uint256 badgeTypeId);
    event ChallengeUpdated(uint256 challengeId, string challengeTitle);
    event ChallengeCancelled(uint256 challengeId);
    event ChallengeSolutionSubmitted(uint256 challengeId, address indexed user);
    event ChallengeSolutionEvaluated(uint256 challengeId, address indexed user, bool isApproved);
    event ReputationUpdated(address indexed user, uint256 newReputation, int256 change);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeePercentageUpdated(uint256 newFeePercentage);
    event DefaultChallengeEvaluatorSet(address newEvaluator);
    event BadgeTypeProposalCreated(uint256 proposalId, string badgeName, address proposer);
    event BadgeTypeProposalVoted(uint256 proposalId, address voter, bool vote);
    event BadgeTypeProposalExecuted(uint256 proposalId, uint256 badgeTypeId);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can call this function.");
        _;
    }

    modifier onlyEvaluator(uint256 _challengeId) {
        require(msg.sender == challenges[_challengeId].evaluator || msg.sender == platformAdmin, "Only challenge evaluator or admin can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(challenges[_challengeId].id == _challengeId, "Challenge does not exist.");
        _;
    }

    modifier badgeTypeExists(uint256 _badgeTypeId) {
        require(skillBadgeTypes[_badgeTypeId].id == _badgeTypeId, "Badge type does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(badgeTypeProposals[_proposalId].id == _proposalId, "Badge type proposal does not exist.");
        _;
    }

    modifier reputationSufficientForProposal(address _user) {
        require(userReputation[_user] >= 100, "Reputation must be at least 100 to create proposals."); // Example reputation threshold
        _;
    }

    // --- Constructor ---

    constructor() {
        platformAdmin = msg.sender;
        platformFeePercentage = 0; // Default to 0% fee
        paused = false;
    }

    // --- Admin Functions ---

    /**
     * @dev Sets a new platform administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setPlatformAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(platformAdmin, _newAdmin);
        platformAdmin = _newAdmin;
    }

    /**
     * @dev Creates a new skill badge type.
     * @param _badgeName The name of the badge.
     * @param _badgeDescription Description of the badge.
     * @param _badgeURI URI pointing to the badge metadata.
     */
    function createSkillBadgeType(string memory _badgeName, string memory _badgeDescription, string memory _badgeURI) external onlyAdmin whenNotPaused {
        require(bytes(_badgeName).length > 0, "Badge name cannot be empty.");
        skillBadgeTypes[nextBadgeTypeId] = SkillBadgeType(
            nextBadgeTypeId,
            _badgeName,
            _badgeDescription,
            _badgeURI,
            true // Initially active
        );
        emit SkillBadgeTypeCreated(nextBadgeTypeId, _badgeName);
        nextBadgeTypeId++;
    }

    /**
     * @dev Updates details of an existing skill badge type.
     * @param _badgeTypeId The ID of the badge type to update.
     * @param _badgeName New name for the badge.
     * @param _badgeDescription New description for the badge.
     * @param _badgeURI New URI for the badge metadata.
     */
    function updateSkillBadgeType(uint256 _badgeTypeId, string memory _badgeName, string memory _badgeDescription, string memory _badgeURI) external onlyAdmin whenNotPaused badgeTypeExists(_badgeTypeId) {
        require(bytes(_badgeName).length > 0, "Badge name cannot be empty.");
        skillBadgeTypes[_badgeTypeId].name = _badgeName;
        skillBadgeTypes[_badgeTypeId].description = _badgeDescription;
        skillBadgeTypes[_badgeTypeId].badgeURI = _badgeURI;
        emit SkillBadgeTypeUpdated(_badgeTypeId, _badgeName);
    }

    /**
     * @dev Sets an evaluator for a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @param _evaluator The address of the evaluator.
     */
    function setChallengeEvaluator(uint256 _challengeId, address _evaluator) external onlyAdmin whenNotPaused challengeExists(_challengeId) {
        require(_evaluator != address(0), "Evaluator address cannot be zero.");
        challenges[_challengeId].evaluator = _evaluator;
        emit ChallengeUpdated(_challengeId, challenges[_challengeId].title); // Consider more specific event
    }

    /**
     * @dev Sets a default evaluator for new challenges.
     * @param _defaultEvaluator The address of the default evaluator.
     */
    function setDefaultChallengeEvaluator(address _defaultEvaluator) external onlyAdmin whenNotPaused {
        defaultChallengeEvaluator = _defaultEvaluator;
        emit DefaultChallengeEvaluatorSet(_defaultEvaluator);
    }

    /**
     * @dev Sets the platform fee percentage.
     * @param _newFeePercentage The new fee percentage (e.g., 200 for 2%).
     */
    function setPlatformFee(uint256 _newFeePercentage) external onlyAdmin whenNotPaused {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageUpdated(_newFeePercentage);
    }

    /**
     * @dev Pauses the contract, preventing core functionalities.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, resuming core functionalities.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev (Optional) Function to withdraw platform fees. Implementation depends on fee collection mechanism.
     */
    function withdrawPlatformFees() external onlyAdmin whenNotPaused {
        // Implement fee withdrawal logic here if platform fees are collected.
        // Example: (Requires a mechanism to collect fees during challenge creation/submission)
        // (This is a placeholder - specific implementation is needed)
        // require(address(this).balance >= collectedFees, "Insufficient contract balance for fee withdrawal.");
        // payable(platformAdmin).transfer(collectedFees);
    }


    // --- Challenge Management Functions ---

    /**
     * @dev Creates a new skill-based challenge.
     * @param _challengeTitle Title of the challenge.
     * @param _challengeDescription Description of the challenge.
     * @param _rewardReputation Reputation points awarded for completing the challenge.
     * @param _deadline Unix timestamp for the challenge deadline.
     * @param _badgeTypeId ID of the skill badge type awarded upon successful completion.
     */
    function createChallenge(
        string memory _challengeTitle,
        string memory _challengeDescription,
        uint256 _rewardReputation,
        uint256 _deadline,
        uint256 _badgeTypeId
    ) external whenNotPaused badgeTypeExists(_badgeTypeId) {
        require(bytes(_challengeTitle).length > 0, "Challenge title cannot be empty.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        challenges[nextChallengeId] = Challenge({
            id: nextChallengeId,
            title: _challengeTitle,
            description: _challengeDescription,
            rewardReputation: _rewardReputation,
            deadline: _deadline,
            badgeTypeId: _badgeTypeId,
            evaluator: defaultChallengeEvaluator, // Default evaluator, can be overridden by admin
            status: ChallengeStatus.Active,
            submissions: mapping(address => SolutionSubmission)() // Initialize empty submissions mapping
        });

        emit ChallengeCreated(nextChallengeId, _challengeTitle, _badgeTypeId);
        nextChallengeId++;
    }

    /**
     * @dev Updates details of an existing challenge.
     * @param _challengeId ID of the challenge to update.
     * @param _challengeTitle New title for the challenge.
     * @param _challengeDescription New description for the challenge.
     * @param _rewardReputation New reputation reward.
     * @param _deadline New deadline.
     * @param _badgeTypeId New badge type ID.
     */
    function updateChallengeDetails(
        uint256 _challengeId,
        string memory _challengeTitle,
        string memory _challengeDescription,
        uint256 _rewardReputation,
        uint256 _deadline,
        uint256 _badgeTypeId
    ) external onlyAdmin whenNotPaused challengeExists(_challengeId) badgeTypeExists(_badgeTypeId) {
        require(bytes(_challengeTitle).length > 0, "Challenge title cannot be empty.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge must be active to update.");

        challenges[_challengeId].title = _challengeTitle;
        challenges[_challengeId].description = _challengeDescription;
        challenges[_challengeId].rewardReputation = _rewardReputation;
        challenges[_challengeId].deadline = _deadline;
        challenges[_challengeId].badgeTypeId = _badgeTypeId;
        emit ChallengeUpdated(_challengeId, _challengeTitle);
    }

    /**
     * @dev Cancels an active challenge.
     * @param _challengeId ID of the challenge to cancel.
     */
    function cancelChallenge(uint256 _challengeId) external onlyAdmin whenNotPaused challengeExists(_challengeId) {
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Only active challenges can be cancelled.");
        challenges[_challengeId].status = ChallengeStatus.Cancelled;
        emit ChallengeCancelled(_challengeId);
    }

    /**
     * @dev Allows users to submit a solution for a challenge.
     * @param _challengeId ID of the challenge.
     * @param _solutionURI URI pointing to the solution submission (e.g., IPFS link).
     */
    function submitChallengeSolution(uint256 _challengeId, string memory _solutionURI) external whenNotPaused challengeExists(_challengeId) {
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge is not active.");
        require(block.timestamp <= challenges[_challengeId].deadline, "Challenge deadline has passed.");
        require(bytes(_solutionURI).length > 0, "Solution URI cannot be empty.");
        require(challenges[_challengeId].submissions[msg.sender].status == SubmissionStatus.Pending || challenges[_challengeId].submissions[msg.sender].status == SubmissionStatus.Rejected, "Solution already submitted or evaluated."); // Allow resubmission after rejection

        challenges[_challengeId].submissions[msg.sender] = SolutionSubmission({
            solutionURI: _solutionURI,
            status: SubmissionStatus.Pending,
            evaluationFeedback: "" // Initialize feedback as empty
        });
        emit ChallengeSolutionSubmitted(_challengeId, msg.sender);
    }

    /**
     * @dev Evaluates a user's solution for a challenge.
     * @param _challengeId ID of the challenge.
     * @param _user Address of the user who submitted the solution.
     * @param _isApproved True if the solution is approved, false if rejected.
     * @param _evaluationFeedback Feedback message from the evaluator.
     */
    function evaluateChallengeSolution(uint256 _challengeId, address _user, bool _isApproved, string memory _evaluationFeedback) external onlyEvaluator(_challengeId) whenNotPaused challengeExists(_challengeId) {
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge is not active.");
        require(challenges[_challengeId].submissions[_user].status == SubmissionStatus.Pending, "Solution is not pending evaluation.");

        if (_isApproved) {
            challenges[_challengeId].submissions[_user].status = SubmissionStatus.Approved;
            _mintSkillBadge(_user, challenges[_challengeId].badgeTypeId, 1); // Mint 1 badge
            _updateReputation(_user, challenges[_challengeId].rewardReputation);
            emit ChallengeSolutionEvaluated(_challengeId, _user, true);
        } else {
            challenges[_challengeId].submissions[_user].status = SubmissionStatus.Rejected;
            challenges[_challengeId].submissions[_user].evaluationFeedback = _evaluationFeedback;
            emit ChallengeSolutionEvaluated(_challengeId, _user, false);
        }

        // Check if all submissions have been evaluated and mark challenge as completed
        bool allEvaluated = true;
        for (uint i = 1; i < nextChallengeId; i++) { // Iterate through challenges (less efficient for very large number of challenges, consider optimization)
            if (challenges[i].id == _challengeId) {
                for (uint j = 0; j < address(this).balance; j++) { // Iterate through all possible addresses (very inefficient, needs better way to track submissions - consider using an array or linked list)
                   address userAddress = address(uint160(uint256(keccak256(abi.encodePacked(i,j))))); // Generate potential address - this is a placeholder and very inefficient!
                   if(challenges[i].submissions[userAddress].status == SubmissionStatus.Pending){
                        allEvaluated = false;
                        break;
                    }
                }
                 if(allEvaluated){
                    challenges[i].status = ChallengeStatus.Completed;
                 }
                break; // Challenge found, no need to continue iterating
            }
        }

    }


    // --- Reputation and Badge Functions ---

    /**
     * @dev Gets a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Gets the balance of a specific skill badge type for a user.
     * @param _user The address of the user.
     * @param _badgeTypeId The ID of the badge type.
     * @return The number of badges of the specified type held by the user.
     */
    function getSkillBadgeBalance(address _user, uint256 _badgeTypeId) external view badgeTypeExists(_badgeTypeId) returns (uint256) {
        return userSkillBadgeBalances[_user][_badgeTypeId];
    }

    /**
     * @dev Transfers skill badges to another user. (Optional - can be restricted per badge type)
     * @param _recipient The address of the recipient.
     * @param _badgeTypeId The ID of the badge type to transfer.
     * @param _amount The amount of badges to transfer.
     */
    function transferSkillBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount) external whenNotPaused badgeTypeExists(_badgeTypeId) {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(msg.sender != _recipient, "Cannot transfer badges to yourself.");
        require(userSkillBadgeBalances[msg.sender][_badgeTypeId] >= _amount, "Insufficient badge balance.");
        require(_amount > 0, "Transfer amount must be greater than zero.");

        userSkillBadgeBalances[msg.sender][_badgeTypeId] -= _amount;
        userSkillBadgeBalances[_recipient][_badgeTypeId] += _amount;
        emit SkillBadgeTransferred(msg.sender, _recipient, _badgeTypeId, _amount);
    }

    /**
     * @dev Burns skill badges. (Optional - for badge type management if needed)
     * @param _badgeTypeId The ID of the badge type to burn.
     * @param _amount The amount of badges to burn.
     */
    function burnSkillBadge(uint256 _badgeTypeId, uint256 _amount) external onlyAdmin whenNotPaused badgeTypeExists(_badgeTypeId) {
        require(totalBadgesMintedOfType[_badgeTypeId] >= _amount, "Cannot burn more badges than minted.");
        require(_amount > 0, "Burn amount must be greater than zero.");

        totalBadgesMintedOfType[_badgeTypeId] -= _amount;
        // In a real NFT implementation, you might need to track individual token IDs and burn them.
        // For this simple example, we just reduce the total minted count.
        emit SkillBadgeBurned(msg.sender, _badgeTypeId, _amount);
    }


    // --- Governance/Community Functions ---

    /**
     * @dev Allows users with sufficient reputation to propose a new skill badge type.
     * @param _badgeName Name of the proposed badge type.
     * @param _badgeDescription Description of the proposed badge type.
     * @param _badgeURI URI for the metadata of the proposed badge type.
     */
    function proposeNewBadgeType(string memory _badgeName, string memory _badgeDescription, string memory _badgeURI) external whenNotPaused reputationSufficientForProposal(msg.sender) {
        require(bytes(_badgeName).length > 0, "Badge name cannot be empty.");

        badgeTypeProposals[nextBadgeTypeProposalId] = BadgeTypeProposal({
            id: nextBadgeTypeProposalId,
            name: _badgeName,
            description: _badgeDescription,
            badgeURI: _badgeURI,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
        });
        emit BadgeTypeProposalCreated(nextBadgeTypeProposalId, _badgeName, msg.sender);
        nextBadgeTypeProposalId++;
    }

    /**
     * @dev Allows users with reputation to vote on a badge type proposal.
     * @param _proposalId ID of the badge type proposal.
     * @param _vote True to vote for, false to vote against.
     */
    function voteOnBadgeTypeProposal(uint256 _proposalId, bool _vote) external whenNotPaused proposalExists(_proposalId) {
        require(badgeTypeProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(userReputation[msg.sender] > 0, "Reputation required to vote."); // Even low reputation can vote

        if (_vote) {
            badgeTypeProposals[_proposalId].votesFor++;
        } else {
            badgeTypeProposals[_proposalId].votesAgainst++;
        }
        emit BadgeTypeProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a badge type proposal if it has enough votes and time has passed.
     * @param _proposalId ID of the badge type proposal.
     */
    function executeBadgeTypeProposal(uint256 _proposalId) external onlyAdmin whenNotPaused proposalExists(_proposalId) {
        require(badgeTypeProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(badgeTypeProposals[_proposalId].votesFor > badgeTypeProposals[_proposalId].votesAgainst, "Proposal does not have enough votes in favor."); // Simple majority
        // Add time-based constraint or more complex quorum logic if needed

        createSkillBadgeType(
            badgeTypeProposals[_proposalId].name,
            badgeTypeProposals[_proposalId].description,
            badgeTypeProposals[_proposalId].badgeURI
        );
        badgeTypeProposals[_proposalId].status = ProposalStatus.Executed;
        emit BadgeTypeProposalExecuted(_proposalId, nextBadgeTypeId - 1); // Emit event with the newly created badge type ID.
    }

    /**
     * @dev (Optional) Function for users to report inappropriate content in challenges.
     * @param _challengeId ID of the challenge being reported.
     * @param _reportReason Reason for reporting the content.
     */
    function reportInappropriateContent(uint256 _challengeId, string memory _reportReason) external whenNotPaused challengeExists(_challengeId) {
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");
        // In a real system, you would store the report and trigger an admin review process.
        // For this example, we'll just emit an event.
        // event ContentReported(uint256 challengeId, address reporter, string reason);
        // emit ContentReported(_challengeId, msg.sender, _reportReason);
        // Admin could then review and take action (e.g., cancel challenge, penalize user).
    }


    // --- View Functions ---

    /**
     * @dev Gets detailed information about a specific challenge.
     * @param _challengeId ID of the challenge.
     * @return Challenge struct containing challenge details.
     */
    function getChallengeDetails(uint256 _challengeId) external view challengeExists(_challengeId) returns (Challenge memory) {
        return challenges[_challengeId];
    }

    /**
     * @dev Gets details of a specific skill badge type.
     * @param _badgeTypeId ID of the badge type.
     * @return SkillBadgeType struct containing badge type details.
     */
    function getSkillBadgeTypeDetails(uint256 _badgeTypeId) external view badgeTypeExists(_badgeTypeId) returns (SkillBadgeType memory) {
        return skillBadgeTypes[_badgeTypeId];
    }

    /**
     * @dev Gets the current platform administrator address.
     * @return The platform administrator address.
     */
    function getPlatformAdmin() external view returns (address) {
        return platformAdmin;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Gets the current platform fee percentage.
     * @return The platform fee percentage.
     */
    function getPlatformFeePercentage() external view returns (uint256) {
        return platformFeePercentage;
    }

    /**
     * @dev Gets the total number of skill badge types defined.
     * @return The total number of skill badge types.
     */
    function getTotalSkillBadgeTypes() external view returns (uint256) {
        return nextBadgeTypeId - 1;
    }

    /**
     * @dev Gets the total number of challenges created.
     * @return The total number of challenges.
     */
    function getTotalChallenges() external view returns (uint256) {
        return nextChallengeId - 1;
    }

    /**
     * @dev Gets details of a badge type proposal.
     * @param _proposalId ID of the badge type proposal.
     * @return BadgeTypeProposal struct containing proposal details.
     */
    function getBadgeTypeProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (BadgeTypeProposal memory) {
        return badgeTypeProposals[_proposalId];
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to mint skill badges and update balances.
     * @param _recipient Address to receive the badges.
     * @param _badgeTypeId ID of the badge type to mint.
     * @param _amount Amount of badges to mint.
     */
    function _mintSkillBadge(address _recipient, uint256 _badgeTypeId, uint256 _amount) internal badgeTypeExists(_badgeTypeId) {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount > 0, "Mint amount must be greater than zero.");

        userSkillBadgeBalances[_recipient][_badgeTypeId] += _amount;
        totalBadgesMintedOfType[_badgeTypeId] += _amount;
        emit SkillBadgeMinted(_recipient, _badgeTypeId, _amount);
    }

    /**
     * @dev Internal function to update user reputation.
     * @param _user Address of the user.
     * @param _reputationChange Amount to change reputation (can be positive or negative).
     */
    function _updateReputation(address _user, int256 _reputationChange) internal {
        uint256 oldReputation = userReputation[_user];
        // Ensure reputation doesn't go below 0
        if (_reputationChange < 0 && userReputation[_user] < uint256(abs(_reputationChange))) {
            userReputation[_user] = 0;
        } else {
            userReputation[_user] = userReputation[_user] + uint256(_reputationChange);
        }
        emit ReputationUpdated(_user, userReputation[_user], _reputationChange);
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}
```