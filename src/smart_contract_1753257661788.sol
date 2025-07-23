This smart contract, `EvoSoulGenesis`, represents a cutting-edge approach to dynamic, AI-assisted, and community-governed digital assets. It moves beyond static NFTs by creating "Living Assets" (EvoSouls) that can evolve, merge, breed, and be influenced by AI-generated traits and owner reputation. The system is fueled by a utility token (`Catalyst`) and governed by a decentralized autonomous organization (DAO).

---

## Contract: `EvoSoulGenesis`

**Concept:** `EvoSoulGenesis` creates dynamic, evolving NFTs ("EvoSouls") that integrate AI-generated traits, owner reputation, and DAO governance. Each EvoSoul is a unique, programmable digital entity that changes over time based on user interaction, AI input, and community decisions.

**Key Advanced Concepts:**

1.  **Dynamic NFTs (EvoSouls):** Traits and metadata evolve based on on-chain actions and external data.
2.  **AI Integration (Oracle-driven):** Users or the DAO can request AI to generate new traits or modify existing ones via a trusted AI oracle.
3.  **Reputation-Linked Evolution:** EvoSouls can be linked to an owner's non-transferable reputation token (SBT-like), influencing the EvoSoul's traits or evolution path.
4.  **Complex Lifecycle Mechanics:** Includes evolution stages, merging, breeding, decomposition, and trait locking.
5.  **DAO Governance:** Critical parameters, evolution rules, and AI oracle updates are controlled by the community.
6.  **Utility Token Integration:** A dedicated `Catalyst` token fuels evolution, AI requests, and other actions.
7.  **Delegated Rights:** Owners can delegate specific actions (like evolution) to other addresses.
8.  **On-Chain Snapshotting:** Records the historical state of an EvoSoul.

---

### Outline and Function Summary:

**I. State Variables & Global Configurations**
    *   `catalystToken`: ERC20 token used for operations.
    *   `aiOracle`: Address of the trusted AI Oracle contract.
    *   `reputationSystem`: Address of the Reputation System (SBT-like) contract.
    *   `minEvolutionInterval`: Minimum time between evolutions.
    *   `evolutionCost`: Cost in Catalyst tokens for evolving.
    *   `nextEvolutionStageBonus`: Bonus to evolution power for each stage.
    *   `daoGovernor`: Address of the DAO's Governor contract (for privileged functions).
    *   `evoSouls`: Mapping of tokenId to `EvoSoul` struct.
    *   `snapshottedStates`: Mapping of tokenId to evolution stage to `EvoSoul` struct (for history).
    *   `allowedTraitCategories`: Whitelist/blacklist for AI-generated trait categories.

**II. Interfaces**
    *   `IAIOracle`: Interface for AI Oracle callbacks.
    *   `IReputationSystem`: Interface for interacting with the Reputation System.
    *   `ICatalystToken`: Interface for the Catalyst ERC20 token.

**III. Events**
    *   `EvoSoulMinted`: When a new EvoSoul is minted.
    *   `EvoSoulEvolved`: When an EvoSoul changes its evolution stage.
    *   `AITraitRequestSent`: When an AI trait generation request is made.
    *   `AITraitFulfilled`: When an AI oracle updates EvoSoul traits.
    *   `EvoSoulMerged`: When two EvoSouls are merged.
    *   `EvoSoulBred`: When a new EvoSoul is bred from parents.
    *   `EvoSoulDecomposed`: When an EvoSoul is decomposed.
    *   `EvoSoulLocked`: When an EvoSoul's traits are locked.
    *   `EvolutionRightsDelegated`: When evolution rights are delegated.
    *   `ReputationLinked`: When an EvoSoul is linked to a reputation token.
    *   `ReputationTraitsSynced`: When EvoSoul traits are synced with reputation.
    *   `EvolutionCostUpdated`: When the evolution cost is changed by DAO.
    *   `AIOracleUpdated`: When the AI oracle address is changed.

**IV. Modifiers**
    *   `onlyAIOracle`: Restricts function calls to the designated AI Oracle.
    *   `onlyGovernor`: Restricts function calls to the DAO Governor.
    *   `notLocked`: Ensures an EvoSoul's traits are not locked.
    *   `enoughTimePassed`: Checks if minimum evolution interval has passed.

