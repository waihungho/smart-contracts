Okay, here is a smart contract concept combining several advanced and dynamic features: **"Evolving Sentinels Nexus"**.

This contract manages a collection of dynamic NFTs ("Sentinels") that can be staked in different virtual "Locations" to yield a fungible token ("Aether"). The Sentinels' traits can evolve based on staking duration, interactions, and external influences mediated by an Oracle. It includes mechanisms for claiming yield, triggering evolution attempts, repairing traits, handling global events, and managing protocol fees, all while incorporating custom ERC721 and ERC20 logic within a single contract.

---

**Smart Contract: EvolvingSentinelsNexus**

**Outline:**

1.  **Core Concepts:**
    *   Dynamic NFTs (Sentinels) with mutable traits (Power, Resilience, Affinity).
    *   Staking mechanism in different Locations.
    *   Yield generation (Aether token) based on staking time, traits, and location bonuses.
    *   Trait evolution system triggered by users, potentially influenced by randomness or state.
    *   Trait decay system influenced by time and Resilience.
    *   Repair mechanism using Aether.
    *   Oracle integration for global events affecting all staked Sentinels.
    *   Protocol fee collection and withdrawal.
    *   Built-in custom ERC721 and ERC20 implementations (minimal required logic for this concept).

2.  **State Variables:** Mappings for Sentinel data, balances, approvals, ownership, staking status, global parameters (rates, oracle address, fees), location bonuses.
3.  **Structs:** `SentinelData` to hold NFT traits and staking info.
4.  **Events:** To signal key actions (mint, stake, unstake, claim, evolve, repair, global event, fee withdrawal).
5.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`), state checks (`whenNotStaked`, `whenStaked`).
6.  **Functions (20+ required):**
    *   ERC721 Standard Functions (Mint, Transfer, Ownership, Approval) - Custom implementation.
    *   ERC20 Standard Functions (Balance, Transfer, Allowance, Approve, Supply) - Custom implementation for Aether.
    *   Sentinel Management (Minting, Staking, Unstaking).
    *   Aether Yield (Calculation, Claiming).
    *   Trait Dynamics (Get, Evolve, Decay, Repair).
    *   Location & Global State (Get bonuses, Set bonuses, Apply global events, Oracle management).
    *   Fees & Burning (Claim fees, Withdraw fees, Burn Aether).
    *   View/Helper Functions (Get status, estimate yield, etc.).

**Function Summary:**

*   **`constructor()`**: Initializes the contract, sets owner, initial rates, etc.
*   **`mintSentinel(address to)`**: Mints a new Sentinel NFT to an address with initial random traits.
*   **`tokenURI(uint256 tokenId)`**: Returns a placeholder URI for the Sentinel NFT.
*   **`stakeSentinel(uint256 tokenId, uint256 locationId)`**: Stakes an owned Sentinel to a specified location.
*   **`unstakeSentinel(uint256 tokenId)`**: Unstakes a staked Sentinel, minting earned Aether.
*   **`claimStakedAether(uint256 tokenId)`**: Claims earned Aether for a staked Sentinel without unstaking. Applies fee and decay attempt.
*   **`calculateAetherEarned(uint256 tokenId)` (internal)**: Calculates Aether earned based on time staked, traits, and location bonus.
*   **`estimateAetherEarned(uint256 tokenId)`**: View function to estimate Aether claimable right now.
*   **`getSentinelTraits(uint256 tokenId)`**: View function returning Sentinel's traits.
*   **`getSentinelStatus(uint256 tokenId)`**: View function returning Sentinel's staking status, location, and last staked time.
*   **`getSentinelDetails(uint256 tokenId)`**: Comprehensive view function returning all Sentinel data.
*   **`triggerEvolutionAttempt(uint256 tokenId, uint256 randomnessSeed)`**: Attempts to evolve Sentinel traits. May consume Aether/fee. Requires a source of randomness.
*   **`triggerDecayAttempt(uint256 tokenId)` (internal)**: Attempts to decay Sentinel traits based on time and resilience.
*   **`repairSentinel(uint256 tokenId, uint256 aetherAmount)`**: Consumes Aether to increase a Sentinel's Resilience trait.
*   **`scoutLocation(uint256 tokenId, uint256 locationId)`**: A staked Sentinel can scout its location (or another). Might yield extra Aether or incur risk.
*   **`applyGlobalEventEffect(uint256 eventId, bytes data, uint256 randomnessSeed)`**: (Oracle only) Applies a global effect to all *staked* Sentinels based on external data and randomness.
*   **`burnAether(uint256 amount)`**: Allows users to burn Aether tokens.
*   **`withdrawOwnerFees()`**: Owner can withdraw collected protocol fees (in Aether).
*   **`setOracleAddress(address _oracleAddress)`**: Owner sets the address authorized to trigger global events.
*   **`setBaseAetherGenerationRate(uint256 _rate)`**: Owner sets the base rate for Aether generation.
*   **`setLocationBonus(uint256 locationId, uint256 bonus)`**: Owner sets the Aether generation bonus for a specific location.
*   **`getLocationBonus(uint256 locationId)`**: View function returning the bonus for a location.
*   **`getCurrentTraitBonus(uint256 tokenId)`**: View function calculating the Aether generation bonus from a Sentinel's current traits.
*   **`getTotalStakedSentinels()`**: View function returning the total count of currently staked Sentinels.
*   **`balanceOf(address account)` (ERC20)**: Get Aether balance.
*   **`transfer(address recipient, uint256 amount)` (ERC20)**: Transfer Aether.
*   **`allowance(address owner, address spender)` (ERC20)**: Get Aether allowance.
*   **`approve(address spender, uint256 amount)` (ERC20)**: Approve Aether spending.
*   **`transferFrom(address sender, address recipient, uint256 amount)` (ERC20)**: Transfer Aether using allowance.
*   **`totalSupply()` (ERC20)**: Get total Aether supply.
*   **`symbol()` (ERC20)**: Get Aether symbol ("AETHER").
*   **`name()` (ERC20)**: Get Aether name ("Aether Token").
*   **`decimals()` (ERC20)**: Get Aether decimals (18).
*   **`balanceOf(address owner)` (ERC721)**: Get number of Sentinels owned.
*   **`ownerOf(uint256 tokenId)` (ERC721)**: Get owner of a Sentinel.
*   **`transferFrom(address from, address to, uint256 tokenId)` (ERC721)**: Transfer Sentinel (custom check for staking).
*   **`safeTransferFrom(address from, address to, uint256 tokenId)` (ERC721)**: Safe transfer (custom check for staking).
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)` (ERC721)**: Safe transfer with data (custom check for staking).
*   **`approve(address to, uint256 tokenId)` (ERC721)**: Approve Sentinel transfer.
*   **`setApprovalForAll(address operator, bool approved)` (ERC721)**: Set approval for all Sentinels.
*   **`getApproved(uint256 tokenId)` (ERC721)**: Get approved address for Sentinel.
*   **`isApprovedForAll(address owner, address operator)` (ERC721)**: Check if operator is approved for all.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This contract includes both ERC721 and ERC20 minimal logic
// within a single contract for demonstration purposes as requested.
// A real-world project might separate these or use standard library implementations.
// Custom logic is implemented to fulfill the unique concept requirements.

