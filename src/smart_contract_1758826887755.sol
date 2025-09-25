This smart contract, named **AetherialSynthesisEngine**, is designed as a decentralized platform for the adaptive generation and evolution of digital assets or data structures. It leverages community input, external "design insights" (simulating AI or expert feedback via an oracle), and special "Catalyst NFTs" to dynamically adjust the parameters that govern the creation process.

The core idea is an "engine" whose creation rules are not static, but evolve over time based on validated information, making the generated outputs potentially more responsive to trends, user preferences, or optimized aesthetic/functional parameters.

---

## AetherialSynthesisEngine Smart Contract

### I. Outline

1.  **Core Structures & State Variables**: Defines the building blocks of the engine (Protocols, Parameters, Insights, Proposals) and manages essential state like addresses, fees, and counters.
2.  **Modifiers & Events**: Access control for functions and logging of significant contract activities.
3.  **Engine Configuration & Control (Owner/Admin)**: Functions for setting up, updating, and pausing the core engine components.
4.  **Adaptive Parameter Management (Oracle/Admin)**: Mechanisms for introducing and applying external "design insights" to modify the engine's behavior.
5.  **Synthesis Catalyst (NFT) Management**: ERC721 implementation for special NFTs that influence the synthesis process.
6.  **User Interaction & Asset Synthesis**: The main interface for users to generate and modify digital assets, and to propose new optimal parameters.
7.  **Treasury & Reward Management**: Handling collected fees and distributing rewards for valuable contributions.
8.  **Read Functions (View/Pure)**: Public functions to query the contract's state.

### II. Function Summary (Total: 28 Functions)

#### A. Core Engine Management (Owner/Admin)

1.  `constructor()`: Initializes the contract with an owner, treasury, and oracle address.
2.  `addSynthesisProtocol(string _name, string _description, uint256 _baseCost, uint256[] _adaptiveParameterIDs)`: Adds a new protocol for asset generation.
3.  `updateSynthesisProtocolDetails(uint256 _protocolId, string _name, string _description, uint256 _baseCost)`: Updates metadata and base cost for an existing protocol.
4.  `deactivateSynthesisProtocol(uint256 _protocolId)`: Deactivates a protocol, preventing its use.
5.  `addAdaptiveParameterDefinition(string _name, string _description, uint256 _minValue, uint256 _maxValue, uint256 _defaultValue)`: Defines a new type of parameter that can be adapted.
6.  `updateAdaptiveParameterDefinition(uint256 _paramId, string _name, string _description, uint256 _minValue, uint256 _maxValue)`: Updates metadata and bounds for an adaptive parameter definition.
7.  `setProtocolParameterDefaultValue(uint256 _protocolId, uint256 _paramId, uint256 _value)`: Sets an initial default value for an adaptive parameter within a specific protocol.
8.  `setOracleAddress(address _newOracleAddress)`: Sets the authorized address for submitting design insights.
9.  `setTreasuryAddress(address _newTreasuryAddress)`: Sets the address where collected fees are sent.
10. `setBaseSynthesisFee(uint256 _newFee)`: Sets the base fee for synthesizing an asset.
11. `togglePause()`: Pauses or unpauses the contract for emergency situations.

#### B. Adaptive Parameter Control (Oracle/Admin)

12. `submitValidatedDesignInsight(uint256 _protocolId, uint256 _adaptiveParameterId, uint256 _suggestedValue, bytes32 _insightHash)`: An authorized oracle submits a new validated value for an adaptive parameter.
13. `executeValidatedParameterUpdate(bytes32 _insightHash)`: The contract owner or a governing entity applies a previously submitted validated insight to update a parameter's value.

#### C. Synthesis Catalyst (NFT) Management (ERC721)

14. `mintCatalystNFT(address _to, uint256 _catalystType)`: Mints a new Catalyst NFT to a specific address, based on a type.
15. `setCatalystEffectMultiplier(uint256 _catalystType, uint256 _multiplier)`: Defines how a specific Catalyst NFT type influences synthesis (e.g., boosts rarity chance).
16. `approve(address to, uint256 tokenId)`: (ERC721) Grants approval to an address to manage a specific Catalyst NFT.
17. `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers ownership of a Catalyst NFT.
18. `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Safely transfers ownership of a Catalyst NFT.

