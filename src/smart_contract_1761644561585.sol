This smart contract, **SynthetikLifeforms**, introduces a novel concept of on-chain digital organisms (NFTs) that are dynamic, interactive, and possess a form of "digital biology." These lifeforms have a genetic code (DNA), require sustenance (feeding tokens), can evolve, mutate, breed, and even "die" if neglected. They can also engage in simple ecosystem interactions like challenges and symbiotic relationships.

The design avoids duplicating existing open-source contracts by integrating these pseudo-biological mechanics directly into the NFT's lifecycle, going beyond static metadata or simple trait generation to offer a living, evolving digital asset.

---

## SynthetikLifeforms: Outline and Function Summary

**Concept:** A protocol for managing dynamic, evolving digital organisms as NFTs. These lifeforms have a genetic code, require resources to survive and grow, can evolve, mutate, breed, and interact within a simple on-chain ecosystem.

**Core Principles:**
*   **On-Chain Genetics:** Lifeforms possess a `DNA` (uint256) which determines their `traits` and `vitality`.
*   **Resource Management:** Lifeforms require `feeding` with tokens to maintain `energy` and avoid `dormancy` or `death`.
*   **Dynamic Lifecycle:** Lifeforms can `evolve`, `mutate`, `breed`, and change `status` (Alive, Dormant, Deceased).
*   **Ecosystem Interactions:** Lifeforms can `challenge` each other or form `symbiotic relationships`.
*   **ERC721 Standard:** Adheres to the ERC721 standard for NFT ownership and transferability.
*   **Pausable & Ownable:** Standard security and admin controls.

---

### Function Summary:

**I. Core Lifeform Management (ERC721 & Status)**
1.  `constructor()`: Initializes the contract with name, symbol, and sets initial admin configurations.
2.  `createLifeform(string calldata _name)`: Mints a new genesis lifeform (ERC721) with an initial random DNA. Requires a creation fee.
3.  `getLifeformDetails(uint256 _tokenId)`: Retrieves all detailed information about a specific lifeform.
4.  `getLifeformDNA(uint256 _tokenId)`: Returns only the raw DNA sequence of a lifeform.
5.  `getLifeformStatus(uint256 _tokenId)`: Returns the current vitality status (Alive, Dormant, Deceased) of a lifeform.
6.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function.
7.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 safe transfer function.
8.  `approve(address to, uint256 tokenId)`: Standard ERC721 approval function.
9.  `getApproved(uint256 tokenId)`: Standard ERC721 function to get approved address.
10. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function for operator approval.
11. `isApprovedForAll(address owner, address operator)`: Standard ERC721 function to check operator approval.
12. `burnLifeform(uint256 _tokenId)`: Allows the owner to permanently destroy a lifeform, setting its status to Deceased.

**II. Lifeform Biology & Evolution**
13. `feedLifeform(uint256 _tokenId, uint256 _amount)`: Feeds the lifeform with `feedingToken`, increasing its energy level and potentially reviving it from dormancy.
14. `attemptEvolution(uint256 _tokenId)`: Triggers an evolution attempt. Requires sufficient energy and time since last evolution. Can change DNA, traits, and generation.
15. `mutateLifeform(uint256 _tokenId, uint256 _mutationFactor)`: Owner can pay to induce a random mutation in the lifeform's DNA, costing energy.
16. `breedLifeforms(uint256 _parentId1, uint256 _parentId2, string calldata _childName)`: Creates a new lifeform by combining DNA from two parent lifeforms. Requires both parents to be owned by or approved to the caller, and consumes their energy.
17. `getDerivedTraits(uint256 _dna)`: Pure function to calculate and return the human-readable traits from a given DNA sequence.
18. `checkLifeformVitality(uint256 _tokenId)`: Internal helper function to update a lifeform's status based on energy and time, potentially leading to dormancy or death.

**III. Ecosystem & Interaction Functions**
19. `challengeLifeform(uint256 _challengerId, uint256 _opponentId)`: Initiates a contest between two lifeforms. Outcome depends on vitality and DNA, affecting energy levels.
20. `declareSymbiosis(uint256 _lifeformId1, uint256 _lifeformId2)`: Establishes a symbiotic link between two lifeforms. Requires consent from both owners and offers mutual benefits (e.g., shared energy, vitality boost).
21. `breakSymbiosis(uint256 _lifeformId1, uint256 _lifeformId2)`: Terminates an existing symbiotic relationship.

