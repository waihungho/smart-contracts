Okay, let's design a smart contract that goes beyond typical ERC-20, ERC-721, or simple DeFi mechanics. We'll create a system for "Mutable On-Chain Artifacts" (MOA) – unique digital assets (like NFTs) that possess dynamic properties and can evolve or decay based on interactions and time (simulated). It will incorporate concepts like internal resource management, state changes, parametric decay, and administrative controls for balancing.

This contract combines aspects of:
1.  **Dynamic NFTs:** Token metadata changes based on state.
2.  **Resource Management:** An internal "Essence" token is consumed by actions.
3.  **Parametric State Changes:** Properties like "Energy" and "Purity" change based on interactions and decay.
4.  **Evolution/Progression:** Artifacts can reach higher levels based on achieving certain property thresholds.
5.  **Simulated Time Influence:** A decay mechanic reduces properties over time (triggered by interaction or admin).
6.  **Administrative Balancing:** Key parameters can be adjusted by an authorized address.

It will implement essential ERC-721 functions but *not* inherit from standard libraries directly to meet the "don't duplicate open source" spirit, though the implementations will follow the standard interfaces and logic.

---

### Smart Contract Outline: `MutableArtifacts`

*   **Purpose:** Manages a collection of dynamic, evolving digital artifacts with state determined by user interactions and time.
*   **Core Assets:**
    *   Mutable Artifacts (ERC-721 inspired) - Unique tokens with state (`energy`, `purity`, `level`, `lastInteractionTime`).
    *   Aether Essence (Internal) - A resource consumed by certain artifact actions.
*   **Key Mechanics:**
    *   Minting new artifacts.
    *   Feeding artifacts (increases Energy, consumes Essence).
    *   Purifying artifacts (increases Purity, consumes Essence).
    *   Evolving artifacts (increases Level based on Energy/Purity thresholds).
    *   Bonding artifacts (interacts two artifacts, subtle state changes, consumes Essence).
    *   State Decay (Energy/Purity decrease over time if not maintained).
    *   Dynamic Metadata (TokenURI reflects current state).
    *   Parameter Configuration (Admin sets decay rates, costs, thresholds).
    *   Pause Functionality.
*   **Access Control:** Simple `onlyOwner` for administrative functions.

### Function Summary:

**ERC-721 Standard (Re-implemented logic):**

