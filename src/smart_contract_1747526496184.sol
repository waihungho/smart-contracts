Okay, let's create a smart contract that incorporates several advanced and creative concepts around dynamic NFTs, resource management, and interactive mechanics.

We'll design a `QuantumFusionNFT` contract. These NFTs will represent entities with dynamic attributes that change based on time (decay), staking, interaction with other NFTs (entanglement), external factors, and can be permanently altered through fusion, upgrading, and salvaging using external ERC-1155 "Quantum Fragments" and "Catalysts".

**Core Concepts:**

1.  **Dynamic Attributes:** NFT attributes (Strength, Agility, Intellect) are not static but calculated based on base attributes, energy level, staking status, entanglement state, and an external influence factor.
2.  **Energy System:** NFTs have an energy level that decays over time. Energy is needed for optimal performance.
3.  **Staking:** Staking an NFT prevents energy decay and provides a bonus to attributes.
4.  **Quantum Fusion:** Combine two (or more) Fusion NFTs and consume specific ERC-1155 fragments/catalysts to mint a *new* Fusion NFT with potentially higher base attributes, energy, and a unique composition. Outcomes can have a pseudo-random element influenced by inputs.
5.  **Upgrading:** Consume fragments/catalysts to permanently increase the *base* attributes of an existing NFT.
6.  **Salvaging:** Burn an NFT to recover a portion of the original fusion/upgrade cost in fragments/catalysts.
7.  **Quantum Entanglement:** Link two Fusion NFTs. Their states can mutually influence each other (e.g., staking one provides a small boost to the entangled partner, or decay on one slightly accelerates decay on the partner). Requires a catalyst to create/break.
8.  **External Influence:** An owner/oracle-controlled factor that can globally affect the dynamic attributes of all NFTs (simulating weather, market conditions, etc.).
9.  **ERC-1155 Integration:** Utilizes an external contract holding different types of "Quantum Fragments" and "Catalysts" necessary for fusion, upgrading, recharging, entanglement, and salvaging.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title QuantumFusionNFT
 * @dev An advanced NFT contract featuring dynamic attributes, fusion,
 *      staking, decay, entanglement, upgrading, and salvage using
 *      external ERC-1155 tokens.
 */
