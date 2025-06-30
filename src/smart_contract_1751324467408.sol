Okay, let's design a smart contract that combines several advanced, creative, and trendy concepts: **Dynamic NFTs, Staking with Evolving Rewards, Delegated Management, Referral System, and On-Chain Evolution based on staking parameters.**

We'll call it the **MetaMorph Protocol**. Users stake an ERC20 token (`MORPH`) to earn rewards and receive a unique ERC721 NFT (`Morphling`) that **evolves** visually and functionally based on the amount staked, duration, and cumulative rewards.

---

**Outline & Function Summary**

**Contract Name:** MetaMorphProtocol

**Concept:** Stake ERC20 (`MORPH`) to earn rewards and mint/evolve a dynamic ERC721 NFT (`Morphling`). NFT traits are calculated on-chain based on staking activity. Includes features like delegated management, referral bonuses, and admin controls.

**Tokens Involved:**
*   `IERC20 MORPH_TOKEN`: The stake and reward token.
*   `ERC721 MorphlingNFT`: The dynamic NFT representing the stake.

**Core Mechanics:**
1.  **Staking:** Users deposit `MORPH` tokens. A new `MorphlingNFT` is minted for each unique stake deposit. The NFT ID is linked to the stake data.
2.  **Dynamic Evolution:** The `MorphlingNFT`'s traits and visual representation (via `tokenURI`) change based on staking duration, amount staked for that specific NFT, and rewards claimed by that NFT.
3.  **Reward Accrual:** Rewards accrue over time based on the staked amount and a dynamic rate.
4.  **Delegated Management:** Owners can delegate staking/claiming actions for specific NFTs to another address.
5.  **Referral System:** Users can earn bonuses by referring new stakers.
6.  **NFT Actions:** Deposit more into an existing NFT's stake, compound rewards, claim rewards, unstake (burns NFT).
7.  **Admin Controls:** Set rates, thresholds, pause/unpause, manage roles.

**Function Categories & Summary:**

*   **Core Staking & NFT Management:**
    *   `depositMorph(uint256 amount, address referrer)`: Stake MORPH tokens, mint a new Morphling NFT. Record referrer if valid.
    *   `withdrawMorph(uint256 tokenId)`: Unstake MORPH tokens associated with a specific Morphling NFT. Burns the NFT. Applies penalty if unstaked too early.
    *   `claimRewards(uint256[] calldata tokenIds)`: Claim accumulated MORPH rewards for multiple NFTs.
    *   `depositMoreIntoNftStake(uint256 tokenId, uint256 amount)`: Add more MORPH tokens to an existing Morphling NFT's stake, increasing its value and potential for evolution.
    *   `compoundRewardsForNft(uint256 tokenId)`: Claim rewards for an NFT and immediately restake them into the *same* NFT's stake.
    *   `claimAndRestakeForNft(uint256 tokenId)`: Claim rewards for an NFT and immediately deposit them as a *new, separate* stake (minting a new NFT). (Alternative compounding logic).
    *   `unstakeMorphling(uint256 tokenId)`: A wrapper/alias for `withdrawMorph`.
*   **Dynamic NFT & Data Retrieval:**
    *   `getPendingRewards(uint256 tokenId)`: Calculate and return pending rewards for a specific NFT.
    *   `getMorphlingTraits(uint256 tokenId)`: Calculate and return the current on-chain traits of a Morphling NFT based on its staking data.
    *   `getCurrentEvolutionStage(uint256 tokenId)`: Determine the evolution stage of an NFT.
    *   `tokenURI(uint256 tokenId)`: ERC721 standard function. Generates a data URI including calculated dynamic traits.
    *   `isMorphlingStaked(uint256 tokenId)`: Check if an NFT is currently linked to an active stake.
    *   `getNftStakingDetails(uint256 tokenId)`: Retrieve comprehensive staking data for an NFT.
    *   `getUserStakedBalance(address user)`: Get total MORPH staked by a user across all their NFTs.
    *   `getOwnedMorphlings(address user)`: Get a list of Morphling NFT IDs owned by a user.
*   **Delegated Management:**
    *   `delegateManagement(uint256 tokenId, address delegate)`: Owner delegates staking/claiming control for an NFT.
    *   `revokeManagement(uint256 tokenId)`: Owner revokes delegation.
    *   `getDelegate(uint256 tokenId)`: Get the delegated address for an NFT.
*   **Referral System:**
    *   `recordReferral(address newUser, address referrer)`: Internal function to record successful referrals. Called during `depositMorph`.
    *   `claimReferralRewards()`: Referrers claim accumulated referral bonuses.
    *   `getPendingReferralRewards(address referrer)`: View pending referral rewards.
