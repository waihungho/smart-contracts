The AlchemiForge Protocol is a decentralized ecosystem for the creation, evolution, and management of dynamic on-chain digital assets called "Artifacts." Unlike static NFTs, Artifacts in AlchemiForge can change their attributes, evolve through stages, and gain unique properties influenced by an AI oracle. Users initiate "forging" or "evolution" processes by combining existing Artifacts, consuming "Catalyst" tokens, and optionally providing off-chain prompts. An external AI oracle then processes these requests, returning outcomes that determine the new Artifact's attributes or an existing Artifact's evolution path, thereby integrating sophisticated off-chain intelligence into on-chain assets. The protocol also features a reputation system that rewards successful contributions and participation.

---

## AlchemiForge Protocol: Outline & Function Summary

**Contract Name:** AlchemiForgeProtocol

**Core Idea:** A decentralized protocol for dynamic, AI-assisted creation and evolution of on-chain digital "Artifacts." Users combine existing Artifacts and 'Catalyst' tokens, optionally submitting off-chain prompts, to generate new or evolve existing Artifacts. An external AI oracle influences the forging outcomes, attributes, and potential evolution paths based on various parameters. The protocol also incorporates a reputation system for contributors and a treasury for development.

---

### **I. Administration & Configuration (5 Functions)**

1.  **`constructor(address initialAdmin, address catalystTokenAddr, address aiOracleAddr)`**:
    *   Initializes the contract, setting the deployer as the initial admin.
    *   Sets the initial address for the Catalyst ERC-20 token and the AI Oracle contract.
    *   Initializes forging costs.
2.  **`updateAdmin(address newAdmin)`**:
    *   Allows the current admin to transfer administrative privileges to a new address.
    *   *Access Control:* `onlyAdmin`.
3.  **`pauseProtocol()`**:
    *   Allows the admin to temporarily pause core user-facing operations (forging, evolving).
    *   *Access Control:* `onlyAdmin`.
4.  **`unpauseProtocol()`**:
    *   Allows the admin to resume core user-facing operations after a pause.
    *   *Access Control:* `onlyAdmin`.
5.  **`setBaseURI(string memory newBaseURI)`**:
    *   Sets the base URI for the NFT metadata, used by `tokenURI` to resolve full metadata links.
    *   *Access Control:* `onlyAdmin`.

### **II. Core Artifact Management (ERC-721-like) (6 Functions)**

1.  **`balanceOf(address owner)`**:
    *   Returns the number of Artifacts owned by a specific address.
    *   *Query:* Read-only.
2.  **`ownerOf(uint256 artifactId)`**:
    *   Returns the address of the owner of a specific Artifact.
    *   *Query:* Read-only.
3.  **`approve(address to, uint256 artifactId)`**:
    *   Grants approval for a specific address to operate a single Artifact.
    *   *Access Control:* `isApprovedOrOwner`.
4.  **`setApprovalForAll(address operator, bool approved)`**:
    *   Grants or revokes approval for an operator to manage all Artifacts owned by the caller.
    *   *Access Control:* `msg.sender`.
5.  **`transferFrom(address from, address to, uint256 artifactId)`**:
    *   Transfers ownership of an Artifact from one address to another.
    *   *Access Control:* `isApprovedOrOwner`.
6.  **`getArtifactDetails(uint256 artifactId)`**:
    *   Retrieves all on-chain details (owner, creation time, stage, affinity, all attributes) of a specific Artifact.
    *   *Query:* Read-only, returns a comprehensive tuple of data.

### **III. Oracle & AI Integration (5 Functions)**

1.  **`setAIOracleAddress(address newOracle)`**:
    *   Sets the trusted address of the external AI oracle contract.
    *   *Access Control:* `onlyAdmin`.
2.  **`setOracleCallbackGasLimit(uint32 newLimit)`**:
    *   Sets the maximum gas limit for the AI oracle's callback functions (`fulfillForgeRequest`, `fulfillEvolveRequest`).
    *   *Access Control:* `onlyAdmin`.
