This smart contract, "Aetherial Genesis Engine (AGE)," introduces a novel approach to dynamic NFTs (dNFTs) by integrating AI oracle-guided evolution, a "soulbound enhancer" reputation system, and on-chain governance. Aetherials are living digital entities whose traits can change over time based on external data, AI suggestions, user actions, and global "environmental shifts." The contract is designed to be interesting, advanced, creative, and trendy by combining multiple cutting-edge concepts without directly duplicating existing open-source projects for its core logic.

---

## Outline & Function Summary

**I. Core NFT Management (ERC721 Standard + Dynamic URI)**
These functions handle the fundamental ownership and metadata of the Aetherial NFTs, extending ERC721 with dynamic URI generation.

1.  `mintGenesisAetherial(address to, AetherialTrait[] memory initialTraits)`: Mints a new Aetherial NFT, initializing its base traits and assigning it to `to`. Callable only by the contract owner (initially, then potentially DAO).
2.  `balanceOf(address owner) view returns (uint256)`: Returns the number of NFTs owned by an address. (ERC721 standard)
3.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of a given NFT. (ERC721 standard)
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers an NFT from one address to another. (ERC721 standard)
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers an NFT, checking if the recipient can receive ERC721 tokens. (ERC721 standard)
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers an NFT with additional data. (ERC721 standard)
7.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific NFT on behalf of the owner. (ERC721 standard)
8.  `getApproved(uint256 tokenId) view returns (address)`: Returns the approved address for a given NFT. (ERC721 standard)
9.  `setApprovalForAll(address operator, bool approved)`: Grants or revokes approval for an operator to manage all NFTs owned by the sender. (ERC721 standard)
10. `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks if an operator is approved for all NFTs of an owner. (ERC721 standard)
11. `tokenURI(uint256 tokenId) view returns (string memory)`: Generates and returns a dynamic metadata URI for the NFT based on its current traits, evolution stage, and other on-chain data.

**II. Dynamic Trait Management & Evolution**
These functions govern how Aetherial NFTs change and evolve, integrating external AI insights and manual adjustments.

12. `requestEvolutionPath(uint256 tokenId)`: Initiates an AI oracle request for the evolution of a specific NFT. Requires payment in "Aether" tokens and is callable by the NFT owner.
13. `fulfillEvolutionPath(uint256 tokenId, bytes memory newTraitsData)`: A callback function, exclusively callable by the configured AI Oracle, to update an NFT's traits based on the oracle's output.
14. `mutateTraitManually(uint256 tokenId, uint256 traitIndex, uint256 newValue, bytes memory metadata)`: Allows an owner to directly adjust a specific trait within predefined boundaries, consuming "Aether" tokens.
15. `getAetherialTraits(uint256 tokenId) view returns (AetherialTrait[] memory)`: Returns the current structured traits (e.g., Physical, Energetic, Cognitive) of a specific Aetherial NFT.
16. `triggerEnvironmentalShift(bytes memory shiftData)`: Admin/DAO function to announce a global environmental event. This event can affect all Aetherials, with owners needing to `applyLatestEnvironmentalShift`.
17. `applyLatestEnvironmentalShift(uint256 tokenId)`: Allows an NFT owner (or automated system) to apply the latest global environmental shift effects to their specific NFT, updating its traits if applicable.
18. `getLatestEnvironmentalShiftId() view returns (uint256)`: Returns the ID of the most recently triggered environmental shift.
19. `getEvolutionHistory(uint256 tokenId) view returns (EvolutionLogEntry[] memory)`: Retrieves the full, immutable log of how an NFT's traits have changed over time.

**III. Reputation & "Aether Shards" (Soulbound Enhancers)**
This set of functions introduces a unique "soulbound enhancer" system where non-transferable "Aether Shards" linked to a wallet can unlock special traits on *any* transferable Aetherial NFT owned by that wallet.

20. `mintAetherShard(address to, uint256 shardType)`: Mints a non-transferable "Aether Shard" to a wallet address. This is typically triggered by off-chain or on-chain achievements.
21. `getAetherShardsForWallet(address wallet) view returns (bool[] memory)`: Returns a boolean array indicating which types of Aether Shards a specific wallet holds.
22. `activateReputationTrait(uint256 tokenId, uint256 requiredShardType, uint256 traitIndex, uint256 newValue)`: Allows an NFT owner to activate a special trait on their Aetherial if their wallet holds the required `AetherShard`.
23. `deactivateReputationTrait(uint256 tokenId, uint256 traitIndex)`: Deactivates a previously activated reputation-bound trait, reverting it to its default (inactive) value.

**IV. AI Oracle Integration & Configuration**
Functions for setting up and managing the trusted AI Oracle that guides NFT evolution.

24. `setAIOracleAddress(address _oracleAddress)`: Admin/DAO function to set the address of the trusted AI Oracle contract.
25. `setEvolutionModelParameters(bytes memory newParameters)`: Admin/DAO function to update parameters that the AI Oracle uses for its evolution logic, allowing for dynamic tuning.
26. `getEvolutionModelParameters() view returns (bytes memory)`: Retrieves the currently configured evolution model parameters.

**V. Governance & System Parameters (Simplified DAO-like functions)**
A basic framework for community governance over the contract's parameters.

27. `proposeParameterChange(string memory description, bytes memory callData, address targetContract)`: Allows users to propose changes to system parameters or call arbitrary functions on the contract itself or other target contracts.
28. `voteOnProposal(uint256 proposalId, bool support)`: Allows eligible participants (e.g., token holders, NFT owners) to vote on active proposals. (Simplified to 1-wallet-1-vote for demonstration).
29. `executeProposal(uint256 proposalId)`: Executes a proposal that has successfully met its voting quorum and passed its voting period.
30. `setTraitCategoryBounds(uint256 traitType, uint256 min, uint256 max)`: Admin/DAO function to define the permissible minimum and maximum values for specific trait categories, ensuring valid mutations.
31. `addApprovedDataFeed(address dataFeedAddress)`: Admin/DAO function to whitelist addresses of external data feeds that the AI oracle is permitted to query for evolutionary input.

**VI. Aether Token Integration (Hypothetical ERC20 for payments)**
Functions to integrate a dedicated ERC20 token ("Aether") for transactions within the AGE ecosystem.

32. `setAetherTokenAddress(address _aetherTokenAddress)`: Admin function to set the address of the Aether ERC20 token contract.
33. `setEvolutionCost(uint256 _cost)`: Admin/DAO function to set the cost (in Aether tokens) for requesting an evolution path from the AI oracle.
34. `getEvolutionCost() view returns (uint256)`: Returns the current cost for an evolution request.
35. `withdrawFees(address recipient, uint256 amount)`: Allows the owner/DAO to withdraw accumulated Aether token fees collected by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Minimal Base64 encoding utility (from OpenZeppelin's ERC721URIStorage)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        // data length is at most 2^128 - 1, so 30 bytes is enough to store it
        assembly {
            let dataLen := mload(data)
            let outputLen := div(add(mul(4, dataLen), 2), 3)
            mstore(0x40, add(outputLen, 1))
        }
        string memory output;
        assembly { output := 0x40 }

        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 input;
            assembly { input := mload(add(data, add(0x20, i))) }

            assembly {
                let d := add(output, add(0x20, div(mul(4, i), 3)))
                mstore8(d, byte(shl(24, and(input, 0xFC000000)), table))
                mstore8(add(d, 1), byte(shl(24, and(input, 0x03F00000)), table))
                mstore8(add(d, 2), byte(shl(24, and(input, 0x000FC000)), table))
                mstore8(add(d, 3), byte(shl(24, and(input, 0x00003F00)), table))
            }
        }

        switch (data.length % 3) {
            case 1:
                assembly {
                    let d := add(output, add(0x20, mul(4, div(data.length, 3))))
                    mstore8(add(d, 2), 0x3d) // '='
                    mstore8(add(d, 3), 0x3d) // '='
                }
            case 2:
                assembly {
                    let d := add(output, add(0x20, mul(4, div(data.length, 3))))
                    mstore8(add(d, 3), 0x3d) // '='
                }
        }

        return output;
    }
}

// Interfaces for external contracts (AI Oracle, Aether ERC20)
interface IAIOracle {
    // requestEvolution returns a requestId which would typically be used to map
    // an external oracle query to an on-chain callback.
    // In a real system, the oracle would then call a specific `fulfill` function on this contract,
    // passing the requestId to verify the origin.
    function requestEvolution(uint256 tokenId, bytes memory currentTraitsData) external returns (bytes32 requestId);
    
    // This function on the oracle would be a placeholder for its internal logic
    // and would NOT be called by the AGE contract directly.
    // function fulfill(bytes32 requestId, bytes memory newTraitsData) external;
}

interface IAetherToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Aetherial Genesis Engine (AGE)
 * @dev A dynamic NFT platform where "Aetherial" NFTs evolve based on AI oracle guidance,
 *      on-chain actions, and a novel "Soulbound Enhancer" system. The platform aims to
 *      create deeply interactive and unique digital entities.
 */
contract AetherialGenesisEngine is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _nextEnvironmentalShiftId; // Global counter for environmental shifts
    Counters.Counter private _nextProposalId; // Global counter for governance proposals

    // --- Configuration Variables ---
    address private _aiOracleAddress;
    address private _aetherTokenAddress; // Address of a hypothetical ERC20 token used for payments
    bytes private _evolutionModelParameters; // Parameters passed to the AI oracle for its logic
    uint256 private _evolutionCost; // Cost in Aether tokens for an evolution request

    // --- Data Structures ---

    enum TraitCategory {
        Physical,
        Energetic,
        Cognitive,
        Reputational, // Special traits unlocked by Aether Shards
        Environmental // Traits influenced by global shifts
    }

    struct AetherialTrait {
        uint256 id; // A unique ID for the trait within its category or globally
        TraitCategory category;
        uint256 value; // E.g., a score, index, or percentage
        string description; // E.g., "Strength", "Aura Color", "Processing Power"
        bool isReputationBound; // True if this trait requires an Aether Shard to activate
        uint256 reputationShardType; // The type of shard required if isReputationBound is true
    }

    struct Aetherial {
        AetherialTrait[] traits;
        uint256 lastEvolutionTimestamp;
        uint256 evolutionStage; // E.g., 0 for Genesis, 1 for Evolved, etc.
        bytes32 pendingEvolutionRequestId; // Stores the request ID for an ongoing oracle request
        uint256 lastEnvironmentalShiftId; // To track if affected by latest global shift
    }

    struct EvolutionLogEntry {
        uint256 timestamp;
        string trigger; // "UserRequest", "AIOracle", "EnvironmentalShift", "ManualMutation", "ReputationActivation", "ReputationDeactivation", "GenesisMint"
        bytes oldTraitsHash; // Hash or abi.encode of the traits before change
        bytes newTraitsHash; // Hash or abi.encode of the traits after change
        string details; // Optional details like "requested by X", "environmental shift Y"
    }

    struct TraitBounds {
        uint256 min;
        uint256 max;
    }

    // Governance (Simplified)
    struct Proposal {
        uint256 id;
        string description;
        bytes callData; // Encoded function call
        address targetContract; // Contract to call (can be `address(this)` for self-modification)
        uint256 voteCount;
        uint256 creationTime;
        bool executed;
        bool passed;
    }

    // --- Mappings ---
    mapping(uint256 => Aetherial) private _aetherials; // tokenId => Aetherial data
    mapping(uint256 => EvolutionLogEntry[]) private _evolutionHistory; // tokenId => Array of log entries
    mapping(address => mapping(uint256 => bool)) private _aetherShards; // wallet => shardType => hasShard (soulbound enhancers)
    mapping(uint256 => TraitBounds) private _traitCategoryBounds; // TraitCategory => Bounds for trait values
    mapping(address => bool) private _approvedDataFeeds; // Address => isApproved for direct oracle interaction (if any)

    // Governance mappings
    mapping(uint256 => Proposal) private _proposals; // proposalId => Proposal data
    mapping(address => mapping(uint256 => bool)) private _hasVotedOnProposal; // voterAddress => proposalId => hasVoted
    uint256 private constant PROPOSAL_VOTE_THRESHOLD = 3; // Minimum votes to pass (simplified for demo)
    uint256 private constant VOTING_PERIOD_DAYS = 3; // Voting period for proposals

    // --- Events ---
    event AetherialMinted(uint256 indexed tokenId, address indexed owner, string initialTraitsJson);
    event EvolutionRequested(uint256 indexed tokenId, address indexed requester, bytes32 requestId);
    event EvolutionFulfilled(uint256 indexed tokenId, bytes newTraitsData);
    event TraitManuallyMutated(uint256 indexed tokenId, uint256 traitIndex, uint256 oldValue, uint256 newValue, address indexed mutator);
    event EnvironmentalShiftTriggered(uint256 indexed shiftId, bytes shiftData, uint256 affectedAetherials);
    event AetherShardMinted(address indexed wallet, uint256 indexed shardType);
    event ReputationTraitActivated(uint256 indexed tokenId, address indexed owner, uint256 traitIndex, uint256 requiredShardType);
    event ReputationTraitDeactivated(uint256 indexed tokenId, address indexed owner, uint256 traitIndex);
    event AIOracleAddressSet(address indexed newAddress);
    event EvolutionModelParametersUpdated(bytes newParameters);
    event EvolutionCostUpdated(uint256 newCost);
    event TraitCategoryBoundsSet(uint256 indexed traitType, uint256 min, uint256 max);
    event ApprovedDataFeedAdded(address indexed dataFeedAddress);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer, uint256 creationTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AetherTokenAddressSet(address indexed newAddress);
    event FeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == _aiOracleAddress, "AGE: Only AI Oracle can call this function");
        _;
    }

    modifier onlyApprovedDataFeed() {
        require(_approvedDataFeeds[msg.sender], "AGE: Caller is not an approved data feed");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        _nextProposalId.increment(); // Start from 1
        _nextEnvironmentalShiftId.increment(); // Start from 1

        _evolutionCost = 1 ether; // Default cost, can be changed by governance

        // Set some default trait category bounds
        _traitCategoryBounds[uint256(TraitCategory.Physical)] = TraitBounds(0, 100);
        _traitCategoryBounds[uint256(TraitCategory.Energetic)] = TraitBounds(0, 1000);
        _traitCategoryBounds[uint256(TraitCategory.Cognitive)] = TraitBounds(0, 500);
        // Reputation and Environmental traits might not use min/max bounds directly,
        // or have specific logic for their values.
    }

    // I. Core NFT Management

    /**
     * @dev Mints a new Aetherial NFT, initializing its base traits.
     *      Callable only by the contract owner.
     * @param to The address to mint the NFT to.
     * @param initialTraits An array of `AetherialTrait` structs representing the NFT's genesis traits.
     */
    function mintGenesisAetherial(address to, AetherialTrait[] memory initialTraits) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);
        
        Aetherial memory newAetherial;
        newAetherial.traits = initialTraits;
        newAetherial.lastEvolutionTimestamp = block.timestamp;
        newAetherial.evolutionStage = 0;
        newAetherial.lastEnvironmentalShiftId = 0; // No shift applied yet

        _aetherials[newItemId] = newAetherial;

        // Set initial URI (could be a generic genesis URI or generated dynamically)
        _setTokenURI(newItemId, _generateTokenURI(newItemId));

        _addEvolutionLogEntry(
            newItemId,
            "GenesisMint",
            bytes(""), // No old traits
            abi.encode(initialTraits),
            "Initial creation of Aetherial"
        );

        emit AetherialMinted(newItemId, to, _getTraitsJson(initialTraits));
    }

    /**
     * @dev Generates and returns a dynamic URI for the NFT based on its current traits and metadata.
     * @param tokenId The ID of the NFT.
     * @return A data URI containing base64 encoded JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _generateTokenURI(tokenId);
    }

    /**
     * @dev Helper to generate dynamic JSON metadata for a given Aetherial.
     */
    function _generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        Aetherial storage aetherial = _aetherials[tokenId];
        
        string memory traitsJson = _getTraitsJson(aetherial.traits);

        // Construct a simple base64 encoded JSON string
        // A real implementation might use a more robust JSON library or off-chain generation for complex metadata.
        string memory json = string.concat(
            '{"name": "Aetherial #', tokenId.toString(),
            '", "description": "A dynamic Aetherial entity, evolving through AI and on-chain actions.",',
            '"image": "ipfs://QmVQ92hW2yB7w8W9Q4j1jY2G6w6Q3x5j4Q1q2R3s4T5u6/placeholder.png",', // Placeholder image, ideally dynamic
            '"attributes": ', traitsJson,
            ', "evolution_stage": ', aetherial.evolutionStage.toString(),
            ', "last_evolution": ', aetherial.lastEvolutionTimestamp.toString(),
            ', "last_environmental_shift": ', aetherial.lastEnvironmentalShiftId.toString(),
            '}'
        );
        return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
    }

    /**
     * @dev Helper to convert an array of AetherialTrait structs into a JSON array string.
     */
    function _getTraitsJson(AetherialTrait[] memory traits) internal pure returns (string memory) {
        bytes memory jsonBytes = abi.encodePacked("[");
        for (uint256 i = 0; i < traits.length; i++) {
            jsonBytes = abi.encodePacked(
                jsonBytes,
                '{"trait_type": "', traits[i].description,
                '", "value": ', traits[i].value.toString(),
                ', "category": ', uint256(traits[i].category).toString(), // numeric category
                ', "is_reputation_bound": ', traits[i].isReputationBound ? "true" : "false",
                ', "reputation_shard_type": ', traits[i].reputationShardType.toString(),
                '}'
            );
            if (i < traits.length - 1) {
                jsonBytes = abi.encodePacked(jsonBytes, ",");
            }
        }
        jsonBytes = abi.encodePacked(jsonBytes, "]");
        return string(jsonBytes);
    }

    // II. Dynamic Trait Management & Evolution

    /**
     * @dev Initiates an AI oracle request for the evolution of a specific NFT.
     *      The owner must approve and pay the `_evolutionCost` in Aether tokens.
     * @param tokenId The ID of the Aetherial NFT to evolve.
     */
    function requestEvolutionPath(uint256 tokenId) public {
        require(_exists(tokenId), "AGE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AGE: Only owner can request evolution");
        require(_aiOracleAddress != address(0), "AGE: AI Oracle address not set");
        require(_aetherTokenAddress != address(0), "AGE: Aether token address not set");

        Aetherial storage aetherial = _aetherials[tokenId];
        require(aetherial.pendingEvolutionRequestId == bytes32(0), "AGE: Evolution already pending for this Aetherial");

        // Transfer Aether tokens to cover the evolution cost
        IAetherToken aetherToken = IAetherToken(_aetherTokenAddress);
        require(aetherToken.transferFrom(msg.sender, address(this), _evolutionCost), "AGE: Aether token transfer failed");

        // Convert current traits to bytes for the oracle
        bytes memory currentTraitsData = abi.encode(aetherial.traits);

        // Call the AI Oracle to request an evolution.
        // The oracle would process this off-chain and then call `fulfillEvolutionPath` back.
        bytes32 requestId = IAIOracle(_aiOracleAddress).requestEvolution(tokenId, currentTraitsData);
        aetherial.pendingEvolutionRequestId = requestId;

        emit EvolutionRequested(tokenId, msg.sender, requestId);
    }

    /**
     * @dev Callback from the AI oracle to update an NFT's traits.
     *      Only callable by the configured AI Oracle address.
     * @param tokenId The ID of the Aetherial NFT.
     * @param newTraitsData The abi.encoded byte array of the new `AetherialTrait[]`.
     */
    function fulfillEvolutionPath(uint256 tokenId, bytes memory newTraitsData) public onlyAIOracle {
        require(_exists(tokenId), "AGE: Token does not exist");
        Aetherial storage aetherial = _aetherials[tokenId];
        require(aetherial.pendingEvolutionRequestId != bytes32(0), "AGE: No pending evolution request for this Aetherial");
        
        // In a real system, `requestId` would be used to match the fulfillment to the request.
        // For simplicity, we assume the oracle only calls with valid data.
        
        AetherialTrait[] memory newTraits = abi.decode(newTraitsData, (AetherialTrait[]));
        
        bytes memory oldTraitsHash = abi.encode(aetherial.traits);
        aetherial.traits = newTraits;
        aetherial.lastEvolutionTimestamp = block.timestamp;
        aetherial.evolutionStage++;
        aetherial.pendingEvolutionRequestId = bytes32(0); // Clear pending request

        _addEvolutionLogEntry(
            tokenId,
            "AIOracle",
            oldTraitsHash,
            newTraitsData,
            "AI-guided evolution fulfilled"
        );

        // Update token URI to reflect new traits
        _setTokenURI(tokenId, _generateTokenURI(tokenId));

        emit EvolutionFulfilled(tokenId, newTraitsData);
    }

    /**
     * @dev Allows an owner to manually adjust a specific trait within defined boundaries,
     *      consuming a portion of Aether tokens. Cannot be used for reputation-bound traits.
     * @param tokenId The ID of the Aetherial NFT.
     * @param traitIndex The index of the trait in the `traits` array to mutate.
     * @param newValue The new value for the trait.
     * @param metadata Optional metadata for the log entry (e.g., reason for mutation).
     */
    function mutateTraitManually(uint256 tokenId, uint256 traitIndex, uint256 newValue, bytes memory metadata) public {
        require(_exists(tokenId), "AGE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AGE: Only owner can mutate traits");
        require(_aetherTokenAddress != address(0), "AGE: Aether token address not set");

        Aetherial storage aetherial = _aetherials[tokenId];
        require(traitIndex < aetherial.traits.length, "AGE: Invalid trait index");
        require(!aetherial.traits[traitIndex].isReputationBound, "AGE: Cannot manually mutate reputation-bound traits");

        TraitBounds storage bounds = _traitCategoryBounds[uint256(aetherial.traits[traitIndex].category)];
        require(newValue >= bounds.min && newValue <= bounds.max, "AGE: New value out of bounds for trait category");

        // Deduct Aether for manual mutation (e.g., half the evolution cost)
        IAetherToken aetherToken = IAetherToken(_aetherTokenAddress);
        require(aetherToken.transferFrom(msg.sender, address(this), _evolutionCost / 2), "AGE: Aether token transfer failed for manual mutation");

        bytes memory oldTraitsHash = abi.encode(aetherial.traits);
        uint256 oldValue = aetherial.traits[traitIndex].value;
        aetherial.traits[traitIndex].value = newValue;

        _addEvolutionLogEntry(
            tokenId,
            "ManualMutation",
            oldTraitsHash,
            abi.encode(aetherial.traits),
            string(abi.encodePacked("Trait index ", traitIndex.toString(), " mutated. Details: ", string(metadata)))
        );
        
        _setTokenURI(tokenId, _generateTokenURI(tokenId)); // Refresh URI
        emit TraitManuallyMutated(tokenId, traitIndex, oldValue, newValue, msg.sender);
    }

    /**
     * @dev Returns the current structured traits of a specific Aetherial NFT.
     * @param tokenId The ID of the Aetherial NFT.
     * @return An array of `AetherialTrait` structs.
     */
    function getAetherialTraits(uint256 tokenId) public view returns (AetherialTrait[] memory) {
        require(_exists(tokenId), "AGE: Token does not exist");
        return _aetherials[tokenId].traits;
    }

    /**
     * @dev Admin/DAO function to trigger a global environmental event.
     *      This function increments a global shift ID and emits an event.
     *      Individual NFTs then need to call `applyLatestEnvironmentalShift` to update.
     * @param shiftData Arbitrary data describing the environmental shift.
     */
    function triggerEnvironmentalShift(bytes memory shiftData) public onlyOwner { // Can be made DAO-governed
        uint256 currentShiftId = _nextEnvironmentalShiftId.current();
        _nextEnvironmentalShiftId.increment(); // Increment for the next shift

        // In a real, gas-optimized system, this would not iterate over all NFTs.
        // It merely signals that a new shift has occurred.
        // Affected count is 0 because effects are applied on demand.
        emit EnvironmentalShiftTriggered(currentShiftId, shiftData, 0); 
    }
    
    /**
     * @dev Returns the ID of the most recently triggered environmental shift.
     */
    function getLatestEnvironmentalShiftId() public view returns (uint256) {
        return _nextEnvironmentalShiftId.current() - 1; // Return the ID of the *last completed* shift
    }

    /**
     * @dev Allows an NFT owner (or automated system like Chainlink Keepers) to apply
     *      the latest global environmental shift effects to their specific NFT.
     *      This avoids iterating over all NFTs in `triggerEnvironmentalShift`, saving gas.
     * @param tokenId The ID of the Aetherial NFT.
     */
    function applyLatestEnvironmentalShift(uint256 tokenId) public {
        require(_exists(tokenId), "AGE: Token does not exist");
        // For simplicity, allowing anyone to trigger an update if it's lagging.
        // In a real system, could add owner check or restrict to Keepers.

        Aetherial storage aetherial = _aetherials[tokenId];
        uint256 latestShiftId = getLatestEnvironmentalShiftId();

        if (latestShiftId == 0 || aetherial.lastEnvironmentalShiftId >= latestShiftId) {
            // Already up-to-date or no shifts happened yet
            return;
        }

        // --- Simulate environmental effect here ---
        // This is a placeholder. In a real system, this could involve:
        // 1. Calling the AI oracle with `shiftData` (from event) and current traits for re-evaluation.
        // 2. Applying a pre-defined rule based on `shiftData` stored on-chain.
        // 3. Complex interaction based on the `latestShiftId`.

        bytes memory oldTraitsHash = abi.encode(aetherial.traits);
        bool traitFoundAndUpdated = false;
        for (uint256 i = 0; i < aetherial.traits.length; i++) {
            if (aetherial.traits[i].category == TraitCategory.Environmental) {
                // Example simple rule: environmental trait value reflects the shift ID
                aetherial.traits[i].value = latestShiftId;
                traitFoundAndUpdated = true;
                break;
            }
        }

        aetherial.lastEnvironmentalShiftId = latestShiftId; // Mark as updated to this shift

        if (traitFoundAndUpdated) {
            _addEvolutionLogEntry(
                tokenId,
                "EnvironmentalShift",
                oldTraitsHash,
                abi.encode(aetherial.traits),
                string(abi.encodePacked("Applied Environmental Shift ID: ", latestShiftId.toString()))
            );
            _setTokenURI(tokenId, _generateTokenURI(tokenId)); // Refresh URI
        }
    }

    /**
     * @dev Retrieves the full evolution history (trait changes) for a given NFT.
     * @param tokenId The ID of the Aetherial NFT.
     * @return An array of `EvolutionLogEntry` structs.
     */
    function getEvolutionHistory(uint256 tokenId) public view returns (EvolutionLogEntry[] memory) {
        require(_exists(tokenId), "AGE: Token does not exist");
        return _evolutionHistory[tokenId];
    }

    /**
     * @dev Internal helper function to add an entry to an Aetherial's evolution log.
     */
    function _addEvolutionLogEntry(
        uint256 tokenId,
        string memory trigger,
        bytes memory oldTraitsHash,
        bytes memory newTraitsHash,
        string memory details
    ) internal {
        _evolutionHistory[tokenId].push(
            EvolutionLogEntry({
                timestamp: block.timestamp,
                trigger: trigger,
                oldTraitsHash: oldTraitsHash,
                newTraitsHash: newTraitsHash,
                details: details
            })
        );
    }

    // III. Reputation & "Aether Shards" (Soulbound Enhancers)

    /**
     * @dev Mints a non-transferable "Aether Shard" to a wallet based on on-chain achievements.
     *      `shardType` identifies the specific achievement (e.g., 1 for "Governance Participant", 2 for "Early Adopter").
     *      Callable by the contract owner, or could be integrated with other achievement systems.
     * @param to The wallet address to mint the shard to.
     * @param shardType The type identifier of the Aether Shard.
     */
    function mintAetherShard(address to, uint256 shardType) public onlyOwner { // Or other achievement-based trigger
        require(to != address(0), "AGE: Cannot mint to zero address");
        require(!_aetherShards[to][shardType], "AGE: Wallet already holds this shard type");

        _aetherShards[to][shardType] = true;
        emit AetherShardMinted(to, shardType);
    }

    /**
     * @dev Returns a boolean array indicating which types of Aether Shards a wallet holds.
     *      For demonstration, it checks for shard types 0-9. In a real system, known shard types
     *      would be registered or enumerated.
     * @param wallet The address to query.
     * @return A boolean array where `true` means the wallet holds the shard of that index.
     */
    function getAetherShardsForWallet(address wallet) public view returns (bool[] memory) {
        // This is a simplified example. In a real system, shard types would be
        // explicitly defined and stored (e.g., in a lookup table or enum)
        // rather than guessing a max count.
        bool[] memory shards = new bool[](10); 
        for (uint256 i = 0; i < 10; i++) {
            shards[i] = _aetherShards[wallet][i];
        }
        return shards;
    }

    /**
     * @dev Allows an NFT owner to activate a special trait on their Aetherial,
     *      provided their wallet holds a specific Aether Shard required for that trait.
     * @param tokenId The ID of the Aetherial NFT.
     * @param requiredShardType The Aether Shard type needed to activate this trait.
     * @param traitIndex The index of the reputation-bound trait to activate.
     * @param newValue The value to set for the activated trait.
     */
    function activateReputationTrait(uint256 tokenId, uint256 requiredShardType, uint256 traitIndex, uint256 newValue) public {
        require(_exists(tokenId), "AGE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AGE: Only owner can activate reputation traits");
        require(_aetherShards[msg.sender][requiredShardType], "AGE: Wallet does not hold the required Aether Shard");

        Aetherial storage aetherial = _aetherials[tokenId];
        require(traitIndex < aetherial.traits.length, "AGE: Invalid trait index");
        require(aetherial.traits[traitIndex].isReputationBound, "AGE: Trait is not reputation-bound");
        require(aetherial.traits[traitIndex].reputationShardType == requiredShardType, "AGE: Incorrect shard type for this trait");
        require(aetherial.traits[traitIndex].value != newValue, "AGE: Trait already has this value or is already activated with this value");

        bytes memory oldTraitsHash = abi.encode(aetherial.traits);
        aetherial.traits[traitIndex].value = newValue;

        _addEvolutionLogEntry(
            tokenId,
            "ReputationActivation",
            oldTraitsHash,
            abi.encode(aetherial.traits),
            string(abi.encodePacked("Activated reputation trait with shard type: ", requiredShardType.toString()))
        );
        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        emit ReputationTraitActivated(tokenId, msg.sender, traitIndex, requiredShardType);
    }

    /**
     * @dev Deactivates a previously activated reputation-bound trait, reverting it to its default state (value 0).
     * @param tokenId The ID of the Aetherial NFT.
     * @param traitIndex The index of the reputation-bound trait to deactivate.
     */
    function deactivateReputationTrait(uint256 tokenId, uint256 traitIndex) public {
        require(_exists(tokenId), "AGE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "AGE: Only owner can deactivate reputation traits");

        Aetherial storage aetherial = _aetherials[tokenId];
        require(traitIndex < aetherial.traits.length, "AGE: Invalid trait index");
        require(aetherial.traits[traitIndex].isReputationBound, "AGE: Trait is not reputation-bound");
        require(aetherial.traits[traitIndex].value != 0, "AGE: Trait is already deactivated or at default value");

        bytes memory oldTraitsHash = abi.encode(aetherial.traits);
        aetherial.traits[traitIndex].value = 0; // Set to default inactive value

        _addEvolutionLogEntry(
            tokenId,
            "ReputationDeactivation",
            oldTraitsHash,
            abi.encode(aetherial.traits),
            "Deactivated reputation trait"
        );
        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        emit ReputationTraitDeactivated(tokenId, msg.sender, traitIndex);
    }

    // IV. AI Oracle Integration & Configuration

    /**
     * @dev Sets the address of the trusted AI Oracle contract.
     *      Callable by the contract owner (initially), can be made DAO-governed.
     * @param _oracleAddress The new address of the AI Oracle.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyOwner { // Can be made DAO-governed
        require(_oracleAddress != address(0), "AGE: AI Oracle address cannot be zero");
        _aiOracleAddress = _oracleAddress;
        emit AIOracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Updates the parameters used by the AI Oracle for its evolution logic.
     *      These parameters would typically be interpreted by the off-chain AI.
     *      Callable by the contract owner, can be made DAO-governed.
     * @param newParameters A byte array containing the new evolution model parameters.
     */
    function setEvolutionModelParameters(bytes memory newParameters) public onlyOwner { // Can be made DAO-governed
        _evolutionModelParameters = newParameters;
        emit EvolutionModelParametersUpdated(newParameters);
    }

    /**
     * @dev Retrieves the currently configured evolution model parameters.
     * @return A byte array containing the evolution model parameters.
     */
    function getEvolutionModelParameters() public view returns (bytes memory) {
        return _evolutionModelParameters;
    }

    // V. Governance & System Parameters (Simplified)

    /**
     * @dev Allows users to propose changes to system parameters or call arbitrary functions
     *      on this contract or other target contracts.
     * @param description A brief description of the proposal.
     * @param callData The ABI-encoded function call to be executed if the proposal passes.
     * @param targetContract The address of the contract to call (can be `address(this)`).
     */
    function proposeParameterChange(string memory description, bytes memory callData, address targetContract) public {
        // In a real DAO, eligibility to propose would be based on token holdings or NFT count.
        // For simplicity, any non-zero address can propose.
        require(msg.sender != address(0), "AGE: Proposer cannot be zero address");
        require(targetContract != address(0), "AGE: Target contract cannot be zero address");
        require(callData.length > 0, "AGE: Call data cannot be empty");

        uint256 proposalId = _nextProposalId.current();
        _proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            callData: callData,
            targetContract: targetContract,
            voteCount: 0,
            creationTime: block.timestamp,
            executed: false,
            passed: false
        });
        _nextProposalId.increment();
        emit ProposalCreated(proposalId, description, msg.sender, block.timestamp);
    }

    /**
     * @dev Allows eligible participants to vote on active proposals.
     *      A simple 1-vote-per-wallet system is implemented for demonstration.
     * @param proposalId The ID of the proposal to vote on.
     * @param support `true` for yes, `false` for no (though `voteCount` simply increments here).
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        require(proposalId > 0 && proposalId < _nextProposalId.current(), "AGE: Invalid proposal ID");
        Proposal storage proposal = _proposals[proposalId];
        require(block.timestamp <= proposal.creationTime + VOTING_PERIOD_DAYS * 1 days, "AGE: Voting period ended");
        require(!proposal.executed, "AGE: Proposal already executed");
        require(!_hasVotedOnProposal[msg.sender][proposalId], "AGE: Already voted on this proposal");
        
        // A more advanced system would check voting power based on token holdings, NFT count, etc.
        proposal.voteCount++; // Simplified: each unique voter adds one vote
        _hasVotedOnProposal[msg.sender][proposalId] = true; // Mark voter has voted on this proposal

        if (proposal.voteCount >= PROPOSAL_VOTE_THRESHOLD) {
            proposal.passed = true;
        }
        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal that has met its voting quorum and passed its voting period.
     *      Any address can call this function once the conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        require(proposalId > 0 && proposalId < _nextProposalId.current(), "AGE: Invalid proposal ID");
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.passed, "AGE: Proposal has not passed or failed to meet quorum");
        require(!proposal.executed, "AGE: Proposal already executed");
        require(block.timestamp > proposal.creationTime + VOTING_PERIOD_DAYS * 1 days, "AGE: Voting period not yet over");

        proposal.executed = true;

        // Execute the encoded function call
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "AGE: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Sets the minimum and maximum permissible values for a specific trait category.
     *      Callable by the contract owner, can be made DAO-governed.
     * @param traitType The numeric ID of the `TraitCategory`.
     * @param min The minimum value for this trait category.
     * @param max The maximum value for this trait category.
     */
    function setTraitCategoryBounds(uint256 traitType, uint256 min, uint256 max) public onlyOwner { // Can be made DAO-governed
        require(max >= min, "AGE: Max must be greater than or equal to min");
        _traitCategoryBounds[traitType] = TraitBounds(min, max);
        emit TraitCategoryBoundsSet(traitType, min, max);
    }

    /**
     * @dev Whitelists an address as an approved data feed. This is conceptual;
     *      it could be used for specific oracles calling back to the contract.
     *      Callable by the contract owner, can be made DAO-governed.
     * @param dataFeedAddress The address of the data feed to approve.
     */
    function addApprovedDataFeed(address dataFeedAddress) public onlyOwner { // Can be made DAO-governed
        require(dataFeedAddress != address(0), "AGE: Data feed address cannot be zero");
        _approvedDataFeeds[dataFeedAddress] = true;
        emit ApprovedDataFeedAdded(dataFeedAddress);
    }

    // VI. Aether Token Integration

    /**
     * @dev Sets the address of the Aether ERC20 token contract.
     *      Callable by the contract owner.
     * @param _aetherTokenAddress_param The address of the Aether ERC20 token.
     */
    function setAetherTokenAddress(address _aetherTokenAddress_param) public onlyOwner {
        require(_aetherTokenAddress_param != address(0), "AGE: Aether token address cannot be zero");
        _aetherTokenAddress = _aetherTokenAddress_param;
        emit AetherTokenAddressSet(_aetherTokenAddress_param);
    }

    /**
     * @dev Sets the cost in Aether tokens for requesting an evolution.
     *      Callable by the contract owner, can be made DAO-governed.
     * @param _cost The new cost in Aether tokens (wei).
     */
    function setEvolutionCost(uint256 _cost) public onlyOwner { // Can be made DAO-governed
        _evolutionCost = _cost;
        emit EvolutionCostUpdated(_cost);
    }

    /**
     * @dev Returns the current cost for an evolution request in Aether tokens (wei).
     */
    function getEvolutionCost() public view returns (uint256) {
        return _evolutionCost;
    }

    /**
     * @dev Allows the contract owner/DAO to withdraw accumulated Aether token fees
     *      from the contract.
     * @param recipient The address to send the Aether tokens to.
     * @param amount The amount of Aether tokens to withdraw.
     */
    function withdrawFees(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "AGE: Recipient cannot be zero address");
        IAetherToken aetherToken = IAetherToken(_aetherTokenAddress);
        require(aetherToken.transfer(recipient, amount), "AGE: Aether token withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }
}
```