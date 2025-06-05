Okay, here is a smart contract concept called `EvolutionaryNFT`. It's an ERC721-based contract where NFTs can evolve through interactions like crossbreeding, challenges, and mutations, influenced by an internal 'genome' and a 'Catalyst' resource (simulated here as an internal balance or interaction with an external token, for simplicity let's make it an internal resource represented by points earned within the system, but it's easy to swap for an ERC20 interface).

This concept is advanced because:
1.  **Dynamic State:** NFTs have internal state (`genome`, `xp`, `generation`) that changes.
2.  **Complex Interactions:** Crossbreeding, challenges, mutations, and battles are defined interactions that affect NFT state and can mint new tokens.
3.  **Internal "Genome":** A structured set of traits influencing outcomes and evolution.
4.  **Simulated Resource Management:** Introduces a `Catalyst` resource needed for advanced operations.
5.  **On-chain Logic for Metadata:** The contract defines how the NFT's properties map to traits, intended for dynamic metadata generation.

It avoids common open-source examples like simple staking, basic fixed-trait NFTs, or standard fractionalization.

---

## Contract Outline: `EvolutionaryNFT`

1.  **Core Standard:** ERC721 Non-Fungible Token.
2.  **Dynamic Properties:** Each token has a `Genome`, `XP (Experience Points)`, and `Generation`.
3.  **Resource:** Uses an internal concept of `Catalyst` points for operations.
4.  **Evolution Mechanisms:**
    *   **Crossbreeding:** Combine two parent NFTs to potentially mint a new one.
    *   **Challenges:** NFTs participate in defined challenges to earn XP and Catalyst.
    *   **Mutation:** Randomly alter an NFT's genome using Catalyst and XP.
    *   **Levelling Up:** Use XP and Catalyst to increase Generation and boost stats.
    *   **Battles:** Pitting two NFTs against each other based on stats for rewards.
5.  **Metadata:** Dynamically generated based on the NFT's current state (`genome`, `xp`, `generation`).

---

## Function Summary:

1.  `constructor()`: Initializes contract, sets base costs.
2.  `mintGenesis(address to)`: Mints initial "genesis" NFTs (owner/admin only).
3.  `balanceOf(address owner)`: ERC721 standard. Returns the number of tokens owned by an address.
4.  `ownerOf(uint256 tokenId)`: ERC721 standard. Returns the owner of a specific token.
5.  `approve(address to, uint256 tokenId)`: ERC721 standard. Approves another address to transfer a token.
6.  `getApproved(uint256 tokenId)`: ERC721 standard. Gets the approved address for a token.
7.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard. Sets approval for an operator for all tokens.
8.  `isApprovedForAll(address owner, address operator)`: ERC721 standard. Checks if an operator is approved for all tokens of an owner.
9.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. Transfers a token without checking receiver support.
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. Transfers a token checking receiver support.
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard. Transfers a token checking receiver support with data.
12. `totalSupply()`: Returns the total number of tokens minted.
13. `tokenURI(uint256 tokenId)`: ERC721 standard. Returns the metadata URI for a token.
14. `getGenome(uint256 tokenId)`: Returns the `Genome` struct of a token.
15. `getXP(uint256 tokenId)`: Returns the current XP of a token.
16. `getGeneration(uint256 tokenId)`: Returns the current Generation of a token.
17. `getTraits(uint256 tokenId)`: Converts the genome/state into a more human-readable trait representation.
18. `crossbreed(uint256 parent1Id, uint256 parent2Id)`: Combines two parent NFTs to potentially mint a new child NFT, consuming Catalyst.
19. `levelUp(uint256 tokenId)`: Spends XP and Catalyst to increase the token's generation and base stats.
20. `mutate(uint256 tokenId)`: Spends Catalyst and XP to randomly alter the token's genome within bounds.
21. `initiateChallenge(uint256 tokenId, uint8 challengeType)`: Commits an NFT to a specific type of challenge.
22. `completeChallenge(uint256 tokenId)`: Resolves a challenge after a duration, potentially granting XP and Catalyst based on outcome. (Outcome simulated internally for simplicity).
23. `withdrawFromChallenge(uint256 tokenId)`: Allows withdrawing an NFT from a challenge before completion (with potential penalty).
24. `battle(uint256 tokenId1, uint256 tokenId2)`: Initiates a battle simulation between two NFTs, rewarding the winner with XP/Catalyst.
25. `setBaseURI(string memory newBaseURI)`: Owner only. Sets the base URI for metadata.
26. `setEvolutionCosts(uint256 _crossbreedCost, uint256 _levelUpCost, uint256 _mutateCost, uint256 _challengeInitiationCost, uint256 _battleCost)`: Owner only. Sets the Catalyst costs for various operations.
27. `setChallengeDuration(uint8 challengeType, uint64 durationSeconds)`: Owner only. Sets duration for challenge types.
28. `generateMetadataJSON(uint256 tokenId)`: Internal/Public helper (can be called externally to preview data) to generate the JSON string logic for metadata.
29. `supportsInterface(bytes4 interfaceId)`: ERC165 standard. Indicates support for interfaces.
30. `getChallengeState(uint256 tokenId)`: Returns the current challenge state of a token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Note: For production use, consider using Chainlink VRF for secure randomness
// instead of block hash and timestamp. This example uses simpler pseudo-randomness
// for illustration without external oracle dependency.

