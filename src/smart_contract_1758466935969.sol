Here's a Solidity smart contract named "ChronoForge" that implements an advanced, creative, and trendy concept: **Adaptive Digital Assets with Inter-Core Influence and Ecosystemic Feedback Loops.**

The core idea is a dynamic NFT (ChronoCore) whose attributes (Energy, Adaptation Score, Rarity Factor, Influence Potency) evolve over time through decay, are boosted by user-bonded "catalyst" tokens, and can be programmatically influenced by *other* ChronoCores. The entire ecosystem also has a "pulse" that affects all assets, simulating a dynamic environment.

---

**Outline and Function Summary:**

**I. Core ChronoCore Management:**
1.  `createChronoCore()`: Mints a new ChronoCore NFT, initializing its dynamic attributes with pseudo-random values.
2.  `getChronoCoreDetails(tokenId)`: Returns all current dynamic attributes (energy, adaptation score, etc.) of a specific ChronoCore.
3.  `bondCatalystToCore(tokenId, catalystTokenAddress, amount)`: Allows a ChronoCore owner to bond specified ERC20 tokens as "catalysts." These catalysts are transferred to the contract and provide a boost to the core's attributes.
4.  `extractCatalystFromCore(tokenId, catalystTokenAddress, amount)`: Allows a ChronoCore owner to unbond previously bonded catalysts, returning them to the owner and potentially reducing the core's boosted attributes.
5.  `_updateCoreStateInternal(tokenId)`: An *internal* helper function. It's called before any major interaction with a ChronoCore to apply time-based decay/rejuvenation and update its `lastUpdateBlock`. This ensures all operations are on up-to-date core states.
6.  `evolveCoreAttribute(tokenId, attributeId, value)`: An administrative function (or one accessible via special catalysts) to directly programmatically evolve specific attributes of a ChronoCore (e.g., boosting energy or adaptation).
7.  `retireChronoCore(tokenId)`: Allows a ChronoCore owner to retire their NFT. This burns the NFT, returns any bonded catalysts, and could conceptually yield a final reward based on its final state.

**II. Ecosystem & Global State Management:**
8.  `setGlobalDecayRate(newRate)`: An administrative function to adjust the global decay rate that affects all ChronoCores' attributes over time.
9.  `setCatalystEffectiveness(catalystTokenAddress, effectivenessFactor)`: An administrative function to configure how strongly a specific allowed ERC20 catalyst token impacts ChronoCore attributes.
10. `triggerEnvironmentalShift()`: An administrative function to trigger a "shift" in the ecosystem. This changes the global `environmentalPulse`, which can subtly influence all ChronoCores' decay/rejuvenation dynamics.
11. `getGlobalEcosystemState()`: Returns the current global ecosystem parameters, including decay rate, last shift time, environmental pulse, and total active cores.
12. `addAllowedCatalystToken(tokenAddress)`: An administrative function to whitelist new ERC20 tokens that can be used as catalysts within the ChronoForge system.
13. `removeAllowedCatalystToken(tokenAddress)`: An administrative function to deregister an ERC20 token, preventing it from being used as a catalyst.
14. `getAllowedCatalystTokens()`: A view function to list all currently whitelisted catalyst token addresses. (Note: for large lists, this would need a more robust implementation than a simple array in production).

**III. Inter-Core Influence & Interaction:**
15. `projectInfluence(sourceCoreId, targetCoreId, influencePower)`: Allows a ChronoCore owner to use their `sourceCoreId` to project influence onto a `targetCoreId`. This interaction is governed by the source's `influencePotency`, target's `adaptationScore`, and the overall `environmentalPulse`. A small fee is paid to the system.
16. `getInfluenceLog(tokenId)`: Returns a log of recent influence events that have targeted a specific ChronoCore, detailing the source, target, timestamp, and net effect.
17. `claimInfluenceBounty(targetCoreId, influenceLogIndex)`: Allows an owner whose ChronoCore was *positively influenced* to claim a conceptual bounty from the system (representing a reward for successful development/interaction).
18. `contestInfluence(targetCoreId, influenceLogIndex)`: Allows a ChronoCore owner to attempt to counteract or mitigate a recent influence event on their core. This requires burning some of the core's energy/adaptation and paying a fee.

