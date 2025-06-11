Okay, let's design a smart contract for a dynamic NFT that evolves over time and based on staking, integrating several advanced concepts like on-chain attributes, conditional state transitions, and a simulated reward mechanism. We'll call it `MetaMorphingNFT`.

This contract is designed to be complex and demonstrate various ideas. It's not audited or production-ready, but serves the purpose of showcasing advanced functionality.

---

**Outline & Function Summary:**

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title MetaMorphingNFT
 * @dev A dynamic NFT contract where tokens evolve based on staking duration and conditions.
 * Features:
 * - ERC721 compliant.
 * - On-chain attributes for each token (level, state, affinity).
 * - Staking mechanism where tokens gain 'evolution progress' over time.
 * - Leveling system based on evolution progress.
 * - Conditional transformation into a new state based on level and staking status.
 * - Simulated reward system based on staking duration (no actual token transfer in this example).
 * - Owner control over evolution parameters and base URI.
 * - Metadata integrity check via on-chain hash storage.
 * - Pausable staking.
 * - Gated functions based on token ownership/state.
 */
contract MetaMorphingNFT is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    /**
     * @dev Stores the mutable attributes of each NFT.
     * Represents the current state and progression of the token.
     */
    struct Attributes {
        uint256 level;                 // Current evolution level (starts at 1)
        uint256 affinity;              // A unique trait parameter for potential visual variation (e.g., 0-100)
        uint8 state;                   // Major form/state of the NFT (e.g., 0=Egg, 1=Creature, 2=Advanced Form)
        uint256 evolutionProgress;     // Accumulated points towards next level/evolution
        uint256 lastProgressUpdateBlock; // Block number when progress was last updated
    }

    /**
     * @dev Stores information about staked tokens.
     * A token is considered staked if an entry exists for its ID.
     */
    struct StakingInfo {
        address stakedBy;           // Address of the staker (should be the owner)
        uint66 stakeStartTime;      // Block number when staking started
        uint256 lastRewardClaimBlock; // Block number of the last reward claim
    }

    // --- State Variables ---

    // Mapping from token ID to its attributes
    mapping(uint256 => Attributes) private _tokenAttributes;

    // Mapping from token ID to its staking information
    mapping(uint256 => StakingInfo) private _stakedTokens;

    // Base URI for token metadata
    string private _baseTokenURI;

    // Owner-set parameters controlling evolution speed and thresholds
    uint256 public evolutionRatePerBlockStaked; // How much progress per block staked
    mapping(uint256 => uint256) public levelUpThresholds; // Progress needed for each level

    // Condition parameters for transformation (e.g., required level to transform from state 1 to 2)
    mapping(uint8 => uint256) public transformationRequiredLevel;

    // Mapping to store a hash representing the expected metadata/art for each token (for integrity check)
    mapping(uint256 => bytes32) private _metadataHashes;

    // Simulated reward token address (replace with actual ERC20 address if integrating)
    address public rewardTokenAddress;

    // Mapping to track accrued rewards (simulated)
    mapping(uint256 => uint256) private _accruedRewards; // Simulated reward amount

    // Staking paused status
    bool public stakingPaused = false;

    // --- Events ---

    event TokenMinted(uint256 indexed tokenId, address indexed owner, uint256 initialLevel, uint8 initialState);
    event AttributesUpdated(uint256 indexed tokenId, uint256 newLevel, uint256 newEvolutionProgress, uint8 newState);
    event TokenStaked(uint256 indexed tokenId, address indexed staker, uint66 stakeBlock);
    event TokenUnstaked(uint256 indexed tokenId, address indexed staker, uint66 stakeDurationBlocks);
    event EvolutionProgressUpdated(uint256 indexed tokenId, uint256 currentProgress, uint256 blocksStakedSinceLastUpdate);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 totalEvolutionProgress);
    event TokenTransformed(uint256 indexed tokenId, uint8 oldState, uint8 newState);
    event RewardClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event BaseTokenURIUpdated(string newBaseURI);
    event EvolutionParametersUpdated(uint256 newRatePerBlockStaked);
    event TransformationConditionUpdated(uint8 state, uint256 requiredLevel);
    event MetadataHashStored(uint256 indexed tokenId, bytes32 metadataHash);
    event StakingPaused(bool pausedStatus);

    // --- Constructor ---

    /**
     * @dev Initializes the contract with a name, symbol, and initial evolution parameters.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol of the NFT collection.
     * @param initialRatePerBlock Initial evolution progress gained per block while staked.
     */
    constructor(string memory name_, string memory symbol_, uint256 initialRatePerBlock)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        evolutionRatePerBlockStaked = initialRatePerBlock;

        // Set some default level-up thresholds (example values)
        levelUpThresholds[1] = 100;   // To reach level 2
        levelUpThresholds[2] = 300;   // To reach level 3
        levelUpThresholds[3] = 600;   // To reach level 4
        levelUpThresholds[4] = 1000;  // To reach level 5
        // ... add more as needed

        // Set some default transformation conditions (example values)
        transformationRequiredLevel[1] = 3; // Requires level 3 to transform from State 1
        transformationRequiredLevel[2] = 5; // Requires level 5 to transform from State 2
    }

    // --- Core ERC721 Overrides (7 functions) ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Overrides to return a URI that could potentially reflect the token's state.
     * Note: The metadata JSON at this URI must be served externally and update dynamically
     * based on the on-chain attributes fetched from this contract.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        if (bytes(_baseTokenURI).length == 0) {
             revert("Base URI not set");
        }

        // Append token ID and potentially state/level as query parameters or path segments
        // for external metadata service to interpret.
        Attributes storage attrs = _tokenAttributes[tokenId];
        string memory currentURI = string(abi.encodePacked(
            _baseTokenURI,
            Strings.toString(tokenId),
            "?level=", Strings.toString(attrs.level),
            "&state=", Strings.toString(attrs.state)
            // Add more attributes as needed for dynamic rendering/metadata
        ));

        return currentURI;
    }

    // The following ERC721 functions are inherited and used directly:
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - getApproved(uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address owner, address operator)

    // --- Custom Minting (1 function) ---

    /**
     * @dev Mints a new token with initial attributes. Only callable by the owner.
     * @param to The address to mint the token to.
     * @param initialAffinity A unique initial parameter for the token.
     */
    function mint(address to, uint256 initialAffinity) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        // Set initial attributes
        _tokenAttributes[newItemId] = Attributes({
            level: 1,                     // Start at level 1
            affinity: initialAffinity,    // Set initial affinity
            state: 0,                     // Start in state 0 (e.g., Egg state)
            evolutionProgress: 0,         // No progress initially
            lastProgressUpdateBlock: block.number // Record current block
        });

        emit TokenMinted(newItemId, to, 1, 0);
    }

    // --- Attribute Management & Query (2 functions) ---

    /**
     * @dev Gets the current attributes of a specific token.
     * @param tokenId The ID of the token.
     * @return Attributes struct containing level, affinity, state, progress, and last update block.
     */
    function getTokenAttributes(uint256 tokenId) public view returns (Attributes memory) {
         _requireMinted(tokenId); // Ensure token exists
        return _tokenAttributes[tokenId];
    }

    /**
     * @dev Gets the current major state of a specific token.
     * Convenience function to quickly check the state.
     * @param tokenId The ID of the token.
     * @return The current state (uint8).
     */
    function getTokenState(uint256 tokenId) public view returns (uint8) {
        _requireMinted(tokenId);
        return _tokenAttributes[tokenId].state;
    }


     // --- Staking (4 functions) ---

    /**
     * @dev Stakes a token owned by the caller. Only the owner can stake their token.
     * Updates staking information and potentially accrues rewards before staking.
     * @param tokenId The ID of the token to stake.
     */
    function stake(uint256 tokenId) public {
        require(!stakingPaused, "Staking is paused");
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Caller is not the owner");
        require(!isStaked(tokenId), "Token is already staked");

        // Ensure progress and potential rewards are calculated before staking
        _updateEvolutionProgress(tokenId);
        _calculateAccruedRewards(tokenId); // Update rewards based on previous state

        _stakedTokens[tokenId] = StakingInfo({
            stakedBy: msg.sender,
            stakeStartTime: uint66(block.number),
            lastRewardClaimBlock: block.number // Reset claim block on stake
        });

        emit TokenStaked(tokenId, msg.sender, uint66(block.number));
    }

    /**
     * @dev Unstakes a token owned by the caller.
     * Updates evolution progress and rewards before unstaking.
     * @param tokenId The ID of the token to unstake.
     */
    function unstake(uint256 tokenId) public {
        require(isStaked(tokenId), "Token is not staked");
        address staker = _stakedTokens[tokenId].stakedBy;
        require(msg.sender == staker, "Caller did not stake this token"); // Only the original staker can unstake
        require(ownerOf(tokenId) == msg.sender, "Caller must still own the token to unstake"); // Ensure ownership hasn't changed

        // Update progress and accrue rewards before removing staking info
        _updateEvolutionProgress(tokenId);
        _calculateAccruedRewards(tokenId);

        delete _stakedTokens[tokenId];

        emit TokenUnstaked(tokenId, msg.sender, uint66(block.number) - _stakedTokens[tokenId].stakeStartTime);
    }

    /**
     * @dev Checks if a token is currently staked.
     * @param tokenId The ID of the token.
     * @return True if staked, false otherwise.
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return _stakedTokens[tokenId].stakedBy != address(0);
    }

    /**
     * @dev Gets the staking information for a token.
     * @param tokenId The ID of the token.
     * @return StakingInfo struct or zero-initialized struct if not staked.
     */
    function getStakingInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        return _stakedTokens[tokenId];
    }

    // --- Evolution (4 functions) ---

    /**
     * @dev Calculates the potential evolution progress gained since the last update block if the token is staked.
     * Note: Does not update the actual state, only computes the value.
     * @param tokenId The ID of the token.
     * @return uint256 The potential progress gained.
     */
    function calculatePotentialEvolutionProgressGained(uint256 tokenId) public view returns (uint256) {
         _requireMinted(tokenId);
        Attributes storage attrs = _tokenAttributes[tokenId];

        if (isStaked(tokenId)) {
            uint256 blocksSinceLastUpdate = block.number - attrs.lastProgressUpdateBlock;
            return blocksSinceLastUpdate * evolutionRatePerBlockStaked;
        }
        return 0;
    }

    /**
     * @dev Internal function to update the actual evolution progress and check for level ups.
     * Should be called before any action that depends on up-to-date progress (stake, unstake, claim, triggerEvolution).
     * @param tokenId The ID of the token to update.
     */
    function _updateEvolutionProgress(uint256 tokenId) internal {
        Attributes storage attrs = _tokenAttributes[tokenId];
        uint256 gainedProgress = calculatePotentialEvolutionProgressGained(tokenId);

        if (gainedProgress > 0) {
            attrs.evolutionProgress += gainedProgress;
            attrs.lastProgressUpdateBlock = block.number;
            emit EvolutionProgressUpdated(tokenId, attrs.evolutionProgress, gainedProgress / evolutionRatePerBlockStaked);

            // Check for level ups
            uint256 currentLevel = attrs.level;
            uint256 requiredForNext = levelUpThresholds[currentLevel];

            while (requiredForNext > 0 && attrs.evolutionProgress >= requiredForNext) {
                attrs.level += 1;
                currentLevel = attrs.level; // Update current level for the next check
                emit LevelUp(tokenId, currentLevel, attrs.evolutionProgress);
                requiredForNext = levelUpThresholds[currentLevel]; // Get threshold for the new level
            }
             emit AttributesUpdated(tokenId, attrs.level, attrs.evolutionProgress, attrs.state);
        }
    }

    /**
     * @dev Allows anyone to trigger an update to a token's evolution progress and level.
     * This allows token holders or others to pay gas to update the state.
     * @param tokenId The ID of the token to update.
     */
    function triggerEvolutionUpdate(uint256 tokenId) public {
        _requireMinted(tokenId);
        _updateEvolutionProgress(tokenId);
    }

    /**
     * @dev Gets the progress needed to reach the next level from the token's current level.
     * @param tokenId The ID of the token.
     * @return uint256 Required progress for the next level, or 0 if no threshold defined.
     */
    function getRequiredEvolutionProgressForNextLevel(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        uint256 currentLevel = _tokenAttributes[tokenId].level;
        return levelUpThresholds[currentLevel];
    }

    // --- Transformation (3 functions) ---

    /**
     * @dev Checks if a token meets the conditions to transform to the next state.
     * Example conditions: reaches a certain level and is NOT staked.
     * @param tokenId The ID of the token.
     * @return bool True if the token can transform, false otherwise.
     */
    function canTransform(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        Attributes storage attrs = _tokenAttributes[tokenId];
        uint8 currentState = attrs.state;
        uint256 requiredLevel = transformationRequiredLevel[currentState];

        // Example condition: Must meet required level for the *current* state to transform to the *next* state
        // And must NOT be staked (transformation requires a temporary 'incubation' period outside of staking?)
        return requiredLevel > 0 && attrs.level >= requiredLevel && !isStaked(tokenId);
    }

    /**
     * @dev Triggers the transformation of a token if conditions are met.
     * Only the token owner can trigger transformation.
     * Changes the token's state and potentially resets some attributes (e.g., level/progress).
     * @param tokenId The ID of the token to transform.
     */
    function transformToken(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Caller is not the owner");
        require(canTransform(tokenId), "Transformation conditions not met");

        Attributes storage attrs = _tokenAttributes[tokenId];
        uint8 oldState = attrs.state;

        // Apply transformation effects
        attrs.state = oldState + 1; // Move to the next state
        attrs.level = 1;            // Reset level
        attrs.evolutionProgress = 0; // Reset progress
        // Affinity could potentially change or be modified here too based on state

        // Optionally set a new lastProgressUpdateBlock if needed
        attrs.lastProgressUpdateBlock = block.number;

        emit TokenTransformed(tokenId, oldState, attrs.state);
        emit AttributesUpdated(tokenId, attrs.level, attrs.evolutionProgress, attrs.state);

        // Note: This might necessitate external metadata update
        // if the tokenURI logic doesn't fully capture the state change.
    }

    /**
     * @dev Gets the required level for a token of a specific state to transform.
     * @param state The current state of the token.
     * @return uint256 The required level, or 0 if no transformation condition is set for this state.
     */
    function getTransformationRequiredLevel(uint8 state) public view returns (uint256) {
        return transformationRequiredLevel[state];
    }


    // --- Simulated Rewards (2 functions) ---

    /**
     * @dev Internal function to calculate and accrue simulated rewards based on staking duration since last claim.
     * This function is called during stake/unstake/claim to update the _accruedRewards mapping.
     * Reward calculation example: 1 reward unit per block staked.
     * @param tokenId The ID of the token.
     */
    function _calculateAccruedRewards(uint256 tokenId) internal {
        StakingInfo storage staking = _stakedTokens[tokenId];
        // Only calculate if staked and some blocks have passed since last claim/stake
        if (staking.stakedBy != address(0) && block.number > staking.lastRewardClaimBlock) {
            uint256 blocksSinceLastClaim = block.number - staking.lastRewardClaimBlock;
            // Example: 1 reward unit per block staked (can be made more complex)
            uint256 rewardsGained = blocksSinceLastClaim; // Simplified calculation

            _accruedRewards[tokenId] += rewardsGained;
            staking.lastRewardClaimBlock = block.number; // Update the last claim block
        }
    }

    /**
     * @dev Claims the accrued simulated rewards for a staked token.
     * Updates reward calculations and resets the accrued amount after claiming.
     * In a real contract, this would transfer ERC20 tokens.
     * @param tokenId The ID of the token.
     */
    function claimRewards(uint256 tokenId) public {
        require(isStaked(tokenId), "Token is not staked to claim rewards");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner"); // Only owner can claim
        require(_stakedTokens[tokenId].stakedBy == msg.sender, "Caller did not stake this token"); // Only original staker can claim

        _calculateAccruedRewards(tokenId); // Ensure rewards are up-to-date

        uint256 rewardsToClaim = _accruedRewards[tokenId];

        require(rewardsToClaim > 0, "No rewards accrued");

        _accruedRewards[tokenId] = 0; // Reset accrued rewards for this token

        // --- SIMULATED TRANSFER ---
        // In a real contract, you would interact with the reward token contract here.
        // Example: IRewardToken(rewardTokenAddress).transfer(msg.sender, rewardsToClaim);
        // For this example, we just emit the event.
        emit RewardClaimed(tokenId, msg.sender, rewardsToClaim);
        // --- END SIMULATION ---
    }

    // --- Metadata & Integrity (3 functions) ---

    /**
     * @dev Sets the base URI for token metadata. Only callable by the owner.
     * @param baseURI_ The new base URI.
     */
    function setBaseTokenURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseTokenURIUpdated(baseURI_);
    }

     /**
     * @dev Allows the owner or minter to store a hash of the token's expected metadata/art.
     * This provides an on-chain anchor for off-chain data integrity.
     * @param tokenId The ID of the token.
     * @param metadataHash_ The hash of the metadata/art.
     */
    function storeMetadataHash(uint256 tokenId, bytes32 metadataHash_) public onlyOwner { // Could be restricted to minter role if applicable
         _requireMinted(tokenId);
        _metadataHashes[tokenId] = metadataHash_;
        emit MetadataHashStored(tokenId, metadataHash_);
    }

    /**
     * @dev Gets the stored metadata hash for a token.
     * @param tokenId The ID of the token.
     * @return bytes32 The stored hash.
     */
    function getMetadataHash(uint256 tokenId) public view returns (bytes32) {
        _requireMinted(tokenId);
        return _metadataHashes[tokenId];
    }


    // --- Access Control & Owner Functions (6 functions) ---

    /**
     * @dev Allows the owner to set the evolution rate per block for staked tokens.
     * @param rate_ The new rate per block.
     */
    function setEvolutionRatePerBlockStaked(uint256 rate_) public onlyOwner {
        evolutionRatePerBlockStaked = rate_;
        emit EvolutionParametersUpdated(rate_);
    }

    /**
     * @dev Allows the owner to set the required evolution progress for a specific level.
     * @param level The level to set the threshold for.
     * @param requiredProgress The progress needed to reach this level.
     */
    function setLevelUpThreshold(uint256 level, uint256 requiredProgress) public onlyOwner {
        levelUpThresholds[level] = requiredProgress;
        // No specific event for this granular update, AttributesUpdated is enough.
    }

     /**
     * @dev Allows the owner to set the required level for a token in a specific state to transform.
     * @param state The state the token must be in.
     * @param requiredLevel The level required to transform from this state.
     */
    function setTransformationRequiredLevel(uint8 state, uint256 requiredLevel) public onlyOwner {
        transformationRequiredLevel[state] = requiredLevel;
        emit TransformationConditionUpdated(state, requiredLevel);
    }


    /**
     * @dev Pauses the staking functionality. Only owner.
     */
    function pauseStaking() public onlyOwner {
        stakingPaused = true;
        emit StakingPaused(true);
    }

    /**
     * @dev Unpauses the staking functionality. Only owner.
     */
    function unpauseStaking() public onlyOwner {
        stakingPaused = false;
        emit StakingPaused(false);
    }

    /**
     * @dev Sets the address of the simulated reward token contract.
     * In a real scenario, this would be the actual ERC20 token contract address.
     * @param tokenAddress The address of the reward token.
     */
    function setRewardTokenAddress(address tokenAddress) public onlyOwner {
        rewardTokenAddress = tokenAddress;
    }

    // --- Utility & Query Functions (4 functions) ---

    /**
     * @dev Burns a token. Can be called by the owner of the token or an approved operator.
     * Note: Burning a staked token might require unstaking first or handling in _beforeTokenTransfer.
     * Current implementation requires unstaking first.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) public {
        require(!isStaked(tokenId), "Cannot burn a staked token");
        _requireOwned(tokenId); // Ensure sender is owner or approved

        // Additional cleanup if needed before burning (e.g., deleting attributes)
        delete _tokenAttributes[tokenId];
         // Do NOT delete staking info here, as unstaking is required first.
         // Do NOT delete rewards here, as claiming is separate.
        delete _metadataHashes[tokenId];

        _burn(tokenId);
    }

    /**
     * @dev Gets the total supply of tokens minted.
     * @return uint256 The total number of tokens minted.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Gets the count of currently staked tokens.
     * Note: This would require iterating through all tokens or maintaining a separate counter,
     * which can be gas-intensive. A simpler view function can check individual token stake status.
     * We won't implement an efficient counter here for simplicity, but the `isStaked` function exists.
     * Let's provide a placeholder or note that iterating is inefficient.
     *
     * Alternative: Return max supply or similar non-iterative data.
     * Let's instead provide `getEvolutionRatePerBlockStaked` as a simple query.
     */

     /**
     * @dev Gets the current evolution rate per block for staked tokens.
     * @return uint256 The rate.
     */
    function getEvolutionRatePerBlockStaked() public view returns (uint256) {
        return evolutionRatePerBlockStaked;
    }

     /**
     * @dev Checks the accrued simulated rewards for a specific token without claiming.
     * Updates the rewards calculation internally first.
     * @param tokenId The ID of the token.
     * @return uint256 The currently accrued simulated rewards.
     */
    function checkAccruedRewards(uint256 tokenId) public {
        require(isStaked(tokenId), "Token is not staked");
         _calculateAccruedRewards(tokenId); // Ensure rewards are up-to-date
    }

    /**
     * @dev Gets the current accrued simulated rewards from storage (after potential calculation via checkAccruedRewards or claimRewards).
     * Note: Use `checkAccruedRewards` or `claimRewards` first to ensure this value is up-to-date.
     * @param tokenId The ID of the token.
     * @return uint256 The stored accrued simulated rewards.
     */
    function getStoredAccruedRewards(uint256 tokenId) public view returns (uint256) {
        return _accruedRewards[tokenId];
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal helper to ensure token exists.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "Token does not exist");
    }

    /**
     * @dev Internal helper to ensure token is owned by the caller or approved operator.
     * Overrides the one from ERC721 to include owner check.
     */
    function _requireOwned(uint256 tokenId) internal view override {
         require(_exists(tokenId), "Token does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender, "Caller is not owner nor approved");
    }

    // --- Function Count Check ---
    // Counting the public/external functions listed:
    // ERC721 Overrides (7): tokenURI, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
    // Custom Minting (1): mint
    // Attribute Management & Query (2): getTokenAttributes, getTokenState
    // Staking (4): stake, unstake, isStaked, getStakingInfo
    // Evolution (4): calculatePotentialEvolutionProgressGained, triggerEvolutionUpdate, getRequiredEvolutionProgressForNextLevel
    // Transformation (3): canTransform, transformToken, getTransformationRequiredLevel
    // Simulated Rewards (4): claimRewards, checkAccruedRewards, getStoredAccruedRewards (plus internal _calculateAccruedRewards) - counting public/external: claimRewards, checkAccruedRewards, getStoredAccruedRewards = 3
    // Metadata & Integrity (3): setBaseTokenURI, storeMetadataHash, getMetadataHash
    // Access Control & Owner (6): setEvolutionRatePerBlockStaked, setLevelUpThreshold, setTransformationRequiredLevel, pauseStaking, unpauseStaking, setRewardTokenAddress
    // Utility & Query (3): burn, getTotalSupply, getEvolutionRatePerBlockStaked

    // Total Public/External Functions: 7 + 1 + 2 + 4 + 3 + 3 + 3 + 6 + 3 = 32 functions.

    // Adding calculatePotentialEvolutionProgressGained = 33
    // Let's ensure no duplicates and clear separation.
    // Re-count:
    // 1. tokenURI
    // 2. balanceOf
    // 3. ownerOf
    // 4. approve
    // 5. getApproved
    // 6. setApprovalForAll
    // 7. isApprovedForAll
    // 8. mint
    // 9. getTokenAttributes
    // 10. getTokenState
    // 11. stake
    // 12. unstake
    // 13. isStaked
    // 14. getStakingInfo
    // 15. calculatePotentialEvolutionProgressGained
    // 16. triggerEvolutionUpdate
    // 17. getRequiredEvolutionProgressForNextLevel
    // 18. canTransform
    // 19. transformToken
    // 20. getTransformationRequiredLevel
    // 21. claimRewards
    // 22. checkAccruedRewards
    // 23. getStoredAccruedRewards
    // 24. setBaseTokenURI
    // 25. storeMetadataHash
    // 26. getMetadataHash
    // 27. setEvolutionRatePerBlockStaked
    // 28. setLevelUpThreshold
    // 29. setTransformationRequiredLevel
    // 30. pauseStaking
    // 31. unpauseStaking
    // 32. setRewardTokenAddress
    // 33. burn
    // 34. getTotalSupply
    // 35. getEvolutionRatePerBlockStaked

    // Total unique public/external functions = 35. More than 20. Mission accomplished.

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic On-Chain Attributes (`Attributes` struct):** Instead of just relying on an external `tokenURI`, core characteristics (`level`, `state`, `evolutionProgress`, `affinity`) are stored directly on the blockchain. This makes these traits immutable and verifiable on-chain.
2.  **Time/Block-Based Evolution (`evolutionProgress`, `lastProgressUpdateBlock`, `_updateEvolutionProgress`):** The contract tracks how many blocks have passed since a token's state was last updated while staked, using this to calculate accumulated "evolution progress".
3.  **Staking for Utility/Evolution (`_stakedTokens`, `stake`, `unstake`, `isStaked`):** Staking the NFT isn't just locking it; it's the *engine* for its evolution. This adds a functional use case beyond just ownership.
4.  **Leveling System (`levelUpThresholds`, `level`, `LevelUp` event):** Evolution progress leads to level increases, creating a clear progression path within the NFT's lifecycle.
5.  **Conditional State Transformation (`state`, `transformationRequiredLevel`, `canTransform`, `transformToken`, `TokenTransformed` event):** NFTs can undergo significant visual or functional changes ("transformations") when specific on-chain conditions are met (e.g., reaching a certain level *and* being unstaked). This creates distinct phases for the NFT.
6.  **Simulated Reward Mechanism (`_accruedRewards`, `rewardTokenAddress`, `claimRewards`, `RewardClaimed` event):** While not transferring actual tokens in this example, the structure for calculating and tracking rewards based on staking duration is included, demonstrating how NFTs can be integrated with DeFi-like earning mechanisms.
7.  **Dynamic `tokenURI`:** The `tokenURI` function is overridden to include on-chain attributes (like level and state) in the generated URL. This signals to an external metadata server that the JSON it serves should be dynamically generated based on the NFT's current on-chain state, making the *visual representation* or *description* of the NFT change as it evolves.
8.  **On-Chain Metadata Integrity Hash (`_metadataHashes`, `storeMetadataHash`, `getMetadataHash`, `MetadataHashStored` event):** While metadata is off-chain, storing a hash of the *expected* metadata (or a specific version of the art) on-chain provides a way for users or platforms to verify that the off-chain data hasn't been tampered with relative to the owner's recorded hash.
9.  **Parameterized Evolution (`evolutionRatePerBlockStaked`, `levelUpThresholds`, `transformationRequiredLevel`, `setEvolutionRatePerBlockStaked`, `setLevelUpThreshold`, `setTransformationRequiredLevel`):** Key parameters governing the evolution and transformation process are stored on-chain and can be adjusted by the contract owner, allowing for fine-tuning or future game design adjustments.
10. **Pausable Feature (`stakingPaused`, `pauseStaking`, `unpauseStaking`, `StakingPaused` event):** Includes a mechanism to pause the staking functionality in case of upgrades, maintenance, or issues.
11. **Publicly Callable Update (`triggerEvolutionUpdate`):** Allows *any* address to trigger the evolution progress update for a specific token. This externalizes the gas cost of keeping tokens up-to-date, benefiting the token owner without requiring them to perform the transaction themselves constantly.
12. **Attribute-Gated Functionality (`canTransform`, `transformToken` require conditions):** Certain functions (like `transformToken`) can only be called if the NFT meets specific attribute-based criteria (`canTransform`), demonstrating how on-chain state can unlock or restrict functionality.
13. **Structured Data (`structs`):** Using structs (`Attributes`, `StakingInfo`) keeps the related data for each token organized and improves code readability.
14. **Gas Optimization Considerations (Implicit):** By only updating evolution progress when necessary (stake, unstake, claim, or explicitly triggered), the contract avoids the gas cost of updating every token's state every block.
15. **Use of OpenZeppelin Libraries:** Leverages battle-tested libraries for ERC721 and Ownable features, focusing the custom logic on the unique mechanics.
16. **Detailed Events:** Emitting events for key actions (Minted, Staked, LevelUp, Transformed, etc.) makes the contract activity easily trackable and interpretable by off-chain applications, indexers, and users.
17. **Error Handling (`require`):** Robust input validation and state checks using `require` statements ensure functions are called correctly and state transitions are valid.
18. **Clear State Transitions:** The combination of `level`, `evolutionProgress`, and `state` creates a multi-layered, verifiable state machine for each NFT.
19. **Modular Functions:** Breaking down logic into smaller, focused functions (`_updateEvolutionProgress`, `_calculateAccruedRewards`, `canTransform`) improves readability and maintainability.
20. **Burn Functionality:** Standard `burn` functionality allowing removal of NFTs from circulation (with a check for staking status).

This contract goes significantly beyond a basic ERC-721 by adding state, mechanics, and interactions that make the NFT a dynamic, evolving asset class.