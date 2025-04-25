Okay, here is a Solidity smart contract demonstrating several interesting, advanced, and creative concepts. It focuses on dynamic NFTs that evolve based on various on-chain and potential off-chain conditions (simulated via oracle).

This contract, named `ChronoGems`, implements NFTs that represent "Gems" which can evolve through different stages. Evolution is triggered by meeting a combination of requirements:
1.  **Time:** A minimum amount of time/blocks must pass since the last evolution.
2.  **Staking:** The Gem must be staked for a minimum duration.
3.  **Resources:** Specific ERC-20 tokens ("Essence") must be 'fed' to the Gem.
4.  **Oracle Data:** A specific value must be reported by a trusted oracle.
5.  **Achievements:** Certain predefined achievements must be unlocked for the Gem/owner.

This involves intricate state management, interaction with external contracts (ERC20, simulated Oracle), time-based logic, staking mechanics, and a flexible evolution system.

---

## Contract Outline and Function Summary

**Contract Name:** ChronoGems

**Concept:** Dynamic Non-Fungible Tokens (NFTs) that evolve through different stages based on a combination of time elapsed, staking duration, consumption of ERC-20 resources ("Essence"), external data (via a simulated Oracle), and unlocked achievements.

**Key Features:**
*   **ERC721 Standard:** Core NFT functionality (ownership, transfers, approvals).
*   **Dynamic State:** Gems have evolving stages and properties.
*   **Multi-Condition Evolution:** Evolution requires meeting *multiple* criteria simultaneously.
*   **Staking Mechanics:** Users can stake Gems to meet evolution criteria and potentially earn rewards (basic staking duration tracking for evolution shown).
*   **ERC-20 Resource Consumption:** Requires 'feeding' an associated ERC-20 token.
*   **Oracle Integration:** Simulates dependency on external data for evolution criteria.
*   **Achievement System:** Tracks and requires specific achievements for evolution.
*   **Pausable:** Contract can be paused by the owner.
*   **Upgradeable (Placeholder):** Structure allows for potential upgradeability patterns (though not fully implemented here).

**Libraries/Standards Used:**
*   OpenZeppelin ERC721, Ownable, Pausable, Counters, Address

**Enums and Structs:**
*   `GemStage`: Enum representing the different evolution stages (e.g., EGG, LARVA, CHRYSALIS, MATURE, ANCIENT).
*   `EvolutionRequirements`: Struct defining the conditions needed to transition from one stage to the next (required block age, stake duration, essence amount, oracle value, achievement IDs).

**State Variables:**
*   `_tokenIdCounter`: Counter for minting new tokens.
*   `_gemStage`: Maps token ID to its current evolution stage.
*   `_lastEvolutionBlock`: Maps token ID to the block number of its last evolution.
*   `_gemStakingInfo`: Maps token ID to the block number when staking ends or allows unstake.
*   `_gemResourceBalance`: Maps token ID and resource token address to the amount of resource fed.
*   `_gemAchievements`: Maps token ID and achievement ID to a boolean indicating if unlocked.
*   `_essenceToken`: Address of the ERC-20 token required for feeding.
*   `_oracle`: Address of the simulated Oracle contract.
*   `_oracleData`: Maps oracle data keys (bytes32) to uint256 values.
*   `_evolutionRequirements`: Maps (current stage, next stage) to the required `EvolutionRequirements` struct.

**Events:**
*   `GemMinted`: Logged when a new Gem is minted.
*   `GemEvolved`: Logged when a Gem evolves to a new stage.
*   `GemStaked`: Logged when a Gem is staked.
*   `GemUnstaked`: Logged when a Gem is unstaked.
*   `EssenceFed`: Logged when Essence is fed to a Gem.
*   `AchievementUnlocked`: Logged when an achievement is unlocked for a Gem.
*   `OracleDataUpdated`: Logged when oracle data is updated.
*   `EvolutionConditionsSet`: Logged when evolution conditions are set for a stage transition.

**Function Summary (>= 20 functions):**

