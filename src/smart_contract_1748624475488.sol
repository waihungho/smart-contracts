Okay, let's create a smart contract concept around "Evolving Digital Organisms" or "Nodes" that live and mutate on-chain. This combines concepts of generative systems, dynamic NFTs, and simple simulation within the constraints of Solidity.

It will be called `GenesisProtocol` and manage unique `Node` entities, each with dynamic "Genetic Code" and "Phenotypic Traits" that can evolve.

**Outline and Function Summary**

**Contract Name:** `GenesisProtocol`

**Core Concept:** A protocol for creating, managing, and evolving unique digital entities called "Nodes". Nodes possess dynamic on-chain "Genetic Code" (numerical array) and "Phenotypic Traits" (string array) that change based on triggered "Mutations", "Environmental Effects", and "Breeding" processes. Nodes are represented as semi-soulbound NFTs (ERC721), primarily intended to reside with their owner but with limited transferability options. The protocol includes mechanics for reputation, status, and simple generative metadata.

**Advanced/Creative Concepts Used:**
1.  **Dynamic On-Chain State:** Node attributes (genes, traits, reputation, status) change over time based on protocol interactions.
2.  **Simulated Evolution/Mutation:** Deterministic processes triggered by users or conditions modify Node state.
3.  **Generative Attributes:** Traits can be derived or modified based on underlying genetic code.
4.  **Breeding Mechanism:** Combining attributes from two parent Nodes to create a new one.
5.  **Semi-Soulbound/Reputation:** While ERC721, mechanisms tie reputation/status to the Node, hinting at SBT-like properties.
6.  **On-Chain Querying/Simulation:** Functions allow querying nodes by traits and simulating future mutations without state change.
7.  **Environmental Effects:** External data (simulated) can influence Node evolution.

**Inheritance:** ERC721, Ownable

**State Variables Summary:**
*   `_nextTokenId`: Counter for unique Node IDs.
*   `nodeGenes`: Mapping Node ID to `NodeGenes` struct (genetic code, mutation count).
*   `nodeTraits`: Mapping Node ID to `NodeTraits` struct (phenotypic traits, last mutation time).
*   `nodeReputation`: Mapping Node ID to reputation score.
*   `nodeStatus`: Mapping Node ID to `NodeStatus` enum.
*   `nodeCreationTime`: Mapping Node ID to creation timestamp.
*   `mutationBaseChance`: Base probability factor for mutation (owner controlled).
*   `breedingFee`: Fee required to initiate breeding (owner controlled).
*   `paused`: Protocol pause state.
*   `protocolBalance`: Accumulator for protocol fees (e.g., breeding fees).

**Events Summary:**
*   `NodeCreated(uint256 indexed tokenId, address indexed owner, string[] initialTraits)`
*   `NodeMutated(uint256 indexed tokenId, uint[] newGenes, string[] newTraits)`
*   `NodeBred(uint256 indexed newNodeId, uint256 indexed parent1Id, uint256 indexed parent2Id, address indexed owner)`
*   `ReputationUpdated(uint256 indexed tokenId, uint256 newReputation)`
*   `StatusUpdated(uint256 indexed tokenId, NodeStatus newStatus)`
*   `EnvironmentalEffectApplied(uint256 indexed tokenId, bytes effectData)`
*   `ProtocolPaused(address indexed pauser)`
*   `ProtocolUnpaused(address indexed unpauser)`

**Functions Summary (>= 20):**

