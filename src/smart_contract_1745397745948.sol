Okay, let's design a smart contract that manages unique, evolving digital assets ("Quantums") created from foundational components ("Fragments") according to user-defined and approved "Protocols". This allows for a generative system with dynamic traits and a permissioned creation/mutation process, distinct from standard token contracts.

We will call this contract `QuantumQuill`.

**Concept:**

*   **Fragments:** Are discoverable, immutable pieces of data or ideas represented on-chain (e.g., a content hash, metadata link). Users can discover and register them. Discovery grants initial usage rights.
*   **Protocols:** Define the rules for combining Fragments into Quantums (Synthesis Protocols) or modifying existing Quantums with additional Fragments (Mutation Protocols). These require approval by a specific role (e.g., a Protocol Manager).
*   **Quantums:** Are unique, non-fungible assets (like NFTs, but custom implemented here). They are created via Synthesis Protocols using Fragments. Crucially, they have a dynamic `state` stored as `bytes`, which can be altered by applying Mutation Protocols and additional Fragments. The interpretation of this state and rendering of the asset (e.g., visual art, text) happens off-chain using a designated "Metadata Renderer", referencing the on-chain state.
*   **Usage Rights:** Discovering a Fragment gives the discoverer the right to use it in Protocols. These rights can be granted to others.
*   **Roles:** Contract Owner, Protocol Manager.

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  ** Custom Errors**
3.  ** Events**
4.  ** Structs:**
    *   `Fragment`: Represents a discovered piece of data.
    *   `SynthesisProtocol`: Rules for creating a Quantum.
    *   `MutationProtocol`: Rules for evolving a Quantum's state.
    *   `Quantum`: Represents a unique, dynamic asset.
5.  ** State Variables:**
    *   Ownership (`owner`)
    *   Role Management (`protocolManager`, `metadataRenderer`)
    *   Counters (`nextFragmentId`, `nextProtocolId`, `nextQuantumId`)
    *   Data Storage:
        *   Fragments (`fragmentsById`, `fragmentExistsByHash`)
        *   Fragment Discovery (`fragmentsByDiscoverer`)
        *   Fragment Usage Rights (`fragmentUsageRights`)
        *   Protocols (`synthesisProtocolsById`, `mutationProtocolsById`)
        *   Quantums (`quantumsById`, `quantumOwner`, `quantumsByOwner`)
        *   Quantum Provenance/History (`quantumSourceFragments`, `quantumMutationHistory`)
