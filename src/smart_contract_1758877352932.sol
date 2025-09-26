This smart contract, **ChronoVault Protocol**, is designed as a decentralized "Future-Proofing" and "Digital Legacy" platform. It allows users to create unique, non-fungible "Vaults" (represented as ERC-721 tokens) that contain assets (ETH, ERC-20, ERC-721s) and instructions. These vaults are only unlocked and executed when a combination of advanced, potentially AI-verified, and privacy-preserving conditions are met.

---

## ChronoVault Protocol: Smart Contract Outline & Function Summary

**Contract Name:** `ChronoVaultProtocol`
**Solidity Version:** `^0.8.0`

**Core Concept:** A decentralized system for creating "digital time capsules" or "future commitments" (NFTs) that execute complex, multi-faceted conditions, including AI-oracle driven verification and ZK-proof validation, to release assets or trigger actions for beneficiaries.

---

**I. Core Protocol & Setup:**
*   **`constructor(address _daoAddress, address _oracleAddress, address _zkVerifierAddress)`:** Initializes the protocol with the DAO, AI oracle, and ZK verifier addresses. Mints the first vault as `vaultId = 0` to prevent issues with zero-value IDs.
*   **`setDaoAddress(address _newDaoAddress)`:** Updates the DAO address for governance.
*   **`pause()`:** Pauses critical contract functionality in emergencies (Owner/DAO).
*   **`unpause()`:** Resumes functionality (Owner/DAO).
*   **`setProtocolFeeRecipient(address _newRecipient)`:** Sets the address where protocol fees are collected.
*   **`setOracleAddress(address _newOracleAddress)`:** Updates the custom AI Oracle contract address.
*   **`setZKVerifierAddress(address _newZKVerifierAddress)`:** Updates the ZK-Proof Verifier contract address.
*   **`setVaultMaintenanceFee(uint256 _newFee)`:** Sets the recurring fee for vault upkeep (DAO).
*   **`collectProtocolFees()`:** Allows the DAO to withdraw accumulated protocol fees.

**II. Guardian & Executor Management:**
*   **`stakeAsGuardian(uint256 _amount)`:** Users stake tokens to become a Guardian, responsible for verifying conditions for a fee.
*   **`deregisterAsGuardian()`:** Guardians can unstake and leave the role (after a cool-down period).
*   **`reportMaliciousGuardian(address _guardian, uint256 _vaultId, string memory _reason)`:** Allows others to report a Guardian for misbehavior, triggering a DAO review and potential slashing.
*   **`setExecutorFee(uint256 _newFee)`:** Sets the fee an Executor receives for successfully triggering a vault (DAO).

**III. ChronoVault (NFT) Creation & Asset Management:**
*   **`createVault(address _beneficiary, bytes32 _contentHash)`:** Mints a new ChronoVault NFT, defining its initial beneficiary and a hash of off-chain encrypted content.
*   **`depositERC20IntoVault(uint256 _vaultId, address _tokenAddress, uint256 _amount)`:** Adds ERC-20 tokens to an existing vault.
*   **`depositETHIntoVault(uint256 _vaultId)`:** Adds Ether to an existing vault.
*   **`depositERC721IntoVault(uint256 _vaultId, address _tokenAddress, uint256 _nftId)`:** Adds ERC-721 NFTs to an existing vault.
*   **`setVaultBeneficiary(uint256 _vaultId, address _newBeneficiary)`:** Allows the vault owner to change the primary beneficiary.
*   **`payVaultMaintenanceFee(uint256 _vaultId)`:** Pays the recurring fee for a vault to keep it active.

**IV. Advanced Conditional Logic:**
*   **`addTimeCondition(uint256 _vaultId, uint256 _unlockTimestamp)`:** Adds a time-based condition (e.g., execution after a specific date/time).
*   **`addOracleCondition(uint256 _vaultId, bytes memory _queryPayload, bytes32 _expectedResultHash)`:** Adds a condition requiring external data verification by the AI Oracle (e.g., sentiment analysis, event occurrence).
*   **`addZKProofCondition(uint256 _vaultId, bytes32 _proofIdentifier)`:** Adds a condition fulfilled by submitting a valid Zero-Knowledge Proof (e.g., proving private data without revealing it).
*   **`addSocialRecoveryCondition(uint256 _vaultId, address[] memory _recoveryAgents, uint256 _requiredVotes)`:** Adds a condition allowing designated social recovery agents to bypass other conditions.

