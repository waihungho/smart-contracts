This smart contract, **ContextualDataNexus**, proposes a novel decentralized platform for managing, monetizing, and accessing contextual data. It combines several advanced and trendy concepts: Dynamic NFTs, on-chain reputation systems, a lightweight contextual knowledge graph, and hooks for off-chain proofs of data integrity and utility. The goal is to provide a robust, transparent, and incentive-aligned ecosystem for data sharing, moving beyond simple data marketplaces to a system where data provenance, quality, and usage are verifiable and contribute to a user's on-chain identity and reputation.

---

### **Outline and Function Summary:**

**Contract Name:** `ContextualDataNexus` (main contract) and `DynamicAccessToken` (ERC721 extension).

#### **Core Idea:**

The **ContextualDataNexus** acts as the central hub. Data Providers (DPs) register metadata for their off-chain datasets, define access policies, and earn from data access. Data Consumers (DCs) request access, which is granted via **Dynamic Access Tokens (DATs)** – special ERC721 NFTs. DATs' metadata changes dynamically based on their status (active, expired, revoked) and the underlying dataset. Both DPs and DCs build **Reputation Scores** based on their interactions, which influences access requirements and visibility. Datasets can be linked via **Context Tags** and **Semantic Relationships**, forming a discoverable knowledge graph. The system also includes conceptual hooks for **Data Integrity and Utility Proofs** using cryptographic hashes, acknowledging the role of off-chain computation and zero-knowledge proofs.

#### **Function Categories (27 functions in total):**

**I. Core Registry & Management (Data Providers)**
1.  **`registerDataProvider(string memory _name, string memory _contactInfo)`**: Onboards a new Data Provider (DP) to the platform.
2.  **`updateDataProviderProfile(string memory _newName, string memory _newContactInfo)`**: Allows an active DP to update their registered profile details.
3.  **`deregisterDataProvider()`**: Marks a DP's account as inactive, preventing them from registering new data or defining new policies.
4.  **`registerDataSet(string memory _ipfsHash, string memory _name, string memory _description, bytes32[] memory _contextTags)`**: Registers metadata for a new dataset. The actual data is stored off-chain (e.g., IPFS) and referenced by `_ipfsHash`.
5.  **`updateDataSetMetadata(uint256 _dataSetId, string memory _newIpfsHash, string memory _newName, string memory _newDescription, bytes32[] memory _newContextTags)`**: Allows a DP to update the metadata of their existing dataset.
6.  **`retireDataSet(uint256 _dataSetId)`**: Marks a dataset as retired, preventing new access grants while existing DATs remain valid until expiration.

**II. Access Policies & Monetization**
7.  **`defineAccessPolicy(uint256 _dataSetId, uint256 _pricePerAccess, uint256 _durationSeconds, address _paymentToken, bool _requireReputation, uint256 _minReputation)`**: Sets the pricing, duration, payment token, and reputation requirements for accessing a specific dataset.
8.  **`updateAccessPolicy(uint256 _dataSetId, uint256 _newPrice, uint256 _newDuration, address _newPaymentToken, bool _newRequireRep, uint256 _newMinReputation)`**: Modifies an existing access policy for a dataset.
9.  **`requestDataSetAccess(uint256 _dataSetId)`**: A Data Consumer (DC) initiates the process to gain access. This function handles payment and triggers the minting of a Dynamic Access Token (DAT).
10. **`extendDataSetAccess(uint256 _datTokenId, uint256 _additionalDuration)`**: Allows a DC to extend the active duration of their existing DAT by making an additional payment.

**III. Dynamic Access Token (DAT) Management (ERC721-based)**
11. **`getAccessExpiration(uint256 _datTokenId)`**: Retrieves the exact UTC timestamp when a specific DAT will expire. (Wraps a `DynamicAccessToken` function).
12. **`isAccessActive(uint256 _datTokenId)`**: Checks if a DAT is currently valid (not expired and not revoked). (Wraps a `DynamicAccessToken` function).
13. **`transferAccessFunds(uint256 _dataSetId, address _tokenAddress)`**: Allows a Data Provider to withdraw collected payment funds for their dataset in a specific token.
14. **`revokeDataSetAccess(uint256 _datTokenId, string memory _reasonHash)`**: Allows the associated Data Provider or the contract owner to prematurely revoke access for a DAT, potentially due to terms violation.

**IV. Reputation System**
15. **`submitReputationFeedback(address _targetAddress, bool _isPositive, string memory _feedbackHash)`**: Allows any user to submit positive or negative feedback on another user (DP or DC), impacting their on-chain reputation score. `_feedbackHash` references off-chain details.
16. **`challengeReputationFeedback(address _targetAddress, uint256 _feedbackIndex, string memory _reasonHash)`**: Allows a user to dispute a specific piece of feedback given about them, marking it for review.
17. **`resolveReputationChallenge(address _targetAddress, uint256 _feedbackIndex, bool _challengeAccepted)`**: An administrative (owner-only) function to resolve a feedback dispute. If the challenge is accepted, the original feedback's impact is reversed, and the reporter may be penalized.
18. **`getReputationScore(address _userAddress)`**: Retrieves the current aggregated reputation score for a given user address.
19. **`getReputationDetails(address _userAddress)`**: Returns an array of all individual feedback entries (hashes, scores, status) for a user.

