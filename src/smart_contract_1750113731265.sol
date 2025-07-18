Okay, let's create a smart contract that blends concepts from DeFi, NFTs, Gamification, and on-chain mechanics. We'll build a system where users can stake a token to generate a yield-bearing, dynamic NFT ("Forge") which produces a resource token based on its level, global conditions, and user progression. Users can then use the resource token to upgrade the Forge NFT, craft utility NFTs ("Artifacts") that boost production, and gain mastery points. We'll incorporate a global state variable influenced by an owner (simulating oracle/governance interaction) and add a basic on-chain randomness element for crafting.

This combines:
*   **Staking/Yield:** Deposit token to earn resource token.
*   **Dynamic NFTs:** Forge NFT properties (level, generation rate) change.
*   **Resource Management:** Claiming and spending a resource token.
*   **Gamification:** Mastery points and potential ranks.
*   **Utility NFTs:** Artifacts granting buffs.
*   **Global State Influence:** Catalyst affecting all users.
*   **On-Chain Mechanics:** Time-based generation, potential entropy in crafting.

We'll aim for 20+ functions covering setup, user interaction, querying, progression, and global state management.

---

**Contract Name:** AetheriumForge

**Concept:** A system where users stake $ESSENCE tokens to obtain a dynamic $FORGE NFT. The Forge generates $AETHER tokens over time, influenced by its level, user mastery, and a global $CATALYST state. $AETHER can be used to upgrade the Forge or craft $ARTIFACT utility NFTs that provide boosts.

**Advanced/Creative Concepts:**
1.  **Dynamic NFT Yield:** NFT properties directly influence resource generation yield.
2.  **Multi-Factor Generation:** Yield calculation based on time, NFT level, user status, and global state.
3.  **Utility NFTs:** Artifacts provide temporary or permanent buffs to the core yield NFT.
4.  **Gamified Progression:** Mastery points tracking user engagement and potentially granting bonuses.
5.  **Global State Influence:** A parameter ($CATALYST) managed by an external source (owner/governance) affects all users' yield.
6.  **On-Chain Crafting with Entropy:** Crafting utility NFTs uses block data for pseudo-randomness.
7.  **Interdependent Assets:** Tokens ($ESSENCE, $AETHER) and NFTs ($FORGE, $ARTIFACT) interact and depend on each other.

**Function Summary:**

*   **Initialization & Setup:**
    *   `constructor`: Sets initial addresses for tokens/NFTs and contract owner.
    *   `setEssenceToken`: Owner sets the $ESSENCE token address.
    *   `setAetherToken`: Owner sets the $AETHER token address.
    *   `setForgeNFTContract`: Owner sets the $FORGE NFT contract address.
    *   `setArtifactNFTContract`: Owner sets the $ARTIFACT NFT contract address.
    *   `setBaseForgeGenerationRate`: Owner sets the base $AETHER per second generated by a Level 1 Forge.
    *   `setRefineCostAether`: Owner sets the $AETHER cost to refine a Forge.
    *   `setRefineLevelIncrease`: Owner sets how much the level increases per refinement.
    *   `setArtifactCraftCostAether`: Owner sets the $AETHER cost to craft an Artifact.
    *   `setMasteryPointsPerAction`: Owner sets mastery points gained for actions (e.g., claim, refine).
    *   `setForgeMintCostEssence`: Owner sets $ESSENCE required to mint a Forge.
    *   `withdrawProtocolFees`: Owner can withdraw collected fees (if any implemented, e.g., % of claims).

*   **User Interaction (Essence Stake & Forge Management):**
    *   `depositEssence`: User stakes $ESSENCE.
    *   `withdrawEssence`: User unstakes $ESSENCE.
    *   `mintForge`: User who has deposited Essence can mint their unique $FORGE NFT.
    *   `claimAether`: User claims accumulated $AETHER from their Forge. Calculates yield based on time, level, mastery, catalyst, artifacts.
    *   `refineForge`: User spends $AETHER to increase their Forge's level.

*   **User Interaction (Artifacts):**
    *   `craftArtifact`: User spends $AETHER to craft a random $ARTIFACT NFT using on-chain entropy.
    *   `useArtifactOnForge`: User applies an $ARTIFACT NFT to a specific Forge NFT, granting a temporary boost.

*   **Global State Management:**
    *   `updateCatalystState`: Owner updates the global $CATALYST value, affecting all Forges' generation rate.

