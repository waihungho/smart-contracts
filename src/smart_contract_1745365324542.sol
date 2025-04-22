Okay, here is a Solidity smart contract implementing a concept I call a "Digital Fabricator". This contract fabricates unique "Artifacts" which are non-fungible digital items. What makes it advanced and creative is that these artifacts are *dynamic* – they can be "Energized" and subjected to "Mutation" attempts, which can procedurally change their attributes on-chain. It also implements a simplified, manual version of asset ownership and transfer similar to ERC-721, but *without* inheriting standard libraries, to fulfill the "don't duplicate open source" aspect while providing core asset management features.

This contract uses pseudo-randomness based on block data for the procedural generation and mutation. **Important Security Note:** Using `blockhash` and `block.timestamp` for randomness is *predictable* to miners and should *not* be used for high-value operations requiring true, unpredictable randomness. For a production system, you would need a Verifiable Random Function (VRF) like Chainlink VRF. This implementation is for demonstration of the *concept*.

---

**Contract Name:** `DigitalFabricator`

**Description:**
A smart contract for fabricating unique, dynamic digital "Artifacts". Each Artifact is an on-chain non-fungible item with immutable "Genes" and mutable "Attributes". Owners can "Energize" their artifacts, allowing them to attempt "Mutations" which can alter the artifact's attributes based on on-chain procedural generation and chance. The fabrication and energizing processes require Ether payments.

**Core Concepts:**
1.  **On-Chain Procedural Generation:** Initial "Genes" and starting "Attributes" are generated based on input complexity and pseudo-random factors at fabrication.
2.  **Dynamic Attributes:** Artifact attributes can change over time through the "Mutation" process.
3.  **State-Based Evolution:** Artifacts must be in an "Energized" state to attempt a mutation.
4.  **Manual Asset Management:** Implements basic ownership, transfer, and approval logic without inheriting standard ERC-721 libraries.
5.  **Parameterized Processes:** Fabrication and energy costs, as well as mutation chances, are parameters that can be adjusted by the contract owner.

**Key Components:**
*   `Artifact` Struct: Defines the structure of a digital artifact including ID, genes, attributes, timestamps, evolution count, energy status, and owner.
*   `artifacts`: A mapping storing `Artifact` structs by their unique ID.
*   `artifactOwners`: A mapping tracking the owner address for each artifact ID (manual ownership).
*   `approvedTransfers`: A mapping tracking approved addresses for transferring specific artifacts (manual approval).
*   `nextArtifactId`: Counter for assigning unique IDs.
*   `FABRICATION_BASE_COST`, `ENERGY_COST_FACTOR`, `MUTATION_CHANCE_PERCENT`, etc.: Configurable parameters.
*   `owner`: The contract administrator address.
*   `allowedGeneRange`: Defines min/max values for generated genes.

**Events:**
*   `ArtifactFabricated`: Emitted when a new artifact is created.
*   `ArtifactEnergized`: Emitted when an artifact is energized.
*   `ArtifactMutated`: Emitted when an artifact successfully mutates.
*   `AttributeChanged`: Emitted when a specific attribute on an artifact changes.
*   `Transfer`: Emitted when an artifact is transferred (manual).
*   `Approval`: Emitted when transfer approval is granted (manual).
*   `OwnershipTransferred`: Emitted when contract ownership changes.
*   `FundsWithdrawn`: Emitted when contract owner withdraws funds.
*   `ParameterUpdated`: Emitted when a contract parameter is changed by the owner.

**Function Summary:**

**Fabrication & Core Interaction:**
1.  `fabricateArtifact(uint256 complexitySeed)`: Creates a new artifact. Requires Ether payment based on complexity. Generates genes and initial attributes.
2.  `energizeArtifact(uint256 artifactId)`: Energizes an existing artifact. Requires Ether payment. Allows subsequent mutation attempts.
3.  `attemptMutation(uint256 artifactId)`: Attempts to mutate an energized artifact. Success is probabilistic. If successful, attributes are altered. Consumes the energized state.

**Asset Management (Manual ERC-721-like):**
4.  `balanceOf(address owner)`: Returns the number of artifacts owned by an address.
5.  `ownerOf(uint256 artifactId)`: Returns the owner of an artifact.
6.  `transferArtifact(address to, uint256 artifactId)`: Transfers an artifact directly to another address (caller must be owner).
7.  `approve(address to, uint256 artifactId)`: Grants approval for another address to transfer a specific artifact.
8.  `getApproved(uint256 artifactId)`: Returns the address approved for a specific artifact.
9.  `transferFrom(address from, address to, uint256 artifactId)`: Transfers an artifact from one address to another (caller must be owner or approved).