#### D. User Interaction & Asset Synthesis

19. `synthesizeAsset(uint256 _protocolId, uint256 _catalystTokenId)`: Users pay a fee to generate a new asset based on a protocol, potentially boosted by a Catalyst NFT. Returns a unique asset ID and URI.
20. `mutateSynthesizedAsset(uint256 _protocolId, bytes32 _assetId, uint256 _catalystTokenId)`: Users pay a fee to mutate an existing asset, applying changes based on a protocol and potentially a Catalyst NFT.
21. `proposeOptimizedParameterSet(uint256 _protocolId, uint256 _adaptiveParameterId, uint256 _proposedValue, string _rationaleURI)`: Users can propose new optimal values for adaptive parameters, potentially earning rewards if adopted.

#### E. Treasury & Reward Management

22. `withdrawCollectedFees()`: Allows the treasury address to withdraw accumulated fees.
23. `rewardParameterProposer(uint256 _proposalId, uint256 _rewardAmount)`: Owner/Admin can reward a user for a successful parameter proposal.

#### F. Read Functions (View/Pure)

24. `getSynthesisProtocol(uint256 _protocolId)`: Retrieves details of a synthesis protocol.
25. `getAdaptiveParameterDefinition(uint256 _paramId)`: Retrieves the definition of an adaptive parameter.
26. `getProtocolParameterValue(uint256 _protocolId, uint256 _paramId)`: Retrieves the current active value of an adaptive parameter for a specific protocol.
27. `balanceOf(address owner)`: (ERC721) Returns the number of Catalyst NFTs an owner has.
28. `ownerOf(uint256 tokenId)`: (ERC721) Returns the owner of a Catalyst NFT.
29. `getApproved(uint256 tokenId)`: (ERC721) Returns the approved address for a specific Catalyst NFT.
30. `getInsight(bytes32 _insightHash)`: Retrieves details of a submitted external design insight.
31. `getParameterProposal(uint256 _proposalId)`: Retrieves details of a user-submitted parameter proposal.

---
### III. Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Error definitions for clarity and gas efficiency
error NotEnoughEth();
error ProtocolNotActive(uint256 protocolId);
error ProtocolNotFound(uint256 protocolId);
error AdaptiveParameterNotFound(uint256 paramId);
error InvalidParameterValue(uint256 value, uint256 min, uint256 max);
error InsightNotFound(bytes32 insightHash);
error InsightAlreadyApplied(bytes32 insightHash);
error OnlyOracleAllowed();
error OnlyTreasuryAllowed();
error ProposalNotFound(uint256 proposalId);
error ProposalAlreadyProcessed(uint256 proposalId);
error CatalystNotFound(uint256 tokenId);
error InvalidCatalystType(uint256 catalystType);

