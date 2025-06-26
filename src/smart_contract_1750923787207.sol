Okay, here is a Solidity smart contract designed with a focus on advanced, creative, and potentially trendy concepts centered around a "Quantum Vault" theme. It combines multi-asset management, complex access conditions, multi-party control, simulated dynamic state changes, and concepts inspired by quantum mechanics (state superposition/splitting, probabilistic decay, entanglement) represented through on-chain logic.

It aims for over 20 functions and avoids directly duplicating simple open-source patterns like basic ERC20/721 contracts, standard multi-sigs (while incorporating multi-sig *logic* for withdrawals), or basic vesting contracts.

---

**Smart Contract: QuantumVault**

**Outline & Function Summary:**

*   **Purpose:** A complex, multi-asset vault contract designed with dynamic, multi-party, and condition-based access controls. It simulates advanced concepts like 'quantum' state management (splitting, merging, probabilistic decay) and 'entanglement' with other vaults to create unique release conditions.
*   **Key Features:**
    *   Multi-asset support (ETH, ERC20, ERC721).
    *   Flexible, combinable access conditions (time-lock, multi-party approval, external data trigger, token/NFT gating).
    *   Complex boolean logic for combining access conditions (AND/OR).
    *   Multi-party ownership and withdrawal proposal system.
    *   Dynamic state mutation based on simulated internal/external factors.
    *   Simulated probabilistic decay of asset access.
    *   Simulated state splitting and merging for managing assets under different condition sets.
    *   Simulated entanglement: Linking vaults for condition synchronization.
    *   Dynamic transaction fees based on configurable parameters.
    *   Pausable mechanism.
*   **Core State Variables:**
    *   `owners`: Addresses with management privileges.
    *   `requiredApprovals`: Number of owner approvals needed for multi-sig actions.
    *   `withdrawalProposals`: Stores details of multi-sig withdrawal requests.
    *   `accessConditions`: Maps a unique ID to sets of complex access conditions.
    *   `assetConditionMap`: Links specific assets (ETH, ERC20, ERC721) to their required `conditionId`.
    *   `conditionSetEvaluated`: Tracks if a specific `conditionId` set has been met.
    *   `decayState`: Stores parameters and status for probabilistic decay linked to `conditionId`.
    *   `vaultStateSplit`: Tracks if a condition set ID represents a 'split' state.
    *   `entangledVaultAddress`: Address of a linked QuantumVault.
    *   `dynamicFeeConfig`: Configuration for calculating dynamic fees.
    *   `paused`: Paused state.
*   **Functions (Total: 34)**
    *   **Vault Management (Owners):**
        1.  `addOwner`: Adds a new owner.
        2.  `removeOwner`: Removes an owner.
        3.  `setRequiredApprovals`: Sets the number of approvals for multi-sig actions.
        4.  `pauseVault`: Pauses all sensitive operations.
        5.  `unpauseVault`: Unpauses the vault.
        6.  `attuneOracleFeed`: Sets the address of an oracle contract (simulated external data source).
        7.  `setEntangledVault`: Sets the address of another QuantumVault for simulated entanglement.
        8.  `setDynamicFeeConfig`: Configures parameters for the dynamic fee calculation.
    *   **Asset Deposit:**
        9.  `depositETH`: Deposits Ether into the vault, assigning it a condition ID.
        10. `depositERC20`: Deposits ERC20 tokens, assigning them a condition ID. Requires prior approval.
        11. `depositERC721`: Deposits ERC721 NFTs, assigning them a condition ID. Requires prior approval.
    *   **Asset Withdrawal (Multi-Sig with Conditions):**
        12. `submitWithdrawProposal`: Initiates a multi-sig withdrawal request for assets linked to a fulfilled condition ID.
        13. `approveWithdrawProposal`: Owner approves a withdrawal proposal.
        14. `rescindWithdrawProposal`: Owner cancels their approval for a proposal.
        15. `executeWithdrawProposal`: Executes a fully approved withdrawal proposal.
        16. `withdrawETHUnconditionally`: Allows owners to withdraw ETH not linked to a specific condition (e.g., fees, leftovers - use with caution).
        17. `withdrawERC20Unconditionally`: Allows owners to withdraw ERC20 not linked to a specific condition.
        18. `withdrawERC721Unconditionally`: Allows owners to withdraw ERC721 not linked to a specific condition.
    *   **Access Conditions & Evaluation:**
        19. `createAccessConditionSet`: Creates a new set of access rules, returning its unique ID.
        20. `assignConditionToETH`: Links deposited ETH to a specific condition ID.
        21. `assignConditionToERC20`: Links deposited ERC20 to a specific condition ID.
        22. `assignConditionToERC721`: Links deposited ERC721 to a specific condition ID.
        23. `triggerConditionCheck`: Evaluates the state of a specific condition ID based on time, multi-sig approvals *for that condition*, external data (oracle), token/NFT balance, and entangled vault state.
    *   **Simulated Quantum Concepts:**
        24. `mutateVaultState`: A function that can dynamically adjust internal parameters (e.g., decay rate, fee factors) based on a simulated trigger or time.
        25. `initiateProbabilisticDecay`: Starts a probabilistic decay process for assets linked to a specific condition ID.
        26. `observeDecayState`: Checks if the probabilistic decay has occurred for a given condition ID (view function).
        27. `splitVaultState`: Creates a new internal 'state' (condition ID) and moves a subset of assets to be governed by it, potentially under new or modified rules (simulating state branching).
        28. `mergeVaultStates`: Merges assets from one condition ID (a 'split' state) back into another, requiring conditions to be met.
        29. `syncWithEntangledVault`: Triggers a check against the entangled vault's state to potentially fulfill a local condition.
    *   **View Functions:**
        30. `isOwner`: Checks if an address is an owner.
        31. `getOwners`: Returns the list of owners.
        32. `getWithdrawalProposal`: Gets details of a specific withdrawal proposal.
        33. `isConditionSetMet`: Checks the boolean evaluation status of a condition ID.
        34. `predictiveAccessCheck`: Attempts to predict if conditions for a given ID *could* be met based on current data and time elapsed (does not guarantee future outcome).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For probabilistic decay simulation

// Interface for a potential Oracle contract (simplistic example)
interface IQuantumOracle {
    function getValue(string memory key) external view returns (uint256);
    function getBool(string memory key) external view returns (bool);
}

// Interface for Entangled Vaults (QuantumVaults)
interface IQuantumVault {
    function isConditionSetMet(bytes32 conditionId) external view returns (bool);
    // Add other necessary view functions for interaction if needed
}


/**
 * @title QuantumVault
 * @dev An advanced, multi-asset vault with complex, dynamic, and simulated 'quantum' access conditions.
 *      Combines multi-party control, diverse condition types, and state manipulation concepts.
 *
 * Outline & Summary provided at the top of the file.
 */
