Okay, let's design a smart contract that represents a "Decentralized Autonomous Creator" or "Procedural Generative Asset Protocol". The concept is that users can seed digital "Fragments", which are unique, evolving digital entities/artworks/lifeforms whose properties change over time and through user interaction. The evolution process is governed by on-chain rules, potentially influenced by simulated external factors or community actions. These Fragments are represented as NFTs.

This concept is advanced because it involves managing complex, dynamic state on-chain, reacting to time and multiple interaction types, and incorporating elements of procedural generation and emergent behavior. It's creative and trendy due to the focus on generative art, evolving NFTs (Dynamic NFTs), and community-influenced digital assets.

Since the constraint is "don't duplicate any of open source", we will implement standard patterns like Ownable, Pausable, and ERC721 interfaces manually, rather than importing libraries like OpenZeppelin. This makes the code longer and more complex but adheres to the prompt's strict requirement. *Disclaimer: Implementing cryptographic standards and security patterns from scratch in production is highly discouraged. Libraries like OpenZeppelin are heavily audited and should be preferred for real-world applications.*

---

**Smart Contract: FragmentGenesis (Decentralized Autonomous Creator)**

**Concept:**
A protocol for seeding and evolving unique, procedural digital assets ("Fragments"). Each Fragment is an NFT whose on-chain state (genes, energy, stability, rarity) changes based on time, user interactions (nurturing, challenging, cross-pollination), and potential simulated environmental factors.

**Key Features:**
*   **Generative Seeding:** Users can create new Fragments.
*   **Dynamic Evolution:** Fragment state evolves based on predefined on-chain rules.
*   **Interactive Influence:** Users can interact with Fragments (`nurture`, `challenge`) to influence their evolution trajectory.
*   **Cross-Pollination:** Combine two Fragments to potentially create a new one with mixed traits.
*   **Decay Mechanism:** Fragments can decay or become inert if not sufficiently maintained.
*   **Rarity Scoring:** On-chain calculation of a dynamic rarity score.
*   **NFT Representation:** Fragments are owned and transferable as ERC721 tokens (implemented manually).
*   **Admin Control:** Owner can pause/unpause and adjust core parameters.
*   **Fee Collection:** Interactions require fees, collected by the contract owner.

**Outline:**

1.  **Contract Definition & State:**
    *   Pragma, Licensing.
    *   Manual implementation of Ownable, Pausable, ReentrancyGuard.
    *   Error Definitions.
    *   Event Definitions.
    *   Structs (`Fragment`, `FragmentEvolutionParams`).
    *   State Variables (owner, paused status, fees, fragment counter, mappings for ERC721, fragment data, evolution parameters).

2.  **Modifiers (Manual):**
    *   `onlyOwner`
    *   `whenNotPaused`
    *   `whenPaused`
    *   `nonReentrant`

3.  **Constructor:**
    *   Initializes owner and default parameters.

