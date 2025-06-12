Okay, let's design a smart contract around the concept of managing dynamic, evolving digital entities ("Artefacts") that interact with a shared, regenerating resource ("Essence"). This combines resource management, dynamic NFTs, and potentially game-like mechanics.

It will incorporate concepts like time-based resource regeneration, state-dependent actions, internal calculations for property evolution, and standard NFT ownership patterns.

We'll aim for at least 20 functions, including core logic, state queries, and standard interface methods (like ERC721 for ownership).

---

**Outline & Function Summary**

**Contract Name:** `EssenceForge`

**Purpose:**
A smart contract for minting, managing, and evolving unique digital assets called "Artefacts". These Artefacts have dynamic properties that can be influenced by user actions, specifically through interacting with a shared, time-regenerating resource called "Essence". The contract manages the global Essence pool, user-owned Artefacts, and provides mechanisms for users to "Synthesize" (channel Essence), "Imbue" (use Essence to boost Artefact properties), and "Reforge" (use Essence and potentially other costs for risky property randomization/transformation).

**Key Concepts:**
*   **Essence:** A finite but regenerating resource within the contract. Its total amount increases over time based on a regeneration rate.
*   **Artefact:** A unique, non-fungible digital asset (like an NFT) owned by a user. Each Artefact has a set of numerical `properties`.
*   **Properties:** Attributes of an Artefact (e.g., Power, Resilience, Affinity). These are stored as numbers and can change.
*   **Synthesis:** An action where a user interacts with the contract to draw Essence into their personal balance, potentially at a cost.
*   **Imbuing:** An action where a user spends their personal Essence balance to increase specific properties of one of their Artefacts.
*   **Reforging:** A high-cost, high-risk action where a user spends Essence and potentially other resources (like ETH) to randomly transform some or all properties of an Artefact.
*   **Time-Based Regeneration:** The total Essence in the system increases over time based on `block.timestamp`.

**State Variables:**
*   `owner`: Contract deployer, for administrative functions.
*   `systemEssencePool`: The total amount of Essence available in the contract (regenerates).
*   `lastEssenceRegenTimestamp`: Timestamp of the last time Essence regeneration was calculated/applied.
*   `essenceRegenRatePerSecond`: Rate at which `systemEssencePool` regenerates.
*   `artefactCounter`: Monotonically increasing ID for new Artefacts.
*   `artefacts`: Mapping from Artefact ID to Artefact data (owner, properties, internal essence).
*   `userEssenceBalance`: Mapping from user address to their personal Essence balance (gained via Synthesis).
*   `_ownerArtefacts`: Mapping from owner address to list of Artefact IDs (for ERC721 enumeration helper).
*   Standard ERC721 mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   Constants/Parameters for costs (`synthesisEthCost`, `imbuingEssenceCost`, `reforgeEthCost`, `reforgeEssenceCost`).
*   `baseTokenURI`: Base URI for ERC721 metadata.

**Structs:**
*   `Artefact`: Holds an Artefact's state (`owner`, `essenceStored`, `properties` array).

