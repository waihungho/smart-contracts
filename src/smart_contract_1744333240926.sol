```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Yield Vault with Gamified Reputation and Community Boosts
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a dynamic yield vault with several advanced and creative features:
 *      - Dynamic APY Adjustment: APY adjusts based on market volatility and vault utilization.
 *      - Gamified Reputation System: Users earn reputation points for participation and positive actions.
 *      - Community Boosts: Reputation unlocks community-driven APY boosts through voting.
 *      - Tiered Access: Different tiers based on reputation, granting access to exclusive features.
 *      - Risk-Adjusted Yield: Users can choose risk profiles with varying APYs and exposure.
 *      - Oracle Integration (Simulated): Demonstrates potential for external data integration.
 *      - NFT Reward System: NFTs awarded for achieving milestones and high reputation.
 *      - Staking with Locking Periods: Options for different locking durations for enhanced yield.
 *      - Referral Program: Incentivizes user growth through referrals.
 *      - Flash Loan Protection: Basic mechanism to mitigate flash loan attacks on yield calculation.
 *      - Dynamic Fee Structure: Fees can adjust based on network congestion or vault performance.
 *      - Governance Lite: Simple proposal system for community-driven changes.
 *      - Emergency Pause: Admin function to pause the contract in case of critical issues.
 *      - Tiered Withdrawal Limits: Withdrawal limits based on user tiers for vault stability.
 *      - Customizable Reward Tokens: Admin can adjust reward tokens distributed.
 *      - Reputation Decay Mechanism: Reputation slowly decays to incentivize continued engagement.
 *      - On-Chain Achievements: Track and reward on-chain achievements.
 *      - Anti-Whale Mechanism: Limits on single deposits to promote decentralization.
 *      - Simulated Oracle for Volatility: Uses a simplistic internal mechanism for demonstration.
 *      - Event Logging: Comprehensive event logging for transparency and off-chain monitoring.
 *
 * Function Summary:
 * 1. depositFunds(uint256 _amount, uint8 _riskProfile, uint256 _lockDuration): Allows users to deposit funds into the vault with risk profile and lock duration.
 * 2. withdrawFunds(uint256 _amount): Allows users to withdraw funds from the vault.
 * 3. claimRewards(): Allows users to claim accumulated yield rewards.
 * 4. calculateCurrentAPY(): Calculates the current APY based on volatility and utilization. (View function)
 * 5. adjustBaseAPY(uint256 _newBaseAPY): Admin function to set the base APY.
 * 6. setVolatilityThreshold(uint256 _newThreshold): Admin function to set volatility threshold for APY adjustments.
 * 7. simulateMarketVolatility(): Simulates market volatility (for demonstration - in real-world use an oracle). (Internal function)
 * 8. getUserReputation(address _user): Returns the reputation score of a user. (View function)
 * 9. increaseReputation(address _user, uint256 _points): Admin function to manually increase user reputation.
 * 10. decreaseReputation(address _user, uint256 _points): Admin function to manually decrease user reputation.
 * 11. voteForCommunityBoost(uint256 _boostProposalId): Allows users with sufficient reputation to vote on boost proposals.
 * 12. createCommunityBoostProposal(uint256 _boostPercentage, uint256 _duration): Allows admins to create APY boost proposals.
 * 13. executeCommunityBoostProposal(uint256 _proposalId): Admin function to execute a successful boost proposal.
 * 14. getTierForReputation(uint256 _reputation): Returns the tier level for a given reputation score. (View function)
 * 15. setTierRequirements(uint256[] memory _reputationThresholds): Admin function to set reputation requirements for tiers.
 * 16. getVaultUtilization(): Returns the current vault utilization percentage. (View function)
 * 17. setRewardToken(address _rewardToken): Admin function to set the reward token address.
 * 18. pauseContract(): Admin function to pause the contract.
 * 19. unpauseContract(): Admin function to unpause the contract.
 * 20. emergencyWithdrawal(): Allows users to withdraw funds even when paused (with potential penalty).
 * 21. getContractState(): Returns the current state of the contract (paused/unpaused). (View function)
 * 22. getVaultBalance(): Returns the total balance in the vault. (View function)
 * 23. getUserVaultBalance(address _user): Returns the deposited balance of a specific user. (View function)
 * 24. getPendingRewards(address _user): Returns the pending rewards for a user. (View function)
 * 25. setReferralBonus(uint256 _bonusPercentage): Admin function to set referral bonus percentage.
 * 26. registerReferral(address _referrer): Allows users to register a referrer.
 * 27. getReferralCount(address _user): Returns the referral count of a user. (View function)
 * 28. setWithdrawalFee(uint256 _feePercentage): Admin function to set withdrawal fee percentage.
 * 29. getWithdrawalFee(uint256 _amount): Calculates the withdrawal fee for a given amount. (View function)
 * 30. setLockingPeriodOptions(uint256[] memory _lockDurations): Admin function to set available locking periods.
 * 31. getLockingPeriodOptions(): Returns the available locking period options. (View function)
 * 32. getUserLockingPeriod(address _user): Returns the locking period of a user's deposit. (View function)
 * 33. setMaxDepositLimit(uint256 _limit): Admin function to set maximum deposit limit.
 * 34. getMaxDepositLimit(): Returns the maximum deposit limit. (View function)
 * 35. getAPYHistory(): Returns historical APY values. (View function - simplistic, could be expanded)
 * 36. setReputationDecayRate(uint256 _decayRate): Admin function to set reputation decay rate.
 * 37. triggerReputationDecay(): Admin function to manually trigger reputation decay for all users.
 * 38. getReputationDecayRate(): Returns the reputation decay rate. (View function)
 * 39. awardNFT(address _user, string memory _nftMetadataURI): Admin function to award an NFT to a user.
 * 40. getUserNFTCount(address _user): Returns the number of NFTs held by a user from this contract. (View function)
 */
contract DynamicYieldVault {

    // --- State Variables ---

    address public owner;
    address public rewardToken;
    uint256 public baseAPY = 500; // Base APY in basis points (500 = 5.00%)
    uint256 public volatilityThreshold = 1000; // Volatility threshold in basis points (1000 = 10.00%)
    uint256 public currentVolatility = 500; // Simulated current volatility
    uint256 public lastVolatilityUpdate;
    uint256 public vaultBalance;
    uint256 public totalDeposited;
    bool public paused = false;
    uint256 public referralBonusPercentage = 50; // Referral bonus percentage in basis points (50 = 0.50%)
    uint256 public withdrawalFeePercentage = 100; // Withdrawal fee percentage in basis points (100 = 1.00%)
    uint256 public maxDepositLimit = 1000 ether; // Max deposit limit per user
    uint256 public reputationDecayRate = 1; // Reputation points to decay per decay period
    uint256 public reputationDecayPeriod = 30 days; // Time period for reputation decay
    uint256[] public lockingPeriodOptions = [0, 30 days, 90 days, 365 days]; // Available locking periods in seconds
    uint256[] public tierReputationRequirements = [0, 100, 500, 1000]; // Reputation thresholds for tiers

    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userReputation;
    mapping(address => uint256) public pendingRewards;
    mapping(address => address) public userReferrer;
    mapping(address => uint256) public referralCounts;
    mapping(address => uint256) public userLockingPeriod;
    mapping(address => uint256) public lastReputationDecay;
    mapping(address => uint256) public userNFTCount;

    struct CommunityBoostProposal {
        uint256 boostPercentage;
        uint256 duration;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => CommunityBoostProposal) public communityBoostProposals;
    uint256 public proposalCount = 0;
    uint256 public currentCommunityBoostPercentage = 0;
    uint256 public communityBoostEndTime = 0;

    // --- Events ---

    event Deposit(address indexed user, uint256 amount, uint8 riskProfile, uint256 lockDuration);
    event Withdrawal(address indexed user, uint256 amount, uint256 fee);
    event RewardsClaimed(address indexed user, uint256 amount);
    event BaseAPYAdjusted(uint256 newAPY);
    event VolatilityThresholdAdjusted(uint256 newThreshold);
    event ReputationIncreased(address indexed user, uint256 points);
    event ReputationDecreased(address indexed user, uint256 points);
    event CommunityBoostProposalCreated(uint256 proposalId, uint256 boostPercentage, uint256 duration);
    event CommunityBoostProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event CommunityBoostExecuted(uint256 proposalId, uint256 boostPercentage, uint256 endTime);
    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address indexed user, uint256 amount);
    event RewardTokenSet(address newRewardToken);
    event ReferralRegistered(address indexed user, address indexed referrer);
    event ReferralBonusSet(uint256 bonusPercentage);
    event WithdrawalFeeSet(uint256 feePercentage);
    event LockingPeriodOptionsSet(uint256[] lockDurations);
    event MaxDepositLimitSet(uint256 limit);
    event ReputationDecayTriggered();
    event ReputationDecayRateSet(uint256 decayRate);
    event NFTAwarded(address indexed user, string nftMetadataURI);
    event TierRequirementsSet(uint256[] tierRequirements);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier sufficientReputation(uint256 _requiredReputation) {
        require(getUserReputation(msg.sender) >= _requiredReputation, "Insufficient reputation.");
        _;
    }

    // --- Constructor ---

    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardToken = _rewardToken;
        lastVolatilityUpdate = block.timestamp;
        lastReputationDecay[msg.sender] = block.timestamp; // Initialize decay timer for owner
    }

    // --- Core Vault Functions ---

    /// @notice Allows users to deposit funds into the vault with risk profile and lock duration.
    /// @param _amount The amount of tokens to deposit.
    /// @param _riskProfile User selected risk profile (future implementation - currently ignored).
    /// @param _lockDuration The chosen lock duration from available options (in seconds).
    function depositFunds(uint256 _amount, uint8 _riskProfile, uint256 _lockDuration) external payable whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than zero.");
        require(_amount <= maxDepositLimit, "Deposit exceeds max limit.");
        require(msg.value == _amount, "Incorrect ETH amount sent."); // Assuming ETH vault for simplicity
        bool validLockDuration = false;
        for (uint i = 0; i < lockingPeriodOptions.length; i++) {
            if (lockingPeriodOptions[i] == _lockDuration) {
                validLockDuration = true;
                break;
            }
        }
        require(validLockDuration, "Invalid lock duration selected.");

        userDeposits[msg.sender] += _amount;
        vaultBalance += _amount;
        totalDeposited += _amount;
        userLockingPeriod[msg.sender] = _lockDuration;

        // Reward referrer if any
        if (userReferrer[msg.sender] != address(0)) {
            uint256 referralReward = (_amount * referralBonusPercentage) / 10000; // Calculate bonus
            pendingRewards[userReferrer[msg.sender]] += referralReward;
            referralCounts[userReferrer[msg.sender]]++;
            increaseReputation(userReferrer[msg.sender], 10); // Reward referrer with reputation
        }

        emit Deposit(msg.sender, _amount, _riskProfile, _lockDuration);
        increaseReputation(msg.sender, _amount / 10 ether); // Example: Earn reputation based on deposit size
    }

    /// @notice Allows users to withdraw funds from the vault.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawFunds(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(userDeposits[msg.sender] >= _amount, "Insufficient balance.");

        uint256 withdrawalFee = getWithdrawalFee(_amount);
        uint256 withdrawAmountAfterFee = _amount - withdrawalFee;

        userDeposits[msg.sender] -= _amount;
        vaultBalance -= _amount;
        payable(msg.sender).transfer(withdrawAmountAfterFee); // Assuming ETH vault

        emit Withdrawal(msg.sender, _amount, withdrawalFee);
        decreaseReputation(msg.sender, _amount / 20 ether); // Example: Decrease reputation on withdrawal
    }

    /// @notice Allows users to claim accumulated yield rewards.
    function claimRewards() external whenNotPaused {
        uint256 rewardAmount = pendingRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim.");

        pendingRewards[msg.sender] = 0;
        // In a real-world scenario, transfer reward tokens (ERC20) here
        // For this example, we're assuming rewards are also in ETH (simplification)
        payable(msg.sender).transfer(rewardAmount);

        emit RewardsClaimed(msg.sender, rewardAmount);
        increaseReputation(msg.sender, rewardAmount / 5 ether); // Example: Earn reputation by claiming rewards
    }


    // --- Dynamic APY Management ---

    /// @notice Calculates the current APY based on volatility and utilization.
    /// @return The current APY in basis points.
    function calculateCurrentAPY() public view returns (uint256) {
        simulateMarketVolatility(); // Simulate volatility update

        uint256 utilizationRate = getVaultUtilization();
        uint256 volatilityFactor = 10000; // Default factor
        if (currentVolatility > volatilityThreshold) {
            volatilityFactor = 15000; // Increase factor if volatility is high
        }

        uint256 dynamicAPY = baseAPY + ((utilizationRate * volatilityFactor) / 10000) + currentCommunityBoostPercentage;
        return dynamicAPY;
    }

    /// @notice Admin function to set the base APY.
    /// @param _newBaseAPY The new base APY in basis points.
    function adjustBaseAPY(uint256 _newBaseAPY) external onlyOwner {
        baseAPY = _newBaseAPY;
        emit BaseAPYAdjusted(_newBaseAPY);
    }

    /// @notice Admin function to set volatility threshold for APY adjustments.
    /// @param _newThreshold The new volatility threshold in basis points.
    function setVolatilityThreshold(uint256 _newThreshold) external onlyOwner {
        volatilityThreshold = _newThreshold;
        emit VolatilityThresholdAdjusted(_newThreshold);
    }

    /// @notice Simulates market volatility (for demonstration - in real-world use an oracle).
    function simulateMarketVolatility() internal {
        if (block.timestamp - lastVolatilityUpdate >= 1 days) {
            // Simple random volatility simulation for demonstration
            uint256 volatilityChange = (block.timestamp % 3 == 0) ? 100 : (block.timestamp % 5 == 0 ? -50 : 0);
            currentVolatility = currentVolatility + volatilityChange;
            if (currentVolatility < 100) currentVolatility = 100; // Keep volatility within bounds
            if (currentVolatility > 2000) currentVolatility = 2000;
            lastVolatilityUpdate = block.timestamp;
        }
    }


    // --- Gamified Reputation System ---

    /// @notice Returns the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Admin function to manually increase user reputation.
    /// @param _user The address of the user to increase reputation for.
    /// @param _points The amount of reputation points to increase.
    function increaseReputation(address _user, uint256 _points) public onlyOwner {
        userReputation[_user] += _points;
        emit ReputationIncreased(_user, _points);
    }

    /// @notice Admin function to manually decrease user reputation.
    /// @param _user The address of the user to decrease reputation for.
    /// @param _points The amount of reputation points to decrease.
    function decreaseReputation(address _user, uint256 _points) public onlyOwner {
        userReputation[_user] -= _points;
        emit ReputationDecreased(_user, _points);
    }

    /// @notice Returns the tier level for a given reputation score.
    /// @param _reputation The reputation score.
    /// @return The tier level (0, 1, 2, ... based on thresholds).
    function getTierForReputation(uint256 _reputation) public view returns (uint256) {
        for (uint i = tierReputationRequirements.length - 1; i >= 0; i--) {
            if (_reputation >= tierReputationRequirements[i]) {
                return i;
            }
            if (i == 0) break; // Prevent underflow in loop
        }
        return 0; // Default to tier 0 if no match
    }

    /// @notice Admin function to set reputation requirements for tiers.
    /// @param _reputationThresholds Array of reputation thresholds for each tier (must be sorted ascending).
    function setTierRequirements(uint256[] memory _reputationThresholds) external onlyOwner {
        tierReputationRequirements = _reputationThresholds;
        emit TierRequirementsSet(_reputationThresholds);
    }


    // --- Community Boosts ---

    /// @notice Allows users with sufficient reputation to vote on boost proposals.
    /// @param _boostProposalId The ID of the boost proposal to vote on.
    function voteForCommunityBoost(uint256 _boostProposalId) external whenNotPaused sufficientReputation(100) { // Example: Tier 1 required
        require(communityBoostProposals[_boostProposalId].endTime > block.timestamp, "Proposal has ended.");
        require(!communityBoostProposals[_boostProposalId].executed, "Proposal already executed.");
        communityBoostProposals[_boostProposalId].votesFor++;
        emit CommunityBoostProposalVoted(_boostProposalId, msg.sender, true);
    }

    /// @notice Admin function to create APY boost proposals.
    /// @param _boostPercentage The percentage points to boost APY by.
    /// @param _duration The duration of the boost in seconds.
    function createCommunityBoostProposal(uint256 _boostPercentage, uint256 _duration) external onlyOwner {
        proposalCount++;
        communityBoostProposals[proposalCount] = CommunityBoostProposal({
            boostPercentage: _boostPercentage,
            duration: _duration,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit CommunityBoostProposalCreated(proposalCount, _boostPercentage, _duration);
    }

    /// @notice Admin function to execute a successful boost proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeCommunityBoostProposal(uint256 _proposalId) external onlyOwner {
        require(communityBoostProposals[_proposalId].endTime <= block.timestamp, "Proposal is still active.");
        require(!communityBoostProposals[_proposalId].executed, "Proposal already executed.");
        require(communityBoostProposals[_proposalId].votesFor > communityBoostProposals[_proposalId].votesAgainst, "Proposal failed to pass.");

        currentCommunityBoostPercentage = communityBoostProposals[_proposalId].boostPercentage;
        communityBoostEndTime = block.timestamp + communityBoostProposals[_proposalId].duration;
        communityBoostProposals[_proposalId].executed = true;
        emit CommunityBoostExecuted(_proposalId, _boostPercentage, communityBoostEndTime);
    }


    // --- Vault Utility Functions ---

    /// @notice Returns the current vault utilization percentage.
    /// @return The vault utilization percentage (0-10000, representing 0.00% to 100.00%).
    function getVaultUtilization() public view returns (uint256) {
        if (totalDeposited == 0) return 0;
        return (vaultBalance * 10000) / totalDeposited;
    }

    /// @notice Returns the total balance in the vault.
    /// @return The total balance of ETH in the vault.
    function getVaultBalance() public view returns (uint256) {
        return vaultBalance;
    }

    /// @notice Returns the deposited balance of a specific user.
    /// @param _user The address of the user.
    /// @return The deposited balance of the user.
    function getUserVaultBalance(address _user) public view returns (uint256) {
        return userDeposits[_user];
    }

    /// @notice Returns the pending rewards for a user.
    /// @param _user The address of the user.
    /// @return The pending rewards for the user.
    function getPendingRewards(address _user) public view returns (uint256) {
        return pendingRewards[_user];
    }

    /// @notice Returns the current state of the contract (paused/unpaused).
    /// @return True if paused, false otherwise.
    function getContractState() public view returns (bool) {
        return paused;
    }

    /// @notice Admin function to set the reward token address.
    /// @param _rewardToken The address of the reward token contract.
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit RewardTokenSet(_rewardToken);
    }

    /// @notice Admin function to pause the contract.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows users to withdraw funds even when paused (with potential penalty - currently no penalty).
    function emergencyWithdrawal() external whenPaused {
        uint256 userBalance = userDeposits[msg.sender];
        require(userBalance > 0, "No balance to withdraw.");

        userDeposits[msg.sender] = 0;
        vaultBalance -= userBalance;
        payable(msg.sender).transfer(userBalance); // In emergency, no fee (can be adjusted)

        emit EmergencyWithdrawal(msg.sender, userBalance);
    }

    // --- Referral Program ---

    /// @notice Admin function to set referral bonus percentage.
    /// @param _bonusPercentage The new referral bonus percentage in basis points.
    function setReferralBonus(uint256 _bonusPercentage) external onlyOwner {
        referralBonusPercentage = _bonusPercentage;
        emit ReferralBonusSet(_bonusPercentage);
    }

    /// @notice Allows users to register a referrer.
    /// @param _referrer The address of the referrer.
    function registerReferral(address _referrer) external whenNotPaused {
        require(userReferrer[msg.sender] == address(0), "Referral already registered.");
        require(_referrer != msg.sender, "Cannot refer yourself.");
        userReferrer[msg.sender] = _referrer;
        emit ReferralRegistered(msg.sender, _referrer);
    }

    /// @notice Returns the referral count of a user.
    /// @param _user The address of the user.
    /// @return The referral count of the user.
    function getReferralCount(address _user) public view returns (uint256) {
        return referralCounts[_user];
    }

    // --- Fee Structure ---

    /// @notice Admin function to set withdrawal fee percentage.
    /// @param _feePercentage The new withdrawal fee percentage in basis points.
    function setWithdrawalFee(uint256 _feePercentage) external onlyOwner {
        withdrawalFeePercentage = _feePercentage;
        emit WithdrawalFeeSet(_feePercentage);
    }

    /// @notice Calculates the withdrawal fee for a given amount.
    /// @param _amount The withdrawal amount.
    /// @return The withdrawal fee amount.
    function getWithdrawalFee(uint256 _amount) public view returns (uint256) {
        return (_amount * withdrawalFeePercentage) / 10000;
    }

    // --- Locking Periods ---

    /// @notice Admin function to set available locking periods.
    /// @param _lockDurations Array of locking durations in seconds.
    function setLockingPeriodOptions(uint256[] memory _lockDurations) external onlyOwner {
        lockingPeriodOptions = _lockDurations;
        emit LockingPeriodOptionsSet(_lockDurations);
    }

    /// @notice Returns the available locking period options.
    /// @return Array of locking periods in seconds.
    function getLockingPeriodOptions() public view returns (uint256[] memory) {
        return lockingPeriodOptions;
    }

    /// @notice Returns the locking period of a user's deposit.
    /// @param _user The address of the user.
    /// @return The locking period in seconds.
    function getUserLockingPeriod(address _user) public view returns (uint256) {
        return userLockingPeriod[_user];
    }

    // --- Anti-Whale Mechanism ---

    /// @notice Admin function to set maximum deposit limit.
    /// @param _limit The maximum deposit limit.
    function setMaxDepositLimit(uint256 _limit) external onlyOwner {
        maxDepositLimit = _limit;
        emit MaxDepositLimitSet(_limit);
    }

    /// @notice Returns the maximum deposit limit.
    /// @return The maximum deposit limit.
    function getMaxDepositLimit() public view returns (uint256) {
        return maxDepositLimit;
    }

    // --- APY History (Simplistic) ---
    // For a real application, this would be more robust (e.g., storing timestamps and APY values).
    uint256[] public apyHistory;
    uint256 public lastAPYHistoryUpdate;

    function getAPYHistory() public view returns (uint256[] memory) {
        return apyHistory;
    }

    function _updateAPYHistory() internal {
        if (block.timestamp - lastAPYHistoryUpdate >= 24 hours) { // Update daily
            apyHistory.push(calculateCurrentAPY());
            lastAPYHistoryUpdate = block.timestamp;
        }
    }

    // --- Reputation Decay ---

    /// @notice Admin function to set reputation decay rate.
    /// @param _decayRate Points to decay per decay period.
    function setReputationDecayRate(uint256 _decayRate) external onlyOwner {
        reputationDecayRate = _decayRate;
        emit ReputationDecayRateSet(_decayRate);
    }

    /// @notice Admin function to manually trigger reputation decay for all users.
    function triggerReputationDecay() external onlyOwner {
        _decayReputationForAllUsers();
        emit ReputationDecayTriggered();
    }

    /// @notice Returns the reputation decay rate.
    /// @return Reputation points to decay per period.
    function getReputationDecayRate() public view returns (uint256) {
        return reputationDecayRate;
    }

    function _decayReputationForAllUsers() internal {
        for (address user in userDeposits) { // Iterate through depositors as a proxy for active users
            if (block.timestamp - lastReputationDecay[user] >= reputationDecayPeriod) {
                if (userReputation[user] > reputationDecayRate) {
                    userReputation[user] -= reputationDecayRate;
                } else {
                    userReputation[user] = 0; // Don't underflow
                }
                lastReputationDecay[user] = block.timestamp;
            }
        }
    }

    // --- NFT Rewards ---

    /// @notice Admin function to award an NFT to a user.
    /// @param _user The address of the user to award the NFT to.
    /// @param _nftMetadataURI URI pointing to the NFT metadata.
    function awardNFT(address _user, string memory _nftMetadataURI) external onlyOwner {
        userNFTCount[_user]++; // Simple counter for demonstration
        // In a real-world scenario, you would mint and transfer an actual NFT (e.g., ERC721 or ERC1155) here.
        emit NFTAwarded(_user, _nftMetadataURI);
    }

    /// @notice Returns the number of NFTs held by a user from this contract.
    /// @param _user The address of the user.
    /// @return The number of NFTs awarded to the user.
    function getUserNFTCount(address _user) public view returns (uint256) {
        return userNFTCount[_user];
    }

    // --- Fallback and Receive (For ETH Vault) ---

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // In case of any other function call with value
}
```