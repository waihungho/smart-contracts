This smart contract, **`AdaptiveDigitalTwinNetwork`**, introduces a novel concept of **Adaptive Digital Twins (ADTs)** represented as NFTs. These ADTs dynamically evolve and reflect the state of real-world or complex virtual entities by integrating verifiable off-chain data through decentralized oracles and applying community-governed "Adaptive Logic Modules" (ALMs).

It combines elements of:
*   **Dynamic NFTs (dNFTs):** NFT properties are mutable on-chain based on external data.
*   **Decentralized AI/Logic Integration:** Adaptive Logic Modules (ALMs) can encapsulate AI inference outcomes or complex algorithms, approved and managed by DAO.
*   **Modular Oracle Integration:** Flexible integration of various data feed sources.
*   **Decentralized Autonomous Organization (DAO):** Community governance over the network's core parameters, trusted data sources, and adaptive logic.
*   **On-chain Structured Data:** Storing rich, mutable properties for each Digital Twin directly on-chain, linked to defined schemas.

The goal is to provide a framework for creating NFTs that are not static collectibles but living, evolving digital representations.

---

## Outline

**Contract Name:** `AdaptiveDigitalTwinNetwork`

**I. Core Components & Concepts:**
*   **Digital Twin NFTs (ERC721):** Each NFT is a unique "Digital Twin" with mutable, on-chain properties.
*   **Twin Schemas:** Defines the structure (property names and types) for different categories of Digital Twins.
*   **Data Feed Sources:** External oracle contracts providing verifiable off-chain data.
*   **Adaptive Logic Modules (ALMs):** Smart contracts containing the logic to process raw data and update Twin properties. These can represent simple rules or decentralized AI model outputs.
*   **Governance (DAO):** Controlled by `ADTNToken` holders, enabling collective decision-making for approving new schemas, data sources, ALMs, and setting network fees.

**II. Function Categories:**
1.  **Twin Management (ERC721 & Properties):** Functions for minting, accessing, and initiating updates for Digital Twin NFTs.
2.  **Data Feeds & ALMs Registry:** Functions for proposing, approving, and querying information about Data Feed Sources and Adaptive Logic Modules.
3.  **Twin Schemas Management:** Functions for defining and retrieving schemas that govern the structure of Digital Twin properties.
4.  **Governance (Proposals & Voting):** Functions for creating, voting on, and executing network-level proposals.
5.  **Utility & Configuration:** Functions for setting fees and managing contract funds.

---

## Function Summary

**I. Twin Management (ERC721 & Properties)**

1.  `mintDigitalTwin(address _to, uint256 _twinSchemaId, uint256 _dataFeedSourceId, uint256 _adaptationLogicId)`: Mints a new Digital Twin NFT for `_to`, associating it with a specific schema, data feed, and adaptation logic. Initial properties are set based on the schema.
2.  `requestTwinPropertyUpdate(uint256 _tokenId)`: Initiates an update request for a Twin's properties. This triggers a call to its assigned Data Feed Source to fetch relevant data. Requires an `updateFee`.
3.  `receiveDataFeedCallback(uint256 _tokenId, bytes memory _data)`: A protected callback function used by approved Data Feed Sources to submit raw data for a requested Twin. This data is then passed to the Twin's ALM.
4.  `setTwinAdaptationLogic(uint256 _tokenId, uint256 _newLogicId)`: Allows the owner of a Digital Twin to change its assigned Adaptive Logic Module to another approved ALM.
5.  `setTwinDataFeedSource(uint256 _tokenId, uint256 _newDataFeedId)`: Allows the owner of a Digital Twin to change its assigned Data Feed Source to another approved source.
6.  `getTwinProperties(uint256 _tokenId)`: Returns a dynamic array of key-value pairs (`string` name, `bytes` value) representing a Twin's current on-chain properties.
7.  `tokenURI(uint256 _tokenId)`: Overrides ERC721 `tokenURI`. Generates a dynamic metadata URI (e.g., pointing to an API endpoint or IPFS gateway) that reflects the Twin's current on-chain properties, allowing for evolving visual representation.

**II. Data Feeds & ALMs Registry**

8.  `proposeDataFeedSource(string memory _name, address _contractAddress, bytes32 _requestSignature, bytes32 _callbackSignature)`: Creates a governance proposal to register a new Data Feed Source, specifying its name, contract address, and expected function signatures for requests and callbacks.
9.  `proposeAdaptiveLogicModule(string memory _name, address _contractAddress, bytes32 _processSignature)`: Creates a governance proposal to register a new Adaptive Logic Module, specifying its name, contract address, and the signature of its property processing function.
10. `getDataFeedInfo(uint256 _feedId)`: Retrieves detailed information (name, address, status) about a registered Data Feed Source.
11. `getAdaptiveLogicModuleInfo(uint256 _moduleId)`: Retrieves detailed information (name, address, status) about a registered Adaptive Logic Module.
12. `updateALMParameters(uint256 _almId, bytes memory _newParams)`: A governance function allowing the DAO to update configurable parameters within an approved ALM. (Assumes ALM has a function to receive and apply parameters).