contract QuantumFusionNFT is ERC721, Ownable {

    // --- ERC-1155 Interface for Fragments/Catalysts ---
    // Assumes a separate contract manages fragment/catalyst tokens
    IERC1155 public quantumFragmentsContract;

    // Fragment/Catalyst Token IDs (Example IDs - replace with actual if deploying)
    uint256 public constant FRAGMENT_FIRE = 1;
    uint256 public constant FRAGMENT_WATER = 2;
    uint256 public constant FRAGMENT_EARTH = 3;
    uint256 public constant FRAGMENT_AIR = 4;
    uint256 public constant CATALYST_BASIC = 100;
    uint256 public constant CATALYST_ENTANGLEMENT = 101;
    uint256 public constant CATALYST_SALVAGE = 102;

    // --- Structs & State Variables ---

    struct Attributes {
        uint256 strength;
        uint256 agility;
        uint256 intellect;
    }

    struct FusionNFTData {
        Attributes baseAttributes;
        uint256 energyLevel; // Represents a value between 0 and 10000 (100.00%)
        uint48 lastProcessedTimestamp; // Timestamp when energy/decay was last calculated/applied
        bool isStaked;
        uint256 entangledWithTokenId; // 0 if not entangled
        uint256 fusedFromTokenId1; // 0 for admin-minted or non-fusion origin
        uint256 fusedFromTokenId2; // 0 for admin-minted or non-fusion origin
    }

    mapping(uint256 => FusionNFTData) private _tokenData;
    uint256 private _nextTokenId;

    // --- Configuration Parameters (Admin Settable) ---

    uint256 public decayRatePerSecond = 1; // Energy decay units per second (e.g., 1 unit per second)
    uint256 public stakeBoostPercentage = 10; // Additional attribute boost when staked (e.g., 10% of base)
    uint256 public stakeEnergyRegenPerSecond = 5; // Energy units regenerated per second when staked
    int256 public externalInfluence = 0; // Factor +/- affecting attributes (e.g., -100 to +100)
    uint256 public entanglementBoostPercentage = 5; // Attribute boost from entangled partner staking (e.g., 5%)
    uint256 public entanglementDecayMultiplier = 120; // Multiplier for decay when entangled partner decays (e.g., 120 = 1.2x)

    // Fusion Costs & Outcomes (Example structure - can be more complex)
    struct FusionCost {
        uint256 catalystId;
        uint256 catalystAmount;
        mapping(uint256 => uint256) fragmentCosts; // fragmentId => amount
    }
    FusionCost public fusionCosts; // Example: only one type of fusion recipe

    // Upgrade Costs (Example structure)
    struct UpgradeCost {
        uint256 catalystId;
        uint256 catalystAmount;
        mapping(uint256 => uint256) fragmentCosts; // fragmentId => amount
        uint256 attributeBoostAmount; // How much each attribute is increased
    }
    UpgradeCost public upgradeCosts; // Example: only one type of upgrade recipe

    // Salvage Return Percentage (Example structure)
    struct SalvageReturn {
        uint256 percentage; // Percentage of original fragment cost returned (e.g., 50)
        uint256 catalystReturnId;
        uint256 catalystReturnAmount; // Flat return amount for catalyst
    }
    SalvageReturn public salvageReturn; // Example: only one type of salvage outcome

    // --- Events ---

    event NFTFused(uint256 indexed newTokenId, uint256 indexed token1, uint256 indexed token2, address indexed owner);
    event NFTStaked(uint256 indexed tokenId);
    event NFTUnstaked(uint256 indexed tokenId);
    event EnergyRecharged(uint256 indexed tokenId, uint256 amountAdded, uint256 newEnergyLevel);
    event EnergyDecayed(uint256 indexed tokenId, uint256 amountDecayed, uint256 newEnergyLevel);
    event AttributesUpgraded(uint256 indexed tokenId, Attributes oldAttributes, Attributes newAttributes);
    event NFTSalvaged(uint256 indexed tokenId, address indexed recipient);
    event NFTsEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event NFTsDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ExternalInfluenceUpdated(int256 newInfluence);
    event FusionParametersUpdated(uint256 catalystId, uint256 catalystAmount); // Add fragment details if complex
    event UpgradeParametersUpdated(uint256 catalystId, uint256 catalystAmount, uint256 attributeBoost); // Add fragment details
    event SalvageParametersUpdated(uint256 percentage, uint256 catalystId, uint256 catalystAmount);

    // --- Modifiers ---

    modifier onlyFusedNFT(uint256 tokenId) {
        require(_tokenData[tokenId].fusedFromTokenId1 != 0, "Not a fused NFT");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address _quantumFragmentsContract)
        ERC721("QuantumFusionNFT", "QFN")
        Ownable(initialOwner)
    {
        require(_quantumFragmentsContract != address(0), "Fragments contract address cannot be zero");
        quantumFragmentsContract = IERC1155(_quantumFragmentsContract);

        // Set default costs (can be updated by admin)
        fusionCosts.catalystId = CATALYST_BASIC;
        fusionCosts.catalystAmount = 5;
        fusionCosts.fragmentCosts[FRAGMENT_FIRE] = 10;
        fusionCosts.fragmentCosts[FRAGMENT_WATER] = 10;

        upgradeCosts.catalystId = CATALYST_BASIC;
        upgradeCosts.catalystAmount = 3;
        upgradeCosts.fragmentCosts[FRAGMENT_EARTH] = 5;
        upgradeCosts.attributeBoostAmount = 10;

        salvageReturn.percentage = 50; // 50% return of fragment costs
        salvageReturn.catalystReturnId = CATALYST_SALVAGE;
        salvageReturn.catalystReturnAmount = 1;
    }

    // --- Admin/Owner Functions (7) ---

    /**
     * @dev Set the address of the ERC-1155 contract for fragments and catalysts.
     * @param _quantumFragmentsContract The address of the ERC-1155 contract.
     */
    function setERC1155Contract(address _quantumFragmentsContract) external onlyOwner {
        require(_quantumFragmentsContract != address(0), "Fragments contract address cannot be zero");
        quantumFragmentsContract = IERC1155(_quantumFragmentsContract);
    }

    /**
     * @dev Set parameters for NFT fusion costs.
     * @param catalystId The ID of the catalyst token required.
     * @param catalystAmount The amount of catalyst token required.
     * @param fragmentIds The array of fragment token IDs required.
     * @param fragmentAmounts The array of amounts for each fragment token ID.
     */
    function setFusionParams(uint256 catalystId, uint256 catalystAmount, uint256[] calldata fragmentIds, uint256[] calldata fragmentAmounts) external onlyOwner {
        require(fragmentIds.length == fragmentAmounts.length, "Fragment IDs and amounts length mismatch");
        fusionCosts.catalystId = catalystId;
        fusionCosts.catalystAmount = catalystAmount;
        // Clear existing costs (simple approach, more complex needed for multiple recipes)
        delete fusionCosts.fragmentCosts;
        for (uint i = 0; i < fragmentIds.length; i++) {
            fusionCosts.fragmentCosts[fragmentIds[i]] = fragmentAmounts[i];
        }
        emit FusionParametersUpdated(catalystId, catalystAmount); // Doesn't detail fragments in event for simplicity
    }

    /**
     * @dev Set parameters for energy decay and staking effects.
     * @param _decayRatePerSecond Energy decay rate per second.
     * @param _stakeBoostPercentage Attribute boost percentage when staked.
     * @param _stakeEnergyRegenPerSecond Energy regeneration per second when staked.
     */
    function setDecayParams(uint256 _decayRatePerSecond, uint256 _stakeBoostPercentage, uint256 _stakeEnergyRegenPerSecond) external onlyOwner {
        decayRatePerSecond = _decayRatePerSecond;
        stakeBoostPercentage = _stakeBoostPercentage;
        stakeEnergyRegenPerSecond = _stakeEnergyRegenPerSecond;
    }

    /**
     * @dev Set parameters for entanglement effects.
     * @param _entanglementBoostPercentage Attribute boost percentage from entangled partner.
     * @param _entanglementDecayMultiplier Decay multiplier from entangled partner.
     */
    function setEntanglementParams(uint256 _entanglementBoostPercentage, uint256 _entanglementDecayMultiplier) external onlyOwner {
        entanglementBoostPercentage = _entanglementBoostPercentage;
        entanglementDecayMultiplier = _entanglementDecayMultiplier;
    }

    /**
     * @dev Set parameters for NFT upgrading costs and effects.
     * @param catalystId The ID of the catalyst token required.
     * @param catalystAmount The amount of catalyst token required.
     * @param fragmentIds The array of fragment token IDs required.
     * @param fragmentAmounts The array of amounts for each fragment token ID.
     * @param attributeBoostAmount How much each attribute is increased.
     */
    function setUpgradeParams(uint256 catalystId, uint256 catalystAmount, uint256[] calldata fragmentIds, uint256[] calldata fragmentAmounts, uint256 attributeBoostAmount) external onlyOwner {
         require(fragmentIds.length == fragmentAmounts.length, "Fragment IDs and amounts length mismatch");
        upgradeCosts.catalystId = catalystId;
        upgradeCosts.catalystAmount = catalystAmount;
        // Clear existing costs
        delete upgradeCosts.fragmentCosts;
        for (uint i = 0; i < fragmentIds.length; i++) {
            upgradeCosts.fragmentCosts[fragmentIds[i]] = fragmentAmounts[i];
        }
        upgradeCosts.attributeBoostAmount = attributeBoostAmount;
        emit UpgradeParametersUpdated(catalystId, catalystAmount, attributeBoostAmount); // Doesn't detail fragments
    }

    /**
     * @dev Set parameters for NFT salvage returns.
     * @param percentage Percentage of original fragment costs returned (0-100).
     * @param catalystReturnId The ID of the catalyst token returned.
     * @param catalystReturnAmount The amount of catalyst token returned.
     */
    function setSalvageParams(uint256 percentage, uint256 catalystReturnId, uint256 catalystReturnAmount) external onlyOwner {
        require(percentage <= 100, "Percentage cannot exceed 100");
        salvageReturn.percentage = percentage;
        salvageReturn.catalystReturnId = catalystReturnId;
        salvageReturn.catalystReturnAmount = catalystReturnAmount;
         emit SalvageParametersUpdated(percentage, catalystReturnId, catalystReturnAmount);
    }


    /**
     * @dev Update the global external influence factor.
     * @param _externalInfluence The new external influence value.
     */
    function setExternalInfluence(int256 _externalInfluence) external onlyOwner {
        externalInfluence = _externalInfluence;
        emit ExternalInfluenceUpdated(_externalInfluence);
    }

    /**
     * @dev Admin function to mint a new NFT directly.
     * @param to The recipient address.
     * @param initialAttributes Initial base attributes.
     * @param initialEnergy Initial energy level (0-10000).
     */
    function adminMint(address to, Attributes calldata initialAttributes, uint256 initialEnergy) external onlyOwner {
        require(to != address(0), "Mint to the zero address");
        require(initialEnergy <= 10000, "Energy level out of bounds (0-10000)");

        uint256 newTokenId = _nextTokenId++;
        _mint(to, newTokenId);

        _tokenData[newTokenId] = FusionNFTData({
            baseAttributes: initialAttributes,
            energyLevel: initialEnergy,
            lastProcessedTimestamp: uint48(block.timestamp),
            isStaked: false,
            entangledWithTokenId: 0,
            fusedFromTokenId1: 0,
            fusedFromTokenId2: 0
        });

        // Emit a generic Transfer event (handled by _mint) or a specific mint event if preferred.
    }

    // --- Query Functions (Public/External) (5) ---

    /**
     * @dev Get the static/base data for a specific token.
     * @param tokenId The ID of the token.
     * @return FusionNFTData struct.
     */
    function getNFTData(uint256 tokenId) external view returns (FusionNFTData memory) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenData[tokenId];
    }

    /**
     * @dev Get the current dynamic attributes of a token, including energy, staking, entanglement, and external influences.
     * @param tokenId The ID of the token.
     * @return Attributes struct with calculated current values.
     */
    function getCurrentAttributes(uint256 tokenId) public view returns (Attributes memory) {
        _requireOwned(tokenId);
        FusionNFTData storage data = _tokenData[tokenId];

        uint256 currentEnergy = calculateCurrentEnergy(tokenId); // Calculate energy considering decay/regen

        // Apply energy influence (e.g., linear scaling)
        uint256 energyMultiplierBasisPoints = (currentEnergy * 10000) / 10000; // Scale energy 0-10000 to 0-10000 basis points
        Attributes memory currentAttrs = data.baseAttributes;

        currentAttrs.strength = (currentAttrs.strength * energyMultiplierBasisPoints) / 10000;
        currentAttrs.agility = (currentAttrs.agility * energyMultiplierBasisPoints) / 10000;
        currentAttrs.intellect = (currentAttrs.intellect * energyMultiplierBasisPoints) / 10000;

        // Apply staking boost
        if (data.isStaked) {
            currentAttrs.strength = currentAttrs.strength + (data.baseAttributes.strength * stakeBoostPercentage) / 100;
            currentAttrs.agility = currentAttrs.agility + (data.baseAttributes.agility * stakeBoostPercentage) / 100;
            currentAttrs.intellect = currentAttrs.intellect + (data.baseAttributes.intellect * stakeBoostPercentage) / 100;
        }

        // Apply entanglement boost (if partner is staked)
        if (data.entangledWithTokenId != 0) {
            uint256 entangledTokenId = data.entangledWithTokenId;
             // Check if entangled partner exists and is staked
            if (_exists(entangledTokenId) && _tokenData[entangledTokenId].isStaked) {
                 currentAttrs.strength = currentAttrs.strength + (data.baseAttributes.strength * entanglementBoostPercentage) / 100;
                 currentAttrs.agility = currentAttrs.agility + (data.baseAttributes.agility * entanglementBoostPercentage) / 100;
                 currentAttrs.intellect = currentAttrs.intellect + (data.baseAttributes.intellect * entanglementBoostPercentage) / 100;
            }
        }

        // Apply external influence
        if (externalInfluence > 0) {
             uint256 influenceBoost = (currentAttrs.strength + currentAttrs.agility + currentAttrs.intellect) * uint256(externalInfluence) / 30000; // Example scaling
             currentAttrs.strength += influenceBoost;
             currentAttrs.agility += influenceBoost;
             currentAttrs.intellect += influenceBoost;
        } else if (externalInfluence < 0) {
             uint256 influencePenalty = (currentAttrs.strength + currentAttrs.agility + currentAttrs.intellect) * uint256(-externalInfluence) / 30000; // Example scaling
             currentAttrs.strength = Math.max(0, currentAttrs.strength - influencePenalty);
             currentAttrs.agility = Math.max(0, currentAttrs.agility - influencePenalty);
             currentAttrs.intellect = Math.max(0, currentAttrs.intellect - influencePenalty);
        }


        return currentAttrs;
    }

     /**
     * @dev Helper to calculate current energy considering elapsed time, staking, and entanglement.
     *      Does *not* modify state. Use triggerDecay to apply and update timestamp.
     * @param tokenId The ID of the token.
     * @return The calculated current energy level (0-10000).
     */
    function calculateCurrentEnergy(uint256 tokenId) public view returns (uint256) {
         // Does not check _exists here, assumed called after owner/exists check
        FusionNFTData storage data = _tokenData[tokenId];
        uint256 elapsed = block.timestamp - data.lastProcessedTimestamp;
        uint256 currentEnergy = data.energyLevel;

        uint256 decayAmount = elapsed * decayRatePerSecond;
        uint256 regenAmount = 0;

        if (data.isStaked) {
            regenAmount = elapsed * stakeEnergyRegenPerSecond;
            // Staking prevents standard decay
            decayAmount = 0;
        }

         // Apply entanglement decay influence (if partner exists and is not staked)
        if (data.entangledWithTokenId != 0) {
             uint256 entangledTokenId = data.entangledWithTokenId;
             // Check if entangled partner exists and is *not* staked
             if (_exists(entangledTokenId) && !_tokenData[entangledTokenId].isStaked) {
                 uint256 entangledElapsed = block.timestamp - _tokenData[entangledTokenId].lastProcessedTimestamp;
                 uint256 entangledDecay = entangledElapsed * decayRatePerSecond;
                 // Add a portion of the partner's potential decay (or decay rate)
                 decayAmount += (entangledDecay * (entanglementDecayMultiplier - 100)) / 100; // Example: 120 multiplier -> add 20% of partner's decay
             }
        }


        // Apply decay first (if any)
        currentEnergy = (decayAmount > currentEnergy) ? 0 : currentEnergy - decayAmount;

        // Apply regeneration
        currentEnergy = Math.min(10000, currentEnergy + regenAmount);

        return currentEnergy;
    }


    /**
     * @dev Get the current energy level of a token.
     * @param tokenId The ID of the token.
     * @return The current energy level (0-10000).
     */
    function getEnergyLevel(uint256 tokenId) external view returns (uint256) {
        _requireOwned(tokenId);
        return calculateCurrentEnergy(tokenId);
    }

    /**
     * @dev Check if a token is currently staked.
     * @param tokenId The ID of the token.
     * @return True if staked, false otherwise.
     */
    function isStaked(uint256 tokenId) external view returns (bool) {
        _requireOwned(tokenId);
        return _tokenData[tokenId].isStaked;
    }

    /**
     * @dev Get the token ID this NFT is entangled with.
     * @param tokenId The ID of the token.
     * @return The entangled token ID, or 0 if not entangled.
     */
    function getEntangledWith(uint256 tokenId) external view returns (uint256) {
        _requireOwned(tokenId);
        return _tokenData[tokenId].entangledWithTokenId;
    }


    // --- Core Mechanics Functions (Public/External) (10) ---

    /**
     * @dev Fuse two NFTs and specific fragments/catalysts to create a new one.
     * @param token1Id The ID of the first NFT to fuse.
     * @param token2Id The ID of the second NFT to fuse.
     */
    function fuseNFTs(uint256 token1Id, uint256 token2Id) external {
        address owner = _ownerOf(token1Id);
        require(owner == _msgSender(), "Sender must own Token 1");
        require(owner == _ownerOf(token2Id), "Sender must own Token 2");
        require(token1Id != token2Id, "Cannot fuse a token with itself");

        // --- Check Fragment/Catalyst Costs and User Balance ---
        require(quantumFragmentsContract.balanceOf(_msgSender(), fusionCosts.catalystId) >= fusionCosts.catalystAmount, "Not enough catalyst");
        uint256[] memory requiredFragmentIds = new uint256[](getFragmentCostsCount(fusionCosts.fragmentCosts));
        uint256[] memory requiredFragmentAmounts = new uint256[](requiredFragmentIds.length);
        uint256 index = 0;
        for (uint i = 1; i <= 100; i++) { // Example loop for fragment IDs 1-100
            uint256 cost = fusionCosts.fragmentCosts[i];
            if (cost > 0) {
                requiredFragmentIds[index] = i;
                requiredFragmentAmounts[index] = cost;
                require(quantumFragmentsContract.balanceOf(_msgSender(), i) >= cost, "Not enough fragments");
                index++;
            }
        }

        // --- Burn Inputs ---
        // The user must have granted approval for this contract to transfer their tokens
        quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this), // Transfer to contract address for burning
            fusionCosts.catalystId,
            fusionCosts.catalystAmount,
            "" // Data
        );
         quantumFragmentsContract.safeBatchTransferFrom(
            _msgSender(),
            address(this), // Transfer to contract address for burning
            requiredFragmentIds,
            requiredFragmentAmounts,
            "" // Data
        );
         // Actually burn the fragments now
        quantumFragmentsContract.burn(address(this), fusionCosts.catalystId, fusionCosts.catalystAmount);
        quantumFragmentsContract.burn(address(this), requiredFragmentIds, requiredFragmentAmounts);

        _burn(token1Id);
        _burn(token2Id);

        // --- Mint New NFT ---
        uint256 newTokenId = _nextTokenId++;
        _mint(owner, newTokenId);

        // --- Calculate New NFT Data ---
        FusionNFTData storage data1 = _tokenData[token1Id];
        FusionNFTData storage data2 = _tokenData[token2Id];

        // Example Fusion Logic: Average base attributes + boost based on fragment types used
        Attributes memory newBaseAttributes;
        newBaseAttributes.strength = (data1.baseAttributes.strength + data2.baseAttributes.strength) / 2;
        newBaseAttributes.agility = (data1.baseAttributes.agility + data2.baseAttributes.agility) / 2;
        newBaseAttributes.intellect = (data1.baseAttributes.intellect + data2.baseAttributes.intellect) / 2;

        // Simple pseudo-random boost based on inputs (miner-manipulable, use VRF in production)
        uint256 seed = uint256(keccak256(abi.encodePacked(token1Id, token2Id, block.timestamp, tx.origin, requiredFragmentIds, requiredFragmentAmounts)));
        uint256 boost = (seed % 50) + 1; // Boost between 1 and 50

         // Boost depends on fragment types (example: Fire boosts Str, Water boosts Agi etc.)
        for (uint i = 0; i < requiredFragmentIds.length; i++) {
            if (requiredFragmentIds[i] == FRAGMENT_FIRE) newBaseAttributes.strength += (requiredFragmentAmounts[i] * 2);
            if (requiredFragmentIds[i] == FRAGMENT_WATER) newBaseAttributes.agility += (requiredFragmentAmounts[i] * 2);
            if (requiredFragmentIds[i] == FRAGMENT_EARTH) newBaseAttributes.intellect += (requiredFragmentAmounts[i] * 2);
            // Additional logic for different fragments
        }
        newBaseAttributes.strength += boost;
        newBaseAttributes.agility += boost;
        newBaseAttributes.intellect += boost;


        _tokenData[newTokenId] = FusionNFTData({
            baseAttributes: newBaseAttributes,
            energyLevel: 10000, // Start with full energy
            lastProcessedTimestamp: uint48(block.timestamp),
            isStaked: false,
            entangledWithTokenId: 0,
            fusedFromTokenId1: token1Id,
            fusedFromTokenId2: token2Id
        });

        // Clean up burned token data (important!)
        delete _tokenData[token1Id];
        delete _tokenData[token2Id];


        emit NFTFused(newTokenId, token1Id, token2Id, owner);
    }

    /**
     * @dev Stake an NFT to prevent energy decay and gain benefits.
     * @param tokenId The ID of the token to stake.
     */
    function stakeNFT(uint256 tokenId) external {
        require(_ownerOf(tokenId) == _msgSender(), "Sender must own the token");
        FusionNFTData storage data = _tokenData[tokenId];
        require(!data.isStaked, "Token is already staked");

        // Update energy and timestamp before staking
        _updateEnergy(tokenId);

        data.isStaked = true;
        emit NFTStaked(tokenId);
    }

    /**
     * @dev Unstake an NFT.
     * @param tokenId The ID of the token to unstake.
     */
    function unstakeNFT(uint256 tokenId) external {
        require(_ownerOf(tokenId) == _msgSender(), "Sender must own the token");
        FusionNFTData storage data = _tokenData[tokenId];
        require(data.isStaked, "Token is not staked");

         // Update energy and timestamp upon unstaking
        _updateEnergy(tokenId);

        data.isStaked = false;
        emit NFTUnstaked(tokenId);
    }

    /**
     * @dev Recharge the energy level of an NFT by consuming fragments.
     * @param tokenId The ID of the token to recharge.
     * @param fragmentId The ID of the fragment type to consume.
     * @param amount The amount of fragments to consume.
     */
    function rechargeEnergy(uint256 tokenId, uint256 fragmentId, uint256 amount) external {
         require(_ownerOf(tokenId) == _msgSender(), "Sender must own the token");
         require(amount > 0, "Amount must be greater than zero");
         require(fragmentId >= FRAGMENT_FIRE && fragmentId <= FRAGMENT_AIR, "Invalid fragment type"); // Example fragment range

         FusionNFTData storage data = _tokenData[tokenId];
         require(data.energyLevel < 10000, "Energy is already full");

         // Check user balance
         require(quantumFragmentsContract.balanceOf(_msgSender(), fragmentId) >= amount, "Not enough fragments");

         // Burn fragments
         quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this), // Transfer to contract address for burning
            fragmentId,
            amount,
            "" // Data
         );
         quantumFragmentsContract.burn(address(this), fragmentId, amount);


         // Update energy and timestamp before adding energy
         _updateEnergy(tokenId);

         // Recharge logic (example: 1 fragment adds 10 energy units)
         uint256 energyAdded = amount * 10;
         data.energyLevel = Math.min(10000, data.energyLevel + energyAdded);

         emit EnergyRecharged(tokenId, energyAdded, data.energyLevel);
    }

    /**
     * @dev Allows anyone to trigger the decay calculation for a specific NFT.
     *      This updates the stored energy level based on elapsed time and applies decay/regen.
     *      Useful for ensuring energy state is relatively current when not staking/unstaking/recharging.
     *      Requires gas paid by the caller.
     * @param tokenId The ID of the token to trigger decay calculation for.
     */
    function triggerDecay(uint256 tokenId) external {
         _requireOwned(tokenId); // Check exists (owner can be address(0) if burned) - wait, need to check if *exists* not owned
         require(_exists(tokenId), "Token does not exist");
         _updateEnergy(tokenId);
    }

    /**
     * @dev Entangle two NFTs. Requires a catalyst.
     * @param token1Id The ID of the first NFT.
     * @param token2Id The ID of the second NFT.
     */
    function entangleNFTs(uint256 token1Id, uint256 token2Id) external {
        address owner = _ownerOf(token1Id);
        require(owner == _msgSender(), "Sender must own Token 1");
        require(owner == _ownerOf(token2Id), "Sender must own Token 2");
        require(token1Id != token2Id, "Cannot entangle a token with itself");
        require(_tokenData[token1Id].entangledWithTokenId == 0, "Token 1 is already entangled");
        require(_tokenData[token2Id].entangledWithTokenId == 0, "Token 2 is already entangled");

        // Check and burn catalyst
        uint256 catalystCost = 1; // Example cost
        require(quantumFragmentsContract.balanceOf(_msgSender(), CATALYST_ENTANGLEMENT) >= catalystCost, "Not enough entanglement catalysts");
         quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this),
            CATALYST_ENTANGLEMENT,
            catalystCost,
            ""
        );
        quantumFragmentsContract.burn(address(this), CATALYST_ENTANGLEMENT, catalystCost);


        // Update energy and timestamp before entangling
        _updateEnergy(token1Id);
        _updateEnergy(token2Id);

        // Create the link
        _tokenData[token1Id].entangledWithTokenId = token2Id;
        _tokenData[token2Id].entangledWithTokenId = token1Id;

        emit NFTsEntangled(token1Id, token2Id);
    }

    /**
     * @dev Disentangle two previously entangled NFTs. Requires a catalyst.
     * @param token1Id The ID of the first NFT.
     * @param token2Id The ID of the second NFT.
     */
    function disentangleNFTs(uint256 token1Id, uint256 token2Id) external {
        address owner = _ownerOf(token1Id);
        require(owner == _msgSender(), "Sender must own Token 1");
        require(owner == _ownerOf(token2Id), "Sender must own Token 2");
        require(token1Id != token2Id, "Invalid entanglement pair");
        require(_tokenData[token1Id].entangledWithTokenId == token2Id, "Tokens are not entangled with each other");
        require(_tokenData[token2Id].entangledWithTokenId == token1Id, "Tokens are not entangled with each other");


         // Check and burn catalyst
        uint256 catalystCost = 1; // Example cost
        require(quantumFragmentsContract.balanceOf(_msgSender(), CATALYST_ENTANGLEMENT) >= catalystCost, "Not enough entanglement catalysts");
         quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this),
            CATALYST_ENTANGLEMENT,
            catalystCost,
            ""
        );
         quantumFragmentsContract.burn(address(this), CATALYST_ENTANGLEMENT, catalystCost);

        // Update energy and timestamp before disentangling
        _updateEnergy(token1Id);
        _updateEnergy(token2Id);

        // Break the link
        _tokenData[token1Id].entangledWithTokenId = 0;
        _tokenData[token2Id].entangledWithTokenId = 0;

        emit NFTsDisentangled(token1Id, token2Id);
    }

    /**
     * @dev Upgrade the base attributes of an NFT by consuming fragments and catalysts.
     * @param tokenId The ID of the token to upgrade.
     */
    function upgradeAttributes(uint256 tokenId) external {
         require(_ownerOf(tokenId) == _msgSender(), "Sender must own the token");

         // --- Check Fragment/Catalyst Costs and User Balance ---
        require(quantumFragmentsContract.balanceOf(_msgSender(), upgradeCosts.catalystId) >= upgradeCosts.catalystAmount, "Not enough catalyst for upgrade");
        uint256[] memory requiredFragmentIds = new uint256[](getFragmentCostsCount(upgradeCosts.fragmentCosts));
        uint256[] memory requiredFragmentAmounts = new uint256[](requiredFragmentIds.length);
        uint256 index = 0;
        for (uint i = 1; i <= 100; i++) { // Example loop
            uint256 cost = upgradeCosts.fragmentCosts[i];
            if (cost > 0) {
                requiredFragmentIds[index] = i;
                requiredFragmentAmounts[index] = cost;
                require(quantumFragmentsContract.balanceOf(_msgSender(), i) >= cost, "Not enough fragments for upgrade");
                index++;
            }
        }

        // --- Burn Inputs ---
         quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this),
            upgradeCosts.catalystId,
            upgradeCosts.catalystAmount,
            ""
        );
         quantumFragmentsContract.safeBatchTransferFrom(
            _msgSender(),
            address(this),
            requiredFragmentIds,
            requiredFragmentAmounts,
            ""
        );
        quantumFragmentsContract.burn(address(this), upgradeCosts.catalystId, upgradeCosts.catalystAmount);
        quantumFragmentsContract.burn(address(this), requiredFragmentIds, requiredFragmentAmounts);

        // Update energy and timestamp before upgrading
        _updateEnergy(tokenId);

        // --- Apply Upgrade ---
        FusionNFTData storage data = _tokenData[tokenId];
        Attributes memory oldAttrs = data.baseAttributes;

        data.baseAttributes.strength += upgradeCosts.attributeBoostAmount;
        data.baseAttributes.agility += upgradeCosts.attributeBoostAmount;
        data.baseAttributes.intellect += upgradeCosts.attributeBoostAmount;

        emit AttributesUpgraded(tokenId, oldAttrs, data.baseAttributes);
    }

    /**
     * @dev Salvage an NFT to recover some fragments and catalysts. Burns the NFT.
     * @param tokenId The ID of the token to salvage.
     */
    function salvageNFT(uint256 tokenId) external {
        require(_ownerOf(tokenId) == _msgSender(), "Sender must own the token");
        require(!_tokenData[tokenId].isStaked, "Cannot salvage staked token");
        require(_tokenData[tokenId].entangledWithTokenId == 0, "Cannot salvage entangled token");

        // --- Burn Catalyst ---
        uint256 catalystCost = 1; // Example cost to salvage
        require(quantumFragmentsContract.balanceOf(_msgSender(), CATALYST_SALVAGE) >= catalystCost, "Not enough salvage catalysts");
         quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            address(this),
            CATALYST_SALVAGE,
            catalystCost,
            ""
        );
        quantumFragmentsContract.burn(address(this), CATALYST_SALVAGE, catalystCost);


        // --- Calculate and Return Fragments ---
        // This part is complex: ideally track original costs per NFT.
        // For simplicity here, we'll return a percentage of the *current fusion* costs.
        // A production contract might track 'lifetime fragment investment'.
        uint256[] memory returnFragmentIds = new uint256[](getFragmentCostsCount(fusionCosts.fragmentCosts)); // Using fusion costs as a proxy
        uint256[] memory returnFragmentAmounts = new uint256[](returnFragmentIds.length);
         uint256 index = 0;
        for (uint i = 1; i <= 100; i++) { // Example loop
            uint256 cost = fusionCosts.fragmentCosts[i];
            if (cost > 0) {
                 returnFragmentIds[index] = i;
                 // Return percentage of the cost, minimum 1
                 returnFragmentAmounts[index] = Math.max(1, (cost * salvageReturn.percentage) / 100);
                 index++;
            }
        }

         // Mint fragments and catalyst back to the user
         if (returnFragmentIds.length > 0) {
              quantumFragmentsContract.mint(_msgSender(), returnFragmentIds, returnFragmentAmounts); // Assumes mint function on ERC1155
         }
          if (salvageReturn.catalystReturnAmount > 0) {
              quantumFragmentsContract.mint(_msgSender(), salvageReturn.catalystReturnId, salvageReturn.catalystReturnAmount, ""); // Assumes mint function
          }


        // --- Burn NFT ---
        uint256 salvagedTokenId = tokenId; // Store before deleting data
        address recipient = _msgSender(); // Store before deleting data

        _burn(tokenId);
        delete _tokenData[tokenId]; // Clean up data

        emit NFTSalvaged(salvagedTokenId, recipient);
    }

    /**
     * @dev Transfer an NFT and a specific amount of a fragment type to a recipient in one transaction.
     *      Requires sender to own both the NFT and the fragments, and approve both contracts.
     * @param to The recipient address.
     * @param tokenId The ID of the NFT to transfer.
     * @param fragmentId The ID of the fragment type to transfer.
     * @param fragmentAmount The amount of fragments to transfer.
     */
    function transferWithEnergy(address to, uint256 tokenId, uint256 fragmentId, uint256 fragmentAmount) external {
        require(to != address(0), "Transfer to the zero address");
        require(to != address(this), "Cannot transfer to the contract itself");
        require(_ownerOf(tokenId) == _msgSender(), "Sender must own the NFT");
        require(!_tokenData[tokenId].isStaked, "Cannot transfer staked NFT");
        require(_tokenData[tokenId].entangledWithTokenId == 0, "Cannot transfer entangled NFT"); // Or handle disentangling

        require(fragmentAmount > 0, "Fragment amount must be > 0");
        require(quantumFragmentsContract.balanceOf(_msgSender(), fragmentId) >= fragmentAmount, "Sender does not have enough fragments");


        // Perform transfers
        _transfer(_msgSender(), to, tokenId); // ERC721 transfer
         // ERC1155 transfer - sender must have approved this contract or the ERC1155 contract itself
        quantumFragmentsContract.safeTransferFrom(
            _msgSender(),
            to,
            fragmentId,
            fragmentAmount,
            "" // Data
        );

        // No specific event needed beyond standard Transfer events
    }


    // --- Internal/Helper Functions (6) ---

    /**
     * @dev Internal helper to calculate and apply energy decay/regen based on elapsed time.
     *      Updates the stored energy level and last processed timestamp.
     * @param tokenId The ID of the token.
     */
    function _updateEnergy(uint256 tokenId) internal {
        FusionNFTData storage data = _tokenData[tokenId];
        uint256 elapsed = block.timestamp - data.lastProcessedTimestamp;

        if (elapsed == 0) {
            return; // No time has passed
        }

        uint256 currentEnergy = data.energyLevel;
        uint256 newEnergy;
        uint256 energyChange;

        if (data.isStaked) {
            // Staking: Regen
            energyChange = elapsed * stakeEnergyRegenPerSecond;
            newEnergy = Math.min(10000, currentEnergy + energyChange);
        } else {
            // Not staked: Decay
            energyChange = elapsed * decayRatePerSecond;

             // Check entangled partner's state for additional decay influence
             if (data.entangledWithTokenId != 0) {
                uint256 entangledTokenId = data.entangledWithTokenId;
                // Check if partner exists and is *not* staked
                if (_exists(entangledTokenId) && !_tokenData[entangledTokenId].isStaked) {
                     uint256 entangledElapsed = block.timestamp - _tokenData[entangledTokenId].lastProcessedTimestamp;
                     uint256 entangledDecay = entangledElapsed * decayRatePerSecond;
                     energyChange += (entangledDecay * (entanglementDecayMultiplier - 100)) / 100; // Add portion of partner's decay
                }
             }

            newEnergy = (energyChange > currentEnergy) ? 0 : currentEnergy - energyChange;
        }

        uint256 oldEnergy = data.energyLevel;
        data.energyLevel = newEnergy;
        data.lastProcessedTimestamp = uint48(block.timestamp);

        if (newEnergy < oldEnergy) {
            emit EnergyDecayed(tokenId, oldEnergy - newEnergy, newEnergy);
        } else if (newEnergy > oldEnergy) {
            emit EnergyRecharged(tokenId, newEnergy - oldEnergy, newEnergy); // Reuse Recharge event for regen
        }
    }

     /**
      * @dev Internal helper to get the number of unique fragment types in a cost mapping.
      */
     function getFragmentCostsCount(mapping(uint256 => uint256) storage fragmentCosts) internal view returns (uint256) {
         uint256 count = 0;
         // Iterate through possible fragment IDs (1-100 in this example)
         for(uint i = 1; i <= 100; i++) {
             if(fragmentCosts[i] > 0) {
                 count++;
             }
         }
         return count;
     }

     /**
      * @dev Override hook from ERC721 to prevent transfers of staked/entangled tokens.
      * @param from The address transferring from.
      * @param to The address transferring to.
      * @param tokenId The ID of the token being transferred.
      */
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if the token is being transferred (not minted or burned)
        if (from != address(0) && to != address(0)) {
             require(!_tokenData[tokenId].isStaked, "Staked tokens cannot be transferred");
             require(_tokenData[tokenId].entangledWithTokenId == 0, "Entangled tokens cannot be transferred"); // Requires disentanglement first
             // Note: This also prevents transfers initiated by owner via transferFrom/safeTransferFrom
        }

        // Clean up entanglement if a token is being burned
        if (to == address(0)) {
            uint256 entangledPartnerId = _tokenData[tokenId].entangledWithTokenId;
            if (entangledPartnerId != 0 && _exists(entangledPartnerId)) {
                 _tokenData[entangledPartnerId].entangledWithTokenId = 0; // Break the link on the other end
                 emit NFTsDisentangled(tokenId, entangledPartnerId); // Emit event
            }
             // No need to delete _tokenData here, done in fuseNFTs or salvageNFT
        }
    }

    // --- ERC721 & Metadata Functions (Public/External) (2) ---

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId`.
     *      This function could be dynamic, generating JSON metadata on the fly
     *      including the current calculated attributes.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists
        // In a real application, this would point to an off-chain JSON file.
        // For demonstration, return a placeholder or minimal dynamic data.

        // Example: Construct a simple JSON string including dynamic attributes
        Attributes memory currentAttrs = getCurrentAttributes(tokenId);
        uint256 currentEnergy = calculateCurrentEnergy(tokenId); // Get calculated energy

        string memory name = string(abi.encodePacked("Quantum Fusion NFT #", tokenId));
        string memory description = string(abi.encodePacked("A dynamic Quantum Fusion Entity. Energy: ", _toString(currentEnergy / 100), ".")); // Energy as 0-100 integer

        // WARNING: Constructing complex JSON on-chain is gas-expensive.
        // This is a simplified example. Off-chain generation is typical.
        string memory attributesJson = string(abi.encodePacked(
            "[",
            '{"trait_type": "Strength", "value": ', _toString(currentAttrs.strength), '},',
            '{"trait_type": "Agility", "value": ', _toString(currentAttrs.agility), '},',
            '{"trait_type": "Intellect", "value": ', _toString(currentAttrs.intellect), '}'
            // Add Energy and Status (Staked/Entangled) as traits
            ',{"trait_type": "Energy", "value": ', _toString(currentEnergy / 100), '}' // Integer %
            ',{"trait_type": "Staked", "value": ', _tokenData[tokenId].isStaked ? '"Yes"' : '"No"', '}'
             , _tokenData[tokenId].entangledWithTokenId != 0 ? string(abi.encodePacked(',{"trait_type": "Entangled", "value": "', _toString(_tokenData[tokenId].entangledWithTokenId), '"}')) : "" // Add entanglement if exists
            , _tokenData[tokenId].fusedFromTokenId1 != 0 ? string(abi.encodePacked(',{"trait_type": "Origin", "value": "Fused"}')) : string(abi.encodePacked(',{"trait_type": "Origin", "value": "Minted"}')) // Add origin
            , _tokenData[tokenId].fusedFromTokenId1 != 0 ? string(abi.encodePacked(',{"trait_type": "Fused From #1", "value": "', _toString(_tokenData[tokenId].fusedFromTokenId1), '"}')) : "" // Add fusion source 1
             , _tokenData[tokenId].fusedFromTokenId2 != 0 ? string(abi.encodePacked(',{"trait_type": "Fused From #2", "value": "', _toString(_tokenData[tokenId].fusedFromTokenId2), '"}')) : "" // Add fusion source 2
            ,
            "]"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "ipfs://<YOUR_PLACEHOLDER_IMAGE_CID>",', // Replace with actual image CID
            '"attributes": ', attributesJson,
            '}'
        ));

        // Prepend data:application/json;base64,...
        // This requires base64 encoding, which is also gas-expensive on-chain.
        // Returning the raw JSON string is simpler for demonstration.
        // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        return string(abi.encodePacked("data:application/json;utf8,", json)); // Less efficient but simpler URI

    }

    /**
     * @dev See {ERC165-supportsInterface}. Required by ERC721.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               super.supportsInterface(interfaceId);
    }

     // --- Utility function for _toString (Copy-pasted from OpenZeppelin) ---
    function _toString(uint256 value) internal pure returns (string memory) {
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
}

// --- Simple Mock ERC1155 Interface (Replace with actual if deploying) ---
// This interface only includes functions used by QuantumFusionNFT
interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external; // User calls this on the ERC1155 contract
    function isApprovedForAll(address account, address operator) external view returns (bool); // User calls this on the ERC1155 contract
    // Assuming the ERC1155 has burn functions callable by approved operators (like this contract)
    function burn(address account, uint256 id, uint256 value) external;
    function burn(address account, uint256[] calldata ids, uint256[] calldata values) external;
     // Assuming the ERC1155 has mint functions callable by the minter (e.g., this contract, if minter role is granted)
    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external;
    function mint(address account, uint256[] calldata ids, uint256[] calldata amounts) external;
}

/*
// For base64 encoding (optional, for tokenURI)
import "@openzeppelin/contracts/utils/Base64.sol";
*/

```

