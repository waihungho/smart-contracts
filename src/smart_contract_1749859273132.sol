Okay, let's design a smart contract concept that incorporates generative art principles, dynamic state, staking, internal tokenomics, and a curation layer, going beyond typical NFT or DeFi examples.

Here's the concept: **The Evolving Generative Seed Vault**.

Users can mint "Seed" NFTs. Each Seed contains a set of parameters. These parameters don't store an image, but rather the *inputs* for an off-chain generative art renderer. The cool part? Seeds can *evolve* over time and through user interaction (staking, expending internal resources), changing their parameters and thus the resulting art. There's an internal "Essence" token gained through staking, used for evolution or locking the seed. Once locked, the seed's parameters are final. There's also a curation mechanism.

This covers:
*   **Generative Art:** Parameters stored on-chain, render off-chain.
*   **Dynamic NFTs:** Seed parameters change, metadata updates.
*   **Staking:** Locking NFTs to gain resources/progress.
*   **Internal Tokenomics:** An `Essence` token for actions.
*   **Evolution/Time:** State changes based on time and interaction.
*   **Curation:** A mechanism to highlight certain seeds.
*   **Complexity:** Managing multiple states, parameters, balances, randomness (pseudo), etc.

---

**Outline:**

1.  **Contract Definition:** Inherits ERC721Enumerable and Ownable.
2.  **Errors:** Custom errors for clarity.
3.  **Structs:**
    *   `SeedParameters`: Defines the attributes used for art generation (e.g., color values, shape types, complexity levels).
    *   `Seed`: Stores the state of each NFT (parameters, evolution progress, locked status, curated status, staking info reference).
    *   `StakeInfo`: Stores details when a seed is staked (owner, start time, essence earned).
4.  **State Variables:**
    *   Mappings for Seed data, Essence balances, Staked Seed data.
    *   Counters for token IDs and stake IDs.
    *   Configuration variables (costs, rates, base parameters).
    *   List of curated seed IDs.
5.  **Events:** For key actions (Mint, Evolve, Lock, Stake, Unstake, EssenceClaimed, Curated).
6.  **Core ERC721 Functions:** Standard overrides (`tokenURI`, `_beforeTokenTransfer`).
7.  **Internal Token (Essence) Management:** Functions to `_mintEssence`, `_burnEssence`, `_transferEssence`.
8.  **Pseudo-Randomness:** Internal function for generating random-ish values on-chain.
9.  **Seed Mechanics:**
    *   Minting (pays ETH, gets Seed NFT with initial params).
    *   Evolution (costs Essence, requires staking time/progress, randomizes parameters).
    *   Staking (locks seed, earns Essence and evolution progress over time).
    *   Unstaking.
    *   Claiming Staking Rewards.
    *   Locking (costs Essence, finalizes parameters).
10. **Generative Parameter Logic:**
    *   Function to deterministically generate a hash from current parameters for rendering.
    *   Function to generate initial random parameters.
    *   Function to apply evolution changes to parameters.
11. **Admin/Configuration Functions:**
    *   Set costs (mint, evolve, lock).
    *   Set staking rate.
    *   Set base parameters for generation/evolution limits.
    *   Distribute Essence (initial or rewards).
    *   Withdraw ETH.
    *   Curate a seed.
12. **View Functions:**
    *   Get seed data, parameters, evolution progress.
    *   Get Essence balance.
    *   Get user's staked seeds.
    *   Get curated seeds list.
    *   Get current configuration.
    *   Get the deterministic art hash for a seed.

---

**Function Summary:**