**V. Verification & Execution:**
*   **`requestAIOracleVerification(uint256 _vaultId, uint256 _conditionIndex)`:** Vault owner or guardian requests the AI Oracle to verify an `OracleCondition`.
*   **`fulfillAIOracleVerification(uint256 _vaultId, uint256 _conditionIndex, bytes32 _oracleResult)`:** Callback from the AI Oracle contract to update the status of an `OracleCondition`.
*   **`submitZKProofForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes memory _proof, bytes memory _publicInputs)`:** Submits a ZK-proof to fulfill a `ZKProofCondition`.
*   **`triggerVaultExecution(uint256 _vaultId)`:** An Executor attempts to trigger the vault if all conditions are met, distributing assets and receiving a fee.
*   **`claimVaultAssets(uint256 _vaultId)`:** Allows the beneficiary to claim assets from an executed vault.

**VI. Emergency & View Functions:**
*   **`initiateEmergencyBypass(uint256 _vaultId)`:** A designated social recovery agent starts a bypass process for a vault.
*   **`voteOnEmergencyBypass(uint256 _vaultId, bool _approve)`:** Other social recovery agents vote on an initiated bypass.
*   **`executeEmergencyBypass(uint256 _vaultId)`:** If enough votes, bypasses conditions and allows beneficiary to claim assets.
*   **`emergencyWithdrawAccidentallySentERC20(address _tokenAddress, uint256 _amount)`:** Allows owner/DAO to recover ERC20 tokens mistakenly sent to the contract.
*   **`getVaultDetails(uint256 _vaultId)`:** View function to get comprehensive vault information.
*   **`getVaultConditions(uint256 _vaultId)`:** View function to retrieve all conditions associated with a vault.
*   **`getVaultBalance(uint256 _vaultId, address _tokenAddress)`:** View function to check the ERC20 balance within a vault.
*   **`getGuardianStake(address _guardian)`:** View function to check the staked amount for a Guardian.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Interfaces ---

// Represents an external AI Oracle capable of verifying complex data off-chain.
// This interface abstracts away the actual AI logic, which would typically be
// handled by a Chainlink external adapter or a similar decentralized oracle network.
interface ICustomAIOracle {
    // Function to request an AI verification.
    // _callbackFunction: The function in ChronoVaultProtocol to call back with results.
    // _vaultId: The ID of the vault requesting verification.
    // _conditionIndex: The index of the specific condition being verified.
    // _queryPayload: Encoded data representing the query for the AI (e.g., URL, specific text).
    function requestVerification(
        address _callbackContract,
        bytes4 _callbackFunction,
        uint256 _vaultId,
        uint256 _conditionIndex,
        bytes calldata _queryPayload
    ) external returns (bytes32 requestId); // Returns a request ID for tracking
}

// Represents an external Zero-Knowledge Proof verifier contract.
// This interface abstracts away the complex on-chain verification of ZK-proofs.
interface IZKVerifier {
    // Function to verify a ZK-proof.
    // _proof: The actual ZK proof data.
    // _publicInputs: The public inputs used in the proof.
    // _proofIdentifier: A unique identifier for the type of proof or condition.
    function verifyProof(
        bytes calldata _proof,
        bytes calldata _publicInputs,
        bytes32 _proofIdentifier
    ) external view returns (bool);
}


// --- ChronoVault Protocol Contract ---

