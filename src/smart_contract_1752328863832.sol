Okay, here is a smart contract concept called the **Quantum Fusion Protocol (QFP)**. It deals with dynamic, stateful NFTs called "Artifacts" that can be "observed" to potentially change states, become "entangled" with other artifacts, and even "fused" together. The states and properties are dynamic, influenced by interactions and time, moving beyond static metadata.

This design incorporates concepts like:
*   **Dynamic State:** NFTs aren't fixed; they have multiple potential states and can transition between them.
*   **Observation Effect:** Interaction (calling `observeArtifact`) is the primary trigger for state evaluation, metaphorical to quantum observation collapsing a superposition.
*   **Entanglement:** Linking two artifacts such that actions on one can affect the other.
*   **Coherence Score:** A dynamic metric reflecting the artifact's interaction history, state, and entanglement.
*   **Fusion:** Combining artifacts to create new ones.
*   **Time-Based & Interaction-Based Logic:** State transitions depend on time elapsed or interaction count.

It avoids replicating standard protocols like basic ERC20/ERC721 logic (beyond the interface), common DeFi mechanisms, or simple DAO structures.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For potential dynamic SVG or JSON metadata

// --- Outline and Function Summary ---
/*
Contract Name: QuantumFusionProtocol (QFP)
Description: A protocol for creating, managing, and interacting with dynamic, stateful NFTs called "Artifacts".
Artifacts can exist in multiple potential states, transition between states based on time or interaction ("Observation"),
become "Entangled" with other artifacts, and be "Fused" together. Each artifact has a dynamic "Coherence Score".

Key Concepts:
1.  Dynamic States: Artifacts have an array of possible states; one is active.
2.  Observation: Calling `observeArtifact` triggers state evaluation and interaction count update.
3.  State Transition: Based on conditions (time elapsed, interaction count) encoded in state data.
4.  Entanglement: Linking artifacts so actions on one can propagate to another.
5.  Coherence Score: A dynamic metric based on state, interactions, entanglement, and time.
6.  Fusion: Combining two artifacts into a new one.

Function Summary:

// Standard ERC721 Functions (inherited/overridden):
1.  balanceOf(address owner): Get number of artifacts owned by address.
2.  ownerOf(uint256 tokenId): Get owner of artifact.
3.  approve(address to, uint256 tokenId): Approve address to manage artifact.
4.  getApproved(uint256 tokenId): Get approved address for artifact.
5.  setApprovalForAll(address operator, bool approved): Set operator approval for all artifacts.
6.  isApprovedForAll(address owner, address operator): Check operator approval status.
7.  transferFrom(address from, address to, uint256 tokenId): Transfer artifact ownership.
8.  safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer with receiver check.
9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
10. tokenURI(uint256 tokenId): Get metadata URI for artifact (dynamic based on state).

// Core Artifact Management:
11. mintArtifact(address recipient, State[] initialStates, string initialMetadataHash): Create and mint a new artifact.
12. burnArtifact(uint256 tokenId): Destroy an artifact (owner or approved).
13. getArtifactDetails(uint256 tokenId): Retrieve all structural details of an artifact.
14. getArtifactState(uint256 tokenId): Get the data for the artifact's *current* active state.

// State Management & Interaction:
15. addPossibleState(uint256 tokenId, State newState): Add a potential state to an existing artifact.
16. removePossibleState(uint256 tokenId, uint8 stateId): Remove a potential state by its ID.
17. updateStateData(uint256 tokenId, uint8 stateId, bytes newData): Update the data associated with a potential state.
18. observeArtifact(uint256 tokenId): The core interaction function. Increments interaction count, updates last observed time, evaluates and potentially transitions state.
19. evaluateAndTransitionState(uint256 tokenId): Internal helper (also callable by owner for forced check) to evaluate state transition conditions and update `currentStateIndex`.
20. getStateData(uint256 tokenId, uint8 stateId): Get the raw data for a specific potential state (not necessarily current).

// Entanglement Mechanics:
21. entangleArtifacts(uint256 tokenId1, uint256 tokenId2): Link two artifacts together (requires ownership/approval of both).
22. disentangleArtifacts(uint256 tokenId1, uint256 tokenId2): Remove the link between two artifacts.
23. getEntangledArtifacts(uint256 tokenId): Get the list of token IDs an artifact is entangled with.
24. propagateInteraction(uint256 sourceTokenId, uint256 targetTokenId): Propagate an observation trigger from one entangled artifact to another (requires source observation).

// Coherence Score:
25. calculateCoherenceScore(uint256 tokenId): Internal/External view function to compute the dynamic coherence score.
26. getCoherenceScore(uint256 tokenId): Get the cached/last calculated coherence score. (Maybe calculate on the fly for view function).

// Fusion Mechanics:
27. fuseArtifacts(uint256 tokenId1, uint256 tokenId2, State[] fusedStates, string fusedMetadataHash) payable: Fuse two artifacts into a new one, potentially requiring payment. Burns the inputs.

// Protocol Configuration & Funds:
28. setBaseMetadataURI(string baseURI): Set a base URI for metadata resolution.
29. setFusionFee(uint256 fee): Set the required fee for fusing artifacts.
30. withdrawFunds(): Withdraw collected fees (owner only).
31. getFusionFee(): Get the current fusion fee.
32. getPurchasePrice(): Get the price for purchasing a new artifact (if implemented, currently minting is only via fuse/direct mint).

*/