**IV. Administrative & Utility:**
19. `pauseSystem()`: An emergency administrative function to pause critical operations of the contract.
20. `unpauseSystem()`: An emergency administrative function to unpause the contract.
21. `setChronoForgeFeeReceiver(newReceiver)`: An administrative function to update the address where contract fees (e.g., from influence projections) are sent.
22. `withdrawCollectedFees(tokenAddress)`: An administrative function to withdraw any collected ERC20 fees (or native token fees accidentally sent) from the contract.
23. `getTotalActiveChronoCores()`: Returns the total count of currently active (non-retired) ChronoCores in the ecosystem.
24. `getCoreOwner(tokenId)`: A standard ERC721 wrapper function to get the owner of a ChronoCore.
25. `setBaseURI(newBaseURI)`: An administrative function to set the base URI for NFT metadata, allowing for dynamic metadata updates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:
//
// I. Core ChronoCore Management:
//    1. createChronoCore(): Mints a new ChronoCore NFT, initializing its dynamic attributes.
//    2. getChronoCoreDetails(tokenId): Returns all current dynamic attributes of a ChronoCore.
//    3. bondCatalystToCore(tokenId, catalystTokenAddress, amount): Allows owner to bond ERC20 tokens as catalysts, boosting attributes.
//    4. extractCatalystFromCore(tokenId, catalystTokenAddress, amount): Allows owner to unbond catalysts, potentially reducing boosts.
//    5. _updateCoreStateInternal(tokenId): Internal function, applies time-based decay/rejuvenation and updates lastUpdateBlock.
//    6. evolveCoreAttribute(tokenId, attributeId, value): Admin/special catalyst function to programmatically evolve specific attributes.
//    7. retireChronoCore(tokenId): Allows owner to retire a ChronoCore, burning the NFT and potentially yielding a reward.
//
// II. Ecosystem & Global State Management:
//    8. setGlobalDecayRate(newRate): Admin function to adjust the global decay rate affecting all ChronoCores.
//    9. setCatalystEffectiveness(catalystTokenAddress, effectivenessFactor): Admin function to configure how strongly a specific ERC20 catalyst impacts ChronoCore attributes.
//    10. triggerEnvironmentalShift(): Admin function to trigger a "shift" in the ecosystem, changing environmentalPulse.
//    11. getGlobalEcosystemState(): Returns the current global state variables.
//    12. addAllowedCatalystToken(tokenAddress): Admin function to register new ERC20 tokens that can be used as catalysts.
//    13. removeAllowedCatalystToken(tokenAddress): Admin function to deregister catalyst tokens.
//    14. getAllowedCatalystTokens(): View function to list all currently allowed catalyst token addresses.
//
// III. Inter-Core Influence & Interaction:
//    15. projectInfluence(sourceCoreId, targetCoreId, influencePower): Allows a ChronoCore owner to use their sourceCoreId to influence targetCoreId.
//    16. getInfluenceLog(tokenId): Returns a log of recent influence events for a specific ChronoCore.
//    17. claimInfluenceBounty(targetCoreId, influenceLogIndex): Allows an owner whose core was positively influenced to claim a bounty.
//    18. contestInfluence(targetCoreId, influenceLogIndex): Allows a ChronoCore owner to attempt to counteract a recent influence event.
//
// IV. Administrative & Utility:
//    19. pauseSystem(): Emergency function to pause critical contract operations.
//    20. unpauseSystem(): Emergency function to unpause the contract.
//    21. setChronoForgeFeeReceiver(newReceiver): Admin function to update the address where contract fees are sent.
//    22. withdrawCollectedFees(tokenAddress): Admin function to withdraw any collected ERC20 fees from the contract.
//    23. getTotalActiveChronoCores(): Returns the total count of currently active (non-retired) ChronoCores.
//    24. getCoreOwner(tokenId): Returns the owner of a ChronoCore (wrapper for ERC721 ownerOf).
//    25. setBaseURI(newBaseURI): Admin function to set the base URI for NFT metadata.