6.  ** Modifiers**
7.  ** Constructor**
8.  ** Functions:**
    *   Owner/Admin/Role Management (transfer ownership, set roles)
    *   Fragment Discovery & Management (discover, query, manage usage rights)
    *   Protocol Management (propose, approve, query)
    *   Quantum Synthesis (create new Quantums)
    *   Quantum Mutation (evolve existing Quantums)
    *   Quantum Querying (get details, owner, state, history, metadata URI)
    *   Quantum Transfer (ownership)
    *   Utility/ERC165 (supportsInterface)

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets initial counters.
2.  `renounceOwnership()`: Relinquishes contract ownership (standard).
3.  `transferOwnership(address newOwner)`: Transfers contract ownership (standard).
4.  `setProtocolManager(address _protocolManager)`: Sets the address responsible for proposing/approving protocols (Owner only).
5.  `getProtocolManager()`: Gets the current protocol manager address.
6.  `setMetadataRenderer(address _metadataRenderer)`: Sets the address/URI prefix responsible for rendering Quantum metadata (Owner only).
7.  `getMetadataRenderer()`: Gets the current metadata renderer address/prefix.
8.  `discoverFragment(bytes32 contentHash, string memory metadataUri)`: Registers a new unique Fragment. Assigns discoverer and ID.
9.  `getFragment(uint256 fragmentId)`: Retrieves all details for a given Fragment ID.
10. `getFragmentContentHash(uint256 fragmentId)`: Retrieves only the content hash for a Fragment.
11. `getFragmentMetadataUri(uint256 fragmentId)`: Retrieves only the metadata URI for a Fragment.
12. `getFragmentDiscoverer(uint256 fragmentId)`: Retrieves the discoverer address for a Fragment.
13. `getFragmentsByDiscoverer(address discoverer)`: Retrieves a list of Fragment IDs discovered by an address.
14. `getTotalFragments()`: Gets the total number of discovered Fragments.
15. `grantFragmentUsageRight(uint256 fragmentId, address user)`: Grants usage rights for a specific Fragment to another user (Discoverer only).
16. `revokeFragmentUsageRight(uint256 fragmentId, address user)`: Revokes usage rights for a specific Fragment from another user (Discoverer only).
17. `isFragmentUsable(uint256 fragmentId, address user)`: Checks if a user has usage rights for a Fragment (either discoverer or explicitly granted).
18. `proposeSynthesisProtocol(string memory name, string memory description, uint256[] memory requiredFragments, bytes memory initialQuantumState)`: Proposes a new Synthesis Protocol (Protocol Manager only). `requiredFragments` could be fragment IDs or pattern identifiers. `initialQuantumState` provides base state data.
19. `approveSynthesisProtocol(uint256 protocolId)`: Approves a proposed Synthesis Protocol, making it usable (Protocol Manager only).
20. `getSynthesisProtocol(uint256 protocolId)`: Retrieves details of a Synthesis Protocol.
21. `getTotalSynthesisProtocols()`: Gets the total number of proposed Synthesis Protocols.
22. `synthesizeQuantum(uint256 protocolId, uint256[] memory fragmentIds)`: Creates a new Quantum using an approved Synthesis Protocol and required Fragments. Consumes/links fragments, sets initial state, assigns ownership to caller.
23. `proposeMutationProtocol(string memory name, string memory description, uint256[] memory requiredFragments, bytes memory stateTransformationCode)`: Proposes a new Mutation Protocol (Protocol Manager only). `requiredFragments` are needed for mutation. `stateTransformationCode` is *conceptual* - in reality, it's more likely a simple ID or enum indicating a predefined on-chain transformation logic, or parameters for a generic transformation function. We'll use `bytes` to represent abstract transformation data.
24. `approveMutationProtocol(uint256 protocolId)`: Approves a proposed Mutation Protocol (Protocol Manager only).
25. `getMutationProtocol(uint256 protocolId)`: Retrieves details of a Mutation Protocol.
26. `getTotalMutationProtocols()`: Gets the total number of proposed Mutation Protocols.
27. `mutateQuantum(uint256 quantumId, uint256 protocolId, uint256[] memory additionalFragmentIds)`: Applies an approved Mutation Protocol and additional Fragments to an existing Quantum, modifying its state. Caller must own the Quantum and have usage rights for fragments.
28. `getQuantum(uint256 quantumId)`: Retrieves basic details of a Quantum (excluding potentially large state/history).
29. `getQuantumOwner(uint256 quantumId)`: Gets the owner of a Quantum.
30. `getQuantumCurrentState(uint256 quantumId)`: Retrieves the current dynamic state data (`bytes`) of a Quantum.
31. `getQuantumSourceFragments(uint256 quantumId)`: Retrieves the list of Fragment IDs used to synthesize a Quantum.
32. `getQuantumMutationHistory(uint256 quantumId)`: Retrieves a list of Mutation Protocol IDs applied to a Quantum.
33. `getQuantumsByOwner(address owner)`: Retrieves a list of Quantum IDs owned by an address.
34. `getTotalQuantums()`: Gets the total number of created Quantums.
35. `transferQuantum(address to, uint256 quantumId)`: Transfers ownership of a Quantum (Owner of Quantum only).
36. `getQuantumMetadataUri(uint256 quantumId)`: Constructs and returns a URI for off-chain metadata, likely referencing the `metadataRenderer` and the Quantum's state.
37. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function, signaling support for custom interfaces (e.g., a hypothetical IDynamicStateNFT).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumQuill
 * @dev A creative smart contract for discovering Fragments, defining Protocols,
 *      and synthesizing/mutating unique, dynamic Quantums.
 *
 * Outline:
 * 1. Errors & Events
 * 2. Structs: Fragment, SynthesisProtocol, MutationProtocol, Quantum
 * 3. State Variables: Ownership, Roles, Counters, Data Mappings
 * 4. Modifiers
 * 5. Constructor
 * 6. Functions (>= 20)
 *    - Owner/Admin/Role Management
 *    - Fragment Discovery & Management
 *    - Protocol Management (Synthesis & Mutation)
 *    - Quantum Synthesis
 *    - Quantum Mutation (Dynamic State Evolution)
 *    - Quantum Querying (Details, State, History, Metadata)
 *    - Quantum Transfer
 *    - Utility (ERC165)
 *
 * Function Summary:
 * - Core Contract Management: constructor, renounceOwnership, transferOwnership,
 *   setProtocolManager, getProtocolManager, setMetadataRenderer, getMetadataRenderer
 * - Fragment Lifecycle: discoverFragment, getFragment, getFragmentContentHash,
 *   getFragmentMetadataUri, getFragmentDiscoverer, getFragmentsByDiscoverer,
 *   getTotalFragments, grantFragmentUsageRight, revokeFragmentUsageRight, isFragmentUsable
 * - Protocol Management: proposeSynthesisProtocol, approveSynthesisProtocol,
 *   getSynthesisProtocol, getTotalSynthesisProtocols, proposeMutationProtocol,
 *   approveMutationProtocol, getMutationProtocol, getTotalMutationProtocols
 * - Quantum Lifecycle: synthesizeQuantum, mutateQuantum, transferQuantum
 * - Quantum Querying: getQuantum, getQuantumOwner, getQuantumCurrentState,
 *   getQuantumSourceFragments, getQuantumMutationHistory, getQuantumsByOwner,
 *   getTotalQuantums, getQuantumMetadataUri
 * - Standard Utility: supportsInterface
 *
 * Advanced Concepts:
 * - Dynamic State: Quantum's state (`bytes`) can be modified on-chain via Mutation Protocols.
 * - Protocol-Based Creation/Evolution: Rules for asset generation and evolution are defined and approved on-chain.
 * - Fragment Provenance & Usage Rights: Tracks fragment originators and manages who can use which fragments.
 * - Off-chain Metadata Rendering: Contract provides hooks for off-chain services to render dynamic assets based on on-chain state.
 */

