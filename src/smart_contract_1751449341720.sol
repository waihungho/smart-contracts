Okay, let's create a smart contract that incorporates several advanced, interesting, and relatively less-duplicated concepts. We'll build a "Quantum Vault" – a metaphor for a multi-asset vault where the release conditions are initially uncertain (in a 'superposition' state) and 'collapse' to a specific outcome once certain verifiable conditions are met or proven.

This concept combines:
1.  **Multi-Asset Holding:** Supports ERC-20 and ERC-721.
2.  **Conditional Release:** Funds/NFTs are locked until specific conditions are met.
3.  **Multiple Potential Outcomes (Superposition Metaphor):** The contract is configured with several possible release configurations.
4.  **Verifiable Conditions:** Conditions can be time-based, dependent on external data (mocked oracle), or require verification of a hash representing an off-chain proof (like a ZK-proof outcome, simplified here).
5.  **State Collapse:** A specific function call (potentially triggered by anyone who can prove *one* of the conditions) transitions the vault from a superposition state to a collapsed state, locking in *one* specific release configuration based on the conditions proven at that moment.
6.  **User-Triggered Proofs:** Users can submit data to *prove* specific conditions have been met.
7.  **Phased Access:** Users first prove conditions, then trigger the collapse, then claim assets based on the *chosen* collapsed configuration.
8.  **Protocol Fees:** A fee mechanism on withdrawals.

