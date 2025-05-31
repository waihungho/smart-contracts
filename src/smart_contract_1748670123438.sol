Okay, let's create a smart contract for "Evolving NFT Avatars". This contract will manage NFTs that can gain experience, evolve through stages, battle other avatars, and be staked to earn passive experience. It incorporates dynamic traits, interaction mechanics, and a simple staking concept.

It uses OpenZeppelin libraries for standard ERC721, Ownable, and Pausable features, but the core evolution, battle, and staking logic is custom.

---

# Smart Contract: NFT Avatar Evolver

**Concept:** A dynamic NFT contract where avatars are minted with initial traits, can earn Experience Points (XP) through various actions (feeding, battling, staking), and evolve through different stages when they meet XP thresholds and pay a fee.

**Advanced Concepts:**
1.  **Dynamic Traits:** NFT traits are stored on-chain and can change based on actions (evolution, battling, feeding).
2.  **On-Chain State Changes:** Avatar state (XP, Stage, Traits, Staking Status, Last Action Timestamp) is directly modified by user interactions.
3.  **Interaction Mechanics:** Includes explicit functions for user interaction (`feedAvatar`, `battleAvatar`) that directly impact NFT state.
4.  **Evolution System:** A defined path for NFTs to upgrade based on achieving specific conditions (XP + Fee).
5.  **Staking Mechanism:** Allows users to stake their NFTs to earn passive benefits (XP) over time.
6.  **Cooldowns:** Implements time-based restrictions on certain actions to prevent spamming and balance gameplay/mechanics.
7.  **Conditional State Transitions:** Evolution is gated by XP requirements and fee payment.
8.  **Modular Design (Conceptual):** While one contract, the functions are separated logically (core NFT, evolution, battle, staking, admin).
9.  **Event-Driven State Changes:** Critical actions are logged via events for off-chain monitoring and transparency.
10. **Access Control:** Uses `Ownable` for administrative functions and checks `_isApprovedOrOwner` for token-specific user actions.

**Outline:**

1.  **License & Version**
2.  **Imports:** ERC721, Ownable, Pausable, ReentrancyGuard (optional but good practice).
3.  **Errors:** Custom error types for clearer revert reasons.
4.  **Events:** To log key actions (Mint, Feed, Evolve, Battle, Stake, Unstake, XPClaim).
5.  **Structs:** `AvatarTraits` to define the properties of an avatar.
6.  **State Variables:**
    *   ERC721 related (managed by library).
    *   Owner (managed by library).
    *   Paused state (managed by library).
    *   Internal token counter (`_currentTokenId`).
    *   Mappings for avatar data: `traits`, `xp`, `lastActionTimestamp`, `isStaked`, `stakeStartTime`.
    *   Evolution parameters: `evolutionFee`, `evolutionXPThresholds`.
    *   Cooldown durations: `feedCooldown`, `battleCooldown`.
    *   Staking XP rate: `stakingXPRatePerSecond`.
7.  **Constructor:** Initializes the contract, owner, base URI, and initial parameters.
8.  **ERC721 Overrides:** `tokenURI`.
9.  **View Functions (Getters):** To retrieve avatar data and contract parameters.
10. **User Interaction Functions (whenNotPaused):**
    *   `mintAvatar` (potentially restricted initially).
    *   `feedAvatar`.
    *   `battleAvatar`.
    *   `isEvolutionReady`.
    *   `evolveAvatar` (payable).
    *   `stakeAvatar`.
    *   `unstakeAvatar`.
    *   `claimStakingXP`.
11. **Owner-Only Admin Functions (onlyOwner):**
    *   `setBaseURI`.
    *   `setEvolutionFee`.
    *   `setFeedCooldown`.
    *   `setBattleCooldown`.
    *   `setStakingXPRate`.
    *   `addEvolutionXPThreshold`.
    *   `removeEvolutionXPThreshold`.
    *   `withdrawFees`.
    *   `pauseContract`.
    *   `unpauseContract`.
    *   `burnAvatar`.
    *   `safeMint` (internal helper, exposed via `mintAvatar`).

