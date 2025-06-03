Okay, this is a fun challenge! We'll create a contract called `CryptoEvolution` that manages unique digital creatures (NFTs) that can evolve, feed, mutate, and interact using a companion fungible token (`EvolutionJuice`). It incorporates concepts like time-based decay, resource management, different evolution stages, and simulated (though non-secure) randomness for mutations and exploration yields.

We will aim for a structure that doesn't directly copy existing popular contracts but implements standard interfaces (like ERC721 and ERC20) from scratch to demonstrate understanding, while adding novel interaction logic.

**Disclaimer:** This contract is designed for complexity and demonstration of concepts.
*   The pseudo-randomness implemented using block data is *not* secure and should not be used for high-value applications where prediction is critical. A real application would use a dedicated VRF oracle (like Chainlink VRF).
*   Error handling and gas optimization are kept simpler for readability; a production contract would require more rigorous attention to these.

---

**Contract Outline & Function Summary**

**Contract:** `CryptoEvolution`

**Core Concepts:**
1.  **Creature NFTs (ERC721):** Unique digital entities with genes, evolution stage, energy, and experience.
2.  **EvolutionJuice (ERC20):** A fungible token used as a resource for feeding, evolving, mutating, and gene enhancement.
3.  **Evolution Stages:** Pre-defined stages with increasing requirements for evolution and potentially different traits/abilities.
4.  **Time-Based Decay:** Creatures lose energy over time if not fed.
5.  **Gene System:** Creatures have a fixed number of genes influencing attributes. Genes can mutate or be enhanced.
6.  **Interactions:** Feeding, Evolution, Breeding, Exploration, Mutation, Gene Enhancement.

**ERC721 Standard Functions (Implemented Manually):**
1.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
3.  `approve(address to, uint256 tokenId)`: Approves an address to spend a specific NFT.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for a specific NFT.
5.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator to manage all owner's NFTs.
6.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers NFT, checks approvals.
8.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with receiver hook.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer without data.

**ERC20 Standard Functions (EvolutionJuice, Implemented Manually):**
10. `totalSupplyJuice()`: Returns total supply of EvolutionJuice.
11. `balanceOfJuice(address owner)`: Returns EvolutionJuice balance of an address.
12. `transferJuice(address to, uint256 amount)`: Transfers EvolutionJuice.
13. `allowanceJuice(address owner, address spender)`: Returns allowance for a spender.
14. `approveJuice(address spender, uint256 amount)`: Sets allowance for a spender.
15. `transferFromJuice(address from, address to, uint256 amount)`: Transfers EvolutionJuice using allowance.

**Creature Lifecycle & Interaction Functions:**
16. `mintInitialCreature()`: Mints a new creature NFT for the caller (with initial genes and stage 0). Requires a mint cost (e.g., ETH/Matic).
17. `feedCreature(uint256 tokenId, uint256 juiceAmount)`: Feeds a creature using EvolutionJuice to restore energy. Applies time-based decay first.
18. `triggerEvolution(uint256 tokenId)`: Attempts to evolve a creature to the next stage if requirements (XP, Energy, Juice) are met.
19. `breedCreatures(uint256 parent1TokenId, uint256 parent2TokenId)`: Breeds two creatures owned by the caller to produce a new offspring NFT, mixing genes. Requires resources.
20. `sendOnExploration(uint256 tokenId, uint256 durationInMinutes)`: Sends a creature on an exploration task for a set duration. Creature is unavailable during this time.
21. `claimExplorationYield(uint256 tokenId)`: Claims rewards (Juice, XP) after a creature returns from exploration.
22. `triggerMutation(uint256 tokenId)`: Attempts to randomly mutate one of the creature's genes. Requires Juice. Can be positive or negative.
23. `applyGeneEnhancement(uint256 tokenId, uint8 geneIndex)`: Attempts to specifically enhance a chosen gene. Requires higher Juice cost and has a chance of success/failure.

**Query & Status Functions:**
24. `getCreatureDetails(uint256 tokenId)`: Returns all core details of a creature struct.
25. `getCreatureGenes(uint256 tokenId)`: Returns the gene array for a creature.
26. `getCreatureStatus(uint256 tokenId)`: Returns current energy, experience, stage, and last fed timestamp.
27. `getExplorationStatus(uint256 tokenId)`: Returns exploration timestamp and duration.
28. `getEvolutionStageConfig(uint8 stage)`: Returns configuration parameters for a specific evolution stage.

