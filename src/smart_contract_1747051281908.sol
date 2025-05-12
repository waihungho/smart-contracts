Okay, let's design a smart contract around a dynamic, evolving NFT concept with integrated staking and influence mechanics. We'll call it the "EtherealFusion Nexus".

This contract will manage unique digital assets called "Essences" (ERC-721 NFTs). These Essences have on-chain attributes that can change over time and through user interaction. Users can stake Ether (or potentially a linked ERC-20 token) to gain "Influence," which affects the properties of newly minted Essences and allows users to perform actions like enhancing or mutating existing Essences. A core mechanic is "Fusion," where two Essences can be combined to create a new, potentially more powerful or rarer Essence with inherited and mutated traits.

This concept combines elements of dynamic NFTs, generative parameters (influenced by stakers/events), staking for utility/influence, and a unique crafting/evolution mechanic (fusion), aiming for something beyond standard marketplaces or simple collectibles.

---

**EtherealFusion Nexus Contract Outline and Function Summary**

*   **Concept:** A system for managing dynamic, evolving ERC-721 NFTs ("Essences") whose on-chain attributes can be influenced, enhanced, mutated, and fused. Users stake ETH to gain "Influence" which affects attribute generation and allows for interaction with Essences.
*   **Tokens:** Manages ERC-721 Essences. Staking uses native ETH.
*   **Core Mechanics:**
    *   **Minting:** Create new Essences with attributes influenced by recent block data and staker influence.
    *   **Staking:** Stake ETH to accumulate Influence.
    *   **Influence:** A score derived from staked ETH, used to bias attribute generation and enable certain actions.
    *   **Fusion:** Combine two Essences to create a new one, inheriting/mutating attributes. Input Essences are burned.
    *   **Enhancement:** Use ETH to directly increase specific attributes of an Essence.
    *   **Mutation:** Use ETH/Influence to randomly re-roll or modify Essence attributes.
    *   **Dynamic Attributes:** Essence properties are stored on-chain and can change.
*   **Key Features:**
    *   ERC-721 compliant Essences.
    *   Integrated ETH staking mechanism.
    *   Influence calculation based on stake.
    *   On-chain storage and manipulation of Essence attributes.
    *   Fusion mechanic with attribute inheritance/mutation.
    *   Pausable for emergencies.
    *   Fee collection and withdrawal.

---

**Function Summary:**

**I. Core ERC-721 Functions (Standard):**
1.  `balanceOf(address owner)`: Returns the number of Essences owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Essence.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers an Essence (legacy, less safe).
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers an Essence, safer version.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers an Essence with data, safer version.
6.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific Essence.
7.  `getApproved(uint256 tokenId)`: Gets the approved address for an Essence.
8.  `setApprovalForAll(address operator, bool approved)`: Approves/unapproves an operator for all Essences.
9.  `isApprovedForAll(address owner, address operator)`: Checks if an address is an approved operator for another.

**II. Essence Management & Interaction:**
10. `mintEssence(uint256 userProvidedSeed)`: Mints a new Essence. Requires ETH payment. Attributes influenced by block data, seed, and staker influence.
11. `getEssenceAttributes(uint256 essenceId)`: Retrieves the current on-chain attributes of an Essence.
12. `fuseEssences(uint256 essenceId1, uint256 essenceId2, uint256 userProvidedSeed)`: Fuses two owned Essences into a new one. Requires ETH payment. Burns inputs, mints new output.
13. `enhanceEssence(uint256 essenceId, uint8 attributeIndex, uint256 amount)`: Increases a specific attribute of an owned Essence. Requires ETH payment.
14. `mutateEssence(uint256 essenceId, uint256 userProvidedSeed)`: Randomly modifies attributes of an owned Essence. Requires ETH payment or sufficient Influence.
15. `getEssenceAttributeNames()`: Returns the human-readable names for the attributes.
16. `getEssenceFusionInputCount(uint256 essenceId)`: Returns how many times this Essence has been used as an input in a fusion.
17. `getEssenceFusionDepth(uint256 essenceId)`: Returns the "generation" or depth of fusion for this Essence (0 for minted, 1+ for fused).

**III. Staking & Influence:**
18. `stakeETH()`: Stakes calling user's attached ETH to gain Influence.
19. `unstakeETH(uint256 amount)`: Unstakes a specified amount of ETH.
20. `getUserStakedETH(address user)`: Returns the amount of ETH staked by a specific user.
21. `getTotalStakedETH()`: Returns the total amount of ETH staked in the contract.
22. `getInfluence(address user)`: Calculates and returns the current Influence score for a user (based on staked ETH).
23. `setInfluenceRate(uint256 rate)`: Owner function to set the rate of Influence gained per staked Wei.

