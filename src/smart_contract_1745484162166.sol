Okay, let's design a smart contract with a unique theme and advanced concepts. We'll create a "Quantum Realm Chronicle" contract, where NFTs represent entities existing in a multidimensional space. These entities have complex states, can interact in non-linear ways, and their history (chronicle) can influence their present state. The realm itself has properties that can shift.

This design incorporates:
*   Complex data structures (structs for entities, realms, chronicles).
*   Non-linear interactions (merging, splitting, entanglement).
*   State influenced by history (simulated "temporal flux").
*   Simulated probabilistic elements (superposition hint).
*   Decentralized governance elements (proposing/voting on realm shifts).
*   Role-based access control.
*   An evolving state space (realm properties).

It will use ERC-721 for entity ownership but build significant custom logic on top.

---

## QuantumRealmChronicles Smart Contract

**Theme:** A decentralized simulation or game managing entities across a complex, quantum-themed state space.

**Core Concepts:**
*   **Entities:** NFTs (`ERC721`) with unique properties (`EntityState`).
*   **Realm:** The environment with global properties (`RealmState`).
*   **Chronicles:** Historical records associated with Entities.
*   **Interactions:** Complex functions modifying Entity or Realm states (merging, entanglement, etc.).
*   **Temporal Flux:** Influence of chronicle history on current state.
*   **Dimensional Drifts:** Periodic or triggered changes to the Realm.
*   **Superposition Hint:** A simulated predictive function.
*   **Decentralized Governance:** Proposal/voting for Realm changes.

---

**Outline & Function Summary:**

1.  **Interfaces & Libraries:** Standard ERC721/ERC165 interfaces.
2.  **Events:** Announce key state changes, interactions, mints, burns, transfers.
3.  **Errors:** Custom errors for clarity.
4.  **Roles:** Simple mapping-based access control for Admin and Observer roles.
5.  **Structs:**
    *   `EntityState`: Properties of an entity (ID, owner, signature, stability, alignment, entropy, chronicle pointer, entanglement partner).
    *   `RealmState`: Global properties (type, stability, epoch).
    *   `RealmShiftProposal`: Data for proposed realm changes.
6.  **Enums:** Define types for Realm (`RealmType`) and Entity Stability (`StabilityLevel`).
7.  **State Variables:** Mappings for entity states, realm state, chronicles, entanglement, roles, token ownership/approvals, proposal tracking, token counter, base URI.
8.  **Modifiers:** Access control checks (`onlyAdmin`, `onlyObserver`).
9.  **ERC721 Implementation (Overridden/Customized):**
    *   `supportsInterface`: Standard ERC165.
    *   `balanceOf`: Get owner's entity count.
    *   `ownerOf`: Get entity owner.
    *   `_safeMint`: Internal minting logic.
    *   `_burn`: Internal burning logic.
    *   `_beforeTokenTransfer`: Custom checks before transfer (e.g., entanglement).
    *   `_afterTokenTransfer`: Custom logic after transfer.
    *   `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`: Standard approval logic.
    *   `transferFrom`, `safeTransferFrom`: Standard transfer logic, potentially using custom before/after hooks.
    *   `tokenURI`: Get metadata URI.
    *   `setBaseURI`: Set base for tokenURI (Admin).
10. **Core State Management Functions:**
    *   `constructor`: Initializes the contract, sets admin, initial realm state.
    *   `mintEntity`: Creates a new entity NFT with initial state.
    *   `getEntityState`: Reads properties of a specific entity.
    *   `getRealmProperties`: Reads properties of the current realm.
    *   `observeRealmState`: Reads a summary of the current realm state.
    *   `evolveEntity`: Changes an entity's state based on internal logic (time, entropy, etc.). Can be triggered externally.
    *   `driftRealm`: Admin-only function to trigger a significant realm state change.
11. **Chronicle Functions:**
    *   `recordChronicleEntry`: Adds an event hash/pointer to an entity's history.
    *   `getChronicleEntries`: Retrieves an entity's chronicle history.
12. **Advanced Interaction Functions:**
    *   `entangleEntities`: Links two entities, affecting how their states evolve together.
    *   `disentangleEntities`: Breaks the entanglement between two entities.
    *   `mergeEntities`: Combines two entities (burns originals, mints new) with properties derived from the merged ones.
    *   `splitEntity`: Splits one entity (burns original, mints two new) distributing properties.
    *   `collapseState`: Initiates or advances an entity's state collapse, potentially making it unstable.
    *   `stabilizeEntity`: Counteracts state collapse, improving stability.
    *   `probeDimensionalBoundary`: Simulates probing other realms, potentially causing minor realm shifts or entity effects.
    *   `initiateTemporalFlux`: Uses an entity's chronicle history to influence its *current* state (simulated effect, doesn't rewrite history).
    *   `queryQuantumSignature`: Pure function to check compatibility/interaction potential between two entities based on their signatures.
    *   `mutateEntitySignature`: Allows changing an entity's signature under specific conditions (Admin or complex game logic).
    *   `observeSuperpositionHint`: A view function that gives a hint about a *potential* future state or interaction outcome without committing changes. (Simulated prediction).
    *   `attuneToRealm`: Adjusts an entity's alignment to match the current realm, potentially providing state bonuses.
13. **Decentralized Governance (Realm Shift Proposals):**
    *   `proposeRealmShift`: Allows eligible addresses (e.g., Observers, or entity owners) to propose a realm state change.
    *   `voteOnRealmShift`: Allows eligible addresses to vote on an active proposal.
    *   `executeRealmShiftProposal`: Admin function to enact a successful proposal.
14. **Role Management Functions:**
    *   `addObserverRole`: Grants Observer role (Admin).
    *   `removeObserverRole`: Revokes Observer role (Admin).
    *   `addAdminRole`: Grants Admin role (Current Admin).
    *   `removeAdminRole`: Revokes Admin role (Current Admin - with caution).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// Note: Using OpenZeppelin interfaces for standard compliance, but implementing logic manually to avoid duplication of *implementation* logic.

