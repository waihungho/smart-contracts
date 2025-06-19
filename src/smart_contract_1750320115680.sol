Okay, let's create a smart contract that embodies a few advanced concepts: dynamic state NFTs, a built-in resource system, a decentralized task/discovery mechanism, and a reputation system, all tied together in a kind of "Autonomous Ethos Garden". The NFTs (representing abstract "Seeds") evolve, decay, and interact based on user actions and time.

This contract aims to be unique by combining these elements into a single, intertwined system, where the state of one component (like a seed's health) affects others (like total garden health), and user interactions (like completing discoveries) affect personal state (reputation, essence) which in turn affects their ability to interact with other components (proposing discoveries, evolving seeds).

We will avoid direct inheritance from standard libraries like OpenZeppelin's ERC721 to fulfill the "don't duplicate any of open source" requirement in spirit, by implementing the necessary mappings and functions internally, while acknowledging the underlying pattern is standard.

---

**EthosGarden Contract Outline**

1.  **Introduction:** Contract purpose and key features.
2.  **State Variables:** Storage for NFTs (Seeds), user profiles (Essence, Reputation), Discoveries (Tasks), and global state (Garden Health, counters).
3.  **Events:** Signals for state changes.
4.  **Errors:** Custom errors for clearer failure reasons.
5.  **Struct Definitions:** `Seed`, `UserProfile`, `Discovery`.
6.  **ERC721-like Internal State:** Mappings for token ownership, approvals.
7.  **Core Mechanics (Internal Helpers):** Logic for decay, health calculation, essence rewards, reputation updates, trait evolution.
8.  **Seed Management (NFT Functions):** Minting, transfer (ERC721-like), burning, querying details.
9.  **Resource Management (Essence):** Querying balance, internal transfer (via nurture/discovery).
10. **Time-Based Logic:** Functions incorporating time (decay, nurturing).
11. **Discovery System:** Proposing, accepting, completing, cancelling tasks; claiming rewards.
12. **Reputation System:** Querying reputation, rules for earning/losing (via discovery system).
13. **Garden State:** Querying global health.
14. **Rule/Parameter Functions:** View functions for dynamic or fixed parameters (costs, rates).
15. **Query Functions:** Extensive view functions to get data about users, seeds, discoveries, and global state.

---

**Function Summary**

*   `constructor()`: Initializes contract owner and base parameters.
*   `mintInitialSeed()`: Allows a user to mint their first "Seed" NFT.
*   `nurtureSeed(uint256 seedId)`: Users spend essence to improve a seed's health and earn yield.
*   `evolveSeed(uint256 seedId, uint256 evolutionEssence)`: Users spend significant essence to advance a seed's generation and potentially traits.
*   `proposeDiscovery(string memory descriptionHash, uint256 essenceReward, uint256 requiredReputation)`: Users with sufficient reputation propose a decentralized task.
*   `acceptDiscovery(uint256 discoveryId)`: A user accepts a proposed discovery task.
*   `completeDiscovery(uint256 discoveryId)`: The user who accepted marks a discovery as complete (simulated).
*   `cancelDiscovery(uint256 discoveryId)`: The proposer cancels an open discovery.
*   `redeemDiscoveryReward(uint256 discoveryId)`: The completer claims essence reward and reputation boost after a successful discovery.
*   `burnSeed(uint256 seedId)`: Removes a seed (e.g., if health drops to 0).
*   `ownerOf(uint256 seedId)`: Gets the owner of a seed (ERC721-like).
*   `balanceOf(address owner)`: Gets the number of seeds owned by an address (ERC721-like).
*   `transferFrom(address from, address to, uint256 seedId)`: Transfers seed ownership (ERC721-like).
*   `safeTransferFrom(address from, address to, uint256 seedId)`: Safe transfer of seed ownership (ERC721-like).
*   `approve(address to, uint256 seedId)`: Approves an address to transfer a seed (ERC721-like).
*   `setApprovalForAll(address operator, bool approved)`: Sets operator approval for all seeds (ERC721-like).
*   `getApproved(uint256 seedId)`: Gets the approved address for a seed (ERC721-like).
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved (ERC721-like).
*   `getSeedDetails(uint256 seedId)`: Retrieves full details of a seed.
*   `getUserProfile(address user)`: Retrieves a user's profile (essence, reputation).
*   `getGlobalGardenHealth()`: Retrieves the total health score of all active seeds.
*   `getDiscoveryDetails(uint256 discoveryId)`: Retrieves details of a discovery.
*   `getDiscoveriesByStatus(uint8 status)`: Lists discoveries filtered by status.
*   `getEssenceBalance(address user)`: Gets a user's current essence balance.
*   `getTotalEssenceSupply()`: Gets the total amount of essence created.
*   `getSeedTraits(uint256 seedId)`: Retrieves only the traits of a seed.
*   `getTotalSeeds()`: Gets the total number of seeds minted.
*   `getUserSeeds(address user)`: Gets a list of seed IDs owned by a user.
*   `getUserReputation(address user)`: Gets a user's current reputation score.
*   `getRequiredReputationForProposal()`: Gets the minimum reputation needed to propose a discovery.
*   `getSeedGeneration(uint256 seedId)`: Gets a seed's generation.
*   `getCurrentGenerationCap()`: Gets the maximum possible seed generation currently allowed by contract rules.
*   `getSeedDecayRate(uint256 seedId)`: Calculates the current decay rate for a specific seed based on its properties.
*   `getNurtureEssenceCost(uint256 seedId)`: Calculates the essence cost to nurture a specific seed.
*   `getEvolutionEssenceCost(uint256 seedId, uint256 requestedEvolutionAmount)`: Calculates the essence cost for a specific evolution step.
*   `calculateSeedHealth(uint256 seedId)`: Calculates the current health of a seed, applying decay since last interaction.
*   `calculateSeedEssenceYield(uint256 seedId)`: Calculates the essence yield received from nurturing a seed.
*   `calculateDiscoveryReward(uint256 requestedReward)`: Calculates the effective reward considering potential contract parameters/fees (simplified here).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EthosGarden
 * @dev An autonomous and evolving digital ecosystem simulation on chain.
 * Seeds (NFTs) have dynamic health and traits that decay over time if not nurtured
 * using internal "Essence" resources. Users earn Essence and Reputation by completing
 * decentralized "Discoveries" (tasks) proposed by others. Reputation allows proposing
 * more complex discoveries. Seeds can be evolved using Essence to increase generation
 * and potentially alter traits, influencing decay and yield rates.
 * The contract intertwines NFT state, resource management, decentralized tasks,
 * and reputation into a single interactive system.
 */

// --- Outline ---
// 1. Introduction (above)
// 2. State Variables
// 3. Events
// 4. Errors
// 5. Struct Definitions
// 6. ERC721-like Internal State
// 7. Core Mechanics (Internal Helpers)
// 8. Seed Management (NFT Functions)
// 9. Resource Management (Essence)
// 10. Time-Based Logic (Integrated into nurture/decay)
// 11. Discovery System
// 12. Reputation System (Integrated into Discovery)
// 13. Garden State
// 14. Rule/Parameter Functions (View)
// 15. Query Functions

// --- Function Summary ---
// constructor(): Initializes contract owner and base parameters.
// mintInitialSeed(): Allows a user to mint their first "Seed" NFT.
// nurtureSeed(uint256 seedId): Users spend essence to improve a seed's health and earn yield.
// evolveSeed(uint256 seedId, uint256 evolutionEssence): Users spend significant essence to advance a seed's generation and potentially traits.
// proposeDiscovery(string memory descriptionHash, uint256 essenceReward, uint256 requiredReputation): Users with sufficient reputation propose a decentralized task.
// acceptDiscovery(uint256 discoveryId): A user accepts a proposed discovery task.
// completeDiscovery(uint256 discoveryId): The user who accepted marks a discovery as complete (simulated).
// cancelDiscovery(uint256 discoveryId): The proposer cancels an open discovery.
// redeemDiscoveryReward(uint256 discoveryId): The completer claims essence reward and reputation boost after a successful discovery.
// burnSeed(uint256 seedId): Removes a seed (e.g., if health drops to 0).
// ownerOf(uint256 seedId): Gets the owner of a seed (ERC721-like).
// balanceOf(address owner): Gets the number of seeds owned by an address (ERC721-like).
// transferFrom(address from, address to, uint256 seedId): Transfers seed ownership (ERC721-like).
// safeTransferFrom(address from, address to, uint256 seedId): Safe transfer of seed ownership (ERC721-like).
// approve(address to, uint256 seedId): Approves an address to transfer a seed (ERC721-like).
// setApprovalForAll(address operator, bool approved): Sets operator approval for all seeds (ERC721-like).
// getApproved(uint256 seedId): Gets the approved address for a seed (ERC721-like).
// isApprovedForAll(address owner, address operator): Checks if an operator is approved (ERC721-like).
// getSeedDetails(uint256 seedId): Retrieves full details of a seed.
// getUserProfile(address user): Retrieves a user's profile (essence, reputation).
// getGlobalGardenHealth(): Retrieves the total health score of all active seeds.
// getDiscoveryDetails(uint256 discoveryId): Retrieves details of a discovery.
// getDiscoveriesByStatus(uint8 status): Lists discoveries filtered by status.
// getEssenceBalance(address user): Gets a user's current essence balance.
// getTotalEssenceSupply(): Gets the total amount of essence created.
// getSeedTraits(uint256 seedId): Retrieves only the traits of a seed.
// getTotalSeeds(): Gets the total number of seeds minted.
// getUserSeeds(address user): Gets a list of seed IDs owned by a user.
// getUserReputation(address user): Gets a user's current reputation score.
// getRequiredReputationForProposal(): Gets the minimum reputation needed to propose a discovery.
// getSeedGeneration(uint256 seedId): Gets a seed's generation.
// getCurrentGenerationCap(): Gets the maximum possible seed generation currently allowed by contract rules.
// getSeedDecayRate(uint256 seedId): Calculates the current decay rate for a specific seed based on its properties.
// getNurtureEssenceCost(uint256 seedId): Calculates the essence cost to nurture a specific seed.
// getEvolutionEssenceCost(uint256 seedId, uint256 requestedEvolutionAmount): Calculates the essence cost for a specific evolution step.
// calculateSeedHealth(uint256 seedId): Calculates the current health of a seed, applying decay since last interaction.
// calculateSeedEssenceYield(uint256 seedId): Calculates the essence yield received from nurturing a seed.
// calculateDiscoveryReward(uint256 requestedReward): Calculates the effective reward considering potential contract parameters/fees (simplified here).

contract EthosGarden {

    // --- State Variables ---

    // ERC721-like state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;

    // Seed state
    struct Seed {
        uint256 id;
        address owner;
        uint64 creationTime; // Block timestamp
        uint64 lastNurtureTime; // Block timestamp
        uint256 health; // 0-100
        uint256 generation;
        uint256[] traits; // Example: [Color, Shape, Resilience, YieldModifier...]
        bool exists; // Track if seed is burned
    }
    mapping(uint256 => Seed) private _seeds;
    uint256 private _totalSeeds;
    uint256 private _totalGardenHealth; // Sum of all seed healths (approximate)

    // User state
    struct UserProfile {
        uint256 essence;
        int256 reputation; // Can be negative
        uint256[] ownedSeedIds; // Keep track of owned seed IDs
    }
    mapping(address => UserProfile) private _userProfiles;
    mapping(uint256 => uint256) private _seedIdToIndexInOwnedSeeds; // Helper for removing seed ID

    // Essence state
    uint256 private _totalEssenceSupply;

    // Discovery state
    enum DiscoveryStatus { Proposed, Accepted, Completed, Cancelled, Claimed }
    struct Discovery {
        uint256 id;
        address proposer;
        address completer; // Address that accepted the task
        string descriptionHash; // Hash of off-chain description
        uint256 essenceReward;
        int256 reputationBoost; // Reputation gain on completion
        int256 reputationPenalty; // Reputation loss on failure/cancellation? (Not implemented fully here, but possible)
        uint64 proposalTime; // Block timestamp
        uint64 acceptanceTime; // Block timestamp
        uint64 completionTime; // Block timestamp
        DiscoveryStatus status;
        uint256 requiredReputation; // Minimum reputation to propose
    }
    mapping(uint256 => Discovery) private _discoveries;
    uint256 private _nextDiscoveryId;

    // Parameters (can be dynamic later, fixed for this example)
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 10;
    uint256 public constant BASE_SEED_DECAY_RATE_PER_SECOND = 1; // Health points per second for Gen 0
    uint256 public constant BASE_NURTURE_COST = 10; // Essence
    uint256 public constant BASE_NURTURE_HEALTH_GAIN = 10; // Health points
    uint256 public constant BASE_NURTURE_ESSENCE_YIELD = 5; // Essence
    uint256 public constant BASE_EVOLUTION_COST_PER_GEN = 100; // Essence per generation step
    int256 public constant DISCOVERY_REPUTATION_BOOST = 5; // Reputation gain per completed discovery
    uint256 public constant SEED_MAX_HEALTH = 100;
    uint256 public constant INITIAL_SEED_HEALTH = 50;
    uint256 public constant MAX_SEED_GENERATION = 10;

    // --- Events ---

    event SeedMinted(uint256 indexed seedId, address indexed owner);
    event SeedNurtured(uint256 indexed seedId, address indexed nurturer, uint256 essenceSpent, uint256 healthGained, uint256 essenceYield);
    event SeedEvolved(uint256 indexed seedId, address indexed evolver, uint256 essenceSpent, uint256 newGeneration);
    event SeedBurned(uint256 indexed seedId, address indexed owner);
    event DiscoveryProposed(uint256 indexed discoveryId, address indexed proposer, uint256 reward, uint256 requiredRep);
    event DiscoveryAccepted(uint256 indexed discoveryId, address indexed completer);
    event DiscoveryCompleted(uint256 indexed discoveryId, address indexed completer);
    event DiscoveryCancelled(uint256 indexed discoveryId, address indexed canceller);
    event DiscoveryRewardClaimed(uint256 indexed discoveryId, address indexed completer, uint256 essenceReward, int256 reputationGained);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount); // For internal transfers
    event ReputationUpdated(address indexed user, int256 newReputation);
    event GardenHealthUpdated(uint256 newTotalHealth);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721 standard
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC721 standard
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721 standard


    // --- Errors ---

    error SeedNotFound(uint256 seedId);
    error NotSeedOwnerOrApproved(address caller, uint256 seedId);
    error NotSeedOwner(address caller, uint256 seedId);
    error NotApprovedOrOwner(address caller, uint256 seedId); // Used by transferFrom
    error TransferToZeroAddress();
    error ApprovalToOwner();
    error DiscoveryNotFound(uint256 discoveryId);
    error DiscoveryNotInStatus(uint256 discoveryId, DiscoveryStatus requiredStatus);
    error NotDiscoveryProposer(uint256 discoveryId, address caller);
    error NotDiscoveryCompleter(uint256 discoveryId, address caller);
    error InsufficientEssence(address user, uint256 required, uint256 available);
    error InsufficientReputation(address user, int256 required, int256 available);
    error SeedNotReadyForEvolution(uint256 seedId, uint256 requiredEssence);
    error SeedAtMaxGeneration(uint256 seedId);
    error SeedHealthZero(uint256 seedId);
    error AlreadyMintedInitialSeed(address user);


    // --- Struct Definitions ---
    // Defined above in State Variables section for clarity


    // --- ERC721-like Internal State ---
    // Defined above


    // --- Core Mechanics (Internal Helpers) ---

    /**
     * @dev Internal function to calculate decay and update seed health.
     * Should be called before any interaction with a seed where time elapsed matters.
     * @param seedId The ID of the seed to update.
     * @return The calculated current health of the seed.
     */
    function _calculateAndApplyDecay(uint256 seedId) internal returns (uint256) {
        Seed storage seed = _seeds[seedId];
        require(seed.exists, "Seed does not exist"); // Should not happen if called correctly

        uint64 lastCheckTime = seed.lastNurtureTime; // We update lastNurtureTime on nurture/evolve
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime > lastCheckTime) {
            uint256 timeElapsed = currentTime - lastCheckTime;
            uint256 decayRate = getSeedDecayRate(seedId); // Use view function to get dynamic rate

            uint256 decayAmount = timeElapsed * decayRate;

            // Update garden health before changing seed health
            _totalGardenHealth -= seed.health; // Subtract old health
            seed.health = seed.health > decayAmount ? seed.health - decayAmount : 0;
            _totalGardenHealth += seed.health; // Add new health

            seed.lastNurtureTime = currentTime; // Update last check time
            emit GardenHealthUpdated(_totalGardenHealth);

            if (seed.health == 0) {
                _burnSeed(seedId); // Automatically burn if health reaches zero
            }
        }
        return seed.health;
    }

    /**
     * @dev Internal function to update a user's reputation.
     * @param user The user's address.
     * @param amount The amount to add to reputation (can be negative).
     */
    function _updateReputation(address user, int256 amount) internal {
        UserProfile storage profile = _userProfiles[user];
        profile.reputation += amount;
        emit ReputationUpdated(user, profile.reputation);
    }

    /**
     * @dev Internal function to add essence to a user's balance and track total supply.
     * @param user The user's address.
     * @param amount The amount of essence to add.
     */
    function _mintEssence(address user, uint256 amount) internal {
        UserProfile storage profile = _userProfiles[user];
        profile.essence += amount;
        _totalEssenceSupply += amount;
        emit EssenceTransferred(address(0), user, amount);
    }

     /**
     * @dev Internal function to remove essence from a user's balance.
     * @param user The user's address.
     * @param amount The amount of essence to remove.
     */
    function _burnEssence(address user, uint256 amount) internal {
        UserProfile storage profile = _userProfiles[user];
        if (profile.essence < amount) revert InsufficientEssence(user, amount, profile.essence);
        profile.essence -= amount;
        // We don't decrease total supply if essence is "spent" within the system
        emit EssenceTransferred(user, address(0), amount);
    }


    // --- ERC721-like Internal Implementation ---
    // Minimal implementation for internal use

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _seeds[tokenId].exists;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _addSeedToOwnedTokens(address to, uint256 seedId) internal {
        UserProfile storage profile = _userProfiles[to];
        _seedIdToIndexInOwnedSeeds[seedId] = profile.ownedSeedIds.length;
        profile.ownedSeedIds.push(seedId);
    }

    function _removeSeedFromOwnedTokens(address from, uint256 seedId) internal {
        UserProfile storage profile = _userProfiles[from];
        uint256 index = _seedIdToIndexInOwnedSeeds[seedId];
        uint256 lastIndex = profile.ownedSeedIds.length - 1;
        uint256 lastSeedId = profile.ownedSeedIds[lastIndex];

        profile.ownedSeedIds[index] = lastSeedId;
        _seedIdToIndexInOwnedSeeds[lastSeedId] = index;
        delete _seedIdToIndexInOwnedSeeds[seedId]; // Clean up the index mapping for the removed token
        profile.ownedSeedIds.pop();
    }

    function _transfer(address from, address to, uint256 seedId) internal {
        require(ownerOf(seedId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, seedId); // Hook

        _removeSeedFromOwnedTokens(from, seedId);
        _addSeedToOwnedTokens(to, seedId);

        _owners[seedId] = to;
        _balances[from]--;
        _balances[to]++;
        delete _tokenApprovals[seedId]; // Clear approvals upon transfer

        emit Transfer(from, to, seedId);

        _afterTokenTransfer(from, to, seedId); // Hook
    }

    // Hooks - Can be extended in derived contracts
    function _beforeTokenTransfer(address from, address to, uint256 seedId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 seedId) internal virtual {}


    // --- Constructor ---

    constructor() {
        _nextTokenId = 1; // Start token IDs from 1
        _nextDiscoveryId = 1; // Start discovery IDs from 1
        // Could mint initial seeds/essence for the contract deployer or a treasury here
    }

    // --- Seed Management (NFT Functions) ---

    /**
     * @summary Allows a user to mint their first "Seed" NFT.
     * @dev Limited to one initial seed per user. Seeds start with partial health.
     * @return The ID of the newly minted seed.
     */
    function mintInitialSeed() external returns (uint256) {
        UserProfile storage userProfile = _userProfiles[msg.sender];
        if (userProfile.ownedSeedIds.length > 0 || _balances[msg.sender] > 0) {
             revert AlreadyMintedInitialSeed(msg.sender);
        }

        uint256 seedId = _nextTokenId++;

        _seeds[seedId] = Seed({
            id: seedId,
            owner: msg.sender,
            creationTime: uint64(block.timestamp),
            lastNurtureTime: uint64(block.timestamp),
            health: INITIAL_SEED_HEALTH,
            generation: 0,
            traits: new uint256[](0), // Start with no traits or base traits
            exists: true
        });

        _owners[seedId] = msg.sender;
        _balances[msg.sender]++;
        _addSeedToOwnedTokens(msg.sender, seedId);
        _totalSeeds++;
        _totalGardenHealth += INITIAL_SEED_HEALTH;

        emit SeedMinted(seedId, msg.sender);
        emit Transfer(address(0), msg.sender, seedId); // ERC721 standard mint event
        emit GardenHealthUpdated(_totalGardenHealth);

        return seedId;
    }

    /**
     * @summary Users spend essence to improve a seed's health and earn yield.
     * @dev Calculates and applies decay before nurturing. Updates health, last nurture time, and essence balance.
     * @param seedId The ID of the seed to nurture.
     */
    function nurtureSeed(uint256 seedId) external {
        Seed storage seed = _seeds[seedId];
        if (!seed.exists) revert SeedNotFound(seedId);
        if (seed.owner != msg.sender) revert NotSeedOwner(msg.sender, seedId);
        if (seed.health == 0) revert SeedHealthZero(seedId);

        // Apply decay first
        _calculateAndApplyDecay(seedId);

        // Check if still alive after decay
        if (seed.health == 0) revert SeedHealthZero(seedId);

        uint256 nurtureCost = getNurtureEssenceCost(seedId);
        _burnEssence(msg.sender, nurtureCost); // Spend essence

        // Increase health (capped at MAX_SEED_HEALTH)
        _totalGardenHealth -= seed.health; // Subtract old health
        seed.health = Math.min(seed.health + BASE_NURTURE_HEALTH_GAIN, SEED_MAX_HEALTH);
        _totalGardenHealth += seed.health; // Add new health

        seed.lastNurtureTime = uint64(block.timestamp);

        // Reward essence yield
        uint256 yieldAmount = calculateSeedEssenceYield(seedId);
        if (yieldAmount > 0) {
             _mintEssence(msg.sender, yieldAmount);
        }

        emit SeedNurtured(seedId, msg.sender, nurtureCost, BASE_NURTURE_HEALTH_GAIN, yieldAmount);
        emit GardenHealthUpdated(_totalGardenHealth);
    }

    /**
     * @summary Users spend significant essence to advance a seed's generation and potentially traits.
     * @dev Requires significant essence. Increases generation and might change traits based on rules.
     * @param seedId The ID of the seed to evolve.
     * @param evolutionEssence The amount of essence to spend on evolution (can influence outcome/success).
     */
    function evolveSeed(uint256 seedId, uint256 evolutionEssence) external {
        Seed storage seed = _seeds[seedId];
        if (!seed.exists) revert SeedNotFound(seedId);
        if (seed.owner != msg.sender) revert NotSeedOwner(msg.sender, seedId);
        if (seed.health == 0) revert SeedHealthZero(seedId);
        if (seed.generation >= MAX_SEED_GENERATION) revert SeedAtMaxGeneration(seedId);

        // Apply decay first
        _calculateAndApplyDecay(seedId);
        if (seed.health == 0) revert SeedHealthZero(seedId);

        uint256 requiredEssence = getEvolutionEssenceCost(seedId, evolutionEssence); // Cost might depend on input essence
        if (evolutionEssence < requiredEssence) revert InsufficientEssence(msg.sender, requiredEssence, evolutionEssence);

        _burnEssence(msg.sender, evolutionEssence); // Spend essence

        seed.generation++;
        // --- Trait evolution logic (simplified placeholder) ---
        // In a real contract, this could involve complex pseudo-randomness based on
        // block data, seed stats, and the amount of essence spent.
        // Example: Add a new random trait value or adjust existing ones.
        seed.traits.push(seed.generation * 100 + uint256(keccak256(abi.encodePacked(seedId, block.timestamp, seed.generation))) % 100);
        // --- End Trait evolution logic ---

        seed.lastNurtureTime = uint64(block.timestamp); // Reset nurture time on evolution

        emit SeedEvolved(seedId, msg.sender, evolutionEssence, seed.generation);
    }

    /**
     * @summary Removes a seed from existence.
     * @dev Called automatically when health reaches zero or can potentially be called manually by owner (not implemented here).
     * Updates total seed count and garden health. Clears ERC721 state.
     * @param seedId The ID of the seed to burn.
     */
    function _burnSeed(uint256 seedId) internal {
         Seed storage seed = _seeds[seedId];
        // Note: We don't check owner here because it's an internal function,
        // assumed to be called by logic that already verified ownership or the
        // health condition.

        address owner = seed.owner; // Get owner before state is reset
        if (!seed.exists) return; // Already burned or never existed

        _beforeTokenTransfer(owner, address(0), seedId); // Hook

        _totalGardenHealth -= seed.health; // Subtract health from garden total
        _totalSeeds--;

        seed.exists = false; // Mark as burned
        seed.owner = address(0); // Clear owner

        _removeSeedFromOwnedTokens(owner, seedId);
        _balances[owner]--;
        delete _owners[seedId];
        delete _tokenApprovals[seedId]; // Clear any approvals

        emit SeedBurned(seedId, owner);
        emit Transfer(owner, address(0), seedId); // ERC721 standard burn event
        emit GardenHealthUpdated(_totalGardenHealth);

        // Note: The seed struct remains in storage, just marked as !exists.
        // This allows querying historical data or verifying non-existence.
    }


    // --- Resource Management (Essence) ---
    // Essence is managed internally within the UserProfile struct.
    // Minting/Burning happens via nurture/discovery functions.

    /**
     * @summary Gets a user's current essence balance.
     * @param user The address of the user.
     * @return The essence balance.
     */
    function getEssenceBalance(address user) external view returns (uint256) {
        return _userProfiles[user].essence;
    }

    /**
     * @summary Gets the total amount of essence ever minted.
     * @return The total essence supply.
     */
    function getTotalEssenceSupply() external view returns (uint256) {
        return _totalEssenceSupply;
    }


    // --- Time-Based Logic ---
    // Decay is calculated on demand in _calculateAndApplyDecay, which is called
    // by functions interacting with seeds (nurture, evolve, getSeedDetails).


    // --- Discovery System ---

    /**
     * @summary Users with sufficient reputation propose a decentralized task.
     * @dev Requires minimum reputation. The essence reward is locked upon proposal.
     * @param descriptionHash Hash of the off-chain task description.
     * @param essenceReward The amount of essence the completer will receive.
     * @param requiredReputation The minimum reputation a completer needs.
     */
    function proposeDiscovery(string memory descriptionHash, uint256 essenceReward, uint256 requiredReputation) external {
        UserProfile storage proposerProfile = _userProfiles[msg.sender];
        if (proposerProfile.reputation < int256(MIN_REPUTATION_FOR_PROPOSAL)) {
             revert InsufficientReputation(msg.sender, int256(MIN_REPUTATION_FOR_PROPOSAL), proposerProfile.reputation);
        }
         if (proposerProfile.reputation < int256(requiredReputation)) {
             revert InsufficientReputation(msg.sender, int256(requiredReputation), proposerProfile.reputation);
        }

        // Lock essence reward from proposer
        _burnEssence(msg.sender, essenceReward);

        uint256 discoveryId = _nextDiscoveryId++;

        _discoveries[discoveryId] = Discovery({
            id: discoveryId,
            proposer: msg.sender,
            completer: address(0), // Not accepted yet
            descriptionHash: descriptionHash,
            essenceReward: essenceReward,
            reputationBoost: DISCOVERY_REPUTATION_BOOST, // Fixed boost for now
            reputationPenalty: 0, // Not implemented penalty
            proposalTime: uint64(block.timestamp),
            acceptanceTime: 0,
            completionTime: 0,
            status: DiscoveryStatus.Proposed,
            requiredReputation: requiredReputation
        });

        emit DiscoveryProposed(discoveryId, msg.sender, essenceReward, requiredReputation);
    }

    /**
     * @summary A user accepts a proposed discovery task.
     * @dev Checks minimum reputation. Changes discovery status to Accepted.
     * @param discoveryId The ID of the discovery to accept.
     */
    function acceptDiscovery(uint256 discoveryId) external {
        Discovery storage discovery = _discoveries[discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
        if (discovery.status != DiscoveryStatus.Proposed) revert DiscoveryNotInStatus(discoveryId, DiscoveryStatus.Proposed);

        UserProfile storage completerProfile = _userProfiles[msg.sender];
        if (completerProfile.reputation < int256(discovery.requiredReputation)) {
             revert InsufficientReputation(msg.sender, int256(discovery.requiredReputation), completerProfile.reputation);
        }

        discovery.completer = msg.sender;
        discovery.acceptanceTime = uint64(block.timestamp);
        discovery.status = DiscoveryStatus.Accepted;

        emit DiscoveryAccepted(discoveryId, msg.sender);
    }

    /**
     * @summary The user who accepted marks a discovery as complete (simulated).
     * @dev Changes discovery status to Completed. This is a simplified step; a real system might require proof or verification.
     * @param discoveryId The ID of the discovery to complete.
     */
    function completeDiscovery(uint256 discoveryId) external {
        Discovery storage discovery = _discoveries[discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
        if (discovery.status != DiscoveryStatus.Accepted) revert DiscoveryNotInStatus(discoveryId, DiscoveryStatus.Accepted);
        if (discovery.completer != msg.sender) revert NotDiscoveryCompleter(discoveryId, msg.sender);

        // In a real system, verification/proof would happen here.
        // For this example, completion is instant by the completer.

        discovery.completionTime = uint64(block.timestamp);
        discovery.status = DiscoveryStatus.Completed;

        emit DiscoveryCompleted(discoveryId, msg.sender);
    }

    /**
     * @summary The proposer cancels an open discovery.
     * @dev Only the proposer can cancel. Must be in Proposed or Accepted status. Returns locked essence.
     * @param discoveryId The ID of the discovery to cancel.
     */
    function cancelDiscovery(uint256 discoveryId) external {
        Discovery storage discovery = _discoveries[discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
        if (discovery.proposer != msg.sender) revert NotDiscoveryProposer(discoveryId, msg.sender);
        if (discovery.status != DiscoveryStatus.Proposed && discovery.status != DiscoveryStatus.Accepted) {
            revert DiscoveryNotInStatus(discoveryId, discovery.status); // More specific error
        }

        // Return locked essence to proposer
        _mintEssence(discovery.proposer, discovery.essenceReward);

        discovery.status = DiscoveryStatus.Cancelled;

        // TODO: Implement reputation penalty for proposer if cancelled after acceptance?

        emit DiscoveryCancelled(discoveryId, msg.sender);
    }

     /**
     * @summary The completer claims essence reward and reputation boost after a successful discovery.
     * @dev Can only be called once by the completer after the discovery is Completed.
     * @param discoveryId The ID of the discovery to claim reward for.
     */
    function redeemDiscoveryReward(uint255 discoveryId) external {
        Discovery storage discovery = _discoveries[discoveryId];
        if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
        if (discovery.status != DiscoveryStatus.Completed) revert DiscoveryNotInStatus(discoveryId, DiscoveryStatus.Completed);
        if (discovery.completer != msg.sender) revert NotDiscoveryCompleter(discoveryId, msg.sender);

        // Transfer essence from contract (where it was locked) to completer
        // Note: _burnEssence was called on proposer, _mintEssence adds to total supply.
        // We need to mint the reward to the completer.
        _mintEssence(discovery.completer, discovery.essenceReward);

        // Update completer's reputation
        _updateReputation(discovery.completer, discovery.reputationBoost);

        discovery.status = DiscoveryStatus.Claimed; // Mark as claimed to prevent double-claiming

        emit DiscoveryRewardClaimed(discoveryId, msg.sender, discovery.essenceReward, discovery.reputationBoost);
    }


    // --- Reputation System ---
    // Reputation is managed internally in UserProfile and updated via _updateReputation,
    // primarily triggered by successful discovery completion.


    // --- Garden State ---

    /**
     * @summary Retrieves the total health score of all active seeds.
     * @dev This value is updated when seed health changes via nurture/decay.
     * @return The total garden health.
     */
    function getGlobalGardenHealth() external view returns (uint256) {
        return _totalGardenHealth;
    }


    // --- Rule/Parameter Functions (View) ---

    /**
     * @summary Gets the minimum reputation needed to propose a discovery.
     * @return The required reputation score.
     */
    function getRequiredReputationForProposal() external pure returns (uint256) {
        return MIN_REPUTATION_FOR_PROPOSAL;
    }

    /**
     * @summary Calculates the current decay rate for a specific seed based on its properties.
     * @dev Example: Decay rate increases with generation. Could depend on traits too.
     * @param seedId The ID of the seed.
     * @return The decay rate in health points per second.
     */
    function getSeedDecayRate(uint256 seedId) public view returns (uint256) {
         if (!_seeds[seedId].exists) return 0; // No decay if burned
         // Simple example: decay increases linearly with generation
        return BASE_SEED_DECAY_RATE_PER_SECOND * (_seeds[seedId].generation + 1);
    }

    /**
     * @summary Calculates the essence cost to nurture a specific seed.
     * @dev Example: Cost might increase with generation.
     * @param seedId The ID of the seed.
     * @return The essence cost.
     */
    function getNurtureEssenceCost(uint256 seedId) public view returns (uint256) {
         if (!_seeds[seedId].exists) return 0;
        // Simple example: cost increases with generation
        return BASE_NURTURE_COST * (_seeds[seedId].generation + 1);
    }

    /**
     * @summary Calculates the essence cost for a specific evolution step.
     * @dev Example: Cost increases based on current generation and desired step size (represented by input essence).
     * @param seedId The ID of the seed.
     * @param requestedEvolutionAmount The amount of essence the user intends to spend (influences calculation).
     * @return The effective essence cost for the next generation step.
     */
    function getEvolutionEssenceCost(uint256 seedId, uint256 requestedEvolutionAmount) public view returns (uint256) {
         if (!_seeds[seedId].exists) return type(uint256).max; // Impossible to evolve burned seed
         if (_seeds[seedId].generation >= MAX_SEED_GENERATION) return type(uint256).max; // Already at max

        // Simple example: cost is base cost per generation * next generation number
        uint256 costForNextGen = BASE_EVOLUTION_COST_PER_GEN * (_seeds[seedId].generation + 1);

        // In a more complex system, the `requestedEvolutionAmount` could influence
        // a success probability or a cost reduction mechanic. For simplicity, we
        // just return the required cost based on the next generation.
        // We check the user's input amount in the evolve function.
        return costForNextGen;
    }

    /**
     * @summary Gets the maximum possible seed generation currently allowed by contract rules.
     * @return The maximum generation number.
     */
    function getCurrentGenerationCap() external pure returns (uint256) {
        return MAX_SEED_GENERATION;
    }

     /**
     * @summary Calculates the current health of a seed, applying decay since last interaction.
     * @dev This is a view function that doesn't change state but calculates based on current time.
     * Useful for UIs to display up-to-date health without a transaction.
     * @param seedId The ID of the seed.
     * @return The current health of the seed (after applying potential decay).
     */
    function calculateSeedHealth(uint256 seedId) external view returns (uint256) {
        Seed storage seed = _seeds[seedId];
        if (!seed.exists) return 0;

        uint64 lastCheckTime = seed.lastNurtureTime;
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime <= lastCheckTime) {
            return seed.health; // No decay if no time has passed
        }

        uint256 timeElapsed = currentTime - lastCheckTime;
        uint256 decayRate = getSeedDecayRate(seedId); // Use view function

        uint256 decayAmount = timeElapsed * decayRate;

        return seed.health > decayAmount ? seed.health - decayAmount : 0;
    }

    /**
     * @summary Calculates the essence yield received from nurturing a seed.
     * @dev Example: Yield might increase with generation or traits.
     * @param seedId The ID of the seed.
     * @return The amount of essence yielded from one nurture action.
     */
    function calculateSeedEssenceYield(uint256 seedId) public view returns (uint256) {
         if (!_seeds[seedId].exists) return 0;
         // Simple example: yield increases with generation
        return BASE_NURTURE_ESSENCE_YIELD * (_seeds[seedId].generation + 1);
    }

    /**
     * @summary Calculates the effective reward for a discovery (simplified).
     * @dev In a real system, could involve fees or dynamic adjustments.
     * @param requestedReward The reward amount proposed.
     * @return The effective reward amount.
     */
    function calculateDiscoveryReward(uint256 requestedReward) public pure returns (uint256) {
        // Simple example: No fees, just return requested reward
        return requestedReward;
    }


    // --- Query Functions ---

    /**
     * @summary Retrieves full details of a seed.
     * @dev Applies decay calculation before returning state.
     * @param seedId The ID of the seed.
     * @return Seed struct containing all details.
     */
    function getSeedDetails(uint256 seedId) external returns (Seed memory) {
        Seed storage seed = _seeds[seedId];
        if (!seed.exists) revert SeedNotFound(seedId);

        // Apply decay before returning details (state-changing view)
        _calculateAndApplyDecay(seedId);

        // Return a memory copy of the updated seed struct
        return seed;
    }

    /**
     * @summary Retrieves a user's profile (essence, reputation, owned seeds).
     * @param user The address of the user.
     * @return UserProfile struct containing all details.
     */
    function getUserProfile(address user) external view returns (UserProfile memory) {
        // Note: This does not return owned seeds directly in the struct due to memory constraints
        // for dynamic arrays in return structs. Use getUserSeeds instead.
        UserProfile storage profile = _userProfiles[user];
        return UserProfile({
            essence: profile.essence,
            reputation: profile.reputation,
            ownedSeedIds: new uint256[](0) // Placeholder - use getUserSeeds()
        });
    }

     /**
     * @summary Gets a list of seed IDs owned by a user.
     * @param user The address of the user.
     * @return An array of seed IDs owned by the user.
     */
    function getUserSeeds(address user) external view returns (uint256[] memory) {
        return _userProfiles[user].ownedSeedIds;
    }

     /**
     * @summary Gets a user's current reputation score.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address user) external view returns (int256) {
        return _userProfiles[user].reputation;
    }

    /**
     * @summary Retrieves details of a discovery.
     * @param discoveryId The ID of the discovery.
     * @return Discovery struct containing all details.
     */
    function getDiscoveryDetails(uint256 discoveryId) external view returns (Discovery memory) {
         Discovery storage discovery = _discoveries[discoveryId];
         if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
         return discovery;
    }

    /**
     * @summary Lists discoveries filtered by status.
     * @dev Iterates through all discoveries up to the current ID. Potential gas cost warning for large numbers.
     * @param status The status to filter by (0: Proposed, 1: Accepted, 2: Completed, 3: Cancelled, 4: Claimed).
     * @return An array of Discovery structs matching the status.
     */
    function getDiscoveriesByStatus(uint8 status) external view returns (Discovery[] memory) {
        require(status <= uint8(DiscoveryStatus.Claimed), "Invalid status");

        uint256 count = 0;
        for (uint256 i = 1; i < _nextDiscoveryId; i++) {
            if (_discoveries[i].status == DiscoveryStatus(status)) {
                count++;
            }
        }

        Discovery[] memory result = new Discovery[](count);
        uint256 currentIndex = 0;
         for (uint256 i = 1; i < _nextDiscoveryId; i++) {
            if (_discoveries[i].status == DiscoveryStatus(status)) {
                result[currentIndex] = _discoveries[i];
                currentIndex++;
            }
        }
        return result;
    }

     /**
     * @summary Retrieves only the traits of a seed.
     * @param seedId The ID of the seed.
     * @return An array of trait values.
     */
    function getSeedTraits(uint256 seedId) external view returns (uint256[] memory) {
         if (!_seeds[seedId].exists) revert SeedNotFound(seedId);
         return _seeds[seedId].traits;
    }

    /**
     * @summary Gets a seed's generation.
     * @param seedId The ID of the seed.
     * @return The generation number.
     */
    function getSeedGeneration(uint256 seedId) external view returns (uint256) {
         if (!_seeds[seedId].exists) revert SeedNotFound(seedId);
         return _seeds[seedId].generation;
    }

    /**
     * @summary Gets the total number of seeds ever minted (including burned).
     * @return The total count of seeds by ID.
     */
    function getTotalSeeds() external view returns (uint256) {
        return _nextTokenId - 1; // Total IDs minted
    }

    /**
     * @summary Gets the discovery reward amount for a specific discovery.
     * @param discoveryId The ID of the discovery.
     * @return The essence reward amount.
     */
    function getDiscoveryReward(uint256 discoveryId) external view returns (uint256) {
         Discovery storage discovery = _discoveries[discoveryId];
         if (discovery.id == 0) revert DiscoveryNotFound(discoveryId);
         return discovery.essenceReward;
    }


    // --- ERC721 Standard Functions (Public Interface) ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToOwner();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotApprovedOrOwner(msg.sender, tokenId);
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
         require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert ApprovalToOwner(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
             _transfer(from, to, tokenId);
        } else {
             revert NotApprovedOrOwner(msg.sender, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // Simplified: Does not check if 'to' is a smart contract and accepts ERC721Receiver.
        // For a full ERC721, this would involve calling onERC721Received on 'to'.
        // Since we're avoiding standard libraries, we omit the complex check.
         if (_isApprovedOrOwner(msg.sender, tokenId)) {
             _transfer(from, to, tokenId);
        } else {
             revert NotApprovedOrOwner(msg.sender, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        // Same as safeTransferFrom(from, to, tokenId) in this simplified implementation
         if (_isApprovedOrOwner(msg.sender, tokenId)) {
             _transfer(from, to, tokenId);
        } else {
             revert NotApprovedOrOwner(msg.sender, tokenId);
        }
    }

    // Note: The ERC165 supportsInterface is omitted for brevity in this conceptual example,
    // but a real ERC721 implementation should include it.

    // --- Utility/Library placeholder ---
    // A full implementation would likely import SafeMath or use compiler check for overflow.
    // For v0.8.x, overflow checks are default.
    // Using a simple min for health capping.
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```