**V. Contextual Linkage & Discovery**
20. **`createContextTag(string memory _tagName)`**: An administrative (owner-only) function to register a new, globally recognized context tag (e.g., "ClimateData", "MedicalResearch").
21. **`linkDataSetsByContext(uint256 _dataSetIdA, uint256 _dataSetIdB, bytes32 _relationshipType)`**: Establishes a semantic link between two datasets (e.g., "derived_from", "related_to") using a predefined relationship type hash.
22. **`queryDatasetsByTag(bytes32 _contextTag, uint256 _minReputation, uint256 _maxPrice, address _paymentToken)`**: Allows consumers to discover relevant datasets based on a specific context tag and optional filtering criteria (reputation, price, payment token).
23. **`queryLinkedDatasets(uint256 _dataSetId, bytes32 _relationshipType)`**: Finds datasets that are semantically linked to a specified dataset via a particular relationship type.

**VI. Data Integrity & Utility Proofs (Advanced & Conceptual)**
24. **`attestDataIntegrity(uint256 _dataSetId, bytes32 _dataHashProof)`**: Allows a Data Provider or a third-party validator to submit a cryptographic proof (e.g., a hash) attesting to the current integrity or consistency of an off-chain dataset.
25. **`submitDataUtilityProof(uint256 _datTokenId, bytes32 _proofOfUseCommitment)`**: A Data Consumer submits a commitment (e.g., a hash of a Zero-Knowledge Proof) indicating they have used the data according to its terms. This serves as a conceptual hook for off-chain verifiable computation and can potentially boost consumer reputation.
26. **`disputeDataSetIntegrity(uint256 _dataSetId, string memory _reasonHash)`**: A user can register a dispute regarding the integrity or quality of a dataset, potentially triggering a dispute resolution process.

**VII. Administrative Functions (Specific to ContextualDataNexus)**
27. **`setDATContractAddress(address _datContractAddress)`**: Sets the address of the deployed `DynamicAccessToken` ERC721 contract. This allows the main contract to interact with and manage the DATs.

---

The `DynamicAccessToken` contract is an ERC721-compliant token that leverages `ERC721URIStorage` to enable dynamic token metadata. Its `tokenURI` function queries the `ContextualDataNexus` contract to construct a rich, up-to-date JSON string reflecting the DAT's status (active, expired, revoked) and the underlying dataset's metadata, which is then Base64 encoded.

This architecture aims for a highly interactive, self-governing, and transparent data ecosystem where trust is built through on-chain reputation and verifiable interactions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary:
// This smart contract, "ContextualDataNexus," establishes a decentralized platform
// for managing, monetizing, and sharing contextual data access. It features
// Dynamic Access Tokens (DATs) as NFTs for granular access control, an on-chain
// reputation system influencing access and costs, and a contextual linkage system
// that forms a lightweight "knowledge graph" of data. It also includes hooks
// for off-chain data integrity and utility proofs.

// Core Components:
// 1.  Data Providers (DPs): Users who register and offer datasets.
// 2.  Data Consumers (DCs): Users who request and access datasets.
// 3.  Datasets: Represented by metadata on-chain (actual data off-chain, e.g., IPFS).
// 4.  Dynamic Access Tokens (DATs): ERC721 NFTs that grant time-bound, revocable
//     access to specific datasets. Their metadata (tokenURI) is dynamic.
// 5.  Reputation System: Tracks the trustworthiness of DPs and DCs based on feedback,
//     influencing access requirements and pricing.
// 6.  Contextual Linkage: Allows linking datasets via tags and relationships,
//     enabling discovery and semantic organization.
// 7.  Proof System: Mechanisms to attest to data integrity and data utility (conceptual,
//     using off-chain proofs represented by hashes).

// Function Categories:

// I. Core Registry & Management (Data Providers)
//    - registerDataProvider: Onboards a new Data Provider.
//    - updateDataProviderProfile: Allows a DP to update their public profile.
//    - deregisterDataProvider: Deactivates a DP's account.
//    - registerDataSet: Registers metadata for a new dataset.
//    - updateDataSetMetadata: Updates existing dataset's metadata.
//    - retireDataSet: Marks a dataset as no longer actively offered.

// II. Access Policies & Monetization
//    - defineAccessPolicy: Sets pricing and access rules for a dataset.
//    - updateAccessPolicy: Modifies an existing dataset's access policy.
//    - requestDataSetAccess: Consumer initiates a request to purchase access to a dataset.
//    - extendDataSetAccess: Allows a consumer to prolong their existing access.

// III. Dynamic Access Token (DAT) Management (ERC721-based)
//    - getAccessExpiration: Retrieves the expiration timestamp for a DAT.
//    - isAccessActive: Checks if a specific DAT is currently valid.
//    - transferAccessFunds: Allows a Data Provider to withdraw earned funds for a dataset.
//    - revokeDataSetAccess: Data Provider or admin can revoke a DAT due to policy violation.

// IV. Reputation System
//    - submitReputationFeedback: Users provide feedback on others (DPs/DCs).
//    - challengeReputationFeedback: Users can dispute feedback against them.
//    - resolveReputationChallenge: Admin/DAO function to mediate and resolve feedback disputes.
//    - getReputationScore: Retrieves a user's current aggregated reputation score.
//    - getReputationDetails: Provides a detailed view of feedback entries for a user.

// V. Contextual Linkage & Discovery
//    - createContextTag: Admin-only function to register new global context tags.
//    - linkDataSetsByContext: Establishes semantic links between datasets.
//    - queryDatasetsByTag: Allows consumers to discover datasets based on tags and criteria.
//    - queryLinkedDatasets: Finds datasets that are semantically linked to a given dataset.

// VI. Data Integrity & Utility Proofs (Advanced & Conceptual)
//    - attestDataIntegrity: Allows DPs or validators to attest to data consistency.
//    - submitDataUtilityProof: Consumers submit proof (hash of ZKP) of data usage.
//    - disputeDataSetIntegrity: Allows users to dispute the integrity of a dataset.

