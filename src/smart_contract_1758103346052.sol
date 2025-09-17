```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For module tracking
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment, then DAO takes over
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VerifiableKnowledgeNetwork (VKN)
 * @author Your Name / AI Assistant
 * @notice The Verifiable Knowledge Network (VKN) is a decentralized platform designed to foster a verifiable ecosystem
 *         for knowledge, data, and AI models. It enables contributors to register "Knowledge Modules" (KMs) –
 *         represented as NFTs – which can encapsulate anything from verifiable facts, research findings,
 *         or even machine learning models. The system integrates Zero-Knowledge (ZK) proofs to verify the properties,
 *         originality, or inference results of these KMs without revealing underlying sensitive data.
 *         Contributors are recognized and rewarded through dynamic Soulbound Tokens (d-SBTs), which track their
 *         reputation and expertise, evolving based on the utility and accuracy of their contributions.
 *         The entire network is governed by a decentralized autonomous organization (DAO).
 *
 * Core Concepts:
 * 1.  Knowledge Modules (KMs): ERC-721 based NFTs representing units of verifiable knowledge or AI models.
 * 2.  Contributor Dynamic Soulbound Tokens (d-SBTs): Non-transferable (soulbound) NFTs that evolve their metadata
 *     to reflect a contributor's reputation and expertise.
 * 3.  ZK-Proof Integration: On-chain verification of off-chain computations related to KM properties, originality,
 *     or inference.
 * 4.  Decentralized Governance: DAO-controlled system parameters, upgrades, and dispute resolution.
 * 5.  Dynamic Incentives: Fees for KM usage and royalty distribution to contributors, with reputation-based influence.
 */

// --- Interfaces ---

/**
 * @notice Interface for external ZK Verifier contracts.
 *         These contracts will contain the actual precompiled solidity `pairing.verify()` logic or similar.
 */
interface IZKVerifier {
    function verifyProof(bytes memory _proof, bytes memory _publicInputs) external view returns (bool);
}

/**
 * @notice Interface for Soulbound Token functionality (inspired by ERC-5192).
 */
interface ISoulbound {
    event Locked(uint256 indexed tokenId);
    function isSoulbound(uint256 tokenId) external view returns (bool);
}

// --- Contract ---

contract VerifiableKnowledgeNetwork is ERC721Enumerable, Ownable, ISoulbound {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token IDs for Knowledge Modules (KMs)
    Counters.Counter private _kmTokenIds;
    // Token IDs for Contributor Soulbound Tokens (d-SBTs)
    Counters.Counter private _sbtTokenIds;

    // Mapping from KM ID to its details
    struct KnowledgeModule {
        address owner;
        string metadataURI;
        bytes32 initialDataHash; // For originality proofs
        address zkVerifier;      // Specific ZK verifier for this module's proofs
        uint256 pricePerUse;
        uint256 royaltyRate;     // Percentage of pricePerUse for the owner, 0-10000 (100% = 10000)
        uint256 accumulatedFunds;
        bool isActive;
        uint256 sbtTokenId; // Link to the contributor's SBT
    }
    mapping(uint256 => KnowledgeModule) public knowledgeModules;

    // Mapping from contributor address to their d-SBT Token ID
    mapping(address => uint256) public contributorSBTs;
    // Mapping from SBT Token ID to its metadata URI (for dynamic updates)
    mapping(uint256 => string) public sbtMetadataURIs;

    // Mapping from contributor address to an array of KM IDs they own
    mapping(address => uint256[]) public contributorKMs;

    // Registered ZK Verifier contracts: name -> address
    mapping(string => address) public registeredZKVerifiers;

    // Allowed proof types for submission: typeId -> description
    mapping(uint8 => string) public allowedProofTypes;

    // System Parameters (governance controlled)
    uint256 public baseRoyaltyRate = 8000; // 80% default royalty rate for KM owner
    uint256 public protocolFeeRate = 2000; // 20% protocol fee for network operations
    address public queryFeeReceiver;       // Address to receive the protocol fee

    // Address of the DAO governance contract (set by initial owner)
    address public governance;

    // --- Events ---
    event KnowledgeModuleRegistered(uint256 indexed moduleId, address indexed owner, string metadataURI, uint256 pricePerUse, uint256 royaltyRate);
    event KnowledgeModuleMetadataUpdated(uint256 indexed moduleId, string newMetadataURI);
    event KnowledgeModuleDeactivated(uint256 indexed moduleId);
    event KnowledgeQueryRequested(uint256 indexed moduleId, address indexed querier, uint256 amountPaid, bytes queryPayload);
    event KnowledgeVerificationProofSubmitted(uint256 indexed moduleId, address indexed submitter, uint8 proofType, bool success);
    event KnowledgeModulePriceUpdated(uint256 indexed moduleId, uint256 newPrice);
    event KnowledgeModuleFundsWithdrawn(uint256 indexed moduleId, address indexed owner, uint256 amount);

    event ContributorSBTMinted(uint256 indexed sbtTokenId, address indexed contributor, string initialReputationURI);
    event SBTReputationUpdated(uint256 indexed sbtTokenId, address indexed contributor, int256 scoreChange, string newMetadataURI);

    event ZKVerifierRegistered(string verifierName, address verifierAddress);
    event ModuleZKVerifierSet(uint256 indexed moduleId, address zkVerifierAddress);
    event AllowedProofTypeAdded(uint8 indexed proofType, string description);

    event SystemParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event SystemFundsDeposited(address indexed depositor, uint256 amount);
    event SystemFundsWithdrawn(address indexed receiver, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address _initialQueryFeeReceiver) ERC721("VerifiableKnowledgeModule", "VKM") {
        require(_initialQueryFeeReceiver != address(0), "Query fee receiver cannot be zero address");
        queryFeeReceiver = _initialQueryFeeReceiver;
        // Initial owner will set the governance address after deployment
        governance = msg.sender; // Temporarily set governance to deployer, should be updated to actual DAO later
    }

    // --- ERC721 Overrides for Soulbound (d-SBT) behavior ---
    /**
     * @dev Prevents transfer of Soulbound Tokens (d-SBTs).
     *      Knowledge Modules (KMs) are regular ERC721s and can be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (contributorSBTs[from] == tokenId || contributorSBTs[to] == tokenId) {
            // This is an SBT being transferred. If `from` is not address(0) (mint) and `to` is not address(0) (burn),
            // prevent the transfer.
            require(from == address(0) || to == address(0), "SBTs are non-transferable");
        }
    }

    // --- Function Summary Implementation ---

    // I. Core Knowledge Module (KM) Management

    /**
     * @notice Registers a new Knowledge Module (KM) as an ERC-721 token.
     * @dev A KM is owned by the creator. Its pricePerUse and royaltyRate define its earning potential.
     *      An initial `_zkVerifier` is assigned for validating proofs related to this module.
     *      Requires a contributor's SBT to be minted prior to registering a KM.
     * @param _metadataURI URI pointing to off-chain metadata describing the KM (e.g., IPFS hash).
     * @param _initialDataHash A cryptographic hash of the underlying data/model for originality claims.
     * @param _zkVerifier Address of the ZK verifier contract to be used for this KM. Must be registered.
     * @param _pricePerUse The cost in WEI for a single query/use of this KM.
     * @param _royaltyRate The percentage (0-10000) of `pricePerUse` that goes to the KM owner.
     *                     Remaining goes to the protocol. Max 10000 (100%).
     */
    function registerKnowledgeModule(
        string memory _metadataURI,
        bytes32 _initialDataHash,
        address _zkVerifier,
        uint256 _pricePerUse,
        uint256 _royaltyRate
    ) external {
        require(contributorSBTs[msg.sender] != 0, "Contributor must have an SBT to register a KM");
        require(registeredZKVerifiers[getVerifierName(_zkVerifier)] == _zkVerifier, "Provided ZK verifier is not registered");
        require(_royaltyRate <= 10000, "Royalty rate cannot exceed 100%");
        require(_royaltyRate + protocolFeeRate <= 10000, "Combined royalty and protocol fee exceeds 100%"); // Redundancy check

        _kmTokenIds.increment();
        uint256 newTokenId = _kmTokenIds.current();

        knowledgeModules[newTokenId] = KnowledgeModule({
            owner: msg.sender,
            metadataURI: _metadataURI,
            initialDataHash: _initialDataHash,
            zkVerifier: _zkVerifier,
            pricePerUse: _pricePerUse,
            royaltyRate: _royaltyRate,
            accumulatedFunds: 0,
            isActive: true,
            sbtTokenId: contributorSBTs[msg.sender]
        });

        _safeMint(msg.sender, newTokenId);
        contributorKMs[msg.sender].push(newTokenId);

        emit KnowledgeModuleRegistered(newTokenId, msg.sender, _metadataURI, _pricePerUse, _royaltyRate);
    }

    /**
     * @notice Allows the KM owner to update the metadata URI.
     * @dev Useful for updating off-chain details about the KM (e.g., new version, description).
     * @param _moduleId The ID of the Knowledge Module.
     * @param _newMetadataURI The new URI pointing to updated metadata.
     */
    function updateKnowledgeModuleMetadata(uint256 _moduleId, string memory _newMetadataURI) external {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.owner == msg.sender, "Only KM owner can update metadata");
        require(km.isActive, "Cannot update metadata of an inactive KM");

        km.metadataURI = _newMetadataURI;
        emit KnowledgeModuleMetadataUpdated(_moduleId, _newMetadataURI);
    }

    /**
     * @notice Marks a KM as inactive, preventing further queries and earning.
     * @dev The KM still exists and its ownership is maintained, but it cannot be actively used.
     * @param _moduleId The ID of the Knowledge Module to deactivate.
     */
    function deactivateKnowledgeModule(uint256 _moduleId) external {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.owner == msg.sender, "Only KM owner can deactivate module");
        require(km.isActive, "KM is already inactive");

        km.isActive = false;
        emit KnowledgeModuleDeactivated(_moduleId);
    }

    /**
     * @notice Initiates a query to a KM, paying the specified `pricePerUse`.
     * @dev This function records the payment and intent. Actual query execution and result verification
     *      are assumed to happen off-chain, potentially with a later ZK proof submission.
     * @param _moduleId The ID of the Knowledge Module to query.
     * @param _queryPayload Arbitrary bytes for the off-chain query.
     */
    function requestKnowledgeQuery(uint256 _moduleId, bytes memory _queryPayload) external payable {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.isActive, "Cannot query an inactive KM");
        require(msg.value >= km.pricePerUse, "Insufficient funds to query KM");
        require(km.pricePerUse > 0, "KM has a zero price, no query allowed this way");

        uint256 ownerShare = (km.pricePerUse * km.royaltyRate) / 10000;
        uint256 protocolShare = km.pricePerUse - ownerShare;

        km.accumulatedFunds += ownerShare;
        // Send protocol fee to the designated receiver
        if (protocolShare > 0) {
            (bool success,) = queryFeeReceiver.call{value: protocolShare}("");
            require(success, "Failed to send protocol fee");
        }

        // Refund any excess payment
        if (msg.value > km.pricePerUse) {
            (bool success,) = msg.sender.call{value: msg.value - km.pricePerUse}("");
            require(success, "Failed to refund excess payment");
        }

        emit KnowledgeQueryRequested(_moduleId, msg.sender, km.pricePerUse, _queryPayload);
    }

    /**
     * @notice Submits a ZK proof for a KM (e.g., proving originality, accuracy, or correct inference result).
     * @dev The `_proofType` dictates how the proof affects reputation and rewards.
     *      The contract calls the KM's designated ZK verifier to validate the proof.
     *      Successful proofs can trigger reputation updates for the KM owner's SBT.
     * @param _moduleId The ID of the Knowledge Module the proof pertains to.
     * @param _proof The raw ZK proof bytes.
     * @param _publicInputs The public inputs for the ZK proof.
     * @param _proofType An identifier for the type of proof being submitted (e.g., 0 for originality, 1 for accuracy).
     */
    function submitKnowledgeVerificationProof(
        uint256 _moduleId,
        bytes memory _proof,
        bytes memory _publicInputs,
        uint8 _proofType
    ) external {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.zkVerifier != address(0), "KM has no ZK verifier assigned");
        require(bytes(allowedProofTypes[_proofType]).length > 0, "Invalid proof type"); // Check if proof type is allowed

        bool success = IZKVerifier(km.zkVerifier).verifyProof(_proof, _publicInputs);

        int256 reputationChange = 0;
        string memory newSBTMetadataURI = sbtMetadataURIs[contributorSBTs[km.owner]]; // Keep current if no change

        if (success) {
            // Logic to calculate reputation change based on proof type and success
            // Example:
            if (_proofType == 0) { // Originality Proof
                reputationChange = 10; // Positive reputation for proving originality
            } else if (_proofType == 1) { // Accuracy Proof
                reputationChange = 5; // Positive reputation for proving accuracy
            }
            // For more complex reputation, integrate a separate reputation calculation module
            // and update `newSBTMetadataURI` with a URI reflecting the new reputation state.

            // Example for updating metadata:
            // newSBTMetadataURI = IPFS_UPLOAD_SERVICE.upload(current_sbt_metadata_json_with_updated_score);
            // For this example, we assume `newSBTMetadataURI` comes from some off-chain system or is simply maintained as before.
            // In a real dApp, this would likely be handled by an off-chain service or a more complex on-chain logic.
        } else {
            // Negative reputation for failed proofs, if desired
            reputationChange = -5; // Example: penalty for false claim or failed proof
        }

        if (reputationChange != 0) {
            _updateSBTReputationScore(km.owner, reputationChange, newSBTMetadataURI);
        }

        emit KnowledgeVerificationProofSubmitted(_moduleId, msg.sender, _proofType, success);
    }

    /**
     * @notice Allows the KM owner to adjust the `pricePerUse` for their module.
     * @param _moduleId The ID of the Knowledge Module.
     * @param _newPrice The new price in WEI for a single use.
     */
    function updateKnowledgeModulePrice(uint256 _moduleId, uint256 _newPrice) external {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.owner == msg.sender, "Only KM owner can update price");
        require(km.isActive, "Cannot update price of an inactive KM");

        km.pricePerUse = _newPrice;
        emit KnowledgeModulePriceUpdated(_moduleId, _newPrice);
    }

    /**
     * @notice Enables the KM owner to withdraw accumulated royalties and fees from their module.
     * @param _moduleId The ID of the Knowledge Module.
     */
    function withdrawKnowledgeModuleFunds(uint256 _moduleId) external {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.owner == msg.sender, "Only KM owner can withdraw funds");
        require(km.accumulatedFunds > 0, "No funds to withdraw");

        uint256 amount = km.accumulatedFunds;
        km.accumulatedFunds = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw funds");

        emit KnowledgeModuleFundsWithdrawn(_moduleId, msg.sender, amount);
    }


    // II. Contributor Dynamic Soulbound Token (d-SBT) Management

    /**
     * @notice Mints a new, non-transferable d-SBT for a contributor.
     * @dev Each contributor can only have one d-SBT. This token represents their reputation.
     * @param _contributor The address of the contributor to mint the SBT for.
     * @param _initialReputationURI The initial URI pointing to the SBT's metadata.
     */
    function mintContributorSBT(address _contributor, string memory _initialReputationURI) external {
        // Initially, only governance can mint SBTs, or a specific whitelisting process
        require(msg.sender == governance, "Only governance can mint Contributor SBTs");
        require(contributorSBTs[_contributor] == 0, "Contributor already has an SBT");

        _sbtTokenIds.increment();
        uint256 newSbtId = _sbtTokenIds.current();

        contributorSBTs[_contributor] = newSbtId;
        sbtMetadataURIs[newSbtId] = _initialReputationURI;

        _safeMint(_contributor, newSbtId); // Mint as ERC721, but it's non-transferable

        emit ContributorSBTMinted(newSbtId, _contributor, _initialReputationURI);
    }

    /**
     * @notice (Internal/Governance-only) Adjusts a contributor's reputation score and updates their d-SBT's metadata URI.
     * @dev This function is typically called internally upon successful verifiable actions or by governance
     *      after dispute resolution. The `_newMetadataURI` should reflect the updated reputation state.
     * @param _contributor The address of the contributor whose SBT is being updated.
     * @param _scoreChange The change in reputation score (can be positive or negative).
     * @param _newMetadataURI The new URI pointing to the updated SBT metadata.
     */
    function _updateSBTReputationScore(address _contributor, int256 _scoreChange, string memory _newMetadataURI) internal {
        uint256 sbtId = contributorSBTs[_contributor];
        require(sbtId != 0, "Contributor does not have an SBT");

        // In a real system, `_scoreChange` would modify an on-chain score,
        // and `_newMetadataURI` would be generated off-chain to reflect the new score.
        // For this example, we directly update the metadata URI.
        sbtMetadataURIs[sbtId] = _newMetadataURI;

        emit SBTReputationUpdated(sbtId, _contributor, _scoreChange, _newMetadataURI);
    }

    /**
     * @notice Retrieves the current metadata URI for a contributor's d-SBT.
     * @param _contributor The address of the contributor.
     * @return The metadata URI of the contributor's d-SBT.
     */
    function getSBTReputationURI(address _contributor) external view returns (string memory) {
        uint256 sbtId = contributorSBTs[_contributor];
        require(sbtId != 0, "Contributor does not have an SBT");
        return sbtMetadataURIs[sbtId];
    }

    /**
     * @notice Implements the ERC-5192 standard check to confirm if a specific token is non-transferable.
     * @dev For this contract, all d-SBTs are soulbound. KMs are regular ERC-721s and are transferable.
     * @param _tokenId The ID of the token to check.
     * @return True if the token is soulbound (a d-SBT), false otherwise.
     */
    function isSoulbound(uint256 _tokenId) external view override returns (bool) {
        // Check if the token ID corresponds to an SBT
        address ownerOfToken = ownerOf(_tokenId);
        if (contributorSBTs[ownerOfToken] == _tokenId) {
            return true;
        }
        return false;
    }

    /**
     * @notice Returns a list of all Knowledge Modules owned by a specific contributor.
     * @param _contributor The address of the contributor.
     * @return An array of KM IDs owned by the contributor.
     */
    function getContributorModules(address _contributor) external view returns (uint256[] memory) {
        return contributorKMs[_contributor];
    }


    // III. ZK Proof & Verifier Management

    /**
     * @notice Allows the DAO to register trusted ZK verifier contracts for different proof types.
     * @dev Only governance can register new verifiers.
     * @param _verifierName A descriptive name for the verifier (e.g., "Groth16OriginalityVerifier").
     * @param _verifierContract The address of the ZK verifier contract.
     */
    function registerZKVerifier(string memory _verifierName, address _verifierContract) external onlyGovernance {
        require(_verifierContract != address(0), "Verifier address cannot be zero");
        registeredZKVerifiers[_verifierName] = _verifierContract;
        emit ZKVerifierRegistered(_verifierName, _verifierContract);
    }

    /**
     * @notice (Governance-only) Assigns a specific registered ZK verifier contract to a Knowledge Module.
     * @dev This allows governance to change or assign a verifier for a KM, potentially after a dispute
     *      or an upgrade to the verification system.
     * @param _moduleId The ID of the Knowledge Module.
     * @param _zkVerifierContract The address of the new ZK verifier contract. Must be registered.
     */
    function setModuleZKVerifier(uint256 _moduleId, address _zkVerifierContract) external onlyGovernance {
        require(knowledgeModules[_moduleId].owner != address(0), "KM does not exist");
        require(registeredZKVerifiers[getVerifierName(_zkVerifierContract)] == _zkVerifierContract, "Provided ZK verifier is not registered");

        knowledgeModules[_moduleId].zkVerifier = _zkVerifierContract;
        emit ModuleZKVerifierSet(_moduleId, _zkVerifierContract);
    }

    /**
     * @notice Retrieves the address of a registered ZK verifier by its name.
     * @param _verifierName The descriptive name of the verifier.
     * @return The address of the registered ZK verifier.
     */
    function getRegisteredZKVerifier(string memory _verifierName) external view returns (address) {
        return registeredZKVerifiers[_verifierName];
    }

    /**
     * @notice (Governance-only) Adds a new valid proof type that can be submitted to the network.
     * @dev This allows for extending the types of verifiable claims that can be made within the VKN.
     * @param _proofType A unique identifier for the new proof type (e.g., an enum value).
     * @param _description A human-readable description of what this proof type verifies.
     */
    function addAllowedProofType(uint8 _proofType, string memory _description) external onlyGovernance {
        require(bytes(allowedProofTypes[_proofType]).length == 0, "Proof type already exists");
        allowedProofTypes[_proofType] = _description;
        emit AllowedProofTypeAdded(_proofType, _description);
    }


    // IV. Governance & System Parameters (DAO-Controlled)

    /**
     * @notice Updates the governance address.
     * @dev This is crucial for transferring control from the deployer to a fully functional DAO contract.
     *      Can only be called by the current governance address.
     * @param _newGovernance The address of the new governance contract.
     */
    function setGovernance(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "New governance address cannot be zero");
        governance = _newGovernance;
        emit SystemParameterUpdated(bytes32("governance"), uint256(uint160(_newGovernance)));
    }

    /**
     * @notice (Governance-only) Executes a passed DAO proposal to update a core system parameter.
     * @dev This function acts as a dispatcher for various parameter updates.
     * @param _paramKey A unique identifier for the system parameter (e.g., hash of "baseRoyaltyRate").
     * @param _newValue The new value for the parameter.
     */
    function executeSystemParameterUpdate(bytes32 _paramKey, uint256 _newValue) external onlyGovernance {
        if (_paramKey == bytes32("baseRoyaltyRate")) {
            setBaseRoyaltyRate(_newValue);
        } else if (_paramKey == bytes32("protocolFeeRate")) {
            setProtocolFeeRate(_newValue);
        } else if (_paramKey == bytes32("queryFeeReceiver")) {
            setQueryFeeReceiver(address(uint160(_newValue))); // Convert uint256 back to address
        } else {
            revert("Unknown system parameter");
        }
        emit SystemParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @notice Allows any user to deposit ETH into the VKN treasury for general system operations or reward pools.
     */
    function depositSystemFunds() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit SystemFundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice (Governance-only) Allows the DAO to withdraw funds from the VKN treasury.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawSystemFunds(uint256 _amount) external onlyGovernance {
        require(address(this).balance >= _amount, "Insufficient system funds");
        require(_amount > 0, "Withdrawal amount must be greater than zero");

        (bool success,) = governance.call{value: _amount}("");
        require(success, "Failed to withdraw system funds");
        emit SystemFundsWithdrawn(governance, _amount);
    }

    /**
     * @notice (Governance-only) Updates the default royalty rate applied to new Knowledge Modules.
     * @dev This rate is used if a KM owner doesn't specify their own, or as a cap.
     * @param _newRate The new base royalty rate (0-10000).
     */
    function setBaseRoyaltyRate(uint256 _newRate) public onlyGovernance {
        require(_newRate <= 10000, "Royalty rate cannot exceed 100%");
        baseRoyaltyRate = _newRate;
        emit SystemParameterUpdated(bytes32("baseRoyaltyRate"), _newRate);
    }

    /**
     * @notice (Governance-only) Updates the protocol fee rate.
     * @param _newRate The new protocol fee rate (0-10000).
     */
    function setProtocolFeeRate(uint256 _newRate) public onlyGovernance {
        require(_newRate <= 10000, "Protocol fee rate cannot exceed 100%");
        protocolFeeRate = _newRate;
        emit SystemParameterUpdated(bytes32("protocolFeeRate"), _newRate);
    }

    /**
     * @notice (Governance-only) Sets the address that receives the protocol's portion of query fees.
     * @param _newReceiver The new address for the query fee receiver.
     */
    function setQueryFeeReceiver(address _newReceiver) public onlyGovernance {
        require(_newReceiver != address(0), "Query fee receiver cannot be zero address");
        queryFeeReceiver = _newReceiver;
        emit SystemParameterUpdated(bytes32("queryFeeReceiver"), uint256(uint160(_newReceiver)));
    }


    // V. Utility & State Access

    /**
     * @notice Retrieves comprehensive details about a specific Knowledge Module.
     * @param _moduleId The ID of the Knowledge Module.
     * @return owner The address of the KM owner.
     * @return metadataURI The URI for the KM's metadata.
     * @return initialDataHash The initial hash of the KM's data.
     * @return zkVerifier The address of the assigned ZK verifier.
     * @return pricePerUse The cost per use of the KM.
     * @return royaltyRate The royalty percentage for the owner.
     * @return accumulatedFunds The funds accumulated for the owner.
     * @return isActive True if the module is active, false otherwise.
     * @return sbtTokenId The ID of the owner's d-SBT.
     */
    function getModuleDetails(uint256 _moduleId)
        external
        view
        returns (
            address owner,
            string memory metadataURI,
            bytes32 initialDataHash,
            address zkVerifier,
            uint256 pricePerUse,
            uint256 royaltyRate,
            uint256 accumulatedFunds,
            bool isActive,
            uint256 sbtTokenId
        )
    {
        KnowledgeModule storage km = knowledgeModules[_moduleId];
        require(km.owner != address(0), "KM does not exist");
        return (
            km.owner,
            km.metadataURI,
            km.initialDataHash,
            km.zkVerifier,
            km.pricePerUse,
            km.royaltyRate,
            km.accumulatedFunds,
            km.isActive,
            km.sbtTokenId
        );
    }

    /**
     * @notice Returns the address of the owner of a Knowledge Module.
     * @param _moduleId The ID of the Knowledge Module.
     * @return The address of the KM owner.
     */
    function getModuleOwner(uint256 _moduleId) external view returns (address) {
        return knowledgeModules[_moduleId].owner;
    }

    /**
     * @dev Helper to get a string representation of an address to use as a key in `registeredZKVerifiers`.
     *      This is a simplification; ideally, verifier registration would use proper string IDs.
     */
    function getVerifierName(address _verifierAddress) private pure returns (string memory) {
        return Strings.toHexString(uint160(_verifierAddress), 20);
    }

    // Fallback function to receive Ether
    receive() external payable {
        emit SystemFundsDeposited(msg.sender, msg.value);
    }
}
```