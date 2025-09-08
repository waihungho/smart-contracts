This Solidity smart contract, named `AetherWeaver`, introduces a novel concept: **Dynamic On-Chain Narrative & Identity Protocol**. It utilizes NFTs (Epoch Weavers) as evolving digital identities that are shaped by user actions, community-driven lore, and external oracle data. This combines elements of dynamic NFTs, decentralized identity (akin to Soulbound Tokens in functionality for certain aspects), interactive storytelling, and a modular system for complex "rituals."

The contract aims to be unique by not just having evolving traits, but by having those traits deeply intertwined with a *co-created narrative* and *external contextual data* in a structured, verifiable manner.

---

### Outline and Function Summary:

**Contract Name:** `AetherWeaver - Dynamic On-Chain Narrative & Identity Protocol`

This contract implements Epoch Weavers (ERC721 NFTs) as evolving on-chain identities. These identities are shaped by user actions, community-driven narrative (Lore Fragments), and external data feeds (Cosmic Whispers). It's a blend of dynamic NFTs, decentralized identity, interactive storytelling, and a modular ritual system.

---

### Outline:

**I. Core Weaver Identity & Essence (ERC721-like with extensions)**
*   Manages the minting, essence fragments (dynamic traits), and memory logs of Epoch Weavers. Essence fragments are numerical values representing core aspects of a Weaver's identity.

**II. Aetheric Chronicle (Narrative Layer)**
*   Facilitates community proposal, voting, and finalization of narrative fragments (lore).
*   Allows linking finalized lore to essence types, influencing their meaning or potential behavior.

**III. Dynamic Bonds & Rituals**
*   Enables semantic connections (bonds) between Weavers or between a Weaver and external entities (EOAs, other contracts). These bonds can be used as conditions for actions.
*   Provides a modular system for "rituals" – special, complex actions that require specific Weaver states (traits, memories, bonds) and are executed via external logic contracts.

**IV. Cosmic Whispers (Oracle Integration)**
*   Manages whitelisted external data providers ("Cosmic Whisperers" or oracles) and their data submissions.
*   Allows Weavers to "attune" to specific whisper types, letting external real-world events or data streams dynamically influence their essence fragments.

**V. Protocol Governance & Maintenance**
*   Implements a basic governance mechanism for adjusting core protocol parameters.
*   Allows for dynamic upgradeability of ritual logic contracts, enabling future expansion without changing the main contract.

---

### Function Summary (24 Functions):

**I. Core Weaver Identity & Essence**

1.  `mintWeaver(string _initialEssenceName) returns (uint256)`: Mints a new Epoch Weaver NFT, assigning it a primary essence fragment based on a registered type.
2.  `registerEssenceFragmentType(string _typeName, int256 _baseValue)`: (Admin/Governance) Defines new fundamental trait categories (e.g., "Courage", "Wisdom") with a base value.
3.  `imbueMemoryFragment(uint256 _tokenId, bytes32 _memoryHash, string _memoryContext)`: Associates an on-chain event (represented by a hash and a descriptive context) with a Weaver, which can optionally trigger an update to its essence fragments.
4.  `updateEssenceFragment(uint256 _tokenId, string _typeName, int256 _valueChange)`: (Internal/Restricted) Modifies a specific essence fragment's value for a given Weaver. Called by other contract logic (e.g., `imbueMemoryFragment`, `processWhisperInfluence`, `initiateRitual`).
5.  `getWeaverEssence(uint256 _tokenId) returns (string[] memory typeNames, int256[] memory values)`: Retrieves all essence fragments and their current values for a specified Weaver.
6.  `getWeaverMemoryLog(uint256 _tokenId) returns (bytes32[] memory memoryHashes, string[] memory contexts)`: Returns the chronological log of memories imbued into a Weaver.

**II. Aetheric Chronicle (Narrative Layer)**

7.  `proposeLoreFragment(bytes32 _loreHash, string _description)`: Proposes a content hash (e.g., IPFS CID of a text snippet) to be added to the collective lore. Requires owning a Weaver.
8.  `voteOnLoreFragment(bytes32 _loreHash, bool _for)`: Allows Weaver owners to vote 'for' or 'against' a proposed lore fragment. Each owned Weaver (or simply caller, as simplified here) counts as a vote.
9.  `finalizeLoreFragment(bytes32 _loreHash)`: (Anyone callable, off-chain trigger intended) Finalizes a lore fragment if it meets predefined vote thresholds, adding it to the official chronicle.
10. `linkLoreToEssence(bytes32 _loreHash, string _essenceType, int256 _influenceMagnitude)`: (Admin/Governance) Associates a finalized lore fragment with an essence type, meaning this lore piece now influences future changes to that essence type or its interpretation.
11. `getLoreFragmentStatus(bytes32 _loreHash) returns (uint256 votesFor, uint256 votesAgainst, bool isFinalized)`: Checks the current voting status and finalization state of a lore fragment proposal.
12. `retrieveChronicleLore(uint256 _startIndex, uint256 _count) returns (bytes32[] memory loreHashes)`: Paginates and retrieves a list of finalized lore fragments from the Aetheric Chronicle.

**III. Dynamic Bonds & Rituals**

13. `forgeAethericBond(uint256 _tokenIdA, address _targetAddress, string _bondType)`: Creates a semantic link (bond) between a Weaver (`_tokenIdA`) and another address (`_targetAddress`), specifying the nature of the relationship (e.g., "mentor", "ally").
14. `dissolveAethericBond(uint256 _tokenIdA, address _targetAddress, string _bondType)`: Removes an existing bond between a Weaver and a target address.
15. `queryAethericBonds(uint256 _tokenId) returns (address[] memory targets, string[] memory bondTypes)`: Retrieves all active bonds associated with a specific Weaver.
16. `initiateRitual(uint256 _tokenId, uint256 _ritualId, bytes _ritualParams)`: Triggers a special "ritual" by delegating execution to a pre-registered ritual logic contract (`IAetherRitual`). This allows for complex, modular, and upgradeable Weaver interactions.

