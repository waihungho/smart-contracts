Okay, let's design a smart contract that represents a "Digital Genome Lab". This contract will manage unique digital "genomes" as NFTs (ERC721). The genomes are represented by arbitrary byte sequences. We'll incorporate concepts like mutation, crossbreeding, analysis, and potentially time-based "culturing", using role-based access control and fee mechanisms.

This isn't a standard ERC721 implementation; it adds significant custom logic on top.

**Concept:** Digital Genomes as NFTs. Each NFT holds a unique `bytes32[]` sequence representing a genome. The contract provides functions to interact with these genomes in ways analogous to biological processes.

**Advanced/Creative Concepts Used:**
1.  **Unique Per-Token Data Structure:** Storing complex data (`bytes32[]`) directly within the contract state for each NFT, not just metadata URI.
2.  **Procedural Mechanics:** Implementing functions (`mutate`, `crossbreed`) that algorithmically modify this per-token data based on rules.
3.  **Simulated Biological Processes:** Analogies for mutation, crossbreeding, and culturing.
4.  **Role-Based Access Control:** Using `AccessControl` to manage who can perform specific "lab" operations (e.g., 'Researchers').
5.  **Time-Based State Changes:** Incorporating block timestamps for processes like "culturing".
6.  **Internal "Analysis":** A function that interprets the genome data *on-chain* to derive simple traits (acknowledging complexity limitation on-chain).
7.  **Fee Mechanism:** Charging ether for certain complex operations.

---

**Outline & Function Summary**

**Contract:** `DigitalGenomeLab` (inherits ERC721 and AccessControl)

**Core Data:**
*   `_genomes`: Mapping from `tokenId` to `bytes32[]` (the genome sequence).
*   `_creationTime`: Mapping from `tokenId` to `uint48` (block timestamp of creation).
*   `_lastMutatedTime`: Mapping from `tokenId` to `uint48` (block timestamp of last mutation).
*   `_genomeFrozen`: Mapping from `tokenId` to `bool` (is mutation/crossbreeding locked?).
*   `_genomeGeneration`: Mapping from `tokenId` to `uint32` (generation number, starts at 1).
*   `_isCulturing`: Mapping from `tokenId` to `bool` (is genome currently being cultured?).
*   `_cultureStartTime`: Mapping from `tokenId` to `uint48` (block timestamp culture started).
*   `_mutationRate`: `uint8` (percentage chance/intensity factor for mutation).
*   `_crossbreedingFee`: `uint256` (ETH required for crossbreeding).
*   `_analysisFee`: `uint256` (ETH required for analysis request).

**Roles:**
*   `DEFAULT_ADMIN_ROLE`: Can grant/revoke other roles, set parameters, withdraw fees.
*   `RESEARCHER_ROLE`: Can perform complex lab operations like mutation and crossbreeding.

**Events:**
*   `GenomeMinted(uint256 indexed tokenId, address indexed owner, bytes32[] initialGenome)`
*   `GenomeMutated(uint256 indexed tokenId, address indexed by)`
*   `GenomesCrossbred(uint256 indexed parent1TokenId, uint256 indexed parent2TokenId, uint256 indexed childTokenId, address indexed by)`
*   `GenomeFrozen(uint256 indexed tokenId, address indexed by)`
*   `GenomeUnfrozen(uint256 indexed tokenId, address indexed by)`
*   `GenomeBurned(uint256 indexed tokenId, address indexed by)`
*   `GenomeCulturingStarted(uint256 indexed tokenId, address indexed by)`
*   `CultureYieldHarvested(uint256 indexed tokenId, address indexed by, uint256 amount)`
*   `AnalysisRequested(uint256 indexed tokenId, address indexed requestedBy)`
*   `FeesWithdrawn(address indexed to, uint256 amount)`
*   `ResearcherRoleGranted(address indexed account, address indexed sender)`
*   `ResearcherRoleRevoked(address indexed account, address indexed sender)`

**Functions (22 total, includes ERC721 basics):**