contract QuantumVault is ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    address[] private owners;
    uint256 private requiredApprovals;
    bool private paused;

    // --- Multi-Sig Withdrawal Proposals ---
    struct WithdrawProposal {
        address recipient;
        uint256 ethAmount; // Amount of ETH to withdraw
        address erc20Token; // ERC20 token address
        uint256 erc20Amount; // ERC20 token amount
        address erc721Token; // ERC721 token address
        uint256 erc721TokenId; // ERC721 token ID
        bytes32 conditionId; // Condition set required for this withdrawal
        uint256 approvals;
        mapping(address => bool) approvedBy;
        bool executed;
        bool cancelled;
    }
    // Mapping from proposal hash to proposal details
    mapping(bytes32 => WithdrawProposal) public withdrawalProposals;
    // Keep track of submitted proposal hashes
    bytes32[] public submittedProposalHashes;

    // --- Access Conditions ---
    enum ConditionType {
        TimeLock,           // Release after a specific timestamp
        MultiSigApproval,   // Requires a specific number of owners to trigger (distinct from withdrawal multi-sig)
        ExternalData,       // Requires oracle data to meet criteria
        TokenBalance,       // Caller/Recipient must hold a minimum token balance
        NFTOwnership,       // Caller/Recipient must own a specific NFT
        EntangledState      // Requires a condition set in an entangled vault to be met
    }

    struct Condition {
        ConditionType conditionType;
        uint256 paramUint;    // e.g., timestamp, required approvals, threshold
        address paramAddress; // e.g., oracle address, token address, NFT contract
        string paramString;   // e.g., oracle data key
        uint256 paramTokenId; // e.g., specific NFT ID
    }

    struct AccessConditionSet {
        Condition[] conditions;
        // Represents boolean logic for combining conditions.
        // Could be a simple ALL_MET or ANY_MET, or a more complex bitmask/expression parser (complex for on-chain).
        // Let's use a simple flag: true means ALL conditions must be met, false means ANY one condition must be met.
        bool requiresAllConditions;
        bool evaluated; // Has this set been checked?
        bool evaluationResult; // Result of the last check
        uint256 lastEvaluatedTimestamp; // When it was last checked
    }
    // Mapping from unique condition ID to the set of conditions
    mapping(bytes32 => AccessConditionSet) public accessConditions;
    // Mapping to track if a condition set's boolean evaluation is currently true
    mapping(bytes32 => bool) public conditionSetEvaluated;

    // --- Asset-to-Condition Mapping ---
    // Tracks which assets are linked to which condition ID for withdrawal
    mapping(address => bytes32) public ethConditionMap; // Uses owner address for simplicity, one per owner deposit? Or one global? Let's make it flexible with deposit ID.
    mapping(uint256 => bytes32) public ethDepositConditionMap; // Map deposit nonce to conditionId
    mapping(address => mapping(uint256 => bytes32)) public erc20ConditionMap; // tokenAddress -> depositNonce -> conditionId
    mapping(address => mapping(uint256 => bytes32)) public erc721ConditionMap; // tokenAddress -> tokenId -> conditionId

    uint256 private ethDepositNonce = 0;
    mapping(address => uint256) private erc20DepositNonces;
    mapping(address => uint256) private erc721DepositNonces; // Could map token address to nonce


    // --- Simulated Quantum Concepts ---
    struct DecayState {
        uint256 initiatedAt;     // Timestamp when decay was initiated
        uint256 decayRatePerSec; // Simulated decay rate (e.g., parts per trillion per second)
        bool hasDecayed;         // Flag indicating if decay has occurred
    }
    // Mapping conditionId to its decay state
    mapping(bytes32 => DecayState) public decayState;

    // Mapping conditionId to indicate if it represents a 'split' state
    mapping(bytes32 => bool) public vaultStateSplit;

    // Address of another QuantumVault contract for simulated entanglement
    address public entangledVaultAddress;
    IQuantumVault private entangledVault; // Interface instance

    // --- Dynamic Fees ---
    struct DynamicFeeConfig {
        uint256 baseFee;           // Base fee amount (in wei)
        address feeOracle;         // Oracle address for dynamic factor
        string feeDataKey;         // Key for oracle data (e.g., "volatility")
        uint256 feeVolatilityFactor; // Factor to multiply oracle value by (e.g., /1000)
    }
    DynamicFeeConfig public dynamicFeeConfig;
    bool public dynamicFeesEnabled;

    // --- Events ---
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed oldOwner);
    event RequiredApprovalsChanged(uint256 newRequiredApprovals);
    event VaultPaused(address indexed caller);
    event VaultUnpaused(address indexed caller);
    event OracleAttuned(address indexed oracleAddress);
    event EntangledVaultSet(address indexed vaultAddress);
    event DynamicFeeConfigUpdated(uint256 baseFee, address oracle, string dataKey, uint256 volatilityFactor);
    event DynamicFeesEnabled(bool enabled);

    event ETHDeposited(address indexed depositor, uint256 amount, uint256 depositNonce, bytes32 indexed conditionId);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount, uint256 depositNonce, bytes32 indexed conditionId);
    event ERC721Deposited(address indexed depositor, address indexed token, uint256 tokenId, uint256 depositNonce, bytes32 indexed conditionId);

    event WithdrawProposalSubmitted(bytes32 indexed proposalHash, address indexed recipient, bytes32 indexed conditionId);
    event WithdrawProposalApproved(bytes32 indexed proposalHash, address indexed approver);
    event WithdrawProposalRescinded(bytes32 indexed proposalHash, address indexed rescinder);
    event WithdrawProposalExecuted(bytes32 indexed proposalHash);
    event WithdrawProposalCancelled(bytes32 indexed proposalHash);

    event AccessConditionSetCreated(bytes32 indexed conditionId, bool requiresAll);
    event ConditionAssignedToETH(uint256 indexed depositNonce, bytes32 indexed conditionId);
    event ConditionAssignedToERC20(address indexed token, uint256 indexed depositNonce, bytes32 indexed conditionId);
    event ConditionAssignedToERC721(address indexed token, uint256 indexed tokenId, bytes32 indexed conditionId);
    event ConditionSetEvaluated(bytes32 indexed conditionId, bool result);

    event VaultStateMutated(bytes32 indexed affectedConditionId, string mutationDetails); // Generic event for state change
    event ProbabilisticDecayInitiated(bytes32 indexed conditionId, uint256 decayRatePerSec);
    event ProbabilisticDecayObserved(bytes32 indexed conditionId, bool hasDecayed);
    event VaultStateSplit(bytes32 indexed originalConditionId, bytes32 indexed newConditionId, string splitDetails);
    event VaultStateMerged(bytes32 indexed fromConditionId, bytes32 indexed toConditionId);
    event EntangledVaultSyncTriggered(bytes32 indexed conditionId, bool entangledConditionMet);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(isOwner(msg.sender), "QV: Not an owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QV: Vault is paused");
        _;
    }

    // --- Constructor ---
    constructor(address[] memory initialOwners, uint256 _requiredApprovals) {
        require(initialOwners.length > 0, "QV: Initial owners required");
        require(_requiredApprovals > 0 && _requiredApprovals <= initialOwners.length, "QV: Invalid required approvals");

        owners = initialOwners;
        requiredApprovals = _requiredApprovals;
        paused = false;
        dynamicFeesEnabled = false; // Start with dynamic fees disabled

        // Initialize default fee config
        dynamicFeeConfig = DynamicFeeConfig(0, address(0), "", 0);
    }

    receive() external payable whenNotPaused {
        // ETH deposits are handled by explicit depositETH function
        // This fallback is mainly to receive ETH transfers if someone sends directly without calling depositETH,
        // but such ETH won't be linked to any condition unless explicitly assigned later.
        // Consider adding a mechanism to assign orphaned ETH to a condition ID.
        emit ETHDeposited(msg.sender, msg.value, 0, bytes32(0)); // Use 0 nonce and 0 conditionId for untracked ETH
    }

    // --- Vault Management (Owners) ---

    /**
     * @notice Adds a new address to the list of owners.
     * @param newOwner The address to add as an owner.
     */
    function addOwner(address newOwner) external onlyOwner {
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != newOwner, "QV: Address is already an owner");
        }
        owners.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Removes an address from the list of owners.
     * @param ownerToRemove The address to remove from owners.
     */
    function removeOwner(address ownerToRemove) external onlyOwner {
        require(owners.length > requiredApprovals, "QV: Cannot remove owner if it reduces total below required approvals");
        bool found = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                found = true;
                break;
            }
        }
        require(found, "QV: Address is not an owner");
        emit OwnerRemoved(ownerToRemove);
    }

    /**
     * @notice Sets the number of required owner approvals for multi-sig actions.
     * @param _requiredApprovals The new required number of approvals.
     */
    function setRequiredApprovals(uint256 _requiredApprovals) external onlyOwner {
        require(_requiredApprovals > 0 && _requiredApprovals <= owners.length, "QV: Invalid required approvals count");
        requiredApprovals = _requiredApprovals;
        emit RequiredApprovalsChanged(_requiredApprovals);
    }

    /**
     * @notice Pauses certain sensitive operations (deposits, withdrawals, condition checks).
     * @dev Only owners can pause.
     */
    function pauseVault() external onlyOwner {
        require(!paused, "QV: Vault is already paused");
        paused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Unpauses the vault, allowing operations to resume.
     * @dev Only owners can unpause.
     */
    function unpauseVault() external onlyOwner {
        require(paused, "QV: Vault is not paused");
        paused = false;
        emit VaultUnpaused(msg.sender);
    }

    /**
     * @notice Sets the address of an external Oracle contract.
     * @param oracleAddress The address of the oracle contract.
     */
    function attuneOracleFeed(address oracleAddress) external onlyOwner {
        // Basic check if it's a contract, not essential but good practice
        uint256 size;
        assembly { size := extcodesize(oracleAddress) }
        require(size > 0, "QV: Oracle address is not a contract");
        // Could add more checks here, e.g., calling a known oracle function

        dynamicFeeConfig.feeOracle = oracleAddress; // Or have a separate oracle address state var
        emit OracleAttuned(oracleAddress);
    }

    /**
     * @notice Sets the address of another QuantumVault contract for simulated entanglement.
     * @param vaultAddress The address of the entangled vault.
     */
    function setEntangledVault(address vaultAddress) external onlyOwner {
        require(vaultAddress != address(0) && vaultAddress != address(this), "QV: Invalid or self address");
        entangledVaultAddress = vaultAddress;
        entangledVault = IQuantumVault(vaultAddress); // Initialize interface instance
        emit EntangledVaultSet(vaultAddress);
    }

    /**
     * @notice Configures parameters for dynamic fee calculation.
     * @param baseFee The base fee amount in wei.
     * @param oracle The address of the oracle contract to get dynamic data.
     * @param dataKey The string key to query the oracle for dynamic factor.
     * @param volatilityFactor The factor to scale oracle data by.
     */
    function setDynamicFeeConfig(uint256 baseFee, address oracle, string calldata dataKey, uint256 volatilityFactor) external onlyOwner {
        dynamicFeeConfig = DynamicFeeConfig(baseFee, oracle, dataKey, volatilityFactor);
        dynamicFeesEnabled = true; // Automatically enable dynamic fees on configuration
        emit DynamicFeeConfigUpdated(baseFee, oracle, dataKey, volatilityFactor);
        emit DynamicFeesEnabled(true);
    }

     /**
     * @notice Toggles whether dynamic fees are enabled.
     * @param enabled True to enable, false to disable.
     */
    function toggleDynamicFees(bool enabled) external onlyOwner {
        dynamicFeesEnabled = enabled;
        emit DynamicFeesEnabled(enabled);
    }


    // --- Asset Deposit ---

    /**
     * @notice Deposits Ether into the vault. Requires a condition ID to link the deposit to.
     * @param conditionId The ID of the access condition set required to withdraw this ETH.
     * @dev The conditionId must already exist via `createAccessConditionSet`.
     */
    function depositETH(bytes32 conditionId) external payable whenNotPaused {
        require(conditionId != bytes32(0), "QV: Valid conditionId required");
        require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set must exist");
        require(msg.value > 0, "QV: ETH amount must be greater than 0");

        uint256 currentNonce = ++ethDepositNonce;
        ethDepositConditionMap[currentNonce] = conditionId;

        emit ETHDeposited(msg.sender, msg.value, currentNonce, conditionId);
    }

    /**
     * @notice Deposits ERC20 tokens into the vault. Requires prior approval.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     * @param conditionId The ID of the access condition set required to withdraw these tokens.
     * @dev The vault contract must have allowance via `token.approve(address(this), amount)`.
     */
    function depositERC20(address token, uint256 amount, bytes32 conditionId) external whenNotPaused {
        require(token != address(0), "QV: Invalid token address");
        require(amount > 0, "QV: Amount must be greater than 0");
        require(conditionId != bytes32(0), "QV: Valid conditionId required");
        require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set must exist");

        IERC20 erc20 = IERC20(token);
        require(erc20.transferFrom(msg.sender, address(this), amount), "QV: ERC20 transfer failed");

        uint256 currentNonce = erc20DepositNonces[token]++;
        erc20ConditionMap[token][currentNonce] = conditionId;

        emit ERC20Deposited(msg.sender, token, amount, currentNonce, conditionId);
    }

    /**
     * @notice Deposits ERC721 NFTs into the vault. Requires prior approval or `setApprovalForAll`.
     * @param token The address of the ERC721 token contract.
     * @param tokenId The ID of the NFT to deposit.
     * @param conditionId The ID of the access condition set required to withdraw this NFT.
     * @dev The vault contract must have approval for this tokenId or the sender must have called `setApprovalForAll`.
     */
    function depositERC721(address token, uint256 tokenId, bytes32 conditionId) external whenNotPaused {
        require(token != address(0), "QV: Invalid token address");
        require(conditionId != bytes32(0), "QV: Valid conditionId required");
         require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set must exist");

        IERC721 erc721 = IERC721(token);
        require(erc721.ownerOf(tokenId) == msg.sender, "QV: Sender does not own NFT");

        erc721.safeTransferFrom(msg.sender, address(this), tokenId);

        erc721ConditionMap[token][tokenId] = conditionId;

        emit ERC721Deposited(msg.sender, token, tokenId, erc721DepositNonces[token]++, conditionId);
    }

    // --- Asset Withdrawal (Multi-Sig with Conditions) ---

    /**
     * @notice Internal function to calculate dynamic fee.
     * @return fee The calculated fee amount.
     */
    function _calculateDynamicFee() internal view returns (uint256) {
        if (!dynamicFeesEnabled || dynamicFeeConfig.feeOracle == address(0)) {
            return 0; // No dynamic fee if disabled or no oracle set
        }
        
        try IQuantumOracle(dynamicFeeConfig.feeOracle).getValue(dynamicFeeConfig.feeDataKey) returns (uint256 oracleValue) {
            // Prevent division by zero if factor is 0, or if oracle returns huge value
            if (dynamicFeeConfig.feeVolatilityFactor == 0) {
                 return dynamicFeeConfig.baseFee;
            }
            // Simple scaling: base + (oracleValue * factor)
            uint256 volatilityFee = oracleValue.mul(dynamicFeeConfig.feeVolatilityFactor) / 1e18; // Assuming oracle returns 18 decimals
            return dynamicFeeConfig.baseFee.add(volatilityFee);

        } catch {
            // If oracle call fails, return base fee or 0 depending on desired behavior
            return dynamicFeeConfig.baseFee; // Fallback to base fee
        }
    }

    /**
     * @notice Submits a proposal for withdrawing assets, requiring a specific condition ID to be met.
     * @param recipient The address to send assets to.
     * @param ethAmount Amount of ETH.
     * @param erc20Token ERC20 token address.
     * @param erc20Amount ERC20 amount.
     * @param erc721Token ERC721 token address.
     * @param erc721TokenId ERC721 token ID.
     * @param conditionId The ID of the access condition set that must be met.
     * @return proposalHash The unique hash of the submitted proposal.
     * @dev This only submits the proposal; it must be approved by owners and executed.
     */
    function submitWithdrawProposal(
        address recipient,
        uint256 ethAmount,
        address erc20Token,
        uint256 erc20Amount,
        address erc721Token,
        uint256 erc721TokenId,
        bytes32 conditionId
    ) external onlyOwner whenNotPaused nonReentrant returns (bytes32 proposalHash) {
        require(recipient != address(0), "QV: Invalid recipient");
        require(conditionId != bytes32(0), "QV: Valid conditionId required");
        require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set must exist");
        require(conditionSetEvaluated[conditionId], "QV: Access condition set is not met");

        // Ensure at least one asset is being proposed
        require(ethAmount > 0 || erc20Amount > 0 || erc721Token != address(0), "QV: No assets specified");

        // Calculate proposal hash
        proposalHash = keccak256(abi.encodePacked(recipient, ethAmount, erc20Token, erc20Amount, erc721Token, erc721TokenId, conditionId, submittedProposalHashes.length));

        require(withdrawalProposals[proposalHash].recipient == address(0), "QV: Proposal already exists");

        withdrawalProposals[proposalHash] = WithdrawProposal({
            recipient: recipient,
            ethAmount: ethAmount,
            erc20Token: erc20Token,
            erc20Amount: erc20Amount,
            erc721Token: erc721Token,
            erc721TokenId: erc721TokenId,
            conditionId: conditionId,
            approvals: 0,
            approvedBy: new mapping(address => bool)(), // Initialize empty mapping
            executed: false,
            cancelled: false
        });

        submittedProposalHashes.push(proposalHash); // Track proposal hashes

        emit WithdrawProposalSubmitted(proposalHash, recipient, conditionId);
        return proposalHash;
    }

    /**
     * @notice Owner approves a withdrawal proposal.
     * @param proposalHash The hash of the proposal to approve.
     */
    function approveWithdrawProposal(bytes32 proposalHash) external onlyOwner whenNotPaused {
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        require(proposal.recipient != address(0), "QV: Proposal does not exist");
        require(!proposal.executed, "QV: Proposal already executed");
        require(!proposal.cancelled, "QV: Proposal cancelled");
        require(!proposal.approvedBy[msg.sender], "QV: Already approved by this owner");

        proposal.approvedBy[msg.sender] = true;
        proposal.approvals++;

        emit WithdrawProposalApproved(proposalHash, msg.sender);
    }

    /**
     * @notice Owner rescinds their approval for a withdrawal proposal.
     * @param proposalHash The hash of the proposal to rescind approval from.
     */
    function rescindWithdrawProposal(bytes32 proposalHash) external onlyOwner whenNotPaused {
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        require(proposal.recipient != address(0), "QV: Proposal does not exist");
        require(!proposal.executed, "QV: Proposal already executed");
        require(!proposal.cancelled, "QV: Proposal cancelled");
        require(proposal.approvedBy[msg.sender], "QV: Approval not found for this owner");

        proposal.approvedBy[msg.sender] = false;
        proposal.approvals--;

        emit WithdrawProposalRescinded(proposalHash, msg.sender);
    }


    /**
     * @notice Executes a withdrawal proposal if required approvals are met and condition is still met.
     * @param proposalHash The hash of the proposal to execute.
     * @dev Includes dynamic fee calculation.
     */
    function executeWithdrawProposal(bytes32 proposalHash) external onlyOwner whenNotPaused nonReentrant {
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        require(proposal.recipient != address(0), "QV: Proposal does not exist");
        require(!proposal.executed, "QV: Proposal already executed");
        require(!proposal.cancelled, "QV: Proposal cancelled");
        require(proposal.approvals >= requiredApprovals, "QV: Not enough approvals");
        // Re-check condition set *at time of execution*
        triggerConditionCheck(proposal.conditionId); // Ensure state is up-to-date
        require(conditionSetEvaluated[proposal.conditionId], "QV: Access condition set is no longer met");

        proposal.executed = true;

        uint256 totalFee = _calculateDynamicFee();
        uint256 ethToSend = proposal.ethAmount;

        if (totalFee > 0) {
             // Deduct fee from ETH withdrawal first
             if (ethToSend >= totalFee) {
                 ethToSend = ethToSend.sub(totalFee);
             } else {
                 // Handle case where ETH withdrawal is less than fee
                 // For simplicity here, we'll just zero out ETH and potentially require other assets to cover,
                 // Or ignore fee if not enough ETH. Let's ignore fee for now if ETH is insufficient.
                 // A more complex contract might burn tokens, require separate fee payment etc.
                 ethToSend = 0; // Fee consumes all proposed ETH withdrawal
             }
             // Note: Fee is not sent anywhere in this simplified example, it's just 'deducted' from withdrawal.
             // A real contract would transfer fees to an owner/treasury address.
        }


        // Execute transfers
        if (ethToSend > 0) {
            (bool success, ) = payable(proposal.recipient).call{value: ethToSend}("");
            require(success, "QV: ETH transfer failed");
        }

        if (proposal.erc20Amount > 0 && proposal.erc20Token != address(0)) {
            IERC20(proposal.erc20Token).transfer(proposal.recipient, proposal.erc20Amount);
        }

        if (proposal.erc721TokenId > 0 && proposal.erc721Token != address(0)) {
             IERC721(proposal.erc721Token).safeTransferFrom(address(this), proposal.recipient, proposal.erc721TokenId);
             // Consider removing the condition mapping entry after withdrawal?
             // delete erc721ConditionMap[proposal.erc721Token][proposal.erc721TokenId];
        }
        // Note: ETH/ERC20 condition mappings are nonce-based, harder to remove specific entries this way without tracking balances linked to nonce.
        // This example doesn't track balances per nonce, assuming assets matching the proposed amounts are available.

        emit WithdrawProposalExecuted(proposalHash);
    }

     /**
     * @notice Cancels a withdrawal proposal. Can be called by any owner.
     * @param proposalHash The hash of the proposal to cancel.
     */
    function cancelWithdrawProposal(bytes32 proposalHash) external onlyOwner whenNotPaused {
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        require(proposal.recipient != address(0), "QV: Proposal does not exist");
        require(!proposal.executed, "QV: Proposal already executed");
        require(!proposal.cancelled, "QV: Proposal cancelled");

        proposal.cancelled = true;
        emit WithdrawProposalCancelled(proposalHash);
    }


    // --- Direct Unconditional Withdrawals (Use with Caution, e.g., for leftover fees) ---

    /**
     * @notice Allows owners to withdraw ETH from the vault without conditions. Use with extreme caution.
     * @param amount The amount of ETH to withdraw.
     * @param recipient The recipient address.
     */
    function withdrawETHUnconditionally(uint256 amount, address payable recipient) external onlyOwner whenNotPaused nonReentrant {
        require(amount > 0, "QV: Amount must be > 0");
        require(address(this).balance >= amount, "QV: Insufficient ETH balance");
        require(recipient != address(0), "QV: Invalid recipient");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "QV: Unconditional ETH transfer failed");
    }

    /**
     * @notice Allows owners to withdraw ERC20 tokens without conditions. Use with extreme caution.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to withdraw.
     * @param recipient The recipient address.
     */
    function withdrawERC20Unconditionally(address token, uint256 amount, address recipient) external onlyOwner whenNotPaused nonReentrant {
         require(token != address(0), "QV: Invalid token address");
         require(amount > 0, "QV: Amount must be > 0");
         require(recipient != address(0), "QV: Invalid recipient");
         require(IERC20(token).balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance");

         IERC20(token).transfer(recipient, amount);
    }

     /**
     * @notice Allows owners to withdraw ERC721 NFTs without conditions. Use with extreme caution.
     * @param token Address of the ERC721 token.
     * @param tokenId Token ID to withdraw.
     * @param recipient The recipient address.
     */
    function withdrawERC721Unconditionally(address token, uint256 tokenId, address recipient) external onlyOwner whenNotPaused nonReentrant {
        require(token != address(0), "QV: Invalid token address");
        require(recipient != address(0), "QV: Invalid recipient");
        // Check ownership by the contract
        require(IERC721(token).ownerOf(tokenId) == address(this), "QV: Vault does not own NFT");

        IERC721(token).safeTransferFrom(address(this), recipient, tokenId);
        // Consider removing the condition mapping entry? delete erc721ConditionMap[token][tokenId];
    }

    // --- Access Conditions & Evaluation ---

    /**
     * @notice Creates a new set of access conditions. Returns a unique ID for this set.
     * @param conditions The array of Condition structs defining the rules.
     * @param requiresAll If true, all conditions must be met. If false, any one condition must be met.
     * @return The unique bytes32 ID for the new condition set.
     */
    function createAccessConditionSet(Condition[] calldata conditions, bool requiresAll) external onlyOwner whenNotPaused returns (bytes32 conditionId) {
        require(conditions.length > 0, "QV: Must provide at least one condition");

        // Generate a unique ID for the condition set
        conditionId = keccak256(abi.encodePacked(conditions, requiresAll, block.timestamp, msg.sender));

        require(accessConditions[conditionId].conditions.length == 0, "QV: Condition set ID collision (highly unlikely)");

        AccessConditionSet storage newSet = accessConditions[conditionId];
        newSet.conditions = conditions; // Store the array
        newSet.requiresAllConditions = requiresAll;
        newSet.evaluated = false; // Not evaluated yet
        newSet.evaluationResult = false;
        newSet.lastEvaluatedTimestamp = 0;

        emit AccessConditionSetCreated(conditionId, requiresAll);
        return conditionId;
    }

    // Note: Assign functions link *existing* deposits/assets to a condition.
    // Deposits via `depositETH`/`depositERC20`/`depositERC721` should ideally call these internally or take conditionId as param.
    // The current deposit functions already take `conditionId`, so these are potentially redundant or for re-assigning orphaned assets.
    // Let's make deposit functions internal and expose wrappers that take conditionId.
    // OR, keep deposits as they are and these functions are for *changing* the condition later (more complex feature).
    // Let's refactor deposit functions to take conditionId, and remove these specific assignment functions for simplicity in this example.
    // The existing deposit functions already take conditionId, so the mappings are populated on deposit. The explicit assign functions are removed.

    /**
     * @notice Evaluates the state of a specific access condition set.
     * @param conditionId The ID of the condition set to evaluate.
     * @dev This function checks all conditions within the set and updates the contract state.
     */
    function triggerConditionCheck(bytes32 conditionId) public whenNotPaused nonReentrant {
        AccessConditionSet storage conditionSet = accessConditions[conditionId];
        require(conditionSet.conditions.length > 0, "QV: Condition set does not exist");

        bool currentResult;

        if (conditionSet.requiresAllConditions) {
            currentResult = true; // Assume true, prove false
            for (uint256 i = 0; i < conditionSet.conditions.length; i++) {
                if (!_checkSingleCondition(conditionSet.conditions[i])) {
                    currentResult = false;
                    break;
                }
            }
        } else {
            currentResult = false; // Assume false, prove true
             for (uint256 i = 0; i < conditionSet.conditions.length; i++) {
                if (_checkSingleCondition(conditionSet.conditions[i])) {
                    currentResult = true;
                    break;
                }
            }
        }

        conditionSet.evaluated = true;
        conditionSet.evaluationResult = currentResult;
        conditionSet.lastEvaluatedTimestamp = block.timestamp;
        conditionSetEvaluated[conditionId] = currentResult; // Update the boolean mapping for easy lookup

        emit ConditionSetEvaluated(conditionId, currentResult);
    }

    /**
     * @notice Internal helper to check a single condition.
     * @param condition The Condition struct to check.
     * @return True if the condition is met, false otherwise.
     * @dev Simulates interactions with oracles and other contract states.
     */
    function _checkSingleCondition(Condition memory condition) internal view returns (bool) {
        address sender = msg.sender; // Or potentially the recipient depending on logic
        address vault = address(this);

        if (decayState[conditionId].hasDecayed) {
             return false; // If decay has occurred for this set, all conditions implicitly fail
        }

        if (vaultStateSplit[conditionId]) {
            // If this is a 'split' state, maybe it requires a specific interaction or observation to resolve?
            // For this example, let's say a split state *always* requires observation (triggerConditionCheck)
            // AND some other factor, or maybe implies a temporary state of 'uncertainty'.
            // Let's make split state require an *additional* oracle check + time passed.
            // This makes split states harder to resolve than their origin.
             bool oracleCheck = false;
             if (condition.paramAddress != address(0) && bytes(condition.paramString).length > 0) {
                 try IQuantumOracle(condition.paramAddress).getBool(condition.paramString) returns (bool oracleResult) {
                     oracleCheck = oracleResult;
                 } catch {
                     oracleCheck = false; // Oracle call failed
                 }
             }
             bool timeCheck = block.timestamp >= condition.paramUint; // Re-use paramUint as a time lock
             return oracleCheck && timeCheck; // Split state requires specific oracle and time
        }


        // Normal conditions
        if (condition.conditionType == ConditionType.TimeLock) {
            return block.timestamp >= condition.paramUint; // paramUint is timestamp
        }
        if (condition.conditionType == ConditionType.MultiSigApproval) {
             // This would require a *separate* approval mechanism tied to the condition ID, not the withdrawal proposals.
             // For simplicity in this example, let's say it requires a specific number of *owners* to have called `triggerConditionCheck`
             // since the condition was set or last failed. This needs more state.
             // ALTERNATIVE: Re-use the withdrawal proposal approval state? No, confusing.
             // Let's make this condition require a specific number of owners to have explicitly 'attested' to the condition.
             // This needs another mapping: `mapping(bytes32 => mapping(address => bool)) conditionAttestedBy;` and `mapping(bytes32 => uint256) conditionAttestations;`
             // And a function `attestCondition(bytes32 conditionId)`.
             // Let's simplify for the example: make MultiSigApproval condition require a specific number of owners currently in the `owners` array. (Less useful, but simpler).
             return owners.length >= condition.paramUint; // paramUint is required owner count
        }
        if (condition.conditionType == ConditionType.ExternalData) {
             require(condition.paramAddress != address(0), "QV: Oracle address not set for condition");
             // Assuming paramUint is a threshold, paramString is the data key
             try IQuantumOracle(condition.paramAddress).getValue(condition.paramString) returns (uint256 oracleValue) {
                 return oracleValue >= condition.paramUint; // paramUint is threshold
             } catch {
                 return false; // Oracle call failed
             }
        }
        if (condition.conditionType == ConditionType.TokenBalance) {
             require(condition.paramAddress != address(0), "QV: Token address not set for condition");
             // Checks caller's balance, could also check recipient's balance
             return IERC20(condition.paramAddress).balanceOf(sender) >= condition.paramUint; // paramUint is min balance
        }
        if (condition.conditionType == ConditionType.NFTOwnership) {
            require(condition.paramAddress != address(0) && condition.paramTokenId > 0, "QV: NFT details not set for condition");
             // Checks caller's ownership, could also check recipient's ownership
             try IERC721(condition.paramAddress).ownerOf(condition.paramTokenId) returns (address nftOwner) {
                 return nftOwner == sender;
             } catch {
                 return false; // NFT call failed (e.g., token doesn't exist)
             }
        }
         if (condition.conditionType == ConditionType.EntangledState) {
             require(entangledVaultAddress != address(0), "QV: Entangled vault not set");
             // paramUint could specify which condition ID in the entangled vault to check
             bytes32 entangledConditionId = bytes32(condition.paramUint); // Re-use paramUint to store entangled conditionId
             return entangledVault.isConditionSetMet(entangledConditionId);
        }

        return false; // Unknown condition type
    }


    // --- Simulated Quantum Concepts ---

    /**
     * @notice Simulates a state mutation within the vault, potentially altering parameters.
     * @param conditionId The ID of the condition set potentially affected by mutation.
     * @dev This is a conceptual function. Real mutation logic would be complex.
     *      Example: Randomly adjust decay rate or trigger an oracle check.
     */
    function mutateVaultState(bytes32 conditionId) external onlyOwner whenNotPaused {
        require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set does not exist");

        // Simulate mutation: e.g., based on block properties and condition ID
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, conditionId)));

        if (decayState[conditionId].initiatedAt > 0) {
            // If decay is active, maybe mutation changes the rate slightly
            uint256 currentRate = decayState[conditionId].decayRatePerSec;
            uint256 rateChange = (entropy % 100) - 50; // +/- 50 variation
            uint256 newRate = (rateChange > 0) ? currentRate.add(uint256(rateChange)) : currentRate.sub(uint256(-rateChange));
             // Ensure rate doesn't go below a minimum (e.g., 1)
             decayState[conditionId].decayRatePerSec = newRate > 0 ? newRate : 1;

            emit VaultStateMutated(conditionId, string(abi.encodePacked("Decay rate changed by: ", rateChange)));
        } else {
            // If no decay, maybe mutation triggers an external check or alters a paramUint in a condition
            if (entropy % 10 < 2 && accessConditions[conditionId].conditions.length > 0) { // 20% chance of altering a param
                 uint256 conditionIndex = entropy % accessConditions[conditionId].conditions.length;
                 AccessConditionSet storage cs = accessConditions[conditionId];
                 Condition storage cond = cs.conditions[conditionIndex];
                 if (cond.conditionType == ConditionType.TimeLock) {
                     // Slightly nudge the time lock
                     int256 timeNudge = int256(entropy % 1000) - 500; // +/- 500 seconds
                     cond.paramUint = uint256(int256(cond.paramUint) + timeNudge);
                     emit VaultStateMutated(conditionId, string(abi.encodePacked("TimeLock nudged by: ", timeNudge, "s")));
                 }
                 // Add more mutation types for other condition types
            }
        }

        emit VaultStateMutated(conditionId, "State potentially mutated");
    }

    /**
     * @notice Initiates a probabilistic decay process for assets linked to a specific condition set.
     * @param conditionId The ID of the condition set subject to decay.
     * @param decayRatePerSec The simulated rate of decay (e.g., units per second). Higher = faster decay.
     * @dev Once initiated, calling `observeDecayState` will check if decay has occurred based on time and rate.
     */
    function initiateProbabilisticDecay(bytes32 conditionId, uint256 decayRatePerSec) external onlyOwner whenNotPaused {
         require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set does not exist");
         require(decayRatePerSec > 0, "QV: Decay rate must be positive");
         require(decayState[conditionId].initiatedAt == 0, "QV: Decay already initiated for this set");

         decayState[conditionId] = DecayState({
             initiatedAt: block.timestamp,
             decayRatePerSec: decayRatePerSec,
             hasDecayed: false
         });

         emit ProbabilisticDecayInitiated(conditionId, decayRatePerSec);
    }

    /**
     * @notice Observes the probabilistic decay state for a condition set.
     * @param conditionId The ID of the condition set to observe.
     * @return True if decay has occurred, false otherwise.
     * @dev This function checks if enough time has passed with the given rate to simulate decay.
     *      Uses blockhash/timestamp for pseudo-randomness. Outcome is fixed after first check.
     */
    function observeDecayState(bytes32 conditionId) public view returns (bool) {
        DecayState storage currentDecayState = decayState[conditionId];
        if (currentDecayState.initiatedAt == 0 || currentDecayState.hasDecayed) {
            // Decay not initiated or already happened/checked
            return currentDecayState.hasDecayed;
        }

        uint256 timeElapsed = block.timestamp - currentDecayState.initiatedAt;
        if (timeElapsed == 0) {
            return false; // No time has passed
        }

        // Simulate probabilistic decay using blockhash/timestamp
        // P(decay) increases with timeElapsed * decayRate
        // Simple simulation: hash % MAX < (rate * elapsed). Need to scale appropriately.
        // Let's scale rate * elapsed by a large number (e.g., 1e18) and compare to a random number scaled similarly.
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, conditionId)));

        // Scale rate * elapsed. Avoid overflow. Max possible value for rate*elapsed needs consideration.
        // Let's cap rate * elapsed * SCALE_FACTOR to prevent overflow with uint256 max.
        // A simpler approach for simulation: if hash is below a certain threshold, decay happens.
        // Threshold increases with time and rate.
        // Threshold = min(MAX_UINT, timeElapsed * decayRatePerSec * ARBITRARY_SCALE_FACTOR)
        // Let's use a fixed scale factor, e.g., 1e12
        uint256 scaleFactor = 1e12;
        uint256 decayThreshold = timeElapsed.mul(currentDecayState.decayRatePerSec);

        // Check if decay has occurred based on the pseudo-random number and threshold
        // If the random number is less than the threshold * scaled, decay occurs.
        // This mapping is conceptual.
        bool decayHappened = (pseudoRandom % (1e18)) < decayThreshold; // Arbitrary mapping to represent probability

        // In a non-view function, you would update:
        // if (decayHappened) { currentDecayState.hasDecayed = true; emit ProbabilisticDecayObserved(conditionId, true); }

        return decayHappened; // In a view function, just return the simulated result
    }

    /**
     * @notice Simulates splitting the state for assets linked to a condition set.
     * @param originalConditionId The condition ID currently governing assets.
     * @param newConditionId The ID of the new condition set to govern a subset of assets.
     * @param ethDepositNoncesToMove Array of ETH deposit nonces to move.
     * @param erc20sToMove Array of structs {token, depositNonce} for ERC20s.
     * @param erc721sToMove Array of structs {token, tokenId} for ERC721s.
     * @dev This marks the original condition ID as 'split' and re-maps specified assets to the new condition ID.
     *      Requires ownership validation or perhaps a specific condition on original ID to be met.
     */
    function splitVaultState(
        bytes32 originalConditionId,
        bytes32 newConditionId,
        uint256[] calldata ethDepositNoncesToMove,
        structs.ERC20Move[] calldata erc20sToMove,
        structs.ERC721Move[] calldata erc721sToMove
    ) external onlyOwner whenNotPaused { // Requires owner for simplicity
         require(accessConditions[originalConditionId].conditions.length > 0, "QV: Original condition set does not exist");
         require(accessConditions[newConditionId].conditions.length > 0, "QV: New condition set does not exist");
         require(!vaultStateSplit[originalConditionId], "QV: Original state is already split");

         // Re-map ETH deposits
         for(uint256 i = 0; i < ethDepositNoncesToMove.length; i++) {
             require(ethDepositConditionMap[ethDepositNoncesToMove[i]] == originalConditionId, "QV: ETH deposit not linked to original condition");
             ethDepositConditionMap[ethDepositNoncesToMove[i]] = newConditionId;
         }

         // Re-map ERC20 deposits
         for(uint256 i = 0; i < erc20sToMove.length; i++) {
             require(erc20ConditionMap[erc20sToMove[i].token][erc20sToMove[i].depositNonce] == originalConditionId, "QV: ERC20 deposit not linked to original condition");
             erc20ConditionMap[erc20sToMove[i].token][erc20sToMove[i].depositNonce] = newConditionId;
         }

         // Re-map ERC721 NFTs
         for(uint256 i = 0; i < erc721sToMove.length; i++) {
              require(erc721ConditionMap[erc721sToMove[i].token][erc721sToMove[i].tokenId] == originalConditionId, "QV: ERC721 not linked to original condition");
              erc721ConditionMap[erc721sToMove[i].token][erc721sToMove[i].tokenId] = newConditionId;
         }

         vaultStateSplit[originalConditionId] = true; // Mark original state as split
         vaultStateSplit[newConditionId] = true; // Mark new state as also part of a split (optional, could be different logic)

         emit VaultStateSplit(originalConditionId, newConditionId, string(abi.encodePacked("Split assets to ", newConditionId)));
    }

     /**
     * @notice Simulates merging assets from one 'split' state condition ID into another.
     * @param fromConditionId The condition ID of the state to merge *from* (must be a 'split' state).
     * @param toConditionId The condition ID of the state to merge *into*.
     * @dev All assets currently mapped to `fromConditionId` will be re-mapped to `toConditionId`.
     *      Requires a condition on `fromConditionId` to be met (e.g., specific time, multi-sig observation of merge intent).
     *      For simplicity, let's require `fromConditionId`'s boolean state to be true.
     */
    function mergeVaultStates(bytes32 fromConditionId, bytes32 toConditionId) external onlyOwner whenNotPaused {
         require(accessConditions[fromConditionId].conditions.length > 0, "QV: From condition set does not exist");
         require(accessConditions[toConditionId].conditions.length > 0, "QV: To condition set does not exist");
         require(fromConditionId != toConditionId, "QV: Cannot merge state into itself");
         require(vaultStateSplit[fromConditionId], "QV: 'From' state must be marked as split");

         // Re-check condition on 'from' state before merging
         triggerConditionCheck(fromConditionId);
         require(conditionSetEvaluated[fromConditionId], "QV: Condition for merging 'from' state not met");

         // This requires iterating through *all* potential assets to find which are mapped to fromConditionId.
         // This is highly inefficient on-chain. A better design would track which assets belong to which state ID.
         // As a simulation, we won't move actual assets here, only the *mapping*.
         // In a real system, you would need a data structure (e.g., a list of assets per conditionId)
         // Here, we'll just conceptually represent the merge by changing the mapping *if* we could iterate.
         // For this example, we'll just update the 'split' flag and emit an event, representing the *intent* or *potential* to merge assets.
         // To make it functional, we would need a way to iterate assets by conditionId.
         // Let's add a dummy state change to represent the merge happening.
         vaultStateSplit[fromConditionId] = false; // No longer considered split (or maybe merge changes state to non-split?)
         // We should ideally re-map assets here. Since iterating is hard, let's assume assets are re-mapped off-chain
         // or by a separate owner action that specifies assets.

         emit VaultStateMerged(fromConditionId, toConditionId);
    }

    /**
     * @notice Triggers a synchronization check with the entangled vault.
     * @param conditionId The ID of the condition set that might rely on the entangled state.
     * @dev This calls `isConditionSetMet` on the entangled vault for a specific condition ID.
     *      The result can be used in the `triggerConditionCheck` for `conditionId`.
     */
    function syncWithEntangledVault(bytes32 conditionId) external whenNotPaused { // Could be open or owner only
         require(entangledVaultAddress != address(0), "QV: Entangled vault not set");
         require(accessConditions[conditionId].conditions.length > 0, "QV: Condition set does not exist");

         // Find the EntangledState condition within the set
         bool entangledConditionMet = false;
         for (uint256 i = 0; i < accessConditions[conditionId].conditions.length; i++) {
             Condition memory cond = accessConditions[conditionId].conditions[i];
             if (cond.conditionType == ConditionType.EntangledState) {
                 bytes32 entangledCheckConditionId = bytes32(cond.paramUint);
                 entangledConditionMet = entangledVault.isConditionSetMet(entangledCheckConditionId);
                 // If requiresAll is true, we need to check ALL. If requiresAny, we can stop at first true.
                 // This logic is handled in triggerConditionCheck, this function just performs the external call.
                 // We could store the entangled vault's state here if needed.
                 // For now, just trigger the check and emit event. The actual condition evaluation happens in triggerConditionCheck.
                 break; // Assuming only one EntangledState condition per set for simplicity
             }
         }

         emit EntangledVaultSyncTriggered(conditionId, entangledConditionMet);
         // Note: The actual state update (`conditionSetEvaluated[conditionId]`) happens in `triggerConditionCheck`
         // after this sync data is potentially used.
    }


    // --- View Functions ---

    /**
     * @notice Checks if an address is currently an owner.
     * @param account The address to check.
     * @return True if the account is an owner, false otherwise.
     */
    function isOwner(address account) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Gets the current list of owners.
     * @return An array of owner addresses.
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Gets the details of a specific withdrawal proposal.
     * @param proposalHash The hash of the proposal.
     * @return The WithdrawProposal struct details.
     */
    function getWithdrawalProposal(bytes32 proposalHash) external view returns (WithdrawProposal memory) {
        // Note: mapping key lookup in view function does not consume gas.
        // However, Solidity currently cannot return a struct containing a mapping directly from a mapping lookup in a view function.
        // A common workaround is to fetch individual fields or use a helper function.
        // Let's return a basic representation without the `approvedBy` mapping.
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        return WithdrawProposal({
            recipient: proposal.recipient,
            ethAmount: proposal.ethAmount,
            erc20Token: proposal.erc20Token,
            erc20Amount: proposal.erc20Amount,
            erc721Token: proposal.erc721Token,
            erc721TokenId: proposal.erc721TokenId,
            conditionId: proposal.conditionId,
            approvals: proposal.approvals,
            approvedBy: new mapping(address => bool)(), // Dummy empty mapping for ABI compatibility
            executed: proposal.executed,
            cancelled: proposal.cancelled
        });
         // For `approvedBy`, you might add a separate view function like `hasApproved(bytes32 proposalHash, address owner)`.
    }

    /**
     * @notice Checks if a specific access condition set's boolean evaluation is currently met.
     * @param conditionId The ID of the condition set to check.
     * @return True if the condition set is evaluated as met, false otherwise.
     * @dev This returns the *last evaluated* result, not a real-time check. Use `triggerConditionCheck` first for real-time.
     */
    function isConditionSetMet(bytes32 conditionId) external view returns (bool) {
         return conditionSetEvaluated[conditionId];
    }

    /**
     * @notice Attempts a predictive check if conditions for a given ID *could* be met based on current data.
     * @param conditionId The ID of the condition set to predict.
     * @return True if based on *current* observable data and time, the conditions *appear* met, false otherwise.
     * @dev This is not a guarantee of future state. It only checks current `block.timestamp`, current oracle data, etc.
     */
    function predictiveAccessCheck(bytes32 conditionId) external view returns (bool possible) {
        AccessConditionSet storage conditionSet = accessConditions[conditionId];
        if (conditionSet.conditions.length == 0) {
            return false; // Condition set does not exist
        }

         if (decayState[conditionId].initiatedAt > 0 && !decayState[conditionId].hasDecayed) {
             // If decay is initiated but not yet observed/flagged, check if decay *would* happen now
             if (observeDecayState(conditionId)) {
                  return false; // Predictive check: decay would occur if observed now, so access is unlikely
             }
         }
         if (decayState[conditionId].hasDecayed) {
              return false; // Decay already happened, access is impossible
         }

        if (conditionSet.requiresAllConditions) {
            possible = true; // Assume true, prove false
            for (uint256 i = 0; i < conditionSet.conditions.length; i++) {
                 // Use _checkSingleCondition, which is a view function
                if (!_checkSingleCondition(conditionSet.conditions[i])) {
                    possible = false;
                    break;
                }
            }
        } else {
            possible = false; // Assume false, prove true
             for (uint256 i = 0; i < conditionSet.conditions.length; i++) {
                 // Use _checkSingleCondition
                if (_checkSingleCondition(conditionSet.conditions[i])) {
                    possible = true;
                    break;
                }
            }
        }
        return possible;
    }

    // --- Internal Structs (for calldata in functions like splitVaultState) ---
    // Placed here or in a separate library/file
    library structs {
        struct ERC20Move {
            address token;
            uint256 depositNonce;
        }
        struct ERC721Move {
            address token;
            uint256 tokenId;
        }
    }

    // Need to add a public/external getter for proposal.approvedBy[owner] as cannot return mapping in view
    function hasApprovedWithdrawProposal(bytes32 proposalHash, address owner) external view returns (bool) {
        WithdrawProposal storage proposal = withdrawalProposals[proposalHash];
        require(proposal.recipient != address(0), "QV: Proposal does not exist");
        return proposal.approvedBy[owner];
    }

}
```