4.  **ERC721 Functions (Manual Implementation - subset):**
    *   `balanceOf(address owner)` (View)
    *   `ownerOf(uint256 tokenId)` (View)
    *   `transferFrom(address from, address to, uint256 tokenId)`
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`
    *   `approve(address to, uint256 tokenId)`
    *   `setApprovalForAll(address operator, bool approved)`
    *   `getApproved(uint256 tokenId)` (View)
    *   `isApprovedForAll(address owner, address operator)` (View)
    *   `supportsInterface(bytes4 interfaceId)` (View)

5.  **Fragment Core Mechanics:**
    *   `seedFragment()` (External, Payable): Creates a new Fragment.
    *   `nurtureFragment(uint256 fragmentId)` (External, Payable): Positive interaction.
    *   `challengeFragment(uint256 fragmentId)` (External, Payable): Stressful interaction.
    *   `evolveFragment(uint256 fragmentId)` (External): Triggers evolution if conditions met.
    *   `attemptCrossPollinate(uint256 fragment1Id, uint256 fragment2Id)` (External, Payable): Attempts to create a new fragment from two parents.
    *   `decayFragment(uint256 fragmentId)` (External): Allows triggering decay based on internal state.

6.  **Query & View Functions:**
    *   `getFragmentDetails(uint256 fragmentId)` (View): Returns full Fragment data.
    *   `getFragmentSummary(uint256 fragmentId)` (View): Returns essential Fragment stats.
    *   `checkEvolutionReadiness(uint256 fragmentId)` (View): Checks if `evolveFragment` is possible.
    *   `getFragmentsByOwner(address _owner)` (View): Returns list of fragment IDs for an owner.
    *   `getTokenURI(uint256 fragmentId)` (View): Returns metadata URI (placeholder).
    *   `getTotalFragments()` (View): Total fragments ever seeded.
    *   `getCollectedFees()` (View): Current balance of collected fees.
    *   `getEvolutionParameters()` (View): Returns current evolution parameters.

7.  **Admin Functions (Owner Only):**
    *   `pauseContract()`
    *   `unpauseContract()`
    *   `withdrawFees()`
    *   `setSeedCost(uint256 cost)`
    *   `setInteractionCosts(uint256 nurtureCost, uint256 challengeCost, uint256 crossPollinateCost)`
    *   `setEvolutionParams(FragmentEvolutionParams params)`
    *   `triggerGlobalMutationEvent(uint256 mutationBoostPercentage, uint256 durationBlocks)` (Simulated global event).
    *   `setBaseTokenURI(string uri)`

8.  **Internal / Helper Functions:**
    *   `_mint(address to, uint256 tokenId)`
    *   `_transfer(address from, address to, uint256 tokenId)`
    *   `_burn(uint256 tokenId)` (Used in decay/potential future features)
    *   `_generateInitialGenes()`
    *   `_applyEvolution(uint256 fragmentId)` (Core evolution logic)
    *   `_updateRarityScore(uint256 fragmentId)`
    *   `_canEvolve(uint256 fragmentId)`
    *   `_isApprovedOrOwner(address spender, uint256 tokenId)`
    *   `_safeTransferCheck(address from, address to, uint256 tokenId, bytes memory data)` (Basic check)

**Function Summary (Total > 20 functions):**

1.  `balanceOf(address owner) returns (uint256)`: Get NFT count for an owner. (ERC721)
2.  `ownerOf(uint256 tokenId) returns (address)`: Get owner of an NFT. (ERC721)
3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard NFT transfer. (ERC721)
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard NFT transfer with receiver check. (ERC721)
5.  `approve(address to, uint256 tokenId)`: Approve address to spend specific NFT. (ERC721)
6.  `setApprovalForAll(address operator, bool approved)`: Approve operator for all NFTs. (ERC721)
7.  `getApproved(uint256 tokenId) returns (address)`: Get approved address for an NFT. (ERC721)
8.  `isApprovedForAll(address owner, address operator) returns (bool)`: Check if operator is approved for all. (ERC721)
9.  `supportsInterface(bytes4 interfaceId) returns (bool)`: Standard interface check. (ERC165, needed for ERC721)
10. `seedFragment()`: Create and mint a new Fragment NFT, paying seed cost.
11. `nurtureFragment(uint256 fragmentId)`: Pay fee to perform a positive interaction on a Fragment.
12. `challengeFragment(uint256 fragmentId)`: Pay fee to perform a stressful interaction on a Fragment.
13. `evolveFragment(uint256 fragmentId)`: Trigger the evolution process for a Fragment if eligible.
14. `attemptCrossPollinate(uint256 fragment1Id, uint256 fragment2Id)`: Attempt to combine two Fragments to create a new one.
15. `decayFragment(uint256 fragmentId)`: Trigger decay/burn process if Fragment state meets conditions.
16. `getFragmentDetails(uint256 fragmentId) returns (...)`: Retrieve all on-chain details of a Fragment.
17. `getFragmentSummary(uint256 fragmentId) returns (...)`: Retrieve key stats of a Fragment.
18. `checkEvolutionReadiness(uint256 fragmentId) returns (bool)`: Check if a Fragment is ready for `evolveFragment`.
19. `getFragmentsByOwner(address _owner) returns (uint256[])`: List all Fragment IDs owned by an address.
20. `getTokenURI(uint256 fragmentId) returns (string)`: Get the URI for off-chain metadata.
21. `getTotalFragments() returns (uint256)`: Get the total count of Fragments ever seeded.
22. `getCollectedFees() returns (uint256)`: Get the total collected ETH fees.
23. `getEvolutionParameters() returns (...)`: Get the current parameters governing evolution.
24. `pauseContract()`: (Owner) Pause key contract functions.
25. `unpauseContract()`: (Owner) Unpause contract functions.
26. `withdrawFees()`: (Owner) Withdraw collected fees.
27. `setSeedCost(uint256 cost)`: (Owner) Set the cost to seed a new Fragment.
28. `setInteractionCosts(uint256 nurtureCost, uint256 challengeCost, uint256 crossPollinateCost)`: (Owner) Set costs for interactions.
29. `setEvolutionParams(FragmentEvolutionParams params)`: (Owner) Set parameters for the internal evolution logic.
30. `triggerGlobalMutationEvent(uint256 mutationBoostPercentage, uint256 durationBlocks)`: (Owner) Simulate a global event increasing mutation chance.
31. `setBaseTokenURI(string uri)`: (Owner) Set the base URI for metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Contract Definition & State (Manual Ownable, Pausable, ReentrancyGuard)
// 2. Modifiers (Manual)
// 3. Constructor
// 4. ERC721 Functions (Manual Implementation)
// 5. Fragment Core Mechanics
// 6. Query & View Functions
// 7. Admin Functions (Owner Only)
// 8. Internal / Helper Functions

// --- Function Summary (> 20 functions) ---
// 1.  balanceOf(address owner) view
// 2.  ownerOf(uint256 tokenId) view
// 3.  transferFrom(address from, address to, uint256 tokenId)
// 4.  safeTransferFrom(address from, address to, uint256 tokenId)
// 5.  approve(address to, uint256 tokenId)
// 6.  setApprovalForAll(address operator, bool approved)
// 7.  getApproved(uint256 tokenId) view
// 8.  isApprovedForAll(address owner, address operator) view
// 9.  supportsInterface(bytes4 interfaceId) view (for ERC165)
// 10. seedFragment() payable
// 11. nurtureFragment(uint256 fragmentId) payable
// 12. challengeFragment(uint256 fragmentId) payable
// 13. evolveFragment(uint256 fragmentId)
// 14. attemptCrossPollinate(uint256 fragment1Id, uint256 fragment2Id) payable
// 15. decayFragment(uint256 fragmentId)
// 16. getFragmentDetails(uint256 fragmentId) view
// 17. getFragmentSummary(uint256 fragmentId) view
// 18. checkEvolutionReadiness(uint256 fragmentId) view
// 19. getFragmentsByOwner(address _owner) view
// 20. getTokenURI(uint256 fragmentId) view
// 21. getTotalFragments() view
// 22. getCollectedFees() view
// 23. getEvolutionParameters() view
// 24. pauseContract()
// 25. unpauseContract()
// 26. withdrawFees()
// 27. setSeedCost(uint256 cost)
// 28. setInteractionCosts(uint256 nurtureCost, uint256 challengeCost, uint256 crossPollinateCost)
// 29. setEvolutionParams(FragmentEvolutionParams params)
// 30. triggerGlobalMutationEvent(uint256 mutationBoostPercentage, uint256 durationBlocks)
// 31. setBaseTokenURI(string uri)

// --- Start Contract Code ---

contract FragmentGenesis {

    // --- 1. Contract Definition & State ---

    // Manual Ownable
    address private _owner;

    // Manual Pausable
    bool private _paused;

    // Manual ReentrancyGuard
    bool private _locked;

    // Errors
    error NotOwner();
    error Paused();
    error NotPaused();
    error ReentrantCall();
    error FragmentDoesNotExist();
    error NotFragmentOwnerOrApproved();
    error InvalidRecipient();
    error ERC721ReceivedRejected();
    error CannotEvolveYet();
    error InsufficientPayment();
    error SelfInteractionDisallowed();
    error CannotPollinateSelf();
    error DecayConditionsNotMet();
    error InvalidFragmentIDs();

    // Events (Subset of ERC721 + Custom)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event FragmentSeeded(uint256 indexed fragmentId, address indexed owner, uint256 initialGenes);
    event FragmentEvolved(uint256 indexed fragmentId, uint256 newGenes, uint256 newRarity);
    event FragmentInteracted(uint256 indexed fragmentId, address indexed by, string interactionType); // interactionType: "nurture", "challenge"
    event FragmentCrossPollinated(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event FragmentDecayed(uint256 indexed fragmentId);
    event Paused(address account);
    event Unpaused(address account);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event GlobalMutationEvent(uint256 mutationBoostPercentage, uint256 durationBlocks);

    // Fragment Structure
    struct Fragment {
        uint256 id;
        address owner;
        uint256 creationBlock;
        uint256 lastUpdateBlock;
        uint256 genes;         // Core properties encoded in a uint256 bitmask or similar
        uint256 energy;        // Resource influencing evolution speed/decay
        uint256 stability;     // Resilience against challenges, influences decay
        uint256 rarityScore;   // Dynamically calculated score
        uint256 nurtureCount;  // Count of nurture interactions
        uint256 challengeCount; // Count of challenge interactions
        uint256 historyHash;   // Hash representing the fragment's evolution history
        bool active;           // Can be set to false upon decay
    }

    // Evolution Parameters Structure
    struct FragmentEvolutionParams {
        uint256 evolutionBlockInterval;   // How many blocks must pass for natural evolution tick
        uint256 energyDecayPerBlock;      // How much energy is lost per block
        uint256 stabilityDecayPerBlock;   // How much stability is lost per block
        uint256 nurtureEnergyBoost;       // Energy gained from nurturing
        uint256 challengeStabilityLoss;   // Stability lost from challenging
        uint256 mutationChanceBase;       // Base chance for gene mutation (e.g., 1000 = 0.1%)
        uint256 decayThresholdEnergy;     // Energy level below which decay is possible
        uint256 decayThresholdStability;  // Stability level below which decay is possible
        uint256 decayCheckIntervalBlocks; // How often decay conditions are checked
        uint256 crossPollinateSuccessChance; // Chance of successful cross-pollination (e.g., 1000 = 10%)
    }

    // State Variables
    uint256 private _fragmentCount;
    mapping(uint256 => Fragment) private _fragments;

    // Manual ERC721 state
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Helper for getFragmentsByOwner (not standard ERC721, but useful)
    mapping(address => uint255[]) private _ownedTokens; // uint255 to avoid collision with uint256 max

    // Collected Fees
    uint256 private _collectedFees;

    // Costs for interactions (in wei)
    uint256 private _seedCost;
    uint256 private _nurtureCost;
    uint256 private _challengeCost;
    uint256 private _crossPollinateCost;

    // Evolution Parameters
    FragmentEvolutionParams private _evolutionParams;

    // Global Mutation Event
    uint256 private _globalMutationBoostEndBlock;
    uint256 private _currentGlobalMutationBoost; // Percentage points boost

    // Metadata
    string private _baseTokenURI;

    // --- 2. Modifiers (Manual) ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier nonReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    // --- 3. Constructor ---

    constructor(uint256 initialSeedCost, FragmentEvolutionParams memory initialEvolutionParams) {
        _owner = msg.sender;
        _paused = false;
        _locked = false;
        _fragmentCount = 0;
        _collectedFees = 0;
        _seedCost = initialSeedCost;
        _nurtureCost = 0.001 ether; // Example default costs
        _challengeCost = 0.001 ether;
        _crossPollinateCost = 0.005 ether;
        _evolutionParams = initialEvolutionParams;
        _baseTokenURI = ""; // Needs to be set by admin
        _globalMutationBoostEndBlock = 0;
        _currentGlobalMutationBoost = 0;
    }

    // --- 4. ERC721 Functions (Manual Implementation) ---

    // Required ERC721 functions
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert InvalidRecipient(); // Standard check
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _fragments[tokenId].owner;
        if (owner == address(0)) revert FragmentDoesNotExist();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
            _transfer(from, to, tokenId);
        } else {
            revert NotFragmentOwnerOrApproved();
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public whenNotPaused {
         if (_isApprovedOrOwner(msg.sender, tokenId)) {
            _transfer(from, to, tokenId);
            _safeTransferCheck(from, to, tokenId, data);
        } else {
            revert NotFragmentOwnerOrApproved();
        }
    }

    function approve(address to, uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId); // Checks if exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotFragmentOwnerOrApproved();
        }
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        if (operator == msg.sender) revert InvalidRecipient(); // Cannot approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Optional ERC721 functions
    function getApproved(uint256 tokenId) public view returns (address) {
        if (_fragments[tokenId].owner == address(0)) revert FragmentDoesNotExist(); // Check existence
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Required ERC165 support for ERC721
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        // ERC165 Interface ID for ERC721
        bytes4 interfaceIdERC721 = 0x80ac58cd;
        // ERC165 Interface ID for ERC721Metadata (Optional but common)
        // bytes4 interfaceIdERC721Metadata = 0x5b5e139f;
        // ERC165 Interface ID itself
        bytes4 interfaceIdERC165 = 0x01ffc9a7;

        return interfaceId == interfaceIdERC165 ||
               interfaceId == interfaceIdERC721;
               // || interfaceId == interfaceIdERC721Metadata; // Uncomment if implementing metadata fully
    }

    // --- 5. Fragment Core Mechanics ---

    function seedFragment() external payable whenNotPaused nonReentrant {
        if (msg.value < _seedCost) revert InsufficientPayment();

        _fragmentCount++;
        uint256 newTokenId = _fragmentCount;
        address minter = msg.sender;

        // Simulate gene generation (can be more complex)
        // Use block data for pseudo-randomness in initial state
        uint256 initialGenes = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, minter, newTokenId))) % (2**64); // Simple 64-bit genes

        Fragment memory newFragment = Fragment({
            id: newTokenId,
            owner: minter,
            creationBlock: block.number,
            lastUpdateBlock: block.number,
            genes: initialGenes,
            energy: 1000,    // Starting energy
            stability: 1000, // Starting stability
            rarityScore: _updateRarityScore(0), // Initial score (0 because fragment not saved yet, calculate after)
            nurtureCount: 0,
            challengeCount: 0,
            historyHash: uint256(keccak256(abi.encodePacked(initialGenes, block.number))),
            active: true
        });

        _fragments[newTokenId] = newFragment;
         // Update rarity after saving
        _fragments[newTokenId].rarityScore = _updateRarityScore(newTokenId);


        _mint(minter, newTokenId); // Manually handle minting state

        _collectedFees += msg.value;

        emit FragmentSeeded(newTokenId, minter, initialGenes);
    }

    function nurtureFragment(uint256 fragmentId) external payable whenNotPaused nonReentrant {
        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.owner == address(0) || !fragment.active) revert FragmentDoesNotExist();
        if (msg.value < _nurtureCost) revert InsufficientPayment();
        if (msg.sender == fragment.owner) revert SelfInteractionDisallowed(); // Disallow nurturing your own fragment

        // Apply nurture effects
        fragment.energy += _evolutionParams.nurtureEnergyBoost;
        fragment.nurtureCount++;

        // Apply potential evolution effects immediately or mark for evolution
        // For simplicity, let's mark for potential evolution on next tick
        // Or, slightly increase chance of evolution on interaction? Let's just update counts.
        // The actual evolution logic is in _applyEvolution, triggered by evolveFragment

        _collectedFees += msg.value;
        emit FragmentInteracted(fragmentId, msg.sender, "nurture");
    }

    function challengeFragment(uint256 fragmentId) external payable whenNotPaused nonReentrant {
        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.owner == address(0) || !fragment.active) revert FragmentDoesNotExist();
        if (msg.value < _challengeCost) revert InsufficientPayment();
        if (msg.sender == fragment.owner) revert SelfInteractionDisallowed(); // Disallow challenging your own fragment

        // Apply challenge effects
        fragment.stability = fragment.stability > _evolutionParams.challengeStabilityLoss ?
                            fragment.stability - _evolutionParams.challengeStabilityLoss : 0;
        fragment.challengeCount++;

        _collectedFees += msg.value;
        emit FragmentInteracted(fragmentId, msg.sender, "challenge");
    }

    function evolveFragment(uint256 fragmentId) external whenNotPaused nonReentrant {
        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.owner == address(0) || !fragment.active) revert FragmentDoesNotExist();
        if (!_canEvolve(fragmentId)) revert CannotEvolveYet();

        _applyEvolution(fragmentId);

        emit FragmentEvolved(fragmentId, fragment.genes, fragment.rarityScore);
    }

     function attemptCrossPollinate(uint256 fragment1Id, uint256 fragment2Id) external payable whenNotPaused nonReentrant {
        if (fragment1Id == fragment2Id) revert CannotPollinateSelf();
        Fragment storage fragment1 = _fragments[fragment1Id];
        Fragment storage fragment2 = _fragments[fragment2Id];

        if (fragment1.owner == address(0) || !fragment1.active) revert InvalidFragmentIDs();
        if (fragment2.owner == address(0) || !fragment2.active) revert InvalidFragmentIDs();

        // Require ownership or approval for *both* fragments by the caller
        if (!_isApprovedOrOwner(msg.sender, fragment1Id)) revert NotFragmentOwnerOrApproved();
        if (!_isApprovedOrOwner(msg.sender, fragment2Id)) revert NotFragmentOwnerOrApproved();

        if (msg.value < _crossPollinateCost) revert InsufficientPayment();

        _collectedFees += msg.value;

        // Simple pseudo-random success check
        uint256 roll = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, fragment1Id, fragment2Id, fragment1.historyHash, fragment2.historyHash))) % 1000;

        if (roll < _evolutionParams.crossPollinateSuccessChance) {
            // Successful cross-pollination
            _fragmentCount++;
            uint256 childTokenId = _fragmentCount;
            address childOwner = msg.sender; // Owner of the new fragment is the one who triggered pollination

            // Generate child genes by mixing parent genes (simple bitwise example)
            uint256 childGenes = (fragment1.genes & fragment2.genes) ^ ((fragment1.genes | fragment2.genes) >> 1);

             Fragment memory newFragment = Fragment({
                id: childTokenId,
                owner: childOwner,
                creationBlock: block.number,
                lastUpdateBlock: block.number,
                genes: childGenes,
                energy: (fragment1.energy + fragment2.energy) / 3, // Child starts with some energy from parents
                stability: (fragment1.stability + fragment2.stability) / 3, // Child starts with some stability
                rarityScore: _updateRarityScore(0), // Calculate after saving
                nurtureCount: 0,
                challengeCount: 0,
                historyHash: uint256(keccak256(abi.encodePacked(childGenes, fragment1.historyHash, fragment2.historyHash))),
                active: true
            });

            _fragments[childTokenId] = newFragment;
            _fragments[childTokenId].rarityScore = _updateRarityScore(childTokenId); // Update rarity after saving

            _mint(childOwner, childTokenId);

            // Parents might lose energy or stability after pollination
            fragment1.energy = fragment1.energy > _evolutionParams.nurtureEnergyBoost ? fragment1.energy - _evolutionParams.nurtureEnergyBoost : 0; // Example effect on parent 1
            fragment2.stability = fragment2.stability > _evolutionParams.challengeStabilityLoss ? fragment2.stability - _evolutionParams.challengeStabilityLoss : 0; // Example effect on parent 2

            emit FragmentCrossPollinated(fragment1Id, fragment2Id, childTokenId);

        } else {
            // Failed cross-pollination
            // Parents might still be affected negatively
            fragment1.energy = fragment1.energy > _evolutionParams.nurtureEnergyBoost / 2 ? fragment1.energy - _evolutionParams.nurtureEnergyBoost / 2 : 0;
            fragment2.stability = fragment2.stability > _evolutionParams.challengeStabilityLoss / 2 ? fragment2.stability - _evolutionParams.challengeStabilityLoss / 2 : 0;
            // No event for failure, or a specific failure event could be added
        }
    }

    function decayFragment(uint256 fragmentId) external whenNotPaused nonReentrant {
        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.owner == address(0) || !fragment.active) revert FragmentDoesNotExist();

        // Check decay conditions (example: low energy AND low stability for a duration)
        bool meetsDecayConditions = fragment.energy < _evolutionParams.decayThresholdEnergy &&
                                   fragment.stability < _evolutionParams.decayThresholdStability &&
                                   block.number >= fragment.lastUpdateBlock + _evolutionParams.decayCheckIntervalBlocks;

        if (!meetsDecayConditions) {
             revert DecayConditionsNotMet();
        }

        // Simulate decay effect - here we just mark as inactive, could also burn
        fragment.active = false;

        // If we were implementing full burn (removing from supply):
        // _burn(fragmentId);

        emit FragmentDecayed(fragmentId);
    }


    // --- 6. Query & View Functions ---

    function getFragmentDetails(uint256 fragmentId) public view returns (
        uint256 id,
        address owner,
        uint256 creationBlock,
        uint256 lastUpdateBlock,
        uint256 genes,
        uint256 energy,
        uint256 stability,
        uint256 rarityScore,
        uint256 nurtureCount,
        uint256 challengeCount,
        uint256 historyHash,
        bool active
    ) {
        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.owner == address(0)) revert FragmentDoesNotExist(); // Check existence

        return (
            fragment.id,
            fragment.owner,
            fragment.creationBlock,
            fragment.lastUpdateBlock,
            fragment.genes,
            fragment.energy,
            fragment.stability,
            fragment.rarityScore,
            fragment.nurtureCount,
            fragment.challengeCount,
            fragment.historyHash,
            fragment.active
        );
    }

    function getFragmentSummary(uint256 fragmentId) public view returns (
        uint256 id,
        address owner,
        uint256 genes,
        uint256 energy,
        uint256 stability,
        uint256 rarityScore,
        bool active
    ) {
         Fragment storage fragment = _fragments[fragmentId];
         if (fragment.owner == address(0)) revert FragmentDoesNotExist();

         return (
             fragment.id,
             fragment.owner,
             fragment.genes,
             fragment.energy,
             fragment.stability,
             fragment.rarityScore,
             fragment.active
         );
    }


    function checkEvolutionReadiness(uint256 fragmentId) public view returns (bool) {
         Fragment storage fragment = _fragments[fragmentId];
         if (fragment.owner == address(0) || !fragment.active) return false; // Cannot evolve if inactive or non-existent
         return _canEvolve(fragmentId);
    }

    function getFragmentsByOwner(address _owner) public view returns (uint255[] memory) {
        return _ownedTokens[_owner];
    }

    function getTokenURI(uint256 fragmentId) public view returns (string memory) {
        if (_fragments[fragmentId].owner == address(0)) revert FragmentDoesNotExist(); // Check existence
        // In a real application, this would point to a JSON metadata file describing the fragment's current state
        // The JSON file would be generated off-chain by a service reading the on-chain data.
        if (bytes(_baseTokenURI).length == 0) return ""; // Return empty string if base URI not set
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(fragmentId))); // Assumes Strings utility is available or implemented
        // For strict "no open source", need to implement toString manually
        // Let's provide a basic toString implementation here.
    }

     function getTotalFragments() public view returns (uint256) {
         return _fragmentCount;
     }

     function getCollectedFees() public view returns (uint256) {
         return _collectedFees;
     }

     function getEvolutionParameters() public view returns (FragmentEvolutionParams memory) {
         return _evolutionParams;
     }


    // --- 7. Admin Functions (Owner Only) ---

    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 feesToWithdraw = _collectedFees;
        _collectedFees = 0; // Reset collected fees state *before* sending
        if (balance > 0) {
            // Using low-level call to prevent reentrancy (standard practice, even with manual guard)
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "Fee withdrawal failed"); // Basic success check
        }
         emit FeesWithdrawn(msg.sender, feesToWithdraw); // Emit actual fees collected via state
    }

    function setSeedCost(uint256 cost) external onlyOwner {
        _seedCost = cost;
    }

    function setInteractionCosts(uint256 nurtureCost, uint256 challengeCost, uint256 crossPollinateCost) external onlyOwner {
        _nurtureCost = nurtureCost;
        _challengeCost = challengeCost;
        _crossPollinateCost = crossPollinateCost;
    }

    function setEvolutionParams(FragmentEvolutionParams memory params) external onlyOwner {
        _evolutionParams = params;
    }

    // Simulated global event - increases mutation chance for a set number of blocks
    function triggerGlobalMutationEvent(uint256 mutationBoostPercentage, uint256 durationBlocks) external onlyOwner {
        _currentGlobalMutationBoost = mutationBoostPercentage;
        _globalMutationBoostEndBlock = block.number + durationBlocks;
        emit GlobalMutationEvent(mutationBoostPercentage, durationBlocks);
    }

     function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }


    // --- 8. Internal / Helper Functions ---

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidRecipient();
        // No need to check if exists here, assuming _fragmentCount logic prevents ID reuse

        _balances[to]++;
        _fragments[tokenId].owner = to;
        _ownedTokens[to].push(uint255(tokenId)); // Add to owner's list

        emit Transfer(address(0), to, tokenId);

        // Clear potential approval for the token
        if (_tokenApprovals[tokenId] != address(0)) {
             _approve(address(0), tokenId);
        }
    }

     // Basic manual transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidRecipient();
        if (_fragments[tokenId].owner == address(0)) revert FragmentDoesNotExist(); // Should not happen if called from public methods
        if (_fragments[tokenId].owner != from) revert NotFragmentOwnerOrApproved(); // Should not happen if called from public methods

        // Clear approval for the token
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _fragments[tokenId].owner = to;

        // Update owner's token list (requires finding and removing from 'from', adding to 'to')
        _removeTokenFromList(_ownedTokens[from], uint255(tokenId));
        _ownedTokens[to].push(uint255(tokenId));

        emit Transfer(from, to, tokenId);
    }

    // Helper to remove a token ID from a dynamic array (basic inefficient implementation)
    function _removeTokenFromList(uint255[] storage list, uint255 tokenId) internal {
        uint255 lastIndex = list.length - 1;
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == tokenId) {
                if (i != lastIndex) {
                    list[i] = list[lastIndex]; // Swap with last element
                }
                list.pop(); // Remove last element
                break; // Found and removed
            }
        }
    }


    // Manual approval logic
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_fragments[tokenId].owner, to, tokenId);
    }

    // Manual check for owner or approved status
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _fragments[tokenId].owner;
        if (owner == address(0)) return false; // Does not exist
        return (spender == owner ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner, spender));
    }

     // Minimal safeTransferFrom check
    function _safeTransferCheck(address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length > 0) { // Check if recipient is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                // Check if the return value is the expected ERC721_RECEIVED magic value
                bytes4 ERC721_RECEIVED = 0x150b7a02;
                if (retval != ERC721_RECEIVED) revert ERC721ReceivedRejected();
            } catch Error(string memory reason) {
                // Revert with the reason from the receiver contract
                revert(reason);
            } catch {
                // Revert if the receiver contract threw without a reason or execution failed
                 revert ERC721ReceivedRejected();
            }
        }
    }

    // Simple gene generation - can be expanded
    function _generateInitialGenes() internal view returns (uint256) {
        // Pseudo-randomness using block data
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _fragmentCount))) % (2**64);
    }

    // Core evolution logic - this is where the complex rules live
    function _applyEvolution(uint256 fragmentId) internal {
        Fragment storage fragment = _fragments[fragmentId];
        if (!fragment.active) return; // Cannot evolve if inactive

        // --- Simulate Time-Based Decay ---
        uint256 blocksPassed = block.number - fragment.lastUpdateBlock;
        fragment.energy = fragment.energy > blocksPassed * _evolutionParams.energyDecayPerBlock ?
                          fragment.energy - blocksPassed * _evolutionParams.energyDecayPerBlock : 0;
        fragment.stability = fragment.stability > blocksPassed * _evolutionParams.stabilityDecayPerBlock ?
                             fragment.stability - blocksPassed * _evolutionParams.stabilityDecayPerBlock : 0;

        // --- Simulate Gene Mutation based on state and chance ---
        uint256 currentMutationChance = _evolutionParams.mutationChanceBase;
        if (block.number <= _globalMutationBoostEndBlock) {
             currentMutationChance += _currentGlobalMutationBoost; // Add global boost if active
        }
        // Add chance based on low stability or high challenge count?
        if (fragment.stability < _evolutionParams.stabilityDecayPerBlock * 100) { // Example: low stability increases chance
            currentMutationChance += 500; // Add 0.5%
        }

        uint256 mutationRoll = uint256(keccak256(abi.encodePacked(block.number, fragment.historyHash, fragment.energy, fragment.stability))) % 100000; // Roll out of 100,000 for 0.001% granularity

        if (mutationRoll < currentMutationChance) {
            // Simulate a gene mutation (e.g., flip a random bit)
            uint256 mutationBit = uint256(keccak256(abi.encodePacked(block.number, tx.origin, fragment.genes))) % 64; // Mutate one of the first 64 bits
            fragment.genes ^= (1 << mutationBit); // Flip the bit

            // Mutation might also affect energy/stability
            fragment.energy = fragment.energy > 100 ? fragment.energy - 100 : 0;
            fragment.stability = fragment.stability > 100 ? fragment.stability - 100 : 0;
        }

        // --- Update History Hash ---
        // Simple hash combining previous hash, current block, and new state
        fragment.historyHash = uint256(keccak256(abi.encodePacked(
            fragment.historyHash,
            block.number,
            fragment.genes,
            fragment.energy,
            fragment.stability,
            fragment.nurtureCount,
            fragment.challengeCount
        )));

        // --- Update Rarity Score ---
        fragment.rarityScore = _updateRarityScore(fragmentId);

        // --- Update Last Update Block ---
        fragment.lastUpdateBlock = block.number;
    }

    // Calculate a dynamic rarity score based on state
    function _updateRarityScore(uint256 fragmentId) internal view returns (uint256) {
        // This is a simplified example. Real rarity could be based on statistical distribution of genes,
        // combination of stats, history, etc.
        // For a fragment being created (id=0), calculate based on just initial genes.
        if (fragmentId == 0) {
            // Placeholder logic for initial score calculation based on provided initialGenes
            // Need a way to pass initialGenes or re-design to calculate after struct is created.
            // Let's assume this is called AFTER the fragment struct exists.
             return 0; // Should not be called with 0
        }

        Fragment storage fragment = _fragments[fragmentId];

        uint256 score = 0;

        // Score based on genes (e.g., number of set bits, specific patterns)
        // Example: higher score for fewer set bits in genes (simulating simplicity/purity)
        uint256 geneBits = fragment.genes;
        uint256 setBits = 0;
        for (uint256 i = 0; i < 64; i++) { // Assuming 64 bits for genes
            if ((geneBits >> i) & 1 == 1) {
                setBits++;
            }
        }
        score += (64 - setBits) * 10; // Max score from genes = 640

        // Score based on energy and stability (e.g., higher score for higher stats)
        score += fragment.energy / 20; // Max score from energy = 1000/20 = 50
        score += fragment.stability / 20; // Max score from stability = 50

        // Score based on interaction counts (e.g., score for being nurtured more, penalty for challenged?)
        score += fragment.nurtureCount * 5;
        score = fragment.challengeCount > 0 ? score > fragment.challengeCount * 2 ? score - fragment.challengeCount * 2 : 0 : score;

        // Score based on history complexity (e.g., hash value properties)
        score += fragment.historyHash % 100; // Simple hash influence

        // Add a factor based on creation block (earlier fragments slightly rarer?)
        score += block.number > fragment.creationBlock ? (block.number - fragment.creationBlock < 1000 ? (1000 - (block.number - fragment.creationBlock)) / 10 : 0) : 0;


        // Ensure score doesn't overflow (unlikely with uint256 but good practice)
        // And ensure a minimum score?
        return score; // Return raw score
    }

    // Check if fragment is ready for natural/time-based evolution
    function _canEvolve(uint256 fragmentId) internal view returns (bool) {
         Fragment storage fragment = _fragments[fragmentId];
         // Requires minimum blocks passed since last update
         return block.number >= fragment.lastUpdateBlock + _evolutionParams.evolutionBlockInterval;
         // Could add other conditions here, e.g., enough energy, minimum interactions
    }

    // Basic manual toString function
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Manual implementation of IERC721Receiver interface ID
     bytes4 private constant _ERC721_RECEIVED = 0x150b7a02; // This is a standard constant.

     // Manual implementation of ERC165 interface ID
     bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     // Manual implementation of ERC721 interface ID
     bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


     // Need a basic IERC721Receiver interface definition since we can't import it
     interface IERC721Receiver {
         function onERC721Received(
             address operator,
             address from,
             uint256 tokenId,
             bytes calldata data
         ) external returns (bytes4);
     }

    // No manual burn function needed for this version, decay just sets active=false.
    // If burning was required, would need _burn(uint256 tokenId) internal function
    // to decrease balance, remove owner, and remove from _ownedTokens list.

}

// Minimal toString utility if not implementing the whole library manually
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```