**Function Summary:**

1.  `constructor(string name, string symbol, string baseURI)`: Initializes the NFT contract with a name, symbol, and base URI. Sets initial owner and parameters.
2.  `tokenURI(uint256 tokenId)`: (Override) Returns the metadata URI for a token, combining the base URI with the token ID.
3.  `_baseURI()`: (Internal) Helper for `tokenURI`.
4.  `setBaseURI(string memory baseURI)`: (Owner) Sets the base part of the metadata URI.
5.  `mintAvatar(address recipient)`: (Owner) Mints a new avatar NFT, assigning initial random-like traits, 0 XP, and stage 1.
6.  `burnAvatar(uint256 tokenId)`: (Owner) Destroys an avatar NFT.
7.  `getTokenTraits(uint256 tokenId)`: (View) Returns the `AvatarTraits` struct for a specific token ID.
8.  `getTokenXP(uint256 tokenId)`: (View) Returns the current XP for a specific token ID.
9.  `getTokenEvolutionStage(uint256 tokenId)`: (View) Returns the current evolution stage for a specific token ID.
10. `getLastActionTimestamp(uint256 tokenId)`: (View) Returns the timestamp of the last major action (feed, battle) for a token.
11. `getEvolutionXPThreshold(uint256 stage)`: (View) Returns the XP needed to reach a specific stage.
12. `isStaked(uint256 tokenId)`: (View) Checks if an avatar is currently staked.
13. `getStakeStartTime(uint256 tokenId)`: (View) Returns the timestamp when an avatar was staked.
14. `calculatePendingStakingXP(uint256 tokenId)`: (View) Calculates how much staking XP an avatar has accrued since last claim/stake.
15. `feedAvatar(uint256 tokenId)`: (User) Allows the token owner/approved to "feed" their avatar, granting a small amount of XP if the cooldown has passed.
16. `battleAvatar(uint256 tokenId1, uint256 tokenId2)`: (User) Allows owner/approved of `tokenId1` to initiate a battle with `tokenId2` (which must be approved for battle to the contract). Simulates outcome based on traits/XP, awards XP, applies cooldowns.
17. `isEvolutionReady(uint256 tokenId)`: (View) Checks if an avatar meets the XP requirement to evolve to the next stage.
18. `evolveAvatar(uint256 tokenId)`: (User, Payable) Allows the token owner/approved to evolve their avatar to the next stage if ready, by paying the evolution fee. Updates traits and stage.
19. `stakeAvatar(uint256 tokenId)`: (User) Allows the token owner/approved to stake their avatar, marking it as staked and starting the XP accrual timer.
20. `unstakeAvatar(uint256 tokenId)`: (User) Allows the token owner to unstake their avatar. Claims any pending staking XP and stops the accrual timer.
21. `claimStakingXP(uint256 tokenId)`: (User) Allows the token owner to claim accrued staking XP without unstaking.
22. `setEvolutionFee(uint256 fee)`: (Owner) Sets the Ether fee required for evolution.
23. `setFeedCooldown(uint256 duration)`: (Owner) Sets the cooldown duration for feeding.
24. `setBattleCooldown(uint256 duration)`: (Owner) Sets the cooldown duration for battling.
25. `setStakingXPRate(uint256 ratePerSecond)`: (Owner) Sets the rate at which staked avatars earn XP per second.
26. `addEvolutionXPThreshold(uint256 stage, uint256 xpNeeded)`: (Owner) Sets or updates the XP required to reach a specific evolution stage.
27. `removeEvolutionXPThreshold(uint256 stage)`: (Owner) Removes an evolution XP threshold entry.
28. `withdrawFees()`: (Owner) Allows the contract owner to withdraw accumulated Ether fees from evolutions.
29. `pause()`: (Owner) Pauses contract interactions (`whenNotPaused` functions).
30. `unpause()`: (Owner) Unpauses contract interactions.