error NotContractOwner();
error NotProtocolManager();
error FragmentAlreadyExists();
error FragmentNotFound();
error FragmentNotUsable(address user, uint256 fragmentId);
error ProtocolNotFound();
error ProtocolNotApproved(uint256 protocolId);
error InvalidProtocolRequirements(); // Generic error for protocol checks
error QuantumNotFound();
error NotQuantumOwner();
error FragmentRequiredForProtocolNotFound(uint256 requiredFragmentId);
error ProtocolStateTransformationFailed(); // Indicates logic error during state mutation

enum ProtocolStatus { Proposed, Approved, Rejected }

struct Fragment {
    uint256 id;
    bytes32 contentHash; // Unique hash representing the fragment's content
    string metadataUri; // URI for off-chain metadata describing the fragment
    address discoverer;
    uint40 discoveryTimestamp;
}

struct SynthesisProtocol {
    uint256 id;
    string name;
    string description;
    uint256[] requiredFragmentIds; // Specific fragment IDs required for synthesis (simple example)
    bytes initialQuantumState; // Initial state data for the Quantum created by this protocol
    address proposer;
    ProtocolStatus status;
}

struct MutationProtocol {
    uint256 id;
    string name;
    string description;
    uint256[] requiredFragmentIds; // Specific fragment IDs required for mutation (simple example)
    // In a real advanced contract, this would be more complex, e.g.,
    // - An index pointing to a hardcoded state transformation function
    // - Parameters for a generic state transformation function
    // For this example, we'll represent it abstractly with bytes.
    bytes stateTransformationData;
    address proposer;
    ProtocolStatus status;
}

struct Quantum {
    uint256 id;
    uint256 synthesisProtocolId; // Protocol used for creation
    bytes state; // The dynamic state of the Quantum
    uint40 creationTimestamp;
}

