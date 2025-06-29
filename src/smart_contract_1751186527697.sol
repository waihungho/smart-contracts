Okay, let's design a smart contract that combines several advanced and trendy concepts: Dynamic NFTs, utility tokens, simulated on-chain evolution/adaptation based on external data, and resource management.

We will create a contract for "EvoPals" - creatures represented by NFTs that can evolve and adapt based on user interaction (spending a utility token), simulated environmental changes (via an oracle), and internal mechanics.

**Concept:**

*   **EvoToken (`EVO`):** A basic ERC-20 token used as the primary resource for interacting with EvoPals (feeding, attempting mutations, leveling up).
*   **EvoCreature (`CREATURE`):** An ERC-721 token representing individual creatures. Each creature has dynamic, on-chain metadata like Level, Experience Points (XP), Traits, Last Fed Timestamp, Environmental Adaptation Score, and an overall "Adaptability" score.
*   **Evolution Mechanics:**
    *   **Feeding:** Burn `EVO` to keep an EvoPal "happy" and boost short-term Adaptability.
    *   **Gaining XP:** XP is gained by burning `EVO` through actions like feeding or attempting mutations.
    *   **Leveling Up:** When XP reaches a threshold, burn `EVO` to increase the EvoPal's level. Leveling increases potential stats and unlocks new possibilities.
    *   **Trait Mutation:** Burn `EVO` to attempt changing a specific trait. Success probability depends on the creature's Adaptability, the current Environmental Conditions, and simulated randomness.
    *   **Environmental Adaptation:** Spend `EVO` to help a creature adapt faster to the current environment. Highly adapted creatures get Adaptability bonuses.
*   **Environmental Conditions:** Simulated external data (e.g., temperature, humidity index) updated by a designated oracle address. These conditions influence mutation success, adaptation speed, and creature Adaptability.
*   **Adaptability Score:** A dynamic score calculated based on Level, XP, recency of feeding, current environmental match, and adaptation level. A higher score improves chances in probabilistic actions (like mutation) and might yield bonuses.

**Note:** This contract includes simplified implementations of ERC-20 and ERC-721 interfaces for self-containment and demonstration purposes, rather than importing standard libraries like OpenZeppelin. In a production environment, using audited libraries is highly recommended. The on-chain randomness simulation (`attemptTraitMutation`) is **not secure** and would require Chainlink VRF or a similar oracle solution for production use.

---

**Outline and Function Summary**

**Contract Name:** EvoPals

**Concept:** A system of dynamic NFTs (EvoCreatures) that evolve using a utility token (EvoToken) and adapt to simulated environmental conditions provided by an oracle.

**Interfaces Used (Simplified Implementation within the Contract):**
*   ERC-20 (for EvoToken)
*   ERC-721 (for EvoCreature NFT)
*   Ownable (Basic ownership pattern)
*   Pausable (Basic pausing pattern)

**State Variables:**
*   Token & NFT metadata and balances (`_balances`, `_allowances`, `_owners`, `_tokenApprovals`, etc.)
*   Creature data mapping (`creatureData`)
*   Evolution costs (`feedingCost`, `levelUpCost`, `mutationCost`, `adaptationCost`)
*   Environmental data (`environmentalConditions`, `lastEnvironmentalUpdateTime`)
*   Oracle address (`oracleAddress`)
*   Admin variables (`_owner`, `paused`)
*   Token counters (`_totalSupplyEVO`, `_nextTokenId`)
*   Base URI for creature metadata (`baseCreatureURI`)

**Structs:**
*   `CreatureData`: Holds level, xp, traits, last fed time, adaptation level, etc.
*   `EnvironmentalConditions`: Holds simulated environment data (e.g., temp index, humidity index).

