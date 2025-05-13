Okay, here is a smart contract idea combining ERC-721 NFTs with concepts inspired by quantum mechanics (Entanglement, Collapse, Superposition/Jump simulation) and dynamic attributes. It's designed to be novel and have plenty of distinct functions.

**Concept:**

**QuantumEntanglementNFT:** An ERC-721 standard compliant NFT where individual tokens can become "entangled" in pairs. When entangled, their attributes become linked and can influence each other. Entangled states can be "collapsed" which finalizes combined attributes based on a pseudo-random outcome. NFTs can also experience a "quantum jump" effect, randomly altering attributes.

**Key Advanced/Creative Features:**

1.  **Entanglement Mechanic:** Two NFTs can be linked, entering an 'entangled' state.
2.  **State Dependence:** NFT behavior and attributes depend on their entanglement status (Idle, Pending, Entangled, Collapsed, Decohered).
3.  **Attribute Propagation:** Entangled tokens can influence each other's attributes.
4.  **Collapse Function:** Simulates quantum collapse, using on-chain pseudo-randomness to determine an outcome for the entangled pair, locking in attributes.
5.  **Quantum Jump Function:** Allows a token to randomly alter one of its attributes (simulating a "jump").
6.  **Dynamic Metadata:** The `tokenURI` *could* dynamically reflect the current attributes and entanglement state (though the contract only provides the data, an external service would render the URI).
7.  **State Transitions:** Functions manage the lifecycle of entanglement and attribute states.
8.  **Ownership Constraint:** Entanglement/Collapse/Jump functions typically require ownership.
9.  **Internal State Tracking:** Detailed mapping of entanglement pairs, states, and attributes.

---

### Outline and Function Summary

**Contract:** `QuantumEntanglementNFT`

**Inherits:** `ERC721Enumerable`, `Ownable`

**Core Concepts:** ERC-721, Token Attributes, Entanglement State, State Transitions, Pseudo-randomness, Dynamic Data.

**Outline:**

1.  **State Variables:** Define mappings, enums, structs for tokens, attributes, entanglement.
2.  **Events:** Define events for state changes and actions.
3.  **Modifiers:** Define access control modifiers.
4.  **Constructor:** Initialize contract.
5.  **ERC721 Standard Functions:** (Provided by inheritance or overridden)
    *   `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`
    *   `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`
6.  **Custom NFT Functions:**
    *   `mint`: Creates a new NFT with initial attributes.
    *   `burn`: Destroys an NFT (handled carefully with entanglement).
    *   `getAttributes`: Retrieves the attributes of a specific token.
    *   `updateTokenMetadataUri`: Sets the base URI for metadata.
7.  **Entanglement Functions:**
    *   `attemptEntanglement`: Initiates the entanglement process between two *owned* tokens.
    *   `finalizeEntanglement`: Completes the entanglement process after a delay/condition.
    *   `breakEntanglement`: Manually breaks an existing entanglement.
    *   `getEntangledPair`: Returns the token ID a given token is entangled with (if any).
    *   `getEntanglementStatus`: Returns the current status of a potential or actual entanglement pair.
    *   `propagateAttributes`: Triggers attribute changes between an entangled pair based on defined rules.
    *   `collapseEntanglement`: Triggers the 'collapse' of an entangled state, finalizing attributes pseudo-randomly.
    *   `onERC721Received`: Hook to handle incoming NFTs (important if the contract might own NFTs, though not strictly needed for *this* design, included for completeness and function count).
8.  **Quantum Effect Functions:**
    *   `simulateQuantumJump`: Attempts to randomly alter an attribute of an NFT.
9.  **Admin/Configuration Functions:**
    *   `toggleEntanglementAllowed`: Enables/Disables entanglement globally.
    *   `setMintPrice`: Sets the price for minting.
    *   `setEntanglementFee`: Sets a fee for attempting entanglement.
    *   `setEntanglementCooldown`: Sets a cooldown period after entanglement breaks/collapses.
    *   `setQuantumJumpProbability`: Sets the probability of success for `simulateQuantumJump`.
    *   `setAttributePropagationFactor`: Sets how much attributes propagate during entanglement.
    *   `setCollapseOutcomeRanges`: Configures the ranges for collapse outcomes based on randomness.
    *   `withdrawEth`: Allows owner to withdraw collected ETH.
10. **Internal Helper Functions:**
    *   `_getPairKey`: Generates a consistent key for a token pair.
    *   `_beforeTokenTransfer`: Hook to handle entanglement state on transfer.
    *   `_generatePseudoRandomNumber`: Generates a pseudo-random number.
    *   `_applyAttributePropagation`: Applies attribute changes during propagation.
    *   `_applyCollapseOutcome`: Applies attribute changes based on collapse outcome.
    *   `_applyQuantumJump`: Applies attribute changes for a quantum jump.

