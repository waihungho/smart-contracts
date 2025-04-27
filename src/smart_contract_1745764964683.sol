Okay, let's design an interesting, advanced, and creative smart contract. We'll create an "Evolving On-Chain Ecosystem" where users own unique digital lifeforms (NFTs) that have dynamic traits influenced by a global ecosystem state, and can interact with the environment and each other to evolve.

This contract will combine elements of:
1.  **Dynamic NFTs:** Traits are stored on-chain and change based on interaction and ecosystem state.
2.  **On-Chain Simulation:** A global ecosystem state evolves over time and influences entities.
3.  **Gamified Interaction:** Users perform actions that cost resources (ETH/other tokens) and affect their entities and the ecosystem.
4.  **Generative Traits:** Initial traits and mutation/breeding outcomes are influenced by the current ecosystem state and pseudo-randomness.
5.  **Parameterization:** Key costs and evolution factors can be adjusted.

Crucially, we will **implement the core logic from scratch** rather than inheriting large open-source libraries like OpenZeppelin's ERC721 standard implementation, focusing the creativity on the ecosystem and evolution mechanics, while acknowledging the trade-offs in security and gas efficiency compared to audited libraries for standard interfaces like ERC721. (Note: Implementing a secure, gas-efficient ERC721 from scratch is complex; this version is for demonstrating the *concept* and meeting the "no duplication" rule strictly regarding implementation code).

---

**Smart Contract Outline: EvolvingOnchainEcosystem**

1.  **Metadata:** SPDX-License-Identifier, Pragma.
2.  **Interfaces:** Minimal necessary interface imports (e.g., `IERC165`, `IERC721`, `IERC721Metadata`). Note: We implement the logic manually, not inherit full OZ contracts.
3.  **Errors:** Custom errors for specific failure conditions.
4.  **Events:** Logging key actions and state changes.
5.  **Enums:** Defining elements or states.
6.  **Structs:** Defining the structure of Entity state and Ecosystem state.
7.  **State Variables:**
    *   Contract owner.
    *   Core ERC721 mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
    *   Next available token ID.
    *   Mapping `_entityStates` (tokenId => EntityState).
    *   `_ecosystemState` (EcosystemState struct).
    *   Costs for actions (`seedCost`, `feedingCost`, `explorationCost`, `mutationCost`, `breedingFee`).
    *   Address for dynamic NFT renderer (`_rendererAddress`).
    *   Ecosystem evolution cooldown.
    *   Last ecosystem evolution block.
