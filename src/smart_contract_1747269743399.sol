Okay, let's create a smart contract concept around dynamic digital assets, combining elements of crafting, staking, and a simple form of on-chain evolution/modification, avoiding direct copy-pastes of common open-source patterns by focusing on the *combination* and *interaction* of these features within a unique theme.

Let's call it "Digital Alchemist". Users will use different types of "Essence" (ERC-20 tokens) and "Catalysts" (another ERC-20 token) to "Synthesize" unique "Artifacts" (ERC-721 tokens). These Artifacts will have dynamic properties that can be upgraded or altered through further interaction, and users can stake tokens for benefits.

---

**Contract Name:** DigitalAlchemist

**Description:**
A smart contract system facilitating the creation (Synthesis) and modification (Alchemy) of unique digital assets (Artifacts) using fungible components (Essence and Catalyst tokens). It incorporates mechanics for defining recipes, managing ingredient costs, dynamic NFT properties, token staking for benefits, and a basic governance layer for recipe discovery. This contract interacts with external ERC-20 and ERC-721 tokens.

**Concepts Used:**
*   ERC-20 and ERC-721 Interaction (external tokens)
*   Access Control (Roles for management)
*   Pausable Pattern
*   Data Structuring (Recipes, Artifact Properties, Staking State)
*   Dynamic NFT Properties (Stored on-chain, referenced by `tokenURI`)
*   Crafting/Synthesis Mechanics (Burning ingredients, Minting result)
*   Token Staking (for yield and synthesis boosts)
*   Cooldowns (Preventing spam/abuse)
*   Basic Governance/Proposal System (Recipe Discovery)
*   Token Burning (Transmutation)
*   Upgradeable Assets (Property updates)

**Key Features & Functions Summary:**
1.  **Token Management:** Set/Get addresses of associated Essence (ERC20), Catalyst (ERC20), and Artifact (ERC721) contracts.
2.  **Recipe Management:** Define, update, remove, and view Synthesis recipes (ingredient costs, cooldowns).
3.  **Synthesis:** Core function to consume ingredients and mint a new Artifact based on a recipe, respecting cooldowns and staking boosts.
4.  **Artifact Properties:** Store and retrieve dynamic properties for each minted Artifact.
5.  **Artifact Alchemy:** Functions to upgrade Artifact properties or Transmute (burn) an Artifact for rewards.
6.  **Staking:** Stake Essence for passive yield, stake Catalyst for synthesis benefits (e.g., cooldown reduction, property boost chance).
7.  **Yield Claiming:** Claim accumulated yield from staked Essence.
8.  **Governance (Recipe Proposal):** Allow users to propose new recipes and vote on them using staked tokens.
9.  **Access Control & Utility:** Pause contract operations, withdraw rescue tokens, manage roles (Admin, RecipeManager, Governor, Pauser).
10. **View Functions:** Retrieve various state data (stakes, cooldowns, recipes, proposals, artifact data).