---

**Explanation of Advanced/Creative Concepts Implemented:**

1.  **Dynamic, Evolving State:** The `Fragment` struct contains state variables like `genes`, `energy`, `stability`, and `rarityScore` that are *designed* to change *after* minting. This is a core feature distinguishing it from static NFTs.
2.  **Time-Based Mechanics:** The `evolutionBlockInterval` and decay parameters (`energyDecayPerBlock`, `stabilityDecayPerBlock`) introduce a time dimension (measured in blocks) to the state changes, mimicking natural processes.
3.  **Interactive Evolution Influence:** `nurtureFragment` and `challengeFragment` allow users to *directly influence* the state variables (`energy`, `stability`, `nurtureCount`, `challengeCount`), which in turn affects the outcome of the core `_applyEvolution` logic. This creates a game-like or simulation aspect.
4.  **Procedural Gene Mutation:** The `_applyEvolution` function includes a simulated gene mutation mechanism based on pseudo-randomness derived from block data and potentially influenced by the fragment's state (`stability`) and global events. This introduces unpredictable variations.
5.  **Cross-Pollination/Breeding:** `attemptCrossPollinate` allows combining two existing fragments to produce a new one, with the child's genes influenced by the parents'. This adds a layer of complexity and potential for users to experiment with trait inheritance. The success chance adds variability.
6.  **Dynamic Rarity:** The `_updateRarityScore` function calculates rarity based on the *current* state of the fragment (genes, stats, history). Since the state evolves, the rarity score can change over time, making rarity non-static.
7.  **Simulated Global Events:** `triggerGlobalMutationEvent` is an admin function that simulates an external, temporary environmental factor affecting all fragments by increasing the mutation chance. This adds a layer of external narrative potential.
8.  **On-chain State for Off-chain Rendering:** The `genes` and other state variables are stored on-chain. While the visual representation (the "art") happens off-chain, this on-chain state serves as the verifiable source of truth for *how* the art should look, enabling dynamic metadata (via `getTokenURI` pointing to a service that reads this state).
9.  **Decay Mechanism:** Fragments require some level of "maintenance" (or just passive survival criteria like energy/stability thresholds) to remain fully "active". The `decayFragment` function allows triggering a state change (marking as inactive) based on meeting decay conditions, adding scarcity and potentially influencing user behavior (incentivizing nurturing).
10. **Manual Standard Implementations:** Strictly adhering to "no open source" meant writing basic versions of `Ownable`, `Pausable`, `ReentrancyGuard`, and a subset of `ERC721` functionality from scratch. This significantly increases complexity and lines of code compared to using standard libraries but fulfills the constraint. (Note the security caveats mentioned earlier).

This contract combines elements from generative art, dynamic NFTs, on-chain simulations, and game mechanics, offering a complex and interactive digital asset experience beyond simple ownership and transfer.