3.  **`setCatalystTokenAddress(address newCatalystToken)`**:
    *   Sets the address of the ERC-20 token designated as the "Catalyst" for protocol operations.
    *   *Access Control:* `onlyAdmin`.
4.  **`updateForgingCosts(uint256 newForgeCost, uint256 newEvolutionCost)`**:
    *   Adjusts the required Catalyst token amounts for initiating forging and evolution processes.
    *   *Access Control:* `onlyAdmin`.
5.  **`fulfillForgeRequest(bytes32 requestId, uint256[] memory newAttributeValues, uint256 newEvolutionStage, uint256 newAffinityScore, bool success)`**:
    *   *Callback function:* Called by the trusted AI oracle to complete a previously requested forging process.
    *   Mints a new Artifact with the AI-determined attributes, awards reputation, and finalizes the request.
    *   *Access Control:* `onlyAIOracle`.

### **IV. User Interaction & Core Logic (6 Functions)**

1.  **`requestForgeArtifact(uint256[] memory parentArtifactIds, string memory aiPromptHash)`**:
    *   Initiates a request to forge a new Artifact. Users must provide parent Artifacts (if any) and an optional hash of an off-chain AI prompt.
    *   Requires approval and transfer of `forgeCost` Catalyst tokens.
    *   Emits an event for the AI oracle to pick up and process.
    *   *Access Control:* `whenNotPaused`, user must own parents, parents must exist.
2.  **`requestEvolveArtifact(uint256 artifactId, string memory aiPromptHash)`**:
    *   Initiates a request to evolve an existing Artifact. Users must own the Artifact and provide an optional hash of an off-chain AI prompt.
    *   Requires approval and transfer of `evolutionCost` Catalyst tokens.
    *   Emits an event for the AI oracle to pick up and process.
    *   *Access Control:* `whenNotPaused`, user must own artifact, artifact must exist.
3.  **`depositToTreasury(uint256 amount)`**:
    *   Allows any user to voluntarily deposit ETH into the protocol's treasury.
    *   *Access Control:* Public.
4.  **`getReputationScore(address user)`**:
    *   Retrieves the current reputation score of a specific user.
    *   *Query:* Read-only.
5.  **`getArtifactAttribute(uint256 artifactId, string memory attributeKey)`**:
    *   Retrieves the value of a specific attribute for a given Artifact.
    *   *Query:* Read-only.
6.  **`tokenURI(uint256 artifactId)`**:
    *   Generates a URI pointing to the metadata for a specific Artifact, following ERC-721 metadata standards. This URI will reference an off-chain JSON file which can dynamically pull on-chain attribute data.
    *   *Query:* Read-only.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- AlchemiForge Protocol: Outline & Function Summary ---
//
// Contract Name: AlchemiForgeProtocol
//
// Core Idea: A decentralized protocol for dynamic, AI-assisted creation and evolution of
// on-chain digital "Artifacts." Users combine existing Artifacts and 'Catalyst' tokens,
// optionally submitting off-chain prompts, to generate new or evolve existing Artifacts.
// An external AI oracle influences the forging outcomes, attributes, and potential
// evolution paths based on various parameters. The protocol also incorporates a reputation
// system for contributors and a treasury for development.
//
// I. Administration & Configuration (5 Functions)
//    1. constructor(address initialAdmin, address catalystTokenAddr, address aiOracleAddr)
//    2. updateAdmin(address newAdmin)
//    3. pauseProtocol()
//    4. unpauseProtocol()
//    5. setBaseURI(string memory newBaseURI)
//
// II. Core Artifact Management (ERC-721-like) (6 Functions)
//    1. balanceOf(address owner)
//    2. ownerOf(uint256 artifactId)
//    3. approve(address to, uint256 artifactId)
//    4. setApprovalForAll(address operator, bool approved)
//    5. transferFrom(address from, address to, uint256 artifactId)
//    6. getArtifactDetails(uint256 artifactId)
//
// III. Oracle & AI Integration (5 Functions)
//    1. setAIOracleAddress(address newOracle)
//    2. setOracleCallbackGasLimit(uint32 newLimit)
//    3. setCatalystTokenAddress(address newCatalystToken)
//    4. updateForgingCosts(uint256 newForgeCost, uint256 newEvolutionCost)
//    5. fulfillForgeRequest(bytes32 requestId, uint256[] memory newAttributeValues, uint256 newEvolutionStage, uint256 newAffinityScore, bool success)
//
// IV. User Interaction & Core Logic (6 Functions)
//    1. requestForgeArtifact(uint256[] memory parentArtifactIds, string memory aiPromptHash)
//    2. requestEvolveArtifact(uint256 artifactId, string memory aiPromptHash)
//    3. depositToTreasury(uint256 amount)
//    4. getReputationScore(address user)
//    5. getArtifactAttribute(uint256 artifactId, string memory attributeKey)
//    6. tokenURI(uint256 artifactId)
//
// Total Functions: 22

