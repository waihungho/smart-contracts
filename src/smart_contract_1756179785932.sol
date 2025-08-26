Here is a Solidity smart contract for an **Evolving Sentient NFT Core**, dubbed `ChronoMindCore`. This contract goes beyond standard NFTs by implementing dynamic traits, on-chain memory, oracle-driven environmental influences, owner-driven nurturing, and a unique replication mechanism. It also incorporates a DAO-lite governance model for community-driven evolution paths.

---

### ChronoMindCore: Outline and Function Summary

**Contract Name:** `ChronoMindCore`

**Key Concepts:**
*   **Dynamic NFTs:** ChronoMind's traits are not static. They represent evolving tendencies that change based on interactions, external data, and time.
*   **Oracle Integration:** A trusted oracle feeds "environmental" or "AI insight" data, influencing ChronoMind's evolution and disposition.
*   **Owner Nurturing:** Owners can spend an `Essence` token (an ERC20) to actively influence specific traits or the ChronoMind's overall disposition.
*   **Community Governance (DAO-lite):** Stakeholders can propose new trait types or evolution mechanics, and vote on them, allowing for community-driven expansion of the ChronoMind ecosystem.
*   **On-chain Memory:** ChronoMinds record and are influenced by their interaction history, shaping their future state and "personality."
*   **Disposition System:** An abstract, evolving metric representing a ChronoMind's current "mood" or overall state, ranging from negative to positive.
*   **Replication:** A unique and costly mechanism allowing highly-evolved ChronoMinds to "clone" or "reproduce" new generations, inheriting parental traits with variance.
*   **Essence Token:** An ERC20 token used for nurturing actions, staking for governance proposals, and replication costs.

---

**Functions Summary (20 ChronoMind-specific functions):**

**I. ChronoMind Lifecycle & State Management:**

1.  `mintInitialChronoMind(address _to)`: Mints a new ChronoMind of the genesis generation with randomized baseline traits and an initial disposition. Callable by the contract owner for initial seeding.
2.  `getChronoMindDetails(uint256 _tokenId)`: Retrieves a ChronoMind's full evolving state, including its generation, owner, current disposition, last recalibration time, and all dynamic traits and their values.
3.  `getChronoMindMemorySummary(uint256 _tokenId)`: Returns a summary of a ChronoMind's accumulated 'memory' by listing various event types and their respective counts that have occurred in its lifetime.
4.  `generateDynamicTokenURI(uint256 _tokenId)`: Dynamically generates the metadata URI (base64 encoded JSON) for a ChronoMind, reflecting its current evolving traits, disposition, and overall state for display on NFT marketplaces.

**II. Evolution & Influence Mechanisms:**

5.  `applyOwnerNurturing(uint256 _tokenId, bytes32 _nurtureAspect)`: Allows the ChronoMind's owner to spend `Essence` tokens to influence a specific trait (e.g., "intellect") or its overall "disposition," boosting the chosen aspect and recording the action in memory.
6.  `processEnvironmentalInfluence(uint256 _tokenId, bytes32 _influenceType, int256 _intensity, address _oracleSender)`: Callable only by the designated `ChronoMindOracle`, this function applies external "environmental" or "AI insight" data (e.g., market sentiment) to influence the ChronoMind's traits and disposition.
7.  `triggerDispositionRecalibration(uint256 _tokenId)`: A complex function that periodically re-evaluates and updates a ChronoMind's overall 'disposition' based on its recent memory events, accumulated owner interactions, and environmental influences.
8.  `recordInteractionEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData)`: Allows any account (or whitelisted applications) to record an arbitrary interaction event with a ChronoMind, contributing to its memory footprint and indirectly influencing future evolution.
9.  `initiateEvolutionSpur(uint256 _tokenId, bytes32 _spurType)`: An owner-initiated, high-cost action that triggers a significant, non-linear jump in specific traits, potentially unlocking new "skills" or "forms" if certain advanced conditions are met.

**III. Oracle & Governance (Community Influence):**

10. `setChronoMindOracle(address _newOracle)`: An administrative function (callable by contract owner) to set or update the address of the trusted oracle contract responsible for feeding external data.
11. `proposeTraitSchema(bytes32 _newTraitKey, string memory _description, int256 _initialValue)`: Allows community members to propose new types of traits (e.g., "curiosity," "charm") that ChronoMinds can potentially evolve. Requires locking `Essence` as a stake.
12. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables `Essence` holders to cast votes (for or against) on active trait schema proposals, with voting power potentially weighted by their `Essence` balance.
13. `finalizeProposal(uint256 _proposalId)`: Executable by anyone after a proposal's voting period has ended. If the proposal passes (based on votes and minimum thresholds), the new trait type is integrated into the ChronoMind system.

**IV. Essence & Financial Management:**

14. `configureChronoMindEssence(address _essenceTokenAddress)`: An administrative function (callable by contract owner) to set the ERC20 token address that will be used as the `Essence` token for nurturing and governance.
15. `depositEssenceForNurturing(uint256 _tokenId, uint256 _amount)`: Allows ChronoMind owners to deposit `Essence` tokens into the contract specifically for their ChronoMind's future nurturing actions, held on its behalf.
16. `withdrawUnusedEssence(uint256 _tokenId, uint256 _amount)`: Enables ChronoMind owners to withdraw any previously deposited but unused `Essence` tokens from their ChronoMind's reserves.

**V. Advanced Utility & Interoperability:**

