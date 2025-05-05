Okay, here is a Solidity smart contract concept that combines generative art principles, dynamic NFTs, role-based access control, and royalty distribution. The core idea is a registry for generative art algorithms and parameter sets, where NFTs represent the *combination* of a specific algorithm and a specific set of parameters. These NFTs can potentially evolve by updating their linked parameter sets.

We will leverage OpenZeppelin contracts for standard functionalities like ERC721, Ownable, AccessControl, and ERC2981 (Royalties) to focus on the unique logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- GenerativeArtRegistry Smart Contract ---
//
// Purpose:
// A decentralized registry for generative art algorithms and parameter sets.
// It allows creators to register their generative code logic (via URI/hash)
// and specific parameter configurations. NFTs minted by this contract
// represent a unique combination of a registered algorithm and a registered
// parameter set, serving as a verifiable proof of a specific generative output.
//
// Advanced Concepts & Features:
// 1. On-Chain Algorithm/Parameter Registration: Stores identifiers (URIs/hashes)
//    for off-chain generative logic and data.
// 2. Dynamic NFTs: Allows updating the parameter set linked to an existing NFT,
//    enabling the artwork to 'evolve' or change based on the new parameters.
// 3. Algorithm Flags: Algorithms can be marked as allowing parameter updates
//    for tokens minted using them.
// 4. Role-Based Access Control: Uses Admin (Owner) and Curator roles to manage
//    registration, deactivation, and configuration.
// 5. Verifiable Provenance: Each NFT links directly to the registered algorithm
//    and parameters used for its generation.
// 6. ERC2981 Royalties: Implements the royalty standard, allowing flexible
//    royalty configurations at contract, algorithm, parameter set, or token levels.
// 7. Cloneable Parameter Sets: Allows easily creating new parameter sets based
//    on existing ones, fostering iteration.
// 8. Token URI Generation: The `tokenURI` function dynamically generates
//    metadata based on the linked algorithm and parameter set IDs. This would
//    typically point to an off-chain service (API) that renders the metadata
//    using the on-chain IDs.
// 9. Archiving/Deactivation: Curators can archive parameter sets or deactivate
//    algorithms to prevent new mints using them.
//
// Outline:
// - State variables and structs for algorithms, parameter sets, and token data.
// - Counters for unique IDs.
// - Mappings to store registered data and token linkages.
// - Access Control roles (Admin, Curator).
// - Events for significant actions.
// - Core ERC721 functions (inherited and overridden where needed).
// - ERC2981 Royalty functions.
// - Algorithm Management functions (register, get, update, deactivate, etc.).
// - Parameter Set Management functions (register, get, update, archive, clone, etc.).
// - Token Minting function (linking algorithm and parameters).
// - Dynamic Update function (update parameter set for a token).
// - Query functions to retrieve registry data.
// - Override `tokenURI` to provide dynamic metadata.

