```solidity
/**
 * @title Decentralized Reputation and Influence Platform - "NexusRank"
 * @author AI Assistant
 * @dev A smart contract for managing decentralized reputation and influence within a community or platform.
 *      NexusRank allows users to earn reputation through various contributions and actions, and this reputation
 *      can be used to gain influence, access privileges, and participate in community governance.
 *
 * Function Summary:
 * -----------------
 * **Core Reputation Management:**
 * 1. initializeUserReputation(): Initializes reputation for a new user.
 * 2. increaseReputation(address _user, uint256 _amount, string _reason): Increases a user's reputation points.
 * 3. decreaseReputation(address _user, uint256 _amount, string _reason): Decreases a user's reputation points.
 * 4. setReputation(address _user, uint256 _amount, string _reason): Sets a user's reputation points to a specific value (admin only).
 * 5. getReputation(address _user): Retrieves a user's current reputation points.
 * 6. applyReputationDecay(): Applies a decay factor to all users' reputation over time (admin scheduled task).
 * 7. setDecayRate(uint256 _newRate): Sets the reputation decay rate (admin only).
 * 8. getDecayRate(): Retrieves the current reputation decay rate.
 * 9. setReputationThresholdForLevel(uint8 _level, uint256 _threshold): Sets the reputation threshold for a specific reputation level (admin only).
 * 10. getReputationThresholdForLevel(uint8 _level): Retrieves the reputation threshold for a specific reputation level.
 * 11. getUserReputationLevel(address _user): Retrieves the reputation level of a user based on their reputation points.
 *
 * **Influence and Access Control:**
 * 12. checkReputationThreshold(address _user, uint256 _threshold): Checks if a user's reputation meets a certain threshold.
 * 13. registerInfluenceAction(string _actionName, uint256 _reputationRequired): Registers a new action that requires a certain reputation level to perform (admin only).
 * 14. getReputationRequiredForAction(string _actionName): Retrieves the reputation required to perform a specific action.
 * 15. canPerformAction(address _user, string _actionName): Checks if a user has enough reputation to perform a registered action.
 * 16. grantBadgeForLevel(uint8 _level, string _badgeName): Grants a badge name for a specific reputation level (admin only).
 * 17. getBadgeForLevel(uint8 _level): Retrieves the badge name associated with a reputation level.
 *
 * **Community Features & Advanced Concepts:**
 * 18. submitReputationBoostProposal(address _targetUser, uint256 _boostAmount, string _reason): Allows users with a certain reputation level to propose reputation boosts for others.
 * 19. voteOnReputationBoostProposal(uint256 _proposalId, bool _vote): Allows users with sufficient reputation to vote on boost proposals.
 * 20. executeReputationBoostProposal(uint256 _proposalId): Executes a passed reputation boost proposal (admin or governance role).
 * 21. createReputationChallenge(string _challengeName, uint256 _rewardAmount): Creates a reputation challenge with a reward for completion (admin only).
 * 22. completeReputationChallenge(string _challengeName): Allows a user to complete a reputation challenge and earn a reward.
 * 23. getChallengeReward(string _challengeName): Retrieves the reputation reward for a specific challenge.
 * 24. setGovernanceThreshold(uint256 _threshold): Sets the reputation threshold required for governance actions (admin only).
 * 25. checkGovernanceAccess(address _user): Checks if a user has sufficient reputation for governance actions.
 * 26. getContractVersion(): Returns the contract version for tracking updates.
 */
pragma solidity ^0.8.0;

contract NexusRank {
    // --- State Variables ---

    // Admin address to manage contract settings
    address public admin;

    // Mapping of user addresses to their reputation points
    mapping(address => uint256) public userReputations;

    // Reputation decay rate (percentage per time period, e.g., 0.01 for 1% decay)
    uint256 public reputationDecayRate = 0; // Default: No decay

    // Last time reputation decay was applied (for scheduled decay)
    uint256 public lastDecayTimestamp;

    // Mapping of reputation levels to their thresholds
    mapping(uint8 => uint256) public reputationLevelThresholds;

    // Mapping of action names to reputation required to perform them
    mapping(string => uint256) public actionReputationRequirements;

    // Mapping of reputation levels to badge names
    mapping(uint8 => string) public levelBadges;

    // Reputation boost proposals
    struct ReputationBoostProposal {
        address targetUser;
        uint256 boostAmount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }
    mapping(uint256 => ReputationBoostProposal) public boostProposals;
    uint256 public proposalCounter;

    // Reputation challenges
    mapping(string => uint256) public challengeRewards;
    mapping(address => mapping(string => bool)) public userChallengesCompleted;

    // Reputation threshold for governance actions
    uint256 public governanceReputationThreshold;

    // Contract version
    string public constant contractVersion = "1.0.0";

    // --- Events ---
    event ReputationInitialized(address user, uint256 initialReputation);
    event ReputationIncreased(address user, uint256 amount, string reason);
    event ReputationDecreased(address user, uint256 amount, string reason);
    event ReputationSet(address user, uint256 newReputation, string reason);
    event ReputationDecayApplied(uint256 timestamp, uint256 decayRate);
    event DecayRateUpdated(uint256 newRate);
    event ReputationThresholdSet(uint8 level, uint256 threshold);
    event ActionReputationRequirementSet(string actionName, uint256 reputationRequired);
    event BadgeForLevelSet(uint8 level, string badgeName);
    event ReputationBoostProposalCreated(uint256 proposalId, address proposer, address targetUser, uint256 boostAmount, string reason);
    event ReputationBoostProposalVoted(uint256 proposalId, address voter, bool vote);
    event ReputationBoostProposalExecuted(uint256 proposalId, address targetUser, uint256 boostedAmount);
    event ReputationChallengeCreated(string challengeName, uint256 rewardAmount);
    event ReputationChallengeCompleted(address user, string challengeName, uint256 rewardAmount);
    event GovernanceThresholdSet(uint256 threshold);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier reputationThresholdMet(address _user, uint256 _threshold) {
        require(userReputations[_user] >= _threshold, "Reputation threshold not met");
        _;
    }

    modifier governanceAccessRequired(address _user) {
        require(userReputations[_user] >= governanceReputationThreshold, "Governance reputation threshold not met");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        lastDecayTimestamp = block.timestamp; // Initialize decay timestamp
        governanceReputationThreshold = 10000; // Default governance threshold
        // Set default reputation levels and thresholds
        setReputationThresholdForLevel(1, 100);
        setReputationThresholdForLevel(2, 500);
        setReputationThresholdForLevel(3, 1000);
        setReputationThresholdForLevel(4, 5000);
        setReputationThresholdForLevel(5, 10000);
        // Set default badges (optional)
        grantBadgeForLevel(1, "Newcomer");
        grantBadgeForLevel(2, "Contributor");
        grantBadgeForLevel(3, "Influencer");
        grantBadgeForLevel(4, "Leader");
        grantBadgeForLevel(5, "Visionary");
    }

    // --- Core Reputation Management Functions ---

    /// @notice Initializes reputation for a new user with 0 points.
    /// @param _user The address of the user to initialize reputation for.
    function initializeUserReputation(address _user) public {
        require(userReputations[_user] == 0, "Reputation already initialized for this user");
        userReputations[_user] = 0;
        emit ReputationInitialized(_user, 0);
    }

    /// @notice Increases a user's reputation points.
    /// @param _user The address of the user to increase reputation for.
    /// @param _amount The amount of reputation points to increase.
    /// @param _reason A string describing the reason for the reputation increase.
    function increaseReputation(address _user, uint256 _amount, string memory _reason) public {
        userReputations[_user] += _amount;
        emit ReputationIncreased(_user, _amount, _reason);
    }

    /// @notice Decreases a user's reputation points.
    /// @param _user The address of the user to decrease reputation for.
    /// @param _amount The amount of reputation points to decrease.
    /// @param _reason A string describing the reason for the reputation decrease.
    function decreaseReputation(address _user, uint256 _amount, string memory _reason) public {
        require(userReputations[_user] >= _amount, "Cannot decrease reputation below zero"); // Prevent negative reputation
        userReputations[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, _reason);
    }

    /// @notice Sets a user's reputation points to a specific value (admin only).
    /// @param _user The address of the user to set reputation for.
    /// @param _amount The new reputation amount.
    /// @param _reason A string describing the reason for setting the reputation.
    function setReputation(address _user, uint256 _amount, string memory _reason) public onlyAdmin {
        userReputations[_user] = _amount;
        emit ReputationSet(_user, _amount, _reason);
    }

    /// @notice Retrieves a user's current reputation points.
    /// @param _user The address of the user to query.
    /// @return The user's current reputation points.
    function getReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    /// @notice Applies a decay factor to all users' reputation over time (admin scheduled task).
    function applyReputationDecay() public onlyAdmin {
        require(reputationDecayRate > 0, "Reputation decay rate is not set");
        uint256 timeElapsed = block.timestamp - lastDecayTimestamp;
        require(timeElapsed > 0, "No time elapsed since last decay"); // Prevent division by zero

        uint256 usersCount = 0; // In a real-world scenario, you might need to track users more efficiently for iteration. This example is simplified.
        address[] memory users = new address[](1000); // Assume max 1000 users for simplicity. In real-world, use a better user tracking mechanism.
        uint256 userIndex = 0;

        // Inefficient way to iterate through mapping keys (not recommended for large mappings in real-world)
        // For demonstration purposes, we'll assume we have a way to get a list of users (e.g., from events or external storage)
        // For this example, we'll use a placeholder to simulate user iteration.
        // In a real contract, you'd need a more robust user tracking mechanism.

        // Placeholder for user iteration (replace with actual user tracking logic)
        // This is just a simplified illustration. In a real contract, you'd need a better way to track users.
        // For example, maintain a list of registered users or iterate through events.
        address sampleUser1 = address(0x123);
        address sampleUser2 = address(0x456);
        address sampleUser3 = address(0x789);
        users[userIndex++] = sampleUser1;
        users[userIndex++] = sampleUser2;
        users[userIndex++] = sampleUser3;
        usersCount = userIndex; // Number of sample users

        for (uint256 i = 0; i < usersCount; i++) {
            address user = users[i];
            if (userReputations[user] > 0) {
                uint256 decayAmount = (userReputations[user] * reputationDecayRate) / 10000; // Assuming decayRate is in basis points (e.g., 100 for 1%)
                if (decayAmount > 0) {
                    decreaseReputation(user, decayAmount, "Reputation Decay");
                }
            }
        }

        lastDecayTimestamp = block.timestamp;
        emit ReputationDecayApplied(block.timestamp, reputationDecayRate);
    }


    /// @notice Sets the reputation decay rate (admin only).
    /// @param _newRate The new decay rate (e.g., 100 for 1%, in basis points).
    function setDecayRate(uint256 _newRate) public onlyAdmin {
        reputationDecayRate = _newRate;
        emit DecayRateUpdated(_newRate);
    }

    /// @notice Retrieves the current reputation decay rate.
    /// @return The current reputation decay rate.
    function getDecayRate() public view returns (uint256) {
        return reputationDecayRate;
    }

    /// @notice Sets the reputation threshold for a specific reputation level (admin only).
    /// @param _level The reputation level (e.g., 1, 2, 3...).
    /// @param _threshold The reputation points required for this level.
    function setReputationThresholdForLevel(uint8 _level, uint256 _threshold) public onlyAdmin {
        reputationLevelThresholds[_level] = _threshold;
        emit ReputationThresholdSet(_level, _threshold);
    }

    /// @notice Retrieves the reputation threshold for a specific reputation level.
    /// @param _level The reputation level to query.
    /// @return The reputation points required for the specified level.
    function getReputationThresholdForLevel(uint8 _level) public view returns (uint256) {
        return reputationLevelThresholds[_level];
    }

    /// @notice Retrieves the reputation level of a user based on their reputation points.
    /// @param _user The address of the user to check.
    /// @return The reputation level of the user.
    function getUserReputationLevel(address _user) public view returns (uint8) {
        uint256 reputation = userReputations[_user];
        for (uint8 level = 5; level >= 1; level--) {
            if (reputation >= reputationLevelThresholds[level]) {
                return level;
            }
        }
        return 0; // Level 0 if below level 1 threshold
    }

    // --- Influence and Access Control Functions ---

    /// @notice Checks if a user's reputation meets a certain threshold.
    /// @param _user The address of the user to check.
    /// @param _threshold The reputation threshold to compare against.
    /// @return True if the user's reputation is greater than or equal to the threshold, false otherwise.
    function checkReputationThreshold(address _user, uint256 _threshold) public view returns (bool) {
        return userReputations[_user] >= _threshold;
    }

    /// @notice Registers a new action that requires a certain reputation level to perform (admin only).
    /// @param _actionName The name of the action (e.g., "create_post", "vote_proposal").
    /// @param _reputationRequired The reputation points required to perform this action.
    function registerInfluenceAction(string memory _actionName, uint256 _reputationRequired) public onlyAdmin {
        actionReputationRequirements[_actionName] = _reputationRequired;
        emit ActionReputationRequirementSet(_actionName, _reputationRequired);
    }

    /// @notice Retrieves the reputation required to perform a specific action.
    /// @param _actionName The name of the action to query.
    /// @return The reputation points required to perform the action, or 0 if not registered.
    function getReputationRequiredForAction(string memory _actionName) public view returns (uint256) {
        return actionReputationRequirements[_actionName];
    }

    /// @notice Checks if a user has enough reputation to perform a registered action.
    /// @param _user The address of the user to check.
    /// @param _actionName The name of the action to check.
    /// @return True if the user has enough reputation, false otherwise.
    function canPerformAction(address _user, string memory _actionName) public view returns (bool) {
        uint256 requiredReputation = getReputationRequiredForAction(_actionName);
        return userReputations[_user] >= requiredReputation;
    }

    /// @notice Grants a badge name for a specific reputation level (admin only).
    /// @param _level The reputation level to assign the badge to.
    /// @param _badgeName The name of the badge (e.g., "Bronze Contributor", "Gold Star").
    function grantBadgeForLevel(uint8 _level, string memory _badgeName) public onlyAdmin {
        levelBadges[_level] = _badgeName;
        emit BadgeForLevelSet(_level, _badgeName);
    }

    /// @notice Retrieves the badge name associated with a reputation level.
    /// @param _level The reputation level to query.
    /// @return The badge name for the level, or an empty string if no badge is set.
    function getBadgeForLevel(uint8 _level) public view returns (string memory) {
        return levelBadges[_level];
    }

    // --- Community Features & Advanced Concepts ---

    /// @notice Allows users with a certain reputation level to propose reputation boosts for others.
    /// @param _targetUser The user to receive the proposed reputation boost.
    /// @param _boostAmount The amount of reputation points to boost.
    /// @param _reason The reason for the reputation boost proposal.
    function submitReputationBoostProposal(address _targetUser, uint256 _boostAmount, string memory _reason) public reputationThresholdMet(msg.sender, reputationLevelThresholds[2]) { // Level 2 or higher can propose
        proposalCounter++;
        boostProposals[proposalCounter] = ReputationBoostProposal({
            targetUser: _targetUser,
            boostAmount: _boostAmount,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });
        emit ReputationBoostProposalCreated(proposalCounter, msg.sender, _targetUser, _boostAmount, _reason);
    }

    /// @notice Allows users with sufficient reputation to vote on boost proposals.
    /// @param _proposalId The ID of the reputation boost proposal.
    /// @param _vote True to vote for, false to vote against.
    function voteOnReputationBoostProposal(uint256 _proposalId, bool _vote) public reputationThresholdMet(msg.sender, reputationLevelThresholds[3]) { // Level 3 or higher can vote
        require(!boostProposals[_proposalId].executed, "Proposal already executed");
        require(boostProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote"); // Proposer cannot vote

        if (_vote) {
            boostProposals[_proposalId].votesFor++;
        } else {
            boostProposals[_proposalId].votesAgainst++;
        }
        emit ReputationBoostProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed reputation boost proposal (admin or governance role).
    /// @param _proposalId The ID of the reputation boost proposal to execute.
    function executeReputationBoostProposal(uint256 _proposalId) public governanceAccessRequired(msg.sender) { // Governance role to execute
        require(!boostProposals[_proposalId].executed, "Proposal already executed");
        require(boostProposals[_proposalId].votesFor > boostProposals[_proposalId].votesAgainst, "Proposal not passed (more against votes)"); // Simple majority for now

        increaseReputation(boostProposals[_proposalId].targetUser, boostProposals[_proposalId].boostAmount, boostProposals[_proposalId].reason);
        boostProposals[_proposalId].executed = true;
        emit ReputationBoostProposalExecuted(_proposalId, boostProposals[_proposalId].targetUser, boostProposals[_proposalId].boostAmount);
    }

    /// @notice Creates a reputation challenge with a reward for completion (admin only).
    /// @param _challengeName The name of the challenge (e.g., "First Contribution", "Community Leader").
    /// @param _rewardAmount The reputation reward for completing the challenge.
    function createReputationChallenge(string memory _challengeName, uint256 _rewardAmount) public onlyAdmin {
        challengeRewards[_challengeName] = _rewardAmount;
        emit ReputationChallengeCreated(_challengeName, _rewardAmount);
    }

    /// @notice Allows a user to complete a reputation challenge and earn a reward.
    /// @param _challengeName The name of the challenge to complete.
    function completeReputationChallenge(string memory _challengeName) public {
        require(challengeRewards[_challengeName] > 0, "Challenge not found");
        require(!userChallengesCompleted[msg.sender][_challengeName], "Challenge already completed");

        userChallengesCompleted[msg.sender][_challengeName] = true;
        increaseReputation(msg.sender, challengeRewards[_challengeName], string.concat("Challenge Completed: ", _challengeName));
        emit ReputationChallengeCompleted(msg.sender, _challengeName, challengeRewards[_challengeName]);
    }

    /// @notice Retrieves the reputation reward for a specific challenge.
    /// @param _challengeName The name of the challenge to query.
    /// @return The reputation reward for the challenge, or 0 if not found.
    function getChallengeReward(string memory _challengeName) public view returns (uint256) {
        return challengeRewards[_challengeName];
    }

    /// @notice Sets the reputation threshold required for governance actions (admin only).
    /// @param _threshold The reputation points required for governance access.
    function setGovernanceThreshold(uint256 _threshold) public onlyAdmin {
        governanceReputationThreshold = _threshold;
        emit GovernanceThresholdSet(_threshold);
    }

    /// @notice Checks if a user has sufficient reputation for governance actions.
    /// @param _user The address of the user to check.
    /// @return True if the user has governance access, false otherwise.
    function checkGovernanceAccess(address _user) public view returns (bool) {
        return userReputations[_user] >= governanceReputationThreshold;
    }

    /// @notice Returns the contract version for tracking updates.
    /// @return The contract version string.
    function getContractVersion() public pure returns (string memory) {
        return contractVersion;
    }
}
```