contract ChronoForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    // Represents a single ChronoCore NFT with dynamic attributes
    struct ChronoCoreState {
        uint256 creationTime;           // Block timestamp of creation
        uint256 energyLevel;            // Affects potential, decays over time, max 10000
        uint256 adaptationScore;        // Reflects resilience and evolution, boosted by catalysts, can decay, max 10000
        uint256 rarityFactor;           // Base rarity, can be slightly influenced, max 10000
        uint256 influencePotency;       // How strongly this core can influence others, max 10000
        uint256 lastUpdateBlock;        // Block number of the last update to calculate decay
        mapping(address => uint256) bondedCatalysts; // Specific catalysts (ERC20 address => amount)
    }

    // Log for influence events
    struct InfluenceEvent {
        uint256 sourceCoreId;
        uint256 targetCoreId;
        uint256 timestamp;
        int256 netInfluenceApplied; // Positive for boost, negative for decay
        bool contested;
        bool claimedBounty;
    }

    // Global ecosystem parameters
    struct EcosystemParams {
        uint256 globalDecayRate;        // Rate at which attributes decay per block, e.g., 10 units per 1000 blocks
        uint256 lastShiftBlock;         // Last block an environmental shift occurred
        uint256 environmentalPulse;     // A dynamic value representing the "mood" of the ecosystem, 0-10000
        uint256 totalActiveCores;       // Count of currently active ChronoCores
    }

    // --- State Variables ---

    mapping(uint256 => ChronoCoreState) public chronoCores;
    mapping(uint256 => InfluenceEvent[]) public coreInfluenceLogs; // targetCoreId => list of events

    mapping(address => uint256) public catalystEffectiveness; // ERC20 token address => effectiveness factor
    mapping(address => bool) public allowedCatalystTokens; // Whitelist of allowed catalysts
    address[] private _allowedCatalystTokensList; // To efficiently retrieve the list

    EcosystemParams public ecosystemParams;

    address public feeReceiver;
    mapping(address => uint256) public collectedFeesERC20; // For various ERC20 tokens collected

    // --- Events ---

    event ChronoCoreCreated(uint256 indexed tokenId, address indexed owner, uint256 creationTime);
    event CatalystBonded(uint256 indexed tokenId, address indexed catalystToken, uint256 amount, uint256 newEnergyLevel, uint256 newAdaptationScore);
    event CatalystExtracted(uint256 indexed tokenId, address indexed catalystToken, uint256 amount, uint256 newEnergyLevel, uint256 newAdaptationScore);
    event CoreStateUpdated(uint256 indexed tokenId, uint256 newEnergy, uint256 newAdaptation, uint256 newRarity, uint256 newPotency);
    event ChronoCoreRetired(uint256 indexed tokenId, address indexed owner, uint256 finalRewardScore);
    event EnvironmentalShiftTriggered(uint256 newPulse, uint256 lastShiftBlock);
    event InfluenceProjected(uint256 indexed sourceCoreId, uint256 indexed targetCoreId, int256 netInfluence, uint256 influenceLogIndex);
    event InfluenceContested(uint256 indexed targetCoreId, uint256 indexed influenceLogIndex);
    event InfluenceBountyClaimed(uint256 indexed targetCoreId, uint256 indexed influenceLogIndex, uint256 bountyAmount);
    event ChronoForgeFeeCollected(address indexed token, uint256 amount);

    // --- Constructor ---

    constructor(address initialFeeReceiver)
        ERC721("ChronoForge", "CHRONO")
        Ownable(msg.sender)
    {
        require(initialFeeReceiver != address(0), "Invalid fee receiver address");
        feeReceiver = initialFeeReceiver;

        // Initialize ecosystem parameters
        ecosystemParams = EcosystemParams({
            globalDecayRate: 10, // Default decay of 10 units per 1000 blocks for attributes
            lastShiftBlock: block.number,
            environmentalPulse: 5000, // Mid-range initial pulse (0-10000)
            totalActiveCores: 0
        });
    }

    // --- Modifiers ---

    modifier onlyChronoCoreOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _;
    }

    // --- Helper Internal Functions ---

    /**
     * @dev Applies time-based decay and rejuvenation to a ChronoCore's attributes.
     *      This function should be called before any interaction with a ChronoCore to ensure its state is current.
     * @param tokenId The ID of the ChronoCore to update.
     */
    function _updateCoreStateInternal(uint256 tokenId) internal {
        ChronoCoreState storage core = chronoCores[tokenId];
        require(core.creationTime != 0, "ChronoCore does not exist");

        uint256 blocksPassed = block.number - core.lastUpdateBlock;
        if (blocksPassed == 0) return; // No update needed if no blocks passed

        // Decay calculation: Basic linear decay, could be more complex (e.g., sqrt, log)
        uint256 decayAmount = (ecosystemParams.globalDecayRate * blocksPassed) / 1000; // e.g., 10 units per 1000 blocks

        core.energyLevel = (core.energyLevel > decayAmount) ? core.energyLevel - decayAmount : 0;
        core.adaptationScore = (core.adaptationScore > decayAmount / 2) ? core.adaptationScore - decayAmount / 2 : 0; // Adaptation decays slower

        // Rejuvenation: The environmental pulse slightly counteracts decay.
        // If environmentalPulse is above 5000 (mid-point), it gives a positive boost.
        if (ecosystemParams.environmentalPulse > 5000) {
            uint256 rejuvenationBoost = (ecosystemParams.environmentalPulse - 5000) * blocksPassed / 100000; // Small boost per block
            core.energyLevel = Math.min(core.energyLevel + rejuvenationBoost, 10000);
            core.adaptationScore = Math.min(core.adaptationScore + (rejuvenationBoost / 2), 10000);
        }

        // Ensure attributes don't exceed max or fall below 0
        core.energyLevel = Math.min(core.energyLevel, 10000);
        core.adaptationScore = Math.min(core.adaptationScore, 10000);
        core.rarityFactor = Math.min(core.rarityFactor, 10000);
        core.influencePotency = Math.min(core.influencePotency, 10000);

        core.lastUpdateBlock = block.number;
        emit CoreStateUpdated(tokenId, core.energyLevel, core.adaptationScore, core.rarityFactor, core.influencePotency);
    }

    // --- I. Core ChronoCore Management ---

    /**
     * @dev Mints a new ChronoCore NFT, initializing its dynamic attributes.
     *      Attributes are pseudo-randomly generated based on block data and sender.
     * @return The ID of the newly created ChronoCore.
     */
    function createChronoCore() public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Initial attributes: randomized within a range for uniqueness
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));

        chronoCores[newTokenId] = ChronoCoreState({
            creationTime: block.timestamp,
            energyLevel: (initialSeed % 2000) + 4000, // 4000-6000 initial energy
            adaptationScore: (initialSeed % 1500) + 3500, // 3500-5000 initial adaptation
            rarityFactor: (initialSeed % 1000) + 2000, // 2000-3000 initial rarity
            influencePotency: (initialSeed % 1000) + 2000, // 2000-3000 initial potency
            lastUpdateBlock: block.number,
            bondedCatalysts: new mapping(address => uint256)() // Initialize empty mapping
        });

        _mint(msg.sender, newTokenId);
        _updateCoreStateInternal(newTokenId); // Ensure state is fresh immediately after creation
        ecosystemParams.totalActiveCores++;
        emit ChronoCoreCreated(newTokenId, msg.sender, block.timestamp);
        return newTokenId;
    }

    /**
     * @dev Returns all current dynamic attributes of a ChronoCore.
     *      Note: This is a view function and does not call `_updateCoreStateInternal`,
     *      so the values may be slightly outdated until a state-modifying function is called.
     * @param tokenId The ID of the ChronoCore.
     * @return A tuple containing (creationTime, energyLevel, adaptationScore, rarityFactor, influencePotency, lastUpdateBlock).
     */
    function getChronoCoreDetails(uint256 tokenId)
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        ChronoCoreState storage core = chronoCores[tokenId];
        require(core.creationTime != 0, "ChronoCore does not exist");
        return (
            core.creationTime,
            core.energyLevel,
            core.adaptationScore,
            core.rarityFactor,
            core.influencePotency,
            core.lastUpdateBlock
        );
    }

    /**
     * @dev Allows owner to bond ERC20 tokens as catalysts, boosting attributes.
     *      Catalyst tokens are transferred from the owner to the contract and recorded against the core.
     * @param tokenId The ID of the ChronoCore.
     * @param catalystTokenAddress The address of the ERC20 catalyst token.
     * @param amount The amount of catalyst to bond.
     */
    function bondCatalystToCore(uint256 tokenId, address catalystTokenAddress, uint256 amount)
        public
        whenNotPaused
        onlyChronoCoreOwner(tokenId)
    {
        require(amount > 0, "Bond amount must be greater than zero");
        require(allowedCatalystTokens[catalystTokenAddress], "Catalyst token not allowed");
        require(catalystEffectiveness[catalystTokenAddress] > 0, "Catalyst has no effectiveness set");

        _updateCoreStateInternal(tokenId); // Ensure core state is fresh before bonding
        ChronoCoreState storage core = chronoCores[tokenId];

        // Transfer catalyst tokens to contract
        IERC20(catalystTokenAddress).transferFrom(_msgSender(), address(this), amount);

        core.bondedCatalysts[catalystTokenAddress] += amount;

        // Apply boost based on catalyst effectiveness
        uint256 boost = amount * catalystEffectiveness[catalystTokenAddress] / 100; // Divide by 100 for scaling

        core.energyLevel = Math.min(core.energyLevel + boost, 10000);
        core.adaptationScore = Math.min(core.adaptationScore + (boost / 2), 10000); // Adaptation gets half the boost
        core.rarityFactor = Math.min(core.rarityFactor + (boost / 10), 10000); // Minor boost to rarity
        core.influencePotency = Math.min(core.influencePotency + (boost / 5), 10000); // Minor boost to potency

        emit CatalystBonded(tokenId, catalystTokenAddress, amount, core.energyLevel, core.adaptationScore);
    }

    /**
     * @dev Allows owner to unbond catalysts, potentially reducing boosts.
     *      Unbonded catalyst tokens are transferred back to the owner.
     * @param tokenId The ID of the ChronoCore.
     * @param catalystTokenAddress The address of the ERC20 catalyst token.
     * @param amount The amount of catalyst to extract.
     */
    function extractCatalystFromCore(uint256 tokenId, address catalystTokenAddress, uint256 amount)
        public
        whenNotPaused
        onlyChronoCoreOwner(tokenId)
    {
        require(amount > 0, "Extract amount must be greater than zero");
        require(allowedCatalystTokens[catalystTokenAddress], "Catalyst token not allowed");

        _updateCoreStateInternal(tokenId); // Ensure core state is fresh before extracting
        ChronoCoreState storage core = chronoCores[tokenId];

        require(core.bondedCatalysts[catalystTokenAddress] >= amount, "Not enough catalyst bonded");

        core.bondedCatalysts[catalystTokenAddress] -= amount;

        // Apply reduction to attributes
        uint224 reduction = uint224(amount * catalystEffectiveness[catalystTokenAddress] / 100);

        core.energyLevel = (core.energyLevel > reduction) ? core.energyLevel - reduction : 0;
        core.adaptationScore = (core.adaptationScore > reduction / 2) ? core.adaptationScore - (reduction / 2) : 0;
        core.rarityFactor = (core.rarityFactor > reduction / 10) ? core.rarityFactor - (reduction / 10) : 0;
        core.influencePotency = (core.influencePotency > reduction / 5) ? core.influencePotency - (reduction / 5) : 0;

        // Transfer catalyst tokens back to owner
        IERC20(catalystTokenAddress).transfer(_msgSender(), amount);

        emit CatalystExtracted(tokenId, catalystTokenAddress, amount, core.energyLevel, core.adaptationScore);
    }

    /**
     * @dev Allows admin or special role to programmatically evolve specific attributes of a ChronoCore.
     *      Attribute IDs: 0: energy, 1: adaptation, 2: rarity, 3: potency.
     * @param tokenId The ID of the ChronoCore.
     * @param attributeId The ID of the attribute to modify.
     * @param value The value to add (positive).
     */
    function evolveCoreAttribute(uint256 tokenId, uint8 attributeId, uint256 value)
        public
        whenNotPaused
        onlyOwner // Or a dedicated `OPERATOR` role for fine-grained control
    {
        require(chronoCores[tokenId].creationTime != 0, "ChronoCore does not exist");
        _updateCoreStateInternal(tokenId);
        ChronoCoreState storage core = chronoCores[tokenId];

        if (attributeId == 0) { // Energy
            core.energyLevel = Math.min(core.energyLevel + value, 10000);
        } else if (attributeId == 1) { // Adaptation
            core.adaptationScore = Math.min(core.adaptationScore + value, 10000);
        } else if (attributeId == 2) { // Rarity
            core.rarityFactor = Math.min(core.rarityFactor + value, 10000);
        } else if (attributeId == 3) { // Influence Potency
            core.influencePotency = Math.min(core.influencePotency + value, 10000);
        } else {
            revert("Invalid attribute ID");
        }
        emit CoreStateUpdated(tokenId, core.energyLevel, core.adaptationScore, core.rarityFactor, core.influencePotency);
    }

    /**
     * @dev Allows owner to retire a ChronoCore, burning the NFT and potentially yielding a final reward.
     *      Before retiring, all bonded catalysts are returned to the owner.
     * @param tokenId The ID of the ChronoCore to retire.
     */
    function retireChronoCore(uint256 tokenId)
        public
        whenNotPaused
        onlyChronoCoreOwner(tokenId)
    {
        _updateCoreStateInternal(tokenId);
        ChronoCoreState storage core = chronoCores[tokenId];

        // Return all bonded catalysts to the owner
        address[] memory allowed = _allowedCatalystTokensList;
        for (uint256 i = 0; i < allowed.length; i++) {
            address catalystToken = allowed[i];
            if (core.bondedCatalysts[catalystToken] > 0) {
                IERC20(catalystToken).transfer(_msgSender(), core.bondedCatalysts[catalystToken]);
                core.bondedCatalysts[catalystToken] = 0; // Clear record
            }
        }

        // Calculate a final reward score (conceptual, for demonstration)
        uint256 finalRewardScore = core.adaptationScore / 100; // Simplified
        // In a real system, this would trigger a token transfer (e.g., native project token).

        _burn(tokenId);
        delete chronoCores[tokenId]; // Remove from storage
        ecosystemParams.totalActiveCores--;

        emit ChronoCoreRetired(tokenId, _msgSender(), finalRewardScore);
    }

    // --- II. Ecosystem & Global State Management ---

    /**
     * @dev Admin function to adjust the global decay rate affecting all ChronoCores.
     * @param newRate The new decay rate (e.g., 10 for 10 units per 1000 blocks).
     */
    function setGlobalDecayRate(uint256 newRate) public onlyOwner {
        ecosystemParams.globalDecayRate = newRate;
    }

    /**
     * @dev Admin function to configure how strongly a specific ERC20 catalyst impacts ChronoCore attributes.
     * @param catalystTokenAddress The address of the ERC20 catalyst token.
     * @param effectivenessFactor The factor by which the catalyst boosts attributes (e.g., 100 for 100% boost per unit).
     */
    function setCatalystEffectiveness(address catalystTokenAddress, uint256 effectivenessFactor) public onlyOwner {
        require(allowedCatalystTokens[catalystTokenAddress], "Catalyst token not registered as allowed");
        catalystEffectiveness[catalystTokenAddress] = effectivenessFactor;
    }

    /**
     * @dev Admin function to trigger a "shift" in the ecosystem, changing environmentalPulse.
     *      This pulse can influence all ChronoCores' decay/rejuvenation rates.
     */
    function triggerEnvironmentalShift() public onlyOwner whenNotPaused {
        // Simple shift: Randomize pulse within a range, could be based on external data via oracle
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, ecosystemParams.lastShiftBlock)));
        ecosystemParams.environmentalPulse = (seed % 10000); // 0-9999
        ecosystemParams.lastShiftBlock = block.number;
        emit EnvironmentalShiftTriggered(ecosystemParams.environmentalPulse, ecosystemParams.lastShiftBlock);
    }

    /**
     * @dev Returns the current global state variables of the ecosystem.
     * @return A tuple containing (globalDecayRate, lastShiftBlock, environmentalPulse, totalActiveCores).
     */
    function getGlobalEcosystemState()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (
            ecosystemParams.globalDecayRate,
            ecosystemParams.lastShiftBlock,
            ecosystemParams.environmentalPulse,
            ecosystemParams.totalActiveCores
        );
    }

    /**
     * @dev Admin function to register new ERC20 tokens that can be used as catalysts.
     * @param tokenAddress The address of the ERC20 token to allow.
     */
    function addAllowedCatalystToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(!allowedCatalystTokens[tokenAddress], "Token already allowed");
        allowedCatalystTokens[tokenAddress] = true;
        _allowedCatalystTokensList.push(tokenAddress); // Add to list for iteration
    }

    /**
     * @dev Admin function to deregister catalyst tokens.
     * @param tokenAddress The address of the ERC20 token to remove.
     */
    function removeAllowedCatalystToken(address tokenAddress) public onlyOwner {
        require(allowedCatalystTokens[tokenAddress], "Token not currently allowed");
        allowedCatalystTokens[tokenAddress] = false;
        delete catalystEffectiveness[tokenAddress]; // Also remove its effectiveness setting

        // Remove from _allowedCatalystTokensList (simple swap-and-pop, order not guaranteed)
        for (uint256 i = 0; i < _allowedCatalystTokensList.length; i++) {
            if (_allowedCatalystTokensList[i] == tokenAddress) {
                _allowedCatalystTokensList[i] = _allowedCatalystTokensList[_allowedCatalystTokensList.length - 1];
                _allowedCatalystTokensList.pop();
                break;
            }
        }
    }

    /**
     * @dev Returns a list of all currently allowed catalyst token addresses.
     */
    function getAllowedCatalystTokens() public view returns (address[] memory) {
        return _allowedCatalystTokensList;
    }

    // --- III. Inter-Core Influence & Interaction ---

    /**
     * @dev Allows a ChronoCore owner to use their sourceCoreId to influence targetCoreId.
     *      Influence can be positive or negative based on a complex algorithm involving
     *      source's influencePotency, target's adaptationScore, chosen influencePower, and environmentalPulse.
     *      A fee (ETH) is paid to the feeReceiver.
     * @param sourceCoreId The ID of the influencing ChronoCore.
     * @param targetCoreId The ID of the ChronoCore to be influenced.
     * @param influencePower The intensity of influence to project (e.g., 1-100).
     */
    function projectInfluence(uint256 sourceCoreId, uint256 targetCoreId, uint256 influencePower)
        public
        payable
        whenNotPaused
        onlyChronoCoreOwner(sourceCoreId)
    {
        require(sourceCoreId != targetCoreId, "Cannot influence self");
        require(chronoCores[targetCoreId].creationTime != 0, "Target ChronoCore does not exist");
        require(influencePower > 0 && influencePower <= 100, "Influence power must be between 1 and 100");
        require(msg.value >= 0.001 ether, "Minimum influence fee not met (0.001 ETH)");

        _updateCoreStateInternal(sourceCoreId); // Update states before calculation
        _updateCoreStateInternal(targetCoreId);

        ChronoCoreState storage sourceCore = chronoCores[sourceCoreId];
        ChronoCoreState storage targetCore = chronoCores[targetCoreId];

        // Influence calculation: Complex and adaptive
        // Source's potency vs Target's resilience
        uint256 effectiveSourcePotency = sourceCore.influencePotency * influencePower / 100;
        uint256 effectiveTargetResilience = targetCore.adaptationScore;

        int256 netInfluence = int256(effectiveSourcePotency);

        // Environmental pulse adds a global modifier to influence outcomes
        if (ecosystemParams.environmentalPulse > 7000) { // High pulse makes influence stronger
            netInfluence = netInfluence * 120 / 100;
        } else if (ecosystemParams.environmentalPulse < 3000) { // Low pulse makes influence weaker
            netInfluence = netInfluence * 80 / 100;
        }

        // Target's resilience reduces/resists influence
        netInfluence -= int256(effectiveTargetResilience);

        // Apply influence to target core
        // A positive netInfluence boosts energy/adaptation, negative reduces it
        if (netInfluence > 0) {
            targetCore.energyLevel = Math.min(targetCore.energyLevel + uint256(netInfluence) / 5, 10000);
            targetCore.adaptationScore = Math.min(targetCore.adaptationScore + uint256(netInfluence) / 10, 10000);
        } else if (netInfluence < 0) {
            uint256 absInfluence = uint256(-netInfluence);
            targetCore.energyLevel = (targetCore.energyLevel > absInfluence / 5) ? targetCore.energyLevel - (absInfluence / 5) : 0;
            targetCore.adaptationScore = (targetCore.adaptationScore > absInfluence / 10) ? targetCore.adaptationScore - (absInfluence / 10) : 0;
        }

        // Reduce source's influence potency slightly from usage
        sourceCore.influencePotency = (sourceCore.influencePotency > influencePower / 2) ? sourceCore.influencePotency - (influencePower / 2) : 0;

        // Record influence event
        uint256 logIndex = coreInfluenceLogs[targetCoreId].length;
        coreInfluenceLogs[targetCoreId].push(InfluenceEvent({
            sourceCoreId: sourceCoreId,
            targetCoreId: targetCoreId,
            timestamp: block.timestamp,
            netInfluenceApplied: netInfluence,
            contested: false,
            claimedBounty: false
        }));

        // Collect fee directly to feeReceiver
        payable(feeReceiver).transfer(msg.value);
        emit ChronoForgeFeeCollected(address(0), msg.value); // address(0) for native token

        emit InfluenceProjected(sourceCoreId, targetCoreId, netInfluence, logIndex);
    }

    /**
     * @dev Returns a log of recent influence events for a specific ChronoCore.
     * @param tokenId The ID of the ChronoCore.
     * @return An array of InfluenceEvent structs.
     */
    function getInfluenceLog(uint256 tokenId) public view returns (InfluenceEvent[] memory) {
        require(chronoCores[tokenId].creationTime != 0, "ChronoCore does not exist");
        return coreInfluenceLogs[tokenId];
    }

    /**
     * @dev Allows an owner whose core was *positively influenced* to claim a bounty.
     *      The bounty is a conceptual reward.
     * @param targetCoreId The ID of the ChronoCore that was influenced.
     * @param influenceLogIndex The index of the influence event in the log.
     */
    function claimInfluenceBounty(uint256 targetCoreId, uint256 influenceLogIndex)
        public
        whenNotPaused
        onlyChronoCoreOwner(targetCoreId)
    {
        require(influenceLogIndex < coreInfluenceLogs[targetCoreId].length, "Invalid influence log index");
        InfluenceEvent storage eventLog = coreInfluenceLogs[targetCoreId][influenceLogIndex];

        require(eventLog.netInfluenceApplied > 0, "Only positive influence events can yield bounties");
        require(!eventLog.claimedBounty, "Bounty already claimed");
        require(!eventLog.contested, "Cannot claim bounty if event was contested");

        // Calculate bounty amount (simplified)
        uint256 bountyAmount = uint256(eventLog.netInfluenceApplied) / 10; // 10% of net positive influence as bounty

        eventLog.claimedBounty = true;

        // In a real system, a specific ERC20 token or native token would be transferred here.
        // For this concept, we simply mark it claimed and emit an event.
        emit InfluenceBountyClaimed(targetCoreId, influenceLogIndex, bountyAmount);
    }

    /**
     * @dev Allows a ChronoCore owner to attempt to counteract a recent influence event on their core.
     *      Requires burning some energy/adaptation from the contesting core and a fee.
     * @param targetCoreId The ID of the ChronoCore that was influenced.
     * @param influenceLogIndex The index of the influence event in the log to contest.
     */
    function contestInfluence(uint256 targetCoreId, uint256 influenceLogIndex)
        public
        payable
        whenNotPaused
        onlyChronoCoreOwner(targetCoreId)
    {
        require(influenceLogIndex < coreInfluenceLogs[targetCoreId].length, "Invalid influence log index");
        InfluenceEvent storage eventLog = coreInfluenceLogs[targetCoreId][influenceLogIndex];

        require(!eventLog.contested, "Influence already contested");
        require(!eventLog.claimedBounty, "Cannot contest if bounty already claimed");
        require(eventLog.timestamp + 1 days > block.timestamp, "Contest period expired (1 day)"); // Time limit to contest

        _updateCoreStateInternal(targetCoreId);
        ChronoCoreState storage targetCore = chronoCores[targetCoreId];

        // Cost to contest: requires energy/adaptation from target core and a fee
        uint256 absInfluenceMagnitude = uint256(eventLog.netInfluenceApplied > 0 ? eventLog.netInfluenceApplied : -eventLog.netInfluenceApplied);
        uint256 contestCostEnergy = absInfluenceMagnitude / 20; // 5% of influence magnitude
        uint256 contestCostAdaptation = contestCostEnergy / 2;

        require(targetCore.energyLevel >= contestCostEnergy, "Not enough energy to contest");
        require(targetCore.adaptationScore >= contestCostAdaptation, "Not enough adaptation to contest");
        require(msg.value >= 0.005 ether, "Minimum contest fee not met (0.005 ETH)"); // Higher fee than influence

        targetCore.energyLevel = (targetCore.energyLevel > contestCostEnergy) ? targetCore.energyLevel - contestCostEnergy : 0;
        targetCore.adaptationScore = (targetCore.adaptationScore > contestCostAdaptation) ? targetCore.adaptationScore - contestCostAdaptation : 0;

        eventLog.contested = true;

        // Collect fee directly to feeReceiver
        payable(feeReceiver).transfer(msg.value);
        emit ChronoForgeFeeCollected(address(0), msg.value);

        // Logic for successful contest: could revert effects, give a small boost, etc.
        // For simplicity, just marking it as contested for now. A more complex system might
        // reverse the `netInfluenceApplied` on the target core based on contest success.

        emit InfluenceContested(targetCoreId, influenceLogIndex);
    }

    // --- IV. Administrative & Utility ---

    /**
     * @dev Pauses the contract, preventing certain operations.
     */
    function pauseSystem() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     */
    function unpauseSystem() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Admin function to update the address where contract fees are sent.
     * @param newReceiver The new address for fee collection.
     */
    function setChronoForgeFeeReceiver(address newReceiver) public onlyOwner {
        require(newReceiver != address(0), "Invalid fee receiver address");
        feeReceiver = newReceiver;
    }

    /**
     * @dev Admin function to withdraw any collected ERC20 fees from the contract.
     *      Native token (ETH) fees are sent directly to the feeReceiver, so this
     *      function primarily handles ERC20s that might accumulate or accidental ETH.
     * @param tokenAddress The address of the ERC20 token to withdraw, or address(0) for native token.
     */
    function withdrawCollectedFees(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw accidental native token (ETH)
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                payable(msg.sender).transfer(contractETHBalance);
            }
        } else {
            // Withdraw ERC20 token
            uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokenAddress).transfer(msg.sender, balance);
            }
        }
    }

    /**
     * @dev Returns the total count of currently active (non-retired) ChronoCores.
     */
    function getTotalActiveChronoCores() public view returns (uint256) {
        return ecosystemParams.totalActiveCores;
    }

    /**
     * @dev Returns the owner of a ChronoCore (wrapper for ERC721 ownerOf).
     * @param tokenId The ID of the ChronoCore.
     */
    function getCoreOwner(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    /**
     * @dev Admin function to set the base URI for NFT metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    // --- ERC721 Overrides (Standard, for completeness) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure core state is updated before any transfer takes place
        _updateCoreStateInternal(tokenId);
    }

    // --- Fallback and Receive functions ---

    receive() external payable {
        // Revert any direct ETH transfers to prevent accidental loss or accumulation in contract.
        // Fees for specific functions (e.g., projectInfluence) are handled explicitly.
        revert("Direct ETH transfers not supported, use specific functions.");
    }

    fallback() external payable {
        revert("Call to unknown function or direct ETH transfer not supported.");
    }
}

// Simple Math library for min function (OpenZeppelin offers more comprehensive libraries)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```