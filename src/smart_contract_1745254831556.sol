```solidity
/**
 * @title Dynamic Yield Farming & Gamified Staking Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic yield farming and gamified staking platform.
 *
 * **Contract Outline:**
 * - **Core Staking & Yield Farming:** Allows users to stake tokens and earn rewards.
 * - **Dynamic APR:**  The Annual Percentage Rate (APR) is not fixed but dynamically adjusts based on various factors like total staked amount, time, and potentially external data sources (simulated in this example).
 * - **Gamified Staking Boosters:** Users can earn or purchase "Boosters" (represented by enums) to increase their staking rewards. Boosters could be tied to NFTs or other on-chain activities in a real implementation.
 * - **Tiered Staking System:**  Users are categorized into tiers based on their staked amounts, unlocking additional benefits or higher base APR.
 * - **Referral Program:** Users can refer others and earn a percentage of their referral's rewards.
 * - **Community Governance (Simplified):**  A basic governance mechanism allowing token holders to vote on certain contract parameters (simulated proposal and voting).
 * - **Emergency Brake & Admin Controls:**  Admin functions to pause the contract in emergencies, withdraw stuck tokens, and manage crucial parameters.
 * - **NFT Integration (Conceptual):**  Placeholder for future NFT integration to enhance boosters or tier benefits.
 *
 * **Function Summary:**
 * 1. **constructor(address _stakingToken, address _rewardToken, address _admin):** Initializes the contract with token addresses and admin.
 * 2. **setRewardToken(address _newRewardToken):** Admin function to update the reward token address.
 * 3. **setAPRParameters(uint256 _baseAPR, uint256 _aprFluctuation):** Admin function to set base APR and fluctuation range.
 * 4. **setTierThreshold(uint256 _tier, uint256 _threshold):** Admin function to set staking threshold for each tier.
 * 5. **setBoosterEffectiveness(BoosterType _booster, uint256 _effectiveness):** Admin function to set the reward boost percentage for each booster type.
 * 6. **stake(uint256 _amount):** Allows users to stake tokens.
 * 7. **unstake(uint256 _amount):** Allows users to unstake tokens.
 * 8. **claimRewards():** Allows users to claim accumulated rewards.
 * 9. **applyBooster(BoosterType _booster):** Allows users to apply a booster to their staking. (Conceptual - in real case, boosters might be NFTs or require specific conditions).
 * 10. **removeBooster(BoosterType _booster):** Allows users to remove a booster.
 * 11. **getPendingRewards(address _user):** View function to calculate pending rewards for a user.
 * 12. **getCurrentAPR():** View function to get the current dynamic APR.
 * 13. **getStakingBalance(address _user):** View function to get the staking balance of a user.
 * 14. **getUserTier(address _user):** View function to determine the tier of a user based on their stake.
 * 15. **getTierThreshold(uint256 _tier):** View function to get the staking threshold for a specific tier.
 * 16. **proposeParameterChange(string memory _parameterName, uint256 _newValue):**  Allows governance token holders to propose changes. (Simplified governance).
 * 17. **voteOnProposal(uint256 _proposalId, bool _vote):** Allows governance token holders to vote on active proposals. (Simplified governance).
 * 18. **executeProposal(uint256 _proposalId):** Admin/Governance function to execute a passed proposal. (Simplified governance).
 * 19. **pauseContract():** Admin function to pause the contract.
 * 20. **unpauseContract():** Admin function to unpause the contract.
 * 21. **emergencyWithdraw(address _tokenAddress, address _recipient, uint256 _amount):** Admin function for emergency withdrawal of any token.
 * 22. **setAdmin(address _newAdmin):** Admin function to change the contract administrator.
 * 23. **setReferrer(address _referrer):** Allows a user to set their referrer.
 * 24. **claimReferralRewards():** Allows users to claim referral rewards.
 * 25. **getReferralRewards(address _user):** View function to get the referral rewards of a user.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicYieldFarm is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public baseAPR = 1000; // Base APR in basis points (1000 = 10%)
    uint256 public aprFluctuation = 200; // APR fluctuation range in basis points

    uint256 public totalStaked;

    mapping(address => uint256) public stakingBalances;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public pendingRewards;
    mapping(address => BoosterType) public activeBoosters;
    mapping(address => address) public referrers;
    mapping(address => uint256) public referralRewardBalances;

    // Tiered Staking System
    uint256[3] public tierThresholds = [100 ether, 1000 ether, 10000 ether]; // Tier thresholds
    uint256[3] public tierAPRBoosts = [500, 1500, 3000]; // APR boosts for each tier (basis points)

    // Booster System
    enum BoosterType { NONE, SPEED, YIELD, LUCK }
    mapping(BoosterType => uint256) public boosterEffectiveness; // Effectiveness in percentage points (e.g., 100 = 100%)

    // Governance (Simplified)
    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    address public governanceToken; // Placeholder for governance token address

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event BoosterApplied(address indexed user, BoosterType booster);
    event BoosterRemoved(address indexed user, BoosterType booster);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ReferralSet(address indexed user, address indexed referrer);
    event ReferralRewardsClaimed(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPausedOrAdmin() {
        require(!paused() || msg.sender == owner(), "Contract is paused");
        _;
    }

    modifier onlyGovernanceTokenHolders() { // Simplified check - in real case, check token balance
        require(msg.sender == governanceToken || msg.sender == owner(), "Only governance token holders or admin can perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address _stakingToken, address _rewardToken, address _admin) payable Ownable(_admin) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        governanceToken = address(0); // In real case, set governance token address
        boosterEffectiveness[BoosterType.SPEED] = 150; // 15% boost
        boosterEffectiveness[BoosterType.YIELD] = 250; // 25% boost
        boosterEffectiveness[BoosterType.LUCK] = 100;  // 10% boost
    }

    // --- Admin Functions ---
    function setRewardToken(address _newRewardToken) external onlyOwner {
        rewardToken = IERC20(_newRewardToken);
    }

    function setAPRParameters(uint256 _baseAPR, uint256 _aprFluctuation) external onlyOwner {
        baseAPR = _baseAPR;
        aprFluctuation = _aprFluctuation;
    }

    function setTierThreshold(uint256 _tier, uint256 _threshold) external onlyOwner {
        require(_tier > 0 && _tier <= tierThresholds.length, "Invalid tier level");
        tierThresholds[_tier - 1] = _threshold;
    }

    function setBoosterEffectiveness(BoosterType _booster, uint256 _effectiveness) external onlyOwner {
        boosterEffectiveness[_booster] = _effectiveness;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance in contract");
        token.transfer(_recipient, _amount);
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
    }

    function setGovernanceToken(address _governanceToken) external onlyOwner {
        governanceToken = _governanceToken;
    }


    // --- Staking & Unstaking ---
    function stake(uint256 _amount) external whenNotPausedOrAdmin {
        require(_amount > 0, "Stake amount must be greater than zero");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingBalances[msg.sender] = stakingBalances[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);
        lastRewardTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external whenNotPausedOrAdmin {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(stakingBalances[msg.sender] >= _amount, "Insufficient staking balance");
        _updateRewards(msg.sender);
        stakingBalances[msg.sender] = stakingBalances[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() external whenNotPausedOrAdmin {
        _updateRewards(msg.sender);
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");
        pendingRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    // --- Boosters ---
    function applyBooster(BoosterType _booster) external whenNotPausedOrAdmin {
        require(activeBoosters[msg.sender] == BoosterType.NONE, "Booster already active"); // Only one booster at a time
        activeBoosters[msg.sender] = _booster;
        emit BoosterApplied(msg.sender, _booster);
    }

    function removeBooster(BoosterType _booster) external whenNotPausedOrAdmin {
        require(activeBoosters[msg.sender] == _booster, "Booster not active");
        activeBoosters[msg.sender] = BoosterType.NONE;
        emit BoosterRemoved(msg.sender, _booster);
    }

    // --- Referral Program ---
    function setReferrer(address _referrer) external whenNotPausedOrAdmin {
        require(referrers[msg.sender] == address(0), "Referrer already set");
        require(referrer != address(0) && referrer != msg.sender, "Invalid referrer address");
        referrers[msg.sender] = _referrer;
        emit ReferralSet(msg.sender, _referrer);
    }

    function claimReferralRewards() external whenNotPausedOrAdmin {
        uint256 rewards = referralRewardBalances[msg.sender];
        require(rewards > 0, "No referral rewards to claim");
        referralRewardBalances[msg.sender] = 0;
        rewardToken.transfer(msg.sender, rewards);
        emit ReferralRewardsClaimed(msg.sender, rewards);
    }


    // --- View Functions ---
    function getPendingRewards(address _user) public view returns (uint256) {
        uint256 currentAPR = getCurrentAPR();
        uint256 timeElapsed = block.timestamp.sub(lastRewardTime[_user]);
        uint256 rewardRate = stakingBalances[_user].mul(currentAPR).div(10000).div(365 days); // Rewards per second (approx.)
        uint256 rewards = rewardRate.mul(timeElapsed);
        uint256 boosterBoost = boosterEffectiveness[activeBoosters[_user]];
        if (boosterBoost > 0) {
            rewards = rewards.add(rewards.mul(boosterBoost).div(100)); // Apply booster effect
        }

        // Referral rewards are calculated separately and not included here.
        return rewards.add(pendingRewards[_user]);
    }

    function getCurrentAPR() public view returns (uint256) {
        uint256 dynamicAPR = baseAPR;
        if (totalStaked > 0) {
            // Example Dynamic APR Logic: APR decreases as total staked amount increases (simulated)
            uint256 stakedFactor = totalStaked.div(100000 ether); // Example factor - adjust as needed
            uint256 aprReduction = stakedFactor.mul(aprFluctuation);
            if (dynamicAPR > aprReduction) {
                dynamicAPR = dynamicAPR.sub(aprReduction);
            } else {
                dynamicAPR = 100; // Minimum APR to avoid zero
            }
        }

        // Apply Tier Boost
        uint256 tierBoost = getTierAPRBoost(msg.sender);
        dynamicAPR = dynamicAPR.add(tierBoost);

        return dynamicAPR;
    }

    function getStakingBalance(address _user) public view returns (uint256) {
        return stakingBalances[_user];
    }

    function getUserTier(address _user) public view returns (uint256) {
        uint256 balance = stakingBalances[_user];
        for (uint256 i = 0; i < tierThresholds.length; i++) {
            if (balance >= tierThresholds[i]) {
                return i + 1; // Tier levels are 1-indexed
            }
        }
        return 0; // Tier 0 if below all thresholds
    }

    function getTierThreshold(uint256 _tier) public view returns (uint256) {
        require(_tier > 0 && _tier <= tierThresholds.length, "Invalid tier level");
        return tierThresholds[_tier - 1];
    }

    function getReferralRewards(address _user) public view returns (uint256) {
        return referralRewardBalances[_user];
    }


    // --- Simplified Governance Functions ---
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyGovernanceTokenHolders whenNotPausedOrAdmin {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            passed: false
        });
        emit ParameterChangeProposed(proposalCount, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyGovernanceTokenHolders whenNotPausedOrAdmin {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPausedOrAdmin { // In real case, governance based execution
        require(proposals[_proposalId].isActive, "Proposal is not active");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed"); // Simple majority
        require(!proposal.passed, "Proposal already executed");

        proposal.isActive = false;
        proposal.passed = true;

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("baseAPR"))) {
            baseAPR = proposal.newValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("aprFluctuation"))) {
            aprFluctuation = proposal.newValue;
        } // Add more parameter checks here as needed

        emit ProposalExecuted(_proposalId);
    }


    // --- Internal Functions ---
    function _updateRewards(address _user) internal {
        uint256 currentAPR = getCurrentAPR();
        uint256 timeElapsed = block.timestamp.sub(lastRewardTime[_user]);
        uint256 rewardRate = stakingBalances[_user].mul(currentAPR).div(10000).div(365 days); // Rewards per second (approx.)
        uint256 rewards = rewardRate.mul(timeElapsed);

        uint256 boosterBoost = boosterEffectiveness[activeBoosters[_user]];
        if (boosterBoost > 0) {
            rewards = rewards.add(rewards.mul(boosterBoost).div(100)); // Apply booster effect
        }

        pendingRewards[_user] = pendingRewards[_user].add(rewards);
        lastRewardTime[_user] = block.timestamp;

        // Referral Rewards Calculation (Example - 5% of referrer's rewards)
        address referrer = referrers[_user];
        if (referrer != address(0)) {
            uint256 referralReward = rewards.mul(5).div(100); // 5% referral reward
            referralRewardBalances[referrer] = referralRewardBalances[referrer].add(referralReward);
        }
    }

    function getTierAPRBoost(address _user) internal view returns (uint256) {
        uint256 userTier = getUserTier(_user);
        if (userTier > 0 && userTier <= tierAPRBoosts.length) {
            return tierAPRBoosts[userTier - 1];
        }
        return 0; // No boost for tier 0 or invalid tier
    }
}
```