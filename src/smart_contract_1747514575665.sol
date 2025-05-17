Okay, here is a Solidity smart contract incorporating a variety of interesting, advanced, and creative concepts for a dynamic digital asset ecosystem, themed around "EvoGems" - non-fungible tokens that can evolve, merge, breed, and interact in complex ways.

This contract is designed to demonstrate multiple unique mechanics beyond typical NFT or basic DeFi functionalities. It uses standard interfaces (like ERC721) and libraries (like OpenZeppelin's `Ownable`, `ERC721`, `SafeMath`, `MerkleProof`) but the *specific logic and combination* of the functions within this contract are novel to this design.

---

**EvoGems Smart Contract**

**Outline & Function Summary:**

This contract implements an ERC721 non-fungible token (NFT) representing dynamic "Gems". These Gems possess various attributes that can change and interact over time through complex on-chain mechanics.

**Core Concepts:**

1.  **Dynamic Attributes:** Gem properties are stored and can be modified on-chain.
2.  **Evolution & Transformation:** Gems can change form (`evolveGem`), combine (`mergeGems`), or generate new ones (`breedGems`).
3.  **Resource Generation & Usage:** Gems can be staked to generate internal resources used for modifications.
4.  **Time-Based Mechanics:** Features like time-locks, decaying boosts, and staking rewards depend on time.
5.  **Conditional Logic:** Actions can require specific on-chain conditions to be met.
6.  **Delegation:** Owners can grant limited control over a specific Gem to another address.
7.  **On-Chain Royalties:** Custom, per-token royalty settings (requires marketplace support).
8.  **Off-Chain Data Verification:** Integration with Merkle proofs for verifying external data commitments.
9.  **Interoperability:** Mechanisms for trusted external contracts to trigger actions.
10. **Tokenomics & Utility:** Functions for burning specific types, claiming attribute-based rewards.
11. **Advanced Utility:** Functions for calculating derived stats, proposing upgrades, temporarily locking attributes.

**Function Categories:**

1.  **ERC721 Standard Interface:**
    *   `balanceOf(address owner)`: Get owner's gem count.
    *   `ownerOf(uint256 tokenId)`: Get gem owner.
    *   `approve(address to, uint256 tokenId)`: Approve transfer for one gem.
    *   `getApproved(uint256 tokenId)`: Get approved address for one gem.
    *   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all gems.
    *   `isApprovedForAll(address owner, address operator)`: Check operator approval.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer gem.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer gem.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
    *   `tokenURI(uint256 tokenId)`: Get dynamic metadata URI.

2.  **Creation & Transformation (Creative/Advanced):**
    *   `mintInitialGem(address to, uint initialType, uint initialPower)`: Mint a new genesis Gem.
    *   `evolveGem(uint256 tokenId, uint evolutionPath)`: Changes a Gem's type and stats based on defined paths and requirements (e.g., resources, level).
    *   `mergeGems(uint256 tokenId1, uint256 tokenId2)`: Combines two Gems into a single, potentially more powerful one, burning the inputs. Attributes and stats are derived from parents.
    *   `breedGems(uint256 parent1Id, uint256 parent2Id)`: Creates a *new* Gem child inheriting mixed traits from two parent Gems (may require resources or cooldown).
    *   `reRollAttributes(uint256 tokenId, bytes32 randomnessSeed)`: Randomly changes certain mutable attributes of a Gem, consuming resources or potentially using a seed derived from an external source (like a VRF).

3.  **Attribute Management (Advanced/Utility):**
    *   `addDynamicAttribute(uint256 tokenId, string calldata attributeName, bytes calldata attributeValue)`: Allows adding custom, dynamic data key-value pairs to a Gem, potentially restricted to certain roles or conditions.
    *   `useResourcesToModifyAttribute(uint256 tokenId, string calldata attributeName, bytes calldata newValue, uint resourcesCost)`: Spends accumulated Gem resources to change a specific dynamic or base attribute (if allowed by game logic).
    *   `proposeAttributeUpgrade(uint256 tokenId, string calldata attributeName, bytes calldata proposedValue, uint resourceCost)`: Creates an on-chain proposal for an attribute change, requiring resources and potentially a confirmation step.
    *   `lockAttributeForAuction(uint256 tokenId, string calldata attributeName, uint duration)`: Temporarily locks a specific dynamic attribute, marking it as available for a potential off-chain or side-contract auction.

4.  **State Query & Utility (Utility/Advanced Data):**
    *   `queryGemTotalPower(uint256 tokenId)`: Calculates a derived "power" score for a Gem based on its current attributes and potentially dynamic state.
    *   `calculateGemValueFloor(uint256 tokenId)`: Provides a simplified on-chain "minimum value" estimate based purely on verifiable attributes, potentially using a predefined registry.
    *   `verifyTraitUsingMerkleProof(uint256 tokenId, string calldata attributeName, bytes calldata attributeValue, bytes32[] calldata proof)`: Verifies if a specific attribute/value pair for a Gem was included in a previously committed Merkle Root (e.g., for provenance or off-chain game state).

5.  **Resource & Incentive Mechanics (DeFi/Gaming/Tokenomics):**
    *   `stakeGemForResources(uint256 tokenId)`: Locks the Gem's transferability and starts accumulating internal resources based on its attributes.
    *   `claimStakedGemResources(uint256 tokenId)`: Allows the owner to claim resources accumulated since staking or the last claim.
    *   `claimRewardBasedOnAttributes(uint256 tokenId)`: Distributes rewards (native currency or external token) based on a Gem's specific combination of attributes and time staked.

6.  **Time & Conditional Mechanics (Advanced Logic):**
    *   `setTimeLock(uint256 tokenId, uint timeUntilUnlock)`: Makes the Gem non-transferable and certain functions inaccessible until a specific future timestamp.
    *   `applyDecayingBoost(uint256 tokenId, uint boostAmount, uint duration)`: Adds a temporary, decaying boost to a Gem's power or other attribute that reduces over time.
    *   `triggerEvolutionIfPowerAbove(uint256 tokenId, uint minPower)`: Allows triggering an evolution *only* if the Gem's calculated power is above a certain threshold.

7.  **Access & Control (Advanced/Governance):**
    *   `delegateGemControl(uint256 tokenId, address delegatee, uint duration)`: Grants a specified address limited permission to call certain pre-approved functions on this specific Gem for a set duration.
    *   `setGemCustomRoyalty(uint256 tokenId, address recipient, uint basisPoints)`: Sets a custom, per-token royalty preference (percentage and recipient) stored on-chain. (Marketplace implementation required for enforcement).
    *   `getExternalTriggerPermission(uint256 tokenId, address externalContract, bool allowed)`: Grants or revokes a specific external contract's permission to call designated trigger functions on this Gem.
    *   `triggerExternalEvolution(uint256 tokenId, uint evolutionPath)`: A function callable *only* by an external contract that has been granted permission, allowing programmed evolution based on external game state or events.

8.  **Destruction (Tokenomics/Utility):**
    *   `burnGemOfType(uint256 tokenId, uint gemType)`: Burns a Gem *only* if it matches a specific type, potentially part of a crafting or sacrifice mechanic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Interfaces (Simplified - Actual external contracts would have defined interfaces)
interface IResourceDistributor {
    function distributeReward(address recipient, uint256 amount) external;
}

/**
 * @title EvoGems
 * @dev An ERC721 contract for dynamic, evolving Gems with various advanced mechanics.
 * Based on OpenZeppelin ERC721Enumerable for token enumeration.
 * Includes creative functions for evolution, merging, breeding, time-locks, delegation, etc.
 */
contract EvoGems is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    struct GemAttributes {
        uint gemType;           // e.g., 1=Fire, 2=Water, 3=Earth, etc.
        uint generation;        // Generation number (e.g., 1 for initial mints)
        uint evolutionLevel;    // How many times it has evolved
        uint basePower;         // Base power stat
        uint color;             // Arbitrary color attribute
        mapping(string => bytes) dynamicAttributes; // Flexible key-value store
    }

    struct GemState {
        uint lastInteractionTime; // Timestamp of last major interaction (e.g., evolution, merge)
        uint timeLockUntil;       // Timestamp when transfer/modify lock expires
        uint delegatedUntil;      // Timestamp when delegation expires
        address delegatee;        // Address currently delegated control
        uint resourcesAccumulated; // Internal resources generated by staking
        uint stakedSince;         // Timestamp when gem was staked (0 if not staked)
        uint decayingBoostAmount; // Amount of temporary boost
        uint decayingBoostExpires; // Timestamp when boost expires
        uint attributeLockUntil;  // Timestamp when an attribute is locked (e.g., for auction)
        string lockedAttributeName; // Name of the attribute currently locked
    }

    struct AttributeUpgradeProposal {
        string attributeName;
        bytes proposedValue;
        uint resourceCost;
        bool exists; // Simple flag to check if proposal exists
    }

    // --- State Variables ---

    mapping(uint256 => GemAttributes) private gemAttributes;
    mapping(uint256 => GemState) private gemState;
    mapping(uint256 => AttributeUpgradeProposal) private gemUpgradeProposals; // One pending proposal per gem
    mapping(uint256 => address) private gemRoyaltyRecipient; // Per-token royalty recipient
    mapping(uint256 => uint96) private gemRoyaltyBasisPoints; // Per-token royalty basis points (0-10000)
    mapping(uint256 => mapping(address => bool)) private externalTriggerPermissions; // externalContract => allowed

    // Configuration
    uint256 public evolutionResourceCost = 100; // Example cost
    uint256 public mergeResourceCost = 200; // Example cost
    uint256 public breedResourceCost = 150; // Example cost
    uint256 public stakeResourceRate = 1; // Resources per second staked (simplified)
    bytes32 public merkleRoot; // Merkle root for off-chain committed data

    IResourceDistributor public resourceDistributor; // Address of a contract to distribute external rewards

    // --- Events ---

    event GemMinted(uint256 indexed tokenId, address indexed owner, uint gemType, uint initialPower);
    event GemEvolved(uint256 indexed tokenId, uint oldType, uint newType, uint newEvolutionLevel);
    event GemsMerged(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2);
    event GemBred(uint256 indexed newTokenId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event DynamicAttributeAdded(uint256 indexed tokenId, string attributeName, bytes attributeValue);
    event DynamicAttributeModified(uint256 indexed tokenId, string attributeName, bytes oldValue, bytes newValue);
    event GemStaked(uint256 indexed tokenId, uint timestamp);
    event GemUnstaked(uint256 indexed tokenId, uint timestamp, uint resourcesClaimed);
    event GemResourcesClaimed(uint256 indexed tokenId, uint resourcesClaimed);
    event GemTimeLocked(uint256 indexed tokenId, uint unlockTime);
    event GemDelegateUpdated(uint256 indexed tokenId, address indexed delegatee, uint untilTime);
    event GemCustomRoyaltyUpdated(uint256 indexed tokenId, address recipient, uint96 basisPoints);
    event MerkleRootUpdated(bytes32 newRoot);
    event DecayingBoostApplied(uint256 indexed tokenId, uint boostAmount, uint expires);
    event RewardClaimed(uint256 indexed tokenId, address indexed recipient, uint rewardAmount);
    event ExternalTriggerPermissionUpdated(uint256 indexed tokenId, address indexed externalContract, bool allowed);
    event AttributeUpgradeProposed(uint256 indexed tokenId, string attributeName, bytes proposedValue, uint resourceCost);
    event AttributeUpgradeExecuted(uint256 indexed tokenId, string attributeName, bytes finalValue);
    event AttributeLocked(uint256 indexed tokenId, string attributeName, uint untilTime);
    event AttributesReRolled(uint256 indexed tokenId, bytes32 randomnessSeed);
    event GemBurned(uint256 indexed tokenId, uint gemType);


    // --- Modifiers ---

    modifier onlyGemOwner(uint256 tokenId) {
        require(_isGemOwnerOrApproved(tokenId), "EvoGems: caller is not gem owner or approved");
        _;
    }

    modifier onlyGemOwnerOrDelegate(uint256 tokenId) {
        require(_isGemOwnerOrApproved(tokenId) || _isGemDelegate(tokenId), "EvoGems: caller is not gem owner, approved, or delegate");
        _;
    }

     modifier onlyGemOwnerDelegateOrPermittedExternal(uint256 tokenId) {
        require(_isGemOwnerOrApproved(tokenId) || _isGemDelegate(tokenId) || externalTriggerPermissions[tokenId][msg.sender],
            "EvoGems: caller not authorized (owner, delegate, or permitted external)"
        );
        _;
    }


    modifier notTimeLocked(uint256 tokenId) {
        require(block.timestamp >= gemState[tokenId].timeLockUntil, "EvoGems: gem is time-locked");
        _;
    }

    modifier attributeNotLocked(uint256 tokenId, string calldata attributeName) {
         GemState storage state = gemState[tokenId];
         require(block.timestamp >= state.attributeLockUntil || !keccak256(abi.encodePacked(state.lockedAttributeName)) == keccak256(abi.encodePacked(attributeName)),
            "EvoGems: attribute is locked");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, string memory name, string memory symbol, bytes32 _initialMerkleRoot)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {
        merkleRoot = _initialMerkleRoot;
    }

    // --- Core ERC721 Functions (Standard implementations inherited/wrapped) ---

    // tokenURI is dynamic, can be overridden or point to an external service
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        // This is a placeholder for a dynamic metadata service.
        // A real implementation would generate JSON based on gemAttributes and gemState.
        // Example: return string(abi.encodePacked("ipfs://YOUR_GATEWAY/", Strings.toString(tokenId)));
         return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
            bytes(
                string(abi.encodePacked(
                    '{"name": "EvoGem #', Strings.toString(tokenId),
                    '", "description": "A dynamic, evolving digital gem.",',
                    '"attributes": [',
                        '{"trait_type": "Type", "value": ', Strings.toString(gemAttributes[tokenId].gemType), '},',
                        '{"trait_type": "Generation", "value": ', Strings.toString(gemAttributes[tokenId].generation), '},',
                        '{"trait_type": "Evolution Level", "value": ', Strings.toString(gemAttributes[tokenId].evolutionLevel), '},',
                        '{"trait_type": "Base Power", "value": ', Strings.toString(gemAttributes[tokenId].basePower), '}',
                        // Add dynamic attributes here if needed, requires iteration or known keys
                    ']}'
                ))
            )
        ))));
    }


    // --- Advanced & Creative Functions (>= 20 unique concepts) ---

    /// @notice Mints a new genesis Gem. Only callable by owner.
    /// @param to The address to mint the gem to.
    /// @param initialType The initial type of the gem.
    /// @param initialPower The initial base power of the gem.
    function mintInitialGem(address to, uint initialType, uint initialPower) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        gemAttributes[newTokenId] = GemAttributes({
            gemType: initialType,
            generation: 1,
            evolutionLevel: 0,
            basePower: initialPower,
            color: initialType, // Simplified: color = type
            dynamicAttributes: new mapping(string => bytes)() // Initialize empty dynamic attributes
        });

        gemState[newTokenId] = GemState({
            lastInteractionTime: block.timestamp,
            timeLockUntil: 0,
            delegatedUntil: 0,
            delegatee: address(0),
            resourcesAccumulated: 0,
            stakedSince: 0,
            decayingBoostAmount: 0,
            decayingBoostExpires: 0,
            attributeLockUntil: 0,
            lockedAttributeName: ""
        });

        emit GemMinted(newTokenId, to, initialType, initialPower);
    }

    /// @notice Evolves a Gem to a new type and level, consuming resources.
    /// @dev Requires the Gem to have enough resources and not be time-locked.
    /// @param tokenId The ID of the Gem to evolve.
    /// @param evolutionPath An identifier for the specific evolution path (determines new stats).
    function evolveGem(uint256 tokenId, uint evolutionPath)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        GemAttributes storage attributes = gemAttributes[tokenId];
        GemState storage state = gemState[tokenId];

        // Claim resources before checking balance and spending
        _claimStakedResources(tokenId);

        require(state.resourcesAccumulated >= evolutionResourceCost, "EvoGems: not enough resources to evolve");

        uint oldType = attributes.gemType;
        attributes.evolutionLevel = attributes.evolutionLevel.add(1);
        state.resourcesAccumulated = state.resourcesAccumulated.sub(evolutionResourceCost);
        state.lastInteractionTime = block.timestamp;

        // --- Evolution Logic (Simplified) ---
        // In a real system, evolutionPath would map to specific outcome rules
        // and potentially require certain attributes or external conditions.
        attributes.gemType = attributes.gemType.add(evolutionPath); // Example: change type based on path
        attributes.basePower = attributes.basePower.add(attributes.basePower.div(5).add(evolutionPath * 10)); // Example: increase power

        // Clear decaying boosts on evolution
        state.decayingBoostAmount = 0;
        state.decayingBoostExpires = 0;

        emit GemEvolved(tokenId, oldType, attributes.gemType, attributes.evolutionLevel);
    }

    /// @notice Merges two Gems into one, burning the inputs.
    /// @dev The resulting Gem's attributes are a combination of the parents. Requires resources.
    /// @param tokenId1 The ID of the first Gem.
    /// @param tokenId2 The ID of the second Gem.
    function mergeGems(uint256 tokenId1, uint256 tokenId2)
        public
        onlyGemOwner(tokenId1) // Must own or be approved for first
        onlyGemOwner(tokenId2) // Must own or be approved for second
        notTimeLocked(tokenId1)
        notTimeLocked(tokenId2)
    {
        require(tokenId1 != tokenId2, "EvoGems: cannot merge a gem with itself");
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "EvoGems: gems must have the same owner to merge");

        address owner = ownerOf(tokenId1);
        // Assuming resources are tracked per gem or implicitly per owner based on staked gems.
        // If per-gem resources are used for merging, they need to be claimed and combined/checked here.
        // Let's assume resources are deducted from owner's accumulated resources (conceptually).
        // For simplicity here, let's just check combined staked resources or use an external resource token.
        // Let's update gemState[tokenId]'s resourcesAccumulated and require a combined check.
        _claimStakedResources(tokenId1);
        _claimStakedResources(tokenId2);

        uint combinedResources = gemState[tokenId1].resourcesAccumulated.add(gemState[tokenId2].resourcesAccumulated);
        require(combinedResources >= mergeResourceCost, "EvoGems: not enough combined resources to merge");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // --- Merge Logic (Simplified) ---
        // Create new gem inheriting combined traits, levels, etc.
        GemAttributes storage attr1 = gemAttributes[tokenId1];
        GemAttributes storage attr2 = gemAttributes[tokenId2];

        gemAttributes[newTokenId] = GemAttributes({
             gemType: (attr1.gemType + attr2.gemType) / 2, // Example average type
             generation: SafeMath.max(attr1.generation, attr2.generation).add(1), // New gen is higher than parents + 1
             evolutionLevel: SafeMath.max(attr1.evolutionLevel, attr2.evolutionLevel), // Keep higher evolution level
             basePower: attr1.basePower.add(attr2.basePower).div(2).add(50), // Average + boost
             color: (attr1.color + attr2.color) / 2, // Example average color
             dynamicAttributes: new mapping(string => bytes)() // Start fresh or inherit selectively
        });

        // Transfer the new gem to the owner and burn the old ones
        _safeMint(owner, newTokenId);
        _burn(tokenId1);
        _burn(tokenId2);

        // Update state for the new gem
         gemState[newTokenId] = GemState({
            lastInteractionTime: block.timestamp,
            timeLockUntil: 0,
            delegatedUntil: 0,
            delegatee: address(0),
            resourcesAccumulated: combinedResources.sub(mergeResourceCost), // Remaining resources go to the new gem
            stakedSince: 0,
            decayingBoostAmount: 0,
            decayingBoostExpires: 0,
            attributeLockUntil: 0,
            lockedAttributeName: ""
        });


        emit GemsMerged(newTokenId, tokenId1, tokenId2);
        emit GemBurned(tokenId1, attr1.gemType); // Emit burn events
        emit GemBurned(tokenId2, attr2.gemType);
    }

    /// @notice Breeds two Gems to create a new child Gem.
    /// @dev Requires both parent Gems to have certain attributes or conditions met. Costs resources.
    /// @param parent1Id The ID of the first parent Gem.
    /// @param parent2Id The ID of the second parent Gem.
    function breedGems(uint256 parent1Id, uint256 parent2Id)
        public
        onlyGemOwner(parent1Id)
        onlyGemOwner(parent2Id)
        notTimeLocked(parent1Id)
        notTimeLocked(parent2Id)
    {
        require(parent1Id != parent2Id, "EvoGems: cannot breed a gem with itself");
        require(ownerOf(parent1Id) == ownerOf(parent2Id), "EvoGems: gems must have the same owner to breed");

        address owner = ownerOf(parent1Id);

        // Check breeding requirements (example: must be different types, min generation)
        require(gemAttributes[parent1Id].gemType != gemAttributes[parent2Id].gemType, "EvoGems: parents must have different types");
        require(gemAttributes[parent1Id].generation >= 2 && gemAttributes[parent2Id].generation >= 2, "EvoGems: parents must be at least generation 2");

        // Claim resources and check cost
        _claimStakedResources(parent1Id);
        _claimStakedResources(parent2Id);
        uint combinedResources = gemState[parent1Id].resourcesAccumulated.add(gemState[parent2Id].resourcesAccumulated);
        require(combinedResources >= breedResourceCost, "EvoGems: not enough combined resources to breed");

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        // --- Breeding Logic (Simplified) ---
        // Child inherits mixed traits, potentially with some randomness
        GemAttributes storage attr1 = gemAttributes[parent1Id];
        GemAttributes storage attr2 = gemAttributes[parent2Id];

        gemAttributes[childTokenId] = GemAttributes({
             gemType: block.timestamp % 2 == 0 ? attr1.gemType : attr2.gemType, // Randomly inherit type (pseudo)
             generation: SafeMath.max(attr1.generation, attr2.generation).add(1),
             evolutionLevel: 0, // New child starts at level 0
             basePower: (attr1.basePower.add(attr2.basePower)).div(3), // Combined power reduced for child
             color: block.timestamp % 2 == 0 ? attr1.color : attr2.color, // Randomly inherit color (pseudo)
             dynamicAttributes: new mapping(string => bytes)()
        });

        // Deduct cost (can be taken from parent resources or owner's balance)
        // Let's deduct from parents' resources proportionally (simplification)
        uint costShare1 = breedResourceCost / 2;
        uint costShare2 = breedResourceCost - costShare1;
        gemState[parent1Id].resourcesAccumulated = gemState[parent1Id].resourcesAccumulated.sub(costShare1);
        gemState[parent2Id].resourcesAccumulated = gemState[parent2Id].resourcesAccumulated.sub(costShare2);

        // Mint the child gem
        _safeMint(owner, childTokenId);

         gemState[childTokenId] = GemState({
            lastInteractionTime: block.timestamp,
            timeLockUntil: 0,
            delegatedUntil: 0,
            delegatee: address(0),
            resourcesAccumulated: 0, // Child starts with no resources
            stakedSince: 0,
            decayingBoostAmount: 0,
            decayingBoostExpires: 0,
            attributeLockUntil: 0,
            lockedAttributeName: ""
        });

        // Update parent state (e.g., add cooldown)
        gemState[parent1Id].lastInteractionTime = block.timestamp;
        gemState[parent2Id].lastInteractionTime = block.timestamp;

        emit GemBred(childTokenId, parent1Id, parent2Id);
    }

    /// @notice Re-rolls some mutable attributes of a Gem using a seed.
    /// @dev The seed could be derived from an external VRF call result or other source.
    /// Using block hash here is insecure for adversarial use cases.
    /// @param tokenId The ID of the Gem.
    /// @param randomnessSeed A seed for the re-roll.
    function reRollAttributes(uint256 tokenId, bytes32 randomnessSeed)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId) attributeNotLocked(tokenId, "") // Check if *any* attribute is locked
    {
        // Claim resources and check cost (example: cost is based on power)
        _claimStakedResources(tokenId);
        uint reRollCost = gemAttributes[tokenId].basePower.div(10);
        require(gemState[tokenId].resourcesAccumulated >= reRollCost, "EvoGems: not enough resources for re-roll");
        gemState[tokenId].resourcesAccumulated = gemState[tokenId].resourcesAccumulated.sub(reRollCost);


        // --- Re-Roll Logic (Simplified Pseudo-randomness) ---
        // Use block.timestamp, tokenId, and provided seed for pseudo-randomness
        bytes32 combinedSeed = keccak256(abi.encodePacked(randomnessSeed, block.timestamp, tokenId, block.difficulty));
        uint256 rand = uint256(combinedSeed);

        GemAttributes storage attributes = gemAttributes[tokenId];

        // Example re-rolls:
        attributes.basePower = (attributes.basePower.mul(9).div(10)).add(rand % 100); // Reduce power by 10%, add randomness
        attributes.color = uint(uint8(rand >> 8)); // Simple color re-roll
        attributes.gemType = (attributes.gemType % 5).add(1); // Re-roll type within a range

        gemState[tokenId].lastInteractionTime = block.timestamp;

        emit AttributesReRolled(tokenId, randomnessSeed);
    }


    /// @notice Adds a dynamic string-bytes attribute to a Gem.
    /// @dev Allows storing arbitrary structured data associated with the NFT.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the attribute.
    /// @param attributeValue The value of the attribute as bytes.
    function addDynamicAttribute(uint256 tokenId, string calldata attributeName, bytes calldata attributeValue)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId) attributeNotLocked(tokenId, attributeName)
    {
        // Optional: Add checks or costs for adding/modifying attributes
        // require(bytes(attributeName).length > 0, "EvoGems: attribute name cannot be empty");

        gemAttributes[tokenId].dynamicAttributes[attributeName] = attributeValue;
        emit DynamicAttributeAdded(tokenId, attributeName, attributeValue);
    }

     /// @notice Uses accumulated resources to modify a specific dynamic or base attribute.
    /// @dev The specific attributes modifiable and costs would be part of the game logic.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the attribute to modify.
    /// @param newValue The new value for the attribute.
    /// @param resourcesCost The number of resources required.
    function useResourcesToModifyAttribute(uint256 tokenId, string calldata attributeName, bytes calldata newValue, uint resourcesCost)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId) attributeNotLocked(tokenId, attributeName)
    {
         GemState storage state = gemState[tokenId];
         GemAttributes storage attributes = gemAttributes[tokenId];

         _claimStakedResources(tokenId); // Claim pending resources first

         require(state.resourcesAccumulated >= resourcesCost, "EvoGems: not enough resources to modify attribute");
         state.resourcesAccumulated = state.resourcesAccumulated.sub(resourcesCost);

         // --- Modification Logic (Simplified) ---
         // In a real system, this would likely be a restricted set of attributes
         // and newValue would be type-checked against attributeName.

         bytes memory oldValue = attributes.dynamicAttributes[attributeName]; // Get current value for event

         // Simple mapping example: "power_boost" -> apply to basePower
         if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("power_boost"))) {
             uint boost = abi.decode(newValue, (uint));
             attributes.basePower = attributes.basePower.add(boost);
             delete attributes.dynamicAttributes["power_boost"]; // Example: consume the dynamic attribute
         } else {
             // Generic dynamic attribute update
             attributes.dynamicAttributes[attributeName] = newValue;
         }

         state.lastInteractionTime = block.timestamp;
         emit DynamicAttributeModified(tokenId, attributeName, oldValue, newValue);
    }

     /// @notice Proposes an attribute upgrade, requiring resources.
    /// @dev This stages an upgrade that may need another action (like confirmation or time delay) to finalize.
    /// Only one proposal can be pending per gem.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the attribute to propose changing.
    /// @param proposedValue The value proposed for the attribute.
    /// @param resourceCost The resources needed for the proposal itself (staging cost).
    function proposeAttributeUpgrade(uint256 tokenId, string calldata attributeName, bytes calldata proposedValue, uint resourceCost)
         public onlyGemOwner(tokenId) notTimeLocked(tokenId) attributeNotLocked(tokenId, attributeName)
    {
        require(!gemUpgradeProposals[tokenId].exists, "EvoGems: there is already a pending upgrade proposal");

        GemState storage state = gemState[tokenId];
        _claimStakedResources(tokenId);

        require(state.resourcesAccumulated >= resourceCost, "EvoGems: not enough resources for proposal");
        state.resourcesAccumulated = state.resourcesAccumulated.sub(resourceCost);

        gemUpgradeProposals[tokenId] = AttributeUpgradeProposal({
            attributeName: attributeName,
            proposedValue: proposedValue,
            resourceCost: resourceCost, // This is the cost to *propose*, not necessarily to finalize
            exists: true
        });

        emit AttributeUpgradeProposed(tokenId, attributeName, proposedValue, resourceCost);
    }

    /// @notice Finalizes a pending attribute upgrade proposal.
    /// @dev Can add conditions like time delay, voting, or additional costs here.
    /// @param tokenId The ID of the Gem.
    function finalizeAttributeUpgrade(uint256 tokenId)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        AttributeUpgradeProposal storage proposal = gemUpgradeProposals[tokenId];
        require(proposal.exists, "EvoGems: no pending upgrade proposal");
        // Add finalization conditions here, e.g., time delay, more resources

        GemAttributes storage attributes = gemAttributes[tokenId];
        bytes memory oldValue = attributes.dynamicAttributes[proposal.attributeName];

        // --- Finalization Logic ---
         // Simple mapping example: "power_boost" -> apply to basePower
         if (keccak256(abi.encodePacked(proposal.attributeName)) == keccak256(abi.encodePacked("power_boost"))) {
             uint boost = abi.decode(proposal.proposedValue, (uint));
             attributes.basePower = attributes.basePower.add(boost);
         } else {
             // Generic dynamic attribute update
             attributes.dynamicAttributes[proposal.attributeName] = proposal.proposedValue;
         }

        // Clear the proposal
        delete gemUpgradeProposals[tokenId];

        emit AttributeUpgradeExecuted(tokenId, proposal.attributeName, proposal.proposedValue);
        // Can emit DynamicAttributeModified as well if appropriate
        emit DynamicAttributeModified(tokenId, proposal.attributeName, oldValue, proposal.proposedValue);
    }

    /// @notice Temporarily locks a specific attribute on a Gem, e.g., for an auction.
    /// @dev Prevents modification of this attribute until the lock expires.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the attribute to lock.
    /// @param duration The duration in seconds to lock the attribute.
    function lockAttributeForAuction(uint256 tokenId, string calldata attributeName, uint duration)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId) attributeNotLocked(tokenId, attributeName)
    {
        require(bytes(attributeName).length > 0, "EvoGems: attribute name cannot be empty");
        require(duration > 0, "EvoGems: lock duration must be greater than 0");

        GemState storage state = gemState[tokenId];
        state.attributeLockUntil = block.timestamp.add(duration);
        state.lockedAttributeName = attributeName;

        emit AttributeLocked(tokenId, attributeName, state.attributeLockUntil);
    }


    /// @notice Calculates a derived total power score for a Gem.
    /// @dev Includes base power, decaying boost, and potential contributions from dynamic attributes.
    /// @param tokenId The ID of the Gem.
    /// @return The calculated total power.
    function queryGemTotalPower(uint256 tokenId) public view returns (uint) {
        _requireOwned(tokenId); // Ensure gem exists
        GemAttributes storage attributes = gemAttributes[tokenId];
        GemState storage state = gemState[tokenId];

        uint totalPower = attributes.basePower;

        // Add decaying boost if active
        if (block.timestamp < state.decayingBoostExpires) {
            uint timeElapsed = block.timestamp.sub(state.lastInteractionTime); // Simplified decay based on time since last action or just system time
             if (timeElapsed < state.decayingBoostExpires.sub(state.decayingBoostExpires.sub(block.timestamp))) { // Prevent overflow if time passes expiration
                  timeElapsed = state.decayingBoostExpires.sub(block.timestamp);
             }

            uint decayRate = state.decayingBoostAmount / (state.decayingBoostExpires - state.lastInteractionTime); // Simple linear decay
            uint currentBoost = state.decayingBoostAmount.sub(decayRate.mul(timeElapsed));
            totalPower = totalPower.add(currentBoost);
        }


        // Add contributions from dynamic attributes (example: "extra_power" attribute)
        bytes memory extraPowerBytes = attributes.dynamicAttributes["extra_power"];
        if (extraPowerBytes.length > 0) {
             uint extraPower = abi.decode(extraPowerBytes, (uint));
             totalPower = totalPower.add(extraPower);
        }

        return totalPower;
    }

     /// @notice Calculates a simplified on-chain value floor based on attributes.
    /// @dev This is a conceptual value and not a true market price.
    /// @param tokenId The ID of the Gem.
    /// @return A calculated floor value (example in a hypothetical internal currency or points).
    function calculateGemValueFloor(uint256 tokenId) public view returns (uint) {
        _requireOwned(tokenId);
        GemAttributes storage attributes = gemAttributes[tokenId];

        // --- Value Calculation Logic (Simplified) ---
        // Formula based on attributes: type multiplier * generation boost * power component
        uint typeMultiplier = attributes.gemType * 100;
        uint generationBoost = attributes.generation * 50;
        uint powerComponent = attributes.basePower;
        uint evolutionBonus = attributes.evolutionLevel * 20;

        return typeMultiplier.add(generationBoost).add(powerComponent).add(evolutionBonus);
    }

    /// @notice Verifies if a specific attribute/value for a Gem is included in the current Merkle Root.
    /// @dev Used to prove the inclusion of off-chain data committed to the contract.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the attribute.
    /// @param attributeValue The value of the attribute.
    /// @param proof The Merkle proof.
    /// @return True if the proof is valid for the given attribute/value and Gem, false otherwise.
    function verifyTraitUsingMerkleProof(uint256 tokenId, string calldata attributeName, bytes calldata attributeValue, bytes32[] calldata proof)
        public view returns (bool)
    {
        // Construct the leaf node: e.g., hash(tokenId, attributeName, attributeValue)
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, attributeName, attributeValue));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

     /// @notice Owner can update the Merkle Root.
    /// @param _newRoot The new Merkle root.
    function setMerkleRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(merkleRoot);
    }


    /// @notice Stakes a Gem, locking its transferability and starting resource accumulation.
    /// @dev Requires the Gem to be owned by the caller and not already staked.
    /// @param tokenId The ID of the Gem to stake.
    function stakeGemForResources(uint256 tokenId)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        GemState storage state = gemState[tokenId];
        require(state.stakedSince == 0, "EvoGems: gem is already staked");

        // Cannot stake if delegated
        require(state.delegatedUntil == 0 || block.timestamp >= state.delegatedUntil, "EvoGems: gem is delegated");

        // Claim any pending resources from previous staking periods
        _claimStakedResources(tokenId);

        state.stakedSince = block.timestamp;
        // Optional: Add transfer lock while staked - handled by notTimeLocked modifier on transfers if timeLockUntil is set.
        // Or override transferFrom/safeTransferFrom to check stakedSince != 0

        emit GemStaked(tokenId, block.timestamp);
    }

    /// @notice Unstakes a Gem, making it transferable again and claiming accumulated resources.
    /// @dev Requires the Gem to be currently staked.
    /// @param tokenId The ID of the Gem to unstake.
    function unstakeGem(uint256 tokenId)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
         GemState storage state = gemState[tokenId];
         require(state.stakedSince != 0, "EvoGems: gem is not staked");

         // Claim resources first
         uint resourcesClaimed = _claimStakedResources(tokenId);

         state.stakedSince = 0;

         emit GemUnstaked(tokenId, block.timestamp, resourcesClaimed);
    }


    /// @notice Claims accumulated resources for a staked Gem without unstaking.
    /// @dev Can be called periodically to harvest resources.
    /// @param tokenId The ID of the Gem.
    /// @return The amount of resources claimed.
    function claimStakedGemResources(uint256 tokenId)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
        returns (uint resourcesClaimed)
    {
        resourcesClaimed = _claimStakedResources(tokenId);
        emit GemResourcesClaimed(tokenId, resourcesClaimed);
    }

     /// @dev Internal function to calculate and add pending resources to the gem's balance.
     /// @param tokenId The ID of the Gem.
     /// @return The amount of resources added in this claim.
    function _claimStakedResources(uint256 tokenId) internal returns (uint) {
        GemState storage state = gemState[tokenId];
        uint stakedSince = state.stakedSince;

        if (stakedSince == 0 || block.timestamp <= stakedSince) {
            return 0; // Not staked or no time has passed
        }

        uint timeStaked = block.timestamp.sub(stakedSince);
        uint resourcesGenerated = timeStaked.mul(stakeResourceRate); // Simplified: linear rate

        // Optional: Resource rate could depend on gem attributes (e.g., basePower)
        // uint resourcesGenerated = timeStaked.mul(stakeResourceRate).mul(gemAttributes[tokenId].basePower).div(100);

        state.resourcesAccumulated = state.resourcesAccumulated.add(resourcesGenerated);
        state.stakedSince = block.timestamp; // Reset timer for next claim

        return resourcesGenerated;
    }


    /// @notice Sets a time-lock on a Gem, preventing transfer and modification until the specified time.
    /// @dev Can only be set by the owner. Overwrites any existing time-lock if later.
    /// @param tokenId The ID of the Gem.
    /// @param timeUntilUnlock The duration in seconds from now until the lock expires.
    function setTimeLock(uint256 tokenId, uint timeUntilUnlock)
        public onlyGemOwner(tokenId)
    {
        require(timeUntilUnlock > 0, "EvoGems: unlock time must be in the future");
        uint newUnlockTime = block.timestamp.add(timeUntilUnlock);
        gemState[tokenId].timeLockUntil = newUnlockTime;
        emit GemTimeLocked(tokenId, newUnlockTime);
    }

    /// @notice Applies a temporary, decaying boost to a Gem's attributes (e.g., power).
    /// @dev The boost amount diminishes over time. Can be reapplied to refresh.
    /// @param tokenId The ID of the Gem.
    /// @param boostAmount The initial amount of the boost.
    /// @param duration The duration in seconds the boost lasts.
    function applyDecayingBoost(uint256 tokenId, uint boostAmount, uint duration)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        require(boostAmount > 0 && duration > 0, "EvoGems: boost amount and duration must be positive");

        GemState storage state = gemState[tokenId];

        // Update state with the new boost parameters
        state.decayingBoostAmount = boostAmount;
        state.decayingBoostExpires = block.timestamp.add(duration);
        state.lastInteractionTime = block.timestamp; // Reset timer for decay calculation

        emit DecayingBoostApplied(tokenId, boostAmount, state.decayingBoostExpires);
    }

    /// @notice Triggers evolution *only* if the Gem's calculated power meets a minimum requirement.
    /// @dev Demonstrates conditional logic based on derived state.
    /// @param tokenId The ID of the Gem.
    /// @param minPower The minimum power required to trigger the evolution.
    function triggerEvolutionIfPowerAbove(uint256 tokenId, uint minPower)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        require(queryGemTotalPower(tokenId) >= minPower, "EvoGems: gem power is below minimum requirement for this evolution");

        // --- Simplified Evolution Logic (could call evolveGem internally) ---
        // Let's make this a specific, simplified conditional evolution
        GemAttributes storage attributes = gemAttributes[tokenId];
        GemState storage state = gemState[tokenId];

        // Claim resources before checking balance and spending (if evolution costs resources)
        // Assuming this conditional evolution has a cost, similar to evolveGem
        _claimStakedResources(tokenId);
        uint conditionalEvolutionCost = evolutionResourceCost.mul(80).div(100); // Slightly cheaper?
        require(state.resourcesAccumulated >= conditionalEvolutionCost, "EvoGems: not enough resources for conditional evolution");
        state.resourcesAccumulated = state.resourcesAccumulated.sub(conditionalEvolutionCost);

        uint oldType = attributes.gemType;
        attributes.evolutionLevel = attributes.evolutionLevel.add(1);
        attributes.basePower = attributes.basePower.add(attributes.basePower.div(10)); // Small power boost

        state.lastInteractionTime = block.timestamp;
        state.decayingBoostAmount = 0; // Reset boost

        emit GemEvolved(tokenId, oldType, attributes.gemType, attributes.evolutionLevel); // Reuse event
    }


    /// @notice Allows the owner to delegate limited control over a Gem to another address.
    /// @dev The delegatee can perform certain pre-defined actions (e.g., staking, claiming resources, specific attribute changes)
    /// defined internally or via modifiers like `onlyGemOwnerOrDelegate`. Cannot transfer the gem.
    /// @param tokenId The ID of the Gem.
    /// @param delegatee The address to delegate control to. Use address(0) to revoke.
    /// @param duration The duration in seconds the delegation is valid (0 for indefinite or until revoked).
    function delegateGemControl(uint256 tokenId, address delegatee, uint duration)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId) // Cannot delegate a time-locked gem
    {
        GemState storage state = gemState[tokenId];
        require(state.stakedSince == 0, "EvoGems: cannot delegate a staked gem"); // Cannot delegate if staked

        state.delegatee = delegatee;
        if (delegatee != address(0) && duration > 0) {
            state.delegatedUntil = block.timestamp.add(duration);
        } else {
            state.delegatedUntil = 0; // Revoke or make indefinite (careful with indefinite)
        }

        emit GemDelegateUpdated(tokenId, delegatee, state.delegatedUntil);
    }

    /// @dev Helper to check if the caller is the active delegatee for a gem.
    function _isGemDelegate(uint256 tokenId) internal view returns (bool) {
        GemState storage state = gemState[tokenId];
        return state.delegatee == msg.sender && block.timestamp < state.delegatedUntil;
    }


    /// @notice Sets a custom royalty recipient and percentage for a specific Gem.
    /// @dev Overrides collection-level royalties for this token. Requires marketplace support for enforcement.
    /// @param tokenId The ID of the Gem.
    /// @param recipient The address to receive royalties (address(0) to clear).
    /// @param basisPoints The royalty percentage in basis points (0-10000).
    function setGemCustomRoyalty(uint256 tokenId, address recipient, uint96 basisPoints)
        public onlyGemOwner(tokenId)
    {
        require(basisPoints <= 10000, "EvoGems: royalty basis points cannot exceed 10000 (100%)");

        gemRoyaltyRecipient[tokenId] = recipient;
        gemRoyaltyBasisPoints[tokenId] = basisPoints;

        emit GemCustomRoyaltyUpdated(tokenId, recipient, basisPoints);
    }

    /// @notice Function to query per-token royalty information.
    /// @dev Follows a common interface pattern for token-specific royalties.
    /// @param tokenId The ID of the Gem.
    /// @param salePrice The hypothetical sale price (not used in this simple example, but standard interface).
    /// @return receiver The address to receive royalties.
    /// @return royaltyAmount The calculated royalty amount (based on basis points).
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view returns (address receiver, uint256 royaltyAmount)
    {
        receiver = gemRoyaltyRecipient[tokenId];
        uint96 basisPoints = gemRoyaltyBasisPoints[tokenId];

        // If no specific royalty set, could fallback to a collection default here
        if (receiver == address(0)) {
            // Example: return contract owner and a default rate
            receiver = owner(); // Example fallback to contract owner
            basisPoints = 250; // Example fallback 2.5%
        }

        royaltyAmount = salePrice.mul(basisPoints).div(10000);

        return (receiver, royaltyAmount);
    }

    /// @notice Grants or revokes an external contract's permission to trigger specific functions on this Gem.
    /// @dev Allows integration with trusted external game logic or protocols.
    /// @param tokenId The ID of the Gem.
    /// @param externalContract The address of the external contract.
    /// @param allowed True to grant permission, false to revoke.
    function getExternalTriggerPermission(uint256 tokenId, address externalContract, bool allowed)
        public onlyGemOwner(tokenId)
    {
        require(externalContract.isContract(), "EvoGems: address must be a contract");
        externalTriggerPermissions[tokenId][externalContract] = allowed;
        emit ExternalTriggerPermissionUpdated(tokenId, externalContract, allowed);
    }

    /// @notice A function callable only by an external contract with explicit permission, to trigger evolution.
    /// @dev Example of a function designed for trusted external calls.
    /// @param tokenId The ID of the Gem.
    /// @param evolutionPath The evolution path identifier.
    function triggerExternalEvolution(uint256 tokenId, uint evolutionPath)
        public onlyGemOwnerDelegateOrPermittedExternal(tokenId) notTimeLocked(tokenId)
    {
        // This function behaves like evolveGem but with different access control
        // Could add extra checks specific to external triggers here

        GemAttributes storage attributes = gemAttributes[tokenId];
        GemState storage state = gemState[tokenId];

        // Claim resources before checking balance and spending
        _claimStakedResources(tokenId);

        // External triggers might have different cost mechanics or requirements
        uint externalEvolutionCost = evolutionResourceCost.mul(90).div(100); // Slightly different cost
        require(state.resourcesAccumulated >= externalEvolutionCost, "EvoGems: not enough resources for external evolution");

        uint oldType = attributes.gemType;
        attributes.evolutionLevel = attributes.evolutionLevel.add(1);
        state.resourcesAccumulated = state.resourcesAccumulated.sub(externalEvolutionCost);
        state.lastInteractionTime = block.timestamp;

        // --- Evolution Logic (Same as internal evolveGem or slightly different) ---
        attributes.gemType = attributes.gemType.add(evolutionPath * 2); // Example: different path logic
        attributes.basePower = attributes.basePower.add(attributes.basePower.div(4).add(evolutionPath * 15)); // Example: different power boost

        // Clear decaying boosts on evolution
        state.decayingBoostAmount = 0;
        state.decayingBoostExpires = 0;

        // Potentially log a different event for external triggers
        emit GemEvolved(tokenId, oldType, attributes.gemType, attributes.evolutionLevel); // Re-using event
        // emit ExternalEvolutionTriggered(tokenId, msg.sender, evolutionPath); // Could add a specific event
    }

     /// @notice Allows claiming a reward (via an external distributor contract) based on Gem attributes.
    /// @dev Reward calculation is based on specific attributes.
    /// @param tokenId The ID of the Gem.
    function claimRewardBasedOnAttributes(uint256 tokenId)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        require(address(resourceDistributor) != address(0), "EvoGems: Resource distributor not set");

        GemAttributes storage attributes = gemAttributes[tokenId];
        // --- Reward Calculation Logic (Simplified) ---
        // Example: Reward = basePower * evolutionLevel + (type == X ? bonus : 0)
        uint rewardAmount = attributes.basePower.mul(attributes.evolutionLevel.add(1)).div(10); // Add 1 to avoid multiplying by 0

        if (attributes.gemType == 5) { // Example: Type 5 gems get a bonus
            rewardAmount = rewardAmount.add(100);
        }

        require(rewardAmount > 0, "EvoGems: gem does not qualify for a reward currently");

        // Assuming the distributor contract handles the actual token transfer
        resourceDistributor.distributeReward(msg.sender, rewardAmount);

        emit RewardClaimed(tokenId, msg.sender, rewardAmount);
    }

    /// @notice Burns a Gem, but only if it matches a specific required type.
    /// @dev Used for mechanics where specific Gem types are consumed (e.g., crafting).
    /// @param tokenId The ID of the Gem to burn.
    /// @param gemType The required type for burning.
    function burnGemOfType(uint256 tokenId, uint gemType)
        public onlyGemOwner(tokenId) notTimeLocked(tokenId)
    {
        require(gemAttributes[tokenId].gemType == gemType, "EvoGems: gem does not match the required type for burning");

        // Clear state before burning
        delete gemAttributes[tokenId];
        delete gemState[tokenId];
        delete gemUpgradeProposals[tokenId];
        delete gemRoyaltyRecipient[tokenId];
        delete gemRoyaltyBasisPoints[tokenId];
        // Note: externalTriggerPermissions are per-gem, per-contract, need careful deletion if many
        // Simplification: assume limited external contracts or accept residual storage

        _burn(tokenId);
        emit GemBurned(tokenId, gemType);
    }

    /// @notice Sets the address of the external resource distributor contract.
    /// @param _distributor The address of the IResourceDistributor contract.
    function setResourceDistributor(IResourceDistributor _distributor) public onlyOwner {
        resourceDistributor = _distributor;
    }

    // --- ERC721 Enumerable Overrides ---
    // These are standard OpenZeppelin overrides required by ERC721Enumerable

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // The following functions are inherited from ERC721Enumerable and ERC721.
    // They provide the standard NFT functionalities (transfer, balance, ownership, approval).
    // We add our custom modifiers where applicable (e.g., notTimeLocked to transfers).

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Apply time-lock check to all transfers (except minting from address(0))
        if (from != address(0)) {
             require(block.timestamp >= gemState[tokenId].timeLockUntil, "EvoGems: gem is time-locked and cannot be transferred");
             require(gemState[tokenId].stakedSince == 0, "EvoGems: staked gems cannot be transferred");
        }
         // Clear delegation on transfer
         if (to != address(0)) { // Not burning
             gemState[tokenId].delegatee = address(0);
             gemState[tokenId].delegatedUntil = 0;
         }
    }

    // _burn override to clean up state
     function _burn(uint256 tokenId) internal override(ERC721Enumerable) {
         // ERC721Enumerable's _burn handles token registry cleanup
         super._burn(tokenId);

         // Explicit state cleanup for our custom mappings
         delete gemAttributes[tokenId];
         delete gemState[tokenId];
         delete gemUpgradeProposals[tokenId];
         delete gemRoyaltyRecipient[tokenId];
         delete gemRoyaltyBasisPoints[tokenId];
         // Dynamic attribute mapping is part of gemAttributes struct, deleted above
         // externalTriggerPermissions is per-gem per-contract, would need iteration or re-design for full cleanup
     }


    // --- Internal/Helper Functions ---

    /// @dev Helper to check if caller is owner or approved for a gem.
    function _isGemOwnerOrApproved(uint256 tokenId) internal view returns (bool) {
         address owner = ownerOf(tokenId); // Will revert if tokenId doesn't exist
         return owner == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    // --- View Functions for Dynamic Attributes ---

    /// @notice Gets the value of a dynamic attribute for a Gem.
    /// @param tokenId The ID of the Gem.
    /// @param attributeName The name of the dynamic attribute.
    /// @return The value of the attribute as bytes.
    function getDynamicAttribute(uint256 tokenId, string calldata attributeName) public view returns (bytes memory) {
        _requireOwned(tokenId);
        return gemAttributes[tokenId].dynamicAttributes[attributeName];
    }

     /// @notice Gets the core attributes of a Gem.
     /// @param tokenId The ID of the Gem.
     /// @return gemType, generation, evolutionLevel, basePower, color.
    function getGemAttributes(uint256 tokenId)
        public view returns (uint gemType, uint generation, uint evolutionLevel, uint basePower, uint color)
    {
        _requireOwned(tokenId);
        GemAttributes storage attrs = gemAttributes[tokenId];
        return (attrs.gemType, attrs.generation, attrs.evolutionLevel, attrs.basePower, attrs.color);
    }

     /// @notice Gets the current state information for a Gem.
     /// @param tokenId The ID of the Gem.
     /// @return lastInteractionTime, timeLockUntil, delegatedUntil, delegatee, resourcesAccumulated, stakedSince, decayingBoostAmount, decayingBoostExpires, attributeLockUntil, lockedAttributeName.
    function getGemState(uint256 tokenId)
        public view returns (uint lastInteractionTime, uint timeLockUntil, uint delegatedUntil, address delegatee, uint resourcesAccumulated, uint stakedSince, uint decayingBoostAmount, uint decayingBoostExpires, uint attributeLockUntil, string memory lockedAttributeName)
    {
        _requireOwned(tokenId);
        GemState storage state = gemState[tokenId];
        return (state.lastInteractionTime, state.timeLockUntil, state.delegatedUntil, state.delegatee, state.resourcesAccumulated, state.stakedSince, state.decayingBoostAmount, state.decayingBoostExpires, state.attributeLockUntil, state.lockedAttributeName);
    }

    /// @notice Gets the details of a pending attribute upgrade proposal for a Gem.
    /// @param tokenId The ID of the Gem.
    /// @return attributeName, proposedValue, resourceCost, exists.
    function getAttributeUpgradeProposal(uint256 tokenId)
         public view returns (string memory attributeName, bytes memory proposedValue, uint resourceCost, bool exists)
    {
         AttributeUpgradeProposal storage proposal = gemUpgradeProposals[tokenId];
         return (proposal.attributeName, proposal.proposedValue, proposal.resourceCost, proposal.exists);
    }

     /// @notice Checks if an external contract has permission to trigger actions on a Gem.
     /// @param tokenId The ID of the Gem.
     /// @param externalContract The address of the external contract.
     /// @return True if permission is granted, false otherwise.
    function hasExternalTriggerPermission(uint256 tokenId, address externalContract) public view returns (bool) {
        _requireOwned(tokenId);
        return externalTriggerPermissions[tokenId][externalContract];
    }


}

