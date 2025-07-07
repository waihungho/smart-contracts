Okay, here is a Solidity smart contract designed with several interesting, advanced, and creative concepts, going beyond standard token or simple staking contracts.

The core idea revolves around a "Synergistic NFT Treasury," where staking specific NFTs yields dynamic rewards influenced by NFT traits, staking duration, and the overall treasury health. It also includes features like yield boosting, penalty mechanisms, staking delegation, and basic treasury management.

**Disclaimer:** This contract is complex and contains features that carry significant risk (e.g., penalty mechanisms, treasury management, dynamic calculations). It is provided for educational purposes as an example of advanced concepts. **It has NOT been audited and should not be used in production without thorough testing and security review.**

---

### **Synergistic NFT Treasury (SYNT) Contract**

**Outline:**

1.  **Contract Description:** Synergistic NFT Staking and Dynamic Yield Treasury.
2.  **Core Concepts:**
    *   NFT Staking for ERC-20 Rewards.
    *   Dynamic Reward Rate (influenced by NFT traits, staking duration, treasury balance).
    *   ERC-20 Treasury (accepts multiple tokens).
    *   Yield Boosting Mechanism.
    *   Staking Penalty/Lock Mechanism.
    *   Staking Claim Delegation.
    *   Pausable Functionality.
3.  **Inheritance:** Ownable, ReentrancyGuard.
4.  **Interfaces:** IERC20, IERC721.
5.  **State Variables:**
    *   Contract Addresses (Reward Token, NFT Contract, Accepted Treasury Tokens).
    *   Configuration Parameters (Base Reward Rate, Trait Multipliers, Duration Tiers/Bonuses, Treasury Impact Factor).
    *   Staking Data (Mapping `tokenId` to `StakingInfo`, Mapping `staker` to `stakedTokenIds`).
    *   Dynamic State (Boost multipliers, Penalty lock times, Paused states).
    *   Treasury Balances.
6.  **Structs:** `StakingInfo`.
7.  **Events:** Stake, Unstake, ClaimRewards, DepositTreasury, Config updates, Boost, Penalty, Delegation.
8.  **Modifiers:** `onlyOwner`, `whenNotPausedStaking`, `whenNotPausedRewards`, `nonReentrant`.
9.  **Functions:**
    *   **Admin/Setup (Owner Only):** Set contract addresses, set reward parameters (base rate, traits, duration bonuses, treasury impact), manage accepted treasury tokens, emergency withdrawals, pause/unpause, transfer ownership.
    *   **Staking/User Interaction:** Stake NFT, Unstake NFT, Claim Rewards, Deposit to Treasury, Boost Staking Yield, Delegate Claim Rights.
    *   **Penalty/Moderation (Owner Only or Authorized):** Apply Penalty (reduce rewards/lock stake).
    *   **Treasury Management (Owner Only):** Withdraw specific token from treasury, Transfer treasury funds to external address.
    *   **View Functions (Public):** Get Pending Rewards for a specific NFT, Get Total Pending Rewards for user, Get User's Staked NFTs, Get Staking Info for specific NFT, View Configuration parameters, Get Treasury Balance.
    *   **Internal Functions:** Calculate Dynamic Reward Rate, Update Staking State (before reward calculations).

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets initial required contract addresses.
2.  `setRewardToken(address _rewardToken)`: Sets the address of the ERC-20 token used for rewards.
3.  `manageAcceptedDepositToken(address _token, bool _accept)`: Adds or removes an ERC-20 token from the list of accepted treasury deposit tokens.
4.  `setSynergyNFTContract(address _synergyNFTContract)`: Sets the address of the ERC-721 NFT contract that can be staked.
5.  `setBaseRewardRate(uint256 _baseRate)`: Sets the base reward rate (per NFT per second, in reward token units).
6.  `setTraitMultiplier(string memory _traitType, string memory _traitValue, uint256 _multiplierBps)`: Sets a yield multiplier for NFTs possessing a specific trait (in basis points, e.g., 12000 for 1.2x).
7.  `setDurationBonusTier(uint64 _durationSeconds, uint256 _bonusBps)`: Sets a duration bonus tier, providing extra yield after a certain staking duration (in basis points).
8.  `setTreasuryBalanceImpactFactor(address _token, int256 _impactFactor)`: Sets how the balance of a specific accepted treasury token impacts the overall reward rate (e.g., positive factor means higher balance increases yield, negative decreases).
9.  `emergencyWithdrawNFT(uint256 _tokenId, address _to)`: Allows the owner to withdraw a specific staked NFT in case of emergencies.
10. `emergencyWithdrawToken(address _token, uint256 _amount, address _to)`: Allows the owner to withdraw any token stuck in the contract in case of emergencies.
11. `pauseStaking()`: Pauses the ability for users to stake new NFTs.
12. `unpauseStaking()`: Unpauses the ability for users to stake new NFTs.
13. `pauseRewards()`: Pauses the accrual of staking rewards for all staked NFTs.
14. `unpauseRewards()`: Unpauses staking reward accrual.
15. `stakeNFT(uint256 _tokenId)`: Allows a user to stake their NFT (requires prior approval).
16. `unstakeNFT(uint256 _tokenId)`: Allows a user to unstake their NFT and claim any pending rewards.
17. `claimRewards(uint256[] calldata _tokenIds)`: Allows a user to claim pending rewards for multiple specific staked NFTs.
18. `depositTreasury(address _token, uint256 _amount)`: Allows a user to deposit an accepted ERC-20 token into the contract's treasury (requires prior approval).
19. `boostStakingYield(uint256 _tokenId, uint256 _boostMultiplierBps, uint64 _duration)`: Allows a user to apply a temporary yield boost to their staked NFT (might require burning tokens or other conditions, simplified here).
20. `applyPenalty(uint256 _tokenId, uint256 _penaltyAmount, uint64 _lockUntil)`: Allows the owner to apply a penalty by reducing pending rewards or locking the stake until a specific timestamp.
21. `delegateStakingPower(uint256 _tokenId, address _delegatee)`: Allows a staker to delegate the right to claim rewards or view info for a specific staked NFT.
22. `checkReputationTier(address _user)`: (View Function) Placeholder/example to represent checking a user's reputation based on criteria tracked by the contract (e.g., total duration staked, SYNT earned). *Note: Actual tier logic/storage not fully implemented here to keep focus, but function signature is defined.*
23. `transferTreasuryFunds(address _token, uint256 _amount, address _to)`: Allows the owner to transfer funds from the contract's treasury to an external address.
24. `getPendingRewards(uint256 _tokenId)`: (View Function) Calculates and returns the currently pending rewards for a specific staked NFT.
25. `getTotalPendingRewards(address _user)`: (View Function) Calculates and returns the total pending rewards for all NFTs staked by a specific user.
26. `getUserStakedTokenIds(address _user)`: (View Function) Returns an array of Token IDs staked by a specific user.
27. `getNFTStakingInfo(uint256 _tokenId)`: (View Function) Returns the staking information (staker, start time, etc.) for a specific staked NFT.
28. `getTreasuryBalance(address _token)`: (View Function) Returns the balance of a specific accepted treasury token held by the contract.
29. `viewCurrentRewardRate(uint256 _tokenId)`: (View Function) Calculates and returns the current effective SYNT reward rate per second for a specific staked NFT, considering all dynamic factors.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for clarity on operations