1.  `constructor(string memory name, string memory symbol)`: Initializes ERC721 and AccessControl.
2.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: ERC165 support for ERC721 and AccessControl. (1)
3.  `balanceOf(address owner) public view override returns (uint256)`: ERC721 standard. (2)
4.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721 standard. (3)
5.  `approve(address to, uint256 tokenId) public override`: ERC721 standard. (4)
6.  `getApproved(uint256 tokenId) public view override returns (address)`: ERC721 standard. (5)
7.  `setApprovalForAll(address operator, bool approved) public override`: ERC721 standard. (6)
8.  `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721 standard. (7)
9.  `transferFrom(address from, address to, uint256 tokenId) public override`: ERC721 standard. (8)
10. `safeTransferFrom(address from, address to, uint256 tokenId) public override`: ERC721 standard. (9)
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override`: ERC721 standard. (10)
12. `mintGenome(address owner, bytes32[] memory initialGenome)`: Mints a new genome NFT for `owner` with a specified initial sequence (or random if empty). Requires Admin or Researcher role. (11)
13. `getGenomeSequence(uint256 tokenId) public view returns (bytes32[] memory)`: Returns the raw genome sequence data for a token. (12)
14. `mutateGenome(uint256 tokenId) public onlyResearcher`: Applies a mutation effect to the genome sequence of `tokenId`. Modifier by `_mutationRate`. Requires Researcher role. (13)
15. `crossbreedGenomes(uint256 parent1TokenId, uint256 parent2TokenId) public payable onlyResearcher returns (uint256 newChildTokenId)`: Combines two parent genomes to create a new child genome NFT. Burns parent tokens. Requires Researcher role and payment of `_crossbreedingFee`. (14)
16. `analyzeGenome(uint256 tokenId) public view returns (uint256[] memory simpleTraits)`: Performs a simplified *on-chain* analysis of the genome sequence and returns derived traits (e.g., simple numerical values based on bytes). Doesn't cost ETH, but external complex analysis would. (15)
17. `freezeGenome(uint256 tokenId) public`: Prevents future mutation or crossbreeding of this genome. Owner or Researcher can do this. (16)
18. `unfreezeGenome(uint256 tokenId) public`: Allows future mutation or crossbreeding again. Owner or Researcher can do this. (17)
19. `burnGenome(uint256 tokenId) public`: Destroys a genome NFT. Owner or Admin can do this. (18)
20. `cultureGenome(uint256 tokenId) public`: Starts a time-based "culturing" process for the genome. Requires Researcher role. (19)
21. `harvestCultureYield(uint256 tokenId) public returns (uint256 yieldAmount)`: Stops culturing and calculates/distributes yield based on time elapsed. Requires Researcher role. (Yield mechanism is simplified for on-chain feasibility). (20)
22. `setMutationRate(uint8 rate) public onlyRole(DEFAULT_ADMIN_ROLE)`: Sets the `_mutationRate`. (21)
23. `setCrossbreedingFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE)`: Sets the `_crossbreedingFee`. (22)
24. `setAnalysisFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE)`: Sets the `_analysisFee`. (23)
25. `withdrawFees() public onlyRole(DEFAULT_ADMIN_ROLE)`: Allows the admin to withdraw accumulated ETH fees. (24)
26. `grantResearcherRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE)`: Grants the Researcher role. (25)
27. `revokeResearcherRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE)`: Revokes the Researcher role. (26)
28. `isResearcher(address account) public view returns (bool)`: Checks if an address has the Researcher role. (Helper, but counts as a function). (27)
29. `getGenomeCreationTime(uint256 tokenId) public view returns (uint48)`: Gets creation timestamp. (28)
30. `getGenomeLastMutatedTime(uint256 tokenId) public view returns (uint48)`: Gets last mutation timestamp. (29)
31. `getCurrentGeneration(uint256 tokenId) public view returns (uint32)`: Gets the generation number. (30)
32. `getGenomeFrozenStatus(uint256 tokenId) public view returns (bool)`: Gets the frozen status. (31)
33. `getCulturingStatus(uint256 tokenId) public view returns (bool, uint48)`: Gets culturing status and start time. (32)