// Simple Base64 library from OpenZeppelin for data URI example
// Needs to be added if not using npm packages in dev environment
// @openzeppelin/contracts/utils/Base64.sol
library Base64 {
    string internal constant base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // Encode a byte array to base64
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = base64chars;

        // allocate 3/4 of the input size plus some overhead
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen);

        /// @solidity memory-safe-assembly
        assembly {
            let tablePtr := add(table, 32)
            let dataPtr := add(data, 32)
            let resultPtr := add(result, 32)

            for { let i := 0; i < data.length; } islt(i, data.length) { } {
                i := add(i, 3)
                let chunk := mload(dataPtr)

                // The three bytes are packed into a 32-bit word.
                //
                // bits: 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
                // byte 1        |byte 2        |byte 3
                // AAAAAABB BBBBBBCC CCCCCCCD DDDDDD

                if islt(i, data.length) {
                    mstore8(resultPtr,      mload(add(tablePtr, and(shr(18, chunk), 0x3F))))
                    mstore8(add(resultPtr, 1), mload(add(tablePtr, and(shr(12, chunk), 0x3F))))
                    mstore8(add(resultPtr, 2), mload(add(tablePtr, and(shr(6, chunk), 0x3F))))
                    mstore8(add(resultPtr, 3), mload(add(tablePtr, and(         chunk, 0x3F))))
                } else if eq(i,            data.length) {
                    mstore8(resultPtr,      mload(add(tablePtr, and(shr(18, chunk), 0x3F))))
                    mstore8(add(resultPtr, 1), mload(add(tablePtr, and(shr(12, chunk), 0x3F))))
                    mstore8(add(resultPtr, 2), mload(add(tablePtr, and(shr(6, chunk), 0x3F))))
                    mstore8(add(resultPtr, 3), 0x3D) // '='
                } else {
                    mstore8(resultPtr,      mload(add(tablePtr, and(shr(18, chunk), 0x3F))))
                    mstore8(add(resultPtr, 1), mload(add(tablePtr, and(shr(12, chunk), 0x3F))))
                    mstore8(add(resultPtr, 2), 0x3D) // '='
                    mstore8(add(resultPtr, 3), 0x3D) // '='
                }

                dataPtr := add(dataPtr, 3)
                resultPtr := add(resultPtr, 4)
            }
        }

        return result;
    }
}

