```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Influence System (DRIS)
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a dynamic reputation and influence system within a community.
 *      This contract allows users to earn reputation through contributions, participate in community decisions based on their influence,
 *      and unlock benefits based on their reputation level. It incorporates elements of dynamic NFTs, staking for boosts,
 *      and decentralized governance, creating a unique and engaging community interaction platform.
 *
 * Function Summary:
 * -----------------
 * **Initialization & Admin:**
 * 1. initialize(string _contractName, address _admin)          : Initializes the contract with a name and admin address (only callable once).
 * 2. setAdmin(address _newAdmin)                            : Allows the current admin to change the admin address.
 * 3. setReputationThresholds(uint256[] _thresholds)        : Sets reputation points required for each influence level.
 * 4. setContributionReward(uint256 _reward)                 : Sets the base reputation points awarded for a successful contribution.
 * 5. pauseContract()                                        : Pauses core functionalities of the contract, only admin.
 * 6. unpauseContract()                                      : Resumes core functionalities of the contract, only admin.
 * 7. withdrawFees()                                         : Allows the admin to withdraw accumulated contract fees (if any).
 *
 * **User Reputation & Influence:**
 * 8. contribute(string memory _contributionDetails)          : Allows users to submit contributions to the community.
 * 9. voteOnContribution(uint256 _contributionId, bool _approve): Allows users to vote on pending contributions based on their influence.
 * 10. reportContribution(uint256 _contributionId, string memory _reportReason): Allows users to report contributions for review.
 * 11. getReputation(address _user)                          : Returns the reputation points of a user.
 * 12. getLevel(address _user)                               : Returns the influence level of a user based on their reputation.
 *
 * **Dynamic NFT Badges:**
 * 13. mintBadge()                                           : Mints a dynamic NFT badge to a user based on reaching a new influence level.
 * 14. transferBadge(address _to, uint256 _tokenId)         : Allows badge holders to transfer their badges. (Standard NFT function).
 * 15. getBadgeOf(address _user)                             : Returns the token ID of the badge owned by a user (if any).
 *
 * **Staking & Reputation Boost:**
 * 16. stakeTokens(uint256 _amount)                           : Allows users to stake platform tokens to boost their reputation gain.
 * 17. unstakeTokens(uint256 _amount)                         : Allows users to unstake their tokens, reducing their reputation boost.
 * 18. boostReputation(address _user)                         : Applies reputation boost to a user based on their staked tokens. (Internal function, triggered on events).
 * 19. getBoostMultiplier(address _user)                     : Returns the current reputation boost multiplier for a user.
 *
 * **Information Retrieval:**
 * 20. getContributionDetails(uint256 _contributionId)      : Returns details of a specific contribution.
 * 21. getChallengeDetails(uint256 _challengeId)            : Returns details of a specific community challenge.
 * 22. getReputationThresholdForLevel(uint256 _level)        : Returns the reputation points threshold for a given influence level.
 *
 * **Community Challenges (Bonus - can be considered as extra functionality beyond 20):**
 * 23. createChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _reward) : Allows high-influence users to propose community challenges.
 * 24. submitChallengeSolution(uint256 _challengeId, string memory _solutionDetails) : Allows users to submit solutions for active challenges.
 * 25. voteOnSolution(uint256 _challengeId, uint256 _solutionId, bool _approve) : Allows users to vote on submitted solutions.
 * 26. rewardChallengeWinners(uint256 _challengeId)         : Rewards winners of a completed challenge with reputation points.
 */
contract DynamicReputationSystem {
    string public contractName;
    address public admin;
    bool public paused;

    // --- Reputation and Influence ---
    mapping(address => uint256) public reputationPoints;
    uint256[] public reputationThresholds; // Reputation needed for each level (Level 1 threshold at index 0, Level 2 at index 1, etc.)
    uint256 public contributionReward = 10; // Base reward for successful contributions
    uint256 public stakingBoostFactor = 100; // Amount of tokens staked per 1% reputation boost

    // --- Contributions ---
    uint256 public contributionCount;
    struct Contribution {
        uint256 id;
        address contributor;
        string details;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool reported;
        ContributionStatus status;
        uint256 createdAt;
    }
    enum ContributionStatus { Pending, Approved, Rejected, Reported }
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => mapping(address => bool)) public contributionVotes; // contributionId => voter => voted (true/false)

    // --- Reporting ---
    uint256 public reportThreshold = 3; // Number of reports needed to mark a contribution as 'Reported'

    // --- Dynamic NFT Badges ---
    string public badgeName = "Influence Badge";
    string public badgeSymbol = "INFB";
    uint256 public badgeCount;
    mapping(address => uint256) public userBadges; // user address => tokenId
    mapping(uint256 => address) public badgeOwners; // tokenId => user address
    mapping(uint256 => uint256) public badgeLevel; // tokenId => influence level when minted

    // --- Staking for Boost ---
    mapping(address => uint256) public stakedTokenBalance; // User's staked token balance (assume using platform's token)
    // In a real implementation, you'd likely integrate with an ERC20 token contract.
    // For simplicity, we'll just track staked amounts here.

    // --- Events ---
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ReputationEarned(address indexed user, uint256 amount, string reason);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, bool approved);
    event ContributionReported(uint256 indexed contributionId, address reporter, string reason);
    event ContributionStatusUpdated(uint256 indexed contributionId, ContributionStatus newStatus);
    event BadgeMinted(uint256 indexed tokenId, address indexed owner, uint256 level);
    event BadgeTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event ReputationBoostApplied(address indexed user, uint256 boostPercentage);
    event ChallengeCreated(uint256 indexed challengeId, string title, address creator);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, uint256 solutionId, address solver);
    event ChallengeSolutionVoted(uint256 indexed challengeId, uint256 solutionId, address voter, bool approved);
    event ChallengeWinnersRewarded(uint256 indexed challengeId, address[] winners, uint256 rewardPerWinner);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier contributionExists(uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= contributionCount, "Contribution does not exist.");
        _;
    }

    modifier notContributor(uint256 _contributionId) {
        require(contributions[_contributionId].contributor != msg.sender, "Contributor cannot vote on their own contribution.");
        _;
    }

    modifier notAlreadyVoted(uint256 _contributionId) {
        require(!contributionVotes[_contributionId][msg.sender], "Already voted on this contribution.");
        _;
    }

    modifier validLevel(uint256 _level) {
        require(_level > 0 && _level <= reputationThresholds.length + 1, "Invalid influence level.");
        _;
    }


    constructor() {
        // Contract name is set during initialization
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    /// @dev Initializes the contract with a name and admin address. Can only be called once.
    /// @param _contractName The name of the reputation system.
    /// @param _admin The initial admin address.
    function initialize(string memory _contractName, address _admin) public onlyAdmin {
        require(bytes(contractName).length == 0, "Contract already initialized.");
        contractName = _contractName;
        setAdmin(_admin); // Set admin using the admin change function for event emission
    }

    /// @dev Sets a new admin address. Only callable by the current admin.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /// @dev Sets the reputation points required for each influence level.
    /// @param _thresholds An array of reputation thresholds. Level 1 threshold is at index 0, Level 2 at index 1, etc.
    function setReputationThresholds(uint256[] memory _thresholds) public onlyAdmin {
        reputationThresholds = _thresholds;
    }

    /// @dev Sets the base reputation points awarded for a successful contribution.
    /// @param _reward The amount of reputation points to award.
    function setContributionReward(uint256 _reward) public onlyAdmin {
        contributionReward = _reward;
    }

    /// @dev Pauses the contract, preventing core functionalities from being used. Only callable by the admin.
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @dev Unpauses the contract, resuming core functionalities. Only callable by the admin.
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @dev Allows the admin to withdraw any accumulated fees in the contract (if any).
    function withdrawFees() public onlyAdmin {
        // In a real scenario, you might have fees accumulated from certain actions.
        // For this example, we'll just assume there's a payable function somewhere that might leave ETH in the contract.
        payable(admin).transfer(address(this).balance);
    }

    /// @dev Allows users to submit a contribution to the community.
    /// @param _contributionDetails A string describing the contribution.
    function contribute(string memory _contributionDetails) public whenNotPaused {
        contributionCount++;
        contributions[contributionCount] = Contribution({
            id: contributionCount,
            contributor: msg.sender,
            details: _contributionDetails,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            reported: false,
            status: ContributionStatus.Pending,
            createdAt: block.timestamp
        });
        emit ContributionSubmitted(contributionCount, msg.sender);
    }

    /// @dev Allows users to vote on a pending contribution. Influence level affects vote weight (not implemented in this simple version).
    /// @param _contributionId The ID of the contribution to vote on.
    /// @param _approve True to approve, false to disapprove.
    function voteOnContribution(uint256 _contributionId, bool _approve)
        public
        whenNotPaused
        contributionExists(_contributionId)
        notContributor(_contributionId)
        notAlreadyVoted(_contributionId)
    {
        contributionVotes[_contributionId][msg.sender] = true; // Mark as voted
        if (_approve) {
            contributions[_contributionId].upvotes++;
        } else {
            contributions[_contributionId].downvotes++;
        }
        emit ContributionVoted(_contributionId, msg.sender, _approve);

        // Simple approval mechanism: more upvotes than downvotes (can be customized)
        if (contributions[_contributionId].upvotes > contributions[_contributionId].downvotes && contributions[_contributionId].status == ContributionStatus.Pending) {
            _approveContribution(_contributionId);
        } else if (contributions[_contributionId].downvotes > contributions[_contributionId].upvotes && contributions[_contributionId].status == ContributionStatus.Pending) {
            _rejectContribution(_contributionId);
        }
    }

    /// @dev Internal function to approve a contribution and reward the contributor.
    /// @param _contributionId The ID of the contribution to approve.
    function _approveContribution(uint256 _contributionId) internal whenNotPaused contributionExists(_contributionId) {
        contributions[_contributionId].approved = true;
        contributions[_contributionId].status = ContributionStatus.Approved;
        reputationPoints[contributions[_contributionId].contributor] += contributionReward;
        emit ReputationEarned(contributions[_contributionId].contributor, contributionReward, "Contribution Approved");
        emit ContributionStatusUpdated(_contributionId, ContributionStatus.Approved);
        _checkAndMintBadge(contributions[_contributionId].contributor); // Check for badge minting after reputation gain
    }

    /// @dev Internal function to reject a contribution.
    /// @param _contributionId The ID of the contribution to reject.
    function _rejectContribution(uint256 _contributionId) internal whenNotPaused contributionExists(_contributionId) {
        contributions[_contributionId].approved = false;
        contributions[_contributionId].status = ContributionStatus.Rejected;
        emit ContributionStatusUpdated(_contributionId, ContributionStatus.Rejected);
    }


    /// @dev Allows users to report a contribution for review.
    /// @param _contributionId The ID of the contribution being reported.
    /// @param _reportReason Reason for reporting the contribution.
    function reportContribution(uint256 _contributionId, string memory _reportReason)
        public
        whenNotPaused
        contributionExists(_contributionId)
    {
        require(contributions[_contributionId].status != ContributionStatus.Reported, "Contribution already reported.");
        contributions[_contributionId].reported = true;
        contributions[_contributionId].status = ContributionStatus.Reported; // Update status to Reported
        emit ContributionReported(_contributionId, msg.sender, _reportReason);
        emit ContributionStatusUpdated(_contributionId, ContributionStatus.Reported);

        // In a real system, you might have an admin review reported contributions.
        // For this example, we'll just mark it as reported.
    }

    /// @dev Gets the reputation points of a user.
    /// @param _user The address of the user.
    /// @return The reputation points of the user.
    function getReputation(address _user) public view returns (uint256) {
        return reputationPoints[_user];
    }

    /// @dev Gets the influence level of a user based on their reputation points.
    /// @param _user The address of the user.
    /// @return The influence level of the user (1, 2, 3, etc.). Returns 1 if below level 1 threshold.
    function getLevel(address _user) public view returns (uint256) {
        uint256 userReputation = reputationPoints[_user];
        for (uint256 i = 0; i < reputationThresholds.length; i++) {
            if (userReputation < reputationThresholds[i]) {
                return i + 1; // Level is index + 1 (Level 1, Level 2, etc.)
            }
        }
        return reputationThresholds.length + 1; // User reached the highest level
    }

    /// @dev Mints a dynamic NFT badge to a user if they reach a new influence level.
    function mintBadge() public whenNotPaused {
        uint256 currentLevel = getLevel(msg.sender);
        uint256 existingBadgeId = userBadges[msg.sender];

        if (existingBadgeId == 0) { // No badge minted yet
            badgeCount++;
            userBadges[msg.sender] = badgeCount;
            badgeOwners[badgeCount] = msg.sender;
            badgeLevel[badgeCount] = currentLevel;
            emit BadgeMinted(badgeCount, msg.sender, currentLevel);
        } else {
            uint256 existingBadgeLevel = badgeLevel[existingBadgeId];
            if (currentLevel > existingBadgeLevel) { // User reached a higher level, update badge
                badgeLevel[existingBadgeId] = currentLevel; // Update badge level
                emit BadgeMinted(existingBadgeId, msg.sender, currentLevel); // Re-emit Minted event to signify level update (could have a separate 'BadgeLevelUpgraded' event for clarity)
            }
            // If level hasn't increased, no new badge is minted or updated.
        }
    }

    /// @dev Internal function to check if a user should mint a badge after gaining reputation.
    /// @param _user The address of the user.
    function _checkAndMintBadge(address _user) internal {
        uint256 currentLevel = getLevel(_user);
        uint256 existingBadgeId = userBadges[_user];

        if (existingBadgeId == 0) { // No badge minted yet, mint initial badge
            badgeCount++;
            userBadges[_user] = badgeCount;
            badgeOwners[badgeCount] = _user;
            badgeLevel[badgeCount] = currentLevel;
            emit BadgeMinted(badgeCount, _user, currentLevel);
        } else {
            uint256 existingBadgeLevel = badgeLevel[existingBadgeId];
            if (currentLevel > existingBadgeLevel) { // User reached a higher level, update badge
                badgeLevel[existingBadgeId] = currentLevel; // Update badge level
                emit BadgeMinted(existingBadgeId, _user, currentLevel); // Re-emit Minted event for level update
            }
        }
    }

    /// @dev Allows badge holders to transfer their badge to another address. (Standard NFT transfer function)
    /// @param _to The address to transfer the badge to.
    /// @param _tokenId The ID of the badge token to transfer.
    function transferBadge(address _to, uint256 _tokenId) public whenNotPaused {
        require(badgeOwners[_tokenId] == msg.sender, "Not the owner of this badge.");
        require(_to != address(0), "Cannot transfer to zero address.");
        address from = msg.sender;
        badgeOwners[_tokenId] = _to;
        userBadges[from] = 0; // Remove badge association from sender
        userBadges[_to] = _tokenId; // Associate badge with receiver
        emit BadgeTransferred(_tokenId, from, _to);
    }

    /// @dev Gets the token ID of the badge owned by a user. Returns 0 if no badge owned.
    /// @param _user The address of the user.
    /// @return The token ID of the badge, or 0 if no badge.
    function getBadgeOf(address _user) public view returns (uint256) {
        return userBadges[_user];
    }

    /// @dev Allows users to stake platform tokens to boost their reputation gain.
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount to stake must be greater than zero.");
        // In a real implementation, you'd transfer tokens from the user to the contract (ERC20 `transferFrom` or similar).
        // For this example, we just track the staked amount.
        stakedTokenBalance[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);
        _applyReputationBoost(msg.sender); // Apply boost immediately after staking
    }

    /// @dev Allows users to unstake their tokens, reducing their reputation boost.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount to unstake must be greater than zero.");
        require(stakedTokenBalance[msg.sender] >= _amount, "Insufficient staked tokens.");
        stakedTokenBalance[msg.sender] -= _amount;
        emit TokensUnstaked(msg.sender, _amount);
        _applyReputationBoost(msg.sender); // Re-apply boost after unstaking
    }

    /// @dev Internal function to apply reputation boost based on staked tokens.
    /// @param _user The address of the user to apply the boost to.
    function _applyReputationBoost(address _user) internal {
        uint256 stakedAmount = stakedTokenBalance[_user];
        uint256 boostPercentage = stakedAmount / stakingBoostFactor; // Example: 100 tokens staked = 1% boost

        // In a real system, you would modify reputation gain calculations in functions like `_approveContribution`
        // to incorporate this boost percentage.  For simplicity, we'll just emit an event indicating the boost.

        emit ReputationBoostApplied(_user, boostPercentage);
    }

    /// @dev Gets the current reputation boost multiplier for a user.
    /// @param _user The address of the user.
    /// @return The boost multiplier (e.g., 1.10 for 10% boost, 1.0 for no boost).
    function getBoostMultiplier(address _user) public view returns (uint256) {
        uint256 stakedAmount = stakedTokenBalance[_user];
        uint256 boostPercentage = stakedAmount / stakingBoostFactor;
        return 100 + boostPercentage; // Return as percentage (e.g., 100 = 100%, 110 = 110%, representing 1.0x and 1.1x multipliers)
    }

    /// @dev Gets details of a specific contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return Contribution struct containing contribution details.
    function getContributionDetails(uint256 _contributionId) public view contributionExists(_contributionId) returns (Contribution memory) {
        return contributions[_contributionId];
    }

    /// @dev Gets details of a specific community challenge. (Currently placeholder - challenge functionality not fully implemented in this example)
    /// @param _challengeId The ID of the challenge.
    /// @return Placeholder string. In a full implementation, would return challenge details.
    function getChallengeDetails(uint256 /*_challengeId*/) public view returns (string memory) {
        return "Challenge details functionality not fully implemented in this example.";
    }

    /// @dev Gets the reputation points threshold for a given influence level.
    /// @param _level The influence level (1, 2, 3, etc.).
    /// @return The reputation points required for that level, or 0 if level is invalid or exceeds defined levels.
    function getReputationThresholdForLevel(uint256 _level) public view validLevel(_level) returns (uint256) {
        if (_level > reputationThresholds.length) {
            return 0; // No threshold defined for levels beyond configured levels
        }
        return reputationThresholds[_level - 1]; // Level 1 is at index 0, Level 2 at index 1, etc.
    }

    // --- Community Challenges (Bonus Functions - can be added for more features) ---
    // Example challenge functions - these are basic and can be significantly expanded.
    uint256 public challengeCount;
    struct Challenge {
        uint256 id;
        string title;
        string description;
        address creator;
        uint256 reward;
        ChallengeStatus status;
        uint256 createdAt;
        uint256 solutionCount;
    }
    enum ChallengeStatus { Active, Voting, Completed, Cancelled }
    mapping(uint256 => Challenge) public challenges;

    struct Solution {
        uint256 id;
        uint256 challengeId;
        address solver;
        string details;
        uint256 upvotes;
        uint256 downvotes;
        SolutionStatus status;
        uint256 createdAt;
    }
    enum SolutionStatus { Pending, Approved, Rejected }
    mapping(uint256 => mapping(uint256 => Solution)) public solutions; // challengeId => solutionId => Solution
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public solutionVotes; // challengeId => solutionId => voter => voted

    /// @dev Allows high-influence users (e.g., level 3+) to create community challenges.
    /// @param _challengeTitle Title of the challenge.
    /// @param _challengeDescription Description of the challenge.
    /// @param _reward Reputation points reward for challenge completion.
    function createChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _reward) public whenNotPaused {
        require(getLevel(msg.sender) >= 3, "Only high-influence users can create challenges."); // Example influence level requirement
        challengeCount++;
        challenges[challengeCount] = Challenge({
            id: challengeCount,
            title: _challengeTitle,
            description: _challengeDescription,
            creator: msg.sender,
            reward: _reward,
            status: ChallengeStatus.Active,
            createdAt: block.timestamp,
            solutionCount: 0
        });
        emit ChallengeCreated(challengeCount, _challengeTitle, msg.sender);
    }

    /// @dev Allows users to submit solutions for active challenges.
    /// @param _challengeId ID of the challenge to submit a solution for.
    /// @param _solutionDetails Details of the submitted solution.
    function submitChallengeSolution(uint256 _challengeId, string memory _solutionDetails) public whenNotPaused {
        require(challenges[_challengeId].status == ChallengeStatus.Active, "Challenge is not active.");
        challenges[_challengeId].solutionCount++;
        uint256 solutionId = challenges[_challengeId].solutionCount;
        solutions[_challengeId][solutionId] = Solution({
            id: solutionId,
            challengeId: _challengeId,
            solver: msg.sender,
            details: _solutionDetails,
            upvotes: 0,
            downvotes: 0,
            status: SolutionStatus.Pending,
            createdAt: block.timestamp
        });
        emit ChallengeSolutionSubmitted(_challengeId, solutionId, msg.sender);
    }

    /// @dev Allows users to vote on submitted solutions for a challenge.
    /// @param _challengeId ID of the challenge.
    /// @param _solutionId ID of the solution to vote on.
    /// @param _approve True to approve, false to disapprove.
    function voteOnSolution(uint256 _challengeId, uint256 _solutionId, bool _approve) public whenNotPaused {
        require(challenges[_challengeId].status == ChallengeStatus.Active || challenges[_challengeId].status == ChallengeStatus.Voting, "Challenge is not in voting phase.");
        require(!solutionVotes[_challengeId][_solutionId][msg.sender], "Already voted on this solution.");
        solutionVotes[_challengeId][_solutionId][msg.sender] = true;

        if (_approve) {
            solutions[_challengeId][_solutionId].upvotes++;
        } else {
            solutions[_challengeId][_solutionId].downvotes++;
        }
        emit ChallengeSolutionVoted(_challengeId, _solutionId, msg.sender, _approve);

        // Simple solution approval mechanism (can be customized):
        if (solutions[_challengeId][_solutionId].upvotes > solutions[_challengeId][_solutionId].downvotes && solutions[_challengeId][_solutionId].status == SolutionStatus.Pending) {
           _approveSolution(_challengeId, _solutionId);
        } else if (solutions[_challengeId][_solutionId].downvotes > solutions[_challengeId][_solutionId].upvotes && solutions[_challengeId][_solutionId].status == SolutionStatus.Pending) {
            _rejectSolution(_challengeId, _solutionId);
        }
    }

    /// @dev Internal function to approve a solution.
    function _approveSolution(uint256 _challengeId, uint256 _solutionId) internal {
        solutions[_challengeId][_solutionId].status = SolutionStatus.Approved;
        emit ContributionStatusUpdated(_challengeId, ContributionStatus.Approved); // Reusing event - may need a dedicated SolutionStatusUpdated event

        // In a more complex scenario, you might select multiple winners or rank solutions.
        // For this simple example, we reward the solver of the first approved solution.
        rewardChallengeWinners(_challengeId, new address[](1) memory, solutions[_challengeId][_solutionId].solver); // Reward just the solver of this solution.  Could be modified to reward all approved solutions.
        challenges[_challengeId].status = ChallengeStatus.Completed; // Mark challenge as completed once a solution is approved.
    }

    /// @dev Internal function to reject a solution.
    function _rejectSolution(uint256 _challengeId, uint256 _solutionId) internal {
        solutions[_challengeId][_solutionId].status = SolutionStatus.Rejected;
        emit ContributionStatusUpdated(_challengeId, ContributionStatus.Rejected); // Reusing event - may need a dedicated SolutionStatusUpdated event
    }


    /// @dev Rewards winners of a completed challenge with reputation points.
    /// @param _challengeId ID of the challenge.
    /// @param _winners Array of winner addresses (can be modified to handle multiple winners or top solutions).
    /// @param _rewardPerWinner Reputation points reward per winner.
    function rewardChallengeWinners(uint256 _challengeId, address[] memory /*_winners*/, address _winner) internal { // Modified to take single winner for simplicity in `_approveSolution`
        address[] memory winners = new address[](1);
        winners[0] = _winner;
        uint256 rewardPerWinner = challenges[_challengeId].reward;

        for (uint256 i = 0; i < winners.length; i++) {
            reputationPoints[winners[i]] += rewardPerWinner;
            emit ReputationEarned(winners[i], rewardPerWinner, "Challenge Winner");
            _checkAndMintBadge(winners[i]); // Check for badge minting after reputation gain
        }
        emit ChallengeWinnersRewarded(_challengeId, winners, rewardPerWinner);
        challenges[_challengeId].status = ChallengeStatus.Completed;
    }

}
```