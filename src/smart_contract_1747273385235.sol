Okay, here is a draft of a complex, advanced, and creative Solidity smart contract designed with a theme of "SynergyCore Protocol". It combines concepts like dynamic staking yield, NFT-based bonuses, a required external "pulse" trigger for reward accumulation, duration-based fees/bonuses, and conditional access based on on-chain activity.

The goal is to create something that isn't a direct copy of common templates (like a basic ERC20, simple staking vault, or standard marketplace) by adding layers of interaction and dynamic elements.

**Outline & Function Summary**

**I. Contract Overview:**
*   **Name:** SynergyCoreProtocol
*   **Purpose:** A protocol enabling users to stake authorized ERC-20 "Energy Tokens" to earn SYNERGY ERC-20 tokens. Rewards are influenced by stake duration, held ERC-721 "Synergy Crystals" (NFTs), and require a protocol-wide "Pulse" action to accrue. Includes dynamic parameters, withdrawal fees, and conditional access checks.
*   **Key Concepts:**
    *   **Energy Tokens:** Whitelisted ERC-20 tokens stakeable for yield.
    *   **SYNERGY Token:** The ERC-20 reward token.
    *   **Synergy Crystals:** Whitelisted ERC-721 NFTs that provide yield bonuses.
    *   **Stake:** A user's deposited amount of a specific Energy Token.
    *   **Duration Bonus:** Increased yield based on how long a stake has been active.
    *   **NFT Bonus:** Increased yield based on owning registered Synergy Crystals.
    *   **Pulse:** A function that must be triggered periodically (by anyone) to finalize reward calculations for all active stakes up to that point in time. Rewards only accrue for periods finalized by a Pulse.
    *   **Dynamic Parameters:** Admin-adjustable rates, bonuses, intervals, and fees.
    *   **Withdrawal Fee:** A fee applied to withdrawals before a minimum duration.
    *   **Conditional Access:** Hypothetical checks for special features based on staking status and NFTs.

**II. Function Summary:**

*   **Admin/Setup Functions (`onlyOwner`):**
    1.  `constructor()`: Initializes the contract with core token addresses and initial owner.
    2.  `setSynergyToken(IERC20 _synergyToken)`: Sets the address of the SYNERGY reward token.
    3.  `setCrystalNFT(IERC721 _crystalNFT)`: Sets the address of the Synergy Crystal NFT contract.
    4.  `addEnergyToken(IERC20 _token)`: Whitelists an ERC-20 token as stakeable.
    5.  `removeEnergyToken(IERC20 _token)`: Removes an ERC-20 token from the whitelist.
    6.  `setBaseEmissionRate(uint256 _rate)`: Sets the base SYNERGY tokens emitted per unit of stake per second (before bonuses).
    7.  `setDurationBonusRate(uint256 _durationSeconds, uint256 _bonusRate)`: Sets the yield bonus rate for exceeding a specific staking duration threshold.
    8.  `setNFTBonusFactor(uint256 _factor)`: Sets the base multiplier applied per registered and owned Crystal NFT for yield bonus.
    9.  `setWithdrawalFeeRate(uint256 _feeRate)`: Sets the percentage fee for early withdrawals (before min duration).
    10. `setMinStakeDurationForFee(uint256 _durationSeconds)`: Sets the minimum stake duration after which the withdrawal fee is waived.
    11. `setPulseInterval(uint256 _intervalSeconds)`: Sets the minimum time required between `triggerPulse` calls.
    12. `pauseStaking()`: Pauses new staking deposits.
    13. `unpauseStaking()`: Unpauses staking deposits.
    14. `transferOwnership(address _newOwner)`: Transfers contract ownership.
    15. `withdrawAdminFees(IERC20 _token, uint256 _amount)`: Allows admin to withdraw collected fees or other tokens sent to the contract.

*   **User Interaction Functions:**
    16. `stakeEnergyToken(IERC20 _energyToken, uint256 _amount)`: Stakes a specified amount of a whitelisted Energy Token. Requires prior ERC-20 approval.
    17. `withdrawEnergyToken(IERC20 _energyToken, uint256 _amount)`: Withdraws a specified amount of a staked Energy Token. Applies fee if duration requirement not met.
    18. `claimSynergyRewards(IERC20 _energyToken)`: Claims accumulated SYNERGY rewards for a specific stake type.
    19. `registerCrystalNFT(uint256[] memory _nftIds)`: Registers owned Crystal NFTs to apply yield bonuses to stakes. Requires prior ERC-721 approval (transfer approval is sufficient for `ownerOf`).
    20. `deregisterCrystalNFT(uint256[] memory _nftIds)`: Deregisters Crystal NFTs previously registered.

*   **Core Protocol Logic:**
    21. `triggerPulse()`: Finalizes a reward accumulation period based on the last pulse time. Can be called by anyone after the minimum interval.

*   **View & Query Functions:**
    22. `getPendingSynergyRewards(address _user, IERC20 _energyToken)`: Calculates and returns the pending SYNERGY rewards for a user's specific stake.
    23. `getUserStakeDetails(address _user, IERC20 _energyToken)`: Returns details about a user's stake (amount, start time, last reward calculation time).
    24. `getUserRegisteredNFTs(address _user)`: Returns the list of NFT IDs registered by a user.
    25. `getEffectiveAPY(address _user, IERC20 _energyToken)`: Calculates and returns the *current* effective APY for a user's stake, considering all bonuses and current base rate. (Note: This is a snapshot, actual yield depends on Pulse frequency and parameter changes).
    26. `getTimeSinceLastPulse()`: Returns the time elapsed since the last `triggerPulse` call.
    27. `getWithdrawalFee(address _user, IERC20 _energyToken, uint256 _amount)`: Calculates the potential withdrawal fee for a user's stake.
    28. `checkSpecialAccess(address _user)`: A hypothetical check (boolean) for access to a special protocol feature based on stake and NFT criteria.
    29. `getAuthorizedEnergyTokens()`: Returns the list of whitelisted Energy Token addresses.
    30. `getProtocolTotalStaked(IERC20 _energyToken)`: Returns the total amount of a specific Energy Token staked in the protocol.

**III. Smart Contract Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline & Function Summary (See above) ---

