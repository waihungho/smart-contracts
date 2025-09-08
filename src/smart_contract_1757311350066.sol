Here's a smart contract written in Solidity, incorporating advanced concepts like dynamic NFTs, on-chain generative art parameters, a simplified DAO for evolution governance, and a custom ERC-20 token for staking and fees. The design aims for creativity by treating NFTs as digital "organisms" that can mutate and cross-breed based on community input or autonomous triggers, distinct from common open-source patterns.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// For a fully compliant data URI, a Base64 encoding library would be necessary (e.g., from OpenZeppelin utils).
// For simplicity in this example, we'll build the JSON string but won't do full Base64 encoding on-chain,
// returning the raw JSON. A real-world scenario might use Chainlink Functions/Keepers or a dedicated off-chain service for complex metadata.

/**
 * @title EvoGenesis: Decentralized Adaptive Art & Attribute Evolution Engine
 * @dev This smart contract implements a novel system for dynamic, generative NFTs that can evolve over time
 *      through community governance or autonomous triggers. It combines ERC-721 for the art pieces,
 *      a custom ERC-20 token ("Catalyst") for staking and governance, and an on-chain attribute
 *      registry that defines the generative parameters of the art. Art evolution can be proposed
 *      via mutation or cross-breeding, voted upon by Catalyst stakers, or triggered autonomously.
 *      The tokenURI for each NFT is dynamic, reflecting its current attributes.
 *
 * Concepts Demonstrated:
 * - Dynamic NFTs: NFTs whose state (attributes) can change post-mint.
 * - On-chain Generative Art Parameters: Art is defined by on-chain numerical/boolean attributes,
 *   enabling a rich, programmable art form.
 * - Decentralized Autonomous Organization (DAO) Lite: Community governance through proposals
 *   and voting using a dedicated token, allowing holders to direct the evolution of art.
 * - Custom ERC-20 Token (Catalyst): Serves as the economic and governance backbone,
 *   used for staking, voting power, and as a fee mechanism for evolution events.
 * - Gamified Evolution Mechanics: "Mutation" and "Cross-Breeding" metaphors are used
 *   to describe the processes of single-attribute changes and combining attributes from multiple NFTs.
 * - Autonomous Triggers: Provides a simpler, faster path for minor, random changes to art
 *   via a direct Catalyst payment, bypassing full governance.
 * - On-chain Event Logging: Comprehensive history tracking for each NFT's evolution,
 *   ensuring transparency and provable lineage.
 * - Pseudo-randomness: Utilizes block data for attribute generation and random events.
 *   (Note: For high-security or truly unpredictable outcomes, Chainlink VRF or similar solutions are recommended).
 */

// --- OUTLINE ---

// I. Core Assets & Registry (ERC-721 for Art, Attribute Definitions)
//    - AttributeType: A struct defining the characteristics of a generative art attribute (e.g., color, shape count, size).
//    - EvolutionEvent: A struct to log every significant change or action applied to an NFT, tracking its history.
//    - NFT Lifecycle: Functions for minting new art pieces, querying their current attributes, and controlling their evolvability (freezing/unfreezing).
//    - Dynamic Metadata: The `tokenURI` function dynamically generates NFT metadata based on its current on-chain attributes, making the NFT truly adaptive.

// II. Catalyst Token & Staking (ERC-20 for Governance & Fees)
//    - `CatalystToken`: A custom ERC-20 token contract.
//    - Standard ERC-20 operations: Transfer, approve, balanceOf.
//    - Staking mechanism: Users can lock their Catalyst tokens within the EvoGenesis contract to gain voting power for governance proposals.

// III. Evolution & Governance (DAO for Proposals, Execution, Autonomous Events)
//    - Proposal: A struct defining a requested change to an NFT or the system (Mutation, CrossBreed, or Generic administrative action).
//    - Voting Mechanism: Staked Catalyst holders can vote on active proposals, influencing their outcome.
//    - Proposal Execution: Functions to finalize and apply approved changes from proposals to NFTs or update system parameters.
//    - Autonomous Evolution: A unique function allowing instant, random mutations to an NFT by paying Catalyst, without a full DAO vote.
//    - Governance Parameters: Admin-set thresholds for proposal creation, voting duration, and quorum requirements for the DAO.
//    - Treasury: Manages Catalyst collected from proposal fees and autonomous evolution payments, controlled by the contract owner (or DAO in a full implementation).

// --- FUNCTION SUMMARY ---