17. `queryEnvironmentalInfluenceHistory(uint256 _tokenId, uint256 _startIndex, uint256 _count)`: A view function that allows anyone to retrieve a paginated log of past environmental influences that have been applied to a specific ChronoMind.
18. `initiateChronoMindReplication(uint256 _parentTokenId, address _to)`: A unique function allowing highly evolved ChronoMinds to "replicate" and create a new, "child" ChronoMind. The child inherits some parental traits with variance, starts a new generation, and the parent enters a cooldown.
19. `getChronoMindTraitHistory(uint256 _tokenId, bytes32 _traitKey)`: A view function that provides a detailed log of how a specific trait (e.g., "intellect") for a given ChronoMind has evolved over time, including timestamps and value changes.
20. `checkEvolutionCondition(uint256 _tokenId, bytes32 _conditionType)`: A public view function to check if a specific ChronoMind meets predefined conditions for major evolution events, such as a "cognitive leap" or being "replication ready."

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Minimal Base64 library for on-chain URI generation
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 len = 4 * ((data.length + 2) / 3);
        bytes memory buffer = new bytes(len);
        uint256 ptr = 0;
        for (uint256 i = 0; i < data.length; i += 3) {
            uint8 b1 = data[i];
            uint8 b2 = i + 1 < data.length ? data[i + 1] : 0;
            uint8 b3 = i + 2 < data.length ? data[i + 2] : 0;
            uint256 enc1 = b1 >> 2;
            uint256 enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
            uint256 enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
            uint256 enc4 = b3 & 0x3F;
            buffer[ptr++] = bytes1(table[enc1]);
            buffer[ptr++] = bytes1(table[enc2]);
            if (i + 1 < data.length) {
                buffer[ptr++] = bytes1(table[enc3]);
            } else {
                buffer[ptr++] = "=";
            }
            if (i + 2 < data.length) {
                buffer[ptr++] = bytes1(table[enc4]);
            } else {
                buffer[ptr++] = "=";
            }
        }
        return string(buffer);
    }
}

// --- Outline and Function Summary ---
//
// ChronoMindCore: An advanced, sentient NFT system where digital entities ("ChronoMinds") evolve dynamically.
// Their traits, disposition, and capabilities are shaped by owner interactions, external data feeds from a trusted oracle,
// and community governance proposals. Each ChronoMind possesses a unique "memory" and can, under specific conditions,
// "replicate" to create a new generation, inheriting some parental traits.
//
// Key Concepts:
// - Dynamic NFTs: Traits are not static but evolve based on various inputs.
// - Oracle Integration: External "environmental" or "AI insight" data influences ChronoMind evolution.
// - Owner Nurturing: Owners actively shape their ChronoMind's development.
// - Community Governance (DAO-lite): Stakeholders propose and vote on new trait types or evolution mechanics.
// - On-chain Memory: ChronoMinds record and are influenced by their interaction history.
// - Disposition System: An abstract, evolving metric representing a ChronoMind's current "mood" or overall state.
// - Replication: A unique mechanism allowing highly-evolved ChronoMinds to "clone" or "reproduce" new generations.
// - Essence Token: An ERC20 token used for nurturing, staking for proposals, and replication costs.
//
//
// Functions Summary (20 ChronoMind-specific functions):
//
// I. ChronoMind Lifecycle & State Management:
// 1.  `mintInitialChronoMind(address _to)`: Mints a new ChronoMind of the genesis generation with base traits.
// 2.  `getChronoMindDetails(uint256 _tokenId)`: Retrieves a ChronoMind's full evolving state (traits, disposition, generation, etc.).
// 3.  `getChronoMindMemorySummary(uint256 _tokenId)`: Returns a summary of a ChronoMind's accumulated memory events.
// 4.  `generateDynamicTokenURI(uint256 _tokenId)`: Creates the on-chain metadata URI, reflecting the ChronoMind's current state.
//
// II. Evolution & Influence Mechanisms:
// 5.  `applyOwnerNurturing(uint256 _tokenId, bytes32 _nurtureAspect)`: Owner-initiated action to influence a trait using 'Essence'.
// 6.  `processEnvironmentalInfluence(uint256 _tokenId, bytes32 _influenceType, int256 _intensity, address _oracleSender)`: Oracle-only function to apply external environmental/AI data.
// 7.  `triggerDispositionRecalibration(uint256 _tokenId)`: Re-evaluates a ChronoMind's overall disposition based on recent history.
// 8.  `recordInteractionEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData)`: Logs an interaction event, impacting memory and future evolution.
// 9.  `initiateEvolutionSpur(uint256 _tokenId, bytes32 _spurType)`: High-cost action for a significant, non-linear trait evolution.
//
// III. Oracle & Governance (Community Influence):
// 10. `setChronoMindOracle(address _newOracle)`: Admin sets the trusted oracle address.
// 11. `proposeTraitSchema(bytes32 _newTraitKey, string memory _description, int256 _initialValue)`: Community proposes new trait types.
// 12. `voteOnProposal(uint256 _proposalId, bool _support)`: Stakeholders vote on active proposals.
// 13. `finalizeProposal(uint256 _proposalId)`: Executes a passed proposal, integrating new trait types.
//
// IV. Essence & Financial Management:
// 14. `configureChronoMindEssence(address _essenceTokenAddress)`: Admin sets the ERC20 'Essence' token address.
// 15. `depositEssenceForNurturing(uint256 _tokenId, uint256 _amount)`: Deposit Essence for a specific ChronoMind's future use.
// 16. `withdrawUnusedEssence(uint256 _tokenId, uint256 _amount)`: Withdraws deposited, unused Essence.
//
// V. Advanced Utility & Interoperability:
// 17. `queryEnvironmentalInfluenceHistory(uint256 _tokenId, uint256 _startIndex, uint256 _count)`: View past environmental impacts.
// 18. `initiateChronoMindReplication(uint256 _parentTokenId, address _to)`: Creates a new ChronoMind from an evolved parent, with costs and cooldowns.
// 19. `getChronoMindTraitHistory(uint256 _tokenId, bytes32 _traitKey)`: Returns a log of a specific trait's evolution.
// 20. `checkEvolutionCondition(uint256 _tokenId, bytes32 _conditionType)`: Checks if a ChronoMind meets conditions for a major evolution event.
//
// Note: Standard ERC721 functions (transferFrom, approve, etc.) are inherited but not explicitly counted in the 20 custom functions.
// This contract aims for a rich, dynamic, and community-driven digital entity experience.