*Note: The ERC721 standard itself requires 10 external functions including the two safeTransferFrom variants and supportsInterface. Counting these towards the 20+ total is reasonable as they are fundamental parts of the contract's interface.* We have significantly exceeded 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DigitalGenomeLab
 * @dev A smart contract managing unique digital genomes as ERC721 tokens.
 * Each token represents a genome sequence (bytes32[]) that can be mutated,
 * crossbred, analyzed, and cultured. Features include role-based access control,
 * time-based mechanics, and fee structures.
 *
 * Outline:
 * 1. Inherits ERC721 for NFT functionality.
 * 2. Inherits AccessControl for role management (Admin, Researcher).
 * 3. Stores core genome data: sequence, creation/mutation times, generation, frozen status, culturing status.
 * 4. Configuration parameters: mutation rate, crossbreeding/analysis fees.
 * 5. Events for tracking key lab operations.
 * 6. Functions for standard ERC721 operations (from inheritance).
 * 7. Functions for genome lifecycle: mint, mutate, crossbreed, analyze, freeze/unfreeze, burn.
 * 8. Functions for time-based mechanics: culture, harvest yield.
 * 9. Functions for admin/researcher tasks: setting parameters, granting roles, withdrawing fees.
 * 10. Helper internal functions for core logic (mutation, crossbreeding, simple analysis).
 *
 * Function Summary:
 * - ERC721 Basics: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), supportsInterface. (10)
 * - Core Genome Management: mintGenome, getGenomeSequence, mutateGenome, crossbreedGenomes, freezeGenome, unfreezeGenome, burnGenome. (7)
 * - Genome Interaction/Analysis: analyzeGenome. (1)
 * - Time-Based Mechanics: cultureGenome, harvestCultureYield. (2)
 * - Configuration/Admin: setMutationRate, setCrossbreedingFee, setAnalysisFee, withdrawFees. (4)
 * - Access Control: grantResearcherRole, revokeResearcherRole, isResearcher. (3)
 * - Data Getters: getGenomeCreationTime, getGenomeLastMutatedTime, getCurrentGeneration, getGenomeFrozenStatus, getCulturingStatus. (5)
 * Total: 10 + 7 + 1 + 2 + 4 + 3 + 5 = 32 Functions.
 */