// VII. Administrative Functions (Specific to ContextualDataNexus)
//    - setDATContractAddress: Sets the address of the deployed DynamicAccessToken contract.

// The `DynamicAccessToken` contract is an ERC721URIStorage, extending ERC721
// to allow dynamic token URIs. It interacts with `ContextualDataNexus` to
// fetch the necessary metadata for its `tokenURI` generation.

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE;

        uint256 _bufferLength = data.length % 3;
        uint256 _outputLength = data.length / 3 * 4 + (_bufferLength == 0 ? 0 : 4);
        bytes memory _output = new bytes(_outputLength);

        for (uint256 i = 0; i < data.length / 3; i++) {
            uint256 a = uint256(data[i * 3]);
            uint256 b = uint256(data[i * 3 + 1]);
            uint256 c = uint256(data[i * 3 + 2]);

            _output[i * 4] = bytes1(table[a >> 2]);
            _output[i * 4 + 1] = bytes1(table[((a & 0x3) << 4) | (b >> 4)]);
            _output[i * 4 + 2] = bytes1(table[((b & 0xF) << 2) | (c >> 6)]);
            _output[i * 4 + 3] = bytes1(table[c & 0x3F]);
        }

        if (_bufferLength == 1) {
            uint256 a = uint256(data[data.length - 1]);
            _output[_output.length - 4] = bytes1(table[a >> 2]);
            _output[_output.length - 3] = bytes1(table[(a & 0x3) << 4]);
            _output[_output.length - 2] = bytes1("="[0]);
            _output[_output.length - 1] = bytes1("="[0]);
        } else if (_bufferLength == 2) {
            uint256 a = uint256(data[data.length - 2]);
            uint256 b = uint256(data[data.length - 1]);
            _output[_output.length - 4] = bytes1(table[a >> 2]);
            _output[_output.length - 3] = bytes1(table[((a & 0x3) << 4) | (b >> 4)]);
            _output[_output.length - 2] = bytes1(table[(b & 0xF) << 2]);
            _output[_output.length - 1] = bytes1("="[0]);
        }

        return string(_output);
    }
}


// Forward declaration to allow the DAT contract to reference the main contract
contract ContextualDataNexus {
    function getDataSetDetails(uint256 _dataSetId)
        public view returns (address dataProvider, string memory ipfsHash, string memory name, string memory description, bytes32[] memory contextTags);
}