contract AetherialSynthesisEngine is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;

    // --- Core Structures ---

    // Defines a recipe or algorithm for generating digital assets
    struct SynthesisProtocol {
        string name;
        string description;
        uint256 baseCost; // Base ETH cost to use this protocol
        bool isActive;
        // An array of adaptive parameter IDs relevant to this protocol.
        // Actual values for these parameters are stored in protocolParameters map.
        uint256[] adaptiveParameterIDs;
        uint256 creationTimestamp;
    }

    // Defines the *type* of parameter that can be adjusted
    struct AdaptiveParameterDefinition {
        string name;
        string description;
        uint256 minValue; // Minimum allowable value for this parameter
        uint256 maxValue; // Maximum allowable value for this parameter
        uint256 defaultValue; // Default value upon protocol creation
        bool exists; // To check if definition exists
    }

    // External Design Insight (submitted by Oracle)
    struct ExternalDesignInsight {
        bytes32 insightHash; // Unique identifier for the insight
        uint256 protocolId;
        uint256 adaptiveParameterId;
        uint256 suggestedValue;
        uint256 submissionTimestamp;
        bool applied; // To prevent double application
        bool exists; // To check if insight exists
    }

    // Proposal for a new optimal parameter set (from user discovery)
    struct ParameterProposal {
        address proposer;
        uint256 protocolId;
        uint256 adaptiveParameterId;
        uint256 proposedValue;
        string rationaleURI; // URI to IPFS/Arweave for detailed rationale
        uint256 submissionTimestamp;
        bool processed; // If it has been rewarded or rejected
        bool exists; // To check if proposal exists
    }

    // --- State Variables ---

    Counters.Counter private _protocolIds;
    Counters.Counter private _adaptiveParameterIds;
    Counters.Counter private _catalystTokenIds;
    Counters.Counter private _proposalIds;

    // Maps protocol IDs to SynthesisProtocol structs
    mapping(uint256 => SynthesisProtocol) public synthesisProtocols;
    // Maps adaptive parameter IDs to AdaptiveParameterDefinition structs
    mapping(uint256 => AdaptiveParameterDefinition) public adaptiveParameterDefinitions;
    // Stores the current active value of an adaptive parameter for a specific protocol
    // protocolId => adaptiveParameterId => value
    mapping(uint256 => mapping(uint256 => uint256)) public protocolParameters;
    // Stores submitted external design insights by their hash
    mapping(bytes32 => ExternalDesignInsight) public insights;
    // Stores user-submitted parameter proposals
    mapping(uint256 => ParameterProposal) public parameterProposals;
    // Defines the multiplier effect of different catalyst types
    mapping(uint256 => uint256) public catalystEffectMultipliers; // catalystType => multiplier (e.g., 100 for 1x, 150 for 1.5x)

    address public oracleAddress;
    address public treasuryAddress;
    uint256 public baseSynthesisFee; // Base fee for synthesis, in wei

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert OnlyOracleAllowed();
        _;
    }

    // --- Events ---

    event ProtocolAdded(uint256 indexed protocolId, string name, address indexed owner);
    event ProtocolUpdated(uint256 indexed protocolId, string name);
    event ProtocolDeactivated(uint256 indexed protocolId);
    event ParameterDefinitionAdded(uint256 indexed paramId, string name);
    event ParameterDefinitionUpdated(uint256 indexed paramId, string name);
    event ProtocolParameterDefaultValueSet(uint256 indexed protocolId, uint256 indexed paramId, uint256 value);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event TreasuryAddressSet(address indexed oldAddress, address indexed newAddress);
    event BaseSynthesisFeeSet(uint256 oldFee, uint256 newFee);
    event DesignInsightSubmitted(bytes32 indexed insightHash, uint256 indexed protocolId, uint256 indexed adaptiveParameterId, uint256 suggestedValue);
    event ParameterValueUpdated(uint256 indexed protocolId, uint256 indexed adaptiveParameterId, uint256 oldValue, uint256 newValue, bytes32 indexed insightHash);
    event CatalystMinted(uint256 indexed tokenId, address indexed to, uint256 catalystType);
    event CatalystEffectMultiplierSet(uint256 indexed catalystType, uint256 multiplier);
    event AssetSynthesized(address indexed user, uint256 indexed protocolId, bytes32 assetId, string assetURI);
    event AssetMutated(address indexed user, uint256 indexed protocolId, bytes32 indexed assetId, string newAssetURI);
    event ParameterProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 indexed protocolId, uint256 adaptiveParameterId, uint256 proposedValue);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ProposerRewarded(uint256 indexed proposalId, address indexed proposer, uint256 rewardAmount);

    // --- Constructor ---

    constructor(address _treasuryAddress, address _oracleAddress) ERC721("SynthesisCatalyst", "ASC") Ownable(msg.sender) {
        if (_treasuryAddress == address(0) || _oracleAddress == address(0)) {
            revert OwnableInvalidOwner(address(0)); // Re-use Ownable error for constructor checks
        }
        treasuryAddress = _treasuryAddress;
        oracleAddress = _oracleAddress;
        baseSynthesisFee = 0.01 ether; // Example default fee
    }

    // --- A. Core Engine Management (Owner/Admin) ---

    function addSynthesisProtocol(
        string memory _name,
        string memory _description,
        uint256 _baseCost,
        uint256[] memory _adaptiveParameterIDs
    ) public onlyOwner whenNotPaused returns (uint256) {
        _protocolIds.increment();
        uint256 newProtocolId = _protocolIds.current();

        // Validate adaptive parameter IDs
        for (uint256 i = 0; i < _adaptiveParameterIDs.length; i++) {
            if (!adaptiveParameterDefinitions[_adaptiveParameterIDs[i]].exists) {
                revert AdaptiveParameterNotFound(_adaptiveParameterIDs[i]);
            }
            // Set initial default values for this protocol
            protocolParameters[newProtocolId][_adaptiveParameterIDs[i]] = adaptiveParameterDefinitions[_adaptiveParameterIDs[i]].defaultValue;
        }

        synthesisProtocols[newProtocolId] = SynthesisProtocol({
            name: _name,
            description: _description,
            baseCost: _baseCost,
            isActive: true,
            adaptiveParameterIDs: _adaptiveParameterIDs,
            creationTimestamp: block.timestamp
        });

        emit ProtocolAdded(newProtocolId, _name, msg.sender);
        return newProtocolId;
    }

    function updateSynthesisProtocolDetails(
        uint256 _protocolId,
        string memory _name,
        string memory _description,
        uint256 _baseCost
    ) public onlyOwner whenNotPaused {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotFound(_protocolId); // Use isActive as a quick check for existence

        protocol.name = _name;
        protocol.description = _description;
        protocol.baseCost = _baseCost;

        emit ProtocolUpdated(_protocolId, _name);
    }

    function deactivateSynthesisProtocol(uint256 _protocolId) public onlyOwner whenNotPaused {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotFound(_protocolId);

        protocol.isActive = false;
        emit ProtocolDeactivated(_protocolId);
    }

    function addAdaptiveParameterDefinition(
        string memory _name,
        string memory _description,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _defaultValue
    ) public onlyOwner whenNotPaused returns (uint256) {
        if (_defaultValue < _minValue || _defaultValue > _maxValue) {
            revert InvalidParameterValue(_defaultValue, _minValue, _maxValue);
        }

        _adaptiveParameterIds.increment();
        uint256 newParamId = _adaptiveParameterIds.current();

        adaptiveParameterDefinitions[newParamId] = AdaptiveParameterDefinition({
            name: _name,
            description: _description,
            minValue: _minValue,
            maxValue: _maxValue,
            defaultValue: _defaultValue,
            exists: true
        });

        emit ParameterDefinitionAdded(newParamId, _name);
        return newParamId;
    }

    function updateAdaptiveParameterDefinition(
        uint256 _paramId,
        string memory _name,
        string memory _description,
        uint256 _minValue,
        uint256 _maxValue
    ) public onlyOwner whenNotPaused {
        AdaptiveParameterDefinition storage paramDef = adaptiveParameterDefinitions[_paramId];
        if (!paramDef.exists) revert AdaptiveParameterNotFound(_paramId);

        paramDef.name = _name;
        paramDef.description = _description;
        paramDef.minValue = _minValue;
        paramDef.maxValue = _maxValue;

        emit ParameterDefinitionUpdated(_paramId, _name);
    }

    function setProtocolParameterDefaultValue(uint256 _protocolId, uint256 _paramId, uint256 _value) public onlyOwner whenNotPaused {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotFound(_protocolId);
        AdaptiveParameterDefinition storage paramDef = adaptiveParameterDefinitions[_paramId];
        if (!paramDef.exists) revert AdaptiveParameterNotFound(_paramId);

        if (_value < paramDef.minValue || _value > paramDef.maxValue) {
            revert InvalidParameterValue(_value, paramDef.minValue, paramDef.maxValue);
        }

        uint256 oldValue = protocolParameters[_protocolId][_paramId];
        protocolParameters[_protocolId][_paramId] = _value;

        emit ProtocolParameterDefaultValueSet(_protocolId, _paramId, _value);
        emit ParameterValueUpdated(_protocolId, _paramId, oldValue, _value, bytes32(0)); // 0 indicates owner/admin set
    }

    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        address oldAddress = oracleAddress;
        oracleAddress = _newOracleAddress;
        emit OracleAddressSet(oldAddress, _newOracleAddress);
    }

    function setTreasuryAddress(address _newTreasuryAddress) public onlyOwner {
        address oldAddress = treasuryAddress;
        treasuryAddress = _newTreasuryAddress;
        emit TreasuryAddressSet(oldAddress, _newTreasuryAddress);
    }

    function setBaseSynthesisFee(uint256 _newFee) public onlyOwner {
        uint256 oldFee = baseSynthesisFee;
        baseSynthesisFee = _newFee;
        emit BaseSynthesisFeeSet(oldFee, _newFee);
    }

    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // --- B. Adaptive Parameter Management (Oracle/Admin) ---

    function submitValidatedDesignInsight(
        uint256 _protocolId,
        uint256 _adaptiveParameterId,
        uint256 _suggestedValue,
        bytes32 _insightHash
    ) public onlyOracle whenNotPaused {
        if (insights[_insightHash].exists) revert InsightAlreadyApplied(_insightHash);
        if (!synthesisProtocols[_protocolId].isActive) revert ProtocolNotFound(_protocolId);
        AdaptiveParameterDefinition storage paramDef = adaptiveParameterDefinitions[_adaptiveParameterId];
        if (!paramDef.exists) revert AdaptiveParameterNotFound(_adaptiveParameterId);

        if (_suggestedValue < paramDef.minValue || _suggestedValue > paramDef.maxValue) {
            revert InvalidParameterValue(_suggestedValue, paramDef.minValue, paramDef.maxValue);
        }

        insights[_insightHash] = ExternalDesignInsight({
            insightHash: _insightHash,
            protocolId: _protocolId,
            adaptiveParameterId: _adaptiveParameterId,
            suggestedValue: _suggestedValue,
            submissionTimestamp: block.timestamp,
            applied: false,
            exists: true
        });

        emit DesignInsightSubmitted(_insightHash, _protocolId, _adaptiveParameterId, _suggestedValue);
    }

    function executeValidatedParameterUpdate(bytes32 _insightHash) public onlyOwner whenNotPaused {
        ExternalDesignInsight storage insight = insights[_insightHash];
        if (!insight.exists) revert InsightNotFound(_insightHash);
        if (insight.applied) revert InsightAlreadyApplied(_insightHash);

        // Ensure the protocol is active and parameter definition exists
        if (!synthesisProtocols[insight.protocolId].isActive) revert ProtocolNotFound(insight.protocolId);
        if (!adaptiveParameterDefinitions[insight.adaptiveParameterId].exists) revert AdaptiveParameterNotFound(insight.adaptiveParameterId);

        uint256 oldValue = protocolParameters[insight.protocolId][insight.adaptiveParameterId];
        protocolParameters[insight.protocolId][insight.adaptiveParameterId] = insight.suggestedValue;
        insight.applied = true;

        emit ParameterValueUpdated(
            insight.protocolId,
            insight.adaptiveParameterId,
            oldValue,
            insight.suggestedValue,
            _insightHash
        );
    }

    // --- C. Synthesis Catalyst (NFT) Management (ERC721) ---
    // Inherits standard ERC721 functions: approve, transferFrom, safeTransferFrom, balanceOf, ownerOf, getApproved

    function mintCatalystNFT(address _to, uint256 _catalystType) public onlyOwner whenNotPaused returns (uint256) {
        _catalystTokenIds.increment();
        uint256 newCatalystId = _catalystTokenIds.current();

        // Optionally, add a check for valid _catalystType if it's enum-like
        // For now, any uint256 is a valid type, its effect is determined by catalystEffectMultipliers

        _mint(_to, newCatalystId);
        _setTokenURI(newCatalystId, string(abi.encodePacked("ipfs://catalyst/", Strings.toString(newCatalystId)))); // Example URI

        emit CatalystMinted(newCatalystId, _to, _catalystType);
        return newCatalystId;
    }

    function setCatalystEffectMultiplier(uint256 _catalystType, uint256 _multiplier) public onlyOwner {
        catalystEffectMultipliers[_catalystType] = _multiplier;
        emit CatalystEffectMultiplierSet(_catalystType, _multiplier);
    }

    // --- D. User Interaction & Asset Synthesis ---

    // Internal helper function for synthesis logic
    function _generateAsset(uint256 _protocolId, uint256 _catalystTokenId, bytes32 _previousAssetId)
        internal
        view
        returns (bytes32 newAssetId, string memory assetURI)
    {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotFound(_protocolId);

        // Simulate asset generation based on adaptive parameters
        // In a real scenario, this would involve more complex on-chain logic
        // or a verifiable off-chain computation whose hash is stored.
        // For demonstration, we'll generate a hash based on current parameters.

        bytes memory seed = abi.encodePacked(
            block.timestamp,
            msg.sender,
            _protocolId,
            _catalystTokenId,
            _previousAssetId
        );

        for (uint256 i = 0; i < protocol.adaptiveParameterIDs.length; i++) {
            uint256 paramId = protocol.adaptiveParameterIDs[i];
            uint256 paramValue = protocolParameters[_protocolId][paramId];
            seed = abi.encodePacked(seed, paramId, paramValue);
        }

        // Apply catalyst effect
        if (_catalystTokenId != 0 && _exists(_catalystTokenId)) { // Check if catalyst exists
            uint256 catalystType = 0; // In a real system, catalyst NFT metadata would specify type
                                     // For simplicity, let's assume type is encoded in token URI or a separate mapping
                                     // Or, for this example, let's just use token ID as a "type" surrogate
            
            // If `_catalystTokenId` indicates a type, use it. Otherwise, use a default.
            // For a minimal example, let's assume `catalystType` is `_catalystTokenId % 10` for example purposes
            // A more robust system would map `_catalystTokenId` to a `catalystType` from metadata or a contract state
            catalystType = _catalystTokenId; // Simplistic: TokenId itself represents a unique effect type

            uint256 multiplier = catalystEffectMultipliers[catalystType];
            if (multiplier == 0) multiplier = 100; // Default 1x multiplier if not set (100 means 100%)

            // Incorporate multiplier into the seed, e.g., by multiplying a specific parameter value
            // This is a simplified example; actual effect would depend on the protocol logic.
            if (protocol.adaptiveParameterIDs.length > 0) {
                 uint256 firstParamId = protocol.adaptiveParameterIDs[0];
                 uint256 currentVal = protocolParameters[_protocolId][firstParamId];
                 // Example: boost a parameter by the catalyst multiplier
                 seed = abi.encodePacked(seed, currentVal * multiplier / 100);
            }
        }

        newAssetId = keccak256(seed);
        assetURI = string(abi.encodePacked("ipfs://synthesized/", Strings.toHexString(uint256(newAssetId))));
        return (newAssetId, assetURI);
    }

    function synthesizeAsset(uint256 _protocolId, uint256 _catalystTokenId)
        public
        payable
        whenNotPaused
        returns (bytes32 assetId, string memory assetURI)
    {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotActive(_protocolId);
        if (msg.value < protocol.baseCost + baseSynthesisFee) revert NotEnoughEth();

        // Transfer fees to treasury
        (bool sent, ) = treasuryAddress.call{value: msg.value}("");
        if (!sent) revert OnlyTreasuryAllowed(); // Revert for treasury transfer failure, though this shouldn't happen with .call

        (assetId, assetURI) = _generateAsset(_protocolId, _catalystTokenId, bytes32(0));

        emit AssetSynthesized(msg.sender, _protocolId, assetId, assetURI);
        return (assetId, assetURI);
    }

    function mutateSynthesizedAsset(uint256 _protocolId, bytes32 _assetId, uint256 _catalystTokenId)
        public
        payable
        whenNotPaused
        returns (bytes32 newAssetId, string memory newAssetURI)
    {
        SynthesisProtocol storage protocol = synthesisProtocols[_protocolId];
        if (!protocol.isActive) revert ProtocolNotActive(_protocolId);
        if (msg.value < protocol.baseCost + baseSynthesisFee) revert NotEnoughEth();

        // Transfer fees to treasury
        (bool sent, ) = treasuryAddress.call{value: msg.value}("");
        if (!sent) revert OnlyTreasuryAllowed();

        (newAssetId, newAssetURI) = _generateAsset(_protocolId, _catalystTokenId, _assetId);

        emit AssetMutated(msg.sender, _protocolId, _assetId, newAssetURI);
        return (newAssetId, newAssetURI);
    }

    function proposeOptimizedParameterSet(
        uint256 _protocolId,
        uint256 _adaptiveParameterId,
        uint256 _proposedValue,
        string memory _rationaleURI
    ) public whenNotPaused returns (uint256) {
        if (!synthesisProtocols[_protocolId].isActive) revert ProtocolNotFound(_protocolId);
        AdaptiveParameterDefinition storage paramDef = adaptiveParameterDefinitions[_adaptiveParameterId];
        if (!paramDef.exists) revert AdaptiveParameterNotFound(_adaptiveParameterId);

        if (_proposedValue < paramDef.minValue || _proposedValue > paramDef.maxValue) {
            revert InvalidParameterValue(_proposedValue, paramDef.minValue, paramDef.maxValue);
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        parameterProposals[newProposalId] = ParameterProposal({
            proposer: msg.sender,
            protocolId: _protocolId,
            adaptiveParameterId: _adaptiveParameterId,
            proposedValue: _proposedValue,
            rationaleURI: _rationaleURI,
            submissionTimestamp: block.timestamp,
            processed: false,
            exists: true
        });

        emit ParameterProposalSubmitted(newProposalId, msg.sender, _protocolId, _adaptiveParameterId, _proposedValue);
        return newProposalId;
    }

    // --- E. Treasury & Reward Management ---

    function withdrawCollectedFees() public onlyOwner {
        uint255 balance = address(this).balance;
        if (balance == 0) revert NotEnoughEth(); // No fees to withdraw

        (bool sent, ) = treasuryAddress.call{value: balance}("");
        if (!sent) revert OnlyTreasuryAllowed(); // This implies treasuryAddress should be reliable
        
        emit FeesWithdrawn(treasuryAddress, balance);
    }

    function rewardParameterProposer(uint256 _proposalId, uint256 _rewardAmount) public onlyOwner {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (!proposal.exists) revert ProposalNotFound(_proposalId);
        if (proposal.processed) revert ProposalAlreadyProcessed(_proposalId);

        // Check if contract has enough ETH for reward
        if (address(this).balance < _rewardAmount) revert NotEnoughEth();

        (bool sent, ) = proposal.proposer.call{value: _rewardAmount}("");
        if (!sent) {
            // Log failure, but don't revert if reward fails to be sent, just mark as processed
            // This allows the reward to be re-attempted or manually sent later if desired
            // Or revert and require re-evaluation if reward sending is critical
            // For now, we revert.
            revert("Failed to send reward");
        }

        proposal.processed = true;
        emit ProposerRewarded(_proposalId, proposal.proposer, _rewardAmount);
    }

    // --- F. Read Functions (View/Pure) ---

    function getSynthesisProtocol(uint256 _protocolId) public view returns (SynthesisProtocol memory) {
        if (!synthesisProtocols[_protocolId].isActive) revert ProtocolNotFound(_protocolId);
        return synthesisProtocols[_protocolId];
    }

    function getAdaptiveParameterDefinition(uint256 _paramId) public view returns (AdaptiveParameterDefinition memory) {
        if (!adaptiveParameterDefinitions[_paramId].exists) revert AdaptiveParameterNotFound(_paramId);
        return adaptiveParameterDefinitions[_paramId];
    }

    function getProtocolParameterValue(uint256 _protocolId, uint256 _paramId) public view returns (uint256) {
        if (!synthesisProtocols[_protocolId].isActive) revert ProtocolNotFound(_protocolId);
        if (!adaptiveParameterDefinitions[_paramId].exists) revert AdaptiveParameterNotFound(_paramId);
        return protocolParameters[_protocolId][_paramId];
    }

    function getInsight(bytes32 _insightHash) public view returns (ExternalDesignInsight memory) {
        if (!insights[_insightHash].exists) revert InsightNotFound(_insightHash);
        return insights[_insightHash];
    }

    function getParameterProposal(uint256 _proposalId) public view returns (ParameterProposal memory) {
        if (!parameterProposals[_proposalId].exists) revert ProposalNotFound(_proposalId);
        return parameterProposals[_proposalId];
    }
}
```