**IV. Query & Utility:**
24. `totalSupply()`: Returns the total number of Essences minted.
25. `getEssenceAttributeRanges()`: Returns the base min/max ranges for attributes set by the owner.
26. `getMintingFee()`: Returns the current fee to mint an Essence.
27. `getFusionFee()`: Returns the current fee to fuse Essences.
28. `getEnhanceCostPerAttribute()`: Returns the cost per unit of attribute enhancement.
29. `getMutationCost()`: Returns the cost for mutation.

**V. Admin & Maintenance (Owner Only):**
30. `withdrawFees(address payable recipient)`: Withdraws accumulated ETH fees.
31. `pauseContract()`: Pauses certain critical contract functions (minting, fusion, enhance, mutate, stake).
32. `unpauseContract()`: Unpauses the contract.
33. `setMintingFee(uint256 fee)`: Sets the fee for minting.
34. `setFusionFee(uint256 fee)`: Sets the fee for fusion.
35. `setEnhanceCostPerAttribute(uint256 cost)`: Sets the cost per unit for enhancement.
36. `setMutationCost(uint256 cost)`: Sets the cost for mutation.
37. `setBaseAttributeRanges(uint256 min, uint256 max)`: Sets the base min/max range used during attribute generation.
38. `setEssenceAttributeNames(string[] memory names)`: Sets the human-readable names for attributes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary (Copied from above)
/*
**EtherealFusion Nexus Contract Outline and Function Summary**

*   **Concept:** A system for managing dynamic, evolving ERC-721 NFTs ("Essences") whose on-chain attributes can be influenced, enhanced, mutated, and fused. Users stake ETH to gain "Influence" which affects the properties of newly minted Essences and allows users to perform actions like enhancing or mutating existing Essences. A core mechanic is "Fusion," where two Essences can be combined to create a new, potentially more powerful or rarer Essence with inherited and mutated traits.
*   **Tokens:** Manages ERC-721 Essences. Staking uses native ETH.
*   **Core Mechanics:**
    *   **Minting:** Create new Essences with attributes influenced by recent block data and staker influence.
    *   **Staking:** Stake ETH to accumulate Influence.
    *   **Influence:** A score derived from staked ETH, used to bias attribute generation and enable certain actions.
    *   **Fusion:** Combine two Essences to create a new one, inheriting/mutating attributes. Input Essences are burned.
    *   **Enhancement:** Use ETH to directly increase specific attributes of an Essence.
    *   **Mutation:** Use ETH/Influence to randomly re-roll or modify Essence attributes.
    *   **Dynamic Attributes:** Essence properties are stored on-chain and can change.
*   **Key Features:**
    *   ERC-721 compliant Essences.
    *   Integrated ETH staking mechanism.
    *   Influence calculation based on stake.
    *   On-chain storage and manipulation of Essence attributes.
    *   Fusion mechanic with attribute inheritance/mutation.
    *   Pausable for emergencies.
    *   Fee collection and withdrawal.

---

**Function Summary:**

**I. Core ERC-721 Functions (Standard):**
1.  `balanceOf(address owner)`: Returns the number of Essences owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Essence.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers an Essence (legacy, less safe).
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers an Essence, safer version.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers an Essence with data, safer version.
6.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific Essence.
7.  `getApproved(uint256 tokenId)`: Gets the approved address for an Essence.
8.  `setApprovalForAll(address operator, bool approved)`: Approves/unapproves an operator for all Essences.
9.  `isApprovedForAll(address owner, address operator)`: Checks if an address is an approved operator for another.

**II. Essence Management & Interaction:**
10. `mintEssence(uint256 userProvidedSeed)`: Mints a new Essence. Requires ETH payment. Attributes influenced by block data, seed, and staker influence.
11. `getEssenceAttributes(uint256 essenceId)`: Retrieves the current on-chain attributes of an Essence.
12. `fuseEssences(uint256 essenceId1, uint256 essenceId2, uint256 userProvidedSeed)`: Fuses two owned Essences into a new one. Requires ETH payment. Burns inputs, mints new output.
13. `enhanceEssence(uint256 essenceId, uint8 attributeIndex, uint256 amount)`: Increases a specific attribute of an owned Essence. Requires ETH payment.
14. `mutateEssence(uint256 essenceId, uint256 userProvidedSeed)`: Randomly modifies attributes of an owned Essence. Requires ETH payment or sufficient Influence.
15. `getEssenceAttributeNames()`: Returns the human-readable names for the attributes.
16. `getEssenceFusionInputCount(uint256 essenceId)`: Returns how many times this Essence has been used as an input in a fusion.
17. `getEssenceFusionDepth(uint256 essenceId)`: Returns the "generation" or depth of fusion for this Essence (0 for minted, 1+ for fused).

**III. Staking & Influence:**
18. `stakeETH()`: Stakes calling user's attached ETH to gain Influence.
19. `unstakeETH(uint256 amount)`: Unstakes a specified amount of ETH.
20. `getUserStakedETH(address user)`: Returns the amount of ETH staked by a specific user.
21. `getTotalStakedETH()`: Returns the total amount of ETH staked in the contract.
22. `getInfluence(address user)`: Calculates and returns the current Influence score for a user (based on staked ETH).
23. `setInfluenceRate(uint256 rate)`: Owner function to set the rate of Influence gained per staked Wei.

**IV. Query & Utility:**
24. `totalSupply()`: Returns the total number of Essences minted.
25. `getEssenceAttributeRanges()`: Returns the base min/max ranges for attributes set by the owner.
26. `getMintingFee()`: Returns the current fee to mint an Essence.
27. `getFusionFee()`: Returns the current fee to fuse Essences.
28. `getEnhanceCostPerAttribute()`: Returns the cost per unit of attribute enhancement.
29. `getMutationCost()`: Returns the cost for mutation.

**V. Admin & Maintenance (Owner Only):**
30. `withdrawFees(address payable recipient)`: Withdraws accumulated ETH fees.
31. `pauseContract()`: Pauses certain critical contract functions (minting, fusion, enhance, mutate, stake).
32. `unpauseContract()`: Unpauses the contract.
33. `setMintingFee(uint256 fee)`: Sets the fee for minting.
34. `setFusionFee(uint256 fee)`: Sets the fee for fusion.
35. `setEnhanceCostPerAttribute(uint256 cost)`: Sets the cost per unit for enhancement.
36. `setMutationCost(uint256 cost)`: Sets the cost for mutation.
37. `setBaseAttributeRanges(uint256 min, uint256 max)`: Sets the base min/max range used during attribute generation.
38. `setEssenceAttributeNames(string[] memory names)`: Sets the human-readable names for attributes.
*/