**Explanation of Functions (Total Public/External Functions: ~24, excluding inherited ERC721 basics like `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` which are handled by inheritance but callable):**

*   **Admin/Owner Functions (7):**
    1.  `setERC1155Contract`: Sets the address of the external ERC-1155 contract.
    2.  `setFusionParams`: Configures the catalyst and fragment costs required for fusion.
    3.  `setDecayParams`: Sets the rate of energy decay, staking attribute boost, and staking energy regeneration rate.
    4.  `setEntanglementParams`: Sets the attribute boost and decay multiplier effects from entanglement.
    5.  `setUpgradeParams`: Configures the costs and attribute boost amount for upgrading NFTs.
    6.  `setSalvageParams`: Configures the return percentage of fragments and catalyst for salvaging NFTs.
    7.  `setExternalInfluence`: Sets the global external influence factor affecting dynamic attributes.
    8.  `adminMint`: Allows the contract owner to mint NFTs directly with initial attributes and energy. (8)

*   **Query Functions (5):**
    9.  `getNFTData`: Retrieves the static base data stored for an NFT.
    10. `getCurrentAttributes`: Calculates and returns the dynamic attributes of an NFT based on its current state and global factors.
    11. `calculateCurrentEnergy`: A helper view function to see the calculated energy level without triggering state updates.
    12. `getEnergyLevel`: Returns the current energy level (wrapper around `calculateCurrentEnergy`).
    13. `isStaked`: Checks the staking status of an NFT.
    14. `getEntangledWith`: Returns the ID of the NFT it's entangled with, or 0. (6)