8.  **Constructor:** Initialize owner, initial ecosystem state, costs, cooldown.
9.  **ERC721 Core Implementation:** Basic manual implementation of required ERC721 functions (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`). Includes internal helpers (`_mint`, `_transfer`).
10. **Custom Ecosystem & Entity Logic (Public/External):**
    *   `seedEntity`: Create a new entity.
    *   `feedEntity`: Provide energy to an entity.
    *   `exploreEnvironment`: Entity interacts with the ecosystem.
    *   `attemptMutation`: Attempt to mutate an entity's traits.
    *   `breedEntities`: Create a new entity from two parents.
    *   `evolveEcosystem`: Trigger global ecosystem state change.
    *   `getTokenURI`: Get the dynamic URI for NFT metadata.
11. **View Functions (Public/External):**
    *   `getEntityState`: Retrieve full state of an entity.
    *   `getEcosystemState`: Retrieve current global ecosystem state.
    *   `getTrait`: Get a specific trait of an entity.
    *   `getEntityGeneration`: Get the generation of an entity.
    *   `getSeedCost`, `getFeedingCost`, `getExplorationCost`, `getMutationCost`, `getBreedingFee`: Retrieve current costs.
    *   `getRendererAddress`: Get the renderer address.
    *   `getEcosystemEvolutionCooldown`: Get the cooldown period.
    *   `getLastEcosystemEvolutionBlock`: Get the last evolution block.
    *   `calculateExplorationOutcome`: Predict outcome of exploration.
    *   `calculateMutationSuccess`: Predict success chance of mutation.
    *   `calculateBreedingResult`: Predict potential traits of offspring.
12. **Admin/Owner Functions (External):**
    *   `setRendererAddress`.
    *   `setSeedCost`, `setFeedingCost`, `setExplorationCost`, `setMutationCost`, `setBreedingFee`.
    *   `setEcosystemEvolutionCooldown`.
    *   `withdrawFunds`.
13. **Internal Helper Functions:**
    *   `_exists`: Check if token ID exists.
    *   `_isApprovedOrOwner`: Check approval/ownership.
    *   `_generateInitialTraits`: Logic for creating initial entity traits.
    *   `_applyEcosystemEffects`: Calculate how ecosystem state modifies traits/actions.
    *   `_performExplorationLogic`: Core logic for explore action.
    *   `_performMutationLogic`: Core logic for mutation action.
    *   `_performBreedingLogic`: Core logic for breeding action.
    *   `_updateEntityState`: Helper to update entity traits.
    *   `_updateEcosystemState`: Helper to change global state.
    *   `_getRandomness`: Pseudo-random number generation helper.
    *   `_requireOwnedOrApproved`: Modifier/internal check for token actions.

---

**Function Summary:**

*   **ERC721 Core (Public/External):**
    *   `balanceOf(address owner)`: Returns the number of tokens in `owner`'s account.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of the NFT specified by `tokenId`.
    *   `approve(address to, uint256 tokenId)`: Gives approval to `to` to transfer a specific `tokenId`.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a single NFT.
    *   `setApprovalForAll(address operator, bool approved)`: Approves or removes `operator` as an operator for the caller.
    *   `isApprovedForAll(address owner, address operator)`: Returns if the `operator` is an approved operator for `owner`.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`. (Requires approval or operator status).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers `tokenId` from `from` to `to`, checking if `to` is a contract that accepts ERC721s.
*   **Custom Ecosystem & Entity Logic (Public/External):**
    *   `seedEntity(address to)`: Mints a new Entity NFT to `to`. Initial traits are determined by the current ecosystem state and pseudo-randomness. Requires `seedCost`.
    *   `feedEntity(uint256 tokenId)`: Increases the `energy` trait of the specified entity. Requires the caller to own or be approved for `tokenId`. Requires `feedingCost`.
    *   `exploreEnvironment(uint256 tokenId)`: Triggers an interaction between the entity and the ecosystem. Outcome depends on entity traits, ecosystem state, and pseudo-randomness, potentially affecting energy, traits, or mutation level. Requires the caller to own or be approved for `tokenId`. Requires `explorationCost`.
    *   `attemptMutation(uint256 tokenId)`: Attempts to randomly mutate one or more traits of the entity. Success chance and outcome depend on entity mutation level, ecosystem factors, and pseudo-randomness. Requires the caller to own or be approved for `tokenId`. Requires `mutationCost`.
    *   `breedEntities(uint256 token1, uint256 token2)`: Creates a new Entity NFT (offspring) from two parent entities. Offspring traits are derived from parents and influenced by ecosystem state. Requires the caller to own or be approved for *both* parent tokens. Requires `breedingFee` and parents to have sufficient energy/state.
    *   `evolveEcosystem()`: Publicly callable function to trigger a change in the global ecosystem state. Can only be called after a cooldown period has passed. Changes parameters like `ambientEnergy`, `environmentalElement`, and `mutationRateFactor` based on time/block and contract state.
*   **View Functions (Public/External):**
    *   `getEntityState(uint256 tokenId)`: Returns the full `EntityState` struct for `tokenId`.
    *   `getEcosystemState()`: Returns the current global `EcosystemState` struct.
    *   `getTrait(uint256 tokenId, uint256 traitIndex)`: Returns the value of a specific trait for the entity (using index 0 for energy, 1 for mutationLevel, etc.).
    *   `getEntityGeneration(uint256 tokenId)`: Returns the generation number of the entity.
    *   `getSeedCost()`, `getFeedingCost()`, `getExplorationCost()`, `getMutationCost()`, `getBreedingFee()`: Returns the current costs in Wei.
    *   `getRendererAddress()`: Returns the address of the external service/contract responsible for rendering the dynamic NFT metadata/image.
    *   `getEcosystemEvolutionCooldown()`: Returns the block count required between ecosystem evolutions.
    *   `getLastEcosystemEvolutionBlock()`: Returns the block number when the ecosystem last evolved.
    *   `calculateExplorationOutcome(uint256 tokenId)`: Simulates and returns the *potential* outcomes (e.g., energy change range, mutation chance) if the entity were to explore now, based on its state and the ecosystem. (Does not change state).
    *   `calculateMutationSuccess(uint256 tokenId)`: Simulates and returns the *chance* of successful mutation and potential trait impact if mutation were attempted now. (Does not change state).
    *   `calculateBreedingResult(uint256 token1, uint256 token2)`: Simulates and returns the *potential* trait ranges for a child if breeding between the two tokens were to occur now. (Does not change state).
*   **Admin/Owner Functions (External):**
    *   `setRendererAddress(address renderer)`: Sets the address for the dynamic NFT renderer (Owner only).
    *   `setSeedCost(uint256 cost)`, `setFeedingCost(uint256 cost)`, `setExplorationCost(uint256 cost)`, `setMutationCost(uint256 cost)`, `setBreedingFee(uint256 fee)`: Sets the costs for the respective actions (Owner only).
    *   `setEcosystemEvolutionCooldown(uint256 blocks)`: Sets the minimum block difference between ecosystem evolutions (Owner only).
    *   `withdrawFunds()`: Transfers the contract's accumulated Ether balance to the owner (Owner only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic interfaces needed for standard compatibility
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address to, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title EvolvingOnchainEcosystem
 * @dev A smart contract for a dynamic on-chain ecosystem with evolving NFT lifeforms.
 * Entities (NFTs) have traits that change based on user interactions and the global ecosystem state.
 * The ecosystem state itself evolves over time.
 * This implementation provides core ERC721 functionality manually for demonstration purposes,
 * focusing creativity on the ecosystem/evolution mechanics rather than standard library usage.
 */
contract EvolvingOnchainEcosystem is IERC721, IERC721Metadata {

    // --- Errors ---
    error NotOwnerOrApproved();
    error TokenDoesNotExist(uint256 tokenId);
    error InvalidRecipient(address recipient);
    error InsufficientFunds(uint256 required, uint256 sent);
    error InsufficientEnergy(uint256 tokenId, uint256 required, uint256 current);
    error BreedingConditionsNotMet(string reason);
    error EcosystemOnCooldown(uint256 blocksRemaining);
    error EvolutionConditionsNotMet(string reason);
    error InvalidTraitIndex(uint256 traitIndex);


    // --- Events ---
    event EntitySeeded(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event EntityFed(uint256 indexed tokenId, uint256 energyGained);
    event EntityExplored(uint256 indexed tokenId, string outcomeSummary, int256 energyChange, uint256 mutationChanceApplied);
    event EntityMutated(uint256 indexed tokenId, bool success, uint256 traitIndex, int256 change, uint256 newMutationLevel);
    event EntityBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, uint256 generation);
    event EcosystemEvolved(uint256 blockNumber, uint256 newAmbientEnergy, uint256 newEnvironmentalElement, uint256 newMutationRateFactor);
    event TraitChanged(uint256 indexed tokenId, uint256 traitIndex, uint256 oldValue, uint256 newValue);
    event CostUpdated(string action, uint256 newCost);
    event RendererAddressUpdated(address newAddress);
    event Withdrawal(address indexed recipient, uint256 amount);


    // --- Enums ---
    enum Element { NONE, FIRE, WATER, EARTH, AIR }

    // --- Structs ---

    /// @dev Represents the dynamic state of an individual entity (NFT).
    struct EntityState {
        uint256 energy;           // Health/Action points (e.g., 0-100)
        uint256 mutationLevel;    // How prone/capable of mutating it is (e.g., 0-100)
        uint256 adaptability;     // How well it handles different environments (e.g., 0-100)
        Element affinityElement;  // Affinity towards a specific ecosystem element
        uint256 generation;       // Generation number (0 for seeded, 1+ for bred)
        // Add more traits here as needed (e.g., strength, intelligence, speed)
        // uint256 strength;
        // uint256 intelligence;
    }

    /// @dev Represents the global state of the ecosystem.
    struct EcosystemState {
        uint256 ambientEnergy;         // Base energy level in the environment (influences feeding/exploration) (e.g., 0-100)
        Element environmentalElement;  // Dominant element in the environment (e.g., FIRE, WATER, EARTH, AIR)
        uint256 mutationRateFactor;    // Global factor influencing mutation success (e.g., 0-100)
        uint256 lastEvolutionBlock;    // Block number of the last ecosystem evolution
    }


    // --- State Variables ---

    // Owner for admin functions
    address private _owner;

    // ERC721 State
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;

    // Ecosystem State
    mapping(uint256 => EntityState) private _entityStates;
    EcosystemState private _ecosystemState;

    // Costs (in Wei)
    uint256 private _seedCost;
    uint256 private _feedingCost;
    uint256 private _explorationCost;
    uint256 private _mutationCost;
    uint256 private _breedingFee;

    // Metadata Renderer
    string private _name = "EvolvingLifeform";
    string private _symbol = "ECLF";
    address private _rendererAddress; // Address of a service/contract to generate dynamic JSON metadata

    // Ecosystem Evolution Control
    uint256 private _ecosystemEvolutionCooldownBlocks = 100; // Blocks required between evolutions

    // Pseudo-randomness counter (mix with block data)
    uint256 private _randomnessCounter = 0;


    // --- Constructor ---

    constructor(address initialRenderer) {
        _owner = msg.sender;

        // Set initial ecosystem state
        _ecosystemState = EcosystemState({
            ambientEnergy: 50,
            environmentalElement: Element.NONE, // Start neutral
            mutationRateFactor: 20,
            lastEvolutionBlock: block.number
        });

        // Set initial costs (example values)
        _seedCost = 0.01 ether;
        _feedingCost = 0.001 ether;
        _explorationCost = 0.002 ether;
        _mutationCost = 0.003 ether;
        _breedingFee = 0.005 ether;

        _rendererAddress = initialRenderer;

        _nextTokenId = 0; // Token IDs start from 0
    }


    // --- Modifiers ---
    // Manual ownership check instead of using OpenZeppelin's Ownable
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    // Internal helper to check ownership or approval
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Use public ownerOf to check existence
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- ERC721 Core Implementation ---

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // Dynamic Token URI - Points to an external renderer
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(_rendererAddress != address(0), "Renderer address not set");
        // Encode token ID as string and concatenate with renderer address
        // Example: ipfs://renderer_base_uri/123 or http://renderer.service/token/123
        // Using a simple string concat for demonstration. Real impl might use abi.encodePacked.
        return string(abi.encodePacked(Strings.fromAddress(_rendererAddress), "/", Strings.toString(tokenId)));
    }

    function approve(address to, uint256 tokenId) public payable override {
        address owner = ownerOf(tokenId); // Implies _exists check
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        // Check if msg.sender is allowed to transfer
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
        // Basic safety check - does not implement full ERC721Receiver hook check
        if (to.code.length > 0) {
             // In a real contract, you would call IERC721Receiver(to).onERC721Received(...)
             // Skipping for strict "no open source" and complexity reduction in this example.
             // Be aware this means transfers to contracts might fail silently or lock tokens
             // if the receiving contract is not designed to handle ERC721s without the hook.
        }
    }

    // Internal ERC721 helpers
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        // Update balances
        _balances[from]--;
        _balances[to]++;

        // Update ownership
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }


    // --- Custom Ecosystem & Entity Logic ---

    /// @dev Seeds a new entity into the ecosystem.
    /// Traits are influenced by the current ecosystem state.
    function seedEntity(address to) public payable {
        require(to != address(0), "Cannot mint to zero address");
        require(msg.value >= _seedCost, InsufficientFunds(_seedCost, msg.value));

        uint256 newTokenId = _nextTokenId++;

        _mint(to, newTokenId); // Mint the NFT

        // Generate initial traits based on ecosystem and block data
        _entityStates[newTokenId] = _generateInitialTraits(newTokenId);

        emit EntitySeeded(newTokenId, to, 0); // Generation 0 for seeded entities
    }

    /// @dev Increases an entity's energy.
    function feedEntity(uint256 tokenId) public payable {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        require(_isApprovedOrOwner(msg.sender, tokenId), NotOwnerOrApproved());
        require(msg.value >= _feedingCost, InsufficientFunds(_feedingCost, msg.value));

        EntityState storage entity = _entityStates[tokenId];
        uint256 energyGained = 10 + (_ecosystemState.ambientEnergy / 10); // Gain influenced by ambient energy

        // Apply some pseudo-random variation
        uint256 randomness = _getRandomness(tokenId, "feed");
        energyGained += (randomness % 5); // Add 0-4 extra energy

        uint256 oldEnergy = entity.energy;
        entity.energy = Math.min(100, entity.energy + energyGained); // Cap energy at 100

        if (entity.energy != oldEnergy) {
            emit TraitChanged(tokenId, 0, oldEnergy, entity.energy); // 0 index for energy
            emit EntityFed(tokenId, energyGained);
        }
    }

    /// @dev Entity explores the environment, leading to various outcomes.
    function exploreEnvironment(uint256 tokenId) public payable {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        require(_isApprovedOrOwner(msg.sender, tokenId), NotOwnerOrApproved());
        require(msg.value >= _explorationCost, InsufficientFunds(_explorationCost, msg.value));
        require(_entityStates[tokenId].energy >= 10, InsufficientEnergy(tokenId, 10, _entityStates[tokenId].energy)); // Exploration costs energy

        EntityState storage entity = _entityStates[tokenId];
        entity.energy -= 10; // Consume base energy

        int256 energyChange = -10; // Base energy cost
        string memory outcomeSummary = "Explored. Base energy cost.";
        uint256 mutationChanceApplied = 0;

        // Logic based on entity traits and ecosystem state
        uint256 affinityBonus = (entity.affinityElement == _ecosystemState.environmentalElement && entity.affinityElement != Element.NONE) ? 20 : 0;
        uint256 adaptabilityBonus = entity.adaptability / 5; // Adaptability helps everywhere

        uint256 effectiveExplorationScore = affinityBonus + adaptabilityBonus + (entity.energy / 10); // Energy also plays a role
        uint256 randomness = _getRandomness(tokenId, "explore");

        // Determine outcome category based on score and randomness
        if (effectiveExplorationScore + (randomness % 30) > 70) { // Highly positive outcome
            int256 gained = 20 + (randomness % 15); // Gain 20-34 energy
            entity.energy = Math.min(100, entity.energy + uint256(gained));
            energyChange += gained;
            outcomeSummary = "Explored successfully! Found abundant energy.";
            // Maybe slight positive mutation chance
            mutationChanceApplied = 5;
        } else if (effectiveExplorationScore + (randomness % 30) > 40) { // Moderately positive/neutral
             int256 gained = 5 + (randomness % 10); // Gain 5-14 energy
            entity.energy = Math.min(100, entity.energy + uint256(gained));
            energyChange += gained;
            outcomeSummary = "Explored. Found some energy.";
        } else if (effectiveExplorationScore + (randomness % 30) > 20) { // Slightly negative/neutral
            // Nothing found, just energy cost
             outcomeSummary = "Explored. Found little.";
        } else { // Highly negative outcome
            int256 lost = 10 + (randomness % 10); // Lose 10-19 extra energy
            entity.energy = entity.energy >= uint256(lost) ? entity.energy - uint256(lost) : 0;
            energyChange -= lost;
            outcomeSummary = "Explored. Encountered harsh conditions, lost energy.";
            // Maybe slight negative mutation chance or mutation level increase
            mutationChanceApplied = 10; // Higher chance of *some* mutation
        }

        // Apply mutation chance (does not guarantee mutation, just increases the level or triggers attempt)
        if (mutationChanceApplied > 0 && (randomness % 100) < mutationChanceApplied) {
             entity.mutationLevel = Math.min(100, entity.mutationLevel + (randomness % 5)); // Increase mutation potential
             outcomeSummary = string(abi.encodePacked(outcomeSummary, " Mutation potential increased."));
        }

        emit TraitChanged(tokenId, 0, entity.energy + uint256(10), entity.energy); // Energy change
        emit EntityExplored(tokenId, outcomeSummary, energyChange, mutationChanceApplied);
    }

    /// @dev Attempts to mutate an entity's traits.
    function attemptMutation(uint256 tokenId) public payable {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        require(_isApprovedOrOwner(msg.sender, tokenId), NotOwnerOrApproved());
        require(msg.value >= _mutationCost, InsufficientFunds(_mutationCost, msg.value));
        require(_entityStates[tokenId].energy >= 20, InsufficientEnergy(tokenId, 20, _entityStates[tokenId].energy)); // Mutation costs energy

        EntityState storage entity = _entityStates[tokenId];
        entity.energy -= 20; // Consume energy

        emit TraitChanged(tokenId, 0, entity.energy + 20, entity.energy); // Energy change

        uint256 randomness = _getRandomness(tokenId, "mutate");
        uint256 effectiveMutationChance = entity.mutationLevel / 2 + _ecosystemState.mutationRateFactor / 2; // 50/50 influence

        bool mutationSuccess = (randomness % 100) < effectiveMutationChance;
        uint256 traitIndex = (randomness / 100) % 4; // Select one of the 4 main traits (energy, mutationLevel, adaptability, affinityElement)

        int256 change = 0;
        uint256 oldTraitValue = 0;
        uint256 newTraitValue = 0;

        if (mutationSuccess) {
            // Determine magnitude and direction of change
            change = int256((randomness / 400) % 10) + 1; // Change by 1 to 10
            if ((randomness / 4000) % 2 == 1) change = -change; // 50% chance of negative change

            if (traitIndex == 0) { // Energy (less likely to mutate directly, maybe recovers energy instead?)
                // Mutating energy trait could mean a permanent shift in max energy or regen rate.
                // For simplicity, let's make it a temporary large energy boost/drain.
                 oldTraitValue = entity.energy;
                 if (change > 0) entity.energy = Math.min(100, entity.energy + uint256(change * 5)); // Big boost
                 else entity.energy = entity.energy >= uint256(-change * 5) ? entity.energy - uint256(-change * 5) : 0; // Big drain
                 newTraitValue = entity.energy;
                 change *= 5; // Magnify energy change reporting
            } else if (traitIndex == 1) { // MutationLevel
                oldTraitValue = entity.mutationLevel;
                if (change > 0) entity.mutationLevel = Math.min(100, entity.mutationLevel + uint256(change));
                else entity.mutationLevel = entity.mutationLevel >= uint256(-change) ? entity.mutationLevel - uint256(-change) : 0;
                newTraitValue = entity.mutationLevel;
            } else if (traitIndex == 2) { // Adaptability
                oldTraitValue = entity.adaptability;
                if (change > 0) entity.adaptability = Math.min(100, entity.adaptability + uint256(change));
                else entity.adaptability = entity.adaptability >= uint256(-change) ? entity.adaptability - uint256(-change) : 0;
                 newTraitValue = entity.adaptability;
            } else if (traitIndex == 3) { // AffinityElement
                oldTraitValue = uint256(entity.affinityElement);
                 if (change > 0) { // Shift towards next element
                     entity.affinityElement = Element((uint256(entity.affinityElement) + 1) % 5); // Cycle through elements
                 } else { // Shift towards previous element
                      entity.affinityElement = Element((uint256(entity.affinityElement) + 5 - 1) % 5); // Cycle backwards
                 }
                 newTraitValue = uint256(entity.affinityElement);
                 change = int256(newTraitValue) - int256(oldTraitValue); // Report change as difference in enum index
            }
             // Note: generation cannot be mutated directly

             // Increase mutation level slightly regardless of outcome to make future mutations more likely/intense
             entity.mutationLevel = Math.min(100, entity.mutationLevel + 2);
             emit TraitChanged(tokenId, 1, entity.mutationLevel - 2, entity.mutationLevel); // Report mutationLevel increase

            if (traitIndex != 0) { // Don't double-emit energy change
                emit TraitChanged(tokenId, traitIndex, oldTraitValue, newTraitValue);
            }
        } else {
            // Mutation failed, maybe slightly increase mutation potential anyway from the attempt
             entity.mutationLevel = Math.min(100, entity.mutationLevel + 1);
             emit TraitChanged(tokenId, 1, entity.mutationLevel - 1, entity.mutationLevel); // Report mutationLevel increase
        }

        emit EntityMutated(tokenId, mutationSuccess, traitIndex, change, entity.mutationLevel);
    }

    /// @dev Breeds two entities to create a new offspring entity.
    function breedEntities(uint256 token1, uint256 token2) public payable {
        require(_exists(token1), TokenDoesNotExist(token1));
        require(_exists(token2), TokenDoesNotExist(token2));
        require(token1 != token2, "Cannot breed entity with itself");
        require(_isApprovedOrOwner(msg.sender, token1), NotOwnerOrApproved());
        require(_isApprovedOrOwner(msg.sender, token2), NotOwnerOrApproved());
        require(msg.value >= _breedingFee, InsufficientFunds(_breedingFee, msg.value));

        EntityState storage parent1 = _entityStates[token1];
        EntityState storage parent2 = _entityStates[token2];

        // Breeding requirements
        require(parent1.energy >= 40 && parent2.energy >= 40, BreedingConditionsNotMet("Insufficient energy"));
        require(parent1.generation < 100 && parent2.generation < 100, BreedingConditionsNotMet("Generation cap reached")); // Example cap

        // Consume energy from parents
        parent1.energy -= 40;
        parent2.energy -= 40;
        emit TraitChanged(token1, 0, parent1.energy + 40, parent1.energy);
        emit TraitChanged(token2, 0, parent2.energy + 40, parent2.energy);


        uint256 newTokenId = _nextTokenId++;
        address childOwner = msg.sender; // Child goes to the caller

        _mint(childOwner, newTokenId);

        // Logic for determining child traits - mix of parents + ecosystem influence + randomness
        uint256 randomness = _getRandomness(token1 + token2, "breed");

        EntityState memory childState;
        childState.generation = Math.max(parent1.generation, parent2.generation) + 1;
        childState.energy = 50; // Start with base energy

        // Inherit traits with variability and ecosystem influence
        childState.mutationLevel = (parent1.mutationLevel + parent2.mutationLevel) / 2;
        childState.mutationLevel = Math.min(100, childState.mutationLevel + (_ecosystemState.mutationRateFactor / 20) + (randomness % 10) - 5); // Avg + ecosystem + random

        childState.adaptability = (parent1.adaptability + parent2.adaptability) / 2;
        childState.adaptability = Math.min(100, childState.adaptability + (_ecosystemState.ambientEnergy / 20) + ((randomness / 10) % 10) - 5); // Avg + ecosystem + random

        // Affinity element: can inherit one parent's, average (if mapping), or shift towards ecosystem element
        // Simple: 50/50 chance of parent1/parent2, strong influence from ecosystem element if dominant
        if ((randomness / 100) % 2 == 0) {
             childState.affinityElement = parent1.affinityElement;
        } else {
             childState.affinityElement = parent2.affinityElement;
        }
        // Ecosystem nudge: If ecosystem element is strong (e.g., > 70 ambient energy) and not NONE, 20% chance child gets ecosystem affinity
         if (_ecosystemState.ambientEnergy > 70 && _ecosystemState.environmentalElement != Element.NONE && ((randomness / 200) % 5 == 0)) {
              childState.affinityElement = _ecosystemState.environmentalElement;
         }


        _entityStates[newTokenId] = childState;

        emit EntityBred(token1, token2, newTokenId, childState.generation);
        emit EntitySeeded(newTokenId, childOwner, childState.generation); // Also emit seeded for new token
    }

    /// @dev Publicly callable function to trigger an ecosystem evolution.
    /// This changes the global state parameters within certain bounds.
    function evolveEcosystem() public {
        require(block.number >= _ecosystemState.lastEvolutionBlock + _ecosystemEvolutionCooldownBlocks, EcosystemOnCooldown(_ecosystemState.lastEvolutionBlock + _ecosystemEvolutionCooldownBlocks - block.number));

        _updateEcosystemState();

        emit EcosystemEvolved(
            block.number,
            _ecosystemState.ambientEnergy,
            uint256(_ecosystemState.environmentalElement),
            _ecosystemState.mutationRateFactor
        );
    }


    // --- View Functions ---

    function getEntityState(uint256 tokenId) public view returns (EntityState memory) {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        return _entityStates[tokenId];
    }

    function getEcosystemState() public view returns (EcosystemState memory) {
        return _ecosystemState;
    }

    function getTrait(uint256 tokenId, uint256 traitIndex) public view returns (uint256) {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        require(traitIndex < 5, InvalidTraitIndex(traitIndex)); // Energy, Mutation, Adaptability, Affinity (as uint), Generation

        EntityState memory entity = _entityStates[tokenId];
        if (traitIndex == 0) return entity.energy;
        if (traitIndex == 1) return entity.mutationLevel;
        if (traitIndex == 2) return entity.adaptability;
        if (traitIndex == 3) return uint256(entity.affinityElement);
        if (traitIndex == 4) return entity.generation;
        // Should not reach here due to require
        return 0;
    }

    function getEntityGeneration(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), TokenDoesNotExist(tokenId));
         return _entityStates[tokenId].generation;
    }

    function getSeedCost() public view returns (uint256) { return _seedCost; }
    function getFeedingCost() public view returns (uint256) { return _feedingCost; }
    function getExplorationCost() public view returns (uint256) { return _explorationCost; }
    function getMutationCost() public view returns (uint256) { return _mutationCost; }
    function getBreedingFee() public view returns (uint256) { return _breedingFee; }
    function getRendererAddress() public view returns (address) { return _rendererAddress; }
    function getEcosystemEvolutionCooldown() public view returns (uint256) { return _ecosystemEvolutionCooldownBlocks; }
    function getLastEcosystemEvolutionBlock() public view returns (uint256) { return _ecosystemState.lastEvolutionBlock; }


    /// @dev Calculates potential outcomes of exploration without changing state.
    function calculateExplorationOutcome(uint256 tokenId) public view returns (string memory outcomeSummary, int256 energyChangeRangeMin, int256 energyChangeRangeMax, uint256 mutationChance) {
        require(_exists(tokenId), TokenDoesNotExist(tokenId));
        EntityState memory entity = _entityStates[tokenId];

        if (entity.energy < 10) return ("Insufficient energy to explore.", 0, 0, 0);

        int256 baseCost = -10;
        int256 potentialGainMin = 5; int256 potentialGainMax = 34; // Based on exploreEnvironment logic
        int256 potentialLossMin = -10; int256 potentialLossMax = -19; // Based on exploreEnvironment logic

        // This simulation cannot use block.timestamp/number reliably for *future* randomness
        // We can provide ranges based on trait/ecosystem influence
        uint256 affinityBonus = (entity.affinityElement == _ecosystemState.environmentalElement && entity.affinityElement != Element.NONE) ? 20 : 0;
        uint256 adaptabilityBonus = entity.adaptability / 5;
        uint256 effectiveScore = affinityBonus + adaptabilityBonus + (entity.energy / 10);

        // Estimate potential outcomes based on effective score
        string memory summary;
        int256 minChange = baseCost;
        int256 maxChange = baseCost;
        uint256 estMutationChance = 0; // Estimated chance applied *after* exploration logic

        if (effectiveScore > 50) { // Likely positive
            summary = "Likely to find energy, maybe positive mutation chance increase.";
            minChange += potentialGainMin;
            maxChange += potentialGainMax;
            estMutationChance = 5;
        } else if (effectiveScore > 20) { // Mixed/Neutral
            summary = "Mixed results possible, some energy gain likely.";
            minChange += potentialGainMin;
            maxChange += potentialGainMax;
             maxChange = Math.max(maxChange, baseCost); // Ensure it doesn't look *too* good if score is just okay
        } else { // Likely negative
             summary = "Harsh conditions likely, potential energy loss.";
             minChange += potentialLossMin;
             maxChange += potentialLossMax;
             estMutationChance = 10;
        }

        return (summary, minChange, maxChange, estMutationChance);
    }


    /// @dev Calculates the chance of successful mutation without changing state.
     function calculateMutationSuccess(uint256 tokenId) public view returns (uint256 successChance, string memory potentialOutcomes) {
         require(_exists(tokenId), TokenDoesNotExist(tokenId));
         EntityState memory entity = _entityStates[tokenId];

         if (entity.energy < 20) return (0, "Insufficient energy to attempt mutation.");

         uint256 effectiveMutationChance = entity.mutationLevel / 2 + _ecosystemState.mutationRateFactor / 2;
         string memory outcomes = "Potential outcomes: Energy change (large), Mutation Level change (small), Adaptability change (small), Affinity Element shift.";

         return (effectiveMutationChance, outcomes);
     }

    /// @dev Calculates potential child traits from breeding two entities without changing state.
    function calculateBreedingResult(uint256 token1, uint256 token2) public view returns (uint256 estimatedGeneration, uint256 estimatedMutationLevel, uint256 estimatedAdaptability, Element estimatedAffinityElement, string memory notes) {
        require(_exists(token1), TokenDoesNotExist(token1));
        require(_exists(token2), TokenDoesNotExist(token2));
        require(token1 != token2, "Cannot breed entity with itself");

        EntityState memory parent1 = _entityStates[token1];
        EntityState memory parent2 = _entityStates[token2];

        if (parent1.energy < 40 || parent2.energy < 40) return (0, 0, 0, Element.NONE, "Insufficient parent energy for breeding.");
        if (parent1.generation >= 100 || parent2.generation >= 100) return (0, 0, 0, Element.NONE, "Parent generation cap reached.");


        uint256 estGen = Math.max(parent1.generation, parent2.generation) + 1;
        uint256 estMut = (parent1.mutationLevel + parent2.mutationLevel) / 2;
        estMut = Math.min(100, estMut + (_ecosystemState.mutationRateFactor / 20)); // Estimate ecosystem nudge

        uint256 estAdapt = (parent1.adaptability + parent2.adaptability) / 2;
        estAdapt = Math.min(100, estAdapt + (_ecosystemState.ambientEnergy / 20)); // Estimate ecosystem nudge

        Element estAffinity;
        // Cannot predict randomness, so note possibilities
        string memory affinityNote = "Affinity Element: Inherits one parent's affinity, potential nudge towards Ecosystem Element.";

        // Can't predict exact child affinity without randomness, show one example or parent1's
        estAffinity = parent1.affinityElement; // Just show parent1's as an example

        return (estGen, estMut, estAdapt, estAffinity, affinityNote);
    }


    // --- Admin/Owner Functions ---

    function setRendererAddress(address renderer) public onlyOwner {
        _rendererAddress = renderer;
        emit RendererAddressUpdated(renderer);
    }

    function setSeedCost(uint256 cost) public onlyOwner {
        _seedCost = cost;
        emit CostUpdated("Seed", cost);
    }

    function setFeedingCost(uint256 cost) public onlyOwner {
        _feedingCost = cost;
        emit CostUpdated("Feeding", cost);
    }

    function setExplorationCost(uint256 cost) public onlyOwner {
        _explorationCost = cost;
        emit CostUpdated("Exploration", cost);
    }

    function setMutationCost(uint256 cost) public onlyOwner {
        _mutationCost = cost;
        emit CostUpdated("Mutation", cost);
    }

    function setBreedingFee(uint256 fee) public onlyOwner {
        _breedingFee = fee;
        emit CostUpdated("Breeding", fee);
    }

    function setEcosystemEvolutionCooldown(uint256 blocks) public onlyOwner {
        _ecosystemEvolutionCooldownBlocks = blocks;
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(_owner).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawal(_owner, balance);
    }


    // --- Internal Helper Functions ---

    /// @dev Generates initial traits for a new entity based on current ecosystem state.
    function _generateInitialTraits(uint256 tokenId) internal view returns (EntityState memory) {
         uint256 randomness = _getRandomness(tokenId, "seed");

        EntityState memory newState;
        newState.energy = 75; // Start with good energy
        newState.generation = 0; // Seeded entities are generation 0

        // Traits influenced by ecosystem state and randomness
        newState.mutationLevel = 10 + (_ecosystemState.mutationRateFactor / 10) + (randomness % 5); // Base + eco + random
        newState.adaptability = 50 + (_ecosystemState.ambientEnergy / 20) - 10 + ((randomness / 10) % 5); // Base + eco + random

        // Initial affinity based on dominant ecosystem element, or random if none
        uint256 elementRand = (randomness / 100) % 5;
        if (_ecosystemState.environmentalElement != Element.NONE) {
            // Higher chance to get affinity to dominant element
            if (elementRand < 3) { // 60% chance
                 newState.affinityElement = _ecosystemState.environmentalElement;
            } else { // 40% chance of random other element
                 newState.affinityElement = Element(elementRand); // elementRand will be 3 or 4, map to Earth/Air
            }
        } else {
             newState.affinityElement = Element(elementRand); // Random element if ecosystem is NONE
        }

        // Cap all stats at 100 (except generation/energy which have specific rules)
        newState.mutationLevel = Math.min(100, newState.mutationLevel);
        newState.adaptability = Math.min(100, newState.adaptability);

        return newState;
    }

    /// @dev Updates the global ecosystem state based on time/blocks and pseudo-randomness.
    function _updateEcosystemState() internal {
        // Logic to evolve ecosystem state
        // Example: Cycle element, randomly change ambient energy and mutation factor within bounds

        uint256 randomness = _getRandomness(block.number, "evolve");

        // Cycle environmental element every few evolutions? Or random change?
        // Let's make it a random shift with a chance to stay the same
        uint256 elementShift = randomness % 10; // 0-9
        if (elementShift < 2) { // 20% chance to stay
             // Stay the same
        } else if (elementShift < 6) { // 40% chance to shift forward
             _ecosystemState.environmentalElement = Element((uint256(_ecosystemState.environmentalElement) + 1) % 5);
        } else { // 40% chance to shift backward
             _ecosystemState.environmentalElement = Element((uint256(_ecosystemState.environmentalElement) + 5 - 1) % 5);
        }


        // Randomly change ambient energy (e.g., +/- 10, bounded 0-100)
        int256 energyChange = int256((randomness / 10) % 21) - 10; // Range -10 to +10
        _ecosystemState.ambientEnergy = uint256(int256(_ecosystemState.ambientEnergy) + energyChange);
        _ecosystemState.ambientEnergy = Math.max(0, Math.min(100, _ecosystemState.ambientEnergy)); // Clamp between 0 and 100

        // Randomly change mutation rate factor (e.g., +/- 5, bounded 0-100)
        int256 mutationChange = int256((randomness / 100) % 11) - 5; // Range -5 to +5
        _ecosystemState.mutationRateFactor = uint256(int256(_ecosystemState.mutationRateFactor) + mutationChange);
        _ecosystemState.mutationRateFactor = Math.max(0, Math.min(100, _ecosystemState.mutationRateFactor)); // Clamp between 0 and 100


        _ecosystemState.lastEvolutionBlock = block.number;
    }


    /// @dev Provides a basic pseudo-random number generator.
    /// WARNING: This is NOT cryptographically secure and susceptible to miner manipulation.
    /// Use only for non-critical in-game randomness where absolute unpredictability isn't required.
    function _getRandomness(uint256 seedModifier, string memory actionContext) internal returns (uint256) {
        _randomnessCounter++; // Increment counter to ensure unique hash each call within the same block
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seedModifier, actionContext, _randomnessCounter));
        return uint256(hash);
    }

    // --- Libraries (needed for basic operations) ---
    // Minimal Math and Strings libraries included to avoid large OZ imports

    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }

    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by Assembly script implementation
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {
                length++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(length);
            while (value != 0) {
                length--;
                buffer[length] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }

         function fromAddress(address account) internal pure returns (string memory) {
            bytes32 value = bytes32(uint256(account));
            bytes memory buffer = new bytes(40);
            for (uint256 i = 0; i < 20; i++) {
                buffer[i * 2] = _HEX_SYMBOLS[uint8(value[i + 12] >> 4)];
                buffer[i * 2 + 1] = _HEX_SYMBOLS[uint8(value[i + 12] & 0x0f)];
            }
            return string(buffer);
        }
    }

    // Fallback/Receive to accept Ether for payable functions
    receive() external payable {}
    fallback() external payable {}
}
```