**Admin & Configuration Functions:**
29. `setEvolutionStageConfig(uint8 stage, uint256 xpToNext, uint256 juiceCost, uint256 energyRequired, uint256 maxEnergy, uint256 decayRatePerMinute)`: Sets parameters for an evolution stage.
30. `setGeneEnhancementCost(uint256 cost)`: Sets the JUICE cost for gene enhancement.
31. `setMintCost(uint256 cost)`: Sets the ETH/Matic cost to mint a creature.
32. `grantJuice(address to, uint256 amount)`: Mints and grants JUICE (e.g., for initial distribution or admin needs).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces (representing standard interfaces without full OpenZeppelin implementation)
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);

    function totalSupply() external view returns (uint255);
    function balanceOf(address account) external view returns (uint255);
    function transfer(address to, uint255 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint255);
    function approve(address spender, uint255 amount) external returns (bool);
    function transferFrom(address from, address to, uint255 amount) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Helper library for safe address interactions (simplified version)
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        require(success, "Address: low-level call failed");
        return returndata;
    }
}


contract CryptoEvolution is IERC721 {
    using Address for address;

    // --- Constants ---
    uint256 public constant GENE_COUNT = 5; // Number of genes per creature
    uint256 public constant MAX_GENE_VALUE = 100; // Max value for a single gene
    uint256 public constant BASE_MUTATION_JUICE_COST = 10;
    uint256 public geneEnhancementCost = 50; // Adjustable cost for specific enhancement
    uint256 public initialMintCost = 0.01 ether; // Cost in native token to mint

    // --- Data Structures ---

    struct Creature {
        uint256 genes[GENE_COUNT]; // Array of gene values (0-MAX_GENE_VALUE)
        uint8 evolutionStage;      // Current stage (0, 1, 2...)
        uint256 experience;        // XP towards next evolution
        uint256 energy;            // Current energy level
        uint256 lastFedTimestamp;  // Timestamp of last feeding
        uint256 lastExplorationTimestamp; // Timestamp exploration started
        uint256 explorationDuration; // Duration of current exploration in minutes
        bool isExploring;           // Flag indicating if currently exploring
    }

    struct EvolutionStageConfig {
        uint256 xpToNext;           // XP required to reach the next stage
        uint256 juiceCost;          // JUICE required for evolution
        uint256 energyRequired;     // Minimum energy required to evolve
        uint256 maxEnergy;          // Maximum energy for this stage
        uint256 decayRatePerMinute; // Energy decay per minute
    }

    // ERC721 Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId; // Counter for unique token IDs

    // ERC20 Mappings (EvolutionJuice)
    string public constant juiceName = "Evolution Juice";
    string public constant juiceSymbol = "JUICE";
    uint8 public constant juiceDecimals = 18;
    uint256 private _totalSupplyJuice;
    mapping(address => uint256) private _balancesJuice;
    mapping(address => mapping(address => uint256)) private _allowancesJuice;

    // Creature Data
    mapping(uint256 => Creature) private _creatures;

    // Evolution Stage Configuration
    EvolutionStageConfig[] public evolutionStages; // evolutionStages[0] is stage 0 config, etc.

    // Access Control
    address public owner;

    // --- Events ---
    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialGenes);
    event CreatureFed(uint256 indexed tokenId, uint256 energyGained, uint256 juiceSpent);
    event CreatureDecayed(uint256 indexed tokenId, uint256 energyLost);
    event CreatureEvolved(uint256 indexed tokenId, uint8 newStage);
    event CreatureBred(uint256 indexed parent1TokenId, uint256 indexed parent2TokenId, uint256 indexed offspringTokenId);
    event CreatureSentOnExploration(uint256 indexed tokenId, uint256 durationInMinutes);
    event ExplorationYieldClaimed(uint256 indexed tokenId, uint256 juiceGained, uint256 xpGained);
    event CreatureMutated(uint256 indexed tokenId, uint8 geneIndex, uint256 oldValue, uint256 newValue, bool success);
    event GeneEnhanced(uint256 indexed tokenId, uint8 geneIndex, uint256 oldValue, uint256 newValue, bool success);
    event JuiceGranted(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1

        // Add an initial default stage 0 config
        evolutionStages.push(EvolutionStageConfig({
            xpToNext: 100,
            juiceCost: 50,
            energyRequired: 20,
            maxEnergy: 100,
            decayRatePerMinute: 1
        }));
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyCreatureOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Not your creature");
        _;
    }

     modifier onlyNotExploring(uint256 tokenId) {
        require(!_creatures[tokenId].isExploring, "Creature is exploring");
        _;
    }

    // --- Internal Helper Functions ---

    // Applies energy decay based on time elapsed since last feed
    function _applyDecay(uint256 tokenId) internal {
        Creature storage creature = _creatures[tokenId];
        if (creature.lastFedTimestamp == 0) {
             // Creature just minted or initialized, no decay yet
            creature.lastFedTimestamp = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - creature.lastFedTimestamp;
        uint256 minutesElapsed = timeElapsed / 60;

        if (minutesElapsed > 0) {
            uint8 currentStage = creature.evolutionStage;
            if (currentStage >= evolutionStages.length) {
                currentStage = uint8(evolutionStages.length - 1); // Use max configured stage decay
            }
            uint256 decayRate = evolutionStages[currentStage].decayRatePerMinute;
            uint256 energyLoss = minutesElapsed * decayRate;

            uint256 oldEnergy = creature.energy;
            if (energyLoss >= creature.energy) {
                creature.energy = 0;
            } else {
                creature.energy -= energyLoss;
            }
            creature.lastFedTimestamp = block.timestamp;
             if (oldEnergy > creature.energy) {
                 emit CreatureDecayed(tokenId, oldEnergy - creature.energy);
             }
        }
    }

    // Generates initial genes (random within limits)
    function _generateInitialGenes(uint256 seed) internal pure returns (uint256[GENE_COUNT] memory) {
        uint256[GENE_COUNT] memory genes;
        uint256 currentSeed = seed;
        for (uint8 i = 0; i < GENE_COUNT; i++) {
            // Simple pseudo-randomness based on seed
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i))) % MAX_GENE_VALUE;
            genes[i] = currentSeed + 1; // Ensure gene value is at least 1
            if (genes[i] > MAX_GENE_VALUE) genes[i] = MAX_GENE_VALUE; // Cap at max
        }
        return genes;
    }

    // Generates genes for offspring based on parents
    function _breedGenes(uint256[GENE_COUNT] memory genes1, uint256[GENE_COUNT] memory genes2, uint256 seed) internal pure returns (uint256[GENE_COUNT] memory) {
         uint256[GENE_COUNT] memory offspringGenes;
         uint256 currentSeed = seed;
         for (uint8 i = 0; i < GENE_COUNT; i++) {
             currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, i)));
             // Simple mix: Take gene from parent1 or parent2 randomly
             if (currentSeed % 2 == 0) {
                 offspringGenes[i] = genes1[i];
             } else {
                 offspringGenes[i] = genes2[i];
             }
             // Small chance of spontaneous mutation during breeding
             if (currentSeed % 10 == 0) { // 10% mutation chance
                 offspringGenes[i] = _mutateGene(offspringGenes[i], uint256(keccak256(abi.encodePacked(currentSeed, "mutate", i))));
             }
         }
         return offspringGenes;
     }

    // Mutates a single gene value (can increase or decrease within limits)
    function _mutateGene(uint256 geneValue, uint256 seed) internal pure returns (uint256) {
        uint256 mutationAmount = (uint256(keccak256(abi.encodePacked(seed, "amount"))) % (MAX_GENE_VALUE / 10)) + 1; // Mutate by up to 10% of max
        if (uint256(keccak256(abi.encodePacked(seed, "direction"))) % 2 == 0) {
            // Increase
            geneValue += mutationAmount;
            if (geneValue > MAX_GENE_VALUE) {
                geneValue = MAX_GENE_VALUE;
            }
        } else {
            // Decrease
            if (geneValue <= mutationAmount) {
                geneValue = 1; // Don't go below 1
            } else {
                geneValue -= mutationAmount;
            }
        }
        return geneValue;
    }

     // Calculate exploration yield based on duration, stage, and genes (simplified)
    function _calculateExplorationYield(uint256 tokenId, uint256 durationInMinutes, uint256 seed) internal view returns (uint256 juiceYield, uint256 xpYield) {
        Creature storage creature = _creatures[tokenId];
        uint8 currentStage = creature.evolutionStage;
         if (currentStage >= evolutionStages.length) {
            currentStage = uint8(evolutionStages.length - 1); // Use max configured stage for yield calc
        }

        // Base yield scales with duration and stage
        juiceYield = durationInMinutes * (currentStage + 1);
        xpYield = durationInMinutes * (currentStage + 1);

        // Genes can influence yield (example: gene 0 for juice, gene 1 for xp)
        uint256 gene0 = creature.genes[0];
        uint256 gene1 = creature.genes[1];

        juiceYield += (juiceYield * gene0) / MAX_GENE_VALUE;
        xpYield += (xpYield * gene1) / MAX_GENE_VALUE;

        // Add some randomness (pseudo)
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(seed, tokenId, "yield"))) % 21; // 0-20% bonus/penalty
        juiceYield = (juiceYield * (80 + randomFactor)) / 100;
        xpYield = (xpYield * (80 + randomFactor)) / 100;

        // Minimum yield
        if (juiceYield < durationInMinutes) juiceYield = durationInMinutes;
        if (xpYield < durationInMinutes) xpYield = durationInMinutes;
    }


    // Mints a new NFT
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    // Burns an NFT
    function _burn(uint256 tokenId) internal {
        address ownerOfToken = ownerOf(tokenId);
        require(ownerOfToken != address(0), "ERC721: token not minted");

        // Clear approvals
        approve(address(0), tokenId);

        _balances[ownerOfToken]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId]; // Redundant with approve(0), but explicit
        delete _creatures[tokenId]; // Also delete creature data

        emit Transfer(ownerOfToken, address(0), tokenId);
    }

     // Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Checks if a token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Checks if msg.sender is approved or operator for the owner
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || isApprovedForAll(tokenOwner, spender) || getApproved(tokenId) == spender);
    }

    // Safe transfer helper
     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // ERC721Receiver hook check
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (unknown reason)");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // Transfer to non-contract is always safe
        }
    }


    // Internal JUICE transfer
    function _transferJuice(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balancesJuice[from] >= amount, "ERC20: transfer amount exceeds balance");

        _balancesJuice[from] -= amount;
        _balancesJuice[to] += amount;
        emit Transfer(from, to, amount);
    }

    // Internal JUICE minting
    function _mintJuice(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupplyJuice += amount;
        _balancesJuice[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal JUICE burning
    function _burnJuice(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balancesJuice[account] >= amount, "ERC20: burn amount exceeds balance");

        _balancesJuice[account] -= amount;
        _totalSupplyJuice -= amount;
        emit Transfer(account, address(0), amount);
    }

     // Internal JUICE allowance update
    function _approveJuice(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowancesJuice[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- ERC721 Public Functions ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address ownerAddr = _owners[tokenId];
        require(ownerAddr != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddr;
    }

    function approve(address to, uint256 tokenId) public override {
        address ownerAddr = ownerOf(tokenId);
        require(msg.sender == ownerAddr || isApprovedForAll(ownerAddr, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerAddr, to, tokenId);
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

    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // --- ERC20 Public Functions (EvolutionJuice) ---

    function totalSupplyJuice() public view returns (uint256) {
        return _totalSupplyJuice;
    }

    function balanceOfJuice(address owner) public view returns (uint256) {
        return _balancesJuice[owner];
    }

    function transferJuice(address to, uint256 amount) public returns (bool) {
        _transferJuice(msg.sender, to, amount);
        return true;
    }

    function allowanceJuice(address owner, address spender) public view returns (uint256) {
        return _allowancesJuice[owner][spender];
    }

    function approveJuice(address spender, uint256 amount) public returns (bool) {
        _approveJuice(msg.sender, spender, amount);
        return true;
    }

    function transferFromJuice(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowancesJuice[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approveJuice(from, msg.sender, currentAllowance - amount); // Decrease allowance
        _transferJuice(from, to, amount);
        return true;
    }


    // --- Creature Lifecycle & Interaction Functions ---

    // Function 16: Mints a new creature NFT
    function mintInitialCreature() public payable returns (uint256) {
        require(msg.value >= initialMintCost, "Not enough ETH/Matic to mint");

        uint256 newTokenId = _nextTokenId++;
        address recipient = msg.sender;

        // Generate initial genes based on block data for pseudo-randomness
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));
        uint256[GENE_COUNT] memory initialGenes = _generateInitialGenes(initialSeed);

        _creatures[newTokenId] = Creature({
            genes: initialGenes,
            evolutionStage: 0,
            experience: 0,
            energy: evolutionStages[0].maxEnergy, // Start with full energy
            lastFedTimestamp: block.timestamp,
            lastExplorationTimestamp: 0,
            explorationDuration: 0,
            isExploring: false
        });

        _mint(recipient, newTokenId);

        // Send mint cost to owner
        if (initialMintCost > 0) {
             Address.sendValue(payable(owner), initialMintCost);
        }
        // Refund excess payment
        if (msg.value > initialMintCost) {
             Address.sendValue(payable(msg.sender), msg.value - initialMintCost);
        }


        emit CreatureMinted(newTokenId, recipient, initialGenes);
        return newTokenId;
    }

    // Function 17: Feeds a creature
    function feedCreature(uint256 tokenId, uint256 juiceAmount) public onlyCreatureOwner(tokenId) onlyNotExploring(tokenId) {
        Creature storage creature = _creatures[tokenId];
        _applyDecay(tokenId); // Apply decay before feeding

        require(juiceAmount > 0, "Cannot feed with 0 juice");
        uint8 currentStage = creature.evolutionStage;
         if (currentStage >= evolutionStages.length) {
            currentStage = uint8(evolutionStages.length - 1); // Use max configured stage stats
        }
        uint256 maxEnergy = evolutionStages[currentStage].maxEnergy;

        // Amount of energy gained is proportional to juice amount (example formula)
        uint256 energyGained = (juiceAmount * maxEnergy) / 100; // Example: 100 JUICE = Max Energy

        // Spend the juice
        _burnJuice(msg.sender, juiceAmount); // Assuming juice is burned
        // Or: _transferJuice(msg.sender, address(this), juiceAmount); // Assuming juice goes to contract

        creature.energy += energyGained;
        if (creature.energy > maxEnergy) {
            creature.energy = maxEnergy;
        }
        creature.lastFedTimestamp = block.timestamp; // Reset decay timer

        // Feeding also gives a little XP
        creature.experience += juiceAmount / 10; // Example: 10 JUICE = 1 XP

        emit CreatureFed(tokenId, energyGained, juiceAmount);
    }

    // Function 18: Triggers evolution
    function triggerEvolution(uint256 tokenId) public onlyCreatureOwner(tokenId) onlyNotExploring(tokenId) {
        Creature storage creature = _creatures[tokenId];
        _applyDecay(tokenId); // Apply decay before evolving

        uint8 currentStageIndex = creature.evolutionStage;
        require(currentStageIndex < evolutionStages.length - 1, "Creature is already at max stage");

        EvolutionStageConfig storage currentStageConfig = evolutionStages[currentStageIndex];
        EvolutionStageConfig storage nextStageConfig = evolutionStages[currentStageIndex + 1];

        require(creature.experience >= currentStageConfig.xpToNext, "Not enough experience");
        require(creature.energy >= currentStageConfig.energyRequired, "Not enough energy");
        require(balanceOfJuice(msg.sender) >= currentStageConfig.juiceCost, "Not enough Evolution Juice");

        // Spend resources
        _burnJuice(msg.sender, currentStageConfig.juiceCost);
        creature.energy -= currentStageConfig.energyRequired; // Energy is consumed

        // Evolve!
        creature.evolutionStage = currentStageIndex + 1;
        creature.experience = 0; // Reset XP for next stage

        // Fully heal energy upon evolution (can be adjusted)
        creature.energy = nextStageConfig.maxEnergy;
        creature.lastFedTimestamp = block.timestamp; // Reset decay timer

        // Trigger a potential mutation upon evolution (simulated random chance)
        uint256 mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, "evolve_mutate")));
        if (mutationSeed % 5 == 0) { // 20% chance of mutation on evolution
            uint8 geneIndexToMutate = uint8(mutationSeed % GENE_COUNT);
            uint256 oldValue = creature.genes[geneIndexToMutate];
            creature.genes[geneIndexToMutate] = _mutateGene(oldValue, mutationSeed);
            emit CreatureMutated(tokenId, geneIndexToMutate, oldValue, creature.genes[geneIndexToMutate], true);
        } else {
             emit CreatureMutated(tokenId, 0, 0, 0, false); // Emit event indicating no mutation occurred
        }


        emit CreatureEvolved(tokenId, creature.evolutionStage);
    }

    // Function 19: Breeds two creatures
    function breedCreatures(uint256 parent1TokenId, uint256 parent2TokenId) public onlyCreatureOwner(parent1TokenId) onlyCreatureOwner(parent2TokenId) {
        require(parent1TokenId != parent2TokenId, "Cannot breed a creature with itself");

        Creature storage parent1 = _creatures[parent1TokenId];
        Creature storage parent2 = _creatures[parent2TokenId];

        // Apply decay to both parents
        _applyDecay(parent1TokenId);
        _applyDecay(parent2TokenId);

        // Breeding requirements (example: minimum energy, stage, Juice cost)
        uint8 stage1 = parent1.evolutionStage;
        uint8 stage2 = parent2.evolutionStage;
        if (stage1 >= evolutionStages.length) stage1 = uint8(evolutionStages.length-1);
        if (stage2 >= evolutionStages.length) stage2 = uint8(evolutionStages.length-1);

        uint256 breedingJuiceCost = 200 + (stage1 + stage2) * 50; // Example: cost increases with stage
        uint256 energyCost = 50; // Example: energy consumed by parents

        require(parent1.energy >= energyCost && parent2.energy >= energyCost, "Parents do not have enough energy to breed");
        require(stage1 > 0 || stage2 > 0, "At least one parent must be beyond stage 0 to breed"); // Example requirement
        require(balanceOfJuice(msg.sender) >= breedingJuiceCost, "Not enough Evolution Juice for breeding");

        // Spend resources
        _burnJuice(msg.sender, breedingJuiceCost);
        parent1.energy -= energyCost;
        parent2.energy -= energyCost;

        // Generate offspring genes
        uint256 breedSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, parent1TokenId, parent2TokenId, msg.sender)));
        uint256[GENE_COUNT] memory offspringGenes = _breedGenes(parent1.genes, parent2.genes, breedSeed);

        // Mint new offspring creature
        uint256 offspringTokenId = _nextTokenId++;
         _creatures[offspringTokenId] = Creature({
            genes: offspringGenes,
            evolutionStage: 0, // Offspring starts at stage 0
            experience: 0,
            energy: evolutionStages[0].maxEnergy, // Start with full energy
            lastFedTimestamp: block.timestamp,
            lastExplorationTimestamp: 0,
            explorationDuration: 0,
            isExploring: false
        });
        _mint(msg.sender, offspringTokenId);

        // Parents gain some XP from breeding
        parent1.experience += 10;
        parent2.experience += 10;


        emit CreatureBred(parent1TokenId, parent2TokenId, offspringTokenId);
    }

    // Function 20: Sends a creature on exploration
    function sendOnExploration(uint256 tokenId, uint256 durationInMinutes) public onlyCreatureOwner(tokenId) onlyNotExploring(tokenId) {
        require(durationInMinutes > 0 && durationInMinutes <= 7 * 24 * 60, "Exploration duration must be between 1 minute and 7 days"); // Example limits

        Creature storage creature = _creatures[tokenId];
         _applyDecay(tokenId); // Apply decay before sending

        // Optional: Require minimum energy to start exploration
        // require(creature.energy >= 10, "Not enough energy to start exploration");
        // creature.energy -= 10; // Cost energy to start

        creature.lastExplorationTimestamp = block.timestamp;
        creature.explorationDuration = durationInMinutes;
        creature.isExploring = true;

        emit CreatureSentOnExploration(tokenId, durationInMinutes);
    }

    // Function 21: Claims exploration yield
    function claimExplorationYield(uint256 tokenId) public onlyCreatureOwner(tokenId) {
        Creature storage creature = _creatures[tokenId];
        require(creature.isExploring, "Creature is not currently exploring");

        uint256 explorationEndTime = creature.lastExplorationTimestamp + (creature.explorationDuration * 60);
        require(block.timestamp >= explorationEndTime, "Exploration is not yet finished");

        // Calculate yield based on exploration duration, genes, and a seed
        uint256 yieldSeed = uint256(keccak256(abi.encodePacked(creature.lastExplorationTimestamp, creature.explorationDuration, tokenId, block.timestamp)));
        (uint256 juiceGained, uint256 xpGained) = _calculateExplorationYield(tokenId, creature.explorationDuration, yieldSeed);

        // Grant rewards
        _mintJuice(msg.sender, juiceGained); // Mint juice directly to owner
        creature.experience += xpGained;

        // Reset exploration status
        creature.lastExplorationTimestamp = 0;
        creature.explorationDuration = 0;
        creature.isExploring = false;

        // Apply decay for the time creature was exploring? Or just rely on next feed?
        // Let's rely on the next feed to apply decay.

        emit ExplorationYieldClaimed(tokenId, juiceGained, xpGained);
    }

    // Function 22: Triggers a random mutation
    function triggerMutation(uint256 tokenId) public onlyCreatureOwner(tokenId) onlyNotExploring(tokenId) {
         Creature storage creature = _creatures[tokenId];
         _applyDecay(tokenId); // Apply decay before mutation

         uint256 mutationJuiceCost = BASE_MUTATION_JUICE_COST + (creature.evolutionStage * 5); // Cost increases with stage
         require(balanceOfJuice(msg.sender) >= mutationJuiceCost, "Not enough Evolution Juice to trigger mutation");

         _burnJuice(msg.sender, mutationJuiceCost);

         // Select a random gene to mutate
         uint256 mutationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, msg.sender, "mutation")));
         uint8 geneIndexToMutate = uint8(mutationSeed % GENE_COUNT);

         uint256 oldValue = creature.genes[geneIndexToMutate];
         creature.genes[geneIndexToMutate] = _mutateGene(oldValue, mutationSeed); // Apply mutation

        emit CreatureMutated(tokenId, geneIndexToMutate, oldValue, creature.genes[geneIndexToMutate], true);

         // Mutation might also affect energy/xp (optional)
         // creature.energy -= 10;
         // creature.experience += 5;
    }

    // Function 23: Attempts to specifically enhance a gene
     function applyGeneEnhancement(uint256 tokenId, uint8 geneIndex) public onlyCreatureOwner(tokenId) onlyNotExploring(tokenId) {
         require(geneIndex < GENE_COUNT, "Invalid gene index");

         Creature storage creature = _creatures[tokenId];
         _applyDecay(tokenId); // Apply decay

         require(balanceOfJuice(msg.sender) >= geneEnhancementCost, "Not enough Evolution Juice for enhancement");

         _burnJuice(msg.sender, geneEnhancementCost);

         uint256 enhancementSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, msg.sender, geneIndex, "enhance")));

         uint256 oldValue = creature.genes[geneIndex];
         uint256 newValue = oldValue;
         bool success = false;

         // 50% chance of success (example logic)
         if (enhancementSeed % 2 == 0) {
             success = true;
             // Increase the gene significantly
             uint256 enhancementAmount = (uint256(keccak256(abi.encodePacked(enhancementSeed, "amount"))) % (MAX_GENE_VALUE / 5)) + 5; // Enhance by at least 5, up to 20% of max
             newValue = oldValue + enhancementAmount;
             if (newValue > MAX_GENE_VALUE) {
                 newValue = MAX_GENE_VALUE;
             }
         } else {
             // On failure, maybe a small penalty or no change
             // newValue = oldValue; // No change on failure
             // Or: Small decrease on failure
              uint256 penaltyAmount = (uint256(keccak256(abi.encodePacked(enhancementSeed, "penalty"))) % 5) + 1; // Penalty up to 5
              if (newValue > penaltyAmount) newValue -= penaltyAmount;
              else newValue = 1; // Don't go below 1
         }

         creature.genes[geneIndex] = newValue;

         emit GeneEnhanced(tokenId, geneIndex, oldValue, newValue, success);

         // Gain or lose XP based on success/failure (optional)
         // if (success) creature.experience += 15;
         // else creature.experience -= 5;
     }


    // --- Query & Status Functions ---

    // Function 24: Gets all core creature details
    function getCreatureDetails(uint256 tokenId) public view returns (uint256[GENE_COUNT] memory genes, uint8 evolutionStage, uint256 experience, uint256 energy, uint256 lastFedTimestamp, uint256 lastExplorationTimestamp, uint256 explorationDuration, bool isExploring) {
        require(_exists(tokenId), "Token does not exist");
        Creature storage creature = _creatures[tokenId];
        return (creature.genes, creature.evolutionStage, creature.experience, creature.energy, creature.lastFedTimestamp, creature.lastExplorationTimestamp, creature.explorationDuration, creature.isExploring);
    }

     // Function 25: Gets creature genes
    function getCreatureGenes(uint256 tokenId) public view returns (uint256[GENE_COUNT] memory) {
        require(_exists(tokenId), "Token does not exist");
        return _creatures[tokenId].genes;
    }

    // Function 26: Gets creature status (Energy, XP, Stage, Last Fed)
    function getCreatureStatus(uint256 tokenId) public view returns (uint256 energy, uint256 experience, uint8 evolutionStage, uint256 lastFedTimestamp) {
        require(_exists(tokenId), "Token does not exist");
        Creature storage creature = _creatures[tokenId];
        // Note: Does NOT apply decay here, only shows current stored value
        return (creature.energy, creature.experience, creature.evolutionStage, creature.lastFedTimestamp);
    }

    // Function 27: Gets exploration status
     function getExplorationStatus(uint256 tokenId) public view returns (uint256 lastExplorationTimestamp, uint256 explorationDuration, bool isExploring) {
         require(_exists(tokenId), "Token does not exist");
         Creature storage creature = _creatures[tokenId];
         return (creature.lastExplorationTimestamp, creature.explorationDuration, creature.isExploring);
     }


    // Function 28: Gets evolution stage configuration
    function getEvolutionStageConfig(uint8 stage) public view returns (uint256 xpToNext, uint256 juiceCost, uint256 energyRequired, uint256 maxEnergy, uint256 decayRatePerMinute) {
        require(stage < evolutionStages.length, "Invalid evolution stage");
        EvolutionStageConfig storage config = evolutionStages[stage];
        return (config.xpToNext, config.juiceCost, config.energyRequired, config.maxEnergy, config.decayRatePerMinute);
    }


    // --- Admin & Configuration Functions ---

    // Function 29: Sets evolution stage parameters
    function setEvolutionStageConfig(uint8 stage, uint256 xpToNext, uint256 juiceCost, uint256 energyRequired, uint256 maxEnergy, uint256 decayRatePerMinute) public onlyOwner {
        require(maxEnergy > 0, "Max energy must be greater than 0");
        // Ensure enough stages exist, or add new ones
        while (evolutionStages.length <= stage) {
            evolutionStages.push(EvolutionStageConfig({
                xpToNext: 0, juiceCost: 0, energyRequired: 0, maxEnergy: 1, decayRatePerMinute: 0 // Add dummy config
            }));
        }

        evolutionStages[stage] = EvolutionStageConfig({
            xpToNext: xpToNext,
            juiceCost: juiceCost,
            energyRequired: energyRequired,
            maxEnergy: maxEnergy,
            decayRatePerMinute: decayRatePerMinute
        });
    }

    // Function 30: Sets the gene enhancement cost
    function setGeneEnhancementCost(uint256 cost) public onlyOwner {
        geneEnhancementCost = cost;
    }

    // Function 31: Sets the ETH/Matic mint cost
    function setMintCost(uint256 cost) public onlyOwner {
        initialMintCost = cost;
    }


    // Function 32: Grants Evolution Juice (Admin Mint)
    function grantJuice(address to, uint256 amount) public onlyOwner {
        _mintJuice(to, amount);
        emit JuiceGranted(to, amount);
    }

    // Optional: Add fallback/receive to accept ETH/Matic for minting
    receive() external payable {
        // Allow receiving ETH/Matic directly, potentially for future features or just holding
    }

    fallback() external payable {
        // Handle unexpected calls, can revert or just accept ETH
    }
}
```