*   **Core Mechanics Functions (Public/External) (10):**
    15. `fuseNFTs`: Burns two NFTs and required fragments/catalysts to mint a new NFT with derived and boosted attributes.
    16. `stakeNFT`: Changes the NFT's state to staked, preventing decay and enabling staking benefits.
    17. `unstakeNFT`: Changes the NFT's state to unstaked, allowing decay and transfers again.
    18. `rechargeEnergy`: Allows the owner to consume fragments to increase the NFT's energy level.
    19. `triggerDecay`: Public function allowing anyone to pay gas to update an NFT's energy based on elapsed time (applies decay/regen).
    20. `entangleNFTs`: Links two NFTs together, requiring a catalyst.
    21. `disentangleNFTs`: Breaks the entanglement link between two NFTs, requiring a catalyst.
    22. `upgradeAttributes`: Consumes fragments/catalysts to permanently increase the base attributes of an NFT.
    23. `salvageNFT`: Burns an NFT and returns a portion of its theoretical cost in fragments/catalysts, requiring a salvage catalyst.
    24. `transferWithEnergy`: Allows transferring an NFT and a specified amount of a fragment type to a single recipient in one transaction. (10)

*   **ERC721 & Metadata Functions (2):**
    25. `tokenURI`: Generates a dynamic URI pointing to metadata that includes the NFT's current calculated attributes.
    26. `supportsInterface`: Standard ERC165 implementation required by ERC721. (2)