**IV. Protocol Administration & Metrics**
22. `setFeedingToken(address _tokenAddress)`: Admin function to change the ERC20 token used for feeding lifeforms.
23. `setEvolutionCost(uint256 _cost)`: Admin function to adjust the token cost required for a lifeform to attempt evolution.
24. `setBreedingFee(uint256 _fee)`: Admin function to adjust the token fee for breeding new lifeforms.
25. `setCreationFee(uint256 _fee)`: Admin function to adjust the token fee for creating genesis lifeforms.
26. `withdrawProtocolFees(address _tokenAddress, address _to, uint256 _amount)`: Admin function to withdraw accumulated protocol fees (ERC20 or native ETH) to a specified address.
27. `getEcosystemMetrics()`: Returns global statistics about the lifeform population (total alive, total deceased, average generation, etc.).
28. `pause()`: Admin function to pause core ecosystem actions (feeding, breeding, evolution, challenges).
29. `unpause()`: Admin function to unpause core ecosystem actions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors
error SynthetikLifeforms__NotLifeformOwnerOrApproved();
error SynthetikLifeforms__LifeformDoesNotExist();
error SynthetikLifeforms__LifeformNotAlive();
error SynthetikLifeforms__InsufficientEnergy();
error SynthetikLifeforms__CannotEvolveYet();
error SynthetikLifeforms__BreedingNotAllowed();
error SynthetikLifeforms__NotEnoughFeedingTokens();
error SynthetikLifeforms__SelfBreedingForbidden();
error SynthetikLifeforms__ParentsNotReadyForBreeding();
error SynthetikLifeforms__CannotChallengeSelf();
error SynthetikLifeforms__SymbiosisAlreadyExists();
error SynthetikLifeforms__SymbiosisDoesNotExist();
error SynthetikLifeforms__SymbiosisRequiresConsent();
error SynthetikLifeforms__NoFeesToWithdraw();
error SynthetikLifeforms__InvalidAmount();