**Outline:**
1.  SPDX License, Pragma, Imports (OpenZeppelin interfaces and utilities).
2.  Interfaces for ERC20 and ERC721.
3.  Role Definitions (Constants).
4.  Events.
5.  Struct Definitions (Recipe, ArtifactProperties, StakedEssence, StakedCatalyst, RecipeProposal).
6.  State Variables (Token addresses, counters, mappings for recipes, properties, stakes, cooldowns, proposals, votes).
7.  Constructor (Initialize roles, set initial token addresses).
8.  Access Control Functions (`grantRole`, `revokeRole`, `hasRole`, `renounceRole`).
9.  Pausable Functions (`pause`, `unpause`).
10. Token Address Management Functions.
11. Recipe Management Functions (`addRecipe`, `updateRecipe`, `removeRecipe`, `getRecipe`, `getRecipeCount`, `getSynthesizableRecipes`).
12. Synthesis Function (`synthesizeArtifact`) & related views (`getUserCooldown`, `getLatestArtifactId`).
13. Staking Functions (`stakeEssence`, `unstakeEssence`, `claimEssenceYield`, `getStakedEssence`, `getPendingEssenceYield`).
14. Catalyst Staking Functions (`stakeCatalyst`, `unstakeCatalyst`, `getCatalystStakeBoost`).
15. Artifact Alchemy Functions (`transmuteArtifact`, `upgradeArtifact`, `getArtifactProperties`).
16. Governance Functions (`proposeRecipe`, `voteOnRecipeProposal`, `executeRecipeProposal`, `getRecipeProposal`, `getRecipeProposalCount`, `getRecipeProposalVoteStatus`).
17. Utility Function (`withdrawToken`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // For tokenURI
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Interfaces ---

interface IEssence is IERC20 {}
interface ICatalyst is IERC20 {}
interface IArtifact is IERC721, IERC721Metadata {
    // Assuming the Artifact contract has a mint function callable by this contract
    function mint(address to, uint256 tokenId) external;
    // Assuming the Artifact contract allows burning by approved addresses (like this contract)
    function burn(uint256 tokenId) external;
    // Artifact contract might need a way for Alchemist to set base URI dynamically, or rely on Alchemist's data
    function setTokenURI(uint256 tokenId, string calldata uri) external; // Example: if artifact supports URI update
}

// --- Contract Definition ---

contract DigitalAlchemist is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RECIPE_MANAGER_ROLE = keccak256("RECIPE_MANAGER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- Events ---
    event TokenAddressesUpdated(address indexed essence, address indexed catalyst, address indexed artifact);
    event RecipeAdded(uint256 indexed recipeId, uint256 essenceAmount, uint256 catalystAmount, uint256 cooldownDuration);
    event RecipeUpdated(uint256 indexed recipeId, uint256 essenceAmount, uint256 catalystAmount, uint256 cooldownDuration);
    event RecipeRemoved(uint256 indexed recipeId);
    event ArtifactSynthesized(address indexed user, uint256 indexed recipeId, uint256 indexed artifactId);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event EssenceYieldClaimed(address indexed user, uint256 amount);
    event CatalystStaked(address indexed user, uint256 amount);
    event CatalystUnstaked(address indexed user, uint256 amount);
    event ArtifactTransmuted(address indexed user, uint256 indexed artifactId, uint256 returnedEssence);
    event ArtifactUpgraded(address indexed user, uint256 indexed artifactId, uint256 newPower, string metadataUri);
    event RecipeProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 essenceAmount, uint256 catalystAmount);
    event RecipeProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event RecipeProposalExecuted(uint256 indexed proposalId, uint256 indexed recipeId);

    // --- State Variables ---
    IEssence private essenceToken;
    ICatalyst private catalystToken;
    IArtifact private artifactNFT;

    struct Recipe {
        uint256 essenceAmount;
        uint256 catalystAmount;
        uint64 cooldownDuration; // in seconds
        bool isActive; // Can this recipe be used?
        // Note: artifactBaseURI could be stored per recipe, but let's manage properties on-chain
        // string artifactBaseURI; // Base URI for metadata service
    }

    mapping(uint256 => Recipe) private recipes;
    Counters.Counter private recipeCounter;

    struct ArtifactProperties {
        uint256 power;
        uint256 creationTime; // Timestamp of synthesis
        uint256 upgradeCount; // How many times this artifact has been upgraded
        // Add more properties as needed, e.g., element, rarity, etc.
        // uint8 element; // 0: Fire, 1: Water, etc.
    }

    mapping(uint256 => ArtifactProperties) private artifactData; // Maps artifact tokenId to its properties

    mapping(address => mapping(uint256 => uint64)) private userSynthesisCooldowns; // user => recipeId => cooldown expiration timestamp

    struct StakedEssence {
        uint256 amount;
        uint64 lastYieldClaimTime; // Timestamp
        uint256 accumulatedYield; // Simple accrued yield value
    }

    mapping(address => StakedEssence) private stakedEssence;
    uint256 public totalStakedEssence;
    uint256 public essenceYieldRate; // e.g., per second or per block - simplified for example

    struct StakedCatalyst {
        uint256 amount;
        // Could add specific catalyst staking benefits here
    }
    mapping(address => StakedCatalyst) private stakedCatalyst;
    uint256 public totalStakedCatalyst;
    uint256 public catalystBoostFactor; // e.g., percentage multiplier for cooldown reduction or property boost chance

    struct RecipeProposal {
        address proposer;
        uint256 essenceAmount;
        uint256 catalystAmount;
        uint64 cooldownDuration;
        // string artifactBaseURI; // If needed
        uint256 votesFor;
        uint256 votesAgainst;
        uint64 creationTime;
        bool isApproved; // Passed vote threshold
        bool isExecuted; // Recipe added
        // Could add expiration time
    }

    mapping(uint256 => RecipeProposal) private recipeProposals;
    Counters.Counter private proposalCounter;
    mapping(uint256 => mapping(address => bool)) private proposalVotes; // proposalId => voter => hasVoted

    uint256 public recipeProposalVoteThreshold; // Minimum votes needed (simple count or token weight)
    uint256 public recipeProposalQuorum; // Minimum total votes needed

    // --- Constructor ---
    constructor(
        address _essenceToken,
        address _catalystToken,
        address _artifactNFT,
        uint256 _initialEssenceYieldRate,
        uint256 _initialCatalystBoostFactor,
        uint256 _recipeProposalVoteThreshold,
        uint256 _recipeProposalQuorum
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(RECIPE_MANAGER_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender); // Governor role for executing proposals

        setTokenAddresses(_essenceToken, _catalystToken, _artifactNFT);

        essenceYieldRate = _initialEssenceYieldRate; // Rate per second per staked token
        catalystBoostFactor = _initialCatalystBoostFactor; // Percentage (e.g., 100 = 1x, 110 = 1.1x)
        recipeProposalVoteThreshold = _recipeProposalVoteThreshold;
        recipeProposalQuorum = _recipeProposalQuorum;
    }

    // --- Access Control Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Pausable Logic ---
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // --- Token Address Management (Admin Only) ---
    /// @notice Sets the addresses for the associated tokens.
    /// @param _essenceToken The address of the Essence ERC20 token.
    /// @param _catalystToken The address of the Catalyst ERC20 token.
    /// @param _artifactNFT The address of the Artifact ERC721 token.
    function setTokenAddresses(address _essenceToken, address _catalystToken, address _artifactNFT) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_essenceToken != address(0), "Essence address cannot be zero");
        require(_catalystToken != address(0), "Catalyst address cannot be zero");
        require(_artifactNFT != address(0), "Artifact address cannot be zero");
        essenceToken = IEssence(_essenceToken);
        catalystToken = ICatalyst(_catalystToken);
        artifactNFT = IArtifact(_artifactNFT);
        emit TokenAddressesUpdated(_essenceToken, _catalystToken, _artifactNFT);
    }

    /// @notice Get the addresses of the associated tokens.
    /// @return essence The address of the Essence token.
    /// @return catalyst The address of the Catalyst token.
    /// @return artifact The address of the Artifact token.
    function getTokenAddresses() public view returns (address essence, address catalyst, address artifact) {
        return (address(essenceToken), address(catalystToken), address(artifactNFT));
    }

    // --- Recipe Management (RecipeManager Role) ---
    /// @notice Adds a new synthesis recipe.
    /// @param essenceAmount Required amount of Essence.
    /// @param catalystAmount Required amount of Catalyst.
    /// @param cooldownDuration Duration of the synthesis cooldown for this recipe (in seconds).
    function addRecipe(uint256 essenceAmount, uint256 catalystAmount, uint64 cooldownDuration) public onlyRole(RECIPE_MANAGER_ROLE) {
        recipeCounter.increment();
        uint256 newRecipeId = recipeCounter.current();
        recipes[newRecipeId] = Recipe(essenceAmount, catalystAmount, cooldownDuration, true);
        emit RecipeAdded(newRecipeId, essenceAmount, catalystAmount, cooldownDuration);
    }

    /// @notice Updates an existing synthesis recipe.
    /// @param recipeId The ID of the recipe to update.
    /// @param essenceAmount New required amount of Essence.
    /// @param catalystAmount New required amount of Catalyst.
    /// @param cooldownDuration New duration of the synthesis cooldown.
    /// @param isActive Whether the recipe should be active.
    function updateRecipe(uint256 recipeId, uint256 essenceAmount, uint256 catalystAmount, uint64 cooldownDuration, bool isActive) public onlyRole(RECIPE_MANAGER_ROLE) {
        require(recipes[recipeId].isActive, "Recipe does not exist or is removed"); // Check if recipe exists
        recipes[recipeId] = Recipe(essenceAmount, catalystAmount, cooldownDuration, isActive);
        emit RecipeUpdated(recipeId, essenceAmount, catalystAmount, cooldownDuration);
    }

    /// @notice Removes (deactivates) a synthesis recipe.
    /// @param recipeId The ID of the recipe to remove.
    function removeRecipe(uint256 recipeId) public onlyRole(RECIPE_MANAGER_ROLE) {
        require(recipes[recipeId].isActive, "Recipe does not exist or is already removed");
        recipes[recipeId].isActive = false; // Mark as inactive instead of deleting
        emit RecipeRemoved(recipeId);
    }

    /// @notice Gets the details of a synthesis recipe.
    /// @param recipeId The ID of the recipe.
    /// @return essenceAmount Required amount of Essence.
    /// @return catalystAmount Required amount of Catalyst.
    /// @return cooldownDuration Duration of the synthesis cooldown (in seconds).
    /// @return isActive Whether the recipe is active.
    function getRecipe(uint256 recipeId) public view returns (uint256 essenceAmount, uint256 catalystAmount, uint64 cooldownDuration, bool isActive) {
        Recipe storage recipe = recipes[recipeId];
        require(recipe.isActive, "Recipe does not exist or is inactive");
        return (recipe.essenceAmount, recipe.catalystAmount, recipe.cooldownDuration, recipe.isActive);
    }

    /// @notice Gets the total count of recipes ever created.
    /// @return The total number of recipes.
    function getRecipeCount() public view returns (uint256) {
        return recipeCounter.current();
    }

    /// @notice Get a list of active recipe IDs.
    /// @dev This could be gas-intensive if there are many recipes. Consider off-chain indexing for large numbers.
    /// @return An array of active recipe IDs.
    function getSynthesizableRecipes() public view returns (uint255[] memory) {
        uint256[] memory activeRecipeIds = new uint255[](recipeCounter.current());
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= recipeCounter.current(); i++) {
            if (recipes[i].isActive) {
                activeRecipeIds[activeCount] = i;
                activeCount++;
            }
        }
        uint255[] memory result = new uint255[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            result[i] = activeRecipeIds[i];
        }
        return result;
    }


    // --- Synthesis Logic ---
    /// @notice Synthesizes a new Artifact based on a recipe.
    /// Requires user to have approved this contract to spend required Essence and Catalyst.
    /// @param recipeId The ID of the recipe to use.
    function synthesizeArtifact(uint256 recipeId) public payable nonReentrant whenNotPaused {
        Recipe storage recipe = recipes[recipeId];
        require(recipe.isActive, "Recipe is not active");

        // Check Cooldown
        uint64 cooldownExpiration = userSynthesisCooldowns[msg.sender][recipeId];
        require(block.timestamp >= cooldownExpiration, "Recipe is on cooldown");

        // Apply Catalyst Boost to Cooldown
        uint256 boostPercentage = getCatalystStakeBoost(msg.sender); // 100 is 0% boost, 110 is 10% boost
        uint64 effectiveCooldown = recipe.cooldownDuration;
        if (boostPercentage > 100) {
             effectiveCooldown = uint64(recipe.cooldownDuration * 100 / boostPercentage); // Reduced cooldown
             if (effectiveCooldown > recipe.cooldownDuration) effectiveCooldown = recipe.cooldownDuration; // Prevent overflow wrap-around
             if (effectiveCooldown < recipe.cooldownDuration && block.timestamp + effectiveCooldown < block.timestamp) effectiveCooldown = 0; // Handle potential tiny effectiveCooldown rounding to 0
        }

        // Burn Ingredients (using SafeERC20 for checks)
        if (recipe.essenceAmount > 0) {
            essenceToken.safeTransferFrom(msg.sender, address(this), recipe.essenceAmount);
        }
        if (recipe.catalystAmount > 0) {
            catalystToken.safeTransferFrom(msg.sender, address(this), recipe.catalystAmount);
        }

        // Determine next Artifact ID (Assuming Artifact contract uses its own counter)
        // A more robust system might coordinate IDs or pass a desired ID.
        // For simplicity, let's assume artifactNFT.mint handles ID generation internally or we pass 0
        // and it assigns the next available ID. Or, even better, track it *here* if Artifact contract allows external minting with ID.
        // Let's assume the Artifact contract has an internal counter and this contract just calls mint(to, 0).
        // If the Artifact contract mints sequentially, we need a way to know the *new* ID after minting.
        // A common pattern is for the ERC721 mint function to emit Transfer event, which includes the tokenId.
        // For this example, let's simulate obtaining the new ID. A real system might use artifactNFT.totalSupply() *before* and *after* minting if the NFT contract tracks it, or rely on the emitted event.
        // Let's assume the Artifact contract has a `getNextTokenId()` view function for simplicity in this example's logic flow.

        uint256 newArtifactId = artifactNFT.getNextTokenId(); // Hypothetical view function
        artifactNFT.mint(msg.sender, newArtifactId); // Assuming mint(address to, uint256 tokenId) exists and we have the role

        // Store Artifact Properties (simplified initial properties)
        artifactData[newArtifactId] = ArtifactProperties({
            power: recipe.essenceAmount / 100 + recipe.catalystAmount / 10, // Simple power calculation
            creationTime: block.timestamp,
            upgradeCount: 0
        });

        // Set Cooldown for the user/recipe
        userSynthesisCooldowns[msg.sender][recipeId] = uint64(block.timestamp + effectiveCooldown);

        emit ArtifactSynthesized(msg.sender, recipeId, newArtifactId);
    }

    /// @notice Gets the timestamp when the synthesis cooldown for a user and recipe expires.
    /// @param user The address of the user.
    /// @param recipeId The ID of the recipe.
    /// @return The expiration timestamp. 0 if no active cooldown.
    function getUserCooldown(address user, uint256 recipeId) public view returns (uint64) {
        return userSynthesisCooldowns[user][recipeId];
    }

    /// @notice Hypothetical view function to get the next artifact ID that would be minted.
    /// @dev Requires the Artifact NFT contract to expose such a function.
    /// @return The next artifact ID.
    function getLatestArtifactId() public view returns (uint256) {
        // In a real scenario, you'd query the actual NFT contract's state or rely on events.
        // This is a placeholder assuming IArtifact has a `nextTokenId` or similar public state/view.
        // Example: return artifactNFT.nextTokenId(); // Assuming IArtifact has this state
        // Or if minting is sequential: return artifactNFT.totalSupply(); // Assuming IArtifact is ERC721Enumerable
        // For this example, let's just return 0, signifying this contract doesn't track it globally this way.
        // A more robust solution would be to have the Artifact contract emit the ID and handle mapping properties *after* minting.
        // Or, this contract could be the NFT contract itself, simplifying ID management and property storage.
         return artifactNFT.totalSupply(); // Assuming standard sequential minting starts from 0 or 1
    }


    // --- Staking Logic (Essence for Yield) ---

    /// @notice Allows a user to stake Essence tokens.
    /// Requires user to have approved this contract to spend the amount.
    /// @param amount The amount of Essence to stake.
    function stakeEssence(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        updateEssenceYield(msg.sender); // Settle pending yield before changing stake

        essenceToken.safeTransferFrom(msg.sender, address(this), amount);
        stakedEssence[msg.sender].amount += amount;
        totalStakedEssence += amount;
        stakedEssence[msg.sender].lastYieldClaimTime = uint64(block.timestamp); // Reset yield accumulation timer for new stake balance

        emit EssenceStaked(msg.sender, amount);
    }

    /// @notice Allows a user to unstake Essence tokens.
    /// @param amount The amount of Essence to unstake.
    function unstakeEssence(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        StakedEssence storage stake = stakedEssence[msg.sender];
        require(stake.amount >= amount, "Insufficient staked amount");

        updateEssenceYield(msg.sender); // Settle pending yield before changing stake

        stake.amount -= amount;
        totalStakedEssence -= amount;
        stakedEssence[msg.sender].lastYieldClaimTime = uint64(block.timestamp); // Reset timer

        essenceToken.safeTransfer(msg.sender, amount); // Return unstaked amount

        emit EssenceUnstaked(msg.sender, amount);
    }

    /// @notice Claims accumulated Essence yield for the user.
    function claimEssenceYield() public nonReentrant whenNotPaused {
        updateEssenceYield(msg.sender); // Calculate and add to accumulated

        uint256 yieldAmount = stakedEssence[msg.sender].accumulatedYield;
        require(yieldAmount > 0, "No yield to claim");

        stakedEssence[msg.sender].accumulatedYield = 0; // Reset claimable yield
        stakedEssence[msg.sender].lastYieldClaimTime = uint64(block.timestamp); // Reset timer after claim

        essenceToken.safeTransfer(msg.sender, yieldAmount); // Send claimed yield

        emit EssenceYieldClaimed(msg.sender, yieldAmount);
    }

    /// @notice Internal function to update and store the accrued yield for a user.
    /// This should be called before any action that changes the stake amount or claims yield.
    /// @param user The address of the user.
    function updateEssenceYield(address user) internal {
        StakedEssence storage stake = stakedEssence[user];
        if (stake.amount == 0 || essenceYieldRate == 0) {
            stake.lastYieldClaimTime = uint64(block.timestamp);
            return;
        }

        uint64 timeElapsed = uint64(block.timestamp) - stake.lastYieldClaimTime;
        if (timeElapsed == 0) {
            return; // No time elapsed since last update
        }

        // Simple yield calculation: amount * rate * time. Potential for overflow if rate/amount/time are large.
        // A real system might use fixed-point math or a more complex model.
        uint256 yieldAccrued = (stake.amount * essenceYieldRate * timeElapsed) / 1e18; // Assume rate is fixed point Q18.18

        stake.accumulatedYield += yieldAccrued;
        stake.lastYieldClaimTime = uint64(block.timestamp);
    }

    /// @notice Gets the current staked Essence amount for a user.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getStakedEssence(address user) public view returns (uint256) {
        return stakedEssence[user].amount;
    }

     /// @notice Gets the current pending Essence yield for a user (estimate).
     /// @dev This is an estimate. The actual yield calculated during claim might differ slightly due to time elapsed between view call and transaction execution.
     /// @param user The address of the user.
     /// @return The pending yield amount.
    function getPendingEssenceYield(address user) public view returns (uint256) {
        StakedEssence storage stake = stakedEssence[user];
        if (stake.amount == 0 || essenceYieldRate == 0) {
            return stake.accumulatedYield; // Only return already accumulated if no active stake/rate
        }

        uint64 timeElapsed = uint64(block.timestamp) - stake.lastYieldClaimTime;
        uint256 yieldAccrued = (stake.amount * essenceYieldRate * timeElapsed) / 1e18;
        return stake.accumulatedYield + yieldAccrued;
    }

    // --- Staking Logic (Catalyst for Boost) ---

    /// @notice Allows a user to stake Catalyst tokens for synthesis boosts.
    /// Requires user to have approved this contract to spend the amount.
    /// @param amount The amount of Catalyst to stake.
    function stakeCatalyst(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        catalystToken.safeTransferFrom(msg.sender, address(this), amount);
        stakedCatalyst[msg.sender].amount += amount;
        totalStakedCatalyst += amount;
        emit CatalystStaked(msg.sender, amount);
    }

    /// @notice Allows a user to unstake Catalyst tokens.
    /// @param amount The amount of Catalyst to unstake.
    function unstakeCatalyst(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        StakedCatalyst storage stake = stakedCatalyst[msg.sender];
        require(stake.amount >= amount, "Insufficient staked amount");

        stake.amount -= amount;
        totalStakedCatalyst -= amount;

        catalystToken.safeTransfer(msg.sender, amount);

        emit CatalystUnstaked(msg.sender, amount);
    }

    /// @notice Gets the current synthesis boost factor for a user based on their staked Catalyst.
    /// @dev Boost calculation is simplified: base factor + (staked amount * per_catalyst_boost).
    /// @return The boost factor (e.g., 100 for no boost, 110 for 10% boost).
    function getCatalystStakeBoost(address user) public view returns (uint256) {
        uint256 staked = stakedCatalyst[user].amount;
        // Example boost logic: 100% base + (staked amount / 100) % bonus, capped.
        // Using catalystBoostFactor as a multiplier: 100 + (staked * catalystBoostFactor / 1e18) ?
        // Let's keep it simpler for the example: 100 + (staked / 1000) e.g., 1000 staked gives 1% boost.
        // Cap boost at a reasonable level.
        uint256 baseBoost = 100; // 100%
        uint256 maxBonus = 50; // Max 50% bonus
        uint256 bonus = (staked * catalystBoostFactor) / 1e18; // Assume catalystBoostFactor is Q18.18
        if (bonus > maxBonus) bonus = maxBonus;

        return baseBoost + bonus;
    }

    // --- Artifact Alchemy (Interaction with existing Artifacts) ---

    /// @notice Allows a user to transmute (burn) an Artifact to recover some Essence.
    /// Requires user to own the Artifact and have approved this contract to burn it.
    /// @param tokenId The ID of the Artifact to transmute.
    function transmuteArtifact(uint256 tokenId) public nonReentrant whenNotPaused {
        // Check ownership and approval
        require(artifactNFT.ownerOf(tokenId) == msg.sender, "Not artifact owner");
        require(artifactNFT.isApprovedForAll(msg.sender, address(this)) || artifactNFT.getApproved(tokenId) == address(this), "Artifact not approved for transmutation");

        ArtifactProperties storage props = artifactData[tokenId];
        require(props.creationTime > 0, "Artifact data not found"); // Check if artifact exists and has properties

        // Determine Essence return amount (e.g., percentage of original Essence cost)
        // Need to know original recipe essence cost. This requires storing recipe ID with artifact properties.
        // Let's add recipeId to ArtifactProperties struct.
        // struct ArtifactProperties { ... uint256 recipeId; }
        // This means the synthesis function needs to store the recipeId.
        // Let's assume this update is done.
        // uint256 originalEssenceCost = recipes[props.recipeId].essenceAmount;
        // uint256 returnedEssence = (originalEssenceCost * 50) / 100; // 50% return

        // For simplicity without storing original recipe ID, let's make return proportional to current power.
        uint256 returnedEssence = props.power * 10; // Example: 10 Essence per power point

        // Burn the Artifact
        artifactNFT.burn(tokenId); // Assumes IArtifact has a burn function and this contract is approved/has burn role.

        // Remove artifact properties
        delete artifactData[tokenId]; // Clean up storage

        // Transfer Essence back
        if (returnedEssence > 0) {
            essenceToken.safeTransfer(msg.sender, returnedEssence);
        }

        emit ArtifactTransmuted(msg.sender, tokenId, returnedEssence);
    }

    /// @notice Allows a user to upgrade an Artifact's properties using ingredients.
    /// Requires user to own the Artifact and have approved this contract.
    /// @param tokenId The ID of the Artifact to upgrade.
    /// @param essenceAmount The amount of Essence to use for the upgrade.
    /// @param catalystAmount The amount of Catalyst to use for the upgrade.
    function upgradeArtifact(uint256 tokenId, uint256 essenceAmount, uint256 catalystAmount) public nonReentrant whenNotPaused {
         require(artifactNFT.ownerOf(tokenId) == msg.sender, "Not artifact owner");
        require(artifactNFT.isApprovedForAll(msg.sender, address(this)) || artifactNFT.getApproved(tokenId) == address(this), "Artifact not approved for upgrade");

        ArtifactProperties storage props = artifactData[tokenId];
        require(props.creationTime > 0, "Artifact data not found");

        require(essenceAmount > 0 || catalystAmount > 0, "Must use some ingredients to upgrade");

        // Burn Ingredients
        if (essenceAmount > 0) {
            essenceToken.safeTransferFrom(msg.sender, address(this), essenceAmount);
        }
        if (catalystAmount > 0) {
            catalystToken.safeTransferFrom(msg.sender, address(this), catalystAmount);
        }

        // Apply upgrade logic (simplified)
        // This could involve pseudo-randomness based on block hash, ingredient amounts, catalyst boost, etc.
        // Secure randomness requires Chainlink VRF or similar. For this example, keep it simple.
        uint256 powerIncrease = (essenceAmount / 50 + catalystAmount / 5); // Example calculation
        props.power += powerIncrease;
        props.upgradeCount++;

        // Could potentially change other properties or add new ones
        // uint8 newElement = uint8((block.timestamp + block.number + tokenId + props.upgradeCount) % 4); // Pseudo-random element change?
        // props.element = newElement;

        // Update metadata URI if the Artifact contract supports it (optional, depends on NFT contract design)
        // string memory newURI = string(abi.encodePacked("https://mydapp.com/artifact/", Strings.toString(tokenId), "/metadata?v=", Strings.toString(props.upgradeCount)));
        // artifactNFT.setTokenURI(tokenId, newURI); // Hypothetical function on Artifact contract

        // A simple way to signal metadata update is just emitting an event
        emit ArtifactUpgraded(msg.sender, tokenId, props.power, ""); // Pass empty string if URI not updated on NFT

        // Note: The metadata service reading the artifactData mapping would automatically reflect the changes.
    }

     /// @notice Gets the dynamic properties of an Artifact.
     /// @param tokenId The ID of the Artifact.
     /// @return power The power level.
     /// @return creationTime The timestamp of synthesis.
     /// @return upgradeCount The number of upgrades.
    function getArtifactProperties(uint256 tokenId) public view returns (uint256 power, uint256 creationTime, uint256 upgradeCount) {
        ArtifactProperties storage props = artifactData[tokenId];
        require(props.creationTime > 0, "Artifact data not found");
        return (props.power, props.creationTime, props.upgradeCount);
    }

    // --- Governance (Recipe Proposal System) ---

    /// @notice Allows any user to propose a new recipe. Costs some Catalyst to prevent spam.
    /// @param essenceAmount The required amount of Essence for the proposed recipe.
    /// @param catalystAmount The required amount of Catalyst for the proposed recipe.
    /// @param cooldownDuration The cooldown duration for the proposed recipe.
    /// @param proposalCost The amount of Catalyst required to submit a proposal.
    function proposeRecipe(uint256 essenceAmount, uint256 catalystAmount, uint64 cooldownDuration, uint256 proposalCost) public nonReentrant whenNotPaused {
        require(proposalCost > 0, "Proposal cost must be greater than 0");
        catalystToken.safeTransferFrom(msg.sender, address(this), proposalCost); // Burn proposal cost

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();

        recipeProposals[proposalId] = RecipeProposal({
            proposer: msg.sender,
            essenceAmount: essenceAmount,
            catalystAmount: catalystAmount,
            cooldownDuration: cooldownDuration,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: uint64(block.timestamp),
            isApproved: false,
            isExecuted: false
        });

        emit RecipeProposalCreated(proposalId, msg.sender, essenceAmount, catalystAmount);
    }

    /// @notice Allows users with staked tokens to vote on a recipe proposal.
    /// Voting weight could be based on staked Essence/Catalyst amounts.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param approve True for yes, False for no.
    function voteOnRecipeProposal(uint256 proposalId, bool approve) public nonReentrant whenNotPaused {
        RecipeProposal storage proposal = recipeProposals[proposalId];
        require(proposal.creationTime > 0 && !proposal.isExecuted, "Proposal does not exist or is already finalized");
        require(!proposalVotes[proposalId][msg.sender], "Already voted on this proposal");

        // Simple vote weight: 1 vote per user, or could use staked balance:
        // uint256 voteWeight = stakedEssence[msg.sender].amount + stakedCatalyst[msg.sender].amount;
        // require(voteWeight > 0, "Must have staked tokens to vote");
        // For simplicity, let's do 1 user = 1 vote.

        proposalVotes[proposalId][msg.sender] = true;

        if (approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Check if threshold/quorum met immediately after voting (simple model)
        if (proposal.votesFor >= recipeProposalVoteThreshold && (proposal.votesFor + proposal.votesAgainst) >= recipeProposalQuorum) {
            proposal.isApproved = true;
            // Could automatically execute here, or require separate execution function (safer)
        }

        emit RecipeProposalVoted(proposalId, msg.sender, approve);
    }

    /// @notice Allows a GOVERNOR_ROLE to execute an approved recipe proposal.
    /// @param proposalId The ID of the proposal to execute.
    function executeRecipeProposal(uint256 proposalId) public onlyRole(GOVERNOR_ROLE) nonReentrant whenNotPaused {
        RecipeProposal storage proposal = recipeProposals[proposalId];
        require(proposal.creationTime > 0 && !proposal.isExecuted, "Proposal does not exist or is already executed");
        require(proposal.isApproved, "Proposal has not met approval threshold or quorum");

        // Add the recipe
        recipeCounter.increment();
        uint256 newRecipeId = recipeCounter.current();
        recipes[newRecipeId] = Recipe(proposal.essenceAmount, proposal.catalystAmount, proposal.cooldownDuration, true);

        proposal.isExecuted = true; // Mark proposal as executed

        emit RecipeAdded(newRecipeId, proposal.essenceAmount, proposal.catalystAmount, proposal.cooldownDuration); // Emit recipe added event
        emit RecipeProposalExecuted(proposalId, newRecipeId);
    }

    /// @notice Gets the details of a recipe proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposer The address of the proposer.
    /// @return essenceAmount Required Essence amount.
    /// @return catalystAmount Required Catalyst amount.
    /// @return cooldownDuration Cooldown duration.
    /// @return votesFor Number of 'yes' votes.
    /// @return votesAgainst Number of 'no' votes.
    /// @return creationTime Timestamp of creation.
    /// @return isApproved Whether the proposal is approved.
    /// @return isExecuted Whether the proposal is executed.
    function getRecipeProposal(uint256 proposalId) public view returns (address proposer, uint256 essenceAmount, uint256 catalystAmount, uint64 cooldownDuration, uint256 votesFor, uint256 votesAgainst, uint64 creationTime, bool isApproved, bool isExecuted) {
        RecipeProposal storage proposal = recipeProposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist");
        return (proposal.proposer, proposal.essenceAmount, proposal.catalystAmount, proposal.cooldownDuration, proposal.votesFor, proposal.votesAgainst, proposal.creationTime, proposal.isApproved, proposal.isExecuted);
    }

     /// @notice Gets the total count of recipe proposals ever created.
     /// @return The total number of proposals.
    function getRecipeProposalCount() public view returns (uint256) {
        return proposalCounter.current();
    }


     /// @notice Checks if a user has voted on a specific proposal.
     /// @param proposalId The ID of the proposal.
     /// @param user The address of the user.
     /// @return True if the user has voted, False otherwise.
    function getRecipeProposalVoteStatus(uint256 proposalId, address user) public view returns (bool) {
        return proposalVotes[proposalId][user];
    }


    // --- Utility Function ---
    /// @notice Allows the admin to withdraw stuck tokens or collected fees.
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawToken(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(tokenAddress != address(essenceToken) && tokenAddress != address(catalystToken) && tokenAddress != address(artifactNFT), "Cannot withdraw primary contract tokens this way");
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
```