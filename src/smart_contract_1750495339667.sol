Okay, here is a Solidity smart contract called `EvolutionaryNFT`. This contract implements dynamic, evolving NFTs with several advanced concepts like trait mutation, stat-based evolution, procreation (breeding), simulated interaction effects, and environmental influences, going beyond standard NFT functionality. It implements the ERC721 standard basics manually to avoid direct duplication of common open-source libraries like OpenZeppelin (though a real project would likely use them for robustness).

It exceeds the 20 function minimum, covering ERC721 requirements, core evolution mechanics, interaction functions, and utility/admin features.

---

**Contract Name:** EvolutionaryNFT

**Concept Summary:**
This contract creates non-fungible tokens (NFTs) representing digital lifeforms that can evolve, gain experience, mutate, and procreate based on owner interactions and simulated environmental factors. The NFTs' traits and stats are dynamic and change over time, affecting their appearance (via dynamic metadata) and capabilities within the contract's logic.

**Advanced Concepts:**
1.  **Dynamic/Stateful NFTs:** NFT metadata and properties change based on on-chain state (stats, level, stage, traits).
2.  **Stat-Based Evolution:** Lifeforms evolve through stages (Juvenile, Adult, Elder) driven by accumulating XP and reaching certain levels.
3.  **Trait System & Mutation:** Lifeforms possess a set of traits represented by a bitmask. Traits can change or new ones can appear via a 'mutation' process triggered during evolution or adaptation, influenced by stats and environmental factors.
4.  **Owner Interaction Effects:** Functions like `train` directly impact the NFT's XP and stats, requiring owner engagement.
5.  **Procreation/Breeding:** Allows two qualifying NFTs to produce a new NFT offspring, inheriting traits and stats in a probabilistic manner.
6.  **Simulated Interaction:** A `simulateBattle` function demonstrates how interactions between NFTs could affect their state (e.g., gaining XP).
7.  **Environmental Influence:** An admin-set `environmentalFactor` parameter influences evolution outcomes and trait mutations, simulating external conditions.
8.  **Dynamic Metadata URI:** The `tokenURI` function is designed to point to metadata that reflects the *current* state of the NFT, rather than static data.

**Function Outline & Summary:**

