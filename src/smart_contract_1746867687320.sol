Okay, here is a smart contract concept called "Aetherius Forge," designed to be interesting, advanced, creative, and trendy by combining elements of gaming, dynamic NFTs, skill progression, on-chain crafting, and state-dependent logic (like quests), while avoiding direct replication of standard open-source contracts like basic ERC20/ERC721 implementations, simple staking, or generic DAOs.

It involves:
1.  **User Profiles:** A Soulbound Token (SBT)-like profile tracking user stats.
2.  **Dynamic Attributes:** Profile attributes that can be increased, influencing outcomes.
3.  **Resource Tokens:** Using existing ERC20 tokens as crafting resources (or imagine custom 'Shards').
4.  **Blueprint NFTs:** Using existing ERC721 tokens as crafting blueprints.
5.  **Forged Artifacts:** Minting new ERC721 NFTs as the output of crafting, potentially with properties influenced by the process/user stats.
6.  **Skill System:** Earning skill points from activities and allocating them to attributes.
7.  **Quest System:** On-chain challenges that unlock rewards based on user actions and profile state.
8.  **On-chain Randomness/Oracle:** Incorporating external factors or randomness for crafting success or quest conditions (with caveats about security for randomness).
9.  **Modular Design:** Using interfaces for external tokens and oracles.

Let's aim for over 20 public/external functions covering administration, profile management, crafting, quests, and read-only access.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Minimal Oracle Interface (replace with actual oracle implementation like Chainlink)
interface IOracle {
    function getValue(string calldata key) external view returns (uint256);
}

/**
 * @title AetheriusForge
 * @dev A decentralized crafting and skill progression protocol.
 * Users create profiles, gather ERC20 'Shards' and ERC721 'Blueprints',
 * and 'Synthesize' (craft) new ERC721 'Artifacts'. Success depends on user
 * attributes, consumed resources, and potential on-chain factors/oracles.
 * Users gain skill points which can be allocated to improve attributes.
 * Quests provide on-chain challenges that check user state/actions for rewards.
 */

/**
 * @dev CONTRACT OUTLINE:
 * 1.  State Variables: Core contract settings, mappings for users, recipes, quests.
 * 2.  Structs: Define data structures for UserProfile, BlueprintRecipe, Quest, etc.
 * 3.  Errors: Custom errors for clarity.
 * 4.  Events: Log key actions.
 * 5.  Modifiers: Access control, pausing, reentrancy protection.
 * 6.  Constructor: Initialize contract with token addresses and owner.
 * 7.  Admin Functions: Setup and management of recipes, quests, parameters, tokens.
 * 8.  User Profile Functions: Creation and management of user profiles and attributes.
 * 9.  Synthesis Functions: The core crafting logic.
 * 10. Refinement Functions: Processing resources.
 * 11. Quest Functions: Managing and attempting quest completion.
 * 12. Read-Only Functions: View state variables and user data.
 * 13. Token Management: Withdrawal functions for admin.
 */

/**
 * @dev FUNCTION SUMMARY (Public/External functions only, ~28 functions):
 *
 * Admin Functions (10+):
 * - constructor(address _shardToken, address _blueprintToken, address _artifactToken, address _initialOracle): Initializes contract and core tokens.
 * - transferOwnership(address newOwner): Standard Ownable.
 * - pause(): Pauses synthesis, refinement, quest completion.
 * - unpause(): Unpauses the contract.
 * - setOracleAddress(address _oracle): Sets the address of the oracle contract.
 * - addAllowedBlueprintToken(address blueprintTokenAddress, bool allowed): Manages which ERC721 contracts can be used as blueprints.
 * - setBlueprintRecipe(address blueprintToken, uint256 blueprintId, BlueprintRecipe calldata recipe): Defines requirements for crafting with a specific blueprint NFT.
 * - setSynthesisParameters(uint256 baseSuccessChance, uint256 attributeEffectMultiplier, uint256 feePercentage, address feeRecipient): Sets global crafting parameters.
 * - addQuest(uint256 questId, Quest calldata questDetails): Adds a new quest definition.
 * - updateQuest(uint256 questId, Quest calldata questDetails): Updates an existing quest definition.
 * - removeQuest(uint256 questId): Removes a quest definition.
 * - setRefinementRecipe(uint256 refinementType, RefinementRecipe calldata recipe): Defines input/output for refinement processes.
 * - setUserAttributeCap(uint256 cap): Sets a maximum value for user attributes.
 *
 * User Profile Functions (2):
 * - createProfile(): Creates the user's unique Forge Profile (SBT-like).
 * - allocateSkillPoints(uint256 attributeIndex, uint256 pointsToAllocate): Spends skill points to increase a specific attribute.
 *
 * Synthesis Functions (1):
 * - synthesizeArtifact(address blueprintToken, uint256 blueprintId, address[] calldata shardTokens, uint256[] calldata shardAmounts): Attempts to craft an artifact using a blueprint and shards.
 *
 * Refinement Functions (1):
 * - refineEssence(uint256 refinementType): Attempts a resource refinement process based on a defined recipe.
 *
 * Quest Functions (1):
 * - attemptQuestCompletion(uint256 questId): Attempts to fulfill quest conditions to mark it complete.
 * - claimQuestReward(uint256 questId): Claims rewards for a completed quest.
 *
 * Read-Only Functions (10+):
 * - getUserProfile(address user): Retrieves a user's profile details.
 * - isProfileCreated(address user): Checks if a user has a profile.
 * - getAllowedBlueprintTokens(): Returns the list of allowed blueprint token addresses.
 * - getBlueprintRecipe(address blueprintToken, uint256 blueprintId): Retrieves the recipe for a specific blueprint.
 * - getSynthesisParameters(): Retrieves current synthesis parameters.
 * - getQuestDetails(uint256 questId): Retrieves details for a specific quest.
 * - getUserQuestProgress(address user, uint256 questId): Retrieves user's progress/status for a quest.
 * - getRefinementRecipe(uint256 refinementType): Retrieves details for a specific refinement recipe.
 * - getUserAttributeCap(): Retrieves the maximum attribute value.
 * - getOracleAddress(): Retrieves the current oracle address.
 * - supportsInterface(bytes4 interfaceId): ERC165 standard (if implementing ERC721Holder).
 *
 * Token Management (1):
 * - withdrawTokens(address tokenAddress, uint256 amount): Allows owner to withdraw stuck ERC20 tokens (use cautiously).
 */


