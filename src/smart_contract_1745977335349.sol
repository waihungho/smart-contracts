Okay, here is a Solidity smart contract concept called `HyperForge`. It combines several advanced concepts: dynamic NFTs with on-chain state, complex crafting/forging mechanics, time-based decay/mutation, resource management (an ERC-20 token), and a mutable global environment affecting all assets.

It is designed to be unique and not a direct copy of common open-source templates like standard ERC-20/ERC-721 implementations (though it will internally manage state akin to them) or simple staking/yield farms.

---

**Contract Name:** HyperForge

**Concept:** A decentralized forging and evolution platform where unique digital artifacts ("Glyphs") are created as dynamic NFTs. Glyphs have complex on-chain properties that can change through crafting ("Forging"), resource infusion ("Infusion"), and are subject to environmental effects ("Mutation Cycle") governed by a global "Aura". A native ERC-20 token ("Essence") acts as the primary resource for interactions.

**Advanced Concepts & Features:**

1.  **Dynamic NFTs:** Glyph properties are stored on-chain and mutable via contract logic.
2.  **Complex Crafting:** The `forgeGlyphs` function takes multiple input NFTs and produces a new one with properties derived from the inputs, involving burning the inputs.
3.  **Resource Management:** An integrated ERC-20 token (`Essence`) is required for various operations (minting, forging, infusion, stabilization, aura changes).
4.  **Time-Based Mechanics:** Glyphs can decay or mutate over time based on block progression, requiring maintenance.
5.  **Global Mutable Environment (Aura):** A contract-wide state (`AuraType`) affects the outcome of actions like infusion and the rate/type of decay/mutation.
6.  **On-chain Simulation:** The `applyEnvironmentalEffect` function simulates the passage of time on Glyph properties.
7.  **Provenance Tracking:** Forged Glyphs track their parent Glyphs.
8.  **Pseudo-Randomness:** Used for mutation outcomes (based on block hash and other factors - *Note: Secure randomness requires Oracles in production*).
9.  **Modular Infusion:** Different functions or logic could exist for targeting specific properties (represented here by a general `infuseGlyph`).

**Outline:**

1.  **State Variables:**
    *   ERC-721 core data (`_tokenOwners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`, `_totalSupplyNFT`).
    *   ERC-20 core data (`_essenceBalances`, `_essenceAllowances`, `_totalSupplyEssence`).
    *   Glyph data (`_glyphData` mapping to `GlyphProperties` struct).
    *   Global Forge State (`_currentAura`, `_auraPoolEssence`, `_mutationRateBasisPoints`, `_decayRateBasisPoints`, `_lastAuraChangeBlock`).
    *   Counters (`_nextTokenId`, `_totalEssenceSupply`).
    *   Owner/Admin (`_owner`).

2.  **Structs & Enums:**
    *   `GlyphProperties`: Defines the dynamic state of a Glyph (power, purity, affinity, stability, creation block, last cycle block, origin, parent IDs, infusion total).
    *   `OriginType`: Enum { Minted, Forged }.
    *   `AuraType`: Enum { Stable, Volatile, Growth, Decay, Chaotic }.

3.  **Events:**
    *   Standard ERC-721/ERC-20 events (Transfer, Approval, ApprovalForAll).
    *   Custom events (GlyphMinted, GlyphsForged, GlyphInfused, EnvironmentalEffectApplied, GlyphStabilized, GlyphDeconstructed, AuraChanged, EssenceContributedToPool).

4.  **Modifiers:**
    *   `onlyOwner`: Restricts access to contract owner.
    *   `isGlyphOwnerOrApproved`: Checks if caller is owner or approved for a specific Glyph.
    *   `payerHasEnoughEssence`: Checks if the caller has enough Essence balance.
    *   `glyphExists`: Checks if a given token ID is valid.