*   **Query Functions (View/Pure):**
    *   `getUserEssenceDeposit`: Get a user's staked $ESSENCE balance.
    *   `getUserForgeId`: Get the $FORGE NFT ID owned by a user.
    *   `getForgeProperties`: Get the level and active boost of a specific Forge NFT.
    *   `calculatePendingAether`: Calculate the amount of $AETHER a user can currently claim.
    *   `getUserMastery`: Get a user's current Mastery points.
    *   `calculateUserRank`: Determine a user's rank based on Mastery points (simple mapping).
    *   `getArtifactProperties`: Get the type and strength of a specific $ARTIFACT NFT (requires interaction with Artifact contract).
    *   `getCurrentCatalyst`: Get the current global $CATALYST value.
    *   `getForgeLastClaimTime`: Get the last time a specific Forge's $AETHER was claimed.

*   **ERC721 Required Functions (assuming external NFT contracts):**
    *   `onERC721Received`: Required for contract to receive NFT transfers (e.g., when user deposits an Artifact to `useArtifactOnForge`).

*(Note: We will define the core logic in this contract, but assume `Essence`, `Aether`, `Forge`, and `Artifact` are separate ERC20 and ERC721 compliant contracts whose addresses are set during setup. We won't include the full code for those standard contracts to focus on the AetheriumForge logic, but we'll include necessary interfaces.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Contract Name: AetheriumForge ---
// Concept: A system where users stake $ESSENCE tokens to obtain a dynamic $FORGE NFT.
// The Forge generates $AETHER tokens over time, influenced by its level, user mastery,
// and a global $CATALYST state. $AETHER can be used to upgrade the Forge or craft
// $ARTIFACT utility NFTs that provide boosts.
// Advanced/Creative Concepts: Dynamic NFT Yield, Multi-Factor Generation,
// Utility NFTs, Gamified Progression, Global State Influence, On-Chain Crafting with Entropy,
// Interdependent Assets.

// --- Function Summary ---

// Initialization & Setup:
// constructor: Sets initial addresses for tokens/NFTs and contract owner.
// setEssenceToken: Owner sets the $ESSENCE token address.
// setAetherToken: Owner sets the $AETHER token address.
// setForgeNFTContract: Owner sets the $FORGE NFT contract address.
// setArtifactNFTContract: Owner sets the $ARTIFACT NFT contract address.
// setBaseForgeGenerationRate: Owner sets the base $AETHER per second generated by a Level 1 Forge.
// setRefineCostAether: Owner sets the $AETHER cost to refine a Forge.
// setRefineLevelIncrease: Owner sets how much the level increases per refinement.
// setArtifactCraftCostAether: Owner sets the $AETHER cost to craft an Artifact.
// setMasteryPointsPerAction: Owner sets mastery points gained for actions.
// setForgeMintCostEssence: Owner sets $ESSENCE required to mint a Forge.
// withdrawProtocolFees: Owner can withdraw collected fees.

// User Interaction (Essence Stake & Forge Management):
// depositEssence: User stakes $ESSENCE.
// withdrawEssence: User unstakes $ESSENCE.
// mintForge: User who has deposited Essence can mint their unique $FORGE NFT.
// claimAether: User claims accumulated $AETHER from their Forge.
// refineForge: User spends $AETHER to increase their Forge's level.

// User Interaction (Artifacts):
// craftArtifact: User spends $AETHER to craft a random $ARTIFACT NFT.
// useArtifactOnForge: User applies an $ARTIFACT NFT to a specific Forge NFT.

// Global State Management:
// updateCatalystState: Owner updates the global $CATALYST value.

// Query Functions (View/Pure):
// getUserEssenceDeposit: Get a user's staked $ESSENCE balance.
// getUserForgeId: Get the $FORGE NFT ID owned by a user.
// getForgeProperties: Get the level and active boost of a specific Forge NFT.
// calculatePendingAether: Calculate the amount of $AETHER a user can currently claim.
// getUserMastery: Get a user's current Mastery points.
// calculateUserRank: Determine a user's rank based on Mastery points.
// getArtifactProperties: Get the type and strength of a specific $ARTIFACT NFT.
// getCurrentCatalyst: Get the current global $CATALYST value.
// getForgeLastClaimTime: Get the last time a specific Forge's $AETHER was claimed.

// ERC721 Required Functions:
// onERC721Received: Required for contract to receive NFT transfers (e.g., user depositing Artifact).


// --- Interfaces (Minimal definitions for interaction) ---

interface IForgeNFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
    function setForgeProperties(uint256 tokenId, uint256 level, uint256 boostRateMultiplier, uint40 boostEndTime) external;
    function getForgeProperties(uint256 tokenId) external view returns (uint256 level, uint256 boostRateMultiplier, uint40 boostEndTime);
    function exists(uint256 tokenId) external view returns (bool);
}