// Function Summary:
// -----------------------------------------------------------------------------
// Constructor: Initializes ERC721, Ownable, and AccessControl, grants admin role.
//
// Access Control (AccessControl & Ownable):
// - grantRole(bytes32 role, address account): Grant a role (Admin or Curator).
// - renounceRole(bytes32 role, address account): Renounce a role.
// - revokeRole(bytes32 role, address account): Revoke a role.
// - hasRole(bytes32 role, address account): Check if account has a role.
// - getRoleAdmin(bytes32 role): Get the admin role for a given role.
// - supportsInterface(bytes4 interfaceId): Standard check for interfaces (ERC165, ERC721, ERC2981, AccessControl).
// - transferOwnership(address newOwner): Transfer Admin role (from Ownable).
// - renounceOwnership(): Renounce Admin role (from Ownable).
//
// Algorithm Management:
// - registerAlgorithm(string memory _name, string memory _algorithmURI, bool _parametersChangable, address _defaultRoyaltyRecipient, uint96 _defaultRoyaltyBps): Register a new algorithm.
// - getAlgorithm(uint256 _algorithmId): Retrieve details for a registered algorithm.
// - updateAlgorithmURI(uint256 _algorithmId, string memory _newAlgorithmURI): Update the URI for an algorithm (Curator/Admin).
// - deactivateAlgorithm(uint256 _algorithmId): Deactivate an algorithm (Curator/Admin), preventing new mints using it.
// - activateAlgorithm(uint256 _algorithmId): Reactivate a deactivated algorithm (Curator/Admin).
// - setAlgorithmParametersChangable(uint256 _algorithmId, bool _changable): Set whether tokens minted with this algorithm can update parameters (Curator/Admin).
// - setAlgorithmDefaultRoyalty(uint256 _algorithmId, address _recipient, uint96 _basisPoints): Set the default royalty for an algorithm (Curator/Admin).
//
// Parameter Set Management:
// - registerParameterSet(string memory _name, string memory _parametersURI, address _defaultRoyaltyRecipient, uint96 _defaultRoyaltyBps): Register a new parameter set.
// - getParameterSet(uint256 _parameterSetId): Retrieve details for a registered parameter set.
// - updateParameterSetURI(uint256 _parameterSetId, string memory _newParametersURI): Update the URI for a parameter set (Curator/Admin).
// - archiveParameterSet(uint256 _parameterSetId): Archive a parameter set (Curator/Admin), preventing new mints using it.
// - unarchiveParameterSet(uint256 _parameterSetId): Unarchive an archived parameter set (Curator/Admin).
// - cloneParameterSet(uint256 _sourceParameterSetId, string memory _newName, string memory _newParametersURI): Clone an existing parameter set (Anyone can clone, must provide new details).
// - setParameterSetDefaultRoyalty(uint256 _parameterSetId, address _recipient, uint96 _basisPoints): Set the default royalty for a parameter set (Curator/Admin).
//
// Token Minting:
// - mintArtwork(address _to, uint256 _algorithmId, uint256 _parameterSetId): Mint a new NFT linking an algorithm and parameter set (Admin/Curator).
//
// Token Data & Dynamics:
// - getTokenData(uint256 _tokenId): Get the algorithm and parameter set IDs for a token.
// - updateTokenParameterSet(uint256 _tokenId, uint256 _newParameterSetId): Update the parameter set for an existing token (Token Owner, only if algorithm allows).
// - tokenURI(uint256 _tokenId): Override ERC721URIStorage to generate a dynamic metadata URI.
// - getAlgorithmIdForToken(uint256 _tokenId): Helper to get algorithm ID for a token.
// - getParameterSetIdForToken(uint256 _tokenId): Helper to get parameter set ID for a token.
//
// Royalty Management (ERC2981):
// - setDefaultRoyalty(address receiver, uint96 basisPoints): Set contract-wide default royalty (Admin).
// - setTokenRoyaltyInfo(uint256 _tokenId, address _receiver, uint96 _basisPoints): Override royalty for a specific token (Token Owner or Admin).
// - royaltyInfo(uint256 _tokenId, uint256 _salePrice): Standard ERC2981 function to get royalty details.
//
// Query Functions:
// - getTotalAlgorithms(): Get the total number of registered algorithms.
// - getTotalParameterSets(): Get the total number of registered parameter sets.
// - getAlgorithmIds(): Get an array of all registered algorithm IDs.
// - getParameterSetIds(): Get an array of all registered parameter set IDs.
// - getTokensByAlgorithm(uint256 _algorithmId): Get token IDs minted using a specific algorithm.
// - getTokensByParameterSet(uint256 _parameterSetId): Get token IDs minted using a specific parameter set.
//
// Total Functions (including inherited public/external):
// Constructor (1)
// Access Control (8) - grantRole, renounceRole, revokeRole, hasRole, getRoleAdmin, supportsInterface, transferOwnership, renounceOwnership
// Algorithm Management (7) - registerAlgorithm, getAlgorithm, updateAlgorithmURI, deactivateAlgorithm, activateAlgorithm, setAlgorithmParametersChangable, setAlgorithmDefaultRoyalty
// Parameter Set Management (7) - registerParameterSet, getParameterSet, updateParameterSetURI, archiveParameterSet, unarchiveParameterSet, cloneParameterSet, setParameterSetDefaultRoyalty
// Token Minting (1) - mintArtwork
// Token Data & Dynamics (4) - getTokenData, updateTokenParameterSet, tokenURI, getAlgorithmIdForToken, getParameterSetIdForToken (5 actually)
// Royalty Management (3) - setDefaultRoyalty, setTokenRoyaltyInfo, royaltyInfo
// Query Functions (6) - getTotalAlgorithms, getTotalParameterSets, getAlgorithmIds, getParameterSetIds, getTokensByAlgorithm, getTokensByParameterSet
// ERC721 Required (from ERC721Enumerable, ERC721URIStorage): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), tokenOfOwnerByIndex, tokenByIndex, totalSupply. (12 functions)
//
// Grand Total: 1 + 8 + 7 + 7 + 1 + 5 + 3 + 6 + 12 = 50 functions. (Well over 20)
// -----------------------------------------------------------------------------

