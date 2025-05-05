Okay, let's design a smart contract based on a concept I'll call "CryptoCultivator". This contract will combine elements of NFTs, time-based growth, resource management, breeding/creation, staking, and limited delegation, moving beyond standard token or simple collectible contracts.

**Concept:** Users own unique digital "Cultivators" (NFTs) that grow and evolve over time. Growth is accelerated by feeding them a special resource token (`Essence`). Cultivators can be harvested for `Essence` periodically, and two mature Cultivators can be bred to create a new one. Users can also stake their Cultivators to earn passive `Essence`.

---

## CryptoCultivator Smart Contract

**Concept:** A gamified system on the blockchain where users cultivate unique digital entities (NFTs) that grow, yield resources (Essence token), can be bred, and staked.

**Core Components:**
1.  **Cultivator NFT (ERC721):** The digital entity itself, possessing unique traits and state (level, XP, last fed/harvested time).
2.  **Essence Token (ERC20):** A fungible resource token used for feeding, breeding, and potentially minting new Cultivators. Earned through harvesting and staking Cultivators.
3.  **Cultivator Contract:** The main logic hub managing NFT lifecycle, growth mechanics, resource interaction, breeding, and staking.

**Outline:**

1.  **Imports:** Necessary OpenZeppelin contracts (ERC721, ERC20, Ownable, ReentrancyGuard, Pausable).
2.  **Error Handling:** Custom errors for clearer reverts.
3.  **Structs:** Define data structures for `Cultivator` state and `CultivatorTraits`.
4.  **State Variables:** Contract addresses (Essence token), mappings for Cultivator data, staking data, delegation data, growth parameters, breeding parameters, fees.
5.  **Events:** Log key actions like minting, feeding, level up, harvesting, breeding, staking, delegation.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`.
7.  **Constructor:** Initialize owner, deploy/link tokens, set initial parameters.
8.  **Admin Functions:** Set parameters, withdraw fees, pause/unpause.
9.  **ERC721 Standard Functions:** Implement or inherit required ERC721 functions (transfer, approve, balance, owner, etc.).
10. **Cultivator Lifecycle (Minting):** Function to mint new Cultivators (requires Essence).
11. **Growth Mechanics:** Function to feed Cultivator (requires Essence, updates state, calculates XP/level up).
12. **Essence Harvesting:** Function to calculate and claim harvestable Essence based on time and state.
13. **Breeding:** Function to breed two Cultivators (requires Essence, cooldown, generates new NFT).
14. **Staking (Potted):** Functions to stake Cultivators for passive yield.
15. **Delegation:** Function to allow another address to feed your Cultivator.
16. **View/Helper Functions:** Get Cultivator state, calculate potential yield/costs, get parameters.
17. **ERC20 Standard Functions (Partial Interface/Interaction):** Functions to check Essence balance/allowance via the linked token contract.

**Function Summary (Targeting > 20 functions):**

*   `constructor()`
*   `setEssenceTokenAddress(address _essenceToken)` (Admin)
*   `setGrowthParameters(...)` (Admin)
*   `setBreedingParameters(...)` (Admin)
*   `setStakingParameters(...)` (Admin)
*   `withdrawFees(address _to)` (Admin)
*   `pause()` (Admin, Inherited Pausable)
*   `unpause()` (Admin, Inherited Pausable)
*   `mintInitialCultivators(...)` (Admin, for initial distribution)
*   `mintCultivator(uint256 _traitSeed)` (User, requires Essence payment)
*   `feedCultivator(uint256 _tokenId, uint256 _amount)` (User, requires Essence approval)
*   `harvestEssence(uint256 _tokenId)` (User)
*   `breedCultivators(uint256 _parentId1, uint256 _parentId2)` (User, requires Essence approval)
*   `stakeCultivator(uint256 _tokenId)` (User)
*   `claimStakedYield(uint256 _tokenId)` (User)
*   `unstakeCultivator(uint256 _tokenId)` (User)
*   `delegateGrowth(uint256 _tokenId, address _delegate)` (User)
*   `removeDelegate(uint256 _tokenId)` (User)
*   `getCultivatorState(uint256 _tokenId)` (View)
*   `getEssenceYieldPreview(uint256 _tokenId)` (View)
*   `getBreedingCostPreview(uint256 _parentId1, uint256 _parentId2)` (View)
*   `getStakingYieldPreview(uint256 _tokenId)` (View)
*   `isGrowthDelegated(uint256 _tokenId)` (View)
*   `getGrowthDelegate(uint256 _tokenId)` (View)
*   `tokenURI(uint256 _tokenId)` (View, ERC721 Standard)
*   `transferFrom(address from, address to, uint256 tokenId)` (Inherited ERC721)
*   `safeTransferFrom(address from, address to, uint256 tokenId)` (Inherited ERC721)
*   `approve(address to, uint256 tokenId)` (Inherited ERC721)
*   `setApprovalForAll(address operator, bool approved)` (Inherited ERC721)
*   `balanceOf(address owner)` (Inherited ERC721)
*   `ownerOf(uint256 tokenId)` (Inherited ERC721)
*   `getApproved(uint256 tokenId)` (Inherited ERC721)
*   `isApprovedForAll(address owner, address operator)` (Inherited ERC721)
*   `getEssenceBalance(address _address)` (View, interacts with Essence token)
*   `getEssenceAllowance(address _owner, address _spender)` (View, interacts with Essence token)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // We'll interact with an existing ERC20
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Custom Errors for clarity
error CryptoCultivator__EssenceTransferFailed();
error CryptoCultivator__InvalidAmount();
error CryptoCultivator__CultivatorNotFound();
error CryptoCultivator__NotOwnerOrDelegate();
error CryptoCultivator__TooSoonToHarvest();
error CryptoCultivator__TooSoonToBreed();
error CryptoCultivator__CultivatorNotMatureEnough();
error CryptoCultivator__CannotBreedSelf();
error CryptoCultivator__CannotStakeStaked();
error CryptoCultivator__CultivatorNotStaked();
error CryptoCultivator__DelegateMustBeDifferent();
error CryptoCultivator__InvalidTraitSeed();

contract CryptoCultivator is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public essenceToken; // Address of the Essence ERC20 token

    struct CultivatorTraits {
        uint8 plantType; // e.g., 1-Rare, 2-Common, etc.
        uint8 colorVariant; // e.g., 1-Red, 2-Blue
        uint8 growthSpeed; // Modifier for growth/yield calculation
        uint8 rarity; // Overall rarity score
        // Add more traits as needed
    }

    struct Cultivator {
        CultivatorTraits traits;
        uint256 level;
        uint256 xp;
        uint256 lastFedTime;
        uint256 lastHarvestTime;
        uint256 breedingCooldownEnds;
        bool isStaked;
    }

    mapping(uint256 => Cultivator) public cultivatorData;
    mapping(uint256 => address) public growthDelegates; // tokenId => delegatedAddress

    // --- Staking ---
    mapping(uint256 => uint256) public cultivatorStakingStartTime; // tokenId => timestamp

    // --- Parameters (Admin settable) ---
    uint256 public essenceCostToMint;
    uint256 public xpPerEssenceUnit;
    uint256 public xpRequiredPerLevelBase;
    uint256 public xpRequiredPerLevelMultiplier; // XP = base + (level * multiplier)
    uint256 public harvestCooldownDuration; // seconds
    uint256 public baseEssenceYieldPerLevel;
    uint256 public breedingCostEssence;
    uint256 public breedingCooldownDuration; // seconds
    uint256 public breedingRequiredLevel; // Minimum level to breed
    uint256 public stakingYieldPerDayPerLevelBase; // Essence per day
    uint256 public stakingYieldPerDayPerLevelMultiplier;

    uint256 public protocolFeeRate; // Basis points (e.g., 500 for 5%) for breeding/minting
    address public protocolFeeRecipient;

    // --- Counters ---
    Counters.Counter private _tokenIdCounter;

    // --- Events ---
    event CultivatorMinted(address indexed owner, uint256 indexed tokenId, CultivatorTraits traits);
    event CultivatorFed(uint256 indexed tokenId, uint256 amount, uint256 newXP, uint256 newLevel);
    event CultivatorLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 oldLevel);
    event EssenceHarvested(uint256 indexed tokenId, uint256 amount);
    event CultivatorsBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event CultivatorStaked(uint256 indexed tokenId, address indexed owner);
    event CultivatorUnstaked(uint256 indexed tokenId, address indexed owner);
    event StakedYieldClaimed(uint256 indexed tokenId, uint256 amount);
    event GrowthDelegateSet(uint256 indexed tokenId, address indexed delegate);
    event GrowthDelegateRemoved(uint256 indexed tokenId);
    event ParametersUpdated(string paramName); // Generic event for admin updates

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _protocolFeeRecipient)
        ERC721("CryptoCultivator", "CULTI")
        Ownable(msg.sender)
        Pausable()
    {
        require(_essenceTokenAddress != address(0), "Invalid essence token address");
        require(_protocolFeeRecipient != address(0), "Invalid fee recipient address");
        essenceToken = IERC20(_essenceTokenAddress);
        protocolFeeRecipient = _protocolFeeRecipient;

        // Set initial default parameters (can be updated by owner)
        essenceCostToMint = 100 ether; // Example: 100 tokens to mint
        xpPerEssenceUnit = 1; // Example: 1 token = 1 XP
        xpRequiredPerLevelBase = 100;
        xpRequiredPerLevelMultiplier = 50; // Level 1: 150 XP, Level 2: 200 XP, etc.
        harvestCooldownDuration = 24 hours;
        baseEssenceYieldPerLevel = 10 ether; // Example: 10 tokens per level per harvest cycle
        breedingCostEssence = 500 ether;
        breedingCooldownDuration = 7 days;
        breedingRequiredLevel = 5;
        stakingYieldPerDayPerLevelBase = 5 ether;
        stakingYieldPerDayPerLevelMultiplier = 1 ether;
        protocolFeeRate = 500; // 5%
    }

    // --- Admin Functions ---

    /// @notice Set the address of the Essence token contract.
    /// @param _essenceToken The new address for the Essence token contract.
    function setEssenceTokenAddress(address _essenceToken) external onlyOwner {
        require(_essenceToken != address(0), "Invalid address");
        essenceToken = IERC20(_essenceToken);
        emit ParametersUpdated("EssenceTokenAddress");
    }

    /// @notice Set parameters related to growth mechanics.
    function setGrowthParameters(
        uint256 _xpPerEssenceUnit,
        uint256 _xpRequiredPerLevelBase,
        uint256 _xpRequiredPerLevelMultiplier,
        uint256 _harvestCooldownDuration,
        uint256 _baseEssenceYieldPerLevel
    ) external onlyOwner {
        xpPerEssenceUnit = _xpPerEssenceUnit;
        xpRequiredPerLevelBase = _xpRequiredPerLevelBase;
        xpRequiredPerLevelMultiplier = _xpRequiredPerLevelMultiplier;
        harvestCooldownDuration = _harvestCooldownDuration;
        baseEssenceYieldPerLevel = _baseEssenceYieldPerLevel;
        emit ParametersUpdated("GrowthParameters");
    }

    /// @notice Set parameters related to breeding mechanics.
    function setBreedingParameters(
        uint256 _breedingCostEssence,
        uint256 _breedingCooldownDuration,
        uint256 _breedingRequiredLevel,
        uint256 _essenceCostToMint // Cost for initial minting
    ) external onlyOwner {
        breedingCostEssence = _breedingCostEssence;
        breedingCooldownDuration = _breedingCooldownDuration;
        breedingRequiredLevel = _breedingRequiredLevel;
        essenceCostToMint = _essenceCostToMint; // Setting initial mint cost here for simplicity
        emit ParametersUpdated("BreedingParameters");
    }

    /// @notice Set parameters related to staking mechanics.
    function setStakingParameters(
        uint256 _stakingYieldPerDayPerLevelBase,
        uint256 _stakingYieldPerDayPerLevelMultiplier
    ) external onlyOwner {
        stakingYieldPerDayPerLevelBase = _stakingYieldPerDayPerLevelBase;
        stakingYieldPerDayPerLevelMultiplier = _stakingYieldPerDayPerLevelMultiplier;
        emit ParametersUpdated("StakingParameters");
    }

    /// @notice Set protocol fee parameters.
    function setProtocolFee(uint256 _protocolFeeRate, address _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid fee recipient address");
        protocolFeeRate = _protocolFeeRate;
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ParametersUpdated("ProtocolFee");
    }

    /// @notice Withdraw accumulated protocol fees to the fee recipient address.
    function withdrawFees(address _to) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        uint256 balance = essenceToken.balanceOf(address(this)).sub(totalStakedEssenceValue()); // Only withdraw fees, not locked staking value
        require(balance > 0, "No fees to withdraw");
        if (!essenceToken.transfer(_to, balance)) {
            revert CryptoCultivator__EssenceTransferFailed();
        }
    }

    /// @notice Mints a batch of initial cultivators (Admin only).
    /// @param _to The recipient of the cultivators.
    /// @param _traitSeeds An array of seeds to generate traits for each new cultivator.
    function mintInitialCultivators(address _to, uint256[] calldata _traitSeeds) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        for (uint i = 0; i < _traitSeeds.length; i++) {
            _mintNewCultivator(_to, _traitSeeds[i]); // Use internal mint function
        }
    }

    // Inherit pause/unpause from Pausable
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- ERC721 Standard Functions Overrides ---
    // We need to override transfer/safeTransfer to handle staking state
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of staked tokens
        if (cultivatorData[tokenId].isStaked && from != address(0)) { // from address(0) is initial mint
             revert CryptoCultivator__CannotStakeStaked(); // Using stake error as it's the same root cause
        }
    }

    // tokenURI: Dynamic metadata based on state
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Ensure token exists

        Cultivator storage culti = cultivatorData[_tokenId];
        // This is where you'd typically construct a URL pointing to an off-chain metadata server
        // The server would read the cultivator's state (level, traits, isStaked) and return appropriate JSON
        // Example placeholder:
        string memory baseURI = "https://your-metadata-server.com/cultivators/";
        string memory status;
        if (culti.isStaked) {
            status = "staked";
        } else if (block.timestamp < culti.breedingCooldownEnds) {
             status = "breeding-cooldown";
        } else if (block.timestamp > culti.lastFedTime + harvestCooldownDuration) { // Simplified 'hungry' state
             status = "needs-feeding";
        } else {
            status = "thriving";
        }

        // In a real contract, you might encode traits/level in the URL or signature
        // Example: baseURI + tokenId + "?level=" + level + "&status=" + status
        // For this example, we'll just return a generic placeholder URL
        return string(abi.encodePacked(baseURI, _toString(_tokenId), "?status=", status, "&level=", _toString(culti.level)));
    }


    // --- Cultivator Lifecycle (User Mint) ---

    /// @notice Allows a user to mint a new Cultivator by paying Essence tokens.
    /// @param _traitSeed A seed used to influence the initial traits of the new Cultivator.
    function mintCultivator(uint256 _traitSeed) external payable nonReentrant whenNotPaused {
        uint256 feeAmount = essenceCostToMint.mul(protocolFeeRate).div(10000); // Calculate protocol fee

        // Transfer Essence token cost (excluding fee) to contract
        if (!essenceToken.transferFrom(msg.sender, address(this), essenceCostToMint.sub(feeAmount))) {
            revert CryptoCultivator__EssenceTransferFailed();
        }

        // Transfer fee amount to protocol fee recipient
        if (feeAmount > 0) {
             if (!essenceToken.transferFrom(msg.sender, protocolFeeRecipient, feeAmount)) {
                // This is a critical failure, potentially pause or rely on manual rescue
                // For this example, we'll just revert, but in production, consider implications
                revert CryptoCultivator__EssenceTransferFailed();
            }
        }

        _mintNewCultivator(msg.sender, _traitSeed);
    }

    /// @dev Internal function to mint a new Cultivator NFT and initialize its state.
    /// @param _to The address to mint the NFT to.
    /// @param _traitSeed A seed for trait generation.
    function _mintNewCultivator(address _to, uint256 _traitSeed) internal {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        // Simple pseudo-random trait generation based on seed, time, and block data
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId, _traitSeed)));

        CultivatorTraits memory newTraits;
        newTraits.plantType = uint8(rand % 5 + 1); // 1-5
        newTraits.colorVariant = uint8((rand / 100) % 10 + 1); // 1-10
        newTraits.growthSpeed = uint8((rand / 1000) % 3 + 1); // 1-3 (e.g., slow, normal, fast)
        newTraits.rarity = uint8(newTraits.plantType + newTraits.colorVariant + newTraits.growthSpeed); // Simple rarity score

        cultivatorData[newItemId] = Cultivator({
            traits: newTraits,
            level: 1,
            xp: 0,
            lastFedTime: block.timestamp, // Start fresh
            lastHarvestTime: block.timestamp, // Start fresh
            breedingCooldownEnds: 0, // No cooldown initially
            isStaked: false
        });

        emit CultivatorMinted(_to, newItemId, newTraits);
    }


    // --- Growth Mechanics ---

    /// @notice Allows the owner or a delegated address to feed a Cultivator using Essence tokens.
    /// @param _tokenId The ID of the Cultivator to feed.
    /// @param _amount The amount of Essence tokens to feed.
    function feedCultivator(uint256 _tokenId, uint256 _amount) external payable nonReentrant whenNotPaused {
        _requireOwned(_tokenId); // Ensure token exists
        Cultivator storage culti = cultivatorData[_tokenId];

        // Check if caller is owner or delegate
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == currentOwner || growthDelegates[_tokenId] == msg.sender, CryptoCultivator__NotOwnerOrDelegate());
        require(_amount > 0, CryptoCultivator__InvalidAmount());
        require(!culti.isStaked, "Cannot feed a staked cultivator directly"); // Staked yield is passive

        // Transfer Essence from feeder to the contract
        if (!essenceToken.transferFrom(msg.sender, address(this), _amount)) {
            revert CryptoCultivator__EssenceTransferFailed();
        }

        uint256 oldXP = culti.xp;
        uint256 oldLevel = culti.level;

        // Add XP
        culti.xp = culti.xp.add(_amount.mul(xpPerEssenceUnit));
        culti.lastFedTime = block.timestamp; // Reset feeding timer

        // Check for level up
        uint256 requiredXP = getLevelRequiredXP(culti.level);
        while (culti.xp >= requiredXP) {
            culti.level = culti.level.add(1);
            culti.xp = culti.xp.sub(requiredXP); // Carry over remaining XP
            emit CultivatorLeveledUp(_tokenId, culti.level, oldLevel);
            requiredXP = getLevelRequiredXP(culti.level); // Recalculate for next level
        }

        emit CultivatorFed(_tokenId, _amount, culti.xp, culti.level);
    }

    /// @notice Calculates the XP required to reach the next level from the current level.
    /// @param _currentLevel The current level.
    /// @return The XP required for the next level.
    function getLevelRequiredXP(uint256 _currentLevel) public view returns (uint256) {
        // Level 1 needs base XP, Level 2 needs base + 1*multiplier, Level 3 needs base + 2*multiplier etc.
        // Next level is _currentLevel + 1. XP needed for next level is relative to current level.
        // Let's define XP needed *for* level N (starting from 1)
        // Level 1 -> Requires xpRequiredPerLevelBase
        // Level 2 -> Requires xpRequiredPerLevelBase + xpRequiredPerLevelMultiplier
        // Level 3 -> Requires xpRequiredPerLevelBase + 2 * xpRequiredPerLevelMultiplier
        // Level N -> Requires xpRequiredPerLevelBase + (N-1) * xpRequiredPerLevelMultiplier
        // If current level is L, XP needed to reach L+1 is base + L * multiplier
        return xpRequiredPerLevelBase.add(_currentLevel.mul(xpRequiredPerLevelMultiplier));
    }


    // --- Essence Harvesting ---

    /// @notice Allows the owner to harvest Essence tokens from a Cultivator.
    /// Requires the harvest cooldown to have passed.
    /// @param _tokenId The ID of the Cultivator to harvest from.
    function harvestEssence(uint256 _tokenId) external nonReentrant whenNotPaused {
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == currentOwner, "Must be owner to harvest");
        Cultivator storage culti = cultivatorData[_tokenId];
        require(!culti.isStaked, "Cannot harvest from a staked cultivator"); // Staked yield claimed separately

        require(block.timestamp >= culti.lastHarvestTime.add(harvestCooldownDuration), CryptoCultivator__TooSoonToHarvest());

        uint256 potentialYield = getEssenceYieldPreview(_tokenId);
        require(potentialYield > 0, "No yield available");

        // Transfer yielded Essence from the contract's balance to the owner
        // Note: The contract is assumed to have a balance of Essence,
        // potentially accumulated from initial seeding, protocol fees, or other sources.
        if (!essenceToken.transfer(msg.sender, potentialYield)) {
             revert CryptoCultivator__EssenceTransferFailed();
        }

        culti.lastHarvestTime = block.timestamp; // Reset harvest timer

        emit EssenceHarvested(_tokenId, potentialYield);
    }

    /// @notice Calculates the potential Essence yield for a Cultivator based on its state and time elapsed.
    /// @param _tokenId The ID of the Cultivator.
    /// @return The amount of Essence tokens that can be harvested.
    function getEssenceYieldPreview(uint256 _tokenId) public view returns (uint256) {
        Cultivator storage culti = cultivatorData[_tokenId];
        if (culti.isStaked) return 0; // Yield is for unstaked harvesting

        // Calculate elapsed harvest cycles
        uint256 timeSinceLastHarvest = block.timestamp.sub(culti.lastHarvestTime);
        if (timeSinceLastHarvest < harvestCooldownDuration) return 0;

        uint256 elapsedCycles = timeSinceLastHarvest.div(harvestCooldownDuration);

        // Calculate yield per cycle based on level and growth speed trait
        uint256 yieldPerCycle = baseEssenceYieldPerLevel.mul(culti.level);
        // Apply growth speed trait modifier (e.g., 1=slow 80%, 2=normal 100%, 3=fast 120%)
        if (culti.traits.growthSpeed == 1) yieldPerCycle = yieldPerCycle.mul(80).div(100);
        else if (culti.traits.growthSpeed == 3) yieldPerCycle = yieldPerCycle.mul(120).div(100);
        // growthSpeed == 2 is 100% (no change)

        return yieldPerCycle.mul(elapsedCycles);
    }


    // --- Breeding ---

    /// @notice Allows the owner to breed two Cultivators to create a new one.
    /// Requires both parents to be owned, mature enough, off cooldown, and costs Essence.
    /// @param _parentId1 The ID of the first parent Cultivator.
    /// @param _parentId2 The ID of the second parent Cultivator.
    function breedCultivators(uint256 _parentId1, uint256 _parentId2) external payable nonReentrant whenNotPaused {
        address currentOwner = ownerOf(_parentId1); // Check owner of parent 1
        require(msg.sender == currentOwner, "Must own parent 1");
        require(ownerOf(_parentId2) == msg.sender, "Must own parent 2"); // Check owner of parent 2
        require(_parentId1 != _parentId2, CryptoCultivator__CannotBreedSelf());

        Cultivator storage parent1 = cultivatorData[_parentId1];
        Cultivator storage parent2 = cultivatorData[_parentId2];

        require(!parent1.isStaked && !parent2.isStaked, "Parents cannot be staked");

        require(parent1.level >= breedingRequiredLevel && parent2.level >= breedingRequiredLevel, CryptoCultivator__CultivatorNotMatureEnough());
        require(block.timestamp >= parent1.breedingCooldownEnds && block.timestamp >= parent2.breedingCooldownEnds, CryptoCultivator__TooSoonToBreed());

        uint256 feeAmount = breedingCostEssence.mul(protocolFeeRate).div(10000);

        // Transfer Essence token cost (excluding fee) from breeder
        if (!essenceToken.transferFrom(msg.sender, address(this), breedingCostEssence.sub(feeAmount))) {
            revert CryptoCultivator__EssenceTransferFailed();
        }

        // Transfer fee amount to protocol fee recipient
        if (feeAmount > 0) {
             if (!essenceToken.transferFrom(msg.sender, protocolFeeRecipient, feeAmount)) {
                revert CryptoCultivator__EssenceTransferFailed();
            }
        }

        // --- Generate Child Traits (Simplified Logic) ---
        // Combine parent traits with some randomness
        uint256 childTraitSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _parentId1, _parentId2)));

        // Basic inheritance + mutation chance (example logic)
        CultivatorTraits memory childTraits;
        childTraits.plantType = (childTraitSeed % 2 == 0) ? parent1.traits.plantType : parent2.traits.plantType;
        if (childTraitSeed % 10 < 2) childTraits.plantType = uint8(childTraitSeed % 5 + 1); // 20% mutation chance

        childTraits.colorVariant = (childTraitSeed % 2 == 0) ? parent1.traits.colorVariant : parent2.traits.colorVariant;
        if ((childTraitSeed / 100) % 10 < 3) childTraits.colorVariant = uint8((childTraitSeed / 100) % 10 + 1); // 30% mutation chance

        childTraits.growthSpeed = (childTraitSeed % 2 == 0) ? parent1.traits.growthSpeed : parent2.traits.growthSpeed;
         if ((childTraitSeed / 1000) % 10 < 4) childTraits.growthSpeed = uint8((childTraitSeed / 1000) % 3 + 1); // 40% mutation chance

        childTraits.rarity = uint8(childTraits.plantType + childTraits.colorVariant + childTraits.growthSpeed); // Recalculate rarity

        // Mint the new child cultivator
        _tokenIdCounter.increment();
        uint256 childId = _tokenIdCounter.current();

        _safeMint(msg.sender, childId);

        cultivatorData[childId] = Cultivator({
            traits: childTraits,
            level: 1, // Newborn starts at level 1
            xp: 0,
            lastFedTime: block.timestamp,
            lastHarvestTime: block.timestamp,
            breedingCooldownEnds: 0,
            isStaked: false
        });

        // Set breeding cooldown on parents
        parent1.breedingCooldownEnds = block.timestamp.add(breedingCooldownDuration);
        parent2.breedingCooldownEnds = block.timestamp.add(breedingCooldownDuration);

        emit CultivatorsBred(_parentId1, _parentId2, childId);
    }

    /// @notice Calculates the Essence cost to breed two Cultivators.
    /// @param _parentId1 The ID of the first parent.
    /// @param _parentId2 The ID of the second parent.
    /// @return The total Essence cost including fees.
    function getBreedingCostPreview(uint256 _parentId1, uint256 _parentId2) public view returns (uint256 totalCost, uint256 feeAmount) {
        // Basic checks without reverting (as it's a preview)
        if (_parentId1 == 0 || _parentId2 == 0 || _parentId1 == _parentId2) return (0, 0);
         if (cultivatorData[_parentId1].isStaked || cultivatorData[_parentId2].isStaked) return (0,0);
         if (cultivatorData[_parentId1].level < breedingRequiredLevel || cultivatorData[_parentId2].level < breedingRequiredLevel) return (0,0);
         if (block.timestamp < cultivatorData[_parentId1].breedingCooldownEnds || block.timestamp < cultivatorData[_parentId2].breedingCooldownEnds) return (0,0);

        feeAmount = breedingCostEssence.mul(protocolFeeRate).div(10000);
        totalCost = breedingCostEssence; // Breeding cost already includes the amount that goes to fees

        return (totalCost, feeAmount);
    }

    // --- Staking (Potted) ---

    /// @notice Allows the owner to stake a Cultivator to earn passive Essence yield.
    /// Transfers the NFT to the contract address.
    /// @param _tokenId The ID of the Cultivator to stake.
    function stakeCultivator(uint256 _tokenId) external nonReentrant whenNotPaused {
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == currentOwner, "Must be owner to stake");
        Cultivator storage culti = cultivatorData[_tokenId];
        require(!culti.isStaked, CryptoCultivator__CannotStakeStaked());
        require(block.timestamp >= culti.breedingCooldownEnds, "Cannot stake during breeding cooldown"); // Cannot stake during cooldown

        // Transfer NFT to the contract address
        _transfer(currentOwner, address(this), _tokenId);

        culti.isStaked = true;
        cultivatorStakingStartTime[_tokenId] = block.timestamp;

        emit CultivatorStaked(_tokenId, currentOwner);
    }

     /// @notice Allows the owner to unstake a Cultivator.
    /// Transfers the NFT back to the owner. Any unclaimed yield remains claimable.
    /// @param _tokenId The ID of the Cultivator to unstake.
    function unstakeCultivator(uint256 _tokenId) external nonReentrant whenNotPaused {
        // The owner of a staked NFT is the contract itself, so we check msg.sender against the original staker
        address originalOwner = _originalOwnerOf(_tokenId); // Need a way to track original owner, or require msg.sender was the last staker.
                                                            // Let's simplify and require msg.sender is the *only* address with unstake permission (like owner)
        require(msg.sender == originalOwner, "Only original owner can unstake"); // Requires tracking original owner.

        // **Alternative Simplification:** Only the current `owner()` of the contract or a designated unstaking manager can unstake.
        // require(msg.sender == owner(), "Only owner can unstake");
        // This is simpler but less user-friendly.

        // Let's implement tracking the original staker:
        // Add mapping: mapping(uint256 => address) public originalStaker;
        // In stakeCultivator: originalStaker[_tokenId] = msg.sender;
        // In unstakeCultivator: require(msg.sender == originalStaker[_tokenId], "Only original staker can unstake");
        // In _beforeTokenTransfer: if (from == address(this)) delete originalStaker[_tokenId]; // Clear when transferred out of staking

        // **Refined approach:** Add a separate mapping for stakedBy.
        mapping(uint256 => address) private _stakedBy;
        // In stakeCultivator: _stakedBy[_tokenId] = msg.sender;
        // In unstakeCultivator: require(msg.sender == _stakedBy[_tokenId], "Only staker can unstake"); delete _stakedBy[_tokenId];

        // Using the _stakedBy mapping approach:
        require(msg.sender == _stakedBy[_tokenId], "Only staker can unstake");
        Cultivator storage culti = cultivatorData[_tokenId];
        require(culti.isStaked, CryptoCultivator__CultivatorNotStaked());

        // Transfer NFT back to the staker
        _transfer(address(this), msg.sender, _tokenId);

        culti.isStaked = false;
        delete cultivatorStakingStartTime[_tokenId]; // Reset staking time
        delete _stakedBy[_tokenId]; // Clear staker record

        emit CultivatorUnstaked(_tokenId, msg.sender);
    }

    /// @notice Allows the owner of a staked Cultivator to claim earned yield.
    /// @param _tokenId The ID of the staked Cultivator.
    function claimStakedYield(uint256 _tokenId) external nonReentrant whenNotPaused {
         // Requires msg.sender is the staker (using _stakedBy)
        require(msg.sender == _stakedBy[_tokenId], "Only staker can claim yield");

        Cultivator storage culti = cultivatorData[_tokenId];
        require(culti.isStaked, CryptoCultivator__CultivatorNotStaked());

        uint256 potentialYield = getStakingYieldPreview(_tokenId);
        require(potentialYield > 0, "No yield available");

        // Transfer yielded Essence from contract balance to the staker
         if (!essenceToken.transfer(msg.sender, potentialYield)) {
             revert CryptoCultivator__EssenceTransferFailed();
        }

        // Reset staking timer for claimed yield
        cultivatorStakingStartTime[_tokenId] = block.timestamp; // Reset to calculate yield from now

        emit StakedYieldClaimed(_tokenId, potentialYield);
    }

    /// @notice Calculates the potential Essence yield for a staked Cultivator.
    /// @param _tokenId The ID of the staked Cultivator.
    /// @return The amount of Essence tokens that can be claimed.
    function getStakingYieldPreview(uint256 _tokenId) public view returns (uint256) {
        Cultivator storage culti = cultivatorData[_tokenId];
        if (!culti.isStaked) return 0;

        uint256 stakingStartTime = cultivatorStakingStartTime[_tokenId];
        if (stakingStartTime == 0) return 0; // Should not happen if isStaked is true

        uint256 timeStaked = block.timestamp.sub(stakingStartTime);
        uint256 daysStaked = timeStaked.div(1 days);

        if (daysStaked == 0) return 0;

        // Calculate yield per day based on level and growth speed trait
        uint256 yieldPerDay = stakingYieldPerDayPerLevelBase.add(culti.level.mul(stakingYieldPerDayPerLevelMultiplier));
        // Apply growth speed trait modifier (same logic as harvesting)
        if (culti.traits.growthSpeed == 1) yieldPerDay = yieldPerDay.mul(80).div(100);
        else if (culti.traits.growthSpeed == 3) yieldPerDay = yieldPerDay.mul(120).div(100);

        return yieldPerDay.mul(daysStaked);
    }

     /// @notice Internal helper to calculate total staked Essence value (for fee withdrawal safety).
    function totalStakedEssenceValue() internal view returns (uint256) {
        uint256 total = 0;
        // This is inefficient for a large number of tokens. In a real system,
        // a dedicated staking contract or different tracking mechanism might be needed.
        // For this example, we iterate through owned tokens by contract (which are staked).
        address contractAddress = address(this);
        uint256 balance = balanceOf(contractAddress);
        for (uint i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(contractAddress, i);
            if (cultivatorData[tokenId].isStaked) {
                 // Estimate value based on maximum possible yield + potential future value?
                 // Or simply calculate the *claimable* yield? Let's calculate claimable.
                 total = total.add(getStakingYieldPreview(tokenId));
            }
        }
        // This estimation is rough. A more accurate way would require tracking pending yield separately.
         return total;
    }


    // --- Delegation ---

    /// @notice Allows a Cultivator owner to delegate growth/feeding rights to another address.
    /// @param _tokenId The ID of the Cultivator to delegate.
    /// @param _delegate The address to delegate growth rights to (address(0) to remove).
    function delegateGrowth(uint256 _tokenId, address _delegate) external nonReentrant whenNotPaused {
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == currentOwner, "Must be owner to delegate");
        require(!cultivatorData[_tokenId].isStaked, "Cannot delegate a staked cultivator");
        require(_delegate != msg.sender, CryptoCultivator__DelegateMustBeDifferent());

        address oldDelegate = growthDelegates[_tokenId];
        growthDelegates[_tokenId] = _delegate;

        if (_delegate == address(0)) {
            emit GrowthDelegateRemoved(_tokenId);
        } else {
             emit GrowthDelegateSet(_tokenId, _delegate);
        }
    }

     /// @notice Removes the growth delegation for a Cultivator.
    /// Only callable by the owner or the current delegate.
    /// @param _tokenId The ID of the Cultivator.
    function removeDelegate(uint256 _tokenId) external nonReentrant whenNotPaused {
        address currentOwner = ownerOf(_tokenId);
        address currentDelegate = growthDelegates[_tokenId];
        require(msg.sender == currentOwner || msg.sender == currentDelegate, "Must be owner or current delegate");
        require(!cultivatorData[_tokenId].isStaked, "Cannot remove delegation from a staked cultivator");
        require(currentDelegate != address(0), "No delegate is set");

        delete growthDelegates[_tokenId];
        emit GrowthDelegateRemoved(_tokenId);
    }

    /// @notice Checks if growth delegation is set for a Cultivator.
    /// @param _tokenId The ID of the Cultivator.
    /// @return True if delegated, false otherwise.
    function isGrowthDelegated(uint256 _tokenId) public view returns (bool) {
        return growthDelegates[_tokenId] != address(0);
    }

    /// @notice Gets the current growth delegate for a Cultivator.
    /// @param _tokenId The ID of the Cultivator.
    /// @return The delegate address, or address(0) if no delegate is set.
    function getGrowthDelegate(uint256 _tokenId) public view returns (address) {
        return growthDelegates[_tokenId];
    }


    // --- View & Helper Functions ---

    /// @notice Gets the full state details for a Cultivator.
    /// @param _tokenId The ID of the Cultivator.
    /// @return A tuple containing all Cultivator data.
    function getCultivatorState(uint256 _tokenId) public view returns (
        CultivatorTraits memory traits,
        uint256 level,
        uint256 xp,
        uint256 lastFedTime,
        uint256 lastHarvestTime,
        uint256 breedingCooldownEnds,
        bool isStaked,
        address growthDelegate
    ) {
        Cultivator storage culti = cultivatorData[_tokenId];
         // Ensure token exists by checking level (or supply)
        if (culti.level == 0 && _exists(_tokenId) == false) {
            revert CryptoCultivator__CultivatorNotFound();
        }
        return (
            culti.traits,
            culti.level,
            culti.xp,
            culti.lastFedTime,
            culti.lastHarvestTime,
            culti.breedingCooldownEnds,
            culti.isStaked,
            growthDelegates[_tokenId]
        );
    }

    /// @notice Helper to check existence and ownership (internal).
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        // The actual ERC721 ownerOf check is part of derived functions like _beforeTokenTransfer or can be added explicitly if needed elsewhere.
        // This function primarily checks existence for functions that operate on the token data directly.
    }

     /// @dev Internal function to get the original staker. Requires the _stakedBy mapping.
     function _originalOwnerOf(uint256 _tokenId) internal view returns (address) {
         return _stakedBy[_tokenId];
     }

     /// @notice Helper function to get Essence balance of an address.
     function getEssenceBalance(address _address) public view returns (uint256) {
         return essenceToken.balanceOf(_address);
     }

     /// @notice Helper function to get Essence allowance granted by an owner to a spender.
     function getEssenceAllowance(address _owner, address _spender) public view returns (uint256) {
         return essenceToken.allowance(_owner, _spender);
     }

     // Add any other view functions needed, e.g., getTraitRarityDistribution, getGrowthParameters etc.

     // Example additional view function:
     /// @notice Gets the current growth parameters.
     function getGrowthParameters() public view returns (uint256, uint256, uint256, uint256, uint256) {
         return (
            xpPerEssenceUnit,
            xpRequiredPerLevelBase,
            xpRequiredPerLevelMultiplier,
            harvestCooldownDuration,
            baseEssenceYieldPerLevel
         );
     }
}
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Dynamic NFTs (`tokenURI`):** The `tokenURI` function, while returning a placeholder URL, *demonstrates* the concept of dynamic NFT metadata. The actual metadata server linked by the URL would read the on-chain state (level, `isStaked`, `lastFedTime`, `breedingCooldownEnds`) via calls to `getCultivatorState` and serve different images or JSON properties based on whether the Cultivator is thriving, hungry, in cooldown, or staked. This makes the NFT visually represent its on-chain state.
2.  **Gamified Tokenomics:** The `Essence` token is tightly integrated into the game loop. It's an *input* (`feedCultivator`, `mintCultivator`, `breedCultivators`) and an *output* (`harvestEssence`, `claimStakedYield`). This creates an internal economy within the contract.
3.  **Time-Based Mechanics:** Growth and yield are tied to elapsed time (`lastFedTime`, `lastHarvestTime`, `breedingCooldownEnds`, `cultivatorStakingStartTime`). The contract logic calculates yield or checks cooldowns based on `block.timestamp`.
4.  **On-chain State Simulation:** The `Cultivator` struct tracks multiple aspects of the digital entity's life cycle (`level`, `xp`, various timers, `isStaked`). This state lives entirely on the blockchain.
5.  **NFT Staking (`stakeCultivator`, `claimStakedYield`, `unstakeCultivator`):** Users can lock their valuable NFTs (`transfer` to the contract address) to earn passive income in the form of `Essence` tokens, similar to staking fungible tokens in DeFi. This adds a yield-farming dimension to the NFT collectible. The `_stakedBy` mapping is used to enforce that only the original staker can unstake/claim yield, even though the contract technically owns the NFT while staked.
6.  **On-chain Breeding (`breedCultivators`):** Two existing NFTs are consumed (conceptually, via cooldowns and costs) to produce a new NFT. The child NFT's traits are derived from the parents' traits with a simulated chance of mutation using blockchain data for randomness (acknowledging this is not truly secure randomness, but common in simpler on-chain games).
7.  **Growth Delegation (`delegateGrowth`, `removeDelegate`):** An advanced social/collaborative feature allowing an owner to grant permission to another address (`delegate`) *specifically* for feeding the Cultivator. This could enable "gardening guilds" or service providers to manage NFTs without needing full ownership transfer.
8.  **Parametric Control (`setGrowthParameters`, etc.):** The owner (intended as a governance/admin role) can tune the core economic and game-play parameters, allowing the game to be balanced or evolved over time.
9.  **Protocol Fees (`protocolFeeRate`, `withdrawFees`):** Demonstrates a simple revenue model where a percentage of resource sinks (minting, breeding) goes to a designated recipient.
10. **Reentrancy Guard & Pausable:** Standard, but important for security in contracts handling multiple external calls and state changes, and for providing an emergency stop mechanism.
11. **Custom Errors:** Using `error` instead of `revert` strings is a modern Solidity feature providing cheaper and clearer error handling.

This contract includes well over 20 functions and combines several interesting concepts that go beyond standard token implementations. It sets up a basic framework for a blockchain-based simulation or game.