**View Functions (Querying Artifacts & State):**
10. `getArtifact(uint256 artifactId)`: Returns all details of a specific artifact (view, requires Solidity >= 0.8.0 for returning structs).
11. `getArtifactGenes(uint256 artifactId)`: Returns just the genes of an artifact.
12. `getArtifactAttributes(uint256 artifactId)`: Returns just the attributes of an artifact.
13. `getArtifactEvolutionCount(uint256 artifactId)`: Returns the evolution count.
14. `getArtifactFabricationTimestamp(uint256 artifactId)`: Returns the fabrication timestamp.
15. `isArtifactEnergized(uint256 artifactId)`: Returns the energized status.
16. `getTotalArtifacts()`: Returns the total number of artifacts fabricated.
17. `getFabricationCost(uint256 complexitySeed)`: Calculates the Ether cost for fabricating with a given complexity.
18. `getEnergyCost()`: Returns the current Ether cost to energize an artifact.
19. `getAllowedFabricationGeneRange()`: Returns the min/max allowed gene values.

**Admin/Parameter Management (Owner Only):**
20. `setFabricationBaseCost(uint256 newCost)`: Sets the base cost for fabrication.
21. `setEnergyCostFactor(uint256 newFactor)`: Sets the factor for calculating energy cost.
22. `setMutationChance(uint256 newChancePercent)`: Sets the mutation success chance (0-100).
23. `setMaxAttributes(uint256 newMax)`: Sets the maximum number of dynamic attributes an artifact can have.
24. `setAllowedFabricationGeneRange(uint256 min, uint256 max)`: Sets the allowed range for initial gene values.
25. `withdrawFunds()`: Allows the contract owner to withdraw accumulated Ether.
26. `transferOwnership(address newOwner)`: Transfers contract ownership.

**Internal/Helper Functions (Not Externally Callable):**
*   `_generateGenes(uint256 complexitySeed)`: Internal logic for generating initial genes.
*   `_mutateAttributes(uint256 artifactId)`: Internal logic for altering attributes during mutation.
*   `_isValidArtifact(uint256 artifactId)`: Internal check if an artifact ID exists.
*   `_transfer(address from, address to, uint256 artifactId)`: Internal logic for transferring ownership.
*   `_clearApproval(uint256 artifactId)`: Internal logic to clear approval after transfer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DigitalFabricator
/// @notice A contract for fabricating unique, dynamic digital Artifacts that can evolve on-chain.

// --- Outline ---
// 1. Structs: Artifact
// 2. State Variables: Artifact storage, ownership, parameters, counters.
// 3. Events: Actions and state changes.
// 4. Modifiers: onlyOwner.
// 5. Constructor.
// 6. Core Fabrication & Evolution Functions: fabricateArtifact, energizeArtifact, attemptMutation.
// 7. Asset Management Functions (Manual ERC721-like): balanceOf, ownerOf, transferArtifact, approve, getApproved, transferFrom.
// 8. View Functions: Get artifact details and contract state.
// 9. Admin Functions: Set parameters, withdraw funds, transfer ownership.
// 10. Internal Helper Functions: Gene generation, attribute mutation, transfer logic, validation.

// --- Function Summary ---
// Fabrication & Core Interaction:
// - fabricateArtifact(uint256 complexitySeed): Creates a new artifact.
// - energizeArtifact(uint256 artifactId): Energizes an artifact for mutation.
// - attemptMutation(uint256 artifactId): Attempts to mutate an energized artifact.
// Asset Management (Manual ERC721-like):
// - balanceOf(address owner): Get number of artifacts owned by address.
// - ownerOf(uint256 artifactId): Get owner of artifact.
// - transferArtifact(address to, uint256 artifactId): Direct owner transfer.
// - approve(address to, uint256 artifactId): Approve transfer.
// - getApproved(uint256 artifactId): Get approved address.
// - transferFrom(address from, address to, uint256 artifactId): Transfer by owner or approved.
// View Functions:
// - getArtifact(uint256 artifactId): Get full artifact details.
// - getArtifactGenes(uint256 artifactId): Get artifact genes.
// - getArtifactAttributes(uint256 artifactId): Get artifact attributes.
// - getArtifactEvolutionCount(uint256 artifactId): Get evolution count.
// - getArtifactFabricationTimestamp(uint256 artifactId): Get fabrication timestamp.
// - isArtifactEnergized(uint256 artifactId): Get energized status.
// - getTotalArtifacts(): Get total fabricated count.
// - getFabricationCost(uint256 complexitySeed): Calculate fabrication cost.
// - getEnergyCost(): Get energy cost.
// - getAllowedFabricationGeneRange(): Get gene range parameters.
// Admin Functions (Owner Only):
// - setFabricationBaseCost(uint256 newCost): Set fabrication base cost.
// - setEnergyCostFactor(uint256 newFactor): Set energy cost factor.
// - setMutationChance(uint256 newChancePercent): Set mutation chance (0-100).
// - setMaxAttributes(uint256 newMax): Set max dynamic attributes.
// - setAllowedFabricationGeneRange(uint256 min, uint256 max): Set gene range.
// - withdrawFunds(): Withdraw contract balance.
// - transferOwnership(address newOwner): Transfer contract ownership.
// Internal Functions:
// - _generateGenes, _mutateAttributes, _isValidArtifact, _transfer, _clearApproval.