contract EtherealFusionNexus is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _essenceIds;

    // --- State Variables ---

    // Essence Data
    struct EssenceAttributes {
        // Example attributes - can be anything conceptually (e.g., Radiance, Harmony, Stability, Mutation)
        uint256[] values;
    }
    mapping(uint256 => EssenceAttributes) private _essenceAttributes;
    mapping(uint256 => uint256) private _essenceFusionInputCount; // How many times this essence was an INPUT to a fusion
    mapping(uint256 => uint256) private _essenceFusionDepth; // Generation (0 for minted, 1+ for fused)

    string[] private _essenceAttributeNames; // Human-readable names
    uint256 private _baseAttributeMin; // Base minimum range for attributes
    uint256 private _baseAttributeMax; // Base maximum range for attributes
    uint8 private constant NUM_ATTRIBUTES = 4; // Fixed number of attributes for simplicity

    // Staking & Influence
    mapping(address => uint256) private _stakedETH;
    uint256 private _totalStakedETH;
    uint256 private _influenceRate = 1; // 1 Influence point per Wei staked (can be adjusted)

    // Fees
    uint256 private _mintingFee;
    uint256 private _fusionFee;
    uint256 private _enhanceCostPerAttribute = 1 ether; // Cost per unit increase per attribute
    uint256 private _mutationCost = 0.1 ether;

    // --- Events ---

    event EssenceMinted(uint256 indexed tokenId, address indexed owner, EssenceAttributes attributes);
    event EssencesFused(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newEssenceId, EssenceAttributes newAttributes);
    event EssenceEnhanced(uint256 indexed tokenId, uint8 indexed attributeIndex, uint256 amount, EssenceAttributes newAttributes);
    event EssenceMutated(uint256 indexed tokenId, EssenceAttributes newAttributes);
    event ETHStaked(address indexed user, uint256 amount, uint256 totalStaked);
    event ETHUnstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event InfluenceRateUpdated(uint256 newRate);
    event AttributeRangesUpdated(uint256 min, uint256 max);
    event AttributeNamesUpdated(string[] names);
    event EnhanceCostUpdated(uint256 newCost);
    event MutationCostUpdated(uint256 newCost);

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMintingFee,
        uint256 initialFusionFee,
        uint256 initialEnhanceCost,
        uint256 initialMutationCost,
        uint256 initialBaseMinAttr,
        uint256 initialBaseMaxAttr,
        string[] memory initialAttributeNames
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
        ReentrancyGuard()
    {
        require(initialBaseMinAttr <= initialBaseMaxAttr, "Min must be <= Max");
        require(initialAttributeNames.length == NUM_ATTRIBUTES, "Incorrect number of attribute names");

        _mintingFee = initialMintingFee;
        _fusionFee = initialFusionFee;
        _enhanceCostPerAttribute = initialEnhanceCost;
        _mutationCost = initialMutationCost;
        _baseAttributeMin = initialBaseMinAttr;
        _baseAttributeMax = initialBaseMaxAttr;
        _essenceAttributeNames = initialAttributeNames;

        // Initialize attributes mapping with empty arrays
        // This isn't strictly needed as mappings default to empty, but conceptually clearer
    }

    // --- Modifiers ---

    modifier onlyEssenceOwner(uint256 essenceId) {
        require(_ownerOf(essenceId) == msg.sender, "Caller is not the essence owner");
        _;
    }

    modifier essenceExists(uint256 essenceId) {
        require(_exists(essenceId), "Essence does not exist");
        _;
    }

    // --- Core ERC-721 Functions (Standard) ---
    // (These are inherited and implemented by ERC721 contract)
    // balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll
    // We just override totalSupply as it's not automatically inherited with Counters

    /**
     * @dev See {IERC721Metadata-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _essenceIds.current();
    }

    // --- Essence Management & Interaction ---

    /**
     * @dev Mints a new Ethereal Essence NFT.
     * Attributes are generated based on block data, user seed, and staker influence.
     * Requires payment of the minting fee.
     * @param userProvidedSeed A seed provided by the user to influence randomness.
     */
    function mintEssence(uint256 userProvidedSeed) public payable whenNotPaused nonReentrant {
        require(msg.value >= _mintingFee, "Insufficient ETH for minting fee");

        uint256 newTokenId = _essenceIds.current();
        _essenceIds.increment();

        // Generate initial attributes based on block hash, user seed, and total influence
        // This is a simplified example. Real randomness on-chain is complex.
        // keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, userProvidedSeed))
        // block.difficulty is deprecated after The Merge. Using block.timestamp and previous blockhash is common,
        // but block.timestamp can be slightly manipulated, and previous blockhash has limited entropy.
        // For a truly production system, consider Chainlink VRF or similar oracle for randomness.
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, newTokenId, userProvidedSeed));
        EssenceAttributes memory newAttributes = _generateInitialAttributes(randomHash);

        _essenceAttributes[newTokenId] = newAttributes;
        _essenceFusionDepth[newTokenId] = 0; // 0 indicates it was minted, not fused

        _safeMint(msg.sender, newTokenId);

        emit EssenceMinted(newTokenId, msg.sender, newAttributes);

        // Send any excess payment back to the sender
        if (msg.value > _mintingFee) {
            payable(msg.sender).transfer(msg.value - _mintingFee);
        }
    }

    /**
     * @dev Retrieves the current attributes for a given Essence ID.
     * @param essenceId The ID of the Essence.
     * @return An array of attribute values.
     */
    function getEssenceAttributes(uint256 essenceId) public view essenceExists(essenceId) returns (uint256[] memory) {
        return _essenceAttributes[essenceId].values;
    }

    /**
     * @dev Fuses two owned Essences into a new, unique Essence.
     * Input Essences are burned. Attributes of the new Essence are derived from the inputs and mutation.
     * Requires payment of the fusion fee.
     * @param essenceId1 The ID of the first Essence (will be burned).
     * @param essenceId2 The ID of the second Essence (will be burned).
     * @param userProvidedSeed A seed provided by the user to influence randomness in mutation.
     */
    function fuseEssences(uint256 essenceId1, uint256 essenceId2, uint256 userProvidedSeed) public payable whenNotPaused nonReentrant {
        require(essenceId1 != essenceId2, "Cannot fuse an essence with itself");
        require(_ownerOf(essenceId1) == msg.sender, "Caller does not own essence 1");
        require(_ownerOf(essenceId2) == msg.sender, "Caller does not own essence 2");
        require(_exists(essenceId1), "Essence 1 does not exist");
        require(_exists(essenceId2), "Essence 2 does not exist");
        require(msg.value >= _fusionFee, "Insufficient ETH for fusion fee");

        // Burn the input essences
        _burn(essenceId1);
        _burn(essenceId2);

        // Mark inputs as used in fusion
        _essenceFusionInputCount[essenceId1]++;
        _essenceFusionInputCount[essenceId2]++;

        uint256 newTokenId = _essenceIds.current();
        _essenceIds.increment();

        // Generate new attributes based on parents' attributes, randomness, and staker influence
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, newTokenId, userProvidedSeed, essenceId1, essenceId2));
        EssenceAttributes memory newAttributes = _generateFusedAttributes(essenceId1, essenceId2, randomHash);

        _essenceAttributes[newTokenId] = newAttributes;
        _essenceFusionDepth[newTokenId] = Math.max(_essenceFusionDepth[essenceId1], _essenceFusionDepth[essenceId2]) + 1; // New depth is max of parents + 1

        _safeMint(msg.sender, newTokenId);

        emit EssencesFused(essenceId1, essenceId2, newTokenId, newAttributes);

        // Send any excess payment back
        if (msg.value > _fusionFee) {
            payable(msg.sender).transfer(msg.value - _fusionFee);
        }
    }

    /**
     * @dev Enhances a specific attribute of an owned Essence.
     * Increases the attribute value by a specified amount, costing ETH per unit.
     * @param essenceId The ID of the Essence to enhance.
     * @param attributeIndex The index of the attribute to enhance (0 to NUM_ATTRIBUTES-1).
     * @param amount The amount to increase the attribute by.
     */
    function enhanceEssence(uint256 essenceId, uint8 attributeIndex, uint256 amount) public payable whenNotPaused nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) {
        require(attributeIndex < NUM_ATTRIBUTES, "Invalid attribute index");
        require(amount > 0, "Enhancement amount must be positive");

        uint256 totalCost = amount * _enhanceCostPerAttribute;
        require(msg.value >= totalCost, "Insufficient ETH for enhancement");

        _essenceAttributes[essenceId].values[attributeIndex] = _essenceAttributes[essenceId].values[attributeIndex] + amount; // Unchecked add is okay due to Solidity >= 0.8

        emit EssenceEnhanced(essenceId, attributeIndex, amount, _essenceAttributes[essenceId]);

        // Send any excess payment back
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    /**
     * @dev Mutates the attributes of an owned Essence.
     * Randomly modifies attributes based on a seed, potentially biased by staker influence.
     * Costs ETH or requires sufficient influence (simplified to ETH cost here).
     * @param essenceId The ID of the Essence to mutate.
     * @param userProvidedSeed A seed to influence randomness during mutation.
     */
    function mutateEssence(uint256 essenceId, uint256 userProvidedSeed) public payable whenNotPaused nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) {
        require(msg.value >= _mutationCost, "Insufficient ETH for mutation");

        // Generate mutation based on block data, user seed, and user influence
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, essenceId, userProvidedSeed));
        _applyMutation(essenceId, randomHash, msg.sender); // Helper applies changes

        emit EssenceMutated(essenceId, _essenceAttributes[essenceId]);

        // Send any excess payment back
        if (msg.value > _mutationCost) {
            payable(msg.sender).transfer(msg.value - _mutationCost);
        }
    }

    /**
     * @dev Returns the human-readable names for the Essence attributes.
     * @return An array of strings representing attribute names.
     */
    function getEssenceAttributeNames() public view returns (string[] memory) {
        return _essenceAttributeNames;
    }

    /**
     * @dev Returns how many times a specific Essence has been used as an input in a fusion.
     * @param essenceId The ID of the Essence.
     * @return The count of fusions where this Essence was an input.
     */
    function getEssenceFusionInputCount(uint256 essenceId) public view returns (uint256) {
        // No essenceExists check needed, mapping defaults to 0
        return _essenceFusionInputCount[essenceId];
    }

    /**
     * @dev Returns the fusion depth (generation) of a specific Essence.
     * 0 for minted, 1+ for fused.
     * @param essenceId The ID of the Essence.
     * @return The fusion depth.
     */
    function getEssenceFusionDepth(uint256 essenceId) public view returns (uint256) {
        // No essenceExists check needed, mapping defaults to 0
        return _essenceFusionDepth[essenceId];
    }


    // --- Staking & Influence ---

    /**
     * @dev Stakes the ETH sent with the transaction. Increases user's staked balance.
     */
    function stakeETH() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must stake a non-zero amount");
        _stakedETH[msg.sender] += msg.value;
        _totalStakedETH += msg.value;
        emit ETHStaked(msg.sender, msg.value, _stakedETH[msg.sender]);
    }

    /**
     * @dev Unstakes a specified amount of ETH.
     * @param amount The amount of ETH to unstake (in Wei).
     */
    function unstakeETH(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Must unstake a non-zero amount");
        require(_stakedETH[msg.sender] >= amount, "Insufficient staked ETH");

        _stakedETH[msg.sender] -= amount;
        _totalStakedETH -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ETHUnstaked(msg.sender, amount, _stakedETH[msg.sender]);
    }

    /**
     * @dev Returns the amount of ETH staked by a specific user.
     * @param user The address of the user.
     * @return The amount of staked ETH in Wei.
     */
    function getUserStakedETH(address user) public view returns (uint256) {
        return _stakedETH[user];
    }

    /**
     * @dev Returns the total amount of ETH staked across all users.
     * @return The total staked ETH in Wei.
     */
    function getTotalStakedETH() public view returns (uint256) {
        return _totalStakedETH;
    }

    /**
     * @dev Calculates and returns the Influence score for a user.
     * Based on their staked ETH and the global influence rate.
     * @param user The address of the user.
     * @return The calculated Influence score.
     */
    function getInfluence(address user) public view returns (uint256) {
        // Simple calculation: staked ETH * rate
        // Could be made more complex (e.g., time-weighted, decaying)
        return _stakedETH[user] * _influenceRate;
    }

    /**
     * @dev Sets the rate at which staked Wei translates to Influence points.
     * Only callable by the owner.
     * @param rate The new influence rate (Influence points per Wei).
     */
    function setInfluenceRate(uint256 rate) public onlyOwner {
        _influenceRate = rate;
        emit InfluenceRateUpdated(rate);
    }

    // --- Query & Utility ---

    /**
     * @dev Returns the current base minimum and maximum values used for initial attribute generation.
     * @return min The base minimum attribute value.
     * @return max The base maximum attribute value.
     */
    function getEssenceAttributeRanges() public view returns (uint256 min, uint256 max) {
        return (_baseAttributeMin, _baseAttributeMax);
    }

    /**
     * @dev Returns the current fee required to mint a new Essence.
     * @return The minting fee in Wei.
     */
    function getMintingFee() public view returns (uint256) {
        return _mintingFee;
    }

    /**
     * @dev Returns the current fee required to fuse two Essences.
     * @return The fusion fee in Wei.
     */
    function getFusionFee() public view returns (uint256) {
        return _fusionFee;
    }

     /**
     * @dev Returns the current cost per unit for enhancing an attribute.
     * @return The enhance cost per attribute unit in Wei.
     */
    function getEnhanceCostPerAttribute() public view returns (uint256) {
        return _enhanceCostPerAttribute;
    }

    /**
     * @dev Returns the current cost for mutating an Essence.
     * @return The mutation cost in Wei.
     */
    function getMutationCost() public view returns (uint256) {
        return _mutationCost;
    }


    // --- Admin & Maintenance (Owner Only) ---

    /**
     * @dev Allows the owner to withdraw accumulated ETH fees (from minting, fusion, enhancement, mutation).
     * Excludes staked ETH.
     * @param payable recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) public onlyOwner nonReentrant {
        uint256 balance = address(this).balance - _totalStakedETH;
        require(balance > 0, "No fees to withdraw");

        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ETH transfer failed");

        emit FeesWithdrawn(recipient, balance);
    }

    /**
     * @dev Pauses core contract functions (minting, fusion, enhance, mutate, stake).
     * Only callable by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the fee required to mint a new Essence.
     * Only callable by the owner.
     * @param fee The new minting fee in Wei.
     */
    function setMintingFee(uint256 fee) public onlyOwner {
        _mintingFee = fee;
    }

    /**
     * @dev Sets the fee required to fuse two Essences.
     * Only callable by the owner.
     * @param fee The new fusion fee in Wei.
     */
    function setFusionFee(uint256 fee) public onlyOwner {
        _fusionFee = fee;
    }

     /**
     * @dev Sets the cost per unit for enhancing an attribute.
     * Only callable by the owner.
     * @param cost The new enhance cost per attribute unit in Wei.
     */
    function setEnhanceCostPerAttribute(uint256 cost) public onlyOwner {
        _enhanceCostPerAttribute = cost;
    }

    /**
     * @dev Sets the cost for mutating an Essence.
     * Only callable by the owner.
     * @param cost The new mutation cost in Wei.
     */
    function setMutationCost(uint256 cost) public onlyOwner {
        _mutationCost = cost;
    }

    /**
     * @dev Sets the base minimum and maximum values used for initial attribute generation.
     * Only callable by the owner.
     * @param min The new base minimum attribute value.
     * @param max The new base maximum attribute value.
     */
    function setBaseAttributeRanges(uint256 min, uint256 max) public onlyOwner {
        require(min <= max, "Min must be <= Max");
        _baseAttributeMin = min;
        _baseAttributeMax = max;
        emit AttributeRangesUpdated(min, max);
    }

    /**
     * @dev Sets the human-readable names for the Essence attributes.
     * Only callable by the owner.
     * @param names An array of strings for attribute names.
     */
    function setEssenceAttributeNames(string[] memory names) public onlyOwner {
         require(names.length == NUM_ATTRIBUTES, "Incorrect number of attribute names");
        _essenceAttributeNames = names;
        emit AttributeNamesUpdated(names);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates initial attributes for a new Essence.
     * Uses a hash for pseudo-randomness and is potentially influenced by total staked ETH.
     * @param randomHash A hash value for randomness.
     * @return A new EssenceAttributes struct.
     */
    function _generateInitialAttributes(bytes32 randomHash) internal view returns (EssenceAttributes memory) {
        EssenceAttributes memory newAttributes;
        newAttributes.values = new uint256[](NUM_ATTRIBUTES);

        uint256 totalInfluence = _totalStakedETH * _influenceRate; // Use total staked ETH for global influence bias

        // Simple example: influence slightly biases towards higher values
        uint256 range = _baseAttributeMax - _baseAttributeMin;

        for (uint i = 0; i < NUM_ATTRIBUTES; i++) {
            uint256 seed = uint256(keccak256(abi.encodePacked(randomHash, i)));
            uint256 baseValue = (_baseAttributeMin + (seed % (range + 1)));

            // Apply a small bias based on total influence relative to a benchmark (e.g., 100 ETH staked)
            // This part is conceptual and needs careful tuning based on desired trait distribution.
            // Avoid large biases that make outcomes too predictable.
            uint256 influenceBias = (totalInfluence > 1 ether) ? (totalInfluence / 1 ether) : 0; // Example bias factor
            influenceBias = influenceBias % (range / 10 + 1); // Keep bias within a reasonable range

            newAttributes.values[i] = baseValue + influenceBias;

             // Ensure value doesn't exceed a conceptual maximum (e.g., _baseAttributeMax + some buffer)
             // Or maybe values can exceed base max, but minting bias is capped.
             // Let's cap initial bias for simplicity.
             newAttributes.values[i] = Math.min(newAttributes.values[i], _baseAttributeMax + (range / 5)); // Cap bias effect
        }

        return newAttributes;
    }

    /**
     * @dev Generates attributes for a new Essence resulting from fusion.
     * Combines attributes of parents and applies mutation based on randomness and staker influence.
     * @param essenceId1 The ID of the first parent Essence.
     * @param essenceId2 The ID of the second parent Essence.
     * @param randomHash A hash value for randomness.
     * @return A new EssenceAttributes struct.
     */
    function _generateFusedAttributes(uint256 essenceId1, uint256 essenceId2, bytes32 randomHash) internal view returns (EssenceAttributes memory) {
        EssenceAttributes memory parent1Attrs = _essenceAttributes[essenceId1];
        EssenceAttributes memory parent2Attrs = _essenceAttributes[essenceId2];
        EssenceAttributes memory newAttributes;
        newAttributes.values = new uint256[](NUM_ATTRIBUTES);

        uint256 fusingUserInfluence = getInfluence(msg.sender);

        for (uint i = 0; i < NUM_ATTRIBUTES; i++) {
            // Basic combination: e.g., average or weighted average
            uint256 combinedValue = (parent1Attrs.values[i] + parent2Attrs.values[i]) / 2;

            // Apply mutation based on randomness and user influence
            // Influence could increase the chance/magnitude of mutation
            uint256 mutationSeed = uint256(keccak256(abi.encodePacked(randomHash, i)));
            int256 mutationAmount = _calculateMutationAmount(mutationSeed, fusingUserInfluence);

            // Apply mutation, ensuring values don't go below zero (attributes are uint)
            if (mutationAmount < 0) {
                 if (combinedValue < uint256(-mutationAmount)) {
                     newAttributes.values[i] = 0; // Don't go below zero
                 } else {
                     newAttributes.values[i] = combinedValue - uint256(-mutationAmount);
                 }
            } else {
                 newAttributes.values[i] = combinedValue + uint256(mutationAmount);
            }

            // Optional: Add a cap to attributes? Maybe they can grow indefinitely?
            // If a cap is desired: newAttributes.values[i] = Math.min(newAttributes.values[i], MAX_ATTRIBUTE_VALUE);
        }

        return newAttributes;
    }

    /**
     * @dev Applies mutation to an existing Essence's attributes.
     * Uses a hash for randomness and is potentially influenced by the mutating user's influence.
     * @param essenceId The ID of the Essence to mutate.
     * @param randomHash A hash value for randomness.
     * @param mutator The address of the user performing the mutation.
     */
    function _applyMutation(uint256 essenceId, bytes32 randomHash, address mutator) internal {
         uint256 mutatorInfluence = getInfluence(mutator);
         EssenceAttributes storage currentAttributes = _essenceAttributes[essenceId];

         for (uint i = 0; i < NUM_ATTRIBUTES; i++) {
             uint256 mutationSeed = uint256(keccak256(abi.encodePacked(randomHash, i, currentAttributes.values[i])));
             int256 mutationAmount = _calculateMutationAmount(mutationSeed, mutatorInfluence);

              // Apply mutation, ensuring values don't go below zero
             if (mutationAmount < 0) {
                  if (currentAttributes.values[i] < uint256(-mutationAmount)) {
                      currentAttributes.values[i] = 0;
                  } else {
                      currentAttributes.values[i] = currentAttributes.values[i] - uint256(-mutationAmount);
                  }
             } else {
                  currentAttributes.values[i] = currentAttributes.values[i] + uint256(mutationAmount);
             }
             // Optional: Cap attribute values if needed
         }
    }

    /**
     * @dev Helper to calculate a mutation amount based on randomness and influence.
     * Influence can increase the range or likelihood of positive/negative mutation.
     * Returns a signed integer to allow both increase and decrease.
     * @param seed A random seed.
     * @param influence The user's influence score.
     * @return The calculated mutation amount (can be negative).
     */
    function _calculateMutationAmount(uint256 seed, uint256 influence) internal pure returns (int256) {
        // Example logic: Mutation range is small, influence increases potential magnitude.
        // Using modulo for randomness means limited output, better PRNG is complex on-chain.
        // The 'randomness' here is primarily for conceptual demonstration.

        uint256 maxBaseMutation = 10; // Base max |mutation amount|
        uint256 influenceFactor = influence / (1 ether); // Influence adds potential magnitude (1 per ETH staked example)
        uint224 influenceAdjustedMax = uint224(Math.min(uint256(type(uint224).max), maxBaseMutation + influenceFactor)); // Cap influence effect

        uint256 rawMutation = seed % (influenceAdjustedMax * 2 + 1); // Range from 0 to 2*max + 0

        // Shift range to be centered around zero [-max, +max]
        int256 mutation = int256(rawMutation) - int256(influenceAdjustedMax);

        return mutation;
    }

    /**
     * @dev Internal function to get mutable reference to EssenceAttributes.
     * Useful for internal functions modifying attributes.
     */
    function _getEssenceAttributes(uint256 essenceId) internal storage returns (EssenceAttributes storage) {
        return _essenceAttributes[essenceId];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Used to clean up state when tokens are burned.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (to == address(0)) { // Token is being burned
             // Cleanup attributes to save gas/storage on the blockchain
            delete _essenceAttributes[tokenId];
            // _essenceFusionInputCount and _essenceFusionDepth map by ID, so they remain and can be queried even after burn,
            // showing the history of that specific ID before it was burned.
            // If you wanted to clean those up too, you would add:
            // delete _essenceFusionInputCount[tokenId];
            // delete _essenceFusionDepth[tokenId];
            // Keeping them allows querying history of burned tokens by ID.
        }
    }

    // --- Fallback function to receive ETH for staking ---
    receive() external payable {
        // If ETH is sent without calling stakeETH, it will be added to the contract balance
        // but not credited to the user's staked balance or influence.
        // We could forward to stakeETH(), but this might have reentrancy risks if not careful.
        // Explicit `stakeETH()` call is safer.
        // Adding a require or reverting ensures users don't accidentally send ETH without staking.
        // require(msg.sender == owner() || msg.data.length > 0, "Direct ETH deposits without function call are not supported");
        // For this contract, direct sends are allowed but just add to the balance without staking state.
        // Consider adding a require(msg.data.length == 0, "Call stakeETH()"); if you want to force staking.
    }
}
```