contract QuantumQuill {
    address private _owner;
    address private _protocolManager;
    address private _metadataRenderer; // Address or URI prefix for off-chain renderer

    uint256 private _nextFragmentId = 1;
    uint256 private _nextProtocolId = 1; // Used for both Synthesis and Mutation Protocols
    uint256 private _nextQuantumId = 1;

    // --- Fragment Storage ---
    mapping(uint256 => Fragment) private _fragmentsById;
    mapping(bytes32 => bool) private _fragmentExistsByHash; // To check uniqueness
    mapping(address => uint256[]) private _fragmentsByDiscoverer;
    // Mapping: FragmentID => UserAddress => HasUsageRight
    mapping(uint256 => mapping(address => bool)) private _fragmentGrantedUsageRights;

    // --- Protocol Storage ---
    mapping(uint256 => SynthesisProtocol) private _synthesisProtocolsById;
    mapping(uint256 => MutationProtocol) private _mutationProtocolsById;

    // --- Quantum Storage ---
    mapping(uint256 => Quantum) private _quantumsById;
    mapping(uint256 => address) private _quantumOwner; // QuantumId => OwnerAddress
    mapping(address => uint256[]) private _quantumsByOwner; // OwnerAddress => QuantumIds
    mapping(uint256 => uint256[]) private _quantumSourceFragments; // QuantumId => FragmentIds used for synthesis
    mapping(uint256 => uint256[]) private _quantumMutationHistory; // QuantumId => MutationProtocolIds applied

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ProtocolManagerUpdated(address indexed oldManager, address indexed newManager);
    event MetadataRendererUpdated(address indexed oldRenderer, address indexed newRenderer);
    event FragmentDiscovered(uint256 indexed fragmentId, bytes32 contentHash, address indexed discoverer, string metadataUri);
    event FragmentUsageRightGranted(uint256 indexed fragmentId, address indexed granter, address indexed user);
    event FragmentUsageRightRevoked(uint256 indexed fragmentId, address indexed revoker, address indexed user);
    event ProtocolProposed(uint256 indexed protocolId, bool isSynthesis, address indexed proposer);
    event ProtocolStatusUpdated(uint256 indexed protocolId, ProtocolStatus newStatus);
    event QuantumSynthesized(uint256 indexed quantumId, uint256 indexed protocolId, address indexed owner);
    event QuantumMutated(uint256 indexed quantumId, uint256 indexed protocolId, bytes newState);
    event QuantumTransferred(address indexed from, address indexed to, uint256 indexed quantumId);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotContractOwner();
        _;
    }

    modifier onlyProtocolManager() {
        if (msg.sender != _protocolManager) revert NotProtocolManager();
        _;
    }

    // Checks if the user is the discoverer or has been explicitly granted rights
    modifier onlyDiscovererOrGranted(uint256 fragmentId) {
        Fragment storage fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) revert FragmentNotFound(); // Ensure fragment exists

        if (msg.sender != fragment.discoverer && !_fragmentGrantedUsageRights[fragmentId][msg.sender]) {
             revert FragmentNotUsable(msg.sender, fragmentId);
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Owner/Admin/Role Management ---

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert NotContractOwner(); // Cannot transfer to zero address
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Sets the address authorized to propose and approve protocols.
     * @param _protocolManager The address of the new protocol manager.
     */
    function setProtocolManager(address _protocolManager) public onlyOwner {
        address oldManager = _protocolManager;
        _protocolManager = _protocolManager;
        emit ProtocolManagerUpdated(oldManager, _protocolManager);
    }

    /**
     * @dev Returns the address of the protocol manager.
     */
    function getProtocolManager() public view returns (address) {
        return _protocolManager;
    }

    /**
     * @dev Sets the address or URI prefix responsible for rendering Quantum metadata.
     * This is typically an off-chain service.
     * @param _metadataRenderer The address or URI base for the metadata renderer.
     */
    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        address oldRenderer = _metadataRenderer;
        _metadataRenderer = _metadataRenderer;
        emit MetadataRendererUpdated(oldRenderer, _metadataRenderer);
    }

    /**
     * @dev Returns the address or URI prefix of the metadata renderer.
     */
    function getMetadataRenderer() public view returns (address) {
        return _metadataRenderer;
    }

    // --- Fragment Discovery & Management ---

    /**
     * @dev Allows users to discover and register new unique fragments.
     * @param contentHash A unique identifier for the fragment's content.
     * @param metadataUri A URI pointing to off-chain metadata about the fragment.
     * @return The ID of the newly discovered fragment.
     */
    function discoverFragment(bytes32 contentHash, string memory metadataUri) public returns (uint256) {
        if (_fragmentExistsByHash[contentHash]) revert FragmentAlreadyExists();

        uint256 fragmentId = _nextFragmentId++;
        _fragmentsById[fragmentId] = Fragment({
            id: fragmentId,
            contentHash: contentHash,
            metadataUri: metadataUri,
            discoverer: msg.sender,
            discoveryTimestamp: uint40(block.timestamp)
        });
        _fragmentExistsByHash[contentHash] = true;
        _fragmentsByDiscoverer[msg.sender].push(fragmentId);

        emit FragmentDiscovered(fragmentId, contentHash, msg.sender, metadataUri);

        return fragmentId;
    }

    /**
     * @dev Retrieves details for a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return The Fragment struct.
     */
    function getFragment(uint256 fragmentId) public view returns (Fragment memory) {
        Fragment memory fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) revert FragmentNotFound();
        return fragment;
    }

    /**
     * @dev Retrieves the content hash for a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return The fragment's content hash.
     */
    function getFragmentContentHash(uint256 fragmentId) public view returns (bytes32) {
         Fragment memory fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) revert FragmentNotFound();
        return fragment.contentHash;
    }

     /**
     * @dev Retrieves the metadata URI for a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return The fragment's metadata URI.
     */
    function getFragmentMetadataUri(uint256 fragmentId) public view returns (string memory) {
         Fragment memory fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) revert FragmentNotFound();
        return fragment.metadataUri;
    }

    /**
     * @dev Retrieves the discoverer address for a specific fragment.
     * @param fragmentId The ID of the fragment.
     * @return The address of the discoverer.
     */
    function getFragmentDiscoverer(uint256 fragmentId) public view returns (address) {
         Fragment memory fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) revert FragmentNotFound();
        return fragment.discoverer;
    }

    /**
     * @dev Retrieves a list of fragment IDs discovered by an address.
     * @param discoverer The address to query.
     * @return An array of fragment IDs.
     */
    function getFragmentsByDiscoverer(address discoverer) public view returns (uint256[] memory) {
        return _fragmentsByDiscoverer[discoverer];
    }

    /**
     * @dev Gets the total count of discovered fragments.
     */
    function getTotalFragments() public view returns (uint256) {
        return _nextFragmentId - 1;
    }

    /**
     * @dev Grants usage rights for a fragment to another user. Only the discoverer can do this.
     * @param fragmentId The ID of the fragment.
     * @param user The address to grant rights to.
     */
    function grantFragmentUsageRight(uint256 fragmentId, address user) public onlyDiscovererOrGranted(fragmentId) {
        // Check caller is the actual discoverer before granting
        if (msg.sender != _fragmentsById[fragmentId].discoverer) revert FragmentNotUsable(msg.sender, fragmentId);

        _fragmentGrantedUsageRights[fragmentId][user] = true;
        emit FragmentUsageRightGranted(fragmentId, msg.sender, user);
    }

    /**
     * @dev Revokes usage rights for a fragment from a user. Only the discoverer can do this.
     * @param fragmentId The ID of the fragment.
     * @param user The address to revoke rights from.
     */
    function revokeFragmentUsageRight(uint256 fragmentId, address user) public onlyDiscovererOrGranted(fragmentId) {
         // Check caller is the actual discoverer before revoking
        if (msg.sender != _fragmentsById[fragmentId].discoverer) revert FragmentNotUsable(msg.sender, fragmentId);

        _fragmentGrantedUsageRights[fragmentId][user] = false;
         emit FragmentUsageRightRevoked(fragmentId, msg.sender, user);
    }

    /**
     * @dev Checks if a user has usage rights for a specific fragment (discoverer or granted).
     * @param fragmentId The ID of the fragment.
     * @param user The address to check.
     * @return True if the user can use the fragment, false otherwise.
     */
    function isFragmentUsable(uint256 fragmentId, address user) public view returns (bool) {
        Fragment memory fragment = _fragmentsById[fragmentId];
        if (fragment.discoverer == address(0)) return false; // Fragment doesn't exist

        return user == fragment.discoverer || _fragmentGrantedUsageRights[fragmentId][user];
    }

    // --- Protocol Management ---

    /**
     * @dev Proposes a new Synthesis Protocol. Requires Protocol Manager role.
     * @param name Protocol name.
     * @param description Protocol description.
     * @param requiredFragmentIds List of fragment IDs required for synthesis.
     * @param initialQuantumState Initial state data for the resulting Quantum.
     * @return The ID of the proposed protocol.
     */
    function proposeSynthesisProtocol(
        string memory name,
        string memory description,
        uint256[] memory requiredFragmentIds,
        bytes memory initialQuantumState
    ) public onlyProtocolManager returns (uint256) {
        uint256 protocolId = _nextProtocolId++;
        _synthesisProtocolsById[protocolId] = SynthesisProtocol({
            id: protocolId,
            name: name,
            description: description,
            requiredFragmentIds: requiredFragmentIds,
            initialQuantumState: initialQuantumState,
            proposer: msg.sender,
            status: ProtocolStatus.Proposed
        });
        emit ProtocolProposed(protocolId, true, msg.sender);
        return protocolId;
    }

    /**
     * @dev Approves a proposed Synthesis Protocol, making it available for use. Requires Protocol Manager role.
     * @param protocolId The ID of the protocol to approve.
     */
    function approveSynthesisProtocol(uint256 protocolId) public onlyProtocolManager {
        SynthesisProtocol storage protocol = _synthesisProtocolsById[protocolId];
        if (protocol.proposer == address(0) || protocol.status != ProtocolStatus.Proposed) revert ProtocolNotFound(); // Protocol doesn't exist or not in proposed state

        protocol.status = ProtocolStatus.Approved;
        emit ProtocolStatusUpdated(protocolId, ProtocolStatus.Approved);
    }

    /**
     * @dev Retrieves details of a Synthesis Protocol.
     * @param protocolId The ID of the protocol.
     * @return The SynthesisProtocol struct.
     */
    function getSynthesisProtocol(uint256 protocolId) public view returns (SynthesisProtocol memory) {
        SynthesisProtocol memory protocol = _synthesisProtocolsById[protocolId];
         if (protocol.proposer == address(0)) revert ProtocolNotFound();
         return protocol;
    }

    /**
     * @dev Gets the total count of proposed protocols (both types).
     */
    function getTotalSynthesisProtocols() public view returns (uint256) {
         // This is not quite accurate as _nextProtocolId is shared.
         // A proper count would require iterating or a separate counter.
         // For simplicity, we'll return the next ID minus 1 as a proxy for total proposed.
        return _nextProtocolId - 1; // This includes mutation protocols too
    }

    /**
     * @dev Proposes a new Mutation Protocol. Requires Protocol Manager role.
     * @param name Protocol name.
     * @param description Protocol description.
     * @param requiredFragmentIds List of fragment IDs required for mutation.
     * @param stateTransformationData Abstract data describing the state change logic.
     * @return The ID of the proposed protocol.
     */
    function proposeMutationProtocol(
        string memory name,
        string memory description,
        uint256[] memory requiredFragmentIds,
        bytes memory stateTransformationData
    ) public onlyProtocolManager returns (uint256) {
        uint256 protocolId = _nextProtocolId++;
        _mutationProtocolsById[protocolId] = MutationProtocol({
            id: protocolId,
            name: name,
            description: description,
            requiredFragmentIds: requiredFragmentIds,
            stateTransformationData: stateTransformationData,
            proposer: msg.sender,
            status: ProtocolStatus.Proposed
        });
        emit ProtocolProposed(protocolId, false, msg.sender);
        return protocolId;
    }

    /**
     * @dev Approves a proposed Mutation Protocol, making it available for use. Requires Protocol Manager role.
     * @param protocolId The ID of the protocol to approve.
     */
    function approveMutationProtocol(uint256 protocolId) public onlyProtocolManager {
        MutationProtocol storage protocol = _mutationProtocolsById[protocolId];
        if (protocol.proposer == address(0) || protocol.status != ProtocolStatus.Proposed) revert ProtocolNotFound(); // Protocol doesn't exist or not in proposed state

        protocol.status = ProtocolStatus.Approved;
        emit ProtocolStatusUpdated(protocolId, ProtocolStatus.Approved);
    }

     /**
     * @dev Retrieves details of a Mutation Protocol.
     * @param protocolId The ID of the protocol.
     * @return The MutationProtocol struct.
     */
    function getMutationProtocol(uint256 protocolId) public view returns (MutationProtocol memory) {
        MutationProtocol memory protocol = _mutationProtocolsById[protocolId];
         if (protocol.proposer == address(0)) revert ProtocolNotFound();
         return protocol;
    }

    /**
     * @dev Gets the total count of proposed protocols (both types).
     */
    function getTotalMutationProtocols() public view returns (uint256) {
        // Same note as getTotalSynthesisProtocols - proxy count.
        return _nextProtocolId - 1;
    }

    // --- Quantum Synthesis ---

    /**
     * @dev Synthesizes a new Quantum using an approved Synthesis Protocol and required fragments.
     * Caller must have usage rights for all required fragments.
     * @param protocolId The ID of the Synthesis Protocol to use.
     * @param fragmentIds The specific fragment IDs to use (must match protocol requirements).
     * @return The ID of the newly synthesized Quantum.
     */
    function synthesizeQuantum(uint256 protocolId, uint256[] memory fragmentIds) public returns (uint256) {
        SynthesisProtocol storage protocol = _synthesisProtocolsById[protocolId];
        if (protocol.proposer == address(0)) revert ProtocolNotFound();
        if (protocol.status != ProtocolStatus.Approved) revert ProtocolNotApproved(protocolId);

        // Basic protocol requirement check: check if the provided fragmentIds match the requiredFragmentIds exactly
        // In a real system, this logic would be more flexible (e.g., minimum count, specific types, attributes)
        if (protocol.requiredFragmentIds.length != fragmentIds.length) revert InvalidProtocolRequirements();
        // Check if provided fragmentIds are the ones required by the protocol and if user can use them
        for (uint i = 0; i < fragmentIds.length; i++) {
             bool foundRequired = false;
             for(uint j = 0; j < protocol.requiredFragmentIds.length; j++) {
                 if (fragmentIds[i] == protocol.requiredFragmentIds[j]) {
                     foundRequired = true;
                     break;
                 }
             }
             if (!foundRequired) revert InvalidProtocolRequirements(); // Provided fragment not required by protocol
             if (!isFragmentUsable(fragmentIds[i], msg.sender)) revert FragmentNotUsable(msg.sender, fragmentIds[i]);
        }
        // Note: This simple implementation requires the *exact* set of fragment IDs listed in the protocol.
        // A more complex one would check categories, types, or attributes.

        uint256 quantumId = _nextQuantumId++;
        _quantumsById[quantumId] = Quantum({
            id: quantumId,
            synthesisProtocolId: protocolId,
            state: protocol.initialQuantumState, // Set initial state from protocol
            creationTimestamp: uint40(block.timestamp)
        });

        _quantumOwner[quantumId] = msg.sender;
        _quantumsByOwner[msg.sender].push(quantumId);
        _quantumSourceFragments[quantumId] = fragmentIds; // Store source fragments

        // In a real system, you might "consume" fragments here (e.g., mark as used for synthesis, or remove usage rights for this purpose)

        emit QuantumSynthesized(quantumId, protocolId, msg.sender);
        return quantumId;
    }

    // --- Quantum Mutation ---

    /**
     * @dev Mutates an existing Quantum using an approved Mutation Protocol and additional fragments.
     * Caller must own the Quantum and have usage rights for additional fragments.
     * The Quantum's state is updated based on the protocol's logic and fragment data.
     * @param quantumId The ID of the Quantum to mutate.
     * @param protocolId The ID of the Mutation Protocol to use.
     * @param additionalFragmentIds Additional fragment IDs used for mutation.
     */
    function mutateQuantum(uint256 quantumId, uint256 protocolId, uint256[] memory additionalFragmentIds) public {
        Quantum storage quantum = _quantumsById[quantumId];
        if (quantum.synthesisProtocolId == 0) revert QuantumNotFound(); // Check if quantum exists
        if (_quantumOwner[quantumId] != msg.sender) revert NotQuantumOwner();

        MutationProtocol storage protocol = _mutationProtocolsById[protocolId];
        if (protocol.proposer == address(0)) revert ProtocolNotFound();
        if (protocol.status != ProtocolStatus.Approved) revert ProtocolNotApproved(protocolId);

         // Basic protocol requirement check for additional fragments
        if (protocol.requiredFragmentIds.length != additionalFragmentIds.length) revert InvalidProtocolRequirements();
         for (uint i = 0; i < additionalFragmentIds.length; i++) {
             bool foundRequired = false;
             for(uint j = 0; j < protocol.requiredFragmentIds.length; j++) {
                 if (additionalFragmentIds[i] == protocol.requiredFragmentIds[j]) {
                     foundRequired = true;
                     break;
                 }
             }
             if (!foundRequired) revert InvalidProtocolRequirements();
             if (!isFragmentUsable(additionalFragmentIds[i], msg.sender)) revert FragmentNotUsable(msg.sender, additionalFragmentIds[i]);
        }

        // --- Advanced State Transformation Logic (Conceptual) ---
        // This is where the core dynamic state logic resides.
        // The `protocol.stateTransformationData` and the `additionalFragmentIds`
        // would be used to calculate the new `quantum.state`.
        // This is highly complex and application-specific. Examples:
        // - Simple: Append fragment content hashes to state
        // - Complex: Interpret `stateTransformationData` as instructions to
        //            modify parts of the state `bytes` based on fragment attributes.
        // For this example, we'll do a simplified "append fragment hash" mutation.

        bytes memory currentState = quantum.state;
        bytes memory transformationInput;

        // Concatenate fragment hashes or other data from additional fragments
        for (uint i = 0; i < additionalFragmentIds.length; i++) {
            Fragment memory frag = _fragmentsById[additionalFragmentIds[i]];
             if (frag.discoverer == address(0)) revert FragmentRequiredForProtocolNotFound(additionalFragmentIds[i]); // Should not happen if isFragmentUsable passes, but safety check
            // Append fragment content hash
            transformationInput = abi.encodePacked(transformationInput, frag.contentHash);
            // Append protocol transformation data (illustrative)
             transformationInput = abi.encodePacked(transformationInput, protocol.stateTransformationData);
        }

        // Apply transformation (simplified: append transformationInput to current state)
        // In a real system, this logic would be far more complex, interpreting
        // protocol.stateTransformationData and fragment data meaningfully.
        bytes memory newState = abi.encodePacked(currentState, transformationInput);

        // Limit state growth to prevent excessive gas costs
        uint256 maxStateSize = 2048; // Example limit (2KB)
        if (newState.length > maxStateSize) {
            // Truncate or handle error. Truncating for example:
             bytes memory truncatedState = new bytes(maxStateSize);
             for(uint i = 0; i < maxStateSize; i++) {
                 truncatedState[i] = newState[i];
             }
             quantum.state = truncatedState;
        } else {
            quantum.state = newState;
        }

        // In a real system, you might "consume" additional fragments here

        _quantumMutationHistory[quantumId].push(protocolId); // Track mutation history

        emit QuantumMutated(quantumId, protocolId, quantum.state);
    }

    // --- Quantum Querying ---

    /**
     * @dev Retrieves basic details of a Quantum.
     * @param quantumId The ID of the quantum.
     * @return The Quantum struct (without state).
     */
    function getQuantum(uint256 quantumId) public view returns (uint256 id, uint256 synthesisProtocolId, uint40 creationTimestamp) {
         Quantum memory quantum = _quantumsById[quantumId];
        if (quantum.synthesisProtocolId == 0) revert QuantumNotFound();
        return (quantum.id, quantum.synthesisProtocolId, quantum.creationTimestamp);
    }

    /**
     * @dev Retrieves the current owner of a Quantum.
     * @param quantumId The ID of the quantum.
     * @return The owner's address.
     */
    function getQuantumOwner(uint256 quantumId) public view returns (address) {
        if (_quantumsById[quantumId].synthesisProtocolId == 0) revert QuantumNotFound();
        return _quantumOwner[quantumId];
    }

    /**
     * @dev Retrieves the current dynamic state data of a Quantum.
     * @param quantumId The ID of the quantum.
     * @return The state data as bytes.
     */
    function getQuantumCurrentState(uint256 quantumId) public view returns (bytes memory) {
        Quantum memory quantum = _quantumsById[quantumId];
        if (quantum.synthesisProtocolId == 0) revert QuantumNotFound();
        return quantum.state;
    }

     /**
     * @dev Retrieves the list of Fragment IDs used to synthesize a Quantum.
     * @param quantumId The ID of the quantum.
     * @return An array of Fragment IDs.
     */
    function getQuantumSourceFragments(uint256 quantumId) public view returns (uint256[] memory) {
         if (_quantumsById[quantumId].synthesisProtocolId == 0) revert QuantumNotFound();
        return _quantumSourceFragments[quantumId];
    }

    /**
     * @dev Retrieves the list of Mutation Protocol IDs applied to a Quantum.
     * @param quantumId The ID of the quantum.
     * @return An array of Mutation Protocol IDs.
     */
    function getQuantumMutationHistory(uint256 quantumId) public view returns (uint256[] memory) {
        if (_quantumsById[quantumId].synthesisProtocolId == 0) revert QuantumNotFound();
        return _quantumMutationHistory[quantumId];
    }

    /**
     * @dev Retrieves a list of Quantum IDs owned by an address.
     * @param owner The address to query.
     * @return An array of Quantum IDs.
     */
    function getQuantumsByOwner(address owner) public view returns (uint256[] memory) {
        return _quantumsByOwner[owner];
    }

    /**
     * @dev Gets the total count of created Quantums.
     */
    function getTotalQuantums() public view returns (uint256) {
        return _nextQuantumId - 1;
    }

    /**
     * @dev Constructs and returns a URI for off-chain metadata of a Quantum.
     * This URI typically points to a service that interprets the Quantum's state.
     * @param quantumId The ID of the quantum.
     * @return The metadata URI.
     */
    function getQuantumMetadataUri(uint256 quantumId) public view returns (string memory) {
        // This is a conceptual URI construction. The actual implementation depends
        // on the off-chain renderer service. Example:
        // renderer_base_uri + /quantum/ + quantumId + /state/ + hex_encoded_state
        if (_metadataRenderer == address(0)) return ""; // No renderer set

        // We return the renderer address and rely on off-chain logic
        // to construct the full URI using quantumId and getQuantumCurrentState().
        // Returning a string here is complex due to dynamic state bytes.
        // Let's return a structured representation or just the renderer address
        // and leave URI building entirely off-chain.
        // For a string return, we'd need to encode quantumId and state.

        // Example: Return a placeholder string indicating the renderer and ID
        // return string(abi.encodePacked("ipfs://", uint2str(quantumId), ".json")); // Simple placeholder

        // A more realistic approach for stateful NFTs is often to have the off-chain
        // renderer service query the contract state (getQuantumCurrentState) directly
        // using the quantumId obtained from a base URI (like the renderer address).
        // We'll return a simple base that the renderer service will use.
         return string(abi.encodePacked("quill://render/", uint2str(quantumId))); // Example custom scheme URI

         // Helper uint to string (minimal implementation)
         function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
             if (_i == 0) {
                 return "0";
             }
             uint256 j = _i;
             uint length = 0;
             while (j != 0) {
                 length++;
                 j /= 10;
             }
             bytes memory bstr = new bytes(length);
             uint k = length;
             while (_i != 0) {
                 k = k-1;
                 uint8 temp = (48 + uint8(_i % 10));
                 bstr[k] = temp;
                 _i /= 10;
             }
             return string(bstr);
         }
    }

    // --- Quantum Transfer ---

    /**
     * @dev Transfers ownership of a Quantum to a new address. Caller must be the current owner.
     * @param to The recipient address.
     * @param quantumId The ID of the quantum to transfer.
     */
    function transferQuantum(address to, uint256 quantumId) public {
        if (to == address(0)) revert NotQuantumOwner(); // Cannot transfer to zero address
        address owner = _quantumOwner[quantumId];
        if (owner == address(0)) revert QuantumNotFound(); // Check if quantum exists
        if (owner != msg.sender) revert NotQuantumOwner();

        // Remove from sender's list
        uint256[] storage ownerQuantums = _quantumsByOwner[owner];
        for (uint i = 0; i < ownerQuantums.length; i++) {
            if (ownerQuantums[i] == quantumId) {
                ownerQuantums[i] = ownerQuantums[ownerQuantums.length - 1];
                ownerQuantums.pop();
                break;
            }
        }

        // Add to recipient's list and update owner mapping
        _quantumOwner[quantumId] = to;
        _quantumsByOwner[to].push(quantumId);

        emit QuantumTransferred(owner, to, quantumId);
    }

    // --- Standard Utility ---

    /**
     * @dev See {IERC165-supportsInterface}.
     * This contract doesn't strictly follow a standard token interface but
     * includes this function as a best practice. It would return true for
     * interfaces it implements (e.g., a hypothetical IDynamicStateNFT).
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // Example: Replace with relevant interface IDs if implementing specific standards
        // bytes4 type(IERC721).interfaceId ^ type(IERC721Enumerable).interfaceId ^ type(IERC721Metadata).interfaceId;
        bytes4 baseInterfaceId = 0x01ffc9a7; // ERC165
        // Add any custom interface IDs this contract explicitly supports
        // bytes4 myCustomInterface = 0x12345678; // Example
        return interfaceId == baseInterfaceId; // || interfaceId == myCustomInterface;
    }

    // --- Internal Helpers ---
     // uint to string helper for getQuantumMetadataUri
     function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
         if (_i == 0) {
             return "0";
         }
         uint256 j = _i;
         uint length = 0;
         while (j != 0) {
             length++;
             j /= 10;
         }
         bytes memory bstr = new bytes(length);
         uint k = length;
         while (_i != 0) {
             k = k-1;
             uint8 temp = (48 + uint8(_i % 10));
             bstr[k] = temp;
             _i /= 10;
         }
         return string(bstr);
     }
}
```