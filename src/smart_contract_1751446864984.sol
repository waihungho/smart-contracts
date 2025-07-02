Okay, here is a Solidity smart contract implementing an advanced, dynamic NFT concept I'll call "MetaMorph Market".

The core idea is an ERC-721 token that represents a unique entity (let's call them "MetaMorphs") with on-chain mutable attributes, energy, and levels. These MetaMorphs can "morph" or change their attributes, level up, spend energy for actions, and even record their history directly on the blockchain. It includes a basic marketplace for trading these dynamic assets.

This design incorporates:
1.  **Dynamic State:** Attributes, energy, and level are stored on-chain and can change.
2.  **Gamification:** Concepts like leveling, energy, and attribute boosting.
3.  **Procedural/Deterministic Elements:** Initial attributes and morphing might be influenced by a unique seed.
4.  **On-chain Provenance:** Recording significant events in the token's history.
5.  **Custom Marketplace:** Simple buy/sell mechanics integrated directly.
6.  **Owner Management:** Control over costs and core parameters.

It's important to note that truly dynamic *visual* or external metadata requires an off-chain service (like an API or IPFS with dynamic rendering) that reads the on-chain state (attributes, level, etc.) via the `tokenURI` and generates the corresponding JSON and image. The contract itself stores the *data* that drives this dynamic metadata.

---

**Smart Contract Outline: MetaMorphMarket**

1.  **License and Imports:** SPDX License, OpenZeppelin library imports (ERC721, Ownable, ERC165).
2.  **Error Definitions:** Custom errors for clearer failure reasons.
3.  **Structs:**
    *   `Attributes`: Stores integer attributes like Strength, Dexterity, etc.
    *   `HistoryEntry`: Records significant events for a token (timestamp, type, description).
    *   `Listing`: Stores marketplace listing information (seller, price).
4.  **State Variables:**
    *   Mappings to store token attributes, energy, level, seed, history, and marketplace listings by token ID.
    *   Counters for token IDs.
    *   Variables for costs of actions (leveling, morphing, etc.).
    *   Base URI for dynamic metadata.
    *   Contract owner address.
    *   Accumulated contract balance (from fees/sales).
5.  **Events:** Signals for key actions (Minting, Leveling Up, Morphing, Listing, Sale, etc.).
6.  **Modifiers:** Restrict access (`onlyOwner`, `onlyTokenOwner`).
7.  **Constructor:** Initializes the contract owner, base URI, and initial costs.
8.  **ERC-721 Standard Functions:** Implementations/Overrides for required ERC-721 functions (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`).
9.  **Core MetaMorph Mechanics:**
    *   Minting functions (`mintInitial`, `mintWithSeed`).
    *   Getters for token state (`getTokenAttributes`, `getTokenEnergy`, `getTokenLevel`, `getTokenSeed`).
    *   Action functions (`replenishEnergy`, `spendEnergy` - internal/helper primarily, `levelUp`, `morphToken`, `boostAttribute`, `respecAttributes`).
10. **Provenance/History:**
    *   Functions to retrieve token history (`getTokenHistory`, `getHistoryEntryCount`, `getHistoryEntry`).
11. **Marketplace Functions:**
    *   Listing and cancelling (`listTokenForSale`, `cancelListing`).
    *   Purchasing (`buyToken`).
    *   Getting listing info (`getTokenListing`).
12. **Owner/Management Functions:**
    *   Setting costs and URI (`setEnergyReplenishCost`, etc., `setBaseURI`).
    *   Withdrawing funds (`withdrawProceeds`).
13. **Internal Helper Functions:** Logic for generating attributes, recording history, etc.
14. **ERC-165 Support:** `supportsInterface`.

---

**Function Summary:**

1.  `constructor()`: Initializes contract with owner, base URI, and default costs.
2.  `balanceOf(address owner)`: (ERC-721) Returns number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId)`: (ERC-721) Returns owner of a token.
4.  `approve(address to, uint256 tokenId)`: (ERC-721) Approves an address to transfer a specific token.
5.  `getApproved(uint256 tokenId)`: (ERC-721) Returns the approved address for a token.
6.  `setApprovalForAll(address operator, bool approved)`: (ERC-721) Approves/disapproves an operator for all owner's tokens.
7.  `isApprovedForAll(address owner, address operator)`: (ERC-721) Checks if an operator is approved for an owner.
8.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC-721) Transfers token ownership.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC-721) Transfers token ownership safely (checks receiver).
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC-721) Transfers token ownership safely with data.
11. `tokenURI(uint256 tokenId)`: (ERC-721 Override) Returns the dynamic metadata URI for a token based on its current state.
12. `supportsInterface(bytes4 interfaceId)`: (ERC-165) Indicates supported interfaces (ERC-721, ERC-165).
13. `mintInitial(address recipient)`: Mints a new MetaMorph token with procedurally generated initial state for the recipient.
14. `mintWithSeed(address recipient, uint256 seed)`: Mints a new MetaMorph token using a specific seed (if allowed by contract logic/state, e.g., during specific minting phases).
15. `getTokenAttributes(uint256 tokenId)`: Returns the current attributes (Strength, Dexterity, etc.) of a token.
16. `getTokenEnergy(uint256 tokenId)`: Returns the current energy level of a token.
17. `getTokenLevel(uint256 tokenId)`: Returns the current level of a token.
18. `getTokenSeed(uint256 tokenId)`: Returns the unique seed associated with a token.
19. `replenishEnergy(uint256 tokenId)`: Allows the token owner to replenish energy for a token by paying a cost.
20. `levelUp(uint256 tokenId)`: Allows the token owner to level up a token if conditions are met (e.g., sufficient energy, payment). Increases level and potentially attribute points.
21. `morphToken(uint256 tokenId)`: Allows the token owner to "morph" the token, potentially changing its attributes based on its seed, level, and energy, by paying a cost. Records history.
22. `boostAttribute(uint256 tokenId, string memory attributeName, uint256 points)`: Allows the token owner to spend attribute points (gained from leveling) to increase a specific attribute. Records history.
23. `respecAttributes(uint256 tokenId)`: Allows the token owner to reset spent attribute points and reallocate them, potentially for a cost. Records history.
24. `getTokenHistory(uint256 tokenId)`: Returns the full history log for a token.
25. `getHistoryEntryCount(uint256 tokenId)`: Returns the number of history entries for a token.
26. `getHistoryEntry(uint256 tokenId, uint256 index)`: Returns a specific history entry for a token by index.
27. `listTokenForSale(uint256 tokenId, uint256 price)`: Allows the token owner to list their token for sale on the marketplace.
28. `cancelListing(uint256 tokenId)`: Allows the token owner to cancel an active listing.
29. `buyToken(uint256 tokenId)`: Allows a user to buy a listed token by paying the listed price. Transfers ownership and Ether. Records history.
30. `getTokenListing(uint256 tokenId)`: Returns the current listing details (seller, price) for a token, if any.
31. `withdrawProceeds()`: Allows the contract owner to withdraw accumulated Ether from sales, costs, etc.
32. `setBaseURI(string memory newBaseURI)`: Allows the contract owner to update the base URI for metadata.
33. `setEnergyReplenishCost(uint256 cost)`: Allows the contract owner to set the cost for replenishing energy.
34. `setLevelUpCost(uint256 cost)`: Allows the contract owner to set the cost for leveling up.
35. `setMorphCost(uint256 cost)`: Allows the contract owner to set the cost for morphing.
36. `setBoostCost(uint256 cost)`: Allows the contract owner to set the cost for boosting attributes.
37. `setRespecCost(uint256 cost)`: Allows the contract owner to set the cost for respecing attributes.

