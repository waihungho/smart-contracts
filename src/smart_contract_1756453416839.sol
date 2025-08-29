Here's a Solidity smart contract, `AuraSynthesizer`, designed with several advanced, creative, and trendy concepts. It focuses on a dynamic NFT ecosystem driven by external data, autonomous agent-like functionalities, and gamified discovery.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
    Contract Name: AuraSynthesizer
    Description:
        The AuraSynthesizer is an advanced, decentralized ecosystem featuring dynamic NFTs ("Auras"),
        an oracle-driven resource economy, and autonomous "Alchemist" agents. This contract
        simulates a living digital environment where NFT properties evolve based on real-world
        (or synthetic) data feeds, users can discover and claim rewards for unique attribute
        combinations, and automated agents execute complex strategies. It aims to create a novel,
        gamified interaction layer on the blockchain, pushing the boundaries of NFT utility and
        decentralized automation.

    Core Advanced Concepts:
    1.  Dynamic NFTs (Auras): NFT properties (traits, rarity, visual representation via metadata URI)
        are not static but algorithmically updated based on external environmental data, resources,
        and user interactions (transmutation, evolution). This brings NFTs closer to "living" digital entities.
    2.  Oracle-Driven Reactivity: The entire ecosystem's state, including resource generation
        and Aura evolution, is dynamically influenced by data fed from a trusted oracle, simulating a
        "living" and responsive environment.
    3.  Alchemist Agents (Simulated Autonomy): Users can deploy and program "Alchemist" agents
        that execute multi-step strategies on their behalf, reacting to the dynamic environment
        and managing their Auras and resources autonomously. This concept introduces a form of on-chain
        "AI-like" agency or delegated automation.
    4.  Proof-of-Attribute-Discovery (PoAD): A gamified system where users are rewarded for
        "discovering" Auras that meet specific, complex, and dynamically changing trait conditions.
        This encourages exploration, strategic collection, and interaction within the ecosystem.
    5.  Complex Resource Economy: An ERC1155-based resource system where different resource types
        are generated (influenced by environmental factors), consumed (for evolution/crafting),
        and combined (for synthesis), adding a deep economic layer to the ecosystem.

    Function Summary (27 functions):

    I. Core Infrastructure & Configuration:
    1.  constructor(): Initializes the contract, setting the deployer as owner and defining initial resource types.
    2.  setOracleAddress(address _newOracle): Owner-only function to set the address of the trusted oracle that provides environmental data.
    3.  setBaseMintFee(uint256 _newFee): Owner-only function to set the base fee required for minting a new Aura NFT.
    4.  setFeeRecipient(address _newRecipient): Owner-only function to set the address where collected minting fees are sent.
    5.  withdrawFees(): Owner-only function to withdraw accumulated Ether fees from the contract to the designated fee recipient.

    II. Environmental Data & Oracle Integration:
    6.  updateEnvironmentalData(bytes32 _dataHash, uint256 _dataValue): Oracle-callable function to feed current environmental data
        (e.g., market sentiment, weather patterns, game state) into the system. This data drives dynamism.
    7.  getCurrentEnvironmentalFactor() view: Retrieves the latest environmental factor value that the system is reacting to.

    III. Aura (Dynamic NFT) Management (ERC721):
    8.  mintAura(string calldata _name, string calldata _symbol) payable: Mints a new, basic Aura NFT. Requires a fee and
        automatically generates initial dynamic properties based on the current environmental factor.
    9.  getAuraProperties(uint256 _tokenId) view: Retrieves all current dynamic and static properties of a given Aura NFT.
    10. isAuraTraitLocked(uint256 _tokenId, AuraTraitType _traitType) view: Checks if a specific dynamic trait of an Aura has been permanently locked.
    11. refreshAuraState(uint256 _tokenId): Allows any user to trigger a re-evaluation and update of an Aura's properties
        based on the latest environmental data, ensuring its dynamism (subject to a cooldown).
    12. transmuteAuras(uint256 _tokenId1, uint256 _tokenId2) returns (uint256 newAuraId): Allows an owner to combine two of their
        existing Auras, burning them and minting a new, more evolved Aura with boosted and merged traits.
    13. dissipateAura(uint256 _tokenId): Burns an Aura, removing it from existence, and potentially releasing a fraction of its
        accumulated resources back to the owner as a form of partial recycling.
    14. evolveAura(uint256 _tokenId, uint256 _resourceTypeId, uint256 _amount): Allows an Aura to be "fed" specific resources,
        which can boost its traits or trigger an evolutionary state change, consuming the resources.
    15. lockAuraTrait(uint256 _tokenId, uint256 _traitIndex): Allows an Aura owner to spend resources to permanently "lock" a desired trait,
        making it immune to future environmental influences or evolutionary changes.
    16. getCurrentAuraRarity(uint256 _tokenId) view: Calculates and returns a dynamic rarity score for an Aura,
        based on its current traits, environmental factors, and predefined rarity algorithms.

    IV. Resource (ERC1155) Management:
    17. claimEnvironmentalResource(uint256 _resourceTypeId, uint256 _amount): Allows users to claim resources that are passively
        generated by the ecosystem, influenced by environmental factors.
    18. depositResource(uint256 _resourceTypeId, uint256 _amount): Allows users to deposit their resources into the contract
        (effectively burning them from their wallet and crediting to the contract's internal balance) for various ecosystem interactions.
    19. withdrawResource(uint256 _resourceTypeId, uint256 _amount): Allows users to withdraw their previously deposited resources
        from the contract (crediting them back to their wallet).
    20. craftSynthesisComponent(uint256 _resourceTypeId1, uint256 _resourceTypeId2, uint256 _quantity) returns (uint256 componentId):
        Combines specific base resources (e.g., Essence and Flux) according to a recipe to craft new, specialized `SynthesisComponent` resources.
    21. getAvailableResources(address _user, uint256 _resourceTypeId) view: Retrieves the balance of a specific resource type for a given user.

    V. Alchemist Agent Management:
    22. deployAlchemist(string calldata _name) returns (uint256 alchemistId): Deploys a new "Alchemist" agent profile for the caller,
        assigning it a unique ID and acting as an automated strategy executor.
    23. setAlchemistStrategy(uint256 _alchemistId, AlchemistStrategyType _strategyType, uint256 _param1, uint256 _param2):
        Owner of an Alchemist defines its automated behavior or strategy, setting its goals and parameters.
    24. executeAlchemistAction(uint256 _alchemistId, uint256[] calldata _auraTokenIdsToConsider): Callable by anyone (e.g., keeper networks)
        to trigger an Alchemist to evaluate and perform its defined strategy. The Alchemist then attempts to execute actions
        (like refreshing Aura states or claiming resources) on behalf of its deployer, contingent on prior approvals.
    25. getAlchemistStatus(uint256 _alchemistId) view: Retrieves the current state, active strategy, and last action timestamp of an Alchemist.

    VI. Proof-of-Attribute-Discovery (PoAD) & Gamification:
    26. defineDiscoveryQuest(bytes32 _questId, bytes calldata _traitConditions, uint256 _rewardAmount, uint256 _rewardResourceTypeId):
        Owner-only function to define new "Discovery Quests" which challenge users to find Auras matching specific, complex trait conditions.
    27. claimDiscoveryReward(uint256 _tokenId, bytes32 _questId): Allows a user to claim a reward if their Aura
        currently meets the specific conditions of an active discovery quest. The quest may then become inactive.
    28. getDiscoveryQuestDetails(bytes32 _questId) view: Retrieves the full details of a specific discovery quest, including its conditions and rewards.
*/

contract AuraSynthesizer is ERC721URIStorage, ERC1155, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables & Constants ---

    // NFT Counters
    Counters.Counter private _auraTokenIds;
    Counters.Counter private _alchemistIds;

    // Addresses
    address public oracleAddress;
    address public feeRecipient;

    // Fees
    uint256 public baseAuraMintFee = 0.01 ether; // Example fee

    // Environmental Data
    uint256 public lastEnvironmentalFactor;
    uint256 public lastEnvironmentalUpdateTimestamp;

    // --- Enums & Structs ---

    // Defines the types of dynamic traits an Aura can possess
    enum AuraTraitType {
        ESSENCE_INFLUENCE,
        FLUX_RESONANCE,
        PURITY_LEVEL
    }

    // Stores the dynamic properties of each Aura NFT
    struct AuraProperties {
        string name;
        string symbol;
        uint256 creationTimestamp;
        uint256 lastUpdatedEnvFactor; // The environmental factor value when properties were last updated
        uint256 essenceInfluence;     // 0-100, affects visual and utility
        uint256 fluxResonance;        // 0-100, impacts visual and utility
        uint256 purityLevel;          // 0-100, impacts utility and rarity
        mapping(uint256 => bool) lockedTraits; // AuraTraitType => isLocked, to prevent changes
        uint256 lastTraitUpdateTimestamp; // Cooldown to prevent spamming Aura state refreshes
    }

    // Mapping of Aura ID to its properties
    mapping(uint256 => AuraProperties) public auras;

    // Defines the types of ERC1155 resources in the ecosystem
    enum ResourceTypeId {
        ESSENCE,        // Base resource, influenced by environmental factors
        FLUX,           // Base resource, influenced by environmental factors
        RESONANCE,      // Base resource, influenced by environmental factors
        COMPONENT_A,    // Crafted component
        COMPONENT_B     // Crafted component
    }

    // Defines the types of strategies an Alchemist agent can execute
    enum AlchemistStrategyType {
        NONE,                   // No active strategy
        ACCUMULATE_ESSENCE,     // Focuses on accumulating Essence resource
        TRANSMUTE_IF_HIGH_FLUX, // Tries to transmute Auras if Flux is high (requires owner approval)
        EVOLVE_PURITY,          // Tries to evolve Auras to increase Purity (requires owner approval)
        SEEK_DISCOVERY_QUESTS   // Actively seeks and claims rewards for discovery quests (requires owner approval)
    }

    // Defines the parameters for an Alchemist's active strategy
    struct AlchemistStrategy {
        AlchemistStrategyType strategyType;
        uint256 param1; // Generic parameter 1 (e.g., target resource, min threshold)
        uint256 param2; // Generic parameter 2 (e.g., amount, max threshold)
    }

    // Stores the status and configuration of each Alchemist agent
    struct AlchemistStatus {
        string name;
        address deployer; // The address that deployed this Alchemist
        AlchemistStrategy activeStrategy;
        uint256 lastActionTimestamp; // Cooldown for Alchemist actions
    }

    // Mapping of Alchemist ID to its status
    mapping(uint256 => AlchemistStatus) public alchemists;

    // Defines the structure of a Discovery Quest
    struct DiscoveryQuest {
        bytes traitConditions; // Encoded conditions an Aura must meet (e.g., abi.encode(AuraTraitType, minVal, maxVal))
        uint256 rewardAmount;
        uint256 rewardResourceTypeId;
        bool active; // True if the quest can still be claimed
    }

    // Mapping of Quest ID (bytes32 hash) to DiscoveryQuest details
    mapping(bytes32 => DiscoveryQuest) public discoveryQuests;

    // --- Events ---

    event OracleAddressSet(address indexed newOracle);
    event EnvironmentalDataUpdated(bytes32 indexed dataHash, uint256 dataValue, uint256 timestamp);
    event AuraMinted(uint256 indexed tokenId, address indexed owner, string name, string symbol);
    event AuraPropertiesUpdated(uint256 indexed tokenId, uint256 essenceInfluence, uint256 fluxResonance, uint256 purityLevel);
    event AurasTransmuted(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newAuraId);
    event AuraDissipated(uint256 indexed tokenId, address indexed owner, uint256 releasedResources);
    event AuraEvolved(uint256 indexed tokenId, uint256 resourceTypeId, uint256 amount);
    event AuraTraitLocked(uint256 indexed tokenId, AuraTraitType traitType);
    event ResourceClaimed(address indexed user, uint256 resourceTypeId, uint256 amount);
    event ResourceDeposited(address indexed user, uint256 resourceTypeId, uint256 amount);
    event ResourceWithdrawn(address indexed user, uint256 resourceTypeId, uint256 amount);
    event ComponentCrafted(address indexed crafter, uint256 indexed componentId, uint256 quantity);
    event AlchemistDeployed(uint256 indexed alchemistId, address indexed deployer, string name);
    event AlchemistStrategySet(uint256 indexed alchemistId, AlchemistStrategyType strategyType);
    event AlchemistActionExecuted(uint256 indexed alchemistId, address indexed executor);
    event DiscoveryQuestDefined(bytes32 indexed questId, uint256 rewardAmount, uint256 rewardResourceTypeId);
    event DiscoveryRewardClaimed(uint256 indexed tokenId, bytes32 indexed questId, address indexed claimant);
    event FeeRecipientSet(address indexed newRecipient);
    event BaseMintFeeSet(uint256 newFee);
    event FeesWithdrawn(uint256 amount);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AuraSynthesizer: Caller is not the oracle");
        _;
    }

    // Checks if the caller is the owner or an approved operator for the specific Aura
    modifier onlyAuraOwnerOrApproved(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AuraSynthesizer: Caller is not owner nor approved for Aura");
        _;
    }

    // Checks if the caller is the deployer of the Alchemist
    modifier onlyAlchemistDeployer(uint256 _alchemistId) {
        require(alchemists[_alchemistId].deployer == msg.sender, "AuraSynthesizer: Caller is not alchemist deployer");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle) ERC721("AuraSynthesizer Aura", "AURA") ERC1155("https://aurasynthesizer.com/api/erc1155/{id}.json") Ownable(msg.sender) {
        require(_initialOracle != address(0), "AuraSynthesizer: Initial oracle address cannot be zero");
        oracleAddress = _initialOracle;
        feeRecipient = msg.sender; // Default fee recipient is the owner
        // ERC1155 URI is set by the constructor of ERC1155
    }

    // --- I. Core Infrastructure & Configuration ---

    /// @notice Sets the address of the trusted oracle. Only owner can call.
    /// @param _newOracle The new address for the oracle.
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AuraSynthesizer: Oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /// @notice Sets the base fee for minting new Auras. Only owner can call.
    /// @param _newFee The new base minting fee in wei.
    function setBaseMintFee(uint256 _newFee) public onlyOwner {
        baseAuraMintFee = _newFee;
        emit BaseMintFeeSet(_newFee);
    }

    /// @notice Sets the address that receives collected fees. Only owner can call.
    /// @param _newRecipient The new address for the fee recipient.
    function setFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "AuraSynthesizer: Fee recipient cannot be zero");
        feeRecipient = _newRecipient;
        emit FeeRecipientSet(_newRecipient);
    }

    /// @notice Allows the owner to withdraw accumulated fees (ETH) to the feeRecipient.
    function withdrawFees() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "AuraSynthesizer: No fees to withdraw");
        (bool success, ) = feeRecipient.call{value: contractBalance}("");
        require(success, "AuraSynthesizer: Fee withdrawal failed");
        emit FeesWithdrawn(contractBalance);
    }

    // --- II. Environmental Data & Oracle Integration ---

    /// @notice Oracle-callable function to feed current environmental data into the system.
    ///         This data influences Aura properties and resource generation.
    /// @param _dataHash A hash representing the unique context or timestamp of the data.
    /// @param _dataValue The numerical value of the environmental factor (e.g., 0-1000).
    function updateEnvironmentalData(bytes32 _dataHash, uint256 _dataValue) public onlyOracle {
        // Example: Environmental factor clamped to a reasonable range
        require(_dataValue <= 1000, "AuraSynthesizer: Environmental factor value too high (max 1000)");
        lastEnvironmentalFactor = _dataValue;
        lastEnvironmentalUpdateTimestamp = block.timestamp;
        emit EnvironmentalDataUpdated(_dataHash, _dataValue, block.timestamp);
    }

    /// @notice Retrieves the latest environmental factor value.
    /// @return The current environmental factor.
    function getCurrentEnvironmentalFactor() public view returns (uint256) {
        return lastEnvironmentalFactor;
    }

    // --- III. Aura (Dynamic NFT) Management (ERC721) ---

    /// @notice Mints a new, basic Aura NFT. Requires a fee and automatically generates initial dynamic properties.
    /// @param _name The name of the Aura.
    /// @param _symbol The symbol of the Aura.
    /// @return tokenId The ID of the newly minted Aura.
    function mintAura(string calldata _name, string calldata _symbol) public payable returns (uint256 tokenId) {
        require(msg.value >= baseAuraMintFee, "AuraSynthesizer: Insufficient minting fee");

        _auraTokenIds.increment();
        tokenId = _auraTokenIds.current();

        _mint(msg.sender, tokenId);
        // The tokenURI will dynamically resolve based on current properties
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI(), tokenId.toString())));

        AuraProperties storage newAura = auras[tokenId];
        newAura.name = _name;
        newAura.symbol = _symbol;
        newAura.creationTimestamp = block.timestamp;
        newAura.lastUpdatedEnvFactor = lastEnvironmentalFactor;
        
        // Initial properties based on a simple pseudo-random generation using environmental factor
        newAura.essenceInfluence = (lastEnvironmentalFactor % 100) + 1; // 1-100
        newAura.fluxResonance = ((lastEnvironmentalFactor * 7) % 100) + 1; // 1-100
        newAura.purityLevel = ((lastEnvironmentalFactor * 3) % 100) + 1; // 1-100
        newAura.lastTraitUpdateTimestamp = block.timestamp;


        emit AuraMinted(tokenId, msg.sender, _name, _symbol);
        emit AuraPropertiesUpdated(tokenId, newAura.essenceInfluence, newAura.fluxResonance, newAura.purityLevel);
    }

    /// @notice Retrieves all current dynamic properties of a given Aura.
    /// @param _tokenId The ID of the Aura.
    /// @return AuraProperties struct containing its current state.
    function getAuraProperties(uint256 _tokenId) public view returns (AuraProperties memory) {
        require(_exists(_tokenId), "AuraSynthesizer: Aura does not exist");
        AuraProperties storage ap = auras[_tokenId];
        // Return a memory copy. Note: mappings within structs cannot be returned directly.
        // `isAuraTraitLocked` function is provided for individual trait lock checks.
        return AuraProperties({
            name: ap.name,
            symbol: ap.symbol,
            creationTimestamp: ap.creationTimestamp,
            lastUpdatedEnvFactor: ap.lastUpdatedEnvFactor,
            essenceInfluence: ap.essenceInfluence,
            fluxResonance: ap.fluxResonance,
            purityLevel: ap.purityLevel,
            lastTraitUpdateTimestamp: ap.lastTraitUpdateTimestamp,
            lockedTraits: ap.lockedTraits // This will just return the memory pointer to the mapping, not the actual values.
                                         // For full external readability, individual getters for `lockedTraits` are needed.
        });
    }
    
    /// @notice Helper to check if a specific trait is locked (for external access)
    /// @param _tokenId The ID of the Aura.
    /// @param _traitType The type of trait to check (from AuraTraitType enum).
    /// @return True if the trait is locked, false otherwise.
    function isAuraTraitLocked(uint256 _tokenId, AuraTraitType _traitType) public view returns (bool) {
        require(_exists(_tokenId), "AuraSynthesizer: Aura does not exist");
        return auras[_tokenId].lockedTraits[uint256(_traitType)];
    }


    /// @notice Allows any user to trigger a re-evaluation and update of an Aura's properties
    ///         based on the latest environmental data, ensuring dynamism.
    ///         There's a cooldown to prevent spam.
    /// @param _tokenId The ID of the Aura to refresh.
    function refreshAuraState(uint256 _tokenId) public {
        require(_exists(_tokenId), "AuraSynthesizer: Aura does not exist");
        AuraProperties storage aura = auras[_tokenId];
        require(block.timestamp >= aura.lastTraitUpdateTimestamp + 1 hours, "AuraSynthesizer: Aura state can only be refreshed once per hour"); // Cooldown

        if (aura.lastUpdatedEnvFactor != lastEnvironmentalFactor) {
            _applyEnvironmentalInfluence(_tokenId); // Apply environmental changes
            aura.lastUpdatedEnvFactor = lastEnvironmentalFactor;
            aura.lastTraitUpdateTimestamp = block.timestamp;
            emit AuraPropertiesUpdated(
                _tokenId,
                aura.essenceInfluence,
                aura.fluxResonance,
                aura.purityLevel
            );
        }
    }

    /// @notice Combines two existing Auras owned by the caller, burning them and minting a new, evolved Aura.
    ///         The new Aura inherits combined properties and receives a boost.
    /// @param _tokenId1 The ID of the first Aura.
    /// @param _tokenId2 The ID of the second Aura.
    /// @return newAuraId The ID of the newly minted Aura.
    function transmuteAuras(uint256 _tokenId1, uint256 _tokenId2) public onlyAuraOwnerOrApproved(_tokenId1) onlyAuraOwnerOrApproved(_tokenId2) returns (uint256 newAuraId) {
        require(_tokenId1 != _tokenId2, "AuraSynthesizer: Cannot transmute an Aura with itself");
        
        // Ensure both Auras are owned by the same user or approved by them
        address owner = ownerOf(_tokenId1);
        require(ownerOf(_tokenId2) == owner, "AuraSynthesizer: Auras must be owned or approved by the same address");

        AuraProperties storage aura1 = auras[_tokenId1];
        AuraProperties storage aura2 = auras[_tokenId2];

        // Perform transmutation logic: average traits, apply boost, etc.
        uint256 newEssence = (aura1.essenceInfluence + aura2.essenceInfluence) / 2;
        uint256 newFlux = (aura1.fluxResonance + aura2.fluxResonance) / 2;
        uint256 newPurity = (aura1.purityLevel + aura2.purityLevel) / 2;

        // Apply a transmutation boost, capped at 100 for each trait
        newEssence = Math.min(newEssence + 10, 100);
        newFlux = Math.min(newFlux + 10, 100);
        newPurity = Math.min(newPurity + 10, 100);

        // Burn original Auras
        _burn(_tokenId1);
        _burn(_tokenId2);

        // Mint new Aura
        _auraTokenIds.increment();
        newAuraId = _auraTokenIds.current();
        _mint(owner, newAuraId); // Mint to the original owner
        _setTokenURI(newAuraId, string(abi.encodePacked(_baseURI(), newAuraId.toString())));

        AuraProperties storage newAura = auras[newAuraId];
        newAura.name = string(abi.encodePacked(aura1.name, "-", aura2.name)); // Example naming
        newAura.symbol = string(abi.encodePacked(aura1.symbol, aura2.symbol));
        newAura.creationTimestamp = block.timestamp;
        newAura.lastUpdatedEnvFactor = lastEnvironmentalFactor;
        newAura.essenceInfluence = newEssence;
        newAura.fluxResonance = newFlux;
        newAura.purityLevel = newPurity;
        newAura.lastTraitUpdateTimestamp = block.timestamp;

        emit AurasTransmuted(_tokenId1, _tokenId2, newAuraId);
        emit AuraPropertiesUpdated(newAuraId, newEssence, newFlux, newPurity);
    }

    /// @notice Burns an Aura, potentially releasing a fraction of its accumulated resources.
    /// @param _tokenId The ID of the Aura to dissipate.
    function dissipateAura(uint256 _tokenId) public onlyAuraOwnerOrApproved(_tokenId) {
        AuraProperties storage aura = auras[_tokenId];
        address owner = ownerOf(_tokenId);

        // Example: release resources based on purity level
        uint256 releasedEssence = aura.purityLevel * 10; // Example calculation
        if (releasedEssence > 0) {
            _mint(owner, uint256(ResourceTypeId.ESSENCE), releasedEssence, "");
            emit ResourceClaimed(owner, uint256(ResourceTypeId.ESSENCE), releasedEssence);
        }

        _burn(_tokenId);
        delete auras[_tokenId]; // Remove from mapping

        emit AuraDissipated(_tokenId, owner, releasedEssence);
    }

    /// @notice Allows an Aura to be "fed" resources, potentially boosting specific traits or triggering an evolutionary state change.
    /// @param _tokenId The ID of the Aura to evolve.
    /// @param _resourceTypeId The type of resource to consume.
    /// @param _amount The amount of resource to consume.
    function evolveAura(uint256 _tokenId, uint256 _resourceTypeId, uint256 _amount) public onlyAuraOwnerOrApproved(_tokenId) {
        require(_amount > 0, "AuraSynthesizer: Amount must be greater than zero");
        
        address owner = ownerOf(_tokenId);
        require(balanceOf(owner, _resourceTypeId) >= _amount, "AuraSynthesizer: Insufficient resources");

        AuraProperties storage aura = auras[_tokenId];

        // Consume resources from the Aura's owner
        _burnBatch(owner, [_resourceTypeId], [_amount]);

        // Apply evolution logic based on resource type
        if (_resourceTypeId == uint256(ResourceTypeId.ESSENCE)) {
            if (!aura.lockedTraits[uint256(AuraTraitType.ESSENCE_INFLUENCE)]) {
                aura.essenceInfluence = Math.min(aura.essenceInfluence + (_amount / 10), 100);
            }
        } else if (_resourceTypeId == uint256(ResourceTypeId.FLUX)) {
            if (!aura.lockedTraits[uint256(AuraTraitType.FLUX_RESONANCE)]) {
                aura.fluxResonance = Math.min(aura.fluxResonance + (_amount / 10), 100);
            }
        } else if (_resourceTypeId == uint256(ResourceTypeId.RESONANCE)) {
            if (!aura.lockedTraits[uint256(AuraTraitType.PURITY_LEVEL)]) {
                aura.purityLevel = Math.min(aura.purityLevel + (_amount / 10), 100);
            }
        } else {
            revert("AuraSynthesizer: Invalid resource type for evolution");
        }

        aura.lastTraitUpdateTimestamp = block.timestamp;
        emit AuraEvolved(_tokenId, _resourceTypeId, _amount);
        emit AuraPropertiesUpdated(
            _tokenId,
            aura.essenceInfluence,
            aura.fluxResonance,
            aura.purityLevel
        );
    }

    /// @notice Allows an Aura owner to spend resources to permanently "lock" a desired trait,
    ///         preventing future environmental factors or evolutions from changing it.
    /// @param _tokenId The ID of the Aura.
    /// @param _traitIndex The index of the trait to lock (from AuraTraitType enum).
    function lockAuraTrait(uint256 _tokenId, uint256 _traitIndex) public onlyAuraOwnerOrApproved(_tokenId) {
        require(_traitIndex < 3, "AuraSynthesizer: Invalid trait index"); // Covers ESSENCE, FLUX, PURITY
        AuraProperties storage aura = auras[_tokenId];
        require(!aura.lockedTraits[_traitIndex], "AuraSynthesizer: Trait is already locked");

        address owner = ownerOf(_tokenId);

        // Example: require specific resources to lock a trait
        uint256 lockFeeFlux = 50;
        uint256 lockFeeResonance = 50;
        
        require(balanceOf(owner, uint256(ResourceTypeId.FLUX)) >= lockFeeFlux, "AuraSynthesizer: Insufficient Flux to lock trait");
        require(balanceOf(owner, uint256(ResourceTypeId.RESONANCE)) >= lockFeeResonance, "AuraSynthesizer: Insufficient Resonance to lock trait");

        _burnBatch(owner, [uint256(ResourceTypeId.FLUX), uint256(ResourceTypeId.RESONANCE)], [lockFeeFlux, lockFeeResonance]);
        aura.lockedTraits[_traitIndex] = true;

        emit AuraTraitLocked(_tokenId, AuraTraitType(_traitIndex));
    }
    
    /// @notice Calculates and returns a dynamic rarity score for an Aura based on its current traits and the environmental factors.
    /// @param _tokenId The ID of the Aura.
    /// @return rarityScore The calculated rarity score (higher is rarer).
    function getCurrentAuraRarity(uint256 _tokenId) public view returns (uint256 rarityScore) {
        require(_exists(_tokenId), "AuraSynthesizer: Aura does not exist");
        AuraProperties storage aura = auras[_tokenId];

        // Simple rarity calculation (can be much more complex in a real system)
        // High values are generally rarer, being close to 0 or 100 can add rarity.
        // Influence of environmental factor (e.g., matching a high/low point in the environment)
        uint256 envImpactNormalized = lastEnvironmentalFactor % 100; // 0-99

        rarityScore = (aura.essenceInfluence * 3) +
                      (aura.fluxResonance * 2) +
                      (aura.purityLevel * 5);

        // Add bonus for traits being at extremes (very high or very low)
        if (aura.essenceInfluence > 90 || aura.essenceInfluence < 10) rarityScore += 50;
        if (aura.fluxResonance > 90 || aura.fluxResonance < 10) rarityScore += 50;
        if (aura.purityLevel > 90 || aura.purityLevel < 10) rarityScore += 100;

        // Add bonus if Purity level aligns or contrasts significantly with the current environmental factor
        if (aura.purityLevel > envImpactNormalized + 20) rarityScore += 75;
        if (aura.purityLevel < envImpactNormalized - 20) rarityScore += 75;

        return rarityScore;
    }


    // --- IV. Resource (ERC1155) Management ---

    /// @notice Allows users to claim resources that are passively generated by the system based on environmental factors.
    ///         A more sophisticated system would track user claim history to prevent spam.
    /// @param _resourceTypeId The type of resource to claim.
    /// @param _amount The amount of resource to claim.
    function claimEnvironmentalResource(uint256 _resourceTypeId, uint256 _amount) public {
        require(_amount > 0, "AuraSynthesizer: Amount must be greater than zero");
        require(_resourceTypeId >= uint256(ResourceTypeId.ESSENCE) && _resourceTypeId <= uint256(ResourceTypeId.RESONANCE),
                "AuraSynthesizer: Only base resources (Essence, Flux, Resonance) can be claimed environmentally");

        // Example: Generation rate based on environmental factor. This is a simplified model.
        uint256 generationRate = (lastEnvironmentalFactor % 50) + 1; // 1-50 units per global "tick"
        require(_amount <= generationRate * 10, "AuraSynthesizer: Claim amount exceeds environmental generation capacity"); // Max claim limit

        _mint(msg.sender, _resourceTypeId, _amount, "");
        emit ResourceClaimed(msg.sender, _resourceTypeId, _amount);
    }

    /// @notice Allows users to deposit their resources into the contract for various interactions.
    ///         This means tokens are burnt from the user and their balance is tracked internally.
    /// @param _resourceTypeId The type of resource to deposit.
    /// @param _amount The amount of resource to deposit.
    function depositResource(uint256 _resourceTypeId, uint256 _amount) public {
        require(_amount > 0, "AuraSynthesizer: Amount must be greater than zero");
        require(balanceOf(msg.sender, _resourceTypeId) >= _amount, "AuraSynthesizer: Insufficient resources to deposit");
        
        // ERC1155 `safeTransferFrom` implies the caller is the `operator` (i.e., this contract if approved).
        // For simplicity, we directly _burn_ from the sender and _mint_ to the contract's internal tracking
        // This is a common pattern when a contract needs to "hold" resources.
        _burnBatch(msg.sender, [_resourceTypeId], [_amount]); // Burn from user
        _mint(address(this), _resourceTypeId, _amount, ""); // Mint to contract's internal balance

        emit ResourceDeposited(msg.sender, _resourceTypeId, _amount);
    }

    /// @notice Allows users to withdraw their deposited resources.
    ///         This means tokens are burnt from the contract's internal balance and minted back to the user.
    /// @param _resourceTypeId The type of resource to withdraw.
    /// @param _amount The amount of resource to withdraw.
    function withdrawResource(uint256 _resourceTypeId, uint256 _amount) public {
        require(_amount > 0, "AuraSynthesizer: Amount must be greater than zero");
        require(balanceOf(address(this), _resourceTypeId) >= _amount, "AuraSynthesizer: Insufficient resources in contract to withdraw");

        _burnBatch(address(this), [_resourceTypeId], [_amount]); // Burn from contract's balance
        _mint(msg.sender, _resourceTypeId, _amount, ""); // Mint to user

        emit ResourceWithdrawn(msg.sender, _resourceTypeId, _amount);
    }

    /// @notice Combines specific resources to craft a `SynthesisComponent` (a new ERC1155 type), requiring a recipe.
    /// @param _resourceTypeId1 The ID of the first resource type.
    /// @param _resourceTypeId2 The ID of the second resource type.
    /// @param _quantity The quantity of components to craft.
    /// @return componentId The ID of the crafted SynthesisComponent.
    function craftSynthesisComponent(uint256 _resourceTypeId1, uint256 _resourceTypeId2, uint256 _quantity) public returns (uint256 componentId) {
        require(_quantity > 0, "AuraSynthesizer: Quantity must be greater than zero");
        // Example recipe: 10 Essence + 10 Flux = 1 Component_A
        require(_resourceTypeId1 == uint256(ResourceTypeId.ESSENCE) && _resourceTypeId2 == uint256(ResourceTypeId.FLUX),
                "AuraSynthesizer: Invalid resource combination for crafting (requires Essence & Flux)");

        uint256 essenceCost = 10 * _quantity;
        uint256 fluxCost = 10 * _quantity;

        require(balanceOf(msg.sender, uint256(ResourceTypeId.ESSENCE)) >= essenceCost, "AuraSynthesizer: Insufficient Essence");
        require(balanceOf(msg.sender, uint256(ResourceTypeId.FLUX)) >= fluxCost, "AuraSynthesizer: Insufficient Flux");

        _burnBatch(msg.sender, [uint256(ResourceTypeId.ESSENCE), uint256(ResourceTypeId.FLUX)], [essenceCost, fluxCost]);
        
        componentId = uint256(ResourceTypeId.COMPONENT_A); // For this specific recipe

        _mint(msg.sender, componentId, _quantity, "");
        emit ComponentCrafted(msg.sender, componentId, _quantity);
    }

    /// @notice Checks a user's balance of a specific resource.
    /// @param _user The address of the user.
    /// @param _resourceTypeId The ID of the resource type.
    /// @return The balance of the specified resource for the user.
    function getAvailableResources(address _user, uint256 _resourceTypeId) public view returns (uint256) {
        return balanceOf(_user, _resourceTypeId);
    }

    // --- V. Alchemist Agent Management ---

    /// @notice Deploys a new "Alchemist" agent profile for the caller, identified by a unique ID.
    /// @param _name The name of the Alchemist.
    /// @return alchemistId The ID of the newly deployed Alchemist.
    function deployAlchemist(string calldata _name) public returns (uint256 alchemistId) {
        _alchemistIds.increment();
        alchemistId = _alchemistIds.current();

        alchemists[alchemistId].name = _name;
        alchemists[alchemistId].deployer = msg.sender;
        alchemists[alchemistId].activeStrategy.strategyType = AlchemistStrategyType.NONE; // Default to no strategy

        emit AlchemistDeployed(alchemistId, msg.sender, _name);
    }

    /// @notice Owner of an Alchemist defines its automated behavior or strategy.
    /// @param _alchemistId The ID of the Alchemist.
    /// @param _strategyType The type of strategy to set.
    /// @param _param1 Generic parameter 1 for the strategy.
    /// @param _param2 Generic parameter 2 for the strategy.
    function setAlchemistStrategy(
        uint256 _alchemistId,
        AlchemistStrategyType _strategyType,
        uint256 _param1,
        uint256 _param2
    ) public onlyAlchemistDeployer(_alchemistId) {
        AlchemistStatus storage alchemist = alchemists[_alchemistId];
        alchemist.activeStrategy = AlchemistStrategy({
            strategyType: _strategyType,
            param1: _param1,
            param2: _param2
        });
        emit AlchemistStrategySet(_alchemistId, _strategyType);
    }

    /// @notice Callable by anyone (or keeper networks) to trigger an Alchemist to perform its defined strategy
    ///         on its owner's Auras, based on current environmental conditions.
    ///         For actions requiring Aura/resource transfers, the Alchemist's deployer must have
    ///         previously set `setApprovalForAll(address(this), true)` for their ERC721 Auras
    ///         and possibly for their ERC1155 resources (if this contract were to operate on owned ERC1155s).
    /// @param _alchemistId The ID of the Alchemist to execute.
    /// @param _auraTokenIdsToConsider An array of Aura IDs owned by the Alchemist's deployer to potentially act upon.
    function executeAlchemistAction(uint256 _alchemistId, uint256[] calldata _auraTokenIdsToConsider) public {
        AlchemistStatus storage alchemist = alchemists[_alchemistId];
        require(alchemist.deployer != address(0), "AuraSynthesizer: Alchemist does not exist");
        require(alchemist.activeStrategy.strategyType != AlchemistStrategyType.NONE, "AuraSynthesizer: Alchemist has no active strategy");
        // Cooldown for action to prevent excessive gas usage
        require(block.timestamp >= alchemist.lastActionTimestamp + 10 minutes, "AuraSynthesizer: Alchemist cooldown period not over"); 

        address alchemistOwner = alchemist.deployer;
        AlchemistStrategy memory strategy = alchemist.activeStrategy;

        // Implement Alchemist logic based on strategy and current environmental factor
        if (strategy.strategyType == AlchemistStrategyType.ACCUMULATE_ESSENCE) {
            // Example: If environmental conditions are favorable for Essence and owner has less than param1
            if (lastEnvironmentalFactor > 500 && balanceOf(alchemistOwner, uint256(ResourceTypeId.ESSENCE)) < strategy.param1) {
                // The Alchemist (via this contract) attempts to claim resources for its owner
                // We directly mint to the owner here. A more complex system might use an allowance.
                _mint(alchemistOwner, uint256(ResourceTypeId.ESSENCE), strategy.param2, "");
                emit ResourceClaimed(alchemistOwner, uint256(ResourceTypeId.ESSENCE), strategy.param2);
            }
        } else if (strategy.strategyType == AlchemistStrategyType.EVOLVE_PURITY) {
            // Example: Alchemist triggers Aura refreshes for low-purity Auras
            // param1: minPurityThreshold, param2: amountOfResonance (not used in this simplified refresh)
            for (uint256 tokenId : _auraTokenIdsToConsider) {
                // The contract needs approval from `alchemistOwner` to operate on `tokenId`
                if (_isApprovedOrOwner(alchemistOwner, tokenId)) {
                    // Refresh Aura state if purity is low and cooldown allows
                    if (auras[tokenId].purityLevel < strategy.param1 && block.timestamp >= auras[tokenId].lastTraitUpdateTimestamp + 1 hours) {
                        _applyEnvironmentalInfluence(tokenId); // Update Aura traits
                        auras[tokenId].lastUpdatedEnvFactor = lastEnvironmentalFactor;
                        auras[tokenId].lastTraitUpdateTimestamp = block.timestamp;
                        emit AuraPropertiesUpdated(tokenId, auras[tokenId].essenceInfluence, auras[tokenId].fluxResonance, auras[tokenId].purityLevel);
                    }
                }
            }
        } else if (strategy.strategyType == AlchemistStrategyType.SEEK_DISCOVERY_QUESTS) {
            // Example: Alchemist tries to claim any available discovery quest for a matching Aura
            for (uint256 tokenId : _auraTokenIdsToConsider) {
                if (_isApprovedOrOwner(alchemistOwner, tokenId)) {
                    // Iterate through active quests (simplified; could optimize with specific quest IDs)
                    bytes32 questHash = keccak256(abi.encode(AuraTraitType.PURITY_LEVEL, 80, 100)); // Example quest condition hash
                    if (discoveryQuests[questHash].active && _checkAuraConditions(tokenId, discoveryQuests[questHash].traitConditions)) {
                        // Alchemist claims the reward on behalf of its owner
                        _mint(alchemistOwner, discoveryQuests[questHash].rewardResourceTypeId, discoveryQuests[questHash].rewardAmount, "");
                        discoveryQuests[questHash].active = false; // Mark quest as completed
                        emit DiscoveryRewardClaimed(tokenId, questHash, alchemistOwner);
                        break; // Claim one quest per execution for simplicity
                    }
                }
            }
        }
        // NOTE: Strategies like TRANSMUTE_IF_HIGH_FLUX are more complex due to requiring two NFTs and `_burn` operations.
        // For truly autonomous agents, the owner must `setApprovalForAll(address(this), true)` for ERC721 Auras.
        // This allows the `AuraSynthesizer` contract itself to perform `_burn` and `_mint` on behalf of the owner.

        alchemist.lastActionTimestamp = block.timestamp;
        emit AlchemistActionExecuted(_alchemistId, msg.sender);
    }

    /// @notice Retrieves the current state, strategy, and last action of an Alchemist.
    /// @param _alchemistId The ID of the Alchemist.
    /// @return AlchemistStatus struct containing its current state.
    function getAlchemistStatus(uint256 _alchemistId) public view returns (AlchemistStatus memory) {
        require(alchemists[_alchemistId].deployer != address(0), "AuraSynthesizer: Alchemist does not exist");
        return alchemists[_alchemistId];
    }

    // --- VI. Proof-of-Attribute-Discovery (PoAD) & Gamification ---

    /// @notice Owner-only function to define new discovery quests (e.g., "Find an Aura with specific traits").
    /// @param _questId A unique identifier for the quest (e.g., hash of conditions to ensure uniqueness).
    /// @param _traitConditions Encoded bytes representing the conditions for discovery (e.g., abi.encode(AuraTraitType.PURITY_LEVEL, 70, 100)).
    /// @param _rewardAmount The amount of reward for completing the quest.
    /// @param _rewardResourceTypeId The type of resource awarded.
    function defineDiscoveryQuest(
        bytes32 _questId,
        bytes calldata _traitConditions,
        uint256 _rewardAmount,
        uint256 _rewardResourceTypeId
    ) public onlyOwner {
        require(_rewardAmount > 0, "AuraSynthesizer: Reward amount must be greater than zero");
        require(_rewardResourceTypeId >= uint256(ResourceTypeId.ESSENCE) && _rewardResourceTypeId <= uint256(ResourceTypeId.COMPONENT_B),
                "AuraSynthesizer: Invalid reward resource type");
        require(!discoveryQuests[_questId].active, "AuraSynthesizer: Quest with this ID is already active");

        discoveryQuests[_questId] = DiscoveryQuest({
            traitConditions: _traitConditions,
            rewardAmount: _rewardAmount,
            rewardResourceTypeId: _rewardResourceTypeId,
            active: true
        });

        emit DiscoveryQuestDefined(_questId, _rewardAmount, _rewardResourceTypeId);
    }

    /// @notice User claims a reward if their Aura currently meets the conditions of a defined quest.
    ///         The caller must be the owner or an approved operator of the Aura.
    /// @param _tokenId The ID of the Aura.
    /// @param _questId The ID of the quest.
    function claimDiscoveryReward(uint256 _tokenId, bytes32 _questId) public onlyAuraOwnerOrApproved(_tokenId) {
        DiscoveryQuest storage quest = discoveryQuests[_questId];
        require(quest.active, "AuraSynthesizer: Quest is not active or has been claimed");
        
        // Check if Aura meets conditions
        require(_checkAuraConditions(_tokenId, quest.traitConditions), "AuraSynthesizer: Aura does not meet quest conditions");

        // Reward the user (owner of the Aura)
        _mint(ownerOf(_tokenId), quest.rewardResourceTypeId, quest.rewardAmount, "");
        quest.active = false; // Mark quest as claimed (or implement cooldown/multiple claims logic)

        emit DiscoveryRewardClaimed(_tokenId, _questId, ownerOf(_tokenId));
    }

    /// @notice Retrieves details of a specific discovery quest.
    /// @param _questId The ID of the quest.
    /// @return _traitConditions Encoded bytes of quest conditions.
    /// @return _rewardAmount The reward amount.
    /// @return _rewardResourceTypeId The reward resource type ID.
    /// @return _active Is the quest currently active.
    function getDiscoveryQuestDetails(bytes32 _questId) public view returns (bytes memory _traitConditions, uint256 _rewardAmount, uint256 _rewardResourceTypeId, bool _active) {
        DiscoveryQuest storage quest = discoveryQuests[_questId];
        return (quest.traitConditions, quest.rewardAmount, quest.rewardResourceTypeId, quest.active);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to apply environmental influence on an Aura's traits.
    ///      Only affects traits that are not locked.
    /// @param _tokenId The ID of the Aura.
    function _applyEnvironmentalInfluence(uint256 _tokenId) internal {
        AuraProperties storage aura = auras[_tokenId];
        
        uint256 envFactor = lastEnvironmentalFactor; // 0-1000

        // Example: Environmental factor dynamically shifts trait values, ensuring they remain 1-100
        if (!aura.lockedTraits[uint256(AuraTraitType.ESSENCE_INFLUENCE)]) {
            // Low envFactor might increase Essence influence
            aura.essenceInfluence = Math.max(1, (aura.essenceInfluence * (1000 - envFactor) / 1000 + (envFactor / 20)));
            aura.essenceInfluence = Math.min(aura.essenceInfluence, 100);
        }
        if (!aura.lockedTraits[uint256(AuraTraitType.FLUX_RESONANCE)]) {
            // High envFactor might increase Flux resonance
            aura.fluxResonance = Math.max(1, (aura.fluxResonance * envFactor / 1000 + (1000 - envFactor) / 20));
            aura.fluxResonance = Math.min(aura.fluxResonance, 100);
        }
        if (!aura.lockedTraits[uint256(AuraTraitType.PURITY_LEVEL)]) {
            // Purity might oscillate or gravitate towards an average, also influenced by current value
            uint256 delta = (envFactor % 20) - 10; // -10 to +9 change
            aura.purityLevel = Math.max(1, aura.purityLevel + delta);
            aura.purityLevel = Math.min(aura.purityLevel, 100);
        }
        aura.lastTraitUpdateTimestamp = block.timestamp;
    }

    /// @dev Internal function to check if an Aura meets specific conditions encoded in bytes.
    ///      Current implementation expects `abi.encode(AuraTraitType, minVal, maxVal)`.
    ///      A more robust system would handle more complex condition sets.
    /// @param _tokenId The ID of the Aura.
    /// @param _conditions Encoded bytes representing the conditions.
    /// @return True if the Aura meets conditions, false otherwise.
    function _checkAuraConditions(uint256 _tokenId, bytes memory _conditions) internal view returns (bool) {
        AuraProperties storage aura = auras[_tokenId];
        
        // Example condition decoding: abi.encode(AuraTraitType.PURITY_LEVEL, minVal, maxVal)
        // A more robust system would use a dedicated ABI decoder for complex structs/arrays
        (uint256 traitType, uint256 minVal, uint256 maxVal) = abi.decode(_conditions, (uint256, uint256, uint256));

        if (traitType == uint256(AuraTraitType.ESSENCE_INFLUENCE)) {
            return aura.essenceInfluence >= minVal && aura.essenceInfluence <= maxVal;
        } else if (traitType == uint256(AuraTraitType.FLUX_RESONANCE)) {
            return aura.fluxResonance >= minVal && aura.fluxResonance <= maxVal;
        } else if (traitType == uint256(AuraTraitType.PURITY_LEVEL)) {
            return aura.purityLevel >= minVal && aura.purityLevel <= maxVal;
        }
        return false; // Unknown trait type or invalid conditions
    }

    // --- ERC721 Overrides ---
    // Base URI for Aura NFTs, dynamically resolved by an off-chain metadata service
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return "https://aurasynthesizer.com/api/aura/";
    }

    // Generates the full token URI for an Aura NFT, pointing to an API endpoint
    // that fetches and serves dynamic JSON metadata based on the Aura's current on-chain state.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    // --- ERC1155 Overrides ---
    // The base URI for ERC1155 resources is set in the constructor.

    // Required by ERC1155 for contracts to receive tokens.
    // In this design, users deposit/withdraw by burning/minting, not direct transfers to the contract.
    // This function is present for full ERC1155 standard compliance, even if not directly used for incoming transfers.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // --- Utility Library ---
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }

    // Fallback function to receive Ether for fees
    receive() external payable {}
}

```