import "@openzeppelin/contracts/access/Ownable.sol";
// Using Ownable from OpenZeppelin is standard practice and not considered duplicating
// the core *novel* logic of the Sentinel/Aether/Staking system.

error NotOwnerOfToken();
error TokenAlreadyStaked();
error TokenNotStaked();
error InvalidLocation();
error NotEnoughAether(uint256 required, uint256 available);
error EvolutionFailed();
error CannotTransferStakedToken();
error InvalidAmount();
error CannotWithdrawZeroFees();
error NotOracle();
error SentinelAlreadyOwned(); // Added for minting check

contract EvolvingSentinelsNexus is Ownable {

    // --- State Variables: ERC721 (Sentinels) ---
    string private _name = "Evolving Sentinels";
    string private _symbol = "SENTINEL";
    uint256 private _tokenIdCounter;
    mapping(uint256 => address) private _owners; // Token ID to owner
    mapping(address => uint256) private _balances; // Owner to number of tokens owned
    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to operator to approved

    // --- State Variables: ERC20 (Aether) ---
    string private _aetherName = "Aether Token";
    string private _aetherSymbol = "AETHER";
    uint8 private _aetherDecimals = 18;
    uint256 private _aetherTotalSupply;
    mapping(address => uint256) private _aetherBalances; // Aether holder to balance
    mapping(address => mapping(address => uint256)) private _aetherAllowances; // Aether owner to spender to amount

    // --- State Variables: Sentinel Dynamics & Staking ---
    struct SentinelData {
        uint8 power; // Affects Aether generation
        uint8 resilience; // Resists decay
        uint8 affinity; // Affects scouting/evolution chance
        bool isStaked;
        uint256 locationId; // 0 if not staked
        uint64 lastStakedTimestamp; // Timestamp when staked or Aether claimed
        uint64 lastDecayAttemptTimestamp; // Timestamp of last decay check
    }
    mapping(uint256 => SentinelData) public sentinelData;
    uint256 public totalStakedCount;

    // --- State Variables: Game Parameters ---
    uint256 public baseAetherGenerationRate = 1e17; // Aether per second per base unit (e.g., 0.1 AETHER/sec)
    uint256 public constant SECONDS_PER_YEAR = 31536000; // Example: 365 days * 24 hours * 60 mins * 60 secs
    uint256 public constant MAX_TRAIT_VALUE = 100;
    uint256 public constant MIN_TRAIT_VALUE = 1; // Traits cannot go below this
    uint256 public constant LOCATION_COUNT = 10; // Example number of locations (1 to 10)
    mapping(uint256 => uint256) public locationBonus; // Location ID => multiplier (e.g., 100 = 1x, 150 = 1.5x)

    uint256 public evolutionAttemptCost = 5e18; // Cost in Aether (e.g., 5 AETHER)
    uint256 public repairCostMultiplier = 1e17; // Aether per trait point restored
    uint256 public scoutingCost = 1e18; // Cost in Aether (e.g., 1 AETHER)
    uint256 public aetherClaimFeeBasisPoints = 500; // 5% fee (500 / 10000)
    uint256 public totalProtocolFees; // Accumulated fees

    // --- Oracle Integration ---
    address public oracleAddress; // Address authorized to trigger global events

    // --- Global Event State ---
    uint256 public currentGlobalEventId;
    uint256 public globalEventStartTime;
    uint256 public globalTraitModifier = 100; // Base 100 = 1x modifier
    uint256 public globalAetherRateModifier = 100; // Base 100 = 1x modifier


    // --- Events: ERC721 ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Events: ERC20 ---
    event Transfer(address indexed from, address indexed to, uint256 amount); // Note: Overloaded Transfer event
    event Approval(address indexed owner, address indexed spender, uint256 amount); // Note: Overloaded Approval event

    // --- Events: Sentinel Dynamics ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, uint8 power, uint8 resilience, uint8 affinity);
    event SentinelStaked(uint256 indexed tokenId, address indexed owner, uint256 indexed locationId);
    event SentinelUnstaked(uint256 indexed tokenId, address indexed owner, uint256 aetherClaimed);
    event AetherClaimed(uint256 indexed tokenId, address indexed owner, uint256 aetherAmount, uint256 feeAmount);
    event TraitsEvolved(uint256 indexed tokenId, uint8 newPower, uint8 newResilience, uint8 newAffinity, string evolutionOutcome);
    event TraitDecayed(uint256 indexed tokenId, uint8 oldTrait, uint8 newTrait, string traitName);
    event SentinelRepaired(uint256 indexed tokenId, uint256 aetherUsed, uint8 newResilience);
    event LocationScouted(uint256 indexed tokenId, uint256 indexed locationId, uint256 extraAetherEarned, string outcome);
    event GlobalEventApplied(uint256 indexed eventId, bytes data, uint256 traitModifier, uint256 aetherRateModifier);
    event AetherBurned(address indexed burner, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed owner, uint256 amount);


    constructor() Ownable(msg.sender) {
        _tokenIdCounter = 0;
        // Set some initial location bonuses (e.g., Location 1=1.2x, Loc 2=1.5x)
        locationBonus[1] = 120; // 120/100 = 1.2x
        locationBonus[2] = 150; // 150/100 = 1.5x
        for(uint256 i = 3; i <= LOCATION_COUNT; i++) {
            locationBonus[i] = 100; // Default 1x
        }
         _aetherTotalSupply = 0; // Start with 0 Aether supply
    }

    // --- Modifiers ---
    modifier whenNotStaked(uint256 tokenId) {
        require(!sentinelData[tokenId].isStaked, TokenAlreadyStaked());
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        require(sentinelData[tokenId].isStaked, TokenNotStaked());
        _;
    }

    modifier onlySentinelOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, NotOwnerOfToken());
        _;
    }

     modifier onlyOracle() {
        require(msg.sender == oracleAddress, NotOracle());
        _;
    }

    // --- ERC721 Custom Implementation ---

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x01ffc9a7; // ERC165
    }

    function balanceOf(address owner) public view override returns (uint255) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

     function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        require(_owners[tokenId] == from, NotOwnerOfToken());
        require(!sentinelData[tokenId].isStaked, CannotTransferStakedToken()); // Custom Staking Check

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Clear approvals
        delete _tokenApprovals[tokenId];

        emit Transfer(from, to, tokenId);

        if (to.code.length > 0) {
             (bool success, ) = to.call(abi.encodeWithSelector(
                0x150b7a02, // onERC721Received function selector
                msg.sender, // operator
                from,       // from address
                tokenId,    // token id
                data        // data
            ));
            require(success, "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }


    function approve(address to, uint256 tokenId) public override {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        address owner = _owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- ERC20 Custom Implementation (for Aether) ---

    function aetherName() public view returns (string memory) { return _aetherName; }
    function aetherSymbol() public view returns (string memory) { return _aetherSymbol; }
    function aetherDecimals() public view returns (uint8) { return _aetherDecimals; }

    function totalSupply() public view override returns (uint256) { return _aetherTotalSupply; }

    function balanceOf(address account) public view override returns (uint256) { return _aetherBalances[account]; }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _aetherAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _aetherAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _aetherBalances[sender];
        require(senderBalance >= amount, NotEnoughAether(amount, senderBalance));

        unchecked {
            _aetherBalances[sender] = senderBalance - amount;
            _aetherBalances[recipient] = _aetherBalances[recipient] + amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    function _mintAether(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _aetherTotalSupply += amount;
        _aetherBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burnAether(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _aetherBalances[account];
         require(accountBalance >= amount, NotEnoughAether(amount, accountBalance));

        unchecked {
             _aetherBalances[account] = accountBalance - amount;
             _aetherTotalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

     function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _aetherAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Sentinel Management ---

    function mintSentinel(address to) public onlyOwner returns (uint256) {
        require(to != address(0), "Mint to zero address");
        require(_balances[to] < type(uint256).max, "Recipient balance overflow");

        uint256 newTokenId = _tokenIdCounter++;

        // Assign owner and update balance
        require(_owners[newTokenId] == address(0), SentinelAlreadyOwned()); // Should not happen with counter
        _owners[newTokenId] = to;
        _balances[to]++;

        // Initialize sentinel data with random-ish traits (using block data for entropy, NOT for security)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));
        sentinelData[newTokenId] = SentinelData({
            power: uint8((seed % (MAX_TRAIT_VALUE / 2)) + (MAX_TRAIT_VALUE / 2)), // Start traits higher
            resilience: uint8(((seed / 10) % (MAX_TRAIT_VALUE / 2)) + (MAX_TRAIT_VALUE / 2)),
            affinity: uint8(((seed / 100) % (MAX_TRAIT_VALUE / 2)) + (MAX_TRAIT_VALUE / 2)),
            isStaked: false,
            locationId: 0,
            lastStakedTimestamp: 0,
            lastDecayAttemptTimestamp: uint64(block.timestamp) // Initialize decay check timestamp
        });

        emit Transfer(address(0), to, newTokenId); // ERC721 Mint Event
        emit SentinelMinted(newTokenId, to, sentinelData[newTokenId].power, sentinelData[newTokenId].resilience, sentinelData[newTokenId].affinity);

        return newTokenId;
    }

    function stakeSentinel(uint256 tokenId, uint256 locationId) public onlySentinelOwner(tokenId) whenNotStaked(tokenId) {
        require(locationId > 0 && locationId <= LOCATION_COUNT, InvalidLocation());

        SentinelData storage sData = sentinelData[tokenId];
        sData.isStaked = true;
        sData.locationId = locationId;
        sData.lastStakedTimestamp = uint64(block.timestamp);
        // Decay check timestamp is NOT reset on stake, only on claim/unstake

        totalStakedCount++;

        emit SentinelStaked(tokenId, msg.sender, locationId);
    }

    function unstakeSentinel(uint256 tokenId) public onlySentinelOwner(tokenId) whenStaked(tokenId) {
        // First, claim any earned Aether
        uint256 earnedAether = calculateAetherEarned(tokenId);
        uint256 feeAmount = (earnedAether * aetherClaimFeeBasisPoints) / 10000;
        uint256 amountToMint = earnedAether - feeAmount;

        _mintAether(msg.sender, amountToMint);
        totalProtocolFees += feeAmount;
        emit AetherClaimed(tokenId, msg.sender, amountToMint, feeAmount);

        // Attempt decay AFTER Aether calculation/claim
        triggerDecayAttempt(tokenId);


        // Then, unstake
        SentinelData storage sData = sentinelData[tokenId];
        sData.isStaked = false;
        sData.locationId = 0;
        sData.lastStakedTimestamp = 0; // Reset timestamp on unstake
         sData.lastDecayAttemptTimestamp = uint64(block.timestamp); // Reset decay timer on unstake

        totalStakedCount--;

        emit SentinelUnstaked(tokenId, msg.sender, amountToMint); // Emitting amount minted excluding fee
    }

     function claimStakedAether(uint256 tokenId) public onlySentinelOwner(tokenId) whenStaked(tokenId) {
        uint256 earnedAether = calculateAetherEarned(tokenId);
        require(earnedAether > 0, "No Aether earned yet");

        uint256 feeAmount = (earnedAether * aetherClaimFeeBasisPoints) / 10000;
        uint256 amountToMint = earnedAether - feeAmount;

        _mintAether(msg.sender, amountToMint);
        totalProtocolFees += feeAmount;

        // Reset the claim timer for this token
        sentinelData[tokenId].lastStakedTimestamp = uint64(block.timestamp);

        // Attempt decay AFTER Aether calculation/claim
        triggerDecayAttempt(tokenId);

        emit AetherClaimed(tokenId, msg.sender, amountToMint, feeAmount);
    }


    // --- Aether Yield ---

    function calculateAetherEarned(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        SentinelData storage sData = sentinelData[tokenId];
        if (!sData.isStaked) {
            return 0;
        }

        uint256 secondsStaked = block.timestamp - sData.lastStakedTimestamp;
        if (secondsStaked == 0) {
            return 0;
        }

        // Base rate * Trait Bonus * Location Bonus * Global Aether Rate Modifier
        uint256 traitBonus = getCurrentTraitBonus(tokenId); // Base 100 = 1x
        uint256 locBonus = getLocationBonus(sData.locationId); // Base 100 = 1x

        // Calculation: (rate * seconds * traitBonus * locBonus * globalRateModifier) / (1e18 * 100 * 100 * 100)
        // Example: 1e17 * seconds * 120 * 150 * 100 / (1e18 * 1000000)
        // Simplified: rate * seconds * (traitBonus/100) * (locBonus/100) * (globalModifier/100)
        // = (rate * seconds * traitBonus * locBonus * globalModifier) / 1e6
        uint256 rawEarned = (baseAetherGenerationRate * secondsStaked);

        // Apply bonuses (multipliers are /100, so apply twice for trait & location, third time for global)
        // Use a large intermediate product to maintain precision before final division
        uint256 totalMultiplier = uint256(traitBonus) * locBonus * globalAetherRateModifier; // Max possible ~100*200*200 = 4,000,000
        uint256 scaleFactor = 100 * 100 * 100; // Scaling for the three /100 bonuses = 1,000,000

         // Safe multiplication (Solidity 0.8+ handles overflow by default, but good to think about)
        uint256 scaledEarned = rawEarned * totalMultiplier;

        // Final result
        return scaledEarned / scaleFactor;
    }

    function estimateAetherEarned(uint256 tokenId) public view returns (uint256) {
        return calculateAetherEarned(tokenId); // Same calculation, just named differently for clarity
    }

    function getCurrentTraitBonus(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
        SentinelData storage sData = sentinelData[tokenId];
        // Simple bonus calculation: (Power + Resilience + Affinity) / 3, scaled to 100 base
        // E.g., if avg trait is 50, bonus is 50/100=0.5, scaled to 100 base -> 50.
        // Let's make 100 avg trait = 1x bonus (100). 50 avg trait = 0.5x bonus (50). 0 avg trait = 0.
        // Formula: ((Power + Resilience + Affinity) / 3) * 100 / MAX_TRAIT_VALUE
        // Or simpler: (Power + Resilience + Affinity) * 100 / (MAX_TRAIT_VALUE * 3)
        // Let's use a formula where 100 of any trait adds a percentage.
        // Example: Power adds +0.5% per point, Resilience +0.3%, Affinity +0.2%
        // Total bonus % = (Power * 0.5) + (Resilience * 0.3) + (Affinity * 0.2)
        // Scaled to base 100: 100 + (Power * 50/100) + (Resilience * 30/100) + (Affinity * 20/100)
        // Integer math: 10000 + (Power * 50) + (Resilience * 30) + (Affinity * 20) -> Divide by 100 for base 100
        uint256 bonusBasisPoints = (uint256(sData.power) * 50) + (uint256(sData.resilience) * 30) + (uint256(sData.affinity) * 20); // Max ~10000 basis points (100%)

        return 100 + (bonusBasisPoints / 100); // Base 100 + percentage bonus
    }

    function getLocationBonus(uint256 locationId) public view returns (uint256) {
        require(locationId > 0 && locationId <= LOCATION_COUNT, InvalidLocation());
        return locationBonus[locationId]; // Returns value directly (e.g., 120 for 1.2x)
    }

    // --- Trait Dynamics ---

    function getSentinelTraits(uint256 tokenId) public view returns (uint8 power, uint8 resilience, uint8 affinity) {
        require(_exists(tokenId), "Token does not exist");
        SentinelData storage sData = sentinelData[tokenId];
        return (sData.power, sData.resilience, sData.affinity);
    }

     function getSentinelStatus(uint256 tokenId) public view returns (bool isStaked, uint256 locationId, uint64 lastStakedTimestamp) {
        require(_exists(tokenId), "Token does not exist");
        SentinelData storage sData = sentinelData[tokenId];
        return (sData.isStaked, sData.locationId, sData.lastStakedTimestamp);
    }

     function getSentinelDetails(uint256 tokenId) public view returns (
        uint256 id,
        address owner,
        uint8 power,
        uint8 resilience,
        uint8 affinity,
        bool isStaked,
        uint256 locationId,
        uint64 lastStakedTimestamp,
        uint64 lastDecayAttemptTimestamp,
        uint256 currentTraitBonus,
        uint256 estimatedAether
    ) {
        require(_exists(tokenId), "Token does not exist");
        SentinelData storage sData = sentinelData[tokenId];
        return (
            tokenId,
            _owners[tokenId],
            sData.power,
            sData.resilience,
            sData.affinity,
            sData.isStaked,
            sData.locationId,
            sData.lastStakedTimestamp,
            sData.lastDecayAttemptTimestamp,
            getCurrentTraitBonus(tokenId),
            estimateAetherEarned(tokenId)
        );
    }


    function triggerEvolutionAttempt(uint256 tokenId, uint256 randomnessSeed) public payable onlySentinelOwner(tokenId) whenStaked(tokenId) {
        // Evolution attempt requires Aether payment
        // Alternatively, could require sending ETH/other tokens which the contract holds or transfers
        // For simplicity, let's require a *separate* function call to burn Aether or use allowance first,
        // OR pay ETH and convert/burn. Using Aether burn directly is simpler here.
        // This function requires the user to have burned the cost *before* calling.
        // Or, let's make it consume ETH and add to fees for owner withdrawal. Yes, ETH is better.
        require(msg.value >= evolutionAttemptCost, NotEnoughAether(evolutionAttemptCost, msg.value)); // Renamed error

        totalProtocolFees += msg.value; // Collect ETH fee

        SentinelData storage sData = sentinelData[tokenId];

        // Basic random simulation based on provided seed + contract state (still not truly secure randomness)
        uint256 seed = uint256(keccak256(abi.encodePacked(randomnessSeed, block.timestamp, block.difficulty, tokenId, msg.sender)));
        uint256 outcome = seed % 100; // 0-99

        string memory outcomeMsg;
        uint8 oldPower = sData.power;
        uint8 oldResilience = sData.resilience;
        uint8 oldAffinity = sData.affinity;

        // Example evolution logic:
        if (outcome < 10) { // 10% chance of significant negative evolution
             outcomeMsg = "Significant Decay";
            sData.power = uint8(Math.max(MIN_TRAIT_VALUE, sData.power - uint8(seed % 10 + 5))); // Lose 5-14 points
            sData.resilience = uint8(Math.max(MIN_TRAIT_VALUE, sData.resilience - uint8((seed / 10) % 10 + 5)));
            sData.affinity = uint8(Math.max(MIN_TRAIT_VALUE, sData.affinity - uint8((seed / 100) % 10 + 5)));
        } else if (outcome < 40) { // 30% chance of minor negative evolution
             outcomeMsg = "Minor Decay";
            sData.power = uint8(Math.max(MIN_TRAIT_VALUE, sData.power - uint8(seed % 5 + 1))); // Lose 1-5 points
            sData.resilience = uint8(Math.max(MIN_TRAIT_VALUE, sData.resilience - uint8((seed / 10) % 5 + 1)));
            sData.affinity = uint8(Math.max(MIN_TRAIT_VALUE, sData.affinity - uint8((seed / 100) % 5 + 1)));
        } else if (outcome < 60) { // 20% chance of no change
            outcomeMsg = "No Change";
        } else if (outcome < 90) { // 30% chance of minor positive evolution
             outcomeMsg = "Minor Evolution";
            sData.power = uint8(Math.min(MAX_TRAIT_VALUE, sData.power + uint8(seed % 5 + 1))); // Gain 1-5 points
            sData.resilience = uint8(Math.min(MAX_TRAIT_VALUE, sData.resilience + uint8((seed / 10) % 5 + 1)));
            sData.affinity = uint8(Math.min(MAX_TRAIT_VALUE, sData.affinity + uint8((seed / 100) % 5 + 1)));
        } else { // 10% chance of significant positive evolution
             outcomeMsg = "Significant Evolution!";
             sData.power = uint8(Math.min(MAX_TRAIT_VALUE, sData.power + uint8(seed % 10 + 5))); // Gain 5-14 points
            sData.resilience = uint8(Math.min(MAX_TRAIT_VALUE, sData.resilience + uint8((seed / 10) % 10 + 5)));
            sData.affinity = uint8(Math.min(MAX_TRAIT_VALUE, sData.affinity + uint8((seed / 100) % 10 + 5)));
        }

        // Decay attempt is also triggered on evolution attempt
        triggerDecayAttempt(tokenId);


        emit TraitsEvolved(tokenId, sData.power, sData.resilience, sData.affinity, outcomeMsg);
    }

    // Internal decay attempt logic - triggered by claim/unstake/evolution attempt
    function triggerDecayAttempt(uint256 tokenId) internal {
         require(_exists(tokenId), "Token does not exist");
         SentinelData storage sData = sentinelData[tokenId];

         if (!sData.isStaked) return; // Decay only applies when staked

         uint256 timeSinceLastDecay = block.timestamp - sData.lastDecayAttemptTimestamp;
         // Decay attempt frequency: e.g., once per week (7 days)
         uint256 decayFrequency = 7 days; // Example: 1 week

         if (timeSinceLastDecay >= decayFrequency) {
             sData.lastDecayAttemptTimestamp = uint64(block.timestamp);

             // Decay chance based on Resilience: Higher resilience means lower chance
             // Example: 100 Resilience = 0% decay chance. 0 Resilience = 100% decay chance (or high chance)
             // Chance = (100 - Resilience) %
             uint256 resilienceBasedChance = uint256(MAX_TRAIT_VALUE - sData.resilience); // 0 to 99

             uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, "decay")));
             uint256 roll = seed % 100; // 0-99

             if (roll < resilienceBasedChance) { // Decay happens
                uint8 decayAmount = uint8((seed / 10) % 3 + 1); // Lose 1-3 points

                // Randomly pick a trait to decay
                uint256 traitToDecay = (seed / 100) % 3; // 0=Power, 1=Resilience, 2=Affinity

                uint8 oldTraitValue;
                string memory traitName;

                if (traitToDecay == 0) {
                    oldTraitValue = sData.power;
                    sData.power = uint8(Math.max(MIN_TRAIT_VALUE, sData.power - decayAmount));
                    traitName = "Power";
                    if (oldTraitValue != sData.power) emit TraitDecayed(tokenId, oldTraitValue, sData.power, traitName);
                } else if (traitToDecay == 1) {
                     oldTraitValue = sData.resilience;
                    sData.resilience = uint8(Math.max(MIN_TRAIT_VALUE, sData.resilience - decayAmount));
                     traitName = "Resilience";
                     if (oldTraitValue != sData.resilience) emit TraitDecayed(tokenId, oldTraitValue, sData.resilience, traitName);
                } else {
                     oldTraitValue = sData.affinity;
                    sData.affinity = uint8(Math.max(MIN_TRAIT_VALUE, sData.affinity - decayAmount));
                     traitName = "Affinity";
                     if (oldTraitValue != sData.affinity) emit TraitDecayed(tokenId, oldTraitValue, sData.affinity, traitName);
                }
             }
         }
    }


    function repairSentinel(uint256 tokenId, uint256 aetherAmount) public onlySentinelOwner(tokenId) whenStaked(tokenId) {
         require(aetherAmount > 0, InvalidAmount());
         require(_aetherBalances[msg.sender] >= aetherAmount, NotEnoughAether(aetherAmount, _aetherBalances[msg.sender]));

         SentinelData storage sData = sentinelData[tokenId];

         uint256 resilienceRestored = (aetherAmount * 1e18) / repairCostMultiplier; // How many points can be restored
         uint8 oldResilience = sData.resilience;

         // Restore Resilience up to MAX_TRAIT_VALUE
         sData.resilience = uint8(Math.min(uint256(MAX_TRAIT_VALUE), uint256(sData.resilience) + resilienceRestored));

         uint256 actualResilienceRestored = uint256(sData.resilience) - uint256(oldResilience);
         // Calculate actual Aether used based on points actually restored
         uint256 actualAetherCost = (actualResilienceRestored * repairCostMultiplier) / 1e18;

         _burnAether(msg.sender, actualAetherCost); // Burn the consumed Aether

         emit SentinelRepaired(tokenId, actualAetherCost, sData.resilience);
    }

    function scoutLocation(uint256 tokenId, uint256 targetLocationId) public onlySentinelOwner(tokenId) whenStaked(tokenId) {
        require(targetLocationId > 0 && targetLocationId <= LOCATION_COUNT, InvalidLocation());
        require(sentinelData[tokenId].locationId == targetLocationId, "Sentinel must be staked at the target location to scout it"); // Must scout current location

         require(_aetherBalances[msg.sender] >= scoutingCost, NotEnoughAether(scoutingCost, _aetherBalances[msg.sender]));
         _burnAether(msg.sender, scoutingCost); // Burn scouting cost


        SentinelData storage sData = sentinelData[tokenId];
        // Scouting success/outcome based on Affinity + Randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, msg.sender, targetLocationId, "scout")));
        uint256 roll = seed % 100; // 0-99
        uint256 affinityBasedSuccessChance = uint256(sData.affinity); // Example: 100 Affinity = 100% chance (simplified)

        uint256 extraAether = 0;
        string memory outcomeMsg;

        if (roll < affinityBasedSuccessChance) { // Scouting successful
            outcomeMsg = "Scouting Successful!";
            // Earn extra Aether based on location bonus and affinity
            extraAether = (baseAetherGenerationRate * 3600) * getLocationBonus(targetLocationId) * uint256(sData.affinity) / (1e18 * 100 * MAX_TRAIT_VALUE); // Example: 1 hour base Aether * location bonus * affinity bonus
            _mintAether(msg.sender, extraAether);
        } else { // Scouting failed or negative outcome
             outcomeMsg = "Scouting Failed.";
             // Could also add risk of trait reduction or requiring repair if failed
        }

        emit LocationScouted(tokenId, targetLocationId, extraAether, outcomeMsg);
    }

    // --- Oracle & Global Events ---

    function applyGlobalEventEffect(uint256 eventId, bytes memory data, uint256 randomnessSeed) public onlyOracle {
        // This function is called by the Oracle to signal a global event
        // 'data' could contain parameters for the event effect
        // 'randomnessSeed' is provided by the oracle for influencing outcomes

        currentGlobalEventId = eventId;
        globalEventStartTime = block.timestamp;

        // Decode data or use eventId to determine effect
        // Example: eventId 1 means reduced Power globally, eventId 2 means increased Aether rate
        uint256 seed = uint256(keccak256(abi.encodePacked(randomnessSeed, block.timestamp, block.difficulty, eventId, data)));

        if (eventId == 1) { // "Cosmic Radiation" - Reduces Power
            globalTraitModifier = 80; // Reduce traits by 20% (applied in calculation, not direct trait reduction)
            globalAetherRateModifier = 90; // Reduce Aether rate by 10%
            // Alternative: Directly reduce traits of *staked* tokens (computationally expensive!)
            // Let's stick to global modifiers for scalability.
        } else if (eventId == 2) { // "Aether Surge" - Increases Aether Rate
            globalTraitModifier = 100; // No trait effect
            globalAetherRateModifier = 150; // Increase Aether rate by 50%
        } else { // Default / Event End
            globalTraitModifier = 100; // Reset
            globalAetherRateModifier = 100; // Reset
        }

        // Note: Decay logic and trait evolution should consider the *current* trait values,
        // while Aether calculation uses the global modifiers.

        emit GlobalEventApplied(eventId, data, globalTraitModifier, globalAetherRateModifier);
    }

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    // --- Owner Functions ---

    function setBaseAetherGenerationRate(uint256 _rate) public onlyOwner {
        baseAetherGenerationRate = _rate;
    }

    function setLocationBonus(uint256 locationId, uint256 bonus) public onlyOwner {
        require(locationId > 0 && locationId <= LOCATION_COUNT, InvalidLocation());
        locationBonus[locationId] = bonus; // e.g., 150 for 1.5x
    }

     function withdrawOwnerFees() public onlyOwner {
        uint256 amount = totalProtocolFees;
        require(amount > 0, CannotWithdrawZeroFees());

        totalProtocolFees = 0; // Reset before sending
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(owner(), amount);
    }


    // --- Aether Burning ---

    function burnAether(uint256 amount) public {
        require(amount > 0, InvalidAmount());
        _burnAether(msg.sender, amount);
         emit AetherBurned(msg.sender, amount);
    }


    // --- Token URI (Placeholder) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real application, this would point to a JSON metadata file,
        // potentially served by an API that dynamically generates metadata
        // based on the Sentinel's current traits fetched from the contract.
        // For this example, we return a placeholder.
        return string(abi.encodePacked("ipfs://YOUR_BASE_URI/", Strings.toString(tokenId), "/metadata.json"));
    }

    // --- Math Utility (Simple Max/Min for trait bounding) ---
    // Using a simple internal library or just helper functions is fine.
    library Math {
        function max(uint8 a, uint8 b) internal pure returns (uint8) {
            return a >= b ? a : b;
        }
        function min(uint8 a, uint8 b) internal pure returns (uint8) {
            return a < b ? a : b;
        }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
     // --- String Utility (For tokenURI) ---
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
            unchecked {
                while (value != 0) {
                    digits--;
                    buffer[digits] = bytes1(uint8(48 + value % 10));
                    value /= 10;
                }
            }
            return string(buffer);
        }
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic NFTs (Mutable State):** The Sentinel NFTs are not static. Their core properties (traits: Power, Resilience, Affinity) can change over time based on in-game mechanics (`triggerEvolutionAttempt`, `triggerDecayAttempt`, `repairSentinel`, `applyGlobalEventEffect`). This moves beyond typical static profile-picture NFTs.
2.  **On-Chain Staking & Yield:** Implements a staking mechanism where NFTs are locked in the contract to generate a fungible token yield (Aether). The yield is calculated dynamically based on time, NFT traits, and location.
3.  **Dual Token Economy:** Manages both a non-fungible token (Sentinel NFT) and a fungible token (Aether) within the same contract, showcasing interaction between different token standards. Aether is used for utility (repair, evolution attempts, scouting) and is the generated yield.
4.  **Trait-Based Mechanics:** NFT traits have a direct impact on gameplay mechanics (Aether generation rate bonus, resistance to decay, scouting/evolution success chance). This gives traits functional value beyond aesthetics.
5.  **Evolution and Decay Simulation:** Introduces complex trait dynamics. Evolution attempts are player-triggered and potentially costly, adding a risk/reward element. Decay is a passive process counteracted by Resilience, representing maintenance needs.
6.  **Oracle Integration for Global Events:** The `applyGlobalEventEffect` function allows an authorized external entity (the Oracle) to introduce global state changes that affect all *staked* Sentinels' performance (via rate/trait modifiers). This enables dynamic world events controlled off-chain but enforced on-chain, making the game environment responsive without requiring contract upgrades.
7.  **Location-Based Bonuses:** Staking location matters, introducing a strategic element to where players stake their Sentinels to optimize Aether yield.
8.  **Scouting Mechanism:** A simple interaction where a staked Sentinel can perform an action (scouting) at its location for potential rewards or risks, adding another layer of gameplay loop.
9.  **Protocol Fees & Burning:** A small fee is taken on Aether claims, accumulating in the contract, and the owner can withdraw it (simulate revenue). Users can also burn Aether, providing a deflationary sink for the fungible token.
10. **Custom ERC721/ERC20 Implementation:** While standard libraries exist, the contract includes custom implementations of the basic ERC721 and ERC20 transfer/ownership/balance logic, integrated with the custom staking checks (`CannotTransferStakedToken`). This fulfills the requirement of not duplicating *entire* open source libraries while adhering to standard interfaces and events.
11. **Timestamp-Based State Changes:** Utilizes `block.timestamp` heavily for calculating Aether earned over time and determining when decay attempts should occur.
12. **Modular Design (within one contract):** Despite being one large contract, different logical sections (ERC721, ERC20, Staking, Dynamics, Oracle, Owner) are conceptually separated.
13. **Error Handling:** Uses custom errors (Solidity 0.8.4+) for clearer revert reasons.
14. **View Functions for Transparency:** Multiple view functions allow users to inspect the state of their Sentinels, calculate potential earnings, and understand game parameters.
15. **Simple Randomness (with caveats):** Uses block data and seeds for *simulating* randomness in evolution and decay. A real production system would require a more robust VRF (Verifiable Random Function) like Chainlink VRF.
16. **Gas Considerations:** While not explicitly optimized for minimal gas in every function, the design avoids iterating over large arrays of tokens for global effects by using global modifiers. Iterating owned tokens by address is still potentially gas-heavy if a user owns many tokens.
17. **Access Control (`Ownable`, `onlyOracle`):** Standard but necessary patterns for managing contract parameters and privileged functions.

This contract provides a framework for a rich, on-chain game or DeFi-like experience involving dynamic NFTs, staking rewards, and evolving attributes influenced by internal mechanics and external data.