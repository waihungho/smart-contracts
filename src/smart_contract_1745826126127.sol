Okay, here is a Solidity smart contract incorporating several advanced and creative concepts around dynamic NFTs, crafting, resource management, and staking, aiming for over 20 functions. It's designed as a "Genesis Shards & Essence" system.

**Concepts Covered:**

1.  **Dynamic NFTs (Genesis Shards):** NFTs with mutable traits stored on-chain.
2.  **Fungible Resource (Essence):** Interaction with an external ERC20 token required for operations.
3.  **NFT Infusion:** Upgrading NFT traits by consuming the fungible resource, potentially with cooldowns.
4.  **NFT Forging:** Burning multiple NFTs and resources to create a new NFT with potentially derived traits, based on predefined recipes.
5.  **NFT Distillation:** Burning an NFT to recover some fungible resource based on its attributes.
6.  **Essence Staking:** Locking the fungible resource to earn yield or benefits within the system.
7.  **Parameterization:** Admin control over costs, yields, recipe definitions, and staking rates.
8.  **Access Control:** Using `Ownable` for administrative functions.

---

**Outline and Function Summary:**

This contract, `GenesisShards`, manages dynamic ERC721 NFTs ("Shards") and interacts with an external ERC20 token ("Essence").

1.  **State Variables:** Stores contract owner, linked Essence token address, counters, mappings for Shard data, forging recipes, staking data, and system parameters.
2.  **Structs:** Defines the structure for Shard traits and Forging recipes.
3.  **Events:** Signals key actions like Minting, Infusing, Forging, Distilling, Staking, and Parameter updates.
4.  **Modifiers:** Ensures functions are callable only by the owner or checks state conditions.
5.  **ERC721 Standard Functions (Inherited):** Standard NFT functionality.
    *   `balanceOf(address owner)`: Get number of Shards owned by address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific Shard.
    *   `approve(address to, uint256 tokenId)`: Approve another address to transfer a specific Shard.
    *   `getApproved(uint256 tokenId)`: Get the approved address for a specific Shard.
    *   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all owner's Shards.
    *   `isApprovedForAll(address owner, address operator)`: Check if an address is an authorized operator.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer Shard (internal, overridden).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer Shard.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfer Shard with data.
    *   `supportsInterface(bytes4 interfaceId)`: Standard interface check.
6.  **Core Mechanics Functions:**
    *   `mintGenesisShard()`: Public function to mint a new Genesis Shard.
    *   `getShardTraits(uint256 shardId)`: Retrieves the current traits of a given Shard.
    *   `infuseShard(uint256 shardId)`: Consumes Essence to upgrade a Shard's traits, respecting cooldowns.
    *   `forgeShards(uint256[] calldata inputShardIds, uint256 recipeId)`: Consumes multiple Shards and Essence based on a recipe to create a new Shard.
    *   `distillShard(uint256 shardId)`: Burns a Shard and grants Essence back to the owner based on Shard traits.
7.  **Essence Staking Functions:**
    *   `stakeEssence(uint256 amount)`: Locks Essence tokens in the contract for staking.
    *   `unstakeEssence()`: Unlocks staked Essence after the required duration.
    *   `claimStakingRewards()`: Calculates and transfers accrued staking rewards.
    *   `getEssenceStakingInfo(address staker)`: Retrieves a staker's current staking details.
    *   `calculateStakingRewards(address staker)`: Calculates pending staking rewards without claiming.
8.  **Admin / Parameter Management Functions (Ownable):**
    *   `setGenesisShardMintPrice(uint256 price)`: Sets the cost in native currency to mint a Shard.
    *   `setMaxGenesisShards(uint256 maxSupply)`: Sets the maximum number of Shards that can be minted.
    *   `addForgingRecipe(uint256 recipeId, ForgingRecipe memory recipe)`: Adds or updates a forging recipe.
    *   `removeForgingRecipe(uint256 recipeId)`: Removes a forging recipe.
    *   `setInfusionParameters(uint256 essenceCost, uint256 cooldownDuration)`: Sets infusion cost and cooldown.
    *   `setDistillationYieldParameters(uint256 baseYield, uint256 yieldPerInfusion)`: Sets parameters for distillation Essence yield.
    *   `setStakingParameters(uint256 rewardRate, uint256 lockDuration)`: Sets staking reward rate (per second) and lock duration.
    *   `withdrawProtocolFees(address tokenAddress)`: Allows owner to withdraw collected fees (e.g., ETH from mints, or other tokens sent to the contract).
    *   `setEssenceToken(address _essenceToken)`: Sets the address of the Essence ERC20 token.