**Events:**
*   Standard ERC-20/ERC-721 events (`Transfer`, `Approval`, `ApprovalForAll`).
*   Custom events (`CreatureMinted`, `CreatureLeveledUp`, `TraitMutated`, `CreatureFed`, `EnvironmentalUpdate`, `CostsUpdated`, `OracleAddressUpdated`, `ContractPaused`, `ContractUnpaused`, `FeesWithdrawn`).

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyOracle`: Restricts access to the designated oracle address.
*   `whenNotPaused`: Prevents execution when the contract is paused.
*   `whenPaused`: Allows execution only when the contract is paused.
*   `creatureExists`: Checks if a given creature ID exists.

**Function Summary (Total Public/External: 36)**

**A. ERC-20 EvoToken Functions (7)**
1.  `transfer(address to, uint256 amount)`: Transfer EVO tokens.
2.  `transferFrom(address from, address to, uint256 amount)`: Transfer EVO tokens using allowance.
3.  `approve(address spender, uint256 amount)`: Set allowance for a spender.
4.  `balanceOf(address account)`: Get EVO balance of an account. (View)
5.  `allowance(address owner, address spender)`: Get allowance granted to a spender. (View)
6.  `totalSupply()`: Get total supply of EVO tokens. (View)
7.  `_mintEVO(address account, uint256 amount)`: Internal helper to mint EVO (can be used by other functions, e.g., admin mint).

**B. ERC-721 EvoCreature Functions (8)**
8.  `balanceOfCreatures(address owner)`: Get number of creatures owned by an address. (View)
9.  `ownerOfCreature(uint256 tokenId)`: Get owner of a specific creature NFT. (View)
10. `transferFromCreature(address from, address to, uint256 tokenId)`: Transfer creature NFT.
11. `approveCreature(address to, uint256 tokenId)`: Approve an address to manage a specific NFT.
12. `setApprovalForAllCreatures(address operator, bool approved)`: Approve/disapprove an operator for all owner's NFTs.
13. `getApprovedCreature(uint256 tokenId)`: Get the approved address for a specific NFT. (View)
14. `isApprovedForAllCreatures(address owner, address operator)`: Check if an operator is approved for all owner's NFTs. (View)
15. `tokenURI(uint256 tokenId)`: Get the metadata URI for a creature NFT. (View)

**C. Creature & Evolution Core Logic (11)**
16. `mintCreature(address owner, uint8 initialTrait1, uint8 initialTrait2, uint8 initialTrait3)`: Mints a new creature NFT for the specified owner with initial traits.
17. `getCreatureTraits(uint256 tokenId)`: Gets the current traits of a creature. (View)
18. `getCreatureStats(uint256 tokenId)`: Gets the level, XP, last fed time, and adaptation level of a creature. (View)
19. `getCreatureAdaptabilityScore(uint256 tokenId)`: Calculates and returns the current adaptability score. (View)
20. `feedCreature(uint256 tokenId)`: Burns `feedingCost` EVO tokens, adds XP, and updates the creature's last fed time. Boosts short-term adaptability.
21. `levelUpCreature(uint256 tokenId)`: Burns `levelUpCost` EVO tokens if XP is sufficient. Increments level and updates stats.
22. `attemptTraitMutation(uint256 tokenId, uint8 traitIndex, uint8 desiredTraitValue, uint256 userEntropy)`: Burns `mutationCost` EVO tokens. Attempts to change a specific trait. Success probability depends on adaptability, environment, and simulated randomness incorporating `userEntropy`.
23. `adaptToEnvironment(uint256 tokenId)`: Burns `adaptationCost` EVO tokens to increase the creature's adaptation level towards the current environment.
24. `updateEnvironmentalConditions(uint8 tempIndex, uint8 humidityIndex, bytes32 externalEntropy)`: Called by the oracle to update the simulated environment. Includes external entropy for simulated randomness. (Only Oracle)
25. `getEnvironmentalConditions()`: Gets the current simulated environmental conditions. (View)
26. `getTraitNames()`: Gets the array of trait names. (View)

**D. Admin & Utility Functions (10)**
27. `setOracleAddress(address _oracleAddress)`: Sets the address authorized to update environmental conditions. (Only Owner)
28. `setFeedingCost(uint256 cost)`: Sets the EVO cost for feeding. (Only Owner)
29. `setLevelUpCost(uint256 cost)`: Sets the EVO cost for leveling up. (Only Owner)
30. `setMutationCost(uint256 cost)`: Sets the EVO cost for attempting trait mutation. (Only Owner)
31. `setAdaptationCost(uint256 cost)`: Sets the EVO cost for adapting to the environment. (Only Owner)
32. `setBaseCreatureURI(string memory baseURI)`: Sets the base URI for creature NFT metadata. (Only Owner)
33. `withdrawFees(address tokenAddress)`: Allows the owner to withdraw accumulated tokens from creature interactions. (Only Owner)
34. `pause()`: Pauses contract operations. (Only Owner)
35. `unpause()`: Unpauses contract operations. (Only Owner)
36. `getTraitName(uint8 traitIndex)`: Get the name of a specific trait index. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract implements a system of dynamic NFTs (EvoCreatures) that evolve
// using a utility token (EvoToken) and adapt to simulated environmental
// conditions provided by an oracle.
// It includes simplified ERC-20 and ERC-721 implementations for demonstration.
// WARNING: The on-chain randomness simulation in attemptTraitMutation is NOT SECURE
// for production use and should be replaced with a provably fair system like Chainlink VRF.
// This contract is for educational and illustrative purposes showcasing advanced concepts.

// --- Outline and Function Summary ---
// Concept: Dynamic NFTs (EvoCreatures) evolving via utility token (EvoToken)
//          and adapting to simulated environmental data.
// Interfaces Used (Simplified Implementation): ERC-20, ERC-721, Ownable, Pausable
// State Variables: Token/NFT data, creature data mapping, evolution costs,
//                  environmental data, oracle address, admin variables.
// Structs: CreatureData, EnvironmentalConditions
// Events: Standard ERC-20/721 events, Custom evolution/admin events.
// Modifiers: onlyOwner, onlyOracle, whenNotPaused, whenPaused, creatureExists.
// Function Summary (Total Public/External: 36)
// A. ERC-20 EvoToken Functions (7): transfer, transferFrom, approve, balanceOf, allowance, totalSupply, _mintEVO (internal helper count included for completeness)
// B. ERC-721 EvoCreature Functions (8): balanceOfCreatures, ownerOfCreature, transferFromCreature, approveCreature, setApprovalForAllCreatures, getApprovedCreature, isApprovedForAllCreatures, tokenURI
// C. Creature & Evolution Core Logic (11): mintCreature, getCreatureTraits, getCreatureStats, getCreatureAdaptabilityScore, feedCreature, levelUpCreature, attemptTraitMutation, adaptToEnvironment, updateEnvironmentalConditions (onlyOracle), getEnvironmentalConditions, getTraitNames
// D. Admin & Utility Functions (10): setOracleAddress, setFeedingCost, setLevelUpCost, setMutationCost, setAdaptationCost, setBaseCreatureURI, withdrawFees, pause, unpause, getTraitName (view)

// --- Error Definitions ---
error NotOwner();
error NotOracle();
error Paused();
error NotPaused();
error CreatureDoesNotExist();
error InvalidTokenId();
error NotApprovedOrOwner();
error ZeroAddress();
error InsufficientBalance();
error InsufficientAllowance();
error InsufficientXP();
error MaxLevelReached();
error InvalidTraitIndex();
error InvalidTraitValue();
error EnvironmentNotStale(); // Used to simulate environment update cooldown

// --- Contract Implementation ---

contract EvoPals {
    // --- State Variables: ERC-20 EvoToken ---
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupplyEVO;
    string public constant nameEVO = "EvoToken";
    string public constant symbolEVO = "EVO";
    uint8 public constant decimalsEVO = 18;

    // --- State Variables: ERC-721 EvoCreature ---
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _creatureBalances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;
    string public constant nameCreature = "EvoCreature";
    string public constant symbolCreature = "CREATURE";
    string private baseCreatureURI;

    // --- State Variables: Creature Data & Mechanics ---
    struct CreatureData {
        uint8 level; // 0-100
        uint256 xp;
        uint8[3] traits; // e.g., [strength, agility, intelligence] 0-255
        uint40 lastFedTime; // Unix timestamp
        uint8 environmentalAdaptationLevel; // 0-100
    }

    mapping(uint256 => CreatureData) private creatureData;

    uint256 public feedingCost; // EVO tokens
    uint256 public levelUpCost; // EVO tokens
    uint256 public mutationCost; // EVO tokens
    uint256 public adaptationCost; // EVO tokens
    uint256 public constant XP_PER_FEED = 50;
    uint256 public constant XP_PER_MUTATION_ATTEMPT = 100;
    uint256 public constant XP_REQUIRED_PER_LEVEL = 1000; // Base XP needed per level, can be dynamic
    uint256 public constant ADAPTATION_XP_BONUS = 20;

    // Define trait names - index corresponds to the traits array in CreatureData
    string[3] public traitNames = ["Strength", "Agility", "Intellect"];

    // --- State Variables: Environment & Oracle ---
    struct EnvironmentalConditions {
        uint8 tempIndex; // e.g., 0-100
        uint8 humidityIndex; // e.g., 0-100
        bytes32 externalEntropy; // Entropy from oracle update
    }

    EnvironmentalConditions public environmentalConditions;
    uint40 public lastEnvironmentalUpdateTime; // Unix timestamp
    uint32 public constant ENVIRONMENT_UPDATE_COOLDOWN = 1 hours; // Simulate update frequency
    address public oracleAddress;

    // --- State Variables: Admin ---
    address private _owner;
    bool private paused;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC-20
    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC-20

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC-721
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC-721
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC-721

    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint8[3] initialTraits);
    event CreatureLeveledUp(uint256 indexed tokenId, uint8 newLevel);
    event TraitMutated(uint256 indexed tokenId, uint8 traitIndex, uint8 oldValue, uint8 newValue, bool success);
    event CreatureFed(uint256 indexed tokenId, uint40 lastFedTime, uint256 xpEarned);
    event EnvironmentalUpdate(uint8 tempIndex, uint8 humidityIndex, bytes32 externalEntropy, uint40 updateTime);
    event CostsUpdated(uint256 feeding, uint256 levelUp, uint256 mutation, uint256 adaptation);
    event OracleAddressUpdated(address indexed newOracle);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event FeesWithdrawn(address indexed tokenAddress, address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier creatureExists(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) revert CreatureDoesNotExist();
        _;
    }

    // --- Constructor ---
    constructor(address initialOracle) {
        _owner = msg.sender;
        oracleAddress = initialOracle;
        paused = false;
        _nextTokenId = 1; // Start token IDs from 1

        // Set initial costs (example values)
        feedingCost = 10 ether; // 10 EVO tokens (assuming 18 decimals)
        levelUpCost = 50 ether;
        mutationCost = 25 ether;
        adaptationCost = 15 ether;

        // Set initial environment (example values)
        environmentalConditions = EnvironmentalConditions(50, 50, bytes32(0));
        lastEnvironmentalUpdateTime = uint40(block.timestamp);

        // Set a default base URI (can be updated)
        baseCreatureURI = "ipfs://Qmevo/"; // Example IPFS base URI
    }

    // --- A. ERC-20 EvoToken Functions (Simplified) ---

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        if (_balances[msg.sender] < amount) revert InsufficientBalance();

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (_allowances[from][msg.sender] < amount) revert InsufficientAllowance();
        if (_balances[from] < amount) revert InsufficientBalance();

        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        if (spender == address(0)) revert ZeroAddress();
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupplyEVO;
    }

    // Internal helper function to mint EVO tokens (can be called by privileged functions)
    function _mintEVO(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        _totalSupplyEVO += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal helper function to burn EVO tokens (can be called by privileged functions)
    function _burnEVO(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        if (_balances[account] < amount) revert InsufficientBalance();

        _balances[account] -= amount;
        _totalSupplyEVO -= amount;
        emit Transfer(account, address(0), amount);
    }


    // --- B. ERC-721 EvoCreature Functions (Simplified) ---

    function balanceOfCreatures(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _creatureBalances[owner];
    }

    function ownerOfCreature(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId(); // Use specific error for clarity
        return owner;
    }

    function transferFromCreature(address from, address to, uint256 tokenId) public whenNotPaused creatureExists(tokenId) {
        if (_owners[tokenId] != from) revert NotApprovedOrOwner();
        if (to == address(0)) revert ZeroAddress();
        if (msg.sender != from && !isApprovedForAllCreatures(from, msg.sender) && getApprovedCreature(tokenId) != msg.sender) {
            revert NotApprovedOrOwner();
        }

        // Clear approvals for the token
        _approveCreature(address(0), tokenId);

        _creatureBalances[from]--;
        _owners[tokenId] = to;
        _creatureBalances[to]++;

        emit Transfer(from, to, tokenId);
    }

    function approveCreature(address to, uint256 tokenId) public whenNotPaused creatureExists(tokenId) {
        address owner = _owners[tokenId];
        if (msg.sender != owner && !isApprovedForAllCreatures(owner, msg.sender)) revert NotApprovedOrOwner();
        if (to == owner) revert InvalidTokenId(); // Cannot approve owner

        _approveCreature(to, tokenId);
    }

    function setApprovalForAllCreatures(address operator, bool approved) public whenNotPaused returns (bool) {
        if (operator == msg.sender) revert InvalidTokenId(); // Cannot approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
        return true;
    }

    function getApprovedCreature(uint256 tokenId) public view creatureExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAllCreatures(address owner, address operator) public view returns (bool) {
         if (owner == address(0)) revert ZeroAddress();
         if (operator == address(0)) revert ZeroAddress(); // Added for clarity
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view creatureExists(tokenId) returns (string memory) {
        // Return base URI + token ID. Dynamic traits are ON-CHAIN,
        // but off-chain metadata systems (like IPFS JSON) would typically
        // read the on-chain state to generate the full JSON.
        // Here we just return a basic base URI.
        return string(abi.encodePacked(baseCreatureURI, Strings.toString(tokenId)));
    }

    // Internal helper to set approval
    function _approveCreature(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOfCreature(tokenId), to, tokenId); // Use ownerOfCreature for current owner
    }

    // Internal helper to mint a creature NFT (called by mintCreature)
    function _mintCreature(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert InvalidTokenId(); // Token already exists

        _owners[tokenId] = to;
        _creatureBalances[to]++;
        emit Transfer(address(0), to, tokenId);
    }

    // Internal helper to burn a creature NFT (not used in this example, but good practice)
    // function _burnCreature(uint256 tokenId) internal {
    //     address owner = ownerOfCreature(tokenId); // Check existence implicitly
    //     _approveCreature(address(0), tokenId);
    //     _creatureBalances[owner]--;
    //     delete _owners[tokenId];
    //     // Optional: delete creatureData[tokenId]; if you don't need history
    //     emit Transfer(owner, address(0), tokenId);
    // }


    // --- C. Creature & Evolution Core Logic ---

    /**
     * @dev Mints a new EvoCreature NFT with initial traits.
     * @param owner The address to mint the creature to.
     * @param initialTrait1 The initial value for the first trait (e.g., Strength).
     * @param initialTrait2 The initial value for the second trait (e.g., Agility).
     * @param initialTrait3 The initial value for the third trait (e.g., Intellect).
     */
    function mintCreature(address owner, uint8 initialTrait1, uint8 initialTrait2, uint8 initialTrait3)
        public
        onlyOwner // Only owner can mint initial creatures
        whenNotPaused
    {
        if (owner == address(0)) revert ZeroAddress();

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _mintCreature(owner, tokenId); // Mint the NFT

        creatureData[tokenId] = CreatureData({
            level: 1,
            xp: 0,
            traits: [initialTrait1, initialTrait2, initialTrait3],
            lastFedTime: uint40(block.timestamp),
            environmentalAdaptationLevel: 0
        });

        emit CreatureMinted(tokenId, owner, [initialTrait1, initialTrait2, initialTrait3]);
    }

    /**
     * @dev Gets the current trait values for a creature.
     * @param tokenId The ID of the creature NFT.
     * @return An array of trait values.
     */
    function getCreatureTraits(uint256 tokenId) public view creatureExists(tokenId) returns (uint8[3] memory) {
        return creatureData[tokenId].traits;
    }

    /**
     * @dev Gets the current level, XP, last fed time, and adaptation level for a creature.
     * @param tokenId The ID of the creature NFT.
     * @return level, xp, lastFedTime, environmentalAdaptationLevel.
     */
    function getCreatureStats(uint256 tokenId) public view creatureExists(tokenId) returns (uint8 level, uint256 xp, uint40 lastFedTime, uint8 environmentalAdaptationLevel) {
        CreatureData storage data = creatureData[tokenId];
        return (data.level, data.xp, data.lastFedTime, data.environmentalAdaptationLevel);
    }

    /**
     * @dev Calculates the current adaptability score for a creature.
     * This is a dynamic score based on various factors.
     * Example calculation: Base Level + (XP / XP_REQUIRED_PER_LEVEL) + FedBonus + EnvironmentalMatchBonus + AdaptationBonus
     * @param tokenId The ID of the creature NFT.
     * @return The calculated adaptability score (higher is better).
     */
    function getCreatureAdaptabilityScore(uint256 tokenId) public view creatureExists(tokenId) returns (uint256) {
        return _calculateAdaptability(tokenId);
    }

    /**
     * @dev Feeds a creature, burning EVO tokens and increasing XP.
     * Updates last fed time, which influences adaptability.
     * @param tokenId The ID of the creature NFT.
     */
    function feedCreature(uint256 tokenId) public whenNotPaused creatureExists(tokenId) {
        address owner = ownerOfCreature(tokenId);
        if (msg.sender != owner) revert NotApprovedOrOwner();

        _burnEVO(msg.sender, feedingCost); // Burn tokens from the owner
        _addXP(tokenId, XP_PER_FEED); // Add XP

        creatureData[tokenId].lastFedTime = uint40(block.timestamp); // Update fed time

        emit CreatureFed(tokenId, creatureData[tokenId].lastFedTime, XP_PER_FEED);
    }

    /**
     * @dev Attempts to level up a creature if it has enough XP and burns the required EVO tokens.
     * @param tokenId The ID of the creature NFT.
     */
    function levelUpCreature(uint256 tokenId) public whenNotPaused creatureExists(tokenId) {
        address owner = ownerOfCreature(tokenId);
        if (msg.sender != owner) revert NotApprovedOrOwner();

        CreatureData storage data = creatureData[tokenId];
        uint256 requiredXP = uint256(data.level) * XP_REQUIRED_PER_LEVEL;

        if (data.level >= 100) revert MaxLevelReached(); // Example Max level
        if (data.xp < requiredXP) revert InsufficientXP();

        _burnEVO(msg.sender, levelUpCost); // Burn tokens

        data.level++;
        data.xp -= requiredXP; // Consume required XP for level up

        emit CreatureLeveledUp(tokenId, data.level);
    }

    /**
     * @dev Attempts to mutate a specific trait of a creature.
     * Burns EVO tokens. Success is probabilistic based on adaptability, environment, and simulated randomness.
     * WARNING: This on-chain randomness simulation is NOT SECURE.
     * @param tokenId The ID of the creature NFT.
     * @param traitIndex The index of the trait to attempt mutating (0, 1, or 2).
     * @param desiredTraitValue The value to attempt mutating the trait to.
     * @param userEntropy A number provided by the user to add entropy (less predictable).
     */
    function attemptTraitMutation(uint256 tokenId, uint8 traitIndex, uint8 desiredTraitValue, uint256 userEntropy) public whenNotPaused creatureExists(tokenId) {
        address owner = ownerOfCreature(tokenId);
        if (msg.sender != owner) revert NotApprovedOrOwner();
        if (traitIndex >= traitNames.length) revert InvalidTraitIndex();
        // Add validation for desiredTraitValue if needed (e.g., min/max range)

        _burnEVO(msg.sender, mutationCost); // Burn tokens
        _addXP(tokenId, XP_PER_MUTATION_ATTEMPT); // Add XP for the attempt

        CreatureData storage data = creatureData[tokenId];

        // --- SIMULATED RANDOMNESS (INSECURE!) ---
        // Combine block data, external oracle entropy, and user entropy
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Deprecated, but included for example entropy sources
            msg.sender,
            tokenId,
            userEntropy,
            environmentalConditions.externalEntropy // Use entropy from latest oracle update
        ));
        uint256 randomNumber = uint256(seed);

        // --- Probability Calculation ---
        uint256 adaptabilityScore = _calculateAdaptability(tokenId);
        uint256 successChance = 30; // Base chance (e.g., 30%)
        successChance += adaptabilityScore / 10; // Adaptability adds to chance (e.g., 1 point adaptability = 0.1% chance)

        // Add bonus based on how well current trait matches environment (example logic)
        // This part is conceptual - linking specific traits to environment requires more complex rules
        // For simplicity, let's say higher adaptability means better chance regardless of specific trait match
        // successChance += _getEnvironmentalMatchBonus(tokenId, traitIndex);

        // Cap success chance
        if (successChance > 90) successChance = 90; // Max 90% chance

        // Determine success based on random number and chance
        bool success = (randomNumber % 100) < successChance;

        uint8 oldTraitValue = data.traits[traitIndex];

        if (success) {
            data.traits[traitIndex] = desiredTraitValue; // Mutate to desired value
        }
        // Note: Could also implement random mutation within a range on failure or partial success

        emit TraitMutated(tokenId, traitIndex, oldTraitValue, data.traits[traitIndex], success);
    }

    /**
     * @dev Burns EVO tokens to increase a creature's adaptation level to the *current* environment.
     * @param tokenId The ID of the creature NFT.
     */
    function adaptToEnvironment(uint256 tokenId) public whenNotPaused creatureExists(tokenId) {
        address owner = ownerOfCreature(tokenId);
        if (msg.sender != owner) revert NotApprovedOrOwner();

        _burnEVO(msg.sender, adaptationCost); // Burn tokens
        _addXP(tokenId, ADAPTATION_XP_BONUS); // Add XP for the effort

        CreatureData storage data = creatureData[tokenId];
        if (data.environmentalAdaptationLevel < 100) {
            data.environmentalAdaptationLevel++; // Increase adaptation level (simple increment)
        }
        // Note: More complex logic could base increase on current level, cost, etc.
    }

    /**
     * @dev Called by the designated oracle address to update the simulated environmental conditions.
     * Includes external entropy for use in probabilistic functions.
     * Has a cooldown to prevent frequent updates.
     * @param tempIndex The new simulated temperature index.
     * @param humidityIndex The new simulated humidity index.
     * @param externalEntropy A random bytes32 provided by the oracle.
     */
    function updateEnvironmentalConditions(uint8 tempIndex, uint8 humidityIndex, bytes32 externalEntropy)
        public
        onlyOracle
        whenNotPaused
    {
        // Enforce cooldown
        if (block.timestamp < lastEnvironmentalUpdateTime + ENVIRONMENT_UPDATE_COOLDOWN) {
            revert EnvironmentNotStale();
        }

        environmentalConditions = EnvironmentalConditions(tempIndex, humidityIndex, externalEntropy);
        lastEnvironmentalUpdateTime = uint40(block.timestamp);

        emit EnvironmentalUpdate(tempIndex, humidityIndex, externalEntropy, lastEnvironmentalUpdateTime);
    }

    /**
     * @dev Gets the current simulated environmental conditions.
     * @return tempIndex, humidityIndex, externalEntropy.
     */
    function getEnvironmentalConditions() public view returns (EnvironmentalConditions memory) {
        return environmentalConditions;
    }

    /**
     * @dev Gets the names of the different traits.
     * @return An array of trait names.
     */
    function getTraitNames() public view returns (string[3] memory) {
        return traitNames;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the adaptability score for a creature based on its state and environment.
     * Internal helper function.
     * @param tokenId The ID of the creature NFT.
     * @return The calculated adaptability score.
     */
    function _calculateAdaptability(uint256 tokenId) internal view returns (uint256) {
        CreatureData storage data = creatureData[tokenId];
        uint256 adaptability = 0;

        // Base adaptability from level
        adaptability += uint256(data.level);

        // Bonus from XP (progress within level)
        uint256 requiredXP = uint256(data.level) * XP_REQUIRED_PER_LEVEL;
        if (requiredXP > 0) {
             adaptability += (data.xp * 10) / requiredXP; // Add up to 10 points based on XP progress
        }


        // Bonus from recent feeding (e.g., full bonus for 1 day, tapers off)
        uint256 timeSinceLastFed = block.timestamp - data.lastFedTime;
        uint256 feedingBonusDecayTime = 2 days; // Example: Bonus lasts up to 2 days
        if (timeSinceLastFed < feedingBonusDecayTime) {
            adaptability += 20 * (feedingBonusDecayTime - timeSinceLastFed) / feedingBonusDecayTime; // Up to 20 bonus points
        }


        // Bonus from environmental adaptation level (e.g., 0.5 point per adaptation level)
        adaptability += uint256(data.environmentalAdaptationLevel) / 2;

        // Bonus from matching environment (conceptual - comparing traits to env indices)
        // This requires defining how traits relate to environment. Example:
        // uint256 envMatchScore = 0;
        // // Example: Strength trait matches TempIndex, Agility matches HumidityIndex
        // envMatchScore += (255 - abs(int(data.traits[0]) - int(environmentalConditions.tempIndex))) / 10; // Max ~25 points
        // envMatchScore += (255 - abs(int(data.traits[1]) - int(environmentalConditions.humidityIndex))) / 10; // Max ~25 points
        // adaptability += envMatchScore / 5; // Add up to ~10 points from environment match


        // Cap adaptability score (optional)
        if (adaptability > 200) adaptability = 200; // Example max score

        return adaptability;
    }

    /**
     * @dev Adds experience points to a creature.
     * Internal helper function.
     * @param tokenId The ID of the creature NFT.
     * @param amount The amount of XP to add.
     */
    function _addXP(uint256 tokenId, uint256 amount) internal creatureExists(tokenId) {
        creatureData[tokenId].xp += amount;
        // Could emit an event here if desired
    }

    /**
     * @dev Internal function to generate a pseudo-random number.
     * WARNING: This is NOT SECURE for applications requiring unpredictable randomness.
     * Relies on block data, sender, token ID, user input, and oracle entropy.
     * Should be replaced by Chainlink VRF or similar in production.
     * @param seedInput Extra seed material.
     * @return A pseudo-random uint256.
     */
     // NOTE: This function is internal and not counted in the public function summary,
     // but its usage in `attemptTraitMutation` is key to the concept.
    function _generatePseudoRandomNumber(uint256 seedInput) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            seedInput,
            environmentalConditions.externalEntropy
        )));
    }

    // --- D. Admin & Utility Functions ---

    function owner() public view returns (address) {
        return _owner;
    }

    function setOracleAddress(address _oracleAddress) public onlyOwner whenNotPaused {
        if (_oracleAddress == address(0)) revert ZeroAddress();
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    function setFeedingCost(uint256 cost) public onlyOwner whenNotPaused {
        feedingCost = cost;
        emit CostsUpdated(feedingCost, levelUpCost, mutationCost, adaptationCost);
    }

    function setLevelUpCost(uint256 cost) public onlyOwner whenNotPaused {
        levelUpCost = cost;
        emit CostsUpdated(feedingCost, levelUpCost, mutationCost, adaptationCost);
    }

    function setMutationCost(uint256 cost) public onlyOwner whenNotPaused {
        mutationCost = cost;
        emit CostsUpdated(feedingCost, levelUpCost, mutationCost, adaptationCost);
    }

    function setAdaptationCost(uint256 cost) public onlyOwner whenNotPaused {
        adaptationCost = cost;
        emit CostsUpdated(feedingCost, levelUpCost, mutationCost, adaptationCost);
    }

    function setBaseCreatureURI(string memory baseURI) public onlyOwner whenNotPaused {
        baseCreatureURI = baseURI;
        // No event for URI change typically, but could add one if needed
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated EVO tokens from interaction fees.
     * Fees are automatically collected when users burn tokens for actions.
     * @param tokenAddress The address of the token to withdraw (in this case, implicitly this contract's EVO).
     */
    function withdrawFees(address tokenAddress) public onlyOwner whenNotPaused {
        // In this simplified model where EVO is within this contract, fees are just here.
        // If EVO were external, we would need to track collected fees separately.
        // Here, the total balance of *this* contract in EVO represents collected fees.
        // This assumes the owner is the *only* source of initial EVO minting not for fees.
        // A more robust system would track fees explicitly.
        // For simplicity, we'll let owner withdraw this contract's EVO balance.
        // This could be risky if the contract needs some reserve.
        // Better: track collectedFees mapping for each action.
        // Simple version for demonstration:
        uint256 contractBalance = _balances[address(this)];
        if (contractBalance == 0) return;

        _balances[address(this)] = 0;
        _balances[msg.sender] += contractBalance; // Send to owner
        emit Transfer(address(this), msg.sender, contractBalance);
        emit FeesWithdrawn(tokenAddress, msg.sender, contractBalance);
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

     function getTraitName(uint8 traitIndex) public view returns (string memory) {
        if (traitIndex >= traitNames.length) revert InvalidTraitIndex();
        return traitNames[traitIndex];
    }
}

// Basic library for converting uint256 to string, needed for tokenURI
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
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```