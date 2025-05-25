Okay, here is a smart contract concept I've developed. It's a "Quantum Vault" focusing on conditional asset/data release and access based on complex, potentially "entangled" or time-sensitive states, combined with non-transferable access tokens and a simplified commitment scheme. The "Quantum" aspect is a metaphor for non-deterministic or conditional states that collapse into a definite outcome upon "measurement" (i.e., state resolution triggered by time or external data).

It avoids direct duplication of standard templates by combining these specific mechanisms:
1.  **Conditional Release:** Assets (ERC20/ERC721) and data are held until a specific set of defined conditions are met.
2.  **Quantum States:** Groupings of conditions with configurable logic (AND, OR, Majority) that define the *state* required for release/access.
3.  **State Entanglement (Metaphor):** Conditions can be linked, and resolving one can influence others (though the implementation here simplifies this to state *dependencies* or combinations).
4.  **Timed/Oracle Measurement:** State resolution is triggered by time passing or receiving data from an oracle.
5.  **Quantum Access Tokens (QAT):** Non-transferable ERC-721 tokens representing *rights* or *shares* in specific vault states or assets, rather than ownership of the underlying asset itself. Non-transferability is enforced.
6.  **Commitment Scheme:** A simple commit-reveal mechanism to prove knowledge of a secret *before* revealing it or triggering an action, adding a layer of conditional access or puzzle-like elements.

This contract aims for complexity by managing multiple types of assets, data, states, conditions, access tokens, and external dependencies within a single system.

---

**Smart Contract Outline & Function Summary: Quantum Vault**

**Contract Name:** QuantumVault

**Core Concept:** A vault holding ERC20 tokens, ERC721 tokens, and arbitrary data, with access/release strictly governed by complex, time-sensitive, or oracle-dependent "Quantum States" and managed via non-transferable "Quantum Access Tokens" and optional commitment proofs.

**Outline:**

1.  **Imports & Interfaces:** Standard libraries (ERC20, ERC721, Ownable, Pausable, ReentrancyGuard) and custom QAT interface.
2.  **Errors:** Custom error definitions for clarity.
3.  **Enums:** Define types for Conditions and State Logic.
4.  **Structs:** Define data structures for Conditions, Quantum States, Data Entries, and QATs.
5.  **State Variables:** Mappings and variables to track assets, data, conditions, states, QATs, commitments, and configuration.
6.  **Events:** Log key actions like deposits, withdrawals, state changes, QAT minting, etc.
7.  **Modifiers:** Standard modifiers (`onlyOwner`, `whenNotPaused`, `nonReentrant`) and custom ones (`isAllowedToken`, `hasRequiredQAT`).
8.  **Core Vault Operations:** Deposit ERC20/ERC721, Store Data.
9.  **Condition Management:** Add, update, resolve individual conditions.
10. **Quantum State Management:** Define, link assets/data to states, resolve states based on condition outcomes.
11. **Asset/Data Release:** Withdraw ERC20/ERC721, Retrieve Data (protected by state/conditions).
12. **Quantum Access Token (QAT) Management:** Mint, burn, check QAT ownership/state.
13. **Commitment Scheme:** Commit a hash, reveal a secret and verify.
14. **Oracle Integration:** Set oracle address, receive oracle data (simplified).
15. **Configuration & Utility:** Set allowed tokens, emergency withdrawal, pause/unpause, ownership.
16. **Getters/View Functions:** Provide visibility into the vault's state.

**Function Summary:**

