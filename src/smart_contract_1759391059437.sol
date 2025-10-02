This smart contract, named `AethelgardProtocol`, is designed to introduce several advanced, creative, and trendy concepts in Solidity. It combines elements of digital legacy management, conditional asset release, dynamic asset transformation, and a lightweight activity attestation system. The goal is to provide a framework where digital assets (ETH, ERC20, ERC721) can be managed with complex, multi-stage rules that react to time, external events (via oracle), and the owner's continued activity.

---

**Contract Name:** AethelgardProtocol

**Core Concept:** A decentralized protocol for "digital legacy management" and "future-proof asset evolution." It allows users to define complex, multi-stage conditional release and transformation rules for digital assets (NFTs, fungible tokens, and ETH) based on time, external events (oracle-fed), and owner activity ("proof of life"). It also introduces concepts of asset transformation and a lightweight attestation system for owner activity.

**Key Innovations & Advanced Concepts:**
*   **Multi-Stage Conditional Release:** Assets can be released or transformed based on a sequence or combination of time, external events, or owner activity, providing granular control over digital inheritance.
*   **"Proof of Life" Mechanism:** A unique condition where assets can be conditionally released to an alternative beneficiary if the vault owner becomes inactive for a defined period, ensuring digital continuity.
*   **Dynamic Asset Transformation:** Beyond simple transfers, assets (especially NFTs) can be defined to *evolve* or *change* based on conditions, such as metadata updates, burning an old token to mint a new one, or even splitting/merging NFTs.
*   **Oracle-Driven Events:** Integration with an external oracle allows conditions to react to real-world events or specific on-chain data points outside the contract's direct scope.
*   **Activity Attestation System:** A community-driven mechanism where third parties can attest to a vault owner's activity, influencing "proof of life" conditions or reputation scores.

---

**I. Protocol Administration & Core Settings**

*   `constructor(address _initialFeeRecipient)`: Initializes the contract with an owner and the address designated to receive protocol fees.
*   `setProtocolFeeRecipient(address _newRecipient)`: Allows the owner to update the address that collects protocol fees.
*   `setVaultCreationFee(uint256 _newFee)`: Sets the fee required to create a new legacy vault.
*   `setOracleAddress(address _newOracle)`: Configures the address of the external oracle that provides event-based condition data.
*   `pauseContract()`: Activates an emergency pause, halting critical operations (owner-only).
*   `unpauseContract()`: Deactivates the emergency pause, restoring contract functionality (owner-only).
*   `withdrawProtocolFees(address _token, uint256 _amount)`: Enables the fee recipient or owner to withdraw collected ERC20 tokens or native ETH fees from the contract.

**II. Vault Management & Asset Deposits**

*   `createVault(address _beneficiary, address _executor)`: Creates a new, unique legacy vault for the caller, specifying a primary beneficiary and an optional executor. Requires a vault creation fee.
*   `depositERC20ToVault(uint256 _vaultId, address _token, uint256 _amount)`: Allows a vault owner to securely deposit ERC20 tokens into their designated vault.
*   `depositNFTToVault(uint256 _vaultId, address _nftAddress, uint256 _tokenId)`: Allows a vault owner to deposit an ERC721 NFT into their vault, with the contract acting as a custodian.
*   `depositETHToVault(uint256 _vaultId)`: Allows a vault owner to deposit native ETH into their vault.
*   `setVaultExecutor(uint256 _vaultId, address _newExecutor)`: Updates the designated executor for a specific vault. Only the vault owner can perform this action.
*   `updateVaultBeneficiary(uint256 _vaultId, address _newBeneficiary)`: Changes the primary beneficiary of a vault. (For simplicity, this is direct, but could have delays/conditions).

**III. Conditional Release & Asset Evolution Logic**

*   `addTimeCondition(uint256 _vaultId, uint256 _releaseTimestamp, bool _recurring)`: Adds a time-based condition. Assets can be released after a specific timestamp, or on a recurring basis.
*   `addEventCondition(uint256 _vaultId, bytes32 _oracleQueryId, uint256 _expectedValue)`: Adds a condition that triggers when an external oracle provides a specific response for a predefined query.
*   `addActivityProofCondition(uint256 _vaultId, uint256 _gracePeriod, uint256 _checkInterval)`: Establishes a "proof of life" condition. If the vault owner fails to `proveLife` within `_gracePeriod`, alternative rules may activate.
*   `defineAlternativeRelease(uint256 _vaultId, address _alternativeBeneficiary, bool _transferAll)`: Configures an alternative release mechanism that triggers if primary conditions (e.g., inactivity) are met.
*   `defineAssetTransformationRule(uint256 _vaultId, AssetType _assetType, address _assetAddress, uint256 _assetTokenId, TransformationType _transformationType, address _targetAddress, bytes memory _transformationData, uint256 _conditionIndex)`: Defines how a specific asset within the vault should transform (e.g., update NFT metadata, burn and mint a new token, split/merge NFTs) once a linked condition is met.
*   `executeConditionalRelease(uint256 _vaultId, uint256 _conditionIndex)`: Initiates the release of assets from a vault if the specified conditions are met. Callable by the executor, beneficiary, or owner.
*   `executeAssetTransformation(uint256 _vaultId, uint256 _ruleIndex)`: Triggers the transformation of an asset within a vault if its associated conditions are met and the rule hasn't been executed.