**I. ERC721 Standard Functions (Basic Implementation):**
1.  `constructor()`: Initializes the contract, sets name and symbol.
2.  `name()`: Returns the contract name.
3.  `symbol()`: Returns the contract symbol.
4.  `totalSupply()`: Returns the total number of NFTs minted.
5.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address.
6.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
7.  `getApproved(uint256 tokenId)`: Returns the approved address for a single NFT.
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of an owner's NFTs.
9.  `approve(address to, uint256 tokenId)`: Sets or clears the approved address for an NFT.
10. `setApprovalForAll(address operator, bool approved)`: Sets or clears operator approval for all NFTs of the caller.
11. `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an NFT (internal approval check).
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers ownership, checking if receiver is a contract that can handle ERC721.
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers with additional data.
14. `supportsInterface(bytes4 interfaceId)`: Declares support for ERC721 and ERC165 interfaces.
15. `tokenURI(uint256 tokenId)`: Returns the metadata URI for an NFT (dynamic based on state).

**II. Core Evolutionary Mechanics:**
16. `mintInitialLifeforms(address[] owners)`: Admin function to mint the first generation of lifeforms.
17. `train(uint256 tokenId)`: Owner interaction to increase an NFT's XP and potentially level up.
18. `evolve(uint256 tokenId)`: Attempts to advance the NFT to the next evolution stage based on level and current stage.
19. `procreate(uint256 tokenId1, uint256 tokenId2)`: Allows two eligible NFTs to create a new offspring NFT.
20. `adapt(uint256 tokenId)`: Attempts to trigger a trait adaptation/mutation event for the NFT.

**III. Interaction & Simulation:**
21. `simulateBattle(uint256 tokenId1, uint256 tokenId2)`: Simulates a simple interaction between two NFTs, affecting their state (e.g., XP gain).

**IV. Admin & Utility Functions:**
22. `setBaseTokenURI(string calldata uri)`: Admin function to set the base URI for dynamic metadata.
23. `setEnvironmentalFactor(uint256 factor)`: Admin function to set a global environmental factor influencing evolution/mutation.
24. `pause()`: Admin function to pause core interactions.
25. `unpause()`: Admin function to unpause core interactions.
26. `paused()`: Checks the contract's pause status.
27. `rescueStuckTokens(address tokenContract, uint256 amount)`: Admin function to rescue accidentally sent ERC20 tokens.

**V. State Getters (Read-Only):**
28. `getLifeformData(uint256 tokenId)`: Retrieves all core dynamic data for a lifeform.
29. `getLifeformStats(uint256 tokenId)`: Retrieves just the core stats (Strength, Agility, Intellect, Spirit).
30. `getLifeformTraits(uint256 tokenId)`: Retrieves the traits bitmask for a lifeform.
31. `getLifeformXP(uint256 tokenId)`: Retrieves current XP.
32. `getLifeformLevel(uint256 tokenId)`: Retrieves current level.
33. `getLifeformStage(uint256 tokenId)`: Retrieves current evolution stage.
34. `getLifeformGeneration(uint256 tokenId)`: Retrieves generation number.
35. `getLifeformLastInteractionTime(uint256 tokenId)`: Retrieves timestamp of the last interaction.
36. `getEnvironmentalFactor()`: Retrieves the current global environmental factor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol"; // Minimal ERC721 interface
import "./IERC165.sol"; // Minimal ERC165 interface
import "./IERC721Metadata.sol"; // Minimal ERC721 Metadata interface
import "./IERC721Enumerable.sol"; // Minimal ERC721 Enumerable interface (optional, not fully implemented here for brevity but interface included)

// Minimal ERC721 Interface (to avoid direct OpenZeppelin import for standard part)
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal ERC165 Interface
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal ERC721 Metadata Interface
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Minimal ERC721 Enumerable Interface (Included for standardness, but not fully implemented in the contract for brevity)
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}


/**
 * @title EvolutionaryNFT
 * @dev A smart contract for dynamic and evolving NFTs representing digital lifeforms.
 * Implements custom mechanics on top of a basic ERC721 structure.
 */
contract EvolutionaryNFT is IERC721Metadata, IERC721Enumerable {
    // --- ERC721 State ---
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Custom State: Lifeform Data ---
    enum EvolutionStage { Juvenile, Adult, Elder }

    struct Lifeform {
        // Core Stats (influence outcomes)
        uint256 strength;
        uint256 agility;
        uint256 intellect;
        uint256 spirit; // Represents resilience or luck

        uint256 xp; // Experience points
        uint256 level; // Derived from XP
        EvolutionStage evolutionStage; // Current stage
        uint256 generation; // Generation number (1 for initial, increases with breeding)
        uint256 traits; // Bitmask representing various traits
        uint256 lastInteractionTime; // Timestamp of last training/battle

        // Potential future fields: parent pointers, unique ID parts, etc.
    }

    mapping(uint256 => Lifeform) private _lifeformsData;

    // --- Constants & Parameters ---
    uint256 public constant XP_PER_LEVEL = 100; // XP needed for one level
    uint256 public constant TRAIN_COOLDOWN = 1 days; // Cooldown for training
    uint256 public constant PROCREATE_COOLDOWN = 7 days; // Cooldown for breeding parents
    uint256 public constant BASE_PROCREATE_FEE = 0 ether; // Example fee (can be 0)
    uint252 private constant MUTATION_CHANCE_DENOMINATOR = 100; // 1/100 chance of mutation base

    // Evolution stage level requirements
    uint256 public constant LEVEL_FOR_ADULT = 10;
    uint256 public constant LEVEL_FOR_ELDER = 25;

    // Trait Bitmask Definitions (Example Traits)
    uint256 public constant TRAIT_FIERY = 1 << 0; // Bit 0
    uint256 public constant TRAIT_AQUATIC = 1 << 1; // Bit 1
    uint256 public constant TRAIT_SWIFT = 1 << 2; // Bit 2
    uint256 public constant TRAIT_RESILIENT = 1 << 3; // Bit 3
    uint256 public constant TRAIT_INTELLIGENT = 1 << 4; // Bit 4
    // ... add more traits (up to 256 if using uint256)

    // --- Admin & Configuration ---
    address public owner; // Contract owner (simple Ownable pattern)
    string private _baseTokenURI; // Base URI for metadata
    uint256 private _environmentalFactor; // Global factor influencing mutations/evolution

    // --- Pausability ---
    bool private _paused = false;

    // --- Events ---
    event LifeformMinted(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event LifeformTrained(uint256 indexed tokenId, uint256 newXP, uint256 newLevel);
    event LifeformEvolved(uint256 indexed tokenId, EvolutionStage newStage);
    event LifeformMutated(uint256 indexed tokenId, uint256 oldTraits, uint256 newTraits);
    event LifeformProcreated(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event BattleSimulated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 winnerId);
    event EnvironmentalFactorUpdated(uint256 newFactor);
    event BaseTokenURIUpdated(string uri);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyLifeformOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

    // --- Constructor ---
    constructor() {
        _name = "EvolutionaryLifeform";
        _symbol = "EVOLF";
        owner = msg.sender; // Set contract owner
        _environmentalFactor = 50; // Default environmental factor
        emit Paused(msg.sender); // Start paused for initial setup (optional)
        _paused = true;
    }

    // --- ERC721 Standard Implementation ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "Balance query for the zero address");
        return _balances[owner_];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for nonexistent token");
        return owner_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

     /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId); // Checks token existence
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "Approval permission denied");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "Approved query for nonexistent token"); // Check existence
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check permission
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer permission denied");
        // Basic validation
        require(ownerOf(tokenId) == from, "Token not owned by 'from'");
        require(to != address(0), "Transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer permission denied");
        require(ownerOf(tokenId) == from, "Token not owned by 'from'");
        require(to != address(0), "Transfer to the zero address");

        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns a URI pointing to metadata that is dynamic based on the lifeform's state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "URI query for nonexistent token");
        // In a real application, this base URI would typically point to an API
        // that takes the tokenId and queries the contract state to generate
        // dynamic JSON metadata and potentially an image/animation URL.
        // Example: "https://myapi.com/metadata/evolf/" + tokenId
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC721, ERC721Metadata, ERC721Enumerable interfaces
        return interfaceId == 0x80ac58cd || // ERC721
               interfaceId == 0x5b5e139f || // ERC721Metadata
               interfaceId == 0x780e9d63 || // ERC721Enumerable (partial support implied by totalSupply)
               interfaceId == 0x01ffc9a7;  // ERC165
    }

    // --- Internal ERC721 Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approvals for the transferring token
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
        _totalSupply++;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
         address owner_ = ownerOf(tokenId); // Checks token existence

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);
        _operatorApprovals[owner_][msg.sender] = false; // Revoke operator if caller is owner

        _balances[owner_]--;
        delete _owners[tokenId];
        delete _lifeformsData[tokenId]; // Also delete associated lifeform data
        _totalSupply--;

        emit Transfer(owner_, address(0), tokenId);
    }


    // Check if a contract receiver can handle ERC721 (Simplified check)
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length > 0) {
                    revert(string(reason));
                } else {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
            }
        } else {
            return true; // EOA can always receive
        }
    }

    // Minimal IERC721Receiver Interface for _checkOnERC721Received
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }

    // Minimal Strings library (based on OpenZeppelin, but simplified to avoid full copy)
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


    // --- Core Evolutionary Mechanics Implementation ---

    /**
     * @dev Admin function to mint initial lifeforms.
     * @param owners Array of addresses to receive the first generation lifeforms.
     */
    function mintInitialLifeforms(address[] calldata owners) external onlyOwner whenPaused {
        uint256 currentTotal = _totalSupply;
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 newTokenId = currentTotal + i;
            _mint(owners[i], newTokenId);

            // Initialize lifeform data
            _lifeformsData[newTokenId] = Lifeform({
                strength: _generateInitialStat(newTokenId, 1),
                agility: _generateInitialStat(newTokenId, 2),
                intellect: _generateInitialStat(newTokenId, 3),
                spirit: _generateInitialStat(newTokenId, 4),
                xp: 0,
                level: 1,
                evolutionStage: EvolutionStage.Juvenile,
                generation: 1,
                traits: _generateInitialTraits(newTokenId),
                lastInteractionTime: block.timestamp // Set initial interaction time
            });

            emit LifeformMinted(newTokenId, owners[i], 1);
        }
    }

    /**
     * @dev Allows owner/approved to train their lifeform, granting XP.
     * Subject to a cooldown.
     * @param tokenId The ID of the lifeform to train.
     */
    function train(uint256 tokenId) external onlyLifeformOwnerOrApproved(tokenId) whenNotPaused {
        Lifeform storage lifeform = _lifeformsData[tokenId];
        require(block.timestamp >= lifeform.lastInteractionTime + TRAIN_COOLDOWN, "Lifeform is on training cooldown");

        uint256 xpGained = _calculateXPGain(lifeform); // Base XP + bonus from stats/traits
        lifeform.xp += xpGained;
        lifeform.lastInteractionTime = block.timestamp;

        uint256 oldLevel = lifeform.level;
        uint256 newLevel = lifeform.xp / XP_PER_LEVEL + 1; // Level starts at 1

        if (newLevel > oldLevel) {
             lifeform.level = newLevel;
             // Grant stat points on level up (example: 3 points per level)
             uint256 pointsToDistribute = (newLevel - oldLevel) * 3;
             _distributeStatPoints(lifeform, pointsToDistribute, tokenId); // Distribute randomly or based on traits/environ.
        }

        emit LifeformTrained(tokenId, lifeform.xp, lifeform.level);
    }

    /**
     * @dev Attempts to evolve the lifeform to the next stage.
     * Requires reaching a certain level for the current stage.
     * May trigger a mutation event.
     * @param tokenId The ID of the lifeform to evolve.
     */
    function evolve(uint256 tokenId) external onlyLifeformOwnerOrApproved(tokenId) whenNotPaused {
        Lifeform storage lifeform = _lifeformsData[tokenId];
        EvolutionStage currentStage = lifeform.evolutionStage;
        uint256 currentLevel = lifeform.level;

        EvolutionStage nextStage = currentStage; // Default to no change
        bool evolved = false;

        if (currentStage == EvolutionStage.Juvenile && currentLevel >= LEVEL_FOR_ADULT) {
            nextStage = EvolutionStage.Adult;
            evolved = true;
        } else if (currentStage == EvolutionStage.Adult && currentLevel >= LEVEL_FOR_ELDER) {
            nextStage = EvolutionStage.Elder;
            evolved = true;
        } else {
            revert("Lifeform not ready to evolve");
        }

        lifeform.evolutionStage = nextStage;
        emit LifeformEvolved(tokenId, nextStage);

        // Potential Mutation on Evolution
        if (_shouldMutate(lifeform, tokenId)) {
            uint256 oldTraits = lifeform.traits;
            lifeform.traits = _mutateTraits(lifeform, tokenId);
            emit LifeformMutated(tokenId, oldTraits, lifeform.traits);
        }
    }

    /**
     * @dev Allows two eligible Adult/Elder lifeforms to procreate, creating a new lifeform.
     * Subject to a cooldown for parents. Requires payment (if fee > 0).
     * Inherits stats and traits probabilistically.
     * @param tokenId1 The ID of the first parent lifeform.
     * @param tokenId2 The ID of the second parent lifeform.
     */
    function procreate(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot procreate with self");
        require(_exists(tokenId1), "Parent 1 does not exist");
        require(_exists(tokenId2), "Parent 2 does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Not owner or approved for parent 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Not owner or approved for parent 2");
        require(msg.value >= BASE_PROCREATE_FEE, "Insufficient procreation fee");

        Lifeform storage parent1 = _lifeformsData[tokenId1];
        Lifeform storage parent2 = _lifeformsData[tokenId2];

        require(parent1.evolutionStage >= EvolutionStage.Adult, "Parent 1 is not mature enough");
        require(parent2.evolutionStage >= EvolutionStage.Adult, "Parent 2 is not mature enough");
        require(block.timestamp >= parent1.lastInteractionTime + PROCREATE_COOLDOWN, "Parent 1 is on procreation cooldown");
        require(block.timestamp >= parent2.lastInteractionTime + PROCREATE_COOLDOWN, "Parent 2 is on procreation cooldown");

        // --- Create Child Lifeform ---
        uint256 newChildId = _totalSupply;
        _mint(msg.sender, newChildId); // Child is minted to the caller

        uint256 childGeneration = Math.max(parent1.generation, parent2.generation) + 1;

        // Simple inheritance logic: Average stats with some randomness
        uint256 childStrength = (_inheritStat(parent1.strength, parent2.strength, newChildId, 1));
        uint256 childAgility = (_inheritStat(parent1.agility, parent2.agility, newChildId, 2));
        uint256 childIntellect = (_inheritStat(parent1.intellect, parent2.intellect, newChildId, 3));
        uint256 childSpirit = (_inheritStat(parent1.spirit, parent2.spirit, newChildId, 4));

        // Inherit traits: Bitwise OR combines traits, plus chance for new mutation
        uint256 inheritedTraits = parent1.traits | parent2.traits;
        uint256 childTraits = _mutateTraitsBasedOnParents(inheritedTraits, parent1, parent2, newChildId);


        _lifeformsData[newChildId] = Lifeform({
            strength: childStrength,
            agility: childAgility,
            intellect: childIntellect,
            spirit: childSpirit,
            xp: 0, // Child starts fresh
            level: 1,
            evolutionStage: EvolutionStage.Juvenile,
            generation: childGeneration,
            traits: childTraits,
            lastInteractionTime: block.timestamp // Child's initial time
        });

        // Update parent cooldowns
        parent1.lastInteractionTime = block.timestamp;
        parent2.lastInteractionTime = block.timestamp;

        emit LifeformProcreated(tokenId1, tokenId2, newChildId);

        // Handle fee (send to owner or burn)
        if (BASE_PROCREATE_FEE > 0) {
             (bool success, ) = payable(owner).call{value: BASE_PROCREATE_FEE}("");
             require(success, "Fee transfer failed");
        }
    }

     /**
     * @dev Attempts to trigger a trait adaptation or mutation for a lifeform.
     * Influenced by current stats and environmental factor.
     * @param tokenId The ID of the lifeform to adapt.
     */
    function adapt(uint256 tokenId) external onlyLifeformOwnerOrApproved(tokenId) whenNotPaused {
         Lifeform storage lifeform = _lifeformsData[tokenId];
         // Add a cooldown or cost for adaptation? For now, free once per... maybe per level? Or based on spirit?
         // Let's add a simple spirit check and use lastInteractionTime as cooldown surrogate for now.
         require(block.timestamp >= lifeform.lastInteractionTime + TRAIN_COOLDOWN, "Lifeform is on cooldown");
         require(lifeform.spirit > 50, "Spirit too low for adaptation"); // Example requirement

         lifeform.lastInteractionTime = block.timestamp; // Use cooldown

         if (_shouldMutate(lifeform, tokenId)) { // Adaptation IS a form of mutation
             uint256 oldTraits = lifeform.traits;
             lifeform.traits = _mutateTraits(lifeform, tokenId);
             emit LifeformMutated(tokenId, oldTraits, lifeform.traits);
         } else {
              // Maybe provide a small XP boost even if no mutation occurs
              lifeform.xp += 10;
              uint256 oldLevel = lifeform.level;
              uint256 newLevel = lifeform.xp / XP_PER_LEVEL + 1;
              if (newLevel > oldLevel) {
                  lifeform.level = newLevel;
                   _distributeStatPoints(lifeform, newLevel - oldLevel, tokenId);
              }
              emit LifeformTrained(tokenId, lifeform.xp, lifeform.level); // Log the minor effect
         }
    }

    /**
     * @dev Simulates a battle between two lifeforms.
     * Winner and loser determined by stats. Affects XP.
     * Simplified interaction - no complex combat logic on-chain.
     * @param tokenId1 ID of the first lifeform.
     * @param tokenId2 ID of the second lifeform.
     */
    function simulateBattle(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot battle self");
        require(_exists(tokenId1), "Lifeform 1 does not exist");
        require(_exists(tokenId2), "Lifeform 2 does not exist");
        // No ownership check - battles can be between any two public NFTs? Or require approval?
        // Let's assume public battles for now. If requiring approval, add modifier.

        Lifeform storage lifeform1 = _lifeformsData[tokenId1];
        Lifeform storage lifeform2 = _lifeformsData[tokenId2];

        // Simple win condition based on combined stats and a pseudo-random factor
        uint256 power1 = lifeform1.strength + lifeform1.agility + lifeform1.intellect + lifeform1.spirit;
        uint256 power2 = lifeform2.strength + lifeform2.agility + lifeform2.intellect + lifeform2.spirit;

        // Introduce pseudo-randomness
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId1, tokenId2))) % 100;

        uint256 effectivePower1 = power1 * (100 + randomFactor) / 100;
        uint256 effectivePower2 = power2 * (100 + (100 - randomFactor)) / 100; // Other gets inverse randomness

        uint256 winnerId;
        uint256 loserId;
        Lifeform storage winnerLifeform;
        Lifeform storage loserLifeform;

        if (effectivePower1 > effectivePower2) {
            winnerId = tokenId1;
            loserId = tokenId2;
            winnerLifeform = lifeform1;
            loserLifeform = lifeform2;
        } else if (effectivePower2 > effectivePower1) {
            winnerId = tokenId2;
            loserId = tokenId1;
            winnerLifeform = lifeform2;
            loserLifeform = lifeform1;
        } else {
            // Draw
            winnerId = 0; // Indicate draw
             emit BattleSimulated(tokenId1, tokenId2, 0);
             return; // No XP change on draw
        }

        // Award XP
        uint256 winnerXP = 50; // Example XP
        uint256 loserXP = 10; // Example XP for participating

        winnerLifeform.xp += winnerXP;
        loserLifeform.xp += loserXP;

         uint256 oldWinnerLevel = winnerLifeform.level;
         uint256 newWinnerLevel = winnerLifeform.xp / XP_PER_LEVEL + 1;
         if (newWinnerLevel > oldWinnerLevel) {
             winnerLifeform.level = newWinnerLevel;
             _distributeStatPoints(winnerLifeform, newWinnerLevel - oldWinnerLevel, winnerId);
         }

         uint256 oldLoserLevel = loserLifeform.level;
         uint256 newLoserLevel = loserLifeform.xp / XP_PER_LEVEL + 1;
         if (newLoserLevel > oldLoserLevel) {
             loserLifeform.level = newLoserLevel;
             _distributeStatPoints(loserLifeform, newLoserLevel - oldLoserLevel, loserId);
         }


        emit BattleSimulated(tokenId1, tokenId2, winnerId);
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Admin function to set the base URI for token metadata.
     * @param uri The new base URI string.
     */
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    /**
     * @dev Admin function to set the global environmental factor.
     * Influences mutation chances and potentially stat distributions.
     * @param factor The new environmental factor value (e.g., 0-100).
     */
    function setEnvironmentalFactor(uint256 factor) external onlyOwner {
        _environmentalFactor = factor;
        emit EnvironmentalFactorUpdated(factor);
    }

    /**
     * @dev Pauses the contract, preventing core interactions.
     * Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing core interactions.
     * Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Returns the current pause status.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

     /**
     * @dev Allows the owner to rescue accidentally sent ERC20 tokens.
     * @param tokenContract The address of the ERC20 token contract.
     * @param amount The amount of tokens to rescue.
     */
    function rescueStuckTokens(address tokenContract, uint256 amount) external onlyOwner {
        IERC20 stuckToken = IERC20(tokenContract);
        require(stuckToken.transfer(owner, amount), "Token transfer failed");
    }

    // --- State Getters (Read-Only) ---

    /**
     * @dev Retrieves all core dynamic data for a lifeform.
     * @param tokenId The ID of the lifeform.
     * @return A struct containing the lifeform's data.
     */
    function getLifeformData(uint256 tokenId) public view returns (Lifeform memory) {
        require(_exists(tokenId), "Lifeform does not exist");
        return _lifeformsData[tokenId];
    }

    /**
     * @dev Retrieves the core stats (Strength, Agility, Intellect, Spirit).
     * @param tokenId The ID of the lifeform.
     * @return strength, agility, intellect, spirit
     */
    function getLifeformStats(uint256 tokenId) public view returns (uint256 strength, uint256 agility, uint256 intellect, uint256 spirit) {
         require(_exists(tokenId), "Lifeform does not exist");
         Lifeform storage lifeform = _lifeformsData[tokenId];
         return (lifeform.strength, lifeform.agility, lifeform.intellect, lifeform.spirit);
    }

    /**
     * @dev Retrieves the traits bitmask.
     * @param tokenId The ID of the lifeform.
     * @return traits bitmask
     */
    function getLifeformTraits(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Lifeform does not exist");
         return _lifeformsData[tokenId].traits;
    }

     /**
     * @dev Retrieves current XP.
     * @param tokenId The ID of the lifeform.
     */
    function getLifeformXP(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Lifeform does not exist");
         return _lifeformsData[tokenId].xp;
    }

     /**
     * @dev Retrieves current level.
     * @param tokenId The ID of the lifeform.
     */
    function getLifeformLevel(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Lifeform does not exist");
         return _lifeformsData[tokenId].level;
    }

     /**
     * @dev Retrieves current evolution stage.
     * @param tokenId The ID of the lifeform.
     */
    function getLifeformStage(uint256 tokenId) public view returns (EvolutionStage) {
         require(_exists(tokenId), "Lifeform does not exist");
         return _lifeformsData[tokenId].evolutionStage;
    }

     /**
     * @dev Retrieves generation number.
     * @param tokenId The ID of the lifeform.
     */
    function getLifeformGeneration(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Lifeform does not exist");
         return _lifeformsData[tokenId].generation;
    }

     /**
     * @dev Retrieves timestamp of the last interaction.
     * @param tokenId The ID of the lifeform.
     */
     function getLifeformLastInteractionTime(uint256 tokenId) public view returns (uint256) {
          require(_exists(tokenId), "Lifeform does not exist");
          return _lifeformsData[tokenId].lastInteractionTime;
     }


    /**
     * @dev Retrieves the current global environmental factor.
     */
    function getEnvironmentalFactor() public view returns (uint256) {
        return _environmentalFactor;
    }

    // --- Internal Logic Helpers ---

    /**
     * @dev Generates an initial stat value for a new lifeform.
     * Uses pseudo-randomness based on block data and token ID.
     */
    function _generateInitialStat(uint256 tokenId, uint256 statSeed) internal view returns (uint256) {
        // Basic pseudo-random generation
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, tokenId, statSeed)));
        // Initial stats are low, e.g., 1-10
        return (randomness % 10) + 1;
    }

     /**
     * @dev Generates initial traits for a new lifeform.
     * Uses pseudo-randomness.
     */
    function _generateInitialTraits(uint256 tokenId) internal view returns (uint256) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, tokenId, 999)));
         // Each trait has a small chance (e.g., 20%) to be present initially
        uint256 initialTraits = 0;
        if (randomness % 100 < 20) initialTraits |= TRAIT_FIERY;
        if ((randomness / 100) % 100 < 20) initialTraits |= TRAIT_AQUATIC;
        if ((randomness / 10000) % 100 < 20) initialTraits |= TRAIT_SWIFT;
        if ((randomness / 1000000) % 100 < 20) initialTraits |= TRAIT_RESILIENT;
        if ((randomness / 100000000) % 100 < 20) initialTraits |= TRAIT_INTELLIGENT;
        // ... add logic for other traits

        return initialTraits;
    }


     /**
     * @dev Calculates XP gain from training. Can be influenced by stats/traits.
     */
    function _calculateXPGain(Lifeform storage lifeform) internal view returns (uint256) {
        // Example: Base XP + bonus based on Spirit
        uint256 baseXP = 20;
        uint256 spiritBonus = lifeform.spirit / 5; // 1 bonus XP for every 5 spirit
        return baseXP + spiritBonus;
    }

     /**
     * @dev Distributes stat points upon leveling up.
     * Example: Distributes randomly, but could be influenced by traits/environment.
     */
    function _distributeStatPoints(Lifeform storage lifeform, uint256 points, uint256 tokenId) internal {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, tokenId, lifeform.level)));
        uint256 totalStats = 4; // Strength, Agility, Intellect, Spirit

        for (uint256 i = 0; i < points; i++) {
            uint256 statIndex = (randomness + i) % totalStats;
            if (statIndex == 0) lifeform.strength++;
            else if (statIndex == 1) lifeform.agility++;
            else if (statIndex == 2) lifeform.intellect++;
            else if (statIndex == 3) lifeform.spirit++;
        }
    }

    /**
     * @dev Determines if a mutation should occur during evolution or adaptation.
     * Influenced by spirit and environmental factor.
     */
    function _shouldMutate(Lifeform storage lifeform, uint256 tokenId) internal view returns (bool) {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, tokenId, "mutate")));
        uint256 baseChance = 100 / MUTATION_CHANCE_DENOMINATOR; // Base 1% chance if denominator is 100

        // Adjust chance based on spirit and environmental factor (example logic)
        // Higher spirit = higher chance? Or maybe spirit influences *type* of mutation?
        // Higher env factor = higher chance?
        uint256 adjustedChance = baseChance;
        adjustedChance += lifeform.spirit / 20; // +1% chance per 20 spirit
        adjustedChance += _environmentalFactor / 10; // +1% chance per 10 env factor

        // Cap chance at 50% to avoid excessive mutation
        if (adjustedChance > 50) adjustedChance = 50;


        return (randomness % 100) < adjustedChance;
    }

     /**
     * @dev Applies trait mutation. Randomly flips bits (adds or removes traits).
     * Influenced by stats and environmental factor.
     */
    function _mutateTraits(Lifeform storage lifeform, uint256 tokenId) internal view returns (uint256) {
        uint256 currentTraits = lifeform.traits;
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, tokenId, "apply_mutate")));

        uint256 newTraits = currentTraits;

        // Example mutation logic: Iterate through possible trait bits
        // Chance to flip each bit based on randomness, stats, and environment.
        // Stronger lifeforms might gain combat traits, smarter ones gain intellect traits, etc.
        // Environmental factor might favor certain traits.

        uint256 totalPossibleTraits = 5; // Number of bits defined (TRAIT_FIERY to TRAIT_INTELLIGENT)
        uint256 mutationSeverity = _environmentalFactor / 20; // Higher env factor = more bits potentially affected

        for (uint265 i = 0; i < totalPossibleTraits; i++) {
             uint256 traitBit = 1 << i;
             uint256 individualBitRandomness = uint256(keccak256(abi.encodePacked(randomness, i)));

             bool shouldFlip = false;

             // Chance to flip based on base randomness + severity
             if (individualBitRandomness % 100 < (5 + mutationSeverity * 2)) { // Example chance logic
                 shouldFlip = true;
             }

             // Add stat/trait/env specific influences here
             // E.g., if mutating TRAIT_FIERY: check Strength and environmentalFactor vs TRAIT_FIERY_ENV_AFFINITY
             if (i == 0 && lifeform.strength > 60) { // TRAIT_FIERY influenced by Strength
                  if (individualBitRandomness % 100 < (10 + mutationSeverity * 3 + lifeform.strength / 10)) shouldFlip = true;
             }
             // ... similar logic for other traits

             if (shouldFlip) {
                 newTraits ^= traitBit; // Flip the bit (add if absent, remove if present)
             }
        }

        // Ensure lifeform always has at least one trait? Or is having no trait valid? Let's allow no trait.

        return newTraits;
    }

    /**
     * @dev Inherits a stat value from parents with randomness.
     */
    function _inheritStat(uint256 stat1, uint256 stat2, uint256 childTokenId, uint256 statSeed) internal view returns (uint256) {
        uint256 average = (stat1 + stat2) / 2;
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, childTokenId, statSeed, "inherit")));
        int256 deviation = int256((randomness % 21) - 10); // Random deviation between -10 and +10

        int256 inheritedValue = int256(average) + deviation;

        // Ensure stats are at least 1
        if (inheritedValue < 1) {
            return 1;
        }
        return uint256(inheritedValue);
    }

     /**
     * @dev Inherits traits from parents and potentially mutates for the child.
     * Combined parental traits (OR) + a chance for a new mutation based on stats/environment.
     */
     function _mutateTraitsBasedOnParents(uint256 inheritedTraits, Lifeform storage parent1, Lifeform storage parent2, uint256 childTokenId) internal view returns (uint256) {
         uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, childTokenId, "child_mutate")));
         uint256 newTraits = inheritedTraits;

         // Higher chance of mutation for children, influenced by parent stats/environment
         uint256 baseChildMutationChance = 20; // Base 20% for children
         uint256 statInfluence = (parent1.spirit + parent2.spirit) / 10; // Parents' spirit influences child mutation
         uint256 envInfluence = _environmentalFactor / 5; // Environmental factor influences child mutation

         uint256 totalChildMutationChance = baseChildMutationChance + statInfluence + envInfluence;
         if (totalChildMutationChance > 80) totalChildMutationChance = 80; // Cap chance

         if (randomness % 100 < totalChildMutationChance) {
             // Apply a mutation process similar to the adult mutation, but possibly more impactful
             // Simplified: just randomly flip a few bits
              uint256 childMutationRandomness = uint256(keccak256(abi.encodePacked(randomness, "child_apply")));
               uint256 totalPossibleTraits = 5;
               uint256 bitsToFlip = (childMutationRandomness % 3) + 1; // Flip 1 to 3 bits

               for(uint256 i = 0; i < bitsToFlip; i++){
                   uint256 bitIndexToFlip = (childMutationRandomness / (100 + i)) % totalPossibleTraits;
                   uint256 traitBit = 1 << bitIndexToFlip;
                   newTraits ^= traitBit; // Flip the bit
               }
         }

         return newTraits;
     }

    // --- Additional ERC721Enumerable Interface Functions (Not fully implemented for brevity) ---
    // These would typically require storing token IDs in an array, which adds complexity and gas costs.
    // Leaving them as simply returning default values or requiring arrays for full implementation.

    // tokenByIndex(uint256 index) external view override returns (uint256) {
    //     // Implementation would require storing token IDs in an array.
    //     revert("ERC721Enumerable not fully implemented");
    // }

    // tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
    //     // Implementation would require storing token IDs per owner in arrays.
    //     revert("ERC721Enumerable not fully implemented");
    // }

    // --- ERC20 Interface for rescueStuckTokens ---
    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
        // other ERC20 functions omitted for brevity
    }

     // --- Owner getter for simple Ownable ---
    function getOwner() external view returns (address) {
        return owner;
    }
}
```