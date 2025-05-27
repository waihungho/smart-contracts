Okay, let's design an interesting and advanced smart contract that combines several trendy concepts: a **Dynamic Progression Vault with Soulbound NFTs**.

Here's the idea:
*   Users stake an ERC20 token into different "Tiers".
*   Based on the amount staked and the duration, users earn rewards (the same ERC20 token).
*   When a user first stakes, they mint a unique, non-transferable (Soulbound) ERC721 NFT.
*   This NFT's properties (metadata) are *dynamic*. They change based on the user's staking activity (total amount staked, total rewards claimed, duration staked, specific achievements).
*   The contract manages the staking, reward calculation, NFT minting, and tracks the progression data for each NFT.

This combines:
1.  **Staking Vault:** Standard DeFi concept.
2.  **Tiered Staking:** Adds complexity and flexibility.
3.  **Dynamic NFTs:** NFT properties change based on on-chain actions.
4.  **Soulbound Tokens:** NFTs are tied to the user's identity/wallet, representing achievement or status within the system.
5.  **On-Chain Progression Tracking:** The core data driving the dynamic NFTs is stored and updated on-chain.

It avoids simple ERC20/ERC721 creation or direct copies of standard vaults by integrating these elements uniquely.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. State Variables: Core addresses, Tier data, User Stake data, NFT data, System state.
// 2. Events: Signal key actions (Stake, Withdraw, Claim, Tier updates, NFT Mint/Update, Emergency).
// 3. Modifiers: Access control (Ownable), Pausability (Emergency Mode).
// 4. Structs: Define data structures for Tiers, Stakes, NFT Progression.
// 5. Core Staking Logic: Deposit, Withdraw, Reward Calculation, Claiming.
// 6. NFT Management: Minting Soulbound NFTs, Linking to User, Tracking Progression.
// 7. Dynamic Progression: Logic to update NFT state based on staking activity.
// 8. Admin Functions: Manage Tiers, Emergency Mode, Recover tokens.
// 9. View Functions: Query state data (Stakes, Rewards, Tiers, NFT data).
// 10. Soulbound Logic: Prevent NFT transfers.
// 11. ERC721 Overrides: Handle standard functions for the soulbound property.

// Function Summary:
// - constructor(address _stakingToken, string memory _nftName, string memory _nftSymbol): Initializes contract with token and NFT details.
// - addStakingTier(uint256 _minStakeAmount, uint256 _rewardRatePermille, string memory _name, bool _active): Owner adds a new staking tier.
// - updateStakingTier(uint256 _tierId, uint256 _minStakeAmount, uint256 _rewardRatePermille, string memory _name, bool _active): Owner updates an existing tier.
// - deactivateStakingTier(uint256 _tierId): Owner deactivates a tier (prevents new stakes).
// - stake(uint256 _tierId, uint256 _amount): User stakes tokens into a specific tier. Mints a Soulbound NFT on first stake.
// - withdraw(uint256 _tierId, uint256 _amount): User withdraws staked tokens from a tier.
// - claimRewards(uint256 _tierId): User claims pending rewards for a tier. Triggers NFT progression update.
// - calculatePendingRewards(address _user, uint256 _tierId) view: Calculates rewards available for a user in a tier.
// - getTierInfo(uint256 _tierId) view: Gets details of a specific staking tier.
// - getAllTierIds() view: Gets a list of all existing tier IDs.
// - getUserStakeInfo(address _user, uint256 _tierId) view: Gets detailed stake info for a user in a tier.
// - getTotalStakedByTier(uint256 _tierId) view: Gets the total amount staked in a tier by all users.
// - getNFTIdForUser(address _user) view: Gets the Soulbound NFT ID linked to a user.
// - getNFTProgressionStatus(uint256 _tokenId) view: Gets the current progression data for an NFT.
// - tokenURI(uint256 _tokenId) view: Standard ERC721 function for dynamic metadata (requires off-chain service).
// - getNFTMetadataOnChain(uint256 _tokenId) view: Exposes the raw on-chain data used for metadata generation.
// - toggleEmergencyMode(): Owner toggles the emergency pause state.
// - withdrawStuckTokens(address _tokenAddress): Owner can rescue other tokens accidentally sent to the contract.
// - burnProgressionNFT(uint256 _tokenId): Allows a user to burn their Soulbound NFT (e.g., after fully unstaking - optional feature).
// - setBaseURI(string memory _baseURI): Owner sets the base URI for tokenURI.
// - balanceOf(address owner) view: Standard ERC721 function.
// - ownerOf(uint256 tokenId) view: Standard ERC721 function.
// - supportsInterface(bytes4 interfaceId) view: Standard ERC721 function.
// - approve(address to, uint256 tokenId) payable: ERC721 override - reverts (soulbound).
// - setApprovalForAll(address operator, bool approved) payable: ERC721 override - reverts (soulbound).
// - getApproved(uint256 tokenId) view: ERC721 override - reverts (soulbound).
// - isApprovedForAll(address owner, address operator) view: ERC721 override - reverts (soulbound).