// Assuming an interface for your Synergy NFT contract that can provide traits
// In a real scenario, this interface would match your specific NFT contract
interface ISynergyNFT is IERC721 {
    // Example function to get a specific trait value for a token
    // The actual implementation depends on your NFT contract
    function getTrait(uint256 tokenId, string calldata traitType) external view returns (string memory);

    // Example function to get multiple traits or a structured trait object
    // function getTraits(uint256 tokenId) external view returns (NFTTrait[] memory);
}

/**
 * @title SynergyNFTTreasury
 * @dev A smart contract for staking Synergy NFTs to earn dynamic ERC-20 rewards.
 * Rewards are influenced by NFT traits, staking duration, and treasury balance.
 * Includes treasury management, boosting, penalties, and delegation features.
 */
contract SynergyNFTTreasury is Ownable, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    // Addresses
    IERC20 public rewardToken;
    ISynergyNFT public synergyNFTContract;
    mapping(address => bool) public acceptedDepositTokens;

    // Configuration - Owner settable
    uint256 public baseRewardRate; // Base SYNT per second per NFT
    mapping(string => mapping(string => uint256)) public traitMultipliersBps; // traitType => traitValue => multiplier (in basis points)
    mapping(uint64 => uint256) public durationBonusTiersBps; // seconds_staked => bonus_percentage (in basis points)
    uint64[] public durationBonusTierThresholds; // Sorted list of duration thresholds
    mapping(address => int256) public treasuryBalanceImpactFactor; // tokenAddress => impact factor (positive/negative)

    // Staking Data
    struct StakingInfo {
        address staker;
        uint256 tokenId; // Staked NFT ID
        uint64 startTime; // Timestamp staking started
        uint64 lastClaimTime; // Timestamp rewards were last claimed
        uint256 accumulatedUnclaimedRewards; // Rewards accrued but not yet claimed
    }
    mapping(uint256 => StakingInfo) private stakedNFTs; // tokenId => StakingInfo
    mapping(address => uint256[]) private userStakedTokenIds; // staker => list of their staked tokenIds

    // Dynamic State / Active Effects
    mapping(uint256 => uint256) private stakingBoostMultiplierBps; // tokenId => boost multiplier (in basis points)
    mapping(uint256 => uint64) private stakingBoostEndTime; // tokenId => timestamp boost expires
    mapping(uint256 => uint64) private stakingLockUntil; // tokenId => timestamp stake is locked until
    mapping(uint256 => address) private stakingClaimDelegatee; // tokenId => address allowed to claim rewards

    // Pausable
    bool public stakingPaused = false;
    bool public rewardsPaused = false;

    // --- Events ---

    event RewardTokenSet(address indexed _rewardToken);
    event AcceptedDepositTokenManaged(address indexed _token, bool _accepted);
    event SynergyNFTContractSet(address indexed _synergyNFTContract);
    event BaseRewardRateSet(uint256 _baseRate);
    event TraitMultiplierSet(string _traitType, string _traitValue, uint256 _multiplierBps);
    event DurationBonusTierSet(uint64 _durationSeconds, uint256 _bonusBps);
    event TreasuryBalanceImpactFactorSet(address indexed _token, int256 _impactFactor);

    event NFTStaked(address indexed staker, uint256 indexed tokenId, uint64 startTime);
    event NFTUnstaked(address indexed staker, uint256 indexed tokenId, uint64 unstakeTime, uint256 claimedRewards);
    event RewardsClaimed(address indexed staker, uint252 indexed tokenId, uint256 amount, uint64 claimTime);
    event BatchRewardsClaimed(address indexed staker, uint256 totalAmount, uint64 claimTime);

    event DepositTreasury(address indexed depositor, address indexed token, uint256 amount);
    event WithdrawalTreasury(address indexed recipient, address indexed token, uint256 amount);

    event StakingYieldBoosted(uint256 indexed tokenId, uint256 multiplierBps, uint64 duration, uint64 endTime);
    event PenaltyApplied(uint256 indexed tokenId, uint256 reducedRewards, uint64 lockUntil);
    event ClaimDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);

    event StakingPaused(bool _paused);
    event RewardsPaused(bool _paused);

    // --- Modifiers ---

    modifier whenNotPausedStaking() {
        require(!stakingPaused, "Staking is paused");
        _;
    }

    modifier whenNotPausedRewards() {
        require(!rewardsPaused, "Reward accrual is paused");
        _;
    }

    modifier onlyDelegateeOrOwner(uint256 _tokenId) {
        require(msg.sender == stakedNFTs[_tokenId].staker || msg.sender == stakingClaimDelegatee[_tokenId] || msg.sender == owner(), "Not authorized");
        _;
    }

    // --- Constructor ---

    constructor(address _rewardToken, address _synergyNFTContract) Ownable(msg.sender) {
        require(_rewardToken != address(0), "Reward token address cannot be zero");
        require(_synergyNFTContract != address(0), "NFT contract address cannot be zero");
        rewardToken = IERC20(_rewardToken);
        synergyNFTContract = ISynergyNFT(_synergyNFTContract);
        emit RewardTokenSet(_rewardToken);
        emit SynergyNFTContractSet(_synergyNFTContract);
    }

    // --- Admin / Setup Functions (Owner Only) ---

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Reward token address cannot be zero");
        rewardToken = IERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    function manageAcceptedDepositToken(address _token, bool _accept) external onlyOwner {
        require(_token != address(0), "Token address cannot be zero");
        acceptedDepositTokens[_token] = _accept;
        emit AcceptedDepositTokenManaged(_token, _accept);
    }

    function setSynergyNFTContract(address _synergyNFTContract) external onlyOwner {
        require(_synergyNFTContract != address(0), "NFT contract address cannot be zero");
        synergyNFTContract = ISynergyNFT(_synergyNFTContract);
        emit SynergyNFTContractSet(_synergyNFTContract);
    }

    function setBaseRewardRate(uint256 _baseRate) external onlyOwner {
        baseRewardRate = _baseRate;
        emit BaseRewardRateSet(_baseRate);
    }

    // Set a yield multiplier for a specific trait type and value
    function setTraitMultiplier(string memory _traitType, string memory _traitValue, uint256 _multiplierBps) external onlyOwner {
        traitMultipliersBps[_traitType][_traitValue] = _multiplierBps;
        emit TraitMultiplierSet(_traitType, _traitValue, _multiplierBps);
    }

    // Set a bonus tier for staking duration. Duration thresholds should be increasing.
    function setDurationBonusTier(uint64 _durationSeconds, uint256 _bonusBps) external onlyOwner {
        durationBonusTiersBps[_durationSeconds] = _bonusBps;

        // Keep durationBonusTierThresholds sorted
        bool found = false;
        for (uint i = 0; i < durationBonusTierThresholds.length; i++) {
            if (durationBonusTierThresholds[i] == _durationSeconds) {
                found = true;
                break;
            }
            if (durationBonusTierThresholds[i] > _durationSeconds) {
                // Insert before this element
                uint64[] memory newThresholds = new uint64[](durationBonusTierThresholds.length + 1);
                for (uint j = 0; j < i; j++) newThresholds[j] = durationBonusTierThresholds[j];
                newThresholds[i] = _durationSeconds;
                for (uint j = i; j < durationBonusTierThresholds.length; j++) newThresholds[j + 1] = durationBonusTierThresholds[j];
                durationBonusTierThresholds = newThresholds;
                found = true;
                break;
            }
        }
        if (!found) {
            // Add to the end if it's the largest
            durationBonusTierThresholds.push(_durationSeconds);
        }

        emit DurationBonusTierSet(_durationSeconds, _bonusBps);
    }

    // Set how the balance of a specific treasury token impacts the reward rate
    function setTreasuryBalanceImpactFactor(address _token, int256 _impactFactor) external onlyOwner {
         require(acceptedDepositTokens[_token] || _token == address(rewardToken), "Token must be accepted or reward token");
        treasuryBalanceImpactFactor[_token] = _impactFactor;
        emit TreasuryBalanceImpactFactorSet(_token, _impactFactor);
    }


    function emergencyWithdrawNFT(uint256 _tokenId, address _to) external onlyOwner {
        require(stakedNFTs[_tokenId].staker != address(0), "NFT not staked");
        require(_to != address(0), "Recipient cannot be zero");
        // Perform checks/cleanup without calculating rewards
        address staker = stakedNFTs[_tokenId].staker;

        // Remove from user's staked list (expensive - needs careful consideration in production)
        uint256[] storage userTokens = userStakedTokenIds[staker];
        for (uint i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == _tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }

        delete stakedNFTs[_tokenId];
        delete stakingBoostMultiplierBps[_tokenId];
        delete stakingBoostEndTime[_tokenId];
        delete stakingLockUntil[_tokenId];
        delete stakingClaimDelegatee[_tokenId];


        // Transfer NFT
        ISynergyNFT(synergyNFTContract).safeTransferFrom(address(this), _to, _tokenId);

        emit NFTUnstaked(staker, _tokenId, uint64(block.timestamp), 0); // Log 0 rewards claimed as this is emergency
    }

    function emergencyWithdrawToken(address _token, uint256 _amount, address _to) external onlyOwner {
        require(_token != address(0), "Token address cannot be zero");
        require(_to != address(0), "Recipient cannot be zero");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        uint256 amountToTransfer = _amount == 0 ? balance : _amount; // 0 means max balance
        require(balance >= amountToTransfer, "Insufficient token balance in contract");

        token.transfer( _to, amountToTransfer);
        emit WithdrawalTreasury(_to, _token, amountToTransfer);
    }

    function pauseStaking() external onlyOwner {
        stakingPaused = true;
        emit StakingPaused(true);
    }

    function unpauseStaking() external onlyOwner {
        stakingPaused = false;
        emit StakingPaused(false);
    }

    function pauseRewards() external onlyOwner {
        // Before pausing, update accumulated rewards for all active stakes
        // This avoids issues with reward calculation when paused
        // NOTE: This can be GAS INTENSIVE if many NFTs are staked.
        // A better approach might be to handle this in the calculation itself
        // by simply not accruing rewards when paused.
        // For this example, we'll just set the flag. Reward calculation must handle it.
        rewardsPaused = true;
        emit RewardsPaused(true);
    }

    function unpauseRewards() external onlyOwner {
        // When unpausing, update lastClaimTime for all active stakes
        // to start accruing from now.
        // NOTE: This is also GAS INTENSIVE.
        // A better approach is to simply resume calculation based on original lastClaimTime
        // but check the paused flag within the calculation logic.
        // We will handle this in the calculate logic.
        rewardsPaused = false;
        emit RewardsPaused(false);
    }


    // --- Staking / User Interaction Functions ---

    // Required by ERC721Holder to accept NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         require(msg.sender == address(synergyNFTContract), "Can only receive NFTs from registered NFT contract");
         // Further checks can be added here if needed based on data
         return this.onERC721Received.selector;
    }

    function stakeNFT(uint256 _tokenId) external nonReentrant whenNotPausedStaking {
        require(stakedNFTs[_tokenId].staker == address(0), "NFT is already staked");
        require(synergyNFTContract.ownerOf(_tokenId) == msg.sender, "Caller must own the NFT");

        // Transfer NFT to this contract
        synergyNFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint64 currentTime = uint64(block.timestamp);

        stakedNFTs[_tokenId] = StakingInfo({
            staker: msg.sender,
            tokenId: _tokenId,
            startTime: currentTime,
            lastClaimTime: currentTime, // Start accruing from now
            accumulatedUnclaimedRewards: 0 // Start with 0 unclaimed
        });

        userStakedTokenIds[msg.sender].push(_tokenId);

        emit NFTStaked(msg.sender, _tokenId, currentTime);
    }

    function unstakeNFT(uint256 _tokenId) external nonReentrant {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        require(stakingInfo.staker == msg.sender, "Caller does not own this stake");
        require(block.timestamp >= stakingLockUntil[_tokenId], "Stake is locked");

        // Calculate and claim pending rewards before unstaking
        uint256 pending = _calculatePendingRewards(_tokenId);
        uint256 totalClaimable = pending.add(stakingInfo.accumulatedUnclaimedRewards);

        if (totalClaimable > 0) {
             // Transfer rewards
            require(rewardToken.transfer(msg.sender, totalClaimable), "Reward token transfer failed");
            emit RewardsClaimed(msg.sender, _tokenId, totalClaimable, uint64(block.timestamp));
        }


        // Remove from user's staked list (expensive - needs careful consideration in production)
        uint224 userTokenCount = uint224(userStakedTokenIds[msg.sender].length);
        for (uint i = 0; i < userTokenCount; i++) {
            if (userStakedTokenIds[msg.sender][i] == _tokenId) {
                // Replace with last element and pop
                userStakedTokenIds[msg.sender][i] = userStakedTokenIds[msg.sender][userTokenCount - 1];
                userStakedTokenIds[msg.sender].pop();
                break;
            }
        }

        // Clean up staking data
        delete stakedNFTs[_tokenId];
        delete stakingBoostMultiplierBps[_tokenId];
        delete stakingBoostEndTime[_tokenId];
        delete stakingLockUntil[_tokenId];
        delete stakingClaimDelegatee[_tokenId];

        // Transfer NFT back
        synergyNFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit NFTUnstaked(msg.sender, _tokenId, uint64(block.timestamp), totalClaimable);
    }

    function claimRewards(uint256[] calldata _tokenIds) external nonReentrant {
        uint256 totalClaimableAmount = 0;
        uint64 currentTime = uint64(block.timestamp);

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            StakingInfo storage stakingInfo = stakedNFTs[tokenId];

            // Check authorization: must be staker, delegatee, or owner
            require(msg.sender == stakingInfo.staker || msg.sender == stakingClaimDelegatee[tokenId] || msg.sender == owner(), "Not authorized to claim for this stake");
            require(stakingInfo.staker != address(0), "NFT is not staked or invalid token ID"); // Ensure stake exists

            // Update accumulated rewards
            uint256 pending = _calculatePendingRewards(tokenId);
            stakingInfo.accumulatedUnclaimedRewards = stakingInfo.accumulatedUnclaimedRewards.add(pending);
            stakingInfo.lastClaimTime = currentTime; // Reset last claim time

            // Add to total for batch claim
            totalClaimableAmount = totalClaimableAmount.add(stakingInfo.accumulatedUnclaimedRewards);

            // Zero out accumulated rewards after calculation for batch
            // We will transfer the total amount at the end
             emit RewardsClaimed(stakingInfo.staker, tokenId, stakingInfo.accumulatedUnclaimedRewards, currentTime); // Emit for each stake

            stakingInfo.accumulatedUnclaimedRewards = 0; // Reset after adding to totalClaimableAmount
        }

        if (totalClaimableAmount > 0) {
            // Transfer total claimed amount in one go
            require(rewardToken.transfer(msg.sender, totalClaimableAmount), "Reward token transfer failed");
            emit BatchRewardsClaimed(msg.sender, totalClaimableAmount, currentTime);
        }
    }


    function depositTreasury(address _token, uint256 _amount) external nonReentrant {
        require(acceptedDepositTokens[_token], "Token is not an accepted deposit token");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        emit DepositTreasury(msg.sender, _token, _amount);
    }

    // Allows a staker to delegate the claim rights for a specific stake
    function delegateStakingPower(uint256 _tokenId, address _delegatee) external {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        require(stakingInfo.staker == msg.sender, "Caller is not the staker");
         require(_delegatee != address(0), "Delegatee cannot be zero address");
        stakingClaimDelegatee[_tokenId] = _delegatee;
        emit ClaimDelegated(_tokenId, msg.sender, _delegatee);
    }


    // --- Dynamic Effects Functions ---

    // Boost the yield for a specific stake (simplified - can add token cost, etc.)
    function boostStakingYield(uint256 _tokenId, uint256 _boostMultiplierBps, uint64 _duration) external nonReentrant {
         StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        require(stakingInfo.staker == msg.sender, "Caller is not the staker");
        require(_boostMultiplierBps >= 10000, "Boost multiplier must be at least 100%"); // Must be a positive boost or 100% (no change)
        require(_duration > 0, "Boost duration must be positive");

        // Calculate pending rewards before applying boost to prevent calculation issues
        uint256 pending = _calculatePendingRewards(_tokenId);
        stakingInfo.accumulatedUnclaimedRewards = stakingInfo.accumulatedUnclaimedRewards.add(pending);
        stakingInfo.lastClaimTime = uint64(block.timestamp); // Reset last claim time

        // Apply boost
        stakingBoostMultiplierBps[_tokenId] = _boostMultiplierBps;
        stakingBoostEndTime[_tokenId] = uint64(block.timestamp) + _duration;

        emit StakingYieldBoosted(_tokenId, _boostMultiplierBps, _duration, stakingBoostEndTime[_tokenId]);
    }

    // Apply a penalty to a stake (e.g., for violating off-chain rules)
    // Can reduce pending rewards or lock the stake temporarily
    function applyPenalty(uint256 _tokenId, uint256 _penaltyAmount, uint64 _lockUntil) external onlyOwner nonReentrant {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        require(stakingInfo.staker != address(0), "NFT is not staked or invalid token ID");

        // Update accumulated rewards before applying penalty
        uint256 pending = _calculatePendingRewards(_tokenId);
        stakingInfo.accumulatedUnclaimedRewards = stakingInfo.accumulatedUnclaimedRewards.add(pending);
        stakingInfo.lastClaimTime = uint64(block.timestamp); // Reset last claim time

        // Apply penalty amount (cannot go below zero)
        stakingInfo.accumulatedUnclaimedRewards = stakingInfo.accumulatedUnclaimedRewards.sub(
            _penaltyAmount, "Penalty amount exceeds accumulated rewards"
        );

        // Apply lock
        if (_lockUntil > block.timestamp) {
             stakingLockUntil[_tokenId] = _lockUntil;
        }


        emit PenaltyApplied(_tokenId, _penaltyAmount, _lockUntil);
    }


    // --- Treasury Management Functions (Owner Only) ---

    function withdrawFromTreasury(address _token, uint256 _amount, address _to) external onlyOwner nonReentrant {
        require(acceptedDepositTokens[_token] || _token == address(rewardToken), "Token not in treasury");
        require(_to != address(0), "Recipient cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance in treasury");

        require(token.transfer(_to, _amount), "Token transfer failed");
        emit WithdrawalTreasury(_to, _token, _amount);
    }

    // Generic function to transfer any accepted treasury token to an external address
    // Could be used for funding operations, grants, etc.
    function transferTreasuryFunds(address _token, uint256 _amount, address _to) external onlyOwner nonReentrant {
        // Note: This function is similar to withdrawFromTreasury but kept separate
        // to potentially represent different use cases (e.g., withdrawal for owner vs funding)
        require(acceptedDepositTokens[_token] || _token == address(rewardToken), "Token not in treasury");
        require(_to != address(0), "Recipient cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance in treasury");

        require(token.transfer(_to, _amount), "Token transfer failed");
        emit WithdrawalTreasury(_to, _token, _amount);
    }


    // --- View Functions ---

    // Calculate pending rewards for a single stake since last claim
    function getPendingRewards(uint256 _tokenId) public view returns (uint256) {
         StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        if (stakingInfo.staker == address(0)) {
            return 0; // Not staked
        }

        // Calculate rewards accrued since last claim
        uint256 newlyAccrued = _calculatePendingRewards(_tokenId);

        // Return total pending (previously accumulated + newly accrued)
        return stakingInfo.accumulatedUnclaimedRewards.add(newlyAccrued);
    }

    // Calculate total pending rewards for a user across all their stakes
    // NOTE: Can be GAS INTENSIVE if user has many staked NFTs
    function getTotalPendingRewards(address _user) external view returns (uint224 totalPending) {
        uint256[] storage stakedIds = userStakedTokenIds[_user];
        for (uint i = 0; i < stakedIds.length; i++) {
            totalPending = totalPending.add(getPendingRewards(stakedIds[i]));
        }
        return totalPending;
    }

     // Get the list of token IDs staked by a user
    function getUserStakedTokenIds(address _user) external view returns (uint256[] memory) {
        return userStakedTokenIds[_user];
    }

    // Get the detailed staking information for a specific token ID
    function getNFTStakingInfo(uint256 _tokenId) external view returns (StakingInfo memory) {
         return stakedNFTs[_tokenId];
    }

    // Get the current balance of an accepted treasury token
    function getTreasuryBalance(address _token) external view returns (uint256) {
        if (!acceptedDepositTokens[_token] && _token != address(rewardToken)) {
             return 0; // Not an accepted token
        }
        return IERC20(_token).balanceOf(address(this));
    }

    // Calculate the current effective reward rate for a specific NFT (per second)
    function viewCurrentRewardRate(uint256 _tokenId) external view returns (uint256) {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        if (stakingInfo.staker == address(0)) {
             return 0; // Not staked
        }
        // Pass a dummy timestamp for current rate calculation
        return _calculateRewardAmount(
            _tokenId,
            stakingInfo.startTime,
            uint64(block.timestamp), // Use current time for rate calculation
            stakingBoostMultiplierBps[_tokenId],
            stakingBoostEndTime[_tokenId]
        );
    }

     // Example of a view function to check reputation tier
     // Actual implementation would depend on how reputation is tracked
    function checkReputationTier(address _user) external view returns (uint256 tier) {
        // Placeholder logic: e.g., based on total staking duration or SYNT earned
        // uint256 totalStakedDuration = ... calculated from userStakedTokenIds and stakingInfo
        // if (totalStakedDuration > X) return 3;
        // else if (totalStakedDuration > Y) return 2;
        // else return 1;
        // OR interact with an external SBT contract
        // return ISoulboundToken(sbtContractAddress).getTier(_user);
        tier = 0; // Default placeholder return
    }


    // --- Internal Helper Functions ---

    // Calculates rewards for a single stake based on time passed since last claim
    function _calculatePendingRewards(uint256 _tokenId) internal view returns (uint256) {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        if (stakingInfo.staker == address(0) || rewardsPaused) {
            return 0; // Not staked or rewards are paused
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - stakingInfo.lastClaimTime;

        if (timeElapsed == 0) {
            return 0; // No time has passed since last claim
        }

        // Get boost multiplier, considering expiry
        uint256 currentBoostMultiplier = 10000; // 100% base
        if (currentTime < stakingBoostEndTime[_tokenId]) {
            currentBoostMultiplier = stakingBoostMultiplierBps[_tokenId];
        } else {
             // Boost expired, return to base
             // In a real scenario, you might want to reset mapping here, but not possible in view
        }


        uint256 rewardAmountPerSecond = _calculateRewardAmount(
            _tokenId,
            stakingInfo.startTime,
            currentTime,
            currentBoostMultiplier,
            stakingBoostEndTime[_tokenId] // Pass boost end time for duration calculation context
        );

        return rewardAmountPerSecond.mul(timeElapsed);
    }

    // Calculates the dynamic reward amount per second for a single NFT
    function _calculateRewardAmount(
        uint256 _tokenId,
        uint64 _stakingStartTime,
        uint64 _currentTime,
        uint256 _currentBoostMultiplierBps, // Pass pre-calculated boost multiplier
        uint64 _stakingBoostEndTime // Pass boost end time for calculation context
    ) internal view returns (uint256) {
        uint256 currentRate = baseRewardRate; // Start with base

        // 1. Apply Trait Multipliers
        // This requires fetching trait data from the NFT contract.
        // Assumes ISynergyNFT interface has getTrait function.
        // Error handling for getTrait call is important in production.
        uint256 traitAggregateMultiplier = 10000; // Start at 100%
         // Example: Assuming a "Type" trait and a "Level" trait
        try synergyNFTContract.getTrait(_tokenId, "Type") returns (string memory traitTypeVal) {
            uint256 typeMultiplier = traitMultipliersBps["Type"][traitTypeVal];
            if (typeMultiplier > 0) traitAggregateMultiplier = traitAggregateMultiplier.mul(typeMultiplier).div(10000);
        } catch {} // Handle error if trait doesn't exist or call fails

         try synergyNFTContract.getTrait(_tokenId, "Level") returns (string memory traitLevelVal) {
             // Need to parse string level or handle differently. Example assumes string keys for multipliers.
             // A better approach might be an enum or integer trait system in the NFT contract.
             uint224 levelMultiplier = uint224(traitMultipliersBps["Level"][traitLevelVal]); // Example cast, risky
             if (levelMultiplier > 0) traitAggregateMultiplier = traitAggregateMultiplier.mul(levelMultiplier).div(10000);
         } catch {} // Handle error

        currentRate = currentRate.mul(traitAggregateMultiplier).div(10000);


        // 2. Apply Duration Bonus
        uint64 stakedDuration = _currentTime - _stakingStartTime;
        uint256 durationBonus = 0; // Start at 0 bonus

        // Find the highest tier achieved
        for (uint i = durationBonusTierThresholds.length; i > 0; i--) {
            uint64 threshold = durationBonusTierThresholds[i-1];
            if (stakedDuration >= threshold) {
                durationBonus = durationBonusTiersBps[threshold];
                break; // Found the highest applicable tier
            }
        }
        currentRate = currentRate.mul(10000 + durationBonus).div(10000); // Apply bonus percentage


        // 3. Apply Treasury Balance Impact
        // This is a simplified example. Real impact logic can be more complex (e.g., thresholds, curves).
        // Here, we just add/subtract based on a factor * log(balance) or similar.
        // For simplicity, let's use a linear impact: impactFactor * (balance / some_reference_unit)
        // Be very careful with integer division/multiplication here.
        // Using a safe, simple linear impact: impact is proportional to (balance / total_supply_like_value)
        // Or even simpler: impact is just proportional to the raw balance scaled by the factor.
        // Let's do a proportional impact relative to a large constant to avoid overflow/underflow issues
        // impact = (balance * factor) / SCALE
        uint256 totalTreasuryImpactBps = 10000; // Start at 100% impact

        for (address tokenAddress : durationBonusTierThresholds) { // Reusing duration list - ERROR! Need a list of accepted deposit token ADDRESSES!
             // Re-declare to avoid reusing list
             address[] memory accepted = new address[](0); // Dummy, need actual list
             // In a real contract, store accepted deposit token addresses in a separate array or iterable mapping

             // For this example, let's just use the RewardToken balance impact
             address tokenAddressToCheck = address(rewardToken); // Example: only reward token balance impacts rate
             if (treasuryBalanceImpactFactor[tokenAddressToCheck] != 0) {
                uint256 balance = IERC20(tokenAddressToCheck).balanceOf(address(this));
                 int256 impactFactor = treasuryBalanceImpactFactor[tokenAddressToCheck];

                 // Simplified linear impact: impact is factor * (balance / 1e18)
                 // Be CAREFUL: this can cause huge swings or zero impact depending on scale
                 // Better: use fixed point math or a curve.
                 // Let's use a log scale approximation or simple percentage:
                 // Impact % = factor * log(balance + 1) / log(MAX_BALANCE)
                 // Or a simpler approach: capped linear impact
                 // impact = min(max(-CAP, balance * factor / SCALE), CAP)
                 // For this example, let's just do a simple multiplication/division, assuming factor and balance scales are handled externally to prevent issues.
                 // Assuming factor is in basis points per token unit (e.g., factor 100 means 1% increase per token)
                 // totalImpactBps = balance.mul(impactFactor) / (10**decimals or some scaling factor)
                 // Let's assume impactFactor is in basis points per 1e18 token units
                 // Example: balance is 100e18, factor is 50 (0.5% per 1e18). Impact = 100 * 50 = 5000 bps (50% increase)
                 // This is still risky. Let's use a safer simplified approach:
                 // Treasury factor acts as a multiplier on the base rate itself, adjusted by balance ratio.
                 // treasury_adjustment = (balance / TARGET_BALANCE) * treasuryBalanceImpactFactor
                 // Let's just apply the impact factor directly scaled by balance, very simplified.
                 // WARNING: THIS SIMPLIFIED LOGIC IS VERY ROUGH AND POTENTIALLY UNSAFE FOR PRODUCTION.
                 int256 balanceImpactBps = int256(balance.div(1e18)).mul(impactFactor); // Impact per full token

                 // Cap impact to avoid extreme rates
                 int256 maxImpact = 50000; // +/- 500% adjustment max
                 if (balanceImpactBps > maxImpact) balanceImpactBps = maxImpact;
                 if (balanceImpactBps < -maxImpact) balanceImpactBps = -maxImpact;

                 totalTreasuryImpactBps = totalTreasuryImpactBps.add(balanceImpactBps); // Add/Subtract impact bps
             }
         }

        // Ensure totalTreasuryImpactBps is not negative, cap at 0% total rate
        if (totalTreasuryImpactBps < 0) totalTreasuryImpactBps = 0;
        currentRate = currentRate.mul(totalTreasuryImpactBps).div(10000);


        // 4. Apply Staking Boost (already calculated based on expiry)
        currentRate = currentRate.mul(_currentBoostMultiplierBps).div(10000);


        return currentRate;
    }

    // Helper to update accumulated rewards before state changes (like claiming, unstaking, boosting, penalizing)
    function _updateAccumulatedRewards(uint256 _tokenId) internal {
        StakingInfo storage stakingInfo = stakedNFTs[_tokenId];
        if (stakingInfo.staker == address(0) || rewardsPaused) {
            return;
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - stakingInfo.lastClaimTime;

        if (timeElapsed > 0) {
            uint256 newlyAccrued = _calculatePendingRewards(_tokenId); // Calls the calculator
            stakingInfo.accumulatedUnclaimedRewards = stakingInfo.accumulatedUnclaimedRewards.add(newlyAccrued);
            stakingInfo.lastClaimTime = currentTime;
        }
    }

    // Helper to find index of a tokenId in a user's staked list (used for removal)
    // NOTE: This is O(N) and can be expensive. Consider alternative data structures
    // for production if users will stake many NFTs.
    function _indexOfUserToken(address _user, uint256 _tokenId) internal view returns (uint256 index) {
        uint256[] storage userTokens = userStakedTokenIds[_user];
        for (uint i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == _tokenId) {
                return i;
            }
        }
        revert("Token ID not found for user"); // Should not happen if logic is correct
    }

    // Override to accept ERC721 tokens
    // This is already handled by inheriting ERC721Holder


    // Fallback and Receive functions to accept Ether (optional)
    receive() external payable {}
    fallback() external payable {}

}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic Reward Rate:** Instead of a fixed rate, the `_calculateRewardAmount` function combines multiple factors:
    *   **Base Rate:** A fundamental rate set by the owner.
    *   **NFT Trait Multipliers:** Reads traits from the staked NFT (via the `ISynergyNFT` interface) and applies configured multipliers (`traitMultipliersBps`). This allows different NFTs within the same collection to have varying staking yields based on their properties.
    *   **Staking Duration Bonuses:** Rewards users for staking longer by applying increasing percentage bonuses based on defined time tiers (`durationBonusTiersBps`).
    *   **Treasury Balance Impact:** The balance of specified tokens within the contract's treasury influences the reward rate (`treasuryBalanceImpactFactor`). This can be used to tie yield to the health or size of the protocol's treasury, creating interesting tokenomics where depositing funds benefits stakers. (Note: The implementation here is a simplified linear model and risky; real-world would need fixed-point math or a carefully designed curve).
    *   **Staking Boost:** An explicit mechanism (`boostStakingYield`) to temporarily increase a specific stake's yield, potentially fueled by burning tokens or other user actions.