*(Note: Functions like `transferFrom`, `approve`, etc., are inherited from ERC721 and not explicitly listed here, but contribute to the total function count of the deployed contract interface).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice for arithmetic

// Custom Errors
error NFTAvatarEvolver__OnlyOwnerOrApproved(uint256 tokenId);
error NFTAvatarEvolver__InsufficientXPForEvolution(uint256 tokenId, uint256 currentXP, uint256 requiredXP);
error NFTAvatarEvolver__EvolutionFeeNotMet(uint256 requiredFee);
error NFTAvatarEvolver__CooldownNotPassed(uint256 timeLeft);
error NFTAvatarEvolver__InvalidBattleParticipants(uint256 tokenId1, uint256 tokenId2);
error NFTAvatarEvolver__BattleApprovalMissing(uint256 tokenId);
error NFTAvatarEvolver__AvatarAlreadyStaked(uint256 tokenId);
error NFTAvatarEvolver__AvatarNotStaked(uint256 tokenId);
error NFTAvatarEvolver__NoXPToClaim(uint256 tokenId);
error NFTAvatarEvolver__EvolutionStageNotFound(uint256 stage);

contract NFTAvatarEvolver is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _currentTokenId;

    struct AvatarTraits {
        uint8 stage; // Evolution Stage (e.g., 1, 2, 3)
        uint16 strength;
        uint16 intelligence;
        uint16 stamina;
        uint16 charisma;
        uint16 affinity; // Elemental or type affinity
    }

    mapping(uint256 => AvatarTraits) public traits;
    mapping(uint256 => uint256) public xp;
    mapping(uint256 => uint256) public lastActionTimestamp; // Cooldown for actions like feed/battle
    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => uint256) public stakeStartTime; // Timestamp when staking started/last claimed

    uint256 public evolutionFee; // Ether required to evolve
    mapping(uint256 => uint256) public evolutionXPThresholds; // Stage => XP needed to reach this stage

    uint256 public feedCooldown = 1 days; // Time between feeding actions
    uint256 public battleCooldown = 1 hours; // Time between battling or being battled
    uint256 public stakingXPRatePerSecond = 1; // XP gained per second while staked (can be adjusted)
    uint256 private constant INITIAL_XP_GAIN_FEED = 10;
    uint256 private constant BASE_BATTLE_XP_WIN = 50;
    uint256 private constant BASE_BATTLE_XP_LOSS = 10;

    // --- Events ---
    event AvatarMinted(uint256 indexed tokenId, address indexed owner, AvatarTraits initialTraits);
    event AvatarFed(uint256 indexed tokenId, uint256 newXP);
    event AvatarBattled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 winnerTokenId, uint256 winnerXPChange, uint256 loserXPChange);
    event AvatarEvolutionReady(uint256 indexed tokenId, uint256 currentXP, uint256 requiredXP);
    event AvatarEvolved(uint256 indexed tokenId, uint8 oldStage, uint8 newStage, AvatarTraits newTraits, uint256 xpSpent, uint256 evolutionFeePaid);
    event AvatarStaked(uint256 indexed tokenId);
    event AvatarUnstaked(uint256 indexed tokenId, uint256 xpClaimed);
    event StakingXPClaimed(uint256 indexed tokenId, uint256 xpClaimed);
    event EvolutionFeeSet(uint256 newFee);
    event CooldownsSet(uint256 newFeedCooldown, uint256 newBattleCooldown);
    event StakingRateSet(uint256 newRatePerSecond);
    event EvolutionThresholdSet(uint256 stage, uint256 xpNeeded);
    event EvolutionThresholdRemoved(uint256 stage);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event AvatarBurned(uint256 indexed tokenId);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        ERC721URIStorage()
        Ownable(msg.sender)
        Pausable()
    {
        _setBaseURI(baseURI);
        evolutionFee = 0.01 ether; // Example initial fee
        stakingXPRatePerSecond = 1; // Example initial rate
        feedCooldown = 1 days;
        battleCooldown = 1 hours;

        // Example initial evolution thresholds:
        // Stage 1 -> 2 requires 100 XP
        // Stage 2 -> 3 requires 500 XP
        // Stage 3 -> 4 requires 2000 XP
        evolutionXPThresholds[2] = 100;
        evolutionXPThresholds[3] = 500;
        evolutionXPThresholds[4] = 2000;
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // You could potentially build a dynamic URI based on traits here
        // For simplicity, we'll just use the standard ERC721URIStorage implementation
        // which typically combines _baseURI() and _tokenURIs[tokenId] (if set)
        // If traits affect URI, you'd override _baseURI or store full URIs per token.
        // Let's stick to the simple baseURI + token ID for this example.
         return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        // Override to use the base URI stored by ERC721URIStorage
        return super._baseURI();
    }

    // --- Internal Helpers ---

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _generateInitialTraits() internal pure returns (AvatarTraits memory) {
        // Simple "random-like" generation based on block hash and timestamp
        // Not truly random, but sufficient for an example. Use Chainlink VRF for real randomness.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _currentTokenId.current())));
        return AvatarTraits({
            stage: 1,
            strength: uint16(seed % 10 + 5), // 5-14
            intelligence: uint16((seed >> 8) % 10 + 5), // 5-14
            stamina: uint16((seed >> 16) % 10 + 5), // 5-14
            charisma: uint16((seed >> 24) % 10 + 5), // 5-14
            affinity: uint16((seed >> 32) % 6) // 0-5 (e.g., Fire, Water, Earth, Air, Light, Dark)
        });
    }

    function _updateTraitsOnEvolution(AvatarTraits memory currentTraits) internal pure returns (AvatarTraits memory) {
        // Example: Traits increase upon evolution
        currentTraits.stage++;
        currentTraits.strength = uint16(currentTraits.strength * 1.5); // Example scaling
        currentTraits.intelligence = uint16(currentTraits.intelligence * 1.5);
        currentTraits.stamina = uint16(currentTraits.stamina * 1.5);
        currentTraits.charisma = uint16(currentTraits.charisma * 1.2); // Some scale more than others
        // Affinity might change or strengthen depending on stage/XP distribution
        // For simplicity, let's just boost primary stats here.
        return currentTraits;
    }

     function _calculateBattleOutcome(uint256 tokenId1, AvatarTraits memory traits1, uint256 xp1, uint256 tokenId2, AvatarTraits memory traits2, uint256 xp2)
        internal
        pure
        returns (uint256 winnerTokenId, uint256 winnerXPChange, uint256 loserXPChange)
    {
        // Simple battle logic: based on Strength + a portion of XP
        uint256 power1 = uint256(traits1.strength).add(xp1.div(10));
        uint256 power2 = uint256(traits2.strength).add(xp2.div(10));

        if (power1 > power2) {
            return (tokenId1, BASE_BATTLE_XP_WIN, BASE_BATTLE_XP_LOSS);
        } else if (power2 > power1) {
            return (tokenId2, BASE_BATTLE_XP_WIN, BASE_BATTLE_XP_LOSS);
        } else {
            // Draw: slight XP gain for both
            return (0, BASE_BATTLE_XP_LOSS.div(2), BASE_BATTLE_XP_LOSS.div(2)); // 0 signifies a draw
        }
    }


    // --- User Interaction Functions (whenNotPaused) ---

    /// @notice Mints a new avatar NFT and assigns it to the recipient. Can be restricted by owner.
    /// @param recipient The address to receive the new avatar.
    function mintAvatar(address recipient) public onlyOwner whenNotPaused {
        _currentTokenId.increment();
        uint256 newTokenId = _currentTokenId.current();

        _safeMint(recipient, newTokenId);

        // Assign initial traits and XP
        AvatarTraits memory initialTraits = _generateInitialTraits();
        traits[newTokenId] = initialTraits;
        xp[newTokenId] = 0;
        lastActionTimestamp[newTokenId] = block.timestamp; // Set initial cooldown

        emit AvatarMinted(newTokenId, recipient, initialTraits);
    }

    /// @notice Allows the owner or approved user to "feed" their avatar to gain XP. Subject to cooldown.
    /// @param tokenId The ID of the avatar to feed.
    function feedAvatar(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId));

        uint256 timeElapsed = block.timestamp.sub(lastActionTimestamp[tokenId]);
        require(timeElapsed >= feedCooldown, NFTAvatarEvolver__CooldownNotPassed(feedCooldown.sub(timeElapsed)));

        uint256 xpGained = INITIAL_XP_GAIN_FEED; // Could be dynamic based on traits/stage

        xp[tokenId] = xp[tokenId].add(xpGained);
        lastActionTimestamp[tokenId] = block.timestamp; // Reset cooldown

        emit AvatarFed(tokenId, xp[tokenId]);

        // Check if evolution is ready after gaining XP
        if (isEvolutionReady(tokenId)) {
             emit AvatarEvolutionReady(tokenId, xp[tokenId], evolutionXPThresholds[traits[tokenId].stage + 1]);
        }
    }

     /// @notice Initiates a battle between two avatars.
     /// @dev The caller must own or be approved for tokenId1. tokenId2 must be approved to the contract address for battling.
     /// @param tokenId1 The ID of the attacking avatar.
     /// @param tokenId2 The ID of the defending avatar.
    function battleAvatar(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(tokenId1 != tokenId2, NFTAvatarEvolver__InvalidBattleParticipants(tokenId1, tokenId2));
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");

        require(_isApprovedOrOwner(msg.sender, tokenId1), NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId1));
        // Require tokenId2 to be approved specifically to *this contract* for battling
        require(getApproved(tokenId2) == address(this) || isApprovedForAll(ownerOf(tokenId2), address(this)), NFTAvatarEvolver__BattleApprovalMissing(tokenId2));

        // Check cooldowns for both participants
        uint256 timeElapsed1 = block.timestamp.sub(lastActionTimestamp[tokenId1]);
        require(timeElapsed1 >= battleCooldown, NFTAvatarEvolver__CooldownNotPassed(battleCooldown.sub(timeElapsed1)));

        uint256 timeElapsed2 = block.timestamp.sub(lastActionTimestamp[tokenId2]);
        require(timeElapsed2 >= battleCooldown, NFTAvatarEvolver__CooldownNotPassed(battleCooldown.sub(timeElapsed2)));

        // Simulate battle outcome
        (uint256 winnerTokenId, uint256 winnerXPChange, uint256 loserXPChange) = _calculateBattleOutcome(
            tokenId1, traits[tokenId1], xp[tokenId1],
            tokenId2, traits[tokenId2], xp[tokenId2]
        );

        // Update XP and cooldowns
        if (winnerTokenId == tokenId1) {
            xp[tokenId1] = xp[tokenId1].add(winnerXPChange);
            xp[tokenId2] = xp[tokenId2].add(loserXPChange);
        } else if (winnerTokenId == tokenId2) {
            xp[tokenId1] = xp[tokenId1].add(loserXPChange);
            xp[tokenId2] = xp[tokenId2].add(winnerXPChange);
        } else { // Draw
             xp[tokenId1] = xp[tokenId1].add(winnerXPChange); // winnerXPChange is draw XP here
             xp[tokenId2] = xp[tokenId2].add(loserXPChange); // loserXPChange is draw XP here
        }

        lastActionTimestamp[tokenId1] = block.timestamp;
        lastActionTimestamp[tokenId2] = block.timestamp;

        emit AvatarBattled(tokenId1, tokenId2, winnerTokenId, winnerXPChange, loserXPChange);

         // Check if evolution is ready after gaining XP
        if (isEvolutionReady(tokenId1)) {
             emit AvatarEvolutionReady(tokenId1, xp[tokenId1], evolutionXPThresholds[traits[tokenId1].stage + 1]);
        }
         if (isEvolutionReady(tokenId2)) {
             emit AvatarEvolutionReady(tokenId2, xp[tokenId2], evolutionXPThresholds[traits[tokenId2].stage + 1]);
        }
    }


    /// @notice Checks if an avatar meets the criteria to evolve to the next stage.
    /// @param tokenId The ID of the avatar to check.
    /// @return bool True if the avatar is ready to evolve, false otherwise.
    function isEvolutionReady(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) return false;
         uint8 currentStage = traits[tokenId].stage;
         uint256 requiredXP = evolutionXPThresholds[currentStage + 1];

         // If no threshold is set for the next stage, it means it cannot evolve further
         if (requiredXP == 0) return false;

         return xp[tokenId] >= requiredXP;
    }

    /// @notice Allows the owner or approved user to evolve their avatar to the next stage.
    /// @dev Requires the avatar to be ready for evolution (meets XP threshold) and payment of the evolution fee.
    /// @param tokenId The ID of the avatar to evolve.
    function evolveAvatar(uint256 tokenId) public payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId));
        require(isEvolutionReady(tokenId), NFTAvatarEvolver__InsufficientXPForEvolution(tokenId, xp[tokenId], evolutionXPThresholds[traits[tokenId].stage + 1]));
        require(msg.value >= evolutionFee, NFTAvatarEvolver__EvolutionFeeNotMet(evolutionFee));

        uint8 oldStage = traits[tokenId].stage;
        uint256 xpNeeded = evolutionXPThresholds[oldStage + 1];

        // Spend XP (optional, could just be a threshold) - let's reduce XP by the threshold amount
        xp[tokenId] = xp[tokenId].sub(xpNeeded);

        // Update traits for the new stage
        traits[tokenId] = _updateTraitsOnEvolution(traits[tokenId]);
        AvatarTraits memory newTraits = traits[tokenId]; // Get the updated traits struct

        lastActionTimestamp[tokenId] = block.timestamp; // Optional: Apply cooldown after evolution

        // Fee is automatically sent to the contract balance due to payable

        emit AvatarEvolved(tokenId, oldStage, newTraits.stage, newTraits, xpNeeded, msg.value);
    }

    /// @notice Allows the owner or approved user to stake their avatar.
    /// @dev Staked avatars passively earn XP. Ownership is retained, but status is marked.
    /// @param tokenId The ID of the avatar to stake.
    function stakeAvatar(uint256 tokenId) public whenNotPaused {
         require(_isApprovedOrOwner(msg.sender, tokenId), NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId));
         require(!isStaked[tokenId], NFTAvatarEvolver__AvatarAlreadyStaked(tokenId));

         isStaked[tokenId] = true;
         stakeStartTime[tokenId] = block.timestamp; // Record start time for XP calculation

         emit AvatarStaked(tokenId);
    }

    /// @notice Allows the owner to unstake their avatar and claim accrued XP.
    /// @param tokenId The ID of the avatar to unstake.
    function unstakeAvatar(uint256 tokenId) public whenNotPaused {
         // Note: Requires the msg.sender to be the *current* owner
         // If ownership was transferred while staked, only the new owner can unstake.
         require(ownerOf(tokenId) == msg.sender, NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId)); // Use ownerOf for staking control
         require(isStaked[tokenId], NFTAvatarEvolver__AvatarNotStaked(tokenId));

         uint256 pendingXP = calculatePendingStakingXP(tokenId);
         isStaked[tokenId] = false;
         stakeStartTime[tokenId] = 0; // Reset stake time

         if (pendingXP > 0) {
             xp[tokenId] = xp[tokenId].add(pendingXP);
             emit StakingXPClaimed(tokenId, pendingXP); // Also emit claim event
         }

         emit AvatarUnstaked(tokenId, pendingXP);
    }

     /// @notice Allows the owner to claim accrued staking XP without unstaking.
     /// @param tokenId The ID of the avatar to claim XP for.
    function claimStakingXP(uint256 tokenId) public whenNotPaused {
         require(ownerOf(tokenId) == msg.sender, NFTAvatarEvolver__OnlyOwnerOrApproved(tokenId)); // Use ownerOf for staking control
         require(isStaked[tokenId], NFTAvatarEvolver__AvatarNotStaked(tokenId));

         uint256 pendingXP = calculatePendingStakingXP(tokenId);
         require(pendingXP > 0, NFTAvatarEvolver__NoXPToClaim(tokenId));

         xp[tokenId] = xp[tokenId].add(pendingXP);
         stakeStartTime[tokenId] = block.timestamp; // Reset stake time to now for calculation

         emit StakingXPClaimed(tokenId, pendingXP);
    }

     /// @notice Calculates the amount of staking XP an avatar has earned since it was staked or last claimed.
     /// @param tokenId The ID of the avatar.
     /// @return uint256 The pending staking XP.
    function calculatePendingStakingXP(uint256 tokenId) public view returns (uint256) {
        if (!isStaked[tokenId] || stakeStartTime[tokenId] == 0) {
            return 0;
        }
        uint256 duration = block.timestamp.sub(stakeStartTime[tokenId]);
        return duration.mul(stakingXPRatePerSecond);
    }


    // --- View Functions (Getters) ---

    /// @notice Returns the traits of a specific avatar.
    /// @param tokenId The ID of the avatar.
    /// @return AvatarTraits The traits struct.
    function getTokenTraits(uint256 tokenId) public view returns (AvatarTraits memory) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         return traits[tokenId];
    }

    /// @notice Returns the current experience points (XP) of a specific avatar.
    /// @param tokenId The ID of the avatar.
    /// @return uint256 The current XP.
    function getTokenXP(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return xp[tokenId];
    }

    /// @notice Returns the current evolution stage of a specific avatar.
    /// @param tokenId The ID of the avatar.
    /// @return uint8 The current stage.
    function getTokenEvolutionStage(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         return traits[tokenId].stage;
    }

    /// @notice Returns the timestamp of the last major action (feed, battle) for an avatar.
    /// @param tokenId The ID of the avatar.
    /// @return uint256 The timestamp.
    function getLastActionTimestamp(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return lastActionTimestamp[tokenId];
    }

    /// @notice Returns the XP required to reach a specific evolution stage.
    /// @param stage The target stage.
    /// @return uint256 The required XP. Returns 0 if no threshold is set for that stage.
    function getEvolutionXPThreshold(uint256 stage) public view returns (uint256) {
        return evolutionXPThresholds[stage];
    }

    /// @notice Checks if an avatar is currently staked.
    /// @param tokenId The ID of the avatar.
    /// @return bool True if staked, false otherwise.
    function isStaked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return isStaked[tokenId];
    }

     /// @notice Returns the timestamp when an avatar was staked or last claimed staking XP.
     /// @param tokenId The ID of the avatar.
     /// @return uint256 The timestamp.
    function getStakeStartTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return stakeStartTime[tokenId];
    }


    // --- Owner-Only Admin Functions (onlyOwner) ---

    /// @notice Sets the base part of the metadata URI.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Sets the Ether fee required for evolution.
    /// @param fee The new evolution fee in Wei.
    function setEvolutionFee(uint256 fee) public onlyOwner {
        evolutionFee = fee;
        emit EvolutionFeeSet(fee);
    }

    /// @notice Sets the cooldown duration for the `feedAvatar` function.
    /// @param duration The new cooldown duration in seconds.
    function setFeedCooldown(uint256 duration) public onlyOwner {
        feedCooldown = duration;
        emit CooldownsSet(feedCooldown, battleCooldown);
    }

     /// @notice Sets the cooldown duration for the `battleAvatar` function.
     /// @param duration The new cooldown duration in seconds.
    function setBattleCooldown(uint256 duration) public onlyOwner {
        battleCooldown = duration;
        emit CooldownsSet(feedCooldown, battleCooldown);
    }

     /// @notice Sets the rate at which staked avatars earn XP per second.
     /// @param ratePerSecond The new rate.
    function setStakingXPRate(uint256 ratePerSecond) public onlyOwner {
        stakingXPRatePerSecond = ratePerSecond;
        emit StakingRateSet(ratePerSecond);
    }


    /// @notice Sets or updates the XP required to reach a specific evolution stage.
    /// @param stage The evolution stage number (e.g., 2 for Stage 1 -> Stage 2).
    /// @param xpNeeded The required XP threshold to reach this stage.
    function addEvolutionXPThreshold(uint256 stage, uint256 xpNeeded) public onlyOwner {
        require(stage > 1, "Stage must be greater than 1"); // Cannot set threshold for stage 1
        evolutionXPThresholds[stage] = xpNeeded;
        emit EvolutionThresholdSet(stage, xpNeeded);
    }

     /// @notice Removes an evolution XP threshold entry.
     /// @param stage The evolution stage number.
    function removeEvolutionXPThreshold(uint256 stage) public onlyOwner {
        require(stage > 1, "Stage must be greater than 1");
         require(evolutionXPThresholds[stage] > 0, EvolutionStageNotFound(stage));
        delete evolutionXPThresholds[stage];
        emit EvolutionThresholdRemoved(stage);
    }

    /// @notice Allows the contract owner to withdraw accumulated Ether fees from evolutions.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    /// @notice Pauses the contract, preventing execution of functions with the `whenNotPaused` modifier.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing execution of functions with the `whenNotPaused` modifier.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the contract owner to burn an avatar NFT.
    /// @dev Use with caution, this permanently destroys the NFT.
    /// @param tokenId The ID of the avatar to burn.
    function burnAvatar(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ERC721: burn of nonexistent token");
         // Additional checks can be added, e.g., cannot burn if staked
         require(!isStaked[tokenId], "Cannot burn staked avatar");
        _burn(tokenId);
        emit AvatarBurned(tokenId);
    }


    // --- Overrides for Pausable ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Add a check to prevent transfers while staked, unless it's to/from address(0) (mint/burn)
        if (from != address(0) && to != address(0)) {
             require(!isStaked[tokenId], "Cannot transfer staked avatar");
        }
    }

    // Function count check:
    // ERC721 standard provides ~10 external/public functions (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom x2, tokenURI)
    // ERC721URIStorage adds _setTokenURI and overrides tokenURI + _baseURI
    // Ownable adds owner() and renounceOwnership(), onlyOwnable modifier
    // Pausable adds paused(), pause(), unpause(), whenNotPaused/whenPaused modifiers
    // Custom:
    // constructor, mintAvatar, burnAvatar, getTokenTraits, getTokenXP, getTokenEvolutionStage, getLastActionTimestamp,
    // getEvolutionXPThreshold, isStaked (public view override), getStakeStartTime, calculatePendingStakingXP,
    // feedAvatar, battleAvatar, isEvolutionReady, evolveAvatar, stakeAvatar, unstakeAvatar, claimStakingXP,
    // setBaseURI, setEvolutionFee, setFeedCooldown, setBattleCooldown, setStakingXPRate, addEvolutionXPThreshold,
    // removeEvolutionXPThreshold, withdrawFees, pauseContract, unpauseContract.
    // This list exceeds 20 public/external functions provided by the contract interface.
}
```