**V. Constructor**
    *   Initializes the contract with addresses for Catalyst, AI Oracle, Reputation System, and DAO Governor.

**VI. ERC721 Overrides**
    *   Standard ERC721 functions like `_baseURI()`, `tokenURI()`.
    *   `_authorizeUpgrade(address newImplementation)`: For UUPS proxy pattern (implied, not fully shown for brevity).

**VII. EvoSoul Core Mechanics**
1.  `mintGenesisEvoSoul(address _to, string memory _initialDNAHash)`: Mints the very first generation EvoSoul.
2.  `evolveEvoSoul(uint256 _tokenId)`: Advances an EvoSoul's evolution stage, consuming `Catalyst` and potentially unlocking new features or trait slots.
3.  `mergeEvoSouls(uint256 _tokenId1, uint256 _tokenId2)`: Combines two EvoSouls into a new one, inheriting traits and averaging evolution stages. Original tokens are burned.
4.  `breedEvoSouls(uint256 _parent1Id, uint256 _parent2Id, address _to)`: Creates a new child EvoSoul based on a genetic mix of two parent EvoSouls.
5.  `decomposeEvoSoul(uint256 _tokenId)`: Allows an owner to decompose an EvoSoul, potentially receiving a partial Catalyst refund or other in-game resources.
6.  `snapshotEvoSoulState(uint256 _tokenId)`: Records the current state of an EvoSoul at its current evolution stage, creating an immutable historical snapshot.
7.  `lockEvoSoulTraits(uint256 _tokenId, uint256 _duration)`: Prevents any trait modifications or evolution for a specified duration.
8.  `delegateEvolutionRights(uint256 _tokenId, address _delegatee)`: Grants another address the permission to call `evolveEvoSoul` on behalf of the owner.
9.  `revokeEvolutionRights(uint256 _tokenId)`: Revokes previously delegated evolution rights.
10. `getEvoSoulMetadataURI(uint256 _tokenId)`: Generates the dynamic metadata URI for an EvoSoul.

**VIII. AI Integration**
11. `requestAI_TraitGeneration(uint256 _tokenId, string memory _prompt, string memory _traitCategory)`: Sends a request to the AI Oracle to generate new traits for an EvoSoul based on a prompt, consuming Catalyst.
12. `fulfillAI_TraitGeneration(uint256 _tokenId, string memory _traitKey, string memory _traitValue, string memory _newMetadataHash)`: Callback function called *only* by the AI Oracle to update an EvoSoul's traits after processing a request.

**IX. Reputation System Interaction**
13. `linkEvoSoulToReputation(uint256 _evoSoulId, uint256 _reputationTokenId)`: Links an EvoSoul to a specific reputation token owned by the EvoSoul owner. This allows reputation to influence the EvoSoul.
14. `syncReputationTraits(uint256 _evoSoulId)`: Triggers an update of an EvoSoul's traits based on its linked reputation token's current attributes (e.g., higher reputation unlocks "wisdom" trait).

**X. Catalyst Token Interaction**
15. `setCatalystToken(address _catalystTokenAddress)`: Sets the address of the `Catalyst` ERC20 token (only callable by Governor).
16. `fundEvolutionPool(uint256 _amount)`: Allows the DAO or other privileged entities to add `Catalyst` to the contract's pool for future use (e.g., rewards, specific features).

**XI. DAO Governance Functions**
    *(These functions are callable only by the `daoGovernor` and represent parameters that can be adjusted via DAO proposals)*
17. `updateEvolutionCost(uint256 _newCost)`: Adjusts the `Catalyst` cost required for EvoSoul evolution.
18. `updateMinEvolutionInterval(uint256 _newInterval)`: Sets the minimum time an EvoSoul must wait between evolutions.
19. `updateAIOracleAddress(address _newAIOracleAddress)`: Changes the trusted AI Oracle address.
20. `setAllowedTraitCategory(string memory _category, bool _allowed)`: Whitelists or blacklists specific trait categories that the AI oracle can generate, ensuring curated content.
21. `setDynamicBaseURI(string memory _newBaseURI)`: Updates the base URI for the dynamic metadata server.
22. `withdrawFees()`: Allows the DAO Governor to withdraw accumulated Catalyst fees from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for external contracts
interface IAIOracle {
    function fulfillAITraitGeneration(uint256 _tokenId, string calldata _traitKey, string calldata _traitValue, string calldata _newMetadataHash) external;
    // Add other AI specific functions if needed, e.g., requestAIModelUpdate
}