1.  `constructor(string memory name_, string memory symbol_, string memory baseURI_, uint256 initialDecayRate, uint256 initialInteractionCost, uint256[] memory initialEvolutionEnergyThresholds, uint256[] memory initialEvolutionPurityThresholds, uint256 initialMintPrice)`: Deploys the contract and sets initial parameters.
2.  `name()`: Returns the collection name.
3.  `symbol()`: Returns the collection symbol.
4.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token, dynamically reflecting its current state.
5.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
6.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers ownership.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers ownership with data.
10. `approve(address to, uint256 tokenId)`: Approves an address to spend a token.
11. `getApproved(uint256 tokenId)`: Returns the approved address for a token.
12. `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator for all tokens.
13. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
14. `supportsInterface(bytes4 interfaceId)`: ERC-165 standard interface support check.

**Artifact Lifecycle & Interaction:**

15. `mintArtifact()`: Mints a new artifact to the caller, requires ETH payment.
16. `getArtifactState(uint256 tokenId)`: Returns the current state (with decay applied) of an artifact.
17. `feedArtifact(uint256 tokenId, uint256 essenceAmount)`: Increases artifact energy, consumes owner's Essence.
18. `purifyArtifact(uint256 tokenId, uint256 essenceAmount)`: Increases artifact purity, consumes owner's Essence.
19. `evolveArtifact(uint256 tokenId)`: Attempts to evolve the artifact to the next level based on current state thresholds.
20. `bondArtifacts(uint256 tokenId1, uint256 tokenId2)`: Performs an interaction between two owned artifacts, consumes Essence, subtly changes states.
21. `adminTriggerDecay(uint256 tokenId)`: (Admin only) Applies decay to a single artifact's state based on elapsed time.

**Aether Essence Management:**

22. `getEssenceBalance(address account)`: Returns the Essence balance of an address.
23. `adminMintEssence(address account, uint256 amount)`: (Admin only) Mints Essence to a specific account.
24. `adminBurnEssence(address account, uint256 amount)`: (Admin only) Burns Essence from a specific account.

**Parameter & Control:**

25. `setParameters(uint256 decayRate, uint256 interactionCost, uint256[] memory evolutionEnergyThresholds, uint256[] memory evolutionPurityThresholds, uint256 mintPrice)`: (Admin only) Sets core contract parameters.
26. `getParameters()`: Returns current contract parameters.
27. `pauseContract()`: (Admin only) Pauses certain contract interactions.
28. `unpauseContract()`: (Admin only) Unpauses contract interactions.
29. `paused()`: Returns the current pause status.
30. `setBaseURI(string memory baseURI_)`: (Admin only) Sets the base URI for token metadata.
31. `withdrawEth()`: (Admin only) Withdraws accumulated ETH from minting.
32. `getTotalSupply()`: Returns the total number of artifacts minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MutableArtifacts
 * @dev A smart contract for dynamic, evolving digital artifacts (ERC-721 inspired)
 *      whose state changes based on user interactions, internal resource consumption,
 *      and simulated time decay.
 */

/**
 * @dev Outline:
 * - ERC-721 Standard Implementation (Manual)
 * - Artifact State Management (Energy, Purity, Level, Time)
 * - Aether Essence Internal Resource Management
 * - Artifact Actions (Feed, Purify, Evolve, Bond)
 * - State Decay Logic (Applied on interaction or admin trigger)
 * - Dynamic TokenURI Generation
 * - Administrative Controls (Parameter setting, pausing, resource mint/burn, ETH withdrawal)
 * - Basic Access Control (Owner)
 * - Events for transparency
 */

/**
 * @dev Function Summary:
 * 1.  constructor: Initializes the contract and sets initial parameters.
 * 2.  name: Returns the ERC-721 collection name.
 * 3.  symbol: Returns the ERC-721 collection symbol.
 * 4.  tokenURI: Generates a dynamic metadata URI based on artifact state.
 * 5.  balanceOf: Returns the number of tokens owned by an address (ERC-721).
 * 6.  ownerOf: Returns the owner of a specific token (ERC-721).
 * 7.  transferFrom: Transfers token ownership (ERC-721).
 * 8.  safeTransferFrom (address, address, uint256): Safely transfers token ownership (ERC-721).
 * 9.  safeTransferFrom (address, address, uint256, bytes): Safely transfers token ownership with data (ERC-721).
 * 10. approve: Approves an address to spend a token (ERC-721).
 * 11. getApproved: Returns the approved address for a token (ERC-721).
 * 12. setApprovalForAll: Approves or revokes operator for all tokens (ERC-721).
 * 13. isApprovedForAll: Checks if operator is approved for owner (ERC-721).
 * 14. supportsInterface: ERC-165 interface check.
 * 15. mintArtifact: Creates a new artifact, requiring ETH payment from caller.
 * 16. getArtifactState: Returns the current state of an artifact (decay applied).
 * 17. feedArtifact: Increases artifact energy, consumes owner's Essence.
 * 18. purifyArtifact: Increases artifact purity, consumes owner's Essence.
 * 19. evolveArtifact: Attempts to evolve artifact to next level based on state.
 * 20. bondArtifacts: Interacts two owned artifacts, consumes Essence, subtle state changes.
 * 21. adminTriggerDecay: (Admin) Applies decay to a single artifact.
 * 22. getEssenceBalance: Returns Essence balance for an account.
 * 23. adminMintEssence: (Admin) Mints Essence to an account.
 * 24. adminBurnEssence: (Admin) Burns Essence from an account.
 * 25. setParameters: (Admin) Sets core contract parameters.
 * 26. getParameters: Returns current contract parameters.
 * 27. pauseContract: (Admin) Pauses certain interactions.
 * 28. unpauseContract: (Admin) Unpauses interactions.
 * 29. paused: Returns pause status.
 * 30. setBaseURI: (Admin) Sets the base URI for metadata.
 * 31. withdrawEth: (Admin) Withdraws accumulated ETH.
 * 32. getTotalSupply: Returns the total number of artifacts minted.
 */

// --- Interfaces (Minimal, for type hinting and standard adherence) ---

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// --- Contract ---

contract MutableArtifacts is IERC721, IERC721Metadata {
    // --- State Variables ---

    address private _owner; // Contract administrator
    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    // ERC-721 state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Artifact specific state
    struct ArtifactState {
        uint256 energy; // Represents vitality or potential
        uint256 purity; // Represents refinement or stability
        uint8 level;    // Evolution level (0, 1, 2...)
        uint64 lastInteractionTime; // Timestamp of last state-changing interaction
    }
    mapping(uint256 => ArtifactState) private _artifactStates;
    uint256 private _artifactCounter; // Counter for total minted artifacts

    // Aether Essence state (Internal resource)
    mapping(address => uint256) private _essenceBalances;

    // Contract parameters
    struct ContractParameters {
        uint256 decayRatePerSecond; // How much energy/purity decays per second per artifact
        uint256 interactionEssenceCost; // Base essence cost for Feed, Purify, Bond
        uint256[] evolutionEnergyThresholds; // Min energy required for evolution to next level
        uint256[] evolutionPurityThresholds; // Min purity required for evolution to next level
        uint256 mintPriceEth; // Price to mint a new artifact in wei
    }
    ContractParameters private _parameters;

    bool private _isPaused;

    // --- Events ---

    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event ArtifactStateChanged(uint256 indexed tokenId, uint256 energy, uint256 purity, uint8 level, uint64 lastInteractionTime, string changeType);
    event EssenceBalanceChanged(address indexed account, uint256 newBalance);
    event ParametersUpdated(address indexed admin, ContractParameters newParameters);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event EthWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "Contract is paused");
        _;
    }

    modifier onlyArtifactOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Caller is not artifact owner");
        _;
    }

    // --- Constructor ---

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 initialDecayRate,
        uint256 initialInteractionCost,
        uint256[] memory initialEvolutionEnergyThresholds,
        uint256[] memory initialEvolutionPurityThresholds,
        uint256 initialMintPrice
    ) {
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
        _isPaused = false;
        _artifactCounter = 0;

        // Set initial parameters
        _parameters.decayRatePerSecond = initialDecayRate;
        _parameters.interactionEssenceCost = initialInteractionCost;
        _parameters.evolutionEnergyThresholds = initialEvolutionEnergyThresholds;
        _parameters.evolutionPurityThresholds = initialEvolutionPurityThresholds;
        _parameters.mintPriceEth = initialMintPrice;
    }

    // --- ERC-721 Core Implementation (Manual) ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256 balance) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solidity non-strict type check
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address operator) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev ERC721: Overload of {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // ERC721: 0x80ac58cd
        // ERC721Metadata: 0x5b5e139f
        // ERC165: 0x01ffc9a7
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC165).interfaceId;
    }

    // --- Internal ERC-721 Helpers ---

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Checks if token exists
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Minimal check for ERC721Receiver
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal virtual returns (bool) {
        if (!isContract(to)) {
            return true;
        }
        // Check if the recipient contract implements ERC721Receiver
        bytes4 selector = IERC721Receiver.onERC721Received.selector;
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(selector, msg.sender, from, tokenId, data));
        if (!success) {
             if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }
         bytes4 retval = abi.decode(returndata, (bytes4));
         return (retval == IERC721Receiver.onERC721Received.selector);
    }

    // Minimal check for contract address
     function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    // Needed for _checkOnERC721Received
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }


    // --- Artifact Lifecycle & Interaction ---

    /**
     * @dev Mints a new artifact to the caller. Requires payment of the mint price in ETH.
     * @return The tokenId of the newly minted artifact.
     */
    function mintArtifact() public payable whenNotPaused returns (uint256) {
        require(msg.value >= _parameters.mintPriceEth, "Insufficient ETH sent for minting");

        uint256 newTokenId = _artifactCounter;
        _artifactCounter++;

        // Initialize artifact state
        _artifactStates[newTokenId] = ArtifactState({
            energy: 100, // Starting energy
            purity: 50,  // Starting purity
            level: 0,    // Starting level
            lastInteractionTime: uint64(block.timestamp)
        });

        _safeMint(msg.sender, newTokenId);

        // Refund excess ETH if any
        if (msg.value > _parameters.mintPriceEth) {
             payable(msg.sender).transfer(msg.value - _parameters.mintPriceEth);
        }

        emit ArtifactMinted(newTokenId, msg.sender, uint64(block.timestamp));
        emit ArtifactStateChanged(newTokenId, 100, 50, 0, uint64(block.timestamp), "Minted");

        return newTokenId;
    }

    /**
     * @dev Returns the current state of an artifact, applying decay based on elapsed time.
     * @param tokenId The ID of the artifact.
     * @return The ArtifactState struct with decay applied.
     */
    function getArtifactState(uint256 tokenId) public view returns (ArtifactState memory) {
        require(_owners[tokenId] != address(0), "Artifact does not exist");
        ArtifactState memory currentState = _artifactStates[tokenId];

        uint66 timeElapsed = uint66(block.timestamp) - currentState.lastInteractionTime;
        uint256 decayAmount = timeElapsed * _parameters.decayRatePerSecond;

        // Apply decay, ensure values don't go below zero
        currentState.energy = currentState.energy > decayAmount ? currentState.energy - decayAmount : 0;
        currentState.purity = currentState.purity > decayAmount ? currentState.purity - decayAmount : 0;

        // Decay should not reduce level, only the underlying properties
        return currentState;
    }

    /**
     * @dev Increases the energy of an artifact by consuming the owner's Essence.
     * Decay is applied before adding energy.
     * @param tokenId The ID of the artifact to feed.
     * @param essenceAmount The amount of Essence to consume.
     */
    function feedArtifact(uint256 tokenId, uint256 essenceAmount) public whenNotPaused onlyArtifactOwner(tokenId) {
        require(essenceAmount > 0, "Essence amount must be greater than zero");
        require(_essenceBalances[msg.sender] >= essenceAmount, "Insufficient Aether Essence");
        require(essenceAmount >= _parameters.interactionEssenceCost, "Must use at least minimum interaction cost");

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint66 timeElapsed = uint66(block.timestamp) - artifact.lastInteractionTime;
        uint256 decayAmount = timeElapsed * _parameters.decayRatePerSecond;

        // Apply decay first
        artifact.energy = artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
        artifact.purity = artifact.purity > decayAmount ? artifact.purity - decayAmount : 0;

        // Add energy from feeding (simple proportional increase)
        artifact.energy = artifact.energy + (essenceAmount / _parameters.interactionEssenceCost * 10); // Example: 10 energy per base cost

        // Cap energy/purity at some maximum (e.g., uint256 max or arbitrary)
        // For simplicity, let's allow large values but beware of overflow if not capped.
        // A realistic contract would cap this, e.g., at 1000 or 10000. Let's cap at 1000 for demo.
        uint256 maxStat = 1000;
        if (artifact.energy > maxStat) artifact.energy = maxStat;
         if (artifact.purity > maxStat) artifact.purity = maxStat; // Apply cap to purity too just in case

        // Update last interaction time
        artifact.lastInteractionTime = uint64(block.timestamp);

        // Consume essence
        _essenceBalances[msg.sender] -= essenceAmount;
        emit EssenceBalanceChanged(msg.sender, _essenceBalances[msg.sender]);

        emit ArtifactStateChanged(tokenId, artifact.energy, artifact.purity, artifact.level, artifact.lastInteractionTime, "Fed");
    }

    /**
     * @dev Increases the purity of an artifact by consuming the owner's Essence.
     * Decay is applied before adding purity.
     * @param tokenId The ID of the artifact to purify.
     * @param essenceAmount The amount of Essence to consume.
     */
    function purifyArtifact(uint256 tokenId, uint256 essenceAmount) public whenNotPaused onlyArtifactOwner(tokenId) {
        require(essenceAmount > 0, "Essence amount must be greater than zero");
        require(_essenceBalances[msg.sender] >= essenceAmount, "Insufficient Aether Essence");
        require(essenceAmount >= _parameters.interactionEssenceCost, "Must use at least minimum interaction cost");

        ArtifactState storage artifact = _artifactStates[tokenId];
        uint66 timeElapsed = uint66(block.timestamp) - artifact.lastInteractionTime;
        uint256 decayAmount = timeElapsed * _parameters.decayRatePerSecond;

        // Apply decay first
        artifact.energy = artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
        artifact.purity = artifact.purity > decayAmount ? artifact.purity - decayAmount : 0;

        // Add purity from purifying
        artifact.purity = artifact.purity + (essenceAmount / _parameters.interactionEssenceCost * 10); // Example: 10 purity per base cost

        // Cap purity (and energy just in case)
         uint256 maxStat = 1000;
        if (artifact.purity > maxStat) artifact.purity = maxStat;
        if (artifact.energy > maxStat) artifact.energy = maxStat;

        // Update last interaction time
        artifact.lastInteractionTime = uint64(block.timestamp);

        // Consume essence
        _essenceBalances[msg.sender] -= essenceAmount;
        emit EssenceBalanceChanged(msg.sender, _essenceBalances[msg.sender]);

        emit ArtifactStateChanged(tokenId, artifact.energy, artifact.purity, artifact.level, artifact.lastInteractionTime, "Purified");
    }

    /**
     * @dev Attempts to evolve the artifact to the next level. Requires sufficient energy and purity
     * based on the current level's thresholds. Decay is applied before checking thresholds.
     * @param tokenId The ID of the artifact to evolve.
     */
    function evolveArtifact(uint256 tokenId) public whenNotPaused onlyArtifactOwner(tokenId) {
        ArtifactState storage artifact = _artifactStates[tokenId];
        uint8 currentLevel = artifact.level;

        // Check if max level reached
        require(currentLevel < _parameters.evolutionEnergyThresholds.length, "Artifact is already at maximum level");
        require(currentLevel < _parameters.evolutionPurityThresholds.length, "Artifact is already at maximum level");

        // Calculate state with decay
        ArtifactState memory stateAfterDecay = getArtifactState(tokenId); // Use the view function to get decayed state

        // Check evolution thresholds for the *next* level
        uint256 requiredEnergy = _parameters.evolutionEnergyThresholds[currentLevel];
        uint256 requiredPurity = _parameters.evolutionPurityThresholds[currentLevel];

        require(stateAfterDecay.energy >= requiredEnergy, "Insufficient energy for evolution");
        require(stateAfterDecay.purity >= requiredPurity, "Insufficient purity for evolution");

        // Update state properties in storage struct (decay already handled conceptually by the check above)
        // The decay isn't persisted until a state-changing function is called.
        // So we must manually apply it here before updating time/level.
        uint66 timeElapsed = uint66(block.timestamp) - artifact.lastInteractionTime;
        uint256 decayAmount = timeElapsed * _parameters.decayRatePerSecond;
        artifact.energy = artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
        artifact.purity = artifact.purity > decayAmount ? artifact.purity - decayAmount : 0;


        // Perform evolution
        artifact.level = currentLevel + 1;
        artifact.lastInteractionTime = uint64(block.timestamp); // Update interaction time

        emit ArtifactStateChanged(tokenId, artifact.energy, artifact.purity, artifact.level, artifact.lastInteractionTime, "Evolved");
    }

    /**
     * @dev Performs an interaction between two owned artifacts. Consumes Essence and subtly changes states.
     * Decay is applied to both before the interaction effect.
     * @param tokenId1 The ID of the first artifact.
     * @param tokenId2 The ID of the second artifact.
     */
    function bondArtifacts(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot bond an artifact with itself");
        require(_owners[tokenId1] == msg.sender && _owners[tokenId2] == msg.sender, "Caller must own both artifacts");
        require(_essenceBalances[msg.sender] >= _parameters.interactionEssenceCost, "Insufficient Aether Essence");

        ArtifactState storage artifact1 = _artifactStates[tokenId1];
        ArtifactState storage artifact2 = _artifactStates[tokenId2];

         // Apply decay to both first
        uint66 timeElapsed1 = uint66(block.timestamp) - artifact1.lastInteractionTime;
        uint256 decayAmount1 = timeElapsed1 * _parameters.decayRatePerSecond;
        artifact1.energy = artifact1.energy > decayAmount1 ? artifact1.energy - decayAmount1 : 0;
        artifact1.purity = artifact1.purity > decayAmount1 ? artifact1.purity - decayAmount1 : 0;

        uint66 timeElapsed2 = uint66(block.timestamp) - artifact2.lastInteractionTime;
        uint256 decayAmount2 = timeElapsed2 * _parameters.decayRatePerSecond;
        artifact2.energy = artifact2.energy > decayAmount2 ? artifact2.energy - decayAmount2 : 0;
        artifact2.purity = artifact2.purity > decayAmount2 ? artifact2.purity - decayAmount2 : 0;

        // Bonding logic (example: simple average and slight boost)
        uint256 avgEnergy = (artifact1.energy + artifact2.energy) / 2;
        uint256 avgPurity = (artifact1.purity + artifact2.purity) / 2;

        uint256 boost = 5; // Small boost
        uint256 maxStat = 1000;

        artifact1.energy = avgEnergy + boost;
        artifact1.purity = avgPurity + boost;
        artifact2.energy = avgEnergy + boost;
        artifact2.purity = avgPurity + boost;

        // Apply cap
        if (artifact1.energy > maxStat) artifact1.energy = maxStat;
        if (artifact1.purity > maxStat) artifact1.purity = maxStat;
        if (artifact2.energy > maxStat) artifact2.energy = maxStat;
        if (artifact2.purity > maxStat) artifact2.purity = maxStat;


        // Update last interaction time for both
        uint64 currentTime = uint64(block.timestamp);
        artifact1.lastInteractionTime = currentTime;
        artifact2.lastInteractionTime = currentTime;

        // Consume essence
        _essenceBalances[msg.sender] -= _parameters.interactionEssenceCost;
        emit EssenceBalanceChanged(msg.sender, _essenceBalances[msg.sender]);

        emit ArtifactStateChanged(tokenId1, artifact1.energy, artifact1.purity, artifact1.level, artifact1.lastInteractionTime, "Bonded");
        emit ArtifactStateChanged(tokenId2, artifact2.energy, artifact2.purity, artifact2.level, artifact2.lastInteractionTime, "Bonded");
    }

    /**
     * @dev (Admin only) Manually triggers decay calculation and state update for a single artifact.
     * Useful if interactions are rare and decay needs to be occasionally updated.
     * @param tokenId The ID of the artifact to decay.
     */
    function adminTriggerDecay(uint256 tokenId) public onlyOwner {
         require(_owners[tokenId] != address(0), "Artifact does not exist");
        ArtifactState storage artifact = _artifactStates[tokenId];

        uint66 timeElapsed = uint66(block.timestamp) - artifact.lastInteractionTime;
        uint256 decayAmount = timeElapsed * _parameters.decayRatePerSecond;

        // Apply decay
        artifact.energy = artifact.energy > decayAmount ? artifact.energy - decayAmount : 0;
        artifact.purity = artifact.purity > decayAmount ? artifact.purity - decayAmount : 0;

        // Update last interaction time (since decay was 'applied' up to now)
        artifact.lastInteractionTime = uint64(block.timestamp);

        emit ArtifactStateChanged(tokenId, artifact.energy, artifact.purity, artifact.level, artifact.lastInteractionTime, "Decayed");
    }

    // --- Aether Essence Management ---

    /**
     * @dev Returns the Aether Essence balance of an account.
     * @param account The address to query.
     * @return The balance of Essence.
     */
    function getEssenceBalance(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /**
     * @dev (Admin only) Mints Aether Essence and assigns it to an account.
     * @param account The address to receive Essence.
     * @param amount The amount of Essence to mint.
     */
    function adminMintEssence(address account, uint256 amount) public onlyOwner {
        _essenceBalances[account] += amount;
        emit EssenceBalanceChanged(account, _essenceBalances[account]);
    }

    /**
     * @dev (Admin only) Burns Aether Essence from an account.
     * @param account The address to burn Essence from.
     * @param amount The amount of Essence to burn.
     */
    function adminBurnEssence(address account, uint256 amount) public onlyOwner {
        require(_essenceBalances[account] >= amount, "Insufficient balance to burn");
        _essenceBalances[account] -= amount;
        emit EssenceBalanceChanged(account, _essenceBalances[account]);
    }


    // --- Parameter & Control ---

    /**
     * @dev (Admin only) Sets core contract parameters including decay rate, interaction costs,
     * evolution thresholds, and mint price.
     * @param decayRate The new decay rate per second.
     * @param interactionCost The new base interaction essence cost.
     * @param evolutionEnergyThresholds The new array of energy thresholds for evolution levels.
     * @param evolutionPurityThresholds The new array of purity thresholds for evolution levels.
     * @param mintPrice The new price to mint an artifact in wei.
     */
    function setParameters(
        uint256 decayRate,
        uint256 interactionCost,
        uint256[] memory evolutionEnergyThresholds,
        uint256[] memory evolutionPurityThresholds,
        uint256 mintPrice
    ) public onlyOwner {
         require(evolutionEnergyThresholds.length == evolutionPurityThresholds.length, "Threshold array lengths must match");

        _parameters.decayRatePerSecond = decayRate;
        _parameters.interactionEssenceCost = interactionCost;
        _parameters.evolutionEnergyThresholds = evolutionEnergyThresholds; // Note: copies the array data
        _parameters.evolutionPurityThresholds = evolutionPurityThresholds; // Note: copies the array data
        _parameters.mintPriceEth = mintPrice;

        emit ParametersUpdated(msg.sender, _parameters);
    }

    /**
     * @dev Returns the current contract parameters.
     * @return The ContractParameters struct.
     */
    function getParameters() public view returns (ContractParameters memory) {
        return _parameters;
    }

    /**
     * @dev (Admin only) Pauses certain user interactions (minting, feeding, purifying, evolving, bonding).
     */
    function pauseContract() public onlyOwner {
        require(!_isPaused, "Contract is already paused");
        _isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev (Admin only) Unpauses contract interactions.
     */
    function unpauseContract() public onlyOwner {
        require(_isPaused, "Contract is not paused");
        _isPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Returns the current pause status.
     * @return True if paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _isPaused;
    }

     /**
     * @dev (Admin only) Sets the base URI for token metadata.
     * This is prepended to the token ID to form the full tokenURI,
     * unless tokenURI is dynamically generated internally.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev (Admin only) Allows the contract owner to withdraw accumulated ETH.
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH balance to withdraw");
        payable(msg.sender).transfer(balance);
        emit EthWithdrawn(msg.sender, balance);
    }

    /**
     * @dev Returns the total number of artifacts that have been minted.
     * @return The total supply.
     */
    function getTotalSupply() public view returns (uint256) {
        return _artifactCounter;
    }

    // --- Dynamic Metadata ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This function generates a data URI for the token metadata,
     * including the artifact's dynamic state (energy, purity, level).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");

        ArtifactState memory currentState = getArtifactState(tokenId); // Get state with decay applied

        // Simple JSON structure showing dynamic state
        string memory json = string(abi.encodePacked(
            '{',
            '"name": "Aether Artifact #', _toString(tokenId), '",',
            '"description": "An evolving digital entity.",',
            '"image": "', _baseTokenURI, _toString(currentState.level), '.png",', // Example: image based on level
            '"attributes": [',
                '{"trait_type": "Level", "value": ', _toString(currentState.level), '},',
                '{"trait_type": "Energy", "value": ', _toString(currentState.energy), '},',
                '{"trait_type": "Purity", "value": ', _toString(currentState.purity), '}',
            ']',
            '}'
        ));

        // Return as a Data URI (not base64 encoded for simplicity and gas efficiency)
        // Note: Not all platforms support non-base64 data URIs. A real-world dynamic NFT
        // might use a dedicated metadata service API pointed to by _baseTokenURI.
        return string(abi.encodePacked("data:application/json,", json));
    }


    // --- Utility Functions ---

    /**
     * @dev Converts a uint256 to its ASCII string representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        // From OpenZeppelin/contracts/utils/Strings.sol (re-implemented manually)
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Receive/Fallback ---

    receive() external payable {} // Allows contract to receive ETH
    fallback() external payable {} // Allows contract to receive ETH

}
```