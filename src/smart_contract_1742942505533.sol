```solidity
/**
 * @title Advanced Gamified Yield Farming Platform with Dynamic NFTs and Challenge System
 * @author Bard (AI Assistant)
 * @dev This smart contract implements an advanced yield farming platform with gamification elements,
 *      dynamic NFTs, and a challenge system to enhance user engagement and create a unique DeFi experience.
 *      It features dynamic yield rates, booster NFTs that enhance farming, time-based challenges with rewards,
 *      a referral program, and sophisticated risk management mechanisms.

 * **Contract Outline and Function Summary:**

 * **1. Core Yield Farming Functions:**
 *    - `depositFunds(uint256 _amount)`: Allows users to deposit funds into the platform.
 *    - `withdrawFunds(uint256 _amount)`: Allows users to withdraw funds from the platform.
 *    - `stakeFunds(uint256 _amount)`: Stakes deposited funds into the yield farming pool.
 *    - `unstakeFunds(uint256 _amount)`: Unstakes funds from the yield farming pool.
 *    - `claimYield()`: Allows users to claim accumulated yield.
 *    - `calculateYield(address _user)`: (Internal/View) Calculates the yield for a user, considering boosters and dynamic rates.
 *    - `getYieldRate()`: (View) Returns the current base yield rate.
 *    - `setYieldRate(uint256 _newRate)`: (Admin) Sets a new base yield rate.
 *    - `getAccountBalance(address _user)`: (View) Returns the deposited balance of a user.
 *    - `getStakedBalance(address _user)`: (View) Returns the staked balance of a user.
 *    - `getClaimableYield(address _user)`: (View) Returns the claimable yield of a user.

 * **2. Dynamic Yield Rate Mechanism:**
 *    - `updateDynamicYieldRate()`: (Internal/Admin triggered) Updates the yield rate based on platform TVL or other dynamic factors.
 *    - `setDynamicRateFactor(uint256 _newFactor)`: (Admin) Sets the factor influencing dynamic yield rate adjustments.

 * **3. Booster NFT Integration:**
 *    - `setBoosterNFTContract(address _boosterNFTContract)`: (Admin) Sets the address of the Booster NFT contract.
 *    - `purchaseBoosterNFT(uint256 _boosterType)`: Allows users to purchase a Booster NFT (simulated interaction).
 *    - `activateBoosterNFT(uint256 _boosterId)`: Allows users to activate a Booster NFT to enhance yield.
 *    - `deactivateBoosterNFT(uint256 _boosterId)`: Allows users to deactivate a Booster NFT.
 *    - `getBoosterEffect(address _user)`: (Internal/View) Calculates the yield boost effect from active NFTs.

 * **4. Time-Based Challenge System:**
 *    - `startChallenge(string memory _challengeName, uint256 _startTime, uint256 _endTime, uint256 _rewardAmount)`: (Admin) Starts a new time-based challenge.
 *    - `endChallenge(uint256 _challengeId)`: (Admin) Ends a specific challenge and distributes rewards.
 *    - `participateInChallenge(uint256 _challengeId)`: Allows users to participate in an active challenge.
 *    - `claimChallengeReward(uint256 _challengeId)`: Allows users to claim rewards for completed challenges.
 *    - `getChallengeStatus(uint256 _challengeId)`: (View) Returns the status and details of a specific challenge.
 *    - `getCurrentChallenges()`: (View) Returns a list of currently active challenges.

 * **5. Referral Program:**
 *    - `setReferrer(address _referrer)`: Allows users to set a referrer address upon first deposit.
 *    - `getReferralCount(address _user)`: (View) Returns the number of users referred by a specific user.
 *    - `calculateReferralReward(address _referrer)`: (Internal/View) Calculates referral rewards (example - could be based on referred user's deposits).
 *    - `claimReferralReward()`: Allows users to claim accumulated referral rewards.

 * **6. Risk Management & Platform Control:**
 *    - `pauseContract()`: (Admin) Pauses core contract functionalities in case of emergency.
 *    - `unpauseContract()`: (Admin) Resumes core contract functionalities.
 *    - `setPlatformFee(uint256 _newFee)`: (Admin) Sets the platform fee charged on yield claims.
 *    - `getPlatformFee()`: (View) Returns the current platform fee percentage.
 *    - `collectPlatformFees()`: (Admin) Collects accumulated platform fees.
 *    - `getContractBalance()`: (View) Returns the total balance of the contract.
 *    - `emergencyWithdraw(address _recipient, uint256 _amount)`: (Admin - Extreme Emergency) Allows admin to withdraw funds in extreme emergency.

 * **7. Events:**
 *    - `Deposit(address indexed user, uint256 amount)`: Emitted when a user deposits funds.
 *    - `Withdrawal(address indexed user, uint256 amount)`: Emitted when a user withdraws funds.
 *    - `Stake(address indexed user, uint256 amount)`: Emitted when a user stakes funds.
 *    - `Unstake(address indexed user, uint256 amount)`: Emitted when a user unstakes funds.
 *    - `YieldClaimed(address indexed user, uint256 amount, uint256 fee)`: Emitted when a user claims yield.
 *    - `YieldRateUpdated(uint256 newRate)`: Emitted when the yield rate is updated.
 *    - `BoosterNFTActivated(address indexed user, uint256 boosterId)`: Emitted when a booster NFT is activated.
 *    - `BoosterNFTDeactivated(address indexed user, uint256 boosterId)`: Emitted when a booster NFT is deactivated.
 *    - `ChallengeStarted(uint256 challengeId, string challengeName, uint256 startTime, uint256 endTime, uint256 rewardAmount)`: Emitted when a challenge starts.
 *    - `ChallengeEnded(uint256 challengeId)`: Emitted when a challenge ends.
 *    - `ChallengeParticipation(address indexed user, uint256 challengeId)`: Emitted when a user participates in a challenge.
 *    - `ChallengeRewardClaimed(address indexed user, uint256 challengeId, uint256 rewardAmount)`: Emitted when a user claims a challenge reward.
 *    - `ReferrerSet(address indexed user, address indexed referrer)`: Emitted when a referrer is set for a user.
 *    - `ReferralRewardClaimed(address indexed referrer, uint256 rewardAmount)`: Emitted when a referrer claims referral reward.
 *    - `ContractPaused()`: Emitted when the contract is paused.
 *    - `ContractUnpaused()`: Emitted when the contract is unpaused.
 *    - `PlatformFeeSet(uint256 newFee)`: Emitted when the platform fee is updated.
 *    - `PlatformFeesCollected(uint256 amount)`: Emitted when platform fees are collected.
 *    - `EmergencyWithdrawal(address indexed recipient, uint256 amount)`: Emitted when an emergency withdrawal is made.


 * **Disclaimer:** This is a conceptual smart contract for demonstration purposes.
 *             It is not audited and should not be used in production without thorough security review and testing.
 *             Some functionalities are simplified for illustration and would require more complex implementations in a real-world scenario,
 *             especially the Booster NFT interaction and dynamic yield rate logic.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdvancedYieldFarm is Ownable {
    using SafeMath for uint256;

    // State Variables
    IERC721BoosterNFT public boosterNFTContract; // Address of the Booster NFT contract
    uint256 public baseYieldRate = 10; // Base yield rate in percentage (e.g., 10% per year, scaled down for block time)
    uint256 public dynamicRateFactor = 1000; // Factor to influence dynamic rate adjustment (example: TVL/dynamicRateFactor)
    uint256 public platformFeePercentage = 2; // Platform fee percentage on yield claims
    bool public paused = false; // Contract paused state

    mapping(address => uint256) public userDeposits; // User deposit balances
    mapping(address => uint256) public userStakes;   // User staked balances
    mapping(address => uint256) public lastYieldClaimTime; // Last time user claimed yield
    mapping(address => address) public userReferrers; // User's referrer
    mapping(address => uint256) public referrerCount; // Count of users referred by a user
    mapping(uint256 => Challenge) public challenges; // Mapping of challenge IDs to Challenge structs
    uint256 public challengeCount = 0; // Counter for challenge IDs

    uint256 public accumulatedPlatformFees; // Accumulated platform fees

    struct Challenge {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardAmount;
        bool isActive;
        mapping(address => bool) participants; // Users participating in the challenge
        mapping(address => bool) rewardClaimed; // Users who claimed reward
    }

    // Events (as outlined in the summary)
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event YieldClaimed(address indexed user, uint256 amount, uint256 fee);
    event YieldRateUpdated(uint256 newRate);
    event BoosterNFTActivated(address indexed user, uint256 boosterId);
    event BoosterNFTDeactivated(address indexed user, uint256 boosterId);
    event ChallengeStarted(uint256 challengeId, string challengeName, uint256 startTime, uint256 endTime, uint256 rewardAmount);
    event ChallengeEnded(uint256 challengeId);
    event ChallengeParticipation(address indexed user, uint256 challengeId);
    event ChallengeRewardClaimed(address indexed user, uint256 challengeId, uint256 rewardAmount);
    event ReferrerSet(address indexed user, address indexed referrer);
    event ReferralRewardClaimed(address indexed referrer, uint256 rewardAmount);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeeSet(uint256 newFee);
    event PlatformFeesCollected(uint256 amount);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount);


    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyOwnerOrBoosterContract() {
        require(_msgSender() == owner() || _msgSender() == address(boosterNFTContract), "Not Owner or Booster Contract");
        _;
    }


    // --- 1. Core Yield Farming Functions ---

    /// @notice Allows users to deposit funds into the platform.
    /// @param _amount The amount to deposit.
    function depositFunds(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than zero");
        userDeposits[_msgSender()] = userDeposits[_msgSender()].add(_amount);
        lastYieldClaimTime[_msgSender()] = block.timestamp; // Reset claim time on deposit
        if (userReferrers[_msgSender()] == address(0) && msg.data.length >= 68) { // Check for referrer on first deposit (simplified)
            address referrer = abi.decode(msg.data[68:], (address)); // Assuming referrer address is passed in calldata after function params
            if (referrer != address(0) && referrer != _msgSender()) {
                setReferrer(referrer);
            }
        }
        emit Deposit(_msgSender(), _amount);
    }

    /// @notice Allows users to withdraw funds from the platform.
    /// @param _amount The amount to withdraw.
    function withdrawFunds(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(userDeposits[_msgSender()] >= _amount, "Insufficient deposit balance");
        uint256 claimableYieldAmount = getClaimableYield(_msgSender());
        if (claimableYieldAmount > 0) {
            _claimYieldInternal(_msgSender()); // Auto-claim yield on withdrawal
        }
        userDeposits[_msgSender()] = userDeposits[_msgSender()].sub(_amount);
        payable(_msgSender()).transfer(_amount);
        emit Withdrawal(_msgSender(), _amount);
    }

    /// @notice Stakes deposited funds into the yield farming pool.
    /// @param _amount The amount to stake.
    function stakeFunds(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(userDeposits[_msgSender()] >= _amount, "Insufficient deposit balance to stake");
        userDeposits[_msgSender()] = userDeposits[_msgSender()].sub(_amount);
        userStakes[_msgSender()] = userStakes[_msgSender()].add(_amount);
        lastYieldClaimTime[_msgSender()] = block.timestamp; // Reset claim time on staking
        emit Stake(_msgSender(), _amount);
    }

    /// @notice Unstakes funds from the yield farming pool.
    /// @param _amount The amount to unstake.
    function unstakeFunds(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(userStakes[_msgSender()] >= _amount, "Insufficient staked balance");
        uint256 claimableYieldAmount = getClaimableYield(_msgSender());
        if (claimableYieldAmount > 0) {
            _claimYieldInternal(_msgSender()); // Auto-claim yield on unstake
        }
        userStakes[_msgSender()] = userStakes[_msgSender()].sub(_amount);
        userDeposits[_msgSender()] = userDeposits[_msgSender()].add(_amount);
        lastYieldClaimTime[_msgSender()] = block.timestamp; // Reset claim time on unstaking
        emit Unstake(_msgSender(), _amount);
    }

    /// @notice Allows users to claim accumulated yield.
    function claimYield() external whenNotPaused {
        _claimYieldInternal(_msgSender());
    }

    /// @dev Internal function to claim yield, used by `claimYield` and auto-claim on withdrawal/unstake
    function _claimYieldInternal(address _user) internal {
        uint256 claimableYieldAmount = getClaimableYield(_user);
        require(claimableYieldAmount > 0, "No yield to claim");

        uint256 platformFee = claimableYieldAmount.mul(platformFeePercentage).div(100);
        uint256 yieldToClaim = claimableYieldAmount.sub(platformFee);

        accumulatedPlatformFees = accumulatedPlatformFees.add(platformFee);
        lastYieldClaimTime[_user] = block.timestamp;

        payable(_user).transfer(yieldToClaim);
        emit YieldClaimed(_user, yieldToClaim, platformFee);
    }

    /// @notice (View) Returns the current base yield rate.
    function getYieldRate() external view returns (uint256) {
        return baseYieldRate;
    }

    /// @notice (Admin) Sets a new base yield rate.
    /// @param _newRate The new yield rate.
    function setYieldRate(uint256 _newRate) external onlyOwner {
        baseYieldRate = _newRate;
        emit YieldRateUpdated(_newRate);
    }

    /// @notice (View) Returns the deposited balance of a user.
    /// @param _user The address of the user.
    function getAccountBalance(address _user) external view returns (uint256) {
        return userDeposits[_user];
    }

    /// @notice (View) Returns the staked balance of a user.
    /// @param _user The address of the user.
    function getStakedBalance(address _user) external view returns (uint256) {
        return userStakes[_user];
    }

    /// @notice (View) Returns the claimable yield of a user.
    /// @param _user The address of the user.
    function getClaimableYield(address _user) public view returns (uint256) {
        return calculateYield(_user);
    }


    // --- 2. Dynamic Yield Rate Mechanism ---

    /// @dev (Internal/View) Calculates the yield for a user, considering boosters and dynamic rates.
    /// @param _user The address of the user.
    function calculateYield(address _user) public view returns (uint256) {
        uint256 stakedBalance = userStakes[_user];
        if (stakedBalance == 0) {
            return 0; // No yield if no stake
        }

        uint256 timeElapsed = block.timestamp.sub(lastYieldClaimTime[_user]);
        uint256 currentYieldRate = getDynamicYieldRate(); // Get dynamic yield rate
        uint256 boostedYieldRate = currentYieldRate.add(getBoosterEffect(_user)); // Apply booster effect
        uint256 yieldAmount = stakedBalance.mul(boostedYieldRate).mul(timeElapsed).div(365 days); // Simplified annual yield calculation (adjust as needed)

        return yieldAmount;
    }

    /// @dev (Internal/Admin triggered) Updates the yield rate based on platform TVL or other dynamic factors.
    function updateDynamicYieldRate() internal {
        // Example dynamic rate logic based on total staked value (TVL proxy)
        uint256 totalStakedValue = getContractBalance(); // Using contract balance as a simple TVL proxy
        uint256 newYieldRate;

        if (totalStakedValue < 1000 ether) {
            newYieldRate = baseYieldRate; // Base rate if TVL is low
        } else if (totalStakedValue < 10000 ether) {
            newYieldRate = baseYieldRate.add(baseYieldRate.mul(totalStakedValue).div(dynamicRateFactor)); // Increase rate slightly with TVL
        } else {
            newYieldRate = baseYieldRate.add(baseYieldRate.mul(totalStakedValue).div(dynamicRateFactor).mul(2)); // Increase rate more with higher TVL
        }

        baseYieldRate = newYieldRate;
        emit YieldRateUpdated(newYieldRate);
    }

    /// @dev (Internal/View) Gets the dynamic yield rate, considering dynamic adjustments
    function getDynamicYieldRate() internal view returns (uint256) {
        // In a real system, you might fetch TVL from an oracle or calculate it more precisely.
        // Here, we are using the baseYieldRate, but `updateDynamicYieldRate()` would adjust it.
        return baseYieldRate;
    }

    /// @notice (Admin) Sets the factor influencing dynamic yield rate adjustments.
    /// @param _newFactor The new dynamic rate factor.
    function setDynamicRateFactor(uint256 _newFactor) external onlyOwner {
        dynamicRateFactor = _newFactor;
    }


    // --- 3. Booster NFT Integration ---

    /// @notice (Admin) Sets the address of the Booster NFT contract.
    /// @param _boosterNFTContract The address of the Booster NFT contract.
    function setBoosterNFTContract(address _boosterNFTContract) external onlyOwner {
        boosterNFTContract = IERC721BoosterNFT(_boosterNFTContract);
    }

    /// @notice Allows users to purchase a Booster NFT (simulated interaction - in real world, call NFT contract).
    /// @param _boosterType The type of Booster NFT to purchase.
    function purchaseBoosterNFT(uint256 _boosterType) external payable whenNotPaused {
        // In a real implementation, you would call the BoosterNFT contract to mint/transfer an NFT to the user.
        // This is a simplified example.
        // Assume BoosterNFT contract has a function like `mintBooster(address _to, uint256 _boosterType)`
        // boosterNFTContract.mintBooster{value: msg.value}(_msgSender(), _boosterType); // Example call
        // For simplicity, we are just emitting an event here.
        // In a real scenario, the BoosterNFT contract would manage ownership and attributes.
        // For this example, assume booster NFTs are tracked externally (e.g., user holds NFT IDs).
        // Assume booster types and effects are defined off-chain or in a separate config.
        // Here, we just assume successful purchase and emit an event.
        // In a real system, you would likely receive an event from the NFT contract upon successful mint/transfer.
        // For now, simulate by emitting an event and assume user gets a booster.
        // In a real system, you would need to handle NFT ownership verification (e.g., using `boosterNFTContract.ownerOf(boosterId) == _msgSender()`).
        emit BoosterNFTActivated(_msgSender(), _boosterType); // Simulate activation on purchase for simplicity.
    }


    /// @notice Allows users to activate a Booster NFT to enhance yield.
    /// @param _boosterId The ID of the Booster NFT to activate.
    function activateBoosterNFT(uint256 _boosterId) external whenNotPaused {
        // In a real implementation, you would verify NFT ownership and then store the active booster for the user.
        // For simplicity, we assume external tracking of NFTs and just emit an event.
        // In a real system, you might have a mapping `mapping(address => uint256[]) public activeBoosters;`
        // and update it here after verifying ownership.
        // For now, just emit event.
        require(boosterNFTContract.ownerOf(_boosterId) == _msgSender(), "Not Booster NFT owner"); // Example ownership check
        emit BoosterNFTActivated(_msgSender(), _boosterId);
    }

    /// @notice Allows users to deactivate a Booster NFT.
    /// @param _boosterId The ID of the Booster NFT to deactivate.
    function deactivateBoosterNFT(uint256 _boosterId) external whenNotPaused {
        // Similar to activateBoosterNFT, in a real system, you would update user's active boosters list.
        // For simplicity, just emit event.
        emit BoosterNFTDeactivated(_msgSender(), _boosterId);
    }

    /// @dev (Internal/View) Calculates the yield boost effect from active NFTs.
    /// @param _user The address of the user.
    function getBoosterEffect(address _user) internal view returns (uint256) {
        // In a real system, you would query the user's active Booster NFTs and calculate the combined effect.
        // This is a simplified example.
        // Assume booster effects are based on NFT type or attributes defined in the BoosterNFT contract.
        // For example, if user has an NFT of type 'LegendaryBooster', it might give a 20% yield boost.
        // Here, we are just returning a fixed boost for demonstration.
        // In a real system, you would likely interact with the BoosterNFT contract to get booster attributes.
        // For now, return a fixed boost for demonstration.
        // Assume a simplified scenario where if user *has* *any* active booster, they get a +5% boost.
        // In a real system, you'd need to track *which* boosters are active and their specific effects.
        // For simplicity, just check if *any* booster is conceptually active (e.g., by checking if an event was emitted recently - very simplified!)
        // A better approach in a real system would be to maintain a mapping of user's active booster IDs and their effects.

        // Simplified example: Assume if user has *activated* any booster (tracked by events for now - VERY simplified), they get a 5% boost.
        // In a real system, you'd have a more robust way to track active boosters.

        // For a truly robust system, you'd need to:
        // 1. Maintain a mapping of user -> active booster IDs.
        // 2. Define booster types and their effects (e.g., in BoosterNFT contract or config).
        // 3. Query BoosterNFT contract to get booster attributes/types.
        // 4. Calculate combined boost based on active boosters.

        // For this simplified example, assume a fixed 5% boost if any booster is considered "active" (very loosely defined here).
        // In a real application, replace this with actual logic to retrieve and calculate booster effects.
        // For demonstration, return a fixed boost value.
        return 5; // Example: 5% yield boost
    }


    // --- 4. Time-Based Challenge System ---

    /// @notice (Admin) Starts a new time-based challenge.
    /// @param _challengeName The name of the challenge.
    /// @param _startTime The start time of the challenge (Unix timestamp).
    /// @param _endTime The end time of the challenge (Unix timestamp).
    /// @param _rewardAmount The reward amount for the challenge.
    function startChallenge(string memory _challengeName, uint256 _startTime, uint256 _endTime, uint256 _rewardAmount) external onlyOwner whenNotPaused {
        require(_startTime < _endTime, "Start time must be before end time");
        challengeCount++;
        challenges[challengeCount] = Challenge({
            name: _challengeName,
            startTime: _startTime,
            endTime: _endTime,
            rewardAmount: _rewardAmount,
            isActive: true
        });
        emit ChallengeStarted(challengeCount, _challengeName, _startTime, _endTime, _rewardAmount);
    }

    /// @notice (Admin) Ends a specific challenge and distributes rewards.
    /// @param _challengeId The ID of the challenge to end.
    function endChallenge(uint256 _challengeId) external onlyOwner whenNotPaused {
        require(challenges[_challengeId].isActive, "Challenge is not active");
        require(block.timestamp >= challenges[_challengeId].endTime, "Challenge end time not reached yet");
        challenges[_challengeId].isActive = false;
        // In a real system, you would implement logic to determine winners and distribute rewards based on challenge criteria.
        // For simplicity, in this example, every participant gets the reward if they participated.
        Challenge storage currentChallenge = challenges[_challengeId];
        for (address participant in currentChallenge.participants) {
            _distributeChallengeReward(participant, _challengeId, currentChallenge.rewardAmount);
        }
        emit ChallengeEnded(_challengeId);
    }

    /// @dev Internal function to distribute challenge rewards.
    /// @param _user The user to reward.
    /// @param _challengeId The ID of the challenge.
    /// @param _rewardAmount The reward amount.
    function _distributeChallengeReward(address _user, uint256 _challengeId, uint256 _rewardAmount) internal {
        if (!challenges[_challengeId].rewardClaimed[_user]) {
            payable(_user).transfer(_rewardAmount);
            challenges[_challengeId].rewardClaimed[_user] = true;
            emit ChallengeRewardClaimed(_user, _challengeId, _rewardAmount);
        }
    }

    /// @notice Allows users to participate in an active challenge.
    /// @param _challengeId The ID of the challenge to participate in.
    function participateInChallenge(uint256 _challengeId) external whenNotPaused {
        require(challenges[_challengeId].isActive, "Challenge is not active");
        require(block.timestamp >= challenges[_challengeId].startTime && block.timestamp <= challenges[_challengeId].endTime, "Challenge is not currently active");
        require(!challenges[_challengeId].participants[_msgSender()], "Already participating in this challenge");
        challenges[_challengeId].participants[_msgSender()] = true;
        emit ChallengeParticipation(_msgSender(), _challengeId);
    }

    /// @notice Allows users to claim rewards for completed challenges.
    /// @param _challengeId The ID of the challenge to claim reward from.
    function claimChallengeReward(uint256 _challengeId) external whenNotPaused {
        require(!challenges[_challengeId].isActive, "Challenge is still active");
        require(challenges[_challengeId].participants[_msgSender()], "Not participated in this challenge");
        require(!challenges[_challengeId].rewardClaimed[_msgSender()], "Reward already claimed");
        _distributeChallengeReward(_msgSender(), _challengeId, challenges[_challengeId].rewardAmount);
    }

    /// @notice (View) Returns the status and details of a specific challenge.
    /// @param _challengeId The ID of the challenge.
    function getChallengeStatus(uint256 _challengeId) external view returns (Challenge memory) {
        return challenges[_challengeId];
    }

    /// @notice (View) Returns a list of currently active challenges (IDs).
    function getCurrentChallenges() external view returns (uint256[] memory) {
        uint256[] memory activeChallengeIds = new uint256[](challengeCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= challengeCount; i++) {
            if (challenges[i].isActive && block.timestamp >= challenges[i].startTime && block.timestamp <= challenges[i].endTime) {
                activeChallengeIds[count] = i;
                count++;
            }
        }
        // Resize array to remove empty slots
        assembly {
            mstore(activeChallengeIds, count)
        }
        return activeChallengeIds;
    }


    // --- 5. Referral Program ---

    /// @notice Allows users to set a referrer address upon first deposit.
    /// @param _referrer The address of the referrer.
    function setReferrer(address _referrer) internal {
        require(userReferrers[_msgSender()] == address(0), "Referrer already set");
        require(_referrer != address(0) && _referrer != _msgSender(), "Invalid referrer address");
        userReferrers[_msgSender()] = _referrer;
        referrerCount[_referrer]++;
        emit ReferrerSet(_msgSender(), _referrer);
    }

    /// @notice (View) Returns the number of users referred by a specific user.
    /// @param _user The address of the user.
    function getReferralCount(address _user) external view returns (uint256) {
        return referrerCount[_user];
    }

    /// @dev (Internal/View) Calculates referral rewards (example - could be based on referred user's deposits).
    /// @param _referrer The address of the referrer.
    function calculateReferralReward(address _referrer) internal view returns (uint256) {
        uint256 totalReferredDeposit = 0;
        // In a real system, you would iterate through all users and check if _referrer is their referrer.
        // For this example, we'll just return a fixed reward for each referral.
        // A more efficient approach would be to track referral deposits directly or calculate rewards on claim.
        // Simplified example: Reward 1% of each referred user's *current deposit balance* (as a one-time reward).
        // This is for demonstration and can be adjusted.
        // For a real system, consider more sophisticated reward structures and tracking mechanisms.

        // Simplified: Assume fixed reward per referral for demonstration.
        return referrerCount[_referrer].mul(1 ether); // Example: 1 ether per referral
    }

    /// @notice Allows users to claim accumulated referral rewards.
    function claimReferralReward() external whenNotPaused {
        uint256 rewardAmount = calculateReferralReward(_msgSender());
        require(rewardAmount > 0, "No referral rewards to claim");
        payable(_msgSender()).transfer(rewardAmount);
        emit ReferralRewardClaimed(_msgSender(), rewardAmount);
    }


    // --- 6. Risk Management & Platform Control ---

    /// @notice (Admin) Pauses core contract functionalities in case of emergency.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /// @notice (Admin) Resumes core contract functionalities.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice (Admin) Sets the platform fee charged on yield claims.
    /// @param _newFee The new platform fee percentage.
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 100, "Platform fee cannot exceed 100%");
        platformFeePercentage = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    /// @notice (View) Returns the current platform fee percentage.
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    /// @notice (Admin) Collects accumulated platform fees.
    function collectPlatformFees() external onlyOwner {
        uint256 amountToCollect = accumulatedPlatformFees;
        accumulatedPlatformFees = 0; // Reset accumulated fees after collection
        payable(owner()).transfer(amountToCollect);
        emit PlatformFeesCollected(amountToCollect);
    }

    /// @notice (View) Returns the total balance of the contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice (Admin - Extreme Emergency) Allows admin to withdraw funds in extreme emergency.
    /// @param _recipient The address to receive the withdrawn funds.
    /// @param _amount The amount to withdraw.
    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount <= getContractBalance(), "Withdrawal amount exceeds contract balance");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount);
    }


    // --- Interfaces ---
    // Example interface for Booster NFT contract (simplified for demonstration)
    interface IERC721BoosterNFT {
        function ownerOf(uint256 tokenId) external view returns (address owner);
        // In a real system, you would likely have functions to get booster attributes, types, etc.
        // function getBoosterType(uint256 tokenId) external view returns (uint256);
        // function getBoosterEffect(uint256 tokenId) external view returns (uint256);
    }
}
```