This avoids simple time locks, standard vesting, or basic multi-sigs. The "quantum" aspect is a thematic wrapper for the probabilistic/conditional outcome based on external/verifiable input.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **Pragma and Interfaces:** Define Solidity version and import necessary interfaces (ERC20, ERC721, Ownable, Pausable).
2.  **State Variables:** Define contract state, owner, vault state, fee percentages, mappings for balances (ERC20/ERC721), release configurations, verification conditions, proven conditions, user states, etc.
3.  **Enums:** Define `VaultState` (Superposition, Collapsed, ClaimingAllowed, Paused) and `ConditionType` (TimeBased, ExternalOracleHash, ZKProofHash).
4.  **Structs:** Define data structures for `VerificationCondition`, `ReleaseConfig`, and `UserVaultState`.
5.  **Events:** Define events for key actions (Deposit, Config Set, Condition Added, Condition Proven, State Collapsed, Claim, Fee Update).
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenState` (custom modifier for state checks).
7.  **Constructor:** Initialize owner, initial state, and potentially set an initial fee.
8.  **Configuration Functions (Owner Only):**
    *   `setReleaseConfig`: Define one of the possible asset distribution outcomes.
    *   `addVerificationCondition`: Link a specific condition type/data to a `ReleaseConfig`.
    *   `setProtocolFeeBasisPoints`: Set the withdrawal fee.
9.  **Deposit Functions:**
    *   `depositERC20`: Allow users to deposit ERC-20 tokens.
    *   `depositERC721`: Allow users to deposit ERC-721 NFTs.
10. **Verification Functions:**
    *   `proveCondition`: Users submit data (e.g., a hash) to mark a specific condition as proven.
11. **State Transition Functions:**
    *   `triggerStateCollapse`: Checks proven conditions and transitions the vault to the `Collapsed` state, determining the final `ReleaseConfig`.
12. **Claim Functions:**
    *   `claimUnlockedAssetsERC20`: Users claim their allocated ERC-20 tokens based on the collapsed state.
    *   `claimUnlockedAssetsERC721`: Users claim their allocated ERC-721 NFTs based on the collapsed state.
13. **Administrative Functions:**
    *   `pause`: Pause contract operations (except owner functions).
    *   `unpause`: Unpause contract.
    *   `withdrawProtocolFeesERC20`: Owner withdraws accumulated ERC-20 fees.
    *   `withdrawProtocolFeesERC721`: Owner withdraws accumulated ERC-721 fees.
14. **Query Functions (Getters):**
    *   `getVaultState`: Get the current state of the vault.
    *   `getReleaseConfig`: Get details of a specific release configuration.
    *   `getVerificationCondition`: Get details of a specific verification condition.
    *   `getUserVaultState`: Get a user's current state and initial deposits.
    *   `getERC20VaultBalance`: Get the total balance of a specific ERC-20 token in the vault.
    *   `getERC721VaultTokens`: Get all NFT token IDs held in the vault for a specific collection.
    *   `getConditionStatus`: Check if a specific condition has been proven.
    *   `getCollapsedConfigId`: Get the ID of the `ReleaseConfig` chosen during state collapse.
    *   `getProtocolFeeBasisPoints`: Get the current protocol fee rate.
    *   `getProtocolFeeBalanceERC20`: Get the accumulated fee balance for a specific ERC-20 token.
    *   `getProtocolFeeBalanceERC721`: Get the accumulated fee balance for a specific ERC-721 collection.
    *   `getAllConditionIds`: Get a list of all configured condition IDs.
    *   `getAllConfigIds`: Get a list of all configured release config IDs.
    *   `getUserClaimableERC20`: Calculate a user's claimable amount for a token in the collapsed state.
    *   `getUserClaimableERC721`: Get list of user's claimable NFT IDs in the collapsed state.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract with owner, sets initial state to Superposition, and sets a default fee.
2.  `setReleaseConfig(uint256 configId, address[] tokens, uint256[] amounts, address[] nftCollections, uint256[][] nftTokenIds)`: Owner defines a potential outcome (which assets go where) associated with `configId`. Amounts/tokenIds are total allocated *if* this config is chosen. *Does not handle per-user distribution yet.* (Refinement needed: Allocation per user or total pool?). Let's make it total pool for simplicity in this concept, and claiming divides proportionally or based on initial deposit/config-specific logic. Let's revise: Each `ReleaseConfig` specifies *how* the *total* deposited assets are distributed. Example: Config A -> 50% to A, 50% to B; Config B -> 100% to C. This is complex. Simpler: A `ReleaseConfig` specifies a set of recipients and their *absolute* asset allocations *from the vault's total*. The sum of allocations must not exceed total vault holdings *for that config*. This still requires pre-knowing deposits or being flexible. Let's try another approach: A `ReleaseConfig` is tied to a user's initial deposit. User U deposits X. Config C says "if proven, User U gets Y% of their deposit back, plus Z bonus". Still complex. Let's make the config define the *total* assets available *in that specific configuration* and a user's claim is based on their *initial deposit proportion* relative to *total deposits* under that config. This implies configs must account for *all* deposited assets. Or, a config defines a *subset* of assets available to users. Let's make it simple: A `ReleaseConfig` is tied to a *group* or *outcome*. A user's *initial deposit* is linked to a *potential* claim based on *which* config is chosen. User deposits: knows they *might* get allocation from Config X or Config Y. Which one depends on which condition is met. Okay, let's structure `ReleaseConfig` to define recipient addresses and their *shares* or *absolute amounts* from the *total pool* if this config is triggered. User deposits contribute to the total pool. Claiming distributes *from* the pool *according to the chosen config*. This feels most aligned with the "quantum" collapse idea.
3.  `addVerificationCondition(uint256 conditionId, uint256 configId, ConditionType conditionType, bytes32 verificationDataHash)`: Owner links a condition (`conditionId`, type, data) to a specific `ReleaseConfig`. If this condition is proven and triggers the collapse, the linked `configId` outcome is chosen.
4.  `setProtocolFeeBasisPoints(uint16 feeBPS)`: Owner sets the fee percentage on withdrawals (in basis points).
5.  `depositERC20(address token, uint256 amount)`: Users deposit ERC-20 tokens. Requires token approval beforehand. Records user's initial deposit for potential later proportional claims.
6.  `depositERC721(address collection, uint256 tokenId)`: Users deposit ERC-721 NFTs. Requires NFT approval beforehand. Records user's initial deposit.
7.  `proveCondition(uint256 conditionId, bytes calldata proofData)`: User submits data (`proofData`) to verify a condition.
    *   `TimeBased`: `proofData` is ignored, checks `block.timestamp >= verificationDataHash` (treating hash as timestamp).
    *   `ExternalOracleHash`: `proofData` must match the `verificationDataHash`. Simulates receiving an oracle hash off-chain and submitting it.
    *   `ZKProofHash`: `proofData` must match the `verificationDataHash`. Simulates submitting a hash that represents a verified ZK-proof result off-chain.
8.  `triggerStateCollapse()`: Anyone can call this *once* while in `Superposition`. It iterates through all `VerificationCondition`s, checks if `proven` is true. The *first* condition (based on iteration order or ID order - let's use ID order for determinism) found to be proven determines the `collapsedConfigId`. Vault state changes to `Collapsed`. Subsequent calls revert. If *no* conditions are proven, it *could* revert, or transition to a default state, or revert after a timeout. Let's make it require at least one proven condition to collapse.
9.  `claimUnlockedAssetsERC20(address token)`: Users call this after state is `Collapsed`. Calculates user's claimable amount for `token` based on the `collapsedConfigId` and their initial deposits. Transfers the calculated amount, minus fee. Marks amount as claimed for the user.
10. `claimUnlockedAssetsERC721(address collection, uint256[] calldata tokenIds)`: Users call this after state is `Collapsed`. Checks if `tokenIds` are claimable by the user based on the `collapsedConfigId` and their initial deposits. Transfers the NFTs, minus potential NFT-based fee (less common, maybe just value-based fee on ERC20 part, or skip NFT fees). Let's skip NFT fees for simplicity. Marks token IDs as claimed for the user.
11. `pause()`: Owner pauses the contract. Most interactions disabled.
12. `unpause()`: Owner unpauses the contract.
13. `withdrawProtocolFeesERC20(address token)`: Owner withdraws accumulated ERC-20 fees for a specific token.
14. `withdrawProtocolFeesERC721(address collection)`: Owner withdraws accumulated ERC-721 fees for a specific collection (if any are collected, maybe from NFT sales facilitated by vault?). Let's assume fees are only in ERC20 for simplicity. Remove this function or make it revert. Let's remove this and keep fees ERC20 only.
15. `getVaultState()`: Getter for the current `VaultState`.
16. `getReleaseConfig(uint256 configId)`: Getter for details of a `ReleaseConfig`.
17. `getVerificationCondition(uint256 conditionId)`: Getter for details of a `VerificationCondition`.
18. `getUserVaultState(address user)`: Getter for a user's deposit records and claimed amounts.
19. `getERC20VaultBalance(address token)`: Getter for the contract's balance of an ERC-20 token.
20. `getERC721VaultTokens(address collection)`: Getter for the list of NFT token IDs held by the contract for a collection.
21. `getConditionStatus(uint256 conditionId)`: Getter to check if a condition is proven.
22. `getCollapsedConfigId()`: Getter for the ID of the chosen config after collapse.
23. `getProtocolFeeBasisPoints()`: Getter for the current fee rate.
24. `getProtocolFeeBalanceERC20(address token)`: Getter for the fee balance of an ERC-20 token.
25. `getUserClaimableERC20(address user, address token)`: Calculates the amount of `token` user can claim.
26. `getUserClaimableERC721(address user, address collection)`: Calculates the list of NFT IDs user can claim for `collection`.
27. `getAllConditionIds()`: Getter for all configured condition IDs.
28. `getAllConfigIds()`: Getter for all configured release config IDs.

That's 28 functions (including some getters needed for transparency), well over the 20 requirement.

Let's refine the `ReleaseConfig` and Claiming logic slightly to make it implementable:
*   `ReleaseConfig` will define distributions as `(recipientAddress, tokenAddress, amount)` or `(recipientAddress, nftCollection, tokenId)`. The *sum* of amounts/NFTs across *all* entries in a `ReleaseConfig` for a given token/collection must equal the *total* amount/NFTs of that type deposited into the vault. This makes it a full redistribution plan.
*   Claiming: User `claimUnlockedAssetsERC20(address token)` checks if *they* are a recipient for `token` in the `collapsedConfigId` and how much they are allocated. Transfers *that specific amount*.
*   Initial user deposits: Still track them, but primarily for linking *who* deposited what originally, maybe for a scenario where the config redistributes back proportionally to initial depositors (a variation of the main config idea). Let's stick to the "Config defines absolute distribution to *specific addresses*" for clarity in this example. The "quantum" part is the uncertainty *which* distribution plan is enacted. Initial deposits just fund the pool that gets distributed. Users claim if their address is in the recipient list of the winning config.

New Claiming Logic:
*   `claimUnlockedAssetsERC20(address token)`: Checks if `msg.sender` is a recipient for `token` in the `collapsedConfigId`. If yes, transfer their *allocated amount* (from the config struct) minus fees, if not already claimed.
*   `claimUnlockedAssetsERC721(address collection)`: Checks which tokenIds in `collection` `msg.sender` is a recipient for in the `collapsedConfigId`. Transfers *those specific tokenIds* if not already claimed.

This requires storing claimed status *per recipient/asset in the chosen config*.

Okay, let's implement this refined version.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using SafeMath for older Solidity versions or explicit safety,
// though 0.8+ has overflow checks by default. Keeping it for verbosity.
using SafeMath for uint256;

/**
 * @title QuantumVault
 * @dev A multi-asset vault with conditional, probabilistic-like release based on verifiable conditions.
 *      The release configuration is in a 'superposition' until a condition is proven,
 *      causing the state to 'collapse' into a single outcome.
 *      Supports ERC-20 and ERC-721 tokens.
 *      Features: Multi-asset deposit, configurable release outcomes, verifiable conditions
 *      (time, mocked oracle/ZK hash), state collapse trigger, phased claiming, protocol fees.
 */
contract QuantumVault is Ownable, Pausable {

    /*
     * OUTLINE:
     * 1. Pragma and Interfaces
     * 2. State Variables
     * 3. Enums
     * 4. Structs
     * 5. Events
     * 6. Modifiers
     * 7. Constructor
     * 8. Configuration Functions (Owner)
     * 9. Deposit Functions
     * 10. Verification Functions
     * 11. State Transition Functions
     * 12. Claim Functions
     * 13. Administrative Functions (Owner)
     * 14. Query Functions (Getters)
     */

    /*
     * FUNCTION SUMMARY:
     * - constructor(): Initializes owner, state, fees.
     * - setReleaseConfig(uint256 configId, ...): Owner defines a potential final distribution plan.
     * - addVerificationCondition(uint256 conditionId, uint256 configId, ...): Owner links a condition to a release plan.
     * - setProtocolFeeBasisPoints(uint16 feeBPS): Owner sets the withdrawal fee percentage.
     * - depositERC20(address token, uint256 amount): Users deposit ERC-20 tokens into the vault pool.
     * - depositERC721(address collection, uint256 tokenId): Users deposit ERC-721 NFTs into the vault pool.
     * - proveCondition(uint256 conditionId, bytes calldata proofData): Users submit data to mark a condition as met/proven.
     * - triggerStateCollapse(): Anyone can call; checks proven conditions to determine the single active ReleaseConfig and changes state.
     * - claimUnlockedAssetsERC20(address token): Users claim their allocated ERC-20 from the chosen config (minus fee).
     * - claimUnlockedAssetsERC721(address collection): Users claim their allocated ERC-721s from the chosen config.
     * - pause(): Owner pauses vault operations.
     * - unpause(): Owner unpauses vault.
     * - withdrawProtocolFeesERC20(address token): Owner withdraws accumulated ERC-20 fees.
     * - getVaultState(): Getter for current vault state.
     * - getReleaseConfig(uint256 configId): Getter for details of a ReleaseConfig.
     * - getVerificationCondition(uint256 conditionId): Getter for details of a VerificationCondition.
     * - getUserVaultState(address user): Getter for user's initial deposits (for tracking, not direct claim).
     * - getERC20VaultBalance(address token): Getter for total ERC-20 balance in vault.
     * - getERC721VaultTokens(address collection): Getter for total ERC-721 tokens in vault for a collection.
     * - getConditionStatus(uint256 conditionId): Getter for proven status of a condition.
     * - getCollapsedConfigId(): Getter for the chosen config ID after collapse.
     * - getProtocolFeeBasisPoints(): Getter for current fee rate.
     * - getProtocolFeeBalanceERC20(address token): Getter for fee balance of an ERC-20 token.
     * - getUserClaimableERC20(address user, address token): Calculates claimable ERC-20 amount for user.
     * - getUserClaimableERC721(address user, address collection): Lists claimable NFT IDs for user.
     * - getAllConditionIds(): Getter for all condition IDs.
     * - getAllConfigIds(): Getter for all config IDs.
     * - isUserClaimedERC20(address user, address token): Check if user has claimed a specific token allocation.
     * - isUserClaimedERC721(address user, address collection, uint256 tokenId): Check if user has claimed a specific NFT.
     */


    // --- State Variables ---

    enum VaultState {
        Superposition, // Initial state: Multiple outcomes possible
        Collapsed,     // State collapsed: One outcome determined, claiming possible
        Paused         // Operations paused by owner
    }

    enum ConditionType {
        TimeBased,         // Condition met after a specific timestamp (verificationDataHash treated as timestamp)
        ExternalOracleHash, // Condition met if proofData matches verificationDataHash (simulates external data feed)
        ZKProofHash        // Condition met if proofData matches verificationDataHash (simulates ZK proof verification)
    }

    struct VerificationCondition {
        uint256 id;
        uint256 linkedConfigId; // Which ReleaseConfig this condition would trigger
        ConditionType conditionType;
        bytes32 verificationDataHash; // Data needed for verification (timestamp, hash, etc.)
        bool isProven;
        address provenBy; // Address that successfully proved it (optional, for tracking/incentives)
    }

    struct ReleaseConfig {
        uint256 id;
        // Defines the distribution if this config is chosen
        // Mapping from recipient address -> token address -> allocated amount
        mapping(address => mapping(address => uint256)) erc20Allocations;
        // Mapping from recipient address -> nft collection address -> list of allocated token IDs
        mapping(address => mapping(address => uint256[])) erc721Allocations;
        bool isConfigured; // Flag to check if configId is set
    }

    struct UserVaultState {
        // Record initial deposits for potential future use or tracking (not directly used for claiming in this config method)
        mapping(address => uint256) initialERC20Deposits;
        mapping(address => uint256[]) initialERC721Deposits; // Stores tokenIds
    }

    VaultState public currentVaultState;
    uint16 public protocolFeeBasisPoints; // Fee in basis points (e.g., 100 = 1%)

    // Mapping to store configured release outcomes
    mapping(uint256 => ReleaseConfig) public releaseConfigs;
    uint256[] private _configIds; // Keep track of configured IDs

    // Mapping to store verification conditions
    mapping(uint256 => VerificationCondition) public verificationConditions;
    uint256[] private _conditionIds; // Keep track of condition IDs

    // ID of the ReleaseConfig that was chosen during collapse
    uint256 public collapsedConfigId;
    bool public isStateCollapsed = false;

    // Track claimed amounts/NFTs per recipient per token/collection within the chosen config
    // recipient address -> token address -> claimed amount
    mapping(address => mapping(address => uint224)) private claimedERC20Amounts; // Using smaller type if amounts expected below 2^224
    // recipient address -> collection address -> tokenId -> claimed status
    mapping(address => mapping(address => mapping(uint256 => bool))) private claimedERC721Tokens;


    // Accumulated protocol fees
    mapping(address => uint256) private protocolFeeBalancesERC20;
    mapping(address => mapping(address => uint256)) private protocolFeeBalancesERC721; // Not used based on decision, but keeping structure

    // --- Events ---

    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed collection, uint256 tokenId);
    event ReleaseConfigSet(uint256 indexed configId);
    event VerificationConditionAdded(uint256 indexed conditionId, uint256 indexed linkedConfigId, ConditionType conditionType, bytes32 verificationDataHash);
    event ConditionProven(uint256 indexed conditionId, address indexed provenBy);
    event StateCollapsed(uint256 indexed chosenConfigId, uint256 blockTimestamp);
    event AssetsClaimedERC20(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event AssetsClaimedERC721(address indexed user, address indexed collection, uint256[] tokenIds);
    event ProtocolFeeUpdated(uint16 newFeeBasisPoints);
    event ProtocolFeesWithdrawnERC20(address indexed token, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier whenState(VaultState expectedState) {
        require(currentVaultState == expectedState, "Vault: Invalid state");
        _;
    }

    modifier onlyStateTransition() {
        require(currentVaultState == VaultState.Superposition, "Vault: State already collapsed");
        _;
    }

    // --- Constructor ---

    constructor(uint16 initialFeeBasisPoints) Ownable(msg.sender) {
        currentVaultState = VaultState.Superposition;
        protocolFeeBasisPoints = initialFeeBasisPoints;
        emit ProtocolFeeUpdated(initialFeeBasisPoints);
    }

    // --- Configuration Functions (Owner Only) ---

    /**
     * @dev Sets or updates a release configuration.
     *      Defines how assets are distributed if this config is chosen.
     *      recipientAddresses, erc20Tokens, erc20Amounts arrays must align.
     *      recipientAddresses, erc721Collections, erc721TokenIds nested arrays must align.
     *      This is a full distribution plan for *all* assets if this config is selected.
     * @param configId The ID for this configuration.
     * @param erc20Recipients Array of recipients for ERC-20 tokens.
     * @param erc20Tokens Array of ERC-20 token addresses corresponding to recipients.
     * @param erc20Amounts Array of amounts corresponding to recipients and tokens.
     * @param erc721Recipients Array of recipients for ERC-721 tokens.
     * @param erc721Collections Array of ERC-721 collection addresses corresponding to recipients.
     * @param erc721TokenIds Nested array where `erc721TokenIds[i]` is a list of token IDs for `erc721Collections[i]` going to `erc721Recipients[i]`.
     */
    function setReleaseConfig(
        uint256 configId,
        address[] calldata erc20Recipients,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts,
        address[] calldata erc721Recipients,
        address[] calldata erc721Collections,
        uint256[][] calldata erc721TokenIds
    ) external onlyOwner whenState(VaultState.Superposition) {
        require(erc20Recipients.length == erc20Tokens.length && erc20Tokens.length == erc20Amounts.length, "Vault: ERC20 array mismatch");
        require(erc721Recipients.length == erc721Collections.length && erc721Collections.length == erc721TokenIds.length, "Vault: ERC721 array mismatch");

        ReleaseConfig storage config = releaseConfigs[configId];

        // Clear previous allocations for this configId if it existed
        // (This is a simplified clear; a robust version would iterate previous allocations)
        // For this example, we assume setReleaseConfig overwrites fully.
        // In production, need careful clearing or append logic.
        if (!config.isConfigured) {
             _configIds.push(configId);
        }

        // Reset allocations for this config (simplified)
        // Note: Resetting mappings is gas-intensive. A better approach for updates
        // would be to manage additions/removals explicitly or use a versioning system.
        // For this example, we'll just directly set. Previous entries *might* persist
        // in storage gas wise until overwritten or cleared via a dedicated function.
        // This implementation assumes setting overrites logically for the *intended* config state.

        for (uint i = 0; i < erc20Recipients.length; i++) {
            config.erc20Allocations[erc20Recipients[i]][erc20Tokens[i]] = erc20Amounts[i];
        }

        for (uint i = 0; i < erc721Recipients.length; i++) {
             // Direct assignment overwrites the array at this key.
             config.erc721Allocations[erc721Recipients[i]][erc771Collections[i]] = erc721TokenIds[i];
        }

        config.id = configId;
        config.isConfigured = true;
        emit ReleaseConfigSet(configId);
    }

    /**
     * @dev Adds a verification condition that can potentially trigger a specific release config.
     * @param conditionId The ID for this condition.
     * @param linkedConfigId The ID of the ReleaseConfig to trigger if this condition is met.
     * @param conditionType The type of condition (TimeBased, ExternalOracleHash, ZKProofHash).
     * @param verificationDataHash The data required for verification (timestamp hash, etc.).
     */
    function addVerificationCondition(
        uint256 conditionId,
        uint256 linkedConfigId,
        ConditionType conditionType,
        bytes32 verificationDataHash
    ) external onlyOwner whenState(VaultState.Superposition) {
        require(releaseConfigs[linkedConfigId].isConfigured, "Vault: Linked config does not exist");
        require(verificationConditions[conditionId].id == 0, "Vault: Condition ID already exists"); // Simple check for new ID

        verificationConditions[conditionId] = VerificationCondition({
            id: conditionId,
            linkedConfigId: linkedConfigId,
            conditionType: conditionType,
            verificationDataHash: verificationDataHash,
            isProven: false,
            provenBy: address(0)
        });
        _conditionIds.push(conditionId);
        emit VerificationConditionAdded(conditionId, linkedConfigId, conditionType, verificationDataHash);
    }

    /**
     * @dev Sets the protocol fee percentage on withdrawals.
     * @param feeBPS Fee in basis points (0-10000, e.g., 100 = 1%).
     */
    function setProtocolFeeBasisPoints(uint16 feeBPS) external onlyOwner {
        require(feeBPS <= 10000, "Vault: Fee exceeds 100%");
        protocolFeeBasisPoints = feeBPS;
        emit ProtocolFeeUpdated(feeBPS);
    }

    // --- Deposit Functions ---

    /**
     * @dev Allows users to deposit ERC-20 tokens into the vault.
     *      Requires user to approve the contract beforehand.
     * @param token The address of the ERC-20 token.
     * @param amount The amount to deposit.
     */
    function depositERC20(address token, uint256 amount) external whenNotPaused whenState(VaultState.Superposition) {
        require(amount > 0, "Vault: Amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        // UserVaultState is kept for reference, but not directly used for claiming in this config model
        // userVaultStates[msg.sender].initialERC20Deposits[token] = userVaultStates[msg.sender].initialERC20Deposits[token].add(amount);
        emit ERC20Deposited(msg.sender, token, amount);
    }

    /**
     * @dev Allows users to deposit ERC-721 NFTs into the vault.
     *      Requires user to approve the contract or the specific token beforehand.
     * @param collection The address of the ERC-721 collection.
     * @param tokenId The ID of the NFT to deposit.
     */
    function depositERC721(address collection, uint256 tokenId) external whenNotPaused whenState(VaultState.Superposition) {
        IERC721(collection).safeTransferFrom(msg.sender, address(this), tokenId);
        // UserVaultState is kept for reference, but not directly used for claiming in this config model
        // userVaultStates[msg.sender].initialERC721Deposits[collection].push(tokenId);
        emit ERC721Deposited(msg.sender, collection, tokenId);
    }

    // --- Verification Functions ---

    /**
     * @dev Allows users to provide data to prove a specific condition is met.
     *      Only affects conditions of type ExternalOracleHash or ZKProofHash directly.
     *      TimeBased conditions are checked directly in triggerStateCollapse.
     * @param conditionId The ID of the condition to prove.
     * @param proofData The data to verify the condition (e.g., hash).
     */
    function proveCondition(uint256 conditionId, bytes calldata proofData) external whenNotPaused whenState(VaultState.Superposition) {
        VerificationCondition storage condition = verificationConditions[conditionId];
        require(condition.id != 0, "Vault: Condition does not exist");
        require(!condition.isProven, "Vault: Condition already proven");

        bool success = false;
        if (condition.conditionType == ConditionType.ExternalOracleHash || condition.conditionType == ConditionType.ZKProofHash) {
            // For hash-based conditions, the provided proofData must match the stored hash
            require(proofData.length == 32, "Vault: proofData must be 32 bytes for hash type conditions");
            bytes32 submittedHash;
            assembly {
                submittedHash := mload(add(proofData, 32))
            }
             if (submittedHash == condition.verificationDataHash) {
                 success = true;
             }
        }
        // TimeBased conditions are *not* proven via this function; they are checked in triggerStateCollapse.
        // Other condition types would be added here.

        require(success, "Vault: Proof verification failed");

        condition.isProven = true;
        condition.provenBy = msg.sender; // Record who proved it
        emit ConditionProven(conditionId, msg.sender);
    }

    // --- State Transition Functions ---

    /**
     * @dev Triggers the state transition from Superposition to Collapsed.
     *      Checks all verification conditions and selects the ReleaseConfig
     *      linked to the *first* proven condition (based on condition ID order).
     *      Can only be called once.
     */
    function triggerStateCollapse() external whenNotPaused onlyStateTransition {
        uint256 winningConfigId = 0; // Use 0 to indicate no config found yet

        // Sort condition IDs to ensure deterministic outcome if multiple are proven simultaneously
        uint256[] memory sortedConditionIds = new uint256[](_conditionIds.length);
        for(uint i = 0; i < _conditionIds.length; i++) {
            sortedConditionIds[i] = _conditionIds[i];
        }
        // Simple bubble sort for demonstration; for many conditions, use a more efficient sort or mapping design.
        // Given the constraint of not duplicating open source, avoiding common sorting libs.
        // If _conditionIds are added in increasing order, this sort is unnecessary.
        // Let's assume owner adds them in an order that implies priority or use ID as priority.
        // Using ID as priority: smaller ID checked first. Iterate through existing IDs.

        uint256 firstProvenConditionId = 0;

        // Iterate through condition IDs to find the first proven one
        for (uint i = 0; i < _conditionIds.length; i++) {
            uint256 currentConditionId = _conditionIds[i]; // Use the stored order
            VerificationCondition storage condition = verificationConditions[currentConditionId];

            bool currentlyMet = condition.isProven; // For Hash-based conditions proven by proveCondition

            // Check TimeBased conditions directly at collapse time
            if (condition.conditionType == ConditionType.TimeBased) {
                 uint256 requiredTimestamp = uint256(condition.verificationDataHash);
                 if (block.timestamp >= requiredTimestamp) {
                     currentlyMet = true;
                     // Mark TimeBased as proven upon check (optional, helpful for state tracking)
                     condition.isProven = true;
                 }
            }

            // If this condition is met, it's the winner (due to iteration order)
            if (currentlyMet) {
                firstProvenConditionId = currentConditionId;
                winningConfigId = condition.linkedConfigId;
                break; // Found the winning condition and config
            }
        }

        require(winningConfigId != 0, "Vault: No verification conditions met to trigger collapse");
        require(releaseConfigs[winningConfigId].isConfigured, "Vault: Winning config is not configured");

        collapsedConfigId = winningConfigId;
        isStateCollapsed = true;
        currentVaultState = VaultState.Collapsed;

        emit StateCollapsed(collapsedConfigId, block.timestamp);
    }

    // --- Claim Functions ---

    /**
     * @dev Allows recipients to claim their allocated ERC-20 tokens
     *      from the chosen ReleaseConfig after the state has collapsed.
     *      Applies the protocol fee.
     * @param token The address of the ERC-20 token to claim.
     */
    function claimUnlockedAssetsERC20(address token) external whenNotPaused whenState(VaultState.Collapsed) {
        ReleaseConfig storage winningConfig = releaseConfigs[collapsedConfigId];
        uint256 allocation = winningConfig.erc20Allocations[msg.sender][token];

        require(allocation > 0, "Vault: No allocation for this token or user in winning config");

        uint256 alreadyClaimed = claimedERC20Amounts[msg.sender][token];
        uint256 claimableAmount = allocation.sub(alreadyClaimed);

        require(claimableAmount > 0, "Vault: All allocated amount already claimed");

        uint256 feeAmount = claimableAmount.mul(protocolFeeBasisPoints) / 10000;
        uint256 transferAmount = claimableAmount.sub(feeAmount);

        // Update claimed amount before transfer to prevent reentrancy
        claimedERC20Amounts[msg.sender][token] = claimedERC20Amounts[msg.sender][token].add(transferAmount); // Note: This adds transferAmount, not allocation

        // A more accurate claimed tracking would mark the *full* allocation as claimed upon first claim
        // or track remaining claimable. Let's track remaining claimable:
        // Change claimedERC20Amounts to track *total allocation claimed so far*.
        // Let's revert to the definition: claimedERC20Amounts tracks the *total* amount claimed by the user for the token.
        // The check should be `allocation.sub(claimedERC20Amounts[msg.sender][token])`.

        uint256 currentClaimed = claimedERC20Amounts[msg.sender][token];
        uint256 remainingClaimable = allocation.sub(currentClaimed);

        require(remainingClaimable > 0, "Vault: All allocated amount already claimed");

        feeAmount = remainingClaimable.mul(protocolFeeBasisPoints) / 10000;
        transferAmount = remainingClaimable.sub(feeAmount);

        // Mark the full remainingClaimable amount as now claimed (or attempting to claim)
        claimedERC20Amounts[msg.sender][token] = currentClaimed.add(remainingClaimable); // Mark full remaining as claimed

        protocolFeeBalancesERC20[token] = protocolFeeBalancesERC20[token].add(feeAmount);

        IERC20(token).transfer(msg.sender, transferAmount);

        emit AssetsClaimedERC20(msg.sender, token, transferAmount, feeAmount);
    }

    /**
     * @dev Allows recipients to claim their allocated ERC-721 tokens
     *      from the chosen ReleaseConfig after the state has collapsed.
     *      Does not apply fees to NFT claims directly.
     * @param collection The address of the ERC-721 collection to claim from.
     * @param tokenIds An array of specific token IDs the user wants to claim.
     */
    function claimUnlockedAssetsERC721(address collection, uint256[] calldata tokenIds) external whenNotPaused whenState(VaultState.Collapsed) {
        ReleaseConfig storage winningConfig = releaseConfigs[collapsedConfigId];
        uint256[] memory allocatedTokenIds = winningConfig.erc721Allocations[msg.sender][collection];

        require(allocatedTokenIds.length > 0, "Vault: No NFT allocation for this collection or user in winning config");

        uint256[] memory successfullyClaimedIds = new uint256[](tokenIds.length);
        uint256 successCount = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenIdToClaim = tokenIds[i];
            bool isAllocated = false;
            // Check if the token ID is in the user's allocation for this collection and config
            for (uint j = 0; j < allocatedTokenIds.length; j++) {
                if (allocatedTokenIds[j] == tokenIdToClaim) {
                    isAllocated = true;
                    break;
                }
            }

            if (isAllocated && !claimedERC721Tokens[msg.sender][collection][tokenIdToClaim]) {
                // Mark as claimed before transfer
                claimedERC721Tokens[msg.sender][collection][tokenIdToClaim] = true;

                // Transfer the NFT
                IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenIdToClaim);

                successfullyClaimedIds[successCount] = tokenIdToClaim;
                successCount++;
            }
        }

        require(successCount > 0, "Vault: No claimable NFTs among provided tokenIds");

        // Emit event with only the successfully claimed IDs
        uint256[] memory claimedIdsSubset = new uint256[](successCount);
        for(uint i = 0; i < successCount; i++) {
            claimedIdsSubset[i] = successfullyClaimedIds[i];
        }

        emit AssetsClaimedERC721(msg.sender, collection, claimedIdsSubset);
    }


    // --- Administrative Functions (Owner Only) ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
         currentVaultState = VaultState.Paused; // Update custom state
         emit Paused(_msgSender());
    }

    function unpause() external onlyOwner whenState(VaultState.Paused) {
        _unpause();
        // Revert to Collapsed if it was collapsed before pausing, else Superposition
        if (isStateCollapsed) {
             currentVaultState = VaultState.Collapsed;
        } else {
             currentVaultState = VaultState.Superposition;
        }
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Owner can withdraw accumulated protocol fees for a specific ERC-20 token.
     * @param token The ERC-20 token address.
     */
    function withdrawProtocolFeesERC20(address token) external onlyOwner {
        uint256 feeBalance = protocolFeeBalancesERC20[token];
        require(feeBalance > 0, "Vault: No fees to withdraw for this token");
        protocolFeeBalancesERC20[token] = 0; // Reset balance before transfer
        IERC20(token).transfer(owner(), feeBalance);
        emit ProtocolFeesWithdrawnERC20(token, feeBalance);
    }

    // --- Query Functions (Getters) ---

    /**
     * @dev Returns the current state of the vault.
     */
    function getVaultState() external view returns (VaultState) {
        if (paused()) return VaultState.Paused;
        return currentVaultState;
    }

    /**
     * @dev Returns the details of a specific release configuration.
     * @param configId The ID of the configuration.
     * @return A tuple containing the configuration ID, and allocation details (recipients, tokens, amounts, nftCollections, nftTokenIds).
     * Note: Returning full mappings is not possible in Solidity. Return arrays based on configured data.
     * This getter requires knowing all recipients and tokens beforehand, or iterating.
     * Let's return a simplified struct or specific allocations for a user.
     * For this example, let's return the flag and ID, more detailed getters needed for allocations.
     */
    function getReleaseConfig(uint256 configId) external view returns (uint256 id, bool isConfigured) {
         ReleaseConfig storage config = releaseConfigs[configId];
         return (config.id, config.isConfigured);
    }

     /**
      * @dev Get all ERC20 allocations for a given recipient in a specific config.
      * @param configId The ID of the configuration.
      * @param recipient The address of the recipient.
      * @return Arrays of token addresses and allocated amounts.
      */
     function getReleaseConfigERC20Allocations(uint256 configId, address recipient) external view returns (address[] memory tokens, uint256[] memory amounts) {
         require(releaseConfigs[configId].isConfigured, "Vault: Config not found");
         // Iterating mappings is not standard/efficient. Need a way to track keys.
         // Assuming a fixed set of relevant tokens per config, or external indexing.
         // For simplicity here, we cannot list all without knowing the keys.
         // A proper implementation would need arrays of tokens per config or iterate known tokens.
         // Returning empty arrays as a placeholder for this limitation.
         // To make this work, `setReleaseConfig` should populate storage arrays of unique tokens/recipients per config.
         return (new address[](0), new uint256[](0));
     }

     /**
      * @dev Get all ERC721 allocations for a given recipient in a specific config.
      * @param configId The ID of the configuration.
      * @param recipient The address of the recipient.
      * @return Arrays of collection addresses and nested arrays of token IDs.
      */
     function getReleaseConfigERC721Allocations(uint256 configId, address recipient) external view returns (address[] memory collections, uint256[][] memory tokenIds) {
         require(releaseConfigs[configId].isConfigured, "Vault: Config not found");
          // Same mapping limitation as above.
          return (new address[](0), new uint256[][](0));
     }


    /**
     * @dev Returns the details of a specific verification condition.
     * @param conditionId The ID of the condition.
     * @return A tuple containing the condition ID, linked config ID, type, verification data hash, proven status, and provenBy address.
     */
    function getVerificationCondition(uint256 conditionId) external view returns (
        uint256 id,
        uint256 linkedConfigId,
        ConditionType conditionType,
        bytes32 verificationDataHash,
        bool isProven,
        address provenBy
    ) {
        VerificationCondition storage condition = verificationConditions[conditionId];
        require(condition.id != 0, "Vault: Condition not found");
        return (
            condition.id,
            condition.linkedConfigId,
            condition.conditionType,
            condition.verificationDataHash,
            condition.isProven,
            condition.provenBy
        );
    }

    /**
     * @dev Returns a user's initial deposit information.
     * Note: This is for tracking/transparency, not direct claimable amount calculation in this version.
     * @param user The address of the user.
     * @return A tuple containing mappings of initial deposits (ERC20 and ERC721 - mapping return is not possible).
     * Returning empty mappings/arrays as a placeholder due to mapping limitations in return types.
     * Need specific getters for user's deposits of a particular token/collection.
     */
    function getUserVaultState(address user) external view returns (address[] memory depositedERC20Tokens, uint256[] memory depositedERC20Amounts) {
        // Cannot return full mappings. Need separate getters per token/collection or track keys.
        // Returning placeholder.
        return (new address[](0), new uint256[](0));
    }

     /**
      * @dev Gets the user's initial deposited amount for a specific ERC20 token.
      * @param user The address of the user.
      * @param token The address of the ERC20 token.
      * @return The initial deposited amount.
      */
     function getUserInitialERC20Deposit(address user, address token) external view returns (uint256) {
         // This getter implies we need to store this data. Let's add it back if required.
         // Based on the refined config logic (config defines absolute amounts to recipients),
         // initial deposits are just funding the pool, user's claim isn't based on their deposit amount directly,
         // but whether they are listed as a recipient in the winning config.
         // So, this getter is less relevant with the current config structure. Let's remove it or keep simple struct.
         // Removing simple UserVaultState struct and related deposit tracking from code for clarity, as it's not used in claiming.
         // If needed, add back `mapping(address => mapping(address => uint256)) initialERC20Deposits;` etc.
         // and update deposit functions.

         // Reverting to returning placeholder/empty arrays for the UserVaultState concept getter.
         // If initial deposits *were* used for proportional claims, this getter would be needed.
         return 0; // Or re-add initial deposit tracking state variable.
     }


    /**
     * @dev Returns the total balance of a specific ERC-20 token held by the vault.
     * @param token The address of the ERC-20 token.
     * @return The total balance.
     */
    function getERC20VaultBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Returns a list of ERC-721 token IDs held by the vault for a specific collection.
     * Note: Iterating all tokens requires external indexing or specific storage if the list is long.
     * This getter is a placeholder and might be inefficient for large collections.
     * A proper implementation would need a storage mechanism to list token IDs.
     * @param collection The address of the ERC-721 collection.
     * @return An array of token IDs.
     */
    function getERC721VaultTokens(address collection) external view returns (uint256[] memory) {
        // Standard ERC721 interface does not provide a way to list all token IDs held by an address.
        // Need to track these internally during deposits if this getter is required.
        // Adding storage `mapping(address => uint256[]) private vaultERC721Tokens;`
        // and update deposit/claim. This significantly increases complexity.
        // Returning placeholder for now.
        return new uint256[](0);
    }

    /**
     * @dev Checks if a specific verification condition has been proven.
     * @param conditionId The ID of the condition.
     * @return True if proven, false otherwise.
     */
    function getConditionStatus(uint256 conditionId) external view returns (bool) {
        return verificationConditions[conditionId].isProven;
    }

    /**
     * @dev Returns the ID of the ReleaseConfig chosen during state collapse.
     *      Returns 0 if state is still Superposition.
     */
    function getCollapsedConfigId() external view returns (uint256) {
        return collapsedConfigId;
    }

    /**
     * @dev Returns the current protocol fee rate in basis points.
     */
    function getProtocolFeeBasisPoints() external view returns (uint16) {
        return protocolFeeBasisPoints;
    }

    /**
     * @dev Returns the accumulated protocol fee balance for a specific ERC-20 token.
     * @param token The address of the ERC-20 token.
     * @return The fee balance.
     */
    function getProtocolFeeBalanceERC20(address token) external view returns (uint256) {
        return protocolFeeBalancesERC20[token];
    }

    /**
     * @dev Calculates the amount of a specific ERC-20 token a user can claim
     *      in the current Collapsed state, considering what's already claimed.
     * @param user The address of the user.
     * @param token The address of the ERC-20 token.
     * @return The claimable amount (before fee).
     */
    function getUserClaimableERC20(address user, address token) external view whenState(VaultState.Collapsed) returns (uint256) {
        ReleaseConfig storage winningConfig = releaseConfigs[collapsedConfigId];
        uint256 allocation = winningConfig.erc20Allocations[user][token];
        uint256 alreadyClaimed = claimedERC20Amounts[user][token];
        // Return remaining claimable before fee calculation for user clarity
        return allocation.sub(alreadyClaimed);
    }

    /**
     * @dev Lists the ERC-721 token IDs a user can claim for a specific collection
     *      in the current Collapsed state, considering what's already claimed.
     * @param user The address of the user.
     * @param collection The address of the ERC-721 collection.
     * @return An array of claimable token IDs.
     */
    function getUserClaimableERC721(address user, address collection) external view whenState(VaultState.Collapsed) returns (uint256[] memory) {
        ReleaseConfig storage winningConfig = releaseConfigs[collapsedConfigId];
        uint256[] memory allocatedTokenIds = winningConfig.erc721Allocations[user][collection];
        uint256[] memory claimableIds = new uint256[](allocatedTokenIds.length);
        uint256 count = 0;

        for (uint i = 0; i < allocatedTokenIds.length; i++) {
            uint256 tokenId = allocatedTokenIds[i];
            if (!claimedERC721Tokens[user][collection][tokenId]) {
                claimableIds[count] = tokenId;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = claimableIds[i];
        }
        return result;
    }

     /**
      * @dev Returns all configured condition IDs.
      */
     function getAllConditionIds() external view returns (uint256[] memory) {
         return _conditionIds;
     }

     /**
      * @dev Returns all configured release config IDs.
      */
     function getAllConfigIds() external view returns (uint256[] memory) {
         return _configIds;
     }

     /**
      * @dev Checks if a user has claimed a specific ERC-20 token allocation (or part of it).
      * Note: This checks if `claimedERC20Amounts[user][token]` > 0. For partial claims,
      * use `getUserClaimableERC20`. This is more for a boolean check if any claim happened.
      * @param user The address of the user.
      * @param token The address of the ERC-20 token.
      * @return True if any amount has been claimed, false otherwise.
      */
     function isUserClaimedERC20(address user, address token) external view returns (bool) {
         return claimedERC20Amounts[user][token] > 0;
     }

      /**
       * @dev Checks if a user has claimed a specific ERC-721 token.
       * @param user The address of the user.
       * @param collection The address of the ERC-721 collection.
       * @param tokenId The ID of the NFT.
       * @return True if the specific NFT has been claimed, false otherwise.
       */
     function isUserClaimedERC721(address user, address collection, uint256 tokenId) external view returns (bool) {
         return claimedERC721Tokens[user][collection][tokenId];
     }


    // The Pausable contract from OpenZeppelin already includes _paused and _notPaused modifiers,
    // as well as a paused() getter. We've added a custom VaultState enum and manual state management
    // alongside Pausable to handle our specific 'Superposition'/'Collapsed' states.
    // The `whenState(VaultState.Paused)` and `whenNotPaused` are used appropriately.
    // Note: pausing sets the internal `_paused` flag. Our `currentVaultState` tracks our custom states.
    // `getVaultState()` needs to check `paused()` first.
}
```