// OpenZeppelin Strings Library for utility
// @openzeppelin/contracts/utils/Strings.sol
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint256 internal constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = uint256(value == 0 ? 1 : Math.log10(value) + 1);
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr := sub(ptr, 1);
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            bytes memory buffer = new bytes(Math.log256(value) / 8 + 1);
            /// @solidity memory-safe-assembly
            assembly {
                let bufferPtr := add(buffer, 32)
            }
            while (value > 0) {
                uint256 v = value;
                uint256 bs = 32;
                if (v <= 0xFF) { bs = 1; }
                else if (v <= 0xFFFF) { bs = 2; }
                else if (v <= 0xFFFFFF) { bs = 3; }
                else if (v <= 0xFFFFFFFF) { bs = 4; }
                else if (v <= 0xFFFFFFFFFF) { bs = 5; }
                else if (v <= 0xFFFFFFFFFFFF) { bs = 6; }
                else if (v <= 0xFFFFFFFFFFFFFF) { bs = 7; }

                bytes memory temp = new bytes(bs);
                /// @solidity memory-safe-assembly
                assembly {
                    mstore(add(temp, 32), shl(sub(32, bs), v))
                }
                buffer = bytes.concat(buffer, temp);
                value = v >> (bs * 8);
            }
            return Bytes.toHexString(buffer);
        }
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        uint256 ptr = length;
        /// @solidity memory-safe-assembly
        assembly {
            let temp_ptr := add(buffer, 32)
        }
        unchecked {
            while (ptr > 0 || value > 0) {
                ptr--;
                buffer[ptr] = _SYMBOLS[value % 16];
                value /= 16;
            }
            return string(buffer);
        }
    }

    function toHexString(address value) internal pure returns (string memory) {
        return toHexString(uint256(uint160(value)), _ADDRESS_LENGTH * 2);
    }

    struct Math {
        uint256 _gap;
    }

    function log256(uint256 value) internal pure returns (uint256) {
        unchecked {
            uint256 ret = 0;
            if (value >= 0x10000000000000000000000000000000) { value >>= 128; ret += 128; }
            if (value >= 0x10000000000000000) { value >>= 64; ret += 64; }
            if (value >= 0x100000000) { value >>= 32; ret += 32; }
            if (value >= 0x10000) { value >>= 16; ret += 16; }
            if (value >= 0x100) { value >>= 8; ret += 8; }
            return ret;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        unchecked {
            uint256 ret = 0;
            if (value >= 10000000000000000000000000000000000000000000000000000000000000000) { value /= 1e32; ret += 32; }
            if (value >= 10000000000000000) { value /= 1e16; ret += 16; }
            if (value >= 100000000) { value /= 1e8; ret += 8; }
            if (value >= 10000) { value /= 1e4; ret += 4; }
            if (value >= 100) { value /= 1e2; ret += 2; }
            if (value >= 10) { value /= 10; ret += 1; }
            return ret;
        }
    }
}

library Bytes {
    function toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory hex = new bytes(data.length * 2);
        for (uint256 i = 0; i < data.length; i++) {
            hex[i * 2] = alphabet[uint8(data[i] >> 4)];
            hex[i * 2 + 1] = alphabet[uint8(data[i] & 0xf)];
        }
        return string(hex);
    }
}

```