contract GenerativeArtRegistry is ERC721URIStorage, ERC721Enumerable, Ownable, AccessControl, ERC2981 {

    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _algorithmIds;
    Counters.Counter private _parameterSetIds;

    struct Algorithm {
        bool isActive; // Can new tokens be minted using this algorithm?
        string name;
        string algorithmURI; // e.g., IPFS hash or link to the code/logic definition
        address creator;
        bool parametersChangable; // Can the parameterSetId for tokens using this algorithm be updated?
        address defaultRoyaltyRecipient;
        uint96 defaultRoyaltyBps;
    }

    struct ParameterSet {
        bool isActive; // Can new tokens be minted using this parameter set?
        string name;
        string parametersURI; // e.g., IPFS hash or link to the specific parameters (JSON, etc.)
        address creator;
        address defaultRoyaltyRecipient;
        uint96 defaultRoyaltyBps;
    }

    struct TokenData {
        uint256 algorithmId;
        uint256 parameterSetId;
    }

    mapping(uint256 => Algorithm) private _algorithms;
    mapping(uint256 => ParameterSet) private _parameterSets;
    mapping(uint256 => TokenData) private _tokenData; // tokenId => TokenData

    // Helper mappings for querying
    mapping(uint256 => uint256[]) private _tokensByAlgorithm; // algorithmId => array of tokenIds
    mapping(uint256 => uint256[]) private _tokensByParameterSet; // parameterSetId => array of tokenIds

    // ERC2981 Royalty storage for token overrides
    mapping(uint256 => address) private _tokenRoyaltyRecipient;
    mapping(uint256 => uint96) private _tokenRoyaltyBasisPoints;

    // Contract-level default royalty
    address private _defaultRoyaltyReceiver;
    uint96 private _defaultRoyaltyBasisPoints;

    // Base URI for the metadata API
    string public baseTokenURI;

    event AlgorithmRegistered(uint256 indexed algorithmId, string name, address indexed creator, string algorithmURI);
    event AlgorithmUpdated(uint256 indexed algorithmId, string newAlgorithmURI);
    event AlgorithmDeactivated(uint256 indexed algorithmId);
    event AlgorithmActivated(uint256 indexed algorithmId);
    event AlgorithmParametersChangableSet(uint256 indexed algorithmId, bool changable);
    event AlgorithmDefaultRoyaltySet(uint256 indexed algorithmId, address recipient, uint96 basisPoints);

    event ParameterSetRegistered(uint256 indexed parameterSetId, string name, address indexed creator, string parametersURI);
    event ParameterSetUpdated(uint256 indexed parameterSetId, string newParametersURI);
    event ParameterSetArchived(uint256 indexed parameterSetId);
    event ParameterSetUnarchived(uint256 indexed parameterSetId);
    event ParameterSetCloned(uint256 indexed sourceParameterSetId, uint256 indexed newParameterSetId, address indexed cloner);
    event ParameterSetDefaultRoyaltySet(uint256 indexed parameterSetId, address recipient, uint96 basisPoints);

    event ArtworkMinted(uint256 indexed tokenId, address indexed owner, uint256 algorithmId, uint256 parameterSetId);
    event TokenParameterSetUpdated(uint256 indexed tokenId, uint256 oldParameterSetId, uint256 newParameterSetId);

    event DefaultRoyaltySet(address receiver, uint96 basisPoints);
    event TokenRoyaltyInfoSet(uint256 indexed tokenId, address receiver, uint96 basisPoints);


    constructor(string memory name, string memory symbol, string memory _baseTokenURI)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets msg.sender as the initial owner (Admin)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseTokenURI = _baseTokenURI;
    }

    // --- Access Control ---

    // The owner is the default admin. We grant the admin role explicitly.
    // renounceOwnership/transferOwnership are inherited from Ownable.
    // grantRole/renounceRole/revokeRole/hasRole/getRoleAdmin from AccessControl.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Algorithm Management ---

    function registerAlgorithm(
        string memory _name,
        string memory _algorithmURI,
        bool _parametersChangable,
        address _defaultRoyaltyRecipient,
        uint96 _defaultRoyaltyBps
    ) public onlyRole(CURATOR_ROLE) returns (uint256) {
        _algorithmIds.increment();
        uint256 newId = _algorithmIds.current();
        _algorithms[newId] = Algorithm({
            isActive: true,
            name: _name,
            algorithmURI: _algorithmURI,
            creator: msg.sender,
            parametersChangable: _parametersChangable,
            defaultRoyaltyRecipient: _defaultRoyaltyRecipient,
            defaultRoyaltyBps: _defaultRoyaltyBps
        });

        emit AlgorithmRegistered(newId, _name, msg.sender, _algorithmURI);
        return newId;
    }

    function getAlgorithm(uint256 _algorithmId) public view returns (
        bool isActive,
        string memory name,
        string memory algorithmURI,
        address creator,
        bool parametersChangable,
        address defaultRoyaltyRecipient,
        uint96 defaultRoyaltyBps
    ) {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist"); // Check if ID is valid
        return (
            algo.isActive,
            algo.name,
            algo.algorithmURI,
            algo.creator,
            algo.parametersChangable,
            algo.defaultRoyaltyRecipient,
            algo.defaultRoyaltyBps
        );
    }

    function updateAlgorithmURI(uint256 _algorithmId, string memory _newAlgorithmURI)
        public onlyRole(CURATOR_ROLE)
    {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist");
        // Only Curator/Admin can update the URI reference
        algo.algorithmURI = _newAlgorithmURI;
        emit AlgorithmUpdated(_algorithmId, _newAlgorithmURI);
    }

    function deactivateAlgorithm(uint256 _algorithmId) public onlyRole(CURATOR_ROLE) {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist");
        require(algo.isActive, "Algorithm already inactive");
        algo.isActive = false;
        emit AlgorithmDeactivated(_algorithmId);
    }

    function activateAlgorithm(uint256 _algorithmId) public onlyRole(CURATOR_ROLE) {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist");
        require(!algo.isActive, "Algorithm already active");
        algo.isActive = true;
        emit AlgorithmActivated(_algorithmId);
    }

    function setAlgorithmParametersChangable(uint256 _algorithmId, bool _changable) public onlyRole(CURATOR_ROLE) {
         Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist");
        algo.parametersChangable = _changable;
        emit AlgorithmParametersChangableSet(_algorithmId, _changable);
    }

    function setAlgorithmDefaultRoyalty(uint256 _algorithmId, address _recipient, uint96 _basisPoints) public onlyRole(CURATOR_ROLE) {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0, "Algorithm does not exist");
        algo.defaultRoyaltyRecipient = _recipient;
        algo.defaultRoyaltyBps = _basisPoints;
        emit AlgorithmDefaultRoyaltySet(_algorithmId, _recipient, _basisPoints);
    }

    // --- Parameter Set Management ---

    function registerParameterSet(
        string memory _name,
        string memory _parametersURI,
        address _defaultRoyaltyRecipient,
        uint96 _defaultRoyaltyBps
    ) public returns (uint256) {
        _parameterSetIds.increment();
        uint256 newId = _parameterSetIds.current();
         _parameterSets[newId] = ParameterSet({
            isActive: true,
            name: _name,
            parametersURI: _parametersURI,
            creator: msg.sender,
            defaultRoyaltyRecipient: _defaultRoyaltyRecipient,
            defaultRoyaltyBps: _defaultRoyaltyBps
        });

        emit ParameterSetRegistered(newId, _name, msg.sender, _parametersURI);
        return newId;
    }

    function getParameterSet(uint256 _parameterSetId) public view returns (
        bool isActive,
        string memory name,
        string memory parametersURI,
        address creator,
        address defaultRoyaltyRecipient,
        uint96 defaultRoyaltyBps
    ) {
        ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0, "Parameter Set does not exist"); // Check if ID is valid
        return (
            params.isActive,
            params.name,
            params.parametersURI,
            params.creator,
            params.defaultRoyaltyRecipient,
            params.defaultRoyaltyBps
        );
    }

    function updateParameterSetURI(uint256 _parameterSetId, string memory _newParametersURI)
        public onlyRole(CURATOR_ROLE) // Or maybe creator? Restricting to Curator for control.
    {
        ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0, "Parameter Set does not exist");
        // Only Curator/Admin can update the URI reference
        params.parametersURI = _newParametersURI;
        emit ParameterSetUpdated(_parameterSetId, _newParametersURI);
    }

    function archiveParameterSet(uint256 _parameterSetId) public onlyRole(CURATOR_ROLE) {
        ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0, "Parameter Set does not exist");
        require(params.isActive, "Parameter Set already inactive");
        params.isActive = false;
        emit ParameterSetArchived(_parameterSetId);
    }

    function unarchiveParameterSet(uint256 _parameterSetId) public onlyRole(CURATOR_ROLE) {
         ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0, "Parameter Set does not exist");
        require(!params.isActive, "Parameter Set already active");
        params.isActive = true;
        emit ParameterSetUnarchived(_parameterSetId);
    }

     function cloneParameterSet(
        uint256 _sourceParameterSetId,
        string memory _newName,
        string memory _newParametersURI // New URI required as clone implies modification
    ) public returns (uint256) {
        ParameterSet storage sourceParams = _parameterSets[_sourceParameterSetId];
        require(bytes(sourceParams.name).length > 0, "Source Parameter Set does not exist");
        // Anyone can clone, creating a new set under their ownership

        _parameterSetIds.increment();
        uint256 newId = _parameterSetIds.current();
         _parameterSets[newId] = ParameterSet({
            isActive: true,
            name: _newName,
            parametersURI: _newParametersURI,
            creator: msg.sender, // New creator is msg.sender
            defaultRoyaltyRecipient: address(0), // Default royalty reset on clone
            defaultRoyaltyBps: 0
        });

        emit ParameterSetCloned(_sourceParameterSetId, newId, msg.sender);
        return newId;
     }

    function setParameterSetDefaultRoyalty(uint256 _parameterSetId, address _recipient, uint96 _basisPoints) public onlyRole(CURATOR_ROLE) {
        ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0, "Parameter Set does not exist");
        params.defaultRoyaltyRecipient = _recipient;
        params.defaultRoyaltyBps = _basisPoints;
        emit ParameterSetDefaultRoyaltySet(_parameterSetId, _recipient, _basisPoints);
    }

    // --- Token Minting ---

    function mintArtwork(address _to, uint256 _algorithmId, uint256 _parameterSetId)
        public onlyRole(CURATOR_ROLE) // Restricted to Curators or Admin for quality control
    {
        Algorithm storage algo = _algorithms[_algorithmId];
        require(bytes(algo.name).length > 0 && algo.isActive, "Algorithm does not exist or is inactive");

        ParameterSet storage params = _parameterSets[_parameterSetId];
        require(bytes(params.name).length > 0 && params.isActive, "Parameter Set does not exist or is inactive");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(_to, newTokenId);

        _tokenData[newTokenId] = TokenData({
            algorithmId: _algorithmId,
            parameterSetId: _parameterSetId
        });

        // Update helper mappings (simple append, assumes order doesn't matter for querying)
        _tokensByAlgorithm[_algorithmId].push(newTokenId);
        _tokensByParameterSet[_parameterSetId].push(newTokenId);

        // Initialize token-specific royalty override to zero
        _tokenRoyaltyRecipient[newTokenId] = address(0);
        _tokenRoyaltyBasisPoints[newTokenId] = 0;

        emit ArtworkMinted(newTokenId, _to, _algorithmId, _parameterSetId);
    }

    // --- Token Data & Dynamics ---

    function getTokenData(uint256 _tokenId) public view returns (uint256 algorithmId, uint256 parameterSetId) {
        _requireMinted(_tokenId);
        TokenData storage data = _tokenData[_tokenId];
        return (data.algorithmId, data.parameterSetId);
    }

    function updateTokenParameterSet(uint256 _tokenId, uint256 _newParameterSetId) public {
        _requireMinted(_tokenId);
        require(ownerOf(_tokenId) == msg.sender, "Only token owner can update parameters");

        TokenData storage data = _tokenData[_tokenId];
        uint256 oldParameterSetId = data.parameterSetId;
        uint256 algorithmId = data.algorithmId;

        Algorithm storage algo = _algorithms[algorithmId];
        require(algo.parametersChangable, "Algorithm does not allow parameter changes");

        ParameterSet storage newParams = _parameterSets[_newParameterSetId];
        require(bytes(newParams.name).length > 0 && newParams.isActive, "New Parameter Set does not exist or is inactive");

        data.parameterSetId = _newParameterSetId;

        // Note: Updating helper mappings for _tokensByParameterSet after update is complex/costly
        // if order matters or require removal. We'll leave them as append-only history for simplicity,
        // or rely on off-chain indexing for accurate current counts.
        // For this contract, we'll keep it simple and not update the helper array.
        // An off-chain indexer should track the *current* parameterSetId via TokenParameterSetUpdated event.

        emit TokenParameterSetUpdated(_tokenId, oldParameterSetId, _newParameterSetId);
    }

    // Override ERC721URIStorage.tokenURI to make metadata dynamic
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(_tokenId);
        TokenData storage data = _tokenData[_tokenId];
        // Construct URI like baseURI/tokenId?algorithmId=X&parameterSetId=Y
        // An off-chain service would listen for minting/update events, or query this data,
        // and generate the JSON metadata and image based on the algorithm+parameters.
        return string(abi.encodePacked(
            baseTokenURI,
            Strings.toString(_tokenId),
            "?algorithmId=", Strings.toString(data.algorithmId),
            "&parameterSetId=", Strings.toString(data.parameterSetId)
        ));
    }

    function getAlgorithmIdForToken(uint256 _tokenId) public view returns (uint256) {
        _requireMinted(_tokenId);
        return _tokenData[_tokenId].algorithmId;
    }

     function getParameterSetIdForToken(uint256 _tokenId) public view returns (uint256) {
        _requireMinted(_tokenId);
        return _tokenData[_tokenId].parameterSetId;
    }


    // --- Royalty Management (ERC2981) ---

    function setDefaultRoyalty(address receiver, uint96 basisPoints) public onlyOwner {
        _defaultRoyaltyReceiver = receiver;
        _defaultRoyaltyBasisPoints = basisPoints;
        emit DefaultRoyaltySet(receiver, basisPoints);
    }

    function setTokenRoyaltyInfo(uint256 _tokenId, address _receiver, uint96 _basisPoints) public {
        _requireMinted(_tokenId);
        require(ownerOf(_tokenId) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only token owner or admin can set token royalty");
        _tokenRoyaltyRecipient[_tokenId] = _receiver;
        _tokenRoyaltyBasisPoints[_tokenId] = _basisPoints;
        emit TokenRoyaltyInfoSet(_tokenId, _receiver, _basisPoints);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override(ERC2981) returns (address receiver, uint256 royaltyAmount) {
        _requireMinted(_tokenId);
        uint256 algoId = _tokenData[_tokenId].algorithmId;
        uint256 paramsId = _tokenData[_tokenId].parameterSetId;

        uint96 basisPoints;
        address recipient;

        // Priority: Token override > Parameter Set default > Algorithm default > Contract default
        if (_tokenRoyaltyRecipient[_tokenId] != address(0) || _tokenRoyaltyBasisPoints[_tokenId] > 0) {
             recipient = _tokenRoyaltyRecipient[_tokenId];
             basisPoints = _tokenRoyaltyBasisPoints[_tokenId];
        } else if (_parameterSets[paramsId].defaultRoyaltyRecipient != address(0) || _parameterSets[paramsId].defaultRoyaltyBps > 0) {
             recipient = _parameterSets[paramsId].defaultRoyaltyRecipient;
             basisPoints = _parameterSets[paramsId].defaultRoyaltyBps;
        } else if (_algorithms[algoId].defaultRoyaltyRecipient != address(0) || _algorithms[algoId].defaultRoyaltyBps > 0) {
             recipient = _algorithms[algoId].defaultRoyaltyRecipient;
             basisPoints = _algorithms[algoId].defaultRoyaltyBps;
        } else {
             recipient = _defaultRoyaltyReceiver;
             basisPoints = _defaultRoyaltyBasisPoints;
        }

        // Ensure recipient is not zero address if basisPoints > 0
        if (basisPoints > 0 && recipient == address(0)) {
            // Fallback if a default is set but recipient is address(0), maybe send to owner or contract itself?
            // For now, just return 0 royalty if recipient is address(0) and basisPoints > 0 from a default source
            // A more robust system might require recipient != address(0) during setting defaults.
             return (address(0), 0);
        }

        return (recipient, (_salePrice * basisPoints) / 10000); // Basis points out of 10000
    }

    // --- Query Functions ---

    function getTotalAlgorithms() public view returns (uint256) {
        return _algorithmIds.current();
    }

    function getTotalParameterSets() public view returns (uint256) {
        return _parameterSetIds.current();
    }

    function getAlgorithmIds() public view returns (uint256[] memory) {
        uint256 total = _algorithmIds.current();
        uint256[] memory ids = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            ids[i] = i + 1; // IDs start from 1
        }
        return ids;
    }

     function getParameterSetIds() public view returns (uint256[] memory) {
        uint256 total = _parameterSetIds.current();
        uint256[] memory ids = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            ids[i] = i + 1; // IDs start from 1
        }
        return ids;
    }

    function getTokensByAlgorithm(uint256 _algorithmId) public view returns (uint256[] memory) {
         require(bytes(_algorithms[_algorithmId].name).length > 0, "Algorithm does not exist");
        return _tokensByAlgorithm[_algorithmId];
    }

     function getTokensByParameterSet(uint256 _parameterSetId) public view returns (uint256[] memory) {
         require(bytes(_parameterSets[_parameterSetId].name).length > 0, "Parameter Set does not exist");
        // Note: This array only includes tokens *initially* minted with this parameter set.
        // It does NOT reflect tokens updated via `updateTokenParameterSet`.
        // An off-chain indexer is needed for real-time current parameter set linkage.
        return _tokensByParameterSet[_parameterSetId];
    }


    // --- ERC721 Overrides for Enumerable & URIStorage ---
    // (Required by OpenZeppelin when combining features)

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
    {
        super._update(to, tokenId, auth);
    }
}
```

---

**Explanation of Advanced Concepts & Design Choices:**

1.  **Separation of Concerns:** The contract doesn't store the generative code or image data directly on-chain (which would be prohibitively expensive). Instead, it stores *references* (`algorithmURI`, `parametersURI`). The actual generation and metadata rendering happen off-chain via a service that reads the on-chain data. This is standard for NFTs but crucial for generative art where the output isn't static.
2.  **Dynamic NFTs via Parameter Updates:** The `updateTokenParameterSet` function is the key "dynamic" feature. By allowing the token owner to change the linked `parameterSetId` (if the `algorithm` allows it), the artwork represented by the NFT can change its appearance or characteristics when viewed via the metadata API. This opens up possibilities for evolving art, interactive pieces, or subscription-like models (where parameter updates could be gated).
3.  **Structured Data (Algorithms/Parameters):** Using structs and mappings provides a clear, structured way to store the metadata about the generative components on-chain. Each component gets a unique, persistent ID.
4.  **Role-Based Access Control:** Using `AccessControl` with `CURATOR_ROLE` allows a decentralized team or a specific group to manage the approved algorithms and parameter sets, controlling the quality and integrity of the registry without relying solely on a single owner.
5.  **Inherited Royalty Logic:** ERC2981 integration provides a standard way for marketplaces to query royalty information. The contract implements a priority system (Token > Parameter Set > Algorithm > Contract) to determine the applicable royalty, offering flexibility for creators.
6.  **Dynamic `tokenURI`:** The overridden `tokenURI` function doesn't just return a static link. It constructs a URL that includes the `tokenId`, `algorithmId`, and `parameterSetId`. An external API endpoint configured at `baseTokenURI` would receive these IDs, look up the corresponding data on-chain, use the `algorithmURI` (code reference) and `parametersURI` (parameter data reference) to run the generative process or fetch pre-generated outputs, and return the correct ERC721 metadata JSON.
7.  **Cloneable Parameters:** Allowing anyone to clone a parameter set fosters iteration and remixing, enabling a community to build upon existing artistic configurations.
8.  **Enumerable & URIStorage:** Inheriting from `ERC721Enumerable` allows easy querying of all token IDs, and `ERC721URIStorage` provides the standard mechanism for linking token IDs to metadata URIs, which we then override for dynamic generation.

This contract provides a robust framework for managing a decentralized generative art collection where the NFTs represent not just static outputs, but verifiable links to the creative *process* and its specific inputs, with the potential for the output to change over time.