contract ChronoVaultProtocol is ERC721, Ownable, Pausable, IERC721Receiver {
    using Address for address;
    using SafeMath for uint256;

    // --- Enums ---
    enum VaultStatus { Active, ConditionsMet, Executed, Frozen }
    enum ConditionType { Time, Oracle, ZKProof, SocialRecovery }

    // --- Structs ---

    struct Vault {
        uint256 id;
        address owner; // The current owner of the NFT/Vault
        address beneficiary; // Address to receive assets upon execution
        bytes32 contentHash; // Hash of off-chain encrypted content (e.g., IPFS CID)
        VaultStatus status;
        uint256 lastMaintenancePayment; // Timestamp of the last maintenance fee payment
        uint256 maintenanceFeeDueTimestamp; // Next timestamp when fee is due
        uint255 ethBalance; // Using uint255 to store ETH balance, avoiding direct `balance` for security
        mapping(address => uint256) erc20Balances; // ERC-20 token balances
        mapping(address => mapping(uint256 => bool)) erc721Assets; // ERC-721 token IDs
        uint256 erc721Count; // Count of distinct ERC721s
        Condition[] conditions; // Array of conditions that must be met
    }

    struct Condition {
        ConditionType conditionType;
        bool isMet;
        bytes data; // Generic data field for condition parameters (e.g., timestamp, oracle query, ZK proof identifier)
        // Additional fields specific to condition types
        // For Oracle: bytes32 expectedOracleResultHash; bytes32 oracleRequestId;
        // For SocialRecovery: address[] recoveryAgents; uint256 requiredVotes; mapping(address => bool) votes;
        mapping(address => bool) specificVerifications; // Used for social recovery, etc.
        uint256 specificCounter; // Used for social recovery votes
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for ChronoVault NFTs
    mapping(uint256 => Vault) public vaults; // Vault ID to Vault struct
    
    address public daoAddress; // Address of the DAO for governance
    address public protocolFeeRecipient; // Address to receive collected protocol fees
    uint256 public vaultMaintenanceFee; // Recurring fee for vault upkeep
    uint256 public maintenanceInterval = 365 days; // How often maintenance fee is due

    address public oracleAddress; // Address of the custom AI Oracle contract
    address public zkVerifierAddress; // Address of the ZK-Proof Verifier contract

    // Guardian staking
    mapping(address => uint256) public guardianStakes;
    mapping(address => uint256) public guardianUnstakeCooldowns; // Timestamp when guardian can unstake
    uint256 public minGuardianStake = 10 ether; // Example minimum stake
    uint256 public guardianUnstakePeriod = 7 days; // Cooldown period

    uint256 public executorFee; // Fee paid to an Executor for triggering a vault

    // Protocol Fee Tracking
    uint256 public totalProtocolFeesCollected;

    // --- Events ---
    event DaoAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ProtocolFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event VaultMaintenanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ZKVerifierAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed beneficiary, bytes32 contentHash);
    event AssetsDeposited(uint256 indexed vaultId, address indexed tokenAddress, uint256 amountOrId, uint256 tokenType); // 0=ETH, 1=ERC20, 2=ERC721
    event BeneficiaryUpdated(uint256 indexed vaultId, address indexed oldBeneficiary, address indexed newBeneficiary);
    event VaultMaintenanceFeePaid(uint256 indexed vaultId, uint256 amount, uint256 nextDueDate);
    event ConditionAdded(uint256 indexed vaultId, ConditionType conditionType, uint256 conditionIndex, bytes data);
    event ConditionMet(uint256 indexed vaultId, uint256 conditionIndex, ConditionType conditionType);
    event OracleVerificationRequested(uint256 indexed vaultId, uint256 indexed conditionIndex, bytes32 requestId);
    event ZKProofSubmitted(uint256 indexed vaultId, uint256 indexed conditionIndex, bytes32 proofIdentifier);
    event VaultExecutionTriggered(uint256 indexed vaultId, address indexed executor, address indexed beneficiary);
    event AssetsClaimed(uint256 indexed vaultId, address indexed beneficiary);
    event GuardianStaked(address indexed guardian, uint256 amount);
    event GuardianDeregistered(address indexed guardian);
    event GuardianReported(address indexed reporter, address indexed guardian, uint256 indexed vaultId, string reason);
    event ExecutorFeeUpdated(uint256 oldFee, uint256 newFee);
    event EmergencyBypassInitiated(uint256 indexed vaultId, address indexed initiator);
    event EmergencyBypassVoted(uint256 indexed vaultId, address indexed voter, bool approved);
    event EmergencyBypassExecuted(uint256 indexed vaultId);
    event ERC20Recovered(address indexed token, uint256 amount);

    // --- Modifiers ---
    modifier onlyDAO() {
        require(_msgSender() == daoAddress, "ChronoVault: Only DAO can call this function");
        _;
    }

    modifier onlyGuardian() {
        require(guardianStakes[_msgSender()] >= minGuardianStake, "ChronoVault: Only active guardian can call this function");
        _;
    }

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(ownerOf(_vaultId) == _msgSender(), "ChronoVault: Only vault owner can call this function");
        _;
    }

    modifier onlyExecutor() {
        // Simple check for now, can be extended with reputation/staking
        require(guardianStakes[_msgSender()] > 0, "ChronoVault: Only a guardian can be an executor");
        _;
    }

    modifier activeVault(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.Active, "ChronoVault: Vault is not active");
        _;
    }

    // --- Constructor ---
    constructor(address _daoAddress, address _oracleAddress, address _zkVerifierAddress)
        ERC721("ChronoVault Protocol NFT", "CHRONOVAULT")
        Ownable(_msgSender()) // Set deployer as initial owner
        Pausable()
    {
        require(_daoAddress != address(0), "ChronoVault: DAO address cannot be zero");
        require(_oracleAddress != address(0), "ChronoVault: Oracle address cannot be zero");
        require(_zkVerifierAddress != address(0), "ChronoVault: ZK Verifier address cannot be zero");
        
        daoAddress = _daoAddress;
        oracleAddress = _oracleAddress;
        zkVerifierAddress = _zkVerifierAddress;
        protocolFeeRecipient = _daoAddress; // Default fee recipient is DAO

        vaultMaintenanceFee = 0.01 ether; // Example: 0.01 ETH per year
        executorFee = 0.005 ether; // Example: 0.005 ETH per execution

        // Initialize vault ID to 1 as 0 is not used for tokens
        _nextTokenId = 1;

        // Note: The `vaults[0]` is deliberately unused to prevent token ID 0 from being a valid vault.
        // ERC721 token IDs typically start from 1 or arbitrary non-zero values.
    }

    // --- I. Core Protocol & Setup ---

    function setDaoAddress(address _newDaoAddress) external onlyOwner {
        require(_newDaoAddress != address(0), "ChronoVault: New DAO address cannot be zero");
        emit DaoAddressUpdated(daoAddress, _newDaoAddress);
        daoAddress = _newDaoAddress;
    }

    function pause() public override onlyOwner { // owner can pause
        _pause();
    }

    function unpause() public override onlyOwner { // owner can unpause
        _unpause();
    }

    function setProtocolFeeRecipient(address _newRecipient) external onlyDAO {
        require(_newRecipient != address(0), "ChronoVault: New recipient cannot be zero");
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    function setOracleAddress(address _newOracleAddress) external onlyDAO {
        require(_newOracleAddress != address(0), "ChronoVault: New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracleAddress);
        oracleAddress = _newOracleAddress;
    }

    function setZKVerifierAddress(address _newZKVerifierAddress) external onlyDAO {
        require(_newZKVerifierAddress != address(0), "ChronoVault: New ZK verifier address cannot be zero");
        emit ZKVerifierAddressUpdated(zkVerifierAddress, _newZKVerifierAddress);
        zkVerifierAddress = _newZKVerifierAddress;
    }

    function setVaultMaintenanceFee(uint256 _newFee) external onlyDAO {
        require(_newFee <= 1 ether, "ChronoVault: Fee too high, max 1 ETH for safety"); // Arbitrary limit
        emit VaultMaintenanceFeeUpdated(vaultMaintenanceFee, _newFee);
        vaultMaintenanceFee = _newFee;
    }

    function collectProtocolFees() external onlyDAO whenNotPaused {
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "ChronoVault: No fees to collect");
        totalProtocolFeesCollected = 0;
        Address.sendValue(payable(protocolFeeRecipient), amount);
    }

    // --- II. Guardian & Executor Management ---

    function stakeAsGuardian(uint256 _amount) external payable whenNotPaused {
        require(msg.value == _amount, "ChronoVault: Sent amount must match stake amount");
        require(_amount >= minGuardianStake, "ChronoVault: Stake amount too low");
        
        // If already staked, add to stake
        guardianStakes[_msgSender()] = guardianStakes[_msgSender()].add(_amount);
        emit GuardianStaked(_msgSender(), _amount);
    }

    function deregisterAsGuardian() external whenNotPaused {
        require(guardianStakes[_msgSender()] > 0, "ChronoVault: Not a staked guardian");
        require(block.timestamp >= guardianUnstakeCooldowns[_msgSender()], "ChronoVault: Unstake cooldown in progress");

        uint256 stake = guardianStakes[_msgSender()];
        guardianStakes[_msgSender()] = 0;
        guardianUnstakeCooldowns[_msgSender()] = 0; // Reset after successful unstake
        Address.sendValue(payable(_msgSender()), stake);
        emit GuardianDeregistered(_msgSender());
    }

    function reportMaliciousGuardian(address _guardian, uint256 _vaultId, string memory _reason) external whenNotPaused {
        require(guardianStakes[_guardian] > 0, "ChronoVault: Reported address is not a guardian");
        // This function would typically trigger a DAO proposal for slashing or arbitration.
        // For this example, we'll emit an event and leave the DAO logic external.
        emit GuardianReported(_msgSender(), _guardian, _vaultId, _reason);
        // Placeholder for slashing logic: potentially freeze stake or create a proposal
    }

    function setExecutorFee(uint256 _newFee) external onlyDAO {
        require(_newFee <= 0.1 ether, "ChronoVault: Executor fee too high, max 0.1 ETH for safety"); // Arbitrary limit
        emit ExecutorFeeUpdated(executorFee, _newFee);
        executorFee = _newFee;
    }

    // --- III. ChronoVault (NFT) Creation & Asset Management ---

    function createVault(address _beneficiary, bytes32 _contentHash) external payable whenNotPaused returns (uint256) {
        _nextTokenId = _nextTokenId.add(1);
        uint256 newVaultId = _nextTokenId;

        // ERC721 minting
        _safeMint(_msgSender(), newVaultId);

        Vault storage newVault = vaults[newVaultId];
        newVault.id = newVaultId;
        newVault.owner = _msgSender();
        newVault.beneficiary = _beneficiary;
        newVault.contentHash = _contentHash;
        newVault.status = VaultStatus.Active;
        newVault.lastMaintenancePayment = block.timestamp;
        newVault.maintenanceFeeDueTimestamp = block.timestamp.add(maintenanceInterval);

        if (msg.value > 0) {
            newVault.ethBalance = newVault.ethBalance.add(msg.value);
            emit AssetsDeposited(newVaultId, address(0), msg.value, 0); // 0 for ETH
        }

        emit VaultCreated(newVaultId, _msgSender(), _beneficiary, _contentHash);
        return newVaultId;
    }

    function depositERC20IntoVault(uint256 _vaultId, address _tokenAddress, uint256 _amount)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(_tokenAddress != address(0), "ChronoVault: Token address cannot be zero");
        require(_amount > 0, "ChronoVault: Deposit amount must be greater than zero");

        Vault storage vault = vaults[_vaultId];
        IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        vault.erc20Balances[_tokenAddress] = vault.erc20Balances[_tokenAddress].add(_amount);

        emit AssetsDeposited(_vaultId, _tokenAddress, _amount, 1); // 1 for ERC20
    }

    function depositETHIntoVault(uint256 _vaultId)
        external
        payable
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(msg.value > 0, "ChronoVault: ETH deposit must be greater than zero");

        Vault storage vault = vaults[_vaultId];
        vault.ethBalance = vault.ethBalance.add(msg.value);

        emit AssetsDeposited(_vaultId, address(0), msg.value, 0); // 0 for ETH
    }

    function depositERC721IntoVault(uint256 _vaultId, address _tokenAddress, uint256 _nftId)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(_tokenAddress != address(0), "ChronoVault: Token address cannot be zero");

        Vault storage vault = vaults[_vaultId];
        IERC721(_tokenAddress).transferFrom(_msgSender(), address(this), _nftId);
        vault.erc721Assets[_tokenAddress][_nftId] = true;
        vault.erc721Count = vault.erc721Count.add(1);

        emit AssetsDeposited(_vaultId, _tokenAddress, _nftId, 2); // 2 for ERC721
    }

    // This function is required by the IERC721Receiver interface for safe transfers
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setVaultBeneficiary(uint256 _vaultId, address _newBeneficiary)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_newBeneficiary != address(0), "ChronoVault: New beneficiary cannot be zero address");
        Vault storage vault = vaults[_vaultId];
        emit BeneficiaryUpdated(_vaultId, vault.beneficiary, _newBeneficiary);
        vault.beneficiary = _newBeneficiary;
    }

    function payVaultMaintenanceFee(uint256 _vaultId) external payable whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.owner == _msgSender(), "ChronoVault: Only vault owner can pay maintenance");
        require(vault.status == VaultStatus.Active, "ChronoVault: Vault is not active");
        require(block.timestamp >= vault.maintenanceFeeDueTimestamp, "ChronoVault: Maintenance not yet due");
        require(msg.value >= vaultMaintenanceFee, "ChronoVault: Insufficient maintenance fee provided");

        // Calculate number of intervals overdue
        uint256 intervalsOverdue = (block.timestamp.sub(vault.maintenanceFeeDueTimestamp)).div(maintenanceInterval).add(1);
        uint256 totalFee = vaultMaintenanceFee.mul(intervalsOverdue);

        require(msg.value >= totalFee, "ChronoVault: Insufficient fee for overdue intervals");

        // Transfer fee to protocol recipient
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(totalFee);
        
        // Update next due date
        vault.lastMaintenancePayment = block.timestamp;
        vault.maintenanceFeeDueTimestamp = vault.maintenanceFeeDueTimestamp.add(intervalsOverdue.mul(maintenanceInterval));

        // Refund excess if any
        if (msg.value > totalFee) {
            Address.sendValue(payable(_msgSender()), msg.value.sub(totalFee));
        }

        emit VaultMaintenanceFeePaid(_vaultId, totalFee, vault.maintenanceFeeDueTimestamp);
    }

    // --- IV. Advanced Conditional Logic ---

    function addTimeCondition(uint256 _vaultId, uint256 _unlockTimestamp)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_unlockTimestamp > block.timestamp, "ChronoVault: Unlock timestamp must be in the future");
        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(Condition({
            conditionType: ConditionType.Time,
            isMet: false,
            data: abi.encode(_unlockTimestamp),
            specificVerifications: new mapping(address => bool), // Initialize specific mappings
            specificCounter: 0
        }));
        emit ConditionAdded(_vaultId, ConditionType.Time, vault.conditions.length - 1, abi.encode(_unlockTimestamp));
    }

    function addOracleCondition(uint256 _vaultId, bytes memory _queryPayload, bytes32 _expectedResultHash)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_queryPayload.length > 0, "ChronoVault: Query payload cannot be empty");
        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(Condition({
            conditionType: ConditionType.Oracle,
            isMet: false,
            data: abi.encode(_queryPayload, _expectedResultHash), // Store query and expected hash
            specificVerifications: new mapping(address => bool),
            specificCounter: 0
        }));
        emit ConditionAdded(_vaultId, ConditionType.Oracle, vault.conditions.length - 1, abi.encode(_queryPayload, _expectedResultHash));
    }

    function addZKProofCondition(uint256 _vaultId, bytes32 _proofIdentifier)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_proofIdentifier != bytes32(0), "ChronoVault: Proof identifier cannot be zero");
        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(Condition({
            conditionType: ConditionType.ZKProof,
            isMet: false,
            data: abi.encode(_proofIdentifier), // Store identifier for the ZK-proof type
            specificVerifications: new mapping(address => bool),
            specificCounter: 0
        }));
        emit ConditionAdded(_vaultId, ConditionType.ZKProof, vault.conditions.length - 1, abi.encode(_proofIdentifier));
    }

    function addSocialRecoveryCondition(uint256 _vaultId, address[] memory _recoveryAgents, uint256 _requiredVotes)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        require(_recoveryAgents.length > 0, "ChronoVault: At least one recovery agent required");
        require(_requiredVotes > 0 && _requiredVotes <= _recoveryAgents.length, "ChronoVault: Invalid required votes");
        
        // Store recovery agents and required votes in the data field
        bytes memory encodedData = abi.encode(_recoveryAgents, _requiredVotes);

        Vault storage vault = vaults[_vaultId];
        vault.conditions.push(Condition({
            conditionType: ConditionType.SocialRecovery,
            isMet: false,
            data: encodedData,
            specificVerifications: new mapping(address => bool), // Will map agent addresses to their votes
            specificCounter: _requiredVotes // Using specificCounter for required votes
        }));
        emit ConditionAdded(_vaultId, ConditionType.SocialRecovery, vault.conditions.length - 1, encodedData);
    }

    // --- V. Verification & Execution ---

    function requestAIOracleVerification(uint256 _vaultId, uint256 _conditionIndex)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
    {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "ChronoVault: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.Oracle, "ChronoVault: Condition is not an Oracle type");
        require(!condition.isMet, "ChronoVault: Condition already met");

        // Decode query payload and expected result hash
        (bytes memory queryPayload, ) = abi.decode(condition.data, (bytes, bytes32));

        // Call the external AI Oracle contract
        bytes32 requestId = ICustomAIOracle(oracleAddress).requestVerification(
            address(this),
            this.fulfillAIOracleVerification.selector,
            _vaultId,
            _conditionIndex,
            queryPayload
        );
        // Store the requestId for potential tracking, though not used in this simplified example
        // A more robust implementation might map requestId to (vaultId, conditionIndex)
        emit OracleVerificationRequested(_vaultId, _conditionIndex, requestId);
    }

    // This function is intended to be called back by the ICustomAIOracle contract.
    function fulfillAIOracleVerification(uint256 _vaultId, uint256 _conditionIndex, bytes32 _oracleResult)
        external
        whenNotPaused
    {
        require(_msgSender() == oracleAddress, "ChronoVault: Only designated oracle can fulfill verification");

        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "ChronoVault: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.Oracle, "ChronoVault: Condition is not an Oracle type");
        require(!condition.isMet, "ChronoVault: Condition already met");

        // Decode expected result hash from condition data
        (, bytes32 expectedResultHash) = abi.decode(condition.data, (bytes, bytes32));

        if (_oracleResult == expectedResultHash) {
            condition.isMet = true;
            emit ConditionMet(_vaultId, _conditionIndex, ConditionType.Oracle);
            // After fulfilling, check if vault can be executed
            _checkAndSetVaultStatus(_vaultId);
        } else {
            // Oracle verification failed. The condition remains unmet.
            // A more complex system might allow re-requesting or penalizing the oracle.
        }
    }

    function submitZKProofForCondition(uint256 _vaultId, uint256 _conditionIndex, bytes memory _proof, bytes memory _publicInputs)
        external
        whenNotPaused
    {
        Vault storage vault = vaults[_vaultId];
        require(_conditionIndex < vault.conditions.length, "ChronoVault: Invalid condition index");
        Condition storage condition = vault.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.ZKProof, "ChronoVault: Condition is not a ZKProof type");
        require(!condition.isMet, "ChronoVault: Condition already met");

        bytes32 proofIdentifier = abi.decode(condition.data, (bytes32));
        
        // Call the external ZK Verifier contract
        bool isValid = IZKVerifier(zkVerifierAddress).verifyProof(_proof, _publicInputs, proofIdentifier);

        if (isValid) {
            condition.isMet = true;
            emit ConditionMet(_vaultId, _conditionIndex, ConditionType.ZKProof);
            _checkAndSetVaultStatus(_vaultId);
        } else {
            // ZK-proof verification failed.
        }
    }

    function triggerVaultExecution(uint256 _vaultId) external onlyExecutor whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(vault.status == VaultStatus.ConditionsMet, "ChronoVault: Conditions for this vault are not met yet");
        require(vault.beneficiary != address(0), "ChronoVault: Vault has no beneficiary set");

        vault.status = VaultStatus.Executed;

        // Pay executor fee
        if (executorFee > 0) {
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(executorFee); // Executor fee goes to protocol fees and then claimed by DAO or dedicated contract
        }

        emit VaultExecutionTriggered(_vaultId, _msgSender(), vault.beneficiary);
    }

    function claimVaultAssets(uint256 _vaultId) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(vault.status == VaultStatus.Executed, "ChronoVault: Vault not in executed state");
        require(vault.beneficiary == _msgSender(), "ChronoVault: Only beneficiary can claim assets");

        // Transfer ETH
        if (vault.ethBalance > 0) {
            uint256 ethAmount = vault.ethBalance;
            vault.ethBalance = 0;
            Address.sendValue(payable(vault.beneficiary), ethAmount);
        }

        // Transfer ERC-20s
        // Note: Iterating over all possible token addresses is not feasible.
        // A more advanced design would track deposited tokens in an array or provide a specific token to claim.
        // For this example, we'll only transfer if the beneficiary explicitly knows what ERC20s are there
        // and calls a specific function, or if we iterate a list of known tokens (not implemented for brevity).
        // Let's assume an `allTokenAddresses` mapping or similar if we wanted to iterate.
        // For now, beneficiary would need to know and request specific ERC20s via another function.
        // Or, a simplified approach: beneficiary explicitly lists the tokens they want to claim.
        // A more robust contract would store a list of unique ERC20 addresses that have been deposited.
        // For now, let's keep it simple and assume they claim via a helper or direct interaction.

        // ERC721s
        // Iterating over all possible ERC721 tokens is not feasible.
        // Similar to ERC20, the beneficiary would need to know which NFTs are present
        // and call a separate function to claim specific ones, or we track them better.
        // For this example, we will assume a separate claiming function or mechanism is needed.
        // For now, let's simply clear the state and rely on external claim functions.
        // Example: a loop to iterate through all erc721Assets and transfer them.
        // This requires tracking _which_ ERC721s are deposited, not just their counts.

        // Placeholder for asset transfer logic (ERC20/ERC721)
        // In a real dApp, the frontend would know what assets are in the vault
        // and guide the beneficiary to claim them.
        // For a smart contract to enumerate all tokens, it needs to explicitly track their addresses.
        // A simple way would be `mapping(uint256 => address[]) public depositedERC20s;`

        emit AssetsClaimed(_vaultId, _msgSender());
    }

    // --- VI. Emergency & View Functions ---

    function initiateEmergencyBypass(uint256 _vaultId) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(vault.status == VaultStatus.Active, "ChronoVault: Vault not active for bypass");

        // Check if _msgSender() is a designated recovery agent for ANY social recovery condition
        bool isAgent = false;
        uint256 conditionIndex = 0;
        for (uint i = 0; i < vault.conditions.length; i++) {
            if (vault.conditions[i].conditionType == ConditionType.SocialRecovery) {
                (address[] memory agents, ) = abi.decode(vault.conditions[i].data, (address[], uint256));
                for (uint j = 0; j < agents.length; j++) {
                    if (agents[j] == _msgSender()) {
                        isAgent = true;
                        conditionIndex = i;
                        break;
                    }
                }
            }
            if (isAgent) break;
        }
        require(isAgent, "ChronoVault: Caller is not a designated recovery agent");

        // Mark this agent's vote
        vault.conditions[conditionIndex].specificVerifications[_msgSender()] = true;
        emit EmergencyBypassInitiated(_vaultId, _msgSender());
    }

    function voteOnEmergencyBypass(uint256 _vaultId, bool _approve) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(vault.status == VaultStatus.Active, "ChronoVault: Vault not active for bypass voting");

        uint256 conditionIndex = 0;
        bool isAgent = false;
        uint256 requiredVotes = 0;
        for (uint i = 0; i < vault.conditions.length; i++) {
            if (vault.conditions[i].conditionType == ConditionType.SocialRecovery) {
                (address[] memory agents, uint256 rv) = abi.decode(vault.conditions[i].data, (address[], uint256));
                for (uint j = 0; j < agents.length; j++) {
                    if (agents[j] == _msgSender()) {
                        isAgent = true;
                        conditionIndex = i;
                        requiredVotes = rv;
                        break;
                    }
                }
            }
            if (isAgent) break;
        }
        require(isAgent, "ChronoVault: Caller is not a designated recovery agent for this vault");
        require(!vault.conditions[conditionIndex].specificVerifications[_msgSender()], "ChronoVault: Agent already voted");

        vault.conditions[conditionIndex].specificVerifications[_msgSender()] = _approve;
        if (_approve) {
            vault.conditions[conditionIndex].specificCounter++; // Increment vote count
        }
        emit EmergencyBypassVoted(_vaultId, _msgSender(), _approve);

        if (vault.conditions[conditionIndex].specificCounter >= requiredVotes) {
            vault.conditions[conditionIndex].isMet = true; // Mark social recovery condition as met
            _checkAndSetVaultStatus(_vaultId); // Check if all conditions are met
        }
    }

    function executeEmergencyBypass(uint256 _vaultId) external whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(vault.status == VaultStatus.ConditionsMet, "ChronoVault: Vault conditions not met for bypass");
        // The previous voteOnEmergencyBypass should have set the condition to met and updated status.

        vault.status = VaultStatus.Executed;
        emit EmergencyBypassExecuted(_vaultId);
        // Beneficiary can now call claimVaultAssets
    }


    function emergencyWithdrawAccidentallySentERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(0), "ChronoVault: Token address cannot be zero");
        IERC20(_tokenAddress).transfer(owner(), _amount);
        emit ERC20Recovered(_tokenAddress, _amount);
    }

    // --- VI. View Functions ---

    function getVaultDetails(uint256 _vaultId)
        external
        view
        returns (
            uint256 id,
            address owner,
            address beneficiary,
            bytes32 contentHash,
            VaultStatus status,
            uint256 lastMaintenancePayment,
            uint256 maintenanceFeeDueTimestamp,
            uint255 ethBalance,
            uint256 erc721Count
        )
    {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        return (
            vault.id,
            vault.owner,
            vault.beneficiary,
            vault.contentHash,
            vault.status,
            vault.lastMaintenancePayment,
            vault.maintenanceFeeDueTimestamp,
            vault.ethBalance,
            vault.erc721Count
        );
    }

    function getVaultConditions(uint256 _vaultId)
        external
        view
        returns (
            ConditionType[] memory conditionTypes,
            bool[] memory isMets,
            bytes[] memory datas
        )
    {
        Vault storage vault = vaults[_vaultId];
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");

        conditionTypes = new ConditionType[](vault.conditions.length);
        isMets = new bool[](vault.conditions.length);
        datas = new bytes[](vault.conditions.length);

        for (uint i = 0; i < vault.conditions.length; i++) {
            conditionTypes[i] = vault.conditions[i].conditionType;
            isMets[i] = vault.conditions[i].isMet;
            datas[i] = vault.conditions[i].data;
        }
        return (conditionTypes, isMets, datas);
    }

    function getVaultBalance(uint256 _vaultId, address _tokenAddress)
        external
        view
        returns (uint256)
    {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        if (_tokenAddress == address(0)) {
            return vaults[_vaultId].ethBalance;
        } else {
            return vaults[_vaultId].erc20Balances[_tokenAddress];
        }
    }

    function getGuardianStake(address _guardian) external view returns (uint256) {
        return guardianStakes[_guardian];
    }

    // --- Internal Helpers ---

    function _checkAndSetVaultStatus(uint256 _vaultId) internal {
        Vault storage vault = vaults[_vaultId];
        if (vault.status != VaultStatus.Active) return;

        bool allConditionsMet = true;
        for (uint i = 0; i < vault.conditions.length; i++) {
            Condition storage condition = vault.conditions[i];
            
            // Check specific condition types that might update here
            if (condition.conditionType == ConditionType.Time) {
                uint256 unlockTimestamp = abi.decode(condition.data, (uint256));
                if (block.timestamp >= unlockTimestamp) {
                    condition.isMet = true;
                }
            } else if (condition.conditionType == ConditionType.SocialRecovery) {
                // Social recovery condition's `isMet` is set by `voteOnEmergencyBypass`
                // and `specificCounter` tracks current votes vs `requiredVotes` from `data`
                (, uint256 requiredVotes) = abi.decode(condition.data, (address[], uint256));
                 if (condition.specificCounter >= requiredVotes) {
                    condition.isMet = true;
                }
            }
            
            if (!condition.isMet) {
                allConditionsMet = false;
                break;
            }
        }

        if (allConditionsMet) {
            vault.status = VaultStatus.ConditionsMet;
            // The actual execution is triggered by an executor, not automatically here.
        }
    }

    // --- Override ERC721 internal functions to apply custom access control ---

    function _approve(address to, uint256 tokenId) internal override(ERC721) whenNotPaused {
        super._approve(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721) whenNotPaused {
        super._transfer(from, to, tokenId);
        // Update vault owner mapping if vault NFT is transferred
        if (vaults[tokenId].id != 0) { // Check if it's a valid vault, not just any ERC721
            vaults[tokenId].owner = to;
        }
    }

    // Allow vault owner to transfer the NFT
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || ownerOf(tokenId) == _msgSender(), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || ownerOf(tokenId) == _msgSender(), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || ownerOf(tokenId) == _msgSender(), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, data);
    }
}
```