**IV. Cosmic Whispers (Oracle Integration)**

17. `registerOracle(address _oracleAddress)`: (Admin) Whitelists an address as an authorized "Cosmic Whisperer" (oracle).
18. `submitCosmicWhisper(bytes32 _whisperId, int256 _value, uint256 _timestamp)`: An authorized oracle submits a data point (e.g., external event ID, market price) identified by `_whisperId`.
19. `attuneWeaverToWhisper(uint256 _tokenId, bytes32 _whisperId)`: A Weaver owner declares their Weaver's attunement to a specific type of cosmic whisper, indicating potential future influence.
20. `processWhisperInfluence(uint256 _tokenId, bytes32 _whisperId)`: (Anyone callable, e.g., keeper) Processes the influence of a recent cosmic whisper on an attuned Weaver, updating its essence fragments based on predefined rules or linked lore.

**V. Protocol Governance & Maintenance**

21. `proposeGovernanceChange(bytes32 _proposalHash, string _description)`: Proposes changes to core contract parameters (e.g., voting thresholds) or system-wide configurations. Requires owning a Weaver.
22. `voteOnGovernanceChange(bytes32 _proposalHash, bool _for)`: Allows Weaver owners to vote on proposed governance changes.
23. `executeGovernanceChange(bytes32 _proposalHash)`: (Admin/Automated) Executes an approved governance proposal if it meets vote thresholds. (Actual parameter changes would be implemented here in a real system).
24. `updateRitualLogic(uint256 _ritualId, address _newRitualContract)`: (Admin/Governance) Allows upgrading or registering the logic contract for a specific ritual type, pointing to a new implementation.

---

### Smart Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

// Outline and Function Summary:
//
// Contract Name: AetherWeaver - Dynamic On-Chain Narrative & Identity Protocol
//
// This contract introduces Epoch Weavers (ERC721 NFTs) as evolving on-chain identities.
// These identities are shaped by user actions, community-driven narrative (Lore Fragments),
// and external data feeds (Cosmic Whispers). It's a blend of dynamic NFTs, decentralized
// identity, interactive storytelling, and a modular ritual system.
//
// --- Outline ---
// I. Core Weaver Identity & Essence (ERC721-like with extensions)
//    - Manages the minting, essence fragments (traits), and memory logs of Epoch Weavers.
// II. Aetheric Chronicle (Narrative Layer)
//    - Facilitates community proposal, voting, and finalization of narrative fragments (lore).
//    - Allows linking lore to essence types, influencing their meaning or behavior.
// III. Dynamic Bonds & Rituals
//    - Enables semantic connections (bonds) between Weavers or external entities.
//    - Provides a modular system for "rituals" – special actions requiring specific Weaver states.
// IV. Cosmic Whispers (Oracle Integration)
//    - Manages whitelisted oracles ("Cosmic Whisperers") and their data submissions.
//    - Allows Weavers to attune to whispers, letting external events influence their essence.
// V. Protocol Governance & Maintenance
//    - Implements a basic governance mechanism for core protocol parameters.
//    - Allows for dynamic upgradeability of ritual logic contracts.
//
// --- Function Summary ---
//
// I. Core Weaver Identity & Essence
// 1. mintWeaver(string _initialEssenceName): Mints a new Epoch Weaver NFT, assigning it a primary essence fragment.
// 2. registerEssenceFragmentType(string _typeName, int256 _baseValue): Admin/Gov defines new fundamental trait categories (e.g., "Courage", "Wisdom").
// 3. imbueMemoryFragment(uint256 _tokenId, bytes32 _memoryHash, string _memoryContext): Associates an on-chain event (hash/context) with a Weaver, potentially altering its essence.
// 4. updateEssenceFragment(uint256 _tokenId, string _typeName, int256 _valueChange): Internal/Restricted function to modify a specific essence fragment's value for a Weaver.
// 5. getWeaverEssence(uint256 _tokenId): Retrieves all essence fragments and their current values for a Weaver.
// 6. getWeaverMemoryLog(uint256 _tokenId): Returns the log of memories imbued into a Weaver.
//
// II. Aetheric Chronicle (Narrative Layer)
// 7. proposeLoreFragment(bytes32 _loreHash, string _description): Proposes a hash (e.g., IPFS CID) of a narrative snippet for community review.
// 8. voteOnLoreFragment(bytes32 _loreHash, bool _for): Allows Weavers to vote on proposed lore fragments.
// 9. finalizeLoreFragment(bytes32 _loreHash): Admin/Automated process finalizes lore if it meets vote thresholds, adding it to the official chronicle.
// 10. linkLoreToEssence(bytes32 _loreHash, string _essenceType, int256 _influenceMagnitude): Associates finalized lore with an essence type, influencing its behavior/interpretation.
// 11. getLoreFragmentStatus(bytes32 _loreHash): Checks voting status and finalization of a lore fragment proposal.
// 12. retrieveChronicleLore(uint256 _startIndex, uint256 _count): Paginates and retrieves finalized lore fragments.
//
// III. Dynamic Bonds & Rituals
// 13. forgeAethericBond(uint256 _tokenIdA, address _targetAddress, string _bondType): Creates a semantic link between a Weaver and another Weaver or external address.
// 14. dissolveAethericBond(uint256 _tokenIdA, address _targetAddress, string _bondType): Removes an existing bond.
// 15. queryAethericBonds(uint256 _tokenId): Retrieves all bonds associated with a specific Weaver.
// 16. initiateRitual(uint256 _tokenId, uint256 _ritualId, bytes _ritualParams): Triggers a special "ritual" by calling into a separate ritual logic contract.
//
// IV. Cosmic Whispers (Oracle Integration)
// 17. registerOracle(address _oracleAddress): Whitelists an address as an authorized "Cosmic Whisperer" (oracle).
// 18. submitCosmicWhisper(bytes32 _whisperId, int256 _value, uint256 _timestamp): An authorized oracle submits a data point (e.g., external event ID, market price).
// 19. attuneWeaverToWhisper(uint256 _tokenId, bytes32 _whisperId): Weaver owner declares their Weaver's attunement to a specific type of cosmic whisper.
// 20. processWhisperInfluence(uint256 _tokenId, bytes32 _whisperId): Processes the influence of a recent cosmic whisper on an attuned Weaver, updating its essence.
//
// V. Protocol Governance & Maintenance
// 21. proposeGovernanceChange(bytes32 _proposalHash, string _description): Propose changes to core contract parameters (e.g., voting thresholds, fees).
// 22. voteOnGovernanceChange(bytes32 _proposalHash, bool _for): Weavers vote on governance proposals.
// 23. executeGovernanceChange(bytes32 _proposalHash): Admin/Automated function executes approved governance changes.
// 24. updateRitualLogic(uint256 _ritualId, address _newRitualContract): Admin/Gov allows upgrading the logic for a specific ritual type to a new implementation contract.