1.  `constructor()`: Initializes the contract, ERC721, and sets owner/initial parameters.
2.  `createGenesisNode(string[] memory initialTraits)`: Mints a new Node (ERC721), assigns initial traits, generates starting genes, and sets initial reputation/status.
3.  `getNodeGenes(uint256 nodeId) view`: Retrieves the raw genetic code of a Node.
4.  `getNodeTraits(uint256 nodeId) view`: Retrieves the phenotypic traits of a Node.
5.  `getNodeReputation(uint256 nodeId) view`: Retrieves the current reputation score of a Node.
6.  `getNodeStatus(uint256 nodeId) view`: Retrieves the current status of a Node.
7.  `getNodeCreationTime(uint256 nodeId) view`: Retrieves the creation timestamp of a Node.
8.  `getTotalNodes() view`: Returns the total number of Nodes created.
9.  `triggerNodeMutation(uint256 nodeId)`: Allows the Node owner (or approved) to attempt to trigger a mutation event based on chance and other factors.
10. `applyEnvironmentalEffect(uint256 nodeId, bytes memory effectData)`: Simulates an external environmental influence that can modify Node genes/traits or reputation. The effect is derived from `effectData`.
11. `proposeBreeding(uint256 node1, uint256 node2) payable`: Initiates a breeding process between two Nodes owned/approved by the caller. Requires payment of the `breedingFee`. (Simplified: immediately finalizes breeding for this example).
12. `generateNodeMetadata(uint256 nodeId) internal view returns (string memory)`: Internal helper to generate the dynamic JSON metadata for a Node's `tokenURI`. Includes genes, traits, status, reputation, etc.
13. `tokenURI(uint256 tokenId) override view returns (string memory)`: Standard ERC721 function. Calls `generateNodeMetadata` and formats it as a data URI.
14. `simulateFutureMutation(uint256 nodeId, bytes memory simulationSeed) view returns (uint[] memory simulatedGenes, string[] memory simulatedTraits)`: A view function that simulates *one possible* outcome of a mutation for a given Node using provided entropy (`simulationSeed`) without changing state.
15. `queryNodesByTrait(string memory trait) view returns (uint256[] memory nodeIds)`: Queries all existing Nodes and returns a list of IDs for Nodes that possess a specific phenotypic trait. (Note: Iterating all tokens is gas-intensive for large collections).
16. `lodgeComplaintAgainstNode(uint256 nodeId, string memory reason)`: Allows a user to flag a Node. Sets its status to `Flagged` and potentially reduces reputation.
17. `resolveComplaint(uint256 nodeId, bool validComplaint)`: Owner-only function to review and resolve a complaint, adjusting status and reputation accordingly.
18. `setNodeStatus(uint256 nodeId, NodeStatus status)`: Owner-only function to manually set a Node's status.
19. `setMutationParams(uint privateBaseChance)`: Owner-only function to update mutation parameters.
20. `setBreedingParams(uint privateFee)`: Owner-only function to update breeding parameters.
21. `pauseProtocol()`: Owner-only function to pause key operations (mutation, breeding).
22. `unpauseProtocol()`: Owner-only function to unpause the protocol.
23. `withdrawProtocolFees()`: Owner-only function to withdraw accumulated protocol balance (e.g., breeding fees).
24. `transferNode(address from, address to, uint256 tokenId)`: ERC721 `transferFrom` alias - kept for clarity but standard ERC721.
25. `updateNodeReputation(uint256 nodeId, int256 reputationChange)`: Internal/Owner helper to adjust reputation. Could be exposed for specific privileged roles.

*(Adding a few more to ensure >= 20 and cover ERC721 essentials)*
26. `balanceOf(address owner) view override returns (uint256)`: Standard ERC721.
27. `ownerOf(uint256 tokenId) view override returns (address)`: Standard ERC721.
28. `approve(address to, uint256 tokenId) override`: Standard ERC721.
29. `getApproved(uint256 tokenId) view override returns (address)`: Standard ERC721.
30. `setApprovalForAll(address operator, bool approved) override`: Standard ERC721.
31. `isApprovedForAll(address owner, address operator) view override returns (bool)`: Standard ERC721.
32. `supportsInterface(bytes4 interfaceId) view override returns (bool)`: Standard ERC721.

Total functions: 32+ (including standard overrides and internal helpers, definitely > 20 public/external).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary provided above the codeblock.

