Okay, let's design a smart contract that combines dynamic NFTs with a multi-layered yield farming mechanism.

The core idea:
1.  Users stake an ERC20 token (StakeToken).
2.  Based on their stake amount and duration, they earn "Yield Points".
3.  Users can redeem these Yield Points to *mint* a unique ERC721 token (YieldNFT).
4.  The YieldNFT is *dynamic*. Its attributes (like 'Level' or 'Boost') improve over time *while it is held within the contract* (either unclaimed after earning or actively staked).
5.  Users can then stake these dynamic YieldNFTs to earn a different ERC20 token (RewardToken).
6.  The yield rate for staking NFTs is influenced by the dynamic attributes of the staked NFTs (e.g., higher level/boost = higher reward).

This incorporates yield farming, dynamic NFTs, points systems, and multi-asset interaction, aiming for something beyond standard open-source examples.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Contract Outline ---
// 1. Interfaces for ERC20 tokens.
// 2. Contract Definition inheriting ERC721 and Ownable.
// 3. State Variables:
//    - Token addresses (StakeToken, RewardToken).
//    - Farming parameters (point emission rates, NFT mint cost, reward emission rates).
//    - User Stake Data (amount, last update time, yield points).
//    - NFT Staking Data (staked status, last stake time, accrued reward debt per NFT).
//    - Dynamic NFT Data (mint time, accrued time per NFT).
//    - Paused states.
//    - Total counters (staked stake token, staked NFTs).
// 4. Events for key actions.
// 5. Modifiers (paused checks).
// 6. Constructor.
// 7. Admin Functions (setting parameters, emergency withdrawal, pausing).
// 8. Internal Helpers:
//    - Point calculation for StakeToken staking.
//    - Reward calculation for NFT staking.
//    - Dynamic NFT attribute calculation (level, boost, accrued time).
//    - Updating user/NFT states.
// 9. Stake Token Farming Functions (stake, unstake, claim points, views).
// 10. Yield NFT Management Functions (mint, tokenURI, attribute views).
// 11. Yield NFT Staking Functions (stake NFTs, unstake NFTs, claim rewards, views).

// --- Function Summary ---
// Constructor: Sets initial token addresses and admin parameters.
// setStakeToken(IERC20 _stakeToken): Admin function to set the StakeToken address.
// setRewardToken(IERC20 _rewardToken): Admin function to set the RewardToken address.
// setYieldPointsEmissionRate(uint256 _rate): Admin function to set the points earned per StakeToken per second.
// setYieldNFTMintCost(uint256 _cost): Admin function to set the YieldPoints required to mint an NFT.
// setRewardTokenEmissionRate(uint256 _rate): Admin function to set the RewardToken earned per boosted NFT point per second.
// withdrawExcessTokens(address _token, uint256 _amount): Admin function to recover mistakenly sent tokens.
// pauseStaking(): Admin function to pause StakeToken staking/unstaking.
// unpauseStaking(): Admin function to unpause StakeToken staking/unstaking.
// pauseNFTStaking(): Admin function to pause YieldNFT staking/unstaking.
// unpauseNFTStaking(): Admin function to unpause YieldNFT staking/unstaking.
// stake(uint256 _amount): Users deposit StakeToken to earn YieldPoints. Updates user's points and stake amount.
// unstake(uint256 _amount): Users withdraw StakeToken. Claims accrued points before unstaking.
// claimYieldPoints(): Users claim accrued YieldPoints.
// pendingYieldPoints(address _user): View function to see how many YieldPoints a user can claim.
// getUserStake(address _user): View function to see a user's current StakeToken amount.
// mintYieldNFT(): Users spend YieldPoints to mint a new dynamic YieldNFT. Sets mint timestamp.
// tokenURI(uint256 tokenId): ERC721 standard function. Generates dynamic metadata based on current NFT state (accrued time, level, boost).
// getNFTAttributes(uint256 tokenId): View function to get the current dynamic attributes (accruedTime, level, passiveBoostRate) of an NFT.
// getAccruedTime(uint256 tokenId): View function for an NFT's total accrued time in the contract.
// stakeYieldNFT(uint256[] calldata tokenIds): Users stake their YieldNFTs to earn RewardToken. Updates NFT state and user's reward debt. Updates NFT's accrued time.
// unstakeYieldNFT(uint256[] calldata tokenIds): Users withdraw their staked YieldNFTs. Claims accrued rewards before unstaking. Updates NFT state and user's accrued time.
// claimRewardTokens(): Users claim accrued RewardTokens from staked NFTs. Updates reward debt. Updates accrued time for staked NFTs.
// pendingRewardTokens(address _user): View function to see how many RewardTokens a user can claim.
// getUserStakedNFTs(address _user): View function to list NFTs a user has staked.
// getNFTStakeStatus(uint256 tokenId): View function to check if an NFT is staked and by which user.
// getNFTMintCost(): View function for the current YieldNFT mint cost.
// getYieldPointsEmissionRate(): View function for the current YieldPoints emission rate.
// getRewardTokenEmissionRate(): View function for the current RewardToken emission rate.
// getTotalStake(): View function for the total StakeToken staked in the contract.
// getTotalStakedNFTs(): View function for the total YieldNFTs staked in the contract.
// calculateNFTLevel(uint256 _accruedTime): Internal/external helper to determine NFT level based on accrued time.
// calculatePassiveBoostRate(uint256 _level): Internal/external helper to determine boost rate based on NFT level.
// updateYieldPoints(address _user): Internal helper to calculate and add pending yield points for a user.
// updateRewardTokens(address _user): Internal helper to calculate and add pending reward tokens for a user based on their staked NFTs.
// updateNFTAccruedTime(uint256 tokenId): Internal helper to update an NFT's accrued time based on how long it's been in a timed state within the contract.

