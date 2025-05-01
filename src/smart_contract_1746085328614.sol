Okay, this is a challenging and fun request! Creating something truly *unique* in Solidity is hard given the open-source landscape, but we can combine advanced concepts in a novel way.

Let's build a "Quantum Vault" smart contract. The core idea is a secure vault that holds various assets (ETH, ERC20, ERC721) which can *only* be unlocked and withdrawn when a complex, multi-part "Quantum Condition" is met. These conditions can combine elements like time, external data (via authorized oracles), possession of specific NFTs, and approval from designated "Guardians". The "Quantum" aspect comes from the potential complexity and dependence on multiple external and internal factors lining up simultaneously or sequentially.

It's overly complex for most real-world uses but demonstrates advanced concepts like flexible condition evaluation, role-based access beyond owner, oracle integration patterns, and interaction with other token standards.

**Disclaimer:** This contract is designed for educational and creative purposes to showcase advanced concepts. It is *complex* and *not audited*. Deploying such a contract in a production environment without rigorous security audits and testing is highly risky.

---

## Smart Contract: QuantumVault

**Concept:** A multi-asset vault where withdrawals are gated by complex, multi-part "Quantum Conditions" defined by authorized parties. These conditions can involve time locks, oracle data, NFT ownership, and guardian approvals.

**Advanced Concepts Demonstrated:**
*   Complex, dynamic condition evaluation.
*   Role-based access control (`Ownable`, `EmergencyOwnable`, `ConditionManager`, `Oracle`, `Guardian`).
*   External data integration pattern (simulated Oracle).
*   Interaction with ERC20 and ERC721 standards.
*   Modular condition definition.
*   Emergency override mechanisms.

**Outline:**

1.  **State Variables:**
    *   Ownership (`owner`, `emergencyOwner`)
    *   Role Mappings (`isConditionManager`, `isOracle`, `isGuardian`)
    *   Deposit Tracking (`deposits`, `depositIdCounter`, `depositsByDepositor`)
    *   Condition Definition (`conditions`, `conditionIdCounter`)
    *   Condition Component State (`oracleData`, `guardianVoteCounts`, `guardianVotes`, `internalCounter`, `internalFlag`)
2.  **Structs:**
    *   `Deposit`: Details of an asset deposit.
    *   `Condition`: Defines the requirements for unlocking associated deposits.
3.  **Events:**
    *   Notifications for key actions (Deposit, Withdraw, Condition Definition, Role Changes, Oracle Data, Guardian Vote, etc.)
4.  **Modifiers:**
    *   Access control checks (`onlyOwner`, `onlyEmergencyOwner`, `onlyConditionManager`, `onlyOracle`, `onlyGuardian`, `whenConditionMet`)
5.  **Internal Helper Function:**
    *   `_checkCondition`: Evaluates if a given condition ID is currently met.
6.  **Functions:**
    *   **Core Ownership/Roles (7 functions):** Constructor, Set Emergency Owner, Transfer Ownership, Renounce Ownership, Add/Remove Condition Manager, Add/Remove Oracle, Add/Remove Guardian.
    *   **Deposit (3 functions):** Deposit ETH, Deposit ERC20, Deposit ERC721. (Requires pre-linking to a condition or linking later).
    *   **Condition Management (6 functions):** Define Condition, Link Deposit to Condition, Update Condition (carefully), Define Specific Condition Requirements (Time, Oracle, NFT, Guardian, Internal).
    *   **External/Internal State Update (4 functions):** Submit Oracle Data, Guardian Vote, Increment Internal Counter, Set Internal Flag.
    *   **Withdrawal (3 functions):** Withdraw ETH, Withdraw ERC20, Withdraw ERC721 (all gated by `_checkCondition`).
    *   **Emergency Withdrawal (3 functions):** Emergency withdraw ETH, ERC20, ERC721 (bypass conditions).
    *   **Query/View (>= 10 functions):** Get Deposit Details, Get Condition Details, Get User Deposit IDs, Check Condition Status for Deposit, Get Oracle Data, Get Guardian Vote Count, Has Guardian Voted, Get Internal Counter, Get Internal Flag, Is Address a Role (Manager, Oracle, Guardian).

**Total Functions (Target: >= 20):** Summing the breakdown above: 7 + 3 + 6 + 4 + 3 + 3 + 10 = 36 functions. Well over the minimum.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title QuantumVault
 * @notice A multi-asset vault with withdrawals gated by complex, multi-part Quantum Conditions.
 * @dev Conditions can combine time locks, oracle data, NFT ownership, and guardian approvals.
 *      This contract is highly complex and meant for demonstration. Not audited.
 */