// --- Interfaces ---

// Simplified AI Oracle Interface for demonstration
interface IAIOracle {
    function requestForge(
        bytes32 requestId,
        address callbackContract,
        uint256 callbackGasLimit,
        uint256[] calldata parentArtifactIds,
        string calldata aiPromptHash,
        address requestingUser
    ) external;

    function requestEvolution(
        bytes32 requestId,
        address callbackContract,
        uint256 callbackGasLimit,
        uint256 artifactId,
        string calldata aiPromptHash,
        address requestingUser
    ) external;
}

// --- Contract Implementation ---

contract AlchemiForgeProtocol {
    // --- State Variables ---

    address public admin;
    bool public paused;

    // ERC-721 Standard Variables
    string public name = "AlchemiForge Artifact";
    string public symbol = "AFA";
    uint256 private _nextTokenId;
    string private _baseURI;

    // Artifact Data Structure
    struct Artifact {
        address owner;
        uint256 creationTime;
        uint256 lastEvolutionTime;
        uint256 evolutionStage; // e.g., 0, 1, 2...
        uint256 affinityScore;  // Influences future forging outcomes
        string[] attributeKeys; // Keys for dynamic attributes
    }
    mapping(uint256 => Artifact) private _artifacts;
    mapping(uint256 => address) private _artifactApprovals; // ERC-721 approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC-721 operator approvals
    mapping(address => uint256) private _balances; // ERC-721 balances

    // Dynamic Attributes for Artifacts: artifactId -> attributeKey -> value
    mapping(uint256 => mapping(string => uint256)) public artifactAttributes;

    // AI Oracle Integration
    address public aiOracleAddress;
    uint32 public oracleCallbackGasLimit = 300_000; // Default gas limit for oracle callbacks

    // Catalyst Token & Costs
    IERC20 public catalystToken;
    uint256 public forgeCost = 100 * 10 ** 18; // Default cost in Catalyst tokens
    uint256 public evolutionCost = 50 * 10 ** 18; // Default cost in Catalyst tokens

    // Request Management (for oracle callbacks)
    struct ForgeRequest {
        address user;
        uint256[] parentArtifacts;
        string aiPromptHash; // Hash of the off-chain prompt
        uint256 requestTime;
        uint256 catalystAmount;
    }
    mapping(bytes32 => ForgeRequest) public forgeRequests; // requestId -> ForgeRequest

    struct EvolutionRequest {
        address user;
        uint256 artifactId;
        string aiPromptHash;
        uint256 requestTime;
        uint256 catalystAmount;
    }
    mapping(bytes32 => EvolutionRequest) public evolutionRequests; // requestId -> EvolutionRequest

    // Reputation System
    mapping(address => uint256) public userReputation; // user -> reputation score

    // --- Events ---

    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event Paused(address account);
    event Unpaused(address account);
    event BaseURIUpdated(string newBaseURI);

    // ERC-721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event AIOracleAddressUpdated(address indexed newOracle);
    event OracleCallbackGasLimitUpdated(uint32 newLimit);
    event CatalystTokenAddressUpdated(address indexed newCatalystToken);
    event ForgingCostsUpdated(uint256 newForgeCost, uint256 newEvolutionCost);

    event ForgeRequested(
        bytes32 indexed requestId,
        address indexed user,
        uint256[] parentArtifacts,
        string aiPromptHash,
        uint256 catalystAmount
    );
    event ArtifactForged(
        bytes32 indexed requestId,
        address indexed owner,
        uint256 indexed artifactId,
        uint256 newEvolutionStage,
        uint256 newAffinityScore,
        string[] attributeKeys,
        uint256[] attributeValues
    );
    event EvolutionRequested(
        bytes32 indexed requestId,
        address indexed user,
        uint256 indexed artifactId,
        string aiPromptHash,
        uint256 catalystAmount
    );
    event ArtifactEvolved(
        bytes32 indexed requestId,
        address indexed owner,
        uint256 indexed artifactId,
        uint256 newEvolutionStage,
        uint256 newAffinityScore,
        string[] attributeKeys,
        uint256[] attributeValues
    );

    event ReputationAwarded(address indexed user, uint256 amount);
    event TreasuryDeposit(address indexed depositor, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "AlchemiForge: Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AlchemiForge: Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AlchemiForge: Protocol is not paused");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AlchemiForge: Only AI oracle can call this function");
        _;
    }

    // --- Constructor ---

    /// @dev Initializes the contract, setting the admin, catalyst token, and AI oracle addresses.
    constructor(address initialAdmin, address catalystTokenAddr, address aiOracleAddr) {
        require(initialAdmin != address(0), "AlchemiForge: Invalid initial admin address");
        require(catalystTokenAddr != address(0), "AlchemiForge: Invalid catalyst token address");
        require(aiOracleAddr != address(0), "AlchemiForge: Invalid AI oracle address");

        admin = initialAdmin;
        catalystToken = IERC20(catalystTokenAddr);
        aiOracleAddress = aiOracleAddr;
        _nextTokenId = 1; // Artifact IDs start from 1

        emit AdminUpdated(address(0), initialAdmin);
        emit CatalystTokenAddressUpdated(catalystTokenAddr);
        emit AIOracleAddressUpdated(aiOracleAddr);
    }

    // --- I. Administration & Configuration ---

    /// @dev Allows the current admin to transfer administrative privileges to a new address.
    /// @param newAdmin The address of the new admin.
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "AlchemiForge: New admin cannot be the zero address");
        emit AdminUpdated(admin, newAdmin);
        admin = newAdmin;
    }

    /// @dev Allows the admin to temporarily pause core user-facing operations.
    function pauseProtocol() external onlyAdmin whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Allows the admin to resume core user-facing operations.
    function unpauseProtocol() external onlyAdmin whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev Sets the base URI for the NFT metadata, used by tokenURI.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) external onlyAdmin {
        _baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // --- II. Core Artifact Management (ERC-721-like) ---

    /// @dev Returns the number of Artifacts owned by a specific address.
    /// @param owner The address to query the balance of.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @dev Returns the address of the owner of a specific Artifact.
    /// @param artifactId The ID of the Artifact.
    function ownerOf(uint256 artifactId) public view returns (address) {
        address owner = _artifacts[artifactId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @dev Allows `to` to manage `artifactId`.
    /// @param to The address to grant approval to.
    /// @param artifactId The ID of the Artifact.
    function approve(address to, uint256 artifactId) public {
        address owner = ownerOf(artifactId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");

        _artifactApprovals[artifactId] = to;
        emit Approval(owner, to, artifactId);
    }

    /// @dev Sets `operator` as an operator for `msg.sender`.
    /// @param operator The address to set as an operator.
    /// @param approved True if the operator is approved, false otherwise.
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Transfers ownership of an Artifact from `from` to `to`.
    /// @param from The current owner of the Artifact.
    /// @param to The new owner of the Artifact.
    /// @param artifactId The ID of the Artifact.
    function transferFrom(address from, address to, uint256 artifactId) public {
        require(_isApprovedOrOwner(msg.sender, artifactId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(artifactId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(artifactId);
        _balances[from]--;
        _balances[to]++;
        _artifacts[artifactId].owner = to;

        emit Transfer(from, to, artifactId);
    }

    /// @dev Retrieves all on-chain details of a specific Artifact.
    /// @param artifactId The ID of the Artifact.
    /// @return A tuple containing the owner, creation time, last evolution time, evolution stage, affinity score,
    ///         attribute keys, and their corresponding values.
    function getArtifactDetails(
        uint256 artifactId
    )
        public
        view
        returns (
            address owner,
            uint256 creationTime,
            uint256 lastEvolutionTime,
            uint256 evolutionStage,
            uint256 affinityScore,
            string[] memory attributeKeys,
            uint256[] memory attributeValues
        )
    {
        Artifact storage artifact = _artifacts[artifactId];
        require(artifact.owner != address(0), "AlchemiForge: Artifact does not exist");

        owner = artifact.owner;
        creationTime = artifact.creationTime;
        lastEvolutionTime = artifact.lastEvolutionTime;
        evolutionStage = artifact.evolutionStage;
        affinityScore = artifact.affinityScore;
        attributeKeys = artifact.attributeKeys;

        attributeValues = new uint256[](attributeKeys.length);
        for (uint256 i = 0; i < attributeKeys.length; i++) {
            attributeValues[i] = artifactAttributes[artifactId][attributeKeys[i]];
        }
    }

    // Internal ERC-721 Helpers
    function _isApprovedOrOwner(address spender, uint256 artifactId) internal view returns (bool) {
        address owner = ownerOf(artifactId);
        return (spender == owner || getApproved(artifactId) == spender || _operatorApprovals[owner][spender]);
    }

    function getApproved(uint256 artifactId) public view returns (address) {
        require(_artifacts[artifactId].owner != address(0), "ERC721: approved query for nonexistent token");
        return _artifactApprovals[artifactId];
    }

    function _clearApproval(uint256 artifactId) internal {
        delete _artifactApprovals[artifactId];
    }

    function _exists(uint256 artifactId) internal view returns (bool) {
        return _artifacts[artifactId].owner != address(0);
    }

    // --- III. Oracle & AI Integration ---

    /// @dev Sets the trusted address of the external AI oracle contract.
    /// @param newOracle The address of the new AI oracle.
    function setAIOracleAddress(address newOracle) external onlyAdmin {
        require(newOracle != address(0), "AlchemiForge: AI oracle cannot be the zero address");
        aiOracleAddress = newOracle;
        emit AIOracleAddressUpdated(newOracle);
    }

    /// @dev Sets the maximum gas limit for the AI oracle's callback functions.
    /// @param newLimit The new gas limit.
    function setOracleCallbackGasLimit(uint32 newLimit) external onlyAdmin {
        require(newLimit > 0, "AlchemiForge: Gas limit must be greater than 0");
        oracleCallbackGasLimit = newLimit;
        emit OracleCallbackGasLimitUpdated(newLimit);
    }

    /// @dev Sets the address of the ERC-20 token designated as the "Catalyst".
    /// @param newCatalystToken The address of the new Catalyst token.
    function setCatalystTokenAddress(address newCatalystToken) external onlyAdmin {
        require(newCatalystToken != address(0), "AlchemiForge: Catalyst token cannot be zero address");
        catalystToken = IERC20(newCatalystToken);
        emit CatalystTokenAddressUpdated(newCatalystToken);
    }

    /// @dev Adjusts the required Catalyst token amounts for forging and evolution.
    /// @param newForgeCost The new cost for forging.
    /// @param newEvolutionCost The new cost for evolution.
    function updateForgingCosts(uint256 newForgeCost, uint256 newEvolutionCost) external onlyAdmin {
        require(newForgeCost > 0, "AlchemiForge: Forge cost must be greater than 0");
        require(newEvolutionCost > 0, "AlchemiForge: Evolution cost must be greater than 0");
        forgeCost = newForgeCost;
        evolutionCost = newEvolutionCost;
        emit ForgingCostsUpdated(newForgeCost, newEvolutionCost);
    }

    /// @dev Callback function from the trusted AI oracle to complete a forging process.
    /// @param requestId The unique ID of the original forge request.
    /// @param newAttributeValues An array of values for the new Artifact's attributes.
    /// @param newEvolutionStage The initial evolution stage for the new Artifact.
    /// @param newAffinityScore The initial affinity score for the new Artifact.
    /// @param success True if the forging was successful, false otherwise.
    function fulfillForgeRequest(
        bytes32 requestId,
        string[] memory newAttributeKeys,
        uint256[] memory newAttributeValues,
        uint256 newEvolutionStage,
        uint256 newAffinityScore,
        bool success
    ) external onlyAIOracle {
        ForgeRequest storage req = forgeRequests[requestId];
        require(req.user != address(0), "AlchemiForge: Unknown forge request ID");

        address requester = req.user;
        delete forgeRequests[requestId]; // Clean up request

        if (success) {
            uint256 newArtifactId = _mintArtifact(requester, newEvolutionStage, newAffinityScore, newAttributeKeys, newAttributeValues);
            _awardReputation(requester, 10); // Award reputation for successful forge

            emit ArtifactForged(
                requestId,
                requester,
                newArtifactId,
                newEvolutionStage,
                newAffinityScore,
                newAttributeKeys,
                newAttributeValues
            );
        } else {
            // Refund Catalyst if forge failed (or handle differently, e.g., burn for 'failed' result)
            require(catalystToken.transfer(requester, req.catalystAmount), "AlchemiForge: Failed to refund Catalyst");
            // Optionally penalize reputation for failure or just do nothing
        }
    }

    /// @dev Callback function from the trusted AI oracle to complete an evolution process.
    /// @param requestId The unique ID of the original evolution request.
    /// @param artifactId The ID of the Artifact being evolved.
    /// @param updatedAttributeValues An array of updated values for the Artifact's attributes.
    /// @param newEvolutionStage The new evolution stage for the Artifact.
    /// @param newAffinityScore The new affinity score for the Artifact.
    /// @param success True if the evolution was successful, false otherwise.
    function fulfillEvolveRequest(
        bytes32 requestId,
        uint256 artifactId,
        string[] memory updatedAttributeKeys,
        uint256[] memory updatedAttributeValues,
        uint256 newEvolutionStage,
        uint256 newAffinityScore,
        bool success
    ) external onlyAIOracle {
        EvolutionRequest storage req = evolutionRequests[requestId];
        require(req.user != address(0), "AlchemiForge: Unknown evolution request ID");
        require(req.artifactId == artifactId, "AlchemiForge: Mismatch artifact ID in evolution request");

        address requester = req.user;
        delete evolutionRequests[requestId]; // Clean up request

        if (success) {
            _updateArtifactAttributes(artifactId, newEvolutionStage, newAffinityScore, updatedAttributeKeys, updatedAttributeValues);
            _awardReputation(requester, 5); // Award reputation for successful evolution

            emit ArtifactEvolved(
                requestId,
                requester,
                artifactId,
                newEvolutionStage,
                newAffinityScore,
                updatedAttributeKeys,
                updatedAttributeValues
            );
        } else {
            // Refund Catalyst if evolution failed
            require(catalystToken.transfer(requester, req.catalystAmount), "AlchemiForge: Failed to refund Catalyst");
        }
    }


    // --- IV. User Interaction & Core Logic ---

    /// @dev Initiates a request to forge a new Artifact.
    /// @param parentArtifactIds An array of IDs of parent Artifacts to be used in forging.
    /// @param aiPromptHash A hash of an off-chain AI prompt relevant to the forging.
    function requestForgeArtifact(
        uint256[] memory parentArtifactIds,
        string memory aiPromptHash
    ) external whenNotPaused {
        require(aiOracleAddress != address(0), "AlchemiForge: AI Oracle not set");
        require(address(catalystToken) != address(0), "AlchemiForge: Catalyst token not set");
        require(catalystToken.transferFrom(msg.sender, address(this), forgeCost), "AlchemiForge: Catalyst transfer failed");

        // Validate parent artifacts ownership
        for (uint256 i = 0; i < parentArtifactIds.length; i++) {
            require(ownerOf(parentArtifactIds[i]) == msg.sender, "AlchemiForge: Caller does not own parent artifact");
        }

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, parentArtifactIds, aiPromptHash, _nextTokenId));

        forgeRequests[requestId] = ForgeRequest({
            user: msg.sender,
            parentArtifacts: parentArtifactIds,
            aiPromptHash: aiPromptHash,
            requestTime: block.timestamp,
            catalystAmount: forgeCost
        });

        IAIOracle(aiOracleAddress).requestForge{gas: oracleCallbackGasLimit}(
            requestId,
            address(this),
            oracleCallbackGasLimit,
            parentArtifactIds,
            aiPromptHash,
            msg.sender
        );

        emit ForgeRequested(requestId, msg.sender, parentArtifactIds, aiPromptHash, forgeCost);
    }

    /// @dev Initiates a request to evolve an existing Artifact.
    /// @param artifactId The ID of the Artifact to evolve.
    /// @param aiPromptHash A hash of an off-chain AI prompt relevant to the evolution.
    function requestEvolveArtifact(uint256 artifactId, string memory aiPromptHash) external whenNotPaused {
        require(_exists(artifactId), "AlchemiForge: Artifact does not exist");
        require(ownerOf(artifactId) == msg.sender, "AlchemiForge: Caller does not own this artifact");
        require(aiOracleAddress != address(0), "AlchemiForge: AI Oracle not set");
        require(address(catalystToken) != address(0), "AlchemiForge: Catalyst token not set");
        require(catalystToken.transferFrom(msg.sender, address(this), evolutionCost), "AlchemiForge: Catalyst transfer failed");

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, artifactId, aiPromptHash));

        evolutionRequests[requestId] = EvolutionRequest({
            user: msg.sender,
            artifactId: artifactId,
            aiPromptHash: aiPromptHash,
            requestTime: block.timestamp,
            catalystAmount: evolutionCost
        });

        IAIOracle(aiOracleAddress).requestEvolution{gas: oracleCallbackGasLimit}(
            requestId,
            address(this),
            oracleCallbackGasLimit,
            artifactId,
            aiPromptHash,
            msg.sender
        );

        emit EvolutionRequested(requestId, msg.sender, artifactId, aiPromptHash, evolutionCost);
    }

    /// @dev Allows any user to voluntarily deposit ETH into the protocol's treasury.
    function depositToTreasury(uint256 amount) public payable {
        require(msg.value == amount, "AlchemiForge: Sent ETH must match amount parameter");
        emit TreasuryDeposit(msg.sender, amount);
    }

    /// @dev Retrieves the current reputation score of a specific user.
    /// @param user The address of the user.
    function getReputationScore(address user) public view returns (uint256) {
        return userReputation[user];
    }

    /// @dev Retrieves the value of a specific attribute for a given Artifact.
    /// @param artifactId The ID of the Artifact.
    /// @param attributeKey The key of the attribute (e.g., "power", "rarity").
    function getArtifactAttribute(uint256 artifactId, string memory attributeKey) public view returns (uint256) {
        require(_exists(artifactId), "AlchemiForge: Artifact does not exist");
        return artifactAttributes[artifactId][attributeKey];
    }

    /// @dev Generates a URI pointing to the metadata for a specific Artifact.
    /// @param artifactId The ID of the Artifact.
    function tokenURI(uint256 artifactId) public view returns (string memory) {
        require(_exists(artifactId), "ERC721Metadata: URI query for nonexistent token");
        // This URI would typically point to a service that dynamically generates JSON
        // metadata including on-chain attributes based on artifactId.
        // For example: "https://api.alchemiforge.io/metadata/123"
        return string(abi.encodePacked(_baseURI, Strings.toString(artifactId)));
    }


    // --- Internal Functions ---

    /// @dev Mints a new Artifact with specified initial properties and attributes.
    /// @param to The recipient of the new Artifact.
    /// @param evolutionStage The initial evolution stage.
    /// @param affinityScore The initial affinity score.
    /// @param attributeKeys An array of attribute keys.
    /// @param attributeValues An array of attribute values (must match keys in length).
    /// @return The ID of the newly minted Artifact.
    function _mintArtifact(
        address to,
        uint256 evolutionStage,
        uint256 affinityScore,
        string[] memory attributeKeys,
        uint256[] memory attributeValues
    ) internal returns (uint256) {
        require(to != address(0), "AlchemiForge: Mint to the zero address");
        require(attributeKeys.length == attributeValues.length, "AlchemiForge: Attribute keys and values length mismatch");

        uint256 newArtifactId = _nextTokenId++;
        _artifacts[newArtifactId] = Artifact({
            owner: to,
            creationTime: block.timestamp,
            lastEvolutionTime: block.timestamp,
            evolutionStage: evolutionStage,
            affinityScore: affinityScore,
            attributeKeys: newAttributeKeys // Store keys for easy retrieval
        });

        for (uint256 i = 0; i < attributeKeys.length; i++) {
            artifactAttributes[newArtifactId][attributeKeys[i]] = attributeValues[i];
        }

        _balances[to]++;
        emit Transfer(address(0), to, newArtifactId);
        return newArtifactId;
    }

    /// @dev Updates the properties and attributes of an existing Artifact.
    /// @param artifactId The ID of the Artifact to update.
    /// @param newEvolutionStage The new evolution stage.
    /// @param newAffinityScore The new affinity score.
    /// @param updatedAttributeKeys An array of attribute keys to update.
    /// @param updatedAttributeValues An array of corresponding new values.
    function _updateArtifactAttributes(
        uint256 artifactId,
        uint256 newEvolutionStage,
        uint256 newAffinityScore,
        string[] memory updatedAttributeKeys,
        uint256[] memory updatedAttributeValues
    ) internal {
        require(_exists(artifactId), "AlchemiForge: Artifact does not exist");
        require(updatedAttributeKeys.length == updatedAttributeValues.length, "AlchemiForge: Attribute keys and values length mismatch");

        Artifact storage artifact = _artifacts[artifactId];
        artifact.lastEvolutionTime = block.timestamp;
        artifact.evolutionStage = newEvolutionStage;
        artifact.affinityScore = newAffinityScore;

        // Update or add attributes
        for (uint256 i = 0; i < updatedAttributeKeys.length; i++) {
            string memory key = updatedAttributeKeys[i];
            uint256 value = updatedAttributeValues[i];

            // If key is new, add it to the artifact's list of keys
            bool keyExists = false;
            for (uint256 j = 0; j < artifact.attributeKeys.length; j++) {
                if (keccak256(abi.encodePacked(artifact.attributeKeys[j])) == keccak256(abi.encodePacked(key))) {
                    keyExists = true;
                    break;
                }
            }
            if (!keyExists) {
                artifact.attributeKeys.push(key);
            }
            artifactAttributes[artifactId][key] = value;
        }
    }

    /// @dev Awards reputation to a user.
    /// @param user The address to award reputation to.
    /// @param amount The amount of reputation to award.
    function _awardReputation(address user, uint256 amount) internal {
        userReputation[user] += amount;
        emit ReputationAwarded(user, amount);
    }
}

// --- Library for string conversions (Simplified from OpenZeppelin for this example) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            digits--;
            buffer[digits] = bytes1(_HEX_SYMBOLS[value % 10]);
            value /= 10;
        }
        return string(buffer);
    }
}
```