contract ChronoMindCore is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    // Represents a ChronoMind's core attributes
    struct ChronoMind {
        uint256 generation; // 0 for genesis, increases with replication
        address ownerAddress; // Current owner (cached for quick lookup, though ERC721 handles primary)
        int256 disposition; // Overall "mood" or state (-100 to 100, e.g., hostile to friendly)
        uint256 lastRecalibrationTime; // Timestamp of last disposition update

        mapping(bytes32 => int256) traits; // Dynamic traits (e.g., "intellect", "creativity", "agility")
        mapping(bytes32 => uint256) memoryFootprint; // Counts of different interaction event types
        mapping(bytes32 => TraitLogEntry[]) traitHistory; // Detailed history for each trait

        uint256 replicationCooldownEnd; // Timestamp when this ChronoMind can next replicate
        uint256 totalEssenceNurtured; // Total essence ever contributed to this ChronoMind
        mapping(address => uint256) depositedEssence; // Essence deposited by specific users for this ChronoMind
    }

    // Stores a snapshot of a trait's value at a specific time
    struct TraitLogEntry {
        uint256 timestamp;
        int256 value;
    }

    // Represents a proposed new trait schema
    struct TraitSchemaProposal {
        uint256 proposalId;
        bytes32 traitKey;
        string description;
        int256 initialValue;
        uint256 creationTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool finalized;
        bool passed;
    }

    // Represents an event from the ChronoMind's "environment"
    struct EnvironmentalInfluence {
        uint256 timestamp;
        bytes32 influenceType;
        int256 intensity;
        address oracle;
    }

    // --- State Variables ---

    mapping(uint256 => ChronoMind) public chronoMinds;
    mapping(uint256 => EnvironmentalInfluence[]) public environmentalInfluenceHistory; // Per ChronoMind history

    address public chronoMindOracle; // Trusted oracle contract address
    IERC20 public essenceToken; // ERC20 token used for nurturing and governance
    uint256 public constant ESSENCE_FOR_NURTURING_COST = 100 * 10**18; // Example cost for nurturing
    uint256 public constant REPLICATION_COST = 5000 * 10**18; // Cost to replicate
    uint256 public constant REPLICATION_COOLDOWN = 30 days; // Cooldown period for replication
    uint256 public constant INITIAL_DISPOSITION = 50; // Starting disposition
    int256 public constant MAX_TRAIT_VALUE = 1000;
    int256 public constant MIN_TRAIT_VALUE = -1000;
    int256 public constant MAX_DISPOSITION = 100;
    int256 public constant MIN_DISPOSITION = -100;

    // Proposal tracking
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => TraitSchemaProposal) public traitSchemaProposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_MIN_ESSENCE_STAKE = 500 * 10**18; // Essence needed to propose
    uint256 public constant PROPOSAL_MIN_VOTES_REQUIRED = 5; // Minimum votes (arbitrary units) for a proposal to be considered

    // Approved trait keys (new traits added via governance)
    mapping(bytes32 => bool) public approvedTraitKeys;
    bytes32[] private _approvedTraitKeysList; // To allow iteration

    // --- Events ---

    event ChronoMindMinted(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event ChronoMindNurtured(uint256 indexed tokenId, address indexed nurturer, bytes32 nurtureAspect, uint256 amountEssence);
    event EnvironmentalInfluenceApplied(uint256 indexed tokenId, bytes32 influenceType, int256 intensity);
    event DispositionRecalibrated(uint256 indexed tokenId, int256 newDisposition);
    event InteractionRecorded(uint256 indexed tokenId, bytes32 eventType, bytes eventData);
    event EvolutionSpurred(uint256 indexed tokenId, bytes32 spurType);
    event OracleAddressSet(address indexed newOracle);
    event TraitSchemaProposed(uint256 indexed proposalId, bytes32 traitKey, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalFinalized(uint256 indexed proposalId, bool passed);
    event EssenceTokenConfigured(address indexed essenceTokenAddress);
    event EssenceDeposited(uint256 indexed tokenId, address indexed depositor, uint256 amount);
    event EssenceWithdrawn(uint256 indexed tokenId, address indexed withdrawer, uint256 amount);
    event ChronoMindReplicated(uint256 indexed parentTokenId, uint256 indexed childTokenId, address indexed childOwner);
    event TraitValueUpdated(uint256 indexed tokenId, bytes32 traitKey, int256 oldValue, int256 newValue);


    // --- Constructor ---

    constructor(address _chronoMindOracle, address _essenceTokenAddress) ERC721("ChronoMindCore", "CHRONO") Ownable(msg.sender) {
        require(_chronoMindOracle != address(0), "Oracle address cannot be zero");
        require(_essenceTokenAddress != address(0), "Essence token address cannot be zero");
        chronoMindOracle = _chronoMindOracle;
        essenceToken = IERC20(_essenceTokenAddress);

        // Initialize some default trait keys that exist from genesis
        _addApprovedTraitKey("intellect");
        _addApprovedTraitKey("creativity");
        _addApprovedTraitKey("empathy");
        _addApprovedTraitKey("resilience");
    }

    // --- Modifiers ---

    modifier onlyChronoMindOracle() {
        require(msg.sender == chronoMindOracle, "Only the designated ChronoMind Oracle can call this function");
        _;
    }

    modifier onlyChronoMindOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _;
    }

    // --- I. ChronoMind Lifecycle & State Management ---

    /// @notice Mints a new ChronoMind of the genesis generation with base randomized traits and disposition.
    ///         Can only be called by the contract owner for initial seeding.
    /// @param _to The address to mint the ChronoMind to.
    /// @return The ID of the newly minted ChronoMind.
    function mintInitialChronoMind(address _to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);
        chronoMinds[newItemId].generation = 0; // Genesis generation
        chronoMinds[newItemId].ownerAddress = _to; // Cache owner
        chronoMinds[newItemId].disposition = INITIAL_DISPOSITION;
        chronoMinds[newItemId].lastRecalibrationTime = block.timestamp;

        // Initialize baseline traits (can be randomized or fixed)
        // Using keccak256 as a pseudo-random source for initial traits
        chronoMinds[newItemId].traits["intellect"] = int256(uint256(keccak256(abi.encodePacked(newItemId, "intellect", block.timestamp))) % 100) + 1; // 1-100
        chronoMinds[newItemId].traits["creativity"] = int256(uint256(keccak256(abi.encodePacked(newItemId, "creativity", block.timestamp))) % 100) + 1;
        chronoMinds[newItemId].traits["empathy"] = int256(uint256(keccak256(abi.encodePacked(newItemId, "empathy", block.timestamp))) % 100) + 1;
        chronoMinds[newItemId].traits["resilience"] = int256(uint256(keccak256(abi.encodePacked(newItemId, "resilience", block.timestamp))) % 100) + 1;

        // Record initial trait values to history
        _recordTraitHistory(newItemId, "intellect", chronoMinds[newItemId].traits["intellect"]);
        _recordTraitHistory(newItemId, "creativity", chronoMinds[newItemId].traits["creativity"]);
        _recordTraitHistory(newItemId, "empathy", chronoMinds[newItemId].traits["empathy"]);
        _recordTraitHistory(newItemId, "resilience", chronoMinds[newItemId].traits["resilience"]);

        emit ChronoMindMinted(newItemId, _to, 0);
        return newItemId;
    }

    /// @notice Retrieves a ChronoMind's full evolving state, including traits, disposition, and generation.
    /// @param _tokenId The ID of the ChronoMind.
    /// @return A tuple containing (generation, ownerAddress, disposition, lastRecalibrationTime, traitKeys, traitValues, memoryFootprintKeys, memoryFootprintValues).
    function getChronoMindDetails(uint256 _tokenId) public view returns (
        uint256 generation,
        address ownerAddress,
        int256 disposition,
        uint256 lastRecalibrationTime,
        bytes32[] memory traitKeys,
        int256[] memory traitValues,
        bytes32[] memory memoryFootprintKeys,
        uint256[] memory memoryFootprintValues
    ) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        generation = mind.generation;
        ownerAddress = ownerOf(_tokenId); // Use ERC721's ownerOf as primary source
        disposition = mind.disposition;
        lastRecalibrationTime = mind.lastRecalibrationTime;

        // Populate trait arrays from the dynamically managed list
        traitKeys = new bytes32[](_approvedTraitKeysList.length);
        traitValues = new int256[](_approvedTraitKeysList.length);
        for (uint256 i = 0; i < _approvedTraitKeysList.length; i++) {
            traitKeys[i] = _approvedTraitKeysList[i];
            traitValues[i] = mind.traits[_approvedTraitKeysList[i]];
        }

        // Populate memory footprint arrays (simplified, a real system would need to track all event types)
        bytes32[] memory tempMemoryKeys = new bytes32[](3); // Example for 3 event types
        uint256[] memory tempMemoryValues = new uint256[](3);
        tempMemoryKeys[0] = "owner_nurture"; tempMemoryValues[0] = mind.memoryFootprint["owner_nurture"];
        tempMemoryKeys[1] = "environmental_impact"; tempMemoryValues[1] = mind.memoryFootprint["environmental_impact"];
        tempMemoryKeys[2] = "evolution_spur"; tempMemoryValues[2] = mind.memoryFootprint["evolution_spur"];
        memoryFootprintKeys = tempMemoryKeys;
        memoryFootprintValues = tempMemoryValues;
    }

    /// @notice Provides a summary of the ChronoMind's accumulated 'memory' by counting event types.
    /// @param _tokenId The ID of the ChronoMind.
    /// @return A tuple of (memoryFootprintKeys, memoryFootprintValues) listing all known event types and their counts.
    function getChronoMindMemorySummary(uint256 _tokenId) public view returns (bytes32[] memory, uint256[] memory) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        // This would ideally iterate over all known event types dynamically.
        // For simplicity, we hardcode some common ones for the example.
        bytes32[] memory keys = new bytes32[](3);
        uint256[] memory values = new uint256[](3);

        keys[0] = "owner_nurture";
        values[0] = mind.memoryFootprint["owner_nurture"];
        keys[1] = "environmental_impact";
        values[1] = mind.memoryFootprint["environmental_impact"];
        keys[2] = "evolution_spur";
        values[2] = mind.memoryFootprint["evolution_spur"];

        return (keys, values);
    }

    /// @notice Dynamically generates the metadata URI for a ChronoMind, reflecting its current evolving state.
    ///         The URI points to on-chain data (base64 encoded JSON).
    /// @param _tokenId The ID of the ChronoMind.
    /// @return The base64 encoded JSON string representing the ChronoMind's metadata.
    function generateDynamicTokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        // Retrieve full details
        (
            uint256 generation,
            address ownerAddress,
            int256 disposition,
            uint256 lastRecalibrationTime,
            bytes32[] memory traitKeys,
            int256[] memory traitValues,
            bytes32[] memory memoryFootprintKeys,
            uint256[] memory memoryFootprintValues
        ) = getChronoMindDetails(_tokenId);

        string memory name = string(abi.encodePacked("ChronoMind #", Strings.toString(_tokenId)));
        string memory description = string(abi.encodePacked(
            "An evolving digital consciousness. Generation: ", Strings.toString(generation),
            ". Disposition: ", Strings.toString(disposition),
            ". Shaped by owner interactions (", Strings.toString(mind.memoryFootprint["owner_nurture"]), " times) and environmental inputs."
        ));

        // Construct attributes array from traits
        string memory attributes = "[";
        for (uint256 i = 0; i < traitKeys.length; i++) {
            attributes = string(abi.encodePacked(attributes,
                '{"trait_type": "', string(abi.encodePacked(traitKeys[i])), '", "value": ', Strings.toString(traitValues[i]), '}'
            ));
            if (i < traitKeys.length - 1) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
        }
        attributes = string(abi.encodePacked(attributes, "]"));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "ipfs://QmbQvH4F5S6Zg4W5R7T8U9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V4W5X6Y7Z",', // Placeholder image (replace with actual image logic)
            '"attributes": ', attributes, '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // Overriding ERC721's tokenURI to use our dynamic one
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return generateDynamicTokenURI(_tokenId);
    }


    // --- II. Evolution & Influence Mechanisms ---

    /// @notice Allows the owner to spend 'Essence' to nurture a specific trait or aspect of their ChronoMind.
    ///         This increases the chosen trait value and records an event in memory.
    /// @param _tokenId The ID of the ChronoMind to nurture.
    /// @param _nurtureAspect The bytes32 key representing the trait/aspect to influence (e.g., "intellect", "disposition").
    function applyOwnerNurturing(uint256 _tokenId, bytes32 _nurtureAspect) public onlyChronoMindOwner(_tokenId) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        require(essenceToken.transferFrom(msg.sender, address(this), ESSENCE_FOR_NURTURING_COST), "Essence transfer failed");

        ChronoMind storage mind = chronoMinds[_tokenId];

        // Influence disposition directly if "disposition" is the aspect
        if (_nurtureAspect == "disposition") {
            mind.disposition = _clamp(mind.disposition + 5, MIN_DISPOSITION, MAX_DISPOSITION); // Small disposition boost
            emit DispositionRecalibrated(_tokenId, mind.disposition);
        } else if (approvedTraitKeys[_nurtureAspect]) { // Only allow nurturing of approved traits
            int256 oldValue = mind.traits[_nurtureAspect];
            mind.traits[_nurtureAspect] = _clamp(oldValue + 10, MIN_TRAIT_VALUE, MAX_TRAIT_VALUE); // Boost trait by 10
            _recordTraitHistory(_tokenId, _nurtureAspect, mind.traits[_nurtureAspect]);
            emit TraitValueUpdated(_tokenId, _nurtureAspect, oldValue, mind.traits[_nurtureAspect]);
        } else {
            revert("Invalid nurture aspect or trait not approved");
        }

        mind.memoryFootprint["owner_nurture"]++;
        mind.totalEssenceNurtured += ESSENCE_FOR_NURTURING_COST;
        emit ChronoMindNurtured(_tokenId, msg.sender, _nurtureAspect, ESSENCE_FOR_NURTURING_COST);
    }

    /// @notice Callable only by the designated ChronoMind Oracle. Feeds external data to influence ChronoMind traits.
    ///         This simulates environmental impact or AI-driven insights affecting the ChronoMind's state.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _influenceType A bytes32 key representing the type of environmental influence (e.g., "market_sentiment", "global_event").
    /// @param _intensity The intensity of the influence, which can be positive or negative.
    /// @param _oracleSender The actual oracle address sending the data (for logging/verification).
    function processEnvironmentalInfluence(uint256 _tokenId, bytes32 _influenceType, int256 _intensity, address _oracleSender) public onlyChronoMindOracle {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        // Example: Environmental influence affecting traits.
        // Logic here would be more complex, potentially involving AI model outputs.
        // For demonstration:
        if (_influenceType == "market_sentiment") {
            int256 oldValue = mind.traits["resilience"];
            mind.traits["resilience"] = _clamp(oldValue + (_intensity / 10), MIN_TRAIT_VALUE, MAX_TRAIT_VALUE);
            _recordTraitHistory(_tokenId, "resilience", mind.traits["resilience"]);
            emit TraitValueUpdated(_tokenId, "resilience", oldValue, mind.traits["resilience"]);
        } else if (_influenceType == "innovation_surge") {
            int256 oldValue = mind.traits["creativity"];
            mind.traits["creativity"] = _clamp(oldValue + (_intensity / 5), MIN_TRAIT_VALUE, MAX_TRAIT_VALUE);
            _recordTraitHistory(_tokenId, "creativity", mind.traits["creativity"]);
            emit TraitValueUpdated(_tokenId, "creativity", oldValue, mind.traits["creativity"]);
        }

        // Apply a general disposition change based on average intensity
        mind.disposition = _clamp(mind.disposition + (_intensity / 20), MIN_DISPOSITION, MAX_DISPOSITION);
        mind.memoryFootprint["environmental_impact"]++;

        environmentalInfluenceHistory[_tokenId].push(EnvironmentalInfluence({
            timestamp: block.timestamp,
            influenceType: _influenceType,
            intensity: _intensity,
            oracle: _oracleSender
        }));

        emit EnvironmentalInfluenceApplied(_tokenId, _influenceType, _intensity);
    }

    /// @notice A complex function that re-evaluates the ChronoMind's overall 'disposition'
    ///         based on its recent memory, owner interactions, and environmental influences.
    /// @param _tokenId The ID of the ChronoMind.
    function triggerDispositionRecalibration(uint256 _tokenId) public {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];
        require(block.timestamp > mind.lastRecalibrationTime + 1 days, "Recalibration too frequent (1 day cooldown)");

        int256 dispositionChange = 0;

        // Influence from owner nurturing (positive)
        dispositionChange += int256(mind.memoryFootprint["owner_nurture"]) * 2;
        mind.memoryFootprint["owner_nurture"] = 0; // Reset counter after impact for next cycle

        // Influence from recent environmental impacts (average intensity)
        if (environmentalInfluenceHistory[_tokenId].length > 0) {
            int256 totalRecentInfluence = 0;
            uint256 recentCount = 0;
            // Consider last 10 influences or influences within a recent time window (7 days)
            for (uint256 i = environmentalInfluenceHistory[_tokenId].length; i > 0 && i > environmentalInfluenceHistory[_tokenId].length - 10; i--) {
                if (environmentalInfluenceHistory[_tokenId][i-1].timestamp > block.timestamp - 7 days) {
                    totalRecentInfluence += environmentalInfluenceHistory[_tokenId][i-1].intensity;
                    recentCount++;
                }
            }
            if (recentCount > 0) {
                dispositionChange += (totalRecentInfluence / int256(recentCount)) / 5;
            }
        }

        // Influence from current traits (e.g., high empathy -> positive, low resilience -> negative)
        dispositionChange += (mind.traits["empathy"] / 20);
        dispositionChange -= (mind.traits["resilience"] / 30); // Lower resilience can make it more prone to negative disposition

        int256 oldDisposition = mind.disposition;
        mind.disposition = _clamp(oldDisposition + dispositionChange, MIN_DISPOSITION, MAX_DISPOSITION);
        mind.lastRecalibrationTime = block.timestamp;

        emit DispositionRecalibrated(_tokenId, mind.disposition);
    }

    /// @notice Allows any account (or specific whitelisted apps) to record an interaction event with the ChronoMind.
    ///         These events influence its memory footprint and can indirectly affect future disposition/traits.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _eventType A bytes32 key describing the type of interaction (e.g., "social_mention", "puzzle_solved", "data_exposed").
    /// @param _eventData Optional additional data about the event, encoded as bytes.
    function recordInteractionEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData) public {
        // In a more complex system, this might be restricted, e.g., to whitelisted "apps" or require a small fee.
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        mind.memoryFootprint[_eventType]++; // Increment count for this event type
        // Further logic could parse _eventData to affect specific traits, but kept simple for example.

        emit InteractionRecorded(_tokenId, _eventType, _eventData);
    }

    /// @notice An owner-initiated action to force a significant, non-linear jump in certain traits,
    ///         potentially unlocking new "skills" or "forms." Requires significant 'Essence' and specific conditions.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _spurType A bytes32 key indicating the type of evolution spur (e.g., "cognitive_leap", "adaptability_boost").
    function initiateEvolutionSpur(uint256 _tokenId, bytes32 _spurType) public onlyChronoMindOwner(_tokenId) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        // Example condition: ChronoMind must have high intellect and creativity, and accumulated enough essence.
        require(checkEvolutionCondition(_tokenId, "cognitive_leap_ready"), "ChronoMind not ready for cognitive leap spur");

        // Deduct a significant amount of essence (this could be from deposited or paid directly)
        // For simplicity, let's say it's paid directly here
        uint256 spurCost = 2000 * 10**18;
        require(essenceToken.transferFrom(msg.sender, address(this), spurCost), "Essence transfer failed for spur");

        // Apply significant trait boosts based on spur type
        if (_spurType == "cognitive_leap") {
            int256 oldIntellect = mind.traits["intellect"];
            mind.traits["intellect"] = _clamp(oldIntellect + 200, MIN_TRAIT_VALUE, MAX_TRAIT_VALUE);
            _recordTraitHistory(_tokenId, "intellect", mind.traits["intellect"]);
            emit TraitValueUpdated(_tokenId, "intellect", oldIntellect, mind.traits["intellect"]);
        } else if (_spurType == "adaptability_boost") {
            int256 oldResilience = mind.traits["resilience"];
            mind.traits["resilience"] = _clamp(oldResilience + 150, MIN_TRAIT_VALUE, MAX_TRAIT_VALUE);
            _recordTraitHistory(_tokenId, "resilience", mind.traits["resilience"]);
            emit TraitValueUpdated(_tokenId, "resilience", oldResilience, mind.traits["resilience"]);
        } else {
            revert("Invalid evolution spur type");
        }

        // Reset some state for next evolution phase, or trigger a new memory event
        mind.memoryFootprint["evolution_spur"]++;
        emit EvolutionSpurred(_tokenId, _spurType);
    }


    // --- III. Oracle & Governance (Community Influence) ---

    /// @notice Admin function to set or update the address of the trusted ChronoMind Oracle.
    /// @param _newOracle The new address for the ChronoMind Oracle.
    function setChronoMindOracle(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        chronoMindOracle = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /// @notice Allows community members to propose new types of traits that ChronoMinds can potentially evolve.
    ///         Requires locking a certain amount of 'Essence' as a stake.
    /// @param _newTraitKey The unique bytes32 key for the new trait (e.g., "curiosity", "charm").
    /// @param _description A human-readable description of the proposed trait.
    /// @param _initialValue The proposed initial value for this trait when first applied or for new ChronoMinds.
    function proposeTraitSchema(bytes32 _newTraitKey, string memory _description, int256 _initialValue) public {
        require(!approvedTraitKeys[_newTraitKey], "Trait key already approved or proposed");
        require(essenceToken.transferFrom(msg.sender, address(this), PROPOSAL_MIN_ESSENCE_STAKE), "Insufficient Essence stake for proposal");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        TraitSchemaProposal storage proposal = traitSchemaProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.traitKey = _newTraitKey;
        proposal.description = _description;
        proposal.initialValue = _initialValue;
        proposal.creationTime = block.timestamp;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.finalized = false;
        proposal.passed = false;

        emit TraitSchemaProposed(proposalId, _newTraitKey, _description);
    }

    /// @notice Allows 'Essence' holders (or ChronoMind owners, if desired) to vote on active proposals.
    ///         Each vote might be weighted by Essence held or number of ChronoMinds owned.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        TraitSchemaProposal storage proposal = traitSchemaProposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(!proposal.finalized, "Voting period has ended for this proposal");
        require(block.timestamp <= proposal.creationTime + PROPOSAL_VOTING_PERIOD, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        // Example: 1 vote per 100 Essence held (simplified for example).
        // More robust would use a snapshotting mechanism or specific governance tokens.
        uint256 voterEssenceBalance = essenceToken.balanceOf(msg.sender);
        require(voterEssenceBalance > 0, "Voter must hold Essence");
        uint256 votes = voterEssenceBalance / (100 * 10**18); // Each 100 Essence = 1 vote
        require(votes > 0, "Voter must have enough Essence for at least 1 vote");


        if (_support) {
            proposal.votesFor += votes;
        } else {
            proposal.votesAgainst += votes;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Finalizes a proposal after its voting period has ended. If passed, integrates the new trait type.
    ///         Can be called by anyone, triggering the outcome if conditions are met.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) public {
        TraitSchemaProposal storage proposal = traitSchemaProposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(!proposal.finalized, "Proposal already finalized");
        require(block.timestamp > proposal.creationTime + PROPOSAL_VOTING_PERIOD, "Voting period has not ended");

        proposal.finalized = true;

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= PROPOSAL_MIN_VOTES_REQUIRED) {
            proposal.passed = true;
            _addApprovedTraitKey(proposal.traitKey); // Add new trait key to approved list
            // Optionally, refund proposal stake to proposer
        }
        // Optionally, burn or return stake for failed proposals

        emit ProposalFinalized(_proposalId, proposal.passed);
    }

    // --- IV. Essence & Financial Management ---

    /// @notice Admin function to set the address of the ERC20 token used as 'Essence'.
    /// @param _essenceTokenAddress The address of the ERC20 Essence token.
    function configureChronoMindEssence(address _essenceTokenAddress) public onlyOwner {
        require(_essenceTokenAddress != address(0), "Essence token address cannot be zero");
        essenceToken = IERC20(_essenceTokenAddress);
        emit EssenceTokenConfigured(_essenceTokenAddress);
    }

    /// @notice Allows owners to deposit 'Essence' tokens specifically for their ChronoMind's future nurturing actions.
    ///         These tokens are held by the contract on behalf of the ChronoMind.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _amount The amount of Essence tokens to deposit.
    function depositEssenceForNurturing(uint256 _tokenId, uint256 _amount) public onlyChronoMindOwner(_tokenId) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "Essence transfer failed");

        chronoMinds[_tokenId].depositedEssence[msg.sender] += _amount; // Track per user
        emit EssenceDeposited(_tokenId, msg.sender, _amount);
    }

    /// @notice Allows owners to withdraw previously deposited but unused 'Essence' from their ChronoMind's reserves.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _amount The amount of Essence tokens to withdraw.
    function withdrawUnusedEssence(uint256 _tokenId, uint256 _amount) public onlyChronoMindOwner(_tokenId) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(chronoMinds[_tokenId].depositedEssence[msg.sender] >= _amount, "Insufficient deposited essence");

        chronoMinds[_tokenId].depositedEssence[msg.sender] -= _amount;
        require(essenceToken.transfer(msg.sender, _amount), "Essence withdrawal failed");
        emit EssenceWithdrawn(_tokenId, msg.sender, _amount);
    }

    // --- V. Advanced Utility & Interoperability ---

    /// @notice Retrieves a log of recent environmental influences applied to a specific ChronoMind.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _startIndex The starting index in the history array.
    /// @param _count The number of entries to retrieve.
    /// @return An array of EnvironmentalInfluence structs.
    function queryEnvironmentalInfluenceHistory(uint256 _tokenId, uint256 _startIndex, uint256 _count) public view returns (EnvironmentalInfluence[] memory) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        require(_startIndex < environmentalInfluenceHistory[_tokenId].length, "Start index out of bounds");
        
        uint256 endIndex = _startIndex + _count;
        if (endIndex > environmentalInfluenceHistory[_tokenId].length) {
            endIndex = environmentalInfluenceHistory[_tokenId].length;
        }

        uint256 actualCount = endIndex - _startIndex;
        EnvironmentalInfluence[] memory historySubset = new EnvironmentalInfluence[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            historySubset[i] = environmentalInfluenceHistory[_tokenId][_startIndex + i];
        }
        return historySubset;
    }

    /// @notice Allows highly evolved ChronoMinds to create a new, "child" ChronoMind,
    ///         inheriting some traits but with significant variance and a high cost, starting a new generation.
    ///         The parent ChronoMind enters a cooldown period.
    /// @param _parentTokenId The ID of the ChronoMind acting as the parent.
    /// @param _to The address to mint the child ChronoMind to.
    /// @return The ID of the newly created child ChronoMind.
    function initiateChronoMindReplication(uint256 _parentTokenId, address _to) public onlyChronoMindOwner(_parentTokenId) returns (uint256) {
        require(_exists(_parentTokenId), "Parent ChronoMind does not exist");
        ChronoMind storage parentMind = chronoMinds[_parentTokenId];
        require(checkEvolutionCondition(_parentTokenId, "replication_ready"), "Parent ChronoMind not ready for replication");

        // Pay replication cost
        require(essenceToken.transferFrom(msg.sender, address(this), REPLICATION_COST), "Essence transfer failed for replication");

        _tokenIdCounter.increment();
        uint256 childTokenId = _tokenIdCounter.current();

        _safeMint(_to, childTokenId);
        chronoMinds[childTokenId].generation = parentMind.generation + 1;
        chronoMinds[childTokenId].ownerAddress = _to;
        // Inherit disposition with variance based on parent's disposition and a pseudo-random factor
        int256 dispositionVariance = int256(uint256(keccak256(abi.encodePacked(childTokenId, "disposition_var", block.timestamp, block.difficulty))) % 20) - 10; // +/- 10
        chronoMinds[childTokenId].disposition = _clamp(parentMind.disposition + dispositionVariance, MIN_DISPOSITION, MAX_DISPOSITION);
        chronoMinds[childTokenId].lastRecalibrationTime = block.timestamp;

        // Inherit all approved traits with variance
        for(uint256 i = 0; i < _approvedTraitKeysList.length; i++) {
            _inheritTraitWithVariance(childTokenId, _parentTokenId, _approvedTraitKeysList[i]);
        }
        
        // Apply cooldown to parent
        parentMind.replicationCooldownEnd = block.timestamp + REPLICATION_COOLDOWN;

        emit ChronoMindReplicated(_parentTokenId, childTokenId, _to);
        emit ChronoMindMinted(childTokenId, _to, parentMind.generation + 1);
        return childTokenId;
    }

    /// @notice Retrieves a log of how a specific trait for a ChronoMind has evolved over time.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _traitKey The bytes32 key of the trait to query.
    /// @return An array of TraitLogEntry structs, showing timestamps and values.
    function getChronoMindTraitHistory(uint256 _tokenId, bytes32 _traitKey) public view returns (TraitLogEntry[] memory) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        require(approvedTraitKeys[_traitKey], "Trait key is not approved or does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        uint256 historyLength = mind.traitHistory[_traitKey].length;
        TraitLogEntry[] memory history = new TraitLogEntry[](historyLength);
        for (uint256 i = 0; i < historyLength; i++) {
            history[i] = mind.traitHistory[_traitKey][i];
        }
        return history;
    }

    /// @notice Public view function to check if specific conditions for a major evolution (e.g., a "spur") are met.
    /// @param _tokenId The ID of the ChronoMind.
    /// @param _conditionType A bytes32 key representing the evolution condition to check.
    /// @return True if the conditions are met, false otherwise.
    function checkEvolutionCondition(uint256 _tokenId, bytes32 _conditionType) public view returns (bool) {
        require(_exists(_tokenId), "ChronoMind does not exist");
        ChronoMind storage mind = chronoMinds[_tokenId];

        if (_conditionType == "cognitive_leap_ready") {
            return mind.traits["intellect"] > 500 && mind.traits["creativity"] > 500 && mind.totalEssenceNurtured >= 5000 * 10**18;
        }
        if (_conditionType == "replication_ready") {
            // Check if ChronoMind has high evolution (e.g., high average trait values)
            int256 totalTraitValue = 0;
            for(uint256 i = 0; i < _approvedTraitKeysList.length; i++) {
                totalTraitValue += mind.traits[_approvedTraitKeysList[i]];
            }
            uint256 averageTraitValue = totalTraitValue > 0 ? uint256(totalTraitValue / int256(_approvedTraitKeysList.length)) : 0;

            return block.timestamp >= mind.replicationCooldownEnd && mind.totalEssenceNurtured >= REPLICATION_COST && averageTraitValue > 300;
        }
        // Add more condition checks as needed
        return false;
    }


    // --- Internal / Private Helper Functions ---

    /// @dev Internal function to clamp a value between a min and max.
    function _clamp(int256 value, int256 min, int256 max) internal pure returns (int256) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    /// @dev Internal function to record a trait's value at a specific timestamp.
    function _recordTraitHistory(uint256 _tokenId, bytes32 _traitKey, int256 _value) internal {
        ChronoMind storage mind = chronoMinds[_tokenId];
        mind.traitHistory[_traitKey].push(TraitLogEntry({
            timestamp: block.timestamp,
            value: _value
        }));
    }

    /// @dev Internal function for replication to inherit a trait with a random-like variance.
    function _inheritTraitWithVariance(uint256 _childId, uint256 _parentId, bytes32 _traitKey) internal {
        ChronoMind storage parentMind = chronoMinds[_parentId];
        ChronoMind storage childMind = chronoMinds[_childId];

        int256 parentValue = parentMind.traits[_traitKey];
        // Introduce pseudo-random variance based on block data and IDs
        // Note: block.difficulty is deprecated in proof-of-stake, use other sources for more robust entropy if possible (e.g., Chainlink VRF)
        int256 variance = int256(uint256(keccak256(abi.encodePacked(_childId, _traitKey, block.timestamp, block.difficulty))) % 50) - 25; // +/- 25
        int256 childValue = _clamp(parentValue + variance, MIN_TRAIT_VALUE, MAX_TRAIT_VALUE);
        childMind.traits[_traitKey] = childValue;
        _recordTraitHistory(_childId, _traitKey, childValue);
    }

    /// @dev Internal function to add a trait key to the approved list and its iterable array.
    function _addApprovedTraitKey(bytes32 _traitKey) internal {
        require(!approvedTraitKeys[_traitKey], "Trait key already approved");
        approvedTraitKeys[_traitKey] = true;
        _approvedTraitKeysList.push(_traitKey);
    }

    // --- ERC721 Overrides (not counted in 20 custom functions) ---
    // These are standard and ensure the contract adheres to the ERC721 interface.
    // They are not listed in the 20 custom functions, as they are boilerplate.

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        chronoMinds[tokenId].ownerAddress = to; // Update cached owner for consistency
        return super._update(to, tokenId, auth);
    }
}
```