**III. Twin Schemas Management**

13. `proposeTwinSchema(string memory _schemaName, string[] memory _propertyNames, uint8[] memory _propertyTypes)`: Creates a governance proposal to define a new Twin Schema, including its name and the list of expected property names and their types (e.g., UINT, STRING, BOOL).
14. `getTwinSchema(uint256 _schemaId)`: Retrieves detailed information about a registered Twin Schema, including its name, property names, and property types.

**IV. Governance (Proposals & Voting)**

15. `createProposal(bytes memory _target, bytes memory _calldata, string memory _description)`: Creates a new generic governance proposal. If passed, it will execute `_calldata` on the `_target` address (which can be this contract itself for internal config changes).
16. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows `ADTNToken` holders to cast their vote (support or oppose) on an active proposal.
17. `executeProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal after a defined timelock period.
18. `getProposalState(uint256 _proposalId)`: Returns the current state of a specific proposal (e.g., Pending, Active, Succeeded, Defeated, Executed).
19. `getCurrentVotingPower(address _voter)`: Returns the voting power of a given address, typically based on its `ADTNToken` balance (conceptual, `IADTNToken` is used).

**V. Utility & Configuration**

20. `setMintingFee(uint256 _newFee)`: A governance function to update the fee required to mint a new Digital Twin NFT.
21. `setUpdateFee(uint256 _newFee)`: A governance function to update the fee required for requesting a property update for a Digital Twin.
22. `withdrawFees(address _recipient)`: Allows the DAO (via a successful governance proposal) to withdraw collected fees from the contract to a specified recipient.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Core Components & Concepts:
//    - Digital Twin NFTs (ERC721): Represent adaptive entities.
//    - Twin Schemas: Defines structure and types of properties for Twins.
//    - Data Feed Sources: Oracles providing off-chain data.
//    - Adaptive Logic Modules (ALMs): Smart contracts defining how Twins' properties evolve.
//    - Governance: DAO for managing core parameters, approving ALMs & Data Feeds.
//    - ADTN Token: Native governance token (conceptual, not implemented here).
//
// II. Function Categories:
//    - I. Twin Management (ERC721 & Properties)
//    - II. Data Feeds & ALMs Registry
//    - III. Twin Schemas Management
//    - IV. Governance (Proposals & Voting)
//    - V. Utility & Configuration

// Function Summary:
// I. Twin Management (ERC721 & Properties)
// 1. mintDigitalTwin(address _to, uint256 _twinSchemaId, uint256 _dataFeedSourceId, uint256 _adaptationLogicId)
// 2. requestTwinPropertyUpdate(uint256 _tokenId)
// 3. receiveDataFeedCallback(uint256 _tokenId, bytes memory _data)
// 4. setTwinAdaptationLogic(uint256 _tokenId, uint256 _newLogicId)
// 5. setTwinDataFeedSource(uint256 _tokenId, uint256 _newDataFeedId)
// 6. getTwinProperties(uint256 _tokenId)
// 7. tokenURI(uint256 _tokenId)
//
// II. Data Feeds & ALMs Registry
// 8. proposeDataFeedSource(string memory _name, address _contractAddress, bytes32 _requestSignature, bytes32 _callbackSignature)
// 9. proposeAdaptiveLogicModule(string memory _name, address _contractAddress, bytes32 _processSignature)
// 10. getDataFeedInfo(uint256 _feedId)
// 11. getAdaptiveLogicModuleInfo(uint256 _moduleId)
// 12. updateALMParameters(uint256 _almId, bytes memory _newParams)
//
// III. Twin Schemas Management
// 13. proposeTwinSchema(string memory _schemaName, string[] memory _propertyNames, uint8[] memory _propertyTypes)
// 14. getTwinSchema(uint256 _schemaId)
//
// IV. Governance (Proposals & Voting)
// 15. createProposal(bytes memory _target, bytes memory _calldata, string memory _description)
// 16. voteOnProposal(uint256 _proposalId, bool _support)
// 17. executeProposal(uint256 _proposalId)
// 18. getProposalState(uint256 _proposalId)
// 19. getCurrentVotingPower(address _voter)
//
// V. Utility & Configuration
// 20. setMintingFee(uint256 _newFee)
// 21. setUpdateFee(uint256 _newFee)
// 22. withdrawFees(address _recipient)

// --- Interfaces for external components ---

// Interface for the conceptual ADTN Governance Token (ERC20-like for voting power)
interface IADTNToken {
    function balanceOf(address account) external view returns (uint256);
}

// Interface for Data Feed Source contracts (Oracles)
interface IDataFeedSource {
    // Function to request data from the oracle.
    // The oracle should eventually call back AdaptiveDigitalTwinNetwork.receiveDataFeedCallback
    function requestData(uint256 _tokenId, bytes memory _parameters) external;
}

// Interface for Adaptive Logic Module (ALM) contracts
interface IAdaptiveLogicModule {
    // Function to process raw data and current properties, returning new property values.
    // _currentProperties is encoded as (string[] names, bytes[] values)
    // _schemaId is provided to ALM to understand the property types
    function processData(
        uint256 _tokenId,
        bytes memory _rawData,
        bytes memory _currentPropertiesEncoded,
        uint256 _schemaId
    )
        external
        view
        returns (string[] memory newPropertyNames, bytes[] memory newPropertyValues);

    // Optional: A function for governance to update parameters within the ALM
    function updateParameters(bytes memory _newParams) external;
}

// --- Main Contract ---

contract AdaptiveDigitalTwinNetwork is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address; // For Address.functionCall

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE"); // Can create proposals

    // --- Enums ---

    enum PropertyType {
        UINT,
        INT,
        BOOL,
        STRING,
        ADDRESS,
        BYTES
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    // --- Structs ---

    struct TwinProperty {
        string name;
        bytes value; // The actual value, encoded
        uint8 pType; // Corresponds to PropertyType enum
    }

    struct DigitalTwin {
        uint256 twinSchemaId;
        uint256 dataFeedSourceId;
        uint256 adaptationLogicId;
        uint256 lastUpdateTime;
        uint256 updateFeePaid; // Cumulative fees paid for updates

        TwinProperty[] properties; // Array for easy iteration
        mapping(string => uint256) propertyNameToIndex; // Mapping for quick lookup
        uint256 propertyCount; // To track number of properties
    }

    struct TwinSchema {
        string name;
        string[] propertyNames;
        uint8[] propertyTypes; // Corresponds to PropertyType enum
        bool isApproved; // Only approved schemas can be used for minting
    }

    struct DataFeedSource {
        string name;
        address contractAddress;
        bytes32 requestSignature; // Expected signature for data request call
        bytes32 callbackSignature; // Expected signature for callback (e.g., receiveDataFeedCallback(uint256,bytes))
        bool isApproved;
    }

    struct AdaptiveLogicModule {
        string name;
        address contractAddress;
        bytes32 processSignature; // Expected signature for processData call
        bool isApproved;
    }

    struct Proposal {
        uint256 id;
        bytes target; // Address to call
        bytes calldata; // Calldata for the target
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 quorumVotes;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
        bool executed;
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _twinSchemaIdCounter;
    Counters.Counter private _dataFeedSourceIdCounter;
    Counters.Counter private _adaptiveLogicModuleIdCounter;

    mapping(uint256 => DigitalTwin) private _digitalTwins;
    mapping(uint256 => TwinSchema) public twinSchemas;
    mapping(uint256 => DataFeedSource) public dataFeedSources;
    mapping(uint256 => AdaptiveLogicModule) public adaptiveLogicModules;
    mapping(uint256 => Proposal) public proposals;

    uint256 public mintingFee = 0.01 ether; // Default minting fee
    uint256 public updateFee = 0.001 ether; // Default update fee

    uint256 public constant VOTING_PERIOD = 3 days; // Duration of voting
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total supply for quorum
    uint256 public constant PROPOSAL_THRESHOLD = 1; // Minimum votes to create a proposal (conceptual with ADTNToken)
    uint256 public constant TIMELOCK_DELAY = 1 days; // Delay before a successful proposal can be executed

    IADTNToken public immutable ADTN_TOKEN; // Address of the ADTN governance token

    // --- Events ---

    event DigitalTwinMinted(uint256 indexed tokenId, address indexed owner, uint256 twinSchemaId);
    event TwinPropertyUpdateRequested(uint256 indexed tokenId, address indexed requester, uint256 feePaid);
    event TwinPropertiesUpdated(uint256 indexed tokenId, uint256 lastUpdateTime);
    event TwinAdaptationLogicSet(uint256 indexed tokenId, uint256 oldLogicId, uint256 newLogicId);
    event TwinDataFeedSourceSet(uint256 indexed tokenId, uint256 oldFeedId, uint256 newFeedId);

    event DataFeedSourceProposed(uint256 indexed proposalId, uint256 indexed sourceId, string name);
    event AdaptiveLogicModuleProposed(uint256 indexed proposalId, uint256 indexed moduleId, string name);
    event TwinSchemaProposed(uint256 indexed proposalId, uint256 indexed schemaId, string name);
    event ALMParametersUpdated(uint256 indexed almId, bytes newParams);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    event MintingFeeSet(uint256 oldFee, uint256 newFee);
    event UpdateFeeSet(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor(address _adtnTokenAddress, string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initially, the deployer is also a GOVERNOR and PROPOSER
        _grantRole(GOVERNOR_ROLE, msg.sender);
        _grantRole(PROPOSER_ROLE, msg.sender);

        require(_adtnTokenAddress != address(0), "ADTN Token address cannot be zero");
        ADTN_TOKEN = IADTNToken(_adtnTokenAddress);
    }

    // --- Modifiers ---

    modifier onlyDataFeedApproved(uint256 _feedId) {
        require(dataFeedSources[_feedId].isApproved, "Data feed source not approved");
        _;
    }

    modifier onlyALMApproved(uint256 _moduleId) {
        require(adaptiveLogicModules[_moduleId].isApproved, "ALM not approved");
        _;
    }

    // --- I. Twin Management (ERC721 & Properties) ---

    // 1. mintDigitalTwin(address _to, uint256 _twinSchemaId, uint256 _dataFeedSourceId, uint256 _adaptationLogicId)
    function mintDigitalTwin(
        address _to,
        uint256 _twinSchemaId,
        uint256 _dataFeedSourceId,
        uint256 _adaptationLogicId
    ) public payable {
        require(msg.value >= mintingFee, "Insufficient minting fee");
        require(twinSchemas[_twinSchemaId].isApproved, "Twin schema not approved");
        require(dataFeedSources[_dataFeedSourceId].isApproved, "Data feed source not approved");
        require(adaptiveLogicModules[_adaptationLogicId].isApproved, "Adaptive logic module not approved");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);

        DigitalTwin storage newTwin = _digitalTwins[newItemId];
        newTwin.twinSchemaId = _twinSchemaId;
        newTwin.dataFeedSourceId = _dataFeedSourceId;
        newTwin.adaptationLogicId = _adaptationLogicId;
        newTwin.lastUpdateTime = block.timestamp;
        newTwin.updateFeePaid = 0; // Initialize

        // Initialize properties based on the schema
        TwinSchema storage schema = twinSchemas[_twinSchemaId];
        for (uint256 i = 0; i < schema.propertyNames.length; i++) {
            string memory propName = schema.propertyNames[i];
            uint8 propType = schema.propertyTypes[i];
            newTwin.properties.push(TwinProperty({name: propName, value: "", pType: propType})); // Empty value init
            newTwin.propertyNameToIndex[propName] = newTwin.propertyCount;
            newTwin.propertyCount++;
        }

        emit DigitalTwinMinted(newItemId, _to, _twinSchemaId);
    }

    // 2. requestTwinPropertyUpdate(uint256 _tokenId)
    function requestTwinPropertyUpdate(uint256 _tokenId) public payable {
        require(_exists(_tokenId), "Digital Twin does not exist");
        require(msg.value >= updateFee, "Insufficient update fee");

        DigitalTwin storage twin = _digitalTwins[_tokenId];
        DataFeedSource storage feed = dataFeedSources[twin.dataFeedSourceId];
        require(feed.isApproved, "Assigned data feed is not approved");

        twin.updateFeePaid += updateFee;

        // Construct current properties to pass to ALM later (packed for cross-contract call)
        (string[] memory names, bytes[] memory values) = getTwinProperties(_tokenId);
        bytes memory currentPropertiesEncoded = abi.encode(names, values);

        // Call the data feed source contract to request data
        // Parameters for requestData are specific to the IDataFeedSource implementation
        // For simplicity, we pass the tokenId and current properties as parameters.
        // The DataFeedSource is expected to eventually call back `receiveDataFeedCallback`.
        IDataFeedSource(feed.contractAddress).requestData(_tokenId, currentPropertiesEncoded);

        emit TwinPropertyUpdateRequested(_tokenId, msg.sender, msg.value);
    }

    // 3. receiveDataFeedCallback(uint256 _tokenId, bytes memory _data)
    // This function is called by an approved Data Feed Source after it has fetched data.
    // It processes the data using the Twin's assigned ALM and updates properties.
    function receiveDataFeedCallback(uint256 _tokenId, bytes memory _data) public {
        require(_exists(_tokenId), "Digital Twin does not exist");

        DigitalTwin storage twin = _digitalTwins[_tokenId];
        DataFeedSource storage feed = dataFeedSources[twin.dataFeedSourceId];
        AdaptiveLogicModule storage alm = adaptiveLogicModules[twin.adaptationLogicId];

        // Ensure only the registered and approved data feed can call this for its assigned twin
        require(msg.sender == feed.contractAddress, "Only assigned data feed can call back");
        require(feed.isApproved, "Data feed not approved");
        require(alm.isApproved, "Adaptive logic module not approved");

        // Construct current properties to pass to ALM
        (string[] memory currentNames, bytes[] memory currentValues) = getTwinProperties(_tokenId);
        bytes memory currentPropertiesEncoded = abi.encode(currentNames, currentValues);

        // Call the Adaptive Logic Module to process the data
        (string[] memory newPropertyNames, bytes[] memory newPropertyValues) =
            IAdaptiveLogicModule(alm.contractAddress).processData(
                _tokenId,
                _data,
                currentPropertiesEncoded,
                twin.twinSchemaId
            );

        // Apply property updates
        _applyPropertyUpdates(twin, newPropertyNames, newPropertyValues);

        twin.lastUpdateTime = block.timestamp;

        emit TwinPropertiesUpdated(_tokenId, twin.lastUpdateTime);
    }

    // Internal helper to apply property updates
    function _applyPropertyUpdates(
        DigitalTwin storage twin,
        string[] memory newPropertyNames,
        bytes[] memory newPropertyValues
    ) internal {
        require(newPropertyNames.length == newPropertyValues.length, "Mismatched property arrays");
        TwinSchema storage schema = twinSchemas[twin.twinSchemaId];

        for (uint256 i = 0; i < newPropertyNames.length; i++) {
            string memory newName = newPropertyNames[i];
            bytes memory newValue = newPropertyValues[i];

            uint256 propIndex = twin.propertyNameToIndex[newName];
            // Check if the property name exists in the schema and the twin
            bool foundInSchema = false;
            uint8 expectedType = 0;
            for(uint256 j=0; j < schema.propertyNames.length; j++){
                if(keccak256(abi.encodePacked(schema.propertyNames[j])) == keccak256(abi.encodePacked(newName))){
                    foundInSchema = true;
                    expectedType = schema.propertyTypes[j];
                    break;
                }
            }
            require(foundInSchema, string.concat("Property '", newName, "' not defined in twin schema"));
            require(propIndex < twin.propertyCount, string.concat("Property '", newName, "' not initialized for twin"));

            // Update the existing property
            twin.properties[propIndex].value = newValue;
            twin.properties[propIndex].pType = expectedType; // Ensure type is consistent with schema
        }
    }

    // 4. setTwinAdaptationLogic(uint256 _tokenId, uint256 _newLogicId)
    function setTwinAdaptationLogic(uint256 _tokenId, uint256 _newLogicId) public {
        require(_exists(_tokenId), "Digital Twin does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only Twin owner can set adaptation logic");
        require(adaptiveLogicModules[_newLogicId].isApproved, "New adaptation logic not approved");

        DigitalTwin storage twin = _digitalTwins[_tokenId];
        uint256 oldLogicId = twin.adaptationLogicId;
        twin.adaptationLogicId = _newLogicId;

        emit TwinAdaptationLogicSet(_tokenId, oldLogicId, _newLogicId);
    }

    // 5. setTwinDataFeedSource(uint256 _tokenId, uint256 _newDataFeedId)
    function setTwinDataFeedSource(uint256 _tokenId, uint256 _newDataFeedId) public {
        require(_exists(_tokenId), "Digital Twin does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only Twin owner can set data feed source");
        require(dataFeedSources[_newDataFeedId].isApproved, "New data feed source not approved");

        DigitalTwin storage twin = _digitalTwins[_tokenId];
        uint256 oldFeedId = twin.dataFeedSourceId;
        twin.dataFeedSourceId = _newDataFeedId;

        emit TwinDataFeedSourceSet(_tokenId, oldFeedId, _newDataFeedId);
    }

    // 6. getTwinProperties(uint256 _tokenId)
    function getTwinProperties(uint256 _tokenId)
        public
        view
        returns (string[] memory names, bytes[] memory values)
    {
        require(_exists(_tokenId), "Digital Twin does not exist");
        DigitalTwin storage twin = _digitalTwins[_tokenId];

        names = new string[](twin.propertyCount);
        values = new bytes[](twin.propertyCount);

        for (uint256 i = 0; i < twin.propertyCount; i++) {
            names[i] = twin.properties[i].name;
            values[i] = twin.properties[i].value;
        }
        return (names, values);
    }

    // 7. tokenURI(uint256 _tokenId) - Overridden from ERC721
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        DigitalTwin storage twin = _digitalTwins[_tokenId];
        TwinSchema storage schema = twinSchemas[twin.twinSchemaId];

        // Construct a dynamic URI to a metadata API endpoint or IPFS gateway
        // This endpoint would fetch the on-chain properties and generate JSON.
        // Example: https://api.yourdomain.com/metadata/{tokenId}
        // Or for IPFS: ipfs://<CID_OF_RESOLVER_SCRIPT>?tokenId={_tokenId}
        // For simplicity, we return a placeholder string.
        // A real implementation would involve fetching properties and composing JSON.
        // The client-side (frontend, marketplace) would query getTwinProperties()
        // and combine it with schema info to display rich metadata.

        string memory json = string(
            abi.encodePacked(
                '{"name": "Digital Twin #',
                _tokenId.toString(),
                '", "description": "An adaptive digital twin.", "image": "ipfs://Qmb...", "attributes": ['
            )
        );

        for (uint256 i = 0; i < twin.propertyCount; i++) {
            TwinProperty storage prop = twin.properties[i];
            string memory propVal = "";
            // Decode bytes based on pType for display in URI
            if (prop.pType == uint8(PropertyType.UINT)) {
                propVal = abi.decode(prop.value, (uint256)).toString();
            } else if (prop.pType == uint8(PropertyType.INT)) {
                propVal = abi.decode(prop.value, (int256)).toString(); // Needs int256 to string conversion
            } else if (prop.pType == uint8(PropertyType.BOOL)) {
                propVal = abi.decode(prop.value, (bool)) ? "true" : "false";
            } else if (prop.pType == uint8(PropertyType.STRING)) {
                propVal = string(abi.decode(prop.value, (string)));
            } else if (prop.pType == uint8(PropertyType.ADDRESS)) {
                propVal = Strings.toHexString(abi.decode(prop.value, (address)));
            } else if (prop.pType == uint8(PropertyType.BYTES)) {
                propVal = Strings.toHexString(prop.value);
            }

            json = string(
                abi.encodePacked(
                    json,
                    '{"trait_type": "',
                    prop.name,
                    '", "value": "',
                    propVal,
                    '"}',
                    (i == twin.propertyCount - 1 ? "" : ",")
                )
            );
        }

        json = string(abi.encodePacked(json, ']}'));

        // For simplicity, directly embedding data URI. In production, use IPFS or a dedicated API.
        return string(abi.encodePacked("data:application/json;base64,", _encodeBase64(bytes(json))));
    }

    // Internal function to encode bytes to Base64 (simplified for example)
    function _encodeBase64(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory encoded = new bytes((data.length + 2) / 3 * 4);
        uint256 i;
        uint256 j;
        for (i = 0; i < data.length; i += 3) {
            uint256 value = uint256(data[i]) << 16;
            if (i + 1 < data.length) value |= uint256(data[i + 1]) << 8;
            if (i + 2 < data.length) value |= uint256(data[i + 2]);

            encoded[j++] = alphabet[(value >> 18) & 0x3F];
            encoded[j++] = alphabet[(value >> 12) & 0x3F];
            encoded[j++] = alphabet[(value >> 6) & 0x3F];
            encoded[j++] = alphabet[value & 0x3F];
        }
        if (data.length % 3 == 1) {
            encoded[encoded.length - 1] = "=";
            encoded[encoded.length - 2] = "=";
        } else if (data.length % 3 == 2) {
            encoded[encoded.length - 1] = "=";
        }
        return string(encoded);
    }

    // --- II. Data Feeds & ALMs Registry ---

    // 8. proposeDataFeedSource(string memory _name, address _contractAddress, bytes32 _requestSignature, bytes32 _callbackSignature)
    function proposeDataFeedSource(
        string memory _name,
        address _contractAddress,
        bytes32 _requestSignature,
        bytes32 _callbackSignature
    ) public onlyRole(PROPOSER_ROLE) returns (uint256 proposalId) {
        _dataFeedSourceIdCounter.increment();
        uint256 newSourceId = _dataFeedSourceIdCounter.current();

        dataFeedSources[newSourceId] = DataFeedSource({
            name: _name,
            contractAddress: _contractAddress,
            requestSignature: _requestSignature,
            callbackSignature: _callbackSignature,
            isApproved: false // Requires governance approval
        });

        // Create a proposal to approve this data feed
        bytes memory _calldata = abi.encodeWithSelector(
            this.approveDataFeedSource.selector,
            newSourceId
        );
        proposalId = createProposal(
            address(this),
            _calldata,
            string(abi.encodePacked("Approve new Data Feed Source: ", _name, " (ID: ", newSourceId.toString(), ")"))
        );

        emit DataFeedSourceProposed(proposalId, newSourceId, _name);
        return proposalId;
    }

    // Internal function called by governance to approve a data feed source
    function approveDataFeedSource(uint256 _sourceId) public onlyRole(GOVERNOR_ROLE) {
        require(_sourceId > 0 && _sourceId <= _dataFeedSourceIdCounter.current(), "Invalid Data Feed Source ID");
        require(!dataFeedSources[_sourceId].isApproved, "Data Feed Source already approved");
        dataFeedSources[_sourceId].isApproved = true;
    }

    // 9. proposeAdaptiveLogicModule(string memory _name, address _contractAddress, bytes32 _processSignature)
    function proposeAdaptiveLogicModule(
        string memory _name,
        address _contractAddress,
        bytes32 _processSignature
    ) public onlyRole(PROPOSER_ROLE) returns (uint256 proposalId) {
        _adaptiveLogicModuleIdCounter.increment();
        uint256 newModuleId = _adaptiveLogicModuleIdCounter.current();

        adaptiveLogicModules[newModuleId] = AdaptiveLogicModule({
            name: _name,
            contractAddress: _contractAddress,
            processSignature: _processSignature,
            isApproved: false // Requires governance approval
        });

        // Create a proposal to approve this ALM
        bytes memory _calldata = abi.encodeWithSelector(
            this.approveAdaptiveLogicModule.selector,
            newModuleId
        );
        proposalId = createProposal(
            address(this),
            _calldata,
            string(abi.encodePacked("Approve new Adaptive Logic Module: ", _name, " (ID: ", newModuleId.toString(), ")"))
        );

        emit AdaptiveLogicModuleProposed(proposalId, newModuleId, _name);
        return proposalId;
    }

    // Internal function called by governance to approve an ALM
    function approveAdaptiveLogicModule(uint256 _moduleId) public onlyRole(GOVERNOR_ROLE) {
        require(_moduleId > 0 && _moduleId <= _adaptiveLogicModuleIdCounter.current(), "Invalid ALM ID");
        require(!adaptiveLogicModules[_moduleId].isApproved, "ALM already approved");
        adaptiveLogicModules[_moduleId].isApproved = true;
    }

    // 10. getDataFeedInfo(uint256 _feedId)
    function getDataFeedInfo(uint256 _feedId)
        public
        view
        returns (string memory name, address contractAddress, bool isApproved)
    {
        require(_feedId > 0 && _feedId <= _dataFeedSourceIdCounter.current(), "Invalid Data Feed Source ID");
        DataFeedSource storage feed = dataFeedSources[_feedId];
        return (feed.name, feed.contractAddress, feed.isApproved);
    }

    // 11. getAdaptiveLogicModuleInfo(uint256 _moduleId)
    function getAdaptiveLogicModuleInfo(uint256 _moduleId)
        public
        view
        returns (string memory name, address contractAddress, bool isApproved)
    {
        require(_moduleId > 0 && _moduleId <= _adaptiveLogicModuleIdCounter.current(), "Invalid ALM ID");
        AdaptiveLogicModule storage alm = adaptiveLogicModules[_moduleId];
        return (alm.name, alm.contractAddress, alm.isApproved);
    }

    // 12. updateALMParameters(uint256 _almId, bytes memory _newParams)
    // This function requires a governance proposal to be called.
    function updateALMParameters(uint256 _almId, bytes memory _newParams) public onlyRole(GOVERNOR_ROLE) {
        require(_almId > 0 && _almId <= _adaptiveLogicModuleIdCounter.current(), "Invalid ALM ID");
        AdaptiveLogicModule storage alm = adaptiveLogicModules[_almId];
        require(alm.isApproved, "ALM not approved");

        // Execute the updateParameters function on the ALM contract
        (bool success, ) = alm.contractAddress.call(abi.encodeWithSelector(IAdaptiveLogicModule.updateParameters.selector, _newParams));
        require(success, "Failed to update ALM parameters");

        emit ALMParametersUpdated(_almId, _newParams);
    }

    // --- III. Twin Schemas Management ---

    // 13. proposeTwinSchema(string memory _schemaName, string[] memory _propertyNames, uint8[] memory _propertyTypes)
    function proposeTwinSchema(
        string memory _schemaName,
        string[] memory _propertyNames,
        uint8[] memory _propertyTypes
    ) public onlyRole(PROPOSER_ROLE) returns (uint256 proposalId) {
        require(_propertyNames.length == _propertyTypes.length, "Mismatched property names and types length");

        _twinSchemaIdCounter.increment();
        uint256 newSchemaId = _twinSchemaIdCounter.current();

        twinSchemas[newSchemaId] = TwinSchema({
            name: _schemaName,
            propertyNames: _propertyNames,
            propertyTypes: _propertyTypes,
            isApproved: false // Requires governance approval
        });

        // Create a proposal to approve this schema
        bytes memory _calldata = abi.encodeWithSelector(this.approveTwinSchema.selector, newSchemaId);
        proposalId = createProposal(
            address(this),
            _calldata,
            string(abi.encodePacked("Approve new Twin Schema: ", _schemaName, " (ID: ", newSchemaId.toString(), ")"))
        );

        emit TwinSchemaProposed(proposalId, newSchemaId, _schemaName);
        return proposalId;
    }

    // Internal function called by governance to approve a Twin Schema
    function approveTwinSchema(uint256 _schemaId) public onlyRole(GOVERNOR_ROLE) {
        require(_schemaId > 0 && _schemaId <= _twinSchemaIdCounter.current(), "Invalid Twin Schema ID");
        require(!twinSchemas[_schemaId].isApproved, "Twin Schema already approved");
        twinSchemas[_schemaId].isApproved = true;
    }

    // 14. getTwinSchema(uint256 _schemaId)
    function getTwinSchema(uint256 _schemaId)
        public
        view
        returns (string memory name, string[] memory propertyNames, uint8[] memory propertyTypes, bool isApproved)
    {
        require(_schemaId > 0 && _schemaId <= _twinSchemaIdCounter.current(), "Invalid Twin Schema ID");
        TwinSchema storage schema = twinSchemas[_schemaId];
        return (schema.name, schema.propertyNames, schema.propertyTypes, schema.isApproved);
    }

    // --- IV. Governance (Proposals & Voting) ---

    // 15. createProposal(bytes memory _target, bytes memory _calldata, string memory _description)
    function createProposal(
        bytes memory _target,
        bytes memory _calldata,
        string memory _description
    ) public onlyRole(PROPOSER_ROLE) returns (uint256 proposalId) {
        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            target: _target,
            calldata: _calldata,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            quorumVotes: (ADTN_TOKEN.balanceOf(address(this)) * QUORUM_PERCENTAGE) / 100, // Dynamic quorum
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    // 16. voteOnProposal(uint256 _proposalId, bool _support)
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime, "Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "Voting has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterVotes = getCurrentVotingPower(msg.sender);
        require(voterVotes >= PROPOSAL_THRESHOLD, "Insufficient voting power");

        if (_support) {
            proposal.yesVotes += voterVotes;
        } else {
            proposal.noVotes += voterVotes;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterVotes);
    }

    // 17. executeProposal(uint256 _proposalId)
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");

        // Check if proposal succeeded
        if (
            proposal.yesVotes > proposal.noVotes &&
            proposal.yesVotes >= proposal.quorumVotes
        ) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Defeated;
        }

        require(proposal.state == ProposalState.Succeeded, "Proposal did not succeed");
        require(block.timestamp >= proposal.voteEndTime + TIMELOCK_DELAY, "Timelock delay not passed");

        // Execute the proposal's calldata on its target
        (bool success, ) = proposal.target.functionCall(proposal.calldata);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(_proposalId);
    }

    // 18. getProposalState(uint256 _proposalId)
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.timestamp <= proposal.voteEndTime) {
            return ProposalState.Active;
        } else {
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes >= proposal.quorumVotes) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
    }

    // 19. getCurrentVotingPower(address _voter)
    function getCurrentVotingPower(address _voter) public view returns (uint256) {
        // In a real scenario, this would use a snapshot mechanism to get voting power
        // at the start of the voting period, or use a specific governance token balance.
        // For simplicity, it directly queries the ADTN_TOKEN balance.
        return ADTN_TOKEN.balanceOf(_voter);
    }

    // --- V. Utility & Configuration ---

    // 20. setMintingFee(uint256 _newFee)
    function setMintingFee(uint256 _newFee) public onlyRole(GOVERNOR_ROLE) {
        uint256 oldFee = mintingFee;
        mintingFee = _newFee;
        emit MintingFeeSet(oldFee, _newFee);
    }

    // 21. setUpdateFee(uint256 _newFee)
    function setUpdateFee(uint256 _newFee) public onlyRole(GOVERNOR_ROLE) {
        uint256 oldFee = updateFee;
        updateFee = _newFee;
        emit UpdateFeeSet(oldFee, _newFee);
    }

    // 22. withdrawFees(address _recipient)
    function withdrawFees(address _recipient) public onlyRole(GOVERNOR_ROLE) {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No fees to withdraw");
        (bool success, ) = payable(_recipient).call{value: contractBalance}("");
        require(success, "Failed to withdraw fees");
        emit FeesWithdrawn(_recipient, contractBalance);
    }

    // Fallback function to receive ether for fees
    receive() external payable {}

    // Public getter for DigitalTwin struct (partial, direct access to struct mapping is not possible)
    function getDigitalTwin(uint256 _tokenId)
        public
        view
        returns (
            uint256 twinSchemaId,
            uint256 dataFeedSourceId,
            uint256 adaptationLogicId,
            uint256 lastUpdateTime,
            uint256 updateFeePaid
        )
    {
        require(_exists(_tokenId), "Digital Twin does not exist");
        DigitalTwin storage twin = _digitalTwins[_tokenId];
        return (
            twin.twinSchemaId,
            twin.dataFeedSourceId,
            twin.adaptationLogicId,
            twin.lastUpdateTime,
            twin.updateFeePaid
        );
    }
}
```