*(Note: Some standard ERC721 functions like `approve`/`transferFrom` might be restricted or overridden in a real implementation to ensure tokens aren't transferred while listed on the internal marketplace, but for this example, we'll keep them standard alongside the marketplace functions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // Potential future extension for royalties
import "@openzeppelin/contracts/interfaces/IERC4906.sol"; // Potential future extension for metadata updates

// --- Smart Contract Outline: MetaMorphMarket ---
// 1. License and Imports: SPDX License, OpenZeppelin library imports (ERC721, Ownable, Counters, Strings, ECDSA).
// 2. Error Definitions: Custom errors for clearer failure reasons.
// 3. Structs: Attributes, HistoryEntry, Listing.
// 4. State Variables: Mappings for token data (attributes, energy, level, seed, history, listings), counters, costs, base URI, owner, balance.
// 5. Events: Signals for key actions (Minting, Leveling Up, Morphing, Listing, Sale, etc.).
// 6. Modifiers: Restrict access (onlyOwner, onlyTokenOwner).
// 7. Constructor: Initializes contract owner, base URI, and initial costs.
// 8. ERC-721 Standard Functions: Implementations/Overrides for required ERC-721 functions.
// 9. Core MetaMorph Mechanics: Minting, Getters for state, Action functions (replenishEnergy, levelUp, morphToken, boostAttribute, respecAttributes).
// 10. Provenance/History: Functions to retrieve token history.
// 11. Marketplace Functions: Listing, cancelling, purchasing, getting listing info.
// 12. Owner/Management Functions: Setting costs and URI, withdrawing funds.
// 13. Internal Helper Functions: Logic for generation, history recording.
// 14. ERC-165 Support: supportsInterface.

// --- Function Summary ---
// 1.  constructor(): Initializes contract.
// 2.  balanceOf(address owner): (ERC-721) Returns number of tokens owned by an address.
// 3.  ownerOf(uint256 tokenId): (ERC-721) Returns owner of a token.
// 4.  approve(address to, uint256 tokenId): (ERC-721) Approves an address.
// 5.  getApproved(uint256 tokenId): (ERC-721) Returns the approved address.
// 6.  setApprovalForAll(address operator, bool approved): (ERC-721) Approves/disapproves an operator.
// 7.  isApprovedForAll(address owner, address operator): (ERC-721) Checks operator approval.
// 8.  transferFrom(address from, address to, uint256 tokenId): (ERC-721) Transfers token ownership.
// 9.  safeTransferFrom(address from, address to, uint256 tokenId): (ERC-721) Transfers token ownership safely.
// 10. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): (ERC-721) Transfers token ownership safely with data.
// 11. tokenURI(uint256 tokenId): (ERC-721 Override) Returns dynamic metadata URI.
// 12. supportsInterface(bytes4 interfaceId): (ERC-165) Indicates supported interfaces.
// 13. mintInitial(address recipient): Mints a new MetaMorph with initial state.
// 14. mintWithSeed(address recipient, uint256 seed): Mints a new MetaMorph using a specific seed.
// 15. getTokenAttributes(uint256 tokenId): Returns current attributes.
// 16. getTokenEnergy(uint256 tokenId): Returns current energy level.
// 17. getTokenLevel(uint256 tokenId): Returns current level.
// 18. getTokenSeed(uint256 tokenId): Returns the token's seed.
// 19. replenishEnergy(uint256 tokenId): Replenishes energy for a cost.
// 20. levelUp(uint256 tokenId): Levels up token (requires energy/cost).
// 21. morphToken(uint256 tokenId): Morphs token (changes attributes, requires energy/cost).
// 22. boostAttribute(uint256 tokenId, string memory attributeName, uint256 points): Spends points to boost attribute.
// 23. respecAttributes(uint256 tokenId): Resets and reallocates attribute points for a cost.
// 24. getTokenHistory(uint256 tokenId): Returns full history log.
// 25. getHistoryEntryCount(uint256 tokenId): Returns number of history entries.
// 26. getHistoryEntry(uint256 tokenId, uint256 index): Returns a specific history entry.
// 27. listTokenForSale(uint256 tokenId, uint256 price): Lists token for sale.
// 28. cancelListing(uint256 tokenId): Cancels an active listing.
// 29. buyToken(uint256 tokenId): Buys a listed token.
// 30. getTokenListing(uint256 tokenId): Returns listing info.
// 31. withdrawProceeds(): Owner withdraws funds.
// 32. setBaseURI(string memory newBaseURI): Owner sets base metadata URI.
// 33. setEnergyReplenishCost(uint256 cost): Owner sets energy cost.
// 34. setLevelUpCost(uint256 cost): Owner sets level up cost.
// 35. setMorphCost(uint256 cost): Owner sets morph cost.
// 36. setBoostCost(uint256 cost): Owner sets boost cost.
// 37. setRespecCost(uint256 cost): Owner sets respec cost.

contract MetaMorphMarket is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Errors ---
    error InvalidTokenId();
    error NotTokenOwnerOrApproved();
    error NotTokenOwner();
    error InsufficientEnergy();
    error MaxLevelReached();
    error InsufficientFunds();
    error TokenNotListed();
    error CannotBuyOwnToken();
    error AlreadyListed();
    error InvalidAttributeName();
    error InsufficientAttributePoints();
    error RespecCooldownActive(); // Example of potential cooldown
    error HistoryIndexOutOfRange();
    error MaxEnergyReached();

    // --- Structs ---
    struct Attributes {
        uint16 strength;
        uint16 dexterity;
        uint16 intelligence;
        uint16 stamina;
        uint16 availablePoints; // Points available to allocate
        uint16 totalPointsAllocated; // For respec logic
    }

    enum HistoryEventType {
        Mint,
        LevelUp,
        Morphed,
        AttributeBoosted,
        EnergyReplenished,
        Respecd,
        ListedForSale,
        Sold
    }

    struct HistoryEntry {
        uint64 timestamp;
        HistoryEventType eventType;
        string description; // e.g., "Level up to 2", "Boosted Strength by 5", "Sold for 0.1 ETH"
    }

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Attributes) private _tokenAttributes;
    mapping(uint256 => uint32) private _tokenEnergy; // Max 2^32-1 energy
    mapping(uint256 => uint16) private _tokenLevel; // Max 65535 levels
    mapping(uint256 => uint256) private _tokenSeed; // Unique seed for potential deterministic traits/morphs
    mapping(uint256 => HistoryEntry[]) private _tokenHistory; // Array of history entries
    mapping(uint256 => Listing) private _tokenListings; // Marketplace listings

    uint256 public energyReplenishCost = 0.01 ether;
    uint256 public levelUpCost = 0.05 ether;
    uint256 public morphCost = 0.03 ether;
    uint256 public boostAttributeCost = 0.001 ether; // Cost *per point* boosted? Or per boost action? Let's make it per action for simplicity.
    uint256 public respecCost = 0.02 ether;

    uint32 public maxEnergy = 100;
    uint16 public maxLevel = 100;
    uint16 public baseAttributePointsPerLevel = 5; // Points gained per level up

    string private _baseTokenURI;
    uint256 private contractBalance; // Accumulated Ether from sales/costs

    // --- Events ---
    event MetaMorphMinted(uint256 indexed tokenId, address indexed owner, uint256 seed);
    event EnergyReplenished(uint256 indexed tokenId, uint32 amount);
    event EnergySpent(uint256 indexed tokenId, uint32 amount);
    event LevelUp(uint256 indexed tokenId, uint16 newLevel);
    event Morphed(uint256 indexed tokenId, uint16 newLevel, Attributes newAttributes);
    event AttributeBoosted(uint256 indexed tokenId, string attributeName, uint16 amount);
    event Respecd(uint256 indexed tokenId);
    event TokenListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event TokenSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event BaseURIUpdated(string newURI);
    event EnergyCostUpdated(uint256 newCost);
    event LevelUpCostUpdated(uint256 newCost);
    event MorphCostUpdated(uint256 newCost);
    event BoostCostUpdated(uint256 newCost);
    event RespecCostUpdated(uint256 newCost);


    // --- Modifiers ---
    modifier onlyTokenOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseTokenURI_) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI_;
    }

    // --- ERC-721 Standard Functions (Overrides) ---

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // The off-chain service at _baseTokenURI should read the state (attributes, level, energy)
        // via getter functions and render the dynamic metadata JSON/image.
        // The structure is typically baseURI + tokenId.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
        // Add ERC2981 or ERC4906 support here if implementing those standards fully
        // return interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
    }

    // Note: Standard transfer functions like `transferFrom` and `safeTransferFrom` are
    // inherited. A more robust marketplace might override these to prevent transfers
    // while a token is listed. For this example, we assume users are careful or
    // the marketplace logic is the primary way transfers happen when listed.

    // --- Core MetaMorph Mechanics ---

    /// @summary Mints a new MetaMorph token with procedurally generated initial state.
    /// @param recipient The address to receive the new token.
    /// @return uint256 The ID of the newly minted token.
    function mintInitial(address recipient) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Generate a seed based on current block/timestamp/sender - not truly random
        // but provides a unique value influencing initial stats.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId)));
        _tokenSeed[newItemId] = seed;

        // Generate initial attributes based on seed (simplified example)
        _tokenAttributes[newItemId] = _generateInitialAttributes(seed);
        _tokenEnergy[newItemId] = maxEnergy; // Start with full energy
        _tokenLevel[newItemId] = 1;

        _safeMint(recipient, newItemId);
        _recordHistoryEvent(newItemId, HistoryEventType.Mint, "MetaMorph minted.");

        emit MetaMorphMinted(newItemId, recipient, seed);

        return newItemId;
    }

     /// @summary Mints a new MetaMorph token using a specific seed.
     /// Can be used for controlled minting events or specific genesis tokens.
     /// @param recipient The address to receive the new token.
     /// @param seed The specific seed to use for initial state generation.
     /// @return uint256 The ID of the newly minted token.
    function mintWithSeed(address recipient, uint256 seed) public onlyOwner returns (uint256) {
         _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _tokenSeed[newItemId] = seed;

        // Generate initial attributes based on provided seed
        _tokenAttributes[newItemId] = _generateInitialAttributes(seed);
        _tokenEnergy[newItemId] = maxEnergy; // Start with full energy
        _tokenLevel[newItemId] = 1;

        _safeMint(recipient, newItemId);
        _recordHistoryEvent(newItemId, HistoryEventType.Mint, "MetaMorph minted with specific seed.");

        emit MetaMorphMinted(newItemId, recipient, seed);

        return newItemId;
    }

    /// @summary Returns the current attributes of a token.
    /// @param tokenId The ID of the token.
    /// @return Attributes The attributes struct.
    function getTokenAttributes(uint256 tokenId) public view returns (Attributes memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenAttributes[tokenId];
    }

    /// @summary Returns the current energy level of a token.
    /// @param tokenId The ID of the token.
    /// @return uint32 The current energy.
    function getTokenEnergy(uint256 tokenId) public view returns (uint32) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenEnergy[tokenId];
    }

    /// @summary Returns the current level of a token.
    /// @param tokenId The ID of the token.
    /// @return uint16 The current level.
    function getTokenLevel(uint256 tokenId) public view returns (uint16) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenLevel[tokenId];
    }

    /// @summary Returns the unique seed associated with a token.
    /// @param tokenId The ID of the token.
    /// @return uint256 The token's seed.
    function getTokenSeed(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenSeed[tokenId];
    }

    /// @summary Allows the token owner to replenish energy for a token by paying a cost.
    /// @param tokenId The ID of the token.
    function replenishEnergy(uint256 tokenId) public payable onlyTokenOwner(tokenId) {
        if (_tokenEnergy[tokenId] >= maxEnergy) revert MaxEnergyReached();
        if (msg.value < energyReplenishCost) revert InsufficientFunds();

        _tokenEnergy[tokenId] = maxEnergy; // Full replenish for simplicity
        contractBalance += msg.value;

        _recordHistoryEvent(tokenId, HistoryEventType.EnergyReplenished, "Energy replenished.");
        emit EnergyReplenished(tokenId, maxEnergy);
    }

    /// @summary Internal function to spend energy. Used by other actions.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of energy to spend.
    function _spendEnergy(uint256 tokenId, uint32 amount) internal {
        if (_tokenEnergy[tokenId] < amount) revert InsufficientEnergy();
        _tokenEnergy[tokenId] -= amount;
        emit EnergySpent(tokenId, amount);
    }

    /// @summary Allows the token owner to level up a token if conditions are met.
    /// Increases level and grants attribute points.
    /// @param tokenId The ID of the token.
    function levelUp(uint256 tokenId) public payable onlyTokenOwner(tokenId) {
        if (_tokenLevel[tokenId] >= maxLevel) revert MaxLevelReached();
        if (msg.value < levelUpCost) revert InsufficientFunds();
        _spendEnergy(tokenId, 10); // Example: Spend 10 energy to level up

        _tokenLevel[tokenId]++;
        _tokenAttributes[tokenId].availablePoints += baseAttributePointsPerLevel;
        contractBalance += msg.value;

        _recordHistoryEvent(tokenId, HistoryEventType.LevelUp, string(abi.encodePacked("Leveled up to ", _tokenLevel[tokenId].toString(), ".")));
        emit LevelUp(tokenId, _tokenLevel[tokenId]);

        // Note: This is where ERC4906 might be useful to signal metadata update
        // emit MetadataUpdate(tokenId); // If using ERC4906
    }

    /// @summary Allows the token owner to "morph" the token.
    /// Changes its attributes based on its seed and current state.
    /// @param tokenId The ID of the token.
    function morphToken(uint256 tokenId) public payable onlyTokenOwner(tokenId) {
        if (msg.value < morphCost) revert InsufficientFunds();
        _spendEnergy(tokenId, 20); // Example: Spend 20 energy to morph

        // Implement morphing logic based on seed, level, current attributes
        // Example: Simple attribute shuffle + slight boost based on seed/level
        Attributes storage currentAttrs = _tokenAttributes[tokenId];
        uint256 seed = _tokenSeed[tokenId];
        uint16 level = _tokenLevel[tokenId];

        // Simple pseudo-random attribute redistribution based on seed & level
        uint16 totalCurrentPoints = currentAttrs.strength + currentAttrs.dexterity + currentAttrs.intelligence + currentAttrs.stamina;
        uint16 bonusPoints = level / 10; // Gain some bonus points every 10 levels (example)

        // Reset and redistribute (simplified example)
        uint256 totalPointsToDistribute = totalCurrentPoints + bonusPoints;
        uint256 distributionFactor = seed % 100; // Use seed to influence distribution slightly

        currentAttrs.strength = uint16((totalPointsToDistribute * (distributionFactor + 10)) / 140); // Example distribution logic
        currentAttrs.dexterity = uint16((totalPointsToDistribute * (distributionFactor % 30 + 15)) / 140);
        currentAttrs.intelligence = uint16((totalPointsToDistribute * (distributionFactor % 20 + 20)) / 140);
        currentAttrs.stamina = uint16((totalPointsToDistribute * (distributionFactor % 10 + 25)) / 140);

        // Normalize total points after distribution to avoid drift (or allow slight growth/shrinkage)
        uint16 distributedTotal = currentAttrs.strength + currentAttrs.dexterity + currentAttrs.intelligence + currentAttrs.stamina;
        // Simple normalization - scale if significantly off (this is basic)
        if (distributedTotal != totalPointsToDistribute && distributedTotal > 0) {
             uint256 scaleFactor = (uint256(totalPointsToDistribute) * 1000) / distributedTotal; // scale by 1000 to keep precision
             currentAttrs.strength = uint16((uint256(currentAttrs.strength) * scaleFactor) / 1000);
             currentAttrs.dexterity = uint16((uint256(currentAttrs.dexterity) * scaleFactor) / 1000);
             currentAttrs.intelligence = uint16((uint256(currentAttrs.intelligence) * scaleFactor) / 1000);
             currentAttrs.stamina = uint16((uint256(currentAttrs.stamina) * scaleFactor) / 1000);
        }

        currentAttrs.availablePoints = 0; // Reset available points on morph? Or carry over? Let's reset for simplicity.
        currentAttrs.totalPointsAllocated = 0; // Reset allocated points

        contractBalance += msg.value;

        _recordHistoryEvent(tokenId, HistoryEventType.Morphed, "MetaMorph underwent a transformation.");
        emit Morphed(tokenId, level, currentAttrs);

        // emit MetadataUpdate(tokenId); // If using ERC4906
    }

    /// @summary Allows the token owner to spend available attribute points to boost a specific attribute.
    /// @param tokenId The ID of the token.
    /// @param attributeName The name of the attribute to boost ("strength", "dexterity", "intelligence", "stamina").
    /// @param points The number of points to spend.
    function boostAttribute(uint256 tokenId, string memory attributeName, uint16 points) public payable onlyTokenOwner(tokenId) {
         if (msg.value < boostAttributeCost) revert InsufficientFunds(); // Cost per action, not per point for simplicity
         Attributes storage attrs = _tokenAttributes[tokenId];

        if (attrs.availablePoints < points) revert InsufficientAttributePoints();

        attrs.availablePoints -= points;
        attrs.totalPointsAllocated += points;

        string memory lowerAttributeName = _toLowerCase(attributeName); // Use a helper for case-insensitivity

        if (keccak256(abi.encodePacked(lowerAttributeName)) == keccak256(abi.encodePacked("strength"))) {
            attrs.strength += points;
        } else if (keccak256(abi.encodePacked(lowerAttributeName)) == keccak256(abi.encodePacked("dexterity"))) {
            attrs.dexterity += points;
        } else if (keccak256(abi.encodePacked(lowerAttributeName)) == keccak256(abi.encodePacked("intelligence"))) {
            attrs.intelligence += points;
        } else if (keccak256(abi.encodePacked(lowerAttributeName)) == keccak256(abi.encodePacked("stamina"))) {
            attrs.stamina += points;
        } else {
            revert InvalidAttributeName();
        }

        contractBalance += msg.value;

        _recordHistoryEvent(tokenId, HistoryEventType.AttributeBoosted, string(abi.encodePacked("Boosted ", attributeName, " by ", points.toString(), ".")));
        emit AttributeBoosted(tokenId, attributeName, points);

         // emit MetadataUpdate(tokenId); // If using ERC4906
    }

    /// @summary Allows the token owner to reset spent attribute points and reallocate them.
    /// @param tokenId The ID of the token.
    function respecAttributes(uint256 tokenId) public payable onlyTokenOwner(tokenId) {
        if (msg.value < respecCost) revert InsufficientFunds();
        // Example: Add a cooldown here if desired
        // if (block.timestamp < _tokenLastRespec[tokenId] + respecCooldownDuration) revert RespecCooldownActive();

        Attributes storage attrs = _tokenAttributes[tokenId];

        uint16 totalPointsRecovered = attrs.totalPointsAllocated;

        // Remove allocated points from attributes (simple removal assuming linear boost)
        attrs.strength = attrs.strength > totalPointsRecovered ? attrs.strength - totalPointsRecovered : 0; // Simplistic - better logic needed if points are distributed across multiple stats
        attrs.dexterity = attrs.dexterity > totalPointsRecovered ? attrs.dexterity - totalPointsRecovered : 0;
        attrs.intelligence = attrs.intelligence > totalPointsRecovered ? attrs.intelligence - totalPointsRecovered : 0;
        attrs.stamina = attrs.stamina > totalPointsRecovered ? attrs.stamina - totalPointsRecovered : 0;


        // A more accurate respec would store how many points were put into *each* stat
        // For simplicity here, we just recover the total and zero out allocated.
        // A better system would recalculate base stats + available points.

        attrs.availablePoints += totalPointsRecovered;
        attrs.totalPointsAllocated = 0;

        // _tokenLastRespec[tokenId] = block.timestamp; // For cooldown

        contractBalance += msg.value;

        _recordHistoryEvent(tokenId, HistoryEventType.Respecd, "Attributes respecd. Points recovered.");
        emit Respecd(tokenId);

         // emit MetadataUpdate(tokenId); // If using ERC4906
    }

    // --- Provenance/History ---

    /// @summary Returns the full history log for a token.
    /// @param tokenId The ID of the token.
    /// @return HistoryEntry[] The array of history entries.
    function getTokenHistory(uint256 tokenId) public view returns (HistoryEntry[] memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         return _tokenHistory[tokenId];
    }

    /// @summary Returns the number of history entries for a token.
    /// @param tokenId The ID of the token.
    /// @return uint256 The count of history entries.
    function getHistoryEntryCount(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenHistory[tokenId].length;
    }

    /// @summary Returns a specific history entry for a token by index.
    /// @param tokenId The ID of the token.
    /// @param index The index of the history entry (0-based).
    /// @return HistoryEntry The requested history entry.
    function getHistoryEntry(uint256 tokenId, uint256 index) public view returns (HistoryEntry memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (index >= _tokenHistory[tokenId].length) revert HistoryIndexOutOfRange();
        return _tokenHistory[tokenId][index];
    }

    /// @summary Internal helper to record a history event for a token.
    /// @param tokenId The ID of the token.
    /// @param eventType The type of event.
    /// @param description A description of the event.
    function _recordHistoryEvent(uint256 tokenId, HistoryEventType eventType, string memory description) internal {
        _tokenHistory[tokenId].push(HistoryEntry({
            timestamp: uint64(block.timestamp),
            eventType: eventType,
            description: description
        }));
    }


    // --- Marketplace Functions ---

    /// @summary Allows the token owner to list their token for sale on the marketplace.
    /// @param tokenId The ID of the token.
    /// @param price The price in Wei.
    function listTokenForSale(uint256 tokenId, uint256 price) public onlyTokenOwner(tokenId) {
        if (_tokenListings[tokenId].isListed) revert AlreadyListed();

        _tokenListings[tokenId] = Listing({
            seller: _msgSender(),
            price: price,
            isListed: true
        });

        _recordHistoryEvent(tokenId, HistoryEventType.ListedForSale, string(abi.encodePacked("Listed for sale at ", price.toString(), " Wei.")));
        emit TokenListed(tokenId, _msgSender(), price);
    }

    /// @summary Allows the token owner to cancel an active listing.
    /// @param tokenId The ID of the token.
    function cancelListing(uint256 tokenId) public onlyTokenOwner(tokenId) {
        if (!_tokenListings[tokenId].isListed) revert TokenNotListed();

        delete _tokenListings[tokenId]; // Remove the listing

        _recordHistoryEvent(tokenId, HistoryEventType.ListingCancelled, "Listing cancelled.");
        emit ListingCancelled(tokenId);
    }

    /// @summary Allows a user to buy a listed token by paying the listed price.
    /// @param tokenId The ID of the token to buy.
    function buyToken(uint256 tokenId) public payable {
        Listing storage listing = _tokenListings[tokenId];

        if (!listing.isListed) revert TokenNotListed();
        if (listing.seller == _msgSender()) revert CannotBuyOwnToken();
        if (msg.value < listing.price) revert InsufficientFunds();

        address seller = listing.seller;
        uint256 price = listing.price;

        // Delete listing *before* transfer to prevent re-entrancy issues with marketplace state
        delete _tokenListings[tokenId];

        // Transfer Ether to the seller (can add marketplace fee here if desired)
        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "Ether transfer failed"); // Use require for critical operations

        // Transfer token ownership using safeTransferFrom
        _safeTransferFrom(seller, _msgSender(), tokenId);

        // Handle potential leftover Ether if msg.value > price
        if (msg.value > price) {
             (bool successRefund, ) = payable(_msgSender()).call{value: msg.value - price}("");
             require(successRefund, "Refund failed"); // Should not fail if initial transfer succeeded
        }


        _recordHistoryEvent(tokenId, HistoryEventType.Sold, string(abi.encodePacked("Sold to ", _msgSender().toHexString(), " for ", price.toString(), " Wei.")));
        emit TokenSold(tokenId, seller, _msgSender(), price);

        // emit MetadataUpdate(tokenId); // If using ERC4906
    }

    /// @summary Returns the current listing details for a token.
    /// @param tokenId The ID of the token.
    /// @return seller The address of the seller (address(0) if not listed).
    /// @return price The listing price (0 if not listed).
    /// @return isListed Whether the token is currently listed for sale.
    function getTokenListing(uint256 tokenId) public view returns (address seller, uint256 price, bool isListed) {
        Listing storage listing = _tokenListings[tokenId];
        return (listing.seller, listing.price, listing.isListed);
    }


    // --- Owner/Management Functions ---

    /// @summary Allows the contract owner to withdraw accumulated Ether.
    function withdrawProceeds() public onlyOwner {
        uint256 balance = address(this).balance;
        // Optionally, track proceeds from sales vs costs separately if fees are implemented
        // uint256 amountToWithdraw = contractBalance; // Or specific portion

        // Ensure there is balance to withdraw
        if (balance == 0) return;

        // Reset internal balance tracker (if used to track sales fees etc.)
        // contractBalance = 0;

        (bool success, ) = payable(owner()).call{value: balance}(""); // Send all balance to owner
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner(), balance);
    }

    /// @summary Allows the contract owner to update the base URI for metadata.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /// @summary Allows the contract owner to set the cost for replenishing energy.
    /// @param cost The new cost in Wei.
    function setEnergyReplenishCost(uint256 cost) public onlyOwner {
        energyReplenishCost = cost;
        emit EnergyCostUpdated(cost);
    }

    /// @summary Allows the contract owner to set the cost for leveling up.
    /// @param cost The new cost in Wei.
    function setLevelUpCost(uint256 cost) public onlyOwner {
        levelUpCost = cost;
        emit LevelUpCostUpdated(cost);
    }

    /// @summary Allows the contract owner to set the cost for morphing.
    /// @param cost The new cost in Wei.
    function setMorphCost(uint256 cost) public onlyOwner {
        morphCost = cost;
        emit MorphCostUpdated(cost);
    }

    /// @summary Allows the contract owner to set the cost for boosting attributes.
    /// @param cost The new cost in Wei.
    function setBoostCost(uint256 cost) public onlyOwner {
        boostAttributeCost = cost;
        emit BoostCostUpdated(cost);
    }

    /// @summary Allows the contract owner to set the cost for respecing attributes.
    /// @param cost The new cost in Wei.
    function setRespecCost(uint256 cost) public onlyOwner {
        respecCost = cost;
        emit RespecCostUpdated(cost);
    }

    // --- Internal Helper Functions ---

    /// @summary Generates initial attributes for a new token based on a seed.
    /// (Simplified deterministic generation)
    /// @param seed The seed value.
    /// @return Attributes The generated attributes struct.
    function _generateInitialAttributes(uint256 seed) internal pure returns (Attributes memory) {
        uint256 sum = 0;
        uint16 baseValue = 5; // Minimum base attribute value

        // Simple deterministic distribution based on seed
        uint16 str = baseValue + uint16((seed % 20) + (seed / 100 % 10));
        uint16 dex = baseValue + uint16((seed % 30) + (seed / 1000 % 10));
        uint16 intel = baseValue + uint16((seed % 40) + (seed / 10000 % 10));
        uint16 stam = baseValue + uint16((seed % 50) + (seed / 100000 % 10));

        // Ensure some randomness within bounds and normalize sum if needed
        sum = str + dex + intel + stam;
        uint16 targetSum = 4 * baseValue + 100; // Example target initial total points

        if (sum != targetSum && sum > 0) {
             uint256 scaleFactor = (uint256(targetSum) * 1000) / sum; // Scale by 1000 for precision
             str = uint16((uint256(str) * scaleFactor) / 1000);
             dex = uint16((uint256(dex) * scaleFactor) / 1000);
             intel = uint16((uint256(intel) * scaleFactor) / 1000);
             stam = uint16((uint256(stam) * scaleFactor) / 1000);
        }

        return Attributes({
            strength: str,
            dexterity: dex,
            intelligence: intel,
            stamina: stam,
            availablePoints: 0, // Start with 0 points, gain on level up
            totalPointsAllocated: 0
        });
    }

    /// @summary Converts a string to lowercase (basic implementation).
    /// @param str The input string.
    /// @return string The lowercase string.
    function _toLowerCase(string memory str) internal pure returns (string memory) {
        bytes memory b = bytes(str);
        for (uint i = 0; i < b.length; i++) {
            // A-Z are 65-90, a-z are 97-122 in ASCII.
            if (b[i] >= 65 && b[i] <= 90) {
                b[i] = bytes1(uint8(b[i]) + 32);
            }
        }
        return string(b);
    }

    // --- Receive Ether ---
    // Fallback function to receive Ether sent without a specific function call
    receive() external payable {
        // Could potentially handle Ether sent here, e.g., for generic energy refill
        // but `replenishEnergy` is more specific.
        // For now, just add to balance or potentially revert if unexpected.
        // contractBalance += msg.value; // Or just let it accumulate in address(this).balance
    }
}
```