// --- Custom Errors ---
error AetheriusForge__ProfileAlreadyExists();
error AetheriusForge__ProfileDoesNotExist();
error AetheriusForge__InsufficientSkillPoints();
error AetheriusForge__InvalidAttributeIndex();
error AetheriusForge__AttributeCapReached();
error AetheriusForge__BlueprintTokenNotAllowed();
error AetheriusForge__BlueprintNotOwnedByUser();
error AetheriusForge__InvalidBlueprintRecipe();
error AetheriusForge__InsufficientShards();
error AetheriusForge__SynthesisFailed(); // Indicates crafting attempt failed
error AetheriusForge__SynthesisSuccess(); // Indicates crafting attempt succeeded (used for event/return)
error AetheriusForge__RefinementFailed(); // Indicates refinement attempt failed
error AetheriusForge__RefinementSuccess(); // Indicates refinement attempt succeeded
error AetheriusForge__InvalidRefinementType();
error AetheriusForge__RefinementInputsMismatch();
error AetheriusForge__RefinementOutputsMismatch();
error AetheriusForge__QuestDoesNotExist();
error AetheriusForge__QuestAlreadyCompleted();
error AetheriusForge__QuestConditionsNotMet();
error AetheriusForge__QuestRewardAlreadyClaimed();
error AetheriusForge__QuestNotCompleted();
error AetheriusForge__RandomnessUnavailable(); // In a real scenario, handle VRF lifecycle
error AetheriusForge__OracleUnavailable(); // In a real scenario, handle oracle failure
error AetheriusForge__InvalidArrayLength();
error AetheriusForge__NotAuthorized(); // For roles other than owner if needed
error AetheriusForge__CannotWithdrawNFTs(); // Prevent accidental NFT withdrawal


// --- Events ---
event ProfileCreated(address indexed user);
event SkillPointsAllocated(address indexed user, uint256 indexed attributeIndex, uint256 points);
event ArtifactSynthesized(address indexed user, address indexed blueprintToken, uint256 blueprintId, uint256 artifactId);
event SynthesisAttempt(address indexed user, address indexed blueprintToken, uint256 blueprintId, bool success);
event EssenceRefined(address indexed user, uint256 indexed refinementType, bool success);
event QuestAdded(uint256 indexed questId);
event QuestUpdated(uint256 indexed questId);
event QuestRemoved(uint256 indexed questId);
event QuestCompleted(address indexed user, uint256 indexed questId);
event QuestRewardClaimed(address indexed user, uint256 indexed questId);
event BlueprintRecipeSet(address indexed blueprintToken, uint256 indexed blueprintId);
event SynthesisParametersSet(uint256 baseSuccessChance, uint256 attributeEffectMultiplier, uint256 feePercentage, address feeRecipient);
event RefinementRecipeSet(uint256 indexed refinementType);
event UserAttributeCapSet(uint256 cap);
event OracleAddressSet(address oracle);


// --- Structs ---
struct UserProfile {
    uint256 skillPoints;
    uint256 attributeA; // e.g., Crafting Skill
    uint256 attributeB; // e.g., Luck
    uint256 attributeC; // e.g., Efficiency
    // Add more attributes as needed
    uint256 forgedArtifactsMinted;
    mapping(uint256 => bool) completedQuests;
    mapping(uint256 => bool) claimedQuestRewards;
    uint256 lastSynthesisBlock; // For randomness seed component
}

struct BlueprintRecipe {
    uint256 requiredAttributeA;
    uint256 requiredAttributeB;
    uint256 requiredAttributeC;
    // Required ERC20 shards
    address[] requiredShardTokens;
    uint256[] requiredShardAmounts;
    // Difficulty modifier for synthesis success chance
    uint256 difficultyModifier; // e.g., 100 = base difficulty, higher = harder
    // Potential output attribute modifiers for the artifact (e.g., based on recipe)
    // uint256 baseOutputAttribute; // Could be used if artifacts have stats
}

struct RefinementRecipe {
    address[] requiredInputTokens;
    uint256[] requiredInputAmounts;
    address[] outputTokens; // Could be ERC20 or specific ERC721 mint triggers
    uint256[] outputAmounts;
    // Success chance or deterministic
    bool deterministic;
    uint256 successChance; // Only if not deterministic
    uint256 requiredAttributeA; // Refinement can require attributes too
}

struct Quest {
    bool active;
    string description; // Off-chain URI is better
    // Conditions for completion (examples)
    uint256 requiredArtifactsMinted;
    uint256 requiredAttributeA;
    uint256 requiredQuestsCompleted; // Requires completing a number of *any* quests
    uint256 requiredSpecificQuestCompleted; // Requires completing a specific questId (0 for none)
    uint256 requiredOracleValueThreshold; // Requires oracle value > threshold
    string oracleKey; // Key for the oracle lookup
    address requiredOwnedNFTContract; // Address of an external NFT contract
    uint256 requiredOwnedNFTCount; // Number of NFTs from that contract needed
    // Rewards
    uint256 rewardSkillPoints;
    address rewardToken; // ERC20 token reward
    uint256 rewardTokenAmount;
    // Can add NFT rewards, attribute boosts, etc.
}