/**
 * @title EvolutionaryNFT
 * @dev An ERC721 contract where NFTs evolve through crossbreeding, challenges,
 * and mutations, influenced by an internal genome and catalyst resource.
 */
contract EvolutionaryNFT is ERC165, IERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Constants ---
    uint256 public constant XP_PER_GENERATION = 100; // XP needed to level up base generation
    uint256 public constant XP_PER_MUTATION = 50; // XP needed for mutation (in addition to catalyst)
    uint8 public constant MAX_GENOME_VALUE = 255; // Max value for a single genome trait
    uint8 public constant MIN_GENOME_VALUE = 1;   // Min value for a single genome trait

    // --- State Variables ---
    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    Counters.Counter private _tokenIdCounter;

    // ERC721 Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // NFT Custom State Mappings
    struct Genome {
        uint8 strength;
        uint8 agility;
        uint8 intelligence;
        uint8 vitality;
        // Could add more traits like bytes3 color, uint16 shape, etc.
    }
    mapping(uint256 => Genome) private _tokenGenomes;
    mapping(uint256 => uint256) private _tokenXP;
    mapping(uint256 => uint256) private _tokenGeneration; // Starts at 1

    // Challenge State Mappings
    struct Challenge {
        uint8 challengeType; // Type identifier (e.g., 1=Quest, 2=Training, 3=Exploration)
        uint64 timestampInitiated;
        bool active; // Is the token currently in a challenge
        bool completed; // Has the challenge finished
        uint256 xpReward;
        uint256 catalystReward; // Simulated catalyst earned
        bytes outcomeData; // Potential data about the challenge outcome
    }
    mapping(uint256 => Challenge) private _tokenChallengeState;
    mapping(uint8 => uint64) public challengeDuration; // Duration for each challenge type

    // Costs (in Catalyst points)
    uint256 public crossbreedCost;
    uint256 public levelUpCost;
    uint256 public mutateCost;
    uint256 public challengeInitiationCost;
    uint256 public battleCost;

    // Simplified Catalyst Resource: Earned and spent internally
    // In a real system, this would likely interact with a separate ERC20 Catalyst token contract
    mapping(address => uint256) private _userCatalystBalance;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event GenesisMinted(address indexed owner, uint256 indexed tokenId);
    event Crossbred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address indexed owner);
    event LeveledUp(uint256 indexed tokenId, uint256 newGeneration, uint256 newXP);
    event Mutated(uint256 indexed tokenId, Genome newGenome);
    event ChallengeInitiated(uint256 indexed tokenId, uint8 challengeType, uint64 timestampInitiated);
    event ChallengeCompleted(uint256 indexed tokenId, uint256 xpEarned, uint256 catalystEarned, bytes outcomeData);
    event ChallengeWithdrawn(uint256 indexed tokenId);
    event BattleConcluded(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 winnerTokenId, uint256 xpEarned, uint256 catalystEarned);
    event CatalystEarned(address indexed owner, uint256 amount);
    event CatalystSpent(address indexed owner, uint256 amount);

    // --- Access Control (Basic Owner) ---
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;

        // Set initial default costs (can be changed by owner)
        crossbreedCost = 100;
        levelUpCost = 50;
        mutateCost = 75;
        challengeInitiationCost = 20;
        battleCost = 30;

        // Set default challenge durations (can be changed by owner)
        challengeDuration[1] = 1 hours; // Quest
        challengeDuration[2] = 2 hours; // Training
        challengeDuration[3] = 4 hours; // Exploration
    }

    // --- ERC721 Standard Implementations ---

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId); // Throws if token doesn't exist
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
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

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check allowance
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner"); // ownerOf checks existence
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Internal mint logic
    function _mint(address to, uint256 tokenId, Genome memory initialGenome, uint256 initialXP, uint256 initialGeneration) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;
        _tokenGenomes[tokenId] = initialGenome;
        _tokenXP[tokenId] = initialXP;
        _tokenGeneration[tokenId] = initialGeneration;

        emit Transfer(address(0), to, tokenId);
    }

    // Internal burn logic (optional, but good practice)
    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId); // Checks existence

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner_]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];

        // Also delete custom state
        delete _tokenGenomes[tokenId];
        delete _tokenXP[tokenId];
        delete _tokenGeneration[tokenId];
        delete _tokenChallengeState[tokenId]; // Clear challenge state if any

        emit Transfer(owner_, address(0), tokenId);
    }

    // Helper to check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Helper to check approval or ownership
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId); // Checks existence
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    // Helper to set token approval (internal)
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    // Helper to check ERC721Receiver
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length > 0) {
                    revert(string(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer ", string(reason))));
                } else {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
            }
        } else {
            return true; // It's a plain address, no receiver check needed
        }
    }

    // --- Custom Contract Logic ---

    /**
     * @dev Mints initial "genesis" NFTs. Restricted to contract owner.
     * @param to The address to mint the token to.
     */
    function mintGenesis(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Generate a simple initial genome for genesis tokens
        Genome memory initialGenome = Genome({
            strength: uint8(50 + (newItemId % 10)), // Base stats + variation
            agility: uint8(50 + (newItemId % 10)),
            intelligence: uint8(50 + (newItemId % 10)),
            vitality: uint8(50 + (newItemId % 10))
            // colorCode: bytes3(uint24(keccak256(abi.encodePacked(newItemId)))) // Example random color
        });

        _mint(to, newItemId, initialGenome, 0, 1); // Starts with 0 XP, Generation 1
        emit GenesisMinted(to, newItemId);
        return newItemId;
    }

    /**
     * @dev Returns the base URI for token metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real application, this base URI would likely point to a server
        // that serves dynamic JSON based on the token ID and its state.
        // Example: "https://api.evolutionarynft.com/metadata/" + tokenId.toString()
        // For on-chain generation logic visualization, see generateMetadataJSON
        string memory base = _baseTokenURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    /**
     * @dev Sets the base URI for token metadata. Owner only.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets the Catalyst costs for various operations. Owner only.
     */
    function setEvolutionCosts(
        uint256 _crossbreedCost,
        uint256 _levelUpCost,
        uint256 _mutateCost,
        uint256 _challengeInitiationCost,
        uint256 _battleCost
    ) public onlyOwner {
        crossbreedCost = _crossbreedCost;
        levelUpCost = _levelUpCost;
        mutateCost = _mutateCost;
        challengeInitiationCost = _challengeInitiationCost;
        battleCost = _battleCost;
    }

    /**
     * @dev Sets the duration for a specific challenge type. Owner only.
     * @param challengeType The type identifier.
     * @param durationSeconds The duration in seconds.
     */
    function setChallengeDuration(uint8 challengeType, uint64 durationSeconds) public onlyOwner {
        challengeDuration[challengeType] = durationSeconds;
    }

    /**
     * @dev Gets the Catalyst balance for a user.
     * @param user The address to check.
     * @return The user's Catalyst balance.
     */
    function getCatalystBalance(address user) public view returns (uint256) {
        return _userCatalystBalance[user];
    }

    /**
     * @dev Internal function to spend Catalyst.
     * @param user The user whose balance to decrease.
     * @param amount The amount to spend.
     */
    function _spendCatalyst(address user, uint256 amount) internal {
        require(_userCatalystBalance[user] >= amount, "Not enough Catalyst");
        _userCatalystBalance[user] -= amount;
        emit CatalystSpent(user, amount);
    }

    /**
     * @dev Internal function to earn Catalyst.
     * @param user The user whose balance to increase.
     * @param amount The amount to earn.
     */
    function _earnCatalyst(address user, uint256 amount) internal {
        _userCatalystBalance[user] += amount;
        emit CatalystEarned(user, amount);
    }

    // --- NFT State Getters ---

    function getGenome(uint256 tokenId) public view returns (Genome memory) {
        require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
        return _tokenGenomes[tokenId];
    }

    function getXP(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
        return _tokenXP[tokenId];
    }

    function getGeneration(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
        return _tokenGeneration[tokenId];
    }

    /**
     * @dev Generates a human-readable trait summary for a token.
     * @param tokenId The ID of the token.
     * @return A string representing the token's traits.
     */
    function getTraits(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
        Genome memory genome = _tokenGenomes[tokenId];
        uint256 xp = _tokenXP[tokenId];
        uint256 generation = _tokenGeneration[tokenId];

        return string(abi.encodePacked(
            "Gen: ", generation.toString(),
            ", XP: ", xp.toString(),
            ", Str: ", genome.strength.toString(),
            ", Agi: ", genome.agility.toString(),
            ", Int: ", genome.intelligence.toString(),
            ", Vit: ", genome.vitality.toString()
            // Add colorCode formatting if included
        ));
    }

    /**
     * @dev Provides the logic for generating the metadata JSON content.
     * This function doesn't return a data URI directly due to potential gas limits,
     * but shows how the contract state maps to the metadata structure.
     * An off-chain service would call this data, format it, and serve via tokenURI.
     * @param tokenId The ID of the token.
     * @return A string containing the potential JSON metadata content.
     */
    function generateMetadataJSON(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
        Genome memory genome = _tokenGenomes[tokenId];
        uint256 xp = _tokenXP[tokenId];
        uint256 generation = _tokenGeneration[tokenId];

        // Basic example JSON structure
        return string(abi.encodePacked(
            '{"name": "Evolutionary NFT #', tokenId.toString(),
            '", "description": "An evolving digital entity.",',
            '"attributes": [',
            '{"trait_type": "Generation", "value": ', generation.toString(), '},',
            '{"trait_type": "Experience", "value": ', xp.toString(), '},',
            '{"trait_type": "Strength", "value": ', genome.strength.toString(), '},',
            '{"trait_type": "Agility", "value": ', genome.agility.toString(), '},',
            '{"trait_type": "Intelligence", "value": ', genome.intelligence.toString(), '},',
            '{"trait_type": "Vitality", "value": ', genome.vitality.toString(), '}',
            // Add more attributes based on genome and state
            ']}'
        ));
    }


    // --- Evolution & Interaction Functions ---

    /**
     * @dev Crossbreeds two parent NFTs to potentially mint a new child NFT.
     * Requires owner of both parents to call. Consumes Catalyst.
     * Child genome is a mix of parents with potential mutation.
     * @param parent1Id The ID of the first parent token.
     * @param parent2Id The ID of the second parent token.
     * @return The ID of the newly minted child token (0 if mint fails or not applicable).
     */
    function crossbreed(uint256 parent1Id, uint256 parent2Id) public returns (uint256) {
        require(_exists(parent1Id), "EvolutionaryNFT: parent1 does not exist");
        require(_exists(parent2Id), "EvolutionaryNFT: parent2 does not exist");
        require(ownerOf(parent1Id) == msg.sender, "EvolutionaryNFT: caller is not owner of parent1");
        require(ownerOf(parent2Id) == msg.sender, "EvolutionaryNFT: caller is not owner of parent2");
        require(parent1Id != parent2Id, "EvolutionaryNFT: cannot crossbreed a token with itself");

        _spendCatalyst(msg.sender, crossbreedCost);

        Genome memory genome1 = _tokenGenomes[parent1Id];
        Genome memory genome2 = _tokenGenomes[parent2Id];

        // Deterministic 'randomness' based on block data and token IDs
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, parent1Id, parent2Id, msg.sender, _tokenIdCounter.current())));

        // Simple averaging/mixing of genomes + chance of mutation
        Genome memory childGenome;
        childGenome.strength = uint8((uint256(genome1.strength) + uint256(genome2.strength)) / 2 + (seed % 10) - 5); // Add minor variance
        childGenome.agility = uint8((uint256(genome1.agility) + uint256(genome2.agility)) / 2 + ((seed / 10) % 10) - 5);
        childGenome.intelligence = uint8((uint256(genome1.intelligence) + uint256(genome2.intelligence)) / 2 + ((seed / 100) % 10) - 5);
        childGenome.vitality = uint8((uint256(genome1.vitality) + uint256(genome2.vitality)) / 2 + ((seed / 1000) % 10) - 5);

        // Apply bounds
        childGenome.strength = childGenome.strength > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (childGenome.strength < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : childGenome.strength);
        childGenome.agility = childGenome.agility > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (childGenome.agility < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : childGenome.agility);
        childGenome.intelligence = childGenome.intelligence > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (childGenome.intelligence < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : childGenome.intelligence);
        childGenome.vitality = childGenome.vitality > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (childGenome.vitality < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : childGenome.vitality);


        // Optional: Add a chance for a larger mutation
        if ((seed % 100) < 10) { // 10% chance of significant mutation
             childGenome.strength = uint8(MIN_GENOME_VALUE + (seed % (MAX_GENOME_VALUE - MIN_GENOME_VALUE + 1)));
             childGenome.agility = uint8(MIN_GENOME_VALUE + ((seed / 10) % (MAX_GENOME_VALUE - MIN_GENOME_VALUE + 1)));
             childGenome.intelligence = uint8(MIN_GENOME_VALUE + ((seed / 100) % (MAX_GENOME_VALUE - MIN_GENOME_VALUE + 1)));
             childGenome.vitality = uint8(MIN_GENOME_VALUE + ((seed / 1000) % (MAX_GENOME_VALUE - MIN_GENOME_VALUE + 1)));
        }


        // Generation is max(parent1.gen, parent2.gen) + 1
        uint256 childGeneration = (_tokenGeneration[parent1Id] > _tokenGeneration[parent2Id] ? _tokenGeneration[parent1Id] : _tokenGeneration[parent2Id]) + 1;

        _tokenIdCounter.increment();
        uint256 childId = _tokenIdCounter.current();

        _mint(msg.sender, childId, childGenome, 0, childGeneration); // Child starts with 0 XP
        emit Crossbred(parent1Id, parent2Id, childId, msg.sender);

        // Optional: Add a cooldown to parents or reduce their vitality
        // For simplicity, skipping this for now.

        return childId;
    }

    /**
     * @dev Uses accumulated XP and Catalyst to increase an NFT's generation.
     * Requires owner to call.
     * @param tokenId The ID of the token to level up.
     */
    function levelUp(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "EvolutionaryNFT: caller is not owner of token");
        require(_tokenXP[tokenId] >= XP_PER_GENERATION, "EvolutionaryNFT: not enough XP to level up");
        _spendCatalyst(msg.sender, levelUpCost);

        _tokenXP[tokenId] -= XP_PER_GENERATION;
        _tokenGeneration[tokenId]++;

        // Apply a small, generation-based boost to base stats
        // Note: Direct changes to genome like this on level up might conflict with mutation later.
        // A better approach might be to add a 'generation_bonus' layer to the effective stats.
        // For simplicity here, let's just slightly adjust the base genome.
        _tokenGenomes[tokenId].strength = uint8(uint256(_tokenGenomes[tokenId].strength) + 1 > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : uint256(_tokenGenomes[tokenId].strength) + 1);
        _tokenGenomes[tokenId].agility = uint8(uint256(_tokenGenomes[tokenId].agility) + 1 > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : uint256(_tokenGenomes[tokenId].agility) + 1);
        _tokenGenomes[tokenId].intelligence = uint8(uint256(_tokenGenomes[tokenId].intelligence) + 1 > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : uint256(_tokenGenomes[tokenId].intelligence) + 1);
        _tokenGenomes[tokenId].vitality = uint8(uint256(_tokenGenomes[tokenId].vitality) + 1 > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : uint256(_tokenGenomes[tokenId].vitality) + 1);


        emit LeveledUp(tokenId, _tokenGeneration[tokenId], _tokenXP[tokenId]);
    }

    /**
     * @dev Spends Catalyst and XP to randomly mutate an NFT's genome.
     * Requires owner to call.
     * @param tokenId The ID of the token to mutate.
     */
    function mutate(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "EvolutionaryNFT: caller is not owner of token");
        require(_tokenXP[tokenId] >= XP_PER_MUTATION, "EvolutionaryNFT: not enough XP for mutation");
        _spendCatalyst(msg.sender, mutateCost);

        _tokenXP[tokenId] -= XP_PER_MUTATION;

        // Deterministic 'randomness' for mutation
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, msg.sender, _tokenXP[tokenId], _tokenGeneration[tokenId])));

        // Randomly pick a trait to mutate and apply a random change
        uint8 traitIndex = uint8(seed % 4); // 0=Str, 1=Agi, 2=Int, 3=Vit
        int8 change = int8(uint8((seed / 4) % 21)) - 10; // Random change between -10 and +10

        Genome memory currentGenome = _tokenGenomes[tokenId];
        uint256 newValue;

        if (traitIndex == 0) {
            newValue = uint256(currentGenome.strength) + int256(change);
            currentGenome.strength = uint8(newValue > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (newValue < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : newValue));
        } else if (traitIndex == 1) {
            newValue = uint256(currentGenome.agility) + int256(change);
            currentGenome.agility = uint8(newValue > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (newValue < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : newValue));
        } else if (traitIndex == 2) {
            newValue = uint256(currentGenome.intelligence) + int256(change);
            currentGenome.intelligence = uint8(newValue > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (newValue < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : newValue));
        } else { // traitIndex == 3
            newValue = uint256(currentGenome.vitality) + int256(change);
            currentGenome.vitality = uint8(newValue > MAX_GENOME_VALUE ? MAX_GENOME_VALUE : (newValue < MIN_GENOME_VALUE ? MIN_GENOME_VALUE : newValue));
        }

        _tokenGenomes[tokenId] = currentGenome;
        emit Mutated(tokenId, currentGenome);
    }

    /**
     * @dev Initiates a challenge for an NFT.
     * Requires owner to call and spends Catalyst.
     * @param tokenId The ID of the token to put in a challenge.
     * @param challengeType The type of challenge (1, 2, or 3).
     */
    function initiateChallenge(uint256 tokenId, uint8 challengeType) public {
        require(ownerOf(tokenId) == msg.sender, "EvolutionaryNFT: caller is not owner of token");
        require(!_tokenChallengeState[tokenId].active, "EvolutionaryNFT: token is already in a challenge");
        require(challengeDuration[challengeType] > 0, "EvolutionaryNFT: invalid challenge type");

        _spendCatalyst(msg.sender, challengeInitiationCost);

        _tokenChallengeState[tokenId] = Challenge({
            challengeType: challengeType,
            timestampInitiated: uint64(block.timestamp),
            active: true,
            completed: false,
            xpReward: 0, // Will be set upon completion
            catalystReward: 0, // Will be set upon completion
            outcomeData: "" // Will be set upon completion
        });

        // Transfer the token to the contract address or a escrow address while in challenge?
        // For simplicity, let's keep ownership with the user but mark it as 'active'
        // require(_isApprovedOrOwner(address(this), tokenId), "EvolutionaryNFT: contract not approved to manage token for challenge");
        // _transfer(msg.sender, address(this), tokenId); // Transfer to contract (requires approval)
        // Or simply track state without transfer:
        // No transfer needed if state is tracked via mapping and functions check the 'active' flag.

        emit ChallengeInitiated(tokenId, challengeType, uint64(block.timestamp));
    }

    /**
     * @dev Completes an active challenge for an NFT if enough time has passed.
     * Anyone can call this once the duration is met.
     * Determines outcome and rewards XP/Catalyst.
     * @param tokenId The ID of the token.
     */
    function completeChallenge(uint256 tokenId) public {
        Challenge storage challenge = _tokenChallengeState[tokenId];
        require(challenge.active, "EvolutionaryNFT: token is not in an active challenge");
        require(!challenge.completed, "EvolutionaryNFT: challenge already completed");
        require(block.timestamp >= challenge.timestampInitiated + challengeDuration[challenge.challengeType], "EvolutionaryNFT: challenge duration not yet met");

        // --- Simulate Challenge Outcome ---
        // This is a simplified, deterministic outcome based on token stats and block data.
        // For true decentralization and unpredictable outcomes, integrate with Chainlink VRF
        // or another oracle solution.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, challenge.timestampInitiated, challenge.challengeType)));
        Genome memory genome = _tokenGenomes[tokenId];

        uint256 successFactor = (uint256(genome.strength) + uint256(genome.agility) + uint256(genome.intelligence) + uint256(genome.vitality)) * _tokenGeneration[tokenId];
        uint256 challengeDifficulty = (uint256(challenge.challengeType) + 1) * 100 * (1 + (seed % 5)); // Difficulty varies

        bool success = successFactor > challengeDifficulty;

        uint256 xpEarned = 0;
        uint256 catalystEarned = 0;
        bytes memory outcomeData;

        if (success) {
            xpEarned = 50 + (seed % 50); // Base + random bonus
            catalystEarned = 30 + ((seed / 10) % 30);
            outcomeData = "Success";
        } else {
            xpEarned = 10 + (seed % 10); // Small participation XP
            catalystEarned = 5; // Small participation Catalyst
            outcomeData = "Failure";
            // Could add penalty for failure, e.g., lose vitality or small XP
        }
        // --- End Simulate Challenge Outcome ---

        // Update token state
        _tokenXP[tokenId] += xpEarned;
        _earnCatalyst(ownerOf(tokenId), catalystEarned); // Earn catalyst for the owner

        // Update challenge state
        challenge.active = false;
        challenge.completed = true;
        challenge.xpReward = xpEarned;
        challenge.catalystReward = catalystEarned;
        challenge.outcomeData = outcomeData;

        // If token was transferred to contract, transfer it back
        // if(ownerOf(tokenId) == address(this)) {
        //     _transfer(address(this), _originalOwnerWhenChallenged[tokenId], tokenId); // Need to store original owner
        // }

        emit ChallengeCompleted(tokenId, xpEarned, catalystEarned, outcomeData);
    }

    /**
     * @dev Allows the owner to withdraw a token from an active challenge before completion.
     * May involve a penalty (e.g., lose Catalyst or XP).
     * @param tokenId The ID of the token.
     */
    function withdrawFromChallenge(uint256 tokenId) public {
        Challenge storage challenge = _tokenChallengeState[tokenId];
        require(ownerOf(tokenId) == msg.sender, "EvolutionaryNFT: caller is not owner of token");
        require(challenge.active && !challenge.completed, "EvolutionaryNFT: token is not in an active, incomplete challenge");

        // Optional Penalty: e.g., burn some catalyst or reduce XP
        // uint256 penalty = challengeInitiationCost / 2;
        // if(_userCatalystBalance[msg.sender] >= penalty) {
        //     _spendCatalyst(msg.sender, penalty);
        // } else {
        //     _userCatalystBalance[msg.sender] = 0;
        // }

        // Reset challenge state
        delete _tokenChallengeState[tokenId];

        // If token was transferred to contract, transfer it back
        // if(ownerOf(tokenId) == address(this)) {
        //     _transfer(address(this), msg.sender, tokenId);
        // }

        emit ChallengeWithdrawn(tokenId);
    }

    /**
     * @dev Gets the current challenge state of a token.
     * @param tokenId The ID of the token.
     * @return The Challenge struct.
     */
    function getChallengeState(uint256 tokenId) public view returns (Challenge memory) {
         require(_exists(tokenId), "EvolutionaryNFT: query for nonexistent token");
         return _tokenChallengeState[tokenId];
    }


    /**
     * @dev Initiates a battle simulation between two NFTs.
     * Requires owner of both tokens (or approval). Consumes Catalyst.
     * Determines a winner based on stats and rewards XP/Catalyst.
     * Simplified battle logic.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function battle(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "EvolutionaryNFT: token1 does not exist");
        require(_exists(tokenId2), "EvolutionaryNFT: token2 does not exist");
        require(ownerOf(tokenId1) == msg.sender || isApprovedForAll(ownerOf(tokenId1), msg.sender), "EvolutionaryNFT: caller not authorized for token1");
        require(ownerOf(tokenId2) == msg.sender || isApprovedForAll(ownerOf(tokenId2), msg.sender), "EvolutionaryNFT: caller not authorized for token2");
        require(tokenId1 != tokenId2, "EvolutionaryNFT: cannot battle a token with itself");
        // Optionally require both tokens to be owned by the same user, or check approvals for both if different owners

        // Ensure neither token is in an active challenge
        require(!_tokenChallengeState[tokenId1].active, "EvolutionaryNFT: token1 is in a challenge");
        require(!_tokenChallengeState[tokenId2].active, "EvolutionaryNFT: token2 is in a challenge");


        _spendCatalyst(msg.sender, battleCost);

        Genome memory genome1 = _tokenGenomes[tokenId1];
        Genome memory genome2 = _tokenGenomes[tokenId2];

        // Simplified battle logic: higher total stats wins, with a random factor
        uint256 stats1 = uint256(genome1.strength) + uint256(genome1.agility) + uint256(genome1.intelligence) + uint256(genome1.vitality);
        uint256 stats2 = uint256(genome2.strength) + uint256(genome2.agility) + uint256(genome2.intelligence) + uint256(genome2.vitality);

         // Deterministic 'randomness' for battle outcome
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId1, tokenId2, msg.sender)));

        // Add random variance to stats
        uint256 score1 = stats1 + (seed % 50);
        uint256 score2 = stats2 + ((seed / 50) % 50);

        uint256 winnerId;
        uint256 loserId;

        if (score1 > score2) {
            winnerId = tokenId1;
            loserId = tokenId2;
        } else if (score2 > score1) {
            winnerId = tokenId2;
            loserId = tokenId1;
        } else {
             // Tie - winner decided by smaller token ID (arbitrary)
             if (tokenId1 < tokenId2) {
                 winnerId = tokenId1;
                 loserId = tokenId2;
             } else {
                 winnerId = tokenId2;
                 loserId = tokenId1;
             }
        }

        // Rewards for winner, small consolation for loser
        uint256 xpEarnedWinner = 40 + (seed % 40);
        uint256 catalystEarnedWinner = 25 + ((seed / 40) % 25);
        uint256 xpEarnedLoser = 10;
        uint256 catalystEarnedLoser = 5;

        _tokenXP[winnerId] += xpEarnedWinner;
        _tokenXP[loserId] += xpEarnedLoser;

        // Owner of the winner token earns Catalyst
        _earnCatalyst(ownerOf(winnerId), catalystEarnedWinner);
        // Owner of the loser token earns Catalyst
        _earnCatalyst(ownerOf(loserId), catalystEarnedLoser);


        // Optional: Apply penalty to loser (e.g., vitality reduction, temporary cooldown)
        // For simplicity, skipping penalty here.

        emit BattleConcluded(tokenId1, tokenId2, winnerId, xpEarnedWinner, catalystEarnedWinner);
    }


    // ERC721 Required metadata getters (if implementing ERC721Metadata)
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}
```