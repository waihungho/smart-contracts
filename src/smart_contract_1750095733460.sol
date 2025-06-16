Okay, let's create a smart contract based on an advanced, somewhat abstract concept: a "Quantum Vault". This vault won't *actually* use quantum computing, but it will use analogies like "superposition", "entanglement", and "collapse" to manage the conditional release of assets (ERC-20 and ERC-721) based on multiple, potentially dynamic or probabilistic conditions.

The core idea is that assets are deposited into a state of "superposition" where their final destination (recipient, unlock time, etc.) is uncertain or dependent on future events. These states can be "entangled" meaning their conditions for release are linked. The state "collapses" when the necessary conditions are met, releasing the assets to the designated recipients.

This allows for complex escrow-like scenarios, multi-conditional time locks, or even simple prediction market elements where assets are locked until certain data points are available.

---

**Quantum Vault Smart Contract: Outline and Function Summary**

**Outline:**

1.  **Purpose:** To manage the conditional release of ERC-20 and ERC-721 tokens based on complex, multi-factor criteria modeled on quantum mechanical concepts (Superposition, Entanglement, Collapse).
2.  **Key Concepts:**
    *   **Superposition:** The initial state of deposited assets where release conditions are set but not yet met.
    *   **Entanglement:** Linking the release conditions of two or more separate deposits. A change or collapse in one can affect the others.
    *   **Collapse:** The irreversible transition from Superposition to a resolved state (released to recipients, or potentially cancelled), triggered when all conditions for a specific deposit (and its entangled group, if any) are met.
    *   **Conditions:** Criteria for collapse, including time locks, required oracle data values, and states of other deposits.
    *   **Trusted Oracle Reporters:** Addresses authorized to provide external data required for conditions.
    *   **Mutable Conditions:** Ability to change conditions under specific, predefined rules (e.g., before a certain time, only by depositor).
    *   **Probabilistic Elements (Simulated):** Conditions can be set based on future external data points provided by reporters, simulating reliance on uncertain outcomes.
3.  **Main Components:**
    *   Storage for deposits (ERC-20 and ERC-721).
    *   Mapping deposits to their release conditions, recipients, state, and entangled group.
    *   Storage for required oracle data points and current provided data.
    *   Mapping for trusted oracle reporters.
    *   Functions for depositing, setting conditions, managing recipients, creating/revoking entanglement, providing oracle data, triggering collapse, claiming assets, and managing roles/state.

**Function Summary:**

1.  `constructor()`: Deploys the contract, setting the initial owner.
2.  `depositERC20(address token, uint256 amount)`: Allows a user to deposit ERC-20 tokens into a new Superposed state. Requires prior approval.
3.  `depositERC721(address token, uint256 tokenId)`: Allows a user to deposit an ERC-721 token into a new Superposed state. Requires prior approval/transfer.
4.  `setERC20ReleaseConditions(uint256 depositId, uint64 unlockTime, bytes32[] requiredOracleDataKeys, uint256[] requiredOracleDataValues)`: Defines the conditions for an ERC-20 deposit's collapse: a future timestamp, and specific key-value pairs from provided oracle data. Can only be set once by the depositor.
5.  `setERC721ReleaseConditions(uint256 depositId, uint64 unlockTime, bytes32[] requiredOracleDataKeys, uint256[] requiredOracleDataValues)`: Defines release conditions for an ERC-721 deposit (similar to ERC-20). Can only be set once by the depositor.
6.  `addRecipient(uint256 depositId, address recipient, uint256 sharePercent)`: Adds a recipient and their percentage share (out of 10000) for a deposit upon collapse. Can only be set by the depositor before conditions are fully met.
7.  `removeRecipient(uint256 depositId, address recipient)`: Removes a recipient from a deposit. Can only be done by the depositor before conditions are fully met.
8.  `entangleDeposits(uint256[] depositIds)`: Links the collapse conditions of a group of deposits. All deposits in an entangled group must have their individual conditions met *and* the entangled group conditions met for *any* of them to collapse. Can only be done by the owner of all listed deposits.
9.  `revokeEntanglement(uint256 depositId)`: Removes a deposit from its entangled group. Can only be done by the deposit owner if the group hasn't collapsed.
10. `addTrustedOracleReporter(address reporter)`: Grants an address the role to provide oracle data. Owner only.
11. `removeTrustedOracleReporter(address reporter)`: Revokes the oracle reporter role. Owner only.
12. `provideOracleData(bytes32 key, uint256 value)`: Allows a trusted oracle reporter to submit a piece of data (key-value pair). This data can potentially fulfill conditions for collapse.
13. `mutateCondition(uint256 depositId, bytes32 oracleKey, uint256 newValue)`: Allows the depositor (under predefined rules, e.g., before unlock time) to change a required oracle data value for a condition. Adds a "dynamic" or "unpredictable" element before collapse.
14. `triggerCollapse(uint256 depositId)`: A public function allowing anyone to attempt to trigger the collapse of a deposit (and its entangled group, if applicable). Checks if all conditions are met. If true, executes the collapse and transfers assets. Includes a small incentive (e.g., native token reward, or a small fee deduction) for the triggerer (not implemented in this draft for simplicity, but a common pattern).
15. `claimAssets(uint256[] collapsedDepositIds)`: Allows a designated recipient to claim their share from multiple deposits that have successfully collapsed.
16. `cancelSuperposition(uint256 depositId)`: Allows the original depositor to cancel a deposit before its conditions are met and before it's part of a collapsed group. Assets are returned to the depositor. May include a penalty or time limit.
17. `getDepositState(uint256 depositId)`: Returns the current state of a deposit (Superposed, ConditionsSet, Collapsing, Collapsed, Cancelled, Entangled).
18. `getDepositConditions(uint256 depositId)`: Returns the set release conditions (unlock time, required oracle data) for a deposit.
19. `getDepositRecipients(uint256 depositId)`: Returns the list of recipients and their shares for a deposit.
20. `getEntangledGroup(uint256 depositId)`: Returns the list of deposit IDs entangled with the given deposit.
21. `getProvidedOracleData(bytes32 key)`: Returns the most recently provided oracle data for a given key.
22. `isTrustedOracleReporter(address reporter)`: Checks if an address has the trusted oracle reporter role.
23. `getTotalDeposits()`: Returns the total number of deposits ever created in the vault.
24. `getDepositAssetDetails(uint256 depositId)`: Returns the asset type (ERC20/ERC721), token address, and amount/tokenId for a deposit.
25. `getRecipientClaimableAmount(address recipient, uint256 depositId)`: Calculates the amount/tokenId a specific recipient can claim from a collapsed deposit. (Internal calculation exposed).
26. `renounceOwnership()`: Relinquishes ownership of the contract.
27. `transferOwnership(address newOwner)`: Transfers ownership of the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumVault
 * @dev A smart contract modeling conditional asset release using quantum analogies.
 * Assets (ERC-20, ERC-721) are deposited into a "Superposed" state.
 * Release ("Collapse") is triggered when multiple conditions (time, oracle data, entanglement) are met.
 * Supports conditional mutability of conditions and external data feeds via trusted reporters.
 */
contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    // --- Structs ---

    enum DepositState {
        Superposed,         // Initial state, no conditions set
        ConditionsSet,      // Conditions defined, waiting for collapse
        Entangled,          // Linked with other deposits, waiting for group collapse
        Collapsing,         // Conditions met, pending execution (internal state)
        Collapsed,          // Assets released to recipients
        Cancelled           // Deposit cancelled by owner before collapse
    }

    enum AssetType {
        ERC20,
        ERC721
    }

    struct Recipient {
        address addr;
        uint256 sharePercent; // Percentage out of 10000 (e.g., 1% = 100)
        bool claimed;
    }

    struct Condition {
        uint64 unlockTime;
        bytes32[] requiredOracleDataKeys;
        uint256[] requiredOracleDataValues;
        // Future: Could add conditions based on other contract states, event emissions, etc.
    }

    struct Deposit {
        uint256 depositId;
        address depositor;
        AssetType assetType;
        address tokenAddress; // 0x0 for ETH (not supported in this version, ERC20/721 only)
        uint256 amountOrTokenId; // amount for ERC20, tokenId for ERC721
        DepositState state;
        Condition conditions;
        Recipient[] recipients;
        uint256 entangledGroupId; // 0 if not entangled
        uint256 totalShares; // Sum of recipient sharePercent
    }

    // --- State Variables ---

    Deposit[] public deposits;
    uint256 private nextDepositId = 1;
    uint256 private nextEntangledGroupId = 1;

    // Mapping depositId to its index in the deposits array
    mapping(uint256 => uint256) private depositIdToIndex;

    // Mapping entangledGroupId to list of depositIds
    mapping(uint256 => uint256[]) public entangledGroups;

    // Mapping of trusted addresses allowed to report oracle data
    mapping(address => bool) public trustedOracleReporters;

    // Storage for reported oracle data (key => value)
    mapping(bytes32 => uint256) public providedOracleData;

    // --- Events ---

    event DepositMade(uint256 indexed depositId, address indexed depositor, AssetType assetType, address tokenAddress, uint256 amountOrTokenId);
    event ConditionsSet(uint256 indexed depositId, uint64 unlockTime);
    event RecipientAdded(uint256 indexed depositId, address indexed recipient, uint256 sharePercent);
    event RecipientRemoved(uint256 indexed depositId, address indexed recipient);
    event DepositsEntangled(uint256 indexed entangledGroupId, uint256[] depositIds);
    event EntanglementRevoked(uint256 indexed depositId, uint256 indexed oldEntangledGroupId);
    event OracleDataProvided(bytes32 indexed key, uint256 value, address indexed reporter);
    event ConditionMutated(uint256 indexed depositId, bytes32 indexed oracleKey, uint256 newValue);
    event CollapseTriggered(uint256 indexed depositId);
    event DepositCollapsed(uint256 indexed depositId);
    event AssetsClaimed(uint256 indexed depositId, address indexed recipient, uint256 amountOrTokenId); // Emits per claim per deposit
    event DepositCancelled(uint256 indexed depositId, address indexed canceller);
    event DepositStateChanged(uint256 indexed depositId, DepositState newState);
    event TrustedOracleReporterAdded(address indexed reporter);
    event TrustedOracleReporterRemoved(address indexed reporter);

    // --- Modifiers ---

    modifier whenStateIs(uint256 _depositId, DepositState _state) {
        require(depositIdToIndex[_depositId] != 0 || _depositId == 0, "Invalid depositId");
        require(deposits[depositIdToIndex[_depositId] -1].state == _state, "Deposit state mismatch");
        _;
    }

    modifier whenStateIsNot(uint256 _depositId, DepositState _state) {
        require(depositIdToIndex[_depositId] != 0 || _depositId == 0, "Invalid depositId");
        require(deposits[depositIdToIndex[_depositId] -1].state != _state, "Deposit state mismatch");
        _;
    }

    modifier onlyDepositor(uint256 _depositId) {
        require(depositIdToIndex[_depositId] != 0 || _depositId == 0, "Invalid depositId");
        require(deposits[depositIdToIndex[_depositId] -1].depositor == msg.sender, "Not deposit depositor");
        _;
    }

    modifier onlyTrustedOracleReporter() {
        require(trustedOracleReporters[msg.sender], "Not a trusted oracle reporter");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Core Functionality ---

    /**
     * @dev Deposits ERC-20 tokens into a new Superposed state.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentDepositId = nextDepositId++;
        depositIdToIndex[currentDepositId] = deposits.length + 1; // Store 1-based index
        deposits.push(Deposit({
            depositId: currentDepositId,
            depositor: msg.sender,
            assetType: AssetType.ERC20,
            tokenAddress: token,
            amountOrTokenId: amount,
            state: DepositState.Superposed,
            conditions: Condition({
                unlockTime: 0,
                requiredOracleDataKeys: new bytes32[](0),
                requiredOracleDataValues: new uint256[](0)
            }),
            recipients: new Recipient[](0),
            entangledGroupId: 0,
            totalShares: 0
        }));

        emit DepositMade(currentDepositId, msg.sender, AssetType.ERC20, token, amount);
        emit DepositStateChanged(currentDepositId, DepositState.Superposed);
    }

    /**
     * @dev Deposits an ERC-721 token into a new Superposed state.
     * @param token The address of the ERC-721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) external nonReentrant {
        IERC721 tokenContract = IERC721(token);
        // Ensure caller is owner or approved operator
        require(tokenContract.ownerOf(tokenId) == msg.sender || tokenContract.isApprovedForAll(msg.sender, address(this)), "Caller not owner or approved operator");
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 currentDepositId = nextDepositId++;
        depositIdToIndex[currentDepositId] = deposits.length + 1; // Store 1-based index
        deposits.push(Deposit({
            depositId: currentDepositId,
            depositor: msg.sender,
            assetType: AssetType.ERC721,
            tokenAddress: token,
            amountOrTokenId: tokenId,
            state: DepositState.Superposed,
            conditions: Condition({
                unlockTime: 0,
                requiredOracleDataKeys: new bytes32[](0),
                requiredOracleDataValues: new uint256[](0)
            }),
            recipients: new Recipient[](0),
            entangledGroupId: 0,
            totalShares: 0
        }));

        emit DepositMade(currentDepositId, msg.sender, AssetType.ERC721, token, tokenId);
        emit DepositStateChanged(currentDepositId, DepositState.Superposed);
    }

    /**
     * @dev Sets the release conditions for an ERC-20 deposit. Can only be called once by the depositor.
     * Transitions state from Superposed to ConditionsSet.
     * @param depositId The ID of the deposit.
     * @param unlockTime The timestamp after which the deposit can collapse.
     * @param requiredOracleDataKeys The keys of oracle data required for collapse.
     * @param requiredOracleDataValues The required values corresponding to the keys.
     */
    function setERC20ReleaseConditions(
        uint256 depositId,
        uint64 unlockTime,
        bytes32[] calldata requiredOracleDataKeys,
        uint256[] calldata requiredOracleDataValues
    )
        external
        onlyDepositor(depositId)
        whenStateIs(depositId, DepositState.Superposed)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(deposit.assetType == AssetType.ERC20, "Not an ERC20 deposit");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");
        require(requiredOracleDataKeys.length == requiredOracleDataValues.length, "Oracle data keys and values mismatch");

        deposit.conditions.unlockTime = unlockTime;
        deposit.conditions.requiredOracleDataKeys = requiredOracleDataKeys;
        deposit.conditions.requiredOracleDataValues = requiredOracleDataValues;
        deposit.state = DepositState.ConditionsSet;

        emit ConditionsSet(depositId, unlockTime);
        emit DepositStateChanged(depositId, DepositState.ConditionsSet);
    }

     /**
     * @dev Sets the release conditions for an ERC-721 deposit. Can only be called once by the depositor.
     * Transitions state from Superposed to ConditionsSet.
     * @param depositId The ID of the deposit.
     * @param unlockTime The timestamp after which the deposit can collapse.
     * @param requiredOracleDataKeys The keys of oracle data required for collapse.
     * @param requiredOracleDataValues The required values corresponding to the keys.
     */
    function setERC721ReleaseConditions(
        uint256 depositId,
        uint64 unlockTime,
        bytes32[] calldata requiredOracleDataKeys,
        uint256[] calldata requiredOracleDataValues
    )
        external
        onlyDepositor(depositId)
        whenStateIs(depositId, DepositState.Superposed)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(deposit.assetType == AssetType.ERC721, "Not an ERC721 deposit");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");
        require(requiredOracleDataKeys.length == requiredOracleDataValues.length, "Oracle data keys and values mismatch");

        deposit.conditions.unlockTime = unlockTime;
        deposit.conditions.requiredOracleDataKeys = requiredOracleDataKeys;
        deposit.conditions.requiredOracleDataValues = requiredOracleDataValues;
        deposit.state = DepositState.ConditionsSet;

        emit ConditionsSet(depositId, unlockTime);
        emit DepositStateChanged(depositId, DepositState.ConditionsSet);
    }

    /**
     * @dev Adds a recipient and their share percentage for a deposit upon collapse.
     * Can be called multiple times for the same deposit.
     * Total shares must equal 10000 before collapse.
     * @param depositId The ID of the deposit.
     * @param recipient The address of the recipient.
     * @param sharePercent The recipient's share percentage (out of 10000).
     */
    function addRecipient(uint256 depositId, address recipient, uint256 sharePercent)
        external
        onlyDepositor(depositId)
        whenStateIsNot(depositId, DepositState.Collapsed)
        whenStateIsNot(depositId, DepositState.Collapsing)
        whenStateIsNot(depositId, DepositState.Cancelled)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(recipient != address(0), "Invalid recipient address");
        require(sharePercent > 0, "Share must be > 0");

        bool found = false;
        for (uint i = 0; i < deposit.recipients.length; i++) {
            if (deposit.recipients[i].addr == recipient) {
                deposit.recipients[i].sharePercent = sharePercent;
                found = true;
                break;
            }
        }
        if (!found) {
            deposit.recipients.push(Recipient({
                addr: recipient,
                sharePercent: sharePercent,
                claimed: false
            }));
        }

        _updateTotalShares(depositId);
        emit RecipientAdded(depositId, recipient, sharePercent);
    }

    /**
     * @dev Removes a recipient from a deposit.
     * @param depositId The ID of the deposit.
     * @param recipient The address of the recipient to remove.
     */
    function removeRecipient(uint256 depositId, address recipient)
        external
        onlyDepositor(depositId)
        whenStateIsNot(depositId, DepositState.Collapsed)
        whenStateIsNot(depositId, DepositState.Collapsing)
        whenStateIsNot(depositId, DepositState.Cancelled)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(recipient != address(0), "Invalid recipient address");

        for (uint i = 0; i < deposit.recipients.length; i++) {
            if (deposit.recipients[i].addr == recipient) {
                // Simple removal by swapping with last and popping
                deposit.recipients[i] = deposit.recipients[deposit.recipients.length - 1];
                deposit.recipients.pop();
                 _updateTotalShares(depositId);
                emit RecipientRemoved(depositId, recipient);
                return; // Exit after finding and removing
            }
        }
        revert("Recipient not found");
    }

    /**
     * @dev Links the collapse conditions of a group of deposits.
     * All deposits in the group must satisfy their conditions for any to collapse.
     * All deposits must be owned by msg.sender and in ConditionsSet state.
     * @param depositIds The IDs of deposits to entangle.
     */
    function entangleDeposits(uint256[] calldata depositIds) external nonReentrant {
        require(depositIds.length >= 2, "Must entangle at least 2 deposits");
        uint256 currentEntangledGroupId = nextEntangledGroupId++;

        uint256[] memory groupDepositIds = new uint256[](depositIds.length);

        for (uint i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            uint256 depositIdx = depositIdToIndex[depositId];
            require(depositIdx != 0, "Invalid depositId in list");
            Deposit storage deposit = deposits[depositIdx - 1];

            require(deposit.depositor == msg.sender, "Caller must own all deposits");
            require(deposit.entangledGroupId == 0, "Deposit already entangled");
            // Allow entanglement from Superposed (if conditions not set) or ConditionsSet
            require(deposit.state == DepositState.Superposed || deposit.state == DepositState.ConditionsSet, "Deposits must be Superposed or ConditionsSet state");

            deposit.entangledGroupId = currentEntangledGroupId;
            groupDepositIds[i] = depositId; // Collect IDs for event/storage
            deposit.state = DepositState.Entangled; // Change state to Entangled
            emit DepositStateChanged(depositId, DepositState.Entangled);
        }

        entangledGroups[currentEntangledGroupId] = groupDepositIds;
        emit DepositsEntangled(currentEntangledGroupId, groupDepositIds);
    }

    /**
     * @dev Removes a deposit from its entangled group.
     * Returns the deposit to ConditionsSet state if conditions were already set, else Superposed.
     * Can only be done by the deposit owner if the group hasn't collapsed.
     * @param depositId The ID of the deposit to untangle.
     */
    function revokeEntanglement(uint256 depositId)
        external
        onlyDepositor(depositId)
        whenStateIs(depositId, DepositState.Entangled)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        uint256 groupId = deposit.entangledGroupId;
        require(groupId != 0, "Deposit is not entangled");

        uint256[] storage group = entangledGroups[groupId];
        require(group.length > 1, "Cannot untangle if only 1 deposit remains in group");

        // Remove depositId from the group array
        for (uint i = 0; i < group.length; i++) {
            if (group[i] == depositId) {
                 // Simple removal by swapping with last and popping
                group[i] = group[group.length - 1];
                group.pop();
                break;
            }
        }

        // If only one deposit remains after removal, untangle it too
        if (group.length == 1) {
            uint256 remainingDepositId = group[0];
            uint256 remainingDepositIdx = depositIdToIndex[remainingDepositId];
            if(remainingDepositIdx != 0) { // Ensure it still exists
                 Deposit storage remainingDeposit = deposits[remainingDepositIdx - 1];
                 remainingDeposit.entangledGroupId = 0;
                 remainingDeposit.state = remainingDeposit.conditions.unlockTime > 0 ? DepositState.ConditionsSet : DepositState.Superposed;
                 emit DepositStateChanged(remainingDepositId, remainingDeposit.state);
            }
            delete entangledGroups[groupId]; // Clean up the group entry
        }

        deposit.entangledGroupId = 0;
        deposit.state = deposit.conditions.unlockTime > 0 ? DepositState.ConditionsSet : DepositState.Superposed; // Return to ConditionsSet or Superposed
        emit EntanglementRevoked(depositId, groupId);
        emit DepositStateChanged(depositId, deposit.state);
    }


    /**
     * @dev Adds an address to the list of trusted oracle reporters.
     * @param reporter The address to add.
     */
    function addTrustedOracleReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "Invalid reporter address");
        trustedOracleReporters[reporter] = true;
        emit TrustedOracleReporterAdded(reporter);
    }

    /**
     * @dev Removes an address from the list of trusted oracle reporters.
     * @param reporter The address to remove.
     */
    function removeTrustedOracleReporter(address reporter) external onlyOwner {
        trustedOracleReporters[reporter] = false;
        emit TrustedOracleReporterRemoved(reporter);
    }

    /**
     * @dev Allows a trusted oracle reporter to submit a piece of data.
     * This data can potentially fulfill conditions for collapse.
     * @param key The key identifying the data.
     * @param value The value of the data.
     */
    function provideOracleData(bytes32 key, uint256 value) external onlyTrustedOracleReporter {
        providedOracleData[key] = value;
        emit OracleDataProvided(key, value, msg.sender);
        // Note: This function simply stores data. The triggerCollapse function
        // checks this data against conditions.
    }

    /**
     * @dev Allows the depositor to mutate a required oracle data value condition
     * under specific rules (e.g., before unlock time). Adds dynamism.
     * @param depositId The ID of the deposit.
     * @param oracleKey The key of the condition to mutate.
     * @param newValue The new required value for the key.
     */
    function mutateCondition(uint256 depositId, bytes32 oracleKey, uint256 newValue)
        external
        onlyDepositor(depositId)
        whenStateIsNot(depositId, DepositState.Collapsed)
        whenStateIsNot(depositId, DepositState.Collapsing)
        whenStateIsNot(depositId, DepositState.Cancelled)
        whenStateIsNot(depositId, DepositState.Superposed) // Must have conditions set
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(block.timestamp < deposit.conditions.unlockTime, "Cannot mutate after unlock time"); // Example rule

        bool found = false;
        for (uint i = 0; i < deposit.conditions.requiredOracleDataKeys.length; i++) {
            if (deposit.conditions.requiredOracleDataKeys[i] == oracleKey) {
                deposit.conditions.requiredOracleDataValues[i] = newValue;
                found = true;
                break;
            }
        }
        require(found, "Oracle key not found in conditions");

        emit ConditionMutated(depositId, oracleKey, newValue);
    }


    /**
     * @dev Attempts to trigger the collapse of a deposit.
     * If the deposit is entangled, it checks conditions for all deposits in the group.
     * If conditions are met for all relevant deposits, triggers collapse for the group.
     * Anyone can call this function.
     * @param depositId The ID of the deposit to attempt collapse for.
     */
    function triggerCollapse(uint256 depositId) external nonReentrant {
         uint256 depositIdx = depositIdToIndex[depositId];
         require(depositIdx != 0, "Invalid depositId");
         Deposit storage deposit = deposits[depositIdx - 1];

         require(deposit.state != DepositState.Collapsed && deposit.state != DepositState.Collapsing && deposit.state != DepositState.Cancelled, "Deposit is not in a collapsible state");

         uint256[] memory depositsToCollapse;
         if (deposit.entangledGroupId != 0) {
             // Check all deposits in the entangled group
             uint256[] storage group = entangledGroups[deposit.entangledGroupId];
             bool allConditionsMet = true;
             for (uint i = 0; i < group.length; i++) {
                 uint256 currentDepositId = group[i];
                 uint256 currentDepositIdx = depositIdToIndex[currentDepositId];
                 if(currentDepositIdx == 0 || deposits[currentDepositIdx - 1].state >= DepositState.Collapsed) {
                     // Skip if already collapsed or cancelled
                     continue;
                 }
                 if (!_checkConditions(currentDepositId)) {
                     allConditionsMet = false;
                     break;
                 }
             }

             if (allConditionsMet) {
                 // Collect deposits from the group that haven't collapsed yet
                 uint256[] memory potentialDeposits = entangledGroups[deposit.entangledGroupId];
                 uint256 collapsibleCount = 0;
                 for(uint i = 0; i < potentialDeposits.length; i++) {
                      uint256 currentDepositIdx = depositIdToIndex[potentialDeposits[i]];
                      if(currentDepositIdx != 0 && deposits[currentDepositIdx - 1].state < DepositState.Collapsed) {
                          collapsibleCount++;
                      }
                 }

                 depositsToCollapse = new uint256[](collapsibleCount);
                 uint k = 0;
                 for(uint i = 0; i < potentialDeposits.length; i++) {
                      uint256 currentDepositIdx = depositIdToIndex[potentialDeposits[i]];
                      if(currentDepositIdx != 0 && deposits[currentDepositIdx - 1].state < DepositState.Collapsed) {
                           depositsToCollapse[k++] = potentialDeposits[i];
                      }
                 }

             } else {
                 revert("Entangled group conditions not met");
             }
         } else {
             // Check condition for a single deposit
             if (_checkConditions(depositId)) {
                 depositsToCollapse = new uint256[](1);
                 depositsToCollapse[0] = depositId;
             } else {
                 revert("Deposit conditions not met");
             }
         }

         // If conditions are met (for single or group), execute collapse
         if (depositsToCollapse.length > 0) {
             for (uint i = 0; i < depositsToCollapse.length; i++) {
                 _executeCollapse(depositsToCollapse[i]);
             }
              // Could add a small reward for msg.sender here using a dedicated fee/reward system
         }
         emit CollapseTriggered(depositId); // Indicate attempt, success or failure determined by reverts or subsequent events
    }


    /**
     * @dev Allows a designated recipient to claim their share from one or more collapsed deposits.
     * @param collapsedDepositIds The IDs of the deposits to claim from.
     */
    function claimAssets(uint256[] calldata collapsedDepositIds) external nonReentrant {
        for (uint i = 0; i < collapsedDepositIds.length; i++) {
            uint256 depositId = collapsedDepositIds[i];
            uint256 depositIdx = depositIdToIndex[depositId];
            require(depositIdx != 0, "Invalid depositId in claim list");
            Deposit storage deposit = deposits[depositIdx - 1];

            require(deposit.state == DepositState.Collapsed, "Deposit not in Collapsed state");
            require(deposit.totalShares == 10000, "Deposit shares not fully distributed (pre-collapse error)");

            bool foundRecipient = false;
            for (uint j = 0; j < deposit.recipients.length; j++) {
                if (deposit.recipients[j].addr == msg.sender) {
                    require(!deposit.recipients[j].claimed, "Assets already claimed for this deposit");
                    deposit.recipients[j].claimed = true;
                    foundRecipient = true;

                    // Calculate and transfer share
                    if (deposit.assetType == AssetType.ERC20) {
                        uint256 amountToClaim = (deposit.amountOrTokenId * deposit.recipients[j].sharePercent) / 10000;
                        if (amountToClaim > 0) {
                             IERC20(deposit.tokenAddress).safeTransfer(msg.sender, amountToClaim);
                             emit AssetsClaimed(depositId, msg.sender, amountToClaim);
                        }
                    } else if (deposit.assetType == AssetType.ERC721) {
                        // ERC721 shares mean one recipient gets the token if their share is >= 10000
                        // Or, a more complex fractionalization/distribution logic would be needed
                        // For simplicity, require 10000% share for ERC721 recipient
                         require(deposit.recipients[j].sharePercent == 10000, "ERC721 can only be claimed by single 100% recipient");
                         IERC721(deposit.tokenAddress).safeTransferFrom(address(this), msg.sender, deposit.amountOrTokenId);
                         emit AssetsClaimed(depositId, msg.sender, deposit.amountOrTokenId);
                    }
                    break; // Recipient processed for this deposit
                }
            }
            require(foundRecipient, "Caller is not a recipient for this deposit");
        }
    }

    /**
     * @dev Allows the original depositor to cancel a deposit before collapse.
     * Assets are returned. Deposit state changes to Cancelled.
     * @param depositId The ID of the deposit to cancel.
     */
    function cancelSuperposition(uint256 depositId)
        external
        onlyDepositor(depositId)
        whenStateIsNot(depositId, DepositState.Collapsed)
        whenStateIsNot(depositId, DepositState.Collapsing)
        whenStateIsNot(depositId, DepositState.Cancelled)
    {
        Deposit storage deposit = deposits[depositIdToIndex[depositId] - 1];
        require(deposit.entangledGroupId == 0, "Cannot cancel entangled deposit, revoke entanglement first");

        // Optional: Add time-based restriction or penalty here
        // require(block.timestamp < deposit.conditions.unlockTime - X days, "Too close to unlock time");
        // uint256 penaltyAmount = calculatePenalty(...);
        // transfer penalty to owner/treasury;
        // uint256 amountToReturn = deposit.amountOrTokenId - penaltyAmount;

        if (deposit.assetType == AssetType.ERC20) {
             IERC20(deposit.tokenAddress).safeTransfer(deposit.depositor, deposit.amountOrTokenId);
        } else if (deposit.assetType == AssetType.ERC721) {
             IERC721(deposit.tokenAddress).safeTransferFrom(address(this), deposit.depositor, deposit.amountOrTokenId);
        }

        deposit.state = DepositState.Cancelled;
        emit DepositCancelled(depositId, msg.sender);
        emit DepositStateChanged(depositId, DepositState.Cancelled);
    }

    // --- View/Pure Functions ---

    /**
     * @dev Returns the current state of a deposit.
     * @param depositId The ID of the deposit.
     * @return The DepositState enum value.
     */
    function getDepositState(uint256 depositId) external view returns (DepositState) {
        uint256 depositIdx = depositIdToIndex[depositId];
        require(depositIdx != 0, "Invalid depositId");
        return deposits[depositIdx - 1].state;
    }

    /**
     * @dev Returns the set release conditions for a deposit.
     * @param depositId The ID of the deposit.
     * @return unlockTime, requiredOracleDataKeys, requiredOracleDataValues
     */
    function getDepositConditions(uint256 depositId) external view returns (uint64 unlockTime, bytes32[] memory requiredOracleDataKeys, uint256[] memory requiredOracleDataValues) {
        uint256 depositIdx = depositIdToIndex[depositId];
        require(depositIdx != 0, "Invalid depositId");
        Deposit storage deposit = deposits[depositIdx - 1];
        return (deposit.conditions.unlockTime, deposit.conditions.requiredOracleDataKeys, deposit.conditions.requiredOracleDataValues);
    }

    /**
     * @dev Returns the list of recipients and their shares for a deposit.
     * @param depositId The ID of the deposit.
     * @return A tuple of arrays: recipient addresses and their share percentages.
     */
    function getDepositRecipients(uint256 depositId) external view returns (address[] memory addrs, uint256[] memory sharePercents, bool[] memory claimedStatuses) {
        uint256 depositIdx = depositIdToIndex[depositId];
        require(depositIdx != 0, "Invalid depositId");
        Deposit storage deposit = deposits[depositIdx - 1];
        uint len = deposit.recipients.length;
        addrs = new address[](len);
        sharePercents = new uint256[](len);
        claimedStatuses = new bool[](len);
        for(uint i = 0; i < len; i++) {
            addrs[i] = deposit.recipients[i].addr;
            sharePercents[i] = deposit.recipients[i].sharePercent;
            claimedStatuses[i] = deposit.recipients[i].claimed;
        }
        return (addrs, sharePercents, claimedStatuses);
    }

     /**
     * @dev Returns the list of deposit IDs entangled with the given deposit.
     * Returns an empty array if not entangled.
     * @param depositId The ID of the deposit.
     * @return An array of deposit IDs in the entangled group.
     */
    function getEntangledGroup(uint256 depositId) external view returns (uint256[] memory) {
        uint256 depositIdx = depositIdToIndex[depositId];
        require(depositIdx != 0, "Invalid depositId");
        uint256 groupId = deposits[depositIdx - 1].entangledGroupId;
        if (groupId == 0) {
            return new uint256[](0);
        }
        return entangledGroups[groupId];
    }

    /**
     * @dev Returns the most recently provided oracle data for a given key.
     * Returns 0 if no data has been provided for the key.
     * @param key The key of the oracle data.
     * @return The value of the oracle data.
     */
    function getProvidedOracleData(bytes32 key) external view returns (uint256) {
        return providedOracleData[key];
    }

    /**
     * @dev Checks if an address has the trusted oracle reporter role.
     * @param reporter The address to check.
     * @return True if the address is a trusted oracle reporter, false otherwise.
     */
    function isTrustedOracleReporter(address reporter) external view returns (bool) {
        return trustedOracleReporters[reporter];
    }

    /**
     * @dev Returns the total number of deposits ever created in the vault.
     * @return The total count of deposits.
     */
    function getTotalDeposits() external view returns (uint256) {
        return deposits.length;
    }

    /**
     * @dev Returns the asset details for a specific deposit.
     * @param depositId The ID of the deposit.
     * @return assetType, tokenAddress, amountOrTokenId
     */
    function getDepositAssetDetails(uint256 depositId) external view returns (AssetType assetType, address tokenAddress, uint256 amountOrTokenId) {
         uint256 depositIdx = depositIdToIndex[depositId];
         require(depositIdx != 0, "Invalid depositId");
         Deposit storage deposit = deposits[depositIdx - 1];
         return (deposit.assetType, deposit.tokenAddress, deposit.amountOrTokenId);
    }

     /**
     * @dev Calculates the amount/tokenId a specific recipient can claim from a collapsed deposit.
     * Does not check if they have already claimed.
     * @param recipient The address of the recipient.
     * @param depositId The ID of the deposit.
     * @return The calculated amount (for ERC20) or tokenId (for ERC721). Returns 0 if not a recipient or deposit not collapsed.
     */
    function getRecipientClaimableAmount(address recipient, uint256 depositId) external view returns (uint256) {
        uint256 depositIdx = depositIdToIndex[depositId];
        if (depositIdx == 0) return 0; // Invalid depositId

        Deposit storage deposit = deposits[depositIdx - 1];
        if (deposit.state != DepositState.Collapsed || deposit.totalShares != 10000) return 0; // Not collapsed correctly

        for (uint j = 0; j < deposit.recipients.length; j++) {
            if (deposit.recipients[j].addr == recipient) {
                 if (deposit.assetType == AssetType.ERC20) {
                    return (deposit.amountOrTokenId * deposit.recipients[j].sharePercent) / 10000;
                 } else if (deposit.assetType == AssetType.ERC721) {
                     // ERC721 shares mean one recipient gets the token if their share is >= 10000
                    return deposit.recipients[j].sharePercent == 10000 ? deposit.amountOrTokenId : 0;
                 }
                 return 0; // Should not reach here
            }
        }
        return 0; // Recipient not found
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to check if all collapse conditions are met for a single deposit.
     * @param depositId The ID of the deposit.
     * @return True if all conditions are met, false otherwise.
     */
    function _checkConditions(uint256 depositId) internal view returns (bool) {
        uint256 depositIdx = depositIdToIndex[depositId];
        if (depositIdx == 0) return false; // Should not happen if called internally with valid ID
        Deposit storage deposit = deposits[depositIdx - 1];

        if (deposit.state < DepositState.ConditionsSet || deposit.state >= DepositState.Collapsed) {
             // Must have conditions set and not already collapsed/cancelled
             return false;
        }
        if (deposit.totalShares != 10000 && deposit.assetType == AssetType.ERC20) {
            // ERC20 must have total shares == 10000 for collapse
            return false;
        }
         if (deposit.assetType == AssetType.ERC721 && deposit.totalShares != 10000) {
             // ERC721 requires a 100% recipient, so total shares must be 10000
             return false;
         }
         if (deposit.assetType == AssetType.ERC721 && deposit.recipients.length != 1) {
             // ERC721 requires exactly one recipient for simplicity in this version
             return false;
         }
          if (deposit.assetType == AssetType.ERC721 && deposit.recipients[0].sharePercent != 10000) {
              // ERC721 requires 100% share for the single recipient
              return false;
          }


        // Check Time Condition
        if (deposit.conditions.unlockTime > block.timestamp) {
            return false;
        }

        // Check Oracle Data Conditions
        require(deposit.conditions.requiredOracleDataKeys.length == deposit.conditions.requiredOracleDataValues.length, "Condition arrays mismatch"); // Should be checked on set
        for (uint i = 0; i < deposit.conditions.requiredOracleDataKeys.length; i++) {
            bytes32 key = deposit.conditions.requiredOracleDataKeys[i];
            uint256 requiredValue = deposit.conditions.requiredOracleDataValues[i];
            // Check if oracle data exists AND matches the required value
            if (providedOracleData[key] == 0 || providedOracleData[key] != requiredValue) {
                // Note: providedOracleData[key] == 0 could mean data is not yet provided OR the required value is 0.
                // A more robust system might distinguish these (e.g., check existence in another mapping).
                // Assuming 0 is not a valid required value unless specifically handled, or data is always > 0.
                 // Refined Check: require providedData[key] to be non-zero AND match value
                 if (providedOracleData[key] == 0 || providedOracleData[key] != requiredValue) {
                      return false;
                 }
            }
        }

        // If all checks pass
        return true;
    }

    /**
     * @dev Internal function to execute the collapse of a single deposit.
     * Transfers assets to recipients based on shares.
     * Changes deposit state to Collapsed.
     * @param depositId The ID of the deposit to collapse.
     */
    function _executeCollapse(uint256 depositId) internal {
        uint256 depositIdx = depositIdToIndex[depositId];
        require(depositIdx != 0, "Invalid depositId for collapse execution");
        Deposit storage deposit = deposits[depositIdx - 1];

        require(deposit.state < DepositState.Collapsed, "Deposit already collapsed or cancelled");
        require(deposit.totalShares == 10000, "Total shares must be 10000 before collapse"); // Redundant check, should be covered by _checkConditions, but safe

        deposit.state = DepositState.Collapsing; // Intermediate state

        if (deposit.assetType == AssetType.ERC20) {
            IERC20 tokenContract = IERC20(deposit.tokenAddress);
            for (uint i = 0; i < deposit.recipients.length; i++) {
                Recipient storage recipient = deposit.recipients[i];
                uint256 amountToTransfer = (deposit.amountOrTokenId * recipient.sharePercent) / 10000;
                if (amountToTransfer > 0) {
                   tokenContract.safeTransfer(recipient.addr, amountToTransfer);
                   // Mark as claimed upon transfer for simplicity in this basic claim model
                   recipient.claimed = true;
                   emit AssetsClaimed(depositId, recipient.addr, amountToTransfer);
                }
            }
        } else if (deposit.assetType == AssetType.ERC721) {
             // As per simplified logic in _checkConditions, only one recipient with 10000 share is allowed
             require(deposit.recipients.length == 1 && deposit.recipients[0].sharePercent == 10000, "ERC721 requires single 100% recipient for collapse");
             Recipient storage recipient = deposit.recipients[0];
             IERC721(deposit.tokenAddress).safeTransferFrom(address(this), recipient.addr, deposit.amountOrTokenId);
             // Mark as claimed upon transfer
             recipient.claimed = true;
             emit AssetsClaimed(depositId, recipient.addr, deposit.amountOrTokenId);
        }
        // Else if ETH: selfdestruct or payable logic (not in this version)

        deposit.state = DepositState.Collapsed;
        emit DepositCollapsed(depositId);
        emit DepositStateChanged(depositId, DepositState.Collapsed);
    }

     /**
     * @dev Internal function to recalculate total shares for a deposit.
     * @param depositId The ID of the deposit.
     */
    function _updateTotalShares(uint256 depositId) internal {
         uint256 depositIdx = depositIdToIndex[depositId];
         require(depositIdx != 0, "Invalid depositId for share update");
         Deposit storage deposit = deposits[depositIdx - 1];

         uint256 currentTotalShares = 0;
         for(uint i = 0; i < deposit.recipients.length; i++) {
             currentTotalShares += deposit.recipients[i].sharePercent;
         }
         deposit.totalShares = currentTotalShares;

         require(deposit.totalShares <= 10000, "Total shares cannot exceed 10000");
    }


    // --- Additional Utility Functions (Beyond 20, but good practice) ---

    // Allow contract to receive ERC721 tokens via safeTransferFrom
    // OpenZeppelin's SafeERC721.safeTransferFrom handles the onERC721Received call automatically
    // No explicit onERC721Received is strictly needed if using SafeERC721 in deposit function,
    // but if external parties might send, this must be implemented and return its selector.
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }

    // Allow contract to receive ERC20 tokens directly (less common without deposit function)
    // Could add a receive() or fallback() for ETH if needed, but not for ERC20.
    // ERC20 deposits rely on the depositERC20 function calling transferFrom.


}
```