5.  **Functions:**
    *   **ERC-721 Standard (7 functions):** `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`.
    *   **ERC-20 Standard (6 functions):** `balanceOf`, `transfer`, `transferFrom`, `approve`, `allowance`, `totalSupply`.
    *   **HyperForge Core Logic (12+ functions):**
        *   `mintGlyph`: Create a new Glyph NFT, consume Essence.
        *   `forgeGlyphs`: Combine multiple Glyphs into a new one, consume Essence, burn inputs.
        *   `infuseGlyph`: Use Essence to boost Glyph properties based on Aura.
        *   `applyEnvironmentalEffect`: Trigger mutation/decay based on time and Aura.
        *   `stabilizeGlyph`: Use Essence to counteract negative environmental effects.
        *   `deconstructGlyph`: Burn a Glyph, reclaim some Essence.
        *   `updateAura`: Owner/governance changes the global Aura (costs Essence from pool).
        *   `contributeEssenceToAuraPool`: Users add Essence to the Aura pool.
        *   `getGlyphProperties`: View function for a Glyph's state.
        *   `getForgeState`: View function for global Aura state.
        *   `getAuraPoolBalance`: View function for the Aura pool.
        *   Helper/Internal functions used by the above (`_mintNFT`, `_burnNFT`, `_transferNFT`, `_safeMintNFT`, `_transferEssence`, `_burnEssence`, `_mintEssence`, `_calculateForgedProperties`, `_applyAuraEffects`, `_generatePseudoRandom`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// State Variables:
// - ERC-721 core mappings (_tokenOwners, _balances, approvals) & _totalSupplyNFT
// - ERC-20 core mappings (_essenceBalances, _essenceAllowances) & _totalSupplyEssence
// - Glyph data (_glyphData mapping to GlyphProperties struct)
// - Global Forge State (_currentAura, _auraPoolEssence, _mutationRateBasisPoints, _decayRateBasisPoints, _lastAuraChangeBlock)
// - Counters (_nextTokenId, _totalEssenceSupply)
// - Owner/Admin (_owner)
// Structs & Enums:
// - GlyphProperties
// - OriginType
// - AuraType
// Events:
// - Standard ERC-721/ERC-20 events
// - Custom events (GlyphMinted, GlyphsForged, GlyphInfused, EnvironmentalEffectApplied, GlyphStabilized, GlyphDeconstructed, AuraChanged, EssenceContributedToPool)
// Modifiers:
// - onlyOwner
// - isGlyphOwnerOrApproved
// - payerHasEnoughEssence
// - glyphExists
// Functions:
// - ERC-721 Standard (7)
// - ERC-20 Standard (6)
// - HyperForge Core Logic (12+)
//   - mintGlyph
//   - forgeGlyphs
//   - infuseGlyph
//   - applyEnvironmentalEffect
//   - stabilizeGlyph
//   - deconstructGlyph
//   - updateAura
//   - contributeEssenceToAuraPool
//   - getGlyphProperties (view)
//   - getForgeState (view)
//   - getAuraPoolBalance (view)
//   - Internal helper functions

// --- Function Summary (Total: 26) ---

// ERC-721 Standard Functions (7):
// 1. balanceOf(address owner): Returns the number of NFTs owned by `owner`.
// 2. ownerOf(uint256 tokenId): Returns the owner of the NFT `tokenId`.
// 3. transferFrom(address from, address to, uint256 tokenId): Transfers `tokenId` from `from` to `to`.
// 4. approve(address to, uint256 tokenId): Grants approval to `to` to transfer `tokenId`.
// 5. getApproved(uint256 tokenId): Returns the approved address for `tokenId`.
// 6. setApprovalForAll(address operator, bool approved): Grants/revokes operator approval for all owner's tokens.
// 7. isApprovedForAll(address owner, address operator): Checks if `operator` is approved for all of `owner`'s tokens.

// ERC-20 Standard Functions (6):
// 8. balanceOf(address account): Returns the Essence balance of `account`.
// 9. transfer(address to, uint256 amount): Transfers `amount` of Essence from caller to `to`.
// 10. transferFrom(address from, address to, uint256 amount): Transfers `amount` of Essence from `from` to `to` using allowance.
// 11. approve(address spender, uint256 amount): Sets allowance for `spender` to spend caller's Essence.
// 12. allowance(address owner, address spender): Returns the allowance of `spender` over `owner`'s Essence.
// 13. totalSupply(): Returns the total supply of Essence tokens.

// HyperForge Core Logic Functions (13+):
// 14. mintGlyph(address recipient, uint256 initialEssenceCost): Mints a new Glyph NFT to `recipient` with initial properties. Costs Essence from caller.
// 15. forgeGlyphs(uint256[] calldata inputTokenIds, address recipient, uint256 forgingEssenceCost): Combines multiple input Glyphs, burns them, creates a new one for `recipient` with derived properties. Costs Essence from caller.
// 16. infuseGlyph(uint256 tokenId, uint256 essenceAmount): Uses `essenceAmount` to boost properties of `tokenId`, effect depends on Aura. Costs Essence from caller.
// 17. applyEnvironmentalEffect(uint256 tokenId): Applies decay or mutation to `tokenId` based on time elapsed and current Aura. Can be triggered by anyone.
// 18. stabilizeGlyph(uint256 tokenId, uint256 essenceAmount): Uses `essenceAmount` to mitigate negative effects of the next environmental cycle on `tokenId`. Costs Essence from caller.
// 19. deconstructGlyph(uint256 tokenId): Burns `tokenId` and refunds a portion of invested Essence back to the owner.
// 20. updateAura(uint8 newAuraType, uint256 requiredEssenceFromPool): Owner/governance changes the global Aura state, consuming Essence from the community pool.
// 21. contributeEssenceToAuraPool(uint256 amount): Users transfer Essence to the contract's Aura pool.
// 22. getGlyphProperties(uint256 tokenId): View function to get the current dynamic properties of a Glyph.
// 23. getForgeState(): View function to get the current global Aura state and related parameters.
// 24. getAuraPoolBalance(): View function to get the amount of Essence in the Aura pool.
// 25. getGlyphOrigin(uint256 tokenId): View function to see if a Glyph was Minted or Forged, and its parent IDs if Forged.
// 26. _generatePseudoRandom(uint256 seed): Internal helper for pseudo-randomness (used in mutation/infusion outcomes). Note: Not secure for critical actions.

// --- End Summary ---


contract HyperForge {
    // --- ERC-721 State ---
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _totalSupplyNFT;
    string public constant name = "HyperForge Glyph";
    string public constant symbol = "HFG";

    // --- ERC-20 State (Essence) ---
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;
    uint256 private _totalEssenceSupply;
    string public constant essenceName = "Forge Essence";
    string public constant essenceSymbol = "ESS";
    uint8 public constant essenceDecimals = 18;

    // --- HyperForge State ---
    struct GlyphProperties {
        uint256 power; // Affects forging outcome, maybe combat (conceptual)
        uint256 purity; // Affects infusion efficiency, resistance to decay/mutation
        uint256 affinity; // Affects interaction with specific Aura types
        uint256 stability; // Direct resistance to decay/mutation
        uint256 creationBlock;
        uint256 lastEnvironmentalCycleBlock; // Last block environmental effects were applied
        OriginType originType;
        uint256[] parentGlyphs; // IDs of input Glyphs if originType is Forged
        uint256 totalInfusionEssence; // Total Essence ever infused into this Glyph
    }

    enum OriginType { Minted, Forged }

    enum AuraType { Stable, Volatile, Growth, Decay, Chaotic }
    AuraType public _currentAura;
    uint256 public _auraPoolEssence; // Essence contributed by users to potentially influence Aura
    uint256 public _mutationRateBasisPoints; // 10000 = 100% chance per cycle (conceptual)
    uint256 public _decayRateBasisPoints; // 10000 = 100% decay severity per cycle (conceptual)
    uint256 public _lastAuraChangeBlock;

    mapping(uint256 => GlyphProperties) private _glyphData;
    uint256 private _nextTokenId; // Counter for new Glyph IDs

    address private immutable _owner; // Contract deployer, maybe later replaced by a DAO

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC721
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721

    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20 (Essence) - Note: Signature clash with ERC721, differentiate by param types
    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC20 (Essence)

    event GlyphMinted(uint256 indexed tokenId, address indexed recipient, uint256 initialEssenceCost, uint256 initialPower, uint256 initialPurity, uint256 initialAffinity, uint256 initialStability);
    event GlyphsForged(uint256[] indexed inputTokenIds, uint256 indexed newTokenId, address indexed recipient, uint256 forgingEssenceCost);
    event GlyphInfused(uint256 indexed tokenId, address indexed infuser, uint256 essenceAmount, AuraType indexed currentAura);
    event EnvironmentalEffectApplied(uint256 indexed tokenId, uint256 blockNumber, AuraType indexed currentAura, bool mutated, bool decayed);
    event GlyphStabilized(uint256 indexed tokenId, address indexed stablizer, uint256 essenceAmount);
    event GlyphDeconstructed(uint256 indexed tokenId, address indexed owner, uint256 reclaimedEssence);
    event AuraChanged(AuraType indexed newAuraType, address indexed changer, uint256 essenceSpentFromPool);
    event EssenceContributedToPool(address indexed contributor, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "HF: Not owner");
        _;
    }

    modifier glyphExists(uint256 tokenId) {
        require(_tokenOwners[tokenId] != address(0), "HF: Glyph does not exist");
        _;
    }

    modifier isGlyphOwnerOrApproved(uint256 tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "HF: Not owner or approved"
        );
        _;
    }

    modifier payerHasEnoughEssence(uint256 amount) {
        require(_essenceBalances[msg.sender] >= amount, "HF: Insufficient essence");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialEssenceSupplyForOwner) {
        _owner = msg.sender;
        // Initial mint of Essence to the deployer for starting the system
        _mintEssence(msg.sender, initialEssenceSupplyForOwner);
        _totalEssenceSupply = initialEssenceSupplyForOwner;

        // Set initial Aura state and parameters
        _currentAura = AuraType.Stable;
        _mutationRateBasisPoints = 100; // 1% base chance
        _decayRateBasisPoints = 50; // 0.5% base severity
        _lastAuraChangeBlock = block.number;
        _auraPoolEssence = 0;
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- ERC-721 Implementations ---

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "HF721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "HF721: owner query for nonexistent token");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        // Public transfer requires sender to be owner or approved
        require(_isApprovedOrOwner(msg.sender, tokenId), "HF721: transfer caller is not owner nor approved");
        _transferNFT(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Implicitly checks if token exists
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "HF721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_tokenOwners[tokenId] != address(0), "HF721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Internal ERC-721 Helpers
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transferNFT(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "HF721: transfer from incorrect owner");
        require(to != address(0), "HF721: transfer to the zero address");

        // Clear approvals for the transferring token
        _tokenApprovals[tokenId] = address(0);

        _balances[from]--;
        _balances[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mintNFT(address to, uint256 tokenId) internal {
        require(to != address(0), "HF721: mint to the zero address");
        require(!_exists(tokenId), "HF721: token already minted");

        _balances[to]++;
        _tokenOwners[tokenId] = to;
        _totalSupplyNFT++;

        emit Transfer(address(0), to, tokenId);
    }

     function _burnNFT(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Implicitly checks if token exists

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);
        _operatorApprovals[owner][msg.sender] = false; // Revoke operator for caller if set for this token? (Or just clear token approval) - Standard is just token/all approval. Let's just clear token.

        _balances[owner]--;
        _tokenOwners[tokenId] = address(0); // Set owner to zero address
        _totalSupplyNFT--;

        emit Transfer(owner, address(0), tokenId);
    }


    // --- ERC-20 Implementations (Essence) ---

    function balanceOf(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    function transfer(address to, uint256 amount) public payerHasEnoughEssence(amount) returns (bool) {
        _transferEssence(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public payerHasEnoughEssence(amount) returns (bool) {
        uint256 currentAllowance = _essenceAllowances[from][msg.sender];
        require(currentAllowance >= amount, "HF20: insufficient allowance");
        unchecked {
            _essenceAllowances[from][msg.sender] = currentAllowance - amount;
        }
        _transferEssence(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _essenceAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalEssenceSupply;
    }

    // Internal ERC-20 Helpers
    function _transferEssence(address from, address to, uint256 amount) internal {
        require(from != address(0), "HF20: transfer from the zero address");
        require(to != address(0), "HF20: transfer to the zero address");

        _essenceBalances[from] = _essenceBalances[from] - amount;
        _essenceBalances[to] = _essenceBalances[to] + amount;

        // Use explicit signature for overloaded event
        emit Transfer(from, to, amount);
    }

    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "HF20: mint to the zero address");
        _totalEssenceSupply = _totalEssenceSupply + amount;
        _essenceBalances[account] = _essenceBalances[account] + amount;
         // Use explicit signature for overloaded event
        emit Transfer(address(0), account, amount);
    }

    function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "HF20: burn from the zero address");
        _essenceBalances[account] = _essenceBalances[account] - amount;
        _totalEssenceSupply = _totalEssenceSupply - amount;
         // Use explicit signature for overloaded event
        emit Transfer(account, address(0), amount);
    }

    // --- HyperForge Core Logic ---

    // 14. Mint a new Glyph
    function mintGlyph(address recipient, uint256 initialEssenceCost)
        public
        payerHasEnoughEssence(initialEssenceCost)
    {
        require(recipient != address(0), "HF: Mint to zero address");
        require(initialEssenceCost > 0, "HF: Mint cost must be positive");

        _burnEssence(msg.sender, initialEssenceCost);

        uint256 tokenId = _nextTokenId++;

        // Assign initial properties (simplified logic, can be more complex)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId)));
        uint256 rand = _generatePseudoRandom(seed);

        _glyphData[tokenId] = GlyphProperties({
            power: (rand % 50) + 1,      // Base power 1-50
            purity: (rand % 50) + 1,     // Base purity 1-50
            affinity: (rand % 50) + 1,   // Base affinity 1-50
            stability: (rand % 50) + 1,  // Base stability 1-50
            creationBlock: block.number,
            lastEnvironmentalCycleBlock: block.number,
            originType: OriginType.Minted,
            parentGlyphs: new uint256[](0),
            totalInfusionEssence: 0
        });

        _mintNFT(recipient, tokenId);

        emit GlyphMinted(
            tokenId,
            recipient,
            initialEssenceCost,
            _glyphData[tokenId].power,
            _glyphData[tokenId].purity,
            _glyphData[tokenId].affinity,
            _glyphData[tokenId].stability
        );
    }

    // 15. Forge Glyphs into a new one
    function forgeGlyphs(uint256[] calldata inputTokenIds, address recipient, uint256 forgingEssenceCost)
        public
        payerHasEnoughEssence(forgingEssenceCost)
    {
        require(inputTokenIds.length >= 2, "HF: Need at least 2 glyphs to forge");
        require(recipient != address(0), "HF: Forge to zero address");

        // Check ownership/approval and burn input glyphs
        uint256 totalParentInfusionEssence = 0;
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 inputTokenId = inputTokenIds[i];
            require(_exists(inputTokenId), "HF: Input glyph does not exist");
            require(_isApprovedOrOwner(msg.sender, inputTokenId), "HF: Not owner/approved for input glyph");

            // Accumulate total infused essence from parents
            totalParentInfusionEssence += _glyphData[inputTokenId].totalInfusionEssence;

            _burnNFT(inputTokenId);
            // Optionally delete glyph data after burning, but keeping history might be useful
            // delete _glyphData[inputTokenId];
        }

        _burnEssence(msg.sender, forgingEssenceCost);

        uint256 newTokenId = _nextTokenId++;

        // Calculate new properties based on inputs (simplified average + boost/randomness)
        (uint256 avgPower, uint256 avgPurity, uint256 avgAffinity, uint256 avgStability) = _calculateForgedProperties(inputTokenIds);

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, inputTokenIds)));
        uint256 rand = _generatePseudoRandom(seed);

        _glyphData[newTokenId] = GlyphProperties({
            power: avgPower + (rand % 10), // Avg + small random boost
            purity: avgPurity + (rand % 10),
            affinity: avgAffinity + (rand % 10),
            stability: avgStability + (rand % 10),
            creationBlock: block.number,
            lastEnvironmentalCycleBlock: block.number,
            originType: OriginType.Forged,
            parentGlyphs: inputTokenIds, // Record parents
            totalInfusionEssence: totalParentInfusionEssence / inputTokenIds.length // Carry over some parent infusion value
        });

        _mintNFT(recipient, newTokenId);

        emit GlyphsForged(inputTokenIds, newTokenId, recipient, forgingEssenceCost);
    }

    // 16. Infuse Glyph with Essence
    function infuseGlyph(uint256 tokenId, uint256 essenceAmount)
        public
        glyphExists(tokenId)
        isGlyphOwnerOrApproved(tokenId)
        payerHasEnoughEssence(essenceAmount)
    {
        require(essenceAmount > 0, "HF: Infusion amount must be positive");

        _burnEssence(msg.sender, essenceAmount);

        GlyphProperties storage glyph = _glyphData[tokenId];
        glyph.totalInfusionEssence += essenceAmount;

        // Apply infusion effect based on Aura (simplified logic)
        uint256 boost = essenceAmount / 100; // Base boost per 100 essence
        uint256 efficiencyMultiplier = 1;

        if (_currentAura == AuraType.Growth) {
            efficiencyMultiplier = 2; // Double boost in Growth Aura
        } else if (_currentAura == AuraType.Decay) {
             efficiencyMultiplier = 0; // No boost in Decay Aura
        } else if (_currentAura == AuraType.Chaotic) {
            // Random outcome in chaotic aura
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, essenceAmount)));
            uint256 rand = _generatePseudoRandom(seed);
            efficiencyMultiplier = rand % 3; // Can be 0x, 1x, or 2x boost
        }
        // Stable and Volatile have base efficiencyMultiplier = 1

        uint256 actualBoost = boost * efficiencyMultiplier;

        glyph.power += actualBoost;
        glyph.purity += actualBoost;
        glyph.affinity += actualBoost;
        glyph.stability += actualBoost;

        emit GlyphInfused(tokenId, msg.sender, essenceAmount, _currentAura);
    }

    // 17. Apply Environmental Effect (Mutation/Decay)
    function applyEnvironmentalEffect(uint256 tokenId)
        public
        glyphExists(tokenId)
    {
        GlyphProperties storage glyph = _glyphData[tokenId];
        uint256 blocksSinceLastCycle = block.number - glyph.lastEnvironmentalCycleBlock;
        require(blocksSinceLastCycle > 0, "HF: Environmental effect already applied this block");

        glyph.lastEnvironmentalCycleBlock = block.number;

        // Calculate potential mutation/decay based on blocks elapsed, rates, and Aura
        uint256 decayChance = _decayRateBasisPoints * blocksSinceLastCycle / 10000; // Simplified
        uint256 mutationChance = _mutationRateBasisPoints * blocksSinceLastCycle / 10000; // Simplified

         // Adjust chances based on Purity, Stability, and Aura
        decayChance = (decayChance * 100) / (100 + glyph.purity + glyph.stability); // Purity & Stability reduce decay chance
        mutationChance = (mutationChance * 100) / (100 + glyph.purity + glyph.stability); // Purity & Stability reduce mutation chance

        if (_currentAura == AuraType.Decay) {
            decayChance = decayChance * 2; // Double decay chance in Decay Aura
        } else if (_currentAura == AuraType.Growth) {
            mutationChance = mutationChance * 2; // Double mutation chance in Growth Aura
        } else if (_currentAura == AuraType.Chaotic) {
            decayChance = decayChance * 150 / 100; // 1.5x decay
            mutationChance = mutationChance * 150 / 100; // 1.5x mutation
        }


        bool mutated = false;
        bool decayed = false;

        // Use block hash + token ID + block number for pseudo-randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, block.number)));
        uint256 rand = _generatePseudoRandom(seed);

        // Apply decay
        if (rand % 10000 < decayChance) {
            decayed = true;
            uint256 decayAmount = rand % 10 + 1; // Decay by 1-10 points (simplified)
            glyph.power = glyph.power > decayAmount ? glyph.power - decayAmount : 0;
            glyph.purity = glyph.purity > decayAmount ? glyph.purity - decayAmount : 0;
            glyph.affinity = glyph.affinity > decayAmount ? glyph.affinity - decayAmount : 0;
            glyph.stability = glyph.stability > decayAmount ? glyph.stability - decayAmount : 0;
             // Cannot go below 0, ensured by `> decayAmount ?` check
        }

        // Apply mutation (independent roll)
        if (rand % 10000 < mutationChance) {
             mutated = true;
             // Mutation changes one random property significantly (simplified)
             uint256 propertyToMutate = (rand / 10000) % 4; // 0=power, 1=purity, 2=affinity, 3=stability
             int256 mutationAmount = int256((rand / 40000) % 20) - 10; // Change by -10 to +9

             if (propertyToMutate == 0) {
                 glyph.power = uint256(int256(glyph.power) + mutationAmount > 0 ? int256(glyph.power) + mutationAmount : 0);
             } else if (propertyToMutate == 1) {
                 glyph.purity = uint256(int256(glyph.purity) + mutationAmount > 0 ? int256(glyph.purity) + mutationAmount : 0);
             } else if (propertyToMutate == 2) {
                 glyph.affinity = uint256(int256(glyph.affinity) + mutationAmount > 0 ? int256(glyph.affinity) + mutationAmount : 0);
             } else { // propertyToMutate == 3
                 glyph.stability = uint256(int256(glyph.stability) + mutationAmount > 0 ? int256(glyph.stability) + mutationAmount : 0);
             }
        }


        emit EnvironmentalEffectApplied(tokenId, block.number, _currentAura, mutated, decayed);
    }

    // 18. Stabilize Glyph with Essence
    function stabilizeGlyph(uint256 tokenId, uint256 essenceAmount)
        public
        glyphExists(tokenId)
        isGlyphOwnerOrApproved(tokenId)
        payerHasEnoughEssence(essenceAmount)
    {
        require(essenceAmount > 0, "HF: Stabilization amount must be positive");

        _burnEssence(msg.sender, essenceAmount);

        GlyphProperties storage glyph = _glyphData[tokenId];

        // Increase stability temporarily or add a buffer against decay/mutation
        // Simplified: add stability directly, capped
        uint256 stabilityBoost = essenceAmount / 50; // 1 stability per 50 essence
        glyph.stability += stabilityBoost;
        // Cap stability at a reasonable value to prevent infinite growth
        if (glyph.stability > 500) glyph.stability = 500; // Example cap

        emit GlyphStabilized(tokenId, msg.sender, essenceAmount);
    }

    // 19. Deconstruct Glyph
    function deconstructGlyph(uint256 tokenId)
        public
        glyphExists(tokenId)
        isGlyphOwnerOrApproved(tokenId)
    {
        GlyphProperties storage glyph = _glyphData[tokenId];

        // Calculate essence to return (simplified: 50% of total infused essence)
        uint256 reclaimedEssence = glyph.totalInfusionEssence / 2;

        address owner = ownerOf(tokenId); // Get owner before burning

        // Burn the Glyph
        _burnNFT(tokenId);
        // Delete the glyph properties data
        delete _glyphData[tokenId];

        // Mint reclaimed Essence to the owner
        if (reclaimedEssence > 0) {
             _mintEssence(owner, reclaimedEssence);
        }

        emit GlyphDeconstructed(tokenId, owner, reclaimedEssence);
    }

    // 20. Update Global Aura
    function updateAura(uint8 newAuraTypeUint, uint256 requiredEssenceFromPool)
        public
        onlyOwner // Could be replaced by DAO/governance logic
    {
        AuraType newAuraType = AuraType(newAuraTypeUint);
        // Basic validation for enum value
        require(uint8(newAuraType) <= uint8(AuraType.Chaotic), "HF: Invalid Aura type");
        require(_auraPoolEssence >= requiredEssenceFromPool, "HF: Not enough essence in Aura pool");

        _burnEssence(address(this), requiredEssenceFromPool); // Burn from the contract's pool balance

        _currentAura = newAuraType;
        _lastAuraChangeBlock = block.number;

        // Adjust rates based on new Aura (simplified)
        if (newAuraType == AuraType.Stable) {
            _mutationRateBasisPoints = 50;
            _decayRateBasisPoints = 20;
        } else if (newAuraType == AuraType.Volatile) {
            _mutationRateBasisPoints = 200;
            _decayRateBasisPoints = 100;
        } else if (newAuraType == AuraType.Growth) {
            _mutationRateBasisPoints = 150;
            _decayRateBasisPoints = 10; // Less decay, more mutation
        } else if (newAuraType == AuraType.Decay) {
             _mutationRateBasisPoints = 50;
            _decayRateBasisPoints = 150; // More decay, less mutation
        } else if (newAuraType == AuraType.Chaotic) {
            _mutationRateBasisPoints = 300;
            _decayRateBasisPoints = 300;
        }

        emit AuraChanged(newAuraType, msg.sender, requiredEssenceFromPool);
    }

    // 21. Contribute Essence to the Aura Pool
    function contributeEssenceToAuraPool(uint256 amount)
        public
        payerHasEnoughEssence(amount)
    {
        require(amount > 0, "HF: Contribution amount must be positive");
        _transferEssence(msg.sender, address(this), amount);
        _auraPoolEssence += amount;
        emit EssenceContributedToPool(msg.sender, amount);
    }


    // --- View Functions ---

    // 22. Get Glyph Properties
    function getGlyphProperties(uint256 tokenId)
        public
        view
        glyphExists(tokenId)
        returns (uint256 power, uint256 purity, uint256 affinity, uint256 stability, uint256 creationBlock, uint256 lastEnvironmentalCycleBlock, uint256 totalInfusionEssence)
    {
        GlyphProperties storage glyph = _glyphData[tokenId];
        return (
            glyph.power,
            glyph.purity,
            glyph.affinity,
            glyph.stability,
            glyph.creationBlock,
            glyph.lastEnvironmentalCycleBlock,
            glyph.totalInfusionEssence
        );
    }

    // 23. Get Forge State
    function getForgeState()
        public
        view
        returns (AuraType currentAura, uint256 auraPoolEssence, uint256 mutationRateBasisPoints, uint256 decayRateBasisPoints, uint256 lastAuraChangeBlock)
    {
        return (
            _currentAura,
            _auraPoolEssence,
            _mutationRateBasisPoints,
            _decayRateBasisPoints,
            _lastAuraChangeBlock
        );
    }

    // 24. Get Aura Pool Balance
    function getAuraPoolBalance() public view returns (uint256) {
        return _auraPoolEssence;
    }

    // 25. Get Glyph Origin and Parents
    function getGlyphOrigin(uint256 tokenId)
        public
        view
        glyphExists(tokenId)
        returns (OriginType originType, uint256[] memory parentGlyphs)
    {
         GlyphProperties storage glyph = _glyphData[tokenId];
         return (glyph.originType, glyph.parentGlyphs);
    }


    // --- Internal Helper Functions ---

    // Internal helper for forging property calculation (simplified averaging)
    function _calculateForgedProperties(uint256[] calldata inputTokenIds)
        internal
        view
        returns (uint256 avgPower, uint256 avgPurity, uint256 avgAffinity, uint256 avgStability)
    {
        uint256 totalPower = 0;
        uint256 totalPurity = 0;
        uint256 totalAffinity = 0;
        uint256 totalStability = 0;

        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            // Check existence again just to be safe, though forgeGlyphs already does
            if (_exists(tokenId)) {
                GlyphProperties storage glyph = _glyphData[tokenId];
                totalPower += glyph.power;
                totalPurity += glyph.purity;
                totalAffinity += glyph.affinity;
                totalStability += glyph.stability;
            }
        }

        uint256 count = inputTokenIds.length;
        avgPower = totalPower / count;
        avgPurity = totalPurity / count;
        avgAffinity = totalAffinity / count;
        avgStability = totalStability / count;

        return (avgPower, avgPurity, avgAffinity, avgStability);
    }

    // Internal helper for pseudo-random number generation
    // WARNING: This is NOT cryptographically secure and should not be used
    // for high-value randomness requirements in a production environment.
    // Use Chainlink VRF or similar Oracle solutions for secure randomness.
    // 26. Pseudo-Random Generator
    function _generatePseudoRandom(uint256 seed) internal view returns (uint256) {
        // Mix block variables with the provided seed
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, seed)));
        // Further mix with a potential previous block hash if available
        if (block.number > 0) {
            rand = uint256(keccak256(abi.encodePacked(rand, blockhash(block.number - 1))));
        }
        return rand;
    }

    // --- Additional ERC-721/ERC-20 standard functions implemented implicitly or via helpers ---
    // For a fully compliant ERC-721/ERC-20, you'd add metadata functions (name, symbol, tokenURI)
    // and ERC165 supportsInterface. These are omitted for brevity as the request focused on core logic count.

    // ERC721: tokenURI(uint256 tokenId) - Omitted, would return metadata URI
    // ERC721: supportsInterface(bytes4 interfaceId) - Omitted, for ERC165 compliance

    // ERC20: name() - Public constant already declared
    // ERC20: symbol() - Public constant already declared
    // ERC20: decimals() - Public constant already declared
}
```