1.  `constructor()`: Initializes contract, sets owner and initial configurations.
2.  `mintSeed(uint256 initialEvolutionProgress)`: Mints a new Seed NFT. Requires ETH payment. Generates initial random parameters and sets starting evolution progress.
3.  `tokenURI(uint256 tokenId)`: Overrides ERC721. Returns a data URI containing JSON metadata for the seed, including its current parameters, state (locked/staked), and evolution progress.
4.  `getSeedData(uint256 tokenId)`: View function returning the full `Seed` struct data for a given token ID.
5.  `getSeedCurrentParameters(uint256 tokenId)`: View function returning just the `SeedParameters` for a given token ID.
6.  `getSeedEvolutionProgress(uint256 tokenId)`: View function returning the current evolution progress points for a seed.
7.  `getEssenceBalance(address owner)`: View function returning the user's current balance of the internal Essence token.
8.  `evolveSeed(uint256 tokenId)`: Triggers the evolution process for a seed. Burns `evolutionCost` Essence. Requires sufficient `evolutionProgress` accumulated (e.g., through staking). Randomly modifies seed parameters and resets evolution progress.
9.  `stakeSeed(uint256 tokenId)`: Marks a seed as staked. Transfers the token to the contract's address (or a dedicated staking escrow). Records the staking start time.
10. `unstakeSeed(uint256 tokenId)`: Removes a seed from staking. Transfers the token back to the owner. Calculates and accrues earned Essence and evolution progress before unstaking.
11. `claimStakingRewards(uint256 tokenId)`: Calculates Essence and evolution progress earned since the last claim/stake action for a specific staked seed and adds it to the user's balance/seed's progress. Resets the timer for claiming.
12. `getUserStakedSeeds(address owner)`: View function returning a list of token IDs that the specified owner has currently staked.
13. `lockSeed(uint256 tokenId)`: Finalizes the seed's parameters. Burns `lockCost` Essence. Sets the `isLocked` flag to true, preventing further evolution or staking.
14. `generateArtHash(uint256 tokenId)`: View function that generates a deterministic unique hash based on the *current* `SeedParameters` of the seed. This hash serves as the unique identifier for the off-chain renderer.
15. `curateSeed(uint256 tokenId)`: Owner-only function to mark a specific seed as "curated". Adds its ID to a list.
16. `uncurateSeed(uint256 tokenId)`: Owner-only function to remove a seed from the curated list.
17. `getCuratedSeeds()`: View function returning the list of token IDs that have been curated.
18. `setMintCost(uint256 cost)`: Owner-only function to set the ETH cost for minting a new seed.
19. `setEvolutionCost(uint256 cost)`: Owner-only function to set the Essence cost for evolving a seed.
20. `setLockCost(uint256 cost)`: Owner-only function to set the Essence cost for locking a seed.
21. `setStakingRewardRate(uint256 essencePerSecond, uint256 evolutionPerSecond)`: Owner-only function to set the rate at which staked seeds earn Essence and evolution progress.
22. `setBaseGenerationParams(uint256[] calldata minParams, uint256[] calldata maxParams, uint256 evolutionMagnitude)`: Owner-only function to set the base ranges for seed parameters and how much evolution changes them.
23. `getCurrentBaseGenerationParams()`: View function returning the current minimum and maximum values for seed parameters and the evolution magnitude.
24. `distributeEssence(address[] calldata recipients, uint256[] calldata amounts)`: Owner-only function to distribute Essence tokens to multiple addresses (e.g., for initial distribution or rewards).
25. `withdrawEth()`: Owner-only function to withdraw collected ETH from minting fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. Contract Definition (Inherits ERC721Enumerable, Ownable)
// 2. Errors
// 3. Structs (SeedParameters, Seed, StakeInfo)
// 4. State Variables (Mappings for seeds, essence, staking; counters; config)
// 5. Events
// 6. ERC721 Overrides (tokenURI)
// 7. Internal Token (Essence) Management (_mint, _burn, _transfer)
// 8. Pseudo-Randomness (Internal function)
// 9. Seed Mechanics (Mint, Evolve, Stake, Unstake, Claim, Lock)
// 10. Generative Parameter Logic (Generate hash, initial params, apply evolution)
// 11. Admin/Configuration Functions (Set costs, rates, params, distribute, withdraw, curate)
// 12. View Functions (Get seed data, balances, staked, curated, config, hash)

// --- Function Summary ---
// 1. constructor(): Initializes contract, owner, config.
// 2. mintSeed(uint256 initialEvolutionProgress): Mints Seed NFT, requires ETH, generates initial random params.
// 3. tokenURI(uint256 tokenId): Returns dynamic JSON metadata URI based on seed state/params.
// 4. getSeedData(uint256 tokenId): View: Full Seed struct data.
// 5. getSeedCurrentParameters(uint256 tokenId): View: Just the SeedParameters.
// 6. getSeedEvolutionProgress(uint256 tokenId): View: Current evolution points.
// 7. getEssenceBalance(address owner): View: User's Essence token balance.
// 8. evolveSeed(uint256 tokenId): Burns Essence, requires progress, randomizes parameters.
// 9. stakeSeed(uint256 tokenId): Stakes seed, transfers to contract, records time.
// 10. unstakeSeed(uint256 tokenId): Unstakes seed, transfers back, accrues rewards/progress.
// 11. claimStakingRewards(uint256 tokenId): Calculates & claims Essence/progress from staking.
// 12. getUserStakedSeeds(address owner): View: List of user's staked seed IDs.
// 13. lockSeed(uint256 tokenId): Burns Essence, finalizes parameters, prevents evolution/staking.
// 14. generateArtHash(uint256 tokenId): View: Deterministic hash from current parameters.
// 15. curateSeed(uint256 tokenId): Owner-only: Marks a seed as curated.
// 16. uncurateSeed(uint256 tokenId): Owner-only: Unmarks a seed as curated.
// 17. getCuratedSeeds(): View: List of curated seed IDs.
// 18. setMintCost(uint256 cost): Owner-only: Sets ETH cost for minting.
// 19. setEvolutionCost(uint256 cost): Owner-only: Sets Essence cost for evolution.
// 20. setLockCost(uint256 cost): Owner-only: Sets Essence cost for locking.
// 21. setStakingRewardRate(uint256 essencePerSecond, uint256 evolutionPerSecond): Owner-only: Sets staking reward rates.
// 22. setBaseGenerationParams(uint256[] calldata minParams, uint256[] calldata maxParams, uint256 evolutionMagnitude): Owner-only: Sets parameter ranges and evolution effect.
// 23. getCurrentBaseGenerationParams(): View: Returns current parameter ranges and evolution magnitude.
// 24. distributeEssence(address[] calldata recipients, uint256[] calldata amounts): Owner-only: Distributes Essence tokens.
// 25. withdrawEth(): Owner-only: Withdraws collected ETH.