contract QuantumFusionProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    // Enum for simple transition conditions
    enum TransitionConditionType {
        None,             // No automatic transition based on this state
        TimeElapsed,      // Transition if a certain time has passed since last observation
        InteractionCount  // Transition if interaction count reaches a threshold
    }

    // State data structure
    struct State {
        uint8 stateId;            // Unique identifier for this state type within the artifact
        bytes stateData;          // Flexible data storage for state properties (e.g., ABI-encoded attributes)
        TransitionConditionType transitionType; // Type of condition to transition *into* this state
        uint256 transitionValue;  // Value associated with the condition (e.g., time in seconds, interaction count)
        string metadataURIFragment; // URI fragment for metadata associated with this state
    }

    // Artifact data structure
    struct Artifact {
        uint256 id;               // ERC721 Token ID
        uint8 currentStateIndex;  // Index in `possibleStates` array of the active state
        State[] possibleStates;   // Array of potential states the artifact can be in
        uint48 creationTime;      // Timestamp of creation
        uint48 lastObservedTime;  // Timestamp of the last observation
        uint32 interactionCount;  // Number of times `observeArtifact` has been called
        uint256[] entangledWith;  // Array of token IDs this artifact is entangled with
        uint256 coherenceScore;   // Dynamic score (cached/calculated)
        string baseMetadataHash;  // Base hash or URI part for metadata (applies across states)
    }

    // --- State Variables ---

    mapping(uint256 => Artifact) private _artifacts;
    string private _baseMetadataURI = ""; // Base URI for tokenURI

    uint256 public fusionFee = 0; // Fee required to fuse artifacts

    // --- Events ---

    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataHash);
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner);
    event StateTransitioned(uint256 indexed tokenId, uint8 indexed oldStateId, uint8 indexed newStateId, uint8 oldStateIndex, uint8 newStateIndex);
    event ArtifactObserved(uint256 indexed tokenId, uint32 newInteractionCount);
    event StateAdded(uint256 indexed tokenId, uint8 indexed stateId);
    event StateRemoved(uint256 indexed tokenId, uint8 indexed stateId);
    event StateDataUpdated(uint256 indexed tokenId, uint8 indexed stateId);
    event ArtifactsEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ArtifactsDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event InteractionPropagated(uint256 indexed sourceTokenId, uint256 indexed targetTokenId);
    event CoherenceScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event ArtifactsFused(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2, address indexed owner);
    event FusionFeeUpdated(uint256 newFee);
    event BaseMetadataURIUpdated(string newBaseURI);

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Modifiers ---

    modifier onlyArtifactOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QFP: Caller is not owner nor approved");
        _;
    }

    // --- Standard ERC721 Overrides (required for mappings) ---

    // These functions are largely handled by OpenZeppelin's ERC721 internally,
    // but we override tokenURI to provide dynamic metadata.

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "QFP: ERC721 query for nonexistent token");
        Artifact storage artifact = _artifacts[tokenId];
        State storage currentState = artifact.possibleStates[artifact.currentStateIndex];

        // Construct the full URI
        // Base URI + artifact base hash + state URI fragment
        return string(abi.encodePacked(
            _baseMetadataURI,
            artifact.baseMetadataHash,
            currentState.metadataURIFragment
        ));

        // Advanced: Could generate dynamic JSON/SVG on-chain for full dynamism,
        // but that's gas-intensive. Using IPFS hashes/URIs is more common.
        // Example hypothetical dynamic JSON:
        /*
        bytes memory json = abi.encodePacked(
            '{"name": "Artifact #', Strings.toString(tokenId), '", ',
            '"description": "A Quantum Fusion Protocol Artifact.", ',
            '"attributes": [',
            '{"trait_type": "State ID", "value": ', Strings.toString(currentState.stateId), '},',
            '{"trait_type": "Interaction Count", "value": ', Strings.toString(artifact.interactionCount), '},',
             // Decode stateData bytes and add more attributes dynamically
            ']}'
        );
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
        */
    }

    // --- Core Artifact Management ---

    /// @notice Mints a new artifact and assigns it to a recipient.
    /// @param recipient The address to receive the new artifact.
    /// @param initialStates The initial set of possible states for the artifact. Must include at least one state. The first state in the array will be the initial active state.
    /// @param initialMetadataHash A base hash or URI part for metadata that applies across all states.
    function mintArtifact(address recipient, State[] memory initialStates, string memory initialMetadataHash) public onlyOwner {
        require(initialStates.length > 0, "QFP: Must provide at least one initial state");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);

        Artifact storage newArtifact = _artifacts[newTokenId];
        newArtifact.id = newTokenId;
        newArtifact.possibleStates = initialStates; // Copy the array
        newArtifact.currentStateIndex = 0; // Start with the first state
        newArtifact.creationTime = uint48(block.timestamp);
        newArtifact.lastObservedTime = uint48(block.timestamp); // Observed upon creation
        newArtifact.interactionCount = 0;
        newArtifact.coherenceScore = calculateCoherenceScore(newTokenId); // Initial calculation
        newArtifact.baseMetadataHash = initialMetadataHash;

        emit ArtifactMinted(newTokenId, recipient, initialMetadataHash);
        emit StateTransitioned(newTokenId, 0, newArtifact.possibleStates[0].stateId, 0, 0); // Assuming stateId 0 for initial transition event
    }

    /// @notice Burns (destroys) an artifact.
    /// @param tokenId The ID of the artifact to burn.
    function burnArtifact(uint256 tokenId) public onlyArtifactOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "QFP: Artifact does not exist");

        // Disentangle from all linked artifacts before burning
        uint256[] memory entangledList = _artifacts[tokenId].entangledWith;
        for(uint i = 0; i < entangledList.length; i++) {
            if (_exists(entangledList[i])) { // Check if entangled artifact still exists
                 // Remove the link from the other side
                _removeEntanglement(_artifacts[entangledList[i]].entangledWith, tokenId);
                emit ArtifactsDisentangled(tokenId, entangledList[i]);
                emit ArtifactsDisentangled(entangledList[i], tokenId);
            }
        }
        delete _artifacts[tokenId].entangledWith; // Clear the array for the artifact being burned

        address owner = ownerOf(tokenId);
        _burn(tokenId);
        delete _artifacts[tokenId]; // Clean up storage

        emit ArtifactBurned(tokenId, owner);
    }

    /// @notice Gets the detailed structure of an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return The Artifact struct.
    function getArtifactDetails(uint256 tokenId) public view returns (Artifact memory) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        return _artifacts[tokenId];
    }

    /// @notice Gets the data for the artifact's current active state.
    /// @param tokenId The ID of the artifact.
    /// @return The active State struct.
    function getArtifactState(uint256 tokenId) public view returns (State memory) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];
        require(artifact.possibleStates.length > artifact.currentStateIndex, "QFP: Invalid state index");
        return artifact.possibleStates[artifact.currentStateIndex];
    }

    // --- State Management & Interaction ---

    /// @notice Adds a new potential state to an existing artifact.
    /// @param tokenId The ID of the artifact.
    /// @param newState The State struct to add. Must have a unique stateId for this artifact.
    function addPossibleState(uint256 tokenId, State memory newState) public onlyArtifactOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        // Check if stateId already exists
        for(uint i = 0; i < artifact.possibleStates.length; i++) {
            require(artifact.possibleStates[i].stateId != newState.stateId, "QFP: State ID already exists");
        }

        artifact.possibleStates.push(newState);
        emit StateAdded(tokenId, newState.stateId);
    }

    /// @notice Removes a potential state from an existing artifact by its stateId.
    /// Does not allow removing the *current* active state unless it's the only one left.
    /// @param tokenId The ID of the artifact.
    /// @param stateId The ID of the state to remove.
    function removePossibleState(uint256 tokenId, uint8 stateId) public onlyArtifactOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        uint indexToRemove = type(uint).max;
        for(uint i = 0; i < artifact.possibleStates.length; i++) {
            if (artifact.possibleStates[i].stateId == stateId) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != type(uint).max, "QFP: State ID not found");
        require(artifact.possibleStates.length > 1, "QFP: Cannot remove the only state");
        require(artifact.currentStateIndex != indexToRemove, "QFP: Cannot remove the current active state");

        // Swap and pop method to remove from dynamic array efficiently
        if (indexToRemove < artifact.possibleStates.length - 1) {
            artifact.possibleStates[indexToRemove] = artifact.possibleStates[artifact.possibleStates.length - 1];
        }
        artifact.possibleStates.pop();

        // If the removed state was *after* the current state index, we need to adjust the index.
        // If the state swapped into `indexToRemove` was *before* the original current state index,
        // the current state index might need adjustment too if the swapped state was the old last one.
        // Simplest: just check if current index is now out of bounds and reset to 0 if needed,
        // or re-evaluate the current state selection if a rule was based on index.
        // For this implementation, let's just ensure index is valid.
        if (artifact.currentStateIndex >= artifact.possibleStates.length) {
             artifact.currentStateIndex = 0; // Fallback to the first state if index becomes invalid
             emit StateTransitioned(tokenId, stateId, artifact.possibleStates[0].stateId, indexToRemove, 0); // Log potential fallback
        }


        emit StateRemoved(tokenId, stateId);
    }

    /// @notice Updates the raw data associated with a specific potential state of an artifact.
    /// @param tokenId The ID of the artifact.
    /// @param stateId The ID of the state to update.
    /// @param newData The new bytes data for the state.
    function updateStateData(uint256 tokenId, uint8 stateId, bytes memory newData) public onlyArtifactOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        uint indexToUpdate = type(uint).max;
        for(uint i = 0; i < artifact.possibleStates.length; i++) {
            if (artifact.possibleStates[i].stateId == stateId) {
                indexToUpdate = i;
                break;
            }
        }
        require(indexToUpdate != type(uint).max, "QFP: State ID not found");

        artifact.possibleStates[indexToUpdate].stateData = newData;
        // Could also allow updating transition conditions/value/metadata fragment here.
        // For simplicity, let's make stateId, type, value, metadata part of State struct creation/addition, only data is updateable.
        // To allow full state struct update:
        // artifact.possibleStates[indexToUpdate] = newState;

        emit StateDataUpdated(tokenId, stateId);
    }

    /// @notice The core interaction function. Observes the artifact, increments interaction count,
    /// updates last observed time, and triggers state evaluation.
    /// Anyone can observe an artifact.
    /// @param tokenId The ID of the artifact to observe.
    function observeArtifact(uint256 tokenId) public {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        artifact.interactionCount++;
        artifact.lastObservedTime = uint48(block.timestamp);

        // Evaluate and potentially transition state
        evaluateAndTransitionState(tokenId);

        // Recalculate coherence score after interaction and potential state change
        artifact.coherenceScore = calculateCoherenceScore(tokenId);

        emit ArtifactObserved(tokenId, artifact.interactionCount);
        emit CoherenceScoreUpdated(tokenId, artifact.coherenceScore);
    }

    /// @notice Evaluates state transition conditions and updates the artifact's active state.
    /// This function checks conditions for *all* possible states (except the current one)
    /// and transitions to the *first* state it finds whose condition is met.
    /// Callable by owner for forced evaluation, or internally by `observeArtifact`.
    /// @param tokenId The ID of the artifact.
    function evaluateAndTransitionState(uint256 tokenId) public {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        uint8 oldStateIndex = artifact.currentStateIndex;
        uint8 oldStateId = artifact.possibleStates[oldStateIndex].stateId;
        uint8 potentialNewStateIndex = oldStateIndex; // Default to no change

        // Iterate through all possible states to find one whose condition is met
        // (excluding the current state, unless it's the only option and somehow its own transition condition makes sense)
        // We prioritize based on the order in the `possibleStates` array.
        for (uint i = 0; i < artifact.possibleStates.length; i++) {
            if (i == oldStateIndex) continue; // Skip evaluation for the current state

            State storage potentialState = artifact.possibleStates[i];

            bool conditionMet = false;
            if (potentialState.transitionType == TransitionConditionType.TimeElapsed) {
                // Condition: Time elapsed since last observation >= transitionValue
                if (block.timestamp >= artifact.lastObservedTime + potentialState.transitionValue) {
                    conditionMet = true;
                }
            } else if (potentialState.transitionType == TransitionConditionType.InteractionCount) {
                // Condition: Interaction count >= transitionValue
                if (artifact.interactionCount >= potentialState.transitionValue) {
                    conditionMet = true;
                }
            }
            // Add other condition types here (e.g., external data, token balance, specific function call history)

            if (conditionMet) {
                potentialNewStateIndex = uint8(i);
                break; // Found a state to transition to, exit loop
            }
        }

        // If a different state was found, perform the transition
        if (potentialNewStateIndex != oldStateIndex) {
            artifact.currentStateIndex = potentialNewStateIndex;
            uint8 newStateId = artifact.possibleStates[potentialNewStateIndex].stateId;
            emit StateTransitioned(tokenId, oldStateId, newStateId, oldStateIndex, potentialNewStateIndex);
        }
    }

    /// @notice Gets the raw data for a specific potential state (not necessarily the current one).
    /// @param tokenId The ID of the artifact.
    /// @param stateId The ID of the state to retrieve data for.
    /// @return The raw bytes data for the specified state.
    function getStateData(uint256 tokenId, uint8 stateId) public view returns (bytes memory) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        for(uint i = 0; i < artifact.possibleStates.length; i++) {
            if (artifact.possibleStates[i].stateId == stateId) {
                return artifact.possibleStates[i].stateData;
            }
        }
        revert("QFP: State ID not found for artifact");
    }


    // --- Entanglement Mechanics ---

    /// @notice Entangles two artifacts. This creates a bidirectional link.
    /// Requires ownership or approval for both artifacts.
    /// @param tokenId1 The ID of the first artifact.
    /// @param tokenId2 The ID of the second artifact.
    function entangleArtifacts(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "QFP: Artifact 1 does not exist");
        require(_exists(tokenId2), "QFP: Artifact 2 does not exist");
        require(tokenId1 != tokenId2, "QFP: Cannot entangle an artifact with itself");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "QFP: Caller is not owner nor approved for artifact 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "QFP: Caller is not owner nor approved for artifact 2");

        Artifact storage artifact1 = _artifacts[tokenId1];
        Artifact storage artifact2 = _artifacts[tokenId2];

        // Check if already entangled
        bool alreadyEntangled = false;
        for(uint i = 0; i < artifact1.entangledWith.length; i++) {
            if (artifact1.entangledWith[i] == tokenId2) {
                alreadyEntangled = true;
                break;
            }
        }
        require(!alreadyEntangled, "QFP: Artifacts are already entangled");

        artifact1.entangledWith.push(tokenId2);
        artifact2.entangledWith.push(tokenId1);

        // Update coherence scores due to new entanglement
        artifact1.coherenceScore = calculateCoherenceScore(tokenId1);
        artifact2.coherenceScore = calculateCoherenceScore(tokenId2);

        emit ArtifactsEntangled(tokenId1, tokenId2);
        emit CoherenceScoreUpdated(tokenId1, artifact1.coherenceScore);
        emit CoherenceScoreUpdated(tokenId2, artifact2.coherenceScore);
    }

     /// @notice Disentangles two artifacts. Removes the bidirectional link.
    /// Requires ownership or approval for either artifact.
    /// @param tokenId1 The ID of the first artifact.
    /// @param tokenId2 The ID of the second artifact.
    function disentangleArtifacts(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "QFP: Artifact 1 does not exist");
        require(_exists(tokenId2), "QFP: Artifact 2 does not exist");
         require(tokenId1 != tokenId2, "QFP: Cannot disentangle from itself"); // Redundant but good check

        // Allow disentanglement if owner/approved of *either* artifact
        require(_isApprovedOrOwner(msg.sender, tokenId1) || _isApprovedOrOwner(msg.sender, tokenId2),
            "QFP: Caller is not owner nor approved for either artifact");

        Artifact storage artifact1 = _artifacts[tokenId1];
        Artifact storage artifact2 = _artifacts[tokenId2];

        require(_isEntangled(artifact1.entangledWith, tokenId2), "QFP: Artifacts are not entangled");

        _removeEntanglement(artifact1.entangledWith, tokenId2);
        _removeEntanglement(artifact2.entangledWith, tokenId1);

        // Update coherence scores
        artifact1.coherenceScore = calculateCoherenceScore(tokenId1);
        artifact2.coherenceScore = calculateCoherenceScore(tokenId2);

        emit ArtifactsDisentangled(tokenId1, tokenId2);
        emit ArtifactsDisentangled(tokenId2, tokenId1); // Emit symmetrical event
        emit CoherenceScoreUpdated(tokenId1, artifact1.coherenceScore);
        emit CoherenceScoreUpdated(tokenId2, artifact2.coherenceScore);
    }

    /// @dev Helper to remove a token ID from an array of entangled IDs.
    function _removeEntanglement(uint256[] storage entangledList, uint256 tokenIdToRemove) private {
        for (uint i = 0; i < entangledList.length; i++) {
            if (entangledList[i] == tokenIdToRemove) {
                // Swap and pop
                if (i < entangledList.length - 1) {
                    entangledList[i] = entangledList[entangledList.length - 1];
                }
                entangledList.pop();
                return;
            }
        }
    }

    /// @dev Helper to check if a token ID is in an entangled list.
    function _isEntangled(uint256[] storage entangledList, uint256 tokenIdToCheck) private view returns (bool) {
         for (uint i = 0; i < entangledList.length; i++) {
            if (entangledList[i] == tokenIdToCheck) {
                return true;
            }
        }
        return false;
    }

    /// @notice Gets the list of token IDs that an artifact is entangled with.
    /// @param tokenId The ID of the artifact.
    /// @return An array of entangled token IDs.
    function getEntangledArtifacts(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        return _artifacts[tokenId].entangledWith;
    }

    /// @notice Allows an interaction (Observation) with a source artifact to propagate to an entangled target artifact.
    /// Requires the caller to own/approve the source artifact AND for the artifacts to be entangled.
    /// @param sourceTokenId The artifact triggering the propagation.
    /// @param targetTokenId The entangled artifact that will also be observed.
    function propagateInteraction(uint256 sourceTokenId, uint256 targetTokenId) public {
        require(_exists(sourceTokenId), "QFP: Source artifact does not exist");
        require(_exists(targetTokenId), "QFP: Target artifact does not exist");
        require(sourceTokenId != targetTokenId, "QFP: Cannot propagate to itself");
        require(_isApprovedOrOwner(msg.sender, sourceTokenId), "QFP: Caller is not owner nor approved for source artifact");

        Artifact storage sourceArtifact = _artifacts[sourceTokenId];
        require(_isEntangled(sourceArtifact.entangledWith, targetTokenId), "QFP: Artifacts are not entangled");

        // Observe the target artifact. This triggers its own logic (interaction count, state eval, coherence)
        observeArtifact(targetTokenId);

        emit InteractionPropagated(sourceTokenId, targetTokenId);

        // Note: This propagation is one-way per function call.
        // Recursive propagation could be implemented but needs careful gas/depth limits.
    }

    // --- Coherence Score ---

    /// @notice Calculates the dynamic coherence score for an artifact.
    /// This is a view function that computes the score based on current artifact state.
    /// The actual score stored in the struct might be a cached value updated on interactions/transitions.
    /// The formula here is illustrative and can be complex.
    /// @param tokenId The ID of the artifact.
    /// @return The calculated coherence score.
    function calculateCoherenceScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        Artifact storage artifact = _artifacts[tokenId];

        uint256 score = 0;

        // Factor in interaction count
        score += artifact.interactionCount * 10; // Example: 10 points per interaction

        // Factor in time since last observation (rewards recent activity or penalizes dormancy)
        uint256 timeSinceLastObserved = block.timestamp - artifact.lastObservedTime;
        // Example: Score decreases with time since last observed (use a non-linear scale or cap)
        // For simplicity, let's add score based on *uptime* / creationTime vs lastObservedTime differential
        // Lower differential -> higher 'observation rate' -> higher score?
        // Or perhaps time elapsed since creation?
        uint256 timeSinceCreation = block.timestamp - artifact.creationTime;
        if (timeSinceCreation > 0) {
             // Example: Reward longevity, penalize inactivity
             score += timeSinceCreation / 1000; // Small base score from age
             if (timeSinceLastObserved < timeSinceCreation / 10) { // Observed somewhat recently (within 10% of its age)
                 score += 50; // Bonus for recent observation
             } else if (timeSinceLastObserved > timeSinceCreation / 2) { // Observed long ago (more than half its age)
                 if (score >= 20) score -= 20; // Penalty for dormancy (cap at 0)
                 else score = 0;
             }
        }


        // Factor in current state properties (e.g., states with higher stateId or specific data increase score)
        // This requires decoding stateData bytes - complex without knowing structure.
        // Let's use the state index or state ID as a proxy for complexity/value.
        score += artifact.currentStateIndex * 50; // Example: Higher index states give more points
        // Or use stateId: score += artifact.possibleStates[artifact.currentStateIndex].stateId * 50;


        // Factor in entanglement
        score += artifact.entangledWith.length * 100; // Example: 100 points per entangled artifact

        // Add other factors: external data, linked protocols, historical states, etc.

        // Ensure minimum score?
        if (score < 10) score = 10; // Base score

        return score;
    }

    /// @notice Gets the stored (potentially cached) coherence score for an artifact.
    /// The stored score is updated during observation, transition, entanglement, etc.
    /// @param tokenId The ID of the artifact.
    /// @return The coherence score.
    function getCoherenceScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QFP: Artifact does not exist");
        // Return the cached score. For real-time calculation use `calculateCoherenceScore`.
        // Deciding whether to calculate real-time vs. cache is a trade-off between gas (calculation on state-changing tx)
        // and data freshness (view call calculation vs. reading storage). Let's return the stored one,
        // and note that calculateCoherenceScore gives the real-time value.
        return _artifacts[tokenId].coherenceScore;
        // Alternative: uncomment this line to always calculate real-time score on view call:
        // return calculateCoherenceScore(tokenId);
    }


    // --- Fusion Mechanics ---

    /// @notice Fuses two artifacts into a new one. This burns the two input artifacts
    /// and mints a new artifact to the caller, potentially inheriting properties or history,
    /// and having the specified initial states and metadata. Requires payment of `fusionFee`.
    /// Requires ownership or approval for both artifacts being fused.
    /// @param tokenId1 The ID of the first artifact to fuse.
    /// @param tokenId2 The ID of the second artifact to fuse.
    /// @param fusedStates The initial set of states for the new fused artifact.
    /// @param fusedMetadataHash A base hash or URI part for the new artifact's metadata.
    function fuseArtifacts(uint256 tokenId1, uint256 tokenId2, State[] memory fusedStates, string memory fusedMetadataHash) public payable {
        require(_exists(tokenId1), "QFP: Artifact 1 does not exist");
        require(_exists(tokenId2), "QFP: Artifact 2 does not exist");
        require(tokenId1 != tokenId2, "QFP: Cannot fuse an artifact with itself");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "QFP: Caller is not owner nor approved for artifact 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "QFP: Caller is not owner nor approved for artifact 2");
        require(msg.value >= fusionFee, "QFP: Insufficient fusion fee");
        require(fusedStates.length > 0, "QFP: Must provide at least one state for fused artifact");

        // Note: More complex logic could inherit states, interaction counts, entanglement history, etc.
        // For simplicity, the new artifact starts fresh with provided states/metadata.

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        address caller = msg.sender;

        // Ensure the caller is either the owner or approved for both.
        // The require checks above already handle this based on msg.sender.
        // Could add complexity like requiring *both* owners to agree or split fee/ownership of new artifact.
        // Here, the caller pays the fee and gets the new artifact, provided they control both inputs.

        // Burn the source artifacts
        burnArtifact(tokenId1);
        burnArtifact(tokenId2);

        // Mint the new fused artifact to the caller
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(caller, newTokenId);

        Artifact storage newArtifact = _artifacts[newTokenId];
        newArtifact.id = newTokenId;
        newArtifact.possibleStates = fusedStates; // Copy the array
        newArtifact.currentStateIndex = 0; // Start with the first state
        newArtifact.creationTime = uint48(block.timestamp);
        newArtifact.lastObservedTime = uint48(block.timestamp); // Observed upon creation
        newArtifact.interactionCount = 0;
        newArtifact.coherenceScore = calculateCoherenceScore(newTokenId); // Initial calculation
        newArtifact.baseMetadataHash = fusedMetadataHash;

        emit ArtifactsFused(newTokenId, tokenId1, tokenId2, caller);
        emit ArtifactMinted(newTokenId, caller, fusedMetadataHash);
        emit StateTransitioned(newTokenId, 0, newArtifact.possibleStates[0].stateId, 0, 0); // Assuming stateId 0 for initial transition event

        // Any excess payment is left in the contract, can be withdrawn by owner
    }

    // --- Protocol Configuration & Funds ---

    /// @notice Sets the base URI for metadata resolution.
    /// @param baseURI The new base URI string.
    function setBaseMetadataURI(string memory baseURI) public onlyOwner {
        _baseMetadataURI = baseURI;
        emit BaseMetadataURIUpdated(baseURI);
    }

    /// @notice Sets the required fee for fusing artifacts.
    /// @param fee The new fusion fee in wei.
    function setFusionFee(uint256 fee) public onlyOwner {
        fusionFee = fee;
        emit FusionFeeUpdated(fee);
    }

    /// @notice Withdraws accumulated ether from fusion fees (owner only).
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "QFP: Withdrawal failed");
    }

    /// @notice Gets the current fusion fee.
    /// @return The current fusion fee in wei.
    function getFusionFee() public view returns (uint256) {
        return fusionFee;
    }

     /// @notice Placeholder function. If minting was possible via purchase, this would return the price.
     /// Currently, new artifacts are only minted via the owner or fusion.
    function getPurchasePrice() public pure returns (uint256) {
        // If there was a 'purchaseArtifact' function with a dynamic price, calculate/return it here.
        // For this example, minting is owner-controlled or via fusion.
        return 0; // No direct purchase price implemented
    }

    // --- Internal/Helper Functions ---

    // Inherited _beforeTokenTransfer and _afterTokenTransfer could be used
    // to handle entanglement checks or score updates on transfer, but for simplicity
    // in this example, entanglement and scores are primarily managed by
    // explicit function calls (entangle, disentangle, observe, fuse).

    // No specific internal helpers needed beyond standard ERC721 ones like _exists, _isApprovedOrOwner, _safeMint, _burn.

}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic States & State Transitions:** The `State` struct and the `possibleStates` array allow an NFT to represent more than just one static item. The `currentStateIndex` determines which state is active. The `evaluateAndTransitionState` function implements the core logic for changing states based on predefined conditions (`TimeElapsed`, `InteractionCount`). This moves NFTs towards being dynamic digital entities.
2.  **Observation Effect (`observeArtifact`):** This function is the primary interaction point. It's designed metaphorically like observing a quantum system – the act of interaction is what potentially triggers a state collapse/transition based on accumulated conditions. It also updates the interaction count and last observed time, which feed into the transition conditions and coherence score.
3.  **Entanglement (`entangleArtifacts`, `disentangleArtifacts`, `propagateInteraction`):** Artifacts can be linked together. The `propagateInteraction` function demonstrates a simple form of entanglement where observing one artifact can trigger an observation on a linked artifact. This creates dependencies and networked effects between NFTs.
4.  **Coherence Score (`calculateCoherenceScore`, `getCoherenceScore`):** This is a totally custom, dynamic metric. It's calculated based on various factors of the artifact's history and state (interaction count, time, current state, number of entangled artifacts). This adds a layer of quantitative value or complexity that changes over time and with user interaction, making the NFT's status fluid.
5.  **Fusion (`fuseArtifacts`):** A crafting/burning mechanism where two NFTs are consumed to produce a new one. This is a common gaming/collectible pattern but implemented here as a core protocol feature, potentially requiring a fee and allowing for the creation of artifacts with unique initial states or properties not available through initial minting.
6.  **Flexible State Data (`stateData` bytes):** The `stateData` field in the `State` struct uses `bytes`, allowing arbitrary data to be associated with each state. This means properties can be complex and state-specific without needing a fixed struct, offering flexibility for different types of artifacts or game mechanics built on top. Decoding and using this data happens off-chain or requires additional helper functions depending on the data structure.
7.  **Condition Encoding:** State transition conditions are not hardcoded but encoded in the `State` struct (`transitionType`, `transitionValue`). While the `evaluateAndTransitionState` function still needs to *interpret* these types, the *values* and *types* of conditions can be defined when states are added or updated, making the transition rules somewhat configurable per state/artifact.

This contract provides a framework for creating NFTs that are more alive, interactive, and interconnected than typical static or purely generative collections. The 20+ functions cover standard NFT operations, custom state and interaction logic, entanglement management, dynamic scoring, and a creation/burning mechanism.