contract QuantumVault is ERC721Holder { // Inherit ERC721Holder to accept safeTransferFrom
    using SafeERC20 for IERC20;
    using Address for address;

    address public owner;
    address public emergencyOwner; // Can bypass conditions in emergency

    // --- Role Management ---
    mapping(address => bool) public isConditionManager; // Can define/update conditions
    mapping(address => bool) public isOracle;           // Can submit specific oracle data
    mapping(address => bool) public isGuardian;         // Can approve guardian-gated conditions

    // --- Deposit Tracking ---
    struct Deposit {
        uint256 id;
        address depositor;
        address tokenAddress; // Address(0) for Ether
        uint256 tokenId;      // Relevant for ERC721, 0 for Ether/ERC20
        uint256 amount;       // Relevant for Ether/ERC20, 0 for ERC721
        uint256 conditionId;  // ID of the condition required for withdrawal
        uint256 depositTime;
    }

    uint256 private depositIdCounter;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) public depositsByDepositor; // Track deposit IDs per user

    // --- Condition Definition ---
    struct Condition {
        uint256 id;
        bool isActive;
        string description; // Human-readable description

        // --- Condition Components ---
        bool requiresTimestamp;
        uint256 requiredTimestamp; // Unlock time

        bool requiresOracleData;
        string requiredOracleKey; // Key for oracle data lookup
        uint256 requiredOracleValue; // Target value from oracle

        bool requiresNFT;
        address requiredNFTContract;
        uint256 requiredNFTTokenId;

        bool requiresGuardianApproval;
        uint256 requiredGuardianVotes; // Number of unique guardians required

        bool requiresInternalCounter;
        uint256 requiredInternalCounterValue; // Value of internal counter needed

        bool requiresInternalFlag;
        bool requiredInternalFlagState; // State of internal boolean flag needed
    }

    uint256 private conditionIdCounter;
    mapping(uint256 => Condition) public conditions;

    // --- Condition Component State ---
    mapping(string => uint256) public oracleData; // Stores latest oracle data by key
    mapping(uint256 => mapping(address => bool)) private guardianVotes; // conditionId => guardianAddress => hasVoted
    mapping(uint256 => uint256) public guardianVoteCounts;             // conditionId => currentVoteCount

    uint256 public internalCounter = 0; // General-purpose counter for conditions
    bool public internalFlag = false;  // General-purpose flag for conditions

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EmergencyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ConditionManagerRoleGranted(address indexed account);
    event ConditionManagerRoleRevoked(address indexed account);
    event OracleRoleGranted(address indexed account);
    event OracleRoleRevoked(address indexed account);
    event GuardianRoleGranted(address indexed account);
    event GuardianRoleRevoked(address indexed account);

    event ETHDeposited(uint256 indexed depositId, address indexed depositor, uint256 amount, uint256 indexed conditionId);
    event ERC20Deposited(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 amount, uint256 indexed conditionId);
    event ERC721Deposited(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 indexed tokenId, uint256 indexed conditionId);
    event DepositLinkedToCondition(uint256 indexed depositId, uint256 indexed conditionId);

    event ConditionDefined(uint256 indexed conditionId, string description);
    event ConditionUpdated(uint256 indexed conditionId);
    event ConditionRequirementUpdated(uint256 indexed conditionId, string requirementType);

    event OracleDataSubmitted(string indexed oracleKey, uint256 value);
    event GuardianVoted(uint256 indexed conditionId, address indexed guardian);
    event InternalCounterIncremented(uint256 newValue);
    event InternalFlagSet(bool newState);

    event ETHWithdrawn(uint256 indexed depositId, address indexed recipient, uint256 amount, uint256 indexed conditionId);
    event ERC20Withdrawn(uint256 indexed depositId, address indexed recipient, address indexed token, uint256 amount, uint256 indexed conditionId);
    event ERC721Withdrawn(uint256 indexed depositId, address indexed recipient, address indexed token, uint256 indexed tokenId, uint256 indexed conditionId);

    event EmergencyETHWithdrawn(uint256 indexed depositId, address indexed recipient, uint256 amount);
    event EmergencyERC20Withdrawn(uint256 indexed depositId, address indexed recipient, address indexed token, uint256 amount);
    event EmergencyERC721Withdrawn(uint256 indexed depositId, address indexed recipient, address indexed token, uint256 indexed tokenId);

    constructor() {
        owner = msg.sender;
        emergencyOwner = msg.sender; // Owner is emergency owner by default
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    modifier onlyEmergencyOwner() {
        require(msg.sender == emergencyOwner, "Only emergency owner can call");
        _;
    }

    modifier onlyConditionManager() {
        require(isConditionManager[msg.sender] || msg.sender == owner, "Only condition manager or owner can call");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender] || msg.sender == owner, "Only oracle or owner can call");
        _;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender] || msg.sender == owner, "Only guardian or owner can call");
        _;
    }

    /**
     * @dev Internal helper to check if a given condition is met.
     * @param _conditionId The ID of the condition to check.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkCondition(uint256 _conditionId) internal view returns (bool) {
        Condition storage condition = conditions[_conditionId];
        if (!condition.isActive) {
            // If condition is not active, it cannot be met UNLESS it's condition 0 (unconditional)
            return _conditionId == 0;
        }

        bool met = true; // Assume met, then check requirements

        if (condition.requiresTimestamp) {
            met = met && block.timestamp >= condition.requiredTimestamp;
        }
        if (condition.requiresOracleData) {
            met = met && oracleData[condition.requiredOracleKey] == condition.requiredOracleValue;
        }
        // Note: NFT check must be done by the user on *their* address, not the contract's address.
        // The condition *definition* requires an NFT. The user proving they meet the condition
        // implies they currently hold it. The withdrawal function will verify *the caller's* ownership.
        // So, this check is *skipped* here and done in the withdrawal function.
        // if (condition.requiresNFT) { ... check happens later }
        if (condition.requiresGuardianApproval) {
             // Check if the current number of votes meets the requirement
            met = met && guardianVoteCounts[_conditionId] >= condition.requiredGuardianVotes;
        }
        if (condition.requiresInternalCounter) {
            met = met && internalCounter >= condition.requiredInternalCounterValue;
        }
         if (condition.requiresInternalFlag) {
            met = met && internalFlag == condition.requiredInternalFlagState;
        }

        return met;
    }

    // --- 1. Core Ownership & Roles (7 functions) ---

    /**
     * @notice Allows the current owner to set a new emergency owner.
     * @param _emergencyOwner The address of the new emergency owner.
     */
    function setEmergencyOwner(address _emergencyOwner) external onlyOwner {
        require(_emergencyOwner != address(0), "New emergency owner is the zero address");
        address oldEmergencyOwner = emergencyOwner;
        emergencyOwner = _emergencyOwner;
        emit EmergencyOwnershipTransferred(oldEmergencyOwner, _emergencyOwner);
    }

     /**
     * @notice Allows the current owner to transfer ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @notice Allows the owner to renounce their ownership. This is irreversible.
     */
    function renounceOwnership() external onlyOwner {
        address oldOwner = owner;
        owner = address(0); // Renounce ownership
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /**
     * @notice Grants the ConditionManager role to an address.
     * @param _account The address to grant the role to.
     */
    function addConditionManager(address _account) external onlyOwner {
        require(_account != address(0), "Account is the zero address");
        isConditionManager[_account] = true;
        emit ConditionManagerRoleGranted(_account);
    }

    /**
     * @notice Revokes the ConditionManager role from an address.
     * @param _account The address to revoke the role from.
     */
    function removeConditionManager(address _account) external onlyOwner {
        isConditionManager[_account] = false;
        emit ConditionManagerRoleRevoked(_account);
    }

    /**
     * @notice Grants the Oracle role to an address.
     * @param _account The address to grant the role to.
     */
    function addOracle(address _account) external onlyOwner {
        require(_account != address(0), "Account is the zero address");
        isOracle[_account] = true;
        emit OracleRoleGranted(_account);
    }

    /**
     * @notice Revokes the Oracle role from an address.
     * @param _account The address to revoke the role from.
     */
    function removeOracle(address _account) external onlyOwner {
        isOracle[_account] = false;
        emit OracleRoleRevoked(_account);
    }

    /**
     * @notice Grants the Guardian role to an address.
     * @param _account The address to grant the role to.
     */
    function addGuardian(address _account) external onlyOwner {
        require(_account != address(0), "Account is the zero address");
        isGuardian[_account] = true;
        emit GuardianRoleGranted(_account);
    }

    /**
     * @notice Revokes the Guardian role from an address.
     * @param _account The address to revoke the role from.
     */
    function removeGuardian(address _account) external onlyOwner {
        isGuardian[_account] = false;
        emit GuardianRoleRevoked(_account);
    }

    // --- 2. Deposit Functions (3 functions) ---

    /**
     * @notice Deposits Ether into the vault, optionally linking it to a condition.
     * @param _conditionId The ID of the condition required for withdrawal (0 for unconditional).
     */
    function depositETH(uint256 _conditionId) external payable {
        require(msg.value > 0, "Must deposit non-zero Ether");
        require(conditions[_conditionId].isActive || _conditionId == 0, "Condition must be active or 0");

        uint256 newDepositId = ++depositIdCounter;
        deposits[newDepositId] = Deposit({
            id: newDepositId,
            depositor: msg.sender,
            tokenAddress: address(0), // Indicate Ether
            tokenId: 0,
            amount: msg.value,
            conditionId: _conditionId,
            depositTime: block.timestamp
        });
        depositsByDepositor[msg.sender].push(newDepositId);

        emit ETHDeposited(newDepositId, msg.sender, msg.value, _conditionId);
    }

    /**
     * @notice Deposits ERC20 tokens into the vault, optionally linking to a condition.
     * @dev Requires the sender to approve this contract beforehand.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _conditionId The ID of the condition required for withdrawal (0 for unconditional).
     */
    function depositERC20(address _tokenAddress, uint256 _amount, uint256 _conditionId) external {
        require(_amount > 0, "Must deposit non-zero amount");
        require(_tokenAddress != address(0), "Token address is the zero address");
        require(conditions[_conditionId].isActive || _conditionId == 0, "Condition must be active or 0");

        IERC20 token = IERC20(_tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 newDepositId = ++depositIdCounter;
        deposits[newDepositId] = Deposit({
            id: newDepositId,
            depositor: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: 0,
            amount: _amount,
            conditionId: _conditionId,
            depositTime: block.timestamp
        });
        depositsByDepositor[msg.sender].push(newDepositId);

        emit ERC20Deposited(newDepositId, msg.sender, _tokenAddress, _amount, _conditionId);
    }

    /**
     * @notice Deposits an ERC721 token into the vault, optionally linking to a condition.
     * @dev Requires the sender to approve this contract or use `safeTransferFrom`.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _tokenId The ID of the ERC721 token.
     * @param _conditionId The ID of the condition required for withdrawal (0 for unconditional).
     */
    function depositERC721(address _tokenAddress, uint256 _tokenId, uint256 _conditionId) external {
        require(_tokenAddress != address(0), "Token address is the zero address");
        require(conditions[_conditionId].isActive || _conditionId == 0, "Condition must be active or 0");

        IERC721 token = IERC721(_tokenAddress);
        // Check ownership before attempting transferFrom
        require(token.ownerOf(_tokenId) == msg.sender, "Sender is not the owner of the NFT");
        token.safeTransferFrom(msg.sender, address(this), _tokenId); // ERC721Holder handles onERC721Received

        uint256 newDepositId = ++depositIdCounter;
        deposits[newDepositId] = Deposit({
            id: newDepositId,
            depositor: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: 0,
            conditionId: _conditionId,
            depositTime: block.timestamp
        });
        depositsByDepositor[msg.sender].push(newDepositId);

        emit ERC721Deposited(newDepositId, msg.sender, _tokenAddress, _tokenId, _conditionId);
    }

    // --- 3. Condition Management (6 functions) ---

    /**
     * @notice Defines a new withdrawal condition. Only owner or condition manager can call.
     * @param _description A human-readable description of the condition.
     * @return uint256 The ID of the newly created condition.
     */
    function defineCondition(string memory _description) external onlyConditionManager returns (uint256) {
        uint256 newConditionId = ++conditionIdCounter;
        conditions[newConditionId] = Condition({
            id: newConditionId,
            isActive: true, // Conditions are active by default
            description: _description,
            requiresTimestamp: false, requiredTimestamp: 0,
            requiresOracleData: false, requiredOracleKey: "", requiredOracleValue: 0,
            requiresNFT: false, requiredNFTContract: address(0), requiredNFTTokenId: 0,
            requiresGuardianApproval: false, requiredGuardianVotes: 0,
            requiresInternalCounter: false, requiredInternalCounterValue: 0,
            requiresInternalFlag: false, requiredInternalFlagState: false
        });
        emit ConditionDefined(newConditionId, _description);
        return newConditionId;
    }

    /**
     * @notice Links an existing deposit to a specific condition. Only owner or condition manager.
     * @param _depositId The ID of the deposit to link.
     * @param _conditionId The ID of the condition to link to (0 for unconditional).
     * @dev Can be used to change the condition of a deposit after creation. Be cautious.
     */
    function linkDepositToCondition(uint256 _depositId, uint256 _conditionId) external onlyConditionManager {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist"); // Check if deposit exists
        require(conditions[_conditionId].isActive || _conditionId == 0, "Condition must be active or 0");

        deposit.conditionId = _conditionId;
        emit DepositLinkedToCondition(_depositId, _conditionId);
    }

    // --- Functions to define specific requirements for a condition ---

    /**
     * @notice Sets the timestamp requirement for a condition.
     * @param _conditionId The ID of the condition.
     * @param _requiredTimestamp The timestamp when the condition becomes met.
     */
    function setConditionTimestampRequirement(uint256 _conditionId, uint256 _requiredTimestamp) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        condition.requiresTimestamp = true;
        condition.requiredTimestamp = _requiredTimestamp;
        emit ConditionRequirementUpdated(_conditionId, "Timestamp");
    }

    /**
     * @notice Sets the oracle data requirement for a condition.
     * @param _conditionId The ID of the condition.
     * @param _requiredOracleKey The key the oracle data must be submitted under.
     * @param _requiredOracleValue The value the oracle data must match.
     */
    function setConditionOracleRequirement(uint256 _conditionId, string memory _requiredOracleKey, uint256 _requiredOracleValue) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        require(bytes(_requiredOracleKey).length > 0, "Oracle key cannot be empty");
        condition.requiresOracleData = true;
        condition.requiredOracleKey = _requiredOracleKey;
        condition.requiredOracleValue = _requiredOracleValue;
        emit ConditionRequirementUpdated(_conditionId, "OracleData");
    }

    /**
     * @notice Sets the NFT ownership requirement for a condition.
     * @param _conditionId The ID of the condition.
     * @param _requiredNFTContract The address of the required ERC721 contract.
     * @param _requiredNFTTokenId The ID of the required token.
     */
    function setConditionNFTRequirement(uint256 _conditionId, address _requiredNFTContract, uint256 _requiredNFTTokenId) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        require(_requiredNFTContract != address(0), "NFT contract address is zero");
        condition.requiresNFT = true;
        condition.requiredNFTContract = _requiredNFTContract;
        condition.requiredNFTTokenId = _requiredNFTTokenId;
        emit ConditionRequirementUpdated(_conditionId, "NFT");
    }

     /**
     * @notice Sets the guardian approval requirement for a condition. Resets current votes.
     * @param _conditionId The ID of the condition.
     * @param _requiredGuardianVotes The number of unique guardian votes required.
     */
    function setConditionGuardianRequirement(uint256 _conditionId, uint256 _requiredGuardianVotes) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        require(_requiredGuardianVotes > 0, "Required guardian votes must be > 0");
        condition.requiresGuardianApproval = true;
        condition.requiredGuardianVotes = _requiredGuardianVotes;
        // Reset votes when requirement changes
        delete guardianVotes[_conditionId];
        guardianVoteCounts[_conditionId] = 0;

        emit ConditionRequirementUpdated(_conditionId, "GuardianApproval");
    }

     /**
     * @notice Sets the internal counter value requirement for a condition.
     * @param _conditionId The ID of the condition.
     * @param _requiredValue The value the internal counter must be >=.
     */
    function setConditionInternalCounterRequirement(uint256 _conditionId, uint256 _requiredValue) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        condition.requiresInternalCounter = true;
        condition.requiredInternalCounterValue = _requiredValue;
        emit ConditionRequirementUpdated(_conditionId, "InternalCounter");
    }

    /**
     * @notice Sets the internal flag state requirement for a condition.
     * @param _conditionId The ID of the condition.
     * @param _requiredState The boolean state the internal flag must match.
     */
    function setConditionInternalFlagRequirement(uint256 _conditionId, bool _requiredState) external onlyConditionManager {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive, "Condition is not active");
        condition.requiresInternalFlag = true;
        condition.requiredInternalFlagState = _requiredState;
        emit ConditionRequirementUpdated(_conditionId, "InternalFlag");
    }

    // --- 4. External/Internal State Update (4 functions) ---

    /**
     * @notice Authorized oracles can submit data updates.
     * @param _oracleKey The key associated with the data.
     * @param _value The uint256 value being submitted.
     */
    function submitOracleData(string memory _oracleKey, uint256 _value) external onlyOracle {
        require(bytes(_oracleKey).length > 0, "Oracle key cannot be empty");
        oracleData[_oracleKey] = _value;
        emit OracleDataSubmitted(_oracleKey, _value);
    }

    /**
     * @notice Guardians can vote to approve conditions requiring guardian approval.
     * @param _conditionId The ID of the condition to vote for.
     */
    function guardianVote(uint256 _conditionId) external onlyGuardian {
        Condition storage condition = conditions[_conditionId];
        require(condition.isActive && condition.requiresGuardianApproval, "Condition is not active or doesn't require guardian approval");
        require(!guardianVotes[_conditionId][msg.sender], "Guardian has already voted for this condition");
        
        guardianVotes[_conditionId][msg.sender] = true;
        guardianVoteCounts[_conditionId]++;
        emit GuardianVoted(_conditionId, msg.sender);
    }

     /**
     * @notice Increments the general-purpose internal counter.
     */
    function incrementInternalCounter() external onlyConditionManager {
        unchecked {
            internalCounter++; // Use unchecked as overflow resets it, which is acceptable for a counter purpose here
        }
        emit InternalCounterIncremented(internalCounter);
    }

    /**
     * @notice Sets the state of the general-purpose internal flag.
     * @param _newState The new boolean state for the flag.
     */
    function setInternalFlag(bool _newState) external onlyConditionManager {
        internalFlag = _newState;
        emit InternalFlagSet(internalFlag);
    }

    // --- 5. Withdrawal Functions (3 functions) ---

    /**
     * @notice Attempts to withdraw deposited Ether.
     * @param _depositId The ID of the ETH deposit to withdraw.
     */
    function withdrawETH(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(deposit.depositor == msg.sender, "Only the depositor can withdraw");
        require(deposit.tokenAddress == address(0), "Deposit is not Ether");
        require(deposit.amount > 0, "Deposit is already withdrawn or empty");

        // Evaluate the condition (including the NFT requirement if applicable)
        bool conditionMet = _checkCondition(deposit.conditionId);

        // If NFT is required, check if the *caller* (depositor) currently owns it
        if (conditions[deposit.conditionId].requiresNFT) {
            address requiredNFTContract = conditions[deposit.conditionId].requiredNFTContract;
            uint256 requiredNFTTokenId = conditions[deposit.conditionId].requiredNFTTokenId;
            require(IERC721(requiredNFTContract).ownerOf(msg.sender) == msg.sender, "Withdrawal requires owning the specific NFT");
            // The NFT check is an *additional* requirement for withdrawal beyond _checkCondition
            // The _checkCondition helper just verifies the *condition definition* requires an NFT,
            // but the actual ownership check must happen at the point of withdrawal by the caller.
            // Since require() reverts on failure, we don't need to explicitly modify 'conditionMet'.
        }

        require(conditionMet, "Withdrawal condition not met");

        // Mark deposit as withdrawn before sending (checks-effects-interactions)
        uint256 amountToSend = deposit.amount;
        delete deposits[_depositId]; // Removes the deposit
        // Note: depositsByDepositor mapping is not updated to save gas on state changes.
        // Users can still query their past deposit IDs.

        (bool success, ) = payable(deposit.depositor).call{value: amountToSend}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(_depositId, deposit.depositor, amountToSend, deposit.conditionId);
    }

    /**
     * @notice Attempts to withdraw deposited ERC20 tokens.
     * @param _depositId The ID of the ERC20 deposit to withdraw.
     */
    function withdrawERC20(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(deposit.depositor == msg.sender, "Only the depositor can withdraw");
        require(deposit.tokenAddress != address(0), "Deposit is not ERC20");
        require(deposit.amount > 0, "Deposit is already withdrawn or empty");

         // Evaluate the condition (including the NFT requirement if applicable)
        bool conditionMet = _checkCondition(deposit.conditionId);
        if (conditions[deposit.conditionId].requiresNFT) {
             address requiredNFTContract = conditions[deposit.conditionId].requiredNFTContract;
             uint256 requiredNFTTokenId = conditions[deposit.conditionId].requiredNFTTokenId;
             require(IERC721(requiredNFTContract).ownerOf(msg.sender) == msg.sender, "Withdrawal requires owning the specific NFT");
        }
        require(conditionMet, "Withdrawal condition not met");

        // Mark deposit as withdrawn before sending (checks-effects-interactions)
        address tokenAddress = deposit.tokenAddress;
        uint256 amountToSend = deposit.amount;
        delete deposits[_depositId];

        IERC20(tokenAddress).safeTransfer(deposit.depositor, amountToSend);

        emit ERC20Withdrawn(_depositId, deposit.depositor, tokenAddress, amountToSend, deposit.conditionId);
    }

     /**
     * @notice Attempts to withdraw deposited ERC721 token.
     * @param _depositId The ID of the ERC721 deposit to withdraw.
     */
    function withdrawERC721(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(deposit.depositor == msg.sender, "Only the depositor can withdraw");
        require(deposit.tokenAddress != address(0), "Deposit is not ERC721"); // Should be ERC721 token address
        require(deposit.tokenId != 0 || deposit.amount == 0, "Deposit is not ERC721 or amount is non-zero"); // Ensure it's an ERC721 deposit format

        // Evaluate the condition (including the NFT requirement if applicable)
        bool conditionMet = _checkCondition(deposit.conditionId);
         if (conditions[deposit.conditionId].requiresNFT) {
             address requiredNFTContract = conditions[deposit.conditionId].requiredNFTContract;
             uint256 requiredNFTTokenId = conditions[deposit.conditionId].requiredNFTTokenId;
             require(IERC721(requiredNFTContract).ownerOf(msg.sender) == msg.sender, "Withdrawal requires owning the specific NFT");
        }
        require(conditionMet, "Withdrawal condition not met");

        // Mark deposit as withdrawn before sending (checks-effects-interactions)
        address tokenAddress = deposit.tokenAddress;
        uint256 tokenIdToSend = deposit.tokenId;
        delete deposits[_depositId];

        IERC721(tokenAddress).safeTransferFrom(address(this), deposit.depositor, tokenIdToSend);

        emit ERC721Withdrawn(_depositId, deposit.depositor, tokenAddress, tokenIdToSend, deposit.conditionId);
    }

    // --- 6. Emergency Withdrawal Functions (3 functions) ---

    /**
     * @notice Allows the emergency owner to withdraw Ether deposits bypassing conditions.
     * @dev Can withdraw any ETH deposit regardless of depositor or condition. Use with extreme caution.
     * @param _depositId The ID of the ETH deposit to withdraw.
     */
    function emergencyWithdrawETH(uint256 _depositId) external onlyEmergencyOwner {
         Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(deposit.tokenAddress == address(0), "Deposit is not Ether");
        require(deposit.amount > 0, "Deposit is already withdrawn or empty");

        // Mark deposit as withdrawn before sending
        uint256 amountToSend = deposit.amount;
        address recipient = deposit.depositor; // Send back to original depositor in emergency? Or emergency owner? Let's send back to depositor.
        delete deposits[_depositId];

        (bool success, ) = payable(recipient).call{value: amountToSend}("");
        require(success, "Emergency ETH transfer failed");

        emit EmergencyETHWithdrawn(_depositId, recipient, amountToSend);
    }

    /**
     * @notice Allows the emergency owner to withdraw ERC20 deposits bypassing conditions.
     * @dev Can withdraw any ERC20 deposit regardless of depositor or condition. Use with extreme caution.
     * @param _depositId The ID of the ERC20 deposit to withdraw.
     */
    function emergencyWithdrawERC20(uint256 _depositId) external onlyEmergencyOwner {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        require(deposit.tokenAddress != address(0), "Deposit is not ERC20");
        require(deposit.amount > 0, "Deposit is already withdrawn or empty");

        // Mark deposit as withdrawn before sending
        address tokenAddress = deposit.tokenAddress;
        uint256 amountToSend = deposit.amount;
        address recipient = deposit.depositor; // Send back to original depositor?
        delete deposits[_depositId];

        IERC20(tokenAddress).safeTransfer(recipient, amountToSend);

        emit EmergencyERC20Withdrawn(_depositId, recipient, tokenAddress, amountToSend);
    }

     /**
     * @notice Allows the emergency owner to withdraw ERC721 deposits bypassing conditions.
     * @dev Can withdraw any ERC721 deposit regardless of depositor or condition. Use with extreme caution.
     * @param _depositId The ID of the ERC721 deposit to withdraw.
     */
    function emergencyWithdrawERC721(uint256 _depositId) external onlyEmergencyOwner {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
         require(deposit.tokenAddress != address(0), "Deposit is not ERC721");
        require(deposit.tokenId != 0 || deposit.amount == 0, "Deposit is not ERC721");

        // Mark deposit as withdrawn before sending
        address tokenAddress = deposit.tokenAddress;
        uint256 tokenIdToSend = deposit.tokenId;
        address recipient = deposit.depositor; // Send back to original depositor?
        delete deposits[_depositId];

         IERC721(tokenAddress).safeTransferFrom(address(this), recipient, tokenIdToSend);

        emit EmergencyERC721Withdrawn(_depositId, recipient, tokenAddress, tokenIdToSend);
    }


    // --- 7. Query/View Functions (>= 10 functions) ---

    /**
     * @notice Gets the details of a specific deposit.
     * @param _depositId The ID of the deposit.
     * @return Deposit struct containing deposit details.
     */
    function getDepositDetails(uint256 _depositId) external view returns (Deposit memory) {
        return deposits[_depositId];
    }

    /**
     * @notice Gets the IDs of all deposits made by a specific depositor.
     * @param _depositor The address of the depositor.
     * @return uint256[] An array of deposit IDs.
     */
    function getUserDepositIds(address _depositor) external view returns (uint256[] memory) {
        return depositsByDepositor[_depositor];
    }

    /**
     * @notice Gets the details of a specific condition definition.
     * @param _conditionId The ID of the condition.
     * @return Condition struct containing condition details.
     */
    function getConditionDetails(uint256 _conditionId) external view returns (Condition memory) {
        return conditions[_conditionId];
    }

    /**
     * @notice Checks if a specific condition is currently met.
     * @param _conditionId The ID of the condition.
     * @return bool True if the condition is met, false otherwise.
     */
    function isConditionMet(uint256 _conditionId) external view returns (bool) {
        return _checkCondition(_conditionId);
    }

     /**
     * @notice Checks if the withdrawal condition is met for a specific deposit.
     * @param _depositId The ID of the deposit.
     * @dev Note: This checks the condition requirements defined in the struct.
     *      The NFT ownership check (if required) must be done by the user
     *      at the time of withdrawal from their address, as the contract
     *      cannot check *future* or *other address'* NFT ownership here.
     * @return bool True if the condition components stored in the struct are met.
     */
    function isWithdrawalConditionMetForDeposit(uint256 _depositId) external view returns (bool) {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.id != 0, "Deposit does not exist");
        return _checkCondition(deposit.conditionId);
    }


    /**
     * @notice Gets the latest oracle data for a given key.
     * @param _oracleKey The key to lookup.
     * @return uint256 The value associated with the key (0 if not set).
     */
    function getOracleData(string memory _oracleKey) external view returns (uint256) {
        return oracleData[_oracleKey];
    }

    /**
     * @notice Gets the current count of guardian votes for a specific condition.
     * @param _conditionId The ID of the condition.
     * @return uint256 The number of votes received.
     */
    function getGuardianVoteCount(uint256 _conditionId) external view returns (uint256) {
        return guardianVoteCounts[_conditionId];
    }

    /**
     * @notice Checks if a specific guardian has voted for a specific condition.
     * @param _conditionId The ID of the condition.
     * @param _guardianAddress The address of the guardian.
     * @return bool True if the guardian has voted, false otherwise.
     */
    function hasGuardianVoted(uint256 _conditionId, address _guardianAddress) external view returns (bool) {
        return guardianVotes[_conditionId][_guardianAddress];
    }

    /**
     * @notice Gets the current value of the internal counter.
     * @return uint256 The current counter value.
     */
    function getInternalCounter() external view returns (uint256) {
        return internalCounter;
    }

    /**
     * @notice Gets the current state of the internal flag.
     * @return bool The current flag state.
     */
    function getInternalFlag() external view returns (bool) {
        return internalFlag;
    }

     /**
     * @notice Checks if an address has the Condition Manager role.
     * @param _account The address to check.
     * @return bool True if the address is a Condition Manager or the owner.
     */
    function checkIsConditionManager(address _account) external view returns (bool) {
        return isConditionManager[_account] || _account == owner;
    }

    /**
     * @notice Checks if an address has the Oracle role.
     * @param _account The address to check.
     * @return bool True if the address is an Oracle or the owner.
     */
    function checkIsOracle(address _account) external view returns (bool) {
        return isOracle[_account] || _account == owner;
    }

     /**
     * @notice Checks if an address has the Guardian role.
     * @param _account The address to check.
     * @return bool True if the address is a Guardian or the owner.
     */
    function checkIsGuardian(address _account) external view returns (bool) {
        return isGuardian[_account] || _account == owner;
    }

    // --- ERC721Holder required function ---
    // This function is called by ERC721 contracts when a token is transferred into this contract using safeTransferFrom.
    // Returning bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) signifies acceptance.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
        // Optionally add checks here if you only want to accept specific NFTs or from specific addresses
        // For this example, we accept any ERC721 transferred via safeTransferFrom
        return this.onERC721Received.selector;
    }

    // Fallback function to accept ETH deposits without specifying a condition explicitly
    // These deposits would default to conditionId 0 (unconditional) or require linking later.
    // Let's make deposits *require* a conditionId for clarity, so no fallback.
    // If a simple payable function was needed, add `receive() external payable { ... }`
    // For this complex vault, requiring a conditionId is part of the concept.

}
```