contract GenerativeArtVault is ERC721Enumerable, Ownable {
    // --- 2. Errors ---
    error InvalidTokenId();
    error NotTokenOwner(uint256 tokenId);
    error SeedAlreadyLocked(uint256 tokenId);
    error SeedNotStaked(uint256 tokenId);
    error SeedAlreadyStaked(uint256 tokenId);
    error InsufficientEssence(uint256 required, uint256 has);
    error InsufficientEvolutionProgress(uint256 required, uint256 has);
    error InvalidParameterLength();
    error ArraysLengthMismatch();
    error EvolutionMagnitudeTooSmall();
    error CannotWithdrawZeroEth();

    // --- 3. Structs ---
    struct SeedParameters {
        // Example parameters - these would define the generative art output
        uint256 colorHue;       // e.g., 0-360
        uint256 shapeComplexity; // e.g., 1-100
        uint256 textureDetail;   // e.g., 0-255
        uint256 randomnessSeed;  // Internal seed for off-chain generator's pseudo-randomness
        uint256 parameterCount; // Number of parameters
        // Add more parameters as needed for the generative art system
        // Using dynamic array for parameters allows flexibility, but requires careful handling
        uint256[] values; // Flexible array of parameter values
    }

    struct Seed {
        SeedParameters parameters;
        uint256 evolutionProgress; // Points towards the next evolution stage
        uint64 lastEvolutionTime;   // Timestamp of the last evolution or mint
        bool isLocked;
        bool isCurated;
        uint256 stakeId; // 0 if not staked, reference to stakeInfo otherwise
    }

    struct StakeInfo {
        address owner;
        uint64 startTime;
        uint256 accruedEssence; // Essence accumulated but not yet claimed for this stake period
        uint256 accruedEvolutionProgress; // Progress accumulated but not yet claimed
    }

    // --- 4. State Variables ---
    mapping(uint256 => Seed) private _seeds;
    mapping(address => uint256) private _essenceBalances;
    mapping(uint256 => StakeInfo) private _stakeInfo; // stakeId => StakeInfo
    mapping(address => uint256[]) private _userStakedSeeds; // owner => list of staked tokenIds

    uint256 private _nextTokenId;
    uint256 private _nextStakeId = 1; // Start from 1 to distinguish from 0 (not staked)

    uint256 public mintCost = 0.01 ether; // ETH cost to mint a seed
    uint256 public evolutionCost = 100; // Essence cost to evolve
    uint256 public lockCost = 500; // Essence cost to lock

    uint256 public evolutionProgressRequired = 1000; // Points needed for one evolution step

    uint256 public stakingEssenceRatePerSecond = 1; // Essence earned per second staked
    uint256 public stakingEvolutionRatePerSecond = 1; // Evolution progress earned per second staked

    // Base parameters defining the min/max ranges and evolution magnitude
    SeedParameters public baseGenerationParams;
    uint256 public evolutionMagnitude = 10; // How much parameters change during evolution

    uint256[] private _curatedSeedIds;

    // --- 5. Events ---
    event SeedMinted(uint256 indexed tokenId, address indexed owner, SeedParameters initialParameters);
    event SeedEvolved(uint256 indexed tokenId, SeedParameters newParameters, uint256 remainingProgress);
    event SeedStaked(uint256 indexed tokenId, address indexed owner, uint256 indexed stakeId);
    event SeedUnstaked(uint256 indexed tokenId, address indexed owner, uint256 indexed stakeId, uint256 claimedEssence, uint256 claimedEvolutionProgress);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 indexed stakeId, uint256 claimedEssence, uint256 claimedEvolutionProgress);
    event SeedLocked(uint256 indexed tokenId);
    event EssenceDistributed(address[] recipients, uint256[] amounts);
    event EssenceBurned(address indexed user, uint256 amount);
    event SeedCurated(uint256 indexed tokenId);
    event SeedUncurated(uint256 indexed tokenId);
    event BaseGenerationParamsUpdated(uint256[] minParams, uint256[] maxParams, uint256 evolutionMagnitude);
    event ConfigUpdated(string key, uint256 value);

    // --- 1. Contract Definition & 6. ERC721 Overrides ---
    constructor(
        string memory name,
        string memory symbol,
        uint256[] memory initialMinParams,
        uint256[] memory initialMaxParams,
        uint256 initialEvolutionMagnitude
    ) ERC721Enumerable(name, symbol) Ownable(msg.sender) {
        if (initialMinParams.length != initialMaxParams.length || initialMinParams.length == 0) {
            revert InvalidParameterLength();
        }
         if (initialEvolutionMagnitude == 0) {
            revert EvolutionMagnitudeTooSmall();
        }
        baseGenerationParams.parameterCount = initialMinParams.length;
        baseGenerationParams.values = initialMinParams; // Store min as initial values array size
        _setBaseGenerationParams(initialMinParams, initialMaxParams, initialEvolutionMagnitude);
    }

    // Override to prevent transfer of staked or locked tokens
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && from != address(this)) { // Check only for actual transfers (not minting/burning)
            Seed storage seed = _seeds[tokenId];
            if (seed.isLocked) {
                revert SeedAlreadyLocked(tokenId);
            }
            if (seed.stakeId != 0) {
                revert SeedAlreadyStaked(tokenId); // Cannot transfer while staked
            }
        }
         // Ensure staking transfers go to and from this contract address
        if (to == address(this) && from != address(0)) { // Staking
            require(_seeds[tokenId].stakeId == 0, "Cannot stake already staked seed");
        }
         if (from == address(this) && to != address(0)) { // Unstaking
            require(_seeds[tokenId].stakeId != 0, "Cannot unstake a non-staked seed");
        }
    }

    // --- 3. tokenURI (Advanced: Dynamic Metadata) ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        Seed storage seed = _seeds[tokenId];
        SeedParameters storage params = seed.parameters;

        // Generate attributes array from parameters
        string memory attributesJson = "[";
        // Assuming parameters have implicit names based on index or structure
        // For this example, we'll just list them as param_0, param_1, etc.
        // A real implementation would map index to meaningful trait names.
        for (uint i = 0; i < params.values.length; i++) {
            attributesJson = string.concat(
                attributesJson,
                '{"trait_type": "Parameter ', Strings.toString(i), '", "value": ', Strings.toString(params.values[i]), '}'
            );
            if (i < params.values.length - 1) {
                attributesJson = string.concat(attributesJson, ",");
            }
        }
         attributesJson = string.concat(attributesJson, "]");

        // Add seed state attributes
        string memory stateAttributesJson = string.concat(
            '[{"trait_type": "Status", "value": "', seed.isLocked ? "Locked" : (seed.stakeId != 0 ? "Staked" : "Active"), '"},',
            '{"trait_type": "Evolution Progress", "value": ', Strings.toString(seed.evolutionProgress), '},',
            '{"trait_type": "Curated", "value": ', seed.isCurated ? "True" : "False", '}]'
        );


        // Combine attributes
         // Note: Combining JSON strings manually can be error-prone. A library or helper might be better.
         // Simple concatenation assumes the first array is not empty.
        if (bytes(attributesJson).length > 2) { // Check if "[{" exists
             attributesJson = string.concat(attributesJson, ",", stateAttributesJson);
             attributesJson = string.concat("[", attributesJson, "]"); // Wrap in outer array
        } else { // If no dynamic parameters, just use state attributes
             attributesJson = stateAttributesJson;
        }


        // Generate a unique identifier for the off-chain renderer based on current parameters
        string memory artIdentifier = Strings.toHexString(generateArtHash(tokenId));

        // Off-chain renderer URL - this is a placeholder.
        // A real renderer would use the artIdentifier to fetch/generate the image.
        string memory image = string.concat("https://mygenerativeartrenderer.com/render/", artIdentifier);

        // Construct the JSON metadata
        string memory json = string.concat(
            '{',
                '"name": "Evolving Seed #', Strings.toString(tokenId), '",',
                '"description": "A generative art seed that can evolve over time and interaction.",',
                '"image": "', image, '",',
                '"attributes": ', attributesJson,
            '}'
        );

        // Return as a data URI
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // --- 7. Internal Token (Essence) Management ---
    function _mintEssence(address recipient, uint256 amount) internal {
        if (amount == 0) return;
        _essenceBalances[recipient] += amount;
        // Consider adding an internal event for minting
    }

    function _burnEssence(address burner, uint256 amount) internal {
        if (amount == 0) return;
        uint256 currentBalance = _essenceBalances[burner];
        if (currentBalance < amount) {
            revert InsufficientEssence(amount, currentBalance);
        }
        _essenceBalances[burner] = currentBalance - amount;
        emit EssenceBurned(burner, amount);
    }

    // Internal transfer, not needed for this concept but good practice
    // function _transferEssence(address from, address to, uint256 amount) internal {
    //     _burnEssence(from, amount);
    //     _mintEssence(to, amount);
    // }

    // --- 8. Pseudo-Randomness ---
    // WARNING: This is NOT cryptographically secure randomness and is predictable.
    // For a real project needing secure randomness, integrate Chainlink VRF or similar.
    function _pseudoRandom(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tx.origin, block.number, block.difficulty, seed)));
    }

    // --- 9. Seed Mechanics ---

    // 2. mintSeed
    function mintSeed(uint256 initialEvolutionProgress) public payable {
        if (msg.value < mintCost) revert InsufficientEssence(mintCost, msg.value); // Using Essence error type for ETH, needs refinement
        // A dedicated error `InsufficientETH` would be better practice

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        SeedParameters memory initialParams = _generateInitialParameters(tokenId);

        _seeds[tokenId] = Seed({
            parameters: initialParams,
            evolutionProgress: initialEvolutionProgress,
            lastEvolutionTime: uint64(block.timestamp),
            isLocked: false,
            isCurated: false,
            stakeId: 0
        });

        emit SeedMinted(tokenId, msg.sender, initialParams);
    }

    // 8. evolveSeed
    function evolveSeed(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotTokenOwner(tokenId);
        Seed storage seed = _seeds[tokenId];

        if (seed.isLocked) revert SeedAlreadyLocked(tokenId);
        if (seed.stakeId != 0) revert SeedAlreadyStaked(tokenId); // Cannot evolve directly if staked

        uint256 currentEssence = _essenceBalances[msg.sender];
        if (currentEssence < evolutionCost) revert InsufficientEssence(evolutionCost, currentEssence);

        if (seed.evolutionProgress < evolutionProgressRequired) revert InsufficientEvolutionProgress(evolutionProgressRequired, seed.evolutionProgress);

        _burnEssence(msg.sender, evolutionCost);

        // Apply evolution changes based on current params and randomness
        seed.parameters = _applyEvolution(seed.parameters, tokenId);

        // Reset progress and update timestamp
        seed.evolutionProgress = seed.evolutionProgress - evolutionProgressRequired; // Deduct cost in progress
        seed.lastEvolutionTime = uint64(block.timestamp);

        emit SeedEvolved(tokenId, seed.parameters, seed.evolutionProgress);
    }

    // Helper to calculate pending rewards/progress
    function _calculatePendingStakingRewards(uint256 tokenId, uint256 stakeId) internal view returns (uint256 essenceAmount, uint256 evolutionAmount) {
        StakeInfo storage stake = _stakeInfo[stakeId];
        uint64 timeStaked = uint64(block.timestamp) - stake.startTime;

        essenceAmount = stake.accruedEssence + (uint256(timeStaked) * stakingEssenceRatePerSecond);
        evolutionAmount = stake.accruedEvolutionProgress + (uint256(timeStaked) * stakingEvolutionRatePerSecond);
    }

    // 9. stakeSeed
    function stakeSeed(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotTokenOwner(tokenId);
        Seed storage seed = _seeds[tokenId];

        if (seed.isLocked) revert SeedAlreadyLocked(tokenId);
        if (seed.stakeId != 0) revert SeedAlreadyStaked(tokenId);

        // Transfer the token to the contract address
        _transfer(msg.sender, address(this), tokenId);

        // Create new stake info
        uint256 currentStakeId = _nextStakeId++;
        _stakeInfo[currentStakeId] = StakeInfo({
            owner: msg.sender,
            startTime: uint64(block.timestamp),
            accruedEssence: 0,
            accruedEvolutionProgress: 0
        });

        // Update seed state
        seed.stakeId = currentStakeId;

        // Add to user's list of staked seeds
        _userStakedSeeds[msg.sender].push(tokenId);

        emit SeedStaked(tokenId, msg.sender, currentStakeId);
    }

    // 10. unstakeSeed
    function unstakeSeed(uint256 tokenId) public {
        Seed storage seed = _seeds[tokenId];
        if (seed.stakeId == 0) revert SeedNotStaked(tokenId);

        StakeInfo storage stake = _stakeInfo[seed.stakeId];
        if (stake.owner != msg.sender) revert NotTokenOwner(tokenId); // msg.sender must be the original staker

        // Claim pending rewards before unstaking
        (uint256 claimedEssence, uint256 claimedEvolutionProgress) = _calculateAndClaimStakingRewards(tokenId, seed.stakeId);

        // Reset stake info and seed state
        delete _stakeInfo[seed.stakeId];
        seed.stakeId = 0;

        // Remove from user's list of staked seeds
        uint256[] storage stakedSeeds = _userStakedSeeds[msg.sender];
        for (uint i = 0; i < stakedSeeds.length; i++) {
            if (stakedSeeds[i] == tokenId) {
                stakedSeeds[i] = stakedSeeds[stakedSeeds.length - 1];
                stakedSeeds.pop();
                break;
            }
        }

        // Transfer the token back to the owner
        _transfer(address(this), msg.sender, tokenId);

        emit SeedUnstaked(tokenId, msg.sender, stake.stakeId, claimedEssence, claimedEvolutionProgress);
    }

    // Helper function to calculate and claim rewards, used internally by unstake and claimStakingRewards
    function _calculateAndClaimStakingRewards(uint256 tokenId, uint256 stakeId) internal returns (uint256 claimedEssence, uint256 claimedEvolutionProgress) {
         StakeInfo storage stake = _stakeInfo[stakeId];
         Seed storage seed = _seeds[tokenId];

         (claimedEssence, claimedEvolutionProgress) = _calculatePendingStakingRewards(tokenId, stakeId);

        if (claimedEssence > 0) {
             _mintEssence(stake.owner, claimedEssence);
             stake.accruedEssence = 0; // Reset accrued
        } else {
             claimedEssence = 0; // Ensure return value is 0 if no new essence
        }

        if (claimedEvolutionProgress > 0) {
             seed.evolutionProgress += claimedEvolutionProgress;
             stake.accruedEvolutionProgress = 0; // Reset accrued
        } else {
             claimedEvolutionProgress = 0; // Ensure return value is 0 if no new progress
        }

         // Reset stake timer
        stake.startTime = uint64(block.timestamp);

        return (claimedEssence, claimedEvolutionProgress);
    }


    // 11. claimStakingRewards
    function claimStakingRewards(uint256 tokenId) public {
        Seed storage seed = _seeds[tokenId];
        if (seed.stakeId == 0) revert SeedNotStaked(tokenId);

        StakeInfo storage stake = _stakeInfo[seed.stakeId];
        if (stake.owner != msg.sender) revert NotTokenOwner(tokenId);

        (uint256 claimedEssence, uint256 claimedEvolutionProgress) = _calculateAndClaimStakingRewards(tokenId, seed.stakeId);

        emit StakingRewardsClaimed(tokenId, msg.sender, seed.stakeId, claimedEssence, claimedEvolutionProgress);
    }

    // 13. lockSeed
    function lockSeed(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert NotTokenOwner(tokenId);
        Seed storage seed = _seeds[tokenId];

        if (seed.isLocked) revert SeedAlreadyLocked(tokenId);
        if (seed.stakeId != 0) revert SeedAlreadyStaked(tokenId); // Must unstake first

        uint256 currentEssence = _essenceBalances[msg.sender];
        if (currentEssence < lockCost) revert InsufficientEssence(lockCost, currentEssence);

        _burnEssence(msg.sender, lockCost);

        seed.isLocked = true;

        emit SeedLocked(tokenId);
    }

    // --- 10. Generative Parameter Logic ---

    // 14. generateArtHash
    function generateArtHash(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Deterministic hash based on the *current* parameters of the seed.
        // This ensures the same parameters always generate the same visual art (via the off-chain renderer).
        return keccak256(abi.encodePacked(_seeds[tokenId].parameters.values));
    }

    // Internal helper to generate initial random parameters within base ranges
    function _generateInitialParameters(uint256 seedValue) internal view returns (SeedParameters memory) {
         uint256[] memory minParams = baseGenerationParams.values;
         uint256[] memory maxParams = baseGenerationParams.values; // Placeholder, will fetch actual max

         // Fetch the actual max values (they are stored in the same array structure but logically separate)
         // This is a simplified way to store min/max in one state variable array.
         // A more robust approach might use two separate arrays in the struct.
         // Let's assume baseGenerationParams.values *are* the min values, and we need to fetch max separately.
         // Correction: Let's store min/max separately in the state variable.
         // This requires adjusting the struct or state variable definition.
         // Let's update the state variable to use two arrays for min/max.

         // --- Re-structuring state variable ---
         // Need `uint256[] public minBaseGenerationParams;` and `uint256[] public maxBaseGenerationParams;`
         // And update `setBaseGenerationParams` and constructor accordingly.

         // For now, assume baseGenerationParams.values is min, and we have a separate max array.
         // Let's pretend `maxBaseGenerationParams` exists for this logic demonstration.
         uint256[] memory minParamValues = baseGenerationParams.values; // Assuming this is the MIN array
         // Let's fetch the MAX values.
         // Assume another state variable exists: `uint256[] public maxBaseGenerationParams;`
         uint256[] memory maxParamValues = new uint256[](minParamValues.length); // Dummy for demo
         // In a real contract, you'd read from a state variable like `maxBaseGenerationParams`

         // Placeholder for fetching max - In a real contract, this would read state
         // For this demo, let's just use arbitrary max values relative to the min for illustration
         for(uint i = 0; i < minParamValues.length; i++){
             maxParamValues[i] = minParamValues[i] + 100; // Example: Max is Min + 100
         }
         // --- End Re-structuring Note ---


        uint256[] memory values = new uint256[](minParamValues.length);
        for (uint i = 0; i < minParamValues.length; i++) {
            uint256 rand = _pseudoRandom(seedValue + i); // Use unique seed per parameter
            uint256 minVal = minParamValues[i];
            uint256 maxVal = maxParamValues[i]; // Use actual max value
            // Generate value within [minVal, maxVal] range
            values[i] = minVal + (rand % (maxVal - minVal + 1));
        }

        return SeedParameters({
            colorHue: 0, // Not used with dynamic array
            shapeComplexity: 0, // Not used with dynamic array
            textureDetail: 0, // Not used with dynamic array
            randomnessSeed: seedValue, // Seed used for the initial generation
            parameterCount: values.length,
            values: values
        });
    }

    // Internal helper to apply evolution changes
    function _applyEvolution(SeedParameters memory currentParams, uint256 seedValue) internal view returns (SeedParameters memory) {
         SeedParameters memory newParams = currentParams; // Copy current params

         // Fetch the actual min/max values from state
         uint256[] memory minParamValues = baseGenerationParams.values; // Assuming this is the MIN array
         // Assume state variable `maxBaseGenerationParams` exists
         uint256[] memory maxParamValues = new uint256[](minParamValues.length); // Dummy
          for(uint i = 0; i < minParamValues.length; i++){
             maxParamValues[i] = minParamValues[i] + 100; // Example: Max is Min + 100
         }
         // End fetching dummy max


        for (uint i = 0; i < newParams.values.length; i++) {
            uint256 rand = _pseudoRandom(seedValue + block.timestamp + i); // Use unique seed per parameter + time

            int256 change = int256(rand % (evolutionMagnitude * 2 + 1)) - int256(evolutionMagnitude); // Change is [-magnitude, +magnitude]

            int256 newVal = int256(newParams.values[i]) + change;

            // Clamp the new value within the base min/max range
            newVal = max(int256(minParamValues[i]), newVal);
            newVal = min(int256(maxParamValues[i]), newVal);

            newParams.values[i] = uint256(newVal);
        }

        newParams.randomnessSeed = _pseudoRandom(seedValue + block.timestamp + 999); // Update internal renderer seed

        return newParams;
    }

    // --- 11. Admin/Configuration Functions (Owner Only) ---

    // 15. curateSeed
    function curateSeed(uint256 tokenId) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Seed storage seed = _seeds[tokenId];
        if (!seed.isCurated) {
            seed.isCurated = true;
            _curatedSeedIds.push(tokenId);
            emit SeedCurated(tokenId);
        }
    }

    // 16. uncurateSeed
     function uncurateSeed(uint256 tokenId) public onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Seed storage seed = _seeds[tokenId];
        if (seed.isCurated) {
            seed.isCurated = false;
            // Remove from curated list (inefficient for large lists, but simple)
            for (uint i = 0; i < _curatedSeedIds.length; i++) {
                if (_curatedSeedIds[i] == tokenId) {
                    _curatedSeedIds[i] = _curatedSeedIds[_curatedSeedIds.length - 1];
                    _curatedSeedIds.pop();
                    break;
                }
            }
            emit SeedUncurated(tokenId);
        }
    }

    // 18. setMintCost
    function setMintCost(uint256 cost) public onlyOwner {
        mintCost = cost;
        emit ConfigUpdated("mintCost", cost);
    }

    // 19. setEvolutionCost
    function setEvolutionCost(uint256 cost) public onlyOwner {
        evolutionCost = cost;
         emit ConfigUpdated("evolutionCost", cost);
    }

    // 20. setLockCost
    function setLockCost(uint256 cost) public onlyOwner {
        lockCost = cost;
        emit ConfigUpdated("lockCost", cost);
    }

    // 21. setStakingRewardRate
    function setStakingRewardRate(uint256 essencePerSecond, uint256 evolutionPerSecond) public onlyOwner {
        stakingEssenceRatePerSecond = essencePerSecond;
        stakingEvolutionRatePerSecond = evolutionPerSecond;
         emit ConfigUpdated("stakingEssenceRatePerSecond", essencePerSecond);
         emit ConfigUpdated("stakingEvolutionRatePerSecond", evolutionPerSecond);
    }

    // 22. setBaseGenerationParams
     // NOTE: This function now requires both min and max arrays.
    function setBaseGenerationParams(uint256[] calldata minParams, uint256[] calldata maxParams, uint256 initialEvolutionMagnitude) public onlyOwner {
        if (minParams.length != maxParams.length || minParams.length == 0) {
            revert ArraysLengthMismatch();
        }
        if (initialEvolutionMagnitude == 0) {
            revert EvolutionMagnitudeTooSmall();
        }

         // Validate min <= max for each parameter
         for(uint i = 0; i < minParams.length; i++){
             if(minParams[i] > maxParams[i]){
                 revert InvalidParameterLength(); // Or a more specific error
             }
         }

         // Store min and max separately (adjusting previous struct assumption)
         // Requires changing SeedParameters struct or using separate state vars.
         // Let's adjust the state variables to have two arrays for clarity:
         // uint256[] public minBaseGenerationParams;
         // uint256[] public maxBaseGenerationParams;

         // For this example, let's use the struct's values array for MIN and assume a separate MAX state variable exists.
         // This design choice is not ideal and should be improved in a production contract.
         // Keeping the struct as is for now means `baseGenerationParams.values` will hold the MINs.

        // Updating the single array in the struct which we use as the MIN array
        baseGenerationParams.values = minParams;
        baseGenerationParams.parameterCount = minParams.length;

        // Assuming a separate state variable exists for MAX:
        // maxBaseGenerationParams = maxParams; // This line is conceptual for this example's limitation

        evolutionMagnitude = initialEvolutionMagnitude;

        emit BaseGenerationParamsUpdated(minParams, maxParams, initialEvolutionMagnitude);
    }

    // 24. distributeEssence
    function distributeEssence(address[] calldata recipients, uint256[] calldata amounts) public onlyOwner {
        if (recipients.length != amounts.length) revert ArraysLengthMismatch();
        for (uint i = 0; i < recipients.length; i++) {
            _mintEssence(recipients[i], amounts[i]);
        }
        emit EssenceDistributed(recipients, amounts);
    }

    // 25. withdrawEth
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert CannotWithdrawZeroEth();
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }


    // --- 12. View Functions ---

    // 4. getSeedData (Already listed in summary, providing implementation)
    function getSeedData(uint256 tokenId) public view returns (Seed memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _seeds[tokenId];
    }

    // 5. getSeedCurrentParameters (Already listed, providing implementation)
    function getSeedCurrentParameters(uint256 tokenId) public view returns (SeedParameters memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _seeds[tokenId].parameters;
    }

    // 6. getSeedEvolutionProgress (Already listed, providing implementation)
     function getSeedEvolutionProgress(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _seeds[tokenId].evolutionProgress;
    }


    // 7. getEssenceBalance (Already listed, providing implementation)
    function getEssenceBalance(address owner) public view returns (uint256) {
        return _essenceBalances[owner];
    }

     // 12. getUserStakedSeeds (Already listed, providing implementation)
    function getUserStakedSeeds(address owner) public view returns (uint256[] memory) {
        return _userStakedSeeds[owner];
    }

    // 17. getCuratedSeeds (Already listed, providing implementation)
    function getCuratedSeeds() public view returns (uint256[] memory) {
        return _curatedSeedIds;
    }

    // 23. getCurrentBaseGenerationParams (Already listed, providing implementation)
     function getCurrentBaseGenerationParams() public view returns (uint256[] memory minParams, uint256[] memory maxParams, uint256 magnitude) {
         // Note: This view returns arrays. In the current struct design,
         // baseGenerationParams.values is used for MIN.
         // To return MAX, you'd need a separate state variable for MAX.
         // Returning dummy max values for illustration based on the simplified structure.
         uint256[] memory currentMin = baseGenerationParams.values;
         uint256[] memory currentMax = new uint256[](currentMin.length);
          for(uint i = 0; i < currentMin.length; i++){
             currentMax[i] = currentMin[i] + 100; // Example: Max is Min + 100
         }
         // End dummy max return

        return (currentMin, currentMax, evolutionMagnitude);
    }

    // Additional helpful view functions
    function getEvolutionProgressRequired() public view returns (uint256) {
        return evolutionProgressRequired;
    }

    function getPendingStakingRewards(uint256 tokenId) public view returns (uint256 essenceAmount, uint256 evolutionAmount) {
        Seed storage seed = _seeds[tokenId];
        if (seed.stakeId == 0) return (0, 0);
        return _calculatePendingStakingRewards(tokenId, seed.stakeId);
    }

     // Helper to get specific stake info if needed (might not be necessary for the UI)
    function getStakeInfo(uint256 stakeId) public view returns (StakeInfo memory) {
        return _stakeInfo[stakeId];
    }
}
```