**Events:**
*   `ArtefactMinted(uint256 artefactId, address owner, uint8[] initialProperties)`
*   `EssenceSynthesized(address user, uint256 amount)`
*   `ArtefactImbued(uint256 artefactId, uint8 propertyIndex, uint8 oldValue, uint8 newValue, uint256 essenceSpent)`
*   `ArtefactReforged(uint256 artefactId, uint8[] oldProperties, uint8[] newProperties, uint256 essenceSpent)`
*   `EssenceRegenerated(uint256 amount, uint256 newPoolBalance)`
*   Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`)

**Functions (>= 20):**

1.  `constructor()`: Initializes contract owner, initial Essence, regeneration rate, costs.
2.  `_updateSystemEssence()`: Internal helper. Calculates and applies Essence regeneration based on time elapsed. Called by state-changing functions.
3.  `getSystemEssencePool()`: Returns the current total system Essence pool (after potential regeneration update).
4.  `getLastEssenceRegenTimestamp()`: Returns the timestamp of the last Essence regeneration update.
5.  `getEssenceRegenRatePerSecond()`: Returns the current Essence regeneration rate.
6.  `getUserEssenceBalance(address user)`: Returns the personal Essence balance for a user.
7.  `getCurrentArtefactSupply()`: Returns the total number of Artefacts minted.
8.  `getArtefactOwner(uint256 artefactId)`: Returns the owner of a specific Artefact (ERC721 `ownerOf`).
9.  `getArtefactProperties(uint256 artefactId)`: Returns the full array of properties for an Artefact.
10. `getArtefactProperty(uint256 artefactId, uint8 propertyIndex)`: Returns a specific property value for an Artefact.
11. `getArtefactEssenceStored(uint256 artefactId)`: Returns the internal Essence stored within an Artefact (if any - decided against internal essence for simplicity in favor of user balance). Let's remove this and stick to user balance.
12. `mintArtefact()`: Allows a user to mint a new Artefact. Costs ETH, consumes some system Essence. Assigns initial properties.
13. `synthesizeEssence()`: Allows a user to synthesize Essence. Costs ETH, transfers Essence from the system pool to the user's personal balance.
14. `imbueArtefact(uint256 artefactId, uint8 propertyIndex, uint256 amountToSpend)`: Allows an Artefact owner to spend personal Essence to increase a specific property of that Artefact.
15. `reforgeArtefact(uint256 artefactId)`: Allows an Artefact owner to spend personal Essence and ETH for a pseudo-random transformation of the Artefact's properties.
16. `getSynthesisCostEth()`: Returns the ETH cost for Synthesis.
17. `getImbuingEssenceCostBase()`: Returns the base Essence cost parameter for Imbuing (actual cost might scale).
18. `getReforgeCostEth()`: Returns the ETH cost for Reforging.
19. `getReforgeCostEssence()`: Returns the Essence cost for Reforging.
20. `withdrawEth(address payable recipient)`: Owner-only function to withdraw collected ETH.
21. `setBaseTokenURI(string memory uri)`: Owner-only function to set the metadata base URI.
22. `tokenURI(uint256 artefactId)`: Returns the metadata URI for an Artefact (ERC721 standard).
23. `balanceOf(address owner)`: Returns the number of Artefacts owned by an address (ERC721 standard).
24. `transferFrom(address from, address to, uint256 artefactId)`: Transfers ownership of an Artefact (ERC721 standard).
25. `safeTransferFrom(address from, address to, uint256 artefactId)`: Safe transfer (ERC721 standard).
26. `safeTransferFrom(address from, address to, uint256 artefactId, bytes memory data)`: Safe transfer with data (ERC721 standard).
27. `approve(address spender, uint256 artefactId)`: Approves an address to transfer an Artefact (ERC721 standard).
28. `getApproved(uint256 artefactId)`: Returns the approved address for an Artefact (ERC721 standard).
29. `setApprovalForAll(address operator, bool approved)`: Sets approval for all Artefacts of an owner (ERC721 standard).
30. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all Artefacts of an owner (ERC721 standard).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721, IERC721Receiver, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// Helper contract for pseudo-randomness (Caution: not cryptographically secure on chain)
contract PseudoRandomHelper {
    // Simple pseudo-random number generator based on block data and seed
    function pseudoRandom(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, seed, msg.sender)));
    }

    // Generate a random-ish byte value (0-255)
    function randomByte(uint256 seed) internal view returns (uint8) {
        return uint8(pseudoRandom(seed) % 256);
    }

    // Generate a random-ish index within bounds
    function randomIndex(uint256 upperBound, uint256 seed) internal view returns (uint256) {
        require(upperBound > 0, "Upper bound must be positive");
        return pseudoRandom(seed) % upperBound;
    }
}


/**
 * @title EssenceForge
 * @dev A smart contract for managing dynamic, evolving digital "Artefacts" interacting with a regenerating "Essence" resource.
 * Incorporates concepts of time-based resource regeneration, dynamic state, and NFT ownership.
 * This contract is designed for exploration of unique mechanics and is not intended for production use without rigorous auditing.
 * Pseudo-randomness used is not cryptographically secure on-chain.
 */
contract EssenceForge is ERC165, IERC721, IERC721Metadata, PseudoRandomHelper {
    using Address for address;
    using Strings for uint256;

    // --- State Variables ---

    address public immutable owner; // Contract deployer

    // Essence Management
    uint256 private systemEssencePool; // Total Essence in the contract, regenerates over time
    uint256 private lastEssenceRegenTimestamp; // Timestamp of the last Essence regeneration update
    uint256 public essenceRegenRatePerSecond; // How much Essence regenerates per second (scaled, e.g., 1e18 for 1 unit)
    mapping(address => uint256) private userEssenceBalance; // Personal Essence balance for each user

    // Artefact Management
    struct Artefact {
        uint256 id;
        uint8[5] properties; // Example properties: [Power, Resilience, Affinity, Speed, Luck] (0-255)
    }

    uint256 private artefactCounter; // Counter for unique Artefact IDs
    mapping(uint256 => Artefact) private artefacts; // Artefact ID => Artefact data

    // ERC721 Standard Compliance
    mapping(address => uint256) private _balances; // Address => Number of Artefacts owned by address
    mapping(uint256 => address) private _owners; // Artefact ID => Owner address
    mapping(uint256 => address) private _tokenApprovals; // Artefact ID => Approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner address => Operator address => Approved

    // Helper for ERC721 enumeration (optional, but useful for getVialsByOwner)
    mapping(address => uint256[]) private _ownerArtefacts;
    mapping(uint256 => uint256) private _artefactOwnerIndex; // Artefact ID => index in owner's array

    // Parameters & Costs (in Wei or Essence units)
    uint256 public synthesisEthCost; // ETH cost to Synthesize Essence
    uint256 public essencePerSynthesis; // Amount of Essence gained per Synthesis
    uint256 public imbuingEssenceCostBase; // Base Essence cost to Imbue Artefact properties
    uint256 public imbuingEssenceCostScale; // Scaling factor for imbuing cost
    uint256 public reforgeEthCost; // ETH cost to Reforge an Artefact
    uint256 public reforgeEssenceCost; // Essence cost to Reforge an Artefact

    string private _baseTokenURI; // Base URI for Artefact metadata

    // --- Events ---

    event ArtefactMinted(uint256 artefactId, address indexed owner, uint8[] initialProperties);
    event EssenceSynthesized(address indexed user, uint256 amount);
    event ArtefactImbued(uint256 indexed artefactId, uint8 propertyIndex, uint8 oldValue, uint8 newValue, uint256 essenceSpent);
    event ArtefactReforged(uint256 indexed artefactId, uint8[] oldProperties, uint8[] newProperties, uint256 essenceSpent);
    event EssenceRegenerated(uint256 amount, uint256 newPoolBalance);

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Constructor ---

    constructor(
        uint256 _initialSystemEssence,
        uint256 _regenRatePerSecond,
        uint256 _synthesisEthCost,
        uint256 _essencePerSynthesis,
        uint256 _imbuingEssenceCostBase,
        uint256 _imbuingEssenceCostScale,
        uint256 _reforgeEthCost,
        uint256 _reforgeEssenceCost,
        string memory __baseTokenURI
    ) {
        owner = msg.sender;
        systemEssencePool = _initialSystemEssence;
        lastEssenceRegenTimestamp = block.timestamp;
        essenceRegenRatePerSecond = _regenRatePerSecond;
        artefactCounter = 0;

        synthesisEthCost = _synthesisEthCost;
        essencePerSynthesis = _essencePerSynthesis;
        imbuingEssenceCostBase = _imbuingEssenceCostBase;
        imbuingEssenceCostScale = _imbuingEssenceCostScale; // Use this to make cost increase per level? Or per imbue action? Let's keep it simple, base cost for now.
        reforgeEthCost = _reforgeEthCost;
        reforgeEssenceCost = _reforgeEssenceCost;

        _baseTokenURI = __baseTokenURI;

        // Register supported interfaces
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenArtefactExists(uint256 artefactId) {
        require(_exists(artefactId), "Artefact does not exist");
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Updates the system Essence pool by applying regeneration based on time elapsed.
     * Called before any function that interacts with the system Essence pool or user Essence balance.
     */
    function _updateSystemEssence() internal {
        uint256 timeElapsed = block.timestamp - lastEssenceRegenTimestamp;
        if (timeElapsed > 0) {
            uint256 regeneratedAmount = timeElapsed * essenceRegenRatePerSecond;
            systemEssencePool += regeneratedAmount;
            lastEssenceRegenTimestamp = block.timestamp;
            emit EssenceRegenerated(regeneratedAmount, systemEssencePool);
        }
    }

    /**
     * @dev Generates initial properties for a new Artefact. Pseudo-random.
     */
    function _generateInitialProperties(uint256 seed) internal view returns (uint8[5] memory) {
        uint8[5] memory properties;
        for (uint8 i = 0; i < 5; i++) {
             // Generate values between 1 and 10 (inclusive) initially
            properties[i] = uint8((pseudoRandom(seed + i) % 10) + 1);
        }
        return properties;
    }

    /**
     * @dev Helper to add an Artefact ID to an owner's list.
     */
    function _addArtefactToOwnerEnumeration(address to, uint256 artefactId) private {
        _ownerArtefacts[to].push(artefactId);
        _artefactOwnerIndex[artefactId] = _ownerArtefacts[to].length - 1;
    }

    /**
     * @dev Helper to remove an Artefact ID from an owner's list.
     */
     function _removeArtefactFromOwnerEnumeration(address from, uint256 artefactId) private {
        uint256 lastTokenIndex = _ownerArtefacts[from].length - 1;
        uint256 tokenIndex = _artefactOwnerIndex[artefactId];

        // If the token is not the last one, swap it with the last token
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownerArtefacts[from][lastTokenIndex];
            _ownerArtefacts[from][tokenIndex] = lastTokenId;
            _artefactOwnerIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last token from the array
        _ownerArtefacts[from].pop();
        delete _artefactOwnerIndex[artefactId];
    }


    // --- Essence Queries ---

    /**
     * @dev Returns the current total system Essence pool.
     * @return uint256 The current system Essence pool balance.
     */
    function getSystemEssencePool() public view returns (uint256) {
        // Note: This doesn't update the pool state, just calculates potential regen for view
        uint256 timeElapsed = block.timestamp - lastEssenceRegenTimestamp;
        uint256 potentialRegen = timeElapsed * essenceRegenRatePerSecond;
        return systemEssencePool + potentialRegen;
    }

    /**
     * @dev Returns the timestamp of the last Essence regeneration calculation.
     * @return uint256 The timestamp.
     */
    function getLastEssenceRegenTimestamp() public view returns (uint256) {
        return lastEssenceRegenTimestamp;
    }

    /**
     * @dev Returns the rate at which system Essence regenerates per second.
     * @return uint256 The regeneration rate.
     */
    function getEssenceRegenRatePerSecond() public view returns (uint256) {
        return essenceRegenRatePerSecond;
    }

     /**
     * @dev Returns the personal Essence balance for a specific user.
     * @param user The address of the user.
     * @return uint256 The user's Essence balance.
     */
    function getUserEssenceBalance(address user) public view returns (uint256) {
        return userEssenceBalance[user];
    }

    // --- Artefact Queries ---

    /**
     * @dev Returns the total number of Artefacts minted.
     * @return uint256 The total supply of Artefacts.
     */
    function getCurrentArtefactSupply() public view returns (uint256) {
        return artefactCounter;
    }

    /**
     * @dev Returns the owner of a specific Artefact. ERC721 ownerOf implementation.
     * @param artefactId The ID of the Artefact.
     * @return address The owner's address.
     */
    function getArtefactOwner(uint256 artefactId) public view whenArtefactExists(artefactId) returns (address) {
        return _owners[artefactId];
    }

    // Alias for ERC721 compliance
    function ownerOf(uint256 artefactId) public view override returns (address) {
         return getArtefactOwner(artefactId);
    }

    /**
     * @dev Returns the array of properties for a specific Artefact.
     * @param artefactId The ID of the Artefact.
     * @return uint8[5] The array of properties.
     */
    function getArtefactProperties(uint256 artefactId) public view whenArtefactExists(artefactId) returns (uint8[5] memory) {
        return artefacts[artefactId].properties;
    }

    /**
     * @dev Returns a specific property value for an Artefact.
     * @param artefactId The ID of the Artefact.
     * @param propertyIndex The index of the property (0 to 4).
     * @return uint8 The property value.
     */
    function getArtefactProperty(uint256 artefactId, uint8 propertyIndex) public view whenArtefactExists(artefactId) returns (uint8) {
        require(propertyIndex < 5, "Invalid property index");
        return artefacts[artefactId].properties[propertyIndex];
    }

    /**
     * @dev Returns the list of Artefact IDs owned by a specific address.
     * @param owner The address of the owner.
     * @return uint256[] An array of Artefact IDs.
     */
    function getArtefactsByOwner(address owner) public view returns (uint256[] memory) {
        return _ownerArtefacts[owner];
    }

    // --- Cost Queries ---

    /**
     * @dev Returns the current ETH cost for Synthesis.
     * @return uint256 The cost in Wei.
     */
    function getSynthesisCostEth() public view returns (uint256) {
        return synthesisEthCost;
    }

    /**
     * @dev Returns the base Essence cost for Imbuing a property.
     * @return uint256 The base Essence cost.
     */
    function getImbuingEssenceCostBase() public view returns (uint256) {
        return imbuingEssenceCostBase;
    }

    /**
     * @dev Returns the current ETH cost for Reforging.
     * @return uint256 The cost in Wei.
     */
    function getReforgeCostEth() public view returns (uint256) {
        return reforgeEthCost;
    }

    /**
     * @dev Returns the current Essence cost for Reforging.
     * @return uint256 The Essence cost.
     */
    function getReforgeCostEssence() public view returns (uint256) {
        return reforgeEssenceCost;
    }

    // --- Core Actions ---

    /**
     * @dev Allows a user to mint a new Artefact.
     * Requires payment of `synthesisEthCost`. Consumes a small amount of system Essence.
     */
    function mintArtefact() public payable {
        require(msg.value >= synthesisEthCost, "Insufficient ETH for minting");

        _updateSystemEssence(); // Ensure Essence pool is up-to-date

        uint256 essenceCost = 100; // Example fixed Essence cost to mint
        require(systemEssencePool >= essenceCost, "System Essence pool too low to mint");

        systemEssencePool -= essenceCost;

        uint256 newId = artefactCounter++;
        uint8[5] memory initialProperties = _generateInitialProperties(newId); // Seed with ID

        artefacts[newId] = Artefact({
            id: newId,
            properties: initialProperties
        });

        // ERC721 minting logic
        address to = msg.sender;
        _owners[newId] = to;
        _balances[to]++;
        _addArtefactToOwnerEnumeration(to, newId);

        emit ArtefactMinted(newId, to, initialProperties);
        emit Transfer(address(0), to, newId); // ERC721 mint event
    }

    /**
     * @dev Allows a user to synthesize Essence from the system pool into their personal balance.
     * Requires payment of `synthesisEthCost`.
     */
    function synthesizeEssence() public payable {
        require(msg.value >= synthesisEthCost, "Insufficient ETH for synthesis");

        _updateSystemEssence(); // Ensure Essence pool is up-to-date

        require(systemEssencePool >= essencePerSynthesis, "System Essence pool too low for synthesis");

        systemEssencePool -= essencePerSynthesis;
        userEssenceBalance[msg.sender] += essencePerSynthesis;

        emit EssenceSynthesized(msg.sender, essencePerSynthesis);
    }

    /**
     * @dev Allows an Artefact owner to spend personal Essence to increase a specific property.
     * @param artefactId The ID of the Artefact to imbue.
     * @param propertyIndex The index of the property to increase (0 to 4).
     * @param amountToSpend The amount of personal Essence to spend.
     */
    function imbueArtefact(uint256 artefactId, uint8 propertyIndex, uint256 amountToSpend) public whenArtefactExists(artefactId) {
        require(_owners[artefactId] == msg.sender, "Only owner can imbue Artefact");
        require(propertyIndex < 5, "Invalid property index");
        require(userEssenceBalance[msg.sender] >= amountToSpend, "Insufficient personal Essence balance");
        require(amountToSpend > 0, "Must spend a positive amount of Essence");

        _updateSystemEssence(); // Ensure Essence pool is up-to-date (less critical here but good practice)

        uint8 currentPropValue = artefacts[artefactId].properties[propertyIndex];
        require(currentPropValue < 255, "Property is already at maximum value");

        userEssenceBalance[msg.sender] -= amountToSpend;

        // Calculate property increase based on Essence spent. Example: 1 Essence = 1/1000th of a property point, capped at 255
        uint256 potentialIncrease = (amountToSpend * 1000) / imbuingEssenceCostBase; // Simple scaling
        uint256 newPropValue = uint256(currentPropValue) + potentialIncrease;

        if (newPropValue > 255) {
            newPropValue = 255;
        }

        artefacts[artefactId].properties[propertyIndex] = uint8(newPropValue);

        emit ArtefactImbued(artefactId, propertyIndex, currentPropValue, uint8(newPropValue), amountToSpend);
    }

    /**
     * @dev Allows an Artefact owner to Reforge it, randomly changing properties at high cost and risk.
     * Requires payment of `reforgeEthCost` and `reforgeEssenceCost`. Uses pseudo-randomness.
     * @param artefactId The ID of the Artefact to reforge.
     */
    function reforgeArtefact(uint256 artefactId) public payable whenArtefactExists(artefactId) {
        require(_owners[artefactId] == msg.sender, "Only owner can reforge Artefact");
        require(msg.value >= reforgeEthCost, "Insufficient ETH for reforging");
        require(userEssenceBalance[msg.sender] >= reforgeEssenceCost, "Insufficient personal Essence for reforging");

        _updateSystemEssence(); // Ensure Essence pool is up-to-date

        userEssenceBalance[msg.sender] -= reforgeEssenceCost;

        uint8[5] memory oldProperties;
        uint8[5] memory newProperties;

        // Store old properties for the event
        for(uint8 i=0; i<5; i++) {
            oldProperties[i] = artefacts[artefactId].properties[i];
        }

        // Apply random transformations to properties
        uint256 seed = artefactId + block.number + block.timestamp + reforgeEssenceCost + reforgeEthCost; // Combine factors for seed

        for (uint8 i = 0; i < 5; i++) {
            uint8 currentValue = artefacts[artefactId].properties[i];
            uint256 randomFactor = pseudoRandom(seed + i); // Different seed for each property

            // Simple random change logic: +/- up to a certain amount, or set new random value
            if (randomFactor % 3 == 0) { // 1/3 chance to increase significantly
                uint256 increase = (randomFactor % 50) + 1; // Increase by 1-50
                newProperties[i] = uint8(Math.min(255, uint256(currentValue) + increase));
            } else if (randomFactor % 3 == 1) { // 1/3 chance to decrease significantly
                 uint256 decrease = (randomFactor % 50) + 1; // Decrease by 1-50
                 newProperties[i] = uint8(Math.max(0, int256(currentValue) - int256(decrease))); // Use int256 for subtraction preventing underflow
            } else { // 1/3 chance to get a new random value in a range
                newProperties[i] = uint8(randomByte(seed + i + 100)); // New random value 0-255
            }
        }

        artefacts[artefactId].properties = newProperties; // Update the properties

        emit ArtefactReforged(artefactId, oldProperties, newProperties, reforgeEssenceCost);
        emit ArtefactPropertiesChanged(artefactId, newProperties); // Optional event for any property change
    }

    // Optional: Event for any property change
    event ArtefactPropertiesChanged(uint256 indexed artefactId, uint8[] newProperties);

    // --- ERC721 Standard Implementations ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function approve(address to, uint256 artefactId) public override {
        address artefactOwner = _owners[artefactId];
        require(artefactOwner != address(0), "ERC721: invalid token ID");
        require(msg.sender == artefactOwner || isApprovedForAll(artefactOwner, msg.sender), "ERC721: approve caller is not token owner nor approved for all");
        _tokenApprovals[artefactId] = to;
        emit Approval(artefactOwner, to, artefactId);
    }

    function getApproved(uint256 artefactId) public view override returns (address) {
         require(_exists(artefactId), "ERC721: approved query for nonexistent token");
         return _tokenApprovals[artefactId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 artefactId) public override {
        // Check if from is the actual owner
        require(_owners[artefactId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Check if msg.sender is owner or approved
        require(_isApprovedOrOwner(msg.sender, artefactId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, artefactId);
    }

     function safeTransferFrom(address from, address to, uint256 artefactId) public override {
         safeTransferFrom(from, to, artefactId, "");
     }

     function safeTransferFrom(address from, address to, uint256 artefactId, bytes memory data) public override {
        require(_owners[artefactId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_isApprovedOrOwner(msg.sender, artefactId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, artefactId);

        // Check if recipient is a smart contract and can receive ERC721 tokens
        if (to.isContract()) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, artefactId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    // --- Internal ERC721 Transfer Logic ---

    function _transfer(address from, address to, uint256 artefactId) internal {
        // Clear approval for the token being transferred
        _tokenApprovals[artefactId] = address(0);

        // Update balances
        _balances[from]--;
        _balances[to]++;

        // Update owner mapping
        _owners[artefactId] = to;

        // Update owner enumeration helper mappings
        _removeArtefactFromOwnerEnumeration(from, artefactId);
        _addArtefactToOwnerEnumeration(to, artefactId);


        emit Transfer(from, to, artefactId);
    }

     function _exists(uint256 artefactId) internal view returns (bool) {
        return _owners[artefactId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 artefactId) internal view returns (bool) {
        address artefactOwner = _owners[artefactId];
        return (spender == artefactOwner || getApproved(artefactId) == spender || isApprovedForAll(artefactOwner, spender));
    }


    // --- Metadata (ERC721Metadata) ---

    function name() public pure override returns (string memory) {
        return "Essence Artefact";
    }

    function symbol() public pure override returns (string memory) {
        return "ESART";
    }

    function tokenURI(uint256 artefactId) public view override returns (string memory) {
        require(_exists(artefactId), "ERC721Metadata: URI query for nonexistent token");

        // Generate dynamic metadata including properties
        Artefact storage artefact = artefacts[artefactId];

        // Simple JSON structure for metadata, base64 encoded
        string memory json = string(abi.encodePacked(
            '{"name": "Artefact #', artefactId.toString(), '",',
            '"description": "A unique digital Artefact from the Essence Forge.",',
            '"properties": {',
                '"Power": ', Strings.toString(artefact.properties[0]), ',',
                '"Resilience": ', Strings.toString(artefact.properties[1]), ',',
                '"Affinity": ', Strings.toString(artefact.properties[2]), ',',
                '"Speed": ', Strings.toString(artefact.properties[3]), ',',
                '"Luck": ', Strings.toString(artefact.properties[4]),
            '}',
            // Add image or other attributes here if applicable
            '}'
        ));

        // Base64 encoding (Solidity doesn't have built-in base64, need a library or simplified version)
        // For a real contract, you'd likely use OpenZeppelin's Base64 or return an IPFS hash etc.
        // Returning a placeholder here or using a simplified inline approach is possible but verbose.
        // Let's just return the base URI + ID for simplicity in this example, acknowledge dynamic part is missing real encoding.
        // Or, let's construct a *simple* data URI.
        // Example structure: data:application/json;base64,eyJuYW1lI...
        // Using a simplified Base64Encode function (illustrative, not a full implementation)
        // This requires a Base64 library contract or inline implementation.
        // For this example, let's return a data URI with *some* properties visible directly or imply off-chain generation.
        // Let's return a simple combined string and note this is not standard base64.

        // A more realistic approach: Point to a gateway URI + ID.
        // E.g., "https://mygateway.io/artefacts/" + artefactId.toString() + ".json"
         if (bytes(_baseTokenURI).length == 0) {
             return ""; // Return empty string if no base URI is set
         }

        return string(abi.encodePacked(_baseTokenURI, artefactId.toString()));

        /*
         // To include properties dynamically on-chain requires encoding. Example using a simplified approach (not standard Base64):
         string memory propertiesJson = string(abi.encodePacked(
             '"Power": ', Strings.toString(artefact.properties[0]), ',',
             '"Resilience": ', Strings.toString(artefact.properties[1]), ',',
             '"Affinity": ', Strings.toString(artefact.properties[2]), ',',
             '"Speed": ', Strings.toString(artefact.properties[3]), ',',
             '"Luck": ', Strings.toString(artefact.properties[4])
         ));

         string memory fullJson = string(abi.encodePacked(
             '{"name": "Artefact #', artefactId.toString(), '",',
             '"description": "A unique digital Artefact from the Essence Forge.",',
             '"attributes": [', // Using attributes array is common for properties
                '{"trait_type": "Power", "value": ', Strings.toString(artefact.properties[0]), '},',
                '{"trait_type": "Resilience", "value": ', Strings.toString(artefact.properties[1]), '},',
                '{"trait_type": "Affinity", "value": ', Strings.toString(artefact.properties[2]), '},',
                '{"trait_type": "Speed", "value": ', Strings.toString(artefact.properties[3]), '},',
                '{"trait_type": "Luck", "value": ', Strings.toString(artefact.properties[4]), '} ],',
             // Add image/animation_url here
             '"image": "ipfs://<your_default_image_hash>"', // Placeholder image
             '}'
         ));

         // This needs a proper Base64 encoder function/library
         // return string(abi.encodePacked("data:application/json;base64,", Base64Encode(bytes(fullJson))));
         */
    }

    /**
     * @dev Sets the base URI for Artefact metadata. Owner only.
     * @param uri The new base URI.
     */
    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Allows the owner to withdraw collected ETH from Synthesis/Reforging fees.
     * @param recipient The address to send ETH to.
     */
    function withdrawEth(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Math Helper (Simple Min for property calculation) ---
    // OpenZeppelin's SafeMath includes min/max, but simple custom one is fine here
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Time-Based Resource Regeneration (`_updateSystemEssence`, `essenceRegenRatePerSecond`):** The `systemEssencePool` is not static. It increases over time based on the block timestamp. This introduces a dynamic element to the core resource, influencing its availability and potentially creating interesting economic or gameplay loops (e.g., waiting for Essence to regenerate, strategizing when to synthesize).
2.  **Dynamic/Evolving NFTs (`Artefact` struct, `properties`, `imbueArtefact`, `reforgeArtefact`):** The "Artefacts" are more than just static tokens. They have mutable `properties` stored directly on-chain. User actions (`imbueArtefact`, `reforgeArtefact`) directly modify these properties, making each Artefact a dynamic asset whose state changes based on interaction. This moves beyond standard static NFT art or simple trait systems.
3.  **Dual Resource Model (ETH + Essence):** The contract uses both native currency (ETH) for base costs (minting, channeling, reforging) and an internal, managed resource (Essence) for specific in-system actions (imbuing, reforging). This creates layered economics and requires users to interact with the system in different ways to acquire each resource.
4.  **Resource Flow and Sinks (Synthesis, Imbuing, Reforging):** The contract explicitly defines how Essence moves: generated in the `systemEssencePool`, transferred to `userEssenceBalance` via `synthesizeEssence`, and consumed from `userEssenceBalance` via `imbueArtefact` and `reforgeArtefact`. The system pool itself is also a sink during minting. This explicit resource management flow is key to the internal economy.
5.  **State-Dependent Actions (Imbuing/Reforging requirements):** Actions like Imbuing and Reforging require not just ETH but also a user's personal Essence balance, which can only be acquired by interacting with the system (Synthesizing). This creates dependencies and potentially forces users to engage with different contract functions strategically.
6.  **Pseudo-Random Property Transformation (`reforgeArtefact` using `PseudoRandomHelper`):** The `reforgeArtefact` function introduces risk and variability by randomly altering properties. While on-chain randomness is limited and not cryptographically secure (a critical point to note in the code), using block data and hashing provides a deterministic-but-unpredictable-in-advance result *on a public chain*, which is a common pattern in on-chain games/dynamics (acknowledging its limitations). This adds a "gambling" or "discovery" element.
7.  **On-Chain Property Storage and Retrieval (`Artefact` struct, `getArtefactProperties`, `getArtefactProperty`):** Storing the dynamic properties directly in the contract state allows them to be accessed and verified directly on-chain, forming the core mutable state of the NFT.
8.  **Integration with ERC721 for Ownership:** While having custom logic, the contract still adheres to the ERC721 standard for ownership (`balanceOf`, `ownerOf`, `transferFrom`, `approve`, `setApprovalForAll`, `tokenURI`), ensuring compatibility with wallets, marketplaces, and the broader NFT ecosystem. The internal logic (`_transfer`, `_addArtefactToOwnerEnumeration`, `_removeArtefactFromOwnerEnumeration`) supports this.
9.  **Metadata for Dynamic Assets (`tokenURI`):** The `tokenURI` function is crucial for NFTs. While the example uses a simplified approach, the intention is for this function (or an associated service) to generate metadata that reflects the *current* dynamic properties of the Artefact, making the metadata itself dynamic. (The provided code snippet demonstrates the structure but skips complex base64 encoding for brevity, noting it would be needed).
10. **Multiple Interaction Types:** The contract provides distinct ways to interact: minting new assets, gaining resources, upgrading assets deterministically (imbue), and transforming assets randomly (reforge). This variety offers different strategies for users.

This contract structure provides a foundation for a system where digital assets are not static collectibles but active participants in a small on-chain ecosystem with its own resources and rules of evolution.