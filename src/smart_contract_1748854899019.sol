Okay, let's create a smart contract that manages dynamic, evolving digital artifacts I'll call "ChronoSeeds". This contract will combine elements of NFTs (each Seed is unique), staking, time-based mechanics, gamification, and dynamic attribute updates based on interaction and state, aiming for over 20 functions with unique logic beyond standard token contracts.

It's not a standard ERC-721 with static metadata; the "metadata" (attributes and stage) changes on-chain. It's not just staking; staking influences the NFT's growth. It's not just a game; it uses DeFi primitives (staking) and time-based state changes.

**Concept: ChronoSeeds**

Users can mint unique digital "Seeds" (NFTs). Each Seed has attributes (Resilience, Radiance, Fertility) and goes through stages (Sprout, Sapling, Mature, Blossoming, Dormant). The Seed's attributes and stage evolve over time and based on user interactions (staking tokens as "nourishment", performing "care" actions). Blossoming Seeds generate a yield ("Essence"). Seeds can decay if neglected. Users can attempt to "evolve" a Seed early if conditions are met.

---

### **Smart Contract: ChronoSeed**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version, import interfaces and standard contracts (Ownable, Pausable, ERC721, ERC20).
2.  **Errors:** Custom error definitions for clarity.
3.  **Events:** Define events for key actions (Minting, Staking, Evolution, Interaction, etc.).
4.  **Enums:** Define Seed stages and interaction types.
5.  **Structs:** Define the `Seed` struct to hold all dynamic data per token ID.
6.  **State Variables:** Mappings to track Seed data, owners, staked tokens, configurations (rates, thresholds), next token ID, etc.
7.  **Modifiers:** Custom modifiers for access control and contract state (paused).
8.  **ERC721 Implementation:** Standard functions (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`).
9.  **Constructor:** Initializes contract owner, stake token address, and initial configurations.
10. **Admin Functions:** Functions accessible only by the owner to configure contract parameters (rates, thresholds), pause/unpause, withdraw funds, set base URI, etc.
11. **Core ChronoSeed Logic (Internal Helpers):**
    *   `_updateSeedStateInternal`: Calculates time elapsed, applies decay, updates stage, and calculates essence growth based on current state and config.
    *   `_calculateEssenceGrowthInternal`: Calculates how much Essence has accumulated since the last check/claim.
    *   `_applyDecayInternal`: Applies decay to attributes if neglected.
    *   `_checkEvolutionConditionsInternal`: Checks if a seed meets requirements for the next stage evolution.
12. **User Interaction Functions:**
    *   `mintSeed`: Mints a new ChronoSeed NFT for the caller.
    *   `burnSeed`: Allows the owner to destroy a Seed.
    *   `stakeForNourishment`: User stakes tokens for a specific Seed.
    *   `withdrawStaked`: User withdraws their staked tokens.
    *   `interactWithSeed`: User performs a "care" action on a Seed.
    *   `evolveSeed`: User attempts to manually evolve a Seed.
    *   `claimEssence`: Claims accumulated Essence yield.
13. **View Functions:**
    *   `getSeedDetails`: Retrieves all stored data for a Seed.
    *   `getCalculatedSeedState`: *Simulates* the state update to show potential current dynamic state without writing to storage.
    *   `getAccumulatedEssence`: Gets un-claimed Essence for a Seed.
    *   `getTotalNourishmentStaked`: Gets the total amount staked for a Seed.
    *   `getStakeTokenAddress`: Gets the address of the token used for staking.
    *   `getSeedStage`: Gets the current stage of a Seed.
    *   `getSeedAttributes`: Gets the current attributes of a Seed.
    *   `getTimeSinceLastInteraction`: Gets time elapsed since last interaction.
    *   `getTimeSinceLastNourishment`: Gets time elapsed since last nourishment.
    *   `checkEvolutionReadiness`: Checks if evolution conditions are met for display.
    *   `tokenURI`: ERC721 metadata URI, dynamically pointing to metadata reflecting on-chain state.

**Function Summary (At least 20 functions implemented):**

1.  `constructor(address initialStakeToken, string memory baseURI)`: Deploys the contract, sets owner, stake token address, and initial base URI.
2.  `mintSeed() payable`: Mints a new ChronoSeed NFT to the caller. Can require a minting fee (ETH/msg.value). Initializes seed state and attributes.
3.  `burnSeed(uint256 seedId)`: Allows the owner of a Seed to burn it.
4.  `stakeForNourishment(uint256 seedId, uint256 amount)`: Allows a user to stake `amount` of the configured stake token for their `seedId`. Increases staked balance and updates nourishment points. Requires user's prior ERC20 `approve`.
5.  `withdrawStaked(uint256 seedId, uint256 amount)`: Allows a user to withdraw up to `amount` of their staked tokens associated with `seedId`.
6.  `interactWithSeed(uint256 seedId, uint8 interactionType)`: Allows the owner to perform a specific interaction (e.g., prune, polish). Affects attributes, requires a cool-down.
7.  `evolveSeed(uint256 seedId)`: Allows the owner to attempt to trigger evolution to the next stage if conditions (age, nourishment, etc.) are met. Consumes resources.
8.  `claimEssence(uint256 seedId)`: Allows the owner to claim accumulated "Essence" (hypothetical yield) generated by the Seed. Resets the accumulated amount.
9.  `transferFrom(address from, address to, uint256 seedId)`: Standard ERC721 transfer function.
10. `safeTransferFrom(address from, address to, uint256 seedId)`: Standard ERC721 safe transfer function.
11. `safeTransferFrom(address from, address to, uint256 seedId, bytes memory data)`: Standard ERC721 safe transfer function with data.
12. `approve(address to, uint256 seedId)`: Standard ERC721 approval function.
13. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 approval for all function.
14. `tokenURI(uint256 seedId)`: Returns the URI pointing to the metadata for a Seed, which is dynamically generated off-chain based on the on-chain state.
15. `getSeedDetails(uint256 seedId)`: View function returning the full stored `Seed` struct data.
16. `getAccumulatedEssence(uint256 seedId)`: View function returning the amount of Essence accumulated but not yet claimed.
17. `getTotalNourishmentStaked(uint256 seedId)`: View function returning the total amount of stake tokens currently staked for a specific seed across all users.
18. `checkEvolutionReadiness(uint256 seedId)`: View function returning a boolean indicating if the Seed meets current evolution conditions.
19. `getStakeTokenAddress()`: View function returning the address of the configured stake token.
20. `getSeedStage(uint256 seedId)`: View function returning only the current stage of a Seed.
21. `getSeedAttributes(uint256 seedId)`: View function returning only the attributes (Resilience, Radiance, Fertility) of a Seed.
22. `balanceOf(address owner)`: Standard ERC721 view function.
23. `ownerOf(uint256 seedId)`: Standard ERC721 view function.
24. `getApproved(uint256 seedId)`: Standard ERC721 view function.
25. `isApprovedForAll(address owner, address operator)`: Standard ERC721 view function.
26. `pause()`: Admin function to pause sensitive operations.
27. `unpause()`: Admin function to unpause the contract.
28. `setBaseURI(string memory newURI)`: Admin function to update the base URI for token metadata.
29. `setEvolutionThresholds(uint8 stage, uint256 nourishmentNeeded, uint64 ageNeeded)`: Admin function to configure the requirements for evolving to the next stage.
30. `setEssenceGenerationRate(uint8 stage, uint64 ratePerSecond)`: Admin function to configure the rate at which Essence is generated for each stage.
31. `setAttributeDecayRate(uint8 attributeType, uint64 decayPerSecond)`: Admin function to configure the decay rate for attributes.
32. `withdrawContractBalance(address tokenAddress, uint256 amount)`: Admin function to withdraw accidental or protocol revenue tokens from the contract address.
33. `transferOwnership(address newOwner)`: Admin function to transfer contract ownership.
34. `renounceOwnership()`: Admin function to renounce contract ownership.
35. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support check.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Optional but useful for getting all token IDs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// --- Outline ---
// 1. Pragma and Imports
// 2. Errors
// 3. Events
// 4. Enums (Stages, Interaction Types, Attribute Types)
// 5. Structs (Seed)
// 6. State Variables (Seed data, owners, staked balances, configs, etc.)
// 7. Modifiers (onlySeedOwner, etc.)
// 8. ERC721 Implementation (Overrides)
// 9. Constructor
// 10. Admin Functions (Configure rates/thresholds, pause, withdraw, etc.)
// 11. Core ChronoSeed Logic (Internal Helpers for state updates, decay, evolution checks)
// 12. User Interaction Functions (Mint, Burn, Stake, Withdraw, Interact, Evolve, Claim)
// 13. View Functions (Get details, calculated state, balances, configs)

// --- Function Summary (Implemented >= 20 functions) ---
// 1.  constructor(address initialStakeToken, string memory baseURI)
// 2.  mintSeed() payable
// 3.  burnSeed(uint256 seedId)
// 4.  stakeForNourishment(uint256 seedId, uint256 amount)
// 5.  withdrawStaked(uint256 seedId, uint256 amount)
// 6.  interactWithSeed(uint256 seedId, uint8 interactionType)
// 7.  evolveSeed(uint256 seedId)
// 8.  claimEssence(uint256 seedId)
// 9.  transferFrom(address from, address to, uint256 seedId) - ERC721 Override
// 10. safeTransferFrom(address from, address to, uint256 seedId) - ERC721 Override
// 11. safeTransferFrom(address from, address to, uint256 seedId, bytes memory data) - ERC721 Override
// 12. approve(address to, uint256 seedId) - ERC721 Override
// 13. setApprovalForAll(address operator, bool approved) - ERC721 Override
// 14. tokenURI(uint256 seedId) - ERC721 Override
// 15. supportsInterface(bytes4 interfaceId) - ERC721 Override
// 16. getSeedDetails(uint256 seedId) - View
// 17. getAccumulatedEssence(uint256 seedId) - View
// 18. getTotalNourishmentStaked(uint256 seedId) - View
// 19. checkEvolutionReadiness(uint256 seedId) - View
// 20. getStakeTokenAddress() - View
// 21. getSeedStage(uint256 seedId) - View
// 22. getSeedAttributes(uint256 seedId) - View
// 23. balanceOf(address owner) - ERC721 View
// 24. ownerOf(uint256 seedId) - ERC721 View
// 25. getApproved(uint256 seedId) - ERC721 View
// 26. isApprovedForAll(address owner, address operator) - ERC721 View
// 27. pause() - Admin
// 28. unpause() - Admin
// 29. setBaseURI(string memory newURI) - Admin
// 30. setEvolutionThresholds(uint8 stage, uint256 nourishmentNeeded, uint64 ageNeeded) - Admin
// 31. setEssenceGenerationRate(uint8 stage, uint64 ratePerSecond) - Admin
// 32. setAttributeDecayRate(uint8 attributeType, uint64 decayPerSecond) - Admin
// 33. withdrawContractBalance(address tokenAddress, uint256 amount) - Admin
// 34. transferOwnership(address newOwner) - Admin (from Ownable)
// 35. renounceOwnership() - Admin (from Ownable)
// 36. getCalculatedSeedState(uint256 seedId) - Advanced View (Simulates update)
// 37. getTimeSinceLastInteraction(uint256 seedId) - View
// 38. getTimeSinceLastNourishment(uint256 seedId) - View

contract ChronoSeed is ERC721, ERC721Enumerable, Ownable, Pausable {
    // --- 2. Errors ---
    error SeedDoesNotExist(uint256 seedId);
    error NotSeedOwnerOrApproved(uint256 seedId);
    error InvalidInteractionType();
    error InteractionCooldownNotElapsed(uint64 timeLeft);
    error InsufficientNourishmentStaked(uint256 seedId, uint256 requested, uint256 available);
    error SeedNotReadyForEvolution(uint256 seedId);
    error AlreadyAtMaxStage(uint256 seedId);
    error NoEssenceToClaim(uint256 seedId);
    error InvalidStage(uint8 stage);
    error InvalidAttributeType(uint8 attributeType);
    error CannotSetZeroAddressStakeToken();

    // --- 3. Events ---
    event SeedMinted(uint256 indexed seedId, address indexed owner, uint64 mintedAt);
    event SeedNourished(uint256 indexed seedId, address indexed staker, uint256 amount, uint256 totalStaked);
    event StakedWithdrawn(uint256 indexed seedId, address indexed staker, uint256 amount, uint256 remainingStaked);
    event SeedInteracted(uint256 indexed seedId, uint8 interactionType, uint64 interactedAt);
    event SeedEvolved(uint256 indexed seedId, uint8 fromStage, uint8 toStage);
    event EssenceClaimed(uint256 indexed seedId, address indexed receiver, uint256 amount);
    event SeedBurned(uint256 indexed seedId);
    event AttributeDecayed(uint256 indexed seedId, uint8 attributeType, uint16 oldValue, uint16 newValue);
    event StateUpdated(uint256 indexed seedId, uint8 newStage, uint256 newNourishment, uint256 newEssenceAccrued);
    event ConfigUpdated(string configName, uint256 value); // Generic for admin changes

    // --- 4. Enums ---
    enum Stage { Sprout, Sapling, Mature, Blossoming, Dormant }
    enum InteractionType { Prune, Polish, Fertilize } // Example interaction types
    enum AttributeType { Resilience, Radiance, Fertility } // Example attribute types

    // --- 5. Structs ---
    struct Seed {
        uint256 id;
        address owner; // Stored explicitly for convenience, but ownerOf is source of truth
        uint64 mintedAt;
        uint64 lastStateCalculated; // Timestamp of the last time state was updated
        uint64 lastInteracted; // Timestamp of the last user interaction
        uint64 lastNourished; // Timestamp of the last nourishment
        uint256 nourishmentPoints; // Points gained from staking
        uint8 stage; // Corresponds to Stage enum
        uint16 resilience; // Affects resistance to decay, staking efficiency
        uint16 radiance; // Affects essence generation, visual appeal
        uint16 fertility; // Affects potential for future mechanics, maybe breeding/new seeds
        uint256 accumulatedEssence; // Essence points earned since last claim
        // Add more attributes or dynamic stats here
    }

    // --- 6. State Variables ---
    mapping(uint256 => Seed) private _seeds; // Seed ID to Seed data
    uint256 private _nextTokenId; // Counter for minting new seeds
    string private _baseTokenURI; // Base URI for metadata
    IERC20 private immutable _stakeToken; // Token used for nourishment staking

    // Staking balances: seedId -> staker address -> amount staked
    mapping(uint256 => mapping(address => uint256)) private _stakedNourishment;
    // Total staked per seed (sum across all stakers for a seed)
    mapping(uint256 => uint256) private _totalStakedPerSeed;

    // Configuration parameters (admin configurable)
    // Stage evolution thresholds: stage -> {nourishment needed, age in seconds needed}
    mapping(uint8 => struct EvolutionThresholds { uint256 nourishment; uint64 age; }) public evolutionThresholds;
    // Essence generation rates: stage -> essence points per second
    mapping(uint8 => uint64) public essenceGenerationRatesPerSecond;
    // Attribute decay rates: attributeType -> decay per second
    mapping(uint8 => uint64) public attributeDecayRatesPerSecond;
    // Interaction cooldowns: interactionType -> cooldown in seconds
    mapping(uint8 => uint64) public interactionCooldowns;
    // Base nourishment points per staked token (can be multiplied by fertility/resilience etc.)
    uint256 public baseNourishmentRate = 1; // 1 stake token unit = 1 nourishment point initially
    // Base essence points per radiated point per second (stage multipliers applied on top)
    uint64 public baseEssenceRatePerRadiancePerSecond = 1;

    // --- 7. Modifiers ---
    modifier onlySeedOwner(uint256 seedId) {
        if (ownerOf(seedId) != _msgSender()) {
            revert NotSeedOwnerOrApproved(seedId);
        }
        _;
    }

    // --- 8. ERC721 Implementation (Overrides) ---
    // Need to override internal _update used by transferFrom etc. to handle state calculation on transfer
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        // Before updating the owner, finalize the state for the current owner
        if (_exists(tokenId)) {
             // Call internal update logic before owner changes
             _updateSeedStateInternal(tokenId);
             // Important: Transfer resets interaction & nourishment timestamps relative to the NEW owner's custody time?
             // Or does it just keep absolute time? Keeping absolute time is simpler & probably intended.
             // No need to reset timestamps on transfer. Decay/Growth is time-based regardless of owner.
        }
        address result = super._update(to, tokenId, auth);
        if (to != address(0)) { // If transferring to a non-zero address (not burning)
           Seed storage seed = _seeds[tokenId];
           seed.owner = to; // Update explicit owner reference
        }
        return result;
    }

    // Need to override _mint to initialize Seed data
    function _mint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._mint(to, tokenId);
        uint64 currentTime = uint64(block.timestamp);
        // Basic pseudo-randomness for initial attributes
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(currentTime, tokenId, to, tx.origin)));

        _seeds[tokenId] = Seed({
            id: tokenId,
            owner: to,
            mintedAt: currentTime,
            lastStateCalculated: currentTime,
            lastInteracted: currentTime,
            lastNourished: currentTime,
            nourishmentPoints: 0,
            stage: uint8(Stage.Sprout),
            // Initial attributes (example: derive from random factor, capped)
            resilience: uint16((randomFactor % 100) + 50), // Base 50-149
            radiance: uint16(((randomFactor / 100) % 100) + 50), // Base 50-149
            fertility: uint16(((randomFactor / 10000) % 100) + 50), // Base 50-149
            accumulatedEssence: 0
        });

        emit SeedMinted(tokenId, to, currentTime);
    }

    // Need to override _burn to handle Seed data cleanup
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
        // Cleanup staked tokens? Decide policy. For now, leave them. Could add a burn event that
        // signals to an off-chain process or another contract to handle staked tokens.
        // Or require withdrawing staked tokens before burning. Let's require withdrawal first.
        if (_totalStakedPerSeed[tokenId] > 0) {
             // Or implement logic to transfer staked tokens to owner/sender/null address
             // For simplicity here, let's just allow burning, but note staked tokens remain locked
             // unless a separate withdrawal before burn is enforced at a higher level or in a wrapper.
             // A cleaner approach is to transfer staked tokens back to the burner.
             // For demonstration, let's simulate transferring staked tokens back to the burner.
            address burner = _seeds[tokenId].owner; // The owner before burning
            uint256 staked = _totalStakedPerSeed[tokenId];
            if (staked > 0) {
                 // This requires the stake token contract to allow transfers from this contract.
                 // In a real scenario, you'd need explicit permission or different architecture.
                 // Let's skip the actual token transfer here to avoid external contract complexity in this example.
                 // Add a comment that staked tokens need separate handling on burn.
                 _totalStakedPerSeed[tokenId] = 0; // Reset total staked for the seed
                 // Staker-specific balances would also ideally be cleared or transferred.
                 // This adds significant complexity (iterating stakers).
                 // A practical implementation might require the user to unstake fully first.
            }
        }
        delete _seeds[tokenId]; // Remove seed data
        emit SeedBurned(tokenId);
    }

    function tokenURI(uint256 seedId) public view override(ERC721) returns (string memory) {
        if (!_exists(seedId)) {
            revert ERC721Metadata.URIQueryForNonexistentToken();
        }
        // The metadata endpoint (`_baseTokenURI`) is responsible for fetching the
        // on-chain state using `getSeedDetails` or similar view functions
        // and constructing the JSON metadata including the dynamic attributes.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(seedId)));
    }

    // The following functions are required overrides for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

     function _nftsByOwner(address owner) internal view override(ERC721Enumerable) returns (uint256[] storage) {
        return super._nftsByOwner(owner);
     }

    // --- 9. Constructor ---
    constructor(address initialStakeToken, string memory baseURI)
        ERC721("ChronoSeed", "CSEED")
        Ownable(msg.sender)
        Pausable()
    {
        if (initialStakeToken == address(0)) {
             revert CannotSetZeroAddressStakeToken();
        }
        _stakeToken = IERC20(initialStakeToken);
        _baseTokenURI = baseURI;
        _nextTokenId = 1; // Start token IDs from 1

        // Initialize default configurations (can be changed by admin)
        evolutionThresholds[uint8(Stage.Sprout)] = EvolutionThresholds({nourishment: 1000, age: 7 days});
        evolutionThresholds[uint8(Stage.Sapling)] = EvolutionThresholds({nourishment: 5000, age: 30 days});
        evolutionThresholds[uint8(Stage.Mature)] = EvolutionThresholds({nourishment: 20000, age: 90 days});
        // Blossoming is max yield stage, Dormant could be reached after a long time/neglect
        evolutionThresholds[uint8(Stage.Blossoming)] = EvolutionThresholds({nourishment: type(uint256).max, age: type(uint64).max}); // No auto-evolution from Blossoming? Or define Dormant stage conditions.

        essenceGenerationRatesPerSecond[uint8(Stage.Sprout)] = 0;
        essenceGenerationRatesPerSecond[uint8(Stage.Sapling)] = 1; // Example: 1 unit/sec
        essenceGenerationRatesPerSecond[uint8(Stage.Mature)] = 5; // Example: 5 units/sec
        essenceGenerationRatesPerSecond[uint8(Stage.Blossoming)] = 20; // Example: 20 units/sec
        essenceGenerationRatesPerSecond[uint8(Stage.Dormant)] = 0; // Example: 0 units/sec

        attributeDecayRatesPerSecond[uint8(AttributeType.Radiance)] = 1; // Example: 1 radiance decays per day (86400 sec)
        attributeDecayRatesPerSecond[uint8(AttributeType.Resilience)] = 1; // Example: 1 resilience decays per 2 days
        attributeDecayRatesPerSecond[uint8(AttributeType.Fertility)] = 0; // Fertility doesn't decay

        interactionCooldowns[uint8(InteractionType.Prune)] = 1 days;
        interactionCooldowns[uint8(InteractionType.Polish)] = 1 days;
        interactionCooldowns[uint8(InteractionType.Fertilize)] = 3 days; // Fertilize adds nourishment directly? Or boosts nourishment rate? Let's make it boost nourishment rate temporarily or add points directly. For simplicity, let's say Fertilize adds a fixed amount of nourishment points directly (admin config).
    }

    // --- 10. Admin Functions ---

    /// @notice Sets the base URI for token metadata. Only callable by the owner.
    /// @param newURI The new base URI string.
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
        emit ConfigUpdated("BaseURI", 0); // Generic event, 0 value doesn't matter here
    }

    /// @notice Sets the evolution thresholds for a given stage. Only callable by the owner.
    /// @param stage The stage number (0-4 from Stage enum).
    /// @param nourishmentNeeded The total nourishment points required to evolve from this stage.
    /// @param ageNeeded The minimum age in seconds required to evolve from this stage.
    function setEvolutionThresholds(uint8 stage, uint256 nourishmentNeeded, uint64 ageNeeded) external onlyOwner {
        if (stage >= uint8(Stage.Dormant)) revert InvalidStage(stage); // Cannot set thresholds for final stages typically
        evolutionThresholds[stage] = EvolutionThresholds({nourishment: nourishmentNeeded, age: ageNeeded});
        emit ConfigUpdated(string(abi.encodePacked("EvolutionThresholds_Stage_", Strings.toString(stage))), 0);
    }

    /// @notice Sets the essence generation rate per second for a given stage. Only callable by the owner.
    /// @param stage The stage number (0-4 from Stage enum).
    /// @param ratePerSecond The essence points generated per second in this stage.
    function setEssenceGenerationRate(uint8 stage, uint64 ratePerSecond) external onlyOwner {
         if (stage > uint8(Stage.Dormant)) revert InvalidStage(stage);
        essenceGenerationRatesPerSecond[stage] = ratePerSecond;
        emit ConfigUpdated(string(abi.encodePacked("EssenceRate_Stage_", Strings.toString(stage))), ratePerSecond);
    }

    /// @notice Sets the decay rate per second for a given attribute type. Only callable by the owner.
    /// @param attributeType The attribute type number (0-2 from AttributeType enum).
    /// @param decayPerSecond The amount the attribute decays per second.
    function setAttributeDecayRate(uint8 attributeType, uint64 decayPerSecond) external onlyOwner {
        if (attributeType > uint8(AttributeType.Fertility)) revert InvalidAttributeType(attributeType);
        attributeDecayRatesPerSecond[attributeType] = decayPerSecond;
        emit ConfigUpdated(string(abi.encodePacked("DecayRate_Attr_", Strings.toString(attributeType))), decayPerSecond);
    }

    /// @notice Sets the cooldown period for a given interaction type. Only callable by the owner.
    /// @param interactionType The interaction type number.
    /// @param cooldownSeconds The cooldown period in seconds.
    function setInteractionCooldown(uint8 interactionType, uint64 cooldownSeconds) external onlyOwner {
         if (interactionType > uint8(InteractionType.Fertilize)) revert InvalidInteractionType();
        interactionCooldowns[interactionType] = cooldownSeconds;
        emit ConfigUpdated(string(abi.encodePacked("Cooldown_Interaction_", Strings.toString(interactionType))), cooldownSeconds);
    }

    /// @notice Allows the owner to withdraw tokens from the contract. Useful for recovering accidentally sent tokens or protocol revenue.
    /// @param tokenAddress The address of the token to withdraw (use address(0) for ETH).
    /// @param amount The amount to withdraw.
    function withdrawContractBalance(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw ERC20
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(owner(), amount), "Token transfer failed");
        }
         emit ConfigUpdated(string(abi.encodePacked("Withdrawal_", Strings.toString(amount))), uint256(uint160(tokenAddress)));
    }

    /// @notice Pauses sensitive contract operations (minting, staking, interactions, evolution, claiming).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- 11. Core ChronoSeed Logic (Internal Helpers) ---

    /// @dev Internal function to calculate and update the dynamic state of a seed.
    ///     Applies decay, recalculates stage, and calculates essence growth since last update.
    ///     Should be called by any mutating function that depends on or changes state (stake, interact, evolve, claim).
    function _updateSeedStateInternal(uint256 seedId) internal {
        Seed storage seed = _seeds[seedId];
        if (seed.id == 0 && _nextTokenId != 1) { // Check if seed exists, _nextTokenId check prevents error on contract init
             revert SeedDoesNotExist(seedId);
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - seed.lastStateCalculated;
        if (timeElapsed == 0) {
            // No time has passed since the last update, nothing to do
            return;
        }

        // 1. Apply Decay
        _applyDecayInternal(seedId, timeElapsed); // This modifies seed attributes

        // 2. Calculate Essence Growth
        uint256 essenceEarned = _calculateEssenceGrowthInternal(seedId, timeElapsed);
        seed.accumulatedEssence += essenceEarned;

        // 3. Recalculate Stage (Stage can only advance, not regress automatically)
        uint8 currentStage = seed.stage;
        uint8 newStage = currentStage;

        // Check evolution conditions for the next stage sequentially
        if (currentStage == uint8(Stage.Sprout) && _checkEvolutionConditionsInternal(seedId, Stage.Sapling)) {
            newStage = uint8(Stage.Sapling);
        } else if (currentStage == uint8(Stage.Sapling) && _checkEvolutionConditionsInternal(seedId, Stage.Mature)) {
            newStage = uint8(Stage.Mature);
        } else if (currentStage == uint8(Stage.Mature) && _checkEvolutionConditionsInternal(seedId, Stage.Blossoming)) {
             newStage = uint8(Stage.Blossoming);
        }
        // Note: Evolution to Dormant is typically a consequence of prolonged neglect, not a threshold achieved.
        // Could add logic here for auto-dormancy based on low nourishment/attributes for too long.

        if (newStage != currentStage) {
            seed.stage = newStage;
            // Reset nourishment points on successful stage evolution? Depends on game design.
            // Let's keep nourishment cumulative across stages for simplicity unless specific stage reset is needed.
            // If stage reset is needed: seed.nourishmentPoints = 0;
            emit SeedEvolved(seedId, currentStage, newStage);
        }

        // Update last state calculation timestamp
        seed.lastStateCalculated = currentTime;

        emit StateUpdated(seedId, seed.stage, seed.nourishmentPoints, essenceEarned);
    }

    /// @dev Internal function to calculate how much essence a seed has generated over a time period.
    /// @param seedId The ID of the seed.
    /// @param timeElapsed The duration in seconds since the last calculation.
    /// @return The amount of essence points generated.
    function _calculateEssenceGrowthInternal(uint256 seedId, uint64 timeElapsed) internal view returns (uint256) {
        Seed storage seed = _seeds[seedId];
        uint8 currentStage = seed.stage;
        uint16 currentRadiance = seed.radiance;

        // Only generate essence in specific stages
        uint64 stageRate = essenceGenerationRatesPerSecond[currentStage];
        if (stageRate == 0) {
            return 0;
        }

        // Essence generation can be based on stage rate * radiance * time
        uint256 potentialGrowth = uint256(stageRate) * currentRadiance * baseEssenceRatePerRadiancePerSecond;
        uint256 actualGrowth = potentialGrowth * timeElapsed;

        return actualGrowth;
    }

    /// @dev Internal function to apply attribute decay based on time elapsed.
    /// @param seedId The ID of the seed.
    /// @param timeElapsed The duration in seconds since the last decay check.
    function _applyDecayInternal(uint256 seedId, uint64 timeElapsed) internal {
        Seed storage seed = _seeds[seedId];
        uint16 oldRadiance = seed.radiance;
        uint16 oldResilience = seed.resilience;
        // uint16 oldFertility = seed.fertility; // Fertility doesn't decay in this example

        // Apply decay to Radiance
        uint64 radianceDecayRate = attributeDecayRatesPerSecond[uint8(AttributeType.Radiance)];
        if (radianceDecayRate > 0) {
            uint256 decayAmount = uint256(radianceDecayRate) * timeElapsed;
            seed.radiance = uint16(Math.max(0, int256(seed.radiance) - int256(decayAmount))); // Prevent underflow, cap at 0
            if (seed.radiance != oldRadiance) emit AttributeDecayed(seedId, uint8(AttributeType.Radiance), oldRadiance, seed.radiance);
        }

        // Apply decay to Resilience
        uint64 resilienceDecayRate = attributeDecayRatesPerSecond[uint8(AttributeType.Resilience)];
        if (resilienceDecayRate > 0) {
             uint256 decayAmount = uint256(resilienceDecayRate) * timeElapsed;
            seed.resilience = uint16(Math.max(0, int256(seed.resilience) - int256(decayAmount))); // Prevent underflow, cap at 0
             if (seed.resilience != oldResilience) emit AttributeDecayed(seedId, uint8(AttributeType.Resilience), oldResilience, seed.resilience);
        }

        // Fertility doesn't decay in this model, but could be added here.
    }


    /// @dev Internal function to check if a seed meets the conditions to evolve to a target stage.
    /// @param seedId The ID of the seed.
    /// @param targetStage The stage to check evolution readiness for.
    /// @return True if the seed meets the evolution conditions, false otherwise.
    function _checkEvolutionConditionsInternal(uint256 seedId, Stage targetStage) internal view returns (bool) {
        Seed storage seed = _seeds[seedId];
        uint8 currentStage = seed.stage;

        // Can only evolve to the next stage sequentially
        if (uint8(targetStage) != currentStage + 1) {
            return false; // Cannot skip stages, or target stage is not the immediate next one
        }

        // Cannot evolve from or past the final defined threshold stage
        if (currentStage >= uint8(Stage.Blossoming)) { // Assuming Blossoming is the last auto-evolution stage
            return false;
        }

        EvolutionThresholds storage thresholds = evolutionThresholds[currentStage];

        bool sufficientNourishment = seed.nourishmentPoints >= thresholds.nourishment;
        bool sufficientAge = (uint64(block.timestamp) - seed.mintedAt) >= thresholds.age;
        // Could add other conditions: minimum attribute values, number of interactions, etc.

        return sufficientNourishment && sufficientAge;
    }

    // --- 12. User Interaction Functions ---

    /// @notice Mints a new ChronoSeed NFT for the caller.
    /// @return The ID of the newly minted seed.
    function mintSeed() external payable whenNotPaused returns (uint256) {
        // Optional: require a minting fee
        // require(msg.value >= MINT_FEE, "Insufficient mint fee");
        // MINT_FEE would be a state variable or constant

        uint256 seedId = _nextTokenId;
        _mint(msg.sender, seedId); // Calls _mint which initializes Seed struct
        _nextTokenId++;
        return seedId;
    }

    /// @notice Allows the owner of a seed to burn it. Staked tokens need to be handled separately.
    /// @param seedId The ID of the seed to burn.
    function burnSeed(uint256 seedId) external whenNotPaused {
        if (ownerOf(seedId) != msg.sender) {
            revert NotSeedOwnerOrApproved(seedId); // Ensure caller is owner
        }
        if (_totalStakedPerSeed[seedId] > 0) {
             // Decide policy: require unstaking first, or auto-transfer?
             // Requiring unstaking is simplest for this example contract.
             revert InsufficientNourishmentStaked(seedId, 0, _totalStakedPerSeed[seedId]); // Reusing error for clarity - maybe make a new one
             // Error message should be: "Cannot burn seed with staked tokens. Withdraw first."
             // Let's fix the error usage below.
             revert InsufficientNourishmentStaked(seedId, 1, _totalStakedPerSeed[seedId]); // Using the error with dummy 1, available > 0
        }

        _burn(seedId); // Calls _burn which cleans up seed data
    }


    /// @notice Allows a user to stake tokens for a specific seed they own or are approved for.
    ///     Increases staked balance and updates nourishment points based on the staked amount and seed attributes.
    /// @param seedId The ID of the seed to nourish.
    /// @param amount The amount of stake tokens to stake.
    function stakeForNourishment(uint256 seedId, uint256 amount) external whenNotPaused {
        // Check if caller is owner or approved for all
        if (ownerOf(seedId) != msg.sender && !isApprovedForAll(ownerOf(seedId), msg.sender)) {
             revert NotSeedOwnerOrApproved(seedId);
        }
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId); // Should not happen if ownerOf check passes, but good practice

        // Update state before staking logic runs
        _updateSeedStateInternal(seedId);

        // Transfer tokens from the staker to the contract
        require(_stakeToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Update staked balances
        _stakedNourishment[seedId][msg.sender] += amount;
        _totalStakedPerSeed[seedId] += amount;

        // Calculate nourishment points gained. Could be complex: amount * base rate * (1 + fertility_bonus) * (1 + resilience_bonus)
        // For simplicity, let's use amount * base rate
        _seeds[seedId].nourishmentPoints += amount * baseNourishmentRate;
        _seeds[seedId].lastNourished = uint64(block.timestamp); // Update last nourished timestamp

        emit SeedNourished(seedId, msg.sender, amount, _totalStakedPerSeed[seedId]);
    }

    /// @notice Allows a user to withdraw their staked tokens from a specific seed.
    /// @param seedId The ID of the seed.
    /// @param amount The amount of stake tokens to withdraw.
    function withdrawStaked(uint256 seedId, uint256 amount) external whenNotPaused {
         if (!_exists(seedId)) revert SeedDoesNotExist(seedId);

        uint256 stakedBySender = _stakedNourishment[seedId][msg.sender];
        if (amount == 0 || amount > stakedBySender) {
            revert InsufficientNourishmentStaked(seedId, amount, stakedBySender);
        }

        // Update state before withdrawal logic runs (decay might reduce points, essence might accrue)
        _updateSeedStateInternal(seedId);

        // Deduct from staked balances
        _stakedNourishment[seedId][msg.sender] -= amount;
        _totalStakedPerSeed[seedId] -= amount;

        // Optionally reduce nourishment points? If nourishment is consumed by decay/evolution,
        // withdrawing staked tokens might not reduce points. If nourishment is purely a reflection
        // of current stake, points should decrease. Let's make nourishment points sticky - they
        // are earned when staking, and don't decrease just by withdrawing stake. They decrease
        // via decay/evolution consumption. This is more like "fertilizer applied" vs "fertilizer present".

        // Transfer tokens back to the user
        require(_stakeToken.transfer(msg.sender, amount), "Token transfer failed");

        emit StakedWithdrawn(seedId, msg.sender, amount, stakedBySender - amount);
    }

    /// @notice Allows the owner to perform a specific care interaction on a seed.
    ///     Affects attributes based on interaction type, requires a cooldown.
    /// @param seedId The ID of the seed.
    /// @param interactionType The type of interaction (from InteractionType enum).
    function interactWithSeed(uint256 seedId, uint8 interactionType) external onlySeedOwner(seedId) whenNotPaused {
        if (interactionType > uint8(InteractionType.Fertilize)) revert InvalidInteractionType();
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId); // Should not happen due to modifier

        Seed storage seed = _seeds[seedId];
        uint64 cooldown = interactionCooldowns[interactionType];
        uint64 timeSinceLastInteraction = uint64(block.timestamp) - seed.lastInteracted;

        if (timeSinceLastInteraction < cooldown) {
            revert InteractionCooldownNotElapsed(cooldown - timeSinceLastInteraction);
        }

        // Update state before applying interaction effects
        _updateSeedStateInternal(seedId);

        // Apply effects based on interaction type
        if (interactionType == uint8(InteractionType.Prune)) {
            // Example effect: Boost Radiance
            seed.radiance = uint16(Math.min(type(uint16).max, seed.radiance + 10)); // Boost radiance, capped
        } else if (interactionType == uint8(InteractionType.Polish)) {
            // Example effect: Boost Resilience
            seed.resilience = uint16(Math.min(type(uint16).max, seed.resilience + 10)); // Boost resilience, capped
        } else if (interactionType == uint8(InteractionType.Fertilize)) {
             // Example effect: Add nourishment points directly (instant boost)
             // Need admin config for amount added per Fertilize interaction
             uint256 pointsAdded = 500; // Example fixed value, make configurable if needed
             seed.nourishmentPoints += pointsAdded;
             // Note: Fertilize interaction adds points, separate from staking.
        }

        seed.lastInteracted = uint64(block.timestamp); // Update interaction timestamp

        emit SeedInteracted(seedId, interactionType, uint64(block.timestamp));
    }

    /// @notice Allows the owner to attempt to evolve a seed to the next stage if conditions are met.
    ///     Consumes nourishment points upon successful evolution.
    /// @param seedId The ID of the seed.
    function evolveSeed(uint256 seedId) external onlySeedOwner(seedId) whenNotPaused {
         if (!_exists(seedId)) revert SeedDoesNotExist(seedId); // Should not happen due to modifier

        // Update state before checking evolution conditions
        _updateSeedStateInternal(seedId);

        Seed storage seed = _seeds[seedId];
        uint8 currentStage = seed.stage;

        if (currentStage >= uint8(Stage.Blossoming)) { // Assuming Blossoming is the max stage for user-triggered evo
             revert AlreadyAtMaxStage(seedId);
        }

        Stage nextStage = Stage(currentStage + 1);
        if (!_checkEvolutionConditionsInternal(seedId, nextStage)) {
            revert SeedNotReadyForEvolution(seedId);
        }

        // Conditions met, perform evolution
        EvolutionThresholds storage thresholds = evolutionThresholds[currentStage];
        // Consume nourishment points (example: consume the exact amount needed for the evolution)
        seed.nourishmentPoints -= thresholds.nourishment;

        // Advance stage
        seed.stage = uint8(nextStage);

        // Optional: Apply permanent attribute boosts on evolution? Reset decay counters?
        // seed.lastInteracted = uint64(block.timestamp); // Reset interaction timer on evo?
        // seed.lastNourished = uint64(block.timestamp); // Reset nourishment timer on evo?
        // Keeping timers absolute is simpler, but resetting can simulate rejuvenation.
        // Let's not reset timers here for simplicity.

        emit SeedEvolved(seedId, currentStage, uint8(nextStage));
        // Note: _updateSeedStateInternal was called at the start, no need to call again immediately.
    }

    /// @notice Allows the owner to claim accumulated essence yield from a seed.
    ///     Resets the accumulated essence counter after claiming.
    /// @param seedId The ID of the seed.
    // In a real scenario, this would transfer actual tokens (e.g., a yield token).
    // Here, it just resets the counter and emits an event indicating claimable amount.
    function claimEssence(uint256 seedId) external onlySeedOwner(seedId) whenNotPaused {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId); // Should not happen due to modifier

        // Update state to calculate latest essence accumulation
        _updateSeedStateInternal(seedId);

        Seed storage seed = _seeds[seedId];
        uint256 claimableAmount = seed.accumulatedEssence;

        if (claimableAmount == 0) {
            revert NoEssenceToClaim(seedId);
        }

        // In a real contract, you would transfer tokens here:
        // require(YieldTokenContract.transfer(msg.sender, claimableAmount), "Yield token transfer failed");

        seed.accumulatedEssence = 0; // Reset accumulated essence

        emit EssenceClaimed(seedId, msg.sender, claimableAmount);
    }


    // --- 13. View Functions ---

    /// @notice Gets all stored data for a specific seed.
    /// @param seedId The ID of the seed.
    /// @return A Seed struct containing all its current state.
    function getSeedDetails(uint256 seedId) external view returns (Seed memory) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        // Note: This returns the *last calculated* state. For the most up-to-date dynamic state,
        // call `getCalculatedSeedState`.
        return _seeds[seedId];
    }

    /// @notice Simulates the state update logic to show the *potential* current dynamic state of a seed
    ///     without making any changes to storage. Useful for display purposes.
    /// @param seedId The ID of the seed.
    /// @return A Seed struct representing the calculated state if `_updateSeedStateInternal` were called now.
    function getCalculatedSeedState(uint256 seedId) external view returns (Seed memory) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        Seed memory currentSeedState = _seeds[seedId]; // Get current stored state

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - currentSeedState.lastStateCalculated;

        if (timeElapsed == 0) {
             return currentSeedState; // State is already up-to-date relative to time
        }

        // Apply decay (simulation)
        uint16 simulatedRadiance = currentSeedState.radiance;
        uint16 simulatedResilience = currentSeedState.resilience;

        uint64 radianceDecayRate = attributeDecayRatesPerSecond[uint8(AttributeType.Radiance)];
        if (radianceDecayRate > 0) {
            uint256 decayAmount = uint256(radianceDecayRate) * timeElapsed;
            simulatedRadiance = uint16(Math.max(0, int256(simulatedRadiance) - int256(decayAmount)));
        }

        uint64 resilienceDecayRate = attributeDecayRatesPerSecond[uint8(AttributeType.Resilience)];
        if (resilienceDecayRate > 0) {
            uint256 decayAmount = uint256(resilienceDecayRate) * timeElapsed;
            simulatedResilience = uint16(Math.max(0, int256(simulatedResilience) - int256(decayAmount)));
        }

        currentSeedState.radiance = simulatedRadiance;
        currentSeedState.resilience = simulatedResilience;
        // Fertility simulation if it decayed

        // Calculate essence growth (simulation)
        uint256 essenceEarned = _calculateEssenceGrowthInternal(seedId, timeElapsed); // This helper is already view-compatible
        currentSeedState.accumulatedEssence += essenceEarned;

        // Recalculate stage (simulation) - This would need replicating _checkEvolutionConditionsInternal logic
        // For simplicity in this example view function, let's *not* simulate stage updates as it adds complexity.
        // A real implementation might call a pure/view helper that does the stage calculation based on provided state.
        // For now, just return with decayed attributes and accrued essence.

        currentSeedState.lastStateCalculated = currentTime; // Simulate the timestamp update

        return currentSeedState;
    }


    /// @notice Gets the amount of Essence accumulated but not yet claimed for a seed.
    /// @param seedId The ID of the seed.
    /// @return The accumulated Essence amount.
    function getAccumulatedEssence(uint256 seedId) external view returns (uint256) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
         // Returns the stored value. For latest, call getCalculatedSeedState and check .accumulatedEssence
        return _seeds[seedId].accumulatedEssence;
    }

    /// @notice Gets the total amount of stake tokens currently staked for a specific seed across all users.
    /// @param seedId The ID of the seed.
    /// @return The total staked amount.
    function getTotalNourishmentStaked(uint256 seedId) external view returns (uint256) {
         if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        return _totalStakedPerSeed[seedId];
    }

    /// @notice Gets the amount of stake tokens staked by a specific user for a specific seed.
    /// @param seedId The ID of the seed.
    /// @param staker The address of the staker.
    /// @return The amount staked by the user for the seed.
    function getStakedAmountByUserForSeed(uint256 seedId, address staker) external view returns (uint256) {
         if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        return _stakedNourishment[seedId][staker];
    }

    /// @notice Checks if a seed meets the conditions required to evolve to its next stage.
    /// @param seedId The ID of the seed.
    /// @return True if evolution conditions are met, false otherwise.
    function checkEvolutionReadiness(uint256 seedId) external view returns (bool) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        Seed storage seed = _seeds[seedId];
        uint8 currentStage = seed.stage;

        if (currentStage >= uint8(Stage.Blossoming)) { // Cannot evolve from or past max stage
             return false;
        }

        return _checkEvolutionConditionsInternal(seedId, Stage(currentStage + 1));
    }

    /// @notice Gets the address of the token used for nourishment staking.
    /// @return The stake token address.
    function getStakeTokenAddress() external view returns (address) {
        return address(_stakeToken);
    }

    /// @notice Gets the current stage of a seed.
    /// @param seedId The ID of the seed.
    /// @return The stage number (corresponds to Stage enum).
    function getSeedStage(uint256 seedId) external view returns (uint8) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        return _seeds[seedId].stage;
    }

    /// @notice Gets the current attributes of a seed.
    /// @param seedId The ID of the seed.
    /// @return resilience, radiance, fertility attributes.
    function getSeedAttributes(uint256 seedId) external view returns (uint16 resilience, uint16 radiance, uint16 fertility) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        Seed storage seed = _seeds[seedId];
        return (seed.resilience, seed.radiance, seed.fertility);
    }

    /// @notice Gets the time elapsed in seconds since the last user interaction with the seed.
    /// @param seedId The ID of the seed.
    /// @return Time elapsed in seconds.
    function getTimeSinceLastInteraction(uint256 seedId) external view returns (uint64) {
        if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        return uint64(block.timestamp) - _seeds[seedId].lastInteracted;
    }

    /// @notice Gets the time elapsed in seconds since the last nourishment was applied to the seed.
    /// @param seedId The ID of the seed.
    /// @return Time elapsed in seconds.
    function getTimeSinceLastNourishment(uint256 seedId) external view returns (uint64) {
         if (!_exists(seedId)) revert SeedDoesNotExist(seedId);
        return uint64(block.timestamp) - _seeds[seedId].lastNourished;
    }


    // --- Internal Check Helper for ERC721 overrides ---
    function _exists(uint256 tokenId) internal view override(ERC721, ERC721Enumerable) returns (bool) {
         // Override _exists to check our internal mapping instead of just the ERC721 internal one,
         // ensuring the Seed struct data exists.
         // Note: The standard ERC721 _exists check based on _balances and _owners might be enough
         // if we rely solely on super._exists(). Let's rely on super for simplicity and standard compliance.
        return super._exists(tokenId);
    }
}
```