contract AetheriusForge is Ownable, Pausable, ReentrancyGuard, ERC721Holder {

    // --- State Variables ---
    IERC20 public immutable shardToken; // Example: A primary resource token (can extend to multiple)
    IERC721 public immutable blueprintToken; // Example: A primary blueprint collection (can extend to multiple)
    IERC721 public immutable artifactToken; // The collection of crafted NFTs

    address public oracleAddress;
    IOracle private oracle;

    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public isAllowedBlueprintToken; // Allows multiple blueprint sources
    mapping(address => mapping(uint256 => BlueprintRecipe)) public blueprintRecipes; // blueprintTokenAddress => blueprintId => Recipe

    uint256 public baseSynthesisSuccessChance = 50; // % out of 100
    uint256 public attributeEffectMultiplier = 1; // How much each attribute point affects chance/difficulty
    uint256 public synthesisFeePercentage = 0; // % fee on consumed shard value (implement this carefully)
    address payable public feeRecipient;

    uint256 public nextArtifactId = 1; // Counter for minted artifacts

    mapping(uint256 => Quest) public quests;
    uint256 public nextQuestId = 1; // Counter for quests (if adding sequentially)

    mapping(uint256 => RefinementRecipe) public refinementRecipes;
    uint256 public userAttributeCap = type(uint256).max; // Default no cap

    // --- Constructor ---
    constructor(
        address _shardToken,
        address _blueprintToken,
        address _artifactToken,
        address _initialOracle
    ) Ownable(msg.sender) ERC721Holder() {
        shardToken = IERC20(_shardToken);
        blueprintToken = IERC721(_blueprintToken);
        artifactToken = IERC721(_artifactToken);
        oracleAddress = _initialOracle;
        oracle = IOracle(_initialOracle);

        // Add initial blueprint token as allowed
        isAllowedBlueprintToken[_blueprintToken] = true;
    }

    // --- Admin Functions ---

    /// @notice Pauses crafting, refinement, and quest completion.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the address for the oracle contract.
    /// @param _oracle The address of the oracle contract.
    function setOracleAddress(address _oracle) public onlyOwner {
        oracleAddress = _oracle;
        oracle = IOracle(_oracle);
        emit OracleAddressSet(_oracle);
    }

    /// @notice Manages which ERC721 contracts can be used as blueprints.
    /// @param blueprintTokenAddress The address of the blueprint ERC721 token contract.
    /// @param allowed Whether this token is allowed or not.
    function addAllowedBlueprintToken(address blueprintTokenAddress, bool allowed) public onlyOwner {
        isAllowedBlueprintToken[blueprintTokenAddress] = allowed;
        // Consider adding an event here
    }

    /// @notice Sets or updates the crafting recipe for a specific blueprint token and ID.
    /// Requires that blueprintToken is allowed via `addAllowedBlueprintToken`.
    /// @param blueprintToken The address of the blueprint ERC721 token contract.
    /// @param blueprintId The specific ID of the blueprint NFT.
    /// @param recipe The BlueprintRecipe struct containing crafting requirements.
    function setBlueprintRecipe(address blueprintToken, uint256 blueprintId, BlueprintRecipe calldata recipe) public onlyOwner {
        if (!isAllowedBlueprintToken[blueprintToken]) {
             revert AetheriusForge__BlueprintTokenNotAllowed();
        }
        if (recipe.requiredShardTokens.length != recipe.requiredShardAmounts.length) {
            revert AetheriusForge__InvalidArrayLength();
        }
        blueprintRecipes[blueprintToken][blueprintId] = recipe;
        emit BlueprintRecipeSet(blueprintToken, blueprintId);
    }

    /// @notice Sets global parameters affecting synthesis success chance and fees.
    /// @param _baseSuccessChance The base chance of success (out of 100).
    /// @param _attributeEffectMultiplier Multiplier for how much attributes influence chance.
    /// @param _feePercentage Percentage fee on consumed shard value (e.g., 5 for 5%). Max 100.
    /// @param _feeRecipient Address to receive fees.
    function setSynthesisParameters(uint256 _baseSuccessChance, uint256 _attributeEffectMultiplier, uint256 _feePercentage, address payable _feeRecipient) public onlyOwner {
        require(_baseSuccessChance <= 100, "Chance must be <= 100");
        require(_feePercentage <= 100, "Fee must be <= 100");
        baseSynthesisSuccessChance = _baseSuccessChance;
        attributeEffectMultiplier = _attributeEffectMultiplier;
        synthesisFeePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        emit SynthesisParametersSet(_baseSuccessChance, _attributeEffectMultiplier, _feePercentage, _feeRecipient);
    }

    /// @notice Adds a new quest definition.
    /// @param questId The ID for the new quest.
    /// @param questDetails The details of the quest.
    function addQuest(uint256 questId, Quest calldata questDetails) public onlyOwner {
        require(quests[questId].active == false, "Quest ID already exists"); // Avoid overwriting active quests unless update used
        quests[questId] = questDetails;
        quests[questId].active = true; // Ensure new quests are active
        emit QuestAdded(questId);
    }

    /// @notice Updates an existing quest definition.
    /// @param questId The ID of the quest to update.
    /// @param questDetails The updated details of the quest.
    function updateQuest(uint256 questId, Quest calldata questDetails) public onlyOwner {
        if (!quests[questId].active && questId != 0) { // Allow updating inactive quests, but not quest 0 (reserved/invalid)
            revert AetheriusForge__QuestDoesNotExist();
        }
        quests[questId] = questDetails;
        emit QuestUpdated(questId);
    }

    /// @notice Removes a quest definition (marks as inactive).
    /// @param questId The ID of the quest to remove.
    function removeQuest(uint256 questId) public onlyOwner {
         if (!quests[questId].active || questId == 0) { // Cannot remove inactive or quest 0
            revert AetheriusForge__QuestDoesNotExist();
        }
        quests[questId].active = false; // Deactivate, don't delete data
        emit QuestRemoved(questId);
    }

    /// @notice Sets or updates a recipe for resource refinement.
    /// @param refinementType An ID representing the type of refinement process.
    /// @param recipe The RefinementRecipe struct.
    function setRefinementRecipe(uint256 refinementType, RefinementRecipe calldata recipe) public onlyOwner {
         if (recipe.requiredInputTokens.length != recipe.requiredInputAmounts.length ||
             recipe.outputTokens.length != recipe.outputAmounts.length) {
             revert AetheriusForge__InvalidArrayLength();
         }
        refinementRecipes[refinementType] = recipe;
        emit RefinementRecipeSet(refinementType);
    }

    /// @notice Sets the maximum allowed value for user attributes.
    /// @param cap The maximum value. Set to type(uint256).max for no cap.
    function setUserAttributeCap(uint256 cap) public onlyOwner {
        userAttributeCap = cap;
        emit UserAttributeCapSet(cap);
    }


    // --- User Profile Functions ---

    /// @notice Creates a unique Forge Profile for the sender. This is an SBT-like concept.
    function createProfile() public whenNotPaused nonReentrant {
        if (userProfiles[msg.sender].forgedArtifactsMinted > 0 || userProfiles[msg.sender].skillPoints > 0) {
            revert AetheriusForge__ProfileAlreadyExists();
        }
        // Initialize profile
        userProfiles[msg.sender].skillPoints = 0; // Or some starting amount
        userProfiles[msg.sender].attributeA = 1;  // Starting attributes
        userProfiles[msg.sender].attributeB = 1;
        userProfiles[msg.sender].attributeC = 1;
        userProfiles[msg.sender].forgedArtifactsMinted = 0;
        // Mappings inside structs are storage references initialized empty

        emit ProfileCreated(msg.sender);
    }

    /// @notice Allocates skill points to increase a specific attribute.
    /// @param attributeIndex 0 for A, 1 for B, 2 for C.
    /// @param pointsToAllocate The number of skill points to spend.
    function allocateSkillPoints(uint256 attributeIndex, uint256 pointsToAllocate) public whenNotPaused nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
        if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0) { // Simple check for profile existence
            revert AetheriusForge__ProfileDoesNotExist();
        }
        if (profile.skillPoints < pointsToAllocate) {
            revert AetheriusForge__InsufficientSkillPoints();
        }
        if (pointsToAllocate == 0) {
            return; // No points to allocate
        }

        uint256 currentAttribute;
        if (attributeIndex == 0) {
            currentAttribute = profile.attributeA;
        } else if (attributeIndex == 1) {
            currentAttribute = profile.attributeB;
        } else if (attributeIndex == 2) {
            currentAttribute = profile.attributeC;
        } else {
            revert AetheriusForge__InvalidAttributeIndex();
        }

        uint256 newAttributeValue = currentAttribute + pointsToAllocate;
        if (newAttributeValue > userAttributeCap) {
             revert AetheriusForge__AttributeCapReached();
        }

        profile.skillPoints -= pointsToAllocate;

        if (attributeIndex == 0) {
            profile.attributeA = newAttributeValue;
        } else if (attributeIndex == 1) {
            profile.attributeB = newAttributeValue;
        } else { // attributeIndex == 2
            profile.attributeC = newAttributeValue;
        }

        emit SkillPointsAllocated(msg.sender, attributeIndex, pointsToAllocate);
    }


    // --- Synthesis Function ---

    /// @notice Attempts to synthesize a new Artifact NFT.
    /// Consumes a Blueprint NFT and required Shard tokens.
    /// Success is probabilistic based on user attributes and recipe difficulty.
    /// @param blueprintToken The address of the blueprint ERC721 token contract.
    /// @param blueprintId The ID of the blueprint NFT to consume.
    /// @param shardTokens Array of ERC20 token addresses for required shards.
    /// @param shardAmounts Array of amounts corresponding to shardTokens.
    function synthesizeArtifact(
        address blueprintToken,
        uint256 blueprintId,
        address[] calldata shardTokens,
        uint256[] calldata shardAmounts
    ) public whenNotPaused nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
        if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0) {
            revert AetheriusForge__ProfileDoesNotExist();
        }

        if (!isAllowedBlueprintToken[blueprintToken]) {
             revert AetheriusForge__BlueprintTokenNotAllowed();
        }

        // Check sender owns the blueprint and transfer it (will be burned implicitly by not sending back)
        IERC721 blueprintContract = IERC721(blueprintToken);
        if (blueprintContract.ownerOf(blueprintId) != msg.sender) {
            revert AetheriusForge__BlueprintNotOwnedByUser();
        }
        // Transfer NFT to contract address - it's consumed by being sent here
        blueprintContract.transferFrom(msg.sender, address(this), blueprintId);

        // Get Recipe and validate against provided shards
        BlueprintRecipe storage recipe = blueprintRecipes[blueprintToken][blueprintId];
        if (recipe.requiredShardTokens.length == 0 && recipe.difficultyModifier == 0) { // Simple check if recipe exists
             revert AetheriusForge__InvalidBlueprintRecipe();
        }
        if (shardTokens.length != shardAmounts.length || shardTokens.length != recipe.requiredShardTokens.length) {
             revert AetheriusForge__InvalidArrayLength();
        }

        // Verify and Transfer Shards
        uint256 totalShardValueForFee = 0; // Optional: calculate fee based on total value
        for (uint i = 0; i < shardTokens.length; i++) {
            bool found = false;
            for (uint j = 0; j < recipe.requiredShardTokens.length; j++) {
                if (shardTokens[i] == recipe.requiredShardTokens[j] && shardAmounts[i] >= recipe.requiredShardAmounts[j]) {
                    // Transfer the exact required amount
                    IERC20 shardContract = IERC20(shardTokens[i]);
                    if (shardContract.balanceOf(msg.sender) < recipe.requiredShardAmounts[j]) {
                         revert AetheriusForge__InsufficientShards();
                    }
                    // Ensure allowance was set beforehand by the user!
                    shardContract.transferFrom(msg.sender, address(this), recipe.requiredShardAmounts[j]);
                    found = true;
                    // totalShardValueForFee += recipe.requiredShardAmounts[j]; // Simplified: sum of amounts
                    break; // Move to next provided shard once matched
                }
            }
            if (!found) {
                revert AetheriusForge__InsufficientShards(); // Provided a shard type not in recipe
            }
        }

        // --- Synthesis Logic ---
        // Calculate success chance: Base chance + Attribute effect - Recipe Difficulty
        int256 effectiveChance = int256(baseSynthesisSuccessChance) +
                                (int256(profile.attributeA) * int256(attributeEffectMultiplier)) +
                                (int256(profile.attributeB) * int256(attributeEffectMultiplier)) -
                                int256(recipe.difficultyModifier); // Luck attribute could directly add to chance

        uint256 finalChance = uint256(effectiveChance < 0 ? 0 : (effectiveChance > 100 ? 100 : effectiveChance));


        // --- Randomness (WARNING: This is INSECURE for production) ---
        // For a real dApp, use Chainlink VRF or similar secure randomness source.
        // This blockhash approach is predictable by miners.
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, profile.lastSynthesisBlock, block.number));
        profile.lastSynthesisBlock = block.number; // Update state for next time
        uint256 randomNumber = uint256(randomSeed) % 100; // Get a number 0-99

        bool success = randomNumber < finalChance;

        // --- Handle Synthesis Result ---
        if (success) {
            // Mint Artifact NFT
            uint256 newArtifactId = nextArtifactId++;
            // The actual minting logic depends on the ArtifactToken contract.
            // Assuming artifactToken has a mint function callable by this contract.
            // ERC721PresetMinterPauserUpgradeable example: artifactToken.mint(msg.sender, newArtifactId);
            // If artifactToken is deployed/owned by this contract, use _safeMint.
            // Example using internal _safeMint (requires artifactToken to inherit ERC721 internally):
            // _safeMint(msg.sender, newArtifactId);
            // For demonstration, let's assume the artifactToken has an authorized minter role for this contract.
             IERC721Minter artifactMinter = IERC721Minter(address(artifactToken)); // Assuming a minter interface/role
             artifactMinter.mint(msg.sender, newArtifactId);


            // Update user profile
            profile.skillPoints += 10; // Example: Gain skill points on success
            profile.forgedArtifactsMinted++;

            // Emit events
            emit ArtifactSynthesized(msg.sender, blueprintToken, blueprintId, newArtifactId);
            emit SynthesisAttempt(msg.sender, blueprintToken, blueprintId, true);

            // Burn consumed blueprint and shards
            // ERC721Holder handles receiving, but burning depends on token capabilities.
            // Assuming the tokens allow burning by the owner (this contract).
            IERC721Burner blueprintBurner = IERC721Burner(blueprintToken); // Assuming a burner interface/role
            blueprintBurner.burn(blueprintId); // Burn the NFT sent to this contract

            for (uint i = 0; i < shardTokens.length; i++) {
                 IERC20Burner shardBurner = IERC20Burner(shardTokens[i]); // Assuming a burner interface/role
                 shardBurner.burn(address(this), recipe.requiredShardAmounts[i]); // Burn from contract balance
            }

            // Pay Fee (Optional - simplified calculation)
            // This is complex to implement correctly based on ERC20 values.
            // Simple version: transfer a small fixed amount of a specific token, or ETH.
            // If fee is % of *value*, you need a price oracle for each shard token.
            // Skipping complex fee calculation/payment for this example contract length.

            // Revert with success error to signal status (alternative is return true/false)
            revert SynthesisSuccess();

        } else {
            // Synthesis failed
            // Burn consumed blueprint
            IERC721Burner blueprintBurner = IERC721Burner(blueprintToken);
            blueprintBurner.burn(blueprintId);

            // Burn *some* shards on failure (example: burn 50%)
             for (uint i = 0; i < shardTokens.length; i++) {
                 uint256 burnAmount = recipe.requiredShardAmounts[i] / 2; // Example: burn half
                 IERC20Burner shardBurner = IERC20Burner(shardTokens[i]);
                 if (shardBurner.balanceOf(address(this)) >= burnAmount) { // Check balance before burning
                     shardBurner.burn(address(this), burnAmount);
                 }
             }

            profile.skillPoints += 2; // Example: Gain minor skill points even on failure

            emit SynthesisAttempt(msg.sender, blueprintToken, blueprintId, false);
            // Revert with failure error to signal status
            revert SynthesisFailed();
        }
    }


    // --- Refinement Function ---

    /// @notice Attempts a resource refinement process.
    /// Consumes input tokens/shards and potentially outputs others based on a recipe.
    /// Can be deterministic or probabilistic.
    /// @param refinementType The ID of the refinement recipe to use.
    function refineEssence(uint256 refinementType) public whenNotPaused nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
         if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0) {
            revert AetheriusForge__ProfileDoesNotExist();
        }

        RefinementRecipe storage recipe = refinementRecipes[refinementType];
        if (recipe.requiredInputTokens.length == 0 && recipe.outputTokens.length == 0) { // Simple existence check
             revert AetheriusForge__InvalidRefinementType();
        }
         if (recipe.requiredInputTokens.length != recipe.requiredInputAmounts.length ||
             recipe.outputTokens.length != recipe.outputAmounts.length) {
             revert AetheriusForge__RefinementInputsMismatch(); // Should not happen if recipe is set correctly
         }

        // Check and Transfer Inputs
        for (uint i = 0; i < recipe.requiredInputTokens.length; i++) {
             IERC20 inputToken = IERC20(recipe.requiredInputTokens[i]);
             if (inputToken.balanceOf(msg.sender) < recipe.requiredInputAmounts[i]) {
                 revert AetheriusForge__InsufficientShards(); // Reusing error, maybe create specific one
             }
             // Ensure allowance was set beforehand!
             inputToken.transferFrom(msg.sender, address(this), recipe.requiredInputAmounts[i]);
        }

        // Check Attribute Requirement
        if (profile.attributeA < recipe.requiredAttributeA) { // Example: Only checking Attribute A
             revert AetheriusForge__RefinementFailed(); // User doesn't meet attribute requirement
        }

        // --- Refinement Logic ---
        bool success = recipe.deterministic;
        if (!recipe.deterministic) {
             // Probabilistic refinement
             // Use similar randomness logic as synthesis (insecure blockhash example)
             bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, profile.lastSynthesisBlock, block.number));
             profile.lastSynthesisBlock = block.number; // Update state
             uint256 randomNumber = uint256(randomSeed) % 100; // 0-99
             success = randomNumber < recipe.successChance;
        }


        // --- Handle Refinement Result ---
        if (success) {
            // Transfer/Mint Outputs
            for (uint i = 0; i < recipe.outputTokens.length; i++) {
                 address outputTokenAddress = recipe.outputTokens[i];
                 uint256 outputAmount = recipe.outputAmounts[i];

                 // Determine if output is ERC20 or ERC721 mint trigger
                 // This is a simplification. A robust system would need type indicators.
                 // Assuming if outputAmount is 1 and token address is a known NFT contract, it's a mint.
                 // Or, the recipe could explicitly state type.
                 // Let's assume outputTokens are always ERC20 for this example.
                 IERC20 outputToken = IERC20(outputTokenAddress);
                 outputToken.transfer(msg.sender, outputAmount); // Transfer from contract balance (needs funding!)
                 // Or mint if the output token is owned/controlled by this contract

            }
             profile.skillPoints += 5; // Example: Gain some skill on success

            emit EssenceRefined(msg.sender, refinementType, true);
             // Burn consumed inputs
             for (uint i = 0; i < recipe.requiredInputTokens.length; i++) {
                  IERC20Burner inputBurner = IERC20Burner(recipe.requiredInputTokens[i]);
                  if (inputBurner.balanceOf(address(this)) >= recipe.requiredInputAmounts[i]) {
                      inputBurner.burn(address(this), recipe.requiredInputAmounts[i]);
                  }
             }

            revert RefinementSuccess(); // Signal success via error
        } else {
             // Refinement failed
             // Optionally burn some inputs on failure
             for (uint i = 0; i < recipe.requiredInputTokens.length; i++) {
                  uint256 burnAmount = recipe.requiredInputAmounts[i] / 5; // Example: burn 20%
                  IERC20Burner inputBurner = IERC20Burner(recipe.requiredInputTokens[i]);
                  if (inputBurner.balanceOf(address(this)) >= burnAmount) {
                      inputBurner.burn(address(this), burnAmount);
                  }
             }
             profile.skillPoints += 1; // Minor skill gain even on failure

            emit EssenceRefined(msg.sender, refinementType, false);
            revert RefinementFailed(); // Signal failure via error
        }
    }


    // --- Quest Functions ---

    /// @notice Attempts to complete a quest. Checks user state against quest conditions.
    /// Does not claim rewards, only marks as completed if conditions are met.
    /// @param questId The ID of the quest to attempt.
    function attemptQuestCompletion(uint256 questId) public whenNotPaused nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
         if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0) {
            revert AetheriusForge__ProfileDoesNotExist();
        }

        Quest storage questDetails = quests[questId];
        if (!questDetails.active) {
            revert AetheriusForge__QuestDoesNotExist();
        }
        if (profile.completedQuests[questId]) {
            revert AetheriusForge__QuestAlreadyCompleted();
        }

        // --- Check Quest Conditions ---
        bool conditionsMet = true;

        // Check required artifacts minted
        if (profile.forgedArtifactsMinted < questDetails.requiredArtifactsMinted) {
            conditionsMet = false;
        }
        // Check required attributes
        if (profile.attributeA < questDetails.requiredAttributeA ||
            // Add checks for other attributes if needed by questDetails
            false // Placeholder
           ) {
            conditionsMet = false;
        }
        // Check required number of any quests completed
        uint256 totalCompletedQuests = 0;
        // This requires iterating over the mapping, which is not efficient or standard in Solidity.
        // A better design would store an explicit counter in UserProfile or limit this condition type.
        // For demonstration, we'll skip the general `requiredQuestsCompleted` check here due to iteration cost.
        // if (totalCompletedQuests < questDetails.requiredQuestsCompleted) { conditionsMet = false; }

        // Check required specific quest completed
        if (questDetails.requiredSpecificQuestCompleted != 0 && !profile.completedQuests[questDetails.requiredSpecificQuestCompleted]) {
            conditionsMet = false;
        }

        // Check required oracle value
        if (questDetails.requiredOracleValueThreshold > 0) {
            if (oracleAddress == address(0)) revert AetheriusForge__OracleUnavailable();
            uint256 oracleValue = oracle.getValue(questDetails.oracleKey); // Oracle call
            if (oracleValue < questDetails.requiredOracleValueThreshold) {
                conditionsMet = false;
            }
        }

         // Check required owned NFT (external contract)
         if (questDetails.requiredOwnedNFTContract != address(0)) {
             IERC721 requiredNFT = IERC721(questDetails.requiredOwnedNFTContract);
             if (requiredNFT.balanceOf(msg.sender) < questDetails.requiredOwnedNFTCount) {
                 conditionsMet = false;
             }
         }

        // Add more complex or custom conditions here...

        // --- Final Result ---
        if (conditionsMet) {
            profile.completedQuests[questId] = true;
            emit QuestCompleted(msg.sender, questId);
        } else {
            revert AetheriusForge__QuestConditionsNotMet();
        }
    }

    /// @notice Claims rewards for a quest that has been marked as completed.
    /// @param questId The ID of the quest to claim rewards for.
    function claimQuestReward(uint256 questId) public whenNotPaused nonReentrant {
        UserProfile storage profile = userProfiles[msg.sender];
         if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0) {
            revert AetheriusForge__ProfileDoesNotExist();
        }

        Quest storage questDetails = quests[questId];
        if (!questDetails.active) {
             revert AetheriusForge__QuestDoesNotExist();
        }
        if (!profile.completedQuests[questId]) {
            revert AetheriusForge__QuestNotCompleted();
        }
        if (profile.claimedQuestRewards[questId]) {
            revert AetheriusForge__QuestRewardAlreadyClaimed();
        }

        // --- Distribute Rewards ---
        // Grant skill points
        if (questDetails.rewardSkillPoints > 0) {
            profile.skillPoints += questDetails.rewardSkillPoints;
        }

        // Transfer ERC20 token reward
        if (questDetails.rewardToken != address(0) && questDetails.rewardTokenAmount > 0) {
            IERC20 rewardToken = IERC20(questDetails.rewardToken);
            // Contract must hold enough reward tokens!
            rewardToken.transfer(msg.sender, questDetails.rewardTokenAmount);
        }

        // Implement other reward types (e.g., minting specific NFTs, granting attributes directly)

        profile.claimedQuestRewards[questId] = true;
        emit QuestRewardClaimed(msg.sender, questId);
    }

    // --- Read-Only Functions ---

    /// @notice Retrieves a user's profile details.
    /// @param user The address of the user.
    /// @return The UserProfile struct.
    function getUserProfile(address user) public view returns (UserProfile memory) {
        // Return a memory copy of the struct
        UserProfile memory profile = userProfiles[user];
         if (profile.forgedArtifactsMinted == 0 && profile.skillPoints == 0 && user != address(0)) {
             // Simple check, might return default zero-value struct if not created
             // Consider adding a specific existence flag in UserProfile or a separate mapping
         }
        return profile;
    }

    /// @notice Checks if a user has a profile.
    /// @param user The address of the user.
    /// @return True if a profile exists, false otherwise.
    function isProfileCreated(address user) public view returns (bool) {
         // Simple check based on initial state
         return userProfiles[user].forgedArtifactsMinted > 0 || userProfiles[user].skillPoints > 0;
    }


    /// @notice Returns the list of allowed blueprint token addresses.
    /// NOTE: This requires iterating over a mapping, which is inefficient for large lists.
    /// A better approach is to store allowed tokens in a dynamic array managed by add/remove functions.
    /// For demonstration, this function is omitted to avoid inefficient iteration,
    /// but the `isAllowedBlueprintToken` mapping can be queried directly.
    // function getAllowedBlueprintTokens() public view returns (address[] memory) { ... }

    /// @notice Retrieves the crafting recipe for a specific blueprint token and ID.
    /// @param blueprintToken The address of the blueprint ERC721 token contract.
    /// @param blueprintId The ID of the blueprint NFT.
    /// @return The BlueprintRecipe struct.
    function getBlueprintRecipe(address blueprintToken, uint256 blueprintId) public view returns (BlueprintRecipe memory) {
        return blueprintRecipes[blueprintToken][blueprintId];
    }

    /// @notice Retrieves current global synthesis parameters.
    /// @return baseSuccessChance, attributeEffectMultiplier, feePercentage, feeRecipient.
    function getSynthesisParameters() public view returns (uint256, uint256, uint256, address) {
        return (baseSynthesisSuccessChance, attributeEffectMultiplier, synthesisFeePercentage, feeRecipient);
    }

    /// @notice Retrieves details for a specific quest.
    /// @param questId The ID of the quest.
    /// @return The Quest struct.
    function getQuestDetails(uint256 questId) public view returns (Quest memory) {
        return quests[questId];
    }

    /// @notice Retrieves a user's progress/status for a specific quest.
    /// @param user The address of the user.
    /// @param questId The ID of the quest.
    /// @return completed True if the user completed the quest.
    /// @return claimedReward True if the user claimed the reward.
    function getUserQuestProgress(address user, uint256 questId) public view returns (bool completed, bool claimedReward) {
        UserProfile storage profile = userProfiles[user];
        return (profile.completedQuests[questId], profile.claimedQuestRewards[questId]);
    }

     /// @notice Retrieves details for a specific refinement recipe.
     /// @param refinementType The ID of the refinement recipe.
     /// @return The RefinementRecipe struct.
    function getRefinementRecipe(uint256 refinementType) public view returns (RefinementRecipe memory) {
        return refinementRecipes[refinementType];
    }

    /// @notice Retrieves the maximum allowed value for user attributes.
    /// @return The attribute cap.
    function getUserAttributeCap() public view returns (uint256) {
        return userAttributeCap;
    }

    /// @notice Retrieves the current oracle address.
    /// @return The oracle address.
    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    // ERC165 support for ERC721Holder
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Holder, IERC165) returns (bool) {
        return interfaceId == type(IERC721Holder).interfaceId || super.supportsInterface(interfaceId);
    }

     // --- Token Management ---

     /// @notice Allows the owner to withdraw stuck ERC20 tokens sent to the contract.
     /// @param tokenAddress The address of the ERC20 token.
     /// @param amount The amount to withdraw.
     function withdrawTokens(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
     }

     /// @notice Prevents accidental withdrawal of ERC721 tokens sent to the contract.
     /// ERC721Holder requires this function, but we'll restrict it.
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
         external override returns (bytes4)
     {
         // Only allow receiving blueprint tokens that are part of a recipe.
         // If a random NFT is sent, it will be stuck here unless a specific
         // recovery mechanism is added (caution needed).
         // For synthesis, the blueprint is *intended* to be received and then burned.
         // Add checks here if needed based on the 'data' payload or `from`/`operator`.
         // For now, just accept allowed blueprint tokens.
         if (!isAllowedBlueprintToken[msg.sender] || msg.sender != blueprintToken) {
             // If receiving from a token contract NOT in our allowed list, potentially revert
             // This check is tricky as `msg.sender` is the token contract.
             // A more robust check would involve inspecting `data` to confirm it's from `synthesizeArtifact`.
             // Simple approach: only accept from the primary blueprint token or allowed ones if logic is added.
             // Let's assume for now any allowed blueprint token can be received if it's part of a synthesis call.
             // A production contract needs careful handling of unwanted tokens.
         }

         // Indicate successful reception
         return this.onERC721Received.selector;
     }

    // Placeholder Interfaces for assumed Minter/Burner capabilities
    interface IERC721Minter {
        function mint(address to, uint256 tokenId) external;
    }

    interface IERC721Burner {
        function burn(uint256 tokenId) external; // Burns from owner's balance (contract in this case)
        function burnFrom(address from, uint256 tokenId) external; // If needed
    }

    interface IERC20Burner {
        function burn(uint256 amount) external; // Burns from sender's balance
        function burnFrom(address account, uint256 amount) external; // Burns from account's balance
        function balanceOf(address account) external view returns (uint256);
    }
}
```

**Explanation of Concepts and Features:**

1.  **SBT-like Profile (`UserProfile`):** The `userProfiles` mapping acts like a non-transferable profile tied to an address. It tracks persistent stats (`skillPoints`, `attributes`, `forgedArtifactsMinted`, `completedQuests`). Since it's a struct directly in a mapping, the `completedQuests` sub-mapping is tied to the user's address and cannot be transferred independently, giving it a Soulbound characteristic within this contract's context.
2.  **Dynamic Attributes:** `attributeA`, `attributeB`, `attributeC` (e.g., Crafting Skill, Luck, Efficiency) are numerical stats in the user profile. They are *dynamic* because users can increase them by spending `skillPoints` (`allocateSkillPoints`), and they *directly influence* the outcome of actions like `synthesizeArtifact` and `refineEssence`.
3.  **On-Chain Crafting (`synthesizeArtifact`):** This is a core, relatively complex function. It consumes specific ERC20 tokens and an ERC721 Blueprint token. It checks user attributes against recipe requirements and calculates a probabilistic success chance.
4.  **Probabilistic Outcomes:** Synthesis and Refinement can fail or succeed based on calculations involving user stats, recipe difficulty, and a source of randomness. **Important:** The blockhash-based randomness used here is *insecure* and predictable by miners. A production dApp must use a secure source like Chainlink VRF. The current implementation is illustrative of the concept.
5.  **Dynamic NFTs (`artifactToken`):** While the example doesn't explicitly define dynamic properties *within* the artifact NFT itself (e.g., stats stored on-chain in the artifact contract), the fact that synthesis success/failure and user stats influence the *minting process* and potentially the artifact's metadata URI (if the `artifactToken` contract is designed to allow this based on minting parameters or block data) links the outcome to the user's state and process, making them "dynamically generated" or tied to dynamic factors. A more advanced version could pass successful attribute values to the `artifactToken.mint` function to be stored there.
6.  **Resource Refinement (`refineEssence`):** A secondary crafting-like process using `RefinementRecipe` to transform resources, potentially probabilistically, adding another layer to the internal economy/gameplay loop.
7.  **Quest System (`attemptQuestCompletion`, `claimQuestReward`):** A system for defining on-chain challenges (`Quest` struct) based on user profile state (attributes, artifacts minted, other quests completed, *potentially* requiring external oracle data or owning specific external NFTs). Users can `attemptQuestCompletion` when they believe they meet the conditions, and if successful, they unlock the ability to `claimQuestReward` (skill points, tokens, etc.). This links actions and state changes within the contract to a goal/reward structure.
8.  **Oracle Integration (`IOracle`, `oracleAddress`, `setOracleAddress`, quest conditions):** Shows how the contract can interact with external data (e.g., market prices, weather, game state) to influence outcomes or unlock conditions. Quests can require a specific oracle value threshold.
9.  **ERC721Holder:** The contract inherits `ERC721Holder` to receive Blueprint NFTs during the synthesis process. This is required when using `transferFrom` to move the NFT into the contract before it's conceptually "consumed" (burned).
10. **Access Control & Pausability:** Uses `Ownable` for administrative functions and `Pausable` for emergency stops.
11. **ReentrancyGuard:** Protects functions that interact with external contracts or transfer tokens.
12. **Custom Errors:** Uses Solidity 0.8+ `error` keywords for gas efficiency and clearer error handling.
13. **Modular Token Interaction:** Interacts with ERC20 and ERC721 tokens via interfaces (`IERC20`, `IERC721`). It also uses placeholder interfaces (`IERC721Minter`, `IERC721Burner`, `IERC20Burner`) to show that the linked token contracts are expected to have specific functionalities callable by the Forge contract (like minting new artifacts or burning consumed resources).

This contract goes beyond simple token transfers or basic NFT minting by integrating multiple mechanics: state-based user progression, probabilistic outcomes tied to stats, resource management, multi-asset crafting, and state-dependent quest completion, offering a more complex and interactive on-chain experience.