contract DynamicAccessToken is ERC721URIStorage {
    address public immutable contextualDataNexus;

    struct DATInfo {
        uint256 dataSetId;
        address consumer;
        uint256 expirationTime;
        bool revoked;
    }

    mapping(uint256 => DATInfo) public datInfos; // tokenId => DATInfo
    uint256 private _nextTokenId; // Counter for DAT token IDs

    // Events
    event DATMinted(uint256 indexed tokenId, uint256 indexed dataSetId, address indexed consumer, uint256 expirationTime);
    event DATExtended(uint256 indexed tokenId, uint256 newExpirationTime);
    event DATRevoked(uint256 indexed tokenId, string reasonHash);

    constructor(address _contextualDataNexusAddress) ERC721("DynamicAccessToken", "DAT") {
        require(_contextualDataNexusAddress != address(0), "CDNX address cannot be zero");
        contextualDataNexus = _contextualDataNexusAddress;
    }

    // --- Internal minting function, only callable by ContextualDataNexus ---
    function _mintDAT(uint256 _dataSetId, address _consumer, uint256 _durationSeconds)
        internal returns (uint256)
    {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(_consumer, newTokenId);

        datInfos[newTokenId] = DATInfo({
            dataSetId: _dataSetId,
            consumer: _consumer,
            expirationTime: block.timestamp + _durationSeconds,
            revoked: false
        });

        emit DATMinted(newTokenId, _dataSetId, _consumer, datInfos[newTokenId].expirationTime);
        return newTokenId;
    }

    // --- Internal function to extend a DAT's expiration ---
    function _extendDAT(uint256 _tokenId, uint256 _additionalDuration) internal {
        require(datInfos[_tokenId].expirationTime != 0, "DAT does not exist");
        datInfos[_tokenId].expirationTime += _additionalDuration;
        emit DATExtended(_tokenId, datInfos[_tokenId].expirationTime);
    }

    // --- Internal function to revoke a DAT ---
    function _revokeDAT(uint256 _tokenId, string memory _reasonHash) internal {
        require(datInfos[_tokenId].expirationTime != 0, "DAT does not exist");
        datInfos[_tokenId].revoked = true;
        emit DATRevoked(_tokenId, _reasonHash);
    }

    // --- Public getter for access expiration (III.11) ---
    function getAccessExpiration(uint256 _tokenId) public view returns (uint256) {
        return datInfos[_tokenId].expirationTime;
    }

    // --- Public checker for active access (III.12) ---
    function isAccessActive(uint256 _tokenId) public view returns (bool) {
        DATInfo storage dat = datInfos[_tokenId];
        return dat.expirationTime != 0 && !dat.revoked && dat.expirationTime > block.timestamp;
    }

    // Overrides ERC721's tokenURI to provide dynamic metadata
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");

        DATInfo storage dat = datInfos[_tokenId];
        ContextualDataNexus cdn = ContextualDataNexus(contextualDataNexus);
        
        // Fetch dataset details directly from ContextualDataNexus
        (address dataProvider, string memory ipfsHash, string memory name, string memory description, bytes32[] memory contextTags) = 
            cdn.getDataSetDetails(dat.dataSetId);

        string memory status = "active";
        if (dat.revoked) {
            status = "revoked";
        } else if (block.timestamp > dat.expirationTime) {
            status = "expired";
        }

        string memory json = string(abi.encodePacked(
            '{"name": "DAT for ', name, '",',
            '"description": "Access token for dataset: ', description, '",',
            '"image": "ipfs://Qmb8Vz1X...",', // Placeholder image hash for NFT display
            '"attributes": [',
            '{"trait_type": "DataSet ID", "value": "', Strings.toString(dat.dataSetId), '"},',
            '{"trait_type": "Data Provider", "value": "', Strings.toHexString(dataProvider), '"},',
            '{"trait_type": "Consumer", "value": "', Strings.toHexString(dat.consumer), '"},',
            '{"trait_type": "IPFS Hash", "value": "', ipfsHash, '"},',
            '{"trait_type": "Expiration", "value": "', Strings.toString(dat.expirationTime), '"},',
            '{"trait_type": "Status", "value": "', status, '"}'
        ));

        // Append context tags if any
        if (contextTags.length > 0) {
            json = string(abi.encodePacked(json, ',{"trait_type": "Context Tags", "value": "['));
            for (uint i = 0; i < contextTags.length; i++) {
                json = string(abi.encodePacked(json, '"', Strings.toHexString(uint256(contextTags[i])), '"'));
                if (i < contextTags.length - 1) {
                    json = string(abi.encodePacked(json, ","));
                }
            }
            json = string(abi.encodePacked(json, ']"'));
        }

        json = string(abi.encodePacked(json, ']}'));

        // Encode JSON to base64 for data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}


contract ContextualDataNexus is Ownable {
    // --- Data Structures ---

    struct DataProvider {
        string name;
        string contactInfo;
        bool isActive;
    }

    struct DataSet {
        address dataProvider;
        string ipfsHash;
        string name;
        string description;
        bytes32[] contextTags;
        bool isRetired;
    }

    struct AccessPolicy {
        uint256 pricePerAccess; // in smallest unit of paymentToken
        uint256 durationSeconds;
        address paymentToken; // ERC20 token address, or address(0) for native token
        bool requireReputation;
        uint256 minReputation;
        mapping(address => uint256) collectedFunds; // For each paymentToken, funds collected
    }

    struct ReputationEntry {
        address reporter;
        bool isPositive;
        string feedbackHash; // Hash of off-chain detailed feedback
        uint256 timestamp;
        bool disputed;
        bool challengeAccepted; // If dispute resolved and reporter's feedback was wrong
    }

    struct ContextTag {
        string name;
        address creator;
        uint256 creationTime;
    }

    struct DataSetLink {
        uint256 targetDataSetId;
        bytes32 relationshipType;
    }

    // --- State Variables ---

    // Global counters
    uint256 public nextDataProviderId;
    uint256 public nextDataSetId;
    uint256 public nextContextTagId; // Not used directly, but good for consistency

    // Mappings
    mapping(address => uint256) public dataProviderAddresses; // Data Provider address => ID
    mapping(uint256 => DataProvider) public dataProviders;    // ID => Data Provider struct

    mapping(uint256 => DataSet) public dataSets;             // ID => DataSet struct
    mapping(uint256 => AccessPolicy) public accessPolicies;  // DataSet ID => Access Policy

    mapping(address => int256) public reputationScores;      // User address => aggregated score
    mapping(address => ReputationEntry[]) public userReputationFeedback; // User address => array of feedback

    mapping(bytes32 => ContextTag) public contextTags;         // Hash of tag name => ContextTag struct (for unique IDs)
    bytes32[] public allContextTagHashes; // For iterating all tags

    mapping(uint256 => DataSetLink[]) public dataSetLinks;   // DataSet ID => array of linked datasets

    // Reference to the DynamicAccessToken contract
    DynamicAccessToken public datContract;

    // --- Events ---
    event DataProviderRegistered(uint256 indexed id, address indexed addr, string name);
    event DataProviderUpdated(uint256 indexed id, address indexed addr, string newName);
    event DataSetRegistered(uint256 indexed id, address indexed provider, string name, string ipfsHash);
    event DataSetPolicyDefined(uint256 indexed dataSetId, uint256 price, uint256 duration, address paymentToken);
    event AccessRequested(uint256 indexed dataSetId, address indexed consumer, uint256 paymentAmount, address paymentToken);
    event DATExtended(uint256 indexed datTokenId, uint256 newExpirationTime); // Re-emitted from DAT contract
    event FundsTransferredToDP(uint256 indexed dataSetId, address indexed dataProvider, address indexed tokenAddress, uint256 amount);
    event DATRevokedByCDN(uint256 indexed datTokenId, address indexed revoker, string reasonHash);
    event ReputationFeedbackSubmitted(address indexed target, address indexed reporter, bool isPositive, string feedbackHash);
    event ReputationChallengeSubmitted(address indexed target, uint256 feedbackIndex, string reasonHash);
    event ReputationChallengeResolved(address indexed target, uint256 feedbackIndex, bool challengeAccepted);
    event ContextTagCreated(bytes32 indexed tagHash, string tagName, address indexed creator);
    event DataSetLinked(uint256 indexed dataSetIdA, uint256 indexed dataSetIdB, bytes32 relationshipType);
    event DataIntegrityAttested(uint256 indexed dataSetId, address indexed attester, bytes32 dataHashProof);
    event DataUtilityProofSubmitted(uint256 indexed datTokenId, address indexed consumer, bytes32 proofOfUseCommitment);
    event DataSetIntegrityDisputed(uint256 indexed dataSetId, address indexed disputer, string reasonHash);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Owner is set by Ownable constructor
        // next IDs start from 1 to avoid 0 being a valid ID
        nextDataProviderId = 1;
        nextDataSetId = 1;
        // nextContextTagId is not directly used for IDs but for array tracking
    }

    // --- Modifiers ---
    modifier onlyDataProvider(uint256 _dataSetId) {
        require(dataSets[_dataSetId].dataProvider == msg.sender, "Caller is not the data provider for this dataset");
        _;
    }

    modifier onlyRegisteredDataProvider() {
        require(dataProviderAddresses[msg.sender] != 0 && dataProviders[dataProviderAddresses[msg.sender]].isActive, "Caller is not a registered and active Data Provider");
        _;
    }

    // --- Public Functions ---

    // VII. Administrative Functions (27)
    // Function to set the address of the deployed DynamicAccessToken contract
    function setDATContractAddress(address _datContractAddress) public onlyOwner {
        require(_datContractAddress != address(0), "DAT contract address cannot be zero");
        datContract = DynamicAccessToken(_datContractAddress);
    }

    // I. Core Registry & Management (Data Providers)

    // 1. Register a new Data Provider (I.1)
    function registerDataProvider(string memory _name, string memory _contactInfo) public {
        require(dataProviderAddresses[msg.sender] == 0, "Already a registered Data Provider");
        uint256 newId = nextDataProviderId++;
        dataProviders[newId] = DataProvider({
            name: _name,
            contactInfo: _contactInfo,
            isActive: true
        });
        dataProviderAddresses[msg.sender] = newId;
        emit DataProviderRegistered(newId, msg.sender, _name);
    }

    // 2. Update Data Provider profile (I.2)
    function updateDataProviderProfile(string memory _newName, string memory _newContactInfo) public onlyRegisteredDataProvider {
        uint256 dpId = dataProviderAddresses[msg.sender];
        dataProviders[dpId].name = _newName;
        dataProviders[dpId].contactInfo = _newContactInfo;
        emit DataProviderUpdated(dpId, msg.sender, _newName);
    }

    // 3. Deactivate Data Provider account (I.3)
    function deregisterDataProvider() public onlyRegisteredDataProvider {
        uint256 dpId = dataProviderAddresses[msg.sender];
        dataProviders[dpId].isActive = false; // Mark as inactive
        // Reputation score is frozen. Active datasets might need to be retired by DP first.
        emit DataProviderUpdated(dpId, msg.sender, dataProviders[dpId].name); // Emit update as deactivation
    }

    // 4. Register a new dataset metadata (I.4)
    function registerDataSet(string memory _ipfsHash, string memory _name, string memory _description, bytes32[] memory _contextTags)
        public onlyRegisteredDataProvider returns (uint256)
    {
        uint256 newId = nextDataSetId++;
        dataSets[newId] = DataSet({
            dataProvider: msg.sender,
            ipfsHash: _ipfsHash,
            name: _name,
            description: _description,
            contextTags: _contextTags,
            isRetired: false
        });
        emit DataSetRegistered(newId, msg.sender, _name, _ipfsHash);
        return newId;
    }

    // 5. Update dataset metadata (I.5)
    function updateDataSetMetadata(uint256 _dataSetId, string memory _newIpfsHash, string memory _newName, string memory _newDescription, bytes32[] memory _newContextTags)
        public onlyDataProvider(_dataSetId)
    {
        require(!dataSets[_dataSetId].isRetired, "Cannot update a retired dataset");
        dataSets[_dataSetId].ipfsHash = _newIpfsHash;
        dataSets[_dataSetId].name = _newName;
        dataSets[_dataSetId].description = _newDescription;
        dataSets[_dataSetId].contextTags = _newContextTags;
        emit DataSetRegistered(_dataSetId, msg.sender, _newName, _newIpfsHash); // Re-emit as update
    }

    // 6. Mark a dataset as retired (I.6)
    function retireDataSet(uint256 _dataSetId) public onlyDataProvider(_dataSetId) {
        require(!dataSets[_dataSetId].isRetired, "Dataset is already retired");
        dataSets[_dataSetId].isRetired = true;
        // Existing DATs for this dataset remain valid until their expiration.
        emit DataSetRegistered(_dataSetId, msg.sender, dataSets[_dataSetId].name, dataSets[_dataSetId].ipfsHash); // Re-emit as update
    }

    // Helper for DAT contract to get dataset details
    function getDataSetDetails(uint256 _dataSetId)
        public view returns (address dataProvider, string memory ipfsHash, string memory name, string memory description, bytes32[] memory contextTags)
    {
        require(msg.sender == address(datContract), "Only DAT contract can call this function");
        DataSet storage ds = dataSets[_dataSetId];
        return (ds.dataProvider, ds.ipfsHash, ds.name, ds.description, ds.contextTags);
    }


    // II. Access Policies & Monetization

    // 7. Define access policy for a dataset (II.7)
    function defineAccessPolicy(uint256 _dataSetId, uint256 _pricePerAccess, uint256 _durationSeconds, address _paymentToken, bool _requireReputation, uint256 _minReputation)
        public onlyDataProvider(_dataSetId)
    {
        require(!dataSets[_dataSetId].isRetired, "Cannot define policy for a retired dataset");
        require(_pricePerAccess > 0, "Price must be greater than zero");
        require(_durationSeconds > 0, "Duration must be greater than zero");
        if (_requireReputation) {
            require(_minReputation > 0, "Min reputation must be greater than zero if required");
        }
        accessPolicies[_dataSetId] = AccessPolicy({
            pricePerAccess: _pricePerAccess,
            durationSeconds: _durationSeconds,
            paymentToken: _paymentToken,
            requireReputation: _requireReputation,
            minReputation: _minReputation,
            collectedFunds: accessPolicies[_dataSetId].collectedFunds // Preserve existing funds
        });
        emit DataSetPolicyDefined(_dataSetId, _pricePerAccess, _durationSeconds, _paymentToken);
    }

    // 8. Update access policy for a dataset (II.8)
    function updateAccessPolicy(uint256 _dataSetId, uint256 _newPrice, uint256 _newDuration, address _newPaymentToken, bool _newRequireRep, uint256 _newMinReputation)
        public onlyDataProvider(_dataSetId)
    {
        require(accessPolicies[_dataSetId].pricePerAccess != 0, "Access policy not defined for this dataset");
        require(!dataSets[_dataSetId].isRetired, "Cannot update policy for a retired dataset");
        require(_newPrice > 0, "Price must be greater than zero");
        require(_newDuration > 0, "Duration must be greater than zero");
        if (_newRequireRep) {
            require(_newMinReputation > 0, "Min reputation must be greater than zero if required");
        }
        accessPolicies[_dataSetId].pricePerAccess = _newPrice;
        accessPolicies[_dataSetId].durationSeconds = _newDuration;
        accessPolicies[_dataSetId].paymentToken = _newPaymentToken;
        accessPolicies[_dataSetId].requireReputation = _newRequireRep;
        accessPolicies[_dataSetId].minReputation = _newMinReputation;
        emit DataSetPolicyDefined(_dataSetId, _newPrice, _newDuration, _newPaymentToken); // Re-emit as update
    }

    // 9. Data Consumer requests access to a dataset (II.9)
    function requestDataSetAccess(uint256 _dataSetId) public payable {
        require(datContract != address(0), "DAT contract not set");
        require(dataSets[_dataSetId].dataProvider != address(0), "Dataset does not exist");
        require(!dataSets[_dataSetId].isRetired, "Dataset is retired");

        AccessPolicy storage policy = accessPolicies[_dataSetId];
        require(policy.pricePerAccess > 0, "Access policy not defined or price is zero");

        if (policy.requireReputation) {
            require(reputationScores[msg.sender] >= int256(policy.minReputation), "Insufficient reputation score");
        }

        // Handle payment
        if (policy.paymentToken == address(0)) { // Native token (ETH)
            require(msg.value == policy.pricePerAccess, "Incorrect native token amount sent");
        } else { // ERC20 token
            require(msg.value == 0, "Do not send native token with ERC20 payment");
            IERC20 paymentToken = IERC20(policy.paymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), policy.pricePerAccess), "ERC20 transfer failed");
        }
        
        // Record collected funds
        policy.collectedFunds[policy.paymentToken] += policy.pricePerAccess;

        // Mint Dynamic Access Token (DAT)
        uint256 datTokenId = datContract._mintDAT(_dataSetId, msg.sender, policy.durationSeconds);

        emit AccessRequested(_dataSetId, msg.sender, policy.pricePerAccess, policy.paymentToken);
        // DATMinted event is also emitted by the DAT contract directly
    }

    // 10. Extend existing DAT access (II.10)
    function extendDataSetAccess(uint256 _datTokenId, uint256 _additionalDuration) public payable {
        require(datContract != address(0), "DAT contract not set");
        require(datContract.ownerOf(_datTokenId) == msg.sender, "Caller is not the DAT owner");

        DynamicAccessToken.DATInfo storage datInfo = datContract.datInfos(_datTokenId);
        require(datInfo.dataSetId != 0, "DAT does not exist");
        require(!datInfo.revoked, "Cannot extend a revoked DAT");

        uint256 dataSetId = datInfo.dataSetId;
        AccessPolicy storage policy = accessPolicies[dataSetId];
        require(policy.pricePerAccess > 0, "Access policy not defined for this dataset");
        require(_additionalDuration > 0, "Additional duration must be greater than zero");

        // Calculate prorated price for extension based on duration, assuming fixed rate.
        // For simplicity, prorate linearly based on policy.durationSeconds
        uint256 extensionCost = (policy.pricePerAccess * _additionalDuration) / policy.durationSeconds;
        require(extensionCost > 0, "Calculated extension cost is zero, adjust duration or policy.");

        // Handle payment for extension
        if (policy.paymentToken == address(0)) { // Native token (ETH)
            require(msg.value == extensionCost, "Incorrect native token amount sent for extension");
        } else { // ERC20 token
            require(msg.value == 0, "Do not send native token with ERC20 payment");
            IERC20 paymentToken = IERC20(policy.paymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), extensionCost), "ERC20 transfer failed for extension");
        }
        
        // Record collected funds for extension
        policy.collectedFunds[policy.paymentToken] += extensionCost;

        datContract._extendDAT(_datTokenId, _additionalDuration);
        emit DATExtended(_datTokenId, datContract.datInfos(_datTokenId).expirationTime); // Re-emit event for easier tracking
    }

    // III. Dynamic Access Token (DAT) Management (ERC721-based)

    // 11. Get DAT expiration (wrapper for DAT contract function) (III.11 - Function is in DAT contract directly)
    // 12. Check if DAT is active (wrapper for DAT contract function) (III.12 - Function is in DAT contract directly)

    // 13. Data Provider can withdraw collected funds for a specific dataset (III.13)
    function transferAccessFunds(uint256 _dataSetId, address _tokenAddress) public onlyDataProvider(_dataSetId) {
        AccessPolicy storage policy = accessPolicies[_dataSetId];
        uint256 amount = policy.collectedFunds[_tokenAddress];
        require(amount > 0, "No funds to withdraw for this dataset and token");

        policy.collectedFunds[_tokenAddress] = 0; // Reset balance first (Checks-Effects-Interactions)

        if (_tokenAddress == address(0)) { // Native token
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Failed to transfer native token");
        } else { // ERC20 token
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, amount), "Failed to transfer ERC20 token");
        }
        emit FundsTransferredToDP(_dataSetId, msg.sender, _tokenAddress, amount);
    }

    // 14. Data Provider or admin can revoke a DAT (III.14)
    function revokeDataSetAccess(uint256 _datTokenId, string memory _reasonHash) public {
        require(datContract != address(0), "DAT contract not set");
        DynamicAccessToken.DATInfo storage datInfo = datContract.datInfos(_datTokenId);
        require(datInfo.dataSetId != 0, "DAT does not exist");

        address dataProvider = dataSets[datInfo.dataSetId].dataProvider;
        require(msg.sender == dataProvider || msg.sender == owner(), "Only Data Provider or contract owner can revoke");

        require(!datInfo.revoked, "DAT is already revoked");

        datContract._revokeDAT(_datTokenId, _reasonHash);
        
        // Optionally, penalize Data Provider reputation if revoking without valid reason (e.g., challenged)
        // Or penalize Consumer if revoked due to terms violation. This would require more complex dispute logic.
        emit DATRevokedByCDN(_datTokenId, msg.sender, _reasonHash);
    }

    // IV. Reputation System

    // 15. Submit reputation feedback for a user (IV.15)
    function submitReputationFeedback(address _targetAddress, bool _isPositive, string memory _feedbackHash) public {
        require(_targetAddress != address(0) && _targetAddress != msg.sender, "Invalid target address or self-feedback");
        
        userReputationFeedback[_targetAddress].push(ReputationEntry({
            reporter: msg.sender,
            isPositive: _isPositive,
            feedbackHash: _feedbackHash,
            timestamp: block.timestamp,
            disputed: false,
            challengeAccepted: false
        }));

        if (_isPositive) {
            reputationScores[_targetAddress] += 1;
        } else {
            reputationScores[_targetAddress] -= 1;
        }
        emit ReputationFeedbackSubmitted(_targetAddress, msg.sender, _isPositive, _feedbackHash);
    }

    // 16. Challenge reputation feedback (IV.16)
    function challengeReputationFeedback(address _targetAddress, uint256 _feedbackIndex, string memory _reasonHash) public {
        require(msg.sender == _targetAddress, "Only the target of feedback can challenge it");
        require(_feedbackIndex < userReputationFeedback[_targetAddress].length, "Invalid feedback index");
        
        ReputationEntry storage feedback = userReputationFeedback[_targetAddress][_feedbackIndex];
        require(!feedback.disputed, "Feedback is already disputed");

        feedback.disputed = true; // Mark as disputed, awaiting resolution
        // _reasonHash can point to off-chain evidence for the challenge
        emit ReputationChallengeSubmitted(_targetAddress, _feedbackIndex, _reasonHash);
    }

    // 17. Admin/DAO resolves a reputation challenge (IV.17)
    function resolveReputationChallenge(address _targetAddress, uint256 _feedbackIndex, bool _challengeAccepted) public onlyOwner {
        require(_feedbackIndex < userReputationFeedback[_targetAddress].length, "Invalid feedback index");
        
        ReputationEntry storage feedback = userReputationFeedback[_targetAddress][_feedbackIndex];
        require(feedback.disputed, "Feedback is not currently disputed");
        require(!feedback.challengeAccepted, "Challenge already resolved"); // Cannot re-resolve same challenge

        feedback.challengeAccepted = _challengeAccepted;

        if (_challengeAccepted) { // If challenge accepted, the original feedback was incorrect
            // Reverse the effect of the original feedback on target's reputation
            if (feedback.isPositive) {
                reputationScores[_targetAddress] -= 1; // It was positive, but it was wrong. So negate.
                reputationScores[feedback.reporter] -= 1; // Penalize reporter for false feedback
            } else {
                reputationScores[_targetAddress] += 1; // It was negative, but it was wrong. So negate.
                reputationScores[feedback.reporter] -= 1; // Penalize reporter for false feedback
            }
        }
        // If challenge not accepted, target's reputation remains as is, reporter's reputation unaffected.
        
        emit ReputationChallengeResolved(_targetAddress, _feedbackIndex, _challengeAccepted);
    }

    // 18. Get a user's current reputation score (IV.18)
    function getReputationScore(address _userAddress) public view returns (int256) {
        return reputationScores[_userAddress];
    }

    // 19. Get detailed reputation feedback for a user (IV.19)
    function getReputationDetails(address _userAddress) public view returns (ReputationEntry[] memory) {
        return userReputationFeedback[_userAddress];
    }

    // V. Contextual Linkage & Discovery

    // 20. Admin/DAO can create new global context tags (V.20)
    function createContextTag(string memory _tagName) public onlyOwner returns (bytes32) {
        bytes32 tagHash = keccak256(abi.encodePacked(_tagName));
        require(contextTags[tagHash].creationTime == 0, "Context tag already exists");
        contextTags[tagHash] = ContextTag({
            name: _tagName,
            creator: msg.sender,
            creationTime: block.timestamp
        });
        allContextTagHashes.push(tagHash);
        emit ContextTagCreated(tagHash, _tagName, msg.sender);
        return tagHash;
    }

    // 21. Link two datasets by a specified relationship type (V.21)
    function linkDataSetsByContext(uint256 _dataSetIdA, uint256 _dataSetIdB, bytes32 _relationshipType)
        public onlyDataProvider(_dataSetIdA) // Only data provider of A can initiate a link from A
    {
        require(dataSets[_dataSetIdB].dataProvider != address(0), "Target dataset B does not exist");
        require(_dataSetIdA != _dataSetIdB, "Cannot link a dataset to itself");

        // Prevent duplicate links from A to B with the same relationship type
        for (uint i = 0; i < dataSetLinks[_dataSetIdA].length; i++) {
            if (dataSetLinks[_dataSetIdA][i].targetDataSetId == _dataSetIdB && dataSetLinks[_dataSetIdA][i].relationshipType == _relationshipType) {
                revert("Link with this relationship type already exists between these datasets");
            }
        }

        dataSetLinks[_dataSetIdA].push(DataSetLink({
            targetDataSetId: _dataSetIdB,
            relationshipType: _relationshipType
        }));
        emit DataSetLinked(_dataSetIdA, _dataSetIdB, _relationshipType);
    }

    // 22. Query datasets based on a context tag and criteria (V.22)
    function queryDatasetsByTag(bytes32 _contextTag, uint256 _minReputation, uint256 _maxPrice, address _paymentToken)
        public view returns (uint256[] memory matchingDataSetIds)
    {
        uint256[] memory tempMatchingIds = new uint256[](nextDataSetId); // Max possible size
        uint256 count = 0;

        // Iterate from 1 as IDs start from 1
        for (uint256 i = 1; i < nextDataSetId; i++) {
            DataSet storage ds = dataSets[i];
            if (ds.dataProvider == address(0) || ds.isRetired) { // Skip non-existent or retired datasets
                continue;
            }

            // Check context tag
            bool hasTag = false;
            for (uint j = 0; j < ds.contextTags.length; j++) {
                if (ds.contextTags[j] == _contextTag) {
                    hasTag = true;
                    break;
                }
            }
            if (!hasTag) {
                continue;
            }

            // Check access policy criteria
            AccessPolicy storage policy = accessPolicies[i];
            if (policy.pricePerAccess == 0) continue; // No policy defined, hence no access
            if (_maxPrice > 0 && policy.pricePerAccess > _maxPrice) continue;
            if (_paymentToken != address(0) && policy.paymentToken != _paymentToken) continue;
            // Consumer seeking data needs min_reputation to meet the policy's required_min_reputation.
            // So the consumer's _minReputation parameter is what they *desire* as minimum from data provider,
            // but the policy's min_reputation is what the *consumer needs* to have.
            // Simplified condition here: consumer searches for data where the *policy's* minReputation is less than or equal to their desired _minReputation.
            // This is a common pattern for filtering.
            if (policy.requireReputation && policy.minReputation > _minReputation) continue;

            tempMatchingIds[count++] = i;
        }

        matchingDataSetIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            matchingDataSetIds[i] = tempMatchingIds[i];
        }
        return matchingDataSetIds;
    }

    // 23. Query datasets linked to a specific dataset (V.23)
    function queryLinkedDatasets(uint256 _dataSetId, bytes32 _relationshipType) public view returns (uint256[] memory) {
        require(dataSets[_dataSetId].dataProvider != address(0), "Source dataset does not exist");

        uint256[] memory tempLinkedIds = new uint256[](dataSetLinks[_dataSetId].length);
        uint256 count = 0;

        for (uint i = 0; i < dataSetLinks[_dataSetId].length; i++) {
            DataSetLink storage link = dataSetLinks[_dataSetId][i];
            if (link.relationshipType == _relationshipType) {
                tempLinkedIds[count++] = link.targetDataSetId;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = tempLinkedIds[i];
        }
        return result;
    }

    // VI. Data Integrity & Utility Proofs (Advanced & Conceptual)

    // 24. Attest to data integrity (e.g., hash matches current off-chain data) (VI.24)
    function attestDataIntegrity(uint256 _dataSetId, bytes32 _dataHashProof) public {
        require(dataSets[_dataSetId].dataProvider != address(0), "Dataset does not exist");
        // This function would ideally be called by the data provider or a designated validator.
        // For simplicity, any user can submit an attestation, but its impact
        // on reputation would depend on a more complex validation system (e.g., DAO vote).

        // Placeholder for logic to record this attestation and potentially impact reputation.
        // For example, if multiple trusted entities attest, DP's reputation increases.
        // Or if it's the DP, it shows proactivity.
        emit DataIntegrityAttested(_dataSetId, msg.sender, _dataHashProof);
    }

    // 25. Data Consumer submits a cryptographic proof (e.g., ZKP commitment hash) that they used the data. (VI.25)
    function submitDataUtilityProof(uint256 _datTokenId, bytes32 _proofOfUseCommitment) public {
        require(datContract != address(0), "DAT contract not set");
        require(datContract.ownerOf(_datTokenId) == msg.sender, "Caller is not the DAT owner");
        require(datContract.isAccessActive(_datTokenId), "DAT is not active");

        // This function records the commitment to an off-chain proof of data utility.
        // The actual verification of the ZKP would happen off-chain, potentially triggering
        // reputation boosts for the consumer and/or the data provider if the proof is valid.
        emit DataUtilityProofSubmitted(_datTokenId, msg.sender, _proofOfUseCommitment);
        
        // Example: If successful, could give a small positive reputation to the consumer
        reputationScores[msg.sender] += 1;
    }

    // 26. A consumer or validator disputes the integrity of a dataset. (VI.26)
    function disputeDataSetIntegrity(uint256 _dataSetId, string memory _reasonHash) public {
        require(dataSets[_dataSetId].dataProvider != address(0), "Dataset does not exist");
        // This would trigger a dispute resolution process, potentially involving the DAO or admin.
        // If the dispute is valid, the data provider's reputation would be negatively impacted.
        // For now, it just records the dispute.
        emit DataSetIntegrityDisputed(_dataSetId, msg.sender, _reasonHash);
    }
}
```