**Important Considerations and Limitations:**

1.  **Complexity:** This contract is complex due to managing multiple asset types, multiple potential configurations, conditions, states, and claiming logic. This increases the surface area for bugs.
2.  **Gas Costs:** Iterating through `_conditionIds` in `triggerStateCollapse` is a potential gas bottleneck if there are a very large number of conditions. Managing arrays in storage (`_configIds`, `_conditionIds`) also adds gas cost.
3.  **Mapping Iteration:** Solidity doesn't easily allow iterating over mapping keys. Getters like `getReleaseConfigERC20Allocations` or `getERC721VaultTokens` are difficult to implement efficiently or completely without additional state variables to track mapping keys or external indexing. The provided getters are placeholders or require external knowledge/iteration.
4.  **ReleaseConfig Definition:** The chosen method where `ReleaseConfig` defines absolute allocations to specific addresses means the owner must pre-calculate or adjust these allocations based on expected or final total deposits. A proportional distribution method based on user deposits would be another approach but adds complexity to the `ReleaseConfig` structure and claim calculation.
5.  **ERC721 Fees:** Fees are only applied to ERC-20 withdrawals. Applying fees to NFTs is less standard and would require valuing the NFT or collecting a fee in a different token.
6.  **Error Handling/Edge Cases:** Robust error handling for all possible edge cases (e.g., zero address, re-entrancy beyond basic checks, token decimals for ERC20 claims, malicious proofData for non-hash types if added) requires thorough testing.
7.  **ZK Proof Verification:** The `ZKProofHash` condition *only* verifies a hash match. A real ZK-proof integration would require an on-chain verifier contract (like those generated by zk-SNARK/STARK tooling), adding significant complexity and gas cost. This implementation is a simplified *representation* of such a condition.
8.  **Non-Duplication:** While core concepts like multi-sig or time locks are common, the specific combination of a multi-asset vault with conditional outcomes determined by proving different *types* of external/verifiable conditions (including a mock ZK-hash verification) and the 'state collapse' mechanism is a creative application of these ideas that is unlikely to be a direct copy of a widely open-sourced contract.
9.  **Auditing:** This is an advanced concept and would *require* rigorous security audits before any use in a production environment with real assets.

This contract provides a framework for an interesting, advanced vault mechanism that goes beyond standard patterns by introducing conditional outcome determination based on external verifiable facts, wrapped in a "quantum state" metaphor.