contract DigitalFabricator {

    /// @dev Represents a unique digital artifact.
    struct Artifact {
        uint256 id;
        uint256[] genes; // Immutable initial parameters
        mapping(string => uint256) attributes; // Dynamic, mutable properties
        uint256 fabricationTimestamp;
        uint256 lastMutationTimestamp;
        uint256 evolutionCount;
        bool isEnergized;
    }

    // --- State Variables ---

    mapping(uint256 => Artifact) private artifacts;
    mapping(uint256 => address) private artifactOwners; // Manual ownership tracking
    mapping(uint256 => address) private approvedTransfers; // Manual approval tracking
    mapping(address => uint256) private ownerArtifactCount; // Manual balance tracking

    uint256 private nextArtifactId = 1;

    uint256 public FABRICATION_BASE_COST = 0.01 ether; // Base cost to fabricate
    uint256 public ENERGY_COST_FACTOR = 0.005 ether; // Cost factor to energize
    uint256 public MUTATION_CHANCE_PERCENT = 25; // % chance for mutation success (0-100)
    uint256 public MAX_ATTRIBUTES = 10; // Max dynamic attributes per artifact

    // Allowed range for initial gene values
    uint256 public allowedGeneRangeMin = 1;
    uint256 public allowedGeneRangeMax = 1000;

    address public owner; // Contract owner/admin

    /// @dev Internal state variable to track if an attribute exists for efficient checking.
    mapping(uint256 => mapping(string => bool)) private attributeExists;

    // --- Events ---

    /// @dev Emitted when a new artifact is fabricated.
    /// @param artifactId The ID of the new artifact.
    /// @param creator The address that fabricated the artifact.
    /// @param cost The Ether cost paid.
    event ArtifactFabricated(uint256 indexed artifactId, address indexed creator, uint256 cost);

    /// @dev Emitted when an artifact is energized.
    /// @param artifactId The ID of the artifact.
    /// @param energizer The address that energized the artifact.
    /// @param cost The Ether cost paid.
    event ArtifactEnergized(uint256 indexed artifactId, address indexed energizer, uint256 cost);

    /// @dev Emitted when an artifact successfully mutates.
    /// @param artifactId The ID of the artifact.
    /// @param evolutionCount The new evolution count.
    event ArtifactMutated(uint256 indexed artifactId, uint256 evolutionCount);

    /// @dev Emitted when an attribute's value changes on an artifact.
    /// @param artifactId The ID of the artifact.
    /// @param attributeName The name of the attribute.
    /// @param newValue The new value of the attribute.
    event AttributeChanged(uint256 indexed artifactId, string attributeName, uint256 newValue);

    /// @dev Emitted when artifact ownership changes (manual ERC721-like).
    /// @param from The address losing ownership.
    /// @param to The address gaining ownership.
    /// @param artifactId The ID of the artifact transferred.
    event Transfer(address indexed from, address indexed to, uint256 indexed artifactId);

    /// @dev Emitted when an address is approved to transfer a specific artifact (manual ERC721-like).
    /// @param approved The address approved.
    /// @param artifactId The ID of the artifact.
    event Approval(address indexed approved, uint256 indexed artifactId);

    /// @dev Emitted when contract ownership is transferred.
    /// @param previousOwner The previous contract owner.
    /// @param newOwner The new contract owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Emitted when the contract owner withdraws funds.
    /// @param to The address receiving funds.
    /// @param amount The amount withdrawn.
    event FundsWithdrawn(address indexed to, uint256 amount);

    /// @dev Emitted when a contract parameter is updated by the owner.
    /// @param parameterName The name of the parameter changed.
    /// @param oldValue The previous value.
    /// @param newValue The new value (represented as uint256).
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---

    /// @dev Restricts function access to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Core Fabrication & Evolution Functions ---

    /// @notice Fabricates a new digital artifact.
    /// @dev The cost is calculated based on the complexity seed. Requires sending Ether.
    /// Uses block data for pseudo-randomness - NOT SECURE FOR HIGH-VALUE.
    /// @param complexitySeed A seed influencing the initial complexity and gene generation.
    /// @return The ID of the newly fabricated artifact.
    function fabricateArtifact(uint256 complexitySeed) external payable returns (uint256) {
        uint256 cost = getFabricationCost(complexitySeed);
        require(msg.value >= cost, "Insufficient Ether provided");

        uint256 newArtifactId = nextArtifactId++;
        address creator = msg.sender;

        // Refund excess Ether
        if (msg.value > cost) {
             payable(creator).transfer(msg.value - cost);
        }

        // --- Pseudo-Random Gene & Attribute Generation ---
        // WARNING: Using blockhash and block.timestamp is predictable.
        // This is for demonstration purposes only.
        uint256 randomnessSeed = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Use previous block hash
            block.timestamp,
            creator,
            complexitySeed,
            newArtifactId
        )));

        uint256[] memory generatedGenes = _generateGenes(randomnessSeed, complexitySeed);

        // Initial attributes (simple example)
        mapping(string => uint256) storage initialAttributes = artifacts[newArtifactId].attributes;
        // Add some initial attributes based on randomness/genes
        initialAttributes["Power"] = (generatedGenes[0] % 100) + 1;
        initialAttributes["Speed"] = (generatedGenes[1] % 100) + 1;
        attributeExists[newArtifactId]["Power"] = true;
        attributeExists[newArtifactId]["Speed"] = true;

        // --- Create Artifact ---
        artifacts[newArtifactId] = Artifact({
            id: newArtifactId,
            genes: generatedGenes, // Store immutable genes
            attributes: initialAttributes, // Store reference to the mapping
            fabricationTimestamp: block.timestamp,
            lastMutationTimestamp: 0, // No mutation yet
            evolutionCount: 0,
            isEnergized: false
        });

        // --- Assign Ownership (Manual) ---
        artifactOwners[newArtifactId] = creator;
        ownerArtifactCount[creator]++;

        emit ArtifactFabricated(newArtifactId, creator, cost);
        emit Transfer(address(0), creator, newArtifactId); // ERC721-like Transfer event for minting

        return newArtifactId;
    }

    /// @notice Energizes an artifact, making it eligible for mutation attempts.
    /// @dev Requires sending Ether. Only the artifact owner can energize it.
    /// @param artifactId The ID of the artifact to energize.
    function energizeArtifact(uint256 artifactId) external payable {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        require(artifactOwners[artifactId] == msg.sender, "Only artifact owner can energize");

        uint256 cost = getEnergyCost();
        require(msg.value >= cost, "Insufficient Ether provided");

        // Refund excess Ether
        if (msg.value > cost) {
             payable(msg.sender).transfer(msg.value - cost);
        }

        artifacts[artifactId].isEnergized = true;
        emit ArtifactEnergized(artifactId, msg.sender, cost);
    }

    /// @notice Attempts to mutate an energized artifact.
    /// @dev Mutation success is based on `MUTATION_CHANCE_PERCENT` using pseudo-randomness.
    /// Consumes the energized state whether mutation succeeds or fails. Only the owner can attempt mutation.
    /// Uses block data for pseudo-randomness - NOT SECURE FOR HIGH-VALUE.
    /// @param artifactId The ID of the artifact to attempt mutation on.
    function attemptMutation(uint256 artifactId) external {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        require(artifactOwners[artifactId] == msg.sender, "Only artifact owner can attempt mutation");
        require(artifacts[artifactId].isEnergized, "Artifact is not energized");

        // Consume energized state regardless of mutation success
        artifacts[artifactId].isEnergized = false;

        // --- Pseudo-Random Mutation Chance ---
        // WARNING: Using blockhash and block.timestamp is predictable.
        // This is for demonstration purposes only.
        uint256 randomnessSeed = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Use previous block hash
            block.timestamp,
            msg.sender,
            artifactId,
            artifacts[artifactId].evolutionCount // Add evolution count for variability
        )));

        uint256 chanceRoll = randomnessSeed % 100; // Roll a number between 0 and 99

        if (chanceRoll < MUTATION_CHANCE_PERCENT) {
            // Mutation successful
            artifacts[artifactId].evolutionCount++;
            artifacts[artifactId].lastMutationTimestamp = block.timestamp;

            _mutateAttributes(artifactId, randomnessSeed); // Mutate attributes based on new randomness

            emit ArtifactMutated(artifactId, artifacts[artifactId].evolutionCount);
        }
        // If mutation fails, nothing changes except `isEnergized` is set to false.
    }

    // --- Asset Management Functions (Manual ERC721-like) ---

    /// @notice Returns the number of artifacts owned by an address.
    /// @param owner The address to query the balance of.
    /// @return The number of artifacts owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return ownerArtifactCount[owner];
    }

    /// @notice Returns the owner of a specific artifact.
    /// @dev Throws if `artifactId` does not exist.
    /// @param artifactId The ID of the artifact to query the owner of.
    /// @return The address of the owner.
    function ownerOf(uint256 artifactId) public view returns (address) {
        address ownerAddr = artifactOwners[artifactId];
        require(ownerAddr != address(0), "Invalid artifact ID");
        return ownerAddr;
    }

    /// @notice Transfers ownership of an artifact from the caller to another address.
    /// @param to The address to transfer ownership to.
    /// @param artifactId The ID of the artifact to transfer.
    function transferArtifact(address to, uint256 artifactId) public {
        require(to != address(0), "Cannot transfer to the zero address");
        address currentOwner = ownerOf(artifactId); // Uses ownerOf check
        require(currentOwner == msg.sender, "Caller is not the owner");

        _transfer(currentOwner, to, artifactId);
    }

    /// @notice Approves another address to transfer a specific artifact on behalf of the owner.
    /// @param to The address to approve.
    /// @param artifactId The ID of the artifact to approve for.
    function approve(address to, uint256 artifactId) public {
        address currentOwner = ownerOf(artifactId); // Uses ownerOf check
        require(currentOwner == msg.sender || owner == msg.sender, "Caller is not the owner or approved operator"); // Simple operator concept: owner or contract owner

        approvedTransfers[artifactId] = to;
        emit Approval(to, artifactId);
    }

    /// @notice Gets the approved address for a single artifact.
    /// @param artifactId The ID of the artifact to query the approval of.
    /// @return The approved address, or address(0) if no address is approved.
    function getApproved(uint256 artifactId) public view returns (address) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        return approvedTransfers[artifactId];
    }

    /// @notice Transfers ownership of an artifact from one address to another.
    /// @dev The caller must be the current owner or the approved address.
    /// @param from The current owner of the artifact.
    /// @param to The address to transfer ownership to.
    /// @param artifactId The ID of the artifact to transfer.
    function transferFrom(address from, address to, uint256 artifactId) public {
        require(to != address(0), "Cannot transfer to the zero address");
        require(from != address(0), "Cannot transfer from the zero address");
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        require(ownerOf(artifactId) == from, "From address is not the owner");

        // Check if caller is the owner or the approved address
        require(msg.sender == from || msg.sender == approvedTransfers[artifactId], "Caller is not owner nor approved");

        _transfer(from, to, artifactId);
    }

    // --- View Functions ---

    /// @notice Retrieves all details for a specific artifact.
    /// @dev Note: This function returns the struct by value. Be mindful of gas costs for large structs.
    /// @param artifactId The ID of the artifact.
    /// @return The Artifact struct.
    function getArtifact(uint256 artifactId) external view returns (Artifact memory) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        // Create a temporary memory struct to return data
        Artifact memory artifactMemory = Artifact({
            id: artifacts[artifactId].id,
            genes: artifacts[artifactId].genes,
            attributes: new mapping(string => uint256)(), // Cannot return mapping directly, need to copy
            fabricationTimestamp: artifacts[artifactId].fabricationTimestamp,
            lastMutationTimestamp: artifacts[artifactId].lastMutationTimestamp,
            evolutionCount: artifacts[artifactId].evolutionCount,
            isEnergized: artifacts[artifactId].isEnergized
        });

        // Manually copy attributes for the return struct
        // Note: This requires knowing attribute names. A better approach might iterate a list of attribute keys if stored.
        // For this example, we'll access common attributes or rely on querying getArtifactAttributes.
        // A more robust implementation might store attribute keys in the struct or a separate mapping.
        // Since we don't store keys explicitly here, returning the full struct including the mapping requires special handling
        // or returning parts separately. Let's simplify: return common ones or use the dedicated getAttributes function.
        // Let's stick to returning common ones defined in _mutateAttributes for demonstration.
        artifactMemory.attributes["Power"] = artifacts[artifactId].attributes["Power"];
        artifactMemory.attributes["Speed"] = artifacts[artifactId].attributes["Speed"];
        artifactMemory.attributes["Durability"] = artifacts[artifactId].attributes["Durability"];
        artifactMemory.attributes["Intelligence"] = artifacts[artifactId].attributes["Intelligence"];


        return artifactMemory;
    }


    /// @notice Retrieves the genes of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return An array of gene values.
    function getArtifactGenes(uint256 artifactId) external view returns (uint256[] memory) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        return artifacts[artifactId].genes;
    }

    /// @notice Retrieves the attributes of a specific artifact.
    /// @dev Returns attribute names and values as separate arrays.
    /// Requires knowing the possible attribute names or tracking them better internally.
    /// This example returns values for pre-defined attribute names. A more advanced version
    /// could iterate through known keys or store keys in the struct.
    /// @param artifactId The ID of the artifact.
    /// @return attributeNames An array of attribute names.
    /// @return attributeValues An array of attribute values corresponding to names.
    function getArtifactAttributes(uint256 artifactId) external view returns (string[] memory attributeNames, uint256[] memory attributeValues) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");

        // Define the list of possible attribute names. In a real app, this might be dynamic
        // or stored elsewhere. For this example, we hardcode known ones.
        string[] memory knownAttributeNames = new string[](4);
        knownAttributeNames[0] = "Power";
        knownAttributeNames[1] = "Speed";
        knownAttributeNames[2] = "Durability";
        knownAttributeNames[3] = "Intelligence";

        uint256 count = 0;
        // Count how many of these known attributes exist
        for(uint i = 0; i < knownAttributeNames.length; i++) {
            if (attributeExists[artifactId][knownAttributeNames[i]]) {
                count++;
            }
        }

        attributeNames = new string[](count);
        attributeValues = new uint256[](count);
        uint256 currentIndex = 0;

        // Populate arrays with existing attributes
        for(uint i = 0; i < knownAttributeNames.length; i++) {
             if (attributeExists[artifactId][knownAttributeNames[i]]) {
                 attributeNames[currentIndex] = knownAttributeNames[i];
                 attributeValues[currentIndex] = artifacts[artifactId].attributes[knownAttributeNames[i]];
                 currentIndex++;
             }
        }

        return (attributeNames, attributeValues);
    }


    /// @notice Retrieves the evolution count of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return The number of times the artifact has successfully mutated.
    function getArtifactEvolutionCount(uint256 artifactId) external view returns (uint256) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        return artifacts[artifactId].evolutionCount;
    }

    /// @notice Retrieves the fabrication timestamp of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return The timestamp when the artifact was fabricated.
    function getArtifactFabricationTimestamp(uint256 artifactId) external view returns (uint256) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        return artifacts[artifactId].fabricationTimestamp;
    }

     /// @notice Retrieves the energized status of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return True if the artifact is currently energized, false otherwise.
    function isArtifactEnergized(uint256 artifactId) external view returns (bool) {
        require(_isValidArtifact(artifactId), "Invalid artifact ID");
        return artifacts[artifactId].isEnergized;
    }

    /// @notice Returns the total number of artifacts ever fabricated by this contract.
    /// @return The total count of artifacts.
    function getTotalArtifacts() external view returns (uint256) {
        return nextArtifactId - 1;
    }

    /// @notice Calculates the required Ether cost for fabricating a new artifact with a given complexity.
    /// @dev Simple linear cost calculation: BASE_COST + complexity * small_factor.
    /// @param complexitySeed The complexity seed for calculation.
    /// @return The calculated cost in wei.
    function getFabricationCost(uint256 complexitySeed) public view returns (uint256) {
        // Prevent overflow for very large complexity seeds
        uint256 effectiveComplexity = complexitySeed > 100 ? 100 : complexitySeed; // Cap complexity effect
        return FABRICATION_BASE_COST + (effectiveComplexity * FABRICATION_BASE_COST / 10); // Example: 10% of base cost per complexity unit
    }

    /// @notice Returns the current Ether cost to energize an artifact.
    /// @return The energy cost in wei.
    function getEnergyCost() public view returns (uint256) {
        return ENERGY_COST_FACTOR;
    }

     /// @notice Returns the currently configured minimum and maximum values allowed for generated genes.
    /// @return min The minimum allowed gene value.
    /// @return max The maximum allowed gene value.
    function getAllowedFabricationGeneRange() external view returns (uint256 min, uint256 max) {
        return (allowedGeneRangeMin, allowedGeneRangeMax);
    }


    // --- Admin Functions (Owner Only) ---

    /// @notice Sets the base Ether cost for fabricating new artifacts.
    /// @param newCost The new base cost in wei.
    function setFabricationBaseCost(uint256 newCost) external onlyOwner {
        uint256 oldValue = FABRICATION_BASE_COST;
        FABRICATION_BASE_COST = newCost;
        emit ParameterUpdated("FABRICATION_BASE_COST", oldValue, newCost);
    }

    /// @notice Sets the Ether cost factor for energizing artifacts.
    /// @param newFactor The new cost factor in wei.
    function setEnergyCostFactor(uint256 newFactor) external onlyOwner {
        uint256 oldValue = ENERGY_COST_FACTOR;
        ENERGY_COST_FACTOR = newFactor;
        emit ParameterUpdated("ENERGY_COST_FACTOR", oldValue, newFactor);
    }

    /// @notice Sets the percentage chance for successful mutation attempts.
    /// @param newChancePercent The new chance (0-100).
    function setMutationChance(uint256 newChancePercent) external onlyOwner {
        require(newChancePercent <= 100, "Chance percentage cannot exceed 100");
        uint256 oldValue = MUTATION_CHANCE_PERCENT;
        MUTATION_CHANCE_PERCENT = newChancePercent;
        emit ParameterUpdated("MUTATION_CHANCE_PERCENT", oldValue, newChancePercent);
    }

    /// @notice Sets the maximum number of dynamic attributes an artifact can have.
    /// @param newMax The new maximum number of attributes.
    function setMaxAttributes(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Max attributes must be greater than 0");
        uint256 oldValue = MAX_ATTRIBUTES;
        MAX_ATTRIBUTES = newMax;
         emit ParameterUpdated("MAX_ATTRIBUTES", oldValue, newMax);
    }

     /// @notice Sets the allowed range [min, max] for initial gene values during fabrication.
    /// @param min The new minimum allowed gene value.
    /// @param max The new maximum allowed gene value.
    function setAllowedFabricationGeneRange(uint256 min, uint256 max) external onlyOwner {
        require(min < max, "Min must be less than max");
        uint256 oldMin = allowedGeneRangeMin;
        uint256 oldMax = allowedGeneRangeMax;
        allowedGeneRangeMin = min;
        allowedGeneRangeMax = max;
        emit ParameterUpdated("allowedGeneRangeMin", oldMin, min);
        emit ParameterUpdated("allowedGeneRangeMax", oldMax, max);
    }


    /// @notice Allows the contract owner to withdraw the accumulated Ether balance.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    // --- Internal Helper Functions ---

    /// @dev Generates initial gene values for a new artifact based on randomness and complexity.
    /// Uses simple modulo arithmetic on the randomness seed.
    /// WARNING: Based on predictable block data.
    /// @param randomnessSeed The seed derived from block data, sender, etc.
    /// @param complexitySeed The complexity input from the user.
    /// @return An array of generated gene values.
    function _generateGenes(uint256 randomnessSeed, uint256 complexitySeed) internal view returns (uint256[] memory) {
        // Example: Generate a fixed number of genes (e.g., 4 genes)
        // Gene count could also be influenced by complexitySeed if desired.
        uint256 geneCount = 4; // Fixed gene count for simplicity
        uint256[] memory genes = new uint256[](geneCount);

        uint256 currentSeed = randomnessSeed;

        for (uint i = 0; i < geneCount; i++) {
             // Generate a gene value within the allowed range [min, max]
             // (currentSeed % (max - min + 1)) gives a value in [0, max-min]
             genes[i] = (currentSeed % (allowedGeneRangeMax - allowedGeneRangeMin + 1)) + allowedGeneRangeMin;

             // Update seed for the next gene (simple LCG-like step)
             currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, complexitySeed, i)));
        }

        return genes;
    }

     /// @dev Mutates attributes of an artifact based on randomness.
     /// Can change existing attributes or add new ones if below MAX_ATTRIBUTES.
     /// Uses simple modulo arithmetic on the randomness seed.
     /// WARNING: Based on predictable block data.
     /// @param artifactId The ID of the artifact to mutate.
     /// @param randomnessSeed The seed derived from block data, sender, etc.
    function _mutateAttributes(uint256 artifactId, uint256 randomnessSeed) internal {
        // Get a reference to the artifact's attributes in storage
        mapping(string => uint256) storage artifactAttributes = artifacts[artifactId].attributes;

        // Define potential attribute names (could be more dynamic)
        string[] memory potentialAttributeNames = new string[](4);
        potentialAttributeNames[0] = "Power";
        potentialAttributeNames[1] = "Speed";
        potentialAttributeNames[2] = "Durability";
        potentialAttributeNames[3] = "Intelligence";

        uint256 currentSeed = randomnessSeed;

        // Determine which attribute to mutate or add
        // Use randomness to select an index from potentialAttributeNames
        uint256 attributeIndexToMutate = (currentSeed % potentialAttributeNames.length);
        string memory attributeName = potentialAttributeNames[attributeIndexToMutate];

        currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, artifactId, block.timestamp))); // Update seed

        // Determine the magnitude/direction of the mutation
        // Example: Mutate value by +/- up to 10% of current value, or add a base value if new.
        uint256 currentValue = artifactAttributes[attributeName];
        uint256 mutationAmount;
        bool isNewAttribute = !attributeExists[artifactId][attributeName];

        if (isNewAttribute) {
            // Add a new attribute (if within max limit)
            uint256 currentAttributeCount = 0;
            for(uint i = 0; i < potentialAttributeNames.length; i++) {
                if (attributeExists[artifactId][potentialAttributeNames[i]]) {
                     currentAttributeCount++;
                }
            }

            if (currentAttributeCount < MAX_ATTRIBUTES) {
                 // Generate a base value for the new attribute (e.g., 1 to 50)
                 mutationAmount = (currentSeed % 50) + 1;
                 artifactAttributes[attributeName] = mutationAmount;
                 attributeExists[artifactId][attributeName] = true;
                 emit AttributeChanged(artifactId, attributeName, mutationAmount);
            }
            // else: Max attributes reached, no new attribute added. Mutation attempt fails silently for this attribute name.

        } else {
            // Mutate an existing attribute
            uint256 delta = (currentSeed % (currentValue / 10 + 1)); // Change up to ~10%
            bool add = (currentSeed % 2 == 0); // 50% chance to add or subtract

            if (add) {
                 mutationAmount = currentValue + delta;
            } else {
                 // Ensure value doesn't go below a minimum (e.g., 1)
                 mutationAmount = (currentValue > delta) ? currentValue - delta : 1;
            }

            // Update attribute value
            artifactAttributes[attributeName] = mutationAmount;
            emit AttributeChanged(artifactId, attributeName, mutationAmount);
        }

        // Could potentially mutate more attributes or with more complex logic
    }


    /// @dev Internal check to ensure an artifact ID is valid (exists).
    /// @param artifactId The ID to check.
    /// @return True if the artifact exists, false otherwise.
    function _isValidArtifact(uint256 artifactId) internal view returns (bool) {
        // Artifact ID 0 is invalid as nextArtifactId starts at 1
        // Check if owner mapping entry exists (more gas efficient than checking the struct existence directly for a non-zero address)
        return artifactOwners[artifactId] != address(0);
    }

     /// @dev Internal function to handle the core transfer logic.
     /// @param from The address losing ownership.
     /// @param to The address gaining ownership.
     /// @param artifactId The ID of the artifact to transfer.
    function _transfer(address from, address to, uint256 artifactId) internal {
        // Ownership checks and validity checks should happen in the public transfer functions
        // Here we just perform the state changes

        ownerArtifactCount[from]--;
        artifactOwners[artifactId] = to;
        ownerArtifactCount[to]++;

        _clearApproval(artifactId); // Clear any existing approval on this artifact

        emit Transfer(from, to, artifactId);
    }

    /// @dev Internal function to clear the approved address for an artifact.
    /// @param artifactId The ID of the artifact.
    function _clearApproval(uint256 artifactId) internal {
        if (approvedTransfers[artifactId] != address(0)) {
            delete approvedTransfers[artifactId];
             // Note: ERC721 standard emits Approval(address(0), artifactId) here.
             // We can add that for compliance if desired, but keeping it simple for "non-duplicate".
        }
    }
}
```