---

**Function Summary (Listing at least 20 distinct ones):**

1.  **`constructor()`**: Initializes the contract, setting the deployer as the owner and configuring base NFT properties.
2.  **`mint(address to, uint256 initialPower, uint256 initialSpeed, string memory initialColor)`**: Mints a new NFT to `to`, assigning initial attributes. Requires payment of `mintPrice`.
3.  **`burn(uint256 tokenId)`**: Allows the owner of the token to burn it, removing it from existence. Handles cleaning up entanglement state if applicable.
4.  **`getAttributes(uint256 tokenId)`**: Returns the current attributes (`power`, `speed`, `colorTrait`, `generation`) of a specific token.
5.  **`attemptEntanglement(uint256 tokenId1, uint256 tokenId2)`**: Initiates an entanglement request between two *owned* tokens (`tokenId1` and `tokenId2`). Requires payment of `entanglementFee`. Sets the pair status to `Pending`.
6.  **`finalizeEntanglement(uint256 tokenId1, uint256 tokenId2)`**: Completes the entanglement process for a pair in `Pending` status. Requires the owner to call it after a specific block delay (simulated condition). Sets the pair status to `Entangled` and links the tokens.
7.  **`breakEntanglement(uint256 tokenId)`**: Allows the owner of an entangled token (`tokenId`) to manually break the entanglement. Sets the pair status to `Decohered` and unlinks tokens.
8.  **`getEntangledPair(uint256 tokenId)`**: Returns the token ID that `tokenId` is currently entangled with. Returns `0` if not entangled.
9.  **`getEntanglementStatus(uint256 tokenId1, uint256 tokenId2)`**: Returns the current `EntanglementStatus` (`Idle`, `Pending`, `Entangled`, `Collapsed`, `Decohered`) for the pair identified by `tokenId1` and `tokenId2`.
10. **`propagateAttributes(uint256 tokenId1, uint256 tokenId2)`**: Applies the attribute propagation rule between an `Entangled` pair (`tokenId1`, `tokenId2`). Modifies their attributes based on the `attributePropagationFactor`. Can only be called if the pair is `Entangled`.
11. **`collapseEntanglement(uint256 tokenId1, uint256 tokenId2)`**: Triggers the 'collapse' of an `Entangled` pair (`tokenId1`, `tokenId2`). Uses a pseudo-random number derived from block data and the pair IDs to determine an outcome. Applies attribute changes based on the outcome and sets the pair status to `Collapsed`.
12. **`simulateQuantumJump(uint256 tokenId)`**: Allows the owner of `tokenId` to attempt a 'quantum jump'. Uses pseudo-randomness and `quantumJumpProbability` to potentially alter one of the token's attributes (`power` or `speed`). Can result in increase, decrease, or no change. Can only be called on `Idle`, `Collapsed`, or `Decohered` tokens.
13. **`toggleEntanglementAllowed(bool _allowed)`**: Owner-only function to globally enable or disable the ability for users to attempt entanglement.
14. **`setMintPrice(uint256 _price)`**: Owner-only function to set the price (in wei) required to mint a new token.
15. **`getMintPrice()`**: Returns the current price for minting a token.
16. **`setEntanglementFee(uint256 _fee)`**: Owner-only function to set the fee (in wei) required to attempt entanglement.
17. **`getEntanglementFee()`**: Returns the current fee for attempting entanglement.
18. **`setEntanglementCooldown(uint256 _cooldownBlocks)`**: Owner-only function to set the minimum number of blocks that must pass after a pair is `Decohered` or `Collapsed` before they can attempt entanglement again.
19. **`setQuantumJumpProbability(uint256 _probabilityBasisPoints)`**: Owner-only function to set the probability of a `simulateQuantumJump` being successful (in basis points, 0-10000).
20. **`setAttributePropagationFactor(uint256 _factorBasisPoints)`**: Owner-only function to set the factor (in basis points) determining how much attributes are averaged/propagated during `propagateAttributes`.
21. **`setCollapseOutcomeRanges(uint256[] memory _ranges)`**: Owner-only function to configure the random number ranges that map to different outcomes during `collapseEntanglement`.
22. **`withdrawEth()`**: Owner-only function to withdraw any Ether accumulated in the contract (from minting fees, entanglement fees).
23. **`tokenURI(uint256 tokenId)` (Override)**: Returns the metadata URI for a token. This implementation can be overridden to generate dynamic metadata based on the token's attributes and entanglement state.
24. **`onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)` (Hook)**: ERC-721 receiver hook. Included to demonstrate contract's ability to potentially receive NFTs (though not central to the core logic here).
25. **`_beforeTokenTransfer(address from, address to, uint256 tokenId)` (Internal Hook)**: Internal OpenZeppelin hook. Used to automatically break entanglement (`Decohered` status) if an entangled token is transferred.