**IV. Advanced Interaction & Security**

*   `proveLife(uint256 _vaultId)`: Called by the vault owner to signal active status, resetting their "proof of life" timer for the vault.
*   `attestVaultActivity(uint256 _vaultId)`: Allows a third party to publicly attest to a vault owner's perceived activity, contributing to a simplified activity score.
*   `challengeVaultActivityAttestation(uint256 _vaultId, address _attestor)`: Provides a mechanism to challenge a potentially false activity attestation, aiming to prevent manipulation of activity scores.
*   `updateVaultSecurityPolicy(uint256 _vaultId, bytes32 _policyHash)`: Allows the vault owner to update a hash pointing to their desired security parameters (e.g., multi-sig requirements, override delays) for the vault.
*   `claimTransformedAsset(uint256 _vaultId, uint256 _ruleIndex)`: Enables the beneficiary to claim an asset that has undergone a defined transformation process, once executed.
*   `migrateVaultAssets(uint256 _fromVaultId, uint256 _toVaultId)`: Allows an owner or authorized executor to consolidate assets and rules from one vault into another, useful for upgrades or reorganizations.
*   `removeCondition(uint256 _vaultId, uint256 _conditionIndex)`: Allows the vault owner to remove a previously set condition, subject to internal checks (e.g., if it's not already released or critical).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AethelgardProtocol
 * @dev A decentralized protocol for "digital legacy management" and "future-proof asset evolution."
 * It allows users to define complex, multi-stage conditional release and transformation rules for
 * digital assets (NFTs, fungible tokens, and ETH) based on time, external events (oracle-fed),
 * and owner activity ("proof of life"). It also introduces concepts of asset transformation and
 * a lightweight attestation system for owner activity.
 *
 * @notice This is a highly conceptual contract designed to showcase advanced features.
 * Real-world deployment would require extensive auditing, gas optimization, and detailed
 * implementation of oracle integration and asset transformation logic. Mapping iteration
 * for asset transfers is a known limitation in Solidity and is conceptualized here.
 */
contract AethelgardProtocol is Ownable, Pausable, ERC721Holder {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---
    //
    // I. Protocol Administration & Core Settings
    //    - constructor(): Initializes the contract with an owner and fee recipient.
    //    - setProtocolFeeRecipient(address _newRecipient): Sets the address to which protocol fees are directed.
    //    - setVaultCreationFee(uint256 _newFee): Sets the fee required to create a new legacy vault.
    //    - setOracleAddress(address _newOracle): Sets the address of the external oracle used for event-based conditions.
    //    - pauseContract(): Pauses core functionalities in emergencies (owner-only).
    //    - unpauseContract(): Unpauses core functionalities (owner-only).
    //    - withdrawProtocolFees(address _token, uint256 _amount): Allows the fee recipient to withdraw collected ERC20 or native ETH fees.
    //
    // II. Vault Management & Asset Deposits
    //    - createVault(address _beneficiary, address _executor): Creates a new unique legacy vault, designating a primary beneficiary and an optional executor. Requires a creation fee.
    //    - depositERC20ToVault(uint256 _vaultId, address _token, uint256 _amount): Allows a vault owner to deposit ERC20 tokens into their vault.
    //    - depositNFTToVault(uint256 _vaultId, address _nftAddress, uint256 _tokenId): Allows a vault owner to deposit an ERC721 NFT into their vault.
    //    - depositETHToVault(uint256 _vaultId): Allows a vault owner to deposit native ETH into their vault.
    //    - setVaultExecutor(uint256 _vaultId, address _newExecutor): Updates the designated executor for a specific vault (vault owner only).
    //    - updateVaultBeneficiary(uint256 _vaultId, address _newBeneficiary): Changes the primary beneficiary of a vault. This may be subject to internal delays or conditions for security.
    //
    // III. Conditional Release & Asset Evolution Logic
    //    - addTimeCondition(uint256 _vaultId, uint256 _releaseTimestamp, bool _recurring): Adds a time-based condition for asset release. Can be a one-time unlock or a recurring release.
    //    - addEventCondition(uint256 _vaultId, bytes32 _oracleQueryId, uint256 _expectedValue): Adds an event-based condition, triggering release when the oracle provides a specific response for a given query.
    //    - addActivityProofCondition(uint256 _vaultId, uint256 _gracePeriod, uint256 _checkInterval): Implements a "proof of life" mechanism, requiring the owner to interact periodically. If inactive, alternative rules may trigger.
    //    - defineAlternativeRelease(uint256 _vaultId, address _alternativeBeneficiary, bool _transferAll): Sets an alternative release destination or rule if a primary condition (e.g., activity proof) fails.
    //    - defineAssetTransformationRule(uint256 _vaultId, AssetType _assetType, address _assetAddress, uint256 _assetTokenId, TransformationType _transformationType, address _targetAddress, bytes memory _transformationData, uint256 _conditionIndex): Defines how an asset transforms upon condition fulfillment (e.g., NFT metadata update, burn old & mint new, split, merge).
    //    - executeConditionalRelease(uint256 _vaultId, uint256 _conditionIndex): Initiates the release of assets from a vault if the specified conditions are met. Can be called by executor or beneficiary.
    //    - executeAssetTransformation(uint256 _vaultId, uint256 _ruleIndex): Triggers the transformation of an asset within a vault if its associated conditions are met.
    //
    // IV. Advanced Interaction & Security
    //    - proveLife(uint256 _vaultId): Called by the vault owner to signal activity, resetting the "proof of life" timer for their vault.
    //    - attestVaultActivity(uint256 _vaultId): Allows a third party to attest to a vault owner's perceived activity. This could influence reputation or conditions.
    //    - challengeVaultActivityAttestation(uint256 _vaultId, address _attestor): Provides a mechanism to challenge a false activity attestation, preventing manipulation.
    //    - updateVaultSecurityPolicy(uint256 _vaultId, bytes32 _policyHash): Allows the vault owner to update internal security parameters (e.g., add multi-sig requirements for changes, set override delays). This hash could point to off-chain rules or complex on-chain logic.
    //    - claimTransformedAsset(uint256 _vaultId, uint256 _ruleIndex): Allows the beneficiary to claim an asset that has undergone a defined transformation.
    //    - migrateVaultAssets(uint256 _fromVaultId, uint256 _toVaultId): Enables an owner or authorized executor to move all assets and associated rules from one vault to another, useful for upgrades or consolidations.
    //    - removeCondition(uint256 _vaultId, uint256 _conditionIndex): Allows the vault owner to remove a previously set condition, potentially subject to a timelock or counter-condition for security.
    //
    // --- End of Outline ---

    // Events
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed beneficiary, address executor);
    event ERC20Deposited(uint256 indexed vaultId, address indexed token, uint256 amount);
    event NFTDeposited(uint256 indexed vaultId, address indexed nftAddress, uint256 indexed tokenId);
    event ETHDeposited(uint256 indexed vaultId, uint256 amount);
    event ExecutorUpdated(uint256 indexed vaultId, address indexed newExecutor);
    event BeneficiaryUpdated(uint256 indexed vaultId, address indexed newBeneficiary);
    event ConditionAdded(uint256 indexed vaultId, uint256 conditionIndex, ConditionType conditionType);
    event AlternativeReleaseDefined(uint256 indexed vaultId, address alternativeBeneficiary, bool transferAll);
    event AssetTransformationRuleDefined(uint256 indexed vaultId, uint256 ruleIndex, TransformationType transformationType);
    event ReleaseExecuted(uint256 indexed vaultId, uint256 conditionIndex, address indexed to);
    event TransformationExecuted(uint256 indexed vaultId, uint256 ruleIndex, address indexed beneficiary);
    event LifeProven(uint256 indexed vaultId, address indexed prover);
    event ActivityAttested(uint256 indexed vaultId, address indexed attestor);
    event ActivityAttestationChallenged(uint256 indexed vaultId, address indexed attestor, address indexed challenger);
    event VaultSecurityPolicyUpdated(uint256 indexed vaultId, bytes32 policyHash);
    event TransformedAssetClaimed(uint256 indexed vaultId, uint256 ruleIndex, address indexed beneficiary);
    event VaultAssetsMigrated(uint256 indexed fromVaultId, uint256 indexed toVaultId);
    event ConditionRemoved(uint256 indexed vaultId, uint256 conditionIndex);
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event VaultCreationFeeUpdated(uint256 oldFee, uint256 newFee);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event ProtocolFeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);


    // Enums for clarity and extensibility
    enum ConditionType { TimeBased, EventBased, ActivityProof }
    enum AssetType { ETH, ERC20, ERC721 }
    enum TransformationType { UpdateMetadata, BurnAndMint, SplitNFT, MergeNFTs } // Advanced transformations

    // Structs for data management
    struct Condition {
        ConditionType conditionType;
        bool met;                   // True if condition is satisfied
        uint256 data1;              // Used variably: timestamp, gracePeriod, expectedValue, etc.
        uint256 data2;              // Used variably: checkInterval, recurring flag, etc.
        bytes32 oracleQueryId;      // For EventBased conditions
        bool isReleased;            // True if assets tied to this condition have been released
    }

    struct AssetTransformationRule {
        AssetType assetType;        // Type of asset to transform
        address assetAddress;       // Address of the asset contract (ERC20/ERC721)
        uint256 assetTokenId;       // Token ID for ERC721, ignored for ERC20/ETH
        TransformationType transformationType;
        address targetAddress;      // E.g., for minting, this could be the new contract address or beneficiary
        bytes transformationData;   // Flexible data for transformation (e.g., new metadata hash, new tokenURI, etc.)
        uint256 conditionIndex;     // The condition index that triggers this transformation
        bool executed;              // True if the transformation has been applied
        bool claimed;               // True if the transformed asset has been claimed by the beneficiary
    }

    struct Vault {
        address owner;
        address beneficiary;
        address executor;
        uint256 createdAt;
        uint256 lastActivityProof; // Timestamp of the last proveLife call
        bytes32 securityPolicyHash; // Hash pointing to off-chain or complex on-chain security rules

        // Asset holdings: Mappings are used for existence checks, but for iteration,
        // a real implementation would need explicit arrays of token addresses/IDs.
        mapping(address => uint256) erc20Balances; // ERC20 balances per token contract
        mapping(address => mapping(uint256 => bool)) erc721Holdings; // ERC721s held: nftAddress -> tokenId -> true
        uint256 ethBalance;

        // Track ERC20 and ERC721 contracts for iteration during transfers
        address[] depositedERC20Tokens;
        mapping(address => address[]) depositedERC721Tokens; // contract => list of tokenIds

        Condition[] conditions;
        AssetTransformationRule[] transformationRules;

        // Alternative release mechanism if primary conditions fail (e.g., owner inactivity)
        struct AlternativeRelease {
            address targetBeneficiary;
            bool transferAll; // If true, all remaining assets go to targetBeneficiary
            bool activated;   // True if the alternative release has been triggered
        }
        AlternativeRelease alternativeRelease;

        // Attestation system
        mapping(address => uint256) activityAttestations; // attestor => lastAttestationTimestamp
        mapping(address => mapping(address => bool)) attestationChallenges; // attestor => challenger => true
        uint256 totalAttestationScore; // Simplified score
    }

    Counters.Counter private _vaultIds;
    mapping(uint256 => Vault) public vaults;

    address public protocolFeeRecipient;
    uint256 public vaultCreationFee;
    address public oracleAddress;

    // Interface for a generic oracle (e.g., Chainlink, custom)
    interface IOracle {
        function getUint256(bytes32 _queryId) external view returns (uint256);
        function getBool(bytes32 _queryId) external view returns (bool); // Added for potential bool conditions
    }

    constructor(address _initialFeeRecipient) Ownable(msg.sender) {
        require(_initialFeeRecipient != address(0), "Invalid fee recipient");
        protocolFeeRecipient = _initialFeeRecipient;
        vaultCreationFee = 0.01 ether; // Example fee
    }

    receive() external payable {
        // Direct ETH deposits are not tied to a vault automatically.
        // It's recommended to use depositETHToVault for explicit assignment.
        // ETH sent here will be considered protocol funds, or reverted for strictness.
        // For this example, if not explicitly deposited, it acts as general contract balance.
    }

    // --- I. Protocol Administration & Core Settings ---

    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient address");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    function setVaultCreationFee(uint256 _newFee) external onlyOwner {
        emit VaultCreationFeeUpdated(vaultCreationFee, _newFee);
        vaultCreationFee = _newFee;
    }

    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _token, uint256 _amount) external {
        require(msg.sender == protocolFeeRecipient || msg.sender == owner(), "Not authorized to withdraw fees");
        if (_token == address(0)) { // ETH withdrawal
            (bool success, ) = payable(protocolFeeRecipient).call{value: _amount}("");
            require(success, "ETH withdrawal failed");
        } else { // ERC20 withdrawal
            IERC20(_token).safeTransfer(protocolFeeRecipient, _amount);
        }
        emit ProtocolFeesWithdrawn(_token, protocolFeeRecipient, _amount);
    }

    // --- II. Vault Management & Asset Deposits ---

    function createVault(address _beneficiary, address _executor) external payable whenNotPaused returns (uint256) {
        require(msg.value >= vaultCreationFee, "Insufficient fee for vault creation");
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");

        if (msg.value > vaultCreationFee) {
            // Refund excess ETH
            (bool success, ) = msg.sender.call{value: msg.value - vaultCreationFee}("");
            require(success, "Failed to refund excess ETH");
        }

        _vaultIds.increment();
        uint256 newVaultId = _vaultIds.current();

        Vault storage newVault = vaults[newVaultId];
        newVault.owner = msg.sender;
        newVault.beneficiary = _beneficiary;
        newVault.executor = _executor;
        newVault.createdAt = block.timestamp;
        newVault.lastActivityProof = block.timestamp; // Initial proof of life

        emit VaultCreated(newVaultId, msg.sender, _beneficiary, _executor);
        return newVaultId;
    }

    function depositERC20ToVault(uint256 _vaultId, address _token, uint256 _amount) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_token != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        
        Vault storage vault = vaults[_vaultId];
        if (vault.erc20Balances[_token] == 0) { // If first deposit of this token type
            vault.depositedERC20Tokens.push(_token);
        }
        vault.erc20Balances[_token] += _amount;

        emit ERC20Deposited(_vaultId, _token, _amount);
    }

    function depositNFTToVault(uint256 _vaultId, address _nftAddress, uint256 _tokenId) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_nftAddress != address(0), "Invalid NFT address");
        require(!vaults[_vaultId].erc721Holdings[_nftAddress][_tokenId], "NFT already in vault");

        // Transfer NFT to this contract
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        
        Vault storage vault = vaults[_vaultId];
        if (!vault.erc721Holdings[_nftAddress][_tokenId]) { // Check if new NFT of this type
            vault.depositedERC721Tokens[_nftAddress].push(_nftAddress); // This is a bit redundant if just tracking contracts, but allows future expansion.
            // If we need to track individual token IDs per contract, this needs modification.
            // For simplicity, we just track existence with the mapping.
        }
        vault.erc721Holdings[_nftAddress][_tokenId] = true;

        emit NFTDeposited(_vaultId, _nftAddress, _tokenId);
    }

    function depositETHToVault(uint256 _vaultId) external payable whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(msg.value > 0, "ETH amount must be greater than zero");

        vaults[_vaultId].ethBalance += msg.value;

        emit ETHDeposited(_vaultId, msg.value);
    }

    function setVaultExecutor(uint256 _vaultId, address _newExecutor) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_newExecutor != address(0), "Executor cannot be zero address");
        vaults[_vaultId].executor = _newExecutor;
        emit ExecutorUpdated(_vaultId, _newExecutor);
    }

    function updateVaultBeneficiary(uint256 _vaultId, address _newBeneficiary) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_newBeneficiary != address(0), "Beneficiary cannot be zero address");
        vaults[_vaultId].beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_vaultId, _newBeneficiary);
    }

    // --- III. Conditional Release & Asset Evolution Logic ---

    function addTimeCondition(uint256 _vaultId, uint256 _releaseTimestamp, bool _recurring) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_releaseTimestamp > block.timestamp, "Release timestamp must be in the future");

        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(
            Condition({
                conditionType: ConditionType.TimeBased,
                met: false,
                data1: _releaseTimestamp,
                data2: _recurring ? 1 : 0, // 1 for recurring, 0 for one-time
                oracleQueryId: bytes32(0),
                isReleased: false
            })
        );
        emit ConditionAdded(_vaultId, vault.conditions.length - 1, ConditionType.TimeBased);
    }

    function addEventCondition(uint256 _vaultId, bytes32 _oracleQueryId, uint256 _expectedValue) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(oracleAddress != address(0), "Oracle address not set");
        require(_oracleQueryId != bytes32(0), "Oracle query ID cannot be zero");

        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(
            Condition({
                conditionType: ConditionType.EventBased,
                met: false,
                data1: _expectedValue,
                data2: 0,
                oracleQueryId: _oracleQueryId,
                isReleased: false
            })
        );
        emit ConditionAdded(_vaultId, vault.conditions.length - 1, ConditionType.EventBased);
    }

    function addActivityProofCondition(uint256 _vaultId, uint256 _gracePeriod, uint256 _checkInterval) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_gracePeriod > 0, "Grace period must be greater than zero");
        require(_checkInterval > 0, "Check interval must be greater than zero");
        require(_gracePeriod > _checkInterval, "Grace period must be longer than check interval");

        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(
            Condition({
                conditionType: ConditionType.ActivityProof,
                met: false,
                data1: _gracePeriod,  // How long before "inactive"
                data2: _checkInterval, // How often to check activity (could be used for attestation incentives)
                oracleQueryId: bytes32(0),
                isReleased: false
            })
        );
        emit ConditionAdded(_vaultId, vault.conditions.length - 1, ConditionType.ActivityProof);
    }

    function defineAlternativeRelease(uint256 _vaultId, address _alternativeBeneficiary, bool _transferAll) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_alternativeBeneficiary != address(0), "Alternative beneficiary cannot be zero address");

        Vault storage vault = vaults[_vaultId];
        vault.alternativeRelease = Vault.AlternativeRelease({
            targetBeneficiary: _alternativeBeneficiary,
            transferAll: _transferAll,
            activated: false
        });
        emit AlternativeReleaseDefined(_vaultId, _alternativeBeneficiary, _transferAll);
    }

    // `_transformationData` structure depends on `_transformationType`:
    // - UpdateMetadata: `bytes32 newMetadataHash` (or directly new URI)
    // - BurnAndMint: `address newNftContract, uint256 newId, string newUri` (packed into bytes)
    // - SplitNFT: `uint256 numSplits, address[] newNftContracts, uint256[] newIds, string[] newUris` (more complex, likely requires helper)
    // - MergeNFTs: `uint256[] tokenIdsToMerge, address newNftContract, uint256 newId, string newUri` (more complex, likely requires helper)
    function defineAssetTransformationRule(
        uint256 _vaultId,
        AssetType _assetType,
        address _assetAddress,
        uint256 _assetTokenId, // Relevant for ERC721
        TransformationType _transformationType,
        address _targetAddress, // E.g., for minting, this could be the new contract address or beneficiary
        bytes memory _transformationData,
        uint256 _conditionIndex // The condition index that triggers this transformation
    ) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        require(_conditionIndex < vaults[_vaultId].conditions.length, "Invalid condition index");

        Vault storage vault = vaults[_vaultId];
        
        // Basic checks for asset existence in vault
        if (_assetType == AssetType.ERC20) {
            require(vault.erc20Balances[_assetAddress] > 0, "ERC20 not in vault");
        } else if (_assetType == AssetType.ERC721) {
            require(vault.erc721Holdings[_assetAddress][_assetTokenId], "NFT not in vault");
        } else { // ETH
            require(vault.ethBalance > 0, "ETH not in vault");
        }

        // Specific checks based on transformation type can be added here
        // e.g., for BurnAndMint, _targetAddress should be a minter contract.

        vault.transformationRules.push(
            AssetTransformationRule({
                assetType: _assetType,
                assetAddress: _assetAddress,
                assetTokenId: _assetTokenId,
                transformationType: _transformationType,
                targetAddress: _targetAddress,
                transformationData: _transformationData,
                conditionIndex: _conditionIndex,
                executed: false,
                claimed: false
            })
        );
        emit AssetTransformationRuleDefined(_vaultId, vault.transformationRules.length - 1, _transformationType);
    }

    // Internal helper to check conditions
    function _checkCondition(uint256 _vaultId, uint256 _conditionIndex) internal view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "Condition index out of bounds");
        Condition storage condition = vault.conditions[_conditionIndex];

        if (condition.conditionType == ConditionType.TimeBased) {
            return block.timestamp >= condition.data1; // data1 is _releaseTimestamp
        } else if (condition.conditionType == ConditionType.EventBased) {
            require(oracleAddress != address(0), "Oracle address not set");
            return IOracle(oracleAddress).getUint256(condition.oracleQueryId) == condition.data1; // data1 is _expectedValue
        } else if (condition.conditionType == ConditionType.ActivityProof) {
            return block.timestamp > vault.lastActivityProof + condition.data1; // data1 is _gracePeriod
        }
        return false;
    }

    function executeConditionalRelease(uint256 _vaultId, uint256 _conditionIndex) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.executor || msg.sender == vault.beneficiary || msg.sender == vault.owner, "Not authorized to execute release");
        require(_conditionIndex < vault.conditions.length, "Condition index out of bounds");

        Condition storage condition = vault.conditions[_conditionIndex];
        require(!condition.isReleased, "Assets for this condition already released");

        bool conditionMet = _checkCondition(_vaultId, _conditionIndex);

        // If it's an ActivityProof condition and it's met (meaning owner is inactive), trigger alternative release
        if (condition.conditionType == ConditionType.ActivityProof && conditionMet) {
            if (vault.alternativeRelease.targetBeneficiary != address(0) && !vault.alternativeRelease.activated) {
                vault.alternativeRelease.activated = true;
                if (vault.alternativeRelease.transferAll) {
                    _transferAllAssets(_vaultId, vault.alternativeRelease.targetBeneficiary);
                }
                condition.met = true; 
                condition.isReleased = true;
                emit ReleaseExecuted(_vaultId, _conditionIndex, vault.alternativeRelease.targetBeneficiary);
                return;
            }
        }

        require(conditionMet, "Condition not yet met");

        condition.met = true;
        condition.isReleased = true;

        // Simplified: if a non-recurring time-based condition is met, release assets.
        // A more complex system would map specific assets to specific conditions.
        // This execution merely flags the condition as met. Actual claims happen via `claimTransformedAsset`
        // or a general `claimAllAssets` after all conditions are met.
        if (condition.conditionType == ConditionType.TimeBased && condition.data2 == 0) { // If it's a one-time release
            _transferAllAssets(_vaultId, vault.beneficiary);
        }
        
        emit ReleaseExecuted(_vaultId, _conditionIndex, vault.beneficiary);
    }

    // Internal helper function for transferring all assets to a beneficiary
    function _transferAllAssets(uint256 _vaultId, address _to) internal {
        Vault storage vault = vaults[_vaultId];

        // Transfer ETH
        if (vault.ethBalance > 0) {
            (bool success, ) = payable(_to).call{value: vault.ethBalance}("");
            require(success, "ETH transfer failed");
            vault.ethBalance = 0;
        }

        // Transfer ERC20s
        // Iterate over a snapshot of deposited ERC20 tokens to avoid reentrancy/array modification issues
        address[] memory currentERC20Tokens = vault.depositedERC20Tokens;
        for (uint256 i = 0; i < currentERC20Tokens.length; i++) {
            address tokenAddress = currentERC20Tokens[i];
            uint256 balance = vault.erc20Balances[tokenAddress];
            if (balance > 0) {
                vault.erc20Balances[tokenAddress] = 0;
                IERC20(tokenAddress).safeTransfer(_to, balance);
            }
        }
        // Clear the array of deposited ERC20 tokens after transfer (optional, could just reset balances)
        delete vault.depositedERC20Tokens;

        // Transfer ERC721s
        // This is complex as `erc721Holdings` is a nested mapping for `tokenId => bool`
        // We'd need to iterate through all known NFT contracts and then their held token IDs.
        // This requires an array of held NFT contracts, and then an array of token IDs per contract.
        // For simplicity and to avoid excessive gas, the full iteration is left conceptual for now.
        // In a real system, you'd likely maintain `mapping(address => uint256[]) nftTokenIdsHeld;`
        // to easily iterate and transfer.
        // As a placeholder, assuming a method to get all currently held NFTs.
        // Example: For each `nftAddress` in `vault.depositedERC721Tokens` (which should be an array of token IDs):
        //   for (uint256 j = 0; j < vault.depositedERC721Tokens[nftAddress].length; j++) {
        //     uint256 tokenId = vault.depositedERC721Tokens[nftAddress][j];
        //     if (vault.erc721Holdings[nftAddress][tokenId]) {
        //       vault.erc721Holdings[nftAddress][tokenId] = false;
        //       IERC721(nftAddress).transferFrom(address(this), _to, tokenId);
        //     }
        //   }
        // Clearing `vault.depositedERC721Tokens` is also needed.
    }


    function executeAssetTransformation(uint256 _vaultId, uint256 _ruleIndex) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.executor || msg.sender == vault.owner, "Not authorized to execute transformation");
        require(_ruleIndex < vault.transformationRules.length, "Rule index out of bounds");

        AssetTransformationRule storage rule = vault.transformationRules[_ruleIndex];
        require(!rule.executed, "Transformation already executed");
        require(vault.conditions[rule.conditionIndex].met, "Associated condition not yet met");

        // --- Execute specific transformation logic based on `rule.transformationType` ---
        // These calls are conceptual and would require specific interfaces for the target contracts.
        if (rule.transformationType == TransformationType.UpdateMetadata) {
            // Requires the NFT contract at `rule.assetAddress` to have an update mechanism.
            // Example: INFTUpdatable(rule.assetAddress).updateMetadata(rule.assetTokenId, rule.transformationData);
            // This would likely involve an external call to an NFT contract with metadata update capabilities.
        } else if (rule.transformationType == TransformationType.BurnAndMint) {
            // Requires `rule.assetAddress` to be a burnable ERC721 and `rule.targetAddress` a minter.
            // IERC721(rule.assetAddress).burn(rule.assetTokenId); // Burn the old NFT
            // IMinter(rule.targetAddress).mint(vault.beneficiary, rule.transformationData); // Mint new NFT for beneficiary
            // Update vault holdings: remove old NFT, perhaps record reference to new one for `claimTransformedAsset`.
        } else if (rule.transformationType == TransformationType.SplitNFT) {
            // More complex: burn one NFT, mint multiple new ones. `_transformationData` would define new NFTs.
        } else if (rule.transformationType == TransformationType.MergeNFTs) {
            // More complex: burn multiple NFTs, mint one new one. `_transformationData` would define input/output.
        }
        // ... more transformation types ...

        rule.executed = true;
        emit TransformationExecuted(_vaultId, _ruleIndex, vault.beneficiary);
    }

    // --- IV. Advanced Interaction & Security ---

    function proveLife(uint256 _vaultId) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        vaults[_vaultId].lastActivityProof = block.timestamp;
        emit LifeProven(_vaultId, msg.sender);
    }

    function attestVaultActivity(uint256 _vaultId) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.owner != address(0), "Vault does not exist");
        require(msg.sender != vault.owner, "Owner cannot attest their own activity");
        // Prevent frequent spamming of attestations
        require(block.timestamp > vault.activityAttestations[msg.sender] + 1 days, "Too frequent attestation");

        vault.activityAttestations[msg.sender] = block.timestamp;
        vault.totalAttestationScore++; // Simplified scoring
        emit ActivityAttested(_vaultId, msg.sender);
        // Could implement a small reward for valid attestations
    }

    function challengeVaultActivityAttestation(uint256 _vaultId, address _attestor) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.activityAttestations[_attestor] > 0, "No attestation found from this address");
        require(msg.sender != vault.owner, "Owner cannot challenge attestations (they can just prove life)");
        require(msg.sender != _attestor, "Cannot challenge your own attestation");
        require(!vault.attestationChallenges[_attestor][msg.sender], "Already challenged by this address");

        // Logic to verify challenge (e.g., provide external proof, or if owner proves life shortly after challenge)
        // For simplicity, we just record the challenge.
        vault.attestationChallenges[_attestor][msg.sender] = true;
        vault.totalAttestationScore--; // Decrement score on challenge (might need more sophisticated logic)
        emit ActivityAttestationChallenged(_vaultId, _attestor, msg.sender);
    }

    // _policyHash could be an IPFS CID of a complex governance document, or a hash of an on-chain multi-sig configuration.
    function updateVaultSecurityPolicy(uint256 _vaultId, bytes32 _policyHash) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        vaults[_vaultId].securityPolicyHash = _policyHash;
        emit VaultSecurityPolicyUpdated(_vaultId, _policyHash);
    }

    function claimTransformedAsset(uint256 _vaultId, uint256 _ruleIndex) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(msg.sender == vault.beneficiary, "Only beneficiary can claim transformed asset");
        require(_ruleIndex < vault.transformationRules.length, "Rule index out of bounds");

        AssetTransformationRule storage rule = vault.transformationRules[_ruleIndex];
        require(rule.executed, "Transformation not yet executed");
        require(!rule.claimed, "Asset already claimed");

        // Logic to transfer the *newly transformed* asset to the beneficiary
        // This depends heavily on the transformation type and how the new asset was created.
        // For example, if BurnAndMint created a new NFT, the beneficiary would claim that new NFT.
        // This would require the `executeAssetTransformation` function to store the new asset's details
        // (e.g., contract address and token ID) for this function to act upon.
        // For simplicity, we mark it claimed.
        rule.claimed = true;
        emit TransformedAssetClaimed(_vaultId, _ruleIndex, msg.sender);
    }

    function migrateVaultAssets(uint256 _fromVaultId, uint256 _toVaultId) external whenNotPaused {
        require(vaults[_fromVaultId].owner == msg.sender, "Not owner of source vault");
        require(vaults[_toVaultId].owner == msg.sender, "Not owner of target vault");
        require(_fromVaultId != _toVaultId, "Cannot migrate to the same vault");

        // For simplicity, this only migrates balances. Conditions and rules are NOT migrated.
        // A full migration would involve complex deep-copying of all associated data.
        Vault storage fromVault = vaults[_fromVaultId];
        Vault storage toVault = vaults[_toVaultId];

        // Migrate ETH
        if (fromVault.ethBalance > 0) {
            toVault.ethBalance += fromVault.ethBalance;
            fromVault.ethBalance = 0;
        }

        // Migrate ERC20s (iterates over the list of deposited token addresses)
        address[] memory fromERC20Tokens = fromVault.depositedERC20Tokens;
        for (uint256 i = 0; i < fromERC20Tokens.length; i++) {
            address tokenAddress = fromERC20Tokens[i];
            uint256 balance = fromVault.erc20Balances[tokenAddress];
            if (balance > 0) {
                if (toVault.erc20Balances[tokenAddress] == 0) { // If this is a new token for the target vault
                    toVault.depositedERC20Tokens.push(tokenAddress);
                }
                toVault.erc20Balances[tokenAddress] += balance;
                fromVault.erc20Balances[tokenAddress] = 0;
            }
        }
        delete fromVault.depositedERC20Tokens; // Clear the old list

        // Migrate ERC721s (conceptual, requires iteration over actual token IDs)
        // This would need a robust way to list all held NFTs per contract in `fromVault`
        // and then update `toVault.erc721Holdings` and `toVault.depositedERC721Tokens`.
        // The underlying NFTs would not be physically moved by `transferFrom` calls
        // because they are already held by `address(this)`. It's a logical transfer
        // within the contract's internal state.

        emit VaultAssetsMigrated(_fromVaultId, _toVaultId);
        // A full implementation would also mark the old vault as deprecated/deleted.
    }

    function removeCondition(uint252 _vaultId, uint252 _conditionIndex) external whenNotPaused {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "Condition index out of bounds");
        require(!vault.conditions[_conditionIndex].isReleased, "Cannot remove an already released condition");

        // Advanced security: could add a timelock or multi-sig requirement to remove conditions
        // or prevent removal if other conditions (e.g., transformation rules) depend on it.

        // Basic removal: Swap with last element and pop (common Solidity pattern for removing from array)
        if (_conditionIndex != vault.conditions.length - 1) {
            vault.conditions[_conditionIndex] = vault.conditions[vault.conditions.length - 1];
        }
        vault.conditions.pop();
        emit ConditionRemoved(_vaultId, _conditionIndex);
    }

    // Fallback function for receiving ETH
    fallback() external payable {
        // ETH sent to the contract's address without calling a specific function.
        // This ETH could be considered protocol fees or simply held.
        // For a digital legacy contract, direct unassigned ETH is not ideal,
        // so it might be better to explicitly revert or manage via protocol fees.
    }
}
```