contract SynthetikLifeforms is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum LifeformStatus { Alive, Dormant, Deceased }

    // --- Structs ---
    struct Lifeform {
        address owner;
        uint256 generation;
        uint256 dna; // Represents the genetic code
        uint64 bornTimestamp; // Block timestamp when created
        uint64 lastFedTimestamp; // Block timestamp when last fed
        uint64 lastEvolutionTimestamp; // Block timestamp when last evolved
        uint256 energyLevel; // Current energy of the lifeform
        uint256 vitalityScore; // Derived from DNA and energy, influences interactions
        LifeformStatus status;
        string name;
    }

    struct SymbioticRelationship {
        uint256 lifeformId1;
        uint256 lifeformId2;
        uint64 establishedTimestamp;
        bool active;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => Lifeform) public lifeforms;
    mapping(uint256 => mapping(uint256 => SymbioticRelationship)) public symbioticRelationships;

    address public feedingToken; // ERC20 token used for feeding lifeforms
    uint256 public creationFee; // Cost to create a genesis lifeform
    uint256 public evolutionCost; // Energy/token cost for evolution attempt
    uint256 public breedingFee; // Token cost for breeding
    uint256 public baseEnergyGainPerFeed; // Amount of energy gained per feed
    uint256 public energyDecayRate; // Rate at which energy decays over time (e.g., per hour)
    uint256 public dormancyThreshold; // Energy level below which a lifeform becomes dormant
    uint256 public dormancyPeriod; // Time (seconds) before a dormant lifeform becomes deceased
    uint256 public evolutionCooldown; // Time (seconds) before a lifeform can evolve again

    // Protocol Fee Management
    mapping(address => uint256) public protocolFees; // Maps token address to accumulated fees

    // --- Events ---
    event LifeformCreated(uint256 indexed tokenId, address indexed owner, uint256 dna, string name);
    event LifeformFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergy);
    event LifeformEvolved(uint256 indexed tokenId, uint256 oldDNA, uint256 newDNA, uint256 newGeneration);
    event LifeformMutated(uint256 indexed tokenId, uint256 oldDNA, uint256 newDNA);
    event LifeformBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, uint256 childDNA);
    event LifeformStatusChanged(uint256 indexed tokenId, LifeformStatus oldStatus, LifeformStatus newStatus);
    event LifeformChallenged(uint256 indexed challengerId, uint256 indexed opponentId, bool challengerWon);
    event SymbiosisDeclared(uint256 indexed lifeformId1, uint256 indexed lifeformId2);
    event SymbiosisBroken(uint256 indexed lifeformId1, uint256 indexed lifeformId2);
    event ProtocolFeeWithdrawn(address indexed tokenAddress, address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialFeedingToken,
        uint256 _creationFee,
        uint256 _evolutionCost,
        uint256 _breedingFee
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_initialFeedingToken != address(0), "Invalid feeding token address");
        feedingToken = _initialFeedingToken;
        creationFee = _creationFee;
        evolutionCost = _evolutionCost;
        breedingFee = _breedingFee;
        baseEnergyGainPerFeed = 100; // Example value
        energyDecayRate = 1; // Example: 1 energy unit per hour
        dormancyThreshold = 10; // Below this energy, lifeform becomes dormant
        dormancyPeriod = 7 days; // 7 days in dormant state before death
        evolutionCooldown = 30 days; // Can evolve once every 30 days
    }

    // --- Modifiers ---
    modifier onlyLifeformOwner(uint256 _tokenId) {
        if (_exists(_tokenId) && _ownerOf(_tokenId) != msg.sender) {
            revert SynthetikLifeforms__NotLifeformOwnerOrApproved();
        }
        _;
    }

    modifier onlyLifeformOwnerOrApproved(uint256 _tokenId) {
        if (_exists(_tokenId) && _isApprovedOrOwner(msg.sender, _tokenId) == false) {
            revert SynthetikLifeforms__NotLifeformOwnerOrApproved();
        }
        _;
    }

    modifier onlyAliveLifeform(uint256 _tokenId) {
        _checkLifeformExists(_tokenId);
        _checkLifeformVitality(_tokenId); // Update status before checking
        if (lifeforms[_tokenId].status != LifeformStatus.Alive) {
            revert SynthetikLifeforms__LifeformNotAlive();
        }
        _;
    }

    // --- ERC721 Overrides (to integrate custom logic) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure lifeform exists
        _checkLifeformExists(tokenId);
        // Update ownership in our custom struct
        lifeforms[tokenId].owner = to;
    }

    function _approve(address to, uint256 tokenId) internal override {
        _checkLifeformExists(tokenId);
        super._approve(to, tokenId);
    }

    // --- Internal Helpers ---
    function _checkLifeformExists(uint256 _tokenId) internal view {
        if (!_exists(_tokenId)) {
            revert SynthetikLifeforms__LifeformDoesNotExist();
        }
    }

    function _generateInitialDNA() internal pure returns (uint256) {
        // Simple initial DNA generation: pseudo-random based on block data and sender
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number)));
        return seed % (2**256 - 1); // Ensure it's within uint256 range
    }

    function _calculateVitality(uint256 _dna, uint256 _energy) internal pure returns (uint256) {
        // A simple example: vitality is a function of certain DNA segments and energy.
        // This makes DNA and energy directly impact lifeform performance.
        uint256 dnaComponent = (_dna % 100) + ((_dna >> 64) % 50); // Example, extract parts of DNA
        return dnaComponent + (_energy / 100); // Add energy influence
    }

    function _calculateEnergyDecay(uint256 _lastTimestamp, uint256 _currentTimestamp) internal view returns (uint256) {
        if (_currentTimestamp <= _lastTimestamp) {
            return 0;
        }
        uint256 timeElapsedHours = (_currentTimestamp - _lastTimestamp) / 1 hours;
        return timeElapsedHours * energyDecayRate;
    }

    /**
     * @dev Updates a lifeform's status based on energy levels and time elapsed.
     * This function is crucial for the "life" aspect of the lifeforms.
     */
    function _checkLifeformVitality(uint256 _tokenId) internal {
        Lifeform storage lf = lifeforms[_tokenId];
        if (lf.status == LifeformStatus.Deceased) {
            return; // Already deceased, no need to update
        }

        uint256 currentEnergy = lf.energyLevel;
        uint256 decayAmount = _calculateEnergyDecay(lf.lastFedTimestamp, block.timestamp);

        if (currentEnergy > decayAmount) {
            lf.energyLevel = currentEnergy - decayAmount;
        } else {
            lf.energyLevel = 0;
        }
        lf.lastFedTimestamp = uint64(block.timestamp);

        LifeformStatus oldStatus = lf.status;
        LifeformStatus newStatus = oldStatus;

        if (lf.energyLevel <= dormancyThreshold && lf.status == LifeformStatus.Alive) {
            newStatus = LifeformStatus.Dormant;
            // Record when dormancy started if it just changed
            if (oldStatus != LifeformStatus.Dormant) {
                // We use lastFedTimestamp as a proxy for dormancy start here for simplicity,
                // but a dedicated `dormancyStartTimestamp` could be added for more precision.
                // For now, if energy hits 0, it means it just entered dormancy.
            }
        } else if (lf.energyLevel > dormancyThreshold && lf.status == LifeformStatus.Dormant) {
            newStatus = LifeformStatus.Alive; // Revived from dormancy
        } else if (lf.status == LifeformStatus.Dormant && (block.timestamp - lf.lastFedTimestamp) >= dormancyPeriod) {
            newStatus = LifeformStatus.Deceased; // Died from prolonged dormancy
        }

        if (newStatus != oldStatus) {
            lf.status = newStatus;
            emit LifeformStatusChanged(_tokenId, oldStatus, newStatus);
        }

        lf.vitalityScore = _calculateVitality(lf.dna, lf.energyLevel);
    }

    // --- I. Core Lifeform Management (ERC721 & Status) ---

    /**
     * @dev Mints a new genesis lifeform (ERC721) with an initial random DNA.
     * Requires a creation fee.
     * @param _name The name of the new lifeform.
     */
    function createLifeform(string calldata _name) external payable whenNotPaused returns (uint256) {
        require(msg.value >= creationFee, "Insufficient creation fee");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        uint256 initialDNA = _generateInitialDNA();

        Lifeform storage newLifeform = lifeforms[newTokenId];
        newLifeform.owner = msg.sender;
        newLifeform.generation = 1;
        newLifeform.dna = initialDNA;
        newLifeform.bornTimestamp = uint64(block.timestamp);
        newLifeform.lastFedTimestamp = uint64(block.timestamp);
        newLifeform.lastEvolutionTimestamp = uint64(block.timestamp); // Can evolve immediately
        newLifeform.energyLevel = baseEnergyGainPerFeed * 5; // Start with some initial energy
        newLifeform.vitalityScore = _calculateVitality(initialDNA, newLifeform.energyLevel);
        newLifeform.status = LifeformStatus.Alive;
        newLifeform.name = _name;

        _mint(msg.sender, newTokenId);

        // Record protocol fees
        if (creationFee > 0) {
            protocolFees[address(0)] += creationFee; // Native ETH fees
        }

        emit LifeformCreated(newTokenId, msg.sender, initialDNA, _name);
        return newTokenId;
    }

    /**
     * @dev Retrieves all detailed information about a specific lifeform.
     * @param _tokenId The ID of the lifeform.
     * @return A tuple containing all lifeform details.
     */
    function getLifeformDetails(uint256 _tokenId) external view returns (Lifeform memory) {
        _checkLifeformExists(_tokenId);
        // Note: Vitality is updated on interactions. This view function provides current state.
        return lifeforms[_tokenId];
    }

    /**
     * @dev Returns only the raw DNA sequence of a lifeform.
     * @param _tokenId The ID of the lifeform.
     * @return The DNA sequence (uint256).
     */
    function getLifeformDNA(uint256 _tokenId) external view returns (uint256) {
        _checkLifeformExists(_tokenId);
        return lifeforms[_tokenId].dna;
    }

    /**
     * @dev Returns the current vitality status (Alive, Dormant, Deceased) of a lifeform.
     * @param _tokenId The ID of the lifeform.
     * @return The LifeformStatus enum value.
     */
    function getLifeformStatus(uint256 _tokenId) external view returns (LifeformStatus) {
        _checkLifeformExists(_tokenId);
        // Need to simulate vitality check without modifying state
        Lifeform storage lf = lifeforms[_tokenId];
        if (lf.status == LifeformStatus.Deceased) return LifeformStatus.Deceased;

        uint256 currentEnergy = lf.energyLevel;
        uint256 decayAmount = _calculateEnergyDecay(lf.lastFedTimestamp, block.timestamp);

        uint256 effectiveEnergy = currentEnergy > decayAmount ? currentEnergy - decayAmount : 0;

        if (effectiveEnergy <= dormancyThreshold && lf.status == LifeformStatus.Alive) {
            return LifeformStatus.Dormant;
        } else if (effectiveEnergy > dormancyThreshold && lf.status == LifeformStatus.Dormant) {
            return LifeformStatus.Alive;
        } else if (lf.status == LifeformStatus.Dormant && (block.timestamp - lf.lastFedTimestamp) >= dormancyPeriod) {
            return LifeformStatus.Deceased;
        }
        return lf.status;
    }

    /**
     * @dev Allows the owner to permanently destroy a lifeform.
     * @param _tokenId The ID of the lifeform to burn.
     */
    function burnLifeform(uint256 _tokenId) external onlyLifeformOwner(_tokenId) {
        _checkLifeformExists(_tokenId);
        Lifeform storage lf = lifeforms[_tokenId];
        LifeformStatus oldStatus = lf.status;
        lf.status = LifeformStatus.Deceased;
        _burn(_tokenId); // ERC721 burn
        emit LifeformStatusChanged(_tokenId, oldStatus, LifeformStatus.Deceased);
    }

    // --- II. Lifeform Biology & Evolution ---

    /**
     * @dev Feeds the lifeform with `feedingToken`, increasing its energy level and potentially reviving it.
     * @param _tokenId The ID of the lifeform to feed.
     * @param _amount The amount of feeding token to use.
     */
    function feedLifeform(uint256 _tokenId, uint256 _amount) external whenNotPaused onlyLifeformOwnerOrApproved(_tokenId) {
        _checkLifeformExists(_tokenId);
        _checkLifeformVitality(_tokenId); // Update status first
        if (_amount == 0) revert SynthetikLifeforms__InvalidAmount();

        // Transfer feeding tokens from feeder to contract
        IERC20(feedingToken).transferFrom(msg.sender, address(this), _amount);

        Lifeform storage lf = lifeforms[_tokenId];
        uint256 energyGained = baseEnergyGainPerFeed * _amount; // Example: 1 token = baseEnergyGain
        lf.energyLevel += energyGained;
        lf.lastFedTimestamp = uint64(block.timestamp);

        // Automatically revive if enough energy
        if (lf.energyLevel > dormancyThreshold && lf.status == LifeformStatus.Dormant) {
            LifeformStatus oldStatus = lf.status;
            lf.status = LifeformStatus.Alive;
            emit LifeformStatusChanged(_tokenId, oldStatus, LifeformStatus.Alive);
        }

        lf.vitalityScore = _calculateVitality(lf.dna, lf.energyLevel);
        protocolFees[feedingToken] += _amount; // Fees for the protocol
        emit LifeformFed(_tokenId, msg.sender, _amount, lf.energyLevel);
    }

    /**
     * @dev Triggers an evolution attempt. Requires sufficient energy and time since last evolution.
     * Can change DNA, traits, and generation.
     * @param _tokenId The ID of the lifeform to evolve.
     */
    function attemptEvolution(uint256 _tokenId) external whenNotPaused onlyAliveLifeform(_tokenId) {
        Lifeform storage lf = lifeforms[_tokenId];
        require(lf.energyLevel >= evolutionCost, SynthetikLifeforms__InsufficientEnergy());
        require(block.timestamp >= lf.lastEvolutionTimestamp + evolutionCooldown, SynthetikLifeforms__CannotEvolveYet());

        lf.energyLevel -= evolutionCost;
        lf.lastEvolutionTimestamp = uint64(block.timestamp);

        uint256 oldDNA = lf.dna;
        // Simplified evolution: a slight random alteration to DNA
        uint256 evolutionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, lf.dna, msg.sender, lf.generation)));
        // Example: flip a random bit or add a small offset
        uint256 newDNA = oldDNA ^ (1 << (evolutionSeed % 256));

        lf.dna = newDNA;
        lf.generation++;
        lf.vitalityScore = _calculateVitality(newDNA, lf.energyLevel);

        protocolFees[feedingToken] += evolutionCost; // Fees for the protocol
        emit LifeformEvolved(_tokenId, oldDNA, newDNA, lf.generation);
    }

    /**
     * @dev Owner can pay to induce a random mutation in the lifeform's DNA, costing energy.
     * @param _tokenId The ID of the lifeform to mutate.
     * @param _mutationFactor A factor influencing the strength/randomness of the mutation.
     */
    function mutateLifeform(uint256 _tokenId, uint256 _mutationFactor) external whenNotPaused onlyAliveLifeform(_tokenId) {
        Lifeform storage lf = lifeforms[_tokenId];
        uint256 mutationCost = (evolutionCost / 2) * _mutationFactor / 100; // Example: half evolution cost, scaled by factor
        require(lf.energyLevel >= mutationCost, SynthetikLifeforms__InsufficientEnergy());

        lf.energyLevel -= mutationCost;

        uint256 oldDNA = lf.dna;
        uint256 mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, lf.dna, msg.sender, _mutationFactor)));
        uint256 newDNA = oldDNA ^ (mutationSeed % (1 << (_mutationFactor % 256))); // Mutate a random range of bits

        lf.dna = newDNA;
        lf.vitalityScore = _calculateVitality(newDNA, lf.energyLevel);

        protocolFees[feedingToken] += mutationCost; // Fees for the protocol
        emit LifeformMutated(_tokenId, oldDNA, newDNA);
    }

    /**
     * @dev Creates a new lifeform by combining DNA from two parent lifeforms.
     * Requires both parents to be owned by or approved to the caller, and consumes their energy.
     * @param _parentId1 The ID of the first parent lifeform.
     * @param _parentId2 The ID of the second parent lifeform.
     * @param _childName The name for the new child lifeform.
     */
    function breedLifeforms(uint256 _parentId1, uint256 _parentId2, string calldata _childName) external payable whenNotPaused {
        require(msg.value >= breedingFee, SynthetikLifeforms__NotEnoughFeedingTokens());
        require(_parentId1 != _parentId2, SynthetikLifeforms__SelfBreedingForbidden());

        // Check if both parents exist and are owned/approved by msg.sender
        _checkLifeformExists(_parentId1);
        _checkLifeformExists(_parentId2);
        require(_isApprovedOrOwner(msg.sender, _parentId1), SynthetikLifeforms__NotLifeformOwnerOrApproved());
        require(_isApprovedOrOwner(msg.sender, _parentId2), SynthetikLifeforms__NotLifeformOwnerOrApproved());

        _checkLifeformVitality(_parentId1); // Update status
        _checkLifeformVitality(_parentId2); // Update status
        require(lifeforms[_parentId1].status == LifeformStatus.Alive, SynthetikLifeforms__ParentsNotReadyForBreeding());
        require(lifeforms[_parentId2].status == LifeformStatus.Alive, SynthetikLifeforms__ParentsNotReadyForBreeding());
        require(lifeforms[_parentId1].energyLevel >= evolutionCost, SynthetikLifeforms__ParentsNotReadyForBreeding());
        require(lifeforms[_parentId2].energyLevel >= evolutionCost, SynthetikLifeforms__ParentsNotReadyForBreeding());

        // Consume energy from parents
        lifeforms[_parentId1].energyLevel -= evolutionCost / 2;
        lifeforms[_parentId2].energyLevel -= evolutionCost / 2;

        // Simple DNA combining (e.g., XOR or alternating bits)
        uint256 dna1 = lifeforms[_parentId1].dna;
        uint256 dna2 = lifeforms[_parentId2].dna;
        uint256 childDNA = (dna1 & 0xFFFF0000FFFF0000) | (dna2 & 0x0000FFFF0000FFFF); // Example: combine halves

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        Lifeform storage newLifeform = lifeforms[childTokenId];
        newLifeform.owner = msg.sender;
        newLifeform.generation = max(lifeforms[_parentId1].generation, lifeforms[_parentId2].generation) + 1;
        newLifeform.dna = childDNA;
        newLifeform.bornTimestamp = uint64(block.timestamp);
        newLifeform.lastFedTimestamp = uint64(block.timestamp);
        newLifeform.lastEvolutionTimestamp = uint64(block.timestamp); // Can evolve immediately
        newLifeform.energyLevel = baseEnergyGainPerFeed * 3; // Start with less energy than genesis
        newLifeform.vitalityScore = _calculateVitality(childDNA, newLifeform.energyLevel);
        newLifeform.status = LifeformStatus.Alive;
        newLifeform.name = _childName;

        _mint(msg.sender, childTokenId);

        if (breedingFee > 0) {
            protocolFees[address(0)] += breedingFee; // Native ETH fees
        }

        emit LifeformBred(_parentId1, _parentId2, childTokenId, childDNA);
    }

    /**
     * @dev Pure function to calculate and return the human-readable traits from a given DNA sequence.
     * This demonstrates how DNA can map to "phenotypes".
     * @param _dna The DNA sequence (uint256).
     * @return An array of strings representing traits.
     */
    function getDerivedTraits(uint256 _dna) external pure returns (string[] memory) {
        string[] memory traits = new string[](3); // Example: 3 traits

        // Example trait derivation from DNA segments
        if ((_dna % 100) < 50) {
            traits[0] = "Agile";
        } else {
            traits[0] = "Strong";
        }

        if ((_dna >> 128) % 2 == 0) {
            traits[1] = "Resilient";
        } else {
            traits[1] = "Fragile";
        }

        if ((_dna & 0x1) == 0x1) { // Check the least significant bit
            traits[2] = "Nocturnal";
        } else {
            traits[2] = "Diurnal";
        }

        return traits;
    }

    // --- III. Ecosystem & Interaction Functions ---

    /**
     * @dev Initiates a contest between two lifeforms. Outcome depends on vitality and DNA,
     * affecting energy levels. Can only be called by owner/approved of challenger.
     * @param _challengerId The ID of the lifeform initiating the challenge.
     * @param _opponentId The ID of the lifeform being challenged.
     */
    function challengeLifeform(uint256 _challengerId, uint256 _opponentId) external whenNotPaused onlyAliveLifeform(_challengerId) {
        require(_challengerId != _opponentId, SynthetikLifeforms__CannotChallengeSelf());
        _checkLifeformExists(_opponentId);
        require(_isApprovedOrOwner(msg.sender, _challengerId), SynthetikLifeforms__NotLifeformOwnerOrApproved());
        _checkLifeformVitality(_opponentId); // Update opponent's status
        require(lifeforms[_opponentId].status == LifeformStatus.Alive, SynthetikLifeforms__LifeformNotAlive());

        Lifeform storage challenger = lifeforms[_challengerId];
        Lifeform storage opponent = lifeforms[_opponentId];

        // Ensure both have enough energy to participate
        uint256 challengeCost = baseEnergyGainPerFeed; // Example cost
        require(challenger.energyLevel >= challengeCost, SynthetikLifeforms__InsufficientEnergy());
        require(opponent.energyLevel >= challengeCost, SynthetikLifeforms__InsufficientEnergy());

        challenger.energyLevel -= challengeCost;
        opponent.energyLevel -= challengeCost;

        // Determine winner based on vitality score, with some randomness
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, challenger.dna, opponent.dna)));
        bool challengerWins = (challenger.vitalityScore * (randomFactor % 100 + 100)) > (opponent.vitalityScore * ((randomFactor >> 64) % 100 + 100));

        if (challengerWins) {
            challenger.energyLevel += challengeCost * 2; // Winner gains energy
        } else {
            opponent.energyLevel += challengeCost * 2; // Opponent gains energy
        }

        // Re-calculate vitality after energy change
        challenger.vitalityScore = _calculateVitality(challenger.dna, challenger.energyLevel);
        opponent.vitalityScore = _calculateVitality(opponent.dna, opponent.energyLevel);

        emit LifeformChallenged(_challengerId, _opponentId, challengerWins);
    }

    /**
     * @dev Establishes a symbiotic link between two lifeforms. Requires consent from both owners
     * and offers mutual benefits (e.g., shared energy, vitality boost).
     * The caller must be an owner/approved of both lifeforms to declare.
     * @param _lifeformId1 The ID of the first lifeform.
     * @param _lifeformId2 The ID of the second lifeform.
     */
    function declareSymbiosis(uint256 _lifeformId1, uint256 _lifeformId2) external whenNotPaused {
        require(_lifeformId1 != _lifeformId2, "Cannot declare symbiosis with self");
        _checkLifeformExists(_lifeformId1);
        _checkLifeformExists(_lifeformId2);
        require(_isApprovedOrOwner(msg.sender, _lifeformId1), SynthetikLifeforms__SymbiosisRequiresConsent());
        require(_isApprovedOrOwner(msg.sender, _lifeformId2), SynthetikLifeforms__SymbiosisRequiresConsent());

        // Ensure no active symbiosis already exists between them (order agnostic)
        if (symbioticRelationships[_lifeformId1][_lifeformId2].active || symbioticRelationships[_lifeformId2][_lifeformId1].active) {
            revert SynthetikLifeforms__SymbiosisAlreadyExists();
        }

        // Create new symbiotic relationship
        symbioticRelationships[_lifeformId1][_lifeformId2] = SymbioticRelationship({
            lifeformId1: _lifeformId1,
            lifeformId2: _lifeformId2,
            establishedTimestamp: uint64(block.timestamp),
            active: true
        });

        // Apply immediate benefits (e.g., energy boost) or just flag for ongoing effects
        lifeforms[_lifeformId1].energyLevel += baseEnergyGainPerFeed;
        lifeforms[_lifeformId2].energyLevel += baseEnergyGainPerFeed;

        lifeforms[_lifeformId1].vitalityScore = _calculateVitality(lifeforms[_lifeformId1].dna, lifeforms[_lifeformId1].energyLevel);
        lifeforms[_lifeformId2].vitalityScore = _calculateVitality(lifeforms[_lifeformId2].dna, lifeforms[_lifeformId2].energyLevel);

        emit SymbiosisDeclared(_lifeformId1, _lifeformId2);
    }

    /**
     * @dev Terminates an existing symbiotic relationship.
     * Caller must be owner/approved of at least one of the lifeforms.
     * @param _lifeformId1 The ID of the first lifeform in the relationship.
     * @param _lifeformId2 The ID of the second lifeform in the relationship.
     */
    function breakSymbiosis(uint256 _lifeformId1, uint256 _lifeformId2) external whenNotPaused {
        require(_lifeformId1 != _lifeformId2, "Invalid symbiosis termination");
        _checkLifeformExists(_lifeformId1);
        _checkLifeformExists(_lifeformId2);
        require(
            _isApprovedOrOwner(msg.sender, _lifeformId1) || _isApprovedOrOwner(msg.sender, _lifeformId2),
            SynthetikLifeforms__NotLifeformOwnerOrApproved()
        );

        SymbioticRelationship storage relationship = symbioticRelationships[_lifeformId1][_lifeformId2];
        if (!relationship.active) {
            relationship = symbioticRelationships[_lifeformId2][_lifeformId1]; // Check reverse order
            if (!relationship.active) {
                revert SynthetikLifeforms__SymbiosisDoesNotExist();
            }
        }

        relationship.active = false;
        // Optionally, apply penalties for breaking symbiosis (e.g., energy drain)
        lifeforms[_lifeformId1].energyLevel -= baseEnergyGainPerFeed;
        lifeforms[_lifeformId2].energyLevel -= baseEnergyGainPerFeed;

        lifeforms[_lifeformId1].vitalityScore = _calculateVitality(lifeforms[_lifeformId1].dna, lifeforms[_lifeformId1].energyLevel);
        lifeforms[_lifeformId2].vitalityScore = _calculateVitality(lifeforms[_lifeformId2].dna, lifeforms[_lifeformId2].energyLevel);

        emit SymbiosisBroken(_lifeformId1, _lifeformId2);
    }


    // --- IV. Protocol Administration & Metrics ---

    /**
     * @dev Admin function to change the ERC20 token used for feeding lifeforms.
     * @param _tokenAddress The address of the new feeding token.
     */
    function setFeedingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        feedingToken = _tokenAddress;
    }

    /**
     * @dev Admin function to adjust the token cost required for a lifeform to attempt evolution.
     * @param _cost The new evolution cost.
     */
    function setEvolutionCost(uint256 _cost) external onlyOwner {
        evolutionCost = _cost;
    }

    /**
     * @dev Admin function to adjust the token fee for breeding new lifeforms.
     * @param _fee The new breeding fee.
     */
    function setBreedingFee(uint256 _fee) external onlyOwner {
        breedingFee = _fee;
    }

    /**
     * @dev Admin function to adjust the token fee for creating genesis lifeforms.
     * @param _fee The new creation fee.
     */
    function setCreationFee(uint256 _fee) external onlyOwner {
        creationFee = _fee;
    }

    /**
     * @dev Admin function to withdraw accumulated protocol fees (ERC20 or native ETH) to a specified address.
     * @param _tokenAddress The address of the token to withdraw (address(0) for ETH).
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, SynthetikLifeforms__NoFeesToWithdraw());
        require(protocolFees[_tokenAddress] >= _amount, SynthetikLifeforms__NoFeesToWithdraw());

        protocolFees[_tokenAddress] -= _amount;

        if (_tokenAddress == address(0)) {
            (bool success,) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_tokenAddress).transfer(_to, _amount);
        }

        emit ProtocolFeeWithdrawn(_tokenAddress, _to, _amount);
    }

    /**
     * @dev Returns global statistics about the lifeform population.
     * @return totalLifeforms Total number of lifeforms ever created.
     * @return aliveLifeforms Count of currently alive lifeforms.
     * @return dormantLifeforms Count of currently dormant lifeforms.
     * @return deceasedLifeforms Count of currently deceased lifeforms.
     * @return averageGeneration Average generation of alive lifeforms.
     */
    function getEcosystemMetrics() external view returns (uint256 totalLifeforms, uint256 aliveLifeforms, uint256 dormantLifeforms, uint256 deceasedLifeforms, uint256 averageGeneration) {
        totalLifeforms = _tokenIdCounter.current();
        uint256 totalGenerations = 0;
        uint256 aliveCount = 0;

        for (uint256 i = 1; i <= totalLifeforms; i++) {
            LifeformStatus currentStatus = getLifeformStatus(i); // Use view function to get up-to-date status
            if (currentStatus == LifeformStatus.Alive) {
                aliveLifeforms++;
                totalGenerations += lifeforms[i].generation;
            } else if (currentStatus == LifeformStatus.Dormant) {
                dormantLifeforms++;
            } else if (currentStatus == LifeformStatus.Deceased) {
                deceasedLifeforms++;
            }
        }

        if (aliveLifeforms > 0) {
            averageGeneration = totalGenerations / aliveLifeforms;
        } else {
            averageGeneration = 0;
        }
    }

    /**
     * @dev Admin function to pause core ecosystem actions.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Admin function to unpause core ecosystem actions.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Utility Functions ---

    // A simple max function for breeding logic
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
```