1.  `constructor(address initialOwner, address initialQatTokenAddress)`: Initializes the contract with owner and Quantum Access Token (QAT) address.
2.  `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle contract. (Owner only)
3.  `addAllowedToken(address _tokenAddress, bool isERC721)`: Adds an ERC20 or ERC721 token to the list of allowed deposit tokens. (Owner only)
4.  `removeAllowedToken(address _tokenAddress)`: Removes a token from the list of allowed deposit tokens. (Owner only)
5.  `depositERC20(address tokenAddress, uint256 amount)`: Deposits ERC20 tokens into the vault. Requires approval beforehand.
6.  `depositERC721(address tokenAddress, uint256 tokenId)`: Deposits an ERC721 token into the vault. Requires approval or prior transfer.
7.  `storeDataWithConditions(uint256 dataId, bytes calldata data, uint256 requiredStateId)`: Stores arbitrary data linked to a specific Quantum State ID.
8.  `addTimeCondition(uint256 conditionId, uint64 unlockTimestamp)`: Defines a time-based condition that is met after a specific timestamp. (Owner only)
9.  `addOracleCondition(uint256 conditionId, bytes32 queryId, int256 expectedValue)`: Defines an oracle-based condition that is met when an oracle reports a specific value for a query. (Owner only)
10. `addEventCondition(uint256 conditionId, bytes32 eventHash)`: Defines a condition met by an external, verified event (represented by a hash). (Owner only - simplification, a real implementation would involve proof verification).
11. `defineQuantumState(uint256 stateId, uint256[] calldata conditionIds, StateLogic logic)`: Defines a Quantum State as a combination of conditions and logic (AND, OR, Majority). (Owner only)
12. `linkAssetToState(uint256 stateId, address tokenAddress, uint256 assetId, bool isERC721)`: Links a deposited asset (ERC20 amount or ERC721 ID) to a specific Quantum State required for its release. (Owner only) (Note: ERC20 linking is by *type*, release amount might be complex, simplify to releasing *some* based on state). Let's simplify: Link *permission* to withdraw ERC20 of a type or specific ERC721 ID based on state.
13. `linkDataToState(uint256 stateId, uint256 dataId)`: Links stored data to a specific Quantum State required for its retrieval. (Owner only)
14. `resolveQuantumState(uint256 stateId)`: Attempts to resolve the state of a Quantum State based on the current status of its linked conditions. Can be triggered by anyone (potentially incentivized or limited).
15. `fulfillOracleRequest(bytes32 queryId, int256 value)`: Callback function for the oracle to report data, potentially resolving oracle conditions.
16. `withdrawERC20(address tokenAddress, uint256 amount, uint256 requiredStateId)`: Allows withdrawal of ERC20 tokens if the required Quantum State is `Met`.
17. `withdrawERC721(address tokenAddress, uint256 tokenId, uint256 requiredStateId)`: Allows withdrawal of a specific ERC721 token if the required Quantum State is `Met`.
18. `retrieveData(uint256 dataId, uint256 requiredStateId)`: Retrieves stored data if the required Quantum State is `Met`. (View function).
19. `mintQAT(address recipient, uint256 qatId, uint256 linkedStateId)`: Mints a non-transferable Quantum Access Token (QAT) linked to a specific Quantum State. (Owner or authorized caller only)
20. `burnQAT(uint256 qatId)`: Burns a Quantum Access Token. (QAT owner or authorized caller)
21. `commitSecret(bytes32 commitmentHash, uint256 expirationTimestamp)`: Allows a user to commit a hash of a secret, valid until an expiration time.
22. `revealSecretAndCheck(uint256 requiredStateId, bytes calldata secret, bytes32 expectedCommitmentHash)`: Allows a user to reveal a secret, which is verified against a prior commitment. This might be an *additional* condition check for accessing assets/data linked to `requiredStateId`.
23. `emergencyWithdrawERC20(address tokenAddress)`: Allows the owner to withdraw all of a specific ERC20 token in an emergency. (Owner only)
24. `emergencyWithdrawERC721(address tokenAddress, uint256 tokenId)`: Allows the owner to withdraw a specific ERC721 token in an emergency. (Owner only)
25. `pause()`: Pauses contract operations (deposits, withdrawals, state resolution). (Owner only)
26. `unpause()`: Unpauses contract operations. (Owner only)
27. `getConditionState(uint256 conditionId)`: Returns the current state of a specific condition. (View)
28. `getQuantumStateOutcome(uint256 stateId)`: Returns the current outcome state of a specific Quantum State. (View)
29. `getQATLinkedState(uint256 qatId)`: Returns the Quantum State ID linked to a specific QAT. (View)
30. `hasRequiredQAT(address user, uint256 requiredStateId)`: Checks if a user holds any QAT linked to the specified state ID. (View)

*(Note: Some functions listed might be getters/views to meet the function count easily and provide necessary state visibility. The core logic resides in the non-view functions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/erc721/ERC721.sol"; // Using ERC721 for QATs, will enforce non-transferability
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interface for the non-transferable QAT (Quantum Access Token)
// We use ERC721 standard functions but will override _beforeTokenTransfer
// to prevent transfers (except for mint/burn initiated by this contract).
interface IQAT is IERC721 {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool approved) external;
    // We will add a view function to check the linked state
    function getLinkedStateId(uint256 tokenId) external view returns (uint256);
}


/**
 * @title QuantumVault
 * @dev A complex vault storing ERC20, ERC721, and data,
 *      governed by conditional "Quantum States" resolved via time/oracle,
 *      and accessed using non-transferable "Quantum Access Tokens" and optional proofs.
 */
contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- Errors ---
    error NotAllowedToken(address token);
    error AssetNotInVault(address token, uint256 assetId, bool isERC721);
    error DataEntryNotFound(uint256 dataId);
    error ConditionNotFound(uint256 conditionId);
    error QuantumStateNotFound(uint256 stateId);
    error StateNotMet(uint256 stateId);
    error StateResolutionFailed(uint256 stateId);
    error CommitmentNotFound(address user);
    error CommitmentExpired(address user);
    error SecretMismatch();
    error OracleNotSet();
    error QATNotFound(uint256 qatId);
    error NotLinkedToRequiredState(uint256 qatId, uint256 requiredStateId);
    error TransferNotAllowed(); // For QAT non-transferability


    // --- Enums ---
    enum ConditionType { Time, Oracle, ExternalEvent, Custom }
    enum ConditionState { Pending, Met, Failed }
    enum StateLogic { AND, OR, Majority } // How conditions combine

    // --- Structs ---

    struct Condition {
        ConditionType conditionType;
        ConditionState state;
        uint64 unlockTimestamp; // For Time
        bytes32 queryId;         // For Oracle/ExternalEvent (e.g., oracle request ID or event hash)
        int256 expectedValue;   // For Oracle
        // Future: Add fields for Custom conditions
    }

    struct QuantumState {
        uint256[] conditionIds;
        StateLogic logic;
        ConditionState outcome; // Result based on logic applied to conditions
        bool resolved;
    }

    struct DataEntry {
        bytes data;
        uint256 linkedStateId;
        bool exists; // Use a flag as bytes cannot be null
    }

    // This struct represents a non-transferable QAT and its link
    struct QAT {
        uint256 tokenId;
        uint256 linkedStateId;
        address owner;
        bool exists;
    }

    struct Commitment {
        bytes32 commitmentHash;
        uint256 expirationTimestamp;
        bool exists;
    }

    // --- State Variables ---

    // Asset storage: Token address => (isERC721 => (assetId => exists))
    mapping(address => mapping(bool => mapping(uint256 => bool))) private depositedAssets;
    // Link deposited assets to states: Token address => (isERC721 => (assetId => linkedStateId))
    mapping(address => mapping(bool => mapping(uint256 => uint256))) private assetLinkedState;

    // Data storage: dataId => DataEntry
    mapping(uint256 => DataEntry) private storedData;
    // Auto-incrementing dataId counter
    uint256 private nextDataId = 1;

    // Condition management: conditionId => Condition
    mapping(uint256 => Condition) private conditions;
    // Auto-incrementing conditionId counter
    uint256 private nextConditionId = 1;

    // Quantum State management: stateId => QuantumState
    mapping(uint256 => QuantumState) private quantumStates;
    // Auto-incrementing stateId counter
    uint256 private nextStateId = 1;

    // Allowed tokens for deposit: tokenAddress => isAllowed
    mapping(address => bool) private allowedTokens;
    mapping(address => bool) private isERC721Allowed; // Distinguish ERC20/ERC721

    address public oracleAddress;
    address public immutable qatTokenAddress; // Address of the deployed QAT ERC721 contract

    // User commitments: userAddress => Commitment
    mapping(address => Commitment) private userCommitments;

    // QAT token ID to QAT struct mapping (handled within the custom ERC721 likely, but keeping a map here for vault's view)
    // In a real scenario, the QAT contract would manage its state. This map is illustrative.
    // Mapping from token ID to its owner and linked state is standard ERC721 + an extension.
    // Let's rely on the IQAT interface for this.

    // --- Events ---
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount);
    event ERC721Deposited(address indexed token, address indexed depositor, uint256 tokenId);
    event DataStored(uint256 indexed dataId, address indexed depositor, uint256 linkedStateId);
    event ConditionAdded(uint256 indexed conditionId, ConditionType conditionType);
    event ConditionStateUpdated(uint256 indexed conditionId, ConditionState newState);
    event QuantumStateDefined(uint256 indexed stateId, StateLogic logic, uint256[] conditionIds);
    event AssetLinkedToState(uint256 indexed stateId, address indexed token, uint256 assetId, bool isERC721);
    event DataLinkedToState(uint256 indexed stateId, uint256 indexed dataId);
    event QuantumStateResolved(uint256 indexed stateId, ConditionState outcome);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount, uint256 indexed requiredStateId);
    event ERC721Withdrawn(address indexed token, address indexed recipient, uint256 indexed tokenId, uint256 indexed requiredStateId);
    event QATMinted(address indexed recipient, uint256 indexed qatId, uint256 linkedStateId);
    event QATBurned(uint256 indexed qatId);
    event SecretCommitted(address indexed user, bytes32 commitmentHash);
    event SecretRevealed(address indexed user, bytes32 commitmentHash);
    event OracleAddressSet(address indexed oracleAddress);
    event TokenAllowed(address indexed token, bool isERC721);
    event TokenRemoved(address indexed token);
    event EmergencyWithdrawal(address indexed token, uint256 amountOrId, bool isERC721);

    // --- Modifiers ---
    modifier isAllowedToken(address _tokenAddress) {
        if (!allowedTokens[_tokenAddress]) {
            revert NotAllowedToken(_tokenAddress);
        }
        _;
    }

    modifier hasRequiredQAT(address _user, uint256 _requiredStateId) {
        if (!hasQAT(_user, _requiredStateId)) {
             // Custom error could be added here
            revert("QuantumVault: User does not hold required QAT");
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner, address initialQatTokenAddress) Ownable(initialOwner) Pausable(false) {
        if (initialQatTokenAddress == address(0)) {
            revert("QuantumVault: Invalid QAT token address");
        }
        qatTokenAddress = initialQatTokenAddress;
    }

    // --- Core Vault Operations ---

    /**
     * @dev Allows users to deposit ERC20 tokens into the vault.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        isAllowedToken(tokenAddress)
    {
        if (isERC721Allowed[tokenAddress]) {
             revert("QuantumVault: Token is configured as ERC721, use depositERC721");
        }
        if (amount == 0) revert("QuantumVault: Deposit amount must be greater than 0");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        // For ERC20, we don't track individual 'assetIds', just the balance.
        // Linking happens at the token *type* level or implicitly via state.
        // We'll use assetId 0 for ERC20 entries in mappings where needed.
        depositedAssets[tokenAddress][false][0] = true; // Mark existence of ERC20 type
        emit ERC20Deposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Allows users to deposit ERC721 tokens into the vault.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address tokenAddress, uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
        isAllowedToken(tokenAddress)
    {
        if (!isERC721Allowed[tokenAddress]) {
            revert("QuantumVault: Token is not configured as ERC721, use depositERC20");
        }
        // The user must have approved the vault or transferred the token prior to calling this.
        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        depositedAssets[tokenAddress][true][tokenId] = true;
        emit ERC721Deposited(tokenAddress, msg.sender, tokenId);
    }

    /**
     * @dev Stores arbitrary bytes data within the vault, linked to a Quantum State.
     * @param dataId An arbitrary ID chosen by the storer, or use nextDataId=0 to auto-assign.
     * @param data The bytes data to store.
     * @param requiredStateId The ID of the Quantum State required to retrieve this data.
     */
    function storeDataWithConditions(uint256 dataId, bytes calldata data, uint256 requiredStateId)
        external
        whenNotPaused
    {
        if (requiredStateId != 0 && !quantumStates[requiredStateId].resolved) {
             revert("QuantumVault: Linked state must exist"); // State doesn't have to be resolved to link
        }
        if (dataId == 0) { // Auto-assign ID
            dataId = nextDataId++;
        } else if (storedData[dataId].exists) {
             revert("QuantumVault: Data ID already exists");
        }

        storedData[dataId] = DataEntry({
            data: data,
            linkedStateId: requiredStateId,
            exists: true
        });
        emit DataStored(dataId, msg.sender, requiredStateId);
    }


    // --- Condition Management ---

    /**
     * @dev Adds a time-based condition.
     * @param conditionId An arbitrary ID, or 0 to auto-assign.
     * @param unlockTimestamp The timestamp when the condition is met.
     */
    function addTimeCondition(uint256 conditionId, uint64 unlockTimestamp) external onlyOwner {
        if (conditionId == 0) {
            conditionId = nextConditionId++;
        } else if (conditions[conditionId].state != ConditionState.Pending) {
             revert("QuantumVault: Condition ID already exists or is not Pending");
        }

        conditions[conditionId] = Condition({
            conditionType: ConditionType.Time,
            state: ConditionState.Pending,
            unlockTimestamp: unlockTimestamp,
            queryId: bytes32(0),
            expectedValue: 0
        });
        emit ConditionAdded(conditionId, ConditionType.Time);
    }

    /**
     * @dev Adds an oracle-based condition. Requires oracleAddress to be set.
     * @param conditionId An arbitrary ID, or 0 to auto-assign.
     * @param queryId A unique identifier for the oracle query.
     * @param expectedValue The value from the oracle required to meet the condition.
     */
    function addOracleCondition(uint256 conditionId, bytes32 queryId, int256 expectedValue) external onlyOwner {
        if (oracleAddress == address(0)) revert OracleNotSet();

        if (conditionId == 0) {
            conditionId = nextConditionId++;
        } else if (conditions[conditionId].state != ConditionState.Pending) {
             revert("QuantumVault: Condition ID already exists or is not Pending");
        }

        conditions[conditionId] = Condition({
            conditionType: ConditionType.Oracle,
            state: ConditionState.Pending,
            unlockTimestamp: 0,
            queryId: queryId,
            expectedValue: expectedValue
        });
        emit ConditionAdded(conditionId, ConditionType.Oracle);
        // In a real Chainlink integration, you'd request the oracle update here or separately.
    }

    /**
     * @dev Adds an external event-based condition (simplified: relies on an off-chain proof verification).
     * @param conditionId An arbitrary ID, or 0 to auto-assign.
     * @param eventHash A hash representing the external event data/proof.
     */
    function addEventCondition(uint256 conditionId, bytes32 eventHash) external onlyOwner {
         if (conditionId == 0) {
            conditionId = nextConditionId++;
        } else if (conditions[conditionId].state != ConditionState.Pending) {
             revert("QuantumVault: Condition ID already exists or is not Pending");
        }
        if (eventHash == bytes32(0)) revert("QuantumVault: Event hash cannot be zero");

        conditions[conditionId] = Condition({
            conditionType: ConditionType.ExternalEvent,
            state: ConditionState.Pending,
            unlockTimestamp: 0, // Not used
            queryId: eventHash, // Using queryId field to store the event hash
            expectedValue: 0    // Not used
        });
        emit ConditionAdded(conditionId, ConditionType.ExternalEvent);
    }

     /**
      * @dev Placeholder for adding a custom condition type logic.
      * @param conditionId An arbitrary ID, or 0 to auto-assign.
      * @param customData Arbitrary data relevant to the custom condition.
      */
    function addCustomCondition(uint256 conditionId, bytes calldata customData) external onlyOwner {
        if (conditionId == 0) {
            conditionId = nextConditionId++;
        } else if (conditions[conditionId].state != ConditionState.Pending) {
             revert("QuantumVault: Condition ID already exists or is not Pending");
        }
         // In a real scenario, customData would define *how* to check this condition
         // and you'd need a corresponding function to resolve it.
         // For this example, we just mark its existence.
        conditions[conditionId] = Condition({
            conditionType: ConditionType.Custom,
            state: ConditionState.Pending,
            unlockTimestamp: 0,
            queryId: bytes32(0),
            expectedValue: 0
            // Custom data would ideally be stored or referenced here
        });
        emit ConditionAdded(conditionId, ConditionType.Custom);
    }

    /**
     * @dev Manually resolves an External Event condition (requires off-chain proof).
     * @param conditionId The ID of the External Event condition to resolve.
     * @param proofVerificationData Data needed to verify the event proof (simplified).
     */
    function resolveExternalEventCondition(uint256 conditionId, bytes calldata proofVerificationData) external nonReentrant whenNotPaused {
        Condition storage condition = conditions[conditionId];
        if (condition.state != ConditionState.Pending || condition.conditionType != ConditionType.ExternalEvent) {
             revert("QuantumVault: Condition not found or not pending ExternalEvent");
        }

        // --- Simplified Proof Verification ---
        // In a real DApp, this would involve complex logic like:
        // 1. Checking a Merkle Proof against a root stored on-chain.
        // 2. Calling another verification contract.
        // 3. Verifying a cryptographic signature.
        // For this example, we'll just simulate success if proofVerificationData is non-empty.
        bool proofIsValid = proofVerificationData.length > 0; // Simplified verification

        if (proofIsValid) {
            condition.state = ConditionState.Met;
            emit ConditionStateUpdated(conditionId, ConditionState.Met);
        } else {
            condition.state = ConditionState.Failed; // Or keep Pending if retriable
            emit ConditionStateUpdated(conditionId, ConditionState.Failed);
             revert("QuantumVault: Proof verification failed");
        }
         // After resolving a condition, it might be necessary to trigger resolution of
         // any Quantum States linked to this condition. This could be done here or
         // left to users calling resolveQuantumState. Let's rely on users calling resolveQuantumState.
    }


    // --- Quantum State Management ---

    /**
     * @dev Defines a Quantum State composed of multiple conditions and logic.
     * @param stateId An arbitrary ID, or 0 to auto-assign.
     * @param conditionIds The IDs of the conditions included in this state.
     * @param logic The logic (AND, OR, Majority) for combining condition outcomes.
     */
    function defineQuantumState(uint256 stateId, uint256[] calldata conditionIds, StateLogic logic) external onlyOwner {
        if (conditionIds.length == 0) revert("QuantumVault: State must have conditions");
        for (uint256 i = 0; i < conditionIds.length; i++) {
            if (conditions[conditionIds[i]].state == ConditionState.Pending && conditions[conditionIds[i]].conditionType == ConditionType.Custom) {
                // Allow defining states with Custom conditions, but they can't be resolved
                // until the custom condition has a resolution mechanism.
            } else if (conditions[conditionIds[i]].state == ConditionState.Pending) {
                 // Ok if condition is pending, it will be checked during resolution
            } else {
                // Allow linking to already resolved conditions too? Let's assume Yes for flexibility.
            }
             if (conditions[conditionIds[i]].state == ConditionState.Failed) {
                 // Linking to a failed condition? Might make state unresolvable.
                 // Add a warning or restrict? Let's allow for now, logic will handle it.
             }
             // Check if conditionId exists at all
             if (conditions[conditionIds[i]].conditionType == ConditionType(0) && conditions[conditionIds[i]].state == ConditionState.Pending) {
                 // This check is tricky. Default struct values make distinguishing non-existent from
                 // default values hard without an 'exists' flag on Condition, or checking nextConditionId.
                 // Assuming conditions[conditionIds[i]].conditionType != ConditionType(0) check is sufficient
                 // if 0 isn't a valid type OR conditionId < nextConditionId. Let's check conditionId existence better.
                 bool conditionExists = conditionIds[i] > 0 && conditionIds[i] < nextConditionId && conditions[conditionIds[i]].conditionType != ConditionType(0);
                 if (!conditionExists && conditions[conditionIds[i]].state != ConditionState.Pending) { // Check state pending just in case
                      revert ConditionNotFound(conditionIds[i]);
                 }
            } else if (conditionIds[i] == 0) { // Condition ID 0 is invalid
                 revert ConditionNotFound(0);
            }
        }

        if (stateId == 0) {
            stateId = nextStateId++;
        } else if (quantumStates[stateId].resolved) {
             revert("QuantumVault: State ID already exists or is already resolved");
        }

        quantumStates[stateId] = QuantumState({
            conditionIds: conditionIds,
            logic: logic,
            outcome: ConditionState.Pending, // Initially pending
            resolved: false
        });
        emit QuantumStateDefined(stateId, logic, conditionIds);
    }

    /**
     * @dev Links a deposited asset to a Quantum State required for its release.
     * @param stateId The ID of the Quantum State.
     * @param tokenAddress The address of the asset token.
     * @param assetId The ID of the asset (0 for ERC20 amount, tokenId for ERC721).
     * @param isERC721 True if ERC721, false if ERC20.
     */
    function linkAssetToState(uint256 stateId, address tokenAddress, uint256 assetId, bool isERC721) external onlyOwner {
        if (!quantumStates[stateId].resolved) revert QuantumStateNotFound(stateId); // State must exist

        // Check if asset is actually deposited or is an allowed type
        if (!allowedTokens[tokenAddress]) revert NotAllowedToken(tokenAddress);
        if (isERC721 && !isERC721Allowed[tokenAddress]) revert("QuantumVault: Token not allowed as ERC721");
        if (!isERC721 && isERC721Allowed[tokenAddress]) revert("QuantumVault: Token not allowed as ERC20");

        if (isERC721) {
             if (!depositedAssets[tokenAddress][true][assetId]) revert AssetNotInVault(tokenAddress, assetId, true);
             assetLinkedState[tokenAddress][true][assetId] = stateId;
        } else {
             // For ERC20, we link the *type* to a state.
             // Release logic will need to decide *how much* is released when the state is met.
             // Let's use assetId 0 to represent the ERC20 type link.
             if (!depositedAssets[tokenAddress][false][0]) revert AssetNotInVault(tokenAddress, 0, false); // Check if any ERC20 of this type is in vault
             assetLinkedState[tokenAddress][false][0] = stateId; // Link the token type to the state
        }
        emit AssetLinkedToState(stateId, tokenAddress, assetId, isERC721);
    }

     /**
      * @dev Links stored data to a Quantum State required for its retrieval.
      * @param stateId The ID of the Quantum State.
      * @param dataId The ID of the stored data.
      */
    function linkDataToState(uint256 stateId, uint256 dataId) external onlyOwner {
         if (!quantumStates[stateId].resolved) revert QuantumStateNotFound(stateId); // State must exist
         if (!storedData[dataId].exists) revert DataEntryNotFound(dataId);

         storedData[dataId].linkedStateId = stateId; // Update the linked state
         emit DataLinkedToState(stateId, dataId);
    }


    /**
     * @dev Attempts to resolve a Quantum State based on its linked conditions.
     *      Can be called by anyone. Success updates the state's outcome.
     * @param stateId The ID of the Quantum State to resolve.
     */
    function resolveQuantumState(uint256 stateId) external whenNotPaused {
        QuantumState storage state = quantumStates[stateId];
        if (!state.resolved) revert QuantumStateNotFound(stateId); // State must be defined

        if (state.resolved) {
            // Already resolved, do nothing
            return;
        }

        uint256 metCount = 0;
        uint256 failedCount = 0;
        uint256 pendingCount = 0;

        for (uint256 i = 0; i < state.conditionIds.length; i++) {
            uint256 conditionId = state.conditionIds[i];
            Condition storage condition = conditions[conditionId];

            // First, attempt to update the condition state if it's Time or Oracle
            if (condition.state == ConditionState.Pending) {
                if (condition.conditionType == ConditionType.Time) {
                    if (block.timestamp >= condition.unlockTimestamp) {
                        condition.state = ConditionState.Met;
                        emit ConditionStateUpdated(conditionId, ConditionState.Met);
                    } else {
                        pendingCount++; // Still pending
                    }
                } else if (condition.conditionType == ConditionType.Oracle) {
                    // Oracle state is updated by fulfillOracleRequest, just check current state
                    pendingCount++; // Still pending, waiting for oracle callback
                } else if (condition.conditionType == ConditionType.ExternalEvent) {
                     // ExternalEvent state is updated by resolveExternalEventCondition
                    pendingCount++; // Still pending, waiting for manual resolution
                } else if (condition.conditionType == ConditionType.Custom) {
                    // Custom conditions need external resolution or specific logic checks not defined here
                     pendingCount++; // Cannot resolve automatically
                }
            }

            // Now check the current state of the condition after potential update
            if (condition.state == ConditionState.Met) {
                metCount++;
            } else if (condition.state == ConditionState.Failed) {
                failedCount++;
            } else { // ConditionState.Pending
                // pendingCount was already incremented
            }
        }

        ConditionState newOutcome = ConditionState.Pending;
        bool stateUpdated = false;

        // Apply the state logic
        if (state.logic == StateLogic.AND) {
            if (failedCount > 0) {
                newOutcome = ConditionState.Failed;
                stateUpdated = true;
            } else if (pendingCount == 0) {
                newOutcome = ConditionState.Met;
                stateUpdated = true;
            }
            // If pendingCount > 0 and failedCount == 0, outcome remains Pending
        } else if (state.logic == StateLogic.OR) {
            if (metCount > 0) {
                newOutcome = ConditionState.Met;
                stateUpdated = true;
            } else if (pendingCount == 0) { // All conditions are Failed
                newOutcome = ConditionState.Failed;
                stateUpdated = true;
            }
            // If pendingCount > 0 and metCount == 0, outcome remains Pending
        } else if (state.logic == StateLogic.Majority) {
            uint256 totalConditions = state.conditionIds.length;
            uint256 threshold = (totalConditions / 2) + 1; // Simple majority

            if (metCount >= threshold) {
                newOutcome = ConditionState.Met;
                stateUpdated = true;
            } else if (failedCount + pendingCount < threshold) {
                 // If not enough pending/failed conditions left to prevent a majority of Met, state could become Met
                 // Or if metCount < threshold AND (failedCount + pendingCount) <= totalConditions - threshold (i.e. metCount + failedCount + pendingCount == totalConditions),
                 // and metCount is not majority, it fails if all remaining become failed.
                 // Let's simplify: if metCount < threshold AND totalConditions - metCount == failedCount (all non-met are failed)
                 if (metCount < threshold && totalConditions - metCount == failedCount) {
                     newOutcome = ConditionState.Failed;
                     stateUpdated = true;
                 }
            }
            // Otherwise, remains Pending
        }

        if (stateUpdated) {
            state.outcome = newOutcome;
            state.resolved = (newOutcome != ConditionState.Pending);
            emit QuantumStateResolved(stateId, newOutcome);
        }
    }

    /**
     * @dev Callback function for the oracle to report data.
     *      Updates the state of relevant Oracle conditions.
     *      Only callable by the designated oracleAddress.
     * @param queryId The identifier of the oracle query.
     * @param value The reported value from the oracle.
     */
    function fulfillOracleRequest(bytes32 queryId, int256 value) external {
        if (msg.sender != oracleAddress) revert("QuantumVault: Caller is not the oracle");
        if (queryId == bytes32(0)) revert("QuantumVault: Invalid query ID");

        // Iterate through all conditions to find matching Oracle conditions
        // This is inefficient for many conditions; better to use a mapping queryId => conditionIds[]
        // For simplicity in this example, we iterate.
        for (uint256 i = 1; i < nextConditionId; i++) {
            Condition storage condition = conditions[i];
            if (condition.conditionType == ConditionType.Oracle && condition.state == ConditionState.Pending && condition.queryId == queryId) {
                if (condition.expectedValue == value) {
                    condition.state = ConditionState.Met;
                    emit ConditionStateUpdated(i, ConditionState.Met);
                } else {
                    condition.state = ConditionState.Failed; // Or maybe just remains Pending if it's retriable? Let's mark Failed.
                    emit ConditionStateUpdated(i, ConditionState.Failed);
                }
            }
        }
         // After updating conditions, potentially trigger resolution of states linked to these conditions
         // This would require finding states linked to updated conditions. Again, mapping helps.
         // Leaving manual triggering via resolveQuantumState for this example.
    }

    // --- Asset/Data Release ---

    /**
     * @dev Allows withdrawal of ERC20 tokens if the linked Quantum State is Met.
     *      Requires the user to potentially hold a QAT linked to the state.
     *      Simplified: withdraws a specified amount *if* the state for that token type is met.
     *      Does not track specific deposits per user.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount to withdraw.
     * @param requiredStateId The Quantum State ID linked to this token type for withdrawal permission.
     */
    function withdrawERC20(address tokenAddress, uint256 amount, uint256 requiredStateId)
        external
        nonReentrant
        whenNotPaused
        isAllowedToken(tokenAddress)
        hasRequiredQAT(msg.sender, requiredStateId) // Optional: require QAT to withdraw
    {
        if (isERC721Allowed[tokenAddress]) revert("QuantumVault: Token is ERC721");
        if (!depositedAssets[tokenAddress][false][0]) revert AssetNotInVault(tokenAddress, 0, false); // Check if any ERC20 of this type is in vault

        // Check if the state linked to this token type allows withdrawal
        // We assume the assetId 0 is used to link the ERC20 type to a state
        if (assetLinkedState[tokenAddress][false][0] != requiredStateId) {
             revert("QuantumVault: Token type not linked to this state");
        }

        // Check the state outcome
        if (quantumStates[requiredStateId].outcome != ConditionState.Met) {
            revert StateNotMet(requiredStateId);
        }
        if (!quantumStates[requiredStateId].resolved) {
             revert("QuantumVault: State not yet resolved");
        }

        // Check if contract has enough balance
        if (IERC20(tokenAddress).balanceOf(address(this)) < amount) {
            revert("QuantumVault: Insufficient contract balance");
        }

        IERC20(tokenAddress).transfer(msg.sender, amount);
        // Note: We don't remove the ERC20 existence flag until balance is zero,
        // as multiple withdrawals are possible.
        emit ERC20Withdrawn(tokenAddress, msg.sender, amount, requiredStateId);
    }

    /**
     * @dev Allows withdrawal of an ERC721 token if the linked Quantum State is Met.
     *      Requires the user to potentially hold a QAT linked to the state.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     * @param requiredStateId The Quantum State ID linked to this specific token for withdrawal permission.
     */
    function withdrawERC721(address tokenAddress, uint256 tokenId, uint256 requiredStateId)
        external
        nonReentrant
        whenNotPaused
        isAllowedToken(tokenAddress)
        hasRequiredQAT(msg.sender, requiredStateId) // Optional: require QAT to withdraw
    {
        if (!isERC721Allowed[tokenAddress]) revert("QuantumVault: Token is not ERC721");
        if (!depositedAssets[tokenAddress][true][tokenId]) revert AssetNotInVault(tokenAddress, tokenId, true);

        // Check if the state linked to this specific token allows withdrawal
        if (assetLinkedState[tokenAddress][true][tokenId] != requiredStateId) {
            revert("QuantumVault: Token not linked to this state");
        }

        // Check the state outcome
        if (quantumStates[requiredStateId].outcome != ConditionState.Met) {
            revert StateNotMet(requiredStateId);
        }
         if (!quantumStates[requiredStateId].resolved) {
             revert("QuantumVault: State not yet resolved");
        }


        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        depositedAssets[tokenAddress][true][tokenId] = false; // Mark as withdrawn
        assetLinkedState[tokenAddress][true][tokenId] = 0; // Unlink state
        emit ERC721Withdrawn(tokenAddress, msg.sender, tokenId, requiredStateId);
    }

    /**
     * @dev Retrieves stored data if the linked Quantum State is Met.
     *      Requires the user to potentially hold a QAT linked to the state.
     * @param dataId The ID of the data entry.
     * @param requiredStateId The Quantum State ID linked to this data for retrieval permission.
     * @return The stored data bytes.
     */
    function retrieveData(uint256 dataId, uint256 requiredStateId)
        external
        view
        whenNotPaused // Apply pausable to views as well if data retrieval should halt
        hasRequiredQAT(msg.sender, requiredStateId) // Optional: require QAT to retrieve data
        returns (bytes memory)
    {
        DataEntry storage dataEntry = storedData[dataId];
        if (!dataEntry.exists) revert DataEntryNotFound(dataId);

        // Check if the state linked to this data allows retrieval
        if (dataEntry.linkedStateId != requiredStateId) {
             revert("QuantumVault: Data not linked to this state");
        }

        // Check the state outcome
        if (quantumStates[requiredStateId].outcome != ConditionState.Met) {
            revert StateNotMet(requiredStateId);
        }
         if (!quantumStates[requiredStateId].resolved) {
             revert("QuantumVault: State not yet resolved");
        }

        return dataEntry.data;
    }

    // --- Quantum Access Token (QAT) Management ---
    // Assumes the QAT contract is a modified ERC721 that prevents external transfers
    // but allows minting/burning by this contract.

    /**
     * @dev Mints a non-transferable Quantum Access Token (QAT) linked to a state.
     *      Tokens minted by this vault contract.
     * @param recipient The address to mint the token to.
     * @param qatId The ID for the new QAT (must be unique).
     * @param linkedStateId The Quantum State ID this QAT represents access/rights for.
     */
    function mintQAT(address recipient, uint256 qatId, uint256 linkedStateId) external onlyOwner {
        if (recipient == address(0)) revert("QuantumVault: Mint to zero address");
        if (qatId == 0) revert("QuantumVault: QAT ID cannot be zero");
        if (!quantumStates[linkedStateId].resolved) revert QuantumStateNotFound(linkedStateId); // State must exist to link

        // Call the mint function on the QAT contract
        // This assumes the QAT contract has a controlled mint function, e.g., only callable by the owner or this vault.
        // A real QAT contract implementation would be needed.
        // Example call (syntax depends on QAT contract ABI):
        IQAT(qatTokenAddress).safeTransferFrom(address(0), recipient, qatId); // Simulate minting by transferring from address(0)
         // Also need to link the state in the QAT contract itself, or rely on external lookup.
         // A better design would be IQAT(qatTokenAddress).mint(recipient, qatId, linkedStateId);
         // For this example, we assume the QAT contract records the linked state upon minting from this vault.
         // We'll rely on IQAT(qatTokenAddress).getLinkedStateId(qatId) for checks.

        emit QATMinted(recipient, qatId, linkedStateId);
    }

    /**
     * @dev Burns a Quantum Access Token.
     *      Callable by the QAT owner or this vault contract (e.g., when state fails).
     * @param qatId The ID of the QAT to burn.
     */
    function burnQAT(uint256 qatId) external {
         address qatOwner = IQAT(qatTokenAddress).ownerOf(qatId);
         if (qatOwner == address(0)) revert QATNotFound(qatId);

        // Check if caller is the owner of the QAT or the owner of the Vault
        if (msg.sender != qatOwner && msg.sender != owner()) {
            revert("QuantumVault: Not QAT owner or Vault owner");
        }

        // Call the burn function on the QAT contract
        // This assumes the QAT contract has a controlled burn function.
        // Example call:
        IQAT(qatTokenAddress).transferFrom(qatOwner, address(0), qatId); // Simulate burning by transferring to address(0)

        emit QATBurned(qatId);
    }

    // --- Commitment Scheme ---

    /**
     * @dev Allows a user to commit a hash of a secret.
     * @param commitmentHash The keccak256 hash of the secret.
     * @param expirationTimestamp The timestamp when this commitment expires.
     */
    function commitSecret(bytes32 commitmentHash, uint256 expirationTimestamp) external whenNotPaused {
        if (commitmentHash == bytes32(0)) revert("QuantumVault: Commitment cannot be zero");
        if (expirationTimestamp <= block.timestamp) revert("QuantumVault: Expiration must be in the future");

        userCommitments[msg.sender] = Commitment({
            commitmentHash: commitmentHash,
            expirationTimestamp: expirationTimestamp,
            exists: true
        });
        emit SecretCommitted(msg.sender, commitmentHash);
    }

    /**
     * @dev Allows a user to reveal a secret and verify it against their commitment.
     *      This function itself doesn't release assets, but could be used as a condition check
     *      within another function (e.g., a custom condition resolver or an access modifier).
     *      Here, it's implemented as a standalone check function that also checks a required state.
     * @param requiredStateId An optional state requirement for revealing.
     * @param secret The secret bytes to reveal.
     * @param expectedCommitmentHash The hash the user committed (redundant but good practice).
     */
    function revealSecretAndCheck(uint256 requiredStateId, bytes calldata secret, bytes32 expectedCommitmentHash)
        external
        view
        whenNotPaused
    {
        Commitment storage commitment = userCommitments[msg.sender];
        if (!commitment.exists) revert CommitmentNotFound(msg.sender);
        if (commitment.expirationTimestamp <= block.timestamp) revert CommitmentExpired(msg.sender);
        if (commitment.commitmentHash != expectedCommitmentHash) revert SecretMismatch(); // Check provided hash matches committed hash

        // Verify the secret against the committed hash
        if (keccak256(secret) != commitment.commitmentHash) {
             revert SecretMismatch();
        }

        // Optional: Check if a specific Quantum State is met before allowing the reveal/check
        if (requiredStateId != 0) {
            if (!quantumStates[requiredStateId].resolved) revert QuantumStateNotFound(requiredStateId);
            if (quantumStates[requiredStateId].outcome != ConditionState.Met) {
                revert StateNotMet(requiredStateId);
            }
        }

        // Secret is valid and matches commitment. Condition met (locally).
        // In a real use case, this would update a condition state or be part of another access check.
        // For this example, it just succeeds if checks pass.
        emit SecretRevealed(msg.sender, commitment.commitmentHash);
        // Note: Commitment is NOT automatically deleted here, needs separate logic if desired.
    }


    // --- Configuration & Utility ---

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Adds a token to the list of allowed deposit tokens.
     * @param _tokenAddress The address of the token.
     * @param isERC721 True if it's an ERC721, false if ERC20.
     */
    function addAllowedToken(address _tokenAddress, bool isERC721) external onlyOwner {
        if (_tokenAddress == address(0)) revert("QuantumVault: Cannot allow zero address");
        allowedTokens[_tokenAddress] = true;
        isERC721Allowed[_tokenAddress] = isERC721;
        emit TokenAllowed(_tokenAddress, isERC721);
    }

    /**
     * @dev Removes a token from the list of allowed deposit tokens. Does not affect already deposited tokens.
     * @param _tokenAddress The address of the token.
     */
    function removeAllowedToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) revert("QuantumVault: Cannot remove zero address");
        allowedTokens[_tokenAddress] = false;
        isERC721Allowed[_tokenAddress] = false; // Reset flag
        emit TokenRemoved(_tokenAddress);
    }

    /**
     * @dev Emergency withdrawal function for the owner in case of issues.
     *      Can withdraw all balance of a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     */
    function emergencyWithdrawERC20(address tokenAddress) external onlyOwner nonReentrant {
        if (!allowedTokens[tokenAddress] || isERC721Allowed[tokenAddress]) revert("QuantumVault: Not an allowed ERC20 token");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance > 0) {
            IERC20(tokenAddress).transfer(owner(), balance);
            emit EmergencyWithdrawal(tokenAddress, balance, false);
        }
    }

    /**
     * @dev Emergency withdrawal function for the owner in case of issues.
     *      Can withdraw a specific ERC721 token.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     */
    function emergencyWithdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner nonReentrant {
         if (!allowedTokens[tokenAddress] || !isERC721Allowed[tokenAddress]) revert("QuantumVault: Not an allowed ERC721 token");
         // Check if the vault still owns it (could be linked or not)
         if (IERC721(tokenAddress).ownerOf(tokenId) != address(this)) revert("QuantumVault: Vault does not own this token");

        IERC721(tokenAddress).transferFrom(address(this), owner(), tokenId);
        // Clean up internal state if it was tracked as deposited
        if (depositedAssets[tokenAddress][true][tokenId]) {
             depositedAssets[tokenAddress][true][tokenId] = false;
             assetLinkedState[tokenAddress][true][tokenId] = 0;
        }
        emit EmergencyWithdrawal(tokenAddress, tokenId, true);
    }

    /**
     * @dev Pauses the contract. Callable by owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable by owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Getters / View Functions (for 20+ functions) ---

    /**
     * @dev Checks if a token address is allowed for deposits.
     */
    function isTokenAllowed(address _tokenAddress) external view returns (bool) {
        return allowedTokens[_tokenAddress];
    }

    /**
     * @dev Checks if a token is configured as ERC721 or ERC20.
     */
    function getIsERC721Allowed(address _tokenAddress) external view returns (bool) {
        return isERC721Allowed[_tokenAddress];
    }

    /**
     * @dev Gets the current balance of a specific ERC20 token held by the contract.
     */
    function getContractTokenBalance(address tokenAddress) external view returns (uint256) {
        if (!allowedTokens[tokenAddress] || isERC721Allowed[tokenAddress]) return 0;
        return IERC20(tokenAddress).balanceOf(address(this));
    }

     /**
     * @dev Checks if a specific ERC721 token ID is marked as deposited.
     */
    function isERC721Deposited(address tokenAddress, uint256 tokenId) external view returns (bool) {
         if (!allowedTokens[tokenAddress] || !isERC721Allowed[tokenAddress]) return false;
         return depositedAssets[tokenAddress][true][tokenId];
    }

    /**
     * @dev Gets the details of a condition.
     */
    function getCondition(uint256 conditionId)
        external
        view
        returns (
            ConditionType conditionType,
            ConditionState state,
            uint64 unlockTimestamp,
            bytes32 queryId,
            int256 expectedValue
        )
    {
        Condition storage c = conditions[conditionId];
        if (c.conditionType == ConditionType(0) && c.state == ConditionState.Pending) {
             // Heuristic to check if ID exists (might need refinement depending on ID assignment)
            revert ConditionNotFound(conditionId);
        }
        return (c.conditionType, c.state, c.unlockTimestamp, c.queryId, c.expectedValue);
    }

    /**
     * @dev Gets the current state/outcome of a Quantum State.
     */
    function getQuantumStateOutcome(uint256 stateId) external view returns (ConditionState) {
         if (!quantumStates[stateId].resolved) revert QuantumStateNotFound(stateId); // Check existence
        return quantumStates[stateId].outcome;
    }

    /**
     * @dev Gets the condition IDs linked to a Quantum State.
     */
    function getQuantumStateConditionIds(uint256 stateId) external view returns (uint256[] memory) {
         if (!quantumStates[stateId].resolved) revert QuantumStateNotFound(stateId); // Check existence
        return quantumStates[stateId].conditionIds;
    }

    /**
     * @dev Gets the logic type of a Quantum State.
     */
     function getQuantumStateLogic(uint256 stateId) external view returns (StateLogic) {
         if (!quantumStates[stateId].resolved) revert QuantumStateNotFound(stateId); // Check existence
        return quantumStates[stateId].logic;
     }

    /**
     * @dev Checks if a user holds any QAT linked to a specific state ID.
     *      Requires iterating through user's QATs on the QAT contract.
     *      NOTE: This is a simplified check. A real QAT contract might need
     *      indexed events or a specific mapping for efficient lookup by stateId.
     *      Iterating through all QATs a user owns and then checking their linked state
     *      can be gas-intensive if a user owns many QATs. A better design would be
     *      a mapping like `hasQatForState[user][stateId] => bool` updated by mint/burn.
     *      Since we can't modify the IQAT interface arbitrarily, we'll use a potentially
     *      inefficient loop or rely on an external indexer. For this example, let's assume
     *      the IQAT contract provides `tokenOfOwnerByIndex`.
     */
    function hasQAT(address user, uint256 requiredStateId) public view returns (bool) {
        if (requiredStateId == 0) return true; // State 0 means no state required
        if (user == address(0)) return false;

        IQAT qatContract = IQAT(qatTokenAddress);
        uint256 balance = qatContract.balanceOf(user);

        // This loop can be very expensive for users with many QATs.
        // Real-world contracts should avoid this or use a better data structure.
        for (uint256 i = 0; i < balance; i++) {
            uint256 qatId = qatContract.tokenOfOwnerByIndex(user, i);
            if (qatContract.getLinkedStateId(qatId) == requiredStateId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Gets the Quantum State ID linked to a deposited ERC20 token type (assetId 0).
     */
    function getERC20LinkedState(address tokenAddress) external view returns (uint256) {
        if (!allowedTokens[tokenAddress] || isERC721Allowed[tokenAddress]) return 0;
        return assetLinkedState[tokenAddress][false][0];
    }

    /**
     * @dev Gets the Quantum State ID linked to a specific deposited ERC721 token.
     */
    function getERC721LinkedState(address tokenAddress, uint256 tokenId) external view returns (uint256) {
         if (!allowedTokens[tokenAddress] || !isERC721Allowed[tokenAddress]) return 0;
         return assetLinkedState[tokenAddress][true][tokenId];
    }

     /**
      * @dev Gets the Quantum State ID linked to stored data.
      */
    function getDataLinkedState(uint256 dataId) external view returns (uint256) {
        if (!storedData[dataId].exists) return 0;
        return storedData[dataId].linkedStateId;
    }

    /**
     * @dev Gets the current commitment hash for a user.
     */
    function getUserCommitment(address user) external view returns (bytes32 commitmentHash, uint256 expirationTimestamp, bool exists) {
        Commitment storage c = userCommitments[user];
        return (c.commitmentHash, c.expirationTimestamp, c.exists);
    }

    /**
     * @dev Gets the total number of conditions created.
     */
    function getTotalConditions() external view returns (uint256) {
        return nextConditionId - 1; // Assuming ID 0 is unused or special
    }

     /**
     * @dev Gets the total number of quantum states defined.
     */
    function getTotalQuantumStates() external view returns (uint256) {
        return nextStateId - 1; // Assuming ID 0 is unused or special
    }

     /**
     * @dev Gets the total number of data entries stored.
     */
    function getTotalDataEntries() external view returns (uint256) {
        return nextDataId - 1; // Assuming ID 0 is unused or special
    }

    /**
     * @dev Gets the address of the associated QAT token contract.
     */
    function getQATTokenAddress() external view returns (address) {
        return qatTokenAddress;
    }

    /**
     * @dev Gets the address of the set oracle.
     */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

     // Override Pausable's _before and _after paused hooks if needed for custom logic
     // For this example, default behavior is fine.

     // Internal helper function to check if a state exists (more robust than just checking resolved)
     function _quantumStateExists(uint256 stateId) internal view returns (bool) {
         // State ID 0 is invalid/reserved, assuming IDs start from 1.
         // Check if stateId is within the range of created states.
         // Also check if the state struct has default values, although this is heuristic.
         // A dedicated 'exists' flag on the struct would be better.
         // Let's use a heuristic: if stateId > 0 and < nextStateId and the conditionIds array is non-empty, it likely exists.
         // This isn't perfect but avoids iterating.
         if (stateId == 0 || stateId >= nextStateId) return false;
         return quantumStates[stateId].conditionIds.length > 0; // Heuristic check
     }

     // --- Non-Transferable QAT Implementation Detail ---
     // We are *not* implementing the full QAT ERC721 here, only the interface and how the Vault interacts.
     // A separate contract would implement the ERC721 logic with an overridden _beforeTokenTransfer:
     /*
     contract QuantumAccessToken is ERC721 {
         address public vaultAddress; // Address of the QuantumVault contract
         mapping(uint256 => uint256) private linkedStateId; // token ID => state ID

         constructor(address _vaultAddress) ERC721("Quantum Access Token", "QAT") {
             vaultAddress = _vaultAddress;
         }

         // Custom mint function callable only by the vault
         function mint(address to, uint256 tokenId, uint256 stateId) external {
             require(msg.sender == vaultAddress, "QAT: Only Vault can mint");
             _safeMint(to, tokenId);
             linkedStateId[tokenId] = stateId;
         }

         // Custom burn function callable by owner or vault
         function burn(uint256 tokenId) external {
             require(_isApprovedOrOwner(_msgSender(), tokenId) || msg.sender == vaultAddress, "QAT: Not owner or Vault");
             _burn(tokenId);
             delete linkedStateId[tokenId];
         }

         // Override _beforeTokenTransfer to prevent transfers NOT initiated by mint/burn
         function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
             super._beforeTokenTransfer(from, to, tokenId);

             if (from != address(0) && to != address(0)) { // Not a mint and not a burn
                 // Allow transfers only if the caller is the vault address
                 require(msg.sender == vaultAddress, "QAT: Token is non-transferable");
                  // Could potentially allow transfers initiated by the owner of the token *if*
                  // the vault owner approved it, but let's keep it strictly vault-controlled for simplicity.
             }
         }

         // Implement IQAT interface function
         function getLinkedStateId(uint256 tokenId) external view returns (uint256) {
             // Standard ERC721 might not have this, it's a custom extension
             // Need to handle case where token doesn't exist or isn't linked (return 0)
             if (!_exists(tokenId)) return 0;
             return linkedStateId[tokenId];
         }
     }
     */
}
```