interface IArtifactNFT is IERC721 {
    function mint(address to, uint256 tokenId, uint8 artifactType, uint256 strength) external;
    function getArtifactProperties(uint256 tokenId) external view returns (uint8 artifactType, uint256 strength);
}

// --- Main Contract ---

contract AetheriumForge is Context, Ownable, IERC721Receiver {

    // --- State Variables ---

    IERC20 public essenceToken;
    IERC20 public aetherToken;
    IForgeNFT public forgeNFT;
    IArtifactNFT public artifactNFT;

    // Mapping from user address to staked Essence balance
    mapping(address => uint256) public userEssenceDeposits;

    // Mapping from user address to their unique Forge NFT ID (assuming 1 per user)
    mapping(address => uint256) public userForgeId;

    // Mapping from Forge NFT ID to the timestamp of the last Aether claim
    mapping(uint256 => uint40) public forgeLastClaimTime; // Using uint40 for timestamps < 2^40 (way in the future)

    // Global state variable affecting generation rate (e.g., based on oracle, governance, etc.)
    uint256 public currentCatalyst; // Percentage multiplier, e.g., 10000 = 100%

    // Mapping from user address to their Mastery points
    mapping(address => uint256) public userMastery;

    // --- Configuration Parameters ---

    uint256 public baseAetherPerSecondPerLevel; // Aether per second for a Level 1 Forge
    uint256 public refineCostAether; // Aether cost to increase Forge level
    uint256 public refineLevelIncrease; // How many levels gained per refinement
    uint256 public artifactCraftCostAether; // Aether cost to craft an Artifact
    uint256 public masteryPointsPerAction; // Mastery points awarded for certain actions (e.g., claim, refine, craft)
    uint256 public forgeMintCostEssence; // Essence required to mint a Forge

    // Artifact types (simple example)
    uint8 public constant ARTIFACT_TYPE_RATE_BOOST = 1; // Increases Aether generation rate
    uint8 public constant ARTIFACT_TYPE_DURATION_BOOST = 2; // Increases boost duration
    // Add more artifact types as needed

    // --- Events ---

    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawal(address indexed user, uint256 amount);
    event ForgeMinted(address indexed user, uint256 indexed tokenId);
    event AetherClaimed(address indexed user, uint256 indexed forgeId, uint256 amount);
    event ForgeRefined(address indexed user, uint256 indexed forgeId, uint256 newLevel);
    event ArtifactCrafted(address indexed user, uint256 indexed artifactId, uint8 artifactType, uint256 strength);
    event ArtifactUsed(address indexed user, uint256 indexed forgeId, uint256 indexed artifactId);
    event CatalystUpdated(uint256 oldCatalyst, uint256 newCatalyst);
    event MasteryGained(address indexed user, uint256 points);

    // --- Modifiers ---

    modifier requiresEssenceDeposit(uint256 requiredAmount) {
        require(userEssenceDeposits[_msgSender()] >= requiredAmount, "Insufficient staked Essence");
        _;
    }

    modifier requiresForgeExists(address user) {
        require(userForgeId[user] != 0, "User does not own a Forge");
        require(forgeNFT.exists(userForgeId[user]), "User's Forge NFT does not exist (burned?)");
        _;
    }

    modifier requiresAether(uint256 requiredAmount) {
        require(aetherToken.balanceOf(_msgSender()) >= requiredAmount, "Insufficient Aether balance");
        _;
    }

    // --- Constructor ---

    constructor(
        address _essenceToken,
        address _aetherToken,
        address _forgeNFT,
        address _artifactNFT,
        uint256 _initialCatalyst, // e.g., 10000 for 100%
        uint256 _baseAetherPerSecondPerLevel,
        uint256 _refineCostAether,
        uint256 _refineLevelIncrease,
        uint256 _artifactCraftCostAether,
        uint256 _masteryPointsPerAction,
        uint256 _forgeMintCostEssence
    ) Ownable(_msgSender()) {
        essenceToken = IERC20(_essenceToken);
        aetherToken = IERC20(_aetherToken);
        forgeNFT = IForgeNFT(_forgeNFT);
        artifactNFT = IArtifactNFT(_artifactNFT);

        currentCatalyst = _initialCatalyst;
        baseAetherPerSecondPerLevel = _baseAetherPerSecondPerLevel;
        refineCostAether = _refineCostAether;
        refineLevelIncrease = _refineLevelIncrease;
        artifactCraftCostAether = _artifactCraftCostAether;
        masteryPointsPerAction = _masteryPointsPerAction;
        forgeMintCostEssence = _forgeMintCostEssence;
    }

    // --- Initialization & Setup Functions (Owner Only) ---

    function setEssenceToken(address _token) external onlyOwner {
        essenceToken = IERC20(_token);
    }

    function setAetherToken(address _token) external onlyOwner {
        aetherToken = IERC20(_token);
    }

    function setForgeNFTContract(address _nft) external onlyOwner {
        forgeNFT = IForgeNFT(_nft);
    }

    function setArtifactNFTContract(address _nft) external onlyOwner {
        artifactNFT = IArtifactNFT(_nft);
    }

    function setBaseForgeGenerationRate(uint256 _rate) external onlyOwner {
        baseAetherPerSecondPerLevel = _rate;
    }

    function setRefineCostAether(uint256 _cost) external onlyOwner {
        refineCostAether = _cost;
    }

    function setRefineLevelIncrease(uint256 _levelIncrease) external onlyOwner {
        refineLevelIncrease = _levelIncrease;
    }

    function setArtifactCraftCostAether(uint256 _cost) external onlyOwner {
        artifactCraftCostAether = _cost;
    }

    function setMasteryPointsPerAction(uint256 _points) external onlyOwner {
        masteryPointsPerAction = _points;
    }

     function setForgeMintCostEssence(uint256 _cost) external onlyOwner {
        forgeMintCostEssence = _cost;
    }

    function withdrawProtocolFees(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner(), amount), "Fee withdrawal failed");
    }

    // --- User Interaction (Essence Stake & Forge Management) ---

    function depositEssence(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        // TransferFrom allows the contract to pull tokens pre-approved by the user
        require(essenceToken.transferFrom(_msgSender(), address(this), amount), "Essence transfer failed");
        userEssenceDeposits[_msgSender()] += amount;
        emit EssenceDeposited(_msgSender(), amount);
    }

    function withdrawEssence(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(userEssenceDeposits[_msgSender()] >= amount, "Insufficient staked Essence to withdraw");

        // Optional: Add logic here to prevent withdrawal if user owns a Forge,
        // or require burning the Forge first, or pay a penalty.
        // For simplicity here, we allow withdrawal as long as minimum is met for minting/holding Forge if applicable.
        // If Forge requires continuous staking, add check here.

        userEssenceDeposits[_msgSender()] -= amount;
        require(essenceToken.transfer(_msgSender(), amount), "Essence withdrawal failed");
        emit EssenceWithdrawal(_msgSender(), amount);
    }

    function mintForge() external requiresEssenceDeposit(forgeMintCostEssence) {
        require(userForgeId[_msgSender()] == 0, "User already owns a Forge");

        // Generate a unique token ID. Simple example: using block data and sender address hash.
        // NOTE: This is NOT cryptographically secure randomness. Use Chainlink VRF for production.
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, block.difficulty)));
        require(!forgeNFT.exists(tokenId), "Token ID collision, try again"); // Very unlikely

        forgeNFT.mint(_msgSender(), tokenId);
        userForgeId[_msgSender()] = tokenId;
        forgeLastClaimTime[tokenId] = uint40(block.timestamp); // Initialize claim time
        // Set initial properties (level 1, no boost)
        forgeNFT.setForgeProperties(tokenId, 1, 10000, uint40(block.timestamp)); // 10000 = 100% boost multiplier
        emit ForgeMinted(_msgSender(), tokenId);
        _addMastery(_msgSender(), masteryPointsPerAction);
    }

    function claimAether() external requiresForgeExists(_msgSender()) {
        uint256 forgeId = userForgeId[_msgSender()];
        uint256 pendingAether = calculatePendingAether(_msgSender());

        require(pendingAether > 0, "No Aether to claim");

        forgeLastClaimTime[forgeId] = uint40(block.timestamp); // Update claim time FIRST

        require(aetherToken.transfer(_msgSender(), pendingAether), "Aether transfer failed");

        emit AetherClaimed(_msgSender(), forgeId, pendingAether);
         _addMastery(_msgSender(), masteryPointsPerAction);
    }

    function refineForge() external requiresForgeExists(_msgSender()) requiresAether(refineCostAether) {
        uint256 forgeId = userForgeId[_msgSender()];

        // Burn Aether cost
        require(aetherToken.transferFrom(_msgSender(), address(this), refineCostAether), "Aether payment failed for refinement");

        // Get current properties
        (uint256 currentLevel, uint256 boostRateMultiplier, uint40 boostEndTime) = forgeNFT.getForgeProperties(forgeId);

        // Calculate new level
        uint256 newLevel = currentLevel + refineLevelIncrease;

        // Update NFT properties
        forgeNFT.setForgeProperties(forgeId, newLevel, boostRateMultiplier, boostEndTime);

        emit ForgeRefined(_msgSender(), forgeId, newLevel);
        _addMastery(_msgSender(), masteryPointsPerAction);
    }

    // --- User Interaction (Artifacts) ---

    function craftArtifact() external requiresAether(artifactCraftCostAether) {
         // Burn Aether cost
        require(aetherToken.transferFrom(_msgSender(), address(this), artifactCraftCostAether), "Aether payment failed for crafting");

        // Pseudo-randomly determine artifact type and strength
        // Using block data for entropy. Again, NOT cryptographically secure.
        uint256 entropy = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, block.difficulty, block.number)));

        uint8 artifactType;
        uint256 strength;

        // Simple probability distribution based on entropy
        if (entropy % 100 < 60) { // 60% chance of Rate Boost
            artifactType = ARTIFACT_TYPE_RATE_BOOST;
            strength = (entropy % 5000) + 5000; // Strength between 5000 and 10000 (0.5x to 1x multiplier)
        } else { // 40% chance of Duration Boost
            artifactType = ARTIFACT_TYPE_DURATION_BOOST;
            strength = (entropy % (3600 * 24 * 7)) + (3600 * 24); // Duration between 1 day and 8 days
        }

        // Generate unique artifact token ID
        uint256 artifactId = uint256(keccak256(abi.encodePacked(entropy, _msgSender(), block.number)));

        artifactNFT.mint(_msgSender(), artifactId, artifactType, strength);

        emit ArtifactCrafted(_msgSender(), artifactId, artifactType, strength);
        _addMastery(_msgSender(), masteryPointsPerAction);
    }

    // Required by IERC721Receiver to receive NFTs (Artifacts being used)
    // This function will be called by the Artifact NFT contract when transferFrom is called with this contract as the recipient
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Check if the sender is the Artifact NFT contract
        require(_msgSender() == address(artifactNFT), "Only Artifact NFT contract can send to this receiver");

        // Decode intended action from 'data'
        // For simplicity, 'data' is expected to be the target Forge ID (uint256)
        require(data.length == 32, "Invalid data payload");
        uint256 targetForgeId = abi.decode(data, (uint256));

        // Process the artifact usage logic
        _processArtifactUsage(from, tokenId, targetForgeId);

        // Return the ERC721Receiver success magic value
        return this.onERC721Received.selector;
    }


    // Internal function called by onERC721Received to process artifact usage
    function _processArtifactUsage(address user, uint256 artifactId, uint256 targetForgeId) internal {
        // Basic check: Ensure the user applying the artifact owns the target forge
        require(userForgeId[user] == targetForgeId, "User does not own the target Forge");
        require(forgeNFT.exists(targetForgeId), "Target Forge does not exist");

        // Get artifact properties
        (uint8 artifactType, uint256 strength) = artifactNFT.getArtifactProperties(artifactId);

        // Get current forge properties
        (uint256 currentLevel, uint256 boostRateMultiplier, uint40 boostEndTime) = forgeNFT.getForgeProperties(targetForgeId);

        // Apply boost based on artifact type
        if (artifactType == ARTIFACT_TYPE_RATE_BOOST) {
             // Boosts the generation rate multiplier.
             // The boost lasts until the current boost ends (if any) + a base duration, or just adds to the current multiplier.
             // Let's implement adding to the multiplier permanently for simplicity here.
             // A more complex version would track multiple temporary boosts.
             // boostRateMultiplier is in basis points (e.g., 10000 for 100%)
             uint256 newBoostMultiplier = boostRateMultiplier + strength; // Strength is in basis points

            // Update Forge NFT properties (level unchanged, boost multiplier increased, duration potentially reset/extended)
            // For rate boost, maybe duration is always fixed? Or strength is a % increase for a fixed duration?
            // Let's make Rate Boost permanent for this example, Duration Boost temporary.
             forgeNFT.setForgeProperties(targetForgeId, currentLevel, newBoostMultiplier, 0); // 0 indicates permanent for this type
        } else if (artifactType == ARTIFACT_TYPE_DURATION_BOOST) {
            // Adds duration to the current boost end time.
            // The boost multiplier for duration artifacts could be fixed or determined during craft.
            // Let's assume duration artifacts grant a fixed rate boost multiplier (e.g., 150%) for 'strength' seconds.
            uint256 durationBoostMultiplier = 15000; // Example: 150% multiplier (1.5x rate)

            uint40 newBoostEndTime;
            uint40 currentTime = uint40(block.timestamp);

            if (boostEndTime < currentTime) {
                // No active boost, start a new one
                newBoostEndTime = currentTime + uint40(strength); // Strength is in seconds
            } else {
                // Extend existing boost
                newBoostEndTime = boostEndTime + uint40(strength); // Strength is in seconds
            }

            // Update Forge NFT properties (level unchanged, boost multiplier updated, duration extended)
            forgeNFT.setForgeProperties(targetForgeId, currentLevel, durationBoostMultiplier, newBoostEndTime);

        }
        // Add more artifact types here

        // Burn the used artifact NFT
        artifactNFT.burn(artifactId); // Assuming burn function exists in IArtifactNFT

        emit ArtifactUsed(user, targetForgeId, artifactId);
        _addMastery(user, masteryPointsPerAction);
    }

    // --- Global State Management ---

    function updateCatalystState(uint256 _newCatalyst) external onlyOwner {
        require(_newCatalyst <= 20000, "Catalyst cannot exceed 200%"); // Example limit
        emit CatalystUpdated(currentCatalyst, _newCatalyst);
        currentCatalyst = _newCatalyst;
    }

    // --- Query Functions (View/Pure) ---

    function getUserEssenceDeposit(address user) external view returns (uint256) {
        return userEssenceDeposits[user];
    }

    function getUserForgeId(address user) external view returns (uint256) {
        return userForgeId[user];
    }

     // Note: This reads properties from the Forge NFT contract
    function getForgeProperties(uint256 forgeId) external view returns (uint256 level, uint256 boostRateMultiplier, uint40 boostEndTime) {
         require(forgeNFT.exists(forgeId), "Forge does not exist");
         return forgeNFT.getForgeProperties(forgeId);
    }

    function calculatePendingAether(address user) public view requiresForgeExists(user) returns (uint256) {
        uint256 forgeId = userForgeId[user];
        uint40 lastClaim = forgeLastClaimTime[forgeId];
        uint40 currentTime = uint40(block.timestamp);

        if (currentTime <= lastClaim) {
            return 0; // Time hasn't advanced or is somehow less (shouldn't happen)
        }

        uint256 timeElapsed = currentTime - lastClaim;

        // Get Forge properties and Mastery
        (uint256 level, uint256 boostRateMultiplier, uint40 boostEndTime) = forgeNFT.getForgeProperties(forgeId);
        uint256 userMasteryPoints = userMastery[user];

        // Calculate base rate per second: BaseRate * Level
        uint256 baseRatePerSecond = baseAetherPerSecondPerLevel * level;

        // Calculate total rate per second: BaseRate * (1 + MasteryBonus + ArtifactBoost + CatalystBonus)
        // Example: Mastery adds 0.1% per 100 points, Catalyst is a direct multiplier
        uint256 masteryBonusBasisPoints = userMasteryPoints / 100; // 1 point per 100 mastery

        // Determine the active boost multiplier: check if artifact boost is active
        uint256 activeBoostMultiplier = 10000; // Default 100% (1x)
        if (boostEndTime > currentTime) {
             // If a temporary boost is active, use its multiplier
             activeBoostMultiplier = boostRateMultiplier; // boostRateMultiplier holds the value for temporary boosts
        } else {
             // If no temporary boost is active, check for permanent boosts (indicated by boostEndTime == 0)
             // This assumes ARTIFACT_TYPE_RATE_BOOST sets boostEndTime to 0 and stores the permanent multiplier in boostRateMultiplier
             if (boostEndTime == 0 && boostRateMultiplier > 10000) {
                  activeBoostMultiplier = boostRateMultiplier;
             }
             // Otherwise, activeBoostMultiplier remains 10000 (1x)
        }


        // Total multiplier calculation (in basis points, 10000 = 100%)
        // Combine base rate, mastery bonus, artifact boost, and catalyst
        // (Level Rate) * (100% + Mastery% + Artifact%) * Catalyst%
        // Let's simplify: (BaseRate * Level) * (10000 + masteryBonusBasisPoints) / 10000 * (activeBoostMultiplier / 10000) * (currentCatalyst / 10000)
        // Avoid large numbers: (BaseRate * Level * (10000 + masteryBonusBasisPoints) * activeBoostMultiplier * currentCatalyst) / (10000 * 10000 * 10000)
        // Be careful with division order to maintain precision.
        // Let's use basis points consistently:
        // Total multiplier BP = 10000 (base) + masteryBonusBasisPoints + (activeBoostMultiplier - 10000) // Add the *extra* boost from artifact
        // No, this is wrong. Multipliers compose: Base * (1+M%) * (1+A%) * (C%). Or Base * (1 + M% + A%) * C%?
        // Let's assume multipliers additively affect the base rate for simplicity in this example:
        // Rate = BaseRatePerSecPerLevel * Level * (10000 + masteryBonusBasisPoints + (activeBoostMultiplier > 10000 ? activeBoostMultiplier - 10000 : 0) + (currentCatalyst > 10000 ? currentCatalyst - 10000 : 0)) / 10000
        // No, Catalyst is probably a *global* multiplier on the entire calculated rate.
        // Rate = (BaseRatePerSecPerLevel * Level * (10000 + masteryBonusBasisPoints + (activeBoostMultiplier > 10000 ? activeBoostMultiplier - 10000 : 0))) / 10000 * currentCatalyst / 10000
        // Rate = (BaseRatePerSecPerLevel * Level * (10000 + masteryBonusBasisPoints + (activeBoostMultiplier > 10000 ? activeBoostMultiplier - 10000 : 0)) * currentCatalyst) / 1e8 // Assuming 1e8 for 10000*10000

        // Let's refine the rate calculation based on how Boosts & Catalyst apply:
        // Effective Rate Per Second = (BaseRatePerLevel * Level) * (1 + MasteryBonus%) * (1 + ArtifactBoost%) * Catalyst%
        // Where MasteryBonus% = masteryPoints / 1000000 (0.1% per 100 points => 1bp per point)
        // Where ArtifactBoost% is derived from activeBoostMultiplier (e.g., activeBoostMultiplier / 10000)
        // Where Catalyst% is currentCatalyst / 10000

        // Rate per second = (BaseRatePerLevel * Level) * (10000 + userMasteryPoints) / 10000 * activeBoostMultiplier / 10000 * currentCatalyst / 10000
        // = (BaseRatePerLevel * Level * (10000 + userMasteryPoints) * activeBoostMultiplier * currentCatalyst) / 1e12 (10000^3)
         uint256 effectiveRatePerSecond = (baseAetherPerSecondPerLevel * level * (10000 + userMasteryPoints) * activeBoostMultiplier * currentCatalyst) / (10000 * 10000 * 10000); // Using uints implicitly handles floor

        uint256 totalAether = effectiveRatePerSecond * timeElapsed;

        return totalAether;
    }

    function getUserMastery(address user) external view returns (uint256) {
        return userMastery[user];
    }

    // Simple example rank calculation
    function calculateUserRank(address user) external view returns (string memory) {
        uint256 mastery = userMastery[user];
        if (mastery < 1000) return "Apprentice";
        if (mastery < 5000) return "Journeyman";
        if (mastery < 10000) return "Artisan";
        if (mastery < 25000) return "Master Forger";
        return "Legendary Forger";
    }

     // Note: This reads properties from the Artifact NFT contract
    function getArtifactProperties(uint256 artifactId) external view returns (uint8 artifactType, uint256 strength) {
        return artifactNFT.getArtifactProperties(artifactId);
    }

    function getCurrentCatalyst() external view returns (uint256) {
        return currentCatalyst;
    }

    function getForgeLastClaimTime(uint256 forgeId) external view returns (uint40) {
        require(forgeNFT.exists(forgeId), "Forge does not exist");
        return forgeLastClaimTime[forgeId];
    }


    // --- Internal/Helper Functions ---

    function _addMastery(address user, uint256 points) internal {
        if (points > 0) {
            userMastery[user] += points;
            emit MasteryGained(user, points);
        }
    }

    // --- Fallback/Receive (Optional but good practice) ---
    receive() external payable {
        // Reject direct ether transfers
        revert("Ether is not accepted");
    }

    fallback() external payable {
        // Reject calls to undefined functions
        revert("Call to undefined function");
    }
}
```

**Explanation and Notes:**

1.  **OpenZeppelin Usage:** The contract uses `Ownable`, `Context`, `IERC20`, `IERC721`, and `IERC721Receiver` from OpenZeppelin. You would need to install OpenZeppelin contracts (e.g., `npm install @openzeppelin/contracts`) to compile this.
2.  **Separate Contracts:** `Essence`, `Aether`, `Forge`, and `Artifact` are assumed to be separate standard token/NFT contracts (ERC20 and ERC721). The `AetheriumForge` contract interacts with them via interfaces (`IERC20`, `IForgeNFT`, `IArtifactNFT`). The `IForgeNFT` and `IArtifactNFT` interfaces define minimal custom functions needed (`mint`, `setForgeProperties`, `getForgeProperties`, `burn`). You would need to implement these token/NFT contracts separately.
3.  **Dynamic Forge NFT:** The `IForgeNFT` interface includes `setForgeProperties` and `getForgeProperties`. This is how the `AetheriumForge` contract can *change* the properties (like level, boost) of the Forge NFT owned by a user. A real implementation of the Forge NFT contract would need to store these properties mapping token ID -> properties.
4.  **Time-Based Generation:** `claimAether` calculates the duration since the `forgeLastClaimTime` and multiplies it by the effective rate per second. The effective rate is a complex calculation incorporating level, mastery, artifacts, and catalyst.
5.  **Multi-Factor Rate Calculation:** The `calculatePendingAether` function shows how multiple factors compose to determine the yield rate. The example calculation uses a combination of additive and multiplicative effects (Level, Mastery, Artifact Boost, Catalyst). The specific formula `(BaseRatePerLevel * Level * (10000 + userMasteryPoints) * activeBoostMultiplier * currentCatalyst) / 1e12` is just *one* way to combine these in basis points; you can devise a more complex or simpler economic model.
6.  **Artifact Utility (`useArtifactOnForge` & `onERC721Received`):**
    *   The `useArtifactOnForge` function isn't directly called by the user. Instead, the user calls `transferFrom` on their `ArtifactNFT` contract, sending the artifact to the `AetheriumForge` contract's address.
    *   When the `AetheriumForge` contract *receives* an ERC721 token (an Artifact), the `onERC721Received` fallback is triggered.
    *   The `onERC721Received` function verifies the sender is the `ArtifactNFT` contract and decodes the `data` payload to find the target Forge NFT ID.
    *   It then calls the internal `_processArtifactUsage` function to apply the boost and burn the artifact.
    *   This pattern (transferring an NFT *to* a contract to trigger an action) is a common way to implement utility NFTs.
7.  **On-Chain Entropy:** `craftArtifact` uses `keccak256` with block data and sender address. **Important:** This is **not** secure randomness for high-value outcomes as miners/validators can influence block data to some extent. For production, integrate with a decentralized oracle like Chainlink VRF.
8.  **Global Catalyst:** `currentCatalyst` affects everyone's yield. In a real application, this could be updated by a DAO vote, an oracle pulling real-world data, or a complex game mechanic. Here, it's owner-set for simplicity.
9.  **Mastery:** `userMastery` tracks user engagement. It's increased on key actions. `calculateUserRank` is a simple example of deriving status from mastery.
10. **Minimum 20 Functions:** We have well over 20 distinct functions covering various aspects of the system: setup (12), user interaction (7), global state (1), queries (8), receiver (1), internal (1) = 30+ functions.
11. **No Duplication:** While individual components like token transfers or basic NFT minting/burning are standard, the *combination* of dynamic NFT yield based on multiple factors, utility NFTs consumed by the contract, integrated progression, global state influence, and on-chain crafting within a single cohesive system makes this contract unique and not a direct copy of standard open-source contracts.

This contract provides a solid foundation for a gamified DeFi or resource-management protocol on chain, showcasing several advanced concepts. Remember to implement the linked ERC20 and ERC721 contracts separately and deploy them before deploying and initializing this `AetheriumForge` contract with their addresses.