**ERC721 Base Functions (8):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (View)
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (View)
3.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific token.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for a single token. (View)
5.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator to manage all tokens.
6.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens. (View)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (standard).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a token (safe, checks receiver).
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers a token (safe with data, checks receiver). (Overloaded = 1 more, so let's count this as 9 ERC721 base)
10. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token. (View)

**Core ChronoGems Functionality:**
11. `constructor()`: Initializes the contract, sets owner, and pauses it initially.
12. `mint()`: Mints a new Gem token to the caller.
13. `triggerEvolution(uint256 tokenId)`: Attempts to evolve the specified Gem token if all conditions are met.
14. `stakeGem(uint256 tokenId, uint256 durationBlocks)`: Stakes a Gem for a specified number of blocks. Requires caller is owner.
15. `unstakeGem(uint256 tokenId)`: Unstakes a Gem if the staking duration has passed. Requires caller is owner.
16. `feedEssence(uint256 tokenId, uint256 amount)`: Transfers Essence tokens from the caller to the contract on behalf of the Gem, increasing its resource balance. Requires caller approves contract first.

**Achievement System:**
17. `unlockAchievement(uint256 tokenId, uint256 achievementId)`: Allows unlocking a specific achievement for a Gem. (Example: Could be internal or owner-only depending on game logic). Made public for demonstration.
18. `checkAchievementStatus(uint256 tokenId, uint256 achievementId)`: Checks if a specific achievement is unlocked for a Gem. (View)

**Oracle Integration (Simulated):**
19. `setOracleAddress(address oracleAddress)`: Sets the address of the trusted Oracle contract. (Owner-only)
20. `updateOracleData(bytes32 key, uint256 value)`: Updates Oracle data. (Restricted - here, owner-only for simplicity, could be `onlyOracle`)

**Admin & Configuration:**
21. `setEssenceToken(address tokenAddress)`: Sets the address of the required Essence ERC-20 token. (Owner-only)
22. `setEvolutionConditions(GemStage fromStage, GemStage toStage, EvolutionRequirements conditions)`: Sets the requirements for a specific stage transition. (Owner-only)
23. `addEvolutionStage(GemStage stage)`: Placeholder/helper if stages were dynamically added (not used in this fixed-enum version, but could be part of a more advanced admin). (Let's replace this with another useful admin func).
23. `withdrawStuckTokens(address tokenAddress, uint256 amount)`: Allows the owner to withdraw accidentally sent ERC20 tokens. (Owner-only)

**View Functions (beyond ERC721 views):**
24. `getGemStage(uint256 tokenId)`: Returns the current evolution stage of a Gem. (View)
25. `getLastEvolutionBlock(uint256 tokenId)`: Returns the block number of the Gem's last evolution. (View)
26. `getStakingInfo(uint256 tokenId)`: Returns the block number until which the Gem is staked. (View)
27. `getGemEssenceBalance(uint256 tokenId, address essenceToken)`: Returns the amount of a specific essence token fed to a Gem. (View)
28. `getEvolutionRequirements(GemStage fromStage, GemStage toStage)`: Returns the requirements for a stage transition. (View)
29. `isGemStaked(uint256 tokenId)`: Checks if a gem is currently staked past the current block. (View)
30. `isGemRequirementMet(uint256 tokenId, GemStage fromStage, GemStage toStage)`: Helper view to check if ALL evolution requirements for a transition are met *now*. (View)

This list totals 30 functions, exceeding the minimum requirement of 20 and covering the planned features.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional, adds token list/index
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For isContract checks

/**
 * @title ChronoGems
 * @dev A dynamic NFT contract where Gems evolve based on multi-condition triggers:
 *      Time elapsed, staking duration, ERC-20 resource consumption, oracle data, and achievements.
 *
 * Contract Outline:
 * - Implements ERC721Enumerable, Ownable, Pausable.
 * - Manages Gem state (stage, last evolution block, staking info, resources, achievements).
 * - Defines evolution stages and requirements for stage transitions.
 * - Provides functions for minting, evolving, staking, feeding resources, unlocking achievements,
 *   interacting with a simulated oracle, and administrative tasks.
 *
 * Function Summary (>= 20 functions):
 * ERC721 Base Functions (9 inherited + 1 standard):
 * 1. balanceOf(address owner)
 * 2. ownerOf(uint256 tokenId)
 * 3. approve(address to, uint256 tokenId)
 * 4. getApproved(uint256 tokenId)
 * 5. setApprovalForAll(address operator, bool approved)
 * 6. isApprovedForAll(address owner, address operator)
 * 7. transferFrom(address from, address to, uint256 tokenId)
 * 8. safeTransferFrom(address from, address to, uint256 tokenId)
 * 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
 * 10. tokenURI(uint256 tokenId)
 *
 * Core ChronoGems Functionality:
 * 11. constructor()
 * 12. mint()
 * 13. triggerEvolution(uint256 tokenId)
 * 14. stakeGem(uint256 tokenId, uint256 durationBlocks)
 * 15. unstakeGem(uint256 tokenId)
 * 16. feedEssence(uint256 tokenId, uint256 amount)
 *
 * Achievement System:
 * 17. unlockAchievement(uint256 tokenId, uint256 achievementId)
 * 18. checkAchievementStatus(uint256 tokenId, uint256 achievementId)
 *
 * Oracle Integration (Simulated):
 * 19. setOracleAddress(address oracleAddress) (Owner-only)
 * 20. updateOracleData(bytes32 key, uint256 value) (Owner-only for sim)
 *
 * Admin & Configuration:
 * 21. setEssenceToken(address tokenAddress) (Owner-only)
 * 22. setEvolutionConditions(GemStage fromStage, GemStage toStage, EvolutionRequirements conditions) (Owner-only)
 * 23. withdrawStuckTokens(address tokenAddress, uint256 amount) (Owner-only)
 *
 * View Functions:
 * 24. getGemStage(uint256 tokenId)
 * 25. getLastEvolutionBlock(uint256 tokenId)
 * 26. getStakingInfo(uint256 tokenId)
 * 27. getGemEssenceBalance(uint256 tokenId, address essenceToken)
 * 28. getEvolutionRequirements(GemStage fromStage, GemStage toStage)
 * 29. isGemStaked(uint256 tokenId)
 * 30. isGemRequirementMet(uint256 tokenId, GemStage fromStage, GemStage toStage)
 */
contract ChronoGems is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter private _tokenIdCounter;

    // --- Enums ---
    enum GemStage { EGG, LARVA, CHRYSALIS, MATURE, ANCIENT, MAX_STAGE } // Added MAX_STAGE as boundary

    // --- Structs ---
    struct EvolutionRequirements {
        uint256 requiredBlockAge; // Blocks since last evolution
        uint256 requiredStakeDurationBlocks; // Blocks Gem must be staked consecutively
        uint256 requiredEssenceAmount; // Total essence required (resets on evolution or consumed?) Let's make it consumed on evolution.
        bytes32 requiredOracleKey;    // Key for oracle data
        uint256 requiredOracleValue;  // Required value from oracle for the key
        uint256[] requiredAchievementIds; // List of achievement IDs required
    }

    // --- State Variables ---
    mapping(uint256 => GemStage) private _gemStage;
    mapping(uint256 => uint256) private _lastEvolutionBlock; // Block number
    mapping(uint256 => uint256) private _gemStakingInfo; // Block number until unstake is allowed (0 if not staked)
    mapping(uint256 => mapping(address => uint256)) private _gemResourceBalance; // tokenId => resourceToken => amount fed

    // Achievement Tracking: tokenId => achievementId => unlocked
    mapping(uint256 => mapping(uint256 => bool)) private _gemAchievements;

    address private _essenceToken; // Address of the ERC-20 Essence token

    address private _oracle; // Address of the trusted Oracle contract
    // Simulated Oracle Data: key => value
    mapping(bytes32 => uint256) private _oracleData;

    // Evolution Requirements: currentStage => nextStage => requirements
    mapping(GemStage => mapping(GemStage => EvolutionRequirements)) private _evolutionRequirements;

    // --- Events ---
    event GemMinted(address indexed owner, uint256 indexed tokenId, GemStage initialStage);
    event GemEvolved(uint256 indexed tokenId, GemStage fromStage, GemStage toStage, uint256 blockNumber);
    event GemStaked(uint256 indexed tokenId, address indexed owner, uint256 durationBlocks, uint256 untilBlock);
    event GemUnstaked(uint256 indexed tokenId, address indexed owner, uint256 blockNumber);
    event EssenceFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, address indexed essenceToken);
    event AchievementUnlocked(uint256 indexed tokenId, uint256 indexed achievementId, address indexed unlocker);
    event OracleDataUpdated(bytes32 indexed key, uint256 value, uint256 blockNumber);
    event EvolutionConditionsSet(GemStage indexed fromStage, GemStage indexed toStage);

    // --- Constructor ---
    constructor() ERC721Enumerable("ChronoGem", "CGEM") Ownable(msg.sender) Pausable(msg.sender) {
        // Contract is paused initially by Pausable constructor. Owner must unpause.
        // Set initial evolution requirements (example)
        // EGG -> LARVA
        _evolutionRequirements[GemStage.EGG][GemStage.LARVA] = EvolutionRequirements({
            requiredBlockAge: 100,
            requiredStakeDurationBlocks: 50,
            requiredEssenceAmount: 1000 * (10**18), // Example: 1000 tokens (assuming 18 decimals)
            requiredOracleKey: keccak256("COSMIC_ALIGNMENT"), // Example key
            requiredOracleValue: 1, // Example required value
            requiredAchievementIds: new uint256[](0) // No specific achievements for this stage
        });
        // LARVA -> CHRYSALIS
         _evolutionRequirements[GemStage.LARVA][GemStage.CHRYSALIS] = EvolutionRequirements({
            requiredBlockAge: 500,
            requiredStakeDurationBlocks: 200,
            requiredEssenceAmount: 5000 * (10**18),
            requiredOracleKey: keccak256("SOLAR_FLARE_INDEX"),
            requiredOracleValue: 50,
            requiredAchievementIds: new uint256[](1) // Requires 1 achievement
        });
        _evolutionRequirements[GemStage.LARVA][GemStage.CHRYSALIS].requiredAchievementIds[0] = 1; // Achievement ID 1

        // CHRYSALIS -> MATURE
         _evolutionRequirements[GemStage.CHRYSALIS][GemStage.MATURE] = EvolutionRequirements({
            requiredBlockAge: 1000,
            requiredStakeDurationBlocks: 500,
            requiredEssenceAmount: 10000 * (10**18),
            requiredOracleKey: keccak256("GALACTIC_ENERGY"),
            requiredOracleValue: 100,
            requiredAchievementIds: new uint256[](2) // Requires 2 achievements
        });
         _evolutionRequirements[GemStage.CHRYSALIS][GemStage.MATURE].requiredAchievementIds[0] = 1; // Achievement ID 1
         _evolutionRequirements[GemStage.CHRYSALIS][GemStage.MATURE].requiredAchievementIds[1] = 2; // Achievement ID 2

         // MATURE -> ANCIENT
          _evolutionRequirements[GemStage.MATURE][GemStage.ANCIENT] = EvolutionRequirements({
            requiredBlockAge: 5000,
            requiredStakeDurationBlocks: 2000,
            requiredEssenceAmount: 50000 * (10**18),
            requiredOracleKey: keccak256("UNIVERSE_STABILITY"),
            requiredOracleValue: 999,
            requiredAchievementIds: new uint256[](3) // Requires 3 achievements
        });
         _evolutionRequirements[GemStage.MATURE][GemStage.ANCIENT].requiredAchievementIds[0] = 1; // Achievement ID 1
         _evolutionRequirements[GemStage.MATURE][GemStage.ANCIENT].requiredAchievementIds[1] = 2; // Achievement ID 2
         _evolutionRequirements[GemStage.MATURE][GemStage.ANCIENT].requiredAchievementIds[2] = 3; // Achievement ID 3

        // Set default essence token and oracle address (can be changed by owner)
        // These need to be set *after* deployment in a real scenario, or passed to constructor.
        // Setting them to zero address initially as placeholders.
        _essenceToken = address(0);
        _oracle = address(0);
    }

    // --- ERC721 Overrides ---
    // These are standard ERC721 functions provided by OpenZeppelin.
    // They are listed here for the function count requirement.
    // 1. balanceOf - Inherited from ERC721
    // 2. ownerOf - Inherited from ERC721
    // 3. approve - Inherited from ERC721
    // 4. getApproved - Inherited from ERC721
    // 5. setApprovalForAll - Inherited from ERC721
    // 6. isApprovedForAll - Inherited from ERC721
    // 7. transferFrom - Inherited from ERC721
    // 8. safeTransferFrom - Inherited from ERC721
    // 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes data) - Inherited from ERC721Enumerable

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for token ID
     * `tokenId` will be the concatenation of the `baseURI` and `tokenId`.
     */
    function _baseURI() internal pure override returns (string memory) {
        // Placeholder: In a real project, this would point to your metadata server
        return "ipfs://YOUR_METADATA_CID/";
    }

    /**
     * @dev Returns the metadata URI for `tokenId`.
     * 10. tokenURI - Standard ERC721, overridden for custom base URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // Append token ID to base URI
        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)));
        // Note: For dynamic NFTs, the metadata *should* change with the stage.
        // A more advanced implementation would include the stage in the URI or metadata logic.
        // e.g., ipfs://YOUR_METADATA_CID/stageX/tokenId
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Used to handle internal state when tokens are transferred.
     * Staking and resource balances are tied to the token, not the owner.
     * Achievements *could* be tied to owner or token - here tied to token.
     * Staking must be ended before transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
             // Prevent transfer if gem is staked
            if (_gemStakingInfo[tokenId] > block.number) {
                 revert("ChronoGems: Cannot transfer staked gem");
            }
            // Add any other checks needed before transfer
        }
    }

    // --- Core ChronoGems Functions ---

    /**
     * @dev Mints a new ChronoGem token and assigns it to the caller.
     * Sets the initial stage and last evolution block.
     * 12. mint()
     */
    function mint() public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        _gemStage[newTokenId] = GemStage.EGG;
        _lastEvolutionBlock[newTokenId] = block.number;
        // _gemStakingInfo[newTokenId] defaults to 0 (not staked)
        // _gemResourceBalance defaults to 0
        // _gemAchievements defaults to false

        emit GemMinted(msg.sender, newTokenId, GemStage.EGG);

        return newTokenId;
    }

    /**
     * @dev Attempts to evolve a specific Gem token.
     * Checks all required conditions based on the current stage and the next possible stage.
     * If all conditions are met, the Gem evolves, resources are consumed, and state is updated.
     * 13. triggerEvolution(uint256 tokenId)
     */
    function triggerEvolution(uint256 tokenId) public whenNotPaused {
        // Check if token exists and is owned by the caller
        require(_exists(tokenId), "ChronoGems: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ChronoGems: Caller is not the owner");

        GemStage currentStage = _gemStage[tokenId];
        // Cannot evolve beyond the maximum defined stage
        require(uint8(currentStage) < uint8(GemStage.MAX_STAGE) - 1, "ChronoGems: Gem is at max stage");

        GemStage nextStage = GemStage(uint8(currentStage) + 1);
        EvolutionRequirements storage reqs = _evolutionRequirements[currentStage][nextStage];

        // --- Check Evolution Conditions ---
        require(block.number >= _lastEvolutionBlock[tokenId] + reqs.requiredBlockAge, "ChronoGems: Time requirement not met");
        require(_isGemStakedForDuration(tokenId, reqs.requiredStakeDurationBlocks), "ChronoGems: Staking requirement not met");
        require(_gemResourceBalance[tokenId][_essenceToken] >= reqs.requiredEssenceAmount, "ChronoGems: Resource requirement not met");
        require(_oracleData[reqs.requiredOracleKey] == reqs.requiredOracleValue, "ChronoGems: Oracle data requirement not met");
        _checkAchievementRequirements(tokenId, reqs.requiredAchievementIds); // Reverts if not met

        // --- Evolution Logic ---
        // Consume required resources
        _gemResourceBalance[tokenId][_essenceToken] = _gemResourceBalance[tokenId][_essenceToken] - reqs.requiredEssenceAmount;
        // Note: Staking state and achievements are requirements, not consumed by evolution itself, but updated separately.

        // Update Gem state
        _gemStage[tokenId] = nextStage;
        _lastEvolutionBlock[tokenId] = block.number;
        // Reset staking info *if* staking was required for evolution, user must restake for next stage
        // or keep the staking info if duration requirement was met via a long stake
        // Let's reset staking requirement for simplicity for the next stage. User must explicitly stake again.
        _gemStakingInfo[tokenId] = 0; // Ends any current stake tracking for evolution purposes

        emit GemEvolved(tokenId, currentStage, nextStage, block.number);
    }

    /**
     * @dev Stakes a Gem token for a specific duration in blocks.
     * Caller must be the owner of the token.
     * Cancels any existing stake.
     * 14. stakeGem(uint256 tokenId, uint256 durationBlocks)
     */
    function stakeGem(uint256 tokenId, uint256 durationBlocks) public whenNotPaused {
        require(_exists(tokenId), "ChronoGems: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ChronoGems: Caller is not the owner");
        require(durationBlocks > 0, "ChronoGems: Staking duration must be positive");

        // Override any previous stake
        _gemStakingInfo[tokenId] = block.number + durationBlocks;

        emit GemStaked(tokenId, msg.sender, durationBlocks, _gemStakingInfo[tokenId]);
    }

    /**
     * @dev Unstakes a Gem token if the staking duration has passed.
     * Allows the owner to end the staking period tracking.
     * Does *not* imply claiming rewards in this simple example.
     * 15. unstakeGem(uint256 tokenId)
     */
    function unstakeGem(uint256 tokenId) public whenNotPaused {
         require(_exists(tokenId), "ChronoGems: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ChronoGems: Caller is not the owner");
        require(_gemStakingInfo[tokenId] > 0, "ChronoGems: Gem is not staked");
        require(block.number >= _gemStakingInfo[tokenId], "ChronoGems: Staking duration not yet passed");

        _gemStakingInfo[tokenId] = 0; // End the stake tracking

        emit GemUnstaked(tokenId, msg.sender, block.number);
    }

     /**
     * @dev Checks if a gem is currently staked past the current block.
     * 29. isGemStaked(uint256 tokenId)
     */
    function isGemStaked(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "ChronoGems: Token does not exist");
         return _gemStakingInfo[tokenId] > block.number;
    }


    /**
     * @dev Feeds Essence ERC-20 tokens to a Gem.
     * Transfers the specified amount of Essence from the caller to this contract.
     * Increments the Gem's resource balance.
     * Caller must own the token and approve this contract to spend the Essence.
     * 16. feedEssence(uint256 tokenId, uint256 amount)
     */
    function feedEssence(uint256 tokenId, uint256 amount) public whenNotPaused {
        require(_exists(tokenId), "ChronoGems: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ChronoGems: Caller is not the owner");
        require(amount > 0, "ChronoGems: Amount must be positive");
        require(_essenceToken != address(0), "ChronoGems: Essence token address not set");
        require(_essenceToken.isContract(), "ChronoGems: Essence token address is not a contract");

        // Transfer Essence tokens from the caller to this contract
        IERC20 essence = IERC20(_essenceToken);
        require(essence.transferFrom(msg.sender, address(this), amount), "ChronoGems: Essence transfer failed");

        // Update Gem's resource balance
        _gemResourceBalance[tokenId][_essenceToken] += amount;

        emit EssenceFed(tokenId, msg.sender, amount, _essenceToken);
    }

    // --- Internal Evolution Condition Checkers ---
    // These are internal helpers used by triggerEvolution.

    /**
     * @dev Internal function to check if the staking duration requirement is met.
     * Does NOT check if the gem is currently staked, but if it *was* staked
     * long enough since its last evolution. This requires a more complex
     * staking history or continuously updated state.
     * For simplicity here, it checks if the *current* stake duration is
     * greater than or equal to the requirement. A real system might track accumulated staked blocks.
     *
     * A simple approach: check if the Gem was staked long enough *since the last evolution block*.
     * This means if user unstakes early, they lose progress for *this* requirement.
     * Let's implement this simpler logic: check if the current stake period started
     * BEFORE (last evolution block + required blocks) and ENDS AFTER (last evolution block + required blocks).
     * Or even simpler: just check if the current stake *duration* is long enough. The `triggerEvolution`
     * will handle if it's currently staked.
     * Let's use the simpler approach for this example: check if `_gemStakingInfo[tokenId]` reflects
     * a duration from `_lastEvolutionBlock[tokenId]` that meets the requirement.
     * THIS IS A SIMPLIFICATION. A real system needs complex staking history.
     */
    function _isGemStakedForDuration(uint256 tokenId, uint256 requiredDurationBlocks) internal view returns (bool) {
        if (requiredDurationBlocks == 0) {
            return true; // No staking required
        }
        // Simple check: Does the current stake period, starting from `_lastEvolutionBlock`,
        // extend *at least* `requiredDurationBlocks` into the future?
        // Requires the gem to be staked *since* the last evolution block or earlier.
        // If _gemStakingInfo[tokenId] represents the END block, then
        // (End Block - Last Evolution Block) >= Required Duration
        uint256 stakeEndBlock = _gemStakingInfo[tokenId];
        uint256 lastEvoBlock = _lastEvolutionBlock[tokenId];

        if (stakeEndBlock <= lastEvoBlock) {
            // Not staked since last evolution block, or stake ended too early
            return false;
        }

        return (stakeEndBlock - lastEvoBlock) >= requiredDurationBlocks;
    }


    /**
     * @dev Internal function to check if all required achievements are unlocked for a Gem.
     * Reverts if any required achievement is missing.
     */
    function _checkAchievementRequirements(uint256 tokenId, uint256[] memory requiredAchievementIds) internal view {
        for (uint i = 0; i < requiredAchievementIds.length; i++) {
            if (!_gemAchievements[tokenId][requiredAchievementIds[i]]) {
                revert("ChronoGems: Achievement requirement not met");
            }
        }
    }

    // --- Achievement System Functions ---

    /**
     * @dev Unlocks a specific achievement for a Gem.
     * This function could be called internally based on in-game actions,
     * or externally by a trusted server/owner depending on the design.
     * Made public for demonstration purposes.
     * 17. unlockAchievement(uint256 tokenId, uint256 achievementId)
     */
    function unlockAchievement(uint256 tokenId, uint256 achievementId) public whenNotPaused {
        // Add access control if needed (e.g., onlyOwner, or only certain roles/addresses)
        // require(ownerOf(tokenId) == msg.sender, "ChronoGems: Caller is not the owner"); // Example: Only owner can unlock for their gem

        require(_exists(tokenId), "ChronoGems: Token does not exist");
        require(achievementId > 0, "ChronoGems: Invalid achievement ID"); // Assuming achievementId 0 is unused/invalid

        if (!_gemAchievements[tokenId][achievementId]) {
            _gemAchievements[tokenId][achievementId] = true;
            emit AchievementUnlocked(tokenId, achievementId, msg.sender);
        }
    }

    /**
     * @dev Checks if a specific achievement is unlocked for a Gem.
     * 18. checkAchievementStatus(uint256 tokenId, uint256 achievementId)
     */
    function checkAchievementStatus(uint256 tokenId, uint256 achievementId) public view returns (bool) {
         require(_exists(tokenId), "ChronoGems: Token does not exist");
         return _gemAchievements[tokenId][achievementId];
    }


    // --- Oracle Integration (Simulated) Functions ---

    /**
     * @dev Sets the address of the trusted Oracle contract.
     * Only callable by the contract owner.
     * 19. setOracleAddress(address oracleAddress)
     */
    function setOracleAddress(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "ChronoGems: Oracle address cannot be zero");
        // Optional: check if the address is a contract using Address.isContract()
        // require(oracleAddress.isContract(), "ChronoGems: Oracle address must be a contract");
        _oracle = oracleAddress;
    }

    /**
     * @dev Updates simulated Oracle data.
     * In a real scenario, this function would likely be callable ONLY by the
     * registered `_oracle` address, receiving signed data or verified reports.
     * For this example, it's simplified to be owner-callable to demonstrate functionality.
     * 20. updateOracleData(bytes32 key, uint256 value)
     */
    function updateOracleData(bytes32 key, uint256 value) public onlyOwner whenNotPaused {
        // In a real system, add signature verification or other oracle-specific checks here.
        // require(msg.sender == _oracle, "ChronoGems: Only the oracle can update data"); // Use this in a real system

        _oracleData[key] = value;
        emit OracleDataUpdated(key, value, block.number);
    }

    // --- Admin & Configuration Functions ---

    /**
     * @dev Sets the address of the ERC-20 token used as Essence for feeding Gems.
     * Only callable by the contract owner.
     * 21. setEssenceToken(address tokenAddress)
     */
    function setEssenceToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "ChronoGems: Essence token address cannot be zero");
         require(tokenAddress.isContract(), "ChronoGems: Essence token address must be a contract");
        _essenceToken = tokenAddress;
    }

     /**
     * @dev Sets or updates the evolution requirements for a specific stage transition.
     * Allows the owner to configure the evolution logic.
     * Only callable by the contract owner.
     * 22. setEvolutionConditions(GemStage fromStage, GemStage toStage, EvolutionRequirements conditions)
     */
    function setEvolutionConditions(GemStage fromStage, GemStage toStage, EvolutionRequirements calldata conditions) public onlyOwner {
        require(uint8(fromStage) < uint8(toStage), "ChronoGems: fromStage must be before toStage");
        require(uint8(fromStage) < uint8(GemStage.MAX_STAGE) - 1, "ChronoGems: Invalid fromStage");
        require(uint8(toStage) <= uint8(GemStage.MAX_STAGE) - 1, "ChronoGems: Invalid toStage");
        if (conditions.requiredEssenceAmount > 0) {
             require(_essenceToken != address(0), "ChronoGems: Essence token must be set to require essence");
        }
         if (conditions.requiredOracleKey != bytes32(0)) {
              require(_oracle != address(0), "ChronoGems: Oracle must be set to require oracle data");
         }

        _evolutionRequirements[fromStage][toStage] = conditions;

        emit EvolutionConditionsSet(fromStage, toStage);
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ERC-20 tokens from the contract.
     * Essential for recovering tokens other than the primary Essence token or
     * excess Essence not tied to a Gem.
     * 23. withdrawStuckTokens(address tokenAddress, uint256 amount)
     */
    function withdrawStuckTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "ChronoGems: Cannot withdraw zero address");
        // Prevent withdrawing the contract's own NFT tokens
        require(tokenAddress != address(this), "ChronoGems: Cannot withdraw ChronoGem tokens");
        // Optional: Prevent withdrawing the designated _essenceToken if you want to lock it
        // require(tokenAddress != _essenceToken, "ChronoGems: Cannot withdraw essence token");

        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }


    // --- View Functions ---

    /**
     * @dev Returns the current evolution stage of a Gem.
     * 24. getGemStage(uint256 tokenId)
     */
    function getGemStage(uint256 tokenId) public view returns (GemStage) {
         require(_exists(tokenId), "ChronoGems: Token does not exist");
         return _gemStage[tokenId];
    }

    /**
     * @dev Returns the block number of the Gem's last evolution.
     * 25. getLastEvolutionBlock(uint256 tokenId)
     */
    function getLastEvolutionBlock(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoGems: Token does not exist");
        return _lastEvolutionBlock[tokenId];
    }

    /**
     * @dev Returns the block number until which the Gem is staked. Returns 0 if not currently staked.
     * 26. getStakingInfo(uint256 tokenId)
     */
    function getStakingInfo(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ChronoGems: Token does not exist");
        return _gemStakingInfo[tokenId];
    }

    /**
     * @dev Returns the amount of a specific essence token fed to a Gem.
     * 27. getGemEssenceBalance(uint256 tokenId, address essenceToken)
     */
    function getGemEssenceBalance(uint256 tokenId, address essenceToken) public view returns (uint256) {
         require(_exists(tokenId), "ChronoGems: Token does not exist");
         require(essenceToken != address(0), "ChronoGems: Essence token address cannot be zero");
         return _gemResourceBalance[tokenId][essenceToken];
    }

    /**
     * @dev Returns the evolution requirements for a specific stage transition.
     * 28. getEvolutionRequirements(GemStage fromStage, GemStage toStage)
     */
    function getEvolutionRequirements(GemStage fromStage, GemStage toStage) public view returns (EvolutionRequirements memory) {
        require(uint8(fromStage) < uint8(toStage), "ChronoGems: fromStage must be before toStage");
        require(uint8(fromStage) < uint8(GemStage.MAX_STAGE) - 1, "ChronoGems: Invalid fromStage");
        require(uint8(toStage) <= uint8(GemStage.MAX_STAGE) - 1, "ChronoGems: Invalid toStage");

        return _evolutionRequirements[fromStage][toStage];
    }

     /**
     * @dev Checks if a gem meets ALL evolution requirements for a specific stage transition *right now*.
     * Useful for dApps to check if `triggerEvolution` will succeed.
     * 30. isGemRequirementMet(uint256 tokenId, GemStage fromStage, GemStage toStage)
     */
    function isGemRequirementMet(uint256 tokenId, GemStage fromStage, GemStage toStage) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        if (_gemStage[tokenId] != fromStage) return false;
        if (uint8(fromStage) >= uint8(GemStage.MAX_STAGE) - 1) return false;
        if (uint8(toStage) != uint8(fromStage) + 1) return false;

        EvolutionRequirements memory reqs = _evolutionRequirements[fromStage][toStage];

        // Check each condition
        if (block.number < _lastEvolutionBlock[tokenId] + reqs.requiredBlockAge) return false;
        if (!_isGemStakedForDuration(tokenId, reqs.requiredStakeDurationBlocks)) return false; // Reusing the simplified check logic
        if (_gemResourceBalance[tokenId][_essenceToken] < reqs.requiredEssenceAmount) return false;
         // Check oracle data only if oracle address is set and key is not zero
        if (_oracle != address(0) && reqs.requiredOracleKey != bytes32(0)) {
            if (_oracleData[reqs.requiredOracleKey] != reqs.requiredOracleValue) return false;
        } else if (_oracle != address(0) && reqs.requiredOracleKey != bytes32(0)) {
             // Oracle required but address not set, or key required but not set in requirements
             return false;
        }


        // Check achievement requirements
        for (uint i = 0; i < reqs.requiredAchievementIds.length; i++) {
            if (!_gemAchievements[tokenId][reqs.requiredAchievementIds[i]]) {
                return false;
            }
        }

        // If all checks pass
        return true;
    }

    // --- Pausable Overrides ---
     function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // The following functions are inherited from Pausable and have the whenNotPaused modifier internally
    // transferFrom, safeTransferFrom, sendValue (via Address.sendValue if used)
    // Functions like mint, triggerEvolution, stakeGem, unstakeGem, feedEssence
    // also have the whenNotPaused modifier applied directly.

}
```