// I. Core Assets & Registry
// 1.  constructor(string _name, string _symbol): Initializes the ERC-721 art contract (`EvoGenesis`) and deploys the associated `CatalystToken` contract.
// 2.  registerAttributeType(string _attributeName, uint256 _minValue, uint256 _maxValue, bool _isInteger): (Admin-only) Defines a new type of generative attribute (e.g., "Color Hue", "Shape Count") that can be part of an EvoGenesis NFT, including its valid range and type (integer or scaled fixed-point).
// 3.  getAttributeTypeDetails(uint256 _attributeTypeId) view returns (AttributeType memory): Retrieves the full definition details of a specific registered attribute type.
// 4.  getRegisteredAttributeCount() view returns (uint256): Returns the total number of distinct attribute types currently registered in the system.
// 5.  mintInitialGenesisArt(address _recipient, string _initialMetadataURI): (Admin-only) Mints a brand new EvoGenesis NFT to `_recipient`, automatically assigning it initial random attribute values based on all registered attribute types, and sets a base metadata URI.
// 6.  getCurrentAttributes(uint256 _tokenId) view returns (uint256[] memory attributeTypeIds, uint256[] memory values): Fetches and returns all current on-chain attribute IDs and their corresponding values for a specified NFT.
// 7.  tokenURI(uint256 _tokenId) view returns (string memory): Dynamically generates and returns a JSON metadata string for an NFT, embedding its current on-chain attributes. This forms the basis of its visual and conceptual identity.
// 8.  freezeEvolution(uint256 _tokenId): Allows the owner of an NFT to permanently (or until `unfreezeEvolution`) prevent their art piece from undergoing any further mutations or cross-breeding.
// 9.  unfreezeEvolution(uint256 _tokenId): Allows the owner to reverse a `freezeEvolution` action, re-enabling an NFT to participate in evolution processes.
// 10. getEvolutionHistory(uint256 _tokenId) view returns (EvolutionEvent[] memory): Provides a complete chronological log of all past evolution events and significant changes applied to a specific NFT.

// II. Catalyst Token & Staking
// 11. mintCatalyst(address _to, uint256 _amount): (Admin-only) Allows the EvoGenesis contract owner to mint new Catalyst tokens and distribute them to any address.
// 12. burnCatalyst(uint256 _amount): Allows a user to reduce the total supply of Catalyst tokens by burning their own held tokens.
// 13. stakeCatalyst(uint256 _amount): Enables a user to deposit their Catalyst tokens into the EvoGenesis contract, locking them and thereby gaining voting power for governance proposals.
// 14. unstakeCatalyst(uint256 _amount): Allows a user to withdraw their previously staked Catalyst tokens, which simultaneously reduces their voting power.
// 15. getVotingPower(address _staker) view returns (uint256): Returns the current amount of Catalyst tokens staked by a given address, indicating their effective voting power.

// III. Evolution & Governance
// 16. proposeMutation(uint256 _tokenId, uint256 _attributeTypeId, uint256 _targetValue, string _justification, uint256 _catalystCost): Allows a Catalyst staker to initiate a proposal to change a specific attribute (`_attributeTypeId`) of an NFT (`_tokenId`) to a new `_targetValue`. Requires a `_catalystCost` payment.
// 17. proposeCrossBreed(uint256 _tokenId1, uint256 _tokenId2, uint256[] _attributeTypeIdsToMix, uint256[] _mixRatios, string _justification, uint256 _catalystCost): Allows a Catalyst staker to propose a "cross-breeding" event. This involves combining selected attributes (`_attributeTypeIdsToMix`) from `_tokenId1` and `_tokenId2` into a new state for `_tokenId1`, using specified `_mixRatios`. Also requires a `_catalystCost`.
// 18. voteOnProposal(uint256 _proposalId, bool _approve): Allows any Catalyst staker with voting power to cast their vote (either for or against) on an active evolution proposal.
// 19. getProposalDetails(uint256 _proposalId) view returns (Proposal memory): Retrieves and displays all detailed information about a specific evolution proposal, including its status, votes, and parameters.
// 20. executeProposal(uint256 _proposalId): Callable by anyone after the voting period ends. This function checks if a proposal has passed (met quorum and majority) and, if so, applies the proposed attribute changes to the target NFT(s). If failed, it marks the proposal as rejected.
// 21. triggerRandomEvolution(uint256 _tokenId, uint256 _catalystPayment): Allows any user to pay a `_catalystPayment` to trigger a minor, random, and immediate mutation on an unfrozen NFT. This offers a spontaneous evolution path separate from the formal DAO process.
// 22. updateGovernanceParameters(uint256 _newProposalThreshold, uint256 _newVotingPeriodBlocks, uint256 _newQuorumPercentage): (Admin-only) Adjusts the key operational parameters of the DAO, such as the minimum Catalyst required to propose, the length of voting periods, and the quorum percentage for proposals to pass.
// 23. withdrawTreasuryFunds(address _recipient, uint256 _amount): (Admin-only) Allows the contract owner to extract accumulated Catalyst tokens (from proposal fees and random evolution payments) from the contract's treasury to a specified recipient.