Total public/external functions related to the *unique logic* are 8 (Admin) + 6 (Query) + 10 (Mechanics) + 1 (tokenURI) = 25+. Including `supportsInterface` and standard inherited view functions like `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `tokenByIndex`, `tokenOfOwnerByIndex`, `totalSupply` brings the total well over 20. The core unique callable functions are the 10 mechanics functions plus the specialized queries and admin settings.

**Prerequisites for Deployment:**

*   An ERC-1155 contract already deployed to the network, which will represent the "Quantum Fragments" and "Catalysts". This contract must have `safeTransferFrom`, `safeBatchTransferFrom`, `balanceOf`, `burn` (callable by this Fusion contract after approval), and `mint` (callable by this Fusion contract, likely requiring a MINTER role granted to the Fusion contract address).
*   The user interacting with `fuseNFTs`, `rechargeEnergy`, `entangleNFTs`, `disentangleNFTs`, `upgradeAttributes`, `salvageNFT`, or `transferWithEnergy` must have first called `setApprovalForAll` on the *ERC-1155 contract* to grant the `QuantumFusionNFT` contract approval to spend their fragment/catalyst tokens.

This contract provides a framework for highly interactive and dynamic NFTs, moving beyond simple static ownership into a system where NFTs evolve, require maintenance, and interact with other tokens and each other.