*   **Admin/Protocol Controls:**
    *   `setRewardRate(uint256 newRatePerSecond)`: Admin sets the base reward rate.
    *   `setEvolutionThresholds(...)`: Admin sets the criteria for NFT evolution stages.
    *   `addApprovedReferrer(address referrer)`: Admin approves an address to participate in the referral program (optional, adds a layer of control).
    *   `removeApprovedReferrer(address referrer)`: Admin removes an approved referrer.
    *   `pauseStaking()`: Admin pauses core staking actions.
    *   `unpauseStaking()`: Admin unpauses.
    *   `withdrawProtocolFees()`: Admin withdraws collected unstaking fees.
    *   `grantRole(bytes32 role, address account)`: Admin grants a specific role (e.g., `PAUSER_ROLE`, `CONFIGURER_ROLE`). (Inherited from AccessControl)
    *   `revokeRole(bytes32 role, address account)`: Admin revokes a role. (Inherited from AccessControl)
    *   `renounceRole(bytes32 role, address account)`: User renounces their own role. (Inherited from AccessControl)
*   **Queries (Inherited/Standard):**
    *   `balanceOf(address owner)`: ERC721 count of NFTs owned.
    *   `ownerOf(uint256 tokenId)`: ERC721 owner of an NFT.
    *   `getRoleAdmin(bytes32 role)`: Get admin role for a role. (Inherited from AccessControl)
    *   `hasRole(bytes32 role, address account)`: Check if account has role. (Inherited from AccessControl)
    *   `isApprovedReferrer(address referrer)`: Check if an address is an approved referrer.
    *   `getTotalStaked()`: Get the total MORPH tokens staked in the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For getOwnedMorphlings efficiency
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MetaMorphProtocol is ERC721Enumerable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONFIGURER_ROLE = keccak256("CONFIGURER_ROLE"); // Can set rates, thresholds
    bytes32 public constant REFERRER_ADMIN_ROLE = keccak256("REFERRER_ADMIN_ROLE"); // Can manage approved referrers

    // --- Tokens ---
    IERC20 public immutable MORPH_TOKEN;

    // --- Staking State ---
    struct Stake {
        uint256 amount;
        uint64 startTime; // Using uint64 for block.timestamp
        uint256 claimedRewards; // Total rewards claimed for this specific stake/NFT
        uint256 lastClaimTime; // Using uint256 for easier calculation
    }

    mapping(uint256 => Stake) public tokenIdToStake;
    mapping(address => uint256) private _userStakedBalance;
    uint256 private _totalStaked;

    // --- NFT Metadata & Evolution ---
    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Apex }
    uint256[] public evolutionStakeThresholds; // MORPH amount thresholds per NFT
    uint256[] public evolutionDurationThresholds; // Seconds staked thresholds per NFT
    uint256[] public evolutionRewardClaimThresholds; // MORPH claimed thresholds per NFT

    // --- Reward System ---
    uint256 public rewardRatePerSecond; // MORPH per second per unit of stake (e.g., 1 MORPH per 1000 staked per sec) - adjust denominator for desired rate
    uint256 public constant REWARD_RATE_DENOMINATOR = 1e18; // Assume MORPH is 18 decimals

    // --- Penalty for early unstaking ---
    uint256 public minStakeDurationForNoPenalty; // Minimum seconds to stake to avoid penalty
    uint256 public earlyUnstakePenaltyRate; // Percentage penalty (e.g., 500 for 5%)
    uint256 public constant PENALTY_RATE_DENOMINATOR = 10000; // 100% is 10000

    // --- Referral System ---
    mapping(address => bool) public isApprovedReferrer;
    mapping(address => uint256) private _referralRewards;
    uint256 public referralRewardAmount; // Fixed MORPH bonus per successful referral

    // --- Delegated Management ---
    mapping(uint256 => address) private _delegatedManagement; // tokenId => delegatedAddress

    // --- Protocol Fees ---
    uint256 public protocolFeeBalance;
    uint256 public unstakeFeeRate; // Percentage fee on unstake amount
    uint256 public constant UNSTAKE_FEE_DENOMINATOR = 10000;

    // --- NFT Counter ---
    Counters.Counter private _tokenIdCounter;

    // --- Events ---
    event Staked(address indexed user, uint256 tokenId, uint256 amount, address indexed referrer);
    event Unstaked(address indexed user, uint256 tokenId, uint256 amount, uint256 rewardsClaimed, uint256 penaltyPaid);
    event RewardsClaimed(address indexed user, uint256[] tokenIds, uint256 totalRewards);
    event DepositMore(address indexed user, uint256 tokenId, uint256 amountAdded);
    event ManagementDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event ManagementRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event ReferralRecorded(address indexed newUser, address indexed referrer);
    event ReferralRewardsClaimed(address indexed referrer, uint256 amount);
    event EvolutionThresholdsSet(uint256[] stakeThresholds, uint256[] durationThresholds, uint256[] rewardThresholds);
    event RewardRateSet(uint256 newRate);
    event ProtocolFeeWithdrawn(address indexed to, uint256 amount);
    event PenaltyRateSet(uint256 newRate);
    event UnstakeFeeRateSet(uint256 newRate);
    event MinStakeDurationSet(uint256 duration);
    event ReferralRewardAmountSet(uint256 amount);

    // --- Constructor ---
    constructor(
        address morphTokenAddress,
        uint256 _rewardRatePerSecond,
        uint256 _minStakeDurationForNoPenalty,
        uint256 _earlyUnstakePenaltyRate,
        uint256 _unstakeFeeRate,
        uint256 _referralRewardAmount,
        uint256[] memory _evolutionStakeThresholds,
        uint256[] memory _evolutionDurationThresholds,
        uint256[] memory _evolutionRewardClaimThresholds
    ) ERC721("MetaMorph Morphling", "MORPHLING") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(CONFIGURER_ROLE, msg.sender);
        _grantRole(REFERRER_ADMIN_ROLE, msg.sender);

        MORPH_TOKEN = IERC20(morphTokenAddress);

        rewardRatePerSecond = _rewardRatePerSecond;
        minStakeDurationForNoPenalty = _minStakeDurationForNoPenalty;
        earlyUnstakePenaltyRate = _earlyUnstakePenaltyRate;
        unstakeFeeRate = _unstakeFeeRate;
        referralRewardAmount = _referralRewardAmount;

        setEvolutionThresholds(_evolutionStakeThresholds, _evolutionDurationThresholds, _evolutionRewardClaimThresholds);

        // Grant initial admin role to the deployer
        if (msg.sender != address(0)) {
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
    }

    // --- Modifiers ---
    modifier onlyNftOwnerOrDelegate(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        address delegate = _delegatedManagement[tokenId];
        require(msg.sender == owner || msg.sender == delegate, "Not authorized for this NFT");
        _;
    }

    modifier onlyStaked(uint256 tokenId) {
        require(tokenIdToStake[tokenId].amount > 0, "NFT not staked");
        _;
    }

    // --- Core Staking & NFT Management Functions ---

    /// @notice Stakes MORPH tokens and mints a new Morphling NFT.
    /// @param amount The amount of MORPH tokens to stake.
    /// @param referrer The address of the referrer, or address(0) if none.
    function depositMorph(uint256 amount, address referrer) external whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(MORPH_TOKEN.transferFrom(msg.sender, address(this), amount), "MORPH transfer failed");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        Stake memory newStake = Stake({
            amount: amount,
            startTime: uint64(block.timestamp),
            claimedRewards: 0,
            lastClaimTime: block.timestamp
        });
        tokenIdToStake[newTokenId] = newStake;

        _userStakedBalance[msg.sender] += amount;
        _totalStaked += amount;

        // Handle referral
        if (referrer != address(0) && referrer != msg.sender && isApprovedReferrer[referrer]) {
            _recordReferral(msg.sender, referrer);
        }

        emit Staked(msg.sender, newTokenId, amount, referrer);
    }

    /// @notice Unstakes MORPH tokens associated with an NFT and burns the NFT.
    /// @param tokenId The ID of the Morphling NFT to unstake.
    function withdrawMorph(uint256 tokenId) external onlyStaked onlyNftOwnerOrDelegate(tokenId) whenNotPaused {
        address owner = ownerOf(tokenId);
        Stake storage stake = tokenIdToStake[tokenId];
        uint256 stakeAmount = stake.amount;

        uint256 pendingRewards = _calculatePendingRewards(tokenId, stake);
        uint256 totalRewards = pendingRewards + (stake.claimedRewards); // Include pending rewards

        // Calculate penalty
        uint256 penaltyAmount = 0;
        if (block.timestamp < stake.startTime + minStakeDurationForNoPenalty) {
            penaltyAmount = (stakeAmount * earlyUnstakePenaltyRate) / PENALTY_RATE_DENOMINATOR;
            // Penalty is applied to the *stake* amount, reducing the amount returned to the user
        }

        // Calculate unstake fee
        uint256 unstakeFee = (stakeAmount * unstakeFeeRate) / UNSTAKE_FEE_DENOMINATOR;
        protocolFeeBalance += unstakeFee; // Collect fee

        uint256 amountToReturn = stakeAmount - penaltyAmount - unstakeFee;

        // Clean up stake data
        delete tokenIdToStake[tokenId];
        _userStakedBalance[owner] -= stakeAmount;
        _totalStaked -= stakeAmount;
        _delegatedManagement[tokenId] = address(0); // Clear delegation

        // Transfer tokens
        if (amountToReturn > 0) {
            require(MORPH_TOKEN.transfer(owner, amountToReturn), "Stake return transfer failed");
        }
        if (pendingRewards > 0) {
             require(MORPH_TOKEN.transfer(owner, pendingRewards), "Reward transfer failed");
        }

        // Burn the NFT
        _burn(tokenId);

        emit Unstaked(owner, tokenId, stakeAmount, totalRewards, penaltyAmount + unstakeFee);
    }

    /// @notice Claims accumulated MORPH rewards for multiple NFTs.
    /// @param tokenIds An array of Morphling NFT IDs to claim rewards for.
    function claimRewards(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 totalRewardsToClaim = 0;
        address user = msg.sender;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check ownership or delegation
            require(ownerOf(tokenId) == user || _delegatedManagement[tokenId] == user, "Not authorized for one or more NFTs");
            require(tokenIdToStake[tokenId].amount > 0, "One or more NFTs not staked");

            Stake storage stake = tokenIdToStake[tokenId];
            uint256 pending = _calculatePendingRewards(tokenId, stake);

            if (pending > 0) {
                totalRewardsToClaim += pending;
                stake.claimedRewards += pending;
                stake.lastClaimTime = block.timestamp;
            }
        }

        if (totalRewardsToClaim > 0) {
            require(MORPH_TOKEN.transfer(user, totalRewardsToClaim), "Reward claim transfer failed");
            emit RewardsClaimed(user, tokenIds, totalRewardsToClaim);
        }
    }

    /// @notice Adds more MORPH tokens to an existing Morphling NFT's stake.
    /// @param tokenId The ID of the Morphling NFT.
    /// @param amount The amount of MORPH tokens to add.
    function depositMoreIntoNftStake(uint256 tokenId, uint256 amount) external onlyStaked onlyNftOwnerOrDelegate(tokenId) whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        address owner = ownerOf(tokenId);

        // First, claim pending rewards for this NFT before modifying the stake
        uint256 pending = _calculatePendingRewards(tokenId, tokenIdToStake[tokenId]);
        if (pending > 0) {
            tokenIdToStake[tokenId].claimedRewards += pending;
            tokenIdToStake[tokenId].lastClaimTime = block.timestamp;
            require(MORPH_TOKEN.transfer(owner, pending), "Pending reward claim failed");
        }

        require(MORPH_TOKEN.transferFrom(msg.sender, address(this), amount), "MORPH transfer failed");

        // Update stake data
        tokenIdToStake[tokenId].amount += amount;
        _userStakedBalance[owner] += amount;
        _totalStaked += amount;

        emit DepositMore(msg.sender, tokenId, amount);
    }

     /// @notice Claims rewards for an NFT and immediately restakes them into the SAME NFT.
    /// @param tokenId The ID of the Morphling NFT.
    function compoundRewardsForNft(uint256 tokenId) external onlyStaked onlyNftOwnerOrDelegate(tokenId) whenNotPaused {
        Stake storage stake = tokenIdToStake[tokenId];
        uint256 pending = _calculatePendingRewards(tokenId, stake);

        if (pending > 0) {
            // Rewards are added to the stake amount directly
            stake.amount += pending;
            stake.claimedRewards += pending; // Count these as claimed towards trait evolution
            stake.lastClaimTime = block.timestamp; // Reset claim time

             // Update total staked balances (user total already reflects it, only need contract total)
            _totalStaked += pending;

            // No need to transfer tokens out and back in, just update the internal stake amount

            emit DepositMore(ownerOf(tokenId), tokenId, pending); // Use DepositMore event for simplicity
            emit RewardsClaimed(ownerOf(tokenId), new uint256[](1){tokenIds[0] = tokenId}, pending); // Also emit RewardsClaimed
        }
    }

    /// @notice Claims rewards for an NFT and immediately deposits them as a NEW stake (mints a new NFT).
    /// @param tokenId The ID of the Morphling NFT to claim from.
    function claimAndRestakeForNft(uint256 tokenId) external onlyStaked onlyNftOwnerOrDelegate(tokenId) whenNotPaused {
        Stake storage stake = tokenIdToStake[tokenId];
        uint256 pending = _calculatePendingRewards(tokenId, stake);

        if (pending > 0) {
            stake.claimedRewards += pending;
            stake.lastClaimTime = block.timestamp;

            // Stake the claimed rewards as a new deposit
            // Important: Transfer needs to happen internally, from contract balance to contract balance
            // ERC20 standard transferFrom needs allowance if from user, but here it's internal contract logic.
            // We assume the contract has enough balance from previous stakes.
            // Alternatively, transfer to user, then user approves & calls depositMorph.
            // Let's do the simpler internal transfer model for this example.
            // require(MORPH_TOKEN.transferFrom(address(this), address(this), pending), "Internal transfer failed"); // Not standard/possible ERC20

            // Simpler approach: Directly mint a new NFT and record the stake amount
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();

            _safeMint(ownerOf(tokenId), newTokenId); // Mint to the owner of the original NFT

            Stake memory newStake = Stake({
                amount: pending,
                startTime: uint64(block.timestamp),
                claimedRewards: 0,
                lastClaimTime: block.timestamp
            });
            tokenIdToStake[newTokenId] = newStake;

            // Update user total staked balance and global total
            _userStakedBalance[ownerOf(tokenId)] += pending;
            _totalStaked += pending;

            emit RewardsClaimed(ownerOf(tokenId), new uint256[](1){tokenIds[0] = tokenId}, pending);
            emit Staked(ownerOf(tokenId), newTokenId, pending, address(0)); // No referrer for compounded stake
        }
    }

    /// @notice Alias for withdrawMorph. Unstakes and burns the NFT.
    /// @param tokenId The ID of the Morphling NFT.
    function unstakeMorphling(uint256 tokenId) external {
        withdrawMorph(tokenId);
    }

    // --- Dynamic NFT & Data Retrieval Functions ---

    /// @notice Calculates pending MORPH rewards for a specific NFT.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return The amount of pending rewards.
    function getPendingRewards(uint256 tokenId) public view onlyStaked returns (uint256) {
        Stake storage stake = tokenIdToStake[tokenId];
        return _calculatePendingRewards(tokenId, stake);
    }

    /// @dev Internal helper to calculate pending rewards.
    function _calculatePendingRewards(uint256 tokenId, Stake storage stake) internal view returns (uint256) {
         if (stake.amount == 0 || block.timestamp <= stake.lastClaimTime) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - stake.lastClaimTime;
        // Avoid overflow if stake amount is very large
        uint256 rewards = (stake.amount / REWARD_RATE_DENOMINATOR) * rewardRatePerSecond * timeElapsed;
        // Add remaining rewards from non-integer division part
        rewards += ((stake.amount % REWARD_RATE_DENOMINATOR) * rewardRatePerSecond / REWARD_RATE_DENOMINATOR) * timeElapsed;
        return rewards;
    }

    /// @notice Calculates and returns the current on-chain traits of a Morphling NFT.
    /// Traits are derived from staking data (amount, duration, claimed rewards).
    /// @param tokenId The ID of the Morphling NFT.
    /// @return A string representing the NFT's current traits.
    function getMorphlingTraits(uint256 tokenId) public view onlyStaked returns (string memory) {
        Stake storage stake = tokenIdToStake[tokenId];
        EvolutionStage stage = getCurrentEvolutionStage(tokenId);

        string memory stageDescription;
        if (stage == EvolutionStage.Egg) stageDescription = "Egg";
        else if (stage == EvolutionStage.Hatchling) stageDescription = "Hatchling";
        else if (stage == EvolutionStage.Juvenile) stageDescription = "Juvenile";
        else if (stage == EvolutionStage.Adult) stageDescription = "Adult";
        else if (stage == EvolutionStage.Apex) stageDescription = "Apex";

        uint256 pendingRewards = _calculatePendingRewards(tokenId, stake);
        uint256 totalClaimed = stake.claimedRewards;
        uint256 totalEarned = pendingRewards + totalClaimed;
        uint256 duration = block.timestamp - stake.startTime;

        // Example traits based on state - can be expanded
        string memory traits = string(abi.encodePacked(
            '{',
            '"stage": "', stageDescription, '",',
            '"stakeAmount": ', stake.amount.toString(), ',',
            '"stakedDuration": ', duration.toString(), ',"s",', // Duration in seconds
            '"rewardsEarnedTotal": ', totalEarned.toString(), ',',
             '"rewardsPending": ', pendingRewards.toString(),
            '}'
        ));
        return traits;
    }

    /// @notice Determines the evolution stage of an NFT based on defined thresholds.
    /// Checks thresholds for stake amount, duration, and claimed rewards.
    /// An NFT is the highest stage it qualifies for based on *any* of the criteria.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return The EvolutionStage enum value.
    function getCurrentEvolutionStage(uint256 tokenId) public view onlyStaked returns (EvolutionStage) {
        Stake storage stake = tokenIdToStake[tokenId];
        uint256 currentStake = stake.amount;
        uint256 currentDuration = block.timestamp - stake.startTime;
        uint256 totalRewardsClaimed = stake.claimedRewards; // Only claimed counts towards this threshold

        uint8 stage = 0; // Start at Egg (stage 0)

        // Ensure thresholds are correctly sized, minimum size 0, max size EvolutionStage - 1
        uint8 maxStageIndex = uint8(EvolutionStage.Apex) - 1;
        uint8 stakeThresholdCount = uint8(evolutionStakeThresholds.length);
        uint8 durationThresholdCount = uint8(evolutionDurationThresholds.length);
        uint8 rewardThresholdCount = uint8(evolutionRewardClaimThresholds.length);

        // Determine stage based on stake amount
        for (uint8 i = 0; i < stakeThresholdCount && i <= maxStageIndex; i++) {
            if (currentStake >= evolutionStakeThresholds[i]) {
                if (i + 1 > stage) stage = i + 1;
            } else {
                break; // Thresholds are expected to be increasing
            }
        }

        // Determine stage based on duration
         for (uint8 i = 0; i < durationThresholdCount && i <= maxStageIndex; i++) {
            if (currentDuration >= evolutionDurationThresholds[i]) {
                 if (i + 1 > stage) stage = i + 1;
            } else {
                break;
            }
        }

        // Determine stage based on rewards claimed
         for (uint8 i = 0; i < rewardThresholdCount && i <= maxStageIndex; i++) {
            if (totalRewardsClaimed >= evolutionRewardClaimThresholds[i]) {
                 if (i + 1 > stage) stage = i + 1;
            } else {
                break;
            }
        }

        return EvolutionStage(stage);
    }

    /// @notice Returns the JSON data URI for a Morphling NFT, including dynamic traits.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return A data URI string.
    function tokenURI(uint256 tokenId) public view override onlyStaked returns (string memory) {
        require(_exists(tokenId), "ERC721: token query for nonexistent token");

        Stake storage stake = tokenIdToStake[tokenId];
        EvolutionStage stage = getCurrentEvolutionStage(tokenId);
        string memory traitsJson = getMorphlingTraits(tokenId);

        string memory name;
        string memory description;
        string memory image; // Placeholder for image URL/SVG

        if (stage == EvolutionStage.Egg) {
            name = "MetaMorph Egg #" + tokenId.toString();
            description = "A nascent Morphling, waiting to hatch.";
            image = "ipfs://Qm.../egg.png"; // Replace with actual IPFS hash
        } else if (stage == EvolutionStage.Hatchling) {
            name = "MetaMorph Hatchling #" + tokenId.toString();
            description = "Newly hatched Morphling, beginning to grow.";
             image = "ipfs://Qm.../hatchling.png"; // Replace
        } else if (stage == EvolutionStage.Juvenile) {
            name = "MetaMorph Juvenile #" + tokenId.toString();
            description = "A young Morphling, actively developing.";
             image = "ipfs://Qm.../juvenile.png"; // Replace
        } else if (stage == EvolutionStage.Adult) {
            name = "MetaMorph Adult #" + tokenId.toString();
            description = "A mature Morphling, strong and capable.";
             image = "ipfs://Qm.../adult.png"; // Replace
        } else if (stage == EvolutionStage.Apex) {
            name = "MetaMorph Apex #" + tokenId.toString();
            description = "An ultimate Morphling, fully evolved.";
             image = "ipfs://Qm.../apex.png"; // Replace
        } else {
             name = "MetaMorph Unknown Stage #" + tokenId.toString();
             description = "A Morphling in an unknown evolutionary state.";
              image = "ipfs://Qm.../unknown.png"; // Replace
        }

        // Basic JSON structure for NFT metadata
        string memory json = string(abi.encodePacked(
            '{',
            '"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",', // Can be an SVG data URI for fully on-chain image
            '"attributes": [',
                // Include base attributes
                string(abi.encodePacked('{ "trait_type": "Evolution Stage", "value": "', name, '" }')), ',',
                string(abi.encodePacked('{ "trait_type": "Staked Amount", "value": "', stake.amount.toString(), '" }')), ',',
                string(abi.encodePacked('{ "trait_type": "Staked Since", "value": "', stake.startTime.toString(), '" }')), ',', // Timestamp
                string(abi.encodePacked('{ "trait_type": "Total Rewards Claimed", "value": "', stake.claimedRewards.toString(), '" }')), ',',
                string(abi.encodePacked('{ "trait_type": "Pending Rewards", "value": "', _calculatePendingRewards(tokenId, stake).toString(), '" }')),
                // Add more dynamic traits derived from `traitsJson` if needed, requires parsing json in solidity which is complex.
                // For this example, we'll just include the raw traitsJson output in a custom field or parse simple values.
                // Let's parse simple values from the output of getMorphlingTraits for attribute array
                 // ... (add more derived attributes here if needed, parsing traitsJson)
            ']', // end attributes array
            // Optionally add the raw trait JSON string
            ', "dynamic_traits_data": ', traitsJson, // Include the raw JSON string
            '}'
        ));

        // Return data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Checks if a specific Morphling NFT is currently linked to an active stake.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return True if staked, false otherwise.
    function isMorphlingStaked(uint256 tokenId) public view returns (bool) {
        return tokenIdToStake[tokenId].amount > 0;
    }

     /// @notice Retrieves comprehensive staking data for a specific NFT.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return A tuple containing stake amount, start time, claimed rewards, and last claim time.
    function getNftStakingDetails(uint256 tokenId) public view onlyStaked returns (uint256 amount, uint64 startTime, uint256 claimedRewards, uint256 lastClaimTime) {
        Stake storage stake = tokenIdToStake[tokenId];
        return (stake.amount, stake.startTime, stake.claimedRewards, stake.lastClaimTime);
    }

    /// @notice Gets the total MORPH tokens staked by a specific user.
    /// @param user The address of the user.
    /// @return The total staked amount.
    function getUserStakedBalance(address user) public view returns (uint256) {
        return _userStakedBalance[user];
    }

     /// @notice Gets a list of Morphling NFT IDs owned by a user.
    /// Uses ERC721Enumerable.
    /// @param user The address of the user.
    /// @return An array of NFT IDs.
    function getOwnedMorphlings(address user) public view returns (uint256[] memory) {
         uint256 tokenCount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    // --- Delegated Management Functions ---

    /// @notice Owner delegates management control for an NFT to another address.
    /// The delegate can call stake/claim/unstake functions for this specific NFT.
    /// @param tokenId The ID of the Morphling NFT.
    /// @param delegate The address to delegate management to. Set to address(0) to revoke.
    function delegateManagement(uint256 tokenId, address delegate) external onlyStaked {
        require(ownerOf(tokenId) == msg.sender, "Must be NFT owner to delegate");
        _delegatedManagement[tokenId] = delegate;
        emit ManagementDelegated(tokenId, msg.sender, delegate);
    }

    /// @notice Owner revokes delegated management for an NFT.
    /// @param tokenId The ID of the Morphling NFT.
    function revokeManagement(uint256 tokenId) external onlyStaked {
        delegateManagement(tokenId, address(0)); // Setting delegate to address(0) revokes
        emit ManagementRevoked(tokenId, msg.sender, _delegatedManagement[tokenId]); // Emit with old delegate before clearing
    }

    /// @notice Gets the address delegated to manage a specific NFT.
    /// @param tokenId The ID of the Morphling NFT.
    /// @return The delegated address, or address(0) if none.
    function getDelegate(uint256 tokenId) public view returns (address) {
        return _delegatedManagement[tokenId];
    }

    // --- Referral System Functions ---

    /// @dev Internal function to record a successful referral.
    function _recordReferral(address newUser, address referrer) internal {
        // Ensure referrer is approved and not the new user themselves
        // isApprovedReferrer check already done in depositMorph
        require(referrer != address(0) && referrer != newUser, "Invalid referrer");

        // Prevent multiple referrals for the same user from the same referrer
        // (Could add a mapping to track this if needed, but simple count is fine for example)

        _referralRewards[referrer] += referralRewardAmount;
        emit ReferralRecorded(newUser, referrer);
    }

    /// @notice Allows approved referrers to claim their accumulated referral rewards.
    function claimReferralRewards() external {
         require(isApprovedReferrer[msg.sender], "Not an approved referrer");
         uint256 rewards = _referralRewards[msg.sender];
         if (rewards > 0) {
             _referralRewards[msg.sender] = 0;
             require(MORPH_TOKEN.transfer(msg.sender, rewards), "Referral reward transfer failed");
             emit ReferralRewardsClaimed(msg.sender, rewards);
         }
    }

     /// @notice Gets the pending referral rewards for a specific referrer.
    /// @param referrer The address of the referrer.
    /// @return The amount of pending referral rewards.
    function getPendingReferralRewards(address referrer) public view returns (uint256) {
        return _referralRewards[referrer];
    }

    // --- Admin/Protocol Control Functions ---

    /// @notice Admin sets the base reward rate per second per unit of stake.
    /// Requires CONFIGURER_ROLE.
    /// @param newRatePerSecond The new reward rate.
    function setRewardRate(uint256 newRatePerSecond) external onlyRole(CONFIGURER_ROLE) {
        rewardRatePerSecond = newRatePerSecond;
        emit RewardRateSet(newRatePerSecond);
    }

    /// @notice Admin sets the thresholds for NFT evolution stages.
    /// Thresholds must be strictly increasing for each category.
    /// Requires CONFIGURER_ROLE.
    /// @param _evolutionStakeThresholds MORPH amount thresholds.
    /// @param _evolutionDurationThresholds Duration (seconds) thresholds.
    /// @param _evolutionRewardClaimThresholds Claimed MORPH thresholds.
    function setEvolutionThresholds(
        uint256[] memory _evolutionStakeThresholds,
        uint256[] memory _evolutionDurationThresholds,
        uint256[] memory _evolutionRewardClaimThresholds
    ) public onlyRole(CONFIGURER_ROLE) {
        uint8 maxStageIndex = uint8(EvolutionStage.Apex) - 1; // Apex is the highest possible reached stage

        require(_evolutionStakeThresholds.length <= maxStageIndex, "Too many stake thresholds");
        require(_evolutionDurationThresholds.length <= maxStageIndex, "Too many duration thresholds");
        require(_evolutionRewardClaimThresholds.length <= maxStageIndex, "Too many reward thresholds");

        // Basic checks for increasing order
        for(uint i = 0; i < _evolutionStakeThresholds.length - 1; i++) {
            require(_evolutionStakeThresholds[i] < _evolutionStakeThresholds[i+1], "Stake thresholds not increasing");
        }
         for(uint i = 0; i < _evolutionDurationThresholds.length - 1; i++) {
            require(_evolutionDurationThresholds[i] < _evolutionDurationThresholds[i+1], "Duration thresholds not increasing");
        }
         for(uint i = 0; i < _evolutionRewardClaimThresholds.length - 1; i++) {
            require(_evolutionRewardClaimThresholds[i] < _evolutionRewardClaimThresholds[i+1], "Reward thresholds not increasing");
        }

        evolutionStakeThresholds = _evolutionStakeThresholds;
        evolutionDurationThresholds = _evolutionDurationThresholds;
        evolutionRewardClaimThresholds = _evolutionRewardClaimThresholds;

        emit EvolutionThresholdsSet(_evolutionStakeThresholds, _evolutionDurationThresholds, _evolutionRewardClaimThresholds);
    }

     /// @notice Admin sets the percentage penalty for unstaking before minStakeDurationForNoPenalty.
    /// Rate is per 10000 (e.g., 500 = 5%). Max 10000 (100%).
    /// Requires CONFIGURER_ROLE.
    /// @param newRate The new penalty rate.
    function setEarlyUnstakePenaltyRate(uint256 newRate) external onlyRole(CONFIGURER_ROLE) {
        require(newRate <= PENALTY_RATE_DENOMINATOR, "Penalty rate cannot exceed 100%");
        earlyUnstakePenaltyRate = newRate;
        emit PenaltyRateSet(newRate);
    }

    /// @notice Admin sets the percentage fee collected by the protocol on unstaking.
    /// Rate is per 10000 (e.g., 100 = 1%). Max 10000 (100%).
    /// Requires CONFIGURER_ROLE.
    /// @param newRate The new unstake fee rate.
    function setUnstakeFeeRate(uint256 newRate) external onlyRole(CONFIGURER_ROLE) {
         require(newRate <= UNSTAKE_FEE_DENOMINATOR, "Unstake fee rate cannot exceed 100%");
        unstakeFeeRate = newRate;
        emit UnstakeFeeRateSet(newRate);
    }

    /// @notice Admin sets the minimum duration stake must be active to avoid early unstake penalty.
    /// Requires CONFIGURER_ROLE.
    /// @param duration The minimum duration in seconds.
    function setMinStakeDurationForNoPenalty(uint256 duration) external onlyRole(CONFIGURER_ROLE) {
        minStakeDurationForNoPenalty = duration;
        emit MinStakeDurationSet(duration);
    }

    /// @notice Admin sets the fixed MORPH amount awarded per successful referral.
    /// Requires REFERRER_ADMIN_ROLE.
    /// @param amount The amount of MORPH per referral.
    function setReferralRewardAmount(uint256 amount) external onlyRole(REFERRER_ADMIN_ROLE) {
        referralRewardAmount = amount;
        emit ReferralRewardAmountSet(amount);
    }

    /// @notice Admin adds an address to the approved referrer list.
    /// Only approved addresses can earn referral rewards.
    /// Requires REFERRER_ADMIN_ROLE.
    /// @param referrer The address to approve.
    function addApprovedReferrer(address referrer) external onlyRole(REFERRER_ADMIN_ROLE) {
        isApprovedReferrer[referrer] = true;
    }

    /// @notice Admin removes an address from the approved referrer list.
    /// Requires REFERRER_ADMIN_ROLE.
    /// @param referrer The address to remove.
    function removeApprovedReferrer(address referrer) external onlyRole(REFERRER_ADMIN_ROLE) {
        isApprovedReferrer[referrer] = false;
    }

    /// @notice Admin pauses staking, unstaking, claiming, and depositMore operations.
    /// Requires PAUSER_ROLE.
    function pauseStaking() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Admin unpauses staking operations.
    /// Requires PAUSER_ROLE.
    function unpauseStaking() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

     /// @notice Admin withdraws protocol fees collected from unstaking penalties/fees.
    /// Requires DEFAULT_ADMIN_ROLE.
    function withdrawProtocolFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = protocolFeeBalance;
        if (amount > 0) {
            protocolFeeBalance = 0;
            require(MORPH_TOKEN.transfer(msg.sender, amount), "Fee withdrawal failed");
            emit ProtocolFeeWithdrawn(msg.sender, amount);
        }
    }

    // --- Query Functions (mostly standard or simple getters) ---

    /// @notice Returns the total MORPH tokens currently staked in the protocol.
    function getTotalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /// @notice Checks if an address is an approved referrer.
    /// @param referrer The address to check.
    /// @return True if approved, false otherwise.
    function isApprovedReferrer(address referrer) public view returns (bool) {
         return isApprovedReferrer[referrer]; // Direct mapping access
    }

    // --- Overrides ---

    /// @dev Override to ensure staked NFTs cannot be transferred via standard ERC721 transfer functions.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of staked NFTs unless transferring to/from address(0) (mint/burn)
        if (from != address(0) && to != address(0)) {
             require(!isMorphlingStaked(tokenId), "Staked NFT cannot be transferred");
        }

        // Clear delegation on transfer (shouldn't happen if staked, but safety)
        if (from != address(0) && to != address(0)) {
             delete _delegatedManagement[tokenId];
        }
    }

    /// @dev Override to handle role checks.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // ERC721Enumerable requires these standard overrides
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _decreaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._decreaseBalance(account, value);
    }

    function _nextTokenId() internal override(ERC721, ERC721Enumerable) view returns (uint256) {
         return _tokenIdCounter.current() + 1; // ERC721Enumerable expects next available ID
    }
}
```