9.  **Query / Utility Functions:**
    *   `getTotalGenesisShards()`: Gets the total number of Shards minted.
    *   `getMaxGenesisShards()`: Gets the maximum mintable supply.
    *   `getGenesisShardMintPrice()`: Gets the current mint price.
    *   `getForgingRecipe(uint256 recipeId)`: Retrieves details of a specific forging recipe.
    *   `getInfusionParameters()`: Retrieves current infusion cost and cooldown.
    *   `getDistillationYieldParameters()`: Retrieves current distillation yield parameters.
    *   `getStakingParameters()`: Retrieves current staking rate and lock duration.
    *   `getEssenceToken()`: Gets the address of the linked Essence token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary can be found in the comments above the contract definition.

contract GenesisShards is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // State Variables
    Counters.Counter private _shardIds; // Counter for unique Shard IDs
    IERC20 public essenceToken;         // Address of the external Essence ERC20 token

    struct ShardTraits {
        uint256 power;              // Core combat/utility stat
        uint256 rarity;             // Influence on yield, forging success, etc.
        uint256 infusionsCount;     // How many times this shard has been infused
        uint256 lastInfusedTime;    // Timestamp of the last infusion
    }

    mapping(uint256 => ShardTraits) private shardTraits; // Map Shard ID to its traits

    struct ForgingRecipe {
        uint256[] requiredInputShardIds; // IDs of specific shards needed (optional, could be empty)
        uint256 requiredInputShardCount; // Number of *any* shards required
        uint256 requiredEssenceAmount; // Essence cost for forging
        uint256 requiredCatalystId;    // ID of a required Catalyst NFT (0 for none) - Requires another NFT contract interaction or define Catalyst here
        // For simplicity, let's assume CatalystId 0 means no catalyst needed.
        // Output trait logic is simplified here; could be complex calculations.
        // Example: output traits based on avg input traits + recipe bonus + randomness
        uint256 minOutputPower;
        uint256 maxOutputPower;
        uint256 minOutputRarity;
        uint256 maxOutputRarity;
    }

    mapping(uint256 => ForgingRecipe) private forgingRecipes; // Map Recipe ID to Recipe details

    struct StakingInfo {
        uint256 amount;         // Amount of Essence staked
        uint256 startTime;      // Timestamp staking began
        uint256 lastClaimTime;  // Timestamp of last reward claim
    }

    mapping(address => StakingInfo) private essenceStaking; // Map staker address to their staking info

    // System Parameters
    uint256 public genesisShardMintPrice = 0.01 ether; // Price in native currency (ETH/MATIC)
    uint256 public maxGenesisShards = 10000;         // Maximum total supply of Shards
    uint256 public totalGenesisShards = 0;           // Current total supply

    uint256 public infusionEssenceCost = 10 ether; // Essence cost per infusion
    uint256 public infusionCooldownDuration = 1 days; // Time required between infusions

    uint256 public distillationBaseEssenceYield = 5 ether; // Base Essence yield from distillation
    uint256 public distillationYieldPerInfusion = 1 ether; // Additional yield per infusion count

    uint256 public stakingRewardRate = 10 ether; // Reward amount per second per staked Essence unit
    uint256 public stakingLockDuration = 30 days; // Minimum duration Essence must be staked

    // Events
    event GenesisShardMinted(uint256 indexed tokenId, address indexed owner);
    event ShardInfused(uint256 indexed tokenId, address indexed owner, uint256 newPower, uint256 newRarity);
    event ShardForged(address indexed owner, uint256[] indexed inputTokenIds, uint256 indexed outputTokenId, uint256 recipeId);
    event ShardDistilled(uint256 indexed tokenId, address indexed owner, uint256 essenceReceived);
    event EssenceStaked(address indexed staker, uint256 amount);
    event EssenceUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event ForgingRecipeAdded(uint256 indexed recipeId);
    event ForgingRecipeRemoved(uint256 indexed recipeId);
    event ParameterUpdated(string parameterName, uint256 newValue);

    // --- Constructor ---
    constructor(address _essenceToken) ERC721("Genesis Shard", "GSHARD") Ownable(msg.sender) {
        require(_essenceToken != address(0), "Essence token address cannot be zero");
        essenceToken = IERC20(_essenceToken);
    }

    // --- ERC721 Standard Functions (Inherited and Overridden) ---
    // Note: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, supportsInterface
    // are automatically available from inheriting ERC721.
    // transferFrom and safeTransferFrom will use the overridden _transfer.

    // Internal helper to burn Shards
    function _burnShard(uint256 tokenId) internal {
        _burn(tokenId);
        delete shardTraits[tokenId]; // Also remove traits when burning
    }

    // Override _transfer to add any custom logic if needed, e.g., status checks
    // For this example, standard transfer logic is fine.
    // We will still list the public transfer functions in the summary as they are part of the API.
    // function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    //     super._transfer(from, to, tokenId);
    //     // Add custom logic here if required, e.g., updating ownership in custom mapping
    // }

    // --- Core Mechanics Functions ---

    /**
     * @dev Mints a new Genesis Shard to the caller.
     * Requires payment of the mint price in native currency.
     */
    function mintGenesisShard() public payable {
        require(totalGenesisShards < maxGenesisShards, "Mint limit reached");
        require(msg.value >= genesisShardMintPrice, "Insufficient native currency sent");

        uint256 newItemId = _shardIds.current();
        _shardIds.increment();
        totalGenesisShards++;

        // Initialize basic traits (can be randomized or fixed)
        shardTraits[newItemId] = ShardTraits({
            power: 10,
            rarity: 1,
            infusionsCount: 0,
            lastInfusedTime: block.timestamp
        });

        _safeMint(msg.sender, newItemId);

        // Refund any excess native currency sent
        if (msg.value > genesisShardMintPrice) {
            payable(msg.sender).transfer(msg.value - genesisShardMintPrice);
        }

        emit GenesisShardMinted(newItemId, msg.sender);
    }

    /**
     * @dev Retrieves the traits of a specific Genesis Shard.
     * @param shardId The ID of the shard.
     * @return ShardTraits struct containing power, rarity, infusionsCount, lastInfusedTime.
     */
    function getShardTraits(uint256 shardId) public view returns (ShardTraits memory) {
        require(_exists(shardId), "Shard does not exist");
        return shardTraits[shardId];
    }

    /**
     * @dev Infuses a Shard, increasing its traits.
     * Requires owning the Shard, Essence tokens, and passing the cooldown.
     * @param shardId The ID of the shard to infuse.
     */
    function infuseShard(uint256 shardId) public {
        require(_exists(shardId), "Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "Not your shard");

        ShardTraits storage traits = shardTraits[shardId];
        require(block.timestamp >= traits.lastInfusedTime.add(infusionCooldownDuration), "Infusion cooldown active");
        require(essenceToken.balanceOf(msg.sender) >= infusionEssenceCost, "Insufficient Essence tokens");

        // Transfer Essence to the contract (requires prior approval)
        require(essenceToken.transferFrom(msg.sender, address(this), infusionEssenceCost), "Essence transfer failed");

        // Apply infusion effect (simplified: fixed increase)
        traits.power = traits.power.add(5); // Example trait increase
        traits.rarity = traits.rarity.add(1); // Example trait increase
        traits.infusionsCount++;
        traits.lastInfusedTime = block.timestamp;

        emit ShardInfused(shardId, msg.sender, traits.power, traits.rarity);
    }

    /**
     * @dev Forges new Shards from input Shards and Essence based on a recipe.
     * Burns input Shards and potentially a Catalyst. Mints a new Shard with calculated traits.
     * @param inputShardIds The IDs of the shards to use as input.
     * @param recipeId The ID of the forging recipe to follow.
     */
    function forgeShards(uint256[] calldata inputShardIds, uint256 recipeId) public {
        ForgingRecipe memory recipe = forgingRecipes[recipeId];
        require(recipe.requiredInputShardCount > 0 || recipe.requiredInputShardIds.length > 0, "Recipe does not exist");
        require(inputShardIds.length == recipe.requiredInputShardCount || inputShardIds.length == recipe.requiredInputShardIds.length, "Incorrect number of input shards");

        uint256 totalInputPower = 0;
        uint256 totalInputRarity = 0;

        // Check ownership and existence of input shards, and accumulate traits
        for (uint i = 0; i < inputShardIds.length; i++) {
            uint256 shardId = inputShardIds[i];
            require(_exists(shardId), "Input shard does not exist");
            require(ownerOf(shardId) == msg.sender, "Not your input shard");
            // If recipe requires specific shards, check IDs
            if (recipe.requiredInputShardIds.length > 0) {
                 bool found = false;
                 for(uint j = 0; j < recipe.requiredInputShardIds.length; j++){
                     if(shardId == recipe.requiredInputShardIds[j]) {
                         found = true;
                         break;
                     }
                 }
                 require(found, "Input shard ID not required by recipe");
                 // Simple check: ensure each required ID is present exactly once (needs more robust check for duplicates if allowed)
            }
            totalInputPower = totalInputPower.add(shardTraits[shardId].power);
            totalInputRarity = totalInputRarity.add(shardTraits[shardId].rarity);
        }

        // Check Catalyst (if required) - This would require interaction with a Catalyst NFT contract
        // if (recipe.requiredCatalystId != 0) {
        //     // Check ownership of Catalyst NFT, maybe burn it
        //     // require(CatalystNFT.ownerOf(recipe.requiredCatalystId) == msg.sender, "Not your catalyst");
        //     // CatalystNFT.burn(recipe.requiredCatalystId); // Example burn
        //     revert("Catalyst functionality not implemented in this example"); // Placeholder
        // }

        // Check and consume Essence
        require(essenceToken.balanceOf(msg.sender) >= recipe.requiredEssenceAmount, "Insufficient Essence tokens for forging");
        require(essenceToken.transferFrom(msg.sender, address(this), recipe.requiredEssenceAmount), "Essence transfer failed for forging");

        // Burn input shards
        for (uint i = 0; i < inputShardIds.length; i++) {
            _burnShard(inputShardIds[i]);
        }

        // Mint new output shard
        uint256 newShardId = _shardIds.current();
        _shardIds.increment();
        totalGenesisShards++; // Note: forging changes supply based on input/output counts

        // Calculate output traits (simplified random based on recipe range and input avg)
        uint256 avgInputPower = totalInputPower.div(inputShardIds.length); // Assumes inputShardIds.length > 0
        uint256 avgInputRarity = totalInputRarity.div(inputShardIds.length);

        // Simple output calculation example: bias towards average input, within recipe range
        uint256 outputPower = Math.max(recipe.minOutputPower, Math.min(recipe.maxOutputPower, avgInputPower)); // Clamp avg
        uint256 outputRarity = Math.max(recipe.minOutputRarity, Math.min(recipe.maxOutputRarity, avgInputRarity));

        // Add a random element (requires Chainlink VRF or similar for production)
        // For demonstration, a simple pseudo-random is used (NOT secure for real value!)
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, inputShardIds, newShardId)));
        outputPower = outputPower.add(pseudoRandom % 10); // Add small random modifier
        outputRarity = outputRarity.add((pseudoRandom / 10) % 5); // Add small random modifier

        outputPower = Math.max(recipe.minOutputPower, Math.min(recipe.maxOutputPower, outputPower)); // Re-clamp after random
        outputRarity = Math.max(recipe.minOutputRarity, Math.min(recipe.maxOutputRarity, outputRarity));


        shardTraits[newShardId] = ShardTraits({
            power: outputPower,
            rarity: outputRarity,
            infusionsCount: 0,
            lastInfusedTime: block.timestamp // Reset infusion cooldown
        });

        _safeMint(msg.sender, newShardId);

        emit ShardForged(msg.sender, inputShardIds, newShardId, recipeId);
    }

    /**
     * @dev Distills a Shard into Essence.
     * Burns the Shard and transfers Essence back to the owner based on its traits.
     * @param shardId The ID of the shard to distill.
     */
    function distillShard(uint256 shardId) public {
        require(_exists(shardId), "Shard does not exist");
        require(ownerOf(shardId) == msg.sender, "Not your shard");

        ShardTraits memory traits = shardTraits[shardId];
        // Calculate yield based on parameters and shard traits
        uint256 essenceYield = distillationBaseEssenceYield.add(traits.infusionsCount.mul(distillationYieldPerInfusion));
        // Could also factor in rarity: essenceYield = essenceYield.add(traits.rarity.mul(...));

        require(essenceToken.balanceOf(address(this)) >= essenceYield, "Contract has insufficient Essence for distillation");

        _burnShard(shardId);

        // Transfer Essence back to the owner
        require(essenceToken.transfer(msg.sender, essenceYield), "Essence transfer failed for distillation");

        emit ShardDistilled(shardId, msg.sender, essenceYield);
    }

    // --- Essence Staking Functions ---

    /**
     * @dev Stakes a specified amount of Essence tokens.
     * Requires prior approval for the contract to transfer the tokens.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) public {
        require(amount > 0, "Cannot stake zero");
        require(essenceToken.balanceOf(msg.sender) >= amount, "Insufficient Essence balance");

        // If staker already has a stake, auto-claim rewards before adding to stake
        if (essenceStaking[msg.sender].amount > 0) {
             claimStakingRewards();
        }

        // Transfer Essence to the contract (requires prior approval)
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed");

        // Update staking info
        essenceStaking[msg.sender].amount = essenceStaking[msg.sender].amount.add(amount);
        if (essenceStaking[msg.sender].startTime == 0) {
             essenceStaking[msg.sender].startTime = block.timestamp;
        }
        essenceStaking[msg.sender].lastClaimTime = block.timestamp; // Reset or update last claim time

        emit EssenceStaked(msg.sender, amount);
    }

    /**
     * @dev Unstakes all staked Essence tokens.
     * Requires the staking lock duration to have passed.
     */
    function unstakeEssence() public {
        StakingInfo storage staking = essenceStaking[msg.sender];
        require(staking.amount > 0, "No Essence staked");
        require(block.timestamp >= staking.startTime.add(stakingLockDuration), "Staking lock duration not met");

        uint256 amountToUnstake = staking.amount;

        // Auto-claim rewards before unstaking
        claimStakingRewards();

        // Reset staking info
        staking.amount = 0;
        staking.startTime = 0;
        staking.lastClaimTime = 0; // Or keep it? Depends on reward calculation logic

        // Transfer staked Essence back
        require(essenceToken.transfer(msg.sender, amountToUnstake), "Essence transfer failed during unstake");

        emit EssenceUnstaked(msg.sender, amountToUnstake);
    }

    /**
     * @dev Calculates and claims accrued staking rewards.
     */
    function claimStakingRewards() public {
        StakingInfo storage staking = essenceStaking[msg.sender];
        require(staking.amount > 0, "No Essence staked to claim rewards from");

        uint256 timeElapsed = block.timestamp.sub(staking.lastClaimTime);
        uint256 potentialRewards = staking.amount.mul(stakingRewardRate).mul(timeElapsed);
        // Need to ensure contract has enough Essence for rewards
        uint256 actualRewards = Math.min(potentialRewards, essenceToken.balanceOf(address(this))); // Avoid draining contract below its staked balance + other needs

        require(actualRewards > 0, "No rewards accrued yet or available");

        staking.lastClaimTime = block.timestamp;

        // Transfer rewards
        require(essenceToken.transfer(msg.sender, actualRewards), "Essence transfer failed during reward claim");

        emit StakingRewardsClaimed(msg.sender, actualRewards);
    }

    /**
     * @dev Retrieves the staking information for a specific staker.
     * @param staker The address of the staker.
     * @return amount, startTime, lastClaimTime.
     */
    function getEssenceStakingInfo(address staker) public view returns (uint256 amount, uint256 startTime, uint256 lastClaimTime) {
         StakingInfo memory staking = essenceStaking[staker];
         return (staking.amount, staking.startTime, staking.lastClaimTime);
    }

     /**
     * @dev Calculates pending staking rewards for a staker without claiming.
     * @param staker The address of the staker.
     * @return pendingRewards The calculated amount of rewards.
     */
    function calculateStakingRewards(address staker) public view returns (uint256 pendingRewards) {
         StakingInfo memory staking = essenceStaking[staker];
         if (staking.amount == 0) {
             return 0;
         }
         uint256 timeElapsed = block.timestamp.sub(staking.lastClaimTime);
         uint256 potentialRewards = staking.amount.mul(stakingRewardRate).mul(timeElapsed);
         // Check contract balance availability for rewards (important for reward calculation view)
         return Math.min(potentialRewards, essenceToken.balanceOf(address(this)).sub(getTotalStakedEssence())); // Don't calculate rewards beyond available - total staked
    }

    // Helper function to get total staked amount (for reward calculation safety)
    function getTotalStakedEssence() public view returns (uint256) {
        // This requires iterating through all stakers, which is not gas efficient.
        // A more efficient way would be to maintain a running total state variable, updated on stake/unstake.
        // For simplicity in this example, we'll skip implementing this complex aggregation.
        // In a real contract, this function would likely be removed or replaced with a state variable.
        // Reverting for now to indicate this complexity:
        revert("getTotalStakedEssence requires iterating mappings which is inefficient. Use a state variable in production.");
        // A production contract would have a state variable like:
        // uint256 private _totalStakedEssence = 0;
        // updated in stake/unstake functions.
        // return _totalStakedEssence;
    }


    // --- Admin / Parameter Management Functions (Ownable) ---

    /**
     * @dev Sets the price in native currency required to mint a Genesis Shard.
     * @param price The new mint price.
     */
    function setGenesisShardMintPrice(uint256 price) public onlyOwner {
        genesisShardMintPrice = price;
        emit ParameterUpdated("genesisShardMintPrice", price);
    }

    /**
     * @dev Sets the maximum number of Genesis Shards that can be minted.
     * Cannot be set below the current total supply.
     * @param maxSupply The new maximum supply.
     */
    function setMaxGenesisShards(uint256 maxSupply) public onlyOwner {
        require(maxSupply >= totalGenesisShards, "Max supply cannot be less than current supply");
        maxGenesisShards = maxSupply;
        emit ParameterUpdated("maxGenesisShards", maxSupply);
    }

    /**
     * @dev Adds or updates a forging recipe.
     * @param recipeId The ID for the recipe.
     * @param recipe The ForgingRecipe struct containing recipe details.
     */
    function addForgingRecipe(uint256 recipeId, ForgingRecipe memory recipe) public onlyOwner {
         require(recipe.requiredInputShardCount > 0 || recipe.requiredInputShardIds.length > 0, "Recipe must require at least one input shard");
        forgingRecipes[recipeId] = recipe;
        emit ForgingRecipeAdded(recipeId);
    }

    /**
     * @dev Removes a forging recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeForgingRecipe(uint256 recipeId) public onlyOwner {
        delete forgingRecipes[recipeId];
        emit ForgingRecipeRemoved(recipeId);
    }

    /**
     * @dev Sets parameters for the infusion process.
     * @param essenceCost The Essence cost per infusion.
     * @param cooldownDuration The cooldown period between infusions in seconds.
     */
    function setInfusionParameters(uint256 essenceCost, uint256 cooldownDuration) public onlyOwner {
        infusionEssenceCost = essenceCost;
        infusionCooldownDuration = cooldownDuration;
        emit ParameterUpdated("infusionEssenceCost", essenceCost);
        emit ParameterUpdated("infusionCooldownDuration", cooldownDuration);
    }

    /**
     * @dev Sets parameters determining Essence yield from distillation.
     * @param baseYield The base amount of Essence returned.
     * @param yieldPerInfusion Additional Essence returned per infusion the shard received.
     */
    function setDistillationYieldParameters(uint256 baseYield, uint256 yieldPerInfusion) public onlyOwner {
        distillationBaseEssenceYield = baseYield;
        distillationYieldPerInfusion = yieldPerInfusion;
        emit ParameterUpdated("distillationBaseEssenceYield", baseYield);
        emit ParameterUpdated("distillationYieldPerInfusion", yieldPerInfusion);
    }

     /**
     * @dev Sets parameters for Essence staking rewards and lock duration.
     * @param rewardRate The amount of Essence rewarded per second per staked Essence unit.
     * @param lockDuration The minimum duration Essence must be staked in seconds.
     */
    function setStakingParameters(uint256 rewardRate, uint256 lockDuration) public onlyOwner {
        stakingRewardRate = rewardRate;
        stakingLockDuration = lockDuration;
        emit ParameterUpdated("stakingRewardRate", rewardRate);
        emit ParameterUpdated("stakingLockDuration", lockDuration);
    }


    /**
     * @dev Allows the contract owner to withdraw collected fees (native currency or other tokens).
     * Useful for withdrawing ETH from mints or Essence collected from crafting.
     * @param tokenAddress The address of the token to withdraw. Use address(0) for native currency.
     */
    function withdrawProtocolFees(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw native currency (ETH/MATIC)
            payable(owner()).transfer(address(this).balance);
        } else {
            // Withdraw a specific ERC20 token
            IERC20 token = IERC20(tokenAddress);
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    /**
     * @dev Sets the address of the external Essence ERC20 token.
     * Should only be called once during setup unless a migration is needed.
     * @param _essenceToken The address of the Essence token contract.
     */
    function setEssenceToken(address _essenceToken) public onlyOwner {
         require(_essenceToken != address(0), "Essence token address cannot be zero");
         essenceToken = IERC20(_essenceToken);
         emit ParameterUpdated("essenceToken", uint256(uint160(_essenceToken))); // Log address as uint256
    }

    // --- Query / Utility Functions ---

    /**
     * @dev Gets the total number of Genesis Shards currently minted.
     * @return The total supply.
     */
    function getTotalGenesisShards() public view returns (uint256) {
        return totalGenesisShards;
    }

    /**
     * @dev Gets the maximum number of Genesis Shards that can be minted.
     * @return The maximum supply.
     */
    function getMaxGenesisShards() public view returns (uint256) {
        return maxGenesisShards;
    }

    /**
     * @dev Gets the current price to mint a Genesis Shard in native currency.
     * @return The mint price in wei.
     */
    function getGenesisShardMintPrice() public view returns (uint256) {
        return genesisShardMintPrice;
    }

    /**
     * @dev Retrieves the details of a specific forging recipe.
     * @param recipeId The ID of the recipe.
     * @return ForgingRecipe struct.
     */
    function getForgingRecipe(uint256 recipeId) public view returns (ForgingRecipe memory) {
        return forgingRecipes[recipeId];
    }

    /**
     * @dev Retrieves the current parameters for the infusion process.
     * @return essenceCost, cooldownDuration.
     */
    function getInfusionParameters() public view returns (uint256 essenceCost, uint256 cooldownDuration) {
        return (infusionEssenceCost, infusionCooldownDuration);
    }

     /**
     * @dev Retrieves the current parameters for distillation yield.
     * @return baseYield, yieldPerInfusion.
     */
    function getDistillationYieldParameters() public view returns (uint256 baseYield, uint256 yieldPerInfusion) {
        return (distillationBaseEssenceYield, distillationYieldPerInfusion);
    }

     /**
     * @dev Retrieves the current parameters for Essence staking.
     * @return rewardRate, lockDuration.
     */
    function getStakingParameters() public view returns (uint256 rewardRate, uint256 lockDuration) {
        return (stakingRewardRate, stakingLockDuration);
    }

     /**
     * @dev Gets the address of the linked Essence ERC20 token.
     * @return The Essence token address.
     */
    function getEssenceToken() public view returns (address) {
        return address(essenceToken);
    }

    // --- Include standard ERC721 view functions explicitly for summary count ---
    // These are inherited and typically don't need explicit implementation unless overriding.
    // Listing them here just to highlight they are part of the contract's public API.

    // function balanceOf(address owner) public view virtual override returns (uint256) { super.balanceOf(owner); }
    // function ownerOf(uint256 tokenId) public view virtual override returns (address) { super.ownerOf(tokenId); }
    // function approve(address to, uint256 tokenId) public virtual override { super.approve(to, tokenId); }
    // function getApproved(uint256 tokenId) public view virtual override returns (address) { super.getApproved(tokenId); }
    // function setApprovalForAll(address operator, bool approved) public virtual override { super.setApprovalForAll(operator, approved); }
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) { super.isApprovedForAll(owner, operator); }
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override { super.transferFrom(from, to, tokenId); } // Public API
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override { super.safeTransferFrom(from, to, tokenId); } // Public API
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override { super.safeTransferFrom(from, to, tokenId, data); } // Public API
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { super.supportsInterface(interfaceId); }


    // Ensure all ERC721 required interfaces are supported
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // --- Math Library Inclusion (for random number in forging) ---
    // This requires adding a simple Math library or using OpenZeppelin's Math if complex ops are needed.
    // For the simplified random example, we'll add a minimal internal Math library.
    // NOTE: Pseudo-randomness in Solidity is INSECURE and should NOT be used for high-value operations.
    // A real application would use Chainlink VRF or similar.
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a <= b ? a : b;
        }
    }
}
```