contract EvoGenesis is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256; // For converting uint256 to string

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _attributeTypeIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- I. Core Assets & Registry ---

    // Struct to define a type of generative attribute for an NFT
    struct AttributeType {
        uint256 id;          // Unique ID for the attribute type
        string name;         // Name of the attribute (e.g., "Color Hue", "Shape Count")
        uint256 minValue;    // Minimum possible value for this attribute
        uint256 maxValue;    // Maximum possible value for this attribute
        bool isInteger;      // True if values are integers, false if scaled fixed-point (e.g., 0-1000 for 0.0-1.0)
    }

    // Stores all registered attribute types in an array
    AttributeType[] public registeredAttributeTypes;
    // Mapping for quick lookup of attribute ID by its name
    mapping(string => uint256) public attributeNameToId;
    // Mapping for quick lookup of attribute details by its ID
    mapping(uint256 => AttributeType) public attributeTypeById;

    // Stores the current attributes for each NFT: tokenId => attributeTypeId => value
    mapping(uint256 => mapping(uint256 => uint256)) public tokenAttributes;
    // Tracks if an NFT's evolution is currently frozen
    mapping(uint256 => bool) public isFrozen;
    // Stores an optional base metadata URI (e.g., an IPFS hash to an image or JSON) for each NFT
    mapping(uint256 => string) public baseMetadataURI;

    // Event struct for logging significant evolution events for each NFT
    struct EvolutionEvent {
        uint256 timestamp;            // When the event occurred
        string eventType;             // Type of event (e.g., "Mint", "Mutation", "CrossBreed", "RandomMutation")
        uint256 proposalId;           // ID of the proposal if applicable (0 for non-proposal events)
        uint256[] affectedAttributeIds; // IDs of attributes that were changed
        uint256[] newValues;          // New values for the affected attributes
        string justification;         // A brief description or reason for the event
    }
    // Evolution history for each token: tokenId => array of EvolutionEvent structs
    mapping(uint256 => EvolutionEvent[]) public evolutionHistory;

    // --- II. Catalyst Token & Staking ---

    // Instance of the custom ERC-20 token used for governance and fees
    CatalystToken public catalystToken;
    // Stores the amount of Catalyst tokens staked by each address, representing their voting power
    mapping(address => uint256) public stakedCatalyst;

    // --- III. Evolution & Governance ---

    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed }
    enum ProposalType { Mutation, CrossBreed, Generic } // Generic for future system changes (e.g., admin actions)

    // Struct defining an evolution proposal
    struct Proposal {
        uint256 id;                         // Unique ID for the proposal
        address proposer;                   // Address that created the proposal
        ProposalType pType;                 // Type of proposal (Mutation, CrossBreed, Generic)
        string justification;               // User-provided reason/description for the proposal
        uint256 catalystCost;               // Catalyst tokens required to execute the proposal (paid to treasury)
        uint256 proposalCreationBlock;      // Block number when the proposal was created
        uint256 votingEndBlock;             // Block number when the voting period ends
        uint256 votesFor;                   // Total voting power (staked Catalyst) cast for the proposal
        uint256 votesAgainst;               // Total voting power (staked Catalyst) cast against the proposal
        uint256 totalVotingPowerAtCreation; // Snapshot of total Catalyst supply at proposal creation for quorum calculation
        uint256 quorumRequired;             // Absolute minimum voting power required for the proposal to be valid
        ProposalStatus status;              // Current status of the proposal
        // Specifics for Mutation/CrossBreed proposals
        uint256 targetTokenId;              // The NFT targeted for mutation or as the primary for cross-breeding
        uint256 secondaryTokenId;           // The secondary NFT used for cross-breeding (0 if not applicable)
        uint256[] relevantAttributeTypeIds; // IDs of attributes involved in the proposal
        uint256[] targetValuesOrMixRatios;  // For mutation: new target values. For cross-breed: mix ratios (0-10000)
    }

    // Stores all proposals by their ID
    mapping(uint256 => Proposal) public proposals;
    // Tracks if an address has voted on a specific proposal: proposalId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Governance parameters, adjustable by the owner
    uint256 public proposalThreshold;    // Minimum staked Catalyst required to create a proposal
    uint256 public votingPeriodBlocks;   // Number of blocks for a proposal's voting duration
    uint256 public quorumPercentage;     // Percentage of total Catalyst supply required for a proposal to meet quorum (0-100)

    // Events emitted by the contract for external listeners
    event AttributeTypeRegistered(uint256 indexed id, string name, uint256 minValue, uint256 maxValue, bool isInteger);
    event GenesisArtMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event ArtEvolutionFrozen(uint256 indexed tokenId);
    event ArtEvolutionUnfrozen(uint256 indexed tokenId);
    event CatalystStaked(address indexed staker, uint256 amount);
    event CatalystUnstaked(address indexed staker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType pType, uint256 catalystCost);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool approved, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus finalStatus);
    event RandomEvolutionTriggered(uint256 indexed tokenId, address indexed triggerer, uint256 catalystPayment);
    event GovernanceParametersUpdated(uint256 newProposalThreshold, uint256 newVotingPeriodBlocks, uint256 newQuorumPercentage);

    /**
     * @dev 1. Contract constructor.
     * @param _name The name of the ERC-721 token (e.g., "EvoGenesis Art").
     * @param _symbol The symbol of the ERC-721 token (e.g., "EGA").
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Deploy the CatalystToken contract, with this EvoGenesis contract as its owner (minter)
        catalystToken = new CatalystToken(address(this));
        
        // Initialize default governance parameters
        proposalThreshold = 1000 * 10 ** catalystToken.decimals(); // e.g., 1000 Catalyst tokens (scaled by decimals)
        votingPeriodBlocks = 10000; // Approximately 3-4 days at 13s/block
        quorumPercentage = 4;       // 4% of total Catalyst supply for quorum
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /**
     * @dev Generates a pseudo-random number within a given range [min, max].
     *      WARNING: Block-based randomness is predictable and should NOT be used for high-security applications
     *      where adversaries can influence outcomes (e.g., gambling). For those cases, use Chainlink VRF or similar.
     * @param _seed A unique seed value to introduce more entropy.
     * @param _min Minimum value (inclusive).
     * @param _max Maximum value (inclusive).
     * @return A pseudo-random number.
     */
    function _pseudoRandom(uint256 _seed, uint256 _min, uint256 _max) internal view returns (uint256) {
        require(_max >= _min, "Max must be >= Min");
        if (_max == _min) return _min; // If range is 0, return min/max
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,    // Current timestamp
            block.difficulty,   // Mining difficulty (can be influenced by miners)
            msg.sender,         // The sender's address
            _seed,              // An additional seed for uniqueness (e.g., tokenId, proposalId)
            _tokenIdCounter.current() // Current highest token ID for more entropy
        )));
        return (_min + (randomSeed % (_max - _min + 1)));
    }

    /**
     * @dev Generates a random attribute value for a given attribute type, using a seed.
     * @param _attributeTypeId The ID of the attribute type to generate a value for.
     * @param _seed A seed value to use with the pseudo-random generator.
     * @return A randomly generated value within the attribute type's defined range.
     */
    function _getRandomAttributeValue(uint256 _attributeTypeId, uint256 _seed) internal view returns (uint256) {
        AttributeType memory attr = attributeTypeById[_attributeTypeId];
        require(attr.id == _attributeTypeId, "Attribute type not found");
        return _pseudoRandom(_seed, attr.minValue, attr.maxValue);
    }

    /**
     * @dev Records an evolution event for a specified NFT, adding it to its history log.
     * @param _tokenId The ID of the NFT for which to record the event.
     * @param _eventType The type of evolution event (e.g., "Mint", "Mutation").
     * @param _proposalId The ID of the associated proposal (0 if not proposal-driven).
     * @param _affectedAttrIds Array of attribute IDs that were changed during this event.
     * @param _newValues Array of new values for the affected attributes.
     * @param _justification A descriptive string explaining the event.
     */
    function _recordEvolutionEvent(
        uint256 _tokenId,
        string memory _eventType,
        uint256 _proposalId,
        uint256[] memory _affectedAttrIds,
        uint256[] memory _newValues,
        string memory _justification
    ) internal {
        evolutionHistory[_tokenId].push(EvolutionEvent({
            timestamp: block.timestamp,
            eventType: _eventType,
            proposalId: _proposalId,
            affectedAttributeIds: _affectedAttrIds,
            newValues: _newValues,
            justification: _justification
        }));
    }

    // --- I. Core Assets & Registry Functions ---

    /**
     * @dev 2. Registers a new attribute type that can be part of an EvoGenesis NFT.
     *      Only callable by the contract owner.
     * @param _attributeName A unique string name for the new attribute (e.g., "Color Hue").
     * @param _minValue The minimum possible value for this attribute.
     * @param _maxValue The maximum possible value for this attribute.
     * @param _isInteger True if the attribute values are integers, false if they are scaled fixed-point numbers.
     */
    function registerAttributeType(string memory _attributeName, uint256 _minValue, uint256 _maxValue, bool _isInteger)
        public
        onlyOwner
    {
        // Require that the attribute name is not already in use (ID 0 means not found)
        require(attributeNameToId[_attributeName] == 0, "Attribute name already registered");
        _attributeTypeIdCounter.increment();
        uint256 newId = _attributeTypeIdCounter.current();
        AttributeType memory newAttr = AttributeType(newId, _attributeName, _minValue, _maxValue, _isInteger);
        registeredAttributeTypes.push(newAttr);
        attributeNameToId[_attributeName] = newId;
        attributeTypeById[newId] = newAttr; // Store by ID for direct lookup
        emit AttributeTypeRegistered(newId, _attributeName, _minValue, _maxValue, _isInteger);
    }

    /**
     * @dev 3. Retrieves the full details of a registered attribute type.
     * @param _attributeTypeId The ID of the attribute type to query.
     * @return An `AttributeType` struct containing its definition.
     */
    function getAttributeTypeDetails(uint256 _attributeTypeId) public view returns (AttributeType memory) {
        require(attributeTypeById[_attributeTypeId].id == _attributeTypeId, "Attribute type not found");
        return attributeTypeById[_attributeTypeId];
    }

    /**
     * @dev 4. Returns the total number of attribute types currently registered in the system.
     * @return The count of registered attribute types.
     */
    function getRegisteredAttributeCount() public view returns (uint256) {
        return registeredAttributeTypes.length;
    }

    /**
     * @dev 5. Mints a new EvoGenesis NFT with initial random attributes.
     *      Only callable by the contract owner.
     * @param _recipient The address that will receive ownership of the new NFT.
     * @param _initialMetadataURI An optional base URI for metadata, such as an IPFS hash pointing to an image or JSON file.
     */
    function mintInitialGenesisArt(address _recipient, string memory _initialMetadataURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_recipient, newTokenId);

        baseMetadataURI[newTokenId] = _initialMetadataURI;

        uint256[] memory initialAttributeIds = new uint256[](registeredAttributeTypes.length);
        uint256[] memory initialAttributeValues = new uint256[](registeredAttributeTypes.length);

        // Assign initial random values for all registered attribute types
        for (uint256 i = 0; i < registeredAttributeTypes.length; i++) {
            uint256 attrTypeId = registeredAttributeTypes[i].id;
            uint256 randomValue = _getRandomAttributeValue(attrTypeId, newTokenId); // Seed with tokenId for uniqueness
            tokenAttributes[newTokenId][attrTypeId] = randomValue;
            initialAttributeIds[i] = attrTypeId;
            initialAttributeValues[i] = randomValue;
        }

        _recordEvolutionEvent(newTokenId, "Mint", 0, initialAttributeIds, initialAttributeValues, "Initial minting with random attributes");
        emit GenesisArtMinted(newTokenId, _recipient, _initialMetadataURI);
    }

    /**
     * @dev 6. Retrieves all current attributes (their type IDs and corresponding values) for a specific NFT.
     * @param _tokenId The ID of the NFT to query.
     * @return Two arrays: one with attribute type IDs and another with their current values.
     */
    function getCurrentAttributes(uint256 _tokenId) public view returns (uint256[] memory attributeTypeIds, uint256[] memory values) {
        require(_exists(_tokenId), "ERC721: token does not exist");

        uint256 count = registeredAttributeTypes.length;
        attributeTypeIds = new uint256[](count);
        values = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 attrTypeId = registeredAttributeTypes[i].id;
            attributeTypeIds[i] = attrTypeId;
            values[i] = tokenAttributes[_tokenId][attrTypeId];
        }
        return (attributeTypeIds, values);
    }

    /**
     * @dev 7. Generates a dynamic metadata URI for an NFT based on its current on-chain attributes.
     *      This function constructs a JSON string compatible with ERC-721 metadata standards.
     *      NOTE: For a full 'data URI', this JSON string would typically be Base64 encoded.
     *      This example returns the raw JSON string directly, assuming an off-chain resolver
     *      or a front-end handling the Base64 encoding. On-chain Base64 encoding can be gas-intensive.
     * @param _tokenId The ID of the NFT for which to generate the metadata URI.
     * @return A JSON string representing the NFT's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        (uint256[] memory attrTypeIds, uint256[] memory attrValues) = getCurrentAttributes(_tokenId);

        string memory attributesJson = "[";
        for (uint256 i = 0; i < attrTypeIds.length; i++) {
            AttributeType memory attr = attributeTypeById[attrTypeIds[i]];
            string memory valueString;
            if (attr.isInteger) {
                valueString = attrValues[i].toString();
            } else {
                // For scaled fixed-point numbers, assume 3 decimal places for display (e.g., 1234 stored as 1.234)
                valueString = string(abi.encodePacked(
                    (attrValues[i] / 1000).toString(),
                    ".",
                    (attrValues[i] % 1000).toString()
                ));
            }
            attributesJson = string(abi.encodePacked(
                attributesJson,
                '{"trait_type": "', attr.name, '", "value": "', valueString, '", "display_type": "', attr.isInteger ? "number" : "number", '"}'
            ));
            if (i < attrTypeIds.length - 1) {
                attributesJson = string(abi.encodePacked(attributesJson, ","));
            }
        }
        attributesJson = string(abi.encodePacked(attributesJson, "]"));

        string memory name = string(abi.encodePacked("EvoGenesis Art #", _tokenId.toString()));
        string memory description = "A generative art piece that evolves through community governance and autonomous events.";

        // Construct the full JSON string
        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', baseMetadataURI[_tokenId], '",', // Use base URI for image, could point to an on-chain SVG renderer
            '"attributes": ', attributesJson,
            '}'
        ));

        // Prepend "data:application/json;base64," and Base64.encode(bytes(json)) for a full data URI.
        // As noted, this example returns raw JSON.
        return json;
    }

    /**
     * @dev 8. Allows the owner of an NFT to freeze its evolution.
     *      A frozen NFT cannot undergo mutation or cross-breeding via proposals or random triggers.
     * @param _tokenId The ID of the NFT to freeze.
     */
    function freezeEvolution(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(!isFrozen[_tokenId], "NFT is already frozen");
        isFrozen[_tokenId] = true;
        emit ArtEvolutionFrozen(_tokenId);
    }

    /**
     * @dev 9. Allows the owner of an NFT to unfreeze its evolution.
     * @param _tokenId The ID of the NFT to unfreeze.
     */
    function unfreezeEvolution(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(isFrozen[_tokenId], "NFT is not frozen");
        isFrozen[_tokenId] = false;
        emit ArtEvolutionUnfrozen(_tokenId);
    }

    /**
     * @dev 10. Retrieves the chronological evolution history of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of `EvolutionEvent` structs, detailing its past changes.
     */
    function getEvolutionHistory(uint256 _tokenId) public view returns (EvolutionEvent[] memory) {
        require(_exists(_tokenId), "ERC721: token does not exist");
        return evolutionHistory[_tokenId];
    }

    // --- II. Catalyst Token & Staking Functions ---

    /**
     * @dev 11. Allows the owner of this contract (EvoGenesis) to mint new Catalyst tokens.
     *      This serves as the initial distribution mechanism for the token.
     * @param _to The address to receive the newly minted tokens.
     * @param _amount The amount of tokens to mint (with 18 decimals by default for ERC-20).
     */
    function mintCatalyst(address _to, uint256 _amount) public onlyOwner {
        catalystToken.mint(_to, _amount);
    }

    /**
     * @dev 12. Allows a user to burn their own Catalyst tokens, permanently removing them from circulation.
     * @param _amount The amount of tokens to burn.
     */
    function burnCatalyst(uint256 _amount) public {
        catalystToken.burn(msg.sender, _amount);
    }

    /**
     * @dev 13. Allows a user to stake Catalyst tokens to gain voting power for governance proposals.
     *      Tokens are transferred from the user to this EvoGenesis contract.
     * @param _amount The amount of Catalyst tokens to stake.
     */
    function stakeCatalyst(uint256 _amount) public {
        require(_amount > 0, "Cannot stake 0");
        // Transfer Catalyst from the staker to this contract (treasury)
        catalystToken.transferFrom(msg.sender, address(this), _amount);
        stakedCatalyst[msg.sender] += _amount;
        emit CatalystStaked(msg.sender, _amount);
    }

    /**
     * @dev 14. Allows a user to unstake their Catalyst tokens, revoking their associated voting power.
     *      Tokens are transferred back from this contract to the user.
     * @param _amount The amount of Catalyst tokens to unstake.
     */
    function unstakeCatalyst(uint256 _amount) public {
        require(_amount > 0, "Cannot unstake 0");
        require(stakedCatalyst[msg.sender] >= _amount, "Insufficient staked Catalyst");
        stakedCatalyst[msg.sender] -= _amount;
        // Transfer Catalyst back from this contract (treasury) to the staker
        catalystToken.transfer(msg.sender, _amount);
        emit CatalystUnstaked(msg.sender, _amount);
    }

    /**
     * @dev 15. Returns the current voting power of an address.
     *      Voting power is directly equivalent to the amount of Catalyst tokens they have staked.
     * @param _staker The address to query.
     * @return The amount of Catalyst tokens staked by `_staker`.
     */
    function getVotingPower(address _staker) public view returns (uint256) {
        return stakedCatalyst[_staker];
    }

    // --- III. Evolution & Governance Functions ---

    /**
     * @dev 16. Allows a Catalyst staker to propose a specific mutation for an NFT.
     *      The proposer must meet the `proposalThreshold` of staked Catalyst.
     *      The `_catalystCost` is transferred to the contract's treasury upon proposal creation.
     * @param _tokenId The ID of the NFT targeted for mutation.
     * @param _attributeTypeId The ID of the specific attribute type to change.
     * @param _targetValue The new value for the attribute. Must be within the attribute's registered range.
     * @param _justification A descriptive reason for this mutation proposal.
     * @param _catalystCost The amount of Catalyst tokens to be paid if the proposal is executed. This amount is collected upfront.
     */
    function proposeMutation(
        uint256 _tokenId,
        uint256 _attributeTypeId,
        uint256 _targetValue,
        string memory _justification,
        uint256 _catalystCost
    ) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(!isFrozen[_tokenId], "NFT is frozen");
        require(stakedCatalyst[msg.sender] >= proposalThreshold, "Proposer must meet stake threshold");
        require(attributeTypeById[_attributeTypeId].id == _attributeTypeId, "Invalid attribute type ID");
        
        AttributeType memory attr = attributeTypeById[_attributeTypeId];
        require(_targetValue >= attr.minValue && _targetValue <= attr.maxValue, "Target value out of range");
        
        require(_catalystCost > 0, "Catalyst cost must be positive");
        catalystToken.transferFrom(msg.sender, address(this), _catalystCost); // Transfer cost to contract treasury

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            pType: ProposalType.Mutation,
            justification: _justification,
            catalystCost: _catalystCost,
            proposalCreationBlock: block.number,
            votingEndBlock: block.number + votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: catalystToken.totalSupply(), // Snapshot of total supply for quorum
            quorumRequired: (catalystToken.totalSupply() * quorumPercentage) / 100, // Calculate quorum dynamically
            status: ProposalStatus.Active,
            targetTokenId: _tokenId,
            secondaryTokenId: 0, // Not applicable for mutation
            relevantAttributeTypeIds: new uint256[](1),
            targetValuesOrMixRatios: new uint256[](1)
        });
        proposals[newProposalId].relevantAttributeTypeIds[0] = _attributeTypeId;
        proposals[newProposalId].targetValuesOrMixRatios[0] = _targetValue;

        emit ProposalCreated(newProposalId, msg.sender, ProposalType.Mutation, _catalystCost);
    }

    /**
     * @dev 17. Allows a Catalyst staker to propose a "cross-breeding" event for two NFTs.
     *      This combines selected attributes from `_tokenId1` and `_tokenId2` into a new state for `_tokenId1`.
     *      The `_mixRatios` define the weighted average for each attribute (0-10000 representing 0-100%).
     * @param _tokenId1 The ID of the primary NFT whose attributes will be updated.
     * @param _tokenId2 The ID of the secondary NFT from which attributes will be mixed.
     * @param _attributeTypeIdsToMix An array of attribute IDs that are targeted for mixing.
     * @param _mixRatios An array of percentages (scaled 0-10000) corresponding to `_attributeTypeIdsToMix`.
     *                   `_mixRatios[i]` determines the weight of `_tokenId1`'s value, with `10000 - _mixRatios[i]`
     *                   being the weight of `_tokenId2`'s value for the corresponding attribute.
     * @param _justification A descriptive reason for this cross-breed proposal.
     * @param _catalystCost The amount of Catalyst tokens to be paid if the proposal is executed. Collected upfront.
     */
    function proposeCrossBreed(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256[] memory _attributeTypeIdsToMix,
        uint256[] memory _mixRatios,
        string memory _justification,
        uint256 _catalystCost
    ) public {
        require(_exists(_tokenId1), "NFT 1 does not exist");
        require(_exists(_tokenId2), "NFT 2 does not exist");
        require(_tokenId1 != _tokenId2, "Cannot cross-breed with itself");
        require(!isFrozen[_tokenId1], "NFT 1 is frozen"); // Only the target NFT needs to be unfrozen
        require(stakedCatalyst[msg.sender] >= proposalThreshold, "Proposer must meet stake threshold");
        require(_attributeTypeIdsToMix.length == _mixRatios.length, "Mismatched attribute IDs and mix ratios arrays");
        require(_attributeTypeIdsToMix.length > 0, "No attributes specified to mix");

        for (uint256 i = 0; i < _mixRatios.length; i++) {
            require(_mixRatios[i] <= 10000, "Mix ratio must be <= 10000 (100%)");
            require(attributeTypeById[_attributeTypeIdsToMix[i]].id == _attributeTypeIdsToMix[i], "Invalid attribute type ID in mix list");
        }
        
        require(_catalystCost > 0, "Catalyst cost must be positive");
        catalystToken.transferFrom(msg.sender, address(this), _catalystCost); // Transfer cost to contract treasury

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            pType: ProposalType.CrossBreed,
            justification: _justification,
            catalystCost: _catalystCost,
            proposalCreationBlock: block.number,
            votingEndBlock: block.number + votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtCreation: catalystToken.totalSupply(),
            quorumRequired: (catalystToken.totalSupply() * quorumPercentage) / 100,
            status: ProposalStatus.Active,
            targetTokenId: _tokenId1,
            secondaryTokenId: _tokenId2,
            relevantAttributeTypeIds: _attributeTypeIdsToMix,
            targetValuesOrMixRatios: _mixRatios
        });

        emit ProposalCreated(newProposalId, msg.sender, ProposalType.CrossBreed, _catalystCost);
    }

    /**
     * @dev 18. Allows a Catalyst staker to cast their vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to vote in favor of the proposal, false to vote against it.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Proposal not active for voting");
        require(block.number <= proposal.votingEndBlock, "Voting period has ended");
        require(stakedCatalyst[msg.sender] > 0, "No staked Catalyst to vote");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterPower = stakedCatalyst[msg.sender];
        if (_approve) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _approve, voterPower);
    }

    /**
     * @dev 19. Retrieves all details of a specific evolution proposal.
     * @param _proposalId The ID of the proposal to fetch.
     * @return A `Proposal` struct containing all its information.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist");
        return proposals[_proposalId];
    }

    /**
     * @dev 20. Executes a proposal if its voting period has ended and it has passed the quorum and approval thresholds.
     *      Applies the proposed changes to the NFT(s) and transfers the `_catalystCost` to the treasury.
     *      Anyone can call this function after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.status != ProposalStatus.Executed, "Proposal already executed");
        require(block.number > proposal.votingEndBlock, "Voting period not ended yet");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool quorumMet = totalVotes >= proposal.quorumRequired;
        bool approved = proposal.votesFor > proposal.votesAgainst; // Simple majority

        if (quorumMet && approved) {
            // Execute the proposal based on its type
            if (proposal.pType == ProposalType.Mutation) {
                uint256 attrTypeId = proposal.relevantAttributeTypeIds[0];
                uint256 targetValue = proposal.targetValuesOrMixRatios[0];
                tokenAttributes[proposal.targetTokenId][attrTypeId] = targetValue;
                _recordEvolutionEvent(
                    proposal.targetTokenId,
                    "Mutation",
                    _proposalId,
                    proposal.relevantAttributeTypeIds,
                    proposal.targetValuesOrMixRatios,
                    proposal.justification
                );
            } else if (proposal.pType == ProposalType.CrossBreed) {
                uint256[] memory newValuesForHistory = new uint256[](proposal.relevantAttributeTypeIds.length);
                for (uint256 i = 0; i < proposal.relevantAttributeTypeIds.length; i++) {
                    uint256 attrTypeId = proposal.relevantAttributeTypeIds[i];
                    uint256 mixRatio = proposal.targetValuesOrMixRatios[i]; // 0-10000 for 0-100%
                    
                    uint256 value1 = tokenAttributes[proposal.targetTokenId][attrTypeId];
                    uint256 value2 = tokenAttributes[proposal.secondaryTokenId][attrTypeId];

                    // Calculate new value as a weighted average
                    uint256 newValue = (value1 * mixRatio + value2 * (10000 - mixRatio)) / 10000;
                    tokenAttributes[proposal.targetTokenId][attrTypeId] = newValue;
                    newValuesForHistory[i] = newValue;
                }
                _recordEvolutionEvent(
                    proposal.targetTokenId,
                    "CrossBreed",
                    _proposalId,
                    proposal.relevantAttributeTypeIds,
                    newValuesForHistory, // Store the actual new values after mixing
                    proposal.justification
                );
            }
            // For Generic proposals, specific logic would be implemented here (e.g., calling another function)

            proposal.status = ProposalStatus.Executed;
        } else {
            // Proposal failed (either quorum not met or more 'against' votes)
            proposal.status = ProposalStatus.Rejected;
            // The `_catalystCost` remains in the contract's treasury, acting as a burn for failed proposals.
        }
        emit ProposalExecuted(_proposalId, proposal.status);
    }

    /**
     * @dev 21. Allows any user to pay Catalyst to trigger a random, minor mutation on an unfrozen NFT.
     *      This provides a faster, less formal way for art to evolve compared to full DAO proposals.
     * @param _tokenId The ID of the NFT to mutate.
     * @param _catalystPayment The amount of Catalyst tokens to pay for this random evolution.
     *                         This amount is transferred to the contract's treasury.
     */
    function triggerRandomEvolution(uint256 _tokenId, uint256 _catalystPayment) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(!isFrozen[_tokenId], "NFT is frozen");
        require(_catalystPayment > 0, "Catalyst payment must be positive");
        
        catalystToken.transferFrom(msg.sender, address(this), _catalystPayment); // Transfer payment to treasury

        require(registeredAttributeTypes.length > 0, "No attribute types registered for random evolution");

        // Pick a random attribute to mutate from the registered types
        uint256 randomAttrIndex = _pseudoRandom(_tokenId, 0, registeredAttributeTypes.length - 1);
        AttributeType memory selectedAttr = registeredAttributeTypes[randomAttrIndex];
        
        uint256 currentValue = tokenAttributes[_tokenId][selectedAttr.id];
        
        // Define a deviation range (e.g., 10% of the total attribute range) for the mutation
        uint256 deviationMagnitude = (selectedAttr.maxValue - selectedAttr.minValue) / 10; 
        if (deviationMagnitude == 0 && selectedAttr.maxValue > selectedAttr.minValue) deviationMagnitude = 1; // Ensure some change for small ranges

        // Calculate min/max for the new random value, staying within attribute's overall range
        uint256 minNewValue = currentValue > deviationMagnitude ? currentValue - deviationMagnitude : selectedAttr.minValue;
        uint256 maxNewValue = currentValue + deviationMagnitude < selectedAttr.maxValue ? currentValue + deviationMagnitude : selectedAttr.maxValue;

        uint256 newRandomValue = _pseudoRandom(block.timestamp + block.difficulty, minNewValue, maxNewValue);
        
        tokenAttributes[_tokenId][selectedAttr.id] = newRandomValue;

        uint256[] memory affectedAttrIds = new uint256[](1);
        affectedAttrIds[0] = selectedAttr.id;
        uint256[] memory newValues = new uint256[](1);
        newValues[0] = newRandomValue;

        _recordEvolutionEvent(_tokenId, "RandomMutation", 0, affectedAttrIds, newValues, "Autonomous random evolution triggered by payment");
        emit RandomEvolutionTriggered(_tokenId, msg.sender, _catalystPayment);
    }

    /**
     * @dev 22. Allows the contract owner to update the governance parameters of the DAO.
     *      In a fully decentralized DAO, this function itself would be subject to a governance proposal.
     * @param _newProposalThreshold The new minimum Catalyst stake required to propose an evolution.
     * @param _newVotingPeriodBlocks The new number of blocks for a proposal's voting period.
     * @param _newQuorumPercentage The new percentage (0-100) of total voting power needed for a proposal to meet quorum.
     */
    function updateGovernanceParameters(uint256 _newProposalThreshold, uint256 _newVotingPeriodBlocks, uint256 _newQuorumPercentage) public onlyOwner {
        require(_newVotingPeriodBlocks > 0, "Voting period must be positive");
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100%");

        proposalThreshold = _newProposalThreshold;
        votingPeriodBlocks = _newVotingPeriodBlocks;
        quorumPercentage = _newQuorumPercentage;

        emit GovernanceParametersUpdated(_newProposalThreshold, _newVotingPeriodBlocks, _newQuorumPercentage);
    }

    /**
     * @dev 23. Allows the contract owner to withdraw accumulated Catalyst funds from the contract's treasury.
     *      These funds are collected from `_catalystCost` payments for proposals and random evolution triggers.
     *      In a more advanced DAO, this withdrawal would likely be subject to a DAO governance vote itself.
     * @param _recipient The address to send the withdrawn funds to.
     * @param _amount The amount of Catalyst tokens to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be positive");
        require(catalystToken.balanceOf(address(this)) >= _amount, "Insufficient funds in treasury");
        catalystToken.transfer(_recipient, _amount);
    }
}

/**
 * @title CatalystToken
 * @dev A simple ERC-20 token designed for the EvoGenesis system.
 *      Only the EvoGenesis contract (its owner) can mint new Catalyst tokens.
 *      Users can burn their own tokens.
 */
contract CatalystToken is ERC20, Ownable {
    /**
     * @dev Constructor for CatalystToken.
     * @param _evoGenesisContract The address of the EvoGenesis contract, which will be the owner and minter.
     */
    constructor(address _evoGenesisContract) ERC20("Catalyst", "CATALYST") Ownable(_evoGenesisContract) {
        // Initial setup, but no tokens are minted here.
        // The EvoGenesis owner can use `mintCatalyst` to distribute initial supply.
    }

    /**
     * @dev Mints new Catalyst tokens.
     *      Only callable by the owner, which is the EvoGenesis contract itself.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @dev Burns tokens from a specific address.
     *      Users can only burn their own tokens. The EvoGenesis contract (owner) can call `burn` internally
     *      via `transferFrom` in case of staking.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) public {
        require(_from == msg.sender, "Can only burn your own tokens"); // Ensure a user can only burn their own tokens
        _burn(_from, _amount);
    }
}
```