contract GenesisProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    // --- Structs ---
    struct NodeGenes {
        uint[] geneticCode; // Represents underlying numerical traits/potential
        uint mutationCount;
    }

    struct NodeTraits {
        string[] phenotypicTraits; // Represents observable traits/characteristics
        uint lastMutationTime;
    }

    enum NodeStatus { Active, Dormant, Mutating, Flagged, Bred }

    // --- State Variables ---
    mapping(uint256 => NodeGenes) private nodeGenes;
    mapping(uint256 => NodeTraits) private nodeTraits;
    mapping(uint256 => uint256) private nodeReputation;
    mapping(uint256 => NodeStatus) private nodeStatus;
    mapping(uint256 => uint256) private nodeCreationTime; // Timestamp

    uint private mutationBaseChance; // Base chance multiplier (e.g., 100 = 10%)
    uint private breedingFee; // Fee in wei to initiate breeding
    bool private paused;

    uint private protocolBalance; // Accumulated fees

    // --- Events ---
    event NodeCreated(uint256 indexed tokenId, address indexed owner, string[] initialTraits);
    event NodeMutated(uint256 indexed tokenId, uint[] newGenes, string[] newTraits);
    event NodeBred(uint256 indexed newNodeId, uint256 indexed parent1Id, uint256 indexed parent2Id, address indexed owner);
    event ReputationUpdated(uint256 indexed tokenId, uint256 newReputation);
    event StatusUpdated(uint256 indexed tokenId, NodeStatus newStatus);
    event EnvironmentalEffectApplied(uint256 indexed tokenId, bytes effectData);
    event ProtocolPaused(address indexed pauser);
    event ProtocolUnpaused(address indexed unpauser);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    modifier onlyNodeOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to interact with this Node");
        _;
    }

    modifier nodeExists(uint256 tokenId) {
        require(_exists(tokenId), "Node does not exist");
        _;
    }

    // --- Constructor ---
    constructor(uint initialMutationChance, uint initialBreedingFee) ERC721("GenesisNode", "GENN") Ownable(msg.sender) {
        mutationBaseChance = initialMutationChance;
        breedingFee = initialBreedingFee;
        paused = false;
    }

    // --- Core Genesis/Creation Functions ---

    /// @notice Creates a new Genesis Node. The first Node in a lineage.
    /// @param initialTraits The initial phenotypic traits for the Node.
    /// @return The ID of the newly created Node.
    function createGenesisNode(string[] memory initialTraits)
        external whenNotPaused
        returns (uint256)
    {
        uint256 newNodeId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(_msgSender(), newNodeId);

        // Simulate initial random genes (example: 5 genes with values up to 100)
        uint[] memory genes = new uint[](5);
        for (uint i = 0; i < genes.length; i++) {
             // Basic on-chain randomness simulation - NOT secure for high-value outcomes
            genes[i] = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, newNodeId, i, block.difficulty))) % 101;
        }

        nodeGenes[newNodeId] = NodeGenes({
            geneticCode: genes,
            mutationCount: 0
        });

        nodeTraits[newNodeId] = NodeTraits({
            phenotypicTraits: initialTraits,
            lastMutationTime: block.timestamp
        });

        nodeReputation[newNodeId] = 100; // Starting reputation
        nodeStatus[newNodeId] = NodeStatus.Active;
        nodeCreationTime[newNodeId] = block.timestamp;

        emit NodeCreated(newNodeId, _msgSender(), initialTraits);
        return newNodeId;
    }

    // --- Node State & Query Functions (>= 20 count target: 3-8) ---

    /// @notice Retrieves the genetic code of a Node.
    /// @param nodeId The ID of the Node.
    /// @return An array representing the Node's genetic code.
    function getNodeGenes(uint256 nodeId)
        public view nodeExists(nodeId)
        returns (uint[] memory)
    {
        return nodeGenes[nodeId].geneticCode;
    }

    /// @notice Retrieves the phenotypic traits of a Node.
    /// @param nodeId The ID of the Node.
    /// @return An array of strings representing the Node's traits.
    function getNodeTraits(uint256 nodeId)
        public view nodeExists(nodeId)
        returns (string[] memory)
    {
        return nodeTraits[nodeId].phenotypicTraits;
    }

    /// @notice Retrieves the reputation score of a Node.
    /// @param nodeId The ID of the Node.
    /// @return The reputation score.
    function getNodeReputation(uint256 nodeId)
        public view nodeExists(nodeId)
        returns (uint256)
    {
        return nodeReputation[nodeId];
    }

    /// @notice Retrieves the status of a Node.
    /// @param nodeId The ID of the Node.
    /// @return The NodeStatus enum value.
    function getNodeStatus(uint256 nodeId)
        public view nodeExists(nodeId)
        returns (NodeStatus)
    {
        return nodeStatus[nodeId];
    }

    /// @notice Retrieves the creation timestamp of a Node.
    /// @param nodeId The ID of the Node.
    /// @return The creation timestamp (Unix time).
    function getNodeCreationTime(uint256 nodeId)
        public view nodeExists(nodeId)
        returns (uint256)
    {
        return nodeCreationTime[nodeId];
    }

    /// @notice Returns the total number of Nodes created so far.
    /// @return The total count of Nodes.
    function getTotalNodes() public view returns (uint256) {
        return _nextTokenId.current();
    }

    // --- Evolution, Mutation & Interaction Functions (>= 20 count target: 9-12) ---

    /// @notice Attempts to trigger a mutation event for a Node.
    /// Chance of mutation is based on `mutationBaseChance`, Node's mutation count, and time since last mutation.
    /// @param nodeId The ID of the Node to mutate.
    function triggerNodeMutation(uint256 nodeId)
        external whenNotPaused onlyNodeOwner(nodeId) nodeExists(nodeId)
    {
        NodeGenes storage genes = nodeGenes[nodeId];
        NodeTraits storage traits = nodeTraits[nodeId];

        // Simplified mutation logic: Higher mutation count/less recent mutation increases chance
        uint currentChance = mutationBaseChance;
        currentChance += genes.mutationCount * 5; // Increase chance by 5% per previous mutation
        if (block.timestamp - traits.lastMutationTime > 30 days) { // Increase chance if dormant
            currentChance += 20;
        }

        // Roll for mutation (simplified randomness)
        uint roll = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nodeId, genes.mutationCount, block.difficulty))) % 1000; // Roll out of 1000

        if (roll < currentChance) { // Mutation triggered
            // Apply mutation to genes (example: randomly change a gene value)
            uint geneIndexToMutate = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nodeId, roll, "gene"))) % genes.geneticCode.length;
             // Randomly add/subtract up to 10, ensuring non-negative
            int change = int(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nodeId, roll, "change"))) % 21) - 10; // Range -10 to +10
            if (change < 0 && uint(-change) > genes.geneticCode[geneIndexToMutate]) {
                 genes.geneticCode[geneIndexToMutate] = 0;
            } else {
                 genes.geneticCode[geneIndexToMutate] = uint(int(genes.geneticCode[geneIndexToMutate]) + change);
            }


            // Apply mutation to traits (example: add a derived trait based on genes)
            traits.phenotypicTraits = _deriveTraitsFromGenes(genes.geneticCode);

            genes.mutationCount++;
            traits.lastMutationTime = block.timestamp;
            nodeStatus[nodeId] = NodeStatus.Mutating; // Temporarily change status

            emit NodeMutated(nodeId, genes.geneticCode, traits.phenotypicTraits);

             // Mutation completed, set back to active after a short period (simulated)
            // In a real system, this might be handled by a separate function call or time-based logic.
            // For simplicity here, we just update the status immediately after the event.
             nodeStatus[nodeId] = NodeStatus.Active;

        } else {
            // No mutation this time, maybe slightly increase reputation for trying
            _updateNodeReputation(nodeId, 1);
        }
    }

     /// @notice Simulates an external environmental effect on a Node.
     /// The effect is determined by the provided `effectData`.
     /// @param nodeId The ID of the Node to affect.
     /// @param effectData Arbitrary data representing the environmental effect.
     function applyEnvironmentalEffect(uint256 nodeId, bytes memory effectData)
         external whenNotPaused nodeExists(nodeId) // Can be called by anyone, effect is mediated
     {
         NodeGenes storage genes = nodeGenes[nodeId];
         NodeTraits storage traits = nodeTraits[nodeId];

         // Simplified effect logic: use hash of effectData to influence a gene
         uint effectSeed = uint(keccak256(effectData));
         uint geneIndexToAffect = effectSeed % genes.geneticCode.length;

         // Example effect: gene value modified based on effectData and timestamp
         int effectStrength = int(uint(keccak256(abi.encodePacked(effectSeed, block.timestamp))) % 31) - 15; // Range -15 to +15

         if (effectStrength < 0 && uint(-effectStrength) > genes.geneticCode[geneIndexToAffect]) {
              genes.geneticCode[geneIndexToAffect] = 0;
         } else {
              genes.geneticCode[geneIndexToAffect] = uint(int(genes.geneticCode[geneIndexToAffect]) + effectStrength);
         }

         // Environmental effects can also influence traits or reputation
         traits.phenotypicTraits = _deriveTraitsFromGenes(genes.geneticCode);
         _updateNodeReputation(nodeId, effectStrength > 0 ? 2 : -1); // Positive effect boosts rep, negative slightly reduces

         emit EnvironmentalEffectApplied(nodeId, effectData);
         emit NodeMutated(nodeId, genes.geneticCode, traits.phenotypicTraits); // Environmental effect is a form of mutation
     }


    /// @notice Initiates and finalizes the breeding process between two Nodes.
    /// Requires ownership/approval for both Nodes and payment of the breeding fee.
    /// @param node1 The ID of the first parent Node.
    /// @param node2 The ID of the second parent Node.
    function proposeBreeding(uint256 node1, uint256 node2)
        external payable whenNotPaused
        onlyNodeOwner(node1) // Caller must own/be approved for node1
        onlyNodeOwner(node2) // Caller must own/be approved for node2
        nodeExists(node1)
        nodeExists(node2)
    {
        require(node1 != node2, "Cannot breed a Node with itself");
        require(msg.value >= breedingFee, "Insufficient breeding fee");

        protocolBalance += msg.value; // Collect the fee

        // Simplified Breeding Logic:
        // Create a new Node, inherit genes/traits by mixing parents

        uint256 newNodeId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(_msgSender(), newNodeId);

        uint[] memory genes1 = nodeGenes[node1].geneticCode;
        uint[] memory genes2 = nodeGenes[node2].geneticCode;
        uint[] memory childGenes = new uint[](genes1.length); // Assuming same gene count

        // Simple gene mixing: Alternate genes from parents
        for (uint i = 0; i < genes1.length; i++) {
            if (i % 2 == 0) {
                childGenes[i] = genes1[i];
            } else {
                childGenes[i] = genes2[i];
            }
        }

        // Add a slight random mutation chance during breeding
        uint breedingMutationRoll = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, node1, node2, "breeding_mutation"))) % 100;
        if (breedingMutationRoll < 10) { // 10% chance of a small breeding mutation
            uint geneIndexToMutate = breedingMutationRoll % childGenes.length;
            int change = int(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, node1, node2, "breeding_change"))) % 11) - 5; // Range -5 to +5
             if (change < 0 && uint(-change) > childGenes[geneIndexToMutate]) {
                 childGenes[geneIndexToMutate] = 0;
             } else {
                 childGenes[geneIndexToMutate] = uint(int(childGenes[geneIndexToMutate]) + change);
            }
        }

        string[] memory traits1 = nodeTraits[node1].phenotypicTraits;
        string[] memory traits2 = nodeTraits[node2].phenotypicTraits;
        // Simple trait mixing: Combine parent traits (avoid duplicates if necessary, simplified here)
        string[] memory childTraits = new string[](traits1.length + traits2.length);
        uint traitIndex = 0;
        for(uint i = 0; i < traits1.length; i++) {
            childTraits[traitIndex] = traits1[i];
            traitIndex++;
        }
         for(uint i = 0; i < traits2.length; i++) {
            childTraits[traitIndex] = traits2[i];
            traitIndex++;
        }
        // Also add traits derived from the child's genes
        string[] memory derivedTraits = _deriveTraitsFromGenes(childGenes);
         string[] memory finalTraits = new string[](childTraits.length + derivedTraits.length);
         uint finalTraitIndex = 0;
         for(uint i = 0; i < childTraits.length; i++) {
            finalTraits[finalTraitIndex] = childTraits[i];
            finalTraitIndex++;
         }
         for(uint i = 0; i < derivedTraits.length; i++) {
            finalTraits[finalTraitIndex] = derivedTraits[i];
            finalTraitIndex++;
         }


        nodeGenes[newNodeId] = NodeGenes({
            geneticCode: childGenes,
            mutationCount: 0
        });

        nodeTraits[newNodeId] = NodeTraits({
            phenotypicTraits: finalTraits,
            lastMutationTime: block.timestamp // Start timer for mutations
        });

        nodeReputation[newNodeId] = (nodeReputation[node1] + nodeReputation[node2]) / 2; // Average reputation
        nodeStatus[newNodeId] = NodeStatus.Bred; // Bred status initially
        nodeCreationTime[newNodeId] = block.timestamp;

        // Update parent status slightly? (e.g., temporarily change to 'Bred', reduce stamina)
        nodeStatus[node1] = NodeStatus.Active; // Reset parent status after breeding
        nodeStatus[node2] = NodeStatus.Active;

        emit NodeBred(newNodeId, node1, node2, _msgSender());
    }

    /// @notice A generic function for Nodes to interact with each other or the protocol.
    /// The specific effect depends on the `interactionData`.
    /// @param nodeId The ID of the Node initiating or being affected by the interaction.
    /// @param interactionData Arbitrary data defining the interaction context/type.
    function interactWithNode(uint256 nodeId, bytes memory interactionData)
        external whenNotPaused nodeExists(nodeId)
    {
        // Example interaction: `interactionData` length influences reputation gain/loss
        // More complex interactions could trigger specific state changes based on data parsing
        int reputationChange = int(interactionData.length) / 10 - 5; // Example: len=50 -> +0, len=0 -> -5, len=100 -> +5

        _updateNodeReputation(nodeId, reputationChange);

        // Maybe interaction also adds a small chance of spontaneous mutation?
        uint interactionMutationRoll = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nodeId, interactionData))) % 1000;
        if (interactionMutationRoll < 50) { // 5% chance
            // Trigger a minor mutation
            NodeGenes storage genes = nodeGenes[nodeId];
            uint geneIndexToMutate = interactionMutationRoll % genes.geneticCode.length;
            int change = int(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nodeId, interactionData, "spont_mut"))) % 5) - 2; // Range -2 to +2
            if (change < 0 && uint(-change) > genes.geneticCode[geneIndexToMutate]) {
                 genes.geneticCode[geneIndexToMutate] = 0;
            } else {
                 genes.geneticCode[geneIndexToMutate] = uint(int(genes.geneticCode[geneIndexToMutate]) + change);
            }
            nodeTraits[nodeId].phenotypicTraits = _deriveTraitsFromGenes(genes.geneticCode);
             emit NodeMutated(nodeId, genes.geneticCode, nodeTraits[nodeId].phenotypicTraits);
        }
    }


    // --- Reputation & Status Management (>= 20 count target: 13-17) ---

    /// @notice Allows a user to lodge a complaint against a Node, potentially affecting its status and reputation.
    /// @param nodeId The ID of the Node being complained about.
    /// @param reason A string describing the reason for the complaint.
    function lodgeComplaintAgainstNode(uint256 nodeId, string memory reason)
        external whenNotPaused nodeExists(nodeId)
    {
        // Simplified: Mark as flagged, slight reputation reduction
        nodeStatus[nodeId] = NodeStatus.Flagged;
        _updateNodeReputation(nodeId, -5); // Small penalty for being flagged

        // In a real system, this would trigger a governance process or review
        // log the reason somehow if necessary, but storing arbitrary strings on-chain is costly.
        // For this example, we just change state.
        emit StatusUpdated(nodeId, NodeStatus.Flagged);
    }

    /// @notice Owner function to resolve a complaint against a Node.
    /// @param nodeId The ID of the Node.
    /// @param validComplaint True if the complaint was found valid, false otherwise.
    function resolveComplaint(uint256 nodeId, bool validComplaint)
        external onlyOwner whenNotPaused nodeExists(nodeId)
    {
        require(nodeStatus[nodeId] == NodeStatus.Flagged, "Node is not currently flagged");

        if (validComplaint) {
            // Further penalty or action for valid complaint
            _updateNodeReputation(nodeId, -20);
            nodeStatus[nodeId] = NodeStatus.Dormant; // Example: Valid complaint makes it dormant
             emit StatusUpdated(nodeId, NodeStatus.Dormant);
        } else {
            // Complaint invalid, remove flag, perhaps reputation recovery
            _updateNodeReputation(nodeId, 10); // Recover some reputation
            nodeStatus[nodeId] = NodeStatus.Active; // Reset status
             emit StatusUpdated(nodeId, NodeStatus.Active);
        }
    }

    /// @notice Owner function to manually set a Node's status.
    /// Useful for administrative purposes or specific protocol events.
    /// @param nodeId The ID of the Node.
    /// @param status The new status for the Node.
    function setNodeStatus(uint256 nodeId, NodeStatus status)
        external onlyOwner nodeExists(nodeId)
    {
        nodeStatus[nodeId] = status;
        emit StatusUpdated(nodeId, status);
    }


     /// @notice Internal helper to update a Node's reputation, ensuring it stays within bounds (e.g., 0-200).
     /// @param nodeId The ID of the Node.
     /// @param reputationChange The amount to add to reputation (can be negative).
     function _updateNodeReputation(uint256 nodeId, int256 reputationChange) internal {
         int256 currentRep = int256(nodeReputation[nodeId]);
         int256 newRep = currentRep + reputationChange;

         // Clamp reputation between 0 and 200 (example bounds)
         if (newRep < 0) newRep = 0;
         if (newRep > 200) newRep = 200;

         nodeReputation[nodeId] = uint256(newRep);
         emit ReputationUpdated(nodeId, nodeReputation[nodeId]);
     }


    // --- Parameter & Protocol Management (>= 20 count target: 18-23) ---

    /// @notice Owner function to set the base chance multiplier for mutations.
    /// @param privateBaseChance The new base mutation chance factor (e.g., 100 for 10%).
    function setMutationParams(uint privateBaseChance) external onlyOwner {
        mutationBaseChance = privateBaseChance;
    }

    /// @notice Owner function to set the fee required for breeding.
    /// @param privateFee The new breeding fee in wei.
    function setBreedingParams(uint privateFee) external onlyOwner {
        breedingFee = privateFee;
    }

    /// @notice Owner function to pause core protocol operations (mutation, breeding).
    function pauseProtocol() external onlyOwner {
        paused = true;
        emit ProtocolPaused(_msgSender());
    }

    /// @notice Owner function to unpause the protocol.
    function unpauseProtocol() external onlyOwner {
        paused = false;
        emit ProtocolUnpaused(_msgSender());
    }

    /// @notice Owner function to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = protocolBalance;
        protocolBalance = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(owner(), amount);
    }


    // --- Generative & Querying Functions (>= 20 count target: 13, 14, 15, 24-32) ---

    /// @notice Internal helper function to derive phenotypic traits from a Node's genetic code.
    /// This logic defines how genes influence observable characteristics.
    /// @param genes The genetic code array.
    /// @return An array of derived trait strings.
    function _deriveTraitsFromGenes(uint[] memory genes) internal pure returns (string[] memory) {
        string[] memory derived = new string[](genes.length); // Simple 1:1 gene-to-trait mapping example

        // Example: Map gene values to simple trait strings
        // In a complex system, this would be more sophisticated.
        for (uint i = 0; i < genes.length; i++) {
            string memory geneValueStr = Strings.toString(genes[i]);
            if (genes[i] < 20) {
                derived[i] = string(abi.encodePacked("Low-", geneValueStr));
            } else if (genes[i] < 80) {
                derived[i] = string(abi.encodePacked("Mid-", geneValueStr));
            } else {
                derived[i] = string(abi.encodePacked("High-", geneValueStr));
            }
        }
        return derived;
    }

     /// @notice Generates the JSON metadata string for a given Node ID.
     /// Used by the `tokenURI` function.
     /// @param nodeId The ID of the Node.
     /// @return A JSON string representing the Node's metadata.
     function generateNodeMetadata(uint256 nodeId) internal view returns (string memory) {
         require(_exists(nodeId), "Metadata query for non-existent token");

         NodeGenes storage genes = nodeGenes[nodeId];
         NodeTraits storage traits = nodeTraits[nodeId];
         uint reputation = nodeReputation[nodeId];
         NodeStatus status = nodeStatus[nodeId];

         string memory geneString = "[";
         for(uint i = 0; i < genes.geneticCode.length; i++) {
             geneString = string(abi.encodePacked(geneString, Strings.toString(genes.geneticCode[i])));
             if (i < genes.geneticCode.length - 1) {
                 geneString = string(abi.encodePacked(geneString, ","));
             }
         }
         geneString = string(abi.encodePacked(geneString, "]"));


         string memory traitString = "[";
         for(uint i = 0; i < traits.phenotypicTraits.length; i++) {
             traitString = string(abi.encodePacked(traitString, '"', traits.phenotypicTraits[i], '"'));
             if (i < traits.phenotypicTraits.length - 1) {
                 traitString = string(abi.encodePacked(traitString, ","));
             }
         }
         traitString = string(abi.encodePacked(traitString, "]"));

         string memory statusString;
         if (status == NodeStatus.Active) statusString = "Active";
         else if (status == NodeStatus.Dormant) statusString = "Dormant";
         else if (status == NodeStatus.Mutating) statusString = "Mutating";
         else if (status == NodeStatus.Flagged) statusString = "Flagged";
         else if (status == NodeStatus.Bred) statusString = "Bred";


         // Basic image placeholder (can be replaced with generative image logic off-chain or SVG on-chain)
         string memory image = string(abi.encodePacked("data:image/svg+xml;base64,",
             Base64.encode(bytes(string(abi.encodePacked(
                 '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="#',
                 Strings.toHexString(genes.geneticCode[0] * 255 / 100, 1), // Use gene 0 for color part 1
                 Strings.toHexString(genes.geneticCode[1] * 255 / 100, 1), // Use gene 1 for color part 2
                 Strings.toHexString(genes.geneticCode[2] * 255 / 100, 1), // Use gene 2 for color part 3
                 '" /><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="20" fill="#ffffff">Node #',
                 Strings.toString(nodeId),
                 '</text><text x="50%" y="60%" dominant-baseline="middle" text-anchor="middle" font-size="14" fill="#ffffff">Rep:',
                 Strings.toString(reputation),
                 '</text></svg>'
             ))))
         ));


         string memory json = string(abi.encodePacked(
             '{',
                 '"name": "Genesis Node #', Strings.toString(nodeId), '",',
                 '"description": "An evolving digital organism managed by the Genesis Protocol.",',
                 '"image": "', image, '",',
                 '"attributes": [',
                     '{ "trait_type": "Mutation Count", "value": ', Strings.toString(genes.mutationCount), ' },',
                     '{ "trait_type": "Reputation", "value": ', Strings.toString(reputation), ' },',
                     '{ "trait_type": "Status", "value": "', statusString, '" },',
                     '{ "trait_type": "Creation Time", "value": ', Strings.toString(nodeCreationTime[nodeId]), ' },',
                     // Add traits from the phenotypicTraits array
                     traitString, ',"is_array":true, "trait_type": "Phenotypic Traits" },',
                     // Add genes from the geneticCode array (optional to expose raw genes)
                     geneString, ',"is_array":true, "trait_type": "Genetic Code" }',
                 ']',
             '}'
         ));

         return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
     }


    /// @notice Returns the URI for the Node's metadata. Overrides ERC721's tokenURI.
    /// The URI is a data URI containing the base64 encoded JSON metadata.
    /// @param tokenId The ID of the Node.
    /// @return A string containing the data URI.
    function tokenURI(uint256 tokenId)
        public view override(ERC721) nodeExists(tokenId)
        returns (string memory)
    {
        return generateNodeMetadata(tokenId);
    }


    /// @notice Simulates the outcome of a potential future mutation for a Node without changing state.
    /// Useful for frontends to preview possible evolutions.
    /// @param nodeId The ID of the Node to simulate mutation for.
    /// @param simulationSeed Arbitrary bytes used as entropy for the simulation.
    /// @return The simulated genetic code and phenotypic traits after mutation.
    function simulateFutureMutation(uint256 nodeId, bytes memory simulationSeed)
        public view nodeExists(nodeId)
        returns (uint[] memory simulatedGenes, string[] memory simulatedTraits)
    {
         // This simulation uses the provided seed and current state/timestamp,
         // but cannot guarantee it's *exactly* what an on-chain mutation would yield
         // unless the seed perfectly replicates future block data. Still useful for preview.
         uint simulatedEntropy = uint(keccak256(abi.encodePacked(block.timestamp, nodeId, simulationSeed)));

        uint[] memory currentGenes = nodeGenes[nodeId].geneticCode;
        simulatedGenes = new uint[](currentGenes.length);
        for(uint i = 0; i < currentGenes.length; i++) {
            simulatedGenes[i] = currentGenes[i];
        }

        // Apply a simulated mutation based on the seed
        uint geneIndexToMutate = simulatedEntropy % simulatedGenes.length;
        int change = int(uint(keccak256(abi.encodePacked(simulatedEntropy, "sim_change"))) % 21) - 10; // Range -10 to +10
        if (change < 0 && uint(-change) > simulatedGenes[geneIndexToMutate]) {
             simulatedGenes[geneIndexToMutate] = 0;
         } else {
             simulatedGenes[geneIndexToMutate] = uint(int(simulatedGenes[geneIndexToMutate]) + change);
         }


        // Derive simulated traits from the simulated genes
        simulatedTraits = _deriveTraitsFromGenes(simulatedGenes);

        return (simulatedGenes, simulatedTraits);
    }

    /// @notice Queries all Nodes and returns the IDs of those possessing a specific phenotypic trait.
    /// NOTE: This function iterates through all existing tokens, which can be gas-intensive
    /// and potentially exceed block gas limits for large collections. Use with caution.
    /// @param trait The trait string to search for.
    /// @return An array of Node IDs that have the specified trait.
    function queryNodesByTrait(string memory trait)
        public view returns (uint256[] memory)
    {
        uint256 total = _nextTokenId.current();
        uint256[] memory matchingNodeIds = new uint256[](total); // Max possible matches
        uint256 count = 0;

        for (uint256 i = 1; i <= total; i++) { // Assuming tokenIds start from 1 or 0+1
            if (_exists(i)) { // Check if token exists (was not burned, if burn implemented)
                 string[] memory traits = nodeTraits[i].phenotypicTraits;
                 for(uint j=0; j < traits.length; j++) {
                     if (keccak256(abi.encodePacked(traits[j])) == keccak256(abi.encodePacked(trait))) {
                         matchingNodeIds[count] = i;
                         count++;
                         break; // Found trait for this node, move to the next node
                     }
                 }
            }
        }

        // Trim the array to the actual number of matches
        uint256[] memory result = new uint256[](count);
        for(uint i=0; i < count; i++) {
            result[i] = matchingNodeIds[i];
        }
        return result;
    }

    // --- Standard ERC721 Functions (>= 20 count target: 24-32) ---
    // These are standard implementations from OpenZeppelin

    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function approve(address to, uint256 tokenId) public override(ERC721) {
        super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        // Optional: Add custom logic here for semi-soulbound behavior, e.g., reputation penalty on transfer
        // or only allow transfer if NodeStatus is not Flagged/Mutating.
        // For this example, we allow standard ERC721 transfer but note the 'semi-soulbound' intent.
        // A truly soulbound token would override this and _safeTransferFrom to revert.
        super.transferFrom(from, to, tokenId);
        // After transfer, perhaps reputation is affected, or mutation counts reset for the new owner?
        // nodeReputation[tokenId] = nodeReputation[tokenId] / 2; // Example penalty
        // nodeGenes[tokenId].mutationCount = 0; // Example reset
        // Emit an event if custom transfer logic impacts state
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.safeTransferFrom(from, to, tokenId);
         // Apply post-transfer effects here if implementing semi-soulbound logic
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) {
        super.safeTransferFrom(from, to, tokenId, data);
         // Apply post-transfer effects here if implementing semi-soulbound logic
    }

     /// @notice Alias for transferFrom, kept for clarity in summary.
     /// @param from The current owner address.
     /// @param to The recipient address.
     /// @param tokenId The ID of the Node to transfer.
    function transferNode(address from, address to, uint256 tokenId) external {
        // Calls the standard transferFrom logic
        transferFrom(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Helpers ---
    // _beforeTokenTransfer and _afterTokenTransfer from ERC721 can be extended
    // if specific logic is needed during minting/transferring/burning.
    // For instance, clear reputation/status on burn, or log provenance.

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //      // Example: Clear approvals on transfer
    //      if (from != address(0) && to != address(0)) {
    //          _approve(address(0), tokenId);
    //      }
    // }

    // function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._afterTokenTransfer(from, to, tokenId, batchSize);
    //     // Example: Log transfer or update state related to new owner
    // }

    // Internal Minting/Burning (if needed, not strictly required by >20 functions)
    // function _mint(address to, uint256 tokenId) internal {
    //     _safeMint(to, tokenId); // Using _safeMint as implemented in createGenesisNode
    // }

    // function burn(uint256 tokenId) public virtual onlyNodeOwner(tokenId) {
    //     _burn(tokenId);
    //     // Optional: Clean up node-specific data mappings on burn
    //     delete nodeGenes[tokenId];
    //     delete nodeTraits[tokenId];
    //     delete nodeReputation[tokenId];
    //     delete nodeStatus[tokenId];
    //     delete nodeCreationTime[tokenId];
    // }
}
```

**Explanation of Creative/Advanced Aspects & Functionality:**

1.  **Dynamic State (`NodeGenes`, `NodeTraits`, `nodeReputation`, `nodeStatus`):** Unlike static NFTs, the core data (`geneticCode`, `phenotypicTraits`) associated with a Node ID is designed to change. This is the foundation of the "evolving" concept.
2.  **On-Chain Simulation (`triggerNodeMutation`, `applyEnvironmentalEffect`, `proposeBreeding`):** These functions implement deterministic (within blockchain limits) processes that read the current Node state and write a *new* state based on defined rules (chance, mixing, environmental input). The `geneticCode` (uint array) allows for mathematical operations that simulate biological/evolutionary concepts (mutation as value change, breeding as mixing).
3.  **Generative Output (`generateNodeMetadata`, `tokenURI`):** The `tokenURI` is generated dynamically by `generateNodeMetadata`. This function reads the *current* on-chain state (genes, traits, reputation, status) and formats it into the ERC721 metadata JSON. It even includes a simple on-chain SVG generation based on gene values for a visual element directly linked to the state.
4.  **On-Chain Querying (`queryNodesByTrait`, `simulateFutureMutation`):** `queryNodesByTrait` demonstrates querying the collection *based on the dynamic state* (phenotypic traits), which goes beyond basic ownership lookups. `simulateFutureMutation` is a `view` function providing a preview of a potential future state based on current data and provided entropy, a unique interactive element.
5.  **Semi-Soulbound/Reputation (`nodeReputation`, `nodeStatus`, `lodgeComplaintAgainstNode`, `resolveComplaint`, `transferFrom` override note):** While using ERC721 for ownership, the contract ties `nodeReputation` and `nodeStatus` directly to the Node ID. The intent (not fully enforced in the example `transferFrom`) is that these attributes are core to the Node's identity and interactions, making it less of a freely tradable collectible and more of an active participant entity whose history matters. The complaint system adds a social/governance layer.
6.  **Rule Parameterization (`setMutationParams`, `setBreedingParams`):** Allows the protocol owner (or future governance) to adjust the core rules of evolution and breeding, enabling the protocol itself to "evolve" in terms of its mechanics.
7.  **Protocol Economy (`breedingFee`, `protocolBalance`, `withdrawProtocolFees`):** Includes basic tokenomics for funding or capturing value within the protocol interactions (here, breeding).

This contract provides a framework for a complex, dynamic digital ecosystem where NFTs are not just static images but living, interacting, and evolving entities governed by on-chain rules. The implementation simplifies complex processes like genetics and randomness due to Solidity's constraints but provides a solid base for these advanced concepts.