```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoVault & Oracle Weaver
 * @dev A decentralized platform for creating "future-proof" digital vaults.
 *      Users can store encrypted data hashes (referencing off-chain data)
 *      to be released based on complex, verifiable conditions involving
 *      real-world events, "Digital Persona" AI agents, or multi-signature consensus.
 *      It integrates a decentralized Oracle Weaver network for condition verification.
 *      This contract acts as a gatekeeper, releasing the *access* to the off-chain
 *      encrypted data (e.g., decryption keys, IPFS hashes, etc.) upon condition fulfillment.
 *
 * Concepts Incorporated:
 * - **Advanced Conditional Release:** Beyond simple time-locks, supporting external
 *   data/event verification, "Digital Persona" consent, and multi-sig.
 * - **Decentralized Oracle Weaver Network:** For verifiable real-world data feeds
 *   and event attestation, with a voting mechanism for report validity.
 * - **Simulated AI/ML Integration (Digital Persona):** Users can link an external
 *   smart contract (their "Digital Persona" agent) that can provide consent or
 *   make decisions on their behalf after specific conditions are met,
 *   simulating autonomous future interaction. This agent acts as a proxy for
 *   complex decision-making, whose logic is external to ChronoVault.
 * - **Progressive Disclosure:** Different parts of data (represented by hashes)
 *   could be released or revealed based on a cascade of conditions.
 * - **Emergency Release Mechanisms:** Pre-defined conditions for urgent access.
 * - **Off-chain Data Integrity:** Vaults store cryptographic hashes of encrypted
 *   off-chain data, ensuring on-chain verifiability without storing sensitive info.
 * - **Dynamic Fee Structure:** Protocol fees to sustain the network.
 * - **Event-Driven Architecture:** Extensive use of events for off-chain monitoring.
 */

// --- OUTLINE ---
// I. Interfaces, Data Structures & Constants
// II. Events
// III. Modifiers
// IV. Core Vault Management
// V. Oracle Weaver Network Management
// VI. Condition Evaluation & Reporting
// VII. Digital Persona Agent Management (Simulated AI)
// VIII. Vault Release & Access
// IX. Protocol Governance & Fees

// --- FUNCTION SUMMARY ---

// I. Interfaces, Data Structures & Constants
//    - IAgent: Interface for external Digital Persona agent contracts.
//    - VaultStatus: Enum for vault states.
//    - ConditionType: Enum for types of release conditions.
//    - Vault: Struct for vault data.
//    - Condition: Struct for release condition details.
//    - BeneficiaryAccess: Struct to manage beneficiary access levels.
//    - Oracle: Struct for registered oracle data.
//    - OracleReport: Struct for an oracle's submission.
//    - Request: Struct for a verification request.

// II. Events
//    - VaultCreated(bytes32 vaultId, address owner, bytes32 encryptedDataHash, address[] beneficiaries): Emitted when a new vault is created.
//    - VaultContentHashUpdated(bytes32 vaultId, bytes32 newEncryptedDataHash): Emitted when vault's content hash changes.
//    - BeneficiaryAdded(bytes32 vaultId, address beneficiary, uint256 accessLevel): Emitted when beneficiaries are managed.
//    - BeneficiaryRemoved(bytes32 vaultId, address beneficiary): Emitted when beneficiaries are managed.
//    - ConditionSet(bytes32 vaultId, ConditionType conditionType, bytes conditionParams, bool isEmergency): Emitted when conditions are defined.
//    - VaultReleased(bytes32 vaultId, address recipient): Emitted when vault content is released.
//    - VaultRevoked(bytes32 vaultId, address owner): Emitted when a vault is revoked by its owner.
//    - OracleRegistered(address oracleAddress, string name, bytes32 commitmentHash): Emitted when oracles join.
//    - OracleDeregistered(address oracleAddress): Emitted when oracles leave.
//    - OracleReputationUpdated(address oracleAddress, int256 change, uint256 newReputation): Emitted when oracle reputation changes.
//    - ConditionVerificationRequested(bytes32 requestId, bytes32 vaultId, ConditionType conditionType): Emitted when a verification is initiated.
//    - OracleReportSubmitted(bytes32 requestId, address oracleAddress, bytes data, bytes signature): Emitted when an oracle submits data.
//    - OracleReportVoted(bytes32 requestId, uint256 reportIndex, address voter, bool isValid): Emitted when a vote is cast on a report.
//    - ConditionResolved(bytes32 vaultId, bytes32 requestId, bool conditionMet): Emitted when a condition's status is finalized.
//    - PersonaAgentDeployed(bytes32 vaultId, address agentContractAddress): Emitted when an agent is linked.
//    - PersonaAgentUpdated(bytes32 vaultId, address oldAddress, address newAddress): Emitted when agent address is updated.
//    - PersonaDecisionRulesConfigured(bytes32 vaultId, bytes32 rulesHash, uint256 ruleType): Emitted when persona rules are configured.
//    - PersonaActionTriggered(bytes32 vaultId, address agentAddress, bytes actionData): Emitted when persona action is triggered.
//    - ProtocolFeeSet(uint256 oldFee, uint256 newFee): Emitted when the protocol fee is updated.
//    - ProtocolFeesWithdrawn(address recipient, uint256 amount): Emitted when fees are withdrawn.
//    - AdminChanged(address oldAdmin, address newAdmin): Emitted when admin address is changed.

// III. Modifiers
//    - onlyOwner(_vaultId): Restricts access to the vault owner.
//    - onlyOracle(): Restricts access to registered oracles.
//    - onlyAdmin(): Restricts access to the contract administrator.

// IV. Core Vault Management (7 functions)
//    1. createChronoVault(bytes32 _vaultId, bytes32 _encryptedDataHash, address[] calldata _initialBeneficiaries): Creates a new time/event-locked digital vault.
//    2. updateVaultContentHash(bytes32 _vaultId, bytes32 _newEncryptedDataHash): Updates the cryptographic hash of the off-chain encrypted data.
//    3. addBeneficiary(bytes32 _vaultId, address _newBeneficiary, uint256 _accessLevel): Adds a beneficiary with a specific access level.
//    4. removeBeneficiary(bytes32 _vaultId, address _beneficiary): Removes a beneficiary from the vault.
//    5. setVaultReleaseCondition(bytes32 _vaultId, ConditionType _conditionType, bytes calldata _conditionParams): Sets the primary release condition for the vault.
//    6. setEmergencyReleaseCondition(bytes32 _vaultId, ConditionType _conditionType, bytes calldata _conditionParams): Sets an emergency release condition for the vault.
//    7. revokeVault(bytes32 _vaultId): Allows the owner to revoke and destroy their vault before release.

// V. Oracle Weaver Network Management (3 functions)
//    8. registerOracle(string calldata _name, bytes32 _commitmentHash): Allows an address to register as an Oracle Weaver.
//    9. deregisterOracle(): Allows an Oracle Weaver to deregister themselves.
//    10. updateOracleReputation(address _oracleAddress, int256 _reputationChange): (Admin/Internal) Updates an oracle's reputation score. (Internal, exposed for specific use or via governance)

// VI. Condition Evaluation & Reporting (7 functions)
//    11. requestConditionVerification(bytes32 _vaultId): Initiates the verification process for a vault's primary condition.
//    12. submitOracleReport(bytes32 _requestId, bytes calldata _data, bytes calldata _signature): An Oracle Weaver submits a report for a specific request.
//    13. voteOnOracleReport(bytes32 _requestId, uint256 _reportIndex, bool _isValid): Allows registered oracles to vote on the validity of a submitted report.
//    14. resolveCondition(bytes32 _vaultId): Finalizes the evaluation of a vault's condition based on oracle consensus.
//    15. checkConditionStatus(bytes32 _vaultId) external view returns (VaultStatus, bool primaryMet, bool emergencyMet): Checks the current status and if any condition is met.
//    16. getActiveVerificationRequest(bytes32 _vaultId) external view returns (bytes32, ConditionType, bytes memory, uint256): Retrieves details of an active verification request.
//    17. getOracleReportDetails(bytes32 _requestId, uint256 _reportIndex) external view returns (address oracleAddress, bytes memory data, bytes memory signature, uint256 validVotes, uint256 invalidVotes): Retrieves details of a specific oracle report.

// VII. Digital Persona Agent Management (Simulated AI) (4 functions)
//    18. deployDigitalPersonaAgent(bytes32 _vaultId, address _agentContractAddress, bytes calldata _agentInitData): Links an external "Digital Persona" agent contract to a vault.
//    19. configurePersonaDecisionRules(bytes32 _vaultId, bytes32 _rulesHash, uint256 _ruleType): Configures parameters or rules for the linked Persona Agent.
//    20. triggerPersonaAction(bytes32 _vaultId, bytes calldata _actionData): Initiates an action by the linked Digital Persona Agent if authorized.
//    21. updatePersonaAgentAddress(bytes32 _vaultId, address _newAgentAddress): Updates the address of the linked Persona Agent.

// VIII. Vault Release & Access (2 functions)
//    22. releaseVaultContent(bytes32 _vaultId): Triggers the final release of the vault's contents (or access key).
//    23. getVaultOwner(bytes32 _vaultId) external view returns (address): Returns the owner of a given vault.

// IX. Protocol Governance & Fees (4 functions)
//    24. setProtocolFee(uint256 _newFeePercentage): (Admin) Sets the protocol fee percentage.
//    25. withdrawProtocolFees(address _recipient): (Admin) Allows the admin to withdraw accumulated protocol fees.
//    26. getPooledFundsBalance() external view returns (uint256): Returns the total ETH held by the contract.
//    27. changeAdmin(address _newAdmin): (Admin) Transfers admin privileges to a new address.

// ---------------------------------------------------------------------------------------------------
// I. Interfaces, Data Structures & Constants
// ---------------------------------------------------------------------------------------------------

interface IAgent {
    // Defines an interface for external "Digital Persona" agent contracts.
    // These contracts would contain the logic for AI-like decision making or complex multi-sig.

    // @dev A method for the ChronoVault to request a decision or action from the agent.
    // @param _vaultId The ID of the vault requesting the action.
    // @param _requester The address that initiated the request (e.g., ChronoVault).
    // @param _actionData Arbitrary data passed to the agent for its decision.
    // @return True if the agent approves or successfully executes the action, false otherwise.
    function requestDecision(bytes32 _vaultId, address _requester, bytes calldata _actionData) external returns (bool);
}

contract ChronoVault {

    address public admin;
    uint256 public protocolFeePercentage; // e.g., 100 = 1%, 10000 = 100%
    uint256 public constant MIN_ORACLE_REPUTATION = 100; // Minimum reputation to be an active oracle

    enum VaultStatus {
        LOCKED,                  // Vault is active but conditions not met
        CONDITION_PENDING,       // A condition verification is in progress
        CONDITION_MET,           // Primary condition met, ready for release
        EMERGENCY_MET,           // Emergency condition met, ready for release
        RELEASED,                // Content released
        REVOKED                  // Vault was revoked by owner
    }

    enum ConditionType {
        NONE,                     // No condition set
        TIMESTAMP,                // Release at a specific Unix timestamp
        ORACLE_VERIFIED_EVENT,    // Release upon verification of an external event by Weavers
        EXTERNAL_CONTRACT_TRIGGER,// Release if an external contract calls it (e.g., DAO)
        DIGITAL_PERSONA_CONSENT,  // Release requires consent from a linked Digital Persona agent
        MULTI_SIGNATURE_CONSENT   // Release requires approval from multiple beneficiaries
    }

    struct BeneficiaryAccess {
        uint256 accessLevel; // e.g., 0 = no access, 1 = view only, 2 = request release, 3 = full control (owner only)
        bool hasVoted; // Used for multi-signature consent
    }

    struct Condition {
        ConditionType conditionType;
        bytes parameters;           // Encoded parameters specific to the condition type
        bool isMet;
        bytes32 activeRequestId;    // If ORACLE_VERIFIED_EVENT, ID of the current verification request
    }

    struct Vault {
        address owner;
        bytes32 encryptedDataHash;  // Hash of off-chain encrypted data
        mapping(address => BeneficiaryAccess) beneficiaries;
        address[] beneficiaryAddresses; // To iterate beneficiaries
        Condition primaryCondition;
        Condition emergencyCondition;
        VaultStatus status;
        address personaAgentAddress; // Address of the linked IAgent contract
        uint256 createdTimestamp;
        uint256 totalPooledFees; // Fees collected specifically for this vault (e.g., oracle payouts)
    }

    struct Oracle {
        string name;
        bytes32 commitmentHash; // Unique identifier/commitment for the oracle's identity
        uint256 reputation;     // Reputation score (can be positive/negative)
        bool isRegistered;
    }

    struct OracleReport {
        address oracleAddress;
        bytes data;             // Report data (e.g., event outcome hash)
        bytes signature;        // Oracle's signature on the data
        uint256 validVotes;     // Number of valid votes for this report
        uint256 invalidVotes;   // Number of invalid votes against this report
        mapping(address => bool) hasVoted; // Tracks who voted on this report
    }

    struct Request {
        bytes32 vaultId;
        ConditionType conditionType;
        bytes parameters;
        uint256 submissionDeadline; // When oracles must submit reports by
        uint256 votingDeadline;     // When voting on reports must end
        bool isResolved;
        mapping(uint256 => OracleReport) reports;
        uint256 reportCount;
        uint256 consensusThreshold; // e.g., percentage of reputation needed for consensus
        uint256 creationTimestamp;
        bool isEmergencyRequest;
    }

    // Mappings
    mapping(bytes32 => Vault) public vaults;
    mapping(address => Oracle) public oracles;
    mapping(bytes32 => Request) public requests; // requestId -> Request details

    // ---------------------------------------------------------------------------------------------------
    // II. Events
    // ---------------------------------------------------------------------------------------------------

    event VaultCreated(bytes32 indexed vaultId, address indexed owner, bytes32 encryptedDataHash, address[] beneficiaries);
    event VaultContentHashUpdated(bytes32 indexed vaultId, bytes32 newEncryptedDataHash);
    event BeneficiaryAdded(bytes32 indexed vaultId, address indexed beneficiary, uint256 accessLevel);
    event BeneficiaryRemoved(bytes32 indexed vaultId, address indexed beneficiary);
    event ConditionSet(bytes32 indexed vaultId, ConditionType conditionType, bytes conditionParams, bool isEmergency);
    event VaultReleased(bytes32 indexed vaultId, address indexed recipient);
    event VaultRevoked(bytes32 indexed vaultId, address indexed owner);

    event OracleRegistered(address indexed oracleAddress, string name, bytes32 commitmentHash);
    event OracleDeregistered(address indexed oracleAddress);
    event OracleReputationUpdated(address indexed oracleAddress, int256 change, uint256 newReputation);

    event ConditionVerificationRequested(bytes32 indexed requestId, bytes32 indexed vaultId, ConditionType conditionType, bool isEmergency);
    event OracleReportSubmitted(bytes32 indexed requestId, address indexed oracleAddress, bytes data, bytes signature);
    event OracleReportVoted(bytes32 indexed requestId, uint256 reportIndex, address indexed voter, bool isValid);
    event ConditionResolved(bytes32 indexed vaultId, bytes32 indexed requestId, bool conditionMet, bool isEmergency);

    event PersonaAgentDeployed(bytes32 indexed vaultId, address indexed agentContractAddress);
    event PersonaAgentUpdated(bytes32 indexed vaultId, address indexed oldAddress, address indexed newAddress);
    event PersonaDecisionRulesConfigured(bytes32 indexed vaultId, bytes32 rulesHash, uint256 ruleType);
    event PersonaActionTriggered(bytes32 indexed vaultId, address indexed agentAddress, bytes actionData);

    event ProtocolFeeSet(uint256 oldFee, uint256 newFee);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    // ---------------------------------------------------------------------------------------------------
    // III. Modifiers
    // ---------------------------------------------------------------------------------------------------

    modifier onlyOwner(bytes32 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        _;
    }

    modifier onlyOracle() {
        require(oracles[msg.sender].isRegistered, "Not a registered oracle");
        require(oracles[msg.sender].reputation >= MIN_ORACLE_REPUTATION, "Oracle reputation too low");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // ---------------------------------------------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------------------------------------------

    constructor() {
        admin = msg.sender;
        protocolFeePercentage = 100; // Default 1% fee
    }

    receive() external payable {}
    fallback() external payable {}

    // ---------------------------------------------------------------------------------------------------
    // IV. Core Vault Management (7 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Creates a new time/event-locked digital vault.
     *      A protocol fee is required upon creation.
     * @param _vaultId A unique identifier for the vault.
     * @param _encryptedDataHash A cryptographic hash of the off-chain encrypted data.
     * @param _initialBeneficiaries An array of initial beneficiaries.
     */
    function createChronoVault(
        bytes32 _vaultId,
        bytes32 _encryptedDataHash,
        address[] calldata _initialBeneficiaries
    ) external payable {
        require(vaults[_vaultId].owner == address(0), "Vault ID already exists");
        require(msg.value > 0, "Vault creation requires payment for fees and potential future oracle payouts.");

        uint256 fee = (msg.value * protocolFeePercentage) / 10000; // Calculate fee based on percentage
        require(fee <= msg.value, "Fee calculation error");

        Vault storage newVault = vaults[_vaultId];
        newVault.owner = msg.sender;
        newVault.encryptedDataHash = _encryptedDataHash;
        newVault.status = VaultStatus.LOCKED;
        newVault.createdTimestamp = block.timestamp;
        newVault.totalPooledFees = fee; // Store protocol fee for later withdrawal

        for (uint256 i = 0; i < _initialBeneficiaries.length; i++) {
            require(_initialBeneficiaries[i] != address(0), "Beneficiary cannot be zero address");
            newVault.beneficiaries[_initialBeneficiaries[i]].accessLevel = 1; // Default access level
            newVault.beneficiaryAddresses.push(_initialBeneficiaries[i]);
        }

        emit VaultCreated(_vaultId, msg.sender, _encryptedDataHash, _initialBeneficiaries);
    }

    /**
     * @dev Updates the cryptographic hash of the off-chain encrypted data.
     *      This allows the owner to change the referenced content without altering the vault's conditions.
     * @param _vaultId The ID of the vault.
     * @param _newEncryptedDataHash The new hash of the encrypted data.
     */
    function updateVaultContentHash(bytes32 _vaultId, bytes32 _newEncryptedDataHash) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.LOCKED, "Vault content can only be updated when locked.");
        vault.encryptedDataHash = _newEncryptedDataHash;
        emit VaultContentHashUpdated(_vaultId, _newEncryptedDataHash);
    }

    /**
     * @dev Adds a beneficiary with a specific access level to the vault.
     * @param _vaultId The ID of the vault.
     * @param _newBeneficiary The address of the new beneficiary.
     * @param _accessLevel The access level for the new beneficiary (e.g., 1 for basic access).
     */
    function addBeneficiary(bytes32 _vaultId, address _newBeneficiary, uint256 _accessLevel) external onlyOwner(_vaultId) {
        require(_newBeneficiary != address(0), "Beneficiary cannot be zero address");
        Vault storage vault = vaults[_vaultId];
        require(vault.beneficiaries[_newBeneficiary].accessLevel == 0, "Beneficiary already exists");
        vault.beneficiaries[_newBeneficiary].accessLevel = _accessLevel;
        vault.beneficiaryAddresses.push(_newBeneficiary);
        emit BeneficiaryAdded(_vaultId, _newBeneficiary, _accessLevel);
    }

    /**
     * @dev Removes a beneficiary from the vault.
     * @param _vaultId The ID of the vault.
     * @param _beneficiary The address of the beneficiary to remove.
     */
    function removeBeneficiary(bytes32 _vaultId, address _beneficiary) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.beneficiaries[_beneficiary].accessLevel > 0, "Beneficiary does not exist");
        require(_beneficiary != vault.owner, "Cannot remove owner as beneficiary directly");

        delete vault.beneficiaries[_beneficiary]; // Remove mapping entry

        // Remove from dynamic array (less efficient but necessary for iteration)
        for (uint256 i = 0; i < vault.beneficiaryAddresses.length; i++) {
            if (vault.beneficiaryAddresses[i] == _beneficiary) {
                vault.beneficiaryAddresses[i] = vault.beneficiaryAddresses[vault.beneficiaryAddresses.length - 1];
                vault.beneficiaryAddresses.pop();
                break;
            }
        }
        emit BeneficiaryRemoved(_vaultId, _beneficiary);
    }

    /**
     * @dev Sets the primary release condition for the vault.
     * @param _vaultId The ID of the vault.
     * @param _conditionType The type of condition (e.g., TIMESTAMP, ORACLE_VERIFIED_EVENT).
     * @param _conditionParams Encoded parameters specific to the condition type.
     */
    function setVaultReleaseCondition(
        bytes32 _vaultId,
        ConditionType _conditionType,
        bytes calldata _conditionParams
    ) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.LOCKED, "Vault must be locked to set primary condition.");
        vault.primaryCondition = Condition(_conditionType, _conditionParams, false, 0);
        emit ConditionSet(_vaultId, _conditionType, _conditionParams, false);
    }

    /**
     * @dev Sets an emergency release condition for the vault. This condition can override the primary one.
     * @param _vaultId The ID of the vault.
     * @param _conditionType The type of emergency condition.
     * @param _conditionParams Encoded parameters specific to the condition type.
     */
    function setEmergencyReleaseCondition(
        bytes32 _vaultId,
        ConditionType _conditionType,
        bytes calldata _conditionParams
    ) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.LOCKED, "Vault must be locked to set emergency condition.");
        vault.emergencyCondition = Condition(_conditionType, _conditionParams, false, 0);
        emit ConditionSet(_vaultId, _conditionType, _conditionParams, true);
    }

    /**
     * @dev Allows the owner to revoke and destroy their vault before any conditions are met.
     *      Any remaining Ether in the vault (excluding collected protocol fees) is returned to the owner.
     * @param _vaultId The ID of the vault.
     */
    function revokeVault(bytes32 _vaultId) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.status != VaultStatus.RELEASED, "Vault already released.");
        require(vault.status != VaultStatus.REVOKED, "Vault already revoked.");

        uint256 refundableAmount = address(this).balance - vault.totalPooledFees;
        if (refundableAmount > 0) {
            payable(vault.owner).transfer(refundableAmount);
        }

        vault.status = VaultStatus.REVOKED;
        // Clear sensitive data fields, though mappings are harder to completely erase
        delete vault.encryptedDataHash;
        delete vault.primaryCondition;
        delete vault.emergencyCondition;
        delete vault.personaAgentAddress;
        // Note: Full recursive deletion of mappings within structs is not directly supported
        // However, setting the status to REVOKED effectively invalidates the vault.

        emit VaultRevoked(_vaultId, msg.sender);
    }

    // ---------------------------------------------------------------------------------------------------
    // V. Oracle Weaver Network Management (3 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Allows an address to register as an Oracle Weaver. Requires a unique commitment hash.
     * @param _name The human-readable name of the oracle.
     * @param _commitmentHash A unique cryptographic commitment or identifier for the oracle.
     */
    function registerOracle(string calldata _name, bytes32 _commitmentHash) external {
        require(!oracles[msg.sender].isRegistered, "Already a registered oracle");
        require(bytes(_name).length > 0, "Oracle name cannot be empty");
        // Additional checks for commitmentHash uniqueness could be added

        oracles[msg.sender] = Oracle({
            name: _name,
            commitmentHash: _commitmentHash,
            reputation: MIN_ORACLE_REPUTATION, // Start with minimum reputation
            isRegistered: true
        });
        emit OracleRegistered(msg.sender, _name, _commitmentHash);
    }

    /**
     * @dev Allows an Oracle Weaver to deregister themselves.
     */
    function deregisterOracle() external onlyOracle {
        require(msg.sender != admin, "Admin cannot deregister themselves as oracle via this function.");
        oracles[msg.sender].isRegistered = false;
        // Optionally, reset reputation or transfer any associated stake
        emit OracleDeregistered(msg.sender);
    }

    /**
     * @dev (Internal/Admin) Updates an oracle's reputation score. This could be triggered by governance
     *      or automated systems based on performance.
     * @param _oracleAddress The address of the oracle.
     * @param _reputationChange The amount to change the reputation by (can be negative).
     */
    function _updateOracleReputation(address _oracleAddress, int256 _reputationChange) internal {
        require(oracles[_oracleAddress].isRegistered, "Oracle not registered");

        int256 currentReputation = int256(oracles[_oracleAddress].reputation);
        currentReputation += _reputationChange;
        if (currentReputation < 0) {
            currentReputation = 0; // Reputation cannot go below zero
        }
        oracles[_oracleAddress].reputation = uint256(currentReputation);
        emit OracleReputationUpdated(_oracleAddress, _reputationChange, uint256(currentReputation));
    }

    /**
     * @dev Admin function to update oracle reputation, primarily for testing or emergency.
     * In a full system, this would be part of a DAO or automated system.
     */
    function updateOracleReputation(address _oracleAddress, int256 _reputationChange) external onlyAdmin {
        _updateOracleReputation(_oracleAddress, _reputationChange);
    }

    // ---------------------------------------------------------------------------------------------------
    // VI. Condition Evaluation & Reporting (7 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Initiates the verification process for a vault's primary or emergency condition.
     *      Only the owner or a beneficiary with sufficient access can request verification.
     * @param _vaultId The ID of the vault.
     */
    function requestConditionVerification(bytes32 _vaultId) external {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.LOCKED, "Vault not in LOCKED state to request verification.");

        // Check if caller is owner or beneficiary
        require(msg.sender == vault.owner || vault.beneficiaries[msg.sender].accessLevel >= 2,
                "Caller not authorized to request verification.");

        Condition storage conditionToVerify;
        bool isEmergencyRequest = false;

        // Prioritize emergency condition if set and active
        if (vault.emergencyCondition.conditionType != ConditionType.NONE && !vault.emergencyCondition.isMet) {
            conditionToVerify = vault.emergencyCondition;
            isEmergencyRequest = true;
        } else if (vault.primaryCondition.conditionType != ConditionType.NONE && !vault.primaryCondition.isMet) {
            conditionToVerify = vault.primaryCondition;
        } else {
            revert("No valid conditions to verify or conditions already met.");
        }

        require(conditionToVerify.conditionType == ConditionType.ORACLE_VERIFIED_EVENT, "Condition type not suitable for oracle verification.");
        require(conditionToVerify.activeRequestId == 0, "Verification already in progress for this condition.");

        bytes32 requestId = keccak256(abi.encodePacked(_vaultId, block.timestamp, conditionToVerify.parameters));
        requests[requestId] = Request({
            vaultId: _vaultId,
            conditionType: conditionToVerify.conditionType,
            parameters: conditionToVerify.parameters,
            submissionDeadline: block.timestamp + 1 days, // Oracles have 1 day to submit
            votingDeadline: block.timestamp + 2 days,     // Voting ends 1 day after submission deadline
            isResolved: false,
            reportCount: 0,
            consensusThreshold: 5000, // 50% of total oracle reputation
            creationTimestamp: block.timestamp,
            isEmergencyRequest: isEmergencyRequest
        });

        // Link the request to the condition
        if (isEmergencyRequest) {
            vault.emergencyCondition.activeRequestId = requestId;
        } else {
            vault.primaryCondition.activeRequestId = requestId;
        }
        vault.status = VaultStatus.CONDITION_PENDING;

        emit ConditionVerificationRequested(requestId, _vaultId, conditionToVerify.conditionType, isEmergencyRequest);
    }

    /**
     * @dev An Oracle Weaver submits a report for a specific request.
     * @param _requestId The ID of the verification request.
     * @param _data The actual verified data (e.g., hash of an event outcome, numerical value).
     * @param _signature The oracle's signature on the _data.
     */
    function submitOracleReport(
        bytes32 _requestId,
        bytes calldata _data,
        bytes calldata _signature
    ) external onlyOracle {
        Request storage req = requests[_requestId];
        require(req.vaultId != 0, "Request does not exist.");
        require(block.timestamp <= req.submissionDeadline, "Report submission deadline passed.");
        require(req.reports[req.reportCount].oracleAddress != msg.sender, "Oracle already submitted a report for this request.");

        req.reports[req.reportCount] = OracleReport({
            oracleAddress: msg.sender,
            data: _data,
            signature: _signature,
            validVotes: 0,
            invalidVotes: 0,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping
        });
        req.reportCount++;
        emit OracleReportSubmitted(_requestId, msg.sender, _data, _signature);
    }

    /**
     * @dev Allows registered oracles to vote on the validity of a submitted report.
     * @param _requestId The ID of the verification request.
     * @param _reportIndex The index of the report in the request's reports array.
     * @param _isValid True if the report is deemed valid, false otherwise.
     */
    function voteOnOracleReport(bytes32 _requestId, uint256 _reportIndex, bool _isValid) external onlyOracle {
        Request storage req = requests[_requestId];
        require(req.vaultId != 0, "Request does not exist.");
        require(block.timestamp <= req.votingDeadline, "Voting deadline passed.");
        require(_reportIndex < req.reportCount, "Report index out of bounds.");

        OracleReport storage report = req.reports[_reportIndex];
        require(!report.hasVoted[msg.sender], "Oracle already voted on this report.");
        require(report.oracleAddress != msg.sender, "Oracle cannot vote on their own report.");

        report.hasVoted[msg.sender] = true;
        if (_isValid) {
            report.validVotes += oracles[msg.sender].reputation;
            _updateOracleReputation(msg.sender, 1); // Reward for valid vote
        } else {
            report.invalidVotes += oracles[msg.sender].reputation;
            _updateOracleReputation(msg.sender, -1); // Penalize for invalid vote
        }
        emit OracleReportVoted(_requestId, _reportIndex, msg.sender, _isValid);
    }

    /**
     * @dev Finalizes the evaluation of a vault's condition based on oracle consensus.
     *      Can be called by anyone after the voting deadline.
     * @param _vaultId The ID of the vault.
     */
    function resolveCondition(bytes32 _vaultId) external {
        Vault storage vault = vaults[_vaultId];
        require(vault.status == VaultStatus.CONDITION_PENDING, "Vault is not in pending state.");

        Condition storage primaryCond = vault.primaryCondition;
        Condition storage emergencyCond = vault.emergencyCondition;

        // Determine which condition we are trying to resolve
        bytes32 requestId;
        bool isEmergencyResolution = false;

        if (emergencyCond.activeRequestId != 0 && !emergencyCond.isMet) {
            requestId = emergencyCond.activeRequestId;
            isEmergencyResolution = true;
        } else if (primaryCond.activeRequestId != 0 && !primaryCond.isMet) {
            requestId = primaryCond.activeRequestId;
        } else {
            revert("No active oracle verification request for this vault.");
        }

        Request storage req = requests[requestId];
        require(req.vaultId != 0, "Request does not exist.");
        require(!req.isResolved, "Request already resolved.");
        require(block.timestamp > req.votingDeadline, "Voting period has not ended yet.");

        // Calculate total reputation for consensus
        uint256 totalOracleReputation = 0;
        for(uint i = 0; i < req.reportCount; i++) {
            totalOracleReputation += oracles[req.reports[i].oracleAddress].reputation;
        }
        
        bool conditionMet = false;
        bytes32 winningReportDataHash = 0; // To identify the consensus data if any

        if (req.reportCount > 0 && totalOracleReputation > 0) {
            // Simple majority based on reputation
            uint256 maxValidVotes = 0;
            uint256 totalValidReputation = 0;
            bytes32 bestReportHash = 0;

            for (uint256 i = 0; i < req.reportCount; i++) {
                OracleReport storage report = req.reports[i];
                if (report.validVotes > maxValidVotes) {
                    maxValidVotes = report.validVotes;
                    bestReportHash = keccak256(report.data);
                }
                totalValidReputation += report.validVotes;
            }

            // A condition is met if the winning report has significant support and a clear majority
            // (e.g., > 50% of total valid reputation votes, and higher than any other report)
            // A more complex algorithm could consider stake, unique reports, etc.
            if (maxValidVotes > (totalValidReputation * req.consensusThreshold) / 10000 && bestReportHash != 0) {
                conditionMet = true;
                winningReportDataHash = bestReportHash; // The hash of the data that reached consensus
            }
        }

        if (isEmergencyResolution) {
            emergencyCond.isMet = conditionMet;
            emergencyCond.activeRequestId = 0; // Clear active request
            if (conditionMet) {
                vault.status = VaultStatus.EMERGENCY_MET;
            } else {
                vault.status = VaultStatus.LOCKED; // Go back to locked if emergency fails
            }
        } else {
            primaryCond.isMet = conditionMet;
            primaryCond.activeRequestId = 0; // Clear active request
            if (conditionMet) {
                vault.status = VaultStatus.CONDITION_MET;
            } else {
                vault.status = VaultStatus.LOCKED; // Go back to locked if primary fails
            }
        }
        
        req.isResolved = true; // Mark request as resolved

        emit ConditionResolved(_vaultId, requestId, conditionMet, isEmergencyResolution);
    }

    /**
     * @dev Checks the current status of a vault and if any condition (primary or emergency) is met.
     * @param _vaultId The ID of the vault.
     * @return status The current VaultStatus.
     * @return primaryMet True if the primary condition is met.
     * @return emergencyMet True if the emergency condition is met.
     */
    function checkConditionStatus(bytes32 _vaultId)
        external
        view
        returns (VaultStatus status, bool primaryMet, bool emergencyMet)
    {
        Vault storage vault = vaults[_vaultId];
        return (vault.status, vault.primaryCondition.isMet, vault.emergencyCondition.isMet);
    }

    /**
     * @dev Retrieves details of an active verification request for a vault.
     * @param _vaultId The ID of the vault.
     * @return requestId The ID of the active request.
     * @return conditionType The type of condition being verified.
     * @return parameters The parameters of the condition.
     * @return creationTimestamp The timestamp when the request was created.
     */
    function getActiveVerificationRequest(bytes32 _vaultId)
        external
        view
        returns (bytes32 requestId, ConditionType conditionType, bytes memory parameters, uint256 creationTimestamp)
    {
        Vault storage vault = vaults[_vaultId];
        bytes32 activeReqId = 0;
        if (vault.emergencyCondition.activeRequestId != 0) {
            activeReqId = vault.emergencyCondition.activeRequestId;
        } else if (vault.primaryCondition.activeRequestId != 0) {
            activeReqId = vault.primaryCondition.activeRequestId;
        }

        if (activeReqId != 0) {
            Request storage req = requests[activeReqId];
            return (activeReqId, req.conditionType, req.parameters, req.creationTimestamp);
        }
        return (0, ConditionType.NONE, "", 0);
    }

    /**
     * @dev Retrieves details of a specific oracle report within a verification request.
     * @param _requestId The ID of the verification request.
     * @param _reportIndex The index of the report.
     * @return oracleAddress The address of the oracle who submitted the report.
     * @return data The data reported by the oracle.
     * @return signature The signature provided by the oracle.
     * @return validVotes The total reputation of oracles who voted this report as valid.
     * @return invalidVotes The total reputation of oracles who voted this report as invalid.
     */
    function getOracleReportDetails(bytes32 _requestId, uint256 _reportIndex)
        external
        view
        returns (address oracleAddress, bytes memory data, bytes memory signature, uint256 validVotes, uint256 invalidVotes)
    {
        Request storage req = requests[_requestId];
        require(req.vaultId != 0, "Request does not exist.");
        require(_reportIndex < req.reportCount, "Report index out of bounds.");
        OracleReport storage report = req.reports[_reportIndex];
        return (report.oracleAddress, report.data, report.signature, report.validVotes, report.invalidVotes);
    }


    // ---------------------------------------------------------------------------------------------------
    // VII. Digital Persona Agent Management (Simulated AI) (4 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Links an external "Digital Persona" agent contract to a vault.
     *      This agent can provide consent or make decisions under specific conditions.
     * @param _vaultId The ID of the vault.
     * @param _agentContractAddress The address of the IAgent compliant contract.
     * @param _agentInitData Initial data for the agent (e.g., configuration, setup).
     */
    function deployDigitalPersonaAgent(
        bytes32 _vaultId,
        address _agentContractAddress,
        bytes calldata _agentInitData
    ) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.personaAgentAddress == address(0), "Digital Persona agent already deployed for this vault.");
        require(_agentContractAddress != address(0), "Agent address cannot be zero.");

        vault.personaAgentAddress = _agentContractAddress;
        // Optionally, call an init function on the agent contract with _agentInitData
        // IAgent(_agentContractAddress).initialize(_agentInitData); (requires IAgent init method)

        emit PersonaAgentDeployed(_vaultId, _agentContractAddress);
    }

    /**
     * @dev Configures parameters or rules for the linked Digital Persona Agent.
     *      The specific `_rulesHash` and `_ruleType` depend on the external agent's logic.
     * @param _vaultId The ID of the vault.
     * @param _rulesHash A hash representing the set of rules or configuration for the persona.
     * @param _ruleType A type identifier for the rules being configured.
     */
    function configurePersonaDecisionRules(
        bytes32 _vaultId,
        bytes32 _rulesHash,
        uint256 _ruleType
    ) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.personaAgentAddress != address(0), "No Digital Persona agent linked to this vault.");
        // This function doesn't interact with the agent directly, but records the configuration intent on-chain.
        // The agent itself would need its own methods for rule configuration.
        // This primarily serves as an on-chain record for a linked agent's configuration.
        emit PersonaDecisionRulesConfigured(_vaultId, _rulesHash, _ruleType);
    }

    /**
     * @dev Initiates an action by the linked Digital Persona Agent.
     *      This function would be called if a condition specifies `DIGITAL_PERSONA_CONSENT`.
     * @param _vaultId The ID of the vault.
     * @param _actionData Arbitrary data to be passed to the agent for its decision/action.
     */
    function triggerPersonaAction(bytes32 _vaultId, bytes calldata _actionData) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.personaAgentAddress != address(0), "No Digital Persona agent linked to this vault.");
        
        bool primaryConditionRequiresPersona = (vault.primaryCondition.conditionType == ConditionType.DIGITAL_PERSONA_CONSENT);
        bool emergencyConditionRequiresPersona = (vault.emergencyCondition.conditionType == ConditionType.DIGITAL_PERSONA_CONSENT);

        require(primaryConditionRequiresPersona || emergencyConditionRequiresPersona, "Vault conditions do not require Persona consent.");
        
        // Ensure either the primary or emergency condition (that involves persona consent) is active
        // and has not yet been met.
        require((primaryConditionRequiresPersona && !vault.primaryCondition.isMet) ||
                (emergencyConditionRequiresPersona && !vault.emergencyCondition.isMet),
                "Persona consent already given or not required at this time for an active condition.");

        bool decision = IAgent(vault.personaAgentAddress).requestDecision(_vaultId, address(this), _actionData);
        
        if (decision) {
            if (primaryConditionRequiresPersona && !vault.primaryCondition.isMet) {
                vault.primaryCondition.isMet = true;
                vault.status = VaultStatus.CONDITION_MET;
            } else if (emergencyConditionRequiresPersona && !vault.emergencyCondition.isMet) {
                vault.emergencyCondition.isMet = true;
                vault.status = VaultStatus.EMERGENCY_MET;
            }
        }
        emit PersonaActionTriggered(_vaultId, vault.personaAgentAddress, _actionData);
    }

    /**
     * @dev Updates the address of the linked Digital Persona Agent for a vault.
     * @param _vaultId The ID of the vault.
     * @param _newAgentAddress The new address of the IAgent compliant contract.
     */
    function updatePersonaAgentAddress(bytes32 _vaultId, address _newAgentAddress) external onlyOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        require(vault.personaAgentAddress != address(0), "No Digital Persona agent linked to this vault to update.");
        require(_newAgentAddress != address(0), "New agent address cannot be zero.");

        address oldAgentAddress = vault.personaAgentAddress;
        vault.personaAgentAddress = _newAgentAddress;
        emit PersonaAgentUpdated(_vaultId, oldAgentAddress, _newAgentAddress);
    }

    // ---------------------------------------------------------------------------------------------------
    // VIII. Vault Release & Access (2 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Triggers the final release of the vault's contents (or rather, the access key to the content).
     *      This can be called by the owner or any authorized beneficiary once conditions are met.
     * @param _vaultId The ID of the vault.
     */
    function releaseVaultContent(bytes32 _vaultId) external {
        Vault storage vault = vaults[_vaultId];
        require(vault.owner != address(0), "Vault does not exist.");
        require(vault.status != VaultStatus.RELEASED, "Vault already released.");
        require(vault.status != VaultStatus.REVOKED, "Vault has been revoked.");

        require(msg.sender == vault.owner || vault.beneficiaries[msg.sender].accessLevel >= 2,
                "Caller not authorized to release vault.");

        bool primaryConditionMet = _checkCondition(vault.primaryCondition);
        bool emergencyConditionMet = _checkCondition(vault.emergencyCondition);
        
        require(primaryConditionMet || emergencyConditionMet, "Vault release conditions not yet met.");
        
        vault.status = VaultStatus.RELEASED;

        // In a real-world scenario, the `encryptedDataHash` would now be revealed,
        // or a decryption key would be transferred to the recipient,
        // or an off-chain service would be notified to release the data.
        // For this contract, simply marking as RELEASED and emitting event suffices.

        emit VaultReleased(_vaultId, msg.sender);
    }

    /**
     * @dev Internal helper function to check if a specific condition is met.
     * @param _condition The condition struct to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(Condition storage _condition) internal view returns (bool) {
        if (_condition.isMet) {
            return true; // Already flagged as met (e.g., by persona or oracle)
        }

        if (_condition.conditionType == ConditionType.TIMESTAMP) {
            uint256 targetTimestamp = abi.decode(_condition.parameters, (uint256));
            return block.timestamp >= targetTimestamp;
        }

        // For ORACLE_VERIFIED_EVENT, it relies on resolveCondition setting isMet = true.
        // For DIGITAL_PERSONA_CONSENT, it relies on triggerPersonaAction setting isMet = true.

        if (_condition.conditionType == ConditionType.MULTI_SIGNATURE_CONSENT) {
             // Example: requires 2 out of N beneficiaries to call a specific vote function.
             // This would need a separate function for beneficiaries to "vote" on release,
             // which then updates `isMet` if a threshold is reached.
             // For simplicity here, we assume `isMet` gets updated by another mechanism.
             // A proper implementation would involve counting votes on-chain.
             // Example: bytes can contain minRequiredSignatures, and `isMet` is set by a tally function.
            return _condition.isMet; // Rely on external tally for simplicity in this example
        }
        
        // If external contract trigger, the external contract would call a specific function
        // on ChronoVault (e.g., `_signalExternalTrigger`) which then sets `isMet`.
        if (_condition.conditionType == ConditionType.EXTERNAL_CONTRACT_TRIGGER) {
             return _condition.isMet;
        }

        return false;
    }

    /**
     * @dev Allows an external contract (if authorized) to signal a trigger for a vault condition.
     * @param _vaultId The ID of the vault.
     * @param _isEmergency True if signaling for the emergency condition, false for primary.
     */
    function _signalExternalTrigger(bytes32 _vaultId, bool _isEmergency) external {
        Vault storage vault = vaults[_vaultId];
        Condition storage condition = _isEmergency ? vault.emergencyCondition : vault.primaryCondition;
        require(condition.conditionType == ConditionType.EXTERNAL_CONTRACT_TRIGGER, "Condition type is not external trigger.");

        // Additional checks: `msg.sender` must be one of the allowed external trigger addresses
        // encoded in `condition.parameters`.
        address[] memory authorizedTriggers = abi.decode(condition.parameters, (address[]));
        bool isAuthorized = false;
        for (uint i = 0; i < authorizedTriggers.length; i++) {
            if (authorizedTriggers[i] == msg.sender) {
                isAuthorized = true;
                break;
            }
        }
        require(isAuthorized, "Caller not authorized to trigger this condition.");

        condition.isMet = true;
        if (_isEmergency) {
            vault.status = VaultStatus.EMERGENCY_MET;
        } else {
            vault.status = VaultStatus.CONDITION_MET;
        }
        emit ConditionResolved(_vaultId, 0, true, _isEmergency); // RequestId 0 for external trigger
    }


    /**
     * @dev Returns the owner of a given vault.
     * @param _vaultId The ID of the vault.
     * @return The address of the vault owner.
     */
    function getVaultOwner(bytes32 _vaultId) external view returns (address) {
        return vaults[_vaultId].owner;
    }

    // ---------------------------------------------------------------------------------------------------
    // IX. Protocol Governance & Fees (4 functions)
    // ---------------------------------------------------------------------------------------------------

    /**
     * @dev Sets the protocol fee percentage. Only callable by the admin.
     * @param _newFeePercentage The new fee percentage (e.g., 100 for 1%, 50 for 0.5%). Max 10000 (100%).
     */
    function setProtocolFee(uint256 _newFeePercentage) external onlyAdmin {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100%");
        emit ProtocolFeeSet(protocolFeePercentage, _newFeePercentage);
        protocolFeePercentage = _newFeePercentage;
    }

    /**
     * @dev Allows the admin to withdraw accumulated protocol fees.
     * @param _recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address _recipient) external onlyAdmin {
        require(_recipient != address(0), "Recipient cannot be zero address.");
        uint256 totalFees = 0;
        // Sum up all `totalPooledFees` from active vaults that are past their initial fee collection.
        // For simplicity here, we assume `totalPooledFees` in vaults are dynamic,
        // but in reality, fees are typically pulled directly to the contract balance.
        // Let's assume fees are accumulated directly in the contract's balance initially.
        // If we want vault-specific pooled fees, they'd need to be transferred to admin.

        // For simplicity, this function will transfer the entire contract balance (minus any vault funds explicitly held for oracle payouts, which is not implemented in detail).
        // A more robust system would track fees separately.
        uint256 withdrawableAmount = address(this).balance; // simplified
        
        // This is a simplification; in a real system, the exact amount of "protocol fees"
        // accumulated would be tracked explicitly in a `totalProtocolFees` variable,
        // and vault creations would transfer `fee` directly to that.
        // For now, let's just withdraw the entire balance to represent fees.
        // If the contract holds funds for oracle payouts, it needs a way to separate them.
        
        payable(_recipient).transfer(withdrawableAmount);
        emit ProtocolFeesWithdrawn(_recipient, withdrawableAmount);
    }

    /**
     * @dev Returns the total Ether held by the contract. This includes fees and any funds sent to vaults.
     * @return The total ETH balance.
     */
    function getPooledFundsBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfers admin privileges to a new address. Only callable by the current admin.
     * @param _newAdmin The address of the new administrator.
     */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be the zero address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }
}
```