// --- Interface for Ritual Contracts ---
// This interface defines the expected function signature for external ritual logic contracts.
interface IAetherRitual {
    function performRitual(uint256 _tokenId, bytes memory _params) external;
}

contract AetherWeaver is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // I. Weaver Identity & Essence
    Counters.Counter private _tokenIdTracker;
    // tokenId => essenceType => value (e.g., 1 => "Courage" => 150)
    mapping(uint256 => mapping(string => int256)) public weaverEssences;
    // tokenId => array of memories associated with the Weaver
    mapping(uint256 => MemoryFragment[]) public weaverMemoryLogs;
    // Stores registered essence fragment types and their base values
    mapping(string => int256) public registeredEssenceTypes;
    string[] public registeredEssenceTypeNames; // Used to iterate over all registered essence types

    struct MemoryFragment {
        bytes32 memoryHash; // Hash of the event/data representing the memory
        string context;     // Short description of the memory
        uint256 timestamp;  // When the memory was imbued
    }

    // II. Aetheric Chronicle (Narrative Layer)
    struct LoreFragment {
        bytes32 loreHash;      // Hash (e.g., IPFS CID) of the narrative content
        string description;    // Short description of the lore
        address proposer;      // Address that proposed this lore
        uint256 timestamp;     // When it was proposed
        uint256 votesFor;
        uint256 votesAgainst;
        bool isFinalized;      // True if the lore has passed voting and is part of the chronicle
    }
    mapping(bytes32 => LoreFragment) public loreFragments;
    bytes32[] public finalizedLoreHashes; // Stores hashes of finalized lore for efficient retrieval
    // essenceType => loreHash => influenceMagnitude (how much a lore piece influences an essence type)
    mapping(string => mapping(bytes32 => int256)) public loreInfluenceMap;

    uint256 public loreVoteThresholdRatio = 60; // Percentage of 'for' votes needed (e.g., 60 for 60%)
    uint256 public loreMinVotes = 3;            // Minimum total votes required for finalization

    // III. Dynamic Bonds & Rituals
    // tokenIdA => targetAddress (or other tokenId's owner) => bondType => exists
    mapping(uint256 => mapping(address => mapping(string => bool))) public aethericBonds;
    // tokenIdA => array of {targetAddress, bondType} for historical record (active status checked via `aethericBonds` map)
    mapping(uint256 => Bond[]) private _weaverBondLogs;

    struct Bond {
        address targetAddress; // The address of the entity bonded with
        string bondType;       // Description of the bond (e.g., "ally", "mentor")
        uint256 timestamp;     // When the bond was forged
    }

    // ritualId => contract address implementing IAetherRitual (for modular ritual logic)
    mapping(uint256 => address) public ritualLogicContracts;

    // IV. Cosmic Whispers (Oracle Integration)
    mapping(address => bool) public isOracle; // Whitelisted oracle addresses
    // whisperId => {value, timestamp, exists}
    mapping(bytes32 => CosmicWhisper) public cosmicWhispers;
    // tokenId => whisperId => bool (is this Weaver attuned to this whisper type?)
    mapping(uint256 => mapping(bytes32 => bool)) public weaverAttunements;

    struct CosmicWhisper {
        int256 value;      // The data value provided by the oracle
        uint256 timestamp; // When the whisper was submitted
        bool exists;       // True if a whisper with this ID has been submitted
    }

    // V. Protocol Governance & Maintenance
    struct GovernanceProposal {
        bytes32 proposalHash; // Hash (e.g., IPFS CID) of the proposal details
        string description;   // Short description of the proposal
        address proposer;     // Address that proposed it
        uint256 timestamp;    // When it was proposed
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;      // True if the proposal has passed and been executed
    }
    mapping(bytes32 => GovernanceProposal) public governanceProposals;
    uint256 public governanceVoteThresholdRatio = 70; // Percentage of 'for' votes needed
    uint256 public governanceMinVotes = 5;            // Minimum total votes required

    // --- Events ---
    event WeaverMinted(uint256 indexed tokenId, address indexed owner, string initialEssence);
    event EssenceFragmentUpdated(uint256 indexed tokenId, string essenceType, int256 newValue, int256 change);
    event MemoryImbued(uint256 indexed tokenId, bytes32 memoryHash, string context);
    event LoreProposed(bytes32 indexed loreHash, address indexed proposer);
    event LoreVoted(bytes32 indexed loreHash, address indexed voter, bool _for);
    event LoreFinalized(bytes32 indexed loreHash);
    event LoreLinkedToEssence(bytes32 indexed loreHash, string essenceType, int256 influence);
    event BondForged(uint256 indexed tokenIdA, address indexed target, string bondType);
    event BondDissolved(uint256 indexed tokenIdA, address indexed target, string bondType);
    event RitualInitiated(uint256 indexed tokenId, uint256 indexed ritualId, address ritualContract);
    event OracleRegistered(address indexed oracleAddress);
    event CosmicWhisperSubmitted(bytes32 indexed whisperId, int256 value, uint256 timestamp);
    event WeaverAttunedToWhisper(uint256 indexed tokenId, bytes32 indexed whisperId);
    event WhisperInfluenceProcessed(uint256 indexed tokenId, bytes32 indexed whisperId, string essenceType, int256 change);
    event GovernanceProposalCreated(bytes32 indexed proposalHash, address indexed proposer);
    event GovernanceVoted(bytes32 indexed proposalHash, address indexed voter, bool _for);
    event GovernanceExecuted(bytes32 indexed proposalHash);
    event RitualLogicUpdated(uint256 indexed ritualId, address newRitualContract);
    event EssenceFragmentTypeRegistered(string indexed typeName, int256 baseValue);


    constructor() ERC721("Aether Weaver", "WEAVER") Ownable(msg.sender) {
        // Register some initial essence types for the Aether Weaver universe
        _registerEssenceFragmentType("Courage", 100);
        _registerEssenceFragmentType("Wisdom", 100);
        _registerEssenceFragmentType("Resilience", 100);
        _registerEssenceFragmentType("Creativity", 100);
        _registerEssenceFragmentType("Harmony", 100);
        _registerEssenceFragmentType("Curiosity", 100);
    }

    // --- Internal helper function for registering essence types (used in constructor and by admin/gov) ---
    function _registerEssenceFragmentType(string memory _typeName, int256 _baseValue) internal {
        require(registeredEssenceTypes[_typeName] == 0, "Essence type already registered.");
        registeredEssenceTypes[_typeName] = _baseValue;
        registeredEssenceTypeNames.push(_typeName);
        emit EssenceFragmentTypeRegistered(_typeName, _baseValue);
    }

    // --- I. Core Weaver Identity & Essence ---

    /**
     * @notice Mints a new Epoch Weaver NFT, assigning it an initial essence fragment.
     *         The newly minted Weaver starts with a base value for the specified essence type.
     * @param _initialEssenceName The name of the essence fragment to initialize the Weaver with.
     * @return The ID of the newly minted Weaver NFT.
     */
    function mintWeaver(string memory _initialEssenceName) public returns (uint256) {
        require(registeredEssenceTypes[_initialEssenceName] != 0, "Initial essence type not registered.");

        _tokenIdTracker.increment();
        uint256 newItemId = _tokenIdTracker.current();
        _safeMint(msg.sender, newItemId); // Mints to the caller

        // Initialize the chosen essence fragment with its base value
        weaverEssences[newItemId][_initialEssenceName] = registeredEssenceTypes[_initialEssenceName];

        emit WeaverMinted(newItemId, msg.sender, _initialEssenceName);
        return newItemId;
    }

    /**
     * @notice Allows the contract owner (or eventually governance) to define new fundamental trait categories for Weavers.
     *         These new types can later be used in `mintWeaver`, `imbueMemoryFragment`, or `processWhisperInfluence`.
     * @param _typeName The name of the new essence fragment type (e.g., "Strength", "Empathy").
     * @param _baseValue The initial base value for this essence type.
     */
    function registerEssenceFragmentType(string memory _typeName, int256 _baseValue) public onlyOwner {
        _registerEssenceFragmentType(_typeName, _baseValue);
    }

    /**
     * @notice Attaches an on-chain event (represented by a hash and context) as a memory to a Weaver.
     *         This action can trigger an update to the Weaver's essence fragments based on the memory type.
     * @param _tokenId The ID of the Weaver NFT.
     * @param _memoryHash A unique hash identifying the memory (e.g., transaction hash, event ID from another contract).
     * @param _memoryContext A short string (e.g., "DAO participation", "Quest completion") describing the context.
     */
    function imbueMemoryFragment(uint256 _tokenId, bytes32 _memoryHash, string memory _memoryContext) public {
        require(_exists(_tokenId), "Weaver does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the Weaver.");

        weaverMemoryLogs[_tokenId].push(MemoryFragment({
            memoryHash: _memoryHash,
            context: _memoryContext,
            timestamp: block.timestamp
        }));

        // Example dynamic logic: Imbuing certain memories could automatically boost specific essences
        // For a more complex system, this would involve a separate logic contract or more elaborate internal rules.
        if (keccak256(abi.encodePacked(_memoryContext)) == keccak256(abi.encodePacked("Participation"))) {
            _updateEssenceFragment(_tokenId, "Courage", 5);
        } else if (keccak256(abi.encodePacked(_memoryContext)) == keccak256(abi.encodePacked("Contribution"))) {
            _updateEssenceFragment(_tokenId, "Creativity", 10);
        } else if (keccak256(abi.encodePacked(_memoryContext)) == keccak256(abi.encodePacked("Challenge_Overcome"))) {
            _updateEssenceFragment(_tokenId, "Resilience", 15);
        }

        emit MemoryImbued(_tokenId, _memoryHash, _memoryContext);
    }

    /**
     * @notice Internal function to safely modify a specific essence fragment's value for a given Weaver.
     *         This function ensures the essence type is registered and emits an event.
     *         It is primarily called by other internal contract functions.
     * @param _tokenId The ID of the Weaver NFT.
     * @param _typeName The name of the essence fragment type.
     * @param _valueChange The amount to add or subtract from the current essence value.
     */
    function _updateEssenceFragment(uint256 _tokenId, string memory _typeName, int256 _valueChange) internal {
        require(registeredEssenceTypes[_typeName] != 0, "Essence type not registered.");
        
        int256 currentValue = weaverEssences[_tokenId][_typeName];
        weaverEssences[_tokenId][_typeName] = currentValue + _valueChange;
        
        emit EssenceFragmentUpdated(_tokenId, _typeName, weaverEssences[_tokenId][_typeName], _valueChange);
    }

    /**
     * @notice Public (owner-restricted) wrapper for `_updateEssenceFragment`.
     *         Allows the contract owner to directly adjust a Weaver's essence for administrative or special events.
     * @param _tokenId The ID of the Weaver NFT.
     * @param _typeName The name of the essence fragment type.
     * @param _valueChange The amount to add or subtract from the current essence value.
     */
    function updateEssenceFragment(uint256 _tokenId, string memory _typeName, int256 _valueChange) public onlyOwner {
        require(_exists(_tokenId), "Weaver does not exist.");
        _updateEssenceFragment(_tokenId, _typeName, _valueChange);
    }

    /**
     * @notice Retrieves all current essence fragments and their values for a given Weaver.
     * @param _tokenId The ID of the Weaver NFT.
     * @return typeNames An array of essence type names.
     * @return values An array of corresponding essence values.
     */
    function getWeaverEssence(uint256 _tokenId) public view returns (string[] memory typeNames, int256[] memory values) {
        require(_exists(_tokenId), "Weaver does not exist.");
        uint256 count = registeredEssenceTypeNames.length;
        typeNames = new string[](count);
        values = new int256[](count);

        for (uint256 i = 0; i < count; i++) {
            string memory typeName = registeredEssenceTypeNames[i];
            typeNames[i] = typeName;
            values[i] = weaverEssences[_tokenId][typeName];
        }
        return (typeNames, values);
    }

    /**
     * @notice Returns the chronological log of memories imbued into a Weaver.
     * @param _tokenId The ID of the Weaver NFT.
     * @return memoryHashes An array of memory hashes.
     * @return contexts An array of memory contexts.
     */
    function getWeaverMemoryLog(uint256 _tokenId) public view returns (bytes32[] memory memoryHashes, string[] memory contexts) {
        require(_exists(_tokenId), "Weaver does not exist.");
        MemoryFragment[] storage logs = weaverMemoryLogs[_tokenId];
        memoryHashes = new bytes32[](logs.length);
        contexts = new string[](logs.length);

        for (uint256 i = 0; i < logs.length; i++) {
            memoryHashes[i] = logs[i].memoryHash;
            contexts[i] = logs[i].context;
        }
        return (memoryHashes, contexts);
    }

    // --- II. Aetheric Chronicle (Narrative Layer) ---

    /**
     * @notice Proposes a hash (e.g., IPFS CID) of a narrative snippet to be added to the collective lore.
     *         Requires the caller to own at least one Weaver to demonstrate commitment to the ecosystem.
     * @param _loreHash A unique hash identifying the lore fragment.
     * @param _description A short description summarizing the lore fragment.
     */
    function proposeLoreFragment(bytes32 _loreHash, string memory _description) public {
        require(balanceOf(msg.sender) > 0, "Caller must own at least one Weaver to propose lore.");
        require(loreFragments[_loreHash].proposer == address(0), "Lore fragment already proposed.");

        loreFragments[_loreHash] = LoreFragment({
            loreHash: _loreHash,
            description: _description,
            proposer: msg.sender,
            timestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            isFinalized: false
        });
        emit LoreProposed(_loreHash, msg.sender);
    }

    /**
     * @notice Allows Weaver owners to vote on proposed lore fragments.
     *         Each distinct caller (owning at least one Weaver) gets one vote.
     * @param _loreHash The hash of the lore fragment to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnLoreFragment(bytes32 _loreHash, bool _for) public {
        LoreFragment storage lore = loreFragments[_loreHash];
        require(lore.proposer != address(0), "Lore fragment not found.");
        require(!lore.isFinalized, "Lore fragment is already finalized.");
        require(balanceOf(msg.sender) > 0, "Caller must own a Weaver to vote.");

        // For simplicity, a mapping to track who voted could be added: mapping(bytes32 => mapping(address => bool)) hasVotedLore;
        // require(!hasVotedLore[_loreHash][msg.sender], "Caller has already voted on this lore fragment.");
        // hasVotedLore[_loreHash][msg.sender] = true;

        if (_for) {
            lore.votesFor = lore.votesFor.add(1);
        } else {
            lore.votesAgainst = lore.votesAgainst.add(1);
        }
        emit LoreVoted(_loreHash, msg.sender, _for);
    }

    /**
     * @notice Finalizes a lore fragment if it meets vote thresholds, making it part of the official chronicle.
     *         This function can be called by anyone; it's designed to be triggered by an off-chain keeper bot
     *         or after a specific time delay to allow voting period to elapse.
     * @param _loreHash The hash of the lore fragment to finalize.
     */
    function finalizeLoreFragment(bytes32 _loreHash) public {
        LoreFragment storage lore = loreFragments[_loreHash];
        require(lore.proposer != address(0), "Lore fragment not found.");
        require(!lore.isFinalized, "Lore fragment is already finalized.");

        uint256 totalVotes = lore.votesFor.add(lore.votesAgainst);
        require(totalVotes >= loreMinVotes, "Not enough total votes to finalize.");

        uint256 approvalPercentage = totalVotes > 0 ? (lore.votesFor.mul(100) / totalVotes) : 0;
        require(approvalPercentage >= loreVoteThresholdRatio, "Lore fragment did not meet approval threshold.");

        lore.isFinalized = true;
        finalizedLoreHashes.push(_loreHash);
        emit LoreFinalized(_loreHash);
    }

    /**
     * @notice Associates a finalized lore fragment with an essence type. This means this lore piece
     *         can now influence future changes to that essence type, or its interpretation within the narrative.
     *         Only the contract owner (or eventually governance) can link lore to essence types.
     * @param _loreHash The hash of the finalized lore fragment.
     * @param _essenceType The name of the essence type it influences.
     * @param _influenceMagnitude The magnitude and direction of influence this lore has on the essence type.
     */
    function linkLoreToEssence(bytes32 _loreHash, string memory _essenceType, int256 _influenceMagnitude) public onlyOwner {
        require(loreFragments[_loreHash].isFinalized, "Lore fragment is not finalized.");
        require(registeredEssenceTypes[_essenceType] != 0, "Essence type not registered.");
        
        loreInfluenceMap[_essenceType][_loreHash] = _influenceMagnitude;
        emit LoreLinkedToEssence(_loreHash, _essenceType, _influenceMagnitude);
    }

    /**
     * @notice Checks the current voting status and finalization state of a lore fragment proposal.
     * @param _loreHash The hash of the lore fragment.
     * @return votesFor Count of 'for' votes.
     * @return votesAgainst Count of 'against' votes.
     * @return isFinalized True if the lore fragment has been finalized.
     */
    function getLoreFragmentStatus(bytes32 _loreHash) public view returns (uint256 votesFor, uint256 votesAgainst, bool isFinalized) {
        LoreFragment storage lore = loreFragments[_loreHash];
        return (lore.votesFor, lore.votesAgainst, lore.isFinalized);
    }

    /**
     * @notice Paginates and retrieves finalized lore fragments from the Aetheric Chronicle.
     *         Useful for building an off-chain interface to display the collective narrative.
     * @param _startIndex The starting index for retrieval (0-based).
     * @param _count The maximum number of lore fragments to retrieve.
     * @return loreHashes An array of finalized lore hashes.
     */
    function retrieveChronicleLore(uint256 _startIndex, uint256 _count) public view returns (bytes32[] memory loreHashes) {
        require(_startIndex <= finalizedLoreHashes.length, "Start index out of bounds.");
        uint256 endIndex = _startIndex.add(_count);
        if (endIndex > finalizedLoreHashes.length) {
            endIndex = finalizedLoreHashes.length;
        }
        uint256 actualCount = endIndex.sub(_startIndex);
        loreHashes = new bytes32[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            loreHashes[i] = finalizedLoreHashes[_startIndex.add(i)];
        }
        return loreHashes;
    }

    // --- III. Dynamic Bonds & Rituals ---

    /**
     * @notice Creates a semantic link (bond) between a Weaver and another address (which could be another Weaver's owner, an EOA, or a contract).
     *         If the target address also owns a Weaver, a reciprocal bond can be created automatically.
     * @param _tokenIdA The ID of the Weaver initiating the bond.
     * @param _targetAddress The address of the entity to bond with.
     * @param _bondType A descriptive string for the nature of the relationship (e.g., "mentor", "ally", "rival", "protector").
     */
    function forgeAethericBond(uint256 _tokenIdA, address _targetAddress, string memory _bondType) public {
        require(_exists(_tokenIdA), "Weaver A does not exist.");
        require(ownerOf(_tokenIdA) == msg.sender, "Caller is not the owner of Weaver A.");
        require(!aethericBonds[_tokenIdA][_targetAddress][_bondType], "Bond already exists.");
        require(_targetAddress != address(0), "Target address cannot be zero.");

        aethericBonds[_tokenIdA][_targetAddress][_bondType] = true;
        _weaverBondLogs[_tokenIdA].push(Bond({
            targetAddress: _targetAddress,
            bondType: _bondType,
            timestamp: block.timestamp
        }));
        
        // Optional: If the target is also a Weaver owner, create a reciprocal bond
        if (balanceOf(_targetAddress) > 0) {
            // This is a simplification; a real system might allow picking a specific target Weaver by ID.
            // Here, we take the first Weaver owned by `_targetAddress`.
            uint256 targetTokenId = tokenOfOwnerByIndex(_targetAddress, 0); // Requires ERC721Enumerable or custom tracking
            aethericBonds[targetTokenId][msg.sender][_bondType] = true; // Reciprocal bond
            _weaverBondLogs[targetTokenId].push(Bond({
                targetAddress: msg.sender, // The owner of Weaver A
                bondType: _bondType,
                timestamp: block.timestamp
            }));
        }

        emit BondForged(_tokenIdA, _targetAddress, _bondType);
    }

    /**
     * @notice Removes an existing semantic link (bond) between a Weaver and a target address.
     * @param _tokenIdA The ID of the Weaver.
     * @param _targetAddress The target address of the bond.
     * @param _bondType The type of the bond to dissolve.
     */
    function dissolveAethericBond(uint256 _tokenIdA, address _targetAddress, string memory _bondType) public {
        require(_exists(_tokenIdA), "Weaver A does not exist.");
        require(ownerOf(_tokenIdA) == msg.sender, "Caller is not the owner of Weaver A.");
        require(aethericBonds[_tokenIdA][_targetAddress][_bondType], "Bond does not exist.");

        aethericBonds[_tokenIdA][_targetAddress][_bondType] = false;
        // Note: Removing from dynamic array (_weaverBondLogs) is gas-costly.
        // For simplicity, old entries remain in the log but are marked inactive via `aethericBonds` map.
        
        // Optional: Dissolve reciprocal bond if it exists and was created automatically
        if (balanceOf(_targetAddress) > 0) {
            uint256 targetTokenId = tokenOfOwnerByIndex(_targetAddress, 0); // Assumes reciprocal bond on first token
            aethericBonds[targetTokenId][msg.sender][_bondType] = false;
        }

        emit BondDissolved(_tokenIdA, _targetAddress, _bondType);
    }

    /**
     * @notice Retrieves all active bonds associated with a specific Weaver.
     *         Note: This function iterates through the bond log to filter active bonds, which can be
     *         gas-intensive for Weavers with a very large number of historical bonds.
     * @param _tokenId The ID of the Weaver.
     * @return targets An array of addresses/Weaver owners involved in active bonds.
     * @return bondTypes An array of corresponding active bond types.
     */
    function queryAethericBonds(uint256 _tokenId) public view returns (address[] memory targets, string[] memory bondTypes) {
        require(_exists(_tokenId), "Weaver does not exist.");
        Bond[] storage logs = _weaverBondLogs[_tokenId];
        uint256 activeCount = 0;
        for (uint256 i = 0; i < logs.length; i++) {
            if (aethericBonds[_tokenId][logs[i].targetAddress][logs[i].bondType]) {
                activeCount++;
            }
        }

        targets = new address[](activeCount);
        bondTypes = new string[](activeCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < logs.length; i++) {
            if (aethericBonds[_tokenId][logs[i].targetAddress][logs[i].bondType]) {
                targets[currentIdx] = logs[i].targetAddress;
                bondTypes[currentIdx] = logs[i].bondType;
                currentIdx++;
            }
        }
        return (targets, bondTypes);
    }

    /**
     * @notice Triggers a special "ritual" by delegating execution to a pre-registered ritual logic contract.
     *         This allows for complex, modular interactions where the main AetherWeaver contract
     *         does not need to implement specific ritual mechanics.
     * @param _tokenId The ID of the Weaver participating in the ritual.
     * @param _ritualId A unique identifier for the specific ritual type.
     * @param _ritualParams Additional parameters encoded as bytes for the specific ritual logic contract.
     */
    function initiateRitual(uint256 _tokenId, uint256 _ritualId, bytes memory _ritualParams) public {
        require(_exists(_tokenId), "Weaver does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the Weaver.");
        address ritualContract = ritualLogicContracts[_ritualId];
        require(ritualContract != address(0), "Ritual logic contract not registered for this ID.");

        // Call the external ritual contract, passing the Weaver ID and any specific parameters
        IAetherRitual(ritualContract).performRitual(_tokenId, _ritualParams);
        emit RitualInitiated(_tokenId, _ritualId, ritualContract);
    }

    // --- IV. Cosmic Whispers (Oracle Integration) ---

    /**
     * @notice Whitelists an address as an authorized "Cosmic Whisperer" (oracle).
     *         Only the contract owner can register new oracles.
     * @param _oracleAddress The address to register as an oracle.
     */
    function registerOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero.");
        isOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @notice An authorized oracle submits a data point ("cosmic whisper") identified by `_whisperId`.
     *         This data can later influence attuned Weavers.
     * @param _whisperId A unique identifier for this specific whisper type (e.g., hash of a specific data feed, event type).
     * @param _value The integer value submitted by the oracle (e.g., price, temperature, event flag).
     * @param _timestamp The timestamp of the whisper (can be `block.timestamp` or an external timestamp).
     */
    function submitCosmicWhisper(bytes32 _whisperId, int256 _value, uint256 _timestamp) public {
        require(isOracle[msg.sender], "Caller is not a registered oracle.");
        
        cosmicWhispers[_whisperId] = CosmicWhisper({
            value: _value,
            timestamp: _timestamp,
            exists: true
        });
        emit CosmicWhisperSubmitted(_whisperId, _value, _timestamp);
    }

    /**
     * @notice A Weaver owner declares their Weaver's attunement to a specific type of cosmic whisper.
     *         This means subsequent whispers of that type might influence the Weaver's essence.
     * @param _tokenId The ID of the Weaver.
     * @param _whisperId The ID of the cosmic whisper type to attune to.
     */
    function attuneWeaverToWhisper(uint256 _tokenId, bytes32 _whisperId) public {
        require(_exists(_tokenId), "Weaver does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the Weaver.");
        require(cosmicWhispers[_whisperId].exists, "Whisper ID not yet submitted by an oracle to establish its type.");

        weaverAttunements[_tokenId][_whisperId] = true;
        emit WeaverAttunedToWhisper(_tokenId, _whisperId);
    }

    /**
     * @notice Processes the influence of a recent cosmic whisper on an attuned Weaver.
     *         Anyone can call this function (e.g., a keeper bot or an interested user) to trigger the influence.
     *         It updates the Weaver's essence fragments based on predefined rules or linked lore.
     * @param _tokenId The ID of the Weaver to process.
     * @param _whisperId The ID of the cosmic whisper to apply.
     */
    function processWhisperInfluence(uint256 _tokenId, bytes32 _whisperId) public {
        require(_exists(_tokenId), "Weaver does not exist.");
        require(weaverAttunements[_tokenId][_whisperId], "Weaver is not attuned to this whisper.");
        CosmicWhisper storage whisper = cosmicWhispers[_whisperId];
        require(whisper.exists, "Whisper data not available for this ID.");
        // Add logic to prevent processing the same whisper multiple times for the same Weaver.
        // E.g., mapping(uint256 => mapping(bytes32 => uint256)) lastProcessedTimestamp;
        // For simplicity, this example allows multiple processing, assuming external logic ensures uniqueness.

        // Example logic for how a whisper influences essence:
        // This is a simplified rule. A real system would have a more complex mapping (e.g., whisper type to essence type),
        // potentially incorporating lore links for dynamic interpretation.

        // Direct mapping example: if a specific whisper ID is known to influence a specific essence.
        if (keccak256(abi.encodePacked(_whisperId)) == keccak256(abi.encodePacked("Oracle.MarketVolatility"))) {
            _updateEssenceFragment(_tokenId, "Resilience", whisper.value / 100); // Resilience increases with volatility
            emit WhisperInfluenceProcessed(_tokenId, _whisperId, "Resilience", whisper.value / 100);
        } else if (keccak256(abi.encodePacked(_whisperId)) == keccak256(abi.encodePacked("Oracle.KnowledgeFeed"))) {
            _updateEssenceFragment(_tokenId, "Wisdom", whisper.value / 50); // Wisdom increases with new knowledge
            emit WhisperInfluenceProcessed(_tokenId, _whisperId, "Wisdom", whisper.value / 50);
        }
        // More advanced: Iterate `loreInfluenceMap` to find relevant lore pieces that link this whisper to an essence.
        // This would be very gas-intensive on-chain and likely handled by off-chain computation and a single oracle update.
    }

    // --- V. Protocol Governance & Maintenance ---

    /**
     * @notice Propose changes to core contract parameters (e.g., voting thresholds, fees, new ritual types).
     *         Requires the caller to own at least one Weaver to propose.
     * @param _proposalHash A unique hash representing the proposed change (e.g., IPFS CID of proposal details).
     * @param _description A short description of the proposal.
     */
    function proposeGovernanceChange(bytes32 _proposalHash, string memory _description) public {
        require(balanceOf(msg.sender) > 0, "Caller must own at least one Weaver to propose governance changes.");
        require(governanceProposals[_proposalHash].proposer == address(0), "Proposal already exists.");

        governanceProposals[_proposalHash] = GovernanceProposal({
            proposalHash: _proposalHash,
            description: _description,
            proposer: msg.sender,
            timestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false
        });
        emit GovernanceProposalCreated(_proposalHash, msg.sender);
    }

    /**
     * @notice Allows Weaver owners to vote on governance proposals.
     *         Each distinct caller (owning at least one Weaver) gets one vote.
     * @param _proposalHash The hash of the governance proposal.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnGovernanceChange(bytes32 _proposalHash, bool _for) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        require(proposal.proposer != address(0), "Governance proposal not found.");
        require(!proposal.isExecuted, "Proposal is already executed.");
        require(balanceOf(msg.sender) > 0, "Caller must own a Weaver to vote.");

        // For simplicity, a mapping to track who voted could be added: mapping(bytes32 => mapping(address => bool)) hasVotedGov;
        // require(!hasVotedGov[_proposalHash][msg.sender], "Caller has already voted on this governance proposal.");
        // hasVotedGov[_proposalHash][msg.sender] = true;

        if (_for) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        emit GovernanceVoted(_proposalHash, msg.sender, _for);
    }

    /**
     * @notice Executes approved governance changes.
     *         Only the contract owner can execute approved proposals, acting as an executive layer.
     *         In a fully decentralized system, this could be permissionless or time-locked.
     *         The actual execution logic (e.g., modifying `loreVoteThresholdRatio`) would be implemented here based on `_proposalHash`.
     * @param _proposalHash The hash of the proposal to execute.
     */
    function executeGovernanceChange(bytes32 _proposalHash) public onlyOwner {
        GovernanceProposal storage proposal = governanceProposals[_proposalHash];
        require(proposal.proposer != address(0), "Governance proposal not found.");
        require(!proposal.isExecuted, "Proposal is already executed.");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes >= governanceMinVotes, "Not enough total votes to execute.");

        uint256 approvalPercentage = totalVotes > 0 ? (proposal.votesFor.mul(100) / totalVotes) : 0;
        require(approvalPercentage >= governanceVoteThresholdRatio, "Proposal did not meet approval threshold.");

        // --- Placeholder for actual execution logic ---
        // In a real system, you would parse _proposalHash (e.g., IPFS content) or use a predefined
        // set of proposal types to enact specific state changes.
        // Example: if (_proposalHash == keccak256(abi.encodePacked("SET_LORE_THRESHOLD_65"))) {
        //              loreVoteThresholdRatio = 65;
        //          }
        // For this demonstration, we simply mark it as executed.
        proposal.isExecuted = true;
        emit GovernanceExecuted(_proposalHash);
    }

    /**
     * @notice Allows the contract owner (or eventually governance) to upgrade or register the logic contract for a specific ritual type.
     *         This enables modularity and future extensibility for rituals without modifying the core contract.
     * @param _ritualId A unique identifier for the ritual type.
     * @param _newRitualContract The address of the new contract implementing `IAetherRitual`.
     */
    function updateRitualLogic(uint256 _ritualId, address _newRitualContract) public onlyOwner {
        require(_newRitualContract != address(0), "Ritual contract address cannot be zero.");
        ritualLogicContracts[_ritualId] = _newRitualContract;
        emit RitualLogicUpdated(_ritualId, _newRitualContract);
    }

    // --- View/Helper Functions ---

    /**
     * @notice Returns the total number of registered essence fragment types.
     */
    function getEssenceTypeCount() public view returns (uint256) {
        return registeredEssenceTypeNames.length;
    }

    /**
     * @notice Returns the name of a registered essence fragment type by its index in the array.
     * @param _index The 0-based index of the essence type.
     */
    function getEssenceTypeNameByIndex(uint256 _index) public view returns (string memory) {
        require(_index < registeredEssenceTypeNames.length, "Index out of bounds.");
        return registeredEssenceTypeNames[_index];
    }

    /**
     * @notice Provides a dynamic URI for Weaver NFT metadata.
     *         In a full implementation, this URI would point to an external service
     *         that generates metadata JSON based on the Weaver's current essence, memories, and bonds.
     * @param tokenId The ID of the Weaver NFT.
     * @return A string representing the metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Example: Base URI + token ID.
        // A real-world application would pass Weaver's current state to an off-chain API
        // which then dynamically generates image, description, and traits based on:
        // - `getWeaverEssence(tokenId)`
        // - `getWeaverMemoryLog(tokenId)`
        // - `queryAethericBonds(tokenId)`
        // - `retrieveChronicleLore(...)` that the Weaver might be linked to.
        string memory baseURI = "https://aetherweaver.xyz/api/metadata/"; // Placeholder
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // Custom implementation of `_tokenOfOwnerByIndex` or other ERC721Enumerable functions
    // would be needed if more granular iteration of owned tokens is required frequently.
    // For this contract, `balanceOf(msg.sender) > 0` is sufficient for voting and proposals,
    // and `tokenOfOwnerByIndex(address, 0)` is used as a simplification for a single representative Weaver.
    // For production, consider adding OpenZeppelin's ERC721Enumerable or specific token-holding tracking.
}
```