contract DynamicNFTYieldFarm is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    // Tokens
    IERC20 public stakeToken;
    IERC20 public rewardToken;

    // Farming Parameters
    uint256 public yieldPointsEmissionRate; // Points per StakeToken per second (e.g., 1e12 for 1 point per token per second)
    uint256 public yieldNFTMintCost; // YieldPoints required to mint one NFT (e.g., 100 ether)
    uint256 public rewardTokenEmissionRate; // RewardToken per total boosted NFT point per second (e.g., 1e16 for 0.01 token per boosted point per second)

    // Stake Token Farming State
    mapping(address => uint256) public userStake; // User's current staked StakeToken amount
    mapping(address => uint26) private lastStakeUpdateTime; // Last timestamp user's stake state was updated
    mapping(address => uint256) public userYieldPoints; // User's claimed YieldPoints

    // Yield NFT State (as ERC721 is inherited, owner mapping is built-in)
    uint256 private _nextTokenId; // Counter for minting new NFTs

    // Dynamic NFT State
    mapping(uint256 => uint64) public nftMintTimestamp; // Timestamp when NFT was minted
    mapping(uint256 => uint256) public nftAccruedTime; // Total time (seconds) NFT has spent in a timed state (staked or pending claim in contract)
    mapping(uint256 => uint64) private nftLastTimedStateUpdate; // Last timestamp NFT state was updated (used for accrued time calculation)

    // Yield NFT Staking State
    mapping(uint256 => address) private nftStakedBy; // Address of user who staked this NFT (address(0) if not staked)
    mapping(address => uint256[]) private userStakedNFTsList; // List of NFT tokenIds staked by a user (optimization might be needed for large numbers)
    mapping(uint256 => uint256) private nftRewardDebt; // User's accumulated reward debt for this specific staked NFT based on global state changes
    mapping(address => uint256) public userPendingRewardTokens; // User's total pending reward tokens from all their staked NFTs

    // Global NFT Staking State
    uint256 public totalBoostedStakedNFTPoints; // Sum of boosted points of all currently staked NFTs
    uint64 private lastRewardUpdateTime; // Last timestamp global reward state was updated

    // Paused State
    bool public stakingPaused;
    bool public nftStakingPaused;

    // Global Totals (for view functions)
    uint256 public totalStakedStakeToken;
    uint256 public totalStakedYieldNFTs;

    // --- Events ---
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event YieldPointsClaimed(address indexed user, uint256 amount);
    event NFTMinted(address indexed user, uint256 indexed tokenId);
    event NFTStaked(address indexed user, uint256 indexed tokenId);
    event NFTUnstaked(address indexed user, uint256 indexed tokenId);
    event RewardTokensClaimed(address indexed user, uint256 amount);
    event YieldPointsEmissionRateUpdated(uint256 newRate);
    event YieldNFTMintCostUpdated(uint256 newCost);
    event RewardTokenEmissionRateUpdated(uint256 newRate);
    event StakingPaused(bool paused);
    event NFTStakingPaused(bool paused);

    // --- Modifiers ---
    modifier whenStakingNotPaused() {
        require(!stakingPaused, "Staking is paused");
        _;
    }

    modifier whenNFTStakingNotPaused() {
        require(!nftStakingPaused, "NFT staking is paused");
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _yieldPointsEmissionRate,
        uint256 _yieldNFTMintCost,
        uint256 _rewardTokenEmissionRate,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        yieldPointsEmissionRate = _yieldPointsEmissionRate;
        yieldNFTMintCost = _yieldNFTMintCost;
        rewardTokenEmissionRate = _rewardTokenEmissionRate;
        _nextTokenId = 0;
        lastRewardUpdateTime = uint64(block.timestamp);
    }

    // --- Admin Functions ---

    function setStakeToken(IERC20 _stakeToken) external onlyOwner {
        stakeToken = _stakeToken;
    }

    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function setYieldPointsEmissionRate(uint256 _rate) external onlyOwner {
        yieldPointsEmissionRate = _rate;
        emit YieldPointsEmissionRateUpdated(_rate);
    }

    function setYieldNFTMintCost(uint256 _cost) external onlyOwner {
        yieldNFTMintCost = _cost;
        emit YieldNFTMintCostUpdated(_cost);
    }

    function setRewardTokenEmissionRate(uint256 _rate) external onlyOwner {
        rewardTokenEmissionRate = _rate;
        emit RewardTokenEmissionRateUpdated(_rate);
        // Note: Changing rate might require updating global reward state,
        // but simplified here to just affect future accrual.
        // A more complex system would update totalBoostedStakedNFTPoints and lastRewardUpdateTime properly.
    }

    function withdrawExcessTokens(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }

    function pauseStaking() external onlyOwner {
        stakingPaused = true;
        emit StakingPaused(true);
    }

    function unpauseStaking() external onlyOwner {
        stakingPaused = false;
        emit StakingPaused(false);
    }

    function pauseNFTStaking() external onlyOwner {
        nftStakingPaused = true;
        emit NFTStakingPaused(true);
    }

    function unpauseNFTStaking() external onlyOwner {
        nftStakingPaused = false;
        emit NFTStakingPaused(false);
    }

    // --- Internal Helpers ---

    // Calculates and adds pending points for a user based on time staked
    function updateYieldPoints(address _user) internal {
        uint256 staked = userStake[_user];
        uint256 lastUpdate = lastStakeUpdateTime[_user];
        uint256 currentTime = block.timestamp;

        if (staked > 0 && currentTime > lastUpdate) {
            uint256 timeElapsed = currentTime.sub(lastUpdate);
            uint256 pointsEarned = staked.mul(timeElapsed).mul(yieldPointsEmissionRate) / 1e18; // Adjust division based on point rate precision
            userYieldPoints[_user] = userYieldPoints[_user].add(pointsEarned);
        }
        lastStakeUpdateTime[_user] = uint26(currentTime);
    }

    // Calculates and adds pending reward tokens for a user based on their staked NFTs
    function updateRewardTokens(address _user) internal {
        uint256 currentRewardPerBoostedPoint = 0;
        uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime);

        if (totalBoostedStakedNFTPoints > 0 && timeElapsed > 0) {
             // Total reward tokens emitted since last update
            uint256 totalEmission = totalBoostedStakedNFTPoints.mul(timeElapsed).mul(rewardTokenEmissionRate) / 1e18; // Adjust precision
             // Reward tokens per boosted point
            currentRewardPerBoostedPoint = totalEmission.div(totalBoostedStakedNFTPoints);
        }

        uint256 userPending = userPendingRewardTokens[_user];

        // Iterate through user's staked NFTs to calculate and update rewards
        // NOTE: Iterating arrays is potentially gas-intensive for large NFT counts.
        // A more advanced structure (like a linked list or mapping per NFT) would be better for scale.
        uint224 totalUserBoostedPoints = 0;
        for (uint i = 0; i < userStakedNFTsList[_user].length; i++) {
            uint256 tokenId = userStakedNFTsList[_user][i];
            if (nftStakedBy[tokenId] == _user) { // Double check in case array is not cleaned perfectly
                // Calculate rewards earned by this NFT since last update
                uint256 boostedPoints = calculatePassiveBoostRate(calculateNFTLevel(getNFTAttributes(tokenId).accruedTime)).mul(1e18) / 1e18; // Normalize boost rate
                uint256 earned = boostedPoints.mul(currentRewardPerBoostedPoint); // Tokens earned by this specific NFT

                // Add to user's pending, subtract from NFT's debt
                userPending = userPending.add(earned);
                // nftRewardDebt[tokenId] should ideally track accumulated reward *per point* to avoid per-NFT iteration here,
                // but for simplicity, let's track total debt against the NFT's earned amount.
                // A proper system would track `(accumulated_reward_per_point_global) - (nft_stake_time_snapshot_reward_per_point)`
                // Let's simplify: calculate total earned since last update and add to user's pending.
            }
        }

        userPendingRewardTokens[_user] = userPending;
        lastRewardUpdateTime = uint64(block.timestamp);
    }

    // Updates the internal accrued time state for a given NFT
    function updateNFTAccruedTime(uint256 tokenId) internal {
         // Only update if the NFT is in a timed state (currently staked)
        if (nftStakedBy[tokenId] != address(0)) {
            uint256 lastUpdate = nftLastTimedStateUpdate[tokenId];
            uint256 currentTime = block.timestamp;
            if (currentTime > lastUpdate) {
                nftAccruedTime[tokenId] = nftAccruedTime[tokenId].add(currentTime.sub(lastUpdate));
                nftLastTimedStateUpdate[tokenId] = uint64(currentTime);
            }
        } else if (nftLastTimedStateUpdate[tokenId] > 0) {
            // If not staked but last update time is set, clear it
            // This handles cases where the NFT leaves the timed state (e.g., unstaked)
            nftLastTimedStateUpdate[tokenId] = 0;
        }
         // Note: NFTs pending claim after earning points don't accrue time in this model.
         // Accrual only happens while actively staked in the NFT staking pool.
    }


    // Maps accrued time to a level (example tiers)
    function calculateNFTLevel(uint256 _accruedTime) public pure returns (uint8) {
        if (_accruedTime >= 365 days) return 5; // Level 5: >= 1 year
        if (_accruedTime >= 180 days) return 4; // Level 4: >= 6 months
        if (_accruedTime >= 90 days) return 3;  // Level 3: >= 3 months
        if (_accruedTime >= 30 days) return 2;  // Level 2: >= 1 month
        if (_accruedTime >= 7 days) return 1;   // Level 1: >= 1 week
        return 0; // Level 0: < 1 week
    }

    // Maps level to a passive boost rate (example percentages, scaled by 1e18)
    function calculatePassiveBoostRate(uint8 _level) public pure returns (uint256) {
        // Boost is a multiplier, e.g., 1.05 for 5% boost = 1.05e18
        if (_level == 5) return 2_00e18; // 2.0x boost
        if (_level == 4) return 1_50e18; // 1.5x boost
        if (_level == 3) return 1_25e18; // 1.25x boost
        if (_level == 2) return 1_10e18; // 1.1x boost
        if (_level == 1) return 1_05e18; // 1.05x boost
        return 1_00e18; // 1.0x boost (no boost)
    }

     struct NFTAttributes {
        uint256 tokenId;
        uint64 mintTimestamp;
        uint256 accruedTime;
        uint8 level;
        uint256 passiveBoostRate; // Scaled by 1e18
        address currentOwner;
        address stakedBy; // address(0) if not staked
    }

    // Internal/External helper to get current dynamic attributes
    function getNFTAttributes(uint256 tokenId) public view returns (NFTAttributes memory) {
        require(_exists(tokenId), "NFT does not exist");

        uint256 currentAccruedTime = nftAccruedTime[tokenId];
        // If currently staked, add time since last update
        if (nftStakedBy[tokenId] != address(0)) {
            currentAccruedTime = currentAccruedTime.add(block.timestamp.sub(nftLastTimedStateUpdate[tokenId]));
        }

        uint8 level = calculateNFTLevel(currentAccruedTime);
        uint256 boostRate = calculatePassiveBoostRate(level);

        return NFTAttributes({
            tokenId: tokenId,
            mintTimestamp: nftMintTimestamp[tokenId],
            accruedTime: currentAccruedTime,
            level: level,
            passiveBoostRate: boostRate,
            currentOwner: ownerOf(tokenId),
            stakedBy: nftStakedBy[tokenId]
        });
    }

    // --- Stake Token Farming Functions ---

    function stake(uint256 _amount) external whenStakingNotPaused {
        require(_amount > 0, "Amount must be > 0");
        require(stakeToken.balanceOf(msg.sender) >= _amount, "Insufficient StakeToken balance");
        require(stakeToken.allowance(msg.sender, address(this)) >= _amount, "Insufficient StakeToken allowance");

        updateYieldPoints(msg.sender); // Update points before changing stake

        stakeToken.transferFrom(msg.sender, address(this), _amount);
        userStake[msg.sender] = userStake[msg.sender].add(_amount);
        totalStakedStakeToken = totalStakedStakeToken.add(_amount);

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external whenStakingNotPaused {
        require(_amount > 0, "Amount must be > 0");
        require(userStake[msg.sender] >= _amount, "Insufficient staked amount");

        updateYieldPoints(msg.sender); // Claim pending points before unstake

        userStake[msg.sender] = userStake[msg.sender].sub(_amount);
        totalStakedStakeToken = totalStakedStakeToken.sub(_amount);
        stakeToken.transfer(msg.sender, _amount);

        // If user's stake becomes 0, reset last update time to prevent stale point calculation
        if (userStake[msg.sender] == 0) {
             lastStakeUpdateTime[msg.sender] = uint26(block.timestamp); // Set to current time or 0
        }

        emit Unstake(msg.sender, _amount);
    }

    function claimYieldPoints() external {
        updateYieldPoints(msg.sender); // Update points before claiming
        uint256 amount = userYieldPoints[msg.sender];
        require(amount > 0, "No points to claim");

        userYieldPoints[msg.sender] = 0;
        // Points are not a transferable token in this model, they are internal balance

        emit YieldPointsClaimed(msg.sender, amount);
    }

    function pendingYieldPoints(address _user) public view returns (uint256) {
        uint256 staked = userStake[_user];
        uint256 lastUpdate = lastStakeUpdateTime[_user];
        uint256 currentTime = block.timestamp;
        uint256 pointsEarned = userYieldPoints[_user]; // Already accumulated points

        if (staked > 0 && currentTime > lastUpdate) {
            uint256 timeElapsed = currentTime.sub(lastUpdate);
            pointsEarned = pointsEarned.add(staked.mul(timeElapsed).mul(yieldPointsEmissionRate) / 1e18); // Add pending points
        }
        return pointsEarned;
    }

    function getUserStake(address _user) external view returns (uint256) {
        return userStake[_user];
    }

    // --- Yield NFT Management Functions ---

    function mintYieldNFT() external {
        require(userYieldPoints[msg.sender] >= yieldNFTMintCost, "Insufficient YieldPoints");

        updateYieldPoints(msg.sender); // Update points before spending

        userYieldPoints[msg.sender] = userYieldPoints[msg.sender].sub(yieldNFTMintCost);

        uint256 newItemId = _nextTokenId++;
        _safeMint(msg.sender, newItemId);

        nftMintTimestamp[newItemId] = uint64(block.timestamp);
        nftAccruedTime[newItemId] = 0; // Starts with 0 accrued time
        nftLastTimedStateUpdate[newItemId] = 0; // Not in a timed state yet

        emit NFTMinted(msg.sender, newItemId);
    }

    // Dynamic tokenURI function
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        NFTAttributes memory attrs = getNFTAttributes(tokenId);

        string memory base = "data:application/json;base64,";
        string memory json = string(abi.encodePacked(
            '{"name": "Dynamic Yield NFT #', tokenId.toString(), '",',
            '"description": "A dynamic NFT representing yield farm participation. Its level and boost grow over time while staked.",',
            '"attributes": [',
                '{"trait_type": "Token ID", "value": ', tokenId.toString(), '},',
                '{"trait_type": "Mint Timestamp", "value": ', attrs.mintTimestamp.toString(), '},',
                '{"trait_type": "Accrued Time (seconds)", "value": ', attrs.accruedTime.toString(), '},',
                '{"trait_type": "Level", "value": ', attrs.level.toString(), '},',
                '{"trait_type": "Passive Boost Rate (x100)", "value": ', (attrs.passiveBoostRate.mul(100)/1e18).toString(), '},', // Display as percentage
                '{"trait_type": "Staked", "value": ', (attrs.stakedBy != address(0) ? "true" : "false"), '}'
            ']}'
        ));

        return string(abi.encodePacked(base, Base64.encode(bytes(json))));
    }

    function getAccruedTime(uint256 tokenId) external view returns (uint256) {
        return getNFTAttributes(tokenId).accruedTime;
    }

    // --- Yield NFT Staking Functions ---

    function stakeYieldNFT(uint256[] calldata tokenIds) external whenNFTStakingNotPaused {
        require(tokenIds.length > 0, "No tokenIds provided");

        updateRewardTokens(msg.sender); // Update user's pending rewards before staking

        uint256 totalBoostPointsChange = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not owner of token");
            require(nftStakedBy[tokenId] == address(0), "NFT already staked");

            // Update accrued time BEFORE staking
            updateNFTAccruedTime(tokenId);

            // Transfer NFT to the contract
            _transfer(msg.sender, address(this), tokenId);

            // Update state
            nftStakedBy[tokenId] = msg.sender;
            userStakedNFTsList[msg.sender].push(tokenId); // Add to user's staked list (potential gas issue)
            nftLastTimedStateUpdate[tokenId] = uint64(block.timestamp); // Start timing for accrued time while staked
            nftRewardDebt[tokenId] = 0; // Reset debt (simple model - could be complex with point tracking)

            // Calculate boost points gained from this NFT
            uint256 boostedPoints = calculatePassiveBoostRate(calculateNFTLevel(nftAccruedTime[tokenId])); // Use updated accrued time
            totalBoostPointsChange = totalBoostPointsChange.add(boostedPoints);

            emit NFTStaked(msg.sender, tokenId);
        }

         // Update global boosted points after processing all NFTs
         totalBoostedStakedNFTPoints = totalBoostedStakedNFTPoints.add(totalBoostPointsChange);
         // Reset global reward update time to account for pool change
         lastRewardUpdateTime = uint64(block.timestamp); // This effectively re-bases reward calculation

        totalStakedYieldNFTs = totalStakedYieldNFTs.add(tokenIds.length);
    }

    function unstakeYieldNFT(uint256[] calldata tokenIds) external whenNFTStakingNotPaused {
         require(tokenIds.length > 0, "No tokenIds provided");

         // Update user's pending rewards before unstaking
         updateRewardTokens(msg.sender);

         uint256 totalBoostPointsChange = 0;
         uint256[] memory toRemoveFromList = new uint256[](tokenIds.length); // Track indices to remove from list

         for (uint i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
             require(nftStakedBy[tokenId] == msg.sender, "NFT not staked by user");

             // Update accrued time AFTER staking duration
             updateNFTAccruedTime(tokenId); // This adds time since last update

             // Remove NFT from staked state and lists
             nftStakedBy[tokenId] = address(0);
             // Find and mark for removal from userStakedNFTsList (expensive)
             bool found = false;
             for(uint j = 0; j < userStakedNFTsList[msg.sender].length; j++) {
                 if (userStakedNFTsList[msg.sender][j] == tokenId) {
                     toRemoveFromList[i] = j; // Store the index to remove
                     found = true;
                     break;
                 }
             }
             require(found, "NFT not found in staked list"); // Should not happen if nftStakedBy is correct

             nftLastTimedStateUpdate[tokenId] = 0; // Reset timed state update
             nftRewardDebt[tokenId] = 0; // Clear debt (simple model)

             // Calculate boost points removed from global pool
             uint256 boostedPoints = calculatePassiveBoostRate(calculateNFTLevel(nftAccruedTime[tokenId])); // Use final accrued time
             totalBoostPointsChange = totalBoostPointsChange.add(boostedPoints);

             // Transfer NFT back to the user
             _transfer(address(this), msg.sender, tokenId);

             emit NFTUnstaked(msg.sender, tokenId);
         }

         // Efficiently remove elements from userStakedNFTsList (swap-and-pop)
         // Iterate in reverse order of indices to remove to avoid shifting issues
         // This requires the `toRemoveFromList` array to be sorted descending.
         // Sorting is complex on-chain. A simpler approach is to just mark or rebuild.
         // Rebuilding is also expensive. Let's use a basic O(n*m) removal for now,
         // acknowledge the gas cost, and state that a better data structure is needed for scale.
         for (uint i = 0; i < tokenIds.length; i++) {
              uint256 tokenId = tokenIds[i];
              for(uint j = 0; j < userStakedNFTsList[msg.sender].length; j++) {
                 if (userStakedNFTsList[msg.sender][j] == tokenId) {
                     // Swap with last element and pop
                     if (j < userStakedNFTsList[msg.sender].length - 1) {
                         userStakedNFTsList[msg.sender][j] = userStakedNFTsList[msg.sender][userStakedNFTsList[msg.sender].length - 1];
                     }
                     userStakedNFTsList[msg.sender].pop();
                     break; // Found and removed
                 }
              }
         }


         // Update global boosted points
         totalBoostedStakedNFTPoints = totalBoostedStakedNFTPoints.sub(totalBoostPointsChange);
         // Reset global reward update time
         lastRewardUpdateTime = uint64(block.timestamp);

         totalStakedYieldNFTs = totalStakedYieldNFTs.sub(tokenIds.length);
    }

    function claimRewardTokens() external {
        updateRewardTokens(msg.sender); // Calculate and add pending rewards
        uint256 amount = userPendingRewardTokens[msg.sender];
        require(amount > 0, "No rewards to claim");

        userPendingRewardTokens[msg.sender] = 0;

        // Transfer reward tokens
        require(rewardToken.transfer(msg.sender, amount), "Reward token transfer failed");

        // Update accrued time for NFTs that *remain staked* after this claim
        // This is crucial because the reward calculation just advanced the clock for them.
        // This loop is also potentially expensive.
         for (uint i = 0; i < userStakedNFTsList[msg.sender].length; i++) {
            uint256 tokenId = userStakedNFTsList[msg.sender][i];
            if (nftStakedBy[tokenId] == msg.sender) {
                 updateNFTAccruedTime(tokenId); // Update based on time elapsed during reward accrual
            }
         }
         // Re-base the global reward timer as user's rewards are paid out (might need adjustment if global rate changes often)
         lastRewardUpdateTime = uint64(block.timestamp);


        emit RewardTokensClaimed(msg.sender, amount);
    }

    function pendingRewardTokens(address _user) public view returns (uint256) {
         uint256 currentRewardPerBoostedPoint = 0;
         uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime);

         if (totalBoostedStakedNFTPoints > 0 && timeElapsed > 0) {
            uint256 totalEmission = totalBoostedStakedNFTPoints.mul(timeElapsed).mul(rewardTokenEmissionRate) / 1e18;
            currentRewardPerBoostedPoint = totalEmission.div(totalBoostedStakedNFTPoints);
         }

         uint256 userPending = userPendingRewardTokens[_user];

         // Add rewards accrued by currently staked NFTs since last global update
         for (uint i = 0; i < userStakedNFTsList[_user].length; i++) {
            uint256 tokenId = userStakedNFTsList[_user][i];
            if (nftStakedBy[tokenId] == _user) {
                 // Calculate boost points for this NFT *at this moment*
                 // Need to calculate its theoretical accrued time IF we were to update now
                 uint256 theoreticalAccruedTime = nftAccruedTime[tokenId];
                 if (nftLastTimedStateUpdate[tokenId] > 0) { // If currently in a timed state
                      theoreticalAccruedTime = theoreticalAccruedTime.add(block.timestamp.sub(nftLastTimedStateUpdate[tokenId]));
                 }
                 uint256 boostedPoints = calculatePassiveBoostRate(calculateNFTLevel(theoreticalAccruedTime));
                 uint256 earned = boostedPoints.mul(currentRewardPerBoostedPoint);
                 userPending = userPending.add(earned);
            }
         }
        return userPending;
    }

    function getUserStakedNFTs(address _user) external view returns (uint256[] memory) {
         // NOTE: Returns the internal list. Might contain remnants if unstake cleanup fails.
         // A more robust solution would iterate and verify nftStakedBy.
         uint256[] memory stakedNFTs = new uint256[](userStakedNFTsList[_user].length);
         uint256 count = 0;
         for(uint i = 0; i < userStakedNFTsList[_user].length; i++) {
              uint256 tokenId = userStakedNFTsList[_user][i];
              if (nftStakedBy[tokenId] == _user) {
                  stakedNFTs[count] = tokenId;
                  count++;
              }
         }
         // Resize array to actual count
         uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             result[i] = stakedNFTs[i];
         }
        return result;
    }

    function getNFTStakeStatus(uint256 tokenId) external view returns (address stakedByAddress) {
        require(_exists(tokenId), "NFT does not exist");
        return nftStakedBy[tokenId];
    }

    // --- View Functions ---

    function getNFTMintCost() external view returns (uint256) {
        return yieldNFTMintCost;
    }

    function getYieldPointsEmissionRate() external view returns (uint256) {
        return yieldPointsEmissionRate;
    }

    function getRewardTokenEmissionRate() external view returns (uint256) {
        return rewardTokenEmissionRate;
    }

    function getTotalStake() external view returns (uint256) {
        return totalStakedStakeToken;
    }

    function getTotalStakedNFTs() external view returns (uint256) {
        return totalStakedYieldNFTs;
    }

     // Override _beforeTokenTransfer to manage NFT timed state on transfer
     // This ensures accrued time is updated whenever an NFT moves in/out of the contract or between users.
     // Note: This needs careful testing to handle all cases (mint, transfer, safeTransferFrom).
     // Our current model only accrues time while STAKED, so simpler explicit updates might be safer.
     // Let's stick to explicit updates in stake/unstake/claim for clarity and gas predictability.
     // Leaving this commented out as it's complex to get right for dynamic state.
    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Update accrued time before the transfer happens if the NFT was in a timed state
         if (nftLastTimedStateUpdate[tokenId] > 0) {
              updateNFTAccruedTime(tokenId); // This calculates time since last update and adds it
              nftLastTimedStateUpdate[tokenId] = 0; // Reset state as it's changing ownership/location
         }

         // If transferring TO this contract AND it's not a mint (from != address(0)),
         // it might be entering a timed state (if it's for staking).
         // This is handled in the stakeYieldNFT function, where nftLastTimedStateUpdate is set.
         // If transferring FROM this contract (to != address(0)), it's leaving.
         // This is handled in unstakeYieldNFT, where nftLastTimedStateUpdate is set to 0.
    }
    */

    // Added to fulfill ERC721Enumerable compatibility if needed, but not strictly required by prompt
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
    //    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    // }
}
```

---

**Explanation of Concepts & Features:**

1.  **Multi-Layer Farming:** Staking ERC20 (`StakeToken`) leads to earning "points" (`YieldPoints`), which are then used to mint NFTs (`YieldNFT`). These NFTs form the basis for a *second* staking layer to earn a different ERC20 (`RewardToken`).
2.  **Yield Points System:** An internal points balance accrues based on the amount of `StakeToken` staked and the duration. This decouples the primary reward (NFT minting) from direct token emissions, allowing for control over NFT supply tied to participation.
3.  **Dynamic NFTs (`YieldNFT`):**
    *   The `tokenURI` function is overridden to generate metadata on the fly.
    *   The key dynamic attribute is `nftAccruedTime`, tracking the total time the NFT has spent inside the contract's "timed state" (specifically, while staked in the NFT staking pool in this implementation).
    *   `updateNFTAccruedTime` is a crucial internal function called during staking/unstaking/claiming to correctly calculate and update this time based on the elapsed duration since the last state change.
    *   `calculateNFTLevel` and `calculatePassiveBoostRate` map the `nftAccruedTime` to tangible in-game attributes that affect the secondary yield.
    *   `getNFTAttributes` provides a view into the *current* state, including extrapolated accrued time if the NFT is currently staked.
4.  **NFT Staking with Boost:** Users stake their `YieldNFT`s in the contract. The rate at which they earn `RewardToken` is influenced by the `passiveBoostRate` of the specific NFTs they have staked. The total reward emitted globally is based on the *sum* of the boosted points of all staked NFTs (`totalBoostedStakedNFTPoints`).
5.  **Time-Weighted Calculations:** Both Yield Points and Reward Tokens are calculated based on `(amount/boost) * time * rate`. This requires tracking `lastUpdate` timestamps for users (for points) and globally (for rewards).
6.  **State Management:** Careful management of user stake amounts, claimed points, staked NFT lists, NFT timed state (`nftLastTimedStateUpdate`, `nftAccruedTime`), and global boosted points is necessary.
7.  **OpenZeppelin Usage:** Leverages standard libraries for ERC721, Ownable, SafeMath, and utility functions like Strings and Base64 for the dynamic URI.
8.  **Admin Controls:** Includes basic functions for the owner to set parameters and pause operations for maintenance or emergencies.
9.  **Gas Considerations:** Notes are included where certain operations (like iterating user's staked NFT list during unstaking or reward claiming) can become gas-intensive with many NFTs, indicating areas where more advanced data structures or off-chain computation might be needed for massive scale.
10. **20+ Functions:** The contract includes setup, admin, two distinct staking/earning flows, NFT management, and various view functions, comfortably exceeding the 20-function requirement.

This contract provides a framework for a complex gamified yield farm where the farmed asset itself (the NFT) evolves and influences further yield generation, moving beyond basic static NFTs or simple token staking.