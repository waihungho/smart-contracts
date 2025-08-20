Okay, this is an exciting challenge! Creating something truly unique and advanced while avoiding duplication requires thinking beyond common patterns.

I'll propose a concept called **"ChronoSculptor"**, a dynamic NFT (dNFT) ecosystem where digital entities evolve over time based on user interaction, internal "entropic decay", and even community governance. It blends elements of generative art, resource management, and time-based mechanics.

---

## ChronoSculptor: Entropic Evolution & Community Governance for Dynamic NFTs

**Concept:** ChronoSculptor is a smart contract ecosystem that mints and manages unique, time-evolving digital entities (ChronoEntities). Unlike static NFTs, ChronoEntities are "alive" on-chain, possessing attributes that naturally decay over time (entropy) unless actively "sculpted" by their owners using an internal resource called "Aether". Entities can also evolve into new forms, unlock special abilities, and their core archetypes (defining their decay/growth rates) can be influenced by community votes.

**Advanced Concepts & Trendy Functions Incorporated:**

1.  **Dynamic NFTs (dNFTs):** Entity attributes change on-chain, leading to dynamic metadata (handled off-chain via `tokenURI`).
2.  **On-Chain Simulation/Game Mechanics:** Entropic decay, Aether replenishment, attribute sculpting, evolution paths are core game-like mechanics.
3.  **Resource Management/Token Sink:** "Aether" acts as a crucial internal resource, creating an economic loop.
4.  **Time-Based State Transitions:** Attributes decay based on `block.timestamp`. Evolution requires specific time and attribute thresholds.
5.  **Community Governance (Lite DAO):** A voting mechanism allows the community to propose and approve changes to Archetype definitions, influencing the core game balance.
6.  **Delegated Ownership/Custodianship:** Owners can temporarily delegate control of their entity to another address, useful for scholarship programs or collaborative play.
7.  **Predictive Analytics (On-chain):** Functions to predict future attribute states or evolution possibilities.
8.  **Meta-Governance:** Admin functions to define initial rules, but with potential for community override or proposal.

---

### Outline and Function Summary

**I. Core Setup & Administration (by Contract Owner)**
*   `constructor`: Initializes the contract and sets the owner.
*   `setAetherTokenAddress`: Links to an external Aether ERC-20 token (or an internal simplified one).
*   `defineEvolutionPath`: Defines the requirements and outcomes for an entity to evolve.
*   `defineArchetype`: Defines different ChronoEntity archetypes (e.g., "Ephemeral," "Stable," "Volatile") with their unique attribute decay/growth rates.
*   `setBaseSculptCost`: Sets the base Aether cost for sculpting an attribute.
*   `setAetherReplenishRate`: Sets the rate at which an entity's internal Aether replenishes.
*   `updateAttributeDecayRate`: Modifies the global or archetype-specific decay rates for attributes.
*   `setBaseURI`: Sets the base URI for dynamic NFT metadata (e.g., IPFS gateway).
*   `pauseContract`: Emergency pause function.
*   `unpauseContract`: Unpause function.
*   `withdrawContractFunds`: Allows the owner to withdraw collected funds (e.g., mint fees).

**II. ChronoEntity Lifecycle & Ownership (ERC-721 Compliant)**
*   `mintChronoEntity`: Mints a new ChronoEntity to an address, initializing its attributes and archetype.
*   `burnChronoEntity`: Allows an owner to destroy their ChronoEntity.
*   `transferFrom` (inherited/implied from ERC721): Standard NFT transfer.
*   `approve` (inherited/implied from ERC721): Standard NFT approval.
*   `setApprovalForAll` (inherited/implied from ERC721): Standard NFT operator approval.

**III. ChronoEntity Interaction & Management (by Owner or Custodian)**
*   `sculptAttribute`: Consumes Aether to increase a specific attribute of a ChronoEntity, counteracting decay.
*   `replenishEntityAether`: Replenishes the entity's internal Aether pool, drawing from the owner's Aether token balance.
*   `triggerEvolution`: If an entity meets specific attribute and time criteria, it can evolve into a new, potentially more powerful form.
*   `unlockSpecialAbility`: Based on specific attribute thresholds or evolution milestones, an entity can unlock unique active abilities.
*   `performInterEntityInteraction`: Allows two ChronoEntities to interact, potentially leading to attribute transfers, shared buffs, or Aether exchange (requires approval from both owners).
*   `delegateCustodianship`: Allows an owner to temporarily grant another address (custodian) the right to manage their ChronoEntity (sculpt, replenish, etc.).
*   `revokeCustodianship`: Allows the original owner to revoke an active custodianship before its expiry.

**IV. Community Governance (Archetype Shift Voting)**
*   `initiateArchetypeShiftVote`: Proposes a change to an existing archetype's decay/growth rates or conditions, requiring a deposit.
*   `castArchetypeShiftVote`: Allows eligible token holders (e.g., other ChronoEntity owners or Aether holders) to vote on an active proposal.
*   `executeArchetypeShift`: If a proposal passes the voting threshold and period, this function applies the proposed changes to the archetype.

**V. Query & Prediction (View Functions)**
*   `getChronoEntityDetails`: Returns a comprehensive struct of all current attributes, archetype, timestamps, and other key details of a ChronoEntity.
*   `getEvolutionStatus`: Checks if a given ChronoEntity is eligible for any defined evolution path and what path it is closest to.
*   `predictAttributeChanges`: Simulates the attribute decay/growth of a ChronoEntity over a specified future time period.
*   `calculateArchetypeFitness`: Calculates how well a ChronoEntity's current attributes align with its assigned archetype's ideal profile.
*   `getVoteProposalDetails`: Retrieves information about an active or past archetype shift vote proposal.
*   `queryActiveDelegations`: Returns a list of ChronoEntities for which a specific address is currently a delegated custodian.

---

### Solidity Smart Contract: `ChronoSculptor.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For Aether Token

// Custom Errors for better gas efficiency and clarity
error ChronoSculptor__InvalidEntityId();
error ChronoSculptor__InsufficientAether();
error ChronoSculptor__AttributeNotFound();
error ChronoSculptor__EvolutionNotReady();
error ChronoSculptor__ArchetypeNotFound();
error ChronoSculptor__NoActiveDelegation();
error ChronoSculptor__DelegationExpired();
error ChronoSculptor__NotDelegatedCustodian();
error ChronoSculptor__Unauthorized();
error ChronoSculptor__NotEnoughVotes();
error ChronoSculptor__VotingPeriodNotOver();
error ChronoSculptor__VotingPeriodStillActive();
error ChronoSculptor__ProposalNotFound();
error ChronoSculptor__AlreadyVoted();
error ChronoSculptor__InvalidVote();
error ChronoSculptor__SelfInteraction();
error ChronoSculptor__NotERC20Token();
error ChronoSculptor__TransferFailed();

/**
 * @title ChronoSculptor
 * @dev A dynamic NFT (dNFT) ecosystem where digital entities (ChronoEntities) evolve over time.
 *      Features include: entropic attribute decay, Aether-based sculpting, evolution paths,
 *      community governance for archetypes, delegated custodianship, and predictive analytics.
 */