interface IReputationSystem {
    // Example: Function to get a user's reputation level or specific trait
    function getReputationLevel(uint256 _reputationTokenId) external view returns (uint256);
    function getReputationTrait(uint256 _reputationTokenId, string calldata _traitKey) external view returns (string memory);
    // Add other functions relevant to reputation influence on EvoSouls
}

interface ICatalystToken is IERC20 {
    // ERC20 standard functions already included via IERC20
}

contract EvoSoulGenesis is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- I. State Variables & Global Configurations ---

    // Core EvoSoul Data Structure
    struct EvoSoul {
        uint256 generation;              // How many times it's been bred/merged
        uint256 evolutionStage;          // Current stage of evolution (0-X)
        string dnaHash;                  // A unique identifier for its core "essence"
        string currentMetadataHash;      // Hash of the current metadata for integrity check
        mapping(string => string) traits; // Dynamic traits that can be updated (e.g., "Strength": "10", "Color": "Red")
        uint256 lastEvolutionTime;       // Timestamp of the last evolution
        uint256 linkedReputationTokenId; // ID of the linked Reputation token (0 if not linked)
        bool isLocked;                   // True if traits are locked
        uint256 lockedUntil;             // Timestamp until which traits are locked
        address evolutionDelegate;       // Address authorized to evolve this EvoSoul
    }

    mapping(uint256 => EvoSoul) public evoSouls;
    mapping(uint256 => mapping(uint256 => EvoSoul)) public snapshottedStates; // tokenId => evolutionStage => EvoSoul data

    // Contract addresses
    ICatalystToken public catalystToken;
    IAIOracle public aiOracle;
    IReputationSystem public reputationSystem;
    address public daoGovernor; // The address of the DAO's Governor contract

    // System parameters (DAO-governed)
    uint256 public minEvolutionInterval; // Minimum time (seconds) between evolutions
    uint256 public evolutionCost;        // Cost in Catalyst tokens for each evolution
    uint256 public nextEvolutionStageBonus; // Bonus power/features unlocked per stage
    string public dynamicBaseURI;        // Base URI for the dynamic metadata server
    mapping(string => bool) public allowedTraitCategories; // Whitelist for AI trait categories

    // --- II. Events ---
    event EvoSoulMinted(uint256 indexed tokenId, address indexed owner, string dnaHash);
    event EvoSoulEvolved(uint256 indexed tokenId, uint256 newStage, address indexed by);
    event AITraitRequestSent(uint256 indexed tokenId, address indexed requester, string prompt, string traitCategory);
    event AITraitFulfilled(uint256 indexed tokenId, string traitKey, string traitValue, string newMetadataHash);
    event EvoSoulMerged(uint256 indexed newTokenId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event EvoSoulBred(uint256 indexed childTokenId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event EvoSoulDecomposed(uint256 indexed tokenId, address indexed owner, uint256 refundedCatalyst);
    event EvoSoulLocked(uint256 indexed tokenId, uint256 lockedUntil);
    event EvolutionRightsDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event ReputationLinked(uint256 indexed evoSoulId, uint256 indexed reputationTokenId);
    event ReputationTraitsSynced(uint256 indexed evoSoulId);
    event EvolutionCostUpdated(uint256 newCost);
    event MinEvolutionIntervalUpdated(uint256 newInterval);
    event AIOracleUpdated(address newAIOracleAddress);
    event TraitCategoryAllowed(string indexed category, bool allowed);
    event DynamicBaseURIUpdated(string newBaseURI);
    event FeesWithdrawn(uint256 amount);

    // --- III. Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "EvoSoulGenesis: Only AI Oracle can call this");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == daoGovernor, "EvoSoulGenesis: Only DAO Governor can call this");
        _;
    }

    modifier notLocked(uint256 _tokenId) {
        require(evoSouls[_tokenId].isLocked == false || block.timestamp > evoSouls[_tokenId].lockedUntil, "EvoSoulGenesis: EvoSoul is locked");
        _;
    }

    modifier enoughTimePassed(uint256 _tokenId) {
        require(block.timestamp >= evoSouls[_tokenId].lastEvolutionTime + minEvolutionInterval, "EvoSoulGenesis: Not enough time passed since last evolution");
        _;
    }

    // --- IV. Constructor ---
    constructor(
        address _catalystTokenAddress,
        address _aiOracleAddress,
        address _reputationSystemAddress,
        address _daoGovernorAddress,
        string memory _initialBaseURI
    ) ERC721("EvoSoulGenesis", "EVO") Ownable(msg.sender) {
        require(_catalystTokenAddress != address(0), "EvoSoulGenesis: Invalid Catalyst token address");
        require(_aiOracleAddress != address(0), "EvoSoulGenesis: Invalid AI Oracle address");
        require(_reputationSystemAddress != address(0), "EvoSoulGenesis: Invalid Reputation System address");
        require(_daoGovernorAddress != address(0), "EvoSoulGenesis: Invalid DAO Governor address");

        catalystToken = ICatalystToken(_catalystTokenAddress);
        aiOracle = IAIOracle(_aiOracleAddress);
        reputationSystem = IReputationSystem(_reputationSystemAddress);
        daoGovernor = _daoGovernorAddress;

        // Set initial DAO-governed parameters
        minEvolutionInterval = 7 days; // 7 days
        evolutionCost = 100 * (10 ** 18); // 100 Catalyst tokens (assuming 18 decimals)
        nextEvolutionStageBonus = 10; // Placeholder for how much bonus new stage gives
        dynamicBaseURI = _initialBaseURI;
    }

    // --- V. ERC721 Overrides ---
    function _baseURI() internal view override returns (string memory) {
        return dynamicBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        string memory _currentMetadataHash = evoSouls[tokenId].currentMetadataHash;
        require(bytes(_currentMetadataHash).length > 0, "EvoSoulGenesis: Metadata hash not set");
        
        // Example: Base URI + token ID + hash for cache busting/integrity
        return string(abi.encodePacked(dynamicBaseURI, Strings.toString(tokenId), "/", _currentMetadataHash));
    }
    
    // For UUPS proxy pattern (simplified, actual implementation would be in a proxy contract)
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}


    // --- VI. EvoSoul Core Mechanics ---

    /**
     * @dev Mints the very first generation EvoSoul.
     * @param _to The address to mint the EvoSoul to.
     * @param _initialDNAHash An initial unique hash representing the EvoSoul's core identity.
     */
    function mintGenesisEvoSoul(address _to, string memory _initialDNAHash) public onlyOwner nonReentrant {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        evoSouls[newItemId] = EvoSoul({
            generation: 1,
            evolutionStage: 0,
            dnaHash: _initialDNAHash,
            currentMetadataHash: "", // Will be set by AI/manual update
            traits: new mapping(string => string)(),
            lastEvolutionTime: block.timestamp,
            linkedReputationTokenId: 0,
            isLocked: false,
            lockedUntil: 0,
            evolutionDelegate: address(0)
        });

        _safeMint(_to, newItemId);
        emit EvoSoulMinted(newItemId, _to, _initialDNAHash);
    }

    /**
     * @dev Advances an EvoSoul's evolution stage, consuming Catalyst.
     * Requires minimum time to have passed and owner/delegate to pay Catalyst.
     * @param _tokenId The ID of the EvoSoul to evolve.
     */
    function evolveEvoSoul(uint256 _tokenId) public nonReentrant notLocked(_tokenId) enoughTimePassed(_tokenId) {
        address _owner = ownerOf(_tokenId);
        require(msg.sender == _owner || msg.sender == evoSouls[_tokenId].evolutionDelegate, "EvoSoulGenesis: Caller not owner or delegate");
        
        // Take Catalyst payment
        catalystToken.transferFrom(msg.sender, address(this), evolutionCost);

        EvoSoul storage soul = evoSouls[_tokenId];
        soul.evolutionStage++;
        soul.lastEvolutionTime = block.timestamp;

        // Optionally, trigger an AI trait update or provide new trait slots here
        // e.g., requestAI_TraitGeneration(_tokenId, "evolved", "general");

        emit EvoSoulEvolved(_tokenId, soul.evolutionStage, msg.sender);
    }

    /**
     * @dev Combines two EvoSouls into a new, potentially stronger one. Original tokens are burned.
     * Traits are inherited, evolution stages are averaged, and generation increases.
     * @param _tokenId1 The ID of the first EvoSoul.
     * @param _tokenId2 The ID of the second EvoSoul.
     */
    function mergeEvoSouls(uint256 _tokenId1, uint256 _tokenId2) public nonReentrant {
        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);
        require(msg.sender == owner1 && msg.sender == owner2, "EvoSoulGenesis: Caller must own both EvoSouls");
        require(_tokenId1 != _tokenId2, "EvoSoulGenesis: Cannot merge an EvoSoul with itself");

        EvoSoul storage soul1 = evoSouls[_tokenId1];
        EvoSoul storage soul2 = evoSouls[_tokenId2];

        _tokenIdCounter.increment();
        uint256 newEvoSoulId = _tokenIdCounter.current();

        // Simple merge logic: average evolution stage, higher generation, combine traits
        uint256 newEvolutionStage = (soul1.evolutionStage + soul2.evolutionStage) / 2;
        uint256 newGeneration = max(soul1.generation, soul2.generation) + 1;
        
        // A simple DNA hash combination (e.g., XOR or concatenation hash)
        string memory newDnaHash = string(abi.encodePacked(soul1.dnaHash, soul2.dnaHash)); // In reality, use keccak256 hash
        
        EvoSoul memory newSoul = EvoSoul({
            generation: newGeneration,
            evolutionStage: newEvolutionStage,
            dnaHash: newDnaHash,
            currentMetadataHash: "",
            traits: new mapping(string => string)(), // Traits are copied below
            lastEvolutionTime: block.timestamp,
            linkedReputationTokenId: 0, // Reset linkage on merge
            isLocked: false,
            lockedUntil: 0,
            evolutionDelegate: address(0)
        });

        // Copy traits (prefer soul1's traits in case of conflict for simplicity)
        // In a real system, trait merging would be more complex (e.g., specific rules, AI assistance)
        // Example for illustration: Iterate over mappings is hard, so this is conceptual.
        // For actual implementation, traits would likely be an array of structs or a fixed set.
        // For now, let's assume `fulfillAI_TraitGeneration` will be called to set new traits.

        evoSouls[newEvoSoulId] = newSoul;
        _safeMint(msg.sender, newEvoSoulId);

        // Burn the original EvoSouls
        _burn(_tokenId1);
        _burn(_tokenId2);

        emit EvoSoulMerged(newEvoSoulId, _tokenId1, _tokenId2);
    }

    /**
     * @dev Creates a new EvoSoul based on traits from two parent EvoSouls (breeding).
     * Parents are not burned but a new child token is minted.
     * @param _parent1Id The ID of the first parent EvoSoul.
     * @param _parent2Id The ID of the second parent EvoSoul.
     * @param _to The address to mint the child EvoSoul to.
     */
    function breedEvoSouls(uint256 _parent1Id, uint256 _parent2Id, address _to) public nonReentrant {
        require(ownerOf(_parent1Id) == msg.sender && ownerOf(_parent2Id) == msg.sender, "EvoSoulGenesis: Caller must own both parents");
        require(_parent1Id != _parent2Id, "EvoSoulGenesis: Cannot breed with itself");

        EvoSoul storage parent1 = evoSouls[_parent1Id];
        EvoSoul storage parent2 = evoSouls[_parent2Id];

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        // Simple breeding logic: new generation, initial stage, combine DNA
        uint256 childGeneration = max(parent1.generation, parent2.generation) + 1;
        uint256 initialChildStage = 0; // Child starts at stage 0
        string memory childDnaHash = string(abi.encodePacked(parent1.dnaHash, parent2.dnaHash, Strings.toString(childGeneration)));

        EvoSoul memory childSoul = EvoSoul({
            generation: childGeneration,
            evolutionStage: initialChildStage,
            dnaHash: childDnaHash,
            currentMetadataHash: "",
            traits: new mapping(string => string)(), // Traits will be inherited/generated
            lastEvolutionTime: block.timestamp,
            linkedReputationTokenId: 0,
            isLocked: false,
            lockedUntil: 0,
            evolutionDelegate: address(0)
        });

        // In a real system, trait inheritance would be complex.
        // For now, conceptual: a new AI request or deterministic trait generation from parents.

        evoSouls[childTokenId] = childSoul;
        _safeMint(_to, childTokenId);

        emit EvoSoulBred(childTokenId, _parent1Id, _parent2Id);
    }

    /**
     * @dev Decomposes an EvoSoul, potentially refunding some Catalyst or providing resources.
     * The EvoSoul is burned.
     * @param _tokenId The ID of the EvoSoul to decompose.
     */
    function decomposeEvoSoul(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        
        // Calculate refund based on evolution stage, generation, etc.
        uint256 refundAmount = evoSouls[_tokenId].evolutionStage * (evolutionCost / 4); // Example: 25% of evolution cost per stage
        
        _burn(_tokenId);
        if (refundAmount > 0) {
            catalystToken.transfer(msg.sender, refundAmount);
        }

        emit EvoSoulDecomposed(_tokenId, msg.sender, refundAmount);
    }

    /**
     * @dev Records the current state of an EvoSoul at its current evolution stage, creating an immutable historical snapshot.
     * @param _tokenId The ID of the EvoSoul to snapshot.
     */
    function snapshotEvoSoulState(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        EvoSoul storage currentSoul = evoSouls[_tokenId];
        
        // Deep copy the current EvoSoul state to the snapshot mapping
        EvoSoul memory snapshot = currentSoul; // Structs are value types when assigned this way
        // Important: `traits` mapping cannot be directly copied. This is a known Solidity limitation.
        // For a full snapshot, traits would need to be stored as a dynamic array of key-value pairs
        // or a dedicated snapshotting function for traits would be needed.
        // For this example, we assume `traits` mapping is effectively part of the state for external metadata generation.

        snapshottedStates[_tokenId][currentSoul.evolutionStage] = snapshot;
        // Optionally, an event could be emitted here
    }

    /**
     * @dev Prevents any trait modifications or evolution for a specified duration.
     * @param _tokenId The ID of the EvoSoul to lock.
     * @param _duration The duration in seconds to lock the EvoSoul.
     */
    function lockEvoSoulTraits(uint256 _tokenId, uint256 _duration) public {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        require(_duration > 0, "EvoSoulGenesis: Lock duration must be greater than 0");
        
        EvoSoul storage soul = evoSouls[_tokenId];
        soul.isLocked = true;
        soul.lockedUntil = block.timestamp + _duration;

        emit EvoSoulLocked(_tokenId, soul.lockedUntil);
    }

    /**
     * @dev Allows an owner to delegate the right to call `evolveEvoSoul` for their EvoSoul to another address.
     * @param _tokenId The ID of the EvoSoul.
     * @param _delegatee The address to delegate evolution rights to.
     */
    function delegateEvolutionRights(uint256 _tokenId, address _delegatee) public {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        evoSouls[_tokenId].evolutionDelegate = _delegatee;
        emit EvolutionRightsDelegated(_tokenId, msg.sender, _delegatee);
    }

    /**
     * @dev Revokes previously delegated evolution rights.
     * @param _tokenId The ID of the EvoSoul.
     */
    function revokeEvolutionRights(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        evoSouls[_tokenId].evolutionDelegate = address(0);
        emit EvolutionRightsDelegated(_tokenId, msg.sender, address(0)); // Emit with address(0) to signify revocation
    }

    /**
     * @dev Generates the dynamic metadata URI for an EvoSoul.
     * @param _tokenId The ID of the EvoSoul.
     * @return The full URI for the EvoSoul's metadata.
     */
    function getEvoSoulMetadataURI(uint256 _tokenId) public view returns (string memory) {
        // This function is intended to be called by external services (e.g., OpenSea) via tokenURI.
        // The actual `tokenURI` function already handles the base URI.
        // This helper is for direct query.
        return tokenURI(_tokenId);
    }

    // --- VII. AI Integration ---

    /**
     * @dev Sends a request to the AI Oracle to generate new traits for an EvoSoul based on a prompt.
     * Consumes Catalyst tokens.
     * @param _tokenId The ID of the EvoSoul to request traits for.
     * @param _prompt The prompt text for the AI.
     * @param _traitCategory The category of the trait being requested (e.g., "visual", "personality", "skill").
     */
    function requestAI_TraitGeneration(uint256 _tokenId, string memory _prompt, string memory _traitCategory) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        require(allowedTraitCategories[_traitCategory], "EvoSoulGenesis: Trait category not allowed by DAO");
        require(bytes(_prompt).length > 0, "EvoSoulGenesis: Prompt cannot be empty");

        // Example: Cost for AI request, separate from evolution cost
        uint256 aiRequestCost = evolutionCost / 2; // Half the evolution cost
        catalystToken.transferFrom(msg.sender, address(this), aiRequestCost);

        // In a real system, AI Oracle would have a function like `requestGeneration` that
        // takes the contract address and token ID for callback. For simplicity,
        // we emit an event that an off-chain oracle service would listen to.
        emit AITraitRequestSent(_tokenId, msg.sender, _prompt, _traitCategory);
    }

    /**
     * @dev Callback function called *only* by the AI Oracle to update an EvoSoul's traits
     * after processing a request.
     * @param _tokenId The ID of the EvoSoul.
     * @param _traitKey The key of the trait (e.g., "Color", "Personality").
     * @param _traitValue The value of the trait (e.g., "Crimson", "Optimistic").
     * @param _newMetadataHash A hash of the updated metadata URI to ensure integrity/freshness.
     */
    function fulfillAI_TraitGeneration(uint256 _tokenId, string memory _traitKey, string memory _traitValue, string memory _newMetadataHash)
        external
        onlyAIOracle
        nonReentrant
        notLocked(_tokenId)
    {
        require(bytes(_traitKey).length > 0, "EvoSoulGenesis: Trait key cannot be empty");
        require(bytes(_traitValue).length > 0, "EvoSoulGenesis: Trait value cannot be empty");
        require(bytes(_newMetadataHash).length > 0, "EvoSoulGenesis: New metadata hash cannot be empty");

        EvoSoul storage soul = evoSouls[_tokenId];
        soul.traits[_traitKey] = _traitValue;
        soul.currentMetadataHash = _newMetadataHash; // Update the metadata hash

        emit AITraitFulfilled(_tokenId, _traitKey, _traitValue, _newMetadataHash);
    }

    // --- VIII. Reputation System Interaction ---

    /**
     * @dev Links an EvoSoul to a specific reputation token owned by the EvoSoul owner.
     * This allows the reputation token's attributes to influence the EvoSoul.
     * @param _evoSoulId The ID of the EvoSoul to link.
     * @param _reputationTokenId The ID of the reputation token to link.
     */
    function linkEvoSoulToReputation(uint256 _evoSoulId, uint256 _reputationTokenId) public {
        require(ownerOf(_evoSoulId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        // In a real scenario, you'd verify ownership of the reputation token too (e.g., via IReputationSystem.ownerOf)
        // For simplicity, we assume the owner is correctly providing their reputation token ID.
        
        evoSouls[_evoSoulId].linkedReputationTokenId = _reputationTokenId;
        emit ReputationLinked(_evoSoulId, _reputationTokenId);
    }

    /**
     * @dev Triggers an update of an EvoSoul's traits based on its linked reputation token's current attributes.
     * Can unlock "wisdom" trait for high reputation.
     * @param _evoSoulId The ID of the EvoSoul to sync traits for.
     */
    function syncReputationTraits(uint256 _evoSoulId) public notLocked(_evoSoulId) {
        require(ownerOf(_evoSoulId) == msg.sender, "EvoSoulGenesis: Caller must own the EvoSoul");
        uint256 repTokenId = evoSouls[_evoSoulId].linkedReputationTokenId;
        require(repTokenId != 0, "EvoSoulGenesis: EvoSoul not linked to a reputation token");

        // Example: Fetch reputation level and update a trait
        uint256 repLevel = reputationSystem.getReputationLevel(repTokenId);
        
        // This is a simplified example. Real-world would involve more complex rules.
        if (repLevel >= 5) {
            evoSouls[_evoSoulId].traits["Wisdom"] = "High";
        } else if (repLevel >= 3) {
            evoSouls[_evoSoulId].traits["Wisdom"] = "Medium";
        } else {
            evoSouls[_evoSoulId].traits["Wisdom"] = "Low";
        }

        // Optionally, update metadata hash after trait change
        // For demonstration, not requiring AI oracle for reputation sync
        // evoSouls[_evoSoulId].currentMetadataHash = keccak256(abi.encodePacked(block.timestamp, _evoSoulId, repLevel)).toString();

        emit ReputationTraitsSynced(_evoSoulId);
    }

    // --- IX. Catalyst Token Interaction ---

    /**
     * @dev Sets the address of the `Catalyst` ERC20 token.
     * Callable only by the DAO Governor.
     * @param _catalystTokenAddress The address of the Catalyst token.
     */
    function setCatalystToken(address _catalystTokenAddress) public onlyGovernor {
        require(_catalystTokenAddress != address(0), "EvoSoulGenesis: Invalid Catalyst token address");
        catalystToken = ICatalystToken(_catalystTokenAddress);
    }

    /**
     * @dev Allows the DAO or other privileged entities to add `Catalyst` to the contract's pool.
     * This pool could be used for rewards, specific features, or stabilizing costs.
     * @param _amount The amount of Catalyst tokens to transfer to the contract.
     */
    function fundEvolutionPool(uint256 _amount) public nonReentrant {
        require(_amount > 0, "EvoSoulGenesis: Amount must be greater than 0");
        catalystToken.transferFrom(msg.sender, address(this), _amount);
        // Optional: emit event
    }

    // --- X. DAO Governance Functions ---
    // These functions are callable only by the `daoGovernor` and represent parameters
    // that can be adjusted via DAO proposals.

    /**
     * @dev Adjusts the `Catalyst` cost required for EvoSoul evolution.
     * Callable only by the DAO Governor.
     * @param _newCost The new cost in Catalyst tokens.
     */
    function updateEvolutionCost(uint256 _newCost) public onlyGovernor {
        require(_newCost > 0, "EvoSoulGenesis: Cost must be positive");
        evolutionCost = _newCost;
        emit EvolutionCostUpdated(_newCost);
    }

    /**
     * @dev Sets the minimum time an EvoSoul must wait between evolutions.
     * Callable only by the DAO Governor.
     * @param _newInterval The new minimum interval in seconds.
     */
    function updateMinEvolutionInterval(uint256 _newInterval) public onlyGovernor {
        minEvolutionInterval = _newInterval;
        emit MinEvolutionIntervalUpdated(_newInterval);
    }

    /**
     * @dev Changes the trusted AI Oracle address.
     * Callable only by the DAO Governor.
     * @param _newAIOracleAddress The address of the new AI Oracle contract.
     */
    function updateAIOracleAddress(address _newAIOracleAddress) public onlyGovernor {
        require(_newAIOracleAddress != address(0), "EvoSoulGenesis: Invalid AI Oracle address");
        aiOracle = IAIOracle(_newAIOracleAddress);
        emit AIOracleUpdated(_newAIOracleAddress);
    }

    /**
     * @dev Whitelists or blacklists specific trait categories that the AI oracle can generate.
     * Ensures curated content and prevents undesirable traits. Callable only by the DAO Governor.
     * @param _category The name of the trait category (e.g., "visual", "personality").
     * @param _allowed True to allow, false to disallow.
     */
    function setAllowedTraitCategory(string memory _category, bool _allowed) public onlyGovernor {
        require(bytes(_category).length > 0, "EvoSoulGenesis: Category name cannot be empty");
        allowedTraitCategories[_category] = _allowed;
        emit TraitCategoryAllowed(_category, _allowed);
    }

    /**
     * @dev Updates the base URI for the dynamic metadata server.
     * Callable only by the DAO Governor.
     * @param _newBaseURI The new base URI.
     */
    function setDynamicBaseURI(string memory _newBaseURI) public onlyGovernor {
        require(bytes(_newBaseURI).length > 0, "EvoSoulGenesis: Base URI cannot be empty");
        dynamicBaseURI = _newBaseURI;
        emit DynamicBaseURIUpdated(_newBaseURI);
    }

    /**
     * @dev Allows the DAO Governor to withdraw accumulated Catalyst fees from the contract.
     * These fees accumulate from evolution costs, AI requests, etc.
     */
    function withdrawFees() public onlyGovernor nonReentrant {
        uint256 contractBalance = catalystToken.balanceOf(address(this));
        require(contractBalance > 0, "EvoSoulGenesis: No fees to withdraw");
        catalystToken.transfer(daoGovernor, contractBalance);
        emit FeesWithdrawn(contractBalance);
    }

    // --- XI. Internal/Helper Functions ---
    // Helper function for max, since Solidity doesn't have built-in max for uint256
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
```