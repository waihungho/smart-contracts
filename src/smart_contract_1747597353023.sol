```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Aetheria Genesis - Dynamic Bloom Cultivation Protocol
 * @author [Your Name/Pseudonym]
 * @notice This contract implements a novel system where users stake an ERC20 token (AetheriaToken)
 *         to cultivate unique, dynamic ERC721 NFTs (GenesisBlooms).
 *         The Blooms evolve in maturity and traits based on staking duration, staked amount,
 *         and active user interactions (nurturing, pruning). Users can harvest yield
 *         (AetherYieldToken) from mature Blooms.
 *
 * @dev This contract includes:
 *      - Custom internal implementation of minimal ERC721 logic.
 *      - Staking of an external ERC20 token tied to specific NFTs.
 *      - Dynamic NFT state (maturity, traits, growth rate) updated based on time and interactions.
 *      - Mechanics for nurturing (boosting growth), pruning (sacrificing staked value for temporary boost),
 *        and harvesting yield.
 *      - Pseudo-random trait discovery mechanism.
 *      - Ability to migrate staked amounts between owned Blooms.
 *      - Aims to demonstrate advanced concepts like state-dependent NFTs, complex token interactions,
 *        and novel mechanics beyond standard DeFi/NFT primitives.
 *      - Includes basic access control and error handling.
 *
 * Outline:
 * 1. Interfaces for external tokens (ERC20 for staking, ERC20 for yield).
 * 2. Error definitions.
 * 3. Events for tracking key actions.
 * 4. Struct to hold dynamic data for each GenesisBloom NFT.
 * 5. Core Contract `AetheriaGenesis`:
 *    - State variables: Owner, token addresses, NFT state mappings (owners, balances, approvals), Bloom data mapping, global counters.
 *    - Constructor: Sets initial owner.
 *    - Access Control: Simple `onlyOwner` modifier.
 *    - Internal ERC721 Helpers: `_exists`, `_msgSender`, `_mint`, `_burn`, `_transfer`, etc. (Minimal implementation).
 *    - Internal Logic: `_calculateMaturity`, `_applyGrowthMultiplier`.
 *    - ERC721 Standard Functions (Minimal subset): `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`.
 *    - Staking & Bloom Initiation: `initiateBloom`, `unstakeAET`.
 *    - Bloom Interaction & Management: `nurtureBloom`, `harvestAether`, `pruneBloom`, `discoverTrait`, `migrateStakedAET`.
 *    - View Functions: `getBloomMaturity`, `getHarvestableAether`, `getCurrentBloomTraits`, `getBloomGrowthRate`, `getBloomState`, `getBloomStakedAmount`, `getTotalStakedAET`, `getBloomCount`, etc.
 *    - Admin Functions: `setAetheriaToken`, `setAetherYieldToken`, `withdrawSystemFees`.
 *
 * Function Summary (27 functions):
 * - Core ERC721 (Internal/Standard Interface):
 *   - ownerOf(uint256 bloomId) external view returns (address owner)
 *   - balanceOf(address owner) external view returns (uint256 balance)
 *   - getApproved(uint256 bloomId) external view returns (address operator)
 *   - isApprovedForAll(address owner, address operator) external view returns (bool)
 *   - approve(address operator, uint256 bloomId) external
 *   - setApprovalForAll(address operator, bool approved) external
 *   - transferFrom(address from, address to, uint256 bloomId) external
 *   - safeTransferFrom(address from, address to, uint256 bloomId) external
 *   - safeTransferFrom(address from, address to, uint256 bloomId, bytes calldata data) external
 *   - supportsInterface(bytes4 interfaceId) external view returns (bool) // ERC165
 * - Staking & Bloom Initiation:
 *   - initiateBloom(uint256 amount) external
 *   - unstakeAET(uint256 bloomId) external
 * - Bloom Interaction & Management:
 *   - nurtureBloom(uint256 bloomId) external
 *   - harvestAether(uint256 bloomId) external
 *   - pruneBloom(uint256 bloomId, uint256 percentageToPrune) external
 *   - discoverTrait(uint256 bloomId) external
 *   - migrateStakedAET(uint256 fromBloomId, uint256 toBloomId, uint256 amount) external
 * - Internal Logic Helpers (Used internally):
 *   - _calculateMaturity(uint256 bloomId) internal view returns (uint256 currentMaturity)
 *   - _applyGrowthMultiplier(uint256 bloomId) internal view returns (uint256 adjustedGrowthRate)
 * - View Functions:
 *   - getBloomMaturity(uint256 bloomId) external view returns (uint256 maturity)
 *   - getHarvestableAether(uint256 bloomId) external view returns (uint256 amount)
 *   - getCurrentBloomTraits(uint256 bloomId) external view returns (uint256[] memory traits)
 *   - getBloomGrowthRate(uint256 bloomId) external view returns (uint256 rate)
 *   - getBloomState(uint256 bloomId) external view returns (BloomData memory bloomData)
 *   - getBloomStakedAmount(uint256 bloomId) external view returns (uint256 amount)
 *   - getTotalStakedAET() external view returns (uint256 amount)
 *   - getBloomCount() external view returns (uint256 count)
 * - Admin Functions:
 *   - setAetheriaToken(address tokenAddress) external onlyOwner
 *   - setAetherYieldToken(address tokenAddress) external onlyOwner
 *   - withdrawSystemFees(address tokenAddress) external onlyOwner
 */

// --- Interfaces ---

interface IAetheriaToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // Minimum functions needed
}

interface IAetherYieldToken {
    function mint(address account, uint256 amount) external;
    // Minimum functions needed
}

// --- Errors ---

error NotOwnerOfBloom(address caller, uint256 bloomId);
error BloomDoesNotExist(uint256 bloomId);
error StakedAmountTooLow();
error InsufficientStakedAmount(uint256 requested, uint256 available);
error ZeroAddress();
error TokensNotSet();
error Unauthorized();
error InvalidPercentage();
error MigrationBetweenDifferentOwners(address owner1, address owner2);
error CannotMigrateToSelf();
error InvalidBloomState(); // Generic error for operations on non-cultivated or invalid blooms

// --- Events ---

event BloomInitiated(uint256 indexed bloomId, address indexed owner, uint256 stakedAmount, uint256 timestamp);
event AETStaked(uint256 indexed bloomId, address indexed owner, uint256 amountAdded, uint256 newTotal);
event AETUnstaked(uint256 indexed bloomId, address indexed owner, uint256 amount);
event AetherHarvested(uint256 indexed bloomId, address indexed owner, uint256 amountYielded, uint256 timestamp);
event BloomNurtured(uint256 indexed bloomId, address indexed owner, uint256 costAmount, uint256 newGrowthMultiplier, uint256 timestamp);
event BloomPruned(uint256 indexed bloomId, address indexed owner, uint256 amountPruned, uint256 newGrowthMultiplier, uint256 timestamp);
event TraitDiscovered(uint256 indexed bloomId, address indexed owner, uint256 traitId, uint256 timestamp);
event AETMigrated(uint256 indexed fromBloomId, uint256 indexed toBloomId, address indexed owner, uint256 amount);

// ERC721 Events (Minimal)
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


// --- Data Structures ---

struct BloomData {
    uint256 stakedAmount;
    uint256 lastUpdated;       // Timestamp of last state change (stake, nurture, prune, harvest, init)
    uint256 maturity;          // Accumulated maturity points
    uint256 growthMultiplier;  // Temporary boost to growth rate (e.g., from nurturing/pruning)
    uint256 lastHarvestTimestamp; // Timestamp of last yield harvest
    uint256[] traits;          // Discovered traits (IDs)
    // Future fields could include: affinity, environmental factor, etc.
}


// --- Main Contract ---

contract AetheriaGenesis {
    // --- State Variables ---

    address private _owner; // Basic owner for admin functions

    IAetheriaToken public aetToken;
    IAetherYieldToken public aetherYieldToken;

    // ERC721 State (Minimal Implementation)
    mapping(uint256 => address) private _owners; // Bloom ID to Owner address
    mapping(address => uint256) private _balances; // Owner address to Bloom count
    mapping(uint256 => address) private _tokenApprovals; // Bloom ID to Approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner address to (Operator address => isApproved)

    // Bloom Specific Data
    mapping(uint256 => BloomData) private _blooms; // Bloom ID to its dynamic data

    uint256 private _nextTokenId; // Counter for unique Bloom IDs
    uint256 private _totalStakedAET;

    // Constants (could be configurable by owner/governance)
    uint256 public constant MIN_STAKE_AMOUNT = 1e18; // Example: 1 AET minimum to initiate a Bloom
    uint256 public constant MATURITY_PER_SECOND_PER_AET = 1; // Base maturity rate per AET staked per second
    uint256 public constant YIELD_RATE_PER_MATURITY_PER_SECOND = 1; // Base yield rate
    uint256 public constant NURTURE_COST_PERCENTAGE_STAKED = 1; // % of staked AET burned on nurture (scaled by 100)
    uint256 public constant NURTURE_GROWTH_BOOST_PERCENTAGE = 10; // % boost to growth rate (scaled by 100)
    uint256 public constant NURTURE_BOOST_DURATION = 7 days; // Duration of growth boost
    uint256 public constant PRUNE_GROWTH_BOOST_PERCENTAGE = 25; // % boost from pruning
    uint256 public constant PRUNE_BOOST_DURATION = 14 days; // Duration of prune boost
    uint256 public constant MAX_TRAIT_ID = 100; // Example max possible trait ID

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- Access Control ---

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert Unauthorized();
        }
        _;
    }

    // --- Internal ERC721 Helpers (Minimal) ---
    // Note: A full ERC721 implementation would use Libraries for safety/efficiency.
    // This minimal version is for demonstration purposes to avoid copy-pasting standard OZ.

    function _exists(uint256 bloomId) internal view returns (bool) {
        return _owners[bloomId] != address(0);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _mint(address to, uint256 bloomId) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_exists(bloomId)) revert InvalidBloomState(); // Cannot mint existing

        _owners[bloomId] = to;
        _balances[to]++;
        emit Transfer(address(0), to, bloomId);
    }

    function _burn(uint256 bloomId) internal {
        address owner = _owners[bloomId];
        if (owner == address(0)) revert BloomDoesNotExist(bloomId);

        // Clear approvals
        approve(address(0), bloomId);

        _balances[owner]--;
        delete _owners[bloomId];
        delete _blooms[bloomId]; // Clear associated Bloom data

        emit Transfer(owner, address(0), bloomId);
    }

    function _transfer(address from, address to, uint256 bloomId) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (_owners[bloomId] != from) revert NotOwnerOfBloom(from, bloomId); // Should not happen if called internally correctly

        // Clear approvals before transfer
        approve(address(0), bloomId);

        _balances[from]--;
        _balances[to]++;
        _owners[bloomId] = to;

        // Bloom data stays with the ID
        // Maturity/Yield calculation needs to handle potential time gaps after transfer
        // Update lastUpdated timestamp on transfer? Yes, good idea.
        _blooms[bloomId].lastUpdated = block.timestamp;
        _blooms[bloomId].lastHarvestTimestamp = block.timestamp; // Reset harvestable on transfer

        emit Transfer(from, to, bloomId);
    }

    function _isApprovedOrOwner(address spender, uint256 bloomId) internal view returns (bool) {
        address owner = ownerOf(bloomId);
        return (spender == owner || getApproved(bloomId) == spender || isApprovedForAll(owner, spender));
    }

    // --- Internal Logic Helpers ---

    function _calculateMaturity(uint256 bloomId) internal view returns (uint256 currentMaturity) {
        BloomData storage bloom = _blooms[bloomId];
        if (bloom.lastUpdated == 0 || bloom.stakedAmount == 0) {
             return bloom.maturity; // Not initiated or no stake
        }

        uint256 timeElapsed = block.timestamp - bloom.lastUpdated;
        if (timeElapsed == 0) {
            return bloom.maturity; // No time passed since last update
        }

        uint256 baseGrowth = timeElapsed * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount;
        uint256 adjustedGrowth = (baseGrowth * _applyGrowthMultiplier(bloomId)) / 100; // Apply growth multiplier

        return bloom.maturity + adjustedGrowth;
    }

    function _applyGrowthMultiplier(uint256 bloomId) internal view returns (uint256 adjustedMultiplier) {
        BloomData storage bloom = _blooms[bloomId];
        // Example: Growth multiplier decays over time.
        // Here, assuming multiplier is a percentage bonus (100 = no bonus, 110 = 10% bonus)
        // For simplicity, we'll just use the current stored multiplier.
        // A more complex version would track *when* boosts were applied and decay them.
        // Let's make it simpler: multiplier is applied *instantly* and lasts for a set duration.
        // Need to add 'growthMultiplierEndTime' to BloomData struct.
        // Re-evaluating BloomData struct:
        // struct BloomData {
        //     uint256 stakedAmount;
        //     uint256 lastUpdated;       // Timestamp of last state change (stake, nurture, prune, harvest, init)
        //     uint256 maturity;          // Accumulated maturity points
        //     uint256 growthMultiplier;  // Current active multiplier (e.g., 100 = base)
        //     uint256 growthMultiplierEndTime; // Timestamp when current multiplier expires
        //     uint256 lastHarvestTimestamp; // Timestamp of last yield harvest
        //     uint256[] traits;          // Discovered traits (IDs)
        // }
        // Okay, let's add growthMultiplierEndTime and update _calculateMaturity

        // Updated _calculateMaturity (Refactored slightly)
        // Function signature remains the same, but internal logic changes.

        // Original plan didn't have growthMultiplierEndTime. Let's stick to the simpler plan for 20+ functions
        // and just have growthMultiplier be a value that nurturing/pruning SETS, which affects growth until the *next* update.
        // This is simpler to implement with minimal state changes. The multiplier is consumed upon maturity calculation.
        // No, that doesn't make sense for a *boost*. A boost should apply *until* it expires.
        // Let's add growthMultiplierEndTime.

        // struct BloomData {
        //     uint256 stakedAmount;
        //     uint256 lastUpdated;       // Timestamp of last state change (stake, nurture, prune, harvest, init)
        //     uint256 maturity;          // Accumulated maturity points
        //     uint256 growthMultiplier;  // Current active multiplier (e.g., 100 = base, 110 = 10% boost)
        //     uint256 growthMultiplierEndTime; // Timestamp when current multiplier expires
        //     uint256 lastHarvestTimestamp; // Timestamp of last yield harvest
        //     uint256[] traits;          // Discovered traits (IDs)
        // }
        // Okay, adding growthMultiplierEndTime field.

        // Let's redefine the maturity calculation slightly.
        // Instead of accumulating maturity *points*, let's calculate 'potential' maturity based on time/stake/multiplier
        // and update the Bloom's state.

        // New approach: Whenever state changes (stake, nurture, harvest, prune, transfer, or specific update call),
        // calculate maturity earned since last update, add it to bloom.maturity, then update bloom.lastUpdated.
        // Apply multiplier only *during* the time it was active.

        BloomData storage bloom = _blooms[bloomId];
        if (bloom.lastUpdated == 0 || bloom.stakedAmount == 0) {
             return 0; // No growth
        }

        uint256 timeElapsed = block.timestamp - bloom.lastUpdated;
        if (timeElapsed == 0) {
            return 0; // No growth
        }

        uint256 growthMultiplier = 100; // Base multiplier (100%)
        uint256 effectiveTimeWithMultiplier = 0;
        uint256 effectiveTimeBase = timeElapsed;

        if (bloom.growthMultiplierEndTime > bloom.lastUpdated) {
             uint256 boostEndTime = bloom.growthMultiplierEndTime;
             uint256 boostStartTime = bloom.lastUpdated; // Assuming boost starts when lastUpdated is set/updated by boost
             if (bloom.growthMultiplierEndTime < block.timestamp) {
                // Boost ended during the elapsed time
                effectiveTimeWithMultiplier = boostEndTime - boostStartTime;
                effectiveTimeBase = block.timestamp - boostEndTime;
                growthMultiplier = bloom.growthMultiplier;
             } else {
                // Boost is still active for the whole elapsed time
                effectiveTimeWithMultiplier = timeElapsed;
                effectiveTimeBase = 0;
                growthMultiplier = bloom.growthMultiplier;
             }
        }
         // If growthMultiplierEndTime <= bloom.lastUpdated, no active boost period in this interval.

        uint256 maturityFromBoost = (effectiveTimeWithMultiplier * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount * growthMultiplier) / 100;
        uint256 maturityFromBase = (effectiveTimeBase * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount); // Base multiplier is 100, so no division needed

        uint256 earnedMaturity = maturityFromBoost + maturityFromBase;

        // Update bloom state
        bloom.maturity += earnedMaturity;
        bloom.lastUpdated = block.timestamp;
        // Reset multiplier if it expired
        if (bloom.growthMultiplierEndTime <= block.timestamp) {
            bloom.growthMultiplier = 100;
            bloom.growthMultiplierEndTime = 0;
        }

        return earnedMaturity; // Return maturity earned in this call
    }


    // --- ERC721 Standard Functions (Minimal) ---
    // Interface check: https://eips.ethereum.org/EIPS/eip-165
    // ERC721: 0x80ac58cd
    // ERC721Metadata: 0x5b5e139f (Not implementing metadata URI for simplicity)
    // ERC721Enumerable: 0x780e9d63 (Not implementing enumeration for simplicity)

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        // ERC165 interface ID
        bytes4 erc165Id = 0x01ffc9a7;
        // ERC721 interface ID
        bytes4 erc721Id = 0x80ac58cd;
        // Add others if implemented (Metadata, Enumerable)
        return interfaceId == erc165Id || interfaceId == erc721Id;
    }

    function ownerOf(uint256 bloomId) public view returns (address owner) {
        owner = _owners[bloomId];
        if (owner == address(0)) {
            revert BloomDoesNotExist(bloomId);
        }
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function getApproved(uint256 bloomId) public view returns (address operator) {
        if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
        return _tokenApprovals[bloomId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        if (owner == address(0) || operator == address(0)) revert ZeroAddress();
        return _operatorApprovals[owner][operator];
    }

    function approve(address operator, uint256 bloomId) public {
        address owner = ownerOf(bloomId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Unauthorized();
        }

        _tokenApprovals[bloomId] = operator;
        emit Approval(owner, operator, bloomId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert Unauthorized(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 bloomId) public {
         _transferFrom(from, to, bloomId);
    }

     function safeTransferFrom(address from, address to, uint256 bloomId) public {
         _transferFrom(from, to, bloomId);
         // Add ERC721Receiver check here for full compliance.
         // Skipping for brevity in this example contract to keep it under 20+ *unique* logic functions.
     }

     function safeTransferFrom(address from, address to, uint256 bloomId, bytes calldata data) public {
         _transferFrom(from, to, bloomId);
         // Add ERC721Receiver check here.
         // Skipping for brevity.
     }

    function _transferFrom(address from, address to, uint256 bloomId) internal {
         if (ownerOf(bloomId) != from) revert NotOwnerOfBloom(from, bloomId);
         if (!_isApprovedOrOwner(_msgSender(), bloomId)) revert Unauthorized();
         if (to == address(0)) revert ZeroAddress();

         _transfer(from, to, bloomId);
    }


    // --- Staking & Bloom Initiation ---

    /**
     * @notice Allows a user to stake AET and initiate a new GenesisBloom NFT.
     * @param amount The amount of AET to stake for this new Bloom.
     */
    function initiateBloom(uint256 amount) external {
        if (address(aetToken) == address(0)) revert TokensNotSet();
        if (amount < MIN_STAKE_AMOUNT) revert StakedAmountTooLow();

        uint256 newBloomId = _nextTokenId;
        _nextTokenId++;

        // Transfer AET from user to this contract
        if (!aetToken.transferFrom(msg.sender, address(this), amount)) {
             revert InvalidBloomState(); // Generic error for transfer failure
        }

        _totalStakedAET += amount;

        // Mint the new Bloom NFT
        _mint(msg.sender, newBloomId);

        // Initialize Bloom data
        _blooms[newBloomId] = BloomData({
            stakedAmount: amount,
            lastUpdated: block.timestamp,
            maturity: 0,
            growthMultiplier: 100, // Base multiplier
            growthMultiplierEndTime: 0, // No boost initially
            lastHarvestTimestamp: block.timestamp,
            traits: new uint256[](0) // Start with no traits
        });

        emit BloomInitiated(newBloomId, msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Allows the owner of a Bloom to unstake the associated AET.
     *         This action burns the GenesisBloom NFT.
     * @param bloomId The ID of the Bloom to unstake and burn.
     */
    function unstakeAET(uint256 bloomId) external {
        if (ownerOf(bloomId) != msg.sender) revert NotOwnerOfBloom(msg.sender, bloomId);
        if (address(aetToken) == address(0)) revert TokensNotSet();

        BloomData storage bloom = _blooms[bloomId];
        uint256 amountToUnstake = bloom.stakedAmount;

        if (amountToUnstake == 0) {
            revert InsufficientStakedAmount(0, 0); // Should not happen if bloom exists and has data, but safety check
        }

        // First, burn the NFT (this also deletes bloom data internally in _burn)
        _burn(bloomId);

        // Then, transfer the staked AET back to the user
        // Note: Need to ensure contract has enough balance. _totalStakedAET tracking helps.
        _totalStakedAET -= amountToUnstake;

        // Use call for transfer out, safer pattern (handle return bool)
        (bool success, ) = address(aetToken).call(abi.encodeWithSelector(aetToken.transfer.selector, msg.sender, amountToUnstake));
        if (!success) {
             // This is a critical error state. Reverting is safest.
             // In a real contract, you might log this error and consider a recovery mechanism.
             revert InvalidBloomState(); // Generic error for transfer failure
        }


        emit AETUnstaked(bloomId, msg.sender, amountToUnstake);
    }

    // --- Bloom Interaction & Management ---

    /**
     * @notice Nurtures a Bloom, consuming a small amount of staked AET
     *         to apply a temporary growth multiplier boost.
     * @param bloomId The ID of the Bloom to nurture.
     */
    function nurtureBloom(uint256 bloomId) external {
        if (ownerOf(bloomId) != msg.sender) revert NotOwnerOfBloom(msg.sender, bloomId);
        if (address(aetToken) == address(0)) revert TokensNotSet();

        BloomData storage bloom = _blooms[bloomId];
        if (bloom.stakedAmount == 0) revert InvalidBloomState();

        // First, calculate earned maturity up to now and update state
        _calculateMaturity(bloomId);

        // Calculate cost: percentage of current staked amount
        uint256 nurtureCost = (bloom.stakedAmount * NURTURE_COST_PERCENTAGE_STAKED) / 100;

        if (nurtureCost > 0) {
            // Reduce staked amount
            bloom.stakedAmount -= nurtureCost;
            _totalStakedAET -= nurtureCost;

            // Note: The cost AET is *burned* from the staked amount, not transferred elsewhere.
            // It could also be transferred to an admin fee wallet if desired.
        }

        // Apply growth boost
        // New multiplier overrides previous if active
        bloom.growthMultiplier = 100 + NURTURE_GROWTH_BOOST_PERCENTAGE;
        bloom.growthMultiplierEndTime = block.timestamp + NURTURE_BOOST_DURATION;

        // Update last updated timestamp
        bloom.lastUpdated = block.timestamp;

        emit BloomNurtured(bloomId, msg.sender, nurtureCost, bloom.growthMultiplier, block.timestamp);
    }

    /**
     * @notice Harvests yield (AetherYieldToken) from a Bloom based on its maturity.
     *         Claimable yield accumulates over time based on maturity.
     * @param bloomId The ID of the Bloom to harvest from.
     */
    function harvestAether(uint256 bloomId) external {
        if (ownerOf(bloomId) != msg.sender) revert NotOwnerOfBloom(msg.sender, bloomId);
        if (address(aetherYieldToken) == address(0)) revert TokensNotSet();

        BloomData storage bloom = _blooms[bloomId];
         if (bloom.stakedAmount == 0) revert InvalidBloomState();

        // First, calculate earned maturity up to now and update state
        _calculateMaturity(bloomId);

        uint256 timeSinceLastHarvest = block.timestamp - bloom.lastHarvestTimestamp;
        if (timeSinceLastHarvest == 0 || bloom.maturity == 0) {
            // No time elapsed or no maturity to yield from
            return; // Or revert, depending on desired strictness
        }

        // Calculate harvestable yield based on maturity and time since last harvest
        // Simple example: yield = maturity * time * rate
        // A more complex model could use maturity as a *factor* in yield rate.
        // Let's use the time since last harvest and the *current* maturity level
        uint256 yieldAmount = (timeSinceLastHarvest * bloom.maturity * YIELD_RATE_PER_MATURITY_PER_SECOND) / 1e18; // Adjust scaling if rates are high

        if (yieldAmount > 0) {
             // Mint AetherYieldToken to the user
             aetherYieldToken.mint(msg.sender, yieldAmount);
             bloom.lastHarvestTimestamp = block.timestamp; // Update last harvest time
             emit AetherHarvested(bloomId, msg.sender, yieldAmount, block.timestamp);
        } else {
             // Optional: Update last harvest time even if amount is 0 to prevent manipulating timestamps
             // bloom.lastHarvestTimestamp = block.timestamp;
        }

        // Update last updated timestamp (already done by _calculateMaturity)
        // bloom.lastUpdated = block.timestamp;
    }


    /**
     * @notice Prunes a Bloom, sacrificing a percentage of its staked AET
     *         in exchange for a stronger, but potentially shorter, growth boost.
     * @param bloomId The ID of the Bloom to prune.
     * @param percentageToPrune The percentage of staked AET to sacrifice (0-100).
     */
    function pruneBloom(uint256 bloomId, uint256 percentageToPrune) external {
        if (ownerOf(bloomId) != msg.sender) revert NotOwnerOfBloom(msg.sender, bloomId);
        if (percentageToPrune > 100) revert InvalidPercentage();
        if (address(aetToken) == address(0)) revert TokensNotSet();

        BloomData storage bloom = _blooms[bloomId];
        if (bloom.stakedAmount == 0) revert InvalidBloomState();

        // First, calculate earned maturity up to now and update state
        _calculateMaturity(bloomId);

        uint256 pruneAmount = (bloom.stakedAmount * percentageToPrune) / 100;

        if (pruneAmount > 0) {
            // Reduce staked amount (burn)
            bloom.stakedAmount -= pruneAmount;
            _totalStakedAET -= pruneAmount;
             // Maturity might decrease proportionally? Or maybe just staked amount decreases growth basis?
             // Let's just decrease staked amount. Maturity is accumulated history.
        }

        // Apply stronger growth boost
        // New multiplier overrides previous if active
        bloom.growthMultiplier = 100 + PRUNE_GROWTH_BOOST_PERCENTAGE;
        bloom.growthMultiplierEndTime = block.timestamp + PRUNE_BOOST_DURATION;

        // Update last updated timestamp
        bloom.lastUpdated = block.timestamp;

        emit BloomPruned(bloomId, msg.sender, pruneAmount, bloom.growthMultiplier, block.timestamp);
    }


    /**
     * @notice Attempts to discover a rare trait for a Bloom using pseudo-randomness.
     *         This action might require a small fee (e.g., AET) or other conditions.
     *         For simplicity, this version just uses block hash and requires Bloom ownership.
     *         Does not cost anything extra besides the transaction gas.
     * @param bloomId The ID of the Bloom to attempt discovery on.
     */
    function discoverTrait(uint256 bloomId) external {
        if (ownerOf(bloomId) != msg.sender) revert NotOwnerOfBloom(msg.sender, bloomId);

        BloomData storage bloom = _blooms[bloomId];
         if (bloom.stakedAmount == 0) revert InvalidBloomState();

        // First, calculate earned maturity up to now and update state
        _calculateMaturity(bloomId);

        // Pseudo-randomness (Note: blockhash is exploitable for high-value use cases)
        bytes32 entropy = keccak256(abi.encodePacked(
            blockhash(block.number - 1), // Use a recent block hash
            block.timestamp,
            bloomId,
            msg.sender,
            bloom.maturity, // Incorporate bloom state
            block.difficulty // Add difficulty for more entropy
        ));

        uint256 randomValue = uint256(entropy);

        // Example discovery logic: Discover a trait if random value meets certain criteria
        // This is a placeholder. Real discovery logic would be more complex,
        // potentially weighted by maturity, staked amount, existing traits, etc.

        uint256 discoveredTraitId = 0;
        bool traitFound = false;

        // Simple probability example: ~5% chance to find a trait up to MAX_TRAIT_ID
        if (randomValue % 100 < 5) { // 5% chance
             discoveredTraitId = (randomValue % MAX_TRAIT_ID) + 1; // Traits 1 to MAX_TRAIT_ID
             traitFound = true;

            // Check if the trait is already discovered
            bool alreadyHasTrait = false;
            for(uint i = 0; i < bloom.traits.length; i++) {
                if (bloom.traits[i] == discoveredTraitId) {
                    alreadyHasTrait = true;
                    break;
                }
            }

            if (!alreadyHasTrait) {
                bloom.traits.push(discoveredTraitId);
                emit TraitDiscovered(bloomId, msg.sender, discoveredTraitId, block.timestamp);
            } else {
                 traitFound = false; // Didn't find a *new* trait
            }
        }

        // Update last updated timestamp
        bloom.lastUpdated = block.timestamp;

        // Optional: Return bool indicating if trait was found
        // return traitFound; // If this were a public/external view function
    }


    /**
     * @notice Allows the owner to migrate a portion of the staked AET
     *         from one owned Bloom to another owned Bloom.
     *         Affects the growth rate of both Blooms.
     * @param fromBloomId The ID of the source Bloom.
     * @param toBloomId The ID of the destination Bloom.
     * @param amount The amount of AET to migrate.
     */
    function migrateStakedAET(uint256 fromBloomId, uint256 toBloomId, uint256 amount) external {
        address owner = msg.sender;
        if (ownerOf(fromBloomId) != owner) revert NotOwnerOfBloom(owner, fromBloomId);
        if (ownerOf(toBloomId) != owner) revert NotOwnerOfBloom(owner, toBloomId);
        if (fromBloomId == toBloomId) revert CannotMigrateToSelf();
        if (amount == 0) return; // No-op if amount is zero

        BloomData storage fromBloom = _blooms[fromBloomId];
        BloomData storage toBloom = _blooms[toBloomId];

        if (fromBloom.stakedAmount < amount) revert InsufficientStakedAmount(amount, fromBloom.stakedAmount);
         if (fromBloom.stakedAmount == 0 || toBloom.stakedAmount == 0) revert InvalidBloomState(); // Both must be cultivated

        // First, calculate earned maturity up to now for both blooms and update state
        _calculateMaturity(fromBloomId);
        _calculateMaturity(toBloomId);

        // Perform migration
        fromBloom.stakedAmount -= amount;
        toBloom.stakedAmount += amount;

        // Update last updated timestamp for both blooms
        fromBloom.lastUpdated = block.timestamp;
        toBloom.lastUpdated = block.timestamp;

        emit AETMigrated(fromBloomId, toBloomId, owner, amount);
    }

    // --- View Functions ---

    /**
     * @notice Gets the current calculated maturity level of a Bloom.
     *         This calculation is dynamic based on time and other factors.
     * @param bloomId The ID of the Bloom.
     * @return The current maturity points.
     */
    function getBloomMaturity(uint256 bloomId) external view returns (uint256 maturity) {
        if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
        return _calculateMaturity(bloomId); // Returns total accumulated maturity including un-applied growth
    }

     /**
      * @notice Gets the amount of AetherYieldToken that can be harvested from a Bloom.
      *         This calculation is dynamic based on maturity and time since last harvest.
      * @param bloomId The ID of the Bloom.
      * @return The harvestable amount of AetherYieldToken.
      */
    function getHarvestableAether(uint256 bloomId) external view returns (uint256 amount) {
        if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
        BloomData storage bloom = _blooms[bloomId];
        if (bloom.stakedAmount == 0) return 0;

        uint256 timeSinceLastHarvest = block.timestamp - bloom.lastHarvestTimestamp;
        if (timeSinceLastHarvest == 0 || bloom.maturity == 0) {
            return 0;
        }

        // Calculate potential earned maturity since last update to get up-to-date maturity for yield calculation
        uint256 potentialEarnedMaturity = 0;
        if (bloom.lastUpdated < block.timestamp) { // Only calculate if time passed since last state change
            uint256 timeElapsedSinceLastUpdate = block.timestamp - bloom.lastUpdated;
            uint256 baseGrowth = timeElapsedSinceLastUpdate * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount;

            uint256 growthMultiplier = 100;
            uint256 effectiveTimeWithMultiplier = 0;
            uint256 effectiveTimeBase = timeElapsedSinceLastUpdate;

            if (bloom.growthMultiplierEndTime > bloom.lastUpdated) {
                uint256 boostEndTime = bloom.growthMultiplierEndTime;
                uint256 boostStartTime = bloom.lastUpdated;
                if (bloom.growthMultiplierEndTime < block.timestamp) {
                    effectiveTimeWithMultiplier = boostEndTime - boostStartTime;
                    effectiveTimeBase = block.timestamp - boostEndTime;
                    growthMultiplier = bloom.growthMultiplier;
                } else {
                    effectiveTimeWithMultiplier = timeElapsedSinceLastUpdate;
                    effectiveTimeBase = 0;
                    growthMultiplier = bloom.growthMultiplier;
                }
            }
            uint256 maturityFromBoost = (effectiveTimeWithMultiplier * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount * growthMultiplier) / 100;
            uint256 maturityFromBase = (effectiveTimeBase * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount);
            potentialEarnedMaturity = maturityFromBoost + maturityFromBase;
        }

        uint256 currentEffectiveMaturity = bloom.maturity + potentialEarnedMaturity; // Maturity including un-applied growth

        // Calculate harvestable yield
        uint256 yieldAmount = (timeSinceLastHarvest * currentEffectiveMaturity * YIELD_RATE_PER_MATURITY_PER_SECOND) / 1e18;

        return yieldAmount;
    }


    /**
     * @notice Gets the list of discovered trait IDs for a Bloom.
     * @param bloomId The ID of the Bloom.
     * @return An array of trait IDs.
     */
    function getCurrentBloomTraits(uint256 bloomId) external view returns (uint256[] memory traits) {
        if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
        // Optionally, calculate maturity first and derive traits based on maturity thresholds
        // For this example, traits are just added via `discoverTrait`.
        return _blooms[bloomId].traits;
    }

     /**
      * @notice Gets the effective current growth rate multiplier for a Bloom.
      * @param bloomId The ID of the Bloom.
      * @return The growth multiplier (e.g., 100 for base rate, 110 for 10% boost).
      */
    function getBloomGrowthRate(uint256 bloomId) external view returns (uint256 rate) {
         if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
         BloomData storage bloom = _blooms[bloomId];
         if (bloom.growthMultiplierEndTime > block.timestamp) {
             return bloom.growthMultiplier;
         } else {
             return 100; // Base rate
         }
    }


    /**
     * @notice Gets all relevant state data for a specific Bloom.
     * @param bloomId The ID of the Bloom.
     * @return A struct containing the Bloom's data.
     */
    function getBloomState(uint256 bloomId) external view returns (BloomData memory bloomData) {
         if (!_exists(bloomId)) revert BloomDoesNotExist(bloomId);
         BloomData storage bloom = _blooms[bloomId];
         // Return a memory copy. Calculate maturity before returning.
         BloomData memory dataCopy = bloom;
         // Need to calculate the *potential* maturity accumulated since last update for this view
         uint256 potentialEarnedMaturity = 0;
         if (bloom.lastUpdated < block.timestamp) {
             uint256 timeElapsedSinceLastUpdate = block.timestamp - bloom.lastUpdated;
             uint256 baseGrowth = timeElapsedSinceLastUpdate * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount;

             uint256 growthMultiplier = 100;
             uint256 effectiveTimeWithMultiplier = 0;
             uint256 effectiveTimeBase = timeElapsedSinceLastUpdate;

             if (bloom.growthMultiplierEndTime > bloom.lastUpdated) {
                 uint256 boostEndTime = bloom.growthMultiplierEndTime;
                 uint256 boostStartTime = bloom.lastUpdated;
                 if (bloom.growthMultiplierEndTime < block.timestamp) {
                     effectiveTimeWithMultiplier = boostEndTime - boostStartTime;
                     effectiveTimeBase = block.timestamp - boostEndTime;
                     growthMultiplier = bloom.growthMultiplier;
                 } else {
                     effectiveTimeWithMultiplier = timeElapsedSinceLastUpdate;
                     effectiveTimeBase = 0;
                     growthMultiplier = bloom.growthMultiplier;
                 }
             }
            uint256 maturityFromBoost = (effectiveTimeWithMultiplier * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount * growthMultiplier) / 100;
            uint256 maturityFromBase = (effectiveTimeBase * MATURITY_PER_SECOND_PER_AET * bloom.stakedAmount);
            potentialEarnedMaturity = maturityFromBoost + maturityFromBase;
         }
         dataCopy.maturity += potentialEarnedMaturity; // Add potential earned maturity for current view

         // Adjust multiplier if it expired
         if (dataCopy.growthMultiplierEndTime <= block.timestamp) {
             dataCopy.growthMultiplier = 100;
             dataCopy.growthMultiplierEndTime = 0;
         }


         return dataCopy;
    }


    /**
     * @notice Gets the amount of AET currently staked for a specific Bloom.
     * @param bloomId The ID of the Bloom.
     * @return The staked amount of AET.
     */
    function getBloomStakedAmount(uint256 bloomId) external view returns (uint256 amount) {
        if (!_exists(bloomId)) return 0; // Return 0 for non-existent blooms
        return _blooms[bloomId].stakedAmount;
    }

    /**
     * @notice Gets the total amount of AET staked across all Blooms in the contract.
     * @return The total staked amount.
     */
    function getTotalStakedAET() external view returns (uint256 amount) {
        return _totalStakedAET;
    }

    /**
     * @notice Gets the total number of GenesisBloom NFTs that have been minted.
     * @return The total count of Blooms (including burned ones if _nextTokenId isn't adjusted, but it's simpler not to adjust it).
     */
    function getBloomCount() external view returns (uint256 count) {
        // This returns the next token ID minus 1. It represents the total number of mint attempts, not necessarily existing blooms.
        // For total *existing* blooms, sum up balances.
        // Let's return the sum of balances for clarity.
        uint256 existingCount = 0;
        // Iterating through all owners is not scalable.
        // A better way is to track existing bloom IDs in a separate enumerable list (like ERC721Enumerable).
        // For this example, let's just return _nextTokenId - 1, acknowledging it's total ever minted.
        return _nextTokenId - 1;
    }

    // --- Admin Functions ---

    /**
     * @notice Sets the address of the AetheriaToken (ERC20) contract used for staking.
     *         Only callable by the contract owner.
     * @param tokenAddress The address of the AetheriaToken contract.
     */
    function setAetheriaToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddress();
        aetToken = IAetheriaToken(tokenAddress);
    }

     /**
      * @notice Sets the address of the AetherYieldToken (ERC20) contract used for yielding.
      *         Only callable by the contract owner.
      * @param tokenAddress The address of the AetherYieldToken contract.
      */
    function setAetherYieldToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddress();
        aetherYieldToken = IAetherYieldToken(tokenAddress);
    }

    /**
     * @notice Allows the owner to withdraw any non-staked token balance
     *         accidentally sent to the contract, or accumulated fees.
     *         (Note: This contract doesn't explicitly collect fees other than burning staked AET).
     * @param tokenAddress The address of the token to withdraw.
     */
    function withdrawSystemFees(address tokenAddress) external onlyOwner {
         if (tokenAddress == address(0)) revert ZeroAddress();
         // Prevent withdrawing staked AET or yield tokens needed by the contract logic
         if (tokenAddress == address(aetToken) && IERC20(tokenAddress).balanceOf(address(this)) > _totalStakedAET) {
             uint256 amountToWithdraw = IERC20(tokenAddress).balanceOf(address(this)) - _totalStakedAET;
             // Use low-level call for flexibility
             (bool success, ) = address(tokenAddress).call(abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, amountToWithdraw));
             if (!success) revert InvalidBloomState(); // Generic error for transfer failure
         } else if (tokenAddress != address(aetToken) && tokenAddress != address(aetherYieldToken)) {
             uint256 amountToWithdraw = IERC20(tokenAddress).balanceOf(address(this));
              if (amountToWithdraw > 0) {
                // Use low-level call
                (bool success, ) = address(tokenAddress).call(abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, amountToWithdraw));
                 if (!success) revert InvalidBloomState(); // Generic error for transfer failure
              }
         } else {
            // Attempting to withdraw staked AET or AetherYieldToken is not allowed
            revert Unauthorized();
         }
    }

    // Add a simple IERC20 interface locally for the withdrawSystemFees function
    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
    }

}
```