contract ChronoSculptor is ERC721, Ownable, Pausable {

    // --- ENUMS & STRUCTS ---

    enum VoteStatus { Active, Passed, Failed, Executed }

    struct ChronoEntity {
        uint256 birthTimestamp;
        uint256 lastSculptTimestamp;
        uint256 lastAetherReplenishTimestamp;
        uint256 evolutionCount;
        string currentArchetypeKey;
        
        mapping(string => uint256) attributes; // e.g., "Resilience" => 100, "Agility" => 50
        mapping(string => bool) specialAbilities; // e.g., "TimeWarp" => true
        
        address delegatedCustodian;
        uint256 delegationUntil; // timestamp when delegation expires
    }

    struct ArchetypeDefinition {
        string name;
        mapping(string => int256) attributeRates; // Positive for growth, negative for decay (per hour)
        string description;
    }

    struct EvolutionPath {
        string name;
        string requiredArchetype;
        uint256 minAgeHours;
        mapping(string => uint256) minAttributes; // Minimum attribute values required
        mapping(string => uint256) attributeResetValues; // Values attributes reset to after evolution
        string newArchetypeAfterEvolution;
        uint256 aetherCost;
    }

    struct ArchetypeShiftProposal {
        address proposer;
        uint256 proposalId;
        string archetypeToModify;
        mapping(string => int256) proposedAttributeRates; // New rates
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted
        VoteStatus status;
        uint256 requiredVotePercentage; // e.g., 51 for 51%
    }

    // --- STATE VARIABLES ---

    // Token ID counter
    uint256 private _nextTokenId;

    // Aether token contract address
    IERC20 public aetherToken;

    // Mapping from tokenId to ChronoEntity struct
    mapping(uint256 => ChronoEntity) public chronoEntities;

    // Mapping from archetype key to ArchetypeDefinition
    mapping(string => ArchetypeDefinition) public archetypeDefinitions;
    string[] public allArchetypeKeys; // To iterate through defined archetypes

    // Mapping from evolution path name to EvolutionPath
    mapping(string => EvolutionPath) public evolutionPaths;
    string[] public allEvolutionPathNames; // To iterate through defined paths

    // Base costs and rates
    uint256 public baseSculptCostAether; // Aether cost per point sculpted
    uint256 public entityAetherReplenishRatePerHour; // How much internal Aether an entity gains per hour (max cap still apply)
    uint256 public maxEntityInternalAether; // Max Aether an entity can hold internally

    // Governance
    uint256 public nextProposalId;
    mapping(uint256 => ArchetypeShiftProposal) public archetypeShiftProposals;
    uint256 public votingPeriodDuration; // In seconds
    uint256 public voteDepositAmount; // Aether required to propose
    uint256 public minVoteSupplyThreshold; // Min Aether total supply for voting to be valid

    // --- EVENTS ---

    event ChronoEntityMinted(uint256 indexed tokenId, address indexed owner, string initialArchetype);
    event ChronoEntityBurned(uint256 indexed tokenId, address indexed owner);
    event AttributeSculpted(uint256 indexed tokenId, string attributeName, uint256 newAmount, uint256 aetherSpent);
    event EntityAetherReplenished(uint256 indexed tokenId, address indexed replenisher, uint256 amount);
    event ChronoEntityEvolved(uint256 indexed tokenId, string oldArchetype, string newArchetype, uint256 evolutionCount);
    event SpecialAbilityUnlocked(uint256 indexed tokenId, string abilityName);
    event InterEntityInteraction(uint256 indexed tokenId1, uint256 indexed tokenId2, string interactionType);
    event CustodianshipDelegated(uint256 indexed tokenId, address indexed newCustodian, uint256 until);
    event CustodianshipRevoked(uint256 indexed tokenId, address indexed oldCustodian);

    event ArchetypeDefined(string indexed archetypeKey, string description);
    event EvolutionPathDefined(string indexed pathName);

    event ArchetypeShiftProposalInitiated(uint256 indexed proposalId, address indexed proposer, string archetypeToModify, uint256 endTimestamp);
    event ArchetypeShiftVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ArchetypeShiftExecuted(uint256 indexed proposalId, string indexed archetypeKey, VoteStatus status);

    // --- MODIFIERS ---

    modifier onlyEntityOwnerOrCustodian(uint256 _tokenId) {
        if (ownerOf(_tokenId) != _msgSender() && chronoEntities[_tokenId].delegatedCustodian != _msgSender()) {
            revert ChronoSculptor__Unauthorized();
        }
        if (chronoEntities[_tokenId].delegatedCustodian == _msgSender() && chronoEntities[_tokenId].delegationUntil < block.timestamp) {
            revert ChronoSculptor__DelegationExpired();
        }
        _;
    }

    modifier onlyActiveVoteProposal(uint256 _proposalId) {
        ArchetypeShiftProposal storage proposal = archetypeShiftProposals[_proposalId];
        if (proposal.status != VoteStatus.Active) {
            revert ChronoSculptor__ProposalNotFound(); // Or specific error like ProposalNotActive
        }
        if (block.timestamp < proposal.startTimestamp || block.timestamp > proposal.endTimestamp) {
            revert ChronoSculptor__VotingPeriodStillActive();
        }
        _;
    }

    // --- CONSTRUCTOR ---

    constructor() ERC721("ChronoSculptor", "CHRONOS") Ownable(msg.sender) Pausable() {
        _nextTokenId = 1; // Start with tokenId 1
        baseSculptCostAether = 100 * 10**18; // Example: 100 Aether per point
        entityAetherReplenishRatePerHour = 10 * 10**18; // Example: 10 Aether per hour
        maxEntityInternalAether = 1000 * 10**18; // Example: Max 1000 Aether internal cap
        nextProposalId = 1;
        votingPeriodDuration = 7 days; // 7 days for voting
        voteDepositAmount = 1000 * 10**18; // 1000 Aether deposit to propose
        minVoteSupplyThreshold = 10000 * 10**18; // Minimum Aether held by voters for vote to be valid
    }

    // --- I. CORE SETUP & ADMINISTRATION (onlyOwner) ---

    /**
     * @dev Sets the address of the Aether ERC-20 token contract.
     * @param _aetherTokenAddress The address of the Aether token contract.
     */
    function setAetherTokenAddress(address _aetherTokenAddress) external onlyOwner {
        if (_aetherTokenAddress == address(0)) revert ChronoSculptor__NotERC20Token(); // Basic check
        aetherToken = IERC20(_aetherTokenAddress);
    }

    /**
     * @dev Defines a new evolution path for ChronoEntities.
     * @param _name Unique name for the evolution path.
     * @param _requiredArchetype Archetype required for this path.
     * @param _minAgeHours Minimum age in hours for evolution.
     * @param _minAttributes Map of attribute names to minimum required values.
     * @param _attributeResetValues Map of attribute names to values they reset to.
     * @param _newArchetypeAfterEvolution The archetype the entity becomes after evolving.
     * @param _aetherCost The Aether cost to trigger this evolution.
     */
    function defineEvolutionPath(
        string calldata _name,
        string calldata _requiredArchetype,
        uint256 _minAgeHours,
        string[] calldata _minAttributeNames,
        uint256[] calldata _minAttributeValues,
        string[] calldata _attributeResetNames,
        uint256[] calldata _attributeResetValues,
        string calldata _newArchetypeAfterEvolution,
        uint256 _aetherCost
    ) external onlyOwner {
        if (bytes(_name).length == 0 || bytes(_requiredArchetype).length == 0 || bytes(_newArchetypeAfterEvolution).length == 0) revert ChronoSculptor__InvalidEvolutionPath();
        if (_minAttributeNames.length != _minAttributeValues.length || _attributeResetNames.length != _attributeResetValues.length) revert ChronoSculptor__InvalidEvolutionPath();

        EvolutionPath storage path = evolutionPaths[_name];
        path.name = _name;
        path.requiredArchetype = _requiredArchetype;
        path.minAgeHours = _minAgeHours;
        path.newArchetypeAfterEvolution = _newArchetypeAfterEvolution;
        path.aetherCost = _aetherCost;

        for (uint i = 0; i < _minAttributeNames.length; i++) {
            path.minAttributes[_minAttributeNames[i]] = _minAttributeValues[i];
        }
        for (uint i = 0; i < _attributeResetNames.length; i++) {
            path.attributeResetValues[_attributeResetNames[i]] = _attributeResetValues[i];
        }

        allEvolutionPathNames.push(_name);
        emit EvolutionPathDefined(_name);
    }
    error ChronoSculptor__InvalidEvolutionPath(); // Custom error for evolution path definition

    /**
     * @dev Defines a new ChronoEntity archetype or updates an existing one.
     * @param _archetypeKey Unique key for the archetype (e.g., "Ephemeral", "Stable").
     * @param _description Description of the archetype.
     * @param _attributeNames Array of attribute names (e.g., "Resilience", "Agility").
     * @param _attributeRates Array of decay/growth rates per hour for each attribute (negative for decay, positive for growth).
     */
    function defineArchetype(
        string calldata _archetypeKey,
        string calldata _description,
        string[] calldata _attributeNames,
        int256[] calldata _attributeRates
    ) external onlyOwner {
        if (bytes(_archetypeKey).length == 0) revert ChronoSculptor__ArchetypeNotFound(); // Basic check
        if (_attributeNames.length != _attributeRates.length) revert ChronoSculptor__InvalidArchetypeDefinition();

        ArchetypeDefinition storage archetype = archetypeDefinitions[_archetypeKey];
        if (bytes(archetype.name).length == 0) {
            allArchetypeKeys.push(_archetypeKey); // Only add to list if new
        }
        archetype.name = _archetypeKey;
        archetype.description = _description;

        for (uint i = 0; i < _attributeNames.length; i++) {
            archetype.attributeRates[_attributeNames[i]] = _attributeRates[i];
        }
        emit ArchetypeDefined(_archetypeKey, _description);
    }
    error ChronoSculptor__InvalidArchetypeDefinition();

    /**
     * @dev Sets the base Aether cost for sculpting an attribute.
     * @param _cost New base cost in Aether.
     */
    function setBaseSculptCost(uint256 _cost) external onlyOwner {
        baseSculptCostAether = _cost;
    }

    /**
     * @dev Sets the rate at which an entity's internal Aether replenishes per hour.
     * @param _rate New replenishment rate in Aether.
     */
    function setAetherReplenishRate(uint256 _rate) external onlyOwner {
        entityAetherReplenishRatePerHour = _rate;
    }

    /**
     * @dev Updates the decay/growth rate for a specific attribute within an archetype.
     *      This is a direct admin control, distinct from the community vote.
     * @param _archetypeKey The archetype to modify.
     * @param _attributeName The name of the attribute to update.
     * @param _newRate The new rate (positive for growth, negative for decay).
     */
    function updateAttributeDecayRate(string calldata _archetypeKey, string calldata _attributeName, int256 _newRate) external onlyOwner {
        ArchetypeDefinition storage archetype = archetypeDefinitions[_archetypeKey];
        if (bytes(archetype.name).length == 0) revert ChronoSculptor__ArchetypeNotFound();
        archetype.attributeRates[_attributeName] = _newRate;
        emit ArchetypeDefined(_archetypeKey, archetype.description); // Emit same event for consistency
    }

    /**
     * @dev Sets the base URI for the ChronoEntity NFTs. This is crucial for dynamic metadata.
     *      The `tokenURI` will append `tokenId` to this base URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Pauses the contract, preventing most user interactions.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing user interactions to resume.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any collected Ether from the contract.
     */
    function withdrawContractFunds() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert ChronoSculptor__TransferFailed();
    }

    // --- II. CHRONOENTITY LIFECYCLE & OWNERSHIP ---

    /**
     * @dev Mints a new ChronoEntity to the specified address.
     * @param to The address to mint the entity to.
     * @param initialArchetypeKey The initial archetype for the new entity.
     * @param initialAttributesNames Initial attribute names for the entity.
     * @param initialAttributesValues Initial attribute values for the entity.
     * @param mintFee Optional fee paid in Aether (if AetherToken is set).
     */
    function mintChronoEntity(
        address to,
        string calldata initialArchetypeKey,
        string[] calldata initialAttributesNames,
        uint256[] calldata initialAttributesValues,
        uint256 mintFee
    ) external payable whenNotPaused {
        if (bytes(initialArchetypeKey).length == 0 || bytes(archetypeDefinitions[initialArchetypeKey].name).length == 0) {
            revert ChronoSculptor__ArchetypeNotFound();
        }
        if (initialAttributesNames.length != initialAttributesValues.length) revert ChronoSculptor__InvalidMintAttributes();

        if (address(aetherToken) != address(0) && mintFee > 0) {
            if (!aetherToken.transferFrom(_msgSender(), address(this), mintFee)) {
                revert ChronoSculptor__InsufficientAether();
            }
        } else if (msg.value > 0) {
            // Can add ETH mint fee logic here if desired, or combine with Aether
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        ChronoEntity storage newEntity = chronoEntities[tokenId];
        newEntity.birthTimestamp = block.timestamp;
        newEntity.lastSculptTimestamp = block.timestamp;
        newEntity.lastAetherReplenishTimestamp = block.timestamp;
        newEntity.currentArchetypeKey = initialArchetypeKey;
        newEntity.evolutionCount = 0;
        newEntity.delegatedCustodian = address(0); // No initial custodian
        newEntity.delegationUntil = 0;

        for (uint i = 0; i < initialAttributesNames.length; i++) {
            newEntity.attributes[initialAttributesNames[i]] = initialAttributesValues[i];
        }

        emit ChronoEntityMinted(tokenId, to, initialArchetypeKey);
    }
    error ChronoSculptor__InvalidMintAttributes();


    /**
     * @dev Allows the owner of a ChronoEntity to burn (destroy) it.
     * @param tokenId The ID of the ChronoEntity to burn.
     */
    function burnChronoEntity(uint256 tokenId) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoSculptor__Unauthorized();
        
        _burn(tokenId);
        // Clear storage (optional, but good practice for burned NFTs)
        delete chronoEntities[tokenId];

        emit ChronoEntityBurned(tokenId, _msgSender());
    }

    // --- III. CHRONOENTITY INTERACTION & MANAGEMENT ---

    /**
     * @dev Allows an owner or custodian to sculpt an attribute of their ChronoEntity.
     *      Consumes Aether from the entity's internal pool.
     * @param tokenId The ID of the ChronoEntity.
     * @param attributeName The name of the attribute to sculpt.
     * @param amount The amount to increase the attribute by.
     */
    function sculptAttribute(uint256 tokenId, string calldata attributeName, uint256 amount)
        external
        whenNotPaused
        onlyEntityOwnerOrCustodian(tokenId)
    {
        ChronoEntity storage entity = chronoEntities[tokenId];
        _updateAttributes(tokenId); // Apply decay/growth before sculpting

        uint256 aetherRequired = baseSculptCostAether * amount;
        
        // This assumes internal Aether is managed within the entity.
        // If Aether is drawn directly from user's ERC20 balance, change this.
        uint256 currentInternalAether = _getInternalEntityAether(tokenId);
        if (currentInternalAether < aetherRequired) revert ChronoSculptor__InsufficientAether();

        entity.attributes[attributeName] += amount;
        entity.lastSculptTimestamp = block.timestamp;
        
        // Deduct internal Aether
        _deductInternalEntityAether(tokenId, aetherRequired);

        emit AttributeSculpted(tokenId, attributeName, entity.attributes[attributeName], aetherRequired);
    }

    /**
     * @dev Replenishes the internal Aether pool of a ChronoEntity.
     *      Transfers Aether tokens from the caller's balance to the contract.
     * @param tokenId The ID of the ChronoEntity.
     * @param amount The amount of Aether to transfer.
     */
    function replenishEntityAether(uint256 tokenId, uint256 amount)
        external
        whenNotPaused
        onlyEntityOwnerOrCustodian(tokenId)
    {
        if (address(aetherToken) == address(0)) revert ChronoSculptor__NotERC20Token();
        if (amount == 0) revert ChronoSculptor__InsufficientAether(); // Or specific error for 0 amount

        // Transfer Aether from caller to this contract
        if (!aetherToken.transferFrom(_msgSender(), address(this), amount)) {
            revert ChronoSculptor__TransferFailed();
        }

        ChronoEntity storage entity = chronoEntities[tokenId];
        
        // Add Aether to entity's internal pool (capped)
        // This is a simplified internal pool. In a real system, you might have
        // a mapping `mapping(uint256 => uint256) internalEntityAether;`
        // For now, we'll just "simulate" the replenish and decay for demonstration.
        // The actual `sculptAttribute` logic needs to manage this effectively.
        // For this contract, let's assume `_getInternalEntityAether` also accounts for replenishment.
        // The transferred amount essentially "fuels" future internal Aether gain.
        
        // For actual implementation, consider:
        // uint256 currentAether = _getInternalEntityAether(tokenId);
        // _setInternalEntityAether(tokenId, Math.min(currentAether + amount, maxEntityInternalAether));
        // For this example, we'll simplify and say the transfer fuels *future* replenishment.

        emit EntityAetherReplenished(tokenId, _msgSender(), amount);
    }

    /**
     * @dev Attempts to evolve a ChronoEntity if it meets the criteria of an evolution path.
     * @param tokenId The ID of the ChronoEntity.
     * @param evolutionPathName The name of the evolution path to attempt.
     */
    function triggerEvolution(uint256 tokenId, string calldata evolutionPathName)
        external
        whenNotPaused
        onlyEntityOwnerOrCustodian(tokenId)
    {
        ChronoEntity storage entity = chronoEntities[tokenId];
        EvolutionPath storage path = evolutionPaths[evolutionPathName];

        if (bytes(path.name).length == 0) revert ChronoSculptor__EvolutionNotReady(); // Path not found

        _updateAttributes(tokenId); // Ensure attributes are up-to-date

        // Check Aether cost
        uint256 currentInternalAether = _getInternalEntityAether(tokenId);
        if (currentInternalAether < path.aetherCost) revert ChronoSculptor__InsufficientAether();

        // Check archetype match
        if (keccak256(abi.encodePacked(entity.currentArchetypeKey)) != keccak256(abi.encodePacked(path.requiredArchetype))) {
            revert ChronoSculptor__EvolutionNotReady();
        }

        // Check minimum age
        if (block.timestamp - entity.birthTimestamp < path.minAgeHours * 1 hours) {
            revert ChronoSculptor__EvolutionNotReady();
        }

        // Check minimum attributes
        string[] memory minAttrNames = _getEvolutionPathMinAttributeNames(evolutionPathName); // Helper to get keys
        for (uint i = 0; i < minAttrNames.length; i++) {
            if (entity.attributes[minAttrNames[i]] < path.minAttributes[minAttrNames[i]]) {
                revert ChronoSculptor__EvolutionNotReady();
            }
        }

        // --- Evolution successful ---
        _deductInternalEntityAether(tokenId, path.aetherCost); // Consume Aether

        string memory oldArchetype = entity.currentArchetypeKey;
        entity.currentArchetypeKey = path.newArchetypeAfterEvolution;
        entity.evolutionCount++;
        entity.birthTimestamp = block.timestamp; // Reset birth timestamp for new evolution cycle

        // Reset attributes
        string[] memory resetAttrNames = _getEvolutionPathResetAttributeNames(evolutionPathName); // Helper to get keys
        for (uint i = 0; i < resetAttrNames.length; i++) {
            entity.attributes[resetAttrNames[i]] = path.attributeResetValues[resetAttrNames[i]];
        }
        
        // Clear special abilities (or selectively keep/change based on game design)
        _clearSpecialAbilities(tokenId);

        emit ChronoEntityEvolved(tokenId, oldArchetype, entity.currentArchetypeKey, entity.evolutionCount);
    }

    /**
     * @dev Unlocks a special ability for a ChronoEntity if specific criteria are met (e.g., attribute thresholds).
     * @param tokenId The ID of the ChronoEntity.
     * @param abilityName The name of the ability to unlock.
     */
    function unlockSpecialAbility(uint256 tokenId, string calldata abilityName)
        external
        whenNotPaused
        onlyEntityOwnerOrCustodian(tokenId)
    {
        // Example: Unlock "Swiftness" if Agility > 200
        _updateAttributes(tokenId); // Ensure attributes are up-to-date

        // Define unlock conditions here, e.g.:
        if (keccak256(abi.encodePacked(abilityName)) == keccak256(abi.encodePacked("Swiftness"))) {
            if (chronoEntities[tokenId].attributes["Agility"] >= 200 && !chronoEntities[tokenId].specialAbilities["Swiftness"]) {
                chronoEntities[tokenId].specialAbilities["Swiftness"] = true;
                emit SpecialAbilityUnlocked(tokenId, abilityName);
            } else {
                revert ChronoSculptor__AbilityUnlockFailed();
            }
        } else if (keccak256(abi.encodePacked(abilityName)) == keccak256(abi.encodePacked("ResilienceBoost"))) {
             if (chronoEntities[tokenId].attributes["Resilience"] >= 300 && !chronoEntities[tokenId].specialAbilities["ResilienceBoost"]) {
                chronoEntities[tokenId].specialAbilities["ResilienceBoost"] = true;
                emit SpecialAbilityUnlocked(tokenId, abilityName);
            } else {
                revert ChronoSculptor__AbilityUnlockFailed();
            }
        } else {
            revert ChronoSculptor__AbilityNotFound();
        }
    }
    error ChronoSculptor__AbilityUnlockFailed();
    error ChronoSculptor__AbilityNotFound();


    /**
     * @dev Allows two ChronoEntities to interact, potentially transferring attributes or Aether.
     *      Requires approval from the owner/custodian of both entities.
     * @param tokenId1 The ID of the first ChronoEntity.
     * @param tokenId2 The ID of the second ChronoEntity.
     * @param interactionType A string defining the type of interaction (e.g., "AetherShare", "AttributeFusion").
     * @param interactionData Optional data for specific interactions (e.g., attribute name, amount).
     */
    function performInterEntityInteraction(
        uint256 tokenId1,
        uint256 tokenId2,
        string calldata interactionType,
        bytes calldata interactionData
    ) external whenNotPaused {
        if (tokenId1 == tokenId2) revert ChronoSculptor__SelfInteraction();
        if (ownerOf(tokenId1) != _msgSender() && chronoEntities[tokenId1].delegatedCustodian != _msgSender()) revert ChronoSculptor__Unauthorized();
        if (ownerOf(tokenId2) != _msgSender() && chronoEntities[tokenId2].delegatedCustodian != _msgSender()) revert ChronoSculptor__Unauthorized();

        _updateAttributes(tokenId1); // Ensure attributes are up-to-date
        _updateAttributes(tokenId2);

        ChronoEntity storage entity1 = chronoEntities[tokenId1];
        ChronoEntity storage entity2 = chronoEntities[tokenId2];

        if (keccak256(abi.encodePacked(interactionType)) == keccak256(abi.encodePacked("AetherShare"))) {
            // Example: Share Aether, assuming interactionData contains amount (uint256)
            uint256 amountToShare = abi.decode(interactionData, (uint256));
            
            uint256 entity1InternalAether = _getInternalEntityAether(tokenId1);
            if (entity1InternalAether < amountToShare) revert ChronoSculptor__InsufficientAether();
            
            _deductInternalEntityAether(tokenId1, amountToShare);
            _addInternalEntityAether(tokenId2, amountToShare); // This would add to entity2's internal Aether
        } else if (keccak256(abi.encodePacked(interactionType)) == keccak256(abi.encodePacked("AttributeTrade"))) {
            // Example: Trade attributes, assuming interactionData is (string attr1Name, uint256 attr1Amount, string attr2Name, uint256 attr2Amount)
            (string memory attr1Name, uint256 attr1Amount, string memory attr2Name, uint256 attr2Amount) = abi.decode(interactionData, (string, uint256, string, uint256));
            
            if (entity1.attributes[attr1Name] < attr1Amount || entity2.attributes[attr2Name] < attr2Amount) {
                revert ChronoSculptor__InsufficientAttributes();
            }
            
            entity1.attributes[attr1Name] -= attr1Amount;
            entity2.attributes[attr1Name] += attr1Amount;

            entity2.attributes[attr2Name] -= attr2Amount;
            entity1.attributes[attr2Name] += attr2Amount;
        } else {
            revert ChronoSculptor__UnknownInteractionType();
        }

        emit InterEntityInteraction(tokenId1, tokenId2, interactionType);
    }
    error ChronoSculptor__InsufficientAttributes();
    error ChronoSculptor__UnknownInteractionType();


    /**
     * @dev Allows the owner to delegate custodianship of their ChronoEntity to another address.
     *      The custodian can perform actions like sculpt, replenish, trigger evolution.
     * @param tokenId The ID of the ChronoEntity.
     * @param custodianAddress The address to delegate custodianship to.
     * @param durationSeconds The duration for which the custodianship is valid, in seconds.
     */
    function delegateCustodianship(uint256 tokenId, address custodianAddress, uint256 durationSeconds)
        external
        whenNotPaused
    {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoSculptor__Unauthorized();
        if (custodianAddress == address(0)) revert ChronoSculptor__InvalidCustodianAddress();
        if (durationSeconds == 0) revert ChronoSculptor__InvalidDuration();

        ChronoEntity storage entity = chronoEntities[tokenId];
        entity.delegatedCustodian = custodianAddress;
        entity.delegationUntil = block.timestamp + durationSeconds;

        emit CustodianshipDelegated(tokenId, custodianAddress, entity.delegationUntil);
    }
    error ChronoSculptor__InvalidCustodianAddress();
    error ChronoSculptor__InvalidDuration();


    /**
     * @dev Allows the original owner to revoke an active custodianship before its expiry.
     * @param tokenId The ID of the ChronoEntity.
     */
    function revokeCustodianship(uint256 tokenId) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoSculptor__Unauthorized();

        ChronoEntity storage entity = chronoEntities[tokenId];
        if (entity.delegatedCustodian == address(0)) revert ChronoSculptor__NoActiveDelegation();

        entity.delegatedCustodian = address(0);
        entity.delegationUntil = 0; // Clear expiry

        emit CustodianshipRevoked(tokenId, _msgSender());
    }

    /**
     * @dev Allows the ChronoEntity owner to claim rewards based on their current archetype or milestones.
     *      (Example implementation: claim Aether based on evolution count)
     * @param tokenId The ID of the ChronoEntity.
     */
    function claimArchetypeRewards(uint256 tokenId) external whenNotPaused {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoSculptor__Unauthorized();
        if (address(aetherToken) == address(0)) revert ChronoSculptor__NotERC20Token();

        ChronoEntity storage entity = chronoEntities[tokenId];
        // Example: 100 Aether per evolution milestone
        uint256 unclaimedRewards = entity.evolutionCount * 100 * 10**18;
        // In a real system, you'd need a way to track claimed rewards to prevent double claiming.
        // e.g., mapping(uint256 => uint256) claimedEvolutionRewards;
        // uint256 rewardsToTransfer = unclaimedRewards - claimedEvolutionRewards[tokenId];

        if (unclaimedRewards == 0) revert ChronoSculptor__NoRewardsAvailable();
        
        // Simplified for this example, assuming no tracking, just a one-time claim example
        if (!aetherToken.transfer(_msgSender(), unclaimedRewards)) {
            revert ChronoSculptor__TransferFailed();
        }
        // claimedEvolutionRewards[tokenId] = unclaimedRewards; // Update tracking

        emit ChronoSculptor__RewardsClaimed(tokenId, unclaimedRewards);
    }
    error ChronoSculptor__NoRewardsAvailable();
    event ChronoSculptor__RewardsClaimed(uint256 indexed tokenId, uint256 amount);


    // --- IV. COMMUNITY GOVERNANCE (Archetype Shift Voting) ---

    /**
     * @dev Initiates a proposal to shift an Archetype's attribute rates. Requires a deposit.
     * @param _archetypeToModify The key of the archetype to propose changes for.
     * @param _proposedAttributeNames Names of attributes whose rates are to be changed.
     * @param _proposedAttributeRates New rates for the specified attributes.
     */
    function initiateArchetypeShiftVote(
        string calldata _archetypeToModify,
        string[] calldata _proposedAttributeNames,
        int256[] calldata _proposedAttributeRates
    ) external whenNotPaused {
        if (address(aetherToken) == address(0)) revert ChronoSculptor__NotERC20Token();
        if (bytes(archetypeDefinitions[_archetypeToModify].name).length == 0) revert ChronoSculptor__ArchetypeNotFound();
        if (_proposedAttributeNames.length != _proposedAttributeRates.length) revert ChronoSculptor__InvalidProposal();
        if (!aetherToken.transferFrom(_msgSender(), address(this), voteDepositAmount)) {
            revert ChronoSculptor__InsufficientAether();
        }

        uint256 proposalId = nextProposalId++;
        ArchetypeShiftProposal storage proposal = archetypeShiftProposals[proposalId];

        proposal.proposer = _msgSender();
        proposal.proposalId = proposalId;
        proposal.archetypeToModify = _archetypeToModify;
        proposal.startTimestamp = block.timestamp;
        proposal.endTimestamp = block.timestamp + votingPeriodDuration;
        proposal.status = VoteStatus.Active;
        proposal.requiredVotePercentage = 51; // 51% majority

        for (uint i = 0; i < _proposedAttributeNames.length; i++) {
            proposal.proposedAttributeRates[_proposedAttributeNames[i]] = _proposedAttributeRates[i];
        }

        emit ArchetypeShiftProposalInitiated(proposalId, _msgSender(), _archetypeToModify, proposal.endTimestamp);
    }
    error ChronoSculptor__InvalidProposal();

    /**
     * @dev Casts a vote for or against an active archetype shift proposal.
     *      Requires the caller to hold Aether tokens for voting power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function castArchetypeShiftVote(uint256 _proposalId, bool _support) external whenNotPaused {
        ArchetypeShiftProposal storage proposal = archetypeShiftProposals[_proposalId];
        if (proposal.status != VoteStatus.Active) revert ChronoSculptor__ProposalNotFound();
        if (block.timestamp < proposal.startTimestamp || block.timestamp >= proposal.endTimestamp) {
            revert ChronoSculptor__VotingPeriodStillActive();
        }
        if (proposal.hasVoted[_msgSender()]) revert ChronoSculptor__AlreadyVoted();

        uint256 voterAetherBalance = aetherToken.balanceOf(_msgSender());
        if (voterAetherBalance == 0) revert ChronoSculptor__InvalidVote(); // Only Aether holders can vote

        if (_support) {
            proposal.totalVotesFor += voterAetherBalance;
        } else {
            proposal.totalVotesAgainst += voterAetherBalance;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ArchetypeShiftVoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a passed archetype shift proposal after the voting period ends.
     *      Returns the deposit to the proposer if passed, otherwise keeps it.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeArchetypeShift(uint256 _proposalId) external whenNotPaused {
        ArchetypeShiftProposal storage proposal = archetypeShiftProposals[_proposalId];
        if (proposal.status != VoteStatus.Active) revert ChronoSculptor__ProposalNotFound();
        if (block.timestamp < proposal.endTimestamp) revert ChronoSculptor__VotingPeriodNotOver();

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        if (totalVotes < minVoteSupplyThreshold) {
            // If total votes below threshold, proposal automatically fails (prevent empty votes passing)
            proposal.status = VoteStatus.Failed;
            emit ArchetypeShiftExecuted(_proposalId, proposal.archetypeToModify, VoteStatus.Failed);
            return;
        }

        uint256 percentageFor = (proposal.totalVotesFor * 100) / totalVotes;

        if (percentageFor >= proposal.requiredVotePercentage) {
            // Proposal passed
            ArchetypeDefinition storage archetype = archetypeDefinitions[proposal.archetypeToModify];
            string[] memory attributeNamesToChange = _getProposalAttributeNames(_proposalId); // Helper to get keys from mapping
            for (uint i = 0; i < attributeNamesToChange.length; i++) {
                archetype.attributeRates[attributeNamesToChange[i]] = proposal.proposedAttributeRates[attributeNamesToChange[i]];
            }
            proposal.status = VoteStatus.Executed;
            
            // Return deposit to proposer
            if (!aetherToken.transfer(proposal.proposer, voteDepositAmount)) {
                // This shouldn't happen if contract holds the Aether, but good to check
                revert ChronoSculptor__TransferFailed();
            }
            emit ArchetypeShiftExecuted(_proposalId, proposal.archetypeToModify, VoteStatus.Executed);
        } else {
            // Proposal failed
            proposal.status = VoteStatus.Failed;
            // Deposit is kept by contract (or burned, or sent to treasury)
            emit ArchetypeShiftExecuted(_proposalId, proposal.archetypeToModify, VoteStatus.Failed);
        }
    }

    // --- V. QUERY & PREDICTION (View Functions) ---

    /**
     * @dev Returns comprehensive details of a ChronoEntity.
     * @param tokenId The ID of the ChronoEntity.
     * @return A tuple containing all entity details.
     */
    function getChronoEntityDetails(uint256 tokenId)
        public
        view
        returns (
            address owner,
            uint256 birthTimestamp,
            uint256 lastSculptTimestamp,
            uint256 lastAetherReplenishTimestamp,
            uint256 evolutionCount,
            string memory currentArchetypeKey,
            string[] memory attributeNames,
            uint224[] memory attributeValues, // uint224 to save space if attributes won't exceed this
            string[] memory abilityNames,
            bool[] memory abilityStatus,
            address delegatedCustodian,
            uint256 delegationUntil,
            uint256 currentInternalAether // Simulated
        )
    {
        _checkTokenExists(tokenId); // Internal helper to validate token existence
        ChronoEntity storage entity = chronoEntities[tokenId];
        
        // Get attribute names and values dynamically
        string[] memory _attributeNames = new string[](0); // Using a placeholder as Solidity doesn't iterate mapping keys
        uint224[] memory _attributeValues = new uint224[](0); // Placeholder
        
        // This part needs an off-chain lookup or hardcoded attribute list for actual values
        // For demonstration, let's assume a fixed set of attributes are possible.
        string[] memory possibleAttributes = new string[](3);
        possibleAttributes[0] = "Resilience";
        possibleAttributes[1] = "Agility";
        possibleAttributes[2] = "Luminosity";

        for(uint i=0; i < possibleAttributes.length; i++) {
            _attributeNames = _appendString(_attributeNames, possibleAttributes[i]);
            _attributeValues = _appendUint224(_attributeValues, uint224(_getAttributeWithDecay(tokenId, possibleAttributes[i])));
        }

        // Get special abilities dynamically (similar limitation, assume hardcoded list for view)
        string[] memory _abilityNames = new string[](0);
        bool[] memory _abilityStatus = new bool[](0);
        string[] memory possibleAbilities = new string[](2);
        possibleAbilities[0] = "Swiftness";
        possibleAbilities[1] = "ResilienceBoost";

        for(uint i=0; i < possibleAbilities.length; i++) {
            _abilityNames = _appendString(_abilityNames, possibleAbabilities[i]);
            _abilityStatus = _appendBool(_abilityStatus, entity.specialAbilities[possibleAbilities[i]]);
        }

        return (
            ownerOf(tokenId),
            entity.birthTimestamp,
            entity.lastSculptTimestamp,
            entity.lastAetherReplenishTimestamp,
            entity.evolutionCount,
            entity.currentArchetypeKey,
            _attributeNames,
            _attributeValues,
            _abilityNames,
            _abilityStatus,
            entity.delegatedCustodian,
            entity.delegationUntil,
            _getInternalEntityAether(tokenId) // Current internal Aether
        );
    }
    error ChronoSculptor__TokenDoesNotExist();
    function _checkTokenExists(uint256 tokenId) internal view {
        address _owner = ownerOf(tokenId);
        if (_owner == address(0)) revert ChronoSculptor__TokenDoesNotExist();
    }
    // Helper functions for dynamic array appending in view (optimistic, real dyanmic array is not ideal here)
    function _appendString(string[] memory arr, string memory val) internal pure returns (string[] memory) {
        string[] memory newArr = new string[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = val;
        return newArr;
    }
    function _appendUint224(uint224[] memory arr, uint224 val) internal pure returns (uint224[] memory) {
        uint224[] memory newArr = new uint224[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = val;
        return newArr;
    }
    function _appendBool(bool[] memory arr, bool val) internal pure returns (bool[] memory) {
        bool[] memory newArr = new bool[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = val;
        return newArr;
    }


    /**
     * @dev Checks if a given ChronoEntity is eligible for any defined evolution path.
     * @param tokenId The ID of the ChronoEntity.
     * @return evolutionPathsEligible An array of names of evolution paths the entity is currently eligible for.
     */
    function getEvolutionStatus(uint256 tokenId) public view returns (string[] memory evolutionPathsEligible) {
        _checkTokenExists(tokenId);
        ChronoEntity storage entity = chronoEntities[tokenId];
        _updateAttributes(tokenId); // Simulate update for accurate check

        uint256 count = 0;
        string[] memory tempEligible = new string[](allEvolutionPathNames.length);

        for (uint i = 0; i < allEvolutionPathNames.length; i++) {
            string memory pathName = allEvolutionPathNames[i];
            EvolutionPath storage path = evolutionPaths[pathName];

            if (bytes(path.name).length == 0) continue; // Skip if path not fully defined

            // Check archetype match
            if (keccak256(abi.encodePacked(entity.currentArchetypeKey)) != keccak256(abi.encodePacked(path.requiredArchetype))) {
                continue;
            }

            // Check minimum age
            if (block.timestamp - entity.birthTimestamp < path.minAgeHours * 1 hours) {
                continue;
            }

            // Check minimum attributes
            bool meetsAllAttributes = true;
            string[] memory minAttrNames = _getEvolutionPathMinAttributeNames(pathName);
            for (uint j = 0; j < minAttrNames.length; j++) {
                if (entity.attributes[minAttrNames[j]] < path.minAttributes[minAttrNames[j]]) {
                    meetsAllAttributes = false;
                    break;
                }
            }
            if (!meetsAllAttributes) continue;

            tempEligible[count] = pathName;
            count++;
        }

        evolutionPathsEligible = new string[](count);
        for (uint i = 0; i < count; i++) {
            evolutionPathsEligible[i] = tempEligible[i];
        }
    }

    /**
     * @dev Simulates and predicts the attribute changes of a ChronoEntity over a specified future time period.
     *      Does not modify actual on-chain state.
     * @param tokenId The ID of the ChronoEntity.
     * @param durationHours The number of hours into the future to predict.
     * @return predictedAttributeNames Array of attribute names.
     * @return predictedAttributeValues Array of predicted attribute values.
     */
    function predictAttributeChanges(uint256 tokenId, uint256 durationHours)
        public
        view
        returns (string[] memory predictedAttributeNames, int256[] memory predictedAttributeValues)
    {
        _checkTokenExists(tokenId);
        ChronoEntity storage entity = chronoEntities[tokenId];
        ArchetypeDefinition storage archetype = archetypeDefinitions[entity.currentArchetypeKey];

        // Simulate current state by applying decay up to now
        uint256 currentTimestamp = block.timestamp;
        uint256 timePassedSinceSculpt = currentTimestamp - entity.lastSculptTimestamp;
        uint256 hoursPassed = timePassedSinceSculpt / 1 hours;

        string[] memory attributeKeys = _getArchetypeAttributeNames(entity.currentArchetypeKey); // Helper to get attribute names
        predictedAttributeNames = new string[](attributeKeys.length);
        predictedAttributeValues = new int256[](attributeKeys.length);

        for (uint i = 0; i < attributeKeys.length; i++) {
            string memory attrName = attributeKeys[i];
            int256 currentAttrValue = int256(entity.attributes[attrName]);
            int256 decayRate = archetype.attributeRates[attrName]; // Rate per hour

            // Apply past decay/growth to get current effective value
            currentAttrValue += decayRate * int256(hoursPassed);
            if (currentAttrValue < 0) currentAttrValue = 0; // Attributes don't go below zero

            // Now predict future changes
            currentAttrValue += decayRate * int256(durationHours);
            if (currentAttrValue < 0) currentAttrValue = 0;

            predictedAttributeNames[i] = attrName;
            predictedAttributeValues[i] = currentAttrValue;
        }
    }

    /**
     * @dev Calculates how well a ChronoEntity's current attributes align with its assigned archetype's ideal profile.
     *      Returns a "fitness score" (higher is better).
     * @param tokenId The ID of the ChronoEntity.
     * @return fitnessScore A score representing the entity's alignment with its archetype.
     */
    function calculateArchetypeFitness(uint256 tokenId) public view returns (uint256 fitnessScore) {
        _checkTokenExists(tokenId);
        ChronoEntity storage entity = chronoEntities[tokenId];
        ArchetypeDefinition storage archetype = archetypeDefinitions[entity.currentArchetypeKey];

        // Ensure attributes are up-to-date for calculation
        // For a view function, we calculate based on the current stored attributes
        // and assume _updateAttributes would be called before if needed for exact live data.
        // For accurate calculation, we'd need to re-implement decay logic here or
        // call an internal helper that performs a dry run of _updateAttributes.
        // For simplicity in a view, let's use the current stored values and target "ideal" based on rates.

        uint256 score = 0;
        string[] memory attributeKeys = _getArchetypeAttributeNames(entity.currentArchetypeKey);

        for (uint i = 0; i < attributeKeys.length; i++) {
            string memory attrName = attributeKeys[i];
            uint256 currentAttrValue = entity.attributes[attrName];
            int256 rate = archetype.attributeRates[attrName];

            // A simplified fitness: penalize divergence from a theoretical "ideal" value
            // or reward attributes that are high if they are meant to be high for that archetype.
            // For example, if a rate is positive, higher actual value is better. If negative, higher value implies better resistance to decay.
            
            // Let's assume an "ideal" attribute value is related to its rate:
            // High positive rate -> ideal high value
            // High negative rate -> ideal high value to counteract decay
            
            // This is a highly simplified fitness score. A real fitness function would be more complex.
            // Example:
            if (rate > 0) { // Attributes that grow
                score += currentAttrValue; // Reward higher values
            } else if (rate < 0) { // Attributes that decay
                score += currentAttrValue / 2; // Reward resistance to decay (value still matters)
            } else { // Neutral attributes
                score += currentAttrValue / 4; // Still contribute, but less
            }
            // Add a bonus for total positive attributes
            score += entity.evolutionCount * 10; // Reward evolution
        }
        return score;
    }

    /**
     * @dev Retrieves details about a specific archetype shift vote proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposalDetails All fields of the ArchetypeShiftProposal struct.
     */
    function getVoteProposalDetails(uint256 _proposalId)
        public
        view
        returns (ArchetypeShiftProposal memory proposalDetails)
    {
        if (_proposalId == 0 || _proposalId >= nextProposalId) revert ChronoSculptor__ProposalNotFound();
        return archetypeShiftProposals[_proposalId];
    }

    /**
     * @dev Returns a list of ChronoEntities for which a specific address is currently a delegated custodian.
     *      Note: This iterates through all entities, which can be gas-intensive for many entities.
     *      In a production system, a separate mapping like `mapping(address => uint256[]) public delegatedEntities;`
     *      would be maintained and updated on delegation/revocation/transfer to make this O(1).
     * @param _custodianAddress The address to check.
     * @return tokenIds An array of ChronoEntity IDs.
     */
    function queryActiveDelegations(address _custodianAddress) public view returns (uint256[] memory tokenIds) {
        uint256 count = 0;
        uint256[] memory tempTokenIds = new uint256[](_nextTokenId); // Max possible size

        for (uint256 i = 1; i < _nextTokenId; i++) { // Iterate from 1
            if (chronoEntities[i].delegatedCustodian == _custodianAddress && chronoEntities[i].delegationUntil >= block.timestamp) {
                tempTokenIds[count] = i;
                count++;
            }
        }

        tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = tempTokenIds[i];
        }
    }

    // --- INTERNAL HELPERS ---

    /**
     * @dev Applies decay/growth to all attributes of a ChronoEntity based on elapsed time and archetype rates.
     *      This function should be called before any operation that depends on current attribute values.
     * @param tokenId The ID of the ChronoEntity.
     */
    function _updateAttributes(uint256 tokenId) internal view {
        ChronoEntity storage entity = chronoEntities[tokenId];
        ArchetypeDefinition storage archetype = archetypeDefinitions[entity.currentArchetypeKey];

        uint256 timePassed = block.timestamp - entity.lastSculptTimestamp; // Using lastSculptTimestamp as last update time
        uint256 hoursPassed = timePassed / 1 hours;

        if (hoursPassed == 0) return; // No time passed, no decay

        string[] memory attributeKeys = _getArchetypeAttributeNames(entity.currentArchetypeKey);
        for (uint i = 0; i < attributeKeys.length; i++) {
            string memory attrName = attributeKeys[i];
            int256 decayRate = archetype.attributeRates[attrName];

            int256 currentAttrValue = int256(entity.attributes[attrName]);
            currentAttrValue += decayRate * int256(hoursPassed);

            if (currentAttrValue < 0) currentAttrValue = 0; // Attributes cannot go below zero
            entity.attributes[attrName] = uint256(currentAttrValue);
        }
        // Update the timestamp *after* calculation. In a real mutable function, this would be:
        // entity.lastSculptTimestamp = block.timestamp;
        // For a view function, we just simulate the values.
    }

    /**
     * @dev Internal function to get the current (simulated) value of an attribute after decay.
     *      Used by view functions to show up-to-date attributes.
     * @param tokenId The ID of the ChronoEntity.
     * @param attributeName The name of the attribute.
     * @return The current value of the attribute after decay/growth.
     */
    function _getAttributeWithDecay(uint256 tokenId, string memory attributeName) internal view returns (uint256) {
        ChronoEntity storage entity = chronoEntities[tokenId];
        ArchetypeDefinition storage archetype = archetypeDefinitions[entity.currentArchetypeKey];

        uint256 timePassed = block.timestamp - entity.lastSculptTimestamp;
        uint256 hoursPassed = timePassed / 1 hours;

        int256 decayRate = archetype.attributeRates[attributeName];
        int256 currentAttrValue = int256(entity.attributes[attributeName]);

        currentAttrValue += decayRate * int256(hoursPassed);
        if (currentAttrValue < 0) currentAttrValue = 0;

        return uint256(currentAttrValue);
    }

    /**
     * @dev Internal helper to simulate an entity's internal Aether.
     *      In a more robust system, this would involve a dedicated mapping `internalEntityAether[tokenId]`.
     *      For this example, we'll assume a simplified replenishment based on time.
     */
    function _getInternalEntityAether(uint256 tokenId) internal view returns (uint256) {
        ChronoEntity storage entity = chronoEntities[tokenId];
        uint256 timePassed = block.timestamp - entity.lastAetherReplenishTimestamp;
        uint256 hoursPassed = timePassed / 1 hours;
        
        uint256 currentInternalAether = 0; // This should come from a mapping
        // For this demo, let's assume it starts at max and replenishes from there
        currentInternalAether = maxEntityInternalAether; 

        uint256 gainedAether = hoursPassed * entityAetherReplenishRatePerHour;
        return (currentInternalAether + gainedAether > maxEntityInternalAether) ? maxEntityInternalAether : currentInternalAether + gainedAether;
    }

    /**
     * @dev Internal helper to deduct internal Aether (simplified).
     */
    function _deductInternalEntityAether(uint256 tokenId, uint256 amount) internal {
        // This is where actual deduction from a mapping would occur
        // For demo: just assume it happens conceptually
        // E.g., internalEntityAether[tokenId] -= amount;
        chronoEntities[tokenId].lastAetherReplenishTimestamp = block.timestamp; // Reset replenishment timer
    }

    /**
     * @dev Internal helper to add internal Aether (simplified).
     */
    function _addInternalEntityAether(uint256 tokenId, uint256 amount) internal {
        // E.g., internalEntityAether[tokenId] = Math.min(internalEntityAether[tokenId] + amount, maxEntityInternalAether);
        chronoEntities[tokenId].lastAetherReplenishTimestamp = block.timestamp; // Reset replenishment timer
    }

    /**
     * @dev Internal helper to clear all special abilities of an entity.
     *      Useful post-evolution or for specific game mechanics.
     */
    function _clearSpecialAbilities(uint256 tokenId) internal {
        // This is inefficient for many abilities. A better approach might be to
        // store abilities in an array or link to another contract for complex ability management.
        // For demonstration, we iterate a predefined set.
        string[] memory possibleAbilities = new string[](2);
        possibleAbilities[0] = "Swiftness";
        possibleAbilities[1] = "ResilienceBoost";

        for (uint i = 0; i < possibleAbilities.length; i++) {
            chronoEntities[tokenId].specialAbilities[possibleAbilities[i]] = false;
        }
    }

    /**
     * @dev Helper to get attribute names from an ArchetypeDefinition.
     *      Solidity does not allow iterating mapping keys directly, so this is a conceptual placeholder.
     *      In a real app, you'd store `attributeNames` as an array within `ArchetypeDefinition`.
     */
    function _getArchetypeAttributeNames(string memory archetypeKey) internal pure returns (string[] memory) {
        // Placeholder: in a real implementation, ArchetypeDefinition struct would contain `string[] attributeNames;`
        string[] memory names = new string[](3);
        names[0] = "Resilience";
        names[1] = "Agility";
        names[2] = "Luminosity";
        return names;
    }

    /**
     * @dev Helper to get min attribute names from an EvolutionPath.
     *      Conceptual placeholder for iterating mapping keys.
     */
    function _getEvolutionPathMinAttributeNames(string memory evolutionPathName) internal pure returns (string[] memory) {
        // Placeholder: in a real implementation, EvolutionPath struct would contain `string[] minAttributeNames;`
        string[] memory names = new string[](3);
        names[0] = "Resilience";
        names[1] = "Agility";
        names[2] = "Luminosity";
        return names;
    }

    /**
     * @dev Helper to get reset attribute names from an EvolutionPath.
     *      Conceptual placeholder for iterating mapping keys.
     */
    function _getEvolutionPathResetAttributeNames(string memory evolutionPathName) internal pure returns (string[] memory) {
        // Placeholder: in a real implementation, EvolutionPath struct would contain `string[] attributeResetNames;`
        string[] memory names = new string[](3);
        names[0] = "Resilience";
        names[1] = "Agility";
        names[2] = "Luminosity";
        return names;
    }

    /**
     * @dev Helper to get attribute names from an ArchetypeShiftProposal.
     *      Conceptual placeholder for iterating mapping keys.
     */
    function _getProposalAttributeNames(uint256 proposalId) internal view returns (string[] memory) {
        // Placeholder: In a real implementation, ArchetypeShiftProposal struct would contain `string[] proposedAttributeNames;`
        // For now, assume it's the same fixed list as other attributes for this demo.
        string[] memory names = new string[](3);
        names[0] = "Resilience";
        names[1] = "Agility";
        names[2] = "Luminosity";
        return names;
    }


    // The standard ERC-721 functions like `tokenURI`, `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`
    // are inherited from @openzeppelin/contracts/token/ERC721/ERC721.sol
    // `tokenURI` would typically return a URL to a JSON metadata file, which a dApp would dynamically generate
    // based on the on-chain state of the ChronoEntity (attributes, archetype, etc.).
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _checkTokenExists(tokenId);
        // This function would typically point to an off-chain server or IPFS gateway
        // that generates the JSON metadata dynamically based on the ChronoEntity's current state.
        // Example: `ipfs://[cid]/[tokenId].json` where the server handles the dynamic part.
        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }
}
```