*(Note: Standard ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, etc., are provided by OpenZeppelin inheritance, contributing to the overall functionality but not listed individually above to highlight the custom functions. Including the enumerable functions `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex` brings the inherited function count up significantly, ensuring well over 20 distinct functions are available in the deployed contract.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although less needed in 0.8+, good habit for clarity/safety

// --- Outline and Function Summary ---
// Contract: QuantumEntanglementNFT
// Inherits: ERC721Enumerable, Ownable
// Core Concepts: ERC-721, Token Attributes, Entanglement State, State Transitions, Pseudo-randomness, Dynamic Data.

// Outline:
// 1. State Variables: Mappings, enums, structs for tokens, attributes, entanglement.
// 2. Events: Define events for state changes and actions.
// 3. Modifiers: Define access control modifiers.
// 4. Constructor: Initialize contract.
// 5. ERC721 Standard Functions: (Provided by inheritance or overridden)
//    - balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, tokenURI
//    - totalSupply, tokenByIndex, tokenOfOwnerByIndex
// 6. Custom NFT Functions:
//    - mint: Creates a new NFT with initial attributes.
//    - burn: Destroys an NFT.
//    - getAttributes: Retrieves the attributes of a token.
//    - updateTokenMetadataUri: Sets base URI.
// 7. Entanglement Functions:
//    - attemptEntanglement: Initiates entanglement.
//    - finalizeEntanglement: Completes entanglement.
//    - breakEntanglement: Breaks entanglement.
//    - getEntangledPair: Gets entangled partner.
//    - getEntanglementStatus: Gets pair status.
//    - propagateAttributes: Applies attribute changes between entangled pair.
//    - collapseEntanglement: Triggers 'collapse' of entangled state.
//    - onERC721Received: ERC721 receiver hook.
// 8. Quantum Effect Functions:
//    - simulateQuantumJump: Randomly alters an attribute.
// 9. Admin/Configuration Functions:
//    - toggleEntanglementAllowed: Global entanglement enable/disable.
//    - setMintPrice: Sets mint price.
//    - getMintPrice: Gets mint price.
//    - setEntanglementFee: Sets entanglement fee.
//    - getEntanglementFee: Gets entanglement fee.
//    - setEntanglementCooldown: Sets cooldown.
//    - setQuantumJumpProbability: Sets jump probability.
//    - setAttributePropagationFactor: Sets propagation factor.
//    - setCollapseOutcomeRanges: Configures collapse outcomes.
//    - withdrawEth: Withdraws ETH.
// 10. Internal Helper Functions:
//     - _getPairKey: Generates consistent key for a pair.
//     - _beforeTokenTransfer: Hook for transfer side effects.
//     - _generatePseudoRandomNumber: Generates pseudo-random number.
//     - _applyAttributePropagation: Internal propagation logic.
//     - _applyCollapseOutcome: Internal collapse logic.
//     - _applyQuantumJump: Internal jump logic.

// Function Summary (Listing at least 20 distinct ones):
// 1. constructor(): Initializes the contract.
// 2. mint(address to, uint256 initialPower, uint256 initialSpeed, string memory initialColor): Mints a new NFT with attributes.
// 3. burn(uint256 tokenId): Burns an NFT, handling entanglement.
// 4. getAttributes(uint256 tokenId): Returns token attributes.
// 5. attemptEntanglement(uint256 tokenId1, uint256 tokenId2): Initiates entanglement between two owned tokens.
// 6. finalizeEntanglement(uint256 tokenId1, uint256 tokenId2): Completes pending entanglement.
// 7. breakEntanglement(uint256 tokenId): Manually breaks entanglement for a token.
// 8. getEntangledPair(uint256 tokenId): Returns partner token ID for an entangled token.
// 9. getEntanglementStatus(uint256 tokenId1, uint256 tokenId2): Returns the status of a token pair.
// 10. propagateAttributes(uint256 tokenId1, uint256 tokenId2): Applies attribute changes based on entanglement.
// 11. collapseEntanglement(uint256 tokenId1, uint256 tokenId2): Triggers entanglement collapse and finalizes attributes.
// 12. simulateQuantumJump(uint256 tokenId): Attempts to randomly alter a token's attribute.
// 13. toggleEntanglementAllowed(bool _allowed): Owner sets global entanglement permission.
// 14. setMintPrice(uint256 _price): Owner sets the price for minting.
// 15. getMintPrice(): Returns the current mint price.
// 16. setEntanglementFee(uint256 _fee): Owner sets the fee for attempting entanglement.
// 17. getEntanglementFee(): Returns the current entanglement fee.
// 18. setEntanglementCooldown(uint256 _cooldownBlocks): Owner sets blocks required after break/collapse.
// 19. setQuantumJumpProbability(uint256 _probabilityBasisPoints): Owner sets jump success probability.
// 20. setAttributePropagationFactor(uint256 _factorBasisPoints): Owner sets propagation influence.
// 21. setCollapseOutcomeRanges(uint256[] memory _ranges): Owner configures collapse results.
// 22. withdrawEth(): Owner withdraws ETH from the contract.
// 23. tokenURI(uint256 tokenId): Returns metadata URI (potentially dynamic).
// 24. onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): ERC721 receive hook.
// 25. _beforeTokenTransfer(address from, address to, uint256 tokenId): Internal hook for transfer effects.
// (Plus standard inherited ERC721Enumerable functions like ownerOf, balanceOf, transferFrom, safeTransferFrom, etc., totaling well over 20 functions)

contract QuantumEntanglementNFT is ERC721Enumerable, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    struct TokenAttributes {
        uint256 power;
        uint256 speed;
        string colorTrait; // Example attribute
        uint8 generation;
    }

    enum EntanglementStatus {
        Idle,          // Not involved in entanglement
        Pending,       // Attempted entanglement, waiting for finalization conditions
        Entangled,     // Actively entangled
        Collapsed,     // Entanglement has collapsed, state finalized
        Decohered      // Entanglement was broken/ended, now separate
    }

    // Mapping tokenId -> TokenAttributes
    mapping(uint256 => TokenAttributes) private _tokenAttributes;

    // Mapping tokenId -> tokenId (partner in entanglement, 0 if not entangled)
    mapping(uint256 => uint256) private _entangledPairs;

    // Mapping pairKey -> EntanglementStatus
    mapping(bytes32 => EntanglementStatus) private _entanglementStatus;

    // Mapping pairKey -> block.number when status changed (e.g., Decohered or Collapsed)
    mapping(bytes32 => uint256) private _lastEntanglementEndBlock;

    string private _baseTokenURI;

    bool public entanglementAllowed = true;
    uint256 public mintPrice = 0.01 ether; // Example price
    uint256 public entanglementFee = 0.001 ether; // Example fee
    uint256 public entanglementFinalizeDelayBlocks = 5; // Blocks to wait before finalizing entanglement
    uint256 public entanglementCooldownBlocks = 10; // Blocks cooldown after break/collapse
    uint256 public quantumJumpProbabilityBasisPoints = 2000; // 20% chance (2000/10000)
    uint256 public attributePropagationFactorBasisPoints = 5000; // 50% influence
    // Configurable ranges for collapse outcomes [range_boundary_1, range_boundary_2, ...]
    // Pseudo-random number will fall into a range, determining the outcome type.
    // Example: [5000] -> if random < 5000 (50% chance) outcome A, else outcome B.
    // Example: [3000, 7000] -> <3000 (30%) A, 3000-6999 (40%) B, >=7000 (30%) C
    uint256[] public collapseOutcomeRanges;

    // Events
    event NFTMinted(address indexed to, uint256 indexed tokenId, TokenAttributes attributes);
    event NFTBurned(uint256 indexed tokenId);
    event EntanglementAttempted(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event EntanglementFinalized(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementCollapsed(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event AttributesPropagated(uint256 indexed tokenId1, uint256 indexed tokenId2, TokenAttributes attributes1, TokenAttributes attributes2);
    event QuantumJumpAttempted(uint256 indexed tokenId, bool success, TokenAttributes oldAttributes, TokenAttributes newAttributes);
    event EntanglementStatusChanged(uint256 indexed tokenId1, uint256 indexed tokenId2, EntanglementStatus oldStatus, EntanglementStatus newStatus);

    // Modifiers
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        _;
    }

    modifier onlyEntanglementAllowed() {
        require(entanglementAllowed, "Entanglement is currently disabled");
        _;
    }

    modifier onlyEntangled(uint256 _tokenId1, uint256 _tokenId2) {
        bytes32 pairKey = _getPairKey(_tokenId1, _tokenId2);
        require(_entanglementStatus[pairKey] == EntanglementStatus.Entangled, "Pair is not Entangled");
        require(_entangledPairs[_tokenId1] == _tokenId2 && _entangledPairs[_tokenId2] == _tokenId1, "Tokens are not linked as entangled pair");
        _;
    }

    modifier onlyEntanglementPending(uint256 _tokenId1, uint256 _tokenId2) {
        bytes32 pairKey = _getPairKey(_tokenId1, _tokenId2);
        require(_entanglementStatus[pairKey] == EntanglementStatus.Pending, "Pair is not Pending Entanglement");
        _;
    }

    modifier onlyNotEntangledOrPending(uint256 _tokenId) {
         require(_entangledPairs[_tokenId] == 0, "Token is involved in entanglement");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
         // Default collapse outcome ranges (e.g., 3 outcomes with ~33% chance each)
        collapseOutcomeRanges = [3333, 6666]; // Example: <3333 -> Outcome1, 3333-6665 -> Outcome2, >=6666 -> Outcome3
    }

    // --- ERC721 Standard Overrides ---

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        // Use _beforeTokenTransfer hook instead of directly overriding _update
        return super._update(to, tokenId, auth);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) {
            uint256 partnerTokenId = _entangledPairs[tokenId];
            if (partnerTokenId != 0) {
                 // If an entangled token is transferred, break the entanglement
                 _breakEntanglementInternal(tokenId, partnerTokenId);
            }
        }
    }

    // We provide a base URI, but actual metadata should be off-chain and dynamic
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Append token ID to base URI
        string memory base = _baseTokenURI;
        // In a real application, you'd likely fetch attributes and state here
        // and construct a dynamic JSON metadata URI pointing to an off-chain service.
        // For this example, we just return base + tokenId.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // --- Custom NFT Functions ---

    function mint(address to, uint256 initialPower, uint256 initialSpeed, string memory initialColor)
        public
        payable
    {
        require(msg.value >= mintPrice, "Insufficient ETH for mint");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        _tokenAttributes[newItemId] = TokenAttributes({
            power: initialPower,
            speed: initialSpeed,
            colorTrait: initialColor,
            generation: 1 // Example generation
        });

        emit NFTMinted(to, newItemId, _tokenAttributes[newItemId]);
    }

    function burn(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
    {
        uint256 partnerTokenId = _entangledPairs[tokenId];
        if (partnerTokenId != 0) {
            // Break entanglement before burning
            _breakEntanglementInternal(tokenId, partnerTokenId);
        }

        _burn(tokenId);
        delete _tokenAttributes[tokenId]; // Clean up attributes

        emit NFTBurned(tokenId);
    }

    function getAttributes(uint256 tokenId) public view returns (TokenAttributes memory) {
        require(_exists(tokenId), "NFT does not exist");
        return _tokenAttributes[tokenId];
    }

    function updateTokenMetadataUri(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    // --- Entanglement Functions ---

    function attemptEntanglement(uint256 tokenId1, uint256 tokenId2)
        public
        payable
        onlyEntanglementAllowed
    {
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(ownerOf(tokenId1) == msg.sender, "Not owner of token 1");
        require(ownerOf(tokenId2) == msg.sender, "Not owner of token 2");
        require(msg.value >= entanglementFee, "Insufficient ETH for entanglement fee");

        bytes32 pairKey = _getPairKey(tokenId1, tokenId2);
        EntanglementStatus currentStatus = _entanglementStatus[pairKey];

        require(currentStatus == EntanglementStatus.Idle || currentStatus == EntanglementStatus.Decohered || currentStatus == EntanglementStatus.Collapsed, "Pair is already involved in entanglement");

        if (currentStatus != EntanglementStatus.Idle) {
             // Check cooldown if not Idle
             require(block.number >= _lastEntanglementEndBlock[pairKey] + entanglementCooldownBlocks, "Entanglement cooldown in effect");
        }

        // Set status to Pending and record block number
        _entanglementStatus[pairKey] = EntanglementStatus.Pending;
         // Store the block number when pending started (can be used for finalization delay)
        _lastEntanglementEndBlock[pairKey] = block.number;

        emit EntanglementAttempted(tokenId1, tokenId2, msg.sender);
        emit EntanglementStatusChanged(tokenId1, tokenId2, currentStatus, EntanglementStatus.Pending);
    }

    function finalizeEntanglement(uint256 tokenId1, uint256 tokenId2)
        public
        onlyTokenOwner(tokenId1) // Owner must own at least one, implies they likely own both from attemptEntanglement
    {
         require(_exists(tokenId1), "Token 1 does not exist");
         require(_exists(tokenId2), "Token 2 does not exist");
         // Re-check ownership of both just in case
         require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Must own both tokens to finalize");

        bytes32 pairKey = _getPairKey(tokenId1, tokenId2);
        EntanglementStatus currentStatus = _entanglementStatus[pairKey];

        require(currentStatus == EntanglementStatus.Pending, "Pair is not Pending Entanglement");
        require(block.number >= _lastEntanglementEndBlock[pairKey] + entanglementFinalizeDelayBlocks, "Entanglement finalize delay not met");

        // Link the tokens
        _entangledPairs[tokenId1] = tokenId2;
        _entangledPairs[tokenId2] = tokenId1;

        // Update status
        _entanglementStatus[pairKey] = EntanglementStatus.Entangled;
         // Update last end block to 0 or another marker, as it's now active
        _lastEntanglementEndBlock[pairKey] = 0; // Or a specific active marker

        emit EntanglementFinalized(tokenId1, tokenId2);
        emit EntanglementStatusChanged(tokenId1, tokenId2, currentStatus, EntanglementStatus.Entangled);
    }


    function breakEntanglement(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
    {
        uint256 partnerTokenId = _entangledPairs[tokenId];
        require(partnerTokenId != 0, "Token is not entangled");
         // Re-check owner of partner just in case
        require(ownerOf(partnerTokenId) == msg.sender, "Must own both tokens to break entanglement manually");

        _breakEntanglementInternal(tokenId, partnerTokenId);
    }

    function _breakEntanglementInternal(uint256 tokenId1, uint256 tokenId2) internal {
        // Ensure consistent order for pairKey
        uint256 t1 = tokenId1 < tokenId2 ? tokenId1 : tokenId2;
        uint256 t2 = tokenId1 < tokenId2 ? tokenId2 : tokenId1;

        bytes32 pairKey = _getPairKey(t1, t2);
        EntanglementStatus currentStatus = _entanglementStatus[pairKey];

        // Only break if Entangled or Pending
        require(currentStatus == EntanglementStatus.Entangled || currentStatus == EntanglementStatus.Pending, "Pair not in active or pending entanglement state");

        _entangledPairs[t1] = 0;
        _entangledPairs[t2] = 0;

        _entanglementStatus[pairKey] = EntanglementStatus.Decohered;
        _lastEntanglementEndBlock[pairKey] = block.number; // Start cooldown

        emit EntanglementBroken(t1, t2);
        emit EntanglementStatusChanged(t1, t2, currentStatus, EntanglementStatus.Decohered);
    }


    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return _entangledPairs[tokenId];
    }

    function getEntanglementStatus(uint256 tokenId1, uint256 tokenId2) public view returns (EntanglementStatus) {
         // Handle order inconsistency
        return _entanglementStatus[_getPairKey(tokenId1, tokenId2)];
    }

    function propagateAttributes(uint256 tokenId1, uint256 tokenId2)
        public
        onlyTokenOwner(tokenId1) // Owner must own at least one, implies they likely own both
        onlyEntangled(tokenId1, tokenId2)
    {
        // Re-check ownership of both just in case
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Must own both tokens to propagate attributes");

        TokenAttributes storage attrs1 = _tokenAttributes[tokenId1];
        TokenAttributes storage attrs2 = _tokenAttributes[tokenId2];

        _applyAttributePropagation(attrs1, attrs2);

        emit AttributesPropagated(tokenId1, tokenId2, attrs1, attrs2);
    }

    function collapseEntanglement(uint256 tokenId1, uint256 tokenId2)
        public
        onlyTokenOwner(tokenId1) // Owner must own at least one, implies they likely own both
        onlyEntangled(tokenId1, tokenId2)
    {
         // Re-check ownership of both just in case
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Must own both tokens to collapse entanglement");

        bytes32 pairKey = _getPairKey(tokenId1, tokenId2);
        TokenAttributes storage attrs1 = _tokenAttributes[tokenId1];
        TokenAttributes storage attrs2 = _tokenAttributes[tokenId2];

        // Generate pseudo-random number based on block info and pair key
        uint256 randomNumber = _generatePseudoRandomNumber(pairKey);

        // Apply collapse outcome based on random number
        _applyCollapseOutcome(attrs1, attrs2, randomNumber);

        // Unlink and update status
        _entangledPairs[tokenId1] = 0;
        _entangledPairs[tokenId2] = 0;
        _entanglementStatus[pairKey] = EntanglementStatus.Collapsed;
        _lastEntanglementEndBlock[pairKey] = block.number; // Start cooldown

        emit EntanglementCollapsed(tokenId1, tokenId2);
        emit EntanglementStatusChanged(tokenId1, tokenId2, EntanglementStatus.Entangled, EntanglementStatus.Collapsed);
    }

    // --- Quantum Effect Functions ---

    function simulateQuantumJump(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
        onlyNotEntangledOrPending(tokenId) // Cannot jump if entangled or pending
    {
        TokenAttributes storage attrs = _tokenAttributes[tokenId];
        TokenAttributes memory oldAttrs = attrs; // Store old attributes for event

        // Generate pseudo-random number for outcome
        uint256 randomNumber = _generatePseudoRandomNumber(bytes32(tokenId));

        // Check probability
        bool success = (randomNumber % 10001) <= quantumJumpProbabilityBasisPoints;

        if (success) {
            _applyQuantumJump(attrs, randomNumber);
        }

        emit QuantumJumpAttempted(tokenId, success, oldAttrs, attrs);
    }


    // --- Admin/Configuration Functions ---

    function toggleEntanglementAllowed(bool _allowed) public onlyOwner {
        entanglementAllowed = _allowed;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setEntanglementFee(uint256 _fee) public onlyOwner {
        entanglementFee = _fee;
    }

    function getEntanglementFee() public view returns (uint256) {
        return entanglementFee;
    }

     function setEntanglementFinalizeDelayBlocks(uint256 _blocks) public onlyOwner {
        entanglementFinalizeDelayBlocks = _blocks;
    }

    function setEntanglementCooldown(uint256 _cooldownBlocks) public onlyOwner {
        entanglementCooldownBlocks = _cooldownBlocks;
    }

    function setQuantumJumpProbability(uint256 _probabilityBasisPoints) public onlyOwner {
        require(_probabilityBasisPoints <= 10000, "Probability cannot exceed 100%");
        quantumJumpProbabilityBasisPoints = _probabilityBasisPoints;
    }

    function setAttributePropagationFactor(uint256 _factorBasisPoints) public onlyOwner {
        require(_factorBasisPoints <= 10000, "Factor cannot exceed 100%");
        attributePropagationFactorBasisPoints = _factorBasisPoints;
    }

    function setCollapseOutcomeRanges(uint256[] memory _ranges) public onlyOwner {
        // Basic validation: ranges should be increasing and within [0, 10000]
        uint256 lastRange = 0;
        for (uint i = 0; i < _ranges.length; i++) {
            require(_ranges[i] > lastRange && _ranges[i] <= 10000, "Invalid collapse outcome ranges");
            lastRange = _ranges[i];
        }
        collapseOutcomeRanges = _ranges;
    }

    function withdrawEth() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Internal Helper Functions ---

    function _getPairKey(uint256 tokenId1, uint256 tokenId2) internal pure returns (bytes32) {
        // Ensure consistent key regardless of order
        if (tokenId1 < tokenId2) {
            return keccak256(abi.encodePacked(tokenId1, tokenId2));
        } else {
            return keccak256(abi.encodePacked(tokenId2, tokenId1));
        }
    }

    function _generatePseudoRandomNumber(bytes32 seed) internal view returns (uint256) {
        // Use block data and a unique seed for pseudo-randomness
        // NOTE: This is NOT cryptographically secure randomness.
        // Miners/validators can influence block data.
        // For production, use Chainlink VRF or similar.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, seed)));
    }

    function _applyAttributePropagation(TokenAttributes storage attrs1, TokenAttributes storage attrs2) internal {
        uint256 factor = attributePropagationFactorBasisPoints;

        // Simple averaging logic based on factor
        // New power = (Old power * (10000 - factor) + Partner power * factor) / 10000
        attrs1.power = (attrs1.power.mul(10000 - factor).add(attrs2.power.mul(factor))).div(10000);
        attrs1.speed = (attrs1.speed.mul(10000 - factor).add(attrs2.speed.mul(factor))).div(10000);

        attrs2.power = (attrs2.power.mul(10000 - factor).add(attrs1.power.mul(factor))).div(10000);
        attrs2.speed = (attrs2.speed.mul(10000 - factor).add(attrs1.speed.mul(factor))).div(10000);

        // Color trait could be more complex, e.g., concatenate, mix, or based on dominance
        // Example: Simple concatenation or pick based on power/speed
        // For simplicity, let's leave color trait static or require specific logic.
        // Here, we'll just modify numeric traits.
    }

    function _applyCollapseOutcome(TokenAttributes storage attrs1, TokenAttributes storage attrs2, uint256 randomNumber) internal {
        // Scale random number to 0-10000 range
        uint256 scaledRandom = randomNumber % 10001;

        // Determine outcome based on ranges
        uint256 outcomeIndex = 0;
        for (uint i = 0; i < collapseOutcomeRanges.length; i++) {
            if (scaledRandom >= collapseOutcomeRanges[i]) {
                outcomeIndex = i + 1;
            } else {
                break; // Found the range
            }
        }

        // --- Define Collapse Outcomes ---
        // Example Logic:
        // Outcome 0: Super Success (Both get enhanced stats)
        // Outcome 1: Success (Both get averaged/good stats)
        // Outcome 2: Partial Success (One gets good stats, other medium)
        // Outcome 3: Neutral (Average stats)
        // Outcome 4: Failure (Stats potentially decrease or average low)

        if (outcomeIndex == 0) { // Super Success (e.g., random < collapseOutcomeRanges[0])
            attrs1.power = attrs1.power.add(attrs2.power).div(2).mul(120).div(100); // 20% boost over average
            attrs1.speed = attrs1.speed.add(attrs2.speed).div(2).mul(120).div(100);
            attrs2.power = attrs1.power; // Match partner
            attrs2.speed = attrs1.speed; // Match partner
        } else if (outcomeIndex == 1) { // Success (e.g., collapseOutcomeRanges[0] <= random < collapseOutcomeRanges[1])
             uint256 avgPower = attrs1.power.add(attrs2.power).div(2);
             uint256 avgSpeed = attrs1.speed.add(attrs2.speed).div(2);
             attrs1.power = avgPower;
             attrs1.speed = avgSpeed;
             attrs2.power = avgPower;
             attrs2.speed = avgSpeed;
        } else if (outcomeIndex == 2) { // Partial Success (e.g., collapseOutcomeRanges[1] <= random < collapseOutcomeRanges[2] if exists)
            // One token gets a boost, the other gets average
            if (attrs1.power + attrs1.speed >= attrs2.power + attrs2.speed) { // Token1 was stronger
                attrs1.power = attrs1.power.add(attrs2.power).div(2).mul(110).div(100);
                attrs1.speed = attrs1.speed.add(attrs2.speed).div(2).mul(110).div(100);
                 uint256 avgPower = attrs1.power.add(attrs2.power).div(2); // Use original for average
                 uint256 avgSpeed = attrs1.speed.add(attrs2.speed).div(2);
                attrs2.power = avgPower;
                attrs2.speed = avgSpeed;
            } else { // Token2 was stronger
                 uint256 avgPower = attrs1.power.add(attrs2.power).div(2); // Use original for average
                 uint256 avgSpeed = attrs1.speed.add(attrs2.speed).div(2);
                attrs1.power = avgPower;
                attrs1.speed = avgSpeed;
                attrs2.power = attrs1.power.add(attrs2.power).div(2).mul(110).div(100);
                attrs2.speed = attrs1.speed.add(attrs2.speed).div(2).mul(110).div(100);
            }
        }
        // Add more outcomes based on collapseOutcomeRanges.length

        // Example: If outcomeIndex is the last possible or out of bounds, it's a 'Neutral' or 'Failure'
        // If outcomeIndex >= collapseOutcomeRanges.length
         else { // Neutral/Failure (e.g., >= last range boundary)
            uint256 avgPower = attrs1.power.add(attrs2.power).div(2);
            uint256 avgSpeed = attrs1.speed.add(attrs2.speed).div(2);
            attrs1.power = avgPower;
            attrs1.speed = avgSpeed;
            attrs2.power = avgPower;
            attrs2.speed = avgSpeed; // Or apply a penalty
         }

         // Ensure minimum values if needed
         attrs1.power = attrs1.power > 1 ? attrs1.power : 1;
         attrs1.speed = attrs1.speed > 1 ? attrs1.speed : 1;
         attrs2.power = attrs2.power > 1 ? attrs2.power : 1;
         attrs2.speed = attrs2.speed > 1 ? attrs2.speed : 1;

        // Color trait could change based on outcome too
    }

     function _applyQuantumJump(TokenAttributes storage attrs, uint256 randomNumber) internal {
        // Decide which attribute to affect (e.g., based on another part of randomNumber)
        bool affectPower = (randomNumber % 2) == 0; // 50% chance power, 50% speed

        // Decide direction and magnitude of change (example: +/- 10%)
        bool increase = (randomNumber % 100) < 50; // 50% chance increase, 50% decrease
        uint256 changeFactorBasisPoints = (randomNumber % 2001) + 500; // Random factor between 5% and 25%

        if (affectPower) {
            if (increase) {
                attrs.power = attrs.power.mul(10000 + changeFactorBasisPoints).div(10000);
            } else {
                attrs.power = attrs.power.mul(10000 > changeFactorBasisPoints ? 10000 - changeFactorBasisPoints : 0).div(10000);
            }
             // Ensure minimum
            attrs.power = attrs.power > 1 ? attrs.power : 1;
        } else { // Affect speed
             if (increase) {
                attrs.speed = attrs.speed.mul(10000 + changeFactorBasisPoints).div(10000);
            } else {
                attrs.speed = attrs.speed.mul(10000 > changeFactorBasisPoints ? 10000 - changeFactorBasisPoints : 0).div(10000);
            }
             // Ensure minimum
            attrs.speed = attrs.speed > 1 ? attrs.speed : 1;
        }

        // Color trait could potentially jump too, but requires more complex logic (e.g., mapping colors)
    }

    // --- IERC721Receiver Implementation ---
    // Required if this contract might own NFTs itself, not just manage them.
    // For this contract's core logic, it's not strictly necessary for *itself* to hold NFTs,
    // but included to fulfill the spirit of a feature-rich contract.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Safely accept ERC721 tokens
        // You might add logic here to handle received NFTs (e.g., store them, interact with them)
        // but for this contract, we'll just return the required value.
        return this.onERC721Received.selector;
    }
}
```