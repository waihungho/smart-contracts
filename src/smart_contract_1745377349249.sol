```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title AuraGuilds: Dynamic NFT Staking, Guilds, and Resource Management
 * @dev This contract implements a complex system involving:
 *      1. Dynamic Aura NFTs: NFTs gain "Aura Power" over time when staked.
 *      2. Gamified Staking: Stake NFTs in Guilds to earn Reward Tokens and Essence.
 *      3. Guild System: Users can create, join, and leave Guilds. Guilds aggregate the power of staked NFTs.
 *      4. Essence Resource: A secondary resource earned via staking, used for actions like instantly leveling up Aura Power.
 *      5. Parameterized System: Key rates and limits are adjustable by the owner.
 *      6. Reward Pool: Reward tokens are distributed by the owner into a pool, claimable by stakers.
 *
 * Outline:
 * 1. State Variables: Core data storage for NFTs, staking, guilds, resources, parameters.
 * 2. Structs: Define structure for Guild data.
 * 3. Events: Announce key actions.
 * 4. Modifiers: Restrict access to functions.
 * 5. Constructor: Initialize contract owner and reward token address.
 * 6. Internal Helpers: Logic for calculating and accruing staking gains, guild member management.
 * 7. ERC721 Overrides: Handle logic on token transfer.
 * 8. Minting Functions: Create new Aura NFTs.
 * 9. NFT State & Query Functions: Retrieve NFT details, calculate pending gains.
 * 10. Staking Functions: Stake/Unstake NFTs into Guilds.
 * 11. Guild Management Functions: Create, join, leave guilds, query guild info.
 * 12. Resource & Power Functions: Get Essence balance, use Essence to level up Aura.
 * 13. Reward Functions: Get claimable rewards, claim earned Reward Tokens from the pool.
 * 14. Admin & Parameter Functions: Owner-only functions to manage the system, distribute rewards, withdraw stuck tokens, set parameters.
 * 15. Global State Queries: Get total staked power and reward pool balance.
 * 16. Fallback/Receive: Prevent accidental Ether transfers.
 *
 * Function Summary:
 * - Constructor: (1) Sets initial parameters, reward token.
 * - ERC721 (Enumerable): (8 Standard + 1 Override) balanceOf, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom, _update.
 * - Internal Helpers: (2) _calculateStakingGains, _accrueStakingGains.
 * - Minting: (1) mint.
 * - NFT Queries: (4) getAuraPower, getLastStakedTime, getStakedGuildId, calculatePendingGains.
 * - Staking: (2) stakeIntoGuild, unstakeFromGuild.
 * - Guild Management: (6) createGuild, joinGuild, leaveGuild, getGuildDetails, getGuildMembers, isGuildMember, getGuildTotalPower.
 * - Resource/Power: (2) getEssenceBalance, levelUpAura.
 * - Rewards: (2) getUserClaimableRewards, claimAllStakedGainsForOwnedTokens.
 * - Admin/Parameters: (7) distributeRewardsToPool, withdrawStuckTokens, setStakingRewardRate, setPowerGainRate, setEssenceGainRate, setLevelUpEssenceCostMultiplier, setMaxGuildSize.
 * - Global Queries: (2) getTotalStakedPower, getGlobalRewardPoolBalance.
 * - Fallback/Receive: (2) receive, fallback.
 *
 * Total Public/External Functions: 1+8+1+4+2+6+2+2+7+2+2 = 37.
 * Total Internal/Overridden: 2+1 = 3.
 * Total Functions (incl. internal/overrides): 40.
 */
contract AuraGuilds is ERC721Enumerable, Ownable {

    // --- State Variables ---

    // NFT State
    /// @dev Maps tokenId to its current Aura Power.
    mapping(uint256 => uint256) public auraPower;
    /// @dev Maps tokenId to the timestamp when its staking gains were last accrued.
    mapping(uint256 => uint64) public lastStakedTimestamp;
    /// @dev Maps tokenId to the Guild ID it is staked in (0 if not staked).
    mapping(uint256 => uint256) public stakedGuildId;

    // Guild State
    struct Guild {
        string name;
        address leader;
        address[] members; // List of addresses that are members of the guild
    }
    /// @dev Maps Guild ID to Guild details.
    mapping(uint256 => Guild) public guilds;
    /// @dev Counter for the next available Guild ID.
    uint256 public nextGuildId = 1; // Guild IDs start from 1

    /// @dev Maps Guild ID to the sum of Aura Power of all staked tokens within that guild.
    mapping(uint256 => uint256) public totalGuildPower;
    /// @dev Total sum of Aura Power of all tokens staked across all guilds.
    uint256 public totalStakedPower;

    // User State
    /// @dev Maps user address to their current Essence balance.
    mapping(address => uint256) public essenceBalance;
    /// @dev Maps user address to the amount of Reward Tokens they have accrued but not yet claimed.
    mapping(address => uint256) public userClaimableRewards;

    // System Parameters (Adjustable by Owner)
    /// @dev Rate of Reward Tokens earned per Aura Power per second staked (in base units of Reward Token).
    uint256 public stakingRewardRatePerPowerPerSecond;
    /// @dev Rate of Aura Power gained per second staked (using 1e18 precision).
    uint256 public powerGainRatePerSecondStaked;
    /// @dev Rate of Essence gained per second staked (using 1e18 precision).
    uint256 public essenceGainRatePerSecondStaked;
    /// @dev Multiplier for Essence cost to level up Aura Power: currentPower * multiplier.
    uint256 public levelUpEssenceCostMultiplier;
    /// @dev Maximum number of members allowed per guild (0 for no limit).
    uint256 public maxGuildSize;

    // Reward Token
    /// @dev Address of the ERC20 token used for rewards.
    IERC20 public rewardToken;

    // --- Events ---

    /// @dev Emitted when a new Aura NFT is minted.
    event Minted(address indexed owner, uint256 indexed tokenId, uint256 initialPower);
    /// @dev Emitted when an NFT is staked into a Guild.
    event Staked(uint256 indexed tokenId, uint256 indexed guildId, address indexed staker);
    /// @dev Emitted when an NFT is unstaked from a Guild.
    event Unstaked(uint256 indexed tokenId, uint256 indexed guildId, address indexed staker);
    /// @dev Emitted when a new Guild is created.
    event GuildCreated(uint256 indexed guildId, string name, address indexed leader);
    /// @dev Emitted when a user joins a Guild.
    event GuildJoined(uint256 indexed guildId, address indexed member);
    /// @dev Emitted when a user leaves a Guild.
    event GuildLeft(uint256 indexed guildId, address indexed member);
    /// @dev Emitted when an NFT's Aura Power is increased via Essence.
    event AuraLeveledUp(uint256 indexed tokenId, uint256 oldPower, uint256 newPower, uint256 essenceBurned);
    /// @dev Emitted when Essence is gained (as part of _accrueStakingGains).
    event EssenceGained(address indexed owner, uint256 amount);
     /// @dev Emitted when Aura Power is gained from staking (as part of _accrueStakingGains).
    event PowerGainedFromStaking(uint256 indexed tokenId, uint256 amount);
    /// @dev Emitted when accrued Reward Tokens are claimed by a user.
    event RewardsClaimed(address indexed owner, uint256 amount);
    /// @dev Emitted when Reward Tokens are added to the contract's pool.
    event RewardsDistributed(address indexed distributor, uint256 amount);
    /// @dev Emitted when an adjustable parameter is updated by the owner.
    event ParameterUpdated(string name, uint256 oldValue, uint256 newValue);
    /// @dev Emitted when accidental ERC20 tokens (not the reward token) are withdrawn by the owner.
    event StuckTokensWithdrawn(address indexed token, address indexed receiver, uint256 amount);

    // --- Modifiers ---

    /// @dev Throws if the caller is not the leader of the specified guild.
    modifier onlyGuildLeader(uint256 _guildId) {
        require(guilds[_guildId].leader == _msgSender(), "AG: Not guild leader");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the contract, setting the reward token and initial parameters.
     * @param _rewardTokenAddress The address of the ERC20 token used for rewards.
     */
    constructor(address _rewardTokenAddress)
        ERC721("Aura Guardian NFT", "AURA")
        Ownable(_msgSender())
    {
        require(_rewardTokenAddress != address(0), "AG: Invalid reward token address");
        rewardToken = IERC20(_rewardTokenAddress);

        // Set initial default parameters (example values)
        // Rates use 1e18 precision for fractional calculations
        stakingRewardRatePerPowerPerSecond = 1e15; // 0.001 reward token per power per second
        powerGainRatePerSecondStaked = 1e15; // 0.001 power per second (1e18 precision)
        essenceGainRatePerSecondStaked = 5e15; // 0.005 essence per second (1e18 precision)
        levelUpEssenceCostMultiplier = 100; // 100 essence per current power to level up
        maxGuildSize = 50; // Max 50 members per guild (0 for unlimited)
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal view function to calculate potential staking gains (rewards, power, essence)
     *      since the last update timestamp. Does not modify state. Returns values with 1e18 precision.
     * @param _tokenId The ID of the NFT.
     * @return potentialRewards Potential reward tokens earned (1e18 precision).
     * @return potentialPower Potential power gained (1e18 precision).
     * @return potentialEssence Potential essence gained (1e18 precision).
     */
    function _calculateStakingGains(uint256 _tokenId)
        internal
        view
        returns (uint256 potentialRewards, uint256 potentialPower, uint256 potentialEssence)
    {
        uint256 lastUpdated = lastStakedTimestamp[_tokenId];
        // No gains if not staked, no aura power, or timestamp is 0 (not initialized/staked)
        if (lastUpdated == 0 || stakedGuildId[_tokenId] == 0 || auraPower[_tokenId] == 0) {
            return (0, 0, 0);
        }

        uint256 timeStaked = block.timestamp - lastUpdated;
        uint256 currentPower = auraPower[_tokenId];

        // Calculate gains using 1e18 precision for rates and results
        // potential = base * time * rate (rate is 1e18 scaled) / 1e18
        potentialRewards = (currentPower * timeStaked * stakingRewardRatePerPowerPerSecond) / (1e18);
        potentialPower = (currentPower * timeStaked * powerGainRatePerSecondStaked) / (1e18);
        potentialEssence = (currentPower * timeStaked * essenceGainRatePerSecondStaked) / (1e18);

        return (potentialRewards, potentialPower, potentialEssence);
    }

    /**
     * @dev Internal function to accrue staking gains (rewards, power, essence) for a token.
     *      Calculates gains since last update, adds to user's balances/NFT power, and resets timestamp.
     *      Does NOT perform actual reward token transfer (handled by claimAllStakedGainsForOwnedTokens).
     * @param _tokenId The ID of the NFT.
     */
    function _accrueStakingGains(uint256 _tokenId) internal {
        address nftOwner = ownerOf(_tokenId);
        (uint256 potentialRewards1e18, uint256 potentialPower1e18, uint256 potentialEssence1e18) = _calculateStakingGains(_tokenId);

        // Only update timestamp if it was previously staked and had aura power, and gains were possible
        if (stakedGuildId[_tokenId] != 0 && auraPower[_tokenId] > 0) {
             // Add potential rewards (which are in 1e18 precision) to user's claimable balance
             userClaimableRewards[nftOwner] += potentialRewards1e18; // Store as 1e18 precision internally

            // Add scaled power gain to auraPower
            uint256 gainedPower = potentialPower1e18 / (1e18);
            if (gainedPower > 0) {
                 auraPower[_tokenId] += gainedPower;
                 emit PowerGainedFromStaking(_tokenId, gainedPower);

                 // Update total guild/global power if staked
                 uint256 gId = stakedGuildId[_tokenId];
                 if (gId != 0) {
                     totalGuildPower[gId] += gainedPower;
                 }
                 totalStakedPower += gainedPower;
            }

             // Add scaled essence gain to essenceBalance
             uint256 gainedEssence = potentialEssence1e18 / (1e18);
             if (gainedEssence > 0) {
                 essenceBalance[nftOwner] += gainedEssence;
                 emit EssenceGained(nftOwner, gainedEssence);
             }

            lastStakedTimestamp[_tokenId] = uint64(block.timestamp);
        }
    }

    /**
     * @dev Internal helper to remove a member from a guild. Assumes guildId and member exist.
     *      Uses a loop which can be gas-intensive for large guilds.
     *      Could be optimized with a mapping if necessary for larger member counts.
     * @param _guildId The ID of the guild.
     * @param _member The address of the member to remove.
     */
    function _removeGuildMember(uint256 _guildId, address _member) internal {
        address[] storage members = guilds[_guildId].members;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                // Move the last element into the found position and pop the last
                members[i] = members[members.length - 1];
                members.pop();
                break; // Assumes one entry per member address
            }
        }
    }

    // --- ERC721 Overrides ---

    /// @dev Override to prevent transferring staked tokens.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        // Check if the token is currently staked before allowing transfer
        if (stakedGuildId[tokenId] != 0) {
             // Note: This check prevents _update from being called on staked tokens via transfer/safeTransferFrom.
             // ERC721Enumerable's _update handles the token counting logic needed for enumeration.
             revert("AG: Cannot transfer staked NFT");
        }
        address from = ERC721._update(to, tokenId, auth);
        return from;
    }

    // --- Minting Functions ---

    /**
     * @dev Mints a new Aura NFT to an address with a specified initial power.
     *      Only callable by the contract owner.
     * @param _to The address to mint the NFT to.
     * @param _initialPower The starting Aura Power of the NFT.
     */
    function mint(address _to, uint256 _initialPower) public onlyOwner {
        uint256 newItemId = totalSupply() + 1; // Simple incrementing ID, assumes no burning or careful re-use
        _mint(_to, newItemId);
        auraPower[newItemId] = _initialPower;
        lastStakedTimestamp[newItemId] = uint64(block.timestamp); // Initialize timestamp for gains calculation
        emit Minted(_to, newItemId, _initialPower);
    }

    // --- NFT State & Query Functions ---

    /**
     * @dev Get the Aura Power of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The Aura Power of the NFT.
     */
    function getAuraPower(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "AG: Token does not exist");
        return auraPower[_tokenId];
    }

    /**
     * @dev Get the last timestamp when a staked NFT's gains were calculated/accrued.
     * @param _tokenId The ID of the NFT.
     * @return The timestamp (uint64).
     */
    function getLastStakedTime(uint256 _tokenId) public view returns (uint64) {
         require(_exists(_tokenId), "AG: Token does not exist");
         return lastStakedTimestamp[_tokenId];
    }

    /**
     * @dev Get the Guild ID that an NFT is currently staked in.
     * @param _tokenId The ID of the NFT.
     * @return The Guild ID (0 if not staked).
     */
    function getStakedGuildId(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "AG: Token does not exist");
        return stakedGuildId[_tokenId];
    }

    /**
     * @dev Calculate the pending staking gains (rewards, power, essence) for a specific NFT
     *      since its last update timestamp. This is a view function and does not change state.
     *      Returns values with 1e18 precision for all gains.
     * @param _tokenId The ID of the NFT.
     * @return potentialRewards Potential reward tokens (1e18 precision).
     * @return potentialPower Potential power gained (1e18 precision).
     * @return potentialEssence Potential essence gained (1e18 precision).
     */
    function calculatePendingGains(uint256 _tokenId)
        public
        view
        returns (uint256 potentialRewards, uint256 potentialPower, uint256 potentialEssence)
    {
         require(_exists(_tokenId), "AG: Token does not exist");
         require(stakedGuildId[_tokenId] != 0, "AG: Token is not staked");
         require(auraPower[_tokenId] > 0, "AG: Token has 0 power, no gains possible");
         return _calculateStakingGains(_tokenId);
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes an Aura NFT into a specific Guild.
     *      Accrues any pending gains *before* updating staking state.
     * @param _tokenId The ID of the NFT to stake.
     * @param _guildId The ID of the Guild to stake into.
     */
    function stakeIntoGuild(uint256 _tokenId, uint256 _guildId) public {
        require(ownerOf(_tokenId) == _msgSender(), "AG: Caller does not own token");
        require(stakedGuildId[_tokenId] == 0, "AG: Token already staked");
        require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");
        require(auraPower[_tokenId] > 0, "AG: Cannot stake token with 0 power");

        // Check max guild size
        if (maxGuildSize > 0) {
             require(guilds[_guildId].members.length < maxGuildSize, "AG: Guild is full");
        }

        // Accrue any gains since last update (should be 0 here if not staked previously)
        _accrueStakingGains(_tokenId);

        // Update staking state
        stakedGuildId[_tokenId] = _guildId;
        lastStakedTimestamp[_tokenId] = uint64(block.timestamp); // Reset timestamp for new staking period

        // Update guild and global power
        totalGuildPower[_guildId] += auraPower[_tokenId];
        totalStakedPower += auraPower[_tokenId];

        // Add member to guild list if not already present
        bool isMember = false;
        for(uint i=0; i<guilds[_guildId].members.length; i++) {
            if(guilds[_guildId].members[i] == _msgSender()) {
                isMember = true;
                break;
            }
        }
        if (!isMember) {
             guilds[_guildId].members.push(_msgSender());
             emit GuildJoined(_guildId, _msgSender());
        }

        emit Staked(_tokenId, _guildId, _msgSender());
    }

    /**
     * @dev Unstakes an Aura NFT from its current Guild.
     *      Accrues any pending gains *before* updating staking state.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeFromGuild(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == _msgSender(), "AG: Caller does not own token");
        uint256 currentGuildId = stakedGuildId[_tokenId];
        require(currentGuildId != 0, "AG: Token is not staked");

        // Accrue gains BEFORE updating staking state
        _accrueStakingGains(_tokenId);

        // Update guild and global power
        totalGuildPower[currentGuildId] -= auraPower[_tokenId];
        totalStakedPower -= auraPower[_tokenId];

        // Reset staking state
        stakedGuildId[_tokenId] = 0;
        lastStakedTimestamp[_tokenId] = uint64(block.timestamp); // Reset timestamp

        // Note: Member is NOT automatically removed from the guild members list upon unstaking.
        // A user can be a guild member without staking. They must call leaveGuild() explicitly if they wish to leave the guild.

        emit Unstaked(_tokenId, currentGuildId, _msgSender());
    }

    // --- Guild Management Functions ---

    /**
     * @dev Creates a new Guild.
     * @param _name The name of the new Guild.
     */
    function createGuild(string memory _name) public {
        require(bytes(_name).length > 0, "AG: Guild name cannot be empty");
        // Potential additions: require minimum token balance, require a cost in tokens/essence.

        uint256 newGuildId = nextGuildId++;
        guilds[newGuildId] = Guild({
            name: _name,
            leader: _msgSender(),
            members: new address[](0) // Initialize empty members array
        });

        // Creator is automatically the first member
        guilds[newGuildId].members.push(_msgSender());

        emit GuildCreated(newGuildId, _name, _msgSender());
        emit GuildJoined(newGuildId, _msgSender()); // Also emit join event for creator
    }

    /**
     * @dev Allows a user to join an existing Guild.
     * @param _guildId The ID of the Guild to join.
     */
    function joinGuild(uint256 _guildId) public {
        require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");

        // Check if already a member
         require(!isGuildMember(_guildId, _msgSender()), "AG: Already a member of this guild");

         // Check max guild size
        if (maxGuildSize > 0) {
             require(guilds[_guildId].members.length < maxGuildSize, "AG: Guild is full");
        }

        guilds[_guildId].members.push(_msgSender());
        emit GuildJoined(_guildId, _msgSender());
    }

    /**
     * @dev Allows a user to leave a Guild.
     *      Requires unstaking all tokens from the guild first.
     *      The leader cannot leave directly (must transfer leadership first - functionality not included).
     * @param _guildId The ID of the Guild to leave.
     */
    function leaveGuild(uint256 _guildId) public {
        require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");

        // Check if user is a member
        require(isGuildMember(_guildId, _msgSender()), "AG: Not a member of this guild");

        // Cannot leave if you are the leader
        require(guilds[_guildId].leader != _msgSender(), "AG: Leader cannot leave guild");

        // Check if user has any tokens staked in this guild
        uint256 balance = balanceOf(_msgSender());
        for(uint i=0; i<balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            if(stakedGuildId[tokenId] == _guildId) {
                revert("AG: Must unstake all tokens from this guild before leaving");
            }
        }

        _removeGuildMember(_guildId, _msgSender());

        emit GuildLeft(_guildId, _msgSender());
    }

    /**
     * @dev Get basic details of a Guild.
     * @param _guildId The ID of the Guild.
     * @return name The guild's name.
     * @return leader The guild leader's address.
     * @return memberCount The current number of members.
     */
    function getGuildDetails(uint256 _guildId) public view returns (string memory name, address leader, uint256 memberCount) {
        require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");
        Guild storage guild = guilds[_guildId];
        return (guild.name, guild.leader, guild.members.length);
    }

    /**
     * @dev Get the list of addresses that are members of a Guild.
     *      Note: This might be gas-intensive for very large guilds.
     * @param _guildId The ID of the Guild.
     * @return A dynamic array of member addresses.
     */
    function getGuildMembers(uint256 _guildId) public view returns (address[] memory) {
         require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");
         return guilds[_guildId].members;
    }

     /**
     * @dev Check if a user is a member of a specific Guild.
     * @param _guildId The ID of the Guild.
     * @param _user The address to check.
     * @return True if the user is a member, false otherwise.
     */
    function isGuildMember(uint256 _guildId, address _user) public view returns (bool) {
         require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");
         address[] memory members = guilds[_guildId].members;
         for(uint i=0; i<members.length; i++) {
             if(members[i] == _user) {
                 return true;
             }
         }
         return false;
    }

    /**
     * @dev Get the total aggregated Aura Power of all NFTs staked in a specific Guild.
     * @param _guildId The ID of the Guild.
     * @return The total staked power in the guild.
     */
    function getGuildTotalPower(uint256 _guildId) public view returns (uint256) {
        require(_guildId > 0 && guilds[_guildId].leader != address(0), "AG: Guild does not exist");
        return totalGuildPower[_guildId];
    }

    // --- Resource & Power Functions ---

     /**
     * @dev Get the Essence balance for a user.
     * @param _user The address of the user.
     * @return The Essence balance.
     */
    function getEssenceBalance(address _user) public view returns (uint256) {
        return essenceBalance[_user];
    }

    /**
     * @dev Use Essence to instantly increase an NFT's Aura Power by 1.
     *      Accrues any pending staking gains for the token *before* leveling up.
     *      Cost is calculated as `currentPower * levelUpEssenceCostMultiplier`.
     * @param _tokenId The ID of the NFT to level up.
     */
    function levelUpAura(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == _msgSender(), "AG: Caller does not own token");
        uint256 currentPower = auraPower[_tokenId];
        require(currentPower > 0, "AG: Cannot level up token with 0 power");

        // Accrue staking gains BEFORE applying level up (prevents earning on newly added power immediately)
        _accrueStakingGains(_tokenId);

        // Calculate essence cost. Use unchecked add/mul if potentially hitting uint256 max,
        // but default checked arithmetic in 0.8+ is safer unless you have a specific reason.
        // Max auraPower is uint256, max multiplier uint256. The product could exceed max(uint256).
        // Let's cap the cost calculation or ensure parameters prevent overflow.
        // Assuming reasonable values where currentPower * multiplier fits in uint256.
        uint256 essenceCost = currentPower * levelUpEssenceCostMultiplier;
        require(essenceBalance[_msgSender()] >= essenceCost, "AG: Insufficient Essence");

        unchecked { // Safe because we checked balance >= cost
             essenceBalance[_msgSender()] -= essenceCost;
        }

        uint256 oldPower = auraPower[_tokenId];
        uint256 newPower = oldPower + 1; // Simple +1 level up for now
        auraPower[_tokenId] = newPower;

        // Update total guild/global power if staked
        uint256 gId = stakedGuildId[_tokenId];
        if (gId != 0) {
             totalGuildPower[gId] += 1; // Add 1 power to guild total
        }
        // Only update totalStakedPower if the token was staked
        if (stakedGuildId[_tokenId] != 0) {
             totalStakedPower += 1; // Add 1 power to global total
        }

        emit AuraLeveledUp(_tokenId, oldPower, newPower, essenceCost);
    }

    // --- Reward Functions ---

     /**
     * @dev Get the total claimable Reward Token balance for a user.
     *      This balance accumulates from the reward portion of staking gains (`_accrueStakingGains`).
     *      The value is stored and calculated in 1e18 precision internally.
     * @param _user The address of the user.
     * @return The total claimable reward tokens (in 1e18 precision).
     */
    function getUserClaimableRewards(address _user) public view returns (uint256) {
        return userClaimableRewards[_user];
    }


    /**
     * @dev Claims all accrued staking gains (Essence, Power, and Reward Tokens) for all
     *      of the caller's staked NFTs.
     *      Reward Tokens are transferred from the contract's pool to the user.
     *      Essence and Power gains are already applied to state by `_accrueStakingGains`.
     *      This function only triggers the accrual for all staked tokens and transfers rewards.
     */
    function claimAllStakedGainsForOwnedTokens() public {
         address user = _msgSender();
         uint256 balance = balanceOf(user);
         require(balance > 0, "AG: User owns no tokens");

         // Accrue gains for ALL staked tokens owned by the user
         bool hasStakedToken = false;
         for(uint i=0; i<balance; i++) {
             uint256 tokenId = tokenOfOwnerByIndex(user, i);
             if(stakedGuildId[tokenId] != 0) {
                 _accrueStakingGains(tokenId);
                 hasStakedToken = true;
             }
         }
         require(hasStakedToken, "AG: User has no staked tokens to claim from");


        uint256 claimableRewards1e18 = userClaimableRewards[user];

        if (claimableRewards1e18 > 0) {
            // Convert claimable amount from 1e18 precision to base units for transfer
            uint256 amountToTransfer = claimableRewards1e18 / (1e18);
            userClaimableRewards[user] -= (amountToTransfer * (1e18)); // Subtract the base units * 1e18 from internal balance

            uint256 poolBalance = rewardToken.balanceOf(address(this));
            amountToTransfer = Math.min(amountToTransfer, poolBalance); // Only transfer what's available in the pool

            if (amountToTransfer > 0) {
                // Transfer rewards from the contract's balance to the user
                bool success = rewardToken.transfer(user, amountToTransfer);
                require(success, "AG: Reward token transfer failed");

                emit RewardsClaimed(user, amountToTransfer);
            }
        }
        // Essence and Power gains are already applied in _accrueStakingGains called above
    }


    // --- Admin & Parameter Functions ---

    /**
     * @dev Allows the owner to distribute Reward Tokens into the contract's pool.
     *      Tokens must be approved for the contract beforehand (e.g., owner approves contract to spend X amount).
     * @param _amount The amount of Reward Tokens to transfer into the pool (in base units).
     */
    function distributeRewardsToPool(uint256 _amount) public onlyOwner {
        require(_amount > 0, "AG: Amount must be greater than 0");
        // Transfer tokens from the owner's balance to the contract's balance
        bool success = rewardToken.transferFrom(_msgSender(), address(this), _amount);
        require(success, "AG: Reward token transferFrom failed");
        emit RewardsDistributed(_msgSender(), _amount);
    }

     /**
     * @dev Get the current balance of Reward Tokens held by the contract (the reward pool).
     * @return The balance of Reward Tokens (in base units).
     */
    function getGlobalRewardPoolBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

     /**
     * @dev Get the total aggregated Aura Power of all currently staked NFTs across all guilds.
     * @return The total staked power globally.
     */
    function getTotalStakedPower() public view returns (uint256) {
        return totalStakedPower;
    }

    /**
     * @dev Owner can withdraw any accidentally sent ERC20 tokens from the contract.
     *      Does not allow withdrawal of the designated reward token or the NFTs themselves.
     * @param _token Address of the token to withdraw.
     * @param _amount Amount to withdraw.
     */
    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        require(_token != address(rewardToken), "AG: Cannot withdraw reward token");
        // Could also add a check to prevent withdrawing this contract's own NFTs if it somehow held them,
        // but ERC721Enumerable doesn't make this trivial without iterating.
        IERC20 stuckToken = IERC20(_token);
        require(stuckToken.balanceOf(address(this)) >= _amount, "AG: Insufficient stuck token balance");
        bool success = stuckToken.transfer(owner(), _amount);
        require(success, "AG: Stuck token withdrawal failed");
        emit StuckTokensWithdrawn(_token, owner(), _amount);
    }

    /**
     * @dev Owner sets the rate at which Reward Tokens are earned per Aura Power per second.
     *      Rate uses 1e18 precision, meaning 1e18 equals 1 full Reward Token per Aura Power per second.
     * @param _rate The new staking reward rate (with 1e18 precision).
     */
    function setStakingRewardRate(uint256 _rate) public onlyOwner {
        emit ParameterUpdated("stakingRewardRatePerPowerPerSecond", stakingRewardRatePerPowerPerSecond, _rate);
        stakingRewardRatePerPowerPerSecond = _rate;
    }

    /**
     * @dev Owner sets the rate at which Aura Power is gained per second staked.
     *      Rate uses 1e18 precision, meaning 1e18 equals 1 full Aura Power point per second.
     * @param _rate The new power gain rate (with 1e18 precision).
     */
    function setPowerGainRate(uint256 _rate) public onlyOwner {
        emit ParameterUpdated("powerGainRatePerSecondStaked", powerGainRatePerSecondStaked, _rate);
        powerGainRatePerSecondStaked = _rate;
    }

    /**
     * @dev Owner sets the rate at which Essence is gained per second staked.
     *      Rate uses 1e18 precision, meaning 1e18 equals 1 full Essence point per second.
     * @param _rate The new essence gain rate (with 1e18 precision).
     */
    function setEssenceGainRate(uint256 _rate) public onlyOwner {
         emit ParameterUpdated("essenceGainRatePerSecondStaked", essenceGainRatePerSecondStaked, _rate);
        essenceGainRatePerSecondStaked = _rate;
    }

    /**
     * @dev Owner sets the multiplier for the Essence cost to level up Aura Power.
     *      Cost = currentPower * multiplier.
     * @param _multiplier The new level up cost multiplier.
     */
    function setLevelUpEssenceCostMultiplier(uint256 _multiplier) public onlyOwner {
        emit ParameterUpdated("levelUpEssenceCostMultiplier", levelUpEssenceCostMultiplier, _multiplier);
        levelUpEssenceCostMultiplier = _multiplier;
    }

    /**
     * @dev Owner sets the maximum number of members allowed per guild.
     *      Set to 0 for no limit.
     * @param _size The new maximum guild size.
     */
    function setMaxGuildSize(uint256 _size) public onlyOwner {
        emit ParameterUpdated("maxGuildSize", maxGuildSize, _size);
        maxGuildSize = _size;
    }

    // --- Fallback to prevent sending ETH ---
    receive() external payable {
        revert("AG: Cannot receive Ether");
    }

    fallback() external payable {
        revert("AG: Cannot receive Ether");
    }
}
```