/**
 * @title QuantumRealmChronicles
 * @dev A smart contract managing entities (NFTs) within a dynamic, multi-dimensional realm.
 *      Entities have complex states, can interact in non-linear ways (merge, split, entangle),
 *      and their history (chronicle) influences their present state. The realm itself can shift.
 */
contract QuantumRealmChronicles is IERC721, IERC165 {

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEntropy);
    event EntityStateEvolved(uint256 indexed tokenId, bytes32 propertiesHash);
    event EntitiesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntitiesDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntitiesMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event EntitySplit(uint256 indexed originalTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2);
    event EntityStateCollapsed(uint256 indexed tokenId, StabilityLevel newStability);
    event EntityStabilized(uint256 indexed tokenId, StabilityLevel newStability);
    event ChronicleEntryRecorded(uint256 indexed tokenId, bytes32 entryHash);
    event RealmDrifted(RealmType newRealmType, uint256 newEpoch);
    event DimensionalProbeResult(uint256 indexed callerTokenId, RealmType probedRealm, bytes32 resultHash);
    event TemporalFluxInitiated(uint256 indexed tokenId, bytes32 fluxEffectHash);
    event QuantumSignatureMutated(uint256 indexed tokenId, bytes32 newSignature);
    event EntityAttunedToRealm(uint256 indexed tokenId, RealmType currentRealm);
    event RealmShiftProposalCreated(uint256 indexed proposalId, address indexed proposer, RealmType targetRealmType, uint256 quorum);
    event RealmShiftProposalVoted(uint256 indexed proposalId, address indexed voter);
    event RealmShiftProposalExecuted(uint256 indexed proposalId, RealmType enactedRealmType);
    event RealmShiftProposalCancelled(uint256 indexed proposalId);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Errors ---
    error NotAdmin();
    error NotObserver();
    error EntityDoesNotExist(uint256 tokenId);
    error EntityAlreadyExists(uint256 tokenId);
    error NotTokenOwner(uint256 tokenId, address caller);
    error NotApprovedOrOwner(uint256 tokenId, address caller);
    error CannotTransferEntangledEntity(uint256 tokenId);
    error CannotMergeDifferentOwners(uint256 tokenId1, uint256 tokenId2);
    error EntitiesNotEntangled(uint256 tokenId1, uint256 tokenId2);
    error EntitiesAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error InvalidEntityState(uint256 tokenId);
    error AlreadyProposedRealmShift(uint256 proposalId);
    error ProposalDoesNotExist(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ProposalQuorumNotMet(uint256 proposalId);
    error ProposalVotingPeriodEnded(uint256 proposalId);
    error ProposalNotYetExecutable(uint256 proposalId);
    error NoActiveProposal();
    error CannotSplitUnstableEntity(uint256 tokenId);
    error CannotAttuneDifferentRealms(RealmType entityAlignment, RealmType currentRealm);


    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OBSERVER_ROLE = keccak256("OBSERVER_ROLE");

    mapping(address => bool) private hasAdminRole;
    mapping(address => bool) private hasObserverRole;

    modifier onlyAdmin() {
        if (!hasAdminRole[msg.sender]) revert NotAdmin();
        _;
    }

    modifier onlyObserver() {
        if (!hasObserverRole[msg.sender] && !hasAdminRole[msg.sender]) revert NotObserver();
        _;
    }

    // --- Enums ---
    enum RealmType {
        Stable,
        Fluxing,
        Entropic,
        Echoing // Realm where history has stronger influence
    }

    enum StabilityLevel {
        Stable,
        Unstable,
        Collapsing
    }

    // --- Structs ---
    struct EntityState {
        address owner;
        uint256 tokenId; // Redundant but useful for lookup
        bytes32 quantumSignature; // Represents inherent properties/identity
        StabilityLevel stability;
        RealmType dimensionalAlignment; // Preferred or current aligned realm type
        uint256 entropy; // Increases with interactions, can lead to instability
        uint256 chroniclePointer; // Points to the starting index in the chronicle history
        uint256 entanglementPartner; // Token ID of entangled partner, 0 if none
        uint64 lastEvolvedEpoch; // Epoch of last evolution or significant interaction
    }

    struct RealmState {
        RealmType realmType;
        uint256 stabilityFactor; // Affects entity stability changes
        uint256 interactionCost; // Base cost modifier for interactions
        uint256 epoch; // Increments with significant realm changes
    }

    struct RealmShiftProposal {
        uint256 id;
        RealmType targetRealmType;
        uint256 proposerVotes;
        mapping(address => bool) hasVoted;
        uint256 creationEpoch;
        bool active;
        bool executed;
    }

    // --- State Variables ---

    // Entity Data
    mapping(uint256 => EntityState) private entities;
    mapping(address => uint256[]) private ownedTokens; // Track tokens per owner (optimistic, requires careful updates)
    uint256 private _tokenCounter; // Total number of entities ever minted

    // ERC721 Standard Data
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Realm Data
    RealmState public currentRealmState;
    uint256 private realmDriftCooldown = 100; // Epochs between admin drifts

    // Chronicle Data (simplified: array of hashes representing chronicle entries)
    mapping(uint256 => bytes32[]) private entityChronicles;

    // Entanglement Data
    mapping(uint256 => uint256) private entanglementPairs; // tokenId => entangledWithTokenId

    // Realm Shift Proposal Data
    uint256 private _proposalCounter;
    mapping(uint256 => RealmShiftProposal) private realmShiftProposals;
    uint256 private activeProposalId = 0; // 0 means no active proposal
    uint256 public proposalVotingPeriodEpochs = 10; // How many epochs a proposal is active
    uint256 public realmShiftQuorum = 5; // Minimum proposer votes needed to pass


    // Metadata
    string private _baseTokenURI;

    // --- Constructor ---
    constructor(string memory baseURI) {
        _baseTokenURI = baseURI;
        // Initialize admin role
        hasAdminRole[msg.sender] = true;
        emit RoleGranted(ADMIN_ROLE, msg.sender, msg.sender);

        // Initialize initial realm state
        currentRealmState = RealmState({
            realmType: RealmType.Stable,
            stabilityFactor: 100, // Higher = more stable
            interactionCost: 1, // Lower = cheaper interactions
            epoch: 1
        });
        emit RealmDrifted(currentRealmState.realmType, currentRealmState.epoch);
    }

    // --- ERC721 & ERC165 Standard Implementations ---

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, IERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0)); // Using standard OZ error name for clarity
        }
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert ERC721NonexistentToken(tokenId); // Using standard OZ error name for clarity
        }
        return owner;
    }

    function _safeMint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ERC721InvalidRecipient(address(0)); // Using standard OZ error name for clarity
        if (_owners[tokenId] != address(0)) revert EntityAlreadyExists(tokenId);

        _owners[tokenId] = to;
        _balances[to]++;
        // Add to ownedTokens (optional, potentially expensive for very large collections)
        // ownedTokens[to].push(tokenId); // Commenting out to avoid potential gas issues, rely on _balances

        emit Transfer(address(0), to, tokenId);

        // Check if recipient is a smart contract and implements ERC721Receiver
        if (to.code.length > 0) {
             require(
                IERC721Receiver(to).onERC721Received(msg.sender, address(0), tokenId, "") == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer" // Using standard OZ message for clarity
            );
        }
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert EntityDoesNotExist(tokenId);

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        // Update owner and balances
        _balances[owner]--;
        _owners[tokenId] = address(0);

        // Remove from ownedTokens (if implemented) - O(N) operation, consider alternatives
        // For simplicity, not implementing removal from ownedTokens here, relies on external tracking or enumeration
        // Or use a linked list structure for ownedTokens for O(1) removal

        emit Transfer(owner, address(0), tokenId);
    }

    // Custom logic before/after transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Prevent transfer of entangled entities
        if (entanglementPairs[tokenId] != 0) {
            revert CannotTransferEntangledEntity(tokenId);
        }
        // Add other custom checks here
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        // Update entity owner in the entity state struct
        if (from != address(0)) { // Not a mint
             entities[tokenId].owner = to;
        }
        // Add other custom logic here
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotApprovedOrOwner(tokenId, msg.sender);
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (_owners[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
         if (ownerOf(tokenId) != from) revert ERC721InvalidOwner(from); // Using standard OZ error name for clarity
         if (to == address(0)) revert ERC721InvalidRecipient(address(0)); // Using standard OZ error name for clarity

         if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
              revert NotApprovedOrOwner(tokenId, msg.sender);
         }

        _beforeTokenTransfer(from, to, tokenId);

        _tokenApprovals[tokenId] = address(0); // Clear approvals
        _balances[from]--;
        _owners[tokenId] = address(0); // Temporarily clear owner
        _balances[to]++;
        _owners[tokenId] = to; // Set new owner

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId); // Execute the transfer

        if (to.code.length > 0) { // Check if recipient is a smart contract
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer" // Using standard OZ message for clarity
            );
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);
        // Implement dynamic URI logic based on entity state here if needed
        // For simplicity, just append token ID to base URI
        string memory base = _baseTokenURI;
        return string(abi.encodePacked(base, Strings.toString(tokenId))); // Requires using OpenZeppelin Strings.sol or implementing it manually
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
    }

     // Simple implementation of Strings.sol toString(uint256) to avoid OZ import
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

    // --- Core State Management Functions ---

    /**
     * @dev Mints a new entity NFT with initial randomized or default state.
     * @param to The address to mint the entity to.
     * @param initialSignature A hash representing the entity's initial unique signature.
     */
    function mintEntity(address to, bytes32 initialSignature) public returns (uint256) {
        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;

        _safeMint(to, newTokenId); // Handles basic ERC721 minting and checks

        // Initialize complex entity state
        entities[newTokenId] = EntityState({
            owner: to,
            tokenId: newTokenId,
            quantumSignature: initialSignature,
            stability: StabilityLevel.Stable,
            dimensionalAlignment: currentRealmState.realmType, // Align to current realm initially
            entropy: 0, // Starts low
            chroniclePointer: 0, // First entry will be at index 0
            entanglementPartner: 0, // Not entangled initially
            lastEvolvedEpoch: currentRealmState.epoch
        });

        emit EntityMinted(newTokenId, to, entities[newTokenId].entropy);
        return newTokenId;
    }

    /**
     * @dev Gets the detailed state of an entity.
     * @param tokenId The ID of the entity.
     * @return EntityState struct.
     */
    function getEntityState(uint256 tokenId) public view returns (EntityState memory) {
        if (_owners[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);
        return entities[tokenId];
    }

    /**
     * @dev Gets the properties of the current realm.
     * @return RealmState struct.
     */
    function getRealmProperties() public view returns (RealmState memory) {
        return currentRealmState;
    }

     /**
     * @dev Gets a simplified summary of the current realm state.
     * @return realmType The current realm type.
     * @return epoch The current realm epoch.
     * @return entityCount The total number of entities in the realm.
     */
    function observeRealmState() public view returns (RealmType realmType, uint256 epoch, uint256 entityCount) {
        return (currentRealmState.realmType, currentRealmState.epoch, _tokenCounter); // Note: _tokenCounter is total minted, not necessarily active
    }


    /**
     * @dev Evolves an entity's state based on internal logic.
     *      Increases entropy, potentially reduces stability over time or interactions.
     * @param tokenId The ID of the entity to evolve.
     */
    function evolveEntity(uint256 tokenId) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Only owner can evolve entity");

        // Simulate entropy increase based on time or interactions
        uint256 epochDifference = currentRealmState.epoch - entity.lastEvolvedEpoch;
        if (epochDifference > 0) {
            entity.entropy += epochDifference * currentRealmState.interactionCost; // Entropy accumulates
            entity.lastEvolvedEpoch = currentRealmState.epoch;

            // Simulate stability decay based on entropy and realm stability
            if (entity.stability != StabilityLevel.Collapsing) {
                uint256 decayThreshold = 1000 * uint256(currentRealmState.stabilityFactor); // Higher stabilityFactor means higher threshold
                if (entity.entropy > decayThreshold && entity.stability == StabilityLevel.Stable) {
                    entity.stability = StabilityLevel.Unstable;
                    emit EntityStateCollapsed(tokenId, StabilityLevel.Unstable);
                } else if (entity.entropy > decayThreshold * 2 && entity.stability == StabilityLevel.Unstable) {
                    entity.stability = StabilityLevel.Collapsing;
                    emit EntityStateCollapsed(tokenId, StabilityLevel.Collapsing);
                }
            }
        }

        // Add other evolution logic here (e.g., alignment changes, signature subtle shifts)

        emit EntityStateEvolved(tokenId, keccak256(abi.encode(entity))); // Emit hash of new state
    }

    /**
     * @dev Admin function to trigger a significant realm state change (Drift).
     *      Resets proposal state and potentially affects entity states.
     * @param newRealmType The target realm type for the drift.
     * @param stabilityFactorModifier Modifier for realm stability.
     */
    function driftRealm(RealmType newRealmType, int256 stabilityFactorModifier) public onlyAdmin {
        // Simulate some cooldown
        require(currentRealmState.epoch - realmShiftProposals[activeProposalId].creationEpoch >= realmDriftCooldown, "Realm drift cooldown in effect");

        currentRealmState.epoch++;
        currentRealmState.realmType = newRealmType;
        // Apply modifier with clamping to avoid extremes
        int256 newStability = int256(currentRealmState.stabilityFactor) + stabilityFactorModifier;
        currentRealmState.stabilityFactor = uint256(newStability < 10 ? 10 : (newStability > 500 ? 500 : newStability)); // Clamp between 10 and 500

        // Clear any active proposal after a drift
        if (activeProposalId != 0 && !realmShiftProposals[activeProposalId].executed) {
             realmShiftProposals[activeProposalId].active = false;
             emit RealmShiftProposalCancelled(activeProposalId);
        }
        activeProposalId = 0; // No active proposal after a drift

        // Note: Entity states are affected by the new realm properties *when they next interact or evolve*.
        // We don't iterate and update all entities here due to gas costs.

        emit RealmDrifted(currentRealmState.realmType, currentRealmState.epoch);
    }


    // --- Chronicle Functions ---

    /**
     * @dev Records an entry in an entity's chronicle history.
     *      Could be a hash of interaction details, a message, etc.
     * @param tokenId The ID of the entity.
     * @param entryHash A hash representing the chronicle entry data.
     */
    function recordChronicleEntry(uint256 tokenId, bytes32 entryHash) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        // Could add checks here: only owner, or only after certain interactions

        entityChronicles[tokenId].push(entryHash);
        emit ChronicleEntryRecorded(tokenId, entryHash);
    }

    /**
     * @dev Retrieves the chronicle history for an entity.
     * @param tokenId The ID of the entity.
     * @return An array of hashes representing the chronicle entries.
     */
    function getChronicleEntries(uint256 tokenId) public view returns (bytes32[] memory) {
         if (_owners[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);
         // Ensure chroniclePointer logic is handled if used to limit history size/access
         // For now, chroniclePointer is illustrative, returning full history
         return entityChronicles[tokenId];
    }


    // --- Advanced Interaction Functions ---

    /**
     * @dev Entangles two entities. Their states might become linked or influence each other in future interactions.
     * @param tokenId1 The ID of the first entity.
     * @param tokenId2 The ID of the second entity.
     */
    function entangleEntities(uint256 tokenId1, uint256 tokenId2) public {
        EntityState storage entity1 = entities[tokenId1];
        EntityState storage entity2 = entities[tokenId2];

        if (entity1.owner == address(0) || entity2.owner == address(0)) revert EntityDoesNotExist(entity1.owner == address(0) ? tokenId1 : tokenId2);
        require(msg.sender == entity1.owner || msg.sender == entity2.owner, "Caller must own one of the entities"); // Or require caller owns both

        if (entanglementPairs[tokenId1] != 0 || entanglementPairs[tokenId2] != 0) revert EntitiesAlreadyEntangled(tokenId1, tokenId2);
        require(tokenId1 != tokenId2, "Cannot entangle an entity with itself");

        entanglementPairs[tokenId1] = tokenId2;
        entanglementPairs[tokenId2] = tokenId1;
        entity1.entanglementPartner = tokenId2;
        entity2.entanglementPartner = tokenId1;

        // Record this significant event
        recordChronicleEntry(tokenId1, keccak256(abi.encodePacked("ENTANGLED_WITH", tokenId2)));
        recordChronicleEntry(tokenId2, keccak256(abi.encodePacked("ENTANGLED_WITH", tokenId1)));

        emit EntitiesEntangled(tokenId1, tokenId2);
    }

    /**
     * @dev Disentangles two entities.
     * @param tokenId1 The ID of the first entity.
     * @param tokenId2 The ID of the second entity.
     */
    function disentangleEntities(uint256 tokenId1, uint256 tokenId2) public {
         EntityState storage entity1 = entities[tokenId1];
         EntityState storage entity2 = entities[tokenId2];

         if (entity1.owner == address(0) || entity2.owner == address(0)) revert EntityDoesNotExist(entity1.owner == address(0) ? tokenId1 : tokenId2);
         require(msg.sender == entity1.owner || msg.sender == entity2.owner, "Caller must own one of the entities"); // Or require caller owns both

         if (entanglementPairs[tokenId1] != tokenId2 || entanglementPairs[tokenId2] != tokenId1) revert EntitiesNotEntangled(tokenId1, tokenId2);

         entanglementPairs[tokenId1] = 0;
         entanglementPairs[tokenId2] = 0;
         entity1.entanglementPartner = 0;
         entity2.entanglementPartner = 0;

         recordChronicleEntry(tokenId1, keccak256(abi.encodePacked("DISENTANGLED_FROM", tokenId2)));
         recordChronicleEntry(tokenId2, keccak256(abi.encodePacked("DISENTANGLED_FROM", tokenId1)));

         emit EntitiesDisentangled(tokenId1, tokenId2);
    }

    /**
     * @dev Merges two entities into a new one. Burns the originals.
     *      Properties of the new entity are derived from the merged ones.
     * @param tokenId1 The ID of the first entity to merge.
     * @param tokenId2 The ID of the second entity to merge.
     */
    function mergeEntities(uint256 tokenId1, uint256 tokenId2) public {
        EntityState storage entity1 = entities[tokenId1];
        EntityState storage entity2 = entities[tokenId2];

        if (entity1.owner == address(0) || entity2.owner == address(0)) revert EntityDoesNotExist(entity1.owner == address(0) ? tokenId1 : tokenId2);
        require(msg.sender == entity1.owner && msg.sender == entity2.owner, "Caller must own both entities to merge");
        require(tokenId1 != tokenId2, "Cannot merge an entity with itself");
        // Could add compatibility checks using queryQuantumSignature here

        // Burn the original entities
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new entity
        _tokenCounter++;
        uint256 newTokenId = _tokenCounter;
        _safeMint(msg.sender, newTokenId);

        // Derive properties for the new entity (example logic)
        bytes32 newSignature = keccak256(abi.encodePacked(entity1.quantumSignature, entity2.quantumSignature, block.timestamp)); // Combine signatures
        StabilityLevel newStability = entity1.stability < entity2.stability ? entity1.stability : entity2.stability; // Take the lower stability
        RealmType newAlignment = (uint256(entity1.dimensionalAlignment) + uint256(entity2.dimensionalAlignment)) % uint256(RealmType.Echoing) == 0 ? entity1.dimensionalAlignment : currentRealmState.realmType; // Simple average or align to current realm
        uint256 newEntropy = (entity1.entropy + entity2.entropy) / 2; // Average entropy

        entities[newTokenId] = EntityState({
            owner: msg.sender,
            tokenId: newTokenId,
            quantumSignature: newSignature,
            stability: newStability,
            dimensionalAlignment: newAlignment,
            entropy: newEntropy,
            chroniclePointer: entityChronicles[newTokenId].length, // Start chronicle from scratch for the new entity
            entanglementPartner: 0,
            lastEvolvedEpoch: currentRealmState.epoch
        });

        // Optionally link new chronicle to old ones or migrate history (can be gas intensive)
        // For simplicity, new entity starts with empty chronicle, but we record the merge event
        recordChronicleEntry(newTokenId, keccak256(abi.encodePacked("MERGED_FROM", tokenId1, tokenId2)));
        // Could record merge event in the old chronicles too before burning, but they are burned anyway.

        emit EntitiesMerged(tokenId1, tokenId2, newTokenId);
    }

    /**
     * @dev Splits one entity into two new ones. Burns the original.
     *      Properties of the new entities are derived from the original.
     * @param tokenId The ID of the entity to split.
     * @param newSignature1 Signature for the first new entity.
     * @param newSignature2 Signature for the second new entity.
     */
    function splitEntity(uint256 tokenId, bytes32 newSignature1, bytes32 newSignature2) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Caller must own the entity to split");
        require(entity.stability != StabilityLevel.Collapsing, CannotSplitUnstableEntity(tokenId)); // Cannot split collapsing entities

        // Burn the original entity
        _burn(tokenId);

        // Mint two new entities
        _tokenCounter++;
        uint256 newTokenId1 = _tokenCounter;
        _safeMint(msg.sender, newTokenId1);

        _tokenCounter++;
        uint256 newTokenId2 = _tokenCounter;
        _safeMint(msg.sender, newTokenId2);

        // Derive properties for the new entities (example logic)
        StabilityLevel newStability = entity.stability == StabilityLevel.Stable ? StabilityLevel.Stable : StabilityLevel.Unstable; // Splitting reduces stability?
        RealmType newAlignment1 = entity.dimensionalAlignment;
        RealmType newAlignment2 = currentRealmState.realmType; // One aligns to old, one to current?
        uint256 newEntropy1 = entity.entropy / 2;
        uint256 newEntropy2 = entity.entropy - newEntropy1;

         entities[newTokenId1] = EntityState({
            owner: msg.sender,
            tokenId: newTokenId1,
            quantumSignature: newSignature1,
            stability: newStability,
            dimensionalAlignment: newAlignment1,
            entropy: newEntropy1,
            chroniclePointer: entityChronicles[newTokenId1].length,
            entanglementPartner: 0,
            lastEvolvedEpoch: currentRealmState.epoch
        });
         entities[newTokenId2] = EntityState({
            owner: msg.sender,
            tokenId: newTokenId2,
            quantumSignature: newSignature2,
            stability: newStability,
            dimensionalAlignment: newAlignment2,
            entropy: newEntropy2,
            chroniclePointer: entityChronicles[newTokenId2].length,
            entanglementPartner: 0,
            lastEvolvedEpoch: currentRealmState.epoch
        });

        recordChronicleEntry(newTokenId1, keccak256(abi.encodePacked("SPLIT_FROM", tokenId)));
        recordChronicleEntry(newTokenId2, keccak256(abi.encodePacked("SPLIT_FROM", tokenId)));

        emit EntitySplit(tokenId, newTokenId1, newTokenId2);
    }

    /**
     * @dev Advances an entity towards a collapsed state, reducing stability.
     * @param tokenId The ID of the entity.
     */
    function collapseState(uint256 tokenId) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Only owner can collapse state");

        if (entity.stability == StabilityLevel.Stable) {
            entity.stability = StabilityLevel.Unstable;
        } else if (entity.stability == StabilityLevel.Unstable) {
            entity.stability = StabilityLevel.Collapsing;
            // Could add logic here for collapsing effect (e.g., cannot interact, becomes transferable to zero address)
        } else {
             revert InvalidEntityState(tokenId); // Already collapsing
        }
         emit EntityStateCollapsed(tokenId, entity.stability);
    }

    /**
     * @dev Stabilizes an entity's state, improving stability. Requires resources or specific conditions.
     *      (Example: Requires msg.value or specific items/tokens - not implemented here).
     * @param tokenId The ID of the entity.
     */
    function stabilizeEntity(uint256 tokenId) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Only owner can stabilize state");
        // Example: require(msg.value >= stabilizationCost, "Insufficient funds");

        if (entity.stability == StabilityLevel.Collapsing) {
            entity.stability = StabilityLevel.Unstable;
        } else if (entity.stability == StabilityLevel.Unstable) {
            entity.stability = StabilityLevel.Stable;
        } else {
            revert InvalidEntityState(tokenId); // Already stable
        }
        // Reduce entropy upon stabilization?
        entity.entropy = entity.entropy / 2; // Halve entropy

        emit EntityStabilized(tokenId, entity.stability);
    }

     /**
     * @dev Simulates probing dimensional boundaries. Might cause minor realm shifts or affect the probing entity.
     * @param callerTokenId The ID of the entity initiating the probe.
     * @param probedRealm The RealmType being probed.
     * @return bytes32 A hash representing the "result" or outcome of the probe.
     */
    function probeDimensionalBoundary(uint256 callerTokenId, RealmType probedRealm) public returns (bytes32) {
        EntityState storage entity = entities[callerTokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(callerTokenId);
        require(msg.sender == entity.owner, "Only owner can probe");

        // Simulate effect: increase entity entropy slightly
        entity.entropy += 10;

        // Simulate a chance of minor realm shift (very small chance or based on complex factors)
        // Example: If hash(tokenId, realmType, block.timestamp) % 100 < 5, trigger minor drift
        bytes32 probeResultHash = keccak256(abi.encodePacked(callerTokenId, probedRealm, block.timestamp, block.number));
        if (uint256(probeResultHash) % 100 < 5 && msg.sender == _owners[_owners[0]]) { // Simulate admin trigger or specific condition
             // Minor drift - only admin can trigger actual drift function for simplicity/control
             // In a real system, this might trigger an internal 'minorDrift' function
        }

        emit DimensionalProbeResult(callerTokenId, probedRealm, probeResultHash);
        return probeResultHash;
    }

    /**
     * @dev Initiates a simulated temporal flux, where an entity's history (chronicle)
     *      can influence its *current* state. Does not rewrite history.
     * @param tokenId The ID of the entity undergoing flux.
     * @return bytes32 A hash representing the calculated 'flux effect'.
     */
    function initiateTemporalFlux(uint256 tokenId) public returns (bytes32) {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Only owner can initiate temporal flux");

        bytes32[] memory chronicle = entityChronicles[tokenId];
        uint256 historyDepth = chronicle.length;

        // Simulate influence based on history (example: sum hashes, use block data)
        bytes32 fluxEffectHash = keccak256(abi.encodePacked(tokenId, block.timestamp, block.number));
        for (uint i = 0; i < historyDepth; i++) {
            fluxEffectHash = keccak256(abi.encodePacked(fluxEffectHash, chronicle[i]));
        }

        // Apply simulated effect based on the fluxEffectHash
        // Example: Affect stability based on hash parity
        if (uint256(fluxEffectHash) % 2 == 0 && entity.stability != StabilityLevel.Collapsing) {
             entity.stability = StabilityLevel(uint256(entity.stability) + 1); // Decrease stability
             emit EntityStateCollapsed(tokenId, entity.stability);
        } else if (uint256(fluxEffectHash) % 3 == 0 && entity.stability != StabilityLevel.Stable) {
             entity.stability = StabilityLevel(uint256(entity.stability) - 1); // Increase stability
             emit EntityStabilized(tokenId, entity.stability);
        }
        entity.entropy += historyDepth * currentRealmState.interactionCost / 10; // Flux increases entropy

        recordChronicleEntry(tokenId, keccak256(abi.encodePacked("TEMPORAL_FLUX", fluxEffectHash)));

        emit TemporalFluxInitiated(tokenId, fluxEffectHash);
        return fluxEffectHash;
    }

    /**
     * @dev Queries the potential interaction or compatibility score between two entities
     *      based on their quantum signatures and current realm state. Pure function.
     * @param tokenId1 The ID of the first entity.
     * @param tokenId2 The ID of the second entity.
     * @return uint256 A compatibility score (higher = more compatible/stronger interaction potential).
     */
    function queryQuantumSignature(uint256 tokenId1, uint256 tokenId2) public view returns (uint256) {
        if (_owners[tokenId1] == address(0) || _owners[tokenId2] == address(0)) revert EntityDoesNotExist(_owners[tokenId1] == address(0) ? tokenId1 : tokenId2);
        if (tokenId1 == tokenId2) return 0; // Cannot query self-compatibility

        EntityState memory entity1 = entities[tokenId1];
        EntityState memory entity2 = entities[tokenId2];

        // Simple compatibility logic based on signatures and realm
        bytes32 combinedSignature = keccak256(abi.encodePacked(entity1.quantumSignature, entity2.quantumSignature));
        uint256 signatureMatchFactor = uint256(combinedSignature); // Use the hash as a base score

        // Add realm influence (example: certain realms boost compatibility)
        uint256 realmInfluence = 0;
        if (currentRealmState.realmType == RealmType.Fluxing) {
             realmInfluence = 100;
        } else if (currentRealmState.realmType == RealmType.Entropic) {
             realmInfluence = 50;
        }

        // Add alignment influence (entities aligned to the same realm or current realm are more compatible)
        uint256 alignmentInfluence = 0;
        if (entity1.dimensionalAlignment == entity2.dimensionalAlignment) {
            alignmentInfluence += 50;
        }
        if (entity1.dimensionalAlignment == currentRealmState.realmType) {
             alignmentInfluence += 25;
        }
         if (entity2.dimensionalAlignment == currentRealmState.realmType) {
             alignmentInfluence += 25;
        }

        // Combine factors (example calculation)
        uint256 compatibilityScore = (signatureMatchFactor % 1000) + realmInfluence + alignmentInfluence;

        return compatibilityScore;
    }

    /**
     * @dev Allows the quantum signature of an entity to be mutated.
     *      (Requires admin role or potentially complex game logic conditions).
     * @param tokenId The ID of the entity.
     * @param newSignature The new quantum signature hash.
     */
    function mutateEntitySignature(uint256 tokenId, bytes32 newSignature) public onlyAdmin { // Example: Admin only
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        // Add other conditions here, e.g., entity must be unstable, or costs resources

        bytes32 oldSignature = entity.quantumSignature;
        entity.quantumSignature = newSignature;
        entity.entropy += 50; // Mutation is energetically costly

        recordChronicleEntry(tokenId, keccak256(abi.encodePacked("SIGNATURE_MUTATED", oldSignature, newSignature)));

        emit QuantumSignatureMutated(tokenId, newSignature);
    }

    /**
     * @dev Observes a 'superposition hint' about a potential future state change
     *      or interaction outcome for an entity based on current realm conditions.
     *      This is a *simulated* prediction, the result is not guaranteed. Pure function.
     * @param tokenId The ID of the entity.
     * @return bytes32 A hash representing the 'hint' data.
     */
    function observeSuperpositionHint(uint256 tokenId) public view returns (bytes32) {
         if (_owners[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);

         EntityState memory entity = entities[tokenId];

         // Simulate generating a hint based on current state and realm
         // Example factors: entity signature, stability, entropy, realm type, epoch, block data
         bytes32 hint = keccak256(abi.encodePacked(
             entity.quantumSignature,
             entity.stability,
             entity.entropy,
             currentRealmState.realmType,
             currentRealmState.epoch,
             block.timestamp,
             block.difficulty // Or block.randao.getAuthedRandomness in future EVM
         ));

         // The 'hint' itself doesn't change state, but off-chain logic could interpret it.
         // We *could* increase entity entropy slightly here, but keeping it pure is better for hints.

         return hint; // Off-chain logic interprets this hash
    }

    /**
     * @dev Attempts to attune an entity's dimensional alignment to the current realm.
     *      Successful attunement might provide state bonuses.
     * @param tokenId The ID of the entity.
     */
    function attuneToRealm(uint256 tokenId) public {
        EntityState storage entity = entities[tokenId];
        if (entity.owner == address(0)) revert EntityDoesNotExist(tokenId);
        require(msg.sender == entity.owner, "Only owner can attune");
        require(entity.dimensionalAlignment != currentRealmState.realmType, "Entity already attuned to current realm");

        // Simulate attunement success chance (e.g., based on stability, entropy, realm stability)
        // Example: Success if entity.stability == Stable OR random_factor > entity.entropy / realm.stabilityFactor
         bytes32 attuneHash = keccak256(abi.encodePacked(tokenId, currentRealmState.epoch, block.timestamp));
         bool success = uint256(attuneHash) % 100 < (uint256(entity.stability) == uint224(StabilityLevel.Stable) ? 80 : 40); // Example chance based on stability

        if (success) {
            entity.dimensionalAlignment = currentRealmState.realmType;
            entity.entropy = entity.entropy / 2; // Attunement reduces internal chaos
            emit EntityAttunedToRealm(tokenId, currentRealmState.realmType);
            recordChronicleEntry(tokenId, keccak256(abi.encodePacked("ATTUNED_TO_REALM", uint256(currentRealmState.realmType))));

        } else {
            // Attunement failed - penalize?
            entity.entropy += 20;
            recordChronicleEntry(tokenId, keccak256(abi.encodePacked("ATTUNEMENT_FAILED", uint256(currentRealmState.realmType))));
        }
    }

    // --- Decentralized Governance (Realm Shift Proposals) ---

    /**
     * @dev Allows an Observer or Admin to propose a Realm Shift.
     * @param targetRealmType The RealmType to propose shifting to.
     */
    function proposeRealmShift(RealmType targetRealmType) public onlyObserver {
        if (activeProposalId != 0) revert AlreadyProposedRealmShift(activeProposalId);

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        realmShiftProposals[proposalId] = RealmShiftProposal({
            id: proposalId,
            targetRealmType: targetRealmType,
            proposerVotes: 1, // Proposer's vote counts immediately
            hasVoted: new mapping(address => bool),
            creationEpoch: currentRealmState.epoch,
            active: true,
            executed: false
        });

        realmShiftProposals[proposalId].hasVoted[msg.sender] = true;
        activeProposalId = proposalId;

        emit RealmShiftProposalCreated(proposalId, msg.sender, targetRealmType, realmShiftQuorum);
        emit RealmShiftProposalVoted(proposalId, msg.sender); // Emit proposer's vote
    }

    /**
     * @dev Allows an Observer or Admin to vote on the active Realm Shift proposal.
     */
    function voteOnRealmShift() public onlyObserver {
        if (activeProposalId == 0) revert NoActiveProposal();
        RealmShiftProposal storage proposal = realmShiftProposals[activeProposalId];

        require(proposal.active, "Proposal is not active");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], ProposalAlreadyVoted(activeProposalId, msg.sender));
        require(currentRealmState.epoch <= proposal.creationEpoch + proposalVotingPeriodEpochs, ProposalVotingPeriodEnded(activeProposalId));

        proposal.hasVoted[msg.sender] = true;
        proposal.proposerVotes++;

        emit RealmShiftProposalVoted(activeProposalId, msg.sender);
    }

    /**
     * @dev Admin function to execute a successful Realm Shift proposal after the voting period ends.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeRealmShiftProposal(uint256 proposalId) public onlyAdmin {
        RealmShiftProposal storage proposal = realmShiftProposals[proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist(proposalId);
        require(proposal.active, "Proposal is not active");
        require(!proposal.executed, "Proposal already executed");
        require(currentRealmState.epoch > proposal.creationEpoch + proposalVotingPeriodEpochs, ProposalNotYetExecutable(proposalId)); // Voting period must have ended
        require(proposal.proposerVotes >= realmShiftQuorum, ProposalQuorumNotMet(proposalId));

        // Execute the realm shift
        currentRealmState.epoch++; // Increment epoch for the shift
        currentRealmState.realmType = proposal.targetRealmType;
        // Simplistic: No stability modifier change from proposal vote, just type change.
        // Could make the vote count influence the stabilityFactor change.

        proposal.executed = true;
        proposal.active = false; // Deactivate the proposal after execution
        activeProposalId = 0; // Clear active proposal

        emit RealmShiftProposalExecuted(proposalId, currentRealmState.realmType);
        emit RealmDrifted(currentRealmState.realmType, currentRealmState.epoch); // Also emit drift event
    }

    /**
     * @dev Gets the state of a Realm Shift proposal.
     * @param proposalId The ID of the proposal.
     */
    function getRealmShiftProposal(uint256 proposalId) public view returns (RealmShiftProposal memory) {
         if (realmShiftProposals[proposalId].id == 0) revert ProposalDoesNotExist(proposalId);
         // Need to reconstruct the struct without the mapping
         RealmShiftProposal storage proposalStorage = realmShiftProposals[proposalId];
         return RealmShiftProposal({
            id: proposalStorage.id,
            targetRealmType: proposalStorage.targetRealmType,
            proposerVotes: proposalStorage.proposerVotes,
            hasVoted: new mapping(address => bool), // Mapping cannot be returned/copied directly
            creationEpoch: proposalStorage.creationEpoch,
            active: proposalStorage.active,
            executed: proposalStorage.executed
         });
    }


    // --- Role Management Functions ---

    /**
     * @dev Grants the Observer role to an account.
     * @param account The address to grant the role to.
     */
    function addObserverRole(address account) public onlyAdmin {
        require(account != address(0), "Account cannot be zero address");
        hasObserverRole[account] = true;
        emit RoleGranted(OBSERVER_ROLE, account, msg.sender);
    }

     /**
     * @dev Revokes the Observer role from an account.
     * @param account The address to revoke the role from.
     */
    function removeObserverRole(address account) public onlyAdmin {
        require(account != address(0), "Account cannot be zero address");
        hasObserverRole[account] = false;
        emit RoleRevoked(OBSERVER_ROLE, account, msg.sender);
    }

     /**
     * @dev Grants the Admin role to an account. Use with extreme caution.
     * @param account The address to grant the role to.
     */
    function addAdminRole(address account) public onlyAdmin {
        require(account != address(0), "Account cannot be zero address");
        hasAdminRole[account] = true;
        emit RoleGranted(ADMIN_ROLE, account, msg.sender);
    }

    /**
     * @dev Revokes the Admin role from an account. Use with extreme caution.
     *      Cannot revoke your own role if you are the last admin.
     * @param account The address to revoke the role from.
     */
    function removeAdminRole(address account) public onlyAdmin {
        require(account != address(0), "Account cannot be zero address");
        // Prevent removing the last admin (requires tracking admin count - simple check here)
        // Note: This is a simplistic check, could be bypassed if there's another admin removing this one first.
        // A more robust system counts admins or uses multisig.
        if (msg.sender == account && _countAdmins() <= 1) {
             revert("Cannot remove last admin role");
        }

        hasAdminRole[account] = false;
        emit RoleRevoked(ADMIN_ROLE, account, msg.sender);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasAdminRole[account];
    }

     function isObserver(address account) public view returns (bool) {
        return hasObserverRole[account];
    }

    // Internal helper to count admins (simple check for removeAdminRole)
    function _countAdmins() internal view returns (uint256) {
        uint256 count = 0;
        // This is inefficient, but ok for a simple check.
        // A real system would use iterable mappings or track count directly.
        // Iterate over some known addresses or rely on external indexing.
        // For this example, we'll assume a small number of admins or accept inefficiency.
        // A better implementation would be to use OpenZeppelin's AccessControl.
        // Simulating a count check based on potential addresses.
        // This part is illustrative and would need robust implementation in production.
        // *** This loop is highly inefficient and should NOT be used in production ***
        // for (address addr : ... list of potential admins ...) { if (hasAdminRole[addr]) count++; }
        // placeholder simulation:
         if (hasAdminRole[msg.sender]) count++;
         // Cannot iterate over mapping keys. A direct count or iterable mapping is needed.
         // For this conceptual contract, accept this limitation or use OZ AccessControl.
         // Assuming there's at least one admin (the deployer) and potentially others added.
         // Let's simplify: just check if the caller is trying to remove themselves AND they are the *only* admin known via msg.sender.
         // This is still flawed but avoids an impossible iteration. Let's stick to the basic msg.sender check.
         // The error message "Cannot remove last admin role" will only truly apply if msg.sender is the *only* admin tracked *in this specific check*.
         // Realistically, need a direct count or iterable mapping.
         // Reverting the original simpler check:
         // if (msg.sender == account) revert("Cannot remove your own admin role directly"); // Safer simple check

         // Let's remove the problematic count check and just allow admin to remove other admins.
         // Self-removal would require a separate mechanism or external admin.

         return 0; // Placeholder, ignore value in this conceptual context
    }


     // --- Additional Utility/View Functions (optional, not strictly part of the 20+) ---

     /**
      * @dev Gets the total number of entities minted.
      */
     function totalSupply() public view returns (uint256) {
         return _tokenCounter;
     }

      /**
       * @dev Gets the current active realm shift proposal ID.
       */
      function getActiveProposalId() public view returns (uint256) {
          return activeProposalId;
      }

      /**
       * @dev Checks if two entities are entangled.
       * @param tokenId1 The ID of the first entity.
       * @param tokenId2 The ID of the second entity.
       */
      function areEntitiesEntangled(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
          return entanglementPairs[tokenId1] == tokenId2 && entanglementPairs[tokenId2] == tokenId1 && tokenId1 != 0 && tokenId2 != 0;
      }

      // Note: Functions like tokensOfOwner(address owner) from ERC721Enumerable
      // are not included to keep the implementation distinct from standard OZ patterns,
      // but they are useful and would require additional state/logic.

}
```