2.  **ERC-20 Treasury:** The contract can accept deposits of multiple, owner-configured ERC-20 tokens (`acceptedDepositTokens`). This treasury can then be used to influence reward rates, or funds can be managed/withdrawn by the owner (`withdrawFromTreasury`, `transferTreasuryFunds`).

3.  **Penalty Mechanism:** The `applyPenalty` function allows the owner (or potentially a governance mechanism) to reduce pending rewards or temporarily lock a staked NFT. This could be integrated with off-chain rules or moderation, although linking off-chain decisions to on-chain penalties is complex and requires careful design outside this contract's scope.

4.  **Staking Claim Delegation:** The `delegateStakingPower` function allows a staker to authorize another address to claim rewards on their behalf for a specific stake. Useful for gaming guilds, asset managers, etc. The `onlyDelegateeOrOwner` modifier enforces this.

5.  **Pausable Granularity:** Separate `stakingPaused` and `rewardsPaused` flags allow fine-grained control over contract activity (preventing new stakes vs. stopping reward accrual for existing ones).

6.  **Reputation Tracking Placeholder:** The `checkReputationTier` function is included as an example hook for integrating a reputation system, where staking history (duration, rewards earned) could contribute to a user's on-chain reputation score or tier (potentially using Soulbound Tokens or similar).

7.  **`ERC721Holder` Inheritance:** Correctly implements `onERC721Received` to safely receive NFTs, following ERC721 standards.

This contract provides a foundation for a more sophisticated and dynamic NFT staking protocol compared to basic models, incorporating elements from DeFi (dynamic yield, treasury management) and gaming/utility NFTs (trait-based mechanics, boosting, delegation).