contract DigitalGenomeLab is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Math for uint256; // For min/max/average if needed later

    bytes32 public constant RESEARCHER_ROLE = keccak256("RESEARCHER_ROLE");

    // --- State Variables ---

    // ERC721 state is handled by the inherited contract.
    Counters.Counter private _tokenIdCounter;

    // Genome data mapping: tokenId => sequence
    mapping(uint256 => bytes32[]) private _genomes;

    // Genome metadata/state mappings
    mapping(uint256 => uint48) private _creationTime; // uint48 for efficiency, sufficient for block.timestamp
    mapping(uint256 => uint48) private _lastMutatedTime;
    mapping(uint256 => bool) private _genomeFrozen;
    mapping(uint256 => uint32) private _genomeGeneration; // Generation number, starts at 1

    // Culturing state
    mapping(uint256 => bool) private _isCulturing;
    mapping(uint256 => uint48) private _cultureStartTime;

    // Lab parameters (configurable by Admin)
    uint8 public _mutationRate; // Percentage (0-100), affects mutation intensity/chance
    uint256 public _crossbreedingFee; // ETH required for crossbreeding
    uint256 public _analysisFee; // ETH required for external analysis requests (simple on-chain analysis is free)

    // --- Events ---

    event GenomeMinted(uint256 indexed tokenId, address indexed owner, bytes32[] initialGenome);
    event GenomeMutated(uint256 indexed tokenId, address indexed by);
    event GenomesCrossbred(uint256 indexed parent1TokenId, uint256 indexed parent2TokenId, uint256 indexed childTokenId, address indexed by);
    event GenomeFrozen(uint256 indexed tokenId, address indexed by);
    event GenomeUnfrozen(uint256 indexed tokenId, address indexed by);
    event GenomeBurned(uint256 indexed tokenId, address indexed by);
    event GenomeCulturingStarted(uint256 indexed tokenId, address indexed by);
    event CultureYieldHarvested(uint256 indexed tokenId, address indexed by, uint256 amount);
    event AnalysisRequested(uint256 indexed tokenId, address indexed requestedBy); // For potential external analysis trigger
    event FeesWithdrawn(address indexed to, uint256 amount);

    // Inherited events from AccessControl: RoleGranted, RoleRevoked
    // Inherited events from ERC721: Transfer, Approval, ApprovalForAll

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --- Access Control ---

    // The following functions are inherited from AccessControl and required:
    // hasRole(bytes32 role, address account)
    // getRoleAdmin(bytes32 role)
    // grantRole(bytes32 role, address account) - restricted to admin
    // revokeRole(bytes32 role, address account) - restricted to admin
    // renounceRole(bytes32 role, address account)

    modifier onlyResearcher() {
        require(hasRole(RESEARCHER_ROLE, msg.sender), "DGL: Caller is not a researcher");
        _;
    }

    function grantResearcherRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RESEARCHER_ROLE, account);
        emit ResearcherRoleGranted(account, msg.sender);
    }

    function revokeResearcherRole(address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
         require(hasRole(RESEARCHER_ROLE, account), "DGL: Account does not have researcher role");
        _revokeRole(RESEARCHER_ROLE, account);
        emit ResearcherRoleRevoked(account, msg.sender);
    }

    function isResearcher(address account) public view returns (bool) {
        return hasRole(RESEARCHER_ROLE, account);
    }

    // --- ERC721 Standard Overrides (Required for some functionality like burning) ---

    // We don't need to override most ERC721 functions unless we add custom logic
    // within transfer/approval flows. Let's add _beforeTokenTransfer for potential hooks.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Potentially add logic here, e.g., prevent transfer if culturing?
        // require(!_isCulturing[tokenId], "DGL: Cannot transfer while culturing");
    }

    // We will use the default _burn implementation inherited from ERC721
    // via the burnGenome function below.

    // Required ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(AccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Core Genome Functions ---

    /**
     * @dev Mints a new Digital Genome NFT.
     * @param owner The address to mint the genome to.
     * @param initialGenome The initial genome sequence. If empty, a pseudo-random one is generated.
     */
    function mintGenome(address owner, bytes32[] memory initialGenome) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        bytes32[] memory genomeSequence;
        if (initialGenome.length == 0) {
             // Generate a pseudo-random initial genome if none is provided
             // WARNING: This is NOT truly random and is predictable by miners.
             // For production, consider using Chainlink VRF or similar.
            genomeSequence = new bytes32[](4); // Example: 4 segments
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, block.number)));
            for(uint i = 0; i < genomeSequence.length; i++) {
                 seed = uint256(keccak256(abi.encodePacked(seed, i)));
                 genomeSequence[i] = bytes32(seed);
            }
        } else {
            genomeSequence = initialGenome;
        }

        _safeMint(owner, newTokenId);
        _genomes[newTokenId] = genomeSequence;
        _creationTime[newTokenId] = uint48(block.timestamp);
        _genomeGeneration[newTokenId] = 1; // First generation

        emit GenomeMinted(newTokenId, owner, genomeSequence);
    }

    /**
     * @dev Returns the genome sequence for a given token ID.
     * @param tokenId The ID of the genome token.
     * @return The genome sequence as a bytes32 array.
     */
    function getGenomeSequence(uint256 tokenId) public view returns (bytes32[] memory) {
        _requireMinted(tokenId); // Check if token exists
        return _genomes[tokenId];
    }

    /**
     * @dev Applies a mutation to a genome sequence.
     * Mutation effect is simplified: randomly flips bits in a byte based on mutation rate.
     * Requires the RESEARCHER_ROLE.
     * @param tokenId The ID of the genome token to mutate.
     */
    function mutateGenome(uint256 tokenId) public virtual onlyResearcher {
        _requireMinted(tokenId);
        require(!_genomeFrozen[tokenId], "DGL: Genome is frozen");

        bytes32[] storage genome = _genomes[tokenId];
        require(genome.length > 0, "DGL: Genome sequence is empty");

        uint256 sequenceLength = genome.length;
        uint256 totalBytes = sequenceLength * 32; // Total number of bytes
        uint256 bytesToMutate = (totalBytes * _mutationRate) / 100; // Number of bytes potentially affected

         // Use a pseudo-random seed for mutation points
         // WARNING: Predictable randomness.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, _lastMutatedTime[tokenId])));

        for(uint i = 0; i < bytesToMutate; i++) {
             seed = uint256(keccak256(abi.encodePacked(seed, i)));
             uint256 byteIndex = seed % totalBytes;
             uint256 blockIndex = byteIndex / 32;
             uint256 byteOffset = byteIndex % 32;

             // Simple mutation: Flip a random bit within the selected byte
             seed = uint256(keccak256(abi.encodePacked(seed, byteIndex))); // New seed for bit flip
             uint8 bitToFlip = uint8(seed % 8);
             bytes1 byteValue = bytes1(uint8(genome[blockIndex][byteOffset]));
             bytes1 mutatedByte = bytes1(uint8(byteValue) ^ (1 << bitToFlip));

             // Update the specific byte in the bytes32 block
             bytes32 blockData = genome[blockIndex];
             assembly {
                 mstore(add(block.buffer, byteOffset), mutatedByte) // Store the mutated byte temporarily
                 mstore(add(blockData, byteOffset), mload(add(block.buffer, byteOffset))) // Copy it into the storage bytes32
             }
             genome[blockIndex] = blockData; // Explicitly update storage

        }

        _lastMutatedTime[tokenId] = uint48(block.timestamp);
        emit GenomeMutated(tokenId, msg.sender);
    }


    /**
     * @dev Crossbreeds two parent genomes to create a new child genome.
     * The parent tokens are burned. Requires the RESEARCHER_ROLE and payment of _crossbreedingFee.
     * @param parent1TokenId The ID of the first parent genome token.
     * @param parent2TokenId The ID of the second parent genome token.
     * @return The ID of the newly created child genome token.
     */
    function crossbreedGenomes(uint256 parent1TokenId, uint256 parent2TokenId) public virtual payable onlyResearcher returns (uint256 newChildTokenId) {
        _requireMinted(parent1TokenId);
        _requireMinted(parent2TokenId);
        require(msg.value >= _crossbreedingFee, "DGL: Insufficient crossbreeding fee");
        require(!_genomeFrozen[parent1TokenId] && !_genomeFrozen[parent2TokenId], "DGL: Parent genome(s) are frozen");
        require(parent1TokenId != parent2TokenId, "DGL: Cannot crossbreed a genome with itself");
        // Optional: Add checks for parent generation or other criteria

        bytes32[] storage genome1 = _genomes[parent1TokenId];
        bytes32[] storage genome2 = _genomes[parent2TokenId];
        require(genome1.length > 0 && genome2.length > 0, "DGL: Parent genome sequence(s) are empty");

        // Simple crossover: Take first half from parent1, second half from parent2
        uint256 maxLength = genome1.length > genome2.length ? genome1.length : genome2.length;
        bytes32[] memory childGenome = new bytes32[](maxLength);
        uint256 crossoverPoint = maxLength / 2; // Simple midpoint

        for (uint i = 0; i < maxLength; i++) {
            if (i < crossoverPoint) {
                childGenome[i] = i < genome1.length ? genome1[i] : bytes32(0); // Use parent1 data or zero pad
            } else {
                 childGenome[i] = i < genome2.length ? genome2[i] : bytes32(0); // Use parent2 data or zero pad
            }
        }

        // Mint the new child genome
        _tokenIdCounter.increment();
        newChildTokenId = _tokenIdCounter.current();
        address childOwner = msg.sender; // Or specify an owner? Let's make it the researcher

        _safeMint(childOwner, newChildTokenId);
        _genomes[newChildTokenId] = childGenome;
        _creationTime[newChildTokenId] = uint48(block.timestamp);
        _genomeGeneration[newChildTokenId] = Math.max(_genomeGeneration[parent1TokenId], _genomeGeneration[parent2TokenId]) + 1;

        // Burn the parent tokens
        _burn(parent1TokenId);
        _burn(parent2TokenId);
        delete _genomes[parent1TokenId]; // Clean up storage
        delete _genomes[parent2TokenId];
        delete _creationTime[parent1TokenId];
        delete _creationTime[parent2TokenId];
        delete _lastMutatedTime[parent1TokenId];
        delete _lastMutatedTime[parent2TokenId];
        delete _genomeFrozen[parent1TokenId];
        delete _genomeFrozen[parent2TokenId];
        delete _genomeGeneration[parent1TokenId];
        delete _genomeGeneration[parent2TokenId];
         delete _isCulturing[parent1TokenId]; // Ensure culturing state is cleared
         delete _isCulturing[parent2TokenId];
         delete _cultureStartTime[parent1TokenId];
         delete _cultureStartTime[parent2TokenId];


        emit GenomesCrossbred(parent1TokenId, parent2TokenId, newChildTokenId, msg.sender);
        emit GenomeBurned(parent1TokenId, msg.sender);
        emit GenomeBurned(parent2TokenId, msg.sender);


        return newChildTokenId;
    }

    /**
     * @dev Performs a simplified on-chain analysis of a genome sequence.
     * This is a placeholder for more complex off-chain analysis.
     * Returns a simple array of derived traits based on specific bytes/patterns.
     * @param tokenId The ID of the genome token to analyze.
     * @return An array of uint256 values representing simple traits.
     */
    function analyzeGenome(uint256 tokenId) public view returns (uint256[] memory simpleTraits) {
        _requireMinted(tokenId);
        bytes32[] memory genome = _genomes[tokenId];
        require(genome.length > 0, "DGL: Genome sequence is empty");

        // --- Simplified On-Chain Analysis ---
        // This is a basic example. Real analysis would be complex and likely off-chain.
        // Traits could be derived from specific indices, patterns, or calculations.
        // Example: Derive 3 traits from the first 3 bytes of the first block.
        uint256 numTraits = Math.min(genome[0].length, 3); // Number of traits to derive
        simpleTraits = new uint256[](numTraits);

        if (genome.length > 0) {
            bytes32 firstBlock = genome[0];
            for (uint i = 0; i < numTraits; i++) {
                // Extract a byte and treat it as a trait value
                simpleTraits[i] = uint8(firstBlock[i]);
            }
        }
        // --- End Simplified Analysis ---

        // Note: Charging a fee for this simple on-chain analysis isn't implemented here,
        // but the _analysisFee variable exists for future integration (e.g., with external oracle)
        // emit AnalysisRequested(tokenId, msg.sender); // Optional event if this were an external trigger
    }

    /**
     * @dev Freezes a genome, preventing mutation and crossbreeding.
     * Can be called by the owner or a Researcher.
     * @param tokenId The ID of the genome token to freeze.
     */
    function freezeGenome(uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(RESEARCHER_ROLE, msg.sender), "DGL: Must be owner or researcher to freeze");
        _genomeFrozen[tokenId] = true;
        emit GenomeFrozen(tokenId, msg.sender);
    }

    /**
     * @dev Unfreezes a genome, allowing mutation and crossbreeding again.
     * Can be called by the owner or a Researcher.
     * @param tokenId The ID of the genome token to unfreeze.
     */
    function unfreezeGenome(uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(RESEARCHER_ROLE, msg.sender), "DGL: Must be owner or researcher to unfreeze");
        _genomeFrozen[tokenId] = false;
        emit GenomeUnfrozen(tokenId, msg.sender);
    }

     /**
     * @dev Burns (destroys) a genome NFT.
     * Can be called by the owner or an Admin.
     * @param tokenId The ID of the genome token to burn.
     */
    function burnGenome(uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DGL: Must be owner or admin to burn");
        require(!_isCulturing[tokenId], "DGL: Cannot burn while culturing"); // Prevent burning cultured genomes

        _burn(tokenId);
        delete _genomes[tokenId]; // Clean up storage
        delete _creationTime[tokenId];
        delete _lastMutatedTime[tokenId];
        delete _genomeFrozen[tokenId];
        delete _genomeGeneration[tokenId];
        delete _isCulturing[tokenId];
        delete _cultureStartTime[tokenId];

        emit GenomeBurned(tokenId, msg.sender);
    }

    // --- Time-Based Culturing Functions ---

    /**
     * @dev Starts the culturing process for a genome.
     * Genome must not be frozen or already culturing. Requires RESEARCHER_ROLE.
     * @param tokenId The ID of the genome token to culture.
     */
    function cultureGenome(uint256 tokenId) public virtual onlyResearcher {
        _requireMinted(tokenId);
        require(!_genomeFrozen[tokenId], "DGL: Cannot culture a frozen genome");
        require(!_isCulturing[tokenId], "DGL: Genome is already culturing");

        _isCulturing[tokenId] = true;
        _cultureStartTime[tokenId] = uint48(block.timestamp);

        emit GenomeCulturingStarted(tokenId, msg.sender);
    }

    /**
     * @dev Stops the culturing process and harvests potential yield.
     * Yield calculation is a simplified example based on time elapsed.
     * Requires RESEARCHER_ROLE.
     * @param tokenId The ID of the genome token to harvest from.
     * @return The amount of yield harvested (example: ETH, or another token).
     */
    function harvestCultureYield(uint256 tokenId) public virtual onlyResearcher returns (uint256 yieldAmount) {
        _requireMinted(tokenId);
        require(_isCulturing[tokenId], "DGL: Genome is not culturing");

        uint256 startTime = _cultureStartTime[tokenId];
        uint256 duration = block.timestamp - startTime;

        // --- Simplified Yield Calculation ---
        // Example: Yield = duration in seconds * (genome length) / some factor
        // This is a highly simplified example. Real yield would depend on tokenomics,
        // potentially genome traits, external factors, etc. Could also distribute another token.
        // Let's calculate a small amount of ether yield for demonstration.
        uint256 genomeLength = _genomes[tokenId].length;
        // Avoid division by zero and keep numbers reasonable for demo
        uint256 yieldPerSecondPerBlock = (genomeLength > 0 ? genomeLength : 1) * 1000; // in wei * blocks
        yieldAmount = (duration * yieldPerSecondPerBlock) / 1e18; // Convert example value to roughly ETH

        // Ensure there's some 'yield pool' or mechanism to pay this out.
        // For simplicity, this contract doesn't have a yield pool; this function
        // just *calculates* the yield amount. A real system would transfer tokens/ether.
        // require(address(this).balance >= yieldAmount, "DGL: Insufficient yield pool");
        // payable(msg.sender).transfer(yieldAmount); // Transfer ETH (Requires contract balance)

        // Reset culturing state
        _isCulturing[tokenId] = false;
        delete _cultureStartTime[tokenId]; // Clean up storage

        emit CultureYieldHarvested(tokenId, msg.sender, yieldAmount);

        return yieldAmount; // Return calculated amount, assuming external system distributes
    }


    // --- Configuration & Admin Functions ---

    /**
     * @dev Sets the mutation rate.
     * Higher rate means more intense/probable mutations. 0-100.
     * Requires the DEFAULT_ADMIN_ROLE.
     * @param rate The new mutation rate (0-100).
     */
    function setMutationRate(uint8 rate) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rate <= 100, "DGL: Rate must be between 0 and 100");
        _mutationRate = rate;
    }

     /**
     * @dev Sets the fee required for crossbreeding.
     * Requires the DEFAULT_ADMIN_ROLE.
     * @param fee The new crossbreeding fee in Wei.
     */
    function setCrossbreedingFee(uint256 fee) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _crossbreedingFee = fee;
    }

    /**
     * @dev Sets the fee required for requesting analysis (if applicable).
     * Requires the DEFAULT_ADMIN_ROLE.
     * @param fee The new analysis fee in Wei.
     */
    function setAnalysisFee(uint256 fee) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _analysisFee = fee;
    }

    /**
     * @dev Allows the admin to withdraw accumulated fees (ETH).
     * Requires the DEFAULT_ADMIN_ROLE.
     */
    function withdrawFees() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "DGL: No fees to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "DGL: ETH withdrawal failed");

        emit FeesWithdrawn(msg.sender, balance);
    }

     // Receive function to accept ETH fees
    receive() external payable {}

    // Fallback function to accept ETH
    fallback() external payable {}


    // --- Data Getters ---

    /**
     * @dev Gets the creation timestamp for a genome.
     * @param tokenId The ID of the genome token.
     * @return The creation timestamp.
     */
    function getGenomeCreationTime(uint256 tokenId) public view returns (uint48) {
         _requireMinted(tokenId);
         return _creationTime[tokenId];
    }

    /**
     * @dev Gets the last mutated timestamp for a genome.
     * @param tokenId The ID of the genome token.
     * @return The last mutated timestamp.
     */
    function getGenomeLastMutatedTime(uint256 tokenId) public view returns (uint48) {
        _requireMinted(tokenId);
        return _lastMutatedTime[tokenId];
    }

    /**
     * @dev Gets the generation number for a genome.
     * @param tokenId The ID of the genome token.
     * @return The generation number.
     */
    function getCurrentGeneration(uint256 tokenId) public view returns (uint32) {
        _requireMinted(tokenId);
        return _genomeGeneration[tokenId];
    }

     /**
     * @dev Checks if a genome is currently frozen.
     * @param tokenId The ID of the genome token.
     * @return True if frozen, false otherwise.
     */
    function getGenomeFrozenStatus(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return _genomeFrozen[tokenId];
    }

    /**
     * @dev Checks if a genome is currently culturing and its start time.
     * @param tokenId The ID of the genome token.
     * @return A tuple containing: bool indicating if culturing, and uint48 start time (0 if not culturing).
     */
    function getCulturingStatus(uint256 tokenId) public view returns (bool, uint48) {
        _requireMinted(tokenId);
        return (_isCulturing[tokenId], _cultureStartTime[tokenId]);
    }

    // --- Internal Helpers ---

    /**
     * @dev Helper to check if a token ID has been minted.
     * @param tokenId The ID of the token.
     */
    function _requireMinted(uint256 tokenId) internal view {
         // Using _exists from ERC721 is more gas efficient than ownerOf(tokenId) != address(0)
         // It also correctly handles cases where the token might be burned.
         require(_exists(tokenId), "DGL: Token does not exist");
    }

    /**
     * @dev Internal helper to check if an address is the owner or approved operator for a token.
     * Used in freeze/unfreeze for owner permission.
     * @param caller The address to check.
     * @param tokenId The ID of the token.
     * @return True if caller is owner or approved, false otherwise.
     */
    function _isApprovedOrOwner(address caller, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return caller == tokenOwner || isApprovedForAll(tokenOwner, caller) || getApproved(tokenId) == caller;
    }


    // Further internal helpers for complex logic like advanced mutation or crossbreeding algorithms
    // would go here. The current implementations in `mutateGenome` and `crossbreedGenomes` are
    // simplified for on-chain feasibility and gas limits.
}
```