contract DynamicProgressionVaultNFT is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public immutable stakingToken; // The token users stake and earn

    // --- State Variables ---

    struct StakingTier {
        uint256 id;
        uint256 minStakeAmount;
        uint256 rewardRatePermille; // Rewards per 1000 tokens per hour
        string name;
        bool active; // Can new stakes be added to this tier?
    }

    mapping(uint256 => StakingTier) public stakingTiers;
    uint256 private nextTierId = 1;

    struct UserStake {
        uint256 amount;
        uint256 startTime; // Timestamp when stake was initiated/last claimed
        uint256 lastClaimTime; // Timestamp of last reward claim
    }

    mapping(address => mapping(uint256 => UserStake)) public userStakes;
    mapping(uint256 => uint256) public totalStakedByTier;

    // NFT State
    mapping(address => uint256) private userToNFTId; // Maps user address to their unique progression NFT ID
    uint256 private nextNFTId = 1; // Counter for unique NFT IDs

    struct NFTProgressionData {
        uint256 level;
        uint256 totalRewardsClaimed;
        uint256 totalStakeDurationSeconds; // Cumulative duration across all stakes/tiers
        uint256 lastProgressionUpdateTime; // When the NFT data was last updated
        // Add more progression metrics here, e.g., specific achievements, total staked history, etc.
    }

    mapping(uint256 => NFTProgressionData) public nftProgressionData;

    // System State
    bool public emergencyMode = false; // Pauses key user interactions

    // Metadata URI
    string private _baseTokenURI;

    // --- Events ---

    event Staked(address indexed user, uint256 indexed tierId, uint256 amount, uint256 stakeTime, uint256 nftId);
    event Withdrew(address indexed user, uint256 indexed tierId, uint256 amount, uint256 unstakeTime);
    event ClaimedRewards(address indexed user, uint256 indexed tierId, uint256 rewardsAmount, uint256 claimTime);
    event TierAdded(uint256 indexed tierId, uint256 minStake, uint256 rewardRatePermille, string name, bool active);
    event TierUpdated(uint256 indexed tierId, uint256 minStake, uint256 rewardRatePermille, string name, bool active);
    event TierDeactivated(uint256 indexed tierId);
    event ProgressionNFTMinted(address indexed user, uint256 indexed tokenId, uint256 initialTierId);
    event NFTProgressionUpdated(uint256 indexed tokenId, uint256 level, uint256 totalRewardsClaimed, uint256 totalStakeDuration);
    event EmergencyModeToggled(bool isEmergency);
    event TokensRescued(address indexed tokenAddress, uint256 amount);
    event ProgressionNFTBurned(uint256 indexed tokenId);
    event BaseURISet(string baseURI);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!emergencyMode, "Paused");
        _;
    }

    modifier whenPaused() {
        require(emergencyMode, "Not paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        _;
    }

    // --- Constructor ---

    constructor(address _stakingToken, string memory _nftName, string memory _nftSymbol)
        ERC721(_nftName, _nftSymbol)
        Ownable(msg.sender)
    {
        stakingToken = IERC20(_stakingToken);
    }

    // --- Admin Functions ---

    function addStakingTier(uint256 _minStakeAmount, uint256 _rewardRatePermille, string memory _name, bool _active) public onlyOwner {
        uint256 tierId = nextTierId++;
        stakingTiers[tierId] = StakingTier(tierId, _minStakeAmount, _rewardRatePermille, _name, _active);
        emit TierAdded(tierId, _minStakeAmount, _rewardRatePermille, _name, _active);
    }

    function updateStakingTier(uint256 _tierId, uint256 _minStakeAmount, uint256 _rewardRatePermille, string memory _name, bool _active) public onlyOwner {
        require(stakingTiers[_tierId].id != 0, "Tier does not exist");
        stakingTiers[_tierId].minStakeAmount = _minStakeAmount;
        stakingTiers[_tierId].rewardRatePermille = _rewardRatePermille;
        stakingTiers[_tierId].name = _name;
        stakingTiers[_tierId].active = _active;
        emit TierUpdated(_tierId, _minStakeAmount, _rewardRatePermille, _name, _active);
    }

    function deactivateStakingTier(uint256 _tierId) public onlyOwner {
        require(stakingTiers[_tierId].id != 0, "Tier does not exist");
        stakingTiers[_tierId].active = false;
        emit TierDeactivated(_tierId);
    }

    function toggleEmergencyMode() public onlyOwner {
        emergencyMode = !emergencyMode;
        emit EmergencyModeToggled(emergencyMode);
    }

    function withdrawStuckTokens(address _tokenAddress) public onlyOwner {
        require(emergencyMode, "Must be in emergency mode to withdraw stuck tokens");
        IERC20 stuckToken = IERC20(_tokenAddress);
        uint256 balance = stuckToken.balanceOf(address(this));
        // Prevent withdrawing the primary staking token unless absolutely necessary (e.g., contract needs to be drained)
        require(_tokenAddress != address(stakingToken), "Cannot withdraw staking token unless specific function is available"); // Add a specific function if needed for full draining

        stuckToken.transfer(owner(), balance);
        emit TokensRescued(_tokenAddress, balance);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseTokenURI = _baseURI;
        emit BaseURISet(_baseURI);
    }


    // --- Core Staking Logic ---

    function stake(uint256 _tierId, uint256 _amount) public whenNotPaused nonReentrant {
        require(stakingTiers[_tierId].id != 0 && stakingTiers[_tierId].active, "Invalid or inactive tier");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount >= stakingTiers[_tierId].minStakeAmount, "Amount below minimum stake for tier");

        address user = _msgSender();
        uint256 currentTime = block.timestamp;

        // Calculate pending rewards before adding new stake
        uint256 pendingRewards = calculatePendingRewards(user, _tierId);
        if (pendingRewards > 0) {
            // Automatically claim pending rewards before restaking in the same tier
            _claimRewards(user, _tierId, pendingRewards);
        }

        // Transfer tokens to contract
        require(stakingToken.transferFrom(user, address(this), _amount), "Token transfer failed");

        // Update user stake information
        userStakes[user][_tierId].amount = userStakes[user][_tierId].amount.add(_amount);
        userStakes[user][_tierId].startTime = currentTime; // Reset start time for reward calculation on new stake/claim
        userStakes[user][_tierId].lastClaimTime = currentTime; // Reset last claim time

        // Update total staked amount
        totalStakedByTier[_tierId] = totalStakedByTier[_tierId].add(_amount);

        // Mint Soulbound NFT if it's the user's first stake
        if (userToNFTId[user] == 0) {
            _mintProgressionNFT(user, _tierId);
        } else {
             // Update progression data on stake
             _updateNFTProgression(userToNFTId[user]);
        }


        emit Staked(user, _tierId, _amount, currentTime, userToNFTId[user]);
    }

    function withdraw(uint256 _tierId, uint256 _amount) public whenNotPaused nonReentrant {
        address user = _msgSender();
        require(stakingTiers[_tierId].id != 0, "Invalid tier");
        require(_amount > 0, "Amount must be greater than zero");
        require(userStakes[user][_tierId].amount >= _amount, "Insufficient staked amount");

        uint256 currentTime = block.timestamp;

        // Claim pending rewards before withdrawing
        uint256 pendingRewards = calculatePendingRewards(user, _tierId);
        if (pendingRewards > 0) {
             _claimRewards(user, _tierId, pendingRewards);
        }

        // Update user stake information
        userStakes[user][_tierId].amount = userStakes[user][_tierId].amount.sub(_amount);
        // If the full amount is withdrawn, reset timestamps, otherwise keep old start time for remaining stake?
        // Let's reset startTime only if remaining stake is zero. Keep lastClaimTime.
        if (userStakes[user][_tierId].amount == 0) {
             userStakes[user][_tierId].startTime = 0;
        }
        // No need to update lastClaimTime here, it was updated by the auto-claim.

        // Update total staked amount
        totalStakedByTier[_tierId] = totalStakedByTier[_tierId].sub(_amount);

        // Transfer tokens back to user (staked amount)
        require(stakingToken.transfer(user, _amount), "Token transfer failed");

        // Update progression data on withdrawal
        if (userToNFTId[user] != 0) {
             _updateNFTProgression(userToNFTId[user]);
        }


        emit Withdrew(user, _tierId, _amount, currentTime);
    }

    function claimRewards(uint256 _tierId) public whenNotPaused nonReentrant {
        address user = _msgSender();
        require(stakingTiers[_tierId].id != 0, "Invalid tier");
        require(userStakes[user][_tierId].amount > 0, "No active stake in this tier");

        uint256 pendingRewards = calculatePendingRewards(user, _tierId);
        require(pendingRewards > 0, "No pending rewards");

        _claimRewards(user, _tierId, pendingRewards);

        // Update progression data after claiming rewards
        if (userToNFTId[user] != 0) {
             _updateNFTProgression(userToNFTId[user]);
        }
    }

    // Internal helper for claiming rewards
    function _claimRewards(address user, uint256 _tierId, uint256 rewardsAmount) internal {
        uint256 currentTime = block.timestamp;

        // Transfer rewards to user
        require(stakingToken.transfer(user, rewardsAmount), "Reward transfer failed");

        // Update user's last claim time and cumulative claimed rewards (for NFT progression)
        userStakes[user][_tierId].lastClaimTime = currentTime;

        uint256 nftId = userToNFTId[user];
        if (nftId != 0) {
             nftProgressionData[nftId].totalRewardsClaimed = nftProgressionData[nftId].totalRewardsClaimed.add(rewardsAmount);
             // Total stake duration is updated in _updateNFTProgression
        }

        emit ClaimedRewards(user, _tierId, rewardsAmount, currentTime);
    }


    function calculatePendingRewards(address _user, uint256 _tierId) public view returns (uint256) {
        require(stakingTiers[_tierId].id != 0, "Invalid tier");
        UserStake storage stake = userStakes[_user][_tierId];
        if (stake.amount == 0) {
            return 0;
        }

        uint256 lastRewardTime = stake.lastClaimTime > 0 ? stake.lastClaimTime : stake.startTime; // Use start time if never claimed
        uint256 currentTime = block.timestamp;

        if (currentTime <= lastRewardTime) {
            return 0;
        }

        // Calculate duration since last claim/start time
        uint256 duration = currentTime - lastRewardTime; // Duration in seconds

        // Reward rate is per 1000 tokens per hour.
        // Convert duration to hours: duration / 3600
        // Calculate rewards: stake.amount * rewardRatePermille / 1000 * duration / 3600
        // Simplified: stake.amount * rewardRatePermille * duration / (1000 * 3600)
        // Use SafeMath, multiply before dividing to maintain precision where possible (within reason for uint256)
        // Ensure no intermediate overflow: stake.amount * rewardRatePermille could be large.
        // uint256 rewards = (stake.amount / 1000).mul(stakingTiers[_tierId].rewardRatePermille).mul(duration / 3600); // Integer division might lose precision significantly
        // Better: Calculate in smaller steps or use a fixed-point math library (complex).
        // For simplicity and clarity with uint256, let's assume reasonable values and use a more precise calculation:
        // Rewards = stake_amount * reward_rate_per_mille * duration_in_seconds / (1000 * 3600)
        // Rewards = stake_amount * reward_rate_per_mille * duration_in_seconds / 3600000
        uint256 rewards = stake.amount.mul(stakingTiers[_tierId].rewardRatePermille).mul(duration).div(3600000); // Div by 1000 for permille, then by 3600 for seconds to hours

        return rewards;
    }

    // --- NFT Management ---

    // Mints a Soulbound NFT linked to the user's progression
    function _mintProgressionNFT(address _user, uint256 _initialTierId) internal {
        require(userToNFTId[_user] == 0, "User already has an NFT");

        uint256 tokenId = nextNFTId++;
        _safeMint(_user, tokenId); // Mint the ERC721 token

        userToNFTId[_user] = tokenId; // Link user to NFT ID

        // Initialize progression data
        nftProgressionData[tokenId] = NFTProgressionData({
            level: 1, // Start at level 1
            totalRewardsClaimed: 0,
            totalStakeDurationSeconds: 0,
            lastProgressionUpdateTime: block.timestamp
        });

        // Update progression data immediately after minting based on initial stake
        _updateNFTProgression(tokenId);

        emit ProgressionNFTMinted(_user, tokenId, _initialTierId);
    }

    // Internal function to update NFT progression data
    function _updateNFTProgression(uint256 _tokenId) internal {
        require(_exists(_tokenId), "NFT does not exist");
        address user = ownerOf(_tokenId);

        NFTProgressionData storage progData = nftProgressionData[_tokenId];
        uint256 currentTime = block.timestamp;

        // Update total stake duration - consider duration since last update for *all* currently active stakes
        // This is simplified: we'll just add the duration since the last update, assuming *any* stake counts.
        // A more complex version would iterate through all user's tiers and sum up durations if they were staked.
        // For this example, we track the duration the NFT *exists* with an active stake.
        // If the user has *any* stake > 0 across *any* tier, increment duration.
        // Let's check if the user has any total stake amount across all tiers.
        uint256 totalActiveStake = 0;
        for (uint256 i = 1; i < nextTierId; i++) {
             totalActiveStake = totalActiveStake.add(userStakes[user][i].amount);
        }

        if (totalActiveStake > 0 && progData.lastProgressionUpdateTime > 0) {
             progData.totalStakeDurationSeconds = progData.totalStakeDurationSeconds.add(currentTime - progData.lastProgressionUpdateTime);
        }
        progData.lastProgressionUpdateTime = currentTime;


        // Progression Logic: Define rules for leveling up
        uint256 newLevel = progData.level;
        // Example rules:
        // Level 2: total rewards claimed >= 1000 AND total stake duration >= 7 days (604800 seconds)
        if (progData.level == 1 && progData.totalRewardsClaimed >= 1000 && progData.totalStakeDurationSeconds >= 604800) {
            newLevel = 2;
        }
        // Level 3: total rewards claimed >= 5000 AND total stake duration >= 30 days (2592000 seconds)
        else if (progData.level == 2 && progData.totalRewardsClaimed >= 5000 && progData.totalStakeDurationSeconds >= 2592000) {
            newLevel = 3;
        }
        // Add more complex rules based on tier, specific actions, etc.

        if (newLevel > progData.level) {
            progData.level = newLevel;
            // Potentially emit a separate level-up event
        }

        emit NFTProgressionUpdated(_tokenId, progData.level, progData.totalRewardsClaimed, progData.totalStakeDurationSeconds);
    }

    // Allows user to burn their Soulbound NFT (e.g., after they have fully unstaked from all tiers)
    function burnProgressionNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        address user = _msgSender();
        require(userToNFTId[user] == _tokenId, "NFT not linked to user");

        // Optional: Require user to have zero staked tokens across all tiers before burning
        uint256 totalActiveStake = 0;
        for (uint256 i = 1; i < nextTierId; i++) {
             totalActiveStake = totalActiveStake.add(userStakes[user][i].amount);
        }
        require(totalActiveStake == 0, "Cannot burn NFT while tokens are staked");

        delete userToNFTId[user]; // Unlink user from NFT
        delete nftProgressionData[_tokenId]; // Delete progression data
        _burn(_tokenId); // Burn the ERC721 token

        emit ProgressionNFTBurned(_tokenId);
    }


    // --- View Functions ---

    function getTierInfo(uint256 _tierId) public view returns (uint256 id, uint256 minStake, uint256 rewardRatePermille, string memory name, bool active) {
        StakingTier storage tier = stakingTiers[_tierId];
        require(tier.id != 0, "Tier does not exist");
        return (tier.id, tier.minStakeAmount, tier.rewardRatePermille, tier.name, tier.active);
    }

    function getAllTierIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](nextTierId - 1);
        for (uint256 i = 1; i < nextTierId; i++) {
            ids[i - 1] = i;
        }
        return ids;
    }

     function getUserStakeInfo(address _user, uint256 _tierId) public view returns (uint256 amount, uint256 startTime, uint256 lastClaimTime) {
        UserStake storage stake = userStakes[_user][_tierId];
        return (stake.amount, stake.startTime, stake.lastClaimTime);
    }

    function getTotalStakedByTier(uint256 _tierId) public view returns (uint256) {
        require(stakingTiers[_tierId].id != 0, "Tier does not exist");
        return totalStakedByTier[_tierId];
    }

    function getNFTIdForUser(address _user) public view returns (uint256) {
        return userToNFTId[_user];
    }

    function getNFTProgressionStatus(uint256 _tokenId) public view returns (uint256 level, uint256 totalRewardsClaimed, uint256 totalStakeDurationSeconds) {
        require(_exists(_tokenId), "NFT does not exist");
        NFTProgressionData storage progData = nftProgressionData[_tokenId];
        return (progData.level, progData.totalRewardsClaimed, progData.totalStakeDurationSeconds);
    }

     // Expose the raw on-chain data used by the metadata service
    function getNFTMetadataOnChain(uint256 _tokenId) public view returns (
        uint256 tokenId,
        address owner,
        uint256 level,
        uint256 totalRewardsClaimed,
        uint256 totalStakeDurationSeconds,
        uint256 lastUpdateTimestamp
    ) {
         require(_exists(_tokenId), "NFT does not exist");
         NFTProgressionData storage progData = nftProgressionData[_tokenId];
         return (
             _tokenId,
             ownerOf(_tokenId),
             progData.level,
             progData.totalRewardsClaimed,
             progData.totalStakeDurationSeconds,
             progData.lastProgressionUpdateTime
         );
    }


    // --- Soulbound Logic (Prevent Transfers) ---

    // Override ERC721's internal transfer function to prevent any transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the transfer is not minting (from != address(0)) or burning (to != address(0)), prevent it.
        // This makes the token soulbound after minting and before burning.
        if (from != address(0) && to != address(0)) {
            revert("Progression NFT is soulbound and cannot be transferred");
        }
    }

    // Override standard transfer functions to explicitly disallow
    function transferFrom(address from, address to, uint256 tokenId) public override {
         revert("Progression NFT is soulbound and cannot be transferred");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         revert("Progression NFT is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
         revert("Progression NFT is soulbound and cannot be transferred");
    }

    // Override approval functions to explicitly disallow
    function approve(address to, uint256 tokenId) public payable override {
         revert("Progression NFT is soulbound and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public override {
         revert("Progression NFT is soulbound and cannot be approved");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
         revert("Progression NFT is soulbound and cannot be approved");
    }

     function isApprovedForAll(address owner, address operator) public view override returns (bool) {
         revert("Progression NFT is soulbound and cannot be approved");
    }


    // --- ERC721 Standard Functions ---
    // Implemented by inheriting ERC721 from OpenZeppelin.
    // Only `tokenURI` needs custom implementation for dynamic metadata.

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721: token query for nonexistent token");

        // The actual dynamic metadata JSON is *not* stored on-chain.
        // This function returns a URI pointing to an off-chain service (like a server or IPFS gateway)
        // that will generate the metadata JSON based on the on-chain progression data.
        // The off-chain service calls `getNFTMetadataOnChain(_tokenId)` to get the data.

        string memory base = _baseTokenURI;

        // If base URI is not set, return empty string as per standard practice or a default error URI
        if (bytes(base).length == 0) {
            return ""; // Or a default placeholder URI
        }

        // Build the full URI: baseURI + tokenId
        // Using string.concat if available or manual assembly
        // Example: "https://mydynamicservice.xyz/api/metadata/" + toString(tokenId)
        // toString requires a helper function, or rely on the off-chain service to append.
        // Let's assume baseURI includes the trailing slash and expects the token ID.
        // A robust implementation would use OpenZeppelin's `Strings.toString` helper if available/imported.
        // For simplicity, let's return base URI + tokenId.
        // This simple concatenation needs OpenZeppelin's `Strings` library.
        // import "@openzeppelin/contracts/utils/Strings.sol";
        // return string(abi.encodePacked(base, Strings.toString(_tokenId)));
        // Without Strings.sol import for brevity in this example:
        // Just return the base URI + a placeholder indication that the ID should be appended.
        // The off-chain service knows to append the token ID.
        return string(abi.encodePacked(base, Strings.toString(_tokenId))); // Add Strings.sol import

    }

    // Need to import Strings for toString
    import "@openzeppelin/contracts/utils/Strings.sol";
}
```

---

**Explanation of Key Concepts & Design Choices:**

1.  **Dynamic NFTs:** The `NFTProgressionData` struct stores key metrics (`level`, `totalRewardsClaimed`, `totalStakeDurationSeconds`). The `_updateNFTProgression` internal function reads this data and updates the `level` based on predefined criteria. The `tokenURI` function is standard for ERC721, but instead of pointing to static metadata, it points to a service that reads the *on-chain state* (`getNFTMetadataOnChain`) and generates the JSON metadata dynamically. This is the crucial link for dynamic NFTs.
2.  **Soulbound:** The `_beforeTokenTransfer` internal function is overridden to revert unless the transfer is a mint (from `address(0)`) or a burn (to `address(0)`). Explicit overrides for `transferFrom`, `safeTransferFrom`, `approve`, and `setApprovalForAll` provide clear error messages and prevent accidental interactions that might imply transferability. This makes the NFT a non-transferable representation of the user's participation and progress.
3.  **Tiered Staking:** The `StakingTier` struct and mapping allow the owner to define different staking levels with varying minimum amounts and reward rates. Users choose which tier to stake into.
4.  **On-Chain Progression:** Staking activity (staking, withdrawing, claiming) triggers calls to the internal `_updateNFTProgression` function. This function calculates cumulative metrics (like duration and claimed rewards) and updates the NFT's on-chain state (`nftProgressionData`). This data is transparent and verifiable.
5.  **Reward Calculation:** Rewards are calculated based on the amount staked and the time elapsed since the last claim/stake time. The `calculatePendingRewards` function provides a view to see potential earnings. Auto-claiming on stake/withdrawal in the same tier simplifies the user experience and ensures progression data is based on claimed rewards.
6.  **Emergency Mode:** A simple boolean `emergencyMode` controlled by the owner allows pausing core staking/claiming functions in case of issues, adding a layer of security.
7.  **Reentrancy Guard:** Used on stake/withdraw/claim functions to prevent reentrancy attacks, although the logic with token transfers happening before state updates already mitigates much of this risk.
8.  **Stuck Token Rescue:** The `withdrawStuckTokens` function allows the owner to retrieve other ERC20 tokens accidentally sent to the contract, provided the contract is in emergency mode (to prevent it being used to drain the primary staking token unexpectedly).
9.  **Burn Function:** Added a `burnProgressionNFT` function allowing users to destroy their Soulbound NFT, perhaps as a final action after unstaking everything.

This contract provides a robust framework for creating a system where user engagement (staking) directly influences a unique, non-transferable digital asset, opening up possibilities for gamification, reputation systems, or exclusive access based on the NFT's progression level. Remember that the dynamic metadata *display* relies on an off-chain service reading the on-chain data provided by `getNFTMetadataOnChain` and `tokenURI`.