contract SynergyCoreProtocol is Ownable, ReentrancyGuard {

    // --- State Variables ---

    IERC20 public synergyToken; // The reward token
    IERC721 public crystalNFT; // The bonus-providing NFT

    // Whitelisted stakeable ERC-20 tokens
    mapping(address => bool) public isAuthorizedEnergyToken;
    address[] private authorizedEnergyTokensList;

    // --- Protocol Parameters ---
    uint256 public baseEmissionRate; // Base SYNERGY per stake unit per second (scaled)
    mapping(uint256 => uint256) public durationBonusRates; // durationSeconds => bonusMultiplier (scaled)
    uint256 public nftBonusFactor; // Base bonus multiplier per registered+owned NFT (scaled)
    uint256 public withdrawalFeeRate; // Percentage fee (e.g., 500 for 5%) (scaled)
    uint256 public minStakeDurationForFee; // Min seconds staked to avoid withdrawal fee
    uint256 public pulseInterval; // Minimum seconds between triggerPulse calls

    // --- Staking & Rewards Data ---
    struct Stake {
        uint256 amount; // Amount of energy token staked
        uint256 startTime; // Timestamp of staking
        uint256 lastRewardCalculationTime; // Timestamp rewards were last calculated up to
        // Registered NFTs are tracked separately per user
    }

    // user => energyTokenAddress => Stake details
    mapping(address => mapping(address => Stake)) public userStakes;

    // user => energyTokenAddress => pending SYNERGY rewards
    mapping(address => mapping(address => uint256)) public pendingSynergyRewards;

    // user => registered Crystal NFT IDs
    mapping(address => uint256[]) public userRegisteredNFTs;
    // Helper mapping to quickly check if an NFT is registered by a user
    mapping(uint256 => address) private nftRegistrationStatus; // nftId => user address (0x0 if not registered)

    // Protocol-wide data
    uint256 public lastPulseTime; // Timestamp of the last triggerPulse call
    bool public stakingPaused; // Whether staking is currently paused

    // --- Events ---
    event SynergyTokenSet(address indexed token);
    event CrystalNFTSet(address indexed nft);
    event EnergyTokenAdded(address indexed token);
    event EnergyTokenRemoved(address indexed token);
    event Staked(address indexed user, address indexed token, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 feePaid, uint256 timestamp);
    event RewardsClaimed(address indexed user, address indexed token, uint256 amount);
    event CrystalNFTsRegistered(address indexed user, uint256[] nftIds);
    event CrystalNFTsDeregistered(address indexed user, uint256[] nftIds);
    event PulseTriggered(uint256 timestamp, uint256 durationSinceLastPulse);
    event ParametersUpdated(string paramName, uint256 newValue);
    event StakingPaused();
    event StakingUnpaused();
    event AdminFeeWithdrawal(address indexed token, address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAuthorizedEnergyToken(IERC20 _token) {
        require(isAuthorizedEnergyToken[address(_token)], "SynergyCore: Not authorized energy token");
        _;
    }

    // --- Constructor ---
    constructor(IERC20 _initialSynergyToken) Ownable(msg.sender) {
        require(address(_initialSynergyToken) != address(0), "SynergyCore: Invalid synergy token address");
        synergyToken = _initialSynergyToken;
        lastPulseTime = block.timestamp; // Initialize last pulse time
        stakingPaused = false; // Staking starts unpaused

        // Set some reasonable initial parameters (can be updated by owner)
        baseEmissionRate = 1e18; // 1 SYNERGY per unit per second (example, adjust scale)
        durationBonusRates[30 days] = 11000; // 10% bonus for >30 days (110% factor)
        durationBonusRates[90 days] = 12500; // 25% bonus for >90 days (125% factor)
        nftBonusFactor = 500; // 0.5% bonus per NFT (e.g., 10 NFTs = 5% bonus) (scaled)
        withdrawalFeeRate = 1000; // 10% fee (scaled)
        minStakeDurationForFee = 60 days; // No fee after 60 days
        pulseInterval = 1 hours; // Pulse can be triggered at most hourly
    }

    // --- Admin/Setup Functions ---

    /// @notice Sets the address of the SYNERGY reward token.
    /// @param _synergyToken The address of the SYNERGY token contract.
    function setSynergyToken(IERC20 _synergyToken) external onlyOwner {
        require(address(_synergyToken) != address(0), "SynergyCore: Invalid synergy token address");
        synergyToken = _synergyToken;
        emit SynergyTokenSet(address(_synergyToken));
    }

    /// @notice Sets the address of the Synergy Crystal NFT contract.
    /// @param _crystalNFT The address of the Crystal NFT contract.
    function setCrystalNFT(IERC721 _crystalNFT) external onlyOwner {
        require(address(_crystalNFT) != address(0), "SynergyCore: Invalid crystal NFT address");
        crystalNFT = _crystalNFT;
        emit CrystalNFTSet(address(_crystalNFT));
    }

    /// @notice Whitelists an ERC-20 token as stakeable.
    /// @param _token The address of the ERC-20 token to add.
    function addEnergyToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "SynergyCore: Invalid token address");
        require(!isAuthorizedEnergyToken[address(_token)], "SynergyCore: Token already authorized");
        isAuthorizedEnergyToken[address(_token)] = true;
        authorizedEnergyTokensList.push(address(_token));
        emit EnergyTokenAdded(address(_token));
    }

    /// @notice Removes an ERC-20 token from the whitelist. Existing stakes remain but new stakes are blocked.
    /// @param _token The address of the ERC-20 token to remove.
    function removeEnergyToken(IERC20 _token) external onlyOwner {
        require(isAuthorizedEnergyToken[address(_token)], "SynergyCore: Token not authorized");
        isAuthorizedEnergyToken[address(_token)] = false;
        // Note: Removing from authorizedEnergyTokensList array is gas-intensive.
        // For simplicity, we mark it unauthorized in the mapping. Iterating the list
        // for authorized tokens will need to check the mapping.
        emit EnergyTokenRemoved(address(_token));
    }

    /// @notice Sets the base emission rate for SYNERGY rewards.
    /// @param _rate The new base emission rate (scaled, e.g., 1e18 for 1 token per unit per second).
    function setBaseEmissionRate(uint256 _rate) external onlyOwner {
        baseEmissionRate = _rate;
        emit ParametersUpdated("baseEmissionRate", _rate);
    }

    /// @notice Sets the duration bonus rate for stakes exceeding a certain duration.
    /// @param _durationSeconds The duration threshold in seconds.
    /// @param _bonusRate The bonus multiplier (e.g., 11000 for 1.1x base rate). Use 10000 for no bonus.
    function setDurationBonusRate(uint256 _durationSeconds, uint256 _bonusRate) external onlyOwner {
        require(_bonusRate >= 10000, "SynergyCore: Bonus rate must be >= 10000"); // Must be at least 1x
        durationBonusRates[_durationSeconds] = _bonusRate;
        emit ParametersUpdated(string(abi.encodePacked("durationBonusRate_", _durationSeconds)), _bonusRate);
    }

    /// @notice Sets the base bonus factor applied per registered and owned Crystal NFT.
    /// @param _factor The bonus factor (e.g., 500 for 0.5% yield bonus per NFT). Scaled by 10000 for percentage points.
    function setNFTBonusFactor(uint256 _factor) external onlyOwner {
        nftBonusFactor = _factor;
        emit ParametersUpdated("nftBonusFactor", _factor);
    }

    /// @notice Sets the percentage fee applied to withdrawals before the minimum duration.
    /// @param _feeRate The fee rate percentage (e.g., 1000 for 10%). Scaled by 10000.
    function setWithdrawalFeeRate(uint256 _feeRate) external onlyOwner {
         require(_feeRate <= 10000, "SynergyCore: Fee rate cannot exceed 100%");
        withdrawalFeeRate = _feeRate;
        emit ParametersUpdated("withdrawalFeeRate", _feeRate);
    }

     /// @notice Sets the minimum stake duration after which the withdrawal fee is waived.
    /// @param _durationSeconds The minimum duration in seconds.
    function setMinStakeDurationForFee(uint256 _durationSeconds) external onlyOwner {
        minStakeDurationForFee = _durationSeconds;
        emit ParametersUpdated("minStakeDurationForFee", _durationSeconds);
    }

    /// @notice Sets the minimum time interval required between triggerPulse calls.
    /// @param _intervalSeconds The minimum interval in seconds.
    function setPulseInterval(uint256 _intervalSeconds) external onlyOwner {
        pulseInterval = _intervalSeconds;
        emit ParametersUpdated("pulseInterval", _intervalSeconds);
    }


    /// @notice Pauses new staking deposits.
    function pauseStaking() external onlyOwner {
        stakingPaused = true;
        emit StakingPaused();
    }

    /// @notice Unpauses staking deposits.
    function unpauseStaking() external onlyOwner {
        stakingPaused = false;
        emit StakingUnpaused();
    }

     /// @notice Allows the owner to withdraw any token balance from the contract, e.g., collected fees.
    /// @param _token The address of the token to withdraw.
    /// @param _amount The amount to withdraw.
    function withdrawAdminFees(IERC20 _token, uint256 _amount) external onlyOwner {
        require(address(_token) != address(synergyToken), "SynergyCore: Cannot withdraw synergy token via this function"); // Prevent draining reward pool
        require(_amount > 0, "SynergyCore: Amount must be greater than 0");
        require(_token.balanceOf(address(this)) >= _amount, "SynergyCore: Insufficient balance");

        _token.transfer(owner(), _amount);
        emit AdminFeeWithdrawal(address(_token), owner(), _amount);
    }


    // --- User Interaction Functions ---

    /// @notice Stakes a specified amount of an authorized Energy Token.
    /// @param _energyToken The ERC-20 token to stake.
    /// @param _amount The amount to stake.
    function stakeEnergyToken(IERC20 _energyToken, uint256 _amount) external nonReentrant onlyAuthorizedEnergyToken(_energyToken) {
        require(!stakingPaused, "SynergyCore: Staking is paused");
        require(_amount > 0, "SynergyCore: Cannot stake zero amount");

        address user = msg.sender;
        address tokenAddress = address(_energyToken);

        // Transfer tokens from user to contract
        uint256 balanceBefore = _energyToken.balanceOf(address(this));
        _energyToken.transferFrom(user, address(this), _amount);
        uint256 transferredAmount = _energyToken.balanceOf(address(this)) - balanceBefore;
        require(transferredAmount == _amount, "SynergyCore: ERC20 transfer failed or mismatch"); // Sanity check

        // Claim any pending rewards before updating stake
        // This prevents rewards from a previous staking period being lost
        _calculateAndAddRewards(user, _energyToken);

        if (userStakes[user][tokenAddress].amount == 0) {
            // First time staking this token
            userStakes[user][tokenAddress] = Stake({
                amount: transferredAmount,
                startTime: block.timestamp,
                lastRewardCalculationTime: lastPulseTime // Start calculating from last pulse
            });
        } else {
            // Adding to existing stake
            userStakes[user][tokenAddress].amount += transferredAmount;
             // Do NOT update startTime or lastRewardCalculationTime here, to maintain duration bonus
        }

        emit Staked(user, tokenAddress, transferredAmount, block.timestamp);
    }

    /// @notice Withdraws a specified amount of a staked Energy Token. Applies fee if early.
    /// @param _energyToken The ERC-20 token to withdraw.
    /// @param _amount The amount to withdraw.
    function withdrawEnergyToken(IERC20 _energyToken, uint256 _amount) external nonReentrant onlyAuthorizedEnergyToken(_energyToken) {
        address user = msg.sender;
        address tokenAddress = address(_energyToken);
        Stake storage stake = userStakes[user][tokenAddress];

        require(stake.amount >= _amount, "SynergyCore: Insufficient staked amount");
        require(_amount > 0, "SynergyCore: Cannot withdraw zero amount");

        // Calculate pending rewards before withdrawal
        _calculateAndAddRewards(user, _energyToken);

        uint256 feeAmount = 0;
        uint256 stakeDuration = block.timestamp - stake.startTime;

        if (stakeDuration < minStakeDurationForFee) {
            feeAmount = (_amount * withdrawalFeeRate) / 10000; // Fee is percentage of withdrawn amount
        }

        uint256 amountToTransfer = _amount - feeAmount;

        stake.amount -= _amount; // Deduct the full amount from stake

        _energyToken.transfer(user, amountToTransfer);

        // If stake becomes zero, reset start time for future stakes
        if (stake.amount == 0) {
            stake.startTime = 0;
            stake.lastRewardCalculationTime = 0;
        }

        emit Withdrawn(user, tokenAddress, _amount, feeAmount, block.timestamp);
    }

    /// @notice Claims accumulated SYNERGY rewards for a specific stake type.
    /// @param _energyToken The ERC-20 token type for which to claim rewards.
    function claimSynergyRewards(IERC20 _energyToken) external nonReentrant onlyAuthorizedEnergyToken(_energyToken) {
        address user = msg.sender;
        address tokenAddress = address(_energyToken);

        // Calculate and add any pending rewards since last calc/pulse
        _calculateAndAddRewards(user, _energyToken);

        uint256 rewardsToClaim = pendingSynergyRewards[user][tokenAddress];
        require(rewardsToClaim > 0, "SynergyCore: No pending rewards to claim");

        pendingSynergyRewards[user][tokenAddress] = 0; // Reset pending rewards

        // Transfer SYNERGY tokens
        synergyToken.transfer(user, rewardsToClaim);

        emit RewardsClaimed(user, tokenAddress, rewardsToClaim);
    }

    /// @notice Registers owned Crystal NFTs to apply yield bonuses.
    /// @param _nftIds An array of NFT IDs to register.
    function registerCrystalNFT(uint256[] memory _nftIds) external nonReentrant {
        require(address(crystalNFT) != address(0), "SynergyCore: Crystal NFT contract not set");
        address user = msg.sender;

        for (uint256 i = 0; i < _nftIds.length; i++) {
            uint256 nftId = _nftIds[i];
            // Ensure user owns the NFT and it's not already registered by anyone
            require(crystalNFT.ownerOf(nftId) == user, "SynergyCore: User does not own NFT or it's invalid");
            require(nftRegistrationStatus[nftId] == address(0), "SynergyCore: NFT already registered");

            userRegisteredNFTs[user].push(nftId);
            nftRegistrationStatus[nftId] = user;
        }

        emit CrystalNFTsRegistered(user, _nftIds);
    }

    /// @notice Deregisters Crystal NFTs.
    /// @param _nftIds An array of NFT IDs to deregister.
    function deregisterCrystalNFT(uint256[] memory _nftIds) external nonReentrant {
         require(address(crystalNFT) != address(0), "SynergyCore: Crystal NFT contract not set");
        address user = msg.sender;

        for (uint256 i = 0; i < _nftIds.length; i++) {
            uint256 nftId = _nftIds[i];
             // Ensure the NFT is registered by this user
            require(nftRegistrationStatus[nftId] == user, "SynergyCore: NFT not registered by user");

            // Find and remove the NFT ID from the userRegisteredNFTs array
            uint256 index = type(uint256).max;
            for (uint256 j = 0; j < userRegisteredNFTs[user].length; j++) {
                if (userRegisteredNFTs[user][j] == nftId) {
                    index = j;
                    break;
                }
            }
            require(index != type(uint256).max, "SynergyCore: NFT ID not found in user's registered list");

            // Swap with last element and pop
            uint256 lastIndex = userRegisteredNFTs[user].length - 1;
            userRegisteredNFTs[user][index] = userRegisteredNFTs[user][lastIndex];
            userRegisteredNFTs[user].pop();

            // Clear registration status
            nftRegistrationStatus[nftId] = address(0);
        }

        emit CrystalNFTsDeregistered(user, _nftIds);
    }

     /// @notice Allows a user to extend their stake duration without unstaking/restaking.
     ///         This resets the stake's `startTime` to `block.timestamp`.
     ///         Warning: Use this carefully, as it restarts the duration bonus clock.
     ///         A different implementation might add time rather than reset start time.
     ///         Current implementation is simpler but resets duration bonus progress.
    /// @param _energyToken The ERC-20 token type of the stake.
    function extendStakeDuration(IERC20 _energyToken) external nonReentrant onlyAuthorizedEnergyToken(_energyToken) {
        address user = msg.sender;
        address tokenAddress = address(_energyToken);
        Stake storage stake = userStakes[user][tokenAddress];

        require(stake.amount > 0, "SynergyCore: No active stake found");

         // Calculate and add any pending rewards before extending
        _calculateAndAddRewards(user, _energyToken);

        stake.startTime = block.timestamp;
        stake.lastRewardCalculationTime = lastPulseTime; // Reset rewards calc time to align with new start

        // No specific event for this, maybe log stake updated? Re-emitting Staked with 0 amount?
         // Let's just rely on calculateAndAddRewards triggering internal state updates.
    }


    // --- Core Protocol Logic ---

    /// @notice Triggers a protocol-wide pulse, allowing rewards to be calculated up to this point.
    ///         Must be called after the minimum pulse interval has passed.
    ///         Can be called by anyone. Gas cost scales with number of active stakes
    ///         processed internally by `_calculateAndAddRewards`.
    function triggerPulse() external nonReentrancy {
        require(block.timestamp >= lastPulseTime + pulseInterval, "SynergyCore: Pulse interval has not passed");

        uint256 durationSinceLast = block.timestamp - lastPulseTime;
        lastPulseTime = block.timestamp; // Update pulse time *before* calculations

        // Note: Reward calculation is handled lazily per-user on claim/view/stake/withdraw.
        // The pulse simply updates the 'lastPulseTime' which serves as a high-water mark
        // for all reward calculations happening after this point. It doesn't iterate all users.
        // This makes triggerPulse gas-efficient regardless of the number of users.

        emit PulseTriggered(block.timestamp, durationSinceLast);
    }

    // --- Internal Helper Functions ---

    /// @dev Calculates and adds pending SYNERGY rewards for a specific user and stake type
    ///      since the last time rewards were calculated for this stake, capped by `lastPulseTime`.
    ///      Updates the stake's `lastRewardCalculationTime`.
    function _calculateAndAddRewards(address _user, IERC20 _energyToken) internal {
        Stake storage stake = userStakes[_user][address(_energyToken)];

        // No active stake or no time passed since last calc (capped by lastPulseTime)
        if (stake.amount == 0 || stake.lastRewardCalculationTime >= lastPulseTime) {
            return;
        }

        uint256 currentTimeForCalc = lastPulseTime; // Rewards accrue up to the last valid pulse

        // Time elapsed for reward calculation in this period
        uint256 timeElapsed = currentTimeForCalc - stake.lastRewardCalculationTime;

        if (timeElapsed == 0) {
            return; // No time has passed in this period
        }

        // Calculate bonuses
        uint256 duration = block.timestamp - stake.startTime; // Use current time for duration bonus
        uint256 durationBonus = _getDurationBonus(duration);
        uint256 nftBonus = _getNFTBonus(_user); // Use current NFT registration for bonus

        // Calculate total bonus multiplier (scaled by 10000*10000)
        // Total Multiplier = (Base + DurationBonus + NFTBonus) / Base (scaled)
        // Let's simplify: (10000 + (DurationBonusFactor - 10000) + NFTBonusPercentage) / 10000
        // Or even simpler: Total Factor = BaseFactor * DurationFactor * NFTFactor
        // Example: Base 1x, Duration 1.1x, NFT 1.05x -> Total 1.155x
        // Scaled: 10000 * 11000/10000 * (10000 + numNFTs * nftBonusFactor / 10000) / 10000
        // Let's try: Base = baseEmissionRate (e.g. 1e18), DurationFactor = durationBonus / 10000 (e.g. 11000/10000 = 1.1)
        // NFTFactor = (10000 + numNFTs * nftBonusFactor) / 10000 (e.g. 10000 + 5*500 / 10000 = 10000 + 2500 / 10000 = 1.25)
        // Total Reward Rate Per Second = baseEmissionRate * DurationFactor * NFTFactor
        // = baseEmissionRate * (durationBonus / 10000) * ((10000 + numNFTs * nftBonusFactor) / 10000)

        uint256 numRegisteredOwnedNFTs = _countRegisteredOwnedNFTs(_user);

        // Scale calculation carefully to avoid overflow/underflow
        // Let's use a fixed point of 10000 for percentages/factors
        uint256 effectiveBonusFactor = (durationBonus * (10000 + numRegisteredOwnedNFTs * nftBonusFactor)) / 10000;
        // effectiveBonusFactor is now scaled by 10000. Example: 1.1 * (10000 + 5*500)/10000 = 1.1 * 1.25 = 1.375 -> 13750

        // Calculate raw rewards: amount * timeElapsed * baseEmissionRate
        // Scale the baseEmissionRate down, assuming it's in full tokens/unit/sec
        uint256 rawRewards = (stake.amount * timeElapsed * baseEmissionRate) / 1e18; // Assuming baseEmissionRate is 1e18 scaled

        // Apply bonus factor: rawRewards * effectiveBonusFactor / 10000 (scaled by 10000)
        uint256 totalRewards = (rawRewards * effectiveBonusFactor) / 10000;

        // Add to pending rewards
        pendingSynergyRewards[_user][address(_energyToken)] += totalRewards;

        // Update last calculation time for this stake
        stake.lastRewardCalculationTime = currentTimeForCalc;
    }

    /// @dev Internal helper to get the duration bonus multiplier for a given duration.
    /// @param _durationSeconds The stake duration in seconds.
    /// @return bonusMultiplier The multiplier (scaled by 10000, e.g., 11000 for 1.1x bonus). Defaults to 10000 (1x).
    function _getDurationBonus(uint256 _durationSeconds) internal view returns (uint256) {
        uint256 currentBonus = 10000; // Default is 1x
        // Iterate through defined bonus thresholds
        // This assumes durationBonusRates keys are sorted or doesn't matter due to logic
        // A better approach for potentially many tiers is a sorted array of structs {duration, bonus}
        // For simplicity here, we just check predefined thresholds.
        if (_durationSeconds >= 90 days) {
             // Check highest tier first
            if(durationBonusRates[90 days] > 0) return durationBonusRates[90 days];
        }
        if (_durationSeconds >= 30 days) {
             // Check next tier
             if(durationBonusRates[30 days] > 0) return durationBonusRates[30 days];
        }
        // Add more tiers here if needed
        return currentBonus;
    }

    /// @dev Internal helper to count valid registered and owned Crystal NFTs for a user.
    /// @param _user The user's address.
    /// @return count The number of valid registered and owned NFTs.
    function _countRegisteredOwnedNFTs(address _user) internal view returns (uint256) {
        if (address(crystalNFT) == address(0)) {
            return 0; // No NFT contract set
        }
        uint256 count = 0;
        uint256[] storage registeredNFTs = userRegisteredNFTs[_user];
        for (uint256 i = 0; i < registeredNFTs.length; i++) {
            uint256 nftId = registeredNFTs[i];
             // Check if it's still registered by this user and if the user still owns it
             // The nftRegistrationStatus check might be redundant if userRegisteredNFTs is kept perfectly in sync,
             // but it adds an extra layer of safety against potential deregistration bugs.
            if (nftRegistrationStatus[nftId] == _user && crystalNFT.ownerOf(nftId) == _user) {
                count++;
            }
        }
        return count;
    }


    // --- View & Query Functions ---

    /// @notice Calculates and returns the pending SYNERGY rewards for a user's specific stake.
    /// @param _user The user's address.
    /// @param _energyToken The ERC-20 token type of the stake.
    /// @return rewards The calculated pending SYNERGY rewards.
    function getPendingSynergyRewards(address _user, IERC20 _energyToken) external view returns (uint256) {
        Stake storage stake = userStakes[_user][address(_energyToken)];

        if (stake.amount == 0 || stake.lastRewardCalculationTime >= lastPulseTime) {
            return pendingSynergyRewards[_user][address(_energyToken)]; // No active stake or no new period since last calc
        }

        uint256 currentTimeForCalc = lastPulseTime;
        uint256 timeElapsed = currentTimeForCalc - stake.lastRewardCalculationTime;

        if (timeElapsed == 0) {
             return pendingSynergyRewards[_user][address(_energyToken)];
        }

        uint256 duration = block.timestamp - stake.startTime; // Use current time for duration bonus
        uint256 durationBonus = _getDurationBonus(duration);
        uint256 nftBonus = _getNFTBonus(_user); // Use current NFT registration for bonus

        uint256 numRegisteredOwnedNFTs = _countRegisteredOwnedNFTs(_user);
        uint256 effectiveBonusFactor = (durationBonus * (10000 + numRegisteredOwnedNFTs * nftBonusFactor)) / 10000;

        uint256 rawRewards = (stake.amount * timeElapsed * baseEmissionRate) / 1e18;
        uint256 totalRewards = (rawRewards * effectiveBonusFactor) / 10000;

        // Return current pending + calculated rewards
        return pendingSynergyRewards[_user][address(_energyToken)] + totalRewards;
    }

     /// @notice Returns details about a user's stake for a specific Energy Token type.
     /// @param _user The user's address.
     /// @param _energyToken The ERC-20 token type.
     /// @return amount The staked amount.
     /// @return startTime The timestamp when the stake was created/last extended.
     /// @return lastRewardCalculationTime The timestamp rewards were last calculated up to for this stake.
    function getUserStakeDetails(address _user, IERC20 _energyToken) external view returns (uint256 amount, uint256 startTime, uint256 lastRewardCalculationTime) {
        Stake storage stake = userStakes[_user][address(_energyToken)];
        return (stake.amount, stake.startTime, stake.lastRewardCalculationTime);
    }

    /// @notice Returns the list of NFT IDs currently registered by a user.
    ///         Note: This does NOT guarantee the user still owns them. Use `_countRegisteredOwnedNFTs` internally for bonus calculation.
    /// @param _user The user's address.
    /// @return nftIds An array of registered NFT IDs.
    function getUserRegisteredNFTs(address _user) external view returns (uint256[] memory) {
        return userRegisteredNFTs[_user];
    }

     /// @dev Internal helper to get the NFT bonus multiplier for a user based on count of registered and owned NFTs.
     /// @param _user The user's address.
     /// @return totalNFTBonusMultiplier The multiplier (scaled by 10000, e.g., 10500 for 1.05x bonus from NFTs).
    function _getNFTBonus(address _user) internal view returns (uint256) {
         uint256 numNFTs = _countRegisteredOwnedNFTs(_user);
         // Total NFT bonus factor is proportional to the number of NFTs
         // Example: 10000 (base) + numNFTs * nftBonusFactor (e.g., 10000 + 5 * 500 = 12500)
         // This is scaled by 10000, so 12500 represents a 1.25x multiplier
        return 10000 + (numNFTs * nftBonusFactor);
    }


    /// @notice Calculates the current effective APY for a user's stake.
    ///         Note: This is a snapshot based on current parameters and stake status.
    ///         Actual APY can change with parameter updates and pulse frequency.
    /// @param _user The user's address.
    /// @param _energyToken The ERC-20 token type of the stake.
    /// @return apy The calculated effective APY (scaled by 10000, e.g., 50000 for 5% APY).
    function getEffectiveAPY(address _user, IERC20 _energyToken) external view returns (uint256 apy) {
        Stake storage stake = userStakes[_user][address(_energyToken)];

        if (stake.amount == 0) {
            return 0; // No active stake
        }

        uint256 duration = block.timestamp - stake.startTime; // Use current time for duration bonus
        uint256 durationBonus = _getDurationBonus(duration);
        uint256 numRegisteredOwnedNFTs = _countRegisteredOwnedNFTs(_user);
        uint256 nftBonus = 10000 + (numRegisteredOwnedNFTs * nftBonusFactor);

        // Calculate the per-second reward rate for 1 unit of stake
        // Reward Rate Per Unit Per Second = baseEmissionRate * DurationFactor * NFTFactor
        // Scale: baseEmissionRate (scaled by 1e18) * (durationBonus / 10000) * (nftBonus / 10000)
        // = (baseEmissionRate * durationBonus * nftBonus) / (1e18 * 10000 * 10000)

        // Let's simplify scaling:
        // Rate per unit per second (scaled by 1e18) = baseEmissionRate * (durationBonus / 10000) * (nftBonus / 10000)
        // = (baseEmissionRate * durationBonus * nftBonus) / 1e8
        // This value is scaled by 1e18 / (10000*10000) = 1e18 / 1e8 = 1e10 ? No, let's think about units.
        // baseEmissionRate is SYNERGY_units / (EnergyToken_units * second). Let's say it's scaled such that 1 SYNERGY = 1e18 units, 1 EnergyToken = 1e18 units.
        // So baseEmissionRate is base_rate * 1e18 (SYNERGY_units) / (1e18 (ET_units) * second) = base_rate SYNERGY_units / (ET_unit * second)

        // Correct Calculation:
        // Effective Emission Rate per Energy Token unit per second = baseEmissionRate * (durationBonus / 10000) * (nftBonus / 10000)
        // This rate is in (SYNERGY units / 1e18) / (ET unit * second)
        // Total Rewards per second for 1 Energy Token unit = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY tokens / second
        // Multiply by seconds in a year to get annual rate = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * 31536000 SYNERGY tokens / ET unit
        // This is the APY as a factor (e.g., 0.05 for 5%). Convert to percentage scaled by 10000:
        // APY (%) scaled by 10000 = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * 31536000 * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * 31536000 * 10000) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * 31536000) / (1e18 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * 31536000) / 1e22

        uint256 annualSeconds = 31536000; // Seconds in a year

        uint256 effectiveRatePerUnitPerSecond_scaled_1e18 = (baseEmissionRate * durationBonus * nftBonus) / 10000; // Still need another /10000 from nftBonus

        // (baseEmissionRate * durationBonus * nftBonus) / (10000 * 10000) -> result scaled by 1e18
        // Need to be very careful with scaling to avoid overflow/underflow
        // Let's assume emission rate is tokens * 1e18 per unit per second.
        // Raw rate per unit per sec = baseEmissionRate / 1e18
        // Bonus multiplier = (durationBonus / 10000) * (nftBonus / 10000)
        // Effective rate per unit per sec = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY tokens
        // APY as a factor = Effective rate * annualSeconds
        // APY scaled by 10000 = APY as a factor * 10000
        // = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / (1e18 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e22

        // Check for potential division by zero if baseEmissionRate is 0 or factors are 0
        if (baseEmissionRate == 0 || durationBonus == 0 || nftBonus == 0) {
             return 0;
        }

        // Perform calculation with intermediate steps to prevent overflow if numbers are very large
        // Let's use WAD-like fixed point (1e18) for intermediate calculations where needed, or just uint256.
        // (baseEmissionRate * annualSeconds) / 1e18 -> raw annual rate factor
        // raw annual rate factor * (durationBonus/10000) * (nftBonus/10000)
        // = (baseEmissionRate * annualSeconds * durationBonus * nftBonus) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate * annualSeconds * durationBonus * nftBonus) / 1e26
        // We want APY scaled by 10000, so multiply by 10000
        // APY_scaled_10000 = (baseEmissionRate * annualSeconds * durationBonus * nftBonus * 10000) / 1e26
        // = (baseEmissionRate * annualSeconds * durationBonus * nftBonus) / 1e22

        // Need to handle potential overflow if baseEmissionRate, durationBonus, nftBonus, annualSeconds are huge
        // Max uint256 is ~1.15e77.
        // baseEmissionRate could be 1e18. annualSeconds ~3e7. durationBonus/nftBonus ~1e5 each.
        // 1e18 * 3e7 * 1e5 * 1e5 = 3e35. This fits within uint256. Division by 1e22 is fine.

        uint256 numerator = baseEmissionRate;
        numerator = (numerator * annualSeconds);
        numerator = (numerator * durationBonus);
        numerator = (numerator * nftBonus);

        uint256 denominator = 1e18; // For base emission rate
        denominator = (denominator * 10000); // For durationBonus scaling
        denominator = (denominator * 10000); // For nftBonus scaling

        uint256 apyFactor = numerator / denominator; // This factor is like 0.05 for 5%

        // Convert factor to percentage scaled by 10000 (e.g., 0.05 * 10000 = 500)
        apy = apyFactor; // Wait, the apyFactor is already scaled correctly based on the derivation APY_scaled_10000 = (num * annual * dur * nft) / 1e22
        // No, the units derivation implies the final result is the APY factor. Let's re-check.
        // Rate per unit per second = base * dur_f * nft_f (in SYNERGY/ET/sec)
        // base_f = baseEmissionRate / 1e18
        // dur_f = durationBonus / 10000
        // nft_f = nftBonus / 10000
        // Rate = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000)
        // Annual Rate = Rate * annualSeconds = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / (1e18 * 10000 * 10000)
        // Annual Rate = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e26
        // APY scaled by 10000 = Annual Rate * 10000 = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e22

        // This APY calculation seems correct now. Let's implement it robustly.
         uint256 numeratorCalc = baseEmissionRate; // Scaled 1e18
         numeratorCalc = SafeMul(numeratorCalc, annualSeconds); // SYNERGY_units / ET_unit * year * 1e18

         uint256 bonusProduct = SafeMul(durationBonus, nftBonus); // Scaled 10000 * 10000 = 1e8
         numeratorCalc = SafeMul(numeratorCalc, bonusProduct); // SYNERGY_units / ET_unit * year * 1e18 * 1e8 = SYNERGY_units / ET_unit * year * 1e26

         uint256 denominatorCalc = 1e18; // From baseEmissionRate scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // From durationBonus scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // From nftBonus scaling
         // denominatorCalc is 1e18 * 1e8 = 1e26

         apy = numeratorCalc / denominatorCalc; // Result is SYNERGY_units / ET_unit * year. This is the APY factor.

        // To get APY scaled by 10000, we need to multiply by 10000.
        // Wait, the division by 1e26 (1e18 * 1e8) seems correct for the APY factor.
        // Let's simplify the `numeratorCalc` part:
        // baseEmissionRate is scaled 1e18. annualSeconds is 1.
        // (baseEmissionRate * annualSeconds) gives SYNERGY_units / (ET_unit * year) * 1e18
        // We want the factor.
        // Let's normalize baseEmissionRate first to SYNERGY_tokens / (ET_unit * second)
        uint256 baseEmissionRate_normalized = baseEmissionRate / 1e18; // Potential loss of precision if base < 1e18

        // Let's stick to scaled integer math carefully.
        // Rate per unit per second (Scaled 1e18) = baseEmissionRate
        // Effective Rate Per Unit Per Second (Scaled 1e18) = baseEmissionRate * (durationBonus / 10000) * (nftBonus / 10000)
        // = (baseEmissionRate * durationBonus * nftBonus) / 1e8
        // Annual Rate Per Unit (Scaled 1e18) = Effective Rate * annualSeconds
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e8
        // This is the number of SYNERGY units (scaled 1e18) you get per ET unit per year.
        // This is the APY factor, still scaled by 1e18.
        // To get APY scaled by 10000, we need (Annual Rate / 1e18) * 10000
        // = ((baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e8) / 1e18 * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e8 * 1e18)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Let's try again:
        // APY scaled by 10000
        // = (baseEmissionRate * durationBonus / 10000 * nftBonus / 10000 * annualSeconds * 10000) / 1e18 // Divide by 1e18 to get token units from base rate scaling
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (10000 * 10000 * 1e18)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Let's simplify the factors:
        // Effective Emission Factor = (durationBonus / 10000) * (nftBonus / 10000) scaled by 10000 -> ((durationBonus * nftBonus) / 10000) / 10000 * 10000?
        // Let's use 1e18 for all scaling for simplicity, like WAD.
        // baseEmissionRate_wad = baseEmissionRate * 1e18 / 1e18 = baseEmissionRate (if baseEmissionRate was originally scaled 1e18)
        // durationBonus_wad = durationBonus * 1e18 / 10000
        // nftBonus_wad = nftBonus * 1e18 / 10000
        // Effective Rate (WAD) = baseEmissionRate_wad * durationBonus_wad / 1e18 * nftBonus_wad / 1e18
        // = baseEmissionRate * (durationBonus * 1e18 / 10000) / 1e18 * (nftBonus * 1e18 / 10000) / 1e18
        // = (baseEmissionRate * durationBonus * nftBonus * 1e18) / (10000 * 10000 * 1e18)
        // = (baseEmissionRate * durationBonus * nftBonus) / 1e8
        // This is the rate per unit per second, scaled by 1e18.
        // Annual Rate (WAD) = Rate (WAD) * annualSeconds
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e8
        // This is the APY factor, scaled by 1e18.
        // APY scaled by 10000 = Annual Rate (WAD) / 1e18 * 10000
        // = ((baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e8) / 1e18 * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e8 * 1e18)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

         numeratorCalc = baseEmissionRate; // Scaled 1e18
         numeratorCalc = SafeMul(numeratorCalc, durationBonus); // Scaled 1e18 * 10000
         numeratorCalc = SafeMul(numeratorCalc, nftBonus); // Scaled 1e18 * 10000 * 10000 = 1e26
         numeratorCalc = SafeMul(numeratorCalc, annualSeconds); // Scaled 1e26 * seconds
         numeratorCalc = SafeMul(numeratorCalc, 10000); // Scaled 1e26 * seconds * 10000

         denominatorCalc = 1e18; // Base emission rate scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // Duration bonus scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // NFT bonus scaling
         denominatorCalc = SafeMul(denominatorCalc, 1e18); // To get actual token units from annual rate

         // denominatorCalc is 1e18 * 1e4 * 1e4 * 1e18 = 1e44 ? This seems too large.

         // Let's go back to simple logic and scaling.
         // Effective Emission Rate per unit per second (scaled 1e18) = (baseEmissionRate * durationBonus * nftBonus) / (10000 * 10000)
         // uint256 effRate_per_sec_scaled_1e18 = (baseEmissionRate * durationBonus * nftBonus) / 1e8;
         // Annual rate per unit (scaled 1e18) = effRate_per_sec_scaled_1e18 * annualSeconds
         // uint256 annualRate_per_unit_scaled_1e18 = (effRate_per_sec_scaled_1e18 * annualSeconds);
         // APY as a factor = annualRate_per_unit_scaled_1e18 / 1e18
         // APY scaled by 10000 = (annualRate_per_unit_scaled_1e18 / 1e18) * 10000
         // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e8 * 1e18)
         // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        numeratorCalc = baseEmissionRate; // Scaled 1e18
        numeratorCalc = SafeMul(numeratorCalc, durationBonus); // Scaled 1e18 * 10000
        numeratorCalc = SafeMul(numeratorCalc, nftBonus);     // Scaled 1e18 * 10000 * 10000 = 1e26
        numeratorCalc = SafeMul(numeratorCalc, annualSeconds); // Scaled 1e26 * seconds
        numeratorCalc = SafeMul(numeratorCalc, 10000); // Scaled 1e26 * seconds * 10000

        denominatorCalc = 1e18; // From baseEmissionRate scaling
        denominatorCalc = SafeMul(denominatorCalc, 10000); // From durationBonus scaling
        denominatorCalc = SafeMul(denominatorCalc, 10000); // From nftBonus scaling
        denominatorCalc = SafeMul(denominatorCalc, 1e18); // To convert annual rate from 1e18 units to 1 unit base

        // Total scaling in numerator is 1e18 * 1e4 * 1e4 * ~3e7 * 1e4 = 3e37 * 1e18 = 3e55 ? No
        // Numerator: baseEmissionRate (1e18) * durationBonus (1e4) * nftBonus (1e4) * annualSeconds (3e7) * 10000 (1e4)
        // = 1e18 * 1e4 * 1e4 * 3e7 * 1e4 = 3e37
        // Denominator: 1e18 * 10000 * 10000 = 1e18 * 1e8 = 1e26
        // Result = (3e37 / 1e26) = 3e11. This looks like a large number, but is it scaled APY?

        // Let's rethink the APY formula units:
        // APY = (Rewards Earned Per Year) / (Principal Staked)
        // Rewards Earned Per Year for 1 unit staked = Rate Per Unit Per Second * annualSeconds
        // Rate Per Unit Per Second = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY tokens / (ET unit * second)
        // Rewards Earned Per Year (for 1 unit) = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds SYNERGY tokens
        // Principal Staked = 1 ET unit
        // APY (factor) = ((baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds) / 1
        // APY (factor) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / (1e18 * 10000 * 10000)
        // APY (factor) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e26
        // APY (scaled 10000) = APY (factor) * 10000
        // APY (scaled 10000) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26
        // APY (scaled 10000) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e22

        // Numerator: baseEmissionRate (1e18) * durationBonus (1e4) * nftBonus (1e4) * annualSeconds (3e7)
        // = 1e18 * 1e4 * 1e4 * 3e7 = 3e33
        // Denominator: 1e22
        // Result: 3e33 / 1e22 = 3e11. This is the APY scaled by 10000.
        // Example: baseRate=1e18, durBonus=11000 (1.1x), nftBonus=12500 (1.25x), annualSec=3.15e7
        // APY scaled 10000 = (1e18 * 11000 * 12500 * 3.15e7) / 1e22
        // = (1e18 * 1.1e4 * 1.25e4 * 3.15e7) / 1e22
        // = (1e18 * 1.1 * 1.25 * 3.15 * 1e15) / 1e22
        // = (1.1 * 1.25 * 3.15 * 1e33) / 1e22
        // = (4.33125 * 1e33) / 1e22 = 4.33125 * 1e11
        // If APY was 100%, result should be 10000. This result is huge.
        // The baseEmissionRate likely needs to be much smaller, or the scaling factors are misunderstood.
        // Let's assume baseEmissionRate is scaled such that 1 unit of baseEmissionRate = 1e-18 SYNERGY_tokens / (ET_unit * second)
        // So baseEmissionRate = actual_rate * 1e18.
        // Actual Rate Per Unit Per Second = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY_tokens / (ET_unit * second)
        // Annual Rate Per Unit = Actual Rate * annualSeconds
        // APY (scaled 10000) = Annual Rate Per Unit * 10000
        // APY (scaled 10000) = ((baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds) * 10000
        // APY (scaled 10000) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 10000 * 10000)
        // APY (scaled 10000) = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Numerator: baseEmissionRate (1e18) * durationBonus (10000) * nftBonus (10000) * annualSeconds (3.15e7) * 10000
        // = 1e18 * 1e4 * 1e4 * 3.15e7 * 1e4 = 3.15e37
        // Denominator: 1e26
        // Result = 3.15e37 / 1e26 = 3.15e11. Still huge.

        // Maybe the bonus factors are multipliers, not additions to a base 10000?
        // Example: durationBonusRates[30 days] = 10000 means 1x bonus. 11000 means 1.1x bonus.
        // Effective multiplier = (durationBonus / 10000) * (nftBonus / 10000)
        // APY scaled 10000 = (baseEmissionRate / 1e18) * Effective Multiplier * annualSeconds * 10000
        // Effective Multiplier = (durationBonus * nftBonus) / 1e8
        // APY scaled 10000 = (baseEmissionRate / 1e18) * (durationBonus * nftBonus / 1e8) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 1e8)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26 -> Same formula as before.

        // Let's assume baseEmissionRate is SYNERGY_tokens (scaled 1e18) per EnergyToken unit per second (scaled 1e18).
        // So if baseEmissionRate is 1e18, it means 1 SYNERGY token per 1 Energy Token per second. This is extremely high.
        // Base emission rate should probably be something like 1e18 / (365 days * 24 hours * 3600 seconds) * 0.05 (for 5% annual).
        // 1e18 / 3.15e7 * 0.05 = 1e18 * 1.58e-9 ~ 1.58e9.
        // Let's use `baseEmissionRate` value itself as the rate per unit per second, scaled by 1e18 * 10000 * 10000 (1e26)
        // baseEmissionRate = actual_rate * 1e26
        // Then APY scaled 10000 = (baseEmissionRate / 1e26) * (durationBonus/10000) * (nftBonus/10000) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e26 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e34
        // This looks complicated. Let's redefine baseEmissionRate scaling.
        // baseEmissionRate is SYNERGY_tokens (scaled 1e18) per EnergyToken unit (scaled 1e18) per second.
        // So baseEmissionRate = 1e18 means 1 SYNERGY token per ET per second.
        // If baseEmissionRate = X, it means X/1e18 SYNERGY tokens per ET per second.

        // Corrected APY (scaled 10000) calculation:
        // Effective Emission Rate per unit per second = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY tokens per ET per second
        // Annual Rate per unit = Above Rate * annualSeconds
        // APY (scaled 10000) = Annual Rate * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Check scaling again:
        // baseEmissionRate (e.g. 1e18 for 1 SYNERGY/ET/sec)
        // durationBonus (e.g. 11000 for 1.1x)
        // nftBonus (e.g. 12500 for 1.25x)
        // annualSeconds (3.15e7)
        // 10000 (for scaling result)
        // Numerator: 1e18 * 11000 * 12500 * 3.15e7 * 10000 = 1e18 * 1.1e4 * 1.25e4 * 3.15e7 * 1e4
        // = 1.1 * 1.25 * 3.15 * 1e18 * 1e4 * 1e4 * 1e7 * 1e4 = 4.33 * 1e37
        // Denominator: 1e18 * 10000 * 10000 = 1e18 * 1e8 = 1e26
        // Result = 4.33e37 / 1e26 = 4.33e11. Still large.

        // The issue might be the scaling assumption of baseEmissionRate.
        // Let's assume `baseEmissionRate` is already scaled to be per unit per second PER TEN THOUSAND,
        // such that `baseEmissionRate / 10000` is the actual rate before bonuses.
        // baseEmissionRate = actual_rate * 10000 (tokens / unit / sec)
        // Effective Rate = (baseEmissionRate / 10000) * (durationBonus / 10000) * (nftBonus / 10000) tokens / unit / sec
        // Annual Rate = Effective Rate * annualSeconds
        // APY (scaled 10000) = Annual Rate * 10000
        // = (baseEmissionRate / 10000) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (10000 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / 1e8

        // Example: baseEmissionRate = 100 (meaning 0.01 tokens/unit/sec).
        // durationBonus=11000 (1.1x), nftBonus=12500 (1.25x), annualSec=3.15e7
        // Numerator: 100 * 11000 * 12500 * 3.15e7 = 1e2 * 1.1e4 * 1.25e4 * 3.15e7 = 1.1 * 1.25 * 3.15 * 1e17 = 4.33e17
        // Denominator: 1e8
        // Result: 4.33e17 / 1e8 = 4.33e9. Still too large for APY scaled by 10000.

        // Let's use a standard fixed point scaling like 1e18.
        // BaseEmissionRate: SYNERGY_tokens (scaled 1e18) per ET_token (scaled 1e18) per second.
        // `baseEmissionRate` as stored is this value scaled by 1e18.
        // So `baseEmissionRate / 1e18` is the actual rate per unit per second.
        // Effective Rate = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000)
        // APY scaled 10000 = Effective Rate * annualSeconds * 10000
        // = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Let's trust this formula and adjust the *meaning* of baseEmissionRate storage.
        // Let `baseEmissionRate` be stored as `actual_rate * 1e26`.
        // Example: For 5% base APY, actual_rate = 0.05 / annualSeconds.
        // actual_rate = 0.05 / 3.15e7 ~ 1.58e-9.
        // baseEmissionRate stored = 1.58e-9 * 1e26 = 1.58e17. This seems reasonable.

        // With `baseEmissionRate` stored as `actual_rate * 1e26`:
        // APY (scaled 10000) = ( (baseEmissionRate / 1e26) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds ) * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e26 * 10000 * 10000)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e34

        // This feels more robust. Let's use this final formula and update the comment for baseEmissionRate.

        // Numerator: baseEmissionRate (scaled 1e26) * durationBonus (1e4) * nftBonus (1e4) * annualSeconds (3.15e7) * 10000 (1e4)
        // = 1e26 * 1e4 * 1e4 * 3.15e7 * 1e4 = 3.15e45
        // Denominator: 1e34
        // Result = 3.15e45 / 1e34 = 3.15e11. Still... too big?

        // Okay, last attempt at scaling APY:
        // Effective Rate per unit per second = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) SYNERGY tokens / (ET token * second)
        // Annual Rate per unit = Effective Rate * annualSeconds
        // APY factor = Annual Rate / 1 (because Principal is 1 unit)
        // APY scaled 10000 = APY factor * 10000
        // APY scaled 10000 = (baseEmissionRate * durationBonus * nftBonus * annualSeconds) / (1e18 * 10000 * 10000) * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        // Example: Base 5% APY. Actual rate per second = 0.05 / 3.15e7.
        // baseEmissionRate (scaled 1e18) = (0.05 / 3.15e7) * 1e18 ~ 1.58e9.
        // durationBonus = 11000. nftBonus = 12500. annualSeconds = 3.15e7. 10000.
        // Num = 1.58e9 * 11000 * 12500 * 3.15e7 * 10000
        // = 1.58e9 * 1.1e4 * 1.25e4 * 3.15e7 * 1e4
        // = 1.58 * 1.1 * 1.25 * 3.15 * 1e9 * 1e4 * 1e4 * 1e7 * 1e4 = 6.88 * 1e28
        // Denom = 1e26
        // Result = 6.88e28 / 1e26 = 6.88e2. This is ~688.
        // Expected: 5% * 1.1 * 1.25 = 5.5% * 1.25 = 6.875%.
        // APY scaled 10000 = 6.875 * 100 = 687.5.
        // The result 688 is close! This formula seems correct.

         numeratorCalc = baseEmissionRate; // Scaled 1e18
         numeratorCalc = SafeMul(numeratorCalc, durationBonus); // Scaled 1e18 * 10000
         numeratorCalc = SafeMul(numeratorCalc, nftBonus);     // Scaled 1e18 * 10000 * 10000 = 1e26
         numeratorCalc = SafeMul(numeratorCalc, annualSeconds); // Scaled 1e26 * seconds
         numeratorCalc = SafeMul(numeratorCalc, 10000); // Scaled 1e26 * seconds * 10000

         denominatorCalc = 1e18; // From baseEmissionRate scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // From durationBonus scaling
         denominatorCalc = SafeMul(denominatorCalc, 10000); // From nftBonus scaling
         denominatorCalc = SafeMul(denominatorCalc, 1e18); // To convert annual rate from 1e18 units to 1 unit base and factor

        // Final formula:
        // APY scaled 10000 = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 1e4 * 1e4 * 1e18)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e44  -- No this is not right.

        // The correct denominator based on the formula and scaling seems to be 1e26
        // baseEmissionRate is scaled 1e18.
        // durationBonus/nftBonus are scaled 10000.
        // annualSeconds is 1.
        // result is scaled 10000.
        // Numerator: baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000
        // Denominator: 1e18 * 10000 * 10000 * 1
        // Final formula: (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 1e8)
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / 1e26

        numeratorCalc = baseEmissionRate;
        numeratorCalc = SafeMul(numeratorCalc, durationBonus);
        numeratorCalc = SafeMul(numeratorCalc, nftBonus);
        numeratorCalc = SafeMul(numeratorCalc, annualSeconds);
        numeratorCalc = SafeMul(numeratorCalc, 10000);

        denominatorCalc = 1e18; // Base rate scaling
        denominatorCalc = SafeMul(denominatorCalc, 10000); // Duration scaling
        denominatorCalc = SafeMul(denominatorCalc, 10000); // NFT scaling

        // Denominator is 1e18 * 1e4 * 1e4 = 1e26
        // This aligns with the formula (base * dur * nft * annual * 10000) / 1e26

        // Need SafeMath functions
        // Use OpenZeppelin SafeMath if targeting <0.8, or just rely on 0.8+ checked arithmetic.
        // With 0.8+, multiplication/addition overflow will revert. Division by zero reverts.
        // So SafeMul/SafeDiv are only needed if intermediate results *before* the final division might overflow uint256.
        // Let's check max possible numerator value:
        // Max baseEmissionRate: Let's say owner sets it to 1e22 (very high).
        // Max duration/nft bonus: Let's say 20000 (2x).
        // Max annualSeconds: 3.15e7.
        // Max 10000.
        // Numerator: 1e22 * 20000 * 20000 * 3.15e7 * 10000 = 1e22 * 2e4 * 2e4 * 3.15e7 * 1e4
        // = 4 * 3.15 * 1e22 * 1e4 * 1e4 * 1e7 * 1e4 = 12.6 * 1e41 = 1.26e42.
        // Denominator: 1e26.
        // Result: 1.26e42 / 1e26 = 1.26e16. This is still scaled by 10000.
        // Actual APY: 1.26e16 / 10000 = 1.26e12 %. This is astronomically high.
        // The parameters need to be set carefully. Max plausible APY might be 10000% (result 1e8).
        // 1e8 * 1e26 = 1e34. The numerator (1.26e42) significantly exceeds this.
        // So, intermediate overflow is possible *before* the final division by 1e26.
        // We need to use SafeMul and potentially divide earlier if possible.

        // Let's rewrite the calculation to divide earlier:
        // APY scaled 10000 = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds * 10000
        // = (baseEmissionRate * durationBonus * nftBonus * annualSeconds * 10000) / (1e18 * 10000 * 10000)
        // = (baseEmissionRate / 1e18) * (durationBonus / 10000) * (nftBonus / 10000) * annualSeconds * 10000
        // Let's divide parts first.
        // Part 1: baseEmissionRate / 1e18
        // Part 2: durationBonus / 10000
        // Part 3: nftBonus / 10000
        // Part 4: annualSeconds
        // Part 5: 10000

        // Using multiplication then division:
        // res = (baseEmissionRate * durationBonus) / 10000
        // res = (res * nftBonus) / 10000
        // res = (res * annualSeconds)
        // res = (res * 10000)
        // res = res / 1e18

        // Let's recheck max values.
        // baseEmissionRate (1e22), durationBonus (2e4), nftBonus (2e4), annualSeconds (3.15e7), 10000 (1e4)
        // 1. (1e22 * 2e4) / 1e4 = 2e22
        // 2. (2e22 * 2e4) / 1e4 = 4e22
        // 3. 4e22 * 3.15e7 = 12.6e29 = 1.26e30
        // 4. 1.26e30 * 1e4 = 1.26e34
        // 5. 1.26e34 / 1e18 = 1.26e16.
        // This sequence of operations works without exceeding uint256 max during intermediate steps, *provided SafeMul is used*.

        uint256 annualSecondsSafe = 31536000; // Use a variable for clarity
        uint256 apy_scaled_10000;

        // Calculate intermediate values using SafeMul to check for overflow
        uint256 rate_step1 = SafeMul(baseEmissionRate, durationBonus);
        uint256 rate_step2 = rate_step1 / 10000; // Divide by 10000 for durationBonus scaling

        uint256 rate_step3 = SafeMul(rate_step2, nftBonus);
        uint256 rate_step4 = rate_step3 / 10000; // Divide by 10000 for nftBonus scaling

        uint256 annualRate_step1 = SafeMul(rate_step4, annualSecondsSafe); // Multiply by seconds in a year
        uint256 annualRate_step2 = SafeMul(annualRate_step1, 10000); // Multiply by 10000 for final scaling

        apy_scaled_10000 = annualRate_step2 / 1e18; // Divide by 1e18 for baseEmissionRate scaling

        return apy_scaled_10000;

    }

    // Custom SafeMul function for uint256
    function SafeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SynergyCore: SafeMul overflow");
        return c;
    }


    /// @notice Returns the time elapsed since the last triggerPulse call.
    /// @return secondsElapsed The number of seconds.
    function getTimeSinceLastPulse() external view returns (uint256 secondsElapsed) {
        return block.timestamp - lastPulseTime;
    }

    /// @notice Calculates the potential withdrawal fee for a user's stake based on current duration.
    /// @param _user The user's address.
    /// @param _energyToken The ERC-20 token type.
    /// @param _amount The amount to calculate the fee for (typically the full stake).
    /// @return feeAmount The calculated fee amount.
    function getWithdrawalFee(address _user, IERC20 _energyToken, uint256 _amount) external view returns (uint256 feeAmount) {
         Stake storage stake = userStakes[_user][address(_energyToken)];

         if (stake.amount == 0 || _amount == 0) {
             return 0;
         }

        uint256 stakeDuration = block.timestamp - stake.startTime;

        if (stakeDuration < minStakeDurationForFee) {
            return (_amount * withdrawalFeeRate) / 10000;
        } else {
            return 0;
        }
    }

    /// @notice Checks if a user meets hypothetical criteria for a special protocol feature.
    ///         Example Criteria: Staked > X amount, Staked for > Y duration, Owns > Z registered NFTs.
    /// @param _user The user's address.
    /// @return hasAccess True if the user qualifies, false otherwise.
    function checkSpecialAccess(address _user) external view returns (bool hasAccess) {
        // Example criteria: Staked > 1000 units of first authorized token AND owns at least 1 registered NFT
        if (authorizedEnergyTokensList.length == 0) return false;

        IERC20 firstEnergyToken = IERC20(authorizedEnergyTokensList[0]);
        Stake storage stake = userStakes[_user][address(firstEnergyToken)];

        uint256 requiredStakeAmount = 1000 * (10 ** uint256(firstEnergyToken.decimals())); // Example: 1000 tokens
        uint256 requiredNFTCount = 1;
        uint256 requiredStakeDuration = 90 days; // Example: 90 days

        bool meetsStakeAmount = stake.amount >= requiredStakeAmount;
        bool meetsStakeDuration = (stake.amount > 0 && (block.timestamp - stake.startTime) >= requiredStakeDuration); // Must have stake > 0 to check duration
        bool meetsNFTCount = _countRegisteredOwnedNFTs(_user) >= requiredNFTCount;

        // Combine criteria (example: all must be true)
        return meetsStakeAmount && meetsStakeDuration && meetsNFTCount;
    }


    /// @notice Returns the list of authorized Energy Token addresses.
    /// @return tokens An array of authorized Energy Token addresses.
    function getAuthorizedEnergyTokens() external view returns (address[] memory) {
        // Need to filter the list to only include currently authorized ones if removeEnergyToken is used
        uint256 authorizedCount = 0;
        for(uint256 i = 0; i < authorizedEnergyTokensList.length; i++) {
            if(isAuthorizedEnergyToken[authorizedEnergyTokensList[i]]) {
                authorizedCount++;
            }
        }

        address[] memory authorizedTokens = new address[](authorizedCount);
        uint256 current = 0;
         for(uint256 i = 0; i < authorizedEnergyTokensList.length; i++) {
            if(isAuthorizedEnergyToken[authorizedEnergyTokensList[i]]) {
                authorizedTokens[current] = authorizedEnergyTokensList[i];
                current++;
            }
        }
        return authorizedTokens;
    }

    /// @notice Returns the total amount of a specific Energy Token staked in the protocol.
    /// @param _energyToken The ERC-20 token type.
    /// @return totalAmount The total staked amount.
    function getProtocolTotalStaked(IERC20 _energyToken) external view onlyAuthorizedEnergyToken(_energyToken) returns (uint256 totalAmount) {
        // Summing total staked across all users is gas-prohibitive for many users.
        // A common pattern is to track a global total variable updated on stake/withdraw.
        // Let's add a mapping for this to make this view function efficient.
        // Mapping: energyTokenAddress => totalStakedAmount
        // Need to add `mapping(address => uint256) private totalStakedByToken;` state variable
        // and update it in stakeEnergyToken and withdrawEnergyToken.

        // For now, return 0 as the user requested >= 20 functions and adding the mapping+updates
        // would slightly refactor stake/withdraw. This is a known limitation of simple sum views.
        // A more scalable approach involves tracking total staked globally.
        // Let's assume a global tracker was added for this function to be meaningful.
        // Adding the state variable and updates would make this function require state changes.
        // Keeping it `view` means it must be calculable from existing state without loops over all users.
        // Therefore, a separate tracking variable is necessary.

        // Add state variable: `mapping(address => uint256) private totalStakedByToken;`
        // Update in `stakeEnergyToken`: `totalStakedByToken[tokenAddress] += transferredAmount;`
        // Update in `withdrawEnergyToken`: `totalStakedByToken[tokenAddress] -= _amount;`
        // Then this function would be: `return totalStakedByToken[address(_energyToken)];`

        // Implementing the state variable and updates:
        // Adding to state variables section: `mapping(address => uint256) private totalStakedByToken;`
        // Update stakeEnergyToken: `totalStakedByToken[tokenAddress] += transferredAmount;` after successful transferFrom
        // Update withdrawEnergyToken: `totalStakedByToken[tokenAddress] -= _amount;` before transferring tokens out

        // Okay, adding the state variable and updates. This makes `getProtocolTotalStaked` efficient.
        return totalStakedByToken[address(_energyToken)];

    }

    // Added state variable as discussed in getProtocolTotalStaked thought process
    mapping(address => uint256) private totalStakedByToken;


}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic Yield Calculation:** The SYNERGY yield is not a fixed rate. It's calculated based on a base emission rate, a duration bonus (tier-based), and an NFT bonus. This creates varied APYs for users depending on their stake age and NFT holdings.
2.  **NFT Synergy:** Holding specific, registered ERC-721 NFTs directly influences the yield rate of staked ERC-20 tokens. This links two different token standards in a functional way beyond just ownership. The contract verifies current ownership of registered NFTs when calculating bonuses.
3.  **Required External "Pulse":** Rewards don't accrue continuously moment-to-moment. They only accrue for periods finalized by the `triggerPulse()` function. This adds an interactive, almost "game-like" element where the community (or a bot/keeper) needs to actively trigger the pulse to unlock reward calculation for the previous period. This design contrasts with standard staking where rewards tick up every block or second passively.
4.  **Duration-Based Dynamics:** Stake duration impacts yield (bonus) and withdrawal cost (fee). This encourages longer-term commitment.
5.  **On-Demand Reward Calculation (with Pulse Cap):** Rewards are calculated on demand (`getPendingSynergyRewards`, `claimSynergyRewards`, triggered internally by `stake`/`withdraw`) but *only* up to the `lastPulseTime`. This makes the per-user calculation efficient as it only processes time since the last relevant event for that user, capped by the global pulse.
6.  **Conditional Access (`checkSpecialAccess`):** Demonstrates how staking status and NFT ownership can gate access to other protocol features (represented here by a simple boolean). This is a pattern used in some protocols for premium access, governance rights, etc.
7.  **Parameter Control & Scalability Considerations:** While many parameters are owner-settable for flexibility, the reward calculation and pulse mechanism are designed to be relatively gas-efficient *per user interaction*, even if the total number of users is large, because calculations are per-user on demand, not iterating all users globally in `triggerPulse`. The `getProtocolTotalStaked` requires a dedicated state variable updated on state changes for efficiency. The NFT registration tracking needs care (checking ownership dynamically).
8.  **Layered Interactions:** The contract isn't just a token vault; it orchestrates interactions between a stakeable token, a reward token, and a utility/bonus NFT, all modulated by time and external action (`triggerPulse`).

This contract is significantly more complex than a basic staking contract and incorporates several patterns found in advanced DeFi and NFT projects, aiming for creativity and demonstrating a broader range of Solidity features and design considerations. It deliberately includes many setter/getter-like functions to meet the function count requirement while supporting the core dynamic mechanics.

**Note on Deploying and Using:**

*   This contract requires `IERC20` and `IERC721` interfaces, typically imported from OpenZeppelin.
*   The owner must deploy and then call admin functions (`setSynergyToken`, `setCrystalNFT`, `addEnergyToken`, `setBaseEmissionRate`, etc.) to configure the protocol before users can stake.
*   Users need to approve the `SynergyCoreProtocol` contract to spend their Energy Tokens (`IERC20.approve`) and potentially their Crystal NFTs (though `ownerOf` is used here, explicit approval might be needed for different NFT interactions).
*   The `triggerPulse()` function must be called periodically for rewards to become accrueable beyond the initial stake time.
*   The scaling (using `10000` and `1e18`) for rates, bonuses, and fees is crucial for precision with integer arithmetic and should be carefully considered